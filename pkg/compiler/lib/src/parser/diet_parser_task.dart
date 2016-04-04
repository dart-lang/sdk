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
    ElementListener,
    ScannerOptions;
import 'partial_parser.dart' show
    PartialParser;

class DietParserTask extends CompilerTask {
  final bool _enableConditionalDirectives;

  DietParserTask(Compiler compiler, {bool enableConditionalDirectives})
      : this._enableConditionalDirectives = enableConditionalDirectives,
        super(compiler);

  final String name = 'Diet Parser';

  dietParse(CompilationUnitElement compilationUnit, Token tokens) {
    measure(() {
      Function idGenerator = compiler.getNextFreeClassId;
      ScannerOptions scannerOptions = new ScannerOptions(
          canUseNative: compiler.backend.canLibraryUseNative(
              compilationUnit.library));
      ElementListener listener = new ElementListener(
          scannerOptions, compiler.reporter, compilationUnit, idGenerator);
      PartialParser parser = new PartialParser(
          listener, enableConditionalDirectives: _enableConditionalDirectives);
      try {
        parser.parseUnit(tokens);
      } on ParserError catch(_) {
        assert(invariant(compilationUnit, compiler.compilationFailed));
      }
    });
  }
}
