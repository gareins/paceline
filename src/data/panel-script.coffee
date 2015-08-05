# click handler for "help" alert link
$( "#help-alert" ).on "click", () ->
  alert """
    Help setting up paceline.

    Use cryptographic functions to generate your password, based on
    username, website data and your personal password.

    Hash functions use input content and output random looking
    string. Cipher functions do the same, only you need to also provide
    encryption key, to use those.

    Choosing content and key can be achieved using your password, username
    and website data. Example below:

    content: '[site.url]rnd[uname][pass]'
    function: SHA512

    For 'facebook.com', username 'john.snow' and password 'iknownothing':
    SHA512(facebook.comrndjohn.snowiknownothing) =
      'wDJwpKEd3KNM8JZnavV0T21Rwz7a6ELLfv34aHiRkSavVc...'

    We currently only support two ways to generate password string from
    given bit stream of criptographic function outputs. These two are:
    - HAX[0:password_length]
    - base64[0:password_length], where invalid non digit or letter
      characters are removed. If Resulting string is too short, we
      append zeroes.

    Currently supported website data is its url, but more could be added
    in future.
  """


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
  root.pass_label      = $("#gen-pass")
  root.content_error_p = $("#content-error-p")

  root.stat_img_0      = $("img.border-inactive[stat='0']")
  root.stat_img_1      = $("img.border-inactive[stat='1']")
  root.stat_img_2      = $("img.border-inactive[stat='2']")

  # port handlers
  self.port.on 'pass-returned', on_pass_returned
  self.port.on 'show_first',    init
  self.port.on 'set_page_stat', set_page_stat

  # click handlers
  $('#copy-button')      .on 'click'  , on_copy_click
  $('.heading-div')      .on 'click'  , on_slide_ud_click
  $('#uname-input')      .on 'keyup'  , generate_send # compute password on any
  $('#site-input')       .on 'keyup'  , generate_send # keyup event for site/uname
  $('textarea')          .on 'keydown', loose_focus_textarea_on_keyup
  $('#mode-select')      .on 'change' , on_simple_setting_change
  $('#length-select')    .on 'change' , on_simple_setting_change
  $('#bit2string-select').on 'change' , on_simple_setting_change
  $("#check-save")       .on 'click'  , on_save_password_checkbox_click
  $("#check-hidden")     .on 'change' , on_hide_password_change
  $("textarea")          .on 'change' , on_textarea_change
  $("#password-input")   .on 'change' , on_password_input_change
  $(".border-inactive")  .on 'click'  , on_status_image_click

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

update_scrollbar = () ->
  content_div.perfectScrollbar('update')

# slide divs up-down helper
slide_up_down = (el, length) ->
  if el.is(":hidden")
    el.show()
    el.animate(
      {"margin-bottom": "0px", "opacity": 1},
      length,
      update_scrollbar
    )
  else
    el.animate(
      {"margin-bottom": ("-" + el.css "height"), "opacity": 0},
      length,
      () ->
        el.hide()
        update_scrollbar()
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

# initialization sequence
init = (pass, settings) ->
  #init scrollbar
  content_div.perfectScrollbar {suppressScrollX: true}

  # fill settings
  $('#check-hidden')     .attr 'checked', settings.hidden
  $('#check-save')       .attr 'checked', settings.save
  $('#mode-select')      .val settings.mode
  $('#length-select')    .val settings.length
  $('#text-content')     .val settings.content
  $('#bit2string-select').val settings.bit2str
  $("#password-input")   .val pass

  # set page_stat
  if !settings.enable
    set_page_stat 2

  #hide divs on startup
  for h1 in $( "h1" )
    do(h1) ->
      h = $(h1)

      # if password not present, show only password div
      # if password is present, show only generate div
      if !(pass.length == 0 && h.text() == "Password") &&
         !(pass.length > 0  && h.text() == "Generate")

        slide_up_down h.parent().parent().next(), 10

  # generate password for empty uname/page
  self.port.emit 'generate', "", ""

  # hide content error paragraph
  $("#content-error-p").hide()
  on_hide_password_change()



##################
#                #
# Event Handlers #
#                #
##################

on_copy_click = () ->
  self.port.emit 'copy', $( this ).prev().text()

on_slide_ud_click = () ->
  slide_up_down $(this).next(), 200

on_pass_returned = (pass) ->
  pass_label.text(pass) # fill password box

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

  update_scrollbar()

on_status_image_click = () ->
  img = $( this )
  stat = parseInt(img.attr "stat")

  if img.hasClass("border-active")
    return #already picked...

  set_page_stat stat
  self.port.emit 'change-stat', stat
  on_setting_change "enable", nxt_stat


# # # # # # # # # # #
preinit() # Preinit #
# # # # # # # # # # #
