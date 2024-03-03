#!/bin/bash
#========================================================================================================================
# https://github.com/ophub/amlogic-s9xxx-openwrt
# Description: Automatically Build OpenWrt
# Function: Diy script (After Update feeds, Modify the default IP, hostname, theme, add/remove software packages, etc.)
# Source code repository: https://github.com/openwrt/openwrt / Branch: main
#========================================================================================================================

# ------------------------------- Main source started -------------------------------
#
# Add the default password for the 'root' user（Change the empty password to 'password'）
sed -i 's/root:::0:99999:7:::/root:$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.::0:99999:7:::/g' package/base-files/files/etc/shadow

# Set etc/openwrt_release
sed -i "s|DISTRIB_REVISION='.*'|DISTRIB_REVISION='R$(date +%Y.%m.%d)'|g" package/base-files/files/etc/openwrt_release
echo "DISTRIB_SOURCECODE='official'" >>package/base-files/files/etc/openwrt_release

# Modify default IP（FROM 192.168.1.1 CHANGE TO 192.168.31.4）
# sed -i 's/192.168.1.1/192.168.31.4/g' package/base-files/files/bin/config_generate
#
# ------------------------------- Main source ends -------------------------------

rm -rf feeds/luci/applications/luci-app-netdata
rm -rf luci/applications/luci-app-argon-config
rm -rf feeds/applications/luci-theme-argon
rm -rf luci/applications/luci-theme-argon
rm -rf feeds/applications/luci-app-argon-config
git clone -b 18.06 https://github.com/jerrykuku/luci-theme-argon.git luci-theme-argon
git clone -b 18.06 https://github.com/jerrykuku/luci-app-argon-config.git luci-app-argon-config
rm -rf feeds/luci/applications/luci-app-gowebdav
rm -rf feeds/packages/net/gowebdav
# git clone https://github.com/tty228/luci-app-serverchan.git package/uci-app-serverchan
git clone https://github.com/sirpdboy/luci-app-netdata package/luci-app-netdata

#svn co https://github.com/sbwml/openwrt_pkgs/trunk/luci-app-gowebdav package/luci-app-gowebdav
#svn co https://github.com/sbwml/openwrt_pkgs/trunk/gowebdav package/gowebdav
#git clone https://github.com/vernesong/OpenClash.git -b master --single-branch luci-app-openclash
function merge_package() {
        # 参数1是分支名,参数2是库地址,参数3是所有文件下载到指定路径。
        # 同一个仓库下载多个文件夹直接在后面跟文件名或路径，空格分开。
        if [[ $# -lt 3 ]]; then
        echo "Syntax error: [$#] [$*]" >&2
        return 1
        fi
        trap 'rm -rf "$tmpdir"' EXIT
        branch="$1" curl="$2" target_dir="$3" && shift 3
        rootdir="$PWD"
        localdir="$target_dir"
        [ -d "$localdir" ] || mkdir -p "$localdir"
        tmpdir="$(mktemp -d)" || exit 1
        git clone -b "$branch" --depth 1 --filter=blob:none --sparse "$curl" "$tmpdir"
        cd "$tmpdir"
        git sparse-checkout init --cone
        git sparse-checkout set "$@"
        # 使用循环逐个移动文件夹
        for folder in "$@"; do
        mv -f "$folder" "$rootdir/$localdir"
        done
        cd "$rootdir"
        }
        merge_package master https://github.com/sbwml/openwrt_pkgs package/openwrt-packages gowebdav luci-app-gowebdav 
        merge_package master https://github.com/messense/aliyundrive-webdav/tree/main/openwrt package/openwrt-packages aliyundrive-webdav luci-app-aliyundrive-webdav 
        merge_package master https://github.com/vernesong/OpenClash package/openwrt-packages luci-app-openclash
# 编译 po2lmo (如果有po2lmo可跳过)
pushd package/custom/luci-app-openclash/tools/po2lmo
make && sudo make install
popd
        
        # ------------------------------- Other started -------------------------------
#
# Add luci-app-amlogic
rm -rf package/luci-app-amlogic
git clone https://github.com/ophub/luci-app-amlogic.git package/luci-app-amlogic
#
# Apply patch
# git apply ../config/patches/{0001*,0002*}.patch --directory=feeds/luci
#
# ------------------------------- Other ends -------------------------------
