// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show jsonDecode;

import 'dart:io' show File;

import 'dart:typed_data' show Uint8List;

import 'package:front_end/src/fasta/command_line_reporting.dart'
    as command_line_reporting;

import 'package:front_end/src/fasta/messages.dart' show Message;

import 'package:front_end/src/fasta/util/direct_parser_ast.dart' show getAST;

import 'package:_fe_analyzer_shared/src/parser/parser.dart'
    show Parser, lengthOfSpan;

import 'package:_fe_analyzer_shared/src/scanner/scanner.dart'
    show ErrorToken, ScannerConfiguration, Token, Utf8BytesScanner;

import 'package:_fe_analyzer_shared/src/scanner/utf8_bytes_scanner.dart'
    show Utf8BytesScanner;

import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;

import 'package:front_end/src/fasta/source/stack_listener_impl.dart'
    show offsetForToken;

import 'package:front_end/src/fasta/util/direct_parser_ast_helper.dart'
    show DirectParserASTContent;

import 'package:kernel/ast.dart';

import 'package:testing/testing.dart'
    show
        Chain,
        ChainContext,
        ExpectationSet,
        Result,
        Step,
        TestDescription,
        runMe;

import 'fasta/testing/suite.dart' show UPDATE_EXPECTATIONS;
import 'utils/kernel_chain.dart' show MatchContext;

import 'parser_test_listener.dart' show ParserTestListener;

import 'parser_test_parser.dart' show TestParser;

import 'testing_utils.dart' show checkEnvironment;

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
  const Set<String> knownEnvironmentKeys = {
    "updateExpectations",
    "trace",
    "annotateLines"
  };
  checkEnvironment(environment, knownEnvironmentKeys);

  bool updateExpectations = environment["updateExpectations"] == "true";
  bool trace = environment["trace"] == "true";
  bool annotateLines = environment["annotateLines"] == "true";

  return new Context(suite.name, updateExpectations, trace, annotateLines);
}

ScannerConfiguration scannerConfiguration = new ScannerConfiguration(
    enableTripleShift: true,
    enableExtensionMethods: true,
    enableNonNullable: true);

ScannerConfiguration scannerConfigurationNonNNBD = new ScannerConfiguration(
    enableTripleShift: true,
    enableExtensionMethods: true,
    enableNonNullable: false);

class Context extends ChainContext with MatchContext {
  final bool updateExpectations;

  @override
  String get updateExpectationsOption => '${UPDATE_EXPECTATIONS}=true';

  final bool addTrace;
  final bool annotateLines;
  final String suiteName;

  Context(this.suiteName, this.updateExpectations, this.addTrace,
      this.annotateLines);

  final List<Step> steps = const <Step>[
    const TokenStep(true, ".scanner.expect"),
    const TokenStep(false, ".parser.expect"),
    const ListenerStep(true),
    const IntertwinedStep(),
  ];

  final ExpectationSet expectationSet =
      new ExpectationSet.fromJsonList(jsonDecode(EXPECTATIONS));

  // Override special handling of negative tests.
  @override
  Result processTestResult(
      TestDescription description, Result result, bool last) {
    return result;
  }
}

class ContextChecksOnly extends Context {
  ContextChecksOnly(String suiteName) : super(suiteName, false, false, false);

  final List<Step> steps = const <Step>[
    const ListenerStep(false),
    const DirectParserASTStep(),
  ];

  final ExpectationSet expectationSet =
      new ExpectationSet.fromJsonList(jsonDecode(EXPECTATIONS));

  // Override special handling of negative tests.
  @override
  Result processTestResult(
      TestDescription description, Result result, bool last) {
    return result;
  }
}

class DirectParserASTStep
    extends Step<TestDescription, TestDescription, Context> {
  const DirectParserASTStep();
  String get name => "DirectParserAST";
  Future<Result<TestDescription>> run(
      TestDescription description, Context context) {
    Uri uri = description.uri;
    File f = new File.fromUri(uri);
    List<int> rawBytes = f.readAsBytesSync();
    DirectParserASTContent ast = getAST(rawBytes);
    if (ast.what != "CompilationUnit") {
      throw "Expected a single element for 'CompilationUnit' "
          "but got ${ast.what}";
    }
    return new Future.value(new Result<TestDescription>.pass(description));
  }
}

class ListenerStep extends Step<TestDescription, TestDescription, Context> {
  final bool doExpects;
  const ListenerStep(this.doExpects);

  String get name => "listener";

  Future<Result<TestDescription>> run(
      TestDescription description, Context context) {
    List<int> lineStarts = <int>[];

    Token firstToken =
        scanUri(description.uri, description.shortName, lineStarts: lineStarts);

    if (firstToken == null) {
      return Future.value(crash(description, StackTrace.current));
    }

    File f = new File.fromUri(description.uri);
    List<int> rawBytes = f.readAsBytesSync();
    Source source =
        new Source(lineStarts, rawBytes, description.uri, description.uri);

    String shortName = "${context.suiteName}/${description.shortName}";

    ParserTestListenerWithMessageFormatting parserTestListener =
        new ParserTestListenerWithMessageFormatting(
            context.addTrace, context.annotateLines, source, shortName);
    Parser parser = new Parser(parserTestListener);
    parser.parseUnit(firstToken);

    String errors = "";
    if (parserTestListener.errors.isNotEmpty) {
      errors = "Problems reported:\n\n"
          "${parserTestListener.errors.join("\n\n")}\n\n";
    }

    if (doExpects) {
      return context.match<TestDescription>(".expect",
          "${errors}${parserTestListener.sb}", description.uri, description);
    } else {
      return new Future.value(new Result<TestDescription>.pass(description));
    }
  }
}

class IntertwinedStep extends Step<TestDescription, TestDescription, Context> {
  const IntertwinedStep();

  String get name => "intertwined";

  Future<Result<TestDescription>> run(
      TestDescription description, Context context) {
    List<int> lineStarts = <int>[];
    Token firstToken =
        scanUri(description.uri, description.shortName, lineStarts: lineStarts);

    if (firstToken == null) {
      return Future.value(crash(description, StackTrace.current));
    }

    File f = new File.fromUri(description.uri);
    List<int> rawBytes = f.readAsBytesSync();
    Source source =
        new Source(lineStarts, rawBytes, description.uri, description.uri);

    ParserTestListenerForIntertwined parserTestListener =
        new ParserTestListenerForIntertwined(
            context.addTrace, context.annotateLines, source);
    TestParser parser = new TestParser(parserTestListener, context.addTrace);
    parserTestListener.parser = parser;
    parser.sb = parserTestListener.sb;
    parser.parseUnit(firstToken);

    return context.match<TestDescription>(
        ".intertwined.expect", "${parser.sb}", description.uri, description);
  }
}

class TokenStep extends Step<TestDescription, TestDescription, Context> {
  final bool onlyScanner;
  final String suffix;

  const TokenStep(this.onlyScanner, this.suffix);

  String get name => "token";

  Future<Result<TestDescription>> run(
      TestDescription description, Context context) {
    List<int> lineStarts = <int>[];
    Token firstToken =
        scanUri(description.uri, description.shortName, lineStarts: lineStarts);

    if (firstToken == null) {
      return Future.value(crash(description, StackTrace.current));
    }

    StringBuffer beforeParser = tokenStreamToString(firstToken, lineStarts);
    StringBuffer beforeParserWithTypes =
        tokenStreamToString(firstToken, lineStarts, addTypes: true);
    if (onlyScanner) {
      return context.match<TestDescription>(
          suffix,
          "${beforeParser}\n\n${beforeParserWithTypes}",
          description.uri,
          description);
    }

    ParserTestListener parserTestListener =
        new ParserTestListener(context.addTrace);
    Parser parser = new Parser(parserTestListener);
    bool parserCrashed = false;
    dynamic parserCrashedE;
    StackTrace parserCrashedSt;
    try {
      parser.parseUnit(firstToken);
    } catch (e, st) {
      parserCrashed = true;
      parserCrashedE = e;
      parserCrashedSt = st;
    }

    StringBuffer afterParser = tokenStreamToString(firstToken, lineStarts);
    StringBuffer afterParserWithTypes =
        tokenStreamToString(firstToken, lineStarts, addTypes: true);

    bool rewritten =
        beforeParserWithTypes.toString() != afterParserWithTypes.toString();
    String rewrittenString =
        rewritten ? "NOTICE: Stream was rewritten by parser!\n\n" : "";

    Future<Result<TestDescription>> result = context.match<TestDescription>(
        suffix,
        "${rewrittenString}${afterParser}\n\n${afterParserWithTypes}",
        description.uri,
        description);
    return result.then((result) {
      if (parserCrashed) {
        return crash("Parser crashed: $parserCrashedE", parserCrashedSt);
      } else {
        return result;
      }
    });
  }
}

