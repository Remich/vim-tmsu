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

## INSTALL

Set the variable `g:vimtmsu_plugin_dir` to the directory name where your vim plugins reside:  

```vim
" when using vim-plug:
let g:vimtmsu_plugin_dir = 'plugged'
```
