// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async' show Future;

import 'dart:convert' show jsonDecode;

import 'dart:io' show File;

import 'dart:typed_data' show Uint8List;

import 'package:front_end/src/fasta/parser.dart' show Parser;
import 'package:front_end/src/fasta/scanner.dart';

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

import 'parser_test_parser.dart' show TestParser;

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

ScannerConfiguration scannerConfiguration = new ScannerConfiguration(
    enableTripleShift: true,
    enableExtensionMethods: true,
    enableNonNullable: true);

class Context extends ChainContext with MatchContext {
  final updateExpectations;

  Context(this.updateExpectations);

  final List<Step> steps = const <Step>[
    const ListenerStep(),
    const IntertwinedStep(),
  ];

  final ExpectationSet expectationSet =
      new ExpectationSet.fromJsonList(jsonDecode(EXPECTATIONS));
}

class ListenerStep extends Step<TestDescription, TestDescription, Context> {
  const ListenerStep();

  String get name => "listener";

  Future<Result<TestDescription>> run(
      TestDescription description, Context context) async {
    File f = new File.fromUri(description.uri);
    List<int> rawBytes = f.readAsBytesSync();

    Uint8List bytes = new Uint8List(rawBytes.length + 1);
    bytes.setRange(0, rawBytes.length, rawBytes);

    Utf8BytesScanner scanner = new Utf8BytesScanner(bytes,
        includeComments: true, configuration: scannerConfiguration);
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

class IntertwinedStep extends Step<TestDescription, TestDescription, Context> {
  const IntertwinedStep();

  String get name => "intertwined";

  Future<Result<TestDescription>> run(
      TestDescription description, Context context) async {
    File f = new File.fromUri(description.uri);
    List<int> rawBytes = f.readAsBytesSync();

    Uint8List bytes = new Uint8List(rawBytes.length + 1);
    bytes.setRange(0, rawBytes.length, rawBytes);

    Utf8BytesScanner scanner = new Utf8BytesScanner(bytes,
        includeComments: true, configuration: scannerConfiguration);
    Token firstToken = scanner.tokenize();

    if (firstToken == null) {
      return crash(description, StackTrace.current);
    }

    ParserTestListener2 parserTestListener = new ParserTestListener2();
    TestParser parser = new TestParser(parserTestListener);
    parserTestListener.parser = parser;
    parser.sb = parserTestListener.sb;
    parser.parseUnit(firstToken);

    return context.match<TestDescription>(
        ".intertwined.expect", "${parser.sb}", description.uri, description);
  }
}

class ParserTestListener2 extends ParserTestListener {
  TestParser parser;

  void doPrint(String s) {
    sb.writeln(("  " * parser.indent) + "listener: " + s);
  }
}
