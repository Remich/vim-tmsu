if exists("b:current_syntax")
    finish
endif

let b:current_syntax = "vtmsu"

syntax match vtmsuTag "\v\zs\<.{-}\>\ze"
highlight link vtmsuTag Identifier

syntax match vtmsuSeperator "\v\/"
highlight link vtmsuSeperator Comment

syntax match vtmsuFolder "\v🗁 \s*\zs\/.*\/\ze"
highlight link vtmsuFolder Operator
