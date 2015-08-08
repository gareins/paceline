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
    symlink:
      options:
        overwrite: true
      explicit:
        src: "package.json"
        dest: "build/package.json"
      expanded:
        files: [
          {
            expand: true
            overwrite: true
            cwd: 'data'
            src: ['panel.html', 'copy.png']
            dest: 'build/data'
          },
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
  grunt.loadNpmTasks 'grunt-contrib-symlink'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-less'
  grunt.loadNpmTasks 'grunt-yui-compressor'

  # Default task(s).
  grunt.registerTask 'default', [ 'symlink', 'coffee', 'less' ]
  grunt.registerTask 'minall', [ 'min', 'cssmin' ]

  return
