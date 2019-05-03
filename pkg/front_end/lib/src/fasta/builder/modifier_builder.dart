// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.modifier_builder;

import '../modifier.dart'
    show
        abstractMask,
        constMask,
        covariantMask,
        externalMask,
        finalMask,
        hasConstConstructorMask,
        hasInitializerMask,
        initializingFormalMask,
        namedMixinApplicationMask,
        staticMask;

import 'builder.dart' show Declaration;

abstract class ModifierBuilder extends Declaration {
  Declaration parent;

  final int charOffset;

  final Uri fileUri;

  ModifierBuilder(this.parent, this.charOffset, [Uri fileUri])
      : fileUri = fileUri ?? parent?.fileUri;

  int get modifiers;

  bool get isAbstract => (modifiers & abstractMask) != 0;

  bool get isConst => (modifiers & constMask) != 0;

  bool get isCovariant => (modifiers & covariantMask) != 0;

  bool get isExternal => (modifiers & externalMask) != 0;

  bool get isFinal => (modifiers & finalMask) != 0;

  bool get isStatic => (modifiers & staticMask) != 0;

  bool get isNamedMixinApplication {
    return (modifiers & namedMixinApplicationMask) != 0;
  }

  bool get hasInitializer => (modifiers & hasInitializerMask) != 0;

  bool get isInitializingFormal => (modifiers & initializingFormalMask) != 0;

  bool get hasConstConstructor => (modifiers & hasConstConstructorMask) != 0;

  bool get isClassMember => false;

  String get name;

  bool get isNative => false;

  String get debugName;

  StringBuffer printOn(StringBuffer buffer) {
    return buffer..write(name ?? fullNameForErrors);
  }

  String toString() => "$debugName(${printOn(new StringBuffer())})";
}
