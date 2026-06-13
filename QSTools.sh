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
Version="20260509"

#命令变量
NowTime=$(date "+%Y年%m月%d日%H时%M分%S秒%3N毫秒")
NowTime_NT=$(date "+%Y%m%d%H%M%S")
CheckManufacturer=$(getprop ro.product.manufacturer)
CheckModel=$(getprop ro.product.model)
CheckVersion=$(getprop ro.build.version.release)
CheckKernel=$(cat /proc/version | awk -F '-' '{print $1}' | awk '{print $3}' | awk -F '.' '{print $1"."$2}')
CheckSlot=$(getprop ro.boot.slot_suffix)
KernelVersion=$(cat /proc/version)
BuildAndroidVersion=$(echo "$KernelVersion" | grep -o 'android[0-9]\+' | grep -o '[0-9]\+' || echo "未在内核版本中检测到安卓版本，你是不是忘记禁用SuSFS/UnameSpoofer了")

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
echo "Model: ${CheckModel}
Manufacturer: ${CheckManufacturer}
Kernel: $(cat /proc/version | awk '{print $3}')
Build time: $(uname -v)
SDK: $(getprop ro.build.version.sdk)
Architecture: $(uname -m)
CPU: $(getprop ro.hardware)-$(getprop ro.board.platform)
Script path: $0
Script version: ${Version}" >>${Logdir}/baseinfo.log
zcat /proc/config.gz >> ${Logdir}/deconfig
cp -af $0 ${Logdir}/script.sh
zip -r ${ExportLogPath}/Report_${NowTime_NT}.zip ${Logdir}/
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
    Init_Libraries
    Update
    MainMenu
else
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
#标准的可输出日志的下载命令：
#Download SkipSSL "下载链接" "下载目录" && OutputLog "${NowTime} -> 文件名或简称 success" "指定的日志文件命令.log" || OutputLog "${NowTime} -> 文件名或简称 failed" "指定的日志文件名称.log"

    local SkipSSL=$1
    local URL=$2
    local Output=$3
    local Functions=""
    if [ "$SkipSSL" = "SkipSSL" ]; then
        local Functions='-k'
    fi
curl --progress-bar -L $Fucntions -o "$Output" "$URL"

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
Download SkipSSL "${KMI}/android12-5.10_kernelsu.ko" "${Filedir}/12-5.10_ksu.ko" >> /dev/null 2>&1
if [ $? -eq 0 ]; then
    OutputLog "${NowTime} -> download 12-5.10 success" "script.log"
else
    OutputLog "${NowTime} -> download 12-5.10 failed" "script.log"
    error_count=$((error_count + 1))
fi

current_task=$((current_task + 1))
show_progress $current_task $total_tasks "KMI-13-5.10"
Download SkipSSL "${KMI}/android13-5.10_kernelsu.ko" "${Filedir}/13-5.10_ksu.ko" >> /dev/null 2>&1
if [ $? -eq 0 ]; then
    OutputLog "${NowTime} -> download 13-5.10 success" "script.log"
else
    OutputLog "${NowTime} -> download 13-5.10 failed" "script.log"
    error_count=$((error_count + 1))
fi

current_task=$((current_task + 1))
show_progress $current_task $total_tasks "KMI-13-5.15"
Download SkipSSL "${KMI}/android13-5.15_kernelsu.ko" "${Filedir}/13-5.15_ksu.ko" >> /dev/null 2>&1
if [ $? -eq 0 ]; then
    OutputLog "${NowTime} -> download 13-5.15 success" "script.log"
else
    OutputLog "${NowTime} -> download13-5.15 failed" "script.log"
    error_count=$((error_count + 1))
fi

current_task=$((current_task + 1))
show_progress $current_task $total_tasks "KMI-14-5.15"
Download SkipSSL "${KMI}/android14-5.15_kernelsu.ko" "${Filedir}/14-5.15_ksu.ko" >> /dev/null 2>&1
if [ $? -eq 0 ]; then
    OutputLog "${NowTime} -> download 14-5.15 success" "script.log"
else
    OutputLog "${NowTime} -> download 14-5.15 failed" "script.log"
    error_count=$((error_count + 1))
fi

current_task=$((current_task + 1))
show_progress $current_task $total_tasks "KMI-14-6.1"
Download SkipSSL "${KMI}/android14-6.1_kernelsu.ko" "${Filedir}/14-6.1_ksu.ko" >> /dev/null 2>&1
if [ $? -eq 0 ]; then
    OutputLog "${NowTime} -> download 14-6.1 success" "script.log"
