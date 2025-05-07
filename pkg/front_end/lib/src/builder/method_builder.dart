// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

import 'member_builder.dart';

abstract class MethodBuilder implements MemberBuilder {
  bool get isAbstract;

  /// Returns `true` if this method is an operator method.
  bool get isOperator;

  @override
  Reference get invokeTargetReference;
}

/// Helper extension with helpers that are derived from other properties of
/// a [MethodBuilder].
extension MethodBuilderExtension on MethodBuilder {
  /// Return `true` if this method is a regular method, i.e. _not_ an operator
  /// method.
  bool get isRegularMethod => !isOperator;
}
