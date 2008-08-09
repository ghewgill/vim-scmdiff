if !exists("g:scmDiffCommand")
    let g:scmDiffCommand = 'svn'
endif

if exists("loadedScmDiff") || &cp
    finish
endif

let loadedScmDiff = 1

map <silent> <C-d> :call <SID>scmDiff()<CR>
noremap <unique> <script> <plug>Dh :call <SID>scmDiff("h")<CR>
com! -bar -nargs=? D :call s:scmDiff(<f-args>)

let g:scmDiffRev = ''

function! s:scmDiff(...)

    if exists('b:scmDiffOn') && b:scmDiffOn == 1
        let b:scmDiffOn = 0
        set nodiff
    else
        let b:scmDiffOn = 1
        let view = winsaveview()

        if a:0 == 1
            if a:1 == 'none'
                let g:scmDiffRev = ”
            else
                let g:scmDiffRev = a:1
            endif
        endif

        let ftype = &filetype
        let tmpfile = tempname()
        let cmd = 'cat ' . bufname('%') . ' > ' . tmpfile
        let cmdOutput = system(cmd)
        let tmpdiff = tempname()
        let cmd = g:scmDiffCommand . ' diff ' . g:scmDiffRev . ' ' . bufname('%') . ' > ' . tmpdiff
        let cmdOutput = system(cmd)

        if v:shell_error && cmdOutput != ''
            echohl WarningMsg | echon cmdOutput 
            return
        endif

        let cmd = 'patch -R -p0 ' . tmpfile . ' ' . tmpdiff
        let cmdOutput = system(cmd)

        if v:shell_error && cmdOutput != ''
            echohl WarningMsg | echon cmdOutput 
            return
        endif

        if exists('s:killbuffs')
            2,9999 bdelete
        endif

        let s:killbuffs = 1

        if a:0 > 0 && a:1 == 'h'
            exe 'diffsplit' . tmpfile
        else
            exe 'vert diffsplit' . tmpfile
        endif 

        exe 'set filetype=' . ftype

        hide

        set foldcolumn=0
        set foldlevel=100
        set diffopt= " removed filler so we don’t show deleted lines

        highlight DiffAdd ctermbg=black ctermfg=DarkGreen
        highlight DiffChange ctermbg=black ctermfg=DarkGreen
        highlight DiffText ctermbg=black ctermfg=DarkGreen cterm=underline
        highlight DiffDelete ctermbg=red ctermfg=white

        call winrestview(view)
    endif
endfunction

"autocmd CursorHold * call s:scmDiff()
