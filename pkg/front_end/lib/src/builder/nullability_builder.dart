// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

/// Represents the nullability modifiers encountered while parsing the types.
///
/// The syntactic nullability needs to be interpreted, that is, built, into the
/// semantic nullability used on [DartType]s of Kernel.
enum SyntacticNullability {
  /// Used when the type is declared with '?' suffix after it.
  nullable,

  /// Used when the type is declared without any nullability suffixes.
  omitted,

  /// Used when the type is nullable without any nullability suffix.
  inherent,
}

class NullabilityBuilder {
  final SyntacticNullability _syntacticNullability;

  const NullabilityBuilder.nullable()
    : _syntacticNullability = SyntacticNullability.nullable;

  const NullabilityBuilder.omitted()
    : _syntacticNullability = SyntacticNullability.omitted;

  const NullabilityBuilder.inherent()
    : _syntacticNullability = SyntacticNullability.inherent;

  bool get isOmitted => _syntacticNullability == SyntacticNullability.omitted;

  bool get isNullable => _syntacticNullability == SyntacticNullability.nullable;

  factory NullabilityBuilder.fromNullability(Nullability nullability) {
    switch (nullability) {
      case Nullability.nullable:
        return const NullabilityBuilder.nullable();
      case Nullability.nonNullable:
      case Nullability.undetermined:
        return const NullabilityBuilder.omitted();
    }
  }

  Nullability build() {
    switch (_syntacticNullability) {
      case SyntacticNullability.nullable:
        return Nullability.nullable;
      case SyntacticNullability.inherent:
        return Nullability.nullable;
      case SyntacticNullability.omitted:
        return Nullability.nonNullable;
    }
  }

  void writeNullabilityOn(StringBuffer sb) {
    switch (_syntacticNullability) {
      case SyntacticNullability.nullable:
        sb.write("?");
        return;
      case SyntacticNullability.omitted:
      case SyntacticNullability.inherent:
        // Do nothing.
        return;
    }
  }

  @override
  String toString() {
    StringBuffer buffer = new StringBuffer();
    writeNullabilityOn(buffer);
    return "$buffer";
  }
}
