#!/system/bin/sh
clear
#========================================
#全局变量
RepositoryURL=https://github.com/qimgss/QSTools
RawURL="https://raw.githubusercontent.com/qimgss/QSTools"
KMIRemote="https://github.com/tiann/KernelSU"
KMI="${KMIRemote}/releases/latest/download"
Workdir=/data/QSTools
Logdir=${Workdir}/logs
Initdir=${Workdir}/init
DLLdir=${Workdir}/Dynamic/Link/Libraries
KMIdir="${Initdir}/KMI"
Version="20260509"
KernelVersion=$(cat /proc/version)
BuildAndroidVersion=$([[ $KernelVersion =~ android([0-9]+) ]] && echo "${BASH_REMATCH[1]}" || echo "未在内核版本中检测到安卓版本，你是不是忘记禁用SuSFS/UnameSpoofer了")


#命令变量
NowTime=$(date "+%Y年%m月%d日%H时%M分%S秒%3N毫秒")
CheckManufacturer=$(getprop ro.product.manufacturer)
CheckModel=$(getprop ro.product.model)
CheckVersion=$(getprop ro.build.version.release)
CheckKernel=$(cat /proc/version | awk -F '-' '{print $1}' | awk '{print $3}' | awk -F '.' '{print $1"."$2}')
CheckSlot=$(getprop ro.boot.slot_suffix)

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
Display(){
echo -e "$1"
}

DisplayMDT(){
cat <<EOF
$1
EOF
}

OutputLog(){
Display "$1" >> ${Logdir}/$2
}

ExportLog(){
Display ""
}

CreateWorkdir(){
mkdir ${Workdir} ${Logdir} ${Initdir} >> /dev/null 2<&1
chmod -R 777 ${Workdir}
}

FindBlock(){
local BlockEnters=$1
local BlockPath=$(find /dev/block/ -name "$BlockEnters" -type l -exec readlink {} \; 2>/dev/null | sort -u)
Display "${BlockPath}"
}

ExtractImage(){
#寻找镜像文件的实际所在位置
local BlockEnters=$1
local ImageOutdir=$2
FindBlock "$BlockEnters"
[ -z $ImageOutdir ] && local ImageOutdir="$Workdir/$Image"
dd if="${BlockPath}" of="${ImageOutdir}" bs=4M status=none && OutputLog "${NowTime} ->extract ${Image} success" "ExtractImage.log" || OutputLog "${NowTime} -> extract ${Image} failed" "ExtractImage.log"
}

