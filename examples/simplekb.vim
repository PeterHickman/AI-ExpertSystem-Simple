" Vim syntax file
" Language:	SimpleKB
" Maintainer:	Peter Hickman
" Last Change:	2004 February 06

" Add the following line to your .vimrc (well it works for me)
" au BufRead,BufNewFile *.skb set filetype=simplekb

" For version 5.x: Clear all syntax items
" For version 6.x: Quit when a syntax file was already loaded
if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

syn keyword skbPrimary		GOAL goal
syn keyword skbPrimary		RULE rule
syn keyword skbPrimary		QUESTION question

syn keyword skbSecondary	CONDITIONS CONDITION conditions condition
syn keyword skbSecondary	ACTIONS ACTION actions action
syn keyword skbSecondary	PRIORITY priority

syn keyword skbThirdary		IS is

syn match   skbNumber            "\<\d\+\>"

syn region  skbComment		start="#" end="$" contains=basicTodo
syn region  skbComment		start=";" end="$" contains=basicTodo

hi link skbPrimary		Statement
hi link skbSecondary		Identifier
hi link skbThirdary		Special
hi link skbNumber               Number
hi link skbComment		Comment

let b:current_syntax = "simplekb"

" vim: ts=8
