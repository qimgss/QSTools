#!/system/bin/bash
clear
#========================================
#全局变量
RepositoryURL=https://github.com/qimgss/QSTools
RawURL="https://raw.githubusercontent.com/qimgss/QSTools"
KMIRemote="https://github.com/tiann/KernelSU"
KMI="${KMIRemote}/releases/latest/download"
FileRepo="https://github.com/qimgss/QSTools-File"
FileRefs="$FileRepo/raw/refs/main"
Workdir=/data/QSTools
Logdir=${Workdir}/logs
Initdir=${Workdir}/Files
Filedir=${Initdir}
Version="20260626"

#命令变量
NowTime=$(date "+%Y年%m月%d日%H时%M分%S秒%3N毫秒")
NowTime_NT=$(date "+%Y%m%d%H%M%S")
CheckManufacturer=$(getprop ro.product.manufacturer)
CheckModel=$(getprop ro.product.model)
CheckVersion=$(getprop ro.build.version.release)
CheckKernel=$(cat /proc/version | awk -F '-' '{print $1}' | awk '{print $3}' | awk -F '.' '{print $1"."$2}')
CheckSlot=$(getprop ro.boot.slot_suffix)
KernelVersion=$(cat /proc/version)
BuildKernelVersion=$(uname -r | sed -E 's/^([0-9]+\.[0-9]+)\.[0-9]+-android([0-9]+).*/\2-\1/')
BuildAndroidVersion=$(uname -r | sed -n 's/.*android\([0-9]\+\).*/\1/p')

#颜色变量
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
BLUE='\033[0;94m'
ORANGE='\033[38;2;255;165;0m'  
CYAN='\033[0;96m'
PINK='\033[0;95m'
NOCOLOR='\033[0m'

# 命令变量
magiskboot="${Workdir}/magiskboot"
blkops="${Workdir}/blkops"
ksud="/data/adb/ksud"

#显示函数
Print_Text(){ # 显示文字
echo -e "$1"
}

MDT_Print_Text(){ # 强制显示文字
cat <<EOF
$1
EOF
}

OutputLog(){
Print_Text "$1" >> ${Logdir}/$2
}

ExportLog(){
ReadEnters "" "请输入导出报告的地址：" "ExportLogPath"
if [ -z ${ExportLogPath} ]; then
    Print_Text "未输入报告导出地址，默认导出至：${Logdir}"
    ExportLogPath=${Logdir}
fi
CheckTerminal
CheckRoot
echo "Model: ${CheckModel}
Manufacturer: ${CheckManufacturer}
Kernel: $(cat /proc/version | awk '{print $3}')
Build time: $(uname -v)
SDK: $(getprop ro.build.version.sdk)
Architecture: $(uname -m)
CPU: $(getprop ro.hardware)-$(getprop ro.board.platform)
Script path: $0
Script version: ${Version}
Root Environment: ${RootEnv}
Terminal: ${TerminalType}" >>${Logdir}/baseinfo.log
zcat /proc/config.gz >> ${Logdir}/defconfig
cp -af $0 ${Logdir}/script.sh
tar -czvf ${ExportLogPath}/Report_${NowTime_NT}.tar.gz -C ${Logdir}/ * 
}

CreateWorkdir(){
mkdir ${Workdir} ${Logdir} ${Initdir} >> /dev/null 2>&1
chmod -R 777 ${Workdir}
}

Start(){
Print_Text "${NowTime} -> 脚本开始运行" >> ${Logdir}/script.log

if [ -d ${Initdir} ]; then
    Print_Text ""
    Update
    clear
    MainMenu
elif [ -f ${Workdir}/updated ]; then
    CreateWorkdir
    Init_Libraries
    Update
    MainMenu
else
    CreateWorkdir
    Init_Libraries
    Update
    MainMenu
fi
}

ExitScript(){
Print_Text "${NowTime} -> 脚本结束运行" >> ${Logdir}/script.log
exit >> /dev/null 2>&1
}

