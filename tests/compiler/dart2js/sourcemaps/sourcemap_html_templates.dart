// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Templates used for the HTML visualization of source map information.

library sourcemap.html.templates;

import 'dart:io';

abstract class Configurations {
  Iterable<String> get configs;
  Iterable<String> get files;
  String getPath(String config, String file);
}

void outputMultiConfigs(Uri uri, Configurations configurations) {
  StringBuffer sb = new StringBuffer();
  String defaultConfig = configurations.configs.first;
  String defaultFile = configurations.files.first;
  sb.write('''
<html>
<head>
<style>
.button {
  cursor: pointer;
  padding: 10px;
  display: inline;
}
iframe {
  border: 0px;
}
</style>
</head>
<body style="margin:0px;">
<script>
function setAll(name, property, value) {
  var elements = document.getElementsByName(name);
  for (var i = 0; i < elements.length; i++) {
    elements[i].style[property] = value;
  }
}

var current_config;
var current_file;

function setConfig(value) {
  var property = 'text-decoration';
  var onValue = 'underline';
  var offValue = 'none';
  if (current_config != value) {
    setAll('config:' + current_config, property, offValue);
    setAll('src:' + current_config + ':' + current_file, 'display', 'none');
    current_config = value;
    setAll('config:' + current_config, property, onValue);
    setAll('src:' + current_config + ':' + current_file, 'display', 'block');
  }
}

function setFile(value) {
  var property = 'text-decoration';
  var onValue = 'underline';
  var offValue = 'none';
  if (current_file != value) {
    setAll('file:' + current_file, property, offValue);
    setAll('src:' + current_config + ':' + current_file, 'display', 'none');
    current_file = value;
    setAll('file:' + current_file, property, onValue);
    setAll('src:' + current_config + ':' + current_file, 'display', 'block');
  }
}
</script>
''');
  for (String config in configurations.configs) {
    for (String file in configurations.files) {
      String uri = configurations.getPath(config, file);
      sb.write('''
<div name="src:$config:$file" 
     style="width:100%;position:absolute;display:none;">
  <iframe src="$uri" style="width:100%;height:100%;">
  </iframe>
</div>
''');
    }
  }
  sb.write('''  
<div style="right:0px;height:30px;background-color:#E0E0E0;position:fixed;">
  file:
''');
  for (String file in configurations.files) {
    sb.write('''
  <h3 class="button" name="file:$file" 
      onclick="setFile('$file');">$file</h3>
''');
  }
  sb.write('''
  config:
''');
  for (String config in configurations.configs) {
    sb.write('''
  <h3 class="button" name="config:$config" 
      onclick="setConfig('$config');">$config</h3>
''');
  }
  sb.write('''
</div>
<script>
setConfig('$defaultConfig');
setFile('$defaultFile');
</script>
</body>
</html>''');
  output(uri, sb.toString());
}

/// Outputs JavaScript/Dart source mapping traces into [uri].
void outputJsDartTrace(
    Uri uri, String jsCodeHtml, String dartCodeHtml, String jsTraceHtml) {
  String html = '''
<div class="js-buffer">
${jsCodeHtml}
</div>
${dartCodeHtml}
${jsTraceHtml}
''';
  String css = '''
.js-buffer {
  left:0%;
  width:50%;
  top:0%;
  height:50%;
}
.dart-buffer {
  right:0%;
  width:50%;
  top:0%;
  height:50%;
}
.js-trace-buffer {
  left:0%;
  width:100%;
  top:50%;
  height:50%;
}
''';
  outputInTemplate(uri, html, css);
}

/// Outputs [html] with customized [css] in [uri].
void outputInTemplate(Uri uri, String html, String css) {
  output(uri, '''
<html>
<head>
<style>
a, a:hover {
  text-decoration: none;
  color: #000;
}
h3 {
  cursor: pointer;
}
.line {
  margin: 0px;
}
.lineNumber {
  font-size: smaller;
  color: #888;
}
.buffer, .js-buffer, .dart-buffer, .js-trace-buffer {
  position:fixed;
  top:0px;
  height:100%;
  overflow:auto;
}
$css,
.code {
  font-family: monospace;
}
td,.code {
  font-family: monospace;
  max-width: 400px;
  overflow: hidden;
}
</style>
</head>
<body>
<script>
function setAll(name, property, value) {
  var elements = document.getElementsByName(name);
  for (var i = 0; i < elements.length; i++) {
    elements[i].style[property] = value;
  }
}

var shownName;
function show(name) {
  if (shownName != name) {
    if (shownName) {
      setAll(shownName, 'display', 'none');
    }
    shownName = name;
    if (shownName) {
      setAll(shownName, 'display', 'block');
    }
  }
}
var highlightNames = [];
function highlight(names) {
  var property = 'text-decoration';
  var onValue = 'underline';
  var offValue = 'none';
  if (highlightNames != names) {
    if (highlightNames && highlightNames.length > 0) {
      for (var index in highlightNames) {
        var highlightName = highlightNames[index];
        setAll(highlightName, property, offValue);
        setAll('js' + highlightName, property, offValue);
        setAll('trace' + highlightName, property, offValue);
      }
    }
    highlightNames = names;
    if (highlightNames && highlightNames.length > 0) {
      for (var index in highlightNames) {  
        var highlightName = highlightNames[index];
        setAll(highlightName, property, onValue);
        setAll('js' + highlightName, property, onValue);
        setAll('trace' + highlightName, property, onValue);
      }
    }
  }
}
</script>
$html
</body>
</html>
''');
}

/// Outputs [html] in [uri].
void output(Uri uri, String html) {
  File outputFile = new File.fromUri(uri);
  outputFile.writeAsStringSync(html);
}
