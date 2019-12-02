// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// NOTE: THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/front_end/messages.yaml' and run
// 'pkg/front_end/tool/fasta generate-messages' to update.

// ignore_for_file: lines_longer_than_80_chars

part of fasta.codes;

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
        analyzerCodes: <String>["AMBIGUOUS_SUPERTYPES"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsAmbiguousSupertypes(
    String name, DartType _type, DartType _type2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeAmbiguousSupertypes,
      message: """'${name}' can't implement both '${type}' and '${type2}'""" +
          labeler.originMessages,
      arguments: {'name': name, 'type': _type, 'type2': _type2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        DartType _type,
        DartType
            _type2)> templateArgumentTypeNotAssignable = const Template<
        Message Function(DartType _type, DartType _type2)>(
    messageTemplate:
        r"""The argument type '#type' can't be assigned to the parameter type '#type2'.""",
    withArguments: _withArgumentsArgumentTypeNotAssignable);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
    codeArgumentTypeNotAssignable =
    const Code<Message Function(DartType _type, DartType _type2)>(
        "ArgumentTypeNotAssignable", templateArgumentTypeNotAssignable,
        analyzerCodes: <String>["ARGUMENT_TYPE_NOT_ASSIGNABLE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsArgumentTypeNotAssignable(
    DartType _type, DartType _type2) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeArgumentTypeNotAssignable,
      message:
          """The argument type '${type}' can't be assigned to the parameter type '${type2}'.""" +
              labeler.originMessages,
      arguments: {'type': _type, 'type2': _type2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        Constant
            _constant)> templateConstEvalDuplicateElement = const Template<
        Message Function(Constant _constant)>(
    messageTemplate:
        r"""The element '#constant' conflicts with another existing element in the set.""",
    withArguments: _withArgumentsConstEvalDuplicateElement);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Constant _constant)> codeConstEvalDuplicateElement =
    const Code<Message Function(Constant _constant)>(
        "ConstEvalDuplicateElement", templateConstEvalDuplicateElement,
        analyzerCodes: <String>["EQUAL_ELEMENTS_IN_CONST_SET"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalDuplicateElement(Constant _constant) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> constantParts = labeler.labelConstant(_constant);
  String constant = constantParts.join();
  return new Message(codeConstEvalDuplicateElement,
      message:
          """The element '${constant}' conflicts with another existing element in the set.""" +
              labeler.originMessages,
      arguments: {'constant': _constant});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        Constant
            _constant)> templateConstEvalDuplicateKey = const Template<
        Message Function(Constant _constant)>(
    messageTemplate:
        r"""The key '#constant' conflicts with another existing key in the map.""",
    withArguments: _withArgumentsConstEvalDuplicateKey);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Constant _constant)> codeConstEvalDuplicateKey =
    const Code<Message Function(Constant _constant)>(
        "ConstEvalDuplicateKey", templateConstEvalDuplicateKey,
        analyzerCodes: <String>["EQUAL_KEYS_IN_CONST_MAP"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalDuplicateKey(Constant _constant) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> constantParts = labeler.labelConstant(_constant);
  String constant = constantParts.join();
  return new Message(codeConstEvalDuplicateKey,
      message:
          """The key '${constant}' conflicts with another existing key in the map.""" +
              labeler.originMessages,
      arguments: {'constant': _constant});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        Constant
            _constant)> templateConstEvalElementImplementsEqual = const Template<
        Message Function(Constant _constant)>(
    messageTemplate:
        r"""The element '#constant' does not have a primitive operator '=='.""",
    withArguments: _withArgumentsConstEvalElementImplementsEqual);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Constant _constant)>
    codeConstEvalElementImplementsEqual =
    const Code<Message Function(Constant _constant)>(
        "ConstEvalElementImplementsEqual",
        templateConstEvalElementImplementsEqual,
        analyzerCodes: <String>["CONST_SET_ELEMENT_TYPE_IMPLEMENTS_EQUALS"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalElementImplementsEqual(Constant _constant) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> constantParts = labeler.labelConstant(_constant);
  String constant = constantParts.join();
  return new Message(codeConstEvalElementImplementsEqual,
      message:
          """The element '${constant}' does not have a primitive operator '=='.""" +
              labeler.originMessages,
      arguments: {'constant': _constant});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        DartType
            _type)> templateConstEvalFreeTypeParameter = const Template<
        Message Function(DartType _type)>(
    messageTemplate:
        r"""The type '#type' is not a constant because it depends on a type parameter, only instantiated types are allowed.""",
    withArguments: _withArgumentsConstEvalFreeTypeParameter);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type)> codeConstEvalFreeTypeParameter =
    const Code<Message Function(DartType _type)>(
  "ConstEvalFreeTypeParameter",
  templateConstEvalFreeTypeParameter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalFreeTypeParameter(DartType _type) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(codeConstEvalFreeTypeParameter,
      message:
          """The type '${type}' is not a constant because it depends on a type parameter, only instantiated types are allowed.""" +
              labeler.originMessages,
      arguments: {'type': _type});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String string,
        Constant _constant,
        DartType _type,
        DartType
            _type2)> templateConstEvalInvalidBinaryOperandType = const Template<
        Message Function(String string, Constant _constant, DartType _type,
            DartType _type2)>(
    messageTemplate:
        r"""Binary operator '#string' on '#constant' requires operand of type '#type', but was of type '#type2'.""",
    withArguments: _withArgumentsConstEvalInvalidBinaryOperandType);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
    Message Function(String string, Constant _constant, DartType _type,
        DartType _type2)> codeConstEvalInvalidBinaryOperandType = const Code<
    Message Function(
        String string, Constant _constant, DartType _type, DartType _type2)>(
  "ConstEvalInvalidBinaryOperandType",
  templateConstEvalInvalidBinaryOperandType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalInvalidBinaryOperandType(
    String string, Constant _constant, DartType _type, DartType _type2) {
  if (string.isEmpty) throw 'No string provided';
  TypeLabeler labeler = new TypeLabeler();
  List<Object> constantParts = labeler.labelConstant(_constant);
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String constant = constantParts.join();
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeConstEvalInvalidBinaryOperandType,
      message:
          """Binary operator '${string}' on '${constant}' requires operand of type '${type}', but was of type '${type2}'.""" +
              labeler.originMessages,
      arguments: {
        'string': string,
        'constant': _constant,
        'type': _type,
        'type2': _type2
      });
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        Constant _constant,
        DartType
            _type)> templateConstEvalInvalidEqualsOperandType = const Template<
        Message Function(Constant _constant, DartType _type)>(
    messageTemplate:
        r"""Binary operator '==' requires receiver constant '#constant' of type 'Null', 'bool', 'int', 'double', or 'String', but was of type '#type'.""",
    withArguments: _withArgumentsConstEvalInvalidEqualsOperandType);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Constant _constant, DartType _type)>
    codeConstEvalInvalidEqualsOperandType =
    const Code<Message Function(Constant _constant, DartType _type)>(
  "ConstEvalInvalidEqualsOperandType",
  templateConstEvalInvalidEqualsOperandType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalInvalidEqualsOperandType(
    Constant _constant, DartType _type) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> constantParts = labeler.labelConstant(_constant);
  List<Object> typeParts = labeler.labelType(_type);
  String constant = constantParts.join();
  String type = typeParts.join();
  return new Message(codeConstEvalInvalidEqualsOperandType,
      message:
          """Binary operator '==' requires receiver constant '${constant}' of type 'Null', 'bool', 'int', 'double', or 'String', but was of type '${type}'.""" +
              labeler.originMessages,
      arguments: {'constant': _constant, 'type': _type});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String string,
        Constant
            _constant)> templateConstEvalInvalidMethodInvocation = const Template<
        Message Function(String string, Constant _constant)>(
    messageTemplate:
        r"""The method '#string' can't be invoked on '#constant' in a constant expression.""",
    withArguments: _withArgumentsConstEvalInvalidMethodInvocation);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string, Constant _constant)>
    codeConstEvalInvalidMethodInvocation =
    const Code<Message Function(String string, Constant _constant)>(
        "ConstEvalInvalidMethodInvocation",
        templateConstEvalInvalidMethodInvocation,
        analyzerCodes: <String>["UNDEFINED_OPERATOR"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalInvalidMethodInvocation(
    String string, Constant _constant) {
  if (string.isEmpty) throw 'No string provided';
  TypeLabeler labeler = new TypeLabeler();
  List<Object> constantParts = labeler.labelConstant(_constant);
  String constant = constantParts.join();
  return new Message(codeConstEvalInvalidMethodInvocation,
      message:
          """The method '${string}' can't be invoked on '${constant}' in a constant expression.""" +
              labeler.originMessages,
      arguments: {'string': string, 'constant': _constant});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String string,
        Constant
            _constant)> templateConstEvalInvalidPropertyGet = const Template<
        Message Function(String string, Constant _constant)>(
    messageTemplate:
        r"""The property '#string' can't be accessed on '#constant' in a constant expression.""",
    withArguments: _withArgumentsConstEvalInvalidPropertyGet);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string, Constant _constant)>
    codeConstEvalInvalidPropertyGet =
    const Code<Message Function(String string, Constant _constant)>(
        "ConstEvalInvalidPropertyGet", templateConstEvalInvalidPropertyGet,
        analyzerCodes: <String>["CONST_EVAL_THROWS_EXCEPTION"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalInvalidPropertyGet(
    String string, Constant _constant) {
  if (string.isEmpty) throw 'No string provided';
  TypeLabeler labeler = new TypeLabeler();
  List<Object> constantParts = labeler.labelConstant(_constant);
  String constant = constantParts.join();
  return new Message(codeConstEvalInvalidPropertyGet,
      message:
          """The property '${string}' can't be accessed on '${constant}' in a constant expression.""" +
              labeler.originMessages,
      arguments: {'string': string, 'constant': _constant});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Constant _constant)>
    templateConstEvalInvalidStringInterpolationOperand =
    const Template<Message Function(Constant _constant)>(
        messageTemplate:
            r"""The constant value '#constant' can't be used as part of a string interpolation in a constant expression.
Only values of type 'null', 'bool', 'int', 'double', or 'String' can be used.""",
        withArguments:
            _withArgumentsConstEvalInvalidStringInterpolationOperand);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Constant _constant)>
    codeConstEvalInvalidStringInterpolationOperand =
    const Code<Message Function(Constant _constant)>(
        "ConstEvalInvalidStringInterpolationOperand",
        templateConstEvalInvalidStringInterpolationOperand,
        analyzerCodes: <String>["CONST_EVAL_TYPE_BOOL_NUM_STRING"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalInvalidStringInterpolationOperand(
    Constant _constant) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> constantParts = labeler.labelConstant(_constant);
  String constant = constantParts.join();
  return new Message(codeConstEvalInvalidStringInterpolationOperand,
      message:
          """The constant value '${constant}' can't be used as part of a string interpolation in a constant expression.
Only values of type 'null', 'bool', 'int', 'double', or 'String' can be used.""" +
              labeler.originMessages,
      arguments: {'constant': _constant});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        Constant
            _constant)> templateConstEvalInvalidSymbolName = const Template<
        Message Function(Constant _constant)>(
    messageTemplate:
        r"""The symbol name must be a valid public Dart member name, public constructor name, or library name, optionally qualified, but was '#constant'.""",
    withArguments: _withArgumentsConstEvalInvalidSymbolName);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Constant _constant)>
    codeConstEvalInvalidSymbolName =
    const Code<Message Function(Constant _constant)>(
        "ConstEvalInvalidSymbolName", templateConstEvalInvalidSymbolName,
        analyzerCodes: <String>["CONST_EVAL_THROWS_EXCEPTION"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalInvalidSymbolName(Constant _constant) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> constantParts = labeler.labelConstant(_constant);
  String constant = constantParts.join();
  return new Message(codeConstEvalInvalidSymbolName,
      message:
          """The symbol name must be a valid public Dart member name, public constructor name, or library name, optionally qualified, but was '${constant}'.""" +
              labeler.originMessages,
      arguments: {'constant': _constant});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        Constant _constant,
        DartType _type,
        DartType
            _type2)> templateConstEvalInvalidType = const Template<
        Message Function(Constant _constant, DartType _type, DartType _type2)>(
    messageTemplate:
        r"""Expected constant '#constant' to be of type '#type', but was of type '#type2'.""",
    withArguments: _withArgumentsConstEvalInvalidType);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(Constant _constant, DartType _type, DartType _type2)>
    codeConstEvalInvalidType = const Code<
        Message Function(Constant _constant, DartType _type, DartType _type2)>(
  "ConstEvalInvalidType",
  templateConstEvalInvalidType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalInvalidType(
    Constant _constant, DartType _type, DartType _type2) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> constantParts = labeler.labelConstant(_constant);
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String constant = constantParts.join();
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeConstEvalInvalidType,
      message:
          """Expected constant '${constant}' to be of type '${type}', but was of type '${type2}'.""" +
              labeler.originMessages,
      arguments: {'constant': _constant, 'type': _type, 'type2': _type2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Constant _constant)>
    templateConstEvalKeyImplementsEqual =
    const Template<Message Function(Constant _constant)>(
        messageTemplate:
            r"""The key '#constant' does not have a primitive operator '=='.""",
        withArguments: _withArgumentsConstEvalKeyImplementsEqual);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Constant _constant)>
    codeConstEvalKeyImplementsEqual =
    const Code<Message Function(Constant _constant)>(
        "ConstEvalKeyImplementsEqual", templateConstEvalKeyImplementsEqual,
        analyzerCodes: <String>[
      "CONST_MAP_KEY_EXPRESSION_TYPE_IMPLEMENTS_EQUALS"
    ]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalKeyImplementsEqual(Constant _constant) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> constantParts = labeler.labelConstant(_constant);
  String constant = constantParts.join();
  return new Message(codeConstEvalKeyImplementsEqual,
      message:
          """The key '${constant}' does not have a primitive operator '=='.""" +
              labeler.originMessages,
      arguments: {'constant': _constant});
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
        analyzerCodes: <String>["TYPE_ANNOTATION_DEFERRED_CLASS"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDeferredTypeAnnotation(DartType _type, String name) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  String type = typeParts.join();
  return new Message(codeDeferredTypeAnnotation,
      message:
          """The type '${type}' is deferred loaded via prefix '${name}' and can't be used as a type annotation.""" +
              labeler.originMessages,
      tip: """Try removing 'deferred' from the import of '${name}' or use a supertype of '${type}' that isn't deferred.""",
      arguments: {'type': _type, 'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, DartType _type2)>
    templateFfiDartTypeMismatch =
    const Template<Message Function(DartType _type, DartType _type2)>(
        messageTemplate: r"""Expected '#type' to be a subtype of '#type2'.""",
        withArguments: _withArgumentsFfiDartTypeMismatch);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
    codeFfiDartTypeMismatch =
    const Code<Message Function(DartType _type, DartType _type2)>(
  "FfiDartTypeMismatch",
  templateFfiDartTypeMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiDartTypeMismatch(DartType _type, DartType _type2) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeFfiDartTypeMismatch,
      message: """Expected '${type}' to be a subtype of '${type2}'.""" +
          labeler.originMessages,
      arguments: {'type': _type, 'type2': _type2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        DartType
            _type)> templateFfiExpectedExceptionalReturn = const Template<
        Message Function(DartType _type)>(
    messageTemplate:
        r"""Expected an exceptional return value for a native callback returning '#type'.""",
    withArguments: _withArgumentsFfiExpectedExceptionalReturn);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type)> codeFfiExpectedExceptionalReturn =
    const Code<Message Function(DartType _type)>(
  "FfiExpectedExceptionalReturn",
  templateFfiExpectedExceptionalReturn,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiExpectedExceptionalReturn(DartType _type) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(codeFfiExpectedExceptionalReturn,
      message:
          """Expected an exceptional return value for a native callback returning '${type}'.""" +
              labeler.originMessages,
      arguments: {'type': _type});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        DartType
            _type)> templateFfiExpectedNoExceptionalReturn = const Template<
        Message Function(DartType _type)>(
    messageTemplate:
        r"""Exceptional return value cannot be provided for a native callback returning '#type'.""",
    withArguments: _withArgumentsFfiExpectedNoExceptionalReturn);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type)>
    codeFfiExpectedNoExceptionalReturn =
    const Code<Message Function(DartType _type)>(
  "FfiExpectedNoExceptionalReturn",
  templateFfiExpectedNoExceptionalReturn,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiExpectedNoExceptionalReturn(DartType _type) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(codeFfiExpectedNoExceptionalReturn,
      message:
          """Exceptional return value cannot be provided for a native callback returning '${type}'.""" +
              labeler.originMessages,
      arguments: {'type': _type});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(DartType _type)> templateFfiTypeInvalid = const Template<
        Message Function(DartType _type)>(
    messageTemplate:
        r"""Expected type '#type' to be a valid and instantiated subtype of 'NativeType'.""",
    withArguments: _withArgumentsFfiTypeInvalid);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type)> codeFfiTypeInvalid =
    const Code<Message Function(DartType _type)>(
  "FfiTypeInvalid",
  templateFfiTypeInvalid,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiTypeInvalid(DartType _type) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(codeFfiTypeInvalid,
      message:
          """Expected type '${type}' to be a valid and instantiated subtype of 'NativeType'.""" +
              labeler.originMessages,
      arguments: {'type': _type});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        DartType _type,
        DartType _type2,
        DartType
            _type3)> templateFfiTypeMismatch = const Template<
        Message Function(DartType _type, DartType _type2, DartType _type3)>(
    messageTemplate:
        r"""Expected type '#type' to be '#type2', which is the Dart type corresponding to '#type3'.""",
    withArguments: _withArgumentsFfiTypeMismatch);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2, DartType _type3)>
    codeFfiTypeMismatch = const Code<
        Message Function(DartType _type, DartType _type2, DartType _type3)>(
  "FfiTypeMismatch",
  templateFfiTypeMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiTypeMismatch(
    DartType _type, DartType _type2, DartType _type3) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  List<Object> type3Parts = labeler.labelType(_type3);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  String type3 = type3Parts.join();
  return new Message(codeFfiTypeMismatch,
      message:
          """Expected type '${type}' to be '${type2}', which is the Dart type corresponding to '${type3}'.""" +
              labeler.originMessages,
      arguments: {'type': _type, 'type2': _type2, 'type3': _type3});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        DartType _type,
        DartType
            _type2)> templateForInLoopElementTypeNotAssignable = const Template<
        Message Function(DartType _type, DartType _type2)>(
    messageTemplate:
        r"""A value of type '#type' can't be assigned to a variable of type '#type2'.""",
    tipTemplate: r"""Try changing the type of the variable.""",
    withArguments: _withArgumentsForInLoopElementTypeNotAssignable);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
    codeForInLoopElementTypeNotAssignable =
    const Code<Message Function(DartType _type, DartType _type2)>(
        "ForInLoopElementTypeNotAssignable",
        templateForInLoopElementTypeNotAssignable,
        analyzerCodes: <String>["FOR_IN_OF_INVALID_ELEMENT_TYPE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsForInLoopElementTypeNotAssignable(
    DartType _type, DartType _type2) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeForInLoopElementTypeNotAssignable,
      message:
          """A value of type '${type}' can't be assigned to a variable of type '${type2}'.""" +
              labeler.originMessages,
      tip: """Try changing the type of the variable.""",
      arguments: {'type': _type, 'type2': _type2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        DartType _type,
        DartType
            _type2)> templateForInLoopTypeNotIterable = const Template<
        Message Function(DartType _type, DartType _type2)>(
    messageTemplate:
        r"""The type '#type' used in the 'for' loop must implement '#type2'.""",
    withArguments: _withArgumentsForInLoopTypeNotIterable);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
    codeForInLoopTypeNotIterable =
    const Code<Message Function(DartType _type, DartType _type2)>(
        "ForInLoopTypeNotIterable", templateForInLoopTypeNotIterable,
        analyzerCodes: <String>["FOR_IN_OF_INVALID_TYPE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsForInLoopTypeNotIterable(
    DartType _type, DartType _type2) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeForInLoopTypeNotIterable,
      message:
          """The type '${type}' used in the 'for' loop must implement '${type2}'.""" +
              labeler.originMessages,
      arguments: {'type': _type, 'type2': _type2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type)>
    templateGenericFunctionTypeInferredAsActualTypeArgument =
    const Template<Message Function(DartType _type)>(
        messageTemplate:
            r"""Generic function type '#type' inferred as a type argument.""",
        tipTemplate:
            r"""Try providing a non-generic function type explicitly.""",
        withArguments:
            _withArgumentsGenericFunctionTypeInferredAsActualTypeArgument);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type)>
    codeGenericFunctionTypeInferredAsActualTypeArgument =
    const Code<Message Function(DartType _type)>(
        "GenericFunctionTypeInferredAsActualTypeArgument",
        templateGenericFunctionTypeInferredAsActualTypeArgument,
        analyzerCodes: <String>["GENERIC_FUNCTION_CANNOT_BE_TYPE_ARGUMENT"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsGenericFunctionTypeInferredAsActualTypeArgument(
    DartType _type) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(codeGenericFunctionTypeInferredAsActualTypeArgument,
      message:
          """Generic function type '${type}' inferred as a type argument.""" +
              labeler.originMessages,
      tip: """Try providing a non-generic function type explicitly.""",
      arguments: {'type': _type});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type)> templateIllegalRecursiveType =
    const Template<Message Function(DartType _type)>(
        messageTemplate: r"""Illegal recursive type '#type'.""",
        withArguments: _withArgumentsIllegalRecursiveType);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type)> codeIllegalRecursiveType =
    const Code<Message Function(DartType _type)>(
  "IllegalRecursiveType",
  templateIllegalRecursiveType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIllegalRecursiveType(DartType _type) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(codeIllegalRecursiveType,
      message: """Illegal recursive type '${type}'.""" + labeler.originMessages,
      arguments: {'type': _type});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        DartType
            _type)> templateImplicitCallOfNonMethod = const Template<
        Message Function(DartType _type)>(
    messageTemplate:
        r"""Cannot invoke an instance of '#type' because it declares 'call' to be something other than a method.""",
    tipTemplate:
        r"""Try changing 'call' to a method or explicitly invoke 'call'.""",
    withArguments: _withArgumentsImplicitCallOfNonMethod);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type)> codeImplicitCallOfNonMethod =
    const Code<Message Function(DartType _type)>(
        "ImplicitCallOfNonMethod", templateImplicitCallOfNonMethod,
        analyzerCodes: <String>["IMPLICIT_CALL_OF_NON_METHOD"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsImplicitCallOfNonMethod(DartType _type) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(codeImplicitCallOfNonMethod,
      message:
          """Cannot invoke an instance of '${type}' because it declares 'call' to be something other than a method.""" +
              labeler.originMessages,
      tip: """Try changing 'call' to a method or explicitly invoke 'call'.""",
      arguments: {'type': _type});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        DartType _type,
        DartType
            _type2)> templateIncompatibleRedirecteeFunctionType = const Template<
        Message Function(DartType _type, DartType _type2)>(
    messageTemplate:
        r"""The constructor function type '#type' isn't a subtype of '#type2'.""",
    withArguments: _withArgumentsIncompatibleRedirecteeFunctionType);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
    codeIncompatibleRedirecteeFunctionType =
    const Code<Message Function(DartType _type, DartType _type2)>(
        "IncompatibleRedirecteeFunctionType",
        templateIncompatibleRedirecteeFunctionType,
        analyzerCodes: <String>["REDIRECT_TO_INVALID_TYPE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIncompatibleRedirecteeFunctionType(
    DartType _type, DartType _type2) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeIncompatibleRedirecteeFunctionType,
      message:
          """The constructor function type '${type}' isn't a subtype of '${type2}'.""" +
              labeler.originMessages,
      arguments: {'type': _type, 'type2': _type2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        DartType _type,
        DartType _type2,
        String name,
        String
            name2)> templateIncorrectTypeArgument = const Template<
        Message Function(
            DartType _type, DartType _type2, String name, String name2)>(
    messageTemplate:
        r"""Type argument '#type' doesn't conform to the bound '#type2' of the type variable '#name' on '#name2'.""",
    tipTemplate:
        r"""Try changing type arguments so that they conform to the bounds.""",
    withArguments: _withArgumentsIncorrectTypeArgument);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            DartType _type, DartType _type2, String name, String name2)>
    codeIncorrectTypeArgument = const Code<
            Message Function(
                DartType _type, DartType _type2, String name, String name2)>(
        "IncorrectTypeArgument", templateIncorrectTypeArgument,
        analyzerCodes: <String>["TYPE_ARGUMENT_NOT_MATCHING_BOUNDS"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIncorrectTypeArgument(
    DartType _type, DartType _type2, String name, String name2) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeIncorrectTypeArgument,
      message:
          """Type argument '${type}' doesn't conform to the bound '${type2}' of the type variable '${name}' on '${name2}'.""" +
              labeler.originMessages,
      tip: """Try changing type arguments so that they conform to the bounds.""",
      arguments: {
        'type': _type,
        'type2': _type2,
        'name': name,
        'name2': name2
      });
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        DartType _type,
        DartType _type2,
        String name,
        String
            name2)> templateIncorrectTypeArgumentInReturnType = const Template<
        Message Function(
            DartType _type, DartType _type2, String name, String name2)>(
    messageTemplate:
        r"""Type argument '#type' doesn't conform to the bound '#type2' of the type variable '#name' on '#name2' in the return type.""",
    tipTemplate:
        r"""Try changing type arguments so that they conform to the bounds.""",
    withArguments: _withArgumentsIncorrectTypeArgumentInReturnType);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            DartType _type, DartType _type2, String name, String name2)>
    codeIncorrectTypeArgumentInReturnType = const Code<
            Message Function(
                DartType _type, DartType _type2, String name, String name2)>(
        "IncorrectTypeArgumentInReturnType",
        templateIncorrectTypeArgumentInReturnType,
        analyzerCodes: <String>["TYPE_ARGUMENT_NOT_MATCHING_BOUNDS"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIncorrectTypeArgumentInReturnType(
    DartType _type, DartType _type2, String name, String name2) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeIncorrectTypeArgumentInReturnType,
      message:
          """Type argument '${type}' doesn't conform to the bound '${type2}' of the type variable '${name}' on '${name2}' in the return type.""" +
              labeler.originMessages,
      tip: """Try changing type arguments so that they conform to the bounds.""",
      arguments: {
        'type': _type,
        'type2': _type2,
        'name': name,
        'name2': name2
      });
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        DartType _type,
        DartType _type2,
        String name,
        String name2,
        String name3,
        String
            name4)> templateIncorrectTypeArgumentInSupertype = const Template<
        Message Function(DartType _type, DartType _type2, String name,
            String name2, String name3, String name4)>(
    messageTemplate:
        r"""Type argument '#type' doesn't conform to the bound '#type2' of the type variable '#name' on '#name2' in the supertype '#name3' of class '#name4'.""",
    tipTemplate:
        r"""Try changing type arguments so that they conform to the bounds.""",
    withArguments: _withArgumentsIncorrectTypeArgumentInSupertype);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(DartType _type, DartType _type2, String name,
            String name2, String name3, String name4)>
    codeIncorrectTypeArgumentInSupertype = const Code<
            Message Function(DartType _type, DartType _type2, String name,
                String name2, String name3, String name4)>(
        "IncorrectTypeArgumentInSupertype",
        templateIncorrectTypeArgumentInSupertype,
        analyzerCodes: <String>["TYPE_ARGUMENT_NOT_MATCHING_BOUNDS"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIncorrectTypeArgumentInSupertype(DartType _type,
    DartType _type2, String name, String name2, String name3, String name4) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  if (name3.isEmpty) throw 'No name provided';
  name3 = demangleMixinApplicationName(name3);
  if (name4.isEmpty) throw 'No name provided';
  name4 = demangleMixinApplicationName(name4);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeIncorrectTypeArgumentInSupertype,
      message:
          """Type argument '${type}' doesn't conform to the bound '${type2}' of the type variable '${name}' on '${name2}' in the supertype '${name3}' of class '${name4}'.""" +
              labeler.originMessages,
      tip:
          """Try changing type arguments so that they conform to the bounds.""",
      arguments: {
        'type': _type,
        'type2': _type2,
        'name': name,
        'name2': name2,
        'name3': name3,
        'name4': name4
      });
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        DartType _type,
        DartType _type2,
        String name,
        String name2,
        String name3,
        String
            name4)> templateIncorrectTypeArgumentInSupertypeInferred = const Template<
        Message Function(
            DartType _type,
            DartType _type2,
            String name,
            String name2,
            String name3,
            String
                name4)>(
    messageTemplate:
        r"""Inferred type argument '#type' doesn't conform to the bound '#type2' of the type variable '#name' on '#name2' in the supertype '#name3' of class '#name4'.""",
    tipTemplate:
        r"""Try specifying type arguments explicitly so that they conform to the bounds.""",
    withArguments: _withArgumentsIncorrectTypeArgumentInSupertypeInferred);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(DartType _type, DartType _type2, String name,
            String name2, String name3, String name4)>
    codeIncorrectTypeArgumentInSupertypeInferred = const Code<
            Message Function(DartType _type, DartType _type2, String name,
                String name2, String name3, String name4)>(
        "IncorrectTypeArgumentInSupertypeInferred",
        templateIncorrectTypeArgumentInSupertypeInferred,
        analyzerCodes: <String>["TYPE_ARGUMENT_NOT_MATCHING_BOUNDS"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIncorrectTypeArgumentInSupertypeInferred(DartType _type,
    DartType _type2, String name, String name2, String name3, String name4) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  if (name3.isEmpty) throw 'No name provided';
  name3 = demangleMixinApplicationName(name3);
  if (name4.isEmpty) throw 'No name provided';
  name4 = demangleMixinApplicationName(name4);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeIncorrectTypeArgumentInSupertypeInferred,
      message:
          """Inferred type argument '${type}' doesn't conform to the bound '${type2}' of the type variable '${name}' on '${name2}' in the supertype '${name3}' of class '${name4}'.""" +
              labeler.originMessages,
      tip:
          """Try specifying type arguments explicitly so that they conform to the bounds.""",
      arguments: {
        'type': _type,
        'type2': _type2,
        'name': name,
        'name2': name2,
        'name3': name3,
        'name4': name4
      });
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        DartType _type,
        DartType _type2,
        String name,
        String
            name2)> templateIncorrectTypeArgumentInferred = const Template<
        Message Function(
            DartType _type, DartType _type2, String name, String name2)>(
    messageTemplate:
        r"""Inferred type argument '#type' doesn't conform to the bound '#type2' of the type variable '#name' on '#name2'.""",
    tipTemplate:
        r"""Try specifying type arguments explicitly so that they conform to the bounds.""",
    withArguments: _withArgumentsIncorrectTypeArgumentInferred);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            DartType _type, DartType _type2, String name, String name2)>
    codeIncorrectTypeArgumentInferred = const Code<
            Message Function(
                DartType _type, DartType _type2, String name, String name2)>(
        "IncorrectTypeArgumentInferred", templateIncorrectTypeArgumentInferred,
        analyzerCodes: <String>["TYPE_ARGUMENT_NOT_MATCHING_BOUNDS"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIncorrectTypeArgumentInferred(
    DartType _type, DartType _type2, String name, String name2) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeIncorrectTypeArgumentInferred,
      message:
          """Inferred type argument '${type}' doesn't conform to the bound '${type2}' of the type variable '${name}' on '${name2}'.""" +
              labeler.originMessages,
      tip: """Try specifying type arguments explicitly so that they conform to the bounds.""",
      arguments: {
        'type': _type,
        'type2': _type2,
        'name': name,
        'name2': name2
      });
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        DartType _type,
        DartType _type2,
        String name,
        DartType _type3,
        String
            name2)> templateIncorrectTypeArgumentQualified = const Template<
        Message Function(
            DartType _type,
            DartType _type2,
            String name,
            DartType _type3,
            String
                name2)>(
    messageTemplate:
        r"""Type argument '#type' doesn't conform to the bound '#type2' of the type variable '#name' on '#type3.#name2'.""",
    tipTemplate:
        r"""Try changing type arguments so that they conform to the bounds.""",
    withArguments: _withArgumentsIncorrectTypeArgumentQualified);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(DartType _type, DartType _type2, String name,
            DartType _type3, String name2)> codeIncorrectTypeArgumentQualified =
    const Code<
            Message Function(DartType _type, DartType _type2, String name,
                DartType _type3, String name2)>(
        "IncorrectTypeArgumentQualified",
        templateIncorrectTypeArgumentQualified,
        analyzerCodes: <String>["TYPE_ARGUMENT_NOT_MATCHING_BOUNDS"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIncorrectTypeArgumentQualified(DartType _type,
    DartType _type2, String name, DartType _type3, String name2) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  List<Object> type3Parts = labeler.labelType(_type3);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  String type3 = type3Parts.join();
  return new Message(codeIncorrectTypeArgumentQualified,
      message:
          """Type argument '${type}' doesn't conform to the bound '${type2}' of the type variable '${name}' on '${type3}.${name2}'.""" +
              labeler.originMessages,
      tip: """Try changing type arguments so that they conform to the bounds.""",
      arguments: {
        'type': _type,
        'type2': _type2,
        'name': name,
        'type3': _type3,
        'name2': name2
      });
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        DartType _type,
        DartType _type2,
        String name,
        DartType _type3,
        String
            name2)> templateIncorrectTypeArgumentQualifiedInferred = const Template<
        Message Function(DartType _type, DartType _type2, String name,
            DartType _type3, String name2)>(
    messageTemplate:
        r"""Inferred type argument '#type' doesn't conform to the bound '#type2' of the type variable '#name' on '#type3.#name2'.""",
    tipTemplate:
        r"""Try specifying type arguments explicitly so that they conform to the bounds.""",
    withArguments: _withArgumentsIncorrectTypeArgumentQualifiedInferred);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(DartType _type, DartType _type2, String name,
            DartType _type3, String name2)>
    codeIncorrectTypeArgumentQualifiedInferred = const Code<
            Message Function(DartType _type, DartType _type2, String name,
                DartType _type3, String name2)>(
        "IncorrectTypeArgumentQualifiedInferred",
        templateIncorrectTypeArgumentQualifiedInferred,
        analyzerCodes: <String>["TYPE_ARGUMENT_NOT_MATCHING_BOUNDS"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIncorrectTypeArgumentQualifiedInferred(DartType _type,
    DartType _type2, String name, DartType _type3, String name2) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  List<Object> type3Parts = labeler.labelType(_type3);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  String type3 = type3Parts.join();
  return new Message(codeIncorrectTypeArgumentQualifiedInferred,
      message:
          """Inferred type argument '${type}' doesn't conform to the bound '${type2}' of the type variable '${name}' on '${type3}.${name2}'.""" +
              labeler.originMessages,
      tip: """Try specifying type arguments explicitly so that they conform to the bounds.""",
      arguments: {
        'type': _type,
        'type2': _type2,
        'name': name,
        'type3': _type3,
        'name2': name2
      });
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String name,
        DartType _type,
        DartType
            _type2)> templateInitializingFormalTypeMismatch = const Template<
        Message Function(String name, DartType _type, DartType _type2)>(
    messageTemplate:
        r"""The type of parameter '#name', '#type' is not a subtype of the corresponding field's type, '#type2'.""",
    tipTemplate:
        r"""Try changing the type of parameter '#name' to a subtype of '#type2'.""",
    withArguments: _withArgumentsInitializingFormalTypeMismatch);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, DartType _type, DartType _type2)>
    codeInitializingFormalTypeMismatch =
    const Code<Message Function(String name, DartType _type, DartType _type2)>(
        "InitializingFormalTypeMismatch",
        templateInitializingFormalTypeMismatch,
        analyzerCodes: <String>["INVALID_PARAMETER_DECLARATION"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInitializingFormalTypeMismatch(
    String name, DartType _type, DartType _type2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeInitializingFormalTypeMismatch,
      message:
          """The type of parameter '${name}', '${type}' is not a subtype of the corresponding field's type, '${type2}'.""" +
              labeler.originMessages,
      tip: """Try changing the type of parameter '${name}' to a subtype of '${type2}'.""",
      arguments: {'name': name, 'type': _type, 'type2': _type2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        DartType _type,
        DartType
            _type2)> templateInvalidAssignment = const Template<
        Message Function(DartType _type, DartType _type2)>(
    messageTemplate:
        r"""A value of type '#type' can't be assigned to a variable of type '#type2'.""",
    withArguments: _withArgumentsInvalidAssignment);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
    codeInvalidAssignment =
    const Code<Message Function(DartType _type, DartType _type2)>(
        "InvalidAssignment", templateInvalidAssignment,
        analyzerCodes: <String>["INVALID_ASSIGNMENT"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidAssignment(DartType _type, DartType _type2) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeInvalidAssignment,
      message:
          """A value of type '${type}' can't be assigned to a variable of type '${type2}'.""" +
              labeler.originMessages,
      arguments: {'type': _type, 'type2': _type2});
}

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
        analyzerCodes: <String>["INVALID_CAST_FUNCTION_EXPR"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidCastFunctionExpr(DartType _type, DartType _type2) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeInvalidCastFunctionExpr,
      message:
          """The function expression type '${type}' isn't of expected type '${type2}'.""" +
              labeler.originMessages,
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
        analyzerCodes: <String>["INVALID_CAST_LITERAL_LIST"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidCastLiteralList(DartType _type, DartType _type2) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeInvalidCastLiteralList,
      message:
          """The list literal type '${type}' isn't of expected type '${type2}'.""" +
              labeler.originMessages,
      tip: """Change the type of the list literal or the context in which it is used.""",
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
        analyzerCodes: <String>["INVALID_CAST_LITERAL_MAP"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidCastLiteralMap(DartType _type, DartType _type2) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeInvalidCastLiteralMap,
      message:
          """The map literal type '${type}' isn't of expected type '${type2}'.""" +
              labeler.originMessages,
      tip: """Change the type of the map literal or the context in which it is used.""",
      arguments: {'type': _type, 'type2': _type2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        DartType _type,
        DartType
            _type2)> templateInvalidCastLiteralSet = const Template<
        Message Function(DartType _type, DartType _type2)>(
    messageTemplate:
        r"""The set literal type '#type' isn't of expected type '#type2'.""",
    tipTemplate:
        r"""Change the type of the set literal or the context in which it is used.""",
    withArguments: _withArgumentsInvalidCastLiteralSet);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
    codeInvalidCastLiteralSet =
    const Code<Message Function(DartType _type, DartType _type2)>(
        "InvalidCastLiteralSet", templateInvalidCastLiteralSet,
        analyzerCodes: <String>["INVALID_CAST_LITERAL_SET"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidCastLiteralSet(DartType _type, DartType _type2) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeInvalidCastLiteralSet,
      message:
          """The set literal type '${type}' isn't of expected type '${type2}'.""" +
              labeler.originMessages,
      tip: """Change the type of the set literal or the context in which it is used.""",
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
        analyzerCodes: <String>["INVALID_CAST_FUNCTION"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidCastLocalFunction(
    DartType _type, DartType _type2) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeInvalidCastLocalFunction,
      message:
          """The local function has type '${type}' that isn't of expected type '${type2}'.""" +
              labeler.originMessages,
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
        analyzerCodes: <String>["INVALID_CAST_NEW_EXPR"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidCastNewExpr(DartType _type, DartType _type2) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeInvalidCastNewExpr,
      message:
          """The constructor returns type '${type}' that isn't of expected type '${type2}'.""" +
              labeler.originMessages,
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
        analyzerCodes: <String>["INVALID_CAST_METHOD"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidCastStaticMethod(DartType _type, DartType _type2) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeInvalidCastStaticMethod,
      message:
          """The static method has type '${type}' that isn't of expected type '${type2}'.""" +
              labeler.originMessages,
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
        analyzerCodes: <String>["INVALID_CAST_FUNCTION"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidCastTopLevelFunction(
    DartType _type, DartType _type2) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeInvalidCastTopLevelFunction,
      message:
          """The top level function has type '${type}' that isn't of expected type '${type2}'.""" +
              labeler.originMessages,
      tip: """Change the type of the function or the context in which it is used.""",
      arguments: {'type': _type, 'type2': _type2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(DartType _type, DartType _type2, DartType _type3)>
    templateMixinApplicationIncompatibleSupertype = const Template<
            Message Function(DartType _type, DartType _type2, DartType _type3)>(
        messageTemplate:
            r"""'#type' doesn't implement '#type2' so it can't be used with '#type3'.""",
        withArguments: _withArgumentsMixinApplicationIncompatibleSupertype);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2, DartType _type3)>
    codeMixinApplicationIncompatibleSupertype = const Code<
            Message Function(DartType _type, DartType _type2, DartType _type3)>(
        "MixinApplicationIncompatibleSupertype",
        templateMixinApplicationIncompatibleSupertype,
        analyzerCodes: <String>["MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMixinApplicationIncompatibleSupertype(
    DartType _type, DartType _type2, DartType _type3) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  List<Object> type3Parts = labeler.labelType(_type3);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  String type3 = type3Parts.join();
  return new Message(codeMixinApplicationIncompatibleSupertype,
      message:
          """'${type}' doesn't implement '${type2}' so it can't be used with '${type3}'.""" +
              labeler.originMessages,
      arguments: {'type': _type, 'type2': _type2, 'type3': _type3});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String name,
        String name2,
        DartType
            _type)> templateMixinInferenceNoMatchingClass = const Template<
        Message Function(String name, String name2, DartType _type)>(
    messageTemplate:
        r"""Type parameters could not be inferred for the mixin '#name' because '#name2' does not implement the mixin's supertype constraint '#type'.""",
    withArguments: _withArgumentsMixinInferenceNoMatchingClass);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String name2, DartType _type)>
    codeMixinInferenceNoMatchingClass =
    const Code<Message Function(String name, String name2, DartType _type)>(
        "MixinInferenceNoMatchingClass", templateMixinInferenceNoMatchingClass,
        analyzerCodes: <String>["MIXIN_INFERENCE_NO_POSSIBLE_SUBSTITUTION"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMixinInferenceNoMatchingClass(
    String name, String name2, DartType _type) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(codeMixinInferenceNoMatchingClass,
      message:
          """Type parameters could not be inferred for the mixin '${name}' because '${name2}' does not implement the mixin's supertype constraint '${type}'.""" +
              labeler.originMessages,
      arguments: {'name': name, 'name2': name2, 'type': _type});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String name,
        String name2,
        DartType _type,
        DartType _type2,
        String
            name3)> templateOverrideTypeMismatchParameter = const Template<
        Message Function(
            String name,
            String name2,
            DartType _type,
            DartType _type2,
            String
                name3)>(
    messageTemplate:
        r"""The parameter '#name' of the method '#name2' has type '#type', which does not match the corresponding type, '#type2', in the overridden method, '#name3'.""",
    tipTemplate:
        r"""Change to a supertype of '#type2', or, for a covariant parameter, a subtype.""",
    withArguments: _withArgumentsOverrideTypeMismatchParameter);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(String name, String name2, DartType _type,
            DartType _type2, String name3)> codeOverrideTypeMismatchParameter =
    const Code<
            Message Function(String name, String name2, DartType _type,
                DartType _type2, String name3)>(
        "OverrideTypeMismatchParameter", templateOverrideTypeMismatchParameter,
        analyzerCodes: <String>["INVALID_METHOD_OVERRIDE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideTypeMismatchParameter(
    String name, String name2, DartType _type, DartType _type2, String name3) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  if (name3.isEmpty) throw 'No name provided';
  name3 = demangleMixinApplicationName(name3);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeOverrideTypeMismatchParameter,
      message:
          """The parameter '${name}' of the method '${name2}' has type '${type}', which does not match the corresponding type, '${type2}', in the overridden method, '${name3}'.""" +
              labeler.originMessages,
      tip: """Change to a supertype of '${type2}', or, for a covariant parameter, a subtype.""",
      arguments: {
        'name': name,
        'name2': name2,
        'type': _type,
        'type2': _type2,
        'name3': name3
      });
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String name,
        DartType _type,
        DartType _type2,
        String
            name2)> templateOverrideTypeMismatchReturnType = const Template<
        Message Function(
            String name, DartType _type, DartType _type2, String name2)>(
    messageTemplate:
        r"""The return type of the method '#name' is '#type', which does not match the return type, '#type2', of the overridden method, '#name2'.""",
    tipTemplate: r"""Change to a subtype of '#type2'.""",
    withArguments: _withArgumentsOverrideTypeMismatchReturnType);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            String name, DartType _type, DartType _type2, String name2)>
    codeOverrideTypeMismatchReturnType = const Code<
            Message Function(
                String name, DartType _type, DartType _type2, String name2)>(
        "OverrideTypeMismatchReturnType",
        templateOverrideTypeMismatchReturnType,
        analyzerCodes: <String>["INVALID_METHOD_OVERRIDE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideTypeMismatchReturnType(
    String name, DartType _type, DartType _type2, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeOverrideTypeMismatchReturnType,
      message:
          """The return type of the method '${name}' is '${type}', which does not match the return type, '${type2}', of the overridden method, '${name2}'.""" +
              labeler.originMessages,
      tip: """Change to a subtype of '${type2}'.""",
      arguments: {
        'name': name,
        'type': _type,
        'type2': _type2,
        'name2': name2
      });
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String name,
        DartType _type,
        DartType _type2,
        String
            name2)> templateOverrideTypeMismatchSetter = const Template<
        Message Function(
            String name, DartType _type, DartType _type2, String name2)>(
    messageTemplate:
        r"""The field '#name' has type '#type', which does not match the corresponding type, '#type2', in the overridden setter, '#name2'.""",
    withArguments: _withArgumentsOverrideTypeMismatchSetter);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            String name, DartType _type, DartType _type2, String name2)>
    codeOverrideTypeMismatchSetter = const Code<
            Message Function(
                String name, DartType _type, DartType _type2, String name2)>(
        "OverrideTypeMismatchSetter", templateOverrideTypeMismatchSetter,
        analyzerCodes: <String>["INVALID_METHOD_OVERRIDE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideTypeMismatchSetter(
    String name, DartType _type, DartType _type2, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeOverrideTypeMismatchSetter,
      message:
          """The field '${name}' has type '${type}', which does not match the corresponding type, '${type2}', in the overridden setter, '${name2}'.""" +
              labeler.originMessages,
      arguments: {
        'name': name,
        'type': _type,
        'type2': _type2,
        'name2': name2
      });
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, DartType _type2)>
    templateRedirectingFactoryIncompatibleTypeArgument =
    const Template<Message Function(DartType _type, DartType _type2)>(
        messageTemplate: r"""The type '#type' doesn't extend '#type2'.""",
        tipTemplate: r"""Try using a different type as argument.""",
        withArguments:
            _withArgumentsRedirectingFactoryIncompatibleTypeArgument);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
    codeRedirectingFactoryIncompatibleTypeArgument =
    const Code<Message Function(DartType _type, DartType _type2)>(
        "RedirectingFactoryIncompatibleTypeArgument",
        templateRedirectingFactoryIncompatibleTypeArgument,
        analyzerCodes: <String>["TYPE_ARGUMENT_NOT_MATCHING_BOUNDS"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsRedirectingFactoryIncompatibleTypeArgument(
    DartType _type, DartType _type2) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeRedirectingFactoryIncompatibleTypeArgument,
      message: """The type '${type}' doesn't extend '${type2}'.""" +
          labeler.originMessages,
      tip: """Try using a different type as argument.""",
      arguments: {'type': _type, 'type2': _type2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        DartType _type,
        DartType
            _type2)> templateSpreadElementTypeMismatch = const Template<
        Message Function(DartType _type, DartType _type2)>(
    messageTemplate:
        r"""Can't assign spread elements of type '#type' to collection elements of type '#type2'.""",
    withArguments: _withArgumentsSpreadElementTypeMismatch);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
    codeSpreadElementTypeMismatch =
    const Code<Message Function(DartType _type, DartType _type2)>(
        "SpreadElementTypeMismatch", templateSpreadElementTypeMismatch,
        analyzerCodes: <String>["LIST_ELEMENT_TYPE_NOT_ASSIGNABLE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSpreadElementTypeMismatch(
    DartType _type, DartType _type2) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeSpreadElementTypeMismatch,
      message:
          """Can't assign spread elements of type '${type}' to collection elements of type '${type2}'.""" +
              labeler.originMessages,
      arguments: {'type': _type, 'type2': _type2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        DartType _type,
        DartType
            _type2)> templateSpreadMapEntryElementKeyTypeMismatch = const Template<
        Message Function(DartType _type, DartType _type2)>(
    messageTemplate:
        r"""Can't assign spread entry keys of type '#type' to map entry keys of type '#type2'.""",
    withArguments: _withArgumentsSpreadMapEntryElementKeyTypeMismatch);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
    codeSpreadMapEntryElementKeyTypeMismatch =
    const Code<Message Function(DartType _type, DartType _type2)>(
        "SpreadMapEntryElementKeyTypeMismatch",
        templateSpreadMapEntryElementKeyTypeMismatch,
        analyzerCodes: <String>["MAP_KEY_TYPE_NOT_ASSIGNABLE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSpreadMapEntryElementKeyTypeMismatch(
    DartType _type, DartType _type2) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeSpreadMapEntryElementKeyTypeMismatch,
      message:
          """Can't assign spread entry keys of type '${type}' to map entry keys of type '${type2}'.""" +
              labeler.originMessages,
      arguments: {'type': _type, 'type2': _type2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, DartType _type2)>
    templateSpreadMapEntryElementValueTypeMismatch =
    const Template<Message Function(DartType _type, DartType _type2)>(
        messageTemplate:
            r"""Can't assign spread entry values of type '#type' to map entry values of type '#type2'.""",
        withArguments: _withArgumentsSpreadMapEntryElementValueTypeMismatch);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
    codeSpreadMapEntryElementValueTypeMismatch =
    const Code<Message Function(DartType _type, DartType _type2)>(
        "SpreadMapEntryElementValueTypeMismatch",
        templateSpreadMapEntryElementValueTypeMismatch,
        analyzerCodes: <String>["MAP_VALUE_TYPE_NOT_ASSIGNABLE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSpreadMapEntryElementValueTypeMismatch(
    DartType _type, DartType _type2) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeSpreadMapEntryElementValueTypeMismatch,
      message:
          """Can't assign spread entry values of type '${type}' to map entry values of type '${type2}'.""" +
              labeler.originMessages,
      arguments: {'type': _type, 'type2': _type2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        DartType
            _type)> templateSpreadMapEntryTypeMismatch = const Template<
        Message Function(DartType _type)>(
    messageTemplate:
        r"""Unexpected type '#type' of a map spread entry.  Expected 'dynamic' or a Map.""",
    withArguments: _withArgumentsSpreadMapEntryTypeMismatch);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type)> codeSpreadMapEntryTypeMismatch =
    const Code<Message Function(DartType _type)>(
  "SpreadMapEntryTypeMismatch",
  templateSpreadMapEntryTypeMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSpreadMapEntryTypeMismatch(DartType _type) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(codeSpreadMapEntryTypeMismatch,
      message:
          """Unexpected type '${type}' of a map spread entry.  Expected 'dynamic' or a Map.""" +
              labeler.originMessages,
      arguments: {'type': _type});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        DartType
            _type)> templateSpreadTypeMismatch = const Template<
        Message Function(DartType _type)>(
    messageTemplate:
        r"""Unexpected type '#type' of a spread.  Expected 'dynamic' or an Iterable.""",
    withArguments: _withArgumentsSpreadTypeMismatch);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type)> codeSpreadTypeMismatch =
    const Code<Message Function(DartType _type)>(
  "SpreadTypeMismatch",
  templateSpreadTypeMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSpreadTypeMismatch(DartType _type) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(codeSpreadTypeMismatch,
      message:
          """Unexpected type '${type}' of a spread.  Expected 'dynamic' or an Iterable.""" +
              labeler.originMessages,
      arguments: {'type': _type});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        DartType _type,
        DartType
            _type2)> templateSwitchExpressionNotAssignable = const Template<
        Message Function(DartType _type, DartType _type2)>(
    messageTemplate:
        r"""Type '#type' of the switch expression isn't assignable to the type '#type2' of this case expression.""",
    withArguments: _withArgumentsSwitchExpressionNotAssignable);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
    codeSwitchExpressionNotAssignable =
    const Code<Message Function(DartType _type, DartType _type2)>(
        "SwitchExpressionNotAssignable", templateSwitchExpressionNotAssignable,
        analyzerCodes: <String>["SWITCH_EXPRESSION_NOT_ASSIGNABLE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSwitchExpressionNotAssignable(
    DartType _type, DartType _type2) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeSwitchExpressionNotAssignable,
      message:
          """Type '${type}' of the switch expression isn't assignable to the type '${type2}' of this case expression.""" +
              labeler.originMessages,
      arguments: {'type': _type, 'type2': _type2});
}

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
        analyzerCodes: <String>["UNDEFINED_GETTER"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUndefinedGetter(String name, DartType _type) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(codeUndefinedGetter,
      message:
          """The getter '${name}' isn't defined for the class '${type}'.""" +
              labeler.originMessages,
      tip:
          """Try correcting the name to the name of an existing getter, or defining a getter or field named '${name}'.""",
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
        analyzerCodes: <String>["UNDEFINED_METHOD"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUndefinedMethod(String name, DartType _type) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(codeUndefinedMethod,
      message:
          """The method '${name}' isn't defined for the class '${type}'.""" +
              labeler.originMessages,
      tip:
          """Try correcting the name to the name of an existing method, or defining a method named '${name}'.""",
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
        analyzerCodes: <String>["UNDEFINED_SETTER"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUndefinedSetter(String name, DartType _type) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(codeUndefinedSetter,
      message:
          """The setter '${name}' isn't defined for the class '${type}'.""" +
              labeler.originMessages,
      tip:
          """Try correcting the name to the name of an existing setter, or defining a setter or field named '${name}'.""",
      arguments: {'name': name, 'type': _type});
}
