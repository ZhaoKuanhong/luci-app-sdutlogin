include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-sdutlogin
PKG_VERSION=0.7
PKG_RELEASE:=5

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-sdutlogin
	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:=sdut Login for LuCI
	PKGARCH:=all
	DEPENDS:=+curl
endef

define Package/luci-app-sdutlogin/description
	sdut Login for LuCI.
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/luci-app-sdutlogin/install
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DIR) $(1)/etc/hotplug.d/iface
	$(INSTALL_DIR) $(1)/usr/lib/sdutlogin
	
	$(INSTALL_CONF) ./files/root/etc/config/sdutlogin $(1)/etc/config/sdutlogin
	$(INSTALL_BIN) ./files/root/etc/init.d/sdutlogin $(1)/etc/init.d/sdutlogin
	$(INSTALL_BIN) ./files/root/etc/hotplug.d/iface/100-sdutlogin $(1)/etc/hotplug.d/iface/100-sdutlogin
	$(INSTALL_BIN) ./login.sh $(1)/usr/lib/sdutlogin/login.sh

	$(INSTALL_DATA) ./files/root/usr/lib/lua/luci/controller/sdutlogin.lua $(1)/usr/lib/lua/luci/controller/sdutlogin.lua
	$(INSTALL_DATA) ./files/root/usr/lib/lua/luci/model/cbi/sdutlogin.lua $(1)/usr/lib/lua/luci/model/cbi/sdutlogin.lua
	$(INSTALL_DATA) ./files/root/usr/lib/lua/luci/model/cbi/sdutloginlog.lua $(1)/usr/lib/lua/luci/model/cbi/sdutloginlog.lua
endef

$(eval $(call BuildPackage,luci-app-sdutlogin))
