// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/line_info.dart';

/// The analysis errors and line info associated with a source.
class AnalysisErrorInfo {
  /// The analysis errors associated with a source, or `null` if there are no
  /// errors.
  final List<AnalysisError> errors;

  /// The line information associated with the errors, or `null` if there are no
  /// errors.
  final LineInfo lineInfo;

  AnalysisErrorInfo(this.errors, this.lineInfo);
}
