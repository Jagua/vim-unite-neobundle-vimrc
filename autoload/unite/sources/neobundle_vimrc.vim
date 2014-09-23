" vim: set et fdm=marker ft=vim sts=2 sw=2 ts=2 :
" NEW BSD LICENSE {{{
" Copyright (c) 2014, Jagua.
" All rights reserved.
"
" Redistribution and use in source and binary forms, with or without modification,
" are permitted provided that the following conditions are met:
"
"     1. Redistributions of source code must retain the above copyright notice,
"        this list of conditions and the following disclaimer.
"     2. Redistributions in binary form must reproduce the above copyright notice,
"        this list of conditions and the following disclaimer in the documentation
"        and/or other materials provided with the distribution.
"     3. The names of the authors may not be used to endorse or promote products
"        derived from this software without specific prior written permission.
"
" THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
" ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
" WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
" IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
" INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
" BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
" DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
" LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
" OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
" THE POSSIBILITY OF SUCH DAMAGE.
" }}}


scriptencoding utf-8


let s:save_cpo = &cpo
set cpo&vim


" define s:source & s:kind "{{{
let s:source = {
\ 'name' : 'neobundle/vimrc',
\ 'description' : 'jump to procedure lines of NeoBundle in your .vimrc.',
\ 'syntax' : 'uniteSource__NeoBundleVimrc',
\ 'parents' : [],
\ 'is_volatile' : 1,
\ 'is_insert' : 1,
\ 'hooks' : {},
\ 'default_action' : 'jump_to_procedure',
\ 'action_table' : {
\   'jump_to_procedure' : {
\     'description' : 'jump to a procedure line.',
\   },
\   'echo' : {
\     'description' : 'echo candidate. (for debug)',
\     'is_listed' : 0,
\   },
\ },
\}


let s:kind = deepcopy(s:source)
"}}}


function! s:source.hooks.on_init(args, context) "{{{
  let a:context.source__tap = (get(a:args, 0, '') ==# '!')
  let a:context.source__bundle_pattern =  get(g:,
  \ 'unite_neobundle_vimrc_bundle_pattern',
  \ '^\\C\\m[^\\\u0022]*\\%(NeoBundle\\|neobundle#bundle\\)'
  \ . '[^\\\u0022\\\u0027]\\+[\\\u0022\\\u0027]\\(.\\+\\)$')
  " XXX: the following pattern is more strict.
  "\  '^\\C\\m[^\\\u0022]*\\%(NeoBundle\\|neobundle#bundle\\)[^\\\u0022\\\u0027]\\+[\\\u0022\\\u0027]\\([^\\\u0022\\\u0027]\\+\\)[\\\u0022\\\u0027].*')
  let a:context.source__tap_pattern = get(g:,
  \ 'unite_neobundle_vimrc_tap_pattern',
  \ '^\\C\\m[^\\\u0022]*\\%(neobundle#tap\\)'
  \ . '[^\\\u0022\\\u0027]\\+[\\\u0022\\\u0027]\\(.\\+\\)$')
  " XXX: the following pattern is more strict.
  "\ '^\\C\\m[^\\\u0022]*\\%(neobundle#tap\\)[^\\\u0022\\\u0027]\\+[\\\u0022\\\u0027]\\([^\\\u0022\\\u0027]\\+\\)[\\\u0022\\\u0027].*')
  let a:context.source__tap_key = get(g:,
  \ 'unite_neobundle_vimrc_tap_key', ';t')
  let a:context.source__vimrc_path = expand(get(g:,
  \ 'unite_neobundle_vimrc_path', $MYVIMRC))
  if !filereadable(a:context.source__vimrc_path)
    echoerr 'Invalid : g:unite_neobundle_vimrc_path'
  endif
endfunction "}}}


function! s:source.hooks.on_syntax(args, context) "{{{
  syntax match uniteSource__NeoBundleVimrc_Line /^.*$/
  \            containedin=uniteSource__NeoBundleVimrc
  syntax match uniteSource__NeoBundleVimrc_User /['"]\zs.\{-}\ze\//
  \            containedin=uniteSource__NeoBundleVimrc_Line
  \            contains=uniteCandidateInputKeyword
  syntax match uniteSource__NeoBundleVimrc_Name /\/\zs.\{-}\ze['"]/
  \            containedin=uniteSource__NeoBundleVimrc_Line
  \            contains=uniteCandidateInputKeyword
  syntax match uniteSource__NeoBundleVimrc_NameOnly /['"]\zs[^\/'"]\{-}\ze['"]/me=e+1
  \            containedin=uniteSource__NeoBundleVimrc_Line
  \            contains=uniteCandidateInputKeyword
  highlight default link uniteSource__NeoBundleVimrc_Line Comment
  highlight default link uniteSource__NeoBundleVimrc_User PreProc
  highlight default link uniteSource__NeoBundleVimrc_Name Type
  highlight default link uniteSource__NeoBundleVimrc_NameOnly Type
endfunction "}}}


function! s:source.gather_candidates(args, context) "{{{
  let bundle_pattern = a:context.source__bundle_pattern
  let tap_pattern = a:context.source__tap_pattern
  let tap_key = a:context.source__tap_key

  let s:unite_neobundle_vimrc = readfile(a:context.source__vimrc_path)

  let tap = (match(unite#get_cur_text(), tap_key) != -1)
  if tap
    let pat = tap_pattern
  else
    let pat = bundle_pattern
  endif
  let a:context.source__tap = tap

  " XXX: match() is always 'magic on'.
  let m = filter(copy(s:unite_neobundle_vimrc), 'match(v:val, "' . pat . '")!=-1')
  return map(m, '{
  \ "word" : tap_key . substitute(v:val,
  \                     "' . pat .'",
  \                     "\\1", ""),
  \ "abbr" : v:val,
  \ "kind" : "neobundle/vimrc",
  \ "source__vimrc_path" : a:context.source__vimrc_path,
  \ }')
endfunction "}}}


function! unite#sources#neobundle_vimrc#define() "{{{
  return s:source
endfunction "}}}


function! s:smart_open(filename) "{{{
  if bufwinnr(a:filename) == -1
    execute 'split' a:filename
  else
    execute bufwinnr(a:filename) . 'wincmd w'
  endif
endfunction "}}}


function! s:kind.action_table.echo.func(candidate) "{{{
  echo a:candidate
endfunction "}}}


function! s:kind.action_table.jump_to_procedure.func(candidate) "{{{
  call s:smart_open(a:candidate.source__vimrc_path)
  call search(escape(a:candidate.abbr, '~'), 'w')
endfunction "}}}


call unite#define_kind(s:kind)


let &cpo = s:save_cpo
unlet s:save_cpo

