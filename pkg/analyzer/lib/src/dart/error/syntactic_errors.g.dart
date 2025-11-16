// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/analyzer/messages.yaml' and run
// 'dart run pkg/analyzer/tool/messages/generate.dart' to update.

// Generated comments don't quite align with flutter style.
// ignore_for_file: flutter_style_todos

part of "package:analyzer/src/dart/error/syntactic_errors.dart";

class ParserErrorCode {
  /// No parameters.
  static const DiagnosticWithoutArguments abstractClassMember =
      diag.abstractClassMember;

  /// No parameters.
  static const DiagnosticWithoutArguments abstractExternalField =
      diag.abstractExternalField;

  /// No parameters.
  static const DiagnosticWithoutArguments abstractFinalBaseClass =
      diag.abstractFinalBaseClass;

  /// No parameters.
  static const DiagnosticWithoutArguments abstractFinalInterfaceClass =
      diag.abstractFinalInterfaceClass;

  /// No parameters.
  static const DiagnosticWithoutArguments abstractLateField =
      diag.abstractLateField;

  /// No parameters.
  static const DiagnosticWithoutArguments abstractSealedClass =
      diag.abstractSealedClass;

  /// No parameters.
  static const DiagnosticWithoutArguments abstractStaticField =
      diag.abstractStaticField;

  /// No parameters.
  static const DiagnosticWithoutArguments abstractStaticMethod =
      diag.abstractStaticMethod;

  /// No parameters.
  static const DiagnosticWithoutArguments annotationOnTypeArgument =
      diag.annotationOnTypeArgument;

  /// No parameters.
  static const DiagnosticWithoutArguments annotationSpaceBeforeParenthesis =
      diag.annotationSpaceBeforeParenthesis;

  /// No parameters.
  static const DiagnosticWithoutArguments annotationWithTypeArguments =
      diag.annotationWithTypeArguments;

  /// No parameters.
  static const DiagnosticWithoutArguments
  annotationWithTypeArgumentsUninstantiated =
      diag.annotationWithTypeArgumentsUninstantiated;

  /// 16.32 Identifier Reference: It is a compile-time error if any of the
  /// identifiers async, await, or yield is used as an identifier in a function
  /// body marked with either async, async, or sync.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments asyncKeywordUsedAsIdentifier =
      diag.asyncKeywordUsedAsIdentifier;

  /// No parameters.
  static const DiagnosticWithoutArguments baseEnum = diag.baseEnum;

