// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer_testing/utilities/extensions/string.dart';

extension DiagnosticCodeExtension on DiagnosticCode {
  /// The name of the constant in the analyzer package (or other related
  /// package) that represents this diagnostic code.
  ///
  /// This string is used when generating test failure messages that suggest how
  /// to change test expectations to match the current behavior.
  ///
  /// For example, if the unique name is `TestClass.MY_ERROR`, this method will
  /// return `diag.myError`.
  String get constantName => 'diag.${lowerCaseUniqueName.toCamelCase()}';
}
