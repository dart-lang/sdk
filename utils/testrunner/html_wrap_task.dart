// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A pipeline task to create a HTML/CSS wrapper for a test so it can run in DRT.
 */
class HtmlWrapTask extends PipelineTask {
  final String _testFileTemplate;
  final String _htmlSourceFileTemplate;
  final String _htmlDestFileTemplate;
  final String _cssSourceFileTemplate;
  final String _cssDestFileTemplate;

  HtmlWrapTask(this._testFileTemplate, this._htmlSourceFileTemplate,
      this._htmlDestFileTemplate, this._cssSourceFileTemplate,
      this._cssDestFileTemplate);

  void execute(Path testfile, List stdout, List stderr, bool logging,
              Function exitHandler) {
    var testname = expandMacros(_testFileTemplate, testfile);

    // If the test already has a corresponding HTML file we copy that,
    // else we create a new wrapper.
    var htmlSourceName = expandMacros(_htmlSourceFileTemplate, testfile);
    var htmlDestName = expandMacros(_htmlDestFileTemplate, testfile);
    var cssSourceName = expandMacros(_cssSourceFileTemplate, testfile);
    var cssDestName = expandMacros(_cssDestFileTemplate, testfile);

    var htmlMaster = new File(htmlSourceName);
    if (htmlMaster.existsSync()) {
      if (logging) {
        stdout.add('Copying $htmlSourceName to $htmlDestName');
      }
      copyFile(htmlSourceName, htmlDestName);
    } else {
      if (logging) {
        stdout.add('Creating wrapper $htmlDestName');
      }
      var p = new Path(testname);
      var runtime = config.runtime;
      var startDart = '';
      if (runtime == 'drt-dart') {
        startDart =
            "if (navigator.webkitStartDart) navigator.webkitStartDart();";
      }

      var prefix = flattenPath(p.directoryPath.toString());
      var suffix = (config.layoutPixel || config.layoutText) ? '-child': '';
      var scriptElement;
      if (runtime == 'drt-dart') {
        scriptElement = "<script type='application/dart' "
            "src='${prefix}_${p.filenameWithoutExtension}$suffix.dart'>";
      } else {
        scriptElement = "<script type='text/javascript' "
            "src='${prefix}_${p.filenameWithoutExtension}$suffix.js'>";
      }

      var bodyElements = "";
      var runAsText = "";

      if (!config.layoutText && !config.layoutPixel) {
        runAsText = "window.testRunner.dumpAsText();";
        bodyElements = """
  <h1>$testname</h1> 
  <div id="container"></div>
  <pre id='console'></pre>
""";
      }

      var htmlContent = """
<!DOCTYPE html>

<html>
<head>
  <meta charset="utf-8">
  <title>$testname</title>
  <link rel="stylesheet" href="${p.filenameWithoutExtension}.css">
  <script type='text/javascript'>
if (window.testRunner) {
  function handleMessage(m) {
    if (m.data == 'done') {
      window.testRunner.notifyDone();
    }
  }
  window.testRunner.waitUntilDone();
  $runAsText
  window.addEventListener("message", handleMessage, false);
}
$startDart
  </script>
</head>
<body>
  $bodyElements
  $scriptElement
  </script>
  <script
src="http://dart.googlecode.com/svn/branches/bleeding_edge/dart/client/dart.js">
  </script>
</body>
</html>
""";
      createFile(htmlDestName, htmlContent);
    }
    var cssMaster = new File(cssSourceName);
    if (cssMaster.existsSync()) {
      if (logging) {
        stdout.add('Copying $cssSourceName to $cssDestName');
      }
      copyFile(cssSourceName, cssDestName);
    } else {
      if (logging) {
        stdout.add('Creating $cssDestName');
      }
      createFile(cssDestName, """
body {
background-color: #F8F8F8;
font-family: 'Open Sans', sans-serif;
font-size: 14px;
font-weight: normal;
line-height: 1.2em;
margin: 15px;
}

p {
color: #333;
}

#container {
width: 100%;
height: 400px;
position: relative;
border: 1px solid #ccc;
background-color: #fff;
}

#text {
font-size: 24pt;
text-align: center;
margin-top: 140px;
}

""");
    }
    exitHandler(0);
  }

  void cleanup(Path testfile, List stdout, List stderr,
               bool logging, bool keepFiles) {
    deleteFiles([_htmlDestFileTemplate, _cssDestFileTemplate], testfile,
        logging, keepFiles, stdout);
  }
}
