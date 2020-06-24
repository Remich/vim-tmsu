
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"																	vim-tmsu-wrapper                         "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:tmpfile = ""

" Creates a tempory file in `/tmp` and opens that file either in the current
" window or a vertical split, depending on the first function argument.
" Then loads a tmsu file index (list of filenames with their tags) into that
" file.  The path of the files of the index is supplied by the second
" argument.
function! OpenArchive(split, path)

	" should i stay or should i split?
	if(a:split == "vsplit")	
		vsplit
	endif

	let l:path = shellescape(a:path)

	" generate filename based on the path we are indexing
	let l:cwdbase = system('/bin/bash', "F=".l:path." && echo ${F##*/}")
	
	echom "\"".l:cwdbase."\""
	
	let l:mktempcmd = "/tmp/tmsu-index-".trim(l:cwdbase)."-XXXXXX.md"

	" create temporary file
	let	s:tmpfile = system("mktemp \"/tmp/tmsu-index-".trim(l:cwdbase)."-XXXXXX.md\"")
	
	" load tmsu index into it
	execute "edit " . s:tmpfile
	execute 'read ! tmsu tags ' . l:path . '/**'
	
	" write file to make it greppable
	execute "write"
	execute "normal! gg"
	
endfunction

" open file on current line with xdg-open
function! OpenFileFromNotesList()
	let line = getline('.')
	let filename = substitute(line, '\v(\\)@<!(:).*', "", "")
	" replace \: with :
	let filename = substitute(filename, '\v\\:', ':', '')
	" replace \\ with \
	let filename = substitute(filename, '\v\\\\', '\\', '')
	" escape cmdline-special (`%`, `#`)
	let filename = substitute(filename, '\v\%', '\\%', '')
	let filename = substitute(filename, '\v\#', '\\#', '')
	" surround filename with `"` 
	let filenameQuoted = shellescape(filename)
	execute ":! xdg-open " . filenameQuoted
	echom line
	echom filename
	echom filenameQuoted
endfunction

" todo make variables local
function! GetFilename(line)
	" replace everything after the first `:` with ``
	let filename = substitute(a:line, '\v(\\)@<!(:).*', "", "") 
	" replace \: with :
	let filename = substitute(filename, '\v\\:', ':', '')
	" replace \\ with \
	let filename = substitute(filename, '\v\\\\', '\\', '')
	" escape cmdline-special (`%`, `#`)
	let filename = substitute(filename, '\v\%', '\\%', '')
	let filename = substitute(filename, '\v\#', '\\#', '')
	return filename
endfunction

function! GetTags(line)
	let l:tags = trim(substitute(a:line, '\v.*(\\)@<!(:)', "", ""))
	" echom "tags:" . l:tags . ";"
	return l:tags
endfunction

function! HelloWorld(val) 
	return a:val
endfunction

function! ApplyTagsOfSelectedLines() 
	let l:start = getpos("'<")
	let l:stop  = getpos("'>")
	let l:lines = range(l:start[1], l:stop[1])
	echo map(l:lines, 'ApplyTagsOfLine(getline(v:val))')
endfunction

function! ApplyTagsOfLine(line) 
	let l:filename = GetFilename(a:line)
	let l:tags     = GetTags(a:line)
	call TagFile(l:filename, l:tags)
endfunction

" function to apply tags to file in line
function! TagFile(filename, tags)
	if(a:filename == "")
		return
	endif
	
	echom "\n"

	echom "Tagging(" . a:filename . ", " . a:tags . ");"

	" always clearing
	echom "Clearing(".a:filename.")"
	execute "! tmsu untag --all " . shellescape(a:filename)
	
	if(a:tags != "")
		echom "Applying(".a:filename.")"
		execute '! tmsu tag --tags="' . a:tags .'" ' . shellescape(a:filename)
	endif
	
endfunction


function! DeleteTemporaryFile()
	let	l:res = system("rm \"".trim(s:tmpfile)."\"")
endfunction

augroup vim_tmsu_wrapper
  autocmd!
  autocmd BufWinLeave *tmsu-index*.md execute "call DeleteTemporaryFile()"
augroup END

execute 'command! Twrite call ApplyTagsOfSelectedLines()'

" opening and loading index
nnoremap <leader>ioa :<c-u> call OpenArchive("vsplit", '/home/pepe/archive')<cr>
nnoremap <leader>io. :<c-u> call OpenArchive("vsplit", getcwd())<cr>
nnoremap <leader>sia :<c-u> call OpenArchive("stay", '/home/pepe/archive')<cr>
nnoremap <leader>si. :<c-u> call OpenArchive("stay", getcwd())<cr>

" open file on current line with xdg-open
nnoremap <leader>of :<c-u> call OpenFileFromNotesList()<cr>
" write changes to tmsu database
vnoremap <leader>wt :<c-u> call ApplyTagsOfSelectedLines()<cr>
