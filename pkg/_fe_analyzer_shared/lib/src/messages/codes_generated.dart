// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// NOTE: THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/front_end/messages.yaml' and run
// 'pkg/front_end/tool/fasta generate-messages' to update.

// ignore_for_file: lines_longer_than_80_chars

part of _fe_analyzer_shared.messages.codes;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateAbstractClassInstantiation =
    const Template<Message Function(String name)>(
        messageTemplate:
            r"""The class '#name' is abstract and can't be instantiated.""",
        withArguments: _withArgumentsAbstractClassInstantiation);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeAbstractClassInstantiation =
    const Code<Message Function(String name)>(
        "AbstractClassInstantiation", templateAbstractClassInstantiation,
        analyzerCodes: <String>["NEW_WITH_ABSTRACT_CLASS"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsAbstractClassInstantiation(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeAbstractClassInstantiation,
      message: """The class '${name}' is abstract and can't be instantiated.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeAbstractClassMember = messageAbstractClassMember;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAbstractClassMember = const MessageCode(
    "AbstractClassMember",
    index: 51,
    message: r"""Members of classes can't be declared to be 'abstract'.""",
    tip:
        r"""Try removing the 'abstract' keyword. You can add the 'abstract' keyword before the class declaration.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeAbstractNotSync = messageAbstractNotSync;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAbstractNotSync = const MessageCode("AbstractNotSync",
    analyzerCodes: <String>["NON_SYNC_ABSTRACT_METHOD"],
    message: r"""Abstract methods can't use 'async', 'async*', or 'sync*'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            name)> templateAbstractRedirectedClassInstantiation = const Template<
        Message Function(String name)>(
    messageTemplate:
        r"""Factory redirects to class '#name', which is abstract and can't be instantiated.""",
    withArguments: _withArgumentsAbstractRedirectedClassInstantiation);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)>
    codeAbstractRedirectedClassInstantiation =
    const Code<Message Function(String name)>(
        "AbstractRedirectedClassInstantiation",
        templateAbstractRedirectedClassInstantiation,
        analyzerCodes: <String>["FACTORY_REDIRECTS_TO_ABSTRACT_CLASS"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsAbstractRedirectedClassInstantiation(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeAbstractRedirectedClassInstantiation,
      message:
          """Factory redirects to class '${name}', which is abstract and can't be instantiated.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateAccessError =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Access error: '#name'.""",
        withArguments: _withArgumentsAccessError);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeAccessError =
    const Code<Message Function(String name)>(
  "AccessError",
  templateAccessError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsAccessError(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeAccessError,
      message: """Access error: '${name}'.""", arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeAmbiguousExtensionCause = messageAmbiguousExtensionCause;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAmbiguousExtensionCause = const MessageCode(
    "AmbiguousExtensionCause",
    severity: Severity.context,
    message: r"""This is one of the extension members.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeAnnotationOnFunctionTypeTypeVariable =
    messageAnnotationOnFunctionTypeTypeVariable;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAnnotationOnFunctionTypeTypeVariable =
    const MessageCode("AnnotationOnFunctionTypeTypeVariable",
        message:
            r"""A type variable on a function type can't have annotations.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeAnonymousBreakTargetOutsideFunction =
    messageAnonymousBreakTargetOutsideFunction;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAnonymousBreakTargetOutsideFunction =
    const MessageCode("AnonymousBreakTargetOutsideFunction",
        analyzerCodes: <String>["LABEL_IN_OUTER_SCOPE"],
        message: r"""Can't break to a target in a different function.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeAnonymousContinueTargetOutsideFunction =
    messageAnonymousContinueTargetOutsideFunction;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAnonymousContinueTargetOutsideFunction =
    const MessageCode("AnonymousContinueTargetOutsideFunction",
        analyzerCodes: <String>["LABEL_IN_OUTER_SCOPE"],
        message: r"""Can't continue at a target in a different function.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        int
            codePoint)> templateAsciiControlCharacter = const Template<
        Message Function(int codePoint)>(
    messageTemplate:
        r"""The control character #unicode can only be used in strings and comments.""",
    withArguments: _withArgumentsAsciiControlCharacter);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(int codePoint)> codeAsciiControlCharacter =
    const Code<Message Function(int codePoint)>(
        "AsciiControlCharacter", templateAsciiControlCharacter,
        analyzerCodes: <String>["ILLEGAL_CHARACTER"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsAsciiControlCharacter(int codePoint) {
  String unicode =
      "U+${codePoint.toRadixString(16).toUpperCase().padLeft(4, '0')}";
  return new Message(codeAsciiControlCharacter,
      message:
          """The control character ${unicode} can only be used in strings and comments.""",
      arguments: {'codePoint': codePoint});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeAssertAsExpression = messageAssertAsExpression;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAssertAsExpression = const MessageCode(
    "AssertAsExpression",
    message: r"""`assert` can't be used as an expression.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeAssertExtraneousArgument = messageAssertExtraneousArgument;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAssertExtraneousArgument = const MessageCode(
    "AssertExtraneousArgument",
    message: r"""`assert` can't have more than two arguments.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeAwaitAsIdentifier = messageAwaitAsIdentifier;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAwaitAsIdentifier = const MessageCode(
    "AwaitAsIdentifier",
    analyzerCodes: <String>["ASYNC_KEYWORD_USED_AS_IDENTIFIER"],
    message:
        r"""'await' can't be used as an identifier in 'async', 'async*', or 'sync*' methods.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeAwaitForNotAsync = messageAwaitForNotAsync;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAwaitForNotAsync = const MessageCode(
    "AwaitForNotAsync",
    analyzerCodes: <String>["ASYNC_FOR_IN_WRONG_CONTEXT"],
    message:
        r"""The asynchronous for-in can only be used in functions marked with 'async' or 'async*'.""",
    tip:
        r"""Try marking the function body with either 'async' or 'async*', or removing the 'await' before the for loop.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeAwaitInLateLocalInitializer =
    messageAwaitInLateLocalInitializer;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAwaitInLateLocalInitializer = const MessageCode(
    "AwaitInLateLocalInitializer",
    message:
        r"""`await` expressions are not supported in late local initializers.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeAwaitNotAsync = messageAwaitNotAsync;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAwaitNotAsync = const MessageCode("AwaitNotAsync",
    analyzerCodes: <String>["AWAIT_IN_WRONG_CONTEXT"],
    message: r"""'await' can only be used in 'async' or 'async*' methods.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String name,
        String
            name2)> templateBoundIssueViaCycleNonSimplicity = const Template<
        Message Function(String name,
            String name2)>(
    messageTemplate:
        r"""Generic type '#name' can't be used without type arguments in the bounds of its own type variables. It is referenced indirectly through '#name2'.""",
    tipTemplate:
        r"""Try providing type arguments to '#name2' here or to some other raw types in the bounds along the reference chain.""",
    withArguments: _withArgumentsBoundIssueViaCycleNonSimplicity);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String name2)>
    codeBoundIssueViaCycleNonSimplicity =
    const Code<Message Function(String name, String name2)>(
        "BoundIssueViaCycleNonSimplicity",
        templateBoundIssueViaCycleNonSimplicity,
        analyzerCodes: <String>["NOT_INSTANTIATED_BOUND"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsBoundIssueViaCycleNonSimplicity(
    String name, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(codeBoundIssueViaCycleNonSimplicity,
      message:
          """Generic type '${name}' can't be used without type arguments in the bounds of its own type variables. It is referenced indirectly through '${name2}'.""",
      tip: """Try providing type arguments to '${name2}' here or to some other raw types in the bounds along the reference chain.""",
      arguments: {'name': name, 'name2': name2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            name)> templateBoundIssueViaLoopNonSimplicity = const Template<
        Message Function(String name)>(
    messageTemplate:
        r"""Generic type '#name' can't be used without type arguments in the bounds of its own type variables.""",
    tipTemplate: r"""Try providing type arguments to '#name' here.""",
    withArguments: _withArgumentsBoundIssueViaLoopNonSimplicity);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeBoundIssueViaLoopNonSimplicity =
    const Code<Message Function(String name)>("BoundIssueViaLoopNonSimplicity",
        templateBoundIssueViaLoopNonSimplicity,
        analyzerCodes: <String>["NOT_INSTANTIATED_BOUND"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsBoundIssueViaLoopNonSimplicity(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeBoundIssueViaLoopNonSimplicity,
      message:
          """Generic type '${name}' can't be used without type arguments in the bounds of its own type variables.""",
      tip: """Try providing type arguments to '${name}' here.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateBoundIssueViaRawTypeWithNonSimpleBounds =
    const Template<Message Function(String name)>(
        messageTemplate:
            r"""Generic type '#name' can't be used without type arguments in a type variable bound.""",
        tipTemplate: r"""Try providing type arguments to '#name' here.""",
        withArguments: _withArgumentsBoundIssueViaRawTypeWithNonSimpleBounds);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)>
    codeBoundIssueViaRawTypeWithNonSimpleBounds =
    const Code<Message Function(String name)>(
        "BoundIssueViaRawTypeWithNonSimpleBounds",
        templateBoundIssueViaRawTypeWithNonSimpleBounds,
        analyzerCodes: <String>["NOT_INSTANTIATED_BOUND"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsBoundIssueViaRawTypeWithNonSimpleBounds(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeBoundIssueViaRawTypeWithNonSimpleBounds,
      message:
          """Generic type '${name}' can't be used without type arguments in a type variable bound.""",
      tip: """Try providing type arguments to '${name}' here.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeBreakOutsideOfLoop = messageBreakOutsideOfLoop;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageBreakOutsideOfLoop = const MessageCode(
    "BreakOutsideOfLoop",
    index: 52,
    message:
        r"""A break statement can't be used outside of a loop or switch statement.""",
    tip: r"""Try removing the break statement.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateBreakTargetOutsideFunction =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Can't break to '#name' in a different function.""",
        withArguments: _withArgumentsBreakTargetOutsideFunction);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeBreakTargetOutsideFunction =
    const Code<Message Function(String name)>(
        "BreakTargetOutsideFunction", templateBreakTargetOutsideFunction,
        analyzerCodes: <String>["LABEL_IN_OUTER_SCOPE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsBreakTargetOutsideFunction(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeBreakTargetOutsideFunction,
      message: """Can't break to '${name}' in a different function.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateBuiltInIdentifierAsType =
    const Template<Message Function(Token token)>(
        messageTemplate:
            r"""The built-in identifier '#lexeme' can't be used as a type.""",
        withArguments: _withArgumentsBuiltInIdentifierAsType);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeBuiltInIdentifierAsType =
    const Code<Message Function(Token token)>(
        "BuiltInIdentifierAsType", templateBuiltInIdentifierAsType,
        analyzerCodes: <String>["BUILT_IN_IDENTIFIER_AS_TYPE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsBuiltInIdentifierAsType(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeBuiltInIdentifierAsType,
      message:
          """The built-in identifier '${lexeme}' can't be used as a type.""",
      arguments: {'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)>
    templateBuiltInIdentifierInDeclaration =
    const Template<Message Function(Token token)>(
        messageTemplate: r"""Can't use '#lexeme' as a name here.""",
        withArguments: _withArgumentsBuiltInIdentifierInDeclaration);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeBuiltInIdentifierInDeclaration =
    const Code<Message Function(Token token)>("BuiltInIdentifierInDeclaration",
        templateBuiltInIdentifierInDeclaration,
        analyzerCodes: <String>["BUILT_IN_IDENTIFIER_IN_DECLARATION"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsBuiltInIdentifierInDeclaration(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeBuiltInIdentifierInDeclaration,
      message: """Can't use '${lexeme}' as a name here.""",
      arguments: {'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeBytecodeLimitExceededTooManyArguments =
    messageBytecodeLimitExceededTooManyArguments;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageBytecodeLimitExceededTooManyArguments =
    const MessageCode("BytecodeLimitExceededTooManyArguments",
        message: r"""Dart bytecode limit exceeded: too many arguments.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeCandidateFound = messageCandidateFound;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCandidateFound = const MessageCode("CandidateFound",
    severity: Severity.context,
    message: r"""Found this candidate, but the arguments don't match.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateCandidateFoundIsDefaultConstructor =
    const Template<Message Function(String name)>(
        messageTemplate:
            r"""The class '#name' has a constructor that takes no arguments.""",
        withArguments: _withArgumentsCandidateFoundIsDefaultConstructor);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)>
    codeCandidateFoundIsDefaultConstructor =
    const Code<Message Function(String name)>(
        "CandidateFoundIsDefaultConstructor",
        templateCandidateFoundIsDefaultConstructor,
        severity: Severity.context);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCandidateFoundIsDefaultConstructor(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeCandidateFoundIsDefaultConstructor,
      message:
          """The class '${name}' has a constructor that takes no arguments.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateCannotAssignToConstVariable =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Can't assign to the const variable '#name'.""",
        withArguments: _withArgumentsCannotAssignToConstVariable);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeCannotAssignToConstVariable =
    const Code<Message Function(String name)>(
  "CannotAssignToConstVariable",
  templateCannotAssignToConstVariable,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCannotAssignToConstVariable(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeCannotAssignToConstVariable,
      message: """Can't assign to the const variable '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeCannotAssignToExtensionThis =
    messageCannotAssignToExtensionThis;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCannotAssignToExtensionThis = const MessageCode(
    "CannotAssignToExtensionThis",
    message: r"""Can't assign to 'this'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateCannotAssignToFinalVariable =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Can't assign to the final variable '#name'.""",
        withArguments: _withArgumentsCannotAssignToFinalVariable);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeCannotAssignToFinalVariable =
    const Code<Message Function(String name)>(
  "CannotAssignToFinalVariable",
  templateCannotAssignToFinalVariable,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCannotAssignToFinalVariable(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeCannotAssignToFinalVariable,
      message: """Can't assign to the final variable '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeCannotAssignToParenthesizedExpression =
    messageCannotAssignToParenthesizedExpression;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCannotAssignToParenthesizedExpression =
    const MessageCode("CannotAssignToParenthesizedExpression",
        analyzerCodes: <String>["ASSIGNMENT_TO_PARENTHESIZED_EXPRESSION"],
        message: r"""Can't assign to a parenthesized expression.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeCannotAssignToSuper = messageCannotAssignToSuper;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCannotAssignToSuper = const MessageCode(
    "CannotAssignToSuper",
    analyzerCodes: <String>["NOT_AN_LVALUE"],
    message: r"""Can't assign to super.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeCannotAssignToTypeLiteral =
    messageCannotAssignToTypeLiteral;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCannotAssignToTypeLiteral = const MessageCode(
    "CannotAssignToTypeLiteral",
    message: r"""Can't assign to a type literal.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)>
    templateCannotReadSdkSpecification =
    const Template<Message Function(String string)>(
        messageTemplate:
            r"""Unable to read the 'libraries.json' specification file:
  #string.""",
        withArguments: _withArgumentsCannotReadSdkSpecification);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string)> codeCannotReadSdkSpecification =
    const Code<Message Function(String string)>(
  "CannotReadSdkSpecification",
  templateCannotReadSdkSpecification,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCannotReadSdkSpecification(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeCannotReadSdkSpecification,
      message: """Unable to read the 'libraries.json' specification file:
  ${string}.""", arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeCantDisambiguateAmbiguousInformation =
    messageCantDisambiguateAmbiguousInformation;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCantDisambiguateAmbiguousInformation = const MessageCode(
    "CantDisambiguateAmbiguousInformation",
    message:
        r"""Both Iterable and Map spread elements encountered in ambiguous literal.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeCantDisambiguateNotEnoughInformation =
    messageCantDisambiguateNotEnoughInformation;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCantDisambiguateNotEnoughInformation = const MessageCode(
    "CantDisambiguateNotEnoughInformation",
    message:
        r"""Not enough type information to disambiguate between literal set and literal map.""",
    tip:
        r"""Try providing type arguments for the literal explicitly to disambiguate it.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeCantInferPackagesFromManyInputs =
    messageCantInferPackagesFromManyInputs;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCantInferPackagesFromManyInputs = const MessageCode(
    "CantInferPackagesFromManyInputs",
    message: r"""Can't infer a packages file when compiling multiple inputs.""",
    tip: r"""Try specifying the file explicitly with the --packages option.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeCantInferPackagesFromPackageUri =
    messageCantInferPackagesFromPackageUri;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCantInferPackagesFromPackageUri = const MessageCode(
    "CantInferPackagesFromPackageUri",
    message: r"""Can't infer a packages file from an input 'package:*' URI.""",
    tip: r"""Try specifying the file explicitly with the --packages option.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateCantInferReturnTypeDueToInconsistentOverrides =
    const Template<Message Function(String name)>(
        messageTemplate:
            r"""Can't infer a return type for '#name' as some of the inherited members have different types.""",
        tipTemplate: r"""Try adding an explicit type.""",
        withArguments:
            _withArgumentsCantInferReturnTypeDueToInconsistentOverrides);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)>
    codeCantInferReturnTypeDueToInconsistentOverrides =
    const Code<Message Function(String name)>(
        "CantInferReturnTypeDueToInconsistentOverrides",
        templateCantInferReturnTypeDueToInconsistentOverrides,
        analyzerCodes: <String>["INVALID_METHOD_OVERRIDE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCantInferReturnTypeDueToInconsistentOverrides(
    String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeCantInferReturnTypeDueToInconsistentOverrides,
      message:
          """Can't infer a return type for '${name}' as some of the inherited members have different types.""",
      tip: """Try adding an explicit type.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            string)> templateCantInferTypeDueToCircularity = const Template<
        Message Function(String string)>(
    messageTemplate:
        r"""Can't infer the type of '#string': circularity found during type inference.""",
    tipTemplate: r"""Specify the type explicitly.""",
    withArguments: _withArgumentsCantInferTypeDueToCircularity);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string)> codeCantInferTypeDueToCircularity =
    const Code<Message Function(String string)>(
        "CantInferTypeDueToCircularity", templateCantInferTypeDueToCircularity,
        analyzerCodes: <String>["RECURSIVE_COMPILE_TIME_CONSTANT"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCantInferTypeDueToCircularity(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeCantInferTypeDueToCircularity,
      message:
          """Can't infer the type of '${string}': circularity found during type inference.""",
      tip: """Specify the type explicitly.""",
      arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateCantInferTypeDueToInconsistentOverrides =
    const Template<Message Function(String name)>(
        messageTemplate:
            r"""Can't infer a type for '#name' as some of the inherited members have different types.""",
        tipTemplate: r"""Try adding an explicit type.""",
        withArguments: _withArgumentsCantInferTypeDueToInconsistentOverrides);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)>
    codeCantInferTypeDueToInconsistentOverrides =
    const Code<Message Function(String name)>(
        "CantInferTypeDueToInconsistentOverrides",
        templateCantInferTypeDueToInconsistentOverrides,
        analyzerCodes: <String>["INVALID_METHOD_OVERRIDE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCantInferTypeDueToInconsistentOverrides(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeCantInferTypeDueToInconsistentOverrides,
      message:
          """Can't infer a type for '${name}' as some of the inherited members have different types.""",
      tip: """Try adding an explicit type.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri_, String string)> templateCantReadFile =
    const Template<Message Function(Uri uri_, String string)>(
        messageTemplate: r"""Error when reading '#uri': #string""",
        withArguments: _withArgumentsCantReadFile);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Uri uri_, String string)> codeCantReadFile =
    const Code<Message Function(Uri uri_, String string)>(
        "CantReadFile", templateCantReadFile,
        analyzerCodes: <String>["URI_DOES_NOT_EXIST"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCantReadFile(Uri uri_, String string) {
  String uri = relativizeUri(uri_);
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeCantReadFile,
      message: """Error when reading '${uri}': ${string}""",
      arguments: {'uri': uri_, 'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)>
    templateCantUseControlFlowOrSpreadAsConstant =
    const Template<Message Function(Token token)>(
        messageTemplate:
            r"""'#lexeme' is not supported in constant expressions.""",
        withArguments: _withArgumentsCantUseControlFlowOrSpreadAsConstant);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)>
    codeCantUseControlFlowOrSpreadAsConstant =
    const Code<Message Function(Token token)>(
        "CantUseControlFlowOrSpreadAsConstant",
        templateCantUseControlFlowOrSpreadAsConstant,
        analyzerCodes: <String>["NOT_CONSTANT_EXPRESSION"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCantUseControlFlowOrSpreadAsConstant(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeCantUseControlFlowOrSpreadAsConstant,
      message: """'${lexeme}' is not supported in constant expressions.""",
      arguments: {'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        Token
            token)> templateCantUseDeferredPrefixAsConstant = const Template<
        Message Function(Token token)>(
    messageTemplate:
        r"""'#lexeme' can't be used in a constant expression because it's marked as 'deferred' which means it isn't available until loaded.""",
    tipTemplate:
        r"""Try moving the constant from the deferred library, or removing 'deferred' from the import.
""",
    withArguments: _withArgumentsCantUseDeferredPrefixAsConstant);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeCantUseDeferredPrefixAsConstant =
    const Code<Message Function(Token token)>("CantUseDeferredPrefixAsConstant",
        templateCantUseDeferredPrefixAsConstant,
        analyzerCodes: <String>["CONST_DEFERRED_CLASS"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCantUseDeferredPrefixAsConstant(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeCantUseDeferredPrefixAsConstant,
      message:
          """'${lexeme}' can't be used in a constant expression because it's marked as 'deferred' which means it isn't available until loaded.""",
      tip: """Try moving the constant from the deferred library, or removing 'deferred' from the import.
""",
      arguments: {'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeCantUsePrefixAsExpression =
    messageCantUsePrefixAsExpression;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCantUsePrefixAsExpression = const MessageCode(
    "CantUsePrefixAsExpression",
    analyzerCodes: <String>["PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT"],
    message: r"""A prefix can't be used as an expression.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeCantUsePrefixWithNullAware =
    messageCantUsePrefixWithNullAware;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCantUsePrefixWithNullAware = const MessageCode(
    "CantUsePrefixWithNullAware",
    analyzerCodes: <String>["PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT"],
    message: r"""A prefix can't be used with null-aware operators.""",
    tip: r"""Try replacing '?.' with '.'""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeCatchSyntax = messageCatchSyntax;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCatchSyntax = const MessageCode("CatchSyntax",
    index: 84,
    message:
        r"""'catch' must be followed by '(identifier)' or '(identifier, identifier)'.""",
    tip:
        r"""No types are needed, the first is given by 'on', the second is always 'StackTrace'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeCatchSyntaxExtraParameters =
    messageCatchSyntaxExtraParameters;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCatchSyntaxExtraParameters = const MessageCode(
    "CatchSyntaxExtraParameters",
    index: 83,
    message:
        r"""'catch' must be followed by '(identifier)' or '(identifier, identifier)'.""",
    tip:
        r"""No types are needed, the first is given by 'on', the second is always 'StackTrace'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeClassInClass = messageClassInClass;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageClassInClass = const MessageCode("ClassInClass",
    index: 53,
    message: r"""Classes can't be declared inside other classes.""",
    tip: r"""Try moving the class to the top-level.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeColonInPlaceOfIn = messageColonInPlaceOfIn;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageColonInPlaceOfIn = const MessageCode(
    "ColonInPlaceOfIn",
    index: 54,
    message: r"""For-in loops use 'in' rather than a colon.""",
    tip: r"""Try replacing the colon with the keyword 'in'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String name,
        String
            name2)> templateCombinedMemberSignatureFailed = const Template<
        Message Function(String name, String name2)>(
    messageTemplate:
        r"""Class '#name' inherits multiple members named '#name2' with incompatible signatures.""",
    tipTemplate: r"""Try adding a declaration of '#name2' to '#name'.""",
    withArguments: _withArgumentsCombinedMemberSignatureFailed);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String name2)>
    codeCombinedMemberSignatureFailed =
    const Code<Message Function(String name, String name2)>(
        "CombinedMemberSignatureFailed", templateCombinedMemberSignatureFailed,
        analyzerCodes: <String>["INCONSISTENT_INHERITANCE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCombinedMemberSignatureFailed(String name, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(codeCombinedMemberSignatureFailed,
      message:
          """Class '${name}' inherits multiple members named '${name2}' with incompatible signatures.""",
      tip: """Try adding a declaration of '${name2}' to '${name}'.""",
      arguments: {'name': name, 'name2': name2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String string,
        String
            string2)> templateConflictingModifiers = const Template<
        Message Function(String string, String string2)>(
    messageTemplate:
        r"""Members can't be declared to be both '#string' and '#string2'.""",
    tipTemplate: r"""Try removing one of the keywords.""",
    withArguments: _withArgumentsConflictingModifiers);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string, String string2)>
    codeConflictingModifiers =
    const Code<Message Function(String string, String string2)>(
        "ConflictingModifiers", templateConflictingModifiers,
        index: 59);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConflictingModifiers(String string, String string2) {
  if (string.isEmpty) throw 'No string provided';
  if (string2.isEmpty) throw 'No string provided';
  return new Message(codeConflictingModifiers,
      message:
          """Members can't be declared to be both '${string}' and '${string2}'.""",
      tip: """Try removing one of the keywords.""",
      arguments: {'string': string, 'string2': string2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateConflictsWithConstructor =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Conflicts with constructor '#name'.""",
        withArguments: _withArgumentsConflictsWithConstructor);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeConflictsWithConstructor =
    const Code<Message Function(String name)>(
        "ConflictsWithConstructor", templateConflictsWithConstructor,
        analyzerCodes: <String>["CONFLICTS_WITH_CONSTRUCTOR"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConflictsWithConstructor(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeConflictsWithConstructor,
      message: """Conflicts with constructor '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateConflictsWithFactory =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Conflicts with factory '#name'.""",
        withArguments: _withArgumentsConflictsWithFactory);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeConflictsWithFactory =
    const Code<Message Function(String name)>(
  "ConflictsWithFactory",
  templateConflictsWithFactory,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConflictsWithFactory(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeConflictsWithFactory,
      message: """Conflicts with factory '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateConflictsWithMember =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Conflicts with member '#name'.""",
        withArguments: _withArgumentsConflictsWithMember);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeConflictsWithMember =
    const Code<Message Function(String name)>(
        "ConflictsWithMember", templateConflictsWithMember,
        analyzerCodes: <String>["CONFLICTS_WITH_MEMBER"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConflictsWithMember(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeConflictsWithMember,
      message: """Conflicts with member '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateConflictsWithSetter =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Conflicts with setter '#name'.""",
        withArguments: _withArgumentsConflictsWithSetter);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeConflictsWithSetter =
    const Code<Message Function(String name)>(
        "ConflictsWithSetter", templateConflictsWithSetter,
        analyzerCodes: <String>["CONFLICTS_WITH_MEMBER"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConflictsWithSetter(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeConflictsWithSetter,
      message: """Conflicts with setter '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateConflictsWithTypeVariable =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Conflicts with type variable '#name'.""",
        withArguments: _withArgumentsConflictsWithTypeVariable);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeConflictsWithTypeVariable =
    const Code<Message Function(String name)>(
        "ConflictsWithTypeVariable", templateConflictsWithTypeVariable,
        analyzerCodes: <String>["CONFLICTING_TYPE_VARIABLE_AND_MEMBER"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConflictsWithTypeVariable(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeConflictsWithTypeVariable,
      message: """Conflicts with type variable '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConflictsWithTypeVariableCause =
    messageConflictsWithTypeVariableCause;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConflictsWithTypeVariableCause = const MessageCode(
    "ConflictsWithTypeVariableCause",
    severity: Severity.context,
    message: r"""This is the type variable.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstAndFinal = messageConstAndFinal;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstAndFinal = const MessageCode("ConstAndFinal",
    index: 58,
    message: r"""Members can't be declared to be both 'const' and 'final'.""",
    tip: r"""Try removing either the 'const' or 'final' keyword.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstClass = messageConstClass;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstClass = const MessageCode("ConstClass",
    index: 60,
    message: r"""Classes can't be declared to be 'const'.""",
    tip:
        r"""Try removing the 'const' keyword. If you're trying to indicate that instances of the class can be constants, place the 'const' keyword on  the class' constructor(s).""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstConstructorLateFinalFieldCause =
    messageConstConstructorLateFinalFieldCause;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstConstructorLateFinalFieldCause =
    const MessageCode("ConstConstructorLateFinalFieldCause",
        severity: Severity.context,
        message: r"""Field is late, but constructor is 'const'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstConstructorLateFinalFieldError =
    messageConstConstructorLateFinalFieldError;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstConstructorLateFinalFieldError =
    const MessageCode("ConstConstructorLateFinalFieldError",
        message: r"""Constructor is marked 'const' so fields can't be late.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstConstructorNonFinalField =
    messageConstConstructorNonFinalField;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstConstructorNonFinalField = const MessageCode(
    "ConstConstructorNonFinalField",
    analyzerCodes: <String>["CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD"],
    message: r"""Constructor is marked 'const' so all fields must be final.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstConstructorNonFinalFieldCause =
    messageConstConstructorNonFinalFieldCause;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstConstructorNonFinalFieldCause = const MessageCode(
    "ConstConstructorNonFinalFieldCause",
    severity: Severity.context,
    message: r"""Field isn't final, but constructor is 'const'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstConstructorRedirectionToNonConst =
    messageConstConstructorRedirectionToNonConst;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstConstructorRedirectionToNonConst =
    const MessageCode("ConstConstructorRedirectionToNonConst",
        message:
            r"""A constant constructor can't call a non-constant constructor.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstConstructorWithBody = messageConstConstructorWithBody;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstConstructorWithBody = const MessageCode(
    "ConstConstructorWithBody",
    analyzerCodes: <String>["CONST_CONSTRUCTOR_WITH_BODY"],
    message: r"""A const constructor can't have a body.""",
    tip: r"""Try removing either the 'const' keyword or the body.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstConstructorWithNonConstSuper =
    messageConstConstructorWithNonConstSuper;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstConstructorWithNonConstSuper = const MessageCode(
    "ConstConstructorWithNonConstSuper",
    analyzerCodes: <String>["CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER"],
    message:
        r"""A constant constructor can't call a non-constant super constructor.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstEvalCircularity = messageConstEvalCircularity;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstEvalCircularity = const MessageCode(
    "ConstEvalCircularity",
    analyzerCodes: <String>["RECURSIVE_COMPILE_TIME_CONSTANT"],
    message: r"""Constant expression depends on itself.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstEvalContext = messageConstEvalContext;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstEvalContext =
    const MessageCode("ConstEvalContext", message: r"""While analyzing:""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            name)> templateConstEvalDeferredLibrary = const Template<
        Message Function(String name)>(
    messageTemplate:
        r"""'#name' can't be used in a constant expression because it's marked as 'deferred' which means it isn't available until loaded.""",
    tipTemplate:
        r"""Try moving the constant from the deferred library, or removing 'deferred' from the import.
""",
    withArguments: _withArgumentsConstEvalDeferredLibrary);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeConstEvalDeferredLibrary =
    const Code<Message Function(String name)>(
        "ConstEvalDeferredLibrary", templateConstEvalDeferredLibrary,
        analyzerCodes: <String>[
      "NON_CONSTANT_DEFAULT_VALUE_FROM_DEFERRED_LIBRARY"
    ]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalDeferredLibrary(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeConstEvalDeferredLibrary,
      message:
          """'${name}' can't be used in a constant expression because it's marked as 'deferred' which means it isn't available until loaded.""",
      tip: """Try moving the constant from the deferred library, or removing 'deferred' from the import.
""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstEvalExtension = messageConstEvalExtension;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstEvalExtension = const MessageCode(
    "ConstEvalExtension",
    analyzerCodes: <String>["NOT_CONSTANT_EXPRESSION"],
    message:
        r"""Extension operations can't be used in constant expressions.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstEvalFailedAssertion = messageConstEvalFailedAssertion;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstEvalFailedAssertion = const MessageCode(
    "ConstEvalFailedAssertion",
    analyzerCodes: <String>["CONST_EVAL_THROWS_EXCEPTION"],
    message: r"""This assertion failed.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)>
    templateConstEvalFailedAssertionWithMessage =
    const Template<Message Function(String string)>(
        messageTemplate: r"""This assertion failed with message: #string""",
        withArguments: _withArgumentsConstEvalFailedAssertionWithMessage);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string)>
    codeConstEvalFailedAssertionWithMessage =
    const Code<Message Function(String string)>(
        "ConstEvalFailedAssertionWithMessage",
        templateConstEvalFailedAssertionWithMessage,
        analyzerCodes: <String>["CONST_EVAL_THROWS_EXCEPTION"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalFailedAssertionWithMessage(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeConstEvalFailedAssertionWithMessage,
      message: """This assertion failed with message: ${string}""",
      arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            name)> templateConstEvalInvalidStaticInvocation = const Template<
        Message Function(String name)>(
    messageTemplate:
        r"""The invocation of '#name' is not allowed in a constant expression.""",
    withArguments: _withArgumentsConstEvalInvalidStaticInvocation);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeConstEvalInvalidStaticInvocation =
    const Code<Message Function(String name)>(
        "ConstEvalInvalidStaticInvocation",
        templateConstEvalInvalidStaticInvocation,
        analyzerCodes: <String>["CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalInvalidStaticInvocation(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeConstEvalInvalidStaticInvocation,
      message:
          """The invocation of '${name}' is not allowed in a constant expression.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String string,
        String string2,
        String
            string3)> templateConstEvalNegativeShift = const Template<
        Message Function(String string, String string2, String string3)>(
    messageTemplate:
        r"""Binary operator '#string' on '#string2' requires non-negative operand, but was '#string3'.""",
    withArguments: _withArgumentsConstEvalNegativeShift);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string, String string2, String string3)>
    codeConstEvalNegativeShift =
    const Code<Message Function(String string, String string2, String string3)>(
  "ConstEvalNegativeShift",
  templateConstEvalNegativeShift,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalNegativeShift(
    String string, String string2, String string3) {
  if (string.isEmpty) throw 'No string provided';
  if (string2.isEmpty) throw 'No string provided';
  if (string3.isEmpty) throw 'No string provided';
  return new Message(codeConstEvalNegativeShift,
      message:
          """Binary operator '${string}' on '${string2}' requires non-negative operand, but was '${string3}'.""",
      arguments: {'string': string, 'string2': string2, 'string3': string3});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            string)> templateConstEvalNonConstantVariableGet = const Template<
        Message Function(String string)>(
    messageTemplate:
        r"""The variable '#string' is not a constant, only constant expressions are allowed.""",
    withArguments: _withArgumentsConstEvalNonConstantVariableGet);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string)>
    codeConstEvalNonConstantVariableGet =
    const Code<Message Function(String string)>(
        "ConstEvalNonConstantVariableGet",
        templateConstEvalNonConstantVariableGet,
        analyzerCodes: <String>["NON_CONSTANT_VALUE_IN_INITIALIZER"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalNonConstantVariableGet(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeConstEvalNonConstantVariableGet,
      message:
          """The variable '${string}' is not a constant, only constant expressions are allowed.""",
      arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstEvalNotListOrSetInSpread =
    messageConstEvalNotListOrSetInSpread;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstEvalNotListOrSetInSpread = const MessageCode(
    "ConstEvalNotListOrSetInSpread",
    analyzerCodes: <String>["CONST_SPREAD_EXPECTED_LIST_OR_SET"],
    message:
        r"""Only lists and sets can be used in spreads in constant lists and sets.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstEvalNotMapInSpread = messageConstEvalNotMapInSpread;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstEvalNotMapInSpread = const MessageCode(
    "ConstEvalNotMapInSpread",
    analyzerCodes: <String>["CONST_SPREAD_EXPECTED_MAP"],
    message: r"""Only maps can be used in spreads in constant maps.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstEvalNullValue = messageConstEvalNullValue;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstEvalNullValue = const MessageCode(
    "ConstEvalNullValue",
    analyzerCodes: <String>["CONST_EVAL_THROWS_EXCEPTION"],
    message: r"""Null value during constant evaluation.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstEvalStartingPoint = messageConstEvalStartingPoint;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstEvalStartingPoint = const MessageCode(
    "ConstEvalStartingPoint",
    message: r"""Constant evaluation error:""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String string,
        String
            string2)> templateConstEvalTruncateError = const Template<
        Message Function(String string, String string2)>(
    messageTemplate:
        r"""Binary operator '#string ~/ #string2' results is Infinity or NaN.""",
    withArguments: _withArgumentsConstEvalTruncateError);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string, String string2)>
    codeConstEvalTruncateError =
    const Code<Message Function(String string, String string2)>(
  "ConstEvalTruncateError",
  templateConstEvalTruncateError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalTruncateError(String string, String string2) {
  if (string.isEmpty) throw 'No string provided';
  if (string2.isEmpty) throw 'No string provided';
  return new Message(codeConstEvalTruncateError,
      message:
          """Binary operator '${string} ~/ ${string2}' results is Infinity or NaN.""",
      arguments: {'string': string, 'string2': string2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstEvalUnevaluated = messageConstEvalUnevaluated;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstEvalUnevaluated = const MessageCode(
    "ConstEvalUnevaluated",
    message: r"""Could not evaluate constant expression.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String string,
        String
            string2)> templateConstEvalZeroDivisor = const Template<
        Message Function(String string, String string2)>(
    messageTemplate:
        r"""Binary operator '#string' on '#string2' requires non-zero divisor, but divisor was '0'.""",
    withArguments: _withArgumentsConstEvalZeroDivisor);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string, String string2)>
    codeConstEvalZeroDivisor =
    const Code<Message Function(String string, String string2)>(
        "ConstEvalZeroDivisor", templateConstEvalZeroDivisor,
        analyzerCodes: <String>["CONST_EVAL_THROWS_IDBZE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalZeroDivisor(String string, String string2) {
  if (string.isEmpty) throw 'No string provided';
  if (string2.isEmpty) throw 'No string provided';
  return new Message(codeConstEvalZeroDivisor,
      message:
          """Binary operator '${string}' on '${string2}' requires non-zero divisor, but divisor was '0'.""",
      arguments: {'string': string, 'string2': string2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstFactory = messageConstFactory;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstFactory = const MessageCode("ConstFactory",
    index: 62,
    message:
        r"""Only redirecting factory constructors can be declared to be 'const'.""",
    tip:
        r"""Try removing the 'const' keyword, or replacing the body with '=' followed by a valid target.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstFactoryRedirectionToNonConst =
    messageConstFactoryRedirectionToNonConst;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstFactoryRedirectionToNonConst = const MessageCode(
    "ConstFactoryRedirectionToNonConst",
    analyzerCodes: <String>["REDIRECT_TO_NON_CONST_CONSTRUCTOR"],
    message:
        r"""Constant factory constructor can't delegate to a non-constant constructor.""",
    tip:
        r"""Try redirecting to a different constructor or marking the target constructor 'const'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            name)> templateConstFieldWithoutInitializer = const Template<
        Message Function(String name)>(
    messageTemplate: r"""The const variable '#name' must be initialized.""",
    tipTemplate:
        r"""Try adding an initializer ('= expression') to the declaration.""",
    withArguments: _withArgumentsConstFieldWithoutInitializer);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeConstFieldWithoutInitializer =
    const Code<Message Function(String name)>(
        "ConstFieldWithoutInitializer", templateConstFieldWithoutInitializer,
        analyzerCodes: <String>["CONST_NOT_INITIALIZED"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstFieldWithoutInitializer(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeConstFieldWithoutInitializer,
      message: """The const variable '${name}' must be initialized.""",
      tip: """Try adding an initializer ('= expression') to the declaration.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstInstanceField = messageConstInstanceField;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstInstanceField = const MessageCode(
    "ConstInstanceField",
    analyzerCodes: <String>["CONST_INSTANCE_FIELD"],
    message: r"""Only static fields can be declared as const.""",
    tip:
        r"""Try using 'final' instead of 'const', or adding the keyword 'static'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstMethod = messageConstMethod;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstMethod = const MessageCode("ConstMethod",
    index: 63,
    message:
        r"""Getters, setters and methods can't be declared to be 'const'.""",
    tip: r"""Try removing the 'const' keyword.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstructorCyclic = messageConstructorCyclic;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstructorCyclic = const MessageCode(
    "ConstructorCyclic",
    analyzerCodes: <String>["RECURSIVE_CONSTRUCTOR_REDIRECT"],
    message: r"""Redirecting constructors can't be cyclic.""",
    tip:
        r"""Try to have all constructors eventually redirect to a non-redirecting constructor.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateConstructorNotFound =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Couldn't find constructor '#name'.""",
        withArguments: _withArgumentsConstructorNotFound);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeConstructorNotFound =
    const Code<Message Function(String name)>(
        "ConstructorNotFound", templateConstructorNotFound,
        analyzerCodes: <String>["CONSTRUCTOR_NOT_FOUND"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstructorNotFound(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeConstructorNotFound,
      message: """Couldn't find constructor '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstructorNotSync = messageConstructorNotSync;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstructorNotSync = const MessageCode(
    "ConstructorNotSync",
    analyzerCodes: <String>["NON_SYNC_CONSTRUCTOR"],
    message:
        r"""Constructor bodies can't use 'async', 'async*', or 'sync*'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstructorWithReturnType =
    messageConstructorWithReturnType;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstructorWithReturnType = const MessageCode(
    "ConstructorWithReturnType",
    index: 55,
    message: r"""Constructors can't have a return type.""",
    tip: r"""Try removing the return type.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstructorWithTypeArguments =
    messageConstructorWithTypeArguments;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstructorWithTypeArguments = const MessageCode(
    "ConstructorWithTypeArguments",
    analyzerCodes: <String>["WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR"],
    message:
        r"""A constructor invocation can't have type arguments on the constructor name.""",
    tip: r"""Try to place the type arguments on the class name.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstructorWithTypeParameters =
    messageConstructorWithTypeParameters;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstructorWithTypeParameters = const MessageCode(
    "ConstructorWithTypeParameters",
    index: 99,
    message: r"""Constructors can't have type parameters.""",
    tip: r"""Try removing the type parameters.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstructorWithWrongName = messageConstructorWithWrongName;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstructorWithWrongName = const MessageCode(
    "ConstructorWithWrongName",
    index: 102,
    message:
        r"""The name of a constructor must match the name of the enclosing class.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateConstructorWithWrongNameContext =
    const Template<Message Function(String name)>(
        messageTemplate: r"""The name of the enclosing class is '#name'.""",
        withArguments: _withArgumentsConstructorWithWrongNameContext);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeConstructorWithWrongNameContext =
    const Code<Message Function(String name)>("ConstructorWithWrongNameContext",
        templateConstructorWithWrongNameContext,
        severity: Severity.context);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstructorWithWrongNameContext(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeConstructorWithWrongNameContext,
      message: """The name of the enclosing class is '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeContinueLabelNotTarget = messageContinueLabelNotTarget;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageContinueLabelNotTarget = const MessageCode(
    "ContinueLabelNotTarget",
    analyzerCodes: <String>["LABEL_UNDEFINED"],
    message: r"""Target of continue must be a label.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeContinueOutsideOfLoop = messageContinueOutsideOfLoop;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageContinueOutsideOfLoop = const MessageCode(
    "ContinueOutsideOfLoop",
    index: 2,
    message:
        r"""A continue statement can't be used outside of a loop or switch statement.""",
    tip: r"""Try removing the continue statement.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateContinueTargetOutsideFunction =
    const Template<Message Function(String name)>(
        messageTemplate:
            r"""Can't continue at '#name' in a different function.""",
        withArguments: _withArgumentsContinueTargetOutsideFunction);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeContinueTargetOutsideFunction =
    const Code<Message Function(String name)>(
        "ContinueTargetOutsideFunction", templateContinueTargetOutsideFunction,
        analyzerCodes: <String>["LABEL_IN_OUTER_SCOPE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsContinueTargetOutsideFunction(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeContinueTargetOutsideFunction,
      message: """Can't continue at '${name}' in a different function.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeContinueWithoutLabelInCase =
    messageContinueWithoutLabelInCase;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageContinueWithoutLabelInCase = const MessageCode(
    "ContinueWithoutLabelInCase",
    index: 64,
    message:
        r"""A continue statement in a switch statement must have a label as a target.""",
    tip:
        r"""Try adding a label associated with one of the case clauses to the continue statement.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string, String string2)>
    templateCouldNotParseUri =
    const Template<Message Function(String string, String string2)>(
        messageTemplate: r"""Couldn't parse URI '#string':
  #string2.""", withArguments: _withArgumentsCouldNotParseUri);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string, String string2)>
    codeCouldNotParseUri =
    const Code<Message Function(String string, String string2)>(
  "CouldNotParseUri",
  templateCouldNotParseUri,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCouldNotParseUri(String string, String string2) {
  if (string.isEmpty) throw 'No string provided';
  if (string2.isEmpty) throw 'No string provided';
  return new Message(codeCouldNotParseUri,
      message: """Couldn't parse URI '${string}':
  ${string2}.""", arguments: {'string': string, 'string2': string2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeCovariantAndStatic = messageCovariantAndStatic;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCovariantAndStatic = const MessageCode(
    "CovariantAndStatic",
    index: 66,
    message:
        r"""Members can't be declared to be both 'covariant' and 'static'.""",
    tip: r"""Try removing either the 'covariant' or 'static' keyword.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeCovariantMember = messageCovariantMember;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCovariantMember = const MessageCode("CovariantMember",
    index: 67,
    message:
        r"""Getters, setters and methods can't be declared to be 'covariant'.""",
    tip: r"""Try removing the 'covariant' keyword.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String name,
        String
            string)> templateCycleInTypeVariables = const Template<
        Message Function(String name, String string)>(
    messageTemplate: r"""Type '#name' is a bound of itself via '#string'.""",
    tipTemplate:
        r"""Try breaking the cycle by removing at least on of the 'extends' clauses in the cycle.""",
    withArguments: _withArgumentsCycleInTypeVariables);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String string)>
    codeCycleInTypeVariables =
    const Code<Message Function(String name, String string)>(
        "CycleInTypeVariables", templateCycleInTypeVariables,
        analyzerCodes: <String>["TYPE_PARAMETER_SUPERTYPE_OF_ITS_BOUND"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCycleInTypeVariables(String name, String string) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeCycleInTypeVariables,
      message: """Type '${name}' is a bound of itself via '${string}'.""",
      tip:
          """Try breaking the cycle by removing at least on of the 'extends' clauses in the cycle.""",
      arguments: {'name': name, 'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateCyclicClassHierarchy =
    const Template<Message Function(String name)>(
        messageTemplate: r"""'#name' is a supertype of itself.""",
        withArguments: _withArgumentsCyclicClassHierarchy);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeCyclicClassHierarchy =
    const Code<Message Function(String name)>(
        "CyclicClassHierarchy", templateCyclicClassHierarchy,
        analyzerCodes: <String>["RECURSIVE_INTERFACE_INHERITANCE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCyclicClassHierarchy(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeCyclicClassHierarchy,
      message: """'${name}' is a supertype of itself.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateCyclicRedirectingFactoryConstructors =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Cyclic definition of factory '#name'.""",
        withArguments: _withArgumentsCyclicRedirectingFactoryConstructors);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)>
    codeCyclicRedirectingFactoryConstructors =
    const Code<Message Function(String name)>(
        "CyclicRedirectingFactoryConstructors",
        templateCyclicRedirectingFactoryConstructors,
        analyzerCodes: <String>["RECURSIVE_FACTORY_REDIRECT"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCyclicRedirectingFactoryConstructors(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeCyclicRedirectingFactoryConstructors,
      message: """Cyclic definition of factory '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateCyclicTypedef =
    const Template<Message Function(String name)>(
        messageTemplate: r"""The typedef '#name' has a reference to itself.""",
        withArguments: _withArgumentsCyclicTypedef);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeCyclicTypedef =
    const Code<Message Function(String name)>(
        "CyclicTypedef", templateCyclicTypedef,
        analyzerCodes: <String>["TYPE_ALIAS_CANNOT_REFERENCE_ITSELF"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCyclicTypedef(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeCyclicTypedef,
      message: """The typedef '${name}' has a reference to itself.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String string)>
    templateDebugTrace =
    const Template<Message Function(String name, String string)>(
        messageTemplate: r"""Fatal '#name' at:
#string""", withArguments: _withArgumentsDebugTrace);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String string)> codeDebugTrace =
    const Code<Message Function(String name, String string)>(
        "DebugTrace", templateDebugTrace,
        severity: Severity.ignored);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDebugTrace(String name, String string) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeDebugTrace, message: """Fatal '${name}' at:
${string}""", arguments: {'name': name, 'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeDeclaredMemberConflictsWithInheritedMember =
    messageDeclaredMemberConflictsWithInheritedMember;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageDeclaredMemberConflictsWithInheritedMember =
    const MessageCode("DeclaredMemberConflictsWithInheritedMember",
        analyzerCodes: <String>["DECLARED_MEMBER_CONFLICTS_WITH_INHERITED"],
        message:
            r"""Can't declare a member that conflicts with an inherited one.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeDeclaredMemberConflictsWithInheritedMemberCause =
    messageDeclaredMemberConflictsWithInheritedMemberCause;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageDeclaredMemberConflictsWithInheritedMemberCause =
    const MessageCode("DeclaredMemberConflictsWithInheritedMemberCause",
        severity: Severity.context,
        message: r"""This is the inherited member.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeDeclaredMemberConflictsWithInheritedMembersCause =
    messageDeclaredMemberConflictsWithInheritedMembersCause;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageDeclaredMemberConflictsWithInheritedMembersCause =
    const MessageCode("DeclaredMemberConflictsWithInheritedMembersCause",
        severity: Severity.context,
        message: r"""This is one of the inherited members.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeDefaultListConstructorError =
    messageDefaultListConstructorError;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageDefaultListConstructorError = const MessageCode(
    "DefaultListConstructorError",
    message: r"""Can't use the default List constructor.""",
    tip: r"""Try using List.filled instead.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateDefaultValueInRedirectingFactoryConstructor =
    const Template<Message Function(String name)>(
        messageTemplate:
            r"""Can't have a default value here because any default values of '#name' would be used instead.""",
        tipTemplate: r"""Try removing the default value.""",
        withArguments:
            _withArgumentsDefaultValueInRedirectingFactoryConstructor);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)>
    codeDefaultValueInRedirectingFactoryConstructor =
    const Code<Message Function(String name)>(
        "DefaultValueInRedirectingFactoryConstructor",
        templateDefaultValueInRedirectingFactoryConstructor,
        analyzerCodes: <String>[
      "DEFAULT_VALUE_IN_REDIRECTING_FACTORY_CONSTRUCTOR"
    ]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDefaultValueInRedirectingFactoryConstructor(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeDefaultValueInRedirectingFactoryConstructor,
      message:
          """Can't have a default value here because any default values of '${name}' would be used instead.""",
      tip: """Try removing the default value.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeDeferredAfterPrefix = messageDeferredAfterPrefix;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageDeferredAfterPrefix = const MessageCode(
    "DeferredAfterPrefix",
    index: 68,
    message:
        r"""The deferred keyword should come immediately before the prefix ('as' clause).""",
    tip: r"""Try moving the deferred keyword before the prefix.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            name)> templateDeferredExtensionImport = const Template<
        Message Function(String name)>(
    messageTemplate:
        r"""Extension '#name' cannot be imported through a deferred import.""",
    tipTemplate: r"""Try adding the `hide #name` to the import.""",
    withArguments: _withArgumentsDeferredExtensionImport);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeDeferredExtensionImport =
    const Code<Message Function(String name)>(
  "DeferredExtensionImport",
  templateDeferredExtensionImport,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDeferredExtensionImport(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeDeferredExtensionImport,
      message:
          """Extension '${name}' cannot be imported through a deferred import.""",
      tip: """Try adding the `hide ${name}` to the import.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            name)> templateDeferredPrefixDuplicated = const Template<
        Message Function(String name)>(
    messageTemplate:
        r"""Can't use the name '#name' for a deferred library, as the name is used elsewhere.""",
    withArguments: _withArgumentsDeferredPrefixDuplicated);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeDeferredPrefixDuplicated =
    const Code<Message Function(String name)>(
        "DeferredPrefixDuplicated", templateDeferredPrefixDuplicated,
        analyzerCodes: <String>["SHARED_DEFERRED_PREFIX"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDeferredPrefixDuplicated(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeDeferredPrefixDuplicated,
      message:
          """Can't use the name '${name}' for a deferred library, as the name is used elsewhere.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateDeferredPrefixDuplicatedCause =
    const Template<Message Function(String name)>(
        messageTemplate: r"""'#name' is used here.""",
        withArguments: _withArgumentsDeferredPrefixDuplicatedCause);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeDeferredPrefixDuplicatedCause =
    const Code<Message Function(String name)>(
        "DeferredPrefixDuplicatedCause", templateDeferredPrefixDuplicatedCause,
        severity: Severity.context);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDeferredPrefixDuplicatedCause(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeDeferredPrefixDuplicatedCause,
      message: """'${name}' is used here.""", arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(
            int count, int count2, num _num1, num _num2, num _num3)>
    templateDillOutlineSummary = const Template<
            Message Function(
                int count, int count2, num _num1, num _num2, num _num3)>(
        messageTemplate:
            r"""Indexed #count libraries (#count2 bytes) in #num1%.3ms, that is,
#num2%12.3 bytes/ms, and
#num3%12.3 ms/libraries.""",
        withArguments: _withArgumentsDillOutlineSummary);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
    Message Function(int count, int count2, num _num1, num _num2,
        num _num3)> codeDillOutlineSummary = const Code<
    Message Function(int count, int count2, num _num1, num _num2, num _num3)>(
  "DillOutlineSummary",
  templateDillOutlineSummary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDillOutlineSummary(
    int count, int count2, num _num1, num _num2, num _num3) {
  if (count == null) throw 'No count provided';
  if (count2 == null) throw 'No count provided';
  if (_num1 == null) throw 'No number provided';
  String num1 = _num1.toStringAsFixed(3);
  if (_num2 == null) throw 'No number provided';
  String num2 = _num2.toStringAsFixed(3).padLeft(12);
  if (_num3 == null) throw 'No number provided';
  String num3 = _num3.toStringAsFixed(3).padLeft(12);
  return new Message(codeDillOutlineSummary,
      message:
          """Indexed ${count} libraries (${count2} bytes) in ${num1}ms, that is,
${num2} bytes/ms, and
${num3} ms/libraries.""",
      arguments: {
        'count': count,
        'count2': count2,
        'num1': _num1,
        'num2': _num2,
        'num3': _num3
      });
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            name)> templateDirectCycleInTypeVariables = const Template<
        Message Function(String name)>(
    messageTemplate: r"""Type '#name' can't use itself as a bound.""",
    tipTemplate:
        r"""Try breaking the cycle by removing at least on of the 'extends' clauses in the cycle.""",
    withArguments: _withArgumentsDirectCycleInTypeVariables);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeDirectCycleInTypeVariables =
    const Code<Message Function(String name)>(
        "DirectCycleInTypeVariables", templateDirectCycleInTypeVariables,
        analyzerCodes: <String>["TYPE_PARAMETER_SUPERTYPE_OF_ITS_BOUND"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDirectCycleInTypeVariables(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeDirectCycleInTypeVariables,
      message: """Type '${name}' can't use itself as a bound.""",
      tip:
          """Try breaking the cycle by removing at least on of the 'extends' clauses in the cycle.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeDirectiveAfterDeclaration =
    messageDirectiveAfterDeclaration;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageDirectiveAfterDeclaration = const MessageCode(
    "DirectiveAfterDeclaration",
    index: 69,
    message: r"""Directives must appear before any declarations.""",
    tip: r"""Try moving the directive before any declarations.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeDuplicateDeferred = messageDuplicateDeferred;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageDuplicateDeferred = const MessageCode(
    "DuplicateDeferred",
    index: 71,
    message: r"""An import directive can only have one 'deferred' keyword.""",
    tip: r"""Try removing all but one 'deferred' keyword.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateDuplicateLabelInSwitchStatement =
    const Template<Message Function(String name)>(
        messageTemplate:
            r"""The label '#name' was already used in this switch statement.""",
        tipTemplate: r"""Try choosing a different name for this label.""",
        withArguments: _withArgumentsDuplicateLabelInSwitchStatement);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeDuplicateLabelInSwitchStatement =
    const Code<Message Function(String name)>("DuplicateLabelInSwitchStatement",
        templateDuplicateLabelInSwitchStatement,
        index: 72);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicateLabelInSwitchStatement(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeDuplicateLabelInSwitchStatement,
      message:
          """The label '${name}' was already used in this switch statement.""",
      tip: """Try choosing a different name for this label.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeDuplicatePrefix = messageDuplicatePrefix;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageDuplicatePrefix = const MessageCode("DuplicatePrefix",
    index: 73,
    message: r"""An import directive can only have one prefix ('as' clause).""",
    tip: r"""Try removing all but one prefix.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateDuplicatedDeclaration =
    const Template<Message Function(String name)>(
        messageTemplate: r"""'#name' is already declared in this scope.""",
        withArguments: _withArgumentsDuplicatedDeclaration);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeDuplicatedDeclaration =
    const Code<Message Function(String name)>(
        "DuplicatedDeclaration", templateDuplicatedDeclaration,
        analyzerCodes: <String>["DUPLICATE_DEFINITION"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedDeclaration(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeDuplicatedDeclaration,
      message: """'${name}' is already declared in this scope.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateDuplicatedDeclarationCause =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Previous declaration of '#name'.""",
        withArguments: _withArgumentsDuplicatedDeclarationCause);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeDuplicatedDeclarationCause =
    const Code<Message Function(String name)>(
        "DuplicatedDeclarationCause", templateDuplicatedDeclarationCause,
        severity: Severity.context);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedDeclarationCause(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeDuplicatedDeclarationCause,
      message: """Previous declaration of '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            name)> templateDuplicatedDeclarationSyntheticCause = const Template<
        Message Function(String name)>(
    messageTemplate:
        r"""Previous declaration of '#name' is implied by this definition.""",
    withArguments: _withArgumentsDuplicatedDeclarationSyntheticCause);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)>
    codeDuplicatedDeclarationSyntheticCause =
    const Code<Message Function(String name)>(
        "DuplicatedDeclarationSyntheticCause",
        templateDuplicatedDeclarationSyntheticCause,
        severity: Severity.context);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedDeclarationSyntheticCause(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeDuplicatedDeclarationSyntheticCause,
      message:
          """Previous declaration of '${name}' is implied by this definition.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateDuplicatedDeclarationUse =
    const Template<Message Function(String name)>(
        messageTemplate:
            r"""Can't use '#name' because it is declared more than once.""",
        withArguments: _withArgumentsDuplicatedDeclarationUse);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeDuplicatedDeclarationUse =
    const Code<Message Function(String name)>(
  "DuplicatedDeclarationUse",
  templateDuplicatedDeclarationUse,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedDeclarationUse(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeDuplicatedDeclarationUse,
      message: """Can't use '${name}' because it is declared more than once.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, Uri uri_, Uri uri2_)>
    templateDuplicatedExport =
    const Template<Message Function(String name, Uri uri_, Uri uri2_)>(
        messageTemplate:
            r"""'#name' is exported from both '#uri' and '#uri2'.""",
        withArguments: _withArgumentsDuplicatedExport);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, Uri uri_, Uri uri2_)>
    codeDuplicatedExport =
    const Code<Message Function(String name, Uri uri_, Uri uri2_)>(
        "DuplicatedExport", templateDuplicatedExport,
        analyzerCodes: <String>["AMBIGUOUS_EXPORT"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedExport(String name, Uri uri_, Uri uri2_) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  String uri = relativizeUri(uri_);
  String uri2 = relativizeUri(uri2_);
  return new Message(codeDuplicatedExport,
      message: """'${name}' is exported from both '${uri}' and '${uri2}'.""",
      arguments: {'name': name, 'uri': uri_, 'uri2': uri2_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, Uri uri_, Uri uri2_)>
    templateDuplicatedExportInType =
    const Template<Message Function(String name, Uri uri_, Uri uri2_)>(
        messageTemplate:
            r"""'#name' is exported from both '#uri' and '#uri2'.""",
        withArguments: _withArgumentsDuplicatedExportInType);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, Uri uri_, Uri uri2_)>
    codeDuplicatedExportInType =
    const Code<Message Function(String name, Uri uri_, Uri uri2_)>(
  "DuplicatedExportInType",
  templateDuplicatedExportInType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedExportInType(String name, Uri uri_, Uri uri2_) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  String uri = relativizeUri(uri_);
  String uri2 = relativizeUri(uri2_);
  return new Message(codeDuplicatedExportInType,
      message: """'${name}' is exported from both '${uri}' and '${uri2}'.""",
      arguments: {'name': name, 'uri': uri_, 'uri2': uri2_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, Uri uri_, Uri uri2_)>
    templateDuplicatedImport =
    const Template<Message Function(String name, Uri uri_, Uri uri2_)>(
        messageTemplate:
            r"""'#name' is imported from both '#uri' and '#uri2'.""",
        withArguments: _withArgumentsDuplicatedImport);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, Uri uri_, Uri uri2_)>
    codeDuplicatedImport =
    const Code<Message Function(String name, Uri uri_, Uri uri2_)>(
        "DuplicatedImport", templateDuplicatedImport,
        severity: Severity.ignored);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedImport(String name, Uri uri_, Uri uri2_) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  String uri = relativizeUri(uri_);
  String uri2 = relativizeUri(uri2_);
  return new Message(codeDuplicatedImport,
      message: """'${name}' is imported from both '${uri}' and '${uri2}'.""",
      arguments: {'name': name, 'uri': uri_, 'uri2': uri2_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, Uri uri_, Uri uri2_)>
    templateDuplicatedImportInType =
    const Template<Message Function(String name, Uri uri_, Uri uri2_)>(
        messageTemplate:
            r"""'#name' is imported from both '#uri' and '#uri2'.""",
        withArguments: _withArgumentsDuplicatedImportInType);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, Uri uri_, Uri uri2_)>
    codeDuplicatedImportInType =
    const Code<Message Function(String name, Uri uri_, Uri uri2_)>(
        "DuplicatedImportInType", templateDuplicatedImportInType,
        analyzerCodes: <String>["AMBIGUOUS_IMPORT"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedImportInType(String name, Uri uri_, Uri uri2_) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  String uri = relativizeUri(uri_);
  String uri2 = relativizeUri(uri2_);
  return new Message(codeDuplicatedImportInType,
      message: """'${name}' is imported from both '${uri}' and '${uri2}'.""",
      arguments: {'name': name, 'uri': uri_, 'uri2': uri2_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateDuplicatedLibraryExport =
    const Template<Message Function(String name)>(
        messageTemplate:
            r"""A library with name '#name' is exported more than once.""",
        withArguments: _withArgumentsDuplicatedLibraryExport);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeDuplicatedLibraryExport =
    const Code<Message Function(String name)>(
        "DuplicatedLibraryExport", templateDuplicatedLibraryExport,
        analyzerCodes: <String>["EXPORT_DUPLICATED_LIBRARY_NAMED"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedLibraryExport(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeDuplicatedLibraryExport,
      message: """A library with name '${name}' is exported more than once.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateDuplicatedLibraryExportContext =
    const Template<Message Function(String name)>(
        messageTemplate: r"""'#name' is also exported here.""",
        withArguments: _withArgumentsDuplicatedLibraryExportContext);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeDuplicatedLibraryExportContext =
    const Code<Message Function(String name)>("DuplicatedLibraryExportContext",
        templateDuplicatedLibraryExportContext,
        severity: Severity.context);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedLibraryExportContext(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeDuplicatedLibraryExportContext,
      message: """'${name}' is also exported here.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateDuplicatedLibraryImport =
    const Template<Message Function(String name)>(
        messageTemplate:
            r"""A library with name '#name' is imported more than once.""",
        withArguments: _withArgumentsDuplicatedLibraryImport);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeDuplicatedLibraryImport =
    const Code<Message Function(String name)>(
        "DuplicatedLibraryImport", templateDuplicatedLibraryImport,
        analyzerCodes: <String>["IMPORT_DUPLICATED_LIBRARY_NAMED"],
        severity: Severity.warning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedLibraryImport(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeDuplicatedLibraryImport,
      message: """A library with name '${name}' is imported more than once.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateDuplicatedLibraryImportContext =
    const Template<Message Function(String name)>(
        messageTemplate: r"""'#name' is also imported here.""",
        withArguments: _withArgumentsDuplicatedLibraryImportContext);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeDuplicatedLibraryImportContext =
    const Code<Message Function(String name)>("DuplicatedLibraryImportContext",
        templateDuplicatedLibraryImportContext,
        severity: Severity.context);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedLibraryImportContext(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeDuplicatedLibraryImportContext,
      message: """'${name}' is also imported here.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateDuplicatedModifier =
    const Template<Message Function(Token token)>(
        messageTemplate: r"""The modifier '#lexeme' was already specified.""",
        tipTemplate:
            r"""Try removing all but one occurrence of the modifier.""",
        withArguments: _withArgumentsDuplicatedModifier);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeDuplicatedModifier =
    const Code<Message Function(Token token)>(
        "DuplicatedModifier", templateDuplicatedModifier,
        index: 70);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedModifier(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeDuplicatedModifier,
      message: """The modifier '${lexeme}' was already specified.""",
      tip: """Try removing all but one occurrence of the modifier.""",
      arguments: {'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            name)> templateDuplicatedNamePreviouslyUsed = const Template<
        Message Function(String name)>(
    messageTemplate:
        r"""Can't declare '#name' because it was already used in this scope.""",
    withArguments: _withArgumentsDuplicatedNamePreviouslyUsed);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeDuplicatedNamePreviouslyUsed =
    const Code<Message Function(String name)>(
        "DuplicatedNamePreviouslyUsed", templateDuplicatedNamePreviouslyUsed,
        analyzerCodes: <String>["REFERENCED_BEFORE_DECLARATION"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedNamePreviouslyUsed(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeDuplicatedNamePreviouslyUsed,
      message:
          """Can't declare '${name}' because it was already used in this scope.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateDuplicatedNamePreviouslyUsedCause =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Previous use of '#name'.""",
        withArguments: _withArgumentsDuplicatedNamePreviouslyUsedCause);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)>
    codeDuplicatedNamePreviouslyUsedCause =
    const Code<Message Function(String name)>(
        "DuplicatedNamePreviouslyUsedCause",
        templateDuplicatedNamePreviouslyUsedCause,
        severity: Severity.context);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedNamePreviouslyUsedCause(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeDuplicatedNamePreviouslyUsedCause,
      message: """Previous use of '${name}'.""", arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateDuplicatedNamedArgument =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Duplicated named argument '#name'.""",
        withArguments: _withArgumentsDuplicatedNamedArgument);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeDuplicatedNamedArgument =
    const Code<Message Function(String name)>(
        "DuplicatedNamedArgument", templateDuplicatedNamedArgument,
        analyzerCodes: <String>["DUPLICATE_NAMED_ARGUMENT"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedNamedArgument(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeDuplicatedNamedArgument,
      message: """Duplicated named argument '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateDuplicatedParameterName =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Duplicated parameter name '#name'.""",
        withArguments: _withArgumentsDuplicatedParameterName);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeDuplicatedParameterName =
    const Code<Message Function(String name)>(
        "DuplicatedParameterName", templateDuplicatedParameterName,
        analyzerCodes: <String>["DUPLICATE_DEFINITION"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedParameterName(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeDuplicatedParameterName,
      message: """Duplicated parameter name '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateDuplicatedParameterNameCause =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Other parameter named '#name'.""",
        withArguments: _withArgumentsDuplicatedParameterNameCause);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeDuplicatedParameterNameCause =
    const Code<Message Function(String name)>(
        "DuplicatedParameterNameCause", templateDuplicatedParameterNameCause,
        severity: Severity.context);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedParameterNameCause(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeDuplicatedParameterNameCause,
      message: """Other parameter named '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeEmptyNamedParameterList = messageEmptyNamedParameterList;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageEmptyNamedParameterList = const MessageCode(
    "EmptyNamedParameterList",
    analyzerCodes: <String>["MISSING_IDENTIFIER"],
    message: r"""Named parameter lists cannot be empty.""",
    tip: r"""Try adding a named parameter to the list.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeEmptyOptionalParameterList =
    messageEmptyOptionalParameterList;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageEmptyOptionalParameterList = const MessageCode(
    "EmptyOptionalParameterList",
    analyzerCodes: <String>["MISSING_IDENTIFIER"],
    message: r"""Optional parameter lists cannot be empty.""",
    tip: r"""Try adding an optional parameter to the list.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeEncoding = messageEncoding;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageEncoding = const MessageCode("Encoding",
    message: r"""Unable to decode bytes as UTF-8.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            name)> templateEnumConstantSameNameAsEnclosing = const Template<
        Message Function(String name)>(
    messageTemplate:
        r"""Name of enum constant '#name' can't be the same as the enum's own name.""",
    withArguments: _withArgumentsEnumConstantSameNameAsEnclosing);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeEnumConstantSameNameAsEnclosing =
    const Code<Message Function(String name)>("EnumConstantSameNameAsEnclosing",
        templateEnumConstantSameNameAsEnclosing,
        analyzerCodes: <String>["ENUM_CONSTANT_WITH_ENUM_NAME"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsEnumConstantSameNameAsEnclosing(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeEnumConstantSameNameAsEnclosing,
      message:
          """Name of enum constant '${name}' can't be the same as the enum's own name.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeEnumDeclarationEmpty = messageEnumDeclarationEmpty;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageEnumDeclarationEmpty = const MessageCode(
    "EnumDeclarationEmpty",
    analyzerCodes: <String>["EMPTY_ENUM_BODY"],
    message: r"""An enum declaration can't be empty.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeEnumInClass = messageEnumInClass;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageEnumInClass = const MessageCode("EnumInClass",
    index: 74,
    message: r"""Enums can't be declared inside classes.""",
    tip: r"""Try moving the enum to the top-level.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeEnumInstantiation = messageEnumInstantiation;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageEnumInstantiation = const MessageCode(
    "EnumInstantiation",
    analyzerCodes: <String>["INSTANTIATE_ENUM"],
    message: r"""Enums can't be instantiated.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeEqualityCannotBeEqualityOperand =
    messageEqualityCannotBeEqualityOperand;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageEqualityCannotBeEqualityOperand = const MessageCode(
    "EqualityCannotBeEqualityOperand",
    index: 1,
    message:
        r"""A comparison expression can't be an operand of another comparison expression.""",
    tip: r"""Try putting parentheses around one of the comparisons.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)> templateExpectedAfterButGot =
    const Template<Message Function(String string)>(
        messageTemplate: r"""Expected '#string' after this.""",
        withArguments: _withArgumentsExpectedAfterButGot);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string)> codeExpectedAfterButGot =
    const Code<Message Function(String string)>(
        "ExpectedAfterButGot", templateExpectedAfterButGot,
        analyzerCodes: <String>["EXPECTED_TOKEN"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedAfterButGot(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeExpectedAfterButGot,
      message: """Expected '${string}' after this.""",
      arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExpectedAnInitializer = messageExpectedAnInitializer;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedAnInitializer = const MessageCode(
    "ExpectedAnInitializer",
    index: 36,
    message: r"""Expected an initializer.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExpectedBlock = messageExpectedBlock;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedBlock = const MessageCode("ExpectedBlock",
    analyzerCodes: <String>["EXPECTED_TOKEN"],
    message: r"""Expected a block.""",
    tip: r"""Try adding {}.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExpectedBlockToSkip = messageExpectedBlockToSkip;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedBlockToSkip = const MessageCode(
    "ExpectedBlockToSkip",
    analyzerCodes: <String>["MISSING_FUNCTION_BODY"],
    message: r"""Expected a function body or '=>'.""",
    tip: r"""Try adding {}.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExpectedBody = messageExpectedBody;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedBody = const MessageCode("ExpectedBody",
    analyzerCodes: <String>["MISSING_FUNCTION_BODY"],
    message: r"""Expected a function body or '=>'.""",
    tip: r"""Try adding {}.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)> templateExpectedButGot =
    const Template<Message Function(String string)>(
        messageTemplate: r"""Expected '#string' before this.""",
        withArguments: _withArgumentsExpectedButGot);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string)> codeExpectedButGot =
    const Code<Message Function(String string)>(
        "ExpectedButGot", templateExpectedButGot,
        analyzerCodes: <String>["EXPECTED_TOKEN"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedButGot(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeExpectedButGot,
      message: """Expected '${string}' before this.""",
      arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateExpectedClassMember =
    const Template<Message Function(Token token)>(
        messageTemplate: r"""Expected a class member, but got '#lexeme'.""",
        withArguments: _withArgumentsExpectedClassMember);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeExpectedClassMember =
    const Code<Message Function(Token token)>(
        "ExpectedClassMember", templateExpectedClassMember,
        analyzerCodes: <String>["EXPECTED_CLASS_MEMBER"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedClassMember(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeExpectedClassMember,
      message: """Expected a class member, but got '${lexeme}'.""",
      arguments: {'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)>
    templateExpectedClassOrMixinBody =
    const Template<Message Function(String string)>(
        messageTemplate:
            r"""A #string must have a body, even if it is empty.""",
        tipTemplate: r"""Try adding an empty body.""",
        withArguments: _withArgumentsExpectedClassOrMixinBody);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string)> codeExpectedClassOrMixinBody =
    const Code<Message Function(String string)>(
        "ExpectedClassOrMixinBody", templateExpectedClassOrMixinBody,
        index: 8);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedClassOrMixinBody(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeExpectedClassOrMixinBody,
      message: """A ${string} must have a body, even if it is empty.""",
      tip: """Try adding an empty body.""",
      arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateExpectedDeclaration =
    const Template<Message Function(Token token)>(
        messageTemplate: r"""Expected a declaration, but got '#lexeme'.""",
        withArguments: _withArgumentsExpectedDeclaration);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeExpectedDeclaration =
    const Code<Message Function(Token token)>(
        "ExpectedDeclaration", templateExpectedDeclaration,
        analyzerCodes: <String>["EXPECTED_EXECUTABLE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedDeclaration(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeExpectedDeclaration,
      message: """Expected a declaration, but got '${lexeme}'.""",
      arguments: {'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExpectedElseOrComma = messageExpectedElseOrComma;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedElseOrComma = const MessageCode(
    "ExpectedElseOrComma",
    index: 46,
    message: r"""Expected 'else' or comma.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(Token token)> templateExpectedEnumBody = const Template<
        Message Function(Token token)>(
    messageTemplate: r"""Expected a enum body, but got '#lexeme'.""",
    tipTemplate:
        r"""An enum definition must have a body with at least one constant name.""",
    withArguments: _withArgumentsExpectedEnumBody);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeExpectedEnumBody =
    const Code<Message Function(Token token)>(
        "ExpectedEnumBody", templateExpectedEnumBody,
        analyzerCodes: <String>["MISSING_ENUM_BODY"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedEnumBody(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeExpectedEnumBody,
      message: """Expected a enum body, but got '${lexeme}'.""",
      tip:
          """An enum definition must have a body with at least one constant name.""",
      arguments: {'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateExpectedFunctionBody =
    const Template<Message Function(Token token)>(
        messageTemplate: r"""Expected a function body, but got '#lexeme'.""",
        withArguments: _withArgumentsExpectedFunctionBody);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeExpectedFunctionBody =
    const Code<Message Function(Token token)>(
        "ExpectedFunctionBody", templateExpectedFunctionBody,
        analyzerCodes: <String>["MISSING_FUNCTION_BODY"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedFunctionBody(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeExpectedFunctionBody,
      message: """Expected a function body, but got '${lexeme}'.""",
      arguments: {'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExpectedHexDigit = messageExpectedHexDigit;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedHexDigit = const MessageCode(
    "ExpectedHexDigit",
    analyzerCodes: <String>["MISSING_HEX_DIGIT"],
    message: r"""A hex digit (0-9 or A-F) must follow '0x'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateExpectedIdentifier =
    const Template<Message Function(Token token)>(
        messageTemplate: r"""Expected an identifier, but got '#lexeme'.""",
        withArguments: _withArgumentsExpectedIdentifier);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeExpectedIdentifier =
    const Code<Message Function(Token token)>(
        "ExpectedIdentifier", templateExpectedIdentifier,
        analyzerCodes: <String>["MISSING_IDENTIFIER"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedIdentifier(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeExpectedIdentifier,
      message: """Expected an identifier, but got '${lexeme}'.""",
      arguments: {'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)> templateExpectedInstead =
    const Template<Message Function(String string)>(
        messageTemplate: r"""Expected '#string' instead of this.""",
        withArguments: _withArgumentsExpectedInstead);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string)> codeExpectedInstead =
    const Code<Message Function(String string)>(
        "ExpectedInstead", templateExpectedInstead,
        index: 41);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedInstead(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeExpectedInstead,
      message: """Expected '${string}' instead of this.""",
      arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExpectedNamedArgument = messageExpectedNamedArgument;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedNamedArgument = const MessageCode(
    "ExpectedNamedArgument",
    analyzerCodes: <String>["EXTRA_POSITIONAL_ARGUMENTS"],
    message: r"""Expected named argument.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExpectedOneExpression = messageExpectedOneExpression;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedOneExpression = const MessageCode(
    "ExpectedOneExpression",
    message: r"""Expected one expression, but found additional input.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExpectedOpenParens = messageExpectedOpenParens;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedOpenParens =
    const MessageCode("ExpectedOpenParens", message: r"""Expected '('.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExpectedStatement = messageExpectedStatement;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedStatement = const MessageCode(
    "ExpectedStatement",
    index: 29,
    message: r"""Expected a statement.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateExpectedString =
    const Template<Message Function(Token token)>(
        messageTemplate: r"""Expected a String, but got '#lexeme'.""",
        withArguments: _withArgumentsExpectedString);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeExpectedString =
    const Code<Message Function(Token token)>(
        "ExpectedString", templateExpectedString,
        analyzerCodes: <String>["EXPECTED_STRING_LITERAL"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedString(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeExpectedString,
      message: """Expected a String, but got '${lexeme}'.""",
      arguments: {'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)> templateExpectedToken =
    const Template<Message Function(String string)>(
        messageTemplate: r"""Expected to find '#string'.""",
        withArguments: _withArgumentsExpectedToken);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string)> codeExpectedToken =
    const Code<Message Function(String string)>(
        "ExpectedToken", templateExpectedToken,
        analyzerCodes: <String>["EXPECTED_TOKEN"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedToken(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeExpectedToken,
      message: """Expected to find '${string}'.""",
      arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateExpectedType =
    const Template<Message Function(Token token)>(
        messageTemplate: r"""Expected a type, but got '#lexeme'.""",
        withArguments: _withArgumentsExpectedType);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeExpectedType =
    const Code<Message Function(Token token)>(
        "ExpectedType", templateExpectedType,
        analyzerCodes: <String>["EXPECTED_TYPE_NAME"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedType(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeExpectedType,
      message: """Expected a type, but got '${lexeme}'.""",
      arguments: {'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExpectedUri = messageExpectedUri;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedUri =
    const MessageCode("ExpectedUri", message: r"""Expected a URI.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String string,
        String
            string2)> templateExperimentNotEnabled = const Template<
        Message Function(String string, String string2)>(
    messageTemplate:
        r"""This requires the '#string' language feature to be enabled.""",
    tipTemplate:
        r"""Try updating your pubspec.yaml to set the minimum SDK constraint to #string2 or higher, and running 'pub get'.""",
    withArguments: _withArgumentsExperimentNotEnabled);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string, String string2)>
    codeExperimentNotEnabled =
    const Code<Message Function(String string, String string2)>(
        "ExperimentNotEnabled", templateExperimentNotEnabled,
        index: 48);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExperimentNotEnabled(String string, String string2) {
  if (string.isEmpty) throw 'No string provided';
  if (string2.isEmpty) throw 'No string provided';
  return new Message(codeExperimentNotEnabled,
      message:
          """This requires the '${string}' language feature to be enabled.""",
      tip:
          """Try updating your pubspec.yaml to set the minimum SDK constraint to ${string2} or higher, and running 'pub get'.""",
      arguments: {'string': string, 'string2': string2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExplicitExtensionArgumentMismatch =
    messageExplicitExtensionArgumentMismatch;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExplicitExtensionArgumentMismatch = const MessageCode(
    "ExplicitExtensionArgumentMismatch",
    message:
        r"""Explicit extension application requires exactly 1 positional argument.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExplicitExtensionAsExpression =
    messageExplicitExtensionAsExpression;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExplicitExtensionAsExpression = const MessageCode(
    "ExplicitExtensionAsExpression",
    message:
        r"""Explicit extension application cannot be used as an expression.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExplicitExtensionAsLvalue =
    messageExplicitExtensionAsLvalue;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExplicitExtensionAsLvalue = const MessageCode(
    "ExplicitExtensionAsLvalue",
    message:
        r"""Explicit extension application cannot be a target for assignment.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String name,
        int
            count)> templateExplicitExtensionTypeArgumentMismatch = const Template<
        Message Function(String name, int count)>(
    messageTemplate:
        r"""Explicit extension application of extension '#name' takes '#count' type argument(s).""",
    withArguments: _withArgumentsExplicitExtensionTypeArgumentMismatch);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, int count)>
    codeExplicitExtensionTypeArgumentMismatch =
    const Code<Message Function(String name, int count)>(
  "ExplicitExtensionTypeArgumentMismatch",
  templateExplicitExtensionTypeArgumentMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExplicitExtensionTypeArgumentMismatch(
    String name, int count) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (count == null) throw 'No count provided';
  return new Message(codeExplicitExtensionTypeArgumentMismatch,
      message:
          """Explicit extension application of extension '${name}' takes '${count}' type argument(s).""",
      arguments: {'name': name, 'count': count});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExportAfterPart = messageExportAfterPart;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExportAfterPart = const MessageCode("ExportAfterPart",
    index: 75,
    message: r"""Export directives must precede part directives.""",
    tip: r"""Try moving the export directives before the part directives.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, Uri uri_, Uri uri2_)>
    templateExportHidesExport =
    const Template<Message Function(String name, Uri uri_, Uri uri2_)>(
        messageTemplate:
            r"""Export of '#name' (from '#uri') hides export from '#uri2'.""",
        withArguments: _withArgumentsExportHidesExport);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, Uri uri_, Uri uri2_)>
    codeExportHidesExport =
    const Code<Message Function(String name, Uri uri_, Uri uri2_)>(
        "ExportHidesExport", templateExportHidesExport,
        severity: Severity.ignored);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExportHidesExport(String name, Uri uri_, Uri uri2_) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  String uri = relativizeUri(uri_);
  String uri2 = relativizeUri(uri2_);
  return new Message(codeExportHidesExport,
      message:
          """Export of '${name}' (from '${uri}') hides export from '${uri2}'.""",
      arguments: {'name': name, 'uri': uri_, 'uri2': uri2_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExportOptOutFromOptIn = messageExportOptOutFromOptIn;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExportOptOutFromOptIn = const MessageCode(
    "ExportOptOutFromOptIn",
    message:
        r"""Null safe libraries are not allowed to export declarations from of opt-out libraries.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExpressionNotMetadata = messageExpressionNotMetadata;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpressionNotMetadata = const MessageCode(
    "ExpressionNotMetadata",
    message:
        r"""This can't be used as metadata; metadata should be a reference to a compile-time constant variable, or a call to a constant constructor.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExtendFunction = messageExtendFunction;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExtendFunction = const MessageCode("ExtendFunction",
    severity: Severity.ignored,
    message: r"""Extending 'Function' is deprecated.""",
    tip: r"""Try removing 'Function' from the 'extends' clause.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateExtendingEnum =
    const Template<Message Function(String name)>(
        messageTemplate:
            r"""'#name' is an enum and can't be extended or implemented.""",
        withArguments: _withArgumentsExtendingEnum);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeExtendingEnum =
    const Code<Message Function(String name)>(
        "ExtendingEnum", templateExtendingEnum,
        analyzerCodes: <String>["EXTENDS_ENUM"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExtendingEnum(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeExtendingEnum,
      message: """'${name}' is an enum and can't be extended or implemented.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateExtendingRestricted =
    const Template<Message Function(String name)>(
        messageTemplate:
            r"""'#name' is restricted and can't be extended or implemented.""",
        withArguments: _withArgumentsExtendingRestricted);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeExtendingRestricted =
    const Code<Message Function(String name)>(
        "ExtendingRestricted", templateExtendingRestricted,
        analyzerCodes: <String>["EXTENDS_DISALLOWED_CLASS"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExtendingRestricted(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeExtendingRestricted,
      message:
          """'${name}' is restricted and can't be extended or implemented.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExtendsFutureOr = messageExtendsFutureOr;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExtendsFutureOr = const MessageCode("ExtendsFutureOr",
    message: r"""The type 'FutureOr' can't be used in an 'extends' clause.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExtendsNever = messageExtendsNever;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExtendsNever = const MessageCode("ExtendsNever",
    message: r"""The type 'Never' can't be used in an 'extends' clause.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExtendsVoid = messageExtendsVoid;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExtendsVoid = const MessageCode("ExtendsVoid",
    message: r"""The type 'void' can't be used in an 'extends' clause.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExtensionDeclaresAbstractMember =
    messageExtensionDeclaresAbstractMember;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExtensionDeclaresAbstractMember = const MessageCode(
    "ExtensionDeclaresAbstractMember",
    index: 94,
    message: r"""Extensions can't declare abstract members.""",
    tip: r"""Try providing an implementation for the member.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExtensionDeclaresConstructor =
    messageExtensionDeclaresConstructor;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExtensionDeclaresConstructor = const MessageCode(
    "ExtensionDeclaresConstructor",
    index: 92,
    message: r"""Extensions can't declare constructors.""",
    tip: r"""Try removing the constructor declaration.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExtensionDeclaresInstanceField =
    messageExtensionDeclaresInstanceField;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExtensionDeclaresInstanceField = const MessageCode(
    "ExtensionDeclaresInstanceField",
    index: 93,
    message: r"""Extensions can't declare instance fields""",
    tip: r"""Try removing the field declaration or making it a static field""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateExtensionMemberConflictsWithObjectMember =
    const Template<Message Function(String name)>(
        messageTemplate:
            r"""This extension member conflicts with Object member '#name'.""",
        withArguments: _withArgumentsExtensionMemberConflictsWithObjectMember);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)>
    codeExtensionMemberConflictsWithObjectMember =
    const Code<Message Function(String name)>(
  "ExtensionMemberConflictsWithObjectMember",
  templateExtensionMemberConflictsWithObjectMember,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExtensionMemberConflictsWithObjectMember(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeExtensionMemberConflictsWithObjectMember,
      message:
          """This extension member conflicts with Object member '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExternalClass = messageExternalClass;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExternalClass = const MessageCode("ExternalClass",
    index: 3,
    message: r"""Classes can't be declared to be 'external'.""",
    tip: r"""Try removing the keyword 'external'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExternalConstructorWithBody =
    messageExternalConstructorWithBody;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExternalConstructorWithBody = const MessageCode(
    "ExternalConstructorWithBody",
    index: 87,
    message: r"""External constructors can't have a body.""",
    tip:
        r"""Try removing the body of the constructor, or removing the keyword 'external'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExternalConstructorWithFieldInitializers =
    messageExternalConstructorWithFieldInitializers;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExternalConstructorWithFieldInitializers =
    const MessageCode("ExternalConstructorWithFieldInitializers",
        analyzerCodes: <String>["EXTERNAL_CONSTRUCTOR_WITH_FIELD_INITIALIZERS"],
        message: r"""An external constructor can't initialize fields.""",
        tip:
            r"""Try removing the field initializers, or removing the keyword 'external'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExternalConstructorWithInitializer =
    messageExternalConstructorWithInitializer;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExternalConstructorWithInitializer = const MessageCode(
    "ExternalConstructorWithInitializer",
    index: 106,
    message: r"""An external constructor can't have any initializers.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExternalEnum = messageExternalEnum;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExternalEnum = const MessageCode("ExternalEnum",
    index: 5,
    message: r"""Enums can't be declared to be 'external'.""",
    tip: r"""Try removing the keyword 'external'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExternalFactoryRedirection =
    messageExternalFactoryRedirection;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExternalFactoryRedirection = const MessageCode(
    "ExternalFactoryRedirection",
    index: 85,
    message: r"""A redirecting factory can't be external.""",
    tip: r"""Try removing the 'external' modifier.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExternalFactoryWithBody = messageExternalFactoryWithBody;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExternalFactoryWithBody = const MessageCode(
    "ExternalFactoryWithBody",
    index: 86,
    message: r"""External factories can't have a body.""",
    tip:
        r"""Try removing the body of the factory, or removing the keyword 'external'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExternalField = messageExternalField;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExternalField = const MessageCode("ExternalField",
    index: 50,
    message: r"""Fields can't be declared to be 'external'.""",
    tip:
        r"""Try removing the keyword 'external', or replacing the field by an external getter and/or setter.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExternalMethodWithBody = messageExternalMethodWithBody;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExternalMethodWithBody = const MessageCode(
    "ExternalMethodWithBody",
    index: 49,
    message: r"""An external or native method can't have a body.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExternalTypedef = messageExternalTypedef;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExternalTypedef = const MessageCode("ExternalTypedef",
    index: 76,
    message: r"""Typedefs can't be declared to be 'external'.""",
    tip: r"""Try removing the keyword 'external'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateExtraneousModifier =
    const Template<Message Function(Token token)>(
        messageTemplate: r"""Can't have modifier '#lexeme' here.""",
        tipTemplate: r"""Try removing '#lexeme'.""",
        withArguments: _withArgumentsExtraneousModifier);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeExtraneousModifier =
    const Code<Message Function(Token token)>(
        "ExtraneousModifier", templateExtraneousModifier,
        index: 77);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExtraneousModifier(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeExtraneousModifier,
      message: """Can't have modifier '${lexeme}' here.""",
      tip: """Try removing '${lexeme}'.""",
      arguments: {'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)>
    templateExtraneousModifierInExtension =
    const Template<Message Function(Token token)>(
        messageTemplate: r"""Can't have modifier '#lexeme' in an extension.""",
        tipTemplate: r"""Try removing '#lexeme'.""",
        withArguments: _withArgumentsExtraneousModifierInExtension);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeExtraneousModifierInExtension =
    const Code<Message Function(Token token)>(
        "ExtraneousModifierInExtension", templateExtraneousModifierInExtension,
        index: 98);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExtraneousModifierInExtension(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeExtraneousModifierInExtension,
      message: """Can't have modifier '${lexeme}' in an extension.""",
      tip: """Try removing '${lexeme}'.""",
      arguments: {'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeFactoryNotSync = messageFactoryNotSync;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFactoryNotSync = const MessageCode("FactoryNotSync",
    analyzerCodes: <String>["NON_SYNC_FACTORY"],
    message: r"""Factory bodies can't use 'async', 'async*', or 'sync*'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeFactoryTopLevelDeclaration =
    messageFactoryTopLevelDeclaration;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFactoryTopLevelDeclaration = const MessageCode(
    "FactoryTopLevelDeclaration",
    index: 78,
    message: r"""Top-level declarations can't be declared to be 'factory'.""",
    tip: r"""Try removing the keyword 'factory'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateFastaCLIArgumentRequired =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Expected value after '#name'.""",
        withArguments: _withArgumentsFastaCLIArgumentRequired);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeFastaCLIArgumentRequired =
    const Code<Message Function(String name)>(
  "FastaCLIArgumentRequired",
  templateFastaCLIArgumentRequired,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFastaCLIArgumentRequired(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeFastaCLIArgumentRequired,
      message: """Expected value after '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeFastaUsageLong = messageFastaUsageLong;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFastaUsageLong =
    const MessageCode("FastaUsageLong", message: r"""Supported options:

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

  --target=dart2js|dart2js_server|dart_runner|dartdevc|flutter|flutter_runner|none|vm
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

  --bytecode
    Generate bytecode. Supported only for SDK platform compilation.

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
    Multiple experiments can be separated by commas.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeFastaUsageShort = messageFastaUsageShort;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFastaUsageShort =
    const MessageCode("FastaUsageShort", message: r"""Frequently used options:

  -o <file> Generate the output into <file>.
  -h        Display this message (add -v for information about all options).""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeFfiExceptionalReturnNull = messageFfiExceptionalReturnNull;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFfiExceptionalReturnNull = const MessageCode(
    "FfiExceptionalReturnNull",
    message: r"""Exceptional return value must not be null.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeFfiExpectedConstant = messageFfiExpectedConstant;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFfiExpectedConstant = const MessageCode(
    "FfiExpectedConstant",
    message: r"""Exceptional return value must be a constant.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateFfiExtendsOrImplementsSealedClass =
    const Template<Message Function(String name)>(
        messageTemplate:
            r"""Class '#name' cannot be extended or implemented.""",
        withArguments: _withArgumentsFfiExtendsOrImplementsSealedClass);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)>
    codeFfiExtendsOrImplementsSealedClass =
    const Code<Message Function(String name)>(
  "FfiExtendsOrImplementsSealedClass",
  templateFfiExtendsOrImplementsSealedClass,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiExtendsOrImplementsSealedClass(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeFfiExtendsOrImplementsSealedClass,
      message: """Class '${name}' cannot be extended or implemented.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(String name)> templateFfiFieldAnnotation = const Template<
        Message Function(String name)>(
    messageTemplate:
        r"""Field '#name' requires exactly one annotation to declare its native type, which cannot be Void. dart:ffi Structs cannot have regular Dart fields.""",
    withArguments: _withArgumentsFfiFieldAnnotation);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeFfiFieldAnnotation =
    const Code<Message Function(String name)>(
  "FfiFieldAnnotation",
  templateFfiFieldAnnotation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiFieldAnnotation(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeFfiFieldAnnotation,
      message:
          """Field '${name}' requires exactly one annotation to declare its native type, which cannot be Void. dart:ffi Structs cannot have regular Dart fields.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(String name)> templateFfiFieldInitializer = const Template<
        Message Function(String name)>(
    messageTemplate:
        r"""Field '#name' is a dart:ffi Pointer to a struct field and therefore cannot be initialized before constructor execution.""",
    withArguments: _withArgumentsFfiFieldInitializer);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeFfiFieldInitializer =
    const Code<Message Function(String name)>(
  "FfiFieldInitializer",
  templateFfiFieldInitializer,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiFieldInitializer(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeFfiFieldInitializer,
      message:
          """Field '${name}' is a dart:ffi Pointer to a struct field and therefore cannot be initialized before constructor execution.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            name)> templateFfiFieldNoAnnotation = const Template<
        Message Function(String name)>(
    messageTemplate:
        r"""Field '#name' requires no annotation to declare its native type, it is a Pointer which is represented by the same type in Dart and native code.""",
    withArguments: _withArgumentsFfiFieldNoAnnotation);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeFfiFieldNoAnnotation =
    const Code<Message Function(String name)>(
  "FfiFieldNoAnnotation",
  templateFfiFieldNoAnnotation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiFieldNoAnnotation(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeFfiFieldNoAnnotation,
      message:
          """Field '${name}' requires no annotation to declare its native type, it is a Pointer which is represented by the same type in Dart and native code.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(String name)> templateFfiNotStatic = const Template<
        Message Function(String name)>(
    messageTemplate:
        r"""#name expects a static function as parameter. dart:ffi only supports calling static Dart functions from native code.""",
    withArguments: _withArgumentsFfiNotStatic);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeFfiNotStatic =
    const Code<Message Function(String name)>(
  "FfiNotStatic",
  templateFfiNotStatic,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiNotStatic(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeFfiNotStatic,
      message:
          """${name} expects a static function as parameter. dart:ffi only supports calling static Dart functions from native code.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateFfiStructGeneric =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Struct '#name' should not be generic.""",
        withArguments: _withArgumentsFfiStructGeneric);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeFfiStructGeneric =
    const Code<Message Function(String name)>(
  "FfiStructGeneric",
  templateFfiStructGeneric,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiStructGeneric(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeFfiStructGeneric,
      message: """Struct '${name}' should not be generic.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeFieldInitializedOutsideDeclaringClass =
    messageFieldInitializedOutsideDeclaringClass;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFieldInitializedOutsideDeclaringClass = const MessageCode(
    "FieldInitializedOutsideDeclaringClass",
    index: 88,
    message: r"""A field can only be initialized in its declaring class""",
    tip:
        r"""Try passing a value into the superclass constructor, or moving the initialization into the constructor body.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeFieldInitializerOutsideConstructor =
    messageFieldInitializerOutsideConstructor;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFieldInitializerOutsideConstructor = const MessageCode(
    "FieldInitializerOutsideConstructor",
    index: 79,
    message: r"""Field formal parameters can only be used in a constructor.""",
    tip: r"""Try removing 'this.'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeFinalAndCovariant = messageFinalAndCovariant;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFinalAndCovariant = const MessageCode(
    "FinalAndCovariant",
    index: 80,
    message:
        r"""Members can't be declared to be both 'final' and 'covariant'.""",
    tip: r"""Try removing either the 'final' or 'covariant' keyword.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeFinalAndCovariantLateWithInitializer =
    messageFinalAndCovariantLateWithInitializer;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFinalAndCovariantLateWithInitializer = const MessageCode(
    "FinalAndCovariantLateWithInitializer",
    index: 101,
    message:
        r"""Members marked 'late' with an initializer can't be declared to be both 'final' and 'covariant'.""",
    tip:
        r"""Try removing either the 'final' or 'covariant' keyword, or removing the initializer.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeFinalAndVar = messageFinalAndVar;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFinalAndVar = const MessageCode("FinalAndVar",
    index: 81,
    message: r"""Members can't be declared to be both 'final' and 'var'.""",
    tip: r"""Try removing the keyword 'var'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            name)> templateFinalFieldNotInitialized = const Template<
        Message Function(String name)>(
    messageTemplate: r"""Final field '#name' is not initialized.""",
    tipTemplate:
        r"""Try to initialize the field in the declaration or in every constructor.""",
    withArguments: _withArgumentsFinalFieldNotInitialized);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeFinalFieldNotInitialized =
    const Code<Message Function(String name)>(
        "FinalFieldNotInitialized", templateFinalFieldNotInitialized,
        analyzerCodes: <String>["FINAL_NOT_INITIALIZED"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFinalFieldNotInitialized(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeFinalFieldNotInitialized,
      message: """Final field '${name}' is not initialized.""",
      tip:
          """Try to initialize the field in the declaration or in every constructor.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            name)> templateFinalFieldNotInitializedByConstructor = const Template<
        Message Function(String name)>(
    messageTemplate:
        r"""Final field '#name' is not initialized by this constructor.""",
    tipTemplate:
        r"""Try to initialize the field using an initializing formal or a field initializer.""",
    withArguments: _withArgumentsFinalFieldNotInitializedByConstructor);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)>
    codeFinalFieldNotInitializedByConstructor =
    const Code<Message Function(String name)>(
        "FinalFieldNotInitializedByConstructor",
        templateFinalFieldNotInitializedByConstructor,
        analyzerCodes: <String>["FINAL_NOT_INITIALIZED_CONSTRUCTOR_1"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFinalFieldNotInitializedByConstructor(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeFinalFieldNotInitializedByConstructor,
      message:
          """Final field '${name}' is not initialized by this constructor.""",
      tip:
          """Try to initialize the field using an initializing formal or a field initializer.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            name)> templateFinalFieldWithoutInitializer = const Template<
        Message Function(String name)>(
    messageTemplate: r"""The final variable '#name' must be initialized.""",
    tipTemplate:
        r"""Try adding an initializer ('= expression') to the declaration.""",
    withArguments: _withArgumentsFinalFieldWithoutInitializer);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeFinalFieldWithoutInitializer =
    const Code<Message Function(String name)>(
        "FinalFieldWithoutInitializer", templateFinalFieldWithoutInitializer,
        analyzerCodes: <String>["FINAL_NOT_INITIALIZED"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFinalFieldWithoutInitializer(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeFinalFieldWithoutInitializer,
      message: """The final variable '${name}' must be initialized.""",
      tip: """Try adding an initializer ('= expression') to the declaration.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateFinalInstanceVariableAlreadyInitialized =
    const Template<Message Function(String name)>(
        messageTemplate:
            r"""'#name' is a final instance variable that has already been initialized.""",
        withArguments: _withArgumentsFinalInstanceVariableAlreadyInitialized);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)>
    codeFinalInstanceVariableAlreadyInitialized =
    const Code<Message Function(String name)>(
        "FinalInstanceVariableAlreadyInitialized",
        templateFinalInstanceVariableAlreadyInitialized,
        analyzerCodes: <String>["FINAL_INITIALIZED_MULTIPLE_TIMES"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFinalInstanceVariableAlreadyInitialized(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeFinalInstanceVariableAlreadyInitialized,
      message:
          """'${name}' is a final instance variable that has already been initialized.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateFinalInstanceVariableAlreadyInitializedCause =
    const Template<Message Function(String name)>(
        messageTemplate: r"""'#name' was initialized here.""",
        withArguments:
            _withArgumentsFinalInstanceVariableAlreadyInitializedCause);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)>
    codeFinalInstanceVariableAlreadyInitializedCause =
    const Code<Message Function(String name)>(
        "FinalInstanceVariableAlreadyInitializedCause",
        templateFinalInstanceVariableAlreadyInitializedCause,
        severity: Severity.context);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFinalInstanceVariableAlreadyInitializedCause(
    String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeFinalInstanceVariableAlreadyInitializedCause,
      message: """'${name}' was initialized here.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeForInLoopExactlyOneVariable =
    messageForInLoopExactlyOneVariable;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageForInLoopExactlyOneVariable = const MessageCode(
    "ForInLoopExactlyOneVariable",
    message: r"""A for-in loop can't have more than one loop variable.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeForInLoopNotAssignable = messageForInLoopNotAssignable;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageForInLoopNotAssignable = const MessageCode(
    "ForInLoopNotAssignable",
    message:
        r"""Can't assign to this, so it can't be used in a for-in loop.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeForInLoopWithConstVariable =
    messageForInLoopWithConstVariable;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageForInLoopWithConstVariable = const MessageCode(
    "ForInLoopWithConstVariable",
    analyzerCodes: <String>["FOR_IN_WITH_CONST_VARIABLE"],
    message: r"""A for-in loop-variable can't be 'const'.""",
    tip: r"""Try removing the 'const' modifier.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeFunctionTypeDefaultValue = messageFunctionTypeDefaultValue;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFunctionTypeDefaultValue = const MessageCode(
    "FunctionTypeDefaultValue",
    analyzerCodes: <String>["DEFAULT_VALUE_IN_FUNCTION_TYPE"],
    message: r"""Can't have a default value in a function type.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeFunctionTypedParameterVar =
    messageFunctionTypedParameterVar;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFunctionTypedParameterVar = const MessageCode(
    "FunctionTypedParameterVar",
    analyzerCodes: <String>["FUNCTION_TYPED_PARAMETER_VAR"],
    message:
        r"""Function-typed parameters can't specify 'const', 'final' or 'var' in place of a return type.""",
    tip: r"""Try replacing the keyword with a return type.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeGeneratorReturnsValue = messageGeneratorReturnsValue;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageGeneratorReturnsValue = const MessageCode(
    "GeneratorReturnsValue",
    analyzerCodes: <String>["RETURN_IN_GENERATOR"],
    message: r"""'sync*' and 'async*' can't return a value.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeGenericFunctionTypeInBound =
    messageGenericFunctionTypeInBound;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageGenericFunctionTypeInBound = const MessageCode(
    "GenericFunctionTypeInBound",
    analyzerCodes: <String>["GENERIC_FUNCTION_TYPE_CANNOT_BE_BOUND"],
    message:
        r"""Type variables can't have generic function types in their bounds.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeGenericFunctionTypeUsedAsActualTypeArgument =
    messageGenericFunctionTypeUsedAsActualTypeArgument;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageGenericFunctionTypeUsedAsActualTypeArgument =
    const MessageCode("GenericFunctionTypeUsedAsActualTypeArgument",
        analyzerCodes: <String>["GENERIC_FUNCTION_CANNOT_BE_TYPE_ARGUMENT"],
        message:
            r"""A generic function type can't be used as a type argument.""",
        tip: r"""Try using a non-generic function type.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeGetterConstructor = messageGetterConstructor;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageGetterConstructor = const MessageCode(
    "GetterConstructor",
    index: 103,
    message: r"""Constructors can't be a getter.""",
    tip: r"""Try removing 'get'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateGetterNotFound =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Getter not found: '#name'.""",
        withArguments: _withArgumentsGetterNotFound);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeGetterNotFound =
    const Code<Message Function(String name)>(
        "GetterNotFound", templateGetterNotFound,
        analyzerCodes: <String>["UNDEFINED_GETTER"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsGetterNotFound(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeGetterNotFound,
      message: """Getter not found: '${name}'.""", arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeGetterWithFormals = messageGetterWithFormals;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageGetterWithFormals = const MessageCode(
    "GetterWithFormals",
    analyzerCodes: <String>["GETTER_WITH_PARAMETERS"],
    message: r"""A getter can't have formal parameters.""",
    tip: r"""Try removing '(...)'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeIllegalAssignmentToNonAssignable =
    messageIllegalAssignmentToNonAssignable;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageIllegalAssignmentToNonAssignable = const MessageCode(
    "IllegalAssignmentToNonAssignable",
    index: 45,
    message: r"""Illegal assignment to non-assignable expression.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeIllegalAsyncGeneratorReturnType =
    messageIllegalAsyncGeneratorReturnType;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageIllegalAsyncGeneratorReturnType = const MessageCode(
    "IllegalAsyncGeneratorReturnType",
    analyzerCodes: <String>["ILLEGAL_ASYNC_GENERATOR_RETURN_TYPE"],
    message:
        r"""Functions marked 'async*' must have a return type assignable to 'Stream'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeIllegalAsyncGeneratorVoidReturnType =
    messageIllegalAsyncGeneratorVoidReturnType;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageIllegalAsyncGeneratorVoidReturnType =
    const MessageCode("IllegalAsyncGeneratorVoidReturnType",
        message:
            r"""Functions marked 'async*' can't have return type 'void'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeIllegalAsyncReturnType = messageIllegalAsyncReturnType;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageIllegalAsyncReturnType = const MessageCode(
    "IllegalAsyncReturnType",
    analyzerCodes: <String>["ILLEGAL_ASYNC_RETURN_TYPE"],
    message:
        r"""Functions marked 'async' must have a return type assignable to 'Future'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateIllegalMixin =
    const Template<Message Function(String name)>(
        messageTemplate: r"""The type '#name' can't be mixed in.""",
        withArguments: _withArgumentsIllegalMixin);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeIllegalMixin =
    const Code<Message Function(String name)>(
        "IllegalMixin", templateIllegalMixin,
        analyzerCodes: <String>["ILLEGAL_MIXIN"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIllegalMixin(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeIllegalMixin,
      message: """The type '${name}' can't be mixed in.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateIllegalMixinDueToConstructors =
    const Template<Message Function(String name)>(
        messageTemplate:
            r"""Can't use '#name' as a mixin because it has constructors.""",
        withArguments: _withArgumentsIllegalMixinDueToConstructors);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeIllegalMixinDueToConstructors =
    const Code<Message Function(String name)>(
        "IllegalMixinDueToConstructors", templateIllegalMixinDueToConstructors,
        analyzerCodes: <String>["MIXIN_DECLARES_CONSTRUCTOR"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIllegalMixinDueToConstructors(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeIllegalMixinDueToConstructors,
      message:
          """Can't use '${name}' as a mixin because it has constructors.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateIllegalMixinDueToConstructorsCause =
    const Template<Message Function(String name)>(
        messageTemplate:
            r"""This constructor prevents using '#name' as a mixin.""",
        withArguments: _withArgumentsIllegalMixinDueToConstructorsCause);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)>
    codeIllegalMixinDueToConstructorsCause =
    const Code<Message Function(String name)>(
        "IllegalMixinDueToConstructorsCause",
        templateIllegalMixinDueToConstructorsCause,
        severity: Severity.context);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIllegalMixinDueToConstructorsCause(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeIllegalMixinDueToConstructorsCause,
      message: """This constructor prevents using '${name}' as a mixin.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeIllegalSyncGeneratorReturnType =
    messageIllegalSyncGeneratorReturnType;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageIllegalSyncGeneratorReturnType = const MessageCode(
    "IllegalSyncGeneratorReturnType",
    analyzerCodes: <String>["ILLEGAL_SYNC_GENERATOR_RETURN_TYPE"],
    message:
        r"""Functions marked 'sync*' must have a return type assignable to 'Iterable'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeIllegalSyncGeneratorVoidReturnType =
    messageIllegalSyncGeneratorVoidReturnType;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageIllegalSyncGeneratorVoidReturnType = const MessageCode(
    "IllegalSyncGeneratorVoidReturnType",
    message: r"""Functions marked 'sync*' can't have return type 'void'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeImplementFunction = messageImplementFunction;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageImplementFunction = const MessageCode(
    "ImplementFunction",
    severity: Severity.ignored,
    message: r"""Implementing 'Function' is deprecated.""",
    tip: r"""Try removing 'Function' from the 'implements' clause.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeImplementsBeforeExtends = messageImplementsBeforeExtends;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageImplementsBeforeExtends = const MessageCode(
    "ImplementsBeforeExtends",
    index: 44,
    message: r"""The extends clause must be before the implements clause.""",
    tip: r"""Try moving the extends clause before the implements clause.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeImplementsBeforeOn = messageImplementsBeforeOn;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageImplementsBeforeOn = const MessageCode(
    "ImplementsBeforeOn",
    index: 43,
    message: r"""The on clause must be before the implements clause.""",
    tip: r"""Try moving the on clause before the implements clause.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeImplementsBeforeWith = messageImplementsBeforeWith;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageImplementsBeforeWith = const MessageCode(
    "ImplementsBeforeWith",
    index: 42,
    message: r"""The with clause must be before the implements clause.""",
    tip: r"""Try moving the with clause before the implements clause.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeImplementsFutureOr = messageImplementsFutureOr;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageImplementsFutureOr = const MessageCode(
    "ImplementsFutureOr",
    message:
        r"""The type 'FutureOr' can't be used in an 'implements' clause.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeImplementsNever = messageImplementsNever;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageImplementsNever = const MessageCode("ImplementsNever",
    message: r"""The type 'Never' can't be used in an 'implements' clause.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, int count)>
    templateImplementsRepeated =
    const Template<Message Function(String name, int count)>(
        messageTemplate: r"""'#name' can only be implemented once.""",
        tipTemplate: r"""Try removing #count of the occurrences.""",
        withArguments: _withArgumentsImplementsRepeated);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, int count)> codeImplementsRepeated =
    const Code<Message Function(String name, int count)>(
        "ImplementsRepeated", templateImplementsRepeated,
        analyzerCodes: <String>["IMPLEMENTS_REPEATED"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsImplementsRepeated(String name, int count) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (count == null) throw 'No count provided';
  return new Message(codeImplementsRepeated,
      message: """'${name}' can only be implemented once.""",
      tip: """Try removing ${count} of the occurrences.""",
      arguments: {'name': name, 'count': count});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            name)> templateImplementsSuperClass = const Template<
        Message Function(String name)>(
    messageTemplate:
        r"""'#name' can't be used in both 'extends' and 'implements' clauses.""",
    tipTemplate: r"""Try removing one of the occurrences.""",
    withArguments: _withArgumentsImplementsSuperClass);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeImplementsSuperClass =
    const Code<Message Function(String name)>(
        "ImplementsSuperClass", templateImplementsSuperClass,
        analyzerCodes: <String>["IMPLEMENTS_SUPER_CLASS"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsImplementsSuperClass(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeImplementsSuperClass,
      message:
          """'${name}' can't be used in both 'extends' and 'implements' clauses.""",
      tip: """Try removing one of the occurrences.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeImplementsVoid = messageImplementsVoid;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageImplementsVoid = const MessageCode("ImplementsVoid",
    message: r"""The type 'void' can't be used in an 'implements' clause.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String name,
        String name2,
        String
            name3)> templateImplicitMixinOverride = const Template<
        Message Function(String name, String name2, String name3)>(
    messageTemplate:
        r"""Applying the mixin '#name' to '#name2' introduces an erroneous override of '#name3'.""",
    withArguments: _withArgumentsImplicitMixinOverride);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String name2, String name3)>
    codeImplicitMixinOverride =
    const Code<Message Function(String name, String name2, String name3)>(
  "ImplicitMixinOverride",
  templateImplicitMixinOverride,
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
  return new Message(codeImplicitMixinOverride,
      message:
          """Applying the mixin '${name}' to '${name2}' introduces an erroneous override of '${name3}'.""",
      arguments: {'name': name, 'name2': name2, 'name3': name3});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeImportAfterPart = messageImportAfterPart;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageImportAfterPart = const MessageCode("ImportAfterPart",
    index: 10,
    message: r"""Import directives must precede part directives.""",
    tip: r"""Try moving the import directives before the part directives.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, Uri uri_, Uri uri2_)>
    templateImportHidesImport =
    const Template<Message Function(String name, Uri uri_, Uri uri2_)>(
        messageTemplate:
            r"""Import of '#name' (from '#uri') hides import from '#uri2'.""",
        withArguments: _withArgumentsImportHidesImport);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, Uri uri_, Uri uri2_)>
    codeImportHidesImport =
    const Code<Message Function(String name, Uri uri_, Uri uri2_)>(
        "ImportHidesImport", templateImportHidesImport,
        severity: Severity.ignored);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsImportHidesImport(String name, Uri uri_, Uri uri2_) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  String uri = relativizeUri(uri_);
  String uri2 = relativizeUri(uri2_);
  return new Message(codeImportHidesImport,
      message:
          """Import of '${name}' (from '${uri}') hides import from '${uri2}'.""",
      arguments: {'name': name, 'uri': uri_, 'uri2': uri2_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeIncorrectTypeArgumentVariable =
    messageIncorrectTypeArgumentVariable;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageIncorrectTypeArgumentVariable = const MessageCode(
    "IncorrectTypeArgumentVariable",
    severity: Severity.context,
    message: r"""This is the type variable whose bound isn't conformed to.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri_)> templateInferredPackageUri =
    const Template<Message Function(Uri uri_)>(
        messageTemplate: r"""Interpreting this as package URI, '#uri'.""",
        withArguments: _withArgumentsInferredPackageUri);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Uri uri_)> codeInferredPackageUri =
    const Code<Message Function(Uri uri_)>(
        "InferredPackageUri", templateInferredPackageUri,
        severity: Severity.warning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInferredPackageUri(Uri uri_) {
  String uri = relativizeUri(uri_);
  return new Message(codeInferredPackageUri,
      message: """Interpreting this as package URI, '${uri}'.""",
      arguments: {'uri': uri_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInheritedMembersConflict = messageInheritedMembersConflict;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInheritedMembersConflict = const MessageCode(
    "InheritedMembersConflict",
    analyzerCodes: <String>["CONFLICTS_WITH_INHERITED_MEMBER"],
    message: r"""Can't inherit members that conflict with each other.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInheritedMembersConflictCause1 =
    messageInheritedMembersConflictCause1;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInheritedMembersConflictCause1 = const MessageCode(
    "InheritedMembersConflictCause1",
    severity: Severity.context,
    message: r"""This is one inherited member.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInheritedMembersConflictCause2 =
    messageInheritedMembersConflictCause2;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInheritedMembersConflictCause2 = const MessageCode(
    "InheritedMembersConflictCause2",
    severity: Severity.context,
    message: r"""This is the other inherited member.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String string,
        Uri
            uri_)> templateInitializeFromDillNotSelfContained = const Template<
        Message Function(String string, Uri uri_)>(
    messageTemplate:
        r"""Tried to initialize from a previous compilation (#string), but the file was not self-contained. This might be a bug.

The Dart team would greatly appreciate it if you would take a moment to report this problem at http://dartbug.com/new.
If you are comfortable with it, it would improve the chances of fixing any bug if you included the file #uri in your error report, but be aware that this file includes your source code.
Either way, you should probably delete the file so it doesn't use unnecessary disk space.""",
    withArguments: _withArgumentsInitializeFromDillNotSelfContained);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string, Uri uri_)>
    codeInitializeFromDillNotSelfContained =
    const Code<Message Function(String string, Uri uri_)>(
        "InitializeFromDillNotSelfContained",
        templateInitializeFromDillNotSelfContained,
        severity: Severity.warning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInitializeFromDillNotSelfContained(
    String string, Uri uri_) {
  if (string.isEmpty) throw 'No string provided';
  String uri = relativizeUri(uri_);
  return new Message(codeInitializeFromDillNotSelfContained,
      message:
          """Tried to initialize from a previous compilation (${string}), but the file was not self-contained. This might be a bug.

The Dart team would greatly appreciate it if you would take a moment to report this problem at http://dartbug.com/new.
If you are comfortable with it, it would improve the chances of fixing any bug if you included the file ${uri} in your error report, but be aware that this file includes your source code.
Either way, you should probably delete the file so it doesn't use unnecessary disk space.""",
      arguments: {'string': string, 'uri': uri_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)>
    templateInitializeFromDillNotSelfContainedNoDump =
    const Template<Message Function(String string)>(
        messageTemplate:
            r"""Tried to initialize from a previous compilation (#string), but the file was not self-contained. This might be a bug.

The Dart team would greatly appreciate it if you would take a moment to report this problem at http://dartbug.com/new.""",
        withArguments: _withArgumentsInitializeFromDillNotSelfContainedNoDump);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string)>
    codeInitializeFromDillNotSelfContainedNoDump =
    const Code<Message Function(String string)>(
        "InitializeFromDillNotSelfContainedNoDump",
        templateInitializeFromDillNotSelfContainedNoDump,
        severity: Severity.warning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInitializeFromDillNotSelfContainedNoDump(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeInitializeFromDillNotSelfContainedNoDump,
      message:
          """Tried to initialize from a previous compilation (${string}), but the file was not self-contained. This might be a bug.

The Dart team would greatly appreciate it if you would take a moment to report this problem at http://dartbug.com/new.""",
      arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String string,
        String string2,
        String string3,
        Uri
            uri_)> templateInitializeFromDillUnknownProblem = const Template<
        Message Function(
            String string, String string2, String string3, Uri uri_)>(
    messageTemplate:
        r"""Tried to initialize from a previous compilation (#string), but couldn't.
Error message was '#string2'.
Stacktrace included '#string3'.
This might be a bug.

The Dart team would greatly appreciate it if you would take a moment to report this problem at http://dartbug.com/new.
If you are comfortable with it, it would improve the chances of fixing any bug if you included the file #uri in your error report, but be aware that this file includes your source code.
Either way, you should probably delete the file so it doesn't use unnecessary disk space.""",
    withArguments: _withArgumentsInitializeFromDillUnknownProblem);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            String string, String string2, String string3, Uri uri_)>
    codeInitializeFromDillUnknownProblem = const Code<
            Message Function(
                String string, String string2, String string3, Uri uri_)>(
        "InitializeFromDillUnknownProblem",
        templateInitializeFromDillUnknownProblem,
        severity: Severity.warning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInitializeFromDillUnknownProblem(
    String string, String string2, String string3, Uri uri_) {
  if (string.isEmpty) throw 'No string provided';
  if (string2.isEmpty) throw 'No string provided';
  if (string3.isEmpty) throw 'No string provided';
  String uri = relativizeUri(uri_);
  return new Message(codeInitializeFromDillUnknownProblem,
      message:
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
        'uri': uri_
      });
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string, String string2, String string3)>
    templateInitializeFromDillUnknownProblemNoDump = const Template<
            Message Function(String string, String string2, String string3)>(
        messageTemplate:
            r"""Tried to initialize from a previous compilation (#string), but couldn't.
Error message was '#string2'.
Stacktrace included '#string3'.
This might be a bug.

The Dart team would greatly appreciate it if you would take a moment to report this problem at http://dartbug.com/new.""",
        withArguments: _withArgumentsInitializeFromDillUnknownProblemNoDump);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string, String string2, String string3)>
    codeInitializeFromDillUnknownProblemNoDump =
    const Code<Message Function(String string, String string2, String string3)>(
        "InitializeFromDillUnknownProblemNoDump",
        templateInitializeFromDillUnknownProblemNoDump,
        severity: Severity.warning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInitializeFromDillUnknownProblemNoDump(
    String string, String string2, String string3) {
  if (string.isEmpty) throw 'No string provided';
  if (string2.isEmpty) throw 'No string provided';
  if (string3.isEmpty) throw 'No string provided';
  return new Message(codeInitializeFromDillUnknownProblemNoDump,
      message:
          """Tried to initialize from a previous compilation (${string}), but couldn't.
Error message was '${string2}'.
Stacktrace included '${string3}'.
This might be a bug.

The Dart team would greatly appreciate it if you would take a moment to report this problem at http://dartbug.com/new.""",
      arguments: {'string': string, 'string2': string2, 'string3': string3});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInitializedVariableInForEach =
    messageInitializedVariableInForEach;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInitializedVariableInForEach = const MessageCode(
    "InitializedVariableInForEach",
    index: 82,
    message: r"""The loop variable in a for-each loop can't be initialized.""",
    tip:
        r"""Try removing the initializer, or using a different kind of loop.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateInitializerForStaticField =
    const Template<Message Function(String name)>(
        messageTemplate: r"""'#name' isn't an instance field of this class.""",
        withArguments: _withArgumentsInitializerForStaticField);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeInitializerForStaticField =
    const Code<Message Function(String name)>(
        "InitializerForStaticField", templateInitializerForStaticField,
        analyzerCodes: <String>["INITIALIZER_FOR_STATIC_FIELD"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInitializerForStaticField(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeInitializerForStaticField,
      message: """'${name}' isn't an instance field of this class.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInitializingFormalTypeMismatchField =
    messageInitializingFormalTypeMismatchField;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInitializingFormalTypeMismatchField =
    const MessageCode("InitializingFormalTypeMismatchField",
        severity: Severity.context,
        message: r"""The field that corresponds to the parameter.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri_)> templateInputFileNotFound =
    const Template<Message Function(Uri uri_)>(
        messageTemplate: r"""Input file not found: #uri.""",
        withArguments: _withArgumentsInputFileNotFound);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Uri uri_)> codeInputFileNotFound =
    const Code<Message Function(Uri uri_)>(
  "InputFileNotFound",
  templateInputFileNotFound,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInputFileNotFound(Uri uri_) {
  String uri = relativizeUri(uri_);
  return new Message(codeInputFileNotFound,
      message: """Input file not found: ${uri}.""", arguments: {'uri': uri_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            string)> templateIntegerLiteralIsOutOfRange = const Template<
        Message Function(String string)>(
    messageTemplate:
        r"""The integer literal #string can't be represented in 64 bits.""",
    tipTemplate:
        r"""Try using the BigInt class if you need an integer larger than 9,223,372,036,854,775,807 or less than -9,223,372,036,854,775,808.""",
    withArguments: _withArgumentsIntegerLiteralIsOutOfRange);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string)> codeIntegerLiteralIsOutOfRange =
    const Code<Message Function(String string)>(
        "IntegerLiteralIsOutOfRange", templateIntegerLiteralIsOutOfRange,
        analyzerCodes: <String>["INTEGER_LITERAL_OUT_OF_RANGE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIntegerLiteralIsOutOfRange(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeIntegerLiteralIsOutOfRange,
      message:
          """The integer literal ${string} can't be represented in 64 bits.""",
      tip:
          """Try using the BigInt class if you need an integer larger than 9,223,372,036,854,775,807 or less than -9,223,372,036,854,775,808.""",
      arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String name,
        String
            name2)> templateInterfaceCheck = const Template<
        Message Function(String name, String name2)>(
    messageTemplate:
        r"""The implementation of '#name' in the non-abstract class '#name2' does not conform to its interface.""",
    withArguments: _withArgumentsInterfaceCheck);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String name2)> codeInterfaceCheck =
    const Code<Message Function(String name, String name2)>(
  "InterfaceCheck",
  templateInterfaceCheck,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInterfaceCheck(String name, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(codeInterfaceCheck,
      message:
          """The implementation of '${name}' in the non-abstract class '${name2}' does not conform to its interface.""",
      arguments: {'name': name, 'name2': name2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInternalProblemAlreadyInitialized =
    messageInternalProblemAlreadyInitialized;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInternalProblemAlreadyInitialized = const MessageCode(
    "InternalProblemAlreadyInitialized",
    severity: Severity.internalProblem,
    message: r"""Attempt to set initializer on field without initializer.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInternalProblemBodyOnAbstractMethod =
    messageInternalProblemBodyOnAbstractMethod;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInternalProblemBodyOnAbstractMethod =
    const MessageCode("InternalProblemBodyOnAbstractMethod",
        severity: Severity.internalProblem,
        message: r"""Attempting to set body on abstract method.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, Uri uri_)>
    templateInternalProblemConstructorNotFound =
    const Template<Message Function(String name, Uri uri_)>(
        messageTemplate: r"""No constructor named '#name' in '#uri'.""",
        withArguments: _withArgumentsInternalProblemConstructorNotFound);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, Uri uri_)>
    codeInternalProblemConstructorNotFound =
    const Code<Message Function(String name, Uri uri_)>(
        "InternalProblemConstructorNotFound",
        templateInternalProblemConstructorNotFound,
        severity: Severity.internalProblem);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemConstructorNotFound(
    String name, Uri uri_) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  String uri = relativizeUri(uri_);
  return new Message(codeInternalProblemConstructorNotFound,
      message: """No constructor named '${name}' in '${uri}'.""",
      arguments: {'name': name, 'uri': uri_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)>
    templateInternalProblemContextSeverity =
    const Template<Message Function(String string)>(
        messageTemplate:
            r"""Non-context message has context severity: #string""",
        withArguments: _withArgumentsInternalProblemContextSeverity);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string)> codeInternalProblemContextSeverity =
    const Code<Message Function(String string)>(
        "InternalProblemContextSeverity",
        templateInternalProblemContextSeverity,
        severity: Severity.internalProblem);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemContextSeverity(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeInternalProblemContextSeverity,
      message: """Non-context message has context severity: ${string}""",
      arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String string)>
    templateInternalProblemDebugAbort =
    const Template<Message Function(String name, String string)>(
        messageTemplate: r"""Compilation aborted due to fatal '#name' at:
#string""", withArguments: _withArgumentsInternalProblemDebugAbort);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String string)>
    codeInternalProblemDebugAbort =
    const Code<Message Function(String name, String string)>(
        "InternalProblemDebugAbort", templateInternalProblemDebugAbort,
        severity: Severity.internalProblem);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemDebugAbort(String name, String string) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeInternalProblemDebugAbort,
      message: """Compilation aborted due to fatal '${name}' at:
${string}""", arguments: {'name': name, 'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInternalProblemExtendingUnmodifiableScope =
    messageInternalProblemExtendingUnmodifiableScope;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInternalProblemExtendingUnmodifiableScope =
    const MessageCode("InternalProblemExtendingUnmodifiableScope",
        severity: Severity.internalProblem,
        message: r"""Can't extend an unmodifiable scope.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInternalProblemLabelUsageInVariablesDeclaration =
    messageInternalProblemLabelUsageInVariablesDeclaration;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInternalProblemLabelUsageInVariablesDeclaration =
    const MessageCode("InternalProblemLabelUsageInVariablesDeclaration",
        severity: Severity.internalProblem,
        message:
            r"""Unexpected usage of label inside declaration of variables.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInternalProblemMissingContext =
    messageInternalProblemMissingContext;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInternalProblemMissingContext = const MessageCode(
    "InternalProblemMissingContext",
    severity: Severity.internalProblem,
    message: r"""Compiler cannot run without a compiler context.""",
    tip:
        r"""Are calls to the compiler wrapped in CompilerContext.runInContext?""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateInternalProblemNotFound =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Couldn't find '#name'.""",
        withArguments: _withArgumentsInternalProblemNotFound);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeInternalProblemNotFound =
    const Code<Message Function(String name)>(
        "InternalProblemNotFound", templateInternalProblemNotFound,
        severity: Severity.internalProblem);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemNotFound(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeInternalProblemNotFound,
      message: """Couldn't find '${name}'.""", arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String name2)>
    templateInternalProblemNotFoundIn =
    const Template<Message Function(String name, String name2)>(
        messageTemplate: r"""Couldn't find '#name' in '#name2'.""",
        withArguments: _withArgumentsInternalProblemNotFoundIn);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String name2)>
    codeInternalProblemNotFoundIn =
    const Code<Message Function(String name, String name2)>(
        "InternalProblemNotFoundIn", templateInternalProblemNotFoundIn,
        severity: Severity.internalProblem);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemNotFoundIn(String name, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(codeInternalProblemNotFoundIn,
      message: """Couldn't find '${name}' in '${name2}'.""",
      arguments: {'name': name, 'name2': name2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInternalProblemPreviousTokenNotFound =
    messageInternalProblemPreviousTokenNotFound;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInternalProblemPreviousTokenNotFound =
    const MessageCode("InternalProblemPreviousTokenNotFound",
        severity: Severity.internalProblem,
        message: r"""Couldn't find previous token.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateInternalProblemPrivateConstructorAccess =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Can't access private constructor '#name'.""",
        withArguments: _withArgumentsInternalProblemPrivateConstructorAccess);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)>
    codeInternalProblemPrivateConstructorAccess =
    const Code<Message Function(String name)>(
        "InternalProblemPrivateConstructorAccess",
        templateInternalProblemPrivateConstructorAccess,
        severity: Severity.internalProblem);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemPrivateConstructorAccess(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeInternalProblemPrivateConstructorAccess,
      message: """Can't access private constructor '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInternalProblemProvidedBothCompileSdkAndSdkSummary =
    messageInternalProblemProvidedBothCompileSdkAndSdkSummary;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInternalProblemProvidedBothCompileSdkAndSdkSummary =
    const MessageCode("InternalProblemProvidedBothCompileSdkAndSdkSummary",
        severity: Severity.internalProblem,
        message:
            r"""The compileSdk and sdkSummary options are mutually exclusive""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String string)>
    templateInternalProblemStackNotEmpty =
    const Template<Message Function(String name, String string)>(
        messageTemplate: r"""#name.stack isn't empty:
  #string""", withArguments: _withArgumentsInternalProblemStackNotEmpty);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String string)>
    codeInternalProblemStackNotEmpty =
    const Code<Message Function(String name, String string)>(
        "InternalProblemStackNotEmpty", templateInternalProblemStackNotEmpty,
        severity: Severity.internalProblem);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemStackNotEmpty(String name, String string) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeInternalProblemStackNotEmpty,
      message: """${name}.stack isn't empty:
  ${string}""", arguments: {'name': name, 'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string, String string2)>
    templateInternalProblemUnexpected =
    const Template<Message Function(String string, String string2)>(
        messageTemplate: r"""Expected '#string', but got '#string2'.""",
        withArguments: _withArgumentsInternalProblemUnexpected);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string, String string2)>
    codeInternalProblemUnexpected =
    const Code<Message Function(String string, String string2)>(
        "InternalProblemUnexpected", templateInternalProblemUnexpected,
        severity: Severity.internalProblem);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemUnexpected(String string, String string2) {
  if (string.isEmpty) throw 'No string provided';
  if (string2.isEmpty) throw 'No string provided';
  return new Message(codeInternalProblemUnexpected,
      message: """Expected '${string}', but got '${string2}'.""",
      arguments: {'string': string, 'string2': string2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String name,
        Uri
            uri_)> templateInternalProblemUnfinishedTypeVariable = const Template<
        Message Function(String name, Uri uri_)>(
    messageTemplate:
        r"""Unfinished type variable '#name' found in non-source library '#uri'.""",
    withArguments: _withArgumentsInternalProblemUnfinishedTypeVariable);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, Uri uri_)>
    codeInternalProblemUnfinishedTypeVariable =
    const Code<Message Function(String name, Uri uri_)>(
        "InternalProblemUnfinishedTypeVariable",
        templateInternalProblemUnfinishedTypeVariable,
        severity: Severity.internalProblem);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemUnfinishedTypeVariable(
    String name, Uri uri_) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  String uri = relativizeUri(uri_);
  return new Message(codeInternalProblemUnfinishedTypeVariable,
      message:
          """Unfinished type variable '${name}' found in non-source library '${uri}'.""",
      arguments: {'name': name, 'uri': uri_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string, String string2)>
    templateInternalProblemUnhandled =
    const Template<Message Function(String string, String string2)>(
        messageTemplate: r"""Unhandled #string in #string2.""",
        withArguments: _withArgumentsInternalProblemUnhandled);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string, String string2)>
    codeInternalProblemUnhandled =
    const Code<Message Function(String string, String string2)>(
        "InternalProblemUnhandled", templateInternalProblemUnhandled,
        severity: Severity.internalProblem);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemUnhandled(String string, String string2) {
  if (string.isEmpty) throw 'No string provided';
  if (string2.isEmpty) throw 'No string provided';
  return new Message(codeInternalProblemUnhandled,
      message: """Unhandled ${string} in ${string2}.""",
      arguments: {'string': string, 'string2': string2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)>
    templateInternalProblemUnimplemented =
    const Template<Message Function(String string)>(
        messageTemplate: r"""Unimplemented #string.""",
        withArguments: _withArgumentsInternalProblemUnimplemented);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string)> codeInternalProblemUnimplemented =
    const Code<Message Function(String string)>(
        "InternalProblemUnimplemented", templateInternalProblemUnimplemented,
        severity: Severity.internalProblem);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemUnimplemented(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeInternalProblemUnimplemented,
      message: """Unimplemented ${string}.""", arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateInternalProblemUnsupported =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Unsupported operation: '#name'.""",
        withArguments: _withArgumentsInternalProblemUnsupported);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeInternalProblemUnsupported =
    const Code<Message Function(String name)>(
        "InternalProblemUnsupported", templateInternalProblemUnsupported,
        severity: Severity.internalProblem);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemUnsupported(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeInternalProblemUnsupported,
      message: """Unsupported operation: '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri_)>
    templateInternalProblemUriMissingScheme =
    const Template<Message Function(Uri uri_)>(
        messageTemplate: r"""The URI '#uri' has no scheme.""",
        withArguments: _withArgumentsInternalProblemUriMissingScheme);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Uri uri_)> codeInternalProblemUriMissingScheme =
    const Code<Message Function(Uri uri_)>("InternalProblemUriMissingScheme",
        templateInternalProblemUriMissingScheme,
        severity: Severity.internalProblem);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemUriMissingScheme(Uri uri_) {
  String uri = relativizeUri(uri_);
  return new Message(codeInternalProblemUriMissingScheme,
      message: """The URI '${uri}' has no scheme.""", arguments: {'uri': uri_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)>
    templateInternalProblemVerificationError =
    const Template<Message Function(String string)>(
        messageTemplate: r"""Verification of the generated program failed:
#string""", withArguments: _withArgumentsInternalProblemVerificationError);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string)>
    codeInternalProblemVerificationError =
    const Code<Message Function(String string)>(
        "InternalProblemVerificationError",
        templateInternalProblemVerificationError,
        severity: Severity.internalProblem);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemVerificationError(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeInternalProblemVerificationError,
      message: """Verification of the generated program failed:
${string}""", arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInterpolationInUri = messageInterpolationInUri;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInterpolationInUri = const MessageCode(
    "InterpolationInUri",
    analyzerCodes: <String>["INVALID_LITERAL_IN_CONFIGURATION"],
    message: r"""Can't use string interpolation in a URI.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInvalidAwaitFor = messageInvalidAwaitFor;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidAwaitFor = const MessageCode("InvalidAwaitFor",
    index: 9,
    message:
        r"""The keyword 'await' isn't allowed for a normal 'for' statement.""",
    tip: r"""Try removing the keyword, or use a for-each statement.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateInvalidBreakTarget =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Can't break to '#name'.""",
        withArguments: _withArgumentsInvalidBreakTarget);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeInvalidBreakTarget =
    const Code<Message Function(String name)>(
  "InvalidBreakTarget",
  templateInvalidBreakTarget,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidBreakTarget(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeInvalidBreakTarget,
      message: """Can't break to '${name}'.""", arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInvalidCatchArguments = messageInvalidCatchArguments;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidCatchArguments = const MessageCode(
    "InvalidCatchArguments",
    analyzerCodes: <String>["INVALID_CATCH_ARGUMENTS"],
    message: r"""Invalid catch arguments.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInvalidCodePoint = messageInvalidCodePoint;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidCodePoint = const MessageCode(
    "InvalidCodePoint",
    analyzerCodes: <String>["INVALID_CODE_POINT"],
    message:
        r"""The escape sequence starting with '\u' isn't a valid code point.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateInvalidContinueTarget =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Can't continue at '#name'.""",
        withArguments: _withArgumentsInvalidContinueTarget);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeInvalidContinueTarget =
    const Code<Message Function(String name)>(
  "InvalidContinueTarget",
  templateInvalidContinueTarget,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidContinueTarget(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeInvalidContinueTarget,
      message: """Can't continue at '${name}'.""", arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInvalidHexEscape = messageInvalidHexEscape;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidHexEscape = const MessageCode(
    "InvalidHexEscape",
    index: 40,
    message:
        r"""An escape sequence starting with '\x' must be followed by 2 hexadecimal digits.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInvalidInitializer = messageInvalidInitializer;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidInitializer = const MessageCode(
    "InvalidInitializer",
    index: 90,
    message: r"""Not a valid initializer.""",
    tip: r"""To initialize a field, use the syntax 'name = value'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInvalidInlineFunctionType =
    messageInvalidInlineFunctionType;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidInlineFunctionType = const MessageCode(
    "InvalidInlineFunctionType",
    analyzerCodes: <String>["INVALID_INLINE_FUNCTION_TYPE"],
    message:
        r"""Inline function types cannot be used for parameters in a generic function type.""",
    tip:
        r"""Try changing the inline function type (as in 'int f()') to a prefixed function type using the `Function` keyword (as in 'int Function() f').""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateInvalidOperator =
    const Template<Message Function(Token token)>(
        messageTemplate:
            r"""The string '#lexeme' isn't a user-definable operator.""",
        withArguments: _withArgumentsInvalidOperator);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeInvalidOperator =
    const Code<Message Function(Token token)>(
        "InvalidOperator", templateInvalidOperator,
        index: 39);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidOperator(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeInvalidOperator,
      message: """The string '${lexeme}' isn't a user-definable operator.""",
      arguments: {'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri_, String string)>
    templateInvalidPackageUri =
    const Template<Message Function(Uri uri_, String string)>(
        messageTemplate: r"""Invalid package URI '#uri':
  #string.""", withArguments: _withArgumentsInvalidPackageUri);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Uri uri_, String string)> codeInvalidPackageUri =
    const Code<Message Function(Uri uri_, String string)>(
  "InvalidPackageUri",
  templateInvalidPackageUri,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidPackageUri(Uri uri_, String string) {
  String uri = relativizeUri(uri_);
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeInvalidPackageUri,
      message: """Invalid package URI '${uri}':
  ${string}.""", arguments: {'uri': uri_, 'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInvalidSuperInInitializer =
    messageInvalidSuperInInitializer;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidSuperInInitializer = const MessageCode(
    "InvalidSuperInInitializer",
    index: 47,
    message:
        r"""Can only use 'super' in an initializer for calling the superclass constructor (e.g. 'super()' or 'super.namedConstructor()')""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInvalidSyncModifier = messageInvalidSyncModifier;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidSyncModifier = const MessageCode(
    "InvalidSyncModifier",
    analyzerCodes: <String>["MISSING_STAR_AFTER_SYNC"],
    message: r"""Invalid modifier 'sync'.""",
    tip: r"""Try replacing 'sync' with 'sync*'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInvalidThisInInitializer = messageInvalidThisInInitializer;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidThisInInitializer = const MessageCode(
    "InvalidThisInInitializer",
    index: 65,
    message:
        r"""Can only use 'this' in an initializer for field initialization (e.g. 'this.x = something') and constructor redirection (e.g. 'this()' or 'this.namedConstructor())""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String name,
        String string2,
        String
            name2)> templateInvalidTypeVariableInSupertype = const Template<
        Message Function(String name, String string2, String name2)>(
    messageTemplate:
        r"""Can't use implicitly 'out' variable '#name' in an '#string2' position in supertype '#name2'.""",
    withArguments: _withArgumentsInvalidTypeVariableInSupertype);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String string2, String name2)>
    codeInvalidTypeVariableInSupertype =
    const Code<Message Function(String name, String string2, String name2)>(
  "InvalidTypeVariableInSupertype",
  templateInvalidTypeVariableInSupertype,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidTypeVariableInSupertype(
    String name, String string2, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (string2.isEmpty) throw 'No string provided';
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(codeInvalidTypeVariableInSupertype,
      message:
          """Can't use implicitly 'out' variable '${name}' in an '${string2}' position in supertype '${name2}'.""",
      arguments: {'name': name, 'string2': string2, 'name2': name2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(
            String string, String name, String string2, String name2)>
    templateInvalidTypeVariableInSupertypeWithVariance = const Template<
            Message Function(
                String string, String name, String string2, String name2)>(
        messageTemplate:
            r"""Can't use '#string' type variable '#name' in an '#string2' position in supertype '#name2'.""",
        withArguments:
            _withArgumentsInvalidTypeVariableInSupertypeWithVariance);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            String string, String name, String string2, String name2)>
    codeInvalidTypeVariableInSupertypeWithVariance = const Code<
        Message Function(
            String string, String name, String string2, String name2)>(
  "InvalidTypeVariableInSupertypeWithVariance",
  templateInvalidTypeVariableInSupertypeWithVariance,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidTypeVariableInSupertypeWithVariance(
    String string, String name, String string2, String name2) {
  if (string.isEmpty) throw 'No string provided';
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (string2.isEmpty) throw 'No string provided';
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(codeInvalidTypeVariableInSupertypeWithVariance,
      message:
          """Can't use '${string}' type variable '${name}' in an '${string2}' position in supertype '${name2}'.""",
      arguments: {
        'string': string,
        'name': name,
        'string2': string2,
        'name2': name2
      });
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String string,
        String name,
        String
            string2)> templateInvalidTypeVariableVariancePosition = const Template<
        Message Function(String string, String name, String string2)>(
    messageTemplate:
        r"""Can't use '#string' type variable '#name' in an '#string2' position.""",
    withArguments: _withArgumentsInvalidTypeVariableVariancePosition);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string, String name, String string2)>
    codeInvalidTypeVariableVariancePosition =
    const Code<Message Function(String string, String name, String string2)>(
  "InvalidTypeVariableVariancePosition",
  templateInvalidTypeVariableVariancePosition,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidTypeVariableVariancePosition(
    String string, String name, String string2) {
  if (string.isEmpty) throw 'No string provided';
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (string2.isEmpty) throw 'No string provided';
  return new Message(codeInvalidTypeVariableVariancePosition,
      message:
          """Can't use '${string}' type variable '${name}' in an '${string2}' position.""",
      arguments: {'string': string, 'name': name, 'string2': string2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string, String name, String string2)>
    templateInvalidTypeVariableVariancePositionInReturnType = const Template<
            Message Function(String string, String name, String string2)>(
        messageTemplate:
            r"""Can't use '#string' type variable '#name' in an '#string2' position in the return type.""",
        withArguments:
            _withArgumentsInvalidTypeVariableVariancePositionInReturnType);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string, String name, String string2)>
    codeInvalidTypeVariableVariancePositionInReturnType =
    const Code<Message Function(String string, String name, String string2)>(
  "InvalidTypeVariableVariancePositionInReturnType",
  templateInvalidTypeVariableVariancePositionInReturnType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidTypeVariableVariancePositionInReturnType(
    String string, String name, String string2) {
  if (string.isEmpty) throw 'No string provided';
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (string2.isEmpty) throw 'No string provided';
  return new Message(codeInvalidTypeVariableVariancePositionInReturnType,
      message:
          """Can't use '${string}' type variable '${name}' in an '${string2}' position in the return type.""",
      arguments: {'string': string, 'name': name, 'string2': string2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInvalidUnicodeEscape = messageInvalidUnicodeEscape;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidUnicodeEscape = const MessageCode(
    "InvalidUnicodeEscape",
    index: 38,
    message:
        r"""An escape sequence starting with '\u' must be followed by 4 hexadecimal digits or from 1 to 6 digits between '{' and '}'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInvalidUseOfNullAwareAccess =
    messageInvalidUseOfNullAwareAccess;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidUseOfNullAwareAccess = const MessageCode(
    "InvalidUseOfNullAwareAccess",
    analyzerCodes: <String>["INVALID_USE_OF_NULL_AWARE_ACCESS"],
    message: r"""Cannot use '?.' here.""",
    tip: r"""Try using '.'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInvalidVoid = messageInvalidVoid;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidVoid = const MessageCode("InvalidVoid",
    analyzerCodes: <String>["EXPECTED_TYPE_NAME"],
    message: r"""Type 'void' can't be used here.""",
    tip:
        r"""Try removing 'void' keyword or replace it with 'var', 'final', or a type.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateInvokeNonFunction =
    const Template<Message Function(String name)>(
        messageTemplate:
            r"""'#name' isn't a function or method and can't be invoked.""",
        withArguments: _withArgumentsInvokeNonFunction);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeInvokeNonFunction =
    const Code<Message Function(String name)>(
        "InvokeNonFunction", templateInvokeNonFunction,
        analyzerCodes: <String>["INVOCATION_OF_NON_FUNCTION"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvokeNonFunction(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeInvokeNonFunction,
      message: """'${name}' isn't a function or method and can't be invoked.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeJsInteropIndexNotSupported =
    messageJsInteropIndexNotSupported;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageJsInteropIndexNotSupported = const MessageCode(
    "JsInteropIndexNotSupported",
    message:
        r"""JS interop classes do not support [] and []= operator methods.""",
    tip: r"""Try replacing with a normal method.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeJsInteropNonExternalConstructor =
    messageJsInteropNonExternalConstructor;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageJsInteropNonExternalConstructor = const MessageCode(
    "JsInteropNonExternalConstructor",
    message:
        r"""JS interop classes do not support non-external constructors.""",
    tip: r"""Try annotating with `external`.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(String name)> templateLabelNotFound = const Template<
        Message Function(String name)>(
    messageTemplate: r"""Can't find label '#name'.""",
    tipTemplate:
        r"""Try defining the label, or correcting the name to match an existing label.""",
    withArguments: _withArgumentsLabelNotFound);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeLabelNotFound =
    const Code<Message Function(String name)>(
        "LabelNotFound", templateLabelNotFound,
        analyzerCodes: <String>["LABEL_UNDEFINED"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsLabelNotFound(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeLabelNotFound,
      message: """Can't find label '${name}'.""",
      tip:
          """Try defining the label, or correcting the name to match an existing label.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeLanguageVersionInvalidInDotPackages =
    messageLanguageVersionInvalidInDotPackages;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageLanguageVersionInvalidInDotPackages = const MessageCode(
    "LanguageVersionInvalidInDotPackages",
    message:
        r"""The language version is not specified correctly in the packages file.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeLanguageVersionLibraryContext =
    messageLanguageVersionLibraryContext;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageLanguageVersionLibraryContext = const MessageCode(
    "LanguageVersionLibraryContext",
    severity: Severity.context,
    message: r"""This is language version annotation in the library.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeLanguageVersionMismatchInPart =
    messageLanguageVersionMismatchInPart;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageLanguageVersionMismatchInPart = const MessageCode(
    "LanguageVersionMismatchInPart",
    message:
        r"""The language version override has to be the same in the library and its part(s).""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeLanguageVersionMismatchInPatch =
    messageLanguageVersionMismatchInPatch;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageLanguageVersionMismatchInPatch = const MessageCode(
    "LanguageVersionMismatchInPatch",
    message:
        r"""The language version override has to be the same in the library and its patch(es).""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeLanguageVersionPartContext =
    messageLanguageVersionPartContext;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageLanguageVersionPartContext = const MessageCode(
    "LanguageVersionPartContext",
    severity: Severity.context,
    message: r"""This is language version annotation in the part.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeLanguageVersionPatchContext =
    messageLanguageVersionPatchContext;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageLanguageVersionPatchContext = const MessageCode(
    "LanguageVersionPatchContext",
    severity: Severity.context,
    message: r"""This is language version annotation in the patch.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        int count,
        int
            count2)> templateLanguageVersionTooHigh = const Template<
        Message Function(int count, int count2)>(
    messageTemplate:
        r"""The specified language version is too high. The highest supported language version is #count.#count2.""",
    withArguments: _withArgumentsLanguageVersionTooHigh);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(int count, int count2)> codeLanguageVersionTooHigh =
    const Code<Message Function(int count, int count2)>(
  "LanguageVersionTooHigh",
  templateLanguageVersionTooHigh,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsLanguageVersionTooHigh(int count, int count2) {
  if (count == null) throw 'No count provided';
  if (count2 == null) throw 'No count provided';
  return new Message(codeLanguageVersionTooHigh,
      message:
          """The specified language version is too high. The highest supported language version is ${count}.${count2}.""",
      arguments: {'count': count, 'count2': count2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeLibraryDirectiveNotFirst = messageLibraryDirectiveNotFirst;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageLibraryDirectiveNotFirst = const MessageCode(
    "LibraryDirectiveNotFirst",
    index: 37,
    message:
        r"""The library directive must appear before all other directives.""",
    tip: r"""Try moving the library directive before any other directives.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeListLiteralTooManyTypeArguments =
    messageListLiteralTooManyTypeArguments;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageListLiteralTooManyTypeArguments = const MessageCode(
    "ListLiteralTooManyTypeArguments",
    analyzerCodes: <String>["EXPECTED_ONE_LIST_TYPE_ARGUMENTS"],
    message: r"""List literal requires exactly one type argument.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(Uri uri_)> templateLoadLibraryHidesMember = const Template<
        Message Function(Uri uri_)>(
    messageTemplate:
        r"""The library '#uri' defines a top-level member named 'loadLibrary'. This member is hidden by the special member 'loadLibrary' that the language adds to support deferred loading.""",
    tipTemplate: r"""Try to rename or hide the member.""",
    withArguments: _withArgumentsLoadLibraryHidesMember);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Uri uri_)> codeLoadLibraryHidesMember =
    const Code<Message Function(Uri uri_)>(
        "LoadLibraryHidesMember", templateLoadLibraryHidesMember,
        severity: Severity.ignored);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsLoadLibraryHidesMember(Uri uri_) {
  String uri = relativizeUri(uri_);
  return new Message(codeLoadLibraryHidesMember,
      message:
          """The library '${uri}' defines a top-level member named 'loadLibrary'. This member is hidden by the special member 'loadLibrary' that the language adds to support deferred loading.""",
      tip: """Try to rename or hide the member.""",
      arguments: {'uri': uri_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeLoadLibraryTakesNoArguments =
    messageLoadLibraryTakesNoArguments;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageLoadLibraryTakesNoArguments = const MessageCode(
    "LoadLibraryTakesNoArguments",
    analyzerCodes: <String>["LOAD_LIBRARY_TAKES_NO_ARGUMENTS"],
    message: r"""'loadLibrary' takes no arguments.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, Uri uri_)>
    templateLocalDefinitionHidesExport =
    const Template<Message Function(String name, Uri uri_)>(
        messageTemplate:
            r"""Local definition of '#name' hides export from '#uri'.""",
        withArguments: _withArgumentsLocalDefinitionHidesExport);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, Uri uri_)>
    codeLocalDefinitionHidesExport =
    const Code<Message Function(String name, Uri uri_)>(
        "LocalDefinitionHidesExport", templateLocalDefinitionHidesExport,
        severity: Severity.ignored);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsLocalDefinitionHidesExport(String name, Uri uri_) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  String uri = relativizeUri(uri_);
  return new Message(codeLocalDefinitionHidesExport,
      message: """Local definition of '${name}' hides export from '${uri}'.""",
      arguments: {'name': name, 'uri': uri_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, Uri uri_)>
    templateLocalDefinitionHidesImport =
    const Template<Message Function(String name, Uri uri_)>(
        messageTemplate:
            r"""Local definition of '#name' hides import from '#uri'.""",
        withArguments: _withArgumentsLocalDefinitionHidesImport);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, Uri uri_)>
    codeLocalDefinitionHidesImport =
    const Code<Message Function(String name, Uri uri_)>(
        "LocalDefinitionHidesImport", templateLocalDefinitionHidesImport,
        severity: Severity.ignored);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsLocalDefinitionHidesImport(String name, Uri uri_) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  String uri = relativizeUri(uri_);
  return new Message(codeLocalDefinitionHidesImport,
      message: """Local definition of '${name}' hides import from '${uri}'.""",
      arguments: {'name': name, 'uri': uri_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMapLiteralTypeArgumentMismatch =
    messageMapLiteralTypeArgumentMismatch;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMapLiteralTypeArgumentMismatch = const MessageCode(
    "MapLiteralTypeArgumentMismatch",
    analyzerCodes: <String>["EXPECTED_TWO_MAP_TYPE_ARGUMENTS"],
    message: r"""A map literal requires exactly two type arguments.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMemberWithSameNameAsClass =
    messageMemberWithSameNameAsClass;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMemberWithSameNameAsClass = const MessageCode(
    "MemberWithSameNameAsClass",
    index: 105,
    message:
        r"""A class member can't have the same name as the enclosing class.""",
    tip: r"""Try renaming the member.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMetadataTypeArguments = messageMetadataTypeArguments;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMetadataTypeArguments = const MessageCode(
    "MetadataTypeArguments",
    index: 91,
    message: r"""An annotation (metadata) can't use type arguments.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateMethodNotFound =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Method not found: '#name'.""",
        withArguments: _withArgumentsMethodNotFound);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeMethodNotFound =
    const Code<Message Function(String name)>(
        "MethodNotFound", templateMethodNotFound,
        analyzerCodes: <String>["UNDEFINED_METHOD"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMethodNotFound(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeMethodNotFound,
      message: """Method not found: '${name}'.""", arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMissingArgumentList = messageMissingArgumentList;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingArgumentList = const MessageCode(
    "MissingArgumentList",
    message: r"""Constructor invocations must have an argument list.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMissingAssignableSelector =
    messageMissingAssignableSelector;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingAssignableSelector = const MessageCode(
    "MissingAssignableSelector",
    index: 35,
    message: r"""Missing selector such as '.identifier' or '[0]'.""",
    tip: r"""Try adding a selector.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMissingAssignmentInInitializer =
    messageMissingAssignmentInInitializer;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingAssignmentInInitializer = const MessageCode(
    "MissingAssignmentInInitializer",
    index: 34,
    message: r"""Expected an assignment after the field name.""",
    tip: r"""To initialize a field, use the syntax 'name = value'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMissingConstFinalVarOrType =
    messageMissingConstFinalVarOrType;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingConstFinalVarOrType = const MessageCode(
    "MissingConstFinalVarOrType",
    index: 33,
    message:
        r"""Variables must be declared using the keywords 'const', 'final', 'var' or a type name.""",
    tip:
        r"""Try adding the name of the type of the variable or the keyword 'var'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMissingExplicitConst = messageMissingExplicitConst;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingExplicitConst = const MessageCode(
    "MissingExplicitConst",
    analyzerCodes: <String>["NOT_CONSTANT_EXPRESSION"],
    message: r"""Constant expression expected.""",
    tip: r"""Try inserting 'const'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(int count)>
    templateMissingExplicitTypeArguments =
    const Template<Message Function(int count)>(
        messageTemplate: r"""No type arguments provided, #count possible.""",
        withArguments: _withArgumentsMissingExplicitTypeArguments);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(int count)> codeMissingExplicitTypeArguments =
    const Code<Message Function(int count)>(
        "MissingExplicitTypeArguments", templateMissingExplicitTypeArguments,
        severity: Severity.ignored);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMissingExplicitTypeArguments(int count) {
  if (count == null) throw 'No count provided';
  return new Message(codeMissingExplicitTypeArguments,
      message: """No type arguments provided, ${count} possible.""",
      arguments: {'count': count});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMissingExponent = messageMissingExponent;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingExponent = const MessageCode("MissingExponent",
    analyzerCodes: <String>["MISSING_DIGIT"],
    message:
        r"""Numbers in exponential notation should always contain an exponent (an integer number with an optional sign).""",
    tip:
        r"""Make sure there is an exponent, and remove any whitespace before it.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMissingExpressionInThrow = messageMissingExpressionInThrow;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingExpressionInThrow = const MessageCode(
    "MissingExpressionInThrow",
    index: 32,
    message: r"""Missing expression after 'throw'.""",
    tip:
        r"""Add an expression after 'throw' or use 'rethrow' to throw a caught exception""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMissingFunctionParameters =
    messageMissingFunctionParameters;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingFunctionParameters = const MessageCode(
    "MissingFunctionParameters",
    analyzerCodes: <String>["MISSING_FUNCTION_PARAMETERS"],
    message:
        r"""A function declaration needs an explicit list of parameters.""",
    tip: r"""Try adding a parameter list to the function declaration.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateMissingImplementationCause =
    const Template<Message Function(String name)>(
        messageTemplate: r"""'#name' is defined here.""",
        withArguments: _withArgumentsMissingImplementationCause);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeMissingImplementationCause =
    const Code<Message Function(String name)>(
        "MissingImplementationCause", templateMissingImplementationCause,
        severity: Severity.context);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMissingImplementationCause(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeMissingImplementationCause,
      message: """'${name}' is defined here.""", arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String name,
        List<String>
            _names)> templateMissingImplementationNotAbstract = const Template<
        Message Function(String name, List<String> _names)>(
    messageTemplate:
        r"""The non-abstract class '#name' is missing implementations for these members:
#names""",
    tipTemplate: r"""Try to either
 - provide an implementation,
 - inherit an implementation from a superclass or mixin,
 - mark the class as abstract, or
 - provide a 'noSuchMethod' implementation.
""",
    withArguments: _withArgumentsMissingImplementationNotAbstract);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, List<String> _names)>
    codeMissingImplementationNotAbstract =
    const Code<Message Function(String name, List<String> _names)>(
        "MissingImplementationNotAbstract",
        templateMissingImplementationNotAbstract,
        analyzerCodes: <String>["CONCRETE_CLASS_WITH_ABSTRACT_MEMBER"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMissingImplementationNotAbstract(
    String name, List<String> _names) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (_names.isEmpty) throw 'No names provided';
  String names = itemizeNames(_names);
  return new Message(codeMissingImplementationNotAbstract,
      message:
          """The non-abstract class '${name}' is missing implementations for these members:
${names}""",
      tip: """Try to either
 - provide an implementation,
 - inherit an implementation from a superclass or mixin,
 - mark the class as abstract, or
 - provide a 'noSuchMethod' implementation.
""",
      arguments: {'name': name, 'names': _names});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMissingInput = messageMissingInput;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingInput = const MessageCode("MissingInput",
    message: r"""No input file provided to the compiler.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMissingMain = messageMissingMain;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingMain = const MessageCode("MissingMain",
    message: r"""No 'main' method found.""",
    tip: r"""Try adding a method named 'main' to your program.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMissingMethodParameters = messageMissingMethodParameters;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingMethodParameters = const MessageCode(
    "MissingMethodParameters",
    analyzerCodes: <String>["MISSING_METHOD_PARAMETERS"],
    message: r"""A method declaration needs an explicit list of parameters.""",
    tip: r"""Try adding a parameter list to the method declaration.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMissingOperatorKeyword = messageMissingOperatorKeyword;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingOperatorKeyword = const MessageCode(
    "MissingOperatorKeyword",
    index: 31,
    message:
        r"""Operator declarations must be preceded by the keyword 'operator'.""",
    tip: r"""Try adding the keyword 'operator'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(Uri uri_)> templateMissingPartOf = const Template<
        Message Function(Uri uri_)>(
    messageTemplate:
        r"""Can't use '#uri' as a part, because it has no 'part of' declaration.""",
    withArguments: _withArgumentsMissingPartOf);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Uri uri_)> codeMissingPartOf =
    const Code<Message Function(Uri uri_)>(
        "MissingPartOf", templateMissingPartOf,
        analyzerCodes: <String>["PART_OF_NON_PART"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMissingPartOf(Uri uri_) {
  String uri = relativizeUri(uri_);
  return new Message(codeMissingPartOf,
      message:
          """Can't use '${uri}' as a part, because it has no 'part of' declaration.""",
      arguments: {'uri': uri_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMissingPrefixInDeferredImport =
    messageMissingPrefixInDeferredImport;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingPrefixInDeferredImport = const MessageCode(
    "MissingPrefixInDeferredImport",
    index: 30,
    message: r"""Deferred imports should have a prefix.""",
    tip: r"""Try adding a prefix to the import by adding an 'as' clause.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMissingTypedefParameters = messageMissingTypedefParameters;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingTypedefParameters = const MessageCode(
    "MissingTypedefParameters",
    analyzerCodes: <String>["MISSING_TYPEDEF_PARAMETERS"],
    message: r"""A typedef needs an explicit list of parameters.""",
    tip: r"""Try adding a parameter list to the typedef.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMixinDeclaresConstructor = messageMixinDeclaresConstructor;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMixinDeclaresConstructor = const MessageCode(
    "MixinDeclaresConstructor",
    index: 95,
    message: r"""Mixins can't declare constructors.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMixinFunction = messageMixinFunction;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMixinFunction = const MessageCode("MixinFunction",
    severity: Severity.ignored,
    message: r"""Mixing in 'Function' is deprecated.""",
    tip: r"""Try removing 'Function' from the 'with' clause.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String string,
        String
            string2)> templateModifierOutOfOrder = const Template<
        Message Function(String string, String string2)>(
    messageTemplate:
        r"""The modifier '#string' should be before the modifier '#string2'.""",
    tipTemplate: r"""Try re-ordering the modifiers.""",
    withArguments: _withArgumentsModifierOutOfOrder);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string, String string2)>
    codeModifierOutOfOrder =
    const Code<Message Function(String string, String string2)>(
        "ModifierOutOfOrder", templateModifierOutOfOrder,
        index: 56);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsModifierOutOfOrder(String string, String string2) {
  if (string.isEmpty) throw 'No string provided';
  if (string2.isEmpty) throw 'No string provided';
  return new Message(codeModifierOutOfOrder,
      message:
          """The modifier '${string}' should be before the modifier '${string2}'.""",
      tip: """Try re-ordering the modifiers.""",
      arguments: {'string': string, 'string2': string2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMoreThanOneSuperOrThisInitializer =
    messageMoreThanOneSuperOrThisInitializer;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMoreThanOneSuperOrThisInitializer = const MessageCode(
    "MoreThanOneSuperOrThisInitializer",
    analyzerCodes: <String>["SUPER_IN_REDIRECTING_CONSTRUCTOR"],
    message: r"""Can't have more than one 'super' or 'this' initializer.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMultipleExtends = messageMultipleExtends;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMultipleExtends = const MessageCode("MultipleExtends",
    index: 28,
    message: r"""Each class definition can have at most one extends clause.""",
    tip:
        r"""Try choosing one superclass and define your class to implement (or mix in) the others.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMultipleImplements = messageMultipleImplements;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMultipleImplements = const MessageCode(
    "MultipleImplements",
    analyzerCodes: <String>["MULTIPLE_IMPLEMENTS_CLAUSES"],
    message:
        r"""Each class definition can have at most one implements clause.""",
    tip:
        r"""Try combining all of the implements clauses into a single clause.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMultipleLibraryDirectives =
    messageMultipleLibraryDirectives;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMultipleLibraryDirectives = const MessageCode(
    "MultipleLibraryDirectives",
    index: 27,
    message: r"""Only one library directive may be declared in a file.""",
    tip: r"""Try removing all but one of the library directives.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMultipleOnClauses = messageMultipleOnClauses;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMultipleOnClauses = const MessageCode(
    "MultipleOnClauses",
    index: 26,
    message: r"""Each mixin definition can have at most one on clause.""",
    tip: r"""Try combining all of the on clauses into a single clause.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMultipleVarianceModifiers =
    messageMultipleVarianceModifiers;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMultipleVarianceModifiers = const MessageCode(
    "MultipleVarianceModifiers",
    index: 97,
    message: r"""Each type parameter can have at most one variance modifier.""",
    tip: r"""Use at most one of the 'in', 'out', or 'inout' modifiers.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMultipleWith = messageMultipleWith;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMultipleWith = const MessageCode("MultipleWith",
    index: 24,
    message: r"""Each class definition can have at most one with clause.""",
    tip: r"""Try combining all of the with clauses into a single clause.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeNamedFunctionExpression = messageNamedFunctionExpression;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNamedFunctionExpression = const MessageCode(
    "NamedFunctionExpression",
    analyzerCodes: <String>["NAMED_FUNCTION_EXPRESSION"],
    message: r"""A function expression can't have a name.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String name,
        String
            name2)> templateNamedMixinOverride = const Template<
        Message Function(String name, String name2)>(
    messageTemplate:
        r"""The mixin application class '#name' introduces an erroneous override of '#name2'.""",
    withArguments: _withArgumentsNamedMixinOverride);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String name2)> codeNamedMixinOverride =
    const Code<Message Function(String name, String name2)>(
  "NamedMixinOverride",
  templateNamedMixinOverride,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNamedMixinOverride(String name, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(codeNamedMixinOverride,
      message:
          """The mixin application class '${name}' introduces an erroneous override of '${name2}'.""",
      arguments: {'name': name, 'name2': name2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeNativeClauseShouldBeAnnotation =
    messageNativeClauseShouldBeAnnotation;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNativeClauseShouldBeAnnotation = const MessageCode(
    "NativeClauseShouldBeAnnotation",
    index: 23,
    message: r"""Native clause in this form is deprecated.""",
    tip:
        r"""Try removing this native clause and adding @native() or @native('native-name') before the declaration.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(Token token)> templateNoFormals = const Template<
        Message Function(Token token)>(
    messageTemplate: r"""A function should have formal parameters.""",
    tipTemplate:
        r"""Try adding '()' after '#lexeme', or add 'get' before '#lexeme' to declare a getter.""",
    withArguments: _withArgumentsNoFormals);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeNoFormals =
    const Code<Message Function(Token token)>("NoFormals", templateNoFormals,
        analyzerCodes: <String>["MISSING_FUNCTION_PARAMETERS"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNoFormals(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeNoFormals,
      message: """A function should have formal parameters.""",
      tip:
          """Try adding '()' after '${lexeme}', or add 'get' before '${lexeme}' to declare a getter.""",
      arguments: {'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateNoSuchNamedParameter =
    const Template<Message Function(String name)>(
        messageTemplate: r"""No named parameter with the name '#name'.""",
        withArguments: _withArgumentsNoSuchNamedParameter);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeNoSuchNamedParameter =
    const Code<Message Function(String name)>(
        "NoSuchNamedParameter", templateNoSuchNamedParameter,
        analyzerCodes: <String>["UNDEFINED_NAMED_PARAMETER"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNoSuchNamedParameter(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeNoSuchNamedParameter,
      message: """No named parameter with the name '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeNoUnnamedConstructorInObject =
    messageNoUnnamedConstructorInObject;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNoUnnamedConstructorInObject = const MessageCode(
    "NoUnnamedConstructorInObject",
    message: r"""'Object' has no unnamed constructor.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeNonAgnosticConstant = messageNonAgnosticConstant;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNonAgnosticConstant = const MessageCode(
    "NonAgnosticConstant",
    message: r"""Constant value is not strong/weak mode agnostic.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String character,
        int
            codePoint)> templateNonAsciiIdentifier = const Template<
        Message Function(String character, int codePoint)>(
    messageTemplate:
        r"""The non-ASCII character '#character' (#unicode) can't be used in identifiers, only in strings and comments.""",
    tipTemplate:
        r"""Try using an US-ASCII letter, a digit, '_' (an underscore), or '$' (a dollar sign).""",
    withArguments: _withArgumentsNonAsciiIdentifier);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String character, int codePoint)>
    codeNonAsciiIdentifier =
    const Code<Message Function(String character, int codePoint)>(
        "NonAsciiIdentifier", templateNonAsciiIdentifier,
        analyzerCodes: <String>["ILLEGAL_CHARACTER"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonAsciiIdentifier(String character, int codePoint) {
  if (character.runes.length != 1) throw "Not a character '${character}'";
  String unicode =
      "U+${codePoint.toRadixString(16).toUpperCase().padLeft(4, '0')}";
  return new Message(codeNonAsciiIdentifier,
      message:
          """The non-ASCII character '${character}' (${unicode}) can't be used in identifiers, only in strings and comments.""",
      tip: """Try using an US-ASCII letter, a digit, '_' (an underscore), or '\$' (a dollar sign).""",
      arguments: {'character': character, 'codePoint': codePoint});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        int
            codePoint)> templateNonAsciiWhitespace = const Template<
        Message Function(int codePoint)>(
    messageTemplate:
        r"""The non-ASCII space character #unicode can only be used in strings and comments.""",
    withArguments: _withArgumentsNonAsciiWhitespace);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(int codePoint)> codeNonAsciiWhitespace =
    const Code<Message Function(int codePoint)>(
        "NonAsciiWhitespace", templateNonAsciiWhitespace,
        analyzerCodes: <String>["ILLEGAL_CHARACTER"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonAsciiWhitespace(int codePoint) {
  String unicode =
      "U+${codePoint.toRadixString(16).toUpperCase().padLeft(4, '0')}";
  return new Message(codeNonAsciiWhitespace,
      message:
          """The non-ASCII space character ${unicode} can only be used in strings and comments.""",
      arguments: {'codePoint': codePoint});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeNonConstConstructor = messageNonConstConstructor;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNonConstConstructor = const MessageCode(
    "NonConstConstructor",
    analyzerCodes: <String>["NOT_CONSTANT_EXPRESSION"],
    message:
        r"""Cannot invoke a non-'const' constructor where a const expression is expected.""",
    tip: r"""Try using a constructor or factory that is 'const'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeNonConstFactory = messageNonConstFactory;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNonConstFactory = const MessageCode("NonConstFactory",
    analyzerCodes: <String>["NOT_CONSTANT_EXPRESSION"],
    message:
        r"""Cannot invoke a non-'const' factory where a const expression is expected.""",
    tip: r"""Try using a constructor or factory that is 'const'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeNonInstanceTypeVariableUse =
    messageNonInstanceTypeVariableUse;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNonInstanceTypeVariableUse = const MessageCode(
    "NonInstanceTypeVariableUse",
    analyzerCodes: <String>["TYPE_PARAMETER_REFERENCED_BY_STATIC"],
    message: r"""Can only use type variables in instance methods.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeNonNullAwareSpreadIsNull = messageNonNullAwareSpreadIsNull;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNonNullAwareSpreadIsNull = const MessageCode(
    "NonNullAwareSpreadIsNull",
    message: r"""Can't spread a value with static type Null.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateNonNullableLateDefinitelyAssignedError =
    const Template<Message Function(String name)>(
        messageTemplate:
            r"""Non-nullable late final variable '#name' definitely assigned.""",
        withArguments: _withArgumentsNonNullableLateDefinitelyAssignedError);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)>
    codeNonNullableLateDefinitelyAssignedError =
    const Code<Message Function(String name)>(
  "NonNullableLateDefinitelyAssignedError",
  templateNonNullableLateDefinitelyAssignedError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonNullableLateDefinitelyAssignedError(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeNonNullableLateDefinitelyAssignedError,
      message:
          """Non-nullable late final variable '${name}' definitely assigned.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateNonNullableLateDefinitelyUnassignedError =
    const Template<Message Function(String name)>(
        messageTemplate:
            r"""Non-nullable late variable '#name' without initializer is definitely unassigned.""",
        withArguments: _withArgumentsNonNullableLateDefinitelyUnassignedError);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)>
    codeNonNullableLateDefinitelyUnassignedError =
    const Code<Message Function(String name)>(
  "NonNullableLateDefinitelyUnassignedError",
  templateNonNullableLateDefinitelyUnassignedError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonNullableLateDefinitelyUnassignedError(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeNonNullableLateDefinitelyUnassignedError,
      message:
          """Non-nullable late variable '${name}' without initializer is definitely unassigned.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            name)> templateNonNullableNotAssignedError = const Template<
        Message Function(String name)>(
    messageTemplate:
        r"""Non-nullable variable '#name' must be assigned before it can be used.""",
    withArguments: _withArgumentsNonNullableNotAssignedError);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeNonNullableNotAssignedError =
    const Code<Message Function(String name)>(
  "NonNullableNotAssignedError",
  templateNonNullableNotAssignedError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonNullableNotAssignedError(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeNonNullableNotAssignedError,
      message:
          """Non-nullable variable '${name}' must be assigned before it can be used.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeNonNullableOptOut = messageNonNullableOptOut;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNonNullableOptOut = const MessageCode(
    "NonNullableOptOut",
    message: r"""Null safety features are disabled for this library.""",
    tip:
        r"""Try removing the `@dart=` annotation or setting the language version higher.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeNonNullableOptOutComment = messageNonNullableOptOutComment;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNonNullableOptOutComment = const MessageCode(
    "NonNullableOptOutComment",
    severity: Severity.context,
    message:
        r"""This is the annotation that opts out this library from null safety features.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeNonPartOfDirectiveInPart = messageNonPartOfDirectiveInPart;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNonPartOfDirectiveInPart = const MessageCode(
    "NonPartOfDirectiveInPart",
    analyzerCodes: <String>["NON_PART_OF_DIRECTIVE_IN_PART"],
    message: r"""The part-of directive must be the only directive in a part.""",
    tip:
        r"""Try removing the other directives, or moving them to the library for which this is a part.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateNonSimpleBoundViaReference =
    const Template<Message Function(String name)>(
        messageTemplate:
            r"""Bound of this variable references raw type '#name'.""",
        withArguments: _withArgumentsNonSimpleBoundViaReference);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeNonSimpleBoundViaReference =
    const Code<Message Function(String name)>(
        "NonSimpleBoundViaReference", templateNonSimpleBoundViaReference,
        severity: Severity.context);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonSimpleBoundViaReference(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeNonSimpleBoundViaReference,
      message: """Bound of this variable references raw type '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            name)> templateNonSimpleBoundViaVariable = const Template<
        Message Function(String name)>(
    messageTemplate:
        r"""Bound of this variable references variable '#name' from the same declaration.""",
    withArguments: _withArgumentsNonSimpleBoundViaVariable);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeNonSimpleBoundViaVariable =
    const Code<Message Function(String name)>(
        "NonSimpleBoundViaVariable", templateNonSimpleBoundViaVariable,
        severity: Severity.context);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonSimpleBoundViaVariable(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeNonSimpleBoundViaVariable,
      message:
          """Bound of this variable references variable '${name}' from the same declaration.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeNotAConstantExpression = messageNotAConstantExpression;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNotAConstantExpression = const MessageCode(
    "NotAConstantExpression",
    analyzerCodes: <String>["NOT_CONSTANT_EXPRESSION"],
    message: r"""Not a constant expression.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String name,
        String
            name2)> templateNotAPrefixInTypeAnnotation = const Template<
        Message Function(String name, String name2)>(
    messageTemplate:
        r"""'#name.#name2' can't be used as a type because '#name' doesn't refer to an import prefix.""",
    withArguments: _withArgumentsNotAPrefixInTypeAnnotation);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String name2)>
    codeNotAPrefixInTypeAnnotation =
    const Code<Message Function(String name, String name2)>(
        "NotAPrefixInTypeAnnotation", templateNotAPrefixInTypeAnnotation,
        analyzerCodes: <String>["NOT_A_TYPE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNotAPrefixInTypeAnnotation(String name, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(codeNotAPrefixInTypeAnnotation,
      message:
          """'${name}.${name2}' can't be used as a type because '${name}' doesn't refer to an import prefix.""",
      arguments: {'name': name, 'name2': name2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateNotAType =
    const Template<Message Function(String name)>(
        messageTemplate: r"""'#name' isn't a type.""",
        withArguments: _withArgumentsNotAType);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeNotAType =
    const Code<Message Function(String name)>("NotAType", templateNotAType,
        analyzerCodes: <String>["NOT_A_TYPE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNotAType(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeNotAType,
      message: """'${name}' isn't a type.""", arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeNotATypeContext = messageNotATypeContext;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNotATypeContext = const MessageCode("NotATypeContext",
    severity: Severity.context, message: r"""This isn't a type.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeNotAnLvalue = messageNotAnLvalue;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNotAnLvalue = const MessageCode("NotAnLvalue",
    analyzerCodes: <String>["NOT_AN_LVALUE"],
    message: r"""Can't assign to this.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateNotBinaryOperator =
    const Template<Message Function(Token token)>(
        messageTemplate: r"""'#lexeme' isn't a binary operator.""",
        withArguments: _withArgumentsNotBinaryOperator);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeNotBinaryOperator =
    const Code<Message Function(Token token)>(
  "NotBinaryOperator",
  templateNotBinaryOperator,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNotBinaryOperator(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeNotBinaryOperator,
      message: """'${lexeme}' isn't a binary operator.""",
      arguments: {'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)> templateNotConstantExpression =
    const Template<Message Function(String string)>(
        messageTemplate: r"""#string is not a constant expression.""",
        withArguments: _withArgumentsNotConstantExpression);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string)> codeNotConstantExpression =
    const Code<Message Function(String string)>(
        "NotConstantExpression", templateNotConstantExpression,
        analyzerCodes: <String>["NOT_CONSTANT_EXPRESSION"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNotConstantExpression(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeNotConstantExpression,
      message: """${string} is not a constant expression.""",
      arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeNullAwareCascadeOutOfOrder =
    messageNullAwareCascadeOutOfOrder;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNullAwareCascadeOutOfOrder = const MessageCode(
    "NullAwareCascadeOutOfOrder",
    index: 96,
    message:
        r"""The '?..' cascade operator must be first in the cascade sequence.""",
    tip:
        r"""Try moving the '?..' operator to be the first cascade operator in the sequence.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateNullableInterfaceError =
    const Template<Message Function(String name)>(
        messageTemplate:
            r"""Can't implement '#name' because it's marked with '?'.""",
        withArguments: _withArgumentsNullableInterfaceError);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeNullableInterfaceError =
    const Code<Message Function(String name)>(
  "NullableInterfaceError",
  templateNullableInterfaceError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNullableInterfaceError(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeNullableInterfaceError,
      message: """Can't implement '${name}' because it's marked with '?'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateNullableMixinError =
    const Template<Message Function(String name)>(
        messageTemplate:
            r"""Can't mix '#name' in because it's marked with '?'.""",
        withArguments: _withArgumentsNullableMixinError);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeNullableMixinError =
    const Code<Message Function(String name)>(
  "NullableMixinError",
  templateNullableMixinError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNullableMixinError(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeNullableMixinError,
      message: """Can't mix '${name}' in because it's marked with '?'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateNullableSuperclassError =
    const Template<Message Function(String name)>(
        messageTemplate:
            r"""Can't extend '#name' because it's marked with '?'.""",
        withArguments: _withArgumentsNullableSuperclassError);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeNullableSuperclassError =
    const Code<Message Function(String name)>(
  "NullableSuperclassError",
  templateNullableSuperclassError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNullableSuperclassError(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeNullableSuperclassError,
      message: """Can't extend '${name}' because it's marked with '?'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateNullableTearoffError =
    const Template<Message Function(String name)>(
        messageTemplate:
            r"""Can't tear off method '#name' from a potentially null value.""",
        withArguments: _withArgumentsNullableTearoffError);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeNullableTearoffError =
    const Code<Message Function(String name)>(
  "NullableTearoffError",
  templateNullableTearoffError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNullableTearoffError(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeNullableTearoffError,
      message:
          """Can't tear off method '${name}' from a potentially null value.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeObjectExtends = messageObjectExtends;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageObjectExtends = const MessageCode("ObjectExtends",
    message: r"""The class 'Object' can't have a superclass.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeObjectImplements = messageObjectImplements;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageObjectImplements = const MessageCode(
    "ObjectImplements",
    message: r"""The class 'Object' can't implement anything.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeObjectMixesIn = messageObjectMixesIn;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageObjectMixesIn = const MessageCode("ObjectMixesIn",
    message: r"""The class 'Object' can't use mixins.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeOnlyTry = messageOnlyTry;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageOnlyTry = const MessageCode("OnlyTry",
    index: 20,
    message:
        r"""A try block must be followed by an 'on', 'catch', or 'finally' clause.""",
    tip:
        r"""Try adding either a catch or finally clause, or remove the try statement.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            name)> templateOperatorMinusParameterMismatch = const Template<
        Message Function(String name)>(
    messageTemplate: r"""Operator '#name' should have zero or one parameter.""",
    tipTemplate:
        r"""With zero parameters, it has the syntactic form '-a', formally known as 'unary-'. With one parameter, it has the syntactic form 'a - b', formally known as '-'.""",
    withArguments: _withArgumentsOperatorMinusParameterMismatch);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeOperatorMinusParameterMismatch =
    const Code<Message Function(String name)>("OperatorMinusParameterMismatch",
        templateOperatorMinusParameterMismatch, analyzerCodes: <String>[
  "WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR_MINUS"
]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOperatorMinusParameterMismatch(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeOperatorMinusParameterMismatch,
      message: """Operator '${name}' should have zero or one parameter.""",
      tip:
          """With zero parameters, it has the syntactic form '-a', formally known as 'unary-'. With one parameter, it has the syntactic form 'a - b', formally known as '-'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateOperatorParameterMismatch0 =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Operator '#name' shouldn't have any parameters.""",
        withArguments: _withArgumentsOperatorParameterMismatch0);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeOperatorParameterMismatch0 =
    const Code<Message Function(String name)>(
  "OperatorParameterMismatch0",
  templateOperatorParameterMismatch0,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOperatorParameterMismatch0(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeOperatorParameterMismatch0,
      message: """Operator '${name}' shouldn't have any parameters.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateOperatorParameterMismatch1 =
    const Template<Message Function(String name)>(
        messageTemplate:
            r"""Operator '#name' should have exactly one parameter.""",
        withArguments: _withArgumentsOperatorParameterMismatch1);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeOperatorParameterMismatch1 =
    const Code<Message Function(String name)>(
        "OperatorParameterMismatch1", templateOperatorParameterMismatch1,
        analyzerCodes: <String>["WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOperatorParameterMismatch1(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeOperatorParameterMismatch1,
      message: """Operator '${name}' should have exactly one parameter.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateOperatorParameterMismatch2 =
    const Template<Message Function(String name)>(
        messageTemplate:
            r"""Operator '#name' should have exactly two parameters.""",
        withArguments: _withArgumentsOperatorParameterMismatch2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeOperatorParameterMismatch2 =
    const Code<Message Function(String name)>(
        "OperatorParameterMismatch2", templateOperatorParameterMismatch2,
        analyzerCodes: <String>["WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOperatorParameterMismatch2(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeOperatorParameterMismatch2,
      message: """Operator '${name}' should have exactly two parameters.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeOperatorWithOptionalFormals =
    messageOperatorWithOptionalFormals;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageOperatorWithOptionalFormals = const MessageCode(
    "OperatorWithOptionalFormals",
    message: r"""An operator can't have optional parameters.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeOperatorWithTypeParameters =
    messageOperatorWithTypeParameters;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageOperatorWithTypeParameters = const MessageCode(
    "OperatorWithTypeParameters",
    analyzerCodes: <String>["TYPE_PARAMETER_ON_OPERATOR"],
    message: r"""Types parameters aren't allowed when defining an operator.""",
    tip: r"""Try removing the type parameters.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateOverriddenMethodCause =
    const Template<Message Function(String name)>(
        messageTemplate: r"""This is the overridden method ('#name').""",
        withArguments: _withArgumentsOverriddenMethodCause);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeOverriddenMethodCause =
    const Code<Message Function(String name)>(
        "OverriddenMethodCause", templateOverriddenMethodCause,
        severity: Severity.context);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverriddenMethodCause(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeOverriddenMethodCause,
      message: """This is the overridden method ('${name}').""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String name,
        String
            name2)> templateOverrideFewerNamedArguments = const Template<
        Message Function(String name, String name2)>(
    messageTemplate:
        r"""The method '#name' has fewer named arguments than those of overridden method '#name2'.""",
    withArguments: _withArgumentsOverrideFewerNamedArguments);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String name2)>
    codeOverrideFewerNamedArguments =
    const Code<Message Function(String name, String name2)>(
        "OverrideFewerNamedArguments", templateOverrideFewerNamedArguments,
        analyzerCodes: <String>["INVALID_OVERRIDE_NAMED"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideFewerNamedArguments(String name, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(codeOverrideFewerNamedArguments,
      message:
          """The method '${name}' has fewer named arguments than those of overridden method '${name2}'.""",
      arguments: {'name': name, 'name2': name2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String name,
        String
            name2)> templateOverrideFewerPositionalArguments = const Template<
        Message Function(String name, String name2)>(
    messageTemplate:
        r"""The method '#name' has fewer positional arguments than those of overridden method '#name2'.""",
    withArguments: _withArgumentsOverrideFewerPositionalArguments);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String name2)>
    codeOverrideFewerPositionalArguments =
    const Code<Message Function(String name, String name2)>(
        "OverrideFewerPositionalArguments",
        templateOverrideFewerPositionalArguments,
        analyzerCodes: <String>["INVALID_OVERRIDE_POSITIONAL"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideFewerPositionalArguments(
    String name, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(codeOverrideFewerPositionalArguments,
      message:
          """The method '${name}' has fewer positional arguments than those of overridden method '${name2}'.""",
      arguments: {'name': name, 'name2': name2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String name,
        String name2,
        String
            name3)> templateOverrideMismatchNamedParameter = const Template<
        Message Function(String name, String name2, String name3)>(
    messageTemplate:
        r"""The method '#name' doesn't have the named parameter '#name2' of overridden method '#name3'.""",
    withArguments: _withArgumentsOverrideMismatchNamedParameter);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String name2, String name3)>
    codeOverrideMismatchNamedParameter =
    const Code<Message Function(String name, String name2, String name3)>(
        "OverrideMismatchNamedParameter",
        templateOverrideMismatchNamedParameter,
        analyzerCodes: <String>["INVALID_OVERRIDE_NAMED"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideMismatchNamedParameter(
    String name, String name2, String name3) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  if (name3.isEmpty) throw 'No name provided';
  name3 = demangleMixinApplicationName(name3);
  return new Message(codeOverrideMismatchNamedParameter,
      message:
          """The method '${name}' doesn't have the named parameter '${name2}' of overridden method '${name3}'.""",
      arguments: {'name': name, 'name2': name2, 'name3': name3});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String name2, String name3)>
    templateOverrideMismatchRequiredNamedParameter =
    const Template<Message Function(String name, String name2, String name3)>(
        messageTemplate:
            r"""The required named parameter '#name' in method '#name2' is not required in overridden method '#name3'.""",
        withArguments: _withArgumentsOverrideMismatchRequiredNamedParameter);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String name2, String name3)>
    codeOverrideMismatchRequiredNamedParameter =
    const Code<Message Function(String name, String name2, String name3)>(
  "OverrideMismatchRequiredNamedParameter",
  templateOverrideMismatchRequiredNamedParameter,
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
  return new Message(codeOverrideMismatchRequiredNamedParameter,
      message:
          """The required named parameter '${name}' in method '${name2}' is not required in overridden method '${name3}'.""",
      arguments: {'name': name, 'name2': name2, 'name3': name3});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String name,
        String
            name2)> templateOverrideMoreRequiredArguments = const Template<
        Message Function(String name, String name2)>(
    messageTemplate:
        r"""The method '#name' has more required arguments than those of overridden method '#name2'.""",
    withArguments: _withArgumentsOverrideMoreRequiredArguments);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String name2)>
    codeOverrideMoreRequiredArguments =
    const Code<Message Function(String name, String name2)>(
        "OverrideMoreRequiredArguments", templateOverrideMoreRequiredArguments,
        analyzerCodes: <String>["INVALID_OVERRIDE_REQUIRED"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideMoreRequiredArguments(String name, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(codeOverrideMoreRequiredArguments,
      message:
          """The method '${name}' has more required arguments than those of overridden method '${name2}'.""",
      arguments: {'name': name, 'name2': name2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String name,
        String
            name2)> templateOverrideTypeVariablesMismatch = const Template<
        Message Function(String name, String name2)>(
    messageTemplate:
        r"""Declared type variables of '#name' doesn't match those on overridden method '#name2'.""",
    withArguments: _withArgumentsOverrideTypeVariablesMismatch);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String name2)>
    codeOverrideTypeVariablesMismatch =
    const Code<Message Function(String name, String name2)>(
        "OverrideTypeVariablesMismatch", templateOverrideTypeVariablesMismatch,
        analyzerCodes: <String>["INVALID_METHOD_OVERRIDE_TYPE_PARAMETERS"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideTypeVariablesMismatch(String name, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(codeOverrideTypeVariablesMismatch,
      message:
          """Declared type variables of '${name}' doesn't match those on overridden method '${name2}'.""",
      arguments: {'name': name, 'name2': name2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(String name, Uri uri_)> templatePackageNotFound =
    const Template<Message Function(String name, Uri uri_)>(
        messageTemplate:
            r"""Could not resolve the package '#name' in '#uri'.""",
        withArguments: _withArgumentsPackageNotFound);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, Uri uri_)> codePackageNotFound =
    const Code<Message Function(String name, Uri uri_)>(
  "PackageNotFound",
  templatePackageNotFound,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsPackageNotFound(String name, Uri uri_) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  String uri = relativizeUri(uri_);
  return new Message(codePackageNotFound,
      message: """Could not resolve the package '${name}' in '${uri}'.""",
      arguments: {'name': name, 'uri': uri_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)> templatePackagesFileFormat =
    const Template<Message Function(String string)>(
        messageTemplate: r"""Problem in packages configuration file: #string""",
        withArguments: _withArgumentsPackagesFileFormat);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string)> codePackagesFileFormat =
    const Code<Message Function(String string)>(
  "PackagesFileFormat",
  templatePackagesFileFormat,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsPackagesFileFormat(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(codePackagesFileFormat,
      message: """Problem in packages configuration file: ${string}""",
      arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codePartExport = messagePartExport;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePartExport = const MessageCode("PartExport",
    analyzerCodes: <String>["EXPORT_OF_NON_LIBRARY"],
    message:
        r"""Can't export this file because it contains a 'part of' declaration.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codePartExportContext = messagePartExportContext;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePartExportContext = const MessageCode(
    "PartExportContext",
    severity: Severity.context,
    message: r"""This is the file that can't be exported.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codePartInPart = messagePartInPart;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePartInPart = const MessageCode("PartInPart",
    analyzerCodes: <String>["NON_PART_OF_DIRECTIVE_IN_PART"],
    message: r"""A file that's a part of a library can't have parts itself.""",
    tip: r"""Try moving the 'part' declaration to the containing library.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codePartInPartLibraryContext = messagePartInPartLibraryContext;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePartInPartLibraryContext = const MessageCode(
    "PartInPartLibraryContext",
    severity: Severity.context,
    message: r"""This is the containing library.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(Uri uri_)> templatePartOfInLibrary = const Template<
        Message Function(Uri uri_)>(
    messageTemplate:
        r"""Can't import '#uri', because it has a 'part of' declaration.""",
    tipTemplate:
        r"""Try removing the 'part of' declaration, or using '#uri' as a part.""",
    withArguments: _withArgumentsPartOfInLibrary);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Uri uri_)> codePartOfInLibrary =
    const Code<Message Function(Uri uri_)>(
        "PartOfInLibrary", templatePartOfInLibrary,
        analyzerCodes: <String>["IMPORT_OF_NON_LIBRARY"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsPartOfInLibrary(Uri uri_) {
  String uri = relativizeUri(uri_);
  return new Message(codePartOfInLibrary,
      message:
          """Can't import '${uri}', because it has a 'part of' declaration.""",
      tip:
          """Try removing the 'part of' declaration, or using '${uri}' as a part.""",
      arguments: {'uri': uri_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        Uri uri_,
        String name,
        String
            name2)> templatePartOfLibraryNameMismatch = const Template<
        Message Function(Uri uri_, String name, String name2)>(
    messageTemplate:
        r"""Using '#uri' as part of '#name' but its 'part of' declaration says '#name2'.""",
    withArguments: _withArgumentsPartOfLibraryNameMismatch);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Uri uri_, String name, String name2)>
    codePartOfLibraryNameMismatch =
    const Code<Message Function(Uri uri_, String name, String name2)>(
        "PartOfLibraryNameMismatch", templatePartOfLibraryNameMismatch,
        analyzerCodes: <String>["PART_OF_DIFFERENT_LIBRARY"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsPartOfLibraryNameMismatch(
    Uri uri_, String name, String name2) {
  String uri = relativizeUri(uri_);
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(codePartOfLibraryNameMismatch,
      message:
          """Using '${uri}' as part of '${name}' but its 'part of' declaration says '${name2}'.""",
      arguments: {'uri': uri_, 'name': name, 'name2': name2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codePartOfSelf = messagePartOfSelf;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePartOfSelf = const MessageCode("PartOfSelf",
    analyzerCodes: <String>["PART_OF_NON_PART"],
    message: r"""A file can't be a part of itself.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codePartOfTwice = messagePartOfTwice;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePartOfTwice = const MessageCode("PartOfTwice",
    index: 25,
    message: r"""Only one part-of directive may be declared in a file.""",
    tip: r"""Try removing all but one of the part-of directives.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codePartOfTwoLibraries = messagePartOfTwoLibraries;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePartOfTwoLibraries = const MessageCode(
    "PartOfTwoLibraries",
    analyzerCodes: <String>["PART_OF_DIFFERENT_LIBRARY"],
    message: r"""A file can't be part of more than one library.""",
    tip:
        r"""Try moving the shared declarations into the libraries, or into a new library.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codePartOfTwoLibrariesContext =
    messagePartOfTwoLibrariesContext;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePartOfTwoLibrariesContext = const MessageCode(
    "PartOfTwoLibrariesContext",
    severity: Severity.context,
    message: r"""Used as a part in this library.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        Uri uri_,
        Uri uri2_,
        Uri
            uri3_)> templatePartOfUriMismatch = const Template<
        Message Function(Uri uri_, Uri uri2_, Uri uri3_)>(
    messageTemplate:
        r"""Using '#uri' as part of '#uri2' but its 'part of' declaration says '#uri3'.""",
    withArguments: _withArgumentsPartOfUriMismatch);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Uri uri_, Uri uri2_, Uri uri3_)>
    codePartOfUriMismatch =
    const Code<Message Function(Uri uri_, Uri uri2_, Uri uri3_)>(
        "PartOfUriMismatch", templatePartOfUriMismatch,
        analyzerCodes: <String>["PART_OF_DIFFERENT_LIBRARY"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsPartOfUriMismatch(Uri uri_, Uri uri2_, Uri uri3_) {
  String uri = relativizeUri(uri_);
  String uri2 = relativizeUri(uri2_);
  String uri3 = relativizeUri(uri3_);
  return new Message(codePartOfUriMismatch,
      message:
          """Using '${uri}' as part of '${uri2}' but its 'part of' declaration says '${uri3}'.""",
      arguments: {'uri': uri_, 'uri2': uri2_, 'uri3': uri3_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        Uri uri_,
        Uri uri2_,
        String
            name)> templatePartOfUseUri = const Template<
        Message Function(Uri uri_, Uri uri2_, String name)>(
    messageTemplate:
        r"""Using '#uri' as part of '#uri2' but its 'part of' declaration says '#name'.""",
    tipTemplate:
        r"""Try changing the 'part of' declaration to use a relative file name.""",
    withArguments: _withArgumentsPartOfUseUri);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Uri uri_, Uri uri2_, String name)>
    codePartOfUseUri =
    const Code<Message Function(Uri uri_, Uri uri2_, String name)>(
        "PartOfUseUri", templatePartOfUseUri,
        analyzerCodes: <String>["PART_OF_UNNAMED_LIBRARY"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsPartOfUseUri(Uri uri_, Uri uri2_, String name) {
  String uri = relativizeUri(uri_);
  String uri2 = relativizeUri(uri2_);
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codePartOfUseUri,
      message:
          """Using '${uri}' as part of '${uri2}' but its 'part of' declaration says '${name}'.""",
      tip: """Try changing the 'part of' declaration to use a relative file name.""",
      arguments: {'uri': uri_, 'uri2': uri2_, 'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codePartOrphan = messagePartOrphan;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePartOrphan = const MessageCode("PartOrphan",
    message: r"""This part doesn't have a containing library.""",
    tip: r"""Try removing the 'part of' declaration.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri_)> templatePartTwice =
    const Template<Message Function(Uri uri_)>(
        messageTemplate: r"""Can't use '#uri' as a part more than once.""",
        withArguments: _withArgumentsPartTwice);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Uri uri_)> codePartTwice =
    const Code<Message Function(Uri uri_)>("PartTwice", templatePartTwice,
        analyzerCodes: <String>["DUPLICATE_PART"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsPartTwice(Uri uri_) {
  String uri = relativizeUri(uri_);
  return new Message(codePartTwice,
      message: """Can't use '${uri}' as a part more than once.""",
      arguments: {'uri': uri_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codePatchClassOrigin = messagePatchClassOrigin;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePatchClassOrigin = const MessageCode(
    "PatchClassOrigin",
    severity: Severity.context,
    message: r"""This is the origin class.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codePatchClassTypeVariablesMismatch =
    messagePatchClassTypeVariablesMismatch;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePatchClassTypeVariablesMismatch = const MessageCode(
    "PatchClassTypeVariablesMismatch",
    message:
        r"""A patch class must have the same number of type variables as its origin class.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codePatchDeclarationMismatch = messagePatchDeclarationMismatch;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePatchDeclarationMismatch = const MessageCode(
    "PatchDeclarationMismatch",
    message: r"""This patch doesn't match origin declaration.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codePatchDeclarationOrigin = messagePatchDeclarationOrigin;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePatchDeclarationOrigin = const MessageCode(
    "PatchDeclarationOrigin",
    severity: Severity.context,
    message: r"""This is the origin declaration.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, Uri uri_)>
    templatePatchInjectionFailed =
    const Template<Message Function(String name, Uri uri_)>(
        messageTemplate: r"""Can't inject '#name' into '#uri'.""",
        tipTemplate: r"""Try adding '@patch'.""",
        withArguments: _withArgumentsPatchInjectionFailed);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, Uri uri_)> codePatchInjectionFailed =
    const Code<Message Function(String name, Uri uri_)>(
  "PatchInjectionFailed",
  templatePatchInjectionFailed,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsPatchInjectionFailed(String name, Uri uri_) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  String uri = relativizeUri(uri_);
  return new Message(codePatchInjectionFailed,
      message: """Can't inject '${name}' into '${uri}'.""",
      tip: """Try adding '@patch'.""",
      arguments: {'name': name, 'uri': uri_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codePatchNonExternal = messagePatchNonExternal;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePatchNonExternal = const MessageCode(
    "PatchNonExternal",
    message:
        r"""Can't apply this patch as its origin declaration isn't external.""",
    tip: r"""Try adding 'external' to the origin declaration.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codePlatformPrivateLibraryAccess =
    messagePlatformPrivateLibraryAccess;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePlatformPrivateLibraryAccess = const MessageCode(
    "PlatformPrivateLibraryAccess",
    analyzerCodes: <String>["IMPORT_INTERNAL_LIBRARY"],
    message: r"""Can't access platform private library.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codePositionalAfterNamedArgument =
    messagePositionalAfterNamedArgument;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePositionalAfterNamedArgument = const MessageCode(
    "PositionalAfterNamedArgument",
    analyzerCodes: <String>["POSITIONAL_AFTER_NAMED_ARGUMENT"],
    message: r"""Place positional arguments before named arguments.""",
    tip:
        r"""Try moving the positional argument before the named arguments, or add a name to the argument.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codePositionalParameterWithEquals =
    messagePositionalParameterWithEquals;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePositionalParameterWithEquals = const MessageCode(
    "PositionalParameterWithEquals",
    analyzerCodes: <String>["WRONG_SEPARATOR_FOR_POSITIONAL_PARAMETER"],
    message:
        r"""Positional optional parameters can't use ':' to specify a default value.""",
    tip: r"""Try replacing ':' with '='.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codePrefixAfterCombinator = messagePrefixAfterCombinator;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePrefixAfterCombinator = const MessageCode(
    "PrefixAfterCombinator",
    index: 6,
    message:
        r"""The prefix ('as' clause) should come before any show/hide combinators.""",
    tip: r"""Try moving the prefix before the combinators.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codePrivateNamedParameter = messagePrivateNamedParameter;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePrivateNamedParameter = const MessageCode(
    "PrivateNamedParameter",
    analyzerCodes: <String>["PRIVATE_OPTIONAL_PARAMETER"],
    message: r"""An optional named parameter can't start with '_'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeRedirectingConstructorWithBody =
    messageRedirectingConstructorWithBody;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageRedirectingConstructorWithBody = const MessageCode(
    "RedirectingConstructorWithBody",
    index: 22,
    message: r"""Redirecting constructors can't have a body.""",
    tip:
        r"""Try removing the body, or not making this a redirecting constructor.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeRedirectionInNonFactory = messageRedirectionInNonFactory;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageRedirectionInNonFactory = const MessageCode(
    "RedirectionInNonFactory",
    index: 21,
    message: r"""Only factory constructor can specify '=' redirection.""",
    tip:
        r"""Try making this a factory constructor, or remove the redirection.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateRedirectionTargetNotFound =
    const Template<Message Function(String name)>(
        messageTemplate:
            r"""Redirection constructor target not found: '#name'""",
        withArguments: _withArgumentsRedirectionTargetNotFound);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeRedirectionTargetNotFound =
    const Code<Message Function(String name)>(
        "RedirectionTargetNotFound", templateRedirectionTargetNotFound,
        analyzerCodes: <String>["REDIRECT_TO_MISSING_CONSTRUCTOR"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsRedirectionTargetNotFound(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeRedirectionTargetNotFound,
      message: """Redirection constructor target not found: '${name}'""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateRequiredNamedParameterHasDefaultValueError =
    const Template<Message Function(String name)>(
        messageTemplate:
            r"""Named parameter '#name' is required and can't have a default value.""",
        withArguments:
            _withArgumentsRequiredNamedParameterHasDefaultValueError);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)>
    codeRequiredNamedParameterHasDefaultValueError =
    const Code<Message Function(String name)>(
  "RequiredNamedParameterHasDefaultValueError",
  templateRequiredNamedParameterHasDefaultValueError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsRequiredNamedParameterHasDefaultValueError(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeRequiredNamedParameterHasDefaultValueError,
      message:
          """Named parameter '${name}' is required and can't have a default value.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeRequiredParameterWithDefault =
    messageRequiredParameterWithDefault;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageRequiredParameterWithDefault = const MessageCode(
    "RequiredParameterWithDefault",
    analyzerCodes: <String>["NAMED_PARAMETER_OUTSIDE_GROUP"],
    message: r"""Non-optional parameters can't have a default value.""",
    tip:
        r"""Try removing the default value or making the parameter optional.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeRethrowNotCatch = messageRethrowNotCatch;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageRethrowNotCatch = const MessageCode("RethrowNotCatch",
    analyzerCodes: <String>["RETHROW_OUTSIDE_CATCH"],
    message: r"""'rethrow' can only be used in catch clauses.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeReturnFromVoidFunction = messageReturnFromVoidFunction;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageReturnFromVoidFunction = const MessageCode(
    "ReturnFromVoidFunction",
    analyzerCodes: <String>["RETURN_OF_INVALID_TYPE"],
    message: r"""Can't return a value from a void function.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeReturnTypeFunctionExpression =
    messageReturnTypeFunctionExpression;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageReturnTypeFunctionExpression = const MessageCode(
    "ReturnTypeFunctionExpression",
    message: r"""A function expression can't have a return type.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeReturnWithoutExpression = messageReturnWithoutExpression;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageReturnWithoutExpression = const MessageCode(
    "ReturnWithoutExpression",
    analyzerCodes: <String>["RETURN_WITHOUT_VALUE"],
    severity: Severity.warning,
    message: r"""Must explicitly return a value from a non-void function.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeReturnWithoutExpressionAsync =
    messageReturnWithoutExpressionAsync;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageReturnWithoutExpressionAsync = const MessageCode(
    "ReturnWithoutExpressionAsync",
    message:
        r"""A value must be explicitly returned from a non-void async function.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeReturnWithoutExpressionSync =
    messageReturnWithoutExpressionSync;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageReturnWithoutExpressionSync = const MessageCode(
    "ReturnWithoutExpressionSync",
    message:
        r"""A value must be explicitly returned from a non-void function.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri_)> templateSdkRootNotFound =
    const Template<Message Function(Uri uri_)>(
        messageTemplate: r"""SDK root directory not found: #uri.""",
        withArguments: _withArgumentsSdkRootNotFound);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Uri uri_)> codeSdkRootNotFound =
    const Code<Message Function(Uri uri_)>(
  "SdkRootNotFound",
  templateSdkRootNotFound,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSdkRootNotFound(Uri uri_) {
  String uri = relativizeUri(uri_);
  return new Message(codeSdkRootNotFound,
      message: """SDK root directory not found: ${uri}.""",
      arguments: {'uri': uri_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        Uri
            uri_)> templateSdkSpecificationNotFound = const Template<
        Message Function(Uri uri_)>(
    messageTemplate: r"""SDK libraries specification not found: #uri.""",
    tipTemplate:
        r"""Normally, the specification is a file named 'libraries.json' in the Dart SDK install location.""",
    withArguments: _withArgumentsSdkSpecificationNotFound);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Uri uri_)> codeSdkSpecificationNotFound =
    const Code<Message Function(Uri uri_)>(
  "SdkSpecificationNotFound",
  templateSdkSpecificationNotFound,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSdkSpecificationNotFound(Uri uri_) {
  String uri = relativizeUri(uri_);
  return new Message(codeSdkSpecificationNotFound,
      message: """SDK libraries specification not found: ${uri}.""",
      tip:
          """Normally, the specification is a file named 'libraries.json' in the Dart SDK install location.""",
      arguments: {'uri': uri_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri_)> templateSdkSummaryNotFound =
    const Template<Message Function(Uri uri_)>(
        messageTemplate: r"""SDK summary not found: #uri.""",
        withArguments: _withArgumentsSdkSummaryNotFound);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Uri uri_)> codeSdkSummaryNotFound =
    const Code<Message Function(Uri uri_)>(
  "SdkSummaryNotFound",
  templateSdkSummaryNotFound,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSdkSummaryNotFound(Uri uri_) {
  String uri = relativizeUri(uri_);
  return new Message(codeSdkSummaryNotFound,
      message: """SDK summary not found: ${uri}.""", arguments: {'uri': uri_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeSetLiteralTooManyTypeArguments =
    messageSetLiteralTooManyTypeArguments;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSetLiteralTooManyTypeArguments = const MessageCode(
    "SetLiteralTooManyTypeArguments",
    message: r"""A set literal requires exactly one type argument.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeSetOrMapLiteralTooManyTypeArguments =
    messageSetOrMapLiteralTooManyTypeArguments;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSetOrMapLiteralTooManyTypeArguments = const MessageCode(
    "SetOrMapLiteralTooManyTypeArguments",
    message:
        r"""A set or map literal requires exactly one or two type arguments, respectively.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeSetterConstructor = messageSetterConstructor;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSetterConstructor = const MessageCode(
    "SetterConstructor",
    index: 104,
    message: r"""Constructors can't be a setter.""",
    tip: r"""Try removing 'set'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateSetterNotFound =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Setter not found: '#name'.""",
        withArguments: _withArgumentsSetterNotFound);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeSetterNotFound =
    const Code<Message Function(String name)>(
        "SetterNotFound", templateSetterNotFound,
        analyzerCodes: <String>["UNDEFINED_SETTER"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSetterNotFound(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeSetterNotFound,
      message: """Setter not found: '${name}'.""", arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeSetterNotSync = messageSetterNotSync;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSetterNotSync = const MessageCode("SetterNotSync",
    analyzerCodes: <String>["INVALID_MODIFIER_ON_SETTER"],
    message: r"""Setters can't use 'async', 'async*', or 'sync*'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeSetterWithWrongNumberOfFormals =
    messageSetterWithWrongNumberOfFormals;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSetterWithWrongNumberOfFormals = const MessageCode(
    "SetterWithWrongNumberOfFormals",
    analyzerCodes: <String>["WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER"],
    message: r"""A setter should have exactly one formal parameter.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        int count,
        int count2,
        num _num1,
        num _num2,
        num
            _num3)> templateSourceBodySummary = const Template<
        Message Function(
            int count, int count2, num _num1, num _num2, num _num3)>(
    messageTemplate:
        r"""Built bodies for #count compilation units (#count2 bytes) in #num1%.3ms, that is,
#num2%12.3 bytes/ms, and
#num3%12.3 ms/compilation unit.""",
    withArguments: _withArgumentsSourceBodySummary);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
    Message Function(int count, int count2, num _num1, num _num2,
        num _num3)> codeSourceBodySummary = const Code<
    Message Function(int count, int count2, num _num1, num _num2, num _num3)>(
  "SourceBodySummary",
  templateSourceBodySummary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSourceBodySummary(
    int count, int count2, num _num1, num _num2, num _num3) {
  if (count == null) throw 'No count provided';
  if (count2 == null) throw 'No count provided';
  if (_num1 == null) throw 'No number provided';
  String num1 = _num1.toStringAsFixed(3);
  if (_num2 == null) throw 'No number provided';
  String num2 = _num2.toStringAsFixed(3).padLeft(12);
  if (_num3 == null) throw 'No number provided';
  String num3 = _num3.toStringAsFixed(3).padLeft(12);
  return new Message(codeSourceBodySummary,
      message:
          """Built bodies for ${count} compilation units (${count2} bytes) in ${num1}ms, that is,
${num2} bytes/ms, and
${num3} ms/compilation unit.""",
      arguments: {
        'count': count,
        'count2': count2,
        'num1': _num1,
        'num2': _num2,
        'num3': _num3
      });
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        int count,
        int count2,
        num _num1,
        num _num2,
        num
            _num3)> templateSourceOutlineSummary = const Template<
        Message Function(
            int count, int count2, num _num1, num _num2, num _num3)>(
    messageTemplate:
        r"""Built outlines for #count compilation units (#count2 bytes) in #num1%.3ms, that is,
#num2%12.3 bytes/ms, and
#num3%12.3 ms/compilation unit.""",
    withArguments: _withArgumentsSourceOutlineSummary);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
    Message Function(int count, int count2, num _num1, num _num2,
        num _num3)> codeSourceOutlineSummary = const Code<
    Message Function(int count, int count2, num _num1, num _num2, num _num3)>(
  "SourceOutlineSummary",
  templateSourceOutlineSummary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSourceOutlineSummary(
    int count, int count2, num _num1, num _num2, num _num3) {
  if (count == null) throw 'No count provided';
  if (count2 == null) throw 'No count provided';
  if (_num1 == null) throw 'No number provided';
  String num1 = _num1.toStringAsFixed(3);
  if (_num2 == null) throw 'No number provided';
  String num2 = _num2.toStringAsFixed(3).padLeft(12);
  if (_num3 == null) throw 'No number provided';
  String num3 = _num3.toStringAsFixed(3).padLeft(12);
  return new Message(codeSourceOutlineSummary,
      message:
          """Built outlines for ${count} compilation units (${count2} bytes) in ${num1}ms, that is,
${num2} bytes/ms, and
${num3} ms/compilation unit.""",
      arguments: {
        'count': count,
        'count2': count2,
        'num1': _num1,
        'num2': _num2,
        'num3': _num3
      });
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeSpreadElement = messageSpreadElement;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSpreadElement = const MessageCode("SpreadElement",
    severity: Severity.context, message: r"""Iterable spread.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeSpreadMapElement = messageSpreadMapElement;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSpreadMapElement = const MessageCode(
    "SpreadMapElement",
    severity: Severity.context,
    message: r"""Map spread.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeStackOverflow = messageStackOverflow;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageStackOverflow = const MessageCode("StackOverflow",
    index: 19,
    message: r"""The file has too many nested expressions or statements.""",
    tip: r"""Try simplifying the code.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeStaticAndInstanceConflict =
    messageStaticAndInstanceConflict;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageStaticAndInstanceConflict = const MessageCode(
    "StaticAndInstanceConflict",
    analyzerCodes: <String>["CONFLICTING_STATIC_AND_INSTANCE"],
    message: r"""This static member conflicts with an instance member.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeStaticAndInstanceConflictCause =
    messageStaticAndInstanceConflictCause;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageStaticAndInstanceConflictCause = const MessageCode(
    "StaticAndInstanceConflictCause",
    severity: Severity.context,
    message: r"""This is the instance member.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeStaticConstructor = messageStaticConstructor;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageStaticConstructor = const MessageCode(
    "StaticConstructor",
    index: 4,
    message: r"""Constructors can't be static.""",
    tip: r"""Try removing the keyword 'static'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeStaticOperator = messageStaticOperator;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageStaticOperator = const MessageCode("StaticOperator",
    index: 17,
    message: r"""Operators can't be static.""",
    tip: r"""Try removing the keyword 'static'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeStrongModeNNBDButOptOut = messageStrongModeNNBDButOptOut;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageStrongModeNNBDButOptOut = const MessageCode(
    "StrongModeNNBDButOptOut",
    message:
        r"""A library can't opt out of null safety by default, when using sound null safety.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        List<String>
            _names)> templateStrongModeNNBDPackageOptOut = const Template<
        Message Function(List<String> _names)>(
    messageTemplate:
        r"""Cannot run with sound null safety as one or more dependencies do not
support null safety:

#names

Run 'pub outdated --mode=null-safety' to determine if versions of your
dependencies supporting null safety are available.""",
    withArguments: _withArgumentsStrongModeNNBDPackageOptOut);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(List<String> _names)>
    codeStrongModeNNBDPackageOptOut =
    const Code<Message Function(List<String> _names)>(
  "StrongModeNNBDPackageOptOut",
  templateStrongModeNNBDPackageOptOut,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsStrongModeNNBDPackageOptOut(List<String> _names) {
  if (_names.isEmpty) throw 'No names provided';
  String names = itemizeNames(_names);
  return new Message(codeStrongModeNNBDPackageOptOut,
      message:
          """Cannot run with sound null safety as one or more dependencies do not
support null safety:

${names}

Run 'pub outdated --mode=null-safety' to determine if versions of your
dependencies supporting null safety are available.""",
      arguments: {'names': _names});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeSuperAsExpression = messageSuperAsExpression;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSuperAsExpression = const MessageCode(
    "SuperAsExpression",
    analyzerCodes: <String>["SUPER_AS_EXPRESSION"],
    message: r"""Can't use 'super' as an expression.""",
    tip:
        r"""To delegate a constructor to a super constructor, put the super call as an initializer.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeSuperAsIdentifier = messageSuperAsIdentifier;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSuperAsIdentifier = const MessageCode(
    "SuperAsIdentifier",
    analyzerCodes: <String>["SUPER_AS_EXPRESSION"],
    message: r"""Expected identifier, but got 'super'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeSuperInitializerNotLast = messageSuperInitializerNotLast;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSuperInitializerNotLast = const MessageCode(
    "SuperInitializerNotLast",
    analyzerCodes: <String>["INVALID_SUPER_INVOCATION"],
    message: r"""Can't have initializers after 'super'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeSuperNullAware = messageSuperNullAware;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSuperNullAware = const MessageCode("SuperNullAware",
    index: 18,
    message:
        r"""The operator '?.' cannot be used with 'super' because 'super' cannot be null.""",
    tip: r"""Try replacing '?.' with '.'""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateSuperclassHasNoConstructor =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Superclass has no constructor named '#name'.""",
        withArguments: _withArgumentsSuperclassHasNoConstructor);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeSuperclassHasNoConstructor =
    const Code<Message Function(String name)>(
        "SuperclassHasNoConstructor", templateSuperclassHasNoConstructor,
        analyzerCodes: <String>[
      "UNDEFINED_CONSTRUCTOR_IN_INITIALIZER",
      "UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT"
    ]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperclassHasNoConstructor(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeSuperclassHasNoConstructor,
      message: """Superclass has no constructor named '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            name)> templateSuperclassHasNoDefaultConstructor = const Template<
        Message Function(String name)>(
    messageTemplate:
        r"""The superclass, '#name', has no unnamed constructor that takes no arguments.""",
    withArguments: _withArgumentsSuperclassHasNoDefaultConstructor);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)>
    codeSuperclassHasNoDefaultConstructor =
    const Code<Message Function(String name)>(
        "SuperclassHasNoDefaultConstructor",
        templateSuperclassHasNoDefaultConstructor,
        analyzerCodes: <String>["NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperclassHasNoDefaultConstructor(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeSuperclassHasNoDefaultConstructor,
      message:
          """The superclass, '${name}', has no unnamed constructor that takes no arguments.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateSuperclassHasNoGetter =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Superclass has no getter named '#name'.""",
        withArguments: _withArgumentsSuperclassHasNoGetter);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeSuperclassHasNoGetter =
    const Code<Message Function(String name)>(
        "SuperclassHasNoGetter", templateSuperclassHasNoGetter,
        analyzerCodes: <String>["UNDEFINED_SUPER_GETTER"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperclassHasNoGetter(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeSuperclassHasNoGetter,
      message: """Superclass has no getter named '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateSuperclassHasNoMethod =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Superclass has no method named '#name'.""",
        withArguments: _withArgumentsSuperclassHasNoMethod);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeSuperclassHasNoMethod =
    const Code<Message Function(String name)>(
        "SuperclassHasNoMethod", templateSuperclassHasNoMethod,
        analyzerCodes: <String>["UNDEFINED_SUPER_METHOD"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperclassHasNoMethod(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeSuperclassHasNoMethod,
      message: """Superclass has no method named '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateSuperclassHasNoSetter =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Superclass has no setter named '#name'.""",
        withArguments: _withArgumentsSuperclassHasNoSetter);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeSuperclassHasNoSetter =
    const Code<Message Function(String name)>(
        "SuperclassHasNoSetter", templateSuperclassHasNoSetter,
        analyzerCodes: <String>["UNDEFINED_SUPER_SETTER"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperclassHasNoSetter(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeSuperclassHasNoSetter,
      message: """Superclass has no setter named '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            name)> templateSuperclassMethodArgumentMismatch = const Template<
        Message Function(String name)>(
    messageTemplate:
        r"""Superclass doesn't have a method named '#name' with matching arguments.""",
    withArguments: _withArgumentsSuperclassMethodArgumentMismatch);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeSuperclassMethodArgumentMismatch =
    const Code<Message Function(String name)>(
  "SuperclassMethodArgumentMismatch",
  templateSuperclassMethodArgumentMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperclassMethodArgumentMismatch(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeSuperclassMethodArgumentMismatch,
      message:
          """Superclass doesn't have a method named '${name}' with matching arguments.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeSupertypeIsFunction = messageSupertypeIsFunction;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSupertypeIsFunction = const MessageCode(
    "SupertypeIsFunction",
    message: r"""Can't use a function type as supertype.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateSupertypeIsIllegal =
    const Template<Message Function(String name)>(
        messageTemplate: r"""The type '#name' can't be used as supertype.""",
        withArguments: _withArgumentsSupertypeIsIllegal);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeSupertypeIsIllegal =
    const Code<Message Function(String name)>(
        "SupertypeIsIllegal", templateSupertypeIsIllegal,
        analyzerCodes: <String>["EXTENDS_NON_CLASS"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSupertypeIsIllegal(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeSupertypeIsIllegal,
      message: """The type '${name}' can't be used as supertype.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateSupertypeIsTypeVariable =
    const Template<Message Function(String name)>(
        messageTemplate:
            r"""The type variable '#name' can't be used as supertype.""",
        withArguments: _withArgumentsSupertypeIsTypeVariable);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeSupertypeIsTypeVariable =
    const Code<Message Function(String name)>(
        "SupertypeIsTypeVariable", templateSupertypeIsTypeVariable,
        analyzerCodes: <String>["EXTENDS_NON_CLASS"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSupertypeIsTypeVariable(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeSupertypeIsTypeVariable,
      message: """The type variable '${name}' can't be used as supertype.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeSwitchCaseFallThrough = messageSwitchCaseFallThrough;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSwitchCaseFallThrough = const MessageCode(
    "SwitchCaseFallThrough",
    analyzerCodes: <String>["CASE_BLOCK_NOT_TERMINATED"],
    message: r"""Switch case may fall through to the next case.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeSwitchExpressionNotAssignableCause =
    messageSwitchExpressionNotAssignableCause;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSwitchExpressionNotAssignableCause = const MessageCode(
    "SwitchExpressionNotAssignableCause",
    severity: Severity.context,
    message: r"""The switch expression is here.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeSwitchHasCaseAfterDefault =
    messageSwitchHasCaseAfterDefault;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSwitchHasCaseAfterDefault = const MessageCode(
    "SwitchHasCaseAfterDefault",
    index: 16,
    message:
        r"""The default case should be the last case in a switch statement.""",
    tip: r"""Try moving the default case after the other case clauses.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeSwitchHasMultipleDefaults =
    messageSwitchHasMultipleDefaults;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSwitchHasMultipleDefaults = const MessageCode(
    "SwitchHasMultipleDefaults",
    index: 15,
    message: r"""The 'default' case can only be declared once.""",
    tip: r"""Try removing all but one default case.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeSyntheticToken = messageSyntheticToken;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSyntheticToken = const MessageCode("SyntheticToken",
    message: r"""This couldn't be parsed.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateThisAccessInFieldInitializer =
    const Template<Message Function(String name)>(
        messageTemplate:
            r"""Can't access 'this' in a field initializer to read '#name'.""",
        withArguments: _withArgumentsThisAccessInFieldInitializer);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeThisAccessInFieldInitializer =
    const Code<Message Function(String name)>(
        "ThisAccessInFieldInitializer", templateThisAccessInFieldInitializer,
        analyzerCodes: <String>["THIS_ACCESS_FROM_FIELD_INITIALIZER"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsThisAccessInFieldInitializer(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeThisAccessInFieldInitializer,
      message:
          """Can't access 'this' in a field initializer to read '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeThisAsIdentifier = messageThisAsIdentifier;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageThisAsIdentifier = const MessageCode(
    "ThisAsIdentifier",
    analyzerCodes: <String>["INVALID_REFERENCE_TO_THIS"],
    message: r"""Expected identifier, but got 'this'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeThisInitializerNotAlone = messageThisInitializerNotAlone;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageThisInitializerNotAlone = const MessageCode(
    "ThisInitializerNotAlone",
    analyzerCodes: <String>["FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR"],
    message: r"""Can't have other initializers together with 'this'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)>
    templateThisOrSuperAccessInFieldInitializer =
    const Template<Message Function(String string)>(
        messageTemplate: r"""Can't access '#string' in a field initializer.""",
        withArguments: _withArgumentsThisOrSuperAccessInFieldInitializer);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string)>
    codeThisOrSuperAccessInFieldInitializer =
    const Code<Message Function(String string)>(
        "ThisOrSuperAccessInFieldInitializer",
        templateThisOrSuperAccessInFieldInitializer,
        analyzerCodes: <String>["THIS_ACCESS_FROM_INITIALIZER"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsThisOrSuperAccessInFieldInitializer(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeThisOrSuperAccessInFieldInitializer,
      message: """Can't access '${string}' in a field initializer.""",
      arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        int count,
        int
            count2)> templateTooFewArguments = const Template<
        Message Function(int count, int count2)>(
    messageTemplate:
        r"""Too few positional arguments: #count required, #count2 given.""",
    withArguments: _withArgumentsTooFewArguments);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(int count, int count2)> codeTooFewArguments =
    const Code<Message Function(int count, int count2)>(
        "TooFewArguments", templateTooFewArguments,
        analyzerCodes: <String>["NOT_ENOUGH_REQUIRED_ARGUMENTS"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsTooFewArguments(int count, int count2) {
  if (count == null) throw 'No count provided';
  if (count2 == null) throw 'No count provided';
  return new Message(codeTooFewArguments,
      message:
          """Too few positional arguments: ${count} required, ${count2} given.""",
      arguments: {'count': count, 'count2': count2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        int count,
        int
            count2)> templateTooManyArguments = const Template<
        Message Function(int count, int count2)>(
    messageTemplate:
        r"""Too many positional arguments: #count allowed, but #count2 found.""",
    tipTemplate: r"""Try removing the extra positional arguments.""",
    withArguments: _withArgumentsTooManyArguments);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(int count, int count2)> codeTooManyArguments =
    const Code<Message Function(int count, int count2)>(
        "TooManyArguments", templateTooManyArguments,
        analyzerCodes: <String>["EXTRA_POSITIONAL_ARGUMENTS"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsTooManyArguments(int count, int count2) {
  if (count == null) throw 'No count provided';
  if (count2 == null) throw 'No count provided';
  return new Message(codeTooManyArguments,
      message:
          """Too many positional arguments: ${count} allowed, but ${count2} found.""",
      tip: """Try removing the extra positional arguments.""",
      arguments: {'count': count, 'count2': count2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeTopLevelOperator = messageTopLevelOperator;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTopLevelOperator = const MessageCode(
    "TopLevelOperator",
    index: 14,
    message: r"""Operators must be declared within a class.""",
    tip:
        r"""Try removing the operator, moving it to a class, or converting it to be a function.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeTypeAfterVar = messageTypeAfterVar;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTypeAfterVar = const MessageCode("TypeAfterVar",
    index: 89,
    message:
        r"""Variables can't be declared using both 'var' and a type name.""",
    tip: r"""Try removing 'var.'""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(int count)> templateTypeArgumentMismatch =
    const Template<Message Function(int count)>(
        messageTemplate: r"""Expected #count type arguments.""",
        withArguments: _withArgumentsTypeArgumentMismatch);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(int count)> codeTypeArgumentMismatch =
    const Code<Message Function(int count)>(
        "TypeArgumentMismatch", templateTypeArgumentMismatch,
        analyzerCodes: <String>["WRONG_NUMBER_OF_TYPE_ARGUMENTS"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsTypeArgumentMismatch(int count) {
  if (count == null) throw 'No count provided';
  return new Message(codeTypeArgumentMismatch,
      message: """Expected ${count} type arguments.""",
      arguments: {'count': count});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateTypeArgumentsOnTypeVariable =
    const Template<Message Function(String name)>(
        messageTemplate:
            r"""Can't use type arguments with type variable '#name'.""",
        tipTemplate: r"""Try removing the type arguments.""",
        withArguments: _withArgumentsTypeArgumentsOnTypeVariable);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeTypeArgumentsOnTypeVariable =
    const Code<Message Function(String name)>(
        "TypeArgumentsOnTypeVariable", templateTypeArgumentsOnTypeVariable,
        index: 13);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsTypeArgumentsOnTypeVariable(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeTypeArgumentsOnTypeVariable,
      message: """Can't use type arguments with type variable '${name}'.""",
      tip: """Try removing the type arguments.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeTypeBeforeFactory = messageTypeBeforeFactory;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTypeBeforeFactory = const MessageCode(
    "TypeBeforeFactory",
    index: 57,
    message: r"""Factory constructors cannot have a return type.""",
    tip: r"""Try removing the type appearing before 'factory'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateTypeNotFound =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Type '#name' not found.""",
        withArguments: _withArgumentsTypeNotFound);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeTypeNotFound =
    const Code<Message Function(String name)>(
        "TypeNotFound", templateTypeNotFound,
        analyzerCodes: <String>["UNDEFINED_CLASS"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsTypeNotFound(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeTypeNotFound,
      message: """Type '${name}' not found.""", arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, Uri uri_)> templateTypeOrigin =
    const Template<Message Function(String name, Uri uri_)>(
        messageTemplate: r"""'#name' is from '#uri'.""",
        withArguments: _withArgumentsTypeOrigin);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, Uri uri_)> codeTypeOrigin =
    const Code<Message Function(String name, Uri uri_)>(
  "TypeOrigin",
  templateTypeOrigin,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsTypeOrigin(String name, Uri uri_) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  String uri = relativizeUri(uri_);
  return new Message(codeTypeOrigin,
      message: """'${name}' is from '${uri}'.""",
      arguments: {'name': name, 'uri': uri_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, Uri uri_, Uri uri2_)>
    templateTypeOriginWithFileUri =
    const Template<Message Function(String name, Uri uri_, Uri uri2_)>(
        messageTemplate: r"""'#name' is from '#uri' ('#uri2').""",
        withArguments: _withArgumentsTypeOriginWithFileUri);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, Uri uri_, Uri uri2_)>
    codeTypeOriginWithFileUri =
    const Code<Message Function(String name, Uri uri_, Uri uri2_)>(
  "TypeOriginWithFileUri",
  templateTypeOriginWithFileUri,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsTypeOriginWithFileUri(String name, Uri uri_, Uri uri2_) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  String uri = relativizeUri(uri_);
  String uri2 = relativizeUri(uri2_);
  return new Message(codeTypeOriginWithFileUri,
      message: """'${name}' is from '${uri}' ('${uri2}').""",
      arguments: {'name': name, 'uri': uri_, 'uri2': uri2_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeTypeVariableDuplicatedName =
    messageTypeVariableDuplicatedName;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTypeVariableDuplicatedName = const MessageCode(
    "TypeVariableDuplicatedName",
    analyzerCodes: <String>["DUPLICATE_DEFINITION"],
    message: r"""A type variable can't have the same name as another.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateTypeVariableDuplicatedNameCause =
    const Template<Message Function(String name)>(
        messageTemplate: r"""The other type variable named '#name'.""",
        withArguments: _withArgumentsTypeVariableDuplicatedNameCause);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeTypeVariableDuplicatedNameCause =
    const Code<Message Function(String name)>("TypeVariableDuplicatedNameCause",
        templateTypeVariableDuplicatedNameCause,
        severity: Severity.context);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsTypeVariableDuplicatedNameCause(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeTypeVariableDuplicatedNameCause,
      message: """The other type variable named '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeTypeVariableInConstantContext =
    messageTypeVariableInConstantContext;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTypeVariableInConstantContext = const MessageCode(
    "TypeVariableInConstantContext",
    analyzerCodes: <String>["TYPE_PARAMETER_IN_CONST_EXPRESSION"],
    message: r"""Type variables can't be used as constants.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeTypeVariableInStaticContext =
    messageTypeVariableInStaticContext;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTypeVariableInStaticContext = const MessageCode(
    "TypeVariableInStaticContext",
    analyzerCodes: <String>["TYPE_PARAMETER_REFERENCED_BY_STATIC"],
    message: r"""Type variables can't be used in static members.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeTypeVariableSameNameAsEnclosing =
    messageTypeVariableSameNameAsEnclosing;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTypeVariableSameNameAsEnclosing = const MessageCode(
    "TypeVariableSameNameAsEnclosing",
    analyzerCodes: <String>["CONFLICTING_TYPE_VARIABLE_AND_CLASS"],
    message:
        r"""A type variable can't have the same name as its enclosing declaration.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeTypedefCause = messageTypedefCause;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTypedefCause = const MessageCode("TypedefCause",
    severity: Severity.context,
    message: r"""The issue arises via this type alias.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeTypedefInClass = messageTypedefInClass;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTypedefInClass = const MessageCode("TypedefInClass",
    index: 7,
    message: r"""Typedefs can't be declared inside classes.""",
    tip: r"""Try moving the typedef to the top-level.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeTypedefNotFunction = messageTypedefNotFunction;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTypedefNotFunction = const MessageCode(
    "TypedefNotFunction",
    analyzerCodes: <String>["INVALID_GENERIC_FUNCTION_TYPE"],
    message: r"""Can't create typedef from non-function type.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeTypedefNotType = messageTypedefNotType;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTypedefNotType = const MessageCode("TypedefNotType",
    analyzerCodes: <String>["INVALID_TYPE_IN_TYPEDEF"],
    message: r"""Can't create typedef from non-type.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeTypedefNullableType = messageTypedefNullableType;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTypedefNullableType = const MessageCode(
    "TypedefNullableType",
    message: r"""Can't create typedef from nullable type.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeTypedefTypeVariableNotConstructor =
    messageTypedefTypeVariableNotConstructor;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTypedefTypeVariableNotConstructor = const MessageCode(
    "TypedefTypeVariableNotConstructor",
    message:
        r"""Can't use a typedef denoting a type variable as a constructor, nor for a static member access.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeTypedefTypeVariableNotConstructorCause =
    messageTypedefTypeVariableNotConstructorCause;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTypedefTypeVariableNotConstructorCause =
    const MessageCode("TypedefTypeVariableNotConstructorCause",
        severity: Severity.context,
        message: r"""This is the type variable ultimately denoted.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeTypedefUnaliasedTypeCause =
    messageTypedefUnaliasedTypeCause;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTypedefUnaliasedTypeCause = const MessageCode(
    "TypedefUnaliasedTypeCause",
    severity: Severity.context,
    message: r"""This is the type denoted by the type alias.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeUnexpectedDollarInString = messageUnexpectedDollarInString;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageUnexpectedDollarInString = const MessageCode(
    "UnexpectedDollarInString",
    analyzerCodes: <String>["UNEXPECTED_DOLLAR_IN_STRING"],
    message:
        r"""A '$' has special meaning inside a string, and must be followed by an identifier or an expression in curly braces ({}).""",
    tip: r"""Try adding a backslash (\) to escape the '$'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateUnexpectedToken =
    const Template<Message Function(Token token)>(
        messageTemplate: r"""Unexpected token '#lexeme'.""",
        withArguments: _withArgumentsUnexpectedToken);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeUnexpectedToken =
    const Code<Message Function(Token token)>(
        "UnexpectedToken", templateUnexpectedToken,
        analyzerCodes: <String>["UNEXPECTED_TOKEN"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnexpectedToken(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeUnexpectedToken,
      message: """Unexpected token '${lexeme}'.""",
      arguments: {'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string, Token token)>
    templateUnmatchedToken =
    const Template<Message Function(String string, Token token)>(
        messageTemplate: r"""Can't find '#string' to match '#lexeme'.""",
        withArguments: _withArgumentsUnmatchedToken);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string, Token token)> codeUnmatchedToken =
    const Code<Message Function(String string, Token token)>(
        "UnmatchedToken", templateUnmatchedToken,
        analyzerCodes: <String>["EXPECTED_TOKEN"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnmatchedToken(String string, Token token) {
  if (string.isEmpty) throw 'No string provided';
  String lexeme = token.lexeme;
  return new Message(codeUnmatchedToken,
      message: """Can't find '${string}' to match '${lexeme}'.""",
      arguments: {'string': string, 'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String name,
        String
            name2)> templateUnresolvedPrefixInTypeAnnotation = const Template<
        Message Function(String name, String name2)>(
    messageTemplate:
        r"""'#name.#name2' can't be used as a type because '#name' isn't defined.""",
    withArguments: _withArgumentsUnresolvedPrefixInTypeAnnotation);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String name2)>
    codeUnresolvedPrefixInTypeAnnotation =
    const Code<Message Function(String name, String name2)>(
        "UnresolvedPrefixInTypeAnnotation",
        templateUnresolvedPrefixInTypeAnnotation,
        analyzerCodes: <String>["NOT_A_TYPE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnresolvedPrefixInTypeAnnotation(
    String name, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(codeUnresolvedPrefixInTypeAnnotation,
      message:
          """'${name}.${name2}' can't be used as a type because '${name}' isn't defined.""",
      arguments: {'name': name, 'name2': name2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)> templateUnspecified =
    const Template<Message Function(String string)>(
        messageTemplate: r"""#string""",
        withArguments: _withArgumentsUnspecified);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string)> codeUnspecified =
    const Code<Message Function(String string)>(
  "Unspecified",
  templateUnspecified,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnspecified(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeUnspecified,
      message: """${string}""", arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateUnsupportedOperator =
    const Template<Message Function(Token token)>(
        messageTemplate: r"""The '#lexeme' operator is not supported.""",
        withArguments: _withArgumentsUnsupportedOperator);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeUnsupportedOperator =
    const Code<Message Function(Token token)>(
        "UnsupportedOperator", templateUnsupportedOperator,
        analyzerCodes: <String>["UNSUPPORTED_OPERATOR"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnsupportedOperator(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeUnsupportedOperator,
      message: """The '${lexeme}' operator is not supported.""",
      arguments: {'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeUnsupportedPrefixPlus = messageUnsupportedPrefixPlus;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageUnsupportedPrefixPlus = const MessageCode(
    "UnsupportedPrefixPlus",
    analyzerCodes: <String>["MISSING_IDENTIFIER"],
    message: r"""'+' is not a prefix operator.""",
    tip: r"""Try removing '+'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeUnterminatedComment = messageUnterminatedComment;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageUnterminatedComment = const MessageCode(
    "UnterminatedComment",
    analyzerCodes: <String>["UNTERMINATED_MULTI_LINE_COMMENT"],
    message: r"""Comment starting with '/*' must end with '*/'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string, String string2)>
    templateUnterminatedString =
    const Template<Message Function(String string, String string2)>(
        messageTemplate:
            r"""String starting with #string must end with #string2.""",
        withArguments: _withArgumentsUnterminatedString);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string, String string2)>
    codeUnterminatedString =
    const Code<Message Function(String string, String string2)>(
        "UnterminatedString", templateUnterminatedString,
        analyzerCodes: <String>["UNTERMINATED_STRING_LITERAL"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnterminatedString(String string, String string2) {
  if (string.isEmpty) throw 'No string provided';
  if (string2.isEmpty) throw 'No string provided';
  return new Message(codeUnterminatedString,
      message: """String starting with ${string} must end with ${string2}.""",
      arguments: {'string': string, 'string2': string2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeUnterminatedToken = messageUnterminatedToken;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageUnterminatedToken =
    const MessageCode("UnterminatedToken", message: r"""Incomplete token.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri_)> templateUntranslatableUri =
    const Template<Message Function(Uri uri_)>(
        messageTemplate: r"""Not found: '#uri'""",
        withArguments: _withArgumentsUntranslatableUri);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Uri uri_)> codeUntranslatableUri =
    const Code<Message Function(Uri uri_)>(
        "UntranslatableUri", templateUntranslatableUri,
        analyzerCodes: <String>["URI_DOES_NOT_EXIST"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUntranslatableUri(Uri uri_) {
  String uri = relativizeUri(uri_);
  return new Message(codeUntranslatableUri,
      message: """Not found: '${uri}'""", arguments: {'uri': uri_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateUseOfDeprecatedIdentifier =
    const Template<Message Function(String name)>(
        messageTemplate: r"""'#name' is deprecated.""",
        withArguments: _withArgumentsUseOfDeprecatedIdentifier);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeUseOfDeprecatedIdentifier =
    const Code<Message Function(String name)>(
        "UseOfDeprecatedIdentifier", templateUseOfDeprecatedIdentifier,
        severity: Severity.ignored);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUseOfDeprecatedIdentifier(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeUseOfDeprecatedIdentifier,
      message: """'${name}' is deprecated.""", arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateValueForRequiredParameterNotProvidedError =
    const Template<Message Function(String name)>(
        messageTemplate:
            r"""Required named parameter '#name' must be provided.""",
        withArguments: _withArgumentsValueForRequiredParameterNotProvidedError);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)>
    codeValueForRequiredParameterNotProvidedError =
    const Code<Message Function(String name)>(
  "ValueForRequiredParameterNotProvidedError",
  templateValueForRequiredParameterNotProvidedError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsValueForRequiredParameterNotProvidedError(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeValueForRequiredParameterNotProvidedError,
      message: """Required named parameter '${name}' must be provided.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeVarAsTypeName = messageVarAsTypeName;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageVarAsTypeName = const MessageCode("VarAsTypeName",
    index: 61, message: r"""The keyword 'var' can't be used as a type name.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeVarReturnType = messageVarReturnType;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageVarReturnType = const MessageCode("VarReturnType",
    index: 12,
    message: r"""The return type can't be 'var'.""",
    tip:
        r"""Try removing the keyword 'var', or replacing it with the name of the return type.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeVerificationErrorOriginContext =
    messageVerificationErrorOriginContext;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageVerificationErrorOriginContext = const MessageCode(
    "VerificationErrorOriginContext",
    severity: Severity.context,
    message: r"""The node most likely is taken from here by a transformer.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeVoidExpression = messageVoidExpression;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageVoidExpression = const MessageCode("VoidExpression",
    analyzerCodes: <String>["USE_OF_VOID_RESULT"],
    message: r"""This expression has type 'void' and can't be used.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeVoidWithTypeArguments = messageVoidWithTypeArguments;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageVoidWithTypeArguments = const MessageCode(
    "VoidWithTypeArguments",
    index: 100,
    message: r"""Type 'void' can't have type arguments.""",
    tip: r"""Try removing the type arguments.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String string,
        String
            string2)> templateWebLiteralCannotBeRepresentedExactly = const Template<
        Message Function(String string, String string2)>(
    messageTemplate:
        r"""The integer literal #string can't be represented exactly in JavaScript.""",
    tipTemplate:
        r"""Try changing the literal to something that can be represented in Javascript. In Javascript #string2 is the nearest value that can be represented exactly.""",
    withArguments: _withArgumentsWebLiteralCannotBeRepresentedExactly);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string, String string2)>
    codeWebLiteralCannotBeRepresentedExactly =
    const Code<Message Function(String string, String string2)>(
  "WebLiteralCannotBeRepresentedExactly",
  templateWebLiteralCannotBeRepresentedExactly,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsWebLiteralCannotBeRepresentedExactly(
    String string, String string2) {
  if (string.isEmpty) throw 'No string provided';
  if (string2.isEmpty) throw 'No string provided';
  return new Message(codeWebLiteralCannotBeRepresentedExactly,
      message:
          """The integer literal ${string} can't be represented exactly in JavaScript.""",
      tip: """Try changing the literal to something that can be represented in Javascript. In Javascript ${string2} is the nearest value that can be represented exactly.""",
      arguments: {'string': string, 'string2': string2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeWithBeforeExtends = messageWithBeforeExtends;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageWithBeforeExtends = const MessageCode(
    "WithBeforeExtends",
    index: 11,
    message: r"""The extends clause must be before the with clause.""",
    tip: r"""Try moving the extends clause before the with clause.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeYieldAsIdentifier = messageYieldAsIdentifier;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageYieldAsIdentifier = const MessageCode(
    "YieldAsIdentifier",
    analyzerCodes: <String>["ASYNC_KEYWORD_USED_AS_IDENTIFIER"],
    message:
        r"""'yield' can't be used as an identifier in 'async', 'async*', or 'sync*' methods.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeYieldNotGenerator = messageYieldNotGenerator;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageYieldNotGenerator = const MessageCode(
    "YieldNotGenerator",
    analyzerCodes: <String>["YIELD_IN_NON_GENERATOR"],
    message: r"""'yield' can only be used in 'sync*' or 'async*' methods.""");
