// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.parser.task;

import '../common.dart';
import '../common/tasks.dart' show
    CompilerTask;
import '../compiler.dart' show
    Compiler;
import '../elements/modelx.dart' show
    ElementX;
import '../tokens/token.dart' show
    Token;
import '../tree/tree.dart' show
    Node;

import 'element_listener.dart' show
    ScannerOptions;
import 'listener.dart' show
    ParserError;
import 'node_listener.dart' show
    NodeListener;
import 'parser.dart' show
    Parser;

class ParserTask extends CompilerTask {
  final bool _enableConditionalDirectives;

  ParserTask(Compiler compiler,
             {bool enableConditionalDirectives: false})
      : this._enableConditionalDirectives = enableConditionalDirectives,
        super(compiler);

  String get name => 'Parser';

  Node parse(ElementX element) {
    return measure(() => element.parseNode(compiler.parsing));
  }

  Node parseCompilationUnit(Token token) {
    return measure(() {
      NodeListener listener = new NodeListener(
          const ScannerOptions(), reporter, null);
      Parser parser = new Parser(
          listener, enableConditionalDirectives: _enableConditionalDirectives);
      try {
        parser.parseUnit(token);
      } on ParserError catch(_) {
        assert(invariant(token, compiler.compilationFailed));
        return listener.makeNodeList(0, null, null, '\n');
      }
      Node result = listener.popNode();
      assert(listener.nodes.isEmpty);
      return result;
    });
  }
}
