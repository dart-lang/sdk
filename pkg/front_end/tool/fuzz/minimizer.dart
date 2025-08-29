// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/scanner/token.dart';

import 'package:front_end/src/util/parser_ast.dart';
import 'package:front_end/src/util/parser_ast_helper.dart';

import '../interval_list.dart';
import 'compile_helper.dart';
import 'stacktrace_utils.dart';

const bool debug = false;

Future<void> main(List<String> args) async {
  if (args.length != 1) throw "Needs exactly 1 input.";

  Helper helper = new Helper();
  await helper.setup();

  Uint8List rawBytes = new File(args.single).readAsBytesSync();
  String sourceAsString = utf8.decode(rawBytes);

  (Object, StackTrace)? compile = await helper.compile(sourceAsString);
  if (compile == null) throw "Input doesn't crash.";
  String categorized = categorize(compile.$2);

  CompilationUnitEnd ast = getAST(
    rawBytes,
    includeComments: true,
    enableTripleShift: true,
    allowPatterns: true,
  );
  ast.debugPrint();

  Visitor v = new Visitor(helper, categorized, sourceAsString);
  Token firstToken = (ast.children!.first as CompilationUnitBegin).token;
  await v.walkTokens(firstToken);
  await ast.accept(v);

  String? minimized = v.getMinimizedSource();
  if (minimized == null) {
    print("Couldn't minimize.");
  } else {
    print("Minimized to: ");
    print(minimized);
  }
}

class Visitor extends RecursiveParserAstVisitorWithDefaultNodeAsync {
  final Helper helper;
  final String wantedCategorizedCrash;
  final String initialSource;
  List<(int, int)> removeable = [];

  Visitor(this.helper, this.wantedCategorizedCrash, this.initialSource) {
    prevBraceInfo = initialSource.getBraceCountString();
    print("Initial source brace info: $prevBraceInfo");
  }

  Future<void> walkTokens(Token token) async {
    Token t = token;
    while (!t.isEof) {
      if (t.endGroup != null) {
        if (await _canRemove("Token range", t.runtimeType, t, t.endGroup!)) {
          t = t.endGroup!.next!;
          continue;
        }
      }
      t = t.next!;
    }
  }

  @override
  Future<void> defaultNode(ParserAstNode node) async {
    if (node is BeginAndEndTokenParserAstNode) {
      if (await _canRemove(
        node.what,
        node.runtimeType,
        node.beginToken,
        node.endToken,
      )) {
        return;
      }
    } else if (node is BinaryExpressionEnd) {
      if (await _canRemove(
        node.what,
        node.runtimeType,
        node.token,
        node.endToken,
      )) {
        return;
      }
    } else if (node is ThrowExpressionHandle) {
      if (await _canRemove(
        node.what,
        node.runtimeType,
        node.throwToken,
        node.endToken,
      )) {
        return;
      }
    } else if (node is LabelHandle) {
      if (await _canRemove(
        node.what,
        node.runtimeType,
        node.token.previous!,
        node.token,
      )) {
        return;
      }
    } else if (node is CaseExpressionEnd) {
      if (await _canRemove(
        node.what,
        node.runtimeType,
        node.caseKeyword,
        node.colon,
      )) {
        return;
      }
    } else if (node is UnaryPrefixAssignmentExpressionHandle) {
      if (await _canRemove(
        node.what,
        node.runtimeType,
        node.token,
        node.token,
      )) {
        return;
      }
    } else if (node is UnaryPrefixExpressionHandle) {
      if (await _canRemove(
        node.what,
        node.runtimeType,
        node.token,
        node.token,
      )) {
        return;
      }
    } else if (node is EmptyStatementHandle) {
      if (await _canRemove(
        node.what,
        node.runtimeType,
        node.token,
        node.token,
      )) {
        return;
      }
    } else if (node is AssignmentExpressionHandle) {
      if (await _canRemove(
        node.what,
        node.runtimeType,
        node.token,
        node.endToken,
      )) {
        return;
      }
    } else if (node is ConditionalExpressionEnd) {
      if (await _canRemove(
        node.what,
        node.runtimeType,
        node.question.next!,
        node.colon.previous!,
      )) {
        // Fine, but we still have to recurse.
      }
      if (await _canRemove(
        node.what,
        node.runtimeType,
        node.colon.next!,
        node.endToken,
      )) {
        // Fine, but we still have to recurse.
      }
    } else if (node is BinaryPatternEnd) {
      // This seems a little dicy.
      if (await _canRemove(
        node.what,
        node.runtimeType,
        node.token,
        node.token,
      )) {
        return;
      }
    } else if (node is PartEnd) {
      if (await _canRemove(
        node.what,
        node.runtimeType,
        node.partKeyword,
        node.semicolon,
      )) {
        return;
      }
    } else if (node is TypedefEnd) {
      if (await _canRemove(
        node.what,
        node.runtimeType,
        node.augmentToken ?? node.typedefKeyword,
        node.endToken,
      )) {
        return;
      }
    }
    // We can't remove the node (or it isn't a Begin/End one) - recurse.
    await super.defaultNode(node);
  }

