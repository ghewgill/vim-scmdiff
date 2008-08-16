" Vim script to show file differences from a base version in SCM.
" Home: http://github.com/ghewgill/vim-scmdiff

" Default commands:
"   C-d     Toggle diff view on/off
"   :D rev  Difference between current and rev

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
        exe 'bdelete ' . b:scmDiffTmpfile
    else
        call s:scmDiff()
    endif

endfunction

function! s:scmRefresh()

    if exists('b:scmDiffOn') && b:scmDiffOn == 1
        call s:scmDiff()
    endif

endfunction

function! s:detectSCM()

    " Cache the results we find here to save time
    if exists("g:scmCWD") && g:scmCWD == getcwd() && exists("g:scmDiffCommand")
        return
    endif
    let g:scmCWD = getcwd()

    " Detect CVS or .svn directories in current path
    if !exists("g:scmDiffCommand") && isdirectory(g:scmCWD."/.svn")
        let g:scmDiffCommand = "svn"
        return
    endif

    if !exists("g:scmDiffCommand") && isdirectory(g:scmCWD."/CVS")
        let g:scmDiffCommand = "cvs"
        return
    endif

    " Detect .git directories recursively in reverse
    let my_cwd = g:scmCWD
    while my_cwd != "/"
        if !exists("g:scmDiffCommand") && isdirectory(my_cwd."/.git")
            let g:scmDiffCommand = "git"
            return
        endif
        let my_cwd = simplify(my_cwd."/../")
    endwhile

endfunction

function! s:scmDiff(...)

    call s:detectSCM()
    if (!exists("g:scmDiffCommand"))
        echohl WarningMsg | echon "Could not find .git, .svn, or CVS directories, are you under a supported SCM repository path?"
        return
    endif

    if exists('b:scmDiffOn') && b:scmDiffOn == 1
        let b:scmDiffOn = 0
        set nodiff
        exe 'bdelete ' . b:scmDiffTmpfile
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
    let b:scmDiffTmpfile = tempname()
    let cmd = 'cat ' . bufname('%') . ' > ' . b:scmDiffTmpfile
    let cmdOutput = system(cmd)
    let tmpdiff = tempname()
    let cmd = g:scmDiffCommand . ' diff ' . g:scmDiffRev . ' ' . bufname('%') . ' > ' . tmpdiff
    let cmdOutput = system(cmd)

    if v:shell_error && cmdOutput != ''
        echohl WarningMsg | echon cmdOutput
        return
    endif

    let cmd = 'patch -R -p0 ' . b:scmDiffTmpfile . ' ' . tmpdiff
    let cmdOutput = system(cmd)

    if v:shell_error && cmdOutput != ''
        echohl WarningMsg | echon cmdOutput
        return
    endif

    if a:0 > 0 && a:1 == 'h'
        exe 'diffsplit' . b:scmDiffTmpfile
    else
        exe 'vert diffsplit' . b:scmDiffTmpfile
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