else
    OutputLog "${NowTime} -> download 14-6.1 failed" "script.log"
    error_count=$((error_count + 1))
fi

current_task=$((current_task + 1))
show_progress $current_task $total_tasks "KMI-15-6.6"
Download SkipSSL "${KMI}/android15-6.6_kernelsu.ko" "${Filedir}/15-6.6_ksu.ko" >> /dev/null 2>&1
if [ $? -eq 0 ]; then
    OutputLog "${NowTime} -> download 15-6.6 success" "script.log"
else
    OutputLog "${NowTime} -> download15-6.6 failed" "script.log"
    error_count=$((error_count + 1))
fi

current_task=$((current_task + 1))
show_progress $current_task $total_tasks "KMI-16-6.12"
Download SkipSSL "${KMI}/android16-6.12_kernelsu.ko" "${Filedir}/16-6.12_ksu.ko" >> /dev/null 2>&1
if [ $? -eq 0 ]; then
    OutputLog "${NowTime} -> download 16-6.12 success" "script.log"
else
    OutputLog "${NowTime} -> download 16-6.12 failed" "script.log"
    error_count=$((error_count + 1))
fi

current_task=$((current_task + 1))
show_progress $current_task $total_tasks "KernelSU"
Download SkipSSL "${KMI}/KernelSU_v3.2.4_32457-release.apk" "/sdcard/ksu.apk" >> /dev/null 2>&1
if [ $? -eq 0 ]; then
    OutputLog "${NowTime} -> download ksu manager success" "script.log"
else
    OutputLog "${NowTime} -> download ksu manager failed" "script.log"
    error_count=$((error_count + 1))
fi

current_task=$((current_task + 1))
show_progress $current_task $total_tasks "移动并解压APK"
cp "/sdcard/ksu.apk" "${Filedir}/" 2>/dev/null
unzip -j "${Filedir}/ksu.apk" "lib/arm64-v8a/libksud.so" -d ${Filedir}/ >> /dev/null 2>&1 && mv ${Filedir}/libksud.so ${Filedir}/ksud 2>/dev/null
rm -rf ${Filedir}/ksu.apk 2>/dev/null
chmod -R 777 ${Filedir} >> /dev/null 2>&1

current_task=$((current_task + 1))
show_progress $current_task $total_tasks "下载blkops"
Download SkipSSL "${RawURL}/binary/blkops" "/sdcard/libblkops.so" >> /dev/null 2>&1
if [ $? -eq 0 ]; then
    OutputLog "${NowTime} -> download blkops binary success" "script.log"
else
    OutputLog "${NowTime} -> download blkops binary failed" "script.log"
    error_count=$((error_count + 1))
fi
cp "/sdcard/libblkops.so" "${Workdir}/blkops" 2>/dev/null && rm -rf /sdcard/libblkops.so
chmod -R 777 ${Filedir} >> /dev/null 2>&1

current_task=$((current_task + 1))
show_progress $current_task $total_tasks "下载magiskboot"
Download SkipSSL "${RawURL}/binary/magiskboot" "/sdcard/magiskboot" >> /dev/null 2>&1
if [ $? -eq 0 ]; then
    OutputLog "${NowTime} -> download magiskboot binary success" "script.log"
else
    OutputLog "${NowTime} -> download magiskboot binary failed" "script.log"
    error_count=$((error_count + 1))
fi
cp "/sdcard/magiskboot" "${Workdir}/magiskboot" 2>/dev/null && rm -rf /sdcard/magiskboot
chmod -R 777 ${Filedir} >> /dev/null 2>&1

current_task=$((current_task + 1))
show_progress $current_task $total_tasks "下载jqlang"
Download SkipSSL "${RawURL}/binary/jq" "/sdcard/jq" >> /dev/null 2>&1
if [ $? -eq 0 ]; then
    OutputLog "${NowTime} -> download jq binary success" "script.log"
else
    OutputLog "${NowTime} -> download jq binary failed" "script.log"
    error_count=$((error_count + 1))
