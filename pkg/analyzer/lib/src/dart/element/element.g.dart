// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Run 'dart pkg/analyzer/tool/element/generate.dart' to update.

part of 'element.dart';

mixin _ClassFragmentImplMixin {
  bool get hasExtendsClause {
    return hasModifier(Modifier.HAS_EXTENDS_CLAUSE);
  }

  set hasExtendsClause(bool value) {
    setModifier(Modifier.HAS_EXTENDS_CLAUSE, value);
  }

  /// Whether the executable element is abstract.
  ///
  /// Executable elements are abstract if they are not external, and have no
  /// body.
  bool get isAbstract {
    return hasModifier(Modifier.ABSTRACT);
  }

  set isAbstract(bool value) {
    setModifier(Modifier.ABSTRACT, value);
  }

  bool get isBase {
    return hasModifier(Modifier.BASE);
  }

  set isBase(bool value) {
    setModifier(Modifier.BASE, value);
  }

  bool get isFinal {
    return hasModifier(Modifier.FINAL);
  }

  set isFinal(bool value) {
    setModifier(Modifier.FINAL, value);
  }

  bool get isInterface {
    return hasModifier(Modifier.INTERFACE);
  }

  set isInterface(bool value) {
    setModifier(Modifier.INTERFACE, value);
  }

  bool get isMixinApplication {
    return hasModifier(Modifier.MIXIN_APPLICATION);
  }

  set isMixinApplication(bool value) {
    setModifier(Modifier.MIXIN_APPLICATION, value);
  }

  bool get isMixinClass {
    return hasModifier(Modifier.MIXIN_CLASS);
  }

  set isMixinClass(bool value) {
    setModifier(Modifier.MIXIN_CLASS, value);
  }

  bool get isSealed {
    return hasModifier(Modifier.SEALED);
  }

  set isSealed(bool value) {
    setModifier(Modifier.SEALED, value);
  }

  bool hasModifier(Modifier modifier);

  void setModifier(Modifier modifier, bool value);
}

mixin _ConstructorFragmentImplMixin {
  bool get isConst {
    return hasModifier(Modifier.CONST);
  }

  set isConst(bool value) {
    setModifier(Modifier.CONST, value);
  }

  bool get isFactory {
    return hasModifier(Modifier.FACTORY);
  }

  set isFactory(bool value) {
    setModifier(Modifier.FACTORY, value);
  }

  bool hasModifier(Modifier modifier);

  void setModifier(Modifier modifier, bool value);
}

mixin _ExecutableFragmentImplMixin {
  bool get hasImplicitReturnType {
    return hasModifier(Modifier.HAS_IMPLICIT_RETURN_TYPE);
  }

  set hasImplicitReturnType(bool value) {
    setModifier(Modifier.HAS_IMPLICIT_RETURN_TYPE, value);
  }

  bool get invokesSuperSelf {
    return hasModifier(Modifier.INVOKES_SUPER_SELF);
  }

  set invokesSuperSelf(bool value) {
    setModifier(Modifier.INVOKES_SUPER_SELF, value);
  }

  /// Whether the executable element is abstract.
  ///
  /// Executable elements are abstract if they are not external, and have no
  /// body.
  bool get isAbstract {
    return hasModifier(Modifier.ABSTRACT);
  }

  set isAbstract(bool value) {
    setModifier(Modifier.ABSTRACT, value);
  }

  bool get isAsynchronous {
    return hasModifier(Modifier.ASYNCHRONOUS);
  }

  set isAsynchronous(bool value) {
    setModifier(Modifier.ASYNCHRONOUS, value);
  }

  /// Executable elements are external if they are explicitly marked as such
  /// using the 'external' keyword.
  bool get isExternal {
    return hasModifier(Modifier.EXTERNAL);
  }

  set isExternal(bool value) {
    setModifier(Modifier.EXTERNAL, value);
  }

  bool get isGenerator {
    return hasModifier(Modifier.GENERATOR);
  }

  set isGenerator(bool value) {
    setModifier(Modifier.GENERATOR, value);
  }

  bool get isStatic {
    return hasModifier(Modifier.STATIC);
  }

  set isStatic(bool value) {
    setModifier(Modifier.STATIC, value);
  }

  bool hasModifier(Modifier modifier);

  void setModifier(Modifier modifier, bool value);
}

