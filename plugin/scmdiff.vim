" Vim script to show file differences from a base version in SCM.
" Home: http://github.com/ghewgill/vim-scmdiff

" Default commands:
"   \d            Toggle diff view on/off
"   :D rev        Difference between current and rev
"   \s            Toggle split view/non-split view
"   :Dsplit       Set Split view as default
"   :Dnosplit     Set no Split view as default
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
map <silent> <Leader>s :call <SID>scmSplitToggle()<CR>
noremap <unique> <script> <plug>Dh :call <SID>scmDiff("h")<CR>
com! -bar -nargs=? D :call s:scmDiff(<f-args>)
com! -bar -nargs=? Dsplit :call s:scmSplitToggle(1)
com! -bar -nargs=? Dnosplit :call s:scmSplitToggle(0)

let g:scmDiffRev = ''

function! s:scmToggle()

    if exists('t:scmDiffOn') && t:scmDiffOn == 1
        let t:scmDiffOn = 0
        if exists('t:scmDiffSplit') && t:scmDiffSplit == 1
            hide
        endif
        set nodiff
        exe 'bdelete ' . t:scmDiffTmpfile
        echohl DiffDelete | echon "scmdiff Disabled" | echohl None
    else
        call s:scmDiff()
        if exists('t:scmDiffOn') && t:scmDiffOn == 1
            echohl DiffAdd | echon "scmdiff Enabled" | echohl None
        endif
    endif

endfunction

function! s:scmSplitToggle(...)

    if a:0 == 1
        let t:scmDiffSplit = a:1
    else
        let l:toggle = 0
        if exists('t:scmDiffOn') && t:scmDiffOn == 1
            let l:toggle = 1
            call s:scmToggle()
        endif

        if exists('t:scmDiffSplit') && t:scmDiffSplit == 1
            let t:scmDiffSplit = 0
            echohl DiffDelete | echon "scmDiffSplit Disabled" | echohl None
        else
            let t:scmDiffSplit = 1 
            echohl DiffAdd | echon "scmDiffSplit  Enabled" | echohl None
        endif

        if l:toggle == 1
            call s:scmToggle()
        endif
    endif

endfunction

function! s:scmRefresh()

    if exists('t:scmDiffOn') && t:scmDiffOn == 1
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

    " Detect .git, SCCS(bitkeeper), .hg(mercurial), _darcs(darcs) directories recursively in reverse
    let my_path = g:scmBufPath
    while my_path != "/"
        if !exists("g:scmDiffCommand") && isdirectory(my_path."/.git")
            let g:scmDiffCommand = "git diff --no-ext-diff"
            return
        endif
        if !exists("g:scmDiffCommand") && isdirectory(my_path."/.hg")
            let g:scmDiffCommand = "hg diff"
            return
        endif
        if !exists("g:scmDiffCommand") && isdirectory(my_path."/_darcs")
            let g:scmDiffCommand = "darcs diff -u"
            return
        endif
        let my_path = simplify(my_path."/../")
    endwhile

endfunction

function! s:scmDiff(...)

    call s:detectSCM()
    if (!exists("g:scmDiffCommand"))
        echohl WarningMsg | echon "Could not find .git, .svn, .hg, _darcs, SCCS, or CVS directories, are you under a supported SCM repository path?" | echohl None
        return
    endif

    if exists('t:scmDiffOn') && t:scmDiffOn == 1
        let t:scmDiffOn = 0
        set nodiff
        exe 'bdelete ' . t:scmDiffTmpfile
    endif

    let view = winsaveview()

    if a:0 == 1
        if a:1 == 'none'
            let g:scmDiffRev = ''
        else
            let g:scmDiffRev = a:1
            if (match(g:scmDiffCommand, 'darcs'))
                g:scmDiffRev = '--from-patch=' . g:scmDiffRev
            endif
        endif
    endif

    let ftype = &filetype
    let t:scmDiffTmpfile = tempname()
    let cmd = 'cat ' . bufname('%') . ' > ' . t:scmDiffTmpfile
    let cmdOutput = system(cmd)
    let tmpdiff = tempname()
    let cmd = 'cd ' . g:scmBufPath . ' && ' . g:scmDiffCommand . ' ' . g:scmDiffRev . ' ' . expand('%:t') . ' > ' . tmpdiff
    let cmdOutput = system(cmd)
    let doWrap = &wrap  " Save the current state of wrap for later

    if v:shell_error && cmdOutput != ''
        echohl WarningMsg | echon cmdOutput | echohl None
        return
    endif

    let cmd = 'patch -R -p0 ' . t:scmDiffTmpfile . ' ' . tmpdiff
    let cmdOutput = system(cmd)

    if v:shell_error && cmdOutput != ''
        echohl WarningMsg | echon cmdOutput | echohl None
        return
    endif

    if a:0 > 0 && a:1 == 'h'
        exe 'diffsplit' . t:scmDiffTmpfile
    else
        exe 'vert diffsplit' . t:scmDiffTmpfile
    endif

    exe 'set filetype=' . ftype

    if !exists("t:scmDiffSplit") || t:scmDiffSplit == 0
        hide
        if doWrap == 1  
            set wrap  "Restore the state of wrap
        endif

        set foldcolumn=0
        set foldlevel=100
        set diffopt= " removed filler so we don't show deleted lines
        set noscrollbind
    endif

    call winrestview(view)
    let t:scmDiffOn = 1

endfunction

autocmd CursorHold * call s:scmRefresh()


" vim>600: expandtab sw=4 ts=4 sts=4 fdm=marker
" vim<600: expandtab sw=4 ts=4 sts=4
