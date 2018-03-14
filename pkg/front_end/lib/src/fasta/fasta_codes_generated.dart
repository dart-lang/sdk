// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// NOTE: THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/front_end/messages.yaml' and run
// 'pkg/front_end/tool/fasta generate-messages' to update.

part of fasta.codes;

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
        severity: Severity.errorLegacyWarning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsAbstractClassInstantiation(String name) {
  return new Message(codeAbstractClassInstantiation,
      message: """The class '$name' is abstract and can't be instantiated.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeAbstractClassMember = messageAbstractClassMember;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAbstractClassMember = const MessageCode(
    "AbstractClassMember",
    analyzerCode: "ABSTRACT_CLASS_MEMBER",
    dart2jsCode: "EXTRANEOUS_MODIFIER",
    message: r"""Members of classes can't be declared to be 'abstract'.""",
    tip:
        r"""Try removing the 'abstract' keyword. You can add the 'abstract' keyword before the class declaration.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeAbstractNotSync = messageAbstractNotSync;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAbstractNotSync = const MessageCode("AbstractNotSync",
    dart2jsCode: "*ignored*",
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
        severity: Severity.errorLegacyWarning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsAbstractRedirectedClassInstantiation(String name) {
  return new Message(codeAbstractRedirectedClassInstantiation,
      message:
          """Factory redirects to class '$name', which is abstract and can't be instantiated.""",
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
  return new Message(codeAccessError,
      message: """Access error: '$name'.""", arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, DartType _type, DartType _type2)>
    templateAmbiguousSupertypes = const Template<
            Message Function(String name, DartType _type, DartType _type2)>(
        messageTemplate:
            r"""'#name' can't implement both '#type' and '#type2'""",
        withArguments: _withArgumentsAmbiguousSupertypes);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, DartType _type, DartType _type2)>
    codeAmbiguousSupertypes =
    const Code<Message Function(String name, DartType _type, DartType _type2)>(
        "AmbiguousSupertypes", templateAmbiguousSupertypes,
        severity: Severity.error);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsAmbiguousSupertypes(
    String name, DartType _type, DartType _type2) {
  NameSystem nameSystem = new NameSystem();
  StringBuffer buffer = new StringBuffer();
  new Printer(buffer, syntheticNames: nameSystem).writeNode(_type);
  String type = '$buffer';

  buffer = new StringBuffer();
  new Printer(buffer, syntheticNames: nameSystem).writeNode(_type2);
  String type2 = '$buffer';

  return new Message(codeAmbiguousSupertypes,
      message: """'$name' can't implement both '$type' and '$type2'""",
      arguments: {'name': name, 'type': _type, 'type2': _type2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeAnnotationOnEnumConstant = messageAnnotationOnEnumConstant;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAnnotationOnEnumConstant = const MessageCode(
    "AnnotationOnEnumConstant",
    analyzerCode: "ANNOTATION_ON_ENUM_CONSTANT",
    dart2jsCode: "*fatal*",
    message: r"""Enum constants can't have annotations.""",
    tip: r"""Try removing the annotation.""");

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
        analyzerCode: "ILLEGAL_CHARACTER", dart2jsCode: "BAD_INPUT_CHARACTER");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsAsciiControlCharacter(int codePoint) {
  String unicode =
      "U+${codePoint.toRadixString(16).toUpperCase().padLeft(4, '0')}";
  return new Message(codeAsciiControlCharacter,
      message:
          """The control character $unicode can only be used in strings and comments.""",
      arguments: {'codePoint': codePoint});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeAssertAsExpression = messageAssertAsExpression;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAssertAsExpression = const MessageCode(
    "AssertAsExpression",
    dart2jsCode: "*fatal*",
    message: r"""`assert` can't be used as an expression.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeAssertExtraneousArgument = messageAssertExtraneousArgument;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAssertExtraneousArgument = const MessageCode(
    "AssertExtraneousArgument",
    dart2jsCode: "*fatal*",
    message: r"""`assert` can't have more than two arguments.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeAsyncAsIdentifier = messageAsyncAsIdentifier;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAsyncAsIdentifier = const MessageCode(
    "AsyncAsIdentifier",
    analyzerCode: "ASYNC_KEYWORD_USED_AS_IDENTIFIER",
    dart2jsCode: "GENERIC",
    message:
        r"""'async' can't be used as an identifier in 'async', 'async*', or 'sync*' methods.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeAwaitAsIdentifier = messageAwaitAsIdentifier;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAwaitAsIdentifier = const MessageCode(
    "AwaitAsIdentifier",
    analyzerCode: "ASYNC_KEYWORD_USED_AS_IDENTIFIER",
    dart2jsCode: "*ignored*",
    message:
        r"""'await' can't be used as an identifier in 'async', 'async*', or 'sync*' methods.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeAwaitForNotAsync = messageAwaitForNotAsync;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAwaitForNotAsync = const MessageCode(
    "AwaitForNotAsync",
    analyzerCode: "ASYNC_FOR_IN_WRONG_CONTEXT",
    dart2jsCode: "*ignored*",
    message:
        r"""The asynchronous for-in can only be used in functions marked with 'async' or 'async*'.""",
    tip:
        r"""Try marking the function body with either 'async' or 'async*', or removing the 'await' before the for loop.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeAwaitNotAsync = messageAwaitNotAsync;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAwaitNotAsync = const MessageCode("AwaitNotAsync",
    dart2jsCode: "*ignored*",
    message: r"""'await' can only be used in 'async' or 'async*' methods.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeBreakOutsideOfLoop = messageBreakOutsideOfLoop;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageBreakOutsideOfLoop = const MessageCode(
    "BreakOutsideOfLoop",
    analyzerCode: "BREAK_OUTSIDE_OF_LOOP",
    dart2jsCode: "*ignored*",
    message:
        r"""A break statement can't be used outside of a loop or switch statement.""",
    tip: r"""Try removing the break statement.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateBuiltInIdentifierAsType =
    const Template<Message Function(Token token)>(
        messageTemplate:
            r"""The built-in identifier '#lexeme' can't be used as a type.""",
        tipTemplate: r"""Try correcting the name to match an existing type.""",
        withArguments: _withArgumentsBuiltInIdentifierAsType);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeBuiltInIdentifierAsType =
    const Code<Message Function(Token token)>(
        "BuiltInIdentifierAsType", templateBuiltInIdentifierAsType,
        analyzerCode: "BUILT_IN_IDENTIFIER_AS_TYPE",
        dart2jsCode: "EXTRANEOUS_MODIFIER");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsBuiltInIdentifierAsType(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeBuiltInIdentifierAsType,
      message: """The built-in identifier '$lexeme' can't be used as a type.""",
      tip: """Try correcting the name to match an existing type.""",
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
        analyzerCode: "BUILT_IN_IDENTIFIER_IN_DECLARATION",
        dart2jsCode: "GENERIC");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsBuiltInIdentifierInDeclaration(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeBuiltInIdentifierInDeclaration,
      message: """Can't use '$lexeme' as a name here.""",
      arguments: {'token': token});
}

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
  return new Message(codeCandidateFoundIsDefaultConstructor,
      message:
          """The class '$name' has a constructor that takes no arguments.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)> templateCannotReadPackagesFile =
    const Template<Message Function(String string)>(
        messageTemplate: r"""Unable to read '.packages' file:
  #string.""", withArguments: _withArgumentsCannotReadPackagesFile);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string)> codeCannotReadPackagesFile =
    const Code<Message Function(String string)>(
  "CannotReadPackagesFile",
  templateCannotReadPackagesFile,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCannotReadPackagesFile(String string) {
  return new Message(codeCannotReadPackagesFile,
      message: """Unable to read '.packages' file:
  $string.""", arguments: {'string': string});
}

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
  return new Message(codeCannotReadSdkSpecification,
      message: """Unable to read the 'libraries.json' specification file:
  $string.""", arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeCantDetermineConstness = messageCantDetermineConstness;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCantDetermineConstness = const MessageCode(
    "CantDetermineConstness",
    severity: Severity.error,
    message:
        r"""The keyword 'const' or 'new' is required here. Due to an implementation limit, the compiler isn't able to infer 'const' or 'new' here.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeCantInferPackagesFromManyInputs =
    messageCantInferPackagesFromManyInputs;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCantInferPackagesFromManyInputs = const MessageCode(
    "CantInferPackagesFromManyInputs",
    message:
        r"""Can't infer a .packages file when compiling multiple inputs.""",
    tip: r"""Try specifying the file explicitly with the --packages option.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeCantInferPackagesFromPackageUri =
    messageCantInferPackagesFromPackageUri;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCantInferPackagesFromPackageUri = const MessageCode(
    "CantInferPackagesFromPackageUri",
    message: r"""Can't infer a .packages file from an input 'package:*' URI.""",
    tip: r"""Try specifying the file explicitly with the --packages option.""");

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
        severity: Severity.error);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCantInferTypeDueToCircularity(String string) {
  return new Message(codeCantInferTypeDueToCircularity,
      message:
          """Can't infer the type of '$string': circularity found during type inference.""",
      tip: """Specify the type explicitly.""",
      arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)>
    templateCantInferTypeDueToInconsistentOverrides =
    const Template<Message Function(String string)>(
        messageTemplate:
            r"""Can't infer the type of '#string': overridden members must all have the same type.""",
        tipTemplate: r"""Specify the type explicitly.""",
        withArguments: _withArgumentsCantInferTypeDueToInconsistentOverrides);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string)>
    codeCantInferTypeDueToInconsistentOverrides =
    const Code<Message Function(String string)>(
  "CantInferTypeDueToInconsistentOverrides",
  templateCantInferTypeDueToInconsistentOverrides,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCantInferTypeDueToInconsistentOverrides(String string) {
  return new Message(codeCantInferTypeDueToInconsistentOverrides,
      message:
          """Can't infer the type of '$string': overridden members must all have the same type.""",
      tip: """Specify the type explicitly.""",
      arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type)>
    templateCantUseSuperBoundedTypeForInstanceCreation =
    const Template<Message Function(DartType _type)>(
        messageTemplate:
            r"""Can't use a super-bounded type for instance creation. Got '#type'.""",
        tipTemplate:
            r"""Specify a regular-bounded type instead of the super-bounded type. Note that the latter may be due to type inference.""",
        withArguments:
            _withArgumentsCantUseSuperBoundedTypeForInstanceCreation);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type)>
    codeCantUseSuperBoundedTypeForInstanceCreation =
    const Code<Message Function(DartType _type)>(
        "CantUseSuperBoundedTypeForInstanceCreation",
        templateCantUseSuperBoundedTypeForInstanceCreation,
        severity: Severity.error);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCantUseSuperBoundedTypeForInstanceCreation(
    DartType _type) {
  NameSystem nameSystem = new NameSystem();
  StringBuffer buffer = new StringBuffer();
  new Printer(buffer, syntheticNames: nameSystem).writeNode(_type);
  String type = '$buffer';

  return new Message(codeCantUseSuperBoundedTypeForInstanceCreation,
      message:
          """Can't use a super-bounded type for instance creation. Got '$type'.""",
      tip: """Specify a regular-bounded type instead of the super-bounded type. Note that the latter may be due to type inference.""",
      arguments: {'type': _type});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeCatchSyntax = messageCatchSyntax;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCatchSyntax = const MessageCode("CatchSyntax",
    dart2jsCode: "*ignored*",
    message:
        r"""'catch' must be followed by '(identifier)' or '(identifier, identifier)'.""",
    tip:
        r"""No types are needed, the first is given by 'on', the second is always 'StackTrace'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeClassInClass = messageClassInClass;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageClassInClass = const MessageCode("ClassInClass",
    analyzerCode: "CLASS_IN_CLASS",
    dart2jsCode: "*fatal*",
    message: r"""Classes can't be declared inside other classes.""",
    tip: r"""Try moving the class to the top-level.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeColonInPlaceOfIn = messageColonInPlaceOfIn;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageColonInPlaceOfIn = const MessageCode(
    "ColonInPlaceOfIn",
    analyzerCode: "COLON_IN_PLACE_OF_IN",
    dart2jsCode: "*fatal*",
    message: r"""For-in loops use 'in' rather than a colon.""",
    tip: r"""Try replacing the colon with the keyword 'in'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateConflictsWithConstructor =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Conflicts with constructor '#name'.""",
        withArguments: _withArgumentsConflictsWithConstructor);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeConflictsWithConstructor =
    const Code<Message Function(String name)>(
        "ConflictsWithConstructor", templateConflictsWithConstructor,
        severity: Severity.error);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConflictsWithConstructor(String name) {
  return new Message(codeConflictsWithConstructor,
      message: """Conflicts with constructor '$name'.""",
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
        "ConflictsWithFactory", templateConflictsWithFactory,
        severity: Severity.error);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConflictsWithFactory(String name) {
  return new Message(codeConflictsWithFactory,
      message: """Conflicts with factory '$name'.""",
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
        severity: Severity.error);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConflictsWithMember(String name) {
  return new Message(codeConflictsWithMember,
      message: """Conflicts with member '$name'.""", arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateConflictsWithMemberWarning =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Conflicts with member '#name'.""",
        withArguments: _withArgumentsConflictsWithMemberWarning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeConflictsWithMemberWarning =
    const Code<Message Function(String name)>(
        "ConflictsWithMemberWarning", templateConflictsWithMemberWarning,
        severity: Severity.errorLegacyWarning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConflictsWithMemberWarning(String name) {
  return new Message(codeConflictsWithMemberWarning,
      message: """Conflicts with member '$name'.""", arguments: {'name': name});
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
        severity: Severity.error);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConflictsWithSetter(String name) {
  return new Message(codeConflictsWithSetter,
      message: """Conflicts with setter '$name'.""", arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateConflictsWithSetterWarning =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Conflicts with setter '#name'.""",
        withArguments: _withArgumentsConflictsWithSetterWarning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeConflictsWithSetterWarning =
    const Code<Message Function(String name)>(
        "ConflictsWithSetterWarning", templateConflictsWithSetterWarning,
        severity: Severity.errorLegacyWarning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConflictsWithSetterWarning(String name) {
  return new Message(codeConflictsWithSetterWarning,
      message: """Conflicts with setter '$name'.""", arguments: {'name': name});
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
        severity: Severity.error);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConflictsWithTypeVariable(String name) {
  return new Message(codeConflictsWithTypeVariable,
      message: """Conflicts with type variable '$name'.""",
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
const Code<Null> codeConstAfterFactory = messageConstAfterFactory;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstAfterFactory = const MessageCode(
    "ConstAfterFactory",
    analyzerCode: "CONST_AFTER_FACTORY",
    dart2jsCode: "*ignored*",
    message:
        r"""The modifier 'const' should be before the modifier 'factory'.""",
    tip: r"""Try re-ordering the modifiers.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstAndCovariant = messageConstAndCovariant;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstAndCovariant = const MessageCode(
    "ConstAndCovariant",
    analyzerCode: "CONST_AND_COVARIANT",
    dart2jsCode: "*ignored*",
    message:
        r"""Members can't be declared to be both 'const' and 'covariant'.""",
    tip: r"""Try removing either the 'const' or 'covariant' keyword.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstAndFinal = messageConstAndFinal;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstAndFinal = const MessageCode("ConstAndFinal",
    analyzerCode: "CONST_AND_FINAL",
    dart2jsCode: "EXTRANEOUS_MODIFIER",
    message: r"""Members can't be declared to be both 'const' and 'final'.""",
    tip: r"""Try removing either the 'const' or 'final' keyword.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstAndVar = messageConstAndVar;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstAndVar = const MessageCode("ConstAndVar",
    analyzerCode: "CONST_AND_VAR",
    dart2jsCode: "EXTRANEOUS_MODIFIER",
    message: r"""Members can't be declared to be both 'const' and 'var'.""",
    tip: r"""Try removing either the 'const' or 'var' keyword.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstClass = messageConstClass;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstClass = const MessageCode("ConstClass",
    analyzerCode: "CONST_CLASS",
    dart2jsCode: "EXTRANEOUS_MODIFIER",
    message: r"""Classes can't be declared to be 'const'.""",
    tip:
        r"""Try removing the 'const' keyword. If you're trying to indicate that instances of the class can be constants, place the 'const' keyword on  the class' constructor(s).""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstConstructorNonFinalField =
    messageConstConstructorNonFinalField;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstConstructorNonFinalField = const MessageCode(
    "ConstConstructorNonFinalField",
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
const Code<Null> codeConstConstructorWithBody = messageConstConstructorWithBody;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstConstructorWithBody = const MessageCode(
    "ConstConstructorWithBody",
    analyzerCode: "CONST_CONSTRUCTOR_WITH_BODY",
    dart2jsCode: "*fatal*",
    message: r"""A const constructor can't have a body.""",
    tip: r"""Try removing either the 'const' keyword or the body.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstFactory = messageConstFactory;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstFactory = const MessageCode("ConstFactory",
    analyzerCode: "CONST_FACTORY",
    dart2jsCode: "*ignored*",
    message:
        r"""Only redirecting factory constructors can be declared to be 'const'.""",
    tip:
        r"""Try removing the 'const' keyword, or replacing the body with '=' followed by a valid target.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            name)> templateConstFieldWithoutInitializer = const Template<
        Message Function(String name)>(
    messageTemplate: r"""The const variable '#name' must be initialized.""",
    tipTemplate:
        r"""Try adding an initializer ('= <expression>') to the declaration.""",
    withArguments: _withArgumentsConstFieldWithoutInitializer);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeConstFieldWithoutInitializer =
    const Code<Message Function(String name)>(
        "ConstFieldWithoutInitializer", templateConstFieldWithoutInitializer,
        analyzerCode: "CONST_NOT_INITIALIZED", dart2jsCode: "*ignored*");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstFieldWithoutInitializer(String name) {
  return new Message(codeConstFieldWithoutInitializer,
      message: """The const variable '$name' must be initialized.""",
      tip:
          """Try adding an initializer ('= <expression>') to the declaration.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstMethod = messageConstMethod;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstMethod = const MessageCode("ConstMethod",
    analyzerCode: "CONST_METHOD",
    dart2jsCode: "*fatal*",
    message:
        r"""Getters, setters and methods can't be declared to be 'const'.""",
    tip: r"""Try removing the 'const' keyword.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(String name)>
    templateConstructorHasNoSuchNamedParameter =
    const Template<Message Function(String name)>(
        messageTemplate:
            r"""Constructor has no named parameter with the name '#name'.""",
        withArguments: _withArgumentsConstructorHasNoSuchNamedParameter);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)>
    codeConstructorHasNoSuchNamedParameter =
    const Code<Message Function(String name)>(
        "ConstructorHasNoSuchNamedParameter",
        templateConstructorHasNoSuchNamedParameter,
        severity: Severity.errorLegacyWarning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstructorHasNoSuchNamedParameter(String name) {
  return new Message(codeConstructorHasNoSuchNamedParameter,
      message: """Constructor has no named parameter with the name '$name'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateConstructorNotFound =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Couldn't find constructor '#name'.""",
        withArguments: _withArgumentsConstructorNotFound);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeConstructorNotFound =
    const Code<Message Function(String name)>(
        "ConstructorNotFound", templateConstructorNotFound,
        severity: Severity.errorLegacyWarning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstructorNotFound(String name) {
  return new Message(codeConstructorNotFound,
      message: """Couldn't find constructor '$name'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstructorWithReturnType =
    messageConstructorWithReturnType;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstructorWithReturnType = const MessageCode(
    "ConstructorWithReturnType",
    analyzerCode: "CONSTRUCTOR_WITH_RETURN_TYPE",
    dart2jsCode: "*fatal*",
    message: r"""Constructors can't have a return type.""",
    tip: r"""Try removing the return type.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeContinueOutsideOfLoop = messageContinueOutsideOfLoop;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageContinueOutsideOfLoop = const MessageCode(
    "ContinueOutsideOfLoop",
    analyzerCode: "CONTINUE_OUTSIDE_OF_LOOP",
    dart2jsCode: "*ignored*",
    message:
        r"""A continue statement can't be used outside of a loop or switch statement.""",
    tip: r"""Try removing the continue statement.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeContinueWithoutLabelInCase =
    messageContinueWithoutLabelInCase;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageContinueWithoutLabelInCase = const MessageCode(
    "ContinueWithoutLabelInCase",
    analyzerCode: "CONTINUE_WITHOUT_LABEL_IN_CASE",
    dart2jsCode: "*ignored*",
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
  return new Message(codeCouldNotParseUri,
      message: """Couldn't parse URI '$string':
  $string2.""", arguments: {'string': string, 'string2': string2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeCovariantAfterFinal = messageCovariantAfterFinal;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCovariantAfterFinal = const MessageCode(
    "CovariantAfterFinal",
    analyzerCode: "COVARIANT_AFTER_FINAL",
    dart2jsCode: "EXTRANEOUS_MODIFIER",
    message:
        r"""The modifier 'covariant' should be before the modifier 'final'.""",
    tip: r"""Try re-ordering the modifiers.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeCovariantAfterVar = messageCovariantAfterVar;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCovariantAfterVar = const MessageCode(
    "CovariantAfterVar",
    analyzerCode: "COVARIANT_AFTER_VAR",
    dart2jsCode: "EXTRANEOUS_MODIFIER",
    message:
        r"""The modifier 'covariant' should be before the modifier 'var'.""",
    tip: r"""Try re-ordering the modifiers.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeCovariantAndStatic = messageCovariantAndStatic;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCovariantAndStatic = const MessageCode(
    "CovariantAndStatic",
    analyzerCode: "COVARIANT_AND_STATIC",
    dart2jsCode: "EXTRANEOUS_MODIFIER",
    message:
        r"""Members can't be declared to be both 'covariant' and 'static'.""",
    tip: r"""Try removing either the 'covariant' or 'static' keyword.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeCovariantMember = messageCovariantMember;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCovariantMember = const MessageCode("CovariantMember",
    analyzerCode: "COVARIANT_MEMBER",
    dart2jsCode: "EXTRANEOUS_MODIFIER",
    message:
        r"""Getters, setters and methods can't be declared to be 'covariant'.""",
    tip: r"""Try removing the 'covariant' keyword.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String string)>
    templateCyclicClassHierarchy =
    const Template<Message Function(String name, String string)>(
        messageTemplate: r"""'#name' is a supertype of itself via '#string'.""",
        withArguments: _withArgumentsCyclicClassHierarchy);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String string)>
    codeCyclicClassHierarchy =
    const Code<Message Function(String name, String string)>(
  "CyclicClassHierarchy",
  templateCyclicClassHierarchy,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCyclicClassHierarchy(String name, String string) {
  return new Message(codeCyclicClassHierarchy,
      message: """'$name' is a supertype of itself via '$string'.""",
      arguments: {'name': name, 'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateCyclicTypedef =
    const Template<Message Function(String name)>(
        messageTemplate: r"""The typedef '#name' has a reference to itself.""",
        withArguments: _withArgumentsCyclicTypedef);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeCyclicTypedef =
    const Code<Message Function(String name)>(
  "CyclicTypedef",
  templateCyclicTypedef,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCyclicTypedef(String name) {
  return new Message(codeCyclicTypedef,
      message: """The typedef '$name' has a reference to itself.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeDeferredAfterPrefix = messageDeferredAfterPrefix;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageDeferredAfterPrefix = const MessageCode(
    "DeferredAfterPrefix",
    analyzerCode: "DEFERRED_AFTER_PREFIX",
    dart2jsCode: "*fatal*",
    message:
        r"""The deferred keyword should come immediately before the prefix ('as' clause).""",
    tip: r"""Try moving the deferred keyword before the prefix.""");

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
  "DeferredPrefixDuplicated",
  templateDeferredPrefixDuplicated,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDeferredPrefixDuplicated(String name) {
  return new Message(codeDeferredPrefixDuplicated,
      message:
          """Can't use the name '$name' for a deferred library, as the name is used elsewhere.""",
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
  return new Message(codeDeferredPrefixDuplicatedCause,
      message: """'$name' is used here.""", arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        DartType _type,
        String
            name)> templateDeferredTypeAnnotation = const Template<
        Message Function(DartType _type, String name)>(
    messageTemplate:
        r"""The type '#type' is deferred loaded via prefix '#name' and can't be used as a type annotation.""",
    tipTemplate:
        r"""Try removing 'deferred' from the import of '#name' or use a supertype of '#type' that isn't deferred.""",
    withArguments: _withArgumentsDeferredTypeAnnotation);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, String name)>
    codeDeferredTypeAnnotation =
    const Code<Message Function(DartType _type, String name)>(
        "DeferredTypeAnnotation", templateDeferredTypeAnnotation,
        analyzerCode: "TYPE_ANNOTATION_DEFERRED_CLASS",
        dart2jsCode: "*fatal*",
        severity: Severity.errorLegacyWarning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDeferredTypeAnnotation(DartType _type, String name) {
  NameSystem nameSystem = new NameSystem();
  StringBuffer buffer = new StringBuffer();
  new Printer(buffer, syntheticNames: nameSystem).writeNode(_type);
  String type = '$buffer';

  return new Message(codeDeferredTypeAnnotation,
      message:
          """The type '$type' is deferred loaded via prefix '$name' and can't be used as a type annotation.""",
      tip: """Try removing 'deferred' from the import of '$name' or use a supertype of '$type' that isn't deferred.""",
      arguments: {'type': _type, 'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(int count, int count2, String string, String string2,
            String string3)> templateDillOutlineSummary =
    const Template<
            Message Function(int count, int count2, String string,
                String string2, String string3)>(
        messageTemplate:
            r"""Indexed #count libraries (#count2 bytes) in #string, that is,
#string2 bytes/ms, and
#string3 ms/libraries.""",
        withArguments: _withArgumentsDillOutlineSummary);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
    Message Function(int count, int count2, String string, String string2,
        String string3)> codeDillOutlineSummary = const Code<
    Message Function(
        int count, int count2, String string, String string2, String string3)>(
  "DillOutlineSummary",
  templateDillOutlineSummary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDillOutlineSummary(
    int count, int count2, String string, String string2, String string3) {
  return new Message(codeDillOutlineSummary,
      message: """Indexed $count libraries ($count2 bytes) in $string, that is,
$string2 bytes/ms, and
$string3 ms/libraries.""",
      arguments: {
        'count': count,
        'count2': count2,
        'string': string,
        'string2': string2,
        'string3': string3
      });
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeDirectiveAfterDeclaration =
    messageDirectiveAfterDeclaration;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageDirectiveAfterDeclaration = const MessageCode(
    "DirectiveAfterDeclaration",
    analyzerCode: "DIRECTIVE_AFTER_DECLARATION",
    dart2jsCode: "*ignored*",
    message: r"""Directives must appear before any declarations.""",
    tip: r"""Try moving the directive before any declarations.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeDuplicateDeferred = messageDuplicateDeferred;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageDuplicateDeferred = const MessageCode(
    "DuplicateDeferred",
    analyzerCode: "DUPLICATE_DEFERRED",
    dart2jsCode: "*fatal*",
    message: r"""An import directive can only have one 'deferred' keyword.""",
    tip: r"""Try removing all but one 'deferred' keyword.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            string)> templateDuplicateLabelInSwitchStatement = const Template<
        Message Function(String string)>(
    messageTemplate:
        r"""The label '#string' was already used in this switch statement.""",
    tipTemplate: r"""Try choosing a different name for this label.""",
    withArguments: _withArgumentsDuplicateLabelInSwitchStatement);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string)>
    codeDuplicateLabelInSwitchStatement =
    const Code<Message Function(String string)>(
        "DuplicateLabelInSwitchStatement",
        templateDuplicateLabelInSwitchStatement,
        analyzerCode: "DUPLICATE_LABEL_IN_SWITCH_STATEMENT",
        dart2jsCode: "*fatal*");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicateLabelInSwitchStatement(String string) {
  return new Message(codeDuplicateLabelInSwitchStatement,
      message:
          """The label '$string' was already used in this switch statement.""",
      tip: """Try choosing a different name for this label.""",
      arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeDuplicatePrefix = messageDuplicatePrefix;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageDuplicatePrefix = const MessageCode("DuplicatePrefix",
    analyzerCode: "DUPLICATE_PREFIX",
    dart2jsCode: "*fatal*",
    message: r"""An import directive can only have one prefix ('as' clause).""",
    tip: r"""Try removing all but one prefix.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateDuplicatedDefinition =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Duplicated definition of '#name'.""",
        withArguments: _withArgumentsDuplicatedDefinition);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeDuplicatedDefinition =
    const Code<Message Function(String name)>(
  "DuplicatedDefinition",
  templateDuplicatedDefinition,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedDefinition(String name) {
  return new Message(codeDuplicatedDefinition,
      message: """Duplicated definition of '$name'.""",
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
        analyzerCode: "AMBIGUOUS_EXPORT",
        dart2jsCode: "*ignored*",
        severity: Severity.nit);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedExport(String name, Uri uri_, Uri uri2_) {
  String uri = relativizeUri(uri_);
  String uri2 = relativizeUri(uri2_);
  return new Message(codeDuplicatedExport,
      message: """'$name' is exported from both '$uri' and '$uri2'.""",
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
        "DuplicatedExportInType", templateDuplicatedExportInType,
        severity: Severity.errorLegacyWarning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedExportInType(String name, Uri uri_, Uri uri2_) {
  String uri = relativizeUri(uri_);
  String uri2 = relativizeUri(uri2_);
  return new Message(codeDuplicatedExportInType,
      message: """'$name' is exported from both '$uri' and '$uri2'.""",
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
        severity: Severity.nit);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedImport(String name, Uri uri_, Uri uri2_) {
  String uri = relativizeUri(uri_);
  String uri2 = relativizeUri(uri2_);
  return new Message(codeDuplicatedImport,
      message: """'$name' is imported from both '$uri' and '$uri2'.""",
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
        severity: Severity.errorLegacyWarning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedImportInType(String name, Uri uri_, Uri uri2_) {
  String uri = relativizeUri(uri_);
  String uri2 = relativizeUri(uri2_);
  return new Message(codeDuplicatedImportInType,
      message: """'$name' is imported from both '$uri' and '$uri2'.""",
      arguments: {'name': name, 'uri': uri_, 'uri2': uri2_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateDuplicatedModifier =
    const Template<Message Function(Token token)>(
        messageTemplate: r"""The modifier '#lexeme' was already specified.""",
        tipTemplate: r"""Try removing all but one occurance of the modifier.""",
        withArguments: _withArgumentsDuplicatedModifier);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeDuplicatedModifier =
    const Code<Message Function(Token token)>(
        "DuplicatedModifier", templateDuplicatedModifier,
        analyzerCode: "DUPLICATED_MODIFIER",
        dart2jsCode: "EXTRANEOUS_MODIFIER");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedModifier(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeDuplicatedModifier,
      message: """The modifier '$lexeme' was already specified.""",
      tip: """Try removing all but one occurance of the modifier.""",
      arguments: {'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateDuplicatedName =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Duplicated name: '#name'.""",
        withArguments: _withArgumentsDuplicatedName);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeDuplicatedName =
    const Code<Message Function(String name)>(
  "DuplicatedName",
  templateDuplicatedName,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedName(String name) {
  return new Message(codeDuplicatedName,
      message: """Duplicated name: '$name'.""", arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateDuplicatedParameterName =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Duplicated parameter name '#name'.""",
        withArguments: _withArgumentsDuplicatedParameterName);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeDuplicatedParameterName =
    const Code<Message Function(String name)>(
  "DuplicatedParameterName",
  templateDuplicatedParameterName,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedParameterName(String name) {
  return new Message(codeDuplicatedParameterName,
      message: """Duplicated parameter name '$name'.""",
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
  return new Message(codeDuplicatedParameterNameCause,
      message: """Other parameter named '$name'.""", arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeEmptyNamedParameterList = messageEmptyNamedParameterList;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageEmptyNamedParameterList = const MessageCode(
    "EmptyNamedParameterList",
    analyzerCode: "MISSING_IDENTIFIER",
    dart2jsCode: "EMPTY_NAMED_PARAMETER_LIST",
    message: r"""Named parameter lists cannot be empty.""",
    tip: r"""Try adding a named parameter to the list.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeEmptyOptionalParameterList =
    messageEmptyOptionalParameterList;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageEmptyOptionalParameterList = const MessageCode(
    "EmptyOptionalParameterList",
    analyzerCode: "MISSING_IDENTIFIER",
    dart2jsCode: "EMPTY_OPTIONAL_PARAMETER_LIST",
    message: r"""Optional parameter lists cannot be empty.""",
    tip: r"""Try adding an optional parameter to the list.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeEncoding = messageEncoding;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageEncoding = const MessageCode("Encoding",
    dart2jsCode: "*fatal*", message: r"""Unable to decode bytes as UTF-8.""");

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
    const Code<Message Function(String name)>(
  "EnumConstantSameNameAsEnclosing",
  templateEnumConstantSameNameAsEnclosing,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsEnumConstantSameNameAsEnclosing(String name) {
  return new Message(codeEnumConstantSameNameAsEnclosing,
      message:
          """Name of enum constant '$name' can't be the same as the enum's own name.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeEnumDeclarationEmpty = messageEnumDeclarationEmpty;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageEnumDeclarationEmpty = const MessageCode(
    "EnumDeclarationEmpty",
    analyzerCode: "EMPTY_ENUM_BODY",
    dart2jsCode: "*ignored*",
    message: r"""An enum declaration can't be empty.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeEnumInClass = messageEnumInClass;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageEnumInClass = const MessageCode("EnumInClass",
    analyzerCode: "ENUM_IN_CLASS",
    dart2jsCode: "*fatal*",
    message: r"""Enums can't be declared inside classes.""",
    tip: r"""Try moving the enum to the top-level.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeEqualityCannotBeEqualityOperand =
    messageEqualityCannotBeEqualityOperand;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageEqualityCannotBeEqualityOperand = const MessageCode(
    "EqualityCannotBeEqualityOperand",
    analyzerCode: "EQUALITY_CANNOT_BE_EQUALITY_OPERAND",
    dart2jsCode: "*fatal*",
    message:
        r"""An equality expression can't be an operand of another equality expression.""",
    tip: r"""Try re-writing the expression.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExpectedAnInitializer = messageExpectedAnInitializer;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedAnInitializer = const MessageCode(
    "ExpectedAnInitializer",
    analyzerCode: "MISSING_INITIALIZER",
    dart2jsCode: "*fatal*",
    message: r"""Expected an initializer.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExpectedBlock = messageExpectedBlock;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedBlock = const MessageCode("ExpectedBlock",
    analyzerCode: "EXPECTED_TOKEN",
    dart2jsCode: "*fatal*",
    message: r"""Expected a block.""",
    tip: r"""Try adding {}.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExpectedBlockToSkip = messageExpectedBlockToSkip;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedBlockToSkip = const MessageCode(
    "ExpectedBlockToSkip",
    analyzerCode: "MISSING_FUNCTION_BODY",
    dart2jsCode: "NATIVE_OR_BODY_EXPECTED",
    message: r"""Expected a function body or '=>'.""",
    tip: r"""Try adding {}.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExpectedBody = messageExpectedBody;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedBody = const MessageCode("ExpectedBody",
    analyzerCode: "MISSING_FUNCTION_BODY",
    dart2jsCode: "BODY_EXPECTED",
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
        analyzerCode: "EXPECTED_TOKEN",
        dart2jsCode: "MISSING_TOKEN_BEFORE_THIS");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedButGot(String string) {
  return new Message(codeExpectedButGot,
      message: """Expected '$string' before this.""",
      arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateExpectedClassBody =
    const Template<Message Function(Token token)>(
        messageTemplate: r"""Expected a class body, but got '#lexeme'.""",
        withArguments: _withArgumentsExpectedClassBody);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeExpectedClassBody =
    const Code<Message Function(Token token)>(
        "ExpectedClassBody", templateExpectedClassBody,
        analyzerCode: "MISSING_CLASS_BODY", dart2jsCode: "*fatal*");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedClassBody(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeExpectedClassBody,
      message: """Expected a class body, but got '$lexeme'.""",
      arguments: {'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateExpectedClassBodyToSkip =
    const Template<Message Function(Token token)>(
        messageTemplate: r"""Expected a class body, but got '#lexeme'.""",
        withArguments: _withArgumentsExpectedClassBodyToSkip);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeExpectedClassBodyToSkip =
    const Code<Message Function(Token token)>(
        "ExpectedClassBodyToSkip", templateExpectedClassBodyToSkip,
        analyzerCode: "MISSING_CLASS_BODY", dart2jsCode: "*fatal*");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedClassBodyToSkip(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeExpectedClassBodyToSkip,
      message: """Expected a class body, but got '$lexeme'.""",
      arguments: {'token': token});
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
        analyzerCode: "EXPECTED_CLASS_MEMBER", dart2jsCode: "*fatal*");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedClassMember(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeExpectedClassMember,
      message: """Expected a class member, but got '$lexeme'.""",
      arguments: {'token': token});
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
        analyzerCode: "EXPECTED_EXECUTABLE", dart2jsCode: "*fatal*");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedDeclaration(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeExpectedDeclaration,
      message: """Expected a declaration, but got '$lexeme'.""",
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
        analyzerCode: "MISSING_FUNCTION_BODY", dart2jsCode: "NATIVE_OR_FATAL");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedFunctionBody(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeExpectedFunctionBody,
      message: """Expected a function body, but got '$lexeme'.""",
      arguments: {'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExpectedHexDigit = messageExpectedHexDigit;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedHexDigit = const MessageCode(
    "ExpectedHexDigit",
    analyzerCode: "MISSING_HEX_DIGIT",
    dart2jsCode: "HEX_DIGIT_EXPECTED",
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
        analyzerCode: "MISSING_IDENTIFIER",
        dart2jsCode: "*fatal*",
        severity: Severity.error);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedIdentifier(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeExpectedIdentifier,
      message: """Expected an identifier, but got '$lexeme'.""",
      arguments: {'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExpectedOpenParens = messageExpectedOpenParens;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedOpenParens = const MessageCode(
    "ExpectedOpenParens",
    dart2jsCode: "GENERIC",
    message: r"""Expected '('.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExpectedStatement = messageExpectedStatement;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedStatement = const MessageCode(
    "ExpectedStatement",
    analyzerCode: "MISSING_STATEMENT",
    dart2jsCode: "*fatal*",
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
        analyzerCode: "EXPECTED_STRING_LITERAL", dart2jsCode: "*fatal*");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedString(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeExpectedString,
      message: """Expected a String, but got '$lexeme'.""",
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
        analyzerCode: "EXPECTED_TOKEN", dart2jsCode: "*fatal*");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedToken(String string) {
  return new Message(codeExpectedToken,
      message: """Expected to find '$string'.""",
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
        analyzerCode: "EXPECTED_TYPE_NAME",
        dart2jsCode: "*fatal*",
        severity: Severity.error);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedType(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeExpectedType,
      message: """Expected a type, but got '$lexeme'.""",
      arguments: {'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExpectedUri = messageExpectedUri;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedUri =
    const MessageCode("ExpectedUri", message: r"""Expected a URI.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExportAfterPart = messageExportAfterPart;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExportAfterPart = const MessageCode("ExportAfterPart",
    analyzerCode: "EXPORT_DIRECTIVE_AFTER_PART_DIRECTIVE",
    dart2jsCode: "*ignored*",
    message: r"""Export directives must preceed part directives.""",
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
        severity: Severity.nit);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExportHidesExport(String name, Uri uri_, Uri uri2_) {
  String uri = relativizeUri(uri_);
  String uri2 = relativizeUri(uri2_);
  return new Message(codeExportHidesExport,
      message: """Export of '$name' (from '$uri') hides export from '$uri2'.""",
      arguments: {'name': name, 'uri': uri_, 'uri2': uri2_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExpressionNotMetadata = messageExpressionNotMetadata;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpressionNotMetadata = const MessageCode(
    "ExpressionNotMetadata",
    message:
        r"""This can't be used as metadata; metadata should be a reference to a compile-time constant variable, or a call to a constant constructor.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateExtendingEnum =
    const Template<Message Function(String name)>(
        messageTemplate:
            r"""'#name' is an enum and can't be extended or implemented.""",
        withArguments: _withArgumentsExtendingEnum);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeExtendingEnum =
    const Code<Message Function(String name)>(
  "ExtendingEnum",
  templateExtendingEnum,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExtendingEnum(String name) {
  return new Message(codeExtendingEnum,
      message: """'$name' is an enum and can't be extended or implemented.""",
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
        analyzerCode: "EXTENDS_DISALLOWED_CLASS", dart2jsCode: "*ignored*");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExtendingRestricted(String name) {
  return new Message(codeExtendingRestricted,
      message:
          """'$name' is restricted and can't be extended or implemented.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExternalAfterConst = messageExternalAfterConst;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExternalAfterConst = const MessageCode(
    "ExternalAfterConst",
    analyzerCode: "EXTERNAL_AFTER_CONST",
    dart2jsCode: "EXTRANEOUS_MODIFIER",
    message:
        r"""The modifier 'external' should be before the modifier 'const'.""",
    tip: r"""Try re-ordering the modifiers.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExternalAfterFactory = messageExternalAfterFactory;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExternalAfterFactory = const MessageCode(
    "ExternalAfterFactory",
    analyzerCode: "EXTERNAL_AFTER_FACTORY",
    dart2jsCode: "*ignored*",
    message:
        r"""The modifier 'external' should be before the modifier 'factory'.""",
    tip: r"""Try re-ordering the modifiers.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExternalAfterStatic = messageExternalAfterStatic;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExternalAfterStatic = const MessageCode(
    "ExternalAfterStatic",
    analyzerCode: "EXTERNAL_AFTER_STATIC",
    dart2jsCode: "EXTRANEOUS_MODIFIER",
    message:
        r"""The modifier 'external' should be before the modifier 'static'.""",
    tip: r"""Try re-ordering the modifiers.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExternalClass = messageExternalClass;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExternalClass = const MessageCode("ExternalClass",
    analyzerCode: "EXTERNAL_CLASS",
    dart2jsCode: "*ignored*",
    message: r"""Classes can't be declared to be 'external'.""",
    tip: r"""Try removing the keyword 'external'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExternalConstructorWithBody =
    messageExternalConstructorWithBody;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExternalConstructorWithBody = const MessageCode(
    "ExternalConstructorWithBody",
    analyzerCode: "EXTERNAL_CONSTRUCTOR_WITH_BODY",
    dart2jsCode: "*ignored*",
    message: r"""External constructors can't have a body.""",
    tip:
        r"""Try removing the body of the constructor, or removing the keyword 'external'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExternalEnum = messageExternalEnum;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExternalEnum = const MessageCode("ExternalEnum",
    analyzerCode: "EXTERNAL_ENUM",
    dart2jsCode: "*ignored*",
    message: r"""Enums can't be declared to be 'external'.""",
    tip: r"""Try removing the keyword 'external'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExternalFactoryRedirection =
    messageExternalFactoryRedirection;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExternalFactoryRedirection = const MessageCode(
    "ExternalFactoryRedirection",
    analyzerCode: "EXTERNAL_CONSTRUCTOR_WITH_BODY",
    dart2jsCode: "*ignored*",
    message: r"""A redirecting factory can't be external.""",
    tip: r"""Try removing the 'external' modifier.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExternalFactoryWithBody = messageExternalFactoryWithBody;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExternalFactoryWithBody = const MessageCode(
    "ExternalFactoryWithBody",
    analyzerCode: "EXTERNAL_CONSTRUCTOR_WITH_BODY",
    dart2jsCode: "*ignored*",
    message: r"""External factories can't have a body.""",
    tip:
        r"""Try removing the body of the factory, or removing the keyword 'external'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExternalField = messageExternalField;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExternalField = const MessageCode("ExternalField",
    analyzerCode: "EXTERNAL_FIELD",
    dart2jsCode: "EXTRANEOUS_MODIFIER",
    message: r"""Fields can't be declared to be 'external'.""",
    tip: r"""Try removing the keyword 'external'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExternalMethodWithBody = messageExternalMethodWithBody;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExternalMethodWithBody = const MessageCode(
    "ExternalMethodWithBody",
    analyzerCode: "EXTERNAL_METHOD_WITH_BODY",
    dart2jsCode: "*ignored*",
    message: r"""An external or native method can't have a body.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExternalTypedef = messageExternalTypedef;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExternalTypedef = const MessageCode("ExternalTypedef",
    analyzerCode: "EXTERNAL_TYPEDEF",
    dart2jsCode: "*ignored*",
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
        analyzerCode: "EXTRANEOUS_MODIFIER",
        dart2jsCode: "EXTRANEOUS_MODIFIER");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExtraneousModifier(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeExtraneousModifier,
      message: """Can't have modifier '$lexeme' here.""",
      tip: """Try removing '$lexeme'.""",
      arguments: {'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeFactoryNotSync = messageFactoryNotSync;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFactoryNotSync = const MessageCode("FactoryNotSync",
    dart2jsCode: "*ignored*",
    message: r"""Factories can't use 'async', 'async*', or 'sync*'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeFactoryTopLevelDeclaration =
    messageFactoryTopLevelDeclaration;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFactoryTopLevelDeclaration = const MessageCode(
    "FactoryTopLevelDeclaration",
    analyzerCode: "FACTORY_TOP_LEVEL_DECLARATION",
    dart2jsCode: "*fatal*",
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
  return new Message(codeFastaCLIArgumentRequired,
      message: """Expected value after '$name'.""", arguments: {'name': name});
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

  --
    Stop option parsing, the rest of the command line is assumed to be
    file names or arguments to the Dart program.

  --packages=<file>
    Use package resolution configuration <file>, which should contain a mapping
    of package names to paths.

  --platform=<file>
    Read the SDK platform from <file>, which should be in Dill/Kernel IR format
    and contain the Dart SDK.

  --target=none|vm|vmcc|vmreify|flutter
    Specify the target configuration.

  --verify
    Check that the generated output is free of various problems. This is mostly
    useful for developers of this compiler or Kernel transformations.

  --dump-ir
    Print compiled libraries in Kernel source notation.

  --exclude-source
    Do not include source code in the dill file.

  --compile-sdk=<sdk>
    Compile the SDK from scratch instead of reading it from a .dill file
    (see --platform).

  --sdk=<sdk>
    Location of the SDK sources for use when compiling additional platform
    libraries.

  --fatal=errors
  --fatal=warnings
  --fatal=nits
    Makes messages of the given kinds fatal, that is, immediately stop the
    compiler with a non-zero exit-code. In --verbose mode, also display an
    internal stack trace from the compiler. Multiple kinds can be separated by
    commas, for example, --fatal=errors,warnings.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeFastaUsageShort = messageFastaUsageShort;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFastaUsageShort =
    const MessageCode("FastaUsageShort", message: r"""Frequently used options:

  -o <file> Generate the output into <file>.
  -h        Display this message (add -v for information about all options).""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeFieldInitializerOutsideConstructor =
    messageFieldInitializerOutsideConstructor;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFieldInitializerOutsideConstructor = const MessageCode(
    "FieldInitializerOutsideConstructor",
    analyzerCode: "FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR",
    dart2jsCode: "*fatal*",
    message: r"""Field formal parameters can only be used in a constructor.""",
    tip: r"""Try removing 'this.'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeFinalAndCovariant = messageFinalAndCovariant;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFinalAndCovariant = const MessageCode(
    "FinalAndCovariant",
    analyzerCode: "FINAL_AND_COVARIANT",
    dart2jsCode: "*ignored*",
    message:
        r"""Members can't be declared to be both 'final' and 'covariant'.""",
    tip: r"""Try removing either the 'final' or 'covariant' keyword.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeFinalAndVar = messageFinalAndVar;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFinalAndVar = const MessageCode("FinalAndVar",
    analyzerCode: "FINAL_AND_VAR",
    dart2jsCode: "EXTRANEOUS_MODIFIER",
    message: r"""Members can't be declared to be both 'final' and 'var'.""",
    tip: r"""Try removing the keyword 'var'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            name)> templateFinalFieldWithoutInitializer = const Template<
        Message Function(String name)>(
    messageTemplate: r"""The final variable '#name' must be initialized.""",
    tipTemplate:
        r"""Try adding an initializer ('= <expression>') to the declaration.""",
    withArguments: _withArgumentsFinalFieldWithoutInitializer);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeFinalFieldWithoutInitializer =
    const Code<Message Function(String name)>(
        "FinalFieldWithoutInitializer", templateFinalFieldWithoutInitializer,
        analyzerCode: "FINAL_NOT_INITIALIZED", dart2jsCode: "*ignored*");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFinalFieldWithoutInitializer(String name) {
  return new Message(codeFinalFieldWithoutInitializer,
      message: """The final variable '$name' must be initialized.""",
      tip:
          """Try adding an initializer ('= <expression>') to the declaration.""",
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
        severity: Severity.errorLegacyWarning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFinalInstanceVariableAlreadyInitialized(String name) {
  return new Message(codeFinalInstanceVariableAlreadyInitialized,
      message:
          """'$name' is a final instance variable that has already been initialized.""",
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
  return new Message(codeFinalInstanceVariableAlreadyInitializedCause,
      message: """'$name' was initialized here.""", arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(String name)> templateFunctionHasNoSuchNamedParameter =
    const Template<Message Function(String name)>(
        messageTemplate:
            r"""Function has no named parameter with the name '#name'.""",
        withArguments: _withArgumentsFunctionHasNoSuchNamedParameter);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeFunctionHasNoSuchNamedParameter =
    const Code<Message Function(String name)>("FunctionHasNoSuchNamedParameter",
        templateFunctionHasNoSuchNamedParameter,
        severity: Severity.errorLegacyWarning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFunctionHasNoSuchNamedParameter(String name) {
  return new Message(codeFunctionHasNoSuchNamedParameter,
      message: """Function has no named parameter with the name '$name'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeFunctionTypeDefaultValue = messageFunctionTypeDefaultValue;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFunctionTypeDefaultValue = const MessageCode(
    "FunctionTypeDefaultValue",
    analyzerCode: "DEFAULT_VALUE_IN_FUNCTION_TYPE",
    dart2jsCode: "*ignored*",
    message: r"""Can't have a default value in a function type.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeFunctionTypedParameterVar =
    messageFunctionTypedParameterVar;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFunctionTypedParameterVar = const MessageCode(
    "FunctionTypedParameterVar",
    analyzerCode: "FUNCTION_TYPED_PARAMETER_VAR",
    dart2jsCode: "*fatal*",
    message:
        r"""Function-typed parameters can't specify 'const', 'final' or 'var' in place of a return type.""",
    tip: r"""Try replacing the keyword with a return type.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeGeneratorReturnsValue = messageGeneratorReturnsValue;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageGeneratorReturnsValue = const MessageCode(
    "GeneratorReturnsValue",
    analyzerCode: "RETURN_IN_GENERATOR",
    dart2jsCode: "*ignored*",
    message: r"""'sync*' and 'async*' can't return a value.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateGetterNotFound =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Getter not found: '#name'.""",
        withArguments: _withArgumentsGetterNotFound);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeGetterNotFound =
    const Code<Message Function(String name)>(
        "GetterNotFound", templateGetterNotFound,
        severity: Severity.errorLegacyWarning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsGetterNotFound(String name) {
  return new Message(codeGetterNotFound,
      message: """Getter not found: '$name'.""", arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeGetterWithFormals = messageGetterWithFormals;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageGetterWithFormals = const MessageCode(
    "GetterWithFormals",
    analyzerCode: "GETTER_WITH_PARAMETERS",
    dart2jsCode: "*ignored*",
    message: r"""A getter can't have formal parameters.""",
    tip: r"""Try removing '(...)'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeIllegalAssignmentToNonAssignable =
    messageIllegalAssignmentToNonAssignable;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageIllegalAssignmentToNonAssignable = const MessageCode(
    "IllegalAssignmentToNonAssignable",
    analyzerCode: "ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE",
    dart2jsCode: "*fatal*",
    message: r"""Illegal assignment to non-assignable expression.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String name2)>
    templateIllegalMethodName =
    const Template<Message Function(String name, String name2)>(
        messageTemplate: r"""'#name' isn't a legal method name.""",
        tipTemplate: r"""Did you mean '#name2'?""",
        withArguments: _withArgumentsIllegalMethodName);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String name2)> codeIllegalMethodName =
    const Code<Message Function(String name, String name2)>(
  "IllegalMethodName",
  templateIllegalMethodName,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIllegalMethodName(String name, String name2) {
  return new Message(codeIllegalMethodName,
      message: """'$name' isn't a legal method name.""",
      tip: """Did you mean '$name2'?""",
      arguments: {'name': name, 'name2': name2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateIllegalMixin =
    const Template<Message Function(String name)>(
        messageTemplate: r"""The type '#name' can't be mixed in.""",
        withArguments: _withArgumentsIllegalMixin);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeIllegalMixin =
    const Code<Message Function(String name)>(
  "IllegalMixin",
  templateIllegalMixin,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIllegalMixin(String name) {
  return new Message(codeIllegalMixin,
      message: """The type '$name' can't be mixed in.""",
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
  "IllegalMixinDueToConstructors",
  templateIllegalMixinDueToConstructors,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIllegalMixinDueToConstructors(String name) {
  return new Message(codeIllegalMixinDueToConstructors,
      message: """Can't use '$name' as a mixin because it has constructors.""",
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
  return new Message(codeIllegalMixinDueToConstructorsCause,
      message: """This constructor prevents using '$name' as a mixin.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeImplementsBeforeExtends = messageImplementsBeforeExtends;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageImplementsBeforeExtends = const MessageCode(
    "ImplementsBeforeExtends",
    analyzerCode: "IMPLEMENTS_BEFORE_EXTENDS",
    dart2jsCode: "*ignored*",
    message: r"""The extends clause must be before the implements clause.""",
    tip: r"""Try moving the extends clause before the implements clause.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeImplementsBeforeWith = messageImplementsBeforeWith;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageImplementsBeforeWith = const MessageCode(
    "ImplementsBeforeWith",
    analyzerCode: "IMPLEMENTS_BEFORE_WITH",
    dart2jsCode: "*ignored*",
    message: r"""The with clause must be before the implements clause.""",
    tip: r"""Try moving the with clause before the implements clause.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        DartType
            _type)> templateImplicitCallOfNonMethod = const Template<
        Message Function(DartType _type)>(
    messageTemplate:
        r"""Can't invoke the type '#type' because its declaration of `.call` is not a method.""",
    tipTemplate: r"""Change .call to a method or explicitly invoke .call.""",
    withArguments: _withArgumentsImplicitCallOfNonMethod);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type)> codeImplicitCallOfNonMethod =
    const Code<Message Function(DartType _type)>(
        "ImplicitCallOfNonMethod", templateImplicitCallOfNonMethod,
        severity: Severity.error);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsImplicitCallOfNonMethod(DartType _type) {
  NameSystem nameSystem = new NameSystem();
  StringBuffer buffer = new StringBuffer();
  new Printer(buffer, syntheticNames: nameSystem).writeNode(_type);
  String type = '$buffer';

  return new Message(codeImplicitCallOfNonMethod,
      message:
          """Can't invoke the type '$type' because its declaration of `.call` is not a method.""",
      tip: """Change .call to a method or explicitly invoke .call.""",
      arguments: {'type': _type});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeImportAfterPart = messageImportAfterPart;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageImportAfterPart = const MessageCode("ImportAfterPart",
    analyzerCode: "IMPORT_DIRECTIVE_AFTER_PART_DIRECTIVE",
    dart2jsCode: "*ignored*",
    message: r"""Import directives must preceed part directives.""",
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
        severity: Severity.nit);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsImportHidesImport(String name, Uri uri_, Uri uri2_) {
  String uri = relativizeUri(uri_);
  String uri2 = relativizeUri(uri2_);
  return new Message(codeImportHidesImport,
      message: """Import of '$name' (from '$uri') hides import from '$uri2'.""",
      arguments: {'name': name, 'uri': uri_, 'uri2': uri2_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInitializedVariableInForEach =
    messageInitializedVariableInForEach;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInitializedVariableInForEach = const MessageCode(
    "InitializedVariableInForEach",
    analyzerCode: "INITIALIZED_VARIABLE_IN_FOR_EACH",
    dart2jsCode: "*fatal*",
    message: r"""The loop variable in a for-each loop can't be initialized.""",
    tip:
        r"""Try removing the initializer, or using a different kind of loop.""");

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
      message: """Input file not found: $uri.""", arguments: {'uri': uri_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        Token
            token)> templateIntegerLiteralIsOutOfRange = const Template<
        Message Function(Token token)>(
    messageTemplate:
        r"""The integer literal #lexeme can't be represented in 64 bits.""",
    tipTemplate:
        r"""Try using the BigInt class if you need an integer larger than 9,223,372,036,854,775,807 or less than -9,223,372,036,854,775,808.""",
    withArguments: _withArgumentsIntegerLiteralIsOutOfRange);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeIntegerLiteralIsOutOfRange =
    const Code<Message Function(Token token)>(
        "IntegerLiteralIsOutOfRange", templateIntegerLiteralIsOutOfRange,
        analyzerCode: "INTEGER_LITERAL_OUT_OF_RANGE", dart2jsCode: "*fatal*");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIntegerLiteralIsOutOfRange(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeIntegerLiteralIsOutOfRange,
      message:
          """The integer literal $lexeme can't be represented in 64 bits.""",
      tip:
          """Try using the BigInt class if you need an integer larger than 9,223,372,036,854,775,807 or less than -9,223,372,036,854,775,808.""",
      arguments: {'token': token});
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
  String uri = relativizeUri(uri_);
  return new Message(codeInternalProblemConstructorNotFound,
      message: """No constructor named '$name' in '$uri'.""",
      arguments: {'name': name, 'uri': uri_});
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
const Template<Message Function(String string)>
    templateInternalProblemMissingSeverity =
    const Template<Message Function(String string)>(
        messageTemplate: r"""Message code missing severity: #string""",
        withArguments: _withArgumentsInternalProblemMissingSeverity);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string)> codeInternalProblemMissingSeverity =
    const Code<Message Function(String string)>(
        "InternalProblemMissingSeverity",
        templateInternalProblemMissingSeverity,
        severity: Severity.internalProblem);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemMissingSeverity(String string) {
  return new Message(codeInternalProblemMissingSeverity,
      message: """Message code missing severity: $string""",
      arguments: {'string': string});
}

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
  return new Message(codeInternalProblemNotFound,
      message: """Couldn't find '$name'.""", arguments: {'name': name});
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
  return new Message(codeInternalProblemNotFoundIn,
      message: """Couldn't find '$name' in '$name2'.""",
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
  return new Message(codeInternalProblemPrivateConstructorAccess,
      message: """Can't access private constructor '$name'.""",
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
  return new Message(codeInternalProblemStackNotEmpty,
      message: """$name.stack isn't empty:
  $string""", arguments: {'name': name, 'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateInternalProblemSuperclassNotFound =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Superclass not found '#name'.""",
        withArguments: _withArgumentsInternalProblemSuperclassNotFound);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)>
    codeInternalProblemSuperclassNotFound =
    const Code<Message Function(String name)>(
        "InternalProblemSuperclassNotFound",
        templateInternalProblemSuperclassNotFound,
        severity: Severity.internalProblem);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemSuperclassNotFound(String name) {
  return new Message(codeInternalProblemSuperclassNotFound,
      message: """Superclass not found '$name'.""", arguments: {'name': name});
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
  return new Message(codeInternalProblemUnexpected,
      message: """Expected '$string', but got '$string2'.""",
      arguments: {'string': string, 'string2': string2});
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
  return new Message(codeInternalProblemUnhandled,
      message: """Unhandled $string in $string2.""",
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
  return new Message(codeInternalProblemUnimplemented,
      message: """Unimplemented $string.""", arguments: {'string': string});
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
  return new Message(codeInternalProblemUnsupported,
      message: """Unsupported operation: '$name'.""",
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
      message: """The URI '$uri' has no scheme.""", arguments: {'uri': uri_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)>
    templateInternalVerificationError =
    const Template<Message Function(String string)>(
        messageTemplate: r"""Verification of the generated program failed:
#string""", withArguments: _withArgumentsInternalVerificationError);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string)> codeInternalVerificationError =
    const Code<Message Function(String string)>(
  "InternalVerificationError",
  templateInternalVerificationError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalVerificationError(String string) {
  return new Message(codeInternalVerificationError,
      message: """Verification of the generated program failed:
$string""", arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInterpolationInUri = messageInterpolationInUri;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInterpolationInUri = const MessageCode(
    "InterpolationInUri",
    analyzerCode: "INVALID_LITERAL_IN_CONFIGURATION",
    dart2jsCode: "*fatal*",
    message: r"""Can't use string interpolation in a URI.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        DartType _type,
        DartType
            _type2)> templateInvalidAssignment = const Template<
        Message Function(DartType _type, DartType _type2)>(
    messageTemplate:
        r"""A value of type '#type' can't be assigned to a variable of type '#type2'.""",
    tipTemplate:
        r"""Try changing the type of the left hand side, or casting the right hand side to '#type2'.""",
    withArguments: _withArgumentsInvalidAssignment);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
    codeInvalidAssignment =
    const Code<Message Function(DartType _type, DartType _type2)>(
        "InvalidAssignment", templateInvalidAssignment,
        analyzerCode: "INVALID_ASSIGNMENT", dart2jsCode: "*ignored*");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidAssignment(DartType _type, DartType _type2) {
  NameSystem nameSystem = new NameSystem();
  StringBuffer buffer = new StringBuffer();
  new Printer(buffer, syntheticNames: nameSystem).writeNode(_type);
  String type = '$buffer';

  buffer = new StringBuffer();
  new Printer(buffer, syntheticNames: nameSystem).writeNode(_type2);
  String type2 = '$buffer';

  return new Message(codeInvalidAssignment,
      message:
          """A value of type '$type' can't be assigned to a variable of type '$type2'.""",
      tip: """Try changing the type of the left hand side, or casting the right hand side to '$type2'.""",
      arguments: {'type': _type, 'type2': _type2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInvalidAwaitFor = messageInvalidAwaitFor;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidAwaitFor = const MessageCode("InvalidAwaitFor",
    analyzerCode: "INVALID_AWAIT_IN_FOR",
    dart2jsCode: "INVALID_AWAIT_FOR",
    message:
        r"""The keyword 'await' isn't allowed for a normal 'for' statement.""",
    tip: r"""Try removing the keyword, or use a for-each statement.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        DartType _type,
        DartType
            _type2)> templateInvalidCastFunctionExpr = const Template<
        Message Function(DartType _type, DartType _type2)>(
    messageTemplate:
        r"""The function expression type '#type' isn't of expected type '#type2'.""",
    tipTemplate:
        r"""Change the type of the function expression or the context in which it is used.""",
    withArguments: _withArgumentsInvalidCastFunctionExpr);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
    codeInvalidCastFunctionExpr =
    const Code<Message Function(DartType _type, DartType _type2)>(
        "InvalidCastFunctionExpr", templateInvalidCastFunctionExpr,
        analyzerCode: "INVALID_CAST_FUNCTION_EXPR", dart2jsCode: "*ignored*");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidCastFunctionExpr(DartType _type, DartType _type2) {
  NameSystem nameSystem = new NameSystem();
  StringBuffer buffer = new StringBuffer();
  new Printer(buffer, syntheticNames: nameSystem).writeNode(_type);
  String type = '$buffer';

  buffer = new StringBuffer();
  new Printer(buffer, syntheticNames: nameSystem).writeNode(_type2);
  String type2 = '$buffer';

  return new Message(codeInvalidCastFunctionExpr,
      message:
          """The function expression type '$type' isn't of expected type '$type2'.""",
      tip: """Change the type of the function expression or the context in which it is used.""",
      arguments: {'type': _type, 'type2': _type2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        DartType _type,
        DartType
            _type2)> templateInvalidCastLiteralList = const Template<
        Message Function(DartType _type, DartType _type2)>(
    messageTemplate:
        r"""The list literal type '#type' isn't of expected type '#type2'.""",
    tipTemplate:
        r"""Change the type of the list literal or the context in which it is used.""",
    withArguments: _withArgumentsInvalidCastLiteralList);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
    codeInvalidCastLiteralList =
    const Code<Message Function(DartType _type, DartType _type2)>(
        "InvalidCastLiteralList", templateInvalidCastLiteralList,
        analyzerCode: "INVALID_CAST_LITERAL_LIST", dart2jsCode: "*ignored*");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidCastLiteralList(DartType _type, DartType _type2) {
  NameSystem nameSystem = new NameSystem();
  StringBuffer buffer = new StringBuffer();
  new Printer(buffer, syntheticNames: nameSystem).writeNode(_type);
  String type = '$buffer';

  buffer = new StringBuffer();
  new Printer(buffer, syntheticNames: nameSystem).writeNode(_type2);
  String type2 = '$buffer';

  return new Message(codeInvalidCastLiteralList,
      message:
          """The list literal type '$type' isn't of expected type '$type2'.""",
      tip:
          """Change the type of the list literal or the context in which it is used.""",
      arguments: {'type': _type, 'type2': _type2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        DartType _type,
        DartType
            _type2)> templateInvalidCastLiteralMap = const Template<
        Message Function(DartType _type, DartType _type2)>(
    messageTemplate:
        r"""The map literal type '#type' isn't of expected type '#type2'.""",
    tipTemplate:
        r"""Change the type of the map literal or the context in which it is used.""",
    withArguments: _withArgumentsInvalidCastLiteralMap);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
    codeInvalidCastLiteralMap =
    const Code<Message Function(DartType _type, DartType _type2)>(
        "InvalidCastLiteralMap", templateInvalidCastLiteralMap,
        analyzerCode: "INVALID_CAST_LITERAL_MAP", dart2jsCode: "*ignored*");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidCastLiteralMap(DartType _type, DartType _type2) {
  NameSystem nameSystem = new NameSystem();
  StringBuffer buffer = new StringBuffer();
  new Printer(buffer, syntheticNames: nameSystem).writeNode(_type);
  String type = '$buffer';

  buffer = new StringBuffer();
  new Printer(buffer, syntheticNames: nameSystem).writeNode(_type2);
  String type2 = '$buffer';

  return new Message(codeInvalidCastLiteralMap,
      message:
          """The map literal type '$type' isn't of expected type '$type2'.""",
      tip:
          """Change the type of the map literal or the context in which it is used.""",
      arguments: {'type': _type, 'type2': _type2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        DartType _type,
        DartType
            _type2)> templateInvalidCastLocalFunction = const Template<
        Message Function(DartType _type, DartType _type2)>(
    messageTemplate:
        r"""The local function has type '#type' that isn't of expected type '#type2'.""",
    tipTemplate:
        r"""Change the type of the function or the context in which it is used.""",
    withArguments: _withArgumentsInvalidCastLocalFunction);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
    codeInvalidCastLocalFunction =
    const Code<Message Function(DartType _type, DartType _type2)>(
        "InvalidCastLocalFunction", templateInvalidCastLocalFunction,
        analyzerCode: "INVALID_CAST_FUNCTION", dart2jsCode: "*ignored*");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidCastLocalFunction(
    DartType _type, DartType _type2) {
  NameSystem nameSystem = new NameSystem();
  StringBuffer buffer = new StringBuffer();
  new Printer(buffer, syntheticNames: nameSystem).writeNode(_type);
  String type = '$buffer';

  buffer = new StringBuffer();
  new Printer(buffer, syntheticNames: nameSystem).writeNode(_type2);
  String type2 = '$buffer';

  return new Message(codeInvalidCastLocalFunction,
      message:
          """The local function has type '$type' that isn't of expected type '$type2'.""",
      tip: """Change the type of the function or the context in which it is used.""",
      arguments: {'type': _type, 'type2': _type2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        DartType _type,
        DartType
            _type2)> templateInvalidCastNewExpr = const Template<
        Message Function(DartType _type, DartType _type2)>(
    messageTemplate:
        r"""The constructor returns type '#type' that isn't of expected type '#type2'.""",
    tipTemplate:
        r"""Change the type of the object being constructed or the context in which it is used.""",
    withArguments: _withArgumentsInvalidCastNewExpr);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
    codeInvalidCastNewExpr =
    const Code<Message Function(DartType _type, DartType _type2)>(
        "InvalidCastNewExpr", templateInvalidCastNewExpr,
        analyzerCode: "INVALID_CAST_NEW_EXPR", dart2jsCode: "*ignored*");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidCastNewExpr(DartType _type, DartType _type2) {
  NameSystem nameSystem = new NameSystem();
  StringBuffer buffer = new StringBuffer();
  new Printer(buffer, syntheticNames: nameSystem).writeNode(_type);
  String type = '$buffer';

  buffer = new StringBuffer();
  new Printer(buffer, syntheticNames: nameSystem).writeNode(_type2);
  String type2 = '$buffer';

  return new Message(codeInvalidCastNewExpr,
      message:
          """The constructor returns type '$type' that isn't of expected type '$type2'.""",
      tip: """Change the type of the object being constructed or the context in which it is used.""",
      arguments: {'type': _type, 'type2': _type2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        DartType _type,
        DartType
            _type2)> templateInvalidCastStaticMethod = const Template<
        Message Function(DartType _type, DartType _type2)>(
    messageTemplate:
        r"""The static method has type '#type' that isn't of expected type '#type2'.""",
    tipTemplate:
        r"""Change the type of the method or the context in which it is used.""",
    withArguments: _withArgumentsInvalidCastStaticMethod);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
    codeInvalidCastStaticMethod =
    const Code<Message Function(DartType _type, DartType _type2)>(
        "InvalidCastStaticMethod", templateInvalidCastStaticMethod,
        analyzerCode: "INVALID_CAST_METHOD", dart2jsCode: "*ignored*");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidCastStaticMethod(DartType _type, DartType _type2) {
  NameSystem nameSystem = new NameSystem();
  StringBuffer buffer = new StringBuffer();
  new Printer(buffer, syntheticNames: nameSystem).writeNode(_type);
  String type = '$buffer';

  buffer = new StringBuffer();
  new Printer(buffer, syntheticNames: nameSystem).writeNode(_type2);
  String type2 = '$buffer';

  return new Message(codeInvalidCastStaticMethod,
      message:
          """The static method has type '$type' that isn't of expected type '$type2'.""",
      tip: """Change the type of the method or the context in which it is used.""",
      arguments: {'type': _type, 'type2': _type2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        DartType _type,
        DartType
            _type2)> templateInvalidCastTopLevelFunction = const Template<
        Message Function(DartType _type, DartType _type2)>(
    messageTemplate:
        r"""The top level function has type '#type' that isn't of expected type '#type2'.""",
    tipTemplate:
        r"""Change the type of the function or the context in which it is used.""",
    withArguments: _withArgumentsInvalidCastTopLevelFunction);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
    codeInvalidCastTopLevelFunction =
    const Code<Message Function(DartType _type, DartType _type2)>(
        "InvalidCastTopLevelFunction", templateInvalidCastTopLevelFunction,
        analyzerCode: "INVALID_CAST_FUNCTION", dart2jsCode: "*ignored*");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidCastTopLevelFunction(
    DartType _type, DartType _type2) {
  NameSystem nameSystem = new NameSystem();
  StringBuffer buffer = new StringBuffer();
  new Printer(buffer, syntheticNames: nameSystem).writeNode(_type);
  String type = '$buffer';

  buffer = new StringBuffer();
  new Printer(buffer, syntheticNames: nameSystem).writeNode(_type2);
  String type2 = '$buffer';

  return new Message(codeInvalidCastTopLevelFunction,
      message:
          """The top level function has type '$type' that isn't of expected type '$type2'.""",
      tip: """Change the type of the function or the context in which it is used.""",
      arguments: {'type': _type, 'type2': _type2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInvalidInitializer = messageInvalidInitializer;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidInitializer = const MessageCode(
    "InvalidInitializer",
    message: r"""Not a valid initializer.""",
    tip: r"""To initialize a field, use the syntax 'name = value'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInvalidInlineFunctionType =
    messageInvalidInlineFunctionType;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidInlineFunctionType = const MessageCode(
    "InvalidInlineFunctionType",
    dart2jsCode: "INVALID_INLINE_FUNCTION_TYPE",
    message: r"""Invalid inline function type.""",
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
        analyzerCode: "INVALID_OPERATOR", dart2jsCode: "*fatal*");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidOperator(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeInvalidOperator,
      message: """The string '$lexeme' isn't a user-definable operator.""",
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
  return new Message(codeInvalidPackageUri,
      message: """Invalid package URI '$uri':
  $string.""", arguments: {'uri': uri_, 'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInvalidSyncModifier = messageInvalidSyncModifier;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidSyncModifier = const MessageCode(
    "InvalidSyncModifier",
    analyzerCode: "MISSING_STAR_AFTER_SYNC",
    dart2jsCode: "INVALID_SYNC_MODIFIER",
    message: r"""Invalid modifier 'sync'.""",
    tip: r"""Try replacing 'sync' with 'sync*'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInvalidVoid = messageInvalidVoid;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidVoid = const MessageCode("InvalidVoid",
    dart2jsCode: "VOID_NOT_ALLOWED",
    message:
        r"""Type 'void' can't be used here because it isn't a return type.""",
    tip:
        r"""Try removing 'void' keyword or replace it with 'var', 'final', or a type.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeLibraryDirectiveNotFirst = messageLibraryDirectiveNotFirst;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageLibraryDirectiveNotFirst = const MessageCode(
    "LibraryDirectiveNotFirst",
    analyzerCode: "LIBRARY_DIRECTIVE_NOT_FIRST",
    dart2jsCode: "*ignored*",
    message:
        r"""The library directive must appear before all other directives.""",
    tip: r"""Try moving the library directive before any other directives.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeListLiteralTooManyTypeArguments =
    messageListLiteralTooManyTypeArguments;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageListLiteralTooManyTypeArguments = const MessageCode(
    "ListLiteralTooManyTypeArguments",
    severity: Severity.errorLegacyWarning,
    message: r"""Too many type arguments on List literal.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeListLiteralTypeArgumentMismatch =
    messageListLiteralTypeArgumentMismatch;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageListLiteralTypeArgumentMismatch = const MessageCode(
    "ListLiteralTypeArgumentMismatch",
    severity: Severity.errorLegacyWarning,
    message: r"""Map literal requires two type arguments.""");

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
        severity: Severity.nit);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsLoadLibraryHidesMember(Uri uri_) {
  String uri = relativizeUri(uri_);
  return new Message(codeLoadLibraryHidesMember,
      message:
          """The library '$uri' defines a top-level member named 'loadLibrary'. This member is hidden by the special member 'loadLibrary' that the language adds to support deferred loading.""",
      tip: """Try to rename or hide the member.""",
      arguments: {'uri': uri_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeLoadLibraryTakesNoArguments =
    messageLoadLibraryTakesNoArguments;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageLoadLibraryTakesNoArguments = const MessageCode(
    "LoadLibraryTakesNoArguments",
    severity: Severity.errorLegacyWarning,
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
        severity: Severity.nit);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsLocalDefinitionHidesExport(String name, Uri uri_) {
  String uri = relativizeUri(uri_);
  return new Message(codeLocalDefinitionHidesExport,
      message: """Local definition of '$name' hides export from '$uri'.""",
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
        severity: Severity.nit);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsLocalDefinitionHidesImport(String name, Uri uri_) {
  String uri = relativizeUri(uri_);
  return new Message(codeLocalDefinitionHidesImport,
      message: """Local definition of '$name' hides import from '$uri'.""",
      arguments: {'name': name, 'uri': uri_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMemberWithSameNameAsClass =
    messageMemberWithSameNameAsClass;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMemberWithSameNameAsClass = const MessageCode(
    "MemberWithSameNameAsClass",
    message:
        r"""A class member can't have the same name as the enclosing class.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMetadataTypeArguments = messageMetadataTypeArguments;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMetadataTypeArguments = const MessageCode(
    "MetadataTypeArguments",
    dart2jsCode: "*ignored*",
    message: r"""An annotation (metadata) can't use type arguments.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(String name)> templateMethodHasNoSuchNamedParameter =
    const Template<Message Function(String name)>(
        messageTemplate:
            r"""Method has no named parameter with the name '#name'.""",
        withArguments: _withArgumentsMethodHasNoSuchNamedParameter);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeMethodHasNoSuchNamedParameter =
    const Code<Message Function(String name)>(
        "MethodHasNoSuchNamedParameter", templateMethodHasNoSuchNamedParameter,
        severity: Severity.errorLegacyWarning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMethodHasNoSuchNamedParameter(String name) {
  return new Message(codeMethodHasNoSuchNamedParameter,
      message: """Method has no named parameter with the name '$name'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateMethodNotFound =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Method not found: '#name'.""",
        withArguments: _withArgumentsMethodNotFound);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeMethodNotFound =
    const Code<Message Function(String name)>(
        "MethodNotFound", templateMethodNotFound,
        severity: Severity.errorLegacyWarning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMethodNotFound(String name) {
  return new Message(codeMethodNotFound,
      message: """Method not found: '$name'.""", arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMissingAssignableSelector =
    messageMissingAssignableSelector;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingAssignableSelector = const MessageCode(
    "MissingAssignableSelector",
    analyzerCode: "MISSING_ASSIGNABLE_SELECTOR",
    dart2jsCode: "*fatal*",
    message: r"""Missing selector such as '.<identifier>' or '[0]'.""",
    tip: r"""Try adding a selector.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMissingAssignmentInInitializer =
    messageMissingAssignmentInInitializer;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingAssignmentInInitializer = const MessageCode(
    "MissingAssignmentInInitializer",
    analyzerCode: "MISSING_ASSIGNMENT_IN_INITIALIZER",
    dart2jsCode: "*fatal*",
    message: r"""Expected an assignment after the field name.""",
    tip: r"""To initialize a field, use the syntax 'name = value'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMissingConstFinalVarOrType =
    messageMissingConstFinalVarOrType;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingConstFinalVarOrType = const MessageCode(
    "MissingConstFinalVarOrType",
    analyzerCode: "MISSING_CONST_FINAL_VAR_OR_TYPE",
    dart2jsCode: "*fatal*",
    message:
        r"""Variables must be declared using the keywords 'const', 'final', 'var' or a type name.""",
    tip:
        r"""Try adding the name of the type of the variable or the keyword 'var'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMissingExponent = messageMissingExponent;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingExponent = const MessageCode("MissingExponent",
    analyzerCode: "MISSING_DIGIT",
    dart2jsCode: "EXPONENT_MISSING",
    message:
        r"""Numbers in exponential notation should always contain an exponent (an integer number with an optional sign).""",
    tip:
        r"""Make sure there is an exponent, and remove any whitespace before it.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMissingFunctionParameters =
    messageMissingFunctionParameters;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingFunctionParameters = const MessageCode(
    "MissingFunctionParameters",
    analyzerCode: "MISSING_FUNCTION_PARAMETERS",
    dart2jsCode: "*fatal*",
    message:
        r"""A function declaration needs an explicit list of parameters.""",
    tip: r"""Try adding a parameter list to the function declaration.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMissingInput = messageMissingInput;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingInput = const MessageCode("MissingInput",
    message: r"""No input file provided to the compiler.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMissingMain = messageMissingMain;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingMain = const MessageCode("MissingMain",
    dart2jsCode: "MISSING_MAIN",
    message: r"""No 'main' method found.""",
    tip: r"""Try adding a method named 'main' to your program.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMissingMethodParameters = messageMissingMethodParameters;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingMethodParameters = const MessageCode(
    "MissingMethodParameters",
    analyzerCode: "MISSING_METHOD_PARAMETERS",
    dart2jsCode: "*fatal*",
    message: r"""A method declaration needs an explicit list of parameters.""",
    tip: r"""Try adding a parameter list to the method declaration.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMissingOperatorKeyword = messageMissingOperatorKeyword;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingOperatorKeyword = const MessageCode(
    "MissingOperatorKeyword",
    analyzerCode: "MISSING_KEYWORD_OPERATOR",
    dart2jsCode: "*fatal*",
    message:
        r"""Operator declarations must be preceeded by the keyword 'operator'.""",
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
  "MissingPartOf",
  templateMissingPartOf,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMissingPartOf(Uri uri_) {
  String uri = relativizeUri(uri_);
  return new Message(codeMissingPartOf,
      message:
          """Can't use '$uri' as a part, because it has no 'part of' declaration.""",
      arguments: {'uri': uri_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMissingPrefixInDeferredImport =
    messageMissingPrefixInDeferredImport;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingPrefixInDeferredImport = const MessageCode(
    "MissingPrefixInDeferredImport",
    analyzerCode: "MISSING_PREFIX_IN_DEFERRED_IMPORT",
    dart2jsCode: "*fatal*",
    message: r"""Deferred imports should have a prefix.""",
    tip: r"""Try adding a prefix to the import.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMissingTypedefParameters = messageMissingTypedefParameters;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingTypedefParameters = const MessageCode(
    "MissingTypedefParameters",
    analyzerCode: "MISSING_TYPEDEF_PARAMETERS",
    dart2jsCode: "*fatal*",
    message: r"""A typedef needs an explicit list of parameters.""",
    tip: r"""Try adding a parameter list to the typedef.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String name,
        String name2,
        DartType
            _type)> templateMixinInferenceNoMatchingClass = const Template<
        Message Function(String name, String name2, DartType _type)>(
    messageTemplate:
        r"""Type parameters could not be inferred for the mixin '#name' because
'#name2' does not implement the mixin's supertype constraint '#type'.""",
    withArguments: _withArgumentsMixinInferenceNoMatchingClass);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String name2, DartType _type)>
    codeMixinInferenceNoMatchingClass =
    const Code<Message Function(String name, String name2, DartType _type)>(
        "MixinInferenceNoMatchingClass", templateMixinInferenceNoMatchingClass,
        severity: Severity.error);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMixinInferenceNoMatchingClass(
    String name, String name2, DartType _type) {
  NameSystem nameSystem = new NameSystem();
  StringBuffer buffer = new StringBuffer();
  new Printer(buffer, syntheticNames: nameSystem).writeNode(_type);
  String type = '$buffer';

  return new Message(codeMixinInferenceNoMatchingClass,
      message:
          """Type parameters could not be inferred for the mixin '$name' because
'$name2' does not implement the mixin's supertype constraint '$type'.""",
      arguments: {'name': name, 'name2': name2, 'type': _type});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMultipleExtends = messageMultipleExtends;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMultipleExtends = const MessageCode("MultipleExtends",
    analyzerCode: "MULTIPLE_EXTENDS_CLAUSES",
    dart2jsCode: "*ignored*",
    message: r"""Each class definition can have at most one extends clause.""",
    tip:
        r"""Try choosing one superclass and define your class to implement (or mix in) the others.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMultipleImplements = messageMultipleImplements;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMultipleImplements = const MessageCode(
    "MultipleImplements",
    analyzerCode: "MULTIPLE_IMPLEMENTS_CLAUSES",
    dart2jsCode: "GENERIC",
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
    analyzerCode: "MULTIPLE_LIBRARY_DIRECTIVES",
    dart2jsCode: "*ignored*",
    message: r"""Only one library directive may be declared in a file.""",
    tip: r"""Try removing all but one of the library directives.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMultipleWith = messageMultipleWith;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMultipleWith = const MessageCode("MultipleWith",
    analyzerCode: "MULTIPLE_WITH_CLAUSES",
    dart2jsCode: "*ignored*",
    message: r"""Each class definition can have at most one with clause.""",
    tip: r"""Try combining all of the with clauses into a single clause.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeNamedFunctionExpression = messageNamedFunctionExpression;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNamedFunctionExpression = const MessageCode(
    "NamedFunctionExpression",
    analyzerCode: "NAMED_FUNCTION_EXPRESSION",
    dart2jsCode: "*ignored*",
    message: r"""A function expression can't have a name.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeNativeClauseShouldBeAnnotation =
    messageNativeClauseShouldBeAnnotation;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNativeClauseShouldBeAnnotation = const MessageCode(
    "NativeClauseShouldBeAnnotation",
    analyzerCode: "NATIVE_CLAUSE_SHOULD_BE_ANNOTATION",
    dart2jsCode: "*fatal*",
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
        analyzerCode: "MISSING_FUNCTION_PARAMETERS", dart2jsCode: "*ignored*");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNoFormals(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeNoFormals,
      message: """A function should have formal parameters.""",
      tip:
          """Try adding '()' after '$lexeme', or add 'get' before '$lexeme' to declare a getter.""",
      arguments: {'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeNoUnnamedConstructorInObject =
    messageNoUnnamedConstructorInObject;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNoUnnamedConstructorInObject = const MessageCode(
    "NoUnnamedConstructorInObject",
    message: r"""'Object' has no unnamed constructor.""");

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
        analyzerCode: "ILLEGAL_CHARACTER", dart2jsCode: "BAD_INPUT_CHARACTER");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonAsciiIdentifier(String character, int codePoint) {
  String unicode =
      "U+${codePoint.toRadixString(16).toUpperCase().padLeft(4, '0')}";
  return new Message(codeNonAsciiIdentifier,
      message:
          """The non-ASCII character '$character' ($unicode) can't be used in identifiers, only in strings and comments.""",
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
        analyzerCode: "ILLEGAL_CHARACTER", dart2jsCode: "BAD_INPUT_CHARACTER");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonAsciiWhitespace(int codePoint) {
  String unicode =
      "U+${codePoint.toRadixString(16).toUpperCase().padLeft(4, '0')}";
  return new Message(codeNonAsciiWhitespace,
      message:
          """The non-ASCII space character $unicode can only be used in strings and comments.""",
      arguments: {'codePoint': codePoint});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeNonInstanceTypeVariableUse =
    messageNonInstanceTypeVariableUse;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNonInstanceTypeVariableUse = const MessageCode(
    "NonInstanceTypeVariableUse",
    severity: Severity.errorLegacyWarning,
    message: r"""Can only use type variables in instance methods.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeNonPartOfDirectiveInPart = messageNonPartOfDirectiveInPart;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNonPartOfDirectiveInPart = const MessageCode(
    "NonPartOfDirectiveInPart",
    analyzerCode: "NON_PART_OF_DIRECTIVE_IN_PART",
    dart2jsCode: "*ignored*",
    message: r"""The part-of directive must be the only directive in a part.""",
    tip:
        r"""Try removing the other directives, or moving them to the library for which this is a part.""");

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
        analyzerCode: "NOT_A_TYPE",
        dart2jsCode: "*ignored*",
        severity: Severity.errorLegacyWarning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNotAPrefixInTypeAnnotation(String name, String name2) {
  return new Message(codeNotAPrefixInTypeAnnotation,
      message:
          """'$name.$name2' can't be used as a type because '$name' doesn't refer to an import prefix.""",
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
        analyzerCode: "NOT_A_TYPE",
        dart2jsCode: "*ignored*",
        severity: Severity.errorLegacyWarning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNotAType(String name) {
  return new Message(codeNotAType,
      message: """'$name' isn't a type.""", arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeNotAnLvalue = messageNotAnLvalue;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNotAnLvalue =
    const MessageCode("NotAnLvalue", message: r"""Can't assign to this.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeOnlyTry = messageOnlyTry;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageOnlyTry = const MessageCode("OnlyTry",
    analyzerCode: "MISSING_CATCH_OR_FINALLY",
    dart2jsCode: "*ignored*",
    message:
        r"""Try block should be followed by 'on', 'catch', or 'finally' block.""",
    tip: r"""Did you forget to add a 'finally' block?""");

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
    const Code<Message Function(String name)>(
  "OperatorMinusParameterMismatch",
  templateOperatorMinusParameterMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOperatorMinusParameterMismatch(String name) {
  return new Message(codeOperatorMinusParameterMismatch,
      message: """Operator '$name' should have zero or one parameter.""",
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
  return new Message(codeOperatorParameterMismatch0,
      message: """Operator '$name' shouldn't have any parameters.""",
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
  "OperatorParameterMismatch1",
  templateOperatorParameterMismatch1,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOperatorParameterMismatch1(String name) {
  return new Message(codeOperatorParameterMismatch1,
      message: """Operator '$name' should have exactly one parameter.""",
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
  "OperatorParameterMismatch2",
  templateOperatorParameterMismatch2,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOperatorParameterMismatch2(String name) {
  return new Message(codeOperatorParameterMismatch2,
      message: """Operator '$name' should have exactly two parameters.""",
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
const Template<Message Function(String name)> templateOverriddenMethodCause =
    const Template<Message Function(String name)>(
        messageTemplate: r"""This is the overriden method ('#name').""",
        withArguments: _withArgumentsOverriddenMethodCause);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeOverriddenMethodCause =
    const Code<Message Function(String name)>(
        "OverriddenMethodCause", templateOverriddenMethodCause,
        severity: Severity.context);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverriddenMethodCause(String name) {
  return new Message(codeOverriddenMethodCause,
      message: """This is the overriden method ('$name').""",
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
        severity: Severity.errorLegacyWarning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideFewerNamedArguments(String name, String name2) {
  return new Message(codeOverrideFewerNamedArguments,
      message:
          """The method '$name' has fewer named arguments than those of overridden method '$name2'.""",
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
        severity: Severity.errorLegacyWarning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideFewerPositionalArguments(
    String name, String name2) {
  return new Message(codeOverrideFewerPositionalArguments,
      message:
          """The method '$name' has fewer positional arguments than those of overridden method '$name2'.""",
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
        r"""The method '#name' doesn't have the named parameter '#name2' of overriden method '#name3'.""",
    withArguments: _withArgumentsOverrideMismatchNamedParameter);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String name2, String name3)>
    codeOverrideMismatchNamedParameter =
    const Code<Message Function(String name, String name2, String name3)>(
        "OverrideMismatchNamedParameter",
        templateOverrideMismatchNamedParameter,
        severity: Severity.errorLegacyWarning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideMismatchNamedParameter(
    String name, String name2, String name3) {
  return new Message(codeOverrideMismatchNamedParameter,
      message:
          """The method '$name' doesn't have the named parameter '$name2' of overriden method '$name3'.""",
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
        severity: Severity.errorLegacyWarning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideMoreRequiredArguments(String name, String name2) {
  return new Message(codeOverrideMoreRequiredArguments,
      message:
          """The method '$name' has more required arguments than those of overridden method '$name2'.""",
      arguments: {'name': name, 'name2': name2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String name,
        String name2,
        DartType _type,
        DartType
            _type2)> templateOverrideTypeMismatchParameter = const Template<
        Message Function(String name, String name2, DartType _type,
            DartType _type2)>(
    messageTemplate:
        r"""The parameter '#name' of the method '#name2' has type #type, which does not match the corresponding type in the overridden method (#type2).""",
    tipTemplate:
        r"""Change to a supertype of #type2 (or, for a covariant parameter, a subtype).""",
    withArguments: _withArgumentsOverrideTypeMismatchParameter);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            String name, String name2, DartType _type, DartType _type2)>
    codeOverrideTypeMismatchParameter = const Code<
            Message Function(
                String name, String name2, DartType _type, DartType _type2)>(
        "OverrideTypeMismatchParameter", templateOverrideTypeMismatchParameter,
        analyzerCode: "INVALID_METHOD_OVERRIDE", dart2jsCode: "*ignored*");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideTypeMismatchParameter(
    String name, String name2, DartType _type, DartType _type2) {
  NameSystem nameSystem = new NameSystem();
  StringBuffer buffer = new StringBuffer();
  new Printer(buffer, syntheticNames: nameSystem).writeNode(_type);
  String type = '$buffer';

  buffer = new StringBuffer();
  new Printer(buffer, syntheticNames: nameSystem).writeNode(_type2);
  String type2 = '$buffer';

  return new Message(codeOverrideTypeMismatchParameter,
      message:
          """The parameter '$name' of the method '$name2' has type $type, which does not match the corresponding type in the overridden method ($type2).""",
      tip: """Change to a supertype of $type2 (or, for a covariant parameter, a subtype).""",
      arguments: {
        'name': name,
        'name2': name2,
        'type': _type,
        'type2': _type2
      });
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String name,
        DartType _type,
        DartType
            _type2)> templateOverrideTypeMismatchReturnType = const Template<
        Message Function(String name, DartType _type, DartType _type2)>(
    messageTemplate:
        r"""The return type of the method '#name' is #type, which does not match the return type of the overridden method (#type2).""",
    tipTemplate: r"""Change to a subtype of #type2.""",
    withArguments: _withArgumentsOverrideTypeMismatchReturnType);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, DartType _type, DartType _type2)>
    codeOverrideTypeMismatchReturnType =
    const Code<Message Function(String name, DartType _type, DartType _type2)>(
        "OverrideTypeMismatchReturnType",
        templateOverrideTypeMismatchReturnType,
        analyzerCode: "INVALID_METHOD_OVERRIDE",
        dart2jsCode: "*ignored*");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideTypeMismatchReturnType(
    String name, DartType _type, DartType _type2) {
  NameSystem nameSystem = new NameSystem();
  StringBuffer buffer = new StringBuffer();
  new Printer(buffer, syntheticNames: nameSystem).writeNode(_type);
  String type = '$buffer';

  buffer = new StringBuffer();
  new Printer(buffer, syntheticNames: nameSystem).writeNode(_type2);
  String type2 = '$buffer';

  return new Message(codeOverrideTypeMismatchReturnType,
      message:
          """The return type of the method '$name' is $type, which does not match the return type of the overridden method ($type2).""",
      tip: """Change to a subtype of $type2.""",
      arguments: {'name': name, 'type': _type, 'type2': _type2});
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
        severity: Severity.errorLegacyWarning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideTypeVariablesMismatch(String name, String name2) {
  return new Message(codeOverrideTypeVariablesMismatch,
      message:
          """Declared type variables of '$name' doesn't match those on overridden method '$name2'.""",
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
  String uri = relativizeUri(uri_);
  return new Message(codePackageNotFound,
      message: """Could not resolve the package '$name' in '$uri'.""",
      arguments: {'name': name, 'uri': uri_});
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
        severity: Severity.errorLegacyWarning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsPartOfLibraryNameMismatch(
    Uri uri_, String name, String name2) {
  String uri = relativizeUri(uri_);
  return new Message(codePartOfLibraryNameMismatch,
      message:
          """Using '$uri' as part of '$name' but its 'part of' declaration says '$name2'.""",
      arguments: {'uri': uri_, 'name': name, 'name2': name2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codePartOfSelf = messagePartOfSelf;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePartOfSelf = const MessageCode("PartOfSelf",
    message: r"""A file can't be a part of itself.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codePartOfTwice = messagePartOfTwice;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePartOfTwice = const MessageCode("PartOfTwice",
    analyzerCode: "MULTIPLE_PART_OF_DIRECTIVES",
    dart2jsCode: "*ignored*",
    message: r"""Only one part-of directive may be declared in a file.""",
    tip: r"""Try removing all but one of the part-of directives.""");

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
        severity: Severity.errorLegacyWarning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsPartOfUriMismatch(Uri uri_, Uri uri2_, Uri uri3_) {
  String uri = relativizeUri(uri_);
  String uri2 = relativizeUri(uri2_);
  String uri3 = relativizeUri(uri3_);
  return new Message(codePartOfUriMismatch,
      message:
          """Using '$uri' as part of '$uri2' but its 'part of' declaration says '$uri3'.""",
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
        severity: Severity.errorLegacyWarning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsPartOfUseUri(Uri uri_, Uri uri2_, String name) {
  String uri = relativizeUri(uri_);
  String uri2 = relativizeUri(uri2_);
  return new Message(codePartOfUseUri,
      message:
          """Using '$uri' as part of '$uri2' but its 'part of' declaration says '$name'.""",
      tip: """Try changing the 'part of' declaration to use a relative file name.""",
      arguments: {'uri': uri_, 'uri2': uri2_, 'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri_)> templatePartTwice =
    const Template<Message Function(Uri uri_)>(
        messageTemplate: r"""Can't use '#uri' as a part more than once.""",
        withArguments: _withArgumentsPartTwice);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Uri uri_)> codePartTwice =
    const Code<Message Function(Uri uri_)>(
  "PartTwice",
  templatePartTwice,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsPartTwice(Uri uri_) {
  String uri = relativizeUri(uri_);
  return new Message(codePartTwice,
      message: """Can't use '$uri' as a part more than once.""",
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
  String uri = relativizeUri(uri_);
  return new Message(codePatchInjectionFailed,
      message: """Can't inject '$name' into '$uri'.""",
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
    message: r"""Can't access platform private library.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codePositionalAfterNamedArgument =
    messagePositionalAfterNamedArgument;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePositionalAfterNamedArgument = const MessageCode(
    "PositionalAfterNamedArgument",
    analyzerCode: "POSITIONAL_AFTER_NAMED_ARGUMENT",
    dart2jsCode: "*ignored*",
    message: r"""Place positional arguments before named arguments.""",
    tip:
        r"""Try moving the positional argument before the named arguments, or add a name to the argument.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codePositionalParameterWithEquals =
    messagePositionalParameterWithEquals;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePositionalParameterWithEquals = const MessageCode(
    "PositionalParameterWithEquals",
    analyzerCode: "WRONG_SEPARATOR_FOR_POSITIONAL_PARAMETER",
    dart2jsCode: "POSITIONAL_PARAMETER_WITH_EQUALS",
    message:
        r"""Positional optional parameters can't use ':' to specify a default value.""",
    tip: r"""Try replacing ':' with '='.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codePrefixAfterCombinator = messagePrefixAfterCombinator;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePrefixAfterCombinator = const MessageCode(
    "PrefixAfterCombinator",
    analyzerCode: "PREFIX_AFTER_COMBINATOR",
    dart2jsCode: "*fatal*",
    message:
        r"""The prefix ('as' clause) should come before any show/hide combinators.""",
    tip: r"""Try moving the prefix before the combinators.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templatePreviousUseOfName =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Previous use of '#name'.""",
        withArguments: _withArgumentsPreviousUseOfName);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codePreviousUseOfName =
    const Code<Message Function(String name)>(
  "PreviousUseOfName",
  templatePreviousUseOfName,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsPreviousUseOfName(String name) {
  return new Message(codePreviousUseOfName,
      message: """Previous use of '$name'.""", arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codePrivateNamedParameter = messagePrivateNamedParameter;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePrivateNamedParameter = const MessageCode(
    "PrivateNamedParameter",
    dart2jsCode: "*ignored*",
    message: r"""An optional named parameter can't start with '_'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeRedirectingConstructorWithBody =
    messageRedirectingConstructorWithBody;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageRedirectingConstructorWithBody = const MessageCode(
    "RedirectingConstructorWithBody",
    analyzerCode: "REDIRECTING_CONSTRUCTOR_WITH_BODY",
    dart2jsCode: "*fatal*",
    message: r"""Redirecting constructors can't have a body.""",
    tip:
        r"""Try removing the body, or not making this a redirecting constructor.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeRedirectionInNonFactory = messageRedirectionInNonFactory;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageRedirectionInNonFactory = const MessageCode(
    "RedirectionInNonFactory",
    analyzerCode: "REDIRECTION_IN_NON_FACTORY_CONSTRUCTOR",
    dart2jsCode: "*fatal*",
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
        severity: Severity.errorLegacyWarning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsRedirectionTargetNotFound(String name) {
  return new Message(codeRedirectionTargetNotFound,
      message: """Redirection constructor target not found: '$name'""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeRequiredParameterWithDefault =
    messageRequiredParameterWithDefault;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageRequiredParameterWithDefault = const MessageCode(
    "RequiredParameterWithDefault",
    analyzerCode: "NAMED_PARAMETER_OUTSIDE_GROUP",
    dart2jsCode: "REQUIRED_PARAMETER_WITH_DEFAULT",
    message: r"""Non-optional parameters can't have a default value.""",
    tip:
        r"""Try removing the default value or making the parameter optional.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeReturnTypeFunctionExpression =
    messageReturnTypeFunctionExpression;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageReturnTypeFunctionExpression = const MessageCode(
    "ReturnTypeFunctionExpression",
    dart2jsCode: "*ignored*",
    severity: Severity.errorLegacyWarning,
    message: r"""A function expression can't have a return type.""");

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
      message: """SDK root directory not found: $uri.""",
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
      message: """SDK libraries specification not found: $uri.""",
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
      message: """SDK summary not found: $uri.""", arguments: {'uri': uri_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateSetterNotFound =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Setter not found: '#name'.""",
        withArguments: _withArgumentsSetterNotFound);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeSetterNotFound =
    const Code<Message Function(String name)>(
        "SetterNotFound", templateSetterNotFound,
        severity: Severity.errorLegacyWarning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSetterNotFound(String name) {
  return new Message(codeSetterNotFound,
      message: """Setter not found: '$name'.""", arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeSetterNotSync = messageSetterNotSync;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSetterNotSync = const MessageCode("SetterNotSync",
    analyzerCode: "INVALID_MODIFIER_ON_SETTER",
    dart2jsCode: "*ignored*",
    message: r"""Setters can't use 'async', 'async*', or 'sync*'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeSetterWithWrongNumberOfFormals =
    messageSetterWithWrongNumberOfFormals;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSetterWithWrongNumberOfFormals = const MessageCode(
    "SetterWithWrongNumberOfFormals",
    analyzerCode: "WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER",
    dart2jsCode: "*ignored*",
    message: r"""A setter should have exactly one formal parameter.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        int count,
        int count2,
        String string,
        String string2,
        String
            string3)> templateSourceBodySummary = const Template<
        Message Function(int count, int count2, String string, String string2,
            String string3)>(
    messageTemplate:
        r"""Built bodies for #count compilation units (#count2 bytes) in #string, that is,
#string2 bytes/ms, and
#string3 ms/compilation unit.""",
    withArguments: _withArgumentsSourceBodySummary);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
    Message Function(int count, int count2, String string, String string2,
        String string3)> codeSourceBodySummary = const Code<
    Message Function(
        int count, int count2, String string, String string2, String string3)>(
  "SourceBodySummary",
  templateSourceBodySummary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSourceBodySummary(
    int count, int count2, String string, String string2, String string3) {
  return new Message(codeSourceBodySummary,
      message:
          """Built bodies for $count compilation units ($count2 bytes) in $string, that is,
$string2 bytes/ms, and
$string3 ms/compilation unit.""",
      arguments: {
        'count': count,
        'count2': count2,
        'string': string,
        'string2': string2,
        'string3': string3
      });
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        int count,
        int count2,
        String string,
        String string2,
        String
            string3)> templateSourceOutlineSummary = const Template<
        Message Function(int count, int count2, String string, String string2,
            String string3)>(
    messageTemplate:
        r"""Built outlines for #count compilation units (#count2 bytes) in #string, that is,
#string2 bytes/ms, and
#string3 ms/compilation unit.""",
    withArguments: _withArgumentsSourceOutlineSummary);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
    Message Function(int count, int count2, String string, String string2,
        String string3)> codeSourceOutlineSummary = const Code<
    Message Function(
        int count, int count2, String string, String string2, String string3)>(
  "SourceOutlineSummary",
  templateSourceOutlineSummary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSourceOutlineSummary(
    int count, int count2, String string, String string2, String string3) {
  return new Message(codeSourceOutlineSummary,
      message:
          """Built outlines for $count compilation units ($count2 bytes) in $string, that is,
$string2 bytes/ms, and
$string3 ms/compilation unit.""",
      arguments: {
        'count': count,
        'count2': count2,
        'string': string,
        'string2': string2,
        'string3': string3
      });
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeStackOverflow = messageStackOverflow;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageStackOverflow = const MessageCode("StackOverflow",
    dart2jsCode: "GENERIC", message: r"""Stack overflow.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeStaticAfterConst = messageStaticAfterConst;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageStaticAfterConst = const MessageCode(
    "StaticAfterConst",
    analyzerCode: "STATIC_AFTER_CONST",
    dart2jsCode: "EXTRANEOUS_MODIFIER",
    message:
        r"""The modifier 'static' should be before the modifier 'const'.""",
    tip: r"""Try re-ordering the modifiers.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeStaticAfterFinal = messageStaticAfterFinal;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageStaticAfterFinal = const MessageCode(
    "StaticAfterFinal",
    analyzerCode: "STATIC_AFTER_FINAL",
    dart2jsCode: "EXTRANEOUS_MODIFIER",
    message:
        r"""The modifier 'static' should be before the modifier 'final'.""",
    tip: r"""Try re-ordering the modifiers.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeStaticAfterVar = messageStaticAfterVar;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageStaticAfterVar = const MessageCode("StaticAfterVar",
    analyzerCode: "STATIC_AFTER_VAR",
    dart2jsCode: "*ignored*",
    message: r"""The modifier 'static' should be before the modifier 'var'.""",
    tip: r"""Try re-ordering the modifiers.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeStaticConstructor = messageStaticConstructor;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageStaticConstructor = const MessageCode(
    "StaticConstructor",
    analyzerCode: "STATIC_CONSTRUCTOR",
    dart2jsCode: "*fatal*",
    message: r"""Constructors can't be static.""",
    tip: r"""Try removing the keyword 'static'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeStaticOperator = messageStaticOperator;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageStaticOperator = const MessageCode("StaticOperator",
    analyzerCode: "STATIC_OPERATOR",
    dart2jsCode: "EXTRANEOUS_MODIFIER",
    message: r"""Operators can't be static.""",
    tip: r"""Try removing the keyword 'static'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeSuperAsExpression = messageSuperAsExpression;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSuperAsExpression = const MessageCode(
    "SuperAsExpression",
    message: r"""Can't use 'super' as an expression.""",
    tip:
        r"""To delegate a constructor to a super constructor, put the super call as an initializer.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeSuperAsIdentifier = messageSuperAsIdentifier;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSuperAsIdentifier = const MessageCode(
    "SuperAsIdentifier",
    message: r"""Expected identifier, but got 'super'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeSuperNullAware = messageSuperNullAware;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSuperNullAware = const MessageCode("SuperNullAware",
    analyzerCode: "INVALID_OPERATOR_FOR_SUPER",
    dart2jsCode: "*ignored*",
    message: r"""'super' can't be null.""",
    tip: r"""Try replacing '?.' with '.'""");

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
        analyzerCode: "NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT",
        dart2jsCode: "*ignored*");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperclassHasNoDefaultConstructor(String name) {
  return new Message(codeSuperclassHasNoDefaultConstructor,
      message:
          """The superclass, '$name', has no unnamed constructor that takes no arguments.""",
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
        severity: Severity.errorLegacyWarning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperclassHasNoGetter(String name) {
  return new Message(codeSuperclassHasNoGetter,
      message: """Superclass has no getter named '$name'.""",
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
        analyzerCode: "UNDEFINED_SUPER_METHOD",
        dart2jsCode: "*ignored*",
        severity: Severity.errorLegacyWarning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperclassHasNoMethod(String name) {
  return new Message(codeSuperclassHasNoMethod,
      message: """Superclass has no method named '$name'.""",
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
        severity: Severity.errorLegacyWarning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperclassHasNoSetter(String name) {
  return new Message(codeSuperclassHasNoSetter,
      message: """Superclass has no setter named '$name'.""",
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
        severity: Severity.errorLegacyWarning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperclassMethodArgumentMismatch(String name) {
  return new Message(codeSuperclassMethodArgumentMismatch,
      message:
          """Superclass doesn't have a method named '$name' with matching arguments.""",
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
  "SupertypeIsIllegal",
  templateSupertypeIsIllegal,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSupertypeIsIllegal(String name) {
  return new Message(codeSupertypeIsIllegal,
      message: """The type '$name' can't be used as supertype.""",
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
  "SupertypeIsTypeVariable",
  templateSupertypeIsTypeVariable,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSupertypeIsTypeVariable(String name) {
  return new Message(codeSupertypeIsTypeVariable,
      message: """The type variable '$name' can't be used as supertype.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeSwitchCaseFallThrough = messageSwitchCaseFallThrough;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSwitchCaseFallThrough = const MessageCode(
    "SwitchCaseFallThrough",
    severity: Severity.errorLegacyWarning,
    message: r"""Switch case may fall through to the next case.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeSwitchHasCaseAfterDefault =
    messageSwitchHasCaseAfterDefault;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSwitchHasCaseAfterDefault = const MessageCode(
    "SwitchHasCaseAfterDefault",
    analyzerCode: "SWITCH_HAS_CASE_AFTER_DEFAULT_CASE",
    dart2jsCode: "*fatal*",
    message:
        r"""The default case should be the last case in a switch statement.""",
    tip: r"""Try moving the default case after the other case clauses.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeSwitchHasMultipleDefaults =
    messageSwitchHasMultipleDefaults;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSwitchHasMultipleDefaults = const MessageCode(
    "SwitchHasMultipleDefaults",
    analyzerCode: "SWITCH_HAS_MULTIPLE_DEFAULT_CASES",
    dart2jsCode: "*fatal*",
    message: r"""The 'default' case can only be declared once.""",
    tip: r"""Try removing all but one default case.""");

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
  "ThisAccessInFieldInitializer",
  templateThisAccessInFieldInitializer,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsThisAccessInFieldInitializer(String name) {
  return new Message(codeThisAccessInFieldInitializer,
      message:
          """Can't access 'this' in a field initializer to read '$name'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeThisAsIdentifier = messageThisAsIdentifier;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageThisAsIdentifier = const MessageCode(
    "ThisAsIdentifier",
    message: r"""Expected identifier, but got 'this'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        int count,
        int
            count2)> templateTooFewArgumentsToConstructor = const Template<
        Message Function(int count, int count2)>(
    messageTemplate:
        r"""Too few positional arguments to constructor: #count required, #count2 given.""",
    withArguments: _withArgumentsTooFewArgumentsToConstructor);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(int count, int count2)>
    codeTooFewArgumentsToConstructor =
    const Code<Message Function(int count, int count2)>(
        "TooFewArgumentsToConstructor", templateTooFewArgumentsToConstructor,
        severity: Severity.errorLegacyWarning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsTooFewArgumentsToConstructor(int count, int count2) {
  return new Message(codeTooFewArgumentsToConstructor,
      message:
          """Too few positional arguments to constructor: $count required, $count2 given.""",
      arguments: {'count': count, 'count2': count2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        int count,
        int
            count2)> templateTooFewArgumentsToFunction = const Template<
        Message Function(int count, int count2)>(
    messageTemplate:
        r"""Too few positional arguments to function: #count required, #count2 given.""",
    withArguments: _withArgumentsTooFewArgumentsToFunction);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(int count, int count2)>
    codeTooFewArgumentsToFunction =
    const Code<Message Function(int count, int count2)>(
        "TooFewArgumentsToFunction", templateTooFewArgumentsToFunction,
        severity: Severity.errorLegacyWarning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsTooFewArgumentsToFunction(int count, int count2) {
  return new Message(codeTooFewArgumentsToFunction,
      message:
          """Too few positional arguments to function: $count required, $count2 given.""",
      arguments: {'count': count, 'count2': count2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        int count,
        int
            count2)> templateTooFewArgumentsToMethod = const Template<
        Message Function(int count, int count2)>(
    messageTemplate:
        r"""Too few positional arguments to method: #count required, #count2 given.""",
    withArguments: _withArgumentsTooFewArgumentsToMethod);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(int count, int count2)>
    codeTooFewArgumentsToMethod =
    const Code<Message Function(int count, int count2)>(
        "TooFewArgumentsToMethod", templateTooFewArgumentsToMethod,
        severity: Severity.errorLegacyWarning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsTooFewArgumentsToMethod(int count, int count2) {
  return new Message(codeTooFewArgumentsToMethod,
      message:
          """Too few positional arguments to method: $count required, $count2 given.""",
      arguments: {'count': count, 'count2': count2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        int count,
        int
            count2)> templateTooManyArgumentsToConstructor = const Template<
        Message Function(int count, int count2)>(
    messageTemplate:
        r"""Too many positional arguments to constructor: #count allowed, #count2 given.""",
    withArguments: _withArgumentsTooManyArgumentsToConstructor);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(int count, int count2)>
    codeTooManyArgumentsToConstructor =
    const Code<Message Function(int count, int count2)>(
        "TooManyArgumentsToConstructor", templateTooManyArgumentsToConstructor,
        severity: Severity.errorLegacyWarning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsTooManyArgumentsToConstructor(int count, int count2) {
  return new Message(codeTooManyArgumentsToConstructor,
      message:
          """Too many positional arguments to constructor: $count allowed, $count2 given.""",
      arguments: {'count': count, 'count2': count2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        int count,
        int
            count2)> templateTooManyArgumentsToFunction = const Template<
        Message Function(int count, int count2)>(
    messageTemplate:
        r"""Too many positional arguments to function: #count allowed, #count2 given.""",
    withArguments: _withArgumentsTooManyArgumentsToFunction);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(int count, int count2)>
    codeTooManyArgumentsToFunction =
    const Code<Message Function(int count, int count2)>(
        "TooManyArgumentsToFunction", templateTooManyArgumentsToFunction,
        severity: Severity.errorLegacyWarning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsTooManyArgumentsToFunction(int count, int count2) {
  return new Message(codeTooManyArgumentsToFunction,
      message:
          """Too many positional arguments to function: $count allowed, $count2 given.""",
      arguments: {'count': count, 'count2': count2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        int count,
        int
            count2)> templateTooManyArgumentsToMethod = const Template<
        Message Function(int count, int count2)>(
    messageTemplate:
        r"""Too many positional arguments to method: #count allowed, #count2 given.""",
    withArguments: _withArgumentsTooManyArgumentsToMethod);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(int count, int count2)>
    codeTooManyArgumentsToMethod =
    const Code<Message Function(int count, int count2)>(
        "TooManyArgumentsToMethod", templateTooManyArgumentsToMethod,
        severity: Severity.errorLegacyWarning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsTooManyArgumentsToMethod(int count, int count2) {
  return new Message(codeTooManyArgumentsToMethod,
      message:
          """Too many positional arguments to method: $count allowed, $count2 given.""",
      arguments: {'count': count, 'count2': count2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeTopLevelOperator = messageTopLevelOperator;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTopLevelOperator = const MessageCode(
    "TopLevelOperator",
    analyzerCode: "TOP_LEVEL_OPERATOR",
    dart2jsCode: "*fatal*",
    message: r"""Operators must be declared within a class.""",
    tip:
        r"""Try removing the operator, moving it to a class, or converting it to be a function.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeTypeAfterVar = messageTypeAfterVar;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTypeAfterVar = const MessageCode("TypeAfterVar",
    analyzerCode: "VAR_AND_TYPE",
    dart2jsCode: "EXTRANEOUS_MODIFIER",
    message: r"""Can't have both a type and 'var'.""",
    tip: r"""Try removing 'var.'""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String string)>
    templateTypeArgumentMismatch =
    const Template<Message Function(String name, String string)>(
        messageTemplate: r"""'#name' expects #string type arguments.""",
        withArguments: _withArgumentsTypeArgumentMismatch);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String string)>
    codeTypeArgumentMismatch =
    const Code<Message Function(String name, String string)>(
        "TypeArgumentMismatch", templateTypeArgumentMismatch,
        severity: Severity.errorLegacyWarning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsTypeArgumentMismatch(String name, String string) {
  return new Message(codeTypeArgumentMismatch,
      message: """'$name' expects $string type arguments.""",
      arguments: {'name': name, 'string': string});
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
        analyzerCode: "TYPE_ARGUMENTS_ON_TYPE_VARIABLE",
        dart2jsCode: "*fatal*",
        severity: Severity.errorLegacyWarning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsTypeArgumentsOnTypeVariable(String name) {
  return new Message(codeTypeArgumentsOnTypeVariable,
      message: """Can't use type arguments with type variable '$name'.""",
      tip: """Try removing the type arguments.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateTypeNotFound =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Type '#name' not found.""",
        withArguments: _withArgumentsTypeNotFound);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeTypeNotFound =
    const Code<Message Function(String name)>(
        "TypeNotFound", templateTypeNotFound,
        severity: Severity.errorLegacyWarning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsTypeNotFound(String name) {
  return new Message(codeTypeNotFound,
      message: """Type '$name' not found.""", arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeTypeVariableDuplicatedName =
    messageTypeVariableDuplicatedName;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTypeVariableDuplicatedName = const MessageCode(
    "TypeVariableDuplicatedName",
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
  return new Message(codeTypeVariableDuplicatedNameCause,
      message: """The other type variable named '$name'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeTypeVariableInStaticContext =
    messageTypeVariableInStaticContext;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTypeVariableInStaticContext = const MessageCode(
    "TypeVariableInStaticContext",
    severity: Severity.errorLegacyWarning,
    message: r"""Type variables can't be used in static members.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeTypeVariableSameNameAsEnclosing =
    messageTypeVariableSameNameAsEnclosing;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTypeVariableSameNameAsEnclosing = const MessageCode(
    "TypeVariableSameNameAsEnclosing",
    message:
        r"""A type variable can't have the same name as its enclosing declaration.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeTypedefInClass = messageTypedefInClass;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTypedefInClass = const MessageCode("TypedefInClass",
    analyzerCode: "TYPEDEF_IN_CLASS",
    dart2jsCode: "*fatal*",
    message: r"""Typedefs can't be declared inside classes.""",
    tip: r"""Try moving the typedef to the top-level.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeTypedefNotFunction = messageTypedefNotFunction;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTypedefNotFunction = const MessageCode(
    "TypedefNotFunction",
    message: r"""Can't create typedef from non-function type.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String name,
        DartType
            _type)> templateUndefinedGetter = const Template<
        Message Function(String name, DartType _type)>(
    messageTemplate:
        r"""The getter '#name' isn't defined for the class '#type'.""",
    tipTemplate:
        r"""Try correcting the name to the name of an existing getter, or defining a getter or field named '#name'.""",
    withArguments: _withArgumentsUndefinedGetter);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, DartType _type)> codeUndefinedGetter =
    const Code<Message Function(String name, DartType _type)>(
        "UndefinedGetter", templateUndefinedGetter,
        analyzerCode: "UNDEFINED_GETTER", dart2jsCode: "*ignored*");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUndefinedGetter(String name, DartType _type) {
  NameSystem nameSystem = new NameSystem();
  StringBuffer buffer = new StringBuffer();
  new Printer(buffer, syntheticNames: nameSystem).writeNode(_type);
  String type = '$buffer';

  return new Message(codeUndefinedGetter,
      message: """The getter '$name' isn't defined for the class '$type'.""",
      tip:
          """Try correcting the name to the name of an existing getter, or defining a getter or field named '$name'.""",
      arguments: {'name': name, 'type': _type});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String name,
        DartType
            _type)> templateUndefinedMethod = const Template<
        Message Function(String name, DartType _type)>(
    messageTemplate:
        r"""The method '#name' isn't defined for the class '#type'.""",
    tipTemplate:
        r"""Try correcting the name to the name of an existing method, or defining a method named '#name'.""",
    withArguments: _withArgumentsUndefinedMethod);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, DartType _type)> codeUndefinedMethod =
    const Code<Message Function(String name, DartType _type)>(
        "UndefinedMethod", templateUndefinedMethod,
        analyzerCode: "UNDEFINED_METHOD", dart2jsCode: "*ignored*");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUndefinedMethod(String name, DartType _type) {
  NameSystem nameSystem = new NameSystem();
  StringBuffer buffer = new StringBuffer();
  new Printer(buffer, syntheticNames: nameSystem).writeNode(_type);
  String type = '$buffer';

  return new Message(codeUndefinedMethod,
      message: """The method '$name' isn't defined for the class '$type'.""",
      tip:
          """Try correcting the name to the name of an existing method, or defining a method named '$name'.""",
      arguments: {'name': name, 'type': _type});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String name,
        DartType
            _type)> templateUndefinedSetter = const Template<
        Message Function(String name, DartType _type)>(
    messageTemplate:
        r"""The setter '#name' isn't defined for the class '#type'.""",
    tipTemplate:
        r"""Try correcting the name to the name of an existing setter, or defining a setter or field named '#name'.""",
    withArguments: _withArgumentsUndefinedSetter);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, DartType _type)> codeUndefinedSetter =
    const Code<Message Function(String name, DartType _type)>(
        "UndefinedSetter", templateUndefinedSetter,
        analyzerCode: "UNDEFINED_SETTER", dart2jsCode: "*ignored*");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUndefinedSetter(String name, DartType _type) {
  NameSystem nameSystem = new NameSystem();
  StringBuffer buffer = new StringBuffer();
  new Printer(buffer, syntheticNames: nameSystem).writeNode(_type);
  String type = '$buffer';

  return new Message(codeUndefinedSetter,
      message: """The setter '$name' isn't defined for the class '$type'.""",
      tip:
          """Try correcting the name to the name of an existing setter, or defining a setter or field named '$name'.""",
      arguments: {'name': name, 'type': _type});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeUnexpectedDollarInString = messageUnexpectedDollarInString;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageUnexpectedDollarInString = const MessageCode(
    "UnexpectedDollarInString",
    dart2jsCode: "MALFORMED_STRING_LITERAL",
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
        analyzerCode: "UNEXPECTED_TOKEN", dart2jsCode: "*fatal*");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnexpectedToken(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeUnexpectedToken,
      message: """Unexpected token '$lexeme'.""", arguments: {'token': token});
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
        dart2jsCode: "UNMATCHED_TOKEN");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnmatchedToken(String string, Token token) {
  String lexeme = token.lexeme;
  return new Message(codeUnmatchedToken,
      message: """Can't find '$string' to match '$lexeme'.""",
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
        analyzerCode: "NOT_A_TYPE",
        dart2jsCode: "*ignored*",
        severity: Severity.errorLegacyWarning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnresolvedPrefixInTypeAnnotation(
    String name, String name2) {
  return new Message(codeUnresolvedPrefixInTypeAnnotation,
      message:
          """'$name.$name2' can't be used as a type because '$name' isn't defined.""",
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
        "Unspecified", templateUnspecified,
        dart2jsCode: "GENERIC");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnspecified(String string) {
  return new Message(codeUnspecified,
      message: """$string""", arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeUnsupportedPrefixPlus = messageUnsupportedPrefixPlus;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageUnsupportedPrefixPlus = const MessageCode(
    "UnsupportedPrefixPlus",
    analyzerCode: "MISSING_IDENTIFIER",
    dart2jsCode: "UNSUPPORTED_PREFIX_PLUS",
    message: r"""'+' is not a prefix operator.""",
    tip: r"""Try removing '+'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeUnterminatedComment = messageUnterminatedComment;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageUnterminatedComment = const MessageCode(
    "UnterminatedComment",
    analyzerCode: "UNTERMINATED_MULTI_LINE_COMMENT",
    dart2jsCode: "UNTERMINATED_COMMENT",
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
        analyzerCode: "UNTERMINATED_STRING_LITERAL",
        dart2jsCode: "UNTERMINATED_STRING");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnterminatedString(String string, String string2) {
  return new Message(codeUnterminatedString,
      message: """String starting with $string must end with $string2.""",
      arguments: {'string': string, 'string2': string2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeUnterminatedToken = messageUnterminatedToken;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageUnterminatedToken = const MessageCode(
    "UnterminatedToken",
    dart2jsCode: "UNTERMINATED_TOKEN",
    message: r"""Incomplete token.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeVarReturnType = messageVarReturnType;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageVarReturnType = const MessageCode("VarReturnType",
    analyzerCode: "VAR_RETURN_TYPE",
    dart2jsCode: "EXTRANEOUS_MODIFIER",
    message: r"""The return type can't be 'var'.""",
    tip:
        r"""Try removing the keyword 'var', or replacing it with the name of the return type.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeWithBeforeExtends = messageWithBeforeExtends;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageWithBeforeExtends = const MessageCode(
    "WithBeforeExtends",
    analyzerCode: "WITH_BEFORE_EXTENDS",
    dart2jsCode: "*ignored*",
    message: r"""The extends clause must be before the with clause.""",
    tip: r"""Try moving the extends clause before the with clause.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeWithWithoutExtends = messageWithWithoutExtends;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageWithWithoutExtends = const MessageCode(
    "WithWithoutExtends",
    analyzerCode: "WITH_WITHOUT_EXTENDS",
    dart2jsCode: "GENERIC",
    message: r"""The with clause can't be used without an extends clause.""",
    tip: r"""Try adding an extends clause such as 'extends Object'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeYieldAsIdentifier = messageYieldAsIdentifier;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageYieldAsIdentifier = const MessageCode(
    "YieldAsIdentifier",
    analyzerCode: "ASYNC_KEYWORD_USED_AS_IDENTIFIER",
    dart2jsCode: "*fatal*",
    message:
        r"""'yield' can't be used as an identifier in 'async', 'async*', or 'sync*' methods.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeYieldNotGenerator = messageYieldNotGenerator;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageYieldNotGenerator = const MessageCode(
    "YieldNotGenerator",
    analyzerCode: "YIELD_IN_NON_GENERATOR",
    dart2jsCode: "*ignored*",
    message: r"""'yield' can only be used in 'sync*' or 'async*' methods.""");
