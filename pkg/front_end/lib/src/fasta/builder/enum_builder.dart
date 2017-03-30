// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.enum_builder;

import 'builder.dart' show ClassBuilder, TypeBuilder;

abstract class EnumBuilder<T extends TypeBuilder, R>
    implements ClassBuilder<T, R> {
  List<Object> get constantNamesAndOffsets;
}
