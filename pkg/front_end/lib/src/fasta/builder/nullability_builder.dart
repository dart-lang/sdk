// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core' hide MapEntry;

import 'package:kernel/ast.dart';

import '../kernel/body_builder.dart';
import '../problems.dart';

import 'library_builder.dart';

/// Represents the nullability modifiers encountered while parsing the types.
///
/// The syntactic nullability needs to be interpreted, that is, built, into the
/// semantic nullability used on [DartType]s of Kernel.
enum SyntacticNullability {
  /// Used when the type is declared with '?' suffix after it.
  nullable,

  /// Used when the type is declared in an opted-out library.
  legacy,

  /// Used when the type is declared without any nullability suffixes.
  omitted,
}

class NullabilityBuilder {
  final SyntacticNullability _syntacticNullability;

  const NullabilityBuilder.nullable()
      : _syntacticNullability = SyntacticNullability.nullable;

  const NullabilityBuilder.omitted()
      : _syntacticNullability = SyntacticNullability.omitted;

  bool get isOmitted => _syntacticNullability == SyntacticNullability.omitted;

  factory NullabilityBuilder.fromNullability(Nullability nullability) {
    switch (nullability) {
      case Nullability.nullable:
        return const NullabilityBuilder.nullable();
      case Nullability.legacy:
      case Nullability.nonNullable:
      case Nullability.undetermined:
      default:
        return const NullabilityBuilder.omitted();
    }
  }

  Nullability build(LibraryBuilder libraryBuilder) {
    assert(libraryBuilder != null);

    Nullability ifOmitted = libraryBuilder.isNonNullableByDefault
        ? Nullability.nonNullable
        : Nullability.legacy;
    switch (_syntacticNullability) {
      case SyntacticNullability.legacy:
        return Nullability.legacy;
      case SyntacticNullability.nullable:
        return Nullability.nullable;
      case SyntacticNullability.omitted:
        return ifOmitted;
    }
    return unhandled(
        "$_syntacticNullability", "buildNullability", noLocation, null);
  }

  void writeNullabilityOn(StringBuffer sb) {
    switch (_syntacticNullability) {
      case SyntacticNullability.legacy:
        sb.write("*");
        return;
      case SyntacticNullability.nullable:
        sb.write("?");
        return;
      case SyntacticNullability.omitted:
        // Do nothing.
        return;
    }
    unhandled("$_syntacticNullability", "writeNullabilityOn", noLocation, null);
  }

  String toString() {
    StringBuffer buffer = new StringBuffer();
    writeNullabilityOn(buffer);
    return "$buffer";
  }
}
