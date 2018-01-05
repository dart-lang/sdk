// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.built_type_builder;

import 'package:kernel/ast.dart' show DartType, Supertype;

import '../kernel/kernel_builder.dart' show KernelTypeBuilder, LibraryBuilder;

import '../problems.dart' show unimplemented;

class BuiltTypeBuilder extends KernelTypeBuilder {
  final DartType builtType;

  BuiltTypeBuilder(this.builtType);

  DartType build(LibraryBuilder library) => builtType;

  Supertype buildSupertype(
      LibraryBuilder library, int charOffset, Uri fileUri) {
    return unimplemented("buildSupertype", -1, null);
  }

  buildInvalidType(int charOffset, Uri fileUri) {
    return unimplemented("buildInvalidType", -1, null);
  }

  String get debugName => "BuiltTypeBuilder";

  StringBuffer printOn(StringBuffer buffer) {
    return buffer..write(builtType.toString());
  }

  String get name {
    return unimplemented("name", -1, null);
  }
}
