" File: vim-tmsu.vim
" Author: René Michalke <rene@renemichalke.de>
" Last Change: 2020 Jun 26
" Description: A vim wrapper for tmsu.

" check for user setting of pluging dir
if !exists("g:vimtmsu_plugin_dir")
	echom "vim-tmsu: Error 'g:vimtmsu_plugin_dir' not set."
	finish
endif
	
" holds the name of the created temporary file ( `/tmp/index-PATH-XXXXXX.vtmsu` )
let s:tmpfile = ""

" path to the file loader script
let s:loader = stdpath("config").'/'.g:vimtmsu_plugin_dir.'/vim-tmsu/src/loader.sh'
	
" Creates a tempory file in `/tmp` and opens that file either in the current
" window or a vertical split, depending on the first function argument.
" Then loads a tmsu file-index (list of filenames with their tags) into that
" file.  The path of the folder of the index is supplied by the second
" argument.
function! LoadFiles(split, path)
	" should i stay or should i split?
	if(a:split == "vsplit")	
		vsplit
	endif

	" generate filename based on the path we are indexing
	let l:cwdbase			= trim(system('/bin/bash', "F=".shellescape(a:path, "A")." && echo ${F##*/}"))
	let l:tmpfilename = '/tmp/index-'.l:cwdbase.'-XXXXXX.vtmsu'

	" create temporary file
	let	s:tmpfile = trim(system("mktemp ".shellescape(l:tmpfilename, "A")))

	" build argument string for bash job
	let l:args = [ s:loader, a:path, s:tmpfile, -1 ]
	let l:args = map(l:args, "shellescape(v:val, 'A')")
	let l:argstr = join(l:args, " ")
	
	" event handling for job control
	function! s:OnEvent(job_id, data, event) dict
		if a:event == 'stdout'
			let str = self.shell.' stdout: '.join(a:data, "\r")
		elseif a:event == 'stderr'
			let str = self.shell.' stderr: '.join(a:data)
		else
			let str = self.shell.' exited'
			" job exit; open temporary file	
			execute "edit! " . s:tmpfile
		endif
		echom str
	endfunction

	" job control events
	let s:callbacks = {
				\ 'on_stdout': function('s:OnEvent'),
				\ 'on_stderr': function('s:OnEvent'),
				\ 'on_exit': function('s:OnEvent')
				\ }
	
	" call the loader, which populates the temporary file
	let job1 = jobstart(['bash', '-c', l:argstr], extend({'shell': 'shell 1'}, s:callbacks))
	
	return
endfunction

" open file on current line with xdg-open
function! OpenFileFromNotesList()
	
	let l:linenum  = getpos('.')[1]
	let l:filename = GetFilename(l:linenum)
	let l:path     = GetPath(l:linenum)
	
	if l:path == 2
		return
	endif

	let l:file = EscapePathAndFilename(l:path, l:filename)
	
	execute ":! xdg-open " . l:file
	
endfunction

function! GetPath(linenum)

	" go every line up until we find a path prefix (`🗁 `)

	let l:found = 0
	let l:curlinenum=a:linenum
	
	while l:found == 0
	
		let l:line = getline(l:curlinenum)

		if l:curlinenum == 0
			echom "ERROR: Missing Path. Reload the index file!"
			return 2
		endif
		
		if match(l:line, '\v🗁 .*') != -1
			let l:found = 1
		else
			let l:curlinenum = l:curlinenum - 1
		endif
	
	endwhile

	" extract path from line
	let l:path=[]
	call substitute(l:line, '\v\/.*\/', '\=add(l:path, submatch(0))', 'g')
	return l:path[0]
	
endfunction

function! GetFilename(linenum)
	let l:line = getline(a:linenum)
	let l:filename=[]
	call substitute(l:line, '\v\/\zs.*\ze\/', '\=add(l:filename, submatch(0))', 'g')
	return l:filename[0]
endfunction

" returns a list of tags
function! GetTags(linenum)
	let l:line = getline(a:linenum)
	let l:tags=[]
	call substitute(l:line, '\v\<\zs.{-}\ze\>', '\=add(l:tags, submatch(0))', 'g')
	return l:tags
endfunction

function! HelloWorld(val) 
	return a:val
endfunction

function! ApplyTagsOfSelectedLines() 
	let l:start = getpos("'<")
	let l:stop  = getpos("'>")
	let l:lines = range(l:start[1], l:stop[1])
	echo map(l:lines, 'ApplyTagsOfLine(v:val)')
endfunction

function! ApplyTagsOfLine(linenum) 

	let l:path = GetPath(a:linenum)
	if l:path == 2
		return
	endif
	
	let l:filename = GetFilename(a:linenum)
	let l:tags     = GetTags(a:linenum)

	" echom "path: ".l:path
	" echom "filename: ".l:filename
	" echo map(l:tags, 'v:val')
	
	call TagFile(l:path, l:filename, l:tags)
endfunction

function! EscapePathAndFilename(path, filename)
	return shellescape(a:path.a:filename, "A")
endfunction

" function to apply tags to file in line
function! TagFile(path, filename, tags)
	
	if(a:path == "" || a:filename == "")
		echom "ERROR: path or filename missing as argument in `TagFile()`."
		return
	endif


	" create argument string for tags
	if a:tags == []
		let l:tags = ""
	else
		let l:tags = map(a:tags, "shellescape(v:val, 'A')")
		let l:tags = join(a:tags)
	endif

	" create argument string for file
	let l:file = EscapePathAndFilename(a:path, a:filename)

	echom "Tagging(" . l:file . ", " . l:tags . ");"

	" always clearing
	execute "! tmsu untag --all " . l:file

	" tagging
	if(l:tags != "") " not necessary, if no tags
		execute "! tmsu tag --tags='".l:tags."' ".l:file
	endif

endfunction

function! DeleteTemporaryFile()
	let	l:res = system("rm ".shellescape(s:tmpfile, "A"))
endfunction

augroup vim_tmsu_wrapper
	autocmd!
	autocmd BufWinLeave *tmsu-index*.md execute "call DeleteTemporaryFile()"
augroup END

execute 'command! Twrite call ApplyTagsOfSelectedLines()'

" opening and loading index
nnoremap <leader>toa :<c-u> call LoadFiles("vsplit", '/home/pepe/archive')<cr>
nnoremap <leader>to. :<c-u> call LoadFiles("vsplit", getcwd())<cr>
nnoremap <leader>tsa :<c-u> call LoadFiles("stay", '/home/pepe/archive')<cr>
nnoremap <leader>ts. :<c-u> call LoadFiles("stay", getcwd())<cr>

" open file on current line with xdg-open
nnoremap <leader>tof :<c-u> call OpenFileFromNotesList()<cr>
" write changes to tmsu database
vnoremap <leader>tw :<c-u> call ApplyTagsOfSelectedLines()<cr>
