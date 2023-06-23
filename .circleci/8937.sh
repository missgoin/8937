#!/usr/bin/env bash

 #
 # Script For Building Android Kernel
 #

##----------------------------------------------------------##
# Specify Kernel Directory
KERNEL_DIR="$(pwd)"

##----------------------------------------------------------##
# Device Name and Model
MODEL=Xiaomi
DEVICE=mi8937

# Kernel Version Code
#VERSION=

# Kernel Defconfig
DEFCONFIG=${DEVICE}_defconfig

# Select LTO variant ( Full LTO by default )
DISABLE_LTO=1
THIN_LTO=0

# Files
IMAGE=$(pwd)/out/arch/arm64/boot/Image.gz-dtb
#DTBO=$(pwd)/out/arch/arm64/boot/dtbo.img
#DTB=$(pwd)/out/arch/arm64/boot/dts/qcom

# Verbose Build
VERBOSE=0

# Kernel Version
KERVER=$(make kernelversion)

COMMIT_HEAD=$(git log --oneline -1)

# Date and Time
DATE=$(TZ=Asia/Jakarta date +"%Y%m%d-%T")
TANGGAL=$(date +"%F%S")

# Specify Final Zip Name
ZIPNAME=SUPER.KERNEL
FINAL_ZIP=${ZIPNAME}-${DEVICE}-${DATE}.zip
FINAL_ZIP_ALIAS=Karenulvin-${DATE}.zip

##----------------------------------------------------------##
# Specify compiler.

COMPILER=proton

##----------------------------------------------------------##
# Specify Linker
LINKER=ld.lld

##----------------------------------------------------------##

##----------------------------------------------------------##
# Clone ToolChain
function cloneTC() {

	if [ $COMPILER = "atomx" ];
	then
	git clone --depth=1 https://gitlab.com/ElectroPerf/atom-x-clang.git clang
	PATH="${KERNEL_DIR}/clang/bin:$PATH"

    elif [ $COMPILER = "neutron" ];
    then
    git clone --depth=1 https://gitlab.com/dakkshesh07/neutron-clang.git clang
    PATH="${KERNEL_DIR}/clang/bin:$PATH"
    
    elif [ $COMPILER = "trb" ];
    then
    git clone --depth=1 https://gitlab.com/varunhardgamer/trb_clang.git clang
    PATH="${KERNEL_DIR}/clang/bin:$PATH"
    
    elif [ $COMPILER = "cosmic" ];
    then
    git clone --depth=1 https://gitlab.com/PixelOS-Devices/playgroundtc.git -b 17 cosmic
    PATH="${KERNEL_DIR}/cosmic/bin:$PATH"
    
	elif [ $COMPILER = "azure" ];
	then
	git clone --depth=1 https://gitlab.com/Panchajanya1999/azure-clang clang
	PATH="${KERNEL_DIR}/clang/bin:$PATH"

	elif [ $COMPILER = "proton" ];
	then
	git clone --depth=1 https://github.com/kdrag0n/proton-clang.git clang
	PATH="${KERNEL_DIR}/clang/bin:$PATH"

	elif [ $COMPILER = "eva" ];
	then
	git clone --depth=1 https://github.com/mvaisakh/gcc-arm64.git -b gcc-new gcc64
	git clone --depth=1 https://github.com/mvaisakh/gcc-arm.git -b gcc-new gcc32
	PATH=$KERNEL_DIR/gcc64/bin/:$KERNEL_DIR/gcc32/bin/:/usr/bin:$PATH

	elif [ $COMPILER = "aosp" ];
	then
        mkdir aosp-clang
        cd aosp-clang || exit
	wget -q https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/master/clang-r450784b.tar.gz
        tar -xf clang*
        cd .. || exit
	git clone https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9.git --depth=1 gcc
	git clone https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9.git  --depth=1 gcc32
	PATH="${KERNEL_DIR}/aosp-clang/bin:${KERNEL_DIR}/gcc/bin:${KERNEL_DIR}/gcc32/bin:${PATH}"
	fi
	
    # Clone AnyKernel
    git clone --depth=1 https://github.com/missgoin/AnyKernel3.git

	}


