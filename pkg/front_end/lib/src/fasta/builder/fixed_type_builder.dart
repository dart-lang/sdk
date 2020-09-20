// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' hide MapEntry;

import '../problems.dart';
import 'library_builder.dart';
import 'nullability_builder.dart';
import 'type_builder.dart';

class FixedTypeBuilder extends TypeBuilder {
  final DartType type;
  final Uri fileUri;
  final int charOffset;

  const FixedTypeBuilder(this.type, this.fileUri, this.charOffset);

  TypeBuilder clone(List<TypeBuilder> newTypes) => this;

  Object get name => null;

  NullabilityBuilder get nullabilityBuilder =>
      new NullabilityBuilder.fromNullability(type.nullability);

  String get debugName => 'FixedTypeBuilder';

  bool get isVoidType => type is VoidType;

  StringBuffer printOn(StringBuffer buffer) {
    buffer.write('type=${type}');
    return buffer;
  }

  DartType build(LibraryBuilder library,
      [TypedefType origin, bool notInstanceContext]) {
    return type;
  }

  Supertype buildSupertype(
      LibraryBuilder library, int charOffset, Uri fileUri) {
    return unhandled('buildSupertype', 'FixedTypeBuilder', charOffset, fileUri);
  }

  Supertype buildMixedInType(
      LibraryBuilder library, int charOffset, Uri fileUri) {
    return unhandled(
        'buildMixedInType', 'FixedTypeBuilder', charOffset, fileUri);
  }

  TypeBuilder withNullabilityBuilder(NullabilityBuilder nullabilityBuilder) =>
      this;
}
