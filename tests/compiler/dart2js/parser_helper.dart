// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library parser_helper;

import "package:expect/expect.dart";

import "package:compiler/src/elements/elements.dart";
import 'package:compiler/src/id_generator.dart';
import "package:compiler/src/tree/tree.dart";
import "package:compiler/src/parser/element_listener.dart";
import "package:compiler/src/parser/node_listener.dart";
import "package:compiler/src/parser/parser.dart";
import "package:compiler/src/parser/partial_parser.dart";
import "package:compiler/src/scanner/string_scanner.dart";
import "package:compiler/src/tokens/token.dart";
import "package:compiler/src/tokens/token_constants.dart";
import "package:compiler/src/io/source_file.dart";
import "package:compiler/src/util/util.dart";

import "package:compiler/src/elements/modelx.dart"
    show CompilationUnitElementX, ElementX, LibraryElementX;

import "package:compiler/src/compiler.dart";
import 'package:compiler/src/options.dart';
import "package:compiler/src/diagnostics/source_span.dart";
import "package:compiler/src/diagnostics/spannable.dart";
import "package:compiler/src/diagnostics/diagnostic_listener.dart";
import "package:compiler/src/diagnostics/messages.dart";
import "package:compiler/src/script.dart";

import "options_helper.dart";

export "package:compiler/src/diagnostics/diagnostic_listener.dart";
export 'package:compiler/src/parser/listener.dart';
export 'package:compiler/src/parser/node_listener.dart';
export 'package:compiler/src/parser/parser.dart';
export 'package:compiler/src/parser/partial_parser.dart';
export 'package:compiler/src/parser/partial_elements.dart';
export "package:compiler/src/tokens/token.dart";
export "package:compiler/src/tokens/token_constants.dart";

class LoggerCanceler extends DiagnosticReporter {
  DiagnosticOptions get options => const MockDiagnosticOptions();

  void log(message) {
    print(message);
  }

  void internalError(node, String message) {
    log(message);
  }

  SourceSpan spanFromSpannable(node) {
    throw 'unsupported operation';
  }

  void reportError(DiagnosticMessage message,
      [List<DiagnosticMessage> infos = const <DiagnosticMessage>[]]) {
    log(message);
    infos.forEach(log);
  }

  void reportWarning(DiagnosticMessage message,
      [List<DiagnosticMessage> infos = const <DiagnosticMessage>[]]) {
    log(message);
    infos.forEach(log);
  }

  void reportInfo(Spannable node, MessageKind errorCode,
      [Map arguments = const {}]) {
    log(new Message(MessageTemplate.TEMPLATES[errorCode], arguments, false));
  }

  void reportHint(DiagnosticMessage message,
      [List<DiagnosticMessage> infos = const <DiagnosticMessage>[]]) {
    log(message);
    infos.forEach(log);
  }

  withCurrentElement(Element element, f()) => f();

  @override
  DiagnosticMessage createMessage(Spannable spannable, MessageKind messageKind,
      [Map arguments = const {}]) {
    return new DiagnosticMessage(null, spannable,
        new Message(MessageTemplate.TEMPLATES[messageKind], arguments, false));
  }

  @override
  bool get hasReportedError => false;
}

Token scan(String text) => new StringScanner.fromString(text).tokenize();

Node parseBodyCode(String text, Function parseMethod,
    {DiagnosticReporter reporter}) {
  Token tokens = scan(text);
  if (reporter == null) reporter = new LoggerCanceler();
  Uri uri = new Uri(scheme: "source");
  Script script = new Script(uri, uri, new MockFile(text));
  LibraryElement library = new LibraryElementX(script);
  NodeListener listener = new NodeListener(
      new ScannerOptions(canUseNative: true),
      reporter,
      library.entryCompilationUnit);
  Parser parser = new Parser(listener);
  Token endToken = parseMethod(parser, tokens);
  assert(endToken.kind == EOF_TOKEN);
  Node node = listener.popNode();
  Expect.isNotNull(node);
  Expect.isTrue(listener.nodes.isEmpty, 'Not empty: ${listener.nodes}');
  return node;
}

Node parseStatement(String text) =>
    parseBodyCode(text, (parser, tokens) => parser.parseStatement(tokens));

Node parseFunction(String text, Compiler compiler) {
  ElementX element = parseUnit(text, compiler, compiler.mainApp).head;
  Expect.isNotNull(element);
  Expect.equals(ElementKind.FUNCTION, element.kind);
  return element.parseNode(compiler.parsingContext);
}

Node parseMember(String text, {DiagnosticReporter reporter}) {
  return parseBodyCode(text, (parser, tokens) => parser.parseMember(tokens),
      reporter: reporter);
}

class MockFile extends StringSourceFile {
  MockFile(text) : super.fromName('<string>', text);
}

var sourceCounter = 0;

Link<Element> parseUnit(String text, Compiler compiler, LibraryElement library,
    [void registerSource(Uri uri, String source)]) {
  Token tokens = scan(text);
  Uri uri = new Uri(scheme: "source", path: '${++sourceCounter}');
  if (registerSource != null) {
    registerSource(uri, text);
  }
  var script = new Script(uri, uri, new MockFile(text));
  var unit = new CompilationUnitElementX(script, library);
  DiagnosticReporter reporter = compiler.reporter;
  ElementListener listener = new ElementListener(
      compiler.parsingContext.getScannerOptionsFor(library),
      reporter,
      unit,
      new IdGenerator());
  PartialParser parser = new PartialParser(listener);
  reporter.withCurrentElement(unit, () => parser.parseUnit(tokens));
  return unit.localMembers;
}

NodeList fullParseUnit(String source, {DiagnosticReporter reporter}) {
  return parseBodyCode(source, (parser, tokens) => parser.parseUnit(tokens),
      reporter: reporter);
}
