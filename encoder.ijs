coclass 'encoder'

require 'convert/pjson'
require 'regex'
require 'utils.ijs'


NB. Explanation of regex options:
NB.   (*UTF): Ensure PCRE2 interprets our UTF-8 bytes as Unicode. This should not be needed
NB.           with base library 9.04.08 and on since UTF mode was enabled by default:
NB.           [https://github.com/jsoftware/base9/commit/c389104]
NB.   (*UCP): Ensure character types (e.g. '\s', called "character classes" elsewhere) are defined
NB.           using Unicode properties, as is default in Python. For example, without this option,
NB.           \s might not match non-breaking spaces (U+00A0).
pat =: '(*UTF)(*UCP)''s|''t|''re|''ve|''m|''ll|''d| ?\p{L}+| ?\p{N}+| ?[^\s\p{L}\p{N}]+|\s+(?!\S)|\s+'

NB. 3&u: converts Unicode to code point, 4&u: does the opposite
bs =: ; _2 <@([ + i.@>:@-~)/\ 3&u: uucp '!~¡¬®ÿ'
cs =: 4&u: bs , 256 + i. 256 - #bs
bs =: bs , (i. 256) -. bs


create =: 3 : 0
  echo 'Loading tokenizer...'

  echo '  Reading merges.txt'
  file_exists y , '/merges.txt'
  bpe_merges =: uucp each cut&> }. cutLF fread y , '/merges.txt'

  echo '  Reading vocab.json'
  file_exists y , '/vocab.json'
  vocab =: uucp each {."1 dec_pjson_ fread y , '/vocab.json'

  echo '  Processing vocab'
  vocab =: (<'\\u[0-9a-f]{4}') ([: uucp@dfh 2&}.) rxapply each vocab

  echo '  Building lookup verbs'
  vocab_i      =: vocab&i.
  bpe_merges_i =: bpe_merges&i.

  echo 'Done.'
)

destroy =: {{ codestroy '' }}

bpe =: (3 : 0) M.
  word  =. <@,"0 y   NB. Ravel because everything in vocab is a list
  while. 1 do.
    if. 1 = # word do. break. end.
    pairs =. ~. 2 ,/\ word
    i =. bpe_merges_i pairs
    if. i *./@:= #bpe_merges do. break. end.
    bigram =. pairs {~ (i. <./) i
    word =. word rplc bigram ,&< <;bigram
  end.
  word
)

encode =: {{ ; {{vocab_i bpe cs {~ bs i. a. i. >y}} each pat rxall utf8 y }}
decode =: {{ ucp a. {~ bs {~ cs i. ; y { vocab }}
