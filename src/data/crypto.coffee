self.port.on "hash", (content, hash, bit2st) ->
  algorithm = null
  encoding = null

  switch hash
    when "sha1"
      algorithm = CryptoJS.SHA1
    when "sha3"
      algorithm = CryptoJS.SHA3
    when "sha256"
      algorithm = CryptoJS.SHA256
    when "sha512"
      algorithm = CryptoJS.SHA512
    when "ripemd"
      algorithm = CryptoJS.RIPEMD160
    when "md5"
      algorithm = CryptoJS.MD5
    else
      algorithm = CryptoJS.SHA1
      console.log "bad hashalg"

  switch bit2str
    when 'b64'
      encoding = CryptoJS.enc.Base64
    when 'hex'
      encoding = CryptoJS.enc.Hex
    else
      encoding = CryptoJS.enc.Hex
      console.log "bad bit2str"

  hash = algorithm(content).toString(encoding)
  self.port.emit "ret", hash
