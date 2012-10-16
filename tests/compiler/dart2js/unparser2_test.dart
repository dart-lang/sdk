// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("../../../lib/compiler/implementation/scanner/scannerlib.dart");
#import("../../../lib/compiler/implementation/elements/elements.dart"); // only need CompilationUnitElement
#import("../../../lib/compiler/implementation/tree/tree.dart");
#import("../../../lib/compiler/implementation/leg.dart"); // only need DiagnosticListener & Script

main() {
  testClassDef();
  testClass1Field();
  testClass2Fields();
  testClass1Field1Method();
  testClass1Field2Method();
  testClassDefTypeParam();
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

void compareCode(String code) {
  Expect.equals(code, doUnparse(code));
}

String doUnparse(String source) {
  MessageCollector diagnosticListener = new MessageCollector();
  Script script = new Script(null, null);
  LibraryElement lib = new LibraryElement(script);
  CompilationUnitElement element = new CompilationUnitElement(script, lib);
  StringScanner scanner = new StringScanner(source);
  Token beginToken = scanner.tokenize();
  NodeListener listener = new NodeListener(diagnosticListener, element);
  Parser parser = new Parser(listener);
  parser.parseUnit(beginToken);
  Node node = listener.popNode();
  Expect.isTrue(listener.nodes.isEmpty());
  return unparse(node);
}

class MessageCollector implements DiagnosticListener {
  List<String> messages;
  MessageCollector() {
    messages = [];
  }
  void cancel(String reason, {node, token, instruction, element}) {
    messages.add(reason);
    throw reason;
  }
  void log(message) {
    messages.add(message);
  }
  void internalErrorOnElement(Element element, String message) {
    throw message;
  }
  void internalError(String message,
                     {Node node, Token token, dynamic instruction,
                      Element element}) {
    throw message;
  }
}
