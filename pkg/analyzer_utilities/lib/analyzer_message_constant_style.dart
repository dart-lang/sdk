// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Encapsulates information about how to generate an analyzer diagnostic
/// message constant, including the style of constant to generate (e.g. with
/// arguments or without) and the classes that should be referenced by the
/// generated code.
sealed class ConstantStyle {
  /// The concrete class name that should be used to construct the constant.
  final String concreteClassName;

  /// The static type of the constant that should be generated.
  final String staticType;

  ConstantStyle({required this.concreteClassName, required this.staticType});
}

/// [ConstantStyle] object indicating that an "old style" constant should be
/// generated (one that does not support the new analyzer literate API for
/// constants).
// TODO(paulberry): finish supporting the literate API in all analyzer messages
// and eliminate this.
class OldConstantStyle extends ConstantStyle {
  OldConstantStyle({
    required super.concreteClassName,
    required super.staticType,
  });
}

/// [ConstantStyle] object indicating that a constant should be generated that
/// supports a `.withArguments` getter.
class WithArgumentsConstantStyle extends ConstantStyle {
  /// The parameters that should be accepted by the `.withArguments` getter.
  final String withArgumentsParams;

  WithArgumentsConstantStyle({
    required super.concreteClassName,
    required super.staticType,
    required this.withArgumentsParams,
  });
}

/// [ConstantStyle] object indicating that a constant should be generated that
/// doesn't require any arguments.
class WithoutArgumentsConstantStyle extends ConstantStyle {
  WithoutArgumentsConstantStyle({
    required super.concreteClassName,
    required super.staticType,
  });
}
