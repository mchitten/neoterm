function! s:CurrentFilePath()
  return @%
endfunction

function! s:InSpecFile()
  return match(expand("%"), "_spec.rb$") != -1
endfunction

function! s:getSpecForFile()
  if s:InSpecFile()
    return s:CurrentFilePath()
  else
    let possible_spec_file = substitute(s:CurrentFilePath(), "app/", "", "")
    let possible_spec_file = substitute(possible_spec_file, ".rb", "_spec.rb", "")
    let possible_spec_file = "spec/" . possible_spec_file

    let path = ''
    if filereadable(possible_spec_file)
      let path = possible_spec_file
    else
      if !exists('g:rspec_file_mappings')
        return ''
      endif

      let curPath = s:CurrentFilePath()
      for [key,val] in items(g:rspec_file_mappings)
        if curPath =~ key
          let path = substitute(curPath, key, val, "")
          break
        endif
      endfor

      if empty(path) || filereadable(path) == 0
        return ''
      endif
    endif

    return path
  endif
endfunction

function! neoterm#test#rspec#find()
  let path = s:getSpecForFile()
  if empty(path)
    echoe 'could not find matching spec file'
    return ''
  else
    execute 'edit ' . path
    return ''
  endif
endfunction

function! neoterm#test#rspec#run(scope)
  let path = g:neoterm_use_relative_path ? expand('%') : expand('%:p')

  if exists('g:neoterm_rspec_lib_cmd')
    let command = g:neoterm_rspec_lib_cmd
  else
    let command = 'bundle exec rspec'
  end

  if a:scope == 'file'
    let path = s:getSpecForFile()
    if empty(path)
      echoe 'could not find matching spec file'
      return ''
    else
      let command .= ' ' . path
    endif
  elseif a:scope == 'current'
    let command .= ' ' . path . ':' . line('.')
  endif

  return command
endfunction

function! neoterm#test#rspec#result_handler(line)
  let counters = matchlist(
        \ a:line,
        \ '\(\d\+\|no\) failures\?'
        \ )

  if !empty(counters)
    let failures = counters[1]

    if str2nr(failures) == 0
      let g:neoterm_statusline = g:neoterm_test_status.success
    else
      let g:neoterm_statusline = g:neoterm_test_status.failed
    end
  end
endfunction