#下载函数
Download(){
#标准的下载命令：
#Download SkipSSL LO "下载链接" "下载目录" "文件名称" "日志名称"
# 或者
#Download SkipSSL NLO "下载链接" "下载目录"

    local SkipSSL=$1
    local LogOutput=$2
    local URL=$3
    local Output=$4
    local FileName=$5
    local LogName=$6
    local Functions=""
    if [ "$SkipSSL" = "SkipSSL" ]; then
        local Functions='-k'
    fi
    if [ "$LogOutput" = "LO" ]; then
        curl --progress-bar -L $Fucntions -o "$Output" "$URL" "${FileName} success" "${LogName}.log" || OutputLog "${NowTime} -> Download ${FileName} failed" "${LogName}.log"
    elif [ "$LogOutput" = "NLO" ]; then
        curl --progress-bar -L $Fucntions -o "$Output" "$URL"
    elif [ -z $LogOutput]; then
        Print_Text "Inputs参数错误"
        ExitScript
    fi
}

Init_Libraries(){
save_cursor() {
    printf "\033[s"
}

restore_cursor() {
    printf "\033[u"
}

clear_to_end() {
    printf "\033[K"
}

show_progress() {
    current=$1
    total=$2
    msg=$3
    
    # 计算百分比
    percent=$((current * 100 / total))
    
    # 绘制进度条
    bar="["
    bar_length=20
    filled=$((current * bar_length / total))
    
    i=0
    while [ $i -lt $bar_length ]; do
        if [ $i -lt $filled ]; then
            bar="${bar}█"
        else
            bar="${bar}░"
        fi
        i=$((i + 1))
    done
    bar="${bar}]"
    
    # 移动到第一行并显示进度
    printf "\033[1;1H"
    clear_to_end
    printf "初始化进度: %s %3d%% - %s\n" "$bar" "$percent" "$msg"
}

# 初始化显示
clear
printf "\n"

# 保存光标位置（在第3行）
printf "\033[3;1H"
save_cursor

total_tasks=10
current_task=0
error_count=0


mkdir ${Filedir} >> /dev/null 2>&1
current_task=$((current_task + 1))
show_progress $current_task $total_tasks "KMI-12-5.10"
Download SkipSSL LO "${KMI}/android12-5.10_kernelsu.ko" "${Filedir}/12-5.10_ksu.ko" "Android12-5.10 KernelModule" "Initation"

current_task=$((current_task + 1))
show_progress $current_task $total_tasks "KMI-13-5.10"
Download SkipSSL LO "${KMI}/android13-5.10_kernelsu.ko" "${Filedir}/13-5.10_ksu.ko" "Android13-5.10 KernelModule" "Initation"

current_task=$((current_task + 1))
show_progress $current_task $total_tasks "KMI-13-5.15"
Download SkipSSL LO "${KMI}/android13-5.15_kernelsu.ko" "${Filedir}/13-5.15_ksu.ko" "Android13-5.15 KernelModule" "Initation"

current_task=$((current_task + 1))
show_progress $current_task $total_tasks "KMI-14-5.15"
Download SkipSSL LO "${KMI}/android14-5.15_kernelsu.ko" "${Filedir}/14-5.15_ksu.ko" "Android14-5.15 KernelModule" "Initation"

current_task=$((current_task + 1))
show_progress $current_task $total_tasks "KMI-14-6.1"
Download SkipSSL LO "${KMI}/android14-6.1_kernelsu.ko" "${Filedir}/14-6.1_ksu.ko" "Android14-6.1 KernelModule" "Initation"

current_task=$((current_task + 1))
show_progress $current_task $total_tasks "KMI-15-6.6"
Download SkipSSL LO "${KMI}/android15-6.6_kernelsu.ko" "${Filedir}/15-6.6_ksu.ko" "Android15-6.6 KernelModule" "Initation"

current_task=$((current_task + 1))
show_progress $current_task $total_tasks "KMI-16-6.12"
Download SkipSSL LO "${KMI}/android16-6.12_kernelsu.ko" "${Filedir}/16-6.12_ksu.ko" "Android16-6.12 KernelModule" "Initation"

current_task=$((current_task + 1))
show_progress $current_task $total_tasks "KernelSU"
Download SkipSSL LO "${KMI}/KernelSU_v3.2.4_32457-release.apk" "/sdcard/ksu.apk" "KernelSU APK" "Initation"
cp "/sdcard/ksu.apk" "${Filedir}/" 2>/dev/null
unzip -j "${Filedir}/ksu.apk" "lib/arm64-v8a/libksud.so" -d ${Filedir}/ >> /dev/null 2>&1 && mv ${Filedir}/libksud.so ${Filedir}/ksud 2>/dev/null
rm -rf ${Filedir}/ksu.apk 2>/dev/null
chmod -R 777 ${Filedir} >> /dev/null 2>&1

current_task=$((current_task + 1))
show_progress $current_task $total_tasks "下载blkops"
Download SkipSSL LO "${RawURL}/binary/blkops" "/sdcard/blkops" "BlockOperations" "Initation"
cp "/sdcard/libblkops" "${Workdir}/blkops" 2>/dev/null && rm -rf /sdcard/libblkops
chmod -R 777 ${Filedir} >> /dev/null 2>&1

current_task=$((current_task + 1))
show_progress $current_task $total_tasks "下载magiskboot"
Download SkipSSL LO "${RawURL}/binary/magiskboot" "/sdcard/magiskboot" "MagiskBoot" "Initation"
cp "/sdcard/magiskboot" "${Workdir}/magiskboot" 2>/dev/null && rm -rf /sdcard/magiskboot
chmod -R 777 ${Filedir} >> /dev/null 2>&1

# 显示最终结果
printf "\033[1;1H"
clear_to_end
printf "初始化进度: [████████████████████] 100%% - 完成！\n"
restore_cursor
clear_to_end

if [ $error_count -eq 0 ]; then
    printf "初始化完成\n"
else
    printf "⚠ 初始化失败，%d 个文件拉取失败\n" "$error_count"
fi
}

