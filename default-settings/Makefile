include $(TOPDIR)/rules.mk

PKG_NAME:=default-settings
PKG_VERSION:=19
PKG_RELEASE:=2023.10.16
PKG_LICENSE:=GPLv3
PKG_LICENSE_FILES:=LICENSE

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=luci
  CATEGORY:=LuCI
  TITLE:=LuCI support for Default Settings
  PKGARCH:=all
  DEPENDS:=+kmod-ipt-raw +kmod-nf-nathelper +kmod-nf-nathelper-extra +luci-base +luci +@LUCI_LANG_zh-cn
endef

define Package/$(PKG_NAME)/description
	Language Support Packages.
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/zzz-default-settings $(1)/etc/uci-defaults/99-default-settings
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