  Future<bool> _canRemove(
    String what,
    Type type,
    Token beginToken,
    Token endToken,
  ) async {
    int length = endToken.charEnd - beginToken.offset;
    if (length > 0) {
      String newSource = _constructSourceFromRemovableAnd((
        type,
        beginToken,
        endToken,
      ));
      print("Compile (${newSource.length} vs ${initialSource.length})");
      (Object, StackTrace)? compile = await helper.compile(newSource);
      if (compile != null) {
        String categorized = categorize(compile.$2);
        if (categorized == wantedCategorizedCrash) {
          print(" => Can remove $what with length $length");
          // We can actually do this.
          removeable.add((beginToken.charOffset, endToken.charEnd));
          return true;
        }
      }
    }
    return false;
  }

  String _constructSourceFromRemovableAnd(
    (Type type, Token beginToken, Token endToken)? nodeInfo,
  ) {
    IntervalListBuilder intervalListBuilder = new IntervalListBuilder();
    if (nodeInfo != null) {
      intervalListBuilder.addIntervalExcludingEnd(
        nodeInfo.$2.charOffset,
        nodeInfo.$3.charEnd,
      );
    }
    for ((int, int) removeThis in removeable) {
      intervalListBuilder.addIntervalExcludingEnd(removeThis.$1, removeThis.$2);
    }
    IntervalList intervalList = intervalListBuilder.buildIntervalList();
    int from = 0;
    StringBuffer sb = new StringBuffer();
    intervalList.forEach((int open, int close) {
      sb.write(initialSource.substring(from, open));
      from = close;
    });
    sb.write(initialSource.substring(from, initialSource.length));
    String output = sb.toString();
    if (debug) {
      String braceInfo = output.getBraceCountString();
      if (braceInfo != prevBraceInfo) {
        print(
          "After cutting out ${nodeInfo?.$1} at "
          "${nodeInfo?.$2.charOffset} brace info: "
          "$braceInfo",
        );
        prevBraceInfo = braceInfo;
      }
    }
    return output;
  }

  String? prevBraceInfo;

  String? getMinimizedSource() {
    if (removeable.isEmpty) return null;
    return _constructSourceFromRemovableAnd(null);
  }
}

extension on String {
  List<int> count() {
    List<int> result = List.filled(257, 0);
    List<int> codeUnits = this.codeUnits;
    for (int i = 0; i < codeUnits.length; i++) {
      int unit = codeUnits[i];
      if (unit < 0 || unit > 255) {
        result[256]++;
      } else {
        result[unit]++;
      }
    }
    return result;
  }

  String getBraceCountString() {
    List<int> counts = count();
    StringBuffer sb = new StringBuffer();
    for (int codeUnit in [40, 41, 91, 93, 123, 125]) {
      if (sb.isNotEmpty) sb.write(", ");
      sb.writeCharCode(codeUnit);
      sb.write(": ");
      sb.write(counts[codeUnit]);
    }
    return sb.toString();
  }
}
