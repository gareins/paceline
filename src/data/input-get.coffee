_pl_chk_url = (url1) ->
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

_pl_init_inputs = (url) ->
  if !_pl_chk_url(url)
    return
    
  # todo: for gmail hidden password...
  _pl_globals.inputs = $(document)
      .find('input')
      .filter("[type='password'], [type='text'], [type='email']")
  
  observer = new MutationObserver _pl_body_change_listener
  target = ($ "body").get(0)
  config =
    childList: true
    subtree: true
  observer.observe target, config

  _pl_choose_input()
  setInterval _pl_choose_input,500
  return

_pl_body_change_listener = (mutations) ->
  mutations.forEach((mut) ->
    if mut.addedNodes.length > 0
      for node in mut.addedNodes
        do (node) ->
          ($ node)
            .find("input")
            .filter("[type='password'], [type='text'], [type='email']")
            .map () ->
              _pl_globals.inputs.push($ this)
  )
  return

_pl_input_change_listener = (mutations) ->
  console.log "inpt"
  return

_pl_choose_input = () ->
  inpts_table = _pl_globals.inputs.map(->
    t = $( this )
    return [[
      t.attr("type") == "password"
      t.is(":visible")
    ]]
  ).get()

  console.log inpts_table

  _pl_globals.inputs.map () ->
      el = ($ this)
      if el.is(":visible")
          el.css 'background-color', 'green'
      else
          el.css 'background-color', 'yellow'
  

  #pass_idx = -1
  #i = 0
  #while i < inputs.length
  #  #inputs.each(function(i, e) {
  #  if $(inputs[i]).attr('type') == 'password'
  #    pass_idx = i
  #    break
  #  i++
  #  
  #if pass_idx <= 0
  #  return
  #  
  #$(inputs[pass_idx - 1]).css 'background-color', 'green'
  #$(inputs[pass_idx]).css 'background-color', 'red'
  return

_pl_globals = exports ? this
_pl_globals.inputs = []

self.port.on 'getInput', _pl_init_inputs
