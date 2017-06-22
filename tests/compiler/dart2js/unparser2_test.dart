// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "package:compiler/src/parser/element_listener.dart";
import "package:compiler/src/parser/node_listener.dart";
import "package:front_end/src/fasta/parser.dart";
import "package:front_end/src/fasta/scanner.dart";
import "package:compiler/src/tree/tree.dart";

import "package:compiler/src/diagnostics/diagnostic_listener.dart";
import "package:compiler/src/elements/elements.dart"
    show CompilationUnitElement, LibraryElement;
import "package:compiler/src/elements/modelx.dart"
    show CompilationUnitElementX, LibraryElementX;
import "package:compiler/src/script.dart";

main() {
  testClassDef();
  testClass1Field();
  testClass2Fields();
  testClass1Field1Method();
  testClass1Field2Method();
  testClassDefTypeParam();
  testEnumDef();
  testEnum1Value();
  testEnum2Value();
  testEnum3Value();
  testEnum3CommaValue();
}

testClassDef() {
  compareCode('class T{}');
}

testClass1Field() {
  compareCode('class T{var x;}');
}

testClass2Fields() {
  compareCode('class T{var x;var y;}');
}

testClass1Field1Method() {
  compareCode('class T{var x;m(){}}');
}

testClass1Field2Method() {
  compareCode('class T{a(){}b(){}}');
}

testClassDefTypeParam() {
  compareCode('class T<X>{}');
}

testEnumDef() {
  compareCode('enum T {}');
}

testEnum1Value() {
  compareCode('enum T {A}');
}

testEnum2Value() {
  compareCode('enum T {A,B}');
}

testEnum3Value() {
  compareCode('enum T {A,B,C}');
}

testEnum3CommaValue() {
  compareCode('enum T {A,B,C,}', expectedResult: 'enum T {A,B,C}');
}

void compareCode(String code, {String expectedResult}) {
  if (expectedResult == null) {
    expectedResult = code;
  }
  Expect.equals(expectedResult, doUnparse(code));
}

String doUnparse(String source) {
  MessageCollector diagnosticListener = new MessageCollector();
  Script script = new Script(null, null, null);
  LibraryElement lib = new LibraryElementX(script);
  CompilationUnitElement element = new CompilationUnitElementX(script, lib);
  StringScanner scanner = new StringScanner(source);
  Token beginToken = scanner.tokenize();
  NodeListener listener =
      new NodeListener(const ScannerOptions(), diagnosticListener, element);
  Parser parser = new Parser(listener);
  parser.parseUnit(beginToken);
  Node node = listener.popNode();
  Expect.isTrue(listener.nodes.isEmpty);
  return unparse(node);
}

class MessageCollector extends DiagnosticReporter {
  List<String> messages;
  MessageCollector() {
    messages = [];
  }
  void internalError(node, covariant String reason) {
    messages.add(reason);
    throw reason;
  }

  void log(message) {
    messages.add(message);
  }

  noSuchMethod(Invocation invocation) => throw 'unsupported operation';
}
