// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.dynamic_type_builder;

import 'builder.dart' show
    TypeBuilder,
    TypeDeclarationBuilder;

// TODO(ahe): Make const class.
class DynamicTypeBuilder<T extends TypeBuilder, R>
    extends TypeDeclarationBuilder<T, R> {
  final R type;

  DynamicTypeBuilder(this.type)
      : super (null, 0, "dynamic", null, null);

  R buildType(List<T> arguments) => type;

  R buildTypesWithBuiltArguments(List<R> arguments) => type;
}
