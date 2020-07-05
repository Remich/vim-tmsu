" File: vim-tmsu.vim
" Author: René Michalke <rene@renemichalke.de>
" Description: A vim wrapper for tmsu.

" Disable loading of plugin.
if exists("g:vimtmsu_load") && g:vimtmsu_load == 0
  finish
endif

" Save user's options, for restoring at the end of the script.
let s:save_cpo = &cpo
set cpo&vim

" Check for user setting of plugin dir.
" Exit if none is set.
if !exists("g:vimtmsu_plugin_dir")
	echom "vim-tmsu: Error 'g:vimtmsu_plugin_dir' not set."
	finish
endif

" Check for user setting for creating a 'index.vtmsu' in the current working directory.
" Otherwise create temporary files in '/tmp'.
if !exists("g:vimtmsu_persistent_index_files")
	let g:vimtmsu_persistent_index_files = 0
edif

" Holds the name of the created file.
" If we are using temporary files it has the form: `/tmp/index-PATH-XXXXXX.vtmsu`.
let s:filename = ""

" Initialize path to the file loader script.
let s:loader = g:vimtmsu_plugin_dir.'/vim-tmsu/src/loader.sh'

" Writes a message.
function! s:Message(msg)
	echom "vim-tmsu: ".a:msg
endfunction

" Writes a error message.
function! s:Error(msg)
	echom "vim-tmsu: ERROR: ".a:msg
endfunction

" Calls the file loader (`src/loader.sh`) using Neovim's Job Control.
" Decides where to create the file the data gets written to.
" Opens that file in the current window or a vertical split, depending on
" the parameter `a:split`.
function! s:LoadFiles(split, path)
	
	call s:Message("LoadFiles(".a:split.", ".a:path.")")	

	" Sanitize `a:path`:

	" a) Remove trailing `/`.
	let l:path = substitute(a:path, '\v\/*$', '', 'g')

	" b) Replace `.` with absolute path of current working directory.
	if l:path == "." || l:path == ""
		let l:path = getcwd()
	endif
	
	" Should i stay or should i split?
	if(a:split == "vsplit")	
		vsplit
	endif

	" Check if we should use a persistent index file or a temporary file.
	if g:vimtmsu_persistent_index_files == 0
		" Generate filename based on the path we are indexing.
		let l:cwdbase			= trim(system('/bin/bash', "F=".shellescape(l:path, "A")." && echo ${F##*/}"))
		let l:tmpfilename = '/tmp/index-'.l:cwdbase.'-XXXXXX.vtmsu'
		" Create temporary file.
		let	s:filename = trim(system("mktemp ".shellescape(l:tmpfilename, "A")))
	else
		let s:filename = l:path."/index.vtmsu"	
		echom "s:filename: ".s:filename
		" Delete old file.
		call system("rm ".shellescape(s:filename, "A"))
	endif

	" Build argument string for bash job.
	let l:args = [ s:loader, l:path, s:filename, -1 ]
	let l:args = map(l:args, "shellescape(v:val, 'A')")
	let l:argstr = join(l:args, " ")
	
	" Event handling for job control.
	function! s:OnEvent(job_id, data, event) dict
		if a:event == 'stdout'
			let str = self.shell.' stdout: '.join(a:data, "\r")
		elseif a:event == 'stderr'
			let str = self.shell.' stderr: '.join(a:data)
		else
			let str = self.shell.' exited'
			" job exit; open file	in vim
			execute "edit! " . s:filename
		endif
		echom str
	endfunction

	" Job control events
	let s:callbacks = {
				\ 'on_stdout': function('s:OnEvent'),
				\ 'on_stderr': function('s:OnEvent'),
				\ 'on_exit': function('s:OnEvent')
				\ }
	
	" Call the loader, which populates the file.
	call s:Message("LoadFiles: Starting job.")	
	let job1 = jobstart(['bash', '-c', l:argstr], extend({'shell': 'shell 1'}, s:callbacks))
	
	return
endfunction

" Returns the full filename / directoryname in line `a:linenum`.
function! s:GetFullFilename(linenum)
	
	let l:path = s:GetPath(a:linenum)
	if l:path == 2
		return
	endif
	
	let l:pathlinenum = s:GetPathLineNum(a:linenum)
	
	" Check if the current line points to a directory.
	if a:linenum == l:pathlinenum
		" Yes: Then `l:path` is the full directoryname.
		return l:path
	else
		" No: Get the filename and combine.
		let l:filename = s:GetFileName(a:linenum)
		return l:path.l:filename
	endif
	
endfunction

" Opens the file/directory of the current line with `xdg-open`.
function! s:OpenFile()
	let l:linenum = getpos('.')[1]
	let l:file    = s:GetFullFilename(l:linenum)
	call s:Message("Opening File: ".l:file."")	
	execute ":! xdg-open " . shellescape(l:file, "A")
endfunction

" Opens the file/directory of the current line with vim (re-implementation of `gf`).
function! s:GoFile()
	let l:linenum = getpos('.')[1]
	let l:file    = s:GetFullFilename(l:linenum)
	call s:Message("Going File: ".l:file."")	
	execute "edit! " . l:file
endfunction

" Returns the linenumber of the path of a file/directory on line `a:linenum`.
function! s:GetPathLineNum(linenum)
	
	" Go every line up until we find a path prefix (`🗁 `).

	let l:found = 0
	let l:curlinenum=a:linenum
	
	while l:found == 0
	
		let l:line = getline(l:curlinenum)

		if l:curlinenum == 0
			call s:Error("GetPathLineNum: Missing Path. Reload the index file!")	
			return 2
		endif
		
		if match(l:line, '\v🗁 .*') != -1
			let l:found = 1
		else
			let l:curlinenum = l:curlinenum - 1
		endif
	
	endwhile

	return l:curlinenum
	
