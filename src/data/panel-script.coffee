$( "#check-hidden" ).on "click", (() ->
  if $(this).prop('checked')
    $("#password-input").attr('type', "password")
  else
    $("#password-input").attr('type', "text")
)

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

self.port.on 'pass-returned', ((pass) ->
  $("#gen-pass").text(pass)
  console.log pass
)

generate_send = () ->
  uname = $("#uname-input").val()
  site  = $("#site-input").val()
  self.port.emit 'generate', uname, site

self.port.on 'show_first', ((pass) ->
  $('#content').perfectScrollbar({
    wheelPropagation: true
    suppressScrollX: true
    scrollXMarginOffset: 20
  })

  for h1 in $( "h1" )
    do(h1) ->
      h = $(h1)

      # if password not present, show only password div
      # if password is present, show only generate div
      if !(pass.length == 0 && h.text() == "Password") &&
         !(pass.length > 0  && h.text() == "Generate")

        h.next().toggle()

      h.after """
        <div class='hr'> <hr class='hrleft'>
        <span>&#8616;</span>
        <hr class='hrright'></div>"""

  $( '.hr' ).on "click", (() ->
    $( this ).next().toggle({
      duration: 50,
      done: () -> $('#content').perfectScrollbar('update')
      easing: "swing"
    })
  )

  if pass.length > 0
    $( "#password-input" ).val( pass )

  self.port.emit 'generate', "", ""

  $("#uname-input").on "keyup", generate_send
  $("#site-input") .on "keyup", generate_send

  $("#site-stat").on "click", (() ->
    img = $( this )
    stat = img.attr("stat")

    stat = ""; src = ""; str=""

    #TODO: communication
    switch img.attr("stat")
      when "0"
        stat = "1"; src = "berr.png"; str = "Disabled for this page"
      when "1"
        stat = "2"; src = "rerr.png"; str = "Disabled for all pages"
      else
        stat = "0"; src = "ok.png";   str = "Enabled for this site"

    img.attr("stat", stat)
    img.attr("src", src)
    img.attr("alt", str)
    img.next().text str

  )

  $('#content').perfectScrollbar('update')
)



