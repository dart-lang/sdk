// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.parser.diet.task;

import '../common.dart';
import '../common/tasks.dart' show
    CompilerTask;
import '../compiler.dart' show
    Compiler;
import '../elements/elements.dart' show
    CompilationUnitElement;
import '../tokens/token.dart' show
    Token;

import 'listener.dart' show
    ParserError;
import 'element_listener.dart' show
    ElementListener;
import 'partial_parser.dart' show
    PartialParser;

class DietParserTask extends CompilerTask {
  DietParserTask(Compiler compiler) : super(compiler);
  final String name = 'Diet Parser';

  dietParse(CompilationUnitElement compilationUnit, Token tokens) {
    measure(() {
      Function idGenerator = compiler.getNextFreeClassId;
      ElementListener listener =
          new ElementListener(compiler.reporter, compilationUnit, idGenerator);
      PartialParser parser = new PartialParser(listener);
      try {
        parser.parseUnit(tokens);
      } on ParserError catch(_) {
        assert(invariant(compilationUnit, compiler.compilationFailed));
      }
    });
  }
}
