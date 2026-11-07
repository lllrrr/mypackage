include $(TOPDIR)/rules.mk

PKG_NAME:=frpmod
PKG_VERSION:=24
PKG_RELEASE:=2
PKGARCH:=all

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	TITLE:=frpmod for OpenWRT
	URL:=http://forums.mydigitallife.info/threads/50234
	DEPENDS:=
endef

define Package/$(PKG_NAME)/description
	frpmod is a modify frp config
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/$(PKG_NAME) $(1)/etc/init.d/$(PKG_NAME)
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
[ -x /etc/init.d/frpmod ] && /etc/init.d/frpmod enable
exit 0
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
