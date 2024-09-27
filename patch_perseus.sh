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
#download_azurlane () {
#    if [ ! -f "com.YoStarEN.AzurLane" ]; then
#    ./apkeep -a com.YoStarEN.AzurLane .
#    fi
#}

#if [ ! -f "com.YoStarEN.AzurLane" ]; then
#    echo "Get Azur Lane apk"
#    download_azurlane
#    unzip -o com.YoStarEN.AzurLane.xapk -d AzurLane
#    cp AzurLane/com.YoStarEN.AzurLane.apk .
#fi
# Manual download
if [ ! -f "com.YoStarEN.AzurLane" ]; then
    echo "Get Azur Lane apk"
    wget https://download1587.mediafire.com/jqlzykx615mgSQM9K6Nl7pMirqQ2CKKq7yw8D-xQml65PtT61JKkSyNqXm_jQ04UAhW3Tz8OX5F1Hx6MLqWyD7cNYpPpV0N-N1jKOkgnIsKW3q1McmxyGkR3ZNIZ5EOSJpbDtT-SKAVUUoVmgGSH-QGwOepx6hrUUaCyDPDxgkxKH_s/hg89kieh4o1l5bt/com.YoStarEN.AzurLane.apk -O com.YoStarEN.AzurLane.apk -q
    echo "apk downloaded !"
fi

# Download Perseus
if [ ! -d "Perseus" ]; then
    echo "Downloading Perseus"
    git clone https://github.com/Egoistically/Perseus
fi

echo "Decompile Azur Lane apk"
java -jar apktool.jar -q -f d com.YoStarEN.AzurLane.apk

echo "Copy Perseus libs"
cp -r Perseus/. com.YoStarEN.AzurLane/lib/

echo "Patching Azur Lane with Perseus"
oncreate=$(grep -n -m 1 'onCreate' com.YoStarEN.AzurLane/smali_classes2/com/unity3d/player/UnityPlayerActivity.smali | sed  's/[0-9]*\:\(.*\)/\1/')
sed -ir "s#\($oncreate\)#.method private static native init(Landroid/content/Context;)V\n.end method\n\n\1#" com.YoStarEN.AzurLane/smali_classes2/com/unity3d/player/UnityPlayerActivity.smali
sed -ir "s#\($oncreate\)#\1\n    const-string v0, \"Perseus\"\n\n\    invoke-static {v0}, Ljava/lang/System;->loadLibrary(Ljava/lang/String;)V\n\n    invoke-static {p0}, Lcom/unity3d/player/UnityPlayerActivity;->init(Landroid/content/Context;)V\n#" com.YoStarEN.AzurLane/smali_classes2/com/unity3d/player/UnityPlayerActivity.smali

echo "Build Patched Azur Lane apk"
java -jar apktool.jar -q -f b com.YoStarEN.AzurLane -o build/com.YoStarEN.AzurLane.patched.apk

echo "Set Github Release version"
s=($(./apkeep -a com.YoStarEN.AzurLane -l))
echo "PERSEUS_VERSION=$(echo ${s[-1]})" >> $GITHUB_ENV