  /// Parameters:
  /// String string: undocumented
  /// String string2: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required String string,
      required String string2,
    })
  >
  binaryOperatorWrittenOut = diag.binaryOperatorWrittenOut;

  /// No parameters.
  static const DiagnosticWithoutArguments breakOutsideOfLoop =
      diag.breakOutsideOfLoop;

  /// No parameters.
  static const DiagnosticWithoutArguments catchSyntax = diag.catchSyntax;

  /// No parameters.
  static const DiagnosticWithoutArguments catchSyntaxExtraParameters =
      diag.catchSyntaxExtraParameters;

  /// No parameters.
  static const DiagnosticWithoutArguments classInClass = diag.classInClass;

  /// No parameters.
  static const DiagnosticWithoutArguments colonInPlaceOfIn =
      diag.colonInPlaceOfIn;

  /// Parameters:
  /// String string: undocumented
  /// String string2: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required String string,
      required String string2,
    })
  >
  conflictingModifiers = diag.conflictingModifiers;

  /// No parameters.
  static const DiagnosticWithoutArguments constAndFinal = diag.constAndFinal;

  /// No parameters.
  static const DiagnosticWithoutArguments constClass = diag.constClass;

  /// No parameters.
  static const DiagnosticWithoutArguments constConstructorWithBody =
      diag.constConstructorWithBody;

  /// No parameters.
  static const DiagnosticWithoutArguments constFactory = diag.constFactory;

  /// No parameters.
  static const DiagnosticWithoutArguments constMethod = diag.constMethod;

  /// No parameters.
  static const DiagnosticWithoutArguments constructorWithReturnType =
      diag.constructorWithReturnType;

  /// No parameters.
  static const DiagnosticWithoutArguments constructorWithTypeArguments =
      diag.constructorWithTypeArguments;

  /// No parameters.
  static const DiagnosticWithoutArguments constWithoutPrimaryConstructor =
      diag.constWithoutPrimaryConstructor;

  /// No parameters.
  static const DiagnosticWithoutArguments continueOutsideOfLoop =
      diag.continueOutsideOfLoop;

  /// No parameters.
  static const DiagnosticWithoutArguments continueWithoutLabelInCase =
      diag.continueWithoutLabelInCase;

  /// No parameters.
  static const DiagnosticWithoutArguments covariantAndStatic =
      diag.covariantAndStatic;

  /// No parameters.
  static const DiagnosticWithoutArguments covariantConstructor =
      diag.covariantConstructor;

  /// No parameters.
  static const DiagnosticWithoutArguments covariantMember =
      diag.covariantMember;

  /// No parameters.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments defaultInSwitchExpression =
      diag.defaultInSwitchExpression;

  /// No parameters.
  static const DiagnosticWithoutArguments defaultValueInFunctionType =
      diag.defaultValueInFunctionType;

  /// No parameters.
  static const DiagnosticWithoutArguments deferredAfterPrefix =
      diag.deferredAfterPrefix;

  /// No parameters.
  static const DiagnosticWithoutArguments directiveAfterDeclaration =
      diag.directiveAfterDeclaration;

  /// No parameters.
  static const DiagnosticWithoutArguments duplicateDeferred =
      diag.duplicateDeferred;

  /// Parameters:
  /// 0: the modifier that was duplicated
  ///
  /// Parameters:
  /// Token lexeme: undocumented
  static const DiagnosticCode duplicatedModifier = diag.duplicatedModifier;

  /// Parameters:
  /// 0: the label that was duplicated
  ///
  /// Parameters:
  /// Name name: undocumented
  static const DiagnosticCode duplicateLabelInSwitchStatement =
      diag.duplicateLabelInSwitchStatement;

  /// No parameters.
  static const DiagnosticWithoutArguments duplicatePrefix =
      diag.duplicatePrefix;

  /// No parameters.
  static const DiagnosticWithoutArguments emptyEnumBody = diag.emptyEnumBody;

  /// No parameters.
  static const DiagnosticWithoutArguments emptyRecordLiteralWithComma =
      diag.emptyRecordLiteralWithComma;

  /// No parameters.
  static const DiagnosticWithoutArguments emptyRecordTypeNamedFieldsList =
      diag.emptyRecordTypeNamedFieldsList;

  /// No parameters.
  static const DiagnosticWithoutArguments emptyRecordTypeWithComma =
      diag.emptyRecordTypeWithComma;

  /// No parameters.
  static const DiagnosticWithoutArguments enumInClass = diag.enumInClass;

  /// No parameters.
  static const DiagnosticWithoutArguments equalityCannotBeEqualityOperand =
      diag.equalityCannotBeEqualityOperand;

  /// No parameters.
  static const DiagnosticWithoutArguments expectedCaseOrDefault =
      diag.expectedCaseOrDefault;

  /// No parameters.
  static const DiagnosticWithoutArguments expectedCatchClauseBody =
      diag.expectedCatchClauseBody;

  /// No parameters.
  static const DiagnosticWithoutArguments expectedClassBody =
      diag.expectedClassBody;

  /// No parameters.
  static const DiagnosticWithoutArguments expectedClassMember =
      diag.expectedClassMember;

  /// No parameters.
  static const DiagnosticWithoutArguments expectedElseOrComma =
      diag.expectedElseOrComma;

  /// No parameters.
  static const DiagnosticWithoutArguments expectedExecutable =
      diag.expectedExecutable;

  /// No parameters.
  static const DiagnosticWithoutArguments expectedExtensionBody =
      diag.expectedExtensionBody;

  /// No parameters.
  static const DiagnosticWithoutArguments expectedExtensionTypeBody =
      diag.expectedExtensionTypeBody;

  /// No parameters.
  static const DiagnosticWithoutArguments expectedFinallyClauseBody =
      diag.expectedFinallyClauseBody;

  /// Parameters:
  /// Token lexeme: undocumented
  static const DiagnosticCode expectedIdentifierButGotKeyword =
      diag.expectedIdentifierButGotKeyword;

  /// Parameters:
  /// String string: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String string})
  >
  expectedInstead = diag.expectedInstead;

  /// No parameters.
  static const DiagnosticWithoutArguments expectedListOrMapLiteral =
      diag.expectedListOrMapLiteral;

  /// No parameters.
  static const DiagnosticWithoutArguments expectedMixinBody =
      diag.expectedMixinBody;

  /// No parameters.
  static const DiagnosticWithoutArguments expectedNamedTypeExtends =
      diag.expectedNamedTypeExtends;

  /// No parameters.
  static const DiagnosticWithoutArguments expectedNamedTypeImplements =
      diag.expectedNamedTypeImplements;

  /// No parameters.
  static const DiagnosticWithoutArguments expectedNamedTypeOn =
      diag.expectedNamedTypeOn;

  /// No parameters.
  static const DiagnosticWithoutArguments expectedNamedTypeWith =
      diag.expectedNamedTypeWith;

  /// No parameters.
  static const DiagnosticWithoutArguments expectedRepresentationField =
      diag.expectedRepresentationField;

  /// No parameters.
  static const DiagnosticWithoutArguments expectedRepresentationType =
      diag.expectedRepresentationType;

  /// No parameters.
  static const DiagnosticWithoutArguments expectedStringLiteral =
      diag.expectedStringLiteral;

  /// No parameters.
  static const DiagnosticWithoutArguments expectedSwitchExpressionBody =
      diag.expectedSwitchExpressionBody;

  /// No parameters.
  static const DiagnosticWithoutArguments expectedSwitchStatementBody =
      diag.expectedSwitchStatementBody;

  /// Parameters:
  /// String p0: the token that was expected but not found
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  expectedToken = diag.expectedToken;

  /// No parameters.
  static const DiagnosticWithoutArguments expectedTryStatementBody =
      diag.expectedTryStatementBody;

  /// No parameters.
  static const DiagnosticWithoutArguments expectedTypeName =
      diag.expectedTypeName;

  /// Parameters:
  /// String string: undocumented
  /// String string2: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required String string,
      required String string2,
    })
  >
  experimentNotEnabled = diag.experimentNotEnabled;

  /// Parameters:
  /// String string: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String string})
  >
  experimentNotEnabledOffByDefault = diag.experimentNotEnabledOffByDefault;

  /// No parameters.
  static const DiagnosticWithoutArguments exportDirectiveAfterPartDirective =
      diag.exportDirectiveAfterPartDirective;

  /// No parameters.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments extensionAugmentationHasOnClause =
      diag.extensionAugmentationHasOnClause;

  /// No parameters.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments extensionDeclaresAbstractMember =
      diag.extensionDeclaresAbstractMember;

  /// No parameters.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments extensionDeclaresConstructor =
      diag.extensionDeclaresConstructor;

  /// No parameters.
  static const DiagnosticWithoutArguments extensionTypeExtends =
      diag.extensionTypeExtends;

  /// No parameters.
  static const DiagnosticWithoutArguments extensionTypeWith =
      diag.extensionTypeWith;

  /// No parameters.
  static const DiagnosticWithoutArguments externalClass = diag.externalClass;

  /// No parameters.
  static const DiagnosticWithoutArguments
  externalConstructorWithFieldInitializers =
      diag.externalConstructorWithFieldInitializers;

  /// No parameters.
  static const DiagnosticWithoutArguments externalConstructorWithInitializer =
      diag.externalConstructorWithInitializer;

  /// No parameters.
  static const DiagnosticWithoutArguments externalEnum = diag.externalEnum;

  /// No parameters.
  static const DiagnosticWithoutArguments externalFactoryRedirection =
      diag.externalFactoryRedirection;

  /// No parameters.
  static const DiagnosticWithoutArguments externalFactoryWithBody =
      diag.externalFactoryWithBody;

  /// No parameters.
  static const DiagnosticWithoutArguments externalGetterWithBody =
      diag.externalGetterWithBody;

  /// No parameters.
  static const DiagnosticWithoutArguments externalLateField =
      diag.externalLateField;

  /// No parameters.
  static const DiagnosticWithoutArguments externalMethodWithBody =
      diag.externalMethodWithBody;

  /// No parameters.
  static const DiagnosticWithoutArguments externalOperatorWithBody =
      diag.externalOperatorWithBody;

  /// No parameters.
  static const DiagnosticWithoutArguments externalSetterWithBody =
      diag.externalSetterWithBody;

  /// No parameters.
  static const DiagnosticWithoutArguments externalTypedef =
      diag.externalTypedef;

  /// Parameters:
  /// Token lexeme: undocumented
  static const DiagnosticCode extraneousModifier = diag.extraneousModifier;

  /// Parameters:
  /// Token lexeme: undocumented
  static const DiagnosticCode extraneousModifierInExtensionType =
      diag.extraneousModifierInExtensionType;

  /// Parameters:
  /// Token lexeme: undocumented
  static const DiagnosticCode extraneousModifierInPrimaryConstructor =
      diag.extraneousModifierInPrimaryConstructor;

  /// No parameters.
  static const DiagnosticWithoutArguments factoryTopLevelDeclaration =
      diag.factoryTopLevelDeclaration;

  /// No parameters.
  static const DiagnosticWithoutArguments factoryWithInitializers =
      diag.factoryWithInitializers;

  /// No parameters.
  static const DiagnosticWithoutArguments factoryWithoutBody =
      diag.factoryWithoutBody;

  /// No parameters.
  static const DiagnosticWithoutArguments
  fieldInitializedOutsideDeclaringClass =
      diag.fieldInitializedOutsideDeclaringClass;

  /// No parameters.
  static const DiagnosticWithoutArguments finalAndCovariant =
      diag.finalAndCovariant;

  /// No parameters.
  static const DiagnosticWithoutArguments finalAndCovariantLateWithInitializer =
      diag.finalAndCovariantLateWithInitializer;

  /// No parameters.
  static const DiagnosticWithoutArguments finalAndVar = diag.finalAndVar;

  /// No parameters.
  static const DiagnosticWithoutArguments finalConstructor =
      diag.finalConstructor;

  /// No parameters.
  static const DiagnosticWithoutArguments finalEnum = diag.finalEnum;

  /// No parameters.
  static const DiagnosticWithoutArguments finalMethod = diag.finalMethod;

  /// No parameters.
  static const DiagnosticWithoutArguments finalMixin = diag.finalMixin;

  /// No parameters.
  static const DiagnosticWithoutArguments finalMixinClass =
      diag.finalMixinClass;

  /// No parameters.
  static const DiagnosticWithoutArguments functionTypedParameterVar =
      diag.functionTypedParameterVar;

  /// No parameters.
  static const DiagnosticWithoutArguments getterConstructor =
      diag.getterConstructor;

  /// No parameters.
  static const DiagnosticWithoutArguments getterInFunction =
      diag.getterInFunction;

  /// No parameters.
  static const DiagnosticWithoutArguments getterWithParameters =
      diag.getterWithParameters;

  /// No parameters.
  static const DiagnosticWithoutArguments illegalAssignmentToNonAssignable =
      diag.illegalAssignmentToNonAssignable;

  /// Parameters:
  /// 0: the illegal name
  ///
  /// Parameters:
  /// Token lexeme: undocumented
  static const DiagnosticCode illegalPatternAssignmentVariableName =
      diag.illegalPatternAssignmentVariableName;

  /// Parameters:
  /// 0: the illegal name
  ///
  /// Parameters:
  /// Token lexeme: undocumented
  static const DiagnosticCode illegalPatternIdentifierName =
      diag.illegalPatternIdentifierName;

  /// Parameters:
  /// 0: the illegal name
  ///
  /// Parameters:
  /// Token lexeme: undocumented
  static const DiagnosticCode illegalPatternVariableName =
      diag.illegalPatternVariableName;

  /// No parameters.
  static const DiagnosticWithoutArguments implementsBeforeExtends =
      diag.implementsBeforeExtends;

  /// No parameters.
  static const DiagnosticWithoutArguments implementsBeforeOn =
      diag.implementsBeforeOn;

  /// No parameters.
  static const DiagnosticWithoutArguments implementsBeforeWith =
      diag.implementsBeforeWith;

  /// No parameters.
  static const DiagnosticWithoutArguments importDirectiveAfterPartDirective =
      diag.importDirectiveAfterPartDirective;

  /// No parameters.
  static const DiagnosticWithoutArguments initializedVariableInForEach =
      diag.initializedVariableInForEach;

  /// No parameters.
  static const DiagnosticWithoutArguments interfaceEnum = diag.interfaceEnum;

  /// No parameters.
  static const DiagnosticWithoutArguments interfaceMixin = diag.interfaceMixin;

  /// No parameters.
  static const DiagnosticWithoutArguments interfaceMixinClass =
      diag.interfaceMixinClass;

  /// No parameters.
  static const DiagnosticWithoutArguments invalidAwaitInFor =
      diag.invalidAwaitInFor;

  /// Parameters:
  /// String p0: the invalid escape sequence
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  invalidCodePoint = diag.invalidCodePoint;

  /// No parameters.
  static const DiagnosticWithoutArguments invalidCommentReference =
      diag.invalidCommentReference;

  /// No parameters.
  static const DiagnosticWithoutArguments invalidConstantConstPrefix =
      diag.invalidConstantConstPrefix;

  /// Parameters:
  /// Name name: undocumented
  static const DiagnosticCode invalidConstantPatternBinary =
      diag.invalidConstantPatternBinary;

  /// No parameters.
  static const DiagnosticWithoutArguments invalidConstantPatternDuplicateConst =
      diag.invalidConstantPatternDuplicateConst;

  /// No parameters.
  static const DiagnosticWithoutArguments
  invalidConstantPatternEmptyRecordLiteral =
      diag.invalidConstantPatternEmptyRecordLiteral;

  /// No parameters.
  static const DiagnosticWithoutArguments invalidConstantPatternGeneric =
      diag.invalidConstantPatternGeneric;

  /// No parameters.
  static const DiagnosticWithoutArguments invalidConstantPatternNegation =
      diag.invalidConstantPatternNegation;

  /// Parameters:
  /// Name name: undocumented
  static const DiagnosticCode invalidConstantPatternUnary =
      diag.invalidConstantPatternUnary;

  /// No parameters.
  static const DiagnosticWithoutArguments invalidConstructorName =
      diag.invalidConstructorName;

  /// No parameters.
  static const DiagnosticWithoutArguments invalidGenericFunctionType =
      diag.invalidGenericFunctionType;

  /// No parameters.
  static const DiagnosticWithoutArguments invalidHexEscape =
      diag.invalidHexEscape;

  /// No parameters.
  static const DiagnosticWithoutArguments invalidInitializer =
      diag.invalidInitializer;

  /// No parameters.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments invalidInsideUnaryPattern =
      diag.invalidInsideUnaryPattern;

  /// No parameters.
  static const DiagnosticWithoutArguments invalidLiteralInConfiguration =
      diag.invalidLiteralInConfiguration;

  /// Parameters:
  /// 0: the operator that is invalid
  ///
  /// Parameters:
  /// Token lexeme: undocumented
  static const DiagnosticCode invalidOperator = diag.invalidOperator;

  /// Only generated by the old parser.
  /// Replaced by INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER.
  ///
  /// Parameters:
  /// Object p0: the operator being applied to 'super'
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  invalidOperatorForSuper = diag.invalidOperatorForSuper;

  /// No parameters.
  static const DiagnosticWithoutArguments
  invalidOperatorQuestionmarkPeriodForSuper =
      diag.invalidOperatorQuestionmarkPeriodForSuper;

  /// No parameters.
  static const DiagnosticWithoutArguments invalidStarAfterAsync =
      diag.invalidStarAfterAsync;

  /// No parameters.
  static const DiagnosticWithoutArguments invalidSuperInInitializer =
      diag.invalidSuperInInitializer;

  /// No parameters.
  static const DiagnosticWithoutArguments invalidSync = diag.invalidSync;

  /// No parameters.
  static const DiagnosticWithoutArguments invalidThisInInitializer =
      diag.invalidThisInInitializer;

  /// No parameters.
  static const DiagnosticWithoutArguments invalidUnicodeEscapeStarted =
      diag.invalidUnicodeEscapeStarted;

  /// No parameters.
  static const DiagnosticWithoutArguments invalidUnicodeEscapeUBracket =
      diag.invalidUnicodeEscapeUBracket;

  /// No parameters.
  static const DiagnosticWithoutArguments invalidUnicodeEscapeUNoBracket =
      diag.invalidUnicodeEscapeUNoBracket;

  /// No parameters.
  static const DiagnosticWithoutArguments invalidUnicodeEscapeUStarted =
      diag.invalidUnicodeEscapeUStarted;

  /// No parameters.
  ///
  /// Parameters:
  /// Token lexeme: undocumented
  static const DiagnosticCode invalidUseOfCovariantInExtension =
      diag.invalidUseOfCovariantInExtension;

  /// No parameters.
  static const DiagnosticWithoutArguments invalidUseOfIdentifierAugmented =
      diag.invalidUseOfIdentifierAugmented;

  /// No parameters.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments latePatternVariableDeclaration =
      diag.latePatternVariableDeclaration;

  /// No parameters.
  static const DiagnosticWithoutArguments libraryDirectiveNotFirst =
      diag.libraryDirectiveNotFirst;

  /// Parameters:
  /// String string: undocumented
  /// Token lexeme: undocumented
  static const DiagnosticCode literalWithClass = diag.literalWithClass;

  /// Parameters:
  /// String string: undocumented
  /// Token lexeme: undocumented
  static const DiagnosticCode literalWithClassAndNew =
      diag.literalWithClassAndNew;

  /// No parameters.
  static const DiagnosticWithoutArguments literalWithNew = diag.literalWithNew;

  /// No parameters.
  static const DiagnosticWithoutArguments localFunctionDeclarationModifier =
      diag.localFunctionDeclarationModifier;

  /// No parameters.
  static const DiagnosticWithoutArguments memberWithClassName =
      diag.memberWithClassName;

  /// No parameters.
  static const DiagnosticWithoutArguments missingAssignableSelector =
      diag.missingAssignableSelector;

  /// No parameters.
  static const DiagnosticWithoutArguments missingAssignmentInInitializer =
      diag.missingAssignmentInInitializer;

  /// No parameters.
  static const DiagnosticWithoutArguments missingCatchOrFinally =
      diag.missingCatchOrFinally;

  /// No parameters.
  static const DiagnosticWithoutArguments missingClosingParenthesis =
      diag.missingClosingParenthesis;

  /// No parameters.
  static const DiagnosticWithoutArguments missingConstFinalVarOrType =
      diag.missingConstFinalVarOrType;

  /// No parameters.
  static const DiagnosticWithoutArguments missingEnumBody =
      diag.missingEnumBody;

  /// No parameters.
  static const DiagnosticWithoutArguments missingExpressionInInitializer =
      diag.missingExpressionInInitializer;

  /// No parameters.
  static const DiagnosticWithoutArguments missingExpressionInThrow =
      diag.missingExpressionInThrow;

  /// No parameters.
  static const DiagnosticWithoutArguments missingFunctionBody =
      diag.missingFunctionBody;

  /// No parameters.
  static const DiagnosticWithoutArguments missingFunctionKeyword =
      diag.missingFunctionKeyword;

  /// No parameters.
  static const DiagnosticWithoutArguments missingFunctionParameters =
      diag.missingFunctionParameters;

  /// No parameters.
  static const DiagnosticWithoutArguments missingGet = diag.missingGet;

  /// No parameters.
  static const DiagnosticWithoutArguments missingIdentifier =
      diag.missingIdentifier;

  /// No parameters.
  static const DiagnosticWithoutArguments missingInitializer =
      diag.missingInitializer;

  /// No parameters.
  static const DiagnosticWithoutArguments missingKeywordOperator =
      diag.missingKeywordOperator;

  /// No parameters.
  static const DiagnosticWithoutArguments missingMethodParameters =
      diag.missingMethodParameters;

  /// No parameters.
  static const DiagnosticWithoutArguments missingNameForNamedParameter =
      diag.missingNameForNamedParameter;

  /// No parameters.
  static const DiagnosticWithoutArguments missingNameInLibraryDirective =
      diag.missingNameInLibraryDirective;

  /// No parameters.
  static const DiagnosticWithoutArguments missingNameInPartOfDirective =
      diag.missingNameInPartOfDirective;

  /// No parameters.
  static const DiagnosticWithoutArguments missingPrefixInDeferredImport =
      diag.missingPrefixInDeferredImport;

  /// No parameters.
  static const DiagnosticWithoutArguments missingPrimaryConstructor =
      diag.missingPrimaryConstructor;

  /// No parameters.
  static const DiagnosticWithoutArguments missingPrimaryConstructorParameters =
      diag.missingPrimaryConstructorParameters;

  /// No parameters.
  static const DiagnosticWithoutArguments missingStarAfterSync =
      diag.missingStarAfterSync;

  /// No parameters.
  static const DiagnosticWithoutArguments missingStatement =
      diag.missingStatement;

  /// Parameters:
  /// Object p0: the terminator that is missing
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  missingTerminatorForParameterGroup = diag.missingTerminatorForParameterGroup;

  /// No parameters.
  static const DiagnosticWithoutArguments missingTypedefParameters =
      diag.missingTypedefParameters;

  /// No parameters.
  static const DiagnosticWithoutArguments missingVariableInForEach =
      diag.missingVariableInForEach;

  /// No parameters.
  static const DiagnosticWithoutArguments mixedParameterGroups =
      diag.mixedParameterGroups;

  /// No parameters.
  static const DiagnosticWithoutArguments mixinDeclaresConstructor =
      diag.mixinDeclaresConstructor;

  /// No parameters.
  static const DiagnosticWithoutArguments mixinWithClause =
      diag.mixinWithClause;

  /// Parameters:
  /// String string: undocumented
  /// String string2: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required String string,
      required String string2,
    })
  >
  modifierOutOfOrder = diag.modifierOutOfOrder;

  /// Parameters:
  /// String string: undocumented
  /// String string2: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required String string,
      required String string2,
    })
  >
  multipleClauses = diag.multipleClauses;

  /// No parameters.
  static const DiagnosticWithoutArguments multipleExtendsClauses =
      diag.multipleExtendsClauses;

  /// No parameters.
  static const DiagnosticWithoutArguments multipleImplementsClauses =
      diag.multipleImplementsClauses;

  /// No parameters.
  static const DiagnosticWithoutArguments multipleLibraryDirectives =
      diag.multipleLibraryDirectives;

  /// No parameters.
  static const DiagnosticWithoutArguments multipleNamedParameterGroups =
      diag.multipleNamedParameterGroups;

  /// No parameters.
  static const DiagnosticWithoutArguments multipleOnClauses =
      diag.multipleOnClauses;

  /// No parameters.
  static const DiagnosticWithoutArguments multiplePartOfDirectives =
      diag.multiplePartOfDirectives;

  /// No parameters.
  static const DiagnosticWithoutArguments multiplePositionalParameterGroups =
      diag.multiplePositionalParameterGroups;

  /// No parameters.
  static const DiagnosticWithoutArguments multipleRepresentationFields =
      diag.multipleRepresentationFields;

  /// Parameters:
  /// Object p0: the number of variables being declared
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  multipleVariablesInForEach = diag.multipleVariablesInForEach;

  /// No parameters.
  static const DiagnosticWithoutArguments multipleVarianceModifiers =
      diag.multipleVarianceModifiers;

  /// No parameters.
  static const DiagnosticWithoutArguments multipleWithClauses =
      diag.multipleWithClauses;

  /// No parameters.
  static const DiagnosticWithoutArguments namedFunctionExpression =
      diag.namedFunctionExpression;

  /// No parameters.
  static const DiagnosticWithoutArguments namedFunctionType =
      diag.namedFunctionType;

  /// No parameters.
  static const DiagnosticWithoutArguments namedParameterOutsideGroup =
      diag.namedParameterOutsideGroup;

  /// No parameters.
  static const DiagnosticWithoutArguments nativeClauseInNonSdkCode =
      diag.nativeClauseInNonSdkCode;

  /// No parameters.
  static const DiagnosticWithoutArguments nativeClauseShouldBeAnnotation =
      diag.nativeClauseShouldBeAnnotation;

  /// No parameters.
  static const DiagnosticWithoutArguments nativeFunctionBodyInNonSdkCode =
      diag.nativeFunctionBodyInNonSdkCode;

  /// No parameters.
  static const DiagnosticWithoutArguments nonConstructorFactory =
      diag.nonConstructorFactory;

  /// No parameters.
  static const DiagnosticWithoutArguments nonIdentifierLibraryName =
      diag.nonIdentifierLibraryName;

  /// No parameters.
  static const DiagnosticWithoutArguments nonPartOfDirectiveInPart =
      diag.nonPartOfDirectiveInPart;

  /// No parameters.
  static const DiagnosticWithoutArguments nonStringLiteralAsUri =
      diag.nonStringLiteralAsUri;

  /// Parameters:
  /// Object p0: the operator that the user is trying to define
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  nonUserDefinableOperator = diag.nonUserDefinableOperator;

  /// No parameters.
  static const DiagnosticWithoutArguments normalBeforeOptionalParameters =
      diag.normalBeforeOptionalParameters;

  /// No parameters.
  static const DiagnosticWithoutArguments nullAwareCascadeOutOfOrder =
      diag.nullAwareCascadeOutOfOrder;

  /// Parameters:
  /// String string: undocumented
  /// String string2: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required String string,
      required String string2,
    })
  >
  outOfOrderClauses = diag.outOfOrderClauses;

  /// No parameters.
  static const DiagnosticWithoutArguments partOfName = diag.partOfName;

  /// Parameters:
  /// Name name: undocumented
  static const DiagnosticCode patternAssignmentDeclaresVariable =
      diag.patternAssignmentDeclaresVariable;

  /// No parameters.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments
  patternVariableDeclarationOutsideFunctionOrMethod =
      diag.patternVariableDeclarationOutsideFunctionOrMethod;

  /// No parameters.
  static const DiagnosticWithoutArguments positionalAfterNamedArgument =
      diag.positionalAfterNamedArgument;

  /// No parameters.
  static const DiagnosticWithoutArguments positionalParameterOutsideGroup =
      diag.positionalParameterOutsideGroup;

  /// No parameters.
  static const DiagnosticWithoutArguments prefixAfterCombinator =
      diag.prefixAfterCombinator;

  /// No parameters.
  static const DiagnosticWithoutArguments privateNamedNonFieldParameter =
      diag.privateNamedNonFieldParameter;

  /// No parameters.
  static const DiagnosticWithoutArguments privateOptionalParameter =
      diag.privateOptionalParameter;

  /// No parameters.
  static const DiagnosticWithoutArguments
  recordLiteralOnePositionalNoTrailingComma =
      diag.recordLiteralOnePositionalNoTrailingComma;

  /// No parameters.
  static const DiagnosticWithoutArguments
  recordTypeOnePositionalNoTrailingComma =
      diag.recordTypeOnePositionalNoTrailingComma;

  /// No parameters.
  static const DiagnosticWithoutArguments redirectingConstructorWithBody =
      diag.redirectingConstructorWithBody;

  /// No parameters.
  static const DiagnosticWithoutArguments redirectionInNonFactoryConstructor =
      diag.redirectionInNonFactoryConstructor;

  /// No parameters.
  static const DiagnosticWithoutArguments representationFieldModifier =
      diag.representationFieldModifier;

  /// No parameters.
  static const DiagnosticWithoutArguments representationFieldTrailingComma =
      diag.representationFieldTrailingComma;

  /// No parameters.
  static const DiagnosticWithoutArguments sealedEnum = diag.sealedEnum;

  /// No parameters.
  static const DiagnosticWithoutArguments sealedMixin = diag.sealedMixin;

  /// No parameters.
  static const DiagnosticWithoutArguments sealedMixinClass =
      diag.sealedMixinClass;

  /// No parameters.
  static const DiagnosticWithoutArguments setterConstructor =
      diag.setterConstructor;

  /// No parameters.
  static const DiagnosticWithoutArguments setterInFunction =
      diag.setterInFunction;

  /// No parameters.
  static const DiagnosticWithoutArguments stackOverflow = diag.stackOverflow;

  /// No parameters.
  static const DiagnosticWithoutArguments staticConstructor =
      diag.staticConstructor;

  /// No parameters.
  static const DiagnosticWithoutArguments staticGetterWithoutBody =
      diag.staticGetterWithoutBody;

  /// No parameters.
  static const DiagnosticWithoutArguments staticOperator = diag.staticOperator;

  /// No parameters.
  static const DiagnosticWithoutArguments staticSetterWithoutBody =
      diag.staticSetterWithoutBody;

  /// No parameters.
  static const DiagnosticWithoutArguments switchHasCaseAfterDefaultCase =
      diag.switchHasCaseAfterDefaultCase;

  /// No parameters.
  static const DiagnosticWithoutArguments switchHasMultipleDefaultCases =
      diag.switchHasMultipleDefaultCases;

  /// No parameters.
  static const DiagnosticWithoutArguments topLevelOperator =
      diag.topLevelOperator;

  /// Parameters:
  /// Name name: undocumented
  static const DiagnosticCode typeArgumentsOnTypeVariable =
      diag.typeArgumentsOnTypeVariable;

  /// No parameters.
  static const DiagnosticWithoutArguments typeBeforeFactory =
      diag.typeBeforeFactory;

  /// No parameters.
  static const DiagnosticWithoutArguments typedefInClass = diag.typedefInClass;

  /// No parameters.
  static const DiagnosticWithoutArguments typeParameterOnConstructor =
      diag.typeParameterOnConstructor;

  /// 7.1.1 Operators: Type parameters are not syntactically supported on an
  /// operator.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments typeParameterOnOperator =
      diag.typeParameterOnOperator;

  /// Parameters:
  /// Object p0: the starting character that was missing
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  unexpectedTerminatorForParameterGroup =
      diag.unexpectedTerminatorForParameterGroup;

  /// Parameters:
  /// String p0: the unexpected text that was found
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  unexpectedToken = diag.unexpectedToken;

  /// No parameters.
  static const DiagnosticWithoutArguments unexpectedTokens =
      diag.unexpectedTokens;

  /// No parameters.
  static const DiagnosticWithoutArguments varAndType = diag.varAndType;

  /// No parameters.
  static const DiagnosticWithoutArguments varAsTypeName = diag.varAsTypeName;

  /// No parameters.
  static const DiagnosticWithoutArguments varClass = diag.varClass;

  /// No parameters.
  static const DiagnosticWithoutArguments varEnum = diag.varEnum;

  /// No parameters.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments
  variablePatternKeywordInDeclarationContext =
      diag.variablePatternKeywordInDeclarationContext;

  /// No parameters.
  static const DiagnosticWithoutArguments varReturnType = diag.varReturnType;

  /// No parameters.
  static const DiagnosticWithoutArguments varTypedef = diag.varTypedef;

  /// No parameters.
  static const DiagnosticWithoutArguments voidWithTypeArguments =
      diag.voidWithTypeArguments;

  /// No parameters.
  static const DiagnosticWithoutArguments withBeforeExtends =
      diag.withBeforeExtends;

  /// No parameters.
  static const DiagnosticWithoutArguments wrongNumberOfParametersForSetter =
      diag.wrongNumberOfParametersForSetter;

  /// No parameters.
  static const DiagnosticWithoutArguments wrongSeparatorForPositionalParameter =
      diag.wrongSeparatorForPositionalParameter;

  /// Parameters:
  /// Object p0: the terminator that was expected
  /// Object p1: the terminator that was found
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  wrongTerminatorForParameterGroup = diag.wrongTerminatorForParameterGroup;

  /// Do not construct instances of this class.
  ParserErrorCode._() : assert(false);
}

