augroup Spin
  autocmd!
  autocmd FileType promela setlocal commentstring=//%s
  autocmd BufWritePost *.pml lua require("spin.util").check_on_save()
  autocmd BufWinEnter,BufEnter *.pml lua require("spin.util").check_on_save()
  autocmd InsertLeave *.pml lua require("spin.util").check_on_insert_leave()
augroup end

command! SpinCheck    lua require("spin").check()
command! SpinGenerate lua require("spin").generate()
command! SpinVerify   lua require("spin").verify()
