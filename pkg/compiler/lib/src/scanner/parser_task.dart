// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of scanner;

class ParserTask extends CompilerTask {
  ParserTask(Compiler compiler) : super(compiler);
  String get name => 'Parser';

  Node parse(ElementX element) {
    return measure(() => element.parseNode(compiler));
  }

  Node parseCompilationUnit(Token token) {
    return measure(() {
      NodeListener listener = new NodeListener(compiler, null);
      Parser parser = new Parser(listener);
      parser.parseUnit(token);
      Node result = listener.popNode();
      assert(listener.nodes.isEmpty);
      return result;
    });
  }
}
