// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Defines the API for the front end to communicate information about
/// compilation errors to clients.
library front_end.compilation_error;

import 'package:source_span/source_span.dart' show SourceSpan;

/// A single error that occurred during compilation, and information about where
/// it occurred and how to fix it.
///
/// TODO(paulberry): add a reference to the analyzer error code.
///
/// Not intended to be implemented or extended by clients.
// TODO(sigmund): rename to CompliationMessage
abstract class CompilationError {
  /// A text description of the compile error.
  String get message;

  /// A suggestion for the user to hint them on how to fix the error. May be
  /// `null`.
  String get tip;

  /// The source span where the error occurred.
  SourceSpan get span;
}