##------------------------------------------------------##
# Export Variables
function exports() {
	
        # Export KBUILD_COMPILER_STRING
        if [ -d ${KERNEL_DIR}/clang ];
           then
               export KBUILD_COMPILER_STRING=$(${KERNEL_DIR}/clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
               export LD_LIBRARY_PATH="${KERNEL_DIR}/clang/lib:$LD_LIBRARY_PATH"
        elif [ -d ${KERNEL_DIR}/gcc64 ];
           then
               export KBUILD_COMPILER_STRING=$("$KERNEL_DIR/gcc64"/bin/aarch64-elf-gcc --version | head -n 1)       
        elif [ -d ${KERNEL_DIR}/cosmic ];
           then
               export KBUILD_COMPILER_STRING=$(${KERNEL_DIR}/cosmic/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')        
        elif [ -d ${KERNEL_DIR}/aosp-clang ];
            then
               export KBUILD_COMPILER_STRING=$(${KERNEL_DIR}/aosp-clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
        fi
        
        # Export ARCH and SUBARCH
        export ARCH=arm64
        export SUBARCH=arm64
        
        # Export Local Version
        #export LOCALVERSION="-${VERSION}"
        
        # KBUILD HOST and USER
        export KBUILD_BUILD_HOST=Pancali
        export KBUILD_BUILD_USER="unknown"
        
	    export PROCS=$(nproc --all)
	    export DISTRO=$(source /etc/os-release && echo "${NAME}")
	
	}
        
##----------------------------------------------------------------##
# Telegram Bot Integration
##----------------------------------------------------------------##

# Export Configs
function configs() {
    if [ -d ${KERNEL_DIR}/clang ] || [ -d ${KERNEL_DIR}/aosp-clang  ] || [ -d ${KERNEL_DIR}/cosmic  ]; then
       if [ $DISABLE_LTO = "1" ]; then
          sed -i 's/CONFIG_LTO_CLANG=y/# CONFIG_LTO_CLANG is not set/' arch/arm64/configs/${DEFCONFIG}
          sed -i 's/CONFIG_LTO=y/# CONFIG_LTO is not set/' arch/arm64/configs/${DEFCONFIG}
          sed -i 's/# CONFIG_LTO_NONE is not set/CONFIG_LTO_NONE=y/' arch/arm64/configs/${DEFCONFIG}
       elif [ $THIN_LTO = "1" ]; then
          sed -i 's/# CONFIG_THINLTO is not set/CONFIG_THINLTO=y/' arch/arm64/configs/${DEFCONFIG}
       fi
    elif [ -d ${KERNEL_DIR}/gcc64 ]; then
       sed -i 's/CONFIG_LLVM_POLLY=y/# CONFIG_LLVM_POLLY is not set/' arch/arm64/configs/${DEFCONFIG}
       sed -i 's/# CONFIG_GCC_GRAPHITE is not set/CONFIG_GCC_GRAPHITE=y/' arch/arm64/configs/${DEFCONFIG}
       if ! [ $DISABLE_LTO = "1" ]; then
          sed -i 's/# CONFIG_LTO_GCC is not set/CONFIG_LTO_GCC=y/' arch/arm64/configs/${DEFCONFIG}
       fi
    fi
}

# Speed up build process
MAKE="./makeparallel"


##----------------------------------------------------------##
# Compilation
function compile() {
START=$(date +"%s")
		
	# Compile
	make O=out ARCH=arm64 ${DEFCONFIG}
	if [ -d ${KERNEL_DIR}/clang ];
	   then
	       make -kj$(nproc --all) O=out \
	       ARCH=arm64 \
	       CC=clang \
	       CROSS_COMPILE=aarch64-linux-gnu- \
	       CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
	       #LLVM=1 \
	       #LLVM_IAS=1 \
	       #LD=${LINKER} \
	       AR=llvm-ar \
	       NM=llvm-nm \
	       OBJCOPY=llvm-objcopy \
	       OBJDUMP=llvm-objdump \
	       #DIS=llvm-dis \
	       STRIP=llvm-strip \
	       #READELF=llvm-readelf \
	       #OBJSIZE=llvm-size \
	       CONFIG_DEBUG_SECTION_MISMATCH=y \
	       CONFIG_NO_ERROR_ON_MISMATCH=y \
	       V=$VERBOSE 2>&1 | tee error.log
	       
	elif [ -d ${KERNEL_DIR}/cosmic ];
	   then
	       make -j$(nproc --all) O=out \
	       ARCH=arm64 \
	       CC=clang \
           CROSS_COMPILE=aarch64-linux-gnu- \
           CROSS_COMPILE_ARM32=arm-linux-gnueabi \
           LLVM=1 \
           #LLVM_IAS=1 \
           AR=llvm-ar \
           NM=llvm-nm \
           LD=${LINKER} \
           OBJCOPY=llvm-objcopy \
           OBJDUMP=llvm-objdump \
           STRIP=llvm-strip \
	       V=$VERBOSE 2>&1 | tee error.log
	elif [ -d ${KERNEL_DIR}/gcc64 ];
	   then
	       make -kj$(nproc --all) O=out \
	       ARCH=arm64 \
	       CROSS_COMPILE_ARM32=arm-eabi- \
	       CROSS_COMPILE=aarch64-elf- \
	       LD=aarch64-elf-${LINKER} \
	       AR=llvm-ar \
	       NM=llvm-nm \
	       OBJCOPY=llvm-objcopy \
	       OBJDUMP=llvm-objdump \
	       STRIP=llvm-strip \
	       OBJSIZE=llvm-size \
	       V=$VERBOSE 2>&1 | tee error.log
    elif [ -d ${KERNEL_DIR}/aosp-clang ];
       then
           make -kj$(nproc --all) O=out \
	       ARCH=arm64 \
	       CC=clang \
           HOSTCC=clang \
	       HOSTCXX=clang++ \
	       CLANG_TRIPLE=aarch64-linux-gnu- \
	       CROSS_COMPILE=aarch64-linux-android- \
	       CROSS_COMPILE_ARM32=arm-linux-androideabi- \
	       LD=${LINKER} \
	       AR=llvm-ar \
	       NM=llvm-nm \
	       OBJCOPY=llvm-objcopy \
	       OBJDUMP=llvm-objdump \
           STRIP=llvm-strip \
	       READELF=llvm-readelf \
	       OBJSIZE=llvm-size \
	       V=$VERBOSE 2>&1 | tee error.log
	fi
}

##----------------------------------------------------------------##
function zipping() {
	# Copy Files To AnyKernel3 Zip
	cp $IMAGE AnyKernel3
	
	# Zipping and Push Kernel
	cd AnyKernel3 || exit 1
        zip -r9 ${FINAL_ZIP} *
        MD5CHECK=$(md5sum "$FINAL_ZIP" | cut -d' ' -f1)
        echo "Zip: $FINAL_ZIP"
        #curl -T $FINAL_ZIP_ALIAS temp.sh; echo
        #curl -T $FINAL_ZIP_ALIAS https://oshi.at; echo
        curl --upload-file $FINAL_ZIP https://free.keep.sh; echo
    cd ..
}
    
##----------------------------------------------------------##

cloneTC
exports
configs
compile
zipping

##----------------*****-----------------------------##