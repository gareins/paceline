#############
#           #
#  Helpers  #
#           #
#############

# check url for js/css
chk_url = (url1) ->
  # I don't remember why this check is done...
  if !window.location
    return false

  # Filter css and js sites // TODO: probably not neaded
  url2 = window.location.href
  if url2.match(new RegExp('.*.(js|css)'))
    return false

  # Filter about:xx firefox pages
  if url2.indexOf("about:") == 0
    return false

  a_url = document.createElement('a')
  a_url.href = url1
  url1 = a_url.hostname
  
  a_url = document.createElement('a')
  a_url.href = url2
  url2 = a_url.hostname

  # check if document not from another site (like add or something)
  if url1 != url2
    return false

  globals.hostname = url1
  true

init = (url) ->
  if !chk_url(url)
    return
  
  # Find all inputs of certain type
  globals.inputs = $(document)
      .find('input')
      .filter("[type='password'], [type='text'], [type='email']")
  
  # Configure and start observer
  observer = new MutationObserver body_change_listener
  target = $("body").get(0)
  config =
    childList: true
    subtree: true
  observer.observe target, config

  # Takes all inputs and "figures out" the right one
  choose_input true

  # Check for change in input field every 0.6 second
  interval = setInterval choose_input, 600

  globals.observer = observer
  globals.interval = interval
  return

# Listening for new inputs, that are not hidden anymore
# or are ajax-ed in to the page
body_change_listener = (mutations) ->
  mutations.forEach (mut) ->
    if mut.addedNodes.length > 0
      for node in mut.addedNodes
        do (node) ->
          ($ node)
            .find("input")
            .filter("[type='password'], [type='text'], [type='email']")
            .map () -> globals.inputs.push($ this)

# Choosing correct input field for username and password
choose_input = () ->
  inputs = globals.inputs
  unameIdx = -1

  # This goes through all inputs, and finds first visible password field 
  # and picks it as a password field. One before is username field
  for i in [0..inputs.length-2]
    no1 = $(inputs[i])
    no2 = $(inputs[i+1])
    no3 = $(inputs[i+2])

    ## first is not password
    bool1 = (no1.attr("type") != 'password') && (no1.is(":visible"))

    ## second is password
    bool2 = (no2.attr("type") == 'password') && (no2.is(":visible"))

    # if password in #id -> also good (#FIX 51)
    if bool2 == false && (no2.is ':visible') && (no2.attr 'id')
      no2_id = no2.attr('id').toLowerCase()
      bool2 = (no2_id.indexOf('password') > -1) && (no2.is(":visible"))

    ## third is also password => this is probably registation form
    bool3 = (i+2 == inputs.length) ||
            (no3.is ":hidden") ||
            (no3.attr("type") != 'password')

    if bool1 && bool2 && bool3
      unameIdx = i
      break

  if unameIdx < 0
    return

  # Check if we already generated password for this username (#FIX 51)
  uname = no1.val()
  if uname != globals.uname && uname.length > 0
    # both fields are saved into globals
    globals.uname = uname
    globals.inputIdx = unameIdx

    # If first time, do not generate password (#FIX 51)
    if arguments.length == 0
      # Generate password
      self.port.emit "username", uname, globals.hostname
 
  return

#############
#           #
#  Globals  #
#           #
#############

root = exports ? this
root.globals =
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
  globals.observer.disconnect()
  clearInterval globals.interval
  globals.inputs = []

self.port.on 'pass', (pass) ->
  inpt = $(globals.inputs[globals.inputIdx + 1])
  # some password fields are not type=password, so check for type (#FIX 51)
  if inpt.attr('type') != 'password'
    inpt.attr('type', 'password')

  on_generated_password_change inpt
  inpt.val(pass)

self.port.on 'enable', init

#############################
#                           #
# Password change animation #
#                           #
#############################

on_generated_password_change = (inpt) ->
  end_opacity = inpt.css('opacity')

  inpt.css('opacity': 0)
  inpt.animate(
    {opacity: end_opacity},
    100,
    () -> return
  )
