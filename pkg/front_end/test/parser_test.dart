// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async' show Future;

import 'dart:convert' show jsonDecode;

import 'dart:io' show File;

import 'dart:typed_data' show Uint8List;

import 'package:front_end/src/fasta/parser.dart' show Parser;

import 'package:front_end/src/fasta/scanner/utf8_bytes_scanner.dart'
    show Utf8BytesScanner;

import 'package:front_end/src/scanner/token.dart' show Token;

import 'package:testing/testing.dart'
    show
        Chain,
        ChainContext,
        ExpectationSet,
        Result,
        Step,
        TestDescription,
        runMe;

import 'utils/kernel_chain.dart' show MatchContext;

import 'parser_test_listener.dart' show ParserTestListener;

const String EXPECTATIONS = '''
[
  {
    "name": "ExpectationFileMismatch",
    "group": "Fail"
  },
  {
    "name": "ExpectationFileMissing",
    "group": "Fail"
  }
]
''';

main([List<String> arguments = const []]) =>
    runMe(arguments, createContext, configurationPath: "../testing.json");

Future<Context> createContext(
    Chain suite, Map<String, String> environment) async {
  return new Context(environment["updateExpectations"] == "true");
}

class Context extends ChainContext with MatchContext {
  final updateExpectations;

  Context(this.updateExpectations);

  final List<Step> steps = const <Step>[
    const ParserStep(),
  ];

  final ExpectationSet expectationSet =
      new ExpectationSet.fromJsonList(jsonDecode(EXPECTATIONS));
}

class ParserStep extends Step<TestDescription, TestDescription, Context> {
  const ParserStep();

  String get name => "parser";

  Future<Result<TestDescription>> run(
      TestDescription description, Context context) async {
    File f = new File.fromUri(description.uri);
    List<int> rawBytes = f.readAsBytesSync();

    Uint8List bytes = new Uint8List(rawBytes.length + 1);
    bytes.setRange(0, rawBytes.length, rawBytes);

    Utf8BytesScanner scanner =
        new Utf8BytesScanner(bytes, includeComments: true);
    Token firstToken = scanner.tokenize();

    if (firstToken == null) {
      return crash(description, StackTrace.current);
    }

    ParserTestListener parserTestListener = new ParserTestListener();
    Parser parser = new Parser(parserTestListener);
    parser.parseUnit(firstToken);

    return context.match<TestDescription>(
        ".expect", "${parserTestListener.sb}", description.uri, description);
  }
}
