let s:save_cpo = &cpo
set cpo&vim

" fmap([a, b, c], f) => [f(a), f(b), f(c)]
" fmap(a, f) => [f(a)]
function! s:fmap(xs, f)
  if type(a:xs) == type([])
    return map(a:xs, a:f)
  else
    return map([a:xs], a:f)
  endif
endfunction

let g:quicklearn_gcc_remote_url = get(g:, 'quicklearn_gcc_remote_url', 'localhost')

let g:quicklearn = get(g:, 'quicklearn', {})
let s:source = {
\ 'name': 'quicklearn',
\ }

call extend(g:quicklearn, {
\ 'c/clang/intermediate': {
\   'meta': { 'parent': 'c/clang'},
\   'exec': '%c %o %s -S -emit-llvm -o -'},
\ 'c/clang-O3/intermediate': {
\   'meta': { 'parent': 'c/clang'},
\   'cmdopt': '-O3',
\   'exec': '%c %o %s -S -emit-llvm -o -'},
\ 'cpp/clang/intermediate': {
\   'meta': { 'parent': 'cpp/clang++'},
\   'exec': '%c %o %s -S -emit-llvm -o -'},
\ 'cpp/clang-O3/intermediate': {
\   'meta': { 'parent': 'cpp/clang++'},
\   'cmdopt': '-O3',
\   'exec': '%c %o %s -S -emit-llvm -o -'},
\ 'c/gcc/intermediate': {
\   'meta': { 'parent': 'c/gcc'},
\   'exec': '%c %o %s -S -o -'},
\ 'c/gcc-32/intermediate': {
\   'meta': { 'parent': 'c/gcc'},
\   'cmdopt': '-m32',
\   'exec': '%c %o %s -S -o -'},
\ 'c/gcc-remote/intermediate': {
\   'meta': { 'parent': 'c/gcc'},
\   'exec': 'ssh ' . g:quicklearn_gcc_remote_url . ' %c %o %s -S -o -'},
\ }, 'keep')

call extend(g:quicklearn, {
\ 'haskell/ghc/intermediate': {
\   'meta': { 'parent': 'haskell/ghc'},
\   'exec': [
\     '%c %o -ddump-simpl -dsuppress-coercions %s',
\     'rm %s:p:r %s:p:r.o %s:p:r.hi'],
\   'cmdopt': '-v0 --make'},
\ 'coffee/intermediate': {
\   'meta': { 'parent': '_'},
\   'exec': ['%c %o -cbp %s %a']},
\ 'ruby/intermediate': {
\   'meta': { 'parent': 'ruby'},
\   'cmdopt': '--dump=insns'},
\ }, 'keep')

call extend(g:quicklearn, {
\ 'css/sass/intermediate': {
\   'meta': { 'parent': 'css'},
\   'command': 'sass-convert',
\   'cmdopt': '-F css -T sass',
\   'exec': '%c %o %s /dev/stdout'},
\ 'css/scss/intermediate': {
\   'meta': { 'parent': 'css'},
\   'command': 'sass-convert',
\   'cmdopt': '-F css -T scss',
\   'exec': '%c %o %s /dev/stdout'},
\ 'css/stylus/intermediate': {
\   'meta': { 'parent': 'css'},
\   'command': 'css2stylus',}
\ }, 'keep')
call extend(g:quicklearn, {
\ 'javascript/coffee/intermediate': {
\   'meta': { 'parent': 'javascript'},
\   'command': 'js2coffee', },
\ 'html/haml/intermediate': {
\   'meta': { 'parent': 'html'},
\   'command': 'html2haml'},
\ 'json/jq/intermediate': {
\   'meta': { 'parent': 'json'},
\   'command': 'jq'},
\ 'rst/intermediate': {
\   'meta': { 'parent': 'rst'},
\   'command': 'rst2html'},
\ })

call extend(g:quicklearn, {
\ 'markdown/md2backlog/intermediate': {
\   'meta': { 'parent': 'markdown'},
\   'command': 'md2backlog'},
\ 'markdown/md2help/intermediate': {
\   'meta': { 'parent': 'markdown'},
\   'command': 'vim-helpfile'},
\ }, 'keep')
" call extend(g:quicklearn, {
" \ }, 'keep')

" inheritance
for k in keys(g:quicklearn)
  let v = g:quicklearn[k]
  for item in ['command', 'exec', 'cmdopt', 'tempfile', 'eval_template']
    let ofParent = get(g:, 'quickrun#default_config[v.meta.parent]', item)
    if type(ofParent) != type(0) || ofParent != 0
      let g:quicklearn[k][item] = get(v, item, ofParent)
    endif
    unlet ofParent
  endfor
endfor

" build quickrun command
for k in keys(g:quicklearn)
  let v = g:quicklearn[k]
  let g:quicklearn[k].quickrun_command = printf(
        \ 'QuickRun %s %s %s -cmdopt %s',
        \ v.meta.parent == '_' ? '' : '-type ' . v.meta.parent,
        \ get(v, 'command') ? '-command ' . string(v.command) : '',
        \ join(s:fmap(get(v, 'exec', []), '"-exec " . string(v:val)'), ' '),
        \ string(get(v, 'cmdopt', '')))
endfor
lockvar g:quicklearn

function! unite#sources#quicklearn#define()
  return s:source
endfunction

function! s:source.gather_candidates(args, context)
  let configs = filter(copy(g:quicklearn), 'v:key =~ "^" . &filetype . "/"')

  return values(map(configs, '{
        \ "word": substitute(v:key, "/intermediate$", "", ""),
        \ "source": s:source.name,
        \ "kind": ["command"],
        \ "action__command": v:val.quickrun_command,
        \ }'))
        "\ "action__type": ": ",
endfunction

let &cpo = s:save_cpo