class ScannerErrorCode {
  /// No parameters.
  static const DiagnosticWithoutArguments encoding = diag.encoding;

  /// Parameters:
  /// Object p0: the illegal character
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  illegalCharacter = diag.illegalCharacter;

  /// No parameters.
  static const DiagnosticWithoutArguments missingDigit = diag.missingDigit;

  /// No parameters.
  static const DiagnosticWithoutArguments missingHexDigit =
      diag.missingHexDigit;

  /// No parameters.
  static const DiagnosticWithoutArguments missingQuote = diag.missingQuote;

  /// Parameters:
  /// Object p0: the path of the file that cannot be read
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  unableGetContent = diag.unableGetContent;

  /// No parameters.
  static const DiagnosticWithoutArguments unexpectedDollarInString =
      diag.unexpectedDollarInString;

  /// No parameters.
  static const DiagnosticWithoutArguments unexpectedSeparatorInNumber =
      diag.unexpectedSeparatorInNumber;

  /// Parameters:
  /// String p0: the unsupported operator
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  unsupportedOperator = diag.unsupportedOperator;

  /// No parameters.
  static const DiagnosticWithoutArguments unterminatedMultiLineComment =
      diag.unterminatedMultiLineComment;

  /// No parameters.
  static const DiagnosticWithoutArguments unterminatedStringLiteral =
      diag.unterminatedStringLiteral;

  /// Do not construct instances of this class.
  ScannerErrorCode._() : assert(false);
}