StringBuffer tokenStreamToString(Token firstToken, List<int> lineStarts,
    {bool addTypes: false}) {
  StringBuffer sb = new StringBuffer();
  Token token = firstToken;

  Token process(Token token, bool errorTokens) {
    bool printed = false;
    int endOfLast = -1;
    int lineStartsIteratorLine = 1;
    Iterator<int> lineStartsIterator = lineStarts.iterator;
    lineStartsIterator.moveNext();
    lineStartsIterator.moveNext();
    lineStartsIteratorLine++;

    Set<Token> seenTokens = new Set<Token>.identity();
    while (token != null) {
      if (errorTokens && token is! ErrorToken) return token;
      if (!errorTokens && token is ErrorToken) {
        if (token == token.next) break;
        token = token.next;
        continue;
      }

      int prevLine = lineStartsIteratorLine;
      while (token.offset >= lineStartsIterator.current &&
          lineStartsIterator.moveNext()) {
        lineStartsIteratorLine++;
      }
      if (printed &&
          (token.offset > endOfLast || prevLine < lineStartsIteratorLine)) {
        if (prevLine < lineStartsIteratorLine) {
          for (int i = prevLine; i < lineStartsIteratorLine; i++) {
            sb.write("\n");
          }
        } else {
          sb.write(" ");
        }
      }
      if (token is! ErrorToken) {
        sb.write(token.lexeme);
      }
      if (addTypes) {
        sb.write("[${token.runtimeType}]");
      }
      printed = true;
      endOfLast = token.end;
      if (token == token.next) break;
      token = token.next;
      if (!seenTokens.add(token)) {
        // Loop in tokens: Print error and break to avoid infinite loop.
        sb.write("\n\nERROR: Loop in tokens: $token "
            "(${token.runtimeType}, ${token.type}, ${token.offset})) "
            "was seen before "
            "(linking to ${token.next}, ${token.next.runtimeType}, "
            "${token.next.type}, ${token.next.offset})!\n\n");
        break;
      }
    }

    return token;
  }

  if (addTypes) {
    token = process(token, true);
  }
  token = process(token, false);

  return sb;
}

Token scanUri(Uri uri, String shortName, {List<int> lineStarts}) {
  ScannerConfiguration config;

  String firstDir = shortName.split("/")[0];
  if (firstDir == "non-nnbd") {
    config = scannerConfigurationNonNNBD;
  } else {
    config = scannerConfiguration;
  }

  File f = new File.fromUri(uri);
  List<int> rawBytes = f.readAsBytesSync();

  return scanRawBytes(rawBytes, config, lineStarts);
}

Token scanRawBytes(
    List<int> rawBytes, ScannerConfiguration config, List<int> lineStarts) {
  Uint8List bytes = new Uint8List(rawBytes.length + 1);
  bytes.setRange(0, rawBytes.length, rawBytes);

  Utf8BytesScanner scanner =
      new Utf8BytesScanner(bytes, includeComments: true, configuration: config);
  Token firstToken = scanner.tokenize();
  if (lineStarts != null) {
    lineStarts.addAll(scanner.lineStarts);
  }
  return firstToken;
}

class ParserTestListenerWithMessageFormatting extends ParserTestListener {
  final bool annotateLines;
  final Source source;
  final String shortName;
  final List<String> errors = <String>[];
  Location latestSeenLocation;

  ParserTestListenerWithMessageFormatting(
      bool trace, this.annotateLines, this.source, this.shortName)
      : super(trace);

  void doPrint(String s) {
    super.doPrint(s);
    if (!annotateLines) {
      if (s.startsWith("beginCompilationUnit(") ||
          s.startsWith("endCompilationUnit(")) {
        if (indent != 0) {
          throw "Incorrect indents: '$s' (indent = $indent).\n\n"
              "${sb.toString()}";
        }
      } else {
        if (indent <= 0) {
          throw "Incorrect indents: '$s' (indent = $indent).\n\n"
              "${sb.toString()}";
        }
      }
    }
  }

  void seen(Token token) {
    if (!annotateLines) return;
    if (token == null) return;
    if (source == null) return;
    if (offsetForToken(token) < 0) return;
    Location location =
        source.getLocation(source.fileUri, offsetForToken(token));
    if (latestSeenLocation == null || location.line > latestSeenLocation.line) {
      latestSeenLocation = location;
      String sourceLine = source.getTextLine(location.line);
      doPrint("");
      doPrint("// Line ${location.line}: $sourceLine");
    }
  }

  void handleRecoverableError(
      Message message, Token startToken, Token endToken) {
    if (source != null) {
      Location location =
          source.getLocation(source.fileUri, offsetForToken(startToken));
      int length = lengthOfSpan(startToken, endToken);
      if (length <= 0) length = 1;
      errors.add(command_line_reporting.formatErrorMessage(
          source.getTextLine(location.line),
          location,
          length,
          shortName,
          message.message));
    } else {
      errors.add(message.message);
    }

    super.handleRecoverableError(message, startToken, endToken);
  }
}

class ParserTestListenerForIntertwined
    extends ParserTestListenerWithMessageFormatting {
  TestParser parser;

  ParserTestListenerForIntertwined(
      bool trace, bool annotateLines, Source source)
      : super(trace, annotateLines, source, null);

  void doPrint(String s) {
    int prevIndent = super.indent;
    super.indent = parser.indent;
    if (s.trim() == "") {
      super.doPrint("");
    } else {
      super.doPrint("listener: " + s);
    }
    super.indent = prevIndent;
  }
}