#下载函数
Download(){
#标准的可输出日志的下载命令：
#Download SkipSSL "下载链接" "下载目录" && OutputLog "${NowTime} -> 文件名或简称 success" "指定的日志文件命令.log" || OutputLog "${NowTime} -> 文件名或简称 failed" "指定的日志文件名称.log"

    local SkipSSL=$1
    local URL=$2
    local Output=$3
    if [ "$SkipSSL" = "SkipSSL" ]; then
        curl --progress-bar -L -k -o "$Output" "$URL"
    else
        curl --progress-bar -L -o "$Output" "$URL"
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


mkdir ${KMIdir} >> /dev/null 2>&1

# 任务1: 下载 android12-5.10_kernelsu.ko
current_task=$((current_task + 1))
show_progress $current_task $total_tasks "KMI-12-5.10"
Download SkipSSL "${KMI}/android12-5.10_kernelsu.ko" "${KMIdir}/12-5.10_ksu.ko" >> /dev/null 2>&1
if [ $? -eq 0 ]; then
    OutputLog "${NowTime} -> download 12-5.10 success" "Pull_KMI.log"
else
    OutputLog "${NowTime} -> download 12-5.10 failed" "Pull_KMI.log"
    error_count=$((error_count + 1))
fi

# 任务2: 下载 android13-5.10_kernelsu.ko
current_task=$((current_task + 1))
show_progress $current_task $total_tasks "KMI-13-5.10"
Download SkipSSL "${KMI}/android13-5.10_kernelsu.ko" "${KMIdir}/13-5.10_ksu.ko" >> /dev/null 2>&1
if [ $? -eq 0 ]; then
    OutputLog "${NowTime} -> download 13-5.10 success" "Pull_KMI.log"
else
    OutputLog "${NowTime} -> download 13-5.10 failed" "Pull_KMI.log"
    error_count=$((error_count + 1))
fi

# 任务3: 下载 android13-5.15_kernelsu.ko
current_task=$((current_task + 1))
show_progress $current_task $total_tasks "KMI-13-5.15"
Download SkipSSL "${KMI}/android13-5.15_kernelsu.ko" "${KMIdir}/13-5.15_ksu.ko" >> /dev/null 2>&1
if [ $? -eq 0 ]; then
    OutputLog "${NowTime} -> download 13-5.15 success" "Pull_KMI.log"
else
    OutputLog "${NowTime} -> download13-5.15 failed" "Pull_KMI.log"
    error_count=$((error_count + 1))
fi

# 任务4: 下载 android14-5.15_kernelsu.ko
current_task=$((current_task + 1))
show_progress $current_task $total_tasks "KMI-14-5.15"
Download SkipSSL "${KMI}/android14-5.15_kernelsu.ko" "${KMIdir}/14-5.15_ksu.ko" >> /dev/null 2>&1
if [ $? -eq 0 ]; then
    OutputLog "${NowTime} -> download 14-5.15 success" "Pull_KMI.log"
else
    OutputLog "${NowTime} -> download 14-5.15 failed" "Pull_KMI.log"
    error_count=$((error_count + 1))
fi

# 任务5: 下载 android14-6.1_kernelsu.ko
current_task=$((current_task + 1))
show_progress $current_task $total_tasks "KMI-14-6.1"
Download SkipSSL "${KMI}/android14-6.1_kernelsu.ko" "${KMIdir}/14-6.1_ksu.ko" >> /dev/null 2>&1
if [ $? -eq 0 ]; then
    OutputLog "${NowTime} -> download 14-6.1 success" "Pull_KMI.log"
else
    OutputLog "${NowTime} -> download 14-6.1 failed" "Pull_KMI.log"
    error_count=$((error_count + 1))
fi

# 任务6: 下载 android15-6.6_kernelsu.ko
current_task=$((current_task + 1))
show_progress $current_task $total_tasks "KMI-15-6.6"
Download SkipSSL "${KMI}/android15-6.6_kernelsu.ko" "${KMIdir}/15-6.6_ksu.ko" >> /dev/null 2>&1
if [ $? -eq 0 ]; then
    OutputLog "${NowTime} -> download 15-6.6 success" "Pull_KMI.log"
else
    OutputLog "${NowTime} -> download15-6.6 failed" "Pull_KMI.log"
    error_count=$((error_count + 1))
fi

# 任务7: 下载 android16-6.12_kernelsu.ko
current_task=$((current_task + 1))
show_progress $current_task $total_tasks "KMI-16-6.12"
Download SkipSSL "${KMI}/android16-6.12_kernelsu.ko" "${KMIdir}/16-6.12_ksu.ko" >> /dev/null 2>&1
if [ $? -eq 0 ]; then
    OutputLog "${NowTime} -> download 16-6.12 success" "Pull_KMI.log"
else
    OutputLog "${NowTime} -> download 16-6.12 failed" "Pull_KMI.log"
    error_count=$((error_count + 1))
fi

# 任务8: 下载 APK文件
current_task=$((current_task + 1))
show_progress $current_task $total_tasks "KernelSU"
Download SkipSSL "${KMI}/KernelSU_v3.2.4_32457-release.apk" "/sdcard/ksu.apk" >> /dev/null 2>&1
if [ $? -eq 0 ]; then
    OutputLog "${NowTime} -> download ksu manager success" "Pull_KMI.log"
else
    OutputLog "${NowTime} -> download ksu manager failed" "Pull_KMI.log"
    error_count=$((error_count + 1))
fi

# 任务9: 移动APK文件
current_task=$((current_task + 1))
show_progress $current_task $total_tasks "移动APK文件"
mv "/sdcard/ksu.apk" "${KMIdir}/" 2>/dev/null

# 任务10: 解压和设置权限
current_task=$((current_task + 1))
show_progress $current_task $total_tasks "解压并设置权限"
unzip -j "${KMIdir}/ksu.apk" "lib/arm64-v8a/libksud.so" -d ${KMIdir}/ >> /dev/null 2>&1 && mv ${KMIdir}/libksud.so ${KMIdir}/ksud 2>/dev/null
rm -rf ${KMIdir}/ksu.apk 2>/dev/null
chmod -R 777 ${KMIdir} >> /dev/null 2>&1

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

ReadEnters(){
    local Title=$1
    local Title2=$2
    local Reads=$3
    Display "${Title}"
    while true; do
        Display "${ORANGE}${Title2}${NOCOLOR}"
    sleep 0.025
        read $Reads
        if [ -z "$Reads" ]; then
            Display "输入不能为空，请重新输入"
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
        Download "SkipSSL" "https://raw.githubusercontent.com/Kdufse/ABNToolbox/main/ABNToolbox.sh" ./QSTools.sh
        Display "${ORANGE}更新完成${NC}"
        if [ $? -eq 0 ]; then
            chmod 777 "./ABNToolbox.sh"
            sleep 1
            clear
            su -c "sh ./QSTools.sh"
        else
            Display "错误：.更新新版本 QSTools 失败！"
        fi
        ;;
        N|n|*)
        return 1
        ;;
    esac
else
    Display "当前为最新版本！"
    sleep 1
fi
}

