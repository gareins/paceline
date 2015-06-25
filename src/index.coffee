#
# TODO:
# - pass length and bit2string op
# - save settings
# - save new password
# - work on only this page
# - crypto
#

re_self    = require('sdk/self')
re_tabs    = require('sdk/tabs')
re_pagemod = require('sdk/page-mod')
re_action  = require('sdk/ui/button/action')
re_panel   = require('sdk/panel')
re_crypto  = require('crypto-js')
re_toggleb = require('sdk/ui/button/toggle')

#
#
# Calculation of passwords
#
#

_pl_get_pass = (uname, url) ->
  console.log "hashing for " + url + " and username " + uname
  # pass = (re_crypto.SHA256 to_hash).substring(0,13)
  # return pass
  return "123 " + uname + " " + url

#
#
# Panel stuff :)
#
#

handleChange = (state) ->
  if state.checked
    panel.show()

handleHide = () ->
  button.state 'window', {checked: false}

button = re_toggleb.ToggleButton
  id: 'pl_button'
  label: 'Paceline'
  icon:
    '16': './icon-16.png'
    '32': './icon-32.png'
    '64': './icon-64.png'
  onChange: handleChange

panel = re_panel.Panel({
  width: 225
  height: 400
  position: button
  contentURL: re_self.data.url('panel.html')
  contentStyleFile: [
    re_self.data.url('scroll/perfect-scrollbar.min.css')
  ]
  contentScriptFile: [
    re_self.data.url('jquery-2.1.4.min.js'),
    re_self.data.url('scroll/perfect-scrollbar.jquery.min.js'),
    re_self.data.url('panel-script.js')
  ]
  onHide: handleHide
})

panel.port.emit 'show_first', ''

panel.port.on 'generate', ((uname, url) ->
  pass = _pl_get_pass uname, url
  panel.port.emit 'pass-returned', pass
)

#
#
# Getting correct inputs
# and reading/filling them
#
#

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
      pass = _pl_get_pass uname, url
      worker.port.emit 'pass', pass
      return
    )
    return
