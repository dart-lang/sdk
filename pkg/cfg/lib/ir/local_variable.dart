// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ast show Variable;
import 'package:cfg/ir/types.dart';

/// Local variable or a function parameter.
///
/// Local variables are used in the flow graph before
/// it is converted to SSA form.
class LocalVariable {
  static const String exceptionVariableName = '#exception';
  static const String stackTraceVariableName = '#stackTrace';

  /// Name of the variable.
  final String name;

  /// Declaration of the variable in the AST, if any.
  final ast.Variable? declaration;

  /// Index of the variable in the [FlowGraph.localVariables].
  final int index;

  /// Type of the variable.
  final CType type;

  LocalVariable(this.name, this.declaration, this.index, this.type);

  bool get isExceptionVariable =>
      declaration == null && name == exceptionVariableName;
  bool get isStackTraceVariable =>
      declaration == null && name == stackTraceVariableName;

  @override
  String toString() => name;
}