CheckKSU(){
if lsmod | grep -q '^kernelsu'; then
    KSU_MODE="LKM"
elif [ -r /proc/config.gz ] && zcat /proc/config.gz | grep -q '^CONFIG_KSU=y$'; then
    KSU_MODE="GKI"
else
    echo "KernelSU working mode unknow"
    exit 1
fi
}

CheckTerminal(){
if command -v pkg >/dev/null 2>&1; then
    TerminalType="Termux"
    SUCommand="$(su -v)"
elif command -v su2 >/dev/null 2>&1 && command -v su >/dev/null 2>&1; then
    TerminalType="MT-Extra"
    SUCommand="$(su2 -v)"
elif command -v su >/dev/null 2>&1; then
    TerminalType="System"
    SUCommand="$(su -v)"
else
    unset Terminal
fi
}

CheckRoot(){
if [ -r /proc/config.gz ] && zcat /proc/config.gz | grep -q '^CONFIG_KSU=y$'; then
    RootType='KernelSU (GKI)'
elif lsmod | grep -q '^kernelsu'; then
    RootType='KernelSU (LKM)'
elif echo "$SUCommand" | grep -q "APatch"; then
    RootType='APatch'
elif echo "$SUCommand" | grep -q "Magisk"; then
    RootType='Magisk'
elif echo "$SUCommand" | grep -qi "alpha"; then
    RootType='Magisk Alpha'
elif echo "$SUCommand" | grep -qi "kitsune" || grep -qi "delta"; then
    RootType='Kitsune Mask'
fi

RootVersion="$(su -V)"
RootEnv="${RootType}-${RootVersion}"
}

ReadEnters(){
    local Title=$1
    local Title2=$2
    local Reads=$3
    Print_Text "${Title}"
    while true; do
        Print_Text "${ORANGE}${Title2}${NOCOLOR}"
    sleep 0.025
        read $Reads
        if [ -z "$Reads" ]; then
            Print_Text "输入不能为空，请重新输入"
    sleep 0.025
        else
            break
        fi
    done
}

