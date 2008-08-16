if !exists("g:scmDiffCommand")
    let g:scmDiffCommand = 'git'
endif

if exists("loadedScmDiff") || &cp
    finish
endif

let loadedScmDiff = 1

map <silent> <C-d> :call <SID>scmToggle()<CR>
noremap <unique> <script> <plug>Dh :call <SID>scmDiff("h")<CR>
com! -bar -nargs=? D :call s:scmDiff(<f-args>)

let g:scmDiffRev = ''

function! s:scmToggle()

    if exists('b:scmDiffOn') && b:scmDiffOn == 1
        let b:scmDiffOn = 0
        set nodiff
        exe 'bdelete ' . b:tmpfile
    else
        call s:scmDiff()
    endif

endfunction

function! s:scmRefresh()

    if exists('b:scmDiffOn') && b:scmDiffOn == 1
        call s:scmDiff()
    endif

endfunction

function! s:scmDiff(...)

    if exists('b:scmDiffOn') && b:scmDiffOn == 1
        let b:scmDiffOn = 0
        set nodiff
        exe 'bdelete ' . b:tmpfile
    endif

    let b:scmDiffOn = 1
    let view = winsaveview()

    if a:0 == 1
        if a:1 == 'none'
            let g:scmDiffRev = ''
        else
            let g:scmDiffRev = a:1
        endif
    endif

    let ftype = &filetype
    let b:tmpfile = tempname()
    let cmd = 'cat ' . bufname('%') . ' > ' . b:tmpfile
    let cmdOutput = system(cmd)
    let tmpdiff = tempname()
    let cmd = g:scmDiffCommand . ' diff ' . g:scmDiffRev . ' ' . bufname('%') . ' > ' . tmpdiff
    let cmdOutput = system(cmd)

    if v:shell_error && cmdOutput != ''
        echohl WarningMsg | echon cmdOutput
        return
    endif

    let cmd = 'patch -R -p0 ' . b:tmpfile . ' ' . tmpdiff
    let cmdOutput = system(cmd)

    if v:shell_error && cmdOutput != ''
        echohl WarningMsg | echon cmdOutput
        return
    endif

    if a:0 > 0 && a:1 == 'h'
        exe 'diffsplit' . b:tmpfile
    else
        exe 'vert diffsplit' . b:tmpfile
    endif

    exe 'set filetype=' . ftype

    hide

    set foldcolumn=0
    set foldlevel=100
    set diffopt= " removed filler so we don't show deleted lines

    highlight DiffAdd ctermbg=DarkBlue ctermfg=white cterm=NONE
    highlight DiffChange ctermbg=DarkBlue ctermfg=white cterm=NONE
    highlight DiffText ctermbg=DarkBlue ctermfg=white cterm=underline
    highlight DiffDelete ctermbg=red ctermfg=white

    call winrestview(view)

endfunction

autocmd CursorHold * call s:scmRefresh()


" vim>600: expandtab sw=4 ts=4 sts=4 fdm=marker
" vim<600: expandtab sw=4 ts=4 sts=4
