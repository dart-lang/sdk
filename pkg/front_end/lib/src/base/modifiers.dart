// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart'
    show
        Keyword,
        // ignore: unused_shown_name
        SimpleToken, // Used for DartDocTest.
        // ignore: unused_shown_name
        StringToken, // Used for DartDocTest.
        Token,
        // ignore: unused_shown_name
        TokenType; // Used for DartDocTest.

const int _abstractMask = 1;

const int _augmentMask = _abstractMask << 1;

const int _constMask = _augmentMask << 1;

const int _covariantMask = _constMask << 1;

const int _externalMask = _covariantMask << 1;

const int _finalMask = _externalMask << 1;

const int _staticMask = _finalMask << 1;

const int _lateMask = _staticMask << 1;

const int _requiredMask = _lateMask << 1;

const int _macroMask = _requiredMask << 1;

const int _sealedMask = _macroMask << 1;

const int _baseMask = _sealedMask << 1;

const int _interfaceMask = _baseMask << 1;

const int _mixinMask = _interfaceMask << 1;

const int _namedMixinApplicationMask = _mixinMask << 1;

/// Not a modifier, used by fields to track if they have an initializer.
const int _hasInitializerMask = _namedMixinApplicationMask << 1;

/// Not a modifier, used by formal parameters to track if they are initializing.
const int _initializingFormalMask = _hasInitializerMask << 1;

/// Not a modifier, used by classes to track if the class declares a const
/// constructor.
const int _declaresConstConstructorMask = _initializingFormalMask << 1;

/// Not a modifier, used by formal parameters to track if they are
/// super-parameter initializers.
const int _superInitializingFormalMask = _declaresConstConstructorMask << 1;

/// Extension type that encodes a set of modifiers as a bit mask.
extension type const Modifiers(int _mask) implements Object {
  /// The empty set of modifiers.
  static const Modifiers empty = const Modifiers(0);

  // Coverage-ignore(suite): Not run.
  /// Returns `true` if the set of modifiers is empty.
  bool get isEmpty => _mask == 0;

  /// Returns the [Modifiers] that is the union between the modifiers in this
  /// and [other].
  ///
  /// ```
  /// DartDocTest(Modifiers.empty | Modifiers.empty, Modifiers.empty)
  /// DartDocTest((Modifiers.Final | Modifiers.Covariant).isFinal, true)
  /// DartDocTest((Modifiers.Final | Modifiers.Covariant).isCovariant, true)
  /// ```
  Modifiers operator |(Modifiers other) {
    return new Modifiers(_mask | other._mask);
  }

  /// Returns the [Modifiers] that removes the modifiers in [other] from this
  /// set of modifiers.
  ///
  /// ```
  /// DartDocTest(Modifiers.Final - Modifiers.Final, Modifiers.empty)
  /// DartDocTest(Modifiers.Final - Modifiers.empty, Modifiers.Final)
  /// DartDocTest(Modifiers.Final - Modifiers.Const, Modifiers.Final)
  /// ``´
  Modifiers operator -(Modifiers other) {
    return new Modifiers(_mask & ~other._mask);
  }

