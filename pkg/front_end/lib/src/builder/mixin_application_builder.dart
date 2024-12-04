// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'declaration_builders.dart';
import 'type_builder.dart';

class MixinApplicationBuilder {
  final List<TypeBuilder> mixins;
  final Uri fileUri;
  final int charOffset;

  List<NominalParameterBuilder>? typeParameters;

  MixinApplicationBuilder(this.mixins, this.fileUri, this.charOffset);
}
