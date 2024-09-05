#!/bin/bash
# Download apkeep
get_artifact_download_url () {
    # Usage: get_download_url <repo_name> <artifact_name> <file_type>
    local api_url="https://api.github.com/repos/$1/releases/latest"
    local result=$(curl $api_url | jq ".assets[] | select(.name | contains(\"$2\") and contains(\"$3\") and (contains(\".sig\") | not)) | .browser_download_url")
    echo ${result:1:-1}
}

# Artifacts associative array aka dictionary
declare -A artifacts

artifacts["apkeep"]="EFForg/apkeep apkeep-x86_64-unknown-linux-gnu"
artifacts["apktool.jar"]="iBotPeaches/Apktool apktool .jar"

# Fetch all the dependencies
for artifact in "${!artifacts[@]}"; do
    if [ ! -f $artifact ]; then
        echo "Downloading $artifact"
        curl -L -o $artifact $(get_artifact_download_url ${artifacts[$artifact]})
    fi
done

chmod +x apkeep

# Download Azur Lane
if [ ! -f "com.bilibili.blhx.m4399.apk" ]; then
    echo "Get Azur Lane apk"

    # eg: wget "your download link" -O "your packge name.apk" -q
    #if you want to patch .xapk, change the suffix here to wget "your download link" -O "your packge name.xapk" -q
    wgetwget https://quinn.bzxa2.shop/personalc6af5d23171760b2b8bf1b829911c841/jpf01_1w3ych_yukaidi_com/_layouts/15/download.aspx?UniqueId=885cbe69-8bb0-4d28-a8b8-6443da96d908&Translate=false&tempauth=v1.eyJzaXRlaWQiOiJiODk4OWU3MS1hYjJhLTQwNzMtYjRiZi0zZmVmNjg2MTZiMTUiLCJhcHBfZGlzcGxheW5hbWUiOiJqcGYwMSIsImFwcGlkIjoiMDViZGMwOTQtZGQ3ZS00ZTNkLWE0OGQtYjE2ZjM5NzkyNDQ4IiwiYXVkIjoiMDAwMDAwMDMtMDAwMC0wZmYxLWNlMDAtMDAwMDAwMDAwMDAwLzF3M3ljaC1teS5zaGFyZXBvaW50LmNvbUBlODc4MjcyMC1jZDcxLTQ4ZGItOTM3YS1lYjY1M2FhNGIzNTEiLCJleHAiOiIxNzI1NTE5NjIzIn0.CgoKBHNuaWQSAjY0EgsI2qPGh8Lepj0QBRoOMjAuMTkwLjE0NC4xNzIqLGEvQ3UwSFFDRUpNZHNNL1ltV0lwMEMyOGl4LzdGNlFvV25uclBhSjlUelk9MJoBOAFCEKFNLx31oAAws0De-cPOGENKEGhhc2hlZHByb29mdG9rZW5yKTBoLmZ8bWVtYmVyc2hpcHwxMDAzMjAwMzdmY2YwMzRmQGxpdmUuY29tegEyggESCSAneOhxzdtIEZN662U6pLNRogEYanBmMDFAMXczeWNoLnl1a2FpZGkuY29tqgEQMTAwMzIwMDM3RkNGMDM0RrIBDmFsbGZpbGVzLndyaXRlyAEB.wsSuQd5jVfexlJxTVCWchyLywleCrPoPzgozrSi66Nc&ApiVersion=2.0 -O com.bilibili.blhx.m4399.apk -q
    echo "apk downloaded !"
    
    # if you can only download .xapk file uncomment 2 lines below. (delete the '#')
    #unzip -o com.bilibili.blhx.m4399.apk -d AzurLane
    #cp AzurLane/com.bilibili.blhx.m4399.apk .
fi

# Download Perseus
if [ ! -d "Perseus" ]; then
    echo "Downloading Perseus"
    git clone https://github.com/Egoistically/Perseus
fi

echo "Decompile Azur Lane apk"
java -jar apktool.jar -q -f d com.bilibili.blhx.m4399.apk

echo "Copy Perseus libs"
cp -r Perseus/. com.bilibili.blhx.m4399/lib/

echo "Patching Azur Lane with Perseus"
oncreate=$(grep -n -m 1 'onCreate' com.bilibili.blhx.m4399/smali_classes/com/unity3d/player/UnityPlayerActivity.smali | sed  's/[0-9]*\:\(.*\)/\1/')
sed -ir "s#\($oncreate\)#.method private static native init(Landroid/content/Context;)V\n.end method\n\n\1#" com.bilibili.blhx.m4399/smali_classes/com/unity3d/player/UnityPlayerActivity.smali
sed -ir "s#\($oncreate\)#\1\n    const-string v0, \"Perseus\"\n\n\    invoke-static {v0}, Ljava/lang/System;->loadLibrary(Ljava/lang/String;)V\n\n    invoke-static {p0}, Lcom/unity3d/player/UnityPlayerActivity;->init(Landroid/content/Context;)V\n#" com.bilibili.blhx.m4399/smali_classes/com/unity3d/player/UnityPlayerActivity.smali

echo "Build Patched Azur Lane apk"
java -jar apktool.jar -q -f b com.bilibili.blhx.m4399 -o build/com.bilibili.blhx.m4399.p.apk

echo "Set Github Release version"
s=($(./apkeep -a com.bilibili.blhx.m4399 -l))
echo "PERSEUS_VERSION=$(echo ${s[-1]})" >> $GITHUB_ENV