fi
cp "/sdcard/jq" "${Workdir}/jq" 2>/dev/null && rm -rf /sdcard/jq
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
        Download "SkipSSL" "${RawURL}/main/QSTools.sh" ./QSTools.sh
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
${PINK}内核版本：${CYAN}${CheckKernel}${NOCOLOR}
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
Print_Text "2" >> $ADBdir/zygisksu/denylist_enforce   #||排除列表策略                  仅还原挂载|
Print_Text "1" >> $ADBdir/zygisksu/memory_type      #|使用匿名内存                         开启|
Print_Text "1" >> $ADBdir/zygisksu/linker               #|使用 Zygisk Next 链接器            开启|
}
mkdir "${Workdir}/Modules"
Download SkipSSL "${RawURL}/Framework/StartInstall.sh" "${Workdir}/Modules/" && OutputLog "${NowTime} -> download StartInstall.sh success" "InstallModule.log" || OutputLog "${NowTime} -> download StartInstall.sh failed" "InstallModule.log"
Download SkipSSL "${RawURL}/Framework/Modules/ZygiskNext.zip" "${Workdir}/Modules/Modules/" && OutputLog "${NowTime} -> download ZygiskNext success" "InstallModule.log" || OutputLog "${NowTime} -> download ZygiskNext failed" "InstallModule.log"
Download SkipSSL "${RawURL}/Framework/Modules/LSPosed.zip" "${Workdir}/Modules/Modules/" && OutputLog "${NowTime} -> download LSPosed success" "InstallModule.log" || OutputLog "${NowTime} -> download LSPosed failed" "InstallModule.log"
if zcat /proc/config.gz | grep -wi CONFIG_KSU_SUSFS; then
    Download SkipSSL "https://github.com/sidex15/susfs4ksu-module/releases/latest/download/ksu_module_susfs_1.5.2+.zip" "${Workdir}/Modules/Modules/" && OutputLog "${NowTime} -> download SUSFS success" "InstallModule.log" || OutputLog "${NowTime} -> download SUSFS failed" "InstallModule.log"
else
    Download SkipSSL "${RawURL}/Framework/Modules/TrickyStore.zip" "${Workdir}/Modules/Modules/" && OutputLog "${NowTime} -> download TrickyStore success" "InstallModule.log" || OutputLog "${NowTime} -> download TrickyStore failed" "InstallModule.log"
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
    Download SkipSSL "$FileRefs/KernelSU.apk" "${Workdir}/"
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
    $blkops -d boot.img boot
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
magiskboot=${Workdir}/magiskboot
blkops=${Workdir}/blkops
if [ "CMD_SPACE" != "CMD" ]; then
    Print_Text "${YELLOW}找到的KMI文件：${CYAN}"
    find ${Filedir}/*.ko -type f -exec basename {} \;
    Print_Text "${YELLOW}根据本机内核版本，建议你使用：${BuildAndroidVersion}-${CheckKernel}"
    Print_Text "输入方法：内核安卓版本+内核版本，如16-6.12"
    Print_Text "留空则退出脚本"
    ReadEnters "" "请输入需要的KMI：" "KMIEnters"
    cd ${Filedir}
    ReadEnters "" "请输入boot/init_boot的地址(留空自动提取)：" "ImageEnters"
else
    ImageEnters=""
    KMIEnters="${BuildAndroidVersion}-${CheckKernel}"
fi
isInitboot=$(${Workdir}/blkops -s -p init_boot)
if [ -z $ImageEnters ]; then
    if $isInitboot | grep -qwi "Partition not found"; then
        ${Workdir}/blkops --dump "boot" "./Image.img"
        ./ksud boot-patch -b ./Image.img -m ${KMIEnters}_ksu.ko --magiskboot $magiskboot
        $blkops --write ./Image.img boot
    else
        ${Workdir}/blkops --dump "init_boot" "./Image.img"
        ./ksud boot-patch -b ./Image.img -m ${KMIEnters}_ksu.ko --magiskboot $magiskboot
        $blkops --write ./Image.img init_boot
    fi
else
    mv $ImageEnters ./Image.img
    ./ksud boot-patch -b ./Image.img -m ${KMIEnters}_ksu.ko --magiskboot $magiskboot
fi

}
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
Print_Text "如果脚本出现问题，请前往https://github.com/qimgss/QSTools/issues报告问题"
Print_Text "${YELLOW}
1.隐藏Root环境        |
2.KernelSU专区        |
3.导出日志            |
4.退出脚本            |"
ReadEnters "" "请输入选项(1~5)：" "MainInputs"
case $MainInputs in
    1) HideRootEnvironment ;;
    2) KSU_SA ;;
    3) ExportLog ;;
    4) ExitScript ;;
    *) return 1 ;;
esac
}

CreateWorkdir
Start
ExitScript

