// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library string_scanner.exception;

import 'package:source_maps/source_maps.dart';

/// An exception thrown by a [StringScanner] that failed to parse a string.
class StringScannerException implements FormatException {
  /// The error message.
  final String message;

  /// The source string being parsed.
  final String string;

  /// The URL of the source file being parsed.
  ///
  /// This may be `null`, indicating that the source URL is unknown.
  final Uri sourceUrl;

  /// The span within [string] that caused the exception.
  final Span span;

  StringScannerException(this.message, this.string, this.sourceUrl, this.span);

  /// Returns a detailed description of this exception.
  ///
  /// If [useColors] is true, the section of the source that caused the
  /// exception will be colored using ANSI color codes. By default, it's colored
  /// red, but a different ANSI code may passed via [color].
  String toString({bool useColors: false, String color}) {
    return "Error on " + span.getLocationMessage(
        message, useColors: useColors, color: color);
  }
}

