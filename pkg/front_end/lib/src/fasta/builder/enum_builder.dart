// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.enum_builder;

import 'builder.dart' show ClassBuilder, MetadataBuilder, TypeBuilder;

abstract class EnumBuilder<T extends TypeBuilder, R>
    implements ClassBuilder<T, R> {
  List<EnumConstantInfo> get enumConstantInfos;
}

class EnumConstantInfo {
  final List<MetadataBuilder<TypeBuilder>> metadata;
  final String name;
  final int charOffset;
  final String documentationComment;
  const EnumConstantInfo(
      this.metadata, this.name, this.charOffset, this.documentationComment);
}