DeviceInfo(){
Display "${PINK}品牌：${ORANGE}${CheckManufacturer}${NOCOLOR}
${PINK}机型：${YELLOW}${CheckModel}${NOCOLOR}
${PINK}内核版本：${CYAN}${CheckKernel}${NOCOLOR}
${PINK}安卓版本：${GREEN}${CheckVersion}${NOCOLOR}"
}

Initialization(){
if [ -d ${Initdir} ]; then
    Update
    MainMenu
else
    Display "初始化库文件中，请稍等..."
    Display "时长因网络环境而不同，请耐心稍等，如有需要可开启VPN"
    Init_Libraries
    Update
    MainMenu
fi
}

#HideRootEnvironment(){}

PatchKSUImage(){
clear
Display "${YELLOW}找到的KMI文件：${CYAN}"
find ${KMIdir}/*.ko -type f -exec basename {} \;
Display "${YELLOW}根据本机内核版本，建议你使用：${BuildAndroidVersion}-${CheckKernel}"
Display "输入方法：内核安卓版本+内核版本，如16-6.12"
Display "留空则退出脚本"
ReadEnters "" "请输入需要的KMI：" "KMIEnters"
cd ${KMIdir}
ReadEnters "" "请输入boot/init_boot的地址(留空自动提取)：" "ImageEnters"
local isInitboot=$(FindBlock init_boot${CheckSlot})
if [ -z $ImageEnters ]; then
    if [ -z $isInitboot ]; then
        ExtractImage "boot${CheckSlot}" "./Image.img"
        ./ksud boot-patch -b ./Image.img -m ${KMIEnters}_ksu.ko --magiskboot /data/adb/ksu/bin/magiskboot
    else
        ExtractImage "init_boot${CheckSot}" "./Image img"
        ./ksud boot-patch -b ./Image.img -m ${KMIEnters}_ksu.ko --magiskboot /data/adb/ksu/bin/magiskboot
    fi
else
    mv $ImageEnters ./Image.img
    ./ksud boot-patch -b ./Image.img -m ${KMIEnters}_ksu.ko --magiskboot /data/adb/ksu/bin/magiskboot
fi
}

MainMenu(){
Display "${CYAN}========================================${YELLOW}"
DisplayMDT '   ___  ____ _____           _     
  / _ \/ ___|_   _|__   ___ | |___ 
 | | | \___ \ | |/ _ \ / _ \| / __|
 | |_| |___) || | (_) | (_) | \__ \
  \__\_\____/ |_|\___/ \___/|_|___/
                                    '
Display "${CYAN}========================================${NOCOLOR}"
DeviceInfo
Display "如果脚本出现问题，请前往https://github.com/qimgss/QSTools/issues报告问题"
Display "${YELLOW}
1.隐藏Root环境        |
2.修补KSU镜像         |
3.配置隐藏应用列表    |
4.导出日志            |
5.退出脚本            |"
ReadEnters "" "请输入选项(1~5)：" "MainInputs"
case $MainInputs in
    1) HideRootEnvironment ;;
    2) PatchKSUImage ;;
    3) CfgHMA ;;
    4) ReportBugs ;;
    5) exit 1;;
    *) return 1 ;;
esac
}
CreateWorkdir
if [ -d ${Initdir} ]; then
    Display ""
    Update
    MainMenu
else
    Init_Libraries
    Update
    MainMenu
fi