Update(){
curl -s "$RawURL/main/version" -o $Workdir/version

Remote_Version=$(cat $Workdir/version | tr -d '\n' | tr -d ' ')

if [ "${Version}" -lt "${Remote_Version}" ]; then
    ReadEnters "检测到新版本：$Remote_Version" "是否更新(Y/n)：" "UpdateEnters"

    case $UpdateInput in
        Y|y)
        Download SkipSSL LO "${RawURL}/main/QSTools.sh" ./QSTools.sh "MainScript" "Update"
        Print_Text "${ORANGE}更新完成${NC}"
        if [ $? -eq 0 ]; then
            chmod 777 "./QSTools.sh"
            sleep 1
            clear
            touch ${Workdir}/updated
            su -c "bash ./QSTools.sh"
        else
            Print_Text "错误：.更新新版本 QSTools 失败！"
        fi
        ;;
        N|n|*)
        return 1
        ;;
    esac
else
    Print_Text "当前为最新版本！"
    sleep 1
fi
}

DeviceInfo(){
Print_Text "${PINK}品牌：${ORANGE}${CheckManufacturer}${NOCOLOR}
${PINK}机型：${YELLOW}${CheckModel}${NOCOLOR}
${PINK}内核版本：${CYAN}${CheckKernel}-Android${BuildAndroidVersion}${NOCOLOR}
${PINK}安卓版本：${GREEN}${CheckVersion}${NOCOLOR}"
}

Initialization(){
if [ -d ${Initdir} ]; then
    Update
    MainMenu
else
    Print_Text "初始化库文件中，请稍等..."
    Print_Text "时长因网络环境而不同，请耐心稍等，如有需要可开启VPN"
    Init_Libraries
    Update
    MainMenu
fi
}

HideRootEnvironment(){
ADBdir="/data/adb"
ConfigureZygiskNext(){
Print_Text "2" >> $ADBdir/zygisksu/denylist_enforce   #|排除列表策略                    仅还原挂载|
Print_Text "1" >> $ADBdir/zygisksu/memory_type        #|使用匿名内存                         开启|
Print_Text "1" >> $ADBdir/zygisksu/linker             #|使用 Zygisk Next 链接器              开启|
} 
mkdir "${Workdir}/Modules"
Download SkipSSL LO "${RawURL}/Framework/StartInstall.sh" "${Workdir}/Modules/" "StartInstall.sh" "InstallModule.log"
Download SkipSSL LO "${RawURL}/Framework/Modules/ZygiskNext.zip" "${Workdir}/Modules/Modules/" "ZygiskNext" "InstallModule.log"
Download SkipSSL LO "${RawURL}/Framework/Modules/LSPosed.zip" "${Workdir}/Modules/Modules/" "LSPosed" "InstallModule.log"
if zcat /proc/config.gz | grep -wi CONFIG_KSU_SUSFS; then
    Download SkipSSL LO "https://github.com/sidex15/susfs4ksu-module/releases/latest/download/ksu_module_susfs_1.5.2+.zip" "${Workdir}/Modules/Modules/" "SUSFS" "InstallModule.log"
else
    Download SkipSSL LO "${RawURL}/Framework/Modules/TrickyStore.zip" "${Workdir}/Modules/Modules/" "TrickyStore" "InstallModule.log"
fi
su -c "sh ${Workdir}/Modules/StartInstall.sh"
ConfigureZygiskNext
}

KSU_SA(){
clear
Print_Text "${CYAN}========================================${YELLOW}"

cat << 'EOF'
  _  ______  _   _   ____    _    
 | |/ / ___|| | | | / ___|  / \   
 | ' /\___ \| | | | \___ \ / _ \  
 | . \ ___) | |_| |  ___) / ___ \ 
 |_|\_\____/ \___/  |____/_/   \_\
                                  
EOF
Print_Text "${CYAN}========================================${YELLOW}"
Print_Text "1.KSU正式转dev版"
Print_Text "2.修补KSU镜像"
Print_Text "3.返回主界面"
ReadEnters "" "请输入选项(1~3)：" "KSU_SA_Enters"
case $KSU_SA_Enters in
    1) KsuReleaseConvertDev ;;
    2) PatchKSUImage "nol" ;;
    3) MainMenu ;;
    *) MainMenu ;;
