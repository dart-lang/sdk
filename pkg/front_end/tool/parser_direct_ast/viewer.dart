// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io" show File, Platform;
import "dart:typed_data" show Uint8List;

import "package:front_end/src/fasta/util/direct_parser_ast.dart" show getAST;
import "package:front_end/src/fasta/util/direct_parser_ast_helper.dart"
    show DirectParserASTContent, DirectParserASTType;

import "console_helper.dart";

void main(List<String> args) {
  Uri uri = Platform.script;
  if (args.isNotEmpty) {
    uri = Uri.base.resolve(args.first);
  }
  Uint8List bytes = new File.fromUri(uri).readAsBytesSync();
  DirectParserASTContent ast = getAST(bytes);

  Widget widget = new QuitOnQWidget(
    new WithSingleLineBottomWidget(
      new BoxedWidget(
        new AstWidget(ast),
      ),
      new StatusBarWidget(),
    ),
  );
  Application app = new Application(widget);
  app.start();
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

  AstWidget(DirectParserASTContent ast) {
    shown = [new PrintedLine.ast(ast, textualize(ast))];
  }

  String textualize(DirectParserASTContent element,
      {bool indent: false, bool withEndHeader: false}) {
    String header;
    switch (element.type) {
      case DirectParserASTType.BEGIN:
        header = "begin";
        break;
      case DirectParserASTType.HANDLE:
        header = "handle";
        break;
      case DirectParserASTType.END:
        header = withEndHeader ? "end" : "";
        break;
    }
    String extra = " ";
    if (element.children != null) {
      extra += element.children.first.deprecatedArguments.toString();
    }
    return "${indent ? "  " : ""}"
        "${header}${element.what} "
        "${element.deprecatedArguments.toString()}${extra}";
  }

  @override
  void print(WriteOnlyOutput output) {
    for (int row = 0; row < shown.length; row++) {
      if (row >= output.rows) break;

      PrintedLine element = shown[row];
      String line = element.text;

      if (selected == row) {
        // Mark line with blue background.
        for (int column = 0; column < output.columns; column++) {
          output.setCell(row, column, backgroundColor: BackgroundColor.Blue);
        }
      }

      // Print text.
      int length = line.length;
      if (length > output.columns) {
        length = output.columns;
      }
      for (int column = 0; column < length; column++) {
        output.setCell(row, column, char: line[column]);
      }
    }
  }

  void enter() {
    // Enter selected line.
    PrintedLine selectedElement = shown[selected];
    if (selectedElement.parentShown != null) {
      shown = selectedElement.parentShown;
      selected = selectedElement.selected;
    } else {
      shown = [new PrintedLine.parent(shown, selected)];
      List<DirectParserASTContent> children = selectedElement.ast.children;
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

  @override
  bool input(_, List<int> data) {
    if (data.length > 2 &&
        data[0] == Application.CSI.codeUnitAt(0) &&
        data[1] == Application.CSI.codeUnitAt(1)) {
      // ANSI codes --- at least on my machine.
      if (data[2] == 65 /* A */) {
        // CSI _n_ A: Cursor Up (where n is optional defaulting to 1).
        // Up arrow.
        if (selected > 0) {
          selected--;
          return true;
        }
      } else if (data[2] == 66 /* B */) {
        // CSI _n_ B: Cursor Down (where n is optional defaulting to 1).
        // Down arrow.
        if (selected < shown.length - 1) {
          selected++;
          return true;
        }
      }
    } else if (data.length == 1 && data[0] == 10) {
      // <Return>.
      enter();
      return true;
    }
    return false;
  }
}

class StatusBarWidget extends Widget {
  List<int> latestInput;

  @override
  void print(WriteOnlyOutput output) {
    // Paint everything with a red background.
    for (int row = 0; row < output.rows; row++) {
      for (int column = 0; column < output.columns; column++) {
        output.setCell(row, column, backgroundColor: BackgroundColor.Red);
      }
    }

    String leftString = "> ${latestInput ?? ""}";
    String rightString = "Press q or Ctrl-C to quit";
    for (int i = 0; i < leftString.length; i++) {
      output.setCell(0, i,
          char: leftString[i], backgroundColor: BackgroundColor.Red);
    }
    for (int i = 0; i < rightString.length; i++) {
      output.setCell(output.rows - 1, output.columns - rightString.length + i,
          char: rightString[i], backgroundColor: BackgroundColor.Red);
    }
  }

  @override
  bool input(Application app, List<int> data) {
    latestInput = data;
    return true;
  }
}
