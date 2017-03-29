// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.invalid_type_builder;

import 'builder.dart' show TypeBuilder, TypeDeclarationBuilder;

abstract class InvalidTypeBuilder<T extends TypeBuilder, R>
    extends TypeDeclarationBuilder<T, R> {
  InvalidTypeBuilder(String name, int charOffset, [Uri fileUri])
      : super(null, 0, name, null, charOffset, fileUri);
}
