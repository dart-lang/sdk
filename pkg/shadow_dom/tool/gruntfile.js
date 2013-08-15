/*
 * Copyright 2013 The Polymer Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 */
module.exports = function(grunt) {
  ShadowDOMPolyfill = [
    'sidetable.js',
    'wrappers.js',
    'wrappers/events.js',
    'wrappers/NodeList.js',
    'wrappers/Node.js',
    'querySelector.js',
    'wrappers/node-interfaces.js',
    'wrappers/CharacterData.js',
    'wrappers/Element.js',
    'wrappers/HTMLElement.js',
    'wrappers/HTMLContentElement.js',
    'wrappers/HTMLShadowElement.js',
    'wrappers/HTMLTemplateElement.js',
    'wrappers/HTMLUnknownElement.js',
    'wrappers/generic.js',
    'wrappers/ShadowRoot.js',
    'ShadowRenderer.js',
    'wrappers/Document.js',
    'wrappers/Window.js',
    'wrappers/MutationObserver.js',
    'wrappers/override-constructors.js'
  ];
  ShadowDOMPolyfill = ShadowDOMPolyfill.map(function(p) {
    return '../../../third_party/polymer/ShadowDOM/src/' + p;
  });

  // Apply partial patch from Polymer/Platform, dart2js, CSS
  // polyfill from platform and dart2js CSS patches:
  ShadowDOMPolyfill.unshift(
    '../lib/src/platform/patches-shadowdom-polyfill-before.js'
    );
  ShadowDOMPolyfill.push(
    '../lib/src/platform/patches-shadowdom-polyfill.js',
    '../lib/src/platform/platform-init.js',
    '../lib/src/platform/ShadowCSS.js',
    '../lib/src/platform/patches-shadow-css.js'
    );

  // Only load polyfill if not natively present.
  ConditionalShadowDOM = [].concat(
    'build/if-poly.js',
    ShadowDOMPolyfill,
    'build/end-if.js'
  );

  // karma setup
  var browsers;
  (function() {
    try {
      var config = grunt.file.readJSON('local.json');
      if (config.browsers) {
        browsers = config.browsers;
      }
    } catch (e) {
      var os = require('os');
      browsers = ['Chrome', 'Firefox'];
      if (os.type() === 'Darwin') {
        browsers.push('ChromeCanary');
      }
      if (os.type() === 'Windows_NT') {
        browsers.push('IE');
      }
    }
  })();
  grunt.initConfig({
    karma: {
      options: {
        configFile: 'conf/karma.conf.js',
        keepalive: true,
        browsers: browsers
      },
      buildbot: {
        browsers: browsers,
        reporters: ['crbot'],
        logLevel: 'OFF'
      },
      ShadowDOM: {
        browsers: browsers
      }
    },
    concat: {
      ShadowDOM: {
        src: ConditionalShadowDOM,
        dest: '../lib/shadow_dom.debug.js',
        nonull: true
      }
    },
    uglify: {
      ShadowDOM: {
        options: {
          compress: {
            // TODO(sjmiles): should be false by default (?)
            // https://github.com/mishoo/UglifyJS2/issues/165
            unsafe: false
          }
          //compress: true, Xmangle: true, beautify: true, unsafe: false
        },
        files: {
          '../lib/shadow_dom.min.js': ['../lib/shadow_dom.debug.js']
        }
      }
    },

    yuidoc: {
      compile: {
        name: '<%= pkg.name %>',
        description: '<%= pkg.description %>',
        version: '<%= pkg.version %>',
        url: '<%= pkg.homepage %>',
        options: {
          exclude: 'third_party',
          paths: '.',
          outdir: 'docs',
          linkNatives: 'true',
          tabtospace: 2,
          themedir: '../docs/doc_themes/simple'
        }
      }
    },
    pkg: grunt.file.readJSON('package.json')
  });

  // plugins
  grunt.loadNpmTasks('grunt-contrib-concat');
  grunt.loadNpmTasks('grunt-contrib-uglify');
  grunt.loadNpmTasks('grunt-contrib-yuidoc');
  grunt.loadNpmTasks('grunt-karma-0.9.1');

  // tasks
  grunt.registerTask('default', ['concat', 'uglify']);
  grunt.registerTask('minify', ['concat', 'uglify']);
  grunt.registerTask('docs', ['yuidoc']);
  grunt.registerTask('test', ['karma:ShadowDOM']);
  grunt.registerTask('test-buildbot', ['karma:buildbot']);
};

