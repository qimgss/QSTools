use std::fs::{File, create_dir_all};
use std::io::{Read, Write};
use std::path::Path;

use crate::error::QSLibError;

const MAGIC_NEW: &[u8] = b"070701";
const MAGIC_CRC: &[u8] = b"070702";

pub fn extract<P: AsRef<Path>>(cpio: P, out: P) -> Result<(), QSLibError> {
    let mut f = File::open(cpio)?;
    let mut data = Vec::new();
    f.read_to_end(&mut data)?;

    let mut pos = 0;
    while pos + 110 <= data.len() {
        if &data[pos..pos + 6] != MAGIC_NEW && &data[pos..pos + 6] != MAGIC_CRC {
            break;
        }

        let name = read_str(&data[pos + 94..]);
        let nlen = hex32(&data[pos + 86..pos + 94])? as usize;
        let flen = hex32(&data[pos + 54..pos + 62])? as usize;

        let data_start = align4(pos + 110 + nlen);
        let data_end = data_start + flen;

        if name == "TRAILER!!!" {
            break;
        }

        let path = out.as_ref().join(strip_slash(&name));
        if name.ends_with('/') {
            create_dir_all(&path)?;
        } else {
            if let Some(p) = path.parent() {
                create_dir_all(p)?;
            }
            let mut o = File::create(path)?;
            o.write_all(&data[data_start..data_end])?;
        }

        pos = align4(data_end);
    }
    Ok(())
}

fn strip_slash(s: &str) -> String {
    s.strip_prefix('/').unwrap_or(s).to_string()
}

fn read_str(b: &[u8]) -> String {
    let n = b.iter().position(|&c| c == 0).unwrap_or(b.len());
    String::from_utf8_lossy(&b[..n]).into()
}

fn hex32(b: &[u8]) -> Result<u32, QSLibError> {
    let s = String::from_utf8_lossy(b);
    u32::from_str_radix(&s, 16)
        .map_err(|e| QSLibError::ParseError(e.to_string()))
}

fn align4(n: usize) -> usize {
    (n + 3) & !3
}