#!/bin/bash
#========================================================================================================================
# https://github.com/ophub/amlogic-s9xxx-openwrt
# Description: Automatically Build OpenWrt for Amlogic s9xxx tv box
# Function: Diy script (After Update feeds, Modify the default IP, hostname, theme, add/remove software packages, etc.)
# Source code repository: https://github.com/coolsnowwolf/lede / Branch: master
#========================================================================================================================

# ------------------------------- Main source started -------------------------------
#
# Modify default theme（FROM uci-theme-bootstrap CHANGE TO luci-theme-material）
# sed -i 's/luci-theme-bootstrap/luci-theme-material/g' ./feeds/luci/collections/luci/Makefile

# Add autocore support for armvirt
sed -i 's/TARGET_rockchip/TARGET_rockchip\|\|TARGET_armvirt/g' package/lean/autocore/Makefile

# Set etc/openwrt_release
sed -i "s|DISTRIB_REVISION='.*'|DISTRIB_REVISION='R$(date +%Y.%m.%d)'|g" package/lean/default-settings/files/zzz-default-settings
echo "DISTRIB_SOURCECODE='lede'" >>package/base-files/files/etc/openwrt_release

# Fix xfsprogs build error
sed -i 's|TARGET_CFLAGS += -DHAVE_MAP_SYNC.*|TARGET_CFLAGS += -DHAVE_MAP_SYNC $(if $(CONFIG_USE_MUSL),-D_LARGEFILE64_SOURCE)|' feeds/packages/utils/xfsprogs/Makefile

# Modify default IP（FROM 192.168.1.1 CHANGE TO 192.168.31.4）
# sed -i 's/192.168.1.1/192.168.31.4/g' package/base-files/files/bin/config_generate

# Replace the default software source
# sed -i 's#openwrt.proxy.ustclug.org#mirrors.bfsu.edu.cn\\/openwrt#' package/lean/default-settings/files/zzz-default-settings
#
# ------------------------------- Main source ends -------------------------------

# ------------------------------- Other started -------------------------------
#

rm -rf feeds/luci/applications/luci-app-netdata
rm -rf luci/applications/luci-app-argon-config
rm -rf feeds/applications/luci-theme-argon
rm -rf luci/applications/luci-theme-argon
rm -rf feeds/applications/luci-app-argon-config
git clone -b 18.06 https://github.com/jerrykuku/luci-theme-argon.git luci-theme-argon
git clone -b 18.06 https://github.com/jerrykuku/luci-app-argon-config.git luci-app-argon-config
rm -rf feeds/luci/applications/luci-app-gowebdav
rm -rf feeds/packages/net/gowebdav
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

# Add luci-app-amlogic
rm -rf package/luci-app-amlogic
git clone https://github.com/ophub/luci-app-amlogic.git package/luci-app-amlogic
#
# Apply patch
# git apply ../config/patches/{0001*,0002*}.patch --directory=feeds/luci
#
# ------------------------------- Other ends -------------------------------
