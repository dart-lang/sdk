// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.compiler_diagnostics_facade;

import '../../compiler_api.dart' as api show Diagnostic;
import '../elements/entities.dart' show Entity;
import '../options.dart' show CompilerOptions;

import 'diagnostic_listener.dart' show DiagnosticMessage;
import 'source_span.dart';
import 'spannable.dart';

/// This interface is a subset of the [Compiler] methods that are needed by
/// [DiagnosticListener].
///
/// See definitions on [Compiler] for documentation.
// TODO(48820): Remove after compiler.dart is migrated.
abstract class CompilerDiagnosticsFacade {
  CompilerOptions get options;

  bool inUserCode(Entity element);

  Uri getCanonicalUri(Entity element);

  void reportDiagnostic(DiagnosticMessage message,
      List<DiagnosticMessage> infos, api.Diagnostic kind);

  void fatalDiagnosticReported(DiagnosticMessage message,
      List<DiagnosticMessage> infos, api.Diagnostic kind);

  bool get compilationFailed;

  SourceSpan spanFromSpannable(Spannable spannable, Entity? currentElement);
}
