// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.parser.diet.task;

import '../common.dart';
import '../common/tasks.dart' show CompilerTask, Measurer;
import '../elements/elements.dart' show CompilationUnitElement;
import '../js_backend/backend.dart' show JavaScriptBackend;
import '../id_generator.dart';
import 'package:front_end/src/fasta/scanner.dart' show Token;
import 'element_listener.dart' show ElementListener, ScannerOptions;
import 'package:front_end/src/fasta/parser.dart'
    show Listener, MemberKind, ParserError, TopLevelParser;

class PartialParser extends TopLevelParser {
  PartialParser(Listener listener) : super(listener);

  Token parseFormalParameters(Token token, MemberKind kind) {
    return skipFormalParameters(token, kind);
  }
}

class DietParserTask extends CompilerTask {
  final IdGenerator _idGenerator;
  final JavaScriptBackend _backend;
  final DiagnosticReporter _reporter;

  DietParserTask(
      this._idGenerator, this._backend, this._reporter, Measurer measurer)
      : super(measurer);

  final String name = 'Diet Parser';

  dietParse(CompilationUnitElement compilationUnit, Token tokens) {
    measure(() {
      ScannerOptions scannerOptions = new ScannerOptions(
          canUseNative: _backend.canLibraryUseNative(compilationUnit.library));
      ElementListener listener = new ElementListener(
          scannerOptions, _reporter, compilationUnit, _idGenerator);
      PartialParser parser = new PartialParser(listener);
      try {
        parser.parseUnit(tokens);
      } on ParserError catch (_) {
        // TODO(johnniwinther): assert that the error was reported once there is
        // a [hasErrorBeenReported] field in [DiagnosticReporter]
        // The error should have already been reported by the parser.
      }
    });
  }
}
