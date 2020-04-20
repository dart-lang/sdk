// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:meta/meta.dart';

/// A concrete implementation of a diagnostic message.
class DiagnosticMessageImpl implements DiagnosticMessage {
  @override
  final String filePath;

  @override
  final int length;

  @override
  final String message;

  @override
  final int offset;

  /// Initialize a newly created message to represent a [message] reported in
  /// the file at the given [filePath] at the given [offset] and with the given
  /// [length].
  DiagnosticMessageImpl(
      {@required this.filePath,
      @required this.length,
      @required this.message,
      @required this.offset});
}