  /// Creates a [Modifiers] using the provided [Token]s.
  ///
  /// ```
  /// DartDocTest(Modifiers.from().isEmpty, true)
  /// DartDocTest(Modifiers.from().isAbstract, false)
  /// DartDocTest(Modifiers.from().isAugment, false)
  ///
  /// DartDocTest(Modifiers.from(
  ///     abstractToken: new SimpleToken(Keyword.ABSTRACT, -1)),
  ///     Modifiers.Abstract)
  /// DartDocTest(Modifiers.from(
  ///     augmentToken: new SimpleToken(Keyword.AUGMENT, -1)),
  ///     Modifiers.Augment)
  /// DartDocTest(Modifiers.from(
  ///     baseToken: new SimpleToken(Keyword.BASE, -1)),
  ///     Modifiers.Base)
  /// DartDocTest(Modifiers.from(
  ///     covariantToken: new SimpleToken(Keyword.COVARIANT, -1)),
  ///     Modifiers.Covariant)
  /// DartDocTest(Modifiers.from(
  ///     constToken: new SimpleToken(Keyword.CONST, -1)),
  ///     Modifiers.Const)
  /// DartDocTest(Modifiers.from(
  ///     externalToken: new SimpleToken(Keyword.EXTERNAL, -1)),
  ///     Modifiers.External)
  /// DartDocTest(Modifiers.from(
  ///     finalToken: new SimpleToken(Keyword.FINAL, -1)),
  ///     Modifiers.Final)
  /// DartDocTest(Modifiers.from(
  ///     interfaceToken: new SimpleToken(Keyword.INTERFACE, -1)),
  ///     Modifiers.Interface)
  /// DartDocTest(Modifiers.from(
  ///     lateToken: new SimpleToken(Keyword.LATE, -1)),
  ///     Modifiers.Late)
  /// DartDocTest(Modifiers.from(
  ///     macroToken: new StringToken(TokenType.IDENTIFIER, 'macro', -1)),
  ///     Modifiers.Macro)
  /// DartDocTest(Modifiers.from(
  ///     mixinToken: new SimpleToken(Keyword.MIXIN, -1)),
  ///     Modifiers.Mixin)
  /// DartDocTest(Modifiers.from(
  ///     requiredToken: new SimpleToken(Keyword.REQUIRED, -1)),
  ///     Modifiers.Required)
  /// DartDocTest(Modifiers.from(
  ///     sealedToken: new SimpleToken(Keyword.SEALED, -1)),
  ///     Modifiers.Sealed)
  /// DartDocTest(Modifiers.from(
  ///     staticToken: new SimpleToken(Keyword.STATIC, -1)),
  ///     Modifiers.Static)
  ///
  /// DartDocTest(Modifiers.from(
  ///     varFinalOrConst: new SimpleToken(Keyword.VAR, -1)),
  ///     Modifiers.empty)
  /// DartDocTest(Modifiers.from(
  ///     varFinalOrConst: new SimpleToken(Keyword.FINAL, -1)),
  ///     Modifiers.Final)
  /// DartDocTest(Modifiers.from(
  ///     varFinalOrConst: new SimpleToken(Keyword.CONST, -1)),
  ///     Modifiers.Const)
  /// DartDocTestThrow(Modifiers.from(
  ///     varFinalOrConst: new SimpleToken(Keyword.STATIC, -1)))
  ///
  /// DartDocTest(Modifiers.from(
  ///     finalToken: new SimpleToken(Keyword.FINAL, -1),
  ///     staticToken: new SimpleToken(Keyword.STATIC, -1)),
  ///     Modifiers.Final | Modifiers.Static)
  /// ```
  static Modifiers from(
      {Token? abstractToken,
      Token? augmentToken,
      Token? baseToken,
      Token? covariantToken,
      Token? constToken,
      Token? externalToken,
      Token? finalToken,
      Token? interfaceToken,
      Token? lateToken,
      Token? macroToken,
      Token? mixinToken,
      Token? requiredToken,
      Token? sealedToken,
      Token? staticToken,
      Token? varFinalOrConst}) {
    assert(abstractToken == null || abstractToken.type == Keyword.ABSTRACT);
    assert(augmentToken == null || augmentToken.type == Keyword.AUGMENT);
    assert(baseToken == null || baseToken.type == Keyword.BASE);
    assert(covariantToken == null || covariantToken.type == Keyword.COVARIANT);
    assert(constToken == null || constToken.type == Keyword.CONST);
    assert(finalToken == null || finalToken.type == Keyword.FINAL);
    assert(interfaceToken == null || interfaceToken.type == Keyword.INTERFACE);
    assert(lateToken == null || lateToken.type == Keyword.LATE);
    assert(macroToken == null || macroToken.lexeme == 'macro');
    assert(mixinToken == null || mixinToken.type == Keyword.MIXIN);
    assert(requiredToken == null || requiredToken.type == Keyword.REQUIRED);
    assert(sealedToken == null || sealedToken.type == Keyword.SEALED);
    assert(staticToken == null || staticToken.type == Keyword.STATIC);

    int mask = (abstractToken != null ? _abstractMask : 0) |
        (augmentToken != null ? _augmentMask : 0) |
        (baseToken != null ? _baseMask : 0) |
        (covariantToken != null ? _covariantMask : 0) |
        (constToken != null ? _constMask : 0) |
        (externalToken != null ? _externalMask : 0) |
        (finalToken != null ? _finalMask : 0) |
        (interfaceToken != null ? _interfaceMask : 0) |
        (lateToken != null ? _lateMask : 0) |
        (macroToken != null ? _macroMask : 0) |
        (mixinToken != null ? _mixinMask : 0) |
        (requiredToken != null ? _requiredMask : 0) |
        (sealedToken != null ? _sealedMask : 0) |
        (staticToken != null ? _staticMask : 0);
    if (varFinalOrConst != null) {
      mask |= switch (varFinalOrConst.type) {
        Keyword.CONST => _constMask,
        Keyword.FINAL => _finalMask,
        Keyword.VAR => 0,
        // Coverage-ignore(suite): Not run.
        _ => // Coverage-ignore(suite): Not run.
          throw new UnsupportedError(
              "Unexpected varFinalOrConst token $varFinalOrConst."),
      };
    }
    return new Modifiers(mask);
  }