mixin _FieldFragmentImplMixin {
  bool get isEnumConstant {
    return hasModifier(Modifier.ENUM_CONSTANT);
  }

  set isEnumConstant(bool value) {
    setModifier(Modifier.ENUM_CONSTANT, value);
  }

  /// Whether the field was explicitly marked as being covariant.
  bool get isExplicitlyCovariant {
    return hasModifier(Modifier.EXPLICITLY_COVARIANT);
  }

  set isExplicitlyCovariant(bool value) {
    setModifier(Modifier.EXPLICITLY_COVARIANT, value);
  }

  bool get isPromotable {
    return hasModifier(Modifier.PROMOTABLE);
  }

  set isPromotable(bool value) {
    setModifier(Modifier.PROMOTABLE, value);
  }

  bool hasModifier(Modifier modifier);

  void setModifier(Modifier modifier, bool value);
}

mixin _FormalParameterFragmentImplMixin {
  /// Whether the field was explicitly marked as being covariant.
  bool get isExplicitlyCovariant {
    return hasModifier(Modifier.EXPLICITLY_COVARIANT);
  }

  set isExplicitlyCovariant(bool value) {
    setModifier(Modifier.EXPLICITLY_COVARIANT, value);
  }

  bool hasModifier(Modifier modifier);

  void setModifier(Modifier modifier, bool value);
}

mixin _FragmentImplMixin {
  bool get isAugmentation {
    return hasModifier(Modifier.AUGMENTATION);
  }

  set isAugmentation(bool value) {
    setModifier(Modifier.AUGMENTATION, value);
  }

  /// A synthetic element is an element that is not represented in the source
  /// code explicitly, but is implied by the source code, such as the default
  /// constructor for a class that does not explicitly define any constructors.
  bool get isSynthetic {
    return hasModifier(Modifier.SYNTHETIC);
  }

  set isSynthetic(bool value) {
    setModifier(Modifier.SYNTHETIC, value);
  }

  bool hasModifier(Modifier modifier);

  void setModifier(Modifier modifier, bool value);
}

mixin _MixinFragmentImplMixin {
  bool get isBase {
    return hasModifier(Modifier.BASE);
  }

  set isBase(bool value) {
    setModifier(Modifier.BASE, value);
  }

  bool hasModifier(Modifier modifier);

  void setModifier(Modifier modifier, bool value);
}

mixin _NonParameterVariableFragmentImplMixin {
  bool get hasInitializer {
    return hasModifier(Modifier.HAS_INITIALIZER);
  }

  set hasInitializer(bool value) {
    setModifier(Modifier.HAS_INITIALIZER, value);
  }

  bool hasModifier(Modifier modifier);

  void setModifier(Modifier modifier, bool value);
}

mixin _VariableFragmentImplMixin {
  /// Whether the variable element did not have an explicit type specified
  /// for it.
  bool get hasImplicitType {
    return hasModifier(Modifier.HAS_IMPLICIT_TYPE);
  }

  set hasImplicitType(bool value) {
    setModifier(Modifier.HAS_IMPLICIT_TYPE, value);
  }

  /// Whether the executable element is abstract.
  ///
  /// Executable elements are abstract if they are not external, and have no
  /// body.
  bool get isAbstract {
    return hasModifier(Modifier.ABSTRACT);
  }

  set isAbstract(bool value) {
    setModifier(Modifier.ABSTRACT, value);
  }

  bool get isConst {
    return hasModifier(Modifier.CONST);
  }

  set isConst(bool value) {
    setModifier(Modifier.CONST, value);
  }

  /// Executable elements are external if they are explicitly marked as such
  /// using the 'external' keyword.
  bool get isExternal {
    return hasModifier(Modifier.EXTERNAL);
  }

  set isExternal(bool value) {
    setModifier(Modifier.EXTERNAL, value);
  }

  /// Whether the variable was declared with the 'final' modifier.
  ///
  /// Variables that are declared with the 'const' modifier will return `false`
  /// even though they are implicitly final.
  bool get isFinal {
    return hasModifier(Modifier.FINAL);
  }

  set isFinal(bool value) {
    setModifier(Modifier.FINAL, value);
  }

  bool get isLate {
    return hasModifier(Modifier.LATE);
  }

  set isLate(bool value) {
    setModifier(Modifier.LATE, value);
  }

  /// Whether the element is a static variable, as per section 8 of the Dart
  /// Language Specification:
  ///
  /// > A static variable is a variable that is not associated with a particular
  /// > instance, but rather with an entire library or class. Static variables
  /// > include library variables and class variables. Class variables are
  /// > variables whose declaration is immediately nested inside a class
  /// > declaration and includes the modifier static. A library variable is
  /// > implicitly static.
  bool get isStatic {
    return hasModifier(Modifier.STATIC);
  }

  set isStatic(bool value) {
    setModifier(Modifier.STATIC, value);
  }

  bool hasModifier(Modifier modifier);

  void setModifier(Modifier modifier, bool value);
}
