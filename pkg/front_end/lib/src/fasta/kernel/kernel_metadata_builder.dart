// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_metadata_builder;

import 'kernel_builder.dart' show MetadataBuilder;

import '../scanner.dart' show Token;

class KernelMetadataBuilder extends MetadataBuilder {
  final int charOffset;

  KernelMetadataBuilder(Token beginToken) : charOffset = beginToken.charOffset;
}