  /// The set of modifiers containing only `abstract`.
  ///
  /// ```
  /// DartDocTest(Modifiers.Abstract.isAbstract, true)
  /// DartDocTest(Modifiers.Abstract.isEmpty, false)
  /// DartDocTest(Modifiers.Abstract.isAugment, false)
  /// ```
  static const Modifiers Abstract = const Modifiers(_abstractMask);

  /// Returns `true` if the set of modifiers contains `abstract'.
  bool get isAbstract => (_mask & _abstractMask) != 0;

  /// The set of modifiers containing only `augment`.
  ///
  /// ```
  /// DartDocTest(Modifiers.Augment.isAugment, true)
  /// DartDocTest(Modifiers.Augment.isEmpty, false)
  /// DartDocTest(Modifiers.Augment.isConst, false)
  /// ```
  static const Modifiers Augment = const Modifiers(_augmentMask);

  /// Returns `true` if the set of modifiers contains `augment'.
  bool get isAugment => (_mask & _augmentMask) != 0;

  /// The set of modifiers containing only `const`.
  ///
  /// ```
  /// DartDocTest(Modifiers.Const.isConst, true)
  /// DartDocTest(Modifiers.Const.isEmpty, false)
  /// DartDocTest(Modifiers.Const.isCovariant, false)
  /// ```
  static const Modifiers Const = const Modifiers(_constMask);

  /// Returns `true` if the set of modifiers contains `const'.
  bool get isConst => (_mask & _constMask) != 0;

  /// The set of modifiers containing only `covariant`.
  ///
  /// ```
  /// DartDocTest(Modifiers.Covariant.isCovariant, true)
  /// DartDocTest(Modifiers.Covariant.isEmpty, false)
  /// DartDocTest(Modifiers.Covariant.isExternal, false)
  /// ```
  static const Modifiers Covariant = const Modifiers(_covariantMask);

  /// Returns `true` if the set of modifiers contains `covariant'.
  bool get isCovariant => (_mask & _covariantMask) != 0;

