include $(TOPDIR)/rules.mk

PKG_NAME:=leakwatcher
PKG_VERSION:=1.0
PKG_RELEASE:=1

PKG_MAINTAINER:=Sour999
PKG_LICENSE:=GPL-3.0

include $(INCLUDE_DIR)/package.mk

define Package/leakwatcher
  SECTION:=net
  CATEGORY:=Network
  TITLE:=OpenClash Leak Watcher
  DEPENDS:=+bash +coreutils +luci
endef

define Package/leakwatcher/description
  自动分析 OpenClash 兜底日志，生成 YAML 文件，用于国内/国际域名与 IP 分流。
endef

define Build/Compile
endef

define Package/leakwatcher/install
	$(INSTALL_DIR) $(1)/etc/leakwatcher
	$(INSTALL_BIN) ./files/etc/leakwatcher/leakwatcher.sh $(1)/etc/leakwatcher/leakwatcher.sh
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DATA) ./luci/controller/leakwatcher.lua $(1)/usr/lib/lua/luci/controller/leakwatcher.lua
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi
	$(INSTALL_DATA) ./luci/model/cbi/leakwatcher.lua $(1)/usr/lib/lua/luci/model/cbi/leakwatcher.lua
endef

$(eval $(call BuildPackage,leakwatcher))
