// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/analyzer/messages.yaml' and run
// 'dart run pkg/analyzer/tool/messages/generate.dart' to update.

// Generated comments don't quite align with flutter style.
// ignore_for_file: flutter_style_todos

part of "package:analyzer/src/error/codes.dart";

class CompileTimeErrorCode {
  /// No parameters.
  static const DiagnosticWithoutArguments abstractFieldConstructorInitializer =
      diag.abstractFieldConstructorInitializer;

  /// No parameters.
  static const DiagnosticWithoutArguments abstractFieldInitializer =
      diag.abstractFieldInitializer;

  /// Parameters:
  /// String memberKind: the display name for the kind of the found abstract
  ///                    member
  /// String name: the name of the member
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required String memberKind,
      required String name,
    })
  >
  abstractSuperMemberReference = diag.abstractSuperMemberReference;

  /// Parameters:
  /// String p0: the name of the ambiguous element
  /// Uri p1: the name of the first library in which the type is found
  /// Uri p2: the name of the second library in which the type is found
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required String p0,
      required Uri p1,
      required Uri p2,
    })
  >
  ambiguousExport = diag.ambiguousExport;

  /// Parameters:
  /// String p0: the name of the member
  /// String p1: the names of the declaring extensions
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  ambiguousExtensionMemberAccessThreeOrMore =
      diag.ambiguousExtensionMemberAccessThreeOrMore;

  /// Parameters:
  /// String p0: the name of the member
  /// Element p1: the name of the first declaring extension
  /// Element p2: the names of the second declaring extension
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required String p0,
      required Element p1,
      required Element p2,
    })
  >
  ambiguousExtensionMemberAccessTwo = diag.ambiguousExtensionMemberAccessTwo;

  /// Parameters:
  /// String p0: the name of the ambiguous type
  /// String p1: the names of the libraries that the type is found
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  ambiguousImport = diag.ambiguousImport;

  /// No parameters.
  static const DiagnosticWithoutArguments ambiguousSetOrMapLiteralBoth =
      diag.ambiguousSetOrMapLiteralBoth;

  /// No parameters.
  static const DiagnosticWithoutArguments ambiguousSetOrMapLiteralEither =
      diag.ambiguousSetOrMapLiteralEither;

  /// Parameters:
  /// Type p0: the name of the actual argument type
  /// Type p1: the name of the expected type
  /// String p2: additional information, if any, when problem is associated with
  ///            records
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required DartType p0,
      required DartType p1,
      required String p2,
    })
  >
  argumentTypeNotAssignable = diag.argumentTypeNotAssignable;

  /// No parameters.
  static const DiagnosticWithoutArguments assertInRedirectingConstructor =
      diag.assertInRedirectingConstructor;

  /// No parameters.
  static const DiagnosticWithoutArguments assignmentToConst =
      diag.assignmentToConst;

  /// Parameters:
  /// String p0: the name of the final variable
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  assignmentToFinal = diag.assignmentToFinal;

  /// Parameters:
  /// String p0: the name of the variable
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  assignmentToFinalLocal = diag.assignmentToFinalLocal;

  /// Parameters:
  /// String p0: the name of the reference
  /// String p1: the name of the class
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  assignmentToFinalNoSetter = diag.assignmentToFinalNoSetter;

  /// No parameters.
  static const DiagnosticWithoutArguments assignmentToFunction =
      diag.assignmentToFunction;

  /// No parameters.
  static const DiagnosticWithoutArguments assignmentToMethod =
      diag.assignmentToMethod;

  /// No parameters.
  static const DiagnosticWithoutArguments assignmentToType =
      diag.assignmentToType;

  /// No parameters.
  static const DiagnosticWithoutArguments asyncForInWrongContext =
      diag.asyncForInWrongContext;

  /// No parameters.
  static const DiagnosticWithoutArguments
  augmentationExtendsClauseAlreadyPresent =
      diag.augmentationExtendsClauseAlreadyPresent;

  /// Parameters:
  /// Object p0: the lexeme of the modifier.
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  augmentationModifierExtra = diag.augmentationModifierExtra;

  /// Parameters:
  /// Object p0: the lexeme of the modifier.
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  augmentationModifierMissing = diag.augmentationModifierMissing;

  /// Parameters:
  /// Object p0: the name of the declaration kind.
  /// Object p1: the name of the augmentation kind.
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  augmentationOfDifferentDeclarationKind =
      diag.augmentationOfDifferentDeclarationKind;

  /// No parameters.
  static const DiagnosticWithoutArguments augmentationTypeParameterBound =
      diag.augmentationTypeParameterBound;

  /// No parameters.
  static const DiagnosticWithoutArguments augmentationTypeParameterCount =
      diag.augmentationTypeParameterCount;

  /// No parameters.
  static const DiagnosticWithoutArguments augmentationTypeParameterName =
      diag.augmentationTypeParameterName;

  /// No parameters.
  static const DiagnosticWithoutArguments augmentationWithoutDeclaration =
      diag.augmentationWithoutDeclaration;

  /// No parameters.
  static const DiagnosticWithoutArguments augmentedExpressionIsNotSetter =
      diag.augmentedExpressionIsNotSetter;

  /// No parameters.
  static const DiagnosticWithoutArguments augmentedExpressionIsSetter =
      diag.augmentedExpressionIsSetter;

  /// Parameters:
  /// Object p0: the lexeme of the operator.
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  augmentedExpressionNotOperator = diag.augmentedExpressionNotOperator;

  /// No parameters.
  static const DiagnosticWithoutArguments awaitInLateLocalVariableInitializer =
      diag.awaitInLateLocalVariableInitializer;

  /// 16.30 Await Expressions: It is a compile-time error if the function
  /// immediately enclosing _a_ is not declared asynchronous. (Where _a_ is the
  /// await expression.)
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments awaitInWrongContext =
      diag.awaitInWrongContext;

  /// No parameters.
  static const DiagnosticWithoutArguments awaitOfIncompatibleType =
      diag.awaitOfIncompatibleType;

  /// Parameters:
  /// String implementedClassName: the name of the base class being implemented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String implementedClassName})
  >
  baseClassImplementedOutsideOfLibrary =
      diag.baseClassImplementedOutsideOfLibrary;

  /// Parameters:
  /// String implementedMixinName: the name of the base mixin being implemented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String implementedMixinName})
  >
  baseMixinImplementedOutsideOfLibrary =
      diag.baseMixinImplementedOutsideOfLibrary;

  /// Parameters:
  /// Type p0: the name of the return type
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required DartType p0})
  >
  bodyMightCompleteNormally = diag.bodyMightCompleteNormally;

  /// No parameters.
  static const DiagnosticWithoutArguments breakLabelOnSwitchMember =
      diag.breakLabelOnSwitchMember;

  /// Parameters:
  /// String p0: the built-in identifier that is being used
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  builtInIdentifierAsExtensionName = diag.builtInIdentifierAsExtensionName;

  /// Parameters:
  /// String p0: the built-in identifier that is being used
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  builtInIdentifierAsExtensionTypeName =
      diag.builtInIdentifierAsExtensionTypeName;

  /// Parameters:
  /// String p0: the built-in identifier that is being used
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  builtInIdentifierAsPrefixName = diag.builtInIdentifierAsPrefixName;

  /// Parameters:
  /// String p0: the built-in identifier that is being used
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  builtInIdentifierAsType = diag.builtInIdentifierAsType;

  /// Parameters:
  /// String p0: the built-in identifier that is being used
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  builtInIdentifierAsTypedefName = diag.builtInIdentifierAsTypedefName;

  /// Parameters:
  /// String p0: the built-in identifier that is being used
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  builtInIdentifierAsTypeName = diag.builtInIdentifierAsTypeName;

  /// Parameters:
  /// String p0: the built-in identifier that is being used
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  builtInIdentifierAsTypeParameterName =
      diag.builtInIdentifierAsTypeParameterName;

  /// Parameters:
  /// Type p0: the this of the switch case expression
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required DartType p0})
  >
  caseExpressionTypeImplementsEquals = diag.caseExpressionTypeImplementsEquals;

  /// Parameters:
  /// Type p0: the type of the case expression
  /// Type p1: the type of the switch expression
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  caseExpressionTypeIsNotSwitchExpressionSubtype =
      diag.caseExpressionTypeIsNotSwitchExpressionSubtype;

  /// Parameters:
  /// String p0: the name of the type
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  castToNonType = diag.castToNonType;

  /// Parameters:
  /// String p0: the name of the member
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  classInstantiationAccessToInstanceMember =
      diag.classInstantiationAccessToInstanceMember;

  /// Parameters:
  /// String p0: the name of the member
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  classInstantiationAccessToStaticMember =
      diag.classInstantiationAccessToStaticMember;

  /// Parameters:
  /// String p0: the name of the class
  /// String p1: the name of the member
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  classInstantiationAccessToUnknownMember =
      diag.classInstantiationAccessToUnknownMember;

  /// Parameters:
  /// String p0: the name of the class being used as a mixin
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  classUsedAsMixin = diag.classUsedAsMixin;

  /// No parameters.
  static const DiagnosticWithoutArguments concreteClassHasEnumSuperinterface =
      diag.concreteClassHasEnumSuperinterface;

  /// Parameters:
  /// String p0: the name of the abstract method
  /// String p1: the name of the enclosing class
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  concreteClassWithAbstractMember = diag.concreteClassWithAbstractMember;

  /// Parameters:
  /// String p0: the name of the constructor and field
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  conflictingConstructorAndStaticField =
      diag.conflictingConstructorAndStaticField;

  /// Parameters:
  /// String p0: the name of the constructor and getter
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  conflictingConstructorAndStaticGetter =
      diag.conflictingConstructorAndStaticGetter;

  /// Parameters:
  /// String p0: the name of the constructor
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  conflictingConstructorAndStaticMethod =
      diag.conflictingConstructorAndStaticMethod;

  /// Parameters:
  /// String p0: the name of the constructor and setter
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  conflictingConstructorAndStaticSetter =
      diag.conflictingConstructorAndStaticSetter;

  /// 10.11 Class Member Conflicts: Let `C` be a class. It is a compile-time
  /// error if `C` declares a getter or a setter with basename `n`, and has a
  /// method named `n`.
  ///
  /// Parameters:
  /// String p0: the name of the class defining the conflicting field
  /// String p1: the name of the conflicting field
  /// String p2: the name of the class defining the method with which the field
  ///            conflicts
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required String p0,
      required String p1,
      required String p2,
    })
  >
  conflictingFieldAndMethod = diag.conflictingFieldAndMethod;

  /// Parameters:
  /// String p0: the name of the kind of the element implementing the
  ///            conflicting interface
  /// String p1: the name of the element implementing the conflicting interface
  /// String p2: the first conflicting type
  /// String p3: the second conflicting type
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required String p0,
      required String p1,
      required String p2,
      required String p3,
    })
  >
  conflictingGenericInterfaces = diag.conflictingGenericInterfaces;

  /// 10.11 Class Member Conflicts: Let `C` be a class. It is a compile-time
  /// error if the interface of `C` has an instance method named `n` and an
  /// instance setter with basename `n`.
  ///
  /// Parameters:
  /// String p0: the name of the enclosing element kind - class, extension type,
  ///            etc
  /// String p1: the name of the enclosing element
  /// String p2: the name of the conflicting method / setter
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required String p0,
      required String p1,
      required String p2,
    })
  >
  conflictingInheritedMethodAndSetter =
      diag.conflictingInheritedMethodAndSetter;

  /// 10.11 Class Member Conflicts: Let `C` be a class. It is a compile-time
  /// error if `C` declares a method named `n`, and has a getter or a setter
  /// with basename `n`.
  ///
  /// Parameters:
  /// String p0: the name of the class defining the conflicting method
  /// String p1: the name of the conflicting method
  /// String p2: the name of the class defining the field with which the method
  ///            conflicts
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required String p0,
      required String p1,
      required String p2,
    })
  >
  conflictingMethodAndField = diag.conflictingMethodAndField;

  /// 10.11 Class Member Conflicts: Let `C` be a class. It is a compile-time
  /// error if `C` declares a static member with basename `n`, and has an
  /// instance member with basename `n`.
  ///
  /// Parameters:
  /// String p0: the name of the class defining the conflicting member
  /// String p1: the name of the conflicting static member
  /// String p2: the name of the class defining the field with which the method
  ///            conflicts
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required String p0,
      required String p1,
      required String p2,
    })
  >
  conflictingStaticAndInstance = diag.conflictingStaticAndInstance;

  /// Parameters:
  /// String p0: the name of the type parameter
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  conflictingTypeVariableAndClass = diag.conflictingTypeVariableAndClass;

  /// Parameters:
  /// String p0: the name of the type parameter
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  conflictingTypeVariableAndEnum = diag.conflictingTypeVariableAndEnum;

  /// Parameters:
  /// String p0: the name of the type parameter
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  conflictingTypeVariableAndExtension =
      diag.conflictingTypeVariableAndExtension;

  /// Parameters:
  /// String p0: the name of the type parameter
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  conflictingTypeVariableAndExtensionType =
      diag.conflictingTypeVariableAndExtensionType;

  /// Parameters:
  /// String p0: the name of the type parameter
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  conflictingTypeVariableAndMemberClass =
      diag.conflictingTypeVariableAndMemberClass;

  /// Parameters:
  /// String p0: the name of the type parameter
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  conflictingTypeVariableAndMemberEnum =
      diag.conflictingTypeVariableAndMemberEnum;

  /// Parameters:
  /// String p0: the name of the type parameter
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  conflictingTypeVariableAndMemberExtension =
      diag.conflictingTypeVariableAndMemberExtension;

  /// Parameters:
  /// String p0: the name of the type parameter
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  conflictingTypeVariableAndMemberExtensionType =
      diag.conflictingTypeVariableAndMemberExtensionType;

  /// Parameters:
  /// String p0: the name of the type parameter
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  conflictingTypeVariableAndMemberMixin =
      diag.conflictingTypeVariableAndMemberMixin;

  /// Parameters:
  /// String p0: the name of the type parameter
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  conflictingTypeVariableAndMixin = diag.conflictingTypeVariableAndMixin;

  /// No parameters.
  static const DiagnosticWithoutArguments
  constantPatternWithNonConstantExpression =
      diag.constantPatternWithNonConstantExpression;

  /// No parameters.
  static const DiagnosticWithoutArguments
  constConstructorConstantFromDeferredLibrary =
      diag.constConstructorConstantFromDeferredLibrary;

  /// 16.12.2 Const: It is a compile-time error if evaluation of a constant
  /// object results in an uncaught exception being thrown.
  ///
  /// Parameters:
  /// Object valueType: the type of the runtime value of the argument
  /// Object fieldName: the name of the field
  /// Object fieldType: the type of the field
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required Object valueType,
      required Object fieldName,
      required Object fieldType,
    })
  >
  constConstructorFieldTypeMismatch = diag.constConstructorFieldTypeMismatch;

  /// Parameters:
  /// String valueType: the type of the runtime value of the argument
  /// String parameterType: the static type of the parameter
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required String valueType,
      required String parameterType,
    })
  >
  constConstructorParamTypeMismatch = diag.constConstructorParamTypeMismatch;

  /// 16.12.2 Const: It is a compile-time error if evaluation of a constant
  /// object results in an uncaught exception being thrown.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments constConstructorThrowsException =
      diag.constConstructorThrowsException;

  /// Parameters:
  /// String p0: the name of the field
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  constConstructorWithFieldInitializedByNonConst =
      diag.constConstructorWithFieldInitializedByNonConst;

  /// 7.6.3 Constant Constructors: The superinitializer that appears, explicitly
  /// or implicitly, in the initializer list of a constant constructor must
  /// specify a constant constructor of the superclass of the immediately
  /// enclosing class or a compile-time error occurs.
  ///
  /// 12.1 Mixin Application: For each generative constructor named ... an
  /// implicitly declared constructor named ... is declared. If Sq is a
  /// generative const constructor, and M does not declare any fields, Cq is
  /// also a const constructor.
  ///
  /// Parameters:
  /// String p0: the name of the instance field.
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  constConstructorWithMixinWithField = diag.constConstructorWithMixinWithField;

  /// 7.6.3 Constant Constructors: The superinitializer that appears, explicitly
  /// or implicitly, in the initializer list of a constant constructor must
  /// specify a constant constructor of the superclass of the immediately
  /// enclosing class or a compile-time error occurs.
  ///
  /// 12.1 Mixin Application: For each generative constructor named ... an
  /// implicitly declared constructor named ... is declared. If Sq is a
  /// generative const constructor, and M does not declare any fields, Cq is
  /// also a const constructor.
  ///
  /// Parameters:
  /// String p0: the names of the instance fields.
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  constConstructorWithMixinWithFields =
      diag.constConstructorWithMixinWithFields;

  /// Parameters:
  /// String p0: the name of the superclass
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  constConstructorWithNonConstSuper = diag.constConstructorWithNonConstSuper;

  /// No parameters.
  static const DiagnosticWithoutArguments constConstructorWithNonFinalField =
      diag.constConstructorWithNonFinalField;

  /// No parameters.
  static const DiagnosticWithoutArguments constDeferredClass =
      diag.constDeferredClass;

  /// No parameters.
  static const DiagnosticWithoutArguments constEvalAssertionFailure =
      diag.constEvalAssertionFailure;

  /// Parameters:
  /// Object message: the message of the assertion
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object message})
  >
  constEvalAssertionFailureWithMessage =
      diag.constEvalAssertionFailureWithMessage;

  /// No parameters.
  static const DiagnosticWithoutArguments constEvalExtensionMethod =
      diag.constEvalExtensionMethod;

  /// No parameters.
  static const DiagnosticWithoutArguments constEvalExtensionTypeMethod =
      diag.constEvalExtensionTypeMethod;

  /// No parameters.
  static const DiagnosticWithoutArguments constEvalForElement =
      diag.constEvalForElement;

  /// No parameters.
  static const DiagnosticWithoutArguments constEvalMethodInvocation =
      diag.constEvalMethodInvocation;

  /// See https://spec.dart.dev/DartLangSpecDraft.pdf#constants, "Constants",
  /// for text about "An expression of the form e1 == e2".
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments constEvalPrimitiveEquality =
      diag.constEvalPrimitiveEquality;

  /// Parameters:
  /// String propertyName: the name of the property being accessed
  /// String type: the type with the property being accessed
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required String propertyName,
      required String type,
    })
  >
  constEvalPropertyAccess = diag.constEvalPropertyAccess;

  /// 16.12.2 Const: It is a compile-time error if evaluation of a constant
  /// object results in an uncaught exception being thrown.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments constEvalThrowsException =
      diag.constEvalThrowsException;

  /// 16.12.2 Const: It is a compile-time error if evaluation of a constant
  /// object results in an uncaught exception being thrown.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments constEvalThrowsIdbze =
      diag.constEvalThrowsIdbze;

  /// See https://spec.dart.dev/DartLangSpecDraft.pdf#constants, "Constants",
  /// for text about "An expression of the form !e1", "An expression of the form
  /// e1 && e2", and "An expression of the form e1 || e2".
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments constEvalTypeBool =
      diag.constEvalTypeBool;

  /// See https://spec.dart.dev/DartLangSpecDraft.pdf#constants, "Constants",
  /// for text about "An expression of the form e1 & e2".
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments constEvalTypeBoolInt =
      diag.constEvalTypeBoolInt;

  /// See https://spec.dart.dev/DartLangSpecDraft.pdf#constants, "Constants",
  /// for text about "A literal string".
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments constEvalTypeBoolNumString =
      diag.constEvalTypeBoolNumString;

  /// See https://spec.dart.dev/DartLangSpecDraft.pdf#constants, "Constants",
  /// for text about "An expression of the form ~e1", "An expression of one of
  /// the forms e1 >> e2".
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments constEvalTypeInt =
      diag.constEvalTypeInt;

  /// See https://spec.dart.dev/DartLangSpecDraft.pdf#constants, "Constants",
  /// for text about "An expression of the form e1 - e2".
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments constEvalTypeNum =
      diag.constEvalTypeNum;

  /// See https://spec.dart.dev/DartLangSpecDraft.pdf#constants, "Constants",
  /// for text about "An expression of the form e1 + e2".
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments constEvalTypeNumString =
      diag.constEvalTypeNumString;

  /// No parameters.
  static const DiagnosticWithoutArguments constEvalTypeString =
      diag.constEvalTypeString;

  /// No parameters.
  static const DiagnosticWithoutArguments constEvalTypeType =
      diag.constEvalTypeType;

  /// Parameters:
  /// Type p0: the name of the type of the initializer expression
  /// Type p1: the name of the type of the field
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  constFieldInitializerNotAssignable = diag.constFieldInitializerNotAssignable;

  /// No parameters.
  static const DiagnosticWithoutArguments constInitializedWithNonConstantValue =
      diag.constInitializedWithNonConstantValue;

  /// No parameters.
  static const DiagnosticWithoutArguments
  constInitializedWithNonConstantValueFromDeferredLibrary =
      diag.constInitializedWithNonConstantValueFromDeferredLibrary;

  /// No parameters.
  static const DiagnosticWithoutArguments constInstanceField =
      diag.constInstanceField;

  /// Parameters:
  /// Type p0: the type of the entry's key
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required DartType p0})
  >
  constMapKeyNotPrimitiveEquality = diag.constMapKeyNotPrimitiveEquality;

  /// Parameters:
  /// String p0: the name of the uninitialized final variable
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  constNotInitialized = diag.constNotInitialized;

  /// Parameters:
  /// Type p0: the type of the element
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required DartType p0})
  >
  constSetElementNotPrimitiveEquality =
      diag.constSetElementNotPrimitiveEquality;

  /// No parameters.
  static const DiagnosticWithoutArguments constSpreadExpectedListOrSet =
      diag.constSpreadExpectedListOrSet;

  /// No parameters.
  static const DiagnosticWithoutArguments constSpreadExpectedMap =
      diag.constSpreadExpectedMap;

  /// No parameters.
  static const DiagnosticWithoutArguments constTypeParameter =
      diag.constTypeParameter;

  /// No parameters.
  static const DiagnosticWithoutArguments constWithNonConst =
      diag.constWithNonConst;

  /// No parameters.
  static const DiagnosticWithoutArguments constWithNonConstantArgument =
      diag.constWithNonConstantArgument;

  /// Parameters:
  /// String p0: the name of the non-type element
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  constWithNonType = diag.constWithNonType;

  /// No parameters.
  static const DiagnosticWithoutArguments constWithTypeParameters =
      diag.constWithTypeParameters;

  /// No parameters.
  static const DiagnosticWithoutArguments
  constWithTypeParametersConstructorTearoff =
      diag.constWithTypeParametersConstructorTearoff;

  /// No parameters.
  static const DiagnosticWithoutArguments
  constWithTypeParametersFunctionTearoff =
      diag.constWithTypeParametersFunctionTearoff;

  /// 16.12.2 Const: It is a compile-time error if <i>T.id</i> is not the name of
  /// a constant constructor declared by the type <i>T</i>.
  ///
  /// Parameters:
  /// Object p0: the name of the type
  /// String p1: the name of the requested constant constructor
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required String p1})
  >
  constWithUndefinedConstructor = diag.constWithUndefinedConstructor;

  /// 16.12.2 Const: It is a compile-time error if <i>T.id</i> is not the name of
  /// a constant constructor declared by the type <i>T</i>.
  ///
  /// Parameters:
  /// String p0: the name of the type
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  constWithUndefinedConstructorDefault =
      diag.constWithUndefinedConstructorDefault;

  /// No parameters.
  static const DiagnosticWithoutArguments continueLabelInvalid =
      diag.continueLabelInvalid;

  /// Parameters:
  /// String p0: the name of the type parameter
  /// String p1: detail text explaining why the type could not be inferred
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  couldNotInfer = diag.couldNotInfer;

  /// No parameters.
  static const DiagnosticWithoutArguments
  defaultValueInRedirectingFactoryConstructor =
      diag.defaultValueInRedirectingFactoryConstructor;

  /// No parameters.
  static const DiagnosticWithoutArguments defaultValueOnRequiredParameter =
      diag.defaultValueOnRequiredParameter;

  /// No parameters.
  static const DiagnosticWithoutArguments deferredImportOfExtension =
      diag.deferredImportOfExtension;

  /// Parameters:
  /// String p0: the name of the variable that is invalid
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  definitelyUnassignedLateLocalVariable =
      diag.definitelyUnassignedLateLocalVariable;

  /// No parameters.
  static const DiagnosticWithoutArguments
  disallowedTypeInstantiationExpression =
      diag.disallowedTypeInstantiationExpression;

  /// No parameters.
  static const DiagnosticWithoutArguments dotShorthandMissingContext =
      diag.dotShorthandMissingContext;

  /// Parameters:
  /// String p0: the name of the static getter
  /// String p1: the name of the enclosing type where the getter is being looked
  ///            for
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  dotShorthandUndefinedGetter = diag.dotShorthandUndefinedGetter;

  /// Parameters:
  /// String p0: the name of the static method or constructor
  /// String p1: the name of the enclosing type where the method or constructor
  ///            is being looked for
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  dotShorthandUndefinedInvocation = diag.dotShorthandUndefinedInvocation;

  /// No parameters.
  static const DiagnosticWithoutArguments duplicateConstructorDefault =
      diag.duplicateConstructorDefault;

  /// Parameters:
  /// String p0: the name of the duplicate entity
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  duplicateConstructorName = diag.duplicateConstructorName;

  /// Parameters:
  /// Object p0: the name of the duplicate entity
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  duplicateDefinition = diag.duplicateDefinition;

  /// Parameters:
  /// Object p0: the name of the field
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  duplicateFieldFormalParameter = diag.duplicateFieldFormalParameter;

  /// Parameters:
  /// Object p0: the duplicated name
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  duplicateFieldName = diag.duplicateFieldName;

  /// Parameters:
  /// String p0: the name of the parameter that was duplicated
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  duplicateNamedArgument = diag.duplicateNamedArgument;

  /// Parameters:
  /// Uri p0: the URI of the duplicate part
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Uri p0})
  >
  duplicatePart = diag.duplicatePart;

  /// Parameters:
  /// Object p0: the name of the variable
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  duplicatePatternAssignmentVariable = diag.duplicatePatternAssignmentVariable;

  /// Parameters:
  /// Object p0: the name of the field
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  duplicatePatternField = diag.duplicatePatternField;

  /// No parameters.
  static const DiagnosticWithoutArguments duplicateRestElementInPattern =
      diag.duplicateRestElementInPattern;

  /// Parameters:
  /// Object p0: the name of the variable
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  duplicateVariablePattern = diag.duplicateVariablePattern;

  /// No parameters.
  static const DiagnosticWithoutArguments emptyMapPattern =
      diag.emptyMapPattern;

  /// No parameters.
  static const DiagnosticWithoutArguments
  enumConstantInvokesFactoryConstructor =
      diag.enumConstantInvokesFactoryConstructor;

  /// No parameters.
  static const DiagnosticWithoutArguments enumConstantSameNameAsEnclosing =
      diag.enumConstantSameNameAsEnclosing;

  /// No parameters.
  static const DiagnosticWithoutArguments
  enumInstantiatedToBoundsIsNotWellBounded =
      diag.enumInstantiatedToBoundsIsNotWellBounded;

  /// No parameters.
  static const DiagnosticWithoutArguments enumMixinWithInstanceVariable =
      diag.enumMixinWithInstanceVariable;

  /// Parameters:
  /// String p0: the name of the abstract method
  /// String p1: the name of the enclosing enum
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  enumWithAbstractMember = diag.enumWithAbstractMember;

  /// No parameters.
  static const DiagnosticWithoutArguments enumWithNameValues =
      diag.enumWithNameValues;

  /// No parameters.
  static const DiagnosticWithoutArguments enumWithoutConstants =
      diag.enumWithoutConstants;

  /// No parameters.
  static const DiagnosticWithoutArguments equalElementsInConstSet =
      diag.equalElementsInConstSet;

  /// No parameters.
  static const DiagnosticWithoutArguments equalKeysInConstMap =
      diag.equalKeysInConstMap;

  /// No parameters.
  static const DiagnosticWithoutArguments equalKeysInMapPattern =
      diag.equalKeysInMapPattern;

  /// Parameters:
  /// int p0: the number of provided type arguments
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required int p0})
  >
  expectedOneListPatternTypeArguments =
      diag.expectedOneListPatternTypeArguments;

  /// Parameters:
  /// int p0: the number of provided type arguments
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required int p0})
  >
  expectedOneListTypeArguments = diag.expectedOneListTypeArguments;

  /// Parameters:
  /// int p0: the number of provided type arguments
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required int p0})
  >
  expectedOneSetTypeArguments = diag.expectedOneSetTypeArguments;

  /// Parameters:
  /// int p0: the number of provided type arguments
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required int p0})
  >
  expectedTwoMapPatternTypeArguments = diag.expectedTwoMapPatternTypeArguments;

  /// Parameters:
  /// int p0: the number of provided type arguments
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required int p0})
  >
  expectedTwoMapTypeArguments = diag.expectedTwoMapTypeArguments;

  /// Parameters:
  /// String p0: the URI pointing to a library
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  exportInternalLibrary = diag.exportInternalLibrary;

  /// Parameters:
  /// String p0: the URI pointing to a non-library declaration
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  exportOfNonLibrary = diag.exportOfNonLibrary;

  /// No parameters.
  static const DiagnosticWithoutArguments expressionInMap =
      diag.expressionInMap;

  /// No parameters.
  static const DiagnosticWithoutArguments extendsDeferredClass =
      diag.extendsDeferredClass;

  /// Parameters:
  /// Type p0: the name of the disallowed type
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required DartType p0})
  >
  extendsDisallowedClass = diag.extendsDisallowedClass;

  /// No parameters.
  static const DiagnosticWithoutArguments extendsNonClass =
      diag.extendsNonClass;

  /// No parameters.
  static const DiagnosticWithoutArguments
  extendsTypeAliasExpandsToTypeParameter =
      diag.extendsTypeAliasExpandsToTypeParameter;

  /// Parameters:
  /// String p0: the name of the extension
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  extensionAsExpression = diag.extensionAsExpression;

  /// Parameters:
  /// String p0: the name of the conflicting static member
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  extensionConflictingStaticAndInstance =
      diag.extensionConflictingStaticAndInstance;

  /// No parameters.
  static const DiagnosticWithoutArguments extensionDeclaresInstanceField =
      diag.extensionDeclaresInstanceField;

  /// No parameters.
  static const DiagnosticWithoutArguments extensionDeclaresMemberOfObject =
      diag.extensionDeclaresMemberOfObject;

  /// No parameters.
  static const DiagnosticWithoutArguments
  extensionOverrideAccessToStaticMember =
      diag.extensionOverrideAccessToStaticMember;

  /// Parameters:
  /// Type p0: the type of the argument
  /// Type p1: the extended type
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  extensionOverrideArgumentNotAssignable =
      diag.extensionOverrideArgumentNotAssignable;

  /// No parameters.
  static const DiagnosticWithoutArguments extensionOverrideWithCascade =
      diag.extensionOverrideWithCascade;

  /// No parameters.
  static const DiagnosticWithoutArguments extensionOverrideWithoutAccess =
      diag.extensionOverrideWithoutAccess;

  /// No parameters.
  static const DiagnosticWithoutArguments
  extensionTypeConstructorWithSuperFormalParameter =
      diag.extensionTypeConstructorWithSuperFormalParameter;

  /// No parameters.
  static const DiagnosticWithoutArguments
  extensionTypeConstructorWithSuperInvocation =
      diag.extensionTypeConstructorWithSuperInvocation;

  /// No parameters.
  static const DiagnosticWithoutArguments extensionTypeDeclaresInstanceField =
      diag.extensionTypeDeclaresInstanceField;

  /// No parameters.
  static const DiagnosticWithoutArguments extensionTypeDeclaresMemberOfObject =
      diag.extensionTypeDeclaresMemberOfObject;

  /// Parameters:
  /// Type p0: the display string of the disallowed type
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required DartType p0})
  >
  extensionTypeImplementsDisallowedType =
      diag.extensionTypeImplementsDisallowedType;

  /// No parameters.
  static const DiagnosticWithoutArguments extensionTypeImplementsItself =
      diag.extensionTypeImplementsItself;

  /// Parameters:
  /// Type p0: the implemented not extension type
  /// Type p1: the ultimate representation type
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  extensionTypeImplementsNotSupertype =
      diag.extensionTypeImplementsNotSupertype;

  /// Parameters:
  /// Type p0: the representation type of the implemented extension type
  /// String p1: the name of the implemented extension type
  /// Type p2: the representation type of the this extension type
  /// String p3: the name of the this extension type
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required DartType p0,
      required String p1,
      required DartType p2,
      required String p3,
    })
  >
  extensionTypeImplementsRepresentationNotSupertype =
      diag.extensionTypeImplementsRepresentationNotSupertype;

  /// Parameters:
  /// String p0: the name of the extension type
  /// String p1: the name of the conflicting member
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  extensionTypeInheritedMemberConflict =
      diag.extensionTypeInheritedMemberConflict;

  /// No parameters.
  static const DiagnosticWithoutArguments
  extensionTypeRepresentationDependsOnItself =
      diag.extensionTypeRepresentationDependsOnItself;

  /// No parameters.
  static const DiagnosticWithoutArguments
  extensionTypeRepresentationTypeBottom =
      diag.extensionTypeRepresentationTypeBottom;

  /// Parameters:
  /// String p0: the name of the abstract method
  /// String p1: the name of the enclosing extension type
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  extensionTypeWithAbstractMember = diag.extensionTypeWithAbstractMember;

  /// No parameters.
  static const DiagnosticWithoutArguments externalFieldConstructorInitializer =
      diag.externalFieldConstructorInitializer;

  /// No parameters.
  static const DiagnosticWithoutArguments externalFieldInitializer =
      diag.externalFieldInitializer;

  /// No parameters.
  static const DiagnosticWithoutArguments externalVariableInitializer =
      diag.externalVariableInitializer;

  /// Parameters:
  /// int p0: the maximum number of positional arguments
  /// int p1: the actual number of positional arguments given
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required int p0, required int p1})
  >
  extraPositionalArguments = diag.extraPositionalArguments;

  /// Parameters:
  /// int p0: the maximum number of positional arguments
  /// int p1: the actual number of positional arguments given
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required int p0, required int p1})
  >
  extraPositionalArgumentsCouldBeNamed =
      diag.extraPositionalArgumentsCouldBeNamed;

  /// Parameters:
  /// String p0: the name of the field being initialized multiple times
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  fieldInitializedByMultipleInitializers =
      diag.fieldInitializedByMultipleInitializers;

  /// No parameters.
  static const DiagnosticWithoutArguments
  fieldInitializedInInitializerAndDeclaration =
      diag.fieldInitializedInInitializerAndDeclaration;

  /// No parameters.
  static const DiagnosticWithoutArguments
  fieldInitializedInParameterAndInitializer =
      diag.fieldInitializedInParameterAndInitializer;

  /// No parameters.
  static const DiagnosticWithoutArguments fieldInitializerFactoryConstructor =
      diag.fieldInitializerFactoryConstructor;

  /// Parameters:
  /// Type p0: the name of the type of the initializer expression
  /// Type p1: the name of the type of the field
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  fieldInitializerNotAssignable = diag.fieldInitializerNotAssignable;

  /// No parameters.
  static const DiagnosticWithoutArguments fieldInitializerOutsideConstructor =
      diag.fieldInitializerOutsideConstructor;

  /// No parameters.
  static const DiagnosticWithoutArguments
  fieldInitializerRedirectingConstructor =
      diag.fieldInitializerRedirectingConstructor;

  /// Parameters:
  /// Type p0: the name of the type of the field formal parameter
  /// Type p1: the name of the type of the field
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  fieldInitializingFormalNotAssignable =
      diag.fieldInitializingFormalNotAssignable;

  /// Parameters:
  /// String p0: the name of the final class being extended.
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  finalClassExtendedOutsideOfLibrary = diag.finalClassExtendedOutsideOfLibrary;

  /// Parameters:
  /// String p0: the name of the final class being implemented.
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  finalClassImplementedOutsideOfLibrary =
      diag.finalClassImplementedOutsideOfLibrary;

  /// Parameters:
  /// String p0: the name of the final class being used as a mixin superclass
  ///            constraint.
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  finalClassUsedAsMixinConstraintOutsideOfLibrary =
      diag.finalClassUsedAsMixinConstraintOutsideOfLibrary;

  /// Parameters:
  /// String p0: the name of the field in question
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  finalInitializedInDeclarationAndConstructor =
      diag.finalInitializedInDeclarationAndConstructor;

  /// Parameters:
  /// String p0: the name of the uninitialized final variable
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  finalNotInitialized = diag.finalNotInitialized;

  /// Parameters:
  /// String p0: the name of the uninitialized final variable
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  finalNotInitializedConstructor1 = diag.finalNotInitializedConstructor1;

  /// Parameters:
  /// String p0: the name of the uninitialized final variable
  /// String p1: the name of the uninitialized final variable
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  finalNotInitializedConstructor2 = diag.finalNotInitializedConstructor2;

  /// Parameters:
  /// String p0: the name of the uninitialized final variable
  /// String p1: the name of the uninitialized final variable
  /// int p2: the number of additional not initialized variables that aren't
  ///         listed
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required String p0,
      required String p1,
      required int p2,
    })
  >
  finalNotInitializedConstructor3Plus =
      diag.finalNotInitializedConstructor3Plus;

  /// Parameters:
  /// Type p0: the type of the iterable expression.
  /// String p1: the sequence type -- Iterable for `for` or Stream for `await
  ///            for`.
  /// Type p2: the loop variable type.
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required DartType p0,
      required String p1,
      required DartType p2,
    })
  >
  forInOfInvalidElementType = diag.forInOfInvalidElementType;

  /// Parameters:
  /// Type p0: the type of the iterable expression.
  /// String p1: the sequence type -- Iterable for `for` or Stream for `await
  ///            for`.
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required DartType p0, required String p1})
  >
  forInOfInvalidType = diag.forInOfInvalidType;

  /// No parameters.
  static const DiagnosticWithoutArguments forInWithConstVariable =
      diag.forInWithConstVariable;

  /// It is a compile-time error if a generic function type is used as a bound
  /// for a formal type parameter of a class or a function.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments genericFunctionTypeCannotBeBound =
      diag.genericFunctionTypeCannotBeBound;

  /// It is a compile-time error if a generic function type is used as an actual
  /// type argument.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments
  genericFunctionTypeCannotBeTypeArgument =
      diag.genericFunctionTypeCannotBeTypeArgument;

  /// No parameters.
  static const DiagnosticWithoutArguments
  genericMethodTypeInstantiationOnDynamic =
      diag.genericMethodTypeInstantiationOnDynamic;

  /// Parameters:
  /// Object p0: the name of the getter
  /// Object p1: the type of the getter
  /// Object p2: the type of the setter
  /// Object p3: the name of the setter
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required Object p0,
      required Object p1,
      required Object p2,
      required Object p3,
    })
  >
  getterNotAssignableSetterTypes = diag.getterNotAssignableSetterTypes;

  /// Parameters:
  /// Object p0: the name of the getter
  /// Object p1: the type of the getter
  /// Object p2: the type of the setter
  /// Object p3: the name of the setter
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required Object p0,
      required Object p1,
      required Object p2,
      required Object p3,
    })
  >
  getterNotSubtypeSetterTypes = diag.getterNotSubtypeSetterTypes;

  /// No parameters.
  static const DiagnosticWithoutArguments
  ifElementConditionFromDeferredLibrary =
      diag.ifElementConditionFromDeferredLibrary;

  /// No parameters.
  static const DiagnosticWithoutArguments illegalAsyncGeneratorReturnType =
      diag.illegalAsyncGeneratorReturnType;

  /// No parameters.
  static const DiagnosticWithoutArguments illegalAsyncReturnType =
      diag.illegalAsyncReturnType;

  /// Parameters:
  /// String p0: the name of member that cannot be declared
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  illegalConcreteEnumMemberDeclaration =
      diag.illegalConcreteEnumMemberDeclaration;

  /// Parameters:
  /// String p0: the name of member that cannot be inherited
  /// String p1: the name of the class that declares the member
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  illegalConcreteEnumMemberInheritance =
      diag.illegalConcreteEnumMemberInheritance;

  /// No parameters.
  static const DiagnosticWithoutArguments illegalEnumValuesDeclaration =
      diag.illegalEnumValuesDeclaration;

  /// Parameters:
  /// String p0: the name of the class that declares 'values'
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  illegalEnumValuesInheritance = diag.illegalEnumValuesInheritance;

  /// Parameters:
  /// String p0: the required language version
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  illegalLanguageVersionOverride = diag.illegalLanguageVersionOverride;

  /// No parameters.
  static const DiagnosticWithoutArguments illegalSyncGeneratorReturnType =
      diag.illegalSyncGeneratorReturnType;

  /// No parameters.
  static const DiagnosticWithoutArguments implementsDeferredClass =
      diag.implementsDeferredClass;

  /// Parameters:
  /// Type p0: the name of the disallowed type
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required DartType p0})
  >
  implementsDisallowedClass = diag.implementsDisallowedClass;

  /// No parameters.
  static const DiagnosticWithoutArguments implementsNonClass =
      diag.implementsNonClass;

  /// Parameters:
  /// String p0: the name of the interface that is implemented more than once
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  implementsRepeated = diag.implementsRepeated;

  /// Parameters:
  /// Element p0: the name of the class that appears in both "extends" and
  ///             "implements" clauses
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Element p0})
  >
  implementsSuperClass = diag.implementsSuperClass;

  /// No parameters.
  static const DiagnosticWithoutArguments
  implementsTypeAliasExpandsToTypeParameter =
      diag.implementsTypeAliasExpandsToTypeParameter;

  /// Parameters:
  /// Type p0: the name of the superclass
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required DartType p0})
  >
  implicitSuperInitializerMissingArguments =
      diag.implicitSuperInitializerMissingArguments;

  /// Parameters:
  /// String p0: the name of the instance member
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  implicitThisReferenceInInitializer = diag.implicitThisReferenceInInitializer;

  /// Parameters:
  /// String p0: the URI pointing to a library
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  importInternalLibrary = diag.importInternalLibrary;

  /// Parameters:
  /// String p0: the URI pointing to a non-library declaration
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  importOfNonLibrary = diag.importOfNonLibrary;

  /// 13.9 Switch: It is a compile-time error if values of the expressions
  /// <i>e<sub>k</sub></i> are not instances of the same class <i>C</i>, for all
  /// <i>1 &lt;= k &lt;= n</i>.
  ///
  /// Parameters:
  /// Object p0: the expression source code that is the unexpected type
  /// Object p1: the name of the expected type
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  inconsistentCaseExpressionTypes = diag.inconsistentCaseExpressionTypes;

  /// Parameters:
  /// String p0: the name of the instance member with inconsistent inheritance.
  /// String p1: the list of all inherited signatures for this member.
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  inconsistentInheritance = diag.inconsistentInheritance;

  /// 11.1.1 Inheritance and Overriding. Let `I` be the implicit interface of a
  /// class `C` declared in library `L`. `I` inherits all members of
  /// `inherited(I, L)` and `I` overrides `m'` if `m' ∈ overrides(I, L)`. It is
  /// a compile-time error if `m` is a method and `m'` is a getter, or if `m`
  /// is a getter and `m'` is a method.
  ///
  /// Parameters:
  /// String p0: the name of the instance member with inconsistent inheritance.
  /// String p1: the name of the superinterface that declares the name as a
  ///            getter.
  /// String p2: the name of the superinterface that declares the name as a
  ///            method.
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required String p0,
      required String p1,
      required String p2,
    })
  >
  inconsistentInheritanceGetterAndMethod =
      diag.inconsistentInheritanceGetterAndMethod;

  /// No parameters.
  static const DiagnosticWithoutArguments inconsistentLanguageVersionOverride =
      diag.inconsistentLanguageVersionOverride;

  /// Parameters:
  /// String p0: the name of the pattern variable
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  inconsistentPatternVariableLogicalOr =
      diag.inconsistentPatternVariableLogicalOr;

  /// Parameters:
  /// String p0: the name of the initializing formal that is not an instance
  ///            variable in the immediately enclosing class
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  initializerForNonExistentField = diag.initializerForNonExistentField;

  /// Parameters:
  /// String p0: the name of the initializing formal that is a static variable
  ///            in the immediately enclosing class
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  initializerForStaticField = diag.initializerForStaticField;

  /// Parameters:
  /// String p0: the name of the initializing formal that is not an instance
  ///            variable in the immediately enclosing class
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  initializingFormalForNonExistentField =
      diag.initializingFormalForNonExistentField;

  /// Parameters:
  /// String p0: the name of the static member
  /// String p1: the kind of the static member (field, getter, setter, or
  ///            method)
  /// String p2: the name of the static member's enclosing element
  /// String p3: the kind of the static member's enclosing element (class,
  ///            mixin, or extension)
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required String p0,
      required String p1,
      required String p2,
      required String p3,
    })
  >
  instanceAccessToStaticMember = diag.instanceAccessToStaticMember;

  /// Parameters:
  /// Object p0: the name of the static member
  /// Object p1: the kind of the static member (field, getter, setter, or
  ///            method)
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  instanceAccessToStaticMemberOfUnnamedExtension =
      diag.instanceAccessToStaticMemberOfUnnamedExtension;

  /// No parameters.
  static const DiagnosticWithoutArguments instanceMemberAccessFromFactory =
      diag.instanceMemberAccessFromFactory;

  /// No parameters.
  static const DiagnosticWithoutArguments instanceMemberAccessFromStatic =
      diag.instanceMemberAccessFromStatic;

  /// No parameters.
  static const DiagnosticWithoutArguments instantiateAbstractClass =
      diag.instantiateAbstractClass;

  /// No parameters.
  static const DiagnosticWithoutArguments instantiateEnum =
      diag.instantiateEnum;

  /// No parameters.
  static const DiagnosticWithoutArguments
  instantiateTypeAliasExpandsToTypeParameter =
      diag.instantiateTypeAliasExpandsToTypeParameter;

  /// Parameters:
  /// String p0: the lexeme of the integer
  /// String p1: the closest valid double
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  integerLiteralImpreciseAsDouble = diag.integerLiteralImpreciseAsDouble;

  /// Parameters:
  /// String p0: the value of the literal
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  integerLiteralOutOfRange = diag.integerLiteralOutOfRange;

  /// Parameters:
  /// String p0: the name of the interface class being extended.
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  interfaceClassExtendedOutsideOfLibrary =
      diag.interfaceClassExtendedOutsideOfLibrary;

  /// No parameters.
  static const DiagnosticWithoutArguments invalidAnnotation =
      diag.invalidAnnotation;

  /// No parameters.
  static const DiagnosticWithoutArguments
  invalidAnnotationConstantValueFromDeferredLibrary =
      diag.invalidAnnotationConstantValueFromDeferredLibrary;

  /// No parameters.
  static const DiagnosticWithoutArguments invalidAnnotationFromDeferredLibrary =
      diag.invalidAnnotationFromDeferredLibrary;

  /// Parameters:
  /// Type p0: the name of the right hand side type
  /// Type p1: the name of the left hand side type
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  invalidAssignment = diag.invalidAssignment;

  /// This error is only reported in libraries which are not null safe.
  ///
  /// Parameters:
  /// Object p0: the name of the function
  /// Object p1: the type of the function
  /// Object p2: the expected function type
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required Object p0,
      required Object p1,
      required Object p2,
    })
  >
  invalidCastFunction = diag.invalidCastFunction;

  /// This error is only reported in libraries which are not null safe.
  ///
  /// Parameters:
  /// Object p0: the type of the torn-off function expression
  /// Object p1: the expected function type
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  invalidCastFunctionExpr = diag.invalidCastFunctionExpr;

  /// This error is only reported in libraries which are not null safe.
  ///
  /// Parameters:
  /// Object p0: the lexeme of the literal
  /// Object p1: the type of the literal
  /// Object p2: the expected type
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required Object p0,
      required Object p1,
      required Object p2,
    })
  >
  invalidCastLiteral = diag.invalidCastLiteral;

  /// This error is only reported in libraries which are not null safe.
  ///
  /// Parameters:
  /// Object p0: the type of the list literal
  /// Object p1: the expected type
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  invalidCastLiteralList = diag.invalidCastLiteralList;

  /// This error is only reported in libraries which are not null safe.
  ///
  /// Parameters:
  /// Object p0: the type of the map literal
  /// Object p1: the expected type
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  invalidCastLiteralMap = diag.invalidCastLiteralMap;

  /// This error is only reported in libraries which are not null safe.
  ///
  /// Parameters:
  /// Object p0: the type of the set literal
  /// Object p1: the expected type
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  invalidCastLiteralSet = diag.invalidCastLiteralSet;

  /// This error is only reported in libraries which are not null safe.
  ///
  /// Parameters:
  /// Object p0: the name of the torn-off method
  /// Object p1: the type of the torn-off method
  /// Object p2: the expected function type
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required Object p0,
      required Object p1,
      required Object p2,
    })
  >
  invalidCastMethod = diag.invalidCastMethod;

  /// This error is only reported in libraries which are not null safe.
  ///
  /// Parameters:
  /// Object p0: the type of the instantiated object
  /// Object p1: the expected type
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  invalidCastNewExpr = diag.invalidCastNewExpr;

  /// TODO(brianwilkerson): Remove this when we have decided on how to report
  /// errors in compile-time constants. Until then, this acts as a placeholder
  /// for more informative errors.
  ///
  /// See TODOs in ConstantVisitor
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments invalidConstant =
      diag.invalidConstant;

  /// No parameters.
  static const DiagnosticWithoutArguments invalidExtensionArgumentCount =
      diag.invalidExtensionArgumentCount;

  /// No parameters.
  static const DiagnosticWithoutArguments invalidFactoryNameNotAClass =
      diag.invalidFactoryNameNotAClass;

  /// No parameters.
  static const DiagnosticWithoutArguments invalidFieldNameFromObject =
      diag.invalidFieldNameFromObject;

  /// No parameters.
  static const DiagnosticWithoutArguments invalidFieldNamePositional =
      diag.invalidFieldNamePositional;

  /// No parameters.
  static const DiagnosticWithoutArguments invalidFieldNamePrivate =
      diag.invalidFieldNamePrivate;

  /// The parameters of this error code must be kept in sync with those of
  /// [diag.invalidOverride].
  ///
  /// Parameters:
  /// Object p0: the name of the declared member that is not a valid override.
  /// Object p1: the name of the interface that declares the member.
  /// Object p2: the type of the declared member in the interface.
  /// Object p3: the name of the interface with the overridden member.
  /// Object p4: the type of the overridden member.
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required Object p0,
      required Object p1,
      required Object p2,
      required Object p3,
      required Object p4,
    })
  >
  invalidImplementationOverride = diag.invalidImplementationOverride;

  /// The parameters of this error code must be kept in sync with those of
  /// [diag.invalidOverride].
  ///
  /// Parameters:
  /// Object p0: the name of the declared setter that is not a valid override.
  /// Object p1: the name of the interface that declares the setter.
  /// Object p2: the type of the declared setter in the interface.
  /// Object p3: the name of the interface with the overridden setter.
  /// Object p4: the type of the overridden setter.
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required Object p0,
      required Object p1,
      required Object p2,
      required Object p3,
      required Object p4,
    })
  >
  invalidImplementationOverrideSetter =
      diag.invalidImplementationOverrideSetter;

  /// No parameters.
  static const DiagnosticWithoutArguments invalidInlineFunctionType =
      diag.invalidInlineFunctionType;

  /// Parameters:
  /// String p0: the invalid modifier
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  invalidModifierOnConstructor = diag.invalidModifierOnConstructor;

  /// No parameters.
  static const DiagnosticWithoutArguments invalidModifierOnSetter =
      diag.invalidModifierOnSetter;

  /// Parameters:
  /// String p0: the name of the declared member that is not a valid override.
  /// String p1: the name of the interface that declares the member.
  /// Type p2: the type of the declared member in the interface.
  /// String p3: the name of the interface with the overridden member.
  /// Type p4: the type of the overridden member.
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required String p0,
      required String p1,
      required DartType p2,
      required String p3,
      required DartType p4,
    })
  >
  invalidOverride = diag.invalidOverride;

  /// Parameters:
  /// Object p0: the name of the declared setter that is not a valid override.
  /// Object p1: the name of the interface that declares the setter.
  /// Object p2: the type of the declared setter in the interface.
  /// Object p3: the name of the interface with the overridden setter.
  /// Object p4: the type of the overridden setter.
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required Object p0,
      required Object p1,
      required Object p2,
      required Object p3,
      required Object p4,
    })
  >
  invalidOverrideSetter = diag.invalidOverrideSetter;

  /// No parameters.
  static const DiagnosticWithoutArguments
  invalidReferenceToGenerativeEnumConstructor =
      diag.invalidReferenceToGenerativeEnumConstructor;

  /// No parameters.
  static const DiagnosticWithoutArguments
  invalidReferenceToGenerativeEnumConstructorTearoff =
      diag.invalidReferenceToGenerativeEnumConstructorTearoff;

  /// No parameters.
  static const DiagnosticWithoutArguments invalidReferenceToThis =
      diag.invalidReferenceToThis;

  /// No parameters.
  static const DiagnosticWithoutArguments invalidSuperFormalParameterLocation =
      diag.invalidSuperFormalParameterLocation;

  /// Parameters:
  /// Object p0: the name of the type parameter
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  invalidTypeArgumentInConstList = diag.invalidTypeArgumentInConstList;

  /// Parameters:
  /// Object p0: the name of the type parameter
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  invalidTypeArgumentInConstMap = diag.invalidTypeArgumentInConstMap;

  /// Parameters:
  /// String p0: the name of the type parameter
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  invalidTypeArgumentInConstSet = diag.invalidTypeArgumentInConstSet;

  /// Parameters:
  /// String p0: the URI that is invalid
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  invalidUri = diag.invalidUri;

  /// The 'covariant' keyword was found in an inappropriate location.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments invalidUseOfCovariant =
      diag.invalidUseOfCovariant;

  /// No parameters.
  static const DiagnosticWithoutArguments invalidUseOfNullValue =
      diag.invalidUseOfNullValue;

  /// Parameters:
  /// String p0: the name of the extension
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  invocationOfExtensionWithoutCall = diag.invocationOfExtensionWithoutCall;

  /// Parameters:
  /// String p0: the name of the identifier that is not a function type
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  invocationOfNonFunction = diag.invocationOfNonFunction;

  /// No parameters.
  static const DiagnosticWithoutArguments invocationOfNonFunctionExpression =
      diag.invocationOfNonFunctionExpression;

  /// Parameters:
  /// String p0: the name of the unresolvable label
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  labelInOuterScope = diag.labelInOuterScope;

  /// Parameters:
  /// String p0: the name of the unresolvable label
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  labelUndefined = diag.labelUndefined;

  /// No parameters.
  static const DiagnosticWithoutArguments lateFinalFieldWithConstConstructor =
      diag.lateFinalFieldWithConstConstructor;

  /// No parameters.
  static const DiagnosticWithoutArguments lateFinalLocalAlreadyAssigned =
      diag.lateFinalLocalAlreadyAssigned;

  /// Parameters:
  /// Type p0: the actual type of the list element
  /// Type p1: the expected type of the list element
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  listElementTypeNotAssignable = diag.listElementTypeNotAssignable;

  /// Parameters:
  /// Type p0: the actual type of the list element
  /// Type p1: the expected type of the list element
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  listElementTypeNotAssignableNullability =
      diag.listElementTypeNotAssignableNullability;

  /// No parameters.
  static const DiagnosticWithoutArguments mainFirstPositionalParameterType =
      diag.mainFirstPositionalParameterType;

  /// No parameters.
  static const DiagnosticWithoutArguments mainHasRequiredNamedParameters =
      diag.mainHasRequiredNamedParameters;

  /// No parameters.
  static const DiagnosticWithoutArguments
  mainHasTooManyRequiredPositionalParameters =
      diag.mainHasTooManyRequiredPositionalParameters;

  /// No parameters.
  static const DiagnosticWithoutArguments mainIsNotFunction =
      diag.mainIsNotFunction;

  /// No parameters.
  static const DiagnosticWithoutArguments mapEntryNotInMap =
      diag.mapEntryNotInMap;

  /// Parameters:
  /// Type p0: the type of the expression being used as a key
  /// Type p1: the type of keys declared for the map
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  mapKeyTypeNotAssignable = diag.mapKeyTypeNotAssignable;

  /// Parameters:
  /// Type p0: the type of the expression being used as a key
  /// Type p1: the type of keys declared for the map
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  mapKeyTypeNotAssignableNullability = diag.mapKeyTypeNotAssignableNullability;

  /// Parameters:
  /// Type p0: the type of the expression being used as a value
  /// Type p1: the type of values declared for the map
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  mapValueTypeNotAssignable = diag.mapValueTypeNotAssignable;

  /// Parameters:
  /// Type p0: the type of the expression being used as a value
  /// Type p1: the type of values declared for the map
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  mapValueTypeNotAssignableNullability =
      diag.mapValueTypeNotAssignableNullability;

  /// 12.1 Constants: A constant expression is ... a constant list literal.
  ///
  /// Note: This diagnostic is never displayed to the user, so it doesn't need
  /// to be documented.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments missingConstInListLiteral =
      diag.missingConstInListLiteral;

  /// 12.1 Constants: A constant expression is ... a constant map literal.
  ///
  /// Note: This diagnostic is never displayed to the user, so it doesn't need
  /// to be documented.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments missingConstInMapLiteral =
      diag.missingConstInMapLiteral;

  /// 12.1 Constants: A constant expression is ... a constant set literal.
  ///
  /// Note: This diagnostic is never displayed to the user, so it doesn't need
  /// to be documented.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments missingConstInSetLiteral =
      diag.missingConstInSetLiteral;

  /// Parameters:
  /// Object p0: the name of the library
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  missingDartLibrary = diag.missingDartLibrary;

  /// Parameters:
  /// String p0: the name of the parameter
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  missingDefaultValueForParameter = diag.missingDefaultValueForParameter;

  /// Parameters:
  /// String p0: the name of the parameter
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  missingDefaultValueForParameterPositional =
      diag.missingDefaultValueForParameterPositional;

  /// No parameters.
  static const DiagnosticWithoutArguments
  missingDefaultValueForParameterWithAnnotation =
      diag.missingDefaultValueForParameterWithAnnotation;

  /// No parameters.
  static const DiagnosticWithoutArguments missingNamedPatternFieldName =
      diag.missingNamedPatternFieldName;

  /// Parameters:
  /// String p0: the name of the parameter
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  missingRequiredArgument = diag.missingRequiredArgument;

  /// Parameters:
  /// String p0: the name of the variable pattern
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  missingVariablePattern = diag.missingVariablePattern;

  /// Parameters:
  /// String p0: the name of the super-invoked member
  /// Type p1: the display name of the type of the super-invoked member in the
  ///          mixin
  /// Type p2: the display name of the type of the concrete member in the class
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required String p0,
      required DartType p1,
      required DartType p2,
    })
  >
  mixinApplicationConcreteSuperInvokedMemberType =
      diag.mixinApplicationConcreteSuperInvokedMemberType;

  /// Parameters:
  /// String p0: the display name of the member without a concrete
  ///            implementation
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  mixinApplicationNoConcreteSuperInvokedMember =
      diag.mixinApplicationNoConcreteSuperInvokedMember;

  /// Parameters:
  /// String p0: the display name of the setter without a concrete
  ///            implementation
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  mixinApplicationNoConcreteSuperInvokedSetter =
      diag.mixinApplicationNoConcreteSuperInvokedSetter;

  /// Parameters:
  /// Type p0: the display name of the mixin
  /// Type p1: the display name of the superclass
  /// Type p2: the display name of the type that is not implemented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required DartType p0,
      required DartType p1,
      required DartType p2,
    })
  >
  mixinApplicationNotImplementedInterface =
      diag.mixinApplicationNotImplementedInterface;

  /// Parameters:
  /// String p0: the name of the mixin class that is invalid
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  mixinClassDeclarationExtendsNotObject =
      diag.mixinClassDeclarationExtendsNotObject;

  /// Parameters:
  /// String p0: the name of the mixin that is invalid
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  mixinClassDeclaresConstructor = diag.mixinClassDeclaresConstructor;

  /// No parameters.
  static const DiagnosticWithoutArguments mixinDeferredClass =
      diag.mixinDeferredClass;

  /// Parameters:
  /// String p0: the name of the mixin that is invalid
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  mixinInheritsFromNotObject = diag.mixinInheritsFromNotObject;

  /// No parameters.
  static const DiagnosticWithoutArguments mixinInstantiate =
      diag.mixinInstantiate;

  /// Parameters:
  /// Type p0: the name of the disallowed type
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required DartType p0})
  >
  mixinOfDisallowedClass = diag.mixinOfDisallowedClass;

  /// No parameters.
  static const DiagnosticWithoutArguments mixinOfNonClass =
      diag.mixinOfNonClass;

  /// No parameters.
  static const DiagnosticWithoutArguments
  mixinOfTypeAliasExpandsToTypeParameter =
      diag.mixinOfTypeAliasExpandsToTypeParameter;

  /// No parameters.
  static const DiagnosticWithoutArguments
  mixinOnTypeAliasExpandsToTypeParameter =
      diag.mixinOnTypeAliasExpandsToTypeParameter;

  /// Parameters:
  /// Element p0: the name of the class that appears in both "extends" and
  ///             "with" clauses
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Element p0})
  >
  mixinsSuperClass = diag.mixinsSuperClass;

  /// Parameters:
  /// String p0: the name of the mixin that is not 'base'
  /// String p1: the name of the 'base' supertype
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  mixinSubtypeOfBaseIsNotBase = diag.mixinSubtypeOfBaseIsNotBase;

  /// Parameters:
  /// String p0: the name of the mixin that is not 'final'
  /// String p1: the name of the 'final' supertype
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  mixinSubtypeOfFinalIsNotBase = diag.mixinSubtypeOfFinalIsNotBase;

  /// No parameters.
  static const DiagnosticWithoutArguments
  mixinSuperClassConstraintDeferredClass =
      diag.mixinSuperClassConstraintDeferredClass;

  /// Parameters:
  /// Type p0: the name of the disallowed type
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required DartType p0})
  >
  mixinSuperClassConstraintDisallowedClass =
      diag.mixinSuperClassConstraintDisallowedClass;

  /// No parameters.
  static const DiagnosticWithoutArguments
  mixinSuperClassConstraintNonInterface =
      diag.mixinSuperClassConstraintNonInterface;

  /// 9.1 Mixin Application: It is a compile-time error if <i>S</i> does not
  /// denote a class available in the immediately enclosing scope.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments mixinWithNonClassSuperclass =
      diag.mixinWithNonClassSuperclass;

  /// No parameters.
  static const DiagnosticWithoutArguments
  multipleRedirectingConstructorInvocations =
      diag.multipleRedirectingConstructorInvocations;

  /// No parameters.
  static const DiagnosticWithoutArguments multipleSuperInitializers =
      diag.multipleSuperInitializers;

  /// Parameters:
  /// String p0: the name of the non-type element
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  newWithNonType = diag.newWithNonType;

  /// 12.11.1 New: If <i>T</i> is a class or parameterized type accessible in the
  /// current scope then:
  /// 1. If <i>e</i> is of the form <i>new T.id(a<sub>1</sub>, &hellip;,
  ///    a<sub>n</sub>, x<sub>n+1</sub>: a<sub>n+1</sub>, &hellip;,
  ///    x<sub>n+k</sub>: a<sub>n+k</sub>)</i> it is a static warning if
  ///    <i>T.id</i> is not the name of a constructor declared by the type
  ///    <i>T</i>.
  /// If <i>e</i> of the form <i>new T(a<sub>1</sub>, &hellip;, a<sub>n</sub>,
  /// x<sub>n+1</sub>: a<sub>n+1</sub>, &hellip;, x<sub>n+k</sub>:
  /// a<sub>n+kM/sub>)</i> it is a static warning if the type <i>T</i> does not
  /// declare a constructor with the same name as the declaration of <i>T</i>.
  ///
  /// Parameters:
  /// String p0: the name of the class being instantiated
  /// String p1: the name of the constructor
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  newWithUndefinedConstructor = diag.newWithUndefinedConstructor;

  /// Parameters:
  /// String p0: the name of the class being instantiated
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  newWithUndefinedConstructorDefault = diag.newWithUndefinedConstructorDefault;

  /// No parameters.
  static const DiagnosticWithoutArguments noAnnotationConstructorArguments =
      diag.noAnnotationConstructorArguments;

  /// Parameters:
  /// String p0: the name of the class where override error was detected
  /// String p1: the list of candidate signatures which cannot be combined
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  noCombinedSuperSignature = diag.noCombinedSuperSignature;

  /// Parameters:
  /// Object p0: the name of the superclass that does not define an implicitly
  ///            invoked constructor
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  noDefaultSuperConstructorExplicit = diag.noDefaultSuperConstructorExplicit;

  /// Parameters:
  /// Type p0: the name of the superclass that does not define an implicitly
  ///          invoked constructor
  /// String p1: the name of the subclass that does not contain any explicit
  ///            constructors
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required DartType p0, required String p1})
  >
  noDefaultSuperConstructorImplicit = diag.noDefaultSuperConstructorImplicit;

  /// Parameters:
  /// String p0: the name of the subclass
  /// String p1: the name of the superclass
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  noGenerativeConstructorsInSuperclass =
      diag.noGenerativeConstructorsInSuperclass;

  /// Parameters:
  /// String p0: the name of the first member
  /// String p1: the name of the second member
  /// String p2: the name of the third member
  /// String p3: the name of the fourth member
  /// int p4: the number of additional missing members that aren't listed
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required String p0,
      required String p1,
      required String p2,
      required String p3,
      required int p4,
    })
  >
  nonAbstractClassInheritsAbstractMemberFivePlus =
      diag.nonAbstractClassInheritsAbstractMemberFivePlus;

  /// Parameters:
  /// String p0: the name of the first member
  /// String p1: the name of the second member
  /// String p2: the name of the third member
  /// String p3: the name of the fourth member
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required String p0,
      required String p1,
      required String p2,
      required String p3,
    })
  >
  nonAbstractClassInheritsAbstractMemberFour =
      diag.nonAbstractClassInheritsAbstractMemberFour;

  /// Parameters:
  /// String p0: the name of the member
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  nonAbstractClassInheritsAbstractMemberOne =
      diag.nonAbstractClassInheritsAbstractMemberOne;

  /// Parameters:
  /// String p0: the name of the first member
  /// String p1: the name of the second member
  /// String p2: the name of the third member
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required String p0,
      required String p1,
      required String p2,
    })
  >
  nonAbstractClassInheritsAbstractMemberThree =
      diag.nonAbstractClassInheritsAbstractMemberThree;

  /// Parameters:
  /// String p0: the name of the first member
  /// String p1: the name of the second member
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  nonAbstractClassInheritsAbstractMemberTwo =
      diag.nonAbstractClassInheritsAbstractMemberTwo;

  /// No parameters.
  static const DiagnosticWithoutArguments nonBoolCondition =
      diag.nonBoolCondition;

  /// No parameters.
  static const DiagnosticWithoutArguments nonBoolExpression =
      diag.nonBoolExpression;

  /// No parameters.
  static const DiagnosticWithoutArguments nonBoolNegationExpression =
      diag.nonBoolNegationExpression;

  /// Parameters:
  /// String p0: the lexeme of the logical operator
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  nonBoolOperand = diag.nonBoolOperand;

  /// No parameters.
  static const DiagnosticWithoutArguments nonConstantAnnotationConstructor =
      diag.nonConstantAnnotationConstructor;

  /// No parameters.
  static const DiagnosticWithoutArguments nonConstantCaseExpression =
      diag.nonConstantCaseExpression;

  /// No parameters.
  static const DiagnosticWithoutArguments
  nonConstantCaseExpressionFromDeferredLibrary =
      diag.nonConstantCaseExpressionFromDeferredLibrary;

  /// No parameters.
  static const DiagnosticWithoutArguments nonConstantDefaultValue =
      diag.nonConstantDefaultValue;

  /// No parameters.
  static const DiagnosticWithoutArguments
  nonConstantDefaultValueFromDeferredLibrary =
      diag.nonConstantDefaultValueFromDeferredLibrary;

  /// No parameters.
  static const DiagnosticWithoutArguments nonConstantListElement =
      diag.nonConstantListElement;

  /// No parameters.
  static const DiagnosticWithoutArguments
  nonConstantListElementFromDeferredLibrary =
      diag.nonConstantListElementFromDeferredLibrary;

  /// No parameters.
  static const DiagnosticWithoutArguments nonConstantMapElement =
      diag.nonConstantMapElement;

  /// No parameters.
  static const DiagnosticWithoutArguments nonConstantMapKey =
      diag.nonConstantMapKey;

  /// No parameters.
  static const DiagnosticWithoutArguments nonConstantMapKeyFromDeferredLibrary =
      diag.nonConstantMapKeyFromDeferredLibrary;

  /// No parameters.
  static const DiagnosticWithoutArguments nonConstantMapPatternKey =
      diag.nonConstantMapPatternKey;

  /// No parameters.
  static const DiagnosticWithoutArguments nonConstantMapValue =
      diag.nonConstantMapValue;

  /// No parameters.
  static const DiagnosticWithoutArguments
  nonConstantMapValueFromDeferredLibrary =
      diag.nonConstantMapValueFromDeferredLibrary;

  /// No parameters.
  static const DiagnosticWithoutArguments nonConstantRecordField =
      diag.nonConstantRecordField;

  /// No parameters.
  static const DiagnosticWithoutArguments
  nonConstantRecordFieldFromDeferredLibrary =
      diag.nonConstantRecordFieldFromDeferredLibrary;

  /// No parameters.
  static const DiagnosticWithoutArguments
  nonConstantRelationalPatternExpression =
      diag.nonConstantRelationalPatternExpression;

  /// No parameters.
  static const DiagnosticWithoutArguments nonConstantSetElement =
      diag.nonConstantSetElement;

  /// No parameters.
  static const DiagnosticWithoutArguments nonConstGenerativeEnumConstructor =
      diag.nonConstGenerativeEnumConstructor;

  /// 13.2 Expression Statements: It is a compile-time error if a non-constant
  /// map literal that has no explicit type arguments appears in a place where a
  /// statement is expected.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments nonConstMapAsExpressionStatement =
      diag.nonConstMapAsExpressionStatement;

  /// No parameters.
  static const DiagnosticWithoutArguments
  nonCovariantTypeParameterPositionInRepresentationType =
      diag.nonCovariantTypeParameterPositionInRepresentationType;

  /// Parameters:
  /// Type p0: the type of the switch scrutinee
  /// String p1: the witness pattern for the unmatched value
  /// String p2: the suggested pattern for the unmatched value
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required DartType p0,
      required String p1,
      required String p2,
    })
  >
  nonExhaustiveSwitchExpression = diag.nonExhaustiveSwitchExpression;

  /// Parameters:
  /// Type p0: the type of the switch scrutinee
  /// String p1: the witness pattern for the unmatched value
  /// String p2: the suggested pattern for the unmatched value
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required DartType p0,
      required String p1,
      required String p2,
    })
  >
  nonExhaustiveSwitchStatement = diag.nonExhaustiveSwitchStatement;

  /// No parameters.
  static const DiagnosticWithoutArguments nonFinalFieldInEnum =
      diag.nonFinalFieldInEnum;

  /// Parameters:
  /// Element p0: the non-generative constructor
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Element p0})
  >
  nonGenerativeConstructor = diag.nonGenerativeConstructor;

  /// Parameters:
  /// String p0: the name of the superclass
  /// String p1: the name of the current class
  /// Element p2: the implicitly called factory constructor of the superclass
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required String p0,
      required String p1,
      required Element p2,
    })
  >
  nonGenerativeImplicitConstructor = diag.nonGenerativeImplicitConstructor;

  /// No parameters.
  static const DiagnosticWithoutArguments nonSyncFactory = diag.nonSyncFactory;

  /// Parameters:
  /// String p0: the name appearing where a type is expected
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  nonTypeAsTypeArgument = diag.nonTypeAsTypeArgument;

  /// Parameters:
  /// String p0: the name of the non-type element
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  nonTypeInCatchClause = diag.nonTypeInCatchClause;

  /// No parameters.
  static const DiagnosticWithoutArguments nonVoidReturnForOperator =
      diag.nonVoidReturnForOperator;

  /// No parameters.
  static const DiagnosticWithoutArguments nonVoidReturnForSetter =
      diag.nonVoidReturnForSetter;

  /// Parameters:
  /// String p0: the name of the variable that is invalid
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  notAssignedPotentiallyNonNullableLocalVariable =
      diag.notAssignedPotentiallyNonNullableLocalVariable;

  /// Parameters:
  /// String p0: the name that is not a type
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  notAType = diag.notAType;

  /// Parameters:
  /// String p0: the name of the operator that is not a binary operator.
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  notBinaryOperator = diag.notBinaryOperator;

  /// Parameters:
  /// int p0: the expected number of required arguments
  /// int p1: the actual number of positional arguments given
  /// String p2: name of the function or method
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required int p0,
      required int p1,
      required String p2,
    })
  >
  notEnoughPositionalArgumentsNamePlural =
      diag.notEnoughPositionalArgumentsNamePlural;

  /// Parameters:
  /// String p0: name of the function or method
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  notEnoughPositionalArgumentsNameSingular =
      diag.notEnoughPositionalArgumentsNameSingular;

  /// Parameters:
  /// int p0: the expected number of required arguments
  /// int p1: the actual number of positional arguments given
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required int p0, required int p1})
  >
  notEnoughPositionalArgumentsPlural = diag.notEnoughPositionalArgumentsPlural;

  /// No parameters.
  static const DiagnosticWithoutArguments notEnoughPositionalArgumentsSingular =
      diag.notEnoughPositionalArgumentsSingular;

  /// Parameters:
  /// String p0: the name of the field that is not initialized
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  notInitializedNonNullableInstanceField =
      diag.notInitializedNonNullableInstanceField;

  /// Parameters:
  /// String p0: the name of the field that is not initialized
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  notInitializedNonNullableInstanceFieldConstructor =
      diag.notInitializedNonNullableInstanceFieldConstructor;

  /// Parameters:
  /// String p0: the name of the variable that is invalid
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  notInitializedNonNullableVariable = diag.notInitializedNonNullableVariable;

  /// No parameters.
  static const DiagnosticWithoutArguments notInstantiatedBound =
      diag.notInstantiatedBound;

  /// No parameters.
  static const DiagnosticWithoutArguments notIterableSpread =
      diag.notIterableSpread;

  /// No parameters.
  static const DiagnosticWithoutArguments notMapSpread = diag.notMapSpread;

  /// No parameters.
  static const DiagnosticWithoutArguments notNullAwareNullSpread =
      diag.notNullAwareNullSpread;

  /// No parameters.
  static const DiagnosticWithoutArguments nullableTypeInExtendsClause =
      diag.nullableTypeInExtendsClause;

  /// No parameters.
  static const DiagnosticWithoutArguments nullableTypeInImplementsClause =
      diag.nullableTypeInImplementsClause;

  /// No parameters.
  static const DiagnosticWithoutArguments nullableTypeInOnClause =
      diag.nullableTypeInOnClause;

  /// No parameters.
  static const DiagnosticWithoutArguments nullableTypeInWithClause =
      diag.nullableTypeInWithClause;

  /// 7.9 Superclasses: It is a compile-time error to specify an extends clause
  /// for class Object.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments objectCannotExtendAnotherClass =
      diag.objectCannotExtendAnotherClass;

  /// No parameters.
  static const DiagnosticWithoutArguments obsoleteColonForDefaultValue =
      diag.obsoleteColonForDefaultValue;

  /// Parameters:
  /// String p0: the name of the interface that is implemented more than once
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  onRepeated = diag.onRepeated;

  /// No parameters.
  static const DiagnosticWithoutArguments optionalParameterInOperator =
      diag.optionalParameterInOperator;

  /// Parameters:
  /// String p0: the name of expected library name
  /// String p1: the non-matching actual library name from the "part of"
  ///            declaration
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  partOfDifferentLibrary = diag.partOfDifferentLibrary;

  /// Parameters:
  /// String p0: the URI pointing to a non-library declaration
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  partOfNonPart = diag.partOfNonPart;

  /// Parameters:
  /// String p0: the non-matching actual library name from the "part of"
  ///            declaration
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  partOfUnnamedLibrary = diag.partOfUnnamedLibrary;

  /// No parameters.
  static const DiagnosticWithoutArguments patternAssignmentNotLocalVariable =
      diag.patternAssignmentNotLocalVariable;

  /// No parameters.
  static const DiagnosticWithoutArguments patternConstantFromDeferredLibrary =
      diag.patternConstantFromDeferredLibrary;

  /// Parameters:
  /// Type p0: the matched type
  /// Type p1: the required type
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  patternTypeMismatchInIrrefutableContext =
      diag.patternTypeMismatchInIrrefutableContext;

  /// No parameters.
  static const DiagnosticWithoutArguments patternVariableAssignmentInsideGuard =
      diag.patternVariableAssignmentInsideGuard;

  /// Parameters:
  /// String p0: the name of the pattern variable
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  patternVariableSharedCaseScopeDifferentFinalityOrType =
      diag.patternVariableSharedCaseScopeDifferentFinalityOrType;

  /// Parameters:
  /// String p0: the name of the pattern variable
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  patternVariableSharedCaseScopeHasLabel =
      diag.patternVariableSharedCaseScopeHasLabel;

  /// Parameters:
  /// String p0: the name of the pattern variable
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  patternVariableSharedCaseScopeNotAllCases =
      diag.patternVariableSharedCaseScopeNotAllCases;

  /// No parameters.
  static const DiagnosticWithoutArguments positionalFieldInObjectPattern =
      diag.positionalFieldInObjectPattern;

  /// No parameters.
  static const DiagnosticWithoutArguments
  positionalSuperFormalParameterWithPositionalArgument =
      diag.positionalSuperFormalParameterWithPositionalArgument;

  /// Parameters:
  /// Object p0: the name of the prefix
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  prefixCollidesWithTopLevelMember = diag.prefixCollidesWithTopLevelMember;

  /// Parameters:
  /// String p0: the name of the prefix
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  prefixIdentifierNotFollowedByDot = diag.prefixIdentifierNotFollowedByDot;

  /// Parameters:
  /// String p0: the prefix being shadowed
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  prefixShadowedByLocalDeclaration = diag.prefixShadowedByLocalDeclaration;

  /// Parameters:
  /// String p0: the private name that collides
  /// String p1: the name of the first mixin
  /// String p2: the name of the second mixin
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required String p0,
      required String p1,
      required String p2,
    })
  >
  privateCollisionInMixinApplication = diag.privateCollisionInMixinApplication;

  /// No parameters.
  static const DiagnosticWithoutArguments
  privateNamedParameterWithoutPublicName =
      diag.privateNamedParameterWithoutPublicName;

  /// Parameters:
  /// String p0: the name of the setter
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  privateSetter = diag.privateSetter;

  /// Parameters:
  /// String p0: the name of the variable
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  readPotentiallyUnassignedFinal = diag.readPotentiallyUnassignedFinal;

  /// This is similar to
  /// ParserErrorCode.recordLiteralOnePositionalNoTrailingComma, but
  /// it is reported at type analysis time, based on a type
  /// incompatibility, rather than at parse time.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments
  recordLiteralOnePositionalNoTrailingCommaByType =
      diag.recordLiteralOnePositionalNoTrailingCommaByType;

  /// No parameters.
  static const DiagnosticWithoutArguments recursiveCompileTimeConstant =
      diag.recursiveCompileTimeConstant;

  /// No parameters.
  static const DiagnosticWithoutArguments recursiveConstantConstructor =
      diag.recursiveConstantConstructor;

  /// TODO(scheglov): review this later, there are no explicit "it is a
  /// compile-time error" in specification. But it was added to the co19 and
  /// there is same error for factories.
  ///
  /// https://code.google.com/p/dart/issues/detail?id=954
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments recursiveConstructorRedirect =
      diag.recursiveConstructorRedirect;

  /// No parameters.
  static const DiagnosticWithoutArguments recursiveFactoryRedirect =
      diag.recursiveFactoryRedirect;

  /// Parameters:
  /// String p0: the name of the class that implements itself recursively
  /// String p1: a string representation of the implements loop
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  recursiveInterfaceInheritance = diag.recursiveInterfaceInheritance;

  /// 7.10 Superinterfaces: It is a compile-time error if the interface of a
  /// class <i>C</i> is a superinterface of itself.
  ///
  /// 8.1 Superinterfaces: It is a compile-time error if an interface is a
  /// superinterface of itself.
  ///
  /// 7.9 Superclasses: It is a compile-time error if a class <i>C</i> is a
  /// superclass of itself.
  ///
  /// Parameters:
  /// String p0: the name of the class that implements itself recursively
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  recursiveInterfaceInheritanceExtends =
      diag.recursiveInterfaceInheritanceExtends;

  /// 7.10 Superinterfaces: It is a compile-time error if the interface of a
  /// class <i>C</i> is a superinterface of itself.
  ///
  /// 8.1 Superinterfaces: It is a compile-time error if an interface is a
  /// superinterface of itself.
  ///
  /// 7.9 Superclasses: It is a compile-time error if a class <i>C</i> is a
  /// superclass of itself.
  ///
  /// Parameters:
  /// String p0: the name of the class that implements itself recursively
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  recursiveInterfaceInheritanceImplements =
      diag.recursiveInterfaceInheritanceImplements;

  /// Parameters:
  /// String p0: the name of the mixin that constraints itself recursively
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  recursiveInterfaceInheritanceOn = diag.recursiveInterfaceInheritanceOn;

  /// 7.10 Superinterfaces: It is a compile-time error if the interface of a
  /// class <i>C</i> is a superinterface of itself.
  ///
  /// 8.1 Superinterfaces: It is a compile-time error if an interface is a
  /// superinterface of itself.
  ///
  /// 7.9 Superclasses: It is a compile-time error if a class <i>C</i> is a
  /// superclass of itself.
  ///
  /// Parameters:
  /// String p0: the name of the class that implements itself recursively
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  recursiveInterfaceInheritanceWith = diag.recursiveInterfaceInheritanceWith;

  /// Parameters:
  /// String p0: the name of the constructor
  /// String p1: the name of the class
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  redirectGenerativeToMissingConstructor =
      diag.redirectGenerativeToMissingConstructor;

  /// No parameters.
  static const DiagnosticWithoutArguments
  redirectGenerativeToNonGenerativeConstructor =
      diag.redirectGenerativeToNonGenerativeConstructor;

  /// Parameters:
  /// String p0: the name of the redirecting constructor
  /// String p1: the name of the abstract class defining the constructor being
  ///            redirected to
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  redirectToAbstractClassConstructor = diag.redirectToAbstractClassConstructor;

  /// Parameters:
  /// Type p0: the name of the redirected constructor
  /// Type p1: the name of the redirecting constructor
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  redirectToInvalidFunctionType = diag.redirectToInvalidFunctionType;

  /// Parameters:
  /// Type p0: the name of the redirected constructor's return type
  /// Type p1: the name of the redirecting constructor's return type
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  redirectToInvalidReturnType = diag.redirectToInvalidReturnType;

  /// Parameters:
  /// String p0: the name of the constructor
  /// Type p1: the name of the class containing the constructor
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required DartType p1})
  >
  redirectToMissingConstructor = diag.redirectToMissingConstructor;

  /// Parameters:
  /// String p0: the name of the non-type referenced in the redirect
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  redirectToNonClass = diag.redirectToNonClass;

  /// No parameters.
  static const DiagnosticWithoutArguments redirectToNonConstConstructor =
      diag.redirectToNonConstConstructor;

  /// No parameters.
  static const DiagnosticWithoutArguments
  redirectToTypeAliasExpandsToTypeParameter =
      diag.redirectToTypeAliasExpandsToTypeParameter;

  /// Parameters:
  /// Object p0: the name of the variable
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  referencedBeforeDeclaration = diag.referencedBeforeDeclaration;

  /// No parameters.
  static const DiagnosticWithoutArguments refutablePatternInIrrefutableContext =
      diag.refutablePatternInIrrefutableContext;

  /// Parameters:
  /// Type p0: the operand type
  /// Type p1: the parameter type of the invoked operator
  /// String p2: the name of the invoked operator
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required DartType p0,
      required DartType p1,
      required String p2,
    })
  >
  relationalPatternOperandTypeNotAssignable =
      diag.relationalPatternOperandTypeNotAssignable;

  /// No parameters.
  static const DiagnosticWithoutArguments
  relationalPatternOperatorReturnTypeNotAssignableToBool =
      diag.relationalPatternOperatorReturnTypeNotAssignableToBool;

  /// No parameters.
  static const DiagnosticWithoutArguments restElementInMapPattern =
      diag.restElementInMapPattern;

  /// No parameters.
  static const DiagnosticWithoutArguments rethrowOutsideCatch =
      diag.rethrowOutsideCatch;

  /// No parameters.
  static const DiagnosticWithoutArguments returnInGenerativeConstructor =
      diag.returnInGenerativeConstructor;

  /// No parameters.
  static const DiagnosticWithoutArguments returnInGenerator =
      diag.returnInGenerator;

  /// Parameters:
  /// Type p0: the return type as declared in the return statement
  /// Type p1: the expected return type as defined by the method
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  returnOfInvalidTypeFromClosure = diag.returnOfInvalidTypeFromClosure;

  /// Parameters:
  /// Type p0: the return type as declared in the return statement
  /// Type p1: the expected return type as defined by the enclosing class
  /// String p2: the name of the constructor
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required DartType p0,
      required DartType p1,
      required String p2,
    })
  >
  returnOfInvalidTypeFromConstructor = diag.returnOfInvalidTypeFromConstructor;

  /// Parameters:
  /// Type p0: the return type as declared in the return statement
  /// Type p1: the expected return type as defined by the method
  /// String p2: the name of the method
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required DartType p0,
      required DartType p1,
      required String p2,
    })
  >
  returnOfInvalidTypeFromFunction = diag.returnOfInvalidTypeFromFunction;

  /// Parameters:
  /// Type p0: the type of the expression in the return statement
  /// Type p1: the expected return type as defined by the method
  /// String p2: the name of the method
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required DartType p0,
      required DartType p1,
      required String p2,
    })
  >
  returnOfInvalidTypeFromMethod = diag.returnOfInvalidTypeFromMethod;

  /// No parameters.
  static const DiagnosticWithoutArguments returnWithoutValue =
      diag.returnWithoutValue;

  /// Parameters:
  /// String p0: the name of the sealed class being extended, implemented, or
  ///            mixed in
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  sealedClassSubtypeOutsideOfLibrary = diag.sealedClassSubtypeOutsideOfLibrary;

  /// No parameters.
  static const DiagnosticWithoutArguments setElementFromDeferredLibrary =
      diag.setElementFromDeferredLibrary;

  /// Parameters:
  /// Type p0: the actual type of the set element
  /// Type p1: the expected type of the set element
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  setElementTypeNotAssignable = diag.setElementTypeNotAssignable;

  /// Parameters:
  /// Type p0: the actual type of the set element
  /// Type p1: the expected type of the set element
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  setElementTypeNotAssignableNullability =
      diag.setElementTypeNotAssignableNullability;

  /// No parameters.
  static const DiagnosticWithoutArguments sharedDeferredPrefix =
      diag.sharedDeferredPrefix;

  /// No parameters.
  static const DiagnosticWithoutArguments spreadExpressionFromDeferredLibrary =
      diag.spreadExpressionFromDeferredLibrary;

  /// Parameters:
  /// String p0: the name of the instance member
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  staticAccessToInstanceMember = diag.staticAccessToInstanceMember;

  /// Parameters:
  /// String p0: the name of the subtype that is not 'base', 'final', or
  ///            'sealed'
  /// String p1: the name of the 'base' supertype
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  subtypeOfBaseIsNotBaseFinalOrSealed =
      diag.subtypeOfBaseIsNotBaseFinalOrSealed;

  /// Parameters:
  /// String p0: the name of the subtype that is not 'base', 'final', or
  ///            'sealed'
  /// String p1: the name of the 'final' supertype
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  subtypeOfFinalIsNotBaseFinalOrSealed =
      diag.subtypeOfFinalIsNotBaseFinalOrSealed;

  /// Parameters:
  /// Type p0: the type of super-parameter
  /// Type p1: the type of associated super-constructor parameter
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  superFormalParameterTypeIsNotSubtypeOfAssociated =
      diag.superFormalParameterTypeIsNotSubtypeOfAssociated;

  /// No parameters.
  static const DiagnosticWithoutArguments
  superFormalParameterWithoutAssociatedNamed =
      diag.superFormalParameterWithoutAssociatedNamed;

  /// No parameters.
  static const DiagnosticWithoutArguments
  superFormalParameterWithoutAssociatedPositional =
      diag.superFormalParameterWithoutAssociatedPositional;

  /// No parameters.
  static const DiagnosticWithoutArguments superInEnumConstructor =
      diag.superInEnumConstructor;

  /// No parameters.
  static const DiagnosticWithoutArguments superInExtension =
      diag.superInExtension;

  /// No parameters.
  static const DiagnosticWithoutArguments superInExtensionType =
      diag.superInExtensionType;

  /// No parameters.
  static const DiagnosticWithoutArguments superInInvalidContext =
      diag.superInInvalidContext;

  /// 7.6.1 Generative Constructors: Let <i>k</i> be a generative constructor. It
  /// is a compile-time error if a generative constructor of class Object
  /// includes a superinitializer.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments superInitializerInObject =
      diag.superInitializerInObject;

  /// No parameters.
  static const DiagnosticWithoutArguments superInRedirectingConstructor =
      diag.superInRedirectingConstructor;

  /// Parameters:
  /// String p0: the superinitializer
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  superInvocationNotLast = diag.superInvocationNotLast;

  /// No parameters.
  static const DiagnosticWithoutArguments switchCaseCompletesNormally =
      diag.switchCaseCompletesNormally;

  /// No parameters.
  static const DiagnosticWithoutArguments
  tearoffOfGenerativeConstructorOfAbstractClass =
      diag.tearoffOfGenerativeConstructorOfAbstractClass;

  /// Parameters:
  /// Type p0: the type that can't be thrown
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required DartType p0})
  >
  throwOfInvalidType = diag.throwOfInvalidType;

  /// Parameters:
  /// String p0: the element whose type could not be inferred.
  /// String p1: The [TopLevelInferenceError]'s arguments that led to the cycle.
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  topLevelCycle = diag.topLevelCycle;

  /// No parameters.
  static const DiagnosticWithoutArguments typeAliasCannotReferenceItself =
      diag.typeAliasCannotReferenceItself;

  /// Parameters:
  /// String p0: the name of the type that is deferred and being used in a type
  ///            annotation
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  typeAnnotationDeferredClass = diag.typeAnnotationDeferredClass;

  /// Parameters:
  /// Type p0: the name of the type used in the instance creation that should be
  ///          limited by the bound as specified in the class declaration
  /// String p1: the name of the type parameter
  /// Type p2: the substituted bound of the type parameter
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required DartType p0,
      required String p1,
      required DartType p2,
    })
  >
  typeArgumentNotMatchingBounds = diag.typeArgumentNotMatchingBounds;

  /// No parameters.
  static const DiagnosticWithoutArguments typeParameterReferencedByStatic =
      diag.typeParameterReferencedByStatic;

  /// See [diag.typeArgumentNotMatchingBounds].
  ///
  /// Parameters:
  /// String p0: the name of the type parameter
  /// Type p1: the name of the bounding type
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required DartType p1})
  >
  typeParameterSupertypeOfItsBound = diag.typeParameterSupertypeOfItsBound;

  /// Parameters:
  /// String p0: the name of the type
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  typeTestWithNonType = diag.typeTestWithNonType;

  /// Parameters:
  /// String p0: the name of the type
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  typeTestWithUndefinedName = diag.typeTestWithUndefinedName;

  /// No parameters.
  static const DiagnosticWithoutArguments uncheckedInvocationOfNullableValue =
      diag.uncheckedInvocationOfNullableValue;

  /// Parameters:
  /// String p0: the name of the method
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  uncheckedMethodInvocationOfNullableValue =
      diag.uncheckedMethodInvocationOfNullableValue;

  /// Parameters:
  /// String p0: the name of the operator
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  uncheckedOperatorInvocationOfNullableValue =
      diag.uncheckedOperatorInvocationOfNullableValue;

  /// Parameters:
  /// String p0: the name of the property
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  uncheckedPropertyAccessOfNullableValue =
      diag.uncheckedPropertyAccessOfNullableValue;

  /// No parameters.
  static const DiagnosticWithoutArguments
  uncheckedUseOfNullableValueAsCondition =
      diag.uncheckedUseOfNullableValueAsCondition;

  /// No parameters.
  static const DiagnosticWithoutArguments
  uncheckedUseOfNullableValueAsIterator =
      diag.uncheckedUseOfNullableValueAsIterator;

  /// No parameters.
  static const DiagnosticWithoutArguments uncheckedUseOfNullableValueInSpread =
      diag.uncheckedUseOfNullableValueInSpread;

  /// No parameters.
  static const DiagnosticWithoutArguments
  uncheckedUseOfNullableValueInYieldEach =
      diag.uncheckedUseOfNullableValueInYieldEach;

  /// Parameters:
  /// String p0: the name of the annotation
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  undefinedAnnotation = diag.undefinedAnnotation;

  /// Parameters:
  /// String p0: the name of the undefined class
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  undefinedClass = diag.undefinedClass;

  /// Same as [diag.undefinedClass], but to catch using
  /// "boolean" instead of "bool" in order to improve the correction message.
  ///
  /// Parameters:
  /// String p0: the name of the undefined class
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  undefinedClassBoolean = diag.undefinedClassBoolean;

  /// Parameters:
  /// Type p0: the name of the superclass that does not define the invoked
  ///          constructor
  /// String p1: the name of the constructor being invoked
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required DartType p0, required String p1})
  >
  undefinedConstructorInInitializer = diag.undefinedConstructorInInitializer;

  /// Parameters:
  /// Object p0: the name of the superclass that does not define the invoked
  ///            constructor
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  undefinedConstructorInInitializerDefault =
      diag.undefinedConstructorInInitializerDefault;

  /// Parameters:
  /// String p0: the name of the enum value that is not defined
  /// String p1: the name of the enum used to access the constant
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  undefinedEnumConstant = diag.undefinedEnumConstant;

  /// Parameters:
  /// String p0: the name of the constructor that is undefined
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  undefinedEnumConstructorNamed = diag.undefinedEnumConstructorNamed;

  /// No parameters.
  static const DiagnosticWithoutArguments undefinedEnumConstructorUnnamed =
      diag.undefinedEnumConstructorUnnamed;

  /// Parameters:
  /// String p0: the name of the getter that is undefined
  /// String p1: the name of the extension that was explicitly specified
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  undefinedExtensionGetter = diag.undefinedExtensionGetter;

  /// Parameters:
  /// String p0: the name of the method that is undefined
  /// String p1: the name of the extension that was explicitly specified
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  undefinedExtensionMethod = diag.undefinedExtensionMethod;

  /// Parameters:
  /// String p0: the name of the operator that is undefined
  /// String p1: the name of the extension that was explicitly specified
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  undefinedExtensionOperator = diag.undefinedExtensionOperator;

  /// Parameters:
  /// String p0: the name of the setter that is undefined
  /// String p1: the name of the extension that was explicitly specified
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  undefinedExtensionSetter = diag.undefinedExtensionSetter;

  /// Parameters:
  /// String p0: the name of the method that is undefined
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  undefinedFunction = diag.undefinedFunction;

  /// Parameters:
  /// String p0: the name of the getter
  /// Object p1: the name of the enclosing type where the getter is being looked
  ///            for
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required Object p1})
  >
  undefinedGetter = diag.undefinedGetter;

  /// Parameters:
  /// String p0: the name of the getter
  /// String p1: the name of the function type alias
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  undefinedGetterOnFunctionType = diag.undefinedGetterOnFunctionType;

  /// Parameters:
  /// String p0: the name of the identifier
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  undefinedIdentifier = diag.undefinedIdentifier;

  /// No parameters.
  static const DiagnosticWithoutArguments undefinedIdentifierAwait =
      diag.undefinedIdentifierAwait;

  /// Parameters:
  /// String p0: the name of the method that is undefined
  /// Object p1: the resolved type name that the method lookup is happening on
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required Object p1})
  >
  undefinedMethod = diag.undefinedMethod;

  /// Parameters:
  /// String p0: the name of the method
  /// String p1: the name of the function type alias
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  undefinedMethodOnFunctionType = diag.undefinedMethodOnFunctionType;

  /// Parameters:
  /// String p0: the name of the requested named parameter
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  undefinedNamedParameter = diag.undefinedNamedParameter;

  /// Parameters:
  /// String p0: the name of the operator
  /// Type p1: the name of the enclosing type where the operator is being looked
  ///          for
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required DartType p1})
  >
  undefinedOperator = diag.undefinedOperator;

  /// Parameters:
  /// String p0: the name of the reference
  /// String p1: the name of the prefix
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  undefinedPrefixedName = diag.undefinedPrefixedName;

  /// Parameters:
  /// String p0: the name of the setter
  /// Type p1: the name of the enclosing type where the setter is being looked
  ///          for
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required DartType p1})
  >
  undefinedSetter = diag.undefinedSetter;

  /// Parameters:
  /// String p0: the name of the setter
  /// String p1: the name of the function type alias
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  undefinedSetterOnFunctionType = diag.undefinedSetterOnFunctionType;

  /// Parameters:
  /// String p0: the name of the getter
  /// Type p1: the name of the enclosing type where the getter is being looked
  ///          for
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required DartType p1})
  >
  undefinedSuperGetter = diag.undefinedSuperGetter;

  /// Parameters:
  /// String p0: the name of the method that is undefined
  /// String p1: the resolved type name that the method lookup is happening on
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  undefinedSuperMethod = diag.undefinedSuperMethod;

  /// Parameters:
  /// String p0: the name of the operator
  /// Type p1: the name of the enclosing type where the operator is being looked
  ///          for
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required DartType p1})
  >
  undefinedSuperOperator = diag.undefinedSuperOperator;

  /// Parameters:
  /// String p0: the name of the setter
  /// Type p1: the name of the enclosing type where the setter is being looked
  ///          for
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required DartType p1})
  >
  undefinedSuperSetter = diag.undefinedSuperSetter;

  /// This is a specialization of [instanceAccessToStaticMember] that is used
  /// when we are able to find the name defined in a supertype. It exists to
  /// provide a more informative error message.
  ///
  /// Parameters:
  /// String p0: the name of the defining type
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  unqualifiedReferenceToNonLocalStaticMember =
      diag.unqualifiedReferenceToNonLocalStaticMember;

  /// Parameters:
  /// String p0: the name of the defining type
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  unqualifiedReferenceToStaticMemberOfExtendedType =
      diag.unqualifiedReferenceToStaticMemberOfExtendedType;

  /// Parameters:
  /// String p0: the URI pointing to a nonexistent file
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  uriDoesNotExist = diag.uriDoesNotExist;

  /// Parameters:
  /// String p0: the URI pointing to a nonexistent file
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  uriHasNotBeenGenerated = diag.uriHasNotBeenGenerated;

  /// No parameters.
  static const DiagnosticWithoutArguments uriWithInterpolation =
      diag.uriWithInterpolation;

  /// No parameters.
  static const DiagnosticWithoutArguments useOfNativeExtension =
      diag.useOfNativeExtension;

  /// No parameters.
  static const DiagnosticWithoutArguments useOfVoidResult =
      diag.useOfVoidResult;

  /// No parameters.
  static const DiagnosticWithoutArguments valuesDeclarationInEnum =
      diag.valuesDeclarationInEnum;

  /// Parameters:
  /// Object valueType: the type of the object being assigned.
  /// Object variableType: the type of the variable being assigned to
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required Object valueType,
      required Object variableType,
    })
  >
  variableTypeMismatch = diag.variableTypeMismatch;

  /// Let `C` be a generic class that declares a formal type parameter `X`, and
  /// assume that `T` is a direct superinterface of `C`.
  ///
  /// It is a compile-time error if `X` is explicitly defined as a covariant or
  /// 'in' type parameter and `X` occurs in a non-covariant position in `T`.
  /// It is a compile-time error if `X` is explicitly defined as a contravariant
  /// or 'out' type parameter and `X` occurs in a non-contravariant position in
  /// `T`.
  ///
  /// Parameters:
  /// Object p0: the name of the type parameter
  /// Object p1: the variance modifier defined for {0}
  /// Object p2: the variance position of the type parameter {0} in the
  ///            superinterface {3}
  /// Object p3: the name of the superinterface
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required Object p0,
      required Object p1,
      required Object p2,
      required Object p3,
    })
  >
  wrongExplicitTypeParameterVarianceInSuperinterface =
      diag.wrongExplicitTypeParameterVarianceInSuperinterface;

  /// Parameters:
  /// String p0: the name of the declared operator
  /// int p1: the number of parameters expected
  /// int p2: the number of parameters found in the operator declaration
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required String p0,
      required int p1,
      required int p2,
    })
  >
  wrongNumberOfParametersForOperator = diag.wrongNumberOfParametersForOperator;

  /// 7.1.1 Operators: It is a compile time error if the arity of the
  /// user-declared operator - is not 0 or 1.
  ///
  /// Parameters:
  /// int p0: the number of parameters found in the operator declaration
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required int p0})
  >
  wrongNumberOfParametersForOperatorMinus =
      diag.wrongNumberOfParametersForOperatorMinus;

  /// Parameters:
  /// Object p0: the name of the type being referenced (<i>G</i>)
  /// int p1: the number of type parameters that were declared
  /// int p2: the number of type arguments provided
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required Object p0,
      required int p1,
      required int p2,
    })
  >
  wrongNumberOfTypeArguments = diag.wrongNumberOfTypeArguments;

  /// Parameters:
  /// int typeParameterCount: the number of type parameters that were declared
  /// int typeArgumentCount: the number of type arguments provided
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required int typeParameterCount,
      required int typeArgumentCount,
    })
  >
  wrongNumberOfTypeArgumentsAnonymousFunction =
      diag.wrongNumberOfTypeArgumentsAnonymousFunction;

  /// Parameters:
  /// String p0: the name of the class being instantiated
  /// String p1: the name of the constructor being invoked
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  wrongNumberOfTypeArgumentsConstructor =
      diag.wrongNumberOfTypeArgumentsConstructor;

  /// Parameters:
  /// String p0: the name of the class being instantiated
  /// String p1: the name of the constructor being invoked
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  wrongNumberOfTypeArgumentsDotShorthandConstructor =
      diag.wrongNumberOfTypeArgumentsDotShorthandConstructor;

  /// Parameters:
  /// int p0: the number of type parameters that were declared
  /// int p1: the number of type arguments provided
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required int p0, required int p1})
  >
  wrongNumberOfTypeArgumentsEnum = diag.wrongNumberOfTypeArgumentsEnum;

  /// Parameters:
  /// String p0: the name of the extension being referenced
  /// int p1: the number of type parameters that were declared
  /// int p2: the number of type arguments provided
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required String p0,
      required int p1,
      required int p2,
    })
  >
  wrongNumberOfTypeArgumentsExtension =
      diag.wrongNumberOfTypeArgumentsExtension;

  /// Parameters:
  /// String functionName: the name of the function being referenced
  /// int typeParameterCount: the number of type parameters that were declared
  /// int typeArgumentCount: the number of type arguments provided
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required String functionName,
      required int typeParameterCount,
      required int typeArgumentCount,
    })
  >
  wrongNumberOfTypeArgumentsFunction = diag.wrongNumberOfTypeArgumentsFunction;

  /// Parameters:
  /// Type p0: the name of the method being referenced (<i>G</i>)
  /// int p1: the number of type parameters that were declared
  /// int p2: the number of type arguments provided
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required DartType p0,
      required int p1,
      required int p2,
    })
  >
  wrongNumberOfTypeArgumentsMethod = diag.wrongNumberOfTypeArgumentsMethod;

  /// Let `C` be a generic class that declares a formal type parameter `X`, and
  /// assume that `T` is a direct superinterface of `C`. It is a compile-time
  /// error if `X` occurs contravariantly or invariantly in `T`.
  ///
  /// Parameters:
  /// String p0: the name of the type parameter
  /// Type p1: the name of the super interface
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required DartType p1})
  >
  wrongTypeParameterVarianceInSuperinterface =
      diag.wrongTypeParameterVarianceInSuperinterface;

  /// Let `C` be a generic class that declares a formal type parameter `X`.
  ///
  /// If `X` is explicitly contravariant then it is a compile-time error for
  /// `X` to occur in a non-contravariant position in a member signature in the
  /// body of `C`, except when `X` is in a contravariant position in the type
  /// annotation of a covariant formal parameter.
  ///
  /// If `X` is explicitly covariant then it is a compile-time error for
  /// `X` to occur in a non-covariant position in a member signature in the
  /// body of `C`, except when `X` is in a covariant position in the type
  /// annotation of a covariant formal parameter.
  ///
  /// Parameters:
  /// Object p0: the variance modifier defined for {0}
  /// Object p1: the name of the type parameter
  /// Object p2: the variance position that the type parameter {1} is in
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required Object p0,
      required Object p1,
      required Object p2,
    })
  >
  wrongTypeParameterVariancePosition = diag.wrongTypeParameterVariancePosition;

  /// No parameters.
  static const DiagnosticWithoutArguments yieldEachInNonGenerator =
      diag.yieldEachInNonGenerator;

  /// Parameters:
  /// Type p0: the type of the expression after `yield*`
  /// Type p1: the return type of the function containing the `yield*`
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  yieldEachOfInvalidType = diag.yieldEachOfInvalidType;

  /// ?? Yield: It is a compile-time error if a yield statement appears in a
  /// function that is not a generator function.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments yieldInNonGenerator =
      diag.yieldInNonGenerator;

  /// Parameters:
  /// Type p0: the type of the expression after `yield`
  /// Type p1: the return type of the function containing the `yield`
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  yieldOfInvalidType = diag.yieldOfInvalidType;

  /// Do not construct instances of this class.
  CompileTimeErrorCode._() : assert(false);
}

