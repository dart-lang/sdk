// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.dynamic_type_builder;

import 'builder.dart' show LibraryBuilder, TypeBuilder, BuiltinTypeBuilder;

class DynamicTypeBuilder<T extends TypeBuilder, R>
    extends BuiltinTypeBuilder<T, R> {
  DynamicTypeBuilder(R type, LibraryBuilder compilationUnit, int charOffset)
      : super("dynamic", type, compilationUnit, charOffset);

  String get debugName => "DynamicTypeBuilder";
}
