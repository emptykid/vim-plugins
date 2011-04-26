""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Copyright (C) 2010 zhengqianglong@baidu.com
"
" Name: closurelinter.vim
" Description: A vim plugin for google closure linter
" Author: zhengqianglong
" Mail: zhengqianglong@baidu.com
" Last Modified: Apr 26, 2011
" Version: 1.0
" ChangeLog: 
" 1. 创建此脚本，支持通过<F3>快捷键调用命令实现输出窗口
"           created 1.0  2011/04/25
" -------------------------------------------
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! g:CL_start()
    " 获取当前文件的工作路径
    let s:current_dir = getcwd()
    " 获取当前文件的文件名称
    let s:current_file_name = bufname("%")

    let s:current_file = s:current_dir.'/'.s:current_file_name
    let g:cl_tmp_file = s:current_dir.'/.'.s:current_file_name.'.cl'

    " 调用系统命令执行Check并把输出结果存在当前目录下的.filename.cl文件中
    let s:result = system('gjslint --custom_jsdoc_tags="fileOverview,mail,date,version,namespace,name,description,field" '.s:current_file.' > '.g:cl_tmp_file)

    let s:main_script_window = winnr()

    call <SID>CL_showResultWindow()
endfunction

function <SID>CL_showResultWindow()
    " 获取检查结果文件的窗口ID，用于判断该窗口是否已经存在了
    let b:cl_window = bufnr(g:cl_tmp_file)
    if b:cl_window > -1
        " 如果窗口已经打开了，重新载入该文件
        exe s:main_script_window." wincmd w"
        exe "e!"
        exe 0
    else
        " 用分割窗口的方式打开
        silent execute 'bo 10split +call\ s:CL_initCLWindow() '.g:cl_tmp_file
    endif
endfunction

function! s:CL_initCLWindow()
    set filetype=closurelinter

    " <buffer>表示此映射只限制在当前缓冲区内
    map <buffer> <cr> :call <SID>CL_getMsgLine()<cr>
endfunction

function <SID>CL_getMsgLine()
    let s:current_line = getline(".")
    if s:current_line =~# '^Line\s\d\{1,}'
        let s:err_line = matchstr(matchstr(s:current_line,'^Line\s\d\{1,}'),'\d\{1,}')
    else
        let s:err_line = -1
    endif
    if s:err_line != -1
        " 切换回原来的窗口
        exe s:main_script_window." wincmd w"
        exe s:err_line
    endif
endfunction

function g:ClosureLinterExit()
    " 退出窗口的时候删除临时文件
    let s:delfile = delete(g:cl_tmp_file)
endfunction

