RELEASE ?= $(shell date +%Y%m%d%H%M)
KERNEL_EXTRAVERSION ?= -rockchip-ayufan-$(RELEASE)
KERNEL_DEFCONFIG ?= rockchip_linux_defconfig

BOARD ?= rk3328-rock64

export KDEB_PKGVERSION=$(RELEASE)~ayufan

KERNEL_MAKE ?= make \
	EXTRAVERSION=$(KERNEL_EXTRAVERSION) \
	ARCH=arm64 \
	HOSTCC=aarch64-linux-gnu-gcc \
	CROSS_COMPILE="ccache aarch64-linux-gnu-"

KERNEL_RELEASE ?= $(shell $(KERNEL_MAKE) -s kernelversion)

.config: arch/arm64/configs/$(KERNEL_DEFCONFIG)
	$(KERNEL_MAKE) $(KERNEL_DEFCONFIG)

version:
	@$(KERNEL_MAKE) -s kernelversion

.PHONY: info
info: .config
	@$(KERNEL_MAKE) -s kernelrelease

.PHONY: kernel-menuconfig
kernel-menuconfig:
	$(KERNEL_MAKE) $(DEFCONFIG)
	$(KERNEL_MAKE) HOSTCC=gcc menuconfig
	$(KERNEL_MAKE) savedefconfig
	mv defconfig arch/arm64/configs/$(KERNEL_DEFCONFIG)

.PHONY: kernel-image
kernel-image:
	$(KERNEL_MAKE) Image dtbs -j$$(nproc)

.PHONY: kernel-modules
kernel-image-and-modules:
	$(KERNEL_MAKE) Image modules dtbs -j$$(nproc)
	$(KERNEL_MAKE) modules_install INSTALL_MOD_PATH=$(CURDIR)/out/linux_modules

.PHONY: kernel-package
kernel-package: .config
	$(KERNEL_MAKE) bindeb-pkg -j$$(nproc)

.PHONY: kernel-update-dts
kernel-update-dts:
	$(KERNEL_MAKE) dtbs -j$$(nproc)
	rsync --partial --checksum -rv arch/arm64/boot/dts/rockchip/$(BOARD).dtb root@$(REMOTE_HOST):$(REMOTE_DIR)/boot/efi/dtb

.PHONY: kernel-update
kernel-update-image:
	rsync --partial --checksum -rv arch/arm64/boot/Image root@$(REMOTE_HOST):$(REMOTE_DIR)/boot/efi/Image
	rsync --partial --checksum -rv arch/arm64/boot/dts/rockchip/$(BOARD).dtb root@$(REMOTE_HOST):$(REMOTE_DIR)/boot/efi/dtb
	rsync --partial --checksum -av out/linux_modules/lib/ root@$(REMOTE_HOST):$(REMOTE_DIR)/lib
