if exists("b:current_syntax")
    finish
endif

let b:current_syntax = "vtmsu"

syntax match vtmsuTag "\v\zs\<.{-}\>\ze"
syntax match vtmsuTag "\v\/"
highlight link vtmsuTag Comment

syntax match vtmsuFolder "\v🗁 \s*\zs\/.*\/\ze"
highlight link vtmsuFolder Operator
