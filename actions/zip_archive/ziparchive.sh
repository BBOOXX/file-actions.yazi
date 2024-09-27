#!/usr/bin/env bash
set -e
IFS=$'\t'
OS="$(uname -s)"

# 变成数组
arrSelection=(${selection})

# 取第一个项目的父路径
parentPath=${arrSelection[0]%/*}

# 取父路径名字
parentName=${parentPath##*/}

# 处理相对路径
case "$OS" in
	Darwin) relativePath=$(grealpath --relative-to="${parentPath}" ${selection}) ;;
	Linux) relativePath=$(realpath --relative-to="${parentPath}" ${selection}) ;;
	*) echo "Unsupported operating system"; exit 1 ;;
esac

# 进入工作目录
cd ${parentPath}

# 分别压缩
if [[ ${compression_mode} == 'separate' ]]; then
	# 执行压缩
	for file in ${relativePath//$'\n'/$IFS}; do
		# 删除最后的/左边的所有
		packName="${file##*/}"
		# 判断是否是文件
		if [[ -f "${file}" ]]; then
			# 删除最后的.右边的所有
			packName="${packName%.*}"
		fi
		zip -r "${packName}".zip "${file}"
	done
# 整体打包
else
	# 如果是单项文件或文件夹取项目本身名字
	if [[ ${choice_mode} == 'single' ]];then
		# 删除最后的/左边的所有
		packName="${arrSelection[0]##*/}"
		if [[ -f "${arrSelection[0]}" ]]; then
			# 删除最后的.右边的所有
			packName="${packName%.*}"
		fi
	# 多项整体打包取父路径名字
	else
		packName="${parentName}"
	fi
	# 执行压缩
	zip -r "${packName}".zip ${relativePath//$'\n'/$IFS}
fi
