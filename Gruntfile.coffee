module.exports = (grunt) ->
  # pkg: grunt.file.readJSON('package.json')
  
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
          {
            expand: true
            overwrite: true
            cwd: '.'
            src: 'node_modules'
            dest: 'build/'
          }
        ]

    coffee:
      compile:
        files:
          'build/index.js': 'src/index.coffee'

      glob_to_multiple:
        expand: true
        flatten: true
        cwd: 'src/data'
        src: ['*.coffee']
        dest: 'build/data'
        ext: '.js'

  # Load the plugin that provides the "jshint" task.
  grunt.loadNpmTasks 'grunt-contrib-jshint'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-coffeelint'
  grunt.loadNpmTasks 'grunt-contrib-symlink'
  grunt.loadNpmTasks 'grunt-contrib-coffee'

  # Default task(s).
  grunt.registerTask 'default', [ 'symlink', 'coffee' ]

  return
