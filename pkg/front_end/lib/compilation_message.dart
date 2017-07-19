// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Defines the API for the front end to communicate information about
/// compilation messages to clients.
library front_end.compilation_message;

import 'package:source_span/source_span.dart' show SourceSpan;

import 'package:front_end/src/fasta/severity.dart' show Severity;
export 'package:front_end/src/fasta/severity.dart' show Severity;

/// A single message, typically an error, reported during compilation, and
/// information about where it occurred and suggestions on how to fix it.
///
/// Not intended to be implemented or extended by clients.
abstract class CompilationMessage {
  /// A text description of the problem.
  String get message;

  /// A suggestion for how to fix the problem. May be `null`.
  String get tip;

  /// The source span where the error occurred.
  SourceSpan get span;

  /// The severity level of the error.
  Severity get severity;

  /// The corresponding analyzer error code, or null if there is no
  /// corresponding message in analyzer.
  String get analyzerCode;

  /// The corresponding dart2js error code, or null if there is no corresponding
  /// message in dart2js.
  String get dart2jsCode;
}
