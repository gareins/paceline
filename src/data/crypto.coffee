self.port.on "hash", (content, hash, bit2str) ->
  alg = null
  enc = null

  switch hash
    when "sha1"
      alg = CryptoJS.SHA1
    when "sha3"
      alg = CryptoJS.SHA3
    when "sha256"
      alg = CryptoJS.SHA256
    when "sha512"
      alg = CryptoJS.SHA512
    when "ripemd"
      alg = CryptoJS.RIPEMD160
    when "md5"
      alg = CryptoJS.MD5
    else
      alg = CryptoJS.SHA1
      console.log "bad hashalg"

  switch bit2str
    when 'b64'
      enc = CryptoJS.enc.Base64
    when 'hex'
      enc = CryptoJS.enc.Hex
    else
      enc = CryptoJS.enc.Hex
      console.log "bad bit2str"

  hash = alg(content).toString(enc)
  self.port.emit "ret", hash