class StaticWarningCode {
  /// No parameters.
  static const DiagnosticWithoutArguments deadNullAwareExpression =
      diag.deadNullAwareExpression;

  /// No parameters.
  static const DiagnosticWithoutArguments invalidNullAwareElement =
      diag.invalidNullAwareElement;

  /// No parameters.
  static const DiagnosticWithoutArguments invalidNullAwareMapEntryKey =
      diag.invalidNullAwareMapEntryKey;

  /// No parameters.
  static const DiagnosticWithoutArguments invalidNullAwareMapEntryValue =
      diag.invalidNullAwareMapEntryValue;

  /// Parameters:
  /// String p0: the null-aware operator that is invalid
  /// String p1: the non-null-aware operator that can replace the invalid
  ///            operator
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  invalidNullAwareOperator = diag.invalidNullAwareOperator;

  /// Parameters:
  /// Object p0: the null-aware operator that is invalid
  /// Object p1: the non-null-aware operator that can replace the invalid
  ///            operator
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  invalidNullAwareOperatorAfterShortCircuit =
      diag.invalidNullAwareOperatorAfterShortCircuit;

  /// Parameters:
  /// String p0: the name of the constant that is missing
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  missingEnumConstantInSwitch = diag.missingEnumConstantInSwitch;

  /// No parameters.
  static const DiagnosticWithoutArguments unnecessaryNonNullAssertion =
      diag.unnecessaryNonNullAssertion;

