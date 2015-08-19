#
# TODO:
# - fix quick typing at page load
#
# LATER:
# - predefined options?
# - list of disabled sites?
#
# BUGS: 
# - feedly -> twitter...
#
# FIX
#  51: Site nogomania.com had default value for username
#      and also password field turned into type=password
#      only after keystrokes.

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

set_interval = require("sdk/timers").setInterval

#
# Handler for disable/shutdown
#

exports.onUnload = (reason) ->
  if reason in ['disable', 'shutdown']
    if not Storage.get_setting 'save'
      Storage.set_setting 'password', ''

#
#
# Set implementation
#
#

class MiniSet
  constructor: ()->
    @data = {}
    if arguments.length == 1
      if (typeof arguments[0] != 'undefined')
        for k in arguments[0]
          @data[k] = true

  get_list: () ->
    lst = []
    for k,_ of @data
      lst.push k
    return lst

  remove: (item)   -> delete @data[item]
  add: (item)      -> @data[item] = true
  contains: (item) -> return (typeof @data[item] != 'undefined')

#
#
# Calculation of passwords
#
#

class Crypto
  constructor: () ->
    @cipher = re_worker.Page {
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
  get_pass: (uname, url, return_func) ->
    s = re_storage.storage.settings
    pass = Storage.get_setting 'password'

    content = s.content
    content = content.replace(/\[uname\]/g, uname)
    content = content.replace(/\[pass\]/g, pass)
    content = content.replace(/\[site\.url\]/g, url)

    @cipher.port.emit "hash", content, s.mode, s.bit2str
    @cipher.port.once "ret", (c) ->
      c = c.replace(/\//g,"") #TODO: make only one regex :)
      c = c.replace(/\+/g,"")
      c = c.replace(/=/g,"")

      while c.length < s.length #TODO: this could be done O(1), but it's 2AM...
        c = c + "0"
      return_func (c.substring 0, s.length)

crypto = new Crypto()

#
#
# Getting correct inputs
# and reading/filling them
#
#

class AutoFiller
  constructor: () ->
    @tabs = {}
    @active_tab = null

  start: (tab) ->
    old_active_tab = @active_tab
    @active_tab = re_tabs.activeTab.id

    # If tab changed -> do not attach, because already running
    if old_active_tab != @active_tab
      return

    @tabs[tab.id] = tab.attach
      contentScriptFile: [
        re_self.data.url('jquery.min.js')
        re_self.data.url('input-get.js')
      ]

    # DEBUG: Check if attachment success
    if typeof @tabs[tab.id] == 'undefined'
      console.error "Why not attached ??"
      return

    tabs_port = @tabs[tab.id].port

    tabs_port.emit 'enable', tab.url
    tabs_port.on 'username', (uname, url) ->
      crypto.get_pass uname, url, (p) ->
        tabs_port.emit 'pass', p

  stop: (tab) ->
    if @tabs[tab.id]
      @tabs[tab.id].destroy()

    delete @tabs[tab.id]

  apply_stat: (stat, tab) ->
    if stat == 0
      @.start tab
    else if stat == 1
      @.stop tab

auto_filler = new AutoFiller()

#
#
# Storage class
#
#

Storage = {}
Storage =
  _s: re_storage.storage
  
  handle_boot: () ->
    if not Storage._s.settings
      Storage._s.settings =
        'hidden': true
        'save': true
        'mode': 'sha1'
        'length': '12'
        'content': '[site.url][uname][pass]'
        'bit2str': 'b64'
        'active': true
        'password': ''
      Storage._s.ds_list = new Array()
      Storage._s.disabled_sites = new MiniSet()
    else
      Storage._s.disabled_sites = new MiniSet(Storage._s.ds_list)

    # Set initial stat; TODO: this should be moved elsewhere
    apply_status_wrapper (if Storage.is_active() then 0 else 2)

  is_site_disabled: (site) ->
    return Storage._s.disabled_sites.contains site

  enable_site: (url) ->
    Storage._s.disabled_sites.remove url

  disable_site: (url) ->
    Storage._s.disabled_sites.add url

  is_active: () ->
    Storage._s.settings.active

  set_setting: (key, value) ->
    if not (key of Storage._s.settings)
      console.error "key: " + key + " not in store.settings!!"
      return
    Storage._s.settings[key] = value

  get_all_settings: () ->
    Storage._s.settings

  get_setting: (key) ->
    return Storage._s.settings[key]

  store_disabled_sites: () ->
    Storage._s.ds_list = Storage._s.disabled_sites.get_list()

  reset_all: () ->
    delete Storage._s.settings
    delete Storage._s.ds_list
    delete Storage._s.disabled_sites
    Storage.handle_boot()

    panel.port.emit 'fill-settings', Storage.get_all_settings()

#
#
# Panel and button objects
#
#

button = re_toggleb.ToggleButton
  id: 'pl_button'
  label: 'Paceline'
  icon:
    '16': './icons/green_16.png'
    '32': './icons/green_32.png'
    '64': './icons/green_64.png'
  onChange: (state) -> if state.checked then panel.show()

panel = re_panel.Panel
  width: 225
  height: 350
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
  onHide: () -> button.state 'window', {checked: false}

#
#
# Function called on status change
# 
#

apply_status_wrapper = (stat, url) ->
  # Set all variables
  Storage.set_setting 'active', (stat != 2)      # store in storage
  panel.port.emit 'set-page-stat', stat          # inform panel
  auto_filler.apply_stat stat, re_tabs.activeTab # inform page auto_filler

  # change button accordingly
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
        '16': './icons/transparent_16.png'
        '32': './icons/transparent_32.png'
        '64': './icons/transparent_64.png'

  # check if active
  if not Storage.is_active()
    return

  # check if url is "real"
  if !url
    return

  # enable/disable site
  if stat == 0
    Storage.enable_site(url)
  else if stat == 1
    Storage.disable_site(url)

#
#
# Event listeners
# 
#

on_panel_generate = (uname, url) ->
  panel_port = panel.port
  crypto.get_pass uname, url, (p) ->
    panel_port.emit 'pass-returned', p

on_panel_copy = (txt) ->
  # send text to clipboard on copy
  re_clipboard.set txt, "text"

on_panel_password_change = (pass) ->
  Storage.set_setting 'password', pass
  panel.port.emit 'pass-returned', ""

on_panel_change_stat = (stat) ->
  apply_status_wrapper stat, re_url.URL(re_tabs.activeTab.url).host

on_change_tab = (t) ->
  if Storage.is_active()
    url = re_url.URL(t.url).host
    stat = if Storage.is_site_disabled(url) then 1 else 0
    apply_status_wrapper stat, url
  
  # Using getFavicon was way too slow, t.favicon
  # on the other side was unreliable and deprecated.
  # Thus, I am using this workaround. Thanks, google.

  # Sending new favicon and url to panel
  favicon = "http://www.google.com/s2/favicons?domain=" + url
  panel.port.emit 'tab-data', favicon, url

on_reset = () ->
  Storage.reset_all()

#
#
# Start listening for events
#
#

panel.port.on 'apply-setting',   Storage.set_setting
panel.port.on 'generate',        on_panel_generate
panel.port.on 'copy',            on_panel_copy
panel.port.on 'password-change', on_panel_password_change
panel.port.on 'change-stat',     on_panel_change_stat
panel.port.on 'reset',           on_reset
re_tabs.on    'ready',           on_change_tab
re_tabs.on    'activate',        on_change_tab


# Store disabled_sites list every so often
set_interval (() -> Storage.store_disabled_sites()), 1000

# Init Storage
Storage.handle_boot()

# Inform panel to initialize itself!
panel.port.emit 'show-first', Storage.get_all_settings()
