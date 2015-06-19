chk_url = (url1) ->
  if !window.location
    return false
    
  url2 = window.location.href
  if url2.match(new RegExp('.*.(js|css)'))
    return false
    
  a_url = document.createElement('a')
  a_url.href = url1
  url1 = a_url.hostname
  
  a_url = document.createElement('a')
  a_url.href = url2
  url2 = a_url.hostname
  
  if url1 != url2
    return false
  true

chk_passwd = (url) ->
  if !chk_url(url)
    return
    
  # todo: for gmail hidden password...
  # todo: on DOM change listener for coursera, 24ur.com, weebly
  # todo: partis.si
  inputs = $(document)
      .find('input')
      .filter("[type='password'], [type='text'], [type='email']")
      .filter(":visible")
  
  pass_idx = -1
  i = 0
  while i < inputs.length
    #inputs.each(function(i, e) {
    if $(inputs[i]).attr('type') == 'password'
      pass_idx = i
      break
    i++
    
  if pass_idx <= 0
    return
    
  $(inputs[pass_idx - 1]).css 'background-color', 'green'
  $(inputs[pass_idx]).css 'background-color', 'red'
  return

self.port.on 'getInput', chk_passwd
