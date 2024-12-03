#!/bin/bash
# ----------------------------------------------------------------------------
# Script Name: RegView.sh
# Description: 一个实现正则可视化的脚本，帮助我们更好学习正则。
# Author: bamuwe
# Date Created: 2024-12-01
# Last Modified: 2024-12-02
# Version: beat1.1
# License: MIT License
# ----------------------------------------------------------------------------

banner="
 ____    __    __  __  __  __  _    _  ____ 
 (  _ \  /__\  (  \/  )(  )(  )( \/\/ )( ___)
  ) _ < /(__)\  )    (  )(__)(  )    (  )__) 
  (____/(__)(__)(_/\/\_)(______)(__/\__)(____)
  "

file_path=${1}
poc_path=${2}
if [ ! -f "$file_path" ]; then
	echo "./RegView <*file> <poc_file>"
	exit 1
fi
declare count=0
tmux splitw -h
tmux select-pane -t 0
input_tty_number=$(tty)
out_tty_number=$(tmux list-panes -F "#{pane_id} #{pane_tty}" | tail -n1 | awk '{print $2}')

if [ -f "$poc_path" ]; then
	tmux splitw
	tmux splitw -h
	tmux select-pane -t 0
	poc_tty_number=$(tmux list-panes -F "#{pane_id} #{pane_tty}" | tail -n2 | head -n1 | awk '{print $2}')
	result_tty_number=$(tmux list-panes -F "#{pane_id} #{pane_tty}" | tail -n3 | head -n1 | awk '{print $2}')
	echo $result_tty_number
	clear >$poc_tty_number
fi
clear >$out_tty_number
clear >$input_tty_number
echo "$banner" >$out_tty_number
echo "按下回车开始使用,输入\q退出并查看结果。" >$out_tty_number
echo "输入正则表达式，结果将出现在这里。" >$out_tty_number
line_bak=".*"

while IFS= read -r line; do
	if [ $count -eq 0 ]; then
		echo "history:"
		echo "----------------------------------------"
	fi
	if [[ $line == "\q" ]]; then
		tmux kill-pane -t $(tmux list-panes -F "#{pane_tty} #{pane_id}" | grep "$out_tty_number" | awk '{print $2}')
		if [ -f "$poc_path" ]; then
			tmux kill-pane -t $(tmux list-panes -F "#{pane_tty} #{pane_id}" | grep "$poc_tty_number" | awk '{print $2}')
			tmux kill-pane -t $(tmux list-panes -F "#{pane_tty} #{pane_id}" | grep "$result_tty_number" | awk '{print $2}')
			echo 'bye!'
			exit 0
		fi
		echo 'bye!' >$input_tty_number
		echo "-----------------" >$input_tty_number
		if [[ -n "$line_bak" && "$line_bak" != "\n" ]]; then
			echo "最后输入的正则：$line_bak" >$input_tty_number
			echo "-----------------" >$input_tty_number
			echo "最后得到的结果：" >$input_tty_number
			echo "-----------------" >$input_tty_number
			grep -Po "$line_bak" "$file_path"
		fi
		exit 0
	fi
	if [ -z "$(echo "$line" | tr -d '[:space:]')" ]; then
		line=$line_bak
	fi
	clear >$out_tty_number
	echo "File_Path: $file_path" >$out_tty_number
	echo "Regular_Expression: $line" >$out_tty_number
	echo "----------------------------------------" >$out_tty_number

	symbols=('/' '#' '@' '%' ':' ';')
	for i in "${symbols[@]}"; do
		if [[ ! "$line" =~ "$i" ]]; then
			matchword="s$i$line$i\x1b[31m$&\x1b[0m${i}g"
			break
		fi
	done
	if [ -f "$poc_path" ]; then

		clear >$poc_tty_number
		clear >$result_tty_number
		echo "poc_content:" >$poc_tty_number
		echo "----------------------------------------" >$poc_tty_number
		perl -pe "$matchword" "$poc_path" 2>/dev/null >$poc_tty_number || { sed -E "s/.*/&/g" "$poc_path" >$poc_tty_number; }
	fi

	command=`perl -pe "$matchword" "$file_path" 2>/dev/null || { sed -E "s/.*/&/g" "$file_path"; }`
	echo "----------------------------------------" >$out_tty_number
	echo "$command" > "$out_tty_number"
	if [ -f "$poc_path" ]; then
		echo "output:" >$result_tty_number
		echo "----------------------------------------" >$result_tty_number
		grep -Po "$line" "$file_path" 2>/dev/null >$result_tty_number
	fi
	line_bak=$line
	echo "----------------------------------------" >$out_tty_number
	((count++))
	printf "[%s] " $count >$input_tty_number
done
