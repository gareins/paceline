#
# TODO:
# - work only on this page
# - crypto
#
# LATER:
# - green acknowledgment on password change
# - predefined options?
# - list of disabled sites?
# - animation on copy
#

re_self      = require('sdk/self')
re_tabs      = require('sdk/tabs')
re_pagemod   = require('sdk/page-mod')
re_action    = require('sdk/ui/button/action')
re_panel     = require('sdk/panel')
#re_crypto    = require('crypto-js') # use page-worker!!
re_toggleb   = require('sdk/ui/button/toggle')
re_storage   = require('sdk/simple-storage')
re_url       = require('sdk/url')
re_clipboard = require('sdk/clipboard')

#
#
# Calculation of passwords
#
#

_pl_get_pass = (uname, url) ->
  s = re_storage.storage.settings

  content = s.content
  content = content.replace(/\[uname\]/g, uname)
  content = content.replace(/\[pass\]/g, re_storage.storage.password)
  content = content.replace(/\[site\.url\]/g, url)

  return s.bit2str + "(" + s.mode + "(" + content + "))[0:" + s.length + "]"
  # pass = (re_crypto.SHA256 to_hash).substring(0,13)

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
    '16': './icons/green_16.png'
    '32': './icons/green_32.png'
    '64': './icons/green_64.png'
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


panel.port.on 'generate', ((uname, url) ->
  pass = _pl_get_pass uname, url
  panel.port.emit 'pass-returned', pass
)

panel.port.on 'copy', (txt) ->
  re_clipboard.set txt, "text"

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

#
#
# Settings manipulation and
# store
#
#

store = re_storage.storage
default_settings =
  'hidden': false
  'save': false
  'mode': 'sha1'
  'length': '12'
  'content': 'ozbo[site.url][uname][pass]'
  'bit2str': 'b64'
  'enable': true

if not store.settings
  store.settings = default_settings
  store.password = ""
  store.disabled_sites = new Set([])

panel.port.on 'apply-setting', ((key, value) ->
  if not (key of store.settings)
    console.log "key not in store.settings!!"
    return
  store.settings[key] = value
)

panel.port.on 'password-change', (pass) ->
  store.password = pass
  panel.port.emit 'pass-returned', ""

# listener for panel click to change stat
panel.port.on 'change-stat', (stat) ->
  url = re_url.URL(re_tabs.activeTab.url).host
  if !url #for non-url pages
    return

  #save to disabled_sites
  ds = store.disabled_sites
  if stat
    ds.delete(url)
  else
    ds.add(url)

#
#
# Init
#
#

panel.port.emit 'show_first', store.password, store.settings
