#!/bin/sh

KERNEL_VERSION=4.4
KERNEL_TREE=build_dir/
KERNEL_SYMBOLS=kernel_symbols_${KERNEL_VERSION}.txt
OPENWRT_DIR=target/

LKDDB=lkddb_${KERNEL_VERSION}.html

if [ -e $KERNEL_SYMBOLS ];
then
	echo "$KERNEL_SYMBOLS exists"
	rm -i $KERNEL_SYMBOLS
fi

if [ -e $LKDDB ];
then
	echo "$LKDDB exists"
	rm -i $LKDDB
fi

#Collect Kernel symbols from Kconfig and write to KERNEL_SYMBOLS file
find $KERNEL_TREE -name "Kconfig*" -exec grep -o "^[[:space:]]\?config\ [ ]\?[a-zA-Z0-9_]\+" {} \; |sort|uniq|awk '{ print $2 }' >> $KERNEL_SYMBOLS
#Add Section symbols
find $KERNEL_TREE -name "Kconfig*" -exec grep -o "^menuconfig\ [a-zA-Z0-9_]\+" {} \; |sort|uniq|awk '{ print $2 }' >> $KERNEL_SYMBOLS
#Add OpenWrt symbols
find $OPENWRT_DIR -name "Kconfig" -exec grep -o "^config\ [a-zA-Z0-9_]\+" {} \; |sort|uniq|awk '{ print $2 }' >> $KERNEL_SYMBOLS
find $OPENWRT_DIR -name "Kconfig" -exec grep -o "^menuconfig\ [a-zA-Z0-9_]\+" {} \; |sort|uniq|awk '{ print $2 }' >> $KERNEL_SYMBOLS

#OpenWrt patches some Kconfig files
find $OPENWRT_DIR -type f -name "*.patch" -exec grep -o "^+config\ [a-zA-Z0-9_]\+" {} \; |sort|uniq|awk '{ print $2 }' >> $KERNEL_SYMBOLS


#Collect Config symbols from arch
OMAP_SYMBOLS=$(grep -o "CONFIG_[a-zA-Z0-9_]\+" target/linux/omap/config-${KERNEL_VERSION})

#Collect Config symbols from generic
GENERIC_SYMBOLS=$(grep -o "CONFIG_[a-zA-Z0-9_]\+" target/linux/generic/config-${KERNEL_VERSION})



for VAR in $OMAP_SYMBOLS; do
	CLEANVAR=$(echo $VAR | sed 's/^CONFIG_//g')
	grep -q $CLEANVAR $KERNEL_SYMBOLS
        retval=$?
        if [ ! $retval -eq 0 ]
	then
		echo "Error: $CLEANVAR not found"
		# generate LKDDB links
		echo "http://cateee.net/lkddb/web-lkddb/$CLEANVAR.html<br>" >> $LKDDB
	fi
done

echo "generic symbol errors:"
for VAR in $GENERIC_SYMBOLS; do
	CLEANVAR=$(echo $VAR | sed 's/^CONFIG_//g')
	grep -xq $CLEANVAR $KERNEL_SYMBOLS
        retval=$?
        if [ ! $retval -eq 0 ]
	then
		echo "Error: $CLEANVAR not found"
		# generate LKDDB links
		echo "http://cateee.net/lkddb/web-lkddb/$CLEANVAR.html<br>" >> $LKDDB
	fi
done