  /// The set of modifiers containing only `external`.
  ///
  /// ```
  /// DartDocTest(Modifiers.External.isExternal, true)
  /// DartDocTest(Modifiers.External.isEmpty, false)
  /// DartDocTest(Modifiers.External.isFinal, false)
  /// ```
  static const Modifiers External = const Modifiers(_externalMask);

  /// Returns `true` if the set of modifiers contains `external'.
  bool get isExternal => (_mask & _externalMask) != 0;

  /// The set of modifiers containing only `final`.
  ///
  /// ```
  /// DartDocTest(Modifiers.Final.isFinal, true)
  /// DartDocTest(Modifiers.Final.isEmpty, false)
  /// DartDocTest(Modifiers.Final.isStatic, false)
  /// ```
  static const Modifiers Final = const Modifiers(_finalMask);

  /// Returns `true` if the set of modifiers contains `final'.
  bool get isFinal => (_mask & _finalMask) != 0;

  /// The set of modifiers containing only `static`.
  ///
  /// ```
  /// DartDocTest(Modifiers.Static.isStatic, true)
  /// DartDocTest(Modifiers.Static.isEmpty, false)
  /// DartDocTest(Modifiers.Static.isLate, false)
  /// ```
  static const Modifiers Static = const Modifiers(_staticMask);

  /// Returns `true` if the set of modifiers contains `static'.
  bool get isStatic => (_mask & _staticMask) != 0;

  /// The set of modifiers containing only `late`.
  ///
  /// ```
  /// DartDocTest(Modifiers.Late.isLate, true)
  /// DartDocTest(Modifiers.Late.isEmpty, false)
  /// DartDocTest(Modifiers.Late.isRequired, false)
  /// ```
  static const Modifiers Late = const Modifiers(_lateMask);

  /// Returns `true` if the set of modifiers contains `late'.
  bool get isLate => (_mask & _lateMask) != 0;

  /// The set of modifiers containing only `required`.
  ///
  /// ```
  /// DartDocTest(Modifiers.Required.isRequired, true)
  /// DartDocTest(Modifiers.Required.isEmpty, false)
  /// DartDocTest(Modifiers.Required.isMacro, false)
  /// ```
  static const Modifiers Required = const Modifiers(_requiredMask);

  /// Returns `true` if the set of modifiers contains `required'.
  bool get isRequired => (_mask & _requiredMask) != 0;

  /// The set of modifiers containing only `macro`.
  ///
  /// ```
  /// DartDocTest(Modifiers.Macro.isMacro, true)
  /// DartDocTest(Modifiers.Macro.isEmpty, false)
  /// DartDocTest(Modifiers.Macro.isSealed, false)
  /// ```
  static const Modifiers Macro = const Modifiers(_macroMask);

  /// Returns `true` if the set of modifiers contains `macro'.
  bool get isMacro => (_mask & _macroMask) != 0;

  /// The set of modifiers containing only `sealed`.
  ///
  /// ```
  /// DartDocTest(Modifiers.Sealed.isSealed, true)
  /// DartDocTest(Modifiers.Sealed.isEmpty, false)
  /// DartDocTest(Modifiers.Sealed.isBase, false)
  /// ```
  static const Modifiers Sealed = const Modifiers(_sealedMask);

  /// Returns `true` if the set of modifiers contains `sealed'.
  bool get isSealed => (_mask & _sealedMask) != 0;

  /// The set of modifiers containing only `base`.
  ///
  /// ```
  /// DartDocTest(Modifiers.Base.isBase, true)
  /// DartDocTest(Modifiers.Base.isEmpty, false)
  /// DartDocTest(Modifiers.Base.isInterface, false)
  /// ```
  static const Modifiers Base = const Modifiers(_baseMask);

  /// Returns `true` if the set of modifiers contains `base'.
  bool get isBase => (_mask & _baseMask) != 0;