esac

KsuReleaseConvertDev(){
Print_Text "正在转dev..."
cd /data/adb
if pm list packages | cut -d':' -f2 | grep -qow com.weishu.kernelsu; then
   if pm list packages | cut -d':' -f2 | grep -qow com.weishu.kernelsu.dev; then
       DEV_APP=y
   else
       DEV_APP=n
   fi
fi

echo "Downloading Dev Version KernelSU"
if [ "$DEV_APP" = "n" ]; then
    Print_Text "正在下载最新KernelSU Dev APK"
    Download SkipSSL LO "$FileRefs/KernelSU.apk" "${Workdir}/"
    pm install -r "${Workdir}/KernelSU.apk"
fi
DEV_LIB="$(pm path me.weishu.kernelsu.dev | cut -d':' -f2)/lib/arm64"
cp $DEV_LIB ${Workdir}/
CheckKSU
if [ "KSU_MODE" = "LKM" ]; then
    PatchKSUImage "CMD"
elif [ "KSU_MODE" = "GKI" ]; then
    blkops="${Workdir}/blkops"
    $blkops -d boot boot.img
    pm uninstall me.weishu.kernelsu
    $blkops -w boot.img boot
    rm -rf boot.img
fi
}


KSU_Supported_Check(){
kver=${CheckKernel}
if [[ $(printf "%d%02d" $(echo "$kver" | cut -d'-' -f1 | tr '.' ' ')) -lt 5010 ]]; then
    echo "kernel < 5.10"
fi
}

