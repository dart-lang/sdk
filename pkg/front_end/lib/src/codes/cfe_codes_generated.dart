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
const Template<Message Function(String name, DartType _type)>
codeAmbiguousExtensionMethod =
    const Template<Message Function(String name, DartType _type)>(
      "AmbiguousExtensionMethod",
      problemMessageTemplate:
          r"""The method '#name' is defined in multiple extensions for '#type' and neither is more specific.""",
      correctionMessageTemplate:
          r"""Try using an explicit extension application of the wanted extension or hiding unwanted extensions from scope.""",
      withArgumentsOld: _withArgumentsOldAmbiguousExtensionMethod,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldAmbiguousExtensionMethod(String name, DartType _type) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeAmbiguousExtensionMethod,
    problemMessage:
        """The method '${name}' is defined in multiple extensions for '${type}' and neither is more specific.""" +
        labeler.originMessages,
    correctionMessage:
        """Try using an explicit extension application of the wanted extension or hiding unwanted extensions from scope.""",
    arguments: {'name': name, 'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, DartType _type)>
codeAmbiguousExtensionOperator =
    const Template<Message Function(String name, DartType _type)>(
      "AmbiguousExtensionOperator",
      problemMessageTemplate:
          r"""The operator '#name' is defined in multiple extensions for '#type' and neither is more specific.""",
      correctionMessageTemplate:
          r"""Try using an explicit extension application of the wanted extension or hiding unwanted extensions from scope.""",
      withArgumentsOld: _withArgumentsOldAmbiguousExtensionOperator,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldAmbiguousExtensionOperator(
  String name,
  DartType _type,
) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeAmbiguousExtensionOperator,
    problemMessage:
        """The operator '${name}' is defined in multiple extensions for '${type}' and neither is more specific.""" +
        labeler.originMessages,
    correctionMessage:
        """Try using an explicit extension application of the wanted extension or hiding unwanted extensions from scope.""",
    arguments: {'name': name, 'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, DartType _type)>
codeAmbiguousExtensionProperty =
    const Template<Message Function(String name, DartType _type)>(
      "AmbiguousExtensionProperty",
      problemMessageTemplate:
          r"""The property '#name' is defined in multiple extensions for '#type' and neither is more specific.""",
      correctionMessageTemplate:
          r"""Try using an explicit extension application of the wanted extension or hiding unwanted extensions from scope.""",
      withArgumentsOld: _withArgumentsOldAmbiguousExtensionProperty,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldAmbiguousExtensionProperty(
  String name,
  DartType _type,
) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeAmbiguousExtensionProperty,
    problemMessage:
        """The property '${name}' is defined in multiple extensions for '${type}' and neither is more specific.""" +
        labeler.originMessages,
    correctionMessage:
        """Try using an explicit extension application of the wanted extension or hiding unwanted extensions from scope.""",
    arguments: {'name': name, 'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, DartType _type, DartType _type2)>
codeAmbiguousSupertypes =
    const Template<
      Message Function(String name, DartType _type, DartType _type2)
    >(
      "AmbiguousSupertypes",
      problemMessageTemplate:
          r"""'#name' can't implement both '#type' and '#type2'""",
      withArgumentsOld: _withArgumentsOldAmbiguousSupertypes,
      analyzerCodes: <String>["AMBIGUOUS_SUPERTYPES"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldAmbiguousSupertypes(
  String name,
  DartType _type,
  DartType _type2,
) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeAmbiguousSupertypes,
    problemMessage:
        """'${name}' can't implement both '${type}' and '${type2}'""" +
        labeler.originMessages,
    arguments: {'name': name, 'type': _type, 'type2': _type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, DartType _type2)>
codeArgumentTypeNotAssignable =
    const Template<Message Function(DartType _type, DartType _type2)>(
      "ArgumentTypeNotAssignable",
      problemMessageTemplate:
          r"""The argument type '#type' can't be assigned to the parameter type '#type2'.""",
      withArgumentsOld: _withArgumentsOldArgumentTypeNotAssignable,
      analyzerCodes: <String>["ARGUMENT_TYPE_NOT_ASSIGNABLE"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldArgumentTypeNotAssignable(
  DartType _type,
  DartType _type2,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeArgumentTypeNotAssignable,
    problemMessage:
        """The argument type '${type}' can't be assigned to the parameter type '${type2}'.""" +
        labeler.originMessages,
    arguments: {'type': _type, 'type2': _type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Constant _constant)>
codeConstEvalCaseImplementsEqual =
    const Template<Message Function(Constant _constant)>(
      "ConstEvalCaseImplementsEqual",
      problemMessageTemplate:
          r"""Case expression '#constant' does not have a primitive operator '=='.""",
      withArgumentsOld: _withArgumentsOldConstEvalCaseImplementsEqual,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConstEvalCaseImplementsEqual(Constant _constant) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> constantParts = labeler.labelConstant(_constant);
  String constant = constantParts.join();
  return new Message(
    codeConstEvalCaseImplementsEqual,
    problemMessage:
        """Case expression '${constant}' does not have a primitive operator '=='.""" +
        labeler.originMessages,
    arguments: {'constant': _constant},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Constant _constant)>
codeConstEvalDuplicateElement =
    const Template<Message Function(Constant _constant)>(
      "ConstEvalDuplicateElement",
      problemMessageTemplate:
          r"""The element '#constant' conflicts with another existing element in the set.""",
      withArgumentsOld: _withArgumentsOldConstEvalDuplicateElement,
      analyzerCodes: <String>["EQUAL_ELEMENTS_IN_CONST_SET"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConstEvalDuplicateElement(Constant _constant) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> constantParts = labeler.labelConstant(_constant);
  String constant = constantParts.join();
  return new Message(
    codeConstEvalDuplicateElement,
    problemMessage:
        """The element '${constant}' conflicts with another existing element in the set.""" +
        labeler.originMessages,
    arguments: {'constant': _constant},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Constant _constant)>
codeConstEvalDuplicateKey = const Template<Message Function(Constant _constant)>(
  "ConstEvalDuplicateKey",
  problemMessageTemplate:
      r"""The key '#constant' conflicts with another existing key in the map.""",
  withArgumentsOld: _withArgumentsOldConstEvalDuplicateKey,
  analyzerCodes: <String>["EQUAL_KEYS_IN_CONST_MAP"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConstEvalDuplicateKey(Constant _constant) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> constantParts = labeler.labelConstant(_constant);
  String constant = constantParts.join();
  return new Message(
    codeConstEvalDuplicateKey,
    problemMessage:
        """The key '${constant}' conflicts with another existing key in the map.""" +
        labeler.originMessages,
    arguments: {'constant': _constant},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Constant _constant)>
codeConstEvalElementImplementsEqual =
    const Template<Message Function(Constant _constant)>(
      "ConstEvalElementImplementsEqual",
      problemMessageTemplate:
          r"""The element '#constant' does not have a primitive operator '=='.""",
      withArgumentsOld: _withArgumentsOldConstEvalElementImplementsEqual,
      analyzerCodes: <String>["CONST_SET_ELEMENT_TYPE_IMPLEMENTS_EQUALS"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConstEvalElementImplementsEqual(Constant _constant) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> constantParts = labeler.labelConstant(_constant);
  String constant = constantParts.join();
  return new Message(
    codeConstEvalElementImplementsEqual,
    problemMessage:
        """The element '${constant}' does not have a primitive operator '=='.""" +
        labeler.originMessages,
    arguments: {'constant': _constant},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Constant _constant)>
codeConstEvalElementNotPrimitiveEquality =
    const Template<Message Function(Constant _constant)>(
      "ConstEvalElementNotPrimitiveEquality",
      problemMessageTemplate:
          r"""The element '#constant' does not have a primitive equality.""",
      withArgumentsOld: _withArgumentsOldConstEvalElementNotPrimitiveEquality,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConstEvalElementNotPrimitiveEquality(
  Constant _constant,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> constantParts = labeler.labelConstant(_constant);
  String constant = constantParts.join();
  return new Message(
    codeConstEvalElementNotPrimitiveEquality,
    problemMessage:
        """The element '${constant}' does not have a primitive equality.""" +
        labeler.originMessages,
    arguments: {'constant': _constant},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Constant _constant, DartType _type)>
codeConstEvalEqualsOperandNotPrimitiveEquality =
    const Template<Message Function(Constant _constant, DartType _type)>(
      "ConstEvalEqualsOperandNotPrimitiveEquality",
      problemMessageTemplate:
          r"""Binary operator '==' requires receiver constant '#constant' of a type with primitive equality or type 'double', but was of type '#type'.""",
      withArgumentsOld:
          _withArgumentsOldConstEvalEqualsOperandNotPrimitiveEquality,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConstEvalEqualsOperandNotPrimitiveEquality(
  Constant _constant,
  DartType _type,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> constantParts = labeler.labelConstant(_constant);
  List<Object> typeParts = labeler.labelType(_type);
  String constant = constantParts.join();
  String type = typeParts.join();
  return new Message(
    codeConstEvalEqualsOperandNotPrimitiveEquality,
    problemMessage:
        """Binary operator '==' requires receiver constant '${constant}' of a type with primitive equality or type 'double', but was of type '${type}'.""" +
        labeler.originMessages,
    arguments: {'constant': _constant, 'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(
    String stringOKEmpty,
    Constant _constant,
    DartType _type,
    DartType _type2,
  )
>
codeConstEvalInvalidBinaryOperandType =
    const Template<
      Message Function(
        String stringOKEmpty,
        Constant _constant,
        DartType _type,
        DartType _type2,
      )
    >(
      "ConstEvalInvalidBinaryOperandType",
      problemMessageTemplate:
          r"""Binary operator '#stringOKEmpty' on '#constant' requires operand of type '#type', but was of type '#type2'.""",
      withArgumentsOld: _withArgumentsOldConstEvalInvalidBinaryOperandType,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConstEvalInvalidBinaryOperandType(
  String stringOKEmpty,
  Constant _constant,
  DartType _type,
  DartType _type2,
) {
  if (stringOKEmpty.isEmpty) stringOKEmpty = '(empty)';
  TypeLabeler labeler = new TypeLabeler();
  List<Object> constantParts = labeler.labelConstant(_constant);
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String constant = constantParts.join();
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeConstEvalInvalidBinaryOperandType,
    problemMessage:
        """Binary operator '${stringOKEmpty}' on '${constant}' requires operand of type '${type}', but was of type '${type2}'.""" +
        labeler.originMessages,
    arguments: {
      'stringOKEmpty': stringOKEmpty,
      'constant': _constant,
      'type': _type,
      'type2': _type2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Constant _constant, DartType _type)>
codeConstEvalInvalidEqualsOperandType =
    const Template<Message Function(Constant _constant, DartType _type)>(
      "ConstEvalInvalidEqualsOperandType",
      problemMessageTemplate:
          r"""Binary operator '==' requires receiver constant '#constant' of type 'Null', 'bool', 'int', 'double', or 'String', but was of type '#type'.""",
      withArgumentsOld: _withArgumentsOldConstEvalInvalidEqualsOperandType,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConstEvalInvalidEqualsOperandType(
  Constant _constant,
  DartType _type,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> constantParts = labeler.labelConstant(_constant);
  List<Object> typeParts = labeler.labelType(_type);
  String constant = constantParts.join();
  String type = typeParts.join();
  return new Message(
    codeConstEvalInvalidEqualsOperandType,
    problemMessage:
        """Binary operator '==' requires receiver constant '${constant}' of type 'Null', 'bool', 'int', 'double', or 'String', but was of type '${type}'.""" +
        labeler.originMessages,
    arguments: {'constant': _constant, 'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String stringOKEmpty, Constant _constant)>
codeConstEvalInvalidMethodInvocation =
    const Template<Message Function(String stringOKEmpty, Constant _constant)>(
      "ConstEvalInvalidMethodInvocation",
      problemMessageTemplate:
          r"""The method '#stringOKEmpty' can't be invoked on '#constant' in a constant expression.""",
      withArgumentsOld: _withArgumentsOldConstEvalInvalidMethodInvocation,
      analyzerCodes: <String>["UNDEFINED_OPERATOR"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConstEvalInvalidMethodInvocation(
  String stringOKEmpty,
  Constant _constant,
) {
  if (stringOKEmpty.isEmpty) stringOKEmpty = '(empty)';
  TypeLabeler labeler = new TypeLabeler();
  List<Object> constantParts = labeler.labelConstant(_constant);
  String constant = constantParts.join();
  return new Message(
    codeConstEvalInvalidMethodInvocation,
    problemMessage:
        """The method '${stringOKEmpty}' can't be invoked on '${constant}' in a constant expression.""" +
        labeler.originMessages,
    arguments: {'stringOKEmpty': stringOKEmpty, 'constant': _constant},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String stringOKEmpty, Constant _constant)>
codeConstEvalInvalidPropertyGet =
    const Template<Message Function(String stringOKEmpty, Constant _constant)>(
      "ConstEvalInvalidPropertyGet",
      problemMessageTemplate:
          r"""The property '#stringOKEmpty' can't be accessed on '#constant' in a constant expression.""",
      withArgumentsOld: _withArgumentsOldConstEvalInvalidPropertyGet,
      analyzerCodes: <String>["CONST_EVAL_THROWS_EXCEPTION"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConstEvalInvalidPropertyGet(
  String stringOKEmpty,
  Constant _constant,
) {
  if (stringOKEmpty.isEmpty) stringOKEmpty = '(empty)';
  TypeLabeler labeler = new TypeLabeler();
  List<Object> constantParts = labeler.labelConstant(_constant);
  String constant = constantParts.join();
  return new Message(
    codeConstEvalInvalidPropertyGet,
    problemMessage:
        """The property '${stringOKEmpty}' can't be accessed on '${constant}' in a constant expression.""" +
        labeler.originMessages,
    arguments: {'stringOKEmpty': stringOKEmpty, 'constant': _constant},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String stringOKEmpty, Constant _constant)>
codeConstEvalInvalidRecordIndexGet =
    const Template<Message Function(String stringOKEmpty, Constant _constant)>(
      "ConstEvalInvalidRecordIndexGet",
      problemMessageTemplate:
          r"""The property '#stringOKEmpty' can't be accessed on '#constant' in a constant expression.""",
      withArgumentsOld: _withArgumentsOldConstEvalInvalidRecordIndexGet,
      analyzerCodes: <String>["CONST_EVAL_THROWS_EXCEPTION"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConstEvalInvalidRecordIndexGet(
  String stringOKEmpty,
  Constant _constant,
) {
  if (stringOKEmpty.isEmpty) stringOKEmpty = '(empty)';
  TypeLabeler labeler = new TypeLabeler();
  List<Object> constantParts = labeler.labelConstant(_constant);
  String constant = constantParts.join();
  return new Message(
    codeConstEvalInvalidRecordIndexGet,
    problemMessage:
        """The property '${stringOKEmpty}' can't be accessed on '${constant}' in a constant expression.""" +
        labeler.originMessages,
    arguments: {'stringOKEmpty': stringOKEmpty, 'constant': _constant},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String stringOKEmpty, Constant _constant)>
codeConstEvalInvalidRecordNameGet =
    const Template<Message Function(String stringOKEmpty, Constant _constant)>(
      "ConstEvalInvalidRecordNameGet",
      problemMessageTemplate:
          r"""The property '#stringOKEmpty' can't be accessed on '#constant' in a constant expression.""",
      withArgumentsOld: _withArgumentsOldConstEvalInvalidRecordNameGet,
      analyzerCodes: <String>["CONST_EVAL_THROWS_EXCEPTION"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConstEvalInvalidRecordNameGet(
  String stringOKEmpty,
  Constant _constant,
) {
  if (stringOKEmpty.isEmpty) stringOKEmpty = '(empty)';
  TypeLabeler labeler = new TypeLabeler();
  List<Object> constantParts = labeler.labelConstant(_constant);
  String constant = constantParts.join();
  return new Message(
    codeConstEvalInvalidRecordNameGet,
    problemMessage:
        """The property '${stringOKEmpty}' can't be accessed on '${constant}' in a constant expression.""" +
        labeler.originMessages,
    arguments: {'stringOKEmpty': stringOKEmpty, 'constant': _constant},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Constant _constant)>
codeConstEvalInvalidStringInterpolationOperand =
    const Template<Message Function(Constant _constant)>(
      "ConstEvalInvalidStringInterpolationOperand",
      problemMessageTemplate:
          r"""The constant value '#constant' can't be used as part of a string interpolation in a constant expression.
Only values of type 'null', 'bool', 'int', 'double', or 'String' can be used.""",
      withArgumentsOld:
          _withArgumentsOldConstEvalInvalidStringInterpolationOperand,
      analyzerCodes: <String>["CONST_EVAL_TYPE_BOOL_NUM_STRING"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConstEvalInvalidStringInterpolationOperand(
  Constant _constant,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> constantParts = labeler.labelConstant(_constant);
  String constant = constantParts.join();
  return new Message(
    codeConstEvalInvalidStringInterpolationOperand,
    problemMessage:
        """The constant value '${constant}' can't be used as part of a string interpolation in a constant expression.
Only values of type 'null', 'bool', 'int', 'double', or 'String' can be used.""" +
        labeler.originMessages,
    arguments: {'constant': _constant},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Constant _constant)>
codeConstEvalInvalidSymbolName =
    const Template<Message Function(Constant _constant)>(
      "ConstEvalInvalidSymbolName",
      problemMessageTemplate:
          r"""The symbol name must be a valid public Dart member name, public constructor name, or library name, optionally qualified, but was '#constant'.""",
      withArgumentsOld: _withArgumentsOldConstEvalInvalidSymbolName,
      analyzerCodes: <String>["CONST_EVAL_THROWS_EXCEPTION"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConstEvalInvalidSymbolName(Constant _constant) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> constantParts = labeler.labelConstant(_constant);
  String constant = constantParts.join();
  return new Message(
    codeConstEvalInvalidSymbolName,
    problemMessage:
        """The symbol name must be a valid public Dart member name, public constructor name, or library name, optionally qualified, but was '${constant}'.""" +
        labeler.originMessages,
    arguments: {'constant': _constant},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Constant _constant, DartType _type, DartType _type2)
>
codeConstEvalInvalidType =
    const Template<
      Message Function(Constant _constant, DartType _type, DartType _type2)
    >(
      "ConstEvalInvalidType",
      problemMessageTemplate:
          r"""Expected constant '#constant' to be of type '#type', but was of type '#type2'.""",
      withArgumentsOld: _withArgumentsOldConstEvalInvalidType,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConstEvalInvalidType(
  Constant _constant,
  DartType _type,
  DartType _type2,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> constantParts = labeler.labelConstant(_constant);
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String constant = constantParts.join();
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeConstEvalInvalidType,
    problemMessage:
        """Expected constant '${constant}' to be of type '${type}', but was of type '${type2}'.""" +
        labeler.originMessages,
    arguments: {'constant': _constant, 'type': _type, 'type2': _type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Constant _constant)>
codeConstEvalKeyImplementsEqual =
    const Template<Message Function(Constant _constant)>(
      "ConstEvalKeyImplementsEqual",
      problemMessageTemplate:
          r"""The key '#constant' does not have a primitive operator '=='.""",
      withArgumentsOld: _withArgumentsOldConstEvalKeyImplementsEqual,
      analyzerCodes: <String>[
        "CONST_MAP_KEY_EXPRESSION_TYPE_IMPLEMENTS_EQUALS",
      ],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConstEvalKeyImplementsEqual(Constant _constant) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> constantParts = labeler.labelConstant(_constant);
  String constant = constantParts.join();
  return new Message(
    codeConstEvalKeyImplementsEqual,
    problemMessage:
        """The key '${constant}' does not have a primitive operator '=='.""" +
        labeler.originMessages,
    arguments: {'constant': _constant},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Constant _constant)>
codeConstEvalKeyNotPrimitiveEquality =
    const Template<Message Function(Constant _constant)>(
      "ConstEvalKeyNotPrimitiveEquality",
      problemMessageTemplate:
          r"""The key '#constant' does not have a primitive equality.""",
      withArgumentsOld: _withArgumentsOldConstEvalKeyNotPrimitiveEquality,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConstEvalKeyNotPrimitiveEquality(Constant _constant) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> constantParts = labeler.labelConstant(_constant);
  String constant = constantParts.join();
  return new Message(
    codeConstEvalKeyNotPrimitiveEquality,
    problemMessage:
        """The key '${constant}' does not have a primitive equality.""" +
        labeler.originMessages,
    arguments: {'constant': _constant},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Constant _constant)>
codeConstEvalUnhandledException =
    const Template<Message Function(Constant _constant)>(
      "ConstEvalUnhandledException",
      problemMessageTemplate: r"""Unhandled exception: #constant""",
      withArgumentsOld: _withArgumentsOldConstEvalUnhandledException,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConstEvalUnhandledException(Constant _constant) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> constantParts = labeler.labelConstant(_constant);
  String constant = constantParts.join();
  return new Message(
    codeConstEvalUnhandledException,
    problemMessage:
        """Unhandled exception: ${constant}""" + labeler.originMessages,
    arguments: {'constant': _constant},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, String name)>
codeDeferredTypeAnnotation =
    const Template<Message Function(DartType _type, String name)>(
      "DeferredTypeAnnotation",
      problemMessageTemplate:
          r"""The type '#type' is deferred loaded via prefix '#name' and can't be used as a type annotation.""",
      correctionMessageTemplate:
          r"""Try removing 'deferred' from the import of '#name' or use a supertype of '#type' that isn't deferred.""",
      withArgumentsOld: _withArgumentsOldDeferredTypeAnnotation,
      analyzerCodes: <String>["TYPE_ANNOTATION_DEFERRED_CLASS"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldDeferredTypeAnnotation(DartType _type, String name) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  String type = typeParts.join();
  return new Message(
    codeDeferredTypeAnnotation,
    problemMessage:
        """The type '${type}' is deferred loaded via prefix '${name}' and can't be used as a type annotation.""" +
        labeler.originMessages,
    correctionMessage:
        """Try removing 'deferred' from the import of '${name}' or use a supertype of '${type}' that isn't deferred.""",
    arguments: {'type': _type, 'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, DartType _type)>
codeDotShorthandsUndefinedGetter =
    const Template<Message Function(String name, DartType _type)>(
      "DotShorthandsUndefinedGetter",
      problemMessageTemplate:
          r"""The static getter or field '#name' isn't defined for the type '#type'.""",
      correctionMessageTemplate:
          r"""Try correcting the name to the name of an existing static getter or field, or defining a getter or field named '#name'.""",
      withArgumentsOld: _withArgumentsOldDotShorthandsUndefinedGetter,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldDotShorthandsUndefinedGetter(
  String name,
  DartType _type,
) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeDotShorthandsUndefinedGetter,
    problemMessage:
        """The static getter or field '${name}' isn't defined for the type '${type}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try correcting the name to the name of an existing static getter or field, or defining a getter or field named '${name}'.""",
    arguments: {'name': name, 'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, DartType _type)>
codeDotShorthandsUndefinedInvocation =
    const Template<Message Function(String name, DartType _type)>(
      "DotShorthandsUndefinedInvocation",
      problemMessageTemplate:
          r"""The static method or constructor '#name' isn't defined for the type '#type'.""",
      correctionMessageTemplate:
          r"""Try correcting the name to the name of an existing static method or constructor, or defining a static method or constructor named '#name'.""",
      withArgumentsOld: _withArgumentsOldDotShorthandsUndefinedInvocation,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldDotShorthandsUndefinedInvocation(
  String name,
  DartType _type,
) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeDotShorthandsUndefinedInvocation,
    problemMessage:
        """The static method or constructor '${name}' isn't defined for the type '${type}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try correcting the name to the name of an existing static method or constructor, or defining a static method or constructor named '${name}'.""",
    arguments: {'name': name, 'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, DartType _type2)>
codeFfiDartTypeMismatch =
    const Template<Message Function(DartType _type, DartType _type2)>(
      "FfiDartTypeMismatch",
      problemMessageTemplate:
          r"""Expected '#type' to be a subtype of '#type2'.""",
      withArgumentsOld: _withArgumentsOldFfiDartTypeMismatch,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldFfiDartTypeMismatch(DartType _type, DartType _type2) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeFfiDartTypeMismatch,
    problemMessage:
        """Expected '${type}' to be a subtype of '${type2}'.""" +
        labeler.originMessages,
    arguments: {'type': _type, 'type2': _type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type)>
codeFfiExpectedExceptionalReturn = const Template<Message Function(DartType _type)>(
  "FfiExpectedExceptionalReturn",
  problemMessageTemplate:
      r"""Expected an exceptional return value for a native callback returning '#type'.""",
  withArgumentsOld: _withArgumentsOldFfiExpectedExceptionalReturn,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldFfiExpectedExceptionalReturn(DartType _type) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeFfiExpectedExceptionalReturn,
    problemMessage:
        """Expected an exceptional return value for a native callback returning '${type}'.""" +
        labeler.originMessages,
    arguments: {'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type)>
codeFfiExpectedNoExceptionalReturn =
    const Template<Message Function(DartType _type)>(
      "FfiExpectedNoExceptionalReturn",
      problemMessageTemplate:
          r"""Exceptional return value cannot be provided for a native callback returning '#type'.""",
      withArgumentsOld: _withArgumentsOldFfiExpectedNoExceptionalReturn,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldFfiExpectedNoExceptionalReturn(DartType _type) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeFfiExpectedNoExceptionalReturn,
    problemMessage:
        """Exceptional return value cannot be provided for a native callback returning '${type}'.""" +
        labeler.originMessages,
    arguments: {'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type)>
codeFfiNativeCallableListenerReturnVoid =
    const Template<Message Function(DartType _type)>(
      "FfiNativeCallableListenerReturnVoid",
      problemMessageTemplate:
          r"""The return type of the function passed to NativeCallable.listener must be void rather than '#type'.""",
      withArgumentsOld: _withArgumentsOldFfiNativeCallableListenerReturnVoid,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldFfiNativeCallableListenerReturnVoid(DartType _type) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeFfiNativeCallableListenerReturnVoid,
    problemMessage:
        """The return type of the function passed to NativeCallable.listener must be void rather than '${type}'.""" +
        labeler.originMessages,
    arguments: {'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type)>
codeFfiTypeInvalid = const Template<Message Function(DartType _type)>(
  "FfiTypeInvalid",
  problemMessageTemplate:
      r"""Expected type '#type' to be a valid and instantiated subtype of 'NativeType'.""",
  withArgumentsOld: _withArgumentsOldFfiTypeInvalid,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldFfiTypeInvalid(DartType _type) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeFfiTypeInvalid,
    problemMessage:
        """Expected type '${type}' to be a valid and instantiated subtype of 'NativeType'.""" +
        labeler.originMessages,
    arguments: {'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType _type, DartType _type2, DartType _type3)
>
codeFfiTypeMismatch =
    const Template<
      Message Function(DartType _type, DartType _type2, DartType _type3)
    >(
      "FfiTypeMismatch",
      problemMessageTemplate:
          r"""Expected type '#type' to be '#type2', which is the Dart type corresponding to '#type3'.""",
      withArgumentsOld: _withArgumentsOldFfiTypeMismatch,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldFfiTypeMismatch(
  DartType _type,
  DartType _type2,
  DartType _type3,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  List<Object> type3Parts = labeler.labelType(_type3);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  String type3 = type3Parts.join();
  return new Message(
    codeFfiTypeMismatch,
    problemMessage:
        """Expected type '${type}' to be '${type2}', which is the Dart type corresponding to '${type3}'.""" +
        labeler.originMessages,
    arguments: {'type': _type, 'type2': _type2, 'type3': _type3},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, DartType _type)>
codeFieldNonNullableNotInitializedByConstructorError =
    const Template<Message Function(String name, DartType _type)>(
      "FieldNonNullableNotInitializedByConstructorError",
      problemMessageTemplate:
          r"""This constructor should initialize field '#name' because its type '#type' doesn't allow null.""",
      withArgumentsOld:
          _withArgumentsOldFieldNonNullableNotInitializedByConstructorError,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldFieldNonNullableNotInitializedByConstructorError(
  String name,
  DartType _type,
) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeFieldNonNullableNotInitializedByConstructorError,
    problemMessage:
        """This constructor should initialize field '${name}' because its type '${type}' doesn't allow null.""" +
        labeler.originMessages,
    arguments: {'name': name, 'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, DartType _type)>
codeFieldNonNullableWithoutInitializerError =
    const Template<Message Function(String name, DartType _type)>(
      "FieldNonNullableWithoutInitializerError",
      problemMessageTemplate:
          r"""Field '#name' should be initialized because its type '#type' doesn't allow null.""",
      withArgumentsOld:
          _withArgumentsOldFieldNonNullableWithoutInitializerError,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldFieldNonNullableWithoutInitializerError(
  String name,
  DartType _type,
) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeFieldNonNullableWithoutInitializerError,
    problemMessage:
        """Field '${name}' should be initialized because its type '${type}' doesn't allow null.""" +
        labeler.originMessages,
    arguments: {'name': name, 'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, DartType _type2)>
codeForInLoopElementTypeNotAssignable =
    const Template<Message Function(DartType _type, DartType _type2)>(
      "ForInLoopElementTypeNotAssignable",
      problemMessageTemplate:
          r"""A value of type '#type' can't be assigned to a variable of type '#type2'.""",
      correctionMessageTemplate: r"""Try changing the type of the variable.""",
      withArgumentsOld: _withArgumentsOldForInLoopElementTypeNotAssignable,
      analyzerCodes: <String>["FOR_IN_OF_INVALID_ELEMENT_TYPE"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldForInLoopElementTypeNotAssignable(
  DartType _type,
  DartType _type2,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeForInLoopElementTypeNotAssignable,
    problemMessage:
        """A value of type '${type}' can't be assigned to a variable of type '${type2}'.""" +
        labeler.originMessages,
    correctionMessage: """Try changing the type of the variable.""",
    arguments: {'type': _type, 'type2': _type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, DartType _type2)>
codeForInLoopTypeNotIterable =
    const Template<Message Function(DartType _type, DartType _type2)>(
      "ForInLoopTypeNotIterable",
      problemMessageTemplate:
          r"""The type '#type' used in the 'for' loop must implement '#type2'.""",
      withArgumentsOld: _withArgumentsOldForInLoopTypeNotIterable,
      analyzerCodes: <String>["FOR_IN_OF_INVALID_TYPE"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldForInLoopTypeNotIterable(
  DartType _type,
  DartType _type2,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeForInLoopTypeNotIterable,
    problemMessage:
        """The type '${type}' used in the 'for' loop must implement '${type2}'.""" +
        labeler.originMessages,
    arguments: {'type': _type, 'type2': _type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, DartType _type2)>
codeGenericFunctionTypeAsTypeArgumentThroughTypedef =
    const Template<Message Function(DartType _type, DartType _type2)>(
      "GenericFunctionTypeAsTypeArgumentThroughTypedef",
      problemMessageTemplate:
          r"""Generic function type '#type' used as a type argument through typedef '#type2'.""",
      correctionMessageTemplate:
          r"""Try providing a non-generic function type explicitly.""",
      withArgumentsOld:
          _withArgumentsOldGenericFunctionTypeAsTypeArgumentThroughTypedef,
      analyzerCodes: <String>["GENERIC_FUNCTION_CANNOT_BE_TYPE_ARGUMENT"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldGenericFunctionTypeAsTypeArgumentThroughTypedef(
  DartType _type,
  DartType _type2,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeGenericFunctionTypeAsTypeArgumentThroughTypedef,
    problemMessage:
        """Generic function type '${type}' used as a type argument through typedef '${type2}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try providing a non-generic function type explicitly.""",
    arguments: {'type': _type, 'type2': _type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type)>
codeGenericFunctionTypeInferredAsActualTypeArgument =
    const Template<Message Function(DartType _type)>(
      "GenericFunctionTypeInferredAsActualTypeArgument",
      problemMessageTemplate:
          r"""Generic function type '#type' inferred as a type argument.""",
      correctionMessageTemplate:
          r"""Try providing a non-generic function type explicitly.""",
      withArgumentsOld:
          _withArgumentsOldGenericFunctionTypeInferredAsActualTypeArgument,
      analyzerCodes: <String>["GENERIC_FUNCTION_CANNOT_BE_TYPE_ARGUMENT"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldGenericFunctionTypeInferredAsActualTypeArgument(
  DartType _type,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeGenericFunctionTypeInferredAsActualTypeArgument,
    problemMessage:
        """Generic function type '${type}' inferred as a type argument.""" +
        labeler.originMessages,
    correctionMessage:
        """Try providing a non-generic function type explicitly.""",
    arguments: {'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type)>
codeImplicitCallOfNonMethod = const Template<Message Function(DartType _type)>(
  "ImplicitCallOfNonMethod",
  problemMessageTemplate:
      r"""Cannot invoke an instance of '#type' because it declares 'call' to be something other than a method.""",
  correctionMessageTemplate:
      r"""Try changing 'call' to a method or explicitly invoke 'call'.""",
  withArgumentsOld: _withArgumentsOldImplicitCallOfNonMethod,
  analyzerCodes: <String>["IMPLICIT_CALL_OF_NON_METHOD"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldImplicitCallOfNonMethod(DartType _type) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeImplicitCallOfNonMethod,
    problemMessage:
        """Cannot invoke an instance of '${type}' because it declares 'call' to be something other than a method.""" +
        labeler.originMessages,
    correctionMessage:
        """Try changing 'call' to a method or explicitly invoke 'call'.""",
    arguments: {'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type)>
codeImplicitReturnNull = const Template<Message Function(DartType _type)>(
  "ImplicitReturnNull",
  problemMessageTemplate:
      r"""A non-null value must be returned since the return type '#type' doesn't allow null.""",
  withArgumentsOld: _withArgumentsOldImplicitReturnNull,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldImplicitReturnNull(DartType _type) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeImplicitReturnNull,
    problemMessage:
        """A non-null value must be returned since the return type '${type}' doesn't allow null.""" +
        labeler.originMessages,
    arguments: {'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, DartType _type2)>
codeIncompatibleRedirecteeFunctionType =
    const Template<Message Function(DartType _type, DartType _type2)>(
      "IncompatibleRedirecteeFunctionType",
      problemMessageTemplate:
          r"""The constructor function type '#type' isn't a subtype of '#type2'.""",
      withArgumentsOld: _withArgumentsOldIncompatibleRedirecteeFunctionType,
      analyzerCodes: <String>["REDIRECT_TO_INVALID_TYPE"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldIncompatibleRedirecteeFunctionType(
  DartType _type,
  DartType _type2,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeIncompatibleRedirecteeFunctionType,
    problemMessage:
        """The constructor function type '${type}' isn't a subtype of '${type2}'.""" +
        labeler.originMessages,
    arguments: {'type': _type, 'type2': _type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType _type, DartType _type2, String name, String name2)
>
codeIncorrectTypeArgument =
    const Template<
      Message Function(
        DartType _type,
        DartType _type2,
        String name,
        String name2,
      )
    >(
      "IncorrectTypeArgument",
      problemMessageTemplate:
          r"""Type argument '#type' doesn't conform to the bound '#type2' of the type variable '#name' on '#name2'.""",
      correctionMessageTemplate:
          r"""Try changing type arguments so that they conform to the bounds.""",
      withArgumentsOld: _withArgumentsOldIncorrectTypeArgument,
      analyzerCodes: <String>["TYPE_ARGUMENT_NOT_MATCHING_BOUNDS"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldIncorrectTypeArgument(
  DartType _type,
  DartType _type2,
  String name,
  String name2,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeIncorrectTypeArgument,
    problemMessage:
        """Type argument '${type}' doesn't conform to the bound '${type2}' of the type variable '${name}' on '${name2}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try changing type arguments so that they conform to the bounds.""",
    arguments: {'type': _type, 'type2': _type2, 'name': name, 'name2': name2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType _type, DartType _type2, String name, String name2)
>
codeIncorrectTypeArgumentInferred =
    const Template<
      Message Function(
        DartType _type,
        DartType _type2,
        String name,
        String name2,
      )
    >(
      "IncorrectTypeArgumentInferred",
      problemMessageTemplate:
          r"""Inferred type argument '#type' doesn't conform to the bound '#type2' of the type variable '#name' on '#name2'.""",
      correctionMessageTemplate:
          r"""Try specifying type arguments explicitly so that they conform to the bounds.""",
      withArgumentsOld: _withArgumentsOldIncorrectTypeArgumentInferred,
      analyzerCodes: <String>["TYPE_ARGUMENT_NOT_MATCHING_BOUNDS"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldIncorrectTypeArgumentInferred(
  DartType _type,
  DartType _type2,
  String name,
  String name2,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeIncorrectTypeArgumentInferred,
    problemMessage:
        """Inferred type argument '${type}' doesn't conform to the bound '${type2}' of the type variable '${name}' on '${name2}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try specifying type arguments explicitly so that they conform to the bounds.""",
    arguments: {'type': _type, 'type2': _type2, 'name': name, 'name2': name2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(
    DartType _type,
    DartType _type2,
    String name,
    DartType _type3,
  )
>
codeIncorrectTypeArgumentInstantiation =
    const Template<
      Message Function(
        DartType _type,
        DartType _type2,
        String name,
        DartType _type3,
      )
    >(
      "IncorrectTypeArgumentInstantiation",
      problemMessageTemplate:
          r"""Type argument '#type' doesn't conform to the bound '#type2' of the type variable '#name' on '#type3'.""",
      correctionMessageTemplate:
          r"""Try changing type arguments so that they conform to the bounds.""",
      withArgumentsOld: _withArgumentsOldIncorrectTypeArgumentInstantiation,
      analyzerCodes: <String>["TYPE_ARGUMENT_NOT_MATCHING_BOUNDS"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldIncorrectTypeArgumentInstantiation(
  DartType _type,
  DartType _type2,
  String name,
  DartType _type3,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  List<Object> type3Parts = labeler.labelType(_type3);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  String type3 = type3Parts.join();
  return new Message(
    codeIncorrectTypeArgumentInstantiation,
    problemMessage:
        """Type argument '${type}' doesn't conform to the bound '${type2}' of the type variable '${name}' on '${type3}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try changing type arguments so that they conform to the bounds.""",
    arguments: {'type': _type, 'type2': _type2, 'name': name, 'type3': _type3},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(
    DartType _type,
    DartType _type2,
    String name,
    DartType _type3,
  )
>
codeIncorrectTypeArgumentInstantiationInferred =
    const Template<
      Message Function(
        DartType _type,
        DartType _type2,
        String name,
        DartType _type3,
      )
    >(
      "IncorrectTypeArgumentInstantiationInferred",
      problemMessageTemplate:
          r"""Inferred type argument '#type' doesn't conform to the bound '#type2' of the type variable '#name' on '#type3'.""",
      correctionMessageTemplate:
          r"""Try specifying type arguments explicitly so that they conform to the bounds.""",
      withArgumentsOld:
          _withArgumentsOldIncorrectTypeArgumentInstantiationInferred,
      analyzerCodes: <String>["TYPE_ARGUMENT_NOT_MATCHING_BOUNDS"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldIncorrectTypeArgumentInstantiationInferred(
  DartType _type,
  DartType _type2,
  String name,
  DartType _type3,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  List<Object> type3Parts = labeler.labelType(_type3);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  String type3 = type3Parts.join();
  return new Message(
    codeIncorrectTypeArgumentInstantiationInferred,
    problemMessage:
        """Inferred type argument '${type}' doesn't conform to the bound '${type2}' of the type variable '${name}' on '${type3}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try specifying type arguments explicitly so that they conform to the bounds.""",
    arguments: {'type': _type, 'type2': _type2, 'name': name, 'type3': _type3},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(
    DartType _type,
    DartType _type2,
    String name,
    DartType _type3,
    String name2,
  )
>
codeIncorrectTypeArgumentQualified =
    const Template<
      Message Function(
        DartType _type,
        DartType _type2,
        String name,
        DartType _type3,
        String name2,
      )
    >(
      "IncorrectTypeArgumentQualified",
      problemMessageTemplate:
          r"""Type argument '#type' doesn't conform to the bound '#type2' of the type variable '#name' on '#type3.#name2'.""",
      correctionMessageTemplate:
          r"""Try changing type arguments so that they conform to the bounds.""",
      withArgumentsOld: _withArgumentsOldIncorrectTypeArgumentQualified,
      analyzerCodes: <String>["TYPE_ARGUMENT_NOT_MATCHING_BOUNDS"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldIncorrectTypeArgumentQualified(
  DartType _type,
  DartType _type2,
  String name,
  DartType _type3,
  String name2,
) {
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
  return new Message(
    codeIncorrectTypeArgumentQualified,
    problemMessage:
        """Type argument '${type}' doesn't conform to the bound '${type2}' of the type variable '${name}' on '${type3}.${name2}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try changing type arguments so that they conform to the bounds.""",
    arguments: {
      'type': _type,
      'type2': _type2,
      'name': name,
      'type3': _type3,
      'name2': name2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(
    DartType _type,
    DartType _type2,
    String name,
    DartType _type3,
    String name2,
  )
>
codeIncorrectTypeArgumentQualifiedInferred =
    const Template<
      Message Function(
        DartType _type,
        DartType _type2,
        String name,
        DartType _type3,
        String name2,
      )
    >(
      "IncorrectTypeArgumentQualifiedInferred",
      problemMessageTemplate:
          r"""Inferred type argument '#type' doesn't conform to the bound '#type2' of the type variable '#name' on '#type3.#name2'.""",
      correctionMessageTemplate:
          r"""Try specifying type arguments explicitly so that they conform to the bounds.""",
      withArgumentsOld: _withArgumentsOldIncorrectTypeArgumentQualifiedInferred,
      analyzerCodes: <String>["TYPE_ARGUMENT_NOT_MATCHING_BOUNDS"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldIncorrectTypeArgumentQualifiedInferred(
  DartType _type,
  DartType _type2,
  String name,
  DartType _type3,
  String name2,
) {
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
  return new Message(
    codeIncorrectTypeArgumentQualifiedInferred,
    problemMessage:
        """Inferred type argument '${type}' doesn't conform to the bound '${type2}' of the type variable '${name}' on '${type3}.${name2}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try specifying type arguments explicitly so that they conform to the bounds.""",
    arguments: {
      'type': _type,
      'type2': _type2,
      'name': name,
      'type3': _type3,
      'name2': name2,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(int count, int count2, DartType _type)>
codeIndexOutOfBoundInRecordIndexGet =
    const Template<Message Function(int count, int count2, DartType _type)>(
      "IndexOutOfBoundInRecordIndexGet",
      problemMessageTemplate:
          r"""Index #count is out of range 0..#count2 of positional fields of records #type.""",
      withArgumentsOld: _withArgumentsOldIndexOutOfBoundInRecordIndexGet,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldIndexOutOfBoundInRecordIndexGet(
  int count,
  int count2,
  DartType _type,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeIndexOutOfBoundInRecordIndexGet,
    problemMessage:
        """Index ${count} is out of range 0..${count2} of positional fields of records ${type}.""" +
        labeler.originMessages,
    arguments: {'count': count, 'count2': count2, 'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, DartType _type, DartType _type2)>
codeInitializingFormalTypeMismatch =
    const Template<
      Message Function(String name, DartType _type, DartType _type2)
    >(
      "InitializingFormalTypeMismatch",
      problemMessageTemplate:
          r"""The type of parameter '#name', '#type' is not a subtype of the corresponding field's type, '#type2'.""",
      correctionMessageTemplate:
          r"""Try changing the type of parameter '#name' to a subtype of '#type2'.""",
      withArgumentsOld: _withArgumentsOldInitializingFormalTypeMismatch,
      analyzerCodes: <String>["INVALID_PARAMETER_DECLARATION"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInitializingFormalTypeMismatch(
  String name,
  DartType _type,
  DartType _type2,
) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeInitializingFormalTypeMismatch,
    problemMessage:
        """The type of parameter '${name}', '${type}' is not a subtype of the corresponding field's type, '${type2}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try changing the type of parameter '${name}' to a subtype of '${type2}'.""",
    arguments: {'name': name, 'type': _type, 'type2': _type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type)>
codeInstantiationNonGenericFunctionType =
    const Template<Message Function(DartType _type)>(
      "InstantiationNonGenericFunctionType",
      problemMessageTemplate:
          r"""The static type of the explicit instantiation operand must be a generic function type but is '#type'.""",
      correctionMessageTemplate:
          r"""Try changing the operand or remove the type arguments.""",
      withArgumentsOld: _withArgumentsOldInstantiationNonGenericFunctionType,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInstantiationNonGenericFunctionType(DartType _type) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeInstantiationNonGenericFunctionType,
    problemMessage:
        """The static type of the explicit instantiation operand must be a generic function type but is '${type}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try changing the operand or remove the type arguments.""",
    arguments: {'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type)>
codeInstantiationNullableGenericFunctionType =
    const Template<Message Function(DartType _type)>(
      "InstantiationNullableGenericFunctionType",
      problemMessageTemplate:
          r"""The static type of the explicit instantiation operand must be a non-null generic function type but is '#type'.""",
      correctionMessageTemplate:
          r"""Try changing the operand or remove the type arguments.""",
      withArgumentsOld:
          _withArgumentsOldInstantiationNullableGenericFunctionType,
      analyzerCodes: <String>["DISALLOWED_TYPE_INSTANTIATION_EXPRESSION"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInstantiationNullableGenericFunctionType(
  DartType _type,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeInstantiationNullableGenericFunctionType,
    problemMessage:
        """The static type of the explicit instantiation operand must be a non-null generic function type but is '${type}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try changing the operand or remove the type arguments.""",
    arguments: {'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string, DartType _type)>
codeInternalProblemUnsupportedNullability =
    const Template<Message Function(String string, DartType _type)>(
      "InternalProblemUnsupportedNullability",
      problemMessageTemplate:
          r"""Unsupported nullability value '#string' on type '#type'.""",
      withArgumentsOld: _withArgumentsOldInternalProblemUnsupportedNullability,
      severity: CfeSeverity.internalProblem,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInternalProblemUnsupportedNullability(
  String string,
  DartType _type,
) {
  if (string.isEmpty) throw 'No string provided';
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeInternalProblemUnsupportedNullability,
    problemMessage:
        """Unsupported nullability value '${string}' on type '${type}'.""" +
        labeler.originMessages,
    arguments: {'string': string, 'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, DartType _type2)>
codeInvalidAssignmentError =
    const Template<Message Function(DartType _type, DartType _type2)>(
      "InvalidAssignmentError",
      problemMessageTemplate:
          r"""A value of type '#type' can't be assigned to a variable of type '#type2'.""",
      withArgumentsOld: _withArgumentsOldInvalidAssignmentError,
      analyzerCodes: <String>["INVALID_ASSIGNMENT"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidAssignmentError(
  DartType _type,
  DartType _type2,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeInvalidAssignmentError,
    problemMessage:
        """A value of type '${type}' can't be assigned to a variable of type '${type2}'.""" +
        labeler.originMessages,
    arguments: {'type': _type, 'type2': _type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, DartType _type2)>
codeInvalidCastFunctionExpr =
    const Template<Message Function(DartType _type, DartType _type2)>(
      "InvalidCastFunctionExpr",
      problemMessageTemplate:
          r"""The function expression type '#type' isn't of expected type '#type2'.""",
      correctionMessageTemplate:
          r"""Change the type of the function expression or the context in which it is used.""",
      withArgumentsOld: _withArgumentsOldInvalidCastFunctionExpr,
      analyzerCodes: <String>["INVALID_CAST_FUNCTION_EXPR"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidCastFunctionExpr(
  DartType _type,
  DartType _type2,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeInvalidCastFunctionExpr,
    problemMessage:
        """The function expression type '${type}' isn't of expected type '${type2}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Change the type of the function expression or the context in which it is used.""",
    arguments: {'type': _type, 'type2': _type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, DartType _type2)>
codeInvalidCastLiteralList =
    const Template<Message Function(DartType _type, DartType _type2)>(
      "InvalidCastLiteralList",
      problemMessageTemplate:
          r"""The list literal type '#type' isn't of expected type '#type2'.""",
      correctionMessageTemplate:
          r"""Change the type of the list literal or the context in which it is used.""",
      withArgumentsOld: _withArgumentsOldInvalidCastLiteralList,
      analyzerCodes: <String>["INVALID_CAST_LITERAL_LIST"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidCastLiteralList(
  DartType _type,
  DartType _type2,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeInvalidCastLiteralList,
    problemMessage:
        """The list literal type '${type}' isn't of expected type '${type2}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Change the type of the list literal or the context in which it is used.""",
    arguments: {'type': _type, 'type2': _type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, DartType _type2)>
codeInvalidCastLiteralMap =
    const Template<Message Function(DartType _type, DartType _type2)>(
      "InvalidCastLiteralMap",
      problemMessageTemplate:
          r"""The map literal type '#type' isn't of expected type '#type2'.""",
      correctionMessageTemplate:
          r"""Change the type of the map literal or the context in which it is used.""",
      withArgumentsOld: _withArgumentsOldInvalidCastLiteralMap,
      analyzerCodes: <String>["INVALID_CAST_LITERAL_MAP"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidCastLiteralMap(
  DartType _type,
  DartType _type2,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeInvalidCastLiteralMap,
    problemMessage:
        """The map literal type '${type}' isn't of expected type '${type2}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Change the type of the map literal or the context in which it is used.""",
    arguments: {'type': _type, 'type2': _type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, DartType _type2)>
codeInvalidCastLiteralSet =
    const Template<Message Function(DartType _type, DartType _type2)>(
      "InvalidCastLiteralSet",
      problemMessageTemplate:
          r"""The set literal type '#type' isn't of expected type '#type2'.""",
      correctionMessageTemplate:
          r"""Change the type of the set literal or the context in which it is used.""",
      withArgumentsOld: _withArgumentsOldInvalidCastLiteralSet,
      analyzerCodes: <String>["INVALID_CAST_LITERAL_SET"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidCastLiteralSet(
  DartType _type,
  DartType _type2,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeInvalidCastLiteralSet,
    problemMessage:
        """The set literal type '${type}' isn't of expected type '${type2}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Change the type of the set literal or the context in which it is used.""",
    arguments: {'type': _type, 'type2': _type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, DartType _type2)>
codeInvalidCastLocalFunction =
    const Template<Message Function(DartType _type, DartType _type2)>(
      "InvalidCastLocalFunction",
      problemMessageTemplate:
          r"""The local function has type '#type' that isn't of expected type '#type2'.""",
      correctionMessageTemplate:
          r"""Change the type of the function or the context in which it is used.""",
      withArgumentsOld: _withArgumentsOldInvalidCastLocalFunction,
      analyzerCodes: <String>["INVALID_CAST_FUNCTION"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidCastLocalFunction(
  DartType _type,
  DartType _type2,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeInvalidCastLocalFunction,
    problemMessage:
        """The local function has type '${type}' that isn't of expected type '${type2}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Change the type of the function or the context in which it is used.""",
    arguments: {'type': _type, 'type2': _type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, DartType _type2)>
codeInvalidCastNewExpr =
    const Template<Message Function(DartType _type, DartType _type2)>(
      "InvalidCastNewExpr",
      problemMessageTemplate:
          r"""The constructor returns type '#type' that isn't of expected type '#type2'.""",
      correctionMessageTemplate:
          r"""Change the type of the object being constructed or the context in which it is used.""",
      withArgumentsOld: _withArgumentsOldInvalidCastNewExpr,
      analyzerCodes: <String>["INVALID_CAST_NEW_EXPR"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidCastNewExpr(DartType _type, DartType _type2) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeInvalidCastNewExpr,
    problemMessage:
        """The constructor returns type '${type}' that isn't of expected type '${type2}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Change the type of the object being constructed or the context in which it is used.""",
    arguments: {'type': _type, 'type2': _type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, DartType _type2)>
codeInvalidCastStaticMethod =
    const Template<Message Function(DartType _type, DartType _type2)>(
      "InvalidCastStaticMethod",
      problemMessageTemplate:
          r"""The static method has type '#type' that isn't of expected type '#type2'.""",
      correctionMessageTemplate:
          r"""Change the type of the method or the context in which it is used.""",
      withArgumentsOld: _withArgumentsOldInvalidCastStaticMethod,
      analyzerCodes: <String>["INVALID_CAST_METHOD"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidCastStaticMethod(
  DartType _type,
  DartType _type2,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeInvalidCastStaticMethod,
    problemMessage:
        """The static method has type '${type}' that isn't of expected type '${type2}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Change the type of the method or the context in which it is used.""",
    arguments: {'type': _type, 'type2': _type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, DartType _type2)>
codeInvalidCastTopLevelFunction =
    const Template<Message Function(DartType _type, DartType _type2)>(
      "InvalidCastTopLevelFunction",
      problemMessageTemplate:
          r"""The top level function has type '#type' that isn't of expected type '#type2'.""",
      correctionMessageTemplate:
          r"""Change the type of the function or the context in which it is used.""",
      withArgumentsOld: _withArgumentsOldInvalidCastTopLevelFunction,
      analyzerCodes: <String>["INVALID_CAST_FUNCTION"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidCastTopLevelFunction(
  DartType _type,
  DartType _type2,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeInvalidCastTopLevelFunction,
    problemMessage:
        """The top level function has type '${type}' that isn't of expected type '${type2}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Change the type of the function or the context in which it is used.""",
    arguments: {'type': _type, 'type2': _type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(
    DartType _type,
    String name,
    DartType _type2,
    DartType _type3,
  )
>
codeInvalidExtensionTypeSuperExtensionType =
    const Template<
      Message Function(
        DartType _type,
        String name,
        DartType _type2,
        DartType _type3,
      )
    >(
      "InvalidExtensionTypeSuperExtensionType",
      problemMessageTemplate:
          r"""The representation type '#type' of extension type '#name' must be either a subtype of the representation type '#type2' of the implemented extension type '#type3' or a subtype of '#type3' itself.""",
      correctionMessageTemplate:
          r"""Try changing the representation type to a subtype of '#type2'.""",
      withArgumentsOld: _withArgumentsOldInvalidExtensionTypeSuperExtensionType,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidExtensionTypeSuperExtensionType(
  DartType _type,
  String name,
  DartType _type2,
  DartType _type3,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  List<Object> type2Parts = labeler.labelType(_type2);
  List<Object> type3Parts = labeler.labelType(_type3);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  String type3 = type3Parts.join();
  return new Message(
    codeInvalidExtensionTypeSuperExtensionType,
    problemMessage:
        """The representation type '${type}' of extension type '${name}' must be either a subtype of the representation type '${type2}' of the implemented extension type '${type3}' or a subtype of '${type3}' itself.""" +
        labeler.originMessages,
    correctionMessage:
        """Try changing the representation type to a subtype of '${type2}'.""",
    arguments: {'type': _type, 'name': name, 'type2': _type2, 'type3': _type3},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, DartType _type2, String name)>
codeInvalidExtensionTypeSuperInterface =
    const Template<
      Message Function(DartType _type, DartType _type2, String name)
    >(
      "InvalidExtensionTypeSuperInterface",
      problemMessageTemplate:
          r"""The implemented interface '#type' must be a supertype of the representation type '#type2' of extension type '#name'.""",
      correctionMessageTemplate:
          r"""Try changing the interface type to a supertype of '#type2' or the representation type to a subtype of '#type'.""",
      withArgumentsOld: _withArgumentsOldInvalidExtensionTypeSuperInterface,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidExtensionTypeSuperInterface(
  DartType _type,
  DartType _type2,
  String name,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeInvalidExtensionTypeSuperInterface,
    problemMessage:
        """The implemented interface '${type}' must be a supertype of the representation type '${type2}' of extension type '${name}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try changing the interface type to a supertype of '${type2}' or the representation type to a subtype of '${type}'.""",
    arguments: {'type': _type, 'type2': _type2, 'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType _type, String name, DartType _type2, String name2)
>
codeInvalidGetterSetterType =
    const Template<
      Message Function(
        DartType _type,
        String name,
        DartType _type2,
        String name2,
      )
    >(
      "InvalidGetterSetterType",
      problemMessageTemplate:
          r"""The type '#type' of the getter '#name' is not a subtype of the type '#type2' of the setter '#name2'.""",
      withArgumentsOld: _withArgumentsOldInvalidGetterSetterType,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidGetterSetterType(
  DartType _type,
  String name,
  DartType _type2,
  String name2,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  List<Object> type2Parts = labeler.labelType(_type2);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeInvalidGetterSetterType,
    problemMessage:
        """The type '${type}' of the getter '${name}' is not a subtype of the type '${type2}' of the setter '${name2}'.""" +
        labeler.originMessages,
    arguments: {'type': _type, 'name': name, 'type2': _type2, 'name2': name2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType _type, String name, DartType _type2, String name2)
>
codeInvalidGetterSetterTypeBothInheritedField =
    const Template<
      Message Function(
        DartType _type,
        String name,
        DartType _type2,
        String name2,
      )
    >(
      "InvalidGetterSetterTypeBothInheritedField",
      problemMessageTemplate:
          r"""The type '#type' of the inherited field '#name' is not a subtype of the type '#type2' of the inherited setter '#name2'.""",
      withArgumentsOld:
          _withArgumentsOldInvalidGetterSetterTypeBothInheritedField,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidGetterSetterTypeBothInheritedField(
  DartType _type,
  String name,
  DartType _type2,
  String name2,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  List<Object> type2Parts = labeler.labelType(_type2);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeInvalidGetterSetterTypeBothInheritedField,
    problemMessage:
        """The type '${type}' of the inherited field '${name}' is not a subtype of the type '${type2}' of the inherited setter '${name2}'.""" +
        labeler.originMessages,
    arguments: {'type': _type, 'name': name, 'type2': _type2, 'name2': name2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType _type, String name, DartType _type2, String name2)
>
codeInvalidGetterSetterTypeBothInheritedGetter =
    const Template<
      Message Function(
        DartType _type,
        String name,
        DartType _type2,
        String name2,
      )
    >(
      "InvalidGetterSetterTypeBothInheritedGetter",
      problemMessageTemplate:
          r"""The type '#type' of the inherited getter '#name' is not a subtype of the type '#type2' of the inherited setter '#name2'.""",
      withArgumentsOld:
          _withArgumentsOldInvalidGetterSetterTypeBothInheritedGetter,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidGetterSetterTypeBothInheritedGetter(
  DartType _type,
  String name,
  DartType _type2,
  String name2,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  List<Object> type2Parts = labeler.labelType(_type2);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeInvalidGetterSetterTypeBothInheritedGetter,
    problemMessage:
        """The type '${type}' of the inherited getter '${name}' is not a subtype of the type '${type2}' of the inherited setter '${name2}'.""" +
        labeler.originMessages,
    arguments: {'type': _type, 'name': name, 'type2': _type2, 'name2': name2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType _type, String name, DartType _type2, String name2)
>
codeInvalidGetterSetterTypeFieldInherited =
    const Template<
      Message Function(
        DartType _type,
        String name,
        DartType _type2,
        String name2,
      )
    >(
      "InvalidGetterSetterTypeFieldInherited",
      problemMessageTemplate:
          r"""The type '#type' of the inherited field '#name' is not a subtype of the type '#type2' of the setter '#name2'.""",
      withArgumentsOld: _withArgumentsOldInvalidGetterSetterTypeFieldInherited,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidGetterSetterTypeFieldInherited(
  DartType _type,
  String name,
  DartType _type2,
  String name2,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  List<Object> type2Parts = labeler.labelType(_type2);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeInvalidGetterSetterTypeFieldInherited,
    problemMessage:
        """The type '${type}' of the inherited field '${name}' is not a subtype of the type '${type2}' of the setter '${name2}'.""" +
        labeler.originMessages,
    arguments: {'type': _type, 'name': name, 'type2': _type2, 'name2': name2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType _type, String name, DartType _type2, String name2)
>
codeInvalidGetterSetterTypeGetterInherited =
    const Template<
      Message Function(
        DartType _type,
        String name,
        DartType _type2,
        String name2,
      )
    >(
      "InvalidGetterSetterTypeGetterInherited",
      problemMessageTemplate:
          r"""The type '#type' of the inherited getter '#name' is not a subtype of the type '#type2' of the setter '#name2'.""",
      withArgumentsOld: _withArgumentsOldInvalidGetterSetterTypeGetterInherited,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidGetterSetterTypeGetterInherited(
  DartType _type,
  String name,
  DartType _type2,
  String name2,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  List<Object> type2Parts = labeler.labelType(_type2);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeInvalidGetterSetterTypeGetterInherited,
    problemMessage:
        """The type '${type}' of the inherited getter '${name}' is not a subtype of the type '${type2}' of the setter '${name2}'.""" +
        labeler.originMessages,
    arguments: {'type': _type, 'name': name, 'type2': _type2, 'name2': name2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType _type, String name, DartType _type2, String name2)
>
codeInvalidGetterSetterTypeSetterInheritedField =
    const Template<
      Message Function(
        DartType _type,
        String name,
        DartType _type2,
        String name2,
      )
    >(
      "InvalidGetterSetterTypeSetterInheritedField",
      problemMessageTemplate:
          r"""The type '#type' of the field '#name' is not a subtype of the type '#type2' of the inherited setter '#name2'.""",
      withArgumentsOld:
          _withArgumentsOldInvalidGetterSetterTypeSetterInheritedField,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidGetterSetterTypeSetterInheritedField(
  DartType _type,
  String name,
  DartType _type2,
  String name2,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  List<Object> type2Parts = labeler.labelType(_type2);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeInvalidGetterSetterTypeSetterInheritedField,
    problemMessage:
        """The type '${type}' of the field '${name}' is not a subtype of the type '${type2}' of the inherited setter '${name2}'.""" +
        labeler.originMessages,
    arguments: {'type': _type, 'name': name, 'type2': _type2, 'name2': name2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType _type, String name, DartType _type2, String name2)
>
codeInvalidGetterSetterTypeSetterInheritedGetter =
    const Template<
      Message Function(
        DartType _type,
        String name,
        DartType _type2,
        String name2,
      )
    >(
      "InvalidGetterSetterTypeSetterInheritedGetter",
      problemMessageTemplate:
          r"""The type '#type' of the getter '#name' is not a subtype of the type '#type2' of the inherited setter '#name2'.""",
      withArgumentsOld:
          _withArgumentsOldInvalidGetterSetterTypeSetterInheritedGetter,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidGetterSetterTypeSetterInheritedGetter(
  DartType _type,
  String name,
  DartType _type2,
  String name2,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  List<Object> type2Parts = labeler.labelType(_type2);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeInvalidGetterSetterTypeSetterInheritedGetter,
    problemMessage:
        """The type '${type}' of the getter '${name}' is not a subtype of the type '${type2}' of the inherited setter '${name2}'.""" +
        labeler.originMessages,
    arguments: {'type': _type, 'name': name, 'type2': _type2, 'name2': name2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, DartType _type2)>
codeInvalidReturn =
    const Template<Message Function(DartType _type, DartType _type2)>(
      "InvalidReturn",
      problemMessageTemplate:
          r"""A value of type '#type' can't be returned from a function with return type '#type2'.""",
      withArgumentsOld: _withArgumentsOldInvalidReturn,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidReturn(DartType _type, DartType _type2) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeInvalidReturn,
    problemMessage:
        """A value of type '${type}' can't be returned from a function with return type '${type2}'.""" +
        labeler.originMessages,
    arguments: {'type': _type, 'type2': _type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, DartType _type2)>
codeInvalidReturnAsync =
    const Template<Message Function(DartType _type, DartType _type2)>(
      "InvalidReturnAsync",
      problemMessageTemplate:
          r"""A value of type '#type' can't be returned from an async function with return type '#type2'.""",
      withArgumentsOld: _withArgumentsOldInvalidReturnAsync,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidReturnAsync(DartType _type, DartType _type2) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeInvalidReturnAsync,
    problemMessage:
        """A value of type '${type}' can't be returned from an async function with return type '${type2}'.""" +
        labeler.originMessages,
    arguments: {'type': _type, 'type2': _type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type)>
codeJsInteropExportInvalidInteropTypeArgument =
    const Template<Message Function(DartType _type)>(
      "JsInteropExportInvalidInteropTypeArgument",
      problemMessageTemplate:
          r"""Type argument '#type' needs to be a non-JS interop type.""",
      correctionMessageTemplate:
          r"""Use a non-JS interop class that uses `@JSExport` instead.""",
      withArgumentsOld:
          _withArgumentsOldJsInteropExportInvalidInteropTypeArgument,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldJsInteropExportInvalidInteropTypeArgument(
  DartType _type,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeJsInteropExportInvalidInteropTypeArgument,
    problemMessage:
        """Type argument '${type}' needs to be a non-JS interop type.""" +
        labeler.originMessages,
    correctionMessage:
        """Use a non-JS interop class that uses `@JSExport` instead.""",
    arguments: {'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type)>
codeJsInteropExportInvalidTypeArgument =
    const Template<Message Function(DartType _type)>(
      "JsInteropExportInvalidTypeArgument",
      problemMessageTemplate:
          r"""Type argument '#type' needs to be an interface type.""",
      correctionMessageTemplate:
          r"""Use a non-JS interop class that uses `@JSExport` instead.""",
      withArgumentsOld: _withArgumentsOldJsInteropExportInvalidTypeArgument,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldJsInteropExportInvalidTypeArgument(DartType _type) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeJsInteropExportInvalidTypeArgument,
    problemMessage:
        """Type argument '${type}' needs to be an interface type.""" +
        labeler.originMessages,
    correctionMessage:
        """Use a non-JS interop class that uses `@JSExport` instead.""",
    arguments: {'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, DartType _type)>
codeJsInteropExtensionTypeNotInterop =
    const Template<Message Function(String name, DartType _type)>(
      "JsInteropExtensionTypeNotInterop",
      problemMessageTemplate:
          r"""Extension type '#name' is marked with a '@JS' annotation, but its representation type is not a valid JS interop type: '#type'.""",
      correctionMessageTemplate:
          r"""Try declaring a valid JS interop representation type, which may include 'dart:js_interop' types, '@staticInterop' types, 'dart:html' types, or other interop extension types.""",
      withArgumentsOld: _withArgumentsOldJsInteropExtensionTypeNotInterop,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldJsInteropExtensionTypeNotInterop(
  String name,
  DartType _type,
) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeJsInteropExtensionTypeNotInterop,
    problemMessage:
        """Extension type '${name}' is marked with a '@JS' annotation, but its representation type is not a valid JS interop type: '${type}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try declaring a valid JS interop representation type, which may include 'dart:js_interop' types, '@staticInterop' types, 'dart:html' types, or other interop extension types.""",
    arguments: {'name': name, 'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type)>
codeJsInteropFunctionToJSRequiresStaticType =
    const Template<Message Function(DartType _type)>(
      "JsInteropFunctionToJSRequiresStaticType",
      problemMessageTemplate:
          r"""`Function.toJS` requires a statically known function type, but Type '#type' is not a precise function type, e.g., `void Function()`.""",
      correctionMessageTemplate:
          r"""Insert an explicit cast to the expected function type.""",
      withArgumentsOld:
          _withArgumentsOldJsInteropFunctionToJSRequiresStaticType,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldJsInteropFunctionToJSRequiresStaticType(
  DartType _type,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeJsInteropFunctionToJSRequiresStaticType,
    problemMessage:
        """`Function.toJS` requires a statically known function type, but Type '${type}' is not a precise function type, e.g., `void Function()`.""" +
        labeler.originMessages,
    correctionMessage:
        """Insert an explicit cast to the expected function type.""",
    arguments: {'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type)>
codeJsInteropIsAInvalidTypeVariable = const Template<Message Function(DartType _type)>(
  "JsInteropIsAInvalidTypeVariable",
  problemMessageTemplate:
      r"""Type argument '#type' provided to 'isA' cannot be a type variable and must be an interop extension type that can be determined at compile-time.""",
  correctionMessageTemplate:
      r"""Use a valid interop extension type that can be determined at compile-time as the type argument instead.""",
  withArgumentsOld: _withArgumentsOldJsInteropIsAInvalidTypeVariable,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldJsInteropIsAInvalidTypeVariable(DartType _type) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeJsInteropIsAInvalidTypeVariable,
    problemMessage:
        """Type argument '${type}' provided to 'isA' cannot be a type variable and must be an interop extension type that can be determined at compile-time.""" +
        labeler.originMessages,
    correctionMessage:
        """Use a valid interop extension type that can be determined at compile-time as the type argument instead.""",
    arguments: {'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type)>
codeJsInteropIsAObjectLiteralType =
    const Template<Message Function(DartType _type)>(
      "JsInteropIsAObjectLiteralType",
      problemMessageTemplate:
          r"""Type argument '#type' has an object literal constructor. Because 'isA' uses the type's name or '@JS()' rename, this may result in an incorrect type check.""",
      correctionMessageTemplate:
          r"""Use 'JSObject' as the type argument instead.""",
      withArgumentsOld: _withArgumentsOldJsInteropIsAObjectLiteralType,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldJsInteropIsAObjectLiteralType(DartType _type) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeJsInteropIsAObjectLiteralType,
    problemMessage:
        """Type argument '${type}' has an object literal constructor. Because 'isA' uses the type's name or '@JS()' rename, this may result in an incorrect type check.""" +
        labeler.originMessages,
    correctionMessage: """Use 'JSObject' as the type argument instead.""",
    arguments: {'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, String string)>
codeJsInteropIsAPrimitiveExtensionType =
    const Template<Message Function(DartType _type, String string)>(
      "JsInteropIsAPrimitiveExtensionType",
      problemMessageTemplate:
          r"""Type argument '#type' wraps primitive JS type '#string', which is specially handled using 'typeof'.""",
      correctionMessageTemplate:
          r"""Use the primitive JS type '#string' as the type argument instead.""",
      withArgumentsOld: _withArgumentsOldJsInteropIsAPrimitiveExtensionType,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldJsInteropIsAPrimitiveExtensionType(
  DartType _type,
  String string,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  if (string.isEmpty) throw 'No string provided';
  String type = typeParts.join();
  return new Message(
    codeJsInteropIsAPrimitiveExtensionType,
    problemMessage:
        """Type argument '${type}' wraps primitive JS type '${string}', which is specially handled using 'typeof'.""" +
        labeler.originMessages,
    correctionMessage:
        """Use the primitive JS type '${string}' as the type argument instead.""",
    arguments: {'type': _type, 'string': string},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type)>
codeJsInteropStaticInteropExternalAccessorTypeViolation =
    const Template<Message Function(DartType _type)>(
      "JsInteropStaticInteropExternalAccessorTypeViolation",
      problemMessageTemplate:
          r"""External JS interop member contains an invalid type: '#type'.""",
      correctionMessageTemplate:
          r"""Use one of these valid types instead: JS types from 'dart:js_interop', ExternalDartReference, void, bool, num, double, int, String, extension types that erase to one of these types, '@staticInterop' types, 'dart:html' types when compiling to JS, or a type parameter that is a subtype of a valid non-primitive type.""",
      withArgumentsOld:
          _withArgumentsOldJsInteropStaticInteropExternalAccessorTypeViolation,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldJsInteropStaticInteropExternalAccessorTypeViolation(
  DartType _type,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeJsInteropStaticInteropExternalAccessorTypeViolation,
    problemMessage:
        """External JS interop member contains an invalid type: '${type}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Use one of these valid types instead: JS types from 'dart:js_interop', ExternalDartReference, void, bool, num, double, int, String, extension types that erase to one of these types, '@staticInterop' types, 'dart:html' types when compiling to JS, or a type parameter that is a subtype of a valid non-primitive type.""",
    arguments: {'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type)>
codeJsInteropStaticInteropMockNotStaticInteropType =
    const Template<Message Function(DartType _type)>(
      "JsInteropStaticInteropMockNotStaticInteropType",
      problemMessageTemplate:
          r"""Type argument '#type' needs to be a `@staticInterop` type.""",
      correctionMessageTemplate: r"""Use a `@staticInterop` class instead.""",
      withArgumentsOld:
          _withArgumentsOldJsInteropStaticInteropMockNotStaticInteropType,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldJsInteropStaticInteropMockNotStaticInteropType(
  DartType _type,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeJsInteropStaticInteropMockNotStaticInteropType,
    problemMessage:
        """Type argument '${type}' needs to be a `@staticInterop` type.""" +
        labeler.originMessages,
    correctionMessage: """Use a `@staticInterop` class instead.""",
    arguments: {'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type)>
codeJsInteropStaticInteropMockTypeParametersNotAllowed =
    const Template<Message Function(DartType _type)>(
      "JsInteropStaticInteropMockTypeParametersNotAllowed",
      problemMessageTemplate:
          r"""Type argument '#type' has type parameters that do not match their bound. createStaticInteropMock requires instantiating all type parameters to their bound to ensure mocking conformance.""",
      correctionMessageTemplate:
          r"""Remove the type parameter in the type argument or replace it with its bound.""",
      withArgumentsOld:
          _withArgumentsOldJsInteropStaticInteropMockTypeParametersNotAllowed,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldJsInteropStaticInteropMockTypeParametersNotAllowed(
  DartType _type,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeJsInteropStaticInteropMockTypeParametersNotAllowed,
    problemMessage:
        """Type argument '${type}' has type parameters that do not match their bound. createStaticInteropMock requires instantiating all type parameters to their bound to ensure mocking conformance.""" +
        labeler.originMessages,
    correctionMessage:
        """Remove the type parameter in the type argument or replace it with its bound.""",
    arguments: {'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, DartType _type2)>
codeMainWrongParameterType =
    const Template<Message Function(DartType _type, DartType _type2)>(
      "MainWrongParameterType",
      problemMessageTemplate:
          r"""The type '#type' of the first parameter of the 'main' method is not a supertype of '#type2'.""",
      withArgumentsOld: _withArgumentsOldMainWrongParameterType,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldMainWrongParameterType(
  DartType _type,
  DartType _type2,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeMainWrongParameterType,
    problemMessage:
        """The type '${type}' of the first parameter of the 'main' method is not a supertype of '${type2}'.""" +
        labeler.originMessages,
    arguments: {'type': _type, 'type2': _type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, DartType _type2)>
codeMainWrongParameterTypeExported =
    const Template<Message Function(DartType _type, DartType _type2)>(
      "MainWrongParameterTypeExported",
      problemMessageTemplate:
          r"""The type '#type' of the first parameter of the exported 'main' method is not a supertype of '#type2'.""",
      withArgumentsOld: _withArgumentsOldMainWrongParameterTypeExported,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldMainWrongParameterTypeExported(
  DartType _type,
  DartType _type2,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeMainWrongParameterTypeExported,
    problemMessage:
        """The type '${type}' of the first parameter of the exported 'main' method is not a supertype of '${type2}'.""" +
        labeler.originMessages,
    arguments: {'type': _type, 'type2': _type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(DartType _type, DartType _type2, DartType _type3)
>
codeMixinApplicationIncompatibleSupertype =
    const Template<
      Message Function(DartType _type, DartType _type2, DartType _type3)
    >(
      "MixinApplicationIncompatibleSupertype",
      problemMessageTemplate:
          r"""'#type' doesn't implement '#type2' so it can't be used with '#type3'.""",
      withArgumentsOld: _withArgumentsOldMixinApplicationIncompatibleSupertype,
      analyzerCodes: <String>["MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldMixinApplicationIncompatibleSupertype(
  DartType _type,
  DartType _type2,
  DartType _type3,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  List<Object> type3Parts = labeler.labelType(_type3);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  String type3 = type3Parts.join();
  return new Message(
    codeMixinApplicationIncompatibleSupertype,
    problemMessage:
        """'${type}' doesn't implement '${type2}' so it can't be used with '${type3}'.""" +
        labeler.originMessages,
    arguments: {'type': _type, 'type2': _type2, 'type3': _type3},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String name2, DartType _type)>
codeMixinInferenceNoMatchingClass =
    const Template<Message Function(String name, String name2, DartType _type)>(
      "MixinInferenceNoMatchingClass",
      problemMessageTemplate:
          r"""Type parameters couldn't be inferred for the mixin '#name' because '#name2' does not implement the mixin's supertype constraint '#type'.""",
      withArgumentsOld: _withArgumentsOldMixinInferenceNoMatchingClass,
      analyzerCodes: <String>["MIXIN_INFERENCE_NO_POSSIBLE_SUBSTITUTION"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldMixinInferenceNoMatchingClass(
  String name,
  String name2,
  DartType _type,
) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeMixinInferenceNoMatchingClass,
    problemMessage:
        """Type parameters couldn't be inferred for the mixin '${name}' because '${name2}' does not implement the mixin's supertype constraint '${type}'.""" +
        labeler.originMessages,
    arguments: {'name': name, 'name2': name2, 'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string, DartType _type)>
codeNameNotFoundInRecordNameGet =
    const Template<Message Function(String string, DartType _type)>(
      "NameNotFoundInRecordNameGet",
      problemMessageTemplate:
          r"""Field name #string isn't found in records of type #type.""",
      withArgumentsOld: _withArgumentsOldNameNotFoundInRecordNameGet,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldNameNotFoundInRecordNameGet(
  String string,
  DartType _type,
) {
  if (string.isEmpty) throw 'No string provided';
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeNameNotFoundInRecordNameGet,
    problemMessage:
        """Field name ${string} isn't found in records of type ${type}.""" +
        labeler.originMessages,
    arguments: {'string': string, 'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, String string, String string2)>
codeNonExhaustiveSwitchExpression =
    const Template<
      Message Function(DartType _type, String string, String string2)
    >(
      "NonExhaustiveSwitchExpression",
      problemMessageTemplate:
          r"""The type '#type' is not exhaustively matched by the switch cases since it doesn't match '#string'.""",
      correctionMessageTemplate:
          r"""Try adding a wildcard pattern or cases that match '#string2'.""",
      withArgumentsOld: _withArgumentsOldNonExhaustiveSwitchExpression,
      analyzerCodes: <String>["NON_EXHAUSTIVE_SWITCH_EXPRESSION"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldNonExhaustiveSwitchExpression(
  DartType _type,
  String string,
  String string2,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  if (string.isEmpty) throw 'No string provided';
  if (string2.isEmpty) throw 'No string provided';
  String type = typeParts.join();
  return new Message(
    codeNonExhaustiveSwitchExpression,
    problemMessage:
        """The type '${type}' is not exhaustively matched by the switch cases since it doesn't match '${string}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try adding a wildcard pattern or cases that match '${string2}'.""",
    arguments: {'type': _type, 'string': string, 'string2': string2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, String string, String string2)>
codeNonExhaustiveSwitchStatement =
    const Template<
      Message Function(DartType _type, String string, String string2)
    >(
      "NonExhaustiveSwitchStatement",
      problemMessageTemplate:
          r"""The type '#type' is not exhaustively matched by the switch cases since it doesn't match '#string'.""",
      correctionMessageTemplate:
          r"""Try adding a default case or cases that match '#string2'.""",
      withArgumentsOld: _withArgumentsOldNonExhaustiveSwitchStatement,
      analyzerCodes: <String>["NON_EXHAUSTIVE_SWITCH_STATEMENT"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldNonExhaustiveSwitchStatement(
  DartType _type,
  String string,
  String string2,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  if (string.isEmpty) throw 'No string provided';
  if (string2.isEmpty) throw 'No string provided';
  String type = typeParts.join();
  return new Message(
    codeNonExhaustiveSwitchStatement,
    problemMessage:
        """The type '${type}' is not exhaustively matched by the switch cases since it doesn't match '${string}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try adding a default case or cases that match '${string2}'.""",
    arguments: {'type': _type, 'string': string, 'string2': string2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type)> codeNonNullAwareSpreadIsNull =
    const Template<Message Function(DartType _type)>(
      "NonNullAwareSpreadIsNull",
      problemMessageTemplate:
          r"""Can't spread a value with static type '#type'.""",
      withArgumentsOld: _withArgumentsOldNonNullAwareSpreadIsNull,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldNonNullAwareSpreadIsNull(DartType _type) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeNonNullAwareSpreadIsNull,
    problemMessage:
        """Can't spread a value with static type '${type}'.""" +
        labeler.originMessages,
    arguments: {'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type)>
codeNullableExpressionCallError = const Template<Message Function(DartType _type)>(
  "NullableExpressionCallError",
  problemMessageTemplate:
      r"""Can't use an expression of type '#type' as a function because it's potentially null.""",
  correctionMessageTemplate: r"""Try calling using ?.call instead.""",
  withArgumentsOld: _withArgumentsOldNullableExpressionCallError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldNullableExpressionCallError(DartType _type) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeNullableExpressionCallError,
    problemMessage:
        """Can't use an expression of type '${type}' as a function because it's potentially null.""" +
        labeler.originMessages,
    correctionMessage: """Try calling using ?.call instead.""",
    arguments: {'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, DartType _type)>
codeNullableMethodCallError =
    const Template<Message Function(String name, DartType _type)>(
      "NullableMethodCallError",
      problemMessageTemplate:
          r"""Method '#name' cannot be called on '#type' because it is potentially null.""",
      correctionMessageTemplate: r"""Try calling using ?. instead.""",
      withArgumentsOld: _withArgumentsOldNullableMethodCallError,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldNullableMethodCallError(String name, DartType _type) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeNullableMethodCallError,
    problemMessage:
        """Method '${name}' cannot be called on '${type}' because it is potentially null.""" +
        labeler.originMessages,
    correctionMessage: """Try calling using ?. instead.""",
    arguments: {'name': name, 'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, DartType _type)>
codeNullableOperatorCallError =
    const Template<Message Function(String name, DartType _type)>(
      "NullableOperatorCallError",
      problemMessageTemplate:
          r"""Operator '#name' cannot be called on '#type' because it is potentially null.""",
      withArgumentsOld: _withArgumentsOldNullableOperatorCallError,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldNullableOperatorCallError(
  String name,
  DartType _type,
) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeNullableOperatorCallError,
    problemMessage:
        """Operator '${name}' cannot be called on '${type}' because it is potentially null.""" +
        labeler.originMessages,
    arguments: {'name': name, 'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, DartType _type)>
codeNullablePropertyAccessError =
    const Template<Message Function(String name, DartType _type)>(
      "NullablePropertyAccessError",
      problemMessageTemplate:
          r"""Property '#name' cannot be accessed on '#type' because it is potentially null.""",
      correctionMessageTemplate: r"""Try accessing using ?. instead.""",
      withArgumentsOld: _withArgumentsOldNullablePropertyAccessError,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldNullablePropertyAccessError(
  String name,
  DartType _type,
) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeNullablePropertyAccessError,
    problemMessage:
        """Property '${name}' cannot be accessed on '${type}' because it is potentially null.""" +
        labeler.originMessages,
    correctionMessage: """Try accessing using ?. instead.""",
    arguments: {'name': name, 'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, DartType _type)>
codeOptionalNonNullableWithoutInitializerError =
    const Template<Message Function(String name, DartType _type)>(
      "OptionalNonNullableWithoutInitializerError",
      problemMessageTemplate:
          r"""The parameter '#name' can't have a value of 'null' because of its type '#type', but the implicit default value is 'null'.""",
      correctionMessageTemplate:
          r"""Try adding either an explicit non-'null' default value or the 'required' modifier.""",
      withArgumentsOld:
          _withArgumentsOldOptionalNonNullableWithoutInitializerError,
      analyzerCodes: <String>["MISSING_DEFAULT_VALUE_FOR_PARAMETER"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldOptionalNonNullableWithoutInitializerError(
  String name,
  DartType _type,
) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeOptionalNonNullableWithoutInitializerError,
    problemMessage:
        """The parameter '${name}' can't have a value of 'null' because of its type '${type}', but the implicit default value is 'null'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try adding either an explicit non-'null' default value or the 'required' modifier.""",
    arguments: {'name': name, 'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, String name)>
codeOptionalSuperParameterWithoutInitializer =
    const Template<Message Function(DartType _type, String name)>(
      "OptionalSuperParameterWithoutInitializer",
      problemMessageTemplate:
          r"""Type '#type' of the optional super-initializer parameter '#name' doesn't allow 'null', but the parameter doesn't have a default value, and the default value can't be copied from the corresponding parameter of the super constructor.""",
      withArgumentsOld:
          _withArgumentsOldOptionalSuperParameterWithoutInitializer,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldOptionalSuperParameterWithoutInitializer(
  DartType _type,
  String name,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  String type = typeParts.join();
  return new Message(
    codeOptionalSuperParameterWithoutInitializer,
    problemMessage:
        """Type '${type}' of the optional super-initializer parameter '${name}' doesn't allow 'null', but the parameter doesn't have a default value, and the default value can't be copied from the corresponding parameter of the super constructor.""" +
        labeler.originMessages,
    arguments: {'type': _type, 'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(
    String name,
    String name2,
    DartType _type,
    DartType _type2,
    String name3,
  )
>
codeOverrideTypeMismatchParameter =
    const Template<
      Message Function(
        String name,
        String name2,
        DartType _type,
        DartType _type2,
        String name3,
      )
    >(
      "OverrideTypeMismatchParameter",
      problemMessageTemplate:
          r"""The parameter '#name' of the method '#name2' has type '#type', which does not match the corresponding type, '#type2', in the overridden method, '#name3'.""",
      correctionMessageTemplate:
          r"""Change to a supertype of '#type2', or, for a covariant parameter, a subtype.""",
      withArgumentsOld: _withArgumentsOldOverrideTypeMismatchParameter,
      analyzerCodes: <String>["INVALID_METHOD_OVERRIDE"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldOverrideTypeMismatchParameter(
  String name,
  String name2,
  DartType _type,
  DartType _type2,
  String name3,
) {
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
  return new Message(
    codeOverrideTypeMismatchParameter,
    problemMessage:
        """The parameter '${name}' of the method '${name2}' has type '${type}', which does not match the corresponding type, '${type2}', in the overridden method, '${name3}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Change to a supertype of '${type2}', or, for a covariant parameter, a subtype.""",
    arguments: {
      'name': name,
      'name2': name2,
      'type': _type,
      'type2': _type2,
      'name3': name3,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, DartType _type, DartType _type2, String name2)
>
codeOverrideTypeMismatchReturnType =
    const Template<
      Message Function(
        String name,
        DartType _type,
        DartType _type2,
        String name2,
      )
    >(
      "OverrideTypeMismatchReturnType",
      problemMessageTemplate:
          r"""The return type of the method '#name' is '#type', which does not match the return type, '#type2', of the overridden method, '#name2'.""",
      correctionMessageTemplate: r"""Change to a subtype of '#type2'.""",
      withArgumentsOld: _withArgumentsOldOverrideTypeMismatchReturnType,
      analyzerCodes: <String>["INVALID_METHOD_OVERRIDE"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldOverrideTypeMismatchReturnType(
  String name,
  DartType _type,
  DartType _type2,
  String name2,
) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeOverrideTypeMismatchReturnType,
    problemMessage:
        """The return type of the method '${name}' is '${type}', which does not match the return type, '${type2}', of the overridden method, '${name2}'.""" +
        labeler.originMessages,
    correctionMessage: """Change to a subtype of '${type2}'.""",
    arguments: {'name': name, 'type': _type, 'type2': _type2, 'name2': name2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, DartType _type, DartType _type2, String name2)
>
codeOverrideTypeMismatchSetter =
    const Template<
      Message Function(
        String name,
        DartType _type,
        DartType _type2,
        String name2,
      )
    >(
      "OverrideTypeMismatchSetter",
      problemMessageTemplate:
          r"""The field '#name' has type '#type', which does not match the corresponding type, '#type2', in the overridden setter, '#name2'.""",
      withArgumentsOld: _withArgumentsOldOverrideTypeMismatchSetter,
      analyzerCodes: <String>["INVALID_METHOD_OVERRIDE"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldOverrideTypeMismatchSetter(
  String name,
  DartType _type,
  DartType _type2,
  String name2,
) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeOverrideTypeMismatchSetter,
    problemMessage:
        """The field '${name}' has type '${type}', which does not match the corresponding type, '${type2}', in the overridden setter, '${name2}'.""" +
        labeler.originMessages,
    arguments: {'name': name, 'type': _type, 'type2': _type2, 'name2': name2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(
    DartType _type,
    String name,
    String name2,
    DartType _type2,
    String name3,
  )
>
codeOverrideTypeParametersBoundMismatch =
    const Template<
      Message Function(
        DartType _type,
        String name,
        String name2,
        DartType _type2,
        String name3,
      )
    >(
      "OverrideTypeParametersBoundMismatch",
      problemMessageTemplate:
          r"""Declared bound '#type' of type variable '#name' of '#name2' doesn't match the bound '#type2' on overridden method '#name3'.""",
      withArgumentsOld: _withArgumentsOldOverrideTypeParametersBoundMismatch,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldOverrideTypeParametersBoundMismatch(
  DartType _type,
  String name,
  String name2,
  DartType _type2,
  String name3,
) {
  TypeLabeler labeler = new TypeLabeler();
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
  return new Message(
    codeOverrideTypeParametersBoundMismatch,
    problemMessage:
        """Declared bound '${type}' of type variable '${name}' of '${name2}' doesn't match the bound '${type2}' on overridden method '${name3}'.""" +
        labeler.originMessages,
    arguments: {
      'type': _type,
      'name': name,
      'name2': name2,
      'type2': _type2,
      'name3': name3,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, DartType _type2)>
codePatternTypeMismatchInIrrefutableContext =
    const Template<Message Function(DartType _type, DartType _type2)>(
      "PatternTypeMismatchInIrrefutableContext",
      problemMessageTemplate:
          r"""The matched value of type '#type' isn't assignable to the required type '#type2'.""",
      correctionMessageTemplate:
          r"""Try changing the required type of the pattern, or the matched value type.""",
      withArgumentsOld:
          _withArgumentsOldPatternTypeMismatchInIrrefutableContext,
      analyzerCodes: <String>["PATTERN_TYPE_MISMATCH_IN_IRREFUTABLE_CONTEXT"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldPatternTypeMismatchInIrrefutableContext(
  DartType _type,
  DartType _type2,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codePatternTypeMismatchInIrrefutableContext,
    problemMessage:
        """The matched value of type '${type}' isn't assignable to the required type '${type2}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try changing the required type of the pattern, or the matched value type.""",
    arguments: {'type': _type, 'type2': _type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, DartType _type2)>
codeRedirectingFactoryIncompatibleTypeArgument =
    const Template<Message Function(DartType _type, DartType _type2)>(
      "RedirectingFactoryIncompatibleTypeArgument",
      problemMessageTemplate: r"""The type '#type' doesn't extend '#type2'.""",
      correctionMessageTemplate: r"""Try using a different type as argument.""",
      withArgumentsOld:
          _withArgumentsOldRedirectingFactoryIncompatibleTypeArgument,
      analyzerCodes: <String>["TYPE_ARGUMENT_NOT_MATCHING_BOUNDS"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldRedirectingFactoryIncompatibleTypeArgument(
  DartType _type,
  DartType _type2,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeRedirectingFactoryIncompatibleTypeArgument,
    problemMessage:
        """The type '${type}' doesn't extend '${type2}'.""" +
        labeler.originMessages,
    correctionMessage: """Try using a different type as argument.""",
    arguments: {'type': _type, 'type2': _type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, DartType _type2)>
codeSpreadElementTypeMismatch =
    const Template<Message Function(DartType _type, DartType _type2)>(
      "SpreadElementTypeMismatch",
      problemMessageTemplate:
          r"""Can't assign spread elements of type '#type' to collection elements of type '#type2'.""",
      withArgumentsOld: _withArgumentsOldSpreadElementTypeMismatch,
      analyzerCodes: <String>["LIST_ELEMENT_TYPE_NOT_ASSIGNABLE"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldSpreadElementTypeMismatch(
  DartType _type,
  DartType _type2,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeSpreadElementTypeMismatch,
    problemMessage:
        """Can't assign spread elements of type '${type}' to collection elements of type '${type2}'.""" +
        labeler.originMessages,
    arguments: {'type': _type, 'type2': _type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, DartType _type2)>
codeSpreadMapEntryElementKeyTypeMismatch =
    const Template<Message Function(DartType _type, DartType _type2)>(
      "SpreadMapEntryElementKeyTypeMismatch",
      problemMessageTemplate:
          r"""Can't assign spread entry keys of type '#type' to map entry keys of type '#type2'.""",
      withArgumentsOld: _withArgumentsOldSpreadMapEntryElementKeyTypeMismatch,
      analyzerCodes: <String>["MAP_KEY_TYPE_NOT_ASSIGNABLE"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldSpreadMapEntryElementKeyTypeMismatch(
  DartType _type,
  DartType _type2,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeSpreadMapEntryElementKeyTypeMismatch,
    problemMessage:
        """Can't assign spread entry keys of type '${type}' to map entry keys of type '${type2}'.""" +
        labeler.originMessages,
    arguments: {'type': _type, 'type2': _type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, DartType _type2)>
codeSpreadMapEntryElementValueTypeMismatch =
    const Template<Message Function(DartType _type, DartType _type2)>(
      "SpreadMapEntryElementValueTypeMismatch",
      problemMessageTemplate:
          r"""Can't assign spread entry values of type '#type' to map entry values of type '#type2'.""",
      withArgumentsOld: _withArgumentsOldSpreadMapEntryElementValueTypeMismatch,
      analyzerCodes: <String>["MAP_VALUE_TYPE_NOT_ASSIGNABLE"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldSpreadMapEntryElementValueTypeMismatch(
  DartType _type,
  DartType _type2,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeSpreadMapEntryElementValueTypeMismatch,
    problemMessage:
        """Can't assign spread entry values of type '${type}' to map entry values of type '${type2}'.""" +
        labeler.originMessages,
    arguments: {'type': _type, 'type2': _type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type)>
codeSpreadMapEntryTypeMismatch = const Template<Message Function(DartType _type)>(
  "SpreadMapEntryTypeMismatch",
  problemMessageTemplate:
      r"""Unexpected type '#type' of a map spread entry.  Expected 'dynamic' or a Map.""",
  withArgumentsOld: _withArgumentsOldSpreadMapEntryTypeMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldSpreadMapEntryTypeMismatch(DartType _type) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeSpreadMapEntryTypeMismatch,
    problemMessage:
        """Unexpected type '${type}' of a map spread entry.  Expected 'dynamic' or a Map.""" +
        labeler.originMessages,
    arguments: {'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type)>
codeSpreadTypeMismatch = const Template<Message Function(DartType _type)>(
  "SpreadTypeMismatch",
  problemMessageTemplate:
      r"""Unexpected type '#type' of a spread.  Expected 'dynamic' or an Iterable.""",
  withArgumentsOld: _withArgumentsOldSpreadTypeMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldSpreadTypeMismatch(DartType _type) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeSpreadTypeMismatch,
    problemMessage:
        """Unexpected type '${type}' of a spread.  Expected 'dynamic' or an Iterable.""" +
        labeler.originMessages,
    arguments: {'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, DartType _type2)>
codeSuperBoundedHint =
    const Template<Message Function(DartType _type, DartType _type2)>(
      "SuperBoundedHint",
      problemMessageTemplate:
          r"""If you want '#type' to be a super-bounded type, note that the inverted type '#type2' must then satisfy its bounds, which it does not.""",
      withArgumentsOld: _withArgumentsOldSuperBoundedHint,
      severity: CfeSeverity.context,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldSuperBoundedHint(DartType _type, DartType _type2) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeSuperBoundedHint,
    problemMessage:
        """If you want '${type}' to be a super-bounded type, note that the inverted type '${type2}' must then satisfy its bounds, which it does not.""" +
        labeler.originMessages,
    arguments: {'type': _type, 'type2': _type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, DartType _type)>
codeSuperExtensionTypeIsIllegalAliased =
    const Template<Message Function(String name, DartType _type)>(
      "SuperExtensionTypeIsIllegalAliased",
      problemMessageTemplate:
          r"""The type '#name' which is an alias of '#type' can't be implemented by an extension type.""",
      withArgumentsOld: _withArgumentsOldSuperExtensionTypeIsIllegalAliased,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldSuperExtensionTypeIsIllegalAliased(
  String name,
  DartType _type,
) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeSuperExtensionTypeIsIllegalAliased,
    problemMessage:
        """The type '${name}' which is an alias of '${type}' can't be implemented by an extension type.""" +
        labeler.originMessages,
    arguments: {'name': name, 'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, DartType _type)>
codeSuperExtensionTypeIsNullableAliased =
    const Template<Message Function(String name, DartType _type)>(
      "SuperExtensionTypeIsNullableAliased",
      problemMessageTemplate:
          r"""The type '#name' which is an alias of '#type' can't be implemented by an extension type because it is nullable.""",
      withArgumentsOld: _withArgumentsOldSuperExtensionTypeIsNullableAliased,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldSuperExtensionTypeIsNullableAliased(
  String name,
  DartType _type,
) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeSuperExtensionTypeIsNullableAliased,
    problemMessage:
        """The type '${name}' which is an alias of '${type}' can't be implemented by an extension type because it is nullable.""" +
        labeler.originMessages,
    arguments: {'name': name, 'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, DartType _type)>
codeSupertypeIsIllegalAliased =
    const Template<Message Function(String name, DartType _type)>(
      "SupertypeIsIllegalAliased",
      problemMessageTemplate:
          r"""The type '#name' which is an alias of '#type' can't be used as supertype.""",
      withArgumentsOld: _withArgumentsOldSupertypeIsIllegalAliased,
      analyzerCodes: <String>["EXTENDS_NON_CLASS"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldSupertypeIsIllegalAliased(
  String name,
  DartType _type,
) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeSupertypeIsIllegalAliased,
    problemMessage:
        """The type '${name}' which is an alias of '${type}' can't be used as supertype.""" +
        labeler.originMessages,
    arguments: {'name': name, 'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, DartType _type)>
codeSupertypeIsNullableAliased =
    const Template<Message Function(String name, DartType _type)>(
      "SupertypeIsNullableAliased",
      problemMessageTemplate:
          r"""The type '#name' which is an alias of '#type' can't be used as supertype because it is nullable.""",
      withArgumentsOld: _withArgumentsOldSupertypeIsNullableAliased,
      analyzerCodes: <String>["EXTENDS_NON_CLASS"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldSupertypeIsNullableAliased(
  String name,
  DartType _type,
) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeSupertypeIsNullableAliased,
    problemMessage:
        """The type '${name}' which is an alias of '${type}' can't be used as supertype because it is nullable.""" +
        labeler.originMessages,
    arguments: {'name': name, 'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, DartType _type2)>
codeSwitchExpressionNotSubtype =
    const Template<Message Function(DartType _type, DartType _type2)>(
      "SwitchExpressionNotSubtype",
      problemMessageTemplate:
          r"""Type '#type' of the case expression is not a subtype of type '#type2' of this switch expression.""",
      withArgumentsOld: _withArgumentsOldSwitchExpressionNotSubtype,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldSwitchExpressionNotSubtype(
  DartType _type,
  DartType _type2,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeSwitchExpressionNotSubtype,
    problemMessage:
        """Type '${type}' of the case expression is not a subtype of type '${type2}' of this switch expression.""" +
        labeler.originMessages,
    arguments: {'type': _type, 'type2': _type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type)>
codeThrowingNotAssignableToObjectError =
    const Template<Message Function(DartType _type)>(
      "ThrowingNotAssignableToObjectError",
      problemMessageTemplate:
          r"""Can't throw a value of '#type' since it is neither dynamic nor non-nullable.""",
      withArgumentsOld: _withArgumentsOldThrowingNotAssignableToObjectError,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldThrowingNotAssignableToObjectError(DartType _type) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeThrowingNotAssignableToObjectError,
    problemMessage:
        """Can't throw a value of '${type}' since it is neither dynamic nor non-nullable.""" +
        labeler.originMessages,
    arguments: {'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, DartType _type)>
codeUndefinedGetter = const Template<Message Function(String name, DartType _type)>(
  "UndefinedGetter",
  problemMessageTemplate:
      r"""The getter '#name' isn't defined for the type '#type'.""",
  correctionMessageTemplate:
      r"""Try correcting the name to the name of an existing getter, or defining a getter or field named '#name'.""",
  withArgumentsOld: _withArgumentsOldUndefinedGetter,
  analyzerCodes: <String>["UNDEFINED_GETTER"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldUndefinedGetter(String name, DartType _type) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeUndefinedGetter,
    problemMessage:
        """The getter '${name}' isn't defined for the type '${type}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try correcting the name to the name of an existing getter, or defining a getter or field named '${name}'.""",
    arguments: {'name': name, 'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, DartType _type)>
codeUndefinedMethod = const Template<Message Function(String name, DartType _type)>(
  "UndefinedMethod",
  problemMessageTemplate:
      r"""The method '#name' isn't defined for the type '#type'.""",
  correctionMessageTemplate:
      r"""Try correcting the name to the name of an existing method, or defining a method named '#name'.""",
  withArgumentsOld: _withArgumentsOldUndefinedMethod,
  analyzerCodes: <String>["UNDEFINED_METHOD"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldUndefinedMethod(String name, DartType _type) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeUndefinedMethod,
    problemMessage:
        """The method '${name}' isn't defined for the type '${type}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try correcting the name to the name of an existing method, or defining a method named '${name}'.""",
    arguments: {'name': name, 'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, DartType _type)>
codeUndefinedOperator =
    const Template<Message Function(String name, DartType _type)>(
      "UndefinedOperator",
      problemMessageTemplate:
          r"""The operator '#name' isn't defined for the type '#type'.""",
      correctionMessageTemplate:
          r"""Try correcting the operator to an existing operator, or defining a '#name' operator.""",
      withArgumentsOld: _withArgumentsOldUndefinedOperator,
      analyzerCodes: <String>["UNDEFINED_METHOD"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldUndefinedOperator(String name, DartType _type) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeUndefinedOperator,
    problemMessage:
        """The operator '${name}' isn't defined for the type '${type}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try correcting the operator to an existing operator, or defining a '${name}' operator.""",
    arguments: {'name': name, 'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, DartType _type)>
codeUndefinedSetter = const Template<Message Function(String name, DartType _type)>(
  "UndefinedSetter",
  problemMessageTemplate:
      r"""The setter '#name' isn't defined for the type '#type'.""",
  correctionMessageTemplate:
      r"""Try correcting the name to the name of an existing setter, or defining a setter or field named '#name'.""",
  withArgumentsOld: _withArgumentsOldUndefinedSetter,
  analyzerCodes: <String>["UNDEFINED_SETTER"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldUndefinedSetter(String name, DartType _type) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeUndefinedSetter,
    problemMessage:
        """The setter '${name}' isn't defined for the type '${type}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try correcting the name to the name of an existing setter, or defining a setter or field named '${name}'.""",
    arguments: {'name': name, 'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, DartType _type)>
codeWrongTypeParameterVarianceInSuperinterface =
    const Template<Message Function(String name, DartType _type)>(
      "WrongTypeParameterVarianceInSuperinterface",
      problemMessageTemplate:
          r"""'#name' can't be used contravariantly or invariantly in '#type'.""",
      withArgumentsOld:
          _withArgumentsOldWrongTypeParameterVarianceInSuperinterface,
      analyzerCodes: <String>[
        "WRONG_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE",
      ],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldWrongTypeParameterVarianceInSuperinterface(
  String name,
  DartType _type,
) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeWrongTypeParameterVarianceInSuperinterface,
    problemMessage:
        """'${name}' can't be used contravariantly or invariantly in '${type}'.""" +
        labeler.originMessages,
    arguments: {'name': name, 'type': _type},
  );
}
