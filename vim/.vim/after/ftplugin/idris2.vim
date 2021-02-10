if bufname('%') == "idris-response"
  finish
endif

" Stop idris2-vim from overriding my tabstops
setlocal shiftwidth=4
setlocal tabstop=4

