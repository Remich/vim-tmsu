# vim-tmsu

A Neovim Plugin which provides a convenient and efficient way to organize your files with tags using the awesome command-line tool [TMSU](https://tmsu.org/).  

## Introduction

This plugin creates a list of files and directories with their respective TMSU tags and writes that list into a file, the so called 'index-file'.  

Within an 'index-file' you can:

* find files and directories using Vim's text searching capabilities (e.g. `grep`,…).
* tag your files and directories using Vim's text editing capabilities.
* open a file/directory in Vim.
* launch a file/directory using `xdg-open`.

## Install

Use your favourite Plugin Manager.  

## Usage

See the help file, by typing `:help vim-tmsu` in Vim.  

## FAQ

### Q: What functionality of TMSU is implemented?
__A:__ Listing, adding and removing tags from files and directories. No recursive, or implied tags yet.  

### Q: Why does it only work in Neovim?
__A:__ Vim and Neovim have different ways of handling job control. Vim support will follow.  