  /// No parameters.
  static const DiagnosticWithoutArguments unnecessaryNullAssertPattern =
      diag.unnecessaryNullAssertPattern;

  /// No parameters.
  static const DiagnosticWithoutArguments unnecessaryNullCheckPattern =
      diag.unnecessaryNullCheckPattern;

  /// Do not construct instances of this class.
  StaticWarningCode._() : assert(false);
}

class WarningCode {
  /// Parameters:
  /// Type p0: the name of the actual argument type
  /// Type p1: the name of the expected function return type
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  argumentTypeNotAssignableToErrorHandler =
      diag.argumentTypeNotAssignableToErrorHandler;

  /// Users should not assign values marked `@doNotStore`.
  ///
  /// Parameters:
  /// String p0: the name of the field or variable
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  assignmentOfDoNotStore = diag.assignmentOfDoNotStore;

  /// Parameters:
  /// Type p0: the return type as derived by the type of the [Future].
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required DartType p0})
  >
  bodyMightCompleteNormallyCatchError =
      diag.bodyMightCompleteNormallyCatchError;

  /// Parameters:
  /// Type p0: the name of the declared return type
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required DartType p0})
  >
  bodyMightCompleteNormallyNullable = diag.bodyMightCompleteNormallyNullable;

  /// Parameters:
  /// String p0: the name of the unassigned variable
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  castFromNullableAlwaysFails = diag.castFromNullableAlwaysFails;

  /// No parameters.
  static const DiagnosticWithoutArguments castFromNullAlwaysFails =
      diag.castFromNullAlwaysFails;

  /// Parameters:
  /// Type p0: the matched value type
  /// Type p1: the constant value type
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  constantPatternNeverMatchesValueType =
      diag.constantPatternNeverMatchesValueType;

  /// Dead code is code that is never reached, this can happen for instance if a
  /// statement follows a return statement.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments deadCode = diag.deadCode;

  /// Dead code is code that is never reached. This case covers cases where the
  /// user has catch clauses after `catch (e)` or `on Object catch (e)`.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments deadCodeCatchFollowingCatch =
      diag.deadCodeCatchFollowingCatch;

  /// No parameters.
  static const DiagnosticWithoutArguments
  deadCodeLateWildcardVariableInitializer =
      diag.deadCodeLateWildcardVariableInitializer;

  /// Dead code is code that is never reached. This case covers cases where the
  /// user has an on-catch clause such as `on A catch (e)`, where a supertype of
  /// `A` was already caught.
  ///
  /// Parameters:
  /// Type p0: name of the subtype
  /// Type p1: name of the supertype
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  deadCodeOnCatchSubtype = diag.deadCodeOnCatchSubtype;

  /// Parameters:
  /// String p0: the name of the element
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  deprecatedExportUse = diag.deprecatedExportUse;

  /// Parameters:
  /// Object typeName: the name of the type
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object typeName})
  >
  deprecatedExtend = diag.deprecatedExtend;

  /// No parameters.
  static const DiagnosticWithoutArguments deprecatedExtendsFunction =
      diag.deprecatedExtendsFunction;

  /// Parameters:
  /// Object typeName: the name of the type
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object typeName})
  >
  deprecatedImplement = diag.deprecatedImplement;

  /// No parameters.
  static const DiagnosticWithoutArguments deprecatedImplementsFunction =
      diag.deprecatedImplementsFunction;

  /// Parameters:
  /// Object typeName: the name of the type
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object typeName})
  >
  deprecatedInstantiate = diag.deprecatedInstantiate;

  /// Parameters:
  /// Object typeName: the name of the type
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object typeName})
  >
  deprecatedMixin = diag.deprecatedMixin;

  /// No parameters.
  static const DiagnosticWithoutArguments deprecatedMixinFunction =
      diag.deprecatedMixinFunction;

  /// No parameters.
  static const DiagnosticWithoutArguments deprecatedNewInCommentReference =
      diag.deprecatedNewInCommentReference;

  /// Parameters:
  /// Object parameterName: the name of the parameter
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object parameterName})
  >
  deprecatedOptional = diag.deprecatedOptional;

  /// Parameters:
  /// Object typeName: the name of the type
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object typeName})
  >
  deprecatedSubclass = diag.deprecatedSubclass;

  /// Parameters:
  /// String p0: the name of the doc directive argument
  /// String p1: the expected format
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  docDirectiveArgumentWrongFormat = diag.docDirectiveArgumentWrongFormat;

  /// Parameters:
  /// String p0: the name of the doc directive
  /// int p1: the actual number of arguments
  /// int p2: the expected number of arguments
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required String p0,
      required int p1,
      required int p2,
    })
  >
  docDirectiveHasExtraArguments = diag.docDirectiveHasExtraArguments;

  /// Parameters:
  /// String p0: the name of the doc directive
  /// String p1: the name of the unexpected argument
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  docDirectiveHasUnexpectedNamedArgument =
      diag.docDirectiveHasUnexpectedNamedArgument;

  /// No parameters.
  static const DiagnosticWithoutArguments docDirectiveMissingClosingBrace =
      diag.docDirectiveMissingClosingBrace;

  /// Parameters:
  /// String p0: the name of the corresponding doc directive tag
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  docDirectiveMissingClosingTag = diag.docDirectiveMissingClosingTag;

  /// Parameters:
  /// String p0: the name of the doc directive
  /// String p1: the name of the missing argument
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  docDirectiveMissingOneArgument = diag.docDirectiveMissingOneArgument;

  /// Parameters:
  /// String p0: the name of the corresponding doc directive tag
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  docDirectiveMissingOpeningTag = diag.docDirectiveMissingOpeningTag;

  /// Parameters:
  /// String p0: the name of the doc directive
  /// String p1: the name of the first missing argument
  /// String p2: the name of the second missing argument
  /// String p3: the name of the third missing argument
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required String p0,
      required String p1,
      required String p2,
      required String p3,
    })
  >
  docDirectiveMissingThreeArguments = diag.docDirectiveMissingThreeArguments;

  /// Parameters:
  /// String p0: the name of the doc directive
  /// String p1: the name of the first missing argument
  /// String p2: the name of the second missing argument
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required String p0,
      required String p1,
      required String p2,
    })
  >
  docDirectiveMissingTwoArguments = diag.docDirectiveMissingTwoArguments;

  /// Parameters:
  /// String p0: the name of the unknown doc directive.
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  docDirectiveUnknown = diag.docDirectiveUnknown;

  /// No parameters.
  static const DiagnosticWithoutArguments docImportCannotBeDeferred =
      diag.docImportCannotBeDeferred;

  /// No parameters.
  static const DiagnosticWithoutArguments docImportCannotHaveCombinators =
      diag.docImportCannotHaveCombinators;

  /// No parameters.
  static const DiagnosticWithoutArguments docImportCannotHaveConfigurations =
      diag.docImportCannotHaveConfigurations;

  /// No parameters.
  static const DiagnosticWithoutArguments docImportCannotHavePrefix =
      diag.docImportCannotHavePrefix;

  /// Duplicate exports.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments duplicateExport =
      diag.duplicateExport;

  /// No parameters.
  static const DiagnosticWithoutArguments duplicateHiddenName =
      diag.duplicateHiddenName;

  /// Parameters:
  /// String p0: the name of the diagnostic being ignored
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  duplicateIgnore = diag.duplicateIgnore;

  /// Duplicate imports.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments duplicateImport =
      diag.duplicateImport;

  /// No parameters.
  static const DiagnosticWithoutArguments duplicateShownName =
      diag.duplicateShownName;

  /// No parameters.
  static const DiagnosticWithoutArguments equalElementsInSet =
      diag.equalElementsInSet;

  /// No parameters.
  static const DiagnosticWithoutArguments equalKeysInMap = diag.equalKeysInMap;

  /// Parameters:
  /// String member: the name of the member
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String member})
  >
  experimentalMemberUse = diag.experimentalMemberUse;

  /// When "strict-inference" is enabled, collection literal types must be
  /// inferred via the context type, or have type arguments.
  ///
  /// Parameters:
  /// String p0: the name of the collection
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  inferenceFailureOnCollectionLiteral =
      diag.inferenceFailureOnCollectionLiteral;

  /// When "strict-inference" is enabled, types in function invocations must be
  /// inferred via the context type, or have type arguments.
  ///
  /// Parameters:
  /// String p0: the name of the function
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  inferenceFailureOnFunctionInvocation =
      diag.inferenceFailureOnFunctionInvocation;

  /// When "strict-inference" is enabled, recursive local functions, top-level
  /// functions, methods, and function-typed function parameters must all
  /// specify a return type. See the strict-inference resource:
  ///
  /// https://github.com/dart-lang/language/blob/master/resources/type-system/strict-inference.md
  ///
  /// Parameters:
  /// String p0: the name of the function or method whose return type can't be
  ///            inferred
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  inferenceFailureOnFunctionReturnType =
      diag.inferenceFailureOnFunctionReturnType;

  /// When "strict-inference" is enabled, types in function invocations must be
  /// inferred via the context type, or have type arguments.
  ///
  /// Parameters:
  /// String p0: the name of the type
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  inferenceFailureOnGenericInvocation =
      diag.inferenceFailureOnGenericInvocation;

  /// When "strict-inference" is enabled, types in instance creation
  /// (constructor calls) must be inferred via the context type, or have type
  /// arguments.
  ///
  /// Parameters:
  /// String p0: the name of the constructor
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  inferenceFailureOnInstanceCreation = diag.inferenceFailureOnInstanceCreation;

  /// When "strict-inference" in enabled, uninitialized variables must be
  /// declared with a specific type.
  ///
  /// Parameters:
  /// String p0: the name of the variable
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  inferenceFailureOnUninitializedVariable =
      diag.inferenceFailureOnUninitializedVariable;

  /// When "strict-inference" in enabled, function parameters must be
  /// declared with a specific type, or inherit a type.
  ///
  /// Parameters:
  /// String p0: the name of the parameter
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  inferenceFailureOnUntypedParameter = diag.inferenceFailureOnUntypedParameter;

  /// Parameters:
  /// String p0: the name of the annotation
  /// String p1: the list of valid targets
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  invalidAnnotationTarget = diag.invalidAnnotationTarget;

  /// No parameters.
  static const DiagnosticWithoutArguments invalidAwaitNotRequiredAnnotation =
      diag.invalidAwaitNotRequiredAnnotation;

  /// No parameters.
  static const DiagnosticWithoutArguments invalidDeprecatedExtendAnnotation =
      diag.invalidDeprecatedExtendAnnotation;

  /// No parameters.
  static const DiagnosticWithoutArguments invalidDeprecatedImplementAnnotation =
      diag.invalidDeprecatedImplementAnnotation;

  /// No parameters.
  static const DiagnosticWithoutArguments
  invalidDeprecatedInstantiateAnnotation =
      diag.invalidDeprecatedInstantiateAnnotation;

  /// This warning is generated anywhere where `@Deprecated.mixin` annotates
  /// something other than a mixin class.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments invalidDeprecatedMixinAnnotation =
      diag.invalidDeprecatedMixinAnnotation;

  /// This warning is generated anywhere where `@Deprecated.optional`
  /// annotates something other than an optional parameter.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments invalidDeprecatedOptionalAnnotation =
      diag.invalidDeprecatedOptionalAnnotation;

  /// No parameters.
  static const DiagnosticWithoutArguments invalidDeprecatedSubclassAnnotation =
      diag.invalidDeprecatedSubclassAnnotation;

  /// Parameters:
  /// String p0: the name of the element
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  invalidExportOfInternalElement = diag.invalidExportOfInternalElement;

  /// Parameters:
  /// String p0: the name of the internal element
  /// String p1: the name of the exported element that indirectly exposes the
  ///            internal element
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  invalidExportOfInternalElementIndirectly =
      diag.invalidExportOfInternalElementIndirectly;

  /// Parameters:
  /// String p0: The name of the method
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  invalidFactoryMethodDecl = diag.invalidFactoryMethodDecl;

  /// Parameters:
  /// String p0: the name of the method
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  invalidFactoryMethodImpl = diag.invalidFactoryMethodImpl;

  /// No parameters.
  static const DiagnosticWithoutArguments invalidInternalAnnotation =
      diag.invalidInternalAnnotation;

  /// No parameters.
  static const DiagnosticWithoutArguments invalidLanguageVersionOverrideAtSign =
      diag.invalidLanguageVersionOverrideAtSign;

  /// No parameters.
  static const DiagnosticWithoutArguments invalidLanguageVersionOverrideEquals =
      diag.invalidLanguageVersionOverrideEquals;

  /// Parameters:
  /// Object p0: the latest major version
  /// Object p1: the latest minor version
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  invalidLanguageVersionOverrideGreater =
      diag.invalidLanguageVersionOverrideGreater;

  /// No parameters.
  static const DiagnosticWithoutArguments
  invalidLanguageVersionOverrideLocation =
      diag.invalidLanguageVersionOverrideLocation;

  /// No parameters.
  static const DiagnosticWithoutArguments
  invalidLanguageVersionOverrideLowerCase =
      diag.invalidLanguageVersionOverrideLowerCase;

  /// No parameters.
  static const DiagnosticWithoutArguments invalidLanguageVersionOverrideNumber =
      diag.invalidLanguageVersionOverrideNumber;

  /// No parameters.
  static const DiagnosticWithoutArguments invalidLanguageVersionOverridePrefix =
      diag.invalidLanguageVersionOverridePrefix;

  /// No parameters.
  static const DiagnosticWithoutArguments
  invalidLanguageVersionOverrideTrailingCharacters =
      diag.invalidLanguageVersionOverrideTrailingCharacters;

  /// No parameters.
  static const DiagnosticWithoutArguments
  invalidLanguageVersionOverrideTwoSlashes =
      diag.invalidLanguageVersionOverrideTwoSlashes;

  /// No parameters.
  static const DiagnosticWithoutArguments invalidLiteralAnnotation =
      diag.invalidLiteralAnnotation;

  /// This warning is generated anywhere where `@nonVirtual` annotates something
  /// other than a non-abstract instance member in a class or mixin.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments invalidNonVirtualAnnotation =
      diag.invalidNonVirtualAnnotation;

  /// This warning is generated anywhere where an instance member annotated with
  /// `@nonVirtual` is overridden in a subclass.
  ///
  /// Parameters:
  /// String p0: the name of the member
  /// String p1: the name of the defining class
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  invalidOverrideOfNonVirtualMember = diag.invalidOverrideOfNonVirtualMember;

  /// This warning is generated anywhere where `@reopen` annotates a class which
  /// did not reopen any type.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments invalidReopenAnnotation =
      diag.invalidReopenAnnotation;

  /// Parameters:
  /// String p0: the name of the member
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  invalidUseOfDoNotSubmitMember = diag.invalidUseOfDoNotSubmitMember;

  /// Parameters:
  /// String p0: the name of the member
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  invalidUseOfInternalMember = diag.invalidUseOfInternalMember;

  /// This warning is generated anywhere where a member annotated with
  /// `@protected` is used outside of an instance member of a subclass.
  ///
  /// Parameters:
  /// String p0: the name of the member
  /// String p1: the name of the defining class
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  invalidUseOfProtectedMember = diag.invalidUseOfProtectedMember;

  /// Parameters:
  /// String p0: the name of the member
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  invalidUseOfVisibleForOverridingMember =
      diag.invalidUseOfVisibleForOverridingMember;

  /// This warning is generated anywhere where a member annotated with
  /// `@visibleForTemplate` is used outside of a "template" Dart file.
  ///
  /// Parameters:
  /// String p0: the name of the member
  /// Uri p1: the name of the defining class
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required Uri p1})
  >
  invalidUseOfVisibleForTemplateMember =
      diag.invalidUseOfVisibleForTemplateMember;

  /// This warning is generated anywhere where a member annotated with
  /// `@visibleForTesting` is used outside the defining library, or a test.
  ///
  /// Parameters:
  /// String p0: the name of the member
  /// Uri p1: the name of the defining class
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required Uri p1})
  >
  invalidUseOfVisibleForTestingMember =
      diag.invalidUseOfVisibleForTestingMember;

  /// This warning is generated anywhere where a private declaration is
  /// annotated with `@visibleForTemplate` or `@visibleForTesting`.
  ///
  /// Parameters:
  /// String p0: the name of the member
  /// String p1: the name of the annotation
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  invalidVisibilityAnnotation = diag.invalidVisibilityAnnotation;

  /// No parameters.
  static const DiagnosticWithoutArguments
  invalidVisibleForOverridingAnnotation =
      diag.invalidVisibleForOverridingAnnotation;

  /// No parameters.
  static const DiagnosticWithoutArguments
  invalidVisibleOutsideTemplateAnnotation =
      diag.invalidVisibleOutsideTemplateAnnotation;

  /// No parameters.
  static const DiagnosticWithoutArguments invalidWidgetPreviewApplication =
      diag.invalidWidgetPreviewApplication;

  /// Parameters:
  /// String p0: the name of the private symbol
  /// String p1: the name of the proposed public symbol equivalent
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  invalidWidgetPreviewPrivateArgument =
      diag.invalidWidgetPreviewPrivateArgument;

  /// Parameters:
  /// String p0: the name of the member
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  missingOverrideOfMustBeOverriddenOne =
      diag.missingOverrideOfMustBeOverriddenOne;

  /// Parameters:
  /// String p0: the name of the first member
  /// String p1: the name of the second member
  /// String p2: the number of additional missing members that aren't listed
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required String p0,
      required String p1,
      required String p2,
    })
  >
  missingOverrideOfMustBeOverriddenThreePlus =
      diag.missingOverrideOfMustBeOverriddenThreePlus;

  /// Parameters:
  /// String p0: the name of the first member
  /// String p1: the name of the second member
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  missingOverrideOfMustBeOverriddenTwo =
      diag.missingOverrideOfMustBeOverriddenTwo;

  /// Generates a warning for a constructor, function or method invocation where
  /// a required parameter is missing.
  ///
  /// Parameters:
  /// String p0: the name of the parameter
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  missingRequiredParam = diag.missingRequiredParam;

  /// Generates a warning for a constructor, function or method invocation where
  /// a required parameter is missing.
  ///
  /// Parameters:
  /// String p0: the name of the parameter
  /// String p1: message details
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  missingRequiredParamWithDetails = diag.missingRequiredParamWithDetails;

  /// This warning is generated anywhere where a `@sealed` class is used as a
  /// a superclass constraint of a mixin.
  ///
  /// Parameters:
  /// String p0: the name of the sealed class
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  mixinOnSealedClass = diag.mixinOnSealedClass;

  /// No parameters.
  static const DiagnosticWithoutArguments multipleCombinators =
      diag.multipleCombinators;

  /// Generates a warning for classes that inherit from classes annotated with
  /// `@immutable` but that are not immutable.
  ///
  /// Parameters:
  /// String p0: the name of the class
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  mustBeImmutable = diag.mustBeImmutable;

  /// Parameters:
  /// String p0: the name of the class declaring the overridden method
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  mustCallSuper = diag.mustCallSuper;

  /// Parameters:
  /// String p0: the name of the argument
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  nonConstArgumentForConstParameter = diag.nonConstArgumentForConstParameter;

  /// Generates a warning for non-const instance creation using a constructor
  /// annotated with `@literal`.
  ///
  /// Parameters:
  /// String p0: the name of the class defining the annotated constructor
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  nonConstCallToLiteralConstructor = diag.nonConstCallToLiteralConstructor;

  /// Generate a warning for non-const instance creation (with the `new` keyword)
  /// using a constructor annotated with `@literal`.
  ///
  /// Parameters:
  /// String p0: the name of the class defining the annotated constructor
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  nonConstCallToLiteralConstructorUsingNew =
      diag.nonConstCallToLiteralConstructorUsingNew;

  /// No parameters.
  static const DiagnosticWithoutArguments nonNullableEqualsParameter =
      diag.nonNullableEqualsParameter;

  /// No parameters.
  static const DiagnosticWithoutArguments nullableTypeInCatchClause =
      diag.nullableTypeInCatchClause;

  /// Parameters:
  /// String p0: the name of the method being invoked
  /// String p1: the type argument associated with the method
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  nullArgumentToNonNullType = diag.nullArgumentToNonNullType;

  /// No parameters.
  static const DiagnosticWithoutArguments nullCheckAlwaysFails =
      diag.nullCheckAlwaysFails;

  /// A field with the override annotation does not override a getter or setter.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments overrideOnNonOverridingField =
      diag.overrideOnNonOverridingField;

  /// A getter with the override annotation does not override an existing getter.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments overrideOnNonOverridingGetter =
      diag.overrideOnNonOverridingGetter;

  /// A method with the override annotation does not override an existing method.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments overrideOnNonOverridingMethod =
      diag.overrideOnNonOverridingMethod;

  /// A setter with the override annotation does not override an existing setter.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments overrideOnNonOverridingSetter =
      diag.overrideOnNonOverridingSetter;

  /// Parameters:
  /// Type p0: the matched value type
  /// Type p1: the required pattern type
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  patternNeverMatchesValueType = diag.patternNeverMatchesValueType;

  /// It is not an error to call or tear-off a method, setter, or getter, or to
  /// read or write a field, on a receiver of static type `Never`.
  /// Implementations that provide feedback about dead or unreachable code are
  /// encouraged to indicate that any arguments to the invocation are
  /// unreachable.
  ///
  /// It is not an error to apply an expression of type `Never` in the function
  /// position of a function call. Implementations that provide feedback about
  /// dead or unreachable code are encouraged to indicate that any arguments to
  /// the call are unreachable.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments receiverOfTypeNever =
      diag.receiverOfTypeNever;

  /// An error code indicating the use of a redeclare annotation on a member that does not redeclare.
  ///
  /// Parameters:
  /// String p0: the kind of member
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  redeclareOnNonRedeclaringMember = diag.redeclareOnNonRedeclaringMember;

  /// An error code indicating use of a removed lint rule.
  ///
  /// Parameters:
  /// Object p0: the rule name
  /// Object p1: the SDK version in which the lint was removed
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  removedLintUse = diag.removedLintUse;

  /// An error code indicating use of a removed lint rule.
  ///
  /// Parameters:
  /// Object p0: the rule name
  /// Object p1: the SDK version in which the lint was removed
  /// Object p2: the name of a replacing lint
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required Object p0,
      required Object p1,
      required Object p2,
    })
  >
  replacedLintUse = diag.replacedLintUse;

  /// Parameters:
  /// String p0: the name of the annotated function being invoked
  /// String p1: the name of the function containing the return
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  returnOfDoNotStore = diag.returnOfDoNotStore;

  /// Parameters:
  /// Type p0: the return type as declared in the return statement
  /// Type p1: the expected return type as defined by the type of the Future
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  returnOfInvalidTypeFromCatchError = diag.returnOfInvalidTypeFromCatchError;

  /// Parameters:
  /// Type p0: the return type of the function
  /// Type p1: the expected return type as defined by the type of the Future
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  returnTypeInvalidForCatchError = diag.returnTypeInvalidForCatchError;

  /// There is also a [diag.experimentNotEnabled] code which
  /// catches some cases of constructor tearoff features (like
  /// `List<int>.filled;`). Other constructor tearoff cases are not realized
  /// until resolution (like `List.filled;`).
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments sdkVersionConstructorTearoffs =
      diag.sdkVersionConstructorTearoffs;

  /// No parameters.
  static const DiagnosticWithoutArguments sdkVersionGtGtGtOperator =
      diag.sdkVersionGtGtGtOperator;

  /// Parameters:
  /// String p0: the version specified in the `@Since()` annotation
  /// String p1: the SDK version constraints
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  sdkVersionSince = diag.sdkVersionSince;

  /// When "strict-raw-types" is enabled, "raw types" must have type arguments.
  ///
  /// A "raw type" is a type name that does not use inference to fill in missing
  /// type arguments; instead, each type argument is instantiated to its bound.
  ///
  /// Parameters:
  /// Type p0: the name of the generic type
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required DartType p0})
  >
  strictRawType = diag.strictRawType;

  /// Parameters:
  /// String p0: the name of the sealed class
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  subtypeOfSealedClass = diag.subtypeOfSealedClass;

  /// Parameters:
  /// String p0: the unicode sequence of the code point.
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  textDirectionCodePointInComment = diag.textDirectionCodePointInComment;

  /// Parameters:
  /// String p0: the unicode sequence of the code point.
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  textDirectionCodePointInLiteral = diag.textDirectionCodePointInLiteral;

  /// No parameters.
  static const DiagnosticWithoutArguments typeCheckIsNotNull =
      diag.typeCheckIsNotNull;

  /// No parameters.
  static const DiagnosticWithoutArguments typeCheckIsNull =
      diag.typeCheckIsNull;

  /// Parameters:
  /// String p0: the name of the library being imported
  /// String p1: the name in the hide clause that isn't defined in the library
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  undefinedHiddenName = diag.undefinedHiddenName;

  /// Parameters:
  /// String p0: the name of the undefined parameter
  /// String p1: the name of the targeted member
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  undefinedReferencedParameter = diag.undefinedReferencedParameter;

  /// Parameters:
  /// String p0: the name of the library being imported
  /// String p1: the name in the show clause that isn't defined in the library
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  undefinedShownName = diag.undefinedShownName;

  /// Parameters:
  /// Object p0: the name of the non-diagnostic being ignored
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  unignorableIgnore = diag.unignorableIgnore;

  /// No parameters.
  static const DiagnosticWithoutArguments unnecessaryCast =
      diag.unnecessaryCast;

  /// No parameters.
  static const DiagnosticWithoutArguments unnecessaryCastPattern =
      diag.unnecessaryCastPattern;

  /// No parameters.
  static const DiagnosticWithoutArguments unnecessaryFinal =
      diag.unnecessaryFinal;

  /// No parameters.
  static const DiagnosticWithoutArguments unnecessaryNanComparisonFalse =
      diag.unnecessaryNanComparisonFalse;

  /// No parameters.
  static const DiagnosticWithoutArguments unnecessaryNanComparisonTrue =
      diag.unnecessaryNanComparisonTrue;

  /// No parameters.
  static const DiagnosticWithoutArguments unnecessaryNoSuchMethod =
      diag.unnecessaryNoSuchMethod;

  /// No parameters.
  static const DiagnosticWithoutArguments
  unnecessaryNullComparisonAlwaysNullFalse =
      diag.unnecessaryNullComparisonAlwaysNullFalse;

  /// No parameters.
  static const DiagnosticWithoutArguments
  unnecessaryNullComparisonAlwaysNullTrue =
      diag.unnecessaryNullComparisonAlwaysNullTrue;

  /// No parameters.
  static const DiagnosticWithoutArguments
  unnecessaryNullComparisonNeverNullFalse =
      diag.unnecessaryNullComparisonNeverNullFalse;

  /// No parameters.
  static const DiagnosticWithoutArguments
  unnecessaryNullComparisonNeverNullTrue =
      diag.unnecessaryNullComparisonNeverNullTrue;

  /// Parameters:
  /// String p0: the name of the type
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  unnecessaryQuestionMark = diag.unnecessaryQuestionMark;

  /// No parameters.
  static const DiagnosticWithoutArguments unnecessarySetLiteral =
      diag.unnecessarySetLiteral;

  /// No parameters.
  static const DiagnosticWithoutArguments unnecessaryTypeCheckFalse =
      diag.unnecessaryTypeCheckFalse;

  /// No parameters.
  static const DiagnosticWithoutArguments unnecessaryTypeCheckTrue =
      diag.unnecessaryTypeCheckTrue;

  /// No parameters.
  static const DiagnosticWithoutArguments unnecessaryWildcardPattern =
      diag.unnecessaryWildcardPattern;

  /// No parameters.
  static const DiagnosticWithoutArguments unreachableSwitchCase =
      diag.unreachableSwitchCase;

  /// No parameters.
  static const DiagnosticWithoutArguments unreachableSwitchDefault =
      diag.unreachableSwitchDefault;

  /// Parameters:
  /// Object p0: the name of the exception variable
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  unusedCatchClause = diag.unusedCatchClause;

  /// Parameters:
  /// Object p0: the name of the stack trace variable
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  unusedCatchStack = diag.unusedCatchStack;

  /// Parameters:
  /// Object p0: the name that is declared but not referenced
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  unusedElement = diag.unusedElement;

  /// Parameters:
  /// Object p0: the name of the parameter that is declared but not used
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  unusedElementParameter = diag.unusedElementParameter;

  /// Parameters:
  /// Object p0: the name of the unused field
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  unusedField = diag.unusedField;

  /// Parameters:
  /// String p0: the content of the unused import's URI
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  unusedImport = diag.unusedImport;

  /// Parameters:
  /// String p0: the label that isn't used
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  unusedLabel = diag.unusedLabel;

  /// Parameters:
  /// Object p0: the name of the unused variable
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  unusedLocalVariable = diag.unusedLocalVariable;

  /// Parameters:
  /// String p0: the name of the annotated method, property or function
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  unusedResult = diag.unusedResult;

  /// The result of invoking a method, property, or function annotated with
  /// `@useResult` must be used (assigned, passed to a function as an argument,
  /// or returned by a function).
  ///
  /// Parameters:
  /// Object p0: the name of the annotated method, property or function
  /// Object p1: message details
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  unusedResultWithMessage = diag.unusedResultWithMessage;

  /// Parameters:
  /// String p0: the name that is shown but not used
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  unusedShownName = diag.unusedShownName;

  /// Parameters:
  /// String p0: the URI pointing to a nonexistent file
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  uriDoesNotExistInDocImport = diag.uriDoesNotExistInDocImport;

  /// Do not construct instances of this class.
  WarningCode._() : assert(false);
}
