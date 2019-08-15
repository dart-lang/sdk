// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async' show Future;

import 'dart:io' show File;

import 'dart:typed_data' show Uint8List;

import 'package:front_end/src/fasta/parser.dart' show Parser;

import 'package:front_end/src/fasta/parser/listener.dart' show Listener;

import 'package:front_end/src/fasta/command_line_reporting.dart'
    as command_line_reporting;

import 'package:front_end/src/fasta/scanner/utf8_bytes_scanner.dart'
    show Utf8BytesScanner;

import 'package:front_end/src/scanner/token.dart' show Token;

import 'package:front_end/src/scanner/token.dart';

import 'package:kernel/kernel.dart';

import 'package:testing/testing.dart'
    show ChainContext, Result, Step, TestDescription, Chain, runMe;

main([List<String> arguments = const []]) =>
    runMe(arguments, createContext, "../testing.json");

Future<Context> createContext(
    Chain suite, Map<String, String> environment) async {
  return new Context();
}

class Context extends ChainContext {
  final List<Step> steps = const <Step>[
    const LintTest(),
  ];

  // Override special handling of negative tests.
  @override
  Result processTestResult(
      TestDescription description, Result result, bool last) {
    return result;
  }

  List<int> rawBytes;
  String cachedText;
  List<int> lineStarts;
  Uri uri;

  void clear() {
    rawBytes = null;
    cachedText = null;
    lineStarts = null;
    uri = null;
  }

  String getErrorMessage(int offset, int squigglyLength, String message) {
    Source source = new Source(lineStarts, rawBytes, uri, uri);
    Location location = source.getLocation(uri, offset);
    return command_line_reporting.formatErrorMessage(
        source.getTextLine(location.line),
        location,
        squigglyLength,
        uri.toString(),
        message);
  }
}

class LintTest extends Step<TestDescription, TestDescription, Context> {
  const LintTest();

  String get name => "lint test";

  Future<Result<TestDescription>> run(
      TestDescription description, Context context) async {
    context.clear();
    context.uri = description.uri;

    File f = new File.fromUri(context.uri);
    context.rawBytes = f.readAsBytesSync();

    Uint8List bytes = new Uint8List(context.rawBytes.length + 1);
    bytes.setRange(0, context.rawBytes.length, context.rawBytes);

    Utf8BytesScanner scanner =
        new Utf8BytesScanner(bytes, includeComments: true);
    Token firstToken = scanner.tokenize();
    context.lineStarts = scanner.lineStarts;

    if (firstToken == null) return null;
    List<String> problems;
    LintListener lintListener =
        new LintListener((int offset, int squigglyLength, String message) {
      problems ??= new List<String>();
      problems.add(context.getErrorMessage(offset, squigglyLength, message));
    });
    Parser parser = new Parser(lintListener);
    parser.parseUnit(firstToken);

    if (problems == null) {
      return pass(description);
    }
    return fail(description, problems.join("\n\n"));
  }
}

class LintListener extends Listener {
  final Function(int offset, int squigglyLength, String message) onProblem;

  LintListener(this.onProblem);

  LatestType _latestType;

  @override
  void beginVariablesDeclaration(
      Token token, Token lateToken, Token varFinalOrConst) {
    if (!_latestType.type) {
      onProblem(
          varFinalOrConst.offset, varFinalOrConst.length, "No explicit type.");
    }
  }

  @override
  void handleType(Token beginToken, Token questionMark) {
    _latestType = new LatestType(beginToken, true);
  }

  @override
  void handleNoType(Token lastConsumed) {
    _latestType = new LatestType(lastConsumed, false);
  }
}

class LatestType {
  final Token token;
  bool type;

  LatestType(this.token, this.type);
}
