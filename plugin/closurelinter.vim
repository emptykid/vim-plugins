""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Copyright (C) 2010 zhengqianglong@baidu.com
"
" Name: closurelinter.vim
" Description: A vim plugin for google closure linter
" Author: zhengqianglong
" Mail: zhengqianglong@baidu.com
" Last Modified: Apr 26, 2011
" Version: 1.0
" Howto:
" 1. 可以通过设置下面的代码来关闭此插件的功能
"
"       let g:CL_plugin_disable = 1
"
" 2. 默认的触发按键是<leader>cl，如果不是你想要的，找到第44行，把<leader>cl改成你想要的键名称
"
" 3. 如果你希望可以监听文件的改动并自动调用检查命令，可以设置如下
"
"       let g:CL_auto_check = 1
"
"    注意，如果设置了此命令，你编辑所有的js文件，在保存的时候都会自动调用检查工具并输出
"
" ChangeLog: 
" 1. 创建此脚本，支持通过<F3>快捷键调用命令实现输出窗口
"           created 1.0  2011/04/25
" -------------------------------------------
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" 版本检查和插件加载检查
if exists('g:CL_plugin_loaded')
    finish
elseif  v:version < 702
    echoerr 'ClosureLinter does not support this version of vim (' . v:version . ').'
    finish
endif
let g:CL_plugin_loaded = 1

" 插件开关
" 可以通过设置g:CL_plugin_disable = 1来关闭此插件
if exists('g:CL_plugin_disable') && g:CL_plugin_disable == 1
    finish
endif

" 绑定一些自动命令
autocmd FileType javascript map <silent> <leader>cl :call g:CL_start()<cr>
augroup closurelinter
    au! BufRead,BufNewFile *.cl setfiletype closurelinter
    " 当js文件推出之后删除对应的临时文件
    au! VimLeave *.js :call g:ClosureLinterExit()
    if exists('g:CL_auto_check') && g:CL_auto_check == 1
        au! bufwritepost *.js :call g:CL_start()
    endif
augroup END

" 插件的入口函数
function! g:CL_start()
    " 获取当前文件的工作路径
    let s:current_dir = getcwd()
    " 获取当前文件的文件名称
    let s:current_file_name = bufname("%")

    let s:current_file = s:current_dir.'/'.s:current_file_name
    let g:cl_tmp_file = s:current_dir.'/.'.s:current_file_name.'.cl'
    let g:cl_tmp_file_name = '.'.s:current_file_name.'.cl'

    " 调用系统命令执行Check并把输出结果存在当前目录下的.filename.cl文件中
    let s:result = system('gjslint --custom_jsdoc_tags="fileOverview,mail,date,version,namespace,name,description,field" '.s:current_file.' > '.g:cl_tmp_file)

    " 保存当前编辑的js文件窗口，便于后续窗口跳转的时候使用
    let s:main_script_window = winnr()
    call <SID>CL_showResultWindow()
endfunction

" 弹出检查结果的窗口
function <SID>CL_showResultWindow()
    " 获取检查结果文件的窗口ID，用于判断该窗口是否已经存在了
    let b:cl_window = bufnr(g:cl_tmp_file)
    if b:cl_window > -1
        " 如果窗口已经打开了，重新载入该文件
        exe "wincmd w"
        exe "e!"
        exe 0
    else
        " 用分割窗口的方式打开
        silent execute 'bo 10split +call\ s:CL_initCLWindow() '.g:cl_tmp_file
    endif
endfunction

" 对结果窗口进行初始化，绑定回车事件
function! s:CL_initCLWindow()
    set filetype=closurelinter

    " <buffer>表示此映射只限制在当前缓冲区内
    map <buffer> <cr> :call <SID>CL_getMsgLine()<cr>
endfunction

" 获取检查窗口的定位行
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

" 当脚本推出时，删除相应的临时文件
function g:ClosureLinterExit()
    let s:tmp_file = findfile(g:cl_tmp_file_name, '.;') 
    " 退出窗口的时候删除临时文件
    if s:tmp_file != ''
        let s:delfile = delete(g:cl_tmp_file)
    endif
endfunction
