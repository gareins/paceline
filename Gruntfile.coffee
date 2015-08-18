module.exports = (grunt) ->
  # Project configuration.
  grunt.initConfig
    jshint:
      files: ['src/**/*.js']
      options:
        globals:
          jQuery: true

    coffeelint:
      app: ['src/**/*.coffee', 'Gruntfile.coffee']
    
    watch:
      files: ['<%= jshint.files %>', '<%= coffeelint.app %>']
      tasks: ['jshint', 'coffeelint']

    # build tasks
    copy:
      main:
        files: [
          {expand: true, dest: "build", src: "package.json"},
          {expand: true, dest: "build", src: "data/panel.html"},
          {expand: true, dest: "build", src: "data/copy.png"},
          {expand: true, dest: "build", src: "data/settings.svg"},
          {expand: true, dest: "build", src: "data/help.png"},
        ]

    coffee:
      compile:
        files:
          'build/index.js': 'src/index.coffee'
          'build/data/input-get.js': 'src/data/input-get.coffee'
          'build/data/panel-script.js': 'src/data/panel-script.coffee'
          'build/data/crypto.js': 'src/data/crypto.coffee'

    less:
      development:
        files:
          'build/data/panel.css': 'data/panel.less'

    min:
      dist0:
        src: ['build/index.js']
        dest: 'build/index.js'
      dist1:
        src: ['build/data/input-get.js']
        dest: 'build/data/input-get.js'
      dist2:
        src: ['build/data/panel-script.js']
        dest: 'build/data/panel-script.js'
      dist3:
        src: ['build/data/crypto.js']
        dest: 'build/data/crypto.js'

    cssmin:
      dist:
        src: ['build/data/panel.css']
        dest: 'build/data/panel.css'

  # Load the plugin that provides the "jshint" task.
  grunt.loadNpmTasks 'grunt-contrib-jshint'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-coffeelint'
  grunt.loadNpmTasks 'grunt-contrib-copy'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-less'
  grunt.loadNpmTasks 'grunt-yui-compressor'

  # Default task(s).
  grunt.registerTask 'default', [ 'copy', 'coffee', 'less' ]
  grunt.registerTask 'minall', [ 'min', 'cssmin' ]

  return
