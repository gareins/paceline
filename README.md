## Paceline

Paceline is a password manager in a form of Firefox addon. It uses different Hash algorithms to generate random, but constistent  passwords for any website you visit.

## Password 

Your personal password is made up of three parts:

* **'The' password** (no limits emposed, but it is advised to use one with enough entropy),
*  Every password is generated from a **generating string**. It can contain website url, your username and  the password, alongside any number of characters. Example: 
'123[uname][pass][site.url]456'
* **Other settings** about how password generation is computed. These are hash algorithm, password length and encoding (base64 or HEX)

> Example: 
>
* password '_iknownothing_'
* generating string '_[uname][pass][site.url]_'
* website 'facebook.com'
* username 'john.snow'
* Hash SHA1
* password length 16
* encoding base64

> base64(SHA1(john.snowiknownothingfacebook.com))[0:16] = 5SkLzfvmrGnnYJX6

### Predefined settings

A plan is to have a couple of predefined settings (so that you only have to remember the password and #predefined setting. And this will happen if anyone will actually use this (besides me).

## Images

Password field and manual password generation.

<a href="http://imgur.com/vA25km9"><img src="http://i.imgur.com/vA25km9.png" title="source: imgur.com" /></a>

Settings.

<a href="http://imgur.com/zhCI9wQ"><img src="http://i.imgur.com/zhCI9wQ.png" title="source: imgur.com" /></a>

Automatic password generation upon username input.

<a href="http://imgur.com/VoMLVqo"><img src="http://i.imgur.com/VoMLVqo.png" title="source: imgur.com" /></a>

## Build

This works for me:
```
$ git clone https://github.com/gareins/paceline.git
$ npm install
$ npm run buildall
```

To debug, you use:
```
$ npm run preview
```

## Feedback

Any kind of feedback is welcomed.
