# vim-tmsu

Provides a convenient and efficient way to organize your files with tags using the awesome command-line tool [tmsu](https://tmsu.org/).  
															
## Q: What does it exactly do?  
__A:__ Given a directory, this plugin loads and opens a list of files and their respective tmsu-tags into a temporary file (from now on called the "index-file").  
	 
Within the "index-file" you can:  

* Find the files and directories your are looking for by using all the tools vim provides you with (e.g. `grep`, `gf`).
* Add and remove tags from your files.
* Open/launch a file.

## Q: What functionality of tmsu is implemented?
__A:__ Listing, adding and removing tags from files and directories. No recursive, or implied tags yet.  

## Q: Why does it only work in Neovim?
__A:__ Vim and Neovim have different ways of handling job control. I only implemented it for Neovim as of now. Vim support will follow.  

## Install

Set the variable `g:vimtmsu_plugin_dir` to the directory name where your vim plugins reside:  

```vim
" when using vim-plug:
let g:vimtmsu_plugin_dir = 'plugged'
```

## Configuration

```vim
" The name of the folder where you store your plugins.
let g:vimtmsu_plugin_dir = 'plugged'

" Set to 0 to disable loading of plugin. 
let g:vimtmsu_load = 1

" Set default directory. Use absolute path.
" If none is set the current working directory will be used.
" NOTE: If the directory and it's subdirectories contain a lot of files,
"				loading might take some time.
let g:vimtmsu_default = ''

" Default mappings:

" Load home directory in current window.
nmap <unique> <Leader>th	<Plug>VimtmsuLoadHome
" Load home directory in a vertical split.
nmap <unique> <Leader>tvh	<Plug>VimtmsuLoadHomeVsplit
" Load current working directory in current window.
nmap <unique> <Leader>t.	<Plug>VimtmsuLoadCwd
" Load current working directory in a vertical split.
nmap <unique> <Leader>tv.	<Plug>VimtmsuLoadCwdVsplit
" Open file on current line with xdg-open.
nmap <unique> <Leader>to	<Plug>VimtmsuOpenFile
" Write changes of selected lines to tmsu database.
vmap <unique> <Leader>tw	<Plug>VimtmsuWriteTags
```
