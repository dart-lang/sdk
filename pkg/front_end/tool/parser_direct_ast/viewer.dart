// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";
import 'dart:typed_data';
import "package:front_end/src/fasta/util/direct_parser_ast.dart";
import "package:front_end/src/fasta/util/direct_parser_ast_helper.dart";

import "console_helper.dart";

void main(List<String> args) {
  Uri uri = Platform.script;
  if (args.isNotEmpty) {
    uri = Uri.base.resolve(args.first);
  }
  Uint8List bytes = new File.fromUri(uri).readAsBytesSync();
  DirectParserASTContent ast = getAST(bytes);

  Widget widget = new PairWidget(new AstWidget(ast), new StatusBar());
  Application app = new Application(widget);
  app.start();
}

class PairWidget extends Widget {
  Widget first;
  Widget second;

  PairWidget(this.first, this.second);

  @override
  void print(Application app) {
    first.print(app);
    second.print(app);
  }

  @override
  void input(Application app, List<int> data) {
    if (data.length == 1 && String.fromCharCode(data[0]) == 'q') {
      app.quit();
      return;
    }
    first.input(app, data);
    second.input(app, data);
  }
}

class PrintedLine {
  final String text;
  final DirectParserASTContent ast;
  final List<PrintedLine> parentShown;
  final int selected;

  PrintedLine.parent(this.parentShown, this.selected)
      : text = "..",
        ast = null;

  PrintedLine.parentWithText(this.parentShown, this.text, this.selected)
      : ast = null;

  PrintedLine.ast(this.ast, this.text)
      : parentShown = null,
        selected = null;
}

class AstWidget extends Widget {
  List<PrintedLine> shown;
  int selected = 0;
  int _latestSelected;
  List<PrintedLine> _latestShown;

  AstWidget(DirectParserASTContent ast) {
    shown = [new PrintedLine.ast(ast, textualize(ast))];
    _latestSelected = selected;
    _latestShown = shown;
  }

  String textualize(DirectParserASTContent element,
      {bool indent: false, bool withEndHeader: false}) {
    String header;
    switch (element.type) {
      case DirectParserASTType.BEGIN:
        header = "begin";
        break;
      case DirectParserASTType.END:
        throw "Unexpected";
      case DirectParserASTType.HANDLE:
        header = "handle";
        break;
      case DirectParserASTType.DONE:
        header = withEndHeader ? "end" : "";
        break;
    }
    String extra = " ";
    if (element.content != null) {
      extra += element.content.first.arguments.toString();
    }
    return "${indent ? "  " : ""}"
        "${header}${element.what} "
        "${element.arguments.toString()}${extra}";
  }

  void clear(Application app) {
    int realSelected = selected;
    selected = -1;
    for (int i = 0; i < app.lastKnownTerminalLines - 2; i++) {
      printLineText(app, "", i);
    }
    selected = realSelected;
  }

  @override
  void print(Application app, {bool totalRepaint: true}) {
    if (!totalRepaint && _latestShown != shown) {
      totalRepaint = true;
    }
    if (!totalRepaint && selected == _latestSelected) {
      return;
    }

    if (totalRepaint) {
      clear(app);
      drawBox(
          1, 1, app.lastKnownTerminalColumns, app.lastKnownTerminalLines - 1);
      for (int i = 0; i < shown.length; i++) {
        if (3 + i >= app.lastKnownTerminalLines) break;
        printLine(app, i);
      }
    } else {
      printLine(app, _latestSelected);
      printLine(app, selected);
    }
    _latestShown = shown;
    _latestSelected = selected;
  }

  void enter() {
    // Enter selected line.
    PrintedLine selectedElement = shown[selected];
    if (selectedElement.parentShown != null) {
      shown = selectedElement.parentShown;
      selected = selectedElement.selected;
    } else {
      shown = [new PrintedLine.parent(shown, selected)];
      List<DirectParserASTContent> children = selectedElement.ast.content;
      if (children != null) {
        for (int i = 0; i < children.length; i++) {
          shown.add(new PrintedLine.ast(
              children[i], textualize(children[i], indent: i > 0)));
        }
      }
      shown.add(new PrintedLine.parentWithText(shown,
          textualize(selectedElement.ast, withEndHeader: true), shown.length));
      selected = 0;
    }
  }

  void printLine(Application app, int lineNum) {
    PrintedLine element = shown[lineNum];
    String line = element.text;
    printLineText(app, line, lineNum);
  }

  void printLineText(Application app, String line, int lineNum) {
    if (line.length > app.lastKnownTerminalColumns - 2) {
      line = line.substring(0, app.lastKnownTerminalColumns - 2);
    } else {
      line = line.padRight(app.lastKnownTerminalColumns - 2);
    }
    printAt(2 + lineNum, 2, ifSelected(line, selected == lineNum));
  }

  String ifSelected(String s, bool isSelected) {
    if (isSelected) return colorBackgroundBlue(s);
    return s;
  }

  @override
  void input(Application app, List<int> data) {
    if (data.length > 2 &&
        data[0] == CSI.codeUnitAt(0) &&
        data[1] == CSI.codeUnitAt(1)) {
      // ANSI codes --- at least on my machine.
      if (data[2] == 65 /* A */) {
        // CSI _n_ A: Cursor Up (where n is optional defaulting to 1).
        // Up arrow.
        if (selected > 0) {
          selected--;
        }
      } else if (data[2] == 66 /* B */) {
        // CSI _n_ B: Cursor Down (where n is optional defaulting to 1).
        // Down arrow.
        if (selected < shown.length - 1) {
          selected++;
        }
      }
    } else if (data.length == 1 && data[0] == 10) {
      // <Return>.
      enter();
    }
    print(app, totalRepaint: false);
  }
}

class StatusBar extends Widget {
  List<int> latestInput;

  @override
  void print(Application app) {
    String leftString = "> ${latestInput ?? ""}";
    String rightString = "Press q or Ctrl-C to quit";
    int padding =
        app.lastKnownTerminalColumns - leftString.length - rightString.length;
    printAt(app.lastKnownTerminalLines, 1,
        colorBackgroundRed("$leftString${" " * padding}${rightString}"));
  }

  @override
  void input(Application app, List<int> data) {
    latestInput = data;
    print(app);
  }
}
