// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import('dart:html');
#import('css.dart');
#import('../lib/file_system_memory.dart');

void runCss([bool debug = false, bool parseOnly = false]) {
  final Document doc = window.document;
  final TextAreaElement classes = doc.query("#classes");
  final TextAreaElement expression = doc.query('#expression');
  final TableCellElement validity = doc.query('#validity');
  final TableCellElement result = doc.query('#result');

  List<String> knownWorld = classes.value.split("\n");
  List<String> knownClasses = [];
  List<String> knownIds = [];
  for (final name in knownWorld) {
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
    } catch (cssException) {
      templateValid = false;
      dumpTree = cssException.toString();
    }
  } else if (parseOnly) {
    try {
      Parser parser = new Parser(new SourceFile(
          SourceFile.IN_MEMORY_FILE, cssExpr));
      Stylesheet stylesheet = parser.parse();
      StringBuffer stylesheetTree = new StringBuffer();
      String prettyStylesheet = stylesheet.toString();
      stylesheetTree.add("${prettyStylesheet}\n");
      stylesheetTree.add("\n============>Tree Dump<============\n");
      stylesheetTree.add(stylesheet.toDebugString());
      dumpTree = stylesheetTree.toString();
    } catch (cssParseException) {
      templateValid = false;
      dumpTree = cssParseException.toString();
    }
  } else {
    try {
      dumpTree = cssParseAndValidateDebug(cssExpr, cssWorld);
    } catch (cssException) {
      templateValid = false;
      dumpTree = cssException.toString();
    }
  }

  final bgcolor = templateValid ? "white" : "red";
  final color = templateValid ? "black" : "white";
  final valid = templateValid ? "VALID" : "NOT VALID";
  String resultStyle = "resize:none; margin:0; height:100%; width:100%;"
    "padding:5px 7px;";
  String validityStyle = "font-weight:bold; background-color:$bgcolor;"
    "color:$color; border:1px solid black; border-bottom:0px solid white;";
  validity.innerHTML = '''
    <div style="$validityStyle">
      Expression: $cssExpr is $valid
    </div>
  ''';
  result.innerHTML = "<textarea style=\"$resultStyle\">$dumpTree</textarea>";
}

void main() {
  final element = new Element.tag('div');
  element.innerHTML = '''
    <table style="width: 100%; height: 100%;">
      <tbody>
        <tr>
          <td style="vertical-align: top; width: 200px;">
            <table style="height: 100%;">
              <tbody>
                <tr style="vertical-align: top; height: 1em;">
                  <td>
                    <span style="font-weight:bold;">Classes</span>
                  </td>
                </tr>
                <tr style="vertical-align: top;">
                  <td>
                    <textarea id="classes" style="resize: none; width: 200px; height: 100%; padding: 5px 7px;">.foobar\n.xyzzy\n.test\n.dummy\n#myId\n#myStory</textarea>
                  </td>
                </tr>
              </tbody>
            </table>
          </td>
          <td>
            <table style="width: 100%; height: 100%;" cellspacing=0 cellpadding=0 border=0>
              <tbody>
                <tr style="vertical-align: top; height: 100px;">
                  <td>
                    <table style="width: 100%;">
                      <tbody>
                        <tr>
                          <td>
                            <span style="font-weight:bold;">Selector Expression</span>
                          </td>
                        </tr>
                        <tr>
                          <td>
                            <textarea id="expression" style="resize: none; width: 100%; height: 100px; padding: 5px 7px;"></textarea>
                          </td>
                        </tr>
                      </tbody>
                    </table>
                  </td>
                </tr>

                <tr style="vertical-align: top; height: 50px;">
                  <td>
                    <table>
                      <tbody>
                        <tr>
                          <td>
                            <button id=parse>Parse</button>
                          </td>
                          <td>
                            <button id=check>Check</button>
                          </td>
                          <td>
                            <button id=debug>Debug</button>
                          </td>
                        </tr>
                      </tbody>
                    </table>
                  </td>
                </tr>

                <tr style="vertical-align: top;">
                  <td>
                    <table style="width: 100%; height: 100%;" border="0" cellpadding="0" cellspacing="0">
                      <tbody>
                        <tr style="vertical-align: top; height: 1em;">
                          <td>
                            <span style="font-weight:bold;">Result</span>
                          </td>
                        </tr>
                        <tr style="vertical-align: top; height: 1em;">
                          <td id="validity">
                          </td>
                        </tr>
                        <tr style="vertical-align: top;">
                          <td id="result">
                            <textarea style="resize: none; width: 100%; height: 100%; border: black solid 1px; padding: 5px 7px;"></textarea>
                          </td>
                        </tr>
                      </tbody>
                    </table>
                  </td>
                </tr>
              </tbody>
            </table>
          </td>
        </tr>
      </tbody>
    </table>
  ''';

  document.body.style.setProperty("background-color", "lightgray");
  document.body.elements.add(element);

  ButtonElement parseButton = window.document.query('#parse');
  parseButton.on.click.add((MouseEvent e) {
    runCss(true, true);
  });

  ButtonElement checkButton = window.document.query('#check');
  checkButton.on.click.add((MouseEvent e) {
    runCss();
  });

  ButtonElement debugButton = window.document.query('#debug');
  debugButton.on.click.add((MouseEvent e) {
    runCss(true);
  });

  initCssWorld(false);
}
