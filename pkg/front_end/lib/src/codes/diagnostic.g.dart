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
const Template<
  Message Function(String name),
  Message Function({required String name})
>
abstractClassInstantiation = const Template(
  "AbstractClassInstantiation",
  withArgumentsOld: _withArgumentsOldAbstractClassInstantiation,
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
Message _withArgumentsOldAbstractClassInstantiation(String name) =>
    _withArgumentsAbstractClassInstantiation(name: name);

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
const Template<
  Message Function(String name),
  Message Function({required String name})
>
abstractRedirectedClassInstantiation = const Template(
  "AbstractRedirectedClassInstantiation",
  withArgumentsOld: _withArgumentsOldAbstractRedirectedClassInstantiation,
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
Message _withArgumentsOldAbstractRedirectedClassInstantiation(String name) =>
    _withArgumentsAbstractRedirectedClassInstantiation(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode ambiguousExtensionCause = const MessageCode(
  "AmbiguousExtensionCause",
  severity: CfeSeverity.context,
  problemMessage: """This is one of the extension members.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, DartType type),
  Message Function({required String name, required DartType type})
>
ambiguousExtensionMethod = const Template(
  "AmbiguousExtensionMethod",
  withArgumentsOld: _withArgumentsOldAmbiguousExtensionMethod,
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
Message _withArgumentsOldAmbiguousExtensionMethod(String name, DartType type) =>
    _withArgumentsAmbiguousExtensionMethod(name: name, type: type);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, DartType type),
  Message Function({required String name, required DartType type})
>
ambiguousExtensionOperator = const Template(
  "AmbiguousExtensionOperator",
  withArgumentsOld: _withArgumentsOldAmbiguousExtensionOperator,
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
Message _withArgumentsOldAmbiguousExtensionOperator(
  String name,
  DartType type,
) => _withArgumentsAmbiguousExtensionOperator(name: name, type: type);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, DartType type),
  Message Function({required String name, required DartType type})
>
ambiguousExtensionProperty = const Template(
  "AmbiguousExtensionProperty",
  withArgumentsOld: _withArgumentsOldAmbiguousExtensionProperty,
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
Message _withArgumentsOldAmbiguousExtensionProperty(
  String name,
  DartType type,
) => _withArgumentsAmbiguousExtensionProperty(name: name, type: type);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, DartType type, DartType type2),
  Message Function({
    required String name,
    required DartType type,
    required DartType type2,
  })
>
ambiguousSupertypes = const Template(
  "AmbiguousSupertypes",
  withArgumentsOld: _withArgumentsOldAmbiguousSupertypes,
  withArguments: _withArgumentsAmbiguousSupertypes,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsAmbiguousSupertypes({
  required String name,
  required DartType type,
  required DartType type2,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var type2_0 = labeler.labelType(type2);
  return new Message(
    ambiguousSupertypes,
    problemMessage:
        """'${name_0}' can't implement both '${type_0}' and '${type2_0}'""" +
        labeler.originMessages,
    arguments: {'name': name, 'type': type, 'type2': type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldAmbiguousSupertypes(
  String name,
  DartType type,
  DartType type2,
) => _withArgumentsAmbiguousSupertypes(name: name, type: type, type2: type2);

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
  Message Function(DartType type, DartType type2),
  Message Function({required DartType type, required DartType type2})
>
argumentTypeNotAssignable = const Template(
  "ArgumentTypeNotAssignable",
  withArgumentsOld: _withArgumentsOldArgumentTypeNotAssignable,
  withArguments: _withArgumentsArgumentTypeNotAssignable,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsArgumentTypeNotAssignable({
  required DartType type,
  required DartType type2,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var type2_0 = labeler.labelType(type2);
  return new Message(
    argumentTypeNotAssignable,
    problemMessage:
        """The argument type '${type_0}' can't be assigned to the parameter type '${type2_0}'.""" +
        labeler.originMessages,
    arguments: {'type': type, 'type2': type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldArgumentTypeNotAssignable(
  DartType type,
  DartType type2,
) => _withArgumentsArgumentTypeNotAssignable(type: type, type2: type2);

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
const Template<
  Message Function(String name),
  Message Function({required String name})
>
baseClassImplementedOutsideOfLibrary = const Template(
  "BaseClassImplementedOutsideOfLibrary",
  withArgumentsOld: _withArgumentsOldBaseClassImplementedOutsideOfLibrary,
  withArguments: _withArgumentsBaseClassImplementedOutsideOfLibrary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsBaseClassImplementedOutsideOfLibrary({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    baseClassImplementedOutsideOfLibrary,
    problemMessage:
        """The class '${name_0}' can't be implemented outside of its library because it's a base class.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldBaseClassImplementedOutsideOfLibrary(String name) =>
    _withArgumentsBaseClassImplementedOutsideOfLibrary(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
baseMixinImplementedOutsideOfLibrary = const Template(
  "BaseMixinImplementedOutsideOfLibrary",
  withArgumentsOld: _withArgumentsOldBaseMixinImplementedOutsideOfLibrary,
  withArguments: _withArgumentsBaseMixinImplementedOutsideOfLibrary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsBaseMixinImplementedOutsideOfLibrary({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    baseMixinImplementedOutsideOfLibrary,
    problemMessage:
        """The mixin '${name_0}' can't be implemented outside of its library because it's a base mixin.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldBaseMixinImplementedOutsideOfLibrary(String name) =>
    _withArgumentsBaseMixinImplementedOutsideOfLibrary(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, String name2),
  Message Function({required String name, required String name2})
>
baseOrFinalClassImplementedOutsideOfLibraryCause = const Template(
  "BaseOrFinalClassImplementedOutsideOfLibraryCause",
  withArgumentsOld:
      _withArgumentsOldBaseOrFinalClassImplementedOutsideOfLibraryCause,
  withArguments: _withArgumentsBaseOrFinalClassImplementedOutsideOfLibraryCause,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsBaseOrFinalClassImplementedOutsideOfLibraryCause({
  required String name,
  required String name2,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var name2_0 = conversions.validateAndDemangleName(name2);
  return new Message(
    baseOrFinalClassImplementedOutsideOfLibraryCause,
    problemMessage:
        """The type '${name_0}' is a subtype of '${name2_0}', and '${name2_0}' is defined here.""",
    arguments: {'name': name, 'name2': name2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldBaseOrFinalClassImplementedOutsideOfLibraryCause(
  String name,
  String name2,
) => _withArgumentsBaseOrFinalClassImplementedOutsideOfLibraryCause(
  name: name,
  name2: name2,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, String name2),
  Message Function({required String name, required String name2})
>
boundIssueViaCycleNonSimplicity = const Template(
  "BoundIssueViaCycleNonSimplicity",
  withArgumentsOld: _withArgumentsOldBoundIssueViaCycleNonSimplicity,
  withArguments: _withArgumentsBoundIssueViaCycleNonSimplicity,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsBoundIssueViaCycleNonSimplicity({
  required String name,
  required String name2,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var name2_0 = conversions.validateAndDemangleName(name2);
  return new Message(
    boundIssueViaCycleNonSimplicity,
    problemMessage:
        """Generic type '${name_0}' can't be used without type arguments in the bounds of its own type variables. It is referenced indirectly through '${name2_0}'.""",
    correctionMessage:
        """Try providing type arguments to '${name2_0}' here or to some other raw types in the bounds along the reference chain.""",
    arguments: {'name': name, 'name2': name2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldBoundIssueViaCycleNonSimplicity(
  String name,
  String name2,
) => _withArgumentsBoundIssueViaCycleNonSimplicity(name: name, name2: name2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
boundIssueViaLoopNonSimplicity = const Template(
  "BoundIssueViaLoopNonSimplicity",
  withArgumentsOld: _withArgumentsOldBoundIssueViaLoopNonSimplicity,
  withArguments: _withArgumentsBoundIssueViaLoopNonSimplicity,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsBoundIssueViaLoopNonSimplicity({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    boundIssueViaLoopNonSimplicity,
    problemMessage:
        """Generic type '${name_0}' can't be used without type arguments in the bounds of its own type variables.""",
    correctionMessage: """Try providing type arguments to '${name_0}' here.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldBoundIssueViaLoopNonSimplicity(String name) =>
    _withArgumentsBoundIssueViaLoopNonSimplicity(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
boundIssueViaRawTypeWithNonSimpleBounds = const Template(
  "BoundIssueViaRawTypeWithNonSimpleBounds",
  withArgumentsOld: _withArgumentsOldBoundIssueViaRawTypeWithNonSimpleBounds,
  withArguments: _withArgumentsBoundIssueViaRawTypeWithNonSimpleBounds,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsBoundIssueViaRawTypeWithNonSimpleBounds({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    boundIssueViaRawTypeWithNonSimpleBounds,
    problemMessage:
        """Generic type '${name_0}' can't be used without type arguments in a type variable bound.""",
    correctionMessage: """Try providing type arguments to '${name_0}' here.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldBoundIssueViaRawTypeWithNonSimpleBounds(String name) =>
    _withArgumentsBoundIssueViaRawTypeWithNonSimpleBounds(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String label),
  Message Function({required String label})
>
breakTargetOutsideFunction = const Template(
  "BreakTargetOutsideFunction",
  withArgumentsOld: _withArgumentsOldBreakTargetOutsideFunction,
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
Message _withArgumentsOldBreakTargetOutsideFunction(String label) =>
    _withArgumentsBreakTargetOutsideFunction(label: label);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode candidateFound = const MessageCode(
  "CandidateFound",
  severity: CfeSeverity.context,
  problemMessage: """Found this candidate, but the arguments don't match.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
candidateFoundIsDefaultConstructor = const Template(
  "CandidateFoundIsDefaultConstructor",
  withArgumentsOld: _withArgumentsOldCandidateFoundIsDefaultConstructor,
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
Message _withArgumentsOldCandidateFoundIsDefaultConstructor(String name) =>
    _withArgumentsCandidateFoundIsDefaultConstructor(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
cannotAssignToConstVariable = const Template(
  "CannotAssignToConstVariable",
  withArgumentsOld: _withArgumentsOldCannotAssignToConstVariable,
  withArguments: _withArgumentsCannotAssignToConstVariable,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCannotAssignToConstVariable({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    cannotAssignToConstVariable,
    problemMessage: """Can't assign to the const variable '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldCannotAssignToConstVariable(String name) =>
    _withArgumentsCannotAssignToConstVariable(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode cannotAssignToExtensionThis = const MessageCode(
  "CannotAssignToExtensionThis",
  problemMessage: """Can't assign to 'this'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
cannotAssignToFinalVariable = const Template(
  "CannotAssignToFinalVariable",
  withArgumentsOld: _withArgumentsOldCannotAssignToFinalVariable,
  withArguments: _withArgumentsCannotAssignToFinalVariable,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCannotAssignToFinalVariable({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    cannotAssignToFinalVariable,
    problemMessage: """Can't assign to the final variable '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldCannotAssignToFinalVariable(String name) =>
    _withArgumentsCannotAssignToFinalVariable(name: name);

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
const Template<
  Message Function(String string),
  Message Function({required String string})
>
cannotReadSdkSpecification = const Template(
  "CannotReadSdkSpecification",
  withArgumentsOld: _withArgumentsOldCannotReadSdkSpecification,
  withArguments: _withArgumentsCannotReadSdkSpecification,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCannotReadSdkSpecification({required String string}) {
  var string_0 = conversions.validateString(string);
  return new Message(
    cannotReadSdkSpecification,
    problemMessage: """Unable to read the 'libraries.json' specification file:
  ${string_0}.""",
    arguments: {'string': string},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldCannotReadSdkSpecification(String string) =>
    _withArgumentsCannotReadSdkSpecification(string: string);

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
const Template<
  Message Function(String name),
  Message Function({required String name})
>
cantHaveNamedParameters = const Template(
  "CantHaveNamedParameters",
  withArgumentsOld: _withArgumentsOldCantHaveNamedParameters,
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
Message _withArgumentsOldCantHaveNamedParameters(String name) =>
    _withArgumentsCantHaveNamedParameters(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
cantHaveOptionalParameters = const Template(
  "CantHaveOptionalParameters",
  withArgumentsOld: _withArgumentsOldCantHaveOptionalParameters,
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
Message _withArgumentsOldCantHaveOptionalParameters(String name) =>
    _withArgumentsCantHaveOptionalParameters(name: name);

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
const Template<
  Message Function(String name),
  Message Function({required String name})
>
cantInferReturnTypeDueToNoCombinedSignature = const Template(
  "CantInferReturnTypeDueToNoCombinedSignature",
  withArgumentsOld:
      _withArgumentsOldCantInferReturnTypeDueToNoCombinedSignature,
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
Message _withArgumentsOldCantInferReturnTypeDueToNoCombinedSignature(
  String name,
) => _withArgumentsCantInferReturnTypeDueToNoCombinedSignature(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string),
  Message Function({required String string})
>
cantInferTypeDueToCircularity = const Template(
  "CantInferTypeDueToCircularity",
  withArgumentsOld: _withArgumentsOldCantInferTypeDueToCircularity,
  withArguments: _withArgumentsCantInferTypeDueToCircularity,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCantInferTypeDueToCircularity({required String string}) {
  var string_0 = conversions.validateString(string);
  return new Message(
    cantInferTypeDueToCircularity,
    problemMessage:
        """Can't infer the type of '${string_0}': circularity found during type inference.""",
    correctionMessage: """Specify the type explicitly.""",
    arguments: {'string': string},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldCantInferTypeDueToCircularity(String string) =>
    _withArgumentsCantInferTypeDueToCircularity(string: string);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
cantInferTypeDueToNoCombinedSignature = const Template(
  "CantInferTypeDueToNoCombinedSignature",
  withArgumentsOld: _withArgumentsOldCantInferTypeDueToNoCombinedSignature,
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
Message _withArgumentsOldCantInferTypeDueToNoCombinedSignature(String name) =>
    _withArgumentsCantInferTypeDueToNoCombinedSignature(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
cantInferTypesDueToNoCombinedSignature = const Template(
  "CantInferTypesDueToNoCombinedSignature",
  withArgumentsOld: _withArgumentsOldCantInferTypesDueToNoCombinedSignature,
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
Message _withArgumentsOldCantInferTypesDueToNoCombinedSignature(String name) =>
    _withArgumentsCantInferTypesDueToNoCombinedSignature(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Uri uri, String string),
  Message Function({required Uri uri, required String string})
>
cantReadFile = const Template(
  "CantReadFile",
  withArgumentsOld: _withArgumentsOldCantReadFile,
  withArguments: _withArgumentsCantReadFile,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCantReadFile({required Uri uri, required String string}) {
  var uri_0 = conversions.relativizeUri(uri);
  var string_0 = conversions.validateString(string);
  return new Message(
    cantReadFile,
    problemMessage: """Error when reading '${uri_0}': ${string_0}""",
    arguments: {'uri': uri, 'string': string},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldCantReadFile(Uri uri, String string) =>
    _withArgumentsCantReadFile(uri: uri, string: string);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
cantUseClassAsMixin = const Template(
  "CantUseClassAsMixin",
  withArgumentsOld: _withArgumentsOldCantUseClassAsMixin,
  withArguments: _withArgumentsCantUseClassAsMixin,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCantUseClassAsMixin({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    cantUseClassAsMixin,
    problemMessage:
        """The class '${name_0}' can't be used as a mixin because it isn't a mixin class nor a mixin.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldCantUseClassAsMixin(String name) =>
    _withArgumentsCantUseClassAsMixin(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Token lexeme),
  Message Function({required Token lexeme})
>
cantUseControlFlowOrSpreadAsConstant = const Template(
  "CantUseControlFlowOrSpreadAsConstant",
  withArgumentsOld: _withArgumentsOldCantUseControlFlowOrSpreadAsConstant,
  withArguments: _withArgumentsCantUseControlFlowOrSpreadAsConstant,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCantUseControlFlowOrSpreadAsConstant({
  required Token lexeme,
}) {
  var lexeme_0 = conversions.tokenToLexeme(lexeme);
  return new Message(
    cantUseControlFlowOrSpreadAsConstant,
    problemMessage:
        """'${lexeme_0}' is not supported in constant expressions.""",
    arguments: {'lexeme': lexeme},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldCantUseControlFlowOrSpreadAsConstant(Token lexeme) =>
    _withArgumentsCantUseControlFlowOrSpreadAsConstant(lexeme: lexeme);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Token lexeme),
  Message Function({required Token lexeme})
>
cantUseDeferredPrefixAsConstant = const Template(
  "CantUseDeferredPrefixAsConstant",
  withArgumentsOld: _withArgumentsOldCantUseDeferredPrefixAsConstant,
  withArguments: _withArgumentsCantUseDeferredPrefixAsConstant,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCantUseDeferredPrefixAsConstant({required Token lexeme}) {
  var lexeme_0 = conversions.tokenToLexeme(lexeme);
  return new Message(
    cantUseDeferredPrefixAsConstant,
    problemMessage:
        """'${lexeme_0}' can't be used in a constant expression because it's marked as 'deferred' which means it isn't available until loaded.""",
    correctionMessage:
        """Try moving the constant from the deferred library, or removing 'deferred' from the import.""",
    arguments: {'lexeme': lexeme},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldCantUseDeferredPrefixAsConstant(Token lexeme) =>
    _withArgumentsCantUseDeferredPrefixAsConstant(lexeme: lexeme);

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
const Template<
  Message Function(String name),
  Message Function({required String name})
>
classShouldBeListedAsCallableInDynamicInterface = const Template(
  "ClassShouldBeListedAsCallableInDynamicInterface",
  withArgumentsOld:
      _withArgumentsOldClassShouldBeListedAsCallableInDynamicInterface,
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
Message _withArgumentsOldClassShouldBeListedAsCallableInDynamicInterface(
  String name,
) => _withArgumentsClassShouldBeListedAsCallableInDynamicInterface(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
classShouldBeListedAsExtendableInDynamicInterface = const Template(
  "ClassShouldBeListedAsExtendableInDynamicInterface",
  withArgumentsOld:
      _withArgumentsOldClassShouldBeListedAsExtendableInDynamicInterface,
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
Message _withArgumentsOldClassShouldBeListedAsExtendableInDynamicInterface(
  String name,
) =>
    _withArgumentsClassShouldBeListedAsExtendableInDynamicInterface(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, String name2),
  Message Function({required String name, required String name2})
>
combinedMemberSignatureFailed = const Template(
  "CombinedMemberSignatureFailed",
  withArgumentsOld: _withArgumentsOldCombinedMemberSignatureFailed,
  withArguments: _withArgumentsCombinedMemberSignatureFailed,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCombinedMemberSignatureFailed({
  required String name,
  required String name2,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var name2_0 = conversions.validateAndDemangleName(name2);
  return new Message(
    combinedMemberSignatureFailed,
    problemMessage:
        """Class '${name_0}' inherits multiple members named '${name2_0}' with incompatible signatures.""",
    correctionMessage:
        """Try adding a declaration of '${name2_0}' to '${name_0}'.""",
    arguments: {'name': name, 'name2': name2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldCombinedMemberSignatureFailed(
  String name,
  String name2,
) => _withArgumentsCombinedMemberSignatureFailed(name: name, name2: name2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String fieldName),
  Message Function({required String fieldName})
>
conflictsWithImplicitSetter = const Template(
  "ConflictsWithImplicitSetter",
  withArgumentsOld: _withArgumentsOldConflictsWithImplicitSetter,
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
Message _withArgumentsOldConflictsWithImplicitSetter(String fieldName) =>
    _withArgumentsConflictsWithImplicitSetter(fieldName: fieldName);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String fieldName),
  Message Function({required String fieldName})
>
conflictsWithImplicitSetterCause = const Template(
  "ConflictsWithImplicitSetterCause",
  withArgumentsOld: _withArgumentsOldConflictsWithImplicitSetterCause,
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
Message _withArgumentsOldConflictsWithImplicitSetterCause(String fieldName) =>
    _withArgumentsConflictsWithImplicitSetterCause(fieldName: fieldName);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String typeVariableName),
  Message Function({required String typeVariableName})
>
conflictsWithTypeParameter = const Template(
  "ConflictsWithTypeParameter",
  withArgumentsOld: _withArgumentsOldConflictsWithTypeParameter,
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
Message _withArgumentsOldConflictsWithTypeParameter(String typeVariableName) =>
    _withArgumentsConflictsWithTypeParameter(
      typeVariableName: typeVariableName,
    );

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
const Template<
  Message Function(Constant constant),
  Message Function({required Constant constant})
>
constEvalCaseImplementsEqual = const Template(
  "ConstEvalCaseImplementsEqual",
  withArgumentsOld: _withArgumentsOldConstEvalCaseImplementsEqual,
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
Message _withArgumentsOldConstEvalCaseImplementsEqual(Constant constant) =>
    _withArgumentsConstEvalCaseImplementsEqual(constant: constant);

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
const Template<
  Message Function(String importName),
  Message Function({required String importName})
>
constEvalDeferredLibrary = const Template(
  "ConstEvalDeferredLibrary",
  withArgumentsOld: _withArgumentsOldConstEvalDeferredLibrary,
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
Message _withArgumentsOldConstEvalDeferredLibrary(String importName) =>
    _withArgumentsConstEvalDeferredLibrary(importName: importName);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Constant element),
  Message Function({required Constant element})
>
constEvalDuplicateElement = const Template(
  "ConstEvalDuplicateElement",
  withArgumentsOld: _withArgumentsOldConstEvalDuplicateElement,
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
Message _withArgumentsOldConstEvalDuplicateElement(Constant element) =>
    _withArgumentsConstEvalDuplicateElement(element: element);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Constant key),
  Message Function({required Constant key})
>
constEvalDuplicateKey = const Template(
  "ConstEvalDuplicateKey",
  withArgumentsOld: _withArgumentsOldConstEvalDuplicateKey,
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
Message _withArgumentsOldConstEvalDuplicateKey(Constant key) =>
    _withArgumentsConstEvalDuplicateKey(key: key);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Constant element),
  Message Function({required Constant element})
>
constEvalElementImplementsEqual = const Template(
  "ConstEvalElementImplementsEqual",
  withArgumentsOld: _withArgumentsOldConstEvalElementImplementsEqual,
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
Message _withArgumentsOldConstEvalElementImplementsEqual(Constant element) =>
    _withArgumentsConstEvalElementImplementsEqual(element: element);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Constant element),
  Message Function({required Constant element})
>
constEvalElementNotPrimitiveEquality = const Template(
  "ConstEvalElementNotPrimitiveEquality",
  withArgumentsOld: _withArgumentsOldConstEvalElementNotPrimitiveEquality,
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
Message _withArgumentsOldConstEvalElementNotPrimitiveEquality(
  Constant element,
) => _withArgumentsConstEvalElementNotPrimitiveEquality(element: element);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Constant receiver, DartType actualType),
  Message Function({required Constant receiver, required DartType actualType})
>
constEvalEqualsOperandNotPrimitiveEquality = const Template(
  "ConstEvalEqualsOperandNotPrimitiveEquality",
  withArgumentsOld: _withArgumentsOldConstEvalEqualsOperandNotPrimitiveEquality,
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
Message _withArgumentsOldConstEvalEqualsOperandNotPrimitiveEquality(
  Constant receiver,
  DartType actualType,
) => _withArgumentsConstEvalEqualsOperandNotPrimitiveEquality(
  receiver: receiver,
  actualType: actualType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String message),
  Message Function({required String message})
>
constEvalError = const Template(
  "ConstEvalError",
  withArgumentsOld: _withArgumentsOldConstEvalError,
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
Message _withArgumentsOldConstEvalError(String message) =>
    _withArgumentsConstEvalError(message: message);

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
const Template<
  Message Function(String message),
  Message Function({required String message})
>
constEvalFailedAssertionWithMessage = const Template(
  "ConstEvalFailedAssertionWithMessage",
  withArgumentsOld: _withArgumentsOldConstEvalFailedAssertionWithMessage,
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
Message _withArgumentsOldConstEvalFailedAssertionWithMessage(String message) =>
    _withArgumentsConstEvalFailedAssertionWithMessage(message: message);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode constEvalFailedAssertionWithNonStringMessage =
    const MessageCode(
      "ConstEvalFailedAssertionWithNonStringMessage",
      problemMessage: """This assertion failed with a non-String message.""",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
constEvalGetterNotFound = const Template(
  "ConstEvalGetterNotFound",
  withArgumentsOld: _withArgumentsOldConstEvalGetterNotFound,
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
Message _withArgumentsOldConstEvalGetterNotFound(String name) =>
    _withArgumentsConstEvalGetterNotFound(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(
    String operator,
    Constant receiver,
    DartType expectedType,
    DartType actualType,
  ),
  Message Function({
    required String operator,
    required Constant receiver,
    required DartType expectedType,
    required DartType actualType,
  })
>
constEvalInvalidBinaryOperandType = const Template(
  "ConstEvalInvalidBinaryOperandType",
  withArgumentsOld: _withArgumentsOldConstEvalInvalidBinaryOperandType,
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
Message _withArgumentsOldConstEvalInvalidBinaryOperandType(
  String operator,
  Constant receiver,
  DartType expectedType,
  DartType actualType,
) => _withArgumentsConstEvalInvalidBinaryOperandType(
  operator: operator,
  receiver: receiver,
  expectedType: expectedType,
  actualType: actualType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Constant receiver, DartType actualType),
  Message Function({required Constant receiver, required DartType actualType})
>
constEvalInvalidEqualsOperandType = const Template(
  "ConstEvalInvalidEqualsOperandType",
  withArgumentsOld: _withArgumentsOldConstEvalInvalidEqualsOperandType,
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
Message _withArgumentsOldConstEvalInvalidEqualsOperandType(
  Constant receiver,
  DartType actualType,
) => _withArgumentsConstEvalInvalidEqualsOperandType(
  receiver: receiver,
  actualType: actualType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String method, Constant receiver),
  Message Function({required String method, required Constant receiver})
>
constEvalInvalidMethodInvocation = const Template(
  "ConstEvalInvalidMethodInvocation",
  withArgumentsOld: _withArgumentsOldConstEvalInvalidMethodInvocation,
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
Message _withArgumentsOldConstEvalInvalidMethodInvocation(
  String method,
  Constant receiver,
) => _withArgumentsConstEvalInvalidMethodInvocation(
  method: method,
  receiver: receiver,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String property, Constant receiver),
  Message Function({required String property, required Constant receiver})
>
constEvalInvalidPropertyGet = const Template(
  "ConstEvalInvalidPropertyGet",
  withArgumentsOld: _withArgumentsOldConstEvalInvalidPropertyGet,
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
Message _withArgumentsOldConstEvalInvalidPropertyGet(
  String property,
  Constant receiver,
) => _withArgumentsConstEvalInvalidPropertyGet(
  property: property,
  receiver: receiver,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String index, Constant receiver),
  Message Function({required String index, required Constant receiver})
>
constEvalInvalidRecordIndexGet = const Template(
  "ConstEvalInvalidRecordIndexGet",
  withArgumentsOld: _withArgumentsOldConstEvalInvalidRecordIndexGet,
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
Message _withArgumentsOldConstEvalInvalidRecordIndexGet(
  String index,
  Constant receiver,
) => _withArgumentsConstEvalInvalidRecordIndexGet(
  index: index,
  receiver: receiver,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String property, Constant receiver),
  Message Function({required String property, required Constant receiver})
>
constEvalInvalidRecordNameGet = const Template(
  "ConstEvalInvalidRecordNameGet",
  withArgumentsOld: _withArgumentsOldConstEvalInvalidRecordNameGet,
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
Message _withArgumentsOldConstEvalInvalidRecordNameGet(
  String property,
  Constant receiver,
) => _withArgumentsConstEvalInvalidRecordNameGet(
  property: property,
  receiver: receiver,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String target),
  Message Function({required String target})
>
constEvalInvalidStaticInvocation = const Template(
  "ConstEvalInvalidStaticInvocation",
  withArgumentsOld: _withArgumentsOldConstEvalInvalidStaticInvocation,
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
Message _withArgumentsOldConstEvalInvalidStaticInvocation(String target) =>
    _withArgumentsConstEvalInvalidStaticInvocation(target: target);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Constant constant),
  Message Function({required Constant constant})
>
constEvalInvalidStringInterpolationOperand = const Template(
  "ConstEvalInvalidStringInterpolationOperand",
  withArgumentsOld: _withArgumentsOldConstEvalInvalidStringInterpolationOperand,
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
Message _withArgumentsOldConstEvalInvalidStringInterpolationOperand(
  Constant constant,
) => _withArgumentsConstEvalInvalidStringInterpolationOperand(
  constant: constant,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Constant name),
  Message Function({required Constant name})
>
constEvalInvalidSymbolName = const Template(
  "ConstEvalInvalidSymbolName",
  withArgumentsOld: _withArgumentsOldConstEvalInvalidSymbolName,
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
Message _withArgumentsOldConstEvalInvalidSymbolName(Constant name) =>
    _withArgumentsConstEvalInvalidSymbolName(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(
    Constant constant,
    DartType expectedType,
    DartType actualType,
  ),
  Message Function({
    required Constant constant,
    required DartType expectedType,
    required DartType actualType,
  })
>
constEvalInvalidType = const Template(
  "ConstEvalInvalidType",
  withArgumentsOld: _withArgumentsOldConstEvalInvalidType,
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
Message _withArgumentsOldConstEvalInvalidType(
  Constant constant,
  DartType expectedType,
  DartType actualType,
) => _withArgumentsConstEvalInvalidType(
  constant: constant,
  expectedType: expectedType,
  actualType: actualType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Constant key),
  Message Function({required Constant key})
>
constEvalKeyImplementsEqual = const Template(
  "ConstEvalKeyImplementsEqual",
  withArgumentsOld: _withArgumentsOldConstEvalKeyImplementsEqual,
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
Message _withArgumentsOldConstEvalKeyImplementsEqual(Constant key) =>
    _withArgumentsConstEvalKeyImplementsEqual(key: key);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Constant key),
  Message Function({required Constant key})
>
constEvalKeyNotPrimitiveEquality = const Template(
  "ConstEvalKeyNotPrimitiveEquality",
  withArgumentsOld: _withArgumentsOldConstEvalKeyNotPrimitiveEquality,
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
Message _withArgumentsOldConstEvalKeyNotPrimitiveEquality(Constant key) =>
    _withArgumentsConstEvalKeyNotPrimitiveEquality(key: key);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String operator, String receiver, String shiftAmount),
  Message Function({
    required String operator,
    required String receiver,
    required String shiftAmount,
  })
>
constEvalNegativeShift = const Template(
  "ConstEvalNegativeShift",
  withArgumentsOld: _withArgumentsOldConstEvalNegativeShift,
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
Message _withArgumentsOldConstEvalNegativeShift(
  String operator,
  String receiver,
  String shiftAmount,
) => _withArgumentsConstEvalNegativeShift(
  operator: operator,
  receiver: receiver,
  shiftAmount: shiftAmount,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String nameOKEmpty),
  Message Function({required String nameOKEmpty})
>
constEvalNonConstantVariableGet = const Template(
  "ConstEvalNonConstantVariableGet",
  withArgumentsOld: _withArgumentsOldConstEvalNonConstantVariableGet,
  withArguments: _withArgumentsConstEvalNonConstantVariableGet,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalNonConstantVariableGet({
  required String nameOKEmpty,
}) {
  var nameOKEmpty_0 = conversions.nameOrUnnamed(nameOKEmpty);
  return new Message(
    constEvalNonConstantVariableGet,
    problemMessage:
        """The variable '${nameOKEmpty_0}' is not a constant, only constant expressions are allowed.""",
    arguments: {'nameOKEmpty': nameOKEmpty},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConstEvalNonConstantVariableGet(String nameOKEmpty) =>
    _withArgumentsConstEvalNonConstantVariableGet(nameOKEmpty: nameOKEmpty);

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
  Message Function(String receiver, String operand),
  Message Function({required String receiver, required String operand})
>
constEvalTruncateError = const Template(
  "ConstEvalTruncateError",
  withArgumentsOld: _withArgumentsOldConstEvalTruncateError,
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
Message _withArgumentsOldConstEvalTruncateError(
  String receiver,
  String operand,
) => _withArgumentsConstEvalTruncateError(receiver: receiver, operand: operand);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode constEvalUnevaluated = const MessageCode(
  "ConstEvalUnevaluated",
  problemMessage: """Couldn't evaluate constant expression.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String exceptionText),
  Message Function({required String exceptionText})
>
constEvalUnhandledCoreException = const Template(
  "ConstEvalUnhandledCoreException",
  withArgumentsOld: _withArgumentsOldConstEvalUnhandledCoreException,
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
Message _withArgumentsOldConstEvalUnhandledCoreException(
  String exceptionText,
) =>
    _withArgumentsConstEvalUnhandledCoreException(exceptionText: exceptionText);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Constant exception),
  Message Function({required Constant exception})
>
constEvalUnhandledException = const Template(
  "ConstEvalUnhandledException",
  withArgumentsOld: _withArgumentsOldConstEvalUnhandledException,
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
Message _withArgumentsOldConstEvalUnhandledException(Constant exception) =>
    _withArgumentsConstEvalUnhandledException(exception: exception);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String operator, String value),
  Message Function({required String operator, required String value})
>
constEvalZeroDivisor = const Template(
  "ConstEvalZeroDivisor",
  withArgumentsOld: _withArgumentsOldConstEvalZeroDivisor,
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
Message _withArgumentsOldConstEvalZeroDivisor(String operator, String value) =>
    _withArgumentsConstEvalZeroDivisor(operator: operator, value: value);

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
const Template<
  Message Function(String memberName),
  Message Function({required String memberName})
>
constructorConflictsWithMember = const Template(
  "ConstructorConflictsWithMember",
  withArgumentsOld: _withArgumentsOldConstructorConflictsWithMember,
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
Message _withArgumentsOldConstructorConflictsWithMember(String memberName) =>
    _withArgumentsConstructorConflictsWithMember(memberName: memberName);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String memberName),
  Message Function({required String memberName})
>
constructorConflictsWithMemberCause = const Template(
  "ConstructorConflictsWithMemberCause",
  withArgumentsOld: _withArgumentsOldConstructorConflictsWithMemberCause,
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
Message _withArgumentsOldConstructorConflictsWithMemberCause(
  String memberName,
) => _withArgumentsConstructorConflictsWithMemberCause(memberName: memberName);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode constructorCyclic = const MessageCode(
  "ConstructorCyclic",
  problemMessage: """Redirecting constructors can't be cyclic.""",
  correctionMessage:
      """Try to have all constructors eventually redirect to a non-redirecting constructor.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
constructorInitializeSameInstanceVariableSeveralTimes = const Template(
  "ConstructorInitializeSameInstanceVariableSeveralTimes",
  withArgumentsOld:
      _withArgumentsOldConstructorInitializeSameInstanceVariableSeveralTimes,
  withArguments:
      _withArgumentsConstructorInitializeSameInstanceVariableSeveralTimes,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstructorInitializeSameInstanceVariableSeveralTimes({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    constructorInitializeSameInstanceVariableSeveralTimes,
    problemMessage:
        """'${name_0}' was already initialized by this constructor.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConstructorInitializeSameInstanceVariableSeveralTimes(
  String name,
) => _withArgumentsConstructorInitializeSameInstanceVariableSeveralTimes(
  name: name,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
constructorNotFound = const Template(
  "ConstructorNotFound",
  withArgumentsOld: _withArgumentsOldConstructorNotFound,
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
Message _withArgumentsOldConstructorNotFound(String name) =>
    _withArgumentsConstructorNotFound(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode constructorNotSync = const MessageCode(
  "ConstructorNotSync",
  problemMessage:
      """Constructor bodies can't use 'async', 'async*', or 'sync*'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
constructorShouldBeListedAsCallableInDynamicInterface = const Template(
  "ConstructorShouldBeListedAsCallableInDynamicInterface",
  withArgumentsOld:
      _withArgumentsOldConstructorShouldBeListedAsCallableInDynamicInterface,
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
Message _withArgumentsOldConstructorShouldBeListedAsCallableInDynamicInterface(
  String name,
) => _withArgumentsConstructorShouldBeListedAsCallableInDynamicInterface(
  name: name,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode constructorTearOffWithTypeArguments = const MessageCode(
  "ConstructorTearOffWithTypeArguments",
  problemMessage:
      """A constructor tear-off can't have type arguments after the constructor name.""",
  correctionMessage:
      """Try removing the type arguments or placing them after the class name.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
constructorWithWrongNameContext = const Template(
  "ConstructorWithWrongNameContext",
  withArgumentsOld: _withArgumentsOldConstructorWithWrongNameContext,
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
Message _withArgumentsOldConstructorWithWrongNameContext(String name) =>
    _withArgumentsConstructorWithWrongNameContext(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode continueLabelInvalid = const MessageCode(
  "ContinueLabelInvalid",
  problemMessage:
      """A 'continue' label must be on a loop or a switch member.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String label),
  Message Function({required String label})
>
continueTargetOutsideFunction = const Template(
  "ContinueTargetOutsideFunction",
  withArgumentsOld: _withArgumentsOldContinueTargetOutsideFunction,
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
Message _withArgumentsOldContinueTargetOutsideFunction(String label) =>
    _withArgumentsContinueTargetOutsideFunction(label: label);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string, String string2),
  Message Function({required String string, required String string2})
>
couldNotParseUri = const Template(
  "CouldNotParseUri",
  withArgumentsOld: _withArgumentsOldCouldNotParseUri,
  withArguments: _withArgumentsCouldNotParseUri,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCouldNotParseUri({
  required String string,
  required String string2,
}) {
  var string_0 = conversions.validateString(string);
  var string2_0 = conversions.validateString(string2);
  return new Message(
    couldNotParseUri,
    problemMessage: """Couldn't parse URI '${string_0}':
  ${string2_0}.""",
    arguments: {'string': string, 'string2': string2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldCouldNotParseUri(String string, String string2) =>
    _withArgumentsCouldNotParseUri(string: string, string2: string2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, String string),
  Message Function({required String name, required String string})
>
cycleInTypeParameters = const Template(
  "CycleInTypeParameters",
  withArgumentsOld: _withArgumentsOldCycleInTypeParameters,
  withArguments: _withArgumentsCycleInTypeParameters,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCycleInTypeParameters({
  required String name,
  required String string,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var string_0 = conversions.validateString(string);
  return new Message(
    cycleInTypeParameters,
    problemMessage:
        """Type '${name_0}' is a bound of itself via '${string_0}'.""",
    correctionMessage:
        """Try breaking the cycle by removing at least one of the 'extends' clauses in the cycle.""",
    arguments: {'name': name, 'string': string},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldCycleInTypeParameters(String name, String string) =>
    _withArgumentsCycleInTypeParameters(name: name, string: string);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String typeName),
  Message Function({required String typeName})
>
cyclicClassHierarchy = const Template(
  "CyclicClassHierarchy",
  withArgumentsOld: _withArgumentsOldCyclicClassHierarchy,
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
Message _withArgumentsOldCyclicClassHierarchy(String typeName) =>
    _withArgumentsCyclicClassHierarchy(typeName: typeName);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
cyclicRedirectingFactoryConstructors = const Template(
  "CyclicRedirectingFactoryConstructors",
  withArgumentsOld: _withArgumentsOldCyclicRedirectingFactoryConstructors,
  withArguments: _withArgumentsCyclicRedirectingFactoryConstructors,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCyclicRedirectingFactoryConstructors({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    cyclicRedirectingFactoryConstructors,
    problemMessage: """Cyclic definition of factory '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldCyclicRedirectingFactoryConstructors(String name) =>
    _withArgumentsCyclicRedirectingFactoryConstructors(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode cyclicRepresentationDependency = const MessageCode(
  "CyclicRepresentationDependency",
  problemMessage:
      """An extension type can't depend on itself through its representation type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
cyclicTypedef = const Template(
  "CyclicTypedef",
  withArgumentsOld: _withArgumentsOldCyclicTypedef,
  withArguments: _withArgumentsCyclicTypedef,
);

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
Message _withArgumentsOldCyclicTypedef(String name) =>
    _withArgumentsCyclicTypedef(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode dartFfiLibraryInDart2Wasm = const MessageCode(
  "DartFfiLibraryInDart2Wasm",
  problemMessage: """'dart:ffi' can't be imported when compiling to Wasm.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String severity, String stackTrace),
  Message Function({required String severity, required String stackTrace})
>
debugTrace = const Template(
  "DebugTrace",
  withArgumentsOld: _withArgumentsOldDebugTrace,
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
Message _withArgumentsOldDebugTrace(String severity, String stackTrace) =>
    _withArgumentsDebugTrace(severity: severity, stackTrace: stackTrace);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String setterName),
  Message Function({required String setterName})
>
declarationConflictsWithSetter = const Template(
  "DeclarationConflictsWithSetter",
  withArgumentsOld: _withArgumentsOldDeclarationConflictsWithSetter,
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
Message _withArgumentsOldDeclarationConflictsWithSetter(String setterName) =>
    _withArgumentsDeclarationConflictsWithSetter(setterName: setterName);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String setterName),
  Message Function({required String setterName})
>
declarationConflictsWithSetterCause = const Template(
  "DeclarationConflictsWithSetterCause",
  withArgumentsOld: _withArgumentsOldDeclarationConflictsWithSetterCause,
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
Message _withArgumentsOldDeclarationConflictsWithSetterCause(
  String setterName,
) => _withArgumentsDeclarationConflictsWithSetterCause(setterName: setterName);

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
const Template<
  Message Function(String name),
  Message Function({required String name})
>
defaultValueInRedirectingFactoryConstructor = const Template(
  "DefaultValueInRedirectingFactoryConstructor",
  withArgumentsOld:
      _withArgumentsOldDefaultValueInRedirectingFactoryConstructor,
  withArguments: _withArgumentsDefaultValueInRedirectingFactoryConstructor,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDefaultValueInRedirectingFactoryConstructor({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    defaultValueInRedirectingFactoryConstructor,
    problemMessage:
        """Can't have a default value here because any default values of '${name_0}' would be used instead.""",
    correctionMessage: """Try removing the default value.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldDefaultValueInRedirectingFactoryConstructor(
  String name,
) => _withArgumentsDefaultValueInRedirectingFactoryConstructor(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
deferredExtensionImport = const Template(
  "DeferredExtensionImport",
  withArgumentsOld: _withArgumentsOldDeferredExtensionImport,
  withArguments: _withArgumentsDeferredExtensionImport,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDeferredExtensionImport({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    deferredExtensionImport,
    problemMessage:
        """Extension '${name_0}' cannot be imported through a deferred import.""",
    correctionMessage: """Try adding the `hide ${name_0}` to the import.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldDeferredExtensionImport(String name) =>
    _withArgumentsDeferredExtensionImport(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String prefixName),
  Message Function({required String prefixName})
>
deferredPrefixDuplicated = const Template(
  "DeferredPrefixDuplicated",
  withArgumentsOld: _withArgumentsOldDeferredPrefixDuplicated,
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
Message _withArgumentsOldDeferredPrefixDuplicated(String prefixName) =>
    _withArgumentsDeferredPrefixDuplicated(prefixName: prefixName);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String prefixName),
  Message Function({required String prefixName})
>
deferredPrefixDuplicatedCause = const Template(
  "DeferredPrefixDuplicatedCause",
  withArgumentsOld: _withArgumentsOldDeferredPrefixDuplicatedCause,
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
Message _withArgumentsOldDeferredPrefixDuplicatedCause(String prefixName) =>
    _withArgumentsDeferredPrefixDuplicatedCause(prefixName: prefixName);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type, String prefix),
  Message Function({required DartType type, required String prefix})
>
deferredTypeAnnotation = const Template(
  "DeferredTypeAnnotation",
  withArgumentsOld: _withArgumentsOldDeferredTypeAnnotation,
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
Message _withArgumentsOldDeferredTypeAnnotation(DartType type, String prefix) =>
    _withArgumentsDeferredTypeAnnotation(type: type, prefix: prefix);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(int count, int count2, num num1, num num2, num num3),
  Message Function({
    required int count,
    required int count2,
    required num num1,
    required num num2,
    required num num3,
  })
>
dillOutlineSummary = const Template(
  "DillOutlineSummary",
  withArgumentsOld: _withArgumentsOldDillOutlineSummary,
  withArguments: _withArgumentsDillOutlineSummary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDillOutlineSummary({
  required int count,
  required int count2,
  required num num1,
  required num num2,
  required num num3,
}) {
  var num1_0 = conversions.formatNumber(
    num1,
    fractionDigits: 3,
    padWidth: 0,
    padWithZeros: false,
  );
  var num2_0 = conversions.formatNumber(
    num2,
    fractionDigits: 3,
    padWidth: 12,
    padWithZeros: false,
  );
  var num3_0 = conversions.formatNumber(
    num3,
    fractionDigits: 3,
    padWidth: 12,
    padWithZeros: false,
  );
  return new Message(
    dillOutlineSummary,
    problemMessage:
        """Indexed ${count} libraries (${count2} bytes) in ${num1_0}ms, that is,
${num2_0} bytes/ms, and
${num3_0} ms/libraries.""",
    arguments: {
      'count': count,
      'count2': count2,
      'num1': num1,
      'num2': num2,
      'num3': num3,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldDillOutlineSummary(
  int count,
  int count2,
  num num1,
  num num2,
  num num3,
) => _withArgumentsDillOutlineSummary(
  count: count,
  count2: count2,
  num1: num1,
  num2: num2,
  num3: num3,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
directCycleInTypeParameters = const Template(
  "DirectCycleInTypeParameters",
  withArgumentsOld: _withArgumentsOldDirectCycleInTypeParameters,
  withArguments: _withArgumentsDirectCycleInTypeParameters,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDirectCycleInTypeParameters({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    directCycleInTypeParameters,
    problemMessage: """Type '${name_0}' can't use itself as a bound.""",
    correctionMessage:
        """Try breaking the cycle by removing at least one of the 'extends' clauses in the cycle.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldDirectCycleInTypeParameters(String name) =>
    _withArgumentsDirectCycleInTypeParameters(name: name);

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
const Template<
  Message Function(String name),
  Message Function({required String name})
>
dotShorthandsInvalidContext = const Template(
  "DotShorthandsInvalidContext",
  withArgumentsOld: _withArgumentsOldDotShorthandsInvalidContext,
  withArguments: _withArgumentsDotShorthandsInvalidContext,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDotShorthandsInvalidContext({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    dotShorthandsInvalidContext,
    problemMessage:
        """No type was provided to find the dot shorthand '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldDotShorthandsInvalidContext(String name) =>
    _withArgumentsDotShorthandsInvalidContext(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, DartType type),
  Message Function({required String name, required DartType type})
>
dotShorthandsUndefinedGetter = const Template(
  "DotShorthandsUndefinedGetter",
  withArgumentsOld: _withArgumentsOldDotShorthandsUndefinedGetter,
  withArguments: _withArgumentsDotShorthandsUndefinedGetter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDotShorthandsUndefinedGetter({
  required String name,
  required DartType type,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    dotShorthandsUndefinedGetter,
    problemMessage:
        """The static getter or field '${name_0}' isn't defined for the type '${type_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try correcting the name to the name of an existing static getter or field, or defining a getter or field named '${name_0}'.""",
    arguments: {'name': name, 'type': type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldDotShorthandsUndefinedGetter(
  String name,
  DartType type,
) => _withArgumentsDotShorthandsUndefinedGetter(name: name, type: type);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, DartType type),
  Message Function({required String name, required DartType type})
>
dotShorthandsUndefinedInvocation = const Template(
  "DotShorthandsUndefinedInvocation",
  withArgumentsOld: _withArgumentsOldDotShorthandsUndefinedInvocation,
  withArguments: _withArgumentsDotShorthandsUndefinedInvocation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDotShorthandsUndefinedInvocation({
  required String name,
  required DartType type,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    dotShorthandsUndefinedInvocation,
    problemMessage:
        """The static method or constructor '${name_0}' isn't defined for the type '${type_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try correcting the name to the name of an existing static method or constructor, or defining a static method or constructor named '${name_0}'.""",
    arguments: {'name': name, 'type': type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldDotShorthandsUndefinedInvocation(
  String name,
  DartType type,
) => _withArgumentsDotShorthandsUndefinedInvocation(name: name, type: type);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
duplicatePatternAssignmentVariable = const Template(
  "DuplicatePatternAssignmentVariable",
  withArgumentsOld: _withArgumentsOldDuplicatePatternAssignmentVariable,
  withArguments: _withArgumentsDuplicatePatternAssignmentVariable,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatePatternAssignmentVariable({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    duplicatePatternAssignmentVariable,
    problemMessage:
        """The variable '${name_0}' is already assigned in this pattern.""",
    correctionMessage: """Try renaming the variable.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldDuplicatePatternAssignmentVariable(String name) =>
    _withArgumentsDuplicatePatternAssignmentVariable(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode duplicatePatternAssignmentVariableContext = const MessageCode(
  "DuplicatePatternAssignmentVariableContext",
  severity: CfeSeverity.context,
  problemMessage: """The first assigned variable pattern.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
duplicateRecordPatternField = const Template(
  "DuplicateRecordPatternField",
  withArgumentsOld: _withArgumentsOldDuplicateRecordPatternField,
  withArguments: _withArgumentsDuplicateRecordPatternField,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicateRecordPatternField({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    duplicateRecordPatternField,
    problemMessage:
        """The field '${name_0}' is already matched in this pattern.""",
    correctionMessage: """Try removing the duplicate field.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldDuplicateRecordPatternField(String name) =>
    _withArgumentsDuplicateRecordPatternField(name: name);

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
const Template<
  Message Function(String name),
  Message Function({required String name})
>
duplicatedDeclaration = const Template(
  "DuplicatedDeclaration",
  withArgumentsOld: _withArgumentsOldDuplicatedDeclaration,
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
Message _withArgumentsOldDuplicatedDeclaration(String name) =>
    _withArgumentsDuplicatedDeclaration(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
duplicatedDeclarationCause = const Template(
  "DuplicatedDeclarationCause",
  withArgumentsOld: _withArgumentsOldDuplicatedDeclarationCause,
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
Message _withArgumentsOldDuplicatedDeclarationCause(String name) =>
    _withArgumentsDuplicatedDeclarationCause(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
duplicatedDeclarationSyntheticCause = const Template(
  "DuplicatedDeclarationSyntheticCause",
  withArgumentsOld: _withArgumentsOldDuplicatedDeclarationSyntheticCause,
  withArguments: _withArgumentsDuplicatedDeclarationSyntheticCause,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedDeclarationSyntheticCause({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    duplicatedDeclarationSyntheticCause,
    problemMessage:
        """Previous declaration of '${name_0}' is implied by this definition.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldDuplicatedDeclarationSyntheticCause(String name) =>
    _withArgumentsDuplicatedDeclarationSyntheticCause(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
duplicatedDeclarationUse = const Template(
  "DuplicatedDeclarationUse",
  withArgumentsOld: _withArgumentsOldDuplicatedDeclarationUse,
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
Message _withArgumentsOldDuplicatedDeclarationUse(String name) =>
    _withArgumentsDuplicatedDeclarationUse(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, Uri uri, Uri uri2),
  Message Function({required String name, required Uri uri, required Uri uri2})
>
duplicatedExport = const Template(
  "DuplicatedExport",
  withArgumentsOld: _withArgumentsOldDuplicatedExport,
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
Message _withArgumentsOldDuplicatedExport(String name, Uri uri, Uri uri2) =>
    _withArgumentsDuplicatedExport(name: name, uri: uri, uri2: uri2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, Uri uri, Uri uri2),
  Message Function({required String name, required Uri uri, required Uri uri2})
>
duplicatedImport = const Template(
  "DuplicatedImport",
  withArgumentsOld: _withArgumentsOldDuplicatedImport,
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
Message _withArgumentsOldDuplicatedImport(String name, Uri uri, Uri uri2) =>
    _withArgumentsDuplicatedImport(name: name, uri: uri, uri2: uri2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
duplicatedNamedArgument = const Template(
  "DuplicatedNamedArgument",
  withArgumentsOld: _withArgumentsOldDuplicatedNamedArgument,
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
Message _withArgumentsOldDuplicatedNamedArgument(String name) =>
    _withArgumentsDuplicatedNamedArgument(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
duplicatedParameterName = const Template(
  "DuplicatedParameterName",
  withArgumentsOld: _withArgumentsOldDuplicatedParameterName,
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
Message _withArgumentsOldDuplicatedParameterName(String name) =>
    _withArgumentsDuplicatedParameterName(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
duplicatedParameterNameCause = const Template(
  "DuplicatedParameterNameCause",
  withArgumentsOld: _withArgumentsOldDuplicatedParameterNameCause,
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
Message _withArgumentsOldDuplicatedParameterNameCause(String name) =>
    _withArgumentsDuplicatedParameterNameCause(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String fieldName),
  Message Function({required String fieldName})
>
duplicatedRecordLiteralFieldName = const Template(
  "DuplicatedRecordLiteralFieldName",
  withArgumentsOld: _withArgumentsOldDuplicatedRecordLiteralFieldName,
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
Message _withArgumentsOldDuplicatedRecordLiteralFieldName(String fieldName) =>
    _withArgumentsDuplicatedRecordLiteralFieldName(fieldName: fieldName);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String fieldName),
  Message Function({required String fieldName})
>
duplicatedRecordLiteralFieldNameContext = const Template(
  "DuplicatedRecordLiteralFieldNameContext",
  withArgumentsOld: _withArgumentsOldDuplicatedRecordLiteralFieldNameContext,
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
Message _withArgumentsOldDuplicatedRecordLiteralFieldNameContext(
  String fieldName,
) =>
    _withArgumentsDuplicatedRecordLiteralFieldNameContext(fieldName: fieldName);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String fieldName),
  Message Function({required String fieldName})
>
duplicatedRecordTypeFieldName = const Template(
  "DuplicatedRecordTypeFieldName",
  withArgumentsOld: _withArgumentsOldDuplicatedRecordTypeFieldName,
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
Message _withArgumentsOldDuplicatedRecordTypeFieldName(String fieldName) =>
    _withArgumentsDuplicatedRecordTypeFieldName(fieldName: fieldName);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String fieldName),
  Message Function({required String fieldName})
>
duplicatedRecordTypeFieldNameContext = const Template(
  "DuplicatedRecordTypeFieldNameContext",
  withArgumentsOld: _withArgumentsOldDuplicatedRecordTypeFieldNameContext,
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
Message _withArgumentsOldDuplicatedRecordTypeFieldNameContext(
  String fieldName,
) => _withArgumentsDuplicatedRecordTypeFieldNameContext(fieldName: fieldName);

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
const Template<
  Message Function(String name),
  Message Function({required String name})
>
enumContainsRestrictedInstanceDeclaration = const Template(
  "EnumContainsRestrictedInstanceDeclaration",
  withArgumentsOld: _withArgumentsOldEnumContainsRestrictedInstanceDeclaration,
  withArguments: _withArgumentsEnumContainsRestrictedInstanceDeclaration,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsEnumContainsRestrictedInstanceDeclaration({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    enumContainsRestrictedInstanceDeclaration,
    problemMessage:
        """An enum can't declare a non-abstract member named '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldEnumContainsRestrictedInstanceDeclaration(
  String name,
) => _withArgumentsEnumContainsRestrictedInstanceDeclaration(name: name);

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
  Message Function(String name, String name2),
  Message Function({required String name, required String name2})
>
enumImplementerContainsRestrictedInstanceDeclaration = const Template(
  "EnumImplementerContainsRestrictedInstanceDeclaration",
  withArgumentsOld:
      _withArgumentsOldEnumImplementerContainsRestrictedInstanceDeclaration,
  withArguments:
      _withArgumentsEnumImplementerContainsRestrictedInstanceDeclaration,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsEnumImplementerContainsRestrictedInstanceDeclaration({
  required String name,
  required String name2,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var name2_0 = conversions.validateAndDemangleName(name2);
  return new Message(
    enumImplementerContainsRestrictedInstanceDeclaration,
    problemMessage:
        """'${name_0}' has 'Enum' as a superinterface and can't contain non-static members with name '${name2_0}'.""",
    arguments: {'name': name, 'name2': name2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldEnumImplementerContainsRestrictedInstanceDeclaration(
  String name,
  String name2,
) => _withArgumentsEnumImplementerContainsRestrictedInstanceDeclaration(
  name: name,
  name2: name2,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
enumImplementerContainsValuesDeclaration = const Template(
  "EnumImplementerContainsValuesDeclaration",
  withArgumentsOld: _withArgumentsOldEnumImplementerContainsValuesDeclaration,
  withArguments: _withArgumentsEnumImplementerContainsValuesDeclaration,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsEnumImplementerContainsValuesDeclaration({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    enumImplementerContainsValuesDeclaration,
    problemMessage:
        """'${name_0}' has 'Enum' as a superinterface and can't contain non-static member with name 'values'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldEnumImplementerContainsValuesDeclaration(
  String name,
) => _withArgumentsEnumImplementerContainsValuesDeclaration(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
enumInheritsRestricted = const Template(
  "EnumInheritsRestricted",
  withArgumentsOld: _withArgumentsOldEnumInheritsRestricted,
  withArguments: _withArgumentsEnumInheritsRestricted,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsEnumInheritsRestricted({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    enumInheritsRestricted,
    problemMessage: """An enum can't inherit a member named '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldEnumInheritsRestricted(String name) =>
    _withArgumentsEnumInheritsRestricted(name: name);

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
const Template<
  Message Function(String name),
  Message Function({required String name})
>
enumSupertypeOfNonAbstractClass = const Template(
  "EnumSupertypeOfNonAbstractClass",
  withArgumentsOld: _withArgumentsOldEnumSupertypeOfNonAbstractClass,
  withArguments: _withArgumentsEnumSupertypeOfNonAbstractClass,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsEnumSupertypeOfNonAbstractClass({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    enumSupertypeOfNonAbstractClass,
    problemMessage:
        """Non-abstract class '${name_0}' has 'Enum' as a superinterface.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldEnumSupertypeOfNonAbstractClass(String name) =>
    _withArgumentsEnumSupertypeOfNonAbstractClass(name: name);

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
const Template<
  Message Function(Uri uri, String string),
  Message Function({required Uri uri, required String string})
>
exceptionReadingFile = const Template(
  "ExceptionReadingFile",
  withArgumentsOld: _withArgumentsOldExceptionReadingFile,
  withArguments: _withArgumentsExceptionReadingFile,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExceptionReadingFile({
  required Uri uri,
  required String string,
}) {
  var uri_0 = conversions.relativizeUri(uri);
  var string_0 = conversions.validateString(string);
  return new Message(
    exceptionReadingFile,
    problemMessage: """Exception when reading '${uri_0}': ${string_0}""",
    arguments: {'uri': uri, 'string': string},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldExceptionReadingFile(Uri uri, String string) =>
    _withArgumentsExceptionReadingFile(uri: uri, string: string);

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
const Template<
  Message Function(String featureName),
  Message Function({required String featureName})
>
experimentDisabled = const Template(
  "ExperimentDisabled",
  withArgumentsOld: _withArgumentsOldExperimentDisabled,
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
Message _withArgumentsOldExperimentDisabled(String featureName) =>
    _withArgumentsExperimentDisabled(featureName: featureName);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String featureName, String requiredLanguageVersion),
  Message Function({
    required String featureName,
    required String requiredLanguageVersion,
  })
>
experimentDisabledInvalidLanguageVersion = const Template(
  "ExperimentDisabledInvalidLanguageVersion",
  withArgumentsOld: _withArgumentsOldExperimentDisabledInvalidLanguageVersion,
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
Message _withArgumentsOldExperimentDisabledInvalidLanguageVersion(
  String featureName,
  String requiredLanguageVersion,
) => _withArgumentsExperimentDisabledInvalidLanguageVersion(
  featureName: featureName,
  requiredLanguageVersion: requiredLanguageVersion,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
experimentExpiredDisabled = const Template(
  "ExperimentExpiredDisabled",
  withArgumentsOld: _withArgumentsOldExperimentExpiredDisabled,
  withArguments: _withArgumentsExperimentExpiredDisabled,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExperimentExpiredDisabled({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    experimentExpiredDisabled,
    problemMessage:
        """The experiment '${name_0}' has expired and can't be disabled.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldExperimentExpiredDisabled(String name) =>
    _withArgumentsExperimentExpiredDisabled(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
experimentExpiredEnabled = const Template(
  "ExperimentExpiredEnabled",
  withArgumentsOld: _withArgumentsOldExperimentExpiredEnabled,
  withArguments: _withArgumentsExperimentExpiredEnabled,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExperimentExpiredEnabled({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    experimentExpiredEnabled,
    problemMessage:
        """The experiment '${name_0}' has expired and can't be enabled.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldExperimentExpiredEnabled(String name) =>
    _withArgumentsExperimentExpiredEnabled(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string),
  Message Function({required String string})
>
experimentOptOutComment = const Template(
  "ExperimentOptOutComment",
  withArgumentsOld: _withArgumentsOldExperimentOptOutComment,
  withArguments: _withArgumentsExperimentOptOutComment,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExperimentOptOutComment({required String string}) {
  var string_0 = conversions.validateString(string);
  return new Message(
    experimentOptOutComment,
    problemMessage:
        """This is the annotation that opts out this library from the '${string_0}' language feature.""",
    arguments: {'string': string},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldExperimentOptOutComment(String string) =>
    _withArgumentsExperimentOptOutComment(string: string);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string, String string2),
  Message Function({required String string, required String string2})
>
experimentOptOutExplicit = const Template(
  "ExperimentOptOutExplicit",
  withArgumentsOld: _withArgumentsOldExperimentOptOutExplicit,
  withArguments: _withArgumentsExperimentOptOutExplicit,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExperimentOptOutExplicit({
  required String string,
  required String string2,
}) {
  var string_0 = conversions.validateString(string);
  var string2_0 = conversions.validateString(string2);
  return new Message(
    experimentOptOutExplicit,
    problemMessage:
        """The '${string_0}' language feature is disabled for this library.""",
    correctionMessage:
        """Try removing the `@dart=` annotation or setting the language version to ${string2_0} or higher.""",
    arguments: {'string': string, 'string2': string2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldExperimentOptOutExplicit(
  String string,
  String string2,
) => _withArgumentsExperimentOptOutExplicit(string: string, string2: string2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string, String string2),
  Message Function({required String string, required String string2})
>
experimentOptOutImplicit = const Template(
  "ExperimentOptOutImplicit",
  withArgumentsOld: _withArgumentsOldExperimentOptOutImplicit,
  withArguments: _withArgumentsExperimentOptOutImplicit,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExperimentOptOutImplicit({
  required String string,
  required String string2,
}) {
  var string_0 = conversions.validateString(string);
  var string2_0 = conversions.validateString(string2);
  return new Message(
    experimentOptOutImplicit,
    problemMessage:
        """The '${string_0}' language feature is disabled for this library.""",
    correctionMessage:
        """Try removing the package language version or setting the language version to ${string2_0} or higher.""",
    arguments: {'string': string, 'string2': string2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldExperimentOptOutImplicit(
  String string,
  String string2,
) => _withArgumentsExperimentOptOutImplicit(string: string, string2: string2);

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
  Message Function(String name, int count),
  Message Function({required String name, required int count})
>
explicitExtensionTypeArgumentMismatch = const Template(
  "ExplicitExtensionTypeArgumentMismatch",
  withArgumentsOld: _withArgumentsOldExplicitExtensionTypeArgumentMismatch,
  withArguments: _withArgumentsExplicitExtensionTypeArgumentMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExplicitExtensionTypeArgumentMismatch({
  required String name,
  required int count,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    explicitExtensionTypeArgumentMismatch,
    problemMessage:
        """Explicit extension application of extension '${name_0}' takes '${count}' type argument(s).""",
    arguments: {'name': name, 'count': count},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldExplicitExtensionTypeArgumentMismatch(
  String name,
  int count,
) => _withArgumentsExplicitExtensionTypeArgumentMismatch(
  name: name,
  count: count,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode exportedMain = const MessageCode(
  "ExportedMain",
  severity: CfeSeverity.context,
  problemMessage: """This is exported 'main' declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
expressionEvaluationKnownVariableUnavailable = const Template(
  "ExpressionEvaluationKnownVariableUnavailable",
  withArgumentsOld:
      _withArgumentsOldExpressionEvaluationKnownVariableUnavailable,
  withArguments: _withArgumentsExpressionEvaluationKnownVariableUnavailable,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpressionEvaluationKnownVariableUnavailable({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    expressionEvaluationKnownVariableUnavailable,
    problemMessage:
        """The variable '${name_0}' is unavailable in this expression evaluation.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldExpressionEvaluationKnownVariableUnavailable(
  String name,
) => _withArgumentsExpressionEvaluationKnownVariableUnavailable(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode expressionNotMetadata = const MessageCode(
  "ExpressionNotMetadata",
  problemMessage:
      """This can't be used as an annotation; an annotation should be a reference to a compile-time constant variable, or a call to a constant constructor.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String enumName),
  Message Function({required String enumName})
>
extendingEnum = const Template(
  "ExtendingEnum",
  withArgumentsOld: _withArgumentsOldExtendingEnum,
  withArguments: _withArgumentsExtendingEnum,
);

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
Message _withArgumentsOldExtendingEnum(String enumName) =>
    _withArgumentsExtendingEnum(enumName: enumName);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String restrictedName),
  Message Function({required String restrictedName})
>
extendingRestricted = const Template(
  "ExtendingRestricted",
  withArgumentsOld: _withArgumentsOldExtendingRestricted,
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
Message _withArgumentsOldExtendingRestricted(String restrictedName) =>
    _withArgumentsExtendingRestricted(restrictedName: restrictedName);

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
const Template<
  Message Function(String memberName),
  Message Function({required String memberName})
>
extensionMemberConflictsWithObjectMember = const Template(
  "ExtensionMemberConflictsWithObjectMember",
  withArgumentsOld: _withArgumentsOldExtensionMemberConflictsWithObjectMember,
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
Message _withArgumentsOldExtensionMemberConflictsWithObjectMember(
  String memberName,
) => _withArgumentsExtensionMemberConflictsWithObjectMember(
  memberName: memberName,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, String name2),
  Message Function({required String name, required String name2})
>
extensionTypeCombinedMemberSignatureFailed = const Template(
  "ExtensionTypeCombinedMemberSignatureFailed",
  withArgumentsOld: _withArgumentsOldExtensionTypeCombinedMemberSignatureFailed,
  withArguments: _withArgumentsExtensionTypeCombinedMemberSignatureFailed,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExtensionTypeCombinedMemberSignatureFailed({
  required String name,
  required String name2,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var name2_0 = conversions.validateAndDemangleName(name2);
  return new Message(
    extensionTypeCombinedMemberSignatureFailed,
    problemMessage:
        """Extension type '${name_0}' inherits multiple members named '${name2_0}' with incompatible signatures.""",
    correctionMessage:
        """Try adding a declaration of '${name2_0}' to '${name_0}'.""",
    arguments: {'name': name, 'name2': name2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldExtensionTypeCombinedMemberSignatureFailed(
  String name,
  String name2,
) => _withArgumentsExtensionTypeCombinedMemberSignatureFailed(
  name: name,
  name2: name2,
);

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
const Template<
  Message Function(String name),
  Message Function({required String name})
>
extensionTypeShouldBeListedAsCallableInDynamicInterface = const Template(
  "ExtensionTypeShouldBeListedAsCallableInDynamicInterface",
  withArgumentsOld:
      _withArgumentsOldExtensionTypeShouldBeListedAsCallableInDynamicInterface,
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
Message
_withArgumentsOldExtensionTypeShouldBeListedAsCallableInDynamicInterface(
  String name,
) => _withArgumentsExtensionTypeShouldBeListedAsCallableInDynamicInterface(
  name: name,
);

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
const Template<
  Message Function(String memberName),
  Message Function({required String memberName})
>
factoryConflictsWithMember = const Template(
  "FactoryConflictsWithMember",
  withArgumentsOld: _withArgumentsOldFactoryConflictsWithMember,
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
Message _withArgumentsOldFactoryConflictsWithMember(String memberName) =>
    _withArgumentsFactoryConflictsWithMember(memberName: memberName);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String memberName),
  Message Function({required String memberName})
>
factoryConflictsWithMemberCause = const Template(
  "FactoryConflictsWithMemberCause",
  withArgumentsOld: _withArgumentsOldFactoryConflictsWithMemberCause,
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
Message _withArgumentsOldFactoryConflictsWithMemberCause(String memberName) =>
    _withArgumentsFactoryConflictsWithMemberCause(memberName: memberName);

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
  Message Function(String string, String name),
  Message Function({required String string, required String name})
>
ffiCompoundImplementsFinalizable = const Template(
  "FfiCompoundImplementsFinalizable",
  withArgumentsOld: _withArgumentsOldFfiCompoundImplementsFinalizable,
  withArguments: _withArgumentsFfiCompoundImplementsFinalizable,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiCompoundImplementsFinalizable({
  required String string,
  required String name,
}) {
  var string_0 = conversions.validateString(string);
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    ffiCompoundImplementsFinalizable,
    problemMessage: """${string_0} '${name_0}' can't implement Finalizable.""",
    correctionMessage:
        """Try removing the implements clause from '${name_0}'.""",
    arguments: {'string': string, 'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldFfiCompoundImplementsFinalizable(
  String string,
  String name,
) => _withArgumentsFfiCompoundImplementsFinalizable(string: string, name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode ffiCreateOfStructOrUnion = const MessageCode(
  "FfiCreateOfStructOrUnion",
  problemMessage:
      """Subclasses of 'Struct' and 'Union' are backed by native memory, and can't be instantiated by a generative constructor. Try allocating it via allocation, or load from a 'Pointer'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type, DartType type2),
  Message Function({required DartType type, required DartType type2})
>
ffiDartTypeMismatch = const Template(
  "FfiDartTypeMismatch",
  withArgumentsOld: _withArgumentsOldFfiDartTypeMismatch,
  withArguments: _withArgumentsFfiDartTypeMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiDartTypeMismatch({
  required DartType type,
  required DartType type2,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var type2_0 = labeler.labelType(type2);
  return new Message(
    ffiDartTypeMismatch,
    problemMessage:
        """Expected '${type_0}' to be a subtype of '${type2_0}'.""" +
        labeler.originMessages,
    arguments: {'type': type, 'type2': type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldFfiDartTypeMismatch(DartType type, DartType type2) =>
    _withArgumentsFfiDartTypeMismatch(type: type, type2: type2);

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
  Message Function(String string, String name),
  Message Function({required String string, required String name})
>
ffiEmptyStruct = const Template(
  "FfiEmptyStruct",
  withArgumentsOld: _withArgumentsOldFfiEmptyStruct,
  withArguments: _withArgumentsFfiEmptyStruct,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiEmptyStruct({
  required String string,
  required String name,
}) {
  var string_0 = conversions.validateString(string);
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    ffiEmptyStruct,
    problemMessage:
        """${string_0} '${name_0}' is empty. Empty structs and unions are undefined behavior.""",
    arguments: {'string': string, 'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldFfiEmptyStruct(String string, String name) =>
    _withArgumentsFfiEmptyStruct(string: string, name: name);

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
const Template<
  Message Function(String name),
  Message Function({required String name})
>
ffiExpectedConstantArg = const Template(
  "FfiExpectedConstantArg",
  withArgumentsOld: _withArgumentsOldFfiExpectedConstantArg,
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
Message _withArgumentsOldFfiExpectedConstantArg(String name) =>
    _withArgumentsFfiExpectedConstantArg(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type),
  Message Function({required DartType type})
>
ffiExpectedExceptionalReturn = const Template(
  "FfiExpectedExceptionalReturn",
  withArgumentsOld: _withArgumentsOldFfiExpectedExceptionalReturn,
  withArguments: _withArgumentsFfiExpectedExceptionalReturn,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiExpectedExceptionalReturn({required DartType type}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    ffiExpectedExceptionalReturn,
    problemMessage:
        """Expected an exceptional return value for a native callback returning '${type_0}'.""" +
        labeler.originMessages,
    arguments: {'type': type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldFfiExpectedExceptionalReturn(DartType type) =>
    _withArgumentsFfiExpectedExceptionalReturn(type: type);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type),
  Message Function({required DartType type})
>
ffiExpectedNoExceptionalReturn = const Template(
  "FfiExpectedNoExceptionalReturn",
  withArgumentsOld: _withArgumentsOldFfiExpectedNoExceptionalReturn,
  withArguments: _withArgumentsFfiExpectedNoExceptionalReturn,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiExpectedNoExceptionalReturn({required DartType type}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    ffiExpectedNoExceptionalReturn,
    problemMessage:
        """Exceptional return value cannot be provided for a native callback returning '${type_0}'.""" +
        labeler.originMessages,
    arguments: {'type': type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldFfiExpectedNoExceptionalReturn(DartType type) =>
    _withArgumentsFfiExpectedNoExceptionalReturn(type: type);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
ffiExtendsOrImplementsSealedClass = const Template(
  "FfiExtendsOrImplementsSealedClass",
  withArgumentsOld: _withArgumentsOldFfiExtendsOrImplementsSealedClass,
  withArguments: _withArgumentsFfiExtendsOrImplementsSealedClass,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiExtendsOrImplementsSealedClass({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    ffiExtendsOrImplementsSealedClass,
    problemMessage: """Class '${name_0}' cannot be extended or implemented.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldFfiExtendsOrImplementsSealedClass(String name) =>
    _withArgumentsFfiExtendsOrImplementsSealedClass(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
ffiFieldAnnotation = const Template(
  "FfiFieldAnnotation",
  withArgumentsOld: _withArgumentsOldFfiFieldAnnotation,
  withArguments: _withArgumentsFfiFieldAnnotation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiFieldAnnotation({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    ffiFieldAnnotation,
    problemMessage:
        """Field '${name_0}' requires exactly one annotation to declare its native type, which cannot be Void. dart:ffi Structs and Unions cannot have regular Dart fields.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldFfiFieldAnnotation(String name) =>
    _withArgumentsFfiFieldAnnotation(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string, String name, List<String> names),
  Message Function({
    required String string,
    required String name,
    required List<String> names,
  })
>
ffiFieldCyclic = const Template(
  "FfiFieldCyclic",
  withArgumentsOld: _withArgumentsOldFfiFieldCyclic,
  withArguments: _withArgumentsFfiFieldCyclic,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiFieldCyclic({
  required String string,
  required String name,
  required List<String> names,
}) {
  var string_0 = conversions.validateString(string);
  var name_0 = conversions.validateAndDemangleName(name);
  var names_0 = conversions.validateAndItemizeNames(names);
  return new Message(
    ffiFieldCyclic,
    problemMessage: """${string_0} '${name_0}' contains itself. Cycle elements:
${names_0}""",
    arguments: {'string': string, 'name': name, 'names': names},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldFfiFieldCyclic(
  String string,
  String name,
  List<String> names,
) => _withArgumentsFfiFieldCyclic(string: string, name: name, names: names);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
ffiFieldInitializer = const Template(
  "FfiFieldInitializer",
  withArgumentsOld: _withArgumentsOldFfiFieldInitializer,
  withArguments: _withArgumentsFfiFieldInitializer,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiFieldInitializer({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    ffiFieldInitializer,
    problemMessage:
        """Field '${name_0}' is a dart:ffi Pointer to a struct field and therefore cannot be initialized before constructor execution.""",
    correctionMessage:
        """Mark the field as external to avoid having to initialize it.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldFfiFieldInitializer(String name) =>
    _withArgumentsFfiFieldInitializer(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
ffiFieldNoAnnotation = const Template(
  "FfiFieldNoAnnotation",
  withArgumentsOld: _withArgumentsOldFfiFieldNoAnnotation,
  withArguments: _withArgumentsFfiFieldNoAnnotation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiFieldNoAnnotation({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    ffiFieldNoAnnotation,
    problemMessage:
        """Field '${name_0}' requires no annotation to declare its native type, it is a Pointer which is represented by the same type in Dart and native code.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldFfiFieldNoAnnotation(String name) =>
    _withArgumentsFfiFieldNoAnnotation(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
ffiFieldNull = const Template(
  "FfiFieldNull",
  withArgumentsOld: _withArgumentsOldFfiFieldNull,
  withArguments: _withArgumentsFfiFieldNull,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiFieldNull({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    ffiFieldNull,
    problemMessage:
        """Field '${name_0}' cannot be nullable or have type 'Null', it must be `int`, `double`, `Pointer`, or a subtype of `Struct` or `Union`.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldFfiFieldNull(String name) =>
    _withArgumentsFfiFieldNull(name: name);

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
const Template<
  Message Function(DartType type),
  Message Function({required DartType type})
>
ffiNativeCallableListenerReturnVoid = const Template(
  "FfiNativeCallableListenerReturnVoid",
  withArgumentsOld: _withArgumentsOldFfiNativeCallableListenerReturnVoid,
  withArguments: _withArgumentsFfiNativeCallableListenerReturnVoid,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiNativeCallableListenerReturnVoid({
  required DartType type,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    ffiNativeCallableListenerReturnVoid,
    problemMessage:
        """The return type of the function passed to NativeCallable.listener must be void rather than '${type_0}'.""" +
        labeler.originMessages,
    arguments: {'type': type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldFfiNativeCallableListenerReturnVoid(DartType type) =>
    _withArgumentsFfiNativeCallableListenerReturnVoid(type: type);

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
  Message Function(int count, int count2),
  Message Function({required int count, required int count2})
>
ffiNativeUnexpectedNumberOfParameters = const Template(
  "FfiNativeUnexpectedNumberOfParameters",
  withArgumentsOld: _withArgumentsOldFfiNativeUnexpectedNumberOfParameters,
  withArguments: _withArgumentsFfiNativeUnexpectedNumberOfParameters,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiNativeUnexpectedNumberOfParameters({
  required int count,
  required int count2,
}) {
  return new Message(
    ffiNativeUnexpectedNumberOfParameters,
    problemMessage:
        """Unexpected number of Native annotation parameters. Expected ${count} but has ${count2}.""",
    arguments: {'count': count, 'count2': count2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldFfiNativeUnexpectedNumberOfParameters(
  int count,
  int count2,
) => _withArgumentsFfiNativeUnexpectedNumberOfParameters(
  count: count,
  count2: count2,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(int count, int count2),
  Message Function({required int count, required int count2})
>
ffiNativeUnexpectedNumberOfParametersWithReceiver = const Template(
  "FfiNativeUnexpectedNumberOfParametersWithReceiver",
  withArgumentsOld:
      _withArgumentsOldFfiNativeUnexpectedNumberOfParametersWithReceiver,
  withArguments:
      _withArgumentsFfiNativeUnexpectedNumberOfParametersWithReceiver,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiNativeUnexpectedNumberOfParametersWithReceiver({
  required int count,
  required int count2,
}) {
  return new Message(
    ffiNativeUnexpectedNumberOfParametersWithReceiver,
    problemMessage:
        """Unexpected number of Native annotation parameters. Expected ${count} but has ${count2}. Native instance method annotation must have receiver as first argument.""",
    arguments: {'count': count, 'count2': count2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldFfiNativeUnexpectedNumberOfParametersWithReceiver(
  int count,
  int count2,
) => _withArgumentsFfiNativeUnexpectedNumberOfParametersWithReceiver(
  count: count,
  count2: count2,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
ffiNotStatic = const Template(
  "FfiNotStatic",
  withArgumentsOld: _withArgumentsOldFfiNotStatic,
  withArguments: _withArgumentsFfiNotStatic,
);

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
Message _withArgumentsOldFfiNotStatic(String name) =>
    _withArgumentsFfiNotStatic(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
ffiPackedAnnotation = const Template(
  "FfiPackedAnnotation",
  withArgumentsOld: _withArgumentsOldFfiPackedAnnotation,
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
Message _withArgumentsOldFfiPackedAnnotation(String name) =>
    _withArgumentsFfiPackedAnnotation(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode ffiPackedAnnotationAlignment = const MessageCode(
  "FfiPackedAnnotationAlignment",
  problemMessage: """Only packing to 1, 2, 4, 8, and 16 bytes is supported.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
ffiSizeAnnotation = const Template(
  "FfiSizeAnnotation",
  withArgumentsOld: _withArgumentsOldFfiSizeAnnotation,
  withArguments: _withArgumentsFfiSizeAnnotation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiSizeAnnotation({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    ffiSizeAnnotation,
    problemMessage:
        """Field '${name_0}' must have exactly one 'Array' annotation.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldFfiSizeAnnotation(String name) =>
    _withArgumentsFfiSizeAnnotation(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
ffiSizeAnnotationDimensions = const Template(
  "FfiSizeAnnotationDimensions",
  withArgumentsOld: _withArgumentsOldFfiSizeAnnotationDimensions,
  withArguments: _withArgumentsFfiSizeAnnotationDimensions,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiSizeAnnotationDimensions({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    ffiSizeAnnotationDimensions,
    problemMessage:
        """Field '${name_0}' must have an 'Array' annotation that matches the dimensions.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldFfiSizeAnnotationDimensions(String name) =>
    _withArgumentsFfiSizeAnnotationDimensions(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string, String name),
  Message Function({required String string, required String name})
>
ffiStructGeneric = const Template(
  "FfiStructGeneric",
  withArgumentsOld: _withArgumentsOldFfiStructGeneric,
  withArguments: _withArgumentsFfiStructGeneric,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiStructGeneric({
  required String string,
  required String name,
}) {
  var string_0 = conversions.validateString(string);
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    ffiStructGeneric,
    problemMessage: """${string_0} '${name_0}' should not be generic.""",
    arguments: {'string': string, 'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldFfiStructGeneric(String string, String name) =>
    _withArgumentsFfiStructGeneric(string: string, name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type),
  Message Function({required DartType type})
>
ffiTypeInvalid = const Template(
  "FfiTypeInvalid",
  withArgumentsOld: _withArgumentsOldFfiTypeInvalid,
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
Message _withArgumentsOldFfiTypeInvalid(DartType type) =>
    _withArgumentsFfiTypeInvalid(type: type);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type, DartType type2, DartType type3),
  Message Function({
    required DartType type,
    required DartType type2,
    required DartType type3,
  })
>
ffiTypeMismatch = const Template(
  "FfiTypeMismatch",
  withArgumentsOld: _withArgumentsOldFfiTypeMismatch,
  withArguments: _withArgumentsFfiTypeMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiTypeMismatch({
  required DartType type,
  required DartType type2,
  required DartType type3,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var type2_0 = labeler.labelType(type2);
  var type3_0 = labeler.labelType(type3);
  return new Message(
    ffiTypeMismatch,
    problemMessage:
        """Expected type '${type_0}' to be '${type2_0}', which is the Dart type corresponding to '${type3_0}'.""" +
        labeler.originMessages,
    arguments: {'type': type, 'type2': type2, 'type3': type3},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldFfiTypeMismatch(
  DartType type,
  DartType type2,
  DartType type3,
) => _withArgumentsFfiTypeMismatch(type: type, type2: type2, type3: type3);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode ffiVariableLengthArrayNotLast = const MessageCode(
  "FfiVariableLengthArrayNotLast",
  problemMessage:
      """Variable length 'Array's must only occur as the last field of Structs.""",
  correctionMessage:
      """Try adjusting the arguments in the 'Array' annotation.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
fieldAlreadyInitializedAtDeclaration = const Template(
  "FieldAlreadyInitializedAtDeclaration",
  withArgumentsOld: _withArgumentsOldFieldAlreadyInitializedAtDeclaration,
  withArguments: _withArgumentsFieldAlreadyInitializedAtDeclaration,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFieldAlreadyInitializedAtDeclaration({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    fieldAlreadyInitializedAtDeclaration,
    problemMessage:
        """'${name_0}' is a final instance variable that was initialized at the declaration.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldFieldAlreadyInitializedAtDeclaration(String name) =>
    _withArgumentsFieldAlreadyInitializedAtDeclaration(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
fieldAlreadyInitializedAtDeclarationCause = const Template(
  "FieldAlreadyInitializedAtDeclarationCause",
  withArgumentsOld: _withArgumentsOldFieldAlreadyInitializedAtDeclarationCause,
  withArguments: _withArgumentsFieldAlreadyInitializedAtDeclarationCause,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFieldAlreadyInitializedAtDeclarationCause({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    fieldAlreadyInitializedAtDeclarationCause,
    problemMessage: """'${name_0}' was initialized here.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldFieldAlreadyInitializedAtDeclarationCause(
  String name,
) => _withArgumentsFieldAlreadyInitializedAtDeclarationCause(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, DartType type),
  Message Function({required String name, required DartType type})
>
fieldNonNullableNotInitializedByConstructorError = const Template(
  "FieldNonNullableNotInitializedByConstructorError",
  withArgumentsOld:
      _withArgumentsOldFieldNonNullableNotInitializedByConstructorError,
  withArguments: _withArgumentsFieldNonNullableNotInitializedByConstructorError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFieldNonNullableNotInitializedByConstructorError({
  required String name,
  required DartType type,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    fieldNonNullableNotInitializedByConstructorError,
    problemMessage:
        """This constructor should initialize field '${name_0}' because its type '${type_0}' doesn't allow null.""" +
        labeler.originMessages,
    arguments: {'name': name, 'type': type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldFieldNonNullableNotInitializedByConstructorError(
  String name,
  DartType type,
) => _withArgumentsFieldNonNullableNotInitializedByConstructorError(
  name: name,
  type: type,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, DartType type),
  Message Function({required String name, required DartType type})
>
fieldNonNullableWithoutInitializerError = const Template(
  "FieldNonNullableWithoutInitializerError",
  withArgumentsOld: _withArgumentsOldFieldNonNullableWithoutInitializerError,
  withArguments: _withArgumentsFieldNonNullableWithoutInitializerError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFieldNonNullableWithoutInitializerError({
  required String name,
  required DartType type,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    fieldNonNullableWithoutInitializerError,
    problemMessage:
        """Field '${name_0}' should be initialized because its type '${type_0}' doesn't allow null.""" +
        labeler.originMessages,
    arguments: {'name': name, 'type': type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldFieldNonNullableWithoutInitializerError(
  String name,
  DartType type,
) => _withArgumentsFieldNonNullableWithoutInitializerError(
  name: name,
  type: type,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, String name2, String string),
  Message Function({
    required String name,
    required String name2,
    required String string,
  })
>
fieldNotPromotedBecauseConflictingField = const Template(
  "FieldNotPromotedBecauseConflictingField",
  withArgumentsOld: _withArgumentsOldFieldNotPromotedBecauseConflictingField,
  withArguments: _withArgumentsFieldNotPromotedBecauseConflictingField,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFieldNotPromotedBecauseConflictingField({
  required String name,
  required String name2,
  required String string,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var name2_0 = conversions.validateAndDemangleName(name2);
  var string_0 = conversions.validateString(string);
  return new Message(
    fieldNotPromotedBecauseConflictingField,
    problemMessage:
        """'${name_0}' couldn't be promoted because there is a conflicting non-promotable field in class '${name2_0}'.""",
    correctionMessage: """See ${string_0}""",
    arguments: {'name': name, 'name2': name2, 'string': string},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldFieldNotPromotedBecauseConflictingField(
  String name,
  String name2,
  String string,
) => _withArgumentsFieldNotPromotedBecauseConflictingField(
  name: name,
  name2: name2,
  string: string,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, String name2, String string),
  Message Function({
    required String name,
    required String name2,
    required String string,
  })
>
fieldNotPromotedBecauseConflictingGetter = const Template(
  "FieldNotPromotedBecauseConflictingGetter",
  withArgumentsOld: _withArgumentsOldFieldNotPromotedBecauseConflictingGetter,
  withArguments: _withArgumentsFieldNotPromotedBecauseConflictingGetter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFieldNotPromotedBecauseConflictingGetter({
  required String name,
  required String name2,
  required String string,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var name2_0 = conversions.validateAndDemangleName(name2);
  var string_0 = conversions.validateString(string);
  return new Message(
    fieldNotPromotedBecauseConflictingGetter,
    problemMessage:
        """'${name_0}' couldn't be promoted because there is a conflicting getter in class '${name2_0}'.""",
    correctionMessage: """See ${string_0}""",
    arguments: {'name': name, 'name2': name2, 'string': string},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldFieldNotPromotedBecauseConflictingGetter(
  String name,
  String name2,
  String string,
) => _withArgumentsFieldNotPromotedBecauseConflictingGetter(
  name: name,
  name2: name2,
  string: string,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, String name2, String string),
  Message Function({
    required String name,
    required String name2,
    required String string,
  })
>
fieldNotPromotedBecauseConflictingNsmForwarder = const Template(
  "FieldNotPromotedBecauseConflictingNsmForwarder",
  withArgumentsOld:
      _withArgumentsOldFieldNotPromotedBecauseConflictingNsmForwarder,
  withArguments: _withArgumentsFieldNotPromotedBecauseConflictingNsmForwarder,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFieldNotPromotedBecauseConflictingNsmForwarder({
  required String name,
  required String name2,
  required String string,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var name2_0 = conversions.validateAndDemangleName(name2);
  var string_0 = conversions.validateString(string);
  return new Message(
    fieldNotPromotedBecauseConflictingNsmForwarder,
    problemMessage:
        """'${name_0}' couldn't be promoted because there is a conflicting noSuchMethod forwarder in class '${name2_0}'.""",
    correctionMessage: """See ${string_0}""",
    arguments: {'name': name, 'name2': name2, 'string': string},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldFieldNotPromotedBecauseConflictingNsmForwarder(
  String name,
  String name2,
  String string,
) => _withArgumentsFieldNotPromotedBecauseConflictingNsmForwarder(
  name: name,
  name2: name2,
  string: string,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, String string),
  Message Function({required String name, required String string})
>
fieldNotPromotedBecauseExternal = const Template(
  "FieldNotPromotedBecauseExternal",
  withArgumentsOld: _withArgumentsOldFieldNotPromotedBecauseExternal,
  withArguments: _withArgumentsFieldNotPromotedBecauseExternal,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFieldNotPromotedBecauseExternal({
  required String name,
  required String string,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var string_0 = conversions.validateString(string);
  return new Message(
    fieldNotPromotedBecauseExternal,
    problemMessage:
        """'${name_0}' refers to an external field so it couldn't be promoted.""",
    correctionMessage: """See ${string_0}""",
    arguments: {'name': name, 'string': string},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldFieldNotPromotedBecauseExternal(
  String name,
  String string,
) => _withArgumentsFieldNotPromotedBecauseExternal(name: name, string: string);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, String string),
  Message Function({required String name, required String string})
>
fieldNotPromotedBecauseNotEnabled = const Template(
  "FieldNotPromotedBecauseNotEnabled",
  withArgumentsOld: _withArgumentsOldFieldNotPromotedBecauseNotEnabled,
  withArguments: _withArgumentsFieldNotPromotedBecauseNotEnabled,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFieldNotPromotedBecauseNotEnabled({
  required String name,
  required String string,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var string_0 = conversions.validateString(string);
  return new Message(
    fieldNotPromotedBecauseNotEnabled,
    problemMessage:
        """'${name_0}' couldn't be promoted because field promotion is only available in Dart 3.2 and above.""",
    correctionMessage: """See ${string_0}""",
    arguments: {'name': name, 'string': string},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldFieldNotPromotedBecauseNotEnabled(
  String name,
  String string,
) =>
    _withArgumentsFieldNotPromotedBecauseNotEnabled(name: name, string: string);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, String string),
  Message Function({required String name, required String string})
>
fieldNotPromotedBecauseNotField = const Template(
  "FieldNotPromotedBecauseNotField",
  withArgumentsOld: _withArgumentsOldFieldNotPromotedBecauseNotField,
  withArguments: _withArgumentsFieldNotPromotedBecauseNotField,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFieldNotPromotedBecauseNotField({
  required String name,
  required String string,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var string_0 = conversions.validateString(string);
  return new Message(
    fieldNotPromotedBecauseNotField,
    problemMessage:
        """'${name_0}' refers to a getter so it couldn't be promoted.""",
    correctionMessage: """See ${string_0}""",
    arguments: {'name': name, 'string': string},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldFieldNotPromotedBecauseNotField(
  String name,
  String string,
) => _withArgumentsFieldNotPromotedBecauseNotField(name: name, string: string);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, String string),
  Message Function({required String name, required String string})
>
fieldNotPromotedBecauseNotFinal = const Template(
  "FieldNotPromotedBecauseNotFinal",
  withArgumentsOld: _withArgumentsOldFieldNotPromotedBecauseNotFinal,
  withArguments: _withArgumentsFieldNotPromotedBecauseNotFinal,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFieldNotPromotedBecauseNotFinal({
  required String name,
  required String string,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var string_0 = conversions.validateString(string);
  return new Message(
    fieldNotPromotedBecauseNotFinal,
    problemMessage:
        """'${name_0}' refers to a non-final field so it couldn't be promoted.""",
    correctionMessage: """See ${string_0}""",
    arguments: {'name': name, 'string': string},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldFieldNotPromotedBecauseNotFinal(
  String name,
  String string,
) => _withArgumentsFieldNotPromotedBecauseNotFinal(name: name, string: string);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, String string),
  Message Function({required String name, required String string})
>
fieldNotPromotedBecauseNotPrivate = const Template(
  "FieldNotPromotedBecauseNotPrivate",
  withArgumentsOld: _withArgumentsOldFieldNotPromotedBecauseNotPrivate,
  withArguments: _withArgumentsFieldNotPromotedBecauseNotPrivate,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFieldNotPromotedBecauseNotPrivate({
  required String name,
  required String string,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var string_0 = conversions.validateString(string);
  return new Message(
    fieldNotPromotedBecauseNotPrivate,
    problemMessage:
        """'${name_0}' refers to a public property so it couldn't be promoted.""",
    correctionMessage: """See ${string_0}""",
    arguments: {'name': name, 'string': string},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldFieldNotPromotedBecauseNotPrivate(
  String name,
  String string,
) =>
    _withArgumentsFieldNotPromotedBecauseNotPrivate(name: name, string: string);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
finalClassExtendedOutsideOfLibrary = const Template(
  "FinalClassExtendedOutsideOfLibrary",
  withArgumentsOld: _withArgumentsOldFinalClassExtendedOutsideOfLibrary,
  withArguments: _withArgumentsFinalClassExtendedOutsideOfLibrary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFinalClassExtendedOutsideOfLibrary({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    finalClassExtendedOutsideOfLibrary,
    problemMessage:
        """The class '${name_0}' can't be extended outside of its library because it's a final class.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldFinalClassExtendedOutsideOfLibrary(String name) =>
    _withArgumentsFinalClassExtendedOutsideOfLibrary(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
finalClassImplementedOutsideOfLibrary = const Template(
  "FinalClassImplementedOutsideOfLibrary",
  withArgumentsOld: _withArgumentsOldFinalClassImplementedOutsideOfLibrary,
  withArguments: _withArgumentsFinalClassImplementedOutsideOfLibrary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFinalClassImplementedOutsideOfLibrary({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    finalClassImplementedOutsideOfLibrary,
    problemMessage:
        """The class '${name_0}' can't be implemented outside of its library because it's a final class.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldFinalClassImplementedOutsideOfLibrary(String name) =>
    _withArgumentsFinalClassImplementedOutsideOfLibrary(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
finalClassUsedAsMixinConstraintOutsideOfLibrary = const Template(
  "FinalClassUsedAsMixinConstraintOutsideOfLibrary",
  withArgumentsOld:
      _withArgumentsOldFinalClassUsedAsMixinConstraintOutsideOfLibrary,
  withArguments: _withArgumentsFinalClassUsedAsMixinConstraintOutsideOfLibrary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFinalClassUsedAsMixinConstraintOutsideOfLibrary({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    finalClassUsedAsMixinConstraintOutsideOfLibrary,
    problemMessage:
        """The class '${name_0}' can't be used as a mixin superclass constraint outside of its library because it's a final class.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldFinalClassUsedAsMixinConstraintOutsideOfLibrary(
  String name,
) => _withArgumentsFinalClassUsedAsMixinConstraintOutsideOfLibrary(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String fieldName),
  Message Function({required String fieldName})
>
finalFieldNotInitialized = const Template(
  "FinalFieldNotInitialized",
  withArgumentsOld: _withArgumentsOldFinalFieldNotInitialized,
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
Message _withArgumentsOldFinalFieldNotInitialized(String fieldName) =>
    _withArgumentsFinalFieldNotInitialized(fieldName: fieldName);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String fieldName),
  Message Function({required String fieldName})
>
finalFieldNotInitializedByConstructor = const Template(
  "FinalFieldNotInitializedByConstructor",
  withArgumentsOld: _withArgumentsOldFinalFieldNotInitializedByConstructor,
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
Message _withArgumentsOldFinalFieldNotInitializedByConstructor(
  String fieldName,
) => _withArgumentsFinalFieldNotInitializedByConstructor(fieldName: fieldName);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
finalNotAssignedError = const Template(
  "FinalNotAssignedError",
  withArgumentsOld: _withArgumentsOldFinalNotAssignedError,
  withArguments: _withArgumentsFinalNotAssignedError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFinalNotAssignedError({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    finalNotAssignedError,
    problemMessage:
        """Final variable '${name_0}' must be assigned before it can be used.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldFinalNotAssignedError(String name) =>
    _withArgumentsFinalNotAssignedError(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
finalPossiblyAssignedError = const Template(
  "FinalPossiblyAssignedError",
  withArgumentsOld: _withArgumentsOldFinalPossiblyAssignedError,
  withArguments: _withArgumentsFinalPossiblyAssignedError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFinalPossiblyAssignedError({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    finalPossiblyAssignedError,
    problemMessage:
        """Final variable '${name_0}' might already be assigned at this point.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldFinalPossiblyAssignedError(String name) =>
    _withArgumentsFinalPossiblyAssignedError(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type, DartType type2),
  Message Function({required DartType type, required DartType type2})
>
forInLoopElementTypeNotAssignable = const Template(
  "ForInLoopElementTypeNotAssignable",
  withArgumentsOld: _withArgumentsOldForInLoopElementTypeNotAssignable,
  withArguments: _withArgumentsForInLoopElementTypeNotAssignable,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsForInLoopElementTypeNotAssignable({
  required DartType type,
  required DartType type2,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var type2_0 = labeler.labelType(type2);
  return new Message(
    forInLoopElementTypeNotAssignable,
    problemMessage:
        """A value of type '${type_0}' can't be assigned to a variable of type '${type2_0}'.""" +
        labeler.originMessages,
    correctionMessage: """Try changing the type of the variable.""",
    arguments: {'type': type, 'type2': type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldForInLoopElementTypeNotAssignable(
  DartType type,
  DartType type2,
) => _withArgumentsForInLoopElementTypeNotAssignable(type: type, type2: type2);

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
  Message Function(DartType type, DartType type2),
  Message Function({required DartType type, required DartType type2})
>
forInLoopTypeNotIterable = const Template(
  "ForInLoopTypeNotIterable",
  withArgumentsOld: _withArgumentsOldForInLoopTypeNotIterable,
  withArguments: _withArgumentsForInLoopTypeNotIterable,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsForInLoopTypeNotIterable({
  required DartType type,
  required DartType type2,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var type2_0 = labeler.labelType(type2);
  return new Message(
    forInLoopTypeNotIterable,
    problemMessage:
        """The type '${type_0}' used in the 'for' loop must implement '${type2_0}'.""" +
        labeler.originMessages,
    arguments: {'type': type, 'type2': type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldForInLoopTypeNotIterable(
  DartType type,
  DartType type2,
) => _withArgumentsForInLoopTypeNotIterable(type: type, type2: type2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode forInLoopWithConstVariable = const MessageCode(
  "ForInLoopWithConstVariable",
  problemMessage: """A for-in loop-variable can't be 'const'.""",
  correctionMessage: """Try removing the 'const' modifier.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type, DartType type2),
  Message Function({required DartType type, required DartType type2})
>
genericFunctionTypeAsTypeArgumentThroughTypedef = const Template(
  "GenericFunctionTypeAsTypeArgumentThroughTypedef",
  withArgumentsOld:
      _withArgumentsOldGenericFunctionTypeAsTypeArgumentThroughTypedef,
  withArguments: _withArgumentsGenericFunctionTypeAsTypeArgumentThroughTypedef,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsGenericFunctionTypeAsTypeArgumentThroughTypedef({
  required DartType type,
  required DartType type2,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var type2_0 = labeler.labelType(type2);
  return new Message(
    genericFunctionTypeAsTypeArgumentThroughTypedef,
    problemMessage:
        """Generic function type '${type_0}' used as a type argument through typedef '${type2_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try providing a non-generic function type explicitly.""",
    arguments: {'type': type, 'type2': type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldGenericFunctionTypeAsTypeArgumentThroughTypedef(
  DartType type,
  DartType type2,
) => _withArgumentsGenericFunctionTypeAsTypeArgumentThroughTypedef(
  type: type,
  type2: type2,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode genericFunctionTypeInBound = const MessageCode(
  "GenericFunctionTypeInBound",
  problemMessage:
      """Type variables can't have generic function types in their bounds.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type),
  Message Function({required DartType type})
>
genericFunctionTypeInferredAsActualTypeArgument = const Template(
  "GenericFunctionTypeInferredAsActualTypeArgument",
  withArgumentsOld:
      _withArgumentsOldGenericFunctionTypeInferredAsActualTypeArgument,
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
Message _withArgumentsOldGenericFunctionTypeInferredAsActualTypeArgument(
  DartType type,
) => _withArgumentsGenericFunctionTypeInferredAsActualTypeArgument(type: type);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode genericFunctionTypeUsedAsActualTypeArgument =
    const MessageCode(
      "GenericFunctionTypeUsedAsActualTypeArgument",
      problemMessage:
          """A generic function type can't be used as a type argument.""",
      correctionMessage: """Try using a non-generic function type.""",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
getterNotFound = const Template(
  "GetterNotFound",
  withArgumentsOld: _withArgumentsOldGetterNotFound,
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
Message _withArgumentsOldGetterNotFound(String name) =>
    _withArgumentsGetterNotFound(name: name);

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
const Template<
  Message Function(String typeName),
  Message Function({required String typeName})
>
illegalMixin = const Template(
  "IllegalMixin",
  withArgumentsOld: _withArgumentsOldIllegalMixin,
  withArguments: _withArgumentsIllegalMixin,
);

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
Message _withArgumentsOldIllegalMixin(String typeName) =>
    _withArgumentsIllegalMixin(typeName: typeName);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String className),
  Message Function({required String className})
>
illegalMixinDueToConstructors = const Template(
  "IllegalMixinDueToConstructors",
  withArgumentsOld: _withArgumentsOldIllegalMixinDueToConstructors,
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
Message _withArgumentsOldIllegalMixinDueToConstructors(String className) =>
    _withArgumentsIllegalMixinDueToConstructors(className: className);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String className),
  Message Function({required String className})
>
illegalMixinDueToConstructorsCause = const Template(
  "IllegalMixinDueToConstructorsCause",
  withArgumentsOld: _withArgumentsOldIllegalMixinDueToConstructorsCause,
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
Message _withArgumentsOldIllegalMixinDueToConstructorsCause(String className) =>
    _withArgumentsIllegalMixinDueToConstructorsCause(className: className);

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
  Message Function(String name, String name2),
  Message Function({required String name, required String name2})
>
implementMultipleExtensionTypeMembers = const Template(
  "ImplementMultipleExtensionTypeMembers",
  withArgumentsOld: _withArgumentsOldImplementMultipleExtensionTypeMembers,
  withArguments: _withArgumentsImplementMultipleExtensionTypeMembers,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsImplementMultipleExtensionTypeMembers({
  required String name,
  required String name2,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var name2_0 = conversions.validateAndDemangleName(name2);
  return new Message(
    implementMultipleExtensionTypeMembers,
    problemMessage:
        """The extension type '${name_0}' can't inherit the member '${name2_0}' from more than one extension type.""",
    correctionMessage:
        """Try declaring a member '${name2_0}' in '${name_0}' to resolve the conflict.""",
    arguments: {'name': name, 'name2': name2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldImplementMultipleExtensionTypeMembers(
  String name,
  String name2,
) => _withArgumentsImplementMultipleExtensionTypeMembers(
  name: name,
  name2: name2,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, String name2),
  Message Function({required String name, required String name2})
>
implementNonExtensionTypeAndExtensionTypeMember = const Template(
  "ImplementNonExtensionTypeAndExtensionTypeMember",
  withArgumentsOld:
      _withArgumentsOldImplementNonExtensionTypeAndExtensionTypeMember,
  withArguments: _withArgumentsImplementNonExtensionTypeAndExtensionTypeMember,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsImplementNonExtensionTypeAndExtensionTypeMember({
  required String name,
  required String name2,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var name2_0 = conversions.validateAndDemangleName(name2);
  return new Message(
    implementNonExtensionTypeAndExtensionTypeMember,
    problemMessage:
        """The extension type '${name_0}' can't inherit the member '${name2_0}' as both an extension type member and a non-extension type member.""",
    correctionMessage:
        """Try declaring a member '${name2_0}' in '${name_0}' to resolve the conflict.""",
    arguments: {'name': name, 'name2': name2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldImplementNonExtensionTypeAndExtensionTypeMember(
  String name,
  String name2,
) => _withArgumentsImplementNonExtensionTypeAndExtensionTypeMember(
  name: name,
  name2: name2,
);

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
  Message Function(String name, int extraCount),
  Message Function({required String name, required int extraCount})
>
implementsRepeated = const Template(
  "ImplementsRepeated",
  withArgumentsOld: _withArgumentsOldImplementsRepeated,
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
Message _withArgumentsOldImplementsRepeated(String name, int extraCount) =>
    _withArgumentsImplementsRepeated(name: name, extraCount: extraCount);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
implementsSuperClass = const Template(
  "ImplementsSuperClass",
  withArgumentsOld: _withArgumentsOldImplementsSuperClass,
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
Message _withArgumentsOldImplementsSuperClass(String name) =>
    _withArgumentsImplementsSuperClass(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type),
  Message Function({required DartType type})
>
implicitCallOfNonMethod = const Template(
  "ImplicitCallOfNonMethod",
  withArgumentsOld: _withArgumentsOldImplicitCallOfNonMethod,
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
Message _withArgumentsOldImplicitCallOfNonMethod(DartType type) =>
    _withArgumentsImplicitCallOfNonMethod(type: type);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String mixinName, String baseName, String erroneousMember),
  Message Function({
    required String mixinName,
    required String baseName,
    required String erroneousMember,
  })
>
implicitMixinOverride = const Template(
  "ImplicitMixinOverride",
  withArgumentsOld: _withArgumentsOldImplicitMixinOverride,
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
Message _withArgumentsOldImplicitMixinOverride(
  String mixinName,
  String baseName,
  String erroneousMember,
) => _withArgumentsImplicitMixinOverride(
  mixinName: mixinName,
  baseName: baseName,
  erroneousMember: erroneousMember,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type),
  Message Function({required DartType type})
>
implicitReturnNull = const Template(
  "ImplicitReturnNull",
  withArgumentsOld: _withArgumentsOldImplicitReturnNull,
  withArguments: _withArgumentsImplicitReturnNull,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsImplicitReturnNull({required DartType type}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    implicitReturnNull,
    problemMessage:
        """A non-null value must be returned since the return type '${type_0}' doesn't allow null.""" +
        labeler.originMessages,
    arguments: {'type': type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldImplicitReturnNull(DartType type) =>
    _withArgumentsImplicitReturnNull(type: type);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode implicitSuperCallOfNonMethod = const MessageCode(
  "ImplicitSuperCallOfNonMethod",
  problemMessage:
      """Cannot invoke `super` because it declares 'call' to be something other than a method.""",
  correctionMessage:
      """Try changing 'call' to a method or explicitly invoke 'call'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
implicitSuperInitializerMissingArguments = const Template(
  "ImplicitSuperInitializerMissingArguments",
  withArgumentsOld: _withArgumentsOldImplicitSuperInitializerMissingArguments,
  withArguments: _withArgumentsImplicitSuperInitializerMissingArguments,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsImplicitSuperInitializerMissingArguments({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    implicitSuperInitializerMissingArguments,
    problemMessage:
        """The implicitly called unnamed constructor from '${name_0}' has required parameters.""",
    correctionMessage:
        """Try adding an explicit super initializer with the required arguments.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldImplicitSuperInitializerMissingArguments(
  String name,
) => _withArgumentsImplicitSuperInitializerMissingArguments(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Uri uri, String string, String string2),
  Message Function({
    required Uri uri,
    required String string,
    required String string2,
  })
>
importChainContext = const Template(
  "ImportChainContext",
  withArgumentsOld: _withArgumentsOldImportChainContext,
  withArguments: _withArgumentsImportChainContext,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsImportChainContext({
  required Uri uri,
  required String string,
  required String string2,
}) {
  var uri_0 = conversions.relativizeUri(uri);
  var string_0 = conversions.validateString(string);
  var string2_0 = conversions.validateString(string2);
  return new Message(
    importChainContext,
    problemMessage:
        """The unavailable library '${uri_0}' is imported through these packages:

${string_0}
Detailed import paths for (some of) the these imports:

${string2_0}""",
    arguments: {'uri': uri, 'string': string, 'string2': string2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldImportChainContext(
  Uri uri,
  String string,
  String string2,
) => _withArgumentsImportChainContext(
  uri: uri,
  string: string,
  string2: string2,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Uri uri, String string),
  Message Function({required Uri uri, required String string})
>
importChainContextSimple = const Template(
  "ImportChainContextSimple",
  withArgumentsOld: _withArgumentsOldImportChainContextSimple,
  withArguments: _withArgumentsImportChainContextSimple,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsImportChainContextSimple({
  required Uri uri,
  required String string,
}) {
  var uri_0 = conversions.relativizeUri(uri);
  var string_0 = conversions.validateString(string);
  return new Message(
    importChainContextSimple,
    problemMessage:
        """The unavailable library '${uri_0}' is imported through these paths:

${string_0}""",
    arguments: {'uri': uri, 'string': string},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldImportChainContextSimple(Uri uri, String string) =>
    _withArgumentsImportChainContextSimple(uri: uri, string: string);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type, DartType type2),
  Message Function({required DartType type, required DartType type2})
>
incompatibleRedirecteeFunctionType = const Template(
  "IncompatibleRedirecteeFunctionType",
  withArgumentsOld: _withArgumentsOldIncompatibleRedirecteeFunctionType,
  withArguments: _withArgumentsIncompatibleRedirecteeFunctionType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIncompatibleRedirecteeFunctionType({
  required DartType type,
  required DartType type2,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var type2_0 = labeler.labelType(type2);
  return new Message(
    incompatibleRedirecteeFunctionType,
    problemMessage:
        """The constructor function type '${type_0}' isn't a subtype of '${type2_0}'.""" +
        labeler.originMessages,
    arguments: {'type': type, 'type2': type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldIncompatibleRedirecteeFunctionType(
  DartType type,
  DartType type2,
) => _withArgumentsIncompatibleRedirecteeFunctionType(type: type, type2: type2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type, DartType type2, String name, String name2),
  Message Function({
    required DartType type,
    required DartType type2,
    required String name,
    required String name2,
  })
>
incorrectTypeArgument = const Template(
  "IncorrectTypeArgument",
  withArgumentsOld: _withArgumentsOldIncorrectTypeArgument,
  withArguments: _withArgumentsIncorrectTypeArgument,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIncorrectTypeArgument({
  required DartType type,
  required DartType type2,
  required String name,
  required String name2,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var type2_0 = labeler.labelType(type2);
  var name_0 = conversions.validateAndDemangleName(name);
  var name2_0 = conversions.validateAndDemangleName(name2);
  return new Message(
    incorrectTypeArgument,
    problemMessage:
        """Type argument '${type_0}' doesn't conform to the bound '${type2_0}' of the type variable '${name_0}' on '${name2_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try changing type arguments so that they conform to the bounds.""",
    arguments: {'type': type, 'type2': type2, 'name': name, 'name2': name2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldIncorrectTypeArgument(
  DartType type,
  DartType type2,
  String name,
  String name2,
) => _withArgumentsIncorrectTypeArgument(
  type: type,
  type2: type2,
  name: name,
  name2: name2,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type, DartType type2, String name, String name2),
  Message Function({
    required DartType type,
    required DartType type2,
    required String name,
    required String name2,
  })
>
incorrectTypeArgumentInferred = const Template(
  "IncorrectTypeArgumentInferred",
  withArgumentsOld: _withArgumentsOldIncorrectTypeArgumentInferred,
  withArguments: _withArgumentsIncorrectTypeArgumentInferred,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIncorrectTypeArgumentInferred({
  required DartType type,
  required DartType type2,
  required String name,
  required String name2,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var type2_0 = labeler.labelType(type2);
  var name_0 = conversions.validateAndDemangleName(name);
  var name2_0 = conversions.validateAndDemangleName(name2);
  return new Message(
    incorrectTypeArgumentInferred,
    problemMessage:
        """Inferred type argument '${type_0}' doesn't conform to the bound '${type2_0}' of the type variable '${name_0}' on '${name2_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try specifying type arguments explicitly so that they conform to the bounds.""",
    arguments: {'type': type, 'type2': type2, 'name': name, 'name2': name2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldIncorrectTypeArgumentInferred(
  DartType type,
  DartType type2,
  String name,
  String name2,
) => _withArgumentsIncorrectTypeArgumentInferred(
  type: type,
  type2: type2,
  name: name,
  name2: name2,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type, DartType type2, String name, DartType type3),
  Message Function({
    required DartType type,
    required DartType type2,
    required String name,
    required DartType type3,
  })
>
incorrectTypeArgumentInstantiation = const Template(
  "IncorrectTypeArgumentInstantiation",
  withArgumentsOld: _withArgumentsOldIncorrectTypeArgumentInstantiation,
  withArguments: _withArgumentsIncorrectTypeArgumentInstantiation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIncorrectTypeArgumentInstantiation({
  required DartType type,
  required DartType type2,
  required String name,
  required DartType type3,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var type2_0 = labeler.labelType(type2);
  var name_0 = conversions.validateAndDemangleName(name);
  var type3_0 = labeler.labelType(type3);
  return new Message(
    incorrectTypeArgumentInstantiation,
    problemMessage:
        """Type argument '${type_0}' doesn't conform to the bound '${type2_0}' of the type variable '${name_0}' on '${type3_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try changing type arguments so that they conform to the bounds.""",
    arguments: {'type': type, 'type2': type2, 'name': name, 'type3': type3},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldIncorrectTypeArgumentInstantiation(
  DartType type,
  DartType type2,
  String name,
  DartType type3,
) => _withArgumentsIncorrectTypeArgumentInstantiation(
  type: type,
  type2: type2,
  name: name,
  type3: type3,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type, DartType type2, String name, DartType type3),
  Message Function({
    required DartType type,
    required DartType type2,
    required String name,
    required DartType type3,
  })
>
incorrectTypeArgumentInstantiationInferred = const Template(
  "IncorrectTypeArgumentInstantiationInferred",
  withArgumentsOld: _withArgumentsOldIncorrectTypeArgumentInstantiationInferred,
  withArguments: _withArgumentsIncorrectTypeArgumentInstantiationInferred,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIncorrectTypeArgumentInstantiationInferred({
  required DartType type,
  required DartType type2,
  required String name,
  required DartType type3,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var type2_0 = labeler.labelType(type2);
  var name_0 = conversions.validateAndDemangleName(name);
  var type3_0 = labeler.labelType(type3);
  return new Message(
    incorrectTypeArgumentInstantiationInferred,
    problemMessage:
        """Inferred type argument '${type_0}' doesn't conform to the bound '${type2_0}' of the type variable '${name_0}' on '${type3_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try specifying type arguments explicitly so that they conform to the bounds.""",
    arguments: {'type': type, 'type2': type2, 'name': name, 'type3': type3},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldIncorrectTypeArgumentInstantiationInferred(
  DartType type,
  DartType type2,
  String name,
  DartType type3,
) => _withArgumentsIncorrectTypeArgumentInstantiationInferred(
  type: type,
  type2: type2,
  name: name,
  type3: type3,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(
    DartType type,
    DartType type2,
    String name,
    DartType type3,
    String name2,
  ),
  Message Function({
    required DartType type,
    required DartType type2,
    required String name,
    required DartType type3,
    required String name2,
  })
>
incorrectTypeArgumentQualified = const Template(
  "IncorrectTypeArgumentQualified",
  withArgumentsOld: _withArgumentsOldIncorrectTypeArgumentQualified,
  withArguments: _withArgumentsIncorrectTypeArgumentQualified,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIncorrectTypeArgumentQualified({
  required DartType type,
  required DartType type2,
  required String name,
  required DartType type3,
  required String name2,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var type2_0 = labeler.labelType(type2);
  var name_0 = conversions.validateAndDemangleName(name);
  var type3_0 = labeler.labelType(type3);
  var name2_0 = conversions.validateAndDemangleName(name2);
  return new Message(
    incorrectTypeArgumentQualified,
    problemMessage:
        """Type argument '${type_0}' doesn't conform to the bound '${type2_0}' of the type variable '${name_0}' on '${type3_0}.${name2_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try changing type arguments so that they conform to the bounds.""",
    arguments: {
      'type': type,
      'type2': type2,
      'name': name,
      'type3': type3,
      'name2': name2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldIncorrectTypeArgumentQualified(
  DartType type,
  DartType type2,
  String name,
  DartType type3,
  String name2,
) => _withArgumentsIncorrectTypeArgumentQualified(
  type: type,
  type2: type2,
  name: name,
  type3: type3,
  name2: name2,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(
    DartType type,
    DartType type2,
    String name,
    DartType type3,
    String name2,
  ),
  Message Function({
    required DartType type,
    required DartType type2,
    required String name,
    required DartType type3,
    required String name2,
  })
>
incorrectTypeArgumentQualifiedInferred = const Template(
  "IncorrectTypeArgumentQualifiedInferred",
  withArgumentsOld: _withArgumentsOldIncorrectTypeArgumentQualifiedInferred,
  withArguments: _withArgumentsIncorrectTypeArgumentQualifiedInferred,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIncorrectTypeArgumentQualifiedInferred({
  required DartType type,
  required DartType type2,
  required String name,
  required DartType type3,
  required String name2,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var type2_0 = labeler.labelType(type2);
  var name_0 = conversions.validateAndDemangleName(name);
  var type3_0 = labeler.labelType(type3);
  var name2_0 = conversions.validateAndDemangleName(name2);
  return new Message(
    incorrectTypeArgumentQualifiedInferred,
    problemMessage:
        """Inferred type argument '${type_0}' doesn't conform to the bound '${type2_0}' of the type variable '${name_0}' on '${type3_0}.${name2_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try specifying type arguments explicitly so that they conform to the bounds.""",
    arguments: {
      'type': type,
      'type2': type2,
      'name': name,
      'type3': type3,
      'name2': name2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldIncorrectTypeArgumentQualifiedInferred(
  DartType type,
  DartType type2,
  String name,
  DartType type3,
  String name2,
) => _withArgumentsIncorrectTypeArgumentQualifiedInferred(
  type: type,
  type2: type2,
  name: name,
  type3: type3,
  name2: name2,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode incorrectTypeArgumentVariable = const MessageCode(
  "IncorrectTypeArgumentVariable",
  severity: CfeSeverity.context,
  problemMessage:
      """This is the type variable whose bound isn't conformed to.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String parameterName),
  Message Function({required String parameterName})
>
incrementalCompilerIllegalParameter = const Template(
  "IncrementalCompilerIllegalParameter",
  withArgumentsOld: _withArgumentsOldIncrementalCompilerIllegalParameter,
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
Message _withArgumentsOldIncrementalCompilerIllegalParameter(
  String parameterName,
) => _withArgumentsIncrementalCompilerIllegalParameter(
  parameterName: parameterName,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String typeParameterName),
  Message Function({required String typeParameterName})
>
incrementalCompilerIllegalTypeParameter = const Template(
  "IncrementalCompilerIllegalTypeParameter",
  withArgumentsOld: _withArgumentsOldIncrementalCompilerIllegalTypeParameter,
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
Message _withArgumentsOldIncrementalCompilerIllegalTypeParameter(
  String typeParameterName,
) => _withArgumentsIncrementalCompilerIllegalTypeParameter(
  typeParameterName: typeParameterName,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(int count, int count2, DartType type),
  Message Function({
    required int count,
    required int count2,
    required DartType type,
  })
>
indexOutOfBoundInRecordIndexGet = const Template(
  "IndexOutOfBoundInRecordIndexGet",
  withArgumentsOld: _withArgumentsOldIndexOutOfBoundInRecordIndexGet,
  withArguments: _withArgumentsIndexOutOfBoundInRecordIndexGet,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIndexOutOfBoundInRecordIndexGet({
  required int count,
  required int count2,
  required DartType type,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    indexOutOfBoundInRecordIndexGet,
    problemMessage:
        """Index ${count} is out of range 0..${count2} of positional fields of records ${type_0}.""" +
        labeler.originMessages,
    arguments: {'count': count, 'count2': count2, 'type': type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldIndexOutOfBoundInRecordIndexGet(
  int count,
  int count2,
  DartType type,
) => _withArgumentsIndexOutOfBoundInRecordIndexGet(
  count: count,
  count2: count2,
  type: type,
);

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
  Message Function(String name, String name2),
  Message Function({required String name, required String name2})
>
inheritedRestrictedMemberOfEnumImplementer = const Template(
  "InheritedRestrictedMemberOfEnumImplementer",
  withArgumentsOld: _withArgumentsOldInheritedRestrictedMemberOfEnumImplementer,
  withArguments: _withArgumentsInheritedRestrictedMemberOfEnumImplementer,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInheritedRestrictedMemberOfEnumImplementer({
  required String name,
  required String name2,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var name2_0 = conversions.validateAndDemangleName(name2);
  return new Message(
    inheritedRestrictedMemberOfEnumImplementer,
    problemMessage:
        """A concrete instance member named '${name_0}' can't be inherited from '${name2_0}' in a class that implements 'Enum'.""",
    arguments: {'name': name, 'name2': name2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInheritedRestrictedMemberOfEnumImplementer(
  String name,
  String name2,
) => _withArgumentsInheritedRestrictedMemberOfEnumImplementer(
  name: name,
  name2: name2,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string, Uri uri),
  Message Function({required String string, required Uri uri})
>
initializeFromDillNotSelfContained = const Template(
  "InitializeFromDillNotSelfContained",
  withArgumentsOld: _withArgumentsOldInitializeFromDillNotSelfContained,
  withArguments: _withArgumentsInitializeFromDillNotSelfContained,
  severity: CfeSeverity.warning,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInitializeFromDillNotSelfContained({
  required String string,
  required Uri uri,
}) {
  var string_0 = conversions.validateString(string);
  var uri_0 = conversions.relativizeUri(uri);
  return new Message(
    initializeFromDillNotSelfContained,
    problemMessage:
        """Tried to initialize from a previous compilation (${string_0}), but the file was not self-contained. This might be a bug.

The Dart team would greatly appreciate it if you would take a moment to report this problem at http://dartbug.com/new.
If you are comfortable with it, it would improve the chances of fixing any bug if you included the file ${uri_0} in your error report, but be aware that this file includes your source code.
Either way, you should probably delete the file so it doesn't use unnecessary disk space.""",
    arguments: {'string': string, 'uri': uri},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInitializeFromDillNotSelfContained(
  String string,
  Uri uri,
) => _withArgumentsInitializeFromDillNotSelfContained(string: string, uri: uri);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string),
  Message Function({required String string})
>
initializeFromDillNotSelfContainedNoDump = const Template(
  "InitializeFromDillNotSelfContainedNoDump",
  withArgumentsOld: _withArgumentsOldInitializeFromDillNotSelfContainedNoDump,
  withArguments: _withArgumentsInitializeFromDillNotSelfContainedNoDump,
  severity: CfeSeverity.warning,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInitializeFromDillNotSelfContainedNoDump({
  required String string,
}) {
  var string_0 = conversions.validateString(string);
  return new Message(
    initializeFromDillNotSelfContainedNoDump,
    problemMessage:
        """Tried to initialize from a previous compilation (${string_0}), but the file was not self-contained. This might be a bug.

The Dart team would greatly appreciate it if you would take a moment to report this problem at http://dartbug.com/new.""",
    arguments: {'string': string},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInitializeFromDillNotSelfContainedNoDump(
  String string,
) => _withArgumentsInitializeFromDillNotSelfContainedNoDump(string: string);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string, String string2, String string3, Uri uri),
  Message Function({
    required String string,
    required String string2,
    required String string3,
    required Uri uri,
  })
>
initializeFromDillUnknownProblem = const Template(
  "InitializeFromDillUnknownProblem",
  withArgumentsOld: _withArgumentsOldInitializeFromDillUnknownProblem,
  withArguments: _withArgumentsInitializeFromDillUnknownProblem,
  severity: CfeSeverity.warning,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInitializeFromDillUnknownProblem({
  required String string,
  required String string2,
  required String string3,
  required Uri uri,
}) {
  var string_0 = conversions.validateString(string);
  var string2_0 = conversions.validateString(string2);
  var string3_0 = conversions.validateString(string3);
  var uri_0 = conversions.relativizeUri(uri);
  return new Message(
    initializeFromDillUnknownProblem,
    problemMessage:
        """Tried to initialize from a previous compilation (${string_0}), but couldn't.
Error message was '${string2_0}'.
Stacktrace included '${string3_0}'.
This might be a bug.

The Dart team would greatly appreciate it if you would take a moment to report this problem at http://dartbug.com/new.
If you are comfortable with it, it would improve the chances of fixing any bug if you included the file ${uri_0} in your error report, but be aware that this file includes your source code.
Either way, you should probably delete the file so it doesn't use unnecessary disk space.""",
    arguments: {
      'string': string,
      'string2': string2,
      'string3': string3,
      'uri': uri,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInitializeFromDillUnknownProblem(
  String string,
  String string2,
  String string3,
  Uri uri,
) => _withArgumentsInitializeFromDillUnknownProblem(
  string: string,
  string2: string2,
  string3: string3,
  uri: uri,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string, String string2, String string3),
  Message Function({
    required String string,
    required String string2,
    required String string3,
  })
>
initializeFromDillUnknownProblemNoDump = const Template(
  "InitializeFromDillUnknownProblemNoDump",
  withArgumentsOld: _withArgumentsOldInitializeFromDillUnknownProblemNoDump,
  withArguments: _withArgumentsInitializeFromDillUnknownProblemNoDump,
  severity: CfeSeverity.warning,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInitializeFromDillUnknownProblemNoDump({
  required String string,
  required String string2,
  required String string3,
}) {
  var string_0 = conversions.validateString(string);
  var string2_0 = conversions.validateString(string2);
  var string3_0 = conversions.validateString(string3);
  return new Message(
    initializeFromDillUnknownProblemNoDump,
    problemMessage:
        """Tried to initialize from a previous compilation (${string_0}), but couldn't.
Error message was '${string2_0}'.
Stacktrace included '${string3_0}'.
This might be a bug.

The Dart team would greatly appreciate it if you would take a moment to report this problem at http://dartbug.com/new.""",
    arguments: {'string': string, 'string2': string2, 'string3': string3},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInitializeFromDillUnknownProblemNoDump(
  String string,
  String string2,
  String string3,
) => _withArgumentsInitializeFromDillUnknownProblemNoDump(
  string: string,
  string2: string2,
  string3: string3,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String fieldName),
  Message Function({required String fieldName})
>
initializerForStaticField = const Template(
  "InitializerForStaticField",
  withArgumentsOld: _withArgumentsOldInitializerForStaticField,
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
Message _withArgumentsOldInitializerForStaticField(String fieldName) =>
    _withArgumentsInitializerForStaticField(fieldName: fieldName);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, DartType type, DartType type2),
  Message Function({
    required String name,
    required DartType type,
    required DartType type2,
  })
>
initializingFormalTypeMismatch = const Template(
  "InitializingFormalTypeMismatch",
  withArgumentsOld: _withArgumentsOldInitializingFormalTypeMismatch,
  withArguments: _withArgumentsInitializingFormalTypeMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInitializingFormalTypeMismatch({
  required String name,
  required DartType type,
  required DartType type2,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var type2_0 = labeler.labelType(type2);
  return new Message(
    initializingFormalTypeMismatch,
    problemMessage:
        """The type of parameter '${name_0}', '${type_0}' is not a subtype of the corresponding field's type, '${type2_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try changing the type of parameter '${name_0}' to a subtype of '${type2_0}'.""",
    arguments: {'name': name, 'type': type, 'type2': type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInitializingFormalTypeMismatch(
  String name,
  DartType type,
  DartType type2,
) => _withArgumentsInitializingFormalTypeMismatch(
  name: name,
  type: type,
  type2: type2,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode initializingFormalTypeMismatchField = const MessageCode(
  "InitializingFormalTypeMismatchField",
  severity: CfeSeverity.context,
  problemMessage: """The field that corresponds to the parameter.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri), Message Function({required Uri uri})>
inputFileNotFound = const Template(
  "InputFileNotFound",
  withArgumentsOld: _withArgumentsOldInputFileNotFound,
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
Message _withArgumentsOldInputFileNotFound(Uri uri) =>
    _withArgumentsInputFileNotFound(uri: uri);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
instanceAndSynthesizedStaticConflict = const Template(
  "InstanceAndSynthesizedStaticConflict",
  withArgumentsOld: _withArgumentsOldInstanceAndSynthesizedStaticConflict,
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
Message _withArgumentsOldInstanceAndSynthesizedStaticConflict(String name) =>
    _withArgumentsInstanceAndSynthesizedStaticConflict(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String propertyName),
  Message Function({required String propertyName})
>
instanceConflictsWithStatic = const Template(
  "InstanceConflictsWithStatic",
  withArgumentsOld: _withArgumentsOldInstanceConflictsWithStatic,
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
Message _withArgumentsOldInstanceConflictsWithStatic(String propertyName) =>
    _withArgumentsInstanceConflictsWithStatic(propertyName: propertyName);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String propertyName),
  Message Function({required String propertyName})
>
instanceConflictsWithStaticCause = const Template(
  "InstanceConflictsWithStaticCause",
  withArgumentsOld: _withArgumentsOldInstanceConflictsWithStaticCause,
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
Message _withArgumentsOldInstanceConflictsWithStaticCause(
  String propertyName,
) => _withArgumentsInstanceConflictsWithStaticCause(propertyName: propertyName);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type),
  Message Function({required DartType type})
>
instantiationNonGenericFunctionType = const Template(
  "InstantiationNonGenericFunctionType",
  withArgumentsOld: _withArgumentsOldInstantiationNonGenericFunctionType,
  withArguments: _withArgumentsInstantiationNonGenericFunctionType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInstantiationNonGenericFunctionType({
  required DartType type,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    instantiationNonGenericFunctionType,
    problemMessage:
        """The static type of the explicit instantiation operand must be a generic function type but is '${type_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try changing the operand or remove the type arguments.""",
    arguments: {'type': type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInstantiationNonGenericFunctionType(DartType type) =>
    _withArgumentsInstantiationNonGenericFunctionType(type: type);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type),
  Message Function({required DartType type})
>
instantiationNullableGenericFunctionType = const Template(
  "InstantiationNullableGenericFunctionType",
  withArgumentsOld: _withArgumentsOldInstantiationNullableGenericFunctionType,
  withArguments: _withArgumentsInstantiationNullableGenericFunctionType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInstantiationNullableGenericFunctionType({
  required DartType type,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    instantiationNullableGenericFunctionType,
    problemMessage:
        """The static type of the explicit instantiation operand must be a non-null generic function type but is '${type_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try changing the operand or remove the type arguments.""",
    arguments: {'type': type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInstantiationNullableGenericFunctionType(
  DartType type,
) => _withArgumentsInstantiationNullableGenericFunctionType(type: type);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(int count, int count2),
  Message Function({required int count, required int count2})
>
instantiationTooFewArguments = const Template(
  "InstantiationTooFewArguments",
  withArgumentsOld: _withArgumentsOldInstantiationTooFewArguments,
  withArguments: _withArgumentsInstantiationTooFewArguments,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInstantiationTooFewArguments({
  required int count,
  required int count2,
}) {
  return new Message(
    instantiationTooFewArguments,
    problemMessage:
        """Too few type arguments: ${count} required, ${count2} given.""",
    correctionMessage: """Try adding the missing type arguments.""",
    arguments: {'count': count, 'count2': count2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInstantiationTooFewArguments(int count, int count2) =>
    _withArgumentsInstantiationTooFewArguments(count: count, count2: count2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(int count, int count2),
  Message Function({required int count, required int count2})
>
instantiationTooManyArguments = const Template(
  "InstantiationTooManyArguments",
  withArgumentsOld: _withArgumentsOldInstantiationTooManyArguments,
  withArguments: _withArgumentsInstantiationTooManyArguments,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInstantiationTooManyArguments({
  required int count,
  required int count2,
}) {
  return new Message(
    instantiationTooManyArguments,
    problemMessage:
        """Too many type arguments: ${count} allowed, but ${count2} found.""",
    correctionMessage: """Try removing the extra type arguments.""",
    arguments: {'count': count, 'count2': count2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInstantiationTooManyArguments(int count, int count2) =>
    _withArgumentsInstantiationTooManyArguments(count: count, count2: count2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string),
  Message Function({required String string})
>
integerLiteralIsOutOfRange = const Template(
  "IntegerLiteralIsOutOfRange",
  withArgumentsOld: _withArgumentsOldIntegerLiteralIsOutOfRange,
  withArguments: _withArgumentsIntegerLiteralIsOutOfRange,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIntegerLiteralIsOutOfRange({required String string}) {
  var string_0 = conversions.validateString(string);
  return new Message(
    integerLiteralIsOutOfRange,
    problemMessage:
        """The integer literal ${string_0} can't be represented in 64 bits.""",
    correctionMessage:
        """Try using the BigInt class if you need an integer larger than 9,223,372,036,854,775,807 or less than -9,223,372,036,854,775,808.""",
    arguments: {'string': string},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldIntegerLiteralIsOutOfRange(String string) =>
    _withArgumentsIntegerLiteralIsOutOfRange(string: string);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String memberName, String className),
  Message Function({required String memberName, required String className})
>
interfaceCheck = const Template(
  "InterfaceCheck",
  withArgumentsOld: _withArgumentsOldInterfaceCheck,
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
Message _withArgumentsOldInterfaceCheck(String memberName, String className) =>
    _withArgumentsInterfaceCheck(memberName: memberName, className: className);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
interfaceClassExtendedOutsideOfLibrary = const Template(
  "InterfaceClassExtendedOutsideOfLibrary",
  withArgumentsOld: _withArgumentsOldInterfaceClassExtendedOutsideOfLibrary,
  withArguments: _withArgumentsInterfaceClassExtendedOutsideOfLibrary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInterfaceClassExtendedOutsideOfLibrary({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    interfaceClassExtendedOutsideOfLibrary,
    problemMessage:
        """The class '${name_0}' can't be extended outside of its library because it's an interface class.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInterfaceClassExtendedOutsideOfLibrary(String name) =>
    _withArgumentsInterfaceClassExtendedOutsideOfLibrary(name: name);

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
const Template<
  Message Function(String name, Uri uri),
  Message Function({required String name, required Uri uri})
>
internalProblemConstructorNotFound = const Template(
  "InternalProblemConstructorNotFound",
  withArgumentsOld: _withArgumentsOldInternalProblemConstructorNotFound,
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
Message _withArgumentsOldInternalProblemConstructorNotFound(
  String name,
  Uri uri,
) => _withArgumentsInternalProblemConstructorNotFound(name: name, uri: uri);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String messageCode),
  Message Function({required String messageCode})
>
internalProblemContextSeverity = const Template(
  "InternalProblemContextSeverity",
  withArgumentsOld: _withArgumentsOldInternalProblemContextSeverity,
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
Message _withArgumentsOldInternalProblemContextSeverity(String messageCode) =>
    _withArgumentsInternalProblemContextSeverity(messageCode: messageCode);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String severityName, String stackTrace),
  Message Function({required String severityName, required String stackTrace})
>
internalProblemDebugAbort = const Template(
  "InternalProblemDebugAbort",
  withArgumentsOld: _withArgumentsOldInternalProblemDebugAbort,
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
Message _withArgumentsOldInternalProblemDebugAbort(
  String severityName,
  String stackTrace,
) => _withArgumentsInternalProblemDebugAbort(
  severityName: severityName,
  stackTrace: stackTrace,
);

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
const Template<
  Message Function(String name),
  Message Function({required String name})
>
internalProblemNotFound = const Template(
  "InternalProblemNotFound",
  withArgumentsOld: _withArgumentsOldInternalProblemNotFound,
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
Message _withArgumentsOldInternalProblemNotFound(String name) =>
    _withArgumentsInternalProblemNotFound(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, String within),
  Message Function({required String name, required String within})
>
internalProblemNotFoundIn = const Template(
  "InternalProblemNotFoundIn",
  withArgumentsOld: _withArgumentsOldInternalProblemNotFoundIn,
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
Message _withArgumentsOldInternalProblemNotFoundIn(
  String name,
  String within,
) => _withArgumentsInternalProblemNotFoundIn(name: name, within: within);

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
const Template<
  Message Function(String name),
  Message Function({required String name})
>
internalProblemPrivateConstructorAccess = const Template(
  "InternalProblemPrivateConstructorAccess",
  withArgumentsOld: _withArgumentsOldInternalProblemPrivateConstructorAccess,
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
Message _withArgumentsOldInternalProblemPrivateConstructorAccess(String name) =>
    _withArgumentsInternalProblemPrivateConstructorAccess(name: name);

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
  Message Function(String expected, String actual),
  Message Function({required String expected, required String actual})
>
internalProblemUnexpected = const Template(
  "InternalProblemUnexpected",
  withArgumentsOld: _withArgumentsOldInternalProblemUnexpected,
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
Message _withArgumentsOldInternalProblemUnexpected(
  String expected,
  String actual,
) =>
    _withArgumentsInternalProblemUnexpected(expected: expected, actual: actual);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String what),
  Message Function({required String what})
>
internalProblemUnimplemented = const Template(
  "InternalProblemUnimplemented",
  withArgumentsOld: _withArgumentsOldInternalProblemUnimplemented,
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
Message _withArgumentsOldInternalProblemUnimplemented(String what) =>
    _withArgumentsInternalProblemUnimplemented(what: what);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String nullability, DartType type),
  Message Function({required String nullability, required DartType type})
>
internalProblemUnsupportedNullability = const Template(
  "InternalProblemUnsupportedNullability",
  withArgumentsOld: _withArgumentsOldInternalProblemUnsupportedNullability,
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
Message _withArgumentsOldInternalProblemUnsupportedNullability(
  String nullability,
  DartType type,
) => _withArgumentsInternalProblemUnsupportedNullability(
  nullability: nullability,
  type: type,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri), Message Function({required Uri uri})>
internalProblemUriMissingScheme = const Template(
  "InternalProblemUriMissingScheme",
  withArgumentsOld: _withArgumentsOldInternalProblemUriMissingScheme,
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
Message _withArgumentsOldInternalProblemUriMissingScheme(Uri uri) =>
    _withArgumentsInternalProblemUriMissingScheme(uri: uri);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String details),
  Message Function({required String details})
>
internalProblemVerificationError = const Template(
  "InternalProblemVerificationError",
  withArgumentsOld: _withArgumentsOldInternalProblemVerificationError,
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
Message _withArgumentsOldInternalProblemVerificationError(String details) =>
    _withArgumentsInternalProblemVerificationError(details: details);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type, DartType type2),
  Message Function({required DartType type, required DartType type2})
>
invalidAssignmentError = const Template(
  "InvalidAssignmentError",
  withArgumentsOld: _withArgumentsOldInvalidAssignmentError,
  withArguments: _withArgumentsInvalidAssignmentError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidAssignmentError({
  required DartType type,
  required DartType type2,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var type2_0 = labeler.labelType(type2);
  return new Message(
    invalidAssignmentError,
    problemMessage:
        """A value of type '${type_0}' can't be assigned to a variable of type '${type2_0}'.""" +
        labeler.originMessages,
    arguments: {'type': type, 'type2': type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidAssignmentError(
  DartType type,
  DartType type2,
) => _withArgumentsInvalidAssignmentError(type: type, type2: type2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode invalidAugmentSuper = const MessageCode(
  "InvalidAugmentSuper",
  problemMessage:
      """'augment super' is only allowed in member augmentations.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String label),
  Message Function({required String label})
>
invalidBreakTarget = const Template(
  "InvalidBreakTarget",
  withArgumentsOld: _withArgumentsOldInvalidBreakTarget,
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
Message _withArgumentsOldInvalidBreakTarget(String label) =>
    _withArgumentsInvalidBreakTarget(label: label);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type, DartType type2),
  Message Function({required DartType type, required DartType type2})
>
invalidCastFunctionExpr = const Template(
  "InvalidCastFunctionExpr",
  withArgumentsOld: _withArgumentsOldInvalidCastFunctionExpr,
  withArguments: _withArgumentsInvalidCastFunctionExpr,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidCastFunctionExpr({
  required DartType type,
  required DartType type2,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var type2_0 = labeler.labelType(type2);
  return new Message(
    invalidCastFunctionExpr,
    problemMessage:
        """The function expression type '${type_0}' isn't of expected type '${type2_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Change the type of the function expression or the context in which it is used.""",
    arguments: {'type': type, 'type2': type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidCastFunctionExpr(
  DartType type,
  DartType type2,
) => _withArgumentsInvalidCastFunctionExpr(type: type, type2: type2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type, DartType type2),
  Message Function({required DartType type, required DartType type2})
>
invalidCastLiteralList = const Template(
  "InvalidCastLiteralList",
  withArgumentsOld: _withArgumentsOldInvalidCastLiteralList,
  withArguments: _withArgumentsInvalidCastLiteralList,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidCastLiteralList({
  required DartType type,
  required DartType type2,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var type2_0 = labeler.labelType(type2);
  return new Message(
    invalidCastLiteralList,
    problemMessage:
        """The list literal type '${type_0}' isn't of expected type '${type2_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Change the type of the list literal or the context in which it is used.""",
    arguments: {'type': type, 'type2': type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidCastLiteralList(
  DartType type,
  DartType type2,
) => _withArgumentsInvalidCastLiteralList(type: type, type2: type2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type, DartType type2),
  Message Function({required DartType type, required DartType type2})
>
invalidCastLiteralMap = const Template(
  "InvalidCastLiteralMap",
  withArgumentsOld: _withArgumentsOldInvalidCastLiteralMap,
  withArguments: _withArgumentsInvalidCastLiteralMap,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidCastLiteralMap({
  required DartType type,
  required DartType type2,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var type2_0 = labeler.labelType(type2);
  return new Message(
    invalidCastLiteralMap,
    problemMessage:
        """The map literal type '${type_0}' isn't of expected type '${type2_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Change the type of the map literal or the context in which it is used.""",
    arguments: {'type': type, 'type2': type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidCastLiteralMap(DartType type, DartType type2) =>
    _withArgumentsInvalidCastLiteralMap(type: type, type2: type2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type, DartType type2),
  Message Function({required DartType type, required DartType type2})
>
invalidCastLiteralSet = const Template(
  "InvalidCastLiteralSet",
  withArgumentsOld: _withArgumentsOldInvalidCastLiteralSet,
  withArguments: _withArgumentsInvalidCastLiteralSet,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidCastLiteralSet({
  required DartType type,
  required DartType type2,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var type2_0 = labeler.labelType(type2);
  return new Message(
    invalidCastLiteralSet,
    problemMessage:
        """The set literal type '${type_0}' isn't of expected type '${type2_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Change the type of the set literal or the context in which it is used.""",
    arguments: {'type': type, 'type2': type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidCastLiteralSet(DartType type, DartType type2) =>
    _withArgumentsInvalidCastLiteralSet(type: type, type2: type2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type, DartType type2),
  Message Function({required DartType type, required DartType type2})
>
invalidCastLocalFunction = const Template(
  "InvalidCastLocalFunction",
  withArgumentsOld: _withArgumentsOldInvalidCastLocalFunction,
  withArguments: _withArgumentsInvalidCastLocalFunction,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidCastLocalFunction({
  required DartType type,
  required DartType type2,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var type2_0 = labeler.labelType(type2);
  return new Message(
    invalidCastLocalFunction,
    problemMessage:
        """The local function has type '${type_0}' that isn't of expected type '${type2_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Change the type of the function or the context in which it is used.""",
    arguments: {'type': type, 'type2': type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidCastLocalFunction(
  DartType type,
  DartType type2,
) => _withArgumentsInvalidCastLocalFunction(type: type, type2: type2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type, DartType type2),
  Message Function({required DartType type, required DartType type2})
>
invalidCastNewExpr = const Template(
  "InvalidCastNewExpr",
  withArgumentsOld: _withArgumentsOldInvalidCastNewExpr,
  withArguments: _withArgumentsInvalidCastNewExpr,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidCastNewExpr({
  required DartType type,
  required DartType type2,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var type2_0 = labeler.labelType(type2);
  return new Message(
    invalidCastNewExpr,
    problemMessage:
        """The constructor returns type '${type_0}' that isn't of expected type '${type2_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Change the type of the object being constructed or the context in which it is used.""",
    arguments: {'type': type, 'type2': type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidCastNewExpr(DartType type, DartType type2) =>
    _withArgumentsInvalidCastNewExpr(type: type, type2: type2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type, DartType type2),
  Message Function({required DartType type, required DartType type2})
>
invalidCastStaticMethod = const Template(
  "InvalidCastStaticMethod",
  withArgumentsOld: _withArgumentsOldInvalidCastStaticMethod,
  withArguments: _withArgumentsInvalidCastStaticMethod,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidCastStaticMethod({
  required DartType type,
  required DartType type2,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var type2_0 = labeler.labelType(type2);
  return new Message(
    invalidCastStaticMethod,
    problemMessage:
        """The static method has type '${type_0}' that isn't of expected type '${type2_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Change the type of the method or the context in which it is used.""",
    arguments: {'type': type, 'type2': type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidCastStaticMethod(
  DartType type,
  DartType type2,
) => _withArgumentsInvalidCastStaticMethod(type: type, type2: type2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type, DartType type2),
  Message Function({required DartType type, required DartType type2})
>
invalidCastTopLevelFunction = const Template(
  "InvalidCastTopLevelFunction",
  withArgumentsOld: _withArgumentsOldInvalidCastTopLevelFunction,
  withArguments: _withArgumentsInvalidCastTopLevelFunction,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidCastTopLevelFunction({
  required DartType type,
  required DartType type2,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var type2_0 = labeler.labelType(type2);
  return new Message(
    invalidCastTopLevelFunction,
    problemMessage:
        """The top level function has type '${type_0}' that isn't of expected type '${type2_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Change the type of the function or the context in which it is used.""",
    arguments: {'type': type, 'type2': type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidCastTopLevelFunction(
  DartType type,
  DartType type2,
) => _withArgumentsInvalidCastTopLevelFunction(type: type, type2: type2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String label),
  Message Function({required String label})
>
invalidContinueTarget = const Template(
  "InvalidContinueTarget",
  withArgumentsOld: _withArgumentsOldInvalidContinueTarget,
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
Message _withArgumentsOldInvalidContinueTarget(String label) =>
    _withArgumentsInvalidContinueTarget(label: label);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type, String name, DartType type2, DartType type3),
  Message Function({
    required DartType type,
    required String name,
    required DartType type2,
    required DartType type3,
  })
>
invalidExtensionTypeSuperExtensionType = const Template(
  "InvalidExtensionTypeSuperExtensionType",
  withArgumentsOld: _withArgumentsOldInvalidExtensionTypeSuperExtensionType,
  withArguments: _withArgumentsInvalidExtensionTypeSuperExtensionType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidExtensionTypeSuperExtensionType({
  required DartType type,
  required String name,
  required DartType type2,
  required DartType type3,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var name_0 = conversions.validateAndDemangleName(name);
  var type2_0 = labeler.labelType(type2);
  var type3_0 = labeler.labelType(type3);
  return new Message(
    invalidExtensionTypeSuperExtensionType,
    problemMessage:
        """The representation type '${type_0}' of extension type '${name_0}' must be either a subtype of the representation type '${type2_0}' of the implemented extension type '${type3_0}' or a subtype of '${type3_0}' itself.""" +
        labeler.originMessages,
    correctionMessage:
        """Try changing the representation type to a subtype of '${type2_0}'.""",
    arguments: {'type': type, 'name': name, 'type2': type2, 'type3': type3},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidExtensionTypeSuperExtensionType(
  DartType type,
  String name,
  DartType type2,
  DartType type3,
) => _withArgumentsInvalidExtensionTypeSuperExtensionType(
  type: type,
  name: name,
  type2: type2,
  type3: type3,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type, DartType type2, String name),
  Message Function({
    required DartType type,
    required DartType type2,
    required String name,
  })
>
invalidExtensionTypeSuperInterface = const Template(
  "InvalidExtensionTypeSuperInterface",
  withArgumentsOld: _withArgumentsOldInvalidExtensionTypeSuperInterface,
  withArguments: _withArgumentsInvalidExtensionTypeSuperInterface,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidExtensionTypeSuperInterface({
  required DartType type,
  required DartType type2,
  required String name,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var type2_0 = labeler.labelType(type2);
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    invalidExtensionTypeSuperInterface,
    problemMessage:
        """The implemented interface '${type_0}' must be a supertype of the representation type '${type2_0}' of extension type '${name_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try changing the interface type to a supertype of '${type2_0}' or the representation type to a subtype of '${type_0}'.""",
    arguments: {'type': type, 'type2': type2, 'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidExtensionTypeSuperInterface(
  DartType type,
  DartType type2,
  String name,
) => _withArgumentsInvalidExtensionTypeSuperInterface(
  type: type,
  type2: type2,
  name: name,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(
    DartType getterType,
    String getterName,
    DartType setterType,
    String setterName,
  ),
  Message Function({
    required DartType getterType,
    required String getterName,
    required DartType setterType,
    required String setterName,
  })
>
invalidGetterSetterType = const Template(
  "InvalidGetterSetterType",
  withArgumentsOld: _withArgumentsOldInvalidGetterSetterType,
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
Message _withArgumentsOldInvalidGetterSetterType(
  DartType getterType,
  String getterName,
  DartType setterType,
  String setterName,
) => _withArgumentsInvalidGetterSetterType(
  getterType: getterType,
  getterName: getterName,
  setterType: setterType,
  setterName: setterName,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type, String name, DartType type2, String name2),
  Message Function({
    required DartType type,
    required String name,
    required DartType type2,
    required String name2,
  })
>
invalidGetterSetterTypeBothInheritedField = const Template(
  "InvalidGetterSetterTypeBothInheritedField",
  withArgumentsOld: _withArgumentsOldInvalidGetterSetterTypeBothInheritedField,
  withArguments: _withArgumentsInvalidGetterSetterTypeBothInheritedField,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidGetterSetterTypeBothInheritedField({
  required DartType type,
  required String name,
  required DartType type2,
  required String name2,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var name_0 = conversions.validateAndDemangleName(name);
  var type2_0 = labeler.labelType(type2);
  var name2_0 = conversions.validateAndDemangleName(name2);
  return new Message(
    invalidGetterSetterTypeBothInheritedField,
    problemMessage:
        """The type '${type_0}' of the inherited field '${name_0}' is not a subtype of the type '${type2_0}' of the inherited setter '${name2_0}'.""" +
        labeler.originMessages,
    arguments: {'type': type, 'name': name, 'type2': type2, 'name2': name2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidGetterSetterTypeBothInheritedField(
  DartType type,
  String name,
  DartType type2,
  String name2,
) => _withArgumentsInvalidGetterSetterTypeBothInheritedField(
  type: type,
  name: name,
  type2: type2,
  name2: name2,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type, String name, DartType type2, String name2),
  Message Function({
    required DartType type,
    required String name,
    required DartType type2,
    required String name2,
  })
>
invalidGetterSetterTypeBothInheritedGetter = const Template(
  "InvalidGetterSetterTypeBothInheritedGetter",
  withArgumentsOld: _withArgumentsOldInvalidGetterSetterTypeBothInheritedGetter,
  withArguments: _withArgumentsInvalidGetterSetterTypeBothInheritedGetter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidGetterSetterTypeBothInheritedGetter({
  required DartType type,
  required String name,
  required DartType type2,
  required String name2,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var name_0 = conversions.validateAndDemangleName(name);
  var type2_0 = labeler.labelType(type2);
  var name2_0 = conversions.validateAndDemangleName(name2);
  return new Message(
    invalidGetterSetterTypeBothInheritedGetter,
    problemMessage:
        """The type '${type_0}' of the inherited getter '${name_0}' is not a subtype of the type '${type2_0}' of the inherited setter '${name2_0}'.""" +
        labeler.originMessages,
    arguments: {'type': type, 'name': name, 'type2': type2, 'name2': name2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidGetterSetterTypeBothInheritedGetter(
  DartType type,
  String name,
  DartType type2,
  String name2,
) => _withArgumentsInvalidGetterSetterTypeBothInheritedGetter(
  type: type,
  name: name,
  type2: type2,
  name2: name2,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
invalidGetterSetterTypeFieldContext = const Template(
  "InvalidGetterSetterTypeFieldContext",
  withArgumentsOld: _withArgumentsOldInvalidGetterSetterTypeFieldContext,
  withArguments: _withArgumentsInvalidGetterSetterTypeFieldContext,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidGetterSetterTypeFieldContext({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    invalidGetterSetterTypeFieldContext,
    problemMessage: """This is the declaration of the field '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidGetterSetterTypeFieldContext(String name) =>
    _withArgumentsInvalidGetterSetterTypeFieldContext(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type, String name, DartType type2, String name2),
  Message Function({
    required DartType type,
    required String name,
    required DartType type2,
    required String name2,
  })
>
invalidGetterSetterTypeFieldInherited = const Template(
  "InvalidGetterSetterTypeFieldInherited",
  withArgumentsOld: _withArgumentsOldInvalidGetterSetterTypeFieldInherited,
  withArguments: _withArgumentsInvalidGetterSetterTypeFieldInherited,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidGetterSetterTypeFieldInherited({
  required DartType type,
  required String name,
  required DartType type2,
  required String name2,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var name_0 = conversions.validateAndDemangleName(name);
  var type2_0 = labeler.labelType(type2);
  var name2_0 = conversions.validateAndDemangleName(name2);
  return new Message(
    invalidGetterSetterTypeFieldInherited,
    problemMessage:
        """The type '${type_0}' of the inherited field '${name_0}' is not a subtype of the type '${type2_0}' of the setter '${name2_0}'.""" +
        labeler.originMessages,
    arguments: {'type': type, 'name': name, 'type2': type2, 'name2': name2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidGetterSetterTypeFieldInherited(
  DartType type,
  String name,
  DartType type2,
  String name2,
) => _withArgumentsInvalidGetterSetterTypeFieldInherited(
  type: type,
  name: name,
  type2: type2,
  name2: name2,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
invalidGetterSetterTypeGetterContext = const Template(
  "InvalidGetterSetterTypeGetterContext",
  withArgumentsOld: _withArgumentsOldInvalidGetterSetterTypeGetterContext,
  withArguments: _withArgumentsInvalidGetterSetterTypeGetterContext,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidGetterSetterTypeGetterContext({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    invalidGetterSetterTypeGetterContext,
    problemMessage: """This is the declaration of the getter '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidGetterSetterTypeGetterContext(String name) =>
    _withArgumentsInvalidGetterSetterTypeGetterContext(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type, String name, DartType type2, String name2),
  Message Function({
    required DartType type,
    required String name,
    required DartType type2,
    required String name2,
  })
>
invalidGetterSetterTypeGetterInherited = const Template(
  "InvalidGetterSetterTypeGetterInherited",
  withArgumentsOld: _withArgumentsOldInvalidGetterSetterTypeGetterInherited,
  withArguments: _withArgumentsInvalidGetterSetterTypeGetterInherited,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidGetterSetterTypeGetterInherited({
  required DartType type,
  required String name,
  required DartType type2,
  required String name2,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var name_0 = conversions.validateAndDemangleName(name);
  var type2_0 = labeler.labelType(type2);
  var name2_0 = conversions.validateAndDemangleName(name2);
  return new Message(
    invalidGetterSetterTypeGetterInherited,
    problemMessage:
        """The type '${type_0}' of the inherited getter '${name_0}' is not a subtype of the type '${type2_0}' of the setter '${name2_0}'.""" +
        labeler.originMessages,
    arguments: {'type': type, 'name': name, 'type2': type2, 'name2': name2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidGetterSetterTypeGetterInherited(
  DartType type,
  String name,
  DartType type2,
  String name2,
) => _withArgumentsInvalidGetterSetterTypeGetterInherited(
  type: type,
  name: name,
  type2: type2,
  name2: name2,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String setterName),
  Message Function({required String setterName})
>
invalidGetterSetterTypeSetterContext = const Template(
  "InvalidGetterSetterTypeSetterContext",
  withArgumentsOld: _withArgumentsOldInvalidGetterSetterTypeSetterContext,
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
Message _withArgumentsOldInvalidGetterSetterTypeSetterContext(
  String setterName,
) => _withArgumentsInvalidGetterSetterTypeSetterContext(setterName: setterName);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type, String name, DartType type2, String name2),
  Message Function({
    required DartType type,
    required String name,
    required DartType type2,
    required String name2,
  })
>
invalidGetterSetterTypeSetterInheritedField = const Template(
  "InvalidGetterSetterTypeSetterInheritedField",
  withArgumentsOld:
      _withArgumentsOldInvalidGetterSetterTypeSetterInheritedField,
  withArguments: _withArgumentsInvalidGetterSetterTypeSetterInheritedField,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidGetterSetterTypeSetterInheritedField({
  required DartType type,
  required String name,
  required DartType type2,
  required String name2,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var name_0 = conversions.validateAndDemangleName(name);
  var type2_0 = labeler.labelType(type2);
  var name2_0 = conversions.validateAndDemangleName(name2);
  return new Message(
    invalidGetterSetterTypeSetterInheritedField,
    problemMessage:
        """The type '${type_0}' of the field '${name_0}' is not a subtype of the type '${type2_0}' of the inherited setter '${name2_0}'.""" +
        labeler.originMessages,
    arguments: {'type': type, 'name': name, 'type2': type2, 'name2': name2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidGetterSetterTypeSetterInheritedField(
  DartType type,
  String name,
  DartType type2,
  String name2,
) => _withArgumentsInvalidGetterSetterTypeSetterInheritedField(
  type: type,
  name: name,
  type2: type2,
  name2: name2,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type, String name, DartType type2, String name2),
  Message Function({
    required DartType type,
    required String name,
    required DartType type2,
    required String name2,
  })
>
invalidGetterSetterTypeSetterInheritedGetter = const Template(
  "InvalidGetterSetterTypeSetterInheritedGetter",
  withArgumentsOld:
      _withArgumentsOldInvalidGetterSetterTypeSetterInheritedGetter,
  withArguments: _withArgumentsInvalidGetterSetterTypeSetterInheritedGetter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidGetterSetterTypeSetterInheritedGetter({
  required DartType type,
  required String name,
  required DartType type2,
  required String name2,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var name_0 = conversions.validateAndDemangleName(name);
  var type2_0 = labeler.labelType(type2);
  var name2_0 = conversions.validateAndDemangleName(name2);
  return new Message(
    invalidGetterSetterTypeSetterInheritedGetter,
    problemMessage:
        """The type '${type_0}' of the getter '${name_0}' is not a subtype of the type '${type2_0}' of the inherited setter '${name2_0}'.""" +
        labeler.originMessages,
    arguments: {'type': type, 'name': name, 'type2': type2, 'name2': name2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidGetterSetterTypeSetterInheritedGetter(
  DartType type,
  String name,
  DartType type2,
  String name2,
) => _withArgumentsInvalidGetterSetterTypeSetterInheritedGetter(
  type: type,
  name: name,
  type2: type2,
  name2: name2,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Uri uri, String string),
  Message Function({required Uri uri, required String string})
>
invalidPackageUri = const Template(
  "InvalidPackageUri",
  withArgumentsOld: _withArgumentsOldInvalidPackageUri,
  withArguments: _withArgumentsInvalidPackageUri,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidPackageUri({
  required Uri uri,
  required String string,
}) {
  var uri_0 = conversions.relativizeUri(uri);
  var string_0 = conversions.validateString(string);
  return new Message(
    invalidPackageUri,
    problemMessage: """Invalid package URI '${uri_0}':
  ${string_0}.""",
    arguments: {'uri': uri, 'string': string},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidPackageUri(Uri uri, String string) =>
    _withArgumentsInvalidPackageUri(uri: uri, string: string);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type, DartType type2),
  Message Function({required DartType type, required DartType type2})
>
invalidReturn = const Template(
  "InvalidReturn",
  withArgumentsOld: _withArgumentsOldInvalidReturn,
  withArguments: _withArgumentsInvalidReturn,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidReturn({
  required DartType type,
  required DartType type2,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var type2_0 = labeler.labelType(type2);
  return new Message(
    invalidReturn,
    problemMessage:
        """A value of type '${type_0}' can't be returned from a function with return type '${type2_0}'.""" +
        labeler.originMessages,
    arguments: {'type': type, 'type2': type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidReturn(DartType type, DartType type2) =>
    _withArgumentsInvalidReturn(type: type, type2: type2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type, DartType type2),
  Message Function({required DartType type, required DartType type2})
>
invalidReturnAsync = const Template(
  "InvalidReturnAsync",
  withArgumentsOld: _withArgumentsOldInvalidReturnAsync,
  withArguments: _withArgumentsInvalidReturnAsync,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidReturnAsync({
  required DartType type,
  required DartType type2,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var type2_0 = labeler.labelType(type2);
  return new Message(
    invalidReturnAsync,
    problemMessage:
        """A value of type '${type_0}' can't be returned from an async function with return type '${type2_0}'.""" +
        labeler.originMessages,
    arguments: {'type': type, 'type2': type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidReturnAsync(DartType type, DartType type2) =>
    _withArgumentsInvalidReturnAsync(type: type, type2: type2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, String string2, String name2),
  Message Function({
    required String name,
    required String string2,
    required String name2,
  })
>
invalidTypeParameterInSupertype = const Template(
  "InvalidTypeParameterInSupertype",
  withArgumentsOld: _withArgumentsOldInvalidTypeParameterInSupertype,
  withArguments: _withArgumentsInvalidTypeParameterInSupertype,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidTypeParameterInSupertype({
  required String name,
  required String string2,
  required String name2,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var string2_0 = conversions.validateString(string2);
  var name2_0 = conversions.validateAndDemangleName(name2);
  return new Message(
    invalidTypeParameterInSupertype,
    problemMessage:
        """Can't use implicitly 'out' variable '${name_0}' in an '${string2_0}' position in supertype '${name2_0}'.""",
    arguments: {'name': name, 'string2': string2, 'name2': name2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidTypeParameterInSupertype(
  String name,
  String string2,
  String name2,
) => _withArgumentsInvalidTypeParameterInSupertype(
  name: name,
  string2: string2,
  name2: name2,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string, String name, String string2, String name2),
  Message Function({
    required String string,
    required String name,
    required String string2,
    required String name2,
  })
>
invalidTypeParameterInSupertypeWithVariance = const Template(
  "InvalidTypeParameterInSupertypeWithVariance",
  withArgumentsOld:
      _withArgumentsOldInvalidTypeParameterInSupertypeWithVariance,
  withArguments: _withArgumentsInvalidTypeParameterInSupertypeWithVariance,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidTypeParameterInSupertypeWithVariance({
  required String string,
  required String name,
  required String string2,
  required String name2,
}) {
  var string_0 = conversions.validateString(string);
  var name_0 = conversions.validateAndDemangleName(name);
  var string2_0 = conversions.validateString(string2);
  var name2_0 = conversions.validateAndDemangleName(name2);
  return new Message(
    invalidTypeParameterInSupertypeWithVariance,
    problemMessage:
        """Can't use '${string_0}' type variable '${name_0}' in an '${string2_0}' position in supertype '${name2_0}'.""",
    arguments: {
      'string': string,
      'name': name,
      'string2': string2,
      'name2': name2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidTypeParameterInSupertypeWithVariance(
  String string,
  String name,
  String string2,
  String name2,
) => _withArgumentsInvalidTypeParameterInSupertypeWithVariance(
  string: string,
  name: name,
  string2: string2,
  name2: name2,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string, String name, String string2),
  Message Function({
    required String string,
    required String name,
    required String string2,
  })
>
invalidTypeParameterVariancePosition = const Template(
  "InvalidTypeParameterVariancePosition",
  withArgumentsOld: _withArgumentsOldInvalidTypeParameterVariancePosition,
  withArguments: _withArgumentsInvalidTypeParameterVariancePosition,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidTypeParameterVariancePosition({
  required String string,
  required String name,
  required String string2,
}) {
  var string_0 = conversions.validateString(string);
  var name_0 = conversions.validateAndDemangleName(name);
  var string2_0 = conversions.validateString(string2);
  return new Message(
    invalidTypeParameterVariancePosition,
    problemMessage:
        """Can't use '${string_0}' type variable '${name_0}' in an '${string2_0}' position.""",
    arguments: {'string': string, 'name': name, 'string2': string2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidTypeParameterVariancePosition(
  String string,
  String name,
  String string2,
) => _withArgumentsInvalidTypeParameterVariancePosition(
  string: string,
  name: name,
  string2: string2,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string, String name, String string2),
  Message Function({
    required String string,
    required String name,
    required String string2,
  })
>
invalidTypeParameterVariancePositionInReturnType = const Template(
  "InvalidTypeParameterVariancePositionInReturnType",
  withArgumentsOld:
      _withArgumentsOldInvalidTypeParameterVariancePositionInReturnType,
  withArguments: _withArgumentsInvalidTypeParameterVariancePositionInReturnType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidTypeParameterVariancePositionInReturnType({
  required String string,
  required String name,
  required String string2,
}) {
  var string_0 = conversions.validateString(string);
  var name_0 = conversions.validateAndDemangleName(name);
  var string2_0 = conversions.validateString(string2);
  return new Message(
    invalidTypeParameterVariancePositionInReturnType,
    problemMessage:
        """Can't use '${string_0}' type variable '${name_0}' in an '${string2_0}' position in the return type.""",
    arguments: {'string': string, 'name': name, 'string2': string2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidTypeParameterVariancePositionInReturnType(
  String string,
  String name,
  String string2,
) => _withArgumentsInvalidTypeParameterVariancePositionInReturnType(
  string: string,
  name: name,
  string2: string2,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode invalidUseOfNullAwareAccess = const MessageCode(
  "InvalidUseOfNullAwareAccess",
  problemMessage: """Cannot use '?.' here.""",
  correctionMessage: """Try using '.'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
invokeNonFunction = const Template(
  "InvokeNonFunction",
  withArgumentsOld: _withArgumentsOldInvokeNonFunction,
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
Message _withArgumentsOldInvokeNonFunction(String name) =>
    _withArgumentsInvokeNonFunction(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
jointPatternVariableNotInAll = const Template(
  "JointPatternVariableNotInAll",
  withArgumentsOld: _withArgumentsOldJointPatternVariableNotInAll,
  withArguments: _withArgumentsJointPatternVariableNotInAll,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJointPatternVariableNotInAll({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    jointPatternVariableNotInAll,
    problemMessage:
        """The variable '${name_0}' is available in some, but not all cases that share this body.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldJointPatternVariableNotInAll(String name) =>
    _withArgumentsJointPatternVariableNotInAll(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
jointPatternVariableWithLabelDefault = const Template(
  "JointPatternVariableWithLabelDefault",
  withArgumentsOld: _withArgumentsOldJointPatternVariableWithLabelDefault,
  withArguments: _withArgumentsJointPatternVariableWithLabelDefault,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJointPatternVariableWithLabelDefault({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    jointPatternVariableWithLabelDefault,
    problemMessage:
        """The variable '${name_0}' is not available because there is a label or 'default' case.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldJointPatternVariableWithLabelDefault(String name) =>
    _withArgumentsJointPatternVariableWithLabelDefault(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
jointPatternVariablesMismatch = const Template(
  "JointPatternVariablesMismatch",
  withArgumentsOld: _withArgumentsOldJointPatternVariablesMismatch,
  withArguments: _withArgumentsJointPatternVariablesMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJointPatternVariablesMismatch({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    jointPatternVariablesMismatch,
    problemMessage:
        """Variable pattern '${name_0}' doesn't have the same type or finality in all cases.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldJointPatternVariablesMismatch(String name) =>
    _withArgumentsJointPatternVariablesMismatch(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, String name2),
  Message Function({required String name, required String name2})
>
jsInteropDartClassExtendsJSClass = const Template(
  "JsInteropDartClassExtendsJSClass",
  withArgumentsOld: _withArgumentsOldJsInteropDartClassExtendsJSClass,
  withArguments: _withArgumentsJsInteropDartClassExtendsJSClass,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropDartClassExtendsJSClass({
  required String name,
  required String name2,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var name2_0 = conversions.validateAndDemangleName(name2);
  return new Message(
    jsInteropDartClassExtendsJSClass,
    problemMessage:
        """Dart class '${name_0}' cannot extend JS interop class '${name2_0}'.""",
    correctionMessage:
        """Try adding the JS interop annotation or removing it from the parent class.""",
    arguments: {'name': name, 'name2': name2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldJsInteropDartClassExtendsJSClass(
  String name,
  String name2,
) => _withArgumentsJsInteropDartClassExtendsJSClass(name: name, name2: name2);

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
const Template<
  Message Function(String name),
  Message Function({required String name})
>
jsInteropExportClassNotMarkedExportable = const Template(
  "JsInteropExportClassNotMarkedExportable",
  withArgumentsOld: _withArgumentsOldJsInteropExportClassNotMarkedExportable,
  withArguments: _withArgumentsJsInteropExportClassNotMarkedExportable,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropExportClassNotMarkedExportable({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    jsInteropExportClassNotMarkedExportable,
    problemMessage:
        """Class '${name_0}' does not have a `@JSExport` on it or any of its members.""",
    correctionMessage: """Use the `@JSExport` annotation on this class.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldJsInteropExportClassNotMarkedExportable(String name) =>
    _withArgumentsJsInteropExportClassNotMarkedExportable(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
jsInteropExportDartInterfaceHasNonEmptyJSExportValue = const Template(
  "JsInteropExportDartInterfaceHasNonEmptyJSExportValue",
  withArgumentsOld:
      _withArgumentsOldJsInteropExportDartInterfaceHasNonEmptyJSExportValue,
  withArguments:
      _withArgumentsJsInteropExportDartInterfaceHasNonEmptyJSExportValue,
  severity: CfeSeverity.warning,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropExportDartInterfaceHasNonEmptyJSExportValue({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    jsInteropExportDartInterfaceHasNonEmptyJSExportValue,
    problemMessage:
        """The value in the `@JSExport` annotation on the class or mixin '${name_0}' will be ignored.""",
    correctionMessage: """Remove the value in the annotation.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldJsInteropExportDartInterfaceHasNonEmptyJSExportValue(
  String name,
) => _withArgumentsJsInteropExportDartInterfaceHasNonEmptyJSExportValue(
  name: name,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
jsInteropExportDisallowedMember = const Template(
  "JsInteropExportDisallowedMember",
  withArgumentsOld: _withArgumentsOldJsInteropExportDisallowedMember,
  withArguments: _withArgumentsJsInteropExportDisallowedMember,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropExportDisallowedMember({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    jsInteropExportDisallowedMember,
    problemMessage:
        """Member '${name_0}' is not a concrete instance member or declares type parameters, and therefore can't be exported.""",
    correctionMessage:
        """Remove the `@JSExport` annotation from the member, and use an instance member to call this member instead.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldJsInteropExportDisallowedMember(String name) =>
    _withArgumentsJsInteropExportDisallowedMember(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type),
  Message Function({required DartType type})
>
jsInteropExportInvalidInteropTypeArgument = const Template(
  "JsInteropExportInvalidInteropTypeArgument",
  withArgumentsOld: _withArgumentsOldJsInteropExportInvalidInteropTypeArgument,
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
Message _withArgumentsOldJsInteropExportInvalidInteropTypeArgument(
  DartType type,
) => _withArgumentsJsInteropExportInvalidInteropTypeArgument(type: type);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type),
  Message Function({required DartType type})
>
jsInteropExportInvalidTypeArgument = const Template(
  "JsInteropExportInvalidTypeArgument",
  withArgumentsOld: _withArgumentsOldJsInteropExportInvalidTypeArgument,
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
Message _withArgumentsOldJsInteropExportInvalidTypeArgument(DartType type) =>
    _withArgumentsJsInteropExportInvalidTypeArgument(type: type);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, String string),
  Message Function({required String name, required String string})
>
jsInteropExportMemberCollision = const Template(
  "JsInteropExportMemberCollision",
  withArgumentsOld: _withArgumentsOldJsInteropExportMemberCollision,
  withArguments: _withArgumentsJsInteropExportMemberCollision,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropExportMemberCollision({
  required String name,
  required String string,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var string_0 = conversions.validateString(string);
  return new Message(
    jsInteropExportMemberCollision,
    problemMessage:
        """The following class members collide with the same export '${name_0}': ${string_0}.""",
    correctionMessage:
        """Either remove the conflicting members or use a different export name.""",
    arguments: {'name': name, 'string': string},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldJsInteropExportMemberCollision(
  String name,
  String string,
) => _withArgumentsJsInteropExportMemberCollision(name: name, string: string);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
jsInteropExportNoExportableMembers = const Template(
  "JsInteropExportNoExportableMembers",
  withArgumentsOld: _withArgumentsOldJsInteropExportNoExportableMembers,
  withArguments: _withArgumentsJsInteropExportNoExportableMembers,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropExportNoExportableMembers({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    jsInteropExportNoExportableMembers,
    problemMessage:
        """Class '${name_0}' has no exportable members in the class or the inheritance chain.""",
    correctionMessage:
        """Using `@JSExport`, annotate at least one instance member with a body or annotate a class that has such a member in the inheritance chain.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldJsInteropExportNoExportableMembers(String name) =>
    _withArgumentsJsInteropExportNoExportableMembers(name: name);

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
  Message Function(String name, DartType type),
  Message Function({required String name, required DartType type})
>
jsInteropExtensionTypeNotInterop = const Template(
  "JsInteropExtensionTypeNotInterop",
  withArgumentsOld: _withArgumentsOldJsInteropExtensionTypeNotInterop,
  withArguments: _withArgumentsJsInteropExtensionTypeNotInterop,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropExtensionTypeNotInterop({
  required String name,
  required DartType type,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    jsInteropExtensionTypeNotInterop,
    problemMessage:
        """Extension type '${name_0}' is marked with a '@JS' annotation, but its representation type is not a valid JS interop type: '${type_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try declaring a valid JS interop representation type, which may include 'dart:js_interop' types, '@staticInterop' types, 'dart:html' types, or other interop extension types.""",
    arguments: {'name': name, 'type': type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldJsInteropExtensionTypeNotInterop(
  String name,
  DartType type,
) => _withArgumentsJsInteropExtensionTypeNotInterop(name: name, type: type);

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
const Template<
  Message Function(String conversion),
  Message Function({required String conversion})
>
jsInteropFunctionToJSNamedParameters = const Template(
  "JsInteropFunctionToJSNamedParameters",
  withArgumentsOld: _withArgumentsOldJsInteropFunctionToJSNamedParameters,
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
Message _withArgumentsOldJsInteropFunctionToJSNamedParameters(
  String conversion,
) => _withArgumentsJsInteropFunctionToJSNamedParameters(conversion: conversion);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String conversion, DartType type),
  Message Function({required String conversion, required DartType type})
>
jsInteropFunctionToJSRequiresStaticType = const Template(
  "JsInteropFunctionToJSRequiresStaticType",
  withArgumentsOld: _withArgumentsOldJsInteropFunctionToJSRequiresStaticType,
  withArguments: _withArgumentsJsInteropFunctionToJSRequiresStaticType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropFunctionToJSRequiresStaticType({
  required String conversion,
  required DartType type,
}) {
  var conversion_0 = conversions.validateString(conversion);
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    jsInteropFunctionToJSRequiresStaticType,
    problemMessage:
        """Functions converted via '${conversion_0}' require a statically known function type, but Type '${type_0}' is not a precise function type, e.g., `void Function()`.""" +
        labeler.originMessages,
    correctionMessage:
        """Insert an explicit cast to the expected function type.""",
    arguments: {'conversion': conversion, 'type': type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldJsInteropFunctionToJSRequiresStaticType(
  String conversion,
  DartType type,
) => _withArgumentsJsInteropFunctionToJSRequiresStaticType(
  conversion: conversion,
  type: type,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String conversion),
  Message Function({required String conversion})
>
jsInteropFunctionToJSTypeParameters = const Template(
  "JsInteropFunctionToJSTypeParameters",
  withArgumentsOld: _withArgumentsOldJsInteropFunctionToJSTypeParameters,
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
Message _withArgumentsOldJsInteropFunctionToJSTypeParameters(
  String conversion,
) => _withArgumentsJsInteropFunctionToJSTypeParameters(conversion: conversion);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String conversion, String string2),
  Message Function({required String conversion, required String string2})
>
jsInteropFunctionToJSTypeViolation = const Template(
  "JsInteropFunctionToJSTypeViolation",
  withArgumentsOld: _withArgumentsOldJsInteropFunctionToJSTypeViolation,
  withArguments: _withArgumentsJsInteropFunctionToJSTypeViolation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropFunctionToJSTypeViolation({
  required String conversion,
  required String string2,
}) {
  var conversion_0 = conversions.validateString(conversion);
  var string2_0 = conversions.validateString(string2);
  return new Message(
    jsInteropFunctionToJSTypeViolation,
    problemMessage:
        """Function converted via '${conversion_0}' contains invalid types in its function signature: '${string2_0}'.""",
    correctionMessage:
        """Use one of these valid types instead: JS types from 'dart:js_interop', ExternalDartReference, void, bool, num, double, int, String, extension types that erase to one of these types, '@staticInterop' types, 'dart:html' types when compiling to JS, or a type parameter that is a subtype of a valid non-primitive type.""",
    arguments: {'conversion': conversion, 'string2': string2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldJsInteropFunctionToJSTypeViolation(
  String conversion,
  String string2,
) => _withArgumentsJsInteropFunctionToJSTypeViolation(
  conversion: conversion,
  string2: string2,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode jsInteropInvalidStaticClassMemberName = const MessageCode(
  "JsInteropInvalidStaticClassMemberName",
  problemMessage:
      """JS interop static class members cannot have '.' in their JS name.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type),
  Message Function({required DartType type})
>
jsInteropIsAInvalidTypeVariable = const Template(
  "JsInteropIsAInvalidTypeVariable",
  withArgumentsOld: _withArgumentsOldJsInteropIsAInvalidTypeVariable,
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
Message _withArgumentsOldJsInteropIsAInvalidTypeVariable(DartType type) =>
    _withArgumentsJsInteropIsAInvalidTypeVariable(type: type);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type),
  Message Function({required DartType type})
>
jsInteropIsAObjectLiteralType = const Template(
  "JsInteropIsAObjectLiteralType",
  withArgumentsOld: _withArgumentsOldJsInteropIsAObjectLiteralType,
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
Message _withArgumentsOldJsInteropIsAObjectLiteralType(DartType type) =>
    _withArgumentsJsInteropIsAObjectLiteralType(type: type);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type, String string),
  Message Function({required DartType type, required String string})
>
jsInteropIsAPrimitiveExtensionType = const Template(
  "JsInteropIsAPrimitiveExtensionType",
  withArgumentsOld: _withArgumentsOldJsInteropIsAPrimitiveExtensionType,
  withArguments: _withArgumentsJsInteropIsAPrimitiveExtensionType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropIsAPrimitiveExtensionType({
  required DartType type,
  required String string,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var string_0 = conversions.validateString(string);
  return new Message(
    jsInteropIsAPrimitiveExtensionType,
    problemMessage:
        """Type argument '${type_0}' wraps primitive JS type '${string_0}', which is specially handled using 'typeof'.""" +
        labeler.originMessages,
    correctionMessage:
        """Use the primitive JS type '${string_0}' as the type argument instead.""",
    arguments: {'type': type, 'string': string},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldJsInteropIsAPrimitiveExtensionType(
  DartType type,
  String string,
) => _withArgumentsJsInteropIsAPrimitiveExtensionType(
  type: type,
  string: string,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode jsInteropIsATearoff = const MessageCode(
  "JsInteropIsATearoff",
  problemMessage: """'isA' can't be torn off.""",
  correctionMessage:
      """Use a method that calls 'isA' and tear off that method instead.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, String name2),
  Message Function({required String name, required String name2})
>
jsInteropJSClassExtendsDartClass = const Template(
  "JsInteropJSClassExtendsDartClass",
  withArgumentsOld: _withArgumentsOldJsInteropJSClassExtendsDartClass,
  withArguments: _withArgumentsJsInteropJSClassExtendsDartClass,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropJSClassExtendsDartClass({
  required String name,
  required String name2,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var name2_0 = conversions.validateAndDemangleName(name2);
  return new Message(
    jsInteropJSClassExtendsDartClass,
    problemMessage:
        """JS interop class '${name_0}' cannot extend Dart class '${name2_0}'.""",
    correctionMessage:
        """Try removing the JS interop annotation or adding it to the parent class.""",
    arguments: {'name': name, 'name2': name2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldJsInteropJSClassExtendsDartClass(
  String name,
  String name2,
) => _withArgumentsJsInteropJSClassExtendsDartClass(name: name, name2: name2);

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
  Message Function(String name, String name2, String string3),
  Message Function({
    required String name,
    required String name2,
    required String string3,
  })
>
jsInteropNativeClassInAnnotation = const Template(
  "JsInteropNativeClassInAnnotation",
  withArgumentsOld: _withArgumentsOldJsInteropNativeClassInAnnotation,
  withArguments: _withArgumentsJsInteropNativeClassInAnnotation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropNativeClassInAnnotation({
  required String name,
  required String name2,
  required String string3,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var name2_0 = conversions.validateAndDemangleName(name2);
  var string3_0 = conversions.validateString(string3);
  return new Message(
    jsInteropNativeClassInAnnotation,
    problemMessage:
        """Non-static JS interop class '${name_0}' conflicts with natively supported class '${name2_0}' in '${string3_0}'.""",
    correctionMessage:
        """Try replacing it with a static JS interop class using `@staticInterop` with extension methods, or use js_util to interact with the native object of type '${name2_0}'.""",
    arguments: {'name': name, 'name2': name2, 'string3': string3},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldJsInteropNativeClassInAnnotation(
  String name,
  String name2,
  String string3,
) => _withArgumentsJsInteropNativeClassInAnnotation(
  name: name,
  name2: name2,
  string3: string3,
);

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
  Message Function(String name, String name2),
  Message Function({required String name, required String name2})
>
jsInteropNonStaticWithStaticInteropSupertype = const Template(
  "JsInteropNonStaticWithStaticInteropSupertype",
  withArgumentsOld:
      _withArgumentsOldJsInteropNonStaticWithStaticInteropSupertype,
  withArguments: _withArgumentsJsInteropNonStaticWithStaticInteropSupertype,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropNonStaticWithStaticInteropSupertype({
  required String name,
  required String name2,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var name2_0 = conversions.validateAndDemangleName(name2);
  return new Message(
    jsInteropNonStaticWithStaticInteropSupertype,
    problemMessage:
        """Class '${name_0}' does not have an `@staticInterop` annotation, but has supertype '${name2_0}', which does.""",
    correctionMessage:
        """Try marking '${name_0}' as a `@staticInterop` class, or don't inherit '${name2_0}'.""",
    arguments: {'name': name, 'name2': name2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldJsInteropNonStaticWithStaticInteropSupertype(
  String name,
  String name2,
) => _withArgumentsJsInteropNonStaticWithStaticInteropSupertype(
  name: name,
  name2: name2,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string),
  Message Function({required String string})
>
jsInteropObjectLiteralConstructorPositionalParameters = const Template(
  "JsInteropObjectLiteralConstructorPositionalParameters",
  withArgumentsOld:
      _withArgumentsOldJsInteropObjectLiteralConstructorPositionalParameters,
  withArguments:
      _withArgumentsJsInteropObjectLiteralConstructorPositionalParameters,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropObjectLiteralConstructorPositionalParameters({
  required String string,
}) {
  var string_0 = conversions.validateString(string);
  return new Message(
    jsInteropObjectLiteralConstructorPositionalParameters,
    problemMessage:
        """${string_0} should not contain any positional parameters.""",
    correctionMessage: """Try replacing them with named parameters instead.""",
    arguments: {'string': string},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldJsInteropObjectLiteralConstructorPositionalParameters(
  String string,
) => _withArgumentsJsInteropObjectLiteralConstructorPositionalParameters(
  string: string,
);

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
const Template<
  Message Function(DartType type),
  Message Function({required DartType type})
>
jsInteropStaticInteropExternalAccessorTypeViolation = const Template(
  "JsInteropStaticInteropExternalAccessorTypeViolation",
  withArgumentsOld:
      _withArgumentsOldJsInteropStaticInteropExternalAccessorTypeViolation,
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
Message _withArgumentsOldJsInteropStaticInteropExternalAccessorTypeViolation(
  DartType type,
) => _withArgumentsJsInteropStaticInteropExternalAccessorTypeViolation(
  type: type,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string2),
  Message Function({required String string2})
>
jsInteropStaticInteropExternalFunctionTypeViolation = const Template(
  "JsInteropStaticInteropExternalFunctionTypeViolation",
  withArgumentsOld:
      _withArgumentsOldJsInteropStaticInteropExternalFunctionTypeViolation,
  withArguments:
      _withArgumentsJsInteropStaticInteropExternalFunctionTypeViolation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropStaticInteropExternalFunctionTypeViolation({
  required String string2,
}) {
  var string2_0 = conversions.validateString(string2);
  return new Message(
    jsInteropStaticInteropExternalFunctionTypeViolation,
    problemMessage:
        """External JS interop member contains invalid types in its function signature: '${string2_0}'.""",
    correctionMessage:
        """Use one of these valid types instead: JS types from 'dart:js_interop', ExternalDartReference, void, bool, num, double, int, String, extension types that erase to one of these types, '@staticInterop' types, 'dart:html' types when compiling to JS, or a type parameter that is a subtype of a valid non-primitive type.""",
    arguments: {'string2': string2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldJsInteropStaticInteropExternalFunctionTypeViolation(
  String string2,
) => _withArgumentsJsInteropStaticInteropExternalFunctionTypeViolation(
  string2: string2,
);

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
  Message Function(
    String name,
    String string,
    String string2,
    String name2,
    String string3,
  ),
  Message Function({
    required String name,
    required String string,
    required String string2,
    required String name2,
    required String string3,
  })
>
jsInteropStaticInteropMockMissingGetterOrSetter = const Template(
  "JsInteropStaticInteropMockMissingGetterOrSetter",
  withArgumentsOld:
      _withArgumentsOldJsInteropStaticInteropMockMissingGetterOrSetter,
  withArguments: _withArgumentsJsInteropStaticInteropMockMissingGetterOrSetter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropStaticInteropMockMissingGetterOrSetter({
  required String name,
  required String string,
  required String string2,
  required String name2,
  required String string3,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var string_0 = conversions.validateString(string);
  var string2_0 = conversions.validateString(string2);
  var name2_0 = conversions.validateAndDemangleName(name2);
  var string3_0 = conversions.validateString(string3);
  return new Message(
    jsInteropStaticInteropMockMissingGetterOrSetter,
    problemMessage:
        """Dart class '${name_0}' has a ${string_0}, but does not have a ${string2_0} to implement any of the following extension member(s) with export name '${name2_0}': ${string3_0}.""",
    correctionMessage:
        """Declare an exportable ${string2_0} that implements one of these extension members.""",
    arguments: {
      'name': name,
      'string': string,
      'string2': string2,
      'name2': name2,
      'string3': string3,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldJsInteropStaticInteropMockMissingGetterOrSetter(
  String name,
  String string,
  String string2,
  String name2,
  String string3,
) => _withArgumentsJsInteropStaticInteropMockMissingGetterOrSetter(
  name: name,
  string: string,
  string2: string2,
  name2: name2,
  string3: string3,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, String name2, String string),
  Message Function({
    required String name,
    required String name2,
    required String string,
  })
>
jsInteropStaticInteropMockMissingImplements = const Template(
  "JsInteropStaticInteropMockMissingImplements",
  withArgumentsOld:
      _withArgumentsOldJsInteropStaticInteropMockMissingImplements,
  withArguments: _withArgumentsJsInteropStaticInteropMockMissingImplements,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropStaticInteropMockMissingImplements({
  required String name,
  required String name2,
  required String string,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var name2_0 = conversions.validateAndDemangleName(name2);
  var string_0 = conversions.validateString(string);
  return new Message(
    jsInteropStaticInteropMockMissingImplements,
    problemMessage:
        """Dart class '${name_0}' does not have any members that implement any of the following extension member(s) with export name '${name2_0}': ${string_0}.""",
    correctionMessage:
        """Declare an exportable member that implements one of these extension members.""",
    arguments: {'name': name, 'name2': name2, 'string': string},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldJsInteropStaticInteropMockMissingImplements(
  String name,
  String name2,
  String string,
) => _withArgumentsJsInteropStaticInteropMockMissingImplements(
  name: name,
  name2: name2,
  string: string,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type),
  Message Function({required DartType type})
>
jsInteropStaticInteropMockNotStaticInteropType = const Template(
  "JsInteropStaticInteropMockNotStaticInteropType",
  withArgumentsOld:
      _withArgumentsOldJsInteropStaticInteropMockNotStaticInteropType,
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
Message _withArgumentsOldJsInteropStaticInteropMockNotStaticInteropType(
  DartType type,
) => _withArgumentsJsInteropStaticInteropMockNotStaticInteropType(type: type);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type),
  Message Function({required DartType type})
>
jsInteropStaticInteropMockTypeParametersNotAllowed = const Template(
  "JsInteropStaticInteropMockTypeParametersNotAllowed",
  withArgumentsOld:
      _withArgumentsOldJsInteropStaticInteropMockTypeParametersNotAllowed,
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
Message _withArgumentsOldJsInteropStaticInteropMockTypeParametersNotAllowed(
  DartType type,
) => _withArgumentsJsInteropStaticInteropMockTypeParametersNotAllowed(
  type: type,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
jsInteropStaticInteropNoJSAnnotation = const Template(
  "JsInteropStaticInteropNoJSAnnotation",
  withArgumentsOld: _withArgumentsOldJsInteropStaticInteropNoJSAnnotation,
  withArguments: _withArgumentsJsInteropStaticInteropNoJSAnnotation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropStaticInteropNoJSAnnotation({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    jsInteropStaticInteropNoJSAnnotation,
    problemMessage:
        """`@staticInterop` classes should also have the `@JS` annotation.""",
    correctionMessage: """Add `@JS` to class '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldJsInteropStaticInteropNoJSAnnotation(String name) =>
    _withArgumentsJsInteropStaticInteropNoJSAnnotation(name: name);

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
  Message Function(String string, String name),
  Message Function({required String string, required String name})
>
jsInteropStaticInteropTearOffsDisallowed = const Template(
  "JsInteropStaticInteropTearOffsDisallowed",
  withArgumentsOld: _withArgumentsOldJsInteropStaticInteropTearOffsDisallowed,
  withArguments: _withArgumentsJsInteropStaticInteropTearOffsDisallowed,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropStaticInteropTearOffsDisallowed({
  required String string,
  required String name,
}) {
  var string_0 = conversions.validateString(string);
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    jsInteropStaticInteropTearOffsDisallowed,
    problemMessage:
        """Tear-offs of external ${string_0} '${name_0}' are disallowed.""",
    correctionMessage: """Declare a closure that calls this member instead.""",
    arguments: {'string': string, 'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldJsInteropStaticInteropTearOffsDisallowed(
  String string,
  String name,
) => _withArgumentsJsInteropStaticInteropTearOffsDisallowed(
  string: string,
  name: name,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
jsInteropStaticInteropTrustTypesUsageNotAllowed = const Template(
  "JsInteropStaticInteropTrustTypesUsageNotAllowed",
  withArgumentsOld:
      _withArgumentsOldJsInteropStaticInteropTrustTypesUsageNotAllowed,
  withArguments: _withArgumentsJsInteropStaticInteropTrustTypesUsageNotAllowed,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropStaticInteropTrustTypesUsageNotAllowed({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    jsInteropStaticInteropTrustTypesUsageNotAllowed,
    problemMessage:
        """JS interop class '${name_0}' has an `@trustTypes` annotation, but `@trustTypes` is only supported within the sdk.""",
    correctionMessage: """Try removing the `@trustTypes` annotation.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldJsInteropStaticInteropTrustTypesUsageNotAllowed(
  String name,
) => _withArgumentsJsInteropStaticInteropTrustTypesUsageNotAllowed(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
jsInteropStaticInteropTrustTypesUsedWithoutStaticInterop = const Template(
  "JsInteropStaticInteropTrustTypesUsedWithoutStaticInterop",
  withArgumentsOld:
      _withArgumentsOldJsInteropStaticInteropTrustTypesUsedWithoutStaticInterop,
  withArguments:
      _withArgumentsJsInteropStaticInteropTrustTypesUsedWithoutStaticInterop,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropStaticInteropTrustTypesUsedWithoutStaticInterop({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    jsInteropStaticInteropTrustTypesUsedWithoutStaticInterop,
    problemMessage:
        """JS interop class '${name_0}' has an `@trustTypes` annotation, but no `@staticInterop` annotation.""",
    correctionMessage: """Try marking the class using `@staticInterop`.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message
_withArgumentsOldJsInteropStaticInteropTrustTypesUsedWithoutStaticInterop(
  String name,
) => _withArgumentsJsInteropStaticInteropTrustTypesUsedWithoutStaticInterop(
  name: name,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
jsInteropStaticInteropWithInstanceMembers = const Template(
  "JsInteropStaticInteropWithInstanceMembers",
  withArgumentsOld: _withArgumentsOldJsInteropStaticInteropWithInstanceMembers,
  withArguments: _withArgumentsJsInteropStaticInteropWithInstanceMembers,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropStaticInteropWithInstanceMembers({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    jsInteropStaticInteropWithInstanceMembers,
    problemMessage:
        """JS interop class '${name_0}' with `@staticInterop` annotation cannot declare instance members.""",
    correctionMessage:
        """Try moving the instance member to a static extension.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldJsInteropStaticInteropWithInstanceMembers(
  String name,
) => _withArgumentsJsInteropStaticInteropWithInstanceMembers(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, String name2),
  Message Function({required String name, required String name2})
>
jsInteropStaticInteropWithNonStaticSupertype = const Template(
  "JsInteropStaticInteropWithNonStaticSupertype",
  withArgumentsOld:
      _withArgumentsOldJsInteropStaticInteropWithNonStaticSupertype,
  withArguments: _withArgumentsJsInteropStaticInteropWithNonStaticSupertype,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropStaticInteropWithNonStaticSupertype({
  required String name,
  required String name2,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var name2_0 = conversions.validateAndDemangleName(name2);
  return new Message(
    jsInteropStaticInteropWithNonStaticSupertype,
    problemMessage:
        """JS interop class '${name_0}' has an `@staticInterop` annotation, but has supertype '${name2_0}', which does not.""",
    correctionMessage:
        """Try marking the supertype as a static interop class using `@staticInterop`.""",
    arguments: {'name': name, 'name2': name2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldJsInteropStaticInteropWithNonStaticSupertype(
  String name,
  String name2,
) => _withArgumentsJsInteropStaticInteropWithNonStaticSupertype(
  name: name,
  name2: name2,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String label),
  Message Function({required String label})
>
labelNotFound = const Template(
  "LabelNotFound",
  withArgumentsOld: _withArgumentsOldLabelNotFound,
  withArguments: _withArgumentsLabelNotFound,
);

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
Message _withArgumentsOldLabelNotFound(String label) =>
    _withArgumentsLabelNotFound(label: label);

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
  Message Function(int count, int count2, int count3, int count4),
  Message Function({
    required int count,
    required int count2,
    required int count3,
    required int count4,
  })
>
languageVersionTooHighExplicit = const Template(
  "LanguageVersionTooHighExplicit",
  withArgumentsOld: _withArgumentsOldLanguageVersionTooHighExplicit,
  withArguments: _withArgumentsLanguageVersionTooHighExplicit,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsLanguageVersionTooHighExplicit({
  required int count,
  required int count2,
  required int count3,
  required int count4,
}) {
  return new Message(
    languageVersionTooHighExplicit,
    problemMessage:
        """The specified language version ${count}.${count2} is too high. The highest supported language version is ${count3}.${count4}.""",
    arguments: {
      'count': count,
      'count2': count2,
      'count3': count3,
      'count4': count4,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldLanguageVersionTooHighExplicit(
  int count,
  int count2,
  int count3,
  int count4,
) => _withArgumentsLanguageVersionTooHighExplicit(
  count: count,
  count2: count2,
  count3: count3,
  count4: count4,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(int count, int count2, String name, int count3, int count4),
  Message Function({
    required int count,
    required int count2,
    required String name,
    required int count3,
    required int count4,
  })
>
languageVersionTooHighPackage = const Template(
  "LanguageVersionTooHighPackage",
  withArgumentsOld: _withArgumentsOldLanguageVersionTooHighPackage,
  withArguments: _withArgumentsLanguageVersionTooHighPackage,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsLanguageVersionTooHighPackage({
  required int count,
  required int count2,
  required String name,
  required int count3,
  required int count4,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    languageVersionTooHighPackage,
    problemMessage:
        """The language version ${count}.${count2} specified for the package '${name_0}' is too high. The highest supported language version is ${count3}.${count4}.""",
    arguments: {
      'count': count,
      'count2': count2,
      'name': name,
      'count3': count3,
      'count4': count4,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldLanguageVersionTooHighPackage(
  int count,
  int count2,
  String name,
  int count3,
  int count4,
) => _withArgumentsLanguageVersionTooHighPackage(
  count: count,
  count2: count2,
  name: name,
  count3: count3,
  count4: count4,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(int count, int count2, int count3, int count4),
  Message Function({
    required int count,
    required int count2,
    required int count3,
    required int count4,
  })
>
languageVersionTooLowExplicit = const Template(
  "LanguageVersionTooLowExplicit",
  withArgumentsOld: _withArgumentsOldLanguageVersionTooLowExplicit,
  withArguments: _withArgumentsLanguageVersionTooLowExplicit,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsLanguageVersionTooLowExplicit({
  required int count,
  required int count2,
  required int count3,
  required int count4,
}) {
  return new Message(
    languageVersionTooLowExplicit,
    problemMessage:
        """The specified language version ${count}.${count2} is too low. The lowest supported language version is ${count3}.${count4}.""",
    arguments: {
      'count': count,
      'count2': count2,
      'count3': count3,
      'count4': count4,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldLanguageVersionTooLowExplicit(
  int count,
  int count2,
  int count3,
  int count4,
) => _withArgumentsLanguageVersionTooLowExplicit(
  count: count,
  count2: count2,
  count3: count3,
  count4: count4,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(int count, int count2, String name, int count3, int count4),
  Message Function({
    required int count,
    required int count2,
    required String name,
    required int count3,
    required int count4,
  })
>
languageVersionTooLowPackage = const Template(
  "LanguageVersionTooLowPackage",
  withArgumentsOld: _withArgumentsOldLanguageVersionTooLowPackage,
  withArguments: _withArgumentsLanguageVersionTooLowPackage,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsLanguageVersionTooLowPackage({
  required int count,
  required int count2,
  required String name,
  required int count3,
  required int count4,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    languageVersionTooLowPackage,
    problemMessage:
        """The language version ${count}.${count2} specified for the package '${name_0}' is too low. The lowest supported language version is ${count3}.${count4}.""",
    arguments: {
      'count': count,
      'count2': count2,
      'name': name,
      'count3': count3,
      'count4': count4,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldLanguageVersionTooLowPackage(
  int count,
  int count2,
  String name,
  int count3,
  int count4,
) => _withArgumentsLanguageVersionTooLowPackage(
  count: count,
  count2: count2,
  name: name,
  count3: count3,
  count4: count4,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
lateDefinitelyAssignedError = const Template(
  "LateDefinitelyAssignedError",
  withArgumentsOld: _withArgumentsOldLateDefinitelyAssignedError,
  withArguments: _withArgumentsLateDefinitelyAssignedError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsLateDefinitelyAssignedError({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    lateDefinitelyAssignedError,
    problemMessage: """Late final variable '${name_0}' definitely assigned.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldLateDefinitelyAssignedError(String name) =>
    _withArgumentsLateDefinitelyAssignedError(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
lateDefinitelyUnassignedError = const Template(
  "LateDefinitelyUnassignedError",
  withArgumentsOld: _withArgumentsOldLateDefinitelyUnassignedError,
  withArguments: _withArgumentsLateDefinitelyUnassignedError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsLateDefinitelyUnassignedError({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    lateDefinitelyUnassignedError,
    problemMessage:
        """Late variable '${name_0}' without initializer is definitely unassigned.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldLateDefinitelyUnassignedError(String name) =>
    _withArgumentsLateDefinitelyUnassignedError(name: name);

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
const Template<
  Message Function(String name),
  Message Function({required String name})
>
localVariableUsedBeforeDeclared = const Template(
  "LocalVariableUsedBeforeDeclared",
  withArgumentsOld: _withArgumentsOldLocalVariableUsedBeforeDeclared,
  withArguments: _withArgumentsLocalVariableUsedBeforeDeclared,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsLocalVariableUsedBeforeDeclared({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    localVariableUsedBeforeDeclared,
    problemMessage:
        """Local variable '${name_0}' can't be referenced before it is declared.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldLocalVariableUsedBeforeDeclared(String name) =>
    _withArgumentsLocalVariableUsedBeforeDeclared(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
localVariableUsedBeforeDeclaredContext = const Template(
  "LocalVariableUsedBeforeDeclaredContext",
  withArgumentsOld: _withArgumentsOldLocalVariableUsedBeforeDeclaredContext,
  withArguments: _withArgumentsLocalVariableUsedBeforeDeclaredContext,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsLocalVariableUsedBeforeDeclaredContext({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    localVariableUsedBeforeDeclaredContext,
    problemMessage: """This is the declaration of the variable '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldLocalVariableUsedBeforeDeclaredContext(String name) =>
    _withArgumentsLocalVariableUsedBeforeDeclaredContext(name: name);

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
  Message Function(DartType type, DartType type2),
  Message Function({required DartType type, required DartType type2})
>
mainWrongParameterType = const Template(
  "MainWrongParameterType",
  withArgumentsOld: _withArgumentsOldMainWrongParameterType,
  withArguments: _withArgumentsMainWrongParameterType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMainWrongParameterType({
  required DartType type,
  required DartType type2,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var type2_0 = labeler.labelType(type2);
  return new Message(
    mainWrongParameterType,
    problemMessage:
        """The type '${type_0}' of the first parameter of the 'main' method is not a supertype of '${type2_0}'.""" +
        labeler.originMessages,
    arguments: {'type': type, 'type2': type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldMainWrongParameterType(
  DartType type,
  DartType type2,
) => _withArgumentsMainWrongParameterType(type: type, type2: type2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type, DartType type2),
  Message Function({required DartType type, required DartType type2})
>
mainWrongParameterTypeExported = const Template(
  "MainWrongParameterTypeExported",
  withArgumentsOld: _withArgumentsOldMainWrongParameterTypeExported,
  withArguments: _withArgumentsMainWrongParameterTypeExported,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMainWrongParameterTypeExported({
  required DartType type,
  required DartType type2,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var type2_0 = labeler.labelType(type2);
  return new Message(
    mainWrongParameterTypeExported,
    problemMessage:
        """The type '${type_0}' of the first parameter of the exported 'main' method is not a supertype of '${type2_0}'.""" +
        labeler.originMessages,
    arguments: {'type': type, 'type2': type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldMainWrongParameterTypeExported(
  DartType type,
  DartType type2,
) => _withArgumentsMainWrongParameterTypeExported(type: type, type2: type2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode mapPatternTypeArgumentMismatch = const MessageCode(
  "MapPatternTypeArgumentMismatch",
  problemMessage: """A map pattern requires exactly two type arguments.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String constructorName),
  Message Function({required String constructorName})
>
memberConflictsWithConstructor = const Template(
  "MemberConflictsWithConstructor",
  withArgumentsOld: _withArgumentsOldMemberConflictsWithConstructor,
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
Message _withArgumentsOldMemberConflictsWithConstructor(
  String constructorName,
) => _withArgumentsMemberConflictsWithConstructor(
  constructorName: constructorName,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String constructorName),
  Message Function({required String constructorName})
>
memberConflictsWithConstructorCause = const Template(
  "MemberConflictsWithConstructorCause",
  withArgumentsOld: _withArgumentsOldMemberConflictsWithConstructorCause,
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
Message _withArgumentsOldMemberConflictsWithConstructorCause(
  String constructorName,
) => _withArgumentsMemberConflictsWithConstructorCause(
  constructorName: constructorName,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String factoryName),
  Message Function({required String factoryName})
>
memberConflictsWithFactory = const Template(
  "MemberConflictsWithFactory",
  withArgumentsOld: _withArgumentsOldMemberConflictsWithFactory,
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
Message _withArgumentsOldMemberConflictsWithFactory(String factoryName) =>
    _withArgumentsMemberConflictsWithFactory(factoryName: factoryName);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String factoryName),
  Message Function({required String factoryName})
>
memberConflictsWithFactoryCause = const Template(
  "MemberConflictsWithFactoryCause",
  withArgumentsOld: _withArgumentsOldMemberConflictsWithFactoryCause,
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
Message _withArgumentsOldMemberConflictsWithFactoryCause(String factoryName) =>
    _withArgumentsMemberConflictsWithFactoryCause(factoryName: factoryName);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
memberNotFound = const Template(
  "MemberNotFound",
  withArgumentsOld: _withArgumentsOldMemberNotFound,
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
Message _withArgumentsOldMemberNotFound(String name) =>
    _withArgumentsMemberNotFound(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
memberShouldBeListedAsCallableInDynamicInterface = const Template(
  "MemberShouldBeListedAsCallableInDynamicInterface",
  withArgumentsOld:
      _withArgumentsOldMemberShouldBeListedAsCallableInDynamicInterface,
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
Message _withArgumentsOldMemberShouldBeListedAsCallableInDynamicInterface(
  String name,
) => _withArgumentsMemberShouldBeListedAsCallableInDynamicInterface(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String className, String memberName),
  Message Function({required String className, required String memberName})
>
memberShouldBeListedAsCanBeOverriddenInDynamicInterface = const Template(
  "MemberShouldBeListedAsCanBeOverriddenInDynamicInterface",
  withArgumentsOld:
      _withArgumentsOldMemberShouldBeListedAsCanBeOverriddenInDynamicInterface,
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
Message
_withArgumentsOldMemberShouldBeListedAsCanBeOverriddenInDynamicInterface(
  String className,
  String memberName,
) => _withArgumentsMemberShouldBeListedAsCanBeOverriddenInDynamicInterface(
  className: className,
  memberName: memberName,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
methodNotFound = const Template(
  "MethodNotFound",
  withArgumentsOld: _withArgumentsOldMethodNotFound,
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
Message _withArgumentsOldMethodNotFound(String name) =>
    _withArgumentsMethodNotFound(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode missingExplicitConst = const MessageCode(
  "MissingExplicitConst",
  problemMessage: """Constant expression expected.""",
  correctionMessage: """Try inserting 'const'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
missingImplementationCause = const Template(
  "MissingImplementationCause",
  withArgumentsOld: _withArgumentsOldMissingImplementationCause,
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
Message _withArgumentsOldMissingImplementationCause(String name) =>
    _withArgumentsMissingImplementationCause(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String className, List<String> memberNames),
  Message Function({
    required String className,
    required List<String> memberNames,
  })
>
missingImplementationNotAbstract = const Template(
  "MissingImplementationNotAbstract",
  withArgumentsOld: _withArgumentsOldMissingImplementationNotAbstract,
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
Message _withArgumentsOldMissingImplementationNotAbstract(
  String className,
  List<String> memberNames,
) => _withArgumentsMissingImplementationNotAbstract(
  className: className,
  memberNames: memberNames,
);

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
const Template<Message Function(Uri uri), Message Function({required Uri uri})>
missingPartOf = const Template(
  "MissingPartOf",
  withArgumentsOld: _withArgumentsOldMissingPartOf,
  withArguments: _withArgumentsMissingPartOf,
);

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
Message _withArgumentsOldMissingPartOf(Uri uri) =>
    _withArgumentsMissingPartOf(uri: uri);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
missingPositionalSuperConstructorParameter = const MessageCode(
  "MissingPositionalSuperConstructorParameter",
  problemMessage:
      """The super constructor has no corresponding positional parameter.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
missingVariablePattern = const Template(
  "MissingVariablePattern",
  withArgumentsOld: _withArgumentsOldMissingVariablePattern,
  withArguments: _withArgumentsMissingVariablePattern,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMissingVariablePattern({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    missingVariablePattern,
    problemMessage:
        """Variable pattern '${name_0}' is missing in this branch of the logical-or pattern.""",
    correctionMessage: """Try declaring this variable pattern in the branch.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldMissingVariablePattern(String name) =>
    _withArgumentsMissingVariablePattern(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type, DartType type2, DartType type3),
  Message Function({
    required DartType type,
    required DartType type2,
    required DartType type3,
  })
>
mixinApplicationIncompatibleSupertype = const Template(
  "MixinApplicationIncompatibleSupertype",
  withArgumentsOld: _withArgumentsOldMixinApplicationIncompatibleSupertype,
  withArguments: _withArgumentsMixinApplicationIncompatibleSupertype,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMixinApplicationIncompatibleSupertype({
  required DartType type,
  required DartType type2,
  required DartType type3,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var type2_0 = labeler.labelType(type2);
  var type3_0 = labeler.labelType(type3);
  return new Message(
    mixinApplicationIncompatibleSupertype,
    problemMessage:
        """'${type_0}' doesn't implement '${type2_0}' so it can't be used with '${type3_0}'.""" +
        labeler.originMessages,
    arguments: {'type': type, 'type2': type2, 'type3': type3},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldMixinApplicationIncompatibleSupertype(
  DartType type,
  DartType type2,
  DartType type3,
) => _withArgumentsMixinApplicationIncompatibleSupertype(
  type: type,
  type2: type2,
  type3: type3,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
mixinApplicationNoConcreteGetter = const Template(
  "MixinApplicationNoConcreteGetter",
  withArgumentsOld: _withArgumentsOldMixinApplicationNoConcreteGetter,
  withArguments: _withArgumentsMixinApplicationNoConcreteGetter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMixinApplicationNoConcreteGetter({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    mixinApplicationNoConcreteGetter,
    problemMessage:
        """The class doesn't have a concrete implementation of the super-accessed member '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldMixinApplicationNoConcreteGetter(String name) =>
    _withArgumentsMixinApplicationNoConcreteGetter(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode mixinApplicationNoConcreteMemberContext = const MessageCode(
  "MixinApplicationNoConcreteMemberContext",
  severity: CfeSeverity.context,
  problemMessage:
      """This is the super-access that doesn't have a concrete target.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
mixinApplicationNoConcreteMethod = const Template(
  "MixinApplicationNoConcreteMethod",
  withArgumentsOld: _withArgumentsOldMixinApplicationNoConcreteMethod,
  withArguments: _withArgumentsMixinApplicationNoConcreteMethod,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMixinApplicationNoConcreteMethod({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    mixinApplicationNoConcreteMethod,
    problemMessage:
        """The class doesn't have a concrete implementation of the super-invoked member '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldMixinApplicationNoConcreteMethod(String name) =>
    _withArgumentsMixinApplicationNoConcreteMethod(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
mixinApplicationNoConcreteSetter = const Template(
  "MixinApplicationNoConcreteSetter",
  withArgumentsOld: _withArgumentsOldMixinApplicationNoConcreteSetter,
  withArguments: _withArgumentsMixinApplicationNoConcreteSetter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMixinApplicationNoConcreteSetter({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    mixinApplicationNoConcreteSetter,
    problemMessage:
        """The class doesn't have a concrete implementation of the super-accessed setter '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldMixinApplicationNoConcreteSetter(String name) =>
    _withArgumentsMixinApplicationNoConcreteSetter(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode mixinDeferredMixin = const MessageCode(
  "MixinDeferredMixin",
  problemMessage: """Classes can't mix in deferred mixins.""",
  correctionMessage: """Try changing the import to not be deferred.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, String name2, DartType type),
  Message Function({
    required String name,
    required String name2,
    required DartType type,
  })
>
mixinInferenceNoMatchingClass = const Template(
  "MixinInferenceNoMatchingClass",
  withArgumentsOld: _withArgumentsOldMixinInferenceNoMatchingClass,
  withArguments: _withArgumentsMixinInferenceNoMatchingClass,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMixinInferenceNoMatchingClass({
  required String name,
  required String name2,
  required DartType type,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var name2_0 = conversions.validateAndDemangleName(name2);
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    mixinInferenceNoMatchingClass,
    problemMessage:
        """Type parameters couldn't be inferred for the mixin '${name_0}' because '${name2_0}' does not implement the mixin's supertype constraint '${type_0}'.""" +
        labeler.originMessages,
    arguments: {'name': name, 'name2': name2, 'type': type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldMixinInferenceNoMatchingClass(
  String name,
  String name2,
  DartType type,
) => _withArgumentsMixinInferenceNoMatchingClass(
  name: name,
  name2: name2,
  type: type,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
mixinInheritsFromNotObject = const Template(
  "MixinInheritsFromNotObject",
  withArgumentsOld: _withArgumentsOldMixinInheritsFromNotObject,
  withArguments: _withArgumentsMixinInheritsFromNotObject,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMixinInheritsFromNotObject({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    mixinInheritsFromNotObject,
    problemMessage:
        """The class '${name_0}' can't be used as a mixin because it extends a class other than 'Object'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldMixinInheritsFromNotObject(String name) =>
    _withArgumentsMixinInheritsFromNotObject(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, String name2),
  Message Function({required String name, required String name2})
>
mixinSubtypeOfBaseIsNotBase = const Template(
  "MixinSubtypeOfBaseIsNotBase",
  withArgumentsOld: _withArgumentsOldMixinSubtypeOfBaseIsNotBase,
  withArguments: _withArgumentsMixinSubtypeOfBaseIsNotBase,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMixinSubtypeOfBaseIsNotBase({
  required String name,
  required String name2,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var name2_0 = conversions.validateAndDemangleName(name2);
  return new Message(
    mixinSubtypeOfBaseIsNotBase,
    problemMessage:
        """The mixin '${name_0}' must be 'base' because the supertype '${name2_0}' is 'base'.""",
    correctionMessage: """Try adding 'base' to the mixin.""",
    arguments: {'name': name, 'name2': name2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldMixinSubtypeOfBaseIsNotBase(
  String name,
  String name2,
) => _withArgumentsMixinSubtypeOfBaseIsNotBase(name: name, name2: name2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, String name2),
  Message Function({required String name, required String name2})
>
mixinSubtypeOfFinalIsNotBase = const Template(
  "MixinSubtypeOfFinalIsNotBase",
  withArgumentsOld: _withArgumentsOldMixinSubtypeOfFinalIsNotBase,
  withArguments: _withArgumentsMixinSubtypeOfFinalIsNotBase,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMixinSubtypeOfFinalIsNotBase({
  required String name,
  required String name2,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var name2_0 = conversions.validateAndDemangleName(name2);
  return new Message(
    mixinSubtypeOfFinalIsNotBase,
    problemMessage:
        """The mixin '${name_0}' must be 'base' because the supertype '${name2_0}' is 'final'.""",
    correctionMessage: """Try adding 'base' to the mixin.""",
    arguments: {'name': name, 'name2': name2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldMixinSubtypeOfFinalIsNotBase(
  String name,
  String name2,
) => _withArgumentsMixinSubtypeOfFinalIsNotBase(name: name, name2: name2);

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
const Template<
  Message Function(String name),
  Message Function({required String name})
>
nameNotFound = const Template(
  "NameNotFound",
  withArgumentsOld: _withArgumentsOldNameNotFound,
  withArguments: _withArgumentsNameNotFound,
);

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
Message _withArgumentsOldNameNotFound(String name) =>
    _withArgumentsNameNotFound(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string, DartType type),
  Message Function({required String string, required DartType type})
>
nameNotFoundInRecordNameGet = const Template(
  "NameNotFoundInRecordNameGet",
  withArgumentsOld: _withArgumentsOldNameNotFoundInRecordNameGet,
  withArguments: _withArgumentsNameNotFoundInRecordNameGet,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNameNotFoundInRecordNameGet({
  required String string,
  required DartType type,
}) {
  var string_0 = conversions.validateString(string);
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    nameNotFoundInRecordNameGet,
    problemMessage:
        """Field name ${string_0} isn't found in records of type ${type_0}.""" +
        labeler.originMessages,
    arguments: {'string': string, 'type': type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldNameNotFoundInRecordNameGet(
  String string,
  DartType type,
) => _withArgumentsNameNotFoundInRecordNameGet(string: string, type: type);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
namedFieldClashesWithPositionalFieldInRecord = const MessageCode(
  "NamedFieldClashesWithPositionalFieldInRecord",
  problemMessage:
      """Record field names can't be a dollar sign followed by an integer when integer is the index of a positional field.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String className, String overriddenMemberName),
  Message Function({
    required String className,
    required String overriddenMemberName,
  })
>
namedMixinOverride = const Template(
  "NamedMixinOverride",
  withArgumentsOld: _withArgumentsOldNamedMixinOverride,
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
Message _withArgumentsOldNamedMixinOverride(
  String className,
  String overriddenMemberName,
) => _withArgumentsNamedMixinOverride(
  className: className,
  overriddenMemberName: overriddenMemberName,
);

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
const Template<
  Message Function(String name),
  Message Function({required String name})
>
noSuchNamedParameter = const Template(
  "NoSuchNamedParameter",
  withArgumentsOld: _withArgumentsOldNoSuchNamedParameter,
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
Message _withArgumentsOldNoSuchNamedParameter(String name) =>
    _withArgumentsNoSuchNamedParameter(name: name);

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
  Message Function(DartType type, String string, String string2),
  Message Function({
    required DartType type,
    required String string,
    required String string2,
  })
>
nonExhaustiveSwitchExpression = const Template(
  "NonExhaustiveSwitchExpression",
  withArgumentsOld: _withArgumentsOldNonExhaustiveSwitchExpression,
  withArguments: _withArgumentsNonExhaustiveSwitchExpression,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonExhaustiveSwitchExpression({
  required DartType type,
  required String string,
  required String string2,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var string_0 = conversions.validateString(string);
  var string2_0 = conversions.validateString(string2);
  return new Message(
    nonExhaustiveSwitchExpression,
    problemMessage:
        """The type '${type_0}' is not exhaustively matched by the switch cases since it doesn't match '${string_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try adding a wildcard pattern or cases that match '${string2_0}'.""",
    arguments: {'type': type, 'string': string, 'string2': string2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldNonExhaustiveSwitchExpression(
  DartType type,
  String string,
  String string2,
) => _withArgumentsNonExhaustiveSwitchExpression(
  type: type,
  string: string,
  string2: string2,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type, String string, String string2),
  Message Function({
    required DartType type,
    required String string,
    required String string2,
  })
>
nonExhaustiveSwitchStatement = const Template(
  "NonExhaustiveSwitchStatement",
  withArgumentsOld: _withArgumentsOldNonExhaustiveSwitchStatement,
  withArguments: _withArgumentsNonExhaustiveSwitchStatement,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonExhaustiveSwitchStatement({
  required DartType type,
  required String string,
  required String string2,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var string_0 = conversions.validateString(string);
  var string2_0 = conversions.validateString(string2);
  return new Message(
    nonExhaustiveSwitchStatement,
    problemMessage:
        """The type '${type_0}' is not exhaustively matched by the switch cases since it doesn't match '${string_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try adding a default case or cases that match '${string2_0}'.""",
    arguments: {'type': type, 'string': string, 'string2': string2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldNonExhaustiveSwitchStatement(
  DartType type,
  String string,
  String string2,
) => _withArgumentsNonExhaustiveSwitchStatement(
  type: type,
  string: string,
  string2: string2,
);

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
const Template<
  Message Function(DartType type),
  Message Function({required DartType type})
>
nonNullAwareSpreadIsNull = const Template(
  "NonNullAwareSpreadIsNull",
  withArgumentsOld: _withArgumentsOldNonNullAwareSpreadIsNull,
  withArguments: _withArgumentsNonNullAwareSpreadIsNull,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonNullAwareSpreadIsNull({required DartType type}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    nonNullAwareSpreadIsNull,
    problemMessage:
        """Can't spread a value with static type '${type_0}'.""" +
        labeler.originMessages,
    arguments: {'type': type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldNonNullAwareSpreadIsNull(DartType type) =>
    _withArgumentsNonNullAwareSpreadIsNull(type: type);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
nonNullableNotAssignedError = const Template(
  "NonNullableNotAssignedError",
  withArgumentsOld: _withArgumentsOldNonNullableNotAssignedError,
  withArguments: _withArgumentsNonNullableNotAssignedError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonNullableNotAssignedError({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    nonNullableNotAssignedError,
    problemMessage:
        """Non-nullable variable '${name_0}' must be assigned before it can be used.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldNonNullableNotAssignedError(String name) =>
    _withArgumentsNonNullableNotAssignedError(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode nonPositiveArrayDimensions = const MessageCode(
  "NonPositiveArrayDimensions",
  problemMessage: """Array dimensions must be positive numbers.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
nonSimpleBoundViaReference = const Template(
  "NonSimpleBoundViaReference",
  withArgumentsOld: _withArgumentsOldNonSimpleBoundViaReference,
  withArguments: _withArgumentsNonSimpleBoundViaReference,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonSimpleBoundViaReference({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    nonSimpleBoundViaReference,
    problemMessage:
        """Bound of this variable references raw type '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldNonSimpleBoundViaReference(String name) =>
    _withArgumentsNonSimpleBoundViaReference(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
nonSimpleBoundViaVariable = const Template(
  "NonSimpleBoundViaVariable",
  withArgumentsOld: _withArgumentsOldNonSimpleBoundViaVariable,
  withArguments: _withArgumentsNonSimpleBoundViaVariable,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonSimpleBoundViaVariable({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    nonSimpleBoundViaVariable,
    problemMessage:
        """Bound of this variable references variable '${name_0}' from the same declaration.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldNonSimpleBoundViaVariable(String name) =>
    _withArgumentsNonSimpleBoundViaVariable(name: name);

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
  Message Function(String prefix, String typeName),
  Message Function({required String prefix, required String typeName})
>
notAPrefixInTypeAnnotation = const Template(
  "NotAPrefixInTypeAnnotation",
  withArgumentsOld: _withArgumentsOldNotAPrefixInTypeAnnotation,
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
Message _withArgumentsOldNotAPrefixInTypeAnnotation(
  String prefix,
  String typeName,
) => _withArgumentsNotAPrefixInTypeAnnotation(
  prefix: prefix,
  typeName: typeName,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
notAType = const Template(
  "NotAType",
  withArgumentsOld: _withArgumentsOldNotAType,
  withArguments: _withArgumentsNotAType,
);

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
Message _withArgumentsOldNotAType(String name) =>
    _withArgumentsNotAType(name: name);

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
const Template<
  Message Function(Token token),
  Message Function({required Token token})
>
notBinaryOperator = const Template(
  "NotBinaryOperator",
  withArgumentsOld: _withArgumentsOldNotBinaryOperator,
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
Message _withArgumentsOldNotBinaryOperator(Token token) =>
    _withArgumentsNotBinaryOperator(token: token);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String description),
  Message Function({required String description})
>
notConstantExpression = const Template(
  "NotConstantExpression",
  withArgumentsOld: _withArgumentsOldNotConstantExpression,
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
Message _withArgumentsOldNotConstantExpression(String description) =>
    _withArgumentsNotConstantExpression(description: description);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type),
  Message Function({required DartType type})
>
nullableExpressionCallError = const Template(
  "NullableExpressionCallError",
  withArgumentsOld: _withArgumentsOldNullableExpressionCallError,
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
Message _withArgumentsOldNullableExpressionCallError(DartType type) =>
    _withArgumentsNullableExpressionCallError(type: type);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
nullableInterfaceError = const Template(
  "NullableInterfaceError",
  withArgumentsOld: _withArgumentsOldNullableInterfaceError,
  withArguments: _withArgumentsNullableInterfaceError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNullableInterfaceError({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    nullableInterfaceError,
    problemMessage: """Can't implement '${name_0}' because it's nullable.""",
    correctionMessage: """Try removing the question mark.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldNullableInterfaceError(String name) =>
    _withArgumentsNullableInterfaceError(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, DartType type),
  Message Function({required String name, required DartType type})
>
nullableMethodCallError = const Template(
  "NullableMethodCallError",
  withArgumentsOld: _withArgumentsOldNullableMethodCallError,
  withArguments: _withArgumentsNullableMethodCallError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNullableMethodCallError({
  required String name,
  required DartType type,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    nullableMethodCallError,
    problemMessage:
        """Method '${name_0}' cannot be called on '${type_0}' because it is potentially null.""" +
        labeler.originMessages,
    correctionMessage: """Try calling using ?. instead.""",
    arguments: {'name': name, 'type': type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldNullableMethodCallError(String name, DartType type) =>
    _withArgumentsNullableMethodCallError(name: name, type: type);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
nullableMixinError = const Template(
  "NullableMixinError",
  withArgumentsOld: _withArgumentsOldNullableMixinError,
  withArguments: _withArgumentsNullableMixinError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNullableMixinError({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    nullableMixinError,
    problemMessage: """Can't mix '${name_0}' in because it's nullable.""",
    correctionMessage: """Try removing the question mark.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldNullableMixinError(String name) =>
    _withArgumentsNullableMixinError(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, DartType type),
  Message Function({required String name, required DartType type})
>
nullableOperatorCallError = const Template(
  "NullableOperatorCallError",
  withArgumentsOld: _withArgumentsOldNullableOperatorCallError,
  withArguments: _withArgumentsNullableOperatorCallError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNullableOperatorCallError({
  required String name,
  required DartType type,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    nullableOperatorCallError,
    problemMessage:
        """Operator '${name_0}' cannot be called on '${type_0}' because it is potentially null.""" +
        labeler.originMessages,
    arguments: {'name': name, 'type': type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldNullableOperatorCallError(
  String name,
  DartType type,
) => _withArgumentsNullableOperatorCallError(name: name, type: type);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, DartType type),
  Message Function({required String name, required DartType type})
>
nullablePropertyAccessError = const Template(
  "NullablePropertyAccessError",
  withArgumentsOld: _withArgumentsOldNullablePropertyAccessError,
  withArguments: _withArgumentsNullablePropertyAccessError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNullablePropertyAccessError({
  required String name,
  required DartType type,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    nullablePropertyAccessError,
    problemMessage:
        """Property '${name_0}' cannot be accessed on '${type_0}' because it is potentially null.""" +
        labeler.originMessages,
    correctionMessage: """Try accessing using ?. instead.""",
    arguments: {'name': name, 'type': type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldNullablePropertyAccessError(
  String name,
  DartType type,
) => _withArgumentsNullablePropertyAccessError(name: name, type: type);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode nullableSpreadError = const MessageCode(
  "NullableSpreadError",
  problemMessage:
      """An expression whose value can be 'null' must be null-checked before it can be dereferenced.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
nullableSuperclassError = const Template(
  "NullableSuperclassError",
  withArgumentsOld: _withArgumentsOldNullableSuperclassError,
  withArguments: _withArgumentsNullableSuperclassError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNullableSuperclassError({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    nullableSuperclassError,
    problemMessage: """Can't extend '${name_0}' because it's nullable.""",
    correctionMessage: """Try removing the question mark.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldNullableSuperclassError(String name) =>
    _withArgumentsNullableSuperclassError(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
nullableTearoffError = const Template(
  "NullableTearoffError",
  withArgumentsOld: _withArgumentsOldNullableTearoffError,
  withArguments: _withArgumentsNullableTearoffError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNullableTearoffError({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    nullableTearoffError,
    problemMessage:
        """Can't tear off method '${name_0}' from a potentially null value.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldNullableTearoffError(String name) =>
    _withArgumentsNullableTearoffError(name: name);

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
const Template<
  Message Function(String name),
  Message Function({required String name})
>
operatorMinusParameterMismatch = const Template(
  "OperatorMinusParameterMismatch",
  withArgumentsOld: _withArgumentsOldOperatorMinusParameterMismatch,
  withArguments: _withArgumentsOperatorMinusParameterMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOperatorMinusParameterMismatch({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    operatorMinusParameterMismatch,
    problemMessage:
        """Operator '${name_0}' should have zero or one parameter.""",
    correctionMessage:
        """With zero parameters, it has the syntactic form '-a', formally known as 'unary-'. With one parameter, it has the syntactic form 'a - b', formally known as '-'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldOperatorMinusParameterMismatch(String name) =>
    _withArgumentsOperatorMinusParameterMismatch(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
operatorParameterMismatch0 = const Template(
  "OperatorParameterMismatch0",
  withArgumentsOld: _withArgumentsOldOperatorParameterMismatch0,
  withArguments: _withArgumentsOperatorParameterMismatch0,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOperatorParameterMismatch0({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    operatorParameterMismatch0,
    problemMessage: """Operator '${name_0}' shouldn't have any parameters.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldOperatorParameterMismatch0(String name) =>
    _withArgumentsOperatorParameterMismatch0(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
operatorParameterMismatch1 = const Template(
  "OperatorParameterMismatch1",
  withArgumentsOld: _withArgumentsOldOperatorParameterMismatch1,
  withArguments: _withArgumentsOperatorParameterMismatch1,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOperatorParameterMismatch1({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    operatorParameterMismatch1,
    problemMessage:
        """Operator '${name_0}' should have exactly one parameter.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldOperatorParameterMismatch1(String name) =>
    _withArgumentsOperatorParameterMismatch1(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
operatorParameterMismatch2 = const Template(
  "OperatorParameterMismatch2",
  withArgumentsOld: _withArgumentsOldOperatorParameterMismatch2,
  withArguments: _withArgumentsOperatorParameterMismatch2,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOperatorParameterMismatch2({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    operatorParameterMismatch2,
    problemMessage:
        """Operator '${name_0}' should have exactly two parameters.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldOperatorParameterMismatch2(String name) =>
    _withArgumentsOperatorParameterMismatch2(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode operatorWithOptionalFormals = const MessageCode(
  "OperatorWithOptionalFormals",
  problemMessage: """An operator can't have optional parameters.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, DartType type),
  Message Function({required String name, required DartType type})
>
optionalNonNullableWithoutInitializerError = const Template(
  "OptionalNonNullableWithoutInitializerError",
  withArgumentsOld: _withArgumentsOldOptionalNonNullableWithoutInitializerError,
  withArguments: _withArgumentsOptionalNonNullableWithoutInitializerError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOptionalNonNullableWithoutInitializerError({
  required String name,
  required DartType type,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    optionalNonNullableWithoutInitializerError,
    problemMessage:
        """The parameter '${name_0}' can't have a value of 'null' because of its type '${type_0}', but the implicit default value is 'null'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try adding either an explicit non-'null' default value or the 'required' modifier.""",
    arguments: {'name': name, 'type': type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldOptionalNonNullableWithoutInitializerError(
  String name,
  DartType type,
) => _withArgumentsOptionalNonNullableWithoutInitializerError(
  name: name,
  type: type,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode optionalParametersInExtensionTypeDeclaration =
    const MessageCode(
      "OptionalParametersInExtensionTypeDeclaration",
      problemMessage:
          """Extension type declarations can't have optional parameters.""",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type, String name),
  Message Function({required DartType type, required String name})
>
optionalSuperParameterWithoutInitializer = const Template(
  "OptionalSuperParameterWithoutInitializer",
  withArgumentsOld: _withArgumentsOldOptionalSuperParameterWithoutInitializer,
  withArguments: _withArgumentsOptionalSuperParameterWithoutInitializer,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOptionalSuperParameterWithoutInitializer({
  required DartType type,
  required String name,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    optionalSuperParameterWithoutInitializer,
    problemMessage:
        """Type '${type_0}' of the optional super-initializer parameter '${name_0}' doesn't allow 'null', but the parameter doesn't have a default value, and the default value can't be copied from the corresponding parameter of the super constructor.""" +
        labeler.originMessages,
    arguments: {'type': type, 'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldOptionalSuperParameterWithoutInitializer(
  DartType type,
  String name,
) => _withArgumentsOptionalSuperParameterWithoutInitializer(
  type: type,
  name: name,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String methodName),
  Message Function({required String methodName})
>
overriddenMethodCause = const Template(
  "OverriddenMethodCause",
  withArgumentsOld: _withArgumentsOldOverriddenMethodCause,
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
Message _withArgumentsOldOverriddenMethodCause(String methodName) =>
    _withArgumentsOverriddenMethodCause(methodName: methodName);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String declaredMemberName, String overriddenMemberName),
  Message Function({
    required String declaredMemberName,
    required String overriddenMemberName,
  })
>
overrideFewerNamedArguments = const Template(
  "OverrideFewerNamedArguments",
  withArgumentsOld: _withArgumentsOldOverrideFewerNamedArguments,
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
Message _withArgumentsOldOverrideFewerNamedArguments(
  String declaredMemberName,
  String overriddenMemberName,
) => _withArgumentsOverrideFewerNamedArguments(
  declaredMemberName: declaredMemberName,
  overriddenMemberName: overriddenMemberName,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String declaredMemberName, String overriddenMemberName),
  Message Function({
    required String declaredMemberName,
    required String overriddenMemberName,
  })
>
overrideFewerPositionalArguments = const Template(
  "OverrideFewerPositionalArguments",
  withArgumentsOld: _withArgumentsOldOverrideFewerPositionalArguments,
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
Message _withArgumentsOldOverrideFewerPositionalArguments(
  String declaredMemberName,
  String overriddenMemberName,
) => _withArgumentsOverrideFewerPositionalArguments(
  declaredMemberName: declaredMemberName,
  overriddenMemberName: overriddenMemberName,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(
    String declaredMemberName,
    String parameterName,
    String overriddenMemberName,
  ),
  Message Function({
    required String declaredMemberName,
    required String parameterName,
    required String overriddenMemberName,
  })
>
overrideMismatchNamedParameter = const Template(
  "OverrideMismatchNamedParameter",
  withArgumentsOld: _withArgumentsOldOverrideMismatchNamedParameter,
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
Message _withArgumentsOldOverrideMismatchNamedParameter(
  String declaredMemberName,
  String parameterName,
  String overriddenMemberName,
) => _withArgumentsOverrideMismatchNamedParameter(
  declaredMemberName: declaredMemberName,
  parameterName: parameterName,
  overriddenMemberName: overriddenMemberName,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(
    String parameterName,
    String declaredMemberName,
    String overriddenMemberName,
  ),
  Message Function({
    required String parameterName,
    required String declaredMemberName,
    required String overriddenMemberName,
  })
>
overrideMismatchRequiredNamedParameter = const Template(
  "OverrideMismatchRequiredNamedParameter",
  withArgumentsOld: _withArgumentsOldOverrideMismatchRequiredNamedParameter,
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
Message _withArgumentsOldOverrideMismatchRequiredNamedParameter(
  String parameterName,
  String declaredMemberName,
  String overriddenMemberName,
) => _withArgumentsOverrideMismatchRequiredNamedParameter(
  parameterName: parameterName,
  declaredMemberName: declaredMemberName,
  overriddenMemberName: overriddenMemberName,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String declaredMemberName, String overriddenMemberName),
  Message Function({
    required String declaredMemberName,
    required String overriddenMemberName,
  })
>
overrideMoreRequiredArguments = const Template(
  "OverrideMoreRequiredArguments",
  withArgumentsOld: _withArgumentsOldOverrideMoreRequiredArguments,
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
Message _withArgumentsOldOverrideMoreRequiredArguments(
  String declaredMemberName,
  String overriddenMemberName,
) => _withArgumentsOverrideMoreRequiredArguments(
  declaredMemberName: declaredMemberName,
  overriddenMemberName: overriddenMemberName,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(
    String parameterName,
    String declaredMemberName,
    DartType declaredType,
    DartType overriddenType,
    String overriddenMemberName,
  ),
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
  withArgumentsOld: _withArgumentsOldOverrideTypeMismatchParameter,
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
Message _withArgumentsOldOverrideTypeMismatchParameter(
  String parameterName,
  String declaredMemberName,
  DartType declaredType,
  DartType overriddenType,
  String overriddenMemberName,
) => _withArgumentsOverrideTypeMismatchParameter(
  parameterName: parameterName,
  declaredMemberName: declaredMemberName,
  declaredType: declaredType,
  overriddenType: overriddenType,
  overriddenMemberName: overriddenMemberName,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(
    String declaredMemberName,
    DartType declaredType,
    DartType overriddenType,
    String overriddenMemberName,
  ),
  Message Function({
    required String declaredMemberName,
    required DartType declaredType,
    required DartType overriddenType,
    required String overriddenMemberName,
  })
>
overrideTypeMismatchReturnType = const Template(
  "OverrideTypeMismatchReturnType",
  withArgumentsOld: _withArgumentsOldOverrideTypeMismatchReturnType,
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
Message _withArgumentsOldOverrideTypeMismatchReturnType(
  String declaredMemberName,
  DartType declaredType,
  DartType overriddenType,
  String overriddenMemberName,
) => _withArgumentsOverrideTypeMismatchReturnType(
  declaredMemberName: declaredMemberName,
  declaredType: declaredType,
  overriddenType: overriddenType,
  overriddenMemberName: overriddenMemberName,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(
    String declaredMemberName,
    DartType declaredType,
    DartType overriddenType,
    String overriddenMemberName,
  ),
  Message Function({
    required String declaredMemberName,
    required DartType declaredType,
    required DartType overriddenType,
    required String overriddenMemberName,
  })
>
overrideTypeMismatchSetter = const Template(
  "OverrideTypeMismatchSetter",
  withArgumentsOld: _withArgumentsOldOverrideTypeMismatchSetter,
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
Message _withArgumentsOldOverrideTypeMismatchSetter(
  String declaredMemberName,
  DartType declaredType,
  DartType overriddenType,
  String overriddenMemberName,
) => _withArgumentsOverrideTypeMismatchSetter(
  declaredMemberName: declaredMemberName,
  declaredType: declaredType,
  overriddenType: overriddenType,
  overriddenMemberName: overriddenMemberName,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(
    DartType declaredBoundType,
    String typeVariableName,
    String declaredMemberName,
    DartType overriddenBoundType,
    String overriddenMemberName,
  ),
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
  withArgumentsOld: _withArgumentsOldOverrideTypeParametersBoundMismatch,
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
Message _withArgumentsOldOverrideTypeParametersBoundMismatch(
  DartType declaredBoundType,
  String typeVariableName,
  String declaredMemberName,
  DartType overriddenBoundType,
  String overriddenMemberName,
) => _withArgumentsOverrideTypeParametersBoundMismatch(
  declaredBoundType: declaredBoundType,
  typeVariableName: typeVariableName,
  declaredMemberName: declaredMemberName,
  overriddenBoundType: overriddenBoundType,
  overriddenMemberName: overriddenMemberName,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String declaredMemberName, String overriddenMemberName),
  Message Function({
    required String declaredMemberName,
    required String overriddenMemberName,
  })
>
overrideTypeParametersMismatch = const Template(
  "OverrideTypeParametersMismatch",
  withArgumentsOld: _withArgumentsOldOverrideTypeParametersMismatch,
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
Message _withArgumentsOldOverrideTypeParametersMismatch(
  String declaredMemberName,
  String overriddenMemberName,
) => _withArgumentsOverrideTypeParametersMismatch(
  declaredMemberName: declaredMemberName,
  overriddenMemberName: overriddenMemberName,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, Uri uri),
  Message Function({required String name, required Uri uri})
>
packageNotFound = const Template(
  "PackageNotFound",
  withArgumentsOld: _withArgumentsOldPackageNotFound,
  withArguments: _withArgumentsPackageNotFound,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsPackageNotFound({
  required String name,
  required Uri uri,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var uri_0 = conversions.relativizeUri(uri);
  return new Message(
    packageNotFound,
    problemMessage:
        """Couldn't resolve the package '${name_0}' in '${uri_0}'.""",
    arguments: {'name': name, 'uri': uri},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldPackageNotFound(String name, Uri uri) =>
    _withArgumentsPackageNotFound(name: name, uri: uri);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string),
  Message Function({required String string})
>
packagesFileFormat = const Template(
  "PackagesFileFormat",
  withArgumentsOld: _withArgumentsOldPackagesFileFormat,
  withArguments: _withArgumentsPackagesFileFormat,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsPackagesFileFormat({required String string}) {
  var string_0 = conversions.validateString(string);
  return new Message(
    packagesFileFormat,
    problemMessage: """Problem in packages configuration file: ${string_0}""",
    arguments: {'string': string},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldPackagesFileFormat(String string) =>
    _withArgumentsPackagesFileFormat(string: string);

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
const Template<Message Function(Uri uri), Message Function({required Uri uri})>
partOfInLibrary = const Template(
  "PartOfInLibrary",
  withArgumentsOld: _withArgumentsOldPartOfInLibrary,
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
Message _withArgumentsOldPartOfInLibrary(Uri uri) =>
    _withArgumentsPartOfInLibrary(uri: uri);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Uri uri, String libraryName, String partOfName),
  Message Function({
    required Uri uri,
    required String libraryName,
    required String partOfName,
  })
>
partOfLibraryNameMismatch = const Template(
  "PartOfLibraryNameMismatch",
  withArgumentsOld: _withArgumentsOldPartOfLibraryNameMismatch,
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
Message _withArgumentsOldPartOfLibraryNameMismatch(
  Uri uri,
  String libraryName,
  String partOfName,
) => _withArgumentsPartOfLibraryNameMismatch(
  uri: uri,
  libraryName: libraryName,
  partOfName: partOfName,
);

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
  Message Function(Uri partUri, Uri libraryUri, Uri partOfUri),
  Message Function({
    required Uri partUri,
    required Uri libraryUri,
    required Uri partOfUri,
  })
>
partOfUriMismatch = const Template(
  "PartOfUriMismatch",
  withArgumentsOld: _withArgumentsOldPartOfUriMismatch,
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
Message _withArgumentsOldPartOfUriMismatch(
  Uri partUri,
  Uri libraryUri,
  Uri partOfUri,
) => _withArgumentsPartOfUriMismatch(
  partUri: partUri,
  libraryUri: libraryUri,
  partOfUri: partOfUri,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Uri partFileUri, Uri libraryUri, String partOfName),
  Message Function({
    required Uri partFileUri,
    required Uri libraryUri,
    required String partOfName,
  })
>
partOfUseUri = const Template(
  "PartOfUseUri",
  withArgumentsOld: _withArgumentsOldPartOfUseUri,
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
Message _withArgumentsOldPartOfUseUri(
  Uri partFileUri,
  Uri libraryUri,
  String partOfName,
) => _withArgumentsPartOfUseUri(
  partFileUri: partFileUri,
  libraryUri: libraryUri,
  partOfName: partOfName,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode partOrphan = const MessageCode(
  "PartOrphan",
  problemMessage: """This part doesn't have a containing library.""",
  correctionMessage: """Try removing the 'part of' declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri), Message Function({required Uri uri})>
partTwice = const Template(
  "PartTwice",
  withArgumentsOld: _withArgumentsOldPartTwice,
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
Message _withArgumentsOldPartTwice(Uri uri) =>
    _withArgumentsPartTwice(uri: uri);

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
const Template<
  Message Function(String name, Uri uri),
  Message Function({required String name, required Uri uri})
>
patchInjectionFailed = const Template(
  "PatchInjectionFailed",
  withArgumentsOld: _withArgumentsOldPatchInjectionFailed,
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
Message _withArgumentsOldPatchInjectionFailed(String name, Uri uri) =>
    _withArgumentsPatchInjectionFailed(name: name, uri: uri);

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
  Message Function(DartType type, DartType type2),
  Message Function({required DartType type, required DartType type2})
>
patternTypeMismatchInIrrefutableContext = const Template(
  "PatternTypeMismatchInIrrefutableContext",
  withArgumentsOld: _withArgumentsOldPatternTypeMismatchInIrrefutableContext,
  withArguments: _withArgumentsPatternTypeMismatchInIrrefutableContext,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsPatternTypeMismatchInIrrefutableContext({
  required DartType type,
  required DartType type2,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var type2_0 = labeler.labelType(type2);
  return new Message(
    patternTypeMismatchInIrrefutableContext,
    problemMessage:
        """The matched value of type '${type_0}' isn't assignable to the required type '${type2_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try changing the required type of the pattern, or the matched value type.""",
    arguments: {'type': type, 'type2': type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldPatternTypeMismatchInIrrefutableContext(
  DartType type,
  DartType type2,
) => _withArgumentsPatternTypeMismatchInIrrefutableContext(
  type: type,
  type2: type2,
);

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
const Template<
  Message Function(String name),
  Message Function({required String name})
>
privateNamedParameterDuplicatePublicName = const Template(
  "PrivateNamedParameterDuplicatePublicName",
  withArgumentsOld: _withArgumentsOldPrivateNamedParameterDuplicatePublicName,
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
Message _withArgumentsOldPrivateNamedParameterDuplicatePublicName(
  String name,
) => _withArgumentsPrivateNamedParameterDuplicatePublicName(name: name);

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
  Message Function(DartType type, DartType type2),
  Message Function({required DartType type, required DartType type2})
>
redirectingFactoryIncompatibleTypeArgument = const Template(
  "RedirectingFactoryIncompatibleTypeArgument",
  withArgumentsOld: _withArgumentsOldRedirectingFactoryIncompatibleTypeArgument,
  withArguments: _withArgumentsRedirectingFactoryIncompatibleTypeArgument,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsRedirectingFactoryIncompatibleTypeArgument({
  required DartType type,
  required DartType type2,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var type2_0 = labeler.labelType(type2);
  return new Message(
    redirectingFactoryIncompatibleTypeArgument,
    problemMessage:
        """The type '${type_0}' doesn't extend '${type2_0}'.""" +
        labeler.originMessages,
    correctionMessage: """Try using a different type as argument.""",
    arguments: {'type': type, 'type2': type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldRedirectingFactoryIncompatibleTypeArgument(
  DartType type,
  DartType type2,
) => _withArgumentsRedirectingFactoryIncompatibleTypeArgument(
  type: type,
  type2: type2,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
redirectionTargetNotFound = const Template(
  "RedirectionTargetNotFound",
  withArgumentsOld: _withArgumentsOldRedirectionTargetNotFound,
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
Message _withArgumentsOldRedirectionTargetNotFound(String name) =>
    _withArgumentsRedirectionTargetNotFound(name: name);

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
const Template<
  Message Function(String name),
  Message Function({required String name})
>
requiredNamedParameterHasDefaultValueError = const Template(
  "RequiredNamedParameterHasDefaultValueError",
  withArgumentsOld: _withArgumentsOldRequiredNamedParameterHasDefaultValueError,
  withArguments: _withArgumentsRequiredNamedParameterHasDefaultValueError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsRequiredNamedParameterHasDefaultValueError({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    requiredNamedParameterHasDefaultValueError,
    problemMessage:
        """Named parameter '${name_0}' is required and can't have a default value.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldRequiredNamedParameterHasDefaultValueError(
  String name,
) => _withArgumentsRequiredNamedParameterHasDefaultValueError(name: name);

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
const Template<Message Function(Uri uri), Message Function({required Uri uri})>
sdkRootNotFound = const Template(
  "SdkRootNotFound",
  withArgumentsOld: _withArgumentsOldSdkRootNotFound,
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
Message _withArgumentsOldSdkRootNotFound(Uri uri) =>
    _withArgumentsSdkRootNotFound(uri: uri);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri), Message Function({required Uri uri})>
sdkSpecificationNotFound = const Template(
  "SdkSpecificationNotFound",
  withArgumentsOld: _withArgumentsOldSdkSpecificationNotFound,
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
Message _withArgumentsOldSdkSpecificationNotFound(Uri uri) =>
    _withArgumentsSdkSpecificationNotFound(uri: uri);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri), Message Function({required Uri uri})>
sdkSummaryNotFound = const Template(
  "SdkSummaryNotFound",
  withArgumentsOld: _withArgumentsOldSdkSummaryNotFound,
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
Message _withArgumentsOldSdkSummaryNotFound(Uri uri) =>
    _withArgumentsSdkSummaryNotFound(uri: uri);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
sealedClassSubtypeOutsideOfLibrary = const Template(
  "SealedClassSubtypeOutsideOfLibrary",
  withArgumentsOld: _withArgumentsOldSealedClassSubtypeOutsideOfLibrary,
  withArguments: _withArgumentsSealedClassSubtypeOutsideOfLibrary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSealedClassSubtypeOutsideOfLibrary({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    sealedClassSubtypeOutsideOfLibrary,
    problemMessage:
        """The class '${name_0}' can't be extended, implemented, or mixed in outside of its library because it's a sealed class.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldSealedClassSubtypeOutsideOfLibrary(String name) =>
    _withArgumentsSealedClassSubtypeOutsideOfLibrary(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String setterName),
  Message Function({required String setterName})
>
setterConflictsWithDeclaration = const Template(
  "SetterConflictsWithDeclaration",
  withArgumentsOld: _withArgumentsOldSetterConflictsWithDeclaration,
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
Message _withArgumentsOldSetterConflictsWithDeclaration(String setterName) =>
    _withArgumentsSetterConflictsWithDeclaration(setterName: setterName);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String setterName),
  Message Function({required String setterName})
>
setterConflictsWithDeclarationCause = const Template(
  "SetterConflictsWithDeclarationCause",
  withArgumentsOld: _withArgumentsOldSetterConflictsWithDeclarationCause,
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
Message _withArgumentsOldSetterConflictsWithDeclarationCause(
  String setterName,
) => _withArgumentsSetterConflictsWithDeclarationCause(setterName: setterName);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
setterNotFound = const Template(
  "SetterNotFound",
  withArgumentsOld: _withArgumentsOldSetterNotFound,
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
Message _withArgumentsOldSetterNotFound(String name) =>
    _withArgumentsSetterNotFound(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode setterWithWrongNumberOfFormals = const MessageCode(
  "SetterWithWrongNumberOfFormals",
  problemMessage: """A setter should have exactly one formal parameter.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(int count, int count2, num num1, num num2, num num3),
  Message Function({
    required int count,
    required int count2,
    required num num1,
    required num num2,
    required num num3,
  })
>
sourceBodySummary = const Template(
  "SourceBodySummary",
  withArgumentsOld: _withArgumentsOldSourceBodySummary,
  withArguments: _withArgumentsSourceBodySummary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSourceBodySummary({
  required int count,
  required int count2,
  required num num1,
  required num num2,
  required num num3,
}) {
  var num1_0 = conversions.formatNumber(
    num1,
    fractionDigits: 3,
    padWidth: 0,
    padWithZeros: false,
  );
  var num2_0 = conversions.formatNumber(
    num2,
    fractionDigits: 3,
    padWidth: 12,
    padWithZeros: false,
  );
  var num3_0 = conversions.formatNumber(
    num3,
    fractionDigits: 3,
    padWidth: 12,
    padWithZeros: false,
  );
  return new Message(
    sourceBodySummary,
    problemMessage:
        """Built bodies for ${count} compilation units (${count2} bytes) in ${num1_0}ms, that is,
${num2_0} bytes/ms, and
${num3_0} ms/compilation unit.""",
    arguments: {
      'count': count,
      'count2': count2,
      'num1': num1,
      'num2': num2,
      'num3': num3,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldSourceBodySummary(
  int count,
  int count2,
  num num1,
  num num2,
  num num3,
) => _withArgumentsSourceBodySummary(
  count: count,
  count2: count2,
  num1: num1,
  num2: num2,
  num3: num3,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(int count, int count2, num num1, num num2, num num3),
  Message Function({
    required int count,
    required int count2,
    required num num1,
    required num num2,
    required num num3,
  })
>
sourceOutlineSummary = const Template(
  "SourceOutlineSummary",
  withArgumentsOld: _withArgumentsOldSourceOutlineSummary,
  withArguments: _withArgumentsSourceOutlineSummary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSourceOutlineSummary({
  required int count,
  required int count2,
  required num num1,
  required num num2,
  required num num3,
}) {
  var num1_0 = conversions.formatNumber(
    num1,
    fractionDigits: 3,
    padWidth: 0,
    padWithZeros: false,
  );
  var num2_0 = conversions.formatNumber(
    num2,
    fractionDigits: 3,
    padWidth: 12,
    padWithZeros: false,
  );
  var num3_0 = conversions.formatNumber(
    num3,
    fractionDigits: 3,
    padWidth: 12,
    padWithZeros: false,
  );
  return new Message(
    sourceOutlineSummary,
    problemMessage:
        """Built outlines for ${count} compilation units (${count2} bytes) in ${num1_0}ms, that is,
${num2_0} bytes/ms, and
${num3_0} ms/compilation unit.""",
    arguments: {
      'count': count,
      'count2': count2,
      'num1': num1,
      'num2': num2,
      'num3': num3,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldSourceOutlineSummary(
  int count,
  int count2,
  num num1,
  num num2,
  num num3,
) => _withArgumentsSourceOutlineSummary(
  count: count,
  count2: count2,
  num1: num1,
  num2: num2,
  num3: num3,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode spreadElement = const MessageCode(
  "SpreadElement",
  severity: CfeSeverity.context,
  problemMessage: """Iterable spread.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type, DartType type2),
  Message Function({required DartType type, required DartType type2})
>
spreadElementTypeMismatch = const Template(
  "SpreadElementTypeMismatch",
  withArgumentsOld: _withArgumentsOldSpreadElementTypeMismatch,
  withArguments: _withArgumentsSpreadElementTypeMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSpreadElementTypeMismatch({
  required DartType type,
  required DartType type2,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var type2_0 = labeler.labelType(type2);
  return new Message(
    spreadElementTypeMismatch,
    problemMessage:
        """Can't assign spread elements of type '${type_0}' to collection elements of type '${type2_0}'.""" +
        labeler.originMessages,
    arguments: {'type': type, 'type2': type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldSpreadElementTypeMismatch(
  DartType type,
  DartType type2,
) => _withArgumentsSpreadElementTypeMismatch(type: type, type2: type2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode spreadMapElement = const MessageCode(
  "SpreadMapElement",
  severity: CfeSeverity.context,
  problemMessage: """Map spread.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type, DartType type2),
  Message Function({required DartType type, required DartType type2})
>
spreadMapEntryElementKeyTypeMismatch = const Template(
  "SpreadMapEntryElementKeyTypeMismatch",
  withArgumentsOld: _withArgumentsOldSpreadMapEntryElementKeyTypeMismatch,
  withArguments: _withArgumentsSpreadMapEntryElementKeyTypeMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSpreadMapEntryElementKeyTypeMismatch({
  required DartType type,
  required DartType type2,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var type2_0 = labeler.labelType(type2);
  return new Message(
    spreadMapEntryElementKeyTypeMismatch,
    problemMessage:
        """Can't assign spread entry keys of type '${type_0}' to map entry keys of type '${type2_0}'.""" +
        labeler.originMessages,
    arguments: {'type': type, 'type2': type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldSpreadMapEntryElementKeyTypeMismatch(
  DartType type,
  DartType type2,
) => _withArgumentsSpreadMapEntryElementKeyTypeMismatch(
  type: type,
  type2: type2,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type, DartType type2),
  Message Function({required DartType type, required DartType type2})
>
spreadMapEntryElementValueTypeMismatch = const Template(
  "SpreadMapEntryElementValueTypeMismatch",
  withArgumentsOld: _withArgumentsOldSpreadMapEntryElementValueTypeMismatch,
  withArguments: _withArgumentsSpreadMapEntryElementValueTypeMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSpreadMapEntryElementValueTypeMismatch({
  required DartType type,
  required DartType type2,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var type2_0 = labeler.labelType(type2);
  return new Message(
    spreadMapEntryElementValueTypeMismatch,
    problemMessage:
        """Can't assign spread entry values of type '${type_0}' to map entry values of type '${type2_0}'.""" +
        labeler.originMessages,
    arguments: {'type': type, 'type2': type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldSpreadMapEntryElementValueTypeMismatch(
  DartType type,
  DartType type2,
) => _withArgumentsSpreadMapEntryElementValueTypeMismatch(
  type: type,
  type2: type2,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type),
  Message Function({required DartType type})
>
spreadMapEntryTypeMismatch = const Template(
  "SpreadMapEntryTypeMismatch",
  withArgumentsOld: _withArgumentsOldSpreadMapEntryTypeMismatch,
  withArguments: _withArgumentsSpreadMapEntryTypeMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSpreadMapEntryTypeMismatch({required DartType type}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    spreadMapEntryTypeMismatch,
    problemMessage:
        """Unexpected type '${type_0}' of a map spread entry.  Expected 'dynamic' or a Map.""" +
        labeler.originMessages,
    arguments: {'type': type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldSpreadMapEntryTypeMismatch(DartType type) =>
    _withArgumentsSpreadMapEntryTypeMismatch(type: type);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type),
  Message Function({required DartType type})
>
spreadTypeMismatch = const Template(
  "SpreadTypeMismatch",
  withArgumentsOld: _withArgumentsOldSpreadTypeMismatch,
  withArguments: _withArgumentsSpreadTypeMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSpreadTypeMismatch({required DartType type}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    spreadTypeMismatch,
    problemMessage:
        """Unexpected type '${type_0}' of a spread.  Expected 'dynamic' or an Iterable.""" +
        labeler.originMessages,
    arguments: {'type': type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldSpreadTypeMismatch(DartType type) =>
    _withArgumentsSpreadTypeMismatch(type: type);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String propertyName),
  Message Function({required String propertyName})
>
staticConflictsWithInstance = const Template(
  "StaticConflictsWithInstance",
  withArgumentsOld: _withArgumentsOldStaticConflictsWithInstance,
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
Message _withArgumentsOldStaticConflictsWithInstance(String propertyName) =>
    _withArgumentsStaticConflictsWithInstance(propertyName: propertyName);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String propertyName),
  Message Function({required String propertyName})
>
staticConflictsWithInstanceCause = const Template(
  "StaticConflictsWithInstanceCause",
  withArgumentsOld: _withArgumentsOldStaticConflictsWithInstanceCause,
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
Message _withArgumentsOldStaticConflictsWithInstanceCause(
  String propertyName,
) => _withArgumentsStaticConflictsWithInstanceCause(propertyName: propertyName);

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
  Message Function(String name, String name2),
  Message Function({required String name, required String name2})
>
subtypeOfBaseIsNotBaseFinalOrSealed = const Template(
  "SubtypeOfBaseIsNotBaseFinalOrSealed",
  withArgumentsOld: _withArgumentsOldSubtypeOfBaseIsNotBaseFinalOrSealed,
  withArguments: _withArgumentsSubtypeOfBaseIsNotBaseFinalOrSealed,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSubtypeOfBaseIsNotBaseFinalOrSealed({
  required String name,
  required String name2,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var name2_0 = conversions.validateAndDemangleName(name2);
  return new Message(
    subtypeOfBaseIsNotBaseFinalOrSealed,
    problemMessage:
        """The type '${name_0}' must be 'base', 'final' or 'sealed' because the supertype '${name2_0}' is 'base'.""",
    correctionMessage:
        """Try adding 'base', 'final', or 'sealed' to the type.""",
    arguments: {'name': name, 'name2': name2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldSubtypeOfBaseIsNotBaseFinalOrSealed(
  String name,
  String name2,
) =>
    _withArgumentsSubtypeOfBaseIsNotBaseFinalOrSealed(name: name, name2: name2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, String name2),
  Message Function({required String name, required String name2})
>
subtypeOfFinalIsNotBaseFinalOrSealed = const Template(
  "SubtypeOfFinalIsNotBaseFinalOrSealed",
  withArgumentsOld: _withArgumentsOldSubtypeOfFinalIsNotBaseFinalOrSealed,
  withArguments: _withArgumentsSubtypeOfFinalIsNotBaseFinalOrSealed,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSubtypeOfFinalIsNotBaseFinalOrSealed({
  required String name,
  required String name2,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var name2_0 = conversions.validateAndDemangleName(name2);
  return new Message(
    subtypeOfFinalIsNotBaseFinalOrSealed,
    problemMessage:
        """The type '${name_0}' must be 'base', 'final' or 'sealed' because the supertype '${name2_0}' is 'final'.""",
    correctionMessage:
        """Try adding 'base', 'final', or 'sealed' to the type.""",
    arguments: {'name': name, 'name2': name2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldSubtypeOfFinalIsNotBaseFinalOrSealed(
  String name,
  String name2,
) => _withArgumentsSubtypeOfFinalIsNotBaseFinalOrSealed(
  name: name,
  name2: name2,
);

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
  Message Function(DartType type, DartType type2),
  Message Function({required DartType type, required DartType type2})
>
superBoundedHint = const Template(
  "SuperBoundedHint",
  withArgumentsOld: _withArgumentsOldSuperBoundedHint,
  withArguments: _withArgumentsSuperBoundedHint,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperBoundedHint({
  required DartType type,
  required DartType type2,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var type2_0 = labeler.labelType(type2);
  return new Message(
    superBoundedHint,
    problemMessage:
        """If you want '${type_0}' to be a super-bounded type, note that the inverted type '${type2_0}' must then satisfy its bounds, which it does not.""" +
        labeler.originMessages,
    arguments: {'type': type, 'type2': type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldSuperBoundedHint(DartType type, DartType type2) =>
    _withArgumentsSuperBoundedHint(type: type, type2: type2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String typeName),
  Message Function({required String typeName})
>
superExtensionTypeIsIllegal = const Template(
  "SuperExtensionTypeIsIllegal",
  withArgumentsOld: _withArgumentsOldSuperExtensionTypeIsIllegal,
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
Message _withArgumentsOldSuperExtensionTypeIsIllegal(String typeName) =>
    _withArgumentsSuperExtensionTypeIsIllegal(typeName: typeName);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String typeName, DartType aliasedType),
  Message Function({required String typeName, required DartType aliasedType})
>
superExtensionTypeIsIllegalAliased = const Template(
  "SuperExtensionTypeIsIllegalAliased",
  withArgumentsOld: _withArgumentsOldSuperExtensionTypeIsIllegalAliased,
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
Message _withArgumentsOldSuperExtensionTypeIsIllegalAliased(
  String typeName,
  DartType aliasedType,
) => _withArgumentsSuperExtensionTypeIsIllegalAliased(
  typeName: typeName,
  aliasedType: aliasedType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String typeName, DartType aliasedType),
  Message Function({required String typeName, required DartType aliasedType})
>
superExtensionTypeIsNullableAliased = const Template(
  "SuperExtensionTypeIsNullableAliased",
  withArgumentsOld: _withArgumentsOldSuperExtensionTypeIsNullableAliased,
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
Message _withArgumentsOldSuperExtensionTypeIsNullableAliased(
  String typeName,
  DartType aliasedType,
) => _withArgumentsSuperExtensionTypeIsNullableAliased(
  typeName: typeName,
  aliasedType: aliasedType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String typeName),
  Message Function({required String typeName})
>
superExtensionTypeIsTypeParameter = const Template(
  "SuperExtensionTypeIsTypeParameter",
  withArgumentsOld: _withArgumentsOldSuperExtensionTypeIsTypeParameter,
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
Message _withArgumentsOldSuperExtensionTypeIsTypeParameter(String typeName) =>
    _withArgumentsSuperExtensionTypeIsTypeParameter(typeName: typeName);

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
const Template<
  Message Function(String name),
  Message Function({required String name})
>
superclassHasNoConstructor = const Template(
  "SuperclassHasNoConstructor",
  withArgumentsOld: _withArgumentsOldSuperclassHasNoConstructor,
  withArguments: _withArgumentsSuperclassHasNoConstructor,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperclassHasNoConstructor({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    superclassHasNoConstructor,
    problemMessage: """Superclass has no constructor named '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldSuperclassHasNoConstructor(String name) =>
    _withArgumentsSuperclassHasNoConstructor(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
superclassHasNoDefaultConstructor = const Template(
  "SuperclassHasNoDefaultConstructor",
  withArgumentsOld: _withArgumentsOldSuperclassHasNoDefaultConstructor,
  withArguments: _withArgumentsSuperclassHasNoDefaultConstructor,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperclassHasNoDefaultConstructor({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    superclassHasNoDefaultConstructor,
    problemMessage:
        """The superclass, '${name_0}', has no unnamed constructor that takes no arguments.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldSuperclassHasNoDefaultConstructor(String name) =>
    _withArgumentsSuperclassHasNoDefaultConstructor(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
superclassHasNoGetter = const Template(
  "SuperclassHasNoGetter",
  withArgumentsOld: _withArgumentsOldSuperclassHasNoGetter,
  withArguments: _withArgumentsSuperclassHasNoGetter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperclassHasNoGetter({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    superclassHasNoGetter,
    problemMessage: """Superclass has no getter named '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldSuperclassHasNoGetter(String name) =>
    _withArgumentsSuperclassHasNoGetter(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
superclassHasNoMember = const Template(
  "SuperclassHasNoMember",
  withArgumentsOld: _withArgumentsOldSuperclassHasNoMember,
  withArguments: _withArgumentsSuperclassHasNoMember,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperclassHasNoMember({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    superclassHasNoMember,
    problemMessage: """Superclass has no member named '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldSuperclassHasNoMember(String name) =>
    _withArgumentsSuperclassHasNoMember(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
superclassHasNoMethod = const Template(
  "SuperclassHasNoMethod",
  withArgumentsOld: _withArgumentsOldSuperclassHasNoMethod,
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
Message _withArgumentsOldSuperclassHasNoMethod(String name) =>
    _withArgumentsSuperclassHasNoMethod(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
superclassHasNoSetter = const Template(
  "SuperclassHasNoSetter",
  withArgumentsOld: _withArgumentsOldSuperclassHasNoSetter,
  withArguments: _withArgumentsSuperclassHasNoSetter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperclassHasNoSetter({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    superclassHasNoSetter,
    problemMessage: """Superclass has no setter named '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldSuperclassHasNoSetter(String name) =>
    _withArgumentsSuperclassHasNoSetter(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode supertypeIsFunction = const MessageCode(
  "SupertypeIsFunction",
  problemMessage: """Can't use a function type as supertype.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
supertypeIsIllegal = const Template(
  "SupertypeIsIllegal",
  withArgumentsOld: _withArgumentsOldSupertypeIsIllegal,
  withArguments: _withArgumentsSupertypeIsIllegal,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSupertypeIsIllegal({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    supertypeIsIllegal,
    problemMessage: """The type '${name_0}' can't be used as supertype.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldSupertypeIsIllegal(String name) =>
    _withArgumentsSupertypeIsIllegal(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String typeName, DartType aliasedType),
  Message Function({required String typeName, required DartType aliasedType})
>
supertypeIsIllegalAliased = const Template(
  "SupertypeIsIllegalAliased",
  withArgumentsOld: _withArgumentsOldSupertypeIsIllegalAliased,
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
Message _withArgumentsOldSupertypeIsIllegalAliased(
  String typeName,
  DartType aliasedType,
) => _withArgumentsSupertypeIsIllegalAliased(
  typeName: typeName,
  aliasedType: aliasedType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String typeName, DartType aliasedType),
  Message Function({required String typeName, required DartType aliasedType})
>
supertypeIsNullableAliased = const Template(
  "SupertypeIsNullableAliased",
  withArgumentsOld: _withArgumentsOldSupertypeIsNullableAliased,
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
Message _withArgumentsOldSupertypeIsNullableAliased(
  String typeName,
  DartType aliasedType,
) => _withArgumentsSupertypeIsNullableAliased(
  typeName: typeName,
  aliasedType: aliasedType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
supertypeIsTypeParameter = const Template(
  "SupertypeIsTypeParameter",
  withArgumentsOld: _withArgumentsOldSupertypeIsTypeParameter,
  withArguments: _withArgumentsSupertypeIsTypeParameter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSupertypeIsTypeParameter({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    supertypeIsTypeParameter,
    problemMessage:
        """The type variable '${name_0}' can't be used as supertype.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldSupertypeIsTypeParameter(String name) =>
    _withArgumentsSupertypeIsTypeParameter(name: name);

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
  Message Function(DartType type, DartType type2),
  Message Function({required DartType type, required DartType type2})
>
switchExpressionNotSubtype = const Template(
  "SwitchExpressionNotSubtype",
  withArgumentsOld: _withArgumentsOldSwitchExpressionNotSubtype,
  withArguments: _withArgumentsSwitchExpressionNotSubtype,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSwitchExpressionNotSubtype({
  required DartType type,
  required DartType type2,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var type2_0 = labeler.labelType(type2);
  return new Message(
    switchExpressionNotSubtype,
    problemMessage:
        """Type '${type_0}' of the case expression is not a subtype of type '${type2_0}' of this switch expression.""" +
        labeler.originMessages,
    arguments: {'type': type, 'type2': type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldSwitchExpressionNotSubtype(
  DartType type,
  DartType type2,
) => _withArgumentsSwitchExpressionNotSubtype(type: type, type2: type2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode syntheticToken = const MessageCode(
  "SyntheticToken",
  problemMessage: """This couldn't be parsed.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
thisAccessInFieldInitializer = const Template(
  "ThisAccessInFieldInitializer",
  withArgumentsOld: _withArgumentsOldThisAccessInFieldInitializer,
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
Message _withArgumentsOldThisAccessInFieldInitializer(String name) =>
    _withArgumentsThisAccessInFieldInitializer(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode thisAsIdentifier = const MessageCode(
  "ThisAsIdentifier",
  problemMessage: """Expected identifier, but got 'this'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string),
  Message Function({required String string})
>
thisNotPromoted = const Template(
  "ThisNotPromoted",
  withArgumentsOld: _withArgumentsOldThisNotPromoted,
  withArguments: _withArgumentsThisNotPromoted,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsThisNotPromoted({required String string}) {
  var string_0 = conversions.validateString(string);
  return new Message(
    thisNotPromoted,
    problemMessage: """'this' can't be promoted.""",
    correctionMessage: """See ${string_0}""",
    arguments: {'string': string},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldThisNotPromoted(String string) =>
    _withArgumentsThisNotPromoted(string: string);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string),
  Message Function({required String string})
>
thisOrSuperAccessInFieldInitializer = const Template(
  "ThisOrSuperAccessInFieldInitializer",
  withArgumentsOld: _withArgumentsOldThisOrSuperAccessInFieldInitializer,
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
Message _withArgumentsOldThisOrSuperAccessInFieldInitializer(String string) =>
    _withArgumentsThisOrSuperAccessInFieldInitializer(string: string);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type),
  Message Function({required DartType type})
>
throwingNotAssignableToObjectError = const Template(
  "ThrowingNotAssignableToObjectError",
  withArgumentsOld: _withArgumentsOldThrowingNotAssignableToObjectError,
  withArguments: _withArgumentsThrowingNotAssignableToObjectError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsThrowingNotAssignableToObjectError({
  required DartType type,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    throwingNotAssignableToObjectError,
    problemMessage:
        """Can't throw a value of '${type_0}' since it is neither dynamic nor non-nullable.""" +
        labeler.originMessages,
    arguments: {'type': type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldThrowingNotAssignableToObjectError(DartType type) =>
    _withArgumentsThrowingNotAssignableToObjectError(type: type);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(int requiredParameterCount, int actualArgumentCount),
  Message Function({
    required int requiredParameterCount,
    required int actualArgumentCount,
  })
>
tooFewArguments = const Template(
  "TooFewArguments",
  withArgumentsOld: _withArgumentsOldTooFewArguments,
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
Message _withArgumentsOldTooFewArguments(
  int requiredParameterCount,
  int actualArgumentCount,
) => _withArgumentsTooFewArguments(
  requiredParameterCount: requiredParameterCount,
  actualArgumentCount: actualArgumentCount,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(int allowedParameterCount, int actualArgumentCount),
  Message Function({
    required int allowedParameterCount,
    required int actualArgumentCount,
  })
>
tooManyArguments = const Template(
  "TooManyArguments",
  withArgumentsOld: _withArgumentsOldTooManyArguments,
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
Message _withArgumentsOldTooManyArguments(
  int allowedParameterCount,
  int actualArgumentCount,
) => _withArgumentsTooManyArguments(
  allowedParameterCount: allowedParameterCount,
  actualArgumentCount: actualArgumentCount,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(int expectedCount),
  Message Function({required int expectedCount})
>
typeArgumentMismatch = const Template(
  "TypeArgumentMismatch",
  withArgumentsOld: _withArgumentsOldTypeArgumentMismatch,
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
Message _withArgumentsOldTypeArgumentMismatch(int expectedCount) =>
    _withArgumentsTypeArgumentMismatch(expectedCount: expectedCount);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
typeNotFound = const Template(
  "TypeNotFound",
  withArgumentsOld: _withArgumentsOldTypeNotFound,
  withArguments: _withArgumentsTypeNotFound,
);

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
Message _withArgumentsOldTypeNotFound(String name) =>
    _withArgumentsTypeNotFound(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, Uri uri),
  Message Function({required String name, required Uri uri})
>
typeOrigin = const Template(
  "TypeOrigin",
  withArgumentsOld: _withArgumentsOldTypeOrigin,
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
Message _withArgumentsOldTypeOrigin(String name, Uri uri) =>
    _withArgumentsTypeOrigin(name: name, uri: uri);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, Uri uri, Uri uri2),
  Message Function({required String name, required Uri uri, required Uri uri2})
>
typeOriginWithFileUri = const Template(
  "TypeOriginWithFileUri",
  withArgumentsOld: _withArgumentsOldTypeOriginWithFileUri,
  withArguments: _withArgumentsTypeOriginWithFileUri,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsTypeOriginWithFileUri({
  required String name,
  required Uri uri,
  required Uri uri2,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var uri_0 = conversions.relativizeUri(uri);
  var uri2_0 = conversions.relativizeUri(uri2);
  return new Message(
    typeOriginWithFileUri,
    problemMessage: """'${name_0}' is from '${uri_0}' ('${uri2_0}').""",
    arguments: {'name': name, 'uri': uri, 'uri2': uri2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldTypeOriginWithFileUri(
  String name,
  Uri uri,
  Uri uri2,
) => _withArgumentsTypeOriginWithFileUri(name: name, uri: uri, uri2: uri2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode typeParameterDuplicatedName = const MessageCode(
  "TypeParameterDuplicatedName",
  problemMessage: """A type variable can't have the same name as another.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String typeVariableName),
  Message Function({required String typeVariableName})
>
typeParameterDuplicatedNameCause = const Template(
  "TypeParameterDuplicatedNameCause",
  withArgumentsOld: _withArgumentsOldTypeParameterDuplicatedNameCause,
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
Message _withArgumentsOldTypeParameterDuplicatedNameCause(
  String typeVariableName,
) => _withArgumentsTypeParameterDuplicatedNameCause(
  typeVariableName: typeVariableName,
);

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
const Template<Message Function(Uri uri), Message Function({required Uri uri})>
unavailableDartLibrary = const Template(
  "UnavailableDartLibrary",
  withArgumentsOld: _withArgumentsOldUnavailableDartLibrary,
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
Message _withArgumentsOldUnavailableDartLibrary(Uri uri) =>
    _withArgumentsUnavailableDartLibrary(uri: uri);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, DartType type),
  Message Function({required String name, required DartType type})
>
undefinedGetter = const Template(
  "UndefinedGetter",
  withArgumentsOld: _withArgumentsOldUndefinedGetter,
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
Message _withArgumentsOldUndefinedGetter(String name, DartType type) =>
    _withArgumentsUndefinedGetter(name: name, type: type);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, DartType type),
  Message Function({required String name, required DartType type})
>
undefinedMethod = const Template(
  "UndefinedMethod",
  withArgumentsOld: _withArgumentsOldUndefinedMethod,
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
Message _withArgumentsOldUndefinedMethod(String name, DartType type) =>
    _withArgumentsUndefinedMethod(name: name, type: type);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, DartType type),
  Message Function({required String name, required DartType type})
>
undefinedOperator = const Template(
  "UndefinedOperator",
  withArgumentsOld: _withArgumentsOldUndefinedOperator,
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
Message _withArgumentsOldUndefinedOperator(String name, DartType type) =>
    _withArgumentsUndefinedOperator(name: name, type: type);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, DartType type),
  Message Function({required String name, required DartType type})
>
undefinedSetter = const Template(
  "UndefinedSetter",
  withArgumentsOld: _withArgumentsOldUndefinedSetter,
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
Message _withArgumentsOldUndefinedSetter(String name, DartType type) =>
    _withArgumentsUndefinedSetter(name: name, type: type);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
unexpectedSuperParametersInGenerativeConstructors = const MessageCode(
  "UnexpectedSuperParametersInGenerativeConstructors",
  problemMessage:
      """Super parameters can only be used in non-redirecting generative constructors.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
unmatchedAugmentationClass = const Template(
  "UnmatchedAugmentationClass",
  withArgumentsOld: _withArgumentsOldUnmatchedAugmentationClass,
  withArguments: _withArgumentsUnmatchedAugmentationClass,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnmatchedAugmentationClass({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    unmatchedAugmentationClass,
    problemMessage:
        """Augmentation class '${name_0}' doesn't match a class in the augmented library.""",
    correctionMessage:
        """Try changing the name to an existing class or removing the 'augment' modifier.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldUnmatchedAugmentationClass(String name) =>
    _withArgumentsUnmatchedAugmentationClass(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
unmatchedAugmentationClassMember = const Template(
  "UnmatchedAugmentationClassMember",
  withArgumentsOld: _withArgumentsOldUnmatchedAugmentationClassMember,
  withArguments: _withArgumentsUnmatchedAugmentationClassMember,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnmatchedAugmentationClassMember({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    unmatchedAugmentationClassMember,
    problemMessage:
        """Augmentation member '${name_0}' doesn't match a member in the augmented class.""",
    correctionMessage:
        """Try changing the name to an existing member or removing the 'augment' modifier.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldUnmatchedAugmentationClassMember(String name) =>
    _withArgumentsUnmatchedAugmentationClassMember(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
unmatchedAugmentationConstructor = const Template(
  "UnmatchedAugmentationConstructor",
  withArgumentsOld: _withArgumentsOldUnmatchedAugmentationConstructor,
  withArguments: _withArgumentsUnmatchedAugmentationConstructor,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnmatchedAugmentationConstructor({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    unmatchedAugmentationConstructor,
    problemMessage:
        """Augmentation constructor '${name_0}' doesn't match a constructor in the augmented class.""",
    correctionMessage:
        """Try changing the name to an existing constructor or removing the 'augment' modifier.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldUnmatchedAugmentationConstructor(String name) =>
    _withArgumentsUnmatchedAugmentationConstructor(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
unmatchedAugmentationDeclaration = const Template(
  "UnmatchedAugmentationDeclaration",
  withArgumentsOld: _withArgumentsOldUnmatchedAugmentationDeclaration,
  withArguments: _withArgumentsUnmatchedAugmentationDeclaration,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnmatchedAugmentationDeclaration({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    unmatchedAugmentationDeclaration,
    problemMessage:
        """Augmentation '${name_0}' doesn't match a declaration in the augmented library.""",
    correctionMessage:
        """Try changing the name to an existing declaration or removing the 'augment' modifier.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldUnmatchedAugmentationDeclaration(String name) =>
    _withArgumentsUnmatchedAugmentationDeclaration(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
unmatchedAugmentationLibraryMember = const Template(
  "UnmatchedAugmentationLibraryMember",
  withArgumentsOld: _withArgumentsOldUnmatchedAugmentationLibraryMember,
  withArguments: _withArgumentsUnmatchedAugmentationLibraryMember,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnmatchedAugmentationLibraryMember({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    unmatchedAugmentationLibraryMember,
    problemMessage:
        """Augmentation member '${name_0}' doesn't match a member in the augmented library.""",
    correctionMessage:
        """Try changing the name to an existing member or removing the 'augment' modifier.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldUnmatchedAugmentationLibraryMember(String name) =>
    _withArgumentsUnmatchedAugmentationLibraryMember(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
unmatchedPatchClass = const Template(
  "UnmatchedPatchClass",
  withArgumentsOld: _withArgumentsOldUnmatchedPatchClass,
  withArguments: _withArgumentsUnmatchedPatchClass,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnmatchedPatchClass({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    unmatchedPatchClass,
    problemMessage:
        """Patch class '${name_0}' doesn't match a class in the origin library.""",
    correctionMessage:
        """Try changing the name to an existing class or removing the '@patch' annotation.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldUnmatchedPatchClass(String name) =>
    _withArgumentsUnmatchedPatchClass(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
unmatchedPatchClassMember = const Template(
  "UnmatchedPatchClassMember",
  withArgumentsOld: _withArgumentsOldUnmatchedPatchClassMember,
  withArguments: _withArgumentsUnmatchedPatchClassMember,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnmatchedPatchClassMember({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    unmatchedPatchClassMember,
    problemMessage:
        """Patch member '${name_0}' doesn't match a member in the origin class.""",
    correctionMessage:
        """Try changing the name to an existing member or removing the '@patch' annotation.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldUnmatchedPatchClassMember(String name) =>
    _withArgumentsUnmatchedPatchClassMember(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
unmatchedPatchDeclaration = const Template(
  "UnmatchedPatchDeclaration",
  withArgumentsOld: _withArgumentsOldUnmatchedPatchDeclaration,
  withArguments: _withArgumentsUnmatchedPatchDeclaration,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnmatchedPatchDeclaration({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    unmatchedPatchDeclaration,
    problemMessage:
        """Patch '${name_0}' doesn't match a declaration in the origin library.""",
    correctionMessage:
        """Try changing the name to an existing declaration or removing the '@patch' annotation.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldUnmatchedPatchDeclaration(String name) =>
    _withArgumentsUnmatchedPatchDeclaration(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
unmatchedPatchLibraryMember = const Template(
  "UnmatchedPatchLibraryMember",
  withArgumentsOld: _withArgumentsOldUnmatchedPatchLibraryMember,
  withArguments: _withArgumentsUnmatchedPatchLibraryMember,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnmatchedPatchLibraryMember({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    unmatchedPatchLibraryMember,
    problemMessage:
        """Patch member '${name_0}' doesn't match a member in the origin library.""",
    correctionMessage:
        """Try changing the name to an existing member or removing the '@patch' annotation.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldUnmatchedPatchLibraryMember(String name) =>
    _withArgumentsUnmatchedPatchLibraryMember(name: name);

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
const Template<Message Function(Uri uri), Message Function({required Uri uri})>
unsupportedPlatformDartLibraryImport = const Template(
  "UnsupportedPlatformDartLibraryImport",
  withArgumentsOld: _withArgumentsOldUnsupportedPlatformDartLibraryImport,
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
Message _withArgumentsOldUnsupportedPlatformDartLibraryImport(Uri uri) =>
    _withArgumentsUnsupportedPlatformDartLibraryImport(uri: uri);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode unterminatedToken = const MessageCode(
  "UnterminatedToken",
  problemMessage: """Incomplete token.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri), Message Function({required Uri uri})>
untranslatableUri = const Template(
  "UntranslatableUri",
  withArgumentsOld: _withArgumentsOldUntranslatableUri,
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
Message _withArgumentsOldUntranslatableUri(Uri uri) =>
    _withArgumentsUntranslatableUri(uri: uri);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
valueForRequiredParameterNotProvidedError = const Template(
  "ValueForRequiredParameterNotProvidedError",
  withArgumentsOld: _withArgumentsOldValueForRequiredParameterNotProvidedError,
  withArguments: _withArgumentsValueForRequiredParameterNotProvidedError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsValueForRequiredParameterNotProvidedError({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    valueForRequiredParameterNotProvidedError,
    problemMessage:
        """Required named parameter '${name_0}' must be provided.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldValueForRequiredParameterNotProvidedError(
  String name,
) => _withArgumentsValueForRequiredParameterNotProvidedError(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, String string),
  Message Function({required String name, required String string})
>
variableCouldBeNullDueToWrite = const Template(
  "VariableCouldBeNullDueToWrite",
  withArgumentsOld: _withArgumentsOldVariableCouldBeNullDueToWrite,
  withArguments: _withArgumentsVariableCouldBeNullDueToWrite,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsVariableCouldBeNullDueToWrite({
  required String name,
  required String string,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var string_0 = conversions.validateString(string);
  return new Message(
    variableCouldBeNullDueToWrite,
    problemMessage:
        """Variable '${name_0}' could not be promoted due to an assignment.""",
    correctionMessage:
        """Try null checking the variable after the assignment.  See ${string_0}""",
    arguments: {'name': name, 'string': string},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldVariableCouldBeNullDueToWrite(
  String name,
  String string,
) => _withArgumentsVariableCouldBeNullDueToWrite(name: name, string: string);

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
  Message Function(String string, String string2),
  Message Function({required String string, required String string2})
>
webLiteralCannotBeRepresentedExactly = const Template(
  "WebLiteralCannotBeRepresentedExactly",
  withArgumentsOld: _withArgumentsOldWebLiteralCannotBeRepresentedExactly,
  withArguments: _withArgumentsWebLiteralCannotBeRepresentedExactly,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsWebLiteralCannotBeRepresentedExactly({
  required String string,
  required String string2,
}) {
  var string_0 = conversions.validateString(string);
  var string2_0 = conversions.validateString(string2);
  return new Message(
    webLiteralCannotBeRepresentedExactly,
    problemMessage:
        """The integer literal ${string_0} can't be represented exactly in JavaScript.""",
    correctionMessage:
        """Try changing the literal to something that can be represented in JavaScript. In JavaScript ${string2_0} is the nearest value that can be represented exactly.""",
    arguments: {'string': string, 'string2': string2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldWebLiteralCannotBeRepresentedExactly(
  String string,
  String string2,
) => _withArgumentsWebLiteralCannotBeRepresentedExactly(
  string: string,
  string2: string2,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, DartType type),
  Message Function({required String name, required DartType type})
>
wrongTypeParameterVarianceInSuperinterface = const Template(
  "WrongTypeParameterVarianceInSuperinterface",
  withArgumentsOld: _withArgumentsOldWrongTypeParameterVarianceInSuperinterface,
  withArguments: _withArgumentsWrongTypeParameterVarianceInSuperinterface,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsWrongTypeParameterVarianceInSuperinterface({
  required String name,
  required DartType type,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    wrongTypeParameterVarianceInSuperinterface,
    problemMessage:
        """'${name_0}' can't be used contravariantly or invariantly in '${type_0}'.""" +
        labeler.originMessages,
    arguments: {'name': name, 'type': type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldWrongTypeParameterVarianceInSuperinterface(
  String name,
  DartType type,
) => _withArgumentsWrongTypeParameterVarianceInSuperinterface(
  name: name,
  type: type,
);
