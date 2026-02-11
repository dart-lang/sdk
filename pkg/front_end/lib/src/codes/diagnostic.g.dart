// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// NOTE: THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/front_end/messages.yaml' and defer to it for the
// commands to update this file.

// ignore_for_file: lines_longer_than_80_chars

part of 'diagnostic.dart';

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode abstractClassConstructorTearOff = const MessageCode(
  "AbstractClassConstructorTearOff",
  problemMessage: """Constructors on abstract classes can't be torn off.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name})>
abstractClassInstantiation = const Template(
  "AbstractClassInstantiation",
  withArguments: _withArgumentsAbstractClassInstantiation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsAbstractClassInstantiation({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    abstractClassInstantiation,
    problemMessage:
        """The class '${name_0}' is abstract and can't be instantiated.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode abstractFieldConstructorInitializer = const MessageCode(
  "AbstractFieldConstructorInitializer",
  problemMessage: """Abstract fields cannot have initializers.""",
  correctionMessage:
      """Try removing the field initializer or the 'abstract' keyword from the field declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode abstractFieldInitializer = const MessageCode(
  "AbstractFieldInitializer",
  problemMessage: """Abstract fields cannot have initializers.""",
  correctionMessage:
      """Try removing the initializer or the 'abstract' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name})>
abstractRedirectedClassInstantiation = const Template(
  "AbstractRedirectedClassInstantiation",
  withArguments: _withArgumentsAbstractRedirectedClassInstantiation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsAbstractRedirectedClassInstantiation({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    abstractRedirectedClassInstantiation,
    problemMessage:
        """Factory redirects to class '${name_0}', which is abstract and can't be instantiated.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode ambiguousExtensionCause = const MessageCode(
  "AmbiguousExtensionCause",
  severity: CfeSeverity.context,
  problemMessage: """This is one of the extension members.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name, required DartType type})>
ambiguousExtensionMethod = const Template(
  "AmbiguousExtensionMethod",
  withArguments: _withArgumentsAmbiguousExtensionMethod,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsAmbiguousExtensionMethod({
  required String name,
  required DartType type,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    ambiguousExtensionMethod,
    problemMessage:
        """The method '${name_0}' is defined in multiple extensions for '${type_0}' and neither is more specific.""" +
        labeler.originMessages,
    correctionMessage:
        """Try using an explicit extension application of the wanted extension or hiding unwanted extensions from scope.""",
    arguments: {'name': name, 'type': type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name, required DartType type})>
ambiguousExtensionOperator = const Template(
  "AmbiguousExtensionOperator",
  withArguments: _withArgumentsAmbiguousExtensionOperator,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsAmbiguousExtensionOperator({
  required String name,
  required DartType type,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    ambiguousExtensionOperator,
    problemMessage:
        """The operator '${name_0}' is defined in multiple extensions for '${type_0}' and neither is more specific.""" +
        labeler.originMessages,
    correctionMessage:
        """Try using an explicit extension application of the wanted extension or hiding unwanted extensions from scope.""",
    arguments: {'name': name, 'type': type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name, required DartType type})>
ambiguousExtensionProperty = const Template(
  "AmbiguousExtensionProperty",
  withArguments: _withArgumentsAmbiguousExtensionProperty,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsAmbiguousExtensionProperty({
  required String name,
  required DartType type,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    ambiguousExtensionProperty,
    problemMessage:
        """The property '${name_0}' is defined in multiple extensions for '${type_0}' and neither is more specific.""" +
        labeler.originMessages,
    correctionMessage:
        """Try using an explicit extension application of the wanted extension or hiding unwanted extensions from scope.""",
    arguments: {'name': name, 'type': type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String name,
    required DartType type1,
    required DartType type2,
  })
>
ambiguousSupertypes = const Template(
  "AmbiguousSupertypes",
  withArguments: _withArgumentsAmbiguousSupertypes,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsAmbiguousSupertypes({
  required String name,
  required DartType type1,
  required DartType type2,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  TypeLabeler labeler = new TypeLabeler();
  var type1_0 = labeler.labelType(type1);
  var type2_0 = labeler.labelType(type2);
  return new Message(
    ambiguousSupertypes,
    problemMessage:
        """'${name_0}' can't implement both '${type1_0}' and '${type2_0}'""" +
        labeler.originMessages,
    arguments: {'name': name, 'type1': type1, 'type2': type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode annotationOnFunctionTypeTypeParameter = const MessageCode(
  "AnnotationOnFunctionTypeTypeParameter",
  problemMessage:
      """A type variable on a function type can't have annotations.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode anonymousBreakTargetOutsideFunction = const MessageCode(
  "AnonymousBreakTargetOutsideFunction",
  problemMessage: """Can't break to a target in a different function.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode anonymousContinueTargetOutsideFunction = const MessageCode(
  "AnonymousContinueTargetOutsideFunction",
  problemMessage: """Can't continue at a target in a different function.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required DartType actualType,
    required DartType expectedType,
  })
>
argumentTypeNotAssignable = const Template(
  "ArgumentTypeNotAssignable",
  withArguments: _withArgumentsArgumentTypeNotAssignable,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsArgumentTypeNotAssignable({
  required DartType actualType,
  required DartType expectedType,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var actualType_0 = labeler.labelType(actualType);
  var expectedType_0 = labeler.labelType(expectedType);
  return new Message(
    argumentTypeNotAssignable,
    problemMessage:
        """The argument type '${actualType_0}' can't be assigned to the parameter type '${expectedType_0}'.""" +
        labeler.originMessages,
    arguments: {'actualType': actualType, 'expectedType': expectedType},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode awaitInLateLocalInitializer = const MessageCode(
  "AwaitInLateLocalInitializer",
  problemMessage:
      """`await` expressions are not supported in late local initializers.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode awaitOfExtensionTypeNotFuture = const MessageCode(
  "AwaitOfExtensionTypeNotFuture",
  problemMessage:
      """The 'await' expression can't be used for an expression with an extension type that is not a subtype of 'Future'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String typeName})>
baseClassImplementedOutsideOfLibrary = const Template(
  "BaseClassImplementedOutsideOfLibrary",
  withArguments: _withArgumentsBaseClassImplementedOutsideOfLibrary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsBaseClassImplementedOutsideOfLibrary({
  required String typeName,
}) {
  var typeName_0 = conversions.validateAndDemangleName(typeName);
  return new Message(
    baseClassImplementedOutsideOfLibrary,
    problemMessage:
        """The class '${typeName_0}' can't be implemented outside of its library because it's a base class.""",
    arguments: {'typeName': typeName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String typeName})>
baseMixinImplementedOutsideOfLibrary = const Template(
  "BaseMixinImplementedOutsideOfLibrary",
  withArguments: _withArgumentsBaseMixinImplementedOutsideOfLibrary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsBaseMixinImplementedOutsideOfLibrary({
  required String typeName,
}) {
  var typeName_0 = conversions.validateAndDemangleName(typeName);
  return new Message(
    baseMixinImplementedOutsideOfLibrary,
    problemMessage:
        """The mixin '${typeName_0}' can't be implemented outside of its library because it's a base mixin.""",
    arguments: {'typeName': typeName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String subtypeName, required String causeName})
>
baseOrFinalClassImplementedOutsideOfLibraryCause = const Template(
  "BaseOrFinalClassImplementedOutsideOfLibraryCause",
  withArguments: _withArgumentsBaseOrFinalClassImplementedOutsideOfLibraryCause,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsBaseOrFinalClassImplementedOutsideOfLibraryCause({
  required String subtypeName,
  required String causeName,
}) {
  var subtypeName_0 = conversions.validateAndDemangleName(subtypeName);
  var causeName_0 = conversions.validateAndDemangleName(causeName);
  return new Message(
    baseOrFinalClassImplementedOutsideOfLibraryCause,
    problemMessage:
        """The type '${subtypeName_0}' is a subtype of '${causeName_0}', and '${causeName_0}' is defined here.""",
    arguments: {'subtypeName': subtypeName, 'causeName': causeName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String typeName, required String firstTypeInCycle})
>
boundIssueViaCycleNonSimplicity = const Template(
  "BoundIssueViaCycleNonSimplicity",
  withArguments: _withArgumentsBoundIssueViaCycleNonSimplicity,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsBoundIssueViaCycleNonSimplicity({
  required String typeName,
  required String firstTypeInCycle,
}) {
  var typeName_0 = conversions.validateAndDemangleName(typeName);
  var firstTypeInCycle_0 = conversions.validateAndDemangleName(
    firstTypeInCycle,
  );
  return new Message(
    boundIssueViaCycleNonSimplicity,
    problemMessage:
        """Generic type '${typeName_0}' can't be used without type arguments in the bounds of its own type variables. It is referenced indirectly through '${firstTypeInCycle_0}'.""",
    correctionMessage:
        """Try providing type arguments to '${firstTypeInCycle_0}' here or to some other raw types in the bounds along the reference chain.""",
    arguments: {'typeName': typeName, 'firstTypeInCycle': firstTypeInCycle},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String typeName})>
boundIssueViaLoopNonSimplicity = const Template(
  "BoundIssueViaLoopNonSimplicity",
  withArguments: _withArgumentsBoundIssueViaLoopNonSimplicity,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsBoundIssueViaLoopNonSimplicity({
  required String typeName,
}) {
  var typeName_0 = conversions.validateAndDemangleName(typeName);
  return new Message(
    boundIssueViaLoopNonSimplicity,
    problemMessage:
        """Generic type '${typeName_0}' can't be used without type arguments in the bounds of its own type variables.""",
    correctionMessage:
        """Try providing type arguments to '${typeName_0}' here.""",
    arguments: {'typeName': typeName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String typeName})>
boundIssueViaRawTypeWithNonSimpleBounds = const Template(
  "BoundIssueViaRawTypeWithNonSimpleBounds",
  withArguments: _withArgumentsBoundIssueViaRawTypeWithNonSimpleBounds,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsBoundIssueViaRawTypeWithNonSimpleBounds({
  required String typeName,
}) {
  var typeName_0 = conversions.validateAndDemangleName(typeName);
  return new Message(
    boundIssueViaRawTypeWithNonSimpleBounds,
    problemMessage:
        """Generic type '${typeName_0}' can't be used without type arguments in a type variable bound.""",
    correctionMessage:
        """Try providing type arguments to '${typeName_0}' here.""",
    arguments: {'typeName': typeName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String label})>
breakTargetOutsideFunction = const Template(
  "BreakTargetOutsideFunction",
  withArguments: _withArgumentsBreakTargetOutsideFunction,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsBreakTargetOutsideFunction({required String label}) {
  var label_0 = conversions.validateAndDemangleName(label);
  return new Message(
    breakTargetOutsideFunction,
    problemMessage: """Can't break to '${label_0}' in a different function.""",
    arguments: {'label': label},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode candidateFound = const MessageCode(
  "CandidateFound",
  severity: CfeSeverity.context,
  problemMessage: """Found this candidate, but the arguments don't match.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name})>
candidateFoundIsDefaultConstructor = const Template(
  "CandidateFoundIsDefaultConstructor",
  withArguments: _withArgumentsCandidateFoundIsDefaultConstructor,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCandidateFoundIsDefaultConstructor({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    candidateFoundIsDefaultConstructor,
    problemMessage:
        """The class '${name_0}' has a constructor that takes no arguments.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String variableName})>
cannotAssignToConstVariable = const Template(
  "CannotAssignToConstVariable",
  withArguments: _withArgumentsCannotAssignToConstVariable,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCannotAssignToConstVariable({
  required String variableName,
}) {
  var variableName_0 = conversions.validateAndDemangleName(variableName);
  return new Message(
    cannotAssignToConstVariable,
    problemMessage:
        """Can't assign to the const variable '${variableName_0}'.""",
    arguments: {'variableName': variableName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode cannotAssignToExtensionThis = const MessageCode(
  "CannotAssignToExtensionThis",
  problemMessage: """Can't assign to 'this'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String variableName})>
cannotAssignToFinalVariable = const Template(
  "CannotAssignToFinalVariable",
  withArguments: _withArgumentsCannotAssignToFinalVariable,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCannotAssignToFinalVariable({
  required String variableName,
}) {
  var variableName_0 = conversions.validateAndDemangleName(variableName);
  return new Message(
    cannotAssignToFinalVariable,
    problemMessage:
        """Can't assign to the final variable '${variableName_0}'.""",
    arguments: {'variableName': variableName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode cannotAssignToParenthesizedExpression = const MessageCode(
  "CannotAssignToParenthesizedExpression",
  problemMessage: """Can't assign to a parenthesized expression.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode cannotAssignToSuper = const MessageCode(
  "CannotAssignToSuper",
  problemMessage: """Can't assign to super.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode cannotAssignToTypeLiteral = const MessageCode(
  "CannotAssignToTypeLiteral",
  problemMessage: """Can't assign to a type literal.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String details})>
cannotReadSdkSpecification = const Template(
  "CannotReadSdkSpecification",
  withArguments: _withArgumentsCannotReadSdkSpecification,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCannotReadSdkSpecification({required String details}) {
  var details_0 = conversions.validateString(details);
  return new Message(
    cannotReadSdkSpecification,
    problemMessage: """Unable to read the 'libraries.json' specification file:
  ${details_0}.""",
    arguments: {'details': details},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode cantDisambiguateAmbiguousInformation = const MessageCode(
  "CantDisambiguateAmbiguousInformation",
  problemMessage:
      """Both Iterable and Map spread elements encountered in ambiguous literal.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode cantDisambiguateNotEnoughInformation = const MessageCode(
  "CantDisambiguateNotEnoughInformation",
  problemMessage:
      """Not enough type information to disambiguate between literal set and literal map.""",
  correctionMessage:
      """Try providing type arguments for the literal explicitly to disambiguate it.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name})>
cantHaveNamedParameters = const Template(
  "CantHaveNamedParameters",
  withArguments: _withArgumentsCantHaveNamedParameters,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCantHaveNamedParameters({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    cantHaveNamedParameters,
    problemMessage: """'${name_0}' can't be declared with named parameters.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name})>
cantHaveOptionalParameters = const Template(
  "CantHaveOptionalParameters",
  withArguments: _withArgumentsCantHaveOptionalParameters,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCantHaveOptionalParameters({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    cantHaveOptionalParameters,
    problemMessage:
        """'${name_0}' can't be declared with optional parameters.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode cantInferPackagesFromManyInputs = const MessageCode(
  "CantInferPackagesFromManyInputs",
  problemMessage:
      """Can't infer a packages file when compiling multiple inputs.""",
  correctionMessage:
      """Try specifying the file explicitly with the --packages option.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode cantInferPackagesFromPackageUri = const MessageCode(
  "CantInferPackagesFromPackageUri",
  problemMessage:
      """Can't infer a packages file from an input 'package:*' URI.""",
  correctionMessage:
      """Try specifying the file explicitly with the --packages option.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name})>
cantInferReturnTypeDueToNoCombinedSignature = const Template(
  "CantInferReturnTypeDueToNoCombinedSignature",
  withArguments: _withArgumentsCantInferReturnTypeDueToNoCombinedSignature,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCantInferReturnTypeDueToNoCombinedSignature({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    cantInferReturnTypeDueToNoCombinedSignature,
    problemMessage:
        """Can't infer a return type for '${name_0}' as the overridden members don't have a combined signature.""",
    correctionMessage: """Try adding an explicit type.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name})>
cantInferTypeDueToCircularity = const Template(
  "CantInferTypeDueToCircularity",
  withArguments: _withArgumentsCantInferTypeDueToCircularity,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCantInferTypeDueToCircularity({required String name}) {
  var name_0 = conversions.validateString(name);
  return new Message(
    cantInferTypeDueToCircularity,
    problemMessage:
        """Can't infer the type of '${name_0}': circularity found during type inference.""",
    correctionMessage: """Specify the type explicitly.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name})>
cantInferTypeDueToNoCombinedSignature = const Template(
  "CantInferTypeDueToNoCombinedSignature",
  withArguments: _withArgumentsCantInferTypeDueToNoCombinedSignature,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCantInferTypeDueToNoCombinedSignature({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    cantInferTypeDueToNoCombinedSignature,
    problemMessage:
        """Can't infer a type for '${name_0}' as the overridden members don't have a combined signature.""",
    correctionMessage: """Try adding an explicit type.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name})>
cantInferTypesDueToNoCombinedSignature = const Template(
  "CantInferTypesDueToNoCombinedSignature",
  withArguments: _withArgumentsCantInferTypesDueToNoCombinedSignature,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCantInferTypesDueToNoCombinedSignature({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    cantInferTypesDueToNoCombinedSignature,
    problemMessage:
        """Can't infer types for '${name_0}' as the overridden members don't have a combined signature.""",
    correctionMessage: """Try adding explicit types.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required Uri uri, required String details})>
cantReadFile = const Template(
  "CantReadFile",
  withArguments: _withArgumentsCantReadFile,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCantReadFile({
  required Uri uri,
  required String details,
}) {
  var uri_0 = conversions.relativizeUri(uri);
  var details_0 = conversions.validateString(details);
  return new Message(
    cantReadFile,
    problemMessage: """Error when reading '${uri_0}': ${details_0}""",
    arguments: {'uri': uri, 'details': details},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String className})>
cantUseClassAsMixin = const Template(
  "CantUseClassAsMixin",
  withArguments: _withArgumentsCantUseClassAsMixin,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCantUseClassAsMixin({required String className}) {
  var className_0 = conversions.validateAndDemangleName(className);
  return new Message(
    cantUseClassAsMixin,
    problemMessage:
        """The class '${className_0}' can't be used as a mixin because it isn't a mixin class nor a mixin.""",
    arguments: {'className': className},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required Token token})>
cantUseControlFlowOrSpreadAsConstant = const Template(
  "CantUseControlFlowOrSpreadAsConstant",
  withArguments: _withArgumentsCantUseControlFlowOrSpreadAsConstant,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCantUseControlFlowOrSpreadAsConstant({
  required Token token,
}) {
  var token_0 = conversions.tokenToLexeme(token);
  return new Message(
    cantUseControlFlowOrSpreadAsConstant,
    problemMessage:
        """'${token_0}' is not supported in constant expressions.""",
    arguments: {'token': token},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required Token token})>
cantUseDeferredPrefixAsConstant = const Template(
  "CantUseDeferredPrefixAsConstant",
  withArguments: _withArgumentsCantUseDeferredPrefixAsConstant,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCantUseDeferredPrefixAsConstant({required Token token}) {
  var token_0 = conversions.tokenToLexeme(token);
  return new Message(
    cantUseDeferredPrefixAsConstant,
    problemMessage:
        """'${token_0}' can't be used in a constant expression because it's marked as 'deferred' which means it isn't available until loaded.""",
    correctionMessage:
        """Try moving the constant from the deferred library, or removing 'deferred' from the import.""",
    arguments: {'token': token},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode cantUsePrefixAsExpression = const MessageCode(
  "CantUsePrefixAsExpression",
  problemMessage: """A prefix can't be used as an expression.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode cantUsePrefixWithNullAware = const MessageCode(
  "CantUsePrefixWithNullAware",
  problemMessage: """A prefix can't be used with null-aware operators.""",
  correctionMessage: """Try replacing '?.' with '.'""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode classImplementsDeferredClass = const MessageCode(
  "ClassImplementsDeferredClass",
  problemMessage: """Classes and mixins can't implement deferred classes.""",
  correctionMessage:
      """Try specifying a different interface, removing the class from the list, or changing the import to not be deferred.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name})>
classShouldBeListedAsCallableInDynamicInterface = const Template(
  "ClassShouldBeListedAsCallableInDynamicInterface",
  withArguments: _withArgumentsClassShouldBeListedAsCallableInDynamicInterface,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsClassShouldBeListedAsCallableInDynamicInterface({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    classShouldBeListedAsCallableInDynamicInterface,
    problemMessage: """Cannot use class '${name_0}' in a dynamic module.""",
    correctionMessage:
        """Try removing the reference to class '${name_0}' or update the dynamic interface to list class '${name_0}' as callable.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name})>
classShouldBeListedAsExtendableInDynamicInterface = const Template(
  "ClassShouldBeListedAsExtendableInDynamicInterface",
  withArguments:
      _withArgumentsClassShouldBeListedAsExtendableInDynamicInterface,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsClassShouldBeListedAsExtendableInDynamicInterface({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    classShouldBeListedAsExtendableInDynamicInterface,
    problemMessage:
        """Cannot extend, implement or mix-in class '${name_0}' in a dynamic module.""",
    correctionMessage:
        """Try removing the reference to class '${name_0}' or update the dynamic interface to list class '${name_0}' as extendable.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String className, required String memberName})
>
combinedMemberSignatureFailed = const Template(
  "CombinedMemberSignatureFailed",
  withArguments: _withArgumentsCombinedMemberSignatureFailed,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCombinedMemberSignatureFailed({
  required String className,
  required String memberName,
}) {
  var className_0 = conversions.validateAndDemangleName(className);
  var memberName_0 = conversions.validateAndDemangleName(memberName);
  return new Message(
    combinedMemberSignatureFailed,
    problemMessage:
        """Class '${className_0}' inherits multiple members named '${memberName_0}' with incompatible signatures.""",
    correctionMessage:
        """Try adding a declaration of '${memberName_0}' to '${className_0}'.""",
    arguments: {'className': className, 'memberName': memberName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String fieldName})>
conflictsWithImplicitSetter = const Template(
  "ConflictsWithImplicitSetter",
  withArguments: _withArgumentsConflictsWithImplicitSetter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConflictsWithImplicitSetter({required String fieldName}) {
  var fieldName_0 = conversions.validateAndDemangleName(fieldName);
  return new Message(
    conflictsWithImplicitSetter,
    problemMessage:
        """Conflicts with the implicit setter of the field '${fieldName_0}'.""",
    arguments: {'fieldName': fieldName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String fieldName})>
conflictsWithImplicitSetterCause = const Template(
  "ConflictsWithImplicitSetterCause",
  withArguments: _withArgumentsConflictsWithImplicitSetterCause,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConflictsWithImplicitSetterCause({
  required String fieldName,
}) {
  var fieldName_0 = conversions.validateAndDemangleName(fieldName);
  return new Message(
    conflictsWithImplicitSetterCause,
    problemMessage: """Field '${fieldName_0}' with the implicit setter.""",
    arguments: {'fieldName': fieldName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String typeVariableName})>
conflictsWithTypeParameter = const Template(
  "ConflictsWithTypeParameter",
  withArguments: _withArgumentsConflictsWithTypeParameter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConflictsWithTypeParameter({
  required String typeVariableName,
}) {
  var typeVariableName_0 = conversions.validateAndDemangleName(
    typeVariableName,
  );
  return new Message(
    conflictsWithTypeParameter,
    problemMessage: """Conflicts with type variable '${typeVariableName_0}'.""",
    arguments: {'typeVariableName': typeVariableName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode conflictsWithTypeParameterCause = const MessageCode(
  "ConflictsWithTypeParameterCause",
  severity: CfeSeverity.context,
  problemMessage: """This is the type variable.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode constConstructorLateFinalFieldCause = const MessageCode(
  "ConstConstructorLateFinalFieldCause",
  severity: CfeSeverity.context,
  problemMessage: """This constructor is const.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode constConstructorLateFinalFieldError = const MessageCode(
  "ConstConstructorLateFinalFieldError",
  problemMessage:
      """Can't have a late final field in a class with a const constructor.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode constConstructorNonFinalField = const MessageCode(
  "ConstConstructorNonFinalField",
  problemMessage:
      """Constructor is marked 'const' so all fields must be final.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode constConstructorNonFinalFieldCause = const MessageCode(
  "ConstConstructorNonFinalFieldCause",
  severity: CfeSeverity.context,
  problemMessage: """Field isn't final, but constructor is 'const'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode constConstructorRedirectionToNonConst = const MessageCode(
  "ConstConstructorRedirectionToNonConst",
  problemMessage:
      """A constant constructor can't call a non-constant constructor.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode constConstructorWithNonConstSuper = const MessageCode(
  "ConstConstructorWithNonConstSuper",
  problemMessage:
      """A constant constructor can't call a non-constant super constructor.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required Constant constant})>
constEvalCaseImplementsEqual = const Template(
  "ConstEvalCaseImplementsEqual",
  withArguments: _withArgumentsConstEvalCaseImplementsEqual,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalCaseImplementsEqual({
  required Constant constant,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var constant_0 = labeler.labelConstant(constant);
  return new Message(
    constEvalCaseImplementsEqual,
    problemMessage:
        """Case expression '${constant_0}' does not have a primitive operator '=='.""" +
        labeler.originMessages,
    arguments: {'constant': constant},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode constEvalCircularity = const MessageCode(
  "ConstEvalCircularity",
  problemMessage: """Constant expression depends on itself.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode constEvalContext = const MessageCode(
  "ConstEvalContext",
  severity: CfeSeverity.context,
  problemMessage: """While analyzing:""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String importName})>
constEvalDeferredLibrary = const Template(
  "ConstEvalDeferredLibrary",
  withArguments: _withArgumentsConstEvalDeferredLibrary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalDeferredLibrary({required String importName}) {
  var importName_0 = conversions.nameOrUnnamed(importName);
  return new Message(
    constEvalDeferredLibrary,
    problemMessage:
        """'${importName_0}' can't be used in a constant expression because it's marked as 'deferred' which means it isn't available until loaded.""",
    correctionMessage:
        """Try moving the constant from the deferred library, or removing 'deferred' from the import.""",
    arguments: {'importName': importName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required Constant element})>
constEvalDuplicateElement = const Template(
  "ConstEvalDuplicateElement",
  withArguments: _withArgumentsConstEvalDuplicateElement,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalDuplicateElement({required Constant element}) {
  TypeLabeler labeler = new TypeLabeler();
  var element_0 = labeler.labelConstant(element);
  return new Message(
    constEvalDuplicateElement,
    problemMessage:
        """The element '${element_0}' conflicts with another existing element in the set.""" +
        labeler.originMessages,
    arguments: {'element': element},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required Constant key})>
constEvalDuplicateKey = const Template(
  "ConstEvalDuplicateKey",
  withArguments: _withArgumentsConstEvalDuplicateKey,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalDuplicateKey({required Constant key}) {
  TypeLabeler labeler = new TypeLabeler();
  var key_0 = labeler.labelConstant(key);
  return new Message(
    constEvalDuplicateKey,
    problemMessage:
        """The key '${key_0}' conflicts with another existing key in the map.""" +
        labeler.originMessages,
    arguments: {'key': key},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required Constant element})>
constEvalElementImplementsEqual = const Template(
  "ConstEvalElementImplementsEqual",
  withArguments: _withArgumentsConstEvalElementImplementsEqual,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalElementImplementsEqual({
  required Constant element,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var element_0 = labeler.labelConstant(element);
  return new Message(
    constEvalElementImplementsEqual,
    problemMessage:
        """The element '${element_0}' does not have a primitive operator '=='.""" +
        labeler.originMessages,
    arguments: {'element': element},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required Constant element})>
constEvalElementNotPrimitiveEquality = const Template(
  "ConstEvalElementNotPrimitiveEquality",
  withArguments: _withArgumentsConstEvalElementNotPrimitiveEquality,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalElementNotPrimitiveEquality({
  required Constant element,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var element_0 = labeler.labelConstant(element);
  return new Message(
    constEvalElementNotPrimitiveEquality,
    problemMessage:
        """The element '${element_0}' does not have a primitive equality.""" +
        labeler.originMessages,
    arguments: {'element': element},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required Constant receiver, required DartType actualType})
>
constEvalEqualsOperandNotPrimitiveEquality = const Template(
  "ConstEvalEqualsOperandNotPrimitiveEquality",
  withArguments: _withArgumentsConstEvalEqualsOperandNotPrimitiveEquality,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalEqualsOperandNotPrimitiveEquality({
  required Constant receiver,
  required DartType actualType,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var receiver_0 = labeler.labelConstant(receiver);
  var actualType_0 = labeler.labelType(actualType);
  return new Message(
    constEvalEqualsOperandNotPrimitiveEquality,
    problemMessage:
        """Binary operator '==' requires receiver constant '${receiver_0}' of a type with primitive equality or type 'double', but was of type '${actualType_0}'.""" +
        labeler.originMessages,
    arguments: {'receiver': receiver, 'actualType': actualType},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String message})> constEvalError =
    const Template(
      "ConstEvalError",
      withArguments: _withArgumentsConstEvalError,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalError({required String message}) {
  var message_0 = conversions.validateString(message);
  return new Message(
    constEvalError,
    problemMessage: """Error evaluating constant expression: ${message_0}""",
    arguments: {'message': message},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode constEvalExtension = const MessageCode(
  "ConstEvalExtension",
  problemMessage:
      """Extension operations can't be used in constant expressions.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode constEvalExternalConstructor = const MessageCode(
  "ConstEvalExternalConstructor",
  problemMessage:
      """External constructors can't be evaluated in constant expressions.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode constEvalExternalFactory = const MessageCode(
  "ConstEvalExternalFactory",
  problemMessage:
      """External factory constructors can't be evaluated in constant expressions.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode constEvalFailedAssertion = const MessageCode(
  "ConstEvalFailedAssertion",
  problemMessage: """This assertion failed.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String message})>
constEvalFailedAssertionWithMessage = const Template(
  "ConstEvalFailedAssertionWithMessage",
  withArguments: _withArgumentsConstEvalFailedAssertionWithMessage,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalFailedAssertionWithMessage({
  required String message,
}) {
  var message_0 = conversions.stringOrEmpty(message);
  return new Message(
    constEvalFailedAssertionWithMessage,
    problemMessage: """This assertion failed with message: ${message_0}""",
    arguments: {'message': message},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode constEvalFailedAssertionWithNonStringMessage =
    const MessageCode(
      "ConstEvalFailedAssertionWithNonStringMessage",
      problemMessage: """This assertion failed with a non-String message.""",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name})>
constEvalGetterNotFound = const Template(
  "ConstEvalGetterNotFound",
  withArguments: _withArgumentsConstEvalGetterNotFound,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalGetterNotFound({required String name}) {
  var name_0 = conversions.nameOrUnnamed(name);
  return new Message(
    constEvalGetterNotFound,
    problemMessage: """Variable get not found: '${name_0}'""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String operator,
    required Constant receiver,
    required DartType expectedType,
    required DartType actualType,
  })
>
constEvalInvalidBinaryOperandType = const Template(
  "ConstEvalInvalidBinaryOperandType",
  withArguments: _withArgumentsConstEvalInvalidBinaryOperandType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalInvalidBinaryOperandType({
  required String operator,
  required Constant receiver,
  required DartType expectedType,
  required DartType actualType,
}) {
  var operator_0 = conversions.stringOrEmpty(operator);
  TypeLabeler labeler = new TypeLabeler();
  var receiver_0 = labeler.labelConstant(receiver);
  var expectedType_0 = labeler.labelType(expectedType);
  var actualType_0 = labeler.labelType(actualType);
  return new Message(
    constEvalInvalidBinaryOperandType,
    problemMessage:
        """Binary operator '${operator_0}' on '${receiver_0}' requires operand of type '${expectedType_0}', but was of type '${actualType_0}'.""" +
        labeler.originMessages,
    arguments: {
      'operator': operator,
      'receiver': receiver,
      'expectedType': expectedType,
      'actualType': actualType,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required Constant receiver, required DartType actualType})
>
constEvalInvalidEqualsOperandType = const Template(
  "ConstEvalInvalidEqualsOperandType",
  withArguments: _withArgumentsConstEvalInvalidEqualsOperandType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalInvalidEqualsOperandType({
  required Constant receiver,
  required DartType actualType,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var receiver_0 = labeler.labelConstant(receiver);
  var actualType_0 = labeler.labelType(actualType);
  return new Message(
    constEvalInvalidEqualsOperandType,
    problemMessage:
        """Binary operator '==' requires receiver constant '${receiver_0}' of type 'Null', 'bool', 'int', 'double', or 'String', but was of type '${actualType_0}'.""" +
        labeler.originMessages,
    arguments: {'receiver': receiver, 'actualType': actualType},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String method, required Constant receiver})
>
constEvalInvalidMethodInvocation = const Template(
  "ConstEvalInvalidMethodInvocation",
  withArguments: _withArgumentsConstEvalInvalidMethodInvocation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalInvalidMethodInvocation({
  required String method,
  required Constant receiver,
}) {
  var method_0 = conversions.stringOrEmpty(method);
  TypeLabeler labeler = new TypeLabeler();
  var receiver_0 = labeler.labelConstant(receiver);
  return new Message(
    constEvalInvalidMethodInvocation,
    problemMessage:
        """The method '${method_0}' can't be invoked on '${receiver_0}' in a constant expression.""" +
        labeler.originMessages,
    arguments: {'method': method, 'receiver': receiver},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String property, required Constant receiver})
>
constEvalInvalidPropertyGet = const Template(
  "ConstEvalInvalidPropertyGet",
  withArguments: _withArgumentsConstEvalInvalidPropertyGet,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalInvalidPropertyGet({
  required String property,
  required Constant receiver,
}) {
  var property_0 = conversions.stringOrEmpty(property);
  TypeLabeler labeler = new TypeLabeler();
  var receiver_0 = labeler.labelConstant(receiver);
  return new Message(
    constEvalInvalidPropertyGet,
    problemMessage:
        """The property '${property_0}' can't be accessed on '${receiver_0}' in a constant expression.""" +
        labeler.originMessages,
    arguments: {'property': property, 'receiver': receiver},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String index, required Constant receiver})
>
constEvalInvalidRecordIndexGet = const Template(
  "ConstEvalInvalidRecordIndexGet",
  withArguments: _withArgumentsConstEvalInvalidRecordIndexGet,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalInvalidRecordIndexGet({
  required String index,
  required Constant receiver,
}) {
  var index_0 = conversions.stringOrEmpty(index);
  TypeLabeler labeler = new TypeLabeler();
  var receiver_0 = labeler.labelConstant(receiver);
  return new Message(
    constEvalInvalidRecordIndexGet,
    problemMessage:
        """The property '${index_0}' can't be accessed on '${receiver_0}' in a constant expression.""" +
        labeler.originMessages,
    arguments: {'index': index, 'receiver': receiver},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String property, required Constant receiver})
>
constEvalInvalidRecordNameGet = const Template(
  "ConstEvalInvalidRecordNameGet",
  withArguments: _withArgumentsConstEvalInvalidRecordNameGet,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalInvalidRecordNameGet({
  required String property,
  required Constant receiver,
}) {
  var property_0 = conversions.stringOrEmpty(property);
  TypeLabeler labeler = new TypeLabeler();
  var receiver_0 = labeler.labelConstant(receiver);
  return new Message(
    constEvalInvalidRecordNameGet,
    problemMessage:
        """The property '${property_0}' can't be accessed on '${receiver_0}' in a constant expression.""" +
        labeler.originMessages,
    arguments: {'property': property, 'receiver': receiver},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String target})>
constEvalInvalidStaticInvocation = const Template(
  "ConstEvalInvalidStaticInvocation",
  withArguments: _withArgumentsConstEvalInvalidStaticInvocation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalInvalidStaticInvocation({
  required String target,
}) {
  var target_0 = conversions.nameOrUnnamed(target);
  return new Message(
    constEvalInvalidStaticInvocation,
    problemMessage:
        """The invocation of '${target_0}' is not allowed in a constant expression.""",
    arguments: {'target': target},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required Constant constant})>
constEvalInvalidStringInterpolationOperand = const Template(
  "ConstEvalInvalidStringInterpolationOperand",
  withArguments: _withArgumentsConstEvalInvalidStringInterpolationOperand,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalInvalidStringInterpolationOperand({
  required Constant constant,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var constant_0 = labeler.labelConstant(constant);
  return new Message(
    constEvalInvalidStringInterpolationOperand,
    problemMessage:
        """The constant value '${constant_0}' can't be used as part of a string interpolation in a constant expression.
Only values of type 'null', 'bool', 'int', 'double', or 'String' can be used.""" +
        labeler.originMessages,
    arguments: {'constant': constant},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required Constant name})>
constEvalInvalidSymbolName = const Template(
  "ConstEvalInvalidSymbolName",
  withArguments: _withArgumentsConstEvalInvalidSymbolName,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalInvalidSymbolName({required Constant name}) {
  TypeLabeler labeler = new TypeLabeler();
  var name_0 = labeler.labelConstant(name);
  return new Message(
    constEvalInvalidSymbolName,
    problemMessage:
        """The symbol name must be a valid public Dart member name, public constructor name, or library name, optionally qualified, but was '${name_0}'.""" +
        labeler.originMessages,
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required Constant constant,
    required DartType expectedType,
    required DartType actualType,
  })
>
constEvalInvalidType = const Template(
  "ConstEvalInvalidType",
  withArguments: _withArgumentsConstEvalInvalidType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalInvalidType({
  required Constant constant,
  required DartType expectedType,
  required DartType actualType,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var constant_0 = labeler.labelConstant(constant);
  var expectedType_0 = labeler.labelType(expectedType);
  var actualType_0 = labeler.labelType(actualType);
  return new Message(
    constEvalInvalidType,
    problemMessage:
        """Expected constant '${constant_0}' to be of type '${expectedType_0}', but was of type '${actualType_0}'.""" +
        labeler.originMessages,
    arguments: {
      'constant': constant,
      'expectedType': expectedType,
      'actualType': actualType,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required Constant key})>
constEvalKeyImplementsEqual = const Template(
  "ConstEvalKeyImplementsEqual",
  withArguments: _withArgumentsConstEvalKeyImplementsEqual,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalKeyImplementsEqual({required Constant key}) {
  TypeLabeler labeler = new TypeLabeler();
  var key_0 = labeler.labelConstant(key);
  return new Message(
    constEvalKeyImplementsEqual,
    problemMessage:
        """The key '${key_0}' does not have a primitive operator '=='.""" +
        labeler.originMessages,
    arguments: {'key': key},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required Constant key})>
constEvalKeyNotPrimitiveEquality = const Template(
  "ConstEvalKeyNotPrimitiveEquality",
  withArguments: _withArgumentsConstEvalKeyNotPrimitiveEquality,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalKeyNotPrimitiveEquality({
  required Constant key,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var key_0 = labeler.labelConstant(key);
  return new Message(
    constEvalKeyNotPrimitiveEquality,
    problemMessage:
        """The key '${key_0}' does not have a primitive equality.""" +
        labeler.originMessages,
    arguments: {'key': key},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String operator,
    required String receiver,
    required String shiftAmount,
  })
>
constEvalNegativeShift = const Template(
  "ConstEvalNegativeShift",
  withArguments: _withArgumentsConstEvalNegativeShift,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalNegativeShift({
  required String operator,
  required String receiver,
  required String shiftAmount,
}) {
  var operator_0 = conversions.validateString(operator);
  var receiver_0 = conversions.validateString(receiver);
  var shiftAmount_0 = conversions.validateString(shiftAmount);
  return new Message(
    constEvalNegativeShift,
    problemMessage:
        """Binary operator '${operator_0}' on '${receiver_0}' requires non-negative operand, but was '${shiftAmount_0}'.""",
    arguments: {
      'operator': operator,
      'receiver': receiver,
      'shiftAmount': shiftAmount,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name})>
constEvalNonConstantVariableGet = const Template(
  "ConstEvalNonConstantVariableGet",
  withArguments: _withArgumentsConstEvalNonConstantVariableGet,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalNonConstantVariableGet({required String name}) {
  var name_0 = conversions.nameOrUnnamed(name);
  return new Message(
    constEvalNonConstantVariableGet,
    problemMessage:
        """The variable '${name_0}' is not a constant, only constant expressions are allowed.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode constEvalNonNull = const MessageCode(
  "ConstEvalNonNull",
  problemMessage: """Constant expression must be non-null.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode constEvalNotListOrSetInSpread = const MessageCode(
  "ConstEvalNotListOrSetInSpread",
  problemMessage:
      """Only lists and sets can be used in spreads in constant lists and sets.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode constEvalNotMapInSpread = const MessageCode(
  "ConstEvalNotMapInSpread",
  problemMessage: """Only maps can be used in spreads in constant maps.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode constEvalNullValue = const MessageCode(
  "ConstEvalNullValue",
  problemMessage: """Null value during constant evaluation.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode constEvalStartingPoint = const MessageCode(
  "ConstEvalStartingPoint",
  problemMessage: """Constant evaluation error:""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String receiver, required String operand})
>
constEvalTruncateError = const Template(
  "ConstEvalTruncateError",
  withArguments: _withArgumentsConstEvalTruncateError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalTruncateError({
  required String receiver,
  required String operand,
}) {
  var receiver_0 = conversions.validateString(receiver);
  var operand_0 = conversions.validateString(operand);
  return new Message(
    constEvalTruncateError,
    problemMessage:
        """Binary operator '${receiver_0} ~/ ${operand_0}' results is Infinity or NaN.""",
    arguments: {'receiver': receiver, 'operand': operand},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode constEvalUnevaluated = const MessageCode(
  "ConstEvalUnevaluated",
  problemMessage: """Couldn't evaluate constant expression.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String exceptionText})>
constEvalUnhandledCoreException = const Template(
  "ConstEvalUnhandledCoreException",
  withArguments: _withArgumentsConstEvalUnhandledCoreException,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalUnhandledCoreException({
  required String exceptionText,
}) {
  var exceptionText_0 = conversions.stringOrEmpty(exceptionText);
  return new Message(
    constEvalUnhandledCoreException,
    problemMessage: """Unhandled core exception: ${exceptionText_0}""",
    arguments: {'exceptionText': exceptionText},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required Constant exception})>
constEvalUnhandledException = const Template(
  "ConstEvalUnhandledException",
  withArguments: _withArgumentsConstEvalUnhandledException,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalUnhandledException({
  required Constant exception,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var exception_0 = labeler.labelConstant(exception);
  return new Message(
    constEvalUnhandledException,
    problemMessage:
        """Unhandled exception: ${exception_0}""" + labeler.originMessages,
    arguments: {'exception': exception},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String operator, required String value})
>
constEvalZeroDivisor = const Template(
  "ConstEvalZeroDivisor",
  withArguments: _withArgumentsConstEvalZeroDivisor,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalZeroDivisor({
  required String operator,
  required String value,
}) {
  var operator_0 = conversions.validateString(operator);
  var value_0 = conversions.validateString(value);
  return new Message(
    constEvalZeroDivisor,
    problemMessage:
        """Binary operator '${operator_0}' on '${value_0}' requires non-zero divisor, but divisor was '0'.""",
    arguments: {'operator': operator, 'value': value},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode constFactoryRedirectionToNonConst = const MessageCode(
  "ConstFactoryRedirectionToNonConst",
  problemMessage:
      """Constant factory constructor can't delegate to a non-constant constructor.""",
  correctionMessage:
      """Try redirecting to a different constructor or marking the target constructor 'const'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode constInstanceField = const MessageCode(
  "ConstInstanceField",
  problemMessage: """Only static fields can be declared as const.""",
  correctionMessage:
      """Try using 'final' instead of 'const', or adding the keyword 'static'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String memberName})>
constructorConflictsWithMember = const Template(
  "ConstructorConflictsWithMember",
  withArguments: _withArgumentsConstructorConflictsWithMember,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstructorConflictsWithMember({
  required String memberName,
}) {
  var memberName_0 = conversions.validateAndDemangleName(memberName);
  return new Message(
    constructorConflictsWithMember,
    problemMessage:
        """The constructor conflicts with member '${memberName_0}'.""",
    arguments: {'memberName': memberName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String memberName})>
constructorConflictsWithMemberCause = const Template(
  "ConstructorConflictsWithMemberCause",
  withArguments: _withArgumentsConstructorConflictsWithMemberCause,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstructorConflictsWithMemberCause({
  required String memberName,
}) {
  var memberName_0 = conversions.validateAndDemangleName(memberName);
  return new Message(
    constructorConflictsWithMemberCause,
    problemMessage: """Conflicting member '${memberName_0}'.""",
    arguments: {'memberName': memberName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode constructorCyclic = const MessageCode(
  "ConstructorCyclic",
  problemMessage: """Redirecting constructors can't be cyclic.""",
  correctionMessage:
      """Try to have all constructors eventually redirect to a non-redirecting constructor.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String fieldName})>
constructorInitializeSameInstanceVariableSeveralTimes = const Template(
  "ConstructorInitializeSameInstanceVariableSeveralTimes",
  withArguments:
      _withArgumentsConstructorInitializeSameInstanceVariableSeveralTimes,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstructorInitializeSameInstanceVariableSeveralTimes({
  required String fieldName,
}) {
  var fieldName_0 = conversions.validateAndDemangleName(fieldName);
  return new Message(
    constructorInitializeSameInstanceVariableSeveralTimes,
    problemMessage:
        """'${fieldName_0}' was already initialized by this constructor.""",
    arguments: {'fieldName': fieldName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name})> constructorNotFound =
    const Template(
      "ConstructorNotFound",
      withArguments: _withArgumentsConstructorNotFound,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstructorNotFound({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    constructorNotFound,
    problemMessage: """Couldn't find constructor '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode constructorNotSync = const MessageCode(
  "ConstructorNotSync",
  problemMessage:
      """Constructor bodies can't use 'async', 'async*', or 'sync*'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name})>
constructorShouldBeListedAsCallableInDynamicInterface = const Template(
  "ConstructorShouldBeListedAsCallableInDynamicInterface",
  withArguments:
      _withArgumentsConstructorShouldBeListedAsCallableInDynamicInterface,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstructorShouldBeListedAsCallableInDynamicInterface({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    constructorShouldBeListedAsCallableInDynamicInterface,
    problemMessage:
        """Cannot invoke constructor '${name_0}' from a dynamic module.""",
    correctionMessage:
        """Try removing the call or update the dynamic interface to list constructor '${name_0}' as callable.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode constructorTearOffWithTypeArguments = const MessageCode(
  "ConstructorTearOffWithTypeArguments",
  problemMessage:
      """A constructor tear-off can't have type arguments after the constructor name.""",
  correctionMessage:
      """Try removing the type arguments or placing them after the class name.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name})>
constructorWithWrongNameContext = const Template(
  "ConstructorWithWrongNameContext",
  withArguments: _withArgumentsConstructorWithWrongNameContext,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstructorWithWrongNameContext({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    constructorWithWrongNameContext,
    problemMessage: """The name of the enclosing class is '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode continueLabelInvalid = const MessageCode(
  "ContinueLabelInvalid",
  problemMessage:
      """A 'continue' label must be on a loop or a switch member.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String label})>
continueTargetOutsideFunction = const Template(
  "ContinueTargetOutsideFunction",
  withArguments: _withArgumentsContinueTargetOutsideFunction,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsContinueTargetOutsideFunction({required String label}) {
  var label_0 = conversions.validateAndDemangleName(label);
  return new Message(
    continueTargetOutsideFunction,
    problemMessage:
        """Can't continue at '${label_0}' in a different function.""",
    arguments: {'label': label},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String uri, required String details})>
couldNotParseUri = const Template(
  "CouldNotParseUri",
  withArguments: _withArgumentsCouldNotParseUri,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCouldNotParseUri({
  required String uri,
  required String details,
}) {
  var uri_0 = conversions.validateString(uri);
  var details_0 = conversions.validateString(details);
  return new Message(
    couldNotParseUri,
    problemMessage: """Couldn't parse URI '${uri_0}':
  ${details_0}.""",
    arguments: {'uri': uri, 'details': details},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String typeName, required String cycle})
>
cycleInTypeParameters = const Template(
  "CycleInTypeParameters",
  withArguments: _withArgumentsCycleInTypeParameters,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCycleInTypeParameters({
  required String typeName,
  required String cycle,
}) {
  var typeName_0 = conversions.validateAndDemangleName(typeName);
  var cycle_0 = conversions.validateString(cycle);
  return new Message(
    cycleInTypeParameters,
    problemMessage:
        """Type '${typeName_0}' is a bound of itself via '${cycle_0}'.""",
    correctionMessage:
        """Try breaking the cycle by removing at least one of the 'extends' clauses in the cycle.""",
    arguments: {'typeName': typeName, 'cycle': cycle},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String typeName})>
cyclicClassHierarchy = const Template(
  "CyclicClassHierarchy",
  withArguments: _withArgumentsCyclicClassHierarchy,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCyclicClassHierarchy({required String typeName}) {
  var typeName_0 = conversions.validateAndDemangleName(typeName);
  return new Message(
    cyclicClassHierarchy,
    problemMessage: """'${typeName_0}' is a supertype of itself.""",
    arguments: {'typeName': typeName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String factoryName})>
cyclicRedirectingFactoryConstructors = const Template(
  "CyclicRedirectingFactoryConstructors",
  withArguments: _withArgumentsCyclicRedirectingFactoryConstructors,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCyclicRedirectingFactoryConstructors({
  required String factoryName,
}) {
  var factoryName_0 = conversions.validateAndDemangleName(factoryName);
  return new Message(
    cyclicRedirectingFactoryConstructors,
    problemMessage: """Cyclic definition of factory '${factoryName_0}'.""",
    arguments: {'factoryName': factoryName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode cyclicRepresentationDependency = const MessageCode(
  "CyclicRepresentationDependency",
  problemMessage:
      """An extension type can't depend on itself through its representation type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name})> cyclicTypedef =
    const Template("CyclicTypedef", withArguments: _withArgumentsCyclicTypedef);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCyclicTypedef({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    cyclicTypedef,
    problemMessage: """The typedef '${name_0}' has a reference to itself.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode dartFfiLibraryInDart2Wasm = const MessageCode(
  "DartFfiLibraryInDart2Wasm",
  problemMessage: """'dart:ffi' can't be imported when compiling to Wasm.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String severity, required String stackTrace})
>
debugTrace = const Template(
  "DebugTrace",
  withArguments: _withArgumentsDebugTrace,
  severity: CfeSeverity.ignored,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDebugTrace({
  required String severity,
  required String stackTrace,
}) {
  var severity_0 = conversions.validateAndDemangleName(severity);
  var stackTrace_0 = conversions.validateString(stackTrace);
  return new Message(
    debugTrace,
    problemMessage: """Fatal '${severity_0}' at:
${stackTrace_0}""",
    arguments: {'severity': severity, 'stackTrace': stackTrace},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String setterName})>
declarationConflictsWithSetter = const Template(
  "DeclarationConflictsWithSetter",
  withArguments: _withArgumentsDeclarationConflictsWithSetter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDeclarationConflictsWithSetter({
  required String setterName,
}) {
  var setterName_0 = conversions.validateAndDemangleName(setterName);
  return new Message(
    declarationConflictsWithSetter,
    problemMessage:
        """The declaration conflicts with setter '${setterName_0}'.""",
    arguments: {'setterName': setterName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String setterName})>
declarationConflictsWithSetterCause = const Template(
  "DeclarationConflictsWithSetterCause",
  withArguments: _withArgumentsDeclarationConflictsWithSetterCause,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDeclarationConflictsWithSetterCause({
  required String setterName,
}) {
  var setterName_0 = conversions.validateAndDemangleName(setterName);
  return new Message(
    declarationConflictsWithSetterCause,
    problemMessage: """Conflicting setter '${setterName_0}'.""",
    arguments: {'setterName': setterName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode declaredMemberConflictsWithInheritedMember =
    const MessageCode(
      "DeclaredMemberConflictsWithInheritedMember",
      problemMessage:
          """Can't declare a member that conflicts with an inherited one.""",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode declaredMemberConflictsWithInheritedMemberCause =
    const MessageCode(
      "DeclaredMemberConflictsWithInheritedMemberCause",
      severity: CfeSeverity.context,
      problemMessage: """This is the inherited member.""",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode declaredMemberConflictsWithInheritedMembersCause =
    const MessageCode(
      "DeclaredMemberConflictsWithInheritedMembersCause",
      severity: CfeSeverity.context,
      problemMessage: """This is one of the inherited members.""",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode declaredMemberConflictsWithOverriddenMembersCause =
    const MessageCode(
      "DeclaredMemberConflictsWithOverriddenMembersCause",
      severity: CfeSeverity.context,
      problemMessage: """This is one of the overridden members.""",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String redirectionTarget})>
defaultValueInRedirectingFactoryConstructor = const Template(
  "DefaultValueInRedirectingFactoryConstructor",
  withArguments: _withArgumentsDefaultValueInRedirectingFactoryConstructor,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDefaultValueInRedirectingFactoryConstructor({
  required String redirectionTarget,
}) {
  var redirectionTarget_0 = conversions.validateAndDemangleName(
    redirectionTarget,
  );
  return new Message(
    defaultValueInRedirectingFactoryConstructor,
    problemMessage:
        """Can't have a default value here because any default values of '${redirectionTarget_0}' would be used instead.""",
    correctionMessage: """Try removing the default value.""",
    arguments: {'redirectionTarget': redirectionTarget},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String extensionName})>
deferredExtensionImport = const Template(
  "DeferredExtensionImport",
  withArguments: _withArgumentsDeferredExtensionImport,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDeferredExtensionImport({required String extensionName}) {
  var extensionName_0 = conversions.validateAndDemangleName(extensionName);
  return new Message(
    deferredExtensionImport,
    problemMessage:
        """Extension '${extensionName_0}' cannot be imported through a deferred import.""",
    correctionMessage:
        """Try adding the `hide ${extensionName_0}` to the import.""",
    arguments: {'extensionName': extensionName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String prefixName})>
deferredPrefixDuplicated = const Template(
  "DeferredPrefixDuplicated",
  withArguments: _withArgumentsDeferredPrefixDuplicated,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDeferredPrefixDuplicated({required String prefixName}) {
  var prefixName_0 = conversions.validateAndDemangleName(prefixName);
  return new Message(
    deferredPrefixDuplicated,
    problemMessage:
        """Can't use the name '${prefixName_0}' for a deferred library, as the name is used elsewhere.""",
    arguments: {'prefixName': prefixName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String prefixName})>
deferredPrefixDuplicatedCause = const Template(
  "DeferredPrefixDuplicatedCause",
  withArguments: _withArgumentsDeferredPrefixDuplicatedCause,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDeferredPrefixDuplicatedCause({
  required String prefixName,
}) {
  var prefixName_0 = conversions.validateAndDemangleName(prefixName);
  return new Message(
    deferredPrefixDuplicatedCause,
    problemMessage: """'${prefixName_0}' is used here.""",
    arguments: {'prefixName': prefixName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required DartType type, required String prefix})
>
deferredTypeAnnotation = const Template(
  "DeferredTypeAnnotation",
  withArguments: _withArgumentsDeferredTypeAnnotation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDeferredTypeAnnotation({
  required DartType type,
  required String prefix,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var prefix_0 = conversions.validateAndDemangleName(prefix);
  return new Message(
    deferredTypeAnnotation,
    problemMessage:
        """The type '${type_0}' is deferred loaded via prefix '${prefix_0}' and can't be used as a type annotation.""" +
        labeler.originMessages,
    correctionMessage:
        """Try removing 'deferred' from the import of '${prefix_0}' or use a supertype of '${type_0}' that isn't deferred.""",
    arguments: {'type': type, 'prefix': prefix},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required int count,
    required int bytes,
    required num timeMs,
    required num rateBytesPerMs,
    required num averageTimeMs,
  })
>
dillOutlineSummary = const Template(
  "DillOutlineSummary",
  withArguments: _withArgumentsDillOutlineSummary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDillOutlineSummary({
  required int count,
  required int bytes,
  required num timeMs,
  required num rateBytesPerMs,
  required num averageTimeMs,
}) {
  var timeMs_0 = conversions.formatNumber(
    timeMs,
    fractionDigits: 3,
    padWidth: 0,
    padWithZeros: false,
  );
  var rateBytesPerMs_0 = conversions.formatNumber(
    rateBytesPerMs,
    fractionDigits: 3,
    padWidth: 12,
    padWithZeros: false,
  );
  var averageTimeMs_0 = conversions.formatNumber(
    averageTimeMs,
    fractionDigits: 3,
    padWidth: 12,
    padWithZeros: false,
  );
  return new Message(
    dillOutlineSummary,
    problemMessage:
        """Indexed ${count} libraries (${bytes} bytes) in ${timeMs_0}ms, that is,
${rateBytesPerMs_0} bytes/ms, and
${averageTimeMs_0} ms/libraries.""",
    arguments: {
      'count': count,
      'bytes': bytes,
      'timeMs': timeMs,
      'rateBytesPerMs': rateBytesPerMs,
      'averageTimeMs': averageTimeMs,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String typeName})>
directCycleInTypeParameters = const Template(
  "DirectCycleInTypeParameters",
  withArguments: _withArgumentsDirectCycleInTypeParameters,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDirectCycleInTypeParameters({required String typeName}) {
  var typeName_0 = conversions.validateAndDemangleName(typeName);
  return new Message(
    directCycleInTypeParameters,
    problemMessage: """Type '${typeName_0}' can't use itself as a bound.""",
    correctionMessage:
        """Try breaking the cycle by removing at least one of the 'extends' clauses in the cycle.""",
    arguments: {'typeName': typeName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
dotShorthandsConstructorInvocationWithTypeArguments = const MessageCode(
  "DotShorthandsConstructorInvocationWithTypeArguments",
  problemMessage:
      """A dot shorthand constructor invocation can't have type arguments.""",
  correctionMessage:
      """Try adding the class name and type arguments explicitly before the constructor name.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String dotShorthandName})>
dotShorthandsInvalidContext = const Template(
  "DotShorthandsInvalidContext",
  withArguments: _withArgumentsDotShorthandsInvalidContext,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDotShorthandsInvalidContext({
  required String dotShorthandName,
}) {
  var dotShorthandName_0 = conversions.validateAndDemangleName(
    dotShorthandName,
  );
  return new Message(
    dotShorthandsInvalidContext,
    problemMessage:
        """No type was provided to find the dot shorthand '${dotShorthandName_0}'.""",
    arguments: {'dotShorthandName': dotShorthandName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String getterName, required DartType contextType})
>
dotShorthandsUndefinedGetter = const Template(
  "DotShorthandsUndefinedGetter",
  withArguments: _withArgumentsDotShorthandsUndefinedGetter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDotShorthandsUndefinedGetter({
  required String getterName,
  required DartType contextType,
}) {
  var getterName_0 = conversions.validateAndDemangleName(getterName);
  TypeLabeler labeler = new TypeLabeler();
  var contextType_0 = labeler.labelType(contextType);
  return new Message(
    dotShorthandsUndefinedGetter,
    problemMessage:
        """The static getter or field '${getterName_0}' isn't defined for the type '${contextType_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try correcting the name to the name of an existing static getter or field, or defining a getter or field named '${getterName_0}'.""",
    arguments: {'getterName': getterName, 'contextType': contextType},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String memberName, required DartType contextType})
>
dotShorthandsUndefinedInvocation = const Template(
  "DotShorthandsUndefinedInvocation",
  withArguments: _withArgumentsDotShorthandsUndefinedInvocation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDotShorthandsUndefinedInvocation({
  required String memberName,
  required DartType contextType,
}) {
  var memberName_0 = conversions.validateAndDemangleName(memberName);
  TypeLabeler labeler = new TypeLabeler();
  var contextType_0 = labeler.labelType(contextType);
  return new Message(
    dotShorthandsUndefinedInvocation,
    problemMessage:
        """The static method or constructor '${memberName_0}' isn't defined for the type '${contextType_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try correcting the name to the name of an existing static method or constructor, or defining a static method or constructor named '${memberName_0}'.""",
    arguments: {'memberName': memberName, 'contextType': contextType},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String variableName})>
duplicatePatternAssignmentVariable = const Template(
  "DuplicatePatternAssignmentVariable",
  withArguments: _withArgumentsDuplicatePatternAssignmentVariable,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatePatternAssignmentVariable({
  required String variableName,
}) {
  var variableName_0 = conversions.validateAndDemangleName(variableName);
  return new Message(
    duplicatePatternAssignmentVariable,
    problemMessage:
        """The variable '${variableName_0}' is already assigned in this pattern.""",
    correctionMessage: """Try renaming the variable.""",
    arguments: {'variableName': variableName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode duplicatePatternAssignmentVariableContext = const MessageCode(
  "DuplicatePatternAssignmentVariableContext",
  severity: CfeSeverity.context,
  problemMessage: """The first assigned variable pattern.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String fieldName})>
duplicateRecordPatternField = const Template(
  "DuplicateRecordPatternField",
  withArguments: _withArgumentsDuplicateRecordPatternField,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicateRecordPatternField({required String fieldName}) {
  var fieldName_0 = conversions.validateAndDemangleName(fieldName);
  return new Message(
    duplicateRecordPatternField,
    problemMessage:
        """The field '${fieldName_0}' is already matched in this pattern.""",
    correctionMessage: """Try removing the duplicate field.""",
    arguments: {'fieldName': fieldName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode duplicateRecordPatternFieldContext = const MessageCode(
  "DuplicateRecordPatternFieldContext",
  severity: CfeSeverity.context,
  problemMessage: """The first field.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode duplicateRestElementInPattern = const MessageCode(
  "DuplicateRestElementInPattern",
  problemMessage:
      """At most one rest element is allowed in a list or map pattern.""",
  correctionMessage: """Try removing the duplicate rest element.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode duplicateRestElementInPatternContext = const MessageCode(
  "DuplicateRestElementInPatternContext",
  severity: CfeSeverity.context,
  problemMessage: """The first rest element.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name})> duplicatedDeclaration =
    const Template(
      "DuplicatedDeclaration",
      withArguments: _withArgumentsDuplicatedDeclaration,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedDeclaration({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    duplicatedDeclaration,
    problemMessage: """'${name_0}' is already declared in this scope.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name})>
duplicatedDeclarationCause = const Template(
  "DuplicatedDeclarationCause",
  withArguments: _withArgumentsDuplicatedDeclarationCause,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedDeclarationCause({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    duplicatedDeclarationCause,
    problemMessage: """Previous declaration of '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name})>
duplicatedDeclarationUse = const Template(
  "DuplicatedDeclarationUse",
  withArguments: _withArgumentsDuplicatedDeclarationUse,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedDeclarationUse({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    duplicatedDeclarationUse,
    problemMessage:
        """Can't use '${name_0}' because it is declared more than once.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String name, required Uri uri, required Uri uri2})
>
duplicatedExport = const Template(
  "DuplicatedExport",
  withArguments: _withArgumentsDuplicatedExport,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedExport({
  required String name,
  required Uri uri,
  required Uri uri2,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var uri_0 = conversions.relativizeUri(uri);
  var uri2_0 = conversions.relativizeUri(uri2);
  return new Message(
    duplicatedExport,
    problemMessage:
        """'${name_0}' is exported from both '${uri_0}' and '${uri2_0}'.""",
    arguments: {'name': name, 'uri': uri, 'uri2': uri2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String name, required Uri uri, required Uri uri2})
>
duplicatedImport = const Template(
  "DuplicatedImport",
  withArguments: _withArgumentsDuplicatedImport,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedImport({
  required String name,
  required Uri uri,
  required Uri uri2,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var uri_0 = conversions.relativizeUri(uri);
  var uri2_0 = conversions.relativizeUri(uri2);
  return new Message(
    duplicatedImport,
    problemMessage:
        """'${name_0}' is imported from both '${uri_0}' and '${uri2_0}'.""",
    arguments: {'name': name, 'uri': uri, 'uri2': uri2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name})>
duplicatedNamedArgument = const Template(
  "DuplicatedNamedArgument",
  withArguments: _withArgumentsDuplicatedNamedArgument,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedNamedArgument({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    duplicatedNamedArgument,
    problemMessage: """Duplicated named argument '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name})>
duplicatedParameterName = const Template(
  "DuplicatedParameterName",
  withArguments: _withArgumentsDuplicatedParameterName,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedParameterName({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    duplicatedParameterName,
    problemMessage: """Duplicated parameter name '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name})>
duplicatedParameterNameCause = const Template(
  "DuplicatedParameterNameCause",
  withArguments: _withArgumentsDuplicatedParameterNameCause,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedParameterNameCause({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    duplicatedParameterNameCause,
    problemMessage: """Other parameter named '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String fieldName})>
duplicatedRecordLiteralFieldName = const Template(
  "DuplicatedRecordLiteralFieldName",
  withArguments: _withArgumentsDuplicatedRecordLiteralFieldName,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedRecordLiteralFieldName({
  required String fieldName,
}) {
  var fieldName_0 = conversions.validateAndDemangleName(fieldName);
  return new Message(
    duplicatedRecordLiteralFieldName,
    problemMessage:
        """Duplicated record literal field name '${fieldName_0}'.""",
    correctionMessage:
        """Try renaming or removing one of the named record literal fields.""",
    arguments: {'fieldName': fieldName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String fieldName})>
duplicatedRecordLiteralFieldNameContext = const Template(
  "DuplicatedRecordLiteralFieldNameContext",
  withArguments: _withArgumentsDuplicatedRecordLiteralFieldNameContext,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedRecordLiteralFieldNameContext({
  required String fieldName,
}) {
  var fieldName_0 = conversions.validateAndDemangleName(fieldName);
  return new Message(
    duplicatedRecordLiteralFieldNameContext,
    problemMessage:
        """This is the existing record literal field named '${fieldName_0}'.""",
    arguments: {'fieldName': fieldName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String fieldName})>
duplicatedRecordTypeFieldName = const Template(
  "DuplicatedRecordTypeFieldName",
  withArguments: _withArgumentsDuplicatedRecordTypeFieldName,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedRecordTypeFieldName({
  required String fieldName,
}) {
  var fieldName_0 = conversions.validateAndDemangleName(fieldName);
  return new Message(
    duplicatedRecordTypeFieldName,
    problemMessage: """Duplicated record type field name '${fieldName_0}'.""",
    correctionMessage:
        """Try renaming or removing one of the named record type fields.""",
    arguments: {'fieldName': fieldName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String fieldName})>
duplicatedRecordTypeFieldNameContext = const Template(
  "DuplicatedRecordTypeFieldNameContext",
  withArguments: _withArgumentsDuplicatedRecordTypeFieldNameContext,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedRecordTypeFieldNameContext({
  required String fieldName,
}) {
  var fieldName_0 = conversions.validateAndDemangleName(fieldName);
  return new Message(
    duplicatedRecordTypeFieldNameContext,
    problemMessage:
        """This is the existing record type field named '${fieldName_0}'.""",
    arguments: {'fieldName': fieldName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode dynamicCallsAreNotAllowedInDynamicModule = const MessageCode(
  "DynamicCallsAreNotAllowedInDynamicModule",
  problemMessage: """Dynamic calls are not allowed in a dynamic module.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode emptyMapPattern = const MessageCode(
  "EmptyMapPattern",
  problemMessage: """A map pattern must have at least one entry.""",
  correctionMessage: """Try replacing it with an object pattern 'Map()'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode enumAbstractMember = const MessageCode(
  "EnumAbstractMember",
  problemMessage: """Enums can't declare abstract members.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode enumConstructorNonFinalField = const MessageCode(
  "EnumConstructorNonFinalField",
  problemMessage:
      """Enum constructors are constant so all fields must be final.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode enumConstructorSuperInitializer = const MessageCode(
  "EnumConstructorSuperInitializer",
  problemMessage: """Enum constructors can't contain super-initializers.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode enumConstructorTearoff = const MessageCode(
  "EnumConstructorTearoff",
  problemMessage: """Enum constructors can't be torn off.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String memberName})>
enumContainsRestrictedInstanceDeclaration = const Template(
  "EnumContainsRestrictedInstanceDeclaration",
  withArguments: _withArgumentsEnumContainsRestrictedInstanceDeclaration,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsEnumContainsRestrictedInstanceDeclaration({
  required String memberName,
}) {
  var memberName_0 = conversions.validateAndDemangleName(memberName);
  return new Message(
    enumContainsRestrictedInstanceDeclaration,
    problemMessage:
        """An enum can't declare a non-abstract member named '${memberName_0}'.""",
    arguments: {'memberName': memberName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode enumContainsValuesDeclaration = const MessageCode(
  "EnumContainsValuesDeclaration",
  problemMessage: """An enum can't declare a member named 'values'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode enumDeclarationEmpty = const MessageCode(
  "EnumDeclarationEmpty",
  problemMessage: """An enum declaration can't be empty.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode enumFactoryRedirectsToConstructor = const MessageCode(
  "EnumFactoryRedirectsToConstructor",
  problemMessage:
      """Enum factory constructors can't redirect to generative constructors.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String className, required String memberName})
>
enumImplementerContainsRestrictedInstanceDeclaration = const Template(
  "EnumImplementerContainsRestrictedInstanceDeclaration",
  withArguments:
      _withArgumentsEnumImplementerContainsRestrictedInstanceDeclaration,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsEnumImplementerContainsRestrictedInstanceDeclaration({
  required String className,
  required String memberName,
}) {
  var className_0 = conversions.validateAndDemangleName(className);
  var memberName_0 = conversions.validateAndDemangleName(memberName);
  return new Message(
    enumImplementerContainsRestrictedInstanceDeclaration,
    problemMessage:
        """'${className_0}' has 'Enum' as a superinterface and can't contain non-static members with name '${memberName_0}'.""",
    arguments: {'className': className, 'memberName': memberName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String className})>
enumImplementerContainsValuesDeclaration = const Template(
  "EnumImplementerContainsValuesDeclaration",
  withArguments: _withArgumentsEnumImplementerContainsValuesDeclaration,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsEnumImplementerContainsValuesDeclaration({
  required String className,
}) {
  var className_0 = conversions.validateAndDemangleName(className);
  return new Message(
    enumImplementerContainsValuesDeclaration,
    problemMessage:
        """'${className_0}' has 'Enum' as a superinterface and can't contain non-static member with name 'values'.""",
    arguments: {'className': className},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String memberName})>
enumInheritsRestricted = const Template(
  "EnumInheritsRestricted",
  withArguments: _withArgumentsEnumInheritsRestricted,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsEnumInheritsRestricted({required String memberName}) {
  var memberName_0 = conversions.validateAndDemangleName(memberName);
  return new Message(
    enumInheritsRestricted,
    problemMessage:
        """An enum can't inherit a member named '${memberName_0}'.""",
    arguments: {'memberName': memberName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode enumInheritsRestrictedMember = const MessageCode(
  "EnumInheritsRestrictedMember",
  severity: CfeSeverity.context,
  problemMessage: """This is the inherited member""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode enumInstantiation = const MessageCode(
  "EnumInstantiation",
  problemMessage: """Enums can't be instantiated.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode enumNonConstConstructor = const MessageCode(
  "EnumNonConstConstructor",
  problemMessage: """Generative enum constructors must be marked as 'const'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String className})>
enumSupertypeOfNonAbstractClass = const Template(
  "EnumSupertypeOfNonAbstractClass",
  withArguments: _withArgumentsEnumSupertypeOfNonAbstractClass,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsEnumSupertypeOfNonAbstractClass({
  required String className,
}) {
  var className_0 = conversions.validateAndDemangleName(className);
  return new Message(
    enumSupertypeOfNonAbstractClass,
    problemMessage:
        """Non-abstract class '${className_0}' has 'Enum' as a superinterface.""",
    arguments: {'className': className},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode enumWithNameValues = const MessageCode(
  "EnumWithNameValues",
  problemMessage:
      """The name 'values' is not a valid name for an enum. Try using a different name.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode equalKeysInMapPattern = const MessageCode(
  "EqualKeysInMapPattern",
  problemMessage: """Two keys in a map pattern can't be equal.""",
  correctionMessage: """Change or remove the duplicate key.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode equalKeysInMapPatternContext = const MessageCode(
  "EqualKeysInMapPatternContext",
  severity: CfeSeverity.context,
  problemMessage: """This is the previous use of the same key.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required Uri uri, required String exception})>
exceptionReadingFile = const Template(
  "ExceptionReadingFile",
  withArguments: _withArgumentsExceptionReadingFile,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExceptionReadingFile({
  required Uri uri,
  required String exception,
}) {
  var uri_0 = conversions.relativizeUri(uri);
  var exception_0 = conversions.validateString(exception);
  return new Message(
    exceptionReadingFile,
    problemMessage: """Exception when reading '${uri_0}': ${exception_0}""",
    arguments: {'uri': uri, 'exception': exception},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode expectedBlockToSkip = const MessageCode(
  "ExpectedBlockToSkip",
  problemMessage: """Expected a function body or '=>'.""",
  correctionMessage: """Try adding {}.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode expectedNamedArgument = const MessageCode(
  "ExpectedNamedArgument",
  problemMessage: """Expected named argument.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode expectedOneExpression = const MessageCode(
  "ExpectedOneExpression",
  problemMessage: """Expected one expression, but found additional input.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode expectedRepresentationField = const MessageCode(
  "ExpectedRepresentationField",
  problemMessage: """Expected a representation field.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode expectedRepresentationType = const MessageCode(
  "ExpectedRepresentationType",
  problemMessage: """Expected a representation type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode expectedUri = const MessageCode(
  "ExpectedUri",
  problemMessage: """Expected a URI.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String featureName})>
experimentDisabled = const Template(
  "ExperimentDisabled",
  withArguments: _withArgumentsExperimentDisabled,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExperimentDisabled({required String featureName}) {
  var featureName_0 = conversions.validateString(featureName);
  return new Message(
    experimentDisabled,
    problemMessage:
        """This requires the '${featureName_0}' language feature to be enabled.""",
    correctionMessage:
        """The feature is on by default but is currently disabled, maybe because the '--enable-experiment=no-${featureName_0}' command line option is passed.""",
    arguments: {'featureName': featureName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String featureName,
    required String requiredLanguageVersion,
  })
>
experimentDisabledInvalidLanguageVersion = const Template(
  "ExperimentDisabledInvalidLanguageVersion",
  withArguments: _withArgumentsExperimentDisabledInvalidLanguageVersion,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExperimentDisabledInvalidLanguageVersion({
  required String featureName,
  required String requiredLanguageVersion,
}) {
  var featureName_0 = conversions.validateString(featureName);
  var requiredLanguageVersion_0 = conversions.validateString(
    requiredLanguageVersion,
  );
  return new Message(
    experimentDisabledInvalidLanguageVersion,
    problemMessage:
        """This requires the '${featureName_0}' language feature, which requires language version of ${requiredLanguageVersion_0} or higher.""",
    arguments: {
      'featureName': featureName,
      'requiredLanguageVersion': requiredLanguageVersion,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String experimentName})>
experimentExpiredDisabled = const Template(
  "ExperimentExpiredDisabled",
  withArguments: _withArgumentsExperimentExpiredDisabled,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExperimentExpiredDisabled({
  required String experimentName,
}) {
  var experimentName_0 = conversions.validateAndDemangleName(experimentName);
  return new Message(
    experimentExpiredDisabled,
    problemMessage:
        """The experiment '${experimentName_0}' has expired and can't be disabled.""",
    arguments: {'experimentName': experimentName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String experimentName})>
experimentExpiredEnabled = const Template(
  "ExperimentExpiredEnabled",
  withArguments: _withArgumentsExperimentExpiredEnabled,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExperimentExpiredEnabled({
  required String experimentName,
}) {
  var experimentName_0 = conversions.validateAndDemangleName(experimentName);
  return new Message(
    experimentExpiredEnabled,
    problemMessage:
        """The experiment '${experimentName_0}' has expired and can't be enabled.""",
    arguments: {'experimentName': experimentName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String featureName})>
experimentOptOutComment = const Template(
  "ExperimentOptOutComment",
  withArguments: _withArgumentsExperimentOptOutComment,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExperimentOptOutComment({required String featureName}) {
  var featureName_0 = conversions.validateString(featureName);
  return new Message(
    experimentOptOutComment,
    problemMessage:
        """This is the annotation that opts out this library from the '${featureName_0}' language feature.""",
    arguments: {'featureName': featureName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String featureName,
    required String enabledVersion,
  })
>
experimentOptOutExplicit = const Template(
  "ExperimentOptOutExplicit",
  withArguments: _withArgumentsExperimentOptOutExplicit,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExperimentOptOutExplicit({
  required String featureName,
  required String enabledVersion,
}) {
  var featureName_0 = conversions.validateString(featureName);
  var enabledVersion_0 = conversions.validateString(enabledVersion);
  return new Message(
    experimentOptOutExplicit,
    problemMessage:
        """The '${featureName_0}' language feature is disabled for this library.""",
    correctionMessage:
        """Try removing the `@dart=` annotation or setting the language version to ${enabledVersion_0} or higher.""",
    arguments: {'featureName': featureName, 'enabledVersion': enabledVersion},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String featureName,
    required String enabledVersion,
  })
>
experimentOptOutImplicit = const Template(
  "ExperimentOptOutImplicit",
  withArguments: _withArgumentsExperimentOptOutImplicit,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExperimentOptOutImplicit({
  required String featureName,
  required String enabledVersion,
}) {
  var featureName_0 = conversions.validateString(featureName);
  var enabledVersion_0 = conversions.validateString(enabledVersion);
  return new Message(
    experimentOptOutImplicit,
    problemMessage:
        """The '${featureName_0}' language feature is disabled for this library.""",
    correctionMessage:
        """Try removing the package language version or setting the language version to ${enabledVersion_0} or higher.""",
    arguments: {'featureName': featureName, 'enabledVersion': enabledVersion},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode explicitExtensionArgumentMismatch = const MessageCode(
  "ExplicitExtensionArgumentMismatch",
  problemMessage:
      """Explicit extension application requires exactly 1 positional argument.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode explicitExtensionAsExpression = const MessageCode(
  "ExplicitExtensionAsExpression",
  problemMessage:
      """Explicit extension application cannot be used as an expression.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode explicitExtensionAsLvalue = const MessageCode(
  "ExplicitExtensionAsLvalue",
  problemMessage:
      """Explicit extension application cannot be a target for assignment.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String extensionName,
    required int typeArgumentCount,
  })
>
explicitExtensionTypeArgumentMismatch = const Template(
  "ExplicitExtensionTypeArgumentMismatch",
  withArguments: _withArgumentsExplicitExtensionTypeArgumentMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExplicitExtensionTypeArgumentMismatch({
  required String extensionName,
  required int typeArgumentCount,
}) {
  var extensionName_0 = conversions.validateAndDemangleName(extensionName);
  return new Message(
    explicitExtensionTypeArgumentMismatch,
    problemMessage:
        """Explicit extension application of extension '${extensionName_0}' takes '${typeArgumentCount}' type argument(s).""",
    arguments: {
      'extensionName': extensionName,
      'typeArgumentCount': typeArgumentCount,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode exportedMain = const MessageCode(
  "ExportedMain",
  severity: CfeSeverity.context,
  problemMessage: """This is exported 'main' declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String variableName})>
expressionEvaluationKnownVariableUnavailable = const Template(
  "ExpressionEvaluationKnownVariableUnavailable",
  withArguments: _withArgumentsExpressionEvaluationKnownVariableUnavailable,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpressionEvaluationKnownVariableUnavailable({
  required String variableName,
}) {
  var variableName_0 = conversions.validateAndDemangleName(variableName);
  return new Message(
    expressionEvaluationKnownVariableUnavailable,
    problemMessage:
        """The variable '${variableName_0}' is unavailable in this expression evaluation.""",
    arguments: {'variableName': variableName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode expressionNotMetadata = const MessageCode(
  "ExpressionNotMetadata",
  problemMessage:
      """This can't be used as an annotation; an annotation should be a reference to a compile-time constant variable, or a call to a constant constructor.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String enumName})> extendingEnum =
    const Template("ExtendingEnum", withArguments: _withArgumentsExtendingEnum);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExtendingEnum({required String enumName}) {
  var enumName_0 = conversions.validateAndDemangleName(enumName);
  return new Message(
    extendingEnum,
    problemMessage:
        """'${enumName_0}' is an enum and can't be extended or implemented.""",
    arguments: {'enumName': enumName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String restrictedName})>
extendingRestricted = const Template(
  "ExtendingRestricted",
  withArguments: _withArgumentsExtendingRestricted,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExtendingRestricted({required String restrictedName}) {
  var restrictedName_0 = conversions.validateAndDemangleName(restrictedName);
  return new Message(
    extendingRestricted,
    problemMessage:
        """'${restrictedName_0}' is restricted and can't be extended or implemented.""",
    arguments: {'restrictedName': restrictedName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode extendsDeferredClass = const MessageCode(
  "ExtendsDeferredClass",
  problemMessage: """Classes can't extend deferred classes.""",
  correctionMessage:
      """Try specifying a different superclass, or removing the extends clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode extendsNever = const MessageCode(
  "ExtendsNever",
  problemMessage: """The type 'Never' can't be used in an 'extends' clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String memberName})>
extensionMemberConflictsWithObjectMember = const Template(
  "ExtensionMemberConflictsWithObjectMember",
  withArguments: _withArgumentsExtensionMemberConflictsWithObjectMember,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExtensionMemberConflictsWithObjectMember({
  required String memberName,
}) {
  var memberName_0 = conversions.validateAndDemangleName(memberName);
  return new Message(
    extensionMemberConflictsWithObjectMember,
    problemMessage:
        """This extension member conflicts with Object member '${memberName_0}'.""",
    arguments: {'memberName': memberName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String extensionTypeName,
    required String memberName,
  })
>
extensionTypeCombinedMemberSignatureFailed = const Template(
  "ExtensionTypeCombinedMemberSignatureFailed",
  withArguments: _withArgumentsExtensionTypeCombinedMemberSignatureFailed,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExtensionTypeCombinedMemberSignatureFailed({
  required String extensionTypeName,
  required String memberName,
}) {
  var extensionTypeName_0 = conversions.validateAndDemangleName(
    extensionTypeName,
  );
  var memberName_0 = conversions.validateAndDemangleName(memberName);
  return new Message(
    extensionTypeCombinedMemberSignatureFailed,
    problemMessage:
        """Extension type '${extensionTypeName_0}' inherits multiple members named '${memberName_0}' with incompatible signatures.""",
    correctionMessage:
        """Try adding a declaration of '${memberName_0}' to '${extensionTypeName_0}'.""",
    arguments: {
      'extensionTypeName': extensionTypeName,
      'memberName': memberName,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
extensionTypeConstructorWithSuperFormalParameter = const MessageCode(
  "ExtensionTypeConstructorWithSuperFormalParameter",
  problemMessage:
      """Extension type constructors can't declare super formal parameters.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode extensionTypeDeclarationCause = const MessageCode(
  "ExtensionTypeDeclarationCause",
  severity: CfeSeverity.context,
  problemMessage: """The issue arises via this extension type declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode extensionTypeImplementsDeferred = const MessageCode(
  "ExtensionTypeImplementsDeferred",
  problemMessage: """Extension types can't implement deferred types.""",
  correctionMessage:
      """Try specifying a different type, removing the type from the list, or changing the import to not be deferred.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode extensionTypeMemberContext = const MessageCode(
  "ExtensionTypeMemberContext",
  severity: CfeSeverity.context,
  problemMessage: """This is the inherited extension type member.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode extensionTypeMemberOneOfContext = const MessageCode(
  "ExtensionTypeMemberOneOfContext",
  severity: CfeSeverity.context,
  problemMessage: """This is one of the inherited extension type members.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
extensionTypePrimaryConstructorFunctionFormalParameterSyntax = const MessageCode(
  "ExtensionTypePrimaryConstructorFunctionFormalParameterSyntax",
  problemMessage:
      """Primary constructors in extension types can't use function formal parameter syntax.""",
  correctionMessage:
      """Try rewriting with an explicit function type, like `int Function() f`.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
extensionTypePrimaryConstructorWithInitializingFormal = const MessageCode(
  "ExtensionTypePrimaryConstructorWithInitializingFormal",
  problemMessage:
      """Primary constructors in extension types can't use initializing formals.""",
  correctionMessage: """Try removing `this.` from the formal parameter.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode extensionTypeRepresentationTypeBottom = const MessageCode(
  "ExtensionTypeRepresentationTypeBottom",
  problemMessage: """The representation type can't be a bottom type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name})>
extensionTypeShouldBeListedAsCallableInDynamicInterface = const Template(
  "ExtensionTypeShouldBeListedAsCallableInDynamicInterface",
  withArguments:
      _withArgumentsExtensionTypeShouldBeListedAsCallableInDynamicInterface,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExtensionTypeShouldBeListedAsCallableInDynamicInterface({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    extensionTypeShouldBeListedAsCallableInDynamicInterface,
    problemMessage:
        """Cannot use extension type '${name_0}' in a dynamic module.""",
    correctionMessage:
        """Try removing the reference to extension type '${name_0}' or update the dynamic interface to list extension type '${name_0}' as callable.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode externalFieldConstructorInitializer = const MessageCode(
  "ExternalFieldConstructorInitializer",
  problemMessage: """External fields cannot have initializers.""",
  correctionMessage:
      """Try removing the field initializer or the 'external' keyword from the field declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode externalFieldInitializer = const MessageCode(
  "ExternalFieldInitializer",
  problemMessage: """External fields cannot have initializers.""",
  correctionMessage:
      """Try removing the initializer or the 'external' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String memberName})>
factoryConflictsWithMember = const Template(
  "FactoryConflictsWithMember",
  withArguments: _withArgumentsFactoryConflictsWithMember,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFactoryConflictsWithMember({required String memberName}) {
  var memberName_0 = conversions.validateAndDemangleName(memberName);
  return new Message(
    factoryConflictsWithMember,
    problemMessage: """The factory conflicts with member '${memberName_0}'.""",
    arguments: {'memberName': memberName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String memberName})>
factoryConflictsWithMemberCause = const Template(
  "FactoryConflictsWithMemberCause",
  withArguments: _withArgumentsFactoryConflictsWithMemberCause,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFactoryConflictsWithMemberCause({
  required String memberName,
}) {
  var memberName_0 = conversions.validateAndDemangleName(memberName);
  return new Message(
    factoryConflictsWithMemberCause,
    problemMessage: """Conflicting member '${memberName_0}'.""",
    arguments: {'memberName': memberName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode fastaUsageLong = const MessageCode(
  "FastaUsageLong",
  problemMessage: """Supported options:

  -o <file>, --output=<file>
    Generate the output into <file>.

  -h, /h, /?, --help
    Display this message (add -v for information about all options).

  -v, --verbose
    Display verbose information.

  -Dname
  -Dname=value
    Define an environment variable in the compile-time environment.

  --no-defines
    Ignore all -D options and leave environment constants unevaluated.

  --
    Stop option parsing, the rest of the command line is assumed to be
    file names or arguments to the Dart program.

  --packages=<file>
    Use package resolution configuration <file>, which should contain a mapping
    of package names to paths.

  --platform=<file>
    Read the SDK platform from <file>, which should be in Dill/Kernel IR format
    and contain the Dart SDK.

  --target=dart2js|dart2js_server|dart2wasm|dart2wasm_js_compatibility|dart_runner|dartdevc|flutter|flutter_runner|none|vm
    Specify the target configuration.

  --enable-asserts
    Check asserts in initializers during constant evaluation.

  --verify
    Check that the generated output is free of various problems. This is mostly
    useful for developers of this compiler or Kernel transformations.

  --dump-ir
    Print compiled libraries in Kernel source notation.

  --omit-platform
    Exclude the platform from the serialized dill file.

  --exclude-source
    Do not include source code in the dill file.

  --compile-sdk=<sdk>
    Compile the SDK from scratch instead of reading it from a .dill file
    (see --platform).

  --sdk=<sdk>
    Location of the SDK sources for use when compiling additional platform
    libraries.

  --single-root-scheme=String
  --single-root-base=<dir>
    Specify a custom URI scheme and a location on disk where such URIs are
    mapped to.

    When specified, the compiler can be invoked with inputs using the custom
    URI scheme. The compiler can ignore the exact location of files on disk
    and as a result to produce output that is independent of the absolute
    location of files on disk. This is mostly useful for integrating with
    build systems.

  --fatal=errors
  --fatal=warnings
    Makes messages of the given kinds fatal, that is, immediately stop the
    compiler with a non-zero exit-code. In --verbose mode, also display an
    internal stack trace from the compiler. Multiple kinds can be separated by
    commas, for example, --fatal=errors,warnings.

  --fatal-skip=<number>
  --fatal-skip=trace
    Skip this many messages that would otherwise be fatal before aborting the
    compilation. Default is 0, which stops at the first message. Specify
    'trace' to print a stack trace for every message without stopping.

  --enable-experiment=<flag>
    Enable or disable an experimental flag, used to guard features currently
    in development. Prefix an experiment name with 'no-' to disable it.
    Multiple experiments can be separated by commas.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode fastaUsageShort = const MessageCode(
  "FastaUsageShort",
  problemMessage: """Frequently used options:

  -o <file> Generate the output into <file>.
  -h        Display this message (add -v for information about all options).""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode ffiAbiSpecificIntegerInvalid = const MessageCode(
  "FfiAbiSpecificIntegerInvalid",
  problemMessage:
      """Classes extending 'AbiSpecificInteger' must have exactly one const constructor, no other members, and no type arguments.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode ffiAbiSpecificIntegerMappingInvalid = const MessageCode(
  "FfiAbiSpecificIntegerMappingInvalid",
  problemMessage:
      """Classes extending 'AbiSpecificInteger' must have exactly one 'AbiSpecificIntegerMapping' annotation specifying the mapping from ABI to a NativeType integer with a fixed size.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode ffiAddressOfMustBeNative = const MessageCode(
  "FfiAddressOfMustBeNative",
  problemMessage:
      """Argument to 'Native.addressOf' must be annotated with @Native.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode ffiAddressPosition = const MessageCode(
  "FfiAddressPosition",
  problemMessage:
      """The '.address' expression can only be used as argument to a leaf native external call.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode ffiAddressReceiver = const MessageCode(
  "FfiAddressReceiver",
  problemMessage:
      """The receiver of '.address' must be a concrete 'TypedData', a concrete 'TypedData' '[]', an 'Array', an 'Array' '[]', a Struct field, or a Union field.""",
  correctionMessage:
      """Change the receiver of '.address' to one of the allowed kinds.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String superclass, required String name})
>
ffiCompoundImplementsFinalizable = const Template(
  "FfiCompoundImplementsFinalizable",
  withArguments: _withArgumentsFfiCompoundImplementsFinalizable,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiCompoundImplementsFinalizable({
  required String superclass,
  required String name,
}) {
  var superclass_0 = conversions.validateString(superclass);
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    ffiCompoundImplementsFinalizable,
    problemMessage:
        """${superclass_0} '${name_0}' can't implement Finalizable.""",
    correctionMessage:
        """Try removing the implements clause from '${name_0}'.""",
    arguments: {'superclass': superclass, 'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode ffiCreateOfStructOrUnion = const MessageCode(
  "FfiCreateOfStructOrUnion",
  problemMessage:
      """Subclasses of 'Struct' and 'Union' are backed by native memory, and can't be instantiated by a generative constructor. Try allocating it via allocation, or load from a 'Pointer'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required DartType actualType,
    required DartType expectedType,
  })
>
ffiDartTypeMismatch = const Template(
  "FfiDartTypeMismatch",
  withArguments: _withArgumentsFfiDartTypeMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiDartTypeMismatch({
  required DartType actualType,
  required DartType expectedType,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var actualType_0 = labeler.labelType(actualType);
  var expectedType_0 = labeler.labelType(expectedType);
  return new Message(
    ffiDartTypeMismatch,
    problemMessage:
        """Expected '${actualType_0}' to be a subtype of '${expectedType_0}'.""" +
        labeler.originMessages,
    arguments: {'actualType': actualType, 'expectedType': expectedType},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode ffiDeeplyImmutableClassesMustBeFinalOrSealed =
    const MessageCode(
      "FfiDeeplyImmutableClassesMustBeFinalOrSealed",
      problemMessage: """Deeply immutable classes must be final or sealed.""",
      correctionMessage: """Try marking this class as final or sealed.""",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode ffiDeeplyImmutableFieldsModifiers = const MessageCode(
  "FfiDeeplyImmutableFieldsModifiers",
  problemMessage:
      """Deeply immutable classes must only have final non-late instance fields.""",
  correctionMessage:
      """Add the 'final' modifier to this field, and remove 'late' modifier from this field.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
ffiDeeplyImmutableFieldsMustBeDeeplyImmutable = const MessageCode(
  "FfiDeeplyImmutableFieldsMustBeDeeplyImmutable",
  problemMessage:
      """Deeply immutable classes must only have deeply immutable instance fields. Deeply immutable types include 'int', 'double', 'bool', 'String', 'Pointer', 'Float32x4', 'Float64x2', 'Int32x4', function types and classes annotated with `@pragma('vm:deeply-immutable')`.""",
  correctionMessage:
      """Try changing the type of this field to a deeply immutable type or mark the type of this field as deeply immutable.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
ffiDeeplyImmutableSubtypesMustBeDeeplyImmutable = const MessageCode(
  "FfiDeeplyImmutableSubtypesMustBeDeeplyImmutable",
  problemMessage:
      """Subtypes of deeply immutable classes must be deeply immutable.""",
  correctionMessage:
      """Try marking this class deeply immutable by adding `@pragma('vm:deeply-immutable')`.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
ffiDeeplyImmutableSupertypeMustBeDeeplyImmutable = const MessageCode(
  "FfiDeeplyImmutableSupertypeMustBeDeeplyImmutable",
  problemMessage:
      """The super type of deeply immutable classes must be deeply immutable.""",
  correctionMessage:
      """Try marking the super class deeply immutable by adding `@pragma('vm:deeply-immutable')`.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode ffiDefaultAssetDuplicate = const MessageCode(
  "FfiDefaultAssetDuplicate",
  problemMessage:
      """There may be at most one @DefaultAsset annotation on a library.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String superclass, required String name})
>
ffiEmptyStruct = const Template(
  "FfiEmptyStruct",
  withArguments: _withArgumentsFfiEmptyStruct,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiEmptyStruct({
  required String superclass,
  required String name,
}) {
  var superclass_0 = conversions.validateString(superclass);
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    ffiEmptyStruct,
    problemMessage:
        """${superclass_0} '${name_0}' is empty. Empty structs and unions are undefined behavior.""",
    arguments: {'superclass': superclass, 'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode ffiExceptionalReturnNull = const MessageCode(
  "FfiExceptionalReturnNull",
  problemMessage: """Exceptional return value must not be null.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode ffiExpectedConstant = const MessageCode(
  "FfiExpectedConstant",
  problemMessage: """Exceptional return value must be a constant.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name})>
ffiExpectedConstantArg = const Template(
  "FfiExpectedConstantArg",
  withArguments: _withArgumentsFfiExpectedConstantArg,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiExpectedConstantArg({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    ffiExpectedConstantArg,
    problemMessage: """Argument '${name_0}' must be a constant.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required DartType returnType})>
ffiExpectedExceptionalReturn = const Template(
  "FfiExpectedExceptionalReturn",
  withArguments: _withArgumentsFfiExpectedExceptionalReturn,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiExpectedExceptionalReturn({
  required DartType returnType,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var returnType_0 = labeler.labelType(returnType);
  return new Message(
    ffiExpectedExceptionalReturn,
    problemMessage:
        """Expected an exceptional return value for a native callback returning '${returnType_0}'.""" +
        labeler.originMessages,
    arguments: {'returnType': returnType},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required DartType returnType})>
ffiExpectedNoExceptionalReturn = const Template(
  "FfiExpectedNoExceptionalReturn",
  withArguments: _withArgumentsFfiExpectedNoExceptionalReturn,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiExpectedNoExceptionalReturn({
  required DartType returnType,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var returnType_0 = labeler.labelType(returnType);
  return new Message(
    ffiExpectedNoExceptionalReturn,
    problemMessage:
        """Exceptional return value cannot be provided for a native callback returning '${returnType_0}'.""" +
        labeler.originMessages,
    arguments: {'returnType': returnType},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String sealedClassName})>
ffiExtendsOrImplementsSealedClass = const Template(
  "FfiExtendsOrImplementsSealedClass",
  withArguments: _withArgumentsFfiExtendsOrImplementsSealedClass,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiExtendsOrImplementsSealedClass({
  required String sealedClassName,
}) {
  var sealedClassName_0 = conversions.validateAndDemangleName(sealedClassName);
  return new Message(
    ffiExtendsOrImplementsSealedClass,
    problemMessage:
        """Class '${sealedClassName_0}' cannot be extended or implemented.""",
    arguments: {'sealedClassName': sealedClassName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String fieldName})>
ffiFieldAnnotation = const Template(
  "FfiFieldAnnotation",
  withArguments: _withArgumentsFfiFieldAnnotation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiFieldAnnotation({required String fieldName}) {
  var fieldName_0 = conversions.validateAndDemangleName(fieldName);
  return new Message(
    ffiFieldAnnotation,
    problemMessage:
        """Field '${fieldName_0}' requires exactly one annotation to declare its native type, which cannot be Void. dart:ffi Structs and Unions cannot have regular Dart fields.""",
    arguments: {'fieldName': fieldName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String superclass,
    required String name,
    required List<String> cycleElements,
  })
>
ffiFieldCyclic = const Template(
  "FfiFieldCyclic",
  withArguments: _withArgumentsFfiFieldCyclic,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiFieldCyclic({
  required String superclass,
  required String name,
  required List<String> cycleElements,
}) {
  var superclass_0 = conversions.validateString(superclass);
  var name_0 = conversions.validateAndDemangleName(name);
  var cycleElements_0 = conversions.validateAndItemizeNames(cycleElements);
  return new Message(
    ffiFieldCyclic,
    problemMessage:
        """${superclass_0} '${name_0}' contains itself. Cycle elements:
${cycleElements_0}""",
    arguments: {
      'superclass': superclass,
      'name': name,
      'cycleElements': cycleElements,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String fieldName})>
ffiFieldInitializer = const Template(
  "FfiFieldInitializer",
  withArguments: _withArgumentsFfiFieldInitializer,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiFieldInitializer({required String fieldName}) {
  var fieldName_0 = conversions.validateAndDemangleName(fieldName);
  return new Message(
    ffiFieldInitializer,
    problemMessage:
        """Field '${fieldName_0}' is a dart:ffi Pointer to a struct field and therefore cannot be initialized before constructor execution.""",
    correctionMessage:
        """Mark the field as external to avoid having to initialize it.""",
    arguments: {'fieldName': fieldName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String fieldName})>
ffiFieldNoAnnotation = const Template(
  "FfiFieldNoAnnotation",
  withArguments: _withArgumentsFfiFieldNoAnnotation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiFieldNoAnnotation({required String fieldName}) {
  var fieldName_0 = conversions.validateAndDemangleName(fieldName);
  return new Message(
    ffiFieldNoAnnotation,
    problemMessage:
        """Field '${fieldName_0}' requires no annotation to declare its native type, it is a Pointer which is represented by the same type in Dart and native code.""",
    arguments: {'fieldName': fieldName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String fieldName})> ffiFieldNull =
    const Template("FfiFieldNull", withArguments: _withArgumentsFfiFieldNull);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiFieldNull({required String fieldName}) {
  var fieldName_0 = conversions.validateAndDemangleName(fieldName);
  return new Message(
    ffiFieldNull,
    problemMessage:
        """Field '${fieldName_0}' cannot be nullable or have type 'Null', it must be `int`, `double`, `Pointer`, or a subtype of `Struct` or `Union`.""",
    arguments: {'fieldName': fieldName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode ffiLeafCallMustNotReturnHandle = const MessageCode(
  "FfiLeafCallMustNotReturnHandle",
  problemMessage: """FFI leaf call must not have Handle return type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode ffiLeafCallMustNotTakeHandle = const MessageCode(
  "FfiLeafCallMustNotTakeHandle",
  problemMessage: """FFI leaf call must not have Handle argument types.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required DartType returnType})>
ffiNativeCallableListenerReturnVoid = const Template(
  "FfiNativeCallableListenerReturnVoid",
  withArguments: _withArgumentsFfiNativeCallableListenerReturnVoid,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiNativeCallableListenerReturnVoid({
  required DartType returnType,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var returnType_0 = labeler.labelType(returnType);
  return new Message(
    ffiNativeCallableListenerReturnVoid,
    problemMessage:
        """The return type of the function passed to NativeCallable.listener must be void rather than '${returnType_0}'.""" +
        labeler.originMessages,
    arguments: {'returnType': returnType},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode ffiNativeDuplicateAnnotations = const MessageCode(
  "FfiNativeDuplicateAnnotations",
  problemMessage:
      """Native functions and fields must not have more than @Native annotation.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode ffiNativeFieldMissingType = const MessageCode(
  "FfiNativeFieldMissingType",
  problemMessage:
      """The native type of this field could not be inferred and must be specified in the annotation.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode ffiNativeFieldMustBeStatic = const MessageCode(
  "FfiNativeFieldMustBeStatic",
  problemMessage: """Native fields must be static.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode ffiNativeFieldType = const MessageCode(
  "FfiNativeFieldType",
  problemMessage:
      """Unsupported type for native fields. Native fields only support pointers, compounds and numeric types.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode ffiNativeFunctionMissingType = const MessageCode(
  "FfiNativeFunctionMissingType",
  problemMessage:
      """The native type of this function couldn't be inferred so it must be specified in the annotation.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode ffiNativeMustBeExternal = const MessageCode(
  "FfiNativeMustBeExternal",
  problemMessage: """Native functions and fields must be marked external.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
ffiNativeOnlyNativeFieldWrapperClassCanBePointer = const MessageCode(
  "FfiNativeOnlyNativeFieldWrapperClassCanBePointer",
  problemMessage:
      """Only classes extending NativeFieldWrapperClass1 can be passed as Pointer.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required int expectedCount, required int actualCount})
>
ffiNativeUnexpectedNumberOfParameters = const Template(
  "FfiNativeUnexpectedNumberOfParameters",
  withArguments: _withArgumentsFfiNativeUnexpectedNumberOfParameters,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiNativeUnexpectedNumberOfParameters({
  required int expectedCount,
  required int actualCount,
}) {
  return new Message(
    ffiNativeUnexpectedNumberOfParameters,
    problemMessage:
        """Unexpected number of Native annotation parameters. Expected ${expectedCount} but has ${actualCount}.""",
    arguments: {'expectedCount': expectedCount, 'actualCount': actualCount},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required int expectedCount, required int actualCount})
>
ffiNativeUnexpectedNumberOfParametersWithReceiver = const Template(
  "FfiNativeUnexpectedNumberOfParametersWithReceiver",
  withArguments:
      _withArgumentsFfiNativeUnexpectedNumberOfParametersWithReceiver,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiNativeUnexpectedNumberOfParametersWithReceiver({
  required int expectedCount,
  required int actualCount,
}) {
  return new Message(
    ffiNativeUnexpectedNumberOfParametersWithReceiver,
    problemMessage:
        """Unexpected number of Native annotation parameters. Expected ${expectedCount} but has ${actualCount}. Native instance method annotation must have receiver as first argument.""",
    arguments: {'expectedCount': expectedCount, 'actualCount': actualCount},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name})> ffiNotStatic =
    const Template("FfiNotStatic", withArguments: _withArgumentsFfiNotStatic);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiNotStatic({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    ffiNotStatic,
    problemMessage:
        """${name_0} expects a static function as parameter. dart:ffi only supports calling static Dart functions from native code. Closures and tear-offs are not supported because they can capture context.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name})> ffiPackedAnnotation =
    const Template(
      "FfiPackedAnnotation",
      withArguments: _withArgumentsFfiPackedAnnotation,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiPackedAnnotation({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    ffiPackedAnnotation,
    problemMessage:
        """Struct '${name_0}' must have at most one 'Packed' annotation.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode ffiPackedAnnotationAlignment = const MessageCode(
  "FfiPackedAnnotationAlignment",
  problemMessage: """Only packing to 1, 2, 4, 8, and 16 bytes is supported.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String fieldName})>
ffiSizeAnnotation = const Template(
  "FfiSizeAnnotation",
  withArguments: _withArgumentsFfiSizeAnnotation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiSizeAnnotation({required String fieldName}) {
  var fieldName_0 = conversions.validateAndDemangleName(fieldName);
  return new Message(
    ffiSizeAnnotation,
    problemMessage:
        """Field '${fieldName_0}' must have exactly one 'Array' annotation.""",
    arguments: {'fieldName': fieldName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String fieldName})>
ffiSizeAnnotationDimensions = const Template(
  "FfiSizeAnnotationDimensions",
  withArguments: _withArgumentsFfiSizeAnnotationDimensions,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiSizeAnnotationDimensions({required String fieldName}) {
  var fieldName_0 = conversions.validateAndDemangleName(fieldName);
  return new Message(
    ffiSizeAnnotationDimensions,
    problemMessage:
        """Field '${fieldName_0}' must have an 'Array' annotation that matches the dimensions.""",
    arguments: {'fieldName': fieldName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String superclass, required String name})
>
ffiStructGeneric = const Template(
  "FfiStructGeneric",
  withArguments: _withArgumentsFfiStructGeneric,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiStructGeneric({
  required String superclass,
  required String name,
}) {
  var superclass_0 = conversions.validateString(superclass);
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    ffiStructGeneric,
    problemMessage: """${superclass_0} '${name_0}' should not be generic.""",
    arguments: {'superclass': superclass, 'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required DartType type})> ffiTypeInvalid =
    const Template(
      "FfiTypeInvalid",
      withArguments: _withArgumentsFfiTypeInvalid,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiTypeInvalid({required DartType type}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    ffiTypeInvalid,
    problemMessage:
        """Expected type '${type_0}' to be a valid and instantiated subtype of 'NativeType'.""" +
        labeler.originMessages,
    arguments: {'type': type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required DartType actualType,
    required DartType expectedType,
    required DartType nativeType,
  })
>
ffiTypeMismatch = const Template(
  "FfiTypeMismatch",
  withArguments: _withArgumentsFfiTypeMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiTypeMismatch({
  required DartType actualType,
  required DartType expectedType,
  required DartType nativeType,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var actualType_0 = labeler.labelType(actualType);
  var expectedType_0 = labeler.labelType(expectedType);
  var nativeType_0 = labeler.labelType(nativeType);
  return new Message(
    ffiTypeMismatch,
    problemMessage:
        """Expected type '${actualType_0}' to be '${expectedType_0}', which is the Dart type corresponding to '${nativeType_0}'.""" +
        labeler.originMessages,
    arguments: {
      'actualType': actualType,
      'expectedType': expectedType,
      'nativeType': nativeType,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode ffiVariableLengthArrayNotLast = const MessageCode(
  "FfiVariableLengthArrayNotLast",
  problemMessage:
      """Variable length 'Array's must only occur as the last field of Structs.""",
  correctionMessage:
      """Try adjusting the arguments in the 'Array' annotation.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String fieldName})>
fieldAlreadyInitializedAtDeclaration = const Template(
  "FieldAlreadyInitializedAtDeclaration",
  withArguments: _withArgumentsFieldAlreadyInitializedAtDeclaration,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFieldAlreadyInitializedAtDeclaration({
  required String fieldName,
}) {
  var fieldName_0 = conversions.validateAndDemangleName(fieldName);
  return new Message(
    fieldAlreadyInitializedAtDeclaration,
    problemMessage:
        """'${fieldName_0}' is a final instance variable that was initialized at the declaration.""",
    arguments: {'fieldName': fieldName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String fieldName})>
fieldAlreadyInitializedAtDeclarationCause = const Template(
  "FieldAlreadyInitializedAtDeclarationCause",
  withArguments: _withArgumentsFieldAlreadyInitializedAtDeclarationCause,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFieldAlreadyInitializedAtDeclarationCause({
  required String fieldName,
}) {
  var fieldName_0 = conversions.validateAndDemangleName(fieldName);
  return new Message(
    fieldAlreadyInitializedAtDeclarationCause,
    problemMessage: """'${fieldName_0}' was initialized here.""",
    arguments: {'fieldName': fieldName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String fieldName, required DartType fieldType})
>
fieldNonNullableNotInitializedByConstructorError = const Template(
  "FieldNonNullableNotInitializedByConstructorError",
  withArguments: _withArgumentsFieldNonNullableNotInitializedByConstructorError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFieldNonNullableNotInitializedByConstructorError({
  required String fieldName,
  required DartType fieldType,
}) {
  var fieldName_0 = conversions.validateAndDemangleName(fieldName);
  TypeLabeler labeler = new TypeLabeler();
  var fieldType_0 = labeler.labelType(fieldType);
  return new Message(
    fieldNonNullableNotInitializedByConstructorError,
    problemMessage:
        """This constructor should initialize field '${fieldName_0}' because its type '${fieldType_0}' doesn't allow null.""" +
        labeler.originMessages,
    arguments: {'fieldName': fieldName, 'fieldType': fieldType},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String fieldName, required DartType fieldType})
>
fieldNonNullableWithoutInitializerError = const Template(
  "FieldNonNullableWithoutInitializerError",
  withArguments: _withArgumentsFieldNonNullableWithoutInitializerError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFieldNonNullableWithoutInitializerError({
  required String fieldName,
  required DartType fieldType,
}) {
  var fieldName_0 = conversions.validateAndDemangleName(fieldName);
  TypeLabeler labeler = new TypeLabeler();
  var fieldType_0 = labeler.labelType(fieldType);
  return new Message(
    fieldNonNullableWithoutInitializerError,
    problemMessage:
        """Field '${fieldName_0}' should be initialized because its type '${fieldType_0}' doesn't allow null.""" +
        labeler.originMessages,
    arguments: {'fieldName': fieldName, 'fieldType': fieldType},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String propertyName,
    required String conflictingFieldClassName,
    required String documentationUrl,
  })
>
fieldNotPromotedBecauseConflictingField = const Template(
  "FieldNotPromotedBecauseConflictingField",
  withArguments: _withArgumentsFieldNotPromotedBecauseConflictingField,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFieldNotPromotedBecauseConflictingField({
  required String propertyName,
  required String conflictingFieldClassName,
  required String documentationUrl,
}) {
  var propertyName_0 = conversions.validateAndDemangleName(propertyName);
  var conflictingFieldClassName_0 = conversions.validateAndDemangleName(
    conflictingFieldClassName,
  );
  var documentationUrl_0 = conversions.validateString(documentationUrl);
  return new Message(
    fieldNotPromotedBecauseConflictingField,
    problemMessage:
        """'${propertyName_0}' couldn't be promoted because there is a conflicting non-promotable field in class '${conflictingFieldClassName_0}'.""",
    correctionMessage: """See ${documentationUrl_0}""",
    arguments: {
      'propertyName': propertyName,
      'conflictingFieldClassName': conflictingFieldClassName,
      'documentationUrl': documentationUrl,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String propertyName,
    required String conflictingGetterClassName,
    required String documentationUrl,
  })
>
fieldNotPromotedBecauseConflictingGetter = const Template(
  "FieldNotPromotedBecauseConflictingGetter",
  withArguments: _withArgumentsFieldNotPromotedBecauseConflictingGetter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFieldNotPromotedBecauseConflictingGetter({
  required String propertyName,
  required String conflictingGetterClassName,
  required String documentationUrl,
}) {
  var propertyName_0 = conversions.validateAndDemangleName(propertyName);
  var conflictingGetterClassName_0 = conversions.validateAndDemangleName(
    conflictingGetterClassName,
  );
  var documentationUrl_0 = conversions.validateString(documentationUrl);
  return new Message(
    fieldNotPromotedBecauseConflictingGetter,
    problemMessage:
        """'${propertyName_0}' couldn't be promoted because there is a conflicting getter in class '${conflictingGetterClassName_0}'.""",
    correctionMessage: """See ${documentationUrl_0}""",
    arguments: {
      'propertyName': propertyName,
      'conflictingGetterClassName': conflictingGetterClassName,
      'documentationUrl': documentationUrl,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String propertyName,
    required String conflictingNsmClassName,
    required String documentationUrl,
  })
>
fieldNotPromotedBecauseConflictingNsmForwarder = const Template(
  "FieldNotPromotedBecauseConflictingNsmForwarder",
  withArguments: _withArgumentsFieldNotPromotedBecauseConflictingNsmForwarder,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFieldNotPromotedBecauseConflictingNsmForwarder({
  required String propertyName,
  required String conflictingNsmClassName,
  required String documentationUrl,
}) {
  var propertyName_0 = conversions.validateAndDemangleName(propertyName);
  var conflictingNsmClassName_0 = conversions.validateAndDemangleName(
    conflictingNsmClassName,
  );
  var documentationUrl_0 = conversions.validateString(documentationUrl);
  return new Message(
    fieldNotPromotedBecauseConflictingNsmForwarder,
    problemMessage:
        """'${propertyName_0}' couldn't be promoted because there is a conflicting noSuchMethod forwarder in class '${conflictingNsmClassName_0}'.""",
    correctionMessage: """See ${documentationUrl_0}""",
    arguments: {
      'propertyName': propertyName,
      'conflictingNsmClassName': conflictingNsmClassName,
      'documentationUrl': documentationUrl,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String propertyName,
    required String documentationUrl,
  })
>
fieldNotPromotedBecauseExternal = const Template(
  "FieldNotPromotedBecauseExternal",
  withArguments: _withArgumentsFieldNotPromotedBecauseExternal,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFieldNotPromotedBecauseExternal({
  required String propertyName,
  required String documentationUrl,
}) {
  var propertyName_0 = conversions.validateAndDemangleName(propertyName);
  var documentationUrl_0 = conversions.validateString(documentationUrl);
  return new Message(
    fieldNotPromotedBecauseExternal,
    problemMessage:
        """'${propertyName_0}' refers to an external field so it couldn't be promoted.""",
    correctionMessage: """See ${documentationUrl_0}""",
    arguments: {
      'propertyName': propertyName,
      'documentationUrl': documentationUrl,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String variableName,
    required String documentationUrl,
  })
>
fieldNotPromotedBecauseNotEnabled = const Template(
  "FieldNotPromotedBecauseNotEnabled",
  withArguments: _withArgumentsFieldNotPromotedBecauseNotEnabled,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFieldNotPromotedBecauseNotEnabled({
  required String variableName,
  required String documentationUrl,
}) {
  var variableName_0 = conversions.validateAndDemangleName(variableName);
  var documentationUrl_0 = conversions.validateString(documentationUrl);
  return new Message(
    fieldNotPromotedBecauseNotEnabled,
    problemMessage:
        """'${variableName_0}' couldn't be promoted because field promotion is only available in Dart 3.2 and above.""",
    correctionMessage: """See ${documentationUrl_0}""",
    arguments: {
      'variableName': variableName,
      'documentationUrl': documentationUrl,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String propertyName,
    required String documentationUrl,
  })
>
fieldNotPromotedBecauseNotField = const Template(
  "FieldNotPromotedBecauseNotField",
  withArguments: _withArgumentsFieldNotPromotedBecauseNotField,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFieldNotPromotedBecauseNotField({
  required String propertyName,
  required String documentationUrl,
}) {
  var propertyName_0 = conversions.validateAndDemangleName(propertyName);
  var documentationUrl_0 = conversions.validateString(documentationUrl);
  return new Message(
    fieldNotPromotedBecauseNotField,
    problemMessage:
        """'${propertyName_0}' refers to a getter so it couldn't be promoted.""",
    correctionMessage: """See ${documentationUrl_0}""",
    arguments: {
      'propertyName': propertyName,
      'documentationUrl': documentationUrl,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String propertyName,
    required String documentationUrl,
  })
>
fieldNotPromotedBecauseNotFinal = const Template(
  "FieldNotPromotedBecauseNotFinal",
  withArguments: _withArgumentsFieldNotPromotedBecauseNotFinal,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFieldNotPromotedBecauseNotFinal({
  required String propertyName,
  required String documentationUrl,
}) {
  var propertyName_0 = conversions.validateAndDemangleName(propertyName);
  var documentationUrl_0 = conversions.validateString(documentationUrl);
  return new Message(
    fieldNotPromotedBecauseNotFinal,
    problemMessage:
        """'${propertyName_0}' refers to a non-final field so it couldn't be promoted.""",
    correctionMessage: """See ${documentationUrl_0}""",
    arguments: {
      'propertyName': propertyName,
      'documentationUrl': documentationUrl,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String propertyName,
    required String documentationUrl,
  })
>
fieldNotPromotedBecauseNotPrivate = const Template(
  "FieldNotPromotedBecauseNotPrivate",
  withArguments: _withArgumentsFieldNotPromotedBecauseNotPrivate,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFieldNotPromotedBecauseNotPrivate({
  required String propertyName,
  required String documentationUrl,
}) {
  var propertyName_0 = conversions.validateAndDemangleName(propertyName);
  var documentationUrl_0 = conversions.validateString(documentationUrl);
  return new Message(
    fieldNotPromotedBecauseNotPrivate,
    problemMessage:
        """'${propertyName_0}' refers to a public property so it couldn't be promoted.""",
    correctionMessage: """See ${documentationUrl_0}""",
    arguments: {
      'propertyName': propertyName,
      'documentationUrl': documentationUrl,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String className})>
finalClassExtendedOutsideOfLibrary = const Template(
  "FinalClassExtendedOutsideOfLibrary",
  withArguments: _withArgumentsFinalClassExtendedOutsideOfLibrary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFinalClassExtendedOutsideOfLibrary({
  required String className,
}) {
  var className_0 = conversions.validateAndDemangleName(className);
  return new Message(
    finalClassExtendedOutsideOfLibrary,
    problemMessage:
        """The class '${className_0}' can't be extended outside of its library because it's a final class.""",
    arguments: {'className': className},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String className})>
finalClassImplementedOutsideOfLibrary = const Template(
  "FinalClassImplementedOutsideOfLibrary",
  withArguments: _withArgumentsFinalClassImplementedOutsideOfLibrary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFinalClassImplementedOutsideOfLibrary({
  required String className,
}) {
  var className_0 = conversions.validateAndDemangleName(className);
  return new Message(
    finalClassImplementedOutsideOfLibrary,
    problemMessage:
        """The class '${className_0}' can't be implemented outside of its library because it's a final class.""",
    arguments: {'className': className},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String className})>
finalClassUsedAsMixinConstraintOutsideOfLibrary = const Template(
  "FinalClassUsedAsMixinConstraintOutsideOfLibrary",
  withArguments: _withArgumentsFinalClassUsedAsMixinConstraintOutsideOfLibrary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFinalClassUsedAsMixinConstraintOutsideOfLibrary({
  required String className,
}) {
  var className_0 = conversions.validateAndDemangleName(className);
  return new Message(
    finalClassUsedAsMixinConstraintOutsideOfLibrary,
    problemMessage:
        """The class '${className_0}' can't be used as a mixin superclass constraint outside of its library because it's a final class.""",
    arguments: {'className': className},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String fieldName})>
finalFieldNotInitialized = const Template(
  "FinalFieldNotInitialized",
  withArguments: _withArgumentsFinalFieldNotInitialized,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFinalFieldNotInitialized({required String fieldName}) {
  var fieldName_0 = conversions.validateAndDemangleName(fieldName);
  return new Message(
    finalFieldNotInitialized,
    problemMessage: """Final field '${fieldName_0}' is not initialized.""",
    correctionMessage:
        """Try to initialize the field in the declaration or in every constructor.""",
    arguments: {'fieldName': fieldName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String fieldName})>
finalFieldNotInitializedByConstructor = const Template(
  "FinalFieldNotInitializedByConstructor",
  withArguments: _withArgumentsFinalFieldNotInitializedByConstructor,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFinalFieldNotInitializedByConstructor({
  required String fieldName,
}) {
  var fieldName_0 = conversions.validateAndDemangleName(fieldName);
  return new Message(
    finalFieldNotInitializedByConstructor,
    problemMessage:
        """Final field '${fieldName_0}' is not initialized by this constructor.""",
    correctionMessage:
        """Try to initialize the field using an initializing formal or a field initializer.""",
    arguments: {'fieldName': fieldName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String variableName})>
finalNotAssignedError = const Template(
  "FinalNotAssignedError",
  withArguments: _withArgumentsFinalNotAssignedError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFinalNotAssignedError({required String variableName}) {
  var variableName_0 = conversions.validateAndDemangleName(variableName);
  return new Message(
    finalNotAssignedError,
    problemMessage:
        """Final variable '${variableName_0}' must be assigned before it can be used.""",
    arguments: {'variableName': variableName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String variableName})>
finalPossiblyAssignedError = const Template(
  "FinalPossiblyAssignedError",
  withArguments: _withArgumentsFinalPossiblyAssignedError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFinalPossiblyAssignedError({
  required String variableName,
}) {
  var variableName_0 = conversions.validateAndDemangleName(variableName);
  return new Message(
    finalPossiblyAssignedError,
    problemMessage:
        """Final variable '${variableName_0}' might already be assigned at this point.""",
    arguments: {'variableName': variableName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required DartType actualType,
    required DartType expectedType,
  })
>
forInLoopElementTypeNotAssignable = const Template(
  "ForInLoopElementTypeNotAssignable",
  withArguments: _withArgumentsForInLoopElementTypeNotAssignable,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsForInLoopElementTypeNotAssignable({
  required DartType actualType,
  required DartType expectedType,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var actualType_0 = labeler.labelType(actualType);
  var expectedType_0 = labeler.labelType(expectedType);
  return new Message(
    forInLoopElementTypeNotAssignable,
    problemMessage:
        """A value of type '${actualType_0}' can't be assigned to a variable of type '${expectedType_0}'.""" +
        labeler.originMessages,
    correctionMessage: """Try changing the type of the variable.""",
    arguments: {'actualType': actualType, 'expectedType': expectedType},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode forInLoopExactlyOneVariable = const MessageCode(
  "ForInLoopExactlyOneVariable",
  problemMessage: """A for-in loop can't have more than one loop variable.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode forInLoopNotAssignable = const MessageCode(
  "ForInLoopNotAssignable",
  problemMessage:
      """Can't assign to this, so it can't be used in a for-in loop.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required DartType actualType,
    required DartType expectedType,
  })
>
forInLoopTypeNotIterable = const Template(
  "ForInLoopTypeNotIterable",
  withArguments: _withArgumentsForInLoopTypeNotIterable,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsForInLoopTypeNotIterable({
  required DartType actualType,
  required DartType expectedType,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var actualType_0 = labeler.labelType(actualType);
  var expectedType_0 = labeler.labelType(expectedType);
  return new Message(
    forInLoopTypeNotIterable,
    problemMessage:
        """The type '${actualType_0}' used in the 'for' loop must implement '${expectedType_0}'.""" +
        labeler.originMessages,
    arguments: {'actualType': actualType, 'expectedType': expectedType},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode forInLoopWithConstVariable = const MessageCode(
  "ForInLoopWithConstVariable",
  problemMessage: """A for-in loop-variable can't be 'const'.""",
  correctionMessage: """Try removing the 'const' modifier.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required DartType genericFunctionType,
    required DartType aliasType,
  })
>
genericFunctionTypeAsTypeArgumentThroughTypedef = const Template(
  "GenericFunctionTypeAsTypeArgumentThroughTypedef",
  withArguments: _withArgumentsGenericFunctionTypeAsTypeArgumentThroughTypedef,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsGenericFunctionTypeAsTypeArgumentThroughTypedef({
  required DartType genericFunctionType,
  required DartType aliasType,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var genericFunctionType_0 = labeler.labelType(genericFunctionType);
  var aliasType_0 = labeler.labelType(aliasType);
  return new Message(
    genericFunctionTypeAsTypeArgumentThroughTypedef,
    problemMessage:
        """Generic function type '${genericFunctionType_0}' used as a type argument through typedef '${aliasType_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try providing a non-generic function type explicitly.""",
    arguments: {
      'genericFunctionType': genericFunctionType,
      'aliasType': aliasType,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode genericFunctionTypeInBound = const MessageCode(
  "GenericFunctionTypeInBound",
  problemMessage:
      """Type variables can't have generic function types in their bounds.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required DartType type})>
genericFunctionTypeInferredAsActualTypeArgument = const Template(
  "GenericFunctionTypeInferredAsActualTypeArgument",
  withArguments: _withArgumentsGenericFunctionTypeInferredAsActualTypeArgument,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsGenericFunctionTypeInferredAsActualTypeArgument({
  required DartType type,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    genericFunctionTypeInferredAsActualTypeArgument,
    problemMessage:
        """Generic function type '${type_0}' inferred as a type argument.""" +
        labeler.originMessages,
    correctionMessage:
        """Try providing a non-generic function type explicitly.""",
    arguments: {'type': type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode genericFunctionTypeUsedAsActualTypeArgument =
    const MessageCode(
      "GenericFunctionTypeUsedAsActualTypeArgument",
      problemMessage:
          """A generic function type can't be used as a type argument.""",
      correctionMessage: """Try using a non-generic function type.""",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name})> getterNotFound =
    const Template(
      "GetterNotFound",
      withArguments: _withArgumentsGetterNotFound,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsGetterNotFound({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    getterNotFound,
    problemMessage: """Getter not found: '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode illegalAsyncGeneratorReturnType = const MessageCode(
  "IllegalAsyncGeneratorReturnType",
  problemMessage:
      """Functions marked 'async*' must have a return type assignable to 'Stream'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode illegalAsyncGeneratorVoidReturnType = const MessageCode(
  "IllegalAsyncGeneratorVoidReturnType",
  problemMessage:
      """Functions marked 'async*' can't have return type 'void'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode illegalAsyncReturnType = const MessageCode(
  "IllegalAsyncReturnType",
  problemMessage:
      """Functions marked 'async' must have a return type assignable to 'Future'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String typeName})> illegalMixin =
    const Template("IllegalMixin", withArguments: _withArgumentsIllegalMixin);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIllegalMixin({required String typeName}) {
  var typeName_0 = conversions.validateAndDemangleName(typeName);
  return new Message(
    illegalMixin,
    problemMessage: """The type '${typeName_0}' can't be mixed in.""",
    arguments: {'typeName': typeName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String className})>
illegalMixinDueToConstructors = const Template(
  "IllegalMixinDueToConstructors",
  withArguments: _withArgumentsIllegalMixinDueToConstructors,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIllegalMixinDueToConstructors({
  required String className,
}) {
  var className_0 = conversions.validateAndDemangleName(className);
  return new Message(
    illegalMixinDueToConstructors,
    problemMessage:
        """Can't use '${className_0}' as a mixin because it has constructors.""",
    arguments: {'className': className},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String className})>
illegalMixinDueToConstructorsCause = const Template(
  "IllegalMixinDueToConstructorsCause",
  withArguments: _withArgumentsIllegalMixinDueToConstructorsCause,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIllegalMixinDueToConstructorsCause({
  required String className,
}) {
  var className_0 = conversions.validateAndDemangleName(className);
  return new Message(
    illegalMixinDueToConstructorsCause,
    problemMessage:
        """This constructor prevents using '${className_0}' as a mixin.""",
    arguments: {'className': className},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode illegalSyncGeneratorReturnType = const MessageCode(
  "IllegalSyncGeneratorReturnType",
  problemMessage:
      """Functions marked 'sync*' must have a return type assignable to 'Iterable'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode illegalSyncGeneratorVoidReturnType = const MessageCode(
  "IllegalSyncGeneratorVoidReturnType",
  problemMessage: """Functions marked 'sync*' can't have return type 'void'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String extensionTypeName,
    required String memberName,
  })
>
implementMultipleExtensionTypeMembers = const Template(
  "ImplementMultipleExtensionTypeMembers",
  withArguments: _withArgumentsImplementMultipleExtensionTypeMembers,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsImplementMultipleExtensionTypeMembers({
  required String extensionTypeName,
  required String memberName,
}) {
  var extensionTypeName_0 = conversions.validateAndDemangleName(
    extensionTypeName,
  );
  var memberName_0 = conversions.validateAndDemangleName(memberName);
  return new Message(
    implementMultipleExtensionTypeMembers,
    problemMessage:
        """The extension type '${extensionTypeName_0}' can't inherit the member '${memberName_0}' from more than one extension type.""",
    correctionMessage:
        """Try declaring a member '${memberName_0}' in '${extensionTypeName_0}' to resolve the conflict.""",
    arguments: {
      'extensionTypeName': extensionTypeName,
      'memberName': memberName,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String extensionTypeName,
    required String memberName,
  })
>
implementNonExtensionTypeAndExtensionTypeMember = const Template(
  "ImplementNonExtensionTypeAndExtensionTypeMember",
  withArguments: _withArgumentsImplementNonExtensionTypeAndExtensionTypeMember,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsImplementNonExtensionTypeAndExtensionTypeMember({
  required String extensionTypeName,
  required String memberName,
}) {
  var extensionTypeName_0 = conversions.validateAndDemangleName(
    extensionTypeName,
  );
  var memberName_0 = conversions.validateAndDemangleName(memberName);
  return new Message(
    implementNonExtensionTypeAndExtensionTypeMember,
    problemMessage:
        """The extension type '${extensionTypeName_0}' can't inherit the member '${memberName_0}' as both an extension type member and a non-extension type member.""",
    correctionMessage:
        """Try declaring a member '${memberName_0}' in '${extensionTypeName_0}' to resolve the conflict.""",
    arguments: {
      'extensionTypeName': extensionTypeName,
      'memberName': memberName,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode implementsFutureOr = const MessageCode(
  "ImplementsFutureOr",
  problemMessage:
      """The type 'FutureOr' can't be used in an 'implements' clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode implementsNever = const MessageCode(
  "ImplementsNever",
  problemMessage:
      """The type 'Never' can't be used in an 'implements' clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String name, required int extraCount})
>
implementsRepeated = const Template(
  "ImplementsRepeated",
  withArguments: _withArgumentsImplementsRepeated,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsImplementsRepeated({
  required String name,
  required int extraCount,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    implementsRepeated,
    problemMessage: """'${name_0}' can only be implemented once.""",
    correctionMessage: """Try removing ${extraCount} of the occurrences.""",
    arguments: {'name': name, 'extraCount': extraCount},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name})> implementsSuperClass =
    const Template(
      "ImplementsSuperClass",
      withArguments: _withArgumentsImplementsSuperClass,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsImplementsSuperClass({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    implementsSuperClass,
    problemMessage:
        """'${name_0}' can't be used in both 'extends' and 'implements' clauses.""",
    correctionMessage: """Try removing one of the occurrences.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required DartType type})>
implicitCallOfNonMethod = const Template(
  "ImplicitCallOfNonMethod",
  withArguments: _withArgumentsImplicitCallOfNonMethod,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsImplicitCallOfNonMethod({required DartType type}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    implicitCallOfNonMethod,
    problemMessage:
        """Cannot invoke an instance of '${type_0}' because it declares 'call' to be something other than a method.""" +
        labeler.originMessages,
    correctionMessage:
        """Try changing 'call' to a method or explicitly invoke 'call'.""",
    arguments: {'type': type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String mixinName,
    required String baseName,
    required String erroneousMember,
  })
>
implicitMixinOverride = const Template(
  "ImplicitMixinOverride",
  withArguments: _withArgumentsImplicitMixinOverride,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsImplicitMixinOverride({
  required String mixinName,
  required String baseName,
  required String erroneousMember,
}) {
  var mixinName_0 = conversions.validateAndDemangleName(mixinName);
  var baseName_0 = conversions.validateAndDemangleName(baseName);
  var erroneousMember_0 = conversions.validateAndDemangleName(erroneousMember);
  return new Message(
    implicitMixinOverride,
    problemMessage:
        """Applying the mixin '${mixinName_0}' to '${baseName_0}' introduces an erroneous override of '${erroneousMember_0}'.""",
    arguments: {
      'mixinName': mixinName,
      'baseName': baseName,
      'erroneousMember': erroneousMember,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required DartType returnType})>
implicitReturnNull = const Template(
  "ImplicitReturnNull",
  withArguments: _withArgumentsImplicitReturnNull,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsImplicitReturnNull({required DartType returnType}) {
  TypeLabeler labeler = new TypeLabeler();
  var returnType_0 = labeler.labelType(returnType);
  return new Message(
    implicitReturnNull,
    problemMessage:
        """A non-null value must be returned since the return type '${returnType_0}' doesn't allow null.""" +
        labeler.originMessages,
    arguments: {'returnType': returnType},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode implicitSuperCallOfNonMethod = const MessageCode(
  "ImplicitSuperCallOfNonMethod",
  problemMessage:
      """Cannot invoke `super` because it declares 'call' to be something other than a method.""",
  correctionMessage:
      """Try changing 'call' to a method or explicitly invoke 'call'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String className})>
implicitSuperInitializerMissingArguments = const Template(
  "ImplicitSuperInitializerMissingArguments",
  withArguments: _withArgumentsImplicitSuperInitializerMissingArguments,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsImplicitSuperInitializerMissingArguments({
  required String className,
}) {
  var className_0 = conversions.validateAndDemangleName(className);
  return new Message(
    implicitSuperInitializerMissingArguments,
    problemMessage:
        """The implicitly called unnamed constructor from '${className_0}' has required parameters.""",
    correctionMessage:
        """Try adding an explicit super initializer with the required arguments.""",
    arguments: {'className': className},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required Uri uri,
    required String importChain,
    required String verboseImportChain,
  })
>
importChainContext = const Template(
  "ImportChainContext",
  withArguments: _withArgumentsImportChainContext,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsImportChainContext({
  required Uri uri,
  required String importChain,
  required String verboseImportChain,
}) {
  var uri_0 = conversions.relativizeUri(uri);
  var importChain_0 = conversions.validateString(importChain);
  var verboseImportChain_0 = conversions.validateString(verboseImportChain);
  return new Message(
    importChainContext,
    problemMessage:
        """The unavailable library '${uri_0}' is imported through these packages:

${importChain_0}
Detailed import paths for (some of) the these imports:

${verboseImportChain_0}""",
    arguments: {
      'uri': uri,
      'importChain': importChain,
      'verboseImportChain': verboseImportChain,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required Uri uri, required String importChain})
>
importChainContextSimple = const Template(
  "ImportChainContextSimple",
  withArguments: _withArgumentsImportChainContextSimple,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsImportChainContextSimple({
  required Uri uri,
  required String importChain,
}) {
  var uri_0 = conversions.relativizeUri(uri);
  var importChain_0 = conversions.validateString(importChain);
  return new Message(
    importChainContextSimple,
    problemMessage:
        """The unavailable library '${uri_0}' is imported through these paths:

${importChain_0}""",
    arguments: {'uri': uri, 'importChain': importChain},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required DartType redirecteeType,
    required DartType expectedType,
  })
>
incompatibleRedirecteeFunctionType = const Template(
  "IncompatibleRedirecteeFunctionType",
  withArguments: _withArgumentsIncompatibleRedirecteeFunctionType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIncompatibleRedirecteeFunctionType({
  required DartType redirecteeType,
  required DartType expectedType,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var redirecteeType_0 = labeler.labelType(redirecteeType);
  var expectedType_0 = labeler.labelType(expectedType);
  return new Message(
    incompatibleRedirecteeFunctionType,
    problemMessage:
        """The constructor function type '${redirecteeType_0}' isn't a subtype of '${expectedType_0}'.""" +
        labeler.originMessages,
    arguments: {'redirecteeType': redirecteeType, 'expectedType': expectedType},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required DartType typeArgument,
    required DartType typeParameterBound,
    required String typeParameterName,
    required String enclosingName,
  })
>
incorrectTypeArgument = const Template(
  "IncorrectTypeArgument",
  withArguments: _withArgumentsIncorrectTypeArgument,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIncorrectTypeArgument({
  required DartType typeArgument,
  required DartType typeParameterBound,
  required String typeParameterName,
  required String enclosingName,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var typeArgument_0 = labeler.labelType(typeArgument);
  var typeParameterBound_0 = labeler.labelType(typeParameterBound);
  var typeParameterName_0 = conversions.validateAndDemangleName(
    typeParameterName,
  );
  var enclosingName_0 = conversions.validateAndDemangleName(enclosingName);
  return new Message(
    incorrectTypeArgument,
    problemMessage:
        """Type argument '${typeArgument_0}' doesn't conform to the bound '${typeParameterBound_0}' of the type variable '${typeParameterName_0}' on '${enclosingName_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try changing type arguments so that they conform to the bounds.""",
    arguments: {
      'typeArgument': typeArgument,
      'typeParameterBound': typeParameterBound,
      'typeParameterName': typeParameterName,
      'enclosingName': enclosingName,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required DartType typeArgument,
    required DartType typeParameterBound,
    required String typeParameterName,
    required String enclosingName,
  })
>
incorrectTypeArgumentInferred = const Template(
  "IncorrectTypeArgumentInferred",
  withArguments: _withArgumentsIncorrectTypeArgumentInferred,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIncorrectTypeArgumentInferred({
  required DartType typeArgument,
  required DartType typeParameterBound,
  required String typeParameterName,
  required String enclosingName,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var typeArgument_0 = labeler.labelType(typeArgument);
  var typeParameterBound_0 = labeler.labelType(typeParameterBound);
  var typeParameterName_0 = conversions.validateAndDemangleName(
    typeParameterName,
  );
  var enclosingName_0 = conversions.validateAndDemangleName(enclosingName);
  return new Message(
    incorrectTypeArgumentInferred,
    problemMessage:
        """Inferred type argument '${typeArgument_0}' doesn't conform to the bound '${typeParameterBound_0}' of the type variable '${typeParameterName_0}' on '${enclosingName_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try specifying type arguments explicitly so that they conform to the bounds.""",
    arguments: {
      'typeArgument': typeArgument,
      'typeParameterBound': typeParameterBound,
      'typeParameterName': typeParameterName,
      'enclosingName': enclosingName,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required DartType typeArgument,
    required DartType typeParameterBound,
    required String typeParameterName,
    required DartType receiverType,
  })
>
incorrectTypeArgumentInstantiation = const Template(
  "IncorrectTypeArgumentInstantiation",
  withArguments: _withArgumentsIncorrectTypeArgumentInstantiation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIncorrectTypeArgumentInstantiation({
  required DartType typeArgument,
  required DartType typeParameterBound,
  required String typeParameterName,
  required DartType receiverType,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var typeArgument_0 = labeler.labelType(typeArgument);
  var typeParameterBound_0 = labeler.labelType(typeParameterBound);
  var typeParameterName_0 = conversions.validateAndDemangleName(
    typeParameterName,
  );
  var receiverType_0 = labeler.labelType(receiverType);
  return new Message(
    incorrectTypeArgumentInstantiation,
    problemMessage:
        """Type argument '${typeArgument_0}' doesn't conform to the bound '${typeParameterBound_0}' of the type variable '${typeParameterName_0}' on '${receiverType_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try changing type arguments so that they conform to the bounds.""",
    arguments: {
      'typeArgument': typeArgument,
      'typeParameterBound': typeParameterBound,
      'typeParameterName': typeParameterName,
      'receiverType': receiverType,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required DartType typeArgument,
    required DartType typeParameterBound,
    required String typeParameterName,
    required DartType receiverType,
  })
>
incorrectTypeArgumentInstantiationInferred = const Template(
  "IncorrectTypeArgumentInstantiationInferred",
  withArguments: _withArgumentsIncorrectTypeArgumentInstantiationInferred,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIncorrectTypeArgumentInstantiationInferred({
  required DartType typeArgument,
  required DartType typeParameterBound,
  required String typeParameterName,
  required DartType receiverType,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var typeArgument_0 = labeler.labelType(typeArgument);
  var typeParameterBound_0 = labeler.labelType(typeParameterBound);
  var typeParameterName_0 = conversions.validateAndDemangleName(
    typeParameterName,
  );
  var receiverType_0 = labeler.labelType(receiverType);
  return new Message(
    incorrectTypeArgumentInstantiationInferred,
    problemMessage:
        """Inferred type argument '${typeArgument_0}' doesn't conform to the bound '${typeParameterBound_0}' of the type variable '${typeParameterName_0}' on '${receiverType_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try specifying type arguments explicitly so that they conform to the bounds.""",
    arguments: {
      'typeArgument': typeArgument,
      'typeParameterBound': typeParameterBound,
      'typeParameterName': typeParameterName,
      'receiverType': receiverType,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required DartType typeArgument,
    required DartType typeParameterBound,
    required String typeParameterName,
    required DartType receiverType,
    required String targetName,
  })
>
incorrectTypeArgumentQualified = const Template(
  "IncorrectTypeArgumentQualified",
  withArguments: _withArgumentsIncorrectTypeArgumentQualified,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIncorrectTypeArgumentQualified({
  required DartType typeArgument,
  required DartType typeParameterBound,
  required String typeParameterName,
  required DartType receiverType,
  required String targetName,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var typeArgument_0 = labeler.labelType(typeArgument);
  var typeParameterBound_0 = labeler.labelType(typeParameterBound);
  var typeParameterName_0 = conversions.validateAndDemangleName(
    typeParameterName,
  );
  var receiverType_0 = labeler.labelType(receiverType);
  var targetName_0 = conversions.validateAndDemangleName(targetName);
  return new Message(
    incorrectTypeArgumentQualified,
    problemMessage:
        """Type argument '${typeArgument_0}' doesn't conform to the bound '${typeParameterBound_0}' of the type variable '${typeParameterName_0}' on '${receiverType_0}.${targetName_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try changing type arguments so that they conform to the bounds.""",
    arguments: {
      'typeArgument': typeArgument,
      'typeParameterBound': typeParameterBound,
      'typeParameterName': typeParameterName,
      'receiverType': receiverType,
      'targetName': targetName,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required DartType typeArgument,
    required DartType typeParameterBound,
    required String typeParameterName,
    required DartType receiverType,
    required String targetName,
  })
>
incorrectTypeArgumentQualifiedInferred = const Template(
  "IncorrectTypeArgumentQualifiedInferred",
  withArguments: _withArgumentsIncorrectTypeArgumentQualifiedInferred,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIncorrectTypeArgumentQualifiedInferred({
  required DartType typeArgument,
  required DartType typeParameterBound,
  required String typeParameterName,
  required DartType receiverType,
  required String targetName,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var typeArgument_0 = labeler.labelType(typeArgument);
  var typeParameterBound_0 = labeler.labelType(typeParameterBound);
  var typeParameterName_0 = conversions.validateAndDemangleName(
    typeParameterName,
  );
  var receiverType_0 = labeler.labelType(receiverType);
  var targetName_0 = conversions.validateAndDemangleName(targetName);
  return new Message(
    incorrectTypeArgumentQualifiedInferred,
    problemMessage:
        """Inferred type argument '${typeArgument_0}' doesn't conform to the bound '${typeParameterBound_0}' of the type variable '${typeParameterName_0}' on '${receiverType_0}.${targetName_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try specifying type arguments explicitly so that they conform to the bounds.""",
    arguments: {
      'typeArgument': typeArgument,
      'typeParameterBound': typeParameterBound,
      'typeParameterName': typeParameterName,
      'receiverType': receiverType,
      'targetName': targetName,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode incorrectTypeArgumentVariable = const MessageCode(
  "IncorrectTypeArgumentVariable",
  severity: CfeSeverity.context,
  problemMessage:
      """This is the type variable whose bound isn't conformed to.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String parameterName})>
incrementalCompilerIllegalParameter = const Template(
  "IncrementalCompilerIllegalParameter",
  withArguments: _withArgumentsIncrementalCompilerIllegalParameter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIncrementalCompilerIllegalParameter({
  required String parameterName,
}) {
  var parameterName_0 = conversions.validateString(parameterName);
  return new Message(
    incrementalCompilerIllegalParameter,
    problemMessage:
        """Illegal parameter name '${parameterName_0}' found during expression compilation.""",
    arguments: {'parameterName': parameterName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String typeParameterName})>
incrementalCompilerIllegalTypeParameter = const Template(
  "IncrementalCompilerIllegalTypeParameter",
  withArguments: _withArgumentsIncrementalCompilerIllegalTypeParameter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIncrementalCompilerIllegalTypeParameter({
  required String typeParameterName,
}) {
  var typeParameterName_0 = conversions.validateString(typeParameterName);
  return new Message(
    incrementalCompilerIllegalTypeParameter,
    problemMessage:
        """Illegal type parameter name '${typeParameterName_0}' found during expression compilation.""",
    arguments: {'typeParameterName': typeParameterName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required int index,
    required int positionalFieldCount,
    required DartType recordType,
  })
>
indexOutOfBoundInRecordIndexGet = const Template(
  "IndexOutOfBoundInRecordIndexGet",
  withArguments: _withArgumentsIndexOutOfBoundInRecordIndexGet,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIndexOutOfBoundInRecordIndexGet({
  required int index,
  required int positionalFieldCount,
  required DartType recordType,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var recordType_0 = labeler.labelType(recordType);
  return new Message(
    indexOutOfBoundInRecordIndexGet,
    problemMessage:
        """Index ${index} is out of range 0..${positionalFieldCount} of positional fields of records ${recordType_0}.""" +
        labeler.originMessages,
    arguments: {
      'index': index,
      'positionalFieldCount': positionalFieldCount,
      'recordType': recordType,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode inheritedMembersConflict = const MessageCode(
  "InheritedMembersConflict",
  problemMessage: """Can't inherit members that conflict with each other.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode inheritedMembersConflictCause1 = const MessageCode(
  "InheritedMembersConflictCause1",
  severity: CfeSeverity.context,
  problemMessage: """This is one inherited member.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode inheritedMembersConflictCause2 = const MessageCode(
  "InheritedMembersConflictCause2",
  severity: CfeSeverity.context,
  problemMessage: """This is the other inherited member.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String memberName, required String superclassName})
>
inheritedRestrictedMemberOfEnumImplementer = const Template(
  "InheritedRestrictedMemberOfEnumImplementer",
  withArguments: _withArgumentsInheritedRestrictedMemberOfEnumImplementer,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInheritedRestrictedMemberOfEnumImplementer({
  required String memberName,
  required String superclassName,
}) {
  var memberName_0 = conversions.validateAndDemangleName(memberName);
  var superclassName_0 = conversions.validateAndDemangleName(superclassName);
  return new Message(
    inheritedRestrictedMemberOfEnumImplementer,
    problemMessage:
        """A concrete instance member named '${memberName_0}' can't be inherited from '${superclassName_0}' in a class that implements 'Enum'.""",
    arguments: {'memberName': memberName, 'superclassName': superclassName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String previousCompilationUri,
    required Uri gzFileUri,
  })
>
initializeFromDillNotSelfContained = const Template(
  "InitializeFromDillNotSelfContained",
  withArguments: _withArgumentsInitializeFromDillNotSelfContained,
  severity: CfeSeverity.warning,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInitializeFromDillNotSelfContained({
  required String previousCompilationUri,
  required Uri gzFileUri,
}) {
  var previousCompilationUri_0 = conversions.validateString(
    previousCompilationUri,
  );
  var gzFileUri_0 = conversions.relativizeUri(gzFileUri);
  return new Message(
    initializeFromDillNotSelfContained,
    problemMessage:
        """Tried to initialize from a previous compilation (${previousCompilationUri_0}), but the file was not self-contained. This might be a bug.

The Dart team would greatly appreciate it if you would take a moment to report this problem at http://dartbug.com/new.
If you are comfortable with it, it would improve the chances of fixing any bug if you included the file ${gzFileUri_0} in your error report, but be aware that this file includes your source code.
Either way, you should probably delete the file so it doesn't use unnecessary disk space.""",
    arguments: {
      'previousCompilationUri': previousCompilationUri,
      'gzFileUri': gzFileUri,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String previousCompilationUri})>
initializeFromDillNotSelfContainedNoDump = const Template(
  "InitializeFromDillNotSelfContainedNoDump",
  withArguments: _withArgumentsInitializeFromDillNotSelfContainedNoDump,
  severity: CfeSeverity.warning,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInitializeFromDillNotSelfContainedNoDump({
  required String previousCompilationUri,
}) {
  var previousCompilationUri_0 = conversions.validateString(
    previousCompilationUri,
  );
  return new Message(
    initializeFromDillNotSelfContainedNoDump,
    problemMessage:
        """Tried to initialize from a previous compilation (${previousCompilationUri_0}), but the file was not self-contained. This might be a bug.

The Dart team would greatly appreciate it if you would take a moment to report this problem at http://dartbug.com/new.""",
    arguments: {'previousCompilationUri': previousCompilationUri},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String previousCompilationUri,
    required String exception,
    required String stackTrace,
    required Uri gzFileUri,
  })
>
initializeFromDillUnknownProblem = const Template(
  "InitializeFromDillUnknownProblem",
  withArguments: _withArgumentsInitializeFromDillUnknownProblem,
  severity: CfeSeverity.warning,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInitializeFromDillUnknownProblem({
  required String previousCompilationUri,
  required String exception,
  required String stackTrace,
  required Uri gzFileUri,
}) {
  var previousCompilationUri_0 = conversions.validateString(
    previousCompilationUri,
  );
  var exception_0 = conversions.validateString(exception);
  var stackTrace_0 = conversions.validateString(stackTrace);
  var gzFileUri_0 = conversions.relativizeUri(gzFileUri);
  return new Message(
    initializeFromDillUnknownProblem,
    problemMessage:
        """Tried to initialize from a previous compilation (${previousCompilationUri_0}), but couldn't.
Error message was '${exception_0}'.
Stacktrace included '${stackTrace_0}'.
This might be a bug.

The Dart team would greatly appreciate it if you would take a moment to report this problem at http://dartbug.com/new.
If you are comfortable with it, it would improve the chances of fixing any bug if you included the file ${gzFileUri_0} in your error report, but be aware that this file includes your source code.
Either way, you should probably delete the file so it doesn't use unnecessary disk space.""",
    arguments: {
      'previousCompilationUri': previousCompilationUri,
      'exception': exception,
      'stackTrace': stackTrace,
      'gzFileUri': gzFileUri,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String previousCompilationUri,
    required String exception,
    required String stackTrace,
  })
>
initializeFromDillUnknownProblemNoDump = const Template(
  "InitializeFromDillUnknownProblemNoDump",
  withArguments: _withArgumentsInitializeFromDillUnknownProblemNoDump,
  severity: CfeSeverity.warning,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInitializeFromDillUnknownProblemNoDump({
  required String previousCompilationUri,
  required String exception,
  required String stackTrace,
}) {
  var previousCompilationUri_0 = conversions.validateString(
    previousCompilationUri,
  );
  var exception_0 = conversions.validateString(exception);
  var stackTrace_0 = conversions.validateString(stackTrace);
  return new Message(
    initializeFromDillUnknownProblemNoDump,
    problemMessage:
        """Tried to initialize from a previous compilation (${previousCompilationUri_0}), but couldn't.
Error message was '${exception_0}'.
Stacktrace included '${stackTrace_0}'.
This might be a bug.

The Dart team would greatly appreciate it if you would take a moment to report this problem at http://dartbug.com/new.""",
    arguments: {
      'previousCompilationUri': previousCompilationUri,
      'exception': exception,
      'stackTrace': stackTrace,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String fieldName})>
initializerForStaticField = const Template(
  "InitializerForStaticField",
  withArguments: _withArgumentsInitializerForStaticField,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInitializerForStaticField({required String fieldName}) {
  var fieldName_0 = conversions.validateAndDemangleName(fieldName);
  return new Message(
    initializerForStaticField,
    problemMessage:
        """'${fieldName_0}' isn't an instance field of this class.""",
    arguments: {'fieldName': fieldName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String parameterName,
    required DartType parameterType,
    required DartType fieldType,
  })
>
initializingFormalTypeMismatch = const Template(
  "InitializingFormalTypeMismatch",
  withArguments: _withArgumentsInitializingFormalTypeMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInitializingFormalTypeMismatch({
  required String parameterName,
  required DartType parameterType,
  required DartType fieldType,
}) {
  var parameterName_0 = conversions.validateAndDemangleName(parameterName);
  TypeLabeler labeler = new TypeLabeler();
  var parameterType_0 = labeler.labelType(parameterType);
  var fieldType_0 = labeler.labelType(fieldType);
  return new Message(
    initializingFormalTypeMismatch,
    problemMessage:
        """The type of parameter '${parameterName_0}', '${parameterType_0}' is not a subtype of the corresponding field's type, '${fieldType_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try changing the type of parameter '${parameterName_0}' to a subtype of '${fieldType_0}'.""",
    arguments: {
      'parameterName': parameterName,
      'parameterType': parameterType,
      'fieldType': fieldType,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode initializingFormalTypeMismatchField = const MessageCode(
  "InitializingFormalTypeMismatchField",
  severity: CfeSeverity.context,
  problemMessage: """The field that corresponds to the parameter.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required Uri uri})> inputFileNotFound =
    const Template(
      "InputFileNotFound",
      withArguments: _withArgumentsInputFileNotFound,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInputFileNotFound({required Uri uri}) {
  var uri_0 = conversions.relativizeUri(uri);
  return new Message(
    inputFileNotFound,
    problemMessage: """Input file not found: ${uri_0}.""",
    arguments: {'uri': uri},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name})>
instanceAndSynthesizedStaticConflict = const Template(
  "InstanceAndSynthesizedStaticConflict",
  withArguments: _withArgumentsInstanceAndSynthesizedStaticConflict,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInstanceAndSynthesizedStaticConflict({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    instanceAndSynthesizedStaticConflict,
    problemMessage:
        """This instance member conflicts with the synthesized static member called '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String propertyName})>
instanceConflictsWithStatic = const Template(
  "InstanceConflictsWithStatic",
  withArguments: _withArgumentsInstanceConflictsWithStatic,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInstanceConflictsWithStatic({
  required String propertyName,
}) {
  var propertyName_0 = conversions.validateAndDemangleName(propertyName);
  return new Message(
    instanceConflictsWithStatic,
    problemMessage:
        """Instance property '${propertyName_0}' conflicts with static property of the same name.""",
    arguments: {'propertyName': propertyName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String propertyName})>
instanceConflictsWithStaticCause = const Template(
  "InstanceConflictsWithStaticCause",
  withArguments: _withArgumentsInstanceConflictsWithStaticCause,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInstanceConflictsWithStaticCause({
  required String propertyName,
}) {
  var propertyName_0 = conversions.validateAndDemangleName(propertyName);
  return new Message(
    instanceConflictsWithStaticCause,
    problemMessage: """Conflicting static property '${propertyName_0}'.""",
    arguments: {'propertyName': propertyName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required DartType operandType})>
instantiationNonGenericFunctionType = const Template(
  "InstantiationNonGenericFunctionType",
  withArguments: _withArgumentsInstantiationNonGenericFunctionType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInstantiationNonGenericFunctionType({
  required DartType operandType,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var operandType_0 = labeler.labelType(operandType);
  return new Message(
    instantiationNonGenericFunctionType,
    problemMessage:
        """The static type of the explicit instantiation operand must be a generic function type but is '${operandType_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try changing the operand or remove the type arguments.""",
    arguments: {'operandType': operandType},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required DartType operandType})>
instantiationNullableGenericFunctionType = const Template(
  "InstantiationNullableGenericFunctionType",
  withArguments: _withArgumentsInstantiationNullableGenericFunctionType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInstantiationNullableGenericFunctionType({
  required DartType operandType,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var operandType_0 = labeler.labelType(operandType);
  return new Message(
    instantiationNullableGenericFunctionType,
    problemMessage:
        """The static type of the explicit instantiation operand must be a non-null generic function type but is '${operandType_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try changing the operand or remove the type arguments.""",
    arguments: {'operandType': operandType},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required int expectedCount, required int actualCount})
>
instantiationTooFewArguments = const Template(
  "InstantiationTooFewArguments",
  withArguments: _withArgumentsInstantiationTooFewArguments,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInstantiationTooFewArguments({
  required int expectedCount,
  required int actualCount,
}) {
  return new Message(
    instantiationTooFewArguments,
    problemMessage:
        """Too few type arguments: ${expectedCount} required, ${actualCount} given.""",
    correctionMessage: """Try adding the missing type arguments.""",
    arguments: {'expectedCount': expectedCount, 'actualCount': actualCount},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required int expectedCount, required int actualCount})
>
instantiationTooManyArguments = const Template(
  "InstantiationTooManyArguments",
  withArguments: _withArgumentsInstantiationTooManyArguments,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInstantiationTooManyArguments({
  required int expectedCount,
  required int actualCount,
}) {
  return new Message(
    instantiationTooManyArguments,
    problemMessage:
        """Too many type arguments: ${expectedCount} allowed, but ${actualCount} found.""",
    correctionMessage: """Try removing the extra type arguments.""",
    arguments: {'expectedCount': expectedCount, 'actualCount': actualCount},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String literal})>
integerLiteralIsOutOfRange = const Template(
  "IntegerLiteralIsOutOfRange",
  withArguments: _withArgumentsIntegerLiteralIsOutOfRange,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIntegerLiteralIsOutOfRange({required String literal}) {
  var literal_0 = conversions.validateString(literal);
  return new Message(
    integerLiteralIsOutOfRange,
    problemMessage:
        """The integer literal ${literal_0} can't be represented in 64 bits.""",
    correctionMessage:
        """Try using the BigInt class if you need an integer larger than 9,223,372,036,854,775,807 or less than -9,223,372,036,854,775,808.""",
    arguments: {'literal': literal},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String memberName, required String className})
>
interfaceCheck = const Template(
  "InterfaceCheck",
  withArguments: _withArgumentsInterfaceCheck,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInterfaceCheck({
  required String memberName,
  required String className,
}) {
  var memberName_0 = conversions.validateAndDemangleName(memberName);
  var className_0 = conversions.validateAndDemangleName(className);
  return new Message(
    interfaceCheck,
    problemMessage:
        """The implementation of '${memberName_0}' in the non-abstract class '${className_0}' does not conform to its interface.""",
    arguments: {'memberName': memberName, 'className': className},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String interfaceClassName})>
interfaceClassExtendedOutsideOfLibrary = const Template(
  "InterfaceClassExtendedOutsideOfLibrary",
  withArguments: _withArgumentsInterfaceClassExtendedOutsideOfLibrary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInterfaceClassExtendedOutsideOfLibrary({
  required String interfaceClassName,
}) {
  var interfaceClassName_0 = conversions.validateAndDemangleName(
    interfaceClassName,
  );
  return new Message(
    interfaceClassExtendedOutsideOfLibrary,
    problemMessage:
        """The class '${interfaceClassName_0}' can't be extended outside of its library because it's an interface class.""",
    arguments: {'interfaceClassName': interfaceClassName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode internalProblemAlreadyInitialized = const MessageCode(
  "InternalProblemAlreadyInitialized",
  severity: CfeSeverity.internalProblem,
  problemMessage:
      """Attempt to set initializer on field without initializer.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode internalProblemBodyOnAbstractMethod = const MessageCode(
  "InternalProblemBodyOnAbstractMethod",
  severity: CfeSeverity.internalProblem,
  problemMessage: """Attempting to set body on abstract method.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name, required Uri uri})>
internalProblemConstructorNotFound = const Template(
  "InternalProblemConstructorNotFound",
  withArguments: _withArgumentsInternalProblemConstructorNotFound,
  severity: CfeSeverity.internalProblem,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemConstructorNotFound({
  required String name,
  required Uri uri,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var uri_0 = conversions.relativizeUri(uri);
  return new Message(
    internalProblemConstructorNotFound,
    problemMessage: """No constructor named '${name_0}' in '${uri_0}'.""",
    arguments: {'name': name, 'uri': uri},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String messageCode})>
internalProblemContextSeverity = const Template(
  "InternalProblemContextSeverity",
  withArguments: _withArgumentsInternalProblemContextSeverity,
  severity: CfeSeverity.internalProblem,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemContextSeverity({
  required String messageCode,
}) {
  var messageCode_0 = conversions.validateString(messageCode);
  return new Message(
    internalProblemContextSeverity,
    problemMessage:
        """Non-context message has context severity: ${messageCode_0}""",
    arguments: {'messageCode': messageCode},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String severityName, required String stackTrace})
>
internalProblemDebugAbort = const Template(
  "InternalProblemDebugAbort",
  withArguments: _withArgumentsInternalProblemDebugAbort,
  severity: CfeSeverity.internalProblem,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemDebugAbort({
  required String severityName,
  required String stackTrace,
}) {
  var severityName_0 = conversions.validateAndDemangleName(severityName);
  var stackTrace_0 = conversions.validateString(stackTrace);
  return new Message(
    internalProblemDebugAbort,
    problemMessage: """Compilation aborted due to fatal '${severityName_0}' at:
${stackTrace_0}""",
    arguments: {'severityName': severityName, 'stackTrace': stackTrace},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode internalProblemExtendingUnmodifiableScope = const MessageCode(
  "InternalProblemExtendingUnmodifiableScope",
  severity: CfeSeverity.internalProblem,
  problemMessage: """Can't extend an unmodifiable scope.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode internalProblemLabelUsageInVariablesDeclaration =
    const MessageCode(
      "InternalProblemLabelUsageInVariablesDeclaration",
      severity: CfeSeverity.internalProblem,
      problemMessage:
          """Unexpected usage of label inside declaration of variables.""",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode internalProblemMissingContext = const MessageCode(
  "InternalProblemMissingContext",
  severity: CfeSeverity.internalProblem,
  problemMessage: """Compiler cannot run without a compiler context.""",
  correctionMessage:
      """Are calls to the compiler wrapped in CompilerContext.runInContext?""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name})>
internalProblemNotFound = const Template(
  "InternalProblemNotFound",
  withArguments: _withArgumentsInternalProblemNotFound,
  severity: CfeSeverity.internalProblem,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemNotFound({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    internalProblemNotFound,
    problemMessage: """Couldn't find '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name, required String within})>
internalProblemNotFoundIn = const Template(
  "InternalProblemNotFoundIn",
  withArguments: _withArgumentsInternalProblemNotFoundIn,
  severity: CfeSeverity.internalProblem,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemNotFoundIn({
  required String name,
  required String within,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var within_0 = conversions.validateAndDemangleName(within);
  return new Message(
    internalProblemNotFoundIn,
    problemMessage: """Couldn't find '${name_0}' in '${within_0}'.""",
    arguments: {'name': name, 'within': within},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
internalProblemOmittedTypeNameInConstructorReference = const MessageCode(
  "InternalProblemOmittedTypeNameInConstructorReference",
  severity: CfeSeverity.internalProblem,
  problemMessage:
      """Unsupported omission of the type name in a constructor reference outside of an enum element declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode internalProblemPreviousTokenNotFound = const MessageCode(
  "InternalProblemPreviousTokenNotFound",
  severity: CfeSeverity.internalProblem,
  problemMessage: """Couldn't find previous token.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name})>
internalProblemPrivateConstructorAccess = const Template(
  "InternalProblemPrivateConstructorAccess",
  withArguments: _withArgumentsInternalProblemPrivateConstructorAccess,
  severity: CfeSeverity.internalProblem,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemPrivateConstructorAccess({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    internalProblemPrivateConstructorAccess,
    problemMessage: """Can't access private constructor '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode internalProblemProvidedBothCompileSdkAndSdkSummary =
    const MessageCode(
      "InternalProblemProvidedBothCompileSdkAndSdkSummary",
      severity: CfeSeverity.internalProblem,
      problemMessage:
          """The compileSdk and sdkSummary options are mutually exclusive""",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String expected, required String actual})
>
internalProblemUnexpected = const Template(
  "InternalProblemUnexpected",
  withArguments: _withArgumentsInternalProblemUnexpected,
  severity: CfeSeverity.internalProblem,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemUnexpected({
  required String expected,
  required String actual,
}) {
  var expected_0 = conversions.validateString(expected);
  var actual_0 = conversions.validateString(actual);
  return new Message(
    internalProblemUnexpected,
    problemMessage: """Expected '${expected_0}', but got '${actual_0}'.""",
    arguments: {'expected': expected, 'actual': actual},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String what})>
internalProblemUnimplemented = const Template(
  "InternalProblemUnimplemented",
  withArguments: _withArgumentsInternalProblemUnimplemented,
  severity: CfeSeverity.internalProblem,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemUnimplemented({required String what}) {
  var what_0 = conversions.validateString(what);
  return new Message(
    internalProblemUnimplemented,
    problemMessage: """Unimplemented ${what_0}.""",
    arguments: {'what': what},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String nullability, required DartType type})
>
internalProblemUnsupportedNullability = const Template(
  "InternalProblemUnsupportedNullability",
  withArguments: _withArgumentsInternalProblemUnsupportedNullability,
  severity: CfeSeverity.internalProblem,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemUnsupportedNullability({
  required String nullability,
  required DartType type,
}) {
  var nullability_0 = conversions.validateString(nullability);
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    internalProblemUnsupportedNullability,
    problemMessage:
        """Unsupported nullability value '${nullability_0}' on type '${type_0}'.""" +
        labeler.originMessages,
    arguments: {'nullability': nullability, 'type': type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required Uri uri})>
internalProblemUriMissingScheme = const Template(
  "InternalProblemUriMissingScheme",
  withArguments: _withArgumentsInternalProblemUriMissingScheme,
  severity: CfeSeverity.internalProblem,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemUriMissingScheme({required Uri uri}) {
  var uri_0 = conversions.relativizeUri(uri);
  return new Message(
    internalProblemUriMissingScheme,
    problemMessage: """The URI '${uri_0}' has no scheme.""",
    arguments: {'uri': uri},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String details})>
internalProblemVerificationError = const Template(
  "InternalProblemVerificationError",
  withArguments: _withArgumentsInternalProblemVerificationError,
  severity: CfeSeverity.internalProblem,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemVerificationError({
  required String details,
}) {
  var details_0 = conversions.validateString(details);
  return new Message(
    internalProblemVerificationError,
    problemMessage: """Verification of the generated program failed:
${details_0}""",
    arguments: {'details': details},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required DartType actualType,
    required DartType expectedType,
  })
>
invalidAssignmentError = const Template(
  "InvalidAssignmentError",
  withArguments: _withArgumentsInvalidAssignmentError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidAssignmentError({
  required DartType actualType,
  required DartType expectedType,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var actualType_0 = labeler.labelType(actualType);
  var expectedType_0 = labeler.labelType(expectedType);
  return new Message(
    invalidAssignmentError,
    problemMessage:
        """A value of type '${actualType_0}' can't be assigned to a variable of type '${expectedType_0}'.""" +
        labeler.originMessages,
    arguments: {'actualType': actualType, 'expectedType': expectedType},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode invalidAugmentSuper = const MessageCode(
  "InvalidAugmentSuper",
  problemMessage:
      """'augment super' is only allowed in member augmentations.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String label})> invalidBreakTarget =
    const Template(
      "InvalidBreakTarget",
      withArguments: _withArgumentsInvalidBreakTarget,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidBreakTarget({required String label}) {
  var label_0 = conversions.validateAndDemangleName(label);
  return new Message(
    invalidBreakTarget,
    problemMessage: """Can't break to '${label_0}'.""",
    arguments: {'label': label},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required DartType actualType,
    required DartType expectedType,
  })
>
invalidCastFunctionExpr = const Template(
  "InvalidCastFunctionExpr",
  withArguments: _withArgumentsInvalidCastFunctionExpr,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidCastFunctionExpr({
  required DartType actualType,
  required DartType expectedType,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var actualType_0 = labeler.labelType(actualType);
  var expectedType_0 = labeler.labelType(expectedType);
  return new Message(
    invalidCastFunctionExpr,
    problemMessage:
        """The function expression type '${actualType_0}' isn't of expected type '${expectedType_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Change the type of the function expression or the context in which it is used.""",
    arguments: {'actualType': actualType, 'expectedType': expectedType},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required DartType actualType,
    required DartType expectedType,
  })
>
invalidCastLiteralList = const Template(
  "InvalidCastLiteralList",
  withArguments: _withArgumentsInvalidCastLiteralList,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidCastLiteralList({
  required DartType actualType,
  required DartType expectedType,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var actualType_0 = labeler.labelType(actualType);
  var expectedType_0 = labeler.labelType(expectedType);
  return new Message(
    invalidCastLiteralList,
    problemMessage:
        """The list literal type '${actualType_0}' isn't of expected type '${expectedType_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Change the type of the list literal or the context in which it is used.""",
    arguments: {'actualType': actualType, 'expectedType': expectedType},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required DartType actualType,
    required DartType expectedType,
  })
>
invalidCastLiteralMap = const Template(
  "InvalidCastLiteralMap",
  withArguments: _withArgumentsInvalidCastLiteralMap,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidCastLiteralMap({
  required DartType actualType,
  required DartType expectedType,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var actualType_0 = labeler.labelType(actualType);
  var expectedType_0 = labeler.labelType(expectedType);
  return new Message(
    invalidCastLiteralMap,
    problemMessage:
        """The map literal type '${actualType_0}' isn't of expected type '${expectedType_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Change the type of the map literal or the context in which it is used.""",
    arguments: {'actualType': actualType, 'expectedType': expectedType},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required DartType actualType,
    required DartType expectedType,
  })
>
invalidCastLiteralSet = const Template(
  "InvalidCastLiteralSet",
  withArguments: _withArgumentsInvalidCastLiteralSet,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidCastLiteralSet({
  required DartType actualType,
  required DartType expectedType,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var actualType_0 = labeler.labelType(actualType);
  var expectedType_0 = labeler.labelType(expectedType);
  return new Message(
    invalidCastLiteralSet,
    problemMessage:
        """The set literal type '${actualType_0}' isn't of expected type '${expectedType_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Change the type of the set literal or the context in which it is used.""",
    arguments: {'actualType': actualType, 'expectedType': expectedType},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required DartType actualType,
    required DartType expectedType,
  })
>
invalidCastLocalFunction = const Template(
  "InvalidCastLocalFunction",
  withArguments: _withArgumentsInvalidCastLocalFunction,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidCastLocalFunction({
  required DartType actualType,
  required DartType expectedType,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var actualType_0 = labeler.labelType(actualType);
  var expectedType_0 = labeler.labelType(expectedType);
  return new Message(
    invalidCastLocalFunction,
    problemMessage:
        """The local function has type '${actualType_0}' that isn't of expected type '${expectedType_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Change the type of the function or the context in which it is used.""",
    arguments: {'actualType': actualType, 'expectedType': expectedType},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required DartType actualType,
    required DartType expectedType,
  })
>
invalidCastNewExpr = const Template(
  "InvalidCastNewExpr",
  withArguments: _withArgumentsInvalidCastNewExpr,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidCastNewExpr({
  required DartType actualType,
  required DartType expectedType,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var actualType_0 = labeler.labelType(actualType);
  var expectedType_0 = labeler.labelType(expectedType);
  return new Message(
    invalidCastNewExpr,
    problemMessage:
        """The constructor returns type '${actualType_0}' that isn't of expected type '${expectedType_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Change the type of the object being constructed or the context in which it is used.""",
    arguments: {'actualType': actualType, 'expectedType': expectedType},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required DartType actualType,
    required DartType expectedType,
  })
>
invalidCastStaticMethod = const Template(
  "InvalidCastStaticMethod",
  withArguments: _withArgumentsInvalidCastStaticMethod,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidCastStaticMethod({
  required DartType actualType,
  required DartType expectedType,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var actualType_0 = labeler.labelType(actualType);
  var expectedType_0 = labeler.labelType(expectedType);
  return new Message(
    invalidCastStaticMethod,
    problemMessage:
        """The static method has type '${actualType_0}' that isn't of expected type '${expectedType_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Change the type of the method or the context in which it is used.""",
    arguments: {'actualType': actualType, 'expectedType': expectedType},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required DartType actualType,
    required DartType expectedType,
  })
>
invalidCastTopLevelFunction = const Template(
  "InvalidCastTopLevelFunction",
  withArguments: _withArgumentsInvalidCastTopLevelFunction,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidCastTopLevelFunction({
  required DartType actualType,
  required DartType expectedType,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var actualType_0 = labeler.labelType(actualType);
  var expectedType_0 = labeler.labelType(expectedType);
  return new Message(
    invalidCastTopLevelFunction,
    problemMessage:
        """The top level function has type '${actualType_0}' that isn't of expected type '${expectedType_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Change the type of the function or the context in which it is used.""",
    arguments: {'actualType': actualType, 'expectedType': expectedType},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String label})>
invalidContinueTarget = const Template(
  "InvalidContinueTarget",
  withArguments: _withArgumentsInvalidContinueTarget,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidContinueTarget({required String label}) {
  var label_0 = conversions.validateAndDemangleName(label);
  return new Message(
    invalidContinueTarget,
    problemMessage: """Can't continue at '${label_0}'.""",
    arguments: {'label': label},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required DartType representationType,
    required String extensionTypeName,
    required DartType implementedExtensionRepresentationType,
    required DartType implementedExtensionType,
  })
>
invalidExtensionTypeSuperExtensionType = const Template(
  "InvalidExtensionTypeSuperExtensionType",
  withArguments: _withArgumentsInvalidExtensionTypeSuperExtensionType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidExtensionTypeSuperExtensionType({
  required DartType representationType,
  required String extensionTypeName,
  required DartType implementedExtensionRepresentationType,
  required DartType implementedExtensionType,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var representationType_0 = labeler.labelType(representationType);
  var extensionTypeName_0 = conversions.validateAndDemangleName(
    extensionTypeName,
  );
  var implementedExtensionRepresentationType_0 = labeler.labelType(
    implementedExtensionRepresentationType,
  );
  var implementedExtensionType_0 = labeler.labelType(implementedExtensionType);
  return new Message(
    invalidExtensionTypeSuperExtensionType,
    problemMessage:
        """The representation type '${representationType_0}' of extension type '${extensionTypeName_0}' must be either a subtype of the representation type '${implementedExtensionRepresentationType_0}' of the implemented extension type '${implementedExtensionType_0}' or a subtype of '${implementedExtensionType_0}' itself.""" +
        labeler.originMessages,
    correctionMessage:
        """Try changing the representation type to a subtype of '${implementedExtensionRepresentationType_0}'.""",
    arguments: {
      'representationType': representationType,
      'extensionTypeName': extensionTypeName,
      'implementedExtensionRepresentationType':
          implementedExtensionRepresentationType,
      'implementedExtensionType': implementedExtensionType,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required DartType interfaceType,
    required DartType representationType,
    required String extensionTypeName,
  })
>
invalidExtensionTypeSuperInterface = const Template(
  "InvalidExtensionTypeSuperInterface",
  withArguments: _withArgumentsInvalidExtensionTypeSuperInterface,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidExtensionTypeSuperInterface({
  required DartType interfaceType,
  required DartType representationType,
  required String extensionTypeName,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var interfaceType_0 = labeler.labelType(interfaceType);
  var representationType_0 = labeler.labelType(representationType);
  var extensionTypeName_0 = conversions.validateAndDemangleName(
    extensionTypeName,
  );
  return new Message(
    invalidExtensionTypeSuperInterface,
    problemMessage:
        """The implemented interface '${interfaceType_0}' must be a supertype of the representation type '${representationType_0}' of extension type '${extensionTypeName_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try changing the interface type to a supertype of '${representationType_0}' or the representation type to a subtype of '${interfaceType_0}'.""",
    arguments: {
      'interfaceType': interfaceType,
      'representationType': representationType,
      'extensionTypeName': extensionTypeName,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required DartType getterType,
    required String getterName,
    required DartType setterType,
    required String setterName,
  })
>
invalidGetterSetterType = const Template(
  "InvalidGetterSetterType",
  withArguments: _withArgumentsInvalidGetterSetterType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidGetterSetterType({
  required DartType getterType,
  required String getterName,
  required DartType setterType,
  required String setterName,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var getterType_0 = labeler.labelType(getterType);
  var getterName_0 = conversions.validateAndDemangleName(getterName);
  var setterType_0 = labeler.labelType(setterType);
  var setterName_0 = conversions.validateAndDemangleName(setterName);
  return new Message(
    invalidGetterSetterType,
    problemMessage:
        """The type '${getterType_0}' of the getter '${getterName_0}' is not a subtype of the type '${setterType_0}' of the setter '${setterName_0}'.""" +
        labeler.originMessages,
    arguments: {
      'getterType': getterType,
      'getterName': getterName,
      'setterType': setterType,
      'setterName': setterName,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required DartType getterType,
    required String getterName,
    required DartType setterType,
    required String setterName,
  })
>
invalidGetterSetterTypeBothInheritedField = const Template(
  "InvalidGetterSetterTypeBothInheritedField",
  withArguments: _withArgumentsInvalidGetterSetterTypeBothInheritedField,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidGetterSetterTypeBothInheritedField({
  required DartType getterType,
  required String getterName,
  required DartType setterType,
  required String setterName,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var getterType_0 = labeler.labelType(getterType);
  var getterName_0 = conversions.validateAndDemangleName(getterName);
  var setterType_0 = labeler.labelType(setterType);
  var setterName_0 = conversions.validateAndDemangleName(setterName);
  return new Message(
    invalidGetterSetterTypeBothInheritedField,
    problemMessage:
        """The type '${getterType_0}' of the inherited field '${getterName_0}' is not a subtype of the type '${setterType_0}' of the inherited setter '${setterName_0}'.""" +
        labeler.originMessages,
    arguments: {
      'getterType': getterType,
      'getterName': getterName,
      'setterType': setterType,
      'setterName': setterName,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required DartType getterType,
    required String getterName,
    required DartType setterType,
    required String setterName,
  })
>
invalidGetterSetterTypeBothInheritedGetter = const Template(
  "InvalidGetterSetterTypeBothInheritedGetter",
  withArguments: _withArgumentsInvalidGetterSetterTypeBothInheritedGetter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidGetterSetterTypeBothInheritedGetter({
  required DartType getterType,
  required String getterName,
  required DartType setterType,
  required String setterName,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var getterType_0 = labeler.labelType(getterType);
  var getterName_0 = conversions.validateAndDemangleName(getterName);
  var setterType_0 = labeler.labelType(setterType);
  var setterName_0 = conversions.validateAndDemangleName(setterName);
  return new Message(
    invalidGetterSetterTypeBothInheritedGetter,
    problemMessage:
        """The type '${getterType_0}' of the inherited getter '${getterName_0}' is not a subtype of the type '${setterType_0}' of the inherited setter '${setterName_0}'.""" +
        labeler.originMessages,
    arguments: {
      'getterType': getterType,
      'getterName': getterName,
      'setterType': setterType,
      'setterName': setterName,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String getterName})>
invalidGetterSetterTypeFieldContext = const Template(
  "InvalidGetterSetterTypeFieldContext",
  withArguments: _withArgumentsInvalidGetterSetterTypeFieldContext,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidGetterSetterTypeFieldContext({
  required String getterName,
}) {
  var getterName_0 = conversions.validateAndDemangleName(getterName);
  return new Message(
    invalidGetterSetterTypeFieldContext,
    problemMessage:
        """This is the declaration of the field '${getterName_0}'.""",
    arguments: {'getterName': getterName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required DartType getterType,
    required String getterName,
    required DartType setterType,
    required String setterName,
  })
>
invalidGetterSetterTypeFieldInherited = const Template(
  "InvalidGetterSetterTypeFieldInherited",
  withArguments: _withArgumentsInvalidGetterSetterTypeFieldInherited,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidGetterSetterTypeFieldInherited({
  required DartType getterType,
  required String getterName,
  required DartType setterType,
  required String setterName,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var getterType_0 = labeler.labelType(getterType);
  var getterName_0 = conversions.validateAndDemangleName(getterName);
  var setterType_0 = labeler.labelType(setterType);
  var setterName_0 = conversions.validateAndDemangleName(setterName);
  return new Message(
    invalidGetterSetterTypeFieldInherited,
    problemMessage:
        """The type '${getterType_0}' of the inherited field '${getterName_0}' is not a subtype of the type '${setterType_0}' of the setter '${setterName_0}'.""" +
        labeler.originMessages,
    arguments: {
      'getterType': getterType,
      'getterName': getterName,
      'setterType': setterType,
      'setterName': setterName,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String getterName})>
invalidGetterSetterTypeGetterContext = const Template(
  "InvalidGetterSetterTypeGetterContext",
  withArguments: _withArgumentsInvalidGetterSetterTypeGetterContext,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidGetterSetterTypeGetterContext({
  required String getterName,
}) {
  var getterName_0 = conversions.validateAndDemangleName(getterName);
  return new Message(
    invalidGetterSetterTypeGetterContext,
    problemMessage:
        """This is the declaration of the getter '${getterName_0}'.""",
    arguments: {'getterName': getterName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required DartType getterType,
    required String getterName,
    required DartType setterType,
    required String setterName,
  })
>
invalidGetterSetterTypeGetterInherited = const Template(
  "InvalidGetterSetterTypeGetterInherited",
  withArguments: _withArgumentsInvalidGetterSetterTypeGetterInherited,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidGetterSetterTypeGetterInherited({
  required DartType getterType,
  required String getterName,
  required DartType setterType,
  required String setterName,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var getterType_0 = labeler.labelType(getterType);
  var getterName_0 = conversions.validateAndDemangleName(getterName);
  var setterType_0 = labeler.labelType(setterType);
  var setterName_0 = conversions.validateAndDemangleName(setterName);
  return new Message(
    invalidGetterSetterTypeGetterInherited,
    problemMessage:
        """The type '${getterType_0}' of the inherited getter '${getterName_0}' is not a subtype of the type '${setterType_0}' of the setter '${setterName_0}'.""" +
        labeler.originMessages,
    arguments: {
      'getterType': getterType,
      'getterName': getterName,
      'setterType': setterType,
      'setterName': setterName,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String setterName})>
invalidGetterSetterTypeSetterContext = const Template(
  "InvalidGetterSetterTypeSetterContext",
  withArguments: _withArgumentsInvalidGetterSetterTypeSetterContext,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidGetterSetterTypeSetterContext({
  required String setterName,
}) {
  var setterName_0 = conversions.validateAndDemangleName(setterName);
  return new Message(
    invalidGetterSetterTypeSetterContext,
    problemMessage:
        """This is the declaration of the setter '${setterName_0}'.""",
    arguments: {'setterName': setterName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required DartType getterType,
    required String getterName,
    required DartType setterType,
    required String setterName,
  })
>
invalidGetterSetterTypeSetterInheritedField = const Template(
  "InvalidGetterSetterTypeSetterInheritedField",
  withArguments: _withArgumentsInvalidGetterSetterTypeSetterInheritedField,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidGetterSetterTypeSetterInheritedField({
  required DartType getterType,
  required String getterName,
  required DartType setterType,
  required String setterName,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var getterType_0 = labeler.labelType(getterType);
  var getterName_0 = conversions.validateAndDemangleName(getterName);
  var setterType_0 = labeler.labelType(setterType);
  var setterName_0 = conversions.validateAndDemangleName(setterName);
  return new Message(
    invalidGetterSetterTypeSetterInheritedField,
    problemMessage:
        """The type '${getterType_0}' of the field '${getterName_0}' is not a subtype of the type '${setterType_0}' of the inherited setter '${setterName_0}'.""" +
        labeler.originMessages,
    arguments: {
      'getterType': getterType,
      'getterName': getterName,
      'setterType': setterType,
      'setterName': setterName,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required DartType getterType,
    required String getterName,
    required DartType setterType,
    required String setterName,
  })
>
invalidGetterSetterTypeSetterInheritedGetter = const Template(
  "InvalidGetterSetterTypeSetterInheritedGetter",
  withArguments: _withArgumentsInvalidGetterSetterTypeSetterInheritedGetter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidGetterSetterTypeSetterInheritedGetter({
  required DartType getterType,
  required String getterName,
  required DartType setterType,
  required String setterName,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var getterType_0 = labeler.labelType(getterType);
  var getterName_0 = conversions.validateAndDemangleName(getterName);
  var setterType_0 = labeler.labelType(setterType);
  var setterName_0 = conversions.validateAndDemangleName(setterName);
  return new Message(
    invalidGetterSetterTypeSetterInheritedGetter,
    problemMessage:
        """The type '${getterType_0}' of the getter '${getterName_0}' is not a subtype of the type '${setterType_0}' of the inherited setter '${setterName_0}'.""" +
        labeler.originMessages,
    arguments: {
      'getterType': getterType,
      'getterName': getterName,
      'setterType': setterType,
      'setterName': setterName,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required Uri uri, required String details})>
invalidPackageUri = const Template(
  "InvalidPackageUri",
  withArguments: _withArgumentsInvalidPackageUri,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidPackageUri({
  required Uri uri,
  required String details,
}) {
  var uri_0 = conversions.relativizeUri(uri);
  var details_0 = conversions.validateString(details);
  return new Message(
    invalidPackageUri,
    problemMessage: """Invalid package URI '${uri_0}':
  ${details_0}.""",
    arguments: {'uri': uri, 'details': details},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required DartType actualType,
    required DartType expectedType,
  })
>
invalidReturn = const Template(
  "InvalidReturn",
  withArguments: _withArgumentsInvalidReturn,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidReturn({
  required DartType actualType,
  required DartType expectedType,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var actualType_0 = labeler.labelType(actualType);
  var expectedType_0 = labeler.labelType(expectedType);
  return new Message(
    invalidReturn,
    problemMessage:
        """A value of type '${actualType_0}' can't be returned from a function with return type '${expectedType_0}'.""" +
        labeler.originMessages,
    arguments: {'actualType': actualType, 'expectedType': expectedType},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required DartType actualType,
    required DartType expectedType,
  })
>
invalidReturnAsync = const Template(
  "InvalidReturnAsync",
  withArguments: _withArgumentsInvalidReturnAsync,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidReturnAsync({
  required DartType actualType,
  required DartType expectedType,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var actualType_0 = labeler.labelType(actualType);
  var expectedType_0 = labeler.labelType(expectedType);
  return new Message(
    invalidReturnAsync,
    problemMessage:
        """A value of type '${actualType_0}' can't be returned from an async function with return type '${expectedType_0}'.""" +
        labeler.originMessages,
    arguments: {'actualType': actualType, 'expectedType': expectedType},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String typeVariableName,
    required String useVariance,
    required String supertypeName,
  })
>
invalidTypeParameterInSupertype = const Template(
  "InvalidTypeParameterInSupertype",
  withArguments: _withArgumentsInvalidTypeParameterInSupertype,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidTypeParameterInSupertype({
  required String typeVariableName,
  required String useVariance,
  required String supertypeName,
}) {
  var typeVariableName_0 = conversions.validateAndDemangleName(
    typeVariableName,
  );
  var useVariance_0 = conversions.validateString(useVariance);
  var supertypeName_0 = conversions.validateAndDemangleName(supertypeName);
  return new Message(
    invalidTypeParameterInSupertype,
    problemMessage:
        """Can't use implicitly 'out' variable '${typeVariableName_0}' in an '${useVariance_0}' position in supertype '${supertypeName_0}'.""",
    arguments: {
      'typeVariableName': typeVariableName,
      'useVariance': useVariance,
      'supertypeName': supertypeName,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String typeVariableVariance,
    required String typeVariableName,
    required String useVariance,
    required String supertypeName,
  })
>
invalidTypeParameterInSupertypeWithVariance = const Template(
  "InvalidTypeParameterInSupertypeWithVariance",
  withArguments: _withArgumentsInvalidTypeParameterInSupertypeWithVariance,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidTypeParameterInSupertypeWithVariance({
  required String typeVariableVariance,
  required String typeVariableName,
  required String useVariance,
  required String supertypeName,
}) {
  var typeVariableVariance_0 = conversions.validateString(typeVariableVariance);
  var typeVariableName_0 = conversions.validateAndDemangleName(
    typeVariableName,
  );
  var useVariance_0 = conversions.validateString(useVariance);
  var supertypeName_0 = conversions.validateAndDemangleName(supertypeName);
  return new Message(
    invalidTypeParameterInSupertypeWithVariance,
    problemMessage:
        """Can't use '${typeVariableVariance_0}' type variable '${typeVariableName_0}' in an '${useVariance_0}' position in supertype '${supertypeName_0}'.""",
    arguments: {
      'typeVariableVariance': typeVariableVariance,
      'typeVariableName': typeVariableName,
      'useVariance': useVariance,
      'supertypeName': supertypeName,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String typeVariableVariance,
    required String typeVariableName,
    required String useVariance,
  })
>
invalidTypeParameterVariancePosition = const Template(
  "InvalidTypeParameterVariancePosition",
  withArguments: _withArgumentsInvalidTypeParameterVariancePosition,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidTypeParameterVariancePosition({
  required String typeVariableVariance,
  required String typeVariableName,
  required String useVariance,
}) {
  var typeVariableVariance_0 = conversions.validateString(typeVariableVariance);
  var typeVariableName_0 = conversions.validateAndDemangleName(
    typeVariableName,
  );
  var useVariance_0 = conversions.validateString(useVariance);
  return new Message(
    invalidTypeParameterVariancePosition,
    problemMessage:
        """Can't use '${typeVariableVariance_0}' type variable '${typeVariableName_0}' in an '${useVariance_0}' position.""",
    arguments: {
      'typeVariableVariance': typeVariableVariance,
      'typeVariableName': typeVariableName,
      'useVariance': useVariance,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String typeVariableVariance,
    required String typeVariableName,
    required String useVariance,
  })
>
invalidTypeParameterVariancePositionInReturnType = const Template(
  "InvalidTypeParameterVariancePositionInReturnType",
  withArguments: _withArgumentsInvalidTypeParameterVariancePositionInReturnType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidTypeParameterVariancePositionInReturnType({
  required String typeVariableVariance,
  required String typeVariableName,
  required String useVariance,
}) {
  var typeVariableVariance_0 = conversions.validateString(typeVariableVariance);
  var typeVariableName_0 = conversions.validateAndDemangleName(
    typeVariableName,
  );
  var useVariance_0 = conversions.validateString(useVariance);
  return new Message(
    invalidTypeParameterVariancePositionInReturnType,
    problemMessage:
        """Can't use '${typeVariableVariance_0}' type variable '${typeVariableName_0}' in an '${useVariance_0}' position in the return type.""",
    arguments: {
      'typeVariableVariance': typeVariableVariance,
      'typeVariableName': typeVariableName,
      'useVariance': useVariance,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode invalidUseOfNullAwareAccess = const MessageCode(
  "InvalidUseOfNullAwareAccess",
  problemMessage: """Cannot use '?.' here.""",
  correctionMessage: """Try using '.'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name})> invokeNonFunction =
    const Template(
      "InvokeNonFunction",
      withArguments: _withArgumentsInvokeNonFunction,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvokeNonFunction({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    invokeNonFunction,
    problemMessage:
        """'${name_0}' isn't a function or method and can't be invoked.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String variableName})>
jointPatternVariableNotInAll = const Template(
  "JointPatternVariableNotInAll",
  withArguments: _withArgumentsJointPatternVariableNotInAll,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJointPatternVariableNotInAll({
  required String variableName,
}) {
  var variableName_0 = conversions.validateAndDemangleName(variableName);
  return new Message(
    jointPatternVariableNotInAll,
    problemMessage:
        """The variable '${variableName_0}' is available in some, but not all cases that share this body.""",
    arguments: {'variableName': variableName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String variableName})>
jointPatternVariableWithLabelDefault = const Template(
  "JointPatternVariableWithLabelDefault",
  withArguments: _withArgumentsJointPatternVariableWithLabelDefault,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJointPatternVariableWithLabelDefault({
  required String variableName,
}) {
  var variableName_0 = conversions.validateAndDemangleName(variableName);
  return new Message(
    jointPatternVariableWithLabelDefault,
    problemMessage:
        """The variable '${variableName_0}' is not available because there is a label or 'default' case.""",
    arguments: {'variableName': variableName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String variableName})>
jointPatternVariablesMismatch = const Template(
  "JointPatternVariablesMismatch",
  withArguments: _withArgumentsJointPatternVariablesMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJointPatternVariablesMismatch({
  required String variableName,
}) {
  var variableName_0 = conversions.validateAndDemangleName(variableName);
  return new Message(
    jointPatternVariablesMismatch,
    problemMessage:
        """Variable pattern '${variableName_0}' doesn't have the same type or finality in all cases.""",
    arguments: {'variableName': variableName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String className, required String superclassName})
>
jsInteropDartClassExtendsJSClass = const Template(
  "JsInteropDartClassExtendsJSClass",
  withArguments: _withArgumentsJsInteropDartClassExtendsJSClass,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropDartClassExtendsJSClass({
  required String className,
  required String superclassName,
}) {
  var className_0 = conversions.validateAndDemangleName(className);
  var superclassName_0 = conversions.validateAndDemangleName(superclassName);
  return new Message(
    jsInteropDartClassExtendsJSClass,
    problemMessage:
        """Dart class '${className_0}' cannot extend JS interop class '${superclassName_0}'.""",
    correctionMessage:
        """Try adding the JS interop annotation or removing it from the parent class.""",
    arguments: {'className': className, 'superclassName': superclassName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
jsInteropDartJsInteropAnnotationForStaticInteropOnly = const MessageCode(
  "JsInteropDartJsInteropAnnotationForStaticInteropOnly",
  problemMessage:
      """The '@JS' annotation from 'dart:js_interop' can only be used for static interop, either through extension types or '@staticInterop' classes.""",
  correctionMessage:
      """Try making this class an extension type or marking it as '@staticInterop'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode jsInteropEnclosingClassJSAnnotation = const MessageCode(
  "JsInteropEnclosingClassJSAnnotation",
  problemMessage:
      """Member has a JS interop annotation but the enclosing class does not.""",
  correctionMessage: """Try adding the annotation to the enclosing class.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode jsInteropEnclosingClassJSAnnotationContext =
    const MessageCode(
      "JsInteropEnclosingClassJSAnnotationContext",
      severity: CfeSeverity.context,
      problemMessage: """This is the enclosing class.""",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String className})>
jsInteropExportClassNotMarkedExportable = const Template(
  "JsInteropExportClassNotMarkedExportable",
  withArguments: _withArgumentsJsInteropExportClassNotMarkedExportable,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropExportClassNotMarkedExportable({
  required String className,
}) {
  var className_0 = conversions.validateAndDemangleName(className);
  return new Message(
    jsInteropExportClassNotMarkedExportable,
    problemMessage:
        """Class '${className_0}' does not have a `@JSExport` on it or any of its members.""",
    correctionMessage: """Use the `@JSExport` annotation on this class.""",
    arguments: {'className': className},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String className})>
jsInteropExportDartInterfaceHasNonEmptyJSExportValue = const Template(
  "JsInteropExportDartInterfaceHasNonEmptyJSExportValue",
  withArguments:
      _withArgumentsJsInteropExportDartInterfaceHasNonEmptyJSExportValue,
  severity: CfeSeverity.warning,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropExportDartInterfaceHasNonEmptyJSExportValue({
  required String className,
}) {
  var className_0 = conversions.validateAndDemangleName(className);
  return new Message(
    jsInteropExportDartInterfaceHasNonEmptyJSExportValue,
    problemMessage:
        """The value in the `@JSExport` annotation on the class or mixin '${className_0}' will be ignored.""",
    correctionMessage: """Remove the value in the annotation.""",
    arguments: {'className': className},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String memberName})>
jsInteropExportDisallowedMember = const Template(
  "JsInteropExportDisallowedMember",
  withArguments: _withArgumentsJsInteropExportDisallowedMember,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropExportDisallowedMember({
  required String memberName,
}) {
  var memberName_0 = conversions.validateAndDemangleName(memberName);
  return new Message(
    jsInteropExportDisallowedMember,
    problemMessage:
        """Member '${memberName_0}' is not a concrete instance member or declares type parameters, and therefore can't be exported.""",
    correctionMessage:
        """Remove the `@JSExport` annotation from the member, and use an instance member to call this member instead.""",
    arguments: {'memberName': memberName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required DartType type})>
jsInteropExportInvalidInteropTypeArgument = const Template(
  "JsInteropExportInvalidInteropTypeArgument",
  withArguments: _withArgumentsJsInteropExportInvalidInteropTypeArgument,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropExportInvalidInteropTypeArgument({
  required DartType type,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    jsInteropExportInvalidInteropTypeArgument,
    problemMessage:
        """Type argument '${type_0}' needs to be a non-JS interop type.""" +
        labeler.originMessages,
    correctionMessage:
        """Use a non-JS interop class that uses `@JSExport` instead.""",
    arguments: {'type': type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required DartType type})>
jsInteropExportInvalidTypeArgument = const Template(
  "JsInteropExportInvalidTypeArgument",
  withArguments: _withArgumentsJsInteropExportInvalidTypeArgument,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropExportInvalidTypeArgument({
  required DartType type,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    jsInteropExportInvalidTypeArgument,
    problemMessage:
        """Type argument '${type_0}' needs to be an interface type.""" +
        labeler.originMessages,
    correctionMessage:
        """Use a non-JS interop class that uses `@JSExport` instead.""",
    arguments: {'type': type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String exportName, required String members})
>
jsInteropExportMemberCollision = const Template(
  "JsInteropExportMemberCollision",
  withArguments: _withArgumentsJsInteropExportMemberCollision,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropExportMemberCollision({
  required String exportName,
  required String members,
}) {
  var exportName_0 = conversions.validateAndDemangleName(exportName);
  var members_0 = conversions.validateString(members);
  return new Message(
    jsInteropExportMemberCollision,
    problemMessage:
        """The following class members collide with the same export '${exportName_0}': ${members_0}.""",
    correctionMessage:
        """Either remove the conflicting members or use a different export name.""",
    arguments: {'exportName': exportName, 'members': members},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String className})>
jsInteropExportNoExportableMembers = const Template(
  "JsInteropExportNoExportableMembers",
  withArguments: _withArgumentsJsInteropExportNoExportableMembers,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropExportNoExportableMembers({
  required String className,
}) {
  var className_0 = conversions.validateAndDemangleName(className);
  return new Message(
    jsInteropExportNoExportableMembers,
    problemMessage:
        """Class '${className_0}' has no exportable members in the class or the inheritance chain.""",
    correctionMessage:
        """Using `@JSExport`, annotate at least one instance member with a body or annotate a class that has such a member in the inheritance chain.""",
    arguments: {'className': className},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode jsInteropExtensionTypeMemberNotInterop = const MessageCode(
  "JsInteropExtensionTypeMemberNotInterop",
  problemMessage:
      """Extension type member is marked 'external', but the representation type of its extension type is not a valid JS interop type.""",
  correctionMessage:
      """Try declaring a valid JS interop representation type, which may include 'dart:js_interop' types, '@staticInterop' types, 'dart:html' types, or other interop extension types.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String extensionTypeName,
    required DartType representationType,
  })
>
jsInteropExtensionTypeNotInterop = const Template(
  "JsInteropExtensionTypeNotInterop",
  withArguments: _withArgumentsJsInteropExtensionTypeNotInterop,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropExtensionTypeNotInterop({
  required String extensionTypeName,
  required DartType representationType,
}) {
  var extensionTypeName_0 = conversions.validateAndDemangleName(
    extensionTypeName,
  );
  TypeLabeler labeler = new TypeLabeler();
  var representationType_0 = labeler.labelType(representationType);
  return new Message(
    jsInteropExtensionTypeNotInterop,
    problemMessage:
        """Extension type '${extensionTypeName_0}' is marked with a '@JS' annotation, but its representation type is not a valid JS interop type: '${representationType_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try declaring a valid JS interop representation type, which may include 'dart:js_interop' types, '@staticInterop' types, 'dart:html' types, or other interop extension types.""",
    arguments: {
      'extensionTypeName': extensionTypeName,
      'representationType': representationType,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
jsInteropExtensionTypeUsedWithWrongJsAnnotation = const MessageCode(
  "JsInteropExtensionTypeUsedWithWrongJsAnnotation",
  problemMessage:
      """Extension types should use the '@JS' annotation from 'dart:js_interop' and not from 'package:js'.""",
  correctionMessage:
      """Try using the '@JS' annotation from 'dart:js_interop' annotation on this extension type instead.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
jsInteropExternalExtensionMemberOnTypeInvalid = const MessageCode(
  "JsInteropExternalExtensionMemberOnTypeInvalid",
  problemMessage:
      """JS interop type or @Native type from an SDK web library required for 'external' extension members.""",
  correctionMessage:
      """Try making the on-type a JS interop type or an @Native SDK web library type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
jsInteropExternalExtensionMemberWithStaticDisallowed = const MessageCode(
  "JsInteropExternalExtensionMemberWithStaticDisallowed",
  problemMessage:
      """External extension members with the keyword 'static' on JS interop and @Native types are disallowed.""",
  correctionMessage: """Try putting the member in the on-type instead.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode jsInteropExternalMemberNotJSAnnotated = const MessageCode(
  "JsInteropExternalMemberNotJSAnnotated",
  problemMessage: """Only JS interop members may be 'external'.""",
  correctionMessage:
      """Try removing the 'external' keyword or adding a JS interop annotation.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String conversion})>
jsInteropFunctionToJSNamedParameters = const Template(
  "JsInteropFunctionToJSNamedParameters",
  withArguments: _withArgumentsJsInteropFunctionToJSNamedParameters,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropFunctionToJSNamedParameters({
  required String conversion,
}) {
  var conversion_0 = conversions.validateString(conversion);
  return new Message(
    jsInteropFunctionToJSNamedParameters,
    problemMessage:
        """Functions converted via '${conversion_0}' cannot declare named parameters.""",
    correctionMessage:
        """Remove the declared named parameters from the function.""",
    arguments: {'conversion': conversion},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String conversion, required DartType functionType})
>
jsInteropFunctionToJSRequiresStaticType = const Template(
  "JsInteropFunctionToJSRequiresStaticType",
  withArguments: _withArgumentsJsInteropFunctionToJSRequiresStaticType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropFunctionToJSRequiresStaticType({
  required String conversion,
  required DartType functionType,
}) {
  var conversion_0 = conversions.validateString(conversion);
  TypeLabeler labeler = new TypeLabeler();
  var functionType_0 = labeler.labelType(functionType);
  return new Message(
    jsInteropFunctionToJSRequiresStaticType,
    problemMessage:
        """Functions converted via '${conversion_0}' require a statically known function type, but Type '${functionType_0}' is not a precise function type, e.g., `void Function()`.""" +
        labeler.originMessages,
    correctionMessage:
        """Insert an explicit cast to the expected function type.""",
    arguments: {'conversion': conversion, 'functionType': functionType},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String conversion})>
jsInteropFunctionToJSTypeParameters = const Template(
  "JsInteropFunctionToJSTypeParameters",
  withArguments: _withArgumentsJsInteropFunctionToJSTypeParameters,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropFunctionToJSTypeParameters({
  required String conversion,
}) {
  var conversion_0 = conversions.validateString(conversion);
  return new Message(
    jsInteropFunctionToJSTypeParameters,
    problemMessage:
        """Functions converted via '${conversion_0}' cannot declare type parameters.""",
    correctionMessage:
        """Remove the declared type parameters from the function.""",
    arguments: {'conversion': conversion},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String conversion,
    required String typeWithDiasllowedPartsHighlighted,
  })
>
jsInteropFunctionToJSTypeViolation = const Template(
  "JsInteropFunctionToJSTypeViolation",
  withArguments: _withArgumentsJsInteropFunctionToJSTypeViolation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropFunctionToJSTypeViolation({
  required String conversion,
  required String typeWithDiasllowedPartsHighlighted,
}) {
  var conversion_0 = conversions.validateString(conversion);
  var typeWithDiasllowedPartsHighlighted_0 = conversions.validateString(
    typeWithDiasllowedPartsHighlighted,
  );
  return new Message(
    jsInteropFunctionToJSTypeViolation,
    problemMessage:
        """Function converted via '${conversion_0}' contains invalid types in its function signature: '${typeWithDiasllowedPartsHighlighted_0}'.""",
    correctionMessage:
        """Use one of these valid types instead: JS types from 'dart:js_interop', ExternalDartReference, void, bool, num, double, int, String, extension types that erase to one of these types, '@staticInterop' types, 'dart:html' types when compiling to JS, or a type parameter that is a subtype of a valid non-primitive type.""",
    arguments: {
      'conversion': conversion,
      'typeWithDiasllowedPartsHighlighted': typeWithDiasllowedPartsHighlighted,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode jsInteropInvalidStaticClassMemberName = const MessageCode(
  "JsInteropInvalidStaticClassMemberName",
  problemMessage:
      """JS interop static class members cannot have '.' in their JS name.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required DartType type})>
jsInteropIsAInvalidTypeVariable = const Template(
  "JsInteropIsAInvalidTypeVariable",
  withArguments: _withArgumentsJsInteropIsAInvalidTypeVariable,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropIsAInvalidTypeVariable({
  required DartType type,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    jsInteropIsAInvalidTypeVariable,
    problemMessage:
        """Type argument '${type_0}' provided to 'isA' cannot be a type variable and must be an interop extension type that can be determined at compile-time.""" +
        labeler.originMessages,
    correctionMessage:
        """Use a valid interop extension type that can be determined at compile-time as the type argument instead.""",
    arguments: {'type': type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required DartType type})>
jsInteropIsAObjectLiteralType = const Template(
  "JsInteropIsAObjectLiteralType",
  withArguments: _withArgumentsJsInteropIsAObjectLiteralType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropIsAObjectLiteralType({required DartType type}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    jsInteropIsAObjectLiteralType,
    problemMessage:
        """Type argument '${type_0}' has an object literal constructor. Because 'isA' uses the type's name or '@JS()' rename, this may result in an incorrect type check.""" +
        labeler.originMessages,
    correctionMessage: """Use 'JSObject' as the type argument instead.""",
    arguments: {'type': type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required DartType interopType, required String jsTypeName})
>
jsInteropIsAPrimitiveExtensionType = const Template(
  "JsInteropIsAPrimitiveExtensionType",
  withArguments: _withArgumentsJsInteropIsAPrimitiveExtensionType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropIsAPrimitiveExtensionType({
  required DartType interopType,
  required String jsTypeName,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var interopType_0 = labeler.labelType(interopType);
  var jsTypeName_0 = conversions.validateString(jsTypeName);
  return new Message(
    jsInteropIsAPrimitiveExtensionType,
    problemMessage:
        """Type argument '${interopType_0}' wraps primitive JS type '${jsTypeName_0}', which is specially handled using 'typeof'.""" +
        labeler.originMessages,
    correctionMessage:
        """Use the primitive JS type '${jsTypeName_0}' as the type argument instead.""",
    arguments: {'interopType': interopType, 'jsTypeName': jsTypeName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode jsInteropIsATearoff = const MessageCode(
  "JsInteropIsATearoff",
  problemMessage: """'isA' can't be torn off.""",
  correctionMessage:
      """Use a method that calls 'isA' and tear off that method instead.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String className, required String superclassName})
>
jsInteropJSClassExtendsDartClass = const Template(
  "JsInteropJSClassExtendsDartClass",
  withArguments: _withArgumentsJsInteropJSClassExtendsDartClass,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropJSClassExtendsDartClass({
  required String className,
  required String superclassName,
}) {
  var className_0 = conversions.validateAndDemangleName(className);
  var superclassName_0 = conversions.validateAndDemangleName(superclassName);
  return new Message(
    jsInteropJSClassExtendsDartClass,
    problemMessage:
        """JS interop class '${className_0}' cannot extend Dart class '${superclassName_0}'.""",
    correctionMessage:
        """Try removing the JS interop annotation or adding it to the parent class.""",
    arguments: {'className': className, 'superclassName': superclassName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode jsInteropNamedParameters = const MessageCode(
  "JsInteropNamedParameters",
  problemMessage:
      """Named parameters for JS interop functions are only allowed in object literal constructors or @anonymous factories.""",
  correctionMessage:
      """Try replacing them with normal or optional parameters.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String className,
    required String nativeClassName,
    required String uri,
  })
>
jsInteropNativeClassInAnnotation = const Template(
  "JsInteropNativeClassInAnnotation",
  withArguments: _withArgumentsJsInteropNativeClassInAnnotation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropNativeClassInAnnotation({
  required String className,
  required String nativeClassName,
  required String uri,
}) {
  var className_0 = conversions.validateAndDemangleName(className);
  var nativeClassName_0 = conversions.validateAndDemangleName(nativeClassName);
  var uri_0 = conversions.validateString(uri);
  return new Message(
    jsInteropNativeClassInAnnotation,
    problemMessage:
        """Non-static JS interop class '${className_0}' conflicts with natively supported class '${nativeClassName_0}' in '${uri_0}'.""",
    correctionMessage:
        """Try replacing it with a static JS interop class using `@staticInterop` with extension methods, or use js_util to interact with the native object of type '${nativeClassName_0}'.""",
    arguments: {
      'className': className,
      'nativeClassName': nativeClassName,
      'uri': uri,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode jsInteropNonExternalConstructor = const MessageCode(
  "JsInteropNonExternalConstructor",
  problemMessage:
      """JS interop classes do not support non-external constructors.""",
  correctionMessage: """Try annotating with `external`.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode jsInteropNonExternalMember = const MessageCode(
  "JsInteropNonExternalMember",
  problemMessage:
      """This JS interop member must be annotated with `external`. Only factories and static methods can be non-external.""",
  correctionMessage: """Try annotating the member with `external`.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String className, required String superclassName})
>
jsInteropNonStaticWithStaticInteropSupertype = const Template(
  "JsInteropNonStaticWithStaticInteropSupertype",
  withArguments: _withArgumentsJsInteropNonStaticWithStaticInteropSupertype,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropNonStaticWithStaticInteropSupertype({
  required String className,
  required String superclassName,
}) {
  var className_0 = conversions.validateAndDemangleName(className);
  var superclassName_0 = conversions.validateAndDemangleName(superclassName);
  return new Message(
    jsInteropNonStaticWithStaticInteropSupertype,
    problemMessage:
        """Class '${className_0}' does not have an `@staticInterop` annotation, but has supertype '${superclassName_0}', which does.""",
    correctionMessage:
        """Try marking '${className_0}' as a `@staticInterop` class, or don't inherit '${superclassName_0}'.""",
    arguments: {'className': className, 'superclassName': superclassName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String kind})>
jsInteropObjectLiteralConstructorPositionalParameters = const Template(
  "JsInteropObjectLiteralConstructorPositionalParameters",
  withArguments:
      _withArgumentsJsInteropObjectLiteralConstructorPositionalParameters,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropObjectLiteralConstructorPositionalParameters({
  required String kind,
}) {
  var kind_0 = conversions.validateString(kind);
  return new Message(
    jsInteropObjectLiteralConstructorPositionalParameters,
    problemMessage:
        """${kind_0} should not contain any positional parameters.""",
    correctionMessage: """Try replacing them with named parameters instead.""",
    arguments: {'kind': kind},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode jsInteropOperatorCannotBeRenamed = const MessageCode(
  "JsInteropOperatorCannotBeRenamed",
  problemMessage:
      """JS interop operator methods cannot be renamed using the '@JS' annotation.""",
  correctionMessage:
      """Remove the annotation or remove the value inside the annotation.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode jsInteropOperatorsNotSupported = const MessageCode(
  "JsInteropOperatorsNotSupported",
  problemMessage:
      """JS interop types do not support overloading external operator methods, with the exception of '[]' and '[]=' using static interop.""",
  correctionMessage: """Try making this class a static interop type instead.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required DartType type})>
jsInteropStaticInteropExternalAccessorTypeViolation = const Template(
  "JsInteropStaticInteropExternalAccessorTypeViolation",
  withArguments:
      _withArgumentsJsInteropStaticInteropExternalAccessorTypeViolation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropStaticInteropExternalAccessorTypeViolation({
  required DartType type,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    jsInteropStaticInteropExternalAccessorTypeViolation,
    problemMessage:
        """External JS interop member contains an invalid type: '${type_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Use one of these valid types instead: JS types from 'dart:js_interop', ExternalDartReference, void, bool, num, double, int, String, extension types that erase to one of these types, '@staticInterop' types, 'dart:html' types when compiling to JS, or a type parameter that is a subtype of a valid non-primitive type.""",
    arguments: {'type': type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String typeWithDiasllowedPartsHighlighted})
>
jsInteropStaticInteropExternalFunctionTypeViolation = const Template(
  "JsInteropStaticInteropExternalFunctionTypeViolation",
  withArguments:
      _withArgumentsJsInteropStaticInteropExternalFunctionTypeViolation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropStaticInteropExternalFunctionTypeViolation({
  required String typeWithDiasllowedPartsHighlighted,
}) {
  var typeWithDiasllowedPartsHighlighted_0 = conversions.validateString(
    typeWithDiasllowedPartsHighlighted,
  );
  return new Message(
    jsInteropStaticInteropExternalFunctionTypeViolation,
    problemMessage:
        """External JS interop member contains invalid types in its function signature: '${typeWithDiasllowedPartsHighlighted_0}'.""",
    correctionMessage:
        """Use one of these valid types instead: JS types from 'dart:js_interop', ExternalDartReference, void, bool, num, double, int, String, extension types that erase to one of these types, '@staticInterop' types, 'dart:html' types when compiling to JS, or a type parameter that is a subtype of a valid non-primitive type.""",
    arguments: {
      'typeWithDiasllowedPartsHighlighted': typeWithDiasllowedPartsHighlighted,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
jsInteropStaticInteropGenerativeConstructor = const MessageCode(
  "JsInteropStaticInteropGenerativeConstructor",
  problemMessage:
      """`@staticInterop` classes should not contain any generative constructors.""",
  correctionMessage: """Use factory constructors instead.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String className,
    required String accessorKindPresent,
    required String accessorKindAbsent,
    required String exportName,
    required String missingMembers,
  })
>
jsInteropStaticInteropMockMissingGetterOrSetter = const Template(
  "JsInteropStaticInteropMockMissingGetterOrSetter",
  withArguments: _withArgumentsJsInteropStaticInteropMockMissingGetterOrSetter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropStaticInteropMockMissingGetterOrSetter({
  required String className,
  required String accessorKindPresent,
  required String accessorKindAbsent,
  required String exportName,
  required String missingMembers,
}) {
  var className_0 = conversions.validateAndDemangleName(className);
  var accessorKindPresent_0 = conversions.validateString(accessorKindPresent);
  var accessorKindAbsent_0 = conversions.validateString(accessorKindAbsent);
  var exportName_0 = conversions.validateAndDemangleName(exportName);
  var missingMembers_0 = conversions.validateString(missingMembers);
  return new Message(
    jsInteropStaticInteropMockMissingGetterOrSetter,
    problemMessage:
        """Dart class '${className_0}' has a ${accessorKindPresent_0}, but does not have a ${accessorKindAbsent_0} to implement any of the following extension member(s) with export name '${exportName_0}': ${missingMembers_0}.""",
    correctionMessage:
        """Declare an exportable ${accessorKindAbsent_0} that implements one of these extension members.""",
    arguments: {
      'className': className,
      'accessorKindPresent': accessorKindPresent,
      'accessorKindAbsent': accessorKindAbsent,
      'exportName': exportName,
      'missingMembers': missingMembers,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String className,
    required String exportName,
    required String missingMembers,
  })
>
jsInteropStaticInteropMockMissingImplements = const Template(
  "JsInteropStaticInteropMockMissingImplements",
  withArguments: _withArgumentsJsInteropStaticInteropMockMissingImplements,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropStaticInteropMockMissingImplements({
  required String className,
  required String exportName,
  required String missingMembers,
}) {
  var className_0 = conversions.validateAndDemangleName(className);
  var exportName_0 = conversions.validateAndDemangleName(exportName);
  var missingMembers_0 = conversions.validateString(missingMembers);
  return new Message(
    jsInteropStaticInteropMockMissingImplements,
    problemMessage:
        """Dart class '${className_0}' does not have any members that implement any of the following extension member(s) with export name '${exportName_0}': ${missingMembers_0}.""",
    correctionMessage:
        """Declare an exportable member that implements one of these extension members.""",
    arguments: {
      'className': className,
      'exportName': exportName,
      'missingMembers': missingMembers,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required DartType type})>
jsInteropStaticInteropMockNotStaticInteropType = const Template(
  "JsInteropStaticInteropMockNotStaticInteropType",
  withArguments: _withArgumentsJsInteropStaticInteropMockNotStaticInteropType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropStaticInteropMockNotStaticInteropType({
  required DartType type,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    jsInteropStaticInteropMockNotStaticInteropType,
    problemMessage:
        """Type argument '${type_0}' needs to be a `@staticInterop` type.""" +
        labeler.originMessages,
    correctionMessage: """Use a `@staticInterop` class instead.""",
    arguments: {'type': type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required DartType type})>
jsInteropStaticInteropMockTypeParametersNotAllowed = const Template(
  "JsInteropStaticInteropMockTypeParametersNotAllowed",
  withArguments:
      _withArgumentsJsInteropStaticInteropMockTypeParametersNotAllowed,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropStaticInteropMockTypeParametersNotAllowed({
  required DartType type,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    jsInteropStaticInteropMockTypeParametersNotAllowed,
    problemMessage:
        """Type argument '${type_0}' has type parameters that do not match their bound. createStaticInteropMock requires instantiating all type parameters to their bound to ensure mocking conformance.""" +
        labeler.originMessages,
    correctionMessage:
        """Remove the type parameter in the type argument or replace it with its bound.""",
    arguments: {'type': type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String className})>
jsInteropStaticInteropNoJSAnnotation = const Template(
  "JsInteropStaticInteropNoJSAnnotation",
  withArguments: _withArgumentsJsInteropStaticInteropNoJSAnnotation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropStaticInteropNoJSAnnotation({
  required String className,
}) {
  var className_0 = conversions.validateAndDemangleName(className);
  return new Message(
    jsInteropStaticInteropNoJSAnnotation,
    problemMessage:
        """`@staticInterop` classes should also have the `@JS` annotation.""",
    correctionMessage: """Add `@JS` to class '${className_0}'.""",
    arguments: {'className': className},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
jsInteropStaticInteropParameterInitializersAreIgnored = const MessageCode(
  "JsInteropStaticInteropParameterInitializersAreIgnored",
  severity: CfeSeverity.warning,
  problemMessage:
      """Initializers for parameters are ignored on static interop external functions.""",
  correctionMessage:
      """Declare a forwarding non-external function with this initializer, or remove the initializer.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
jsInteropStaticInteropSyntheticConstructor = const MessageCode(
  "JsInteropStaticInteropSyntheticConstructor",
  problemMessage:
      """Synthetic constructors on `@staticInterop` classes can not be used.""",
  correctionMessage:
      """Declare an external factory constructor for this `@staticInterop` class and use that instead.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String memberKind, required String memberName})
>
jsInteropStaticInteropTearOffsDisallowed = const Template(
  "JsInteropStaticInteropTearOffsDisallowed",
  withArguments: _withArgumentsJsInteropStaticInteropTearOffsDisallowed,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropStaticInteropTearOffsDisallowed({
  required String memberKind,
  required String memberName,
}) {
  var memberKind_0 = conversions.validateString(memberKind);
  var memberName_0 = conversions.validateAndDemangleName(memberName);
  return new Message(
    jsInteropStaticInteropTearOffsDisallowed,
    problemMessage:
        """Tear-offs of external ${memberKind_0} '${memberName_0}' are disallowed.""",
    correctionMessage: """Declare a closure that calls this member instead.""",
    arguments: {'memberKind': memberKind, 'memberName': memberName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String className})>
jsInteropStaticInteropTrustTypesUsageNotAllowed = const Template(
  "JsInteropStaticInteropTrustTypesUsageNotAllowed",
  withArguments: _withArgumentsJsInteropStaticInteropTrustTypesUsageNotAllowed,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropStaticInteropTrustTypesUsageNotAllowed({
  required String className,
}) {
  var className_0 = conversions.validateAndDemangleName(className);
  return new Message(
    jsInteropStaticInteropTrustTypesUsageNotAllowed,
    problemMessage:
        """JS interop class '${className_0}' has an `@trustTypes` annotation, but `@trustTypes` is only supported within the sdk.""",
    correctionMessage: """Try removing the `@trustTypes` annotation.""",
    arguments: {'className': className},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String className})>
jsInteropStaticInteropTrustTypesUsedWithoutStaticInterop = const Template(
  "JsInteropStaticInteropTrustTypesUsedWithoutStaticInterop",
  withArguments:
      _withArgumentsJsInteropStaticInteropTrustTypesUsedWithoutStaticInterop,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropStaticInteropTrustTypesUsedWithoutStaticInterop({
  required String className,
}) {
  var className_0 = conversions.validateAndDemangleName(className);
  return new Message(
    jsInteropStaticInteropTrustTypesUsedWithoutStaticInterop,
    problemMessage:
        """JS interop class '${className_0}' has an `@trustTypes` annotation, but no `@staticInterop` annotation.""",
    correctionMessage: """Try marking the class using `@staticInterop`.""",
    arguments: {'className': className},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String className})>
jsInteropStaticInteropWithInstanceMembers = const Template(
  "JsInteropStaticInteropWithInstanceMembers",
  withArguments: _withArgumentsJsInteropStaticInteropWithInstanceMembers,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropStaticInteropWithInstanceMembers({
  required String className,
}) {
  var className_0 = conversions.validateAndDemangleName(className);
  return new Message(
    jsInteropStaticInteropWithInstanceMembers,
    problemMessage:
        """JS interop class '${className_0}' with `@staticInterop` annotation cannot declare instance members.""",
    correctionMessage:
        """Try moving the instance member to a static extension.""",
    arguments: {'className': className},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String className, required String superclassName})
>
jsInteropStaticInteropWithNonStaticSupertype = const Template(
  "JsInteropStaticInteropWithNonStaticSupertype",
  withArguments: _withArgumentsJsInteropStaticInteropWithNonStaticSupertype,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropStaticInteropWithNonStaticSupertype({
  required String className,
  required String superclassName,
}) {
  var className_0 = conversions.validateAndDemangleName(className);
  var superclassName_0 = conversions.validateAndDemangleName(superclassName);
  return new Message(
    jsInteropStaticInteropWithNonStaticSupertype,
    problemMessage:
        """JS interop class '${className_0}' has an `@staticInterop` annotation, but has supertype '${superclassName_0}', which does not.""",
    correctionMessage:
        """Try marking the supertype as a static interop class using `@staticInterop`.""",
    arguments: {'className': className, 'superclassName': superclassName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String label})> labelNotFound =
    const Template("LabelNotFound", withArguments: _withArgumentsLabelNotFound);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsLabelNotFound({required String label}) {
  var label_0 = conversions.validateAndDemangleName(label);
  return new Message(
    labelNotFound,
    problemMessage: """Can't find label '${label_0}'.""",
    correctionMessage:
        """Try defining the label, or correcting the name to match an existing label.""",
    arguments: {'label': label},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode languageVersionInvalidInDotPackages = const MessageCode(
  "LanguageVersionInvalidInDotPackages",
  problemMessage:
      """The language version is not specified correctly in the packages file.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode languageVersionLibraryContext = const MessageCode(
  "LanguageVersionLibraryContext",
  severity: CfeSeverity.context,
  problemMessage: """This is language version annotation in the library.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode languageVersionMismatchInPart = const MessageCode(
  "LanguageVersionMismatchInPart",
  problemMessage:
      """The language version override has to be the same in the library and its part(s).""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode languageVersionMismatchInPatch = const MessageCode(
  "LanguageVersionMismatchInPatch",
  problemMessage:
      """The language version override has to be the same in the library and its patch(es).""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode languageVersionPartContext = const MessageCode(
  "LanguageVersionPartContext",
  severity: CfeSeverity.context,
  problemMessage: """This is language version annotation in the part.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode languageVersionPatchContext = const MessageCode(
  "LanguageVersionPatchContext",
  severity: CfeSeverity.context,
  problemMessage: """This is language version annotation in the patch.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required int specifiedMajor,
    required int specifiedMinor,
    required int highestSupportedMajor,
    required int highestSupportedMinor,
  })
>
languageVersionTooHighExplicit = const Template(
  "LanguageVersionTooHighExplicit",
  withArguments: _withArgumentsLanguageVersionTooHighExplicit,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsLanguageVersionTooHighExplicit({
  required int specifiedMajor,
  required int specifiedMinor,
  required int highestSupportedMajor,
  required int highestSupportedMinor,
}) {
  return new Message(
    languageVersionTooHighExplicit,
    problemMessage:
        """The specified language version ${specifiedMajor}.${specifiedMinor} is too high. The highest supported language version is ${highestSupportedMajor}.${highestSupportedMinor}.""",
    arguments: {
      'specifiedMajor': specifiedMajor,
      'specifiedMinor': specifiedMinor,
      'highestSupportedMajor': highestSupportedMajor,
      'highestSupportedMinor': highestSupportedMinor,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required int specifiedMajor,
    required int specifiedMinor,
    required String packageName,
    required int highestSupportedMajor,
    required int highestSupportedMinor,
  })
>
languageVersionTooHighPackage = const Template(
  "LanguageVersionTooHighPackage",
  withArguments: _withArgumentsLanguageVersionTooHighPackage,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsLanguageVersionTooHighPackage({
  required int specifiedMajor,
  required int specifiedMinor,
  required String packageName,
  required int highestSupportedMajor,
  required int highestSupportedMinor,
}) {
  var packageName_0 = conversions.validateAndDemangleName(packageName);
  return new Message(
    languageVersionTooHighPackage,
    problemMessage:
        """The language version ${specifiedMajor}.${specifiedMinor} specified for the package '${packageName_0}' is too high. The highest supported language version is ${highestSupportedMajor}.${highestSupportedMinor}.""",
    arguments: {
      'specifiedMajor': specifiedMajor,
      'specifiedMinor': specifiedMinor,
      'packageName': packageName,
      'highestSupportedMajor': highestSupportedMajor,
      'highestSupportedMinor': highestSupportedMinor,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required int specifiedMajor,
    required int specifiedMinor,
    required int lowestSupportedMajor,
    required int lowestSupportedMinor,
  })
>
languageVersionTooLowExplicit = const Template(
  "LanguageVersionTooLowExplicit",
  withArguments: _withArgumentsLanguageVersionTooLowExplicit,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsLanguageVersionTooLowExplicit({
  required int specifiedMajor,
  required int specifiedMinor,
  required int lowestSupportedMajor,
  required int lowestSupportedMinor,
}) {
  return new Message(
    languageVersionTooLowExplicit,
    problemMessage:
        """The specified language version ${specifiedMajor}.${specifiedMinor} is too low. The lowest supported language version is ${lowestSupportedMajor}.${lowestSupportedMinor}.""",
    arguments: {
      'specifiedMajor': specifiedMajor,
      'specifiedMinor': specifiedMinor,
      'lowestSupportedMajor': lowestSupportedMajor,
      'lowestSupportedMinor': lowestSupportedMinor,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required int specifiedMajor,
    required int specifiedMinor,
    required String packageName,
    required int lowestSupportedMajor,
    required int lowestSupportedMinor,
  })
>
languageVersionTooLowPackage = const Template(
  "LanguageVersionTooLowPackage",
  withArguments: _withArgumentsLanguageVersionTooLowPackage,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsLanguageVersionTooLowPackage({
  required int specifiedMajor,
  required int specifiedMinor,
  required String packageName,
  required int lowestSupportedMajor,
  required int lowestSupportedMinor,
}) {
  var packageName_0 = conversions.validateAndDemangleName(packageName);
  return new Message(
    languageVersionTooLowPackage,
    problemMessage:
        """The language version ${specifiedMajor}.${specifiedMinor} specified for the package '${packageName_0}' is too low. The lowest supported language version is ${lowestSupportedMajor}.${lowestSupportedMinor}.""",
    arguments: {
      'specifiedMajor': specifiedMajor,
      'specifiedMinor': specifiedMinor,
      'packageName': packageName,
      'lowestSupportedMajor': lowestSupportedMajor,
      'lowestSupportedMinor': lowestSupportedMinor,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String variableName})>
lateDefinitelyAssignedError = const Template(
  "LateDefinitelyAssignedError",
  withArguments: _withArgumentsLateDefinitelyAssignedError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsLateDefinitelyAssignedError({
  required String variableName,
}) {
  var variableName_0 = conversions.validateAndDemangleName(variableName);
  return new Message(
    lateDefinitelyAssignedError,
    problemMessage:
        """Late final variable '${variableName_0}' definitely assigned.""",
    arguments: {'variableName': variableName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String variableName})>
lateDefinitelyUnassignedError = const Template(
  "LateDefinitelyUnassignedError",
  withArguments: _withArgumentsLateDefinitelyUnassignedError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsLateDefinitelyUnassignedError({
  required String variableName,
}) {
  var variableName_0 = conversions.validateAndDemangleName(variableName);
  return new Message(
    lateDefinitelyUnassignedError,
    problemMessage:
        """Late variable '${variableName_0}' without initializer is definitely unassigned.""",
    arguments: {'variableName': variableName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode listLiteralTooManyTypeArguments = const MessageCode(
  "ListLiteralTooManyTypeArguments",
  problemMessage: """List literal requires exactly one type argument.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode listPatternTooManyTypeArguments = const MessageCode(
  "ListPatternTooManyTypeArguments",
  problemMessage: """A list pattern requires exactly one type argument.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode loadLibraryTakesNoArguments = const MessageCode(
  "LoadLibraryTakesNoArguments",
  problemMessage: """'loadLibrary' takes no arguments.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String variableName})>
localVariableUsedBeforeDeclared = const Template(
  "LocalVariableUsedBeforeDeclared",
  withArguments: _withArgumentsLocalVariableUsedBeforeDeclared,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsLocalVariableUsedBeforeDeclared({
  required String variableName,
}) {
  var variableName_0 = conversions.validateAndDemangleName(variableName);
  return new Message(
    localVariableUsedBeforeDeclared,
    problemMessage:
        """Local variable '${variableName_0}' can't be referenced before it is declared.""",
    arguments: {'variableName': variableName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String variableName})>
localVariableUsedBeforeDeclaredContext = const Template(
  "LocalVariableUsedBeforeDeclaredContext",
  withArguments: _withArgumentsLocalVariableUsedBeforeDeclaredContext,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsLocalVariableUsedBeforeDeclaredContext({
  required String variableName,
}) {
  var variableName_0 = conversions.validateAndDemangleName(variableName);
  return new Message(
    localVariableUsedBeforeDeclaredContext,
    problemMessage:
        """This is the declaration of the variable '${variableName_0}'.""",
    arguments: {'variableName': variableName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode mainNotFunctionDeclaration = const MessageCode(
  "MainNotFunctionDeclaration",
  problemMessage: """The 'main' declaration must be a function declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode mainNotFunctionDeclarationExported = const MessageCode(
  "MainNotFunctionDeclarationExported",
  problemMessage:
      """The exported 'main' declaration must be a function declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode mainRequiredNamedParameters = const MessageCode(
  "MainRequiredNamedParameters",
  problemMessage:
      """The 'main' method cannot have required named parameters.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode mainRequiredNamedParametersExported = const MessageCode(
  "MainRequiredNamedParametersExported",
  problemMessage:
      """The exported 'main' method cannot have required named parameters.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode mainTooManyRequiredParameters = const MessageCode(
  "MainTooManyRequiredParameters",
  problemMessage:
      """The 'main' method must have at most 2 required parameters.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode mainTooManyRequiredParametersExported = const MessageCode(
  "MainTooManyRequiredParametersExported",
  problemMessage:
      """The exported 'main' method must have at most 2 required parameters.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required DartType actualType,
    required DartType expectedType,
  })
>
mainWrongParameterType = const Template(
  "MainWrongParameterType",
  withArguments: _withArgumentsMainWrongParameterType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMainWrongParameterType({
  required DartType actualType,
  required DartType expectedType,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var actualType_0 = labeler.labelType(actualType);
  var expectedType_0 = labeler.labelType(expectedType);
  return new Message(
    mainWrongParameterType,
    problemMessage:
        """The type '${actualType_0}' of the first parameter of the 'main' method is not a supertype of '${expectedType_0}'.""" +
        labeler.originMessages,
    arguments: {'actualType': actualType, 'expectedType': expectedType},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required DartType actualType,
    required DartType expectedType,
  })
>
mainWrongParameterTypeExported = const Template(
  "MainWrongParameterTypeExported",
  withArguments: _withArgumentsMainWrongParameterTypeExported,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMainWrongParameterTypeExported({
  required DartType actualType,
  required DartType expectedType,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var actualType_0 = labeler.labelType(actualType);
  var expectedType_0 = labeler.labelType(expectedType);
  return new Message(
    mainWrongParameterTypeExported,
    problemMessage:
        """The type '${actualType_0}' of the first parameter of the exported 'main' method is not a supertype of '${expectedType_0}'.""" +
        labeler.originMessages,
    arguments: {'actualType': actualType, 'expectedType': expectedType},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode mapPatternTypeArgumentMismatch = const MessageCode(
  "MapPatternTypeArgumentMismatch",
  problemMessage: """A map pattern requires exactly two type arguments.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String constructorName})>
memberConflictsWithConstructor = const Template(
  "MemberConflictsWithConstructor",
  withArguments: _withArgumentsMemberConflictsWithConstructor,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMemberConflictsWithConstructor({
  required String constructorName,
}) {
  var constructorName_0 = conversions.validateAndDemangleName(constructorName);
  return new Message(
    memberConflictsWithConstructor,
    problemMessage:
        """The member conflicts with constructor '${constructorName_0}'.""",
    arguments: {'constructorName': constructorName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String constructorName})>
memberConflictsWithConstructorCause = const Template(
  "MemberConflictsWithConstructorCause",
  withArguments: _withArgumentsMemberConflictsWithConstructorCause,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMemberConflictsWithConstructorCause({
  required String constructorName,
}) {
  var constructorName_0 = conversions.validateAndDemangleName(constructorName);
  return new Message(
    memberConflictsWithConstructorCause,
    problemMessage: """Conflicting constructor '${constructorName_0}'.""",
    arguments: {'constructorName': constructorName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String factoryName})>
memberConflictsWithFactory = const Template(
  "MemberConflictsWithFactory",
  withArguments: _withArgumentsMemberConflictsWithFactory,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMemberConflictsWithFactory({
  required String factoryName,
}) {
  var factoryName_0 = conversions.validateAndDemangleName(factoryName);
  return new Message(
    memberConflictsWithFactory,
    problemMessage: """The member conflicts with factory '${factoryName_0}'.""",
    arguments: {'factoryName': factoryName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String factoryName})>
memberConflictsWithFactoryCause = const Template(
  "MemberConflictsWithFactoryCause",
  withArguments: _withArgumentsMemberConflictsWithFactoryCause,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMemberConflictsWithFactoryCause({
  required String factoryName,
}) {
  var factoryName_0 = conversions.validateAndDemangleName(factoryName);
  return new Message(
    memberConflictsWithFactoryCause,
    problemMessage: """Conflicting factory '${factoryName_0}'.""",
    arguments: {'factoryName': factoryName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name})> memberNotFound =
    const Template(
      "MemberNotFound",
      withArguments: _withArgumentsMemberNotFound,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMemberNotFound({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    memberNotFound,
    problemMessage: """Member not found: '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name})>
memberShouldBeListedAsCallableInDynamicInterface = const Template(
  "MemberShouldBeListedAsCallableInDynamicInterface",
  withArguments: _withArgumentsMemberShouldBeListedAsCallableInDynamicInterface,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMemberShouldBeListedAsCallableInDynamicInterface({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    memberShouldBeListedAsCallableInDynamicInterface,
    problemMessage:
        """Cannot invoke member '${name_0}' from a dynamic module.""",
    correctionMessage:
        """Try removing the call or update the dynamic interface to list member '${name_0}' as callable.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String className, required String memberName})
>
memberShouldBeListedAsCanBeOverriddenInDynamicInterface = const Template(
  "MemberShouldBeListedAsCanBeOverriddenInDynamicInterface",
  withArguments:
      _withArgumentsMemberShouldBeListedAsCanBeOverriddenInDynamicInterface,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMemberShouldBeListedAsCanBeOverriddenInDynamicInterface({
  required String className,
  required String memberName,
}) {
  var className_0 = conversions.validateAndDemangleName(className);
  var memberName_0 = conversions.validateAndDemangleName(memberName);
  return new Message(
    memberShouldBeListedAsCanBeOverriddenInDynamicInterface,
    problemMessage:
        """Cannot override member '${className_0}.${memberName_0}' in a dynamic module.""",
    correctionMessage:
        """Try removing the override or update the dynamic interface to list member '${className_0}.${memberName_0}' as can-be-overridden.""",
    arguments: {'className': className, 'memberName': memberName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name})> methodNotFound =
    const Template(
      "MethodNotFound",
      withArguments: _withArgumentsMethodNotFound,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMethodNotFound({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    methodNotFound,
    problemMessage: """Method not found: '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode missingExplicitConst = const MessageCode(
  "MissingExplicitConst",
  problemMessage: """Constant expression expected.""",
  correctionMessage: """Try inserting 'const'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name})>
missingImplementationCause = const Template(
  "MissingImplementationCause",
  withArguments: _withArgumentsMissingImplementationCause,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMissingImplementationCause({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    missingImplementationCause,
    problemMessage: """'${name_0}' is defined here.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String className,
    required List<String> memberNames,
  })
>
missingImplementationNotAbstract = const Template(
  "MissingImplementationNotAbstract",
  withArguments: _withArgumentsMissingImplementationNotAbstract,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMissingImplementationNotAbstract({
  required String className,
  required List<String> memberNames,
}) {
  var className_0 = conversions.validateAndDemangleName(className);
  var memberNames_0 = conversions.validateAndItemizeNames(memberNames);
  return new Message(
    missingImplementationNotAbstract,
    problemMessage:
        """The non-abstract class '${className_0}' is missing implementations for these members:
${memberNames_0}""",
    correctionMessage: """Try to either
 - provide an implementation,
 - inherit an implementation from a superclass or mixin,
 - mark the class as abstract, or
 - provide a 'noSuchMethod' implementation.""",
    arguments: {'className': className, 'memberNames': memberNames},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode missingInput = const MessageCode(
  "MissingInput",
  problemMessage: """No input file provided to the compiler.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode missingMain = const MessageCode(
  "MissingMain",
  problemMessage: """No 'main' method found.""",
  correctionMessage: """Try adding a method named 'main' to your program.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode missingNamedSuperConstructorParameter = const MessageCode(
  "MissingNamedSuperConstructorParameter",
  problemMessage:
      """The super constructor has no corresponding named parameter.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required Uri uri})> missingPartOf =
    const Template("MissingPartOf", withArguments: _withArgumentsMissingPartOf);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMissingPartOf({required Uri uri}) {
  var uri_0 = conversions.relativizeUri(uri);
  return new Message(
    missingPartOf,
    problemMessage:
        """Can't use '${uri_0}' as a part, because it has no 'part of' declaration.""",
    arguments: {'uri': uri},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
missingPositionalSuperConstructorParameter = const MessageCode(
  "MissingPositionalSuperConstructorParameter",
  problemMessage:
      """The super constructor has no corresponding positional parameter.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String variableName})>
missingVariablePattern = const Template(
  "MissingVariablePattern",
  withArguments: _withArgumentsMissingVariablePattern,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMissingVariablePattern({required String variableName}) {
  var variableName_0 = conversions.validateAndDemangleName(variableName);
  return new Message(
    missingVariablePattern,
    problemMessage:
        """Variable pattern '${variableName_0}' is missing in this branch of the logical-or pattern.""",
    correctionMessage: """Try declaring this variable pattern in the branch.""",
    arguments: {'variableName': variableName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required DartType supertype,
    required DartType requiredInterfaceType,
    required DartType mixedInType,
  })
>
mixinApplicationIncompatibleSupertype = const Template(
  "MixinApplicationIncompatibleSupertype",
  withArguments: _withArgumentsMixinApplicationIncompatibleSupertype,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMixinApplicationIncompatibleSupertype({
  required DartType supertype,
  required DartType requiredInterfaceType,
  required DartType mixedInType,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var supertype_0 = labeler.labelType(supertype);
  var requiredInterfaceType_0 = labeler.labelType(requiredInterfaceType);
  var mixedInType_0 = labeler.labelType(mixedInType);
  return new Message(
    mixinApplicationIncompatibleSupertype,
    problemMessage:
        """'${supertype_0}' doesn't implement '${requiredInterfaceType_0}' so it can't be used with '${mixedInType_0}'.""" +
        labeler.originMessages,
    arguments: {
      'supertype': supertype,
      'requiredInterfaceType': requiredInterfaceType,
      'mixedInType': mixedInType,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String memberName})>
mixinApplicationNoConcreteGetter = const Template(
  "MixinApplicationNoConcreteGetter",
  withArguments: _withArgumentsMixinApplicationNoConcreteGetter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMixinApplicationNoConcreteGetter({
  required String memberName,
}) {
  var memberName_0 = conversions.validateAndDemangleName(memberName);
  return new Message(
    mixinApplicationNoConcreteGetter,
    problemMessage:
        """The class doesn't have a concrete implementation of the super-accessed member '${memberName_0}'.""",
    arguments: {'memberName': memberName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode mixinApplicationNoConcreteMemberContext = const MessageCode(
  "MixinApplicationNoConcreteMemberContext",
  severity: CfeSeverity.context,
  problemMessage:
      """This is the super-access that doesn't have a concrete target.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String memberName})>
mixinApplicationNoConcreteMethod = const Template(
  "MixinApplicationNoConcreteMethod",
  withArguments: _withArgumentsMixinApplicationNoConcreteMethod,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMixinApplicationNoConcreteMethod({
  required String memberName,
}) {
  var memberName_0 = conversions.validateAndDemangleName(memberName);
  return new Message(
    mixinApplicationNoConcreteMethod,
    problemMessage:
        """The class doesn't have a concrete implementation of the super-invoked member '${memberName_0}'.""",
    arguments: {'memberName': memberName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String memberName})>
mixinApplicationNoConcreteSetter = const Template(
  "MixinApplicationNoConcreteSetter",
  withArguments: _withArgumentsMixinApplicationNoConcreteSetter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMixinApplicationNoConcreteSetter({
  required String memberName,
}) {
  var memberName_0 = conversions.validateAndDemangleName(memberName);
  return new Message(
    mixinApplicationNoConcreteSetter,
    problemMessage:
        """The class doesn't have a concrete implementation of the super-accessed setter '${memberName_0}'.""",
    arguments: {'memberName': memberName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode mixinDeferredMixin = const MessageCode(
  "MixinDeferredMixin",
  problemMessage: """Classes can't mix in deferred mixins.""",
  correctionMessage: """Try changing the import to not be deferred.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String mixinName,
    required String baseTypeName,
    required DartType supertypeConstraint,
  })
>
mixinInferenceNoMatchingClass = const Template(
  "MixinInferenceNoMatchingClass",
  withArguments: _withArgumentsMixinInferenceNoMatchingClass,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMixinInferenceNoMatchingClass({
  required String mixinName,
  required String baseTypeName,
  required DartType supertypeConstraint,
}) {
  var mixinName_0 = conversions.validateAndDemangleName(mixinName);
  var baseTypeName_0 = conversions.validateAndDemangleName(baseTypeName);
  TypeLabeler labeler = new TypeLabeler();
  var supertypeConstraint_0 = labeler.labelType(supertypeConstraint);
  return new Message(
    mixinInferenceNoMatchingClass,
    problemMessage:
        """Type parameters couldn't be inferred for the mixin '${mixinName_0}' because '${baseTypeName_0}' does not implement the mixin's supertype constraint '${supertypeConstraint_0}'.""" +
        labeler.originMessages,
    arguments: {
      'mixinName': mixinName,
      'baseTypeName': baseTypeName,
      'supertypeConstraint': supertypeConstraint,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String className})>
mixinInheritsFromNotObject = const Template(
  "MixinInheritsFromNotObject",
  withArguments: _withArgumentsMixinInheritsFromNotObject,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMixinInheritsFromNotObject({required String className}) {
  var className_0 = conversions.validateAndDemangleName(className);
  return new Message(
    mixinInheritsFromNotObject,
    problemMessage:
        """The class '${className_0}' can't be used as a mixin because it extends a class other than 'Object'.""",
    arguments: {'className': className},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String className, required String superclassName})
>
mixinSubtypeOfBaseIsNotBase = const Template(
  "MixinSubtypeOfBaseIsNotBase",
  withArguments: _withArgumentsMixinSubtypeOfBaseIsNotBase,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMixinSubtypeOfBaseIsNotBase({
  required String className,
  required String superclassName,
}) {
  var className_0 = conversions.validateAndDemangleName(className);
  var superclassName_0 = conversions.validateAndDemangleName(superclassName);
  return new Message(
    mixinSubtypeOfBaseIsNotBase,
    problemMessage:
        """The mixin '${className_0}' must be 'base' because the supertype '${superclassName_0}' is 'base'.""",
    correctionMessage: """Try adding 'base' to the mixin.""",
    arguments: {'className': className, 'superclassName': superclassName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String typeName, required String supertypeName})
>
mixinSubtypeOfFinalIsNotBase = const Template(
  "MixinSubtypeOfFinalIsNotBase",
  withArguments: _withArgumentsMixinSubtypeOfFinalIsNotBase,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMixinSubtypeOfFinalIsNotBase({
  required String typeName,
  required String supertypeName,
}) {
  var typeName_0 = conversions.validateAndDemangleName(typeName);
  var supertypeName_0 = conversions.validateAndDemangleName(supertypeName);
  return new Message(
    mixinSubtypeOfFinalIsNotBase,
    problemMessage:
        """The mixin '${typeName_0}' must be 'base' because the supertype '${supertypeName_0}' is 'final'.""",
    correctionMessage: """Try adding 'base' to the mixin.""",
    arguments: {'typeName': typeName, 'supertypeName': supertypeName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode mixinSuperClassConstraintDeferredClass = const MessageCode(
  "MixinSuperClassConstraintDeferredClass",
  problemMessage:
      """Deferred classes can't be used as superclass constraints.""",
  correctionMessage: """Try changing the import to not be deferred.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode moreThanOneSuperInitializer = const MessageCode(
  "MoreThanOneSuperInitializer",
  problemMessage: """Can't have more than one 'super' initializer.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode multipleRepresentationFields = const MessageCode(
  "MultipleRepresentationFields",
  problemMessage:
      """Each extension type should have exactly one representation field.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name})> nameNotFound =
    const Template("NameNotFound", withArguments: _withArgumentsNameNotFound);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNameNotFound({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    nameNotFound,
    problemMessage: """Undefined name '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String fieldName, required DartType recordType})
>
nameNotFoundInRecordNameGet = const Template(
  "NameNotFoundInRecordNameGet",
  withArguments: _withArgumentsNameNotFoundInRecordNameGet,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNameNotFoundInRecordNameGet({
  required String fieldName,
  required DartType recordType,
}) {
  var fieldName_0 = conversions.validateString(fieldName);
  TypeLabeler labeler = new TypeLabeler();
  var recordType_0 = labeler.labelType(recordType);
  return new Message(
    nameNotFoundInRecordNameGet,
    problemMessage:
        """Field name ${fieldName_0} isn't found in records of type ${recordType_0}.""" +
        labeler.originMessages,
    arguments: {'fieldName': fieldName, 'recordType': recordType},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
namedFieldClashesWithPositionalFieldInRecord = const MessageCode(
  "NamedFieldClashesWithPositionalFieldInRecord",
  problemMessage:
      """Record field names can't be a dollar sign followed by an integer when integer is the index of a positional field.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String className,
    required String overriddenMemberName,
  })
>
namedMixinOverride = const Template(
  "NamedMixinOverride",
  withArguments: _withArgumentsNamedMixinOverride,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNamedMixinOverride({
  required String className,
  required String overriddenMemberName,
}) {
  var className_0 = conversions.validateAndDemangleName(className);
  var overriddenMemberName_0 = conversions.validateAndDemangleName(
    overriddenMemberName,
  );
  return new Message(
    namedMixinOverride,
    problemMessage:
        """The mixin application class '${className_0}' introduces an erroneous override of '${overriddenMemberName_0}'.""",
    arguments: {
      'className': className,
      'overriddenMemberName': overriddenMemberName,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode namedParametersInExtensionTypeDeclaration = const MessageCode(
  "NamedParametersInExtensionTypeDeclaration",
  problemMessage:
      """Extension type declarations can't have named parameters.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode negativeVariableDimension = const MessageCode(
  "NegativeVariableDimension",
  problemMessage:
      """The variable dimension of a variable-length array must be non-negative.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode neverReachableSwitchDefaultError = const MessageCode(
  "NeverReachableSwitchDefaultError",
  problemMessage:
      """`null` encountered as case in a switch expression with a non-nullable enum type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode neverReachableSwitchExpressionError = const MessageCode(
  "NeverReachableSwitchExpressionError",
  problemMessage:
      """`null` encountered as case in a switch expression with a non-nullable type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode neverReachableSwitchStatementError = const MessageCode(
  "NeverReachableSwitchStatementError",
  problemMessage:
      """`null` encountered as case in a switch statement with a non-nullable type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode neverValueError = const MessageCode(
  "NeverValueError",
  problemMessage:
      """`null` encountered as the result from expression with type `Never`.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode newAsSelector = const MessageCode(
  "NewAsSelector",
  problemMessage: """'new' can only be used as a constructor reference.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode noAugmentSuperInvokeTarget = const MessageCode(
  "NoAugmentSuperInvokeTarget",
  problemMessage: """Cannot call 'augment super'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode noAugmentSuperReadTarget = const MessageCode(
  "NoAugmentSuperReadTarget",
  problemMessage: """Cannot read from 'augment super'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode noAugmentSuperWriteTarget = const MessageCode(
  "NoAugmentSuperWriteTarget",
  problemMessage: """Cannot write to 'augment super'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name})> noSuchNamedParameter =
    const Template(
      "NoSuchNamedParameter",
      withArguments: _withArgumentsNoSuchNamedParameter,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNoSuchNamedParameter({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    noSuchNamedParameter,
    problemMessage: """No named parameter with the name '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode noUnnamedConstructorInObject = const MessageCode(
  "NoUnnamedConstructorInObject",
  problemMessage: """'Object' has no unnamed constructor.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode nonAugmentationDeclarationConflictCause = const MessageCode(
  "NonAugmentationDeclarationConflictCause",
  severity: CfeSeverity.context,
  problemMessage: """This is the existing declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode nonAugmentationMemberConflictCause = const MessageCode(
  "NonAugmentationMemberConflictCause",
  severity: CfeSeverity.context,
  problemMessage: """This is the existing member.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode nonBoolCondition = const MessageCode(
  "NonBoolCondition",
  problemMessage: """Conditions must have a static type of 'bool'.""",
  correctionMessage: """Try changing the condition.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode nonConstConstructor = const MessageCode(
  "NonConstConstructor",
  problemMessage:
      """Cannot invoke a non-'const' constructor where a const expression is expected.""",
  correctionMessage: """Try using a constructor or factory that is 'const'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode nonConstFactory = const MessageCode(
  "NonConstFactory",
  problemMessage:
      """Cannot invoke a non-'const' factory where a const expression is expected.""",
  correctionMessage: """Try using a constructor or factory that is 'const'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
nonCovariantTypeParameterInRepresentationType = const MessageCode(
  "NonCovariantTypeParameterInRepresentationType",
  problemMessage:
      """An extension type parameter can't be used non-covariantly in its representation type.""",
  correctionMessage:
      """Try removing the type parameters from function parameter types and type parameter bounds.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required DartType scrutineeType,
    required String witness,
    required String correction,
  })
>
nonExhaustiveSwitchExpression = const Template(
  "NonExhaustiveSwitchExpression",
  withArguments: _withArgumentsNonExhaustiveSwitchExpression,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonExhaustiveSwitchExpression({
  required DartType scrutineeType,
  required String witness,
  required String correction,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var scrutineeType_0 = labeler.labelType(scrutineeType);
  var witness_0 = conversions.validateString(witness);
  var correction_0 = conversions.validateString(correction);
  return new Message(
    nonExhaustiveSwitchExpression,
    problemMessage:
        """The type '${scrutineeType_0}' is not exhaustively matched by the switch cases since it doesn't match '${witness_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try adding a wildcard pattern or cases that match '${correction_0}'.""",
    arguments: {
      'scrutineeType': scrutineeType,
      'witness': witness,
      'correction': correction,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required DartType scrutineeType,
    required String witness,
    required String correction,
  })
>
nonExhaustiveSwitchStatement = const Template(
  "NonExhaustiveSwitchStatement",
  withArguments: _withArgumentsNonExhaustiveSwitchStatement,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonExhaustiveSwitchStatement({
  required DartType scrutineeType,
  required String witness,
  required String correction,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var scrutineeType_0 = labeler.labelType(scrutineeType);
  var witness_0 = conversions.validateString(witness);
  var correction_0 = conversions.validateString(correction);
  return new Message(
    nonExhaustiveSwitchStatement,
    problemMessage:
        """The type '${scrutineeType_0}' is not exhaustively matched by the switch cases since it doesn't match '${witness_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try adding a default case or cases that match '${correction_0}'.""",
    arguments: {
      'scrutineeType': scrutineeType,
      'witness': witness,
      'correction': correction,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode nonExtensionTypeMemberContext = const MessageCode(
  "NonExtensionTypeMemberContext",
  severity: CfeSeverity.context,
  problemMessage: """This is the inherited non-extension type member.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode nonExtensionTypeMemberOneOfContext = const MessageCode(
  "NonExtensionTypeMemberOneOfContext",
  severity: CfeSeverity.context,
  problemMessage:
      """This is one of the inherited non-extension type members.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required DartType spreadType})>
nonNullAwareSpreadIsNull = const Template(
  "NonNullAwareSpreadIsNull",
  withArguments: _withArgumentsNonNullAwareSpreadIsNull,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonNullAwareSpreadIsNull({required DartType spreadType}) {
  TypeLabeler labeler = new TypeLabeler();
  var spreadType_0 = labeler.labelType(spreadType);
  return new Message(
    nonNullAwareSpreadIsNull,
    problemMessage:
        """Can't spread a value with static type '${spreadType_0}'.""" +
        labeler.originMessages,
    arguments: {'spreadType': spreadType},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String variableName})>
nonNullableNotAssignedError = const Template(
  "NonNullableNotAssignedError",
  withArguments: _withArgumentsNonNullableNotAssignedError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonNullableNotAssignedError({
  required String variableName,
}) {
  var variableName_0 = conversions.validateAndDemangleName(variableName);
  return new Message(
    nonNullableNotAssignedError,
    problemMessage:
        """Non-nullable variable '${variableName_0}' must be assigned before it can be used.""",
    arguments: {'variableName': variableName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode nonPositiveArrayDimensions = const MessageCode(
  "NonPositiveArrayDimensions",
  problemMessage: """Array dimensions must be positive numbers.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String typeName})>
nonSimpleBoundViaReference = const Template(
  "NonSimpleBoundViaReference",
  withArguments: _withArgumentsNonSimpleBoundViaReference,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonSimpleBoundViaReference({required String typeName}) {
  var typeName_0 = conversions.validateAndDemangleName(typeName);
  return new Message(
    nonSimpleBoundViaReference,
    problemMessage:
        """Bound of this variable references raw type '${typeName_0}'.""",
    arguments: {'typeName': typeName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String typeName})>
nonSimpleBoundViaVariable = const Template(
  "NonSimpleBoundViaVariable",
  withArguments: _withArgumentsNonSimpleBoundViaVariable,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonSimpleBoundViaVariable({required String typeName}) {
  var typeName_0 = conversions.validateAndDemangleName(typeName);
  return new Message(
    nonSimpleBoundViaVariable,
    problemMessage:
        """Bound of this variable references variable '${typeName_0}' from the same declaration.""",
    arguments: {'typeName': typeName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode nonVoidReturnOperator = const MessageCode(
  "NonVoidReturnOperator",
  problemMessage: """The return type of the operator []= must be 'void'.""",
  correctionMessage: """Try changing the return type to 'void'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode nonVoidReturnSetter = const MessageCode(
  "NonVoidReturnSetter",
  problemMessage: """The return type of the setter must be 'void' or absent.""",
  correctionMessage:
      """Try removing the return type, or define a method rather than a setter.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode notAConstantExpression = const MessageCode(
  "NotAConstantExpression",
  problemMessage: """Not a constant expression.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String prefix, required String typeName})
>
notAPrefixInTypeAnnotation = const Template(
  "NotAPrefixInTypeAnnotation",
  withArguments: _withArgumentsNotAPrefixInTypeAnnotation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNotAPrefixInTypeAnnotation({
  required String prefix,
  required String typeName,
}) {
  var prefix_0 = conversions.validateAndDemangleName(prefix);
  var typeName_0 = conversions.validateAndDemangleName(typeName);
  return new Message(
    notAPrefixInTypeAnnotation,
    problemMessage:
        """'${prefix_0}.${typeName_0}' can't be used as a type because '${prefix_0}' doesn't refer to an import prefix.""",
    arguments: {'prefix': prefix, 'typeName': typeName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name})> notAType =
    const Template("NotAType", withArguments: _withArgumentsNotAType);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNotAType({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    notAType,
    problemMessage: """'${name_0}' isn't a type.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode notATypeContext = const MessageCode(
  "NotATypeContext",
  severity: CfeSeverity.context,
  problemMessage: """This isn't a type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode notAnLvalue = const MessageCode(
  "NotAnLvalue",
  problemMessage: """Can't assign to this.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required Token token})> notBinaryOperator =
    const Template(
      "NotBinaryOperator",
      withArguments: _withArgumentsNotBinaryOperator,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNotBinaryOperator({required Token token}) {
  var token_0 = conversions.tokenToLexeme(token);
  return new Message(
    notBinaryOperator,
    problemMessage: """'${token_0}' isn't a binary operator.""",
    arguments: {'token': token},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String description})>
notConstantExpression = const Template(
  "NotConstantExpression",
  withArguments: _withArgumentsNotConstantExpression,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNotConstantExpression({required String description}) {
  var description_0 = conversions.validateString(description);
  return new Message(
    notConstantExpression,
    problemMessage: """${description_0} is not a constant expression.""",
    arguments: {'description': description},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required DartType type})>
nullableExpressionCallError = const Template(
  "NullableExpressionCallError",
  withArguments: _withArgumentsNullableExpressionCallError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNullableExpressionCallError({required DartType type}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    nullableExpressionCallError,
    problemMessage:
        """Can't use an expression of type '${type_0}' as a function because it's potentially null.""" +
        labeler.originMessages,
    correctionMessage: """Try calling using ?.call instead.""",
    arguments: {'type': type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String interfaceName})>
nullableInterfaceError = const Template(
  "NullableInterfaceError",
  withArguments: _withArgumentsNullableInterfaceError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNullableInterfaceError({required String interfaceName}) {
  var interfaceName_0 = conversions.validateAndDemangleName(interfaceName);
  return new Message(
    nullableInterfaceError,
    problemMessage:
        """Can't implement '${interfaceName_0}' because it's nullable.""",
    correctionMessage: """Try removing the question mark.""",
    arguments: {'interfaceName': interfaceName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String methodName, required DartType receiverType})
>
nullableMethodCallError = const Template(
  "NullableMethodCallError",
  withArguments: _withArgumentsNullableMethodCallError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNullableMethodCallError({
  required String methodName,
  required DartType receiverType,
}) {
  var methodName_0 = conversions.validateAndDemangleName(methodName);
  TypeLabeler labeler = new TypeLabeler();
  var receiverType_0 = labeler.labelType(receiverType);
  return new Message(
    nullableMethodCallError,
    problemMessage:
        """Method '${methodName_0}' cannot be called on '${receiverType_0}' because it is potentially null.""" +
        labeler.originMessages,
    correctionMessage: """Try calling using ?. instead.""",
    arguments: {'methodName': methodName, 'receiverType': receiverType},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String mixinName})>
nullableMixinError = const Template(
  "NullableMixinError",
  withArguments: _withArgumentsNullableMixinError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNullableMixinError({required String mixinName}) {
  var mixinName_0 = conversions.validateAndDemangleName(mixinName);
  return new Message(
    nullableMixinError,
    problemMessage: """Can't mix '${mixinName_0}' in because it's nullable.""",
    correctionMessage: """Try removing the question mark.""",
    arguments: {'mixinName': mixinName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String operator, required DartType receiverType})
>
nullableOperatorCallError = const Template(
  "NullableOperatorCallError",
  withArguments: _withArgumentsNullableOperatorCallError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNullableOperatorCallError({
  required String operator,
  required DartType receiverType,
}) {
  var operator_0 = conversions.validateAndDemangleName(operator);
  TypeLabeler labeler = new TypeLabeler();
  var receiverType_0 = labeler.labelType(receiverType);
  return new Message(
    nullableOperatorCallError,
    problemMessage:
        """Operator '${operator_0}' cannot be called on '${receiverType_0}' because it is potentially null.""" +
        labeler.originMessages,
    arguments: {'operator': operator, 'receiverType': receiverType},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String propertyName,
    required DartType receiverType,
  })
>
nullablePropertyAccessError = const Template(
  "NullablePropertyAccessError",
  withArguments: _withArgumentsNullablePropertyAccessError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNullablePropertyAccessError({
  required String propertyName,
  required DartType receiverType,
}) {
  var propertyName_0 = conversions.validateAndDemangleName(propertyName);
  TypeLabeler labeler = new TypeLabeler();
  var receiverType_0 = labeler.labelType(receiverType);
  return new Message(
    nullablePropertyAccessError,
    problemMessage:
        """Property '${propertyName_0}' cannot be accessed on '${receiverType_0}' because it is potentially null.""" +
        labeler.originMessages,
    correctionMessage: """Try accessing using ?. instead.""",
    arguments: {'propertyName': propertyName, 'receiverType': receiverType},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode nullableSpreadError = const MessageCode(
  "NullableSpreadError",
  problemMessage:
      """An expression whose value can be 'null' must be null-checked before it can be dereferenced.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String supertypeName})>
nullableSuperclassError = const Template(
  "NullableSuperclassError",
  withArguments: _withArgumentsNullableSuperclassError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNullableSuperclassError({required String supertypeName}) {
  var supertypeName_0 = conversions.validateAndDemangleName(supertypeName);
  return new Message(
    nullableSuperclassError,
    problemMessage:
        """Can't extend '${supertypeName_0}' because it's nullable.""",
    correctionMessage: """Try removing the question mark.""",
    arguments: {'supertypeName': supertypeName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String methodName})>
nullableTearoffError = const Template(
  "NullableTearoffError",
  withArguments: _withArgumentsNullableTearoffError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNullableTearoffError({required String methodName}) {
  var methodName_0 = conversions.validateAndDemangleName(methodName);
  return new Message(
    nullableTearoffError,
    problemMessage:
        """Can't tear off method '${methodName_0}' from a potentially null value.""",
    arguments: {'methodName': methodName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode objectExtends = const MessageCode(
  "ObjectExtends",
  problemMessage: """The class 'Object' can't have a superclass.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode objectImplements = const MessageCode(
  "ObjectImplements",
  problemMessage: """The class 'Object' can't implement anything.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode objectMemberNameUsedForRecordField = const MessageCode(
  "ObjectMemberNameUsedForRecordField",
  problemMessage:
      """Record field names can't be the same as a member from 'Object'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode objectMixesIn = const MessageCode(
  "ObjectMixesIn",
  problemMessage: """The class 'Object' can't use mixins.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode obsoleteColonForDefaultValue = const MessageCode(
  "ObsoleteColonForDefaultValue",
  problemMessage:
      """Using a colon as a separator before a default value is no longer supported.""",
  correctionMessage: """Try replacing the colon with an equal sign.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String operatorName})>
operatorMinusParameterMismatch = const Template(
  "OperatorMinusParameterMismatch",
  withArguments: _withArgumentsOperatorMinusParameterMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOperatorMinusParameterMismatch({
  required String operatorName,
}) {
  var operatorName_0 = conversions.validateAndDemangleName(operatorName);
  return new Message(
    operatorMinusParameterMismatch,
    problemMessage:
        """Operator '${operatorName_0}' should have zero or one parameter.""",
    correctionMessage:
        """With zero parameters, it has the syntactic form '-a', formally known as 'unary-'. With one parameter, it has the syntactic form 'a - b', formally known as '-'.""",
    arguments: {'operatorName': operatorName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String operatorName})>
operatorParameterMismatch0 = const Template(
  "OperatorParameterMismatch0",
  withArguments: _withArgumentsOperatorParameterMismatch0,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOperatorParameterMismatch0({
  required String operatorName,
}) {
  var operatorName_0 = conversions.validateAndDemangleName(operatorName);
  return new Message(
    operatorParameterMismatch0,
    problemMessage:
        """Operator '${operatorName_0}' shouldn't have any parameters.""",
    arguments: {'operatorName': operatorName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String operatorName})>
operatorParameterMismatch1 = const Template(
  "OperatorParameterMismatch1",
  withArguments: _withArgumentsOperatorParameterMismatch1,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOperatorParameterMismatch1({
  required String operatorName,
}) {
  var operatorName_0 = conversions.validateAndDemangleName(operatorName);
  return new Message(
    operatorParameterMismatch1,
    problemMessage:
        """Operator '${operatorName_0}' should have exactly one parameter.""",
    arguments: {'operatorName': operatorName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String operatorName})>
operatorParameterMismatch2 = const Template(
  "OperatorParameterMismatch2",
  withArguments: _withArgumentsOperatorParameterMismatch2,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOperatorParameterMismatch2({
  required String operatorName,
}) {
  var operatorName_0 = conversions.validateAndDemangleName(operatorName);
  return new Message(
    operatorParameterMismatch2,
    problemMessage:
        """Operator '${operatorName_0}' should have exactly two parameters.""",
    arguments: {'operatorName': operatorName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode operatorWithOptionalFormals = const MessageCode(
  "OperatorWithOptionalFormals",
  problemMessage: """An operator can't have optional parameters.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String parameterName,
    required DartType parameterType,
  })
>
optionalNonNullableWithoutInitializerError = const Template(
  "OptionalNonNullableWithoutInitializerError",
  withArguments: _withArgumentsOptionalNonNullableWithoutInitializerError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOptionalNonNullableWithoutInitializerError({
  required String parameterName,
  required DartType parameterType,
}) {
  var parameterName_0 = conversions.validateAndDemangleName(parameterName);
  TypeLabeler labeler = new TypeLabeler();
  var parameterType_0 = labeler.labelType(parameterType);
  return new Message(
    optionalNonNullableWithoutInitializerError,
    problemMessage:
        """The parameter '${parameterName_0}' can't have a value of 'null' because of its type '${parameterType_0}', but the implicit default value is 'null'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try adding either an explicit non-'null' default value or the 'required' modifier.""",
    arguments: {'parameterName': parameterName, 'parameterType': parameterType},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode optionalParametersInExtensionTypeDeclaration =
    const MessageCode(
      "OptionalParametersInExtensionTypeDeclaration",
      problemMessage:
          """Extension type declarations can't have optional parameters.""",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required DartType superParameterType,
    required String superParameterName,
  })
>
optionalSuperParameterWithoutInitializer = const Template(
  "OptionalSuperParameterWithoutInitializer",
  withArguments: _withArgumentsOptionalSuperParameterWithoutInitializer,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOptionalSuperParameterWithoutInitializer({
  required DartType superParameterType,
  required String superParameterName,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var superParameterType_0 = labeler.labelType(superParameterType);
  var superParameterName_0 = conversions.validateAndDemangleName(
    superParameterName,
  );
  return new Message(
    optionalSuperParameterWithoutInitializer,
    problemMessage:
        """Type '${superParameterType_0}' of the optional super-initializer parameter '${superParameterName_0}' doesn't allow 'null', but the parameter doesn't have a default value, and the default value can't be copied from the corresponding parameter of the super constructor.""" +
        labeler.originMessages,
    arguments: {
      'superParameterType': superParameterType,
      'superParameterName': superParameterName,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String methodName})>
overriddenMethodCause = const Template(
  "OverriddenMethodCause",
  withArguments: _withArgumentsOverriddenMethodCause,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverriddenMethodCause({required String methodName}) {
  var methodName_0 = conversions.validateAndDemangleName(methodName);
  return new Message(
    overriddenMethodCause,
    problemMessage: """This is the overridden method ('${methodName_0}').""",
    arguments: {'methodName': methodName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String declaredMemberName,
    required String overriddenMemberName,
  })
>
overrideFewerNamedArguments = const Template(
  "OverrideFewerNamedArguments",
  withArguments: _withArgumentsOverrideFewerNamedArguments,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideFewerNamedArguments({
  required String declaredMemberName,
  required String overriddenMemberName,
}) {
  var declaredMemberName_0 = conversions.validateAndDemangleName(
    declaredMemberName,
  );
  var overriddenMemberName_0 = conversions.validateAndDemangleName(
    overriddenMemberName,
  );
  return new Message(
    overrideFewerNamedArguments,
    problemMessage:
        """The method '${declaredMemberName_0}' has fewer named arguments than those of overridden method '${overriddenMemberName_0}'.""",
    arguments: {
      'declaredMemberName': declaredMemberName,
      'overriddenMemberName': overriddenMemberName,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String declaredMemberName,
    required String overriddenMemberName,
  })
>
overrideFewerPositionalArguments = const Template(
  "OverrideFewerPositionalArguments",
  withArguments: _withArgumentsOverrideFewerPositionalArguments,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideFewerPositionalArguments({
  required String declaredMemberName,
  required String overriddenMemberName,
}) {
  var declaredMemberName_0 = conversions.validateAndDemangleName(
    declaredMemberName,
  );
  var overriddenMemberName_0 = conversions.validateAndDemangleName(
    overriddenMemberName,
  );
  return new Message(
    overrideFewerPositionalArguments,
    problemMessage:
        """The method '${declaredMemberName_0}' has fewer positional arguments than those of overridden method '${overriddenMemberName_0}'.""",
    arguments: {
      'declaredMemberName': declaredMemberName,
      'overriddenMemberName': overriddenMemberName,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String declaredMemberName,
    required String parameterName,
    required String overriddenMemberName,
  })
>
overrideMismatchNamedParameter = const Template(
  "OverrideMismatchNamedParameter",
  withArguments: _withArgumentsOverrideMismatchNamedParameter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideMismatchNamedParameter({
  required String declaredMemberName,
  required String parameterName,
  required String overriddenMemberName,
}) {
  var declaredMemberName_0 = conversions.validateAndDemangleName(
    declaredMemberName,
  );
  var parameterName_0 = conversions.validateAndDemangleName(parameterName);
  var overriddenMemberName_0 = conversions.validateAndDemangleName(
    overriddenMemberName,
  );
  return new Message(
    overrideMismatchNamedParameter,
    problemMessage:
        """The method '${declaredMemberName_0}' doesn't have the named parameter '${parameterName_0}' of overridden method '${overriddenMemberName_0}'.""",
    arguments: {
      'declaredMemberName': declaredMemberName,
      'parameterName': parameterName,
      'overriddenMemberName': overriddenMemberName,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String parameterName,
    required String declaredMemberName,
    required String overriddenMemberName,
  })
>
overrideMismatchRequiredNamedParameter = const Template(
  "OverrideMismatchRequiredNamedParameter",
  withArguments: _withArgumentsOverrideMismatchRequiredNamedParameter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideMismatchRequiredNamedParameter({
  required String parameterName,
  required String declaredMemberName,
  required String overriddenMemberName,
}) {
  var parameterName_0 = conversions.validateAndDemangleName(parameterName);
  var declaredMemberName_0 = conversions.validateAndDemangleName(
    declaredMemberName,
  );
  var overriddenMemberName_0 = conversions.validateAndDemangleName(
    overriddenMemberName,
  );
  return new Message(
    overrideMismatchRequiredNamedParameter,
    problemMessage:
        """The required named parameter '${parameterName_0}' in method '${declaredMemberName_0}' is not required in overridden method '${overriddenMemberName_0}'.""",
    arguments: {
      'parameterName': parameterName,
      'declaredMemberName': declaredMemberName,
      'overriddenMemberName': overriddenMemberName,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String declaredMemberName,
    required String overriddenMemberName,
  })
>
overrideMoreRequiredArguments = const Template(
  "OverrideMoreRequiredArguments",
  withArguments: _withArgumentsOverrideMoreRequiredArguments,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideMoreRequiredArguments({
  required String declaredMemberName,
  required String overriddenMemberName,
}) {
  var declaredMemberName_0 = conversions.validateAndDemangleName(
    declaredMemberName,
  );
  var overriddenMemberName_0 = conversions.validateAndDemangleName(
    overriddenMemberName,
  );
  return new Message(
    overrideMoreRequiredArguments,
    problemMessage:
        """The method '${declaredMemberName_0}' has more required arguments than those of overridden method '${overriddenMemberName_0}'.""",
    arguments: {
      'declaredMemberName': declaredMemberName,
      'overriddenMemberName': overriddenMemberName,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String parameterName,
    required String declaredMemberName,
    required DartType declaredType,
    required DartType overriddenType,
    required String overriddenMemberName,
  })
>
overrideTypeMismatchParameter = const Template(
  "OverrideTypeMismatchParameter",
  withArguments: _withArgumentsOverrideTypeMismatchParameter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideTypeMismatchParameter({
  required String parameterName,
  required String declaredMemberName,
  required DartType declaredType,
  required DartType overriddenType,
  required String overriddenMemberName,
}) {
  var parameterName_0 = conversions.validateAndDemangleName(parameterName);
  var declaredMemberName_0 = conversions.validateAndDemangleName(
    declaredMemberName,
  );
  TypeLabeler labeler = new TypeLabeler();
  var declaredType_0 = labeler.labelType(declaredType);
  var overriddenType_0 = labeler.labelType(overriddenType);
  var overriddenMemberName_0 = conversions.validateAndDemangleName(
    overriddenMemberName,
  );
  return new Message(
    overrideTypeMismatchParameter,
    problemMessage:
        """The parameter '${parameterName_0}' of the method '${declaredMemberName_0}' has type '${declaredType_0}', which does not match the corresponding type, '${overriddenType_0}', in the overridden method, '${overriddenMemberName_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Change to a supertype of '${overriddenType_0}', or, for a covariant parameter, a subtype.""",
    arguments: {
      'parameterName': parameterName,
      'declaredMemberName': declaredMemberName,
      'declaredType': declaredType,
      'overriddenType': overriddenType,
      'overriddenMemberName': overriddenMemberName,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String declaredMemberName,
    required DartType declaredType,
    required DartType overriddenType,
    required String overriddenMemberName,
  })
>
overrideTypeMismatchReturnType = const Template(
  "OverrideTypeMismatchReturnType",
  withArguments: _withArgumentsOverrideTypeMismatchReturnType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideTypeMismatchReturnType({
  required String declaredMemberName,
  required DartType declaredType,
  required DartType overriddenType,
  required String overriddenMemberName,
}) {
  var declaredMemberName_0 = conversions.validateAndDemangleName(
    declaredMemberName,
  );
  TypeLabeler labeler = new TypeLabeler();
  var declaredType_0 = labeler.labelType(declaredType);
  var overriddenType_0 = labeler.labelType(overriddenType);
  var overriddenMemberName_0 = conversions.validateAndDemangleName(
    overriddenMemberName,
  );
  return new Message(
    overrideTypeMismatchReturnType,
    problemMessage:
        """The return type of the method '${declaredMemberName_0}' is '${declaredType_0}', which does not match the return type, '${overriddenType_0}', of the overridden method, '${overriddenMemberName_0}'.""" +
        labeler.originMessages,
    correctionMessage: """Change to a subtype of '${overriddenType_0}'.""",
    arguments: {
      'declaredMemberName': declaredMemberName,
      'declaredType': declaredType,
      'overriddenType': overriddenType,
      'overriddenMemberName': overriddenMemberName,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String declaredMemberName,
    required DartType declaredType,
    required DartType overriddenType,
    required String overriddenMemberName,
  })
>
overrideTypeMismatchSetter = const Template(
  "OverrideTypeMismatchSetter",
  withArguments: _withArgumentsOverrideTypeMismatchSetter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideTypeMismatchSetter({
  required String declaredMemberName,
  required DartType declaredType,
  required DartType overriddenType,
  required String overriddenMemberName,
}) {
  var declaredMemberName_0 = conversions.validateAndDemangleName(
    declaredMemberName,
  );
  TypeLabeler labeler = new TypeLabeler();
  var declaredType_0 = labeler.labelType(declaredType);
  var overriddenType_0 = labeler.labelType(overriddenType);
  var overriddenMemberName_0 = conversions.validateAndDemangleName(
    overriddenMemberName,
  );
  return new Message(
    overrideTypeMismatchSetter,
    problemMessage:
        """The field '${declaredMemberName_0}' has type '${declaredType_0}', which does not match the corresponding type, '${overriddenType_0}', in the overridden setter, '${overriddenMemberName_0}'.""" +
        labeler.originMessages,
    arguments: {
      'declaredMemberName': declaredMemberName,
      'declaredType': declaredType,
      'overriddenType': overriddenType,
      'overriddenMemberName': overriddenMemberName,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required DartType declaredBoundType,
    required String typeVariableName,
    required String declaredMemberName,
    required DartType overriddenBoundType,
    required String overriddenMemberName,
  })
>
overrideTypeParametersBoundMismatch = const Template(
  "OverrideTypeParametersBoundMismatch",
  withArguments: _withArgumentsOverrideTypeParametersBoundMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideTypeParametersBoundMismatch({
  required DartType declaredBoundType,
  required String typeVariableName,
  required String declaredMemberName,
  required DartType overriddenBoundType,
  required String overriddenMemberName,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var declaredBoundType_0 = labeler.labelType(declaredBoundType);
  var typeVariableName_0 = conversions.validateAndDemangleName(
    typeVariableName,
  );
  var declaredMemberName_0 = conversions.validateAndDemangleName(
    declaredMemberName,
  );
  var overriddenBoundType_0 = labeler.labelType(overriddenBoundType);
  var overriddenMemberName_0 = conversions.validateAndDemangleName(
    overriddenMemberName,
  );
  return new Message(
    overrideTypeParametersBoundMismatch,
    problemMessage:
        """Declared bound '${declaredBoundType_0}' of type variable '${typeVariableName_0}' of '${declaredMemberName_0}' doesn't match the bound '${overriddenBoundType_0}' on overridden method '${overriddenMemberName_0}'.""" +
        labeler.originMessages,
    arguments: {
      'declaredBoundType': declaredBoundType,
      'typeVariableName': typeVariableName,
      'declaredMemberName': declaredMemberName,
      'overriddenBoundType': overriddenBoundType,
      'overriddenMemberName': overriddenMemberName,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String declaredMemberName,
    required String overriddenMemberName,
  })
>
overrideTypeParametersMismatch = const Template(
  "OverrideTypeParametersMismatch",
  withArguments: _withArgumentsOverrideTypeParametersMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideTypeParametersMismatch({
  required String declaredMemberName,
  required String overriddenMemberName,
}) {
  var declaredMemberName_0 = conversions.validateAndDemangleName(
    declaredMemberName,
  );
  var overriddenMemberName_0 = conversions.validateAndDemangleName(
    overriddenMemberName,
  );
  return new Message(
    overrideTypeParametersMismatch,
    problemMessage:
        """Declared type variables of '${declaredMemberName_0}' doesn't match those on overridden method '${overriddenMemberName_0}'.""",
    arguments: {
      'declaredMemberName': declaredMemberName,
      'overriddenMemberName': overriddenMemberName,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String packageName, required Uri uri})
>
packageNotFound = const Template(
  "PackageNotFound",
  withArguments: _withArgumentsPackageNotFound,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsPackageNotFound({
  required String packageName,
  required Uri uri,
}) {
  var packageName_0 = conversions.validateAndDemangleName(packageName);
  var uri_0 = conversions.relativizeUri(uri);
  return new Message(
    packageNotFound,
    problemMessage:
        """Couldn't resolve the package '${packageName_0}' in '${uri_0}'.""",
    arguments: {'packageName': packageName, 'uri': uri},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String details})> packagesFileFormat =
    const Template(
      "PackagesFileFormat",
      withArguments: _withArgumentsPackagesFileFormat,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsPackagesFileFormat({required String details}) {
  var details_0 = conversions.validateString(details);
  return new Message(
    packagesFileFormat,
    problemMessage: """Problem in packages configuration file: ${details_0}""",
    arguments: {'details': details},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode partExport = const MessageCode(
  "PartExport",
  problemMessage:
      """Can't export this file because it contains a 'part of' declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode partExportContext = const MessageCode(
  "PartExportContext",
  severity: CfeSeverity.context,
  problemMessage: """This is the file that can't be exported.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode partInPart = const MessageCode(
  "PartInPart",
  problemMessage:
      """A file that's a part of a library can't have parts itself.""",
  correctionMessage:
      """Try moving the 'part' declaration to the containing library.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode partInPartLibraryContext = const MessageCode(
  "PartInPartLibraryContext",
  severity: CfeSeverity.context,
  problemMessage: """This is the containing library.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required Uri uri})> partOfInLibrary =
    const Template(
      "PartOfInLibrary",
      withArguments: _withArgumentsPartOfInLibrary,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsPartOfInLibrary({required Uri uri}) {
  var uri_0 = conversions.relativizeUri(uri);
  return new Message(
    partOfInLibrary,
    problemMessage:
        """Can't import '${uri_0}', because it has a 'part of' declaration.""",
    correctionMessage:
        """Try removing the 'part of' declaration, or using '${uri_0}' as a part.""",
    arguments: {'uri': uri},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required Uri uri,
    required String libraryName,
    required String partOfName,
  })
>
partOfLibraryNameMismatch = const Template(
  "PartOfLibraryNameMismatch",
  withArguments: _withArgumentsPartOfLibraryNameMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsPartOfLibraryNameMismatch({
  required Uri uri,
  required String libraryName,
  required String partOfName,
}) {
  var uri_0 = conversions.relativizeUri(uri);
  var libraryName_0 = conversions.validateAndDemangleName(libraryName);
  var partOfName_0 = conversions.validateAndDemangleName(partOfName);
  return new Message(
    partOfLibraryNameMismatch,
    problemMessage:
        """Using '${uri_0}' as part of '${libraryName_0}' but its 'part of' declaration says '${partOfName_0}'.""",
    arguments: {
      'uri': uri,
      'libraryName': libraryName,
      'partOfName': partOfName,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode partOfName = const MessageCode(
  "PartOfName",
  problemMessage:
      """The 'part of' directive can't use a name with the enhanced-parts feature.""",
  correctionMessage: """Try using 'part of' with a URI instead.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode partOfSelf = const MessageCode(
  "PartOfSelf",
  problemMessage: """A file can't be a part of itself.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode partOfTwoLibraries = const MessageCode(
  "PartOfTwoLibraries",
  problemMessage: """A file can't be part of more than one library.""",
  correctionMessage:
      """Try moving the shared declarations into the libraries, or into a new library.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode partOfTwoLibrariesContext = const MessageCode(
  "PartOfTwoLibrariesContext",
  severity: CfeSeverity.context,
  problemMessage: """Used as a part in this library.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required Uri partUri,
    required Uri libraryUri,
    required Uri partOfUri,
  })
>
partOfUriMismatch = const Template(
  "PartOfUriMismatch",
  withArguments: _withArgumentsPartOfUriMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsPartOfUriMismatch({
  required Uri partUri,
  required Uri libraryUri,
  required Uri partOfUri,
}) {
  var partUri_0 = conversions.relativizeUri(partUri);
  var libraryUri_0 = conversions.relativizeUri(libraryUri);
  var partOfUri_0 = conversions.relativizeUri(partOfUri);
  return new Message(
    partOfUriMismatch,
    problemMessage:
        """Using '${partUri_0}' as part of '${libraryUri_0}' but its 'part of' declaration says '${partOfUri_0}'.""",
    arguments: {
      'partUri': partUri,
      'libraryUri': libraryUri,
      'partOfUri': partOfUri,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required Uri partFileUri,
    required Uri libraryUri,
    required String partOfName,
  })
>
partOfUseUri = const Template(
  "PartOfUseUri",
  withArguments: _withArgumentsPartOfUseUri,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsPartOfUseUri({
  required Uri partFileUri,
  required Uri libraryUri,
  required String partOfName,
}) {
  var partFileUri_0 = conversions.relativizeUri(partFileUri);
  var libraryUri_0 = conversions.relativizeUri(libraryUri);
  var partOfName_0 = conversions.validateAndDemangleName(partOfName);
  return new Message(
    partOfUseUri,
    problemMessage:
        """Using '${partFileUri_0}' as part of '${libraryUri_0}' but its 'part of' declaration says '${partOfName_0}'.""",
    correctionMessage:
        """Try changing the 'part of' declaration to use a relative file name.""",
    arguments: {
      'partFileUri': partFileUri,
      'libraryUri': libraryUri,
      'partOfName': partOfName,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode partOrphan = const MessageCode(
  "PartOrphan",
  problemMessage: """This part doesn't have a containing library.""",
  correctionMessage: """Try removing the 'part of' declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required Uri uri})> partTwice = const Template(
  "PartTwice",
  withArguments: _withArgumentsPartTwice,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsPartTwice({required Uri uri}) {
  var uri_0 = conversions.relativizeUri(uri);
  return new Message(
    partTwice,
    problemMessage: """Can't use '${uri_0}' as a part more than once.""",
    arguments: {'uri': uri},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode partWithLibraryDirective = const MessageCode(
  "PartWithLibraryDirective",
  problemMessage: """A part cannot have a library directive.""",
  correctionMessage: """Try removing the library directive.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode patchClassOrigin = const MessageCode(
  "PatchClassOrigin",
  severity: CfeSeverity.context,
  problemMessage: """This is the origin class.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode patchClassTypeParametersMismatch = const MessageCode(
  "PatchClassTypeParametersMismatch",
  problemMessage:
      """A patch class must have the same number of type variables as its origin class.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode patchDeclarationOrigin = const MessageCode(
  "PatchDeclarationOrigin",
  severity: CfeSeverity.context,
  problemMessage: """This is the origin declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode patchExtensionOrigin = const MessageCode(
  "PatchExtensionOrigin",
  severity: CfeSeverity.context,
  problemMessage: """This is the origin extension.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode patchExtensionTypeParametersMismatch = const MessageCode(
  "PatchExtensionTypeParametersMismatch",
  problemMessage:
      """A patch extension must have the same number of type variables as its origin extension.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name, required Uri uri})>
patchInjectionFailed = const Template(
  "PatchInjectionFailed",
  withArguments: _withArgumentsPatchInjectionFailed,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsPatchInjectionFailed({
  required String name,
  required Uri uri,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var uri_0 = conversions.relativizeUri(uri);
  return new Message(
    patchInjectionFailed,
    problemMessage: """Can't inject public '${name_0}' into '${uri_0}'.""",
    correctionMessage:
        """Make '${name_0}' private, or make sure injected library has "dart" scheme and is private (e.g. "dart:_internal").""",
    arguments: {'name': name, 'uri': uri},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode patternAssignmentNotLocalVariable = const MessageCode(
  "PatternAssignmentNotLocalVariable",
  problemMessage:
      """Only local variables or formal parameters can be used in pattern assignments.""",
  correctionMessage: """Try assigning to a local variable.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode patternMatchingError = const MessageCode(
  "PatternMatchingError",
  problemMessage: """Pattern matching error""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required DartType actualType,
    required DartType expectedType,
  })
>
patternTypeMismatchInIrrefutableContext = const Template(
  "PatternTypeMismatchInIrrefutableContext",
  withArguments: _withArgumentsPatternTypeMismatchInIrrefutableContext,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsPatternTypeMismatchInIrrefutableContext({
  required DartType actualType,
  required DartType expectedType,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var actualType_0 = labeler.labelType(actualType);
  var expectedType_0 = labeler.labelType(expectedType);
  return new Message(
    patternTypeMismatchInIrrefutableContext,
    problemMessage:
        """The matched value of type '${actualType_0}' isn't assignable to the required type '${expectedType_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try changing the required type of the pattern, or the matched value type.""",
    arguments: {'actualType': actualType, 'expectedType': expectedType},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode patternVariableAssignmentInsideGuard = const MessageCode(
  "PatternVariableAssignmentInsideGuard",
  problemMessage:
      """Pattern variables can't be assigned inside the guard of the enclosing guarded pattern.""",
  correctionMessage: """Try assigning to a different variable.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode platformPrivateLibraryAccess = const MessageCode(
  "PlatformPrivateLibraryAccess",
  problemMessage: """Can't access platform private library.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode positionalSuperParametersAndArguments = const MessageCode(
  "PositionalSuperParametersAndArguments",
  problemMessage:
      """Positional super-initializer parameters cannot be used when the super initializer has positional arguments.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name})>
privateNamedParameterDuplicatePublicName = const Template(
  "PrivateNamedParameterDuplicatePublicName",
  withArguments: _withArgumentsPrivateNamedParameterDuplicatePublicName,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsPrivateNamedParameterDuplicatePublicName({
  required String name,
}) {
  var name_0 = conversions.validateString(name);
  return new Message(
    privateNamedParameterDuplicatePublicName,
    problemMessage:
        """The corresponding public name '${name_0}' is already the name of another parameter.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode privateNamedParameterWithoutPublicName = const MessageCode(
  "PrivateNamedParameterWithoutPublicName",
  problemMessage:
      """A private named parameter must have a corresponding public name.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode recordFieldsCantBePrivate = const MessageCode(
  "RecordFieldsCantBePrivate",
  problemMessage: """Record field names can't be private.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode recordUseCannotBePlacedHere = const MessageCode(
  "RecordUseCannotBePlacedHere",
  problemMessage:
      """`RecordUse` annotation cannot be placed on this element.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode recordUseOutsideOfPackage = const MessageCode(
  "RecordUseOutsideOfPackage",
  problemMessage:
      """`RecordUse` annotations are only supported in libraries with a `package:` URI.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode recordUsedAsCallable = const MessageCode(
  "RecordUsedAsCallable",
  problemMessage:
      """The 'call' property on the record type isn't directly callable but could be invoked by `.call(...)`""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode redirectingConstructorWithAnotherInitializer =
    const MessageCode(
      "RedirectingConstructorWithAnotherInitializer",
      problemMessage:
          """A redirecting constructor can't have other initializers.""",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode redirectingConstructorWithMultipleRedirectInitializers =
    const MessageCode(
      "RedirectingConstructorWithMultipleRedirectInitializers",
      problemMessage:
          """A redirecting constructor can't have more than one redirection.""",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode redirectingConstructorWithSuperInitializer =
    const MessageCode(
      "RedirectingConstructorWithSuperInitializer",
      problemMessage:
          """A redirecting constructor can't have a 'super' initializer.""",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required DartType typeArgumentType,
    required DartType expectedType,
  })
>
redirectingFactoryIncompatibleTypeArgument = const Template(
  "RedirectingFactoryIncompatibleTypeArgument",
  withArguments: _withArgumentsRedirectingFactoryIncompatibleTypeArgument,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsRedirectingFactoryIncompatibleTypeArgument({
  required DartType typeArgumentType,
  required DartType expectedType,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var typeArgumentType_0 = labeler.labelType(typeArgumentType);
  var expectedType_0 = labeler.labelType(expectedType);
  return new Message(
    redirectingFactoryIncompatibleTypeArgument,
    problemMessage:
        """The type '${typeArgumentType_0}' doesn't extend '${expectedType_0}'.""" +
        labeler.originMessages,
    correctionMessage: """Try using a different type as argument.""",
    arguments: {
      'typeArgumentType': typeArgumentType,
      'expectedType': expectedType,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name})>
redirectionTargetNotFound = const Template(
  "RedirectionTargetNotFound",
  withArguments: _withArgumentsRedirectionTargetNotFound,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsRedirectionTargetNotFound({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    redirectionTargetNotFound,
    problemMessage: """Redirection constructor target not found: '${name_0}'""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode refutablePatternInIrrefutableContext = const MessageCode(
  "RefutablePatternInIrrefutableContext",
  problemMessage:
      """Refutable patterns can't be used in an irrefutable context.""",
  correctionMessage:
      """Try using an if-case, a 'switch' statement, or a 'switch' expression instead.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode representationFieldModifier = const MessageCode(
  "RepresentationFieldModifier",
  problemMessage: """Representation fields can't have modifiers.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode representationFieldTrailingComma = const MessageCode(
  "RepresentationFieldTrailingComma",
  problemMessage: """The representation field can't have a trailing comma.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String parameterName})>
requiredNamedParameterHasDefaultValueError = const Template(
  "RequiredNamedParameterHasDefaultValueError",
  withArguments: _withArgumentsRequiredNamedParameterHasDefaultValueError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsRequiredNamedParameterHasDefaultValueError({
  required String parameterName,
}) {
  var parameterName_0 = conversions.validateAndDemangleName(parameterName);
  return new Message(
    requiredNamedParameterHasDefaultValueError,
    problemMessage:
        """Named parameter '${parameterName_0}' is required and can't have a default value.""",
    arguments: {'parameterName': parameterName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode restPatternInMapPattern = const MessageCode(
  "RestPatternInMapPattern",
  problemMessage: """The '...' pattern can't appear in map patterns.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode rethrowNotCatch = const MessageCode(
  "RethrowNotCatch",
  problemMessage: """'rethrow' can only be used in catch clauses.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode returnFromVoidFunction = const MessageCode(
  "ReturnFromVoidFunction",
  problemMessage: """Can't return a value from a void function.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode returnWithoutExpressionAsync = const MessageCode(
  "ReturnWithoutExpressionAsync",
  problemMessage:
      """A value must be explicitly returned from a non-void async function.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode returnWithoutExpressionSync = const MessageCode(
  "ReturnWithoutExpressionSync",
  problemMessage:
      """A value must be explicitly returned from a non-void function.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode scriptTagInPartFile = const MessageCode(
  "ScriptTagInPartFile",
  problemMessage: """A part file cannot have script tag.""",
  correctionMessage:
      """Try removing the script tag or the 'part of' directive.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required Uri uri})> sdkRootNotFound =
    const Template(
      "SdkRootNotFound",
      withArguments: _withArgumentsSdkRootNotFound,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSdkRootNotFound({required Uri uri}) {
  var uri_0 = conversions.relativizeUri(uri);
  return new Message(
    sdkRootNotFound,
    problemMessage: """SDK root directory not found: ${uri_0}.""",
    arguments: {'uri': uri},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required Uri uri})> sdkSpecificationNotFound =
    const Template(
      "SdkSpecificationNotFound",
      withArguments: _withArgumentsSdkSpecificationNotFound,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSdkSpecificationNotFound({required Uri uri}) {
  var uri_0 = conversions.relativizeUri(uri);
  return new Message(
    sdkSpecificationNotFound,
    problemMessage: """SDK libraries specification not found: ${uri_0}.""",
    correctionMessage:
        """Normally, the specification is a file named 'libraries.json' in the Dart SDK install location.""",
    arguments: {'uri': uri},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required Uri uri})> sdkSummaryNotFound =
    const Template(
      "SdkSummaryNotFound",
      withArguments: _withArgumentsSdkSummaryNotFound,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSdkSummaryNotFound({required Uri uri}) {
  var uri_0 = conversions.relativizeUri(uri);
  return new Message(
    sdkSummaryNotFound,
    problemMessage: """SDK summary not found: ${uri_0}.""",
    arguments: {'uri': uri},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String sealedClassName})>
sealedClassSubtypeOutsideOfLibrary = const Template(
  "SealedClassSubtypeOutsideOfLibrary",
  withArguments: _withArgumentsSealedClassSubtypeOutsideOfLibrary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSealedClassSubtypeOutsideOfLibrary({
  required String sealedClassName,
}) {
  var sealedClassName_0 = conversions.validateAndDemangleName(sealedClassName);
  return new Message(
    sealedClassSubtypeOutsideOfLibrary,
    problemMessage:
        """The class '${sealedClassName_0}' can't be extended, implemented, or mixed in outside of its library because it's a sealed class.""",
    arguments: {'sealedClassName': sealedClassName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String setterName})>
setterConflictsWithDeclaration = const Template(
  "SetterConflictsWithDeclaration",
  withArguments: _withArgumentsSetterConflictsWithDeclaration,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSetterConflictsWithDeclaration({
  required String setterName,
}) {
  var setterName_0 = conversions.validateAndDemangleName(setterName);
  return new Message(
    setterConflictsWithDeclaration,
    problemMessage:
        """The setter conflicts with declaration '${setterName_0}'.""",
    arguments: {'setterName': setterName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String setterName})>
setterConflictsWithDeclarationCause = const Template(
  "SetterConflictsWithDeclarationCause",
  withArguments: _withArgumentsSetterConflictsWithDeclarationCause,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSetterConflictsWithDeclarationCause({
  required String setterName,
}) {
  var setterName_0 = conversions.validateAndDemangleName(setterName);
  return new Message(
    setterConflictsWithDeclarationCause,
    problemMessage: """Conflicting declaration '${setterName_0}'.""",
    arguments: {'setterName': setterName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name})> setterNotFound =
    const Template(
      "SetterNotFound",
      withArguments: _withArgumentsSetterNotFound,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSetterNotFound({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    setterNotFound,
    problemMessage: """Setter not found: '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode setterWithWrongNumberOfFormals = const MessageCode(
  "SetterWithWrongNumberOfFormals",
  problemMessage: """A setter should have exactly one formal parameter.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required int count,
    required int bytes,
    required num timeMs,
    required num rateBytesPerMs,
    required num averageTimeMs,
  })
>
sourceBodySummary = const Template(
  "SourceBodySummary",
  withArguments: _withArgumentsSourceBodySummary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSourceBodySummary({
  required int count,
  required int bytes,
  required num timeMs,
  required num rateBytesPerMs,
  required num averageTimeMs,
}) {
  var timeMs_0 = conversions.formatNumber(
    timeMs,
    fractionDigits: 3,
    padWidth: 0,
    padWithZeros: false,
  );
  var rateBytesPerMs_0 = conversions.formatNumber(
    rateBytesPerMs,
    fractionDigits: 3,
    padWidth: 12,
    padWithZeros: false,
  );
  var averageTimeMs_0 = conversions.formatNumber(
    averageTimeMs,
    fractionDigits: 3,
    padWidth: 12,
    padWithZeros: false,
  );
  return new Message(
    sourceBodySummary,
    problemMessage:
        """Built bodies for ${count} compilation units (${bytes} bytes) in ${timeMs_0}ms, that is,
${rateBytesPerMs_0} bytes/ms, and
${averageTimeMs_0} ms/compilation unit.""",
    arguments: {
      'count': count,
      'bytes': bytes,
      'timeMs': timeMs,
      'rateBytesPerMs': rateBytesPerMs,
      'averageTimeMs': averageTimeMs,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required int count,
    required int bytes,
    required num timeMs,
    required num rateBytesPerMs,
    required num averageTimeMs,
  })
>
sourceOutlineSummary = const Template(
  "SourceOutlineSummary",
  withArguments: _withArgumentsSourceOutlineSummary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSourceOutlineSummary({
  required int count,
  required int bytes,
  required num timeMs,
  required num rateBytesPerMs,
  required num averageTimeMs,
}) {
  var timeMs_0 = conversions.formatNumber(
    timeMs,
    fractionDigits: 3,
    padWidth: 0,
    padWithZeros: false,
  );
  var rateBytesPerMs_0 = conversions.formatNumber(
    rateBytesPerMs,
    fractionDigits: 3,
    padWidth: 12,
    padWithZeros: false,
  );
  var averageTimeMs_0 = conversions.formatNumber(
    averageTimeMs,
    fractionDigits: 3,
    padWidth: 12,
    padWithZeros: false,
  );
  return new Message(
    sourceOutlineSummary,
    problemMessage:
        """Built outlines for ${count} compilation units (${bytes} bytes) in ${timeMs_0}ms, that is,
${rateBytesPerMs_0} bytes/ms, and
${averageTimeMs_0} ms/compilation unit.""",
    arguments: {
      'count': count,
      'bytes': bytes,
      'timeMs': timeMs,
      'rateBytesPerMs': rateBytesPerMs,
      'averageTimeMs': averageTimeMs,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode spreadElement = const MessageCode(
  "SpreadElement",
  severity: CfeSeverity.context,
  problemMessage: """Iterable spread.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required DartType spreadElementType,
    required DartType collectionElementType,
  })
>
spreadElementTypeMismatch = const Template(
  "SpreadElementTypeMismatch",
  withArguments: _withArgumentsSpreadElementTypeMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSpreadElementTypeMismatch({
  required DartType spreadElementType,
  required DartType collectionElementType,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var spreadElementType_0 = labeler.labelType(spreadElementType);
  var collectionElementType_0 = labeler.labelType(collectionElementType);
  return new Message(
    spreadElementTypeMismatch,
    problemMessage:
        """Can't assign spread elements of type '${spreadElementType_0}' to collection elements of type '${collectionElementType_0}'.""" +
        labeler.originMessages,
    arguments: {
      'spreadElementType': spreadElementType,
      'collectionElementType': collectionElementType,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode spreadMapElement = const MessageCode(
  "SpreadMapElement",
  severity: CfeSeverity.context,
  problemMessage: """Map spread.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required DartType spreadKeyType,
    required DartType mapKeyType,
  })
>
spreadMapEntryElementKeyTypeMismatch = const Template(
  "SpreadMapEntryElementKeyTypeMismatch",
  withArguments: _withArgumentsSpreadMapEntryElementKeyTypeMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSpreadMapEntryElementKeyTypeMismatch({
  required DartType spreadKeyType,
  required DartType mapKeyType,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var spreadKeyType_0 = labeler.labelType(spreadKeyType);
  var mapKeyType_0 = labeler.labelType(mapKeyType);
  return new Message(
    spreadMapEntryElementKeyTypeMismatch,
    problemMessage:
        """Can't assign spread entry keys of type '${spreadKeyType_0}' to map entry keys of type '${mapKeyType_0}'.""" +
        labeler.originMessages,
    arguments: {'spreadKeyType': spreadKeyType, 'mapKeyType': mapKeyType},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required DartType spreadValueType,
    required DartType mapValueType,
  })
>
spreadMapEntryElementValueTypeMismatch = const Template(
  "SpreadMapEntryElementValueTypeMismatch",
  withArguments: _withArgumentsSpreadMapEntryElementValueTypeMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSpreadMapEntryElementValueTypeMismatch({
  required DartType spreadValueType,
  required DartType mapValueType,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var spreadValueType_0 = labeler.labelType(spreadValueType);
  var mapValueType_0 = labeler.labelType(mapValueType);
  return new Message(
    spreadMapEntryElementValueTypeMismatch,
    problemMessage:
        """Can't assign spread entry values of type '${spreadValueType_0}' to map entry values of type '${mapValueType_0}'.""" +
        labeler.originMessages,
    arguments: {
      'spreadValueType': spreadValueType,
      'mapValueType': mapValueType,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required DartType spreadType})>
spreadMapEntryTypeMismatch = const Template(
  "SpreadMapEntryTypeMismatch",
  withArguments: _withArgumentsSpreadMapEntryTypeMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSpreadMapEntryTypeMismatch({
  required DartType spreadType,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var spreadType_0 = labeler.labelType(spreadType);
  return new Message(
    spreadMapEntryTypeMismatch,
    problemMessage:
        """Unexpected type '${spreadType_0}' of a map spread entry.  Expected 'dynamic' or a Map.""" +
        labeler.originMessages,
    arguments: {'spreadType': spreadType},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required DartType spreadType})>
spreadTypeMismatch = const Template(
  "SpreadTypeMismatch",
  withArguments: _withArgumentsSpreadTypeMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSpreadTypeMismatch({required DartType spreadType}) {
  TypeLabeler labeler = new TypeLabeler();
  var spreadType_0 = labeler.labelType(spreadType);
  return new Message(
    spreadTypeMismatch,
    problemMessage:
        """Unexpected type '${spreadType_0}' of a spread.  Expected 'dynamic' or an Iterable.""" +
        labeler.originMessages,
    arguments: {'spreadType': spreadType},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String propertyName})>
staticConflictsWithInstance = const Template(
  "StaticConflictsWithInstance",
  withArguments: _withArgumentsStaticConflictsWithInstance,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsStaticConflictsWithInstance({
  required String propertyName,
}) {
  var propertyName_0 = conversions.validateAndDemangleName(propertyName);
  return new Message(
    staticConflictsWithInstance,
    problemMessage:
        """Static property '${propertyName_0}' conflicts with instance property of the same name.""",
    arguments: {'propertyName': propertyName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String propertyName})>
staticConflictsWithInstanceCause = const Template(
  "StaticConflictsWithInstanceCause",
  withArguments: _withArgumentsStaticConflictsWithInstanceCause,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsStaticConflictsWithInstanceCause({
  required String propertyName,
}) {
  var propertyName_0 = conversions.validateAndDemangleName(propertyName);
  return new Message(
    staticConflictsWithInstanceCause,
    problemMessage: """Conflicting instance property '${propertyName_0}'.""",
    arguments: {'propertyName': propertyName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode staticTearOffFromInstantiatedClass = const MessageCode(
  "StaticTearOffFromInstantiatedClass",
  problemMessage:
      """Cannot access static member on an instantiated generic class.""",
  correctionMessage:
      """Try removing the type arguments or placing them after the member name.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String className, required String superclassName})
>
subtypeOfBaseIsNotBaseFinalOrSealed = const Template(
  "SubtypeOfBaseIsNotBaseFinalOrSealed",
  withArguments: _withArgumentsSubtypeOfBaseIsNotBaseFinalOrSealed,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSubtypeOfBaseIsNotBaseFinalOrSealed({
  required String className,
  required String superclassName,
}) {
  var className_0 = conversions.validateAndDemangleName(className);
  var superclassName_0 = conversions.validateAndDemangleName(superclassName);
  return new Message(
    subtypeOfBaseIsNotBaseFinalOrSealed,
    problemMessage:
        """The type '${className_0}' must be 'base', 'final' or 'sealed' because the supertype '${superclassName_0}' is 'base'.""",
    correctionMessage:
        """Try adding 'base', 'final', or 'sealed' to the type.""",
    arguments: {'className': className, 'superclassName': superclassName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String typeName, required String supertypeName})
>
subtypeOfFinalIsNotBaseFinalOrSealed = const Template(
  "SubtypeOfFinalIsNotBaseFinalOrSealed",
  withArguments: _withArgumentsSubtypeOfFinalIsNotBaseFinalOrSealed,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSubtypeOfFinalIsNotBaseFinalOrSealed({
  required String typeName,
  required String supertypeName,
}) {
  var typeName_0 = conversions.validateAndDemangleName(typeName);
  var supertypeName_0 = conversions.validateAndDemangleName(supertypeName);
  return new Message(
    subtypeOfFinalIsNotBaseFinalOrSealed,
    problemMessage:
        """The type '${typeName_0}' must be 'base', 'final' or 'sealed' because the supertype '${supertypeName_0}' is 'final'.""",
    correctionMessage:
        """Try adding 'base', 'final', or 'sealed' to the type.""",
    arguments: {'typeName': typeName, 'supertypeName': supertypeName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode superAsExpression = const MessageCode(
  "SuperAsExpression",
  problemMessage: """Can't use 'super' as an expression.""",
  correctionMessage:
      """To delegate a constructor to a super constructor, put the super call as an initializer.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode superAsIdentifier = const MessageCode(
  "SuperAsIdentifier",
  problemMessage: """Expected identifier, but got 'super'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required DartType attemptedType,
    required DartType invertedType,
  })
>
superBoundedHint = const Template(
  "SuperBoundedHint",
  withArguments: _withArgumentsSuperBoundedHint,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperBoundedHint({
  required DartType attemptedType,
  required DartType invertedType,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var attemptedType_0 = labeler.labelType(attemptedType);
  var invertedType_0 = labeler.labelType(invertedType);
  return new Message(
    superBoundedHint,
    problemMessage:
        """If you want '${attemptedType_0}' to be a super-bounded type, note that the inverted type '${invertedType_0}' must then satisfy its bounds, which it does not.""" +
        labeler.originMessages,
    arguments: {'attemptedType': attemptedType, 'invertedType': invertedType},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String typeName})>
superExtensionTypeIsIllegal = const Template(
  "SuperExtensionTypeIsIllegal",
  withArguments: _withArgumentsSuperExtensionTypeIsIllegal,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperExtensionTypeIsIllegal({required String typeName}) {
  var typeName_0 = conversions.validateAndDemangleName(typeName);
  return new Message(
    superExtensionTypeIsIllegal,
    problemMessage:
        """The type '${typeName_0}' can't be implemented by an extension type.""",
    arguments: {'typeName': typeName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String typeName, required DartType aliasedType})
>
superExtensionTypeIsIllegalAliased = const Template(
  "SuperExtensionTypeIsIllegalAliased",
  withArguments: _withArgumentsSuperExtensionTypeIsIllegalAliased,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperExtensionTypeIsIllegalAliased({
  required String typeName,
  required DartType aliasedType,
}) {
  var typeName_0 = conversions.validateAndDemangleName(typeName);
  TypeLabeler labeler = new TypeLabeler();
  var aliasedType_0 = labeler.labelType(aliasedType);
  return new Message(
    superExtensionTypeIsIllegalAliased,
    problemMessage:
        """The type '${typeName_0}' which is an alias of '${aliasedType_0}' can't be implemented by an extension type.""" +
        labeler.originMessages,
    arguments: {'typeName': typeName, 'aliasedType': aliasedType},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String typeName, required DartType aliasedType})
>
superExtensionTypeIsNullableAliased = const Template(
  "SuperExtensionTypeIsNullableAliased",
  withArguments: _withArgumentsSuperExtensionTypeIsNullableAliased,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperExtensionTypeIsNullableAliased({
  required String typeName,
  required DartType aliasedType,
}) {
  var typeName_0 = conversions.validateAndDemangleName(typeName);
  TypeLabeler labeler = new TypeLabeler();
  var aliasedType_0 = labeler.labelType(aliasedType);
  return new Message(
    superExtensionTypeIsNullableAliased,
    problemMessage:
        """The type '${typeName_0}' which is an alias of '${aliasedType_0}' can't be implemented by an extension type because it is nullable.""" +
        labeler.originMessages,
    arguments: {'typeName': typeName, 'aliasedType': aliasedType},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String typeName})>
superExtensionTypeIsTypeParameter = const Template(
  "SuperExtensionTypeIsTypeParameter",
  withArguments: _withArgumentsSuperExtensionTypeIsTypeParameter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperExtensionTypeIsTypeParameter({
  required String typeName,
}) {
  var typeName_0 = conversions.validateAndDemangleName(typeName);
  return new Message(
    superExtensionTypeIsTypeParameter,
    problemMessage:
        """The type variable '${typeName_0}' can't be implemented by an extension type.""",
    arguments: {'typeName': typeName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode superInitializerNotLast = const MessageCode(
  "SuperInitializerNotLast",
  problemMessage: """Can't have initializers after 'super'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode superInitializerParameter = const MessageCode(
  "SuperInitializerParameter",
  severity: CfeSeverity.context,
  problemMessage: """This is the super-initializer parameter.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
superParameterInitializerOutsideConstructor = const MessageCode(
  "SuperParameterInitializerOutsideConstructor",
  problemMessage:
      """Super-initializer formal parameters can only be used in generative constructors.""",
  correctionMessage: """Try removing 'super.'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String constructorName})>
superclassHasNoConstructor = const Template(
  "SuperclassHasNoConstructor",
  withArguments: _withArgumentsSuperclassHasNoConstructor,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperclassHasNoConstructor({
  required String constructorName,
}) {
  var constructorName_0 = conversions.validateAndDemangleName(constructorName);
  return new Message(
    superclassHasNoConstructor,
    problemMessage:
        """Superclass has no constructor named '${constructorName_0}'.""",
    arguments: {'constructorName': constructorName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String className})>
superclassHasNoDefaultConstructor = const Template(
  "SuperclassHasNoDefaultConstructor",
  withArguments: _withArgumentsSuperclassHasNoDefaultConstructor,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperclassHasNoDefaultConstructor({
  required String className,
}) {
  var className_0 = conversions.validateAndDemangleName(className);
  return new Message(
    superclassHasNoDefaultConstructor,
    problemMessage:
        """The superclass, '${className_0}', has no unnamed constructor that takes no arguments.""",
    arguments: {'className': className},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String getterName})>
superclassHasNoGetter = const Template(
  "SuperclassHasNoGetter",
  withArguments: _withArgumentsSuperclassHasNoGetter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperclassHasNoGetter({required String getterName}) {
  var getterName_0 = conversions.validateAndDemangleName(getterName);
  return new Message(
    superclassHasNoGetter,
    problemMessage: """Superclass has no getter named '${getterName_0}'.""",
    arguments: {'getterName': getterName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String memberName})>
superclassHasNoMember = const Template(
  "SuperclassHasNoMember",
  withArguments: _withArgumentsSuperclassHasNoMember,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperclassHasNoMember({required String memberName}) {
  var memberName_0 = conversions.validateAndDemangleName(memberName);
  return new Message(
    superclassHasNoMember,
    problemMessage: """Superclass has no member named '${memberName_0}'.""",
    arguments: {'memberName': memberName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name})> superclassHasNoMethod =
    const Template(
      "SuperclassHasNoMethod",
      withArguments: _withArgumentsSuperclassHasNoMethod,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperclassHasNoMethod({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    superclassHasNoMethod,
    problemMessage: """Superclass has no method named '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String setterName})>
superclassHasNoSetter = const Template(
  "SuperclassHasNoSetter",
  withArguments: _withArgumentsSuperclassHasNoSetter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperclassHasNoSetter({required String setterName}) {
  var setterName_0 = conversions.validateAndDemangleName(setterName);
  return new Message(
    superclassHasNoSetter,
    problemMessage: """Superclass has no setter named '${setterName_0}'.""",
    arguments: {'setterName': setterName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode supertypeIsFunction = const MessageCode(
  "SupertypeIsFunction",
  problemMessage: """Can't use a function type as supertype.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String typeName})>
supertypeIsIllegal = const Template(
  "SupertypeIsIllegal",
  withArguments: _withArgumentsSupertypeIsIllegal,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSupertypeIsIllegal({required String typeName}) {
  var typeName_0 = conversions.validateAndDemangleName(typeName);
  return new Message(
    supertypeIsIllegal,
    problemMessage: """The type '${typeName_0}' can't be used as supertype.""",
    arguments: {'typeName': typeName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String typeName, required DartType aliasedType})
>
supertypeIsIllegalAliased = const Template(
  "SupertypeIsIllegalAliased",
  withArguments: _withArgumentsSupertypeIsIllegalAliased,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSupertypeIsIllegalAliased({
  required String typeName,
  required DartType aliasedType,
}) {
  var typeName_0 = conversions.validateAndDemangleName(typeName);
  TypeLabeler labeler = new TypeLabeler();
  var aliasedType_0 = labeler.labelType(aliasedType);
  return new Message(
    supertypeIsIllegalAliased,
    problemMessage:
        """The type '${typeName_0}' which is an alias of '${aliasedType_0}' can't be used as supertype.""" +
        labeler.originMessages,
    arguments: {'typeName': typeName, 'aliasedType': aliasedType},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String typeName, required DartType aliasedType})
>
supertypeIsNullableAliased = const Template(
  "SupertypeIsNullableAliased",
  withArguments: _withArgumentsSupertypeIsNullableAliased,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSupertypeIsNullableAliased({
  required String typeName,
  required DartType aliasedType,
}) {
  var typeName_0 = conversions.validateAndDemangleName(typeName);
  TypeLabeler labeler = new TypeLabeler();
  var aliasedType_0 = labeler.labelType(aliasedType);
  return new Message(
    supertypeIsNullableAliased,
    problemMessage:
        """The type '${typeName_0}' which is an alias of '${aliasedType_0}' can't be used as supertype because it is nullable.""" +
        labeler.originMessages,
    arguments: {'typeName': typeName, 'aliasedType': aliasedType},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String typeName})>
supertypeIsTypeParameter = const Template(
  "SupertypeIsTypeParameter",
  withArguments: _withArgumentsSupertypeIsTypeParameter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSupertypeIsTypeParameter({required String typeName}) {
  var typeName_0 = conversions.validateAndDemangleName(typeName);
  return new Message(
    supertypeIsTypeParameter,
    problemMessage:
        """The type variable '${typeName_0}' can't be used as supertype.""",
    arguments: {'typeName': typeName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode switchCaseFallThrough = const MessageCode(
  "SwitchCaseFallThrough",
  problemMessage: """Switch case may fall through to the next case.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode switchExpressionNotAssignableCause = const MessageCode(
  "SwitchExpressionNotAssignableCause",
  severity: CfeSeverity.context,
  problemMessage: """The switch expression is here.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required DartType caseExpressionType,
    required DartType scrutineeType,
  })
>
switchExpressionNotSubtype = const Template(
  "SwitchExpressionNotSubtype",
  withArguments: _withArgumentsSwitchExpressionNotSubtype,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSwitchExpressionNotSubtype({
  required DartType caseExpressionType,
  required DartType scrutineeType,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var caseExpressionType_0 = labeler.labelType(caseExpressionType);
  var scrutineeType_0 = labeler.labelType(scrutineeType);
  return new Message(
    switchExpressionNotSubtype,
    problemMessage:
        """Type '${caseExpressionType_0}' of the case expression is not a subtype of type '${scrutineeType_0}' of this switch expression.""" +
        labeler.originMessages,
    arguments: {
      'caseExpressionType': caseExpressionType,
      'scrutineeType': scrutineeType,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode syntheticToken = const MessageCode(
  "SyntheticToken",
  problemMessage: """This couldn't be parsed.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name})>
thisAccessInFieldInitializer = const Template(
  "ThisAccessInFieldInitializer",
  withArguments: _withArgumentsThisAccessInFieldInitializer,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsThisAccessInFieldInitializer({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    thisAccessInFieldInitializer,
    problemMessage:
        """Can't access 'this' in a field initializer to read '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode thisAsIdentifier = const MessageCode(
  "ThisAsIdentifier",
  problemMessage: """Expected identifier, but got 'this'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String documentationUrl})>
thisNotPromoted = const Template(
  "ThisNotPromoted",
  withArguments: _withArgumentsThisNotPromoted,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsThisNotPromoted({required String documentationUrl}) {
  var documentationUrl_0 = conversions.validateString(documentationUrl);
  return new Message(
    thisNotPromoted,
    problemMessage: """'this' can't be promoted.""",
    correctionMessage: """See ${documentationUrl_0}""",
    arguments: {'documentationUrl': documentationUrl},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String string})>
thisOrSuperAccessInFieldInitializer = const Template(
  "ThisOrSuperAccessInFieldInitializer",
  withArguments: _withArgumentsThisOrSuperAccessInFieldInitializer,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsThisOrSuperAccessInFieldInitializer({
  required String string,
}) {
  var string_0 = conversions.validateString(string);
  return new Message(
    thisOrSuperAccessInFieldInitializer,
    problemMessage: """Can't access '${string_0}' in a field initializer.""",
    arguments: {'string': string},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required DartType thrownType})>
throwingNotAssignableToObjectError = const Template(
  "ThrowingNotAssignableToObjectError",
  withArguments: _withArgumentsThrowingNotAssignableToObjectError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsThrowingNotAssignableToObjectError({
  required DartType thrownType,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var thrownType_0 = labeler.labelType(thrownType);
  return new Message(
    throwingNotAssignableToObjectError,
    problemMessage:
        """Can't throw a value of '${thrownType_0}' since it is neither dynamic nor non-nullable.""" +
        labeler.originMessages,
    arguments: {'thrownType': thrownType},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required int requiredParameterCount,
    required int actualArgumentCount,
  })
>
tooFewArguments = const Template(
  "TooFewArguments",
  withArguments: _withArgumentsTooFewArguments,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsTooFewArguments({
  required int requiredParameterCount,
  required int actualArgumentCount,
}) {
  return new Message(
    tooFewArguments,
    problemMessage:
        """Too few positional arguments: ${requiredParameterCount} required, ${actualArgumentCount} given.""",
    arguments: {
      'requiredParameterCount': requiredParameterCount,
      'actualArgumentCount': actualArgumentCount,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required int allowedParameterCount,
    required int actualArgumentCount,
  })
>
tooManyArguments = const Template(
  "TooManyArguments",
  withArguments: _withArgumentsTooManyArguments,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsTooManyArguments({
  required int allowedParameterCount,
  required int actualArgumentCount,
}) {
  return new Message(
    tooManyArguments,
    problemMessage:
        """Too many positional arguments: ${allowedParameterCount} allowed, but ${actualArgumentCount} found.""",
    correctionMessage: """Try removing the extra positional arguments.""",
    arguments: {
      'allowedParameterCount': allowedParameterCount,
      'actualArgumentCount': actualArgumentCount,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required int expectedCount})>
typeArgumentMismatch = const Template(
  "TypeArgumentMismatch",
  withArguments: _withArgumentsTypeArgumentMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsTypeArgumentMismatch({required int expectedCount}) {
  return new Message(
    typeArgumentMismatch,
    problemMessage: """Expected ${expectedCount} type arguments.""",
    arguments: {'expectedCount': expectedCount},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name})> typeNotFound =
    const Template("TypeNotFound", withArguments: _withArgumentsTypeNotFound);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsTypeNotFound({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    typeNotFound,
    problemMessage: """Type '${name_0}' not found.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name, required Uri uri})>
typeOrigin = const Template(
  "TypeOrigin",
  withArguments: _withArgumentsTypeOrigin,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsTypeOrigin({required String name, required Uri uri}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var uri_0 = conversions.relativizeUri(uri);
  return new Message(
    typeOrigin,
    problemMessage: """'${name_0}' is from '${uri_0}'.""",
    arguments: {'name': name, 'uri': uri},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String name,
    required Uri importUri,
    required Uri fileUri,
  })
>
typeOriginWithFileUri = const Template(
  "TypeOriginWithFileUri",
  withArguments: _withArgumentsTypeOriginWithFileUri,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsTypeOriginWithFileUri({
  required String name,
  required Uri importUri,
  required Uri fileUri,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var importUri_0 = conversions.relativizeUri(importUri);
  var fileUri_0 = conversions.relativizeUri(fileUri);
  return new Message(
    typeOriginWithFileUri,
    problemMessage:
        """'${name_0}' is from '${importUri_0}' ('${fileUri_0}').""",
    arguments: {'name': name, 'importUri': importUri, 'fileUri': fileUri},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode typeParameterDuplicatedName = const MessageCode(
  "TypeParameterDuplicatedName",
  problemMessage: """A type variable can't have the same name as another.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String typeVariableName})>
typeParameterDuplicatedNameCause = const Template(
  "TypeParameterDuplicatedNameCause",
  withArguments: _withArgumentsTypeParameterDuplicatedNameCause,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsTypeParameterDuplicatedNameCause({
  required String typeVariableName,
}) {
  var typeVariableName_0 = conversions.validateAndDemangleName(
    typeVariableName,
  );
  return new Message(
    typeParameterDuplicatedNameCause,
    problemMessage:
        """The other type variable named '${typeVariableName_0}'.""",
    arguments: {'typeVariableName': typeVariableName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode typeParameterSameNameAsEnclosing = const MessageCode(
  "TypeParameterSameNameAsEnclosing",
  problemMessage:
      """A type variable can't have the same name as its enclosing declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode typeVariableInConstantContext = const MessageCode(
  "TypeVariableInConstantContext",
  problemMessage: """Type variables can't be used as constants.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode typeVariableInStaticContext = const MessageCode(
  "TypeVariableInStaticContext",
  problemMessage: """Type variables can't be used in static members.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode typedefCause = const MessageCode(
  "TypedefCause",
  severity: CfeSeverity.context,
  problemMessage: """The issue arises via this type alias.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode typedefNotFunction = const MessageCode(
  "TypedefNotFunction",
  problemMessage: """Can't create typedef from non-function type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode typedefNotType = const MessageCode(
  "TypedefNotType",
  problemMessage: """Can't create typedef from non-type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode typedefNullableType = const MessageCode(
  "TypedefNullableType",
  problemMessage: """Can't create typedef from nullable type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode typedefTypeParameterNotConstructor = const MessageCode(
  "TypedefTypeParameterNotConstructor",
  problemMessage:
      """Can't use a typedef denoting a type variable as a constructor, nor for a static member access.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode typedefTypeParameterNotConstructorCause = const MessageCode(
  "TypedefTypeParameterNotConstructorCause",
  severity: CfeSeverity.context,
  problemMessage: """This is the type variable ultimately denoted.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode typedefUnaliasedTypeCause = const MessageCode(
  "TypedefUnaliasedTypeCause",
  severity: CfeSeverity.context,
  problemMessage: """This is the type denoted by the type alias.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required Uri uri})> unavailableDartLibrary =
    const Template(
      "UnavailableDartLibrary",
      withArguments: _withArgumentsUnavailableDartLibrary,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnavailableDartLibrary({required Uri uri}) {
  var uri_0 = conversions.relativizeUri(uri);
  return new Message(
    unavailableDartLibrary,
    problemMessage:
        """Dart library '${uri_0}' is not available on this platform.""",
    arguments: {'uri': uri},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name, required DartType type})>
undefinedGetter = const Template(
  "UndefinedGetter",
  withArguments: _withArgumentsUndefinedGetter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUndefinedGetter({
  required String name,
  required DartType type,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    undefinedGetter,
    problemMessage:
        """The getter '${name_0}' isn't defined for the type '${type_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try correcting the name to the name of an existing getter, or defining a getter or field named '${name_0}'.""",
    arguments: {'name': name, 'type': type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name, required DartType type})>
undefinedMethod = const Template(
  "UndefinedMethod",
  withArguments: _withArgumentsUndefinedMethod,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUndefinedMethod({
  required String name,
  required DartType type,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    undefinedMethod,
    problemMessage:
        """The method '${name_0}' isn't defined for the type '${type_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try correcting the name to the name of an existing method, or defining a method named '${name_0}'.""",
    arguments: {'name': name, 'type': type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name, required DartType type})>
undefinedOperator = const Template(
  "UndefinedOperator",
  withArguments: _withArgumentsUndefinedOperator,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUndefinedOperator({
  required String name,
  required DartType type,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    undefinedOperator,
    problemMessage:
        """The operator '${name_0}' isn't defined for the type '${type_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try correcting the operator to an existing operator, or defining a '${name_0}' operator.""",
    arguments: {'name': name, 'type': type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name, required DartType type})>
undefinedSetter = const Template(
  "UndefinedSetter",
  withArguments: _withArgumentsUndefinedSetter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUndefinedSetter({
  required String name,
  required DartType type,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    undefinedSetter,
    problemMessage:
        """The setter '${name_0}' isn't defined for the type '${type_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try correcting the name to the name of an existing setter, or defining a setter or field named '${name_0}'.""",
    arguments: {'name': name, 'type': type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
unexpectedSuperParametersInGenerativeConstructors = const MessageCode(
  "UnexpectedSuperParametersInGenerativeConstructors",
  problemMessage:
      """Super parameters can only be used in non-redirecting generative constructors.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String className})>
unmatchedAugmentationClass = const Template(
  "UnmatchedAugmentationClass",
  withArguments: _withArgumentsUnmatchedAugmentationClass,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnmatchedAugmentationClass({required String className}) {
  var className_0 = conversions.validateAndDemangleName(className);
  return new Message(
    unmatchedAugmentationClass,
    problemMessage:
        """Augmentation class '${className_0}' doesn't match a class in the augmented library.""",
    correctionMessage:
        """Try changing the name to an existing class or removing the 'augment' modifier.""",
    arguments: {'className': className},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String memberName})>
unmatchedAugmentationClassMember = const Template(
  "UnmatchedAugmentationClassMember",
  withArguments: _withArgumentsUnmatchedAugmentationClassMember,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnmatchedAugmentationClassMember({
  required String memberName,
}) {
  var memberName_0 = conversions.validateAndDemangleName(memberName);
  return new Message(
    unmatchedAugmentationClassMember,
    problemMessage:
        """Augmentation member '${memberName_0}' doesn't match a member in the augmented class.""",
    correctionMessage:
        """Try changing the name to an existing member or removing the 'augment' modifier.""",
    arguments: {'memberName': memberName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String declarationName})>
unmatchedAugmentationDeclaration = const Template(
  "UnmatchedAugmentationDeclaration",
  withArguments: _withArgumentsUnmatchedAugmentationDeclaration,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnmatchedAugmentationDeclaration({
  required String declarationName,
}) {
  var declarationName_0 = conversions.validateAndDemangleName(declarationName);
  return new Message(
    unmatchedAugmentationDeclaration,
    problemMessage:
        """Augmentation '${declarationName_0}' doesn't match a declaration in the augmented library.""",
    correctionMessage:
        """Try changing the name to an existing declaration or removing the 'augment' modifier.""",
    arguments: {'declarationName': declarationName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String memberName})>
unmatchedAugmentationLibraryMember = const Template(
  "UnmatchedAugmentationLibraryMember",
  withArguments: _withArgumentsUnmatchedAugmentationLibraryMember,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnmatchedAugmentationLibraryMember({
  required String memberName,
}) {
  var memberName_0 = conversions.validateAndDemangleName(memberName);
  return new Message(
    unmatchedAugmentationLibraryMember,
    problemMessage:
        """Augmentation member '${memberName_0}' doesn't match a member in the augmented library.""",
    correctionMessage:
        """Try changing the name to an existing member or removing the 'augment' modifier.""",
    arguments: {'memberName': memberName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String className})>
unmatchedPatchClass = const Template(
  "UnmatchedPatchClass",
  withArguments: _withArgumentsUnmatchedPatchClass,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnmatchedPatchClass({required String className}) {
  var className_0 = conversions.validateAndDemangleName(className);
  return new Message(
    unmatchedPatchClass,
    problemMessage:
        """Patch class '${className_0}' doesn't match a class in the origin library.""",
    correctionMessage:
        """Try changing the name to an existing class or removing the '@patch' annotation.""",
    arguments: {'className': className},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String memberName})>
unmatchedPatchClassMember = const Template(
  "UnmatchedPatchClassMember",
  withArguments: _withArgumentsUnmatchedPatchClassMember,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnmatchedPatchClassMember({required String memberName}) {
  var memberName_0 = conversions.validateAndDemangleName(memberName);
  return new Message(
    unmatchedPatchClassMember,
    problemMessage:
        """Patch member '${memberName_0}' doesn't match a member in the origin class.""",
    correctionMessage:
        """Try changing the name to an existing member or removing the '@patch' annotation.""",
    arguments: {'memberName': memberName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String declarationName})>
unmatchedPatchDeclaration = const Template(
  "UnmatchedPatchDeclaration",
  withArguments: _withArgumentsUnmatchedPatchDeclaration,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnmatchedPatchDeclaration({
  required String declarationName,
}) {
  var declarationName_0 = conversions.validateAndDemangleName(declarationName);
  return new Message(
    unmatchedPatchDeclaration,
    problemMessage:
        """Patch '${declarationName_0}' doesn't match a declaration in the origin library.""",
    correctionMessage:
        """Try changing the name to an existing declaration or removing the '@patch' annotation.""",
    arguments: {'declarationName': declarationName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String memberName})>
unmatchedPatchLibraryMember = const Template(
  "UnmatchedPatchLibraryMember",
  withArguments: _withArgumentsUnmatchedPatchLibraryMember,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnmatchedPatchLibraryMember({
  required String memberName,
}) {
  var memberName_0 = conversions.validateAndDemangleName(memberName);
  return new Message(
    unmatchedPatchLibraryMember,
    problemMessage:
        """Patch member '${memberName_0}' doesn't match a member in the origin library.""",
    correctionMessage:
        """Try changing the name to an existing member or removing the '@patch' annotation.""",
    arguments: {'memberName': memberName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode unnamedObjectPatternField = const MessageCode(
  "UnnamedObjectPatternField",
  problemMessage: """A pattern field in an object pattern must be named.""",
  correctionMessage: """Try adding a pattern name or ':' before the pattern.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode unsoundSwitchExpressionError = const MessageCode(
  "UnsoundSwitchExpressionError",
  problemMessage:
      """None of the patterns in the switch expression the matched input value. See https://github.com/dart-lang/language/issues/3488 for details.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode unsoundSwitchStatementError = const MessageCode(
  "UnsoundSwitchStatementError",
  problemMessage:
      """None of the patterns in the exhaustive switch statement the matched input value. See https://github.com/dart-lang/language/issues/3488 for details.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode unspecifiedGetterNameInObjectPattern = const MessageCode(
  "UnspecifiedGetterNameInObjectPattern",
  problemMessage:
      """The getter name is not specified explicitly, and the pattern is not a variable. Try specifying the getter name explicitly, or using a variable pattern.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode unsupportedDartExt = const MessageCode(
  "UnsupportedDartExt",
  problemMessage: """Dart native extensions are no longer supported.""",
  correctionMessage:
      """Migrate to using FFI instead (https://dart.dev/guides/libraries/c-interop)""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required Uri uri})>
unsupportedPlatformDartLibraryImport = const Template(
  "UnsupportedPlatformDartLibraryImport",
  withArguments: _withArgumentsUnsupportedPlatformDartLibraryImport,
  severity: CfeSeverity.warning,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnsupportedPlatformDartLibraryImport({required Uri uri}) {
  var uri_0 = conversions.relativizeUri(uri);
  return new Message(
    unsupportedPlatformDartLibraryImport,
    problemMessage:
        """Using stub implementations for APIs in platform-specific Dart library
'${uri_0}', which will throw 'UnsupportedError' if invoked.""",
    arguments: {'uri': uri},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode unterminatedToken = const MessageCode(
  "UnterminatedToken",
  problemMessage: """Incomplete token.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required Uri uri})> untranslatableUri =
    const Template(
      "UntranslatableUri",
      withArguments: _withArgumentsUntranslatableUri,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUntranslatableUri({required Uri uri}) {
  var uri_0 = conversions.relativizeUri(uri);
  return new Message(
    untranslatableUri,
    problemMessage: """Not found: '${uri_0}'""",
    arguments: {'uri': uri},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String parameterName})>
valueForRequiredParameterNotProvidedError = const Template(
  "ValueForRequiredParameterNotProvidedError",
  withArguments: _withArgumentsValueForRequiredParameterNotProvidedError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsValueForRequiredParameterNotProvidedError({
  required String parameterName,
}) {
  var parameterName_0 = conversions.validateAndDemangleName(parameterName);
  return new Message(
    valueForRequiredParameterNotProvidedError,
    problemMessage:
        """Required named parameter '${parameterName_0}' must be provided.""",
    arguments: {'parameterName': parameterName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String variableName,
    required String documentationUrl,
  })
>
variableCouldBeNullDueToWrite = const Template(
  "VariableCouldBeNullDueToWrite",
  withArguments: _withArgumentsVariableCouldBeNullDueToWrite,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsVariableCouldBeNullDueToWrite({
  required String variableName,
  required String documentationUrl,
}) {
  var variableName_0 = conversions.validateAndDemangleName(variableName);
  var documentationUrl_0 = conversions.validateString(documentationUrl);
  return new Message(
    variableCouldBeNullDueToWrite,
    problemMessage:
        """Variable '${variableName_0}' could not be promoted due to an assignment.""",
    correctionMessage:
        """Try null checking the variable after the assignment.  See ${documentationUrl_0}""",
    arguments: {
      'variableName': variableName,
      'documentationUrl': documentationUrl,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode verificationErrorOriginContext = const MessageCode(
  "VerificationErrorOriginContext",
  severity: CfeSeverity.context,
  problemMessage:
      """The node most likely is taken from here by a transformer.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode voidExpression = const MessageCode(
  "VoidExpression",
  problemMessage: """This expression has type 'void' and can't be used.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode wasmExternInvalidLoad = const MessageCode(
  "WasmExternInvalidLoad",
  problemMessage:
      """WebAssembly elements may only be referenced to directly call a method on them.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode wasmExternInvalidTarget = const MessageCode(
  "WasmExternInvalidTarget",
  problemMessage:
      """The receiver of this call must be a top-level variable describing the WebAssembly element.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode wasmExternMemoryMissingAnnotation = const MessageCode(
  "WasmExternMemoryMissingAnnotation",
  problemMessage:
      """This external getter returns a memory instance, but no annotation describing it was found""",
  correctionMessage:
      """Try adding a `@MemoryType()` or `@Import.memory()` annotation.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode wasmImportOrExportInUserCode = const MessageCode(
  "WasmImportOrExportInUserCode",
  problemMessage:
      """Pragmas `wasm:import` and `wasm:export` are for internal use only and cannot be used by user code.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode wasmIntrinsicTearOff = const MessageCode(
  "WasmIntrinsicTearOff",
  problemMessage: """This intrinsic extension member may not be torn off.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode weakReferenceMismatchReturnAndArgumentTypes =
    const MessageCode(
      "WeakReferenceMismatchReturnAndArgumentTypes",
      problemMessage:
          """Return and argument types of a weak reference should match.""",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode weakReferenceNotOneArgument = const MessageCode(
  "WeakReferenceNotOneArgument",
  problemMessage:
      """Weak reference should take one required positional argument.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode weakReferenceNotStatic = const MessageCode(
  "WeakReferenceNotStatic",
  problemMessage:
      """Weak reference pragma can be used on a static method only.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode weakReferenceReturnTypeNotNullable = const MessageCode(
  "WeakReferenceReturnTypeNotNullable",
  problemMessage: """Return type of a weak reference should be nullable.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode weakReferenceTargetHasParameters = const MessageCode(
  "WeakReferenceTargetHasParameters",
  problemMessage:
      """The target of weak reference should not take parameters.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode weakReferenceTargetNotStaticTearoff = const MessageCode(
  "WeakReferenceTargetNotStaticTearoff",
  problemMessage:
      """The target of weak reference should be a tearoff of a static method.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String integerLiteral,
    required String nearestJsValue,
  })
>
webLiteralCannotBeRepresentedExactly = const Template(
  "WebLiteralCannotBeRepresentedExactly",
  withArguments: _withArgumentsWebLiteralCannotBeRepresentedExactly,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsWebLiteralCannotBeRepresentedExactly({
  required String integerLiteral,
  required String nearestJsValue,
}) {
  var integerLiteral_0 = conversions.validateString(integerLiteral);
  var nearestJsValue_0 = conversions.validateString(nearestJsValue);
  return new Message(
    webLiteralCannotBeRepresentedExactly,
    problemMessage:
        """The integer literal ${integerLiteral_0} can't be represented exactly in JavaScript.""",
    correctionMessage:
        """Try changing the literal to something that can be represented in JavaScript. In JavaScript ${nearestJsValue_0} is the nearest value that can be represented exactly.""",
    arguments: {
      'integerLiteral': integerLiteral,
      'nearestJsValue': nearestJsValue,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String typeVariableName, required DartType type})
>
wrongTypeParameterVarianceInSuperinterface = const Template(
  "WrongTypeParameterVarianceInSuperinterface",
  withArguments: _withArgumentsWrongTypeParameterVarianceInSuperinterface,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsWrongTypeParameterVarianceInSuperinterface({
  required String typeVariableName,
  required DartType type,
}) {
  var typeVariableName_0 = conversions.validateAndDemangleName(
    typeVariableName,
  );
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    wrongTypeParameterVarianceInSuperinterface,
    problemMessage:
        """'${typeVariableName_0}' can't be used contravariantly or invariantly in '${type_0}'.""" +
        labeler.originMessages,
    arguments: {'typeVariableName': typeVariableName, 'type': type},
  );
}
