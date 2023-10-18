// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.modifier;

import 'problems.dart' show unhandled;

enum ModifierEnum {
  Abstract,
  Augment,
  Const,
  Covariant,
  External,
  Final,
  Static,

  // Not a real modifier.
  Var,
}

const int abstractMask = 1;

const int augmentMask = abstractMask << 1;

const int constMask = augmentMask << 1;

const int covariantMask = constMask << 1;

const int externalMask = covariantMask << 1;

const int finalMask = externalMask << 1;

const int staticMask = finalMask << 1;

const int lateMask = staticMask << 1;

const int requiredMask = lateMask << 1;

const int namedMixinApplicationMask = requiredMask << 1;

/// Not a modifier, used for mixins declared explicitly by using the `mixin`
/// keyword.
const int mixinDeclarationMask = namedMixinApplicationMask << 1;

/// Not a modifier, used by fields to track if they have an initializer.
const int hasInitializerMask = mixinDeclarationMask << 1;

/// Not a modifier, used by formal parameters to track if they are initializing.
const int initializingFormalMask = hasInitializerMask << 1;

/// Not a modifier, used by classes to track if the class declares a const
/// constructor.
const int declaresConstConstructorMask = initializingFormalMask << 1;

/// Not a modifier, used by formal parameters to track if they are
/// super-parameter initializers.
const int superInitializingFormalMask = declaresConstConstructorMask << 1;

/// Not a real modifier, and by setting it to zero, it is automatically ignored
/// by [Modifier.toMask] below.
const int varMask = 0;

const Modifier Abstract = const Modifier(ModifierEnum.Abstract, abstractMask);

const Modifier Augment = const Modifier(ModifierEnum.Augment, augmentMask);

const Modifier Const = const Modifier(ModifierEnum.Const, constMask);

const Modifier Covariant =
    const Modifier(ModifierEnum.Covariant, covariantMask);

const Modifier External = const Modifier(ModifierEnum.External, externalMask);

const Modifier Final = const Modifier(ModifierEnum.Final, finalMask);

const Modifier Static = const Modifier(ModifierEnum.Static, staticMask);

/// Not a real modifier.
const Modifier Var = const Modifier(ModifierEnum.Var, varMask);

class Modifier {
  final ModifierEnum kind;

  final int mask;

  const Modifier(this.kind, this.mask);

  factory Modifier.fromString(String string) {
    if (identical('abstract', string)) return Abstract;
    if (identical('augment', string)) return Augment;
    if (identical('const', string)) return Const;
    if (identical('covariant', string)) return Covariant;
    if (identical('external', string)) return External;
    if (identical('final', string)) return Final;
    if (identical('static', string)) return Static;
    if (identical('var', string)) return Var;
    return unhandled(string, "Modifier.fromString", -1, null);
  }

  @override
  String toString() => "modifier(${'$kind'.substring('ModifierEnum.'.length)})";

  static int toMask(List<Modifier>? modifiers) {
    int result = 0;
    if (modifiers == null) return result;
    for (Modifier modifier in modifiers) {
      result |= modifier.mask;
    }
    return result;
  }

  static int validateVarFinalOrConst(String? lexeme) {
    if (lexeme == null) return 0;
    if (identical('const', lexeme)) return Const.mask;
    if (identical('final', lexeme)) return Final.mask;
    if (identical('var', lexeme)) return Var.mask;
    return unhandled(lexeme, "Modifier.validateVarFinalOrConst", -1, null);
  }

  /// Returns [modifier] with [abstractMask] added if [isAbstract] and
  /// [modifiers] doesn't contain [externalMask].
  static int addAbstractMask(int modifiers, {bool isAbstract = false}) {
    if (isAbstract && (modifiers & externalMask) == 0) {
      modifiers |= abstractMask;
    }
    return modifiers;
  }

  /// Returns `true` if the modifier mask contains modifier bits
  ///
  /// Some of the bits stored in modified masks don't represent actual
  /// modifiers, as noted in their comments (see [mixinDeclarationMask],
  /// [hasInitializerMask], [initializingFormalMask],
  /// [declaresConstConstructorMask], [superInitializingFormalMask], [varMask]).
  /// Method [maskContainsActualModifiers] returns `true` if the mask has any of
  /// the actual modifier bits set, and `false` otherwise.
  static bool maskContainsActualModifiers(int mask) {
    mask &= ~(1 << mixinDeclarationMask);
    mask &= ~(1 << hasInitializerMask);
    mask &= ~(1 << initializingFormalMask);
    mask &= ~(1 << declaresConstConstructorMask);
    mask &= ~(1 << superInitializingFormalMask);
    mask &= ~(1 << varMask);

    return mask != 0;
  }
}
