#
# TODO:
# - work only on this page
#
# LATER:
# - green acknowledgment on password change
# - predefined options?
# - list of disabled sites?
#
# BUGS: 
# - feedly -> twitter...
# - change password on settings change
#

re_self      = require('sdk/self')
re_tabs      = require('sdk/tabs')
re_pagemod   = require('sdk/page-mod')
re_action    = require('sdk/ui/button/action')
re_panel     = require('sdk/panel')
re_worker    = require('sdk/page-worker')
re_toggleb   = require('sdk/ui/button/toggle')
re_storage   = require('sdk/simple-storage')
re_url       = require('sdk/url')
re_clipboard = require('sdk/clipboard')

#
#
# Calculation of passwords
#
#

cipher = re_worker.Page {
  contentScriptFile: [
    re_self.data.url('crypto/sha256.js'),
    re_self.data.url('crypto/sha512.js'),
    re_self.data.url('crypto/sha1.js'),
    re_self.data.url('crypto/sha3.js'),
    re_self.data.url('crypto/ripemd160.js'),
    re_self.data.url('crypto/md5.js'),
    re_self.data.url('crypto/enc-base64-min.js'),
    re_self.data.url('crypto.js')
  ]
}

# function takes uname and url, generates
# hash password according to settings, then
# passes resulting string to return function
get_pass = (uname, url, return_func) ->
  s = re_storage.storage.settings

  content = s.content
  content = content.replace(/\[uname\]/g, uname)
  content = content.replace(/\[pass\]/g, re_storage.storage.password)
  content = content.replace(/\[site\.url\]/g, url)

  cipher.port.emit "hash", content, s.mode, s.bit2str
  cipher.port.once "ret", (c) ->
    c = c.replace(/\//g,"") #TODO: make only one regex :)
    c = c.replace(/\+/g,"")
    c = c.replace(/=/g,"")

    while c.length < s.length #TODO: this could be done O(1), but it's 2AM...
      c = c + "0"
    return_func (c.substring 0, s.length)

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
    re_self.data.url('jquery.min.js'),
    re_self.data.url('scroll/perfect-scrollbar.jquery.min.js'),
    re_self.data.url('tooltipsy.min.js'),
    re_self.data.url('panel-script.js')
  ]
  onHide: handleHide
})

panel.port.on 'generate', ((uname, url) ->
  get_pass uname, url, (p) ->
    panel.port.emit 'pass-returned', p
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
    re_self.data.url('jquery.min.js')
    re_self.data.url('input-get.js')
  ]
  onAttach: (worker) ->
    worker.port.emit 'enable', re_tabs.activeTab.url

    worker.port.on 'username', ((uname, url) ->
      get_pass uname, url, (p) ->
        worker.port.emit 'pass', p
    )
    return

# Observer to detect pageload and change icons accordingly

function_on_change_url = (t) ->
  url = re_url.URL(t.url).host
  if !url #for non-url pages
    return

  console.log url

re_tabs.on "ready", function_on_change_url
re_tabs.on "activate", function_on_change_url

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

is_site_disabled = (site) ->
  return not (site in store.disabled_sites)

#panel.port.on 'is-site-disabled', (s) ->
#  panel.port.emit 'site-disabled', is_site_disabled(s)

#
#
# Init
#
#

panel.port.emit 'show_first', store.password, store.settings
