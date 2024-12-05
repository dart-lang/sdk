// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.modifier_builder;

import '../base/modifier.dart';
import 'builder.dart';

abstract class ModifierBuilderImpl extends BuilderImpl {
  int get modifiers;

  String? get name;

  String get debugName;

  ModifierBuilderImpl();

  @override
  bool get isConst => (modifiers & constMask) != 0;

  @override
  bool get isFinal => (modifiers & finalMask) != 0;

  @override
  bool get isStatic => (modifiers & staticMask) != 0;

  @override
  bool get isAugment => (modifiers & augmentMask) != 0;

  // Coverage-ignore(suite): Not run.
  StringBuffer printOn(StringBuffer buffer) {
    return buffer..write(name);
  }

  @override
  String toString() => "${isAugmenting ? 'augmentation ' : ''}"
      "$debugName(${printOn(new StringBuffer())})";
}
