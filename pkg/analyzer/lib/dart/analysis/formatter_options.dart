// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A set of options related to the formatter that apply to the code within a
/// single analysis context.
final class FormatterOptions {
  /// The width configured for where the formatter should wrap code.
  final int? pageWidth;

  /// How trailing commas in various constructs should affect formatting.
  final TrailingCommas? trailingCommas;

  FormatterOptions({this.pageWidth, this.trailingCommas});
}

/// How trailing commas in various constructs should affect formatting.
enum TrailingCommas { automate, preserve }
