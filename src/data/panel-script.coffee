
# click handler for "help" alert link
$( "#help-alert" ).on "click", (() ->
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
)

# fill password box on pass-returned event
self.port.on 'pass-returned', ((pass) ->
  $("#gen-pass").text(pass)
)

# send password info on username/webpage change
generate_send = () ->
  uname = $("#uname-input").val()
  site  = $("#site-input").val()
  self.port.emit 'generate', uname, site

# slide divs up-down when requested
slide_up_down = ((el, length) ->
  if el.is(":hidden")
    el.show()
    el.animate(
      {"margin-bottom": "0px", "opacity": 1},
      length,
      () -> $('#content').perfectScrollbar('update')
    )

  else
    el.animate(
      {"margin-bottom": ("-" + el.css "height"), "opacity": 0},
      length,
      () ->
        el.hide()
        $('#content').perfectScrollbar('update')
    )
)

# initialization sequence
self.port.on 'show_first', ((pass) ->
  #init scrollbar
  $('#content').perfectScrollbar({
    suppressScrollX: true
  })

  #hide divs on startup
  for h1 in $( "h1" )
    do(h1) ->
      h = $(h1)

      # if password not present, show only password div
      # if password is present, show only generate div
      if !(pass.length == 0 && h.text() == "Password") &&
         !(pass.length > 0  && h.text() == "Generate")

        slide_up_down h.parent().next(), 10

  # on click -> slide up/down
  $( '.hr' ).on "click", () ->
    slide_up_down $(this).parent().next(), 200

  $( "#password-input" ).val( pass )

  # generate password for empty uname/page
  self.port.emit 'generate', "", ""

  $("#uname-input").on "keyup", generate_send
  $("#site-input") .on "keyup", generate_send

  $("#content-error-p").hide()
)

#loose focus on enter key
$("textarea").on "keydown", (e) ->
  if e.keyCode == 13
    e.preventDefault()
    $(':focus').blur()

# on settings change function handler
on_setting_change = ((setting, value) ->
  #ALL TODO
  console.log setting, value
)

# for couple of simple settings change
on_simple_setting_change = () ->
  el = $( this )
  on_setting_change el.val(), el.attr "name"

# saving settings on change: imple versions
$("#mode-select").change       on_simple_setting_change
$("#length-select").change     on_simple_setting_change
$("#bit2string-select").change on_simple_setting_change

# handler for "save password" checkbox
$("#check-save").on "click", () ->
  on_setting_change $( this ).prop("checked"), "save"

# click handler for "hide password" checkbox
$( "#check-hidden" ).on "click", (() ->
  $("#password-input").attr 'type',
    if $(this).prop('checked') then "password" else "text"

  on_setting_change $( this ).prop("checked"), "hidden"
)

# change handler for "content" text field
$("textarea").change (() ->
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

  cep = $("#content-error-p")

  if found
    cep.show()
    cep.children().eq(1).text("Error: " + found)
  else
    cep.hide()
    on_setting_change txt, "content"

  $('#content').perfectScrollbar('update')
)

# hangeld for image click
$("#site-stat").on "click", (() ->
  img = $( this )
  stat = img.attr("stat")
  a = (f,s) -> img.attr(f,s)

  switch img.attr("stat")
    when "0"
      a("stat", "1"); a("src", "berr.png"); a("alt", "Disabled for this page")
    when "1"
      a("stat", "2"); a("src", "rerr.png"); a("alt", "Disabled for all pages")
    else
      a("stat", "0"); a("src", "ok.png"); a("alt", "Enabled for this site")

  img.next().text img.attr("alt")
  on_setting_change img.attr("stat"), "enable"
)

