#
# TODO:
# - refactor this
# - fix start/stop
#
# LATER:
# - predefined options?
# - list of disabled sites?
#
# BUGS: 
# - feedly -> twitter...
# - Nogomania
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
# Set implementation
#
#

class MiniSet
  constructor: ()  -> @data = {}
  contains: (item) -> return (typeof @data[item] != 'undefined')
  remove: (item)   -> delete @data[item]
  add: (item)      -> @data[item] = true

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

panel = re_panel.Panel {
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
}

panel.port.on 'generate', ((uname, url) ->
  get_pass uname, url, (p) ->
    panel.port.emit 'pass-returned', p
)

panel.port.on 'copy', (txt) ->
  re_clipboard.set txt, "text"

change_button_icon = (stat) ->
  switch stat
    when 0
      button.icon =
        '16': './icons/green_16.png'
        '32': './icons/green_32.png'
        '64': './icons/green_64.png'
    when 1
      button.icon =
        '16': './icons/red_16.png'
        '32': './icons/red_32.png'
        '64': './icons/red_64.png'
    else
      button.icon =
        '16': './icons/grey_16.png'
        '32': './icons/grey_32.png'
        '64': './icons/grey_64.png'

#
#
# Getting correct inputs
# and reading/filling them
#
#

class AutoFiller
  constructor: () ->
    @tabs = {}

  start: (tab) ->
    if @tabs[tab.id]
      #if only switch tabs...
      return

    console.log "start"
    @tabs[tab.id] = tab.attach
      contentScriptFile: [
        re_self.data.url('jquery.min.js')
        re_self.data.url('input-get.js')
      ]

    tabs_port = @tabs[tab.id].port

    tabs_port.emit 'enable', tab.url
    tabs_port.on 'username', (uname, url) ->
      console.log 'gaining for: ', uname, url
      get_pass uname, url, (p) ->
        tabs_port.emit 'pass', p

  stop: (tab) ->
    if @tabs[tab.id]
      @tabs[tab.id].destroy()
      console.log "stop"

    delete @tabs[tab.id]

  apply_stat: (stat, tab) ->
    if stat == 0
      @.start tab
    else if stat == 1
      @.stop tab

auto_filler = new AutoFiller()

#
# Observer to detect pageload and change icons accordingly
#

apply_stat_all = (stat) ->
  change_button_icon stat
  auto_filler.apply_stat stat, re_tabs.activeTab

function_on_change_url = (t) ->
  # check if enabled
  if not store.settings.enable
    return

  url = re_url.URL(t.url).host
  if !url
    return

  stat = if is_site_disabled(url) then 1 else 0

  panel.port.emit 'set_page_stat', stat
  apply_stat_all stat

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
  'content': '[site.url][uname][pass]'
  'bit2str': 'b64'
  'enable': true

if not store.settings
  store.settings = default_settings
  store.password = ""
  store.disabled_sites = new MiniSet()

panel.port.on 'apply-setting', (key, value) ->
  if not (key of store.settings)
    console.log key + " not in store.settings!!"
    return
  store.settings[key] = value

panel.port.on 'password-change', (pass) ->
  store.password = pass
  panel.port.emit 'pass-returned', ""

# listener for panel click to change stat
panel.port.on 'change-stat', (stat) ->
  # check if checking was disabled
  store.settings.enable = stat != 2
  apply_stat_all stat

  if not store.settings.enable
    return
  else
    stat = stat==0

  # check if url is "real"
  url = re_url.URL(re_tabs.activeTab.url).host
  if !url
    return

  #save to disabled_sites
  if stat
    store.disabled_sites.remove url
  else
    store.disabled_sites.add url

is_site_disabled = (site) ->
  return store.disabled_sites.contains site

#
#
# Init
#
#

panel.port.emit 'show_first', store.password, store.settings