endfunction

" Returns the path of the file on line `a:linenum`.
function! s:GetPath(linenum)
	let l:line = getline(s:GetPathLineNum(a:linenum))
	let l:path = []
	call substitute(l:line, '\v\/.*\/', '\=add(l:path, submatch(0))', 'g')
	return l:path[0]
endfunction

" Returns the filename of the file on line `a:linenum`.
function! s:GetFileName(linenum)
	let l:line = getline(a:linenum)
	let l:filename=[]
	call substitute(l:line, '\v\/\zs.*\ze\/', '\=add(l:filename, submatch(0))', 'g')
	return l:filename[0]
endfunction

" Returns a list of tags of the file/directory on line `a:linenum`.
function! s:GetTags(linenum)
	let l:line = getline(a:linenum)
	let l:tags = []
	call substitute(l:line, '\v\<\zs.{-}\ze\>', '\=add(l:tags, submatch(0))', 'g')
	return l:tags
endfunction

" Gets the lines of the current selection and calls `s:ApplyTagsOfLine()` on
" every line.
function! s:WriteTags() 
	let l:start = getpos("'<")
	let l:stop  = getpos("'>")
	let l:lines = range(l:start[1], l:stop[1])
	echo map(l:lines, 's:ApplyTagsOfLine(v:val)')
endfunction

" Gets the tags and correct names of the line `a:linenum`
" and calls `s:TagFile()`.
function! s:ApplyTagsOfLine(linenum) 
	let l:tags = s:GetTags(a:linenum)
	let l:file = s:GetFullFilename(a:linenum)
	call s:TagFile(l:file, l:tags)
endfunction

" Tags the file `a:file` with the tags `a:tags`.
function! s:TagFile(file, tags)
	
	if a:file == ""
		call s:Error("a:file missing as argument in 'TagFile()'.")
		return
	endif

	let l:file = shellescape(a:file, "A")

	" Create argument string for tags.
	if a:tags == []
		let l:tags = ""
	else
		let l:tags = map(a:tags, "shellescape(v:val, 'A')")
		let l:tags = join(a:tags)
	endif

	call s:Message("Tagging(" . l:file . ", " . l:tags . ")")

	" Always remove all previous tags.
	execute "! tmsu untag --all " . l:file

	" Actual tagging. Don't if no tags.
	if(l:tags != "")
		execute "! tmsu tag --tags='".l:tags."' ".l:file
	endif

endfunction


" ===============
" = Ex Commands =
" ===============

command! -nargs=? VTLoad :call s:LoadFiles("stay", <q-args>)

" ================
" = Autocommands =
" ================

" Deletes the temporary file.
function! s:DeleteTemporaryFile()
	call s:Message("Removing ".s:filename)
	let	l:res = system("rm ".shellescape(s:filename, "A"))
endfunction

augroup vim_tmsu_wrapper
	autocmd!
	
	" Delete temporary file on `BufWinLeave`.
	autocmd BufWinLeave /tmp/index*.vtmsu execute "call s:DeleteTemporaryFile()"
	
	" Buffer local mapping for: open file on current line with `xdg-open`.
	if !hasmapto('<Plug>VimtmsuOpenFile')
		autocmd Filetype vtmsu nmap <buffer> gx	<Plug>VimtmsuOpenFile
	endif
	
	" Buffer local mapping for: reimplementation of `gf`.
	if !hasmapto('<Plug>VimtmsuGoFile')
		autocmd Filetype vtmsu nmap <buffer> gf	<Plug>VimtmsuGoFile
	endif
augroup END

" ============
" = MAPPINGS =
" ============

if exists("g:vimtmsu_loaded_mappings") == v:false
	
	noremap <unique> <script> <Plug>VimtmsuOpenFile		<SID>Open
	noremap <SID>Open		:<c-u> call <SID>OpenFile()<CR>
	
	noremap <unique> <script> <Plug>VimtmsuGoFile		<SID>Go
	noremap <SID>Go		:<c-u> call <SID>GoFile()<CR>

	" Load current working directory in current window.
	if !hasmapto('<Plug>VimtmsuLoadCwd')
		nmap <unique> <Leader>t.	<Plug>VimtmsuLoadCwd
	endif
	noremap <unique> <script> <Plug>VimtmsuLoadCwd		<SID>Cwd
	noremap <SID>Cwd		:<c-u> call <SID>LoadFiles("stay", getcwd())<CR>

	" Load current working directory in a vertical split.
	if !hasmapto('<Plug>VimtmsuLoadCwdVsplit')
		nmap <unique> <Leader>tv.	<Plug>VimtmsuLoadCwdVsplit
	endif
	noremap <unique> <script> <Plug>VimtmsuLoadCwdVsplit		<SID>CwdVsplit
	noremap <SID>CwdVsplit		:<c-u> call <SID>LoadFiles("vsplit", getcwd())<CR>

	" Write changes of selected lines to tmsu database.
	if !hasmapto('<Plug>VimtmsuWriteTags')
		vmap <unique> <Leader>tw	<Plug>VimtmsuWriteTags
	endif
	noremap <unique> <script> <Plug>VimtmsuWriteTags		<SID>Write
	noremap <SID>Write		:<c-u> call <SID>WriteTags()<CR>

let g:vimtmsu_loaded_mappings = 1

endif

" Restore user's options.
let &cpo = s:save_cpo
unlet s:save_cpo