PatchKSUImage(){
clear
local CMD_SPACE=$1
if [ "CMD_SPACE" != "CMD" ]; then
    Print_Text "${YELLOW}找到的KMI文件：${CYAN}"
    find ${Filedir}/*.ko -type f -exec basename {} \;
    Print_Text "${YELLOW}根据本机内核版本，建议你使用：${BuildKernelVersion}-${CheckKernel}"
    Print_Text "输入方法：内核安卓版本+内核版本，如16-6.12"
    Print_Text "留空则退出脚本"
    ReadEnters "" "请输入需要的KMI：" "KMIEnters"
    cd ${Filedir}
    ReadEnters "" "请输入boot/init_boot的地址(留空自动提取)：" "ImageEnters"
else
    ImageEnters=""
    KMIEnters="${BuildKernelVersion}-${CheckKernel}"
fi
isInitboot=$(${Workdir}/blkops -s init_boot -p)
if [ -z $ImageEnters ]; then
    if $isInitboot | grep -qwi "Partition not found"; then
        ${Workdir}/blkops --dump "boot" "./Image.img"
        $ksud boot-patch -b ./Image.img -m ${KMIEnters}_ksu.ko --magiskboot $magiskboot
        $blkops --write ./Image.img boot
    else
        ${Workdir}/blkops --dump "init_boot" "./Image.img"
        $ksud boot-patch -b ./Image.img -m ${KMIEnters}_ksu.ko --magiskboot $magiskboot
        $blkops --write ./Image.img init_boot
    fi
else
    mv $ImageEnters ./Image.img
    $ksud boot-patch -b ./Image.img -m ${KMIEnters}_ksu.ko --magiskboot $magiskboot
    $blkops --write ./Image.img init_boot
fi

}
}

FlashArea(){
FlashImage(){
ReadEnters "" "请输入Image的路径：" "ImagePath"
ReadEnters "" "请输入需要刷写的分区" "TargetPart"
$blkops -w $ImagePath $TargetPart
}

FlashKernel(){
ReadEnters "" "请输入内核镜像的路径：" "KernelPath"
Print_Text "内核镜像路径：$KernelPath"
$blkops -d boot boot.img
$magiskboot unpack boot.img
cp $KernelPath ./
$magiskboot repack boot.img
$blkops -w boot.img boot
rm -rf ramdisk.cpio
rm -rf kernel
rm -rf boot.img
rm -rf new-boot.img
Print_Text "刷写完成."

}

clear
Print_Text "${CYAN}========================================${YELLOW}"
Print_Text "${YELLOW}1.刷写镜像
2.刷写内核
3.返回主菜单"
ReadEnters "" "请输入选项(1~3)：" "FlashAreaInputs"
case $FlashAreaInputs in
    1) FlashImage ;;
    2) FlashKernel ;;
    3) MainMenu ;;
esac

}

ConvertRoot(){
clear
Github="https://github.comm"
Print_Text "${CYAN}========================================${YELLOW}"
Print_Text "1.Magisk
2.APatch
3.KernelSU"
ReadEnters "" "请输入当前的Root实现方式，当前为${RootType}(留空自动选择${RootType})：" "ConvertRootInputs"
if [ -z $ConvertRootInputs ]; then
    CurrentRoot="${RootType}"
fi
Print_Text "${CYAN}========================================${YELLOW}"
Print "1.Magisk
2.APatch 
3.FolkPatch
4.KernelSU
5.KernelSU-Next
6.SukiSU-Ultra"
# 7.ReSukiSU
ReadEnters "" "请输入需要转换的Root实现方式：" "ConvertTargetRootInputs"
[ ! -d ${Workdir}/ConvertSpaces ] && mkdir ${Workdir}/ConvertSpaces && ConvertSpaces="${Workdir}/ConvertSpaces"
isInitboot=$($blkops -s init_boot -p)
if $isInitboot | grep -qwi "Partition not found"; then
    $blkops -d boot ${ConvertSpaces}/Image.img
    TargetPartition="boot"
else
    $blkops -d init_boot ${ConvertSpaces}/Image.img
    TargetPartition="init_boot"
fi
[ ! -d ${ConvertSpaces}/current ] && mkdir ${ConvertSpaces}/current
[ ! -d ${ConvertSpaces}/target ] && mkdir ${ConvertSpaces}/target

case $ConvertRootInputs in
    1)
        Download SkipSSL LO "$Github/topjohnwu/Magisk/releases/latest/download/app-debug.apk" "${ConvertSpaces}/magisk.apk" "Magisk.apk" "ConvertRoot"
        unzip ${ConvertSpaces}/magisk.apk ${ConvertSpaces}/target
        ${ConvertSpaces}/target/assets/uninstaller.sh
    ;;
    2)
        Download SkipSSL LO "$Github/bmax121/KernelPatch/releases/latest/download/kptools-android" "${ConvertSpaces}/target/kptools" "KPTools" "ConvertRoot"
        $magiskboot unpack ${ConvertSpaces}/Image.img
        mv ${ConvertSpaces}/kernel ${ConvertSpaces}/kernel.patched
        ${ConvertSpaces}/target/kptools --unpatch --image "${ConvertSpaces}/kernel.patched" --out ${ConvertSpaces}/kernel
        $magiskboot repack ${ConvertSpaces}/Image.img
        mv ${ConvertSpaces}/new-boot.img ${ConvertSpaces}/kernelpatch.img
        $blkops -w ${ConvertSpaces}/kernelpatch.img $TargetPartition 
    ;;
    3)
        ReadEnters "" "你需要保留模块吗？(Y/n)" "KeepModules"
        case $KeepModules in
            1)
                $ksud boot-restore --boot ${ConvertSpaces}/Image.img --magiskboot $magiskboot --out ${ConvertSpaces}/ksu.img
                $blkops -w ${ConvertSpaces}/ksu.img $TargetPartition
            ;;
            2)
                $ksud boot-restore --boot ${ConvertSpaces}/Image.img --magiskboot $magiskboot --out ${ConvertSpaces}/ksu.img
                rm -rf /data/adb && mkdir /data/adb
                $blkops -w ${ConvertSpaces}/ksu.img $TargetPartition
            ;;
        esac
    ;;
esac

case $ConvertTargetRootInputs in
    1)
        Download SkipSSL LO "$Github/topjohnwu/Magisk/releases/latest/download/app-debug.apk" "${ConvertSpaces}/magisk.apk" "Magisk.apk" "ConvertRoot"
        unzip ${ConvertSpaces}/magisk.apk ${ConvertSpaces}/target
        ${ConvertSpaces}/target/assets/boot_patch.sh ${ConvertSpaces}/Image.img
        $blkops -w new-boot.img $TargetPartition
    ;;
    2|3)
        ReadEnters "" "请输入超级密钥：" "SuperKey"
        ReadEnters "" "需要将超级密钥保存在本机吗？(Y/n)" "SaveSuperKeyInLocalHost"
        case $SaveSuperKeyInLocalHost in
            Y|y) Print_Text "${SuperKey}" > ${Workdir}SuperKey ;;
            N|n) Print_Text "你选择了不保存在本机" ;;
        esac

        Download SkipSSL LO "$Github/bmax121/KernelPatch/releases/latest/download/kptools-android" "${ConvertSpaces}/target/kptools" "KPTools" "ConvertRoot"
        Download SkipSSL LO "$Github/bmax121/KernelPatch/releases/latest/download/kpimg-android" "${ConvertSpaces}/target/kpimg" "KPImg" "ConvertRoot"
        $magiskboot unpack ${ConvertSpaces}/Image.img
        mv ${ConvertSpaces}/kernel ${ConvertSpaces}/kernel.original
        ${ConvertSpaces}/target/kptools --patch --image "${ConvertSpaces}/kernel.original" --kpimg "${ConvertSpaces}/target/kpimg" --root-skey "$SuperKey" --out ${ConvertSpaces}/kernel
        $magiskboot repack ${ConvertSpaces}/Image.img
        mv ${ConvertSpaces}/new-boot.img ${ConvertSpaces}/kernelpatch.img
        $blkops -w ${ConvertSpaces}/kernelpatch.img $TargetPartition
    ;;
    4|5|6)
        case ConvertTargetRootInputs in
            4) KernelSU_SC="$Github/tiann/KernelSU" ;;
            5) KernelSU_SC="$Github/KernelSU-Next/KernelSU-Next" ;;
            6) KernelSU_SC="$Github/SukiSU-Ultra/SukiSU-Ultra" ;;
            # 7) KernelSU_SC="$Github/ReSukiSU/ReSukiSU" ;;
        esac
        Download SkipSSL LO "${KernelSU_SC}/releases/latest/android${BuildKernelVersion}_kernelsu.ko" "${ConvertSpaces}/target/kernelsu.ko" "KernelSU LKM Module" "ConvertRoot"
        $ksud boot-patch --boot "${ConvertSpaces}/Image.img" --magiskboot "${magiskboot}" --module "${ConvertSpaces}/target/kernelsu.ko" --out-name ${ConvertSpaces}/target/ksu.img
        $blkops -w ${ConvertSpaces}/ksu.img $TargetPartition
    ;;
esac
rm -rf $ConvertSpaces && Print_Text "转换空间清理完成"

}

MainMenu(){
Print_Text "${CYAN}========================================${YELLOW}"
MDT_Print_Text '   ___  ____ _____           _     
  / _ \/ ___|_   _|__   ___ | |___ 
 | | | \___ \ | |/ _ \ / _ \| / __|
 | |_| |___) || | (_) | (_) | \__ \
  \__\_\____/ |_|\___/ \___/|_|___/
                                    '
Print_Text "${CYAN}========================================${NOCOLOR}"
DeviceInfo
CheckTerminal && Print_Text "当前终端：${TerminalType}"
CheckRoot && Print_Text "Root实现方式：${RootEnv}"
Print_Text "如果脚本出现问题，请前往https://github.com/qimgss/QSTools/issues报告问题"
Print_Text "${YELLOW}
| 1.隐藏Root环境        | 6.退出脚本
| 2.KernelSU专区        |
| 3.导出日志            |
| 4.刷写区              |
| 5.转换Root            |"
ReadEnters "" "请输入选项(1~5)：" "MainInputs"
case $MainInputs in
    1) HideRootEnvironment ;;
    2) KSU_SA ;;
    3) ExportLog ;;
    4) FlashArea ;;
    5) ConvertRoot ;;
    6) ExitScript ;;
    *) ExitScript ;;
esac
}
Start
ExitScript

