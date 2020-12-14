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
const Template<
    Message Function(
        String name,
        DartType _type,
        bool
            isNonNullableByDefault)> templateAmbiguousExtensionMethod = const Template<
        Message Function(
            String name, DartType _type, bool isNonNullableByDefault)>(
    messageTemplate:
        r"""The method '#name' is defined in multiple extensions for '#type' and neither is more specific.""",
    tipTemplate:
        r"""Try using an explicit extension application of the wanted extension or hiding unwanted extensions from scope.""",
    withArguments: _withArgumentsAmbiguousExtensionMethod);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
    Message Function(String name, DartType _type,
        bool isNonNullableByDefault)> codeAmbiguousExtensionMethod = const Code<
    Message Function(String name, DartType _type, bool isNonNullableByDefault)>(
  "AmbiguousExtensionMethod",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsAmbiguousExtensionMethod(
    String name, DartType _type, bool isNonNullableByDefault) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(codeAmbiguousExtensionMethod,
      message:
          """The method '${name}' is defined in multiple extensions for '${type}' and neither is more specific.""" +
              labeler.originMessages,
      tip: """Try using an explicit extension application of the wanted extension or hiding unwanted extensions from scope.""",
      arguments: {'name': name, 'type': _type});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(
            String name, DartType _type, bool isNonNullableByDefault)>
    templateAmbiguousExtensionOperator = const Template<
            Message Function(
                String name, DartType _type, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""The operator '#name' is defined in multiple extensions for '#type' and neither is more specific.""",
        tipTemplate:
            r"""Try using an explicit extension application of the wanted extension or hiding unwanted extensions from scope.""",
        withArguments: _withArgumentsAmbiguousExtensionOperator);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            String name, DartType _type, bool isNonNullableByDefault)>
    codeAmbiguousExtensionOperator = const Code<
        Message Function(
            String name, DartType _type, bool isNonNullableByDefault)>(
  "AmbiguousExtensionOperator",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsAmbiguousExtensionOperator(
    String name, DartType _type, bool isNonNullableByDefault) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(codeAmbiguousExtensionOperator,
      message:
          """The operator '${name}' is defined in multiple extensions for '${type}' and neither is more specific.""" +
              labeler.originMessages,
      tip: """Try using an explicit extension application of the wanted extension or hiding unwanted extensions from scope.""",
      arguments: {'name': name, 'type': _type});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(
            String name, DartType _type, bool isNonNullableByDefault)>
    templateAmbiguousExtensionProperty = const Template<
            Message Function(
                String name, DartType _type, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""The property '#name' is defined in multiple extensions for '#type' and neither is more specific.""",
        tipTemplate:
            r"""Try using an explicit extension application of the wanted extension or hiding unwanted extensions from scope.""",
        withArguments: _withArgumentsAmbiguousExtensionProperty);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            String name, DartType _type, bool isNonNullableByDefault)>
    codeAmbiguousExtensionProperty = const Code<
        Message Function(
            String name, DartType _type, bool isNonNullableByDefault)>(
  "AmbiguousExtensionProperty",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsAmbiguousExtensionProperty(
    String name, DartType _type, bool isNonNullableByDefault) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(codeAmbiguousExtensionProperty,
      message:
          """The property '${name}' is defined in multiple extensions for '${type}' and neither is more specific.""" +
              labeler.originMessages,
      tip: """Try using an explicit extension application of the wanted extension or hiding unwanted extensions from scope.""",
      arguments: {'name': name, 'type': _type});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(String name, DartType _type, DartType _type2,
            bool isNonNullableByDefault)> templateAmbiguousSupertypes =
    const Template<
            Message Function(String name, DartType _type, DartType _type2,
                bool isNonNullableByDefault)>(
        messageTemplate:
            r"""'#name' can't implement both '#type' and '#type2'""",
        withArguments: _withArgumentsAmbiguousSupertypes);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(String name, DartType _type, DartType _type2,
            bool isNonNullableByDefault)> codeAmbiguousSupertypes =
    const Code<
            Message Function(String name, DartType _type, DartType _type2,
                bool isNonNullableByDefault)>("AmbiguousSupertypes",
        analyzerCodes: <String>["AMBIGUOUS_SUPERTYPES"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsAmbiguousSupertypes(
    String name, DartType _type, DartType _type2, bool isNonNullableByDefault) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
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
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    templateArgumentTypeNotAssignable = const Template<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""The argument type '#type' can't be assigned to the parameter type '#type2'.""",
        withArguments: _withArgumentsArgumentTypeNotAssignable);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    codeArgumentTypeNotAssignable = const Code<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        "ArgumentTypeNotAssignable",
        analyzerCodes: <String>["ARGUMENT_TYPE_NOT_ASSIGNABLE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsArgumentTypeNotAssignable(
    DartType _type, DartType _type2, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
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
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    templateArgumentTypeNotAssignableNullability = const Template<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""The argument type '#type' can't be assigned to the parameter type '#type2' because '#type' is nullable and '#type2' isn't.""",
        withArguments: _withArgumentsArgumentTypeNotAssignableNullability);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    codeArgumentTypeNotAssignableNullability = const Code<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        "ArgumentTypeNotAssignableNullability",
        analyzerCodes: <String>["ARGUMENT_TYPE_NOT_ASSIGNABLE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsArgumentTypeNotAssignableNullability(
    DartType _type, DartType _type2, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeArgumentTypeNotAssignableNullability,
      message:
          """The argument type '${type}' can't be assigned to the parameter type '${type2}' because '${type}' is nullable and '${type2}' isn't.""" +
              labeler.originMessages,
      arguments: {'type': _type, 'type2': _type2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, bool isNonNullableByDefault)>
    templateArgumentTypeNotAssignableNullabilityNull = const Template<
            Message Function(DartType _type, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""The value 'null' can't be assigned to the parameter type '#type' because '#type' is not nullable.""",
        withArguments: _withArgumentsArgumentTypeNotAssignableNullabilityNull);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, bool isNonNullableByDefault)>
    codeArgumentTypeNotAssignableNullabilityNull =
    const Code<Message Function(DartType _type, bool isNonNullableByDefault)>(
        "ArgumentTypeNotAssignableNullabilityNull",
        analyzerCodes: <String>["ARGUMENT_TYPE_NOT_ASSIGNABLE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsArgumentTypeNotAssignableNullabilityNull(
    DartType _type, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(codeArgumentTypeNotAssignableNullabilityNull,
      message:
          """The value 'null' can't be assigned to the parameter type '${type}' because '${type}' is not nullable.""" +
              labeler.originMessages,
      arguments: {'type': _type});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    templateArgumentTypeNotAssignableNullabilityNullType = const Template<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""The argument type '#type' can't be assigned to the parameter type '#type2' because '#type2' is not nullable.""",
        withArguments:
            _withArgumentsArgumentTypeNotAssignableNullabilityNullType);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    codeArgumentTypeNotAssignableNullabilityNullType = const Code<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        "ArgumentTypeNotAssignableNullabilityNullType",
        analyzerCodes: <String>["ARGUMENT_TYPE_NOT_ASSIGNABLE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsArgumentTypeNotAssignableNullabilityNullType(
    DartType _type, DartType _type2, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeArgumentTypeNotAssignableNullabilityNullType,
      message:
          """The argument type '${type}' can't be assigned to the parameter type '${type2}' because '${type2}' is not nullable.""" +
              labeler.originMessages,
      arguments: {'type': _type, 'type2': _type2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(DartType _type, DartType _type2, DartType _type3,
            DartType _type4, bool isNonNullableByDefault)>
    templateArgumentTypeNotAssignablePartNullability = const Template<
            Message Function(DartType _type, DartType _type2, DartType _type3,
                DartType _type4, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""The argument type '#type' can't be assigned to the parameter type '#type2' because '#type3' is nullable and '#type4' isn't.""",
        withArguments: _withArgumentsArgumentTypeNotAssignablePartNullability);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(DartType _type, DartType _type2, DartType _type3,
            DartType _type4, bool isNonNullableByDefault)>
    codeArgumentTypeNotAssignablePartNullability = const Code<
            Message Function(DartType _type, DartType _type2, DartType _type3,
                DartType _type4, bool isNonNullableByDefault)>(
        "ArgumentTypeNotAssignablePartNullability",
        analyzerCodes: <String>["ARGUMENT_TYPE_NOT_ASSIGNABLE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsArgumentTypeNotAssignablePartNullability(
    DartType _type,
    DartType _type2,
    DartType _type3,
    DartType _type4,
    bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  List<Object> type3Parts = labeler.labelType(_type3);
  List<Object> type4Parts = labeler.labelType(_type4);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  String type3 = type3Parts.join();
  String type4 = type4Parts.join();
  return new Message(codeArgumentTypeNotAssignablePartNullability,
      message:
          """The argument type '${type}' can't be assigned to the parameter type '${type2}' because '${type3}' is nullable and '${type4}' isn't.""" +
              labeler.originMessages,
      arguments: {
        'type': _type,
        'type2': _type2,
        'type3': _type3,
        'type4': _type4
      });
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(Constant _constant, bool isNonNullableByDefault)>
    templateConstEvalCaseImplementsEqual = const Template<
            Message Function(Constant _constant, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""Case expression '#constant' does not have a primitive operator '=='.""",
        withArguments: _withArgumentsConstEvalCaseImplementsEqual);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Constant _constant, bool isNonNullableByDefault)>
    codeConstEvalCaseImplementsEqual = const Code<
        Message Function(Constant _constant, bool isNonNullableByDefault)>(
  "ConstEvalCaseImplementsEqual",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalCaseImplementsEqual(
    Constant _constant, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> constantParts = labeler.labelConstant(_constant);
  String constant = constantParts.join();
  return new Message(codeConstEvalCaseImplementsEqual,
      message:
          """Case expression '${constant}' does not have a primitive operator '=='.""" +
              labeler.originMessages,
      arguments: {'constant': _constant});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(Constant _constant, bool isNonNullableByDefault)>
    templateConstEvalDuplicateElement = const Template<
            Message Function(Constant _constant, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""The element '#constant' conflicts with another existing element in the set.""",
        withArguments: _withArgumentsConstEvalDuplicateElement);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Constant _constant, bool isNonNullableByDefault)>
    codeConstEvalDuplicateElement = const Code<
            Message Function(Constant _constant, bool isNonNullableByDefault)>(
        "ConstEvalDuplicateElement",
        analyzerCodes: <String>["EQUAL_ELEMENTS_IN_CONST_SET"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalDuplicateElement(
    Constant _constant, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
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
        Message Function(Constant _constant, bool isNonNullableByDefault)>
    templateConstEvalDuplicateKey = const Template<
            Message Function(Constant _constant, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""The key '#constant' conflicts with another existing key in the map.""",
        withArguments: _withArgumentsConstEvalDuplicateKey);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Constant _constant, bool isNonNullableByDefault)>
    codeConstEvalDuplicateKey = const Code<
            Message Function(Constant _constant, bool isNonNullableByDefault)>(
        "ConstEvalDuplicateKey",
        analyzerCodes: <String>["EQUAL_KEYS_IN_CONST_MAP"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalDuplicateKey(
    Constant _constant, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
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
        Message Function(Constant _constant, bool isNonNullableByDefault)>
    templateConstEvalElementImplementsEqual = const Template<
            Message Function(Constant _constant, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""The element '#constant' does not have a primitive operator '=='.""",
        withArguments: _withArgumentsConstEvalElementImplementsEqual);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Constant _constant, bool isNonNullableByDefault)>
    codeConstEvalElementImplementsEqual = const Code<
            Message Function(Constant _constant, bool isNonNullableByDefault)>(
        "ConstEvalElementImplementsEqual",
        analyzerCodes: <String>["CONST_SET_ELEMENT_TYPE_IMPLEMENTS_EQUALS"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalElementImplementsEqual(
    Constant _constant, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> constantParts = labeler.labelConstant(_constant);
  String constant = constantParts.join();
  return new Message(codeConstEvalElementImplementsEqual,
      message:
          """The element '${constant}' does not have a primitive operator '=='.""" +
              labeler.originMessages,
      arguments: {'constant': _constant});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, bool isNonNullableByDefault)>
    templateConstEvalFreeTypeParameter = const Template<
            Message Function(DartType _type, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""The type '#type' is not a constant because it depends on a type parameter, only instantiated types are allowed.""",
        withArguments: _withArgumentsConstEvalFreeTypeParameter);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, bool isNonNullableByDefault)>
    codeConstEvalFreeTypeParameter =
    const Code<Message Function(DartType _type, bool isNonNullableByDefault)>(
  "ConstEvalFreeTypeParameter",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalFreeTypeParameter(
    DartType _type, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
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
        Message Function(String stringOKEmpty, Constant _constant,
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    templateConstEvalInvalidBinaryOperandType = const Template<
            Message Function(String stringOKEmpty, Constant _constant,
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""Binary operator '#stringOKEmpty' on '#constant' requires operand of type '#type', but was of type '#type2'.""",
        withArguments: _withArgumentsConstEvalInvalidBinaryOperandType);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(String stringOKEmpty, Constant _constant,
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    codeConstEvalInvalidBinaryOperandType = const Code<
        Message Function(String stringOKEmpty, Constant _constant,
            DartType _type, DartType _type2, bool isNonNullableByDefault)>(
  "ConstEvalInvalidBinaryOperandType",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalInvalidBinaryOperandType(
    String stringOKEmpty,
    Constant _constant,
    DartType _type,
    DartType _type2,
    bool isNonNullableByDefault) {
  // ignore: unnecessary_null_comparison
  if (stringOKEmpty == null || stringOKEmpty.isEmpty) stringOKEmpty = '(empty)';
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> constantParts = labeler.labelConstant(_constant);
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String constant = constantParts.join();
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeConstEvalInvalidBinaryOperandType,
      message:
          """Binary operator '${stringOKEmpty}' on '${constant}' requires operand of type '${type}', but was of type '${type2}'.""" +
              labeler.originMessages,
      arguments: {
        'stringOKEmpty': stringOKEmpty,
        'constant': _constant,
        'type': _type,
        'type2': _type2
      });
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(
            Constant _constant, DartType _type, bool isNonNullableByDefault)>
    templateConstEvalInvalidEqualsOperandType = const Template<
            Message Function(Constant _constant, DartType _type,
                bool isNonNullableByDefault)>(
        messageTemplate:
            r"""Binary operator '==' requires receiver constant '#constant' of type 'Null', 'bool', 'int', 'double', or 'String', but was of type '#type'.""",
        withArguments: _withArgumentsConstEvalInvalidEqualsOperandType);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            Constant _constant, DartType _type, bool isNonNullableByDefault)>
    codeConstEvalInvalidEqualsOperandType = const Code<
        Message Function(
            Constant _constant, DartType _type, bool isNonNullableByDefault)>(
  "ConstEvalInvalidEqualsOperandType",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalInvalidEqualsOperandType(
    Constant _constant, DartType _type, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
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
        Message Function(String stringOKEmpty, Constant _constant,
            bool isNonNullableByDefault)>
    templateConstEvalInvalidMethodInvocation = const Template<
            Message Function(String stringOKEmpty, Constant _constant,
                bool isNonNullableByDefault)>(
        messageTemplate:
            r"""The method '#stringOKEmpty' can't be invoked on '#constant' in a constant expression.""",
        withArguments: _withArgumentsConstEvalInvalidMethodInvocation);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(String stringOKEmpty, Constant _constant,
            bool isNonNullableByDefault)> codeConstEvalInvalidMethodInvocation =
    const Code<
            Message Function(String stringOKEmpty, Constant _constant,
                bool isNonNullableByDefault)>(
        "ConstEvalInvalidMethodInvocation",
        analyzerCodes: <String>["UNDEFINED_OPERATOR"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalInvalidMethodInvocation(
    String stringOKEmpty, Constant _constant, bool isNonNullableByDefault) {
  // ignore: unnecessary_null_comparison
  if (stringOKEmpty == null || stringOKEmpty.isEmpty) stringOKEmpty = '(empty)';
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> constantParts = labeler.labelConstant(_constant);
  String constant = constantParts.join();
  return new Message(codeConstEvalInvalidMethodInvocation,
      message:
          """The method '${stringOKEmpty}' can't be invoked on '${constant}' in a constant expression.""" +
              labeler.originMessages,
      arguments: {'stringOKEmpty': stringOKEmpty, 'constant': _constant});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(String stringOKEmpty, Constant _constant,
            bool isNonNullableByDefault)> templateConstEvalInvalidPropertyGet =
    const Template<
            Message Function(String stringOKEmpty, Constant _constant,
                bool isNonNullableByDefault)>(
        messageTemplate:
            r"""The property '#stringOKEmpty' can't be accessed on '#constant' in a constant expression.""",
        withArguments: _withArgumentsConstEvalInvalidPropertyGet);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(String stringOKEmpty, Constant _constant,
            bool isNonNullableByDefault)> codeConstEvalInvalidPropertyGet =
    const Code<
            Message Function(String stringOKEmpty, Constant _constant,
                bool isNonNullableByDefault)>("ConstEvalInvalidPropertyGet",
        analyzerCodes: <String>["CONST_EVAL_THROWS_EXCEPTION"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalInvalidPropertyGet(
    String stringOKEmpty, Constant _constant, bool isNonNullableByDefault) {
  // ignore: unnecessary_null_comparison
  if (stringOKEmpty == null || stringOKEmpty.isEmpty) stringOKEmpty = '(empty)';
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> constantParts = labeler.labelConstant(_constant);
  String constant = constantParts.join();
  return new Message(codeConstEvalInvalidPropertyGet,
      message:
          """The property '${stringOKEmpty}' can't be accessed on '${constant}' in a constant expression.""" +
              labeler.originMessages,
      arguments: {'stringOKEmpty': stringOKEmpty, 'constant': _constant});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(Constant _constant, bool isNonNullableByDefault)>
    templateConstEvalInvalidStringInterpolationOperand = const Template<
            Message Function(Constant _constant, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""The constant value '#constant' can't be used as part of a string interpolation in a constant expression.
Only values of type 'null', 'bool', 'int', 'double', or 'String' can be used.""",
        withArguments:
            _withArgumentsConstEvalInvalidStringInterpolationOperand);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Constant _constant, bool isNonNullableByDefault)>
    codeConstEvalInvalidStringInterpolationOperand = const Code<
            Message Function(Constant _constant, bool isNonNullableByDefault)>(
        "ConstEvalInvalidStringInterpolationOperand",
        analyzerCodes: <String>["CONST_EVAL_TYPE_BOOL_NUM_STRING"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalInvalidStringInterpolationOperand(
    Constant _constant, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
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
        Message Function(Constant _constant, bool isNonNullableByDefault)>
    templateConstEvalInvalidSymbolName = const Template<
            Message Function(Constant _constant, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""The symbol name must be a valid public Dart member name, public constructor name, or library name, optionally qualified, but was '#constant'.""",
        withArguments: _withArgumentsConstEvalInvalidSymbolName);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Constant _constant, bool isNonNullableByDefault)>
    codeConstEvalInvalidSymbolName = const Code<
            Message Function(Constant _constant, bool isNonNullableByDefault)>(
        "ConstEvalInvalidSymbolName",
        analyzerCodes: <String>["CONST_EVAL_THROWS_EXCEPTION"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalInvalidSymbolName(
    Constant _constant, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
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
        DartType _type2,
        bool
            isNonNullableByDefault)> templateConstEvalInvalidType = const Template<
        Message Function(Constant _constant, DartType _type, DartType _type2,
            bool isNonNullableByDefault)>(
    messageTemplate:
        r"""Expected constant '#constant' to be of type '#type', but was of type '#type2'.""",
    withArguments: _withArgumentsConstEvalInvalidType);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
    Message Function(Constant _constant, DartType _type, DartType _type2,
        bool isNonNullableByDefault)> codeConstEvalInvalidType = const Code<
    Message Function(Constant _constant, DartType _type, DartType _type2,
        bool isNonNullableByDefault)>(
  "ConstEvalInvalidType",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalInvalidType(Constant _constant, DartType _type,
    DartType _type2, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
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
const Template<
        Message Function(Constant _constant, bool isNonNullableByDefault)>
    templateConstEvalKeyImplementsEqual = const Template<
            Message Function(Constant _constant, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""The key '#constant' does not have a primitive operator '=='.""",
        withArguments: _withArgumentsConstEvalKeyImplementsEqual);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Constant _constant, bool isNonNullableByDefault)>
    codeConstEvalKeyImplementsEqual = const Code<
            Message Function(Constant _constant, bool isNonNullableByDefault)>(
        "ConstEvalKeyImplementsEqual",
        analyzerCodes: <String>[
      "CONST_MAP_KEY_EXPRESSION_TYPE_IMPLEMENTS_EQUALS"
    ]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalKeyImplementsEqual(
    Constant _constant, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
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
        String name,
        bool
            isNonNullableByDefault)> templateDeferredTypeAnnotation = const Template<
        Message Function(
            DartType _type, String name, bool isNonNullableByDefault)>(
    messageTemplate:
        r"""The type '#type' is deferred loaded via prefix '#name' and can't be used as a type annotation.""",
    tipTemplate:
        r"""Try removing 'deferred' from the import of '#name' or use a supertype of '#type' that isn't deferred.""",
    withArguments: _withArgumentsDeferredTypeAnnotation);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            DartType _type, String name, bool isNonNullableByDefault)>
    codeDeferredTypeAnnotation = const Code<
            Message Function(
                DartType _type, String name, bool isNonNullableByDefault)>(
        "DeferredTypeAnnotation",
        analyzerCodes: <String>["TYPE_ANNOTATION_DEFERRED_CLASS"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDeferredTypeAnnotation(
    DartType _type, String name, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
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
const Template<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    templateFfiDartTypeMismatch = const Template<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        messageTemplate: r"""Expected '#type' to be a subtype of '#type2'.""",
        withArguments: _withArgumentsFfiDartTypeMismatch);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    codeFfiDartTypeMismatch = const Code<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>(
  "FfiDartTypeMismatch",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiDartTypeMismatch(
    DartType _type, DartType _type2, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
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
const Template<Message Function(DartType _type, bool isNonNullableByDefault)>
    templateFfiExpectedExceptionalReturn = const Template<
            Message Function(DartType _type, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""Expected an exceptional return value for a native callback returning '#type'.""",
        withArguments: _withArgumentsFfiExpectedExceptionalReturn);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, bool isNonNullableByDefault)>
    codeFfiExpectedExceptionalReturn =
    const Code<Message Function(DartType _type, bool isNonNullableByDefault)>(
  "FfiExpectedExceptionalReturn",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiExpectedExceptionalReturn(
    DartType _type, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(codeFfiExpectedExceptionalReturn,
      message:
          """Expected an exceptional return value for a native callback returning '${type}'.""" +
              labeler.originMessages,
      arguments: {'type': _type});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, bool isNonNullableByDefault)>
    templateFfiExpectedNoExceptionalReturn = const Template<
            Message Function(DartType _type, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""Exceptional return value cannot be provided for a native callback returning '#type'.""",
        withArguments: _withArgumentsFfiExpectedNoExceptionalReturn);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, bool isNonNullableByDefault)>
    codeFfiExpectedNoExceptionalReturn =
    const Code<Message Function(DartType _type, bool isNonNullableByDefault)>(
  "FfiExpectedNoExceptionalReturn",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiExpectedNoExceptionalReturn(
    DartType _type, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
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
    Message Function(
        DartType _type,
        bool
            isNonNullableByDefault)> templateFfiTypeInvalid = const Template<
        Message Function(DartType _type, bool isNonNullableByDefault)>(
    messageTemplate:
        r"""Expected type '#type' to be a valid and instantiated subtype of 'NativeType'.""",
    withArguments: _withArgumentsFfiTypeInvalid);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, bool isNonNullableByDefault)>
    codeFfiTypeInvalid =
    const Code<Message Function(DartType _type, bool isNonNullableByDefault)>(
  "FfiTypeInvalid",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiTypeInvalid(
    DartType _type, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
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
        DartType _type3,
        bool
            isNonNullableByDefault)> templateFfiTypeMismatch = const Template<
        Message Function(DartType _type, DartType _type2, DartType _type3,
            bool isNonNullableByDefault)>(
    messageTemplate:
        r"""Expected type '#type' to be '#type2', which is the Dart type corresponding to '#type3'.""",
    withArguments: _withArgumentsFfiTypeMismatch);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
    Message Function(DartType _type, DartType _type2, DartType _type3,
        bool isNonNullableByDefault)> codeFfiTypeMismatch = const Code<
    Message Function(DartType _type, DartType _type2, DartType _type3,
        bool isNonNullableByDefault)>(
  "FfiTypeMismatch",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiTypeMismatch(DartType _type, DartType _type2,
    DartType _type3, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
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
            String name, DartType _type, bool isNonNullableByDefault)>
    templateFieldNonNullableNotInitializedByConstructorError = const Template<
            Message Function(
                String name, DartType _type, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""This constructor should initialize field '#name' because its type '#type' doesn't allow null.""",
        withArguments:
            _withArgumentsFieldNonNullableNotInitializedByConstructorError);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            String name, DartType _type, bool isNonNullableByDefault)>
    codeFieldNonNullableNotInitializedByConstructorError = const Code<
        Message Function(
            String name, DartType _type, bool isNonNullableByDefault)>(
  "FieldNonNullableNotInitializedByConstructorError",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFieldNonNullableNotInitializedByConstructorError(
    String name, DartType _type, bool isNonNullableByDefault) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(codeFieldNonNullableNotInitializedByConstructorError,
      message:
          """This constructor should initialize field '${name}' because its type '${type}' doesn't allow null.""" +
              labeler.originMessages,
      arguments: {'name': name, 'type': _type});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(
            String name, DartType _type, bool isNonNullableByDefault)>
    templateFieldNonNullableWithoutInitializerError = const Template<
            Message Function(
                String name, DartType _type, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""Field '#name' should be initialized because its type '#type' doesn't allow null.""",
        withArguments: _withArgumentsFieldNonNullableWithoutInitializerError);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            String name, DartType _type, bool isNonNullableByDefault)>
    codeFieldNonNullableWithoutInitializerError = const Code<
        Message Function(
            String name, DartType _type, bool isNonNullableByDefault)>(
  "FieldNonNullableWithoutInitializerError",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFieldNonNullableWithoutInitializerError(
    String name, DartType _type, bool isNonNullableByDefault) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(codeFieldNonNullableWithoutInitializerError,
      message:
          """Field '${name}' should be initialized because its type '${type}' doesn't allow null.""" +
              labeler.originMessages,
      arguments: {'name': name, 'type': _type});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    templateForInLoopElementTypeNotAssignable = const Template<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""A value of type '#type' can't be assigned to a variable of type '#type2'.""",
        tipTemplate: r"""Try changing the type of the variable.""",
        withArguments: _withArgumentsForInLoopElementTypeNotAssignable);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    codeForInLoopElementTypeNotAssignable = const Code<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        "ForInLoopElementTypeNotAssignable",
        analyzerCodes: <String>["FOR_IN_OF_INVALID_ELEMENT_TYPE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsForInLoopElementTypeNotAssignable(
    DartType _type, DartType _type2, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
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
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    templateForInLoopElementTypeNotAssignableNullability = const Template<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""A value of type '#type' can't be assigned to a variable of type '#type2' because '#type' is nullable and '#type2' isn't.""",
        tipTemplate: r"""Try changing the type of the variable.""",
        withArguments:
            _withArgumentsForInLoopElementTypeNotAssignableNullability);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    codeForInLoopElementTypeNotAssignableNullability = const Code<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        "ForInLoopElementTypeNotAssignableNullability",
        analyzerCodes: <String>["FOR_IN_OF_INVALID_ELEMENT_TYPE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsForInLoopElementTypeNotAssignableNullability(
    DartType _type, DartType _type2, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeForInLoopElementTypeNotAssignableNullability,
      message:
          """A value of type '${type}' can't be assigned to a variable of type '${type2}' because '${type}' is nullable and '${type2}' isn't.""" +
              labeler.originMessages,
      tip: """Try changing the type of the variable.""",
      arguments: {'type': _type, 'type2': _type2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(DartType _type, DartType _type2, DartType _type3,
            DartType _type4, bool isNonNullableByDefault)>
    templateForInLoopElementTypeNotAssignablePartNullability = const Template<
            Message Function(DartType _type, DartType _type2, DartType _type3,
                DartType _type4, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""A value of type '#type' can't be assigned to a variable of type '#type2' because '#type3' is nullable and '#type4' isn't.""",
        tipTemplate: r"""Try changing the type of the variable.""",
        withArguments:
            _withArgumentsForInLoopElementTypeNotAssignablePartNullability);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(DartType _type, DartType _type2, DartType _type3,
            DartType _type4, bool isNonNullableByDefault)>
    codeForInLoopElementTypeNotAssignablePartNullability = const Code<
            Message Function(DartType _type, DartType _type2, DartType _type3,
                DartType _type4, bool isNonNullableByDefault)>(
        "ForInLoopElementTypeNotAssignablePartNullability",
        analyzerCodes: <String>["FOR_IN_OF_INVALID_ELEMENT_TYPE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsForInLoopElementTypeNotAssignablePartNullability(
    DartType _type,
    DartType _type2,
    DartType _type3,
    DartType _type4,
    bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  List<Object> type3Parts = labeler.labelType(_type3);
  List<Object> type4Parts = labeler.labelType(_type4);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  String type3 = type3Parts.join();
  String type4 = type4Parts.join();
  return new Message(codeForInLoopElementTypeNotAssignablePartNullability,
      message:
          """A value of type '${type}' can't be assigned to a variable of type '${type2}' because '${type3}' is nullable and '${type4}' isn't.""" +
              labeler.originMessages,
      tip: """Try changing the type of the variable.""",
      arguments: {
        'type': _type,
        'type2': _type2,
        'type3': _type3,
        'type4': _type4
      });
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    templateForInLoopTypeNotIterable = const Template<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""The type '#type' used in the 'for' loop must implement '#type2'.""",
        withArguments: _withArgumentsForInLoopTypeNotIterable);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    codeForInLoopTypeNotIterable = const Code<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        "ForInLoopTypeNotIterable",
        analyzerCodes: <String>["FOR_IN_OF_INVALID_TYPE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsForInLoopTypeNotIterable(
    DartType _type, DartType _type2, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
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
const Template<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    templateForInLoopTypeNotIterableNullability = const Template<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""The type '#type' used in the 'for' loop must implement '#type2' because '#type' is nullable and '#type2' isn't.""",
        withArguments: _withArgumentsForInLoopTypeNotIterableNullability);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    codeForInLoopTypeNotIterableNullability = const Code<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        "ForInLoopTypeNotIterableNullability",
        analyzerCodes: <String>["FOR_IN_OF_INVALID_TYPE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsForInLoopTypeNotIterableNullability(
    DartType _type, DartType _type2, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeForInLoopTypeNotIterableNullability,
      message:
          """The type '${type}' used in the 'for' loop must implement '${type2}' because '${type}' is nullable and '${type2}' isn't.""" +
              labeler.originMessages,
      arguments: {'type': _type, 'type2': _type2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(DartType _type, DartType _type2, DartType _type3,
            DartType _type4, bool isNonNullableByDefault)>
    templateForInLoopTypeNotIterablePartNullability = const Template<
            Message Function(DartType _type, DartType _type2, DartType _type3,
                DartType _type4, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""The type '#type' used in the 'for' loop must implement '#type2' because '#type3' is nullable and '#type4' isn't.""",
        withArguments: _withArgumentsForInLoopTypeNotIterablePartNullability);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(DartType _type, DartType _type2, DartType _type3,
            DartType _type4, bool isNonNullableByDefault)>
    codeForInLoopTypeNotIterablePartNullability = const Code<
            Message Function(DartType _type, DartType _type2, DartType _type3,
                DartType _type4, bool isNonNullableByDefault)>(
        "ForInLoopTypeNotIterablePartNullability",
        analyzerCodes: <String>["FOR_IN_OF_INVALID_TYPE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsForInLoopTypeNotIterablePartNullability(
    DartType _type,
    DartType _type2,
    DartType _type3,
    DartType _type4,
    bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  List<Object> type3Parts = labeler.labelType(_type3);
  List<Object> type4Parts = labeler.labelType(_type4);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  String type3 = type3Parts.join();
  String type4 = type4Parts.join();
  return new Message(codeForInLoopTypeNotIterablePartNullability,
      message:
          """The type '${type}' used in the 'for' loop must implement '${type2}' because '${type3}' is nullable and '${type4}' isn't.""" +
              labeler.originMessages,
      arguments: {
        'type': _type,
        'type2': _type2,
        'type3': _type3,
        'type4': _type4
      });
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, bool isNonNullableByDefault)>
    templateGenericFunctionTypeInferredAsActualTypeArgument = const Template<
            Message Function(DartType _type, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""Generic function type '#type' inferred as a type argument.""",
        tipTemplate:
            r"""Try providing a non-generic function type explicitly.""",
        withArguments:
            _withArgumentsGenericFunctionTypeInferredAsActualTypeArgument);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, bool isNonNullableByDefault)>
    codeGenericFunctionTypeInferredAsActualTypeArgument =
    const Code<Message Function(DartType _type, bool isNonNullableByDefault)>(
        "GenericFunctionTypeInferredAsActualTypeArgument",
        analyzerCodes: <String>["GENERIC_FUNCTION_CANNOT_BE_TYPE_ARGUMENT"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsGenericFunctionTypeInferredAsActualTypeArgument(
    DartType _type, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
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
const Template<Message Function(DartType _type, bool isNonNullableByDefault)>
    templateImplicitCallOfNonMethod = const Template<
            Message Function(DartType _type, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""Cannot invoke an instance of '#type' because it declares 'call' to be something other than a method.""",
        tipTemplate:
            r"""Try changing 'call' to a method or explicitly invoke 'call'.""",
        withArguments: _withArgumentsImplicitCallOfNonMethod);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, bool isNonNullableByDefault)>
    codeImplicitCallOfNonMethod =
    const Code<Message Function(DartType _type, bool isNonNullableByDefault)>(
        "ImplicitCallOfNonMethod",
        analyzerCodes: <String>["IMPLICIT_CALL_OF_NON_METHOD"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsImplicitCallOfNonMethod(
    DartType _type, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
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
        bool
            isNonNullableByDefault)> templateImplicitReturnNull = const Template<
        Message Function(DartType _type, bool isNonNullableByDefault)>(
    messageTemplate:
        r"""A non-null value must be returned since the return type '#type' doesn't allow null.""",
    withArguments: _withArgumentsImplicitReturnNull);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, bool isNonNullableByDefault)>
    codeImplicitReturnNull =
    const Code<Message Function(DartType _type, bool isNonNullableByDefault)>(
  "ImplicitReturnNull",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsImplicitReturnNull(
    DartType _type, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(codeImplicitReturnNull,
      message:
          """A non-null value must be returned since the return type '${type}' doesn't allow null.""" +
              labeler.originMessages,
      arguments: {'type': _type});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    templateIncompatibleRedirecteeFunctionType = const Template<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""The constructor function type '#type' isn't a subtype of '#type2'.""",
        withArguments: _withArgumentsIncompatibleRedirecteeFunctionType);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    codeIncompatibleRedirecteeFunctionType = const Code<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        "IncompatibleRedirecteeFunctionType",
        analyzerCodes: <String>["REDIRECT_TO_INVALID_TYPE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIncompatibleRedirecteeFunctionType(
    DartType _type, DartType _type2, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
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
        Message Function(DartType _type, DartType _type2, String name,
            String name2, bool isNonNullableByDefault)>
    templateIncorrectTypeArgument = const Template<
            Message Function(DartType _type, DartType _type2, String name,
                String name2, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""Type argument '#type' doesn't conform to the bound '#type2' of the type variable '#name' on '#name2'.""",
        tipTemplate:
            r"""Try changing type arguments so that they conform to the bounds.""",
        withArguments: _withArgumentsIncorrectTypeArgument);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(DartType _type, DartType _type2, String name,
            String name2, bool isNonNullableByDefault)>
    codeIncorrectTypeArgument = const Code<
            Message Function(
                DartType _type,
                DartType _type2,
                String name,
                String name2,
                bool isNonNullableByDefault)>("IncorrectTypeArgument",
        analyzerCodes: <String>["TYPE_ARGUMENT_NOT_MATCHING_BOUNDS"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIncorrectTypeArgument(DartType _type, DartType _type2,
    String name, String name2, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
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
        Message Function(DartType _type, DartType _type2, String name,
            String name2, bool isNonNullableByDefault)>
    templateIncorrectTypeArgumentInReturnType = const Template<
            Message Function(DartType _type, DartType _type2, String name,
                String name2, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""Type argument '#type' doesn't conform to the bound '#type2' of the type variable '#name' on '#name2' in the return type.""",
        tipTemplate:
            r"""Try changing type arguments so that they conform to the bounds.""",
        withArguments: _withArgumentsIncorrectTypeArgumentInReturnType);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(DartType _type, DartType _type2, String name,
            String name2, bool isNonNullableByDefault)>
    codeIncorrectTypeArgumentInReturnType = const Code<
            Message Function(DartType _type, DartType _type2, String name,
                String name2, bool isNonNullableByDefault)>(
        "IncorrectTypeArgumentInReturnType",
        analyzerCodes: <String>["TYPE_ARGUMENT_NOT_MATCHING_BOUNDS"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIncorrectTypeArgumentInReturnType(DartType _type,
    DartType _type2, String name, String name2, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
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
            String name4,
            bool isNonNullableByDefault)>
    templateIncorrectTypeArgumentInSupertype = const Template<
            Message Function(
                DartType _type,
                DartType _type2,
                String name,
                String name2,
                String name3,
                String name4,
                bool isNonNullableByDefault)>(
        messageTemplate:
            r"""Type argument '#type' doesn't conform to the bound '#type2' of the type variable '#name' on '#name2' in the supertype '#name3' of class '#name4'.""",
        tipTemplate:
            r"""Try changing type arguments so that they conform to the bounds.""",
        withArguments: _withArgumentsIncorrectTypeArgumentInSupertype);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            DartType _type,
            DartType _type2,
            String name,
            String name2,
            String name3,
            String name4,
            bool isNonNullableByDefault)> codeIncorrectTypeArgumentInSupertype =
    const Code<
            Message Function(
                DartType _type,
                DartType _type2,
                String name,
                String name2,
                String name3,
                String name4,
                bool isNonNullableByDefault)>(
        "IncorrectTypeArgumentInSupertype",
        analyzerCodes: <String>["TYPE_ARGUMENT_NOT_MATCHING_BOUNDS"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIncorrectTypeArgumentInSupertype(
    DartType _type,
    DartType _type2,
    String name,
    String name2,
    String name3,
    String name4,
    bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
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
            String name4,
            bool isNonNullableByDefault)>
    templateIncorrectTypeArgumentInSupertypeInferred = const Template<
            Message Function(
                DartType _type,
                DartType _type2,
                String name,
                String name2,
                String name3,
                String name4,
                bool isNonNullableByDefault)>(
        messageTemplate:
            r"""Inferred type argument '#type' doesn't conform to the bound '#type2' of the type variable '#name' on '#name2' in the supertype '#name3' of class '#name4'.""",
        tipTemplate:
            r"""Try specifying type arguments explicitly so that they conform to the bounds.""",
        withArguments: _withArgumentsIncorrectTypeArgumentInSupertypeInferred);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            DartType _type,
            DartType _type2,
            String name,
            String name2,
            String name3,
            String name4,
            bool isNonNullableByDefault)>
    codeIncorrectTypeArgumentInSupertypeInferred = const Code<
            Message Function(
                DartType _type,
                DartType _type2,
                String name,
                String name2,
                String name3,
                String name4,
                bool isNonNullableByDefault)>(
        "IncorrectTypeArgumentInSupertypeInferred",
        analyzerCodes: <String>["TYPE_ARGUMENT_NOT_MATCHING_BOUNDS"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIncorrectTypeArgumentInSupertypeInferred(
    DartType _type,
    DartType _type2,
    String name,
    String name2,
    String name3,
    String name4,
    bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
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
        Message Function(DartType _type, DartType _type2, String name,
            String name2, bool isNonNullableByDefault)>
    templateIncorrectTypeArgumentInferred = const Template<
            Message Function(DartType _type, DartType _type2, String name,
                String name2, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""Inferred type argument '#type' doesn't conform to the bound '#type2' of the type variable '#name' on '#name2'.""",
        tipTemplate:
            r"""Try specifying type arguments explicitly so that they conform to the bounds.""",
        withArguments: _withArgumentsIncorrectTypeArgumentInferred);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(DartType _type, DartType _type2, String name,
            String name2, bool isNonNullableByDefault)>
    codeIncorrectTypeArgumentInferred = const Code<
            Message Function(
                DartType _type,
                DartType _type2,
                String name,
                String name2,
                bool isNonNullableByDefault)>("IncorrectTypeArgumentInferred",
        analyzerCodes: <String>["TYPE_ARGUMENT_NOT_MATCHING_BOUNDS"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIncorrectTypeArgumentInferred(DartType _type,
    DartType _type2, String name, String name2, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
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
        Message Function(DartType _type, DartType _type2, String name,
            DartType _type3, String name2, bool isNonNullableByDefault)>
    templateIncorrectTypeArgumentQualified = const Template<
            Message Function(DartType _type, DartType _type2, String name,
                DartType _type3, String name2, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""Type argument '#type' doesn't conform to the bound '#type2' of the type variable '#name' on '#type3.#name2'.""",
        tipTemplate:
            r"""Try changing type arguments so that they conform to the bounds.""",
        withArguments: _withArgumentsIncorrectTypeArgumentQualified);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(DartType _type, DartType _type2, String name,
            DartType _type3, String name2, bool isNonNullableByDefault)>
    codeIncorrectTypeArgumentQualified = const Code<
            Message Function(
                DartType _type,
                DartType _type2,
                String name,
                DartType _type3,
                String name2,
                bool isNonNullableByDefault)>("IncorrectTypeArgumentQualified",
        analyzerCodes: <String>["TYPE_ARGUMENT_NOT_MATCHING_BOUNDS"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIncorrectTypeArgumentQualified(
    DartType _type,
    DartType _type2,
    String name,
    DartType _type3,
    String name2,
    bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
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
        Message Function(DartType _type, DartType _type2, String name,
            DartType _type3, String name2, bool isNonNullableByDefault)>
    templateIncorrectTypeArgumentQualifiedInferred = const Template<
            Message Function(DartType _type, DartType _type2, String name,
                DartType _type3, String name2, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""Inferred type argument '#type' doesn't conform to the bound '#type2' of the type variable '#name' on '#type3.#name2'.""",
        tipTemplate:
            r"""Try specifying type arguments explicitly so that they conform to the bounds.""",
        withArguments: _withArgumentsIncorrectTypeArgumentQualifiedInferred);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(DartType _type, DartType _type2, String name,
            DartType _type3, String name2, bool isNonNullableByDefault)>
    codeIncorrectTypeArgumentQualifiedInferred = const Code<
            Message Function(DartType _type, DartType _type2, String name,
                DartType _type3, String name2, bool isNonNullableByDefault)>(
        "IncorrectTypeArgumentQualifiedInferred",
        analyzerCodes: <String>["TYPE_ARGUMENT_NOT_MATCHING_BOUNDS"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIncorrectTypeArgumentQualifiedInferred(
    DartType _type,
    DartType _type2,
    String name,
    DartType _type3,
    String name2,
    bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
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
        Message Function(String name, DartType _type, DartType _type2,
            bool isNonNullableByDefault)>
    templateInitializingFormalTypeMismatch = const Template<
            Message Function(String name, DartType _type, DartType _type2,
                bool isNonNullableByDefault)>(
        messageTemplate:
            r"""The type of parameter '#name', '#type' is not a subtype of the corresponding field's type, '#type2'.""",
        tipTemplate:
            r"""Try changing the type of parameter '#name' to a subtype of '#type2'.""",
        withArguments: _withArgumentsInitializingFormalTypeMismatch);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(String name, DartType _type, DartType _type2,
            bool isNonNullableByDefault)> codeInitializingFormalTypeMismatch =
    const Code<
            Message Function(String name, DartType _type, DartType _type2,
                bool isNonNullableByDefault)>("InitializingFormalTypeMismatch",
        analyzerCodes: <String>["INVALID_PARAMETER_DECLARATION"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInitializingFormalTypeMismatch(
    String name, DartType _type, DartType _type2, bool isNonNullableByDefault) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
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
            String string, DartType _type, bool isNonNullableByDefault)>
    templateInternalProblemUnsupportedNullability = const Template<
            Message Function(
                String string, DartType _type, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""Unsupported nullability value '#string' on type '#type'.""",
        withArguments: _withArgumentsInternalProblemUnsupportedNullability);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            String string, DartType _type, bool isNonNullableByDefault)>
    codeInternalProblemUnsupportedNullability = const Code<
            Message Function(
                String string, DartType _type, bool isNonNullableByDefault)>(
        "InternalProblemUnsupportedNullability",
        severity: Severity.internalProblem);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemUnsupportedNullability(
    String string, DartType _type, bool isNonNullableByDefault) {
  if (string.isEmpty) throw 'No string provided';
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(codeInternalProblemUnsupportedNullability,
      message:
          """Unsupported nullability value '${string}' on type '${type}'.""" +
              labeler.originMessages,
      arguments: {'string': string, 'type': _type});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    templateInvalidAssignmentError = const Template<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""A value of type '#type' can't be assigned to a variable of type '#type2'.""",
        withArguments: _withArgumentsInvalidAssignmentError);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    codeInvalidAssignmentError = const Code<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        "InvalidAssignmentError",
        analyzerCodes: <String>["INVALID_ASSIGNMENT"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidAssignmentError(
    DartType _type, DartType _type2, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeInvalidAssignmentError,
      message:
          """A value of type '${type}' can't be assigned to a variable of type '${type2}'.""" +
              labeler.originMessages,
      arguments: {'type': _type, 'type2': _type2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    templateInvalidAssignmentErrorNullability = const Template<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""A value of type '#type' can't be assigned to a variable of type '#type2' because '#type' is nullable and '#type2' isn't.""",
        withArguments: _withArgumentsInvalidAssignmentErrorNullability);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    codeInvalidAssignmentErrorNullability = const Code<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        "InvalidAssignmentErrorNullability",
        analyzerCodes: <String>["INVALID_ASSIGNMENT"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidAssignmentErrorNullability(
    DartType _type, DartType _type2, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeInvalidAssignmentErrorNullability,
      message:
          """A value of type '${type}' can't be assigned to a variable of type '${type2}' because '${type}' is nullable and '${type2}' isn't.""" +
              labeler.originMessages,
      arguments: {'type': _type, 'type2': _type2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, bool isNonNullableByDefault)>
    templateInvalidAssignmentErrorNullabilityNull = const Template<
            Message Function(DartType _type, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""The value 'null' can't be assigned to a variable of type '#type' because '#type' is not nullable.""",
        withArguments: _withArgumentsInvalidAssignmentErrorNullabilityNull);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, bool isNonNullableByDefault)>
    codeInvalidAssignmentErrorNullabilityNull =
    const Code<Message Function(DartType _type, bool isNonNullableByDefault)>(
        "InvalidAssignmentErrorNullabilityNull",
        analyzerCodes: <String>["INVALID_ASSIGNMENT"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidAssignmentErrorNullabilityNull(
    DartType _type, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(codeInvalidAssignmentErrorNullabilityNull,
      message:
          """The value 'null' can't be assigned to a variable of type '${type}' because '${type}' is not nullable.""" +
              labeler.originMessages,
      arguments: {'type': _type});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    templateInvalidAssignmentErrorNullabilityNullType = const Template<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""A value of type '#type' can't be assigned to a variable of type '#type2' because '#type2' is not nullable.""",
        withArguments: _withArgumentsInvalidAssignmentErrorNullabilityNullType);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    codeInvalidAssignmentErrorNullabilityNullType = const Code<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        "InvalidAssignmentErrorNullabilityNullType",
        analyzerCodes: <String>["INVALID_ASSIGNMENT"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidAssignmentErrorNullabilityNullType(
    DartType _type, DartType _type2, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeInvalidAssignmentErrorNullabilityNullType,
      message:
          """A value of type '${type}' can't be assigned to a variable of type '${type2}' because '${type2}' is not nullable.""" +
              labeler.originMessages,
      arguments: {'type': _type, 'type2': _type2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(DartType _type, DartType _type2, DartType _type3,
            DartType _type4, bool isNonNullableByDefault)>
    templateInvalidAssignmentErrorPartNullability = const Template<
            Message Function(DartType _type, DartType _type2, DartType _type3,
                DartType _type4, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""A value of type '#type' can't be assigned to a variable of type '#type2' because '#type3' is nullable and '#type4' isn't.""",
        withArguments: _withArgumentsInvalidAssignmentErrorPartNullability);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(DartType _type, DartType _type2, DartType _type3,
            DartType _type4, bool isNonNullableByDefault)>
    codeInvalidAssignmentErrorPartNullability = const Code<
            Message Function(DartType _type, DartType _type2, DartType _type3,
                DartType _type4, bool isNonNullableByDefault)>(
        "InvalidAssignmentErrorPartNullability",
        analyzerCodes: <String>["INVALID_ASSIGNMENT"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidAssignmentErrorPartNullability(
    DartType _type,
    DartType _type2,
    DartType _type3,
    DartType _type4,
    bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  List<Object> type3Parts = labeler.labelType(_type3);
  List<Object> type4Parts = labeler.labelType(_type4);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  String type3 = type3Parts.join();
  String type4 = type4Parts.join();
  return new Message(codeInvalidAssignmentErrorPartNullability,
      message:
          """A value of type '${type}' can't be assigned to a variable of type '${type2}' because '${type3}' is nullable and '${type4}' isn't.""" +
              labeler.originMessages,
      arguments: {
        'type': _type,
        'type2': _type2,
        'type3': _type3,
        'type4': _type4
      });
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        DartType _type,
        DartType _type2,
        bool
            isNonNullableByDefault)> templateInvalidCastFunctionExpr = const Template<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>(
    messageTemplate:
        r"""The function expression type '#type' isn't of expected type '#type2'.""",
    tipTemplate:
        r"""Change the type of the function expression or the context in which it is used.""",
    withArguments: _withArgumentsInvalidCastFunctionExpr);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    codeInvalidCastFunctionExpr = const Code<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        "InvalidCastFunctionExpr",
        analyzerCodes: <String>["INVALID_CAST_FUNCTION_EXPR"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidCastFunctionExpr(
    DartType _type, DartType _type2, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
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
        DartType _type2,
        bool
            isNonNullableByDefault)> templateInvalidCastLiteralList = const Template<
        Message Function(
            DartType _type,
            DartType _type2,
            bool
                isNonNullableByDefault)>(
    messageTemplate:
        r"""The list literal type '#type' isn't of expected type '#type2'.""",
    tipTemplate:
        r"""Change the type of the list literal or the context in which it is used.""",
    withArguments: _withArgumentsInvalidCastLiteralList);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    codeInvalidCastLiteralList = const Code<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        "InvalidCastLiteralList",
        analyzerCodes: <String>["INVALID_CAST_LITERAL_LIST"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidCastLiteralList(
    DartType _type, DartType _type2, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
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
        DartType _type2,
        bool
            isNonNullableByDefault)> templateInvalidCastLiteralMap = const Template<
        Message Function(
            DartType _type,
            DartType _type2,
            bool
                isNonNullableByDefault)>(
    messageTemplate:
        r"""The map literal type '#type' isn't of expected type '#type2'.""",
    tipTemplate:
        r"""Change the type of the map literal or the context in which it is used.""",
    withArguments: _withArgumentsInvalidCastLiteralMap);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    codeInvalidCastLiteralMap = const Code<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        "InvalidCastLiteralMap",
        analyzerCodes: <String>["INVALID_CAST_LITERAL_MAP"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidCastLiteralMap(
    DartType _type, DartType _type2, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
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
        DartType _type2,
        bool
            isNonNullableByDefault)> templateInvalidCastLiteralSet = const Template<
        Message Function(
            DartType _type,
            DartType _type2,
            bool
                isNonNullableByDefault)>(
    messageTemplate:
        r"""The set literal type '#type' isn't of expected type '#type2'.""",
    tipTemplate:
        r"""Change the type of the set literal or the context in which it is used.""",
    withArguments: _withArgumentsInvalidCastLiteralSet);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    codeInvalidCastLiteralSet = const Code<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        "InvalidCastLiteralSet",
        analyzerCodes: <String>["INVALID_CAST_LITERAL_SET"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidCastLiteralSet(
    DartType _type, DartType _type2, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
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
        DartType _type2,
        bool
            isNonNullableByDefault)> templateInvalidCastLocalFunction = const Template<
        Message Function(
            DartType _type,
            DartType _type2,
            bool
                isNonNullableByDefault)>(
    messageTemplate:
        r"""The local function has type '#type' that isn't of expected type '#type2'.""",
    tipTemplate:
        r"""Change the type of the function or the context in which it is used.""",
    withArguments: _withArgumentsInvalidCastLocalFunction);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    codeInvalidCastLocalFunction = const Code<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        "InvalidCastLocalFunction",
        analyzerCodes: <String>["INVALID_CAST_FUNCTION"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidCastLocalFunction(
    DartType _type, DartType _type2, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
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
        DartType _type2,
        bool
            isNonNullableByDefault)> templateInvalidCastNewExpr = const Template<
        Message Function(
            DartType _type,
            DartType _type2,
            bool
                isNonNullableByDefault)>(
    messageTemplate:
        r"""The constructor returns type '#type' that isn't of expected type '#type2'.""",
    tipTemplate:
        r"""Change the type of the object being constructed or the context in which it is used.""",
    withArguments: _withArgumentsInvalidCastNewExpr);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    codeInvalidCastNewExpr = const Code<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        "InvalidCastNewExpr",
        analyzerCodes: <String>["INVALID_CAST_NEW_EXPR"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidCastNewExpr(
    DartType _type, DartType _type2, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
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
        DartType _type2,
        bool
            isNonNullableByDefault)> templateInvalidCastStaticMethod = const Template<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>(
    messageTemplate:
        r"""The static method has type '#type' that isn't of expected type '#type2'.""",
    tipTemplate:
        r"""Change the type of the method or the context in which it is used.""",
    withArguments: _withArgumentsInvalidCastStaticMethod);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    codeInvalidCastStaticMethod = const Code<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        "InvalidCastStaticMethod",
        analyzerCodes: <String>["INVALID_CAST_METHOD"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidCastStaticMethod(
    DartType _type, DartType _type2, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
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
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    templateInvalidCastTopLevelFunction = const Template<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""The top level function has type '#type' that isn't of expected type '#type2'.""",
        tipTemplate:
            r"""Change the type of the function or the context in which it is used.""",
        withArguments: _withArgumentsInvalidCastTopLevelFunction);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    codeInvalidCastTopLevelFunction = const Code<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        "InvalidCastTopLevelFunction",
        analyzerCodes: <String>["INVALID_CAST_FUNCTION"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidCastTopLevelFunction(
    DartType _type, DartType _type2, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
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
        Message Function(DartType _type, String name, DartType _type2,
            String name2, bool isNonNullableByDefault)>
    templateInvalidGetterSetterType = const Template<
            Message Function(DartType _type, String name, DartType _type2,
                String name2, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""The type '#type' of the getter '#name' is not a subtype of the type '#type2' of the setter '#name2'.""",
        withArguments: _withArgumentsInvalidGetterSetterType);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
    Message Function(DartType _type, String name, DartType _type2, String name2,
        bool isNonNullableByDefault)> codeInvalidGetterSetterType = const Code<
    Message Function(DartType _type, String name, DartType _type2, String name2,
        bool isNonNullableByDefault)>(
  "InvalidGetterSetterType",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidGetterSetterType(DartType _type, String name,
    DartType _type2, String name2, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  List<Object> type2Parts = labeler.labelType(_type2);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeInvalidGetterSetterType,
      message:
          """The type '${type}' of the getter '${name}' is not a subtype of the type '${type2}' of the setter '${name2}'.""" +
              labeler.originMessages,
      arguments: {
        'type': _type,
        'name': name,
        'type2': _type2,
        'name2': name2
      });
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(DartType _type, String name, DartType _type2,
            String name2, bool isNonNullableByDefault)>
    templateInvalidGetterSetterTypeBothInheritedField = const Template<
            Message Function(DartType _type, String name, DartType _type2,
                String name2, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""The type '#type' of the inherited field '#name' is not a subtype of the type '#type2' of the inherited setter '#name2'.""",
        withArguments: _withArgumentsInvalidGetterSetterTypeBothInheritedField);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(DartType _type, String name, DartType _type2,
            String name2, bool isNonNullableByDefault)>
    codeInvalidGetterSetterTypeBothInheritedField = const Code<
        Message Function(DartType _type, String name, DartType _type2,
            String name2, bool isNonNullableByDefault)>(
  "InvalidGetterSetterTypeBothInheritedField",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidGetterSetterTypeBothInheritedField(DartType _type,
    String name, DartType _type2, String name2, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  List<Object> type2Parts = labeler.labelType(_type2);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeInvalidGetterSetterTypeBothInheritedField,
      message:
          """The type '${type}' of the inherited field '${name}' is not a subtype of the type '${type2}' of the inherited setter '${name2}'.""" +
              labeler.originMessages,
      arguments: {
        'type': _type,
        'name': name,
        'type2': _type2,
        'name2': name2
      });
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(DartType _type, String name, DartType _type2,
            String name2, bool isNonNullableByDefault)>
    templateInvalidGetterSetterTypeBothInheritedFieldLegacy = const Template<
            Message Function(DartType _type, String name, DartType _type2,
                String name2, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""The type '#type' of the inherited field '#name' is not assignable to the type '#type2' of the inherited setter '#name2'.""",
        withArguments:
            _withArgumentsInvalidGetterSetterTypeBothInheritedFieldLegacy);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(DartType _type, String name, DartType _type2,
            String name2, bool isNonNullableByDefault)>
    codeInvalidGetterSetterTypeBothInheritedFieldLegacy = const Code<
        Message Function(DartType _type, String name, DartType _type2,
            String name2, bool isNonNullableByDefault)>(
  "InvalidGetterSetterTypeBothInheritedFieldLegacy",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidGetterSetterTypeBothInheritedFieldLegacy(
    DartType _type,
    String name,
    DartType _type2,
    String name2,
    bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  List<Object> type2Parts = labeler.labelType(_type2);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeInvalidGetterSetterTypeBothInheritedFieldLegacy,
      message:
          """The type '${type}' of the inherited field '${name}' is not assignable to the type '${type2}' of the inherited setter '${name2}'.""" +
              labeler.originMessages,
      arguments: {
        'type': _type,
        'name': name,
        'type2': _type2,
        'name2': name2
      });
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(DartType _type, String name, DartType _type2,
            String name2, bool isNonNullableByDefault)>
    templateInvalidGetterSetterTypeBothInheritedGetter = const Template<
            Message Function(DartType _type, String name, DartType _type2,
                String name2, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""The type '#type' of the inherited getter '#name' is not a subtype of the type '#type2' of the inherited setter '#name2'.""",
        withArguments:
            _withArgumentsInvalidGetterSetterTypeBothInheritedGetter);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(DartType _type, String name, DartType _type2,
            String name2, bool isNonNullableByDefault)>
    codeInvalidGetterSetterTypeBothInheritedGetter = const Code<
        Message Function(DartType _type, String name, DartType _type2,
            String name2, bool isNonNullableByDefault)>(
  "InvalidGetterSetterTypeBothInheritedGetter",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidGetterSetterTypeBothInheritedGetter(DartType _type,
    String name, DartType _type2, String name2, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  List<Object> type2Parts = labeler.labelType(_type2);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeInvalidGetterSetterTypeBothInheritedGetter,
      message:
          """The type '${type}' of the inherited getter '${name}' is not a subtype of the type '${type2}' of the inherited setter '${name2}'.""" +
              labeler.originMessages,
      arguments: {
        'type': _type,
        'name': name,
        'type2': _type2,
        'name2': name2
      });
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(DartType _type, String name, DartType _type2,
            String name2, bool isNonNullableByDefault)>
    templateInvalidGetterSetterTypeBothInheritedGetterLegacy = const Template<
            Message Function(DartType _type, String name, DartType _type2,
                String name2, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""The type '#type' of the inherited getter '#name' is not assignable to the type '#type2' of the inherited setter '#name2'.""",
        withArguments:
            _withArgumentsInvalidGetterSetterTypeBothInheritedGetterLegacy);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(DartType _type, String name, DartType _type2,
            String name2, bool isNonNullableByDefault)>
    codeInvalidGetterSetterTypeBothInheritedGetterLegacy = const Code<
        Message Function(DartType _type, String name, DartType _type2,
            String name2, bool isNonNullableByDefault)>(
  "InvalidGetterSetterTypeBothInheritedGetterLegacy",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidGetterSetterTypeBothInheritedGetterLegacy(
    DartType _type,
    String name,
    DartType _type2,
    String name2,
    bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  List<Object> type2Parts = labeler.labelType(_type2);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeInvalidGetterSetterTypeBothInheritedGetterLegacy,
      message:
          """The type '${type}' of the inherited getter '${name}' is not assignable to the type '${type2}' of the inherited setter '${name2}'.""" +
              labeler.originMessages,
      arguments: {
        'type': _type,
        'name': name,
        'type2': _type2,
        'name2': name2
      });
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(DartType _type, String name, DartType _type2,
            String name2, bool isNonNullableByDefault)>
    templateInvalidGetterSetterTypeFieldInherited = const Template<
            Message Function(DartType _type, String name, DartType _type2,
                String name2, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""The type '#type' of the inherited field '#name' is not a subtype of the type '#type2' of the setter '#name2'.""",
        withArguments: _withArgumentsInvalidGetterSetterTypeFieldInherited);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(DartType _type, String name, DartType _type2,
            String name2, bool isNonNullableByDefault)>
    codeInvalidGetterSetterTypeFieldInherited = const Code<
        Message Function(DartType _type, String name, DartType _type2,
            String name2, bool isNonNullableByDefault)>(
  "InvalidGetterSetterTypeFieldInherited",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidGetterSetterTypeFieldInherited(DartType _type,
    String name, DartType _type2, String name2, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  List<Object> type2Parts = labeler.labelType(_type2);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeInvalidGetterSetterTypeFieldInherited,
      message:
          """The type '${type}' of the inherited field '${name}' is not a subtype of the type '${type2}' of the setter '${name2}'.""" +
              labeler.originMessages,
      arguments: {
        'type': _type,
        'name': name,
        'type2': _type2,
        'name2': name2
      });
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(DartType _type, String name, DartType _type2,
            String name2, bool isNonNullableByDefault)>
    templateInvalidGetterSetterTypeFieldInheritedLegacy = const Template<
            Message Function(DartType _type, String name, DartType _type2,
                String name2, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""The type '#type' of the inherited field '#name' is not assignable to the type '#type2' of the setter '#name2'.""",
        withArguments:
            _withArgumentsInvalidGetterSetterTypeFieldInheritedLegacy);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(DartType _type, String name, DartType _type2,
            String name2, bool isNonNullableByDefault)>
    codeInvalidGetterSetterTypeFieldInheritedLegacy = const Code<
        Message Function(DartType _type, String name, DartType _type2,
            String name2, bool isNonNullableByDefault)>(
  "InvalidGetterSetterTypeFieldInheritedLegacy",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidGetterSetterTypeFieldInheritedLegacy(
    DartType _type,
    String name,
    DartType _type2,
    String name2,
    bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  List<Object> type2Parts = labeler.labelType(_type2);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeInvalidGetterSetterTypeFieldInheritedLegacy,
      message:
          """The type '${type}' of the inherited field '${name}' is not assignable to the type '${type2}' of the setter '${name2}'.""" +
              labeler.originMessages,
      arguments: {
        'type': _type,
        'name': name,
        'type2': _type2,
        'name2': name2
      });
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(DartType _type, String name, DartType _type2,
            String name2, bool isNonNullableByDefault)>
    templateInvalidGetterSetterTypeGetterInherited = const Template<
            Message Function(DartType _type, String name, DartType _type2,
                String name2, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""The type '#type' of the inherited getter '#name' is not a subtype of the type '#type2' of the setter '#name2'.""",
        withArguments: _withArgumentsInvalidGetterSetterTypeGetterInherited);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(DartType _type, String name, DartType _type2,
            String name2, bool isNonNullableByDefault)>
    codeInvalidGetterSetterTypeGetterInherited = const Code<
        Message Function(DartType _type, String name, DartType _type2,
            String name2, bool isNonNullableByDefault)>(
  "InvalidGetterSetterTypeGetterInherited",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidGetterSetterTypeGetterInherited(DartType _type,
    String name, DartType _type2, String name2, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  List<Object> type2Parts = labeler.labelType(_type2);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeInvalidGetterSetterTypeGetterInherited,
      message:
          """The type '${type}' of the inherited getter '${name}' is not a subtype of the type '${type2}' of the setter '${name2}'.""" +
              labeler.originMessages,
      arguments: {
        'type': _type,
        'name': name,
        'type2': _type2,
        'name2': name2
      });
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(DartType _type, String name, DartType _type2,
            String name2, bool isNonNullableByDefault)>
    templateInvalidGetterSetterTypeGetterInheritedLegacy = const Template<
            Message Function(DartType _type, String name, DartType _type2,
                String name2, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""The type '#type' of the inherited getter '#name' is not assignable to the type '#type2' of the setter '#name2'.""",
        withArguments:
            _withArgumentsInvalidGetterSetterTypeGetterInheritedLegacy);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(DartType _type, String name, DartType _type2,
            String name2, bool isNonNullableByDefault)>
    codeInvalidGetterSetterTypeGetterInheritedLegacy = const Code<
        Message Function(DartType _type, String name, DartType _type2,
            String name2, bool isNonNullableByDefault)>(
  "InvalidGetterSetterTypeGetterInheritedLegacy",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidGetterSetterTypeGetterInheritedLegacy(
    DartType _type,
    String name,
    DartType _type2,
    String name2,
    bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  List<Object> type2Parts = labeler.labelType(_type2);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeInvalidGetterSetterTypeGetterInheritedLegacy,
      message:
          """The type '${type}' of the inherited getter '${name}' is not assignable to the type '${type2}' of the setter '${name2}'.""" +
              labeler.originMessages,
      arguments: {
        'type': _type,
        'name': name,
        'type2': _type2,
        'name2': name2
      });
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(DartType _type, String name, DartType _type2,
            String name2, bool isNonNullableByDefault)>
    templateInvalidGetterSetterTypeLegacy = const Template<
            Message Function(DartType _type, String name, DartType _type2,
                String name2, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""The type '#type' of the getter '#name' is not assignable to the type '#type2' of the setter '#name2'.""",
        withArguments: _withArgumentsInvalidGetterSetterTypeLegacy);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(DartType _type, String name, DartType _type2,
            String name2, bool isNonNullableByDefault)>
    codeInvalidGetterSetterTypeLegacy = const Code<
        Message Function(DartType _type, String name, DartType _type2,
            String name2, bool isNonNullableByDefault)>(
  "InvalidGetterSetterTypeLegacy",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidGetterSetterTypeLegacy(DartType _type, String name,
    DartType _type2, String name2, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  List<Object> type2Parts = labeler.labelType(_type2);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeInvalidGetterSetterTypeLegacy,
      message:
          """The type '${type}' of the getter '${name}' is not assignable to the type '${type2}' of the setter '${name2}'.""" +
              labeler.originMessages,
      arguments: {
        'type': _type,
        'name': name,
        'type2': _type2,
        'name2': name2
      });
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(DartType _type, String name, DartType _type2,
            String name2, bool isNonNullableByDefault)>
    templateInvalidGetterSetterTypeSetterInheritedField = const Template<
            Message Function(DartType _type, String name, DartType _type2,
                String name2, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""The type '#type' of the field '#name' is not a subtype of the type '#type2' of the inherited setter '#name2'.""",
        withArguments:
            _withArgumentsInvalidGetterSetterTypeSetterInheritedField);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(DartType _type, String name, DartType _type2,
            String name2, bool isNonNullableByDefault)>
    codeInvalidGetterSetterTypeSetterInheritedField = const Code<
        Message Function(DartType _type, String name, DartType _type2,
            String name2, bool isNonNullableByDefault)>(
  "InvalidGetterSetterTypeSetterInheritedField",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidGetterSetterTypeSetterInheritedField(
    DartType _type,
    String name,
    DartType _type2,
    String name2,
    bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  List<Object> type2Parts = labeler.labelType(_type2);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeInvalidGetterSetterTypeSetterInheritedField,
      message:
          """The type '${type}' of the field '${name}' is not a subtype of the type '${type2}' of the inherited setter '${name2}'.""" +
              labeler.originMessages,
      arguments: {
        'type': _type,
        'name': name,
        'type2': _type2,
        'name2': name2
      });
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(DartType _type, String name, DartType _type2,
            String name2, bool isNonNullableByDefault)>
    templateInvalidGetterSetterTypeSetterInheritedFieldLegacy = const Template<
            Message Function(DartType _type, String name, DartType _type2,
                String name2, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""The type '#type' of the field '#name' is not assignable to the type '#type2' of the inherited setter '#name2'.""",
        withArguments:
            _withArgumentsInvalidGetterSetterTypeSetterInheritedFieldLegacy);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(DartType _type, String name, DartType _type2,
            String name2, bool isNonNullableByDefault)>
    codeInvalidGetterSetterTypeSetterInheritedFieldLegacy = const Code<
        Message Function(DartType _type, String name, DartType _type2,
            String name2, bool isNonNullableByDefault)>(
  "InvalidGetterSetterTypeSetterInheritedFieldLegacy",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidGetterSetterTypeSetterInheritedFieldLegacy(
    DartType _type,
    String name,
    DartType _type2,
    String name2,
    bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  List<Object> type2Parts = labeler.labelType(_type2);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeInvalidGetterSetterTypeSetterInheritedFieldLegacy,
      message:
          """The type '${type}' of the field '${name}' is not assignable to the type '${type2}' of the inherited setter '${name2}'.""" +
              labeler.originMessages,
      arguments: {
        'type': _type,
        'name': name,
        'type2': _type2,
        'name2': name2
      });
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(DartType _type, String name, DartType _type2,
            String name2, bool isNonNullableByDefault)>
    templateInvalidGetterSetterTypeSetterInheritedGetter = const Template<
            Message Function(DartType _type, String name, DartType _type2,
                String name2, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""The type '#type' of the getter '#name' is not a subtype of the type '#type2' of the inherited setter '#name2'.""",
        withArguments:
            _withArgumentsInvalidGetterSetterTypeSetterInheritedGetter);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(DartType _type, String name, DartType _type2,
            String name2, bool isNonNullableByDefault)>
    codeInvalidGetterSetterTypeSetterInheritedGetter = const Code<
        Message Function(DartType _type, String name, DartType _type2,
            String name2, bool isNonNullableByDefault)>(
  "InvalidGetterSetterTypeSetterInheritedGetter",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidGetterSetterTypeSetterInheritedGetter(
    DartType _type,
    String name,
    DartType _type2,
    String name2,
    bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  List<Object> type2Parts = labeler.labelType(_type2);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeInvalidGetterSetterTypeSetterInheritedGetter,
      message:
          """The type '${type}' of the getter '${name}' is not a subtype of the type '${type2}' of the inherited setter '${name2}'.""" +
              labeler.originMessages,
      arguments: {
        'type': _type,
        'name': name,
        'type2': _type2,
        'name2': name2
      });
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(DartType _type, String name, DartType _type2,
            String name2, bool isNonNullableByDefault)>
    templateInvalidGetterSetterTypeSetterInheritedGetterLegacy = const Template<
            Message Function(DartType _type, String name, DartType _type2,
                String name2, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""The type '#type' of the getter '#name' is not assignable to the type '#type2' of the inherited setter '#name2'.""",
        withArguments:
            _withArgumentsInvalidGetterSetterTypeSetterInheritedGetterLegacy);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(DartType _type, String name, DartType _type2,
            String name2, bool isNonNullableByDefault)>
    codeInvalidGetterSetterTypeSetterInheritedGetterLegacy = const Code<
        Message Function(DartType _type, String name, DartType _type2,
            String name2, bool isNonNullableByDefault)>(
  "InvalidGetterSetterTypeSetterInheritedGetterLegacy",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidGetterSetterTypeSetterInheritedGetterLegacy(
    DartType _type,
    String name,
    DartType _type2,
    String name2,
    bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  List<Object> type2Parts = labeler.labelType(_type2);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeInvalidGetterSetterTypeSetterInheritedGetterLegacy,
      message:
          """The type '${type}' of the getter '${name}' is not assignable to the type '${type2}' of the inherited setter '${name2}'.""" +
              labeler.originMessages,
      arguments: {
        'type': _type,
        'name': name,
        'type2': _type2,
        'name2': name2
      });
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        DartType _type,
        DartType _type2,
        bool
            isNonNullableByDefault)> templateInvalidReturn = const Template<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>(
    messageTemplate:
        r"""A value of type '#type' can't be returned from a function with return type '#type2'.""",
    withArguments: _withArgumentsInvalidReturn);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    codeInvalidReturn = const Code<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>(
  "InvalidReturn",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidReturn(
    DartType _type, DartType _type2, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeInvalidReturn,
      message:
          """A value of type '${type}' can't be returned from a function with return type '${type2}'.""" +
              labeler.originMessages,
      arguments: {'type': _type, 'type2': _type2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        DartType _type,
        DartType _type2,
        bool
            isNonNullableByDefault)> templateInvalidReturnAsync = const Template<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>(
    messageTemplate:
        r"""A value of type '#type' can't be returned from an async function with return type '#type2'.""",
    withArguments: _withArgumentsInvalidReturnAsync);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    codeInvalidReturnAsync = const Code<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>(
  "InvalidReturnAsync",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidReturnAsync(
    DartType _type, DartType _type2, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeInvalidReturnAsync,
      message:
          """A value of type '${type}' can't be returned from an async function with return type '${type2}'.""" +
              labeler.originMessages,
      arguments: {'type': _type, 'type2': _type2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    templateInvalidReturnAsyncNullability = const Template<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""A value of type '#type' can't be returned from an async function with return type '#type2' because '#type' is nullable and '#type2' isn't.""",
        withArguments: _withArgumentsInvalidReturnAsyncNullability);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    codeInvalidReturnAsyncNullability = const Code<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>(
  "InvalidReturnAsyncNullability",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidReturnAsyncNullability(
    DartType _type, DartType _type2, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeInvalidReturnAsyncNullability,
      message:
          """A value of type '${type}' can't be returned from an async function with return type '${type2}' because '${type}' is nullable and '${type2}' isn't.""" +
              labeler.originMessages,
      arguments: {'type': _type, 'type2': _type2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, bool isNonNullableByDefault)>
    templateInvalidReturnAsyncNullabilityNull = const Template<
            Message Function(DartType _type, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""The value 'null' can't be returned from an async function with return type '#type' because '#type' is not nullable.""",
        withArguments: _withArgumentsInvalidReturnAsyncNullabilityNull);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, bool isNonNullableByDefault)>
    codeInvalidReturnAsyncNullabilityNull =
    const Code<Message Function(DartType _type, bool isNonNullableByDefault)>(
  "InvalidReturnAsyncNullabilityNull",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidReturnAsyncNullabilityNull(
    DartType _type, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(codeInvalidReturnAsyncNullabilityNull,
      message:
          """The value 'null' can't be returned from an async function with return type '${type}' because '${type}' is not nullable.""" +
              labeler.originMessages,
      arguments: {'type': _type});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    templateInvalidReturnAsyncNullabilityNullType = const Template<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""A value of type '#type' can't be returned from an async function with return type '#type2' because '#type2' is not nullable.""",
        withArguments: _withArgumentsInvalidReturnAsyncNullabilityNullType);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    codeInvalidReturnAsyncNullabilityNullType = const Code<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>(
  "InvalidReturnAsyncNullabilityNullType",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidReturnAsyncNullabilityNullType(
    DartType _type, DartType _type2, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeInvalidReturnAsyncNullabilityNullType,
      message:
          """A value of type '${type}' can't be returned from an async function with return type '${type2}' because '${type2}' is not nullable.""" +
              labeler.originMessages,
      arguments: {'type': _type, 'type2': _type2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(DartType _type, DartType _type2, DartType _type3,
            DartType _type4, bool isNonNullableByDefault)>
    templateInvalidReturnAsyncPartNullability = const Template<
            Message Function(DartType _type, DartType _type2, DartType _type3,
                DartType _type4, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""A value of type '#type' can't be returned from an async function with return type '#type2' because '#type3' is nullable and '#type4' isn't.""",
        withArguments: _withArgumentsInvalidReturnAsyncPartNullability);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(DartType _type, DartType _type2, DartType _type3,
            DartType _type4, bool isNonNullableByDefault)>
    codeInvalidReturnAsyncPartNullability = const Code<
        Message Function(DartType _type, DartType _type2, DartType _type3,
            DartType _type4, bool isNonNullableByDefault)>(
  "InvalidReturnAsyncPartNullability",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidReturnAsyncPartNullability(
    DartType _type,
    DartType _type2,
    DartType _type3,
    DartType _type4,
    bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  List<Object> type3Parts = labeler.labelType(_type3);
  List<Object> type4Parts = labeler.labelType(_type4);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  String type3 = type3Parts.join();
  String type4 = type4Parts.join();
  return new Message(codeInvalidReturnAsyncPartNullability,
      message:
          """A value of type '${type}' can't be returned from an async function with return type '${type2}' because '${type3}' is nullable and '${type4}' isn't.""" +
              labeler.originMessages,
      arguments: {
        'type': _type,
        'type2': _type2,
        'type3': _type3,
        'type4': _type4
      });
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    templateInvalidReturnNullability = const Template<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""A value of type '#type' can't be returned from a function with return type '#type2' because '#type' is nullable and '#type2' isn't.""",
        withArguments: _withArgumentsInvalidReturnNullability);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    codeInvalidReturnNullability = const Code<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>(
  "InvalidReturnNullability",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidReturnNullability(
    DartType _type, DartType _type2, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeInvalidReturnNullability,
      message:
          """A value of type '${type}' can't be returned from a function with return type '${type2}' because '${type}' is nullable and '${type2}' isn't.""" +
              labeler.originMessages,
      arguments: {'type': _type, 'type2': _type2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, bool isNonNullableByDefault)>
    templateInvalidReturnNullabilityNull = const Template<
            Message Function(DartType _type, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""The value 'null' can't be returned from a function with return type '#type' because '#type' is not nullable.""",
        withArguments: _withArgumentsInvalidReturnNullabilityNull);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, bool isNonNullableByDefault)>
    codeInvalidReturnNullabilityNull =
    const Code<Message Function(DartType _type, bool isNonNullableByDefault)>(
  "InvalidReturnNullabilityNull",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidReturnNullabilityNull(
    DartType _type, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(codeInvalidReturnNullabilityNull,
      message:
          """The value 'null' can't be returned from a function with return type '${type}' because '${type}' is not nullable.""" +
              labeler.originMessages,
      arguments: {'type': _type});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    templateInvalidReturnNullabilityNullType = const Template<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""A value of type '#type' can't be returned from a function with return type '#type2' because '#type2' is not nullable.""",
        withArguments: _withArgumentsInvalidReturnNullabilityNullType);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    codeInvalidReturnNullabilityNullType = const Code<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>(
  "InvalidReturnNullabilityNullType",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidReturnNullabilityNullType(
    DartType _type, DartType _type2, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeInvalidReturnNullabilityNullType,
      message:
          """A value of type '${type}' can't be returned from a function with return type '${type2}' because '${type2}' is not nullable.""" +
              labeler.originMessages,
      arguments: {'type': _type, 'type2': _type2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(DartType _type, DartType _type2, DartType _type3,
            DartType _type4, bool isNonNullableByDefault)>
    templateInvalidReturnPartNullability = const Template<
            Message Function(DartType _type, DartType _type2, DartType _type3,
                DartType _type4, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""A value of type '#type' can't be returned from a function with return type '#type2' because '#type3' is nullable and '#type4' isn't.""",
        withArguments: _withArgumentsInvalidReturnPartNullability);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(DartType _type, DartType _type2, DartType _type3,
            DartType _type4, bool isNonNullableByDefault)>
    codeInvalidReturnPartNullability = const Code<
        Message Function(DartType _type, DartType _type2, DartType _type3,
            DartType _type4, bool isNonNullableByDefault)>(
  "InvalidReturnPartNullability",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidReturnPartNullability(
    DartType _type,
    DartType _type2,
    DartType _type3,
    DartType _type4,
    bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  List<Object> type3Parts = labeler.labelType(_type3);
  List<Object> type4Parts = labeler.labelType(_type4);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  String type3 = type3Parts.join();
  String type4 = type4Parts.join();
  return new Message(codeInvalidReturnPartNullability,
      message:
          """A value of type '${type}' can't be returned from a function with return type '${type2}' because '${type3}' is nullable and '${type4}' isn't.""" +
              labeler.originMessages,
      arguments: {
        'type': _type,
        'type2': _type2,
        'type3': _type3,
        'type4': _type4
      });
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    templateMainWrongParameterType = const Template<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""The type '#type' of the first parameter of the 'main' method is not a supertype of '#type2'.""",
        withArguments: _withArgumentsMainWrongParameterType);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    codeMainWrongParameterType = const Code<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>(
  "MainWrongParameterType",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMainWrongParameterType(
    DartType _type, DartType _type2, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeMainWrongParameterType,
      message:
          """The type '${type}' of the first parameter of the 'main' method is not a supertype of '${type2}'.""" +
              labeler.originMessages,
      arguments: {'type': _type, 'type2': _type2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    templateMainWrongParameterTypeExported = const Template<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""The type '#type' of the first parameter of the exported 'main' method is not a supertype of '#type2'.""",
        withArguments: _withArgumentsMainWrongParameterTypeExported);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    codeMainWrongParameterTypeExported = const Code<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>(
  "MainWrongParameterTypeExported",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMainWrongParameterTypeExported(
    DartType _type, DartType _type2, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeMainWrongParameterTypeExported,
      message:
          """The type '${type}' of the first parameter of the exported 'main' method is not a supertype of '${type2}'.""" +
              labeler.originMessages,
      arguments: {'type': _type, 'type2': _type2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(DartType _type, DartType _type2, DartType _type3,
            bool isNonNullableByDefault)>
    templateMixinApplicationIncompatibleSupertype = const Template<
            Message Function(DartType _type, DartType _type2, DartType _type3,
                bool isNonNullableByDefault)>(
        messageTemplate:
            r"""'#type' doesn't implement '#type2' so it can't be used with '#type3'.""",
        withArguments: _withArgumentsMixinApplicationIncompatibleSupertype);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(DartType _type, DartType _type2, DartType _type3,
            bool isNonNullableByDefault)>
    codeMixinApplicationIncompatibleSupertype = const Code<
            Message Function(DartType _type, DartType _type2, DartType _type3,
                bool isNonNullableByDefault)>(
        "MixinApplicationIncompatibleSupertype",
        analyzerCodes: <String>["MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMixinApplicationIncompatibleSupertype(DartType _type,
    DartType _type2, DartType _type3, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
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
        Message Function(String name, String name2, DartType _type,
            bool isNonNullableByDefault)>
    templateMixinInferenceNoMatchingClass =
    const Template<
            Message Function(String name, String name2, DartType _type,
                bool isNonNullableByDefault)>(
        messageTemplate:
            r"""Type parameters could not be inferred for the mixin '#name' because '#name2' does not implement the mixin's supertype constraint '#type'.""",
        withArguments: _withArgumentsMixinInferenceNoMatchingClass);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(String name, String name2, DartType _type,
            bool isNonNullableByDefault)> codeMixinInferenceNoMatchingClass =
    const Code<
            Message Function(String name, String name2, DartType _type,
                bool isNonNullableByDefault)>("MixinInferenceNoMatchingClass",
        analyzerCodes: <String>["MIXIN_INFERENCE_NO_POSSIBLE_SUBSTITUTION"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMixinInferenceNoMatchingClass(
    String name, String name2, DartType _type, bool isNonNullableByDefault) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(codeMixinInferenceNoMatchingClass,
      message:
          """Type parameters could not be inferred for the mixin '${name}' because '${name2}' does not implement the mixin's supertype constraint '${type}'.""" +
              labeler.originMessages,
      arguments: {'name': name, 'name2': name2, 'type': _type});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, bool isNonNullableByDefault)>
    templateNonNullAwareSpreadIsNull = const Template<
            Message Function(DartType _type, bool isNonNullableByDefault)>(
        messageTemplate: r"""Can't spread a value with static type '#type'.""",
        withArguments: _withArgumentsNonNullAwareSpreadIsNull);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, bool isNonNullableByDefault)>
    codeNonNullAwareSpreadIsNull =
    const Code<Message Function(DartType _type, bool isNonNullableByDefault)>(
  "NonNullAwareSpreadIsNull",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonNullAwareSpreadIsNull(
    DartType _type, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(codeNonNullAwareSpreadIsNull,
      message: """Can't spread a value with static type '${type}'.""" +
          labeler.originMessages,
      arguments: {'type': _type});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(
            String name, DartType _type, bool isNonNullableByDefault)>
    templateNonNullableInNullAware = const Template<
            Message Function(
                String name, DartType _type, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""Operand of null-aware operation '#name' has type '#type' which excludes null.""",
        withArguments: _withArgumentsNonNullableInNullAware);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            String name, DartType _type, bool isNonNullableByDefault)>
    codeNonNullableInNullAware = const Code<
            Message Function(
                String name, DartType _type, bool isNonNullableByDefault)>(
        "NonNullableInNullAware",
        severity: Severity.warning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonNullableInNullAware(
    String name, DartType _type, bool isNonNullableByDefault) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(codeNonNullableInNullAware,
      message:
          """Operand of null-aware operation '${name}' has type '${type}' which excludes null.""" +
              labeler.originMessages,
      arguments: {'name': name, 'type': _type});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, bool isNonNullableByDefault)>
    templateNullableExpressionCallError = const Template<
            Message Function(DartType _type, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""Can't use an expression of type '#type' as a function because it's potentially null.""",
        tipTemplate: r"""Try calling using ?.call instead.""",
        withArguments: _withArgumentsNullableExpressionCallError);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, bool isNonNullableByDefault)>
    codeNullableExpressionCallError =
    const Code<Message Function(DartType _type, bool isNonNullableByDefault)>(
  "NullableExpressionCallError",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNullableExpressionCallError(
    DartType _type, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(codeNullableExpressionCallError,
      message:
          """Can't use an expression of type '${type}' as a function because it's potentially null.""" +
              labeler.originMessages,
      tip: """Try calling using ?.call instead.""",
      arguments: {'type': _type});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(
            String name, DartType _type, bool isNonNullableByDefault)>
    templateNullableMethodCallError = const Template<
            Message Function(
                String name, DartType _type, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""Method '#name' cannot be called on '#type' because it is potentially null.""",
        tipTemplate: r"""Try calling using ?. instead.""",
        withArguments: _withArgumentsNullableMethodCallError);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
    Message Function(String name, DartType _type,
        bool isNonNullableByDefault)> codeNullableMethodCallError = const Code<
    Message Function(String name, DartType _type, bool isNonNullableByDefault)>(
  "NullableMethodCallError",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNullableMethodCallError(
    String name, DartType _type, bool isNonNullableByDefault) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(codeNullableMethodCallError,
      message:
          """Method '${name}' cannot be called on '${type}' because it is potentially null.""" +
              labeler.originMessages,
      tip: """Try calling using ?. instead.""",
      arguments: {'name': name, 'type': _type});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(
            String name, DartType _type, bool isNonNullableByDefault)>
    templateNullableOperatorCallError = const Template<
            Message Function(
                String name, DartType _type, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""Operator '#name' cannot be called on '#type' because it is potentially null.""",
        withArguments: _withArgumentsNullableOperatorCallError);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            String name, DartType _type, bool isNonNullableByDefault)>
    codeNullableOperatorCallError = const Code<
        Message Function(
            String name, DartType _type, bool isNonNullableByDefault)>(
  "NullableOperatorCallError",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNullableOperatorCallError(
    String name, DartType _type, bool isNonNullableByDefault) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(codeNullableOperatorCallError,
      message:
          """Operator '${name}' cannot be called on '${type}' because it is potentially null.""" +
              labeler.originMessages,
      arguments: {'name': name, 'type': _type});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(
            String name, DartType _type, bool isNonNullableByDefault)>
    templateNullablePropertyAccessError = const Template<
            Message Function(
                String name, DartType _type, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""Property '#name' cannot be accessed on '#type' because it is potentially null.""",
        tipTemplate: r"""Try accessing using ?. instead.""",
        withArguments: _withArgumentsNullablePropertyAccessError);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            String name, DartType _type, bool isNonNullableByDefault)>
    codeNullablePropertyAccessError = const Code<
        Message Function(
            String name, DartType _type, bool isNonNullableByDefault)>(
  "NullablePropertyAccessError",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNullablePropertyAccessError(
    String name, DartType _type, bool isNonNullableByDefault) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(codeNullablePropertyAccessError,
      message:
          """Property '${name}' cannot be accessed on '${type}' because it is potentially null.""" +
              labeler.originMessages,
      tip: """Try accessing using ?. instead.""",
      arguments: {'name': name, 'type': _type});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(
            String name, DartType _type, bool isNonNullableByDefault)>
    templateOptionalNonNullableWithoutInitializerError = const Template<
            Message Function(
                String name, DartType _type, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""The parameter '#name' can't have a value of 'null' because of its type '#type', but the implicit default value is 'null'.""",
        tipTemplate:
            r"""Try adding either an explicit non-'null' default value or the 'required' modifier.""",
        withArguments:
            _withArgumentsOptionalNonNullableWithoutInitializerError);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            String name, DartType _type, bool isNonNullableByDefault)>
    codeOptionalNonNullableWithoutInitializerError = const Code<
            Message Function(
                String name, DartType _type, bool isNonNullableByDefault)>(
        "OptionalNonNullableWithoutInitializerError",
        analyzerCodes: <String>["MISSING_DEFAULT_VALUE_FOR_PARAMETER"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOptionalNonNullableWithoutInitializerError(
    String name, DartType _type, bool isNonNullableByDefault) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(codeOptionalNonNullableWithoutInitializerError,
      message:
          """The parameter '${name}' can't have a value of 'null' because of its type '${type}', but the implicit default value is 'null'.""" +
              labeler.originMessages,
      tip: """Try adding either an explicit non-'null' default value or the 'required' modifier.""",
      arguments: {'name': name, 'type': _type});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(String name, String name2, DartType _type,
            DartType _type2, String name3, bool isNonNullableByDefault)>
    templateOverrideTypeMismatchParameter = const Template<
            Message Function(String name, String name2, DartType _type,
                DartType _type2, String name3, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""The parameter '#name' of the method '#name2' has type '#type', which does not match the corresponding type, '#type2', in the overridden method, '#name3'.""",
        tipTemplate:
            r"""Change to a supertype of '#type2', or, for a covariant parameter, a subtype.""",
        withArguments: _withArgumentsOverrideTypeMismatchParameter);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(String name, String name2, DartType _type,
            DartType _type2, String name3, bool isNonNullableByDefault)>
    codeOverrideTypeMismatchParameter = const Code<
            Message Function(
                String name,
                String name2,
                DartType _type,
                DartType _type2,
                String name3,
                bool isNonNullableByDefault)>("OverrideTypeMismatchParameter",
        analyzerCodes: <String>["INVALID_METHOD_OVERRIDE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideTypeMismatchParameter(
    String name,
    String name2,
    DartType _type,
    DartType _type2,
    String name3,
    bool isNonNullableByDefault) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
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
        Message Function(String name, DartType _type, DartType _type2,
            String name2, bool isNonNullableByDefault)>
    templateOverrideTypeMismatchReturnType = const Template<
            Message Function(String name, DartType _type, DartType _type2,
                String name2, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""The return type of the method '#name' is '#type', which does not match the return type, '#type2', of the overridden method, '#name2'.""",
        tipTemplate: r"""Change to a subtype of '#type2'.""",
        withArguments: _withArgumentsOverrideTypeMismatchReturnType);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(String name, DartType _type, DartType _type2,
            String name2, bool isNonNullableByDefault)>
    codeOverrideTypeMismatchReturnType = const Code<
            Message Function(
                String name,
                DartType _type,
                DartType _type2,
                String name2,
                bool isNonNullableByDefault)>("OverrideTypeMismatchReturnType",
        analyzerCodes: <String>["INVALID_METHOD_OVERRIDE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideTypeMismatchReturnType(
    String name,
    DartType _type,
    DartType _type2,
    String name2,
    bool isNonNullableByDefault) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
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
        Message Function(String name, DartType _type, DartType _type2,
            String name2, bool isNonNullableByDefault)>
    templateOverrideTypeMismatchSetter = const Template<
            Message Function(String name, DartType _type, DartType _type2,
                String name2, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""The field '#name' has type '#type', which does not match the corresponding type, '#type2', in the overridden setter, '#name2'.""",
        withArguments: _withArgumentsOverrideTypeMismatchSetter);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(String name, DartType _type, DartType _type2,
            String name2, bool isNonNullableByDefault)>
    codeOverrideTypeMismatchSetter = const Code<
            Message Function(
                String name,
                DartType _type,
                DartType _type2,
                String name2,
                bool isNonNullableByDefault)>("OverrideTypeMismatchSetter",
        analyzerCodes: <String>["INVALID_METHOD_OVERRIDE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideTypeMismatchSetter(String name, DartType _type,
    DartType _type2, String name2, bool isNonNullableByDefault) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
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
const Template<
        Message Function(DartType _type, String name, String name2,
            DartType _type2, String name3, bool isNonNullableByDefault)>
    templateOverrideTypeVariablesBoundMismatch = const Template<
            Message Function(DartType _type, String name, String name2,
                DartType _type2, String name3, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""Declared bound '#type' of type variable '#name' of '#name2' doesn't match the bound '#type2' on overridden method '#name3'.""",
        withArguments: _withArgumentsOverrideTypeVariablesBoundMismatch);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(DartType _type, String name, String name2,
            DartType _type2, String name3, bool isNonNullableByDefault)>
    codeOverrideTypeVariablesBoundMismatch = const Code<
        Message Function(DartType _type, String name, String name2,
            DartType _type2, String name3, bool isNonNullableByDefault)>(
  "OverrideTypeVariablesBoundMismatch",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideTypeVariablesBoundMismatch(
    DartType _type,
    String name,
    String name2,
    DartType _type2,
    String name3,
    bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  List<Object> type2Parts = labeler.labelType(_type2);
  if (name3.isEmpty) throw 'No name provided';
  name3 = demangleMixinApplicationName(name3);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeOverrideTypeVariablesBoundMismatch,
      message:
          """Declared bound '${type}' of type variable '${name}' of '${name2}' doesn't match the bound '${type2}' on overridden method '${name3}'.""" +
              labeler.originMessages,
      arguments: {
        'type': _type,
        'name': name,
        'name2': name2,
        'type2': _type2,
        'name3': name3
      });
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    templateRedirectingFactoryIncompatibleTypeArgument = const Template<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        messageTemplate: r"""The type '#type' doesn't extend '#type2'.""",
        tipTemplate: r"""Try using a different type as argument.""",
        withArguments:
            _withArgumentsRedirectingFactoryIncompatibleTypeArgument);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    codeRedirectingFactoryIncompatibleTypeArgument = const Code<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        "RedirectingFactoryIncompatibleTypeArgument",
        analyzerCodes: <String>["TYPE_ARGUMENT_NOT_MATCHING_BOUNDS"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsRedirectingFactoryIncompatibleTypeArgument(
    DartType _type, DartType _type2, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
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
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    templateSpreadElementTypeMismatch = const Template<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""Can't assign spread elements of type '#type' to collection elements of type '#type2'.""",
        withArguments: _withArgumentsSpreadElementTypeMismatch);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    codeSpreadElementTypeMismatch = const Code<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        "SpreadElementTypeMismatch",
        analyzerCodes: <String>["LIST_ELEMENT_TYPE_NOT_ASSIGNABLE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSpreadElementTypeMismatch(
    DartType _type, DartType _type2, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
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
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    templateSpreadElementTypeMismatchNullability = const Template<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""Can't assign spread elements of type '#type' to collection elements of type '#type2' because '#type' is nullable and '#type2' isn't.""",
        withArguments: _withArgumentsSpreadElementTypeMismatchNullability);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    codeSpreadElementTypeMismatchNullability = const Code<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        "SpreadElementTypeMismatchNullability",
        analyzerCodes: <String>["LIST_ELEMENT_TYPE_NOT_ASSIGNABLE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSpreadElementTypeMismatchNullability(
    DartType _type, DartType _type2, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeSpreadElementTypeMismatchNullability,
      message:
          """Can't assign spread elements of type '${type}' to collection elements of type '${type2}' because '${type}' is nullable and '${type2}' isn't.""" +
              labeler.originMessages,
      arguments: {'type': _type, 'type2': _type2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(DartType _type, DartType _type2, DartType _type3,
            DartType _type4, bool isNonNullableByDefault)>
    templateSpreadElementTypeMismatchPartNullability = const Template<
            Message Function(DartType _type, DartType _type2, DartType _type3,
                DartType _type4, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""Can't assign spread elements of type '#type' to collection elements of type '#type2' because '#type3' is nullable and '#type4' isn't.""",
        withArguments: _withArgumentsSpreadElementTypeMismatchPartNullability);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(DartType _type, DartType _type2, DartType _type3,
            DartType _type4, bool isNonNullableByDefault)>
    codeSpreadElementTypeMismatchPartNullability = const Code<
            Message Function(DartType _type, DartType _type2, DartType _type3,
                DartType _type4, bool isNonNullableByDefault)>(
        "SpreadElementTypeMismatchPartNullability",
        analyzerCodes: <String>["LIST_ELEMENT_TYPE_NOT_ASSIGNABLE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSpreadElementTypeMismatchPartNullability(
    DartType _type,
    DartType _type2,
    DartType _type3,
    DartType _type4,
    bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  List<Object> type3Parts = labeler.labelType(_type3);
  List<Object> type4Parts = labeler.labelType(_type4);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  String type3 = type3Parts.join();
  String type4 = type4Parts.join();
  return new Message(codeSpreadElementTypeMismatchPartNullability,
      message:
          """Can't assign spread elements of type '${type}' to collection elements of type '${type2}' because '${type3}' is nullable and '${type4}' isn't.""" +
              labeler.originMessages,
      arguments: {
        'type': _type,
        'type2': _type2,
        'type3': _type3,
        'type4': _type4
      });
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    templateSpreadMapEntryElementKeyTypeMismatch = const Template<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""Can't assign spread entry keys of type '#type' to map entry keys of type '#type2'.""",
        withArguments: _withArgumentsSpreadMapEntryElementKeyTypeMismatch);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    codeSpreadMapEntryElementKeyTypeMismatch = const Code<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        "SpreadMapEntryElementKeyTypeMismatch",
        analyzerCodes: <String>["MAP_KEY_TYPE_NOT_ASSIGNABLE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSpreadMapEntryElementKeyTypeMismatch(
    DartType _type, DartType _type2, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
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
const Template<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    templateSpreadMapEntryElementKeyTypeMismatchNullability = const Template<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""Can't assign spread entry keys of type '#type' to map entry keys of type '#type2' because '#type' is nullable and '#type2' isn't.""",
        withArguments:
            _withArgumentsSpreadMapEntryElementKeyTypeMismatchNullability);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    codeSpreadMapEntryElementKeyTypeMismatchNullability = const Code<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        "SpreadMapEntryElementKeyTypeMismatchNullability",
        analyzerCodes: <String>["MAP_KEY_TYPE_NOT_ASSIGNABLE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSpreadMapEntryElementKeyTypeMismatchNullability(
    DartType _type, DartType _type2, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeSpreadMapEntryElementKeyTypeMismatchNullability,
      message:
          """Can't assign spread entry keys of type '${type}' to map entry keys of type '${type2}' because '${type}' is nullable and '${type2}' isn't.""" +
              labeler.originMessages,
      arguments: {'type': _type, 'type2': _type2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(DartType _type, DartType _type2, DartType _type3,
            DartType _type4, bool isNonNullableByDefault)>
    templateSpreadMapEntryElementKeyTypeMismatchPartNullability =
    const Template<
            Message Function(DartType _type, DartType _type2, DartType _type3,
                DartType _type4, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""Can't assign spread entry keys of type '#type' to map entry keys of type '#type2' because '#type3' is nullable and '#type4' isn't.""",
        withArguments:
            _withArgumentsSpreadMapEntryElementKeyTypeMismatchPartNullability);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(DartType _type, DartType _type2, DartType _type3,
            DartType _type4, bool isNonNullableByDefault)>
    codeSpreadMapEntryElementKeyTypeMismatchPartNullability = const Code<
            Message Function(DartType _type, DartType _type2, DartType _type3,
                DartType _type4, bool isNonNullableByDefault)>(
        "SpreadMapEntryElementKeyTypeMismatchPartNullability",
        analyzerCodes: <String>["MAP_KEY_TYPE_NOT_ASSIGNABLE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSpreadMapEntryElementKeyTypeMismatchPartNullability(
    DartType _type,
    DartType _type2,
    DartType _type3,
    DartType _type4,
    bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  List<Object> type3Parts = labeler.labelType(_type3);
  List<Object> type4Parts = labeler.labelType(_type4);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  String type3 = type3Parts.join();
  String type4 = type4Parts.join();
  return new Message(codeSpreadMapEntryElementKeyTypeMismatchPartNullability,
      message:
          """Can't assign spread entry keys of type '${type}' to map entry keys of type '${type2}' because '${type3}' is nullable and '${type4}' isn't.""" +
              labeler.originMessages,
      arguments: {
        'type': _type,
        'type2': _type2,
        'type3': _type3,
        'type4': _type4
      });
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    templateSpreadMapEntryElementValueTypeMismatch = const Template<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""Can't assign spread entry values of type '#type' to map entry values of type '#type2'.""",
        withArguments: _withArgumentsSpreadMapEntryElementValueTypeMismatch);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    codeSpreadMapEntryElementValueTypeMismatch = const Code<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        "SpreadMapEntryElementValueTypeMismatch",
        analyzerCodes: <String>["MAP_VALUE_TYPE_NOT_ASSIGNABLE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSpreadMapEntryElementValueTypeMismatch(
    DartType _type, DartType _type2, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
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
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    templateSpreadMapEntryElementValueTypeMismatchNullability = const Template<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""Can't assign spread entry values of type '#type' to map entry values of type '#type2' because '#type' is nullable and '#type2' isn't.""",
        withArguments:
            _withArgumentsSpreadMapEntryElementValueTypeMismatchNullability);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    codeSpreadMapEntryElementValueTypeMismatchNullability = const Code<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        "SpreadMapEntryElementValueTypeMismatchNullability",
        analyzerCodes: <String>["MAP_VALUE_TYPE_NOT_ASSIGNABLE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSpreadMapEntryElementValueTypeMismatchNullability(
    DartType _type, DartType _type2, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeSpreadMapEntryElementValueTypeMismatchNullability,
      message:
          """Can't assign spread entry values of type '${type}' to map entry values of type '${type2}' because '${type}' is nullable and '${type2}' isn't.""" +
              labeler.originMessages,
      arguments: {'type': _type, 'type2': _type2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(DartType _type, DartType _type2, DartType _type3,
            DartType _type4, bool isNonNullableByDefault)>
    templateSpreadMapEntryElementValueTypeMismatchPartNullability =
    const Template<
            Message Function(DartType _type, DartType _type2, DartType _type3,
                DartType _type4, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""Can't assign spread entry values of type '#type' to map entry values of type '#type2' because '#type3' is nullable and '#type4' isn't.""",
        withArguments:
            _withArgumentsSpreadMapEntryElementValueTypeMismatchPartNullability);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(DartType _type, DartType _type2, DartType _type3,
            DartType _type4, bool isNonNullableByDefault)>
    codeSpreadMapEntryElementValueTypeMismatchPartNullability = const Code<
            Message Function(DartType _type, DartType _type2, DartType _type3,
                DartType _type4, bool isNonNullableByDefault)>(
        "SpreadMapEntryElementValueTypeMismatchPartNullability",
        analyzerCodes: <String>["MAP_VALUE_TYPE_NOT_ASSIGNABLE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSpreadMapEntryElementValueTypeMismatchPartNullability(
    DartType _type,
    DartType _type2,
    DartType _type3,
    DartType _type4,
    bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  List<Object> type3Parts = labeler.labelType(_type3);
  List<Object> type4Parts = labeler.labelType(_type4);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  String type3 = type3Parts.join();
  String type4 = type4Parts.join();
  return new Message(codeSpreadMapEntryElementValueTypeMismatchPartNullability,
      message:
          """Can't assign spread entry values of type '${type}' to map entry values of type '${type2}' because '${type3}' is nullable and '${type4}' isn't.""" +
              labeler.originMessages,
      arguments: {
        'type': _type,
        'type2': _type2,
        'type3': _type3,
        'type4': _type4
      });
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, bool isNonNullableByDefault)>
    templateSpreadMapEntryTypeMismatch = const Template<
            Message Function(DartType _type, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""Unexpected type '#type' of a map spread entry.  Expected 'dynamic' or a Map.""",
        withArguments: _withArgumentsSpreadMapEntryTypeMismatch);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, bool isNonNullableByDefault)>
    codeSpreadMapEntryTypeMismatch =
    const Code<Message Function(DartType _type, bool isNonNullableByDefault)>(
  "SpreadMapEntryTypeMismatch",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSpreadMapEntryTypeMismatch(
    DartType _type, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
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
        DartType _type,
        bool
            isNonNullableByDefault)> templateSpreadTypeMismatch = const Template<
        Message Function(DartType _type, bool isNonNullableByDefault)>(
    messageTemplate:
        r"""Unexpected type '#type' of a spread.  Expected 'dynamic' or an Iterable.""",
    withArguments: _withArgumentsSpreadTypeMismatch);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, bool isNonNullableByDefault)>
    codeSpreadTypeMismatch =
    const Code<Message Function(DartType _type, bool isNonNullableByDefault)>(
  "SpreadTypeMismatch",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSpreadTypeMismatch(
    DartType _type, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
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
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    templateSwitchExpressionNotAssignable = const Template<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""Type '#type' of the switch expression isn't assignable to the type '#type2' of this case expression.""",
        withArguments: _withArgumentsSwitchExpressionNotAssignable);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    codeSwitchExpressionNotAssignable = const Code<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        "SwitchExpressionNotAssignable",
        analyzerCodes: <String>["SWITCH_EXPRESSION_NOT_ASSIGNABLE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSwitchExpressionNotAssignable(
    DartType _type, DartType _type2, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
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
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    templateSwitchExpressionNotSubtype = const Template<
            Message Function(
                DartType _type, DartType _type2, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""Type '#type' of the case expression is not a subtype of type '#type2' of this switch expression.""",
        withArguments: _withArgumentsSwitchExpressionNotSubtype);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>
    codeSwitchExpressionNotSubtype = const Code<
        Message Function(
            DartType _type, DartType _type2, bool isNonNullableByDefault)>(
  "SwitchExpressionNotSubtype",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSwitchExpressionNotSubtype(
    DartType _type, DartType _type2, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(codeSwitchExpressionNotSubtype,
      message:
          """Type '${type}' of the case expression is not a subtype of type '${type2}' of this switch expression.""" +
              labeler.originMessages,
      arguments: {'type': _type, 'type2': _type2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, bool isNonNullableByDefault)>
    templateThrowingNotAssignableToObjectError = const Template<
            Message Function(DartType _type, bool isNonNullableByDefault)>(
        messageTemplate:
            r"""Can't throw a value of '#type' since it is neither dynamic nor non-nullable.""",
        withArguments: _withArgumentsThrowingNotAssignableToObjectError);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, bool isNonNullableByDefault)>
    codeThrowingNotAssignableToObjectError =
    const Code<Message Function(DartType _type, bool isNonNullableByDefault)>(
  "ThrowingNotAssignableToObjectError",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsThrowingNotAssignableToObjectError(
    DartType _type, bool isNonNullableByDefault) {
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(codeThrowingNotAssignableToObjectError,
      message:
          """Can't throw a value of '${type}' since it is neither dynamic nor non-nullable.""" +
              labeler.originMessages,
      arguments: {'type': _type});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String name,
        DartType _type,
        bool
            isNonNullableByDefault)> templateUndefinedGetter = const Template<
        Message Function(
            String name, DartType _type, bool isNonNullableByDefault)>(
    messageTemplate:
        r"""The getter '#name' isn't defined for the class '#type'.""",
    tipTemplate:
        r"""Try correcting the name to the name of an existing getter, or defining a getter or field named '#name'.""",
    withArguments: _withArgumentsUndefinedGetter);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            String name, DartType _type, bool isNonNullableByDefault)>
    codeUndefinedGetter = const Code<
            Message Function(
                String name, DartType _type, bool isNonNullableByDefault)>(
        "UndefinedGetter",
        analyzerCodes: <String>["UNDEFINED_GETTER"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUndefinedGetter(
    String name, DartType _type, bool isNonNullableByDefault) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
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
        DartType _type,
        bool
            isNonNullableByDefault)> templateUndefinedMethod = const Template<
        Message Function(
            String name, DartType _type, bool isNonNullableByDefault)>(
    messageTemplate:
        r"""The method '#name' isn't defined for the class '#type'.""",
    tipTemplate:
        r"""Try correcting the name to the name of an existing method, or defining a method named '#name'.""",
    withArguments: _withArgumentsUndefinedMethod);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            String name, DartType _type, bool isNonNullableByDefault)>
    codeUndefinedMethod = const Code<
            Message Function(
                String name, DartType _type, bool isNonNullableByDefault)>(
        "UndefinedMethod",
        analyzerCodes: <String>["UNDEFINED_METHOD"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUndefinedMethod(
    String name, DartType _type, bool isNonNullableByDefault) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
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
        DartType _type,
        bool
            isNonNullableByDefault)> templateUndefinedOperator = const Template<
        Message Function(String name, DartType _type,
            bool isNonNullableByDefault)>(
    messageTemplate:
        r"""The operator '#name' isn't defined for the class '#type'.""",
    tipTemplate:
        r"""Try correcting the operator to an existing operator, or defining a '#name' operator.""",
    withArguments: _withArgumentsUndefinedOperator);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            String name, DartType _type, bool isNonNullableByDefault)>
    codeUndefinedOperator = const Code<
            Message Function(
                String name, DartType _type, bool isNonNullableByDefault)>(
        "UndefinedOperator",
        analyzerCodes: <String>["UNDEFINED_METHOD"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUndefinedOperator(
    String name, DartType _type, bool isNonNullableByDefault) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(codeUndefinedOperator,
      message:
          """The operator '${name}' isn't defined for the class '${type}'.""" +
              labeler.originMessages,
      tip:
          """Try correcting the operator to an existing operator, or defining a '${name}' operator.""",
      arguments: {'name': name, 'type': _type});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String name,
        DartType _type,
        bool
            isNonNullableByDefault)> templateUndefinedSetter = const Template<
        Message Function(
            String name, DartType _type, bool isNonNullableByDefault)>(
    messageTemplate:
        r"""The setter '#name' isn't defined for the class '#type'.""",
    tipTemplate:
        r"""Try correcting the name to the name of an existing setter, or defining a setter or field named '#name'.""",
    withArguments: _withArgumentsUndefinedSetter);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            String name, DartType _type, bool isNonNullableByDefault)>
    codeUndefinedSetter = const Code<
            Message Function(
                String name, DartType _type, bool isNonNullableByDefault)>(
        "UndefinedSetter",
        analyzerCodes: <String>["UNDEFINED_SETTER"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUndefinedSetter(
    String name, DartType _type, bool isNonNullableByDefault) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);
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
