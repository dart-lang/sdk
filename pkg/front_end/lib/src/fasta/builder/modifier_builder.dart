// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.modifier_builder;

import '../modifier.dart'
    show
        abstractMask,
        constMask,
        externalMask,
        finalMask,
        namedMixinApplicationMask,
        staticMask;

import 'builder.dart' show Builder;

abstract class ModifierBuilder extends Builder {
  final int charOffset;

  ModifierBuilder(Builder parent, this.charOffset, [Uri fileUri])
      : super(parent, charOffset, fileUri ?? parent?.fileUri);

  int get modifiers;

  bool get isAbstract => (modifiers & abstractMask) != 0;

  bool get isConst => (modifiers & constMask) != 0;

  bool get isExternal => (modifiers & externalMask) != 0;

  bool get isFinal => (modifiers & finalMask) != 0;

  bool get isStatic => (modifiers & staticMask) != 0;

  bool get isNamedMixinApplication {
    return (modifiers & namedMixinApplicationMask) != 0;
  }

  bool get isClassMember => false;

  String get name;

  bool get isNative => false;

  String get debugName;

  StringBuffer printOn(StringBuffer buffer) {
    return buffer..write(name ?? fullNameForErrors);
  }

  String toString() => "$debugName(${printOn(new StringBuffer())})";
}
