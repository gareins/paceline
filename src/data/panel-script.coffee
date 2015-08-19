###################
#                 #
# runs on startup #
#                 #
###################

preinit = () ->
  root = exports ? this
  # globals
  root.uname_input     = $("#uname-input")
  root.site_input      = $("#site-input")
  root.content_div     = $("#content")
  root.wrapper_div     = $("#wrapper")
  root.pass_label      = $("#gen-pass")
  root.content_error_p = $("#content-error-p")
  root.site_input_img  = $('#site-input-img img')

  root.stat_img_0      = $("img.border-inactive[stat='0']")
  root.stat_img_1      = $("img.border-inactive[stat='1']")
  root.stat_img_2      = $("img.border-inactive[stat='2']")

  # port handlers
  self.port.on 'pass-returned', on_pass_returned
  self.port.on 'show-first',    init
  self.port.on 'fill-settings', fill_settings
  self.port.on 'set-page-stat', set_page_stat
  self.port.on 'tab-data',      set_site_input

  # click handlers
  $('#copy-button')      .on 'click'  , on_copy_click
  $('.pane-btn')         .on 'click'  , on_slide_lr_click
  $('#uname-input')      .on 'keyup'  , generate_send # compute password on any
  $('#site-input')       .on 'keyup'  , generate_send # keyup event for site/uname
  $('textarea')          .on 'keydown', loose_focus_textarea_on_keyup
  $('#mode-select')      .on 'change' , on_simple_setting_change
  $('#length-select')    .on 'change' , on_simple_setting_change
  $('#bit2string-select').on 'change' , on_simple_setting_change
  $('#check-save')       .on 'click'  , on_save_password_checkbox_click
  $('#check-hidden')     .on 'change' , on_hide_password_change
  $('textarea')          .on 'change' , on_textarea_change
  $('#password-input')   .on 'change' , on_password_input_change
  $('.border-inactive')  .on 'click'  , on_status_image_click
  $('#site-input-img')   .on 'click'  , on_site_img_click
  $('#reset')            .on 'click'  , on_reset

  # other
  delay = 75

  $('#copy-button').tooltipsy {delay:delay}
  stat_img_0       .tooltipsy {delay:delay}
  stat_img_1       .tooltipsy {delay:delay}
  stat_img_2       .tooltipsy {delay:delay}

##################
#                #
# Helper methods #
#                #
##################

# slide divs up-down helper
slide_lr = (el, length) ->
  go_right = $(el).hasClass("btn-right")
  go_left = $(el).hasClass("btn-left")
  width = wrapper_div.width()
  margin_now = content_div.css("margin-left")

  margin_now = parseInt(margin_now.substring(0,margin_now.length-2),10)

  # check boundaries
  if not (go_left or go_right)
    return

  margin_nxt = margin_now +
    (if go_right then -width else width)

  content_div.animate(
    {"margin-left": margin_nxt + "px"},
    length,
    null
  )

# send password info on username/webpage change
generate_send = () ->
  uname = uname_input.val()
  site  = site_input.val()
  self.port.emit 'generate', uname, site

# on settings change function handler
on_setting_change = (setting, value) ->
  self.port.emit 'apply-setting', setting, value
  generate_send()

# Sets icon border accordingly to status
set_page_stat = (stat) ->
  stat_img_0.removeClass()
  stat_img_1.removeClass()
  stat_img_2.removeClass()

  switch stat
    when 0
      stat_img_0.addClass("border-active")
      stat_img_1.addClass("border-inactive")
      stat_img_2.addClass("border-inactive")
    when 1
      stat_img_0.addClass("border-inactive")
      stat_img_1.addClass("border-active")
      stat_img_2.addClass("border-inactive")
    when 2
      stat_img_0.addClass("border-inactive")
      stat_img_1.addClass("border-inactive")
      stat_img_2.addClass("border-active")

# Fill sesttings form
fill_settings = (settings) ->
  $('#check-hidden')     .attr 'checked', settings.hidden
  $('#check-save')       .attr 'checked', settings.save
  $('#mode-select')      .val settings.mode
  $('#length-select')    .val settings.length
  $('#text-content')     .val settings.content
  $('#bit2string-select').val settings.bit2str
  $('#password-input')   .val settings.password

  # set page_stat
  stat = if settings.active then 0 else 2
  set_page_stat stat


# initialization sequence
init = (settings) ->
  #init scrollbar
  $("#help-div").perfectScrollbar {suppressScrollX: true}
  content_div.css("margin-left", -wrapper_div.width())

  #fill settings
  fill_settings settings
  pass = settings.password

  # generate password for empty uname/page
  self.port.emit 'generate', "", ""

  # hide content error paragraph
  $("#content-error-p").hide()


##################
#                #
# Event Handlers #
#                #
##################

on_copy_click = () ->
  self.port.emit 'copy', $( this ).prev().text()

on_slide_lr_click = () ->
  slide_lr $(this), 200

on_pass_returned = (pass) ->
  pass_label.text(pass) # fill password box

on_site_img_click = () ->
  site_input.val(site_input_img.attr('alt'))

set_site_input = (favicon, url) ->
  site_input_img.attr('src', favicon)
  site_input_img.attr('alt', url)

loose_focus_textarea_on_keyup = (e) ->
  if e.keyCode == 13 #if key==Enter
    e.preventDefault()
    $(':focus').blur()

on_simple_setting_change = () ->
  el = $( this )
  on_setting_change el.attr("name"), el.val()

on_save_password_checkbox_click = () ->
  on_setting_change "save", $( this ).prop("checked")

on_hide_password_change = () ->
  $("#password-input").attr(
    'type',
    if $("#check-hidden").prop('checked') then "password" else "text"
  )
  on_setting_change "hidden", $( this ).prop("checked")

on_password_input_change = () ->
  self.port.emit 'password-change', $( this ).val()
  generate_send()

on_reset = () ->
  self.port.emit 'reset'

on_textarea_change = () ->
  el = $( this )
  allowed = ["site.url", "uname", "pass"]

  txt = el.val()
  re = /\[([^\]]+)\]/g

  found = null
  for m in txt.match(re)
    do (m) ->
      m = m.substring 1, m.length-1
      if m not in allowed
        found = m

  if found
    content_error_p.show()
    content_error_p.children().eq(1).text("Error: " + found)
  else
    content_error_p.hide()
    on_setting_change "content", txt

on_status_image_click = () ->
  img = $( this )
  stat = parseInt(img.attr "stat")

  if img.hasClass("border-active")
    return #already picked...

  set_page_stat stat
  self.port.emit 'change-stat', stat

# # # # # # # # # # #
preinit() # Preinit #
# # # # # # # # # # #
