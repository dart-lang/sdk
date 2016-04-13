// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.parser.diet.task;

import '../common.dart';
import '../common/tasks.dart' show CompilerTask;
import '../compiler.dart' show Compiler;
import '../elements/elements.dart' show CompilationUnitElement;
import '../id_generator.dart';
import '../tokens/token.dart' show Token;

import 'listener.dart' show ParserError;
import 'element_listener.dart' show ElementListener, ScannerOptions;
import '../options.dart' show ParserOptions;
import 'partial_parser.dart' show PartialParser;

class DietParserTask extends CompilerTask {
  final ParserOptions _parserOptions;
  final IdGenerator _idGenerator;

  DietParserTask(Compiler compiler, this._parserOptions, this._idGenerator)
      : super(compiler);

  final String name = 'Diet Parser';

  dietParse(CompilationUnitElement compilationUnit, Token tokens) {
    measure(() {
      ScannerOptions scannerOptions =
          new ScannerOptions.from(compiler, compilationUnit.library);
      ElementListener listener = new ElementListener(
          scannerOptions, compiler.reporter, compilationUnit, _idGenerator);
      PartialParser parser = new PartialParser(listener, _parserOptions);
      try {
        parser.parseUnit(tokens);
      } on ParserError catch (_) {
        assert(invariant(compilationUnit, compiler.compilationFailed));
      }
    });
  }
}
