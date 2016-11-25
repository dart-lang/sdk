// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.parser.task;

import '../common.dart';
import '../common/tasks.dart' show CompilerTask;
import '../compiler.dart' show Compiler;
import '../elements/modelx.dart' show ElementX;
import '../tokens/token.dart' show Token;
import '../tree/tree.dart' show Node;
import 'element_listener.dart' show ScannerOptions;
import 'listener.dart' show ParserError;
import 'node_listener.dart' show NodeListener;
import 'parser.dart' show Parser;

class ParserTask extends CompilerTask {
  final Compiler compiler;

  ParserTask(Compiler compiler): compiler = compiler, super(compiler.measurer);

  String get name => 'Parser';

  Node parse(ElementX element) {
    return measure(() => element.parseNode(compiler.parsingContext));
  }

  Node parseCompilationUnit(Token token) {
    return measure(() {
      NodeListener listener =
          new NodeListener(const ScannerOptions(), compiler.reporter, null);
      Parser parser = new Parser(listener);
      try {
        parser.parseUnit(token);
      } on ParserError catch (_) {
        assert(invariant(token, compiler.compilationFailed));
        return listener.makeNodeList(0, null, null, '\n');
      }
      Node result = listener.popNode();
      assert(listener.nodes.isEmpty);
      return result;
    });
  }
}
