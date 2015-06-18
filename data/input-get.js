function chk_url(url1) {
  if(!window.location)
    return false;

  var url2 = window.location.href;
  if( url2.match(new RegExp(".*\.(js|css)")))
    return false;
  
  var a_url;

  a_url = document.createElement('a');
  a_url.href = url1;
  url1 = a_url.hostname;

  a_url = document.createElement('a');
  a_url.href = url2;
  url2 = a_url.hostname;

  if(url1 !== url2)
    return false;

  return true;
}

function chk_passwd(url) {
  if(!chk_url(url))
    return;


  // todo: for gmail hidden password...
  // todo: on DOM change listener for coursera, 24ur.com, weebly
  // todo: partis.si
  var inputs = $(document)
                .find("input")
                .filter("[type='password'], [type='text'], [type='email']")
                .filter(':visible');
  
  var pass_idx = -1;
  for(var i=0; i<inputs.length; i++) {
  //inputs.each(function(i, e) {
    if($(inputs[i]).attr("type") === "password") {
      pass_idx = i;
      break;
    }
  }

  if(pass_idx <= 0)
    return;

  $(inputs[pass_idx-1]).css("background-color", "green");
  $(inputs[pass_idx  ]).css("background-color", "red");
}

self.port.on("getInput", chk_passwd);
