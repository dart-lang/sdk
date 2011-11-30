// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

//#import('../file_system.dart');

#import("dart:dom");
#import('css.dart');
#import('../../frog/lang.dart', prefix:'lang');


void runCss([bool debug = false, bool parseOnly = false]) {
  final HTMLTextAreaElement classes = document.getElementById('classes');
  final HTMLTextAreaElement expression = document.getElementById('expression');
  final HTMLDivElement result = document.getElementById('result');

  List<String> knownWorld = classes.value.split("\n");
  List<String> knownClasses = [];
  List<String> knownIds = [];
  for (name in knownWorld) {
    if (name.startsWith('.')) {
      knownClasses.add(name.substring(1));
    } else if (name.startsWith('#')) {
      knownIds.add(name.substring(1));
    }
  }

  CssWorld cssWorld = new CssWorld(knownClasses, knownIds);
  bool templateValid = true;
  String dumpTree = "";

  String cssExpr = expression.value;
  if (!debug) {
    try {
      cssParseAndValidate(cssExpr, cssWorld);
    } catch (var cssException) {
      templateValid = false;
      dumpTree = cssException.toString();
    }
  } else if (parseOnly) {
    try {
      Parser parser = new Parser(new lang.SourceFile(
          lang.SourceFile.IN_MEMORY_FILE, cssExpr));
      List<SelectorGroup> groups = parser.preprocess();
      StringBuffer groupTree = new StringBuffer();
      for (group in groups) {
        String prettySelector = group.toString();
        groupTree.add("${prettySelector}\n");
        groupTree.add("-----\n");
        groupTree.add(group.toDebugString());
      }
      dumpTree = groupTree.toString();
    } catch (var cssParseException) {
      templateValid = false;
      dumpTree = cssParseException.toString();
    }
  } else {
    try {
      dumpTree = cssParseAndValidateDebug(cssExpr, cssWorld);
    } catch (var cssException) {
      templateValid = false;
      dumpTree = cssException.toString();
    }
  }

  final var bgcolor = templateValid ? "white" : "red";
  final var color = templateValid ? "black" : "white";
  final var valid = templateValid ? "VALID" : "NOT VALID";
  String resultStyle = 'margin: 0; height: 138px; width: 100%; border: 0; border-top: 1px solid black;';
  result.innerHTML = '''
    <div style="font-weight: bold; background-color: $bgcolor; color: $color;">
      Expression: $cssExpr is $valid
    </div>
    <textarea style="$resultStyle">$dumpTree</textarea>
  ''';
}

void main() {
  var element = document.createElement('div');
  element.innerHTML = '''
    <div style="position: absolute; top: 10px; width: 200px;" align=center>
      <span style="font-weight:bold;">Classes</span><br/>
      <textarea id="classes" style="width: 200px; height: 310px;">.foobar\n.xyzzy\n.test\n.dummy\n#myId\n#myStory</textarea>
    </div>
    <div style="left: 225px; position: absolute; top: 10px;">
      <span style="font-weight:bold;">Selector Expression</span><br/>
      <textarea id="expression" style="width: 400px; height: 100px;"></textarea>
      <br/>
    </div>
    <button onclick="runCss(true, true)" style="position: absolute; left: 430px; top: 135px;">Parse</button>
    <button onclick="runCss()" style="position: absolute; left: 500px; top: 135px;">Check</button>
    <button onclick="runCss(true)" style="position: absolute; left: 570px; top: 135px;">Debug</button>
    <div style="top: 160px; left: 225px; position: absolute;">
      <span style="font-weight:bold;">Result</span><br/>
      <div id="result" style="width: 400px; height: 158px; border: black solid 1px;"></textarea>
    </div>
  ''';

  document.body.appendChild(element);

  // TODO(terry): Needed so runCss isn't shakened out.
  if (false) {
    runCss();
  }

  initCssWorld();
}
