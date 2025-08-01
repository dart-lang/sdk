// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// NOTE: THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/front_end/messages.yaml' and defer to it for the
// commands to update this file.

// ignore_for_file: lines_longer_than_80_chars

part of _fe_analyzer_shared.messages.codes;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeAbstractClassConstructorTearOff =
    messageAbstractClassConstructorTearOff;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAbstractClassConstructorTearOff = const MessageCode(
  "AbstractClassConstructorTearOff",
  problemMessage: r"""Constructors on abstract classes can't be torn off.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateAbstractClassInstantiation =
    const Template<Message Function(String name)>(
  "AbstractClassInstantiation",
  problemMessageTemplate:
      r"""The class '#name' is abstract and can't be instantiated.""",
  withArguments: _withArgumentsAbstractClassInstantiation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeAbstractClassInstantiation = const Code(
  "AbstractClassInstantiation",
  analyzerCodes: <String>["NEW_WITH_ABSTRACT_CLASS"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsAbstractClassInstantiation(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeAbstractClassInstantiation,
    problemMessage:
        """The class '${name}' is abstract and can't be instantiated.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeAbstractClassMember = messageAbstractClassMember;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAbstractClassMember = const MessageCode(
  "AbstractClassMember",
  index: 51,
  problemMessage: r"""Members of classes can't be declared to be 'abstract'.""",
  correctionMessage:
      r"""Try removing the 'abstract' keyword. You can add the 'abstract' keyword before the class declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeAbstractExtensionField = messageAbstractExtensionField;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAbstractExtensionField = const MessageCode(
  "AbstractExtensionField",
  analyzerCodes: <String>["ABSTRACT_EXTENSION_FIELD"],
  problemMessage: r"""Extension fields can't be declared 'abstract'.""",
  correctionMessage: r"""Try removing the 'abstract' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeAbstractExternalField = messageAbstractExternalField;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAbstractExternalField = const MessageCode(
  "AbstractExternalField",
  index: 110,
  problemMessage:
      r"""Fields can't be declared both 'abstract' and 'external'.""",
  correctionMessage: r"""Try removing the 'abstract' or 'external' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeAbstractFieldConstructorInitializer =
    messageAbstractFieldConstructorInitializer;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAbstractFieldConstructorInitializer =
    const MessageCode(
  "AbstractFieldConstructorInitializer",
  problemMessage: r"""Abstract fields cannot have initializers.""",
  correctionMessage:
      r"""Try removing the field initializer or the 'abstract' keyword from the field declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeAbstractFieldInitializer = messageAbstractFieldInitializer;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAbstractFieldInitializer = const MessageCode(
  "AbstractFieldInitializer",
  problemMessage: r"""Abstract fields cannot have initializers.""",
  correctionMessage:
      r"""Try removing the initializer or the 'abstract' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeAbstractFinalBaseClass = messageAbstractFinalBaseClass;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAbstractFinalBaseClass = const MessageCode(
  "AbstractFinalBaseClass",
  index: 176,
  problemMessage:
      r"""An 'abstract' class can't be declared as both 'final' and 'base'.""",
  correctionMessage: r"""Try removing either the 'final' or 'base' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeAbstractFinalInterfaceClass = messageAbstractFinalInterfaceClass;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAbstractFinalInterfaceClass = const MessageCode(
  "AbstractFinalInterfaceClass",
  index: 177,
  problemMessage:
      r"""An 'abstract' class can't be declared as both 'final' and 'interface'.""",
  correctionMessage:
      r"""Try removing either the 'final' or 'interface' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeAbstractLateField = messageAbstractLateField;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAbstractLateField = const MessageCode(
  "AbstractLateField",
  index: 108,
  problemMessage: r"""Abstract fields cannot be late.""",
  correctionMessage: r"""Try removing the 'abstract' or 'late' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeAbstractNotSync = messageAbstractNotSync;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAbstractNotSync = const MessageCode(
  "AbstractNotSync",
  analyzerCodes: <String>["NON_SYNC_ABSTRACT_METHOD"],
  problemMessage:
      r"""Abstract methods can't use 'async', 'async*', or 'sync*'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateAbstractRedirectedClassInstantiation =
    const Template<Message Function(String name)>(
  "AbstractRedirectedClassInstantiation",
  problemMessageTemplate:
      r"""Factory redirects to class '#name', which is abstract and can't be instantiated.""",
  withArguments: _withArgumentsAbstractRedirectedClassInstantiation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeAbstractRedirectedClassInstantiation = const Code(
  "AbstractRedirectedClassInstantiation",
  analyzerCodes: <String>["FACTORY_REDIRECTS_TO_ABSTRACT_CLASS"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsAbstractRedirectedClassInstantiation(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeAbstractRedirectedClassInstantiation,
    problemMessage:
        """Factory redirects to class '${name}', which is abstract and can't be instantiated.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeAbstractSealedClass = messageAbstractSealedClass;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAbstractSealedClass = const MessageCode(
  "AbstractSealedClass",
  index: 132,
  problemMessage:
      r"""A 'sealed' class can't be marked 'abstract' because it's already implicitly abstract.""",
  correctionMessage: r"""Try removing the 'abstract' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeAbstractStaticField = messageAbstractStaticField;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAbstractStaticField = const MessageCode(
  "AbstractStaticField",
  index: 107,
  problemMessage: r"""Static fields can't be declared 'abstract'.""",
  correctionMessage: r"""Try removing the 'abstract' or 'static' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateAccessError =
    const Template<Message Function(String name)>(
  "AccessError",
  problemMessageTemplate: r"""Access error: '#name'.""",
  withArguments: _withArgumentsAccessError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeAccessError = const Code(
  "AccessError",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsAccessError(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeAccessError,
    problemMessage: """Access error: '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeAmbiguousExtensionCause = messageAmbiguousExtensionCause;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAmbiguousExtensionCause = const MessageCode(
  "AmbiguousExtensionCause",
  severity: Severity.context,
  problemMessage: r"""This is one of the extension members.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeAnnotationOnFunctionTypeTypeParameter =
    messageAnnotationOnFunctionTypeTypeParameter;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAnnotationOnFunctionTypeTypeParameter =
    const MessageCode(
  "AnnotationOnFunctionTypeTypeParameter",
  problemMessage:
      r"""A type variable on a function type can't have annotations.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeAnnotationOnTypeArgument = messageAnnotationOnTypeArgument;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAnnotationOnTypeArgument = const MessageCode(
  "AnnotationOnTypeArgument",
  index: 111,
  problemMessage:
      r"""Type arguments can't have annotations because they aren't declarations.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeAnonymousBreakTargetOutsideFunction =
    messageAnonymousBreakTargetOutsideFunction;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAnonymousBreakTargetOutsideFunction =
    const MessageCode(
  "AnonymousBreakTargetOutsideFunction",
  analyzerCodes: <String>["LABEL_IN_OUTER_SCOPE"],
  problemMessage: r"""Can't break to a target in a different function.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeAnonymousContinueTargetOutsideFunction =
    messageAnonymousContinueTargetOutsideFunction;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAnonymousContinueTargetOutsideFunction =
    const MessageCode(
  "AnonymousContinueTargetOutsideFunction",
  analyzerCodes: <String>["LABEL_IN_OUTER_SCOPE"],
  problemMessage: r"""Can't continue at a target in a different function.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(int codePoint)> templateAsciiControlCharacter =
    const Template<Message Function(int codePoint)>(
  "AsciiControlCharacter",
  problemMessageTemplate:
      r"""The control character #unicode can only be used in strings and comments.""",
  withArguments: _withArgumentsAsciiControlCharacter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeAsciiControlCharacter = const Code(
  "AsciiControlCharacter",
  analyzerCodes: <String>["ILLEGAL_CHARACTER"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsAsciiControlCharacter(int codePoint) {
  String unicode =
      "U+${codePoint.toRadixString(16).toUpperCase().padLeft(4, '0')}";
  return new Message(
    codeAsciiControlCharacter,
    problemMessage:
        """The control character ${unicode} can only be used in strings and comments.""",
    arguments: {
      'unicode': codePoint,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeAssertAsExpression = messageAssertAsExpression;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAssertAsExpression = const MessageCode(
  "AssertAsExpression",
  problemMessage: r"""`assert` can't be used as an expression.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeAssertExtraneousArgument = messageAssertExtraneousArgument;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAssertExtraneousArgument = const MessageCode(
  "AssertExtraneousArgument",
  problemMessage: r"""`assert` can't have more than two arguments.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeAwaitAsIdentifier = messageAwaitAsIdentifier;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAwaitAsIdentifier = const MessageCode(
  "AwaitAsIdentifier",
  analyzerCodes: <String>["ASYNC_KEYWORD_USED_AS_IDENTIFIER"],
  problemMessage:
      r"""'await' can't be used as an identifier in 'async', 'async*', or 'sync*' methods.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeAwaitForNotAsync = messageAwaitForNotAsync;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAwaitForNotAsync = const MessageCode(
  "AwaitForNotAsync",
  analyzerCodes: <String>["ASYNC_FOR_IN_WRONG_CONTEXT"],
  problemMessage:
      r"""The asynchronous for-in can only be used in functions marked with 'async' or 'async*'.""",
  correctionMessage:
      r"""Try marking the function body with either 'async' or 'async*', or removing the 'await' before the for loop.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeAwaitInLateLocalInitializer = messageAwaitInLateLocalInitializer;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAwaitInLateLocalInitializer = const MessageCode(
  "AwaitInLateLocalInitializer",
  problemMessage:
      r"""`await` expressions are not supported in late local initializers.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeAwaitNotAsync = messageAwaitNotAsync;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAwaitNotAsync = const MessageCode(
  "AwaitNotAsync",
  analyzerCodes: <String>["AWAIT_IN_WRONG_CONTEXT"],
  problemMessage:
      r"""'await' can only be used in 'async' or 'async*' methods.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeAwaitOfExtensionTypeNotFuture =
    messageAwaitOfExtensionTypeNotFuture;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAwaitOfExtensionTypeNotFuture = const MessageCode(
  "AwaitOfExtensionTypeNotFuture",
  analyzerCodes: <String>["AWAIT_OF_EXTENSION_TYPE_NOT_FUTURE"],
  problemMessage:
      r"""The 'await' expression can't be used for an expression with an extension type that is not a subtype of 'Future'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateBaseClassImplementedOutsideOfLibrary =
    const Template<Message Function(String name)>(
  "BaseClassImplementedOutsideOfLibrary",
  problemMessageTemplate:
      r"""The class '#name' can't be implemented outside of its library because it's a base class.""",
  withArguments: _withArgumentsBaseClassImplementedOutsideOfLibrary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeBaseClassImplementedOutsideOfLibrary = const Code(
  "BaseClassImplementedOutsideOfLibrary",
  analyzerCodes: <String>["BASE_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsBaseClassImplementedOutsideOfLibrary(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeBaseClassImplementedOutsideOfLibrary,
    problemMessage:
        """The class '${name}' can't be implemented outside of its library because it's a base class.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeBaseEnum = messageBaseEnum;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageBaseEnum = const MessageCode(
  "BaseEnum",
  index: 155,
  problemMessage: r"""Enums can't be declared to be 'base'.""",
  correctionMessage: r"""Try removing the keyword 'base'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateBaseMixinImplementedOutsideOfLibrary =
    const Template<Message Function(String name)>(
  "BaseMixinImplementedOutsideOfLibrary",
  problemMessageTemplate:
      r"""The mixin '#name' can't be implemented outside of its library because it's a base mixin.""",
  withArguments: _withArgumentsBaseMixinImplementedOutsideOfLibrary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeBaseMixinImplementedOutsideOfLibrary = const Code(
  "BaseMixinImplementedOutsideOfLibrary",
  analyzerCodes: <String>["BASE_MIXIN_IMPLEMENTED_OUTSIDE_OF_LIBRARY"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsBaseMixinImplementedOutsideOfLibrary(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeBaseMixinImplementedOutsideOfLibrary,
    problemMessage:
        """The mixin '${name}' can't be implemented outside of its library because it's a base mixin.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String name2)>
    templateBaseOrFinalClassImplementedOutsideOfLibraryCause =
    const Template<Message Function(String name, String name2)>(
  "BaseOrFinalClassImplementedOutsideOfLibraryCause",
  problemMessageTemplate:
      r"""The type '#name' is a subtype of '#name2', and '#name2' is defined here.""",
  withArguments: _withArgumentsBaseOrFinalClassImplementedOutsideOfLibraryCause,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeBaseOrFinalClassImplementedOutsideOfLibraryCause = const Code(
  "BaseOrFinalClassImplementedOutsideOfLibraryCause",
  severity: Severity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsBaseOrFinalClassImplementedOutsideOfLibraryCause(
    String name, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(
    codeBaseOrFinalClassImplementedOutsideOfLibraryCause,
    problemMessage:
        """The type '${name}' is a subtype of '${name2}', and '${name2}' is defined here.""",
    arguments: {
      'name': name,
      'name2': name2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string, String string2)>
    templateBinaryOperatorWrittenOut =
    const Template<Message Function(String string, String string2)>(
  "BinaryOperatorWrittenOut",
  problemMessageTemplate:
      r"""Binary operator '#string' is written as '#string2' instead of the written out word.""",
  correctionMessageTemplate: r"""Try replacing '#string' with '#string2'.""",
  withArguments: _withArgumentsBinaryOperatorWrittenOut,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeBinaryOperatorWrittenOut = const Code(
  "BinaryOperatorWrittenOut",
  index: 112,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsBinaryOperatorWrittenOut(String string, String string2) {
  if (string.isEmpty) throw 'No string provided';
  if (string2.isEmpty) throw 'No string provided';
  return new Message(
    codeBinaryOperatorWrittenOut,
    problemMessage:
        """Binary operator '${string}' is written as '${string2}' instead of the written out word.""",
    correctionMessage: """Try replacing '${string}' with '${string2}'.""",
    arguments: {
      'string': string,
      'string2': string2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String name2)>
    templateBoundIssueViaCycleNonSimplicity =
    const Template<Message Function(String name, String name2)>(
  "BoundIssueViaCycleNonSimplicity",
  problemMessageTemplate:
      r"""Generic type '#name' can't be used without type arguments in the bounds of its own type variables. It is referenced indirectly through '#name2'.""",
  correctionMessageTemplate:
      r"""Try providing type arguments to '#name2' here or to some other raw types in the bounds along the reference chain.""",
  withArguments: _withArgumentsBoundIssueViaCycleNonSimplicity,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeBoundIssueViaCycleNonSimplicity = const Code(
  "BoundIssueViaCycleNonSimplicity",
  analyzerCodes: <String>["NOT_INSTANTIATED_BOUND"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsBoundIssueViaCycleNonSimplicity(
    String name, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(
    codeBoundIssueViaCycleNonSimplicity,
    problemMessage:
        """Generic type '${name}' can't be used without type arguments in the bounds of its own type variables. It is referenced indirectly through '${name2}'.""",
    correctionMessage:
        """Try providing type arguments to '${name2}' here or to some other raw types in the bounds along the reference chain.""",
    arguments: {
      'name': name,
      'name2': name2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateBoundIssueViaLoopNonSimplicity =
    const Template<Message Function(String name)>(
  "BoundIssueViaLoopNonSimplicity",
  problemMessageTemplate:
      r"""Generic type '#name' can't be used without type arguments in the bounds of its own type variables.""",
  correctionMessageTemplate:
      r"""Try providing type arguments to '#name' here.""",
  withArguments: _withArgumentsBoundIssueViaLoopNonSimplicity,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeBoundIssueViaLoopNonSimplicity = const Code(
  "BoundIssueViaLoopNonSimplicity",
  analyzerCodes: <String>["NOT_INSTANTIATED_BOUND"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsBoundIssueViaLoopNonSimplicity(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeBoundIssueViaLoopNonSimplicity,
    problemMessage:
        """Generic type '${name}' can't be used without type arguments in the bounds of its own type variables.""",
    correctionMessage: """Try providing type arguments to '${name}' here.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateBoundIssueViaRawTypeWithNonSimpleBounds =
    const Template<Message Function(String name)>(
  "BoundIssueViaRawTypeWithNonSimpleBounds",
  problemMessageTemplate:
      r"""Generic type '#name' can't be used without type arguments in a type variable bound.""",
  correctionMessageTemplate:
      r"""Try providing type arguments to '#name' here.""",
  withArguments: _withArgumentsBoundIssueViaRawTypeWithNonSimpleBounds,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeBoundIssueViaRawTypeWithNonSimpleBounds = const Code(
  "BoundIssueViaRawTypeWithNonSimpleBounds",
  analyzerCodes: <String>["NOT_INSTANTIATED_BOUND"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsBoundIssueViaRawTypeWithNonSimpleBounds(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeBoundIssueViaRawTypeWithNonSimpleBounds,
    problemMessage:
        """Generic type '${name}' can't be used without type arguments in a type variable bound.""",
    correctionMessage: """Try providing type arguments to '${name}' here.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeBreakOutsideOfLoop = messageBreakOutsideOfLoop;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageBreakOutsideOfLoop = const MessageCode(
  "BreakOutsideOfLoop",
  index: 52,
  problemMessage:
      r"""A break statement can't be used outside of a loop or switch statement.""",
  correctionMessage: r"""Try removing the break statement.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateBreakTargetOutsideFunction =
    const Template<Message Function(String name)>(
  "BreakTargetOutsideFunction",
  problemMessageTemplate:
      r"""Can't break to '#name' in a different function.""",
  withArguments: _withArgumentsBreakTargetOutsideFunction,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeBreakTargetOutsideFunction = const Code(
  "BreakTargetOutsideFunction",
  analyzerCodes: <String>["LABEL_IN_OUTER_SCOPE"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsBreakTargetOutsideFunction(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeBreakTargetOutsideFunction,
    problemMessage: """Can't break to '${name}' in a different function.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateBuiltInIdentifierAsType =
    const Template<Message Function(Token token)>(
  "BuiltInIdentifierAsType",
  problemMessageTemplate:
      r"""The built-in identifier '#lexeme' can't be used as a type.""",
  withArguments: _withArgumentsBuiltInIdentifierAsType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeBuiltInIdentifierAsType = const Code(
  "BuiltInIdentifierAsType",
  analyzerCodes: <String>["BUILT_IN_IDENTIFIER_AS_TYPE"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsBuiltInIdentifierAsType(Token token) {
  String lexeme = token.lexeme;
  return new Message(
    codeBuiltInIdentifierAsType,
    problemMessage:
        """The built-in identifier '${lexeme}' can't be used as a type.""",
    arguments: {
      'lexeme': token,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)>
    templateBuiltInIdentifierInDeclaration =
    const Template<Message Function(Token token)>(
  "BuiltInIdentifierInDeclaration",
  problemMessageTemplate: r"""Can't use '#lexeme' as a name here.""",
  withArguments: _withArgumentsBuiltInIdentifierInDeclaration,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeBuiltInIdentifierInDeclaration = const Code(
  "BuiltInIdentifierInDeclaration",
  analyzerCodes: <String>["BUILT_IN_IDENTIFIER_IN_DECLARATION"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsBuiltInIdentifierInDeclaration(Token token) {
  String lexeme = token.lexeme;
  return new Message(
    codeBuiltInIdentifierInDeclaration,
    problemMessage: """Can't use '${lexeme}' as a name here.""",
    arguments: {
      'lexeme': token,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeCandidateFound = messageCandidateFound;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCandidateFound = const MessageCode(
  "CandidateFound",
  severity: Severity.context,
  problemMessage: r"""Found this candidate, but the arguments don't match.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateCandidateFoundIsDefaultConstructor =
    const Template<Message Function(String name)>(
  "CandidateFoundIsDefaultConstructor",
  problemMessageTemplate:
      r"""The class '#name' has a constructor that takes no arguments.""",
  withArguments: _withArgumentsCandidateFoundIsDefaultConstructor,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeCandidateFoundIsDefaultConstructor = const Code(
  "CandidateFoundIsDefaultConstructor",
  severity: Severity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCandidateFoundIsDefaultConstructor(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeCandidateFoundIsDefaultConstructor,
    problemMessage:
        """The class '${name}' has a constructor that takes no arguments.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateCannotAssignToConstVariable =
    const Template<Message Function(String name)>(
  "CannotAssignToConstVariable",
  problemMessageTemplate: r"""Can't assign to the const variable '#name'.""",
  withArguments: _withArgumentsCannotAssignToConstVariable,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeCannotAssignToConstVariable = const Code(
  "CannotAssignToConstVariable",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCannotAssignToConstVariable(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeCannotAssignToConstVariable,
    problemMessage: """Can't assign to the const variable '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeCannotAssignToExtensionThis = messageCannotAssignToExtensionThis;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCannotAssignToExtensionThis = const MessageCode(
  "CannotAssignToExtensionThis",
  problemMessage: r"""Can't assign to 'this'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateCannotAssignToFinalVariable =
    const Template<Message Function(String name)>(
  "CannotAssignToFinalVariable",
  problemMessageTemplate: r"""Can't assign to the final variable '#name'.""",
  withArguments: _withArgumentsCannotAssignToFinalVariable,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeCannotAssignToFinalVariable = const Code(
  "CannotAssignToFinalVariable",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCannotAssignToFinalVariable(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeCannotAssignToFinalVariable,
    problemMessage: """Can't assign to the final variable '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeCannotAssignToParenthesizedExpression =
    messageCannotAssignToParenthesizedExpression;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCannotAssignToParenthesizedExpression =
    const MessageCode(
  "CannotAssignToParenthesizedExpression",
  analyzerCodes: <String>["ASSIGNMENT_TO_PARENTHESIZED_EXPRESSION"],
  problemMessage: r"""Can't assign to a parenthesized expression.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeCannotAssignToSuper = messageCannotAssignToSuper;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCannotAssignToSuper = const MessageCode(
  "CannotAssignToSuper",
  analyzerCodes: <String>["NOT_AN_LVALUE"],
  problemMessage: r"""Can't assign to super.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeCannotAssignToTypeLiteral = messageCannotAssignToTypeLiteral;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCannotAssignToTypeLiteral = const MessageCode(
  "CannotAssignToTypeLiteral",
  problemMessage: r"""Can't assign to a type literal.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)>
    templateCannotReadSdkSpecification =
    const Template<Message Function(String string)>(
  "CannotReadSdkSpecification",
  problemMessageTemplate:
      r"""Unable to read the 'libraries.json' specification file:
  #string.""",
  withArguments: _withArgumentsCannotReadSdkSpecification,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeCannotReadSdkSpecification = const Code(
  "CannotReadSdkSpecification",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCannotReadSdkSpecification(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(
    codeCannotReadSdkSpecification,
    problemMessage: """Unable to read the 'libraries.json' specification file:
  ${string}.""",
    arguments: {
      'string': string,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeCantDisambiguateAmbiguousInformation =
    messageCantDisambiguateAmbiguousInformation;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCantDisambiguateAmbiguousInformation =
    const MessageCode(
  "CantDisambiguateAmbiguousInformation",
  problemMessage:
      r"""Both Iterable and Map spread elements encountered in ambiguous literal.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeCantDisambiguateNotEnoughInformation =
    messageCantDisambiguateNotEnoughInformation;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCantDisambiguateNotEnoughInformation =
    const MessageCode(
  "CantDisambiguateNotEnoughInformation",
  problemMessage:
      r"""Not enough type information to disambiguate between literal set and literal map.""",
  correctionMessage:
      r"""Try providing type arguments for the literal explicitly to disambiguate it.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateCantHaveNamedParameters =
    const Template<Message Function(String name)>(
  "CantHaveNamedParameters",
  problemMessageTemplate:
      r"""'#name' can't be declared with named parameters.""",
  withArguments: _withArgumentsCantHaveNamedParameters,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeCantHaveNamedParameters = const Code(
  "CantHaveNamedParameters",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCantHaveNamedParameters(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeCantHaveNamedParameters,
    problemMessage: """'${name}' can't be declared with named parameters.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateCantHaveOptionalParameters =
    const Template<Message Function(String name)>(
  "CantHaveOptionalParameters",
  problemMessageTemplate:
      r"""'#name' can't be declared with optional parameters.""",
  withArguments: _withArgumentsCantHaveOptionalParameters,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeCantHaveOptionalParameters = const Code(
  "CantHaveOptionalParameters",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCantHaveOptionalParameters(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeCantHaveOptionalParameters,
    problemMessage: """'${name}' can't be declared with optional parameters.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeCantInferPackagesFromManyInputs =
    messageCantInferPackagesFromManyInputs;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCantInferPackagesFromManyInputs = const MessageCode(
  "CantInferPackagesFromManyInputs",
  problemMessage:
      r"""Can't infer a packages file when compiling multiple inputs.""",
  correctionMessage:
      r"""Try specifying the file explicitly with the --packages option.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeCantInferPackagesFromPackageUri =
    messageCantInferPackagesFromPackageUri;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCantInferPackagesFromPackageUri = const MessageCode(
  "CantInferPackagesFromPackageUri",
  problemMessage:
      r"""Can't infer a packages file from an input 'package:*' URI.""",
  correctionMessage:
      r"""Try specifying the file explicitly with the --packages option.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateCantInferReturnTypeDueToNoCombinedSignature =
    const Template<Message Function(String name)>(
  "CantInferReturnTypeDueToNoCombinedSignature",
  problemMessageTemplate:
      r"""Can't infer a return type for '#name' as the overridden members don't have a combined signature.""",
  correctionMessageTemplate: r"""Try adding an explicit type.""",
  withArguments: _withArgumentsCantInferReturnTypeDueToNoCombinedSignature,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeCantInferReturnTypeDueToNoCombinedSignature = const Code(
  "CantInferReturnTypeDueToNoCombinedSignature",
  analyzerCodes: <String>["COMPILE_TIME_ERROR.NO_COMBINED_SUPER_SIGNATURE"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCantInferReturnTypeDueToNoCombinedSignature(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeCantInferReturnTypeDueToNoCombinedSignature,
    problemMessage:
        """Can't infer a return type for '${name}' as the overridden members don't have a combined signature.""",
    correctionMessage: """Try adding an explicit type.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)>
    templateCantInferTypeDueToCircularity =
    const Template<Message Function(String string)>(
  "CantInferTypeDueToCircularity",
  problemMessageTemplate:
      r"""Can't infer the type of '#string': circularity found during type inference.""",
  correctionMessageTemplate: r"""Specify the type explicitly.""",
  withArguments: _withArgumentsCantInferTypeDueToCircularity,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeCantInferTypeDueToCircularity = const Code(
  "CantInferTypeDueToCircularity",
  analyzerCodes: <String>["RECURSIVE_COMPILE_TIME_CONSTANT"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCantInferTypeDueToCircularity(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(
    codeCantInferTypeDueToCircularity,
    problemMessage:
        """Can't infer the type of '${string}': circularity found during type inference.""",
    correctionMessage: """Specify the type explicitly.""",
    arguments: {
      'string': string,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateCantInferTypeDueToNoCombinedSignature =
    const Template<Message Function(String name)>(
  "CantInferTypeDueToNoCombinedSignature",
  problemMessageTemplate:
      r"""Can't infer a type for '#name' as the overridden members don't have a combined signature.""",
  correctionMessageTemplate: r"""Try adding an explicit type.""",
  withArguments: _withArgumentsCantInferTypeDueToNoCombinedSignature,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeCantInferTypeDueToNoCombinedSignature = const Code(
  "CantInferTypeDueToNoCombinedSignature",
  analyzerCodes: <String>["COMPILE_TIME_ERROR.NO_COMBINED_SUPER_SIGNATURE"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCantInferTypeDueToNoCombinedSignature(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeCantInferTypeDueToNoCombinedSignature,
    problemMessage:
        """Can't infer a type for '${name}' as the overridden members don't have a combined signature.""",
    correctionMessage: """Try adding an explicit type.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateCantInferTypesDueToNoCombinedSignature =
    const Template<Message Function(String name)>(
  "CantInferTypesDueToNoCombinedSignature",
  problemMessageTemplate:
      r"""Can't infer types for '#name' as the overridden members don't have a combined signature.""",
  correctionMessageTemplate: r"""Try adding explicit types.""",
  withArguments: _withArgumentsCantInferTypesDueToNoCombinedSignature,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeCantInferTypesDueToNoCombinedSignature = const Code(
  "CantInferTypesDueToNoCombinedSignature",
  analyzerCodes: <String>["COMPILE_TIME_ERROR.NO_COMBINED_SUPER_SIGNATURE"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCantInferTypesDueToNoCombinedSignature(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeCantInferTypesDueToNoCombinedSignature,
    problemMessage:
        """Can't infer types for '${name}' as the overridden members don't have a combined signature.""",
    correctionMessage: """Try adding explicit types.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri_, String string)> templateCantReadFile =
    const Template<Message Function(Uri uri_, String string)>(
  "CantReadFile",
  problemMessageTemplate: r"""Error when reading '#uri': #string""",
  withArguments: _withArgumentsCantReadFile,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeCantReadFile = const Code(
  "CantReadFile",
  analyzerCodes: <String>["URI_DOES_NOT_EXIST"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCantReadFile(Uri uri_, String string) {
  String? uri = relativizeUri(uri_);
  if (string.isEmpty) throw 'No string provided';
  return new Message(
    codeCantReadFile,
    problemMessage: """Error when reading '${uri}': ${string}""",
    arguments: {
      'uri': uri_,
      'string': string,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateCantUseClassAsMixin =
    const Template<Message Function(String name)>(
  "CantUseClassAsMixin",
  problemMessageTemplate:
      r"""The class '#name' can't be used as a mixin because it isn't a mixin class nor a mixin.""",
  withArguments: _withArgumentsCantUseClassAsMixin,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeCantUseClassAsMixin = const Code(
  "CantUseClassAsMixin",
  analyzerCodes: <String>["CLASS_USED_AS_MIXIN"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCantUseClassAsMixin(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeCantUseClassAsMixin,
    problemMessage:
        """The class '${name}' can't be used as a mixin because it isn't a mixin class nor a mixin.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)>
    templateCantUseControlFlowOrSpreadAsConstant =
    const Template<Message Function(Token token)>(
  "CantUseControlFlowOrSpreadAsConstant",
  problemMessageTemplate:
      r"""'#lexeme' is not supported in constant expressions.""",
  withArguments: _withArgumentsCantUseControlFlowOrSpreadAsConstant,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeCantUseControlFlowOrSpreadAsConstant = const Code(
  "CantUseControlFlowOrSpreadAsConstant",
  analyzerCodes: <String>["NOT_CONSTANT_EXPRESSION"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCantUseControlFlowOrSpreadAsConstant(Token token) {
  String lexeme = token.lexeme;
  return new Message(
    codeCantUseControlFlowOrSpreadAsConstant,
    problemMessage: """'${lexeme}' is not supported in constant expressions.""",
    arguments: {
      'lexeme': token,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)>
    templateCantUseDeferredPrefixAsConstant =
    const Template<Message Function(Token token)>(
  "CantUseDeferredPrefixAsConstant",
  problemMessageTemplate:
      r"""'#lexeme' can't be used in a constant expression because it's marked as 'deferred' which means it isn't available until loaded.""",
  correctionMessageTemplate:
      r"""Try moving the constant from the deferred library, or removing 'deferred' from the import.
""",
  withArguments: _withArgumentsCantUseDeferredPrefixAsConstant,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeCantUseDeferredPrefixAsConstant = const Code(
  "CantUseDeferredPrefixAsConstant",
  analyzerCodes: <String>["CONST_DEFERRED_CLASS"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCantUseDeferredPrefixAsConstant(Token token) {
  String lexeme = token.lexeme;
  return new Message(
    codeCantUseDeferredPrefixAsConstant,
    problemMessage:
        """'${lexeme}' can't be used in a constant expression because it's marked as 'deferred' which means it isn't available until loaded.""",
    correctionMessage:
        """Try moving the constant from the deferred library, or removing 'deferred' from the import.
""",
    arguments: {
      'lexeme': token,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeCantUsePrefixAsExpression = messageCantUsePrefixAsExpression;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCantUsePrefixAsExpression = const MessageCode(
  "CantUsePrefixAsExpression",
  analyzerCodes: <String>["PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT"],
  problemMessage: r"""A prefix can't be used as an expression.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeCantUsePrefixWithNullAware = messageCantUsePrefixWithNullAware;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCantUsePrefixWithNullAware = const MessageCode(
  "CantUsePrefixWithNullAware",
  analyzerCodes: <String>["PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT"],
  problemMessage: r"""A prefix can't be used with null-aware operators.""",
  correctionMessage: r"""Try replacing '?.' with '.'""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeCatchSyntax = messageCatchSyntax;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCatchSyntax = const MessageCode(
  "CatchSyntax",
  index: 84,
  problemMessage:
      r"""'catch' must be followed by '(identifier)' or '(identifier, identifier)'.""",
  correctionMessage:
      r"""No types are needed, the first is given by 'on', the second is always 'StackTrace'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeCatchSyntaxExtraParameters = messageCatchSyntaxExtraParameters;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCatchSyntaxExtraParameters = const MessageCode(
  "CatchSyntaxExtraParameters",
  index: 83,
  problemMessage:
      r"""'catch' must be followed by '(identifier)' or '(identifier, identifier)'.""",
  correctionMessage:
      r"""No types are needed, the first is given by 'on', the second is always 'StackTrace'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeClassImplementsDeferredClass =
    messageClassImplementsDeferredClass;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageClassImplementsDeferredClass = const MessageCode(
  "ClassImplementsDeferredClass",
  analyzerCodes: <String>["IMPLEMENTS_DEFERRED_CLASS"],
  problemMessage: r"""Classes and mixins can't implement deferred classes.""",
  correctionMessage:
      r"""Try specifying a different interface, removing the class from the list, or changing the import to not be deferred.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeClassInClass = messageClassInClass;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageClassInClass = const MessageCode(
  "ClassInClass",
  index: 53,
  problemMessage: r"""Classes can't be declared inside other classes.""",
  correctionMessage: r"""Try moving the class to the top-level.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateClassShouldBeListedAsCallableInDynamicInterface =
    const Template<Message Function(String name)>(
  "ClassShouldBeListedAsCallableInDynamicInterface",
  problemMessageTemplate: r"""Cannot use class '#name' in a dynamic module.""",
  correctionMessageTemplate:
      r"""Try removing the reference to class '#name' or update the dynamic interface to list class '#name' as callable.""",
  withArguments: _withArgumentsClassShouldBeListedAsCallableInDynamicInterface,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeClassShouldBeListedAsCallableInDynamicInterface = const Code(
  "ClassShouldBeListedAsCallableInDynamicInterface",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsClassShouldBeListedAsCallableInDynamicInterface(
    String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeClassShouldBeListedAsCallableInDynamicInterface,
    problemMessage: """Cannot use class '${name}' in a dynamic module.""",
    correctionMessage:
        """Try removing the reference to class '${name}' or update the dynamic interface to list class '${name}' as callable.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateClassShouldBeListedAsExtendableInDynamicInterface =
    const Template<Message Function(String name)>(
  "ClassShouldBeListedAsExtendableInDynamicInterface",
  problemMessageTemplate:
      r"""Cannot extend, implement or mix-in class '#name' in a dynamic module.""",
  correctionMessageTemplate:
      r"""Try removing the reference to class '#name' or update the dynamic interface to list class '#name' as extendable.""",
  withArguments:
      _withArgumentsClassShouldBeListedAsExtendableInDynamicInterface,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeClassShouldBeListedAsExtendableInDynamicInterface = const Code(
  "ClassShouldBeListedAsExtendableInDynamicInterface",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsClassShouldBeListedAsExtendableInDynamicInterface(
    String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeClassShouldBeListedAsExtendableInDynamicInterface,
    problemMessage:
        """Cannot extend, implement or mix-in class '${name}' in a dynamic module.""",
    correctionMessage:
        """Try removing the reference to class '${name}' or update the dynamic interface to list class '${name}' as extendable.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeColonInPlaceOfIn = messageColonInPlaceOfIn;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageColonInPlaceOfIn = const MessageCode(
  "ColonInPlaceOfIn",
  index: 54,
  problemMessage: r"""For-in loops use 'in' rather than a colon.""",
  correctionMessage: r"""Try replacing the colon with the keyword 'in'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String name2)>
    templateCombinedMemberSignatureFailed =
    const Template<Message Function(String name, String name2)>(
  "CombinedMemberSignatureFailed",
  problemMessageTemplate:
      r"""Class '#name' inherits multiple members named '#name2' with incompatible signatures.""",
  correctionMessageTemplate:
      r"""Try adding a declaration of '#name2' to '#name'.""",
  withArguments: _withArgumentsCombinedMemberSignatureFailed,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeCombinedMemberSignatureFailed = const Code(
  "CombinedMemberSignatureFailed",
  analyzerCodes: <String>["INCONSISTENT_INHERITANCE"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCombinedMemberSignatureFailed(String name, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(
    codeCombinedMemberSignatureFailed,
    problemMessage:
        """Class '${name}' inherits multiple members named '${name2}' with incompatible signatures.""",
    correctionMessage:
        """Try adding a declaration of '${name2}' to '${name}'.""",
    arguments: {
      'name': name,
      'name2': name2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string, String string2)>
    templateConflictingModifiers =
    const Template<Message Function(String string, String string2)>(
  "ConflictingModifiers",
  problemMessageTemplate:
      r"""Members can't be declared to be both '#string' and '#string2'.""",
  correctionMessageTemplate: r"""Try removing one of the keywords.""",
  withArguments: _withArgumentsConflictingModifiers,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConflictingModifiers = const Code(
  "ConflictingModifiers",
  index: 59,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConflictingModifiers(String string, String string2) {
  if (string.isEmpty) throw 'No string provided';
  if (string2.isEmpty) throw 'No string provided';
  return new Message(
    codeConflictingModifiers,
    problemMessage:
        """Members can't be declared to be both '${string}' and '${string2}'.""",
    correctionMessage: """Try removing one of the keywords.""",
    arguments: {
      'string': string,
      'string2': string2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateConflictsWithImplicitSetter =
    const Template<Message Function(String name)>(
  "ConflictsWithImplicitSetter",
  problemMessageTemplate:
      r"""Conflicts with the implicit setter of the field '#name'.""",
  withArguments: _withArgumentsConflictsWithImplicitSetter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConflictsWithImplicitSetter = const Code(
  "ConflictsWithImplicitSetter",
  analyzerCodes: <String>["CONFLICTS_WITH_MEMBER"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConflictsWithImplicitSetter(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeConflictsWithImplicitSetter,
    problemMessage:
        """Conflicts with the implicit setter of the field '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateConflictsWithImplicitSetterCause =
    const Template<Message Function(String name)>(
  "ConflictsWithImplicitSetterCause",
  problemMessageTemplate: r"""Field '#name' with the implicit setter.""",
  withArguments: _withArgumentsConflictsWithImplicitSetterCause,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConflictsWithImplicitSetterCause = const Code(
  "ConflictsWithImplicitSetterCause",
  severity: Severity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConflictsWithImplicitSetterCause(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeConflictsWithImplicitSetterCause,
    problemMessage: """Field '${name}' with the implicit setter.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateConflictsWithTypeParameter =
    const Template<Message Function(String name)>(
  "ConflictsWithTypeParameter",
  problemMessageTemplate: r"""Conflicts with type variable '#name'.""",
  withArguments: _withArgumentsConflictsWithTypeParameter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConflictsWithTypeParameter = const Code(
  "ConflictsWithTypeParameter",
  analyzerCodes: <String>["CONFLICTING_TYPE_VARIABLE_AND_MEMBER"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConflictsWithTypeParameter(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeConflictsWithTypeParameter,
    problemMessage: """Conflicts with type variable '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConflictsWithTypeParameterCause =
    messageConflictsWithTypeParameterCause;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConflictsWithTypeParameterCause = const MessageCode(
  "ConflictsWithTypeParameterCause",
  severity: Severity.context,
  problemMessage: r"""This is the type variable.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConstAndFinal = messageConstAndFinal;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstAndFinal = const MessageCode(
  "ConstAndFinal",
  index: 58,
  problemMessage:
      r"""Members can't be declared to be both 'const' and 'final'.""",
  correctionMessage: r"""Try removing either the 'const' or 'final' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConstClass = messageConstClass;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstClass = const MessageCode(
  "ConstClass",
  index: 60,
  problemMessage: r"""Classes can't be declared to be 'const'.""",
  correctionMessage:
      r"""Try removing the 'const' keyword. If you're trying to indicate that instances of the class can be constants, place the 'const' keyword on  the class' constructor(s).""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConstConstructorLateFinalFieldCause =
    messageConstConstructorLateFinalFieldCause;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstConstructorLateFinalFieldCause =
    const MessageCode(
  "ConstConstructorLateFinalFieldCause",
  severity: Severity.context,
  problemMessage: r"""This constructor is const.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConstConstructorLateFinalFieldError =
    messageConstConstructorLateFinalFieldError;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstConstructorLateFinalFieldError =
    const MessageCode(
  "ConstConstructorLateFinalFieldError",
  problemMessage:
      r"""Can't have a late final field in a class with a const constructor.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConstConstructorNonFinalField =
    messageConstConstructorNonFinalField;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstConstructorNonFinalField = const MessageCode(
  "ConstConstructorNonFinalField",
  analyzerCodes: <String>["CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD"],
  problemMessage:
      r"""Constructor is marked 'const' so all fields must be final.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConstConstructorNonFinalFieldCause =
    messageConstConstructorNonFinalFieldCause;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstConstructorNonFinalFieldCause = const MessageCode(
  "ConstConstructorNonFinalFieldCause",
  severity: Severity.context,
  problemMessage: r"""Field isn't final, but constructor is 'const'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConstConstructorRedirectionToNonConst =
    messageConstConstructorRedirectionToNonConst;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstConstructorRedirectionToNonConst =
    const MessageCode(
  "ConstConstructorRedirectionToNonConst",
  problemMessage:
      r"""A constant constructor can't call a non-constant constructor.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConstConstructorWithBody = messageConstConstructorWithBody;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstConstructorWithBody = const MessageCode(
  "ConstConstructorWithBody",
  analyzerCodes: <String>["CONST_CONSTRUCTOR_WITH_BODY"],
  problemMessage: r"""A const constructor can't have a body.""",
  correctionMessage:
      r"""Try removing either the 'const' keyword or the body.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConstConstructorWithNonConstSuper =
    messageConstConstructorWithNonConstSuper;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstConstructorWithNonConstSuper = const MessageCode(
  "ConstConstructorWithNonConstSuper",
  analyzerCodes: <String>["CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER"],
  problemMessage:
      r"""A constant constructor can't call a non-constant super constructor.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConstEvalCircularity = messageConstEvalCircularity;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstEvalCircularity = const MessageCode(
  "ConstEvalCircularity",
  analyzerCodes: <String>["RECURSIVE_COMPILE_TIME_CONSTANT"],
  problemMessage: r"""Constant expression depends on itself.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConstEvalContext = messageConstEvalContext;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstEvalContext = const MessageCode(
  "ConstEvalContext",
  problemMessage: r"""While analyzing:""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String nameOKEmpty)>
    templateConstEvalDeferredLibrary =
    const Template<Message Function(String nameOKEmpty)>(
  "ConstEvalDeferredLibrary",
  problemMessageTemplate:
      r"""'#nameOKEmpty' can't be used in a constant expression because it's marked as 'deferred' which means it isn't available until loaded.""",
  correctionMessageTemplate:
      r"""Try moving the constant from the deferred library, or removing 'deferred' from the import.
""",
  withArguments: _withArgumentsConstEvalDeferredLibrary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConstEvalDeferredLibrary = const Code(
  "ConstEvalDeferredLibrary",
  analyzerCodes: <String>[
    "INVALID_ANNOTATION_CONSTANT_VALUE_FROM_DEFERRED_LIBRARY"
  ],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalDeferredLibrary(String nameOKEmpty) {
  if (nameOKEmpty.isEmpty) nameOKEmpty = '(unnamed)';
  return new Message(
    codeConstEvalDeferredLibrary,
    problemMessage:
        """'${nameOKEmpty}' can't be used in a constant expression because it's marked as 'deferred' which means it isn't available until loaded.""",
    correctionMessage:
        """Try moving the constant from the deferred library, or removing 'deferred' from the import.
""",
    arguments: {
      'nameOKEmpty': nameOKEmpty,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)> templateConstEvalError =
    const Template<Message Function(String string)>(
  "ConstEvalError",
  problemMessageTemplate: r"""Error evaluating constant expression: #string""",
  withArguments: _withArgumentsConstEvalError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConstEvalError = const Code(
  "ConstEvalError",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalError(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(
    codeConstEvalError,
    problemMessage: """Error evaluating constant expression: ${string}""",
    arguments: {
      'string': string,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConstEvalExtension = messageConstEvalExtension;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstEvalExtension = const MessageCode(
  "ConstEvalExtension",
  analyzerCodes: <String>["NOT_CONSTANT_EXPRESSION"],
  problemMessage:
      r"""Extension operations can't be used in constant expressions.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConstEvalExternalConstructor =
    messageConstEvalExternalConstructor;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstEvalExternalConstructor = const MessageCode(
  "ConstEvalExternalConstructor",
  problemMessage:
      r"""External constructors can't be evaluated in constant expressions.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConstEvalExternalFactory = messageConstEvalExternalFactory;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstEvalExternalFactory = const MessageCode(
  "ConstEvalExternalFactory",
  problemMessage:
      r"""External factory constructors can't be evaluated in constant expressions.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConstEvalFailedAssertion = messageConstEvalFailedAssertion;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstEvalFailedAssertion = const MessageCode(
  "ConstEvalFailedAssertion",
  analyzerCodes: <String>["CONST_EVAL_THROWS_EXCEPTION"],
  problemMessage: r"""This assertion failed.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String stringOKEmpty)>
    templateConstEvalFailedAssertionWithMessage =
    const Template<Message Function(String stringOKEmpty)>(
  "ConstEvalFailedAssertionWithMessage",
  problemMessageTemplate:
      r"""This assertion failed with message: #stringOKEmpty""",
  withArguments: _withArgumentsConstEvalFailedAssertionWithMessage,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConstEvalFailedAssertionWithMessage = const Code(
  "ConstEvalFailedAssertionWithMessage",
  analyzerCodes: <String>["CONST_EVAL_THROWS_EXCEPTION"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalFailedAssertionWithMessage(
    String stringOKEmpty) {
  if (stringOKEmpty.isEmpty) stringOKEmpty = '(empty)';
  return new Message(
    codeConstEvalFailedAssertionWithMessage,
    problemMessage: """This assertion failed with message: ${stringOKEmpty}""",
    arguments: {
      'stringOKEmpty': stringOKEmpty,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConstEvalFailedAssertionWithNonStringMessage =
    messageConstEvalFailedAssertionWithNonStringMessage;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstEvalFailedAssertionWithNonStringMessage =
    const MessageCode(
  "ConstEvalFailedAssertionWithNonStringMessage",
  analyzerCodes: <String>["CONST_EVAL_THROWS_EXCEPTION"],
  problemMessage: r"""This assertion failed with a non-String message.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String nameOKEmpty)>
    templateConstEvalGetterNotFound =
    const Template<Message Function(String nameOKEmpty)>(
  "ConstEvalGetterNotFound",
  problemMessageTemplate: r"""Variable get not found: '#nameOKEmpty'""",
  withArguments: _withArgumentsConstEvalGetterNotFound,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConstEvalGetterNotFound = const Code(
  "ConstEvalGetterNotFound",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalGetterNotFound(String nameOKEmpty) {
  if (nameOKEmpty.isEmpty) nameOKEmpty = '(unnamed)';
  return new Message(
    codeConstEvalGetterNotFound,
    problemMessage: """Variable get not found: '${nameOKEmpty}'""",
    arguments: {
      'nameOKEmpty': nameOKEmpty,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String nameOKEmpty)>
    templateConstEvalInvalidStaticInvocation =
    const Template<Message Function(String nameOKEmpty)>(
  "ConstEvalInvalidStaticInvocation",
  problemMessageTemplate:
      r"""The invocation of '#nameOKEmpty' is not allowed in a constant expression.""",
  withArguments: _withArgumentsConstEvalInvalidStaticInvocation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConstEvalInvalidStaticInvocation = const Code(
  "ConstEvalInvalidStaticInvocation",
  analyzerCodes: <String>["CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalInvalidStaticInvocation(String nameOKEmpty) {
  if (nameOKEmpty.isEmpty) nameOKEmpty = '(unnamed)';
  return new Message(
    codeConstEvalInvalidStaticInvocation,
    problemMessage:
        """The invocation of '${nameOKEmpty}' is not allowed in a constant expression.""",
    arguments: {
      'nameOKEmpty': nameOKEmpty,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string, String string2, String string3)>
    templateConstEvalNegativeShift = const Template<
        Message Function(String string, String string2, String string3)>(
  "ConstEvalNegativeShift",
  problemMessageTemplate:
      r"""Binary operator '#string' on '#string2' requires non-negative operand, but was '#string3'.""",
  withArguments: _withArgumentsConstEvalNegativeShift,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConstEvalNegativeShift = const Code(
  "ConstEvalNegativeShift",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalNegativeShift(
    String string, String string2, String string3) {
  if (string.isEmpty) throw 'No string provided';
  if (string2.isEmpty) throw 'No string provided';
  if (string3.isEmpty) throw 'No string provided';
  return new Message(
    codeConstEvalNegativeShift,
    problemMessage:
        """Binary operator '${string}' on '${string2}' requires non-negative operand, but was '${string3}'.""",
    arguments: {
      'string': string,
      'string2': string2,
      'string3': string3,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String nameOKEmpty)>
    templateConstEvalNonConstantVariableGet =
    const Template<Message Function(String nameOKEmpty)>(
  "ConstEvalNonConstantVariableGet",
  problemMessageTemplate:
      r"""The variable '#nameOKEmpty' is not a constant, only constant expressions are allowed.""",
  withArguments: _withArgumentsConstEvalNonConstantVariableGet,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConstEvalNonConstantVariableGet = const Code(
  "ConstEvalNonConstantVariableGet",
  analyzerCodes: <String>["NON_CONSTANT_VALUE_IN_INITIALIZER"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalNonConstantVariableGet(String nameOKEmpty) {
  if (nameOKEmpty.isEmpty) nameOKEmpty = '(unnamed)';
  return new Message(
    codeConstEvalNonConstantVariableGet,
    problemMessage:
        """The variable '${nameOKEmpty}' is not a constant, only constant expressions are allowed.""",
    arguments: {
      'nameOKEmpty': nameOKEmpty,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConstEvalNonNull = messageConstEvalNonNull;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstEvalNonNull = const MessageCode(
  "ConstEvalNonNull",
  problemMessage: r"""Constant expression must be non-null.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConstEvalNotListOrSetInSpread =
    messageConstEvalNotListOrSetInSpread;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstEvalNotListOrSetInSpread = const MessageCode(
  "ConstEvalNotListOrSetInSpread",
  analyzerCodes: <String>["CONST_SPREAD_EXPECTED_LIST_OR_SET"],
  problemMessage:
      r"""Only lists and sets can be used in spreads in constant lists and sets.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConstEvalNotMapInSpread = messageConstEvalNotMapInSpread;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstEvalNotMapInSpread = const MessageCode(
  "ConstEvalNotMapInSpread",
  analyzerCodes: <String>["CONST_SPREAD_EXPECTED_MAP"],
  problemMessage: r"""Only maps can be used in spreads in constant maps.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConstEvalNullValue = messageConstEvalNullValue;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstEvalNullValue = const MessageCode(
  "ConstEvalNullValue",
  analyzerCodes: <String>["CONST_EVAL_THROWS_EXCEPTION"],
  problemMessage: r"""Null value during constant evaluation.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConstEvalStartingPoint = messageConstEvalStartingPoint;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstEvalStartingPoint = const MessageCode(
  "ConstEvalStartingPoint",
  problemMessage: r"""Constant evaluation error:""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string, String string2)>
    templateConstEvalTruncateError =
    const Template<Message Function(String string, String string2)>(
  "ConstEvalTruncateError",
  problemMessageTemplate:
      r"""Binary operator '#string ~/ #string2' results is Infinity or NaN.""",
  withArguments: _withArgumentsConstEvalTruncateError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConstEvalTruncateError = const Code(
  "ConstEvalTruncateError",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalTruncateError(String string, String string2) {
  if (string.isEmpty) throw 'No string provided';
  if (string2.isEmpty) throw 'No string provided';
  return new Message(
    codeConstEvalTruncateError,
    problemMessage:
        """Binary operator '${string} ~/ ${string2}' results is Infinity or NaN.""",
    arguments: {
      'string': string,
      'string2': string2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConstEvalUnevaluated = messageConstEvalUnevaluated;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstEvalUnevaluated = const MessageCode(
  "ConstEvalUnevaluated",
  problemMessage: r"""Couldn't evaluate constant expression.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String stringOKEmpty)>
    templateConstEvalUnhandledCoreException =
    const Template<Message Function(String stringOKEmpty)>(
  "ConstEvalUnhandledCoreException",
  problemMessageTemplate: r"""Unhandled core exception: #stringOKEmpty""",
  withArguments: _withArgumentsConstEvalUnhandledCoreException,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConstEvalUnhandledCoreException = const Code(
  "ConstEvalUnhandledCoreException",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalUnhandledCoreException(String stringOKEmpty) {
  if (stringOKEmpty.isEmpty) stringOKEmpty = '(empty)';
  return new Message(
    codeConstEvalUnhandledCoreException,
    problemMessage: """Unhandled core exception: ${stringOKEmpty}""",
    arguments: {
      'stringOKEmpty': stringOKEmpty,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string, String string2)>
    templateConstEvalZeroDivisor =
    const Template<Message Function(String string, String string2)>(
  "ConstEvalZeroDivisor",
  problemMessageTemplate:
      r"""Binary operator '#string' on '#string2' requires non-zero divisor, but divisor was '0'.""",
  withArguments: _withArgumentsConstEvalZeroDivisor,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConstEvalZeroDivisor = const Code(
  "ConstEvalZeroDivisor",
  analyzerCodes: <String>["CONST_EVAL_THROWS_IDBZE"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalZeroDivisor(String string, String string2) {
  if (string.isEmpty) throw 'No string provided';
  if (string2.isEmpty) throw 'No string provided';
  return new Message(
    codeConstEvalZeroDivisor,
    problemMessage:
        """Binary operator '${string}' on '${string2}' requires non-zero divisor, but divisor was '0'.""",
    arguments: {
      'string': string,
      'string2': string2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConstFactory = messageConstFactory;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstFactory = const MessageCode(
  "ConstFactory",
  index: 62,
  problemMessage:
      r"""Only redirecting factory constructors can be declared to be 'const'.""",
  correctionMessage:
      r"""Try removing the 'const' keyword, or replacing the body with '=' followed by a valid target.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConstFactoryRedirectionToNonConst =
    messageConstFactoryRedirectionToNonConst;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstFactoryRedirectionToNonConst = const MessageCode(
  "ConstFactoryRedirectionToNonConst",
  analyzerCodes: <String>["REDIRECT_TO_NON_CONST_CONSTRUCTOR"],
  problemMessage:
      r"""Constant factory constructor can't delegate to a non-constant constructor.""",
  correctionMessage:
      r"""Try redirecting to a different constructor or marking the target constructor 'const'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateConstFieldWithoutInitializer =
    const Template<Message Function(String name)>(
  "ConstFieldWithoutInitializer",
  problemMessageTemplate:
      r"""The const variable '#name' must be initialized.""",
  correctionMessageTemplate:
      r"""Try adding an initializer ('= expression') to the declaration.""",
  withArguments: _withArgumentsConstFieldWithoutInitializer,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConstFieldWithoutInitializer = const Code(
  "ConstFieldWithoutInitializer",
  analyzerCodes: <String>["CONST_NOT_INITIALIZED"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstFieldWithoutInitializer(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeConstFieldWithoutInitializer,
    problemMessage: """The const variable '${name}' must be initialized.""",
    correctionMessage:
        """Try adding an initializer ('= expression') to the declaration.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConstInstanceField = messageConstInstanceField;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstInstanceField = const MessageCode(
  "ConstInstanceField",
  analyzerCodes: <String>["CONST_INSTANCE_FIELD"],
  problemMessage: r"""Only static fields can be declared as const.""",
  correctionMessage:
      r"""Try using 'final' instead of 'const', or adding the keyword 'static'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConstMethod = messageConstMethod;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstMethod = const MessageCode(
  "ConstMethod",
  index: 63,
  problemMessage:
      r"""Getters, setters and methods can't be declared to be 'const'.""",
  correctionMessage: r"""Try removing the 'const' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateConstructorConflictsWithMember =
    const Template<Message Function(String name)>(
  "ConstructorConflictsWithMember",
  problemMessageTemplate: r"""The constructor conflicts with member '#name'.""",
  withArguments: _withArgumentsConstructorConflictsWithMember,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConstructorConflictsWithMember = const Code(
  "ConstructorConflictsWithMember",
  analyzerCodes: <String>["CONFLICTS_WITH_MEMBER"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstructorConflictsWithMember(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeConstructorConflictsWithMember,
    problemMessage: """The constructor conflicts with member '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateConstructorConflictsWithMemberCause =
    const Template<Message Function(String name)>(
  "ConstructorConflictsWithMemberCause",
  problemMessageTemplate: r"""Conflicting member '#name'.""",
  withArguments: _withArgumentsConstructorConflictsWithMemberCause,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConstructorConflictsWithMemberCause = const Code(
  "ConstructorConflictsWithMemberCause",
  severity: Severity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstructorConflictsWithMemberCause(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeConstructorConflictsWithMemberCause,
    problemMessage: """Conflicting member '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConstructorCyclic = messageConstructorCyclic;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstructorCyclic = const MessageCode(
  "ConstructorCyclic",
  analyzerCodes: <String>["RECURSIVE_CONSTRUCTOR_REDIRECT"],
  problemMessage: r"""Redirecting constructors can't be cyclic.""",
  correctionMessage:
      r"""Try to have all constructors eventually redirect to a non-redirecting constructor.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateConstructorInitializeSameInstanceVariableSeveralTimes =
    const Template<Message Function(String name)>(
  "ConstructorInitializeSameInstanceVariableSeveralTimes",
  problemMessageTemplate:
      r"""'#name' was already initialized by this constructor.""",
  withArguments:
      _withArgumentsConstructorInitializeSameInstanceVariableSeveralTimes,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConstructorInitializeSameInstanceVariableSeveralTimes =
    const Code(
  "ConstructorInitializeSameInstanceVariableSeveralTimes",
  analyzerCodes: <String>["FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstructorInitializeSameInstanceVariableSeveralTimes(
    String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeConstructorInitializeSameInstanceVariableSeveralTimes,
    problemMessage:
        """'${name}' was already initialized by this constructor.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateConstructorNotFound =
    const Template<Message Function(String name)>(
  "ConstructorNotFound",
  problemMessageTemplate: r"""Couldn't find constructor '#name'.""",
  withArguments: _withArgumentsConstructorNotFound,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConstructorNotFound = const Code(
  "ConstructorNotFound",
  analyzerCodes: <String>["CONSTRUCTOR_NOT_FOUND"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstructorNotFound(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeConstructorNotFound,
    problemMessage: """Couldn't find constructor '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConstructorNotSync = messageConstructorNotSync;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstructorNotSync = const MessageCode(
  "ConstructorNotSync",
  analyzerCodes: <String>["NON_SYNC_CONSTRUCTOR"],
  problemMessage:
      r"""Constructor bodies can't use 'async', 'async*', or 'sync*'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateConstructorShouldBeListedAsCallableInDynamicInterface =
    const Template<Message Function(String name)>(
  "ConstructorShouldBeListedAsCallableInDynamicInterface",
  problemMessageTemplate:
      r"""Cannot invoke constructor '#name' from a dynamic module.""",
  correctionMessageTemplate:
      r"""Try removing the call or update the dynamic interface to list constructor '#name' as callable.""",
  withArguments:
      _withArgumentsConstructorShouldBeListedAsCallableInDynamicInterface,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConstructorShouldBeListedAsCallableInDynamicInterface =
    const Code(
  "ConstructorShouldBeListedAsCallableInDynamicInterface",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstructorShouldBeListedAsCallableInDynamicInterface(
    String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeConstructorShouldBeListedAsCallableInDynamicInterface,
    problemMessage:
        """Cannot invoke constructor '${name}' from a dynamic module.""",
    correctionMessage:
        """Try removing the call or update the dynamic interface to list constructor '${name}' as callable.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConstructorTearOffWithTypeArguments =
    messageConstructorTearOffWithTypeArguments;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstructorTearOffWithTypeArguments =
    const MessageCode(
  "ConstructorTearOffWithTypeArguments",
  problemMessage:
      r"""A constructor tear-off can't have type arguments after the constructor name.""",
  correctionMessage:
      r"""Try removing the type arguments or placing them after the class name.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConstructorWithReturnType = messageConstructorWithReturnType;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstructorWithReturnType = const MessageCode(
  "ConstructorWithReturnType",
  index: 55,
  problemMessage: r"""Constructors can't have a return type.""",
  correctionMessage: r"""Try removing the return type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConstructorWithTypeArguments =
    messageConstructorWithTypeArguments;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstructorWithTypeArguments = const MessageCode(
  "ConstructorWithTypeArguments",
  index: 118,
  problemMessage:
      r"""A constructor invocation can't have type arguments after the constructor name.""",
  correctionMessage:
      r"""Try removing the type arguments or placing them after the class name.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConstructorWithTypeParameters =
    messageConstructorWithTypeParameters;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstructorWithTypeParameters = const MessageCode(
  "ConstructorWithTypeParameters",
  index: 99,
  problemMessage: r"""Constructors can't have type parameters.""",
  correctionMessage: r"""Try removing the type parameters.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConstructorWithWrongName = messageConstructorWithWrongName;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstructorWithWrongName = const MessageCode(
  "ConstructorWithWrongName",
  index: 102,
  problemMessage:
      r"""The name of a constructor must match the name of the enclosing class.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateConstructorWithWrongNameContext =
    const Template<Message Function(String name)>(
  "ConstructorWithWrongNameContext",
  problemMessageTemplate: r"""The name of the enclosing class is '#name'.""",
  withArguments: _withArgumentsConstructorWithWrongNameContext,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeConstructorWithWrongNameContext = const Code(
  "ConstructorWithWrongNameContext",
  severity: Severity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstructorWithWrongNameContext(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeConstructorWithWrongNameContext,
    problemMessage: """The name of the enclosing class is '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeContinueLabelInvalid = messageContinueLabelInvalid;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageContinueLabelInvalid = const MessageCode(
  "ContinueLabelInvalid",
  analyzerCodes: <String>["CONTINUE_LABEL_INVALID"],
  problemMessage:
      r"""A 'continue' label must be on a loop or a switch member.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeContinueOutsideOfLoop = messageContinueOutsideOfLoop;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageContinueOutsideOfLoop = const MessageCode(
  "ContinueOutsideOfLoop",
  index: 2,
  problemMessage:
      r"""A continue statement can't be used outside of a loop or switch statement.""",
  correctionMessage: r"""Try removing the continue statement.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateContinueTargetOutsideFunction =
    const Template<Message Function(String name)>(
  "ContinueTargetOutsideFunction",
  problemMessageTemplate:
      r"""Can't continue at '#name' in a different function.""",
  withArguments: _withArgumentsContinueTargetOutsideFunction,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeContinueTargetOutsideFunction = const Code(
  "ContinueTargetOutsideFunction",
  analyzerCodes: <String>["LABEL_IN_OUTER_SCOPE"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsContinueTargetOutsideFunction(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeContinueTargetOutsideFunction,
    problemMessage: """Can't continue at '${name}' in a different function.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeContinueWithoutLabelInCase = messageContinueWithoutLabelInCase;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageContinueWithoutLabelInCase = const MessageCode(
  "ContinueWithoutLabelInCase",
  index: 64,
  problemMessage:
      r"""A continue statement in a switch statement must have a label as a target.""",
  correctionMessage:
      r"""Try adding a label associated with one of the case clauses to the continue statement.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string, String string2)>
    templateCouldNotParseUri =
    const Template<Message Function(String string, String string2)>(
  "CouldNotParseUri",
  problemMessageTemplate: r"""Couldn't parse URI '#string':
  #string2.""",
  withArguments: _withArgumentsCouldNotParseUri,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeCouldNotParseUri = const Code(
  "CouldNotParseUri",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCouldNotParseUri(String string, String string2) {
  if (string.isEmpty) throw 'No string provided';
  if (string2.isEmpty) throw 'No string provided';
  return new Message(
    codeCouldNotParseUri,
    problemMessage: """Couldn't parse URI '${string}':
  ${string2}.""",
    arguments: {
      'string': string,
      'string2': string2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeCovariantAndStatic = messageCovariantAndStatic;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCovariantAndStatic = const MessageCode(
  "CovariantAndStatic",
  index: 66,
  problemMessage:
      r"""Members can't be declared to be both 'covariant' and 'static'.""",
  correctionMessage:
      r"""Try removing either the 'covariant' or 'static' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeCovariantMember = messageCovariantMember;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCovariantMember = const MessageCode(
  "CovariantMember",
  index: 67,
  problemMessage:
      r"""Getters, setters and methods can't be declared to be 'covariant'.""",
  correctionMessage: r"""Try removing the 'covariant' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String string)>
    templateCycleInTypeParameters =
    const Template<Message Function(String name, String string)>(
  "CycleInTypeParameters",
  problemMessageTemplate:
      r"""Type '#name' is a bound of itself via '#string'.""",
  correctionMessageTemplate:
      r"""Try breaking the cycle by removing at least one of the 'extends' clauses in the cycle.""",
  withArguments: _withArgumentsCycleInTypeParameters,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeCycleInTypeParameters = const Code(
  "CycleInTypeParameters",
  analyzerCodes: <String>["TYPE_PARAMETER_SUPERTYPE_OF_ITS_BOUND"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCycleInTypeParameters(String name, String string) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (string.isEmpty) throw 'No string provided';
  return new Message(
    codeCycleInTypeParameters,
    problemMessage: """Type '${name}' is a bound of itself via '${string}'.""",
    correctionMessage:
        """Try breaking the cycle by removing at least one of the 'extends' clauses in the cycle.""",
    arguments: {
      'name': name,
      'string': string,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateCyclicClassHierarchy =
    const Template<Message Function(String name)>(
  "CyclicClassHierarchy",
  problemMessageTemplate: r"""'#name' is a supertype of itself.""",
  withArguments: _withArgumentsCyclicClassHierarchy,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeCyclicClassHierarchy = const Code(
  "CyclicClassHierarchy",
  analyzerCodes: <String>["RECURSIVE_INTERFACE_INHERITANCE"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCyclicClassHierarchy(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeCyclicClassHierarchy,
    problemMessage: """'${name}' is a supertype of itself.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateCyclicRedirectingFactoryConstructors =
    const Template<Message Function(String name)>(
  "CyclicRedirectingFactoryConstructors",
  problemMessageTemplate: r"""Cyclic definition of factory '#name'.""",
  withArguments: _withArgumentsCyclicRedirectingFactoryConstructors,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeCyclicRedirectingFactoryConstructors = const Code(
  "CyclicRedirectingFactoryConstructors",
  analyzerCodes: <String>["RECURSIVE_FACTORY_REDIRECT"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCyclicRedirectingFactoryConstructors(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeCyclicRedirectingFactoryConstructors,
    problemMessage: """Cyclic definition of factory '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeCyclicRepresentationDependency =
    messageCyclicRepresentationDependency;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCyclicRepresentationDependency = const MessageCode(
  "CyclicRepresentationDependency",
  problemMessage:
      r"""An extension type can't depend on itself through its representation type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateCyclicTypedef =
    const Template<Message Function(String name)>(
  "CyclicTypedef",
  problemMessageTemplate: r"""The typedef '#name' has a reference to itself.""",
  withArguments: _withArgumentsCyclicTypedef,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeCyclicTypedef = const Code(
  "CyclicTypedef",
  analyzerCodes: <String>["TYPE_ALIAS_CANNOT_REFERENCE_ITSELF"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCyclicTypedef(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeCyclicTypedef,
    problemMessage: """The typedef '${name}' has a reference to itself.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeDartFfiLibraryInDart2Wasm = messageDartFfiLibraryInDart2Wasm;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageDartFfiLibraryInDart2Wasm = const MessageCode(
  "DartFfiLibraryInDart2Wasm",
  problemMessage: r"""'dart:ffi' can't be imported when compiling to Wasm.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String string)>
    templateDebugTrace =
    const Template<Message Function(String name, String string)>(
  "DebugTrace",
  problemMessageTemplate: r"""Fatal '#name' at:
#string""",
  withArguments: _withArgumentsDebugTrace,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeDebugTrace = const Code(
  "DebugTrace",
  severity: Severity.ignored,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDebugTrace(String name, String string) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (string.isEmpty) throw 'No string provided';
  return new Message(
    codeDebugTrace,
    problemMessage: """Fatal '${name}' at:
${string}""",
    arguments: {
      'name': name,
      'string': string,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateDeclarationConflictsWithSetter =
    const Template<Message Function(String name)>(
  "DeclarationConflictsWithSetter",
  problemMessageTemplate: r"""The declaration conflicts with setter '#name'.""",
  withArguments: _withArgumentsDeclarationConflictsWithSetter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeDeclarationConflictsWithSetter = const Code(
  "DeclarationConflictsWithSetter",
  analyzerCodes: <String>["CONFLICTS_WITH_MEMBER"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDeclarationConflictsWithSetter(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeDeclarationConflictsWithSetter,
    problemMessage: """The declaration conflicts with setter '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateDeclarationConflictsWithSetterCause =
    const Template<Message Function(String name)>(
  "DeclarationConflictsWithSetterCause",
  problemMessageTemplate: r"""Conflicting setter '#name'.""",
  withArguments: _withArgumentsDeclarationConflictsWithSetterCause,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeDeclarationConflictsWithSetterCause = const Code(
  "DeclarationConflictsWithSetterCause",
  severity: Severity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDeclarationConflictsWithSetterCause(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeDeclarationConflictsWithSetterCause,
    problemMessage: """Conflicting setter '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeDeclaredMemberConflictsWithInheritedMember =
    messageDeclaredMemberConflictsWithInheritedMember;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageDeclaredMemberConflictsWithInheritedMember =
    const MessageCode(
  "DeclaredMemberConflictsWithInheritedMember",
  analyzerCodes: <String>["DECLARED_MEMBER_CONFLICTS_WITH_INHERITED"],
  problemMessage:
      r"""Can't declare a member that conflicts with an inherited one.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeDeclaredMemberConflictsWithInheritedMemberCause =
    messageDeclaredMemberConflictsWithInheritedMemberCause;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageDeclaredMemberConflictsWithInheritedMemberCause =
    const MessageCode(
  "DeclaredMemberConflictsWithInheritedMemberCause",
  severity: Severity.context,
  problemMessage: r"""This is the inherited member.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeDeclaredMemberConflictsWithInheritedMembersCause =
    messageDeclaredMemberConflictsWithInheritedMembersCause;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageDeclaredMemberConflictsWithInheritedMembersCause =
    const MessageCode(
  "DeclaredMemberConflictsWithInheritedMembersCause",
  severity: Severity.context,
  problemMessage: r"""This is one of the inherited members.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeDeclaredMemberConflictsWithOverriddenMembersCause =
    messageDeclaredMemberConflictsWithOverriddenMembersCause;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageDeclaredMemberConflictsWithOverriddenMembersCause =
    const MessageCode(
  "DeclaredMemberConflictsWithOverriddenMembersCause",
  severity: Severity.context,
  problemMessage: r"""This is one of the overridden members.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeDefaultInSwitchExpression = messageDefaultInSwitchExpression;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageDefaultInSwitchExpression = const MessageCode(
  "DefaultInSwitchExpression",
  index: 153,
  problemMessage: r"""A switch expression may not use the `default` keyword.""",
  correctionMessage: r"""Try replacing `default` with `_`.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateDefaultValueInRedirectingFactoryConstructor =
    const Template<Message Function(String name)>(
  "DefaultValueInRedirectingFactoryConstructor",
  problemMessageTemplate:
      r"""Can't have a default value here because any default values of '#name' would be used instead.""",
  correctionMessageTemplate: r"""Try removing the default value.""",
  withArguments: _withArgumentsDefaultValueInRedirectingFactoryConstructor,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeDefaultValueInRedirectingFactoryConstructor = const Code(
  "DefaultValueInRedirectingFactoryConstructor",
  analyzerCodes: <String>["DEFAULT_VALUE_IN_REDIRECTING_FACTORY_CONSTRUCTOR"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDefaultValueInRedirectingFactoryConstructor(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeDefaultValueInRedirectingFactoryConstructor,
    problemMessage:
        """Can't have a default value here because any default values of '${name}' would be used instead.""",
    correctionMessage: """Try removing the default value.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeDeferredAfterPrefix = messageDeferredAfterPrefix;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageDeferredAfterPrefix = const MessageCode(
  "DeferredAfterPrefix",
  index: 68,
  problemMessage:
      r"""The deferred keyword should come immediately before the prefix ('as' clause).""",
  correctionMessage: r"""Try moving the deferred keyword before the prefix.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateDeferredExtensionImport =
    const Template<Message Function(String name)>(
  "DeferredExtensionImport",
  problemMessageTemplate:
      r"""Extension '#name' cannot be imported through a deferred import.""",
  correctionMessageTemplate: r"""Try adding the `hide #name` to the import.""",
  withArguments: _withArgumentsDeferredExtensionImport,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeDeferredExtensionImport = const Code(
  "DeferredExtensionImport",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDeferredExtensionImport(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeDeferredExtensionImport,
    problemMessage:
        """Extension '${name}' cannot be imported through a deferred import.""",
    correctionMessage: """Try adding the `hide ${name}` to the import.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateDeferredPrefixDuplicated =
    const Template<Message Function(String name)>(
  "DeferredPrefixDuplicated",
  problemMessageTemplate:
      r"""Can't use the name '#name' for a deferred library, as the name is used elsewhere.""",
  withArguments: _withArgumentsDeferredPrefixDuplicated,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeDeferredPrefixDuplicated = const Code(
  "DeferredPrefixDuplicated",
  analyzerCodes: <String>["SHARED_DEFERRED_PREFIX"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDeferredPrefixDuplicated(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeDeferredPrefixDuplicated,
    problemMessage:
        """Can't use the name '${name}' for a deferred library, as the name is used elsewhere.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateDeferredPrefixDuplicatedCause =
    const Template<Message Function(String name)>(
  "DeferredPrefixDuplicatedCause",
  problemMessageTemplate: r"""'#name' is used here.""",
  withArguments: _withArgumentsDeferredPrefixDuplicatedCause,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeDeferredPrefixDuplicatedCause = const Code(
  "DeferredPrefixDuplicatedCause",
  severity: Severity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDeferredPrefixDuplicatedCause(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeDeferredPrefixDuplicatedCause,
    problemMessage: """'${name}' is used here.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(int count, int count2, num _num1, num _num2,
        num _num3)> templateDillOutlineSummary = const Template<
    Message Function(int count, int count2, num _num1, num _num2, num _num3)>(
  "DillOutlineSummary",
  problemMessageTemplate:
      r"""Indexed #count libraries (#count2 bytes) in #num1%.3ms, that is,
#num2%12.3 bytes/ms, and
#num3%12.3 ms/libraries.""",
  withArguments: _withArgumentsDillOutlineSummary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeDillOutlineSummary = const Code(
  "DillOutlineSummary",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDillOutlineSummary(
    int count, int count2, num _num1, num _num2, num _num3) {
  String num1 = _num1.toStringAsFixed(3);
  String num2 = _num2.toStringAsFixed(3).padLeft(12);
  String num3 = _num3.toStringAsFixed(3).padLeft(12);
  return new Message(
    codeDillOutlineSummary,
    problemMessage:
        """Indexed ${count} libraries (${count2} bytes) in ${num1}ms, that is,
${num2} bytes/ms, and
${num3} ms/libraries.""",
    arguments: {
      'count': count,
      'count2': count2,
      'num1': _num1,
      'num2': _num2,
      'num3': _num3,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateDirectCycleInTypeParameters =
    const Template<Message Function(String name)>(
  "DirectCycleInTypeParameters",
  problemMessageTemplate: r"""Type '#name' can't use itself as a bound.""",
  correctionMessageTemplate:
      r"""Try breaking the cycle by removing at least one of the 'extends' clauses in the cycle.""",
  withArguments: _withArgumentsDirectCycleInTypeParameters,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeDirectCycleInTypeParameters = const Code(
  "DirectCycleInTypeParameters",
  analyzerCodes: <String>["TYPE_PARAMETER_SUPERTYPE_OF_ITS_BOUND"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDirectCycleInTypeParameters(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeDirectCycleInTypeParameters,
    problemMessage: """Type '${name}' can't use itself as a bound.""",
    correctionMessage:
        """Try breaking the cycle by removing at least one of the 'extends' clauses in the cycle.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeDirectiveAfterDeclaration = messageDirectiveAfterDeclaration;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageDirectiveAfterDeclaration = const MessageCode(
  "DirectiveAfterDeclaration",
  index: 69,
  problemMessage: r"""Directives must appear before any declarations.""",
  correctionMessage: r"""Try moving the directive before any declarations.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeDotShorthandsConstructorInvocationWithTypeArguments =
    messageDotShorthandsConstructorInvocationWithTypeArguments;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageDotShorthandsConstructorInvocationWithTypeArguments =
    const MessageCode(
  "DotShorthandsConstructorInvocationWithTypeArguments",
  problemMessage:
      r"""A dot shorthand constructor invocation can't have type arguments.""",
  correctionMessage:
      r"""Try adding the class name and type arguments explicitly before the constructor name.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateDotShorthandsInvalidContext =
    const Template<Message Function(String name)>(
  "DotShorthandsInvalidContext",
  problemMessageTemplate:
      r"""No type was provided to find the dot shorthand '#name'.""",
  withArguments: _withArgumentsDotShorthandsInvalidContext,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeDotShorthandsInvalidContext = const Code(
  "DotShorthandsInvalidContext",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDotShorthandsInvalidContext(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeDotShorthandsInvalidContext,
    problemMessage:
        """No type was provided to find the dot shorthand '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeDuplicateDeferred = messageDuplicateDeferred;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageDuplicateDeferred = const MessageCode(
  "DuplicateDeferred",
  index: 71,
  problemMessage:
      r"""An import directive can only have one 'deferred' keyword.""",
  correctionMessage: r"""Try removing all but one 'deferred' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateDuplicateLabelInSwitchStatement =
    const Template<Message Function(String name)>(
  "DuplicateLabelInSwitchStatement",
  problemMessageTemplate:
      r"""The label '#name' was already used in this switch statement.""",
  correctionMessageTemplate:
      r"""Try choosing a different name for this label.""",
  withArguments: _withArgumentsDuplicateLabelInSwitchStatement,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeDuplicateLabelInSwitchStatement = const Code(
  "DuplicateLabelInSwitchStatement",
  index: 72,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicateLabelInSwitchStatement(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeDuplicateLabelInSwitchStatement,
    problemMessage:
        """The label '${name}' was already used in this switch statement.""",
    correctionMessage: """Try choosing a different name for this label.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateDuplicatePatternAssignmentVariable =
    const Template<Message Function(String name)>(
  "DuplicatePatternAssignmentVariable",
  problemMessageTemplate:
      r"""The variable '#name' is already assigned in this pattern.""",
  correctionMessageTemplate: r"""Try renaming the variable.""",
  withArguments: _withArgumentsDuplicatePatternAssignmentVariable,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeDuplicatePatternAssignmentVariable = const Code(
  "DuplicatePatternAssignmentVariable",
  analyzerCodes: <String>["DUPLICATE_PATTERN_ASSIGNMENT_VARIABLE"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatePatternAssignmentVariable(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeDuplicatePatternAssignmentVariable,
    problemMessage:
        """The variable '${name}' is already assigned in this pattern.""",
    correctionMessage: """Try renaming the variable.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeDuplicatePatternAssignmentVariableContext =
    messageDuplicatePatternAssignmentVariableContext;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageDuplicatePatternAssignmentVariableContext =
    const MessageCode(
  "DuplicatePatternAssignmentVariableContext",
  severity: Severity.context,
  problemMessage: r"""The first assigned variable pattern.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeDuplicatePrefix = messageDuplicatePrefix;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageDuplicatePrefix = const MessageCode(
  "DuplicatePrefix",
  index: 73,
  problemMessage:
      r"""An import directive can only have one prefix ('as' clause).""",
  correctionMessage: r"""Try removing all but one prefix.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateDuplicateRecordPatternField =
    const Template<Message Function(String name)>(
  "DuplicateRecordPatternField",
  problemMessageTemplate:
      r"""The field '#name' is already matched in this pattern.""",
  correctionMessageTemplate: r"""Try removing the duplicate field.""",
  withArguments: _withArgumentsDuplicateRecordPatternField,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeDuplicateRecordPatternField = const Code(
  "DuplicateRecordPatternField",
  analyzerCodes: <String>["DUPLICATE_RECORD_PATTERN_FIELD"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicateRecordPatternField(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeDuplicateRecordPatternField,
    problemMessage:
        """The field '${name}' is already matched in this pattern.""",
    correctionMessage: """Try removing the duplicate field.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeDuplicateRecordPatternFieldContext =
    messageDuplicateRecordPatternFieldContext;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageDuplicateRecordPatternFieldContext = const MessageCode(
  "DuplicateRecordPatternFieldContext",
  severity: Severity.context,
  problemMessage: r"""The first field.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeDuplicateRestElementInPattern =
    messageDuplicateRestElementInPattern;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageDuplicateRestElementInPattern = const MessageCode(
  "DuplicateRestElementInPattern",
  analyzerCodes: <String>["DUPLICATE_REST_ELEMENT_IN_PATTERN"],
  problemMessage:
      r"""At most one rest element is allowed in a list or map pattern.""",
  correctionMessage: r"""Try removing the duplicate rest element.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeDuplicateRestElementInPatternContext =
    messageDuplicateRestElementInPatternContext;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageDuplicateRestElementInPatternContext =
    const MessageCode(
  "DuplicateRestElementInPatternContext",
  severity: Severity.context,
  problemMessage: r"""The first rest element.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateDuplicatedDeclaration =
    const Template<Message Function(String name)>(
  "DuplicatedDeclaration",
  problemMessageTemplate: r"""'#name' is already declared in this scope.""",
  withArguments: _withArgumentsDuplicatedDeclaration,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeDuplicatedDeclaration = const Code(
  "DuplicatedDeclaration",
  analyzerCodes: <String>["DUPLICATE_DEFINITION"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedDeclaration(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeDuplicatedDeclaration,
    problemMessage: """'${name}' is already declared in this scope.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateDuplicatedDeclarationCause =
    const Template<Message Function(String name)>(
  "DuplicatedDeclarationCause",
  problemMessageTemplate: r"""Previous declaration of '#name'.""",
  withArguments: _withArgumentsDuplicatedDeclarationCause,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeDuplicatedDeclarationCause = const Code(
  "DuplicatedDeclarationCause",
  severity: Severity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedDeclarationCause(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeDuplicatedDeclarationCause,
    problemMessage: """Previous declaration of '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateDuplicatedDeclarationSyntheticCause =
    const Template<Message Function(String name)>(
  "DuplicatedDeclarationSyntheticCause",
  problemMessageTemplate:
      r"""Previous declaration of '#name' is implied by this definition.""",
  withArguments: _withArgumentsDuplicatedDeclarationSyntheticCause,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeDuplicatedDeclarationSyntheticCause = const Code(
  "DuplicatedDeclarationSyntheticCause",
  severity: Severity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedDeclarationSyntheticCause(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeDuplicatedDeclarationSyntheticCause,
    problemMessage:
        """Previous declaration of '${name}' is implied by this definition.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateDuplicatedDeclarationUse =
    const Template<Message Function(String name)>(
  "DuplicatedDeclarationUse",
  problemMessageTemplate:
      r"""Can't use '#name' because it is declared more than once.""",
  withArguments: _withArgumentsDuplicatedDeclarationUse,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeDuplicatedDeclarationUse = const Code(
  "DuplicatedDeclarationUse",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedDeclarationUse(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeDuplicatedDeclarationUse,
    problemMessage:
        """Can't use '${name}' because it is declared more than once.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, Uri uri_, Uri uri2_)>
    templateDuplicatedExport =
    const Template<Message Function(String name, Uri uri_, Uri uri2_)>(
  "DuplicatedExport",
  problemMessageTemplate:
      r"""'#name' is exported from both '#uri' and '#uri2'.""",
  withArguments: _withArgumentsDuplicatedExport,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeDuplicatedExport = const Code(
  "DuplicatedExport",
  analyzerCodes: <String>["AMBIGUOUS_EXPORT"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedExport(String name, Uri uri_, Uri uri2_) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  String? uri = relativizeUri(uri_);
  String? uri2 = relativizeUri(uri2_);
  return new Message(
    codeDuplicatedExport,
    problemMessage:
        """'${name}' is exported from both '${uri}' and '${uri2}'.""",
    arguments: {
      'name': name,
      'uri': uri_,
      'uri2': uri2_,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, Uri uri_, Uri uri2_)>
    templateDuplicatedImport =
    const Template<Message Function(String name, Uri uri_, Uri uri2_)>(
  "DuplicatedImport",
  problemMessageTemplate:
      r"""'#name' is imported from both '#uri' and '#uri2'.""",
  withArguments: _withArgumentsDuplicatedImport,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeDuplicatedImport = const Code(
  "DuplicatedImport",
  analyzerCodes: <String>["AMBIGUOUS_IMPORT"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedImport(String name, Uri uri_, Uri uri2_) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  String? uri = relativizeUri(uri_);
  String? uri2 = relativizeUri(uri2_);
  return new Message(
    codeDuplicatedImport,
    problemMessage:
        """'${name}' is imported from both '${uri}' and '${uri2}'.""",
    arguments: {
      'name': name,
      'uri': uri_,
      'uri2': uri2_,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateDuplicatedModifier =
    const Template<Message Function(Token token)>(
  "DuplicatedModifier",
  problemMessageTemplate: r"""The modifier '#lexeme' was already specified.""",
  correctionMessageTemplate:
      r"""Try removing all but one occurrence of the modifier.""",
  withArguments: _withArgumentsDuplicatedModifier,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeDuplicatedModifier = const Code(
  "DuplicatedModifier",
  index: 70,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedModifier(Token token) {
  String lexeme = token.lexeme;
  return new Message(
    codeDuplicatedModifier,
    problemMessage: """The modifier '${lexeme}' was already specified.""",
    correctionMessage:
        """Try removing all but one occurrence of the modifier.""",
    arguments: {
      'lexeme': token,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateDuplicatedNamedArgument =
    const Template<Message Function(String name)>(
  "DuplicatedNamedArgument",
  problemMessageTemplate: r"""Duplicated named argument '#name'.""",
  withArguments: _withArgumentsDuplicatedNamedArgument,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeDuplicatedNamedArgument = const Code(
  "DuplicatedNamedArgument",
  analyzerCodes: <String>["DUPLICATE_NAMED_ARGUMENT"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedNamedArgument(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeDuplicatedNamedArgument,
    problemMessage: """Duplicated named argument '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateDuplicatedParameterName =
    const Template<Message Function(String name)>(
  "DuplicatedParameterName",
  problemMessageTemplate: r"""Duplicated parameter name '#name'.""",
  withArguments: _withArgumentsDuplicatedParameterName,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeDuplicatedParameterName = const Code(
  "DuplicatedParameterName",
  analyzerCodes: <String>["DUPLICATE_DEFINITION"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedParameterName(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeDuplicatedParameterName,
    problemMessage: """Duplicated parameter name '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateDuplicatedParameterNameCause =
    const Template<Message Function(String name)>(
  "DuplicatedParameterNameCause",
  problemMessageTemplate: r"""Other parameter named '#name'.""",
  withArguments: _withArgumentsDuplicatedParameterNameCause,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeDuplicatedParameterNameCause = const Code(
  "DuplicatedParameterNameCause",
  severity: Severity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedParameterNameCause(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeDuplicatedParameterNameCause,
    problemMessage: """Other parameter named '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateDuplicatedRecordLiteralFieldName =
    const Template<Message Function(String name)>(
  "DuplicatedRecordLiteralFieldName",
  problemMessageTemplate: r"""Duplicated record literal field name '#name'.""",
  correctionMessageTemplate:
      r"""Try renaming or removing one of the named record literal fields.""",
  withArguments: _withArgumentsDuplicatedRecordLiteralFieldName,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeDuplicatedRecordLiteralFieldName = const Code(
  "DuplicatedRecordLiteralFieldName",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedRecordLiteralFieldName(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeDuplicatedRecordLiteralFieldName,
    problemMessage: """Duplicated record literal field name '${name}'.""",
    correctionMessage:
        """Try renaming or removing one of the named record literal fields.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateDuplicatedRecordLiteralFieldNameContext =
    const Template<Message Function(String name)>(
  "DuplicatedRecordLiteralFieldNameContext",
  problemMessageTemplate:
      r"""This is the existing record literal field named '#name'.""",
  withArguments: _withArgumentsDuplicatedRecordLiteralFieldNameContext,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeDuplicatedRecordLiteralFieldNameContext = const Code(
  "DuplicatedRecordLiteralFieldNameContext",
  severity: Severity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedRecordLiteralFieldNameContext(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeDuplicatedRecordLiteralFieldNameContext,
    problemMessage:
        """This is the existing record literal field named '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateDuplicatedRecordTypeFieldName =
    const Template<Message Function(String name)>(
  "DuplicatedRecordTypeFieldName",
  problemMessageTemplate: r"""Duplicated record type field name '#name'.""",
  correctionMessageTemplate:
      r"""Try renaming or removing one of the named record type fields.""",
  withArguments: _withArgumentsDuplicatedRecordTypeFieldName,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeDuplicatedRecordTypeFieldName = const Code(
  "DuplicatedRecordTypeFieldName",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedRecordTypeFieldName(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeDuplicatedRecordTypeFieldName,
    problemMessage: """Duplicated record type field name '${name}'.""",
    correctionMessage:
        """Try renaming or removing one of the named record type fields.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateDuplicatedRecordTypeFieldNameContext =
    const Template<Message Function(String name)>(
  "DuplicatedRecordTypeFieldNameContext",
  problemMessageTemplate:
      r"""This is the existing record type field named '#name'.""",
  withArguments: _withArgumentsDuplicatedRecordTypeFieldNameContext,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeDuplicatedRecordTypeFieldNameContext = const Code(
  "DuplicatedRecordTypeFieldNameContext",
  severity: Severity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedRecordTypeFieldNameContext(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeDuplicatedRecordTypeFieldNameContext,
    problemMessage:
        """This is the existing record type field named '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeDynamicCallsAreNotAllowedInDynamicModule =
    messageDynamicCallsAreNotAllowedInDynamicModule;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageDynamicCallsAreNotAllowedInDynamicModule =
    const MessageCode(
  "DynamicCallsAreNotAllowedInDynamicModule",
  problemMessage: r"""Dynamic calls are not allowed in a dynamic module.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeEmptyMapPattern = messageEmptyMapPattern;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageEmptyMapPattern = const MessageCode(
  "EmptyMapPattern",
  analyzerCodes: <String>["EMPTY_MAP_PATTERN"],
  problemMessage: r"""A map pattern must have at least one entry.""",
  correctionMessage: r"""Try replacing it with an object pattern 'Map()'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeEmptyNamedParameterList = messageEmptyNamedParameterList;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageEmptyNamedParameterList = const MessageCode(
  "EmptyNamedParameterList",
  analyzerCodes: <String>["MISSING_IDENTIFIER"],
  problemMessage: r"""Named parameter lists cannot be empty.""",
  correctionMessage: r"""Try adding a named parameter to the list.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeEmptyOptionalParameterList = messageEmptyOptionalParameterList;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageEmptyOptionalParameterList = const MessageCode(
  "EmptyOptionalParameterList",
  analyzerCodes: <String>["MISSING_IDENTIFIER"],
  problemMessage: r"""Optional parameter lists cannot be empty.""",
  correctionMessage: r"""Try adding an optional parameter to the list.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeEmptyRecordTypeNamedFieldsList =
    messageEmptyRecordTypeNamedFieldsList;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageEmptyRecordTypeNamedFieldsList = const MessageCode(
  "EmptyRecordTypeNamedFieldsList",
  index: 129,
  problemMessage:
      r"""The list of named fields in a record type can't be empty.""",
  correctionMessage: r"""Try adding a named field to the list.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeEncoding = messageEncoding;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageEncoding = const MessageCode(
  "Encoding",
  problemMessage: r"""Unable to decode bytes as UTF-8.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeEnumAbstractMember = messageEnumAbstractMember;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageEnumAbstractMember = const MessageCode(
  "EnumAbstractMember",
  problemMessage: r"""Enums can't declare abstract members.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateEnumConstantSameNameAsEnclosing =
    const Template<Message Function(String name)>(
  "EnumConstantSameNameAsEnclosing",
  problemMessageTemplate:
      r"""Name of enum constant '#name' can't be the same as the enum's own name.""",
  withArguments: _withArgumentsEnumConstantSameNameAsEnclosing,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeEnumConstantSameNameAsEnclosing = const Code(
  "EnumConstantSameNameAsEnclosing",
  analyzerCodes: <String>["ENUM_CONSTANT_WITH_ENUM_NAME"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsEnumConstantSameNameAsEnclosing(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeEnumConstantSameNameAsEnclosing,
    problemMessage:
        """Name of enum constant '${name}' can't be the same as the enum's own name.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeEnumConstructorSuperInitializer =
    messageEnumConstructorSuperInitializer;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageEnumConstructorSuperInitializer = const MessageCode(
  "EnumConstructorSuperInitializer",
  problemMessage: r"""Enum constructors can't contain super-initializers.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeEnumConstructorTearoff = messageEnumConstructorTearoff;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageEnumConstructorTearoff = const MessageCode(
  "EnumConstructorTearoff",
  problemMessage: r"""Enum constructors can't be torn off.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateEnumContainsRestrictedInstanceDeclaration =
    const Template<Message Function(String name)>(
  "EnumContainsRestrictedInstanceDeclaration",
  problemMessageTemplate:
      r"""An enum can't declare a non-abstract member named '#name'.""",
  withArguments: _withArgumentsEnumContainsRestrictedInstanceDeclaration,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeEnumContainsRestrictedInstanceDeclaration = const Code(
  "EnumContainsRestrictedInstanceDeclaration",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsEnumContainsRestrictedInstanceDeclaration(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeEnumContainsRestrictedInstanceDeclaration,
    problemMessage:
        """An enum can't declare a non-abstract member named '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeEnumContainsValuesDeclaration =
    messageEnumContainsValuesDeclaration;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageEnumContainsValuesDeclaration = const MessageCode(
  "EnumContainsValuesDeclaration",
  problemMessage: r"""An enum can't declare a member named 'values'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeEnumDeclarationEmpty = messageEnumDeclarationEmpty;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageEnumDeclarationEmpty = const MessageCode(
  "EnumDeclarationEmpty",
  analyzerCodes: <String>["EMPTY_ENUM_BODY"],
  problemMessage: r"""An enum declaration can't be empty.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeEnumDeclaresConstFactory = messageEnumDeclaresConstFactory;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageEnumDeclaresConstFactory = const MessageCode(
  "EnumDeclaresConstFactory",
  problemMessage: r"""Enums can't declare const factory constructors.""",
  correctionMessage: r"""Try removing the factory constructor declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeEnumFactoryRedirectsToConstructor =
    messageEnumFactoryRedirectsToConstructor;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageEnumFactoryRedirectsToConstructor = const MessageCode(
  "EnumFactoryRedirectsToConstructor",
  problemMessage:
      r"""Enum factory constructors can't redirect to generative constructors.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String name2)>
    templateEnumImplementerContainsRestrictedInstanceDeclaration =
    const Template<Message Function(String name, String name2)>(
  "EnumImplementerContainsRestrictedInstanceDeclaration",
  problemMessageTemplate:
      r"""'#name' has 'Enum' as a superinterface and can't contain non-static members with name '#name2'.""",
  withArguments:
      _withArgumentsEnumImplementerContainsRestrictedInstanceDeclaration,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeEnumImplementerContainsRestrictedInstanceDeclaration =
    const Code(
  "EnumImplementerContainsRestrictedInstanceDeclaration",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsEnumImplementerContainsRestrictedInstanceDeclaration(
    String name, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(
    codeEnumImplementerContainsRestrictedInstanceDeclaration,
    problemMessage:
        """'${name}' has 'Enum' as a superinterface and can't contain non-static members with name '${name2}'.""",
    arguments: {
      'name': name,
      'name2': name2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateEnumImplementerContainsValuesDeclaration =
    const Template<Message Function(String name)>(
  "EnumImplementerContainsValuesDeclaration",
  problemMessageTemplate:
      r"""'#name' has 'Enum' as a superinterface and can't contain non-static member with name 'values'.""",
  withArguments: _withArgumentsEnumImplementerContainsValuesDeclaration,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeEnumImplementerContainsValuesDeclaration = const Code(
  "EnumImplementerContainsValuesDeclaration",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsEnumImplementerContainsValuesDeclaration(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeEnumImplementerContainsValuesDeclaration,
    problemMessage:
        """'${name}' has 'Enum' as a superinterface and can't contain non-static member with name 'values'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeEnumInClass = messageEnumInClass;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageEnumInClass = const MessageCode(
  "EnumInClass",
  index: 74,
  problemMessage: r"""Enums can't be declared inside classes.""",
  correctionMessage: r"""Try moving the enum to the top-level.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateEnumInheritsRestricted =
    const Template<Message Function(String name)>(
  "EnumInheritsRestricted",
  problemMessageTemplate: r"""An enum can't inherit a member named '#name'.""",
  withArguments: _withArgumentsEnumInheritsRestricted,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeEnumInheritsRestricted = const Code(
  "EnumInheritsRestricted",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsEnumInheritsRestricted(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeEnumInheritsRestricted,
    problemMessage: """An enum can't inherit a member named '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeEnumInheritsRestrictedMember =
    messageEnumInheritsRestrictedMember;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageEnumInheritsRestrictedMember = const MessageCode(
  "EnumInheritsRestrictedMember",
  severity: Severity.context,
  problemMessage: r"""This is the inherited member""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeEnumInstantiation = messageEnumInstantiation;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageEnumInstantiation = const MessageCode(
  "EnumInstantiation",
  analyzerCodes: <String>["INSTANTIATE_ENUM"],
  problemMessage: r"""Enums can't be instantiated.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeEnumNonConstConstructor = messageEnumNonConstConstructor;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageEnumNonConstConstructor = const MessageCode(
  "EnumNonConstConstructor",
  problemMessage:
      r"""Generative enum constructors must be marked as 'const'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateEnumSupertypeOfNonAbstractClass =
    const Template<Message Function(String name)>(
  "EnumSupertypeOfNonAbstractClass",
  problemMessageTemplate:
      r"""Non-abstract class '#name' has 'Enum' as a superinterface.""",
  withArguments: _withArgumentsEnumSupertypeOfNonAbstractClass,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeEnumSupertypeOfNonAbstractClass = const Code(
  "EnumSupertypeOfNonAbstractClass",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsEnumSupertypeOfNonAbstractClass(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeEnumSupertypeOfNonAbstractClass,
    problemMessage:
        """Non-abstract class '${name}' has 'Enum' as a superinterface.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeEnumWithNameValues = messageEnumWithNameValues;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageEnumWithNameValues = const MessageCode(
  "EnumWithNameValues",
  analyzerCodes: <String>["ENUM_WITH_NAME_VALUES"],
  problemMessage:
      r"""The name 'values' is not a valid name for an enum. Try using a different name.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeEqualKeysInMapPattern = messageEqualKeysInMapPattern;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageEqualKeysInMapPattern = const MessageCode(
  "EqualKeysInMapPattern",
  analyzerCodes: <String>["EQUAL_KEYS_IN_MAP_PATTERN"],
  problemMessage: r"""Two keys in a map pattern can't be equal.""",
  correctionMessage: r"""Change or remove the duplicate key.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeEqualKeysInMapPatternContext =
    messageEqualKeysInMapPatternContext;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageEqualKeysInMapPatternContext = const MessageCode(
  "EqualKeysInMapPatternContext",
  severity: Severity.context,
  problemMessage: r"""This is the previous use of the same key.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeEqualityCannotBeEqualityOperand =
    messageEqualityCannotBeEqualityOperand;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageEqualityCannotBeEqualityOperand = const MessageCode(
  "EqualityCannotBeEqualityOperand",
  index: 1,
  problemMessage:
      r"""A comparison expression can't be an operand of another comparison expression.""",
  correctionMessage:
      r"""Try putting parentheses around one of the comparisons.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri_, String string)>
    templateExceptionReadingFile =
    const Template<Message Function(Uri uri_, String string)>(
  "ExceptionReadingFile",
  problemMessageTemplate: r"""Exception when reading '#uri': #string""",
  withArguments: _withArgumentsExceptionReadingFile,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExceptionReadingFile = const Code(
  "ExceptionReadingFile",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExceptionReadingFile(Uri uri_, String string) {
  String? uri = relativizeUri(uri_);
  if (string.isEmpty) throw 'No string provided';
  return new Message(
    codeExceptionReadingFile,
    problemMessage: """Exception when reading '${uri}': ${string}""",
    arguments: {
      'uri': uri_,
      'string': string,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)> templateExpectedAfterButGot =
    const Template<Message Function(String string)>(
  "ExpectedAfterButGot",
  problemMessageTemplate: r"""Expected '#string' after this.""",
  withArguments: _withArgumentsExpectedAfterButGot,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExpectedAfterButGot = const Code(
  "ExpectedAfterButGot",
  analyzerCodes: <String>["EXPECTED_TOKEN"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedAfterButGot(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(
    codeExpectedAfterButGot,
    problemMessage: """Expected '${string}' after this.""",
    arguments: {
      'string': string,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExpectedAnInitializer = messageExpectedAnInitializer;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedAnInitializer = const MessageCode(
  "ExpectedAnInitializer",
  index: 36,
  problemMessage: r"""Expected an initializer.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExpectedBlock = messageExpectedBlock;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedBlock = const MessageCode(
  "ExpectedBlock",
  analyzerCodes: <String>["EXPECTED_TOKEN"],
  problemMessage: r"""Expected a block.""",
  correctionMessage: r"""Try adding {}.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExpectedBlockToSkip = messageExpectedBlockToSkip;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedBlockToSkip = const MessageCode(
  "ExpectedBlockToSkip",
  analyzerCodes: <String>["MISSING_FUNCTION_BODY"],
  problemMessage: r"""Expected a function body or '=>'.""",
  correctionMessage: r"""Try adding {}.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExpectedBody = messageExpectedBody;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedBody = const MessageCode(
  "ExpectedBody",
  analyzerCodes: <String>["MISSING_FUNCTION_BODY"],
  problemMessage: r"""Expected a function body or '=>'.""",
  correctionMessage: r"""Try adding {}.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)> templateExpectedButGot =
    const Template<Message Function(String string)>(
  "ExpectedButGot",
  problemMessageTemplate: r"""Expected '#string' before this.""",
  withArguments: _withArgumentsExpectedButGot,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExpectedButGot = const Code(
  "ExpectedButGot",
  analyzerCodes: <String>["EXPECTED_TOKEN"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedButGot(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(
    codeExpectedButGot,
    problemMessage: """Expected '${string}' before this.""",
    arguments: {
      'string': string,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExpectedCatchClauseBody = messageExpectedCatchClauseBody;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedCatchClauseBody = const MessageCode(
  "ExpectedCatchClauseBody",
  index: 169,
  problemMessage: r"""A catch clause must have a body, even if it is empty.""",
  correctionMessage: r"""Try adding an empty body.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExpectedClassBody = messageExpectedClassBody;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedClassBody = const MessageCode(
  "ExpectedClassBody",
  index: 8,
  problemMessage:
      r"""A class declaration must have a body, even if it is empty.""",
  correctionMessage: r"""Try adding an empty body.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateExpectedClassMember =
    const Template<Message Function(Token token)>(
  "ExpectedClassMember",
  problemMessageTemplate: r"""Expected a class member, but got '#lexeme'.""",
  withArguments: _withArgumentsExpectedClassMember,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExpectedClassMember = const Code(
  "ExpectedClassMember",
  analyzerCodes: <String>["EXPECTED_CLASS_MEMBER"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedClassMember(Token token) {
  String lexeme = token.lexeme;
  return new Message(
    codeExpectedClassMember,
    problemMessage: """Expected a class member, but got '${lexeme}'.""",
    arguments: {
      'lexeme': token,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateExpectedDeclaration =
    const Template<Message Function(Token token)>(
  "ExpectedDeclaration",
  problemMessageTemplate: r"""Expected a declaration, but got '#lexeme'.""",
  withArguments: _withArgumentsExpectedDeclaration,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExpectedDeclaration = const Code(
  "ExpectedDeclaration",
  analyzerCodes: <String>["EXPECTED_EXECUTABLE"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedDeclaration(Token token) {
  String lexeme = token.lexeme;
  return new Message(
    codeExpectedDeclaration,
    problemMessage: """Expected a declaration, but got '${lexeme}'.""",
    arguments: {
      'lexeme': token,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExpectedElseOrComma = messageExpectedElseOrComma;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedElseOrComma = const MessageCode(
  "ExpectedElseOrComma",
  index: 46,
  problemMessage: r"""Expected 'else' or comma.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateExpectedEnumBody =
    const Template<Message Function(Token token)>(
  "ExpectedEnumBody",
  problemMessageTemplate: r"""Expected a enum body, but got '#lexeme'.""",
  correctionMessageTemplate:
      r"""An enum definition must have a body with at least one constant name.""",
  withArguments: _withArgumentsExpectedEnumBody,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExpectedEnumBody = const Code(
  "ExpectedEnumBody",
  analyzerCodes: <String>["MISSING_ENUM_BODY"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedEnumBody(Token token) {
  String lexeme = token.lexeme;
  return new Message(
    codeExpectedEnumBody,
    problemMessage: """Expected a enum body, but got '${lexeme}'.""",
    correctionMessage:
        """An enum definition must have a body with at least one constant name.""",
    arguments: {
      'lexeme': token,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExpectedExtensionBody = messageExpectedExtensionBody;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedExtensionBody = const MessageCode(
  "ExpectedExtensionBody",
  index: 173,
  problemMessage:
      r"""An extension declaration must have a body, even if it is empty.""",
  correctionMessage: r"""Try adding an empty body.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExpectedExtensionTypeBody = messageExpectedExtensionTypeBody;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedExtensionTypeBody = const MessageCode(
  "ExpectedExtensionTypeBody",
  index: 167,
  problemMessage:
      r"""An extension type declaration must have a body, even if it is empty.""",
  correctionMessage: r"""Try adding an empty body.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExpectedFinallyClauseBody = messageExpectedFinallyClauseBody;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedFinallyClauseBody = const MessageCode(
  "ExpectedFinallyClauseBody",
  index: 170,
  problemMessage:
      r"""A finally clause must have a body, even if it is empty.""",
  correctionMessage: r"""Try adding an empty body.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateExpectedFunctionBody =
    const Template<Message Function(Token token)>(
  "ExpectedFunctionBody",
  problemMessageTemplate: r"""Expected a function body, but got '#lexeme'.""",
  withArguments: _withArgumentsExpectedFunctionBody,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExpectedFunctionBody = const Code(
  "ExpectedFunctionBody",
  analyzerCodes: <String>["MISSING_FUNCTION_BODY"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedFunctionBody(Token token) {
  String lexeme = token.lexeme;
  return new Message(
    codeExpectedFunctionBody,
    problemMessage: """Expected a function body, but got '${lexeme}'.""",
    arguments: {
      'lexeme': token,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExpectedHexDigit = messageExpectedHexDigit;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedHexDigit = const MessageCode(
  "ExpectedHexDigit",
  analyzerCodes: <String>["MISSING_HEX_DIGIT"],
  problemMessage: r"""A hex digit (0-9 or A-F) must follow '0x'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateExpectedIdentifier =
    const Template<Message Function(Token token)>(
  "ExpectedIdentifier",
  problemMessageTemplate: r"""Expected an identifier, but got '#lexeme'.""",
  correctionMessageTemplate:
      r"""Try inserting an identifier before '#lexeme'.""",
  withArguments: _withArgumentsExpectedIdentifier,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExpectedIdentifier = const Code(
  "ExpectedIdentifier",
  analyzerCodes: <String>["MISSING_IDENTIFIER"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedIdentifier(Token token) {
  String lexeme = token.lexeme;
  return new Message(
    codeExpectedIdentifier,
    problemMessage: """Expected an identifier, but got '${lexeme}'.""",
    correctionMessage: """Try inserting an identifier before '${lexeme}'.""",
    arguments: {
      'lexeme': token,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)>
    templateExpectedIdentifierButGotKeyword =
    const Template<Message Function(Token token)>(
  "ExpectedIdentifierButGotKeyword",
  problemMessageTemplate:
      r"""'#lexeme' can't be used as an identifier because it's a keyword.""",
  correctionMessageTemplate:
      r"""Try renaming this to be an identifier that isn't a keyword.""",
  withArguments: _withArgumentsExpectedIdentifierButGotKeyword,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExpectedIdentifierButGotKeyword = const Code(
  "ExpectedIdentifierButGotKeyword",
  index: 113,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedIdentifierButGotKeyword(Token token) {
  String lexeme = token.lexeme;
  return new Message(
    codeExpectedIdentifierButGotKeyword,
    problemMessage:
        """'${lexeme}' can't be used as an identifier because it's a keyword.""",
    correctionMessage:
        """Try renaming this to be an identifier that isn't a keyword.""",
    arguments: {
      'lexeme': token,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)> templateExpectedInstead =
    const Template<Message Function(String string)>(
  "ExpectedInstead",
  problemMessageTemplate: r"""Expected '#string' instead of this.""",
  withArguments: _withArgumentsExpectedInstead,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExpectedInstead = const Code(
  "ExpectedInstead",
  index: 41,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedInstead(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(
    codeExpectedInstead,
    problemMessage: """Expected '${string}' instead of this.""",
    arguments: {
      'string': string,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExpectedMixinBody = messageExpectedMixinBody;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedMixinBody = const MessageCode(
  "ExpectedMixinBody",
  index: 166,
  problemMessage:
      r"""A mixin declaration must have a body, even if it is empty.""",
  correctionMessage: r"""Try adding an empty body.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExpectedNamedArgument = messageExpectedNamedArgument;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedNamedArgument = const MessageCode(
  "ExpectedNamedArgument",
  analyzerCodes: <String>["EXTRA_POSITIONAL_ARGUMENTS"],
  problemMessage: r"""Expected named argument.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExpectedOneExpression = messageExpectedOneExpression;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedOneExpression = const MessageCode(
  "ExpectedOneExpression",
  problemMessage: r"""Expected one expression, but found additional input.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExpectedOpenParens = messageExpectedOpenParens;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedOpenParens = const MessageCode(
  "ExpectedOpenParens",
  problemMessage: r"""Expected '('.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExpectedRepresentationField = messageExpectedRepresentationField;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedRepresentationField = const MessageCode(
  "ExpectedRepresentationField",
  analyzerCodes: <String>["EXPECTED_REPRESENTATION_FIELD"],
  problemMessage: r"""Expected a representation field.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExpectedRepresentationType = messageExpectedRepresentationType;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedRepresentationType = const MessageCode(
  "ExpectedRepresentationType",
  analyzerCodes: <String>["EXPECTED_REPRESENTATION_TYPE"],
  problemMessage: r"""Expected a representation type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExpectedStatement = messageExpectedStatement;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedStatement = const MessageCode(
  "ExpectedStatement",
  index: 29,
  problemMessage: r"""Expected a statement.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateExpectedString =
    const Template<Message Function(Token token)>(
  "ExpectedString",
  problemMessageTemplate: r"""Expected a String, but got '#lexeme'.""",
  withArguments: _withArgumentsExpectedString,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExpectedString = const Code(
  "ExpectedString",
  analyzerCodes: <String>["EXPECTED_STRING_LITERAL"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedString(Token token) {
  String lexeme = token.lexeme;
  return new Message(
    codeExpectedString,
    problemMessage: """Expected a String, but got '${lexeme}'.""",
    arguments: {
      'lexeme': token,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExpectedSwitchExpressionBody =
    messageExpectedSwitchExpressionBody;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedSwitchExpressionBody = const MessageCode(
  "ExpectedSwitchExpressionBody",
  index: 171,
  problemMessage:
      r"""A switch expression must have a body, even if it is empty.""",
  correctionMessage: r"""Try adding an empty body.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExpectedSwitchStatementBody = messageExpectedSwitchStatementBody;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedSwitchStatementBody = const MessageCode(
  "ExpectedSwitchStatementBody",
  index: 172,
  problemMessage:
      r"""A switch statement must have a body, even if it is empty.""",
  correctionMessage: r"""Try adding an empty body.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)> templateExpectedToken =
    const Template<Message Function(String string)>(
  "ExpectedToken",
  problemMessageTemplate: r"""Expected to find '#string'.""",
  withArguments: _withArgumentsExpectedToken,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExpectedToken = const Code(
  "ExpectedToken",
  analyzerCodes: <String>["EXPECTED_TOKEN"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedToken(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(
    codeExpectedToken,
    problemMessage: """Expected to find '${string}'.""",
    arguments: {
      'string': string,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExpectedTryStatementBody = messageExpectedTryStatementBody;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedTryStatementBody = const MessageCode(
  "ExpectedTryStatementBody",
  index: 168,
  problemMessage: r"""A try statement must have a body, even if it is empty.""",
  correctionMessage: r"""Try adding an empty body.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateExpectedType =
    const Template<Message Function(Token token)>(
  "ExpectedType",
  problemMessageTemplate: r"""Expected a type, but got '#lexeme'.""",
  withArguments: _withArgumentsExpectedType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExpectedType = const Code(
  "ExpectedType",
  analyzerCodes: <String>["EXPECTED_TYPE_NAME"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedType(Token token) {
  String lexeme = token.lexeme;
  return new Message(
    codeExpectedType,
    problemMessage: """Expected a type, but got '${lexeme}'.""",
    arguments: {
      'lexeme': token,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExpectedUri = messageExpectedUri;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedUri = const MessageCode(
  "ExpectedUri",
  problemMessage: r"""Expected a URI.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)> templateExperimentDisabled =
    const Template<Message Function(String string)>(
  "ExperimentDisabled",
  problemMessageTemplate:
      r"""This requires the '#string' language feature to be enabled.""",
  correctionMessageTemplate:
      r"""The feature is on by default but is currently disabled, maybe because the '--enable-experiment=no-#string' command line option is passed.""",
  withArguments: _withArgumentsExperimentDisabled,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExperimentDisabled = const Code(
  "ExperimentDisabled",
  analyzerCodes: <String>["ParserErrorCode.EXPERIMENT_NOT_ENABLED"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExperimentDisabled(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(
    codeExperimentDisabled,
    problemMessage:
        """This requires the '${string}' language feature to be enabled.""",
    correctionMessage:
        """The feature is on by default but is currently disabled, maybe because the '--enable-experiment=no-${string}' command line option is passed.""",
    arguments: {
      'string': string,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string, String string2)>
    templateExperimentDisabledInvalidLanguageVersion =
    const Template<Message Function(String string, String string2)>(
  "ExperimentDisabledInvalidLanguageVersion",
  problemMessageTemplate:
      r"""This requires the '#string' language feature, which requires language version of #string2 or higher.""",
  withArguments: _withArgumentsExperimentDisabledInvalidLanguageVersion,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExperimentDisabledInvalidLanguageVersion = const Code(
  "ExperimentDisabledInvalidLanguageVersion",
  analyzerCodes: <String>["ParserErrorCode.EXPERIMENT_NOT_ENABLED"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExperimentDisabledInvalidLanguageVersion(
    String string, String string2) {
  if (string.isEmpty) throw 'No string provided';
  if (string2.isEmpty) throw 'No string provided';
  return new Message(
    codeExperimentDisabledInvalidLanguageVersion,
    problemMessage:
        """This requires the '${string}' language feature, which requires language version of ${string2} or higher.""",
    arguments: {
      'string': string,
      'string2': string2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateExperimentExpiredDisabled =
    const Template<Message Function(String name)>(
  "ExperimentExpiredDisabled",
  problemMessageTemplate:
      r"""The experiment '#name' has expired and can't be disabled.""",
  withArguments: _withArgumentsExperimentExpiredDisabled,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExperimentExpiredDisabled = const Code(
  "ExperimentExpiredDisabled",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExperimentExpiredDisabled(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeExperimentExpiredDisabled,
    problemMessage:
        """The experiment '${name}' has expired and can't be disabled.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateExperimentExpiredEnabled =
    const Template<Message Function(String name)>(
  "ExperimentExpiredEnabled",
  problemMessageTemplate:
      r"""The experiment '#name' has expired and can't be enabled.""",
  withArguments: _withArgumentsExperimentExpiredEnabled,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExperimentExpiredEnabled = const Code(
  "ExperimentExpiredEnabled",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExperimentExpiredEnabled(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeExperimentExpiredEnabled,
    problemMessage:
        """The experiment '${name}' has expired and can't be enabled.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string, String string2)>
    templateExperimentNotEnabled =
    const Template<Message Function(String string, String string2)>(
  "ExperimentNotEnabled",
  problemMessageTemplate:
      r"""This requires the '#string' language feature to be enabled.""",
  correctionMessageTemplate:
      r"""Try updating your pubspec.yaml to set the minimum SDK constraint to #string2 or higher, and running 'pub get'.""",
  withArguments: _withArgumentsExperimentNotEnabled,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExperimentNotEnabled = const Code(
  "ExperimentNotEnabled",
  index: 48,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExperimentNotEnabled(String string, String string2) {
  if (string.isEmpty) throw 'No string provided';
  if (string2.isEmpty) throw 'No string provided';
  return new Message(
    codeExperimentNotEnabled,
    problemMessage:
        """This requires the '${string}' language feature to be enabled.""",
    correctionMessage:
        """Try updating your pubspec.yaml to set the minimum SDK constraint to ${string2} or higher, and running 'pub get'.""",
    arguments: {
      'string': string,
      'string2': string2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)>
    templateExperimentNotEnabledOffByDefault =
    const Template<Message Function(String string)>(
  "ExperimentNotEnabledOffByDefault",
  problemMessageTemplate:
      r"""This requires the experimental '#string' language feature to be enabled.""",
  correctionMessageTemplate:
      r"""Try passing the '--enable-experiment=#string' command line option.""",
  withArguments: _withArgumentsExperimentNotEnabledOffByDefault,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExperimentNotEnabledOffByDefault = const Code(
  "ExperimentNotEnabledOffByDefault",
  index: 133,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExperimentNotEnabledOffByDefault(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(
    codeExperimentNotEnabledOffByDefault,
    problemMessage:
        """This requires the experimental '${string}' language feature to be enabled.""",
    correctionMessage:
        """Try passing the '--enable-experiment=${string}' command line option.""",
    arguments: {
      'string': string,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)>
    templateExperimentOptOutComment =
    const Template<Message Function(String string)>(
  "ExperimentOptOutComment",
  problemMessageTemplate:
      r"""This is the annotation that opts out this library from the '#string' language feature.""",
  withArguments: _withArgumentsExperimentOptOutComment,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExperimentOptOutComment = const Code(
  "ExperimentOptOutComment",
  severity: Severity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExperimentOptOutComment(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(
    codeExperimentOptOutComment,
    problemMessage:
        """This is the annotation that opts out this library from the '${string}' language feature.""",
    arguments: {
      'string': string,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string, String string2)>
    templateExperimentOptOutExplicit =
    const Template<Message Function(String string, String string2)>(
  "ExperimentOptOutExplicit",
  problemMessageTemplate:
      r"""The '#string' language feature is disabled for this library.""",
  correctionMessageTemplate:
      r"""Try removing the `@dart=` annotation or setting the language version to #string2 or higher.""",
  withArguments: _withArgumentsExperimentOptOutExplicit,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExperimentOptOutExplicit = const Code(
  "ExperimentOptOutExplicit",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExperimentOptOutExplicit(String string, String string2) {
  if (string.isEmpty) throw 'No string provided';
  if (string2.isEmpty) throw 'No string provided';
  return new Message(
    codeExperimentOptOutExplicit,
    problemMessage:
        """The '${string}' language feature is disabled for this library.""",
    correctionMessage:
        """Try removing the `@dart=` annotation or setting the language version to ${string2} or higher.""",
    arguments: {
      'string': string,
      'string2': string2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string, String string2)>
    templateExperimentOptOutImplicit =
    const Template<Message Function(String string, String string2)>(
  "ExperimentOptOutImplicit",
  problemMessageTemplate:
      r"""The '#string' language feature is disabled for this library.""",
  correctionMessageTemplate:
      r"""Try removing the package language version or setting the language version to #string2 or higher.""",
  withArguments: _withArgumentsExperimentOptOutImplicit,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExperimentOptOutImplicit = const Code(
  "ExperimentOptOutImplicit",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExperimentOptOutImplicit(String string, String string2) {
  if (string.isEmpty) throw 'No string provided';
  if (string2.isEmpty) throw 'No string provided';
  return new Message(
    codeExperimentOptOutImplicit,
    problemMessage:
        """The '${string}' language feature is disabled for this library.""",
    correctionMessage:
        """Try removing the package language version or setting the language version to ${string2} or higher.""",
    arguments: {
      'string': string,
      'string2': string2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExplicitExtensionArgumentMismatch =
    messageExplicitExtensionArgumentMismatch;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExplicitExtensionArgumentMismatch = const MessageCode(
  "ExplicitExtensionArgumentMismatch",
  problemMessage:
      r"""Explicit extension application requires exactly 1 positional argument.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExplicitExtensionAsExpression =
    messageExplicitExtensionAsExpression;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExplicitExtensionAsExpression = const MessageCode(
  "ExplicitExtensionAsExpression",
  problemMessage:
      r"""Explicit extension application cannot be used as an expression.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExplicitExtensionAsLvalue = messageExplicitExtensionAsLvalue;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExplicitExtensionAsLvalue = const MessageCode(
  "ExplicitExtensionAsLvalue",
  problemMessage:
      r"""Explicit extension application cannot be a target for assignment.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, int count)>
    templateExplicitExtensionTypeArgumentMismatch =
    const Template<Message Function(String name, int count)>(
  "ExplicitExtensionTypeArgumentMismatch",
  problemMessageTemplate:
      r"""Explicit extension application of extension '#name' takes '#count' type argument(s).""",
  withArguments: _withArgumentsExplicitExtensionTypeArgumentMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExplicitExtensionTypeArgumentMismatch = const Code(
  "ExplicitExtensionTypeArgumentMismatch",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExplicitExtensionTypeArgumentMismatch(
    String name, int count) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeExplicitExtensionTypeArgumentMismatch,
    problemMessage:
        """Explicit extension application of extension '${name}' takes '${count}' type argument(s).""",
    arguments: {
      'name': name,
      'count': count,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExportAfterPart = messageExportAfterPart;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExportAfterPart = const MessageCode(
  "ExportAfterPart",
  index: 75,
  problemMessage: r"""Export directives must precede part directives.""",
  correctionMessage:
      r"""Try moving the export directives before the part directives.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExportedMain = messageExportedMain;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExportedMain = const MessageCode(
  "ExportedMain",
  severity: Severity.context,
  problemMessage: r"""This is exported 'main' declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExpressionNotMetadata = messageExpressionNotMetadata;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpressionNotMetadata = const MessageCode(
  "ExpressionNotMetadata",
  problemMessage:
      r"""This can't be used as an annotation; an annotation should be a reference to a compile-time constant variable, or a call to a constant constructor.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateExtendingEnum =
    const Template<Message Function(String name)>(
  "ExtendingEnum",
  problemMessageTemplate:
      r"""'#name' is an enum and can't be extended or implemented.""",
  withArguments: _withArgumentsExtendingEnum,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExtendingEnum = const Code(
  "ExtendingEnum",
  analyzerCodes: <String>["EXTENDS_ENUM"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExtendingEnum(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeExtendingEnum,
    problemMessage:
        """'${name}' is an enum and can't be extended or implemented.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateExtendingRestricted =
    const Template<Message Function(String name)>(
  "ExtendingRestricted",
  problemMessageTemplate:
      r"""'#name' is restricted and can't be extended or implemented.""",
  withArguments: _withArgumentsExtendingRestricted,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExtendingRestricted = const Code(
  "ExtendingRestricted",
  analyzerCodes: <String>["EXTENDS_DISALLOWED_CLASS"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExtendingRestricted(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeExtendingRestricted,
    problemMessage:
        """'${name}' is restricted and can't be extended or implemented.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExtendsDeferredClass = messageExtendsDeferredClass;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExtendsDeferredClass = const MessageCode(
  "ExtendsDeferredClass",
  analyzerCodes: <String>["EXTENDS_DEFERRED_CLASS"],
  problemMessage: r"""Classes can't extend deferred classes.""",
  correctionMessage:
      r"""Try specifying a different superclass, or removing the extends clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExtendsFutureOr = messageExtendsFutureOr;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExtendsFutureOr = const MessageCode(
  "ExtendsFutureOr",
  problemMessage:
      r"""The type 'FutureOr' can't be used in an 'extends' clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExtendsNever = messageExtendsNever;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExtendsNever = const MessageCode(
  "ExtendsNever",
  problemMessage: r"""The type 'Never' can't be used in an 'extends' clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExtendsVoid = messageExtendsVoid;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExtendsVoid = const MessageCode(
  "ExtendsVoid",
  problemMessage: r"""The type 'void' can't be used in an 'extends' clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExtensionAugmentationHasOnClause =
    messageExtensionAugmentationHasOnClause;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExtensionAugmentationHasOnClause = const MessageCode(
  "ExtensionAugmentationHasOnClause",
  index: 93,
  problemMessage: r"""Extension augmentations can't have 'on' clauses.""",
  correctionMessage: r"""Try removing the 'on' clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExtensionDeclaresAbstractMember =
    messageExtensionDeclaresAbstractMember;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExtensionDeclaresAbstractMember = const MessageCode(
  "ExtensionDeclaresAbstractMember",
  index: 94,
  problemMessage: r"""Extensions can't declare abstract members.""",
  correctionMessage: r"""Try providing an implementation for the member.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExtensionDeclaresConstructor =
    messageExtensionDeclaresConstructor;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExtensionDeclaresConstructor = const MessageCode(
  "ExtensionDeclaresConstructor",
  index: 92,
  problemMessage: r"""Extensions can't declare constructors.""",
  correctionMessage: r"""Try removing the constructor declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExtensionDeclaresInstanceField =
    messageExtensionDeclaresInstanceField;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExtensionDeclaresInstanceField = const MessageCode(
  "ExtensionDeclaresInstanceField",
  analyzerCodes: <String>["EXTENSION_DECLARES_INSTANCE_FIELD"],
  problemMessage: r"""Extensions can't declare instance fields""",
  correctionMessage:
      r"""Try removing the field declaration or making it a static field""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateExtensionMemberConflictsWithObjectMember =
    const Template<Message Function(String name)>(
  "ExtensionMemberConflictsWithObjectMember",
  problemMessageTemplate:
      r"""This extension member conflicts with Object member '#name'.""",
  withArguments: _withArgumentsExtensionMemberConflictsWithObjectMember,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExtensionMemberConflictsWithObjectMember = const Code(
  "ExtensionMemberConflictsWithObjectMember",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExtensionMemberConflictsWithObjectMember(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeExtensionMemberConflictsWithObjectMember,
    problemMessage:
        """This extension member conflicts with Object member '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String name2)>
    templateExtensionTypeCombinedMemberSignatureFailed =
    const Template<Message Function(String name, String name2)>(
  "ExtensionTypeCombinedMemberSignatureFailed",
  problemMessageTemplate:
      r"""Extension type '#name' inherits multiple members named '#name2' with incompatible signatures.""",
  correctionMessageTemplate:
      r"""Try adding a declaration of '#name2' to '#name'.""",
  withArguments: _withArgumentsExtensionTypeCombinedMemberSignatureFailed,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExtensionTypeCombinedMemberSignatureFailed = const Code(
  "ExtensionTypeCombinedMemberSignatureFailed",
  analyzerCodes: <String>["INCONSISTENT_INHERITANCE"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExtensionTypeCombinedMemberSignatureFailed(
    String name, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(
    codeExtensionTypeCombinedMemberSignatureFailed,
    problemMessage:
        """Extension type '${name}' inherits multiple members named '${name2}' with incompatible signatures.""",
    correctionMessage:
        """Try adding a declaration of '${name2}' to '${name}'.""",
    arguments: {
      'name': name,
      'name2': name2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExtensionTypeConstructorWithSuperFormalParameter =
    messageExtensionTypeConstructorWithSuperFormalParameter;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExtensionTypeConstructorWithSuperFormalParameter =
    const MessageCode(
  "ExtensionTypeConstructorWithSuperFormalParameter",
  analyzerCodes: <String>[
    "EXTENSION_TYPE_CONSTRUCTOR_WITH_SUPER_FORMAL_PARAMETER"
  ],
  problemMessage:
      r"""Extension type constructors can't declare super formal parameters.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExtensionTypeDeclarationCause =
    messageExtensionTypeDeclarationCause;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExtensionTypeDeclarationCause = const MessageCode(
  "ExtensionTypeDeclarationCause",
  severity: Severity.context,
  problemMessage: r"""The issue arises via this extension type declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExtensionTypeDeclaresAbstractMember =
    messageExtensionTypeDeclaresAbstractMember;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExtensionTypeDeclaresAbstractMember =
    const MessageCode(
  "ExtensionTypeDeclaresAbstractMember",
  analyzerCodes: <String>["EXTENSION_TYPE_WITH_ABSTRACT_MEMBER"],
  problemMessage: r"""Extension types can't declare abstract members.""",
  correctionMessage: r"""Try providing an implementation for the member.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExtensionTypeDeclaresInstanceField =
    messageExtensionTypeDeclaresInstanceField;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExtensionTypeDeclaresInstanceField = const MessageCode(
  "ExtensionTypeDeclaresInstanceField",
  analyzerCodes: <String>["EXTENSION_TYPE_DECLARES_INSTANCE_FIELD"],
  problemMessage: r"""Extension types can't declare instance fields""",
  correctionMessage:
      r"""Try removing the field declaration or making it a static field""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExtensionTypeExtends = messageExtensionTypeExtends;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExtensionTypeExtends = const MessageCode(
  "ExtensionTypeExtends",
  index: 164,
  problemMessage:
      r"""An extension type declaration can't have an 'extends' clause.""",
  correctionMessage:
      r"""Try removing the 'extends' clause or replacing the 'extends' with 'implements'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExtensionTypeImplementsDeferred =
    messageExtensionTypeImplementsDeferred;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExtensionTypeImplementsDeferred = const MessageCode(
  "ExtensionTypeImplementsDeferred",
  analyzerCodes: <String>["IMPLEMENTS_DEFERRED_CLASS"],
  problemMessage: r"""Extension types can't implement deferred types.""",
  correctionMessage:
      r"""Try specifying a different type, removing the type from the list, or changing the import to not be deferred.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExtensionTypeMemberContext = messageExtensionTypeMemberContext;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExtensionTypeMemberContext = const MessageCode(
  "ExtensionTypeMemberContext",
  severity: Severity.context,
  problemMessage: r"""This is the inherited extension type member.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExtensionTypeMemberOneOfContext =
    messageExtensionTypeMemberOneOfContext;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExtensionTypeMemberOneOfContext = const MessageCode(
  "ExtensionTypeMemberOneOfContext",
  severity: Severity.context,
  problemMessage: r"""This is one of the inherited extension type members.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExtensionTypePrimaryConstructorFunctionFormalParameterSyntax =
    messageExtensionTypePrimaryConstructorFunctionFormalParameterSyntax;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
    messageExtensionTypePrimaryConstructorFunctionFormalParameterSyntax =
    const MessageCode(
  "ExtensionTypePrimaryConstructorFunctionFormalParameterSyntax",
  problemMessage:
      r"""Primary constructors in extension types can't use function formal parameter syntax.""",
  correctionMessage:
      r"""Try rewriting with an explicit function type, like `int Function() f`.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExtensionTypePrimaryConstructorWithInitializingFormal =
    messageExtensionTypePrimaryConstructorWithInitializingFormal;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExtensionTypePrimaryConstructorWithInitializingFormal =
    const MessageCode(
  "ExtensionTypePrimaryConstructorWithInitializingFormal",
  problemMessage:
      r"""Primary constructors in extension types can't use initializing formals.""",
  correctionMessage: r"""Try removing `this.` from the formal parameter.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExtensionTypeRepresentationTypeBottom =
    messageExtensionTypeRepresentationTypeBottom;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExtensionTypeRepresentationTypeBottom =
    const MessageCode(
  "ExtensionTypeRepresentationTypeBottom",
  analyzerCodes: <String>["EXTENSION_TYPE_REPRESENTATION_TYPE_BOTTOM"],
  problemMessage: r"""The representation type can't be a bottom type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateExtensionTypeShouldBeListedAsCallableInDynamicInterface =
    const Template<Message Function(String name)>(
  "ExtensionTypeShouldBeListedAsCallableInDynamicInterface",
  problemMessageTemplate:
      r"""Cannot use extension type '#name' in a dynamic module.""",
  correctionMessageTemplate:
      r"""Try removing the reference to extension type '#name' or update the dynamic interface to list extension type '#name' as callable.""",
  withArguments:
      _withArgumentsExtensionTypeShouldBeListedAsCallableInDynamicInterface,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExtensionTypeShouldBeListedAsCallableInDynamicInterface =
    const Code(
  "ExtensionTypeShouldBeListedAsCallableInDynamicInterface",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExtensionTypeShouldBeListedAsCallableInDynamicInterface(
    String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeExtensionTypeShouldBeListedAsCallableInDynamicInterface,
    problemMessage:
        """Cannot use extension type '${name}' in a dynamic module.""",
    correctionMessage:
        """Try removing the reference to extension type '${name}' or update the dynamic interface to list extension type '${name}' as callable.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExtensionTypeWith = messageExtensionTypeWith;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExtensionTypeWith = const MessageCode(
  "ExtensionTypeWith",
  index: 165,
  problemMessage:
      r"""An extension type declaration can't have a 'with' clause.""",
  correctionMessage:
      r"""Try removing the 'with' clause or replacing the 'with' with 'implements'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExternalClass = messageExternalClass;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExternalClass = const MessageCode(
  "ExternalClass",
  index: 3,
  problemMessage: r"""Classes can't be declared to be 'external'.""",
  correctionMessage: r"""Try removing the keyword 'external'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExternalConstructorWithBody = messageExternalConstructorWithBody;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExternalConstructorWithBody = const MessageCode(
  "ExternalConstructorWithBody",
  index: 87,
  problemMessage: r"""External constructors can't have a body.""",
  correctionMessage:
      r"""Try removing the body of the constructor, or removing the keyword 'external'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExternalConstructorWithFieldInitializers =
    messageExternalConstructorWithFieldInitializers;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExternalConstructorWithFieldInitializers =
    const MessageCode(
  "ExternalConstructorWithFieldInitializers",
  index: 178,
  problemMessage: r"""An external constructor can't initialize fields.""",
  correctionMessage:
      r"""Try removing the field initializers, or removing the keyword 'external'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExternalConstructorWithInitializer =
    messageExternalConstructorWithInitializer;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExternalConstructorWithInitializer = const MessageCode(
  "ExternalConstructorWithInitializer",
  index: 106,
  problemMessage: r"""An external constructor can't have any initializers.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExternalEnum = messageExternalEnum;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExternalEnum = const MessageCode(
  "ExternalEnum",
  index: 5,
  problemMessage: r"""Enums can't be declared to be 'external'.""",
  correctionMessage: r"""Try removing the keyword 'external'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExternalFactoryRedirection = messageExternalFactoryRedirection;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExternalFactoryRedirection = const MessageCode(
  "ExternalFactoryRedirection",
  index: 85,
  problemMessage: r"""A redirecting factory can't be external.""",
  correctionMessage: r"""Try removing the 'external' modifier.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExternalFactoryWithBody = messageExternalFactoryWithBody;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExternalFactoryWithBody = const MessageCode(
  "ExternalFactoryWithBody",
  index: 86,
  problemMessage: r"""External factories can't have a body.""",
  correctionMessage:
      r"""Try removing the body of the factory, or removing the keyword 'external'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExternalField = messageExternalField;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExternalField = const MessageCode(
  "ExternalField",
  index: 50,
  problemMessage: r"""Fields can't be declared to be 'external'.""",
  correctionMessage:
      r"""Try removing the keyword 'external', or replacing the field by an external getter and/or setter.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExternalFieldConstructorInitializer =
    messageExternalFieldConstructorInitializer;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExternalFieldConstructorInitializer =
    const MessageCode(
  "ExternalFieldConstructorInitializer",
  problemMessage: r"""External fields cannot have initializers.""",
  correctionMessage:
      r"""Try removing the field initializer or the 'external' keyword from the field declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExternalFieldInitializer = messageExternalFieldInitializer;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExternalFieldInitializer = const MessageCode(
  "ExternalFieldInitializer",
  problemMessage: r"""External fields cannot have initializers.""",
  correctionMessage:
      r"""Try removing the initializer or the 'external' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExternalLateField = messageExternalLateField;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExternalLateField = const MessageCode(
  "ExternalLateField",
  index: 109,
  problemMessage: r"""External fields cannot be late.""",
  correctionMessage: r"""Try removing the 'external' or 'late' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExternalMethodWithBody = messageExternalMethodWithBody;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExternalMethodWithBody = const MessageCode(
  "ExternalMethodWithBody",
  index: 49,
  problemMessage: r"""An external or native method can't have a body.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExternalTypedef = messageExternalTypedef;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExternalTypedef = const MessageCode(
  "ExternalTypedef",
  index: 76,
  problemMessage: r"""Typedefs can't be declared to be 'external'.""",
  correctionMessage: r"""Try removing the keyword 'external'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateExtraneousModifier =
    const Template<Message Function(Token token)>(
  "ExtraneousModifier",
  problemMessageTemplate: r"""Can't have modifier '#lexeme' here.""",
  correctionMessageTemplate: r"""Try removing '#lexeme'.""",
  withArguments: _withArgumentsExtraneousModifier,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExtraneousModifier = const Code(
  "ExtraneousModifier",
  index: 77,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExtraneousModifier(Token token) {
  String lexeme = token.lexeme;
  return new Message(
    codeExtraneousModifier,
    problemMessage: """Can't have modifier '${lexeme}' here.""",
    correctionMessage: """Try removing '${lexeme}'.""",
    arguments: {
      'lexeme': token,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)>
    templateExtraneousModifierInExtension =
    const Template<Message Function(Token token)>(
  "ExtraneousModifierInExtension",
  problemMessageTemplate: r"""Can't have modifier '#lexeme' in an extension.""",
  correctionMessageTemplate: r"""Try removing '#lexeme'.""",
  withArguments: _withArgumentsExtraneousModifierInExtension,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExtraneousModifierInExtension = const Code(
  "ExtraneousModifierInExtension",
  index: 98,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExtraneousModifierInExtension(Token token) {
  String lexeme = token.lexeme;
  return new Message(
    codeExtraneousModifierInExtension,
    problemMessage: """Can't have modifier '${lexeme}' in an extension.""",
    correctionMessage: """Try removing '${lexeme}'.""",
    arguments: {
      'lexeme': token,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)>
    templateExtraneousModifierInExtensionType =
    const Template<Message Function(Token token)>(
  "ExtraneousModifierInExtensionType",
  problemMessageTemplate:
      r"""Can't have modifier '#lexeme' in an extension type.""",
  correctionMessageTemplate: r"""Try removing '#lexeme'.""",
  withArguments: _withArgumentsExtraneousModifierInExtensionType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExtraneousModifierInExtensionType = const Code(
  "ExtraneousModifierInExtensionType",
  index: 174,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExtraneousModifierInExtensionType(Token token) {
  String lexeme = token.lexeme;
  return new Message(
    codeExtraneousModifierInExtensionType,
    problemMessage: """Can't have modifier '${lexeme}' in an extension type.""",
    correctionMessage: """Try removing '${lexeme}'.""",
    arguments: {
      'lexeme': token,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)>
    templateExtraneousModifierInPrimaryConstructor =
    const Template<Message Function(Token token)>(
  "ExtraneousModifierInPrimaryConstructor",
  problemMessageTemplate:
      r"""Can't have modifier '#lexeme' in a primary constructor.""",
  correctionMessageTemplate: r"""Try removing '#lexeme'.""",
  withArguments: _withArgumentsExtraneousModifierInPrimaryConstructor,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeExtraneousModifierInPrimaryConstructor = const Code(
  "ExtraneousModifierInPrimaryConstructor",
  index: 175,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExtraneousModifierInPrimaryConstructor(Token token) {
  String lexeme = token.lexeme;
  return new Message(
    codeExtraneousModifierInPrimaryConstructor,
    problemMessage:
        """Can't have modifier '${lexeme}' in a primary constructor.""",
    correctionMessage: """Try removing '${lexeme}'.""",
    arguments: {
      'lexeme': token,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateFactoryConflictsWithMember =
    const Template<Message Function(String name)>(
  "FactoryConflictsWithMember",
  problemMessageTemplate: r"""The factory conflicts with member '#name'.""",
  withArguments: _withArgumentsFactoryConflictsWithMember,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFactoryConflictsWithMember = const Code(
  "FactoryConflictsWithMember",
  analyzerCodes: <String>["CONFLICTS_WITH_MEMBER"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFactoryConflictsWithMember(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeFactoryConflictsWithMember,
    problemMessage: """The factory conflicts with member '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateFactoryConflictsWithMemberCause =
    const Template<Message Function(String name)>(
  "FactoryConflictsWithMemberCause",
  problemMessageTemplate: r"""Conflicting member '#name'.""",
  withArguments: _withArgumentsFactoryConflictsWithMemberCause,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFactoryConflictsWithMemberCause = const Code(
  "FactoryConflictsWithMemberCause",
  severity: Severity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFactoryConflictsWithMemberCause(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeFactoryConflictsWithMemberCause,
    problemMessage: """Conflicting member '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFactoryNotSync = messageFactoryNotSync;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFactoryNotSync = const MessageCode(
  "FactoryNotSync",
  analyzerCodes: <String>["NON_SYNC_FACTORY"],
  problemMessage:
      r"""Factory bodies can't use 'async', 'async*', or 'sync*'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFactoryTopLevelDeclaration = messageFactoryTopLevelDeclaration;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFactoryTopLevelDeclaration = const MessageCode(
  "FactoryTopLevelDeclaration",
  index: 78,
  problemMessage:
      r"""Top-level declarations can't be declared to be 'factory'.""",
  correctionMessage: r"""Try removing the keyword 'factory'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateFastaCLIArgumentRequired =
    const Template<Message Function(String name)>(
  "FastaCLIArgumentRequired",
  problemMessageTemplate: r"""Expected value after '#name'.""",
  withArguments: _withArgumentsFastaCLIArgumentRequired,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFastaCLIArgumentRequired = const Code(
  "FastaCLIArgumentRequired",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFastaCLIArgumentRequired(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeFastaCLIArgumentRequired,
    problemMessage: """Expected value after '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFastaUsageLong = messageFastaUsageLong;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFastaUsageLong = const MessageCode(
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
const Code codeFastaUsageShort = messageFastaUsageShort;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFastaUsageShort = const MessageCode(
  "FastaUsageShort",
  problemMessage: r"""Frequently used options:

  -o <file> Generate the output into <file>.
  -h        Display this message (add -v for information about all options).""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFfiAbiSpecificIntegerInvalid =
    messageFfiAbiSpecificIntegerInvalid;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFfiAbiSpecificIntegerInvalid = const MessageCode(
  "FfiAbiSpecificIntegerInvalid",
  problemMessage:
      r"""Classes extending 'AbiSpecificInteger' must have exactly one const constructor, no other members, and no type arguments.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFfiAbiSpecificIntegerMappingInvalid =
    messageFfiAbiSpecificIntegerMappingInvalid;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFfiAbiSpecificIntegerMappingInvalid =
    const MessageCode(
  "FfiAbiSpecificIntegerMappingInvalid",
  problemMessage:
      r"""Classes extending 'AbiSpecificInteger' must have exactly one 'AbiSpecificIntegerMapping' annotation specifying the mapping from ABI to a NativeType integer with a fixed size.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFfiAddressOfMustBeNative = messageFfiAddressOfMustBeNative;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFfiAddressOfMustBeNative = const MessageCode(
  "FfiAddressOfMustBeNative",
  analyzerCodes: <String>["ARGUMENT_MUST_BE_NATIVE"],
  problemMessage:
      r"""Argument to 'Native.addressOf' must be annotated with @Native.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFfiAddressPosition = messageFfiAddressPosition;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFfiAddressPosition = const MessageCode(
  "FfiAddressPosition",
  problemMessage:
      r"""The '.address' expression can only be used as argument to a leaf native external call.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFfiAddressReceiver = messageFfiAddressReceiver;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFfiAddressReceiver = const MessageCode(
  "FfiAddressReceiver",
  problemMessage:
      r"""The receiver of '.address' must be a concrete 'TypedData', a concrete 'TypedData' '[]', an 'Array', an 'Array' '[]', a Struct field, or a Union field.""",
  correctionMessage:
      r"""Change the receiver of '.address' to one of the allowed kinds.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string, String name)>
    templateFfiCompoundImplementsFinalizable =
    const Template<Message Function(String string, String name)>(
  "FfiCompoundImplementsFinalizable",
  problemMessageTemplate: r"""#string '#name' can't implement Finalizable.""",
  correctionMessageTemplate:
      r"""Try removing the implements clause from '#name'.""",
  withArguments: _withArgumentsFfiCompoundImplementsFinalizable,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFfiCompoundImplementsFinalizable = const Code(
  "FfiCompoundImplementsFinalizable",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiCompoundImplementsFinalizable(
    String string, String name) {
  if (string.isEmpty) throw 'No string provided';
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeFfiCompoundImplementsFinalizable,
    problemMessage: """${string} '${name}' can't implement Finalizable.""",
    correctionMessage: """Try removing the implements clause from '${name}'.""",
    arguments: {
      'string': string,
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFfiCreateOfStructOrUnion = messageFfiCreateOfStructOrUnion;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFfiCreateOfStructOrUnion = const MessageCode(
  "FfiCreateOfStructOrUnion",
  problemMessage:
      r"""Subclasses of 'Struct' and 'Union' are backed by native memory, and can't be instantiated by a generative constructor. Try allocating it via allocation, or load from a 'Pointer'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFfiDeeplyImmutableClassesMustBeFinalOrSealed =
    messageFfiDeeplyImmutableClassesMustBeFinalOrSealed;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFfiDeeplyImmutableClassesMustBeFinalOrSealed =
    const MessageCode(
  "FfiDeeplyImmutableClassesMustBeFinalOrSealed",
  problemMessage: r"""Deeply immutable classes must be final or sealed.""",
  correctionMessage: r"""Try marking this class as final or sealed.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFfiDeeplyImmutableFieldsModifiers =
    messageFfiDeeplyImmutableFieldsModifiers;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFfiDeeplyImmutableFieldsModifiers = const MessageCode(
  "FfiDeeplyImmutableFieldsModifiers",
  problemMessage:
      r"""Deeply immutable classes must only have final non-late instance fields.""",
  correctionMessage:
      r"""Add the 'final' modifier to this field, and remove 'late' modifier from this field.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFfiDeeplyImmutableFieldsMustBeDeeplyImmutable =
    messageFfiDeeplyImmutableFieldsMustBeDeeplyImmutable;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFfiDeeplyImmutableFieldsMustBeDeeplyImmutable =
    const MessageCode(
  "FfiDeeplyImmutableFieldsMustBeDeeplyImmutable",
  problemMessage:
      r"""Deeply immutable classes must only have deeply immutable instance fields. Deeply immutable types include 'int', 'double', 'bool', 'String', 'Pointer', 'Float32x4', 'Float64x2', 'Int32x4', and classes annotated with `@pragma('vm:deeply-immutable')`.""",
  correctionMessage:
      r"""Try changing the type of this field to a deeply immutable type or mark the type of this field as deeply immutable.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFfiDeeplyImmutableSubtypesMustBeDeeplyImmutable =
    messageFfiDeeplyImmutableSubtypesMustBeDeeplyImmutable;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFfiDeeplyImmutableSubtypesMustBeDeeplyImmutable =
    const MessageCode(
  "FfiDeeplyImmutableSubtypesMustBeDeeplyImmutable",
  problemMessage:
      r"""Subtypes of deeply immutable classes must be deeply immutable.""",
  correctionMessage:
      r"""Try marking this class deeply immutable by adding `@pragma('vm:deeply-immutable')`.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFfiDeeplyImmutableSupertypeMustBeDeeplyImmutable =
    messageFfiDeeplyImmutableSupertypeMustBeDeeplyImmutable;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFfiDeeplyImmutableSupertypeMustBeDeeplyImmutable =
    const MessageCode(
  "FfiDeeplyImmutableSupertypeMustBeDeeplyImmutable",
  problemMessage:
      r"""The super type of deeply immutable classes must be deeply immutable.""",
  correctionMessage:
      r"""Try marking the super class deeply immutable by adding `@pragma('vm:deeply-immutable')`.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFfiDefaultAssetDuplicate = messageFfiDefaultAssetDuplicate;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFfiDefaultAssetDuplicate = const MessageCode(
  "FfiDefaultAssetDuplicate",
  analyzerCodes: <String>["FFI_NATIVE_INVALID_DUPLICATE_DEFAULT_ASSET"],
  problemMessage:
      r"""There may be at most one @DefaultAsset annotation on a library.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string, String name)>
    templateFfiEmptyStruct =
    const Template<Message Function(String string, String name)>(
  "FfiEmptyStruct",
  problemMessageTemplate:
      r"""#string '#name' is empty. Empty structs and unions are undefined behavior.""",
  withArguments: _withArgumentsFfiEmptyStruct,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFfiEmptyStruct = const Code(
  "FfiEmptyStruct",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiEmptyStruct(String string, String name) {
  if (string.isEmpty) throw 'No string provided';
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeFfiEmptyStruct,
    problemMessage:
        """${string} '${name}' is empty. Empty structs and unions are undefined behavior.""",
    arguments: {
      'string': string,
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFfiExceptionalReturnNull = messageFfiExceptionalReturnNull;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFfiExceptionalReturnNull = const MessageCode(
  "FfiExceptionalReturnNull",
  problemMessage: r"""Exceptional return value must not be null.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFfiExpectedConstant = messageFfiExpectedConstant;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFfiExpectedConstant = const MessageCode(
  "FfiExpectedConstant",
  problemMessage: r"""Exceptional return value must be a constant.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateFfiExpectedConstantArg =
    const Template<Message Function(String name)>(
  "FfiExpectedConstantArg",
  problemMessageTemplate: r"""Argument '#name' must be a constant.""",
  withArguments: _withArgumentsFfiExpectedConstantArg,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFfiExpectedConstantArg = const Code(
  "FfiExpectedConstantArg",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiExpectedConstantArg(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeFfiExpectedConstantArg,
    problemMessage: """Argument '${name}' must be a constant.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateFfiExtendsOrImplementsSealedClass =
    const Template<Message Function(String name)>(
  "FfiExtendsOrImplementsSealedClass",
  problemMessageTemplate:
      r"""Class '#name' cannot be extended or implemented.""",
  withArguments: _withArgumentsFfiExtendsOrImplementsSealedClass,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFfiExtendsOrImplementsSealedClass = const Code(
  "FfiExtendsOrImplementsSealedClass",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiExtendsOrImplementsSealedClass(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeFfiExtendsOrImplementsSealedClass,
    problemMessage: """Class '${name}' cannot be extended or implemented.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateFfiFieldAnnotation =
    const Template<Message Function(String name)>(
  "FfiFieldAnnotation",
  problemMessageTemplate:
      r"""Field '#name' requires exactly one annotation to declare its native type, which cannot be Void. dart:ffi Structs and Unions cannot have regular Dart fields.""",
  withArguments: _withArgumentsFfiFieldAnnotation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFfiFieldAnnotation = const Code(
  "FfiFieldAnnotation",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiFieldAnnotation(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeFfiFieldAnnotation,
    problemMessage:
        """Field '${name}' requires exactly one annotation to declare its native type, which cannot be Void. dart:ffi Structs and Unions cannot have regular Dart fields.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(String string, String name, List<String> _names)>
    templateFfiFieldCyclic = const Template<
        Message Function(String string, String name, List<String> _names)>(
  "FfiFieldCyclic",
  problemMessageTemplate: r"""#string '#name' contains itself. Cycle elements:
#names""",
  withArguments: _withArgumentsFfiFieldCyclic,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFfiFieldCyclic = const Code(
  "FfiFieldCyclic",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiFieldCyclic(
    String string, String name, List<String> _names) {
  if (string.isEmpty) throw 'No string provided';
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (_names.isEmpty) throw 'No names provided';
  String names = itemizeNames(_names);
  return new Message(
    codeFfiFieldCyclic,
    problemMessage: """${string} '${name}' contains itself. Cycle elements:
${names}""",
    arguments: {
      'string': string,
      'name': name,
      'names': _names,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateFfiFieldInitializer =
    const Template<Message Function(String name)>(
  "FfiFieldInitializer",
  problemMessageTemplate:
      r"""Field '#name' is a dart:ffi Pointer to a struct field and therefore cannot be initialized before constructor execution.""",
  correctionMessageTemplate:
      r"""Mark the field as external to avoid having to initialize it.""",
  withArguments: _withArgumentsFfiFieldInitializer,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFfiFieldInitializer = const Code(
  "FfiFieldInitializer",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiFieldInitializer(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeFfiFieldInitializer,
    problemMessage:
        """Field '${name}' is a dart:ffi Pointer to a struct field and therefore cannot be initialized before constructor execution.""",
    correctionMessage:
        """Mark the field as external to avoid having to initialize it.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateFfiFieldNoAnnotation =
    const Template<Message Function(String name)>(
  "FfiFieldNoAnnotation",
  problemMessageTemplate:
      r"""Field '#name' requires no annotation to declare its native type, it is a Pointer which is represented by the same type in Dart and native code.""",
  withArguments: _withArgumentsFfiFieldNoAnnotation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFfiFieldNoAnnotation = const Code(
  "FfiFieldNoAnnotation",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiFieldNoAnnotation(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeFfiFieldNoAnnotation,
    problemMessage:
        """Field '${name}' requires no annotation to declare its native type, it is a Pointer which is represented by the same type in Dart and native code.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateFfiFieldNull =
    const Template<Message Function(String name)>(
  "FfiFieldNull",
  problemMessageTemplate:
      r"""Field '#name' cannot be nullable or have type 'Null', it must be `int`, `double`, `Pointer`, or a subtype of `Struct` or `Union`.""",
  withArguments: _withArgumentsFfiFieldNull,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFfiFieldNull = const Code(
  "FfiFieldNull",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiFieldNull(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeFfiFieldNull,
    problemMessage:
        """Field '${name}' cannot be nullable or have type 'Null', it must be `int`, `double`, `Pointer`, or a subtype of `Struct` or `Union`.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFfiLeafCallMustNotReturnHandle =
    messageFfiLeafCallMustNotReturnHandle;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFfiLeafCallMustNotReturnHandle = const MessageCode(
  "FfiLeafCallMustNotReturnHandle",
  problemMessage: r"""FFI leaf call must not have Handle return type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFfiLeafCallMustNotTakeHandle =
    messageFfiLeafCallMustNotTakeHandle;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFfiLeafCallMustNotTakeHandle = const MessageCode(
  "FfiLeafCallMustNotTakeHandle",
  problemMessage: r"""FFI leaf call must not have Handle argument types.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFfiNativeDuplicateAnnotations =
    messageFfiNativeDuplicateAnnotations;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFfiNativeDuplicateAnnotations = const MessageCode(
  "FfiNativeDuplicateAnnotations",
  analyzerCodes: <String>["FFI_NATIVE_INVALID_MULTIPLE_ANNOTATIONS"],
  problemMessage:
      r"""Native functions and fields must not have more than @Native annotation.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFfiNativeFieldMissingType = messageFfiNativeFieldMissingType;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFfiNativeFieldMissingType = const MessageCode(
  "FfiNativeFieldMissingType",
  analyzerCodes: <String>["NATIVE_FIELD_MISSING_TYPE"],
  problemMessage:
      r"""The native type of this field could not be inferred and must be specified in the annotation.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFfiNativeFieldMustBeStatic = messageFfiNativeFieldMustBeStatic;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFfiNativeFieldMustBeStatic = const MessageCode(
  "FfiNativeFieldMustBeStatic",
  analyzerCodes: <String>["NATIVE_FIELD_NOT_STATIC"],
  problemMessage: r"""Native fields must be static.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFfiNativeFieldType = messageFfiNativeFieldType;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFfiNativeFieldType = const MessageCode(
  "FfiNativeFieldType",
  analyzerCodes: <String>["NATIVE_FIELD_INVALID_TYPE"],
  problemMessage:
      r"""Unsupported type for native fields. Native fields only support pointers, compounds and numeric types.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFfiNativeFunctionMissingType =
    messageFfiNativeFunctionMissingType;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFfiNativeFunctionMissingType = const MessageCode(
  "FfiNativeFunctionMissingType",
  analyzerCodes: <String>["NATIVE_FUNCTION_MISSING_TYPE"],
  problemMessage:
      r"""The native type of this function couldn't be inferred so it must be specified in the annotation.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFfiNativeMustBeExternal = messageFfiNativeMustBeExternal;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFfiNativeMustBeExternal = const MessageCode(
  "FfiNativeMustBeExternal",
  problemMessage: r"""Native functions and fields must be marked external.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFfiNativeOnlyNativeFieldWrapperClassCanBePointer =
    messageFfiNativeOnlyNativeFieldWrapperClassCanBePointer;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFfiNativeOnlyNativeFieldWrapperClassCanBePointer =
    const MessageCode(
  "FfiNativeOnlyNativeFieldWrapperClassCanBePointer",
  problemMessage:
      r"""Only classes extending NativeFieldWrapperClass1 can be passed as Pointer.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(int count, int count2)>
    templateFfiNativeUnexpectedNumberOfParameters =
    const Template<Message Function(int count, int count2)>(
  "FfiNativeUnexpectedNumberOfParameters",
  problemMessageTemplate:
      r"""Unexpected number of Native annotation parameters. Expected #count but has #count2.""",
  withArguments: _withArgumentsFfiNativeUnexpectedNumberOfParameters,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFfiNativeUnexpectedNumberOfParameters = const Code(
  "FfiNativeUnexpectedNumberOfParameters",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiNativeUnexpectedNumberOfParameters(
    int count, int count2) {
  return new Message(
    codeFfiNativeUnexpectedNumberOfParameters,
    problemMessage:
        """Unexpected number of Native annotation parameters. Expected ${count} but has ${count2}.""",
    arguments: {
      'count': count,
      'count2': count2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(int count, int count2)>
    templateFfiNativeUnexpectedNumberOfParametersWithReceiver =
    const Template<Message Function(int count, int count2)>(
  "FfiNativeUnexpectedNumberOfParametersWithReceiver",
  problemMessageTemplate:
      r"""Unexpected number of Native annotation parameters. Expected #count but has #count2. Native instance method annotation must have receiver as first argument.""",
  withArguments:
      _withArgumentsFfiNativeUnexpectedNumberOfParametersWithReceiver,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFfiNativeUnexpectedNumberOfParametersWithReceiver = const Code(
  "FfiNativeUnexpectedNumberOfParametersWithReceiver",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiNativeUnexpectedNumberOfParametersWithReceiver(
    int count, int count2) {
  return new Message(
    codeFfiNativeUnexpectedNumberOfParametersWithReceiver,
    problemMessage:
        """Unexpected number of Native annotation parameters. Expected ${count} but has ${count2}. Native instance method annotation must have receiver as first argument.""",
    arguments: {
      'count': count,
      'count2': count2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateFfiNotStatic =
    const Template<Message Function(String name)>(
  "FfiNotStatic",
  problemMessageTemplate:
      r"""#name expects a static function as parameter. dart:ffi only supports calling static Dart functions from native code. Closures and tear-offs are not supported because they can capture context.""",
  withArguments: _withArgumentsFfiNotStatic,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFfiNotStatic = const Code(
  "FfiNotStatic",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiNotStatic(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeFfiNotStatic,
    problemMessage:
        """${name} expects a static function as parameter. dart:ffi only supports calling static Dart functions from native code. Closures and tear-offs are not supported because they can capture context.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateFfiPackedAnnotation =
    const Template<Message Function(String name)>(
  "FfiPackedAnnotation",
  problemMessageTemplate:
      r"""Struct '#name' must have at most one 'Packed' annotation.""",
  withArguments: _withArgumentsFfiPackedAnnotation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFfiPackedAnnotation = const Code(
  "FfiPackedAnnotation",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiPackedAnnotation(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeFfiPackedAnnotation,
    problemMessage:
        """Struct '${name}' must have at most one 'Packed' annotation.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFfiPackedAnnotationAlignment =
    messageFfiPackedAnnotationAlignment;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFfiPackedAnnotationAlignment = const MessageCode(
  "FfiPackedAnnotationAlignment",
  problemMessage: r"""Only packing to 1, 2, 4, 8, and 16 bytes is supported.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateFfiSizeAnnotation =
    const Template<Message Function(String name)>(
  "FfiSizeAnnotation",
  problemMessageTemplate:
      r"""Field '#name' must have exactly one 'Array' annotation.""",
  withArguments: _withArgumentsFfiSizeAnnotation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFfiSizeAnnotation = const Code(
  "FfiSizeAnnotation",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiSizeAnnotation(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeFfiSizeAnnotation,
    problemMessage:
        """Field '${name}' must have exactly one 'Array' annotation.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateFfiSizeAnnotationDimensions =
    const Template<Message Function(String name)>(
  "FfiSizeAnnotationDimensions",
  problemMessageTemplate:
      r"""Field '#name' must have an 'Array' annotation that matches the dimensions.""",
  withArguments: _withArgumentsFfiSizeAnnotationDimensions,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFfiSizeAnnotationDimensions = const Code(
  "FfiSizeAnnotationDimensions",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiSizeAnnotationDimensions(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeFfiSizeAnnotationDimensions,
    problemMessage:
        """Field '${name}' must have an 'Array' annotation that matches the dimensions.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string, String name)>
    templateFfiStructGeneric =
    const Template<Message Function(String string, String name)>(
  "FfiStructGeneric",
  problemMessageTemplate: r"""#string '#name' should not be generic.""",
  withArguments: _withArgumentsFfiStructGeneric,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFfiStructGeneric = const Code(
  "FfiStructGeneric",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiStructGeneric(String string, String name) {
  if (string.isEmpty) throw 'No string provided';
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeFfiStructGeneric,
    problemMessage: """${string} '${name}' should not be generic.""",
    arguments: {
      'string': string,
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFfiVariableLengthArrayNotLast =
    messageFfiVariableLengthArrayNotLast;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFfiVariableLengthArrayNotLast = const MessageCode(
  "FfiVariableLengthArrayNotLast",
  problemMessage:
      r"""Variable length 'Array's must only occur as the last field of Structs.""",
  correctionMessage:
      r"""Try adjusting the arguments in the 'Array' annotation.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateFieldAlreadyInitializedAtDeclaration =
    const Template<Message Function(String name)>(
  "FieldAlreadyInitializedAtDeclaration",
  problemMessageTemplate:
      r"""'#name' is a final instance variable that was initialized at the declaration.""",
  withArguments: _withArgumentsFieldAlreadyInitializedAtDeclaration,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFieldAlreadyInitializedAtDeclaration = const Code(
  "FieldAlreadyInitializedAtDeclaration",
  analyzerCodes: <String>["FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFieldAlreadyInitializedAtDeclaration(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeFieldAlreadyInitializedAtDeclaration,
    problemMessage:
        """'${name}' is a final instance variable that was initialized at the declaration.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateFieldAlreadyInitializedAtDeclarationCause =
    const Template<Message Function(String name)>(
  "FieldAlreadyInitializedAtDeclarationCause",
  problemMessageTemplate: r"""'#name' was initialized here.""",
  withArguments: _withArgumentsFieldAlreadyInitializedAtDeclarationCause,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFieldAlreadyInitializedAtDeclarationCause = const Code(
  "FieldAlreadyInitializedAtDeclarationCause",
  severity: Severity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFieldAlreadyInitializedAtDeclarationCause(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeFieldAlreadyInitializedAtDeclarationCause,
    problemMessage: """'${name}' was initialized here.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFieldInitializedOutsideDeclaringClass =
    messageFieldInitializedOutsideDeclaringClass;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFieldInitializedOutsideDeclaringClass =
    const MessageCode(
  "FieldInitializedOutsideDeclaringClass",
  index: 88,
  problemMessage: r"""A field can only be initialized in its declaring class""",
  correctionMessage:
      r"""Try passing a value into the superclass constructor, or moving the initialization into the constructor body.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFieldInitializerOutsideConstructor =
    messageFieldInitializerOutsideConstructor;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFieldInitializerOutsideConstructor = const MessageCode(
  "FieldInitializerOutsideConstructor",
  index: 79,
  problemMessage:
      r"""Field formal parameters can only be used in a constructor.""",
  correctionMessage: r"""Try removing 'this.'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String name2, String string)>
    templateFieldNotPromotedBecauseConflictingField =
    const Template<Message Function(String name, String name2, String string)>(
  "FieldNotPromotedBecauseConflictingField",
  problemMessageTemplate:
      r"""'#name' couldn't be promoted because there is a conflicting non-promotable field in class '#name2'.""",
  correctionMessageTemplate: r"""See #string""",
  withArguments: _withArgumentsFieldNotPromotedBecauseConflictingField,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFieldNotPromotedBecauseConflictingField = const Code(
  "FieldNotPromotedBecauseConflictingField",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFieldNotPromotedBecauseConflictingField(
    String name, String name2, String string) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  if (string.isEmpty) throw 'No string provided';
  return new Message(
    codeFieldNotPromotedBecauseConflictingField,
    problemMessage:
        """'${name}' couldn't be promoted because there is a conflicting non-promotable field in class '${name2}'.""",
    correctionMessage: """See ${string}""",
    arguments: {
      'name': name,
      'name2': name2,
      'string': string,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String name2, String string)>
    templateFieldNotPromotedBecauseConflictingGetter =
    const Template<Message Function(String name, String name2, String string)>(
  "FieldNotPromotedBecauseConflictingGetter",
  problemMessageTemplate:
      r"""'#name' couldn't be promoted because there is a conflicting getter in class '#name2'.""",
  correctionMessageTemplate: r"""See #string""",
  withArguments: _withArgumentsFieldNotPromotedBecauseConflictingGetter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFieldNotPromotedBecauseConflictingGetter = const Code(
  "FieldNotPromotedBecauseConflictingGetter",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFieldNotPromotedBecauseConflictingGetter(
    String name, String name2, String string) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  if (string.isEmpty) throw 'No string provided';
  return new Message(
    codeFieldNotPromotedBecauseConflictingGetter,
    problemMessage:
        """'${name}' couldn't be promoted because there is a conflicting getter in class '${name2}'.""",
    correctionMessage: """See ${string}""",
    arguments: {
      'name': name,
      'name2': name2,
      'string': string,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String name2, String string)>
    templateFieldNotPromotedBecauseConflictingNsmForwarder =
    const Template<Message Function(String name, String name2, String string)>(
  "FieldNotPromotedBecauseConflictingNsmForwarder",
  problemMessageTemplate:
      r"""'#name' couldn't be promoted because there is a conflicting noSuchMethod forwarder in class '#name2'.""",
  correctionMessageTemplate: r"""See #string""",
  withArguments: _withArgumentsFieldNotPromotedBecauseConflictingNsmForwarder,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFieldNotPromotedBecauseConflictingNsmForwarder = const Code(
  "FieldNotPromotedBecauseConflictingNsmForwarder",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFieldNotPromotedBecauseConflictingNsmForwarder(
    String name, String name2, String string) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  if (string.isEmpty) throw 'No string provided';
  return new Message(
    codeFieldNotPromotedBecauseConflictingNsmForwarder,
    problemMessage:
        """'${name}' couldn't be promoted because there is a conflicting noSuchMethod forwarder in class '${name2}'.""",
    correctionMessage: """See ${string}""",
    arguments: {
      'name': name,
      'name2': name2,
      'string': string,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String string)>
    templateFieldNotPromotedBecauseExternal =
    const Template<Message Function(String name, String string)>(
  "FieldNotPromotedBecauseExternal",
  problemMessageTemplate:
      r"""'#name' refers to an external field so it couldn't be promoted.""",
  correctionMessageTemplate: r"""See #string""",
  withArguments: _withArgumentsFieldNotPromotedBecauseExternal,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFieldNotPromotedBecauseExternal = const Code(
  "FieldNotPromotedBecauseExternal",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFieldNotPromotedBecauseExternal(
    String name, String string) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (string.isEmpty) throw 'No string provided';
  return new Message(
    codeFieldNotPromotedBecauseExternal,
    problemMessage:
        """'${name}' refers to an external field so it couldn't be promoted.""",
    correctionMessage: """See ${string}""",
    arguments: {
      'name': name,
      'string': string,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String string)>
    templateFieldNotPromotedBecauseNotEnabled =
    const Template<Message Function(String name, String string)>(
  "FieldNotPromotedBecauseNotEnabled",
  problemMessageTemplate:
      r"""'#name' couldn't be promoted because field promotion is only available in Dart 3.2 and above.""",
  correctionMessageTemplate: r"""See #string""",
  withArguments: _withArgumentsFieldNotPromotedBecauseNotEnabled,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFieldNotPromotedBecauseNotEnabled = const Code(
  "FieldNotPromotedBecauseNotEnabled",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFieldNotPromotedBecauseNotEnabled(
    String name, String string) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (string.isEmpty) throw 'No string provided';
  return new Message(
    codeFieldNotPromotedBecauseNotEnabled,
    problemMessage:
        """'${name}' couldn't be promoted because field promotion is only available in Dart 3.2 and above.""",
    correctionMessage: """See ${string}""",
    arguments: {
      'name': name,
      'string': string,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String string)>
    templateFieldNotPromotedBecauseNotField =
    const Template<Message Function(String name, String string)>(
  "FieldNotPromotedBecauseNotField",
  problemMessageTemplate:
      r"""'#name' refers to a getter so it couldn't be promoted.""",
  correctionMessageTemplate: r"""See #string""",
  withArguments: _withArgumentsFieldNotPromotedBecauseNotField,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFieldNotPromotedBecauseNotField = const Code(
  "FieldNotPromotedBecauseNotField",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFieldNotPromotedBecauseNotField(
    String name, String string) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (string.isEmpty) throw 'No string provided';
  return new Message(
    codeFieldNotPromotedBecauseNotField,
    problemMessage:
        """'${name}' refers to a getter so it couldn't be promoted.""",
    correctionMessage: """See ${string}""",
    arguments: {
      'name': name,
      'string': string,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String string)>
    templateFieldNotPromotedBecauseNotFinal =
    const Template<Message Function(String name, String string)>(
  "FieldNotPromotedBecauseNotFinal",
  problemMessageTemplate:
      r"""'#name' refers to a non-final field so it couldn't be promoted.""",
  correctionMessageTemplate: r"""See #string""",
  withArguments: _withArgumentsFieldNotPromotedBecauseNotFinal,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFieldNotPromotedBecauseNotFinal = const Code(
  "FieldNotPromotedBecauseNotFinal",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFieldNotPromotedBecauseNotFinal(
    String name, String string) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (string.isEmpty) throw 'No string provided';
  return new Message(
    codeFieldNotPromotedBecauseNotFinal,
    problemMessage:
        """'${name}' refers to a non-final field so it couldn't be promoted.""",
    correctionMessage: """See ${string}""",
    arguments: {
      'name': name,
      'string': string,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String string)>
    templateFieldNotPromotedBecauseNotPrivate =
    const Template<Message Function(String name, String string)>(
  "FieldNotPromotedBecauseNotPrivate",
  problemMessageTemplate:
      r"""'#name' refers to a public property so it couldn't be promoted.""",
  correctionMessageTemplate: r"""See #string""",
  withArguments: _withArgumentsFieldNotPromotedBecauseNotPrivate,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFieldNotPromotedBecauseNotPrivate = const Code(
  "FieldNotPromotedBecauseNotPrivate",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFieldNotPromotedBecauseNotPrivate(
    String name, String string) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (string.isEmpty) throw 'No string provided';
  return new Message(
    codeFieldNotPromotedBecauseNotPrivate,
    problemMessage:
        """'${name}' refers to a public property so it couldn't be promoted.""",
    correctionMessage: """See ${string}""",
    arguments: {
      'name': name,
      'string': string,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFinalAndCovariant = messageFinalAndCovariant;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFinalAndCovariant = const MessageCode(
  "FinalAndCovariant",
  index: 80,
  problemMessage:
      r"""Members can't be declared to be both 'final' and 'covariant'.""",
  correctionMessage:
      r"""Try removing either the 'final' or 'covariant' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFinalAndCovariantLateWithInitializer =
    messageFinalAndCovariantLateWithInitializer;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFinalAndCovariantLateWithInitializer =
    const MessageCode(
  "FinalAndCovariantLateWithInitializer",
  index: 101,
  problemMessage:
      r"""Members marked 'late' with an initializer can't be declared to be both 'final' and 'covariant'.""",
  correctionMessage:
      r"""Try removing either the 'final' or 'covariant' keyword, or removing the initializer.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFinalAndVar = messageFinalAndVar;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFinalAndVar = const MessageCode(
  "FinalAndVar",
  index: 81,
  problemMessage:
      r"""Members can't be declared to be both 'final' and 'var'.""",
  correctionMessage: r"""Try removing the keyword 'var'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateFinalClassExtendedOutsideOfLibrary =
    const Template<Message Function(String name)>(
  "FinalClassExtendedOutsideOfLibrary",
  problemMessageTemplate:
      r"""The class '#name' can't be extended outside of its library because it's a final class.""",
  withArguments: _withArgumentsFinalClassExtendedOutsideOfLibrary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFinalClassExtendedOutsideOfLibrary = const Code(
  "FinalClassExtendedOutsideOfLibrary",
  analyzerCodes: <String>["FINAL_CLASS_EXTENDED_OUTSIDE_OF_LIBRARY"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFinalClassExtendedOutsideOfLibrary(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeFinalClassExtendedOutsideOfLibrary,
    problemMessage:
        """The class '${name}' can't be extended outside of its library because it's a final class.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateFinalClassImplementedOutsideOfLibrary =
    const Template<Message Function(String name)>(
  "FinalClassImplementedOutsideOfLibrary",
  problemMessageTemplate:
      r"""The class '#name' can't be implemented outside of its library because it's a final class.""",
  withArguments: _withArgumentsFinalClassImplementedOutsideOfLibrary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFinalClassImplementedOutsideOfLibrary = const Code(
  "FinalClassImplementedOutsideOfLibrary",
  analyzerCodes: <String>["FINAL_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFinalClassImplementedOutsideOfLibrary(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeFinalClassImplementedOutsideOfLibrary,
    problemMessage:
        """The class '${name}' can't be implemented outside of its library because it's a final class.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateFinalClassUsedAsMixinConstraintOutsideOfLibrary =
    const Template<Message Function(String name)>(
  "FinalClassUsedAsMixinConstraintOutsideOfLibrary",
  problemMessageTemplate:
      r"""The class '#name' can't be used as a mixin superclass constraint outside of its library because it's a final class.""",
  withArguments: _withArgumentsFinalClassUsedAsMixinConstraintOutsideOfLibrary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFinalClassUsedAsMixinConstraintOutsideOfLibrary = const Code(
  "FinalClassUsedAsMixinConstraintOutsideOfLibrary",
  analyzerCodes: <String>[
    "FINAL_CLASS_USED_AS_MIXIN_CONSTRAINT_OUTSIDE_OF_LIBRARY"
  ],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFinalClassUsedAsMixinConstraintOutsideOfLibrary(
    String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeFinalClassUsedAsMixinConstraintOutsideOfLibrary,
    problemMessage:
        """The class '${name}' can't be used as a mixin superclass constraint outside of its library because it's a final class.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFinalEnum = messageFinalEnum;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFinalEnum = const MessageCode(
  "FinalEnum",
  index: 156,
  problemMessage: r"""Enums can't be declared to be 'final'.""",
  correctionMessage: r"""Try removing the keyword 'final'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateFinalFieldNotInitialized =
    const Template<Message Function(String name)>(
  "FinalFieldNotInitialized",
  problemMessageTemplate: r"""Final field '#name' is not initialized.""",
  correctionMessageTemplate:
      r"""Try to initialize the field in the declaration or in every constructor.""",
  withArguments: _withArgumentsFinalFieldNotInitialized,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFinalFieldNotInitialized = const Code(
  "FinalFieldNotInitialized",
  analyzerCodes: <String>["FINAL_NOT_INITIALIZED"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFinalFieldNotInitialized(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeFinalFieldNotInitialized,
    problemMessage: """Final field '${name}' is not initialized.""",
    correctionMessage:
        """Try to initialize the field in the declaration or in every constructor.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateFinalFieldNotInitializedByConstructor =
    const Template<Message Function(String name)>(
  "FinalFieldNotInitializedByConstructor",
  problemMessageTemplate:
      r"""Final field '#name' is not initialized by this constructor.""",
  correctionMessageTemplate:
      r"""Try to initialize the field using an initializing formal or a field initializer.""",
  withArguments: _withArgumentsFinalFieldNotInitializedByConstructor,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFinalFieldNotInitializedByConstructor = const Code(
  "FinalFieldNotInitializedByConstructor",
  analyzerCodes: <String>["FINAL_NOT_INITIALIZED_CONSTRUCTOR_1"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFinalFieldNotInitializedByConstructor(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeFinalFieldNotInitializedByConstructor,
    problemMessage:
        """Final field '${name}' is not initialized by this constructor.""",
    correctionMessage:
        """Try to initialize the field using an initializing formal or a field initializer.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateFinalFieldWithoutInitializer =
    const Template<Message Function(String name)>(
  "FinalFieldWithoutInitializer",
  problemMessageTemplate:
      r"""The final variable '#name' must be initialized.""",
  correctionMessageTemplate:
      r"""Try adding an initializer ('= expression') to the declaration.""",
  withArguments: _withArgumentsFinalFieldWithoutInitializer,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFinalFieldWithoutInitializer = const Code(
  "FinalFieldWithoutInitializer",
  analyzerCodes: <String>["FINAL_NOT_INITIALIZED"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFinalFieldWithoutInitializer(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeFinalFieldWithoutInitializer,
    problemMessage: """The final variable '${name}' must be initialized.""",
    correctionMessage:
        """Try adding an initializer ('= expression') to the declaration.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFinalMixin = messageFinalMixin;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFinalMixin = const MessageCode(
  "FinalMixin",
  index: 146,
  problemMessage: r"""A mixin can't be declared 'final'.""",
  correctionMessage: r"""Try removing the 'final' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFinalMixinClass = messageFinalMixinClass;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFinalMixinClass = const MessageCode(
  "FinalMixinClass",
  index: 142,
  problemMessage: r"""A mixin class can't be declared 'final'.""",
  correctionMessage: r"""Try removing the 'final' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateFinalNotAssignedError =
    const Template<Message Function(String name)>(
  "FinalNotAssignedError",
  problemMessageTemplate:
      r"""Final variable '#name' must be assigned before it can be used.""",
  withArguments: _withArgumentsFinalNotAssignedError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFinalNotAssignedError = const Code(
  "FinalNotAssignedError",
  analyzerCodes: <String>["READ_POTENTIALLY_UNASSIGNED_FINAL"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFinalNotAssignedError(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeFinalNotAssignedError,
    problemMessage:
        """Final variable '${name}' must be assigned before it can be used.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateFinalPossiblyAssignedError =
    const Template<Message Function(String name)>(
  "FinalPossiblyAssignedError",
  problemMessageTemplate:
      r"""Final variable '#name' might already be assigned at this point.""",
  withArguments: _withArgumentsFinalPossiblyAssignedError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFinalPossiblyAssignedError = const Code(
  "FinalPossiblyAssignedError",
  analyzerCodes: <String>["ASSIGNMENT_TO_FINAL_LOCAL"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFinalPossiblyAssignedError(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeFinalPossiblyAssignedError,
    problemMessage:
        """Final variable '${name}' might already be assigned at this point.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeForInLoopExactlyOneVariable = messageForInLoopExactlyOneVariable;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageForInLoopExactlyOneVariable = const MessageCode(
  "ForInLoopExactlyOneVariable",
  problemMessage: r"""A for-in loop can't have more than one loop variable.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeForInLoopNotAssignable = messageForInLoopNotAssignable;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageForInLoopNotAssignable = const MessageCode(
  "ForInLoopNotAssignable",
  problemMessage:
      r"""Can't assign to this, so it can't be used in a for-in loop.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeForInLoopWithConstVariable = messageForInLoopWithConstVariable;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageForInLoopWithConstVariable = const MessageCode(
  "ForInLoopWithConstVariable",
  analyzerCodes: <String>["FOR_IN_WITH_CONST_VARIABLE"],
  problemMessage: r"""A for-in loop-variable can't be 'const'.""",
  correctionMessage: r"""Try removing the 'const' modifier.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFunctionTypeDefaultValue = messageFunctionTypeDefaultValue;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFunctionTypeDefaultValue = const MessageCode(
  "FunctionTypeDefaultValue",
  analyzerCodes: <String>["DEFAULT_VALUE_IN_FUNCTION_TYPE"],
  problemMessage: r"""Can't have a default value in a function type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeFunctionTypedParameterVar = messageFunctionTypedParameterVar;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFunctionTypedParameterVar = const MessageCode(
  "FunctionTypedParameterVar",
  index: 119,
  problemMessage:
      r"""Function-typed parameters can't specify 'const', 'final' or 'var' in place of a return type.""",
  correctionMessage: r"""Try replacing the keyword with a return type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeGeneratorReturnsValue = messageGeneratorReturnsValue;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageGeneratorReturnsValue = const MessageCode(
  "GeneratorReturnsValue",
  analyzerCodes: <String>["RETURN_IN_GENERATOR"],
  problemMessage: r"""'sync*' and 'async*' can't return a value.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeGenericFunctionTypeInBound = messageGenericFunctionTypeInBound;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageGenericFunctionTypeInBound = const MessageCode(
  "GenericFunctionTypeInBound",
  analyzerCodes: <String>["GENERIC_FUNCTION_TYPE_CANNOT_BE_BOUND"],
  problemMessage:
      r"""Type variables can't have generic function types in their bounds.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeGenericFunctionTypeUsedAsActualTypeArgument =
    messageGenericFunctionTypeUsedAsActualTypeArgument;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageGenericFunctionTypeUsedAsActualTypeArgument =
    const MessageCode(
  "GenericFunctionTypeUsedAsActualTypeArgument",
  analyzerCodes: <String>["GENERIC_FUNCTION_CANNOT_BE_TYPE_ARGUMENT"],
  problemMessage:
      r"""A generic function type can't be used as a type argument.""",
  correctionMessage: r"""Try using a non-generic function type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeGetterConstructor = messageGetterConstructor;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageGetterConstructor = const MessageCode(
  "GetterConstructor",
  index: 103,
  problemMessage: r"""Constructors can't be a getter.""",
  correctionMessage: r"""Try removing 'get'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateGetterNotFound =
    const Template<Message Function(String name)>(
  "GetterNotFound",
  problemMessageTemplate: r"""Getter not found: '#name'.""",
  withArguments: _withArgumentsGetterNotFound,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeGetterNotFound = const Code(
  "GetterNotFound",
  analyzerCodes: <String>["UNDEFINED_GETTER"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsGetterNotFound(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeGetterNotFound,
    problemMessage: """Getter not found: '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeGetterWithFormals = messageGetterWithFormals;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageGetterWithFormals = const MessageCode(
  "GetterWithFormals",
  analyzerCodes: <String>["GETTER_WITH_PARAMETERS"],
  problemMessage: r"""A getter can't have formal parameters.""",
  correctionMessage: r"""Try removing '(...)'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeIllegalAssignmentToNonAssignable =
    messageIllegalAssignmentToNonAssignable;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageIllegalAssignmentToNonAssignable = const MessageCode(
  "IllegalAssignmentToNonAssignable",
  index: 45,
  problemMessage: r"""Illegal assignment to non-assignable expression.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeIllegalAsyncGeneratorReturnType =
    messageIllegalAsyncGeneratorReturnType;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageIllegalAsyncGeneratorReturnType = const MessageCode(
  "IllegalAsyncGeneratorReturnType",
  analyzerCodes: <String>["ILLEGAL_ASYNC_GENERATOR_RETURN_TYPE"],
  problemMessage:
      r"""Functions marked 'async*' must have a return type assignable to 'Stream'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeIllegalAsyncGeneratorVoidReturnType =
    messageIllegalAsyncGeneratorVoidReturnType;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageIllegalAsyncGeneratorVoidReturnType =
    const MessageCode(
  "IllegalAsyncGeneratorVoidReturnType",
  problemMessage:
      r"""Functions marked 'async*' can't have return type 'void'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeIllegalAsyncReturnType = messageIllegalAsyncReturnType;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageIllegalAsyncReturnType = const MessageCode(
  "IllegalAsyncReturnType",
  analyzerCodes: <String>["ILLEGAL_ASYNC_RETURN_TYPE"],
  problemMessage:
      r"""Functions marked 'async' must have a return type assignable to 'Future'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateIllegalMixin =
    const Template<Message Function(String name)>(
  "IllegalMixin",
  problemMessageTemplate: r"""The type '#name' can't be mixed in.""",
  withArguments: _withArgumentsIllegalMixin,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeIllegalMixin = const Code(
  "IllegalMixin",
  analyzerCodes: <String>["ILLEGAL_MIXIN"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIllegalMixin(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeIllegalMixin,
    problemMessage: """The type '${name}' can't be mixed in.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateIllegalMixinDueToConstructors =
    const Template<Message Function(String name)>(
  "IllegalMixinDueToConstructors",
  problemMessageTemplate:
      r"""Can't use '#name' as a mixin because it has constructors.""",
  withArguments: _withArgumentsIllegalMixinDueToConstructors,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeIllegalMixinDueToConstructors = const Code(
  "IllegalMixinDueToConstructors",
  analyzerCodes: <String>["MIXIN_DECLARES_CONSTRUCTOR"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIllegalMixinDueToConstructors(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeIllegalMixinDueToConstructors,
    problemMessage:
        """Can't use '${name}' as a mixin because it has constructors.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateIllegalMixinDueToConstructorsCause =
    const Template<Message Function(String name)>(
  "IllegalMixinDueToConstructorsCause",
  problemMessageTemplate:
      r"""This constructor prevents using '#name' as a mixin.""",
  withArguments: _withArgumentsIllegalMixinDueToConstructorsCause,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeIllegalMixinDueToConstructorsCause = const Code(
  "IllegalMixinDueToConstructorsCause",
  severity: Severity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIllegalMixinDueToConstructorsCause(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeIllegalMixinDueToConstructorsCause,
    problemMessage: """This constructor prevents using '${name}' as a mixin.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)>
    templateIllegalPatternAssignmentVariableName =
    const Template<Message Function(Token token)>(
  "IllegalPatternAssignmentVariableName",
  problemMessageTemplate:
      r"""A variable assigned by a pattern assignment can't be named '#lexeme'.""",
  correctionMessageTemplate: r"""Choose a different name.""",
  withArguments: _withArgumentsIllegalPatternAssignmentVariableName,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeIllegalPatternAssignmentVariableName = const Code(
  "IllegalPatternAssignmentVariableName",
  index: 160,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIllegalPatternAssignmentVariableName(Token token) {
  String lexeme = token.lexeme;
  return new Message(
    codeIllegalPatternAssignmentVariableName,
    problemMessage:
        """A variable assigned by a pattern assignment can't be named '${lexeme}'.""",
    correctionMessage: """Choose a different name.""",
    arguments: {
      'lexeme': token,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)>
    templateIllegalPatternIdentifierName =
    const Template<Message Function(Token token)>(
  "IllegalPatternIdentifierName",
  problemMessageTemplate:
      r"""A pattern can't refer to an identifier named '#lexeme'.""",
  correctionMessageTemplate: r"""Match the identifier using '==""",
  withArguments: _withArgumentsIllegalPatternIdentifierName,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeIllegalPatternIdentifierName = const Code(
  "IllegalPatternIdentifierName",
  index: 161,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIllegalPatternIdentifierName(Token token) {
  String lexeme = token.lexeme;
  return new Message(
    codeIllegalPatternIdentifierName,
    problemMessage:
        """A pattern can't refer to an identifier named '${lexeme}'.""",
    correctionMessage: """Match the identifier using '==""",
    arguments: {
      'lexeme': token,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)>
    templateIllegalPatternVariableName =
    const Template<Message Function(Token token)>(
  "IllegalPatternVariableName",
  problemMessageTemplate:
      r"""The variable declared by a variable pattern can't be named '#lexeme'.""",
  correctionMessageTemplate: r"""Choose a different name.""",
  withArguments: _withArgumentsIllegalPatternVariableName,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeIllegalPatternVariableName = const Code(
  "IllegalPatternVariableName",
  index: 159,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIllegalPatternVariableName(Token token) {
  String lexeme = token.lexeme;
  return new Message(
    codeIllegalPatternVariableName,
    problemMessage:
        """The variable declared by a variable pattern can't be named '${lexeme}'.""",
    correctionMessage: """Choose a different name.""",
    arguments: {
      'lexeme': token,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeIllegalSyncGeneratorReturnType =
    messageIllegalSyncGeneratorReturnType;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageIllegalSyncGeneratorReturnType = const MessageCode(
  "IllegalSyncGeneratorReturnType",
  analyzerCodes: <String>["ILLEGAL_SYNC_GENERATOR_RETURN_TYPE"],
  problemMessage:
      r"""Functions marked 'sync*' must have a return type assignable to 'Iterable'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeIllegalSyncGeneratorVoidReturnType =
    messageIllegalSyncGeneratorVoidReturnType;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageIllegalSyncGeneratorVoidReturnType = const MessageCode(
  "IllegalSyncGeneratorVoidReturnType",
  problemMessage:
      r"""Functions marked 'sync*' can't have return type 'void'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String name2)>
    templateImplementMultipleExtensionTypeMembers =
    const Template<Message Function(String name, String name2)>(
  "ImplementMultipleExtensionTypeMembers",
  problemMessageTemplate:
      r"""The extension type '#name' can't inherit the member '#name2' from more than one extension type.""",
  correctionMessageTemplate:
      r"""Try declaring a member '#name2' in '#name' to resolve the conflict.""",
  withArguments: _withArgumentsImplementMultipleExtensionTypeMembers,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeImplementMultipleExtensionTypeMembers = const Code(
  "ImplementMultipleExtensionTypeMembers",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsImplementMultipleExtensionTypeMembers(
    String name, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(
    codeImplementMultipleExtensionTypeMembers,
    problemMessage:
        """The extension type '${name}' can't inherit the member '${name2}' from more than one extension type.""",
    correctionMessage:
        """Try declaring a member '${name2}' in '${name}' to resolve the conflict.""",
    arguments: {
      'name': name,
      'name2': name2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String name2)>
    templateImplementNonExtensionTypeAndExtensionTypeMember =
    const Template<Message Function(String name, String name2)>(
  "ImplementNonExtensionTypeAndExtensionTypeMember",
  problemMessageTemplate:
      r"""The extension type '#name' can't inherit the member '#name2' as both an extension type member and a non-extension type member.""",
  correctionMessageTemplate:
      r"""Try declaring a member '#name2' in '#name' to resolve the conflict.""",
  withArguments: _withArgumentsImplementNonExtensionTypeAndExtensionTypeMember,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeImplementNonExtensionTypeAndExtensionTypeMember = const Code(
  "ImplementNonExtensionTypeAndExtensionTypeMember",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsImplementNonExtensionTypeAndExtensionTypeMember(
    String name, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(
    codeImplementNonExtensionTypeAndExtensionTypeMember,
    problemMessage:
        """The extension type '${name}' can't inherit the member '${name2}' as both an extension type member and a non-extension type member.""",
    correctionMessage:
        """Try declaring a member '${name2}' in '${name}' to resolve the conflict.""",
    arguments: {
      'name': name,
      'name2': name2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeImplementsBeforeExtends = messageImplementsBeforeExtends;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageImplementsBeforeExtends = const MessageCode(
  "ImplementsBeforeExtends",
  index: 44,
  problemMessage:
      r"""The extends clause must be before the implements clause.""",
  correctionMessage:
      r"""Try moving the extends clause before the implements clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeImplementsBeforeOn = messageImplementsBeforeOn;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageImplementsBeforeOn = const MessageCode(
  "ImplementsBeforeOn",
  index: 43,
  problemMessage: r"""The on clause must be before the implements clause.""",
  correctionMessage:
      r"""Try moving the on clause before the implements clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeImplementsBeforeWith = messageImplementsBeforeWith;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageImplementsBeforeWith = const MessageCode(
  "ImplementsBeforeWith",
  index: 42,
  problemMessage: r"""The with clause must be before the implements clause.""",
  correctionMessage:
      r"""Try moving the with clause before the implements clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeImplementsFutureOr = messageImplementsFutureOr;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageImplementsFutureOr = const MessageCode(
  "ImplementsFutureOr",
  problemMessage:
      r"""The type 'FutureOr' can't be used in an 'implements' clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeImplementsNever = messageImplementsNever;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageImplementsNever = const MessageCode(
  "ImplementsNever",
  problemMessage:
      r"""The type 'Never' can't be used in an 'implements' clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, int count)>
    templateImplementsRepeated =
    const Template<Message Function(String name, int count)>(
  "ImplementsRepeated",
  problemMessageTemplate: r"""'#name' can only be implemented once.""",
  correctionMessageTemplate: r"""Try removing #count of the occurrences.""",
  withArguments: _withArgumentsImplementsRepeated,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeImplementsRepeated = const Code(
  "ImplementsRepeated",
  analyzerCodes: <String>["IMPLEMENTS_REPEATED"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsImplementsRepeated(String name, int count) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeImplementsRepeated,
    problemMessage: """'${name}' can only be implemented once.""",
    correctionMessage: """Try removing ${count} of the occurrences.""",
    arguments: {
      'name': name,
      'count': count,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateImplementsSuperClass =
    const Template<Message Function(String name)>(
  "ImplementsSuperClass",
  problemMessageTemplate:
      r"""'#name' can't be used in both 'extends' and 'implements' clauses.""",
  correctionMessageTemplate: r"""Try removing one of the occurrences.""",
  withArguments: _withArgumentsImplementsSuperClass,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeImplementsSuperClass = const Code(
  "ImplementsSuperClass",
  analyzerCodes: <String>["IMPLEMENTS_SUPER_CLASS"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsImplementsSuperClass(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeImplementsSuperClass,
    problemMessage:
        """'${name}' can't be used in both 'extends' and 'implements' clauses.""",
    correctionMessage: """Try removing one of the occurrences.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeImplementsVoid = messageImplementsVoid;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageImplementsVoid = const MessageCode(
  "ImplementsVoid",
  problemMessage:
      r"""The type 'void' can't be used in an 'implements' clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String name2, String name3)>
    templateImplicitMixinOverride =
    const Template<Message Function(String name, String name2, String name3)>(
  "ImplicitMixinOverride",
  problemMessageTemplate:
      r"""Applying the mixin '#name' to '#name2' introduces an erroneous override of '#name3'.""",
  withArguments: _withArgumentsImplicitMixinOverride,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeImplicitMixinOverride = const Code(
  "ImplicitMixinOverride",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsImplicitMixinOverride(
    String name, String name2, String name3) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  if (name3.isEmpty) throw 'No name provided';
  name3 = demangleMixinApplicationName(name3);
  return new Message(
    codeImplicitMixinOverride,
    problemMessage:
        """Applying the mixin '${name}' to '${name2}' introduces an erroneous override of '${name3}'.""",
    arguments: {
      'name': name,
      'name2': name2,
      'name3': name3,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeImplicitSuperCallOfNonMethod =
    messageImplicitSuperCallOfNonMethod;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageImplicitSuperCallOfNonMethod = const MessageCode(
  "ImplicitSuperCallOfNonMethod",
  analyzerCodes: <String>["IMPLICIT_CALL_OF_NON_METHOD"],
  problemMessage:
      r"""Cannot invoke `super` because it declares 'call' to be something other than a method.""",
  correctionMessage:
      r"""Try changing 'call' to a method or explicitly invoke 'call'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateImplicitSuperInitializerMissingArguments =
    const Template<Message Function(String name)>(
  "ImplicitSuperInitializerMissingArguments",
  problemMessageTemplate:
      r"""The implicitly called unnamed constructor from '#name' has required parameters.""",
  correctionMessageTemplate:
      r"""Try adding an explicit super initializer with the required arguments.""",
  withArguments: _withArgumentsImplicitSuperInitializerMissingArguments,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeImplicitSuperInitializerMissingArguments = const Code(
  "ImplicitSuperInitializerMissingArguments",
  analyzerCodes: <String>["IMPLICIT_SUPER_INITIALIZER_MISSING_ARGUMENTS"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsImplicitSuperInitializerMissingArguments(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeImplicitSuperInitializerMissingArguments,
    problemMessage:
        """The implicitly called unnamed constructor from '${name}' has required parameters.""",
    correctionMessage:
        """Try adding an explicit super initializer with the required arguments.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeImportAfterPart = messageImportAfterPart;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageImportAfterPart = const MessageCode(
  "ImportAfterPart",
  index: 10,
  problemMessage: r"""Import directives must precede part directives.""",
  correctionMessage:
      r"""Try moving the import directives before the part directives.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri_, String string, String string2)>
    templateImportChainContext =
    const Template<Message Function(Uri uri_, String string, String string2)>(
  "ImportChainContext",
  problemMessageTemplate:
      r"""The unavailable library '#uri' is imported through these packages:

#string
Detailed import paths for (some of) the these imports:

#string2""",
  withArguments: _withArgumentsImportChainContext,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeImportChainContext = const Code(
  "ImportChainContext",
  severity: Severity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsImportChainContext(
    Uri uri_, String string, String string2) {
  String? uri = relativizeUri(uri_);
  if (string.isEmpty) throw 'No string provided';
  if (string2.isEmpty) throw 'No string provided';
  return new Message(
    codeImportChainContext,
    problemMessage:
        """The unavailable library '${uri}' is imported through these packages:

${string}
Detailed import paths for (some of) the these imports:

${string2}""",
    arguments: {
      'uri': uri_,
      'string': string,
      'string2': string2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri_, String string)>
    templateImportChainContextSimple =
    const Template<Message Function(Uri uri_, String string)>(
  "ImportChainContextSimple",
  problemMessageTemplate:
      r"""The unavailable library '#uri' is imported through these paths:

#string""",
  withArguments: _withArgumentsImportChainContextSimple,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeImportChainContextSimple = const Code(
  "ImportChainContextSimple",
  severity: Severity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsImportChainContextSimple(Uri uri_, String string) {
  String? uri = relativizeUri(uri_);
  if (string.isEmpty) throw 'No string provided';
  return new Message(
    codeImportChainContextSimple,
    problemMessage:
        """The unavailable library '${uri}' is imported through these paths:

${string}""",
    arguments: {
      'uri': uri_,
      'string': string,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeIncorrectTypeArgumentVariable =
    messageIncorrectTypeArgumentVariable;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageIncorrectTypeArgumentVariable = const MessageCode(
  "IncorrectTypeArgumentVariable",
  severity: Severity.context,
  problemMessage:
      r"""This is the type variable whose bound isn't conformed to.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)>
    templateIncrementalCompilerIllegalParameter =
    const Template<Message Function(String string)>(
  "IncrementalCompilerIllegalParameter",
  problemMessageTemplate:
      r"""Illegal parameter name '#string' found during expression compilation.""",
  withArguments: _withArgumentsIncrementalCompilerIllegalParameter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeIncrementalCompilerIllegalParameter = const Code(
  "IncrementalCompilerIllegalParameter",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIncrementalCompilerIllegalParameter(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(
    codeIncrementalCompilerIllegalParameter,
    problemMessage:
        """Illegal parameter name '${string}' found during expression compilation.""",
    arguments: {
      'string': string,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)>
    templateIncrementalCompilerIllegalTypeParameter =
    const Template<Message Function(String string)>(
  "IncrementalCompilerIllegalTypeParameter",
  problemMessageTemplate:
      r"""Illegal type parameter name '#string' found during expression compilation.""",
  withArguments: _withArgumentsIncrementalCompilerIllegalTypeParameter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeIncrementalCompilerIllegalTypeParameter = const Code(
  "IncrementalCompilerIllegalTypeParameter",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIncrementalCompilerIllegalTypeParameter(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(
    codeIncrementalCompilerIllegalTypeParameter,
    problemMessage:
        """Illegal type parameter name '${string}' found during expression compilation.""",
    arguments: {
      'string': string,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInheritedMembersConflict = messageInheritedMembersConflict;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInheritedMembersConflict = const MessageCode(
  "InheritedMembersConflict",
  analyzerCodes: <String>["CONFLICTS_WITH_INHERITED_MEMBER"],
  problemMessage: r"""Can't inherit members that conflict with each other.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInheritedMembersConflictCause1 =
    messageInheritedMembersConflictCause1;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInheritedMembersConflictCause1 = const MessageCode(
  "InheritedMembersConflictCause1",
  severity: Severity.context,
  problemMessage: r"""This is one inherited member.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInheritedMembersConflictCause2 =
    messageInheritedMembersConflictCause2;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInheritedMembersConflictCause2 = const MessageCode(
  "InheritedMembersConflictCause2",
  severity: Severity.context,
  problemMessage: r"""This is the other inherited member.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String name2)>
    templateInheritedRestrictedMemberOfEnumImplementer =
    const Template<Message Function(String name, String name2)>(
  "InheritedRestrictedMemberOfEnumImplementer",
  problemMessageTemplate:
      r"""A concrete instance member named '#name' can't be inherited from '#name2' in a class that implements 'Enum'.""",
  withArguments: _withArgumentsInheritedRestrictedMemberOfEnumImplementer,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInheritedRestrictedMemberOfEnumImplementer = const Code(
  "InheritedRestrictedMemberOfEnumImplementer",
  analyzerCodes: <String>["ILLEGAL_CONCRETE_ENUM_MEMBER"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInheritedRestrictedMemberOfEnumImplementer(
    String name, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(
    codeInheritedRestrictedMemberOfEnumImplementer,
    problemMessage:
        """A concrete instance member named '${name}' can't be inherited from '${name2}' in a class that implements 'Enum'.""",
    arguments: {
      'name': name,
      'name2': name2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string, Uri uri_)>
    templateInitializeFromDillNotSelfContained =
    const Template<Message Function(String string, Uri uri_)>(
  "InitializeFromDillNotSelfContained",
  problemMessageTemplate:
      r"""Tried to initialize from a previous compilation (#string), but the file was not self-contained. This might be a bug.

The Dart team would greatly appreciate it if you would take a moment to report this problem at http://dartbug.com/new.
If you are comfortable with it, it would improve the chances of fixing any bug if you included the file #uri in your error report, but be aware that this file includes your source code.
Either way, you should probably delete the file so it doesn't use unnecessary disk space.""",
  withArguments: _withArgumentsInitializeFromDillNotSelfContained,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInitializeFromDillNotSelfContained = const Code(
  "InitializeFromDillNotSelfContained",
  severity: Severity.warning,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInitializeFromDillNotSelfContained(
    String string, Uri uri_) {
  if (string.isEmpty) throw 'No string provided';
  String? uri = relativizeUri(uri_);
  return new Message(
    codeInitializeFromDillNotSelfContained,
    problemMessage:
        """Tried to initialize from a previous compilation (${string}), but the file was not self-contained. This might be a bug.

The Dart team would greatly appreciate it if you would take a moment to report this problem at http://dartbug.com/new.
If you are comfortable with it, it would improve the chances of fixing any bug if you included the file ${uri} in your error report, but be aware that this file includes your source code.
Either way, you should probably delete the file so it doesn't use unnecessary disk space.""",
    arguments: {
      'string': string,
      'uri': uri_,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)>
    templateInitializeFromDillNotSelfContainedNoDump =
    const Template<Message Function(String string)>(
  "InitializeFromDillNotSelfContainedNoDump",
  problemMessageTemplate:
      r"""Tried to initialize from a previous compilation (#string), but the file was not self-contained. This might be a bug.

The Dart team would greatly appreciate it if you would take a moment to report this problem at http://dartbug.com/new.""",
  withArguments: _withArgumentsInitializeFromDillNotSelfContainedNoDump,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInitializeFromDillNotSelfContainedNoDump = const Code(
  "InitializeFromDillNotSelfContainedNoDump",
  severity: Severity.warning,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInitializeFromDillNotSelfContainedNoDump(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(
    codeInitializeFromDillNotSelfContainedNoDump,
    problemMessage:
        """Tried to initialize from a previous compilation (${string}), but the file was not self-contained. This might be a bug.

The Dart team would greatly appreciate it if you would take a moment to report this problem at http://dartbug.com/new.""",
    arguments: {
      'string': string,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(String string, String string2, String string3,
        Uri uri_)> templateInitializeFromDillUnknownProblem = const Template<
    Message Function(String string, String string2, String string3, Uri uri_)>(
  "InitializeFromDillUnknownProblem",
  problemMessageTemplate:
      r"""Tried to initialize from a previous compilation (#string), but couldn't.
Error message was '#string2'.
Stacktrace included '#string3'.
This might be a bug.

The Dart team would greatly appreciate it if you would take a moment to report this problem at http://dartbug.com/new.
If you are comfortable with it, it would improve the chances of fixing any bug if you included the file #uri in your error report, but be aware that this file includes your source code.
Either way, you should probably delete the file so it doesn't use unnecessary disk space.""",
  withArguments: _withArgumentsInitializeFromDillUnknownProblem,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInitializeFromDillUnknownProblem = const Code(
  "InitializeFromDillUnknownProblem",
  severity: Severity.warning,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInitializeFromDillUnknownProblem(
    String string, String string2, String string3, Uri uri_) {
  if (string.isEmpty) throw 'No string provided';
  if (string2.isEmpty) throw 'No string provided';
  if (string3.isEmpty) throw 'No string provided';
  String? uri = relativizeUri(uri_);
  return new Message(
    codeInitializeFromDillUnknownProblem,
    problemMessage:
        """Tried to initialize from a previous compilation (${string}), but couldn't.
Error message was '${string2}'.
Stacktrace included '${string3}'.
This might be a bug.

The Dart team would greatly appreciate it if you would take a moment to report this problem at http://dartbug.com/new.
If you are comfortable with it, it would improve the chances of fixing any bug if you included the file ${uri} in your error report, but be aware that this file includes your source code.
Either way, you should probably delete the file so it doesn't use unnecessary disk space.""",
    arguments: {
      'string': string,
      'string2': string2,
      'string3': string3,
      'uri': uri_,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string, String string2, String string3)>
    templateInitializeFromDillUnknownProblemNoDump = const Template<
        Message Function(String string, String string2, String string3)>(
  "InitializeFromDillUnknownProblemNoDump",
  problemMessageTemplate:
      r"""Tried to initialize from a previous compilation (#string), but couldn't.
Error message was '#string2'.
Stacktrace included '#string3'.
This might be a bug.

The Dart team would greatly appreciate it if you would take a moment to report this problem at http://dartbug.com/new.""",
  withArguments: _withArgumentsInitializeFromDillUnknownProblemNoDump,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInitializeFromDillUnknownProblemNoDump = const Code(
  "InitializeFromDillUnknownProblemNoDump",
  severity: Severity.warning,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInitializeFromDillUnknownProblemNoDump(
    String string, String string2, String string3) {
  if (string.isEmpty) throw 'No string provided';
  if (string2.isEmpty) throw 'No string provided';
  if (string3.isEmpty) throw 'No string provided';
  return new Message(
    codeInitializeFromDillUnknownProblemNoDump,
    problemMessage:
        """Tried to initialize from a previous compilation (${string}), but couldn't.
Error message was '${string2}'.
Stacktrace included '${string3}'.
This might be a bug.

The Dart team would greatly appreciate it if you would take a moment to report this problem at http://dartbug.com/new.""",
    arguments: {
      'string': string,
      'string2': string2,
      'string3': string3,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInitializedVariableInForEach =
    messageInitializedVariableInForEach;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInitializedVariableInForEach = const MessageCode(
  "InitializedVariableInForEach",
  index: 82,
  problemMessage:
      r"""The loop variable in a for-each loop can't be initialized.""",
  correctionMessage:
      r"""Try removing the initializer, or using a different kind of loop.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateInitializerForStaticField =
    const Template<Message Function(String name)>(
  "InitializerForStaticField",
  problemMessageTemplate: r"""'#name' isn't an instance field of this class.""",
  withArguments: _withArgumentsInitializerForStaticField,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInitializerForStaticField = const Code(
  "InitializerForStaticField",
  analyzerCodes: <String>["INITIALIZER_FOR_STATIC_FIELD"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInitializerForStaticField(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeInitializerForStaticField,
    problemMessage: """'${name}' isn't an instance field of this class.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInitializingFormalTypeMismatchField =
    messageInitializingFormalTypeMismatchField;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInitializingFormalTypeMismatchField =
    const MessageCode(
  "InitializingFormalTypeMismatchField",
  severity: Severity.context,
  problemMessage: r"""The field that corresponds to the parameter.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri_)> templateInputFileNotFound =
    const Template<Message Function(Uri uri_)>(
  "InputFileNotFound",
  problemMessageTemplate: r"""Input file not found: #uri.""",
  withArguments: _withArgumentsInputFileNotFound,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInputFileNotFound = const Code(
  "InputFileNotFound",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInputFileNotFound(Uri uri_) {
  String? uri = relativizeUri(uri_);
  return new Message(
    codeInputFileNotFound,
    problemMessage: """Input file not found: ${uri}.""",
    arguments: {
      'uri': uri_,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateInstanceAndSynthesizedStaticConflict =
    const Template<Message Function(String name)>(
  "InstanceAndSynthesizedStaticConflict",
  problemMessageTemplate:
      r"""This instance member conflicts with the synthesized static member called '#name'.""",
  withArguments: _withArgumentsInstanceAndSynthesizedStaticConflict,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInstanceAndSynthesizedStaticConflict = const Code(
  "InstanceAndSynthesizedStaticConflict",
  analyzerCodes: <String>["CONFLICTING_STATIC_AND_INSTANCE"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInstanceAndSynthesizedStaticConflict(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeInstanceAndSynthesizedStaticConflict,
    problemMessage:
        """This instance member conflicts with the synthesized static member called '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateInstanceConflictsWithStatic =
    const Template<Message Function(String name)>(
  "InstanceConflictsWithStatic",
  problemMessageTemplate:
      r"""Instance property '#name' conflicts with static property of the same name.""",
  withArguments: _withArgumentsInstanceConflictsWithStatic,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInstanceConflictsWithStatic = const Code(
  "InstanceConflictsWithStatic",
  analyzerCodes: <String>["CONFLICTS_WITH_MEMBER"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInstanceConflictsWithStatic(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeInstanceConflictsWithStatic,
    problemMessage:
        """Instance property '${name}' conflicts with static property of the same name.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateInstanceConflictsWithStaticCause =
    const Template<Message Function(String name)>(
  "InstanceConflictsWithStaticCause",
  problemMessageTemplate: r"""Conflicting static property '#name'.""",
  withArguments: _withArgumentsInstanceConflictsWithStaticCause,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInstanceConflictsWithStaticCause = const Code(
  "InstanceConflictsWithStaticCause",
  severity: Severity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInstanceConflictsWithStaticCause(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeInstanceConflictsWithStaticCause,
    problemMessage: """Conflicting static property '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(int count, int count2)>
    templateInstantiationTooFewArguments =
    const Template<Message Function(int count, int count2)>(
  "InstantiationTooFewArguments",
  problemMessageTemplate:
      r"""Too few type arguments: #count required, #count2 given.""",
  correctionMessageTemplate: r"""Try adding the missing type arguments.""",
  withArguments: _withArgumentsInstantiationTooFewArguments,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInstantiationTooFewArguments = const Code(
  "InstantiationTooFewArguments",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInstantiationTooFewArguments(int count, int count2) {
  return new Message(
    codeInstantiationTooFewArguments,
    problemMessage:
        """Too few type arguments: ${count} required, ${count2} given.""",
    correctionMessage: """Try adding the missing type arguments.""",
    arguments: {
      'count': count,
      'count2': count2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(int count, int count2)>
    templateInstantiationTooManyArguments =
    const Template<Message Function(int count, int count2)>(
  "InstantiationTooManyArguments",
  problemMessageTemplate:
      r"""Too many type arguments: #count allowed, but #count2 found.""",
  correctionMessageTemplate: r"""Try removing the extra type arguments.""",
  withArguments: _withArgumentsInstantiationTooManyArguments,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInstantiationTooManyArguments = const Code(
  "InstantiationTooManyArguments",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInstantiationTooManyArguments(int count, int count2) {
  return new Message(
    codeInstantiationTooManyArguments,
    problemMessage:
        """Too many type arguments: ${count} allowed, but ${count2} found.""",
    correctionMessage: """Try removing the extra type arguments.""",
    arguments: {
      'count': count,
      'count2': count2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)>
    templateIntegerLiteralIsOutOfRange =
    const Template<Message Function(String string)>(
  "IntegerLiteralIsOutOfRange",
  problemMessageTemplate:
      r"""The integer literal #string can't be represented in 64 bits.""",
  correctionMessageTemplate:
      r"""Try using the BigInt class if you need an integer larger than 9,223,372,036,854,775,807 or less than -9,223,372,036,854,775,808.""",
  withArguments: _withArgumentsIntegerLiteralIsOutOfRange,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeIntegerLiteralIsOutOfRange = const Code(
  "IntegerLiteralIsOutOfRange",
  analyzerCodes: <String>["INTEGER_LITERAL_OUT_OF_RANGE"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIntegerLiteralIsOutOfRange(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(
    codeIntegerLiteralIsOutOfRange,
    problemMessage:
        """The integer literal ${string} can't be represented in 64 bits.""",
    correctionMessage:
        """Try using the BigInt class if you need an integer larger than 9,223,372,036,854,775,807 or less than -9,223,372,036,854,775,808.""",
    arguments: {
      'string': string,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String name2)>
    templateInterfaceCheck =
    const Template<Message Function(String name, String name2)>(
  "InterfaceCheck",
  problemMessageTemplate:
      r"""The implementation of '#name' in the non-abstract class '#name2' does not conform to its interface.""",
  withArguments: _withArgumentsInterfaceCheck,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInterfaceCheck = const Code(
  "InterfaceCheck",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInterfaceCheck(String name, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(
    codeInterfaceCheck,
    problemMessage:
        """The implementation of '${name}' in the non-abstract class '${name2}' does not conform to its interface.""",
    arguments: {
      'name': name,
      'name2': name2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateInterfaceClassExtendedOutsideOfLibrary =
    const Template<Message Function(String name)>(
  "InterfaceClassExtendedOutsideOfLibrary",
  problemMessageTemplate:
      r"""The class '#name' can't be extended outside of its library because it's an interface class.""",
  withArguments: _withArgumentsInterfaceClassExtendedOutsideOfLibrary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInterfaceClassExtendedOutsideOfLibrary = const Code(
  "InterfaceClassExtendedOutsideOfLibrary",
  analyzerCodes: <String>["INTERFACE_CLASS_EXTENDED_OUTSIDE_OF_LIBRARY"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInterfaceClassExtendedOutsideOfLibrary(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeInterfaceClassExtendedOutsideOfLibrary,
    problemMessage:
        """The class '${name}' can't be extended outside of its library because it's an interface class.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInterfaceEnum = messageInterfaceEnum;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInterfaceEnum = const MessageCode(
  "InterfaceEnum",
  index: 157,
  problemMessage: r"""Enums can't be declared to be 'interface'.""",
  correctionMessage: r"""Try removing the keyword 'interface'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInterfaceMixin = messageInterfaceMixin;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInterfaceMixin = const MessageCode(
  "InterfaceMixin",
  index: 147,
  problemMessage: r"""A mixin can't be declared 'interface'.""",
  correctionMessage: r"""Try removing the 'interface' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInterfaceMixinClass = messageInterfaceMixinClass;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInterfaceMixinClass = const MessageCode(
  "InterfaceMixinClass",
  index: 143,
  problemMessage: r"""A mixin class can't be declared 'interface'.""",
  correctionMessage: r"""Try removing the 'interface' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInternalProblemAlreadyInitialized =
    messageInternalProblemAlreadyInitialized;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInternalProblemAlreadyInitialized = const MessageCode(
  "InternalProblemAlreadyInitialized",
  severity: Severity.internalProblem,
  problemMessage:
      r"""Attempt to set initializer on field without initializer.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInternalProblemBodyOnAbstractMethod =
    messageInternalProblemBodyOnAbstractMethod;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInternalProblemBodyOnAbstractMethod =
    const MessageCode(
  "InternalProblemBodyOnAbstractMethod",
  severity: Severity.internalProblem,
  problemMessage: r"""Attempting to set body on abstract method.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, Uri uri_)>
    templateInternalProblemConstructorNotFound =
    const Template<Message Function(String name, Uri uri_)>(
  "InternalProblemConstructorNotFound",
  problemMessageTemplate: r"""No constructor named '#name' in '#uri'.""",
  withArguments: _withArgumentsInternalProblemConstructorNotFound,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInternalProblemConstructorNotFound = const Code(
  "InternalProblemConstructorNotFound",
  severity: Severity.internalProblem,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemConstructorNotFound(
    String name, Uri uri_) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  String? uri = relativizeUri(uri_);
  return new Message(
    codeInternalProblemConstructorNotFound,
    problemMessage: """No constructor named '${name}' in '${uri}'.""",
    arguments: {
      'name': name,
      'uri': uri_,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)>
    templateInternalProblemContextSeverity =
    const Template<Message Function(String string)>(
  "InternalProblemContextSeverity",
  problemMessageTemplate:
      r"""Non-context message has context severity: #string""",
  withArguments: _withArgumentsInternalProblemContextSeverity,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInternalProblemContextSeverity = const Code(
  "InternalProblemContextSeverity",
  severity: Severity.internalProblem,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemContextSeverity(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(
    codeInternalProblemContextSeverity,
    problemMessage: """Non-context message has context severity: ${string}""",
    arguments: {
      'string': string,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String string)>
    templateInternalProblemDebugAbort =
    const Template<Message Function(String name, String string)>(
  "InternalProblemDebugAbort",
  problemMessageTemplate: r"""Compilation aborted due to fatal '#name' at:
#string""",
  withArguments: _withArgumentsInternalProblemDebugAbort,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInternalProblemDebugAbort = const Code(
  "InternalProblemDebugAbort",
  severity: Severity.internalProblem,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemDebugAbort(String name, String string) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (string.isEmpty) throw 'No string provided';
  return new Message(
    codeInternalProblemDebugAbort,
    problemMessage: """Compilation aborted due to fatal '${name}' at:
${string}""",
    arguments: {
      'name': name,
      'string': string,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInternalProblemExtendingUnmodifiableScope =
    messageInternalProblemExtendingUnmodifiableScope;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInternalProblemExtendingUnmodifiableScope =
    const MessageCode(
  "InternalProblemExtendingUnmodifiableScope",
  severity: Severity.internalProblem,
  problemMessage: r"""Can't extend an unmodifiable scope.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInternalProblemLabelUsageInVariablesDeclaration =
    messageInternalProblemLabelUsageInVariablesDeclaration;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInternalProblemLabelUsageInVariablesDeclaration =
    const MessageCode(
  "InternalProblemLabelUsageInVariablesDeclaration",
  severity: Severity.internalProblem,
  problemMessage:
      r"""Unexpected usage of label inside declaration of variables.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInternalProblemMissingContext =
    messageInternalProblemMissingContext;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInternalProblemMissingContext = const MessageCode(
  "InternalProblemMissingContext",
  severity: Severity.internalProblem,
  problemMessage: r"""Compiler cannot run without a compiler context.""",
  correctionMessage:
      r"""Are calls to the compiler wrapped in CompilerContext.runInContext?""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateInternalProblemNotFound =
    const Template<Message Function(String name)>(
  "InternalProblemNotFound",
  problemMessageTemplate: r"""Couldn't find '#name'.""",
  withArguments: _withArgumentsInternalProblemNotFound,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInternalProblemNotFound = const Code(
  "InternalProblemNotFound",
  severity: Severity.internalProblem,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemNotFound(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeInternalProblemNotFound,
    problemMessage: """Couldn't find '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String name2)>
    templateInternalProblemNotFoundIn =
    const Template<Message Function(String name, String name2)>(
  "InternalProblemNotFoundIn",
  problemMessageTemplate: r"""Couldn't find '#name' in '#name2'.""",
  withArguments: _withArgumentsInternalProblemNotFoundIn,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInternalProblemNotFoundIn = const Code(
  "InternalProblemNotFoundIn",
  severity: Severity.internalProblem,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemNotFoundIn(String name, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(
    codeInternalProblemNotFoundIn,
    problemMessage: """Couldn't find '${name}' in '${name2}'.""",
    arguments: {
      'name': name,
      'name2': name2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInternalProblemOmittedTypeNameInConstructorReference =
    messageInternalProblemOmittedTypeNameInConstructorReference;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInternalProblemOmittedTypeNameInConstructorReference =
    const MessageCode(
  "InternalProblemOmittedTypeNameInConstructorReference",
  severity: Severity.internalProblem,
  problemMessage:
      r"""Unsupported omission of the type name in a constructor reference outside of an enum element declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInternalProblemPreviousTokenNotFound =
    messageInternalProblemPreviousTokenNotFound;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInternalProblemPreviousTokenNotFound =
    const MessageCode(
  "InternalProblemPreviousTokenNotFound",
  severity: Severity.internalProblem,
  problemMessage: r"""Couldn't find previous token.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateInternalProblemPrivateConstructorAccess =
    const Template<Message Function(String name)>(
  "InternalProblemPrivateConstructorAccess",
  problemMessageTemplate: r"""Can't access private constructor '#name'.""",
  withArguments: _withArgumentsInternalProblemPrivateConstructorAccess,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInternalProblemPrivateConstructorAccess = const Code(
  "InternalProblemPrivateConstructorAccess",
  severity: Severity.internalProblem,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemPrivateConstructorAccess(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeInternalProblemPrivateConstructorAccess,
    problemMessage: """Can't access private constructor '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInternalProblemProvidedBothCompileSdkAndSdkSummary =
    messageInternalProblemProvidedBothCompileSdkAndSdkSummary;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInternalProblemProvidedBothCompileSdkAndSdkSummary =
    const MessageCode(
  "InternalProblemProvidedBothCompileSdkAndSdkSummary",
  severity: Severity.internalProblem,
  problemMessage:
      r"""The compileSdk and sdkSummary options are mutually exclusive""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String string)>
    templateInternalProblemStackNotEmpty =
    const Template<Message Function(String name, String string)>(
  "InternalProblemStackNotEmpty",
  problemMessageTemplate: r"""#name.stack isn't empty:
  #string""",
  withArguments: _withArgumentsInternalProblemStackNotEmpty,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInternalProblemStackNotEmpty = const Code(
  "InternalProblemStackNotEmpty",
  severity: Severity.internalProblem,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemStackNotEmpty(String name, String string) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (string.isEmpty) throw 'No string provided';
  return new Message(
    codeInternalProblemStackNotEmpty,
    problemMessage: """${name}.stack isn't empty:
  ${string}""",
    arguments: {
      'name': name,
      'string': string,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string, String string2)>
    templateInternalProblemUnexpected =
    const Template<Message Function(String string, String string2)>(
  "InternalProblemUnexpected",
  problemMessageTemplate: r"""Expected '#string', but got '#string2'.""",
  withArguments: _withArgumentsInternalProblemUnexpected,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInternalProblemUnexpected = const Code(
  "InternalProblemUnexpected",
  severity: Severity.internalProblem,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemUnexpected(String string, String string2) {
  if (string.isEmpty) throw 'No string provided';
  if (string2.isEmpty) throw 'No string provided';
  return new Message(
    codeInternalProblemUnexpected,
    problemMessage: """Expected '${string}', but got '${string2}'.""",
    arguments: {
      'string': string,
      'string2': string2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string, String string2)>
    templateInternalProblemUnhandled =
    const Template<Message Function(String string, String string2)>(
  "InternalProblemUnhandled",
  problemMessageTemplate: r"""Unhandled #string in #string2.""",
  withArguments: _withArgumentsInternalProblemUnhandled,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInternalProblemUnhandled = const Code(
  "InternalProblemUnhandled",
  severity: Severity.internalProblem,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemUnhandled(String string, String string2) {
  if (string.isEmpty) throw 'No string provided';
  if (string2.isEmpty) throw 'No string provided';
  return new Message(
    codeInternalProblemUnhandled,
    problemMessage: """Unhandled ${string} in ${string2}.""",
    arguments: {
      'string': string,
      'string2': string2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)>
    templateInternalProblemUnimplemented =
    const Template<Message Function(String string)>(
  "InternalProblemUnimplemented",
  problemMessageTemplate: r"""Unimplemented #string.""",
  withArguments: _withArgumentsInternalProblemUnimplemented,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInternalProblemUnimplemented = const Code(
  "InternalProblemUnimplemented",
  severity: Severity.internalProblem,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemUnimplemented(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(
    codeInternalProblemUnimplemented,
    problemMessage: """Unimplemented ${string}.""",
    arguments: {
      'string': string,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateInternalProblemUnsupported =
    const Template<Message Function(String name)>(
  "InternalProblemUnsupported",
  problemMessageTemplate: r"""Unsupported operation: '#name'.""",
  withArguments: _withArgumentsInternalProblemUnsupported,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInternalProblemUnsupported = const Code(
  "InternalProblemUnsupported",
  severity: Severity.internalProblem,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemUnsupported(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeInternalProblemUnsupported,
    problemMessage: """Unsupported operation: '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri_)>
    templateInternalProblemUriMissingScheme =
    const Template<Message Function(Uri uri_)>(
  "InternalProblemUriMissingScheme",
  problemMessageTemplate: r"""The URI '#uri' has no scheme.""",
  withArguments: _withArgumentsInternalProblemUriMissingScheme,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInternalProblemUriMissingScheme = const Code(
  "InternalProblemUriMissingScheme",
  severity: Severity.internalProblem,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemUriMissingScheme(Uri uri_) {
  String? uri = relativizeUri(uri_);
  return new Message(
    codeInternalProblemUriMissingScheme,
    problemMessage: """The URI '${uri}' has no scheme.""",
    arguments: {
      'uri': uri_,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)>
    templateInternalProblemVerificationError =
    const Template<Message Function(String string)>(
  "InternalProblemVerificationError",
  problemMessageTemplate: r"""Verification of the generated program failed:
#string""",
  withArguments: _withArgumentsInternalProblemVerificationError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInternalProblemVerificationError = const Code(
  "InternalProblemVerificationError",
  severity: Severity.internalProblem,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemVerificationError(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(
    codeInternalProblemVerificationError,
    problemMessage: """Verification of the generated program failed:
${string}""",
    arguments: {
      'string': string,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInterpolationInUri = messageInterpolationInUri;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInterpolationInUri = const MessageCode(
  "InterpolationInUri",
  analyzerCodes: <String>["INVALID_LITERAL_IN_CONFIGURATION"],
  problemMessage: r"""Can't use string interpolation in a URI.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInvalidAugmentSuper = messageInvalidAugmentSuper;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidAugmentSuper = const MessageCode(
  "InvalidAugmentSuper",
  problemMessage:
      r"""'augment super' is only allowed in member augmentations.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInvalidAwaitFor = messageInvalidAwaitFor;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidAwaitFor = const MessageCode(
  "InvalidAwaitFor",
  index: 9,
  problemMessage:
      r"""The keyword 'await' isn't allowed for a normal 'for' statement.""",
  correctionMessage:
      r"""Try removing the keyword, or use a for-each statement.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateInvalidBreakTarget =
    const Template<Message Function(String name)>(
  "InvalidBreakTarget",
  problemMessageTemplate: r"""Can't break to '#name'.""",
  withArguments: _withArgumentsInvalidBreakTarget,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInvalidBreakTarget = const Code(
  "InvalidBreakTarget",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidBreakTarget(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeInvalidBreakTarget,
    problemMessage: """Can't break to '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInvalidCatchArguments = messageInvalidCatchArguments;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidCatchArguments = const MessageCode(
  "InvalidCatchArguments",
  analyzerCodes: <String>["INVALID_CATCH_ARGUMENTS"],
  problemMessage: r"""Invalid catch arguments.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInvalidCodePoint = messageInvalidCodePoint;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidCodePoint = const MessageCode(
  "InvalidCodePoint",
  analyzerCodes: <String>["INVALID_CODE_POINT"],
  problemMessage:
      r"""The escape sequence starting with '\u' isn't a valid code point.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateInvalidConstantPatternBinary =
    const Template<Message Function(String name)>(
  "InvalidConstantPatternBinary",
  problemMessageTemplate:
      r"""The binary operator #name is not supported as a constant pattern.""",
  correctionMessageTemplate:
      r"""Try wrapping the expression in 'const ( ... )'.""",
  withArguments: _withArgumentsInvalidConstantPatternBinary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInvalidConstantPatternBinary = const Code(
  "InvalidConstantPatternBinary",
  index: 141,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidConstantPatternBinary(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeInvalidConstantPatternBinary,
    problemMessage:
        """The binary operator ${name} is not supported as a constant pattern.""",
    correctionMessage: """Try wrapping the expression in 'const ( ... )'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInvalidConstantPatternConstPrefix =
    messageInvalidConstantPatternConstPrefix;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidConstantPatternConstPrefix = const MessageCode(
  "InvalidConstantPatternConstPrefix",
  index: 140,
  problemMessage:
      r"""The expression can't be prefixed by 'const' to form a constant pattern.""",
  correctionMessage:
      r"""Try wrapping the expression in 'const ( ... )' instead.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInvalidConstantPatternDuplicateConst =
    messageInvalidConstantPatternDuplicateConst;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidConstantPatternDuplicateConst =
    const MessageCode(
  "InvalidConstantPatternDuplicateConst",
  index: 137,
  problemMessage: r"""Duplicate 'const' keyword in constant expression.""",
  correctionMessage: r"""Try removing one of the 'const' keywords.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInvalidConstantPatternEmptyRecordLiteral =
    messageInvalidConstantPatternEmptyRecordLiteral;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidConstantPatternEmptyRecordLiteral =
    const MessageCode(
  "InvalidConstantPatternEmptyRecordLiteral",
  index: 138,
  problemMessage:
      r"""The empty record literal is not supported as a constant pattern.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInvalidConstantPatternGeneric =
    messageInvalidConstantPatternGeneric;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidConstantPatternGeneric = const MessageCode(
  "InvalidConstantPatternGeneric",
  index: 139,
  problemMessage:
      r"""This expression is not supported as a constant pattern.""",
  correctionMessage: r"""Try wrapping the expression in 'const ( ... )'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInvalidConstantPatternNegation =
    messageInvalidConstantPatternNegation;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidConstantPatternNegation = const MessageCode(
  "InvalidConstantPatternNegation",
  index: 135,
  problemMessage:
      r"""Only negation of a numeric literal is supported as a constant pattern.""",
  correctionMessage: r"""Try wrapping the expression in 'const ( ... )'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateInvalidConstantPatternUnary =
    const Template<Message Function(String name)>(
  "InvalidConstantPatternUnary",
  problemMessageTemplate:
      r"""The unary operator #name is not supported as a constant pattern.""",
  correctionMessageTemplate:
      r"""Try wrapping the expression in 'const ( ... )'.""",
  withArguments: _withArgumentsInvalidConstantPatternUnary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInvalidConstantPatternUnary = const Code(
  "InvalidConstantPatternUnary",
  index: 136,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidConstantPatternUnary(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeInvalidConstantPatternUnary,
    problemMessage:
        """The unary operator ${name} is not supported as a constant pattern.""",
    correctionMessage: """Try wrapping the expression in 'const ( ... )'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateInvalidContinueTarget =
    const Template<Message Function(String name)>(
  "InvalidContinueTarget",
  problemMessageTemplate: r"""Can't continue at '#name'.""",
  withArguments: _withArgumentsInvalidContinueTarget,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInvalidContinueTarget = const Code(
  "InvalidContinueTarget",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidContinueTarget(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeInvalidContinueTarget,
    problemMessage: """Can't continue at '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInvalidEscapeStarted = messageInvalidEscapeStarted;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidEscapeStarted = const MessageCode(
  "InvalidEscapeStarted",
  index: 126,
  problemMessage: r"""The string '\' can't stand alone.""",
  correctionMessage: r"""Try adding another backslash (\) to escape the '\'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateInvalidGetterSetterTypeFieldContext =
    const Template<Message Function(String name)>(
  "InvalidGetterSetterTypeFieldContext",
  problemMessageTemplate: r"""This is the declaration of the field '#name'.""",
  withArguments: _withArgumentsInvalidGetterSetterTypeFieldContext,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInvalidGetterSetterTypeFieldContext = const Code(
  "InvalidGetterSetterTypeFieldContext",
  severity: Severity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidGetterSetterTypeFieldContext(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeInvalidGetterSetterTypeFieldContext,
    problemMessage: """This is the declaration of the field '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateInvalidGetterSetterTypeGetterContext =
    const Template<Message Function(String name)>(
  "InvalidGetterSetterTypeGetterContext",
  problemMessageTemplate: r"""This is the declaration of the getter '#name'.""",
  withArguments: _withArgumentsInvalidGetterSetterTypeGetterContext,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInvalidGetterSetterTypeGetterContext = const Code(
  "InvalidGetterSetterTypeGetterContext",
  severity: Severity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidGetterSetterTypeGetterContext(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeInvalidGetterSetterTypeGetterContext,
    problemMessage: """This is the declaration of the getter '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateInvalidGetterSetterTypeSetterContext =
    const Template<Message Function(String name)>(
  "InvalidGetterSetterTypeSetterContext",
  problemMessageTemplate: r"""This is the declaration of the setter '#name'.""",
  withArguments: _withArgumentsInvalidGetterSetterTypeSetterContext,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInvalidGetterSetterTypeSetterContext = const Code(
  "InvalidGetterSetterTypeSetterContext",
  severity: Severity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidGetterSetterTypeSetterContext(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeInvalidGetterSetterTypeSetterContext,
    problemMessage: """This is the declaration of the setter '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInvalidHexEscape = messageInvalidHexEscape;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidHexEscape = const MessageCode(
  "InvalidHexEscape",
  index: 40,
  problemMessage:
      r"""An escape sequence starting with '\x' must be followed by 2 hexadecimal digits.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInvalidInitializer = messageInvalidInitializer;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidInitializer = const MessageCode(
  "InvalidInitializer",
  index: 90,
  problemMessage: r"""Not a valid initializer.""",
  correctionMessage:
      r"""To initialize a field, use the syntax 'name = value'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInvalidInlineFunctionType = messageInvalidInlineFunctionType;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidInlineFunctionType = const MessageCode(
  "InvalidInlineFunctionType",
  analyzerCodes: <String>["INVALID_INLINE_FUNCTION_TYPE"],
  problemMessage:
      r"""Inline function types cannot be used for parameters in a generic function type.""",
  correctionMessage:
      r"""Try changing the inline function type (as in 'int f()') to a prefixed function type using the `Function` keyword (as in 'int Function() f').""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInvalidInsideUnaryPattern = messageInvalidInsideUnaryPattern;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidInsideUnaryPattern = const MessageCode(
  "InvalidInsideUnaryPattern",
  index: 150,
  problemMessage:
      r"""This pattern cannot appear inside a unary pattern (cast pattern, null check pattern, or null assert pattern) without parentheses.""",
  correctionMessage:
      r"""Try combining into a single pattern if possible, or enclose the inner pattern in parentheses.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)>
    templateInvalidMacroApplicationTarget =
    const Template<Message Function(String string)>(
  "InvalidMacroApplicationTarget",
  problemMessageTemplate: r"""The macro can only be applied to #string.""",
  withArguments: _withArgumentsInvalidMacroApplicationTarget,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInvalidMacroApplicationTarget = const Code(
  "InvalidMacroApplicationTarget",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidMacroApplicationTarget(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(
    codeInvalidMacroApplicationTarget,
    problemMessage: """The macro can only be applied to ${string}.""",
    arguments: {
      'string': string,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInvalidNnbdDillLibrary = messageInvalidNnbdDillLibrary;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidNnbdDillLibrary = const MessageCode(
  "InvalidNnbdDillLibrary",
  problemMessage: r"""Trying to use library with invalid null safety.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateInvalidOperator =
    const Template<Message Function(Token token)>(
  "InvalidOperator",
  problemMessageTemplate:
      r"""The string '#lexeme' isn't a user-definable operator.""",
  withArguments: _withArgumentsInvalidOperator,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInvalidOperator = const Code(
  "InvalidOperator",
  index: 39,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidOperator(Token token) {
  String lexeme = token.lexeme;
  return new Message(
    codeInvalidOperator,
    problemMessage:
        """The string '${lexeme}' isn't a user-definable operator.""",
    arguments: {
      'lexeme': token,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri_, String string)>
    templateInvalidPackageUri =
    const Template<Message Function(Uri uri_, String string)>(
  "InvalidPackageUri",
  problemMessageTemplate: r"""Invalid package URI '#uri':
  #string.""",
  withArguments: _withArgumentsInvalidPackageUri,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInvalidPackageUri = const Code(
  "InvalidPackageUri",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidPackageUri(Uri uri_, String string) {
  String? uri = relativizeUri(uri_);
  if (string.isEmpty) throw 'No string provided';
  return new Message(
    codeInvalidPackageUri,
    problemMessage: """Invalid package URI '${uri}':
  ${string}.""",
    arguments: {
      'uri': uri_,
      'string': string,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInvalidSuperInInitializer = messageInvalidSuperInInitializer;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidSuperInInitializer = const MessageCode(
  "InvalidSuperInInitializer",
  index: 47,
  problemMessage:
      r"""Can only use 'super' in an initializer for calling the superclass constructor (e.g. 'super()' or 'super.namedConstructor()')""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInvalidSyncModifier = messageInvalidSyncModifier;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidSyncModifier = const MessageCode(
  "InvalidSyncModifier",
  analyzerCodes: <String>["MISSING_STAR_AFTER_SYNC"],
  problemMessage: r"""Invalid modifier 'sync'.""",
  correctionMessage: r"""Try replacing 'sync' with 'sync*'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInvalidThisInInitializer = messageInvalidThisInInitializer;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidThisInInitializer = const MessageCode(
  "InvalidThisInInitializer",
  index: 65,
  problemMessage:
      r"""Can only use 'this' in an initializer for field initialization (e.g. 'this.x = something') and constructor redirection (e.g. 'this()' or 'this.namedConstructor())""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String string2, String name2)>
    templateInvalidTypeParameterInSupertype =
    const Template<Message Function(String name, String string2, String name2)>(
  "InvalidTypeParameterInSupertype",
  problemMessageTemplate:
      r"""Can't use implicitly 'out' variable '#name' in an '#string2' position in supertype '#name2'.""",
  withArguments: _withArgumentsInvalidTypeParameterInSupertype,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInvalidTypeParameterInSupertype = const Code(
  "InvalidTypeParameterInSupertype",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidTypeParameterInSupertype(
    String name, String string2, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (string2.isEmpty) throw 'No string provided';
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(
    codeInvalidTypeParameterInSupertype,
    problemMessage:
        """Can't use implicitly 'out' variable '${name}' in an '${string2}' position in supertype '${name2}'.""",
    arguments: {
      'name': name,
      'string2': string2,
      'name2': name2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(
            String string, String name, String string2, String name2)>
    templateInvalidTypeParameterInSupertypeWithVariance = const Template<
        Message Function(
            String string, String name, String string2, String name2)>(
  "InvalidTypeParameterInSupertypeWithVariance",
  problemMessageTemplate:
      r"""Can't use '#string' type variable '#name' in an '#string2' position in supertype '#name2'.""",
  withArguments: _withArgumentsInvalidTypeParameterInSupertypeWithVariance,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInvalidTypeParameterInSupertypeWithVariance = const Code(
  "InvalidTypeParameterInSupertypeWithVariance",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidTypeParameterInSupertypeWithVariance(
    String string, String name, String string2, String name2) {
  if (string.isEmpty) throw 'No string provided';
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (string2.isEmpty) throw 'No string provided';
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(
    codeInvalidTypeParameterInSupertypeWithVariance,
    problemMessage:
        """Can't use '${string}' type variable '${name}' in an '${string2}' position in supertype '${name2}'.""",
    arguments: {
      'string': string,
      'name': name,
      'string2': string2,
      'name2': name2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string, String name, String string2)>
    templateInvalidTypeParameterVariancePosition = const Template<
        Message Function(String string, String name, String string2)>(
  "InvalidTypeParameterVariancePosition",
  problemMessageTemplate:
      r"""Can't use '#string' type variable '#name' in an '#string2' position.""",
  withArguments: _withArgumentsInvalidTypeParameterVariancePosition,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInvalidTypeParameterVariancePosition = const Code(
  "InvalidTypeParameterVariancePosition",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidTypeParameterVariancePosition(
    String string, String name, String string2) {
  if (string.isEmpty) throw 'No string provided';
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (string2.isEmpty) throw 'No string provided';
  return new Message(
    codeInvalidTypeParameterVariancePosition,
    problemMessage:
        """Can't use '${string}' type variable '${name}' in an '${string2}' position.""",
    arguments: {
      'string': string,
      'name': name,
      'string2': string2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string, String name, String string2)>
    templateInvalidTypeParameterVariancePositionInReturnType = const Template<
        Message Function(String string, String name, String string2)>(
  "InvalidTypeParameterVariancePositionInReturnType",
  problemMessageTemplate:
      r"""Can't use '#string' type variable '#name' in an '#string2' position in the return type.""",
  withArguments: _withArgumentsInvalidTypeParameterVariancePositionInReturnType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInvalidTypeParameterVariancePositionInReturnType = const Code(
  "InvalidTypeParameterVariancePositionInReturnType",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidTypeParameterVariancePositionInReturnType(
    String string, String name, String string2) {
  if (string.isEmpty) throw 'No string provided';
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (string2.isEmpty) throw 'No string provided';
  return new Message(
    codeInvalidTypeParameterVariancePositionInReturnType,
    problemMessage:
        """Can't use '${string}' type variable '${name}' in an '${string2}' position in the return type.""",
    arguments: {
      'string': string,
      'name': name,
      'string2': string2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInvalidUnicodeEscapeUBracket =
    messageInvalidUnicodeEscapeUBracket;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidUnicodeEscapeUBracket = const MessageCode(
  "InvalidUnicodeEscapeUBracket",
  index: 125,
  problemMessage:
      r"""An escape sequence starting with '\u{' must be followed by 1 to 6 hexadecimal digits followed by a '}'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInvalidUnicodeEscapeUNoBracket =
    messageInvalidUnicodeEscapeUNoBracket;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidUnicodeEscapeUNoBracket = const MessageCode(
  "InvalidUnicodeEscapeUNoBracket",
  index: 124,
  problemMessage:
      r"""An escape sequence starting with '\u' must be followed by 4 hexadecimal digits.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInvalidUnicodeEscapeUStarted =
    messageInvalidUnicodeEscapeUStarted;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidUnicodeEscapeUStarted = const MessageCode(
  "InvalidUnicodeEscapeUStarted",
  index: 38,
  problemMessage:
      r"""An escape sequence starting with '\u' must be followed by 4 hexadecimal digits or from 1 to 6 digits between '{' and '}'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInvalidUseOfNullAwareAccess = messageInvalidUseOfNullAwareAccess;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidUseOfNullAwareAccess = const MessageCode(
  "InvalidUseOfNullAwareAccess",
  analyzerCodes: <String>["INVALID_USE_OF_NULL_AWARE_ACCESS"],
  problemMessage: r"""Cannot use '?.' here.""",
  correctionMessage: r"""Try using '.'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInvalidVoid = messageInvalidVoid;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidVoid = const MessageCode(
  "InvalidVoid",
  analyzerCodes: <String>["EXPECTED_TYPE_NAME"],
  problemMessage: r"""Type 'void' can't be used here.""",
  correctionMessage:
      r"""Try removing 'void' keyword or replace it with 'var', 'final', or a type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateInvokeNonFunction =
    const Template<Message Function(String name)>(
  "InvokeNonFunction",
  problemMessageTemplate:
      r"""'#name' isn't a function or method and can't be invoked.""",
  withArguments: _withArgumentsInvokeNonFunction,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeInvokeNonFunction = const Code(
  "InvokeNonFunction",
  analyzerCodes: <String>["INVOCATION_OF_NON_FUNCTION"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvokeNonFunction(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeInvokeNonFunction,
    problemMessage:
        """'${name}' isn't a function or method and can't be invoked.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateJointPatternVariableNotInAll =
    const Template<Message Function(String name)>(
  "JointPatternVariableNotInAll",
  problemMessageTemplate:
      r"""The variable '#name' is available in some, but not all cases that share this body.""",
  withArguments: _withArgumentsJointPatternVariableNotInAll,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeJointPatternVariableNotInAll = const Code(
  "JointPatternVariableNotInAll",
  analyzerCodes: <String>["INVALID_PATTERN_VARIABLE_IN_SHARED_CASE_SCOPE"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJointPatternVariableNotInAll(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeJointPatternVariableNotInAll,
    problemMessage:
        """The variable '${name}' is available in some, but not all cases that share this body.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateJointPatternVariableWithLabelDefault =
    const Template<Message Function(String name)>(
  "JointPatternVariableWithLabelDefault",
  problemMessageTemplate:
      r"""The variable '#name' is not available because there is a label or 'default' case.""",
  withArguments: _withArgumentsJointPatternVariableWithLabelDefault,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeJointPatternVariableWithLabelDefault = const Code(
  "JointPatternVariableWithLabelDefault",
  analyzerCodes: <String>["INVALID_PATTERN_VARIABLE_IN_SHARED_CASE_SCOPE"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJointPatternVariableWithLabelDefault(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeJointPatternVariableWithLabelDefault,
    problemMessage:
        """The variable '${name}' is not available because there is a label or 'default' case.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateJointPatternVariablesMismatch =
    const Template<Message Function(String name)>(
  "JointPatternVariablesMismatch",
  problemMessageTemplate:
      r"""Variable pattern '#name' doesn't have the same type or finality in all cases.""",
  withArguments: _withArgumentsJointPatternVariablesMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeJointPatternVariablesMismatch = const Code(
  "JointPatternVariablesMismatch",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJointPatternVariablesMismatch(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeJointPatternVariablesMismatch,
    problemMessage:
        """Variable pattern '${name}' doesn't have the same type or finality in all cases.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String name2)>
    templateJsInteropDartClassExtendsJSClass =
    const Template<Message Function(String name, String name2)>(
  "JsInteropDartClassExtendsJSClass",
  problemMessageTemplate:
      r"""Dart class '#name' cannot extend JS interop class '#name2'.""",
  correctionMessageTemplate:
      r"""Try adding the JS interop annotation or removing it from the parent class.""",
  withArguments: _withArgumentsJsInteropDartClassExtendsJSClass,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeJsInteropDartClassExtendsJSClass = const Code(
  "JsInteropDartClassExtendsJSClass",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropDartClassExtendsJSClass(
    String name, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(
    codeJsInteropDartClassExtendsJSClass,
    problemMessage:
        """Dart class '${name}' cannot extend JS interop class '${name2}'.""",
    correctionMessage:
        """Try adding the JS interop annotation or removing it from the parent class.""",
    arguments: {
      'name': name,
      'name2': name2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeJsInteropDartJsInteropAnnotationForStaticInteropOnly =
    messageJsInteropDartJsInteropAnnotationForStaticInteropOnly;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageJsInteropDartJsInteropAnnotationForStaticInteropOnly =
    const MessageCode(
  "JsInteropDartJsInteropAnnotationForStaticInteropOnly",
  problemMessage:
      r"""The '@JS' annotation from 'dart:js_interop' can only be used for static interop, either through extension types or '@staticInterop' classes.""",
  correctionMessage:
      r"""Try making this class an extension type or marking it as '@staticInterop'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateJsInteropDisallowedInteropLibraryInDart2Wasm =
    const Template<Message Function(String name)>(
  "JsInteropDisallowedInteropLibraryInDart2Wasm",
  problemMessageTemplate:
      r"""JS interop library '#name' can't be imported when compiling to Wasm.""",
  correctionMessageTemplate:
      r"""Try using 'dart:js_interop' or 'dart:js_interop_unsafe' instead.""",
  withArguments: _withArgumentsJsInteropDisallowedInteropLibraryInDart2Wasm,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeJsInteropDisallowedInteropLibraryInDart2Wasm = const Code(
  "JsInteropDisallowedInteropLibraryInDart2Wasm",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropDisallowedInteropLibraryInDart2Wasm(
    String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeJsInteropDisallowedInteropLibraryInDart2Wasm,
    problemMessage:
        """JS interop library '${name}' can't be imported when compiling to Wasm.""",
    correctionMessage:
        """Try using 'dart:js_interop' or 'dart:js_interop_unsafe' instead.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeJsInteropEnclosingClassJSAnnotation =
    messageJsInteropEnclosingClassJSAnnotation;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageJsInteropEnclosingClassJSAnnotation =
    const MessageCode(
  "JsInteropEnclosingClassJSAnnotation",
  problemMessage:
      r"""Member has a JS interop annotation but the enclosing class does not.""",
  correctionMessage: r"""Try adding the annotation to the enclosing class.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeJsInteropEnclosingClassJSAnnotationContext =
    messageJsInteropEnclosingClassJSAnnotationContext;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageJsInteropEnclosingClassJSAnnotationContext =
    const MessageCode(
  "JsInteropEnclosingClassJSAnnotationContext",
  severity: Severity.context,
  problemMessage: r"""This is the enclosing class.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateJsInteropExportClassNotMarkedExportable =
    const Template<Message Function(String name)>(
  "JsInteropExportClassNotMarkedExportable",
  problemMessageTemplate:
      r"""Class '#name' does not have a `@JSExport` on it or any of its members.""",
  correctionMessageTemplate:
      r"""Use the `@JSExport` annotation on this class.""",
  withArguments: _withArgumentsJsInteropExportClassNotMarkedExportable,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeJsInteropExportClassNotMarkedExportable = const Code(
  "JsInteropExportClassNotMarkedExportable",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropExportClassNotMarkedExportable(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeJsInteropExportClassNotMarkedExportable,
    problemMessage:
        """Class '${name}' does not have a `@JSExport` on it or any of its members.""",
    correctionMessage: """Use the `@JSExport` annotation on this class.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateJsInteropExportDartInterfaceHasNonEmptyJSExportValue =
    const Template<Message Function(String name)>(
  "JsInteropExportDartInterfaceHasNonEmptyJSExportValue",
  problemMessageTemplate:
      r"""The value in the `@JSExport` annotation on the class or mixin '#name' will be ignored.""",
  correctionMessageTemplate: r"""Remove the value in the annotation.""",
  withArguments:
      _withArgumentsJsInteropExportDartInterfaceHasNonEmptyJSExportValue,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeJsInteropExportDartInterfaceHasNonEmptyJSExportValue =
    const Code(
  "JsInteropExportDartInterfaceHasNonEmptyJSExportValue",
  severity: Severity.warning,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropExportDartInterfaceHasNonEmptyJSExportValue(
    String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeJsInteropExportDartInterfaceHasNonEmptyJSExportValue,
    problemMessage:
        """The value in the `@JSExport` annotation on the class or mixin '${name}' will be ignored.""",
    correctionMessage: """Remove the value in the annotation.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateJsInteropExportDisallowedMember =
    const Template<Message Function(String name)>(
  "JsInteropExportDisallowedMember",
  problemMessageTemplate:
      r"""Member '#name' is not a concrete instance member or declares type parameters, and therefore can't be exported.""",
  correctionMessageTemplate:
      r"""Remove the `@JSExport` annotation from the member, and use an instance member to call this member instead.""",
  withArguments: _withArgumentsJsInteropExportDisallowedMember,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeJsInteropExportDisallowedMember = const Code(
  "JsInteropExportDisallowedMember",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropExportDisallowedMember(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeJsInteropExportDisallowedMember,
    problemMessage:
        """Member '${name}' is not a concrete instance member or declares type parameters, and therefore can't be exported.""",
    correctionMessage:
        """Remove the `@JSExport` annotation from the member, and use an instance member to call this member instead.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String string)>
    templateJsInteropExportMemberCollision =
    const Template<Message Function(String name, String string)>(
  "JsInteropExportMemberCollision",
  problemMessageTemplate:
      r"""The following class members collide with the same export '#name': #string.""",
  correctionMessageTemplate:
      r"""Either remove the conflicting members or use a different export name.""",
  withArguments: _withArgumentsJsInteropExportMemberCollision,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeJsInteropExportMemberCollision = const Code(
  "JsInteropExportMemberCollision",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropExportMemberCollision(
    String name, String string) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (string.isEmpty) throw 'No string provided';
  return new Message(
    codeJsInteropExportMemberCollision,
    problemMessage:
        """The following class members collide with the same export '${name}': ${string}.""",
    correctionMessage:
        """Either remove the conflicting members or use a different export name.""",
    arguments: {
      'name': name,
      'string': string,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateJsInteropExportNoExportableMembers =
    const Template<Message Function(String name)>(
  "JsInteropExportNoExportableMembers",
  problemMessageTemplate:
      r"""Class '#name' has no exportable members in the class or the inheritance chain.""",
  correctionMessageTemplate:
      r"""Using `@JSExport`, annotate at least one instance member with a body or annotate a class that has such a member in the inheritance chain.""",
  withArguments: _withArgumentsJsInteropExportNoExportableMembers,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeJsInteropExportNoExportableMembers = const Code(
  "JsInteropExportNoExportableMembers",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropExportNoExportableMembers(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeJsInteropExportNoExportableMembers,
    problemMessage:
        """Class '${name}' has no exportable members in the class or the inheritance chain.""",
    correctionMessage:
        """Using `@JSExport`, annotate at least one instance member with a body or annotate a class that has such a member in the inheritance chain.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeJsInteropExtensionTypeMemberNotInterop =
    messageJsInteropExtensionTypeMemberNotInterop;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageJsInteropExtensionTypeMemberNotInterop =
    const MessageCode(
  "JsInteropExtensionTypeMemberNotInterop",
  problemMessage:
      r"""Extension type member is marked 'external', but the representation type of its extension type is not a valid JS interop type.""",
  correctionMessage:
      r"""Try declaring a valid JS interop representation type, which may include 'dart:js_interop' types, '@staticInterop' types, 'dart:html' types, or other interop extension types.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeJsInteropExtensionTypeUsedWithWrongJsAnnotation =
    messageJsInteropExtensionTypeUsedWithWrongJsAnnotation;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageJsInteropExtensionTypeUsedWithWrongJsAnnotation =
    const MessageCode(
  "JsInteropExtensionTypeUsedWithWrongJsAnnotation",
  problemMessage:
      r"""Extension types should use the '@JS' annotation from 'dart:js_interop' and not from 'package:js'.""",
  correctionMessage:
      r"""Try using the '@JS' annotation from 'dart:js_interop' annotation on this extension type instead.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeJsInteropExternalExtensionMemberOnTypeInvalid =
    messageJsInteropExternalExtensionMemberOnTypeInvalid;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageJsInteropExternalExtensionMemberOnTypeInvalid =
    const MessageCode(
  "JsInteropExternalExtensionMemberOnTypeInvalid",
  problemMessage:
      r"""JS interop type or @Native type from an SDK web library required for 'external' extension members.""",
  correctionMessage:
      r"""Try making the on-type a JS interop type or an @Native SDK web library type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeJsInteropExternalExtensionMemberWithStaticDisallowed =
    messageJsInteropExternalExtensionMemberWithStaticDisallowed;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageJsInteropExternalExtensionMemberWithStaticDisallowed =
    const MessageCode(
  "JsInteropExternalExtensionMemberWithStaticDisallowed",
  problemMessage:
      r"""External extension members with the keyword 'static' on JS interop and @Native types are disallowed.""",
  correctionMessage: r"""Try putting the member in the on-type instead.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeJsInteropExternalMemberNotJSAnnotated =
    messageJsInteropExternalMemberNotJSAnnotated;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageJsInteropExternalMemberNotJSAnnotated =
    const MessageCode(
  "JsInteropExternalMemberNotJSAnnotated",
  problemMessage: r"""Only JS interop members may be 'external'.""",
  correctionMessage:
      r"""Try removing the 'external' keyword or adding a JS interop annotation.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeJsInteropFunctionToJSNamedParameters =
    messageJsInteropFunctionToJSNamedParameters;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageJsInteropFunctionToJSNamedParameters =
    const MessageCode(
  "JsInteropFunctionToJSNamedParameters",
  problemMessage:
      r"""Functions converted via `toJS` cannot declare named parameters.""",
  correctionMessage:
      r"""Remove the declared named parameters from the function.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeJsInteropFunctionToJSTypeParameters =
    messageJsInteropFunctionToJSTypeParameters;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageJsInteropFunctionToJSTypeParameters =
    const MessageCode(
  "JsInteropFunctionToJSTypeParameters",
  problemMessage:
      r"""Functions converted via `toJS` cannot declare type parameters.""",
  correctionMessage:
      r"""Remove the declared type parameters from the function.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeJsInteropInvalidStaticClassMemberName =
    messageJsInteropInvalidStaticClassMemberName;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageJsInteropInvalidStaticClassMemberName =
    const MessageCode(
  "JsInteropInvalidStaticClassMemberName",
  problemMessage:
      r"""JS interop static class members cannot have '.' in their JS name.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeJsInteropIsATearoff = messageJsInteropIsATearoff;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageJsInteropIsATearoff = const MessageCode(
  "JsInteropIsATearoff",
  problemMessage: r"""'isA' can't be torn off.""",
  correctionMessage:
      r"""Use a method that calls 'isA' and tear off that method instead.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String name2)>
    templateJsInteropJSClassExtendsDartClass =
    const Template<Message Function(String name, String name2)>(
  "JsInteropJSClassExtendsDartClass",
  problemMessageTemplate:
      r"""JS interop class '#name' cannot extend Dart class '#name2'.""",
  correctionMessageTemplate:
      r"""Try removing the JS interop annotation or adding it to the parent class.""",
  withArguments: _withArgumentsJsInteropJSClassExtendsDartClass,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeJsInteropJSClassExtendsDartClass = const Code(
  "JsInteropJSClassExtendsDartClass",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropJSClassExtendsDartClass(
    String name, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(
    codeJsInteropJSClassExtendsDartClass,
    problemMessage:
        """JS interop class '${name}' cannot extend Dart class '${name2}'.""",
    correctionMessage:
        """Try removing the JS interop annotation or adding it to the parent class.""",
    arguments: {
      'name': name,
      'name2': name2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeJsInteropNamedParameters = messageJsInteropNamedParameters;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageJsInteropNamedParameters = const MessageCode(
  "JsInteropNamedParameters",
  problemMessage:
      r"""Named parameters for JS interop functions are only allowed in object literal constructors or @anonymous factories.""",
  correctionMessage:
      r"""Try replacing them with normal or optional parameters.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String name2, String string3)>
    templateJsInteropNativeClassInAnnotation =
    const Template<Message Function(String name, String name2, String string3)>(
  "JsInteropNativeClassInAnnotation",
  problemMessageTemplate:
      r"""Non-static JS interop class '#name' conflicts with natively supported class '#name2' in '#string3'.""",
  correctionMessageTemplate:
      r"""Try replacing it with a static JS interop class using `@staticInterop` with extension methods, or use js_util to interact with the native object of type '#name2'.""",
  withArguments: _withArgumentsJsInteropNativeClassInAnnotation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeJsInteropNativeClassInAnnotation = const Code(
  "JsInteropNativeClassInAnnotation",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropNativeClassInAnnotation(
    String name, String name2, String string3) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  if (string3.isEmpty) throw 'No string provided';
  return new Message(
    codeJsInteropNativeClassInAnnotation,
    problemMessage:
        """Non-static JS interop class '${name}' conflicts with natively supported class '${name2}' in '${string3}'.""",
    correctionMessage:
        """Try replacing it with a static JS interop class using `@staticInterop` with extension methods, or use js_util to interact with the native object of type '${name2}'.""",
    arguments: {
      'name': name,
      'name2': name2,
      'string3': string3,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeJsInteropNonExternalConstructor =
    messageJsInteropNonExternalConstructor;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageJsInteropNonExternalConstructor = const MessageCode(
  "JsInteropNonExternalConstructor",
  problemMessage:
      r"""JS interop classes do not support non-external constructors.""",
  correctionMessage: r"""Try annotating with `external`.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeJsInteropNonExternalMember = messageJsInteropNonExternalMember;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageJsInteropNonExternalMember = const MessageCode(
  "JsInteropNonExternalMember",
  problemMessage:
      r"""This JS interop member must be annotated with `external`. Only factories and static methods can be non-external.""",
  correctionMessage: r"""Try annotating the member with `external`.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String name2)>
    templateJsInteropNonStaticWithStaticInteropSupertype =
    const Template<Message Function(String name, String name2)>(
  "JsInteropNonStaticWithStaticInteropSupertype",
  problemMessageTemplate:
      r"""Class '#name' does not have an `@staticInterop` annotation, but has supertype '#name2', which does.""",
  correctionMessageTemplate:
      r"""Try marking '#name' as a `@staticInterop` class, or don't inherit '#name2'.""",
  withArguments: _withArgumentsJsInteropNonStaticWithStaticInteropSupertype,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeJsInteropNonStaticWithStaticInteropSupertype = const Code(
  "JsInteropNonStaticWithStaticInteropSupertype",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropNonStaticWithStaticInteropSupertype(
    String name, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(
    codeJsInteropNonStaticWithStaticInteropSupertype,
    problemMessage:
        """Class '${name}' does not have an `@staticInterop` annotation, but has supertype '${name2}', which does.""",
    correctionMessage:
        """Try marking '${name}' as a `@staticInterop` class, or don't inherit '${name2}'.""",
    arguments: {
      'name': name,
      'name2': name2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)>
    templateJsInteropObjectLiteralConstructorPositionalParameters =
    const Template<Message Function(String string)>(
  "JsInteropObjectLiteralConstructorPositionalParameters",
  problemMessageTemplate:
      r"""#string should not contain any positional parameters.""",
  correctionMessageTemplate:
      r"""Try replacing them with named parameters instead.""",
  withArguments:
      _withArgumentsJsInteropObjectLiteralConstructorPositionalParameters,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeJsInteropObjectLiteralConstructorPositionalParameters =
    const Code(
  "JsInteropObjectLiteralConstructorPositionalParameters",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropObjectLiteralConstructorPositionalParameters(
    String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(
    codeJsInteropObjectLiteralConstructorPositionalParameters,
    problemMessage:
        """${string} should not contain any positional parameters.""",
    correctionMessage: """Try replacing them with named parameters instead.""",
    arguments: {
      'string': string,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeJsInteropOperatorCannotBeRenamed =
    messageJsInteropOperatorCannotBeRenamed;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageJsInteropOperatorCannotBeRenamed = const MessageCode(
  "JsInteropOperatorCannotBeRenamed",
  problemMessage:
      r"""JS interop operator methods cannot be renamed using the '@JS' annotation.""",
  correctionMessage:
      r"""Remove the annotation or remove the value inside the annotation.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeJsInteropOperatorsNotSupported =
    messageJsInteropOperatorsNotSupported;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageJsInteropOperatorsNotSupported = const MessageCode(
  "JsInteropOperatorsNotSupported",
  problemMessage:
      r"""JS interop types do not support overloading external operator methods, with the exception of '[]' and '[]=' using static interop.""",
  correctionMessage:
      r"""Try making this class a static interop type instead.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string2)>
    templateJsInteropStaticInteropExternalFunctionTypeViolation =
    const Template<Message Function(String string2)>(
  "JsInteropStaticInteropExternalFunctionTypeViolation",
  problemMessageTemplate:
      r"""External JS interop member contains invalid types in its function signature: '#string2'.""",
  correctionMessageTemplate:
      r"""Use one of these valid types instead: JS types from 'dart:js_interop', ExternalDartReference, void, bool, num, double, int, String, extension types that erase to one of these types, '@staticInterop' types, 'dart:html' types when compiling to JS, or a type parameter that is a subtype of a valid non-primitive type.""",
  withArguments:
      _withArgumentsJsInteropStaticInteropExternalFunctionTypeViolation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeJsInteropStaticInteropExternalFunctionTypeViolation = const Code(
  "JsInteropStaticInteropExternalFunctionTypeViolation",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropStaticInteropExternalFunctionTypeViolation(
    String string2) {
  if (string2.isEmpty) throw 'No string provided';
  return new Message(
    codeJsInteropStaticInteropExternalFunctionTypeViolation,
    problemMessage:
        """External JS interop member contains invalid types in its function signature: '${string2}'.""",
    correctionMessage:
        """Use one of these valid types instead: JS types from 'dart:js_interop', ExternalDartReference, void, bool, num, double, int, String, extension types that erase to one of these types, '@staticInterop' types, 'dart:html' types when compiling to JS, or a type parameter that is a subtype of a valid non-primitive type.""",
    arguments: {
      'string2': string2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeJsInteropStaticInteropGenerativeConstructor =
    messageJsInteropStaticInteropGenerativeConstructor;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageJsInteropStaticInteropGenerativeConstructor =
    const MessageCode(
  "JsInteropStaticInteropGenerativeConstructor",
  problemMessage:
      r"""`@staticInterop` classes should not contain any generative constructors.""",
  correctionMessage: r"""Use factory constructors instead.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(String name, String string, String string2,
            String name2, String string3)>
    templateJsInteropStaticInteropMockMissingGetterOrSetter = const Template<
        Message Function(String name, String string, String string2,
            String name2, String string3)>(
  "JsInteropStaticInteropMockMissingGetterOrSetter",
  problemMessageTemplate:
      r"""Dart class '#name' has a #string, but does not have a #string2 to implement any of the following extension member(s) with export name '#name2': #string3.""",
  correctionMessageTemplate:
      r"""Declare an exportable #string2 that implements one of these extension members.""",
  withArguments: _withArgumentsJsInteropStaticInteropMockMissingGetterOrSetter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeJsInteropStaticInteropMockMissingGetterOrSetter = const Code(
  "JsInteropStaticInteropMockMissingGetterOrSetter",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropStaticInteropMockMissingGetterOrSetter(
    String name, String string, String string2, String name2, String string3) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (string.isEmpty) throw 'No string provided';
  if (string2.isEmpty) throw 'No string provided';
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  if (string3.isEmpty) throw 'No string provided';
  return new Message(
    codeJsInteropStaticInteropMockMissingGetterOrSetter,
    problemMessage:
        """Dart class '${name}' has a ${string}, but does not have a ${string2} to implement any of the following extension member(s) with export name '${name2}': ${string3}.""",
    correctionMessage:
        """Declare an exportable ${string2} that implements one of these extension members.""",
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
const Template<Message Function(String name, String name2, String string)>
    templateJsInteropStaticInteropMockMissingImplements =
    const Template<Message Function(String name, String name2, String string)>(
  "JsInteropStaticInteropMockMissingImplements",
  problemMessageTemplate:
      r"""Dart class '#name' does not have any members that implement any of the following extension member(s) with export name '#name2': #string.""",
  correctionMessageTemplate:
      r"""Declare an exportable member that implements one of these extension members.""",
  withArguments: _withArgumentsJsInteropStaticInteropMockMissingImplements,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeJsInteropStaticInteropMockMissingImplements = const Code(
  "JsInteropStaticInteropMockMissingImplements",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropStaticInteropMockMissingImplements(
    String name, String name2, String string) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  if (string.isEmpty) throw 'No string provided';
  return new Message(
    codeJsInteropStaticInteropMockMissingImplements,
    problemMessage:
        """Dart class '${name}' does not have any members that implement any of the following extension member(s) with export name '${name2}': ${string}.""",
    correctionMessage:
        """Declare an exportable member that implements one of these extension members.""",
    arguments: {
      'name': name,
      'name2': name2,
      'string': string,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateJsInteropStaticInteropNoJSAnnotation =
    const Template<Message Function(String name)>(
  "JsInteropStaticInteropNoJSAnnotation",
  problemMessageTemplate:
      r"""`@staticInterop` classes should also have the `@JS` annotation.""",
  correctionMessageTemplate: r"""Add `@JS` to class '#name'.""",
  withArguments: _withArgumentsJsInteropStaticInteropNoJSAnnotation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeJsInteropStaticInteropNoJSAnnotation = const Code(
  "JsInteropStaticInteropNoJSAnnotation",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropStaticInteropNoJSAnnotation(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeJsInteropStaticInteropNoJSAnnotation,
    problemMessage:
        """`@staticInterop` classes should also have the `@JS` annotation.""",
    correctionMessage: """Add `@JS` to class '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeJsInteropStaticInteropParameterInitializersAreIgnored =
    messageJsInteropStaticInteropParameterInitializersAreIgnored;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageJsInteropStaticInteropParameterInitializersAreIgnored =
    const MessageCode(
  "JsInteropStaticInteropParameterInitializersAreIgnored",
  severity: Severity.warning,
  problemMessage:
      r"""Initializers for parameters are ignored on static interop external functions.""",
  correctionMessage:
      r"""Declare a forwarding non-external function with this initializer, or remove the initializer.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeJsInteropStaticInteropSyntheticConstructor =
    messageJsInteropStaticInteropSyntheticConstructor;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageJsInteropStaticInteropSyntheticConstructor =
    const MessageCode(
  "JsInteropStaticInteropSyntheticConstructor",
  problemMessage:
      r"""Synthetic constructors on `@staticInterop` classes can not be used.""",
  correctionMessage:
      r"""Declare an external factory constructor for this `@staticInterop` class and use that instead.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string, String name)>
    templateJsInteropStaticInteropTearOffsDisallowed =
    const Template<Message Function(String string, String name)>(
  "JsInteropStaticInteropTearOffsDisallowed",
  problemMessageTemplate:
      r"""Tear-offs of external #string '#name' are disallowed.""",
  correctionMessageTemplate:
      r"""Declare a closure that calls this member instead.""",
  withArguments: _withArgumentsJsInteropStaticInteropTearOffsDisallowed,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeJsInteropStaticInteropTearOffsDisallowed = const Code(
  "JsInteropStaticInteropTearOffsDisallowed",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropStaticInteropTearOffsDisallowed(
    String string, String name) {
  if (string.isEmpty) throw 'No string provided';
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeJsInteropStaticInteropTearOffsDisallowed,
    problemMessage:
        """Tear-offs of external ${string} '${name}' are disallowed.""",
    correctionMessage: """Declare a closure that calls this member instead.""",
    arguments: {
      'string': string,
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string2)>
    templateJsInteropStaticInteropToJSFunctionTypeViolation =
    const Template<Message Function(String string2)>(
  "JsInteropStaticInteropToJSFunctionTypeViolation",
  problemMessageTemplate:
      r"""Function converted via 'toJS' contains invalid types in its function signature: '#string2'.""",
  correctionMessageTemplate:
      r"""Use one of these valid types instead: JS types from 'dart:js_interop', ExternalDartReference, void, bool, num, double, int, String, extension types that erase to one of these types, '@staticInterop' types, 'dart:html' types when compiling to JS, or a type parameter that is a subtype of a valid non-primitive type.""",
  withArguments: _withArgumentsJsInteropStaticInteropToJSFunctionTypeViolation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeJsInteropStaticInteropToJSFunctionTypeViolation = const Code(
  "JsInteropStaticInteropToJSFunctionTypeViolation",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropStaticInteropToJSFunctionTypeViolation(
    String string2) {
  if (string2.isEmpty) throw 'No string provided';
  return new Message(
    codeJsInteropStaticInteropToJSFunctionTypeViolation,
    problemMessage:
        """Function converted via 'toJS' contains invalid types in its function signature: '${string2}'.""",
    correctionMessage:
        """Use one of these valid types instead: JS types from 'dart:js_interop', ExternalDartReference, void, bool, num, double, int, String, extension types that erase to one of these types, '@staticInterop' types, 'dart:html' types when compiling to JS, or a type parameter that is a subtype of a valid non-primitive type.""",
    arguments: {
      'string2': string2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateJsInteropStaticInteropTrustTypesUsageNotAllowed =
    const Template<Message Function(String name)>(
  "JsInteropStaticInteropTrustTypesUsageNotAllowed",
  problemMessageTemplate:
      r"""JS interop class '#name' has an `@trustTypes` annotation, but `@trustTypes` is only supported within the sdk.""",
  correctionMessageTemplate: r"""Try removing the `@trustTypes` annotation.""",
  withArguments: _withArgumentsJsInteropStaticInteropTrustTypesUsageNotAllowed,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeJsInteropStaticInteropTrustTypesUsageNotAllowed = const Code(
  "JsInteropStaticInteropTrustTypesUsageNotAllowed",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropStaticInteropTrustTypesUsageNotAllowed(
    String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeJsInteropStaticInteropTrustTypesUsageNotAllowed,
    problemMessage:
        """JS interop class '${name}' has an `@trustTypes` annotation, but `@trustTypes` is only supported within the sdk.""",
    correctionMessage: """Try removing the `@trustTypes` annotation.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateJsInteropStaticInteropTrustTypesUsedWithoutStaticInterop =
    const Template<Message Function(String name)>(
  "JsInteropStaticInteropTrustTypesUsedWithoutStaticInterop",
  problemMessageTemplate:
      r"""JS interop class '#name' has an `@trustTypes` annotation, but no `@staticInterop` annotation.""",
  correctionMessageTemplate:
      r"""Try marking the class using `@staticInterop`.""",
  withArguments:
      _withArgumentsJsInteropStaticInteropTrustTypesUsedWithoutStaticInterop,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeJsInteropStaticInteropTrustTypesUsedWithoutStaticInterop =
    const Code(
  "JsInteropStaticInteropTrustTypesUsedWithoutStaticInterop",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropStaticInteropTrustTypesUsedWithoutStaticInterop(
    String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeJsInteropStaticInteropTrustTypesUsedWithoutStaticInterop,
    problemMessage:
        """JS interop class '${name}' has an `@trustTypes` annotation, but no `@staticInterop` annotation.""",
    correctionMessage: """Try marking the class using `@staticInterop`.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateJsInteropStaticInteropWithInstanceMembers =
    const Template<Message Function(String name)>(
  "JsInteropStaticInteropWithInstanceMembers",
  problemMessageTemplate:
      r"""JS interop class '#name' with `@staticInterop` annotation cannot declare instance members.""",
  correctionMessageTemplate:
      r"""Try moving the instance member to a static extension.""",
  withArguments: _withArgumentsJsInteropStaticInteropWithInstanceMembers,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeJsInteropStaticInteropWithInstanceMembers = const Code(
  "JsInteropStaticInteropWithInstanceMembers",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropStaticInteropWithInstanceMembers(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeJsInteropStaticInteropWithInstanceMembers,
    problemMessage:
        """JS interop class '${name}' with `@staticInterop` annotation cannot declare instance members.""",
    correctionMessage:
        """Try moving the instance member to a static extension.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String name2)>
    templateJsInteropStaticInteropWithNonStaticSupertype =
    const Template<Message Function(String name, String name2)>(
  "JsInteropStaticInteropWithNonStaticSupertype",
  problemMessageTemplate:
      r"""JS interop class '#name' has an `@staticInterop` annotation, but has supertype '#name2', which does not.""",
  correctionMessageTemplate:
      r"""Try marking the supertype as a static interop class using `@staticInterop`.""",
  withArguments: _withArgumentsJsInteropStaticInteropWithNonStaticSupertype,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeJsInteropStaticInteropWithNonStaticSupertype = const Code(
  "JsInteropStaticInteropWithNonStaticSupertype",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropStaticInteropWithNonStaticSupertype(
    String name, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(
    codeJsInteropStaticInteropWithNonStaticSupertype,
    problemMessage:
        """JS interop class '${name}' has an `@staticInterop` annotation, but has supertype '${name2}', which does not.""",
    correctionMessage:
        """Try marking the supertype as a static interop class using `@staticInterop`.""",
    arguments: {
      'name': name,
      'name2': name2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateLabelNotFound =
    const Template<Message Function(String name)>(
  "LabelNotFound",
  problemMessageTemplate: r"""Can't find label '#name'.""",
  correctionMessageTemplate:
      r"""Try defining the label, or correcting the name to match an existing label.""",
  withArguments: _withArgumentsLabelNotFound,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeLabelNotFound = const Code(
  "LabelNotFound",
  analyzerCodes: <String>["LABEL_UNDEFINED"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsLabelNotFound(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeLabelNotFound,
    problemMessage: """Can't find label '${name}'.""",
    correctionMessage:
        """Try defining the label, or correcting the name to match an existing label.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeLanguageVersionInvalidInDotPackages =
    messageLanguageVersionInvalidInDotPackages;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageLanguageVersionInvalidInDotPackages =
    const MessageCode(
  "LanguageVersionInvalidInDotPackages",
  problemMessage:
      r"""The language version is not specified correctly in the packages file.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeLanguageVersionLibraryContext =
    messageLanguageVersionLibraryContext;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageLanguageVersionLibraryContext = const MessageCode(
  "LanguageVersionLibraryContext",
  severity: Severity.context,
  problemMessage: r"""This is language version annotation in the library.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeLanguageVersionMismatchInPart =
    messageLanguageVersionMismatchInPart;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageLanguageVersionMismatchInPart = const MessageCode(
  "LanguageVersionMismatchInPart",
  problemMessage:
      r"""The language version override has to be the same in the library and its part(s).""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeLanguageVersionMismatchInPatch =
    messageLanguageVersionMismatchInPatch;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageLanguageVersionMismatchInPatch = const MessageCode(
  "LanguageVersionMismatchInPatch",
  problemMessage:
      r"""The language version override has to be the same in the library and its patch(es).""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeLanguageVersionPartContext = messageLanguageVersionPartContext;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageLanguageVersionPartContext = const MessageCode(
  "LanguageVersionPartContext",
  severity: Severity.context,
  problemMessage: r"""This is language version annotation in the part.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeLanguageVersionPatchContext = messageLanguageVersionPatchContext;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageLanguageVersionPatchContext = const MessageCode(
  "LanguageVersionPatchContext",
  severity: Severity.context,
  problemMessage: r"""This is language version annotation in the patch.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(int count, int count2, int count3, int count4)>
    templateLanguageVersionTooHighExplicit = const Template<
        Message Function(int count, int count2, int count3, int count4)>(
  "LanguageVersionTooHighExplicit",
  problemMessageTemplate:
      r"""The specified language version #count.#count2 is too high. The highest supported language version is #count3.#count4.""",
  withArguments: _withArgumentsLanguageVersionTooHighExplicit,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeLanguageVersionTooHighExplicit = const Code(
  "LanguageVersionTooHighExplicit",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsLanguageVersionTooHighExplicit(
    int count, int count2, int count3, int count4) {
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
const Template<
        Message Function(
            int count, int count2, String name, int count3, int count4)>
    templateLanguageVersionTooHighPackage = const Template<
        Message Function(
            int count, int count2, String name, int count3, int count4)>(
  "LanguageVersionTooHighPackage",
  problemMessageTemplate:
      r"""The language version #count.#count2 specified for the package '#name' is too high. The highest supported language version is #count3.#count4.""",
  withArguments: _withArgumentsLanguageVersionTooHighPackage,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeLanguageVersionTooHighPackage = const Code(
  "LanguageVersionTooHighPackage",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsLanguageVersionTooHighPackage(
    int count, int count2, String name, int count3, int count4) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeLanguageVersionTooHighPackage,
    problemMessage:
        """The language version ${count}.${count2} specified for the package '${name}' is too high. The highest supported language version is ${count3}.${count4}.""",
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
const Template<Message Function(int count, int count2, int count3, int count4)>
    templateLanguageVersionTooLowExplicit = const Template<
        Message Function(int count, int count2, int count3, int count4)>(
  "LanguageVersionTooLowExplicit",
  problemMessageTemplate:
      r"""The specified language version #count.#count2 is too low. The lowest supported language version is #count3.#count4.""",
  withArguments: _withArgumentsLanguageVersionTooLowExplicit,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeLanguageVersionTooLowExplicit = const Code(
  "LanguageVersionTooLowExplicit",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsLanguageVersionTooLowExplicit(
    int count, int count2, int count3, int count4) {
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
const Template<
        Message Function(
            int count, int count2, String name, int count3, int count4)>
    templateLanguageVersionTooLowPackage = const Template<
        Message Function(
            int count, int count2, String name, int count3, int count4)>(
  "LanguageVersionTooLowPackage",
  problemMessageTemplate:
      r"""The language version #count.#count2 specified for the package '#name' is too low. The lowest supported language version is #count3.#count4.""",
  withArguments: _withArgumentsLanguageVersionTooLowPackage,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeLanguageVersionTooLowPackage = const Code(
  "LanguageVersionTooLowPackage",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsLanguageVersionTooLowPackage(
    int count, int count2, String name, int count3, int count4) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeLanguageVersionTooLowPackage,
    problemMessage:
        """The language version ${count}.${count2} specified for the package '${name}' is too low. The lowest supported language version is ${count3}.${count4}.""",
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
const Template<Message Function(String name)>
    templateLateDefinitelyAssignedError =
    const Template<Message Function(String name)>(
  "LateDefinitelyAssignedError",
  problemMessageTemplate:
      r"""Late final variable '#name' definitely assigned.""",
  withArguments: _withArgumentsLateDefinitelyAssignedError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeLateDefinitelyAssignedError = const Code(
  "LateDefinitelyAssignedError",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsLateDefinitelyAssignedError(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeLateDefinitelyAssignedError,
    problemMessage: """Late final variable '${name}' definitely assigned.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateLateDefinitelyUnassignedError =
    const Template<Message Function(String name)>(
  "LateDefinitelyUnassignedError",
  problemMessageTemplate:
      r"""Late variable '#name' without initializer is definitely unassigned.""",
  withArguments: _withArgumentsLateDefinitelyUnassignedError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeLateDefinitelyUnassignedError = const Code(
  "LateDefinitelyUnassignedError",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsLateDefinitelyUnassignedError(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeLateDefinitelyUnassignedError,
    problemMessage:
        """Late variable '${name}' without initializer is definitely unassigned.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeLatePatternVariableDeclaration =
    messageLatePatternVariableDeclaration;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageLatePatternVariableDeclaration = const MessageCode(
  "LatePatternVariableDeclaration",
  index: 151,
  problemMessage:
      r"""A pattern variable declaration may not use the `late` keyword.""",
  correctionMessage: r"""Try removing the keyword `late`.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeLibraryDirectiveNotFirst = messageLibraryDirectiveNotFirst;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageLibraryDirectiveNotFirst = const MessageCode(
  "LibraryDirectiveNotFirst",
  index: 37,
  problemMessage:
      r"""The library directive must appear before all other directives.""",
  correctionMessage:
      r"""Try moving the library directive before any other directives.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeListLiteralTooManyTypeArguments =
    messageListLiteralTooManyTypeArguments;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageListLiteralTooManyTypeArguments = const MessageCode(
  "ListLiteralTooManyTypeArguments",
  analyzerCodes: <String>["EXPECTED_ONE_LIST_TYPE_ARGUMENTS"],
  problemMessage: r"""List literal requires exactly one type argument.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeListPatternTooManyTypeArguments =
    messageListPatternTooManyTypeArguments;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageListPatternTooManyTypeArguments = const MessageCode(
  "ListPatternTooManyTypeArguments",
  analyzerCodes: <String>["EXPECTED_ONE_LIST_PATTERN_TYPE_ARGUMENTS"],
  problemMessage: r"""A list pattern requires exactly one type argument.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string, Token token)>
    templateLiteralWithClass =
    const Template<Message Function(String string, Token token)>(
  "LiteralWithClass",
  problemMessageTemplate:
      r"""A #string literal can't be prefixed by '#lexeme'.""",
  correctionMessageTemplate: r"""Try removing '#lexeme'""",
  withArguments: _withArgumentsLiteralWithClass,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeLiteralWithClass = const Code(
  "LiteralWithClass",
  index: 116,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsLiteralWithClass(String string, Token token) {
  if (string.isEmpty) throw 'No string provided';
  String lexeme = token.lexeme;
  return new Message(
    codeLiteralWithClass,
    problemMessage: """A ${string} literal can't be prefixed by '${lexeme}'.""",
    correctionMessage: """Try removing '${lexeme}'""",
    arguments: {
      'string': string,
      'lexeme': token,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string, Token token)>
    templateLiteralWithClassAndNew =
    const Template<Message Function(String string, Token token)>(
  "LiteralWithClassAndNew",
  problemMessageTemplate:
      r"""A #string literal can't be prefixed by 'new #lexeme'.""",
  correctionMessageTemplate: r"""Try removing 'new' and '#lexeme'""",
  withArguments: _withArgumentsLiteralWithClassAndNew,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeLiteralWithClassAndNew = const Code(
  "LiteralWithClassAndNew",
  index: 115,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsLiteralWithClassAndNew(String string, Token token) {
  if (string.isEmpty) throw 'No string provided';
  String lexeme = token.lexeme;
  return new Message(
    codeLiteralWithClassAndNew,
    problemMessage:
        """A ${string} literal can't be prefixed by 'new ${lexeme}'.""",
    correctionMessage: """Try removing 'new' and '${lexeme}'""",
    arguments: {
      'string': string,
      'lexeme': token,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeLiteralWithNew = messageLiteralWithNew;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageLiteralWithNew = const MessageCode(
  "LiteralWithNew",
  index: 117,
  problemMessage: r"""A literal can't be prefixed by 'new'.""",
  correctionMessage: r"""Try removing 'new'""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeLoadLibraryTakesNoArguments = messageLoadLibraryTakesNoArguments;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageLoadLibraryTakesNoArguments = const MessageCode(
  "LoadLibraryTakesNoArguments",
  analyzerCodes: <String>["LOAD_LIBRARY_TAKES_NO_ARGUMENTS"],
  problemMessage: r"""'loadLibrary' takes no arguments.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateLocalVariableUsedBeforeDeclared =
    const Template<Message Function(String name)>(
  "LocalVariableUsedBeforeDeclared",
  problemMessageTemplate:
      r"""Local variable '#name' can't be referenced before it is declared.""",
  withArguments: _withArgumentsLocalVariableUsedBeforeDeclared,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeLocalVariableUsedBeforeDeclared = const Code(
  "LocalVariableUsedBeforeDeclared",
  analyzerCodes: <String>["REFERENCED_BEFORE_DECLARATION"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsLocalVariableUsedBeforeDeclared(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeLocalVariableUsedBeforeDeclared,
    problemMessage:
        """Local variable '${name}' can't be referenced before it is declared.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateLocalVariableUsedBeforeDeclaredContext =
    const Template<Message Function(String name)>(
  "LocalVariableUsedBeforeDeclaredContext",
  problemMessageTemplate:
      r"""This is the declaration of the variable '#name'.""",
  withArguments: _withArgumentsLocalVariableUsedBeforeDeclaredContext,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeLocalVariableUsedBeforeDeclaredContext = const Code(
  "LocalVariableUsedBeforeDeclaredContext",
  severity: Severity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsLocalVariableUsedBeforeDeclaredContext(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeLocalVariableUsedBeforeDeclaredContext,
    problemMessage: """This is the declaration of the variable '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateMacroClassNotDeclaredMacro =
    const Template<Message Function(String name)>(
  "MacroClassNotDeclaredMacro",
  problemMessageTemplate:
      r"""Non-abstract class '#name' implements 'Macro' but isn't declared as a macro class.""",
  correctionMessageTemplate: r"""Try adding the 'macro' class modifier.""",
  withArguments: _withArgumentsMacroClassNotDeclaredMacro,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMacroClassNotDeclaredMacro = const Code(
  "MacroClassNotDeclaredMacro",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMacroClassNotDeclaredMacro(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeMacroClassNotDeclaredMacro,
    problemMessage:
        """Non-abstract class '${name}' implements 'Macro' but isn't declared as a macro class.""",
    correctionMessage: """Try adding the 'macro' class modifier.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateMacroDefinitionApplicationSameLibraryCycle =
    const Template<Message Function(String name)>(
  "MacroDefinitionApplicationSameLibraryCycle",
  problemMessageTemplate:
      r"""The macro '#name' can't be applied in the same library cycle where it is defined.""",
  correctionMessageTemplate:
      r"""Try moving it to a different library that does not import the one where it is applied.""",
  withArguments: _withArgumentsMacroDefinitionApplicationSameLibraryCycle,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMacroDefinitionApplicationSameLibraryCycle = const Code(
  "MacroDefinitionApplicationSameLibraryCycle",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMacroDefinitionApplicationSameLibraryCycle(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeMacroDefinitionApplicationSameLibraryCycle,
    problemMessage:
        """The macro '${name}' can't be applied in the same library cycle where it is defined.""",
    correctionMessage:
        """Try moving it to a different library that does not import the one where it is applied.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMainNotFunctionDeclaration = messageMainNotFunctionDeclaration;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMainNotFunctionDeclaration = const MessageCode(
  "MainNotFunctionDeclaration",
  problemMessage: r"""The 'main' declaration must be a function declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMainNotFunctionDeclarationExported =
    messageMainNotFunctionDeclarationExported;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMainNotFunctionDeclarationExported = const MessageCode(
  "MainNotFunctionDeclarationExported",
  problemMessage:
      r"""The exported 'main' declaration must be a function declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMainRequiredNamedParameters = messageMainRequiredNamedParameters;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMainRequiredNamedParameters = const MessageCode(
  "MainRequiredNamedParameters",
  problemMessage:
      r"""The 'main' method cannot have required named parameters.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMainRequiredNamedParametersExported =
    messageMainRequiredNamedParametersExported;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMainRequiredNamedParametersExported =
    const MessageCode(
  "MainRequiredNamedParametersExported",
  problemMessage:
      r"""The exported 'main' method cannot have required named parameters.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMainTooManyRequiredParameters =
    messageMainTooManyRequiredParameters;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMainTooManyRequiredParameters = const MessageCode(
  "MainTooManyRequiredParameters",
  problemMessage:
      r"""The 'main' method must have at most 2 required parameters.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMainTooManyRequiredParametersExported =
    messageMainTooManyRequiredParametersExported;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMainTooManyRequiredParametersExported =
    const MessageCode(
  "MainTooManyRequiredParametersExported",
  problemMessage:
      r"""The exported 'main' method must have at most 2 required parameters.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMapLiteralTypeArgumentMismatch =
    messageMapLiteralTypeArgumentMismatch;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMapLiteralTypeArgumentMismatch = const MessageCode(
  "MapLiteralTypeArgumentMismatch",
  analyzerCodes: <String>["EXPECTED_TWO_MAP_TYPE_ARGUMENTS"],
  problemMessage: r"""A map literal requires exactly two type arguments.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMapPatternTypeArgumentMismatch =
    messageMapPatternTypeArgumentMismatch;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMapPatternTypeArgumentMismatch = const MessageCode(
  "MapPatternTypeArgumentMismatch",
  analyzerCodes: <String>["EXPECTED_TWO_MAP_PATTERN_TYPE_ARGUMENTS"],
  problemMessage: r"""A map pattern requires exactly two type arguments.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateMemberConflictsWithConstructor =
    const Template<Message Function(String name)>(
  "MemberConflictsWithConstructor",
  problemMessageTemplate: r"""The member conflicts with constructor '#name'.""",
  withArguments: _withArgumentsMemberConflictsWithConstructor,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMemberConflictsWithConstructor = const Code(
  "MemberConflictsWithConstructor",
  analyzerCodes: <String>["CONFLICTS_WITH_MEMBER"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMemberConflictsWithConstructor(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeMemberConflictsWithConstructor,
    problemMessage: """The member conflicts with constructor '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateMemberConflictsWithConstructorCause =
    const Template<Message Function(String name)>(
  "MemberConflictsWithConstructorCause",
  problemMessageTemplate: r"""Conflicting constructor '#name'.""",
  withArguments: _withArgumentsMemberConflictsWithConstructorCause,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMemberConflictsWithConstructorCause = const Code(
  "MemberConflictsWithConstructorCause",
  severity: Severity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMemberConflictsWithConstructorCause(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeMemberConflictsWithConstructorCause,
    problemMessage: """Conflicting constructor '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateMemberConflictsWithFactory =
    const Template<Message Function(String name)>(
  "MemberConflictsWithFactory",
  problemMessageTemplate: r"""The member conflicts with factory '#name'.""",
  withArguments: _withArgumentsMemberConflictsWithFactory,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMemberConflictsWithFactory = const Code(
  "MemberConflictsWithFactory",
  analyzerCodes: <String>["CONFLICTS_WITH_MEMBER"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMemberConflictsWithFactory(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeMemberConflictsWithFactory,
    problemMessage: """The member conflicts with factory '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateMemberConflictsWithFactoryCause =
    const Template<Message Function(String name)>(
  "MemberConflictsWithFactoryCause",
  problemMessageTemplate: r"""Conflicting factory '#name'.""",
  withArguments: _withArgumentsMemberConflictsWithFactoryCause,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMemberConflictsWithFactoryCause = const Code(
  "MemberConflictsWithFactoryCause",
  severity: Severity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMemberConflictsWithFactoryCause(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeMemberConflictsWithFactoryCause,
    problemMessage: """Conflicting factory '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateMemberNotFound =
    const Template<Message Function(String name)>(
  "MemberNotFound",
  problemMessageTemplate: r"""Member not found: '#name'.""",
  withArguments: _withArgumentsMemberNotFound,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMemberNotFound = const Code(
  "MemberNotFound",
  analyzerCodes: <String>["UNDEFINED_GETTER"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMemberNotFound(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeMemberNotFound,
    problemMessage: """Member not found: '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateMemberShouldBeListedAsCallableInDynamicInterface =
    const Template<Message Function(String name)>(
  "MemberShouldBeListedAsCallableInDynamicInterface",
  problemMessageTemplate:
      r"""Cannot invoke member '#name' from a dynamic module.""",
  correctionMessageTemplate:
      r"""Try removing the call or update the dynamic interface to list member '#name' as callable.""",
  withArguments: _withArgumentsMemberShouldBeListedAsCallableInDynamicInterface,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMemberShouldBeListedAsCallableInDynamicInterface = const Code(
  "MemberShouldBeListedAsCallableInDynamicInterface",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMemberShouldBeListedAsCallableInDynamicInterface(
    String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeMemberShouldBeListedAsCallableInDynamicInterface,
    problemMessage: """Cannot invoke member '${name}' from a dynamic module.""",
    correctionMessage:
        """Try removing the call or update the dynamic interface to list member '${name}' as callable.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String name2)>
    templateMemberShouldBeListedAsCanBeOverriddenInDynamicInterface =
    const Template<Message Function(String name, String name2)>(
  "MemberShouldBeListedAsCanBeOverriddenInDynamicInterface",
  problemMessageTemplate:
      r"""Cannot override member '#name.#name2' in a dynamic module.""",
  correctionMessageTemplate:
      r"""Try removing the override or update the dynamic interface to list member '#name.#name2' as can-be-overridden.""",
  withArguments:
      _withArgumentsMemberShouldBeListedAsCanBeOverriddenInDynamicInterface,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMemberShouldBeListedAsCanBeOverriddenInDynamicInterface =
    const Code(
  "MemberShouldBeListedAsCanBeOverriddenInDynamicInterface",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMemberShouldBeListedAsCanBeOverriddenInDynamicInterface(
    String name, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(
    codeMemberShouldBeListedAsCanBeOverriddenInDynamicInterface,
    problemMessage:
        """Cannot override member '${name}.${name2}' in a dynamic module.""",
    correctionMessage:
        """Try removing the override or update the dynamic interface to list member '${name}.${name2}' as can-be-overridden.""",
    arguments: {
      'name': name,
      'name2': name2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMemberWithSameNameAsClass = messageMemberWithSameNameAsClass;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMemberWithSameNameAsClass = const MessageCode(
  "MemberWithSameNameAsClass",
  index: 105,
  problemMessage:
      r"""A class member can't have the same name as the enclosing class.""",
  correctionMessage: r"""Try renaming the member.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMetadataSpaceBeforeParenthesis =
    messageMetadataSpaceBeforeParenthesis;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMetadataSpaceBeforeParenthesis = const MessageCode(
  "MetadataSpaceBeforeParenthesis",
  index: 134,
  problemMessage:
      r"""Annotations can't have spaces or comments before the parenthesis.""",
  correctionMessage:
      r"""Remove any spaces or comments before the parenthesis.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMetadataTypeArguments = messageMetadataTypeArguments;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMetadataTypeArguments = const MessageCode(
  "MetadataTypeArguments",
  index: 91,
  problemMessage: r"""An annotation can't use type arguments.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMetadataTypeArgumentsUninstantiated =
    messageMetadataTypeArgumentsUninstantiated;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMetadataTypeArgumentsUninstantiated =
    const MessageCode(
  "MetadataTypeArgumentsUninstantiated",
  index: 114,
  problemMessage:
      r"""An annotation with type arguments must be followed by an argument list.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateMethodNotFound =
    const Template<Message Function(String name)>(
  "MethodNotFound",
  problemMessageTemplate: r"""Method not found: '#name'.""",
  withArguments: _withArgumentsMethodNotFound,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMethodNotFound = const Code(
  "MethodNotFound",
  analyzerCodes: <String>["UNDEFINED_METHOD"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMethodNotFound(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeMethodNotFound,
    problemMessage: """Method not found: '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMissingArgumentList = messageMissingArgumentList;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingArgumentList = const MessageCode(
  "MissingArgumentList",
  problemMessage: r"""Constructor invocations must have an argument list.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMissingAssignableSelector = messageMissingAssignableSelector;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingAssignableSelector = const MessageCode(
  "MissingAssignableSelector",
  index: 35,
  problemMessage: r"""Missing selector such as '.identifier' or '[0]'.""",
  correctionMessage: r"""Try adding a selector.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMissingAssignmentInInitializer =
    messageMissingAssignmentInInitializer;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingAssignmentInInitializer = const MessageCode(
  "MissingAssignmentInInitializer",
  index: 34,
  problemMessage: r"""Expected an assignment after the field name.""",
  correctionMessage:
      r"""To initialize a field, use the syntax 'name = value'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMissingConstFinalVarOrType = messageMissingConstFinalVarOrType;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingConstFinalVarOrType = const MessageCode(
  "MissingConstFinalVarOrType",
  index: 33,
  problemMessage:
      r"""Variables must be declared using the keywords 'const', 'final', 'var' or a type name.""",
  correctionMessage:
      r"""Try adding the name of the type of the variable or the keyword 'var'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMissingExplicitConst = messageMissingExplicitConst;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingExplicitConst = const MessageCode(
  "MissingExplicitConst",
  analyzerCodes: <String>["NOT_CONSTANT_EXPRESSION"],
  problemMessage: r"""Constant expression expected.""",
  correctionMessage: r"""Try inserting 'const'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMissingExponent = messageMissingExponent;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingExponent = const MessageCode(
  "MissingExponent",
  analyzerCodes: <String>["MISSING_DIGIT"],
  problemMessage:
      r"""Numbers in exponential notation should always contain an exponent (an integer number with an optional sign).""",
  correctionMessage:
      r"""Make sure there is an exponent, and remove any whitespace before it.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMissingExpressionInThrow = messageMissingExpressionInThrow;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingExpressionInThrow = const MessageCode(
  "MissingExpressionInThrow",
  index: 32,
  problemMessage: r"""Missing expression after 'throw'.""",
  correctionMessage:
      r"""Add an expression after 'throw' or use 'rethrow' to throw a caught exception""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMissingFunctionParameters = messageMissingFunctionParameters;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingFunctionParameters = const MessageCode(
  "MissingFunctionParameters",
  analyzerCodes: <String>["MISSING_FUNCTION_PARAMETERS"],
  problemMessage:
      r"""A function declaration needs an explicit list of parameters.""",
  correctionMessage:
      r"""Try adding a parameter list to the function declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateMissingImplementationCause =
    const Template<Message Function(String name)>(
  "MissingImplementationCause",
  problemMessageTemplate: r"""'#name' is defined here.""",
  withArguments: _withArgumentsMissingImplementationCause,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMissingImplementationCause = const Code(
  "MissingImplementationCause",
  severity: Severity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMissingImplementationCause(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeMissingImplementationCause,
    problemMessage: """'${name}' is defined here.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, List<String> _names)>
    templateMissingImplementationNotAbstract =
    const Template<Message Function(String name, List<String> _names)>(
  "MissingImplementationNotAbstract",
  problemMessageTemplate:
      r"""The non-abstract class '#name' is missing implementations for these members:
#names""",
  correctionMessageTemplate: r"""Try to either
 - provide an implementation,
 - inherit an implementation from a superclass or mixin,
 - mark the class as abstract, or
 - provide a 'noSuchMethod' implementation.
""",
  withArguments: _withArgumentsMissingImplementationNotAbstract,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMissingImplementationNotAbstract = const Code(
  "MissingImplementationNotAbstract",
  analyzerCodes: <String>["CONCRETE_CLASS_WITH_ABSTRACT_MEMBER"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMissingImplementationNotAbstract(
    String name, List<String> _names) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (_names.isEmpty) throw 'No names provided';
  String names = itemizeNames(_names);
  return new Message(
    codeMissingImplementationNotAbstract,
    problemMessage:
        """The non-abstract class '${name}' is missing implementations for these members:
${names}""",
    correctionMessage: """Try to either
 - provide an implementation,
 - inherit an implementation from a superclass or mixin,
 - mark the class as abstract, or
 - provide a 'noSuchMethod' implementation.
""",
    arguments: {
      'name': name,
      'names': _names,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMissingInput = messageMissingInput;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingInput = const MessageCode(
  "MissingInput",
  problemMessage: r"""No input file provided to the compiler.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMissingMain = messageMissingMain;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingMain = const MessageCode(
  "MissingMain",
  problemMessage: r"""No 'main' method found.""",
  correctionMessage: r"""Try adding a method named 'main' to your program.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMissingMethodParameters = messageMissingMethodParameters;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingMethodParameters = const MessageCode(
  "MissingMethodParameters",
  analyzerCodes: <String>["MISSING_METHOD_PARAMETERS"],
  problemMessage:
      r"""A method declaration needs an explicit list of parameters.""",
  correctionMessage:
      r"""Try adding a parameter list to the method declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMissingNamedSuperConstructorParameter =
    messageMissingNamedSuperConstructorParameter;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingNamedSuperConstructorParameter =
    const MessageCode(
  "MissingNamedSuperConstructorParameter",
  analyzerCodes: <String>["SUPER_FORMAL_PARAMETER_WITHOUT_ASSOCIATED_NAMED"],
  problemMessage:
      r"""The super constructor has no corresponding named parameter.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMissingOperatorKeyword = messageMissingOperatorKeyword;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingOperatorKeyword = const MessageCode(
  "MissingOperatorKeyword",
  index: 31,
  problemMessage:
      r"""Operator declarations must be preceded by the keyword 'operator'.""",
  correctionMessage: r"""Try adding the keyword 'operator'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri_)> templateMissingPartOf =
    const Template<Message Function(Uri uri_)>(
  "MissingPartOf",
  problemMessageTemplate:
      r"""Can't use '#uri' as a part, because it has no 'part of' declaration.""",
  withArguments: _withArgumentsMissingPartOf,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMissingPartOf = const Code(
  "MissingPartOf",
  analyzerCodes: <String>["PART_OF_NON_PART"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMissingPartOf(Uri uri_) {
  String? uri = relativizeUri(uri_);
  return new Message(
    codeMissingPartOf,
    problemMessage:
        """Can't use '${uri}' as a part, because it has no 'part of' declaration.""",
    arguments: {
      'uri': uri_,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMissingPositionalSuperConstructorParameter =
    messageMissingPositionalSuperConstructorParameter;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingPositionalSuperConstructorParameter =
    const MessageCode(
  "MissingPositionalSuperConstructorParameter",
  analyzerCodes: <String>[
    "SUPER_FORMAL_PARAMETER_WITHOUT_ASSOCIATED_POSITIONAL"
  ],
  problemMessage:
      r"""The super constructor has no corresponding positional parameter.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMissingPrefixInDeferredImport =
    messageMissingPrefixInDeferredImport;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingPrefixInDeferredImport = const MessageCode(
  "MissingPrefixInDeferredImport",
  index: 30,
  problemMessage: r"""Deferred imports should have a prefix.""",
  correctionMessage:
      r"""Try adding a prefix to the import by adding an 'as' clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMissingPrimaryConstructor = messageMissingPrimaryConstructor;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingPrimaryConstructor = const MessageCode(
  "MissingPrimaryConstructor",
  index: 162,
  problemMessage:
      r"""An extension type declaration must have a primary constructor declaration.""",
  correctionMessage:
      r"""Try adding a primary constructor to the extension type declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMissingPrimaryConstructorParameters =
    messageMissingPrimaryConstructorParameters;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingPrimaryConstructorParameters =
    const MessageCode(
  "MissingPrimaryConstructorParameters",
  index: 163,
  problemMessage:
      r"""A primary constructor declaration must have formal parameters.""",
  correctionMessage:
      r"""Try adding formal parameters after the primary constructor name.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMissingTypedefParameters = messageMissingTypedefParameters;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingTypedefParameters = const MessageCode(
  "MissingTypedefParameters",
  analyzerCodes: <String>["MISSING_TYPEDEF_PARAMETERS"],
  problemMessage: r"""A typedef needs an explicit list of parameters.""",
  correctionMessage: r"""Try adding a parameter list to the typedef.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateMissingVariablePattern =
    const Template<Message Function(String name)>(
  "MissingVariablePattern",
  problemMessageTemplate:
      r"""Variable pattern '#name' is missing in this branch of the logical-or pattern.""",
  correctionMessageTemplate:
      r"""Try declaring this variable pattern in the branch.""",
  withArguments: _withArgumentsMissingVariablePattern,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMissingVariablePattern = const Code(
  "MissingVariablePattern",
  analyzerCodes: <String>["MISSING_VARIABLE_PATTERN"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMissingVariablePattern(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeMissingVariablePattern,
    problemMessage:
        """Variable pattern '${name}' is missing in this branch of the logical-or pattern.""",
    correctionMessage: """Try declaring this variable pattern in the branch.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateMixinApplicationNoConcreteGetter =
    const Template<Message Function(String name)>(
  "MixinApplicationNoConcreteGetter",
  problemMessageTemplate:
      r"""The class doesn't have a concrete implementation of the super-accessed member '#name'.""",
  withArguments: _withArgumentsMixinApplicationNoConcreteGetter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMixinApplicationNoConcreteGetter = const Code(
  "MixinApplicationNoConcreteGetter",
  analyzerCodes: <String>["MIXIN_APPLICATION_NO_CONCRETE_SUPER_INVOKED_MEMBER"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMixinApplicationNoConcreteGetter(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeMixinApplicationNoConcreteGetter,
    problemMessage:
        """The class doesn't have a concrete implementation of the super-accessed member '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMixinApplicationNoConcreteMemberContext =
    messageMixinApplicationNoConcreteMemberContext;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMixinApplicationNoConcreteMemberContext =
    const MessageCode(
  "MixinApplicationNoConcreteMemberContext",
  severity: Severity.context,
  problemMessage:
      r"""This is the super-access that doesn't have a concrete target.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateMixinApplicationNoConcreteMethod =
    const Template<Message Function(String name)>(
  "MixinApplicationNoConcreteMethod",
  problemMessageTemplate:
      r"""The class doesn't have a concrete implementation of the super-invoked member '#name'.""",
  withArguments: _withArgumentsMixinApplicationNoConcreteMethod,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMixinApplicationNoConcreteMethod = const Code(
  "MixinApplicationNoConcreteMethod",
  analyzerCodes: <String>["MIXIN_APPLICATION_NO_CONCRETE_SUPER_INVOKED_MEMBER"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMixinApplicationNoConcreteMethod(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeMixinApplicationNoConcreteMethod,
    problemMessage:
        """The class doesn't have a concrete implementation of the super-invoked member '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateMixinApplicationNoConcreteSetter =
    const Template<Message Function(String name)>(
  "MixinApplicationNoConcreteSetter",
  problemMessageTemplate:
      r"""The class doesn't have a concrete implementation of the super-accessed setter '#name'.""",
  withArguments: _withArgumentsMixinApplicationNoConcreteSetter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMixinApplicationNoConcreteSetter = const Code(
  "MixinApplicationNoConcreteSetter",
  analyzerCodes: <String>["MIXIN_APPLICATION_NO_CONCRETE_SUPER_INVOKED_MEMBER"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMixinApplicationNoConcreteSetter(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeMixinApplicationNoConcreteSetter,
    problemMessage:
        """The class doesn't have a concrete implementation of the super-accessed setter '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMixinDeclaresConstructor = messageMixinDeclaresConstructor;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMixinDeclaresConstructor = const MessageCode(
  "MixinDeclaresConstructor",
  index: 95,
  problemMessage: r"""Mixins can't declare constructors.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMixinDeferredMixin = messageMixinDeferredMixin;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMixinDeferredMixin = const MessageCode(
  "MixinDeferredMixin",
  analyzerCodes: <String>["MIXIN_DEFERRED_CLASS"],
  problemMessage: r"""Classes can't mix in deferred mixins.""",
  correctionMessage: r"""Try changing the import to not be deferred.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateMixinInheritsFromNotObject =
    const Template<Message Function(String name)>(
  "MixinInheritsFromNotObject",
  problemMessageTemplate:
      r"""The class '#name' can't be used as a mixin because it extends a class other than 'Object'.""",
  withArguments: _withArgumentsMixinInheritsFromNotObject,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMixinInheritsFromNotObject = const Code(
  "MixinInheritsFromNotObject",
  analyzerCodes: <String>["MIXIN_INHERITS_FROM_NOT_OBJECT"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMixinInheritsFromNotObject(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeMixinInheritsFromNotObject,
    problemMessage:
        """The class '${name}' can't be used as a mixin because it extends a class other than 'Object'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String name2)>
    templateMixinSubtypeOfBaseIsNotBase =
    const Template<Message Function(String name, String name2)>(
  "MixinSubtypeOfBaseIsNotBase",
  problemMessageTemplate:
      r"""The mixin '#name' must be 'base' because the supertype '#name2' is 'base'.""",
  correctionMessageTemplate: r"""Try adding 'base' to the mixin.""",
  withArguments: _withArgumentsMixinSubtypeOfBaseIsNotBase,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMixinSubtypeOfBaseIsNotBase = const Code(
  "MixinSubtypeOfBaseIsNotBase",
  analyzerCodes: <String>["MIXIN_SUBTYPE_OF_BASE_IS_NOT_BASE"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMixinSubtypeOfBaseIsNotBase(String name, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(
    codeMixinSubtypeOfBaseIsNotBase,
    problemMessage:
        """The mixin '${name}' must be 'base' because the supertype '${name2}' is 'base'.""",
    correctionMessage: """Try adding 'base' to the mixin.""",
    arguments: {
      'name': name,
      'name2': name2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String name2)>
    templateMixinSubtypeOfFinalIsNotBase =
    const Template<Message Function(String name, String name2)>(
  "MixinSubtypeOfFinalIsNotBase",
  problemMessageTemplate:
      r"""The mixin '#name' must be 'base' because the supertype '#name2' is 'final'.""",
  correctionMessageTemplate: r"""Try adding 'base' to the mixin.""",
  withArguments: _withArgumentsMixinSubtypeOfFinalIsNotBase,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMixinSubtypeOfFinalIsNotBase = const Code(
  "MixinSubtypeOfFinalIsNotBase",
  analyzerCodes: <String>["MIXIN_SUBTYPE_OF_FINAL_IS_NOT_BASE"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMixinSubtypeOfFinalIsNotBase(String name, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(
    codeMixinSubtypeOfFinalIsNotBase,
    problemMessage:
        """The mixin '${name}' must be 'base' because the supertype '${name2}' is 'final'.""",
    correctionMessage: """Try adding 'base' to the mixin.""",
    arguments: {
      'name': name,
      'name2': name2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMixinSuperClassConstraintDeferredClass =
    messageMixinSuperClassConstraintDeferredClass;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMixinSuperClassConstraintDeferredClass =
    const MessageCode(
  "MixinSuperClassConstraintDeferredClass",
  analyzerCodes: <String>["MIXIN_SUPER_CLASS_CONSTRAINT_DEFERRED_CLASS"],
  problemMessage:
      r"""Deferred classes can't be used as superclass constraints.""",
  correctionMessage: r"""Try changing the import to not be deferred.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMixinWithClause = messageMixinWithClause;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMixinWithClause = const MessageCode(
  "MixinWithClause",
  index: 154,
  problemMessage: r"""A mixin can't have a with clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string, String string2)>
    templateModifierOutOfOrder =
    const Template<Message Function(String string, String string2)>(
  "ModifierOutOfOrder",
  problemMessageTemplate:
      r"""The modifier '#string' should be before the modifier '#string2'.""",
  correctionMessageTemplate: r"""Try re-ordering the modifiers.""",
  withArguments: _withArgumentsModifierOutOfOrder,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeModifierOutOfOrder = const Code(
  "ModifierOutOfOrder",
  index: 56,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsModifierOutOfOrder(String string, String string2) {
  if (string.isEmpty) throw 'No string provided';
  if (string2.isEmpty) throw 'No string provided';
  return new Message(
    codeModifierOutOfOrder,
    problemMessage:
        """The modifier '${string}' should be before the modifier '${string2}'.""",
    correctionMessage: """Try re-ordering the modifiers.""",
    arguments: {
      'string': string,
      'string2': string2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMoreThanOneSuperInitializer = messageMoreThanOneSuperInitializer;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMoreThanOneSuperInitializer = const MessageCode(
  "MoreThanOneSuperInitializer",
  analyzerCodes: <String>["MULTIPLE_SUPER_INITIALIZERS"],
  problemMessage: r"""Can't have more than one 'super' initializer.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string, String string2)>
    templateMultipleClauses =
    const Template<Message Function(String string, String string2)>(
  "MultipleClauses",
  problemMessageTemplate:
      r"""Each '#string' definition can have at most one '#string2' clause.""",
  correctionMessageTemplate:
      r"""Try combining all of the '#string2' clauses into a single clause.""",
  withArguments: _withArgumentsMultipleClauses,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMultipleClauses = const Code(
  "MultipleClauses",
  index: 121,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMultipleClauses(String string, String string2) {
  if (string.isEmpty) throw 'No string provided';
  if (string2.isEmpty) throw 'No string provided';
  return new Message(
    codeMultipleClauses,
    problemMessage:
        """Each '${string}' definition can have at most one '${string2}' clause.""",
    correctionMessage:
        """Try combining all of the '${string2}' clauses into a single clause.""",
    arguments: {
      'string': string,
      'string2': string2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMultipleExtends = messageMultipleExtends;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMultipleExtends = const MessageCode(
  "MultipleExtends",
  index: 28,
  problemMessage:
      r"""Each class definition can have at most one extends clause.""",
  correctionMessage:
      r"""Try choosing one superclass and define your class to implement (or mix in) the others.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMultipleImplements = messageMultipleImplements;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMultipleImplements = const MessageCode(
  "MultipleImplements",
  analyzerCodes: <String>["MULTIPLE_IMPLEMENTS_CLAUSES"],
  problemMessage:
      r"""Each class definition can have at most one implements clause.""",
  correctionMessage:
      r"""Try combining all of the implements clauses into a single clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMultipleLibraryDirectives = messageMultipleLibraryDirectives;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMultipleLibraryDirectives = const MessageCode(
  "MultipleLibraryDirectives",
  index: 27,
  problemMessage: r"""Only one library directive may be declared in a file.""",
  correctionMessage: r"""Try removing all but one of the library directives.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMultipleOnClauses = messageMultipleOnClauses;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMultipleOnClauses = const MessageCode(
  "MultipleOnClauses",
  index: 26,
  problemMessage: r"""Each mixin definition can have at most one on clause.""",
  correctionMessage:
      r"""Try combining all of the on clauses into a single clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMultipleRepresentationFields =
    messageMultipleRepresentationFields;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMultipleRepresentationFields = const MessageCode(
  "MultipleRepresentationFields",
  analyzerCodes: <String>["MULTIPLE_REPRESENTATION_FIELDS"],
  problemMessage:
      r"""Each extension type should have exactly one representation field.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMultipleVarianceModifiers = messageMultipleVarianceModifiers;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMultipleVarianceModifiers = const MessageCode(
  "MultipleVarianceModifiers",
  index: 97,
  problemMessage:
      r"""Each type parameter can have at most one variance modifier.""",
  correctionMessage:
      r"""Use at most one of the 'in', 'out', or 'inout' modifiers.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeMultipleWith = messageMultipleWith;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMultipleWith = const MessageCode(
  "MultipleWith",
  index: 24,
  problemMessage:
      r"""Each class definition can have at most one with clause.""",
  correctionMessage:
      r"""Try combining all of the with clauses into a single clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateNameNotFound =
    const Template<Message Function(String name)>(
  "NameNotFound",
  problemMessageTemplate: r"""Undefined name '#name'.""",
  withArguments: _withArgumentsNameNotFound,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNameNotFound = const Code(
  "NameNotFound",
  analyzerCodes: <String>["UNDEFINED_NAME"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNameNotFound(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeNameNotFound,
    problemMessage: """Undefined name '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNamedFieldClashesWithPositionalFieldInRecord =
    messageNamedFieldClashesWithPositionalFieldInRecord;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNamedFieldClashesWithPositionalFieldInRecord =
    const MessageCode(
  "NamedFieldClashesWithPositionalFieldInRecord",
  analyzerCodes: <String>["INVALID_FIELD_NAME"],
  problemMessage:
      r"""Record field names can't be a dollar sign followed by an integer when integer is the index of a positional field.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNamedFunctionExpression = messageNamedFunctionExpression;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNamedFunctionExpression = const MessageCode(
  "NamedFunctionExpression",
  analyzerCodes: <String>["NAMED_FUNCTION_EXPRESSION"],
  problemMessage: r"""A function expression can't have a name.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String name2)>
    templateNamedMixinOverride =
    const Template<Message Function(String name, String name2)>(
  "NamedMixinOverride",
  problemMessageTemplate:
      r"""The mixin application class '#name' introduces an erroneous override of '#name2'.""",
  withArguments: _withArgumentsNamedMixinOverride,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNamedMixinOverride = const Code(
  "NamedMixinOverride",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNamedMixinOverride(String name, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(
    codeNamedMixinOverride,
    problemMessage:
        """The mixin application class '${name}' introduces an erroneous override of '${name2}'.""",
    arguments: {
      'name': name,
      'name2': name2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNamedParametersInExtensionTypeDeclaration =
    messageNamedParametersInExtensionTypeDeclaration;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNamedParametersInExtensionTypeDeclaration =
    const MessageCode(
  "NamedParametersInExtensionTypeDeclaration",
  problemMessage:
      r"""Extension type declarations can't have named parameters.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNativeClauseShouldBeAnnotation =
    messageNativeClauseShouldBeAnnotation;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNativeClauseShouldBeAnnotation = const MessageCode(
  "NativeClauseShouldBeAnnotation",
  index: 23,
  problemMessage: r"""Native clause in this form is deprecated.""",
  correctionMessage:
      r"""Try removing this native clause and adding @native() or @native('native-name') before the declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNegativeVariableDimension = messageNegativeVariableDimension;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNegativeVariableDimension = const MessageCode(
  "NegativeVariableDimension",
  problemMessage:
      r"""The variable dimension of a variable-length array must be non-negative.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNeverReachableSwitchDefaultError =
    messageNeverReachableSwitchDefaultError;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNeverReachableSwitchDefaultError = const MessageCode(
  "NeverReachableSwitchDefaultError",
  problemMessage:
      r"""`null` encountered as case in a switch expression with a non-nullable enum type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNeverReachableSwitchExpressionError =
    messageNeverReachableSwitchExpressionError;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNeverReachableSwitchExpressionError =
    const MessageCode(
  "NeverReachableSwitchExpressionError",
  problemMessage:
      r"""`null` encountered as case in a switch expression with a non-nullable type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNeverReachableSwitchStatementError =
    messageNeverReachableSwitchStatementError;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNeverReachableSwitchStatementError = const MessageCode(
  "NeverReachableSwitchStatementError",
  problemMessage:
      r"""`null` encountered as case in a switch statement with a non-nullable type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNeverValueError = messageNeverValueError;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNeverValueError = const MessageCode(
  "NeverValueError",
  problemMessage:
      r"""`null` encountered as the result from expression with type `Never`.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNewAsSelector = messageNewAsSelector;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNewAsSelector = const MessageCode(
  "NewAsSelector",
  problemMessage: r"""'new' can only be used as a constructor reference.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNoAugmentSuperInvokeTarget = messageNoAugmentSuperInvokeTarget;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNoAugmentSuperInvokeTarget = const MessageCode(
  "NoAugmentSuperInvokeTarget",
  problemMessage: r"""Cannot call 'augment super'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNoAugmentSuperReadTarget = messageNoAugmentSuperReadTarget;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNoAugmentSuperReadTarget = const MessageCode(
  "NoAugmentSuperReadTarget",
  problemMessage: r"""Cannot read from 'augment super'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNoAugmentSuperWriteTarget = messageNoAugmentSuperWriteTarget;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNoAugmentSuperWriteTarget = const MessageCode(
  "NoAugmentSuperWriteTarget",
  problemMessage: r"""Cannot write to 'augment super'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateNoFormals =
    const Template<Message Function(Token token)>(
  "NoFormals",
  problemMessageTemplate: r"""A function should have formal parameters.""",
  correctionMessageTemplate:
      r"""Try adding '()' after '#lexeme', or add 'get' before '#lexeme' to declare a getter.""",
  withArguments: _withArgumentsNoFormals,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNoFormals = const Code(
  "NoFormals",
  analyzerCodes: <String>["MISSING_FUNCTION_PARAMETERS"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNoFormals(Token token) {
  String lexeme = token.lexeme;
  return new Message(
    codeNoFormals,
    problemMessage: """A function should have formal parameters.""",
    correctionMessage:
        """Try adding '()' after '${lexeme}', or add 'get' before '${lexeme}' to declare a getter.""",
    arguments: {
      'lexeme': token,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNoMacroApplicationTarget = messageNoMacroApplicationTarget;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNoMacroApplicationTarget = const MessageCode(
  "NoMacroApplicationTarget",
  problemMessage: r"""The macro can not be applied to this declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateNoSuchNamedParameter =
    const Template<Message Function(String name)>(
  "NoSuchNamedParameter",
  problemMessageTemplate: r"""No named parameter with the name '#name'.""",
  withArguments: _withArgumentsNoSuchNamedParameter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNoSuchNamedParameter = const Code(
  "NoSuchNamedParameter",
  analyzerCodes: <String>["UNDEFINED_NAMED_PARAMETER"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNoSuchNamedParameter(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeNoSuchNamedParameter,
    problemMessage: """No named parameter with the name '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNoUnnamedConstructorInObject =
    messageNoUnnamedConstructorInObject;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNoUnnamedConstructorInObject = const MessageCode(
  "NoUnnamedConstructorInObject",
  problemMessage: r"""'Object' has no unnamed constructor.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String character, int codePoint)>
    templateNonAsciiIdentifier =
    const Template<Message Function(String character, int codePoint)>(
  "NonAsciiIdentifier",
  problemMessageTemplate:
      r"""The non-ASCII character '#character' (#unicode) can't be used in identifiers, only in strings and comments.""",
  correctionMessageTemplate:
      r"""Try using an US-ASCII letter, a digit, '_' (an underscore), or '$' (a dollar sign).""",
  withArguments: _withArgumentsNonAsciiIdentifier,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNonAsciiIdentifier = const Code(
  "NonAsciiIdentifier",
  analyzerCodes: <String>["ILLEGAL_CHARACTER"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonAsciiIdentifier(String character, int codePoint) {
  if (character.runes.length != 1) throw "Not a character '${character}'";
  String unicode =
      "U+${codePoint.toRadixString(16).toUpperCase().padLeft(4, '0')}";
  return new Message(
    codeNonAsciiIdentifier,
    problemMessage:
        """The non-ASCII character '${character}' (${unicode}) can't be used in identifiers, only in strings and comments.""",
    correctionMessage:
        """Try using an US-ASCII letter, a digit, '_' (an underscore), or '\$' (a dollar sign).""",
    arguments: {
      'character': character,
      'unicode': codePoint,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(int codePoint)> templateNonAsciiWhitespace =
    const Template<Message Function(int codePoint)>(
  "NonAsciiWhitespace",
  problemMessageTemplate:
      r"""The non-ASCII space character #unicode can only be used in strings and comments.""",
  withArguments: _withArgumentsNonAsciiWhitespace,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNonAsciiWhitespace = const Code(
  "NonAsciiWhitespace",
  analyzerCodes: <String>["ILLEGAL_CHARACTER"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonAsciiWhitespace(int codePoint) {
  String unicode =
      "U+${codePoint.toRadixString(16).toUpperCase().padLeft(4, '0')}";
  return new Message(
    codeNonAsciiWhitespace,
    problemMessage:
        """The non-ASCII space character ${unicode} can only be used in strings and comments.""",
    arguments: {
      'unicode': codePoint,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateNonAugmentationClassConflict =
    const Template<Message Function(String name)>(
  "NonAugmentationClassConflict",
  problemMessageTemplate:
      r"""Class '#name' conflicts with an existing class of the same name in the augmented library.""",
  correctionMessageTemplate:
      r"""Try changing the name of the class or adding an 'augment' modifier.""",
  withArguments: _withArgumentsNonAugmentationClassConflict,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNonAugmentationClassConflict = const Code(
  "NonAugmentationClassConflict",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonAugmentationClassConflict(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeNonAugmentationClassConflict,
    problemMessage:
        """Class '${name}' conflicts with an existing class of the same name in the augmented library.""",
    correctionMessage:
        """Try changing the name of the class or adding an 'augment' modifier.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNonAugmentationClassConflictCause =
    messageNonAugmentationClassConflictCause;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNonAugmentationClassConflictCause = const MessageCode(
  "NonAugmentationClassConflictCause",
  severity: Severity.context,
  problemMessage: r"""This is the existing class.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateNonAugmentationClassMemberConflict =
    const Template<Message Function(String name)>(
  "NonAugmentationClassMemberConflict",
  problemMessageTemplate:
      r"""Member '#name' conflicts with an existing member of the same name in the augmented class.""",
  correctionMessageTemplate:
      r"""Try changing the name of the member or adding an 'augment' modifier.""",
  withArguments: _withArgumentsNonAugmentationClassMemberConflict,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNonAugmentationClassMemberConflict = const Code(
  "NonAugmentationClassMemberConflict",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonAugmentationClassMemberConflict(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeNonAugmentationClassMemberConflict,
    problemMessage:
        """Member '${name}' conflicts with an existing member of the same name in the augmented class.""",
    correctionMessage:
        """Try changing the name of the member or adding an 'augment' modifier.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateNonAugmentationConstructorConflict =
    const Template<Message Function(String name)>(
  "NonAugmentationConstructorConflict",
  problemMessageTemplate:
      r"""Constructor '#name' conflicts with an existing constructor of the same name in the augmented class.""",
  correctionMessageTemplate:
      r"""Try changing the name of the constructor or adding an 'augment' modifier.""",
  withArguments: _withArgumentsNonAugmentationConstructorConflict,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNonAugmentationConstructorConflict = const Code(
  "NonAugmentationConstructorConflict",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonAugmentationConstructorConflict(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeNonAugmentationConstructorConflict,
    problemMessage:
        """Constructor '${name}' conflicts with an existing constructor of the same name in the augmented class.""",
    correctionMessage:
        """Try changing the name of the constructor or adding an 'augment' modifier.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNonAugmentationConstructorConflictCause =
    messageNonAugmentationConstructorConflictCause;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNonAugmentationConstructorConflictCause =
    const MessageCode(
  "NonAugmentationConstructorConflictCause",
  severity: Severity.context,
  problemMessage: r"""This is the existing constructor.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNonAugmentationDeclarationConflictCause =
    messageNonAugmentationDeclarationConflictCause;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNonAugmentationDeclarationConflictCause =
    const MessageCode(
  "NonAugmentationDeclarationConflictCause",
  severity: Severity.context,
  problemMessage: r"""This is the existing declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateNonAugmentationLibraryConflict =
    const Template<Message Function(String name)>(
  "NonAugmentationLibraryConflict",
  problemMessageTemplate:
      r"""Declaration '#name' conflicts with an existing declaration of the same name in the augmented library.""",
  correctionMessageTemplate: r"""Try changing the name of the declaration.""",
  withArguments: _withArgumentsNonAugmentationLibraryConflict,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNonAugmentationLibraryConflict = const Code(
  "NonAugmentationLibraryConflict",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonAugmentationLibraryConflict(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeNonAugmentationLibraryConflict,
    problemMessage:
        """Declaration '${name}' conflicts with an existing declaration of the same name in the augmented library.""",
    correctionMessage: """Try changing the name of the declaration.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateNonAugmentationLibraryMemberConflict =
    const Template<Message Function(String name)>(
  "NonAugmentationLibraryMemberConflict",
  problemMessageTemplate:
      r"""Member '#name' conflicts with an existing member of the same name in the augmented library.""",
  correctionMessageTemplate:
      r"""Try changing the name of the member or adding an 'augment' modifier.""",
  withArguments: _withArgumentsNonAugmentationLibraryMemberConflict,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNonAugmentationLibraryMemberConflict = const Code(
  "NonAugmentationLibraryMemberConflict",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonAugmentationLibraryMemberConflict(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeNonAugmentationLibraryMemberConflict,
    problemMessage:
        """Member '${name}' conflicts with an existing member of the same name in the augmented library.""",
    correctionMessage:
        """Try changing the name of the member or adding an 'augment' modifier.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNonAugmentationMemberConflictCause =
    messageNonAugmentationMemberConflictCause;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNonAugmentationMemberConflictCause = const MessageCode(
  "NonAugmentationMemberConflictCause",
  severity: Severity.context,
  problemMessage: r"""This is the existing member.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNonBoolCondition = messageNonBoolCondition;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNonBoolCondition = const MessageCode(
  "NonBoolCondition",
  analyzerCodes: <String>["NON_BOOL_CONDITION"],
  problemMessage: r"""Conditions must have a static type of 'bool'.""",
  correctionMessage: r"""Try changing the condition.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNonConstConstructor = messageNonConstConstructor;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNonConstConstructor = const MessageCode(
  "NonConstConstructor",
  analyzerCodes: <String>["NOT_CONSTANT_EXPRESSION"],
  problemMessage:
      r"""Cannot invoke a non-'const' constructor where a const expression is expected.""",
  correctionMessage: r"""Try using a constructor or factory that is 'const'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNonConstFactory = messageNonConstFactory;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNonConstFactory = const MessageCode(
  "NonConstFactory",
  analyzerCodes: <String>["NOT_CONSTANT_EXPRESSION"],
  problemMessage:
      r"""Cannot invoke a non-'const' factory where a const expression is expected.""",
  correctionMessage: r"""Try using a constructor or factory that is 'const'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNonCovariantTypeParameterInRepresentationType =
    messageNonCovariantTypeParameterInRepresentationType;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNonCovariantTypeParameterInRepresentationType =
    const MessageCode(
  "NonCovariantTypeParameterInRepresentationType",
  problemMessage:
      r"""An extension type parameter can't be used non-covariantly in its representation type.""",
  correctionMessage:
      r"""Try removing the type parameters from function parameter types and type parameter bounds.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNonExtensionTypeMemberContext =
    messageNonExtensionTypeMemberContext;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNonExtensionTypeMemberContext = const MessageCode(
  "NonExtensionTypeMemberContext",
  severity: Severity.context,
  problemMessage: r"""This is the inherited non-extension type member.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNonExtensionTypeMemberOneOfContext =
    messageNonExtensionTypeMemberOneOfContext;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNonExtensionTypeMemberOneOfContext = const MessageCode(
  "NonExtensionTypeMemberOneOfContext",
  severity: Severity.context,
  problemMessage:
      r"""This is one of the inherited non-extension type members.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateNonNullableNotAssignedError =
    const Template<Message Function(String name)>(
  "NonNullableNotAssignedError",
  problemMessageTemplate:
      r"""Non-nullable variable '#name' must be assigned before it can be used.""",
  withArguments: _withArgumentsNonNullableNotAssignedError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNonNullableNotAssignedError = const Code(
  "NonNullableNotAssignedError",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonNullableNotAssignedError(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeNonNullableNotAssignedError,
    problemMessage:
        """Non-nullable variable '${name}' must be assigned before it can be used.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNonPartOfDirectiveInPart = messageNonPartOfDirectiveInPart;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNonPartOfDirectiveInPart = const MessageCode(
  "NonPartOfDirectiveInPart",
  analyzerCodes: <String>["NON_PART_OF_DIRECTIVE_IN_PART"],
  problemMessage:
      r"""The part-of directive must be the only directive in a part.""",
  correctionMessage:
      r"""Try removing the other directives, or moving them to the library for which this is a part.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateNonPatchClassConflict =
    const Template<Message Function(String name)>(
  "NonPatchClassConflict",
  problemMessageTemplate:
      r"""Class '#name' conflicts with an existing class of the same name in the origin library.""",
  correctionMessageTemplate:
      r"""Try changing the name of the class or adding an '@patch' annotation.""",
  withArguments: _withArgumentsNonPatchClassConflict,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNonPatchClassConflict = const Code(
  "NonPatchClassConflict",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonPatchClassConflict(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeNonPatchClassConflict,
    problemMessage:
        """Class '${name}' conflicts with an existing class of the same name in the origin library.""",
    correctionMessage:
        """Try changing the name of the class or adding an '@patch' annotation.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateNonPatchClassMemberConflict =
    const Template<Message Function(String name)>(
  "NonPatchClassMemberConflict",
  problemMessageTemplate:
      r"""Member '#name' conflicts with an existing member of the same name in the origin class.""",
  correctionMessageTemplate:
      r"""Try changing the name of the member or adding an '@patch' annotation.""",
  withArguments: _withArgumentsNonPatchClassMemberConflict,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNonPatchClassMemberConflict = const Code(
  "NonPatchClassMemberConflict",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonPatchClassMemberConflict(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeNonPatchClassMemberConflict,
    problemMessage:
        """Member '${name}' conflicts with an existing member of the same name in the origin class.""",
    correctionMessage:
        """Try changing the name of the member or adding an '@patch' annotation.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateNonPatchConstructorConflict =
    const Template<Message Function(String name)>(
  "NonPatchConstructorConflict",
  problemMessageTemplate:
      r"""Constructor '#name' conflicts with an existing constructor of the same name in the origin class.""",
  correctionMessageTemplate:
      r"""Try changing the name of the constructor or adding an '@patch' annotation.""",
  withArguments: _withArgumentsNonPatchConstructorConflict,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNonPatchConstructorConflict = const Code(
  "NonPatchConstructorConflict",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonPatchConstructorConflict(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeNonPatchConstructorConflict,
    problemMessage:
        """Constructor '${name}' conflicts with an existing constructor of the same name in the origin class.""",
    correctionMessage:
        """Try changing the name of the constructor or adding an '@patch' annotation.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateNonPatchLibraryConflict =
    const Template<Message Function(String name)>(
  "NonPatchLibraryConflict",
  problemMessageTemplate:
      r"""Declaration '#name' conflicts with an existing declaration of the same name in the origin library.""",
  correctionMessageTemplate: r"""Try changing the name of the declaration.""",
  withArguments: _withArgumentsNonPatchLibraryConflict,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNonPatchLibraryConflict = const Code(
  "NonPatchLibraryConflict",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonPatchLibraryConflict(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeNonPatchLibraryConflict,
    problemMessage:
        """Declaration '${name}' conflicts with an existing declaration of the same name in the origin library.""",
    correctionMessage: """Try changing the name of the declaration.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateNonPatchLibraryMemberConflict =
    const Template<Message Function(String name)>(
  "NonPatchLibraryMemberConflict",
  problemMessageTemplate:
      r"""Member '#name' conflicts with an existing member of the same name in the origin library.""",
  correctionMessageTemplate:
      r"""Try changing the name of the member or adding an '@patch' annotation.""",
  withArguments: _withArgumentsNonPatchLibraryMemberConflict,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNonPatchLibraryMemberConflict = const Code(
  "NonPatchLibraryMemberConflict",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonPatchLibraryMemberConflict(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeNonPatchLibraryMemberConflict,
    problemMessage:
        """Member '${name}' conflicts with an existing member of the same name in the origin library.""",
    correctionMessage:
        """Try changing the name of the member or adding an '@patch' annotation.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNonPositiveArrayDimensions = messageNonPositiveArrayDimensions;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNonPositiveArrayDimensions = const MessageCode(
  "NonPositiveArrayDimensions",
  problemMessage: r"""Array dimensions must be positive numbers.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateNonSimpleBoundViaReference =
    const Template<Message Function(String name)>(
  "NonSimpleBoundViaReference",
  problemMessageTemplate:
      r"""Bound of this variable references raw type '#name'.""",
  withArguments: _withArgumentsNonSimpleBoundViaReference,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNonSimpleBoundViaReference = const Code(
  "NonSimpleBoundViaReference",
  severity: Severity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonSimpleBoundViaReference(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeNonSimpleBoundViaReference,
    problemMessage: """Bound of this variable references raw type '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateNonSimpleBoundViaVariable =
    const Template<Message Function(String name)>(
  "NonSimpleBoundViaVariable",
  problemMessageTemplate:
      r"""Bound of this variable references variable '#name' from the same declaration.""",
  withArguments: _withArgumentsNonSimpleBoundViaVariable,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNonSimpleBoundViaVariable = const Code(
  "NonSimpleBoundViaVariable",
  severity: Severity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonSimpleBoundViaVariable(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeNonSimpleBoundViaVariable,
    problemMessage:
        """Bound of this variable references variable '${name}' from the same declaration.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNonVoidReturnOperator = messageNonVoidReturnOperator;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNonVoidReturnOperator = const MessageCode(
  "NonVoidReturnOperator",
  analyzerCodes: <String>["NON_VOID_RETURN_FOR_OPERATOR"],
  problemMessage: r"""The return type of the operator []= must be 'void'.""",
  correctionMessage: r"""Try changing the return type to 'void'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNonVoidReturnSetter = messageNonVoidReturnSetter;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNonVoidReturnSetter = const MessageCode(
  "NonVoidReturnSetter",
  analyzerCodes: <String>["NON_VOID_RETURN_FOR_SETTER"],
  problemMessage:
      r"""The return type of the setter must be 'void' or absent.""",
  correctionMessage:
      r"""Try removing the return type, or define a method rather than a setter.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNotAConstantExpression = messageNotAConstantExpression;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNotAConstantExpression = const MessageCode(
  "NotAConstantExpression",
  analyzerCodes: <String>["NOT_CONSTANT_EXPRESSION"],
  problemMessage: r"""Not a constant expression.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String name2)>
    templateNotAPrefixInTypeAnnotation =
    const Template<Message Function(String name, String name2)>(
  "NotAPrefixInTypeAnnotation",
  problemMessageTemplate:
      r"""'#name.#name2' can't be used as a type because '#name' doesn't refer to an import prefix.""",
  withArguments: _withArgumentsNotAPrefixInTypeAnnotation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNotAPrefixInTypeAnnotation = const Code(
  "NotAPrefixInTypeAnnotation",
  analyzerCodes: <String>["NOT_A_TYPE"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNotAPrefixInTypeAnnotation(String name, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(
    codeNotAPrefixInTypeAnnotation,
    problemMessage:
        """'${name}.${name2}' can't be used as a type because '${name}' doesn't refer to an import prefix.""",
    arguments: {
      'name': name,
      'name2': name2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateNotAType =
    const Template<Message Function(String name)>(
  "NotAType",
  problemMessageTemplate: r"""'#name' isn't a type.""",
  withArguments: _withArgumentsNotAType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNotAType = const Code(
  "NotAType",
  analyzerCodes: <String>["NOT_A_TYPE"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNotAType(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeNotAType,
    problemMessage: """'${name}' isn't a type.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNotATypeContext = messageNotATypeContext;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNotATypeContext = const MessageCode(
  "NotATypeContext",
  severity: Severity.context,
  problemMessage: r"""This isn't a type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNotAnLvalue = messageNotAnLvalue;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNotAnLvalue = const MessageCode(
  "NotAnLvalue",
  analyzerCodes: <String>["NOT_AN_LVALUE"],
  problemMessage: r"""Can't assign to this.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateNotBinaryOperator =
    const Template<Message Function(Token token)>(
  "NotBinaryOperator",
  problemMessageTemplate: r"""'#lexeme' isn't a binary operator.""",
  withArguments: _withArgumentsNotBinaryOperator,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNotBinaryOperator = const Code(
  "NotBinaryOperator",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNotBinaryOperator(Token token) {
  String lexeme = token.lexeme;
  return new Message(
    codeNotBinaryOperator,
    problemMessage: """'${lexeme}' isn't a binary operator.""",
    arguments: {
      'lexeme': token,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)> templateNotConstantExpression =
    const Template<Message Function(String string)>(
  "NotConstantExpression",
  problemMessageTemplate: r"""#string is not a constant expression.""",
  withArguments: _withArgumentsNotConstantExpression,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNotConstantExpression = const Code(
  "NotConstantExpression",
  analyzerCodes: <String>["NOT_CONSTANT_EXPRESSION"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNotConstantExpression(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(
    codeNotConstantExpression,
    problemMessage: """${string} is not a constant expression.""",
    arguments: {
      'string': string,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNullAwareCascadeOutOfOrder = messageNullAwareCascadeOutOfOrder;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNullAwareCascadeOutOfOrder = const MessageCode(
  "NullAwareCascadeOutOfOrder",
  index: 96,
  problemMessage:
      r"""The '?..' cascade operator must be first in the cascade sequence.""",
  correctionMessage:
      r"""Try moving the '?..' operator to be the first cascade operator in the sequence.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateNullableInterfaceError =
    const Template<Message Function(String name)>(
  "NullableInterfaceError",
  problemMessageTemplate: r"""Can't implement '#name' because it's nullable.""",
  correctionMessageTemplate: r"""Try removing the question mark.""",
  withArguments: _withArgumentsNullableInterfaceError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNullableInterfaceError = const Code(
  "NullableInterfaceError",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNullableInterfaceError(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeNullableInterfaceError,
    problemMessage: """Can't implement '${name}' because it's nullable.""",
    correctionMessage: """Try removing the question mark.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateNullableMixinError =
    const Template<Message Function(String name)>(
  "NullableMixinError",
  problemMessageTemplate: r"""Can't mix '#name' in because it's nullable.""",
  correctionMessageTemplate: r"""Try removing the question mark.""",
  withArguments: _withArgumentsNullableMixinError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNullableMixinError = const Code(
  "NullableMixinError",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNullableMixinError(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeNullableMixinError,
    problemMessage: """Can't mix '${name}' in because it's nullable.""",
    correctionMessage: """Try removing the question mark.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNullableSpreadError = messageNullableSpreadError;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNullableSpreadError = const MessageCode(
  "NullableSpreadError",
  problemMessage:
      r"""An expression whose value can be 'null' must be null-checked before it can be dereferenced.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateNullableSuperclassError =
    const Template<Message Function(String name)>(
  "NullableSuperclassError",
  problemMessageTemplate: r"""Can't extend '#name' because it's nullable.""",
  correctionMessageTemplate: r"""Try removing the question mark.""",
  withArguments: _withArgumentsNullableSuperclassError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNullableSuperclassError = const Code(
  "NullableSuperclassError",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNullableSuperclassError(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeNullableSuperclassError,
    problemMessage: """Can't extend '${name}' because it's nullable.""",
    correctionMessage: """Try removing the question mark.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateNullableTearoffError =
    const Template<Message Function(String name)>(
  "NullableTearoffError",
  problemMessageTemplate:
      r"""Can't tear off method '#name' from a potentially null value.""",
  withArguments: _withArgumentsNullableTearoffError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeNullableTearoffError = const Code(
  "NullableTearoffError",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNullableTearoffError(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeNullableTearoffError,
    problemMessage:
        """Can't tear off method '${name}' from a potentially null value.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeObjectExtends = messageObjectExtends;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageObjectExtends = const MessageCode(
  "ObjectExtends",
  problemMessage: r"""The class 'Object' can't have a superclass.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeObjectImplements = messageObjectImplements;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageObjectImplements = const MessageCode(
  "ObjectImplements",
  problemMessage: r"""The class 'Object' can't implement anything.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeObjectMemberNameUsedForRecordField =
    messageObjectMemberNameUsedForRecordField;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageObjectMemberNameUsedForRecordField = const MessageCode(
  "ObjectMemberNameUsedForRecordField",
  problemMessage:
      r"""Record field names can't be the same as a member from 'Object'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeObjectMixesIn = messageObjectMixesIn;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageObjectMixesIn = const MessageCode(
  "ObjectMixesIn",
  problemMessage: r"""The class 'Object' can't use mixins.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeObsoleteColonForDefaultValue =
    messageObsoleteColonForDefaultValue;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageObsoleteColonForDefaultValue = const MessageCode(
  "ObsoleteColonForDefaultValue",
  problemMessage:
      r"""Using a colon as a separator before a default value is no longer supported.""",
  correctionMessage: r"""Try replacing the colon with an equal sign.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeOnlyTry = messageOnlyTry;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageOnlyTry = const MessageCode(
  "OnlyTry",
  index: 20,
  problemMessage:
      r"""A try block must be followed by an 'on', 'catch', or 'finally' clause.""",
  correctionMessage:
      r"""Try adding either a catch or finally clause, or remove the try statement.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateOperatorMinusParameterMismatch =
    const Template<Message Function(String name)>(
  "OperatorMinusParameterMismatch",
  problemMessageTemplate:
      r"""Operator '#name' should have zero or one parameter.""",
  correctionMessageTemplate:
      r"""With zero parameters, it has the syntactic form '-a', formally known as 'unary-'. With one parameter, it has the syntactic form 'a - b', formally known as '-'.""",
  withArguments: _withArgumentsOperatorMinusParameterMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeOperatorMinusParameterMismatch = const Code(
  "OperatorMinusParameterMismatch",
  analyzerCodes: <String>["WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR_MINUS"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOperatorMinusParameterMismatch(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeOperatorMinusParameterMismatch,
    problemMessage: """Operator '${name}' should have zero or one parameter.""",
    correctionMessage:
        """With zero parameters, it has the syntactic form '-a', formally known as 'unary-'. With one parameter, it has the syntactic form 'a - b', formally known as '-'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateOperatorParameterMismatch0 =
    const Template<Message Function(String name)>(
  "OperatorParameterMismatch0",
  problemMessageTemplate:
      r"""Operator '#name' shouldn't have any parameters.""",
  withArguments: _withArgumentsOperatorParameterMismatch0,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeOperatorParameterMismatch0 = const Code(
  "OperatorParameterMismatch0",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOperatorParameterMismatch0(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeOperatorParameterMismatch0,
    problemMessage: """Operator '${name}' shouldn't have any parameters.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateOperatorParameterMismatch1 =
    const Template<Message Function(String name)>(
  "OperatorParameterMismatch1",
  problemMessageTemplate:
      r"""Operator '#name' should have exactly one parameter.""",
  withArguments: _withArgumentsOperatorParameterMismatch1,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeOperatorParameterMismatch1 = const Code(
  "OperatorParameterMismatch1",
  analyzerCodes: <String>["WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOperatorParameterMismatch1(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeOperatorParameterMismatch1,
    problemMessage: """Operator '${name}' should have exactly one parameter.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateOperatorParameterMismatch2 =
    const Template<Message Function(String name)>(
  "OperatorParameterMismatch2",
  problemMessageTemplate:
      r"""Operator '#name' should have exactly two parameters.""",
  withArguments: _withArgumentsOperatorParameterMismatch2,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeOperatorParameterMismatch2 = const Code(
  "OperatorParameterMismatch2",
  analyzerCodes: <String>["WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOperatorParameterMismatch2(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeOperatorParameterMismatch2,
    problemMessage:
        """Operator '${name}' should have exactly two parameters.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeOperatorWithOptionalFormals = messageOperatorWithOptionalFormals;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageOperatorWithOptionalFormals = const MessageCode(
  "OperatorWithOptionalFormals",
  problemMessage: r"""An operator can't have optional parameters.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeOperatorWithTypeParameters = messageOperatorWithTypeParameters;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageOperatorWithTypeParameters = const MessageCode(
  "OperatorWithTypeParameters",
  index: 120,
  problemMessage:
      r"""Types parameters aren't allowed when defining an operator.""",
  correctionMessage: r"""Try removing the type parameters.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeOptionalParametersInExtensionTypeDeclaration =
    messageOptionalParametersInExtensionTypeDeclaration;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageOptionalParametersInExtensionTypeDeclaration =
    const MessageCode(
  "OptionalParametersInExtensionTypeDeclaration",
  problemMessage:
      r"""Extension type declarations can't have optional parameters.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string, String string2)>
    templateOutOfOrderClauses =
    const Template<Message Function(String string, String string2)>(
  "OutOfOrderClauses",
  problemMessageTemplate:
      r"""The '#string' clause must come before the '#string2' clause.""",
  correctionMessageTemplate:
      r"""Try moving the '#string' clause before the '#string2' clause.""",
  withArguments: _withArgumentsOutOfOrderClauses,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeOutOfOrderClauses = const Code(
  "OutOfOrderClauses",
  index: 122,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOutOfOrderClauses(String string, String string2) {
  if (string.isEmpty) throw 'No string provided';
  if (string2.isEmpty) throw 'No string provided';
  return new Message(
    codeOutOfOrderClauses,
    problemMessage:
        """The '${string}' clause must come before the '${string2}' clause.""",
    correctionMessage:
        """Try moving the '${string}' clause before the '${string2}' clause.""",
    arguments: {
      'string': string,
      'string2': string2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateOverriddenMethodCause =
    const Template<Message Function(String name)>(
  "OverriddenMethodCause",
  problemMessageTemplate: r"""This is the overridden method ('#name').""",
  withArguments: _withArgumentsOverriddenMethodCause,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeOverriddenMethodCause = const Code(
  "OverriddenMethodCause",
  severity: Severity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverriddenMethodCause(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeOverriddenMethodCause,
    problemMessage: """This is the overridden method ('${name}').""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String name2)>
    templateOverrideFewerNamedArguments =
    const Template<Message Function(String name, String name2)>(
  "OverrideFewerNamedArguments",
  problemMessageTemplate:
      r"""The method '#name' has fewer named arguments than those of overridden method '#name2'.""",
  withArguments: _withArgumentsOverrideFewerNamedArguments,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeOverrideFewerNamedArguments = const Code(
  "OverrideFewerNamedArguments",
  analyzerCodes: <String>["INVALID_OVERRIDE_NAMED"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideFewerNamedArguments(String name, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(
    codeOverrideFewerNamedArguments,
    problemMessage:
        """The method '${name}' has fewer named arguments than those of overridden method '${name2}'.""",
    arguments: {
      'name': name,
      'name2': name2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String name2)>
    templateOverrideFewerPositionalArguments =
    const Template<Message Function(String name, String name2)>(
  "OverrideFewerPositionalArguments",
  problemMessageTemplate:
      r"""The method '#name' has fewer positional arguments than those of overridden method '#name2'.""",
  withArguments: _withArgumentsOverrideFewerPositionalArguments,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeOverrideFewerPositionalArguments = const Code(
  "OverrideFewerPositionalArguments",
  analyzerCodes: <String>["INVALID_OVERRIDE_POSITIONAL"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideFewerPositionalArguments(
    String name, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(
    codeOverrideFewerPositionalArguments,
    problemMessage:
        """The method '${name}' has fewer positional arguments than those of overridden method '${name2}'.""",
    arguments: {
      'name': name,
      'name2': name2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String name2, String name3)>
    templateOverrideMismatchNamedParameter =
    const Template<Message Function(String name, String name2, String name3)>(
  "OverrideMismatchNamedParameter",
  problemMessageTemplate:
      r"""The method '#name' doesn't have the named parameter '#name2' of overridden method '#name3'.""",
  withArguments: _withArgumentsOverrideMismatchNamedParameter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeOverrideMismatchNamedParameter = const Code(
  "OverrideMismatchNamedParameter",
  analyzerCodes: <String>["INVALID_OVERRIDE_NAMED"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideMismatchNamedParameter(
    String name, String name2, String name3) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  if (name3.isEmpty) throw 'No name provided';
  name3 = demangleMixinApplicationName(name3);
  return new Message(
    codeOverrideMismatchNamedParameter,
    problemMessage:
        """The method '${name}' doesn't have the named parameter '${name2}' of overridden method '${name3}'.""",
    arguments: {
      'name': name,
      'name2': name2,
      'name3': name3,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String name2, String name3)>
    templateOverrideMismatchRequiredNamedParameter =
    const Template<Message Function(String name, String name2, String name3)>(
  "OverrideMismatchRequiredNamedParameter",
  problemMessageTemplate:
      r"""The required named parameter '#name' in method '#name2' is not required in overridden method '#name3'.""",
  withArguments: _withArgumentsOverrideMismatchRequiredNamedParameter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeOverrideMismatchRequiredNamedParameter = const Code(
  "OverrideMismatchRequiredNamedParameter",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideMismatchRequiredNamedParameter(
    String name, String name2, String name3) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  if (name3.isEmpty) throw 'No name provided';
  name3 = demangleMixinApplicationName(name3);
  return new Message(
    codeOverrideMismatchRequiredNamedParameter,
    problemMessage:
        """The required named parameter '${name}' in method '${name2}' is not required in overridden method '${name3}'.""",
    arguments: {
      'name': name,
      'name2': name2,
      'name3': name3,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String name2)>
    templateOverrideMoreRequiredArguments =
    const Template<Message Function(String name, String name2)>(
  "OverrideMoreRequiredArguments",
  problemMessageTemplate:
      r"""The method '#name' has more required arguments than those of overridden method '#name2'.""",
  withArguments: _withArgumentsOverrideMoreRequiredArguments,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeOverrideMoreRequiredArguments = const Code(
  "OverrideMoreRequiredArguments",
  analyzerCodes: <String>["INVALID_OVERRIDE_REQUIRED"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideMoreRequiredArguments(String name, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(
    codeOverrideMoreRequiredArguments,
    problemMessage:
        """The method '${name}' has more required arguments than those of overridden method '${name2}'.""",
    arguments: {
      'name': name,
      'name2': name2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String name2)>
    templateOverrideTypeParametersMismatch =
    const Template<Message Function(String name, String name2)>(
  "OverrideTypeParametersMismatch",
  problemMessageTemplate:
      r"""Declared type variables of '#name' doesn't match those on overridden method '#name2'.""",
  withArguments: _withArgumentsOverrideTypeParametersMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeOverrideTypeParametersMismatch = const Code(
  "OverrideTypeParametersMismatch",
  analyzerCodes: <String>["INVALID_METHOD_OVERRIDE_TYPE_PARAMETERS"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideTypeParametersMismatch(
    String name, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(
    codeOverrideTypeParametersMismatch,
    problemMessage:
        """Declared type variables of '${name}' doesn't match those on overridden method '${name2}'.""",
    arguments: {
      'name': name,
      'name2': name2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, Uri uri_)>
    templatePackageNotFound =
    const Template<Message Function(String name, Uri uri_)>(
  "PackageNotFound",
  problemMessageTemplate:
      r"""Couldn't resolve the package '#name' in '#uri'.""",
  withArguments: _withArgumentsPackageNotFound,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codePackageNotFound = const Code(
  "PackageNotFound",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsPackageNotFound(String name, Uri uri_) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  String? uri = relativizeUri(uri_);
  return new Message(
    codePackageNotFound,
    problemMessage: """Couldn't resolve the package '${name}' in '${uri}'.""",
    arguments: {
      'name': name,
      'uri': uri_,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)> templatePackagesFileFormat =
    const Template<Message Function(String string)>(
  "PackagesFileFormat",
  problemMessageTemplate:
      r"""Problem in packages configuration file: #string""",
  withArguments: _withArgumentsPackagesFileFormat,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codePackagesFileFormat = const Code(
  "PackagesFileFormat",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsPackagesFileFormat(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(
    codePackagesFileFormat,
    problemMessage: """Problem in packages configuration file: ${string}""",
    arguments: {
      'string': string,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codePartExport = messagePartExport;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePartExport = const MessageCode(
  "PartExport",
  analyzerCodes: <String>["EXPORT_OF_NON_LIBRARY"],
  problemMessage:
      r"""Can't export this file because it contains a 'part of' declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codePartExportContext = messagePartExportContext;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePartExportContext = const MessageCode(
  "PartExportContext",
  severity: Severity.context,
  problemMessage: r"""This is the file that can't be exported.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codePartInPart = messagePartInPart;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePartInPart = const MessageCode(
  "PartInPart",
  analyzerCodes: <String>["NON_PART_OF_DIRECTIVE_IN_PART"],
  problemMessage:
      r"""A file that's a part of a library can't have parts itself.""",
  correctionMessage:
      r"""Try moving the 'part' declaration to the containing library.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codePartInPartLibraryContext = messagePartInPartLibraryContext;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePartInPartLibraryContext = const MessageCode(
  "PartInPartLibraryContext",
  severity: Severity.context,
  problemMessage: r"""This is the containing library.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri_)> templatePartOfInLibrary =
    const Template<Message Function(Uri uri_)>(
  "PartOfInLibrary",
  problemMessageTemplate:
      r"""Can't import '#uri', because it has a 'part of' declaration.""",
  correctionMessageTemplate:
      r"""Try removing the 'part of' declaration, or using '#uri' as a part.""",
  withArguments: _withArgumentsPartOfInLibrary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codePartOfInLibrary = const Code(
  "PartOfInLibrary",
  analyzerCodes: <String>["IMPORT_OF_NON_LIBRARY"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsPartOfInLibrary(Uri uri_) {
  String? uri = relativizeUri(uri_);
  return new Message(
    codePartOfInLibrary,
    problemMessage:
        """Can't import '${uri}', because it has a 'part of' declaration.""",
    correctionMessage:
        """Try removing the 'part of' declaration, or using '${uri}' as a part.""",
    arguments: {
      'uri': uri_,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri_, String name, String name2)>
    templatePartOfLibraryNameMismatch =
    const Template<Message Function(Uri uri_, String name, String name2)>(
  "PartOfLibraryNameMismatch",
  problemMessageTemplate:
      r"""Using '#uri' as part of '#name' but its 'part of' declaration says '#name2'.""",
  withArguments: _withArgumentsPartOfLibraryNameMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codePartOfLibraryNameMismatch = const Code(
  "PartOfLibraryNameMismatch",
  analyzerCodes: <String>["PART_OF_DIFFERENT_LIBRARY"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsPartOfLibraryNameMismatch(
    Uri uri_, String name, String name2) {
  String? uri = relativizeUri(uri_);
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(
    codePartOfLibraryNameMismatch,
    problemMessage:
        """Using '${uri}' as part of '${name}' but its 'part of' declaration says '${name2}'.""",
    arguments: {
      'uri': uri_,
      'name': name,
      'name2': name2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codePartOfSelf = messagePartOfSelf;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePartOfSelf = const MessageCode(
  "PartOfSelf",
  analyzerCodes: <String>["PART_OF_NON_PART"],
  problemMessage: r"""A file can't be a part of itself.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codePartOfTwice = messagePartOfTwice;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePartOfTwice = const MessageCode(
  "PartOfTwice",
  index: 25,
  problemMessage: r"""Only one part-of directive may be declared in a file.""",
  correctionMessage: r"""Try removing all but one of the part-of directives.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codePartOfTwoLibraries = messagePartOfTwoLibraries;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePartOfTwoLibraries = const MessageCode(
  "PartOfTwoLibraries",
  analyzerCodes: <String>["PART_OF_DIFFERENT_LIBRARY"],
  problemMessage: r"""A file can't be part of more than one library.""",
  correctionMessage:
      r"""Try moving the shared declarations into the libraries, or into a new library.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codePartOfTwoLibrariesContext = messagePartOfTwoLibrariesContext;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePartOfTwoLibrariesContext = const MessageCode(
  "PartOfTwoLibrariesContext",
  severity: Severity.context,
  problemMessage: r"""Used as a part in this library.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri_, Uri uri2_, Uri uri3_)>
    templatePartOfUriMismatch =
    const Template<Message Function(Uri uri_, Uri uri2_, Uri uri3_)>(
  "PartOfUriMismatch",
  problemMessageTemplate:
      r"""Using '#uri' as part of '#uri2' but its 'part of' declaration says '#uri3'.""",
  withArguments: _withArgumentsPartOfUriMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codePartOfUriMismatch = const Code(
  "PartOfUriMismatch",
  analyzerCodes: <String>["PART_OF_DIFFERENT_LIBRARY"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsPartOfUriMismatch(Uri uri_, Uri uri2_, Uri uri3_) {
  String? uri = relativizeUri(uri_);
  String? uri2 = relativizeUri(uri2_);
  String? uri3 = relativizeUri(uri3_);
  return new Message(
    codePartOfUriMismatch,
    problemMessage:
        """Using '${uri}' as part of '${uri2}' but its 'part of' declaration says '${uri3}'.""",
    arguments: {
      'uri': uri_,
      'uri2': uri2_,
      'uri3': uri3_,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri_, Uri uri2_, String name)>
    templatePartOfUseUri =
    const Template<Message Function(Uri uri_, Uri uri2_, String name)>(
  "PartOfUseUri",
  problemMessageTemplate:
      r"""Using '#uri' as part of '#uri2' but its 'part of' declaration says '#name'.""",
  correctionMessageTemplate:
      r"""Try changing the 'part of' declaration to use a relative file name.""",
  withArguments: _withArgumentsPartOfUseUri,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codePartOfUseUri = const Code(
  "PartOfUseUri",
  analyzerCodes: <String>["PART_OF_UNNAMED_LIBRARY"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsPartOfUseUri(Uri uri_, Uri uri2_, String name) {
  String? uri = relativizeUri(uri_);
  String? uri2 = relativizeUri(uri2_);
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codePartOfUseUri,
    problemMessage:
        """Using '${uri}' as part of '${uri2}' but its 'part of' declaration says '${name}'.""",
    correctionMessage:
        """Try changing the 'part of' declaration to use a relative file name.""",
    arguments: {
      'uri': uri_,
      'uri2': uri2_,
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codePartOrphan = messagePartOrphan;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePartOrphan = const MessageCode(
  "PartOrphan",
  problemMessage: r"""This part doesn't have a containing library.""",
  correctionMessage: r"""Try removing the 'part of' declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri_)> templatePartTwice =
    const Template<Message Function(Uri uri_)>(
  "PartTwice",
  problemMessageTemplate: r"""Can't use '#uri' as a part more than once.""",
  withArguments: _withArgumentsPartTwice,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codePartTwice = const Code(
  "PartTwice",
  analyzerCodes: <String>["DUPLICATE_PART"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsPartTwice(Uri uri_) {
  String? uri = relativizeUri(uri_);
  return new Message(
    codePartTwice,
    problemMessage: """Can't use '${uri}' as a part more than once.""",
    arguments: {
      'uri': uri_,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codePatchClassOrigin = messagePatchClassOrigin;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePatchClassOrigin = const MessageCode(
  "PatchClassOrigin",
  severity: Severity.context,
  problemMessage: r"""This is the origin class.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codePatchClassTypeParametersMismatch =
    messagePatchClassTypeParametersMismatch;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePatchClassTypeParametersMismatch = const MessageCode(
  "PatchClassTypeParametersMismatch",
  problemMessage:
      r"""A patch class must have the same number of type variables as its origin class.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codePatchDeclarationMismatch = messagePatchDeclarationMismatch;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePatchDeclarationMismatch = const MessageCode(
  "PatchDeclarationMismatch",
  problemMessage: r"""This patch doesn't match origin declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codePatchDeclarationOrigin = messagePatchDeclarationOrigin;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePatchDeclarationOrigin = const MessageCode(
  "PatchDeclarationOrigin",
  severity: Severity.context,
  problemMessage: r"""This is the origin declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codePatchExtensionOrigin = messagePatchExtensionOrigin;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePatchExtensionOrigin = const MessageCode(
  "PatchExtensionOrigin",
  severity: Severity.context,
  problemMessage: r"""This is the origin extension.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codePatchExtensionTypeParametersMismatch =
    messagePatchExtensionTypeParametersMismatch;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePatchExtensionTypeParametersMismatch =
    const MessageCode(
  "PatchExtensionTypeParametersMismatch",
  problemMessage:
      r"""A patch extension must have the same number of type variables as its origin extension.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, Uri uri_)>
    templatePatchInjectionFailed =
    const Template<Message Function(String name, Uri uri_)>(
  "PatchInjectionFailed",
  problemMessageTemplate: r"""Can't inject public '#name' into '#uri'.""",
  correctionMessageTemplate:
      r"""Make '#name' private, or make sure injected library has "dart" scheme and is private (e.g. "dart:_internal").""",
  withArguments: _withArgumentsPatchInjectionFailed,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codePatchInjectionFailed = const Code(
  "PatchInjectionFailed",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsPatchInjectionFailed(String name, Uri uri_) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  String? uri = relativizeUri(uri_);
  return new Message(
    codePatchInjectionFailed,
    problemMessage: """Can't inject public '${name}' into '${uri}'.""",
    correctionMessage:
        """Make '${name}' private, or make sure injected library has "dart" scheme and is private (e.g. "dart:_internal").""",
    arguments: {
      'name': name,
      'uri': uri_,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codePatchNonExternal = messagePatchNonExternal;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePatchNonExternal = const MessageCode(
  "PatchNonExternal",
  problemMessage:
      r"""Can't apply this patch as its origin declaration isn't external.""",
  correctionMessage: r"""Try adding 'external' to the origin declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templatePatternAssignmentDeclaresVariable =
    const Template<Message Function(String name)>(
  "PatternAssignmentDeclaresVariable",
  problemMessageTemplate:
      r"""Variable '#name' can't be declared in a pattern assignment.""",
  correctionMessageTemplate:
      r"""Try using a preexisting variable or changing the assignment to a pattern variable declaration.""",
  withArguments: _withArgumentsPatternAssignmentDeclaresVariable,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codePatternAssignmentDeclaresVariable = const Code(
  "PatternAssignmentDeclaresVariable",
  index: 145,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsPatternAssignmentDeclaresVariable(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codePatternAssignmentDeclaresVariable,
    problemMessage:
        """Variable '${name}' can't be declared in a pattern assignment.""",
    correctionMessage:
        """Try using a preexisting variable or changing the assignment to a pattern variable declaration.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codePatternAssignmentNotLocalVariable =
    messagePatternAssignmentNotLocalVariable;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePatternAssignmentNotLocalVariable = const MessageCode(
  "PatternAssignmentNotLocalVariable",
  analyzerCodes: <String>["PATTERN_ASSIGNMENT_NOT_LOCAL_VARIABLE"],
  problemMessage:
      r"""Only local variables or formal parameters can be used in pattern assignments.""",
  correctionMessage: r"""Try assigning to a local variable.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codePatternMatchingError = messagePatternMatchingError;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePatternMatchingError = const MessageCode(
  "PatternMatchingError",
  problemMessage: r"""Pattern matching error""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codePatternVariableAssignmentInsideGuard =
    messagePatternVariableAssignmentInsideGuard;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePatternVariableAssignmentInsideGuard =
    const MessageCode(
  "PatternVariableAssignmentInsideGuard",
  analyzerCodes: <String>["PATTERN_VARIABLE_ASSIGNMENT_INSIDE_GUARD"],
  problemMessage:
      r"""Pattern variables can't be assigned inside the guard of the enclosing guarded pattern.""",
  correctionMessage: r"""Try assigning to a different variable.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codePatternVariableDeclarationOutsideFunctionOrMethod =
    messagePatternVariableDeclarationOutsideFunctionOrMethod;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePatternVariableDeclarationOutsideFunctionOrMethod =
    const MessageCode(
  "PatternVariableDeclarationOutsideFunctionOrMethod",
  index: 152,
  problemMessage:
      r"""A pattern variable declaration may not appear outside a function or method.""",
  correctionMessage:
      r"""Try declaring ordinary variables and assigning from within a function or method.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codePlatformPrivateLibraryAccess =
    messagePlatformPrivateLibraryAccess;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePlatformPrivateLibraryAccess = const MessageCode(
  "PlatformPrivateLibraryAccess",
  analyzerCodes: <String>["IMPORT_INTERNAL_LIBRARY"],
  problemMessage: r"""Can't access platform private library.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codePositionalAfterNamedArgument =
    messagePositionalAfterNamedArgument;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePositionalAfterNamedArgument = const MessageCode(
  "PositionalAfterNamedArgument",
  analyzerCodes: <String>["POSITIONAL_AFTER_NAMED_ARGUMENT"],
  problemMessage: r"""Place positional arguments before named arguments.""",
  correctionMessage:
      r"""Try moving the positional argument before the named arguments, or add a name to the argument.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codePositionalParameterWithEquals =
    messagePositionalParameterWithEquals;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePositionalParameterWithEquals = const MessageCode(
  "PositionalParameterWithEquals",
  analyzerCodes: <String>["WRONG_SEPARATOR_FOR_POSITIONAL_PARAMETER"],
  problemMessage:
      r"""Positional optional parameters can't use ':' to specify a default value.""",
  correctionMessage: r"""Try replacing ':' with '='.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codePositionalSuperParametersAndArguments =
    messagePositionalSuperParametersAndArguments;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePositionalSuperParametersAndArguments =
    const MessageCode(
  "PositionalSuperParametersAndArguments",
  problemMessage:
      r"""Positional super-initializer parameters cannot be used when the super initializer has positional arguments.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codePrefixAfterCombinator = messagePrefixAfterCombinator;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePrefixAfterCombinator = const MessageCode(
  "PrefixAfterCombinator",
  index: 6,
  problemMessage:
      r"""The prefix ('as' clause) should come before any show/hide combinators.""",
  correctionMessage: r"""Try moving the prefix before the combinators.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codePrivateNamedParameter = messagePrivateNamedParameter;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePrivateNamedParameter = const MessageCode(
  "PrivateNamedParameter",
  analyzerCodes: <String>["PRIVATE_OPTIONAL_PARAMETER"],
  problemMessage:
      r"""A named parameter can't start with an underscore ('_').""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeRecordFieldsCantBePrivate = messageRecordFieldsCantBePrivate;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageRecordFieldsCantBePrivate = const MessageCode(
  "RecordFieldsCantBePrivate",
  analyzerCodes: <String>["INVALID_FIELD_NAME"],
  problemMessage: r"""Record field names can't be private.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeRecordLiteralOnePositionalFieldNoTrailingComma =
    messageRecordLiteralOnePositionalFieldNoTrailingComma;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageRecordLiteralOnePositionalFieldNoTrailingComma =
    const MessageCode(
  "RecordLiteralOnePositionalFieldNoTrailingComma",
  index: 127,
  problemMessage:
      r"""A record literal with exactly one positional field requires a trailing comma.""",
  correctionMessage: r"""Try adding a trailing comma.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeRecordLiteralZeroFieldsWithTrailingComma =
    messageRecordLiteralZeroFieldsWithTrailingComma;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageRecordLiteralZeroFieldsWithTrailingComma =
    const MessageCode(
  "RecordLiteralZeroFieldsWithTrailingComma",
  index: 128,
  problemMessage:
      r"""A record literal without fields can't have a trailing comma.""",
  correctionMessage: r"""Try removing the trailing comma.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeRecordTypeOnePositionalFieldNoTrailingComma =
    messageRecordTypeOnePositionalFieldNoTrailingComma;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageRecordTypeOnePositionalFieldNoTrailingComma =
    const MessageCode(
  "RecordTypeOnePositionalFieldNoTrailingComma",
  index: 131,
  problemMessage:
      r"""A record type with exactly one positional field requires a trailing comma.""",
  correctionMessage: r"""Try adding a trailing comma.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeRecordTypeZeroFieldsButTrailingComma =
    messageRecordTypeZeroFieldsButTrailingComma;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageRecordTypeZeroFieldsButTrailingComma =
    const MessageCode(
  "RecordTypeZeroFieldsButTrailingComma",
  index: 130,
  problemMessage:
      r"""A record type without fields can't have a trailing comma.""",
  correctionMessage: r"""Try removing the trailing comma.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeRecordUseCannotBePlacedHere = messageRecordUseCannotBePlacedHere;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageRecordUseCannotBePlacedHere = const MessageCode(
  "RecordUseCannotBePlacedHere",
  problemMessage:
      r"""`RecordUse` annotation cannot be placed on this element.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeRecordUsedAsCallable = messageRecordUsedAsCallable;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageRecordUsedAsCallable = const MessageCode(
  "RecordUsedAsCallable",
  problemMessage:
      r"""The 'call' property on the record type isn't directly callable but could be invoked by `.call(...)`""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeRedirectingConstructorWithAnotherInitializer =
    messageRedirectingConstructorWithAnotherInitializer;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageRedirectingConstructorWithAnotherInitializer =
    const MessageCode(
  "RedirectingConstructorWithAnotherInitializer",
  analyzerCodes: <String>["FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR"],
  problemMessage:
      r"""A redirecting constructor can't have other initializers.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeRedirectingConstructorWithBody =
    messageRedirectingConstructorWithBody;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageRedirectingConstructorWithBody = const MessageCode(
  "RedirectingConstructorWithBody",
  index: 22,
  problemMessage: r"""Redirecting constructors can't have a body.""",
  correctionMessage:
      r"""Try removing the body, or not making this a redirecting constructor.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeRedirectingConstructorWithMultipleRedirectInitializers =
    messageRedirectingConstructorWithMultipleRedirectInitializers;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
    messageRedirectingConstructorWithMultipleRedirectInitializers =
    const MessageCode(
  "RedirectingConstructorWithMultipleRedirectInitializers",
  analyzerCodes: <String>["MULTIPLE_REDIRECTING_CONSTRUCTOR_INVOCATIONS"],
  problemMessage:
      r"""A redirecting constructor can't have more than one redirection.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeRedirectingConstructorWithSuperInitializer =
    messageRedirectingConstructorWithSuperInitializer;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageRedirectingConstructorWithSuperInitializer =
    const MessageCode(
  "RedirectingConstructorWithSuperInitializer",
  analyzerCodes: <String>["SUPER_IN_REDIRECTING_CONSTRUCTOR"],
  problemMessage:
      r"""A redirecting constructor can't have a 'super' initializer.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeRedirectionInNonFactory = messageRedirectionInNonFactory;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageRedirectionInNonFactory = const MessageCode(
  "RedirectionInNonFactory",
  index: 21,
  problemMessage: r"""Only factory constructor can specify '=' redirection.""",
  correctionMessage:
      r"""Try making this a factory constructor, or remove the redirection.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateRedirectionTargetNotFound =
    const Template<Message Function(String name)>(
  "RedirectionTargetNotFound",
  problemMessageTemplate:
      r"""Redirection constructor target not found: '#name'""",
  withArguments: _withArgumentsRedirectionTargetNotFound,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeRedirectionTargetNotFound = const Code(
  "RedirectionTargetNotFound",
  analyzerCodes: <String>["REDIRECT_TO_MISSING_CONSTRUCTOR"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsRedirectionTargetNotFound(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeRedirectionTargetNotFound,
    problemMessage: """Redirection constructor target not found: '${name}'""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeRefutablePatternInIrrefutableContext =
    messageRefutablePatternInIrrefutableContext;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageRefutablePatternInIrrefutableContext =
    const MessageCode(
  "RefutablePatternInIrrefutableContext",
  analyzerCodes: <String>["REFUTABLE_PATTERN_IN_IRREFUTABLE_CONTEXT"],
  problemMessage:
      r"""Refutable patterns can't be used in an irrefutable context.""",
  correctionMessage:
      r"""Try using an if-case, a 'switch' statement, or a 'switch' expression instead.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeRepresentationFieldModifier = messageRepresentationFieldModifier;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageRepresentationFieldModifier = const MessageCode(
  "RepresentationFieldModifier",
  analyzerCodes: <String>["REPRESENTATION_FIELD_MODIFIER"],
  problemMessage: r"""Representation fields can't have modifiers.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeRepresentationFieldTrailingComma =
    messageRepresentationFieldTrailingComma;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageRepresentationFieldTrailingComma = const MessageCode(
  "RepresentationFieldTrailingComma",
  analyzerCodes: <String>["REPRESENTATION_FIELD_TRAILING_COMMA"],
  problemMessage: r"""The representation field can't have a trailing comma.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateRequiredNamedParameterHasDefaultValueError =
    const Template<Message Function(String name)>(
  "RequiredNamedParameterHasDefaultValueError",
  problemMessageTemplate:
      r"""Named parameter '#name' is required and can't have a default value.""",
  withArguments: _withArgumentsRequiredNamedParameterHasDefaultValueError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeRequiredNamedParameterHasDefaultValueError = const Code(
  "RequiredNamedParameterHasDefaultValueError",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsRequiredNamedParameterHasDefaultValueError(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeRequiredNamedParameterHasDefaultValueError,
    problemMessage:
        """Named parameter '${name}' is required and can't have a default value.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeRequiredParameterWithDefault =
    messageRequiredParameterWithDefault;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageRequiredParameterWithDefault = const MessageCode(
  "RequiredParameterWithDefault",
  analyzerCodes: <String>["NAMED_PARAMETER_OUTSIDE_GROUP"],
  problemMessage: r"""Non-optional parameters can't have a default value.""",
  correctionMessage:
      r"""Try removing the default value or making the parameter optional.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeRestPatternInMapPattern = messageRestPatternInMapPattern;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageRestPatternInMapPattern = const MessageCode(
  "RestPatternInMapPattern",
  problemMessage: r"""The '...' pattern can't appear in map patterns.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeRethrowNotCatch = messageRethrowNotCatch;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageRethrowNotCatch = const MessageCode(
  "RethrowNotCatch",
  analyzerCodes: <String>["RETHROW_OUTSIDE_CATCH"],
  problemMessage: r"""'rethrow' can only be used in catch clauses.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeReturnFromVoidFunction = messageReturnFromVoidFunction;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageReturnFromVoidFunction = const MessageCode(
  "ReturnFromVoidFunction",
  analyzerCodes: <String>["RETURN_OF_INVALID_TYPE"],
  problemMessage: r"""Can't return a value from a void function.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeReturnTypeFunctionExpression =
    messageReturnTypeFunctionExpression;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageReturnTypeFunctionExpression = const MessageCode(
  "ReturnTypeFunctionExpression",
  problemMessage: r"""A function expression can't have a return type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeReturnWithoutExpressionAsync =
    messageReturnWithoutExpressionAsync;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageReturnWithoutExpressionAsync = const MessageCode(
  "ReturnWithoutExpressionAsync",
  problemMessage:
      r"""A value must be explicitly returned from a non-void async function.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeReturnWithoutExpressionSync = messageReturnWithoutExpressionSync;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageReturnWithoutExpressionSync = const MessageCode(
  "ReturnWithoutExpressionSync",
  problemMessage:
      r"""A value must be explicitly returned from a non-void function.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeScriptTagInPartFile = messageScriptTagInPartFile;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageScriptTagInPartFile = const MessageCode(
  "ScriptTagInPartFile",
  problemMessage: r"""A part file cannot have script tag.""",
  correctionMessage:
      r"""Try removing the script tag or the 'part of' directive.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri_)> templateSdkRootNotFound =
    const Template<Message Function(Uri uri_)>(
  "SdkRootNotFound",
  problemMessageTemplate: r"""SDK root directory not found: #uri.""",
  withArguments: _withArgumentsSdkRootNotFound,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeSdkRootNotFound = const Code(
  "SdkRootNotFound",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSdkRootNotFound(Uri uri_) {
  String? uri = relativizeUri(uri_);
  return new Message(
    codeSdkRootNotFound,
    problemMessage: """SDK root directory not found: ${uri}.""",
    arguments: {
      'uri': uri_,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri_)> templateSdkSpecificationNotFound =
    const Template<Message Function(Uri uri_)>(
  "SdkSpecificationNotFound",
  problemMessageTemplate: r"""SDK libraries specification not found: #uri.""",
  correctionMessageTemplate:
      r"""Normally, the specification is a file named 'libraries.json' in the Dart SDK install location.""",
  withArguments: _withArgumentsSdkSpecificationNotFound,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeSdkSpecificationNotFound = const Code(
  "SdkSpecificationNotFound",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSdkSpecificationNotFound(Uri uri_) {
  String? uri = relativizeUri(uri_);
  return new Message(
    codeSdkSpecificationNotFound,
    problemMessage: """SDK libraries specification not found: ${uri}.""",
    correctionMessage:
        """Normally, the specification is a file named 'libraries.json' in the Dart SDK install location.""",
    arguments: {
      'uri': uri_,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri_)> templateSdkSummaryNotFound =
    const Template<Message Function(Uri uri_)>(
  "SdkSummaryNotFound",
  problemMessageTemplate: r"""SDK summary not found: #uri.""",
  withArguments: _withArgumentsSdkSummaryNotFound,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeSdkSummaryNotFound = const Code(
  "SdkSummaryNotFound",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSdkSummaryNotFound(Uri uri_) {
  String? uri = relativizeUri(uri_);
  return new Message(
    codeSdkSummaryNotFound,
    problemMessage: """SDK summary not found: ${uri}.""",
    arguments: {
      'uri': uri_,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateSealedClassSubtypeOutsideOfLibrary =
    const Template<Message Function(String name)>(
  "SealedClassSubtypeOutsideOfLibrary",
  problemMessageTemplate:
      r"""The class '#name' can't be extended, implemented, or mixed in outside of its library because it's a sealed class.""",
  withArguments: _withArgumentsSealedClassSubtypeOutsideOfLibrary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeSealedClassSubtypeOutsideOfLibrary = const Code(
  "SealedClassSubtypeOutsideOfLibrary",
  analyzerCodes: <String>["SEALED_CLASS_SUBTYPE_OUTSIDE_OF_LIBRARY"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSealedClassSubtypeOutsideOfLibrary(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeSealedClassSubtypeOutsideOfLibrary,
    problemMessage:
        """The class '${name}' can't be extended, implemented, or mixed in outside of its library because it's a sealed class.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeSealedEnum = messageSealedEnum;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSealedEnum = const MessageCode(
  "SealedEnum",
  index: 158,
  problemMessage: r"""Enums can't be declared to be 'sealed'.""",
  correctionMessage: r"""Try removing the keyword 'sealed'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeSealedMixin = messageSealedMixin;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSealedMixin = const MessageCode(
  "SealedMixin",
  index: 148,
  problemMessage: r"""A mixin can't be declared 'sealed'.""",
  correctionMessage: r"""Try removing the 'sealed' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeSealedMixinClass = messageSealedMixinClass;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSealedMixinClass = const MessageCode(
  "SealedMixinClass",
  index: 144,
  problemMessage: r"""A mixin class can't be declared 'sealed'.""",
  correctionMessage: r"""Try removing the 'sealed' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeSetLiteralTooManyTypeArguments =
    messageSetLiteralTooManyTypeArguments;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSetLiteralTooManyTypeArguments = const MessageCode(
  "SetLiteralTooManyTypeArguments",
  problemMessage: r"""A set literal requires exactly one type argument.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeSetOrMapLiteralTooManyTypeArguments =
    messageSetOrMapLiteralTooManyTypeArguments;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSetOrMapLiteralTooManyTypeArguments =
    const MessageCode(
  "SetOrMapLiteralTooManyTypeArguments",
  problemMessage:
      r"""A set or map literal requires exactly one or two type arguments, respectively.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateSetterConflictsWithDeclaration =
    const Template<Message Function(String name)>(
  "SetterConflictsWithDeclaration",
  problemMessageTemplate: r"""The setter conflicts with declaration '#name'.""",
  withArguments: _withArgumentsSetterConflictsWithDeclaration,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeSetterConflictsWithDeclaration = const Code(
  "SetterConflictsWithDeclaration",
  analyzerCodes: <String>["CONFLICTS_WITH_MEMBER"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSetterConflictsWithDeclaration(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeSetterConflictsWithDeclaration,
    problemMessage: """The setter conflicts with declaration '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateSetterConflictsWithDeclarationCause =
    const Template<Message Function(String name)>(
  "SetterConflictsWithDeclarationCause",
  problemMessageTemplate: r"""Conflicting declaration '#name'.""",
  withArguments: _withArgumentsSetterConflictsWithDeclarationCause,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeSetterConflictsWithDeclarationCause = const Code(
  "SetterConflictsWithDeclarationCause",
  severity: Severity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSetterConflictsWithDeclarationCause(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeSetterConflictsWithDeclarationCause,
    problemMessage: """Conflicting declaration '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeSetterConstructor = messageSetterConstructor;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSetterConstructor = const MessageCode(
  "SetterConstructor",
  index: 104,
  problemMessage: r"""Constructors can't be a setter.""",
  correctionMessage: r"""Try removing 'set'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateSetterNotFound =
    const Template<Message Function(String name)>(
  "SetterNotFound",
  problemMessageTemplate: r"""Setter not found: '#name'.""",
  withArguments: _withArgumentsSetterNotFound,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeSetterNotFound = const Code(
  "SetterNotFound",
  analyzerCodes: <String>["UNDEFINED_SETTER"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSetterNotFound(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeSetterNotFound,
    problemMessage: """Setter not found: '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeSetterNotSync = messageSetterNotSync;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSetterNotSync = const MessageCode(
  "SetterNotSync",
  analyzerCodes: <String>["INVALID_MODIFIER_ON_SETTER"],
  problemMessage: r"""Setters can't use 'async', 'async*', or 'sync*'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeSetterWithWrongNumberOfFormals =
    messageSetterWithWrongNumberOfFormals;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSetterWithWrongNumberOfFormals = const MessageCode(
  "SetterWithWrongNumberOfFormals",
  analyzerCodes: <String>["WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER"],
  problemMessage: r"""A setter should have exactly one formal parameter.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(int count, int count2, num _num1, num _num2,
        num _num3)> templateSourceBodySummary = const Template<
    Message Function(int count, int count2, num _num1, num _num2, num _num3)>(
  "SourceBodySummary",
  problemMessageTemplate:
      r"""Built bodies for #count compilation units (#count2 bytes) in #num1%.3ms, that is,
#num2%12.3 bytes/ms, and
#num3%12.3 ms/compilation unit.""",
  withArguments: _withArgumentsSourceBodySummary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeSourceBodySummary = const Code(
  "SourceBodySummary",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSourceBodySummary(
    int count, int count2, num _num1, num _num2, num _num3) {
  String num1 = _num1.toStringAsFixed(3);
  String num2 = _num2.toStringAsFixed(3).padLeft(12);
  String num3 = _num3.toStringAsFixed(3).padLeft(12);
  return new Message(
    codeSourceBodySummary,
    problemMessage:
        """Built bodies for ${count} compilation units (${count2} bytes) in ${num1}ms, that is,
${num2} bytes/ms, and
${num3} ms/compilation unit.""",
    arguments: {
      'count': count,
      'count2': count2,
      'num1': _num1,
      'num2': _num2,
      'num3': _num3,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(int count, int count2, num _num1, num _num2,
        num _num3)> templateSourceOutlineSummary = const Template<
    Message Function(int count, int count2, num _num1, num _num2, num _num3)>(
  "SourceOutlineSummary",
  problemMessageTemplate:
      r"""Built outlines for #count compilation units (#count2 bytes) in #num1%.3ms, that is,
#num2%12.3 bytes/ms, and
#num3%12.3 ms/compilation unit.""",
  withArguments: _withArgumentsSourceOutlineSummary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeSourceOutlineSummary = const Code(
  "SourceOutlineSummary",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSourceOutlineSummary(
    int count, int count2, num _num1, num _num2, num _num3) {
  String num1 = _num1.toStringAsFixed(3);
  String num2 = _num2.toStringAsFixed(3).padLeft(12);
  String num3 = _num3.toStringAsFixed(3).padLeft(12);
  return new Message(
    codeSourceOutlineSummary,
    problemMessage:
        """Built outlines for ${count} compilation units (${count2} bytes) in ${num1}ms, that is,
${num2} bytes/ms, and
${num3} ms/compilation unit.""",
    arguments: {
      'count': count,
      'count2': count2,
      'num1': _num1,
      'num2': _num2,
      'num3': _num3,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeSpreadElement = messageSpreadElement;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSpreadElement = const MessageCode(
  "SpreadElement",
  severity: Severity.context,
  problemMessage: r"""Iterable spread.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeSpreadMapElement = messageSpreadMapElement;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSpreadMapElement = const MessageCode(
  "SpreadMapElement",
  severity: Severity.context,
  problemMessage: r"""Map spread.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeStackOverflow = messageStackOverflow;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageStackOverflow = const MessageCode(
  "StackOverflow",
  index: 19,
  problemMessage:
      r"""The file has too many nested expressions or statements.""",
  correctionMessage: r"""Try simplifying the code.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateStaticConflictsWithInstance =
    const Template<Message Function(String name)>(
  "StaticConflictsWithInstance",
  problemMessageTemplate:
      r"""Static property '#name' conflicts with instance property of the same name.""",
  withArguments: _withArgumentsStaticConflictsWithInstance,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeStaticConflictsWithInstance = const Code(
  "StaticConflictsWithInstance",
  analyzerCodes: <String>["CONFLICTS_WITH_MEMBER"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsStaticConflictsWithInstance(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeStaticConflictsWithInstance,
    problemMessage:
        """Static property '${name}' conflicts with instance property of the same name.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateStaticConflictsWithInstanceCause =
    const Template<Message Function(String name)>(
  "StaticConflictsWithInstanceCause",
  problemMessageTemplate: r"""Conflicting instance property '#name'.""",
  withArguments: _withArgumentsStaticConflictsWithInstanceCause,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeStaticConflictsWithInstanceCause = const Code(
  "StaticConflictsWithInstanceCause",
  severity: Severity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsStaticConflictsWithInstanceCause(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeStaticConflictsWithInstanceCause,
    problemMessage: """Conflicting instance property '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeStaticConstructor = messageStaticConstructor;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageStaticConstructor = const MessageCode(
  "StaticConstructor",
  index: 4,
  problemMessage: r"""Constructors can't be static.""",
  correctionMessage: r"""Try removing the keyword 'static'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeStaticOperator = messageStaticOperator;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageStaticOperator = const MessageCode(
  "StaticOperator",
  index: 17,
  problemMessage: r"""Operators can't be static.""",
  correctionMessage: r"""Try removing the keyword 'static'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeStaticTearOffFromInstantiatedClass =
    messageStaticTearOffFromInstantiatedClass;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageStaticTearOffFromInstantiatedClass = const MessageCode(
  "StaticTearOffFromInstantiatedClass",
  problemMessage:
      r"""Cannot access static member on an instantiated generic class.""",
  correctionMessage:
      r"""Try removing the type arguments or placing them after the member name.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeStrongWithWeakDillLibrary = messageStrongWithWeakDillLibrary;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageStrongWithWeakDillLibrary = const MessageCode(
  "StrongWithWeakDillLibrary",
  problemMessage:
      r"""Loaded library is compiled with unsound null safety and cannot be used in compilation for sound null safety.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String name2)>
    templateSubtypeOfBaseIsNotBaseFinalOrSealed =
    const Template<Message Function(String name, String name2)>(
  "SubtypeOfBaseIsNotBaseFinalOrSealed",
  problemMessageTemplate:
      r"""The type '#name' must be 'base', 'final' or 'sealed' because the supertype '#name2' is 'base'.""",
  correctionMessageTemplate:
      r"""Try adding 'base', 'final', or 'sealed' to the type.""",
  withArguments: _withArgumentsSubtypeOfBaseIsNotBaseFinalOrSealed,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeSubtypeOfBaseIsNotBaseFinalOrSealed = const Code(
  "SubtypeOfBaseIsNotBaseFinalOrSealed",
  analyzerCodes: <String>["SUBTYPE_OF_BASE_IS_NOT_BASE_FINAL_OR_SEALED"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSubtypeOfBaseIsNotBaseFinalOrSealed(
    String name, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(
    codeSubtypeOfBaseIsNotBaseFinalOrSealed,
    problemMessage:
        """The type '${name}' must be 'base', 'final' or 'sealed' because the supertype '${name2}' is 'base'.""",
    correctionMessage:
        """Try adding 'base', 'final', or 'sealed' to the type.""",
    arguments: {
      'name': name,
      'name2': name2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String name2)>
    templateSubtypeOfFinalIsNotBaseFinalOrSealed =
    const Template<Message Function(String name, String name2)>(
  "SubtypeOfFinalIsNotBaseFinalOrSealed",
  problemMessageTemplate:
      r"""The type '#name' must be 'base', 'final' or 'sealed' because the supertype '#name2' is 'final'.""",
  correctionMessageTemplate:
      r"""Try adding 'base', 'final', or 'sealed' to the type.""",
  withArguments: _withArgumentsSubtypeOfFinalIsNotBaseFinalOrSealed,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeSubtypeOfFinalIsNotBaseFinalOrSealed = const Code(
  "SubtypeOfFinalIsNotBaseFinalOrSealed",
  analyzerCodes: <String>["SUBTYPE_OF_FINAL_IS_NOT_BASE_FINAL_OR_SEALED"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSubtypeOfFinalIsNotBaseFinalOrSealed(
    String name, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(
    codeSubtypeOfFinalIsNotBaseFinalOrSealed,
    problemMessage:
        """The type '${name}' must be 'base', 'final' or 'sealed' because the supertype '${name2}' is 'final'.""",
    correctionMessage:
        """Try adding 'base', 'final', or 'sealed' to the type.""",
    arguments: {
      'name': name,
      'name2': name2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeSuperAsExpression = messageSuperAsExpression;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSuperAsExpression = const MessageCode(
  "SuperAsExpression",
  analyzerCodes: <String>["SUPER_AS_EXPRESSION"],
  problemMessage: r"""Can't use 'super' as an expression.""",
  correctionMessage:
      r"""To delegate a constructor to a super constructor, put the super call as an initializer.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeSuperAsIdentifier = messageSuperAsIdentifier;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSuperAsIdentifier = const MessageCode(
  "SuperAsIdentifier",
  analyzerCodes: <String>["SUPER_AS_EXPRESSION"],
  problemMessage: r"""Expected identifier, but got 'super'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateSuperExtensionTypeIsIllegal =
    const Template<Message Function(String name)>(
  "SuperExtensionTypeIsIllegal",
  problemMessageTemplate:
      r"""The type '#name' can't be implemented by an extension type.""",
  withArguments: _withArgumentsSuperExtensionTypeIsIllegal,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeSuperExtensionTypeIsIllegal = const Code(
  "SuperExtensionTypeIsIllegal",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperExtensionTypeIsIllegal(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeSuperExtensionTypeIsIllegal,
    problemMessage:
        """The type '${name}' can't be implemented by an extension type.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateSuperExtensionTypeIsTypeParameter =
    const Template<Message Function(String name)>(
  "SuperExtensionTypeIsTypeParameter",
  problemMessageTemplate:
      r"""The type variable '#name' can't be implemented by an extension type.""",
  withArguments: _withArgumentsSuperExtensionTypeIsTypeParameter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeSuperExtensionTypeIsTypeParameter = const Code(
  "SuperExtensionTypeIsTypeParameter",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperExtensionTypeIsTypeParameter(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeSuperExtensionTypeIsTypeParameter,
    problemMessage:
        """The type variable '${name}' can't be implemented by an extension type.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeSuperInitializerNotLast = messageSuperInitializerNotLast;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSuperInitializerNotLast = const MessageCode(
  "SuperInitializerNotLast",
  analyzerCodes: <String>["SUPER_INVOCATION_NOT_LAST"],
  problemMessage: r"""Can't have initializers after 'super'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeSuperInitializerParameter = messageSuperInitializerParameter;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSuperInitializerParameter = const MessageCode(
  "SuperInitializerParameter",
  severity: Severity.context,
  problemMessage: r"""This is the super-initializer parameter.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeSuperNullAware = messageSuperNullAware;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSuperNullAware = const MessageCode(
  "SuperNullAware",
  index: 18,
  problemMessage:
      r"""The operator '?.' cannot be used with 'super' because 'super' cannot be null.""",
  correctionMessage: r"""Try replacing '?.' with '.'""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeSuperParameterInitializerOutsideConstructor =
    messageSuperParameterInitializerOutsideConstructor;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSuperParameterInitializerOutsideConstructor =
    const MessageCode(
  "SuperParameterInitializerOutsideConstructor",
  problemMessage:
      r"""Super-initializer formal parameters can only be used in generative constructors.""",
  correctionMessage: r"""Try removing 'super.'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateSuperclassHasNoConstructor =
    const Template<Message Function(String name)>(
  "SuperclassHasNoConstructor",
  problemMessageTemplate: r"""Superclass has no constructor named '#name'.""",
  withArguments: _withArgumentsSuperclassHasNoConstructor,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeSuperclassHasNoConstructor = const Code(
  "SuperclassHasNoConstructor",
  analyzerCodes: <String>[
    "UNDEFINED_CONSTRUCTOR_IN_INITIALIZER",
    "UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT"
  ],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperclassHasNoConstructor(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeSuperclassHasNoConstructor,
    problemMessage: """Superclass has no constructor named '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateSuperclassHasNoDefaultConstructor =
    const Template<Message Function(String name)>(
  "SuperclassHasNoDefaultConstructor",
  problemMessageTemplate:
      r"""The superclass, '#name', has no unnamed constructor that takes no arguments.""",
  withArguments: _withArgumentsSuperclassHasNoDefaultConstructor,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeSuperclassHasNoDefaultConstructor = const Code(
  "SuperclassHasNoDefaultConstructor",
  analyzerCodes: <String>["NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperclassHasNoDefaultConstructor(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeSuperclassHasNoDefaultConstructor,
    problemMessage:
        """The superclass, '${name}', has no unnamed constructor that takes no arguments.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateSuperclassHasNoGetter =
    const Template<Message Function(String name)>(
  "SuperclassHasNoGetter",
  problemMessageTemplate: r"""Superclass has no getter named '#name'.""",
  withArguments: _withArgumentsSuperclassHasNoGetter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeSuperclassHasNoGetter = const Code(
  "SuperclassHasNoGetter",
  analyzerCodes: <String>["UNDEFINED_SUPER_GETTER"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperclassHasNoGetter(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeSuperclassHasNoGetter,
    problemMessage: """Superclass has no getter named '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateSuperclassHasNoMember =
    const Template<Message Function(String name)>(
  "SuperclassHasNoMember",
  problemMessageTemplate: r"""Superclass has no member named '#name'.""",
  withArguments: _withArgumentsSuperclassHasNoMember,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeSuperclassHasNoMember = const Code(
  "SuperclassHasNoMember",
  analyzerCodes: <String>["UNDEFINED_SUPER_GETTER"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperclassHasNoMember(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeSuperclassHasNoMember,
    problemMessage: """Superclass has no member named '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateSuperclassHasNoMethod =
    const Template<Message Function(String name)>(
  "SuperclassHasNoMethod",
  problemMessageTemplate: r"""Superclass has no method named '#name'.""",
  withArguments: _withArgumentsSuperclassHasNoMethod,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeSuperclassHasNoMethod = const Code(
  "SuperclassHasNoMethod",
  analyzerCodes: <String>["UNDEFINED_SUPER_METHOD"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperclassHasNoMethod(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeSuperclassHasNoMethod,
    problemMessage: """Superclass has no method named '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateSuperclassHasNoSetter =
    const Template<Message Function(String name)>(
  "SuperclassHasNoSetter",
  problemMessageTemplate: r"""Superclass has no setter named '#name'.""",
  withArguments: _withArgumentsSuperclassHasNoSetter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeSuperclassHasNoSetter = const Code(
  "SuperclassHasNoSetter",
  analyzerCodes: <String>["UNDEFINED_SUPER_SETTER"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperclassHasNoSetter(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeSuperclassHasNoSetter,
    problemMessage: """Superclass has no setter named '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateSuperclassMethodArgumentMismatch =
    const Template<Message Function(String name)>(
  "SuperclassMethodArgumentMismatch",
  problemMessageTemplate:
      r"""Superclass doesn't have a method named '#name' with matching arguments.""",
  withArguments: _withArgumentsSuperclassMethodArgumentMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeSuperclassMethodArgumentMismatch = const Code(
  "SuperclassMethodArgumentMismatch",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperclassMethodArgumentMismatch(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeSuperclassMethodArgumentMismatch,
    problemMessage:
        """Superclass doesn't have a method named '${name}' with matching arguments.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeSupertypeIsFunction = messageSupertypeIsFunction;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSupertypeIsFunction = const MessageCode(
  "SupertypeIsFunction",
  problemMessage: r"""Can't use a function type as supertype.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateSupertypeIsIllegal =
    const Template<Message Function(String name)>(
  "SupertypeIsIllegal",
  problemMessageTemplate: r"""The type '#name' can't be used as supertype.""",
  withArguments: _withArgumentsSupertypeIsIllegal,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeSupertypeIsIllegal = const Code(
  "SupertypeIsIllegal",
  analyzerCodes: <String>["EXTENDS_NON_CLASS"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSupertypeIsIllegal(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeSupertypeIsIllegal,
    problemMessage: """The type '${name}' can't be used as supertype.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateSupertypeIsTypeParameter =
    const Template<Message Function(String name)>(
  "SupertypeIsTypeParameter",
  problemMessageTemplate:
      r"""The type variable '#name' can't be used as supertype.""",
  withArguments: _withArgumentsSupertypeIsTypeParameter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeSupertypeIsTypeParameter = const Code(
  "SupertypeIsTypeParameter",
  analyzerCodes: <String>["EXTENDS_NON_CLASS"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSupertypeIsTypeParameter(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeSupertypeIsTypeParameter,
    problemMessage:
        """The type variable '${name}' can't be used as supertype.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeSwitchCaseFallThrough = messageSwitchCaseFallThrough;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSwitchCaseFallThrough = const MessageCode(
  "SwitchCaseFallThrough",
  analyzerCodes: <String>["CASE_BLOCK_NOT_TERMINATED"],
  problemMessage: r"""Switch case may fall through to the next case.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeSwitchExpressionNotAssignableCause =
    messageSwitchExpressionNotAssignableCause;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSwitchExpressionNotAssignableCause = const MessageCode(
  "SwitchExpressionNotAssignableCause",
  severity: Severity.context,
  problemMessage: r"""The switch expression is here.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeSwitchHasCaseAfterDefault = messageSwitchHasCaseAfterDefault;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSwitchHasCaseAfterDefault = const MessageCode(
  "SwitchHasCaseAfterDefault",
  index: 16,
  problemMessage:
      r"""The default case should be the last case in a switch statement.""",
  correctionMessage:
      r"""Try moving the default case after the other case clauses.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeSwitchHasMultipleDefaults = messageSwitchHasMultipleDefaults;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSwitchHasMultipleDefaults = const MessageCode(
  "SwitchHasMultipleDefaults",
  index: 15,
  problemMessage: r"""The 'default' case can only be declared once.""",
  correctionMessage: r"""Try removing all but one default case.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeSyntheticToken = messageSyntheticToken;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSyntheticToken = const MessageCode(
  "SyntheticToken",
  problemMessage: r"""This couldn't be parsed.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateThisAccessInFieldInitializer =
    const Template<Message Function(String name)>(
  "ThisAccessInFieldInitializer",
  problemMessageTemplate:
      r"""Can't access 'this' in a field initializer to read '#name'.""",
  withArguments: _withArgumentsThisAccessInFieldInitializer,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeThisAccessInFieldInitializer = const Code(
  "ThisAccessInFieldInitializer",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsThisAccessInFieldInitializer(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeThisAccessInFieldInitializer,
    problemMessage:
        """Can't access 'this' in a field initializer to read '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeThisAsIdentifier = messageThisAsIdentifier;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageThisAsIdentifier = const MessageCode(
  "ThisAsIdentifier",
  analyzerCodes: <String>["INVALID_REFERENCE_TO_THIS"],
  problemMessage: r"""Expected identifier, but got 'this'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)> templateThisNotPromoted =
    const Template<Message Function(String string)>(
  "ThisNotPromoted",
  problemMessageTemplate: r"""'this' can't be promoted.""",
  correctionMessageTemplate: r"""See #string""",
  withArguments: _withArgumentsThisNotPromoted,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeThisNotPromoted = const Code(
  "ThisNotPromoted",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsThisNotPromoted(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(
    codeThisNotPromoted,
    problemMessage: """'this' can't be promoted.""",
    correctionMessage: """See ${string}""",
    arguments: {
      'string': string,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)>
    templateThisOrSuperAccessInFieldInitializer =
    const Template<Message Function(String string)>(
  "ThisOrSuperAccessInFieldInitializer",
  problemMessageTemplate: r"""Can't access '#string' in a field initializer.""",
  withArguments: _withArgumentsThisOrSuperAccessInFieldInitializer,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeThisOrSuperAccessInFieldInitializer = const Code(
  "ThisOrSuperAccessInFieldInitializer",
  analyzerCodes: <String>["THIS_ACCESS_FROM_INITIALIZER"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsThisOrSuperAccessInFieldInitializer(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(
    codeThisOrSuperAccessInFieldInitializer,
    problemMessage: """Can't access '${string}' in a field initializer.""",
    arguments: {
      'string': string,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(int count, int count2)>
    templateTooFewArguments =
    const Template<Message Function(int count, int count2)>(
  "TooFewArguments",
  problemMessageTemplate:
      r"""Too few positional arguments: #count required, #count2 given.""",
  withArguments: _withArgumentsTooFewArguments,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeTooFewArguments = const Code(
  "TooFewArguments",
  analyzerCodes: <String>["NOT_ENOUGH_REQUIRED_ARGUMENTS"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsTooFewArguments(int count, int count2) {
  return new Message(
    codeTooFewArguments,
    problemMessage:
        """Too few positional arguments: ${count} required, ${count2} given.""",
    arguments: {
      'count': count,
      'count2': count2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(int count, int count2)>
    templateTooManyArguments =
    const Template<Message Function(int count, int count2)>(
  "TooManyArguments",
  problemMessageTemplate:
      r"""Too many positional arguments: #count allowed, but #count2 found.""",
  correctionMessageTemplate:
      r"""Try removing the extra positional arguments.""",
  withArguments: _withArgumentsTooManyArguments,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeTooManyArguments = const Code(
  "TooManyArguments",
  analyzerCodes: <String>["EXTRA_POSITIONAL_ARGUMENTS"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsTooManyArguments(int count, int count2) {
  return new Message(
    codeTooManyArguments,
    problemMessage:
        """Too many positional arguments: ${count} allowed, but ${count2} found.""",
    correctionMessage: """Try removing the extra positional arguments.""",
    arguments: {
      'count': count,
      'count2': count2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeTopLevelOperator = messageTopLevelOperator;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTopLevelOperator = const MessageCode(
  "TopLevelOperator",
  index: 14,
  problemMessage: r"""Operators must be declared within a class.""",
  correctionMessage:
      r"""Try removing the operator, moving it to a class, or converting it to be a function.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeTypeAfterVar = messageTypeAfterVar;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTypeAfterVar = const MessageCode(
  "TypeAfterVar",
  index: 89,
  problemMessage:
      r"""Variables can't be declared using both 'var' and a type name.""",
  correctionMessage: r"""Try removing 'var.'""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(int count)> templateTypeArgumentMismatch =
    const Template<Message Function(int count)>(
  "TypeArgumentMismatch",
  problemMessageTemplate: r"""Expected #count type arguments.""",
  withArguments: _withArgumentsTypeArgumentMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeTypeArgumentMismatch = const Code(
  "TypeArgumentMismatch",
  analyzerCodes: <String>["WRONG_NUMBER_OF_TYPE_ARGUMENTS"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsTypeArgumentMismatch(int count) {
  return new Message(
    codeTypeArgumentMismatch,
    problemMessage: """Expected ${count} type arguments.""",
    arguments: {
      'count': count,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateTypeArgumentsOnTypeVariable =
    const Template<Message Function(String name)>(
  "TypeArgumentsOnTypeVariable",
  problemMessageTemplate:
      r"""Can't use type arguments with type variable '#name'.""",
  correctionMessageTemplate: r"""Try removing the type arguments.""",
  withArguments: _withArgumentsTypeArgumentsOnTypeVariable,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeTypeArgumentsOnTypeVariable = const Code(
  "TypeArgumentsOnTypeVariable",
  index: 13,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsTypeArgumentsOnTypeVariable(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeTypeArgumentsOnTypeVariable,
    problemMessage:
        """Can't use type arguments with type variable '${name}'.""",
    correctionMessage: """Try removing the type arguments.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeTypeBeforeFactory = messageTypeBeforeFactory;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTypeBeforeFactory = const MessageCode(
  "TypeBeforeFactory",
  index: 57,
  problemMessage: r"""Factory constructors cannot have a return type.""",
  correctionMessage: r"""Try removing the type appearing before 'factory'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateTypeNotFound =
    const Template<Message Function(String name)>(
  "TypeNotFound",
  problemMessageTemplate: r"""Type '#name' not found.""",
  withArguments: _withArgumentsTypeNotFound,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeTypeNotFound = const Code(
  "TypeNotFound",
  analyzerCodes: <String>["UNDEFINED_CLASS"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsTypeNotFound(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeTypeNotFound,
    problemMessage: """Type '${name}' not found.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, Uri uri_)> templateTypeOrigin =
    const Template<Message Function(String name, Uri uri_)>(
  "TypeOrigin",
  problemMessageTemplate: r"""'#name' is from '#uri'.""",
  withArguments: _withArgumentsTypeOrigin,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeTypeOrigin = const Code(
  "TypeOrigin",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsTypeOrigin(String name, Uri uri_) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  String? uri = relativizeUri(uri_);
  return new Message(
    codeTypeOrigin,
    problemMessage: """'${name}' is from '${uri}'.""",
    arguments: {
      'name': name,
      'uri': uri_,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, Uri uri_, Uri uri2_)>
    templateTypeOriginWithFileUri =
    const Template<Message Function(String name, Uri uri_, Uri uri2_)>(
  "TypeOriginWithFileUri",
  problemMessageTemplate: r"""'#name' is from '#uri' ('#uri2').""",
  withArguments: _withArgumentsTypeOriginWithFileUri,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeTypeOriginWithFileUri = const Code(
  "TypeOriginWithFileUri",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsTypeOriginWithFileUri(String name, Uri uri_, Uri uri2_) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  String? uri = relativizeUri(uri_);
  String? uri2 = relativizeUri(uri2_);
  return new Message(
    codeTypeOriginWithFileUri,
    problemMessage: """'${name}' is from '${uri}' ('${uri2}').""",
    arguments: {
      'name': name,
      'uri': uri_,
      'uri2': uri2_,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeTypeParameterDuplicatedName = messageTypeParameterDuplicatedName;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTypeParameterDuplicatedName = const MessageCode(
  "TypeParameterDuplicatedName",
  analyzerCodes: <String>["DUPLICATE_DEFINITION"],
  problemMessage: r"""A type variable can't have the same name as another.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateTypeParameterDuplicatedNameCause =
    const Template<Message Function(String name)>(
  "TypeParameterDuplicatedNameCause",
  problemMessageTemplate: r"""The other type variable named '#name'.""",
  withArguments: _withArgumentsTypeParameterDuplicatedNameCause,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeTypeParameterDuplicatedNameCause = const Code(
  "TypeParameterDuplicatedNameCause",
  severity: Severity.context,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsTypeParameterDuplicatedNameCause(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeTypeParameterDuplicatedNameCause,
    problemMessage: """The other type variable named '${name}'.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeTypeParameterSameNameAsEnclosing =
    messageTypeParameterSameNameAsEnclosing;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTypeParameterSameNameAsEnclosing = const MessageCode(
  "TypeParameterSameNameAsEnclosing",
  analyzerCodes: <String>["CONFLICTING_TYPE_VARIABLE_AND_CLASS"],
  problemMessage:
      r"""A type variable can't have the same name as its enclosing declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeTypeVariableInConstantContext =
    messageTypeVariableInConstantContext;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTypeVariableInConstantContext = const MessageCode(
  "TypeVariableInConstantContext",
  analyzerCodes: <String>["TYPE_PARAMETER_IN_CONST_EXPRESSION"],
  problemMessage: r"""Type variables can't be used as constants.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeTypeVariableInStaticContext = messageTypeVariableInStaticContext;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTypeVariableInStaticContext = const MessageCode(
  "TypeVariableInStaticContext",
  analyzerCodes: <String>["TYPE_PARAMETER_REFERENCED_BY_STATIC"],
  problemMessage: r"""Type variables can't be used in static members.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeTypedefCause = messageTypedefCause;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTypedefCause = const MessageCode(
  "TypedefCause",
  severity: Severity.context,
  problemMessage: r"""The issue arises via this type alias.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeTypedefInClass = messageTypedefInClass;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTypedefInClass = const MessageCode(
  "TypedefInClass",
  index: 7,
  problemMessage: r"""Typedefs can't be declared inside classes.""",
  correctionMessage: r"""Try moving the typedef to the top-level.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeTypedefNotFunction = messageTypedefNotFunction;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTypedefNotFunction = const MessageCode(
  "TypedefNotFunction",
  analyzerCodes: <String>["INVALID_GENERIC_FUNCTION_TYPE"],
  problemMessage: r"""Can't create typedef from non-function type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeTypedefNotType = messageTypedefNotType;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTypedefNotType = const MessageCode(
  "TypedefNotType",
  analyzerCodes: <String>["INVALID_TYPE_IN_TYPEDEF"],
  problemMessage: r"""Can't create typedef from non-type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeTypedefNullableType = messageTypedefNullableType;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTypedefNullableType = const MessageCode(
  "TypedefNullableType",
  problemMessage: r"""Can't create typedef from nullable type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeTypedefTypeParameterNotConstructor =
    messageTypedefTypeParameterNotConstructor;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTypedefTypeParameterNotConstructor = const MessageCode(
  "TypedefTypeParameterNotConstructor",
  problemMessage:
      r"""Can't use a typedef denoting a type variable as a constructor, nor for a static member access.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeTypedefTypeParameterNotConstructorCause =
    messageTypedefTypeParameterNotConstructorCause;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTypedefTypeParameterNotConstructorCause =
    const MessageCode(
  "TypedefTypeParameterNotConstructorCause",
  severity: Severity.context,
  problemMessage: r"""This is the type variable ultimately denoted.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeTypedefUnaliasedTypeCause = messageTypedefUnaliasedTypeCause;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTypedefUnaliasedTypeCause = const MessageCode(
  "TypedefUnaliasedTypeCause",
  severity: Severity.context,
  problemMessage: r"""This is the type denoted by the type alias.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri_)> templateUnavailableDartLibrary =
    const Template<Message Function(Uri uri_)>(
  "UnavailableDartLibrary",
  problemMessageTemplate:
      r"""Dart library '#uri' is not available on this platform.""",
  withArguments: _withArgumentsUnavailableDartLibrary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeUnavailableDartLibrary = const Code(
  "UnavailableDartLibrary",
  analyzerCodes: <String>["URI_DOES_NOT_EXIST"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnavailableDartLibrary(Uri uri_) {
  String? uri = relativizeUri(uri_);
  return new Message(
    codeUnavailableDartLibrary,
    problemMessage:
        """Dart library '${uri}' is not available on this platform.""",
    arguments: {
      'uri': uri_,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeUnexpectedDollarInString = messageUnexpectedDollarInString;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageUnexpectedDollarInString = const MessageCode(
  "UnexpectedDollarInString",
  analyzerCodes: <String>["UNEXPECTED_DOLLAR_IN_STRING"],
  problemMessage:
      r"""A '$' has special meaning inside a string, and must be followed by an identifier or an expression in curly braces ({}).""",
  correctionMessage: r"""Try adding a backslash (\) to escape the '$'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)>
    templateUnexpectedModifierInNonNnbd =
    const Template<Message Function(Token token)>(
  "UnexpectedModifierInNonNnbd",
  problemMessageTemplate:
      r"""The modifier '#lexeme' is only available in null safe libraries.""",
  withArguments: _withArgumentsUnexpectedModifierInNonNnbd,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeUnexpectedModifierInNonNnbd = const Code(
  "UnexpectedModifierInNonNnbd",
  analyzerCodes: <String>["UNEXPECTED_TOKEN"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnexpectedModifierInNonNnbd(Token token) {
  String lexeme = token.lexeme;
  return new Message(
    codeUnexpectedModifierInNonNnbd,
    problemMessage:
        """The modifier '${lexeme}' is only available in null safe libraries.""",
    arguments: {
      'lexeme': token,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeUnexpectedSeparatorInNumber = messageUnexpectedSeparatorInNumber;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageUnexpectedSeparatorInNumber = const MessageCode(
  "UnexpectedSeparatorInNumber",
  analyzerCodes: <String>["UNEXPECTED_SEPARATOR_IN_NUMBER"],
  problemMessage:
      r"""Digit separators ('_') in a number literal can only be placed between two digits.""",
  correctionMessage: r"""Try removing the '_'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeUnexpectedSuperParametersInGenerativeConstructors =
    messageUnexpectedSuperParametersInGenerativeConstructors;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageUnexpectedSuperParametersInGenerativeConstructors =
    const MessageCode(
  "UnexpectedSuperParametersInGenerativeConstructors",
  analyzerCodes: <String>["INVALID_SUPER_FORMAL_PARAMETER_LOCATION"],
  problemMessage:
      r"""Super parameters can only be used in non-redirecting generative constructors.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateUnexpectedToken =
    const Template<Message Function(Token token)>(
  "UnexpectedToken",
  problemMessageTemplate: r"""Unexpected token '#lexeme'.""",
  withArguments: _withArgumentsUnexpectedToken,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeUnexpectedToken = const Code(
  "UnexpectedToken",
  analyzerCodes: <String>["UNEXPECTED_TOKEN"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnexpectedToken(Token token) {
  String lexeme = token.lexeme;
  return new Message(
    codeUnexpectedToken,
    problemMessage: """Unexpected token '${lexeme}'.""",
    arguments: {
      'lexeme': token,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeUnexpectedTokens = messageUnexpectedTokens;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageUnexpectedTokens = const MessageCode(
  "UnexpectedTokens",
  index: 123,
  problemMessage: r"""Unexpected tokens.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateUnhandledMacroApplication =
    const Template<Message Function(String name)>(
  "UnhandledMacroApplication",
  problemMessageTemplate:
      r"""This macro application didn't apply correctly due to an unhandled #name.""",
  withArguments: _withArgumentsUnhandledMacroApplication,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeUnhandledMacroApplication = const Code(
  "UnhandledMacroApplication",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnhandledMacroApplication(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeUnhandledMacroApplication,
    problemMessage:
        """This macro application didn't apply correctly due to an unhandled ${name}.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateUnmatchedAugmentationClass =
    const Template<Message Function(String name)>(
  "UnmatchedAugmentationClass",
  problemMessageTemplate:
      r"""Augmentation class '#name' doesn't match a class in the augmented library.""",
  correctionMessageTemplate:
      r"""Try changing the name to an existing class or removing the 'augment' modifier.""",
  withArguments: _withArgumentsUnmatchedAugmentationClass,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeUnmatchedAugmentationClass = const Code(
  "UnmatchedAugmentationClass",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnmatchedAugmentationClass(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeUnmatchedAugmentationClass,
    problemMessage:
        """Augmentation class '${name}' doesn't match a class in the augmented library.""",
    correctionMessage:
        """Try changing the name to an existing class or removing the 'augment' modifier.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateUnmatchedAugmentationClassMember =
    const Template<Message Function(String name)>(
  "UnmatchedAugmentationClassMember",
  problemMessageTemplate:
      r"""Augmentation member '#name' doesn't match a member in the augmented class.""",
  correctionMessageTemplate:
      r"""Try changing the name to an existing member or removing the 'augment' modifier.""",
  withArguments: _withArgumentsUnmatchedAugmentationClassMember,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeUnmatchedAugmentationClassMember = const Code(
  "UnmatchedAugmentationClassMember",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnmatchedAugmentationClassMember(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeUnmatchedAugmentationClassMember,
    problemMessage:
        """Augmentation member '${name}' doesn't match a member in the augmented class.""",
    correctionMessage:
        """Try changing the name to an existing member or removing the 'augment' modifier.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateUnmatchedAugmentationConstructor =
    const Template<Message Function(String name)>(
  "UnmatchedAugmentationConstructor",
  problemMessageTemplate:
      r"""Augmentation constructor '#name' doesn't match a constructor in the augmented class.""",
  correctionMessageTemplate:
      r"""Try changing the name to an existing constructor or removing the 'augment' modifier.""",
  withArguments: _withArgumentsUnmatchedAugmentationConstructor,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeUnmatchedAugmentationConstructor = const Code(
  "UnmatchedAugmentationConstructor",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnmatchedAugmentationConstructor(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeUnmatchedAugmentationConstructor,
    problemMessage:
        """Augmentation constructor '${name}' doesn't match a constructor in the augmented class.""",
    correctionMessage:
        """Try changing the name to an existing constructor or removing the 'augment' modifier.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateUnmatchedAugmentationDeclaration =
    const Template<Message Function(String name)>(
  "UnmatchedAugmentationDeclaration",
  problemMessageTemplate:
      r"""Augmentation '#name' doesn't match a declaration in the augmented library.""",
  correctionMessageTemplate:
      r"""Try changing the name to an existing declaration or removing the 'augment' modifier.""",
  withArguments: _withArgumentsUnmatchedAugmentationDeclaration,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeUnmatchedAugmentationDeclaration = const Code(
  "UnmatchedAugmentationDeclaration",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnmatchedAugmentationDeclaration(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeUnmatchedAugmentationDeclaration,
    problemMessage:
        """Augmentation '${name}' doesn't match a declaration in the augmented library.""",
    correctionMessage:
        """Try changing the name to an existing declaration or removing the 'augment' modifier.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateUnmatchedAugmentationLibraryMember =
    const Template<Message Function(String name)>(
  "UnmatchedAugmentationLibraryMember",
  problemMessageTemplate:
      r"""Augmentation member '#name' doesn't match a member in the augmented library.""",
  correctionMessageTemplate:
      r"""Try changing the name to an existing member or removing the 'augment' modifier.""",
  withArguments: _withArgumentsUnmatchedAugmentationLibraryMember,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeUnmatchedAugmentationLibraryMember = const Code(
  "UnmatchedAugmentationLibraryMember",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnmatchedAugmentationLibraryMember(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeUnmatchedAugmentationLibraryMember,
    problemMessage:
        """Augmentation member '${name}' doesn't match a member in the augmented library.""",
    correctionMessage:
        """Try changing the name to an existing member or removing the 'augment' modifier.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateUnmatchedPatchClass =
    const Template<Message Function(String name)>(
  "UnmatchedPatchClass",
  problemMessageTemplate:
      r"""Patch class '#name' doesn't match a class in the origin library.""",
  correctionMessageTemplate:
      r"""Try changing the name to an existing class or removing the '@patch' annotation.""",
  withArguments: _withArgumentsUnmatchedPatchClass,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeUnmatchedPatchClass = const Code(
  "UnmatchedPatchClass",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnmatchedPatchClass(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeUnmatchedPatchClass,
    problemMessage:
        """Patch class '${name}' doesn't match a class in the origin library.""",
    correctionMessage:
        """Try changing the name to an existing class or removing the '@patch' annotation.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateUnmatchedPatchClassMember =
    const Template<Message Function(String name)>(
  "UnmatchedPatchClassMember",
  problemMessageTemplate:
      r"""Patch member '#name' doesn't match a member in the origin class.""",
  correctionMessageTemplate:
      r"""Try changing the name to an existing member or removing the '@patch' annotation.""",
  withArguments: _withArgumentsUnmatchedPatchClassMember,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeUnmatchedPatchClassMember = const Code(
  "UnmatchedPatchClassMember",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnmatchedPatchClassMember(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeUnmatchedPatchClassMember,
    problemMessage:
        """Patch member '${name}' doesn't match a member in the origin class.""",
    correctionMessage:
        """Try changing the name to an existing member or removing the '@patch' annotation.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateUnmatchedPatchConstructor =
    const Template<Message Function(String name)>(
  "UnmatchedPatchConstructor",
  problemMessageTemplate:
      r"""Patch constructor '#name' doesn't match a constructor in the origin class.""",
  correctionMessageTemplate:
      r"""Try changing the name to an existing constructor or removing the '@patch' annotation.""",
  withArguments: _withArgumentsUnmatchedPatchConstructor,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeUnmatchedPatchConstructor = const Code(
  "UnmatchedPatchConstructor",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnmatchedPatchConstructor(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeUnmatchedPatchConstructor,
    problemMessage:
        """Patch constructor '${name}' doesn't match a constructor in the origin class.""",
    correctionMessage:
        """Try changing the name to an existing constructor or removing the '@patch' annotation.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateUnmatchedPatchDeclaration =
    const Template<Message Function(String name)>(
  "UnmatchedPatchDeclaration",
  problemMessageTemplate:
      r"""Patch '#name' doesn't match a declaration in the origin library.""",
  correctionMessageTemplate:
      r"""Try changing the name to an existing declaration or removing the '@patch' annotation.""",
  withArguments: _withArgumentsUnmatchedPatchDeclaration,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeUnmatchedPatchDeclaration = const Code(
  "UnmatchedPatchDeclaration",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnmatchedPatchDeclaration(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeUnmatchedPatchDeclaration,
    problemMessage:
        """Patch '${name}' doesn't match a declaration in the origin library.""",
    correctionMessage:
        """Try changing the name to an existing declaration or removing the '@patch' annotation.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateUnmatchedPatchLibraryMember =
    const Template<Message Function(String name)>(
  "UnmatchedPatchLibraryMember",
  problemMessageTemplate:
      r"""Patch member '#name' doesn't match a member in the origin library.""",
  correctionMessageTemplate:
      r"""Try changing the name to an existing member or removing the '@patch' annotation.""",
  withArguments: _withArgumentsUnmatchedPatchLibraryMember,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeUnmatchedPatchLibraryMember = const Code(
  "UnmatchedPatchLibraryMember",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnmatchedPatchLibraryMember(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeUnmatchedPatchLibraryMember,
    problemMessage:
        """Patch member '${name}' doesn't match a member in the origin library.""",
    correctionMessage:
        """Try changing the name to an existing member or removing the '@patch' annotation.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string, Token token)>
    templateUnmatchedToken =
    const Template<Message Function(String string, Token token)>(
  "UnmatchedToken",
  problemMessageTemplate: r"""Can't find '#string' to match '#lexeme'.""",
  withArguments: _withArgumentsUnmatchedToken,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeUnmatchedToken = const Code(
  "UnmatchedToken",
  analyzerCodes: <String>["EXPECTED_TOKEN"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnmatchedToken(String string, Token token) {
  if (string.isEmpty) throw 'No string provided';
  String lexeme = token.lexeme;
  return new Message(
    codeUnmatchedToken,
    problemMessage: """Can't find '${string}' to match '${lexeme}'.""",
    arguments: {
      'string': string,
      'lexeme': token,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeUnnamedObjectPatternField = messageUnnamedObjectPatternField;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageUnnamedObjectPatternField = const MessageCode(
  "UnnamedObjectPatternField",
  problemMessage: r"""A pattern field in an object pattern must be named.""",
  correctionMessage:
      r"""Try adding a pattern name or ':' before the pattern.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeUnsoundSwitchExpressionError =
    messageUnsoundSwitchExpressionError;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageUnsoundSwitchExpressionError = const MessageCode(
  "UnsoundSwitchExpressionError",
  problemMessage:
      r"""None of the patterns in the switch expression the matched input value. See https://github.com/dart-lang/language/issues/3488 for details.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeUnsoundSwitchStatementError = messageUnsoundSwitchStatementError;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageUnsoundSwitchStatementError = const MessageCode(
  "UnsoundSwitchStatementError",
  problemMessage:
      r"""None of the patterns in the exhaustive switch statement the matched input value. See https://github.com/dart-lang/language/issues/3488 for details.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)> templateUnspecified =
    const Template<Message Function(String string)>(
  "Unspecified",
  problemMessageTemplate: r"""#string""",
  withArguments: _withArgumentsUnspecified,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeUnspecified = const Code(
  "Unspecified",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnspecified(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(
    codeUnspecified,
    problemMessage: """${string}""",
    arguments: {
      'string': string,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeUnspecifiedGetterNameInObjectPattern =
    messageUnspecifiedGetterNameInObjectPattern;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageUnspecifiedGetterNameInObjectPattern =
    const MessageCode(
  "UnspecifiedGetterNameInObjectPattern",
  analyzerCodes: <String>["MISSING_OBJECT_PATTERN_GETTER_NAME"],
  problemMessage:
      r"""The getter name is not specified explicitly, and the pattern is not a variable. Try specifying the getter name explicitly, or using a variable pattern.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeUnsupportedDartExt = messageUnsupportedDartExt;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageUnsupportedDartExt = const MessageCode(
  "UnsupportedDartExt",
  problemMessage: r"""Dart native extensions are no longer supported.""",
  correctionMessage:
      r"""Migrate to using FFI instead (https://dart.dev/guides/libraries/c-interop)""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeUnsupportedMacroApplication = messageUnsupportedMacroApplication;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageUnsupportedMacroApplication = const MessageCode(
  "UnsupportedMacroApplication",
  problemMessage: r"""This macro application didn't apply correctly.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateUnsupportedOperator =
    const Template<Message Function(Token token)>(
  "UnsupportedOperator",
  problemMessageTemplate: r"""The '#lexeme' operator is not supported.""",
  withArguments: _withArgumentsUnsupportedOperator,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeUnsupportedOperator = const Code(
  "UnsupportedOperator",
  analyzerCodes: <String>["UNSUPPORTED_OPERATOR"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnsupportedOperator(Token token) {
  String lexeme = token.lexeme;
  return new Message(
    codeUnsupportedOperator,
    problemMessage: """The '${lexeme}' operator is not supported.""",
    arguments: {
      'lexeme': token,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeUnsupportedPrefixPlus = messageUnsupportedPrefixPlus;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageUnsupportedPrefixPlus = const MessageCode(
  "UnsupportedPrefixPlus",
  analyzerCodes: <String>["MISSING_IDENTIFIER"],
  problemMessage: r"""'+' is not a prefix operator.""",
  correctionMessage: r"""Try removing '+'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeUnterminatedComment = messageUnterminatedComment;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageUnterminatedComment = const MessageCode(
  "UnterminatedComment",
  analyzerCodes: <String>["UNTERMINATED_MULTI_LINE_COMMENT"],
  problemMessage: r"""Comment starting with '/*' must end with '*/'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string, String string2)>
    templateUnterminatedString =
    const Template<Message Function(String string, String string2)>(
  "UnterminatedString",
  problemMessageTemplate:
      r"""String starting with #string must end with #string2.""",
  withArguments: _withArgumentsUnterminatedString,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeUnterminatedString = const Code(
  "UnterminatedString",
  analyzerCodes: <String>["UNTERMINATED_STRING_LITERAL"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnterminatedString(String string, String string2) {
  if (string.isEmpty) throw 'No string provided';
  if (string2.isEmpty) throw 'No string provided';
  return new Message(
    codeUnterminatedString,
    problemMessage:
        """String starting with ${string} must end with ${string2}.""",
    arguments: {
      'string': string,
      'string2': string2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeUnterminatedToken = messageUnterminatedToken;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageUnterminatedToken = const MessageCode(
  "UnterminatedToken",
  problemMessage: r"""Incomplete token.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri_)> templateUntranslatableUri =
    const Template<Message Function(Uri uri_)>(
  "UntranslatableUri",
  problemMessageTemplate: r"""Not found: '#uri'""",
  withArguments: _withArgumentsUntranslatableUri,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeUntranslatableUri = const Code(
  "UntranslatableUri",
  analyzerCodes: <String>["URI_DOES_NOT_EXIST"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUntranslatableUri(Uri uri_) {
  String? uri = relativizeUri(uri_);
  return new Message(
    codeUntranslatableUri,
    problemMessage: """Not found: '${uri}'""",
    arguments: {
      'uri': uri_,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateValueForRequiredParameterNotProvidedError =
    const Template<Message Function(String name)>(
  "ValueForRequiredParameterNotProvidedError",
  problemMessageTemplate:
      r"""Required named parameter '#name' must be provided.""",
  withArguments: _withArgumentsValueForRequiredParameterNotProvidedError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeValueForRequiredParameterNotProvidedError = const Code(
  "ValueForRequiredParameterNotProvidedError",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsValueForRequiredParameterNotProvidedError(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(
    codeValueForRequiredParameterNotProvidedError,
    problemMessage: """Required named parameter '${name}' must be provided.""",
    arguments: {
      'name': name,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeVarAsTypeName = messageVarAsTypeName;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageVarAsTypeName = const MessageCode(
  "VarAsTypeName",
  index: 61,
  problemMessage: r"""The keyword 'var' can't be used as a type name.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeVarReturnType = messageVarReturnType;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageVarReturnType = const MessageCode(
  "VarReturnType",
  index: 12,
  problemMessage: r"""The return type can't be 'var'.""",
  correctionMessage:
      r"""Try removing the keyword 'var', or replacing it with the name of the return type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String string)>
    templateVariableCouldBeNullDueToWrite =
    const Template<Message Function(String name, String string)>(
  "VariableCouldBeNullDueToWrite",
  problemMessageTemplate:
      r"""Variable '#name' could not be promoted due to an assignment.""",
  correctionMessageTemplate:
      r"""Try null checking the variable after the assignment.  See #string""",
  withArguments: _withArgumentsVariableCouldBeNullDueToWrite,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeVariableCouldBeNullDueToWrite = const Code(
  "VariableCouldBeNullDueToWrite",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsVariableCouldBeNullDueToWrite(
    String name, String string) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (string.isEmpty) throw 'No string provided';
  return new Message(
    codeVariableCouldBeNullDueToWrite,
    problemMessage:
        """Variable '${name}' could not be promoted due to an assignment.""",
    correctionMessage:
        """Try null checking the variable after the assignment.  See ${string}""",
    arguments: {
      'name': name,
      'string': string,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeVariablePatternKeywordInDeclarationContext =
    messageVariablePatternKeywordInDeclarationContext;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageVariablePatternKeywordInDeclarationContext =
    const MessageCode(
  "VariablePatternKeywordInDeclarationContext",
  index: 149,
  problemMessage:
      r"""Variable patterns in declaration context can't specify 'var' or 'final' keyword.""",
  correctionMessage: r"""Try removing the keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeVerificationErrorOriginContext =
    messageVerificationErrorOriginContext;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageVerificationErrorOriginContext = const MessageCode(
  "VerificationErrorOriginContext",
  severity: Severity.context,
  problemMessage:
      r"""The node most likely is taken from here by a transformer.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeVoidExpression = messageVoidExpression;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageVoidExpression = const MessageCode(
  "VoidExpression",
  analyzerCodes: <String>["USE_OF_VOID_RESULT"],
  problemMessage: r"""This expression has type 'void' and can't be used.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeVoidWithTypeArguments = messageVoidWithTypeArguments;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageVoidWithTypeArguments = const MessageCode(
  "VoidWithTypeArguments",
  index: 100,
  problemMessage: r"""Type 'void' can't have type arguments.""",
  correctionMessage: r"""Try removing the type arguments.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeWasmImportOrExportInUserCode =
    messageWasmImportOrExportInUserCode;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageWasmImportOrExportInUserCode = const MessageCode(
  "WasmImportOrExportInUserCode",
  problemMessage:
      r"""Pragmas `wasm:import` and `wasm:export` are for internal use only and cannot be used by user code.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeWeakReferenceMismatchReturnAndArgumentTypes =
    messageWeakReferenceMismatchReturnAndArgumentTypes;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageWeakReferenceMismatchReturnAndArgumentTypes =
    const MessageCode(
  "WeakReferenceMismatchReturnAndArgumentTypes",
  problemMessage:
      r"""Return and argument types of a weak reference should match.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeWeakReferenceNotOneArgument = messageWeakReferenceNotOneArgument;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageWeakReferenceNotOneArgument = const MessageCode(
  "WeakReferenceNotOneArgument",
  problemMessage:
      r"""Weak reference should take one required positional argument.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeWeakReferenceNotStatic = messageWeakReferenceNotStatic;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageWeakReferenceNotStatic = const MessageCode(
  "WeakReferenceNotStatic",
  problemMessage:
      r"""Weak reference pragma can be used on a static method only.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeWeakReferenceReturnTypeNotNullable =
    messageWeakReferenceReturnTypeNotNullable;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageWeakReferenceReturnTypeNotNullable = const MessageCode(
  "WeakReferenceReturnTypeNotNullable",
  problemMessage: r"""Return type of a weak reference should be nullable.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeWeakReferenceTargetHasParameters =
    messageWeakReferenceTargetHasParameters;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageWeakReferenceTargetHasParameters = const MessageCode(
  "WeakReferenceTargetHasParameters",
  problemMessage:
      r"""The target of weak reference should not take parameters.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeWeakReferenceTargetNotStaticTearoff =
    messageWeakReferenceTargetNotStaticTearoff;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageWeakReferenceTargetNotStaticTearoff =
    const MessageCode(
  "WeakReferenceTargetNotStaticTearoff",
  problemMessage:
      r"""The target of weak reference should be a tearoff of a static method.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeWeakWithStrongDillLibrary = messageWeakWithStrongDillLibrary;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageWeakWithStrongDillLibrary = const MessageCode(
  "WeakWithStrongDillLibrary",
  problemMessage:
      r"""Loaded library is compiled with sound null safety and cannot be used in compilation for unsound null safety.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string, String string2)>
    templateWebLiteralCannotBeRepresentedExactly =
    const Template<Message Function(String string, String string2)>(
  "WebLiteralCannotBeRepresentedExactly",
  problemMessageTemplate:
      r"""The integer literal #string can't be represented exactly in JavaScript.""",
  correctionMessageTemplate:
      r"""Try changing the literal to something that can be represented in JavaScript. In JavaScript #string2 is the nearest value that can be represented exactly.""",
  withArguments: _withArgumentsWebLiteralCannotBeRepresentedExactly,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeWebLiteralCannotBeRepresentedExactly = const Code(
  "WebLiteralCannotBeRepresentedExactly",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsWebLiteralCannotBeRepresentedExactly(
    String string, String string2) {
  if (string.isEmpty) throw 'No string provided';
  if (string2.isEmpty) throw 'No string provided';
  return new Message(
    codeWebLiteralCannotBeRepresentedExactly,
    problemMessage:
        """The integer literal ${string} can't be represented exactly in JavaScript.""",
    correctionMessage:
        """Try changing the literal to something that can be represented in JavaScript. In JavaScript ${string2} is the nearest value that can be represented exactly.""",
    arguments: {
      'string': string,
      'string2': string2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeWithBeforeExtends = messageWithBeforeExtends;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageWithBeforeExtends = const MessageCode(
  "WithBeforeExtends",
  index: 11,
  problemMessage: r"""The extends clause must be before the with clause.""",
  correctionMessage:
      r"""Try moving the extends clause before the with clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeYieldAsIdentifier = messageYieldAsIdentifier;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageYieldAsIdentifier = const MessageCode(
  "YieldAsIdentifier",
  analyzerCodes: <String>["ASYNC_KEYWORD_USED_AS_IDENTIFIER"],
  problemMessage:
      r"""'yield' can't be used as an identifier in 'async', 'async*', or 'sync*' methods.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code codeYieldNotGenerator = messageYieldNotGenerator;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageYieldNotGenerator = const MessageCode(
  "YieldNotGenerator",
  analyzerCodes: <String>["YIELD_IN_NON_GENERATOR"],
  problemMessage:
      r"""'yield' can only be used in 'sync*' or 'async*' methods.""",
);
