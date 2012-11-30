// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library parser_helper;

import "dart:uri";

import "../../../sdk/lib/_internal/compiler/implementation/elements/elements.dart";
import "../../../sdk/lib/_internal/compiler/implementation/tree/tree.dart";
import "../../../sdk/lib/_internal/compiler/implementation/scanner/scannerlib.dart";
import "../../../sdk/lib/_internal/compiler/implementation/dart2jslib.dart" 
       hide SourceString;
import "../../../sdk/lib/_internal/compiler/implementation/source_file.dart";
import "../../../sdk/lib/_internal/compiler/implementation/util/util.dart";

export "../../../sdk/lib/_internal/compiler/implementation/dart2jslib.dart"
       show DiagnosticListener;
// TODO(ahe): We should have token library to export instead.
export "../../../sdk/lib/_internal/compiler/implementation/scanner/scannerlib.dart";

class LoggerCanceler implements DiagnosticListener {
  void cancel(String reason, {node, token, instruction, element}) {
    throw new CompilerCancelledException(reason);
  }

  void log(message) {
    print(message);
  }
}

Token scan(String text) => new StringScanner(text).tokenize();

Node parseBodyCode(String text, Function parseMethod,
                   {DiagnosticListener diagnosticHandler}) {
  Token tokens = scan(text);
  if (diagnosticHandler == null) diagnosticHandler = new LoggerCanceler();
  Script script =
      new Script(
          new Uri.fromComponents(scheme: "source"),
          new MockFile(text));
  LibraryElement library = new LibraryElement(script);
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
  Element element = parseUnit(text, compiler, compiler.mainApp).head;
  Expect.isNotNull(element);
  Expect.equals(ElementKind.FUNCTION, element.kind);
  return element.parseNode(compiler);
}

Node parseMember(String text, {DiagnosticListener diagnosticHandler}) {
  return parseBodyCode(text, (parser, tokens) => parser.parseMember(tokens),
                       diagnosticHandler: diagnosticHandler);
}

class MockFile extends SourceFile {
  MockFile(text)
      : super('<string>', text);
}

Link<Element> parseUnit(String text, Compiler compiler,
                        LibraryElement library) {
  Token tokens = scan(text);
  Uri uri = new Uri.fromComponents(scheme: "source");
  var script = new Script(uri, new MockFile(text));
  var unit = new CompilationUnitElement(script, library);
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

// TODO(ahe): We define this method to avoid having to import
// the scanner in the tests. We should move SourceString to another
// location instead.
SourceString buildSourceString(String name) {
  return new SourceString(name);
}
