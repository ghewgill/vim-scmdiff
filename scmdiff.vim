" Vim script to show file differences from a base version in SCM.
" Home: http://github.com/ghewgill/vim-scmdiff

" Default commands:
"   \d      Toggle diff view on/off
"   :D rev  Difference between current and rev
"
" You can change the highlighting by adding the following to your 
" .vimrc file and customizing as necessary.  (or just uncomment them here):
"   highlight DiffAdd ctermbg=DarkBlue ctermfg=white cterm=NONE
"   highlight DiffChange ctermbg=DarkBlue ctermfg=white cterm=NONE
"   highlight DiffText ctermbg=DarkBlue ctermfg=white cterm=underline
"   highlight DiffDelete ctermbg=red ctermfg=white

if exists("loadedScmDiff") || &cp
    finish
endif

let loadedScmDiff = 1

map <silent> <Leader>d :call <SID>scmToggle()<CR>
noremap <unique> <script> <plug>Dh :call <SID>scmDiff("h")<CR>
com! -bar -nargs=? D :call s:scmDiff(<f-args>)

let g:scmDiffRev = ''

function! s:scmToggle()

    if exists('b:scmDiffOn') && b:scmDiffOn == 1
        let b:scmDiffOn = 0
        set nodiff
        exe 'bdelete ' . b:scmDiffTmpfile
        echohl DiffDelete | echon "scmdiff Disabled" | echohl None
    else
        call s:scmDiff()
        if exists('b:scmDiffOn') && b:scmDiffOn == 1
            echohl DiffAdd | echon "scmdiff Enabled" | echohl None
        endif
    endif

endfunction

function! s:scmRefresh()

    if exists('b:scmDiffOn') && b:scmDiffOn == 1
        call s:scmDiff()
    endif

endfunction

function! s:detectSCM()

    " Cache the results we find here to save time
    if exists("g:scmBufPath") && g:scmBufPath == expand("%:p:h") && exists("g:scmDiffCommand")
        return
    endif
    let g:scmBufPath = expand("%:p:h")

    " Detect CVS, SCCS(bitkeeper) or .svn directories in current path
    if !exists("g:scmDiffCommand") && isdirectory(g:scmBufPath."/.svn")
        let g:scmDiffCommand = "svn diff"
        return
    endif

    if !exists("g:scmDiffCommand") && isdirectory(g:scmBufPath."/CVS")
        let g:scmDiffCommand = "cvs diff"
        return
    endif

    if !exists("g:scmDiffCommand") && isdirectory(g:scmBufPath."/SCCS")
        let g:scmDiffCommand = "bk diffs"
        return
    endif

    " Detect .git, SCCS(bitkeeper), .hg(mercurial) directories recursively in reverse
    let my_path = g:scmBufPath
    while my_path != "/"
        if !exists("g:scmDiffCommand") && isdirectory(my_path."/.git")
            let g:scmDiffCommand = "git diff"
            return
        endif
        if !exists("g:scmDiffCommand") && isdirectory(my_path."/.hg")
            let g:scmDiffCommand = "hg diff"
            return
        endif
        let my_path = simplify(my_path."/../")
    endwhile

endfunction

function! s:scmDiff(...)

    call s:detectSCM()
    if (!exists("g:scmDiffCommand"))
        echohl WarningMsg | echon "Could not find .git, .svn, .hg, SCCS, or CVS directories, are you under a supported SCM repository path?" | echohl None
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
    let cmd = 'cd ' . g:scmBufPath . ' && ' . g:scmDiffCommand . ' ' . g:scmDiffRev . ' ' . expand('%:p') . ' > ' . tmpdiff
    let cmdOutput = system(cmd)

    if v:shell_error && cmdOutput != ''
        echohl WarningMsg | echon cmdOutput | echohl None
        return
    endif

    let cmd = 'patch -R -p0 ' . b:scmDiffTmpfile . ' ' . tmpdiff
    let cmdOutput = system(cmd)

    if v:shell_error && cmdOutput != ''
        echohl WarningMsg | echon cmdOutput | echohl None
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
    set noscrollbind

    call winrestview(view)

endfunction

autocmd CursorHold * call s:scmRefresh()


" vim>600: expandtab sw=4 ts=4 sts=4 fdm=marker
" vim<600: expandtab sw=4 ts=4 sts=4
