// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// NOTE: THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/front_end/messages.yaml' and defer to it for the
// commands to update this file.

// ignore_for_file: lines_longer_than_80_chars

part of 'cfe_codes.dart';

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeAbstractClassConstructorTearOff = const MessageCode(
  "AbstractClassConstructorTearOff",
  problemMessage: r"""Constructors on abstract classes can't be torn off.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeAbstractClassInstantiation = const Template(
  "AbstractClassInstantiation",
  problemMessageTemplate:
      r"""The class '#name' is abstract and can't be instantiated.""",
  withArgumentsOld: _withArgumentsOldAbstractClassInstantiation,
  withArguments: _withArgumentsAbstractClassInstantiation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsAbstractClassInstantiation({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeAbstractClassInstantiation,
    problemMessage:
        """The class '${name_0}' is abstract and can't be instantiated.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldAbstractClassInstantiation(String name) =>
    _withArgumentsAbstractClassInstantiation(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeAbstractFieldConstructorInitializer = const MessageCode(
  "AbstractFieldConstructorInitializer",
  problemMessage: r"""Abstract fields cannot have initializers.""",
  correctionMessage:
      r"""Try removing the field initializer or the 'abstract' keyword from the field declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeAbstractFieldInitializer = const MessageCode(
  "AbstractFieldInitializer",
  problemMessage: r"""Abstract fields cannot have initializers.""",
  correctionMessage:
      r"""Try removing the initializer or the 'abstract' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeAbstractRedirectedClassInstantiation = const Template(
  "AbstractRedirectedClassInstantiation",
  problemMessageTemplate:
      r"""Factory redirects to class '#name', which is abstract and can't be instantiated.""",
  withArgumentsOld: _withArgumentsOldAbstractRedirectedClassInstantiation,
  withArguments: _withArgumentsAbstractRedirectedClassInstantiation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsAbstractRedirectedClassInstantiation({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeAbstractRedirectedClassInstantiation,
    problemMessage:
        """Factory redirects to class '${name_0}', which is abstract and can't be instantiated.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldAbstractRedirectedClassInstantiation(String name) =>
    _withArgumentsAbstractRedirectedClassInstantiation(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeAmbiguousExtensionCause = const MessageCode(
  "AmbiguousExtensionCause",
  severity: CfeSeverity.context,
  problemMessage: r"""This is one of the extension members.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, DartType type),
  Message Function({required String name, required DartType type})
>
codeAmbiguousExtensionMethod = const Template(
  "AmbiguousExtensionMethod",
  problemMessageTemplate:
      r"""The method '#name' is defined in multiple extensions for '#type' and neither is more specific.""",
  correctionMessageTemplate:
      r"""Try using an explicit extension application of the wanted extension or hiding unwanted extensions from scope.""",
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
    codeAmbiguousExtensionMethod,
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
codeAmbiguousExtensionOperator = const Template(
  "AmbiguousExtensionOperator",
  problemMessageTemplate:
      r"""The operator '#name' is defined in multiple extensions for '#type' and neither is more specific.""",
  correctionMessageTemplate:
      r"""Try using an explicit extension application of the wanted extension or hiding unwanted extensions from scope.""",
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
    codeAmbiguousExtensionOperator,
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
codeAmbiguousExtensionProperty = const Template(
  "AmbiguousExtensionProperty",
  problemMessageTemplate:
      r"""The property '#name' is defined in multiple extensions for '#type' and neither is more specific.""",
  correctionMessageTemplate:
      r"""Try using an explicit extension application of the wanted extension or hiding unwanted extensions from scope.""",
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
    codeAmbiguousExtensionProperty,
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
codeAmbiguousSupertypes = const Template(
  "AmbiguousSupertypes",
  problemMessageTemplate:
      r"""'#name' can't implement both '#type' and '#type2'""",
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
    codeAmbiguousSupertypes,
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
const MessageCode codeAnnotationOnFunctionTypeTypeParameter = const MessageCode(
  "AnnotationOnFunctionTypeTypeParameter",
  problemMessage:
      r"""A type variable on a function type can't have annotations.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeAnonymousBreakTargetOutsideFunction = const MessageCode(
  "AnonymousBreakTargetOutsideFunction",
  problemMessage: r"""Can't break to a target in a different function.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeAnonymousContinueTargetOutsideFunction =
    const MessageCode(
      "AnonymousContinueTargetOutsideFunction",
      problemMessage:
          r"""Can't continue at a target in a different function.""",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type, DartType type2),
  Message Function({required DartType type, required DartType type2})
>
codeArgumentTypeNotAssignable = const Template(
  "ArgumentTypeNotAssignable",
  problemMessageTemplate:
      r"""The argument type '#type' can't be assigned to the parameter type '#type2'.""",
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
    codeArgumentTypeNotAssignable,
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
const MessageCode codeAwaitInLateLocalInitializer = const MessageCode(
  "AwaitInLateLocalInitializer",
  problemMessage:
      r"""`await` expressions are not supported in late local initializers.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeAwaitOfExtensionTypeNotFuture = const MessageCode(
  "AwaitOfExtensionTypeNotFuture",
  problemMessage:
      r"""The 'await' expression can't be used for an expression with an extension type that is not a subtype of 'Future'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeBaseClassImplementedOutsideOfLibrary = const Template(
  "BaseClassImplementedOutsideOfLibrary",
  problemMessageTemplate:
      r"""The class '#name' can't be implemented outside of its library because it's a base class.""",
  withArgumentsOld: _withArgumentsOldBaseClassImplementedOutsideOfLibrary,
  withArguments: _withArgumentsBaseClassImplementedOutsideOfLibrary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsBaseClassImplementedOutsideOfLibrary({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeBaseClassImplementedOutsideOfLibrary,
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
codeBaseMixinImplementedOutsideOfLibrary = const Template(
  "BaseMixinImplementedOutsideOfLibrary",
  problemMessageTemplate:
      r"""The mixin '#name' can't be implemented outside of its library because it's a base mixin.""",
  withArgumentsOld: _withArgumentsOldBaseMixinImplementedOutsideOfLibrary,
  withArguments: _withArgumentsBaseMixinImplementedOutsideOfLibrary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsBaseMixinImplementedOutsideOfLibrary({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeBaseMixinImplementedOutsideOfLibrary,
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
codeBaseOrFinalClassImplementedOutsideOfLibraryCause = const Template(
  "BaseOrFinalClassImplementedOutsideOfLibraryCause",
  problemMessageTemplate:
      r"""The type '#name' is a subtype of '#name2', and '#name2' is defined here.""",
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
    codeBaseOrFinalClassImplementedOutsideOfLibraryCause,
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
codeBoundIssueViaCycleNonSimplicity = const Template(
  "BoundIssueViaCycleNonSimplicity",
  problemMessageTemplate:
      r"""Generic type '#name' can't be used without type arguments in the bounds of its own type variables. It is referenced indirectly through '#name2'.""",
  correctionMessageTemplate:
      r"""Try providing type arguments to '#name2' here or to some other raw types in the bounds along the reference chain.""",
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
    codeBoundIssueViaCycleNonSimplicity,
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
codeBoundIssueViaLoopNonSimplicity = const Template(
  "BoundIssueViaLoopNonSimplicity",
  problemMessageTemplate:
      r"""Generic type '#name' can't be used without type arguments in the bounds of its own type variables.""",
  correctionMessageTemplate:
      r"""Try providing type arguments to '#name' here.""",
  withArgumentsOld: _withArgumentsOldBoundIssueViaLoopNonSimplicity,
  withArguments: _withArgumentsBoundIssueViaLoopNonSimplicity,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsBoundIssueViaLoopNonSimplicity({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeBoundIssueViaLoopNonSimplicity,
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
codeBoundIssueViaRawTypeWithNonSimpleBounds = const Template(
  "BoundIssueViaRawTypeWithNonSimpleBounds",
  problemMessageTemplate:
      r"""Generic type '#name' can't be used without type arguments in a type variable bound.""",
  correctionMessageTemplate:
      r"""Try providing type arguments to '#name' here.""",
  withArgumentsOld: _withArgumentsOldBoundIssueViaRawTypeWithNonSimpleBounds,
  withArguments: _withArgumentsBoundIssueViaRawTypeWithNonSimpleBounds,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsBoundIssueViaRawTypeWithNonSimpleBounds({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeBoundIssueViaRawTypeWithNonSimpleBounds,
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
  Message Function(String name),
  Message Function({required String name})
>
codeBreakTargetOutsideFunction = const Template(
  "BreakTargetOutsideFunction",
  problemMessageTemplate:
      r"""Can't break to '#name' in a different function.""",
  withArgumentsOld: _withArgumentsOldBreakTargetOutsideFunction,
  withArguments: _withArgumentsBreakTargetOutsideFunction,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsBreakTargetOutsideFunction({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeBreakTargetOutsideFunction,
    problemMessage: """Can't break to '${name_0}' in a different function.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldBreakTargetOutsideFunction(String name) =>
    _withArgumentsBreakTargetOutsideFunction(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeCandidateFound = const MessageCode(
  "CandidateFound",
  severity: CfeSeverity.context,
  problemMessage: r"""Found this candidate, but the arguments don't match.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeCandidateFoundIsDefaultConstructor = const Template(
  "CandidateFoundIsDefaultConstructor",
  problemMessageTemplate:
      r"""The class '#name' has a constructor that takes no arguments.""",
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
    codeCandidateFoundIsDefaultConstructor,
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
codeCannotAssignToConstVariable = const Template(
  "CannotAssignToConstVariable",
  problemMessageTemplate: r"""Can't assign to the const variable '#name'.""",
  withArgumentsOld: _withArgumentsOldCannotAssignToConstVariable,
  withArguments: _withArgumentsCannotAssignToConstVariable,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCannotAssignToConstVariable({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeCannotAssignToConstVariable,
    problemMessage: """Can't assign to the const variable '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldCannotAssignToConstVariable(String name) =>
    _withArgumentsCannotAssignToConstVariable(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeCannotAssignToExtensionThis = const MessageCode(
  "CannotAssignToExtensionThis",
  problemMessage: r"""Can't assign to 'this'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeCannotAssignToFinalVariable = const Template(
  "CannotAssignToFinalVariable",
  problemMessageTemplate: r"""Can't assign to the final variable '#name'.""",
  withArgumentsOld: _withArgumentsOldCannotAssignToFinalVariable,
  withArguments: _withArgumentsCannotAssignToFinalVariable,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCannotAssignToFinalVariable({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeCannotAssignToFinalVariable,
    problemMessage: """Can't assign to the final variable '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldCannotAssignToFinalVariable(String name) =>
    _withArgumentsCannotAssignToFinalVariable(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeCannotAssignToParenthesizedExpression = const MessageCode(
  "CannotAssignToParenthesizedExpression",
  problemMessage: r"""Can't assign to a parenthesized expression.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeCannotAssignToSuper = const MessageCode(
  "CannotAssignToSuper",
  problemMessage: r"""Can't assign to super.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeCannotAssignToTypeLiteral = const MessageCode(
  "CannotAssignToTypeLiteral",
  problemMessage: r"""Can't assign to a type literal.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string),
  Message Function({required String string})
>
codeCannotReadSdkSpecification = const Template(
  "CannotReadSdkSpecification",
  problemMessageTemplate:
      r"""Unable to read the 'libraries.json' specification file:
  #string.""",
  withArgumentsOld: _withArgumentsOldCannotReadSdkSpecification,
  withArguments: _withArgumentsCannotReadSdkSpecification,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCannotReadSdkSpecification({required String string}) {
  var string_0 = conversions.validateString(string);
  return new Message(
    codeCannotReadSdkSpecification,
    problemMessage: """Unable to read the 'libraries.json' specification file:
  ${string_0}.""",
    arguments: {'string': string},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldCannotReadSdkSpecification(String string) =>
    _withArgumentsCannotReadSdkSpecification(string: string);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeCantDisambiguateAmbiguousInformation = const MessageCode(
  "CantDisambiguateAmbiguousInformation",
  problemMessage:
      r"""Both Iterable and Map spread elements encountered in ambiguous literal.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeCantDisambiguateNotEnoughInformation = const MessageCode(
  "CantDisambiguateNotEnoughInformation",
  problemMessage:
      r"""Not enough type information to disambiguate between literal set and literal map.""",
  correctionMessage:
      r"""Try providing type arguments for the literal explicitly to disambiguate it.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeCantHaveNamedParameters = const Template(
  "CantHaveNamedParameters",
  problemMessageTemplate:
      r"""'#name' can't be declared with named parameters.""",
  withArgumentsOld: _withArgumentsOldCantHaveNamedParameters,
  withArguments: _withArgumentsCantHaveNamedParameters,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCantHaveNamedParameters({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeCantHaveNamedParameters,
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
codeCantHaveOptionalParameters = const Template(
  "CantHaveOptionalParameters",
  problemMessageTemplate:
      r"""'#name' can't be declared with optional parameters.""",
  withArgumentsOld: _withArgumentsOldCantHaveOptionalParameters,
  withArguments: _withArgumentsCantHaveOptionalParameters,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCantHaveOptionalParameters({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeCantHaveOptionalParameters,
    problemMessage:
        """'${name_0}' can't be declared with optional parameters.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldCantHaveOptionalParameters(String name) =>
    _withArgumentsCantHaveOptionalParameters(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeCantInferPackagesFromManyInputs = const MessageCode(
  "CantInferPackagesFromManyInputs",
  problemMessage:
      r"""Can't infer a packages file when compiling multiple inputs.""",
  correctionMessage:
      r"""Try specifying the file explicitly with the --packages option.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeCantInferPackagesFromPackageUri = const MessageCode(
  "CantInferPackagesFromPackageUri",
  problemMessage:
      r"""Can't infer a packages file from an input 'package:*' URI.""",
  correctionMessage:
      r"""Try specifying the file explicitly with the --packages option.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeCantInferReturnTypeDueToNoCombinedSignature = const Template(
  "CantInferReturnTypeDueToNoCombinedSignature",
  problemMessageTemplate:
      r"""Can't infer a return type for '#name' as the overridden members don't have a combined signature.""",
  correctionMessageTemplate: r"""Try adding an explicit type.""",
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
    codeCantInferReturnTypeDueToNoCombinedSignature,
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
codeCantInferTypeDueToCircularity = const Template(
  "CantInferTypeDueToCircularity",
  problemMessageTemplate:
      r"""Can't infer the type of '#string': circularity found during type inference.""",
  correctionMessageTemplate: r"""Specify the type explicitly.""",
  withArgumentsOld: _withArgumentsOldCantInferTypeDueToCircularity,
  withArguments: _withArgumentsCantInferTypeDueToCircularity,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCantInferTypeDueToCircularity({required String string}) {
  var string_0 = conversions.validateString(string);
  return new Message(
    codeCantInferTypeDueToCircularity,
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
codeCantInferTypeDueToNoCombinedSignature = const Template(
  "CantInferTypeDueToNoCombinedSignature",
  problemMessageTemplate:
      r"""Can't infer a type for '#name' as the overridden members don't have a combined signature.""",
  correctionMessageTemplate: r"""Try adding an explicit type.""",
  withArgumentsOld: _withArgumentsOldCantInferTypeDueToNoCombinedSignature,
  withArguments: _withArgumentsCantInferTypeDueToNoCombinedSignature,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCantInferTypeDueToNoCombinedSignature({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeCantInferTypeDueToNoCombinedSignature,
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
codeCantInferTypesDueToNoCombinedSignature = const Template(
  "CantInferTypesDueToNoCombinedSignature",
  problemMessageTemplate:
      r"""Can't infer types for '#name' as the overridden members don't have a combined signature.""",
  correctionMessageTemplate: r"""Try adding explicit types.""",
  withArgumentsOld: _withArgumentsOldCantInferTypesDueToNoCombinedSignature,
  withArguments: _withArgumentsCantInferTypesDueToNoCombinedSignature,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCantInferTypesDueToNoCombinedSignature({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeCantInferTypesDueToNoCombinedSignature,
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
codeCantReadFile = const Template(
  "CantReadFile",
  problemMessageTemplate: r"""Error when reading '#uri': #string""",
  withArgumentsOld: _withArgumentsOldCantReadFile,
  withArguments: _withArgumentsCantReadFile,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCantReadFile({required Uri uri, required String string}) {
  var uri_0 = conversions.relativizeUri(uri);
  var string_0 = conversions.validateString(string);
  return new Message(
    codeCantReadFile,
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
codeCantUseClassAsMixin = const Template(
  "CantUseClassAsMixin",
  problemMessageTemplate:
      r"""The class '#name' can't be used as a mixin because it isn't a mixin class nor a mixin.""",
  withArgumentsOld: _withArgumentsOldCantUseClassAsMixin,
  withArguments: _withArgumentsCantUseClassAsMixin,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCantUseClassAsMixin({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeCantUseClassAsMixin,
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
codeCantUseControlFlowOrSpreadAsConstant = const Template(
  "CantUseControlFlowOrSpreadAsConstant",
  problemMessageTemplate:
      r"""'#lexeme' is not supported in constant expressions.""",
  withArgumentsOld: _withArgumentsOldCantUseControlFlowOrSpreadAsConstant,
  withArguments: _withArgumentsCantUseControlFlowOrSpreadAsConstant,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCantUseControlFlowOrSpreadAsConstant({
  required Token lexeme,
}) {
  var lexeme_0 = conversions.tokenToLexeme(lexeme);
  return new Message(
    codeCantUseControlFlowOrSpreadAsConstant,
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
codeCantUseDeferredPrefixAsConstant = const Template(
  "CantUseDeferredPrefixAsConstant",
  problemMessageTemplate:
      r"""'#lexeme' can't be used in a constant expression because it's marked as 'deferred' which means it isn't available until loaded.""",
  correctionMessageTemplate:
      r"""Try moving the constant from the deferred library, or removing 'deferred' from the import.""",
  withArgumentsOld: _withArgumentsOldCantUseDeferredPrefixAsConstant,
  withArguments: _withArgumentsCantUseDeferredPrefixAsConstant,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCantUseDeferredPrefixAsConstant({required Token lexeme}) {
  var lexeme_0 = conversions.tokenToLexeme(lexeme);
  return new Message(
    codeCantUseDeferredPrefixAsConstant,
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
const MessageCode codeCantUsePrefixAsExpression = const MessageCode(
  "CantUsePrefixAsExpression",
  problemMessage: r"""A prefix can't be used as an expression.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeCantUsePrefixWithNullAware = const MessageCode(
  "CantUsePrefixWithNullAware",
  problemMessage: r"""A prefix can't be used with null-aware operators.""",
  correctionMessage: r"""Try replacing '?.' with '.'""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeClassImplementsDeferredClass = const MessageCode(
  "ClassImplementsDeferredClass",
  problemMessage: r"""Classes and mixins can't implement deferred classes.""",
  correctionMessage:
      r"""Try specifying a different interface, removing the class from the list, or changing the import to not be deferred.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeClassShouldBeListedAsCallableInDynamicInterface = const Template(
  "ClassShouldBeListedAsCallableInDynamicInterface",
  problemMessageTemplate: r"""Cannot use class '#name' in a dynamic module.""",
  correctionMessageTemplate:
      r"""Try removing the reference to class '#name' or update the dynamic interface to list class '#name' as callable.""",
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
    codeClassShouldBeListedAsCallableInDynamicInterface,
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
codeClassShouldBeListedAsExtendableInDynamicInterface = const Template(
  "ClassShouldBeListedAsExtendableInDynamicInterface",
  problemMessageTemplate:
      r"""Cannot extend, implement or mix-in class '#name' in a dynamic module.""",
  correctionMessageTemplate:
      r"""Try removing the reference to class '#name' or update the dynamic interface to list class '#name' as extendable.""",
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
    codeClassShouldBeListedAsExtendableInDynamicInterface,
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
codeCombinedMemberSignatureFailed = const Template(
  "CombinedMemberSignatureFailed",
  problemMessageTemplate:
      r"""Class '#name' inherits multiple members named '#name2' with incompatible signatures.""",
  correctionMessageTemplate:
      r"""Try adding a declaration of '#name2' to '#name'.""",
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
    codeCombinedMemberSignatureFailed,
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
  Message Function(String name),
  Message Function({required String name})
>
codeConflictsWithImplicitSetter = const Template(
  "ConflictsWithImplicitSetter",
  problemMessageTemplate:
      r"""Conflicts with the implicit setter of the field '#name'.""",
  withArgumentsOld: _withArgumentsOldConflictsWithImplicitSetter,
  withArguments: _withArgumentsConflictsWithImplicitSetter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConflictsWithImplicitSetter({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeConflictsWithImplicitSetter,
    problemMessage:
        """Conflicts with the implicit setter of the field '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConflictsWithImplicitSetter(String name) =>
    _withArgumentsConflictsWithImplicitSetter(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeConflictsWithImplicitSetterCause = const Template(
  "ConflictsWithImplicitSetterCause",
  problemMessageTemplate: r"""Field '#name' with the implicit setter.""",
  withArgumentsOld: _withArgumentsOldConflictsWithImplicitSetterCause,
  withArguments: _withArgumentsConflictsWithImplicitSetterCause,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConflictsWithImplicitSetterCause({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeConflictsWithImplicitSetterCause,
    problemMessage: """Field '${name_0}' with the implicit setter.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConflictsWithImplicitSetterCause(String name) =>
    _withArgumentsConflictsWithImplicitSetterCause(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeConflictsWithTypeParameter = const Template(
  "ConflictsWithTypeParameter",
  problemMessageTemplate: r"""Conflicts with type variable '#name'.""",
  withArgumentsOld: _withArgumentsOldConflictsWithTypeParameter,
  withArguments: _withArgumentsConflictsWithTypeParameter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConflictsWithTypeParameter({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeConflictsWithTypeParameter,
    problemMessage: """Conflicts with type variable '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConflictsWithTypeParameter(String name) =>
    _withArgumentsConflictsWithTypeParameter(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeConflictsWithTypeParameterCause = const MessageCode(
  "ConflictsWithTypeParameterCause",
  severity: CfeSeverity.context,
  problemMessage: r"""This is the type variable.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeConstConstructorLateFinalFieldCause = const MessageCode(
  "ConstConstructorLateFinalFieldCause",
  severity: CfeSeverity.context,
  problemMessage: r"""This constructor is const.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeConstConstructorLateFinalFieldError = const MessageCode(
  "ConstConstructorLateFinalFieldError",
  problemMessage:
      r"""Can't have a late final field in a class with a const constructor.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeConstConstructorNonFinalField = const MessageCode(
  "ConstConstructorNonFinalField",
  problemMessage:
      r"""Constructor is marked 'const' so all fields must be final.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeConstConstructorNonFinalFieldCause = const MessageCode(
  "ConstConstructorNonFinalFieldCause",
  severity: CfeSeverity.context,
  problemMessage: r"""Field isn't final, but constructor is 'const'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeConstConstructorRedirectionToNonConst = const MessageCode(
  "ConstConstructorRedirectionToNonConst",
  problemMessage:
      r"""A constant constructor can't call a non-constant constructor.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeConstConstructorWithNonConstSuper = const MessageCode(
  "ConstConstructorWithNonConstSuper",
  problemMessage:
      r"""A constant constructor can't call a non-constant super constructor.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Constant constant),
  Message Function({required Constant constant})
>
codeConstEvalCaseImplementsEqual = const Template(
  "ConstEvalCaseImplementsEqual",
  problemMessageTemplate:
      r"""Case expression '#constant' does not have a primitive operator '=='.""",
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
    codeConstEvalCaseImplementsEqual,
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
const MessageCode codeConstEvalCircularity = const MessageCode(
  "ConstEvalCircularity",
  problemMessage: r"""Constant expression depends on itself.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeConstEvalContext = const MessageCode(
  "ConstEvalContext",
  severity: CfeSeverity.context,
  problemMessage: r"""While analyzing:""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String nameOKEmpty),
  Message Function({required String nameOKEmpty})
>
codeConstEvalDeferredLibrary = const Template(
  "ConstEvalDeferredLibrary",
  problemMessageTemplate:
      r"""'#nameOKEmpty' can't be used in a constant expression because it's marked as 'deferred' which means it isn't available until loaded.""",
  correctionMessageTemplate:
      r"""Try moving the constant from the deferred library, or removing 'deferred' from the import.""",
  withArgumentsOld: _withArgumentsOldConstEvalDeferredLibrary,
  withArguments: _withArgumentsConstEvalDeferredLibrary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalDeferredLibrary({required String nameOKEmpty}) {
  var nameOKEmpty_0 = conversions.nameOrUnnamed(nameOKEmpty);
  return new Message(
    codeConstEvalDeferredLibrary,
    problemMessage:
        """'${nameOKEmpty_0}' can't be used in a constant expression because it's marked as 'deferred' which means it isn't available until loaded.""",
    correctionMessage:
        """Try moving the constant from the deferred library, or removing 'deferred' from the import.""",
    arguments: {'nameOKEmpty': nameOKEmpty},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConstEvalDeferredLibrary(String nameOKEmpty) =>
    _withArgumentsConstEvalDeferredLibrary(nameOKEmpty: nameOKEmpty);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Constant constant),
  Message Function({required Constant constant})
>
codeConstEvalDuplicateElement = const Template(
  "ConstEvalDuplicateElement",
  problemMessageTemplate:
      r"""The element '#constant' conflicts with another existing element in the set.""",
  withArgumentsOld: _withArgumentsOldConstEvalDuplicateElement,
  withArguments: _withArgumentsConstEvalDuplicateElement,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalDuplicateElement({required Constant constant}) {
  TypeLabeler labeler = new TypeLabeler();
  var constant_0 = labeler.labelConstant(constant);
  return new Message(
    codeConstEvalDuplicateElement,
    problemMessage:
        """The element '${constant_0}' conflicts with another existing element in the set.""" +
        labeler.originMessages,
    arguments: {'constant': constant},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConstEvalDuplicateElement(Constant constant) =>
    _withArgumentsConstEvalDuplicateElement(constant: constant);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Constant constant),
  Message Function({required Constant constant})
>
codeConstEvalDuplicateKey = const Template(
  "ConstEvalDuplicateKey",
  problemMessageTemplate:
      r"""The key '#constant' conflicts with another existing key in the map.""",
  withArgumentsOld: _withArgumentsOldConstEvalDuplicateKey,
  withArguments: _withArgumentsConstEvalDuplicateKey,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalDuplicateKey({required Constant constant}) {
  TypeLabeler labeler = new TypeLabeler();
  var constant_0 = labeler.labelConstant(constant);
  return new Message(
    codeConstEvalDuplicateKey,
    problemMessage:
        """The key '${constant_0}' conflicts with another existing key in the map.""" +
        labeler.originMessages,
    arguments: {'constant': constant},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConstEvalDuplicateKey(Constant constant) =>
    _withArgumentsConstEvalDuplicateKey(constant: constant);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Constant constant),
  Message Function({required Constant constant})
>
codeConstEvalElementImplementsEqual = const Template(
  "ConstEvalElementImplementsEqual",
  problemMessageTemplate:
      r"""The element '#constant' does not have a primitive operator '=='.""",
  withArgumentsOld: _withArgumentsOldConstEvalElementImplementsEqual,
  withArguments: _withArgumentsConstEvalElementImplementsEqual,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalElementImplementsEqual({
  required Constant constant,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var constant_0 = labeler.labelConstant(constant);
  return new Message(
    codeConstEvalElementImplementsEqual,
    problemMessage:
        """The element '${constant_0}' does not have a primitive operator '=='.""" +
        labeler.originMessages,
    arguments: {'constant': constant},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConstEvalElementImplementsEqual(Constant constant) =>
    _withArgumentsConstEvalElementImplementsEqual(constant: constant);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Constant constant),
  Message Function({required Constant constant})
>
codeConstEvalElementNotPrimitiveEquality = const Template(
  "ConstEvalElementNotPrimitiveEquality",
  problemMessageTemplate:
      r"""The element '#constant' does not have a primitive equality.""",
  withArgumentsOld: _withArgumentsOldConstEvalElementNotPrimitiveEquality,
  withArguments: _withArgumentsConstEvalElementNotPrimitiveEquality,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalElementNotPrimitiveEquality({
  required Constant constant,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var constant_0 = labeler.labelConstant(constant);
  return new Message(
    codeConstEvalElementNotPrimitiveEquality,
    problemMessage:
        """The element '${constant_0}' does not have a primitive equality.""" +
        labeler.originMessages,
    arguments: {'constant': constant},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConstEvalElementNotPrimitiveEquality(
  Constant constant,
) => _withArgumentsConstEvalElementNotPrimitiveEquality(constant: constant);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Constant constant, DartType type),
  Message Function({required Constant constant, required DartType type})
>
codeConstEvalEqualsOperandNotPrimitiveEquality = const Template(
  "ConstEvalEqualsOperandNotPrimitiveEquality",
  problemMessageTemplate:
      r"""Binary operator '==' requires receiver constant '#constant' of a type with primitive equality or type 'double', but was of type '#type'.""",
  withArgumentsOld: _withArgumentsOldConstEvalEqualsOperandNotPrimitiveEquality,
  withArguments: _withArgumentsConstEvalEqualsOperandNotPrimitiveEquality,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalEqualsOperandNotPrimitiveEquality({
  required Constant constant,
  required DartType type,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var constant_0 = labeler.labelConstant(constant);
  var type_0 = labeler.labelType(type);
  return new Message(
    codeConstEvalEqualsOperandNotPrimitiveEquality,
    problemMessage:
        """Binary operator '==' requires receiver constant '${constant_0}' of a type with primitive equality or type 'double', but was of type '${type_0}'.""" +
        labeler.originMessages,
    arguments: {'constant': constant, 'type': type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConstEvalEqualsOperandNotPrimitiveEquality(
  Constant constant,
  DartType type,
) => _withArgumentsConstEvalEqualsOperandNotPrimitiveEquality(
  constant: constant,
  type: type,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string),
  Message Function({required String string})
>
codeConstEvalError = const Template(
  "ConstEvalError",
  problemMessageTemplate: r"""Error evaluating constant expression: #string""",
  withArgumentsOld: _withArgumentsOldConstEvalError,
  withArguments: _withArgumentsConstEvalError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalError({required String string}) {
  var string_0 = conversions.validateString(string);
  return new Message(
    codeConstEvalError,
    problemMessage: """Error evaluating constant expression: ${string_0}""",
    arguments: {'string': string},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConstEvalError(String string) =>
    _withArgumentsConstEvalError(string: string);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeConstEvalExtension = const MessageCode(
  "ConstEvalExtension",
  problemMessage:
      r"""Extension operations can't be used in constant expressions.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeConstEvalExternalConstructor = const MessageCode(
  "ConstEvalExternalConstructor",
  problemMessage:
      r"""External constructors can't be evaluated in constant expressions.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeConstEvalExternalFactory = const MessageCode(
  "ConstEvalExternalFactory",
  problemMessage:
      r"""External factory constructors can't be evaluated in constant expressions.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeConstEvalFailedAssertion = const MessageCode(
  "ConstEvalFailedAssertion",
  problemMessage: r"""This assertion failed.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String stringOKEmpty),
  Message Function({required String stringOKEmpty})
>
codeConstEvalFailedAssertionWithMessage = const Template(
  "ConstEvalFailedAssertionWithMessage",
  problemMessageTemplate:
      r"""This assertion failed with message: #stringOKEmpty""",
  withArgumentsOld: _withArgumentsOldConstEvalFailedAssertionWithMessage,
  withArguments: _withArgumentsConstEvalFailedAssertionWithMessage,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalFailedAssertionWithMessage({
  required String stringOKEmpty,
}) {
  var stringOKEmpty_0 = conversions.stringOrEmpty(stringOKEmpty);
  return new Message(
    codeConstEvalFailedAssertionWithMessage,
    problemMessage:
        """This assertion failed with message: ${stringOKEmpty_0}""",
    arguments: {'stringOKEmpty': stringOKEmpty},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConstEvalFailedAssertionWithMessage(
  String stringOKEmpty,
) => _withArgumentsConstEvalFailedAssertionWithMessage(
  stringOKEmpty: stringOKEmpty,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeConstEvalFailedAssertionWithNonStringMessage =
    const MessageCode(
      "ConstEvalFailedAssertionWithNonStringMessage",
      problemMessage: r"""This assertion failed with a non-String message.""",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String nameOKEmpty),
  Message Function({required String nameOKEmpty})
>
codeConstEvalGetterNotFound = const Template(
  "ConstEvalGetterNotFound",
  problemMessageTemplate: r"""Variable get not found: '#nameOKEmpty'""",
  withArgumentsOld: _withArgumentsOldConstEvalGetterNotFound,
  withArguments: _withArgumentsConstEvalGetterNotFound,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalGetterNotFound({required String nameOKEmpty}) {
  var nameOKEmpty_0 = conversions.nameOrUnnamed(nameOKEmpty);
  return new Message(
    codeConstEvalGetterNotFound,
    problemMessage: """Variable get not found: '${nameOKEmpty_0}'""",
    arguments: {'nameOKEmpty': nameOKEmpty},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConstEvalGetterNotFound(String nameOKEmpty) =>
    _withArgumentsConstEvalGetterNotFound(nameOKEmpty: nameOKEmpty);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(
    String stringOKEmpty,
    Constant constant,
    DartType type,
    DartType type2,
  ),
  Message Function({
    required String stringOKEmpty,
    required Constant constant,
    required DartType type,
    required DartType type2,
  })
>
codeConstEvalInvalidBinaryOperandType = const Template(
  "ConstEvalInvalidBinaryOperandType",
  problemMessageTemplate:
      r"""Binary operator '#stringOKEmpty' on '#constant' requires operand of type '#type', but was of type '#type2'.""",
  withArgumentsOld: _withArgumentsOldConstEvalInvalidBinaryOperandType,
  withArguments: _withArgumentsConstEvalInvalidBinaryOperandType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalInvalidBinaryOperandType({
  required String stringOKEmpty,
  required Constant constant,
  required DartType type,
  required DartType type2,
}) {
  var stringOKEmpty_0 = conversions.stringOrEmpty(stringOKEmpty);
  TypeLabeler labeler = new TypeLabeler();
  var constant_0 = labeler.labelConstant(constant);
  var type_0 = labeler.labelType(type);
  var type2_0 = labeler.labelType(type2);
  return new Message(
    codeConstEvalInvalidBinaryOperandType,
    problemMessage:
        """Binary operator '${stringOKEmpty_0}' on '${constant_0}' requires operand of type '${type_0}', but was of type '${type2_0}'.""" +
        labeler.originMessages,
    arguments: {
      'stringOKEmpty': stringOKEmpty,
      'constant': constant,
      'type': type,
      'type2': type2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConstEvalInvalidBinaryOperandType(
  String stringOKEmpty,
  Constant constant,
  DartType type,
  DartType type2,
) => _withArgumentsConstEvalInvalidBinaryOperandType(
  stringOKEmpty: stringOKEmpty,
  constant: constant,
  type: type,
  type2: type2,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Constant constant, DartType type),
  Message Function({required Constant constant, required DartType type})
>
codeConstEvalInvalidEqualsOperandType = const Template(
  "ConstEvalInvalidEqualsOperandType",
  problemMessageTemplate:
      r"""Binary operator '==' requires receiver constant '#constant' of type 'Null', 'bool', 'int', 'double', or 'String', but was of type '#type'.""",
  withArgumentsOld: _withArgumentsOldConstEvalInvalidEqualsOperandType,
  withArguments: _withArgumentsConstEvalInvalidEqualsOperandType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalInvalidEqualsOperandType({
  required Constant constant,
  required DartType type,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var constant_0 = labeler.labelConstant(constant);
  var type_0 = labeler.labelType(type);
  return new Message(
    codeConstEvalInvalidEqualsOperandType,
    problemMessage:
        """Binary operator '==' requires receiver constant '${constant_0}' of type 'Null', 'bool', 'int', 'double', or 'String', but was of type '${type_0}'.""" +
        labeler.originMessages,
    arguments: {'constant': constant, 'type': type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConstEvalInvalidEqualsOperandType(
  Constant constant,
  DartType type,
) => _withArgumentsConstEvalInvalidEqualsOperandType(
  constant: constant,
  type: type,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String stringOKEmpty, Constant constant),
  Message Function({required String stringOKEmpty, required Constant constant})
>
codeConstEvalInvalidMethodInvocation = const Template(
  "ConstEvalInvalidMethodInvocation",
  problemMessageTemplate:
      r"""The method '#stringOKEmpty' can't be invoked on '#constant' in a constant expression.""",
  withArgumentsOld: _withArgumentsOldConstEvalInvalidMethodInvocation,
  withArguments: _withArgumentsConstEvalInvalidMethodInvocation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalInvalidMethodInvocation({
  required String stringOKEmpty,
  required Constant constant,
}) {
  var stringOKEmpty_0 = conversions.stringOrEmpty(stringOKEmpty);
  TypeLabeler labeler = new TypeLabeler();
  var constant_0 = labeler.labelConstant(constant);
  return new Message(
    codeConstEvalInvalidMethodInvocation,
    problemMessage:
        """The method '${stringOKEmpty_0}' can't be invoked on '${constant_0}' in a constant expression.""" +
        labeler.originMessages,
    arguments: {'stringOKEmpty': stringOKEmpty, 'constant': constant},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConstEvalInvalidMethodInvocation(
  String stringOKEmpty,
  Constant constant,
) => _withArgumentsConstEvalInvalidMethodInvocation(
  stringOKEmpty: stringOKEmpty,
  constant: constant,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String stringOKEmpty, Constant constant),
  Message Function({required String stringOKEmpty, required Constant constant})
>
codeConstEvalInvalidPropertyGet = const Template(
  "ConstEvalInvalidPropertyGet",
  problemMessageTemplate:
      r"""The property '#stringOKEmpty' can't be accessed on '#constant' in a constant expression.""",
  withArgumentsOld: _withArgumentsOldConstEvalInvalidPropertyGet,
  withArguments: _withArgumentsConstEvalInvalidPropertyGet,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalInvalidPropertyGet({
  required String stringOKEmpty,
  required Constant constant,
}) {
  var stringOKEmpty_0 = conversions.stringOrEmpty(stringOKEmpty);
  TypeLabeler labeler = new TypeLabeler();
  var constant_0 = labeler.labelConstant(constant);
  return new Message(
    codeConstEvalInvalidPropertyGet,
    problemMessage:
        """The property '${stringOKEmpty_0}' can't be accessed on '${constant_0}' in a constant expression.""" +
        labeler.originMessages,
    arguments: {'stringOKEmpty': stringOKEmpty, 'constant': constant},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConstEvalInvalidPropertyGet(
  String stringOKEmpty,
  Constant constant,
) => _withArgumentsConstEvalInvalidPropertyGet(
  stringOKEmpty: stringOKEmpty,
  constant: constant,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String stringOKEmpty, Constant constant),
  Message Function({required String stringOKEmpty, required Constant constant})
>
codeConstEvalInvalidRecordIndexGet = const Template(
  "ConstEvalInvalidRecordIndexGet",
  problemMessageTemplate:
      r"""The property '#stringOKEmpty' can't be accessed on '#constant' in a constant expression.""",
  withArgumentsOld: _withArgumentsOldConstEvalInvalidRecordIndexGet,
  withArguments: _withArgumentsConstEvalInvalidRecordIndexGet,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalInvalidRecordIndexGet({
  required String stringOKEmpty,
  required Constant constant,
}) {
  var stringOKEmpty_0 = conversions.stringOrEmpty(stringOKEmpty);
  TypeLabeler labeler = new TypeLabeler();
  var constant_0 = labeler.labelConstant(constant);
  return new Message(
    codeConstEvalInvalidRecordIndexGet,
    problemMessage:
        """The property '${stringOKEmpty_0}' can't be accessed on '${constant_0}' in a constant expression.""" +
        labeler.originMessages,
    arguments: {'stringOKEmpty': stringOKEmpty, 'constant': constant},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConstEvalInvalidRecordIndexGet(
  String stringOKEmpty,
  Constant constant,
) => _withArgumentsConstEvalInvalidRecordIndexGet(
  stringOKEmpty: stringOKEmpty,
  constant: constant,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String stringOKEmpty, Constant constant),
  Message Function({required String stringOKEmpty, required Constant constant})
>
codeConstEvalInvalidRecordNameGet = const Template(
  "ConstEvalInvalidRecordNameGet",
  problemMessageTemplate:
      r"""The property '#stringOKEmpty' can't be accessed on '#constant' in a constant expression.""",
  withArgumentsOld: _withArgumentsOldConstEvalInvalidRecordNameGet,
  withArguments: _withArgumentsConstEvalInvalidRecordNameGet,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalInvalidRecordNameGet({
  required String stringOKEmpty,
  required Constant constant,
}) {
  var stringOKEmpty_0 = conversions.stringOrEmpty(stringOKEmpty);
  TypeLabeler labeler = new TypeLabeler();
  var constant_0 = labeler.labelConstant(constant);
  return new Message(
    codeConstEvalInvalidRecordNameGet,
    problemMessage:
        """The property '${stringOKEmpty_0}' can't be accessed on '${constant_0}' in a constant expression.""" +
        labeler.originMessages,
    arguments: {'stringOKEmpty': stringOKEmpty, 'constant': constant},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConstEvalInvalidRecordNameGet(
  String stringOKEmpty,
  Constant constant,
) => _withArgumentsConstEvalInvalidRecordNameGet(
  stringOKEmpty: stringOKEmpty,
  constant: constant,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String nameOKEmpty),
  Message Function({required String nameOKEmpty})
>
codeConstEvalInvalidStaticInvocation = const Template(
  "ConstEvalInvalidStaticInvocation",
  problemMessageTemplate:
      r"""The invocation of '#nameOKEmpty' is not allowed in a constant expression.""",
  withArgumentsOld: _withArgumentsOldConstEvalInvalidStaticInvocation,
  withArguments: _withArgumentsConstEvalInvalidStaticInvocation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalInvalidStaticInvocation({
  required String nameOKEmpty,
}) {
  var nameOKEmpty_0 = conversions.nameOrUnnamed(nameOKEmpty);
  return new Message(
    codeConstEvalInvalidStaticInvocation,
    problemMessage:
        """The invocation of '${nameOKEmpty_0}' is not allowed in a constant expression.""",
    arguments: {'nameOKEmpty': nameOKEmpty},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConstEvalInvalidStaticInvocation(String nameOKEmpty) =>
    _withArgumentsConstEvalInvalidStaticInvocation(nameOKEmpty: nameOKEmpty);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Constant constant),
  Message Function({required Constant constant})
>
codeConstEvalInvalidStringInterpolationOperand = const Template(
  "ConstEvalInvalidStringInterpolationOperand",
  problemMessageTemplate:
      r"""The constant value '#constant' can't be used as part of a string interpolation in a constant expression.
Only values of type 'null', 'bool', 'int', 'double', or 'String' can be used.""",
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
    codeConstEvalInvalidStringInterpolationOperand,
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
  Message Function(Constant constant),
  Message Function({required Constant constant})
>
codeConstEvalInvalidSymbolName = const Template(
  "ConstEvalInvalidSymbolName",
  problemMessageTemplate:
      r"""The symbol name must be a valid public Dart member name, public constructor name, or library name, optionally qualified, but was '#constant'.""",
  withArgumentsOld: _withArgumentsOldConstEvalInvalidSymbolName,
  withArguments: _withArgumentsConstEvalInvalidSymbolName,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalInvalidSymbolName({required Constant constant}) {
  TypeLabeler labeler = new TypeLabeler();
  var constant_0 = labeler.labelConstant(constant);
  return new Message(
    codeConstEvalInvalidSymbolName,
    problemMessage:
        """The symbol name must be a valid public Dart member name, public constructor name, or library name, optionally qualified, but was '${constant_0}'.""" +
        labeler.originMessages,
    arguments: {'constant': constant},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConstEvalInvalidSymbolName(Constant constant) =>
    _withArgumentsConstEvalInvalidSymbolName(constant: constant);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Constant constant, DartType type, DartType type2),
  Message Function({
    required Constant constant,
    required DartType type,
    required DartType type2,
  })
>
codeConstEvalInvalidType = const Template(
  "ConstEvalInvalidType",
  problemMessageTemplate:
      r"""Expected constant '#constant' to be of type '#type', but was of type '#type2'.""",
  withArgumentsOld: _withArgumentsOldConstEvalInvalidType,
  withArguments: _withArgumentsConstEvalInvalidType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalInvalidType({
  required Constant constant,
  required DartType type,
  required DartType type2,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var constant_0 = labeler.labelConstant(constant);
  var type_0 = labeler.labelType(type);
  var type2_0 = labeler.labelType(type2);
  return new Message(
    codeConstEvalInvalidType,
    problemMessage:
        """Expected constant '${constant_0}' to be of type '${type_0}', but was of type '${type2_0}'.""" +
        labeler.originMessages,
    arguments: {'constant': constant, 'type': type, 'type2': type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConstEvalInvalidType(
  Constant constant,
  DartType type,
  DartType type2,
) => _withArgumentsConstEvalInvalidType(
  constant: constant,
  type: type,
  type2: type2,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Constant constant),
  Message Function({required Constant constant})
>
codeConstEvalKeyImplementsEqual = const Template(
  "ConstEvalKeyImplementsEqual",
  problemMessageTemplate:
      r"""The key '#constant' does not have a primitive operator '=='.""",
  withArgumentsOld: _withArgumentsOldConstEvalKeyImplementsEqual,
  withArguments: _withArgumentsConstEvalKeyImplementsEqual,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalKeyImplementsEqual({
  required Constant constant,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var constant_0 = labeler.labelConstant(constant);
  return new Message(
    codeConstEvalKeyImplementsEqual,
    problemMessage:
        """The key '${constant_0}' does not have a primitive operator '=='.""" +
        labeler.originMessages,
    arguments: {'constant': constant},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConstEvalKeyImplementsEqual(Constant constant) =>
    _withArgumentsConstEvalKeyImplementsEqual(constant: constant);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Constant constant),
  Message Function({required Constant constant})
>
codeConstEvalKeyNotPrimitiveEquality = const Template(
  "ConstEvalKeyNotPrimitiveEquality",
  problemMessageTemplate:
      r"""The key '#constant' does not have a primitive equality.""",
  withArgumentsOld: _withArgumentsOldConstEvalKeyNotPrimitiveEquality,
  withArguments: _withArgumentsConstEvalKeyNotPrimitiveEquality,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalKeyNotPrimitiveEquality({
  required Constant constant,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var constant_0 = labeler.labelConstant(constant);
  return new Message(
    codeConstEvalKeyNotPrimitiveEquality,
    problemMessage:
        """The key '${constant_0}' does not have a primitive equality.""" +
        labeler.originMessages,
    arguments: {'constant': constant},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConstEvalKeyNotPrimitiveEquality(Constant constant) =>
    _withArgumentsConstEvalKeyNotPrimitiveEquality(constant: constant);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string, String string2, String string3),
  Message Function({
    required String string,
    required String string2,
    required String string3,
  })
>
codeConstEvalNegativeShift = const Template(
  "ConstEvalNegativeShift",
  problemMessageTemplate:
      r"""Binary operator '#string' on '#string2' requires non-negative operand, but was '#string3'.""",
  withArgumentsOld: _withArgumentsOldConstEvalNegativeShift,
  withArguments: _withArgumentsConstEvalNegativeShift,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalNegativeShift({
  required String string,
  required String string2,
  required String string3,
}) {
  var string_0 = conversions.validateString(string);
  var string2_0 = conversions.validateString(string2);
  var string3_0 = conversions.validateString(string3);
  return new Message(
    codeConstEvalNegativeShift,
    problemMessage:
        """Binary operator '${string_0}' on '${string2_0}' requires non-negative operand, but was '${string3_0}'.""",
    arguments: {'string': string, 'string2': string2, 'string3': string3},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConstEvalNegativeShift(
  String string,
  String string2,
  String string3,
) => _withArgumentsConstEvalNegativeShift(
  string: string,
  string2: string2,
  string3: string3,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String nameOKEmpty),
  Message Function({required String nameOKEmpty})
>
codeConstEvalNonConstantVariableGet = const Template(
  "ConstEvalNonConstantVariableGet",
  problemMessageTemplate:
      r"""The variable '#nameOKEmpty' is not a constant, only constant expressions are allowed.""",
  withArgumentsOld: _withArgumentsOldConstEvalNonConstantVariableGet,
  withArguments: _withArgumentsConstEvalNonConstantVariableGet,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalNonConstantVariableGet({
  required String nameOKEmpty,
}) {
  var nameOKEmpty_0 = conversions.nameOrUnnamed(nameOKEmpty);
  return new Message(
    codeConstEvalNonConstantVariableGet,
    problemMessage:
        """The variable '${nameOKEmpty_0}' is not a constant, only constant expressions are allowed.""",
    arguments: {'nameOKEmpty': nameOKEmpty},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConstEvalNonConstantVariableGet(String nameOKEmpty) =>
    _withArgumentsConstEvalNonConstantVariableGet(nameOKEmpty: nameOKEmpty);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeConstEvalNonNull = const MessageCode(
  "ConstEvalNonNull",
  problemMessage: r"""Constant expression must be non-null.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeConstEvalNotListOrSetInSpread = const MessageCode(
  "ConstEvalNotListOrSetInSpread",
  problemMessage:
      r"""Only lists and sets can be used in spreads in constant lists and sets.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeConstEvalNotMapInSpread = const MessageCode(
  "ConstEvalNotMapInSpread",
  problemMessage: r"""Only maps can be used in spreads in constant maps.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeConstEvalNullValue = const MessageCode(
  "ConstEvalNullValue",
  problemMessage: r"""Null value during constant evaluation.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeConstEvalStartingPoint = const MessageCode(
  "ConstEvalStartingPoint",
  problemMessage: r"""Constant evaluation error:""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string, String string2),
  Message Function({required String string, required String string2})
>
codeConstEvalTruncateError = const Template(
  "ConstEvalTruncateError",
  problemMessageTemplate:
      r"""Binary operator '#string ~/ #string2' results is Infinity or NaN.""",
  withArgumentsOld: _withArgumentsOldConstEvalTruncateError,
  withArguments: _withArgumentsConstEvalTruncateError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalTruncateError({
  required String string,
  required String string2,
}) {
  var string_0 = conversions.validateString(string);
  var string2_0 = conversions.validateString(string2);
  return new Message(
    codeConstEvalTruncateError,
    problemMessage:
        """Binary operator '${string_0} ~/ ${string2_0}' results is Infinity or NaN.""",
    arguments: {'string': string, 'string2': string2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConstEvalTruncateError(
  String string,
  String string2,
) => _withArgumentsConstEvalTruncateError(string: string, string2: string2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeConstEvalUnevaluated = const MessageCode(
  "ConstEvalUnevaluated",
  problemMessage: r"""Couldn't evaluate constant expression.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String stringOKEmpty),
  Message Function({required String stringOKEmpty})
>
codeConstEvalUnhandledCoreException = const Template(
  "ConstEvalUnhandledCoreException",
  problemMessageTemplate: r"""Unhandled core exception: #stringOKEmpty""",
  withArgumentsOld: _withArgumentsOldConstEvalUnhandledCoreException,
  withArguments: _withArgumentsConstEvalUnhandledCoreException,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalUnhandledCoreException({
  required String stringOKEmpty,
}) {
  var stringOKEmpty_0 = conversions.stringOrEmpty(stringOKEmpty);
  return new Message(
    codeConstEvalUnhandledCoreException,
    problemMessage: """Unhandled core exception: ${stringOKEmpty_0}""",
    arguments: {'stringOKEmpty': stringOKEmpty},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConstEvalUnhandledCoreException(
  String stringOKEmpty,
) =>
    _withArgumentsConstEvalUnhandledCoreException(stringOKEmpty: stringOKEmpty);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Constant constant),
  Message Function({required Constant constant})
>
codeConstEvalUnhandledException = const Template(
  "ConstEvalUnhandledException",
  problemMessageTemplate: r"""Unhandled exception: #constant""",
  withArgumentsOld: _withArgumentsOldConstEvalUnhandledException,
  withArguments: _withArgumentsConstEvalUnhandledException,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalUnhandledException({
  required Constant constant,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var constant_0 = labeler.labelConstant(constant);
  return new Message(
    codeConstEvalUnhandledException,
    problemMessage:
        """Unhandled exception: ${constant_0}""" + labeler.originMessages,
    arguments: {'constant': constant},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConstEvalUnhandledException(Constant constant) =>
    _withArgumentsConstEvalUnhandledException(constant: constant);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string, String string2),
  Message Function({required String string, required String string2})
>
codeConstEvalZeroDivisor = const Template(
  "ConstEvalZeroDivisor",
  problemMessageTemplate:
      r"""Binary operator '#string' on '#string2' requires non-zero divisor, but divisor was '0'.""",
  withArgumentsOld: _withArgumentsOldConstEvalZeroDivisor,
  withArguments: _withArgumentsConstEvalZeroDivisor,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalZeroDivisor({
  required String string,
  required String string2,
}) {
  var string_0 = conversions.validateString(string);
  var string2_0 = conversions.validateString(string2);
  return new Message(
    codeConstEvalZeroDivisor,
    problemMessage:
        """Binary operator '${string_0}' on '${string2_0}' requires non-zero divisor, but divisor was '0'.""",
    arguments: {'string': string, 'string2': string2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConstEvalZeroDivisor(String string, String string2) =>
    _withArgumentsConstEvalZeroDivisor(string: string, string2: string2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeConstFactoryRedirectionToNonConst = const MessageCode(
  "ConstFactoryRedirectionToNonConst",
  problemMessage:
      r"""Constant factory constructor can't delegate to a non-constant constructor.""",
  correctionMessage:
      r"""Try redirecting to a different constructor or marking the target constructor 'const'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeConstInstanceField = const MessageCode(
  "ConstInstanceField",
  problemMessage: r"""Only static fields can be declared as const.""",
  correctionMessage:
      r"""Try using 'final' instead of 'const', or adding the keyword 'static'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeConstructorConflictsWithMember = const Template(
  "ConstructorConflictsWithMember",
  problemMessageTemplate: r"""The constructor conflicts with member '#name'.""",
  withArgumentsOld: _withArgumentsOldConstructorConflictsWithMember,
  withArguments: _withArgumentsConstructorConflictsWithMember,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstructorConflictsWithMember({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeConstructorConflictsWithMember,
    problemMessage: """The constructor conflicts with member '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConstructorConflictsWithMember(String name) =>
    _withArgumentsConstructorConflictsWithMember(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeConstructorConflictsWithMemberCause = const Template(
  "ConstructorConflictsWithMemberCause",
  problemMessageTemplate: r"""Conflicting member '#name'.""",
  withArgumentsOld: _withArgumentsOldConstructorConflictsWithMemberCause,
  withArguments: _withArgumentsConstructorConflictsWithMemberCause,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstructorConflictsWithMemberCause({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeConstructorConflictsWithMemberCause,
    problemMessage: """Conflicting member '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConstructorConflictsWithMemberCause(String name) =>
    _withArgumentsConstructorConflictsWithMemberCause(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeConstructorCyclic = const MessageCode(
  "ConstructorCyclic",
  problemMessage: r"""Redirecting constructors can't be cyclic.""",
  correctionMessage:
      r"""Try to have all constructors eventually redirect to a non-redirecting constructor.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeConstructorInitializeSameInstanceVariableSeveralTimes = const Template(
  "ConstructorInitializeSameInstanceVariableSeveralTimes",
  problemMessageTemplate:
      r"""'#name' was already initialized by this constructor.""",
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
    codeConstructorInitializeSameInstanceVariableSeveralTimes,
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
codeConstructorNotFound = const Template(
  "ConstructorNotFound",
  problemMessageTemplate: r"""Couldn't find constructor '#name'.""",
  withArgumentsOld: _withArgumentsOldConstructorNotFound,
  withArguments: _withArgumentsConstructorNotFound,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstructorNotFound({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeConstructorNotFound,
    problemMessage: """Couldn't find constructor '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConstructorNotFound(String name) =>
    _withArgumentsConstructorNotFound(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeConstructorNotSync = const MessageCode(
  "ConstructorNotSync",
  problemMessage:
      r"""Constructor bodies can't use 'async', 'async*', or 'sync*'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeConstructorShouldBeListedAsCallableInDynamicInterface = const Template(
  "ConstructorShouldBeListedAsCallableInDynamicInterface",
  problemMessageTemplate:
      r"""Cannot invoke constructor '#name' from a dynamic module.""",
  correctionMessageTemplate:
      r"""Try removing the call or update the dynamic interface to list constructor '#name' as callable.""",
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
    codeConstructorShouldBeListedAsCallableInDynamicInterface,
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
const MessageCode codeConstructorTearOffWithTypeArguments = const MessageCode(
  "ConstructorTearOffWithTypeArguments",
  problemMessage:
      r"""A constructor tear-off can't have type arguments after the constructor name.""",
  correctionMessage:
      r"""Try removing the type arguments or placing them after the class name.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeConstructorWithWrongNameContext = const Template(
  "ConstructorWithWrongNameContext",
  problemMessageTemplate: r"""The name of the enclosing class is '#name'.""",
  withArgumentsOld: _withArgumentsOldConstructorWithWrongNameContext,
  withArguments: _withArgumentsConstructorWithWrongNameContext,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstructorWithWrongNameContext({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeConstructorWithWrongNameContext,
    problemMessage: """The name of the enclosing class is '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConstructorWithWrongNameContext(String name) =>
    _withArgumentsConstructorWithWrongNameContext(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeContinueLabelInvalid = const MessageCode(
  "ContinueLabelInvalid",
  problemMessage:
      r"""A 'continue' label must be on a loop or a switch member.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeContinueTargetOutsideFunction = const Template(
  "ContinueTargetOutsideFunction",
  problemMessageTemplate:
      r"""Can't continue at '#name' in a different function.""",
  withArgumentsOld: _withArgumentsOldContinueTargetOutsideFunction,
  withArguments: _withArgumentsContinueTargetOutsideFunction,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsContinueTargetOutsideFunction({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeContinueTargetOutsideFunction,
    problemMessage:
        """Can't continue at '${name_0}' in a different function.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldContinueTargetOutsideFunction(String name) =>
    _withArgumentsContinueTargetOutsideFunction(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string, String string2),
  Message Function({required String string, required String string2})
>
codeCouldNotParseUri = const Template(
  "CouldNotParseUri",
  problemMessageTemplate: r"""Couldn't parse URI '#string':
  #string2.""",
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
    codeCouldNotParseUri,
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
codeCycleInTypeParameters = const Template(
  "CycleInTypeParameters",
  problemMessageTemplate:
      r"""Type '#name' is a bound of itself via '#string'.""",
  correctionMessageTemplate:
      r"""Try breaking the cycle by removing at least one of the 'extends' clauses in the cycle.""",
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
    codeCycleInTypeParameters,
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
  Message Function(String name),
  Message Function({required String name})
>
codeCyclicClassHierarchy = const Template(
  "CyclicClassHierarchy",
  problemMessageTemplate: r"""'#name' is a supertype of itself.""",
  withArgumentsOld: _withArgumentsOldCyclicClassHierarchy,
  withArguments: _withArgumentsCyclicClassHierarchy,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCyclicClassHierarchy({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeCyclicClassHierarchy,
    problemMessage: """'${name_0}' is a supertype of itself.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldCyclicClassHierarchy(String name) =>
    _withArgumentsCyclicClassHierarchy(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeCyclicRedirectingFactoryConstructors = const Template(
  "CyclicRedirectingFactoryConstructors",
  problemMessageTemplate: r"""Cyclic definition of factory '#name'.""",
  withArgumentsOld: _withArgumentsOldCyclicRedirectingFactoryConstructors,
  withArguments: _withArgumentsCyclicRedirectingFactoryConstructors,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCyclicRedirectingFactoryConstructors({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeCyclicRedirectingFactoryConstructors,
    problemMessage: """Cyclic definition of factory '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldCyclicRedirectingFactoryConstructors(String name) =>
    _withArgumentsCyclicRedirectingFactoryConstructors(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeCyclicRepresentationDependency = const MessageCode(
  "CyclicRepresentationDependency",
  problemMessage:
      r"""An extension type can't depend on itself through its representation type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeCyclicTypedef = const Template(
  "CyclicTypedef",
  problemMessageTemplate: r"""The typedef '#name' has a reference to itself.""",
  withArgumentsOld: _withArgumentsOldCyclicTypedef,
  withArguments: _withArgumentsCyclicTypedef,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCyclicTypedef({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeCyclicTypedef,
    problemMessage: """The typedef '${name_0}' has a reference to itself.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldCyclicTypedef(String name) =>
    _withArgumentsCyclicTypedef(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeDartFfiLibraryInDart2Wasm = const MessageCode(
  "DartFfiLibraryInDart2Wasm",
  problemMessage: r"""'dart:ffi' can't be imported when compiling to Wasm.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, String string),
  Message Function({required String name, required String string})
>
codeDebugTrace = const Template(
  "DebugTrace",
  problemMessageTemplate: r"""Fatal '#name' at:
#string""",
  withArgumentsOld: _withArgumentsOldDebugTrace,
  withArguments: _withArgumentsDebugTrace,
  severity: CfeSeverity.ignored,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDebugTrace({
  required String name,
  required String string,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var string_0 = conversions.validateString(string);
  return new Message(
    codeDebugTrace,
    problemMessage: """Fatal '${name_0}' at:
${string_0}""",
    arguments: {'name': name, 'string': string},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldDebugTrace(String name, String string) =>
    _withArgumentsDebugTrace(name: name, string: string);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeDeclarationConflictsWithSetter = const Template(
  "DeclarationConflictsWithSetter",
  problemMessageTemplate: r"""The declaration conflicts with setter '#name'.""",
  withArgumentsOld: _withArgumentsOldDeclarationConflictsWithSetter,
  withArguments: _withArgumentsDeclarationConflictsWithSetter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDeclarationConflictsWithSetter({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeDeclarationConflictsWithSetter,
    problemMessage: """The declaration conflicts with setter '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldDeclarationConflictsWithSetter(String name) =>
    _withArgumentsDeclarationConflictsWithSetter(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeDeclarationConflictsWithSetterCause = const Template(
  "DeclarationConflictsWithSetterCause",
  problemMessageTemplate: r"""Conflicting setter '#name'.""",
  withArgumentsOld: _withArgumentsOldDeclarationConflictsWithSetterCause,
  withArguments: _withArgumentsDeclarationConflictsWithSetterCause,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDeclarationConflictsWithSetterCause({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeDeclarationConflictsWithSetterCause,
    problemMessage: """Conflicting setter '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldDeclarationConflictsWithSetterCause(String name) =>
    _withArgumentsDeclarationConflictsWithSetterCause(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeDeclaredMemberConflictsWithInheritedMember =
    const MessageCode(
      "DeclaredMemberConflictsWithInheritedMember",
      problemMessage:
          r"""Can't declare a member that conflicts with an inherited one.""",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeDeclaredMemberConflictsWithInheritedMemberCause =
    const MessageCode(
      "DeclaredMemberConflictsWithInheritedMemberCause",
      severity: CfeSeverity.context,
      problemMessage: r"""This is the inherited member.""",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeDeclaredMemberConflictsWithInheritedMembersCause =
    const MessageCode(
      "DeclaredMemberConflictsWithInheritedMembersCause",
      severity: CfeSeverity.context,
      problemMessage: r"""This is one of the inherited members.""",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeDeclaredMemberConflictsWithOverriddenMembersCause =
    const MessageCode(
      "DeclaredMemberConflictsWithOverriddenMembersCause",
      severity: CfeSeverity.context,
      problemMessage: r"""This is one of the overridden members.""",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeDefaultValueInRedirectingFactoryConstructor = const Template(
  "DefaultValueInRedirectingFactoryConstructor",
  problemMessageTemplate:
      r"""Can't have a default value here because any default values of '#name' would be used instead.""",
  correctionMessageTemplate: r"""Try removing the default value.""",
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
    codeDefaultValueInRedirectingFactoryConstructor,
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
codeDeferredExtensionImport = const Template(
  "DeferredExtensionImport",
  problemMessageTemplate:
      r"""Extension '#name' cannot be imported through a deferred import.""",
  correctionMessageTemplate: r"""Try adding the `hide #name` to the import.""",
  withArgumentsOld: _withArgumentsOldDeferredExtensionImport,
  withArguments: _withArgumentsDeferredExtensionImport,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDeferredExtensionImport({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeDeferredExtensionImport,
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
  Message Function(String name),
  Message Function({required String name})
>
codeDeferredPrefixDuplicated = const Template(
  "DeferredPrefixDuplicated",
  problemMessageTemplate:
      r"""Can't use the name '#name' for a deferred library, as the name is used elsewhere.""",
  withArgumentsOld: _withArgumentsOldDeferredPrefixDuplicated,
  withArguments: _withArgumentsDeferredPrefixDuplicated,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDeferredPrefixDuplicated({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeDeferredPrefixDuplicated,
    problemMessage:
        """Can't use the name '${name_0}' for a deferred library, as the name is used elsewhere.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldDeferredPrefixDuplicated(String name) =>
    _withArgumentsDeferredPrefixDuplicated(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeDeferredPrefixDuplicatedCause = const Template(
  "DeferredPrefixDuplicatedCause",
  problemMessageTemplate: r"""'#name' is used here.""",
  withArgumentsOld: _withArgumentsOldDeferredPrefixDuplicatedCause,
  withArguments: _withArgumentsDeferredPrefixDuplicatedCause,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDeferredPrefixDuplicatedCause({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeDeferredPrefixDuplicatedCause,
    problemMessage: """'${name_0}' is used here.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldDeferredPrefixDuplicatedCause(String name) =>
    _withArgumentsDeferredPrefixDuplicatedCause(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type, String name),
  Message Function({required DartType type, required String name})
>
codeDeferredTypeAnnotation = const Template(
  "DeferredTypeAnnotation",
  problemMessageTemplate:
      r"""The type '#type' is deferred loaded via prefix '#name' and can't be used as a type annotation.""",
  correctionMessageTemplate:
      r"""Try removing 'deferred' from the import of '#name' or use a supertype of '#type' that isn't deferred.""",
  withArgumentsOld: _withArgumentsOldDeferredTypeAnnotation,
  withArguments: _withArgumentsDeferredTypeAnnotation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDeferredTypeAnnotation({
  required DartType type,
  required String name,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeDeferredTypeAnnotation,
    problemMessage:
        """The type '${type_0}' is deferred loaded via prefix '${name_0}' and can't be used as a type annotation.""" +
        labeler.originMessages,
    correctionMessage:
        """Try removing 'deferred' from the import of '${name_0}' or use a supertype of '${type_0}' that isn't deferred.""",
    arguments: {'type': type, 'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldDeferredTypeAnnotation(DartType type, String name) =>
    _withArgumentsDeferredTypeAnnotation(type: type, name: name);

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
codeDillOutlineSummary = const Template(
  "DillOutlineSummary",
  problemMessageTemplate:
      r"""Indexed #count libraries (#count2 bytes) in #num1%.3ms, that is,
#num2%12.3 bytes/ms, and
#num3%12.3 ms/libraries.""",
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
    codeDillOutlineSummary,
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
codeDirectCycleInTypeParameters = const Template(
  "DirectCycleInTypeParameters",
  problemMessageTemplate: r"""Type '#name' can't use itself as a bound.""",
  correctionMessageTemplate:
      r"""Try breaking the cycle by removing at least one of the 'extends' clauses in the cycle.""",
  withArgumentsOld: _withArgumentsOldDirectCycleInTypeParameters,
  withArguments: _withArgumentsDirectCycleInTypeParameters,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDirectCycleInTypeParameters({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeDirectCycleInTypeParameters,
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
codeDotShorthandsConstructorInvocationWithTypeArguments = const MessageCode(
  "DotShorthandsConstructorInvocationWithTypeArguments",
  problemMessage:
      r"""A dot shorthand constructor invocation can't have type arguments.""",
  correctionMessage:
      r"""Try adding the class name and type arguments explicitly before the constructor name.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeDotShorthandsInvalidContext = const Template(
  "DotShorthandsInvalidContext",
  problemMessageTemplate:
      r"""No type was provided to find the dot shorthand '#name'.""",
  withArgumentsOld: _withArgumentsOldDotShorthandsInvalidContext,
  withArguments: _withArgumentsDotShorthandsInvalidContext,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDotShorthandsInvalidContext({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeDotShorthandsInvalidContext,
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
codeDotShorthandsUndefinedGetter = const Template(
  "DotShorthandsUndefinedGetter",
  problemMessageTemplate:
      r"""The static getter or field '#name' isn't defined for the type '#type'.""",
  correctionMessageTemplate:
      r"""Try correcting the name to the name of an existing static getter or field, or defining a getter or field named '#name'.""",
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
    codeDotShorthandsUndefinedGetter,
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
codeDotShorthandsUndefinedInvocation = const Template(
  "DotShorthandsUndefinedInvocation",
  problemMessageTemplate:
      r"""The static method or constructor '#name' isn't defined for the type '#type'.""",
  correctionMessageTemplate:
      r"""Try correcting the name to the name of an existing static method or constructor, or defining a static method or constructor named '#name'.""",
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
    codeDotShorthandsUndefinedInvocation,
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
codeDuplicatePatternAssignmentVariable = const Template(
  "DuplicatePatternAssignmentVariable",
  problemMessageTemplate:
      r"""The variable '#name' is already assigned in this pattern.""",
  correctionMessageTemplate: r"""Try renaming the variable.""",
  withArgumentsOld: _withArgumentsOldDuplicatePatternAssignmentVariable,
  withArguments: _withArgumentsDuplicatePatternAssignmentVariable,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatePatternAssignmentVariable({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeDuplicatePatternAssignmentVariable,
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
const MessageCode codeDuplicatePatternAssignmentVariableContext =
    const MessageCode(
      "DuplicatePatternAssignmentVariableContext",
      severity: CfeSeverity.context,
      problemMessage: r"""The first assigned variable pattern.""",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeDuplicateRecordPatternField = const Template(
  "DuplicateRecordPatternField",
  problemMessageTemplate:
      r"""The field '#name' is already matched in this pattern.""",
  correctionMessageTemplate: r"""Try removing the duplicate field.""",
  withArgumentsOld: _withArgumentsOldDuplicateRecordPatternField,
  withArguments: _withArgumentsDuplicateRecordPatternField,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicateRecordPatternField({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeDuplicateRecordPatternField,
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
const MessageCode codeDuplicateRecordPatternFieldContext = const MessageCode(
  "DuplicateRecordPatternFieldContext",
  severity: CfeSeverity.context,
  problemMessage: r"""The first field.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeDuplicateRestElementInPattern = const MessageCode(
  "DuplicateRestElementInPattern",
  problemMessage:
      r"""At most one rest element is allowed in a list or map pattern.""",
  correctionMessage: r"""Try removing the duplicate rest element.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeDuplicateRestElementInPatternContext = const MessageCode(
  "DuplicateRestElementInPatternContext",
  severity: CfeSeverity.context,
  problemMessage: r"""The first rest element.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeDuplicatedDeclaration = const Template(
  "DuplicatedDeclaration",
  problemMessageTemplate: r"""'#name' is already declared in this scope.""",
  withArgumentsOld: _withArgumentsOldDuplicatedDeclaration,
  withArguments: _withArgumentsDuplicatedDeclaration,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedDeclaration({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeDuplicatedDeclaration,
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
codeDuplicatedDeclarationCause = const Template(
  "DuplicatedDeclarationCause",
  problemMessageTemplate: r"""Previous declaration of '#name'.""",
  withArgumentsOld: _withArgumentsOldDuplicatedDeclarationCause,
  withArguments: _withArgumentsDuplicatedDeclarationCause,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedDeclarationCause({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeDuplicatedDeclarationCause,
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
codeDuplicatedDeclarationSyntheticCause = const Template(
  "DuplicatedDeclarationSyntheticCause",
  problemMessageTemplate:
      r"""Previous declaration of '#name' is implied by this definition.""",
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
    codeDuplicatedDeclarationSyntheticCause,
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
codeDuplicatedDeclarationUse = const Template(
  "DuplicatedDeclarationUse",
  problemMessageTemplate:
      r"""Can't use '#name' because it is declared more than once.""",
  withArgumentsOld: _withArgumentsOldDuplicatedDeclarationUse,
  withArguments: _withArgumentsDuplicatedDeclarationUse,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedDeclarationUse({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeDuplicatedDeclarationUse,
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
codeDuplicatedExport = const Template(
  "DuplicatedExport",
  problemMessageTemplate:
      r"""'#name' is exported from both '#uri' and '#uri2'.""",
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
    codeDuplicatedExport,
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
codeDuplicatedImport = const Template(
  "DuplicatedImport",
  problemMessageTemplate:
      r"""'#name' is imported from both '#uri' and '#uri2'.""",
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
    codeDuplicatedImport,
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
codeDuplicatedNamedArgument = const Template(
  "DuplicatedNamedArgument",
  problemMessageTemplate: r"""Duplicated named argument '#name'.""",
  withArgumentsOld: _withArgumentsOldDuplicatedNamedArgument,
  withArguments: _withArgumentsDuplicatedNamedArgument,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedNamedArgument({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeDuplicatedNamedArgument,
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
codeDuplicatedParameterName = const Template(
  "DuplicatedParameterName",
  problemMessageTemplate: r"""Duplicated parameter name '#name'.""",
  withArgumentsOld: _withArgumentsOldDuplicatedParameterName,
  withArguments: _withArgumentsDuplicatedParameterName,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedParameterName({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeDuplicatedParameterName,
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
codeDuplicatedParameterNameCause = const Template(
  "DuplicatedParameterNameCause",
  problemMessageTemplate: r"""Other parameter named '#name'.""",
  withArgumentsOld: _withArgumentsOldDuplicatedParameterNameCause,
  withArguments: _withArgumentsDuplicatedParameterNameCause,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedParameterNameCause({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeDuplicatedParameterNameCause,
    problemMessage: """Other parameter named '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldDuplicatedParameterNameCause(String name) =>
    _withArgumentsDuplicatedParameterNameCause(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeDuplicatedRecordLiteralFieldName = const Template(
  "DuplicatedRecordLiteralFieldName",
  problemMessageTemplate: r"""Duplicated record literal field name '#name'.""",
  correctionMessageTemplate:
      r"""Try renaming or removing one of the named record literal fields.""",
  withArgumentsOld: _withArgumentsOldDuplicatedRecordLiteralFieldName,
  withArguments: _withArgumentsDuplicatedRecordLiteralFieldName,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedRecordLiteralFieldName({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeDuplicatedRecordLiteralFieldName,
    problemMessage: """Duplicated record literal field name '${name_0}'.""",
    correctionMessage:
        """Try renaming or removing one of the named record literal fields.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldDuplicatedRecordLiteralFieldName(String name) =>
    _withArgumentsDuplicatedRecordLiteralFieldName(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeDuplicatedRecordLiteralFieldNameContext = const Template(
  "DuplicatedRecordLiteralFieldNameContext",
  problemMessageTemplate:
      r"""This is the existing record literal field named '#name'.""",
  withArgumentsOld: _withArgumentsOldDuplicatedRecordLiteralFieldNameContext,
  withArguments: _withArgumentsDuplicatedRecordLiteralFieldNameContext,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedRecordLiteralFieldNameContext({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeDuplicatedRecordLiteralFieldNameContext,
    problemMessage:
        """This is the existing record literal field named '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldDuplicatedRecordLiteralFieldNameContext(String name) =>
    _withArgumentsDuplicatedRecordLiteralFieldNameContext(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeDuplicatedRecordTypeFieldName = const Template(
  "DuplicatedRecordTypeFieldName",
  problemMessageTemplate: r"""Duplicated record type field name '#name'.""",
  correctionMessageTemplate:
      r"""Try renaming or removing one of the named record type fields.""",
  withArgumentsOld: _withArgumentsOldDuplicatedRecordTypeFieldName,
  withArguments: _withArgumentsDuplicatedRecordTypeFieldName,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedRecordTypeFieldName({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeDuplicatedRecordTypeFieldName,
    problemMessage: """Duplicated record type field name '${name_0}'.""",
    correctionMessage:
        """Try renaming or removing one of the named record type fields.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldDuplicatedRecordTypeFieldName(String name) =>
    _withArgumentsDuplicatedRecordTypeFieldName(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeDuplicatedRecordTypeFieldNameContext = const Template(
  "DuplicatedRecordTypeFieldNameContext",
  problemMessageTemplate:
      r"""This is the existing record type field named '#name'.""",
  withArgumentsOld: _withArgumentsOldDuplicatedRecordTypeFieldNameContext,
  withArguments: _withArgumentsDuplicatedRecordTypeFieldNameContext,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedRecordTypeFieldNameContext({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeDuplicatedRecordTypeFieldNameContext,
    problemMessage:
        """This is the existing record type field named '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldDuplicatedRecordTypeFieldNameContext(String name) =>
    _withArgumentsDuplicatedRecordTypeFieldNameContext(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeDynamicCallsAreNotAllowedInDynamicModule =
    const MessageCode(
      "DynamicCallsAreNotAllowedInDynamicModule",
      problemMessage: r"""Dynamic calls are not allowed in a dynamic module.""",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeEmptyMapPattern = const MessageCode(
  "EmptyMapPattern",
  problemMessage: r"""A map pattern must have at least one entry.""",
  correctionMessage: r"""Try replacing it with an object pattern 'Map()'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeEnumAbstractMember = const MessageCode(
  "EnumAbstractMember",
  problemMessage: r"""Enums can't declare abstract members.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeEnumConstructorSuperInitializer = const MessageCode(
  "EnumConstructorSuperInitializer",
  problemMessage: r"""Enum constructors can't contain super-initializers.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeEnumConstructorTearoff = const MessageCode(
  "EnumConstructorTearoff",
  problemMessage: r"""Enum constructors can't be torn off.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeEnumContainsRestrictedInstanceDeclaration = const Template(
  "EnumContainsRestrictedInstanceDeclaration",
  problemMessageTemplate:
      r"""An enum can't declare a non-abstract member named '#name'.""",
  withArgumentsOld: _withArgumentsOldEnumContainsRestrictedInstanceDeclaration,
  withArguments: _withArgumentsEnumContainsRestrictedInstanceDeclaration,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsEnumContainsRestrictedInstanceDeclaration({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeEnumContainsRestrictedInstanceDeclaration,
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
const MessageCode codeEnumContainsValuesDeclaration = const MessageCode(
  "EnumContainsValuesDeclaration",
  problemMessage: r"""An enum can't declare a member named 'values'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeEnumDeclarationEmpty = const MessageCode(
  "EnumDeclarationEmpty",
  problemMessage: r"""An enum declaration can't be empty.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeEnumFactoryRedirectsToConstructor = const MessageCode(
  "EnumFactoryRedirectsToConstructor",
  problemMessage:
      r"""Enum factory constructors can't redirect to generative constructors.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, String name2),
  Message Function({required String name, required String name2})
>
codeEnumImplementerContainsRestrictedInstanceDeclaration = const Template(
  "EnumImplementerContainsRestrictedInstanceDeclaration",
  problemMessageTemplate:
      r"""'#name' has 'Enum' as a superinterface and can't contain non-static members with name '#name2'.""",
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
    codeEnumImplementerContainsRestrictedInstanceDeclaration,
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
codeEnumImplementerContainsValuesDeclaration = const Template(
  "EnumImplementerContainsValuesDeclaration",
  problemMessageTemplate:
      r"""'#name' has 'Enum' as a superinterface and can't contain non-static member with name 'values'.""",
  withArgumentsOld: _withArgumentsOldEnumImplementerContainsValuesDeclaration,
  withArguments: _withArgumentsEnumImplementerContainsValuesDeclaration,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsEnumImplementerContainsValuesDeclaration({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeEnumImplementerContainsValuesDeclaration,
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
codeEnumInheritsRestricted = const Template(
  "EnumInheritsRestricted",
  problemMessageTemplate: r"""An enum can't inherit a member named '#name'.""",
  withArgumentsOld: _withArgumentsOldEnumInheritsRestricted,
  withArguments: _withArgumentsEnumInheritsRestricted,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsEnumInheritsRestricted({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeEnumInheritsRestricted,
    problemMessage: """An enum can't inherit a member named '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldEnumInheritsRestricted(String name) =>
    _withArgumentsEnumInheritsRestricted(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeEnumInheritsRestrictedMember = const MessageCode(
  "EnumInheritsRestrictedMember",
  severity: CfeSeverity.context,
  problemMessage: r"""This is the inherited member""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeEnumInstantiation = const MessageCode(
  "EnumInstantiation",
  problemMessage: r"""Enums can't be instantiated.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeEnumNonConstConstructor = const MessageCode(
  "EnumNonConstConstructor",
  problemMessage:
      r"""Generative enum constructors must be marked as 'const'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeEnumSupertypeOfNonAbstractClass = const Template(
  "EnumSupertypeOfNonAbstractClass",
  problemMessageTemplate:
      r"""Non-abstract class '#name' has 'Enum' as a superinterface.""",
  withArgumentsOld: _withArgumentsOldEnumSupertypeOfNonAbstractClass,
  withArguments: _withArgumentsEnumSupertypeOfNonAbstractClass,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsEnumSupertypeOfNonAbstractClass({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeEnumSupertypeOfNonAbstractClass,
    problemMessage:
        """Non-abstract class '${name_0}' has 'Enum' as a superinterface.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldEnumSupertypeOfNonAbstractClass(String name) =>
    _withArgumentsEnumSupertypeOfNonAbstractClass(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeEnumWithNameValues = const MessageCode(
  "EnumWithNameValues",
  problemMessage:
      r"""The name 'values' is not a valid name for an enum. Try using a different name.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeEqualKeysInMapPattern = const MessageCode(
  "EqualKeysInMapPattern",
  problemMessage: r"""Two keys in a map pattern can't be equal.""",
  correctionMessage: r"""Change or remove the duplicate key.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeEqualKeysInMapPatternContext = const MessageCode(
  "EqualKeysInMapPatternContext",
  severity: CfeSeverity.context,
  problemMessage: r"""This is the previous use of the same key.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Uri uri, String string),
  Message Function({required Uri uri, required String string})
>
codeExceptionReadingFile = const Template(
  "ExceptionReadingFile",
  problemMessageTemplate: r"""Exception when reading '#uri': #string""",
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
    codeExceptionReadingFile,
    problemMessage: """Exception when reading '${uri_0}': ${string_0}""",
    arguments: {'uri': uri, 'string': string},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldExceptionReadingFile(Uri uri, String string) =>
    _withArgumentsExceptionReadingFile(uri: uri, string: string);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExpectedBlockToSkip = const MessageCode(
  "ExpectedBlockToSkip",
  problemMessage: r"""Expected a function body or '=>'.""",
  correctionMessage: r"""Try adding {}.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExpectedNamedArgument = const MessageCode(
  "ExpectedNamedArgument",
  problemMessage: r"""Expected named argument.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExpectedOneExpression = const MessageCode(
  "ExpectedOneExpression",
  problemMessage: r"""Expected one expression, but found additional input.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExpectedRepresentationField = const MessageCode(
  "ExpectedRepresentationField",
  problemMessage: r"""Expected a representation field.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExpectedRepresentationType = const MessageCode(
  "ExpectedRepresentationType",
  problemMessage: r"""Expected a representation type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExpectedUri = const MessageCode(
  "ExpectedUri",
  problemMessage: r"""Expected a URI.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string),
  Message Function({required String string})
>
codeExperimentDisabled = const Template(
  "ExperimentDisabled",
  problemMessageTemplate:
      r"""This requires the '#string' language feature to be enabled.""",
  correctionMessageTemplate:
      r"""The feature is on by default but is currently disabled, maybe because the '--enable-experiment=no-#string' command line option is passed.""",
  withArgumentsOld: _withArgumentsOldExperimentDisabled,
  withArguments: _withArgumentsExperimentDisabled,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExperimentDisabled({required String string}) {
  var string_0 = conversions.validateString(string);
  return new Message(
    codeExperimentDisabled,
    problemMessage:
        """This requires the '${string_0}' language feature to be enabled.""",
    correctionMessage:
        """The feature is on by default but is currently disabled, maybe because the '--enable-experiment=no-${string_0}' command line option is passed.""",
    arguments: {'string': string},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldExperimentDisabled(String string) =>
    _withArgumentsExperimentDisabled(string: string);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string, String string2),
  Message Function({required String string, required String string2})
>
codeExperimentDisabledInvalidLanguageVersion = const Template(
  "ExperimentDisabledInvalidLanguageVersion",
  problemMessageTemplate:
      r"""This requires the '#string' language feature, which requires language version of #string2 or higher.""",
  withArgumentsOld: _withArgumentsOldExperimentDisabledInvalidLanguageVersion,
  withArguments: _withArgumentsExperimentDisabledInvalidLanguageVersion,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExperimentDisabledInvalidLanguageVersion({
  required String string,
  required String string2,
}) {
  var string_0 = conversions.validateString(string);
  var string2_0 = conversions.validateString(string2);
  return new Message(
    codeExperimentDisabledInvalidLanguageVersion,
    problemMessage:
        """This requires the '${string_0}' language feature, which requires language version of ${string2_0} or higher.""",
    arguments: {'string': string, 'string2': string2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldExperimentDisabledInvalidLanguageVersion(
  String string,
  String string2,
) => _withArgumentsExperimentDisabledInvalidLanguageVersion(
  string: string,
  string2: string2,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeExperimentExpiredDisabled = const Template(
  "ExperimentExpiredDisabled",
  problemMessageTemplate:
      r"""The experiment '#name' has expired and can't be disabled.""",
  withArgumentsOld: _withArgumentsOldExperimentExpiredDisabled,
  withArguments: _withArgumentsExperimentExpiredDisabled,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExperimentExpiredDisabled({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeExperimentExpiredDisabled,
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
codeExperimentExpiredEnabled = const Template(
  "ExperimentExpiredEnabled",
  problemMessageTemplate:
      r"""The experiment '#name' has expired and can't be enabled.""",
  withArgumentsOld: _withArgumentsOldExperimentExpiredEnabled,
  withArguments: _withArgumentsExperimentExpiredEnabled,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExperimentExpiredEnabled({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeExperimentExpiredEnabled,
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
codeExperimentOptOutComment = const Template(
  "ExperimentOptOutComment",
  problemMessageTemplate:
      r"""This is the annotation that opts out this library from the '#string' language feature.""",
  withArgumentsOld: _withArgumentsOldExperimentOptOutComment,
  withArguments: _withArgumentsExperimentOptOutComment,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExperimentOptOutComment({required String string}) {
  var string_0 = conversions.validateString(string);
  return new Message(
    codeExperimentOptOutComment,
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
codeExperimentOptOutExplicit = const Template(
  "ExperimentOptOutExplicit",
  problemMessageTemplate:
      r"""The '#string' language feature is disabled for this library.""",
  correctionMessageTemplate:
      r"""Try removing the `@dart=` annotation or setting the language version to #string2 or higher.""",
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
    codeExperimentOptOutExplicit,
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
codeExperimentOptOutImplicit = const Template(
  "ExperimentOptOutImplicit",
  problemMessageTemplate:
      r"""The '#string' language feature is disabled for this library.""",
  correctionMessageTemplate:
      r"""Try removing the package language version or setting the language version to #string2 or higher.""",
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
    codeExperimentOptOutImplicit,
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
const MessageCode codeExplicitExtensionArgumentMismatch = const MessageCode(
  "ExplicitExtensionArgumentMismatch",
  problemMessage:
      r"""Explicit extension application requires exactly 1 positional argument.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExplicitExtensionAsExpression = const MessageCode(
  "ExplicitExtensionAsExpression",
  problemMessage:
      r"""Explicit extension application cannot be used as an expression.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExplicitExtensionAsLvalue = const MessageCode(
  "ExplicitExtensionAsLvalue",
  problemMessage:
      r"""Explicit extension application cannot be a target for assignment.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, int count),
  Message Function({required String name, required int count})
>
codeExplicitExtensionTypeArgumentMismatch = const Template(
  "ExplicitExtensionTypeArgumentMismatch",
  problemMessageTemplate:
      r"""Explicit extension application of extension '#name' takes '#count' type argument(s).""",
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
    codeExplicitExtensionTypeArgumentMismatch,
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
const MessageCode codeExportedMain = const MessageCode(
  "ExportedMain",
  severity: CfeSeverity.context,
  problemMessage: r"""This is exported 'main' declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeExpressionEvaluationKnownVariableUnavailable = const Template(
  "ExpressionEvaluationKnownVariableUnavailable",
  problemMessageTemplate:
      r"""The variable '#name' is unavailable in this expression evaluation.""",
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
    codeExpressionEvaluationKnownVariableUnavailable,
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
const MessageCode codeExpressionNotMetadata = const MessageCode(
  "ExpressionNotMetadata",
  problemMessage:
      r"""This can't be used as an annotation; an annotation should be a reference to a compile-time constant variable, or a call to a constant constructor.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeExtendingEnum = const Template(
  "ExtendingEnum",
  problemMessageTemplate:
      r"""'#name' is an enum and can't be extended or implemented.""",
  withArgumentsOld: _withArgumentsOldExtendingEnum,
  withArguments: _withArgumentsExtendingEnum,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExtendingEnum({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeExtendingEnum,
    problemMessage:
        """'${name_0}' is an enum and can't be extended or implemented.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldExtendingEnum(String name) =>
    _withArgumentsExtendingEnum(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeExtendingRestricted = const Template(
  "ExtendingRestricted",
  problemMessageTemplate:
      r"""'#name' is restricted and can't be extended or implemented.""",
  withArgumentsOld: _withArgumentsOldExtendingRestricted,
  withArguments: _withArgumentsExtendingRestricted,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExtendingRestricted({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeExtendingRestricted,
    problemMessage:
        """'${name_0}' is restricted and can't be extended or implemented.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldExtendingRestricted(String name) =>
    _withArgumentsExtendingRestricted(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExtendsDeferredClass = const MessageCode(
  "ExtendsDeferredClass",
  problemMessage: r"""Classes can't extend deferred classes.""",
  correctionMessage:
      r"""Try specifying a different superclass, or removing the extends clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExtendsNever = const MessageCode(
  "ExtendsNever",
  problemMessage: r"""The type 'Never' can't be used in an 'extends' clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeExtensionMemberConflictsWithObjectMember = const Template(
  "ExtensionMemberConflictsWithObjectMember",
  problemMessageTemplate:
      r"""This extension member conflicts with Object member '#name'.""",
  withArgumentsOld: _withArgumentsOldExtensionMemberConflictsWithObjectMember,
  withArguments: _withArgumentsExtensionMemberConflictsWithObjectMember,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExtensionMemberConflictsWithObjectMember({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeExtensionMemberConflictsWithObjectMember,
    problemMessage:
        """This extension member conflicts with Object member '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldExtensionMemberConflictsWithObjectMember(
  String name,
) => _withArgumentsExtensionMemberConflictsWithObjectMember(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, String name2),
  Message Function({required String name, required String name2})
>
codeExtensionTypeCombinedMemberSignatureFailed = const Template(
  "ExtensionTypeCombinedMemberSignatureFailed",
  problemMessageTemplate:
      r"""Extension type '#name' inherits multiple members named '#name2' with incompatible signatures.""",
  correctionMessageTemplate:
      r"""Try adding a declaration of '#name2' to '#name'.""",
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
    codeExtensionTypeCombinedMemberSignatureFailed,
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
codeExtensionTypeConstructorWithSuperFormalParameter = const MessageCode(
  "ExtensionTypeConstructorWithSuperFormalParameter",
  problemMessage:
      r"""Extension type constructors can't declare super formal parameters.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExtensionTypeDeclarationCause = const MessageCode(
  "ExtensionTypeDeclarationCause",
  severity: CfeSeverity.context,
  problemMessage: r"""The issue arises via this extension type declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExtensionTypeImplementsDeferred = const MessageCode(
  "ExtensionTypeImplementsDeferred",
  problemMessage: r"""Extension types can't implement deferred types.""",
  correctionMessage:
      r"""Try specifying a different type, removing the type from the list, or changing the import to not be deferred.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExtensionTypeMemberContext = const MessageCode(
  "ExtensionTypeMemberContext",
  severity: CfeSeverity.context,
  problemMessage: r"""This is the inherited extension type member.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExtensionTypeMemberOneOfContext = const MessageCode(
  "ExtensionTypeMemberOneOfContext",
  severity: CfeSeverity.context,
  problemMessage: r"""This is one of the inherited extension type members.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
codeExtensionTypePrimaryConstructorFunctionFormalParameterSyntax = const MessageCode(
  "ExtensionTypePrimaryConstructorFunctionFormalParameterSyntax",
  problemMessage:
      r"""Primary constructors in extension types can't use function formal parameter syntax.""",
  correctionMessage:
      r"""Try rewriting with an explicit function type, like `int Function() f`.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
codeExtensionTypePrimaryConstructorWithInitializingFormal = const MessageCode(
  "ExtensionTypePrimaryConstructorWithInitializingFormal",
  problemMessage:
      r"""Primary constructors in extension types can't use initializing formals.""",
  correctionMessage: r"""Try removing `this.` from the formal parameter.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExtensionTypeRepresentationTypeBottom = const MessageCode(
  "ExtensionTypeRepresentationTypeBottom",
  problemMessage: r"""The representation type can't be a bottom type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeExtensionTypeShouldBeListedAsCallableInDynamicInterface = const Template(
  "ExtensionTypeShouldBeListedAsCallableInDynamicInterface",
  problemMessageTemplate:
      r"""Cannot use extension type '#name' in a dynamic module.""",
  correctionMessageTemplate:
      r"""Try removing the reference to extension type '#name' or update the dynamic interface to list extension type '#name' as callable.""",
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
    codeExtensionTypeShouldBeListedAsCallableInDynamicInterface,
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
const MessageCode codeExternalFieldConstructorInitializer = const MessageCode(
  "ExternalFieldConstructorInitializer",
  problemMessage: r"""External fields cannot have initializers.""",
  correctionMessage:
      r"""Try removing the field initializer or the 'external' keyword from the field declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExternalFieldInitializer = const MessageCode(
  "ExternalFieldInitializer",
  problemMessage: r"""External fields cannot have initializers.""",
  correctionMessage:
      r"""Try removing the initializer or the 'external' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeFactoryConflictsWithMember = const Template(
  "FactoryConflictsWithMember",
  problemMessageTemplate: r"""The factory conflicts with member '#name'.""",
  withArgumentsOld: _withArgumentsOldFactoryConflictsWithMember,
  withArguments: _withArgumentsFactoryConflictsWithMember,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFactoryConflictsWithMember({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeFactoryConflictsWithMember,
    problemMessage: """The factory conflicts with member '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldFactoryConflictsWithMember(String name) =>
    _withArgumentsFactoryConflictsWithMember(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeFactoryConflictsWithMemberCause = const Template(
  "FactoryConflictsWithMemberCause",
  problemMessageTemplate: r"""Conflicting member '#name'.""",
  withArgumentsOld: _withArgumentsOldFactoryConflictsWithMemberCause,
  withArguments: _withArgumentsFactoryConflictsWithMemberCause,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFactoryConflictsWithMemberCause({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeFactoryConflictsWithMemberCause,
    problemMessage: """Conflicting member '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldFactoryConflictsWithMemberCause(String name) =>
    _withArgumentsFactoryConflictsWithMemberCause(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeFastaUsageLong = const MessageCode(
  "FastaUsageLong",
  problemMessage: r"""Supported options:

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
const MessageCode codeFastaUsageShort = const MessageCode(
  "FastaUsageShort",
  problemMessage: r"""Frequently used options:

  -o <file> Generate the output into <file>.
  -h        Display this message (add -v for information about all options).""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeFfiAbiSpecificIntegerInvalid = const MessageCode(
  "FfiAbiSpecificIntegerInvalid",
  problemMessage:
      r"""Classes extending 'AbiSpecificInteger' must have exactly one const constructor, no other members, and no type arguments.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeFfiAbiSpecificIntegerMappingInvalid = const MessageCode(
  "FfiAbiSpecificIntegerMappingInvalid",
  problemMessage:
      r"""Classes extending 'AbiSpecificInteger' must have exactly one 'AbiSpecificIntegerMapping' annotation specifying the mapping from ABI to a NativeType integer with a fixed size.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeFfiAddressOfMustBeNative = const MessageCode(
  "FfiAddressOfMustBeNative",
  problemMessage:
      r"""Argument to 'Native.addressOf' must be annotated with @Native.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeFfiAddressPosition = const MessageCode(
  "FfiAddressPosition",
  problemMessage:
      r"""The '.address' expression can only be used as argument to a leaf native external call.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeFfiAddressReceiver = const MessageCode(
  "FfiAddressReceiver",
  problemMessage:
      r"""The receiver of '.address' must be a concrete 'TypedData', a concrete 'TypedData' '[]', an 'Array', an 'Array' '[]', a Struct field, or a Union field.""",
  correctionMessage:
      r"""Change the receiver of '.address' to one of the allowed kinds.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string, String name),
  Message Function({required String string, required String name})
>
codeFfiCompoundImplementsFinalizable = const Template(
  "FfiCompoundImplementsFinalizable",
  problemMessageTemplate: r"""#string '#name' can't implement Finalizable.""",
  correctionMessageTemplate:
      r"""Try removing the implements clause from '#name'.""",
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
    codeFfiCompoundImplementsFinalizable,
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
const MessageCode codeFfiCreateOfStructOrUnion = const MessageCode(
  "FfiCreateOfStructOrUnion",
  problemMessage:
      r"""Subclasses of 'Struct' and 'Union' are backed by native memory, and can't be instantiated by a generative constructor. Try allocating it via allocation, or load from a 'Pointer'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type, DartType type2),
  Message Function({required DartType type, required DartType type2})
>
codeFfiDartTypeMismatch = const Template(
  "FfiDartTypeMismatch",
  problemMessageTemplate: r"""Expected '#type' to be a subtype of '#type2'.""",
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
    codeFfiDartTypeMismatch,
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
const MessageCode codeFfiDeeplyImmutableClassesMustBeFinalOrSealed =
    const MessageCode(
      "FfiDeeplyImmutableClassesMustBeFinalOrSealed",
      problemMessage: r"""Deeply immutable classes must be final or sealed.""",
      correctionMessage: r"""Try marking this class as final or sealed.""",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeFfiDeeplyImmutableFieldsModifiers = const MessageCode(
  "FfiDeeplyImmutableFieldsModifiers",
  problemMessage:
      r"""Deeply immutable classes must only have final non-late instance fields.""",
  correctionMessage:
      r"""Add the 'final' modifier to this field, and remove 'late' modifier from this field.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
codeFfiDeeplyImmutableFieldsMustBeDeeplyImmutable = const MessageCode(
  "FfiDeeplyImmutableFieldsMustBeDeeplyImmutable",
  problemMessage:
      r"""Deeply immutable classes must only have deeply immutable instance fields. Deeply immutable types include 'int', 'double', 'bool', 'String', 'Pointer', 'Float32x4', 'Float64x2', 'Int32x4', and classes annotated with `@pragma('vm:deeply-immutable')`.""",
  correctionMessage:
      r"""Try changing the type of this field to a deeply immutable type or mark the type of this field as deeply immutable.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
codeFfiDeeplyImmutableSubtypesMustBeDeeplyImmutable = const MessageCode(
  "FfiDeeplyImmutableSubtypesMustBeDeeplyImmutable",
  problemMessage:
      r"""Subtypes of deeply immutable classes must be deeply immutable.""",
  correctionMessage:
      r"""Try marking this class deeply immutable by adding `@pragma('vm:deeply-immutable')`.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
codeFfiDeeplyImmutableSupertypeMustBeDeeplyImmutable = const MessageCode(
  "FfiDeeplyImmutableSupertypeMustBeDeeplyImmutable",
  problemMessage:
      r"""The super type of deeply immutable classes must be deeply immutable.""",
  correctionMessage:
      r"""Try marking the super class deeply immutable by adding `@pragma('vm:deeply-immutable')`.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeFfiDefaultAssetDuplicate = const MessageCode(
  "FfiDefaultAssetDuplicate",
  problemMessage:
      r"""There may be at most one @DefaultAsset annotation on a library.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string, String name),
  Message Function({required String string, required String name})
>
codeFfiEmptyStruct = const Template(
  "FfiEmptyStruct",
  problemMessageTemplate:
      r"""#string '#name' is empty. Empty structs and unions are undefined behavior.""",
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
    codeFfiEmptyStruct,
    problemMessage:
        """${string_0} '${name_0}' is empty. Empty structs and unions are undefined behavior.""",
    arguments: {'string': string, 'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldFfiEmptyStruct(String string, String name) =>
    _withArgumentsFfiEmptyStruct(string: string, name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeFfiExceptionalReturnNull = const MessageCode(
  "FfiExceptionalReturnNull",
  problemMessage: r"""Exceptional return value must not be null.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeFfiExpectedConstant = const MessageCode(
  "FfiExpectedConstant",
  problemMessage: r"""Exceptional return value must be a constant.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeFfiExpectedConstantArg = const Template(
  "FfiExpectedConstantArg",
  problemMessageTemplate: r"""Argument '#name' must be a constant.""",
  withArgumentsOld: _withArgumentsOldFfiExpectedConstantArg,
  withArguments: _withArgumentsFfiExpectedConstantArg,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiExpectedConstantArg({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeFfiExpectedConstantArg,
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
codeFfiExpectedExceptionalReturn = const Template(
  "FfiExpectedExceptionalReturn",
  problemMessageTemplate:
      r"""Expected an exceptional return value for a native callback returning '#type'.""",
  withArgumentsOld: _withArgumentsOldFfiExpectedExceptionalReturn,
  withArguments: _withArgumentsFfiExpectedExceptionalReturn,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiExpectedExceptionalReturn({required DartType type}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    codeFfiExpectedExceptionalReturn,
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
codeFfiExpectedNoExceptionalReturn = const Template(
  "FfiExpectedNoExceptionalReturn",
  problemMessageTemplate:
      r"""Exceptional return value cannot be provided for a native callback returning '#type'.""",
  withArgumentsOld: _withArgumentsOldFfiExpectedNoExceptionalReturn,
  withArguments: _withArgumentsFfiExpectedNoExceptionalReturn,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiExpectedNoExceptionalReturn({required DartType type}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    codeFfiExpectedNoExceptionalReturn,
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
codeFfiExtendsOrImplementsSealedClass = const Template(
  "FfiExtendsOrImplementsSealedClass",
  problemMessageTemplate:
      r"""Class '#name' cannot be extended or implemented.""",
  withArgumentsOld: _withArgumentsOldFfiExtendsOrImplementsSealedClass,
  withArguments: _withArgumentsFfiExtendsOrImplementsSealedClass,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiExtendsOrImplementsSealedClass({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeFfiExtendsOrImplementsSealedClass,
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
codeFfiFieldAnnotation = const Template(
  "FfiFieldAnnotation",
  problemMessageTemplate:
      r"""Field '#name' requires exactly one annotation to declare its native type, which cannot be Void. dart:ffi Structs and Unions cannot have regular Dart fields.""",
  withArgumentsOld: _withArgumentsOldFfiFieldAnnotation,
  withArguments: _withArgumentsFfiFieldAnnotation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiFieldAnnotation({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeFfiFieldAnnotation,
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
codeFfiFieldCyclic = const Template(
  "FfiFieldCyclic",
  problemMessageTemplate: r"""#string '#name' contains itself. Cycle elements:
#names""",
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
    codeFfiFieldCyclic,
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
codeFfiFieldInitializer = const Template(
  "FfiFieldInitializer",
  problemMessageTemplate:
      r"""Field '#name' is a dart:ffi Pointer to a struct field and therefore cannot be initialized before constructor execution.""",
  correctionMessageTemplate:
      r"""Mark the field as external to avoid having to initialize it.""",
  withArgumentsOld: _withArgumentsOldFfiFieldInitializer,
  withArguments: _withArgumentsFfiFieldInitializer,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiFieldInitializer({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeFfiFieldInitializer,
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
codeFfiFieldNoAnnotation = const Template(
  "FfiFieldNoAnnotation",
  problemMessageTemplate:
      r"""Field '#name' requires no annotation to declare its native type, it is a Pointer which is represented by the same type in Dart and native code.""",
  withArgumentsOld: _withArgumentsOldFfiFieldNoAnnotation,
  withArguments: _withArgumentsFfiFieldNoAnnotation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiFieldNoAnnotation({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeFfiFieldNoAnnotation,
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
codeFfiFieldNull = const Template(
  "FfiFieldNull",
  problemMessageTemplate:
      r"""Field '#name' cannot be nullable or have type 'Null', it must be `int`, `double`, `Pointer`, or a subtype of `Struct` or `Union`.""",
  withArgumentsOld: _withArgumentsOldFfiFieldNull,
  withArguments: _withArgumentsFfiFieldNull,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiFieldNull({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeFfiFieldNull,
    problemMessage:
        """Field '${name_0}' cannot be nullable or have type 'Null', it must be `int`, `double`, `Pointer`, or a subtype of `Struct` or `Union`.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldFfiFieldNull(String name) =>
    _withArgumentsFfiFieldNull(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeFfiLeafCallMustNotReturnHandle = const MessageCode(
  "FfiLeafCallMustNotReturnHandle",
  problemMessage: r"""FFI leaf call must not have Handle return type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeFfiLeafCallMustNotTakeHandle = const MessageCode(
  "FfiLeafCallMustNotTakeHandle",
  problemMessage: r"""FFI leaf call must not have Handle argument types.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type),
  Message Function({required DartType type})
>
codeFfiNativeCallableListenerReturnVoid = const Template(
  "FfiNativeCallableListenerReturnVoid",
  problemMessageTemplate:
      r"""The return type of the function passed to NativeCallable.listener must be void rather than '#type'.""",
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
    codeFfiNativeCallableListenerReturnVoid,
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
const MessageCode codeFfiNativeDuplicateAnnotations = const MessageCode(
  "FfiNativeDuplicateAnnotations",
  problemMessage:
      r"""Native functions and fields must not have more than @Native annotation.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeFfiNativeFieldMissingType = const MessageCode(
  "FfiNativeFieldMissingType",
  problemMessage:
      r"""The native type of this field could not be inferred and must be specified in the annotation.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeFfiNativeFieldMustBeStatic = const MessageCode(
  "FfiNativeFieldMustBeStatic",
  problemMessage: r"""Native fields must be static.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeFfiNativeFieldType = const MessageCode(
  "FfiNativeFieldType",
  problemMessage:
      r"""Unsupported type for native fields. Native fields only support pointers, compounds and numeric types.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeFfiNativeFunctionMissingType = const MessageCode(
  "FfiNativeFunctionMissingType",
  problemMessage:
      r"""The native type of this function couldn't be inferred so it must be specified in the annotation.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeFfiNativeMustBeExternal = const MessageCode(
  "FfiNativeMustBeExternal",
  problemMessage: r"""Native functions and fields must be marked external.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
codeFfiNativeOnlyNativeFieldWrapperClassCanBePointer = const MessageCode(
  "FfiNativeOnlyNativeFieldWrapperClassCanBePointer",
  problemMessage:
      r"""Only classes extending NativeFieldWrapperClass1 can be passed as Pointer.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(int count, int count2),
  Message Function({required int count, required int count2})
>
codeFfiNativeUnexpectedNumberOfParameters = const Template(
  "FfiNativeUnexpectedNumberOfParameters",
  problemMessageTemplate:
      r"""Unexpected number of Native annotation parameters. Expected #count but has #count2.""",
  withArgumentsOld: _withArgumentsOldFfiNativeUnexpectedNumberOfParameters,
  withArguments: _withArgumentsFfiNativeUnexpectedNumberOfParameters,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiNativeUnexpectedNumberOfParameters({
  required int count,
  required int count2,
}) {
  return new Message(
    codeFfiNativeUnexpectedNumberOfParameters,
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
codeFfiNativeUnexpectedNumberOfParametersWithReceiver = const Template(
  "FfiNativeUnexpectedNumberOfParametersWithReceiver",
  problemMessageTemplate:
      r"""Unexpected number of Native annotation parameters. Expected #count but has #count2. Native instance method annotation must have receiver as first argument.""",
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
    codeFfiNativeUnexpectedNumberOfParametersWithReceiver,
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
codeFfiNotStatic = const Template(
  "FfiNotStatic",
  problemMessageTemplate:
      r"""#name expects a static function as parameter. dart:ffi only supports calling static Dart functions from native code. Closures and tear-offs are not supported because they can capture context.""",
  withArgumentsOld: _withArgumentsOldFfiNotStatic,
  withArguments: _withArgumentsFfiNotStatic,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiNotStatic({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeFfiNotStatic,
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
codeFfiPackedAnnotation = const Template(
  "FfiPackedAnnotation",
  problemMessageTemplate:
      r"""Struct '#name' must have at most one 'Packed' annotation.""",
  withArgumentsOld: _withArgumentsOldFfiPackedAnnotation,
  withArguments: _withArgumentsFfiPackedAnnotation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiPackedAnnotation({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeFfiPackedAnnotation,
    problemMessage:
        """Struct '${name_0}' must have at most one 'Packed' annotation.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldFfiPackedAnnotation(String name) =>
    _withArgumentsFfiPackedAnnotation(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeFfiPackedAnnotationAlignment = const MessageCode(
  "FfiPackedAnnotationAlignment",
  problemMessage: r"""Only packing to 1, 2, 4, 8, and 16 bytes is supported.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeFfiSizeAnnotation = const Template(
  "FfiSizeAnnotation",
  problemMessageTemplate:
      r"""Field '#name' must have exactly one 'Array' annotation.""",
  withArgumentsOld: _withArgumentsOldFfiSizeAnnotation,
  withArguments: _withArgumentsFfiSizeAnnotation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiSizeAnnotation({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeFfiSizeAnnotation,
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
codeFfiSizeAnnotationDimensions = const Template(
  "FfiSizeAnnotationDimensions",
  problemMessageTemplate:
      r"""Field '#name' must have an 'Array' annotation that matches the dimensions.""",
  withArgumentsOld: _withArgumentsOldFfiSizeAnnotationDimensions,
  withArguments: _withArgumentsFfiSizeAnnotationDimensions,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiSizeAnnotationDimensions({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeFfiSizeAnnotationDimensions,
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
codeFfiStructGeneric = const Template(
  "FfiStructGeneric",
  problemMessageTemplate: r"""#string '#name' should not be generic.""",
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
    codeFfiStructGeneric,
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
codeFfiTypeInvalid = const Template(
  "FfiTypeInvalid",
  problemMessageTemplate:
      r"""Expected type '#type' to be a valid and instantiated subtype of 'NativeType'.""",
  withArgumentsOld: _withArgumentsOldFfiTypeInvalid,
  withArguments: _withArgumentsFfiTypeInvalid,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiTypeInvalid({required DartType type}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    codeFfiTypeInvalid,
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
codeFfiTypeMismatch = const Template(
  "FfiTypeMismatch",
  problemMessageTemplate:
      r"""Expected type '#type' to be '#type2', which is the Dart type corresponding to '#type3'.""",
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
    codeFfiTypeMismatch,
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
const MessageCode codeFfiVariableLengthArrayNotLast = const MessageCode(
  "FfiVariableLengthArrayNotLast",
  problemMessage:
      r"""Variable length 'Array's must only occur as the last field of Structs.""",
  correctionMessage:
      r"""Try adjusting the arguments in the 'Array' annotation.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeFieldAlreadyInitializedAtDeclaration = const Template(
  "FieldAlreadyInitializedAtDeclaration",
  problemMessageTemplate:
      r"""'#name' is a final instance variable that was initialized at the declaration.""",
  withArgumentsOld: _withArgumentsOldFieldAlreadyInitializedAtDeclaration,
  withArguments: _withArgumentsFieldAlreadyInitializedAtDeclaration,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFieldAlreadyInitializedAtDeclaration({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeFieldAlreadyInitializedAtDeclaration,
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
codeFieldAlreadyInitializedAtDeclarationCause = const Template(
  "FieldAlreadyInitializedAtDeclarationCause",
  problemMessageTemplate: r"""'#name' was initialized here.""",
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
    codeFieldAlreadyInitializedAtDeclarationCause,
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
codeFieldNonNullableNotInitializedByConstructorError = const Template(
  "FieldNonNullableNotInitializedByConstructorError",
  problemMessageTemplate:
      r"""This constructor should initialize field '#name' because its type '#type' doesn't allow null.""",
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
    codeFieldNonNullableNotInitializedByConstructorError,
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
codeFieldNonNullableWithoutInitializerError = const Template(
  "FieldNonNullableWithoutInitializerError",
  problemMessageTemplate:
      r"""Field '#name' should be initialized because its type '#type' doesn't allow null.""",
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
    codeFieldNonNullableWithoutInitializerError,
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
codeFieldNotPromotedBecauseConflictingField = const Template(
  "FieldNotPromotedBecauseConflictingField",
  problemMessageTemplate:
      r"""'#name' couldn't be promoted because there is a conflicting non-promotable field in class '#name2'.""",
  correctionMessageTemplate: r"""See #string""",
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
    codeFieldNotPromotedBecauseConflictingField,
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
codeFieldNotPromotedBecauseConflictingGetter = const Template(
  "FieldNotPromotedBecauseConflictingGetter",
  problemMessageTemplate:
      r"""'#name' couldn't be promoted because there is a conflicting getter in class '#name2'.""",
  correctionMessageTemplate: r"""See #string""",
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
    codeFieldNotPromotedBecauseConflictingGetter,
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
codeFieldNotPromotedBecauseConflictingNsmForwarder = const Template(
  "FieldNotPromotedBecauseConflictingNsmForwarder",
  problemMessageTemplate:
      r"""'#name' couldn't be promoted because there is a conflicting noSuchMethod forwarder in class '#name2'.""",
  correctionMessageTemplate: r"""See #string""",
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
    codeFieldNotPromotedBecauseConflictingNsmForwarder,
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
codeFieldNotPromotedBecauseExternal = const Template(
  "FieldNotPromotedBecauseExternal",
  problemMessageTemplate:
      r"""'#name' refers to an external field so it couldn't be promoted.""",
  correctionMessageTemplate: r"""See #string""",
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
    codeFieldNotPromotedBecauseExternal,
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
codeFieldNotPromotedBecauseNotEnabled = const Template(
  "FieldNotPromotedBecauseNotEnabled",
  problemMessageTemplate:
      r"""'#name' couldn't be promoted because field promotion is only available in Dart 3.2 and above.""",
  correctionMessageTemplate: r"""See #string""",
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
    codeFieldNotPromotedBecauseNotEnabled,
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
codeFieldNotPromotedBecauseNotField = const Template(
  "FieldNotPromotedBecauseNotField",
  problemMessageTemplate:
      r"""'#name' refers to a getter so it couldn't be promoted.""",
  correctionMessageTemplate: r"""See #string""",
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
    codeFieldNotPromotedBecauseNotField,
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
codeFieldNotPromotedBecauseNotFinal = const Template(
  "FieldNotPromotedBecauseNotFinal",
  problemMessageTemplate:
      r"""'#name' refers to a non-final field so it couldn't be promoted.""",
  correctionMessageTemplate: r"""See #string""",
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
    codeFieldNotPromotedBecauseNotFinal,
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
codeFieldNotPromotedBecauseNotPrivate = const Template(
  "FieldNotPromotedBecauseNotPrivate",
  problemMessageTemplate:
      r"""'#name' refers to a public property so it couldn't be promoted.""",
  correctionMessageTemplate: r"""See #string""",
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
    codeFieldNotPromotedBecauseNotPrivate,
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
codeFinalClassExtendedOutsideOfLibrary = const Template(
  "FinalClassExtendedOutsideOfLibrary",
  problemMessageTemplate:
      r"""The class '#name' can't be extended outside of its library because it's a final class.""",
  withArgumentsOld: _withArgumentsOldFinalClassExtendedOutsideOfLibrary,
  withArguments: _withArgumentsFinalClassExtendedOutsideOfLibrary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFinalClassExtendedOutsideOfLibrary({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeFinalClassExtendedOutsideOfLibrary,
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
codeFinalClassImplementedOutsideOfLibrary = const Template(
  "FinalClassImplementedOutsideOfLibrary",
  problemMessageTemplate:
      r"""The class '#name' can't be implemented outside of its library because it's a final class.""",
  withArgumentsOld: _withArgumentsOldFinalClassImplementedOutsideOfLibrary,
  withArguments: _withArgumentsFinalClassImplementedOutsideOfLibrary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFinalClassImplementedOutsideOfLibrary({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeFinalClassImplementedOutsideOfLibrary,
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
codeFinalClassUsedAsMixinConstraintOutsideOfLibrary = const Template(
  "FinalClassUsedAsMixinConstraintOutsideOfLibrary",
  problemMessageTemplate:
      r"""The class '#name' can't be used as a mixin superclass constraint outside of its library because it's a final class.""",
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
    codeFinalClassUsedAsMixinConstraintOutsideOfLibrary,
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
  Message Function(String name),
  Message Function({required String name})
>
codeFinalFieldNotInitialized = const Template(
  "FinalFieldNotInitialized",
  problemMessageTemplate: r"""Final field '#name' is not initialized.""",
  correctionMessageTemplate:
      r"""Try to initialize the field in the declaration or in every constructor.""",
  withArgumentsOld: _withArgumentsOldFinalFieldNotInitialized,
  withArguments: _withArgumentsFinalFieldNotInitialized,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFinalFieldNotInitialized({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeFinalFieldNotInitialized,
    problemMessage: """Final field '${name_0}' is not initialized.""",
    correctionMessage:
        """Try to initialize the field in the declaration or in every constructor.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldFinalFieldNotInitialized(String name) =>
    _withArgumentsFinalFieldNotInitialized(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeFinalFieldNotInitializedByConstructor = const Template(
  "FinalFieldNotInitializedByConstructor",
  problemMessageTemplate:
      r"""Final field '#name' is not initialized by this constructor.""",
  correctionMessageTemplate:
      r"""Try to initialize the field using an initializing formal or a field initializer.""",
  withArgumentsOld: _withArgumentsOldFinalFieldNotInitializedByConstructor,
  withArguments: _withArgumentsFinalFieldNotInitializedByConstructor,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFinalFieldNotInitializedByConstructor({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeFinalFieldNotInitializedByConstructor,
    problemMessage:
        """Final field '${name_0}' is not initialized by this constructor.""",
    correctionMessage:
        """Try to initialize the field using an initializing formal or a field initializer.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldFinalFieldNotInitializedByConstructor(String name) =>
    _withArgumentsFinalFieldNotInitializedByConstructor(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeFinalNotAssignedError = const Template(
  "FinalNotAssignedError",
  problemMessageTemplate:
      r"""Final variable '#name' must be assigned before it can be used.""",
  withArgumentsOld: _withArgumentsOldFinalNotAssignedError,
  withArguments: _withArgumentsFinalNotAssignedError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFinalNotAssignedError({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeFinalNotAssignedError,
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
codeFinalPossiblyAssignedError = const Template(
  "FinalPossiblyAssignedError",
  problemMessageTemplate:
      r"""Final variable '#name' might already be assigned at this point.""",
  withArgumentsOld: _withArgumentsOldFinalPossiblyAssignedError,
  withArguments: _withArgumentsFinalPossiblyAssignedError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFinalPossiblyAssignedError({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeFinalPossiblyAssignedError,
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
codeForInLoopElementTypeNotAssignable = const Template(
  "ForInLoopElementTypeNotAssignable",
  problemMessageTemplate:
      r"""A value of type '#type' can't be assigned to a variable of type '#type2'.""",
  correctionMessageTemplate: r"""Try changing the type of the variable.""",
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
    codeForInLoopElementTypeNotAssignable,
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
const MessageCode codeForInLoopExactlyOneVariable = const MessageCode(
  "ForInLoopExactlyOneVariable",
  problemMessage: r"""A for-in loop can't have more than one loop variable.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeForInLoopNotAssignable = const MessageCode(
  "ForInLoopNotAssignable",
  problemMessage:
      r"""Can't assign to this, so it can't be used in a for-in loop.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type, DartType type2),
  Message Function({required DartType type, required DartType type2})
>
codeForInLoopTypeNotIterable = const Template(
  "ForInLoopTypeNotIterable",
  problemMessageTemplate:
      r"""The type '#type' used in the 'for' loop must implement '#type2'.""",
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
    codeForInLoopTypeNotIterable,
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
const MessageCode codeForInLoopWithConstVariable = const MessageCode(
  "ForInLoopWithConstVariable",
  problemMessage: r"""A for-in loop-variable can't be 'const'.""",
  correctionMessage: r"""Try removing the 'const' modifier.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type, DartType type2),
  Message Function({required DartType type, required DartType type2})
>
codeGenericFunctionTypeAsTypeArgumentThroughTypedef = const Template(
  "GenericFunctionTypeAsTypeArgumentThroughTypedef",
  problemMessageTemplate:
      r"""Generic function type '#type' used as a type argument through typedef '#type2'.""",
  correctionMessageTemplate:
      r"""Try providing a non-generic function type explicitly.""",
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
    codeGenericFunctionTypeAsTypeArgumentThroughTypedef,
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
const MessageCode codeGenericFunctionTypeInBound = const MessageCode(
  "GenericFunctionTypeInBound",
  problemMessage:
      r"""Type variables can't have generic function types in their bounds.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type),
  Message Function({required DartType type})
>
codeGenericFunctionTypeInferredAsActualTypeArgument = const Template(
  "GenericFunctionTypeInferredAsActualTypeArgument",
  problemMessageTemplate:
      r"""Generic function type '#type' inferred as a type argument.""",
  correctionMessageTemplate:
      r"""Try providing a non-generic function type explicitly.""",
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
    codeGenericFunctionTypeInferredAsActualTypeArgument,
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
const MessageCode codeGenericFunctionTypeUsedAsActualTypeArgument =
    const MessageCode(
      "GenericFunctionTypeUsedAsActualTypeArgument",
      problemMessage:
          r"""A generic function type can't be used as a type argument.""",
      correctionMessage: r"""Try using a non-generic function type.""",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeGetterNotFound = const Template(
  "GetterNotFound",
  problemMessageTemplate: r"""Getter not found: '#name'.""",
  withArgumentsOld: _withArgumentsOldGetterNotFound,
  withArguments: _withArgumentsGetterNotFound,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsGetterNotFound({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeGetterNotFound,
    problemMessage: """Getter not found: '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldGetterNotFound(String name) =>
    _withArgumentsGetterNotFound(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeIllegalAsyncGeneratorReturnType = const MessageCode(
  "IllegalAsyncGeneratorReturnType",
  problemMessage:
      r"""Functions marked 'async*' must have a return type assignable to 'Stream'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeIllegalAsyncGeneratorVoidReturnType = const MessageCode(
  "IllegalAsyncGeneratorVoidReturnType",
  problemMessage:
      r"""Functions marked 'async*' can't have return type 'void'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeIllegalAsyncReturnType = const MessageCode(
  "IllegalAsyncReturnType",
  problemMessage:
      r"""Functions marked 'async' must have a return type assignable to 'Future'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeIllegalMixin = const Template(
  "IllegalMixin",
  problemMessageTemplate: r"""The type '#name' can't be mixed in.""",
  withArgumentsOld: _withArgumentsOldIllegalMixin,
  withArguments: _withArgumentsIllegalMixin,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIllegalMixin({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeIllegalMixin,
    problemMessage: """The type '${name_0}' can't be mixed in.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldIllegalMixin(String name) =>
    _withArgumentsIllegalMixin(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeIllegalMixinDueToConstructors = const Template(
  "IllegalMixinDueToConstructors",
  problemMessageTemplate:
      r"""Can't use '#name' as a mixin because it has constructors.""",
  withArgumentsOld: _withArgumentsOldIllegalMixinDueToConstructors,
  withArguments: _withArgumentsIllegalMixinDueToConstructors,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIllegalMixinDueToConstructors({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeIllegalMixinDueToConstructors,
    problemMessage:
        """Can't use '${name_0}' as a mixin because it has constructors.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldIllegalMixinDueToConstructors(String name) =>
    _withArgumentsIllegalMixinDueToConstructors(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeIllegalMixinDueToConstructorsCause = const Template(
  "IllegalMixinDueToConstructorsCause",
  problemMessageTemplate:
      r"""This constructor prevents using '#name' as a mixin.""",
  withArgumentsOld: _withArgumentsOldIllegalMixinDueToConstructorsCause,
  withArguments: _withArgumentsIllegalMixinDueToConstructorsCause,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIllegalMixinDueToConstructorsCause({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeIllegalMixinDueToConstructorsCause,
    problemMessage:
        """This constructor prevents using '${name_0}' as a mixin.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldIllegalMixinDueToConstructorsCause(String name) =>
    _withArgumentsIllegalMixinDueToConstructorsCause(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeIllegalSyncGeneratorReturnType = const MessageCode(
  "IllegalSyncGeneratorReturnType",
  problemMessage:
      r"""Functions marked 'sync*' must have a return type assignable to 'Iterable'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeIllegalSyncGeneratorVoidReturnType = const MessageCode(
  "IllegalSyncGeneratorVoidReturnType",
  problemMessage:
      r"""Functions marked 'sync*' can't have return type 'void'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, String name2),
  Message Function({required String name, required String name2})
>
codeImplementMultipleExtensionTypeMembers = const Template(
  "ImplementMultipleExtensionTypeMembers",
  problemMessageTemplate:
      r"""The extension type '#name' can't inherit the member '#name2' from more than one extension type.""",
  correctionMessageTemplate:
      r"""Try declaring a member '#name2' in '#name' to resolve the conflict.""",
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
    codeImplementMultipleExtensionTypeMembers,
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
codeImplementNonExtensionTypeAndExtensionTypeMember = const Template(
  "ImplementNonExtensionTypeAndExtensionTypeMember",
  problemMessageTemplate:
      r"""The extension type '#name' can't inherit the member '#name2' as both an extension type member and a non-extension type member.""",
  correctionMessageTemplate:
      r"""Try declaring a member '#name2' in '#name' to resolve the conflict.""",
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
    codeImplementNonExtensionTypeAndExtensionTypeMember,
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
const MessageCode codeImplementsFutureOr = const MessageCode(
  "ImplementsFutureOr",
  problemMessage:
      r"""The type 'FutureOr' can't be used in an 'implements' clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeImplementsNever = const MessageCode(
  "ImplementsNever",
  problemMessage:
      r"""The type 'Never' can't be used in an 'implements' clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, int count),
  Message Function({required String name, required int count})
>
codeImplementsRepeated = const Template(
  "ImplementsRepeated",
  problemMessageTemplate: r"""'#name' can only be implemented once.""",
  correctionMessageTemplate: r"""Try removing #count of the occurrences.""",
  withArgumentsOld: _withArgumentsOldImplementsRepeated,
  withArguments: _withArgumentsImplementsRepeated,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsImplementsRepeated({
  required String name,
  required int count,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeImplementsRepeated,
    problemMessage: """'${name_0}' can only be implemented once.""",
    correctionMessage: """Try removing ${count} of the occurrences.""",
    arguments: {'name': name, 'count': count},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldImplementsRepeated(String name, int count) =>
    _withArgumentsImplementsRepeated(name: name, count: count);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeImplementsSuperClass = const Template(
  "ImplementsSuperClass",
  problemMessageTemplate:
      r"""'#name' can't be used in both 'extends' and 'implements' clauses.""",
  correctionMessageTemplate: r"""Try removing one of the occurrences.""",
  withArgumentsOld: _withArgumentsOldImplementsSuperClass,
  withArguments: _withArgumentsImplementsSuperClass,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsImplementsSuperClass({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeImplementsSuperClass,
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
codeImplicitCallOfNonMethod = const Template(
  "ImplicitCallOfNonMethod",
  problemMessageTemplate:
      r"""Cannot invoke an instance of '#type' because it declares 'call' to be something other than a method.""",
  correctionMessageTemplate:
      r"""Try changing 'call' to a method or explicitly invoke 'call'.""",
  withArgumentsOld: _withArgumentsOldImplicitCallOfNonMethod,
  withArguments: _withArgumentsImplicitCallOfNonMethod,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsImplicitCallOfNonMethod({required DartType type}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    codeImplicitCallOfNonMethod,
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
  Message Function(String name, String name2, String name3),
  Message Function({
    required String name,
    required String name2,
    required String name3,
  })
>
codeImplicitMixinOverride = const Template(
  "ImplicitMixinOverride",
  problemMessageTemplate:
      r"""Applying the mixin '#name' to '#name2' introduces an erroneous override of '#name3'.""",
  withArgumentsOld: _withArgumentsOldImplicitMixinOverride,
  withArguments: _withArgumentsImplicitMixinOverride,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsImplicitMixinOverride({
  required String name,
  required String name2,
  required String name3,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var name2_0 = conversions.validateAndDemangleName(name2);
  var name3_0 = conversions.validateAndDemangleName(name3);
  return new Message(
    codeImplicitMixinOverride,
    problemMessage:
        """Applying the mixin '${name_0}' to '${name2_0}' introduces an erroneous override of '${name3_0}'.""",
    arguments: {'name': name, 'name2': name2, 'name3': name3},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldImplicitMixinOverride(
  String name,
  String name2,
  String name3,
) =>
    _withArgumentsImplicitMixinOverride(name: name, name2: name2, name3: name3);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type),
  Message Function({required DartType type})
>
codeImplicitReturnNull = const Template(
  "ImplicitReturnNull",
  problemMessageTemplate:
      r"""A non-null value must be returned since the return type '#type' doesn't allow null.""",
  withArgumentsOld: _withArgumentsOldImplicitReturnNull,
  withArguments: _withArgumentsImplicitReturnNull,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsImplicitReturnNull({required DartType type}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    codeImplicitReturnNull,
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
const MessageCode codeImplicitSuperCallOfNonMethod = const MessageCode(
  "ImplicitSuperCallOfNonMethod",
  problemMessage:
      r"""Cannot invoke `super` because it declares 'call' to be something other than a method.""",
  correctionMessage:
      r"""Try changing 'call' to a method or explicitly invoke 'call'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeImplicitSuperInitializerMissingArguments = const Template(
  "ImplicitSuperInitializerMissingArguments",
  problemMessageTemplate:
      r"""The implicitly called unnamed constructor from '#name' has required parameters.""",
  correctionMessageTemplate:
      r"""Try adding an explicit super initializer with the required arguments.""",
  withArgumentsOld: _withArgumentsOldImplicitSuperInitializerMissingArguments,
  withArguments: _withArgumentsImplicitSuperInitializerMissingArguments,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsImplicitSuperInitializerMissingArguments({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeImplicitSuperInitializerMissingArguments,
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
codeImportChainContext = const Template(
  "ImportChainContext",
  problemMessageTemplate:
      r"""The unavailable library '#uri' is imported through these packages:

#string
Detailed import paths for (some of) the these imports:

#string2""",
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
    codeImportChainContext,
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
codeImportChainContextSimple = const Template(
  "ImportChainContextSimple",
  problemMessageTemplate:
      r"""The unavailable library '#uri' is imported through these paths:

#string""",
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
    codeImportChainContextSimple,
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
codeIncompatibleRedirecteeFunctionType = const Template(
  "IncompatibleRedirecteeFunctionType",
  problemMessageTemplate:
      r"""The constructor function type '#type' isn't a subtype of '#type2'.""",
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
    codeIncompatibleRedirecteeFunctionType,
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
codeIncorrectTypeArgument = const Template(
  "IncorrectTypeArgument",
  problemMessageTemplate:
      r"""Type argument '#type' doesn't conform to the bound '#type2' of the type variable '#name' on '#name2'.""",
  correctionMessageTemplate:
      r"""Try changing type arguments so that they conform to the bounds.""",
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
    codeIncorrectTypeArgument,
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
codeIncorrectTypeArgumentInferred = const Template(
  "IncorrectTypeArgumentInferred",
  problemMessageTemplate:
      r"""Inferred type argument '#type' doesn't conform to the bound '#type2' of the type variable '#name' on '#name2'.""",
  correctionMessageTemplate:
      r"""Try specifying type arguments explicitly so that they conform to the bounds.""",
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
    codeIncorrectTypeArgumentInferred,
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
codeIncorrectTypeArgumentInstantiation = const Template(
  "IncorrectTypeArgumentInstantiation",
  problemMessageTemplate:
      r"""Type argument '#type' doesn't conform to the bound '#type2' of the type variable '#name' on '#type3'.""",
  correctionMessageTemplate:
      r"""Try changing type arguments so that they conform to the bounds.""",
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
    codeIncorrectTypeArgumentInstantiation,
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
codeIncorrectTypeArgumentInstantiationInferred = const Template(
  "IncorrectTypeArgumentInstantiationInferred",
  problemMessageTemplate:
      r"""Inferred type argument '#type' doesn't conform to the bound '#type2' of the type variable '#name' on '#type3'.""",
  correctionMessageTemplate:
      r"""Try specifying type arguments explicitly so that they conform to the bounds.""",
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
    codeIncorrectTypeArgumentInstantiationInferred,
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
codeIncorrectTypeArgumentQualified = const Template(
  "IncorrectTypeArgumentQualified",
  problemMessageTemplate:
      r"""Type argument '#type' doesn't conform to the bound '#type2' of the type variable '#name' on '#type3.#name2'.""",
  correctionMessageTemplate:
      r"""Try changing type arguments so that they conform to the bounds.""",
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
    codeIncorrectTypeArgumentQualified,
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
codeIncorrectTypeArgumentQualifiedInferred = const Template(
  "IncorrectTypeArgumentQualifiedInferred",
  problemMessageTemplate:
      r"""Inferred type argument '#type' doesn't conform to the bound '#type2' of the type variable '#name' on '#type3.#name2'.""",
  correctionMessageTemplate:
      r"""Try specifying type arguments explicitly so that they conform to the bounds.""",
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
    codeIncorrectTypeArgumentQualifiedInferred,
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
const MessageCode codeIncorrectTypeArgumentVariable = const MessageCode(
  "IncorrectTypeArgumentVariable",
  severity: CfeSeverity.context,
  problemMessage:
      r"""This is the type variable whose bound isn't conformed to.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string),
  Message Function({required String string})
>
codeIncrementalCompilerIllegalParameter = const Template(
  "IncrementalCompilerIllegalParameter",
  problemMessageTemplate:
      r"""Illegal parameter name '#string' found during expression compilation.""",
  withArgumentsOld: _withArgumentsOldIncrementalCompilerIllegalParameter,
  withArguments: _withArgumentsIncrementalCompilerIllegalParameter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIncrementalCompilerIllegalParameter({
  required String string,
}) {
  var string_0 = conversions.validateString(string);
  return new Message(
    codeIncrementalCompilerIllegalParameter,
    problemMessage:
        """Illegal parameter name '${string_0}' found during expression compilation.""",
    arguments: {'string': string},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldIncrementalCompilerIllegalParameter(String string) =>
    _withArgumentsIncrementalCompilerIllegalParameter(string: string);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string),
  Message Function({required String string})
>
codeIncrementalCompilerIllegalTypeParameter = const Template(
  "IncrementalCompilerIllegalTypeParameter",
  problemMessageTemplate:
      r"""Illegal type parameter name '#string' found during expression compilation.""",
  withArgumentsOld: _withArgumentsOldIncrementalCompilerIllegalTypeParameter,
  withArguments: _withArgumentsIncrementalCompilerIllegalTypeParameter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIncrementalCompilerIllegalTypeParameter({
  required String string,
}) {
  var string_0 = conversions.validateString(string);
  return new Message(
    codeIncrementalCompilerIllegalTypeParameter,
    problemMessage:
        """Illegal type parameter name '${string_0}' found during expression compilation.""",
    arguments: {'string': string},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldIncrementalCompilerIllegalTypeParameter(
  String string,
) => _withArgumentsIncrementalCompilerIllegalTypeParameter(string: string);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(int count, int count2, DartType type),
  Message Function({
    required int count,
    required int count2,
    required DartType type,
  })
>
codeIndexOutOfBoundInRecordIndexGet = const Template(
  "IndexOutOfBoundInRecordIndexGet",
  problemMessageTemplate:
      r"""Index #count is out of range 0..#count2 of positional fields of records #type.""",
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
    codeIndexOutOfBoundInRecordIndexGet,
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
const MessageCode codeInheritedMembersConflict = const MessageCode(
  "InheritedMembersConflict",
  problemMessage: r"""Can't inherit members that conflict with each other.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeInheritedMembersConflictCause1 = const MessageCode(
  "InheritedMembersConflictCause1",
  severity: CfeSeverity.context,
  problemMessage: r"""This is one inherited member.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeInheritedMembersConflictCause2 = const MessageCode(
  "InheritedMembersConflictCause2",
  severity: CfeSeverity.context,
  problemMessage: r"""This is the other inherited member.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, String name2),
  Message Function({required String name, required String name2})
>
codeInheritedRestrictedMemberOfEnumImplementer = const Template(
  "InheritedRestrictedMemberOfEnumImplementer",
  problemMessageTemplate:
      r"""A concrete instance member named '#name' can't be inherited from '#name2' in a class that implements 'Enum'.""",
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
    codeInheritedRestrictedMemberOfEnumImplementer,
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
codeInitializeFromDillNotSelfContained = const Template(
  "InitializeFromDillNotSelfContained",
  problemMessageTemplate:
      r"""Tried to initialize from a previous compilation (#string), but the file was not self-contained. This might be a bug.

The Dart team would greatly appreciate it if you would take a moment to report this problem at http://dartbug.com/new.
If you are comfortable with it, it would improve the chances of fixing any bug if you included the file #uri in your error report, but be aware that this file includes your source code.
Either way, you should probably delete the file so it doesn't use unnecessary disk space.""",
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
    codeInitializeFromDillNotSelfContained,
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
codeInitializeFromDillNotSelfContainedNoDump = const Template(
  "InitializeFromDillNotSelfContainedNoDump",
  problemMessageTemplate:
      r"""Tried to initialize from a previous compilation (#string), but the file was not self-contained. This might be a bug.

The Dart team would greatly appreciate it if you would take a moment to report this problem at http://dartbug.com/new.""",
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
    codeInitializeFromDillNotSelfContainedNoDump,
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
codeInitializeFromDillUnknownProblem = const Template(
  "InitializeFromDillUnknownProblem",
  problemMessageTemplate:
      r"""Tried to initialize from a previous compilation (#string), but couldn't.
Error message was '#string2'.
Stacktrace included '#string3'.
This might be a bug.

The Dart team would greatly appreciate it if you would take a moment to report this problem at http://dartbug.com/new.
If you are comfortable with it, it would improve the chances of fixing any bug if you included the file #uri in your error report, but be aware that this file includes your source code.
Either way, you should probably delete the file so it doesn't use unnecessary disk space.""",
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
    codeInitializeFromDillUnknownProblem,
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
codeInitializeFromDillUnknownProblemNoDump = const Template(
  "InitializeFromDillUnknownProblemNoDump",
  problemMessageTemplate:
      r"""Tried to initialize from a previous compilation (#string), but couldn't.
Error message was '#string2'.
Stacktrace included '#string3'.
This might be a bug.

The Dart team would greatly appreciate it if you would take a moment to report this problem at http://dartbug.com/new.""",
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
    codeInitializeFromDillUnknownProblemNoDump,
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
  Message Function(String name),
  Message Function({required String name})
>
codeInitializerForStaticField = const Template(
  "InitializerForStaticField",
  problemMessageTemplate: r"""'#name' isn't an instance field of this class.""",
  withArgumentsOld: _withArgumentsOldInitializerForStaticField,
  withArguments: _withArgumentsInitializerForStaticField,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInitializerForStaticField({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeInitializerForStaticField,
    problemMessage: """'${name_0}' isn't an instance field of this class.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInitializerForStaticField(String name) =>
    _withArgumentsInitializerForStaticField(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, DartType type, DartType type2),
  Message Function({
    required String name,
    required DartType type,
    required DartType type2,
  })
>
codeInitializingFormalTypeMismatch = const Template(
  "InitializingFormalTypeMismatch",
  problemMessageTemplate:
      r"""The type of parameter '#name', '#type' is not a subtype of the corresponding field's type, '#type2'.""",
  correctionMessageTemplate:
      r"""Try changing the type of parameter '#name' to a subtype of '#type2'.""",
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
    codeInitializingFormalTypeMismatch,
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
const MessageCode codeInitializingFormalTypeMismatchField = const MessageCode(
  "InitializingFormalTypeMismatchField",
  severity: CfeSeverity.context,
  problemMessage: r"""The field that corresponds to the parameter.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri), Message Function({required Uri uri})>
codeInputFileNotFound = const Template(
  "InputFileNotFound",
  problemMessageTemplate: r"""Input file not found: #uri.""",
  withArgumentsOld: _withArgumentsOldInputFileNotFound,
  withArguments: _withArgumentsInputFileNotFound,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInputFileNotFound({required Uri uri}) {
  var uri_0 = conversions.relativizeUri(uri);
  return new Message(
    codeInputFileNotFound,
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
codeInstanceAndSynthesizedStaticConflict = const Template(
  "InstanceAndSynthesizedStaticConflict",
  problemMessageTemplate:
      r"""This instance member conflicts with the synthesized static member called '#name'.""",
  withArgumentsOld: _withArgumentsOldInstanceAndSynthesizedStaticConflict,
  withArguments: _withArgumentsInstanceAndSynthesizedStaticConflict,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInstanceAndSynthesizedStaticConflict({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeInstanceAndSynthesizedStaticConflict,
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
  Message Function(String name),
  Message Function({required String name})
>
codeInstanceConflictsWithStatic = const Template(
  "InstanceConflictsWithStatic",
  problemMessageTemplate:
      r"""Instance property '#name' conflicts with static property of the same name.""",
  withArgumentsOld: _withArgumentsOldInstanceConflictsWithStatic,
  withArguments: _withArgumentsInstanceConflictsWithStatic,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInstanceConflictsWithStatic({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeInstanceConflictsWithStatic,
    problemMessage:
        """Instance property '${name_0}' conflicts with static property of the same name.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInstanceConflictsWithStatic(String name) =>
    _withArgumentsInstanceConflictsWithStatic(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeInstanceConflictsWithStaticCause = const Template(
  "InstanceConflictsWithStaticCause",
  problemMessageTemplate: r"""Conflicting static property '#name'.""",
  withArgumentsOld: _withArgumentsOldInstanceConflictsWithStaticCause,
  withArguments: _withArgumentsInstanceConflictsWithStaticCause,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInstanceConflictsWithStaticCause({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeInstanceConflictsWithStaticCause,
    problemMessage: """Conflicting static property '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInstanceConflictsWithStaticCause(String name) =>
    _withArgumentsInstanceConflictsWithStaticCause(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type),
  Message Function({required DartType type})
>
codeInstantiationNonGenericFunctionType = const Template(
  "InstantiationNonGenericFunctionType",
  problemMessageTemplate:
      r"""The static type of the explicit instantiation operand must be a generic function type but is '#type'.""",
  correctionMessageTemplate:
      r"""Try changing the operand or remove the type arguments.""",
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
    codeInstantiationNonGenericFunctionType,
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
codeInstantiationNullableGenericFunctionType = const Template(
  "InstantiationNullableGenericFunctionType",
  problemMessageTemplate:
      r"""The static type of the explicit instantiation operand must be a non-null generic function type but is '#type'.""",
  correctionMessageTemplate:
      r"""Try changing the operand or remove the type arguments.""",
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
    codeInstantiationNullableGenericFunctionType,
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
codeInstantiationTooFewArguments = const Template(
  "InstantiationTooFewArguments",
  problemMessageTemplate:
      r"""Too few type arguments: #count required, #count2 given.""",
  correctionMessageTemplate: r"""Try adding the missing type arguments.""",
  withArgumentsOld: _withArgumentsOldInstantiationTooFewArguments,
  withArguments: _withArgumentsInstantiationTooFewArguments,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInstantiationTooFewArguments({
  required int count,
  required int count2,
}) {
  return new Message(
    codeInstantiationTooFewArguments,
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
codeInstantiationTooManyArguments = const Template(
  "InstantiationTooManyArguments",
  problemMessageTemplate:
      r"""Too many type arguments: #count allowed, but #count2 found.""",
  correctionMessageTemplate: r"""Try removing the extra type arguments.""",
  withArgumentsOld: _withArgumentsOldInstantiationTooManyArguments,
  withArguments: _withArgumentsInstantiationTooManyArguments,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInstantiationTooManyArguments({
  required int count,
  required int count2,
}) {
  return new Message(
    codeInstantiationTooManyArguments,
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
codeIntegerLiteralIsOutOfRange = const Template(
  "IntegerLiteralIsOutOfRange",
  problemMessageTemplate:
      r"""The integer literal #string can't be represented in 64 bits.""",
  correctionMessageTemplate:
      r"""Try using the BigInt class if you need an integer larger than 9,223,372,036,854,775,807 or less than -9,223,372,036,854,775,808.""",
  withArgumentsOld: _withArgumentsOldIntegerLiteralIsOutOfRange,
  withArguments: _withArgumentsIntegerLiteralIsOutOfRange,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIntegerLiteralIsOutOfRange({required String string}) {
  var string_0 = conversions.validateString(string);
  return new Message(
    codeIntegerLiteralIsOutOfRange,
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
  Message Function(String name, String name2),
  Message Function({required String name, required String name2})
>
codeInterfaceCheck = const Template(
  "InterfaceCheck",
  problemMessageTemplate:
      r"""The implementation of '#name' in the non-abstract class '#name2' does not conform to its interface.""",
  withArgumentsOld: _withArgumentsOldInterfaceCheck,
  withArguments: _withArgumentsInterfaceCheck,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInterfaceCheck({
  required String name,
  required String name2,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var name2_0 = conversions.validateAndDemangleName(name2);
  return new Message(
    codeInterfaceCheck,
    problemMessage:
        """The implementation of '${name_0}' in the non-abstract class '${name2_0}' does not conform to its interface.""",
    arguments: {'name': name, 'name2': name2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInterfaceCheck(String name, String name2) =>
    _withArgumentsInterfaceCheck(name: name, name2: name2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeInterfaceClassExtendedOutsideOfLibrary = const Template(
  "InterfaceClassExtendedOutsideOfLibrary",
  problemMessageTemplate:
      r"""The class '#name' can't be extended outside of its library because it's an interface class.""",
  withArgumentsOld: _withArgumentsOldInterfaceClassExtendedOutsideOfLibrary,
  withArguments: _withArgumentsInterfaceClassExtendedOutsideOfLibrary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInterfaceClassExtendedOutsideOfLibrary({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeInterfaceClassExtendedOutsideOfLibrary,
    problemMessage:
        """The class '${name_0}' can't be extended outside of its library because it's an interface class.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInterfaceClassExtendedOutsideOfLibrary(String name) =>
    _withArgumentsInterfaceClassExtendedOutsideOfLibrary(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeInternalProblemAlreadyInitialized = const MessageCode(
  "InternalProblemAlreadyInitialized",
  severity: CfeSeverity.internalProblem,
  problemMessage:
      r"""Attempt to set initializer on field without initializer.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeInternalProblemBodyOnAbstractMethod = const MessageCode(
  "InternalProblemBodyOnAbstractMethod",
  severity: CfeSeverity.internalProblem,
  problemMessage: r"""Attempting to set body on abstract method.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, Uri uri),
  Message Function({required String name, required Uri uri})
>
codeInternalProblemConstructorNotFound = const Template(
  "InternalProblemConstructorNotFound",
  problemMessageTemplate: r"""No constructor named '#name' in '#uri'.""",
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
    codeInternalProblemConstructorNotFound,
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
  Message Function(String string),
  Message Function({required String string})
>
codeInternalProblemContextSeverity = const Template(
  "InternalProblemContextSeverity",
  problemMessageTemplate:
      r"""Non-context message has context severity: #string""",
  withArgumentsOld: _withArgumentsOldInternalProblemContextSeverity,
  withArguments: _withArgumentsInternalProblemContextSeverity,
  severity: CfeSeverity.internalProblem,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemContextSeverity({required String string}) {
  var string_0 = conversions.validateString(string);
  return new Message(
    codeInternalProblemContextSeverity,
    problemMessage: """Non-context message has context severity: ${string_0}""",
    arguments: {'string': string},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInternalProblemContextSeverity(String string) =>
    _withArgumentsInternalProblemContextSeverity(string: string);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, String string),
  Message Function({required String name, required String string})
>
codeInternalProblemDebugAbort = const Template(
  "InternalProblemDebugAbort",
  problemMessageTemplate: r"""Compilation aborted due to fatal '#name' at:
#string""",
  withArgumentsOld: _withArgumentsOldInternalProblemDebugAbort,
  withArguments: _withArgumentsInternalProblemDebugAbort,
  severity: CfeSeverity.internalProblem,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemDebugAbort({
  required String name,
  required String string,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var string_0 = conversions.validateString(string);
  return new Message(
    codeInternalProblemDebugAbort,
    problemMessage: """Compilation aborted due to fatal '${name_0}' at:
${string_0}""",
    arguments: {'name': name, 'string': string},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInternalProblemDebugAbort(
  String name,
  String string,
) => _withArgumentsInternalProblemDebugAbort(name: name, string: string);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeInternalProblemExtendingUnmodifiableScope =
    const MessageCode(
      "InternalProblemExtendingUnmodifiableScope",
      severity: CfeSeverity.internalProblem,
      problemMessage: r"""Can't extend an unmodifiable scope.""",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeInternalProblemLabelUsageInVariablesDeclaration =
    const MessageCode(
      "InternalProblemLabelUsageInVariablesDeclaration",
      severity: CfeSeverity.internalProblem,
      problemMessage:
          r"""Unexpected usage of label inside declaration of variables.""",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeInternalProblemMissingContext = const MessageCode(
  "InternalProblemMissingContext",
  severity: CfeSeverity.internalProblem,
  problemMessage: r"""Compiler cannot run without a compiler context.""",
  correctionMessage:
      r"""Are calls to the compiler wrapped in CompilerContext.runInContext?""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeInternalProblemNotFound = const Template(
  "InternalProblemNotFound",
  problemMessageTemplate: r"""Couldn't find '#name'.""",
  withArgumentsOld: _withArgumentsOldInternalProblemNotFound,
  withArguments: _withArgumentsInternalProblemNotFound,
  severity: CfeSeverity.internalProblem,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemNotFound({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeInternalProblemNotFound,
    problemMessage: """Couldn't find '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInternalProblemNotFound(String name) =>
    _withArgumentsInternalProblemNotFound(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, String name2),
  Message Function({required String name, required String name2})
>
codeInternalProblemNotFoundIn = const Template(
  "InternalProblemNotFoundIn",
  problemMessageTemplate: r"""Couldn't find '#name' in '#name2'.""",
  withArgumentsOld: _withArgumentsOldInternalProblemNotFoundIn,
  withArguments: _withArgumentsInternalProblemNotFoundIn,
  severity: CfeSeverity.internalProblem,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemNotFoundIn({
  required String name,
  required String name2,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var name2_0 = conversions.validateAndDemangleName(name2);
  return new Message(
    codeInternalProblemNotFoundIn,
    problemMessage: """Couldn't find '${name_0}' in '${name2_0}'.""",
    arguments: {'name': name, 'name2': name2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInternalProblemNotFoundIn(String name, String name2) =>
    _withArgumentsInternalProblemNotFoundIn(name: name, name2: name2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
codeInternalProblemOmittedTypeNameInConstructorReference = const MessageCode(
  "InternalProblemOmittedTypeNameInConstructorReference",
  severity: CfeSeverity.internalProblem,
  problemMessage:
      r"""Unsupported omission of the type name in a constructor reference outside of an enum element declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeInternalProblemPreviousTokenNotFound = const MessageCode(
  "InternalProblemPreviousTokenNotFound",
  severity: CfeSeverity.internalProblem,
  problemMessage: r"""Couldn't find previous token.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeInternalProblemPrivateConstructorAccess = const Template(
  "InternalProblemPrivateConstructorAccess",
  problemMessageTemplate: r"""Can't access private constructor '#name'.""",
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
    codeInternalProblemPrivateConstructorAccess,
    problemMessage: """Can't access private constructor '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInternalProblemPrivateConstructorAccess(String name) =>
    _withArgumentsInternalProblemPrivateConstructorAccess(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeInternalProblemProvidedBothCompileSdkAndSdkSummary =
    const MessageCode(
      "InternalProblemProvidedBothCompileSdkAndSdkSummary",
      severity: CfeSeverity.internalProblem,
      problemMessage:
          r"""The compileSdk and sdkSummary options are mutually exclusive""",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string, String string2),
  Message Function({required String string, required String string2})
>
codeInternalProblemUnexpected = const Template(
  "InternalProblemUnexpected",
  problemMessageTemplate: r"""Expected '#string', but got '#string2'.""",
  withArgumentsOld: _withArgumentsOldInternalProblemUnexpected,
  withArguments: _withArgumentsInternalProblemUnexpected,
  severity: CfeSeverity.internalProblem,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemUnexpected({
  required String string,
  required String string2,
}) {
  var string_0 = conversions.validateString(string);
  var string2_0 = conversions.validateString(string2);
  return new Message(
    codeInternalProblemUnexpected,
    problemMessage: """Expected '${string_0}', but got '${string2_0}'.""",
    arguments: {'string': string, 'string2': string2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInternalProblemUnexpected(
  String string,
  String string2,
) => _withArgumentsInternalProblemUnexpected(string: string, string2: string2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string),
  Message Function({required String string})
>
codeInternalProblemUnimplemented = const Template(
  "InternalProblemUnimplemented",
  problemMessageTemplate: r"""Unimplemented #string.""",
  withArgumentsOld: _withArgumentsOldInternalProblemUnimplemented,
  withArguments: _withArgumentsInternalProblemUnimplemented,
  severity: CfeSeverity.internalProblem,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemUnimplemented({required String string}) {
  var string_0 = conversions.validateString(string);
  return new Message(
    codeInternalProblemUnimplemented,
    problemMessage: """Unimplemented ${string_0}.""",
    arguments: {'string': string},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInternalProblemUnimplemented(String string) =>
    _withArgumentsInternalProblemUnimplemented(string: string);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string, DartType type),
  Message Function({required String string, required DartType type})
>
codeInternalProblemUnsupportedNullability = const Template(
  "InternalProblemUnsupportedNullability",
  problemMessageTemplate:
      r"""Unsupported nullability value '#string' on type '#type'.""",
  withArgumentsOld: _withArgumentsOldInternalProblemUnsupportedNullability,
  withArguments: _withArgumentsInternalProblemUnsupportedNullability,
  severity: CfeSeverity.internalProblem,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemUnsupportedNullability({
  required String string,
  required DartType type,
}) {
  var string_0 = conversions.validateString(string);
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    codeInternalProblemUnsupportedNullability,
    problemMessage:
        """Unsupported nullability value '${string_0}' on type '${type_0}'.""" +
        labeler.originMessages,
    arguments: {'string': string, 'type': type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInternalProblemUnsupportedNullability(
  String string,
  DartType type,
) => _withArgumentsInternalProblemUnsupportedNullability(
  string: string,
  type: type,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri), Message Function({required Uri uri})>
codeInternalProblemUriMissingScheme = const Template(
  "InternalProblemUriMissingScheme",
  problemMessageTemplate: r"""The URI '#uri' has no scheme.""",
  withArgumentsOld: _withArgumentsOldInternalProblemUriMissingScheme,
  withArguments: _withArgumentsInternalProblemUriMissingScheme,
  severity: CfeSeverity.internalProblem,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemUriMissingScheme({required Uri uri}) {
  var uri_0 = conversions.relativizeUri(uri);
  return new Message(
    codeInternalProblemUriMissingScheme,
    problemMessage: """The URI '${uri_0}' has no scheme.""",
    arguments: {'uri': uri},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInternalProblemUriMissingScheme(Uri uri) =>
    _withArgumentsInternalProblemUriMissingScheme(uri: uri);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string),
  Message Function({required String string})
>
codeInternalProblemVerificationError = const Template(
  "InternalProblemVerificationError",
  problemMessageTemplate: r"""Verification of the generated program failed:
#string""",
  withArgumentsOld: _withArgumentsOldInternalProblemVerificationError,
  withArguments: _withArgumentsInternalProblemVerificationError,
  severity: CfeSeverity.internalProblem,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemVerificationError({
  required String string,
}) {
  var string_0 = conversions.validateString(string);
  return new Message(
    codeInternalProblemVerificationError,
    problemMessage: """Verification of the generated program failed:
${string_0}""",
    arguments: {'string': string},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInternalProblemVerificationError(String string) =>
    _withArgumentsInternalProblemVerificationError(string: string);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type, DartType type2),
  Message Function({required DartType type, required DartType type2})
>
codeInvalidAssignmentError = const Template(
  "InvalidAssignmentError",
  problemMessageTemplate:
      r"""A value of type '#type' can't be assigned to a variable of type '#type2'.""",
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
    codeInvalidAssignmentError,
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
const MessageCode codeInvalidAugmentSuper = const MessageCode(
  "InvalidAugmentSuper",
  problemMessage:
      r"""'augment super' is only allowed in member augmentations.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeInvalidBreakTarget = const Template(
  "InvalidBreakTarget",
  problemMessageTemplate: r"""Can't break to '#name'.""",
  withArgumentsOld: _withArgumentsOldInvalidBreakTarget,
  withArguments: _withArgumentsInvalidBreakTarget,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidBreakTarget({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeInvalidBreakTarget,
    problemMessage: """Can't break to '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidBreakTarget(String name) =>
    _withArgumentsInvalidBreakTarget(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type, DartType type2),
  Message Function({required DartType type, required DartType type2})
>
codeInvalidCastFunctionExpr = const Template(
  "InvalidCastFunctionExpr",
  problemMessageTemplate:
      r"""The function expression type '#type' isn't of expected type '#type2'.""",
  correctionMessageTemplate:
      r"""Change the type of the function expression or the context in which it is used.""",
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
    codeInvalidCastFunctionExpr,
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
codeInvalidCastLiteralList = const Template(
  "InvalidCastLiteralList",
  problemMessageTemplate:
      r"""The list literal type '#type' isn't of expected type '#type2'.""",
  correctionMessageTemplate:
      r"""Change the type of the list literal or the context in which it is used.""",
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
    codeInvalidCastLiteralList,
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
codeInvalidCastLiteralMap = const Template(
  "InvalidCastLiteralMap",
  problemMessageTemplate:
      r"""The map literal type '#type' isn't of expected type '#type2'.""",
  correctionMessageTemplate:
      r"""Change the type of the map literal or the context in which it is used.""",
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
    codeInvalidCastLiteralMap,
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
codeInvalidCastLiteralSet = const Template(
  "InvalidCastLiteralSet",
  problemMessageTemplate:
      r"""The set literal type '#type' isn't of expected type '#type2'.""",
  correctionMessageTemplate:
      r"""Change the type of the set literal or the context in which it is used.""",
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
    codeInvalidCastLiteralSet,
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
codeInvalidCastLocalFunction = const Template(
  "InvalidCastLocalFunction",
  problemMessageTemplate:
      r"""The local function has type '#type' that isn't of expected type '#type2'.""",
  correctionMessageTemplate:
      r"""Change the type of the function or the context in which it is used.""",
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
    codeInvalidCastLocalFunction,
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
codeInvalidCastNewExpr = const Template(
  "InvalidCastNewExpr",
  problemMessageTemplate:
      r"""The constructor returns type '#type' that isn't of expected type '#type2'.""",
  correctionMessageTemplate:
      r"""Change the type of the object being constructed or the context in which it is used.""",
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
    codeInvalidCastNewExpr,
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
codeInvalidCastStaticMethod = const Template(
  "InvalidCastStaticMethod",
  problemMessageTemplate:
      r"""The static method has type '#type' that isn't of expected type '#type2'.""",
  correctionMessageTemplate:
      r"""Change the type of the method or the context in which it is used.""",
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
    codeInvalidCastStaticMethod,
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
codeInvalidCastTopLevelFunction = const Template(
  "InvalidCastTopLevelFunction",
  problemMessageTemplate:
      r"""The top level function has type '#type' that isn't of expected type '#type2'.""",
  correctionMessageTemplate:
      r"""Change the type of the function or the context in which it is used.""",
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
    codeInvalidCastTopLevelFunction,
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
  Message Function(String name),
  Message Function({required String name})
>
codeInvalidContinueTarget = const Template(
  "InvalidContinueTarget",
  problemMessageTemplate: r"""Can't continue at '#name'.""",
  withArgumentsOld: _withArgumentsOldInvalidContinueTarget,
  withArguments: _withArgumentsInvalidContinueTarget,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidContinueTarget({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeInvalidContinueTarget,
    problemMessage: """Can't continue at '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidContinueTarget(String name) =>
    _withArgumentsInvalidContinueTarget(name: name);

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
codeInvalidExtensionTypeSuperExtensionType = const Template(
  "InvalidExtensionTypeSuperExtensionType",
  problemMessageTemplate:
      r"""The representation type '#type' of extension type '#name' must be either a subtype of the representation type '#type2' of the implemented extension type '#type3' or a subtype of '#type3' itself.""",
  correctionMessageTemplate:
      r"""Try changing the representation type to a subtype of '#type2'.""",
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
    codeInvalidExtensionTypeSuperExtensionType,
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
codeInvalidExtensionTypeSuperInterface = const Template(
  "InvalidExtensionTypeSuperInterface",
  problemMessageTemplate:
      r"""The implemented interface '#type' must be a supertype of the representation type '#type2' of extension type '#name'.""",
  correctionMessageTemplate:
      r"""Try changing the interface type to a supertype of '#type2' or the representation type to a subtype of '#type'.""",
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
    codeInvalidExtensionTypeSuperInterface,
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
  Message Function(DartType type, String name, DartType type2, String name2),
  Message Function({
    required DartType type,
    required String name,
    required DartType type2,
    required String name2,
  })
>
codeInvalidGetterSetterType = const Template(
  "InvalidGetterSetterType",
  problemMessageTemplate:
      r"""The type '#type' of the getter '#name' is not a subtype of the type '#type2' of the setter '#name2'.""",
  withArgumentsOld: _withArgumentsOldInvalidGetterSetterType,
  withArguments: _withArgumentsInvalidGetterSetterType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidGetterSetterType({
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
    codeInvalidGetterSetterType,
    problemMessage:
        """The type '${type_0}' of the getter '${name_0}' is not a subtype of the type '${type2_0}' of the setter '${name2_0}'.""" +
        labeler.originMessages,
    arguments: {'type': type, 'name': name, 'type2': type2, 'name2': name2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidGetterSetterType(
  DartType type,
  String name,
  DartType type2,
  String name2,
) => _withArgumentsInvalidGetterSetterType(
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
codeInvalidGetterSetterTypeBothInheritedField = const Template(
  "InvalidGetterSetterTypeBothInheritedField",
  problemMessageTemplate:
      r"""The type '#type' of the inherited field '#name' is not a subtype of the type '#type2' of the inherited setter '#name2'.""",
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
    codeInvalidGetterSetterTypeBothInheritedField,
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
codeInvalidGetterSetterTypeBothInheritedGetter = const Template(
  "InvalidGetterSetterTypeBothInheritedGetter",
  problemMessageTemplate:
      r"""The type '#type' of the inherited getter '#name' is not a subtype of the type '#type2' of the inherited setter '#name2'.""",
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
    codeInvalidGetterSetterTypeBothInheritedGetter,
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
codeInvalidGetterSetterTypeFieldContext = const Template(
  "InvalidGetterSetterTypeFieldContext",
  problemMessageTemplate: r"""This is the declaration of the field '#name'.""",
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
    codeInvalidGetterSetterTypeFieldContext,
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
codeInvalidGetterSetterTypeFieldInherited = const Template(
  "InvalidGetterSetterTypeFieldInherited",
  problemMessageTemplate:
      r"""The type '#type' of the inherited field '#name' is not a subtype of the type '#type2' of the setter '#name2'.""",
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
    codeInvalidGetterSetterTypeFieldInherited,
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
codeInvalidGetterSetterTypeGetterContext = const Template(
  "InvalidGetterSetterTypeGetterContext",
  problemMessageTemplate: r"""This is the declaration of the getter '#name'.""",
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
    codeInvalidGetterSetterTypeGetterContext,
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
codeInvalidGetterSetterTypeGetterInherited = const Template(
  "InvalidGetterSetterTypeGetterInherited",
  problemMessageTemplate:
      r"""The type '#type' of the inherited getter '#name' is not a subtype of the type '#type2' of the setter '#name2'.""",
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
    codeInvalidGetterSetterTypeGetterInherited,
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
  Message Function(String name),
  Message Function({required String name})
>
codeInvalidGetterSetterTypeSetterContext = const Template(
  "InvalidGetterSetterTypeSetterContext",
  problemMessageTemplate: r"""This is the declaration of the setter '#name'.""",
  withArgumentsOld: _withArgumentsOldInvalidGetterSetterTypeSetterContext,
  withArguments: _withArgumentsInvalidGetterSetterTypeSetterContext,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidGetterSetterTypeSetterContext({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeInvalidGetterSetterTypeSetterContext,
    problemMessage: """This is the declaration of the setter '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidGetterSetterTypeSetterContext(String name) =>
    _withArgumentsInvalidGetterSetterTypeSetterContext(name: name);

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
codeInvalidGetterSetterTypeSetterInheritedField = const Template(
  "InvalidGetterSetterTypeSetterInheritedField",
  problemMessageTemplate:
      r"""The type '#type' of the field '#name' is not a subtype of the type '#type2' of the inherited setter '#name2'.""",
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
    codeInvalidGetterSetterTypeSetterInheritedField,
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
codeInvalidGetterSetterTypeSetterInheritedGetter = const Template(
  "InvalidGetterSetterTypeSetterInheritedGetter",
  problemMessageTemplate:
      r"""The type '#type' of the getter '#name' is not a subtype of the type '#type2' of the inherited setter '#name2'.""",
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
    codeInvalidGetterSetterTypeSetterInheritedGetter,
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
codeInvalidPackageUri = const Template(
  "InvalidPackageUri",
  problemMessageTemplate: r"""Invalid package URI '#uri':
  #string.""",
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
    codeInvalidPackageUri,
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
codeInvalidReturn = const Template(
  "InvalidReturn",
  problemMessageTemplate:
      r"""A value of type '#type' can't be returned from a function with return type '#type2'.""",
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
    codeInvalidReturn,
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
codeInvalidReturnAsync = const Template(
  "InvalidReturnAsync",
  problemMessageTemplate:
      r"""A value of type '#type' can't be returned from an async function with return type '#type2'.""",
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
    codeInvalidReturnAsync,
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
codeInvalidTypeParameterInSupertype = const Template(
  "InvalidTypeParameterInSupertype",
  problemMessageTemplate:
      r"""Can't use implicitly 'out' variable '#name' in an '#string2' position in supertype '#name2'.""",
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
    codeInvalidTypeParameterInSupertype,
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
codeInvalidTypeParameterInSupertypeWithVariance = const Template(
  "InvalidTypeParameterInSupertypeWithVariance",
  problemMessageTemplate:
      r"""Can't use '#string' type variable '#name' in an '#string2' position in supertype '#name2'.""",
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
    codeInvalidTypeParameterInSupertypeWithVariance,
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
codeInvalidTypeParameterVariancePosition = const Template(
  "InvalidTypeParameterVariancePosition",
  problemMessageTemplate:
      r"""Can't use '#string' type variable '#name' in an '#string2' position.""",
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
    codeInvalidTypeParameterVariancePosition,
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
codeInvalidTypeParameterVariancePositionInReturnType = const Template(
  "InvalidTypeParameterVariancePositionInReturnType",
  problemMessageTemplate:
      r"""Can't use '#string' type variable '#name' in an '#string2' position in the return type.""",
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
    codeInvalidTypeParameterVariancePositionInReturnType,
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
const MessageCode codeInvalidUseOfNullAwareAccess = const MessageCode(
  "InvalidUseOfNullAwareAccess",
  problemMessage: r"""Cannot use '?.' here.""",
  correctionMessage: r"""Try using '.'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeInvokeNonFunction = const Template(
  "InvokeNonFunction",
  problemMessageTemplate:
      r"""'#name' isn't a function or method and can't be invoked.""",
  withArgumentsOld: _withArgumentsOldInvokeNonFunction,
  withArguments: _withArgumentsInvokeNonFunction,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvokeNonFunction({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeInvokeNonFunction,
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
codeJointPatternVariableNotInAll = const Template(
  "JointPatternVariableNotInAll",
  problemMessageTemplate:
      r"""The variable '#name' is available in some, but not all cases that share this body.""",
  withArgumentsOld: _withArgumentsOldJointPatternVariableNotInAll,
  withArguments: _withArgumentsJointPatternVariableNotInAll,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJointPatternVariableNotInAll({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeJointPatternVariableNotInAll,
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
codeJointPatternVariableWithLabelDefault = const Template(
  "JointPatternVariableWithLabelDefault",
  problemMessageTemplate:
      r"""The variable '#name' is not available because there is a label or 'default' case.""",
  withArgumentsOld: _withArgumentsOldJointPatternVariableWithLabelDefault,
  withArguments: _withArgumentsJointPatternVariableWithLabelDefault,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJointPatternVariableWithLabelDefault({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeJointPatternVariableWithLabelDefault,
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
codeJointPatternVariablesMismatch = const Template(
  "JointPatternVariablesMismatch",
  problemMessageTemplate:
      r"""Variable pattern '#name' doesn't have the same type or finality in all cases.""",
  withArgumentsOld: _withArgumentsOldJointPatternVariablesMismatch,
  withArguments: _withArgumentsJointPatternVariablesMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJointPatternVariablesMismatch({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeJointPatternVariablesMismatch,
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
codeJsInteropDartClassExtendsJSClass = const Template(
  "JsInteropDartClassExtendsJSClass",
  problemMessageTemplate:
      r"""Dart class '#name' cannot extend JS interop class '#name2'.""",
  correctionMessageTemplate:
      r"""Try adding the JS interop annotation or removing it from the parent class.""",
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
    codeJsInteropDartClassExtendsJSClass,
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
codeJsInteropDartJsInteropAnnotationForStaticInteropOnly = const MessageCode(
  "JsInteropDartJsInteropAnnotationForStaticInteropOnly",
  problemMessage:
      r"""The '@JS' annotation from 'dart:js_interop' can only be used for static interop, either through extension types or '@staticInterop' classes.""",
  correctionMessage:
      r"""Try making this class an extension type or marking it as '@staticInterop'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeJsInteropDisallowedInteropLibraryInDart2Wasm = const Template(
  "JsInteropDisallowedInteropLibraryInDart2Wasm",
  problemMessageTemplate:
      r"""JS interop library '#name' can't be imported when compiling to Wasm.""",
  correctionMessageTemplate:
      r"""Try using 'dart:js_interop' or 'dart:js_interop_unsafe' instead.""",
  withArgumentsOld:
      _withArgumentsOldJsInteropDisallowedInteropLibraryInDart2Wasm,
  withArguments: _withArgumentsJsInteropDisallowedInteropLibraryInDart2Wasm,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropDisallowedInteropLibraryInDart2Wasm({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeJsInteropDisallowedInteropLibraryInDart2Wasm,
    problemMessage:
        """JS interop library '${name_0}' can't be imported when compiling to Wasm.""",
    correctionMessage:
        """Try using 'dart:js_interop' or 'dart:js_interop_unsafe' instead.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldJsInteropDisallowedInteropLibraryInDart2Wasm(
  String name,
) => _withArgumentsJsInteropDisallowedInteropLibraryInDart2Wasm(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeJsInteropEnclosingClassJSAnnotation = const MessageCode(
  "JsInteropEnclosingClassJSAnnotation",
  problemMessage:
      r"""Member has a JS interop annotation but the enclosing class does not.""",
  correctionMessage: r"""Try adding the annotation to the enclosing class.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeJsInteropEnclosingClassJSAnnotationContext =
    const MessageCode(
      "JsInteropEnclosingClassJSAnnotationContext",
      severity: CfeSeverity.context,
      problemMessage: r"""This is the enclosing class.""",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeJsInteropExportClassNotMarkedExportable = const Template(
  "JsInteropExportClassNotMarkedExportable",
  problemMessageTemplate:
      r"""Class '#name' does not have a `@JSExport` on it or any of its members.""",
  correctionMessageTemplate:
      r"""Use the `@JSExport` annotation on this class.""",
  withArgumentsOld: _withArgumentsOldJsInteropExportClassNotMarkedExportable,
  withArguments: _withArgumentsJsInteropExportClassNotMarkedExportable,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropExportClassNotMarkedExportable({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeJsInteropExportClassNotMarkedExportable,
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
codeJsInteropExportDartInterfaceHasNonEmptyJSExportValue = const Template(
  "JsInteropExportDartInterfaceHasNonEmptyJSExportValue",
  problemMessageTemplate:
      r"""The value in the `@JSExport` annotation on the class or mixin '#name' will be ignored.""",
  correctionMessageTemplate: r"""Remove the value in the annotation.""",
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
    codeJsInteropExportDartInterfaceHasNonEmptyJSExportValue,
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
codeJsInteropExportDisallowedMember = const Template(
  "JsInteropExportDisallowedMember",
  problemMessageTemplate:
      r"""Member '#name' is not a concrete instance member or declares type parameters, and therefore can't be exported.""",
  correctionMessageTemplate:
      r"""Remove the `@JSExport` annotation from the member, and use an instance member to call this member instead.""",
  withArgumentsOld: _withArgumentsOldJsInteropExportDisallowedMember,
  withArguments: _withArgumentsJsInteropExportDisallowedMember,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropExportDisallowedMember({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeJsInteropExportDisallowedMember,
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
codeJsInteropExportInvalidInteropTypeArgument = const Template(
  "JsInteropExportInvalidInteropTypeArgument",
  problemMessageTemplate:
      r"""Type argument '#type' needs to be a non-JS interop type.""",
  correctionMessageTemplate:
      r"""Use a non-JS interop class that uses `@JSExport` instead.""",
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
    codeJsInteropExportInvalidInteropTypeArgument,
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
codeJsInteropExportInvalidTypeArgument = const Template(
  "JsInteropExportInvalidTypeArgument",
  problemMessageTemplate:
      r"""Type argument '#type' needs to be an interface type.""",
  correctionMessageTemplate:
      r"""Use a non-JS interop class that uses `@JSExport` instead.""",
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
    codeJsInteropExportInvalidTypeArgument,
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
codeJsInteropExportMemberCollision = const Template(
  "JsInteropExportMemberCollision",
  problemMessageTemplate:
      r"""The following class members collide with the same export '#name': #string.""",
  correctionMessageTemplate:
      r"""Either remove the conflicting members or use a different export name.""",
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
    codeJsInteropExportMemberCollision,
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
codeJsInteropExportNoExportableMembers = const Template(
  "JsInteropExportNoExportableMembers",
  problemMessageTemplate:
      r"""Class '#name' has no exportable members in the class or the inheritance chain.""",
  correctionMessageTemplate:
      r"""Using `@JSExport`, annotate at least one instance member with a body or annotate a class that has such a member in the inheritance chain.""",
  withArgumentsOld: _withArgumentsOldJsInteropExportNoExportableMembers,
  withArguments: _withArgumentsJsInteropExportNoExportableMembers,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropExportNoExportableMembers({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeJsInteropExportNoExportableMembers,
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
const MessageCode
codeJsInteropExtensionTypeMemberNotInterop = const MessageCode(
  "JsInteropExtensionTypeMemberNotInterop",
  problemMessage:
      r"""Extension type member is marked 'external', but the representation type of its extension type is not a valid JS interop type.""",
  correctionMessage:
      r"""Try declaring a valid JS interop representation type, which may include 'dart:js_interop' types, '@staticInterop' types, 'dart:html' types, or other interop extension types.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, DartType type),
  Message Function({required String name, required DartType type})
>
codeJsInteropExtensionTypeNotInterop = const Template(
  "JsInteropExtensionTypeNotInterop",
  problemMessageTemplate:
      r"""Extension type '#name' is marked with a '@JS' annotation, but its representation type is not a valid JS interop type: '#type'.""",
  correctionMessageTemplate:
      r"""Try declaring a valid JS interop representation type, which may include 'dart:js_interop' types, '@staticInterop' types, 'dart:html' types, or other interop extension types.""",
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
    codeJsInteropExtensionTypeNotInterop,
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
codeJsInteropExtensionTypeUsedWithWrongJsAnnotation = const MessageCode(
  "JsInteropExtensionTypeUsedWithWrongJsAnnotation",
  problemMessage:
      r"""Extension types should use the '@JS' annotation from 'dart:js_interop' and not from 'package:js'.""",
  correctionMessage:
      r"""Try using the '@JS' annotation from 'dart:js_interop' annotation on this extension type instead.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
codeJsInteropExternalExtensionMemberOnTypeInvalid = const MessageCode(
  "JsInteropExternalExtensionMemberOnTypeInvalid",
  problemMessage:
      r"""JS interop type or @Native type from an SDK web library required for 'external' extension members.""",
  correctionMessage:
      r"""Try making the on-type a JS interop type or an @Native SDK web library type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
codeJsInteropExternalExtensionMemberWithStaticDisallowed = const MessageCode(
  "JsInteropExternalExtensionMemberWithStaticDisallowed",
  problemMessage:
      r"""External extension members with the keyword 'static' on JS interop and @Native types are disallowed.""",
  correctionMessage: r"""Try putting the member in the on-type instead.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeJsInteropExternalMemberNotJSAnnotated = const MessageCode(
  "JsInteropExternalMemberNotJSAnnotated",
  problemMessage: r"""Only JS interop members may be 'external'.""",
  correctionMessage:
      r"""Try removing the 'external' keyword or adding a JS interop annotation.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String conversion),
  Message Function({required String conversion})
>
codeJsInteropFunctionToJSNamedParameters = const Template(
  "JsInteropFunctionToJSNamedParameters",
  problemMessageTemplate:
      r"""Functions converted via '#conversion' cannot declare named parameters.""",
  correctionMessageTemplate:
      r"""Remove the declared named parameters from the function.""",
  withArgumentsOld: _withArgumentsOldJsInteropFunctionToJSNamedParameters,
  withArguments: _withArgumentsJsInteropFunctionToJSNamedParameters,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropFunctionToJSNamedParameters({
  required String conversion,
}) {
  var conversion_0 = conversions.validateString(conversion);
  return new Message(
    codeJsInteropFunctionToJSNamedParameters,
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
codeJsInteropFunctionToJSRequiresStaticType = const Template(
  "JsInteropFunctionToJSRequiresStaticType",
  problemMessageTemplate:
      r"""Functions converted via '#conversion' require a statically known function type, but Type '#type' is not a precise function type, e.g., `void Function()`.""",
  correctionMessageTemplate:
      r"""Insert an explicit cast to the expected function type.""",
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
    codeJsInteropFunctionToJSRequiresStaticType,
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
codeJsInteropFunctionToJSTypeParameters = const Template(
  "JsInteropFunctionToJSTypeParameters",
  problemMessageTemplate:
      r"""Functions converted via '#conversion' cannot declare type parameters.""",
  correctionMessageTemplate:
      r"""Remove the declared type parameters from the function.""",
  withArgumentsOld: _withArgumentsOldJsInteropFunctionToJSTypeParameters,
  withArguments: _withArgumentsJsInteropFunctionToJSTypeParameters,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropFunctionToJSTypeParameters({
  required String conversion,
}) {
  var conversion_0 = conversions.validateString(conversion);
  return new Message(
    codeJsInteropFunctionToJSTypeParameters,
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
codeJsInteropFunctionToJSTypeViolation = const Template(
  "JsInteropFunctionToJSTypeViolation",
  problemMessageTemplate:
      r"""Function converted via '#conversion' contains invalid types in its function signature: '#string2'.""",
  correctionMessageTemplate:
      r"""Use one of these valid types instead: JS types from 'dart:js_interop', ExternalDartReference, void, bool, num, double, int, String, extension types that erase to one of these types, '@staticInterop' types, 'dart:html' types when compiling to JS, or a type parameter that is a subtype of a valid non-primitive type.""",
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
    codeJsInteropFunctionToJSTypeViolation,
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
const MessageCode codeJsInteropInvalidStaticClassMemberName = const MessageCode(
  "JsInteropInvalidStaticClassMemberName",
  problemMessage:
      r"""JS interop static class members cannot have '.' in their JS name.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type),
  Message Function({required DartType type})
>
codeJsInteropIsAInvalidTypeVariable = const Template(
  "JsInteropIsAInvalidTypeVariable",
  problemMessageTemplate:
      r"""Type argument '#type' provided to 'isA' cannot be a type variable and must be an interop extension type that can be determined at compile-time.""",
  correctionMessageTemplate:
      r"""Use a valid interop extension type that can be determined at compile-time as the type argument instead.""",
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
    codeJsInteropIsAInvalidTypeVariable,
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
codeJsInteropIsAObjectLiteralType = const Template(
  "JsInteropIsAObjectLiteralType",
  problemMessageTemplate:
      r"""Type argument '#type' has an object literal constructor. Because 'isA' uses the type's name or '@JS()' rename, this may result in an incorrect type check.""",
  correctionMessageTemplate:
      r"""Use 'JSObject' as the type argument instead.""",
  withArgumentsOld: _withArgumentsOldJsInteropIsAObjectLiteralType,
  withArguments: _withArgumentsJsInteropIsAObjectLiteralType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropIsAObjectLiteralType({required DartType type}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    codeJsInteropIsAObjectLiteralType,
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
codeJsInteropIsAPrimitiveExtensionType = const Template(
  "JsInteropIsAPrimitiveExtensionType",
  problemMessageTemplate:
      r"""Type argument '#type' wraps primitive JS type '#string', which is specially handled using 'typeof'.""",
  correctionMessageTemplate:
      r"""Use the primitive JS type '#string' as the type argument instead.""",
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
    codeJsInteropIsAPrimitiveExtensionType,
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
const MessageCode codeJsInteropIsATearoff = const MessageCode(
  "JsInteropIsATearoff",
  problemMessage: r"""'isA' can't be torn off.""",
  correctionMessage:
      r"""Use a method that calls 'isA' and tear off that method instead.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, String name2),
  Message Function({required String name, required String name2})
>
codeJsInteropJSClassExtendsDartClass = const Template(
  "JsInteropJSClassExtendsDartClass",
  problemMessageTemplate:
      r"""JS interop class '#name' cannot extend Dart class '#name2'.""",
  correctionMessageTemplate:
      r"""Try removing the JS interop annotation or adding it to the parent class.""",
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
    codeJsInteropJSClassExtendsDartClass,
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
const MessageCode codeJsInteropNamedParameters = const MessageCode(
  "JsInteropNamedParameters",
  problemMessage:
      r"""Named parameters for JS interop functions are only allowed in object literal constructors or @anonymous factories.""",
  correctionMessage:
      r"""Try replacing them with normal or optional parameters.""",
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
codeJsInteropNativeClassInAnnotation = const Template(
  "JsInteropNativeClassInAnnotation",
  problemMessageTemplate:
      r"""Non-static JS interop class '#name' conflicts with natively supported class '#name2' in '#string3'.""",
  correctionMessageTemplate:
      r"""Try replacing it with a static JS interop class using `@staticInterop` with extension methods, or use js_util to interact with the native object of type '#name2'.""",
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
    codeJsInteropNativeClassInAnnotation,
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
const MessageCode codeJsInteropNonExternalConstructor = const MessageCode(
  "JsInteropNonExternalConstructor",
  problemMessage:
      r"""JS interop classes do not support non-external constructors.""",
  correctionMessage: r"""Try annotating with `external`.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeJsInteropNonExternalMember = const MessageCode(
  "JsInteropNonExternalMember",
  problemMessage:
      r"""This JS interop member must be annotated with `external`. Only factories and static methods can be non-external.""",
  correctionMessage: r"""Try annotating the member with `external`.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, String name2),
  Message Function({required String name, required String name2})
>
codeJsInteropNonStaticWithStaticInteropSupertype = const Template(
  "JsInteropNonStaticWithStaticInteropSupertype",
  problemMessageTemplate:
      r"""Class '#name' does not have an `@staticInterop` annotation, but has supertype '#name2', which does.""",
  correctionMessageTemplate:
      r"""Try marking '#name' as a `@staticInterop` class, or don't inherit '#name2'.""",
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
    codeJsInteropNonStaticWithStaticInteropSupertype,
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
codeJsInteropObjectLiteralConstructorPositionalParameters = const Template(
  "JsInteropObjectLiteralConstructorPositionalParameters",
  problemMessageTemplate:
      r"""#string should not contain any positional parameters.""",
  correctionMessageTemplate:
      r"""Try replacing them with named parameters instead.""",
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
    codeJsInteropObjectLiteralConstructorPositionalParameters,
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
const MessageCode codeJsInteropOperatorCannotBeRenamed = const MessageCode(
  "JsInteropOperatorCannotBeRenamed",
  problemMessage:
      r"""JS interop operator methods cannot be renamed using the '@JS' annotation.""",
  correctionMessage:
      r"""Remove the annotation or remove the value inside the annotation.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeJsInteropOperatorsNotSupported = const MessageCode(
  "JsInteropOperatorsNotSupported",
  problemMessage:
      r"""JS interop types do not support overloading external operator methods, with the exception of '[]' and '[]=' using static interop.""",
  correctionMessage:
      r"""Try making this class a static interop type instead.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type),
  Message Function({required DartType type})
>
codeJsInteropStaticInteropExternalAccessorTypeViolation = const Template(
  "JsInteropStaticInteropExternalAccessorTypeViolation",
  problemMessageTemplate:
      r"""External JS interop member contains an invalid type: '#type'.""",
  correctionMessageTemplate:
      r"""Use one of these valid types instead: JS types from 'dart:js_interop', ExternalDartReference, void, bool, num, double, int, String, extension types that erase to one of these types, '@staticInterop' types, 'dart:html' types when compiling to JS, or a type parameter that is a subtype of a valid non-primitive type.""",
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
    codeJsInteropStaticInteropExternalAccessorTypeViolation,
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
codeJsInteropStaticInteropExternalFunctionTypeViolation = const Template(
  "JsInteropStaticInteropExternalFunctionTypeViolation",
  problemMessageTemplate:
      r"""External JS interop member contains invalid types in its function signature: '#string2'.""",
  correctionMessageTemplate:
      r"""Use one of these valid types instead: JS types from 'dart:js_interop', ExternalDartReference, void, bool, num, double, int, String, extension types that erase to one of these types, '@staticInterop' types, 'dart:html' types when compiling to JS, or a type parameter that is a subtype of a valid non-primitive type.""",
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
    codeJsInteropStaticInteropExternalFunctionTypeViolation,
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
codeJsInteropStaticInteropGenerativeConstructor = const MessageCode(
  "JsInteropStaticInteropGenerativeConstructor",
  problemMessage:
      r"""`@staticInterop` classes should not contain any generative constructors.""",
  correctionMessage: r"""Use factory constructors instead.""",
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
codeJsInteropStaticInteropMockMissingGetterOrSetter = const Template(
  "JsInteropStaticInteropMockMissingGetterOrSetter",
  problemMessageTemplate:
      r"""Dart class '#name' has a #string, but does not have a #string2 to implement any of the following extension member(s) with export name '#name2': #string3.""",
  correctionMessageTemplate:
      r"""Declare an exportable #string2 that implements one of these extension members.""",
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
    codeJsInteropStaticInteropMockMissingGetterOrSetter,
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
codeJsInteropStaticInteropMockMissingImplements = const Template(
  "JsInteropStaticInteropMockMissingImplements",
  problemMessageTemplate:
      r"""Dart class '#name' does not have any members that implement any of the following extension member(s) with export name '#name2': #string.""",
  correctionMessageTemplate:
      r"""Declare an exportable member that implements one of these extension members.""",
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
    codeJsInteropStaticInteropMockMissingImplements,
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
codeJsInteropStaticInteropMockNotStaticInteropType = const Template(
  "JsInteropStaticInteropMockNotStaticInteropType",
  problemMessageTemplate:
      r"""Type argument '#type' needs to be a `@staticInterop` type.""",
  correctionMessageTemplate: r"""Use a `@staticInterop` class instead.""",
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
    codeJsInteropStaticInteropMockNotStaticInteropType,
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
codeJsInteropStaticInteropMockTypeParametersNotAllowed = const Template(
  "JsInteropStaticInteropMockTypeParametersNotAllowed",
  problemMessageTemplate:
      r"""Type argument '#type' has type parameters that do not match their bound. createStaticInteropMock requires instantiating all type parameters to their bound to ensure mocking conformance.""",
  correctionMessageTemplate:
      r"""Remove the type parameter in the type argument or replace it with its bound.""",
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
    codeJsInteropStaticInteropMockTypeParametersNotAllowed,
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
codeJsInteropStaticInteropNoJSAnnotation = const Template(
  "JsInteropStaticInteropNoJSAnnotation",
  problemMessageTemplate:
      r"""`@staticInterop` classes should also have the `@JS` annotation.""",
  correctionMessageTemplate: r"""Add `@JS` to class '#name'.""",
  withArgumentsOld: _withArgumentsOldJsInteropStaticInteropNoJSAnnotation,
  withArguments: _withArgumentsJsInteropStaticInteropNoJSAnnotation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropStaticInteropNoJSAnnotation({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeJsInteropStaticInteropNoJSAnnotation,
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
codeJsInteropStaticInteropParameterInitializersAreIgnored = const MessageCode(
  "JsInteropStaticInteropParameterInitializersAreIgnored",
  severity: CfeSeverity.warning,
  problemMessage:
      r"""Initializers for parameters are ignored on static interop external functions.""",
  correctionMessage:
      r"""Declare a forwarding non-external function with this initializer, or remove the initializer.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
codeJsInteropStaticInteropSyntheticConstructor = const MessageCode(
  "JsInteropStaticInteropSyntheticConstructor",
  problemMessage:
      r"""Synthetic constructors on `@staticInterop` classes can not be used.""",
  correctionMessage:
      r"""Declare an external factory constructor for this `@staticInterop` class and use that instead.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string, String name),
  Message Function({required String string, required String name})
>
codeJsInteropStaticInteropTearOffsDisallowed = const Template(
  "JsInteropStaticInteropTearOffsDisallowed",
  problemMessageTemplate:
      r"""Tear-offs of external #string '#name' are disallowed.""",
  correctionMessageTemplate:
      r"""Declare a closure that calls this member instead.""",
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
    codeJsInteropStaticInteropTearOffsDisallowed,
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
codeJsInteropStaticInteropTrustTypesUsageNotAllowed = const Template(
  "JsInteropStaticInteropTrustTypesUsageNotAllowed",
  problemMessageTemplate:
      r"""JS interop class '#name' has an `@trustTypes` annotation, but `@trustTypes` is only supported within the sdk.""",
  correctionMessageTemplate: r"""Try removing the `@trustTypes` annotation.""",
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
    codeJsInteropStaticInteropTrustTypesUsageNotAllowed,
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
codeJsInteropStaticInteropTrustTypesUsedWithoutStaticInterop = const Template(
  "JsInteropStaticInteropTrustTypesUsedWithoutStaticInterop",
  problemMessageTemplate:
      r"""JS interop class '#name' has an `@trustTypes` annotation, but no `@staticInterop` annotation.""",
  correctionMessageTemplate:
      r"""Try marking the class using `@staticInterop`.""",
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
    codeJsInteropStaticInteropTrustTypesUsedWithoutStaticInterop,
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
codeJsInteropStaticInteropWithInstanceMembers = const Template(
  "JsInteropStaticInteropWithInstanceMembers",
  problemMessageTemplate:
      r"""JS interop class '#name' with `@staticInterop` annotation cannot declare instance members.""",
  correctionMessageTemplate:
      r"""Try moving the instance member to a static extension.""",
  withArgumentsOld: _withArgumentsOldJsInteropStaticInteropWithInstanceMembers,
  withArguments: _withArgumentsJsInteropStaticInteropWithInstanceMembers,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropStaticInteropWithInstanceMembers({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeJsInteropStaticInteropWithInstanceMembers,
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
codeJsInteropStaticInteropWithNonStaticSupertype = const Template(
  "JsInteropStaticInteropWithNonStaticSupertype",
  problemMessageTemplate:
      r"""JS interop class '#name' has an `@staticInterop` annotation, but has supertype '#name2', which does not.""",
  correctionMessageTemplate:
      r"""Try marking the supertype as a static interop class using `@staticInterop`.""",
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
    codeJsInteropStaticInteropWithNonStaticSupertype,
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
  Message Function(String name),
  Message Function({required String name})
>
codeLabelNotFound = const Template(
  "LabelNotFound",
  problemMessageTemplate: r"""Can't find label '#name'.""",
  correctionMessageTemplate:
      r"""Try defining the label, or correcting the name to match an existing label.""",
  withArgumentsOld: _withArgumentsOldLabelNotFound,
  withArguments: _withArgumentsLabelNotFound,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsLabelNotFound({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeLabelNotFound,
    problemMessage: """Can't find label '${name_0}'.""",
    correctionMessage:
        """Try defining the label, or correcting the name to match an existing label.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldLabelNotFound(String name) =>
    _withArgumentsLabelNotFound(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeLanguageVersionInvalidInDotPackages = const MessageCode(
  "LanguageVersionInvalidInDotPackages",
  problemMessage:
      r"""The language version is not specified correctly in the packages file.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeLanguageVersionLibraryContext = const MessageCode(
  "LanguageVersionLibraryContext",
  severity: CfeSeverity.context,
  problemMessage: r"""This is language version annotation in the library.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeLanguageVersionMismatchInPart = const MessageCode(
  "LanguageVersionMismatchInPart",
  problemMessage:
      r"""The language version override has to be the same in the library and its part(s).""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeLanguageVersionMismatchInPatch = const MessageCode(
  "LanguageVersionMismatchInPatch",
  problemMessage:
      r"""The language version override has to be the same in the library and its patch(es).""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeLanguageVersionPartContext = const MessageCode(
  "LanguageVersionPartContext",
  severity: CfeSeverity.context,
  problemMessage: r"""This is language version annotation in the part.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeLanguageVersionPatchContext = const MessageCode(
  "LanguageVersionPatchContext",
  severity: CfeSeverity.context,
  problemMessage: r"""This is language version annotation in the patch.""",
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
codeLanguageVersionTooHighExplicit = const Template(
  "LanguageVersionTooHighExplicit",
  problemMessageTemplate:
      r"""The specified language version #count.#count2 is too high. The highest supported language version is #count3.#count4.""",
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
    codeLanguageVersionTooHighExplicit,
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
codeLanguageVersionTooHighPackage = const Template(
  "LanguageVersionTooHighPackage",
  problemMessageTemplate:
      r"""The language version #count.#count2 specified for the package '#name' is too high. The highest supported language version is #count3.#count4.""",
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
    codeLanguageVersionTooHighPackage,
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
codeLanguageVersionTooLowExplicit = const Template(
  "LanguageVersionTooLowExplicit",
  problemMessageTemplate:
      r"""The specified language version #count.#count2 is too low. The lowest supported language version is #count3.#count4.""",
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
    codeLanguageVersionTooLowExplicit,
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
codeLanguageVersionTooLowPackage = const Template(
  "LanguageVersionTooLowPackage",
  problemMessageTemplate:
      r"""The language version #count.#count2 specified for the package '#name' is too low. The lowest supported language version is #count3.#count4.""",
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
    codeLanguageVersionTooLowPackage,
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
codeLateDefinitelyAssignedError = const Template(
  "LateDefinitelyAssignedError",
  problemMessageTemplate:
      r"""Late final variable '#name' definitely assigned.""",
  withArgumentsOld: _withArgumentsOldLateDefinitelyAssignedError,
  withArguments: _withArgumentsLateDefinitelyAssignedError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsLateDefinitelyAssignedError({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeLateDefinitelyAssignedError,
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
codeLateDefinitelyUnassignedError = const Template(
  "LateDefinitelyUnassignedError",
  problemMessageTemplate:
      r"""Late variable '#name' without initializer is definitely unassigned.""",
  withArgumentsOld: _withArgumentsOldLateDefinitelyUnassignedError,
  withArguments: _withArgumentsLateDefinitelyUnassignedError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsLateDefinitelyUnassignedError({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeLateDefinitelyUnassignedError,
    problemMessage:
        """Late variable '${name_0}' without initializer is definitely unassigned.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldLateDefinitelyUnassignedError(String name) =>
    _withArgumentsLateDefinitelyUnassignedError(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeListLiteralTooManyTypeArguments = const MessageCode(
  "ListLiteralTooManyTypeArguments",
  problemMessage: r"""List literal requires exactly one type argument.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeListPatternTooManyTypeArguments = const MessageCode(
  "ListPatternTooManyTypeArguments",
  problemMessage: r"""A list pattern requires exactly one type argument.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeLoadLibraryTakesNoArguments = const MessageCode(
  "LoadLibraryTakesNoArguments",
  problemMessage: r"""'loadLibrary' takes no arguments.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeLocalVariableUsedBeforeDeclared = const Template(
  "LocalVariableUsedBeforeDeclared",
  problemMessageTemplate:
      r"""Local variable '#name' can't be referenced before it is declared.""",
  withArgumentsOld: _withArgumentsOldLocalVariableUsedBeforeDeclared,
  withArguments: _withArgumentsLocalVariableUsedBeforeDeclared,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsLocalVariableUsedBeforeDeclared({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeLocalVariableUsedBeforeDeclared,
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
codeLocalVariableUsedBeforeDeclaredContext = const Template(
  "LocalVariableUsedBeforeDeclaredContext",
  problemMessageTemplate:
      r"""This is the declaration of the variable '#name'.""",
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
    codeLocalVariableUsedBeforeDeclaredContext,
    problemMessage: """This is the declaration of the variable '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldLocalVariableUsedBeforeDeclaredContext(String name) =>
    _withArgumentsLocalVariableUsedBeforeDeclaredContext(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMainNotFunctionDeclaration = const MessageCode(
  "MainNotFunctionDeclaration",
  problemMessage: r"""The 'main' declaration must be a function declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMainNotFunctionDeclarationExported = const MessageCode(
  "MainNotFunctionDeclarationExported",
  problemMessage:
      r"""The exported 'main' declaration must be a function declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMainRequiredNamedParameters = const MessageCode(
  "MainRequiredNamedParameters",
  problemMessage:
      r"""The 'main' method cannot have required named parameters.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMainRequiredNamedParametersExported = const MessageCode(
  "MainRequiredNamedParametersExported",
  problemMessage:
      r"""The exported 'main' method cannot have required named parameters.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMainTooManyRequiredParameters = const MessageCode(
  "MainTooManyRequiredParameters",
  problemMessage:
      r"""The 'main' method must have at most 2 required parameters.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMainTooManyRequiredParametersExported = const MessageCode(
  "MainTooManyRequiredParametersExported",
  problemMessage:
      r"""The exported 'main' method must have at most 2 required parameters.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type, DartType type2),
  Message Function({required DartType type, required DartType type2})
>
codeMainWrongParameterType = const Template(
  "MainWrongParameterType",
  problemMessageTemplate:
      r"""The type '#type' of the first parameter of the 'main' method is not a supertype of '#type2'.""",
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
    codeMainWrongParameterType,
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
codeMainWrongParameterTypeExported = const Template(
  "MainWrongParameterTypeExported",
  problemMessageTemplate:
      r"""The type '#type' of the first parameter of the exported 'main' method is not a supertype of '#type2'.""",
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
    codeMainWrongParameterTypeExported,
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
const MessageCode codeMapPatternTypeArgumentMismatch = const MessageCode(
  "MapPatternTypeArgumentMismatch",
  problemMessage: r"""A map pattern requires exactly two type arguments.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeMemberConflictsWithConstructor = const Template(
  "MemberConflictsWithConstructor",
  problemMessageTemplate: r"""The member conflicts with constructor '#name'.""",
  withArgumentsOld: _withArgumentsOldMemberConflictsWithConstructor,
  withArguments: _withArgumentsMemberConflictsWithConstructor,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMemberConflictsWithConstructor({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeMemberConflictsWithConstructor,
    problemMessage: """The member conflicts with constructor '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldMemberConflictsWithConstructor(String name) =>
    _withArgumentsMemberConflictsWithConstructor(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeMemberConflictsWithConstructorCause = const Template(
  "MemberConflictsWithConstructorCause",
  problemMessageTemplate: r"""Conflicting constructor '#name'.""",
  withArgumentsOld: _withArgumentsOldMemberConflictsWithConstructorCause,
  withArguments: _withArgumentsMemberConflictsWithConstructorCause,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMemberConflictsWithConstructorCause({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeMemberConflictsWithConstructorCause,
    problemMessage: """Conflicting constructor '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldMemberConflictsWithConstructorCause(String name) =>
    _withArgumentsMemberConflictsWithConstructorCause(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeMemberConflictsWithFactory = const Template(
  "MemberConflictsWithFactory",
  problemMessageTemplate: r"""The member conflicts with factory '#name'.""",
  withArgumentsOld: _withArgumentsOldMemberConflictsWithFactory,
  withArguments: _withArgumentsMemberConflictsWithFactory,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMemberConflictsWithFactory({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeMemberConflictsWithFactory,
    problemMessage: """The member conflicts with factory '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldMemberConflictsWithFactory(String name) =>
    _withArgumentsMemberConflictsWithFactory(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeMemberConflictsWithFactoryCause = const Template(
  "MemberConflictsWithFactoryCause",
  problemMessageTemplate: r"""Conflicting factory '#name'.""",
  withArgumentsOld: _withArgumentsOldMemberConflictsWithFactoryCause,
  withArguments: _withArgumentsMemberConflictsWithFactoryCause,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMemberConflictsWithFactoryCause({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeMemberConflictsWithFactoryCause,
    problemMessage: """Conflicting factory '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldMemberConflictsWithFactoryCause(String name) =>
    _withArgumentsMemberConflictsWithFactoryCause(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeMemberNotFound = const Template(
  "MemberNotFound",
  problemMessageTemplate: r"""Member not found: '#name'.""",
  withArgumentsOld: _withArgumentsOldMemberNotFound,
  withArguments: _withArgumentsMemberNotFound,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMemberNotFound({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeMemberNotFound,
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
codeMemberShouldBeListedAsCallableInDynamicInterface = const Template(
  "MemberShouldBeListedAsCallableInDynamicInterface",
  problemMessageTemplate:
      r"""Cannot invoke member '#name' from a dynamic module.""",
  correctionMessageTemplate:
      r"""Try removing the call or update the dynamic interface to list member '#name' as callable.""",
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
    codeMemberShouldBeListedAsCallableInDynamicInterface,
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
  Message Function(String name, String name2),
  Message Function({required String name, required String name2})
>
codeMemberShouldBeListedAsCanBeOverriddenInDynamicInterface = const Template(
  "MemberShouldBeListedAsCanBeOverriddenInDynamicInterface",
  problemMessageTemplate:
      r"""Cannot override member '#name.#name2' in a dynamic module.""",
  correctionMessageTemplate:
      r"""Try removing the override or update the dynamic interface to list member '#name.#name2' as can-be-overridden.""",
  withArgumentsOld:
      _withArgumentsOldMemberShouldBeListedAsCanBeOverriddenInDynamicInterface,
  withArguments:
      _withArgumentsMemberShouldBeListedAsCanBeOverriddenInDynamicInterface,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMemberShouldBeListedAsCanBeOverriddenInDynamicInterface({
  required String name,
  required String name2,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var name2_0 = conversions.validateAndDemangleName(name2);
  return new Message(
    codeMemberShouldBeListedAsCanBeOverriddenInDynamicInterface,
    problemMessage:
        """Cannot override member '${name_0}.${name2_0}' in a dynamic module.""",
    correctionMessage:
        """Try removing the override or update the dynamic interface to list member '${name_0}.${name2_0}' as can-be-overridden.""",
    arguments: {'name': name, 'name2': name2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message
_withArgumentsOldMemberShouldBeListedAsCanBeOverriddenInDynamicInterface(
  String name,
  String name2,
) => _withArgumentsMemberShouldBeListedAsCanBeOverriddenInDynamicInterface(
  name: name,
  name2: name2,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeMethodNotFound = const Template(
  "MethodNotFound",
  problemMessageTemplate: r"""Method not found: '#name'.""",
  withArgumentsOld: _withArgumentsOldMethodNotFound,
  withArguments: _withArgumentsMethodNotFound,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMethodNotFound({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeMethodNotFound,
    problemMessage: """Method not found: '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldMethodNotFound(String name) =>
    _withArgumentsMethodNotFound(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMissingExplicitConst = const MessageCode(
  "MissingExplicitConst",
  problemMessage: r"""Constant expression expected.""",
  correctionMessage: r"""Try inserting 'const'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeMissingImplementationCause = const Template(
  "MissingImplementationCause",
  problemMessageTemplate: r"""'#name' is defined here.""",
  withArgumentsOld: _withArgumentsOldMissingImplementationCause,
  withArguments: _withArgumentsMissingImplementationCause,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMissingImplementationCause({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeMissingImplementationCause,
    problemMessage: """'${name_0}' is defined here.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldMissingImplementationCause(String name) =>
    _withArgumentsMissingImplementationCause(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, List<String> names),
  Message Function({required String name, required List<String> names})
>
codeMissingImplementationNotAbstract = const Template(
  "MissingImplementationNotAbstract",
  problemMessageTemplate:
      r"""The non-abstract class '#name' is missing implementations for these members:
#names""",
  correctionMessageTemplate: r"""Try to either
 - provide an implementation,
 - inherit an implementation from a superclass or mixin,
 - mark the class as abstract, or
 - provide a 'noSuchMethod' implementation.""",
  withArgumentsOld: _withArgumentsOldMissingImplementationNotAbstract,
  withArguments: _withArgumentsMissingImplementationNotAbstract,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMissingImplementationNotAbstract({
  required String name,
  required List<String> names,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var names_0 = conversions.validateAndItemizeNames(names);
  return new Message(
    codeMissingImplementationNotAbstract,
    problemMessage:
        """The non-abstract class '${name_0}' is missing implementations for these members:
${names_0}""",
    correctionMessage: """Try to either
 - provide an implementation,
 - inherit an implementation from a superclass or mixin,
 - mark the class as abstract, or
 - provide a 'noSuchMethod' implementation.""",
    arguments: {'name': name, 'names': names},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldMissingImplementationNotAbstract(
  String name,
  List<String> names,
) => _withArgumentsMissingImplementationNotAbstract(name: name, names: names);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMissingInput = const MessageCode(
  "MissingInput",
  problemMessage: r"""No input file provided to the compiler.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMissingMain = const MessageCode(
  "MissingMain",
  problemMessage: r"""No 'main' method found.""",
  correctionMessage: r"""Try adding a method named 'main' to your program.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMissingNamedSuperConstructorParameter = const MessageCode(
  "MissingNamedSuperConstructorParameter",
  problemMessage:
      r"""The super constructor has no corresponding named parameter.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri), Message Function({required Uri uri})>
codeMissingPartOf = const Template(
  "MissingPartOf",
  problemMessageTemplate:
      r"""Can't use '#uri' as a part, because it has no 'part of' declaration.""",
  withArgumentsOld: _withArgumentsOldMissingPartOf,
  withArguments: _withArgumentsMissingPartOf,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMissingPartOf({required Uri uri}) {
  var uri_0 = conversions.relativizeUri(uri);
  return new Message(
    codeMissingPartOf,
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
codeMissingPositionalSuperConstructorParameter = const MessageCode(
  "MissingPositionalSuperConstructorParameter",
  problemMessage:
      r"""The super constructor has no corresponding positional parameter.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeMissingVariablePattern = const Template(
  "MissingVariablePattern",
  problemMessageTemplate:
      r"""Variable pattern '#name' is missing in this branch of the logical-or pattern.""",
  correctionMessageTemplate:
      r"""Try declaring this variable pattern in the branch.""",
  withArgumentsOld: _withArgumentsOldMissingVariablePattern,
  withArguments: _withArgumentsMissingVariablePattern,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMissingVariablePattern({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeMissingVariablePattern,
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
codeMixinApplicationIncompatibleSupertype = const Template(
  "MixinApplicationIncompatibleSupertype",
  problemMessageTemplate:
      r"""'#type' doesn't implement '#type2' so it can't be used with '#type3'.""",
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
    codeMixinApplicationIncompatibleSupertype,
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
codeMixinApplicationNoConcreteGetter = const Template(
  "MixinApplicationNoConcreteGetter",
  problemMessageTemplate:
      r"""The class doesn't have a concrete implementation of the super-accessed member '#name'.""",
  withArgumentsOld: _withArgumentsOldMixinApplicationNoConcreteGetter,
  withArguments: _withArgumentsMixinApplicationNoConcreteGetter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMixinApplicationNoConcreteGetter({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeMixinApplicationNoConcreteGetter,
    problemMessage:
        """The class doesn't have a concrete implementation of the super-accessed member '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldMixinApplicationNoConcreteGetter(String name) =>
    _withArgumentsMixinApplicationNoConcreteGetter(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMixinApplicationNoConcreteMemberContext =
    const MessageCode(
      "MixinApplicationNoConcreteMemberContext",
      severity: CfeSeverity.context,
      problemMessage:
          r"""This is the super-access that doesn't have a concrete target.""",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeMixinApplicationNoConcreteMethod = const Template(
  "MixinApplicationNoConcreteMethod",
  problemMessageTemplate:
      r"""The class doesn't have a concrete implementation of the super-invoked member '#name'.""",
  withArgumentsOld: _withArgumentsOldMixinApplicationNoConcreteMethod,
  withArguments: _withArgumentsMixinApplicationNoConcreteMethod,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMixinApplicationNoConcreteMethod({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeMixinApplicationNoConcreteMethod,
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
codeMixinApplicationNoConcreteSetter = const Template(
  "MixinApplicationNoConcreteSetter",
  problemMessageTemplate:
      r"""The class doesn't have a concrete implementation of the super-accessed setter '#name'.""",
  withArgumentsOld: _withArgumentsOldMixinApplicationNoConcreteSetter,
  withArguments: _withArgumentsMixinApplicationNoConcreteSetter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMixinApplicationNoConcreteSetter({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeMixinApplicationNoConcreteSetter,
    problemMessage:
        """The class doesn't have a concrete implementation of the super-accessed setter '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldMixinApplicationNoConcreteSetter(String name) =>
    _withArgumentsMixinApplicationNoConcreteSetter(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMixinDeferredMixin = const MessageCode(
  "MixinDeferredMixin",
  problemMessage: r"""Classes can't mix in deferred mixins.""",
  correctionMessage: r"""Try changing the import to not be deferred.""",
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
codeMixinInferenceNoMatchingClass = const Template(
  "MixinInferenceNoMatchingClass",
  problemMessageTemplate:
      r"""Type parameters couldn't be inferred for the mixin '#name' because '#name2' does not implement the mixin's supertype constraint '#type'.""",
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
    codeMixinInferenceNoMatchingClass,
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
codeMixinInheritsFromNotObject = const Template(
  "MixinInheritsFromNotObject",
  problemMessageTemplate:
      r"""The class '#name' can't be used as a mixin because it extends a class other than 'Object'.""",
  withArgumentsOld: _withArgumentsOldMixinInheritsFromNotObject,
  withArguments: _withArgumentsMixinInheritsFromNotObject,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMixinInheritsFromNotObject({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeMixinInheritsFromNotObject,
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
codeMixinSubtypeOfBaseIsNotBase = const Template(
  "MixinSubtypeOfBaseIsNotBase",
  problemMessageTemplate:
      r"""The mixin '#name' must be 'base' because the supertype '#name2' is 'base'.""",
  correctionMessageTemplate: r"""Try adding 'base' to the mixin.""",
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
    codeMixinSubtypeOfBaseIsNotBase,
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
codeMixinSubtypeOfFinalIsNotBase = const Template(
  "MixinSubtypeOfFinalIsNotBase",
  problemMessageTemplate:
      r"""The mixin '#name' must be 'base' because the supertype '#name2' is 'final'.""",
  correctionMessageTemplate: r"""Try adding 'base' to the mixin.""",
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
    codeMixinSubtypeOfFinalIsNotBase,
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
const MessageCode codeMixinSuperClassConstraintDeferredClass =
    const MessageCode(
      "MixinSuperClassConstraintDeferredClass",
      problemMessage:
          r"""Deferred classes can't be used as superclass constraints.""",
      correctionMessage: r"""Try changing the import to not be deferred.""",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMoreThanOneSuperInitializer = const MessageCode(
  "MoreThanOneSuperInitializer",
  problemMessage: r"""Can't have more than one 'super' initializer.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMultipleRepresentationFields = const MessageCode(
  "MultipleRepresentationFields",
  problemMessage:
      r"""Each extension type should have exactly one representation field.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeNameNotFound = const Template(
  "NameNotFound",
  problemMessageTemplate: r"""Undefined name '#name'.""",
  withArgumentsOld: _withArgumentsOldNameNotFound,
  withArguments: _withArgumentsNameNotFound,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNameNotFound({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeNameNotFound,
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
codeNameNotFoundInRecordNameGet = const Template(
  "NameNotFoundInRecordNameGet",
  problemMessageTemplate:
      r"""Field name #string isn't found in records of type #type.""",
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
    codeNameNotFoundInRecordNameGet,
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
codeNamedFieldClashesWithPositionalFieldInRecord = const MessageCode(
  "NamedFieldClashesWithPositionalFieldInRecord",
  problemMessage:
      r"""Record field names can't be a dollar sign followed by an integer when integer is the index of a positional field.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, String name2),
  Message Function({required String name, required String name2})
>
codeNamedMixinOverride = const Template(
  "NamedMixinOverride",
  problemMessageTemplate:
      r"""The mixin application class '#name' introduces an erroneous override of '#name2'.""",
  withArgumentsOld: _withArgumentsOldNamedMixinOverride,
  withArguments: _withArgumentsNamedMixinOverride,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNamedMixinOverride({
  required String name,
  required String name2,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var name2_0 = conversions.validateAndDemangleName(name2);
  return new Message(
    codeNamedMixinOverride,
    problemMessage:
        """The mixin application class '${name_0}' introduces an erroneous override of '${name2_0}'.""",
    arguments: {'name': name, 'name2': name2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldNamedMixinOverride(String name, String name2) =>
    _withArgumentsNamedMixinOverride(name: name, name2: name2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeNamedParametersInExtensionTypeDeclaration =
    const MessageCode(
      "NamedParametersInExtensionTypeDeclaration",
      problemMessage:
          r"""Extension type declarations can't have named parameters.""",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeNegativeVariableDimension = const MessageCode(
  "NegativeVariableDimension",
  problemMessage:
      r"""The variable dimension of a variable-length array must be non-negative.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeNeverReachableSwitchDefaultError = const MessageCode(
  "NeverReachableSwitchDefaultError",
  problemMessage:
      r"""`null` encountered as case in a switch expression with a non-nullable enum type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeNeverReachableSwitchExpressionError = const MessageCode(
  "NeverReachableSwitchExpressionError",
  problemMessage:
      r"""`null` encountered as case in a switch expression with a non-nullable type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeNeverReachableSwitchStatementError = const MessageCode(
  "NeverReachableSwitchStatementError",
  problemMessage:
      r"""`null` encountered as case in a switch statement with a non-nullable type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeNeverValueError = const MessageCode(
  "NeverValueError",
  problemMessage:
      r"""`null` encountered as the result from expression with type `Never`.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeNewAsSelector = const MessageCode(
  "NewAsSelector",
  problemMessage: r"""'new' can only be used as a constructor reference.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeNoAugmentSuperInvokeTarget = const MessageCode(
  "NoAugmentSuperInvokeTarget",
  problemMessage: r"""Cannot call 'augment super'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeNoAugmentSuperReadTarget = const MessageCode(
  "NoAugmentSuperReadTarget",
  problemMessage: r"""Cannot read from 'augment super'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeNoAugmentSuperWriteTarget = const MessageCode(
  "NoAugmentSuperWriteTarget",
  problemMessage: r"""Cannot write to 'augment super'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeNoSuchNamedParameter = const Template(
  "NoSuchNamedParameter",
  problemMessageTemplate: r"""No named parameter with the name '#name'.""",
  withArgumentsOld: _withArgumentsOldNoSuchNamedParameter,
  withArguments: _withArgumentsNoSuchNamedParameter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNoSuchNamedParameter({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeNoSuchNamedParameter,
    problemMessage: """No named parameter with the name '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldNoSuchNamedParameter(String name) =>
    _withArgumentsNoSuchNamedParameter(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeNoUnnamedConstructorInObject = const MessageCode(
  "NoUnnamedConstructorInObject",
  problemMessage: r"""'Object' has no unnamed constructor.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeNonAugmentationDeclarationConflictCause =
    const MessageCode(
      "NonAugmentationDeclarationConflictCause",
      severity: CfeSeverity.context,
      problemMessage: r"""This is the existing declaration.""",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeNonAugmentationMemberConflictCause = const MessageCode(
  "NonAugmentationMemberConflictCause",
  severity: CfeSeverity.context,
  problemMessage: r"""This is the existing member.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeNonBoolCondition = const MessageCode(
  "NonBoolCondition",
  problemMessage: r"""Conditions must have a static type of 'bool'.""",
  correctionMessage: r"""Try changing the condition.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeNonConstConstructor = const MessageCode(
  "NonConstConstructor",
  problemMessage:
      r"""Cannot invoke a non-'const' constructor where a const expression is expected.""",
  correctionMessage: r"""Try using a constructor or factory that is 'const'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeNonConstFactory = const MessageCode(
  "NonConstFactory",
  problemMessage:
      r"""Cannot invoke a non-'const' factory where a const expression is expected.""",
  correctionMessage: r"""Try using a constructor or factory that is 'const'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
codeNonCovariantTypeParameterInRepresentationType = const MessageCode(
  "NonCovariantTypeParameterInRepresentationType",
  problemMessage:
      r"""An extension type parameter can't be used non-covariantly in its representation type.""",
  correctionMessage:
      r"""Try removing the type parameters from function parameter types and type parameter bounds.""",
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
codeNonExhaustiveSwitchExpression = const Template(
  "NonExhaustiveSwitchExpression",
  problemMessageTemplate:
      r"""The type '#type' is not exhaustively matched by the switch cases since it doesn't match '#string'.""",
  correctionMessageTemplate:
      r"""Try adding a wildcard pattern or cases that match '#string2'.""",
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
    codeNonExhaustiveSwitchExpression,
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
codeNonExhaustiveSwitchStatement = const Template(
  "NonExhaustiveSwitchStatement",
  problemMessageTemplate:
      r"""The type '#type' is not exhaustively matched by the switch cases since it doesn't match '#string'.""",
  correctionMessageTemplate:
      r"""Try adding a default case or cases that match '#string2'.""",
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
    codeNonExhaustiveSwitchStatement,
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
const MessageCode codeNonExtensionTypeMemberContext = const MessageCode(
  "NonExtensionTypeMemberContext",
  severity: CfeSeverity.context,
  problemMessage: r"""This is the inherited non-extension type member.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeNonExtensionTypeMemberOneOfContext = const MessageCode(
  "NonExtensionTypeMemberOneOfContext",
  severity: CfeSeverity.context,
  problemMessage:
      r"""This is one of the inherited non-extension type members.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type),
  Message Function({required DartType type})
>
codeNonNullAwareSpreadIsNull = const Template(
  "NonNullAwareSpreadIsNull",
  problemMessageTemplate: r"""Can't spread a value with static type '#type'.""",
  withArgumentsOld: _withArgumentsOldNonNullAwareSpreadIsNull,
  withArguments: _withArgumentsNonNullAwareSpreadIsNull,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonNullAwareSpreadIsNull({required DartType type}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    codeNonNullAwareSpreadIsNull,
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
codeNonNullableNotAssignedError = const Template(
  "NonNullableNotAssignedError",
  problemMessageTemplate:
      r"""Non-nullable variable '#name' must be assigned before it can be used.""",
  withArgumentsOld: _withArgumentsOldNonNullableNotAssignedError,
  withArguments: _withArgumentsNonNullableNotAssignedError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonNullableNotAssignedError({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeNonNullableNotAssignedError,
    problemMessage:
        """Non-nullable variable '${name_0}' must be assigned before it can be used.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldNonNullableNotAssignedError(String name) =>
    _withArgumentsNonNullableNotAssignedError(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeNonPositiveArrayDimensions = const MessageCode(
  "NonPositiveArrayDimensions",
  problemMessage: r"""Array dimensions must be positive numbers.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeNonSimpleBoundViaReference = const Template(
  "NonSimpleBoundViaReference",
  problemMessageTemplate:
      r"""Bound of this variable references raw type '#name'.""",
  withArgumentsOld: _withArgumentsOldNonSimpleBoundViaReference,
  withArguments: _withArgumentsNonSimpleBoundViaReference,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonSimpleBoundViaReference({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeNonSimpleBoundViaReference,
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
codeNonSimpleBoundViaVariable = const Template(
  "NonSimpleBoundViaVariable",
  problemMessageTemplate:
      r"""Bound of this variable references variable '#name' from the same declaration.""",
  withArgumentsOld: _withArgumentsOldNonSimpleBoundViaVariable,
  withArguments: _withArgumentsNonSimpleBoundViaVariable,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonSimpleBoundViaVariable({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeNonSimpleBoundViaVariable,
    problemMessage:
        """Bound of this variable references variable '${name_0}' from the same declaration.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldNonSimpleBoundViaVariable(String name) =>
    _withArgumentsNonSimpleBoundViaVariable(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeNonVoidReturnOperator = const MessageCode(
  "NonVoidReturnOperator",
  problemMessage: r"""The return type of the operator []= must be 'void'.""",
  correctionMessage: r"""Try changing the return type to 'void'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeNonVoidReturnSetter = const MessageCode(
  "NonVoidReturnSetter",
  problemMessage:
      r"""The return type of the setter must be 'void' or absent.""",
  correctionMessage:
      r"""Try removing the return type, or define a method rather than a setter.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeNotAConstantExpression = const MessageCode(
  "NotAConstantExpression",
  problemMessage: r"""Not a constant expression.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, String name2),
  Message Function({required String name, required String name2})
>
codeNotAPrefixInTypeAnnotation = const Template(
  "NotAPrefixInTypeAnnotation",
  problemMessageTemplate:
      r"""'#name.#name2' can't be used as a type because '#name' doesn't refer to an import prefix.""",
  withArgumentsOld: _withArgumentsOldNotAPrefixInTypeAnnotation,
  withArguments: _withArgumentsNotAPrefixInTypeAnnotation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNotAPrefixInTypeAnnotation({
  required String name,
  required String name2,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var name2_0 = conversions.validateAndDemangleName(name2);
  return new Message(
    codeNotAPrefixInTypeAnnotation,
    problemMessage:
        """'${name_0}.${name2_0}' can't be used as a type because '${name_0}' doesn't refer to an import prefix.""",
    arguments: {'name': name, 'name2': name2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldNotAPrefixInTypeAnnotation(
  String name,
  String name2,
) => _withArgumentsNotAPrefixInTypeAnnotation(name: name, name2: name2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeNotAType = const Template(
  "NotAType",
  problemMessageTemplate: r"""'#name' isn't a type.""",
  withArgumentsOld: _withArgumentsOldNotAType,
  withArguments: _withArgumentsNotAType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNotAType({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeNotAType,
    problemMessage: """'${name_0}' isn't a type.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldNotAType(String name) =>
    _withArgumentsNotAType(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeNotATypeContext = const MessageCode(
  "NotATypeContext",
  severity: CfeSeverity.context,
  problemMessage: r"""This isn't a type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeNotAnLvalue = const MessageCode(
  "NotAnLvalue",
  problemMessage: r"""Can't assign to this.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Token lexeme),
  Message Function({required Token lexeme})
>
codeNotBinaryOperator = const Template(
  "NotBinaryOperator",
  problemMessageTemplate: r"""'#lexeme' isn't a binary operator.""",
  withArgumentsOld: _withArgumentsOldNotBinaryOperator,
  withArguments: _withArgumentsNotBinaryOperator,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNotBinaryOperator({required Token lexeme}) {
  var lexeme_0 = conversions.tokenToLexeme(lexeme);
  return new Message(
    codeNotBinaryOperator,
    problemMessage: """'${lexeme_0}' isn't a binary operator.""",
    arguments: {'lexeme': lexeme},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldNotBinaryOperator(Token lexeme) =>
    _withArgumentsNotBinaryOperator(lexeme: lexeme);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string),
  Message Function({required String string})
>
codeNotConstantExpression = const Template(
  "NotConstantExpression",
  problemMessageTemplate: r"""#string is not a constant expression.""",
  withArgumentsOld: _withArgumentsOldNotConstantExpression,
  withArguments: _withArgumentsNotConstantExpression,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNotConstantExpression({required String string}) {
  var string_0 = conversions.validateString(string);
  return new Message(
    codeNotConstantExpression,
    problemMessage: """${string_0} is not a constant expression.""",
    arguments: {'string': string},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldNotConstantExpression(String string) =>
    _withArgumentsNotConstantExpression(string: string);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type),
  Message Function({required DartType type})
>
codeNullableExpressionCallError = const Template(
  "NullableExpressionCallError",
  problemMessageTemplate:
      r"""Can't use an expression of type '#type' as a function because it's potentially null.""",
  correctionMessageTemplate: r"""Try calling using ?.call instead.""",
  withArgumentsOld: _withArgumentsOldNullableExpressionCallError,
  withArguments: _withArgumentsNullableExpressionCallError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNullableExpressionCallError({required DartType type}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    codeNullableExpressionCallError,
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
codeNullableInterfaceError = const Template(
  "NullableInterfaceError",
  problemMessageTemplate: r"""Can't implement '#name' because it's nullable.""",
  correctionMessageTemplate: r"""Try removing the question mark.""",
  withArgumentsOld: _withArgumentsOldNullableInterfaceError,
  withArguments: _withArgumentsNullableInterfaceError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNullableInterfaceError({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeNullableInterfaceError,
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
codeNullableMethodCallError = const Template(
  "NullableMethodCallError",
  problemMessageTemplate:
      r"""Method '#name' cannot be called on '#type' because it is potentially null.""",
  correctionMessageTemplate: r"""Try calling using ?. instead.""",
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
    codeNullableMethodCallError,
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
codeNullableMixinError = const Template(
  "NullableMixinError",
  problemMessageTemplate: r"""Can't mix '#name' in because it's nullable.""",
  correctionMessageTemplate: r"""Try removing the question mark.""",
  withArgumentsOld: _withArgumentsOldNullableMixinError,
  withArguments: _withArgumentsNullableMixinError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNullableMixinError({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeNullableMixinError,
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
codeNullableOperatorCallError = const Template(
  "NullableOperatorCallError",
  problemMessageTemplate:
      r"""Operator '#name' cannot be called on '#type' because it is potentially null.""",
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
    codeNullableOperatorCallError,
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
codeNullablePropertyAccessError = const Template(
  "NullablePropertyAccessError",
  problemMessageTemplate:
      r"""Property '#name' cannot be accessed on '#type' because it is potentially null.""",
  correctionMessageTemplate: r"""Try accessing using ?. instead.""",
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
    codeNullablePropertyAccessError,
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
const MessageCode codeNullableSpreadError = const MessageCode(
  "NullableSpreadError",
  problemMessage:
      r"""An expression whose value can be 'null' must be null-checked before it can be dereferenced.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeNullableSuperclassError = const Template(
  "NullableSuperclassError",
  problemMessageTemplate: r"""Can't extend '#name' because it's nullable.""",
  correctionMessageTemplate: r"""Try removing the question mark.""",
  withArgumentsOld: _withArgumentsOldNullableSuperclassError,
  withArguments: _withArgumentsNullableSuperclassError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNullableSuperclassError({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeNullableSuperclassError,
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
codeNullableTearoffError = const Template(
  "NullableTearoffError",
  problemMessageTemplate:
      r"""Can't tear off method '#name' from a potentially null value.""",
  withArgumentsOld: _withArgumentsOldNullableTearoffError,
  withArguments: _withArgumentsNullableTearoffError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNullableTearoffError({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeNullableTearoffError,
    problemMessage:
        """Can't tear off method '${name_0}' from a potentially null value.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldNullableTearoffError(String name) =>
    _withArgumentsNullableTearoffError(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeObjectExtends = const MessageCode(
  "ObjectExtends",
  problemMessage: r"""The class 'Object' can't have a superclass.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeObjectImplements = const MessageCode(
  "ObjectImplements",
  problemMessage: r"""The class 'Object' can't implement anything.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeObjectMemberNameUsedForRecordField = const MessageCode(
  "ObjectMemberNameUsedForRecordField",
  problemMessage:
      r"""Record field names can't be the same as a member from 'Object'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeObjectMixesIn = const MessageCode(
  "ObjectMixesIn",
  problemMessage: r"""The class 'Object' can't use mixins.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeObsoleteColonForDefaultValue = const MessageCode(
  "ObsoleteColonForDefaultValue",
  problemMessage:
      r"""Using a colon as a separator before a default value is no longer supported.""",
  correctionMessage: r"""Try replacing the colon with an equal sign.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeOperatorMinusParameterMismatch = const Template(
  "OperatorMinusParameterMismatch",
  problemMessageTemplate:
      r"""Operator '#name' should have zero or one parameter.""",
  correctionMessageTemplate:
      r"""With zero parameters, it has the syntactic form '-a', formally known as 'unary-'. With one parameter, it has the syntactic form 'a - b', formally known as '-'.""",
  withArgumentsOld: _withArgumentsOldOperatorMinusParameterMismatch,
  withArguments: _withArgumentsOperatorMinusParameterMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOperatorMinusParameterMismatch({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeOperatorMinusParameterMismatch,
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
codeOperatorParameterMismatch0 = const Template(
  "OperatorParameterMismatch0",
  problemMessageTemplate:
      r"""Operator '#name' shouldn't have any parameters.""",
  withArgumentsOld: _withArgumentsOldOperatorParameterMismatch0,
  withArguments: _withArgumentsOperatorParameterMismatch0,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOperatorParameterMismatch0({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeOperatorParameterMismatch0,
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
codeOperatorParameterMismatch1 = const Template(
  "OperatorParameterMismatch1",
  problemMessageTemplate:
      r"""Operator '#name' should have exactly one parameter.""",
  withArgumentsOld: _withArgumentsOldOperatorParameterMismatch1,
  withArguments: _withArgumentsOperatorParameterMismatch1,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOperatorParameterMismatch1({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeOperatorParameterMismatch1,
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
codeOperatorParameterMismatch2 = const Template(
  "OperatorParameterMismatch2",
  problemMessageTemplate:
      r"""Operator '#name' should have exactly two parameters.""",
  withArgumentsOld: _withArgumentsOldOperatorParameterMismatch2,
  withArguments: _withArgumentsOperatorParameterMismatch2,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOperatorParameterMismatch2({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeOperatorParameterMismatch2,
    problemMessage:
        """Operator '${name_0}' should have exactly two parameters.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldOperatorParameterMismatch2(String name) =>
    _withArgumentsOperatorParameterMismatch2(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeOperatorWithOptionalFormals = const MessageCode(
  "OperatorWithOptionalFormals",
  problemMessage: r"""An operator can't have optional parameters.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, DartType type),
  Message Function({required String name, required DartType type})
>
codeOptionalNonNullableWithoutInitializerError = const Template(
  "OptionalNonNullableWithoutInitializerError",
  problemMessageTemplate:
      r"""The parameter '#name' can't have a value of 'null' because of its type '#type', but the implicit default value is 'null'.""",
  correctionMessageTemplate:
      r"""Try adding either an explicit non-'null' default value or the 'required' modifier.""",
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
    codeOptionalNonNullableWithoutInitializerError,
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
const MessageCode codeOptionalParametersInExtensionTypeDeclaration =
    const MessageCode(
      "OptionalParametersInExtensionTypeDeclaration",
      problemMessage:
          r"""Extension type declarations can't have optional parameters.""",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type, String name),
  Message Function({required DartType type, required String name})
>
codeOptionalSuperParameterWithoutInitializer = const Template(
  "OptionalSuperParameterWithoutInitializer",
  problemMessageTemplate:
      r"""Type '#type' of the optional super-initializer parameter '#name' doesn't allow 'null', but the parameter doesn't have a default value, and the default value can't be copied from the corresponding parameter of the super constructor.""",
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
    codeOptionalSuperParameterWithoutInitializer,
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
  Message Function(String name),
  Message Function({required String name})
>
codeOverriddenMethodCause = const Template(
  "OverriddenMethodCause",
  problemMessageTemplate: r"""This is the overridden method ('#name').""",
  withArgumentsOld: _withArgumentsOldOverriddenMethodCause,
  withArguments: _withArgumentsOverriddenMethodCause,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverriddenMethodCause({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeOverriddenMethodCause,
    problemMessage: """This is the overridden method ('${name_0}').""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldOverriddenMethodCause(String name) =>
    _withArgumentsOverriddenMethodCause(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, String name2),
  Message Function({required String name, required String name2})
>
codeOverrideFewerNamedArguments = const Template(
  "OverrideFewerNamedArguments",
  problemMessageTemplate:
      r"""The method '#name' has fewer named arguments than those of overridden method '#name2'.""",
  withArgumentsOld: _withArgumentsOldOverrideFewerNamedArguments,
  withArguments: _withArgumentsOverrideFewerNamedArguments,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideFewerNamedArguments({
  required String name,
  required String name2,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var name2_0 = conversions.validateAndDemangleName(name2);
  return new Message(
    codeOverrideFewerNamedArguments,
    problemMessage:
        """The method '${name_0}' has fewer named arguments than those of overridden method '${name2_0}'.""",
    arguments: {'name': name, 'name2': name2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldOverrideFewerNamedArguments(
  String name,
  String name2,
) => _withArgumentsOverrideFewerNamedArguments(name: name, name2: name2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, String name2),
  Message Function({required String name, required String name2})
>
codeOverrideFewerPositionalArguments = const Template(
  "OverrideFewerPositionalArguments",
  problemMessageTemplate:
      r"""The method '#name' has fewer positional arguments than those of overridden method '#name2'.""",
  withArgumentsOld: _withArgumentsOldOverrideFewerPositionalArguments,
  withArguments: _withArgumentsOverrideFewerPositionalArguments,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideFewerPositionalArguments({
  required String name,
  required String name2,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var name2_0 = conversions.validateAndDemangleName(name2);
  return new Message(
    codeOverrideFewerPositionalArguments,
    problemMessage:
        """The method '${name_0}' has fewer positional arguments than those of overridden method '${name2_0}'.""",
    arguments: {'name': name, 'name2': name2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldOverrideFewerPositionalArguments(
  String name,
  String name2,
) => _withArgumentsOverrideFewerPositionalArguments(name: name, name2: name2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, String name2, String name3),
  Message Function({
    required String name,
    required String name2,
    required String name3,
  })
>
codeOverrideMismatchNamedParameter = const Template(
  "OverrideMismatchNamedParameter",
  problemMessageTemplate:
      r"""The method '#name' doesn't have the named parameter '#name2' of overridden method '#name3'.""",
  withArgumentsOld: _withArgumentsOldOverrideMismatchNamedParameter,
  withArguments: _withArgumentsOverrideMismatchNamedParameter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideMismatchNamedParameter({
  required String name,
  required String name2,
  required String name3,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var name2_0 = conversions.validateAndDemangleName(name2);
  var name3_0 = conversions.validateAndDemangleName(name3);
  return new Message(
    codeOverrideMismatchNamedParameter,
    problemMessage:
        """The method '${name_0}' doesn't have the named parameter '${name2_0}' of overridden method '${name3_0}'.""",
    arguments: {'name': name, 'name2': name2, 'name3': name3},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldOverrideMismatchNamedParameter(
  String name,
  String name2,
  String name3,
) => _withArgumentsOverrideMismatchNamedParameter(
  name: name,
  name2: name2,
  name3: name3,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, String name2, String name3),
  Message Function({
    required String name,
    required String name2,
    required String name3,
  })
>
codeOverrideMismatchRequiredNamedParameter = const Template(
  "OverrideMismatchRequiredNamedParameter",
  problemMessageTemplate:
      r"""The required named parameter '#name' in method '#name2' is not required in overridden method '#name3'.""",
  withArgumentsOld: _withArgumentsOldOverrideMismatchRequiredNamedParameter,
  withArguments: _withArgumentsOverrideMismatchRequiredNamedParameter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideMismatchRequiredNamedParameter({
  required String name,
  required String name2,
  required String name3,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var name2_0 = conversions.validateAndDemangleName(name2);
  var name3_0 = conversions.validateAndDemangleName(name3);
  return new Message(
    codeOverrideMismatchRequiredNamedParameter,
    problemMessage:
        """The required named parameter '${name_0}' in method '${name2_0}' is not required in overridden method '${name3_0}'.""",
    arguments: {'name': name, 'name2': name2, 'name3': name3},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldOverrideMismatchRequiredNamedParameter(
  String name,
  String name2,
  String name3,
) => _withArgumentsOverrideMismatchRequiredNamedParameter(
  name: name,
  name2: name2,
  name3: name3,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, String name2),
  Message Function({required String name, required String name2})
>
codeOverrideMoreRequiredArguments = const Template(
  "OverrideMoreRequiredArguments",
  problemMessageTemplate:
      r"""The method '#name' has more required arguments than those of overridden method '#name2'.""",
  withArgumentsOld: _withArgumentsOldOverrideMoreRequiredArguments,
  withArguments: _withArgumentsOverrideMoreRequiredArguments,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideMoreRequiredArguments({
  required String name,
  required String name2,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var name2_0 = conversions.validateAndDemangleName(name2);
  return new Message(
    codeOverrideMoreRequiredArguments,
    problemMessage:
        """The method '${name_0}' has more required arguments than those of overridden method '${name2_0}'.""",
    arguments: {'name': name, 'name2': name2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldOverrideMoreRequiredArguments(
  String name,
  String name2,
) => _withArgumentsOverrideMoreRequiredArguments(name: name, name2: name2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(
    String name,
    String name2,
    DartType type,
    DartType type2,
    String name3,
  ),
  Message Function({
    required String name,
    required String name2,
    required DartType type,
    required DartType type2,
    required String name3,
  })
>
codeOverrideTypeMismatchParameter = const Template(
  "OverrideTypeMismatchParameter",
  problemMessageTemplate:
      r"""The parameter '#name' of the method '#name2' has type '#type', which does not match the corresponding type, '#type2', in the overridden method, '#name3'.""",
  correctionMessageTemplate:
      r"""Change to a supertype of '#type2', or, for a covariant parameter, a subtype.""",
  withArgumentsOld: _withArgumentsOldOverrideTypeMismatchParameter,
  withArguments: _withArgumentsOverrideTypeMismatchParameter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideTypeMismatchParameter({
  required String name,
  required String name2,
  required DartType type,
  required DartType type2,
  required String name3,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var name2_0 = conversions.validateAndDemangleName(name2);
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var type2_0 = labeler.labelType(type2);
  var name3_0 = conversions.validateAndDemangleName(name3);
  return new Message(
    codeOverrideTypeMismatchParameter,
    problemMessage:
        """The parameter '${name_0}' of the method '${name2_0}' has type '${type_0}', which does not match the corresponding type, '${type2_0}', in the overridden method, '${name3_0}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Change to a supertype of '${type2_0}', or, for a covariant parameter, a subtype.""",
    arguments: {
      'name': name,
      'name2': name2,
      'type': type,
      'type2': type2,
      'name3': name3,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldOverrideTypeMismatchParameter(
  String name,
  String name2,
  DartType type,
  DartType type2,
  String name3,
) => _withArgumentsOverrideTypeMismatchParameter(
  name: name,
  name2: name2,
  type: type,
  type2: type2,
  name3: name3,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, DartType type, DartType type2, String name2),
  Message Function({
    required String name,
    required DartType type,
    required DartType type2,
    required String name2,
  })
>
codeOverrideTypeMismatchReturnType = const Template(
  "OverrideTypeMismatchReturnType",
  problemMessageTemplate:
      r"""The return type of the method '#name' is '#type', which does not match the return type, '#type2', of the overridden method, '#name2'.""",
  correctionMessageTemplate: r"""Change to a subtype of '#type2'.""",
  withArgumentsOld: _withArgumentsOldOverrideTypeMismatchReturnType,
  withArguments: _withArgumentsOverrideTypeMismatchReturnType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideTypeMismatchReturnType({
  required String name,
  required DartType type,
  required DartType type2,
  required String name2,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var type2_0 = labeler.labelType(type2);
  var name2_0 = conversions.validateAndDemangleName(name2);
  return new Message(
    codeOverrideTypeMismatchReturnType,
    problemMessage:
        """The return type of the method '${name_0}' is '${type_0}', which does not match the return type, '${type2_0}', of the overridden method, '${name2_0}'.""" +
        labeler.originMessages,
    correctionMessage: """Change to a subtype of '${type2_0}'.""",
    arguments: {'name': name, 'type': type, 'type2': type2, 'name2': name2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldOverrideTypeMismatchReturnType(
  String name,
  DartType type,
  DartType type2,
  String name2,
) => _withArgumentsOverrideTypeMismatchReturnType(
  name: name,
  type: type,
  type2: type2,
  name2: name2,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, DartType type, DartType type2, String name2),
  Message Function({
    required String name,
    required DartType type,
    required DartType type2,
    required String name2,
  })
>
codeOverrideTypeMismatchSetter = const Template(
  "OverrideTypeMismatchSetter",
  problemMessageTemplate:
      r"""The field '#name' has type '#type', which does not match the corresponding type, '#type2', in the overridden setter, '#name2'.""",
  withArgumentsOld: _withArgumentsOldOverrideTypeMismatchSetter,
  withArguments: _withArgumentsOverrideTypeMismatchSetter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideTypeMismatchSetter({
  required String name,
  required DartType type,
  required DartType type2,
  required String name2,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var type2_0 = labeler.labelType(type2);
  var name2_0 = conversions.validateAndDemangleName(name2);
  return new Message(
    codeOverrideTypeMismatchSetter,
    problemMessage:
        """The field '${name_0}' has type '${type_0}', which does not match the corresponding type, '${type2_0}', in the overridden setter, '${name2_0}'.""" +
        labeler.originMessages,
    arguments: {'name': name, 'type': type, 'type2': type2, 'name2': name2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldOverrideTypeMismatchSetter(
  String name,
  DartType type,
  DartType type2,
  String name2,
) => _withArgumentsOverrideTypeMismatchSetter(
  name: name,
  type: type,
  type2: type2,
  name2: name2,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(
    DartType type,
    String name,
    String name2,
    DartType type2,
    String name3,
  ),
  Message Function({
    required DartType type,
    required String name,
    required String name2,
    required DartType type2,
    required String name3,
  })
>
codeOverrideTypeParametersBoundMismatch = const Template(
  "OverrideTypeParametersBoundMismatch",
  problemMessageTemplate:
      r"""Declared bound '#type' of type variable '#name' of '#name2' doesn't match the bound '#type2' on overridden method '#name3'.""",
  withArgumentsOld: _withArgumentsOldOverrideTypeParametersBoundMismatch,
  withArguments: _withArgumentsOverrideTypeParametersBoundMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideTypeParametersBoundMismatch({
  required DartType type,
  required String name,
  required String name2,
  required DartType type2,
  required String name3,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  var name_0 = conversions.validateAndDemangleName(name);
  var name2_0 = conversions.validateAndDemangleName(name2);
  var type2_0 = labeler.labelType(type2);
  var name3_0 = conversions.validateAndDemangleName(name3);
  return new Message(
    codeOverrideTypeParametersBoundMismatch,
    problemMessage:
        """Declared bound '${type_0}' of type variable '${name_0}' of '${name2_0}' doesn't match the bound '${type2_0}' on overridden method '${name3_0}'.""" +
        labeler.originMessages,
    arguments: {
      'type': type,
      'name': name,
      'name2': name2,
      'type2': type2,
      'name3': name3,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldOverrideTypeParametersBoundMismatch(
  DartType type,
  String name,
  String name2,
  DartType type2,
  String name3,
) => _withArgumentsOverrideTypeParametersBoundMismatch(
  type: type,
  name: name,
  name2: name2,
  type2: type2,
  name3: name3,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, String name2),
  Message Function({required String name, required String name2})
>
codeOverrideTypeParametersMismatch = const Template(
  "OverrideTypeParametersMismatch",
  problemMessageTemplate:
      r"""Declared type variables of '#name' doesn't match those on overridden method '#name2'.""",
  withArgumentsOld: _withArgumentsOldOverrideTypeParametersMismatch,
  withArguments: _withArgumentsOverrideTypeParametersMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideTypeParametersMismatch({
  required String name,
  required String name2,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var name2_0 = conversions.validateAndDemangleName(name2);
  return new Message(
    codeOverrideTypeParametersMismatch,
    problemMessage:
        """Declared type variables of '${name_0}' doesn't match those on overridden method '${name2_0}'.""",
    arguments: {'name': name, 'name2': name2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldOverrideTypeParametersMismatch(
  String name,
  String name2,
) => _withArgumentsOverrideTypeParametersMismatch(name: name, name2: name2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, Uri uri),
  Message Function({required String name, required Uri uri})
>
codePackageNotFound = const Template(
  "PackageNotFound",
  problemMessageTemplate:
      r"""Couldn't resolve the package '#name' in '#uri'.""",
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
    codePackageNotFound,
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
codePackagesFileFormat = const Template(
  "PackagesFileFormat",
  problemMessageTemplate:
      r"""Problem in packages configuration file: #string""",
  withArgumentsOld: _withArgumentsOldPackagesFileFormat,
  withArguments: _withArgumentsPackagesFileFormat,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsPackagesFileFormat({required String string}) {
  var string_0 = conversions.validateString(string);
  return new Message(
    codePackagesFileFormat,
    problemMessage: """Problem in packages configuration file: ${string_0}""",
    arguments: {'string': string},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldPackagesFileFormat(String string) =>
    _withArgumentsPackagesFileFormat(string: string);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codePartExport = const MessageCode(
  "PartExport",
  problemMessage:
      r"""Can't export this file because it contains a 'part of' declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codePartExportContext = const MessageCode(
  "PartExportContext",
  severity: CfeSeverity.context,
  problemMessage: r"""This is the file that can't be exported.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codePartInPart = const MessageCode(
  "PartInPart",
  problemMessage:
      r"""A file that's a part of a library can't have parts itself.""",
  correctionMessage:
      r"""Try moving the 'part' declaration to the containing library.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codePartInPartLibraryContext = const MessageCode(
  "PartInPartLibraryContext",
  severity: CfeSeverity.context,
  problemMessage: r"""This is the containing library.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri), Message Function({required Uri uri})>
codePartOfInLibrary = const Template(
  "PartOfInLibrary",
  problemMessageTemplate:
      r"""Can't import '#uri', because it has a 'part of' declaration.""",
  correctionMessageTemplate:
      r"""Try removing the 'part of' declaration, or using '#uri' as a part.""",
  withArgumentsOld: _withArgumentsOldPartOfInLibrary,
  withArguments: _withArgumentsPartOfInLibrary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsPartOfInLibrary({required Uri uri}) {
  var uri_0 = conversions.relativizeUri(uri);
  return new Message(
    codePartOfInLibrary,
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
  Message Function(Uri uri, String name, String name2),
  Message Function({
    required Uri uri,
    required String name,
    required String name2,
  })
>
codePartOfLibraryNameMismatch = const Template(
  "PartOfLibraryNameMismatch",
  problemMessageTemplate:
      r"""Using '#uri' as part of '#name' but its 'part of' declaration says '#name2'.""",
  withArgumentsOld: _withArgumentsOldPartOfLibraryNameMismatch,
  withArguments: _withArgumentsPartOfLibraryNameMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsPartOfLibraryNameMismatch({
  required Uri uri,
  required String name,
  required String name2,
}) {
  var uri_0 = conversions.relativizeUri(uri);
  var name_0 = conversions.validateAndDemangleName(name);
  var name2_0 = conversions.validateAndDemangleName(name2);
  return new Message(
    codePartOfLibraryNameMismatch,
    problemMessage:
        """Using '${uri_0}' as part of '${name_0}' but its 'part of' declaration says '${name2_0}'.""",
    arguments: {'uri': uri, 'name': name, 'name2': name2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldPartOfLibraryNameMismatch(
  Uri uri,
  String name,
  String name2,
) =>
    _withArgumentsPartOfLibraryNameMismatch(uri: uri, name: name, name2: name2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codePartOfSelf = const MessageCode(
  "PartOfSelf",
  problemMessage: r"""A file can't be a part of itself.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codePartOfTwoLibraries = const MessageCode(
  "PartOfTwoLibraries",
  problemMessage: r"""A file can't be part of more than one library.""",
  correctionMessage:
      r"""Try moving the shared declarations into the libraries, or into a new library.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codePartOfTwoLibrariesContext = const MessageCode(
  "PartOfTwoLibrariesContext",
  severity: CfeSeverity.context,
  problemMessage: r"""Used as a part in this library.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Uri uri, Uri uri2, Uri uri3),
  Message Function({required Uri uri, required Uri uri2, required Uri uri3})
>
codePartOfUriMismatch = const Template(
  "PartOfUriMismatch",
  problemMessageTemplate:
      r"""Using '#uri' as part of '#uri2' but its 'part of' declaration says '#uri3'.""",
  withArgumentsOld: _withArgumentsOldPartOfUriMismatch,
  withArguments: _withArgumentsPartOfUriMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsPartOfUriMismatch({
  required Uri uri,
  required Uri uri2,
  required Uri uri3,
}) {
  var uri_0 = conversions.relativizeUri(uri);
  var uri2_0 = conversions.relativizeUri(uri2);
  var uri3_0 = conversions.relativizeUri(uri3);
  return new Message(
    codePartOfUriMismatch,
    problemMessage:
        """Using '${uri_0}' as part of '${uri2_0}' but its 'part of' declaration says '${uri3_0}'.""",
    arguments: {'uri': uri, 'uri2': uri2, 'uri3': uri3},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldPartOfUriMismatch(Uri uri, Uri uri2, Uri uri3) =>
    _withArgumentsPartOfUriMismatch(uri: uri, uri2: uri2, uri3: uri3);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Uri uri, Uri uri2, String name),
  Message Function({required Uri uri, required Uri uri2, required String name})
>
codePartOfUseUri = const Template(
  "PartOfUseUri",
  problemMessageTemplate:
      r"""Using '#uri' as part of '#uri2' but its 'part of' declaration says '#name'.""",
  correctionMessageTemplate:
      r"""Try changing the 'part of' declaration to use a relative file name.""",
  withArgumentsOld: _withArgumentsOldPartOfUseUri,
  withArguments: _withArgumentsPartOfUseUri,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsPartOfUseUri({
  required Uri uri,
  required Uri uri2,
  required String name,
}) {
  var uri_0 = conversions.relativizeUri(uri);
  var uri2_0 = conversions.relativizeUri(uri2);
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codePartOfUseUri,
    problemMessage:
        """Using '${uri_0}' as part of '${uri2_0}' but its 'part of' declaration says '${name_0}'.""",
    correctionMessage:
        """Try changing the 'part of' declaration to use a relative file name.""",
    arguments: {'uri': uri, 'uri2': uri2, 'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldPartOfUseUri(Uri uri, Uri uri2, String name) =>
    _withArgumentsPartOfUseUri(uri: uri, uri2: uri2, name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codePartOrphan = const MessageCode(
  "PartOrphan",
  problemMessage: r"""This part doesn't have a containing library.""",
  correctionMessage: r"""Try removing the 'part of' declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri), Message Function({required Uri uri})>
codePartTwice = const Template(
  "PartTwice",
  problemMessageTemplate: r"""Can't use '#uri' as a part more than once.""",
  withArgumentsOld: _withArgumentsOldPartTwice,
  withArguments: _withArgumentsPartTwice,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsPartTwice({required Uri uri}) {
  var uri_0 = conversions.relativizeUri(uri);
  return new Message(
    codePartTwice,
    problemMessage: """Can't use '${uri_0}' as a part more than once.""",
    arguments: {'uri': uri},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldPartTwice(Uri uri) =>
    _withArgumentsPartTwice(uri: uri);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codePatchClassOrigin = const MessageCode(
  "PatchClassOrigin",
  severity: CfeSeverity.context,
  problemMessage: r"""This is the origin class.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codePatchClassTypeParametersMismatch = const MessageCode(
  "PatchClassTypeParametersMismatch",
  problemMessage:
      r"""A patch class must have the same number of type variables as its origin class.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codePatchDeclarationOrigin = const MessageCode(
  "PatchDeclarationOrigin",
  severity: CfeSeverity.context,
  problemMessage: r"""This is the origin declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codePatchExtensionOrigin = const MessageCode(
  "PatchExtensionOrigin",
  severity: CfeSeverity.context,
  problemMessage: r"""This is the origin extension.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codePatchExtensionTypeParametersMismatch = const MessageCode(
  "PatchExtensionTypeParametersMismatch",
  problemMessage:
      r"""A patch extension must have the same number of type variables as its origin extension.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, Uri uri),
  Message Function({required String name, required Uri uri})
>
codePatchInjectionFailed = const Template(
  "PatchInjectionFailed",
  problemMessageTemplate: r"""Can't inject public '#name' into '#uri'.""",
  correctionMessageTemplate:
      r"""Make '#name' private, or make sure injected library has "dart" scheme and is private (e.g. "dart:_internal").""",
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
    codePatchInjectionFailed,
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
const MessageCode codePatternAssignmentNotLocalVariable = const MessageCode(
  "PatternAssignmentNotLocalVariable",
  problemMessage:
      r"""Only local variables or formal parameters can be used in pattern assignments.""",
  correctionMessage: r"""Try assigning to a local variable.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codePatternMatchingError = const MessageCode(
  "PatternMatchingError",
  problemMessage: r"""Pattern matching error""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type, DartType type2),
  Message Function({required DartType type, required DartType type2})
>
codePatternTypeMismatchInIrrefutableContext = const Template(
  "PatternTypeMismatchInIrrefutableContext",
  problemMessageTemplate:
      r"""The matched value of type '#type' isn't assignable to the required type '#type2'.""",
  correctionMessageTemplate:
      r"""Try changing the required type of the pattern, or the matched value type.""",
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
    codePatternTypeMismatchInIrrefutableContext,
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
const MessageCode codePatternVariableAssignmentInsideGuard = const MessageCode(
  "PatternVariableAssignmentInsideGuard",
  problemMessage:
      r"""Pattern variables can't be assigned inside the guard of the enclosing guarded pattern.""",
  correctionMessage: r"""Try assigning to a different variable.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codePlatformPrivateLibraryAccess = const MessageCode(
  "PlatformPrivateLibraryAccess",
  problemMessage: r"""Can't access platform private library.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codePositionalSuperParametersAndArguments = const MessageCode(
  "PositionalSuperParametersAndArguments",
  problemMessage:
      r"""Positional super-initializer parameters cannot be used when the super initializer has positional arguments.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeRecordFieldsCantBePrivate = const MessageCode(
  "RecordFieldsCantBePrivate",
  problemMessage: r"""Record field names can't be private.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeRecordUseCannotBePlacedHere = const MessageCode(
  "RecordUseCannotBePlacedHere",
  problemMessage:
      r"""`RecordUse` annotation cannot be placed on this element.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeRecordUsedAsCallable = const MessageCode(
  "RecordUsedAsCallable",
  problemMessage:
      r"""The 'call' property on the record type isn't directly callable but could be invoked by `.call(...)`""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeRedirectingConstructorWithAnotherInitializer =
    const MessageCode(
      "RedirectingConstructorWithAnotherInitializer",
      problemMessage:
          r"""A redirecting constructor can't have other initializers.""",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
codeRedirectingConstructorWithMultipleRedirectInitializers = const MessageCode(
  "RedirectingConstructorWithMultipleRedirectInitializers",
  problemMessage:
      r"""A redirecting constructor can't have more than one redirection.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeRedirectingConstructorWithSuperInitializer =
    const MessageCode(
      "RedirectingConstructorWithSuperInitializer",
      problemMessage:
          r"""A redirecting constructor can't have a 'super' initializer.""",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type, DartType type2),
  Message Function({required DartType type, required DartType type2})
>
codeRedirectingFactoryIncompatibleTypeArgument = const Template(
  "RedirectingFactoryIncompatibleTypeArgument",
  problemMessageTemplate: r"""The type '#type' doesn't extend '#type2'.""",
  correctionMessageTemplate: r"""Try using a different type as argument.""",
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
    codeRedirectingFactoryIncompatibleTypeArgument,
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
codeRedirectionTargetNotFound = const Template(
  "RedirectionTargetNotFound",
  problemMessageTemplate:
      r"""Redirection constructor target not found: '#name'""",
  withArgumentsOld: _withArgumentsOldRedirectionTargetNotFound,
  withArguments: _withArgumentsRedirectionTargetNotFound,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsRedirectionTargetNotFound({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeRedirectionTargetNotFound,
    problemMessage: """Redirection constructor target not found: '${name_0}'""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldRedirectionTargetNotFound(String name) =>
    _withArgumentsRedirectionTargetNotFound(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeRefutablePatternInIrrefutableContext = const MessageCode(
  "RefutablePatternInIrrefutableContext",
  problemMessage:
      r"""Refutable patterns can't be used in an irrefutable context.""",
  correctionMessage:
      r"""Try using an if-case, a 'switch' statement, or a 'switch' expression instead.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeRepresentationFieldModifier = const MessageCode(
  "RepresentationFieldModifier",
  problemMessage: r"""Representation fields can't have modifiers.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeRepresentationFieldTrailingComma = const MessageCode(
  "RepresentationFieldTrailingComma",
  problemMessage: r"""The representation field can't have a trailing comma.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeRequiredNamedParameterHasDefaultValueError = const Template(
  "RequiredNamedParameterHasDefaultValueError",
  problemMessageTemplate:
      r"""Named parameter '#name' is required and can't have a default value.""",
  withArgumentsOld: _withArgumentsOldRequiredNamedParameterHasDefaultValueError,
  withArguments: _withArgumentsRequiredNamedParameterHasDefaultValueError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsRequiredNamedParameterHasDefaultValueError({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeRequiredNamedParameterHasDefaultValueError,
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
const MessageCode codeRestPatternInMapPattern = const MessageCode(
  "RestPatternInMapPattern",
  problemMessage: r"""The '...' pattern can't appear in map patterns.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeRethrowNotCatch = const MessageCode(
  "RethrowNotCatch",
  problemMessage: r"""'rethrow' can only be used in catch clauses.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeReturnFromVoidFunction = const MessageCode(
  "ReturnFromVoidFunction",
  problemMessage: r"""Can't return a value from a void function.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeReturnWithoutExpressionAsync = const MessageCode(
  "ReturnWithoutExpressionAsync",
  problemMessage:
      r"""A value must be explicitly returned from a non-void async function.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeReturnWithoutExpressionSync = const MessageCode(
  "ReturnWithoutExpressionSync",
  problemMessage:
      r"""A value must be explicitly returned from a non-void function.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeScriptTagInPartFile = const MessageCode(
  "ScriptTagInPartFile",
  problemMessage: r"""A part file cannot have script tag.""",
  correctionMessage:
      r"""Try removing the script tag or the 'part of' directive.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri), Message Function({required Uri uri})>
codeSdkRootNotFound = const Template(
  "SdkRootNotFound",
  problemMessageTemplate: r"""SDK root directory not found: #uri.""",
  withArgumentsOld: _withArgumentsOldSdkRootNotFound,
  withArguments: _withArgumentsSdkRootNotFound,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSdkRootNotFound({required Uri uri}) {
  var uri_0 = conversions.relativizeUri(uri);
  return new Message(
    codeSdkRootNotFound,
    problemMessage: """SDK root directory not found: ${uri_0}.""",
    arguments: {'uri': uri},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldSdkRootNotFound(Uri uri) =>
    _withArgumentsSdkRootNotFound(uri: uri);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri), Message Function({required Uri uri})>
codeSdkSpecificationNotFound = const Template(
  "SdkSpecificationNotFound",
  problemMessageTemplate: r"""SDK libraries specification not found: #uri.""",
  correctionMessageTemplate:
      r"""Normally, the specification is a file named 'libraries.json' in the Dart SDK install location.""",
  withArgumentsOld: _withArgumentsOldSdkSpecificationNotFound,
  withArguments: _withArgumentsSdkSpecificationNotFound,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSdkSpecificationNotFound({required Uri uri}) {
  var uri_0 = conversions.relativizeUri(uri);
  return new Message(
    codeSdkSpecificationNotFound,
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
codeSdkSummaryNotFound = const Template(
  "SdkSummaryNotFound",
  problemMessageTemplate: r"""SDK summary not found: #uri.""",
  withArgumentsOld: _withArgumentsOldSdkSummaryNotFound,
  withArguments: _withArgumentsSdkSummaryNotFound,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSdkSummaryNotFound({required Uri uri}) {
  var uri_0 = conversions.relativizeUri(uri);
  return new Message(
    codeSdkSummaryNotFound,
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
codeSealedClassSubtypeOutsideOfLibrary = const Template(
  "SealedClassSubtypeOutsideOfLibrary",
  problemMessageTemplate:
      r"""The class '#name' can't be extended, implemented, or mixed in outside of its library because it's a sealed class.""",
  withArgumentsOld: _withArgumentsOldSealedClassSubtypeOutsideOfLibrary,
  withArguments: _withArgumentsSealedClassSubtypeOutsideOfLibrary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSealedClassSubtypeOutsideOfLibrary({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeSealedClassSubtypeOutsideOfLibrary,
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
  Message Function(String name),
  Message Function({required String name})
>
codeSetterConflictsWithDeclaration = const Template(
  "SetterConflictsWithDeclaration",
  problemMessageTemplate: r"""The setter conflicts with declaration '#name'.""",
  withArgumentsOld: _withArgumentsOldSetterConflictsWithDeclaration,
  withArguments: _withArgumentsSetterConflictsWithDeclaration,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSetterConflictsWithDeclaration({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeSetterConflictsWithDeclaration,
    problemMessage: """The setter conflicts with declaration '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldSetterConflictsWithDeclaration(String name) =>
    _withArgumentsSetterConflictsWithDeclaration(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeSetterConflictsWithDeclarationCause = const Template(
  "SetterConflictsWithDeclarationCause",
  problemMessageTemplate: r"""Conflicting declaration '#name'.""",
  withArgumentsOld: _withArgumentsOldSetterConflictsWithDeclarationCause,
  withArguments: _withArgumentsSetterConflictsWithDeclarationCause,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSetterConflictsWithDeclarationCause({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeSetterConflictsWithDeclarationCause,
    problemMessage: """Conflicting declaration '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldSetterConflictsWithDeclarationCause(String name) =>
    _withArgumentsSetterConflictsWithDeclarationCause(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeSetterNotFound = const Template(
  "SetterNotFound",
  problemMessageTemplate: r"""Setter not found: '#name'.""",
  withArgumentsOld: _withArgumentsOldSetterNotFound,
  withArguments: _withArgumentsSetterNotFound,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSetterNotFound({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeSetterNotFound,
    problemMessage: """Setter not found: '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldSetterNotFound(String name) =>
    _withArgumentsSetterNotFound(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeSetterWithWrongNumberOfFormals = const MessageCode(
  "SetterWithWrongNumberOfFormals",
  problemMessage: r"""A setter should have exactly one formal parameter.""",
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
codeSourceBodySummary = const Template(
  "SourceBodySummary",
  problemMessageTemplate:
      r"""Built bodies for #count compilation units (#count2 bytes) in #num1%.3ms, that is,
#num2%12.3 bytes/ms, and
#num3%12.3 ms/compilation unit.""",
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
    codeSourceBodySummary,
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
codeSourceOutlineSummary = const Template(
  "SourceOutlineSummary",
  problemMessageTemplate:
      r"""Built outlines for #count compilation units (#count2 bytes) in #num1%.3ms, that is,
#num2%12.3 bytes/ms, and
#num3%12.3 ms/compilation unit.""",
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
    codeSourceOutlineSummary,
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
const MessageCode codeSpreadElement = const MessageCode(
  "SpreadElement",
  severity: CfeSeverity.context,
  problemMessage: r"""Iterable spread.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type, DartType type2),
  Message Function({required DartType type, required DartType type2})
>
codeSpreadElementTypeMismatch = const Template(
  "SpreadElementTypeMismatch",
  problemMessageTemplate:
      r"""Can't assign spread elements of type '#type' to collection elements of type '#type2'.""",
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
    codeSpreadElementTypeMismatch,
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
const MessageCode codeSpreadMapElement = const MessageCode(
  "SpreadMapElement",
  severity: CfeSeverity.context,
  problemMessage: r"""Map spread.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type, DartType type2),
  Message Function({required DartType type, required DartType type2})
>
codeSpreadMapEntryElementKeyTypeMismatch = const Template(
  "SpreadMapEntryElementKeyTypeMismatch",
  problemMessageTemplate:
      r"""Can't assign spread entry keys of type '#type' to map entry keys of type '#type2'.""",
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
    codeSpreadMapEntryElementKeyTypeMismatch,
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
codeSpreadMapEntryElementValueTypeMismatch = const Template(
  "SpreadMapEntryElementValueTypeMismatch",
  problemMessageTemplate:
      r"""Can't assign spread entry values of type '#type' to map entry values of type '#type2'.""",
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
    codeSpreadMapEntryElementValueTypeMismatch,
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
codeSpreadMapEntryTypeMismatch = const Template(
  "SpreadMapEntryTypeMismatch",
  problemMessageTemplate:
      r"""Unexpected type '#type' of a map spread entry.  Expected 'dynamic' or a Map.""",
  withArgumentsOld: _withArgumentsOldSpreadMapEntryTypeMismatch,
  withArguments: _withArgumentsSpreadMapEntryTypeMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSpreadMapEntryTypeMismatch({required DartType type}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    codeSpreadMapEntryTypeMismatch,
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
codeSpreadTypeMismatch = const Template(
  "SpreadTypeMismatch",
  problemMessageTemplate:
      r"""Unexpected type '#type' of a spread.  Expected 'dynamic' or an Iterable.""",
  withArgumentsOld: _withArgumentsOldSpreadTypeMismatch,
  withArguments: _withArgumentsSpreadTypeMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSpreadTypeMismatch({required DartType type}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    codeSpreadTypeMismatch,
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
  Message Function(String name),
  Message Function({required String name})
>
codeStaticConflictsWithInstance = const Template(
  "StaticConflictsWithInstance",
  problemMessageTemplate:
      r"""Static property '#name' conflicts with instance property of the same name.""",
  withArgumentsOld: _withArgumentsOldStaticConflictsWithInstance,
  withArguments: _withArgumentsStaticConflictsWithInstance,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsStaticConflictsWithInstance({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeStaticConflictsWithInstance,
    problemMessage:
        """Static property '${name_0}' conflicts with instance property of the same name.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldStaticConflictsWithInstance(String name) =>
    _withArgumentsStaticConflictsWithInstance(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeStaticConflictsWithInstanceCause = const Template(
  "StaticConflictsWithInstanceCause",
  problemMessageTemplate: r"""Conflicting instance property '#name'.""",
  withArgumentsOld: _withArgumentsOldStaticConflictsWithInstanceCause,
  withArguments: _withArgumentsStaticConflictsWithInstanceCause,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsStaticConflictsWithInstanceCause({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeStaticConflictsWithInstanceCause,
    problemMessage: """Conflicting instance property '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldStaticConflictsWithInstanceCause(String name) =>
    _withArgumentsStaticConflictsWithInstanceCause(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeStaticTearOffFromInstantiatedClass = const MessageCode(
  "StaticTearOffFromInstantiatedClass",
  problemMessage:
      r"""Cannot access static member on an instantiated generic class.""",
  correctionMessage:
      r"""Try removing the type arguments or placing them after the member name.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, String name2),
  Message Function({required String name, required String name2})
>
codeSubtypeOfBaseIsNotBaseFinalOrSealed = const Template(
  "SubtypeOfBaseIsNotBaseFinalOrSealed",
  problemMessageTemplate:
      r"""The type '#name' must be 'base', 'final' or 'sealed' because the supertype '#name2' is 'base'.""",
  correctionMessageTemplate:
      r"""Try adding 'base', 'final', or 'sealed' to the type.""",
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
    codeSubtypeOfBaseIsNotBaseFinalOrSealed,
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
codeSubtypeOfFinalIsNotBaseFinalOrSealed = const Template(
  "SubtypeOfFinalIsNotBaseFinalOrSealed",
  problemMessageTemplate:
      r"""The type '#name' must be 'base', 'final' or 'sealed' because the supertype '#name2' is 'final'.""",
  correctionMessageTemplate:
      r"""Try adding 'base', 'final', or 'sealed' to the type.""",
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
    codeSubtypeOfFinalIsNotBaseFinalOrSealed,
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
const MessageCode codeSuperAsExpression = const MessageCode(
  "SuperAsExpression",
  problemMessage: r"""Can't use 'super' as an expression.""",
  correctionMessage:
      r"""To delegate a constructor to a super constructor, put the super call as an initializer.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeSuperAsIdentifier = const MessageCode(
  "SuperAsIdentifier",
  problemMessage: r"""Expected identifier, but got 'super'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type, DartType type2),
  Message Function({required DartType type, required DartType type2})
>
codeSuperBoundedHint = const Template(
  "SuperBoundedHint",
  problemMessageTemplate:
      r"""If you want '#type' to be a super-bounded type, note that the inverted type '#type2' must then satisfy its bounds, which it does not.""",
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
    codeSuperBoundedHint,
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
  Message Function(String name),
  Message Function({required String name})
>
codeSuperExtensionTypeIsIllegal = const Template(
  "SuperExtensionTypeIsIllegal",
  problemMessageTemplate:
      r"""The type '#name' can't be implemented by an extension type.""",
  withArgumentsOld: _withArgumentsOldSuperExtensionTypeIsIllegal,
  withArguments: _withArgumentsSuperExtensionTypeIsIllegal,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperExtensionTypeIsIllegal({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeSuperExtensionTypeIsIllegal,
    problemMessage:
        """The type '${name_0}' can't be implemented by an extension type.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldSuperExtensionTypeIsIllegal(String name) =>
    _withArgumentsSuperExtensionTypeIsIllegal(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, DartType type),
  Message Function({required String name, required DartType type})
>
codeSuperExtensionTypeIsIllegalAliased = const Template(
  "SuperExtensionTypeIsIllegalAliased",
  problemMessageTemplate:
      r"""The type '#name' which is an alias of '#type' can't be implemented by an extension type.""",
  withArgumentsOld: _withArgumentsOldSuperExtensionTypeIsIllegalAliased,
  withArguments: _withArgumentsSuperExtensionTypeIsIllegalAliased,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperExtensionTypeIsIllegalAliased({
  required String name,
  required DartType type,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    codeSuperExtensionTypeIsIllegalAliased,
    problemMessage:
        """The type '${name_0}' which is an alias of '${type_0}' can't be implemented by an extension type.""" +
        labeler.originMessages,
    arguments: {'name': name, 'type': type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldSuperExtensionTypeIsIllegalAliased(
  String name,
  DartType type,
) => _withArgumentsSuperExtensionTypeIsIllegalAliased(name: name, type: type);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, DartType type),
  Message Function({required String name, required DartType type})
>
codeSuperExtensionTypeIsNullableAliased = const Template(
  "SuperExtensionTypeIsNullableAliased",
  problemMessageTemplate:
      r"""The type '#name' which is an alias of '#type' can't be implemented by an extension type because it is nullable.""",
  withArgumentsOld: _withArgumentsOldSuperExtensionTypeIsNullableAliased,
  withArguments: _withArgumentsSuperExtensionTypeIsNullableAliased,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperExtensionTypeIsNullableAliased({
  required String name,
  required DartType type,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    codeSuperExtensionTypeIsNullableAliased,
    problemMessage:
        """The type '${name_0}' which is an alias of '${type_0}' can't be implemented by an extension type because it is nullable.""" +
        labeler.originMessages,
    arguments: {'name': name, 'type': type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldSuperExtensionTypeIsNullableAliased(
  String name,
  DartType type,
) => _withArgumentsSuperExtensionTypeIsNullableAliased(name: name, type: type);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeSuperExtensionTypeIsTypeParameter = const Template(
  "SuperExtensionTypeIsTypeParameter",
  problemMessageTemplate:
      r"""The type variable '#name' can't be implemented by an extension type.""",
  withArgumentsOld: _withArgumentsOldSuperExtensionTypeIsTypeParameter,
  withArguments: _withArgumentsSuperExtensionTypeIsTypeParameter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperExtensionTypeIsTypeParameter({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeSuperExtensionTypeIsTypeParameter,
    problemMessage:
        """The type variable '${name_0}' can't be implemented by an extension type.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldSuperExtensionTypeIsTypeParameter(String name) =>
    _withArgumentsSuperExtensionTypeIsTypeParameter(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeSuperInitializerNotLast = const MessageCode(
  "SuperInitializerNotLast",
  problemMessage: r"""Can't have initializers after 'super'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeSuperInitializerParameter = const MessageCode(
  "SuperInitializerParameter",
  severity: CfeSeverity.context,
  problemMessage: r"""This is the super-initializer parameter.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
codeSuperParameterInitializerOutsideConstructor = const MessageCode(
  "SuperParameterInitializerOutsideConstructor",
  problemMessage:
      r"""Super-initializer formal parameters can only be used in generative constructors.""",
  correctionMessage: r"""Try removing 'super.'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeSuperclassHasNoConstructor = const Template(
  "SuperclassHasNoConstructor",
  problemMessageTemplate: r"""Superclass has no constructor named '#name'.""",
  withArgumentsOld: _withArgumentsOldSuperclassHasNoConstructor,
  withArguments: _withArgumentsSuperclassHasNoConstructor,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperclassHasNoConstructor({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeSuperclassHasNoConstructor,
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
codeSuperclassHasNoDefaultConstructor = const Template(
  "SuperclassHasNoDefaultConstructor",
  problemMessageTemplate:
      r"""The superclass, '#name', has no unnamed constructor that takes no arguments.""",
  withArgumentsOld: _withArgumentsOldSuperclassHasNoDefaultConstructor,
  withArguments: _withArgumentsSuperclassHasNoDefaultConstructor,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperclassHasNoDefaultConstructor({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeSuperclassHasNoDefaultConstructor,
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
codeSuperclassHasNoGetter = const Template(
  "SuperclassHasNoGetter",
  problemMessageTemplate: r"""Superclass has no getter named '#name'.""",
  withArgumentsOld: _withArgumentsOldSuperclassHasNoGetter,
  withArguments: _withArgumentsSuperclassHasNoGetter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperclassHasNoGetter({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeSuperclassHasNoGetter,
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
codeSuperclassHasNoMember = const Template(
  "SuperclassHasNoMember",
  problemMessageTemplate: r"""Superclass has no member named '#name'.""",
  withArgumentsOld: _withArgumentsOldSuperclassHasNoMember,
  withArguments: _withArgumentsSuperclassHasNoMember,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperclassHasNoMember({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeSuperclassHasNoMember,
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
codeSuperclassHasNoMethod = const Template(
  "SuperclassHasNoMethod",
  problemMessageTemplate: r"""Superclass has no method named '#name'.""",
  withArgumentsOld: _withArgumentsOldSuperclassHasNoMethod,
  withArguments: _withArgumentsSuperclassHasNoMethod,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperclassHasNoMethod({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeSuperclassHasNoMethod,
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
codeSuperclassHasNoSetter = const Template(
  "SuperclassHasNoSetter",
  problemMessageTemplate: r"""Superclass has no setter named '#name'.""",
  withArgumentsOld: _withArgumentsOldSuperclassHasNoSetter,
  withArguments: _withArgumentsSuperclassHasNoSetter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperclassHasNoSetter({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeSuperclassHasNoSetter,
    problemMessage: """Superclass has no setter named '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldSuperclassHasNoSetter(String name) =>
    _withArgumentsSuperclassHasNoSetter(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeSupertypeIsFunction = const MessageCode(
  "SupertypeIsFunction",
  problemMessage: r"""Can't use a function type as supertype.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeSupertypeIsIllegal = const Template(
  "SupertypeIsIllegal",
  problemMessageTemplate: r"""The type '#name' can't be used as supertype.""",
  withArgumentsOld: _withArgumentsOldSupertypeIsIllegal,
  withArguments: _withArgumentsSupertypeIsIllegal,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSupertypeIsIllegal({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeSupertypeIsIllegal,
    problemMessage: """The type '${name_0}' can't be used as supertype.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldSupertypeIsIllegal(String name) =>
    _withArgumentsSupertypeIsIllegal(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, DartType type),
  Message Function({required String name, required DartType type})
>
codeSupertypeIsIllegalAliased = const Template(
  "SupertypeIsIllegalAliased",
  problemMessageTemplate:
      r"""The type '#name' which is an alias of '#type' can't be used as supertype.""",
  withArgumentsOld: _withArgumentsOldSupertypeIsIllegalAliased,
  withArguments: _withArgumentsSupertypeIsIllegalAliased,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSupertypeIsIllegalAliased({
  required String name,
  required DartType type,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    codeSupertypeIsIllegalAliased,
    problemMessage:
        """The type '${name_0}' which is an alias of '${type_0}' can't be used as supertype.""" +
        labeler.originMessages,
    arguments: {'name': name, 'type': type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldSupertypeIsIllegalAliased(
  String name,
  DartType type,
) => _withArgumentsSupertypeIsIllegalAliased(name: name, type: type);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, DartType type),
  Message Function({required String name, required DartType type})
>
codeSupertypeIsNullableAliased = const Template(
  "SupertypeIsNullableAliased",
  problemMessageTemplate:
      r"""The type '#name' which is an alias of '#type' can't be used as supertype because it is nullable.""",
  withArgumentsOld: _withArgumentsOldSupertypeIsNullableAliased,
  withArguments: _withArgumentsSupertypeIsNullableAliased,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSupertypeIsNullableAliased({
  required String name,
  required DartType type,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    codeSupertypeIsNullableAliased,
    problemMessage:
        """The type '${name_0}' which is an alias of '${type_0}' can't be used as supertype because it is nullable.""" +
        labeler.originMessages,
    arguments: {'name': name, 'type': type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldSupertypeIsNullableAliased(
  String name,
  DartType type,
) => _withArgumentsSupertypeIsNullableAliased(name: name, type: type);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeSupertypeIsTypeParameter = const Template(
  "SupertypeIsTypeParameter",
  problemMessageTemplate:
      r"""The type variable '#name' can't be used as supertype.""",
  withArgumentsOld: _withArgumentsOldSupertypeIsTypeParameter,
  withArguments: _withArgumentsSupertypeIsTypeParameter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSupertypeIsTypeParameter({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeSupertypeIsTypeParameter,
    problemMessage:
        """The type variable '${name_0}' can't be used as supertype.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldSupertypeIsTypeParameter(String name) =>
    _withArgumentsSupertypeIsTypeParameter(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeSwitchCaseFallThrough = const MessageCode(
  "SwitchCaseFallThrough",
  problemMessage: r"""Switch case may fall through to the next case.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeSwitchExpressionNotAssignableCause = const MessageCode(
  "SwitchExpressionNotAssignableCause",
  severity: CfeSeverity.context,
  problemMessage: r"""The switch expression is here.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType type, DartType type2),
  Message Function({required DartType type, required DartType type2})
>
codeSwitchExpressionNotSubtype = const Template(
  "SwitchExpressionNotSubtype",
  problemMessageTemplate:
      r"""Type '#type' of the case expression is not a subtype of type '#type2' of this switch expression.""",
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
    codeSwitchExpressionNotSubtype,
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
const MessageCode codeSyntheticToken = const MessageCode(
  "SyntheticToken",
  problemMessage: r"""This couldn't be parsed.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeThisAccessInFieldInitializer = const Template(
  "ThisAccessInFieldInitializer",
  problemMessageTemplate:
      r"""Can't access 'this' in a field initializer to read '#name'.""",
  withArgumentsOld: _withArgumentsOldThisAccessInFieldInitializer,
  withArguments: _withArgumentsThisAccessInFieldInitializer,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsThisAccessInFieldInitializer({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeThisAccessInFieldInitializer,
    problemMessage:
        """Can't access 'this' in a field initializer to read '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldThisAccessInFieldInitializer(String name) =>
    _withArgumentsThisAccessInFieldInitializer(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeThisAsIdentifier = const MessageCode(
  "ThisAsIdentifier",
  problemMessage: r"""Expected identifier, but got 'this'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string),
  Message Function({required String string})
>
codeThisNotPromoted = const Template(
  "ThisNotPromoted",
  problemMessageTemplate: r"""'this' can't be promoted.""",
  correctionMessageTemplate: r"""See #string""",
  withArgumentsOld: _withArgumentsOldThisNotPromoted,
  withArguments: _withArgumentsThisNotPromoted,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsThisNotPromoted({required String string}) {
  var string_0 = conversions.validateString(string);
  return new Message(
    codeThisNotPromoted,
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
codeThisOrSuperAccessInFieldInitializer = const Template(
  "ThisOrSuperAccessInFieldInitializer",
  problemMessageTemplate: r"""Can't access '#string' in a field initializer.""",
  withArgumentsOld: _withArgumentsOldThisOrSuperAccessInFieldInitializer,
  withArguments: _withArgumentsThisOrSuperAccessInFieldInitializer,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsThisOrSuperAccessInFieldInitializer({
  required String string,
}) {
  var string_0 = conversions.validateString(string);
  return new Message(
    codeThisOrSuperAccessInFieldInitializer,
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
codeThrowingNotAssignableToObjectError = const Template(
  "ThrowingNotAssignableToObjectError",
  problemMessageTemplate:
      r"""Can't throw a value of '#type' since it is neither dynamic nor non-nullable.""",
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
    codeThrowingNotAssignableToObjectError,
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
  Message Function(int count, int count2),
  Message Function({required int count, required int count2})
>
codeTooFewArguments = const Template(
  "TooFewArguments",
  problemMessageTemplate:
      r"""Too few positional arguments: #count required, #count2 given.""",
  withArgumentsOld: _withArgumentsOldTooFewArguments,
  withArguments: _withArgumentsTooFewArguments,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsTooFewArguments({
  required int count,
  required int count2,
}) {
  return new Message(
    codeTooFewArguments,
    problemMessage:
        """Too few positional arguments: ${count} required, ${count2} given.""",
    arguments: {'count': count, 'count2': count2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldTooFewArguments(int count, int count2) =>
    _withArgumentsTooFewArguments(count: count, count2: count2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(int count, int count2),
  Message Function({required int count, required int count2})
>
codeTooManyArguments = const Template(
  "TooManyArguments",
  problemMessageTemplate:
      r"""Too many positional arguments: #count allowed, but #count2 found.""",
  correctionMessageTemplate:
      r"""Try removing the extra positional arguments.""",
  withArgumentsOld: _withArgumentsOldTooManyArguments,
  withArguments: _withArgumentsTooManyArguments,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsTooManyArguments({
  required int count,
  required int count2,
}) {
  return new Message(
    codeTooManyArguments,
    problemMessage:
        """Too many positional arguments: ${count} allowed, but ${count2} found.""",
    correctionMessage: """Try removing the extra positional arguments.""",
    arguments: {'count': count, 'count2': count2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldTooManyArguments(int count, int count2) =>
    _withArgumentsTooManyArguments(count: count, count2: count2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(int count),
  Message Function({required int count})
>
codeTypeArgumentMismatch = const Template(
  "TypeArgumentMismatch",
  problemMessageTemplate: r"""Expected #count type arguments.""",
  withArgumentsOld: _withArgumentsOldTypeArgumentMismatch,
  withArguments: _withArgumentsTypeArgumentMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsTypeArgumentMismatch({required int count}) {
  return new Message(
    codeTypeArgumentMismatch,
    problemMessage: """Expected ${count} type arguments.""",
    arguments: {'count': count},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldTypeArgumentMismatch(int count) =>
    _withArgumentsTypeArgumentMismatch(count: count);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeTypeNotFound = const Template(
  "TypeNotFound",
  problemMessageTemplate: r"""Type '#name' not found.""",
  withArgumentsOld: _withArgumentsOldTypeNotFound,
  withArguments: _withArgumentsTypeNotFound,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsTypeNotFound({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeTypeNotFound,
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
codeTypeOrigin = const Template(
  "TypeOrigin",
  problemMessageTemplate: r"""'#name' is from '#uri'.""",
  withArgumentsOld: _withArgumentsOldTypeOrigin,
  withArguments: _withArgumentsTypeOrigin,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsTypeOrigin({required String name, required Uri uri}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var uri_0 = conversions.relativizeUri(uri);
  return new Message(
    codeTypeOrigin,
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
codeTypeOriginWithFileUri = const Template(
  "TypeOriginWithFileUri",
  problemMessageTemplate: r"""'#name' is from '#uri' ('#uri2').""",
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
    codeTypeOriginWithFileUri,
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
const MessageCode codeTypeParameterDuplicatedName = const MessageCode(
  "TypeParameterDuplicatedName",
  problemMessage: r"""A type variable can't have the same name as another.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeTypeParameterDuplicatedNameCause = const Template(
  "TypeParameterDuplicatedNameCause",
  problemMessageTemplate: r"""The other type variable named '#name'.""",
  withArgumentsOld: _withArgumentsOldTypeParameterDuplicatedNameCause,
  withArguments: _withArgumentsTypeParameterDuplicatedNameCause,
  severity: CfeSeverity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsTypeParameterDuplicatedNameCause({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeTypeParameterDuplicatedNameCause,
    problemMessage: """The other type variable named '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldTypeParameterDuplicatedNameCause(String name) =>
    _withArgumentsTypeParameterDuplicatedNameCause(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeTypeParameterSameNameAsEnclosing = const MessageCode(
  "TypeParameterSameNameAsEnclosing",
  problemMessage:
      r"""A type variable can't have the same name as its enclosing declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeTypeVariableInConstantContext = const MessageCode(
  "TypeVariableInConstantContext",
  problemMessage: r"""Type variables can't be used as constants.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeTypeVariableInStaticContext = const MessageCode(
  "TypeVariableInStaticContext",
  problemMessage: r"""Type variables can't be used in static members.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeTypedefCause = const MessageCode(
  "TypedefCause",
  severity: CfeSeverity.context,
  problemMessage: r"""The issue arises via this type alias.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeTypedefNotFunction = const MessageCode(
  "TypedefNotFunction",
  problemMessage: r"""Can't create typedef from non-function type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeTypedefNotType = const MessageCode(
  "TypedefNotType",
  problemMessage: r"""Can't create typedef from non-type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeTypedefNullableType = const MessageCode(
  "TypedefNullableType",
  problemMessage: r"""Can't create typedef from nullable type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeTypedefTypeParameterNotConstructor = const MessageCode(
  "TypedefTypeParameterNotConstructor",
  problemMessage:
      r"""Can't use a typedef denoting a type variable as a constructor, nor for a static member access.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeTypedefTypeParameterNotConstructorCause =
    const MessageCode(
      "TypedefTypeParameterNotConstructorCause",
      severity: CfeSeverity.context,
      problemMessage: r"""This is the type variable ultimately denoted.""",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeTypedefUnaliasedTypeCause = const MessageCode(
  "TypedefUnaliasedTypeCause",
  severity: CfeSeverity.context,
  problemMessage: r"""This is the type denoted by the type alias.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri), Message Function({required Uri uri})>
codeUnavailableDartLibrary = const Template(
  "UnavailableDartLibrary",
  problemMessageTemplate:
      r"""Dart library '#uri' is not available on this platform.""",
  withArgumentsOld: _withArgumentsOldUnavailableDartLibrary,
  withArguments: _withArgumentsUnavailableDartLibrary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnavailableDartLibrary({required Uri uri}) {
  var uri_0 = conversions.relativizeUri(uri);
  return new Message(
    codeUnavailableDartLibrary,
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
codeUndefinedGetter = const Template(
  "UndefinedGetter",
  problemMessageTemplate:
      r"""The getter '#name' isn't defined for the type '#type'.""",
  correctionMessageTemplate:
      r"""Try correcting the name to the name of an existing getter, or defining a getter or field named '#name'.""",
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
    codeUndefinedGetter,
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
codeUndefinedMethod = const Template(
  "UndefinedMethod",
  problemMessageTemplate:
      r"""The method '#name' isn't defined for the type '#type'.""",
  correctionMessageTemplate:
      r"""Try correcting the name to the name of an existing method, or defining a method named '#name'.""",
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
    codeUndefinedMethod,
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
codeUndefinedOperator = const Template(
  "UndefinedOperator",
  problemMessageTemplate:
      r"""The operator '#name' isn't defined for the type '#type'.""",
  correctionMessageTemplate:
      r"""Try correcting the operator to an existing operator, or defining a '#name' operator.""",
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
    codeUndefinedOperator,
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
codeUndefinedSetter = const Template(
  "UndefinedSetter",
  problemMessageTemplate:
      r"""The setter '#name' isn't defined for the type '#type'.""",
  correctionMessageTemplate:
      r"""Try correcting the name to the name of an existing setter, or defining a setter or field named '#name'.""",
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
    codeUndefinedSetter,
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
codeUnexpectedSuperParametersInGenerativeConstructors = const MessageCode(
  "UnexpectedSuperParametersInGenerativeConstructors",
  problemMessage:
      r"""Super parameters can only be used in non-redirecting generative constructors.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeUnmatchedAugmentationClass = const Template(
  "UnmatchedAugmentationClass",
  problemMessageTemplate:
      r"""Augmentation class '#name' doesn't match a class in the augmented library.""",
  correctionMessageTemplate:
      r"""Try changing the name to an existing class or removing the 'augment' modifier.""",
  withArgumentsOld: _withArgumentsOldUnmatchedAugmentationClass,
  withArguments: _withArgumentsUnmatchedAugmentationClass,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnmatchedAugmentationClass({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeUnmatchedAugmentationClass,
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
codeUnmatchedAugmentationClassMember = const Template(
  "UnmatchedAugmentationClassMember",
  problemMessageTemplate:
      r"""Augmentation member '#name' doesn't match a member in the augmented class.""",
  correctionMessageTemplate:
      r"""Try changing the name to an existing member or removing the 'augment' modifier.""",
  withArgumentsOld: _withArgumentsOldUnmatchedAugmentationClassMember,
  withArguments: _withArgumentsUnmatchedAugmentationClassMember,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnmatchedAugmentationClassMember({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeUnmatchedAugmentationClassMember,
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
codeUnmatchedAugmentationConstructor = const Template(
  "UnmatchedAugmentationConstructor",
  problemMessageTemplate:
      r"""Augmentation constructor '#name' doesn't match a constructor in the augmented class.""",
  correctionMessageTemplate:
      r"""Try changing the name to an existing constructor or removing the 'augment' modifier.""",
  withArgumentsOld: _withArgumentsOldUnmatchedAugmentationConstructor,
  withArguments: _withArgumentsUnmatchedAugmentationConstructor,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnmatchedAugmentationConstructor({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeUnmatchedAugmentationConstructor,
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
codeUnmatchedAugmentationDeclaration = const Template(
  "UnmatchedAugmentationDeclaration",
  problemMessageTemplate:
      r"""Augmentation '#name' doesn't match a declaration in the augmented library.""",
  correctionMessageTemplate:
      r"""Try changing the name to an existing declaration or removing the 'augment' modifier.""",
  withArgumentsOld: _withArgumentsOldUnmatchedAugmentationDeclaration,
  withArguments: _withArgumentsUnmatchedAugmentationDeclaration,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnmatchedAugmentationDeclaration({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeUnmatchedAugmentationDeclaration,
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
codeUnmatchedAugmentationLibraryMember = const Template(
  "UnmatchedAugmentationLibraryMember",
  problemMessageTemplate:
      r"""Augmentation member '#name' doesn't match a member in the augmented library.""",
  correctionMessageTemplate:
      r"""Try changing the name to an existing member or removing the 'augment' modifier.""",
  withArgumentsOld: _withArgumentsOldUnmatchedAugmentationLibraryMember,
  withArguments: _withArgumentsUnmatchedAugmentationLibraryMember,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnmatchedAugmentationLibraryMember({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeUnmatchedAugmentationLibraryMember,
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
codeUnmatchedPatchClass = const Template(
  "UnmatchedPatchClass",
  problemMessageTemplate:
      r"""Patch class '#name' doesn't match a class in the origin library.""",
  correctionMessageTemplate:
      r"""Try changing the name to an existing class or removing the '@patch' annotation.""",
  withArgumentsOld: _withArgumentsOldUnmatchedPatchClass,
  withArguments: _withArgumentsUnmatchedPatchClass,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnmatchedPatchClass({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeUnmatchedPatchClass,
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
codeUnmatchedPatchClassMember = const Template(
  "UnmatchedPatchClassMember",
  problemMessageTemplate:
      r"""Patch member '#name' doesn't match a member in the origin class.""",
  correctionMessageTemplate:
      r"""Try changing the name to an existing member or removing the '@patch' annotation.""",
  withArgumentsOld: _withArgumentsOldUnmatchedPatchClassMember,
  withArguments: _withArgumentsUnmatchedPatchClassMember,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnmatchedPatchClassMember({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeUnmatchedPatchClassMember,
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
codeUnmatchedPatchDeclaration = const Template(
  "UnmatchedPatchDeclaration",
  problemMessageTemplate:
      r"""Patch '#name' doesn't match a declaration in the origin library.""",
  correctionMessageTemplate:
      r"""Try changing the name to an existing declaration or removing the '@patch' annotation.""",
  withArgumentsOld: _withArgumentsOldUnmatchedPatchDeclaration,
  withArguments: _withArgumentsUnmatchedPatchDeclaration,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnmatchedPatchDeclaration({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeUnmatchedPatchDeclaration,
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
codeUnmatchedPatchLibraryMember = const Template(
  "UnmatchedPatchLibraryMember",
  problemMessageTemplate:
      r"""Patch member '#name' doesn't match a member in the origin library.""",
  correctionMessageTemplate:
      r"""Try changing the name to an existing member or removing the '@patch' annotation.""",
  withArgumentsOld: _withArgumentsOldUnmatchedPatchLibraryMember,
  withArguments: _withArgumentsUnmatchedPatchLibraryMember,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnmatchedPatchLibraryMember({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeUnmatchedPatchLibraryMember,
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
const MessageCode codeUnnamedObjectPatternField = const MessageCode(
  "UnnamedObjectPatternField",
  problemMessage: r"""A pattern field in an object pattern must be named.""",
  correctionMessage:
      r"""Try adding a pattern name or ':' before the pattern.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeUnsoundSwitchExpressionError = const MessageCode(
  "UnsoundSwitchExpressionError",
  problemMessage:
      r"""None of the patterns in the switch expression the matched input value. See https://github.com/dart-lang/language/issues/3488 for details.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeUnsoundSwitchStatementError = const MessageCode(
  "UnsoundSwitchStatementError",
  problemMessage:
      r"""None of the patterns in the exhaustive switch statement the matched input value. See https://github.com/dart-lang/language/issues/3488 for details.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeUnspecifiedGetterNameInObjectPattern = const MessageCode(
  "UnspecifiedGetterNameInObjectPattern",
  problemMessage:
      r"""The getter name is not specified explicitly, and the pattern is not a variable. Try specifying the getter name explicitly, or using a variable pattern.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeUnsupportedDartExt = const MessageCode(
  "UnsupportedDartExt",
  problemMessage: r"""Dart native extensions are no longer supported.""",
  correctionMessage:
      r"""Migrate to using FFI instead (https://dart.dev/guides/libraries/c-interop)""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeUnterminatedToken = const MessageCode(
  "UnterminatedToken",
  problemMessage: r"""Incomplete token.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri), Message Function({required Uri uri})>
codeUntranslatableUri = const Template(
  "UntranslatableUri",
  problemMessageTemplate: r"""Not found: '#uri'""",
  withArgumentsOld: _withArgumentsOldUntranslatableUri,
  withArguments: _withArgumentsUntranslatableUri,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUntranslatableUri({required Uri uri}) {
  var uri_0 = conversions.relativizeUri(uri);
  return new Message(
    codeUntranslatableUri,
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
codeValueForRequiredParameterNotProvidedError = const Template(
  "ValueForRequiredParameterNotProvidedError",
  problemMessageTemplate:
      r"""Required named parameter '#name' must be provided.""",
  withArgumentsOld: _withArgumentsOldValueForRequiredParameterNotProvidedError,
  withArguments: _withArgumentsValueForRequiredParameterNotProvidedError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsValueForRequiredParameterNotProvidedError({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeValueForRequiredParameterNotProvidedError,
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
codeVariableCouldBeNullDueToWrite = const Template(
  "VariableCouldBeNullDueToWrite",
  problemMessageTemplate:
      r"""Variable '#name' could not be promoted due to an assignment.""",
  correctionMessageTemplate:
      r"""Try null checking the variable after the assignment.  See #string""",
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
    codeVariableCouldBeNullDueToWrite,
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
const MessageCode codeVerificationErrorOriginContext = const MessageCode(
  "VerificationErrorOriginContext",
  severity: CfeSeverity.context,
  problemMessage:
      r"""The node most likely is taken from here by a transformer.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeVoidExpression = const MessageCode(
  "VoidExpression",
  problemMessage: r"""This expression has type 'void' and can't be used.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeWasmImportOrExportInUserCode = const MessageCode(
  "WasmImportOrExportInUserCode",
  problemMessage:
      r"""Pragmas `wasm:import` and `wasm:export` are for internal use only and cannot be used by user code.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeWeakReferenceMismatchReturnAndArgumentTypes =
    const MessageCode(
      "WeakReferenceMismatchReturnAndArgumentTypes",
      problemMessage:
          r"""Return and argument types of a weak reference should match.""",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeWeakReferenceNotOneArgument = const MessageCode(
  "WeakReferenceNotOneArgument",
  problemMessage:
      r"""Weak reference should take one required positional argument.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeWeakReferenceNotStatic = const MessageCode(
  "WeakReferenceNotStatic",
  problemMessage:
      r"""Weak reference pragma can be used on a static method only.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeWeakReferenceReturnTypeNotNullable = const MessageCode(
  "WeakReferenceReturnTypeNotNullable",
  problemMessage: r"""Return type of a weak reference should be nullable.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeWeakReferenceTargetHasParameters = const MessageCode(
  "WeakReferenceTargetHasParameters",
  problemMessage:
      r"""The target of weak reference should not take parameters.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeWeakReferenceTargetNotStaticTearoff = const MessageCode(
  "WeakReferenceTargetNotStaticTearoff",
  problemMessage:
      r"""The target of weak reference should be a tearoff of a static method.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string, String string2),
  Message Function({required String string, required String string2})
>
codeWebLiteralCannotBeRepresentedExactly = const Template(
  "WebLiteralCannotBeRepresentedExactly",
  problemMessageTemplate:
      r"""The integer literal #string can't be represented exactly in JavaScript.""",
  correctionMessageTemplate:
      r"""Try changing the literal to something that can be represented in JavaScript. In JavaScript #string2 is the nearest value that can be represented exactly.""",
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
    codeWebLiteralCannotBeRepresentedExactly,
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
codeWrongTypeParameterVarianceInSuperinterface = const Template(
  "WrongTypeParameterVarianceInSuperinterface",
  problemMessageTemplate:
      r"""'#name' can't be used contravariantly or invariantly in '#type'.""",
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
    codeWrongTypeParameterVarianceInSuperinterface,
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
