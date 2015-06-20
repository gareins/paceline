re_self    = require('sdk/self')
re_tabs    = require('sdk/tabs')
re_pagemod = require('sdk/page-mod')
re_action  = require('sdk/ui/button/action')
re_panel   = require('sdk/panel')
re_crypto  = require('crypto-js')

# Construct a panel, loading its content from the "text-entry.html"
# file in the "data" directory, and loading the "get-text.js" script
# into it.
text_entry = re_panel.Panel(
  contentURL: re_self.data.url('text-entry.html')
  contentScriptFile: re_self.data.url('get-text.js'))

# Create a button
# Show the panel when the user clicks the button.
handleClick = (state) ->
  text_entry.show()
  return

re_action.ActionButton
  id: 'show-panel'
  label: 'Show Panel'
  icon:
    '16': './icon-16.png'
    '32': './icon-32.png'
    '64': './icon-64.png'
  onClick: handleClick

# When the panel is displayed it generated an event called
# "show": we will listen for that event and when it happens,
# send our own "show" event to the panel's script, so the
# script can prepare the panel for display.
text_entry.on 'show', ->
  text_entry.port.emit 'show'
  return

# Listen for messages called "text-entered" coming from
# the content script. The message payload is the text the user entered.
# In this implementation we'll just log the text to the console.
text_entry.port.on 'text-entered', (text) ->
  console.log text
  text_entry.hide()
  return

_pl_get_pass = (uname, url, opts) ->
  # for now, without option only for length, default 13
  to_hash = uname + url + opts.password
  console.log(to_hash)

  pass = (re_crypto.SHA256 to_hash).substring(0,13)
  return pass

# on ready...
re_pagemod.PageMod
  include: '*'
  exclude: [
    '*.js'
    '*.css'
  ]
  contentScriptWhen: "ready"
  contentScriptFile: [
    re_self.data.url('jquery-2.1.4.min.js')
    re_self.data.url('input-get.js')
  ]
  onAttach: (worker) ->
    worker.port.emit 'enable', re_tabs.activeTab.url

    worker.port.on 'username', ((uname, url) ->
      _pl_get_pass uname, url, {"password": "password"}
      return
    )
    return
