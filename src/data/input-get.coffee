#############
#           #
#  Helpers  #
#           #
#############

# check url for js/css
_pl_chk_url = (url1) ->
  if !window.location
    return false
    
  url2 = window.location.href
  if url2.match(new RegExp('.*.(js|css)'))
    return false

  console.log window.location.href
    
  a_url = document.createElement('a')
  a_url.href = url1
  url1 = a_url.hostname
  
  a_url = document.createElement('a')
  a_url.href = url2
  url2 = a_url.hostname
  
  # check if document not from another site (like add or something)
  if url1 != url2
    return false

  _pl_globals.hostname = url1
  true

_pl_init = (url) ->
  if !_pl_chk_url(url)
    return

  # Find all inputs of certain type
  _pl_globals.inputs = $(document)
      .find('input')
      .filter("[type='password'], [type='text'], [type='email']")
  
  # Configure and start observer
  observer = new MutationObserver _pl_body_change_listener
  target = ($ "body").get(0)
  config =
    childList: true
    subtree: true
  observer.observe target, config

  # Takes all inputs and "figures out" the right one
  _pl_choose_input()
  # Check for change in input field every 0.6 second
  interval = setInterval _pl_choose_input, 600

  _pl_globals.observer = observer
  _pl_globals.interval = interval
  return

# Listening for new inputs, that are not hidden anymore
# or are ajax-ed in to the page
_pl_body_change_listener = (mutations) ->
  mutations.forEach (mut) ->
    if mut.addedNodes.length > 0
      for node in mut.addedNodes
        do (node) ->
          ($ node)
            .find("input")
            .filter("[type='password'], [type='text'], [type='email']")
            .map () -> _pl_globals.inputs.push($ this)

# Choosing correct input field for username and password
_pl_choose_input = () ->
  inputs = _pl_globals.inputs
  unameIdx = -1

  # This goes through all inputs, and finds first visible password field 
  # and picks it as a password field. One before is username field
  for i in [0..inputs.length-2]
    no1 = $(inputs[i])
    no2 = $(inputs[i+1])
    no3 = $(inputs[i+2])

    bool1 = (no1.attr("type") != 'password') && (no1.is(":visible"))
    bool2 = (no2.attr("type") == 'password') && (no2.is(":visible"))
    bool3 = (i+2 == inputs.length) ||
            (no3.is ":hidden") ||
            (no3.attr("type") != 'password')

    if bool1 && bool2 && bool3
      unameIdx = i
      break

  if unameIdx < 0
    return

  # both fields are saved into globals
  uname = no1.val()
  if uname != _pl_globals.uname && uname.length > 0
    _pl_globals.uname = uname
    _pl_globals.inputIdx = unameIdx

    self.port.emit "username", uname, _pl_globals.hostname
 
  return

#############
#           #
#  Globals  #
#           #
#############

_pl_root = exports ? this
_pl_root._pl_globals =
  inputs:[]
  inputIdx: -1
  uname: ""
  interval: null
  observer: null
  hostname: null

####################
#                  #
#  Port listeners  #
#                  #
####################

self.port.on 'disable', () ->
  _pl_globals.observer.disconnect()
  clearInterval _pl_globals.interval
  _pl_globals.inputs = []

self.port.on 'pass', (pass) ->
  $(_pl_globals.inputs[_pl_globals.inputIdx + 1]).val(pass)

self.port.on 'enable', _pl_init
