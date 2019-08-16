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
        lateMask,
        mixinDeclarationMask,
        namedMixinApplicationMask,
        staticMask;

import 'builder.dart' show Builder;

abstract class ModifierBuilder extends Builder {
  Builder parent;

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

  bool get isLate => (modifiers & lateMask) != 0;

  // TODO(johnniwinther): Add this when semantics for
  // `FormalParameterBuilder.isRequired` has been updated to support required
  // named parameters.
  //bool get isRequired => (modifiers & requiredMask) != 0;

  bool get isNamedMixinApplication {
    return (modifiers & namedMixinApplicationMask) != 0;
  }

  bool get hasInitializer => (modifiers & hasInitializerMask) != 0;

  bool get isInitializingFormal => (modifiers & initializingFormalMask) != 0;

  bool get hasConstConstructor => (modifiers & hasConstConstructorMask) != 0;

  bool get isMixin => (modifiers & mixinDeclarationMask) != 0;

  String get name;

  bool get isNative => false;

  String get debugName;

  StringBuffer printOn(StringBuffer buffer) {
    return buffer..write(name ?? fullNameForErrors);
  }

  String toString() => "$debugName(${printOn(new StringBuffer())})";
}
