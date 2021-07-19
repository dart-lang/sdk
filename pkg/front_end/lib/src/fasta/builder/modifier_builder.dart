// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.modifier_builder;

import '../modifier.dart';

import 'builder.dart';

abstract class ModifierBuilder implements Builder {
  String? get name;

  bool get isNative;
}

abstract class ModifierBuilderImpl extends BuilderImpl
    implements ModifierBuilder {
  int get modifiers;

  String get debugName;

  @override
  Builder? parent;

  @override
  final int charOffset;

  ModifierBuilderImpl(Builder? parent, this.charOffset) : this.parent = parent;

  @override
  bool get isConst => (modifiers & constMask) != 0;

  @override
  bool get isFinal => (modifiers & finalMask) != 0;

  @override
  bool get isStatic => (modifiers & staticMask) != 0;

  @override
  bool get isNative => false;

  StringBuffer printOn(StringBuffer buffer) {
    return buffer..write(name);
  }

  @override
  String toString() =>
      "${isPatch ? 'patch ' : ''}$debugName(${printOn(new StringBuffer())})";
}
