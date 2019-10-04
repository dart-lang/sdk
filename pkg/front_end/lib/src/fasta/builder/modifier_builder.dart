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

import 'declaration.dart';

abstract class ModifierBuilder implements Builder {
  int get modifiers;

  bool get isAbstract;

  bool get isCovariant;

  bool get isExternal;

  bool get isLate;

  // TODO(johnniwinther): Add this when semantics for
  // `FormalParameterBuilder.isRequired` has been updated to support required
  // named parameters.
  //bool get isRequired;

  bool get hasInitializer;

  bool get isInitializingFormal;

  bool get hasConstConstructor;

  bool get isMixin;

  String get name;

  bool get isNative;

  String get debugName;

  StringBuffer printOn(StringBuffer buffer);
}

abstract class ModifierBuilderImpl extends BuilderImpl
    implements ModifierBuilder {
  @override
  Builder parent;

  @override
  final int charOffset;

  @override
  final Uri fileUri;

  ModifierBuilderImpl(this.parent, this.charOffset, [Uri fileUri])
      : fileUri = fileUri ?? parent?.fileUri;

  @override
  bool get isAbstract => (modifiers & abstractMask) != 0;

  @override
  bool get isConst => (modifiers & constMask) != 0;

  @override
  bool get isCovariant => (modifiers & covariantMask) != 0;

  @override
  bool get isExternal => (modifiers & externalMask) != 0;

  @override
  bool get isFinal => (modifiers & finalMask) != 0;

  @override
  bool get isStatic => (modifiers & staticMask) != 0;

  @override
  bool get isLate => (modifiers & lateMask) != 0;

  // TODO(johnniwinther): Add this when semantics for
  // `FormalParameterBuilder.isRequired` has been updated to support required
  // named parameters.
  //bool get isRequired => (modifiers & requiredMask) != 0;

  @override
  bool get isNamedMixinApplication {
    return (modifiers & namedMixinApplicationMask) != 0;
  }

  @override
  bool get hasInitializer => (modifiers & hasInitializerMask) != 0;

  @override
  bool get isInitializingFormal => (modifiers & initializingFormalMask) != 0;

  @override
  bool get hasConstConstructor => (modifiers & hasConstConstructorMask) != 0;

  @override
  bool get isMixin => (modifiers & mixinDeclarationMask) != 0;

  @override
  bool get isNative => false;

  @override
  StringBuffer printOn(StringBuffer buffer) {
    return buffer..write(name ?? fullNameForErrors);
  }

  @override
  String toString() =>
      "${isPatch ? 'patch ' : ''}$debugName(${printOn(new StringBuffer())})";
}
