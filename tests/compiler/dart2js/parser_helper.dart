// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library parser_helper;

import "package:expect/expect.dart";

import "package:compiler/implementation/elements/elements.dart";
import "package:compiler/implementation/tree/tree.dart";
import "package:compiler/implementation/scanner/scannerlib.dart";
import "package:compiler/implementation/source_file.dart";
import "package:compiler/implementation/util/util.dart";

import "package:compiler/implementation/elements/modelx.dart"
    show CompilationUnitElementX, ElementX, LibraryElementX;

import "package:compiler/implementation/dart2jslib.dart";

export "package:compiler/implementation/dart2jslib.dart"
    show DiagnosticListener;
// TODO(ahe): We should have token library to export instead.
export "package:compiler/implementation/scanner/scannerlib.dart";

class LoggerCanceler implements DiagnosticListener {
  void cancel(String reason, {node, token, instruction, element}) {
    throw new CompilerCancelledException(reason);
  }

  void log(message) {
    print(message);
  }

  void internalError(node, String message) {
    log(message);
  }

  SourceSpan spanFromSpannable(node) {
    throw 'unsupported operation';
  }

  void reportMessage(SourceSpan span, Message message, kind) {
    log(message);
  }

  void reportFatalError(Spannable node,
                        MessageKind errorCode,
                        [Map arguments]) {
    log(new Message(errorCode, arguments, false));
  }

  void reportError(Spannable node, MessageKind errorCode, [Map arguments]) {
    log(new Message(errorCode, arguments, false));
  }

  void reportWarning(Spannable node, MessageKind errorCode, [Map arguments]) {
    log(new Message(errorCode, arguments, false));
  }

  void reportInfo(Spannable node, MessageKind errorCode, [Map arguments]) {
    log(new Message(errorCode, arguments, false));
  }

  void reportHint(Spannable node, MessageKind errorCode, [Map arguments]) {
    log(new Message(errorCode, arguments, false));
  }

  withCurrentElement(Element element, f()) => f();
}

Token scan(String text) => new StringScanner.fromString(text).tokenize();

Node parseBodyCode(String text, Function parseMethod,
                   {DiagnosticListener diagnosticHandler}) {
  Token tokens = scan(text);
  if (diagnosticHandler == null) diagnosticHandler = new LoggerCanceler();
  Uri uri = new Uri(scheme: "source");
  Script script = new Script(uri, uri,new MockFile(text));
  LibraryElement library = new LibraryElementX(script);
  library.canUseNative = true;
  NodeListener listener =
      new NodeListener(diagnosticHandler, library.entryCompilationUnit);
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
  return element.parseNode(compiler);
}

Node parseMember(String text, {DiagnosticListener diagnosticHandler}) {
  return parseBodyCode(text, (parser, tokens) => parser.parseMember(tokens),
                       diagnosticHandler: diagnosticHandler);
}

class MockFile extends StringSourceFile {
  MockFile(text)
      : super('<string>', text);
}

var sourceCounter = 0;

Link<Element> parseUnit(String text, Compiler compiler,
                        LibraryElement library,
                        [void registerSource(Uri uri, String source)]) {
  Token tokens = scan(text);
  Uri uri = new Uri(scheme: "source", path: '${++sourceCounter}');
  if (registerSource != null) {
    registerSource(uri, text);
  }
  var script = new Script(uri, uri, new MockFile(text));
  var unit = new CompilationUnitElementX(script, library);
  int id = 0;
  ElementListener listener = new ElementListener(compiler, unit, () => id++);
  PartialParser parser = new PartialParser(listener);
  compiler.withCurrentElement(unit, () => parser.parseUnit(tokens));
  return unit.localMembers;
}

NodeList fullParseUnit(String source, {DiagnosticListener diagnosticHandler}) {
  return parseBodyCode(source, (parser, tokens) => parser.parseUnit(tokens),
                       diagnosticHandler: diagnosticHandler);
}
