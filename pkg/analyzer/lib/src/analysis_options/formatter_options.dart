// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_options.dart';
import 'package:analyzer/dart/analysis/formatter_options.dart';

/// The concrete implementation of [FormatterOptions].
class FormatterOptionsImpl implements FormatterOptions {
  /// The analysis options that owns this instance.
  final AnalysisOptions options;

  /// The width configured for where the formatter should wrap code.
  @override
  final int? pageWidth;

  FormatterOptionsImpl(this.options, {this.pageWidth});
}
