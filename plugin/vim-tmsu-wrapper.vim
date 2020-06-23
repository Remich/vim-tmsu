
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"																	vim-tmsu-wrapper                         "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:tmsupath = '/home/pepe/archive'
" creates an index of my archive and opens it either in an vertical split or
" current split
function! OpenArchive(split)
	execute a:split
	execute 'read ! tmsu tags ' . s:tmsupath . '/**'
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

execute 'command! Twrite call ApplyTagsOfSelectedLines()'

" write changes to tmsu database
vnoremap <leader>wt :<c-u> call ApplyTagsOfSelectedLines()<cr>
" build temporary archive index and open it in a new split
nnoremap <leader>oa :<c-u> call OpenArchive("vnew")<cr>
" re-build temporary archive index and load it in current split
nnoremap <leader>sa :<c-u> call OpenArchive("enew")<cr>
" open file on current line with xdg-open
nnoremap <leader>of :<c-u> call OpenFileFromNotesList()<cr>
