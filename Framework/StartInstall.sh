cd ./
rm -rf ./Modules/placeholder

if su -v | grep -qwi "magisk"; then
    Command="magisk --install-module"
elif su -v | grep -qwi "apatch"; then
    Command="apd module install"
elif su -v | grep -qwi "kernelsu"; then
    Command="ksud module install"
fi

find ./Modules/ -name "*.zip" -exec $Command {} \;