  /// The set of modifiers containing only `interface`.
  ///
  /// ```
  /// DartDocTest(Modifiers.Interface.isInterface, true)
  /// DartDocTest(Modifiers.Interface.isEmpty, false)
  /// DartDocTest(Modifiers.Interface.isMixin, false)
  /// ```
  static const Modifiers Interface = const Modifiers(_interfaceMask);

  /// Returns `true` if the set of modifiers contains `interface'.
  bool get isInterface => (_mask & _interfaceMask) != 0;

  /// The set of modifiers containing only `mixin`.
  ///
  /// ```
  /// DartDocTest(Modifiers.Mixin.isMixin, true)
  /// DartDocTest(Modifiers.Mixin.isEmpty, false)
  /// DartDocTest(Modifiers.Mixin.isNamedMixinApplication, false)
  /// ```
  static const Modifiers Mixin = const Modifiers(_mixinMask);

  /// Returns `true` if the set of modifiers contains `mixin'.
  bool get isMixin => (_mask & _mixinMask) != 0;

  /// The set of modifiers containing only the synthetic modifier used to denote
  /// that a class is a named mixin application.
  ///
  /// ```
  /// DartDocTest(Modifiers.NamedMixinApplication.isNamedMixinApplication, true)
  /// DartDocTest(Modifiers.NamedMixinApplication.isEmpty, false)
  /// DartDocTest(Modifiers.NamedMixinApplication.hasInitializer, false)
  /// ```
  static const Modifiers NamedMixinApplication =
      const Modifiers(_namedMixinApplicationMask);

  /// Returns `true` if the set of modifiers contains the synthetic modifier
  /// used to denote that a class is a named mixin application.
  bool get isNamedMixinApplication => (_mask & _namedMixinApplicationMask) != 0;

  /// The set of modifiers containing only the synthetic modifier used to denote
  /// that a field or variable has an explicit initializer.
  ///
  /// ```
  /// DartDocTest(Modifiers.HasInitializer.hasInitializer, true)
  /// DartDocTest(Modifiers.HasInitializer.isEmpty, false)
  /// DartDocTest(Modifiers.HasInitializer.isInitializingFormal, false)
  /// ```
  static const Modifiers HasInitializer = const Modifiers(_hasInitializerMask);

  /// Returns `true` if the set of modifiers contains the synthetic modifier
  /// used to denote that a field or variable has an explicit initializer.
  bool get hasInitializer => (_mask & _hasInitializerMask) != 0;

  /// The set of modifiers containing only the synthetic modifier used to denote
  /// that a parameter is an initializing formal.
  ///
  /// ```
  /// DartDocTest(Modifiers.InitializingFormal.isInitializingFormal, true)
  /// DartDocTest(Modifiers.InitializingFormal.isEmpty, false)
  /// DartDocTest(Modifiers.InitializingFormal.declaresConstConstructor, false)
  /// ```
  static const Modifiers InitializingFormal =
      const Modifiers(_initializingFormalMask);

  /// Returns `true` if the set of modifiers contains the synthetic modifier
  /// used to denote that a parameter is an initializing formal.
  bool get isInitializingFormal => (_mask & _initializingFormalMask) != 0;

  /// The set of modifiers containing only the synthetic modifier used to denote
  /// that a declaration declares a const constructor.
  ///
  /// ```
  /// DartDocTest(
  ///     Modifiers.DeclaresConstConstructor.declaresConstConstructor, true)
  /// DartDocTest(Modifiers.DeclaresConstConstructor.isEmpty, false)
  /// DartDocTest(
  ///     Modifiers.DeclaresConstConstructor.isSuperInitializingFormal, false)
  /// ```
  static const Modifiers DeclaresConstConstructor =
      const Modifiers(_declaresConstConstructorMask);

  /// Returns `true` if the set of modifiers contains the synthetic modifier
  /// used to denote that a declaration declares a const constructor.
  bool get declaresConstConstructor =>
      (_mask & _declaresConstConstructorMask) != 0;

  /// The set of modifiers containing only the synthetic modifier used to denote
  /// that a parameter is a super initializing formal.
  ///
  /// ```
  /// DartDocTest(
  ///     Modifiers.SuperInitializingFormal.isSuperInitializingFormal, true)
  /// DartDocTest(Modifiers.SuperInitializingFormal.isEmpty, false)
  /// DartDocTest(Modifiers.SuperInitializingFormal.isAbstract, false)
  /// ```
  static const Modifiers SuperInitializingFormal =
      const Modifiers(_superInitializingFormalMask);

  /// Returns `true` if the set of modifiers contains the synthetic modifier
  /// used to denote that a parameter is a super initializing formal.
  bool get isSuperInitializingFormal =>
      (_mask & _superInitializingFormalMask) != 0;

  /// Returns `true` if this set of modifiers contains any syntactic modifiers.
  ///
  /// If [ignoreRequired] is `true`, `required` is ignored. If
  /// [ignoreCovariant] is `true`, `covariant` is ignored.
  ///
  /// This ignores synthetic modifiers like [HasInitializer] and
  /// [InitializingFormal].
  ///
  /// ```
  /// DartDocTest(Modifiers.empty.containsSyntacticModifiers(), false)
  ///
  /// DartDocTest(Modifiers.Required.containsSyntacticModifiers(), true)
  /// DartDocTest(
  ///     Modifiers.Required.containsSyntacticModifiers(ignoreRequired: true),
  ///     false)
  ///
  /// DartDocTest(Modifiers.Covariant.containsSyntacticModifiers(), true)
  /// DartDocTest(
  ///     Modifiers.Covariant.containsSyntacticModifiers(ignoreCovariant: true),
  ///     false)
  ///
  /// DartDocTest(Modifiers.Abstract.containsSyntacticModifiers(), true)
  /// DartDocTest(Modifiers.Augment.containsSyntacticModifiers(), true)
  /// DartDocTest(Modifiers.Base.containsSyntacticModifiers(), true)
  /// DartDocTest(Modifiers.Const.containsSyntacticModifiers(), true)
  /// DartDocTest(
  ///     Modifiers.DeclaresConstConstructor.containsSyntacticModifiers(),
  ///     false)
  /// DartDocTest(Modifiers.External.containsSyntacticModifiers(), true)
  /// DartDocTest(Modifiers.Final.containsSyntacticModifiers(), true)
  /// DartDocTest(Modifiers.HasInitializer.containsSyntacticModifiers(), false)
  /// DartDocTest(
  ///     Modifiers.InitializingFormal.containsSyntacticModifiers(), false)
  /// DartDocTest(Modifiers.Interface.containsSyntacticModifiers(), true)
  /// DartDocTest(Modifiers.Late.containsSyntacticModifiers(), true)
  /// DartDocTest(Modifiers.Macro.containsSyntacticModifiers(), true)
  /// DartDocTest(Modifiers.Mixin.containsSyntacticModifiers(), true)
  /// DartDocTest(
  ///     Modifiers.NamedMixinApplication.containsSyntacticModifiers(), false)
  /// DartDocTest(Modifiers.Sealed.containsSyntacticModifiers(), true)
  /// DartDocTest(Modifiers.Static.containsSyntacticModifiers(), true)
  /// DartDocTest(
  ///     Modifiers.SuperInitializingFormal.containsSyntacticModifiers(), false)
  /// ```
  bool containsSyntacticModifiers(
      {bool ignoreRequired = false, bool ignoreCovariant = false}) {
    int mask = _mask &
        ~(_hasInitializerMask |
            _initializingFormalMask |
            _declaresConstConstructorMask |
            _namedMixinApplicationMask |
            _superInitializingFormalMask);
    if (ignoreRequired) {
      mask &= ~_requiredMask;
    }
    if (ignoreCovariant) {
      mask &= ~_covariantMask;
    }
    return mask != 0;
  }
}
