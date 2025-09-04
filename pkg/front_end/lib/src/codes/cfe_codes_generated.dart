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
  analyzerCodes: <String>["AMBIGUOUS_SUPERTYPES"],
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
  analyzerCodes: <String>["ARGUMENT_TYPE_NOT_ASSIGNABLE"],
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
  analyzerCodes: <String>["EQUAL_ELEMENTS_IN_CONST_SET"],
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
  analyzerCodes: <String>["EQUAL_KEYS_IN_CONST_MAP"],
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
  analyzerCodes: <String>["CONST_SET_ELEMENT_TYPE_IMPLEMENTS_EQUALS"],
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
  analyzerCodes: <String>["UNDEFINED_OPERATOR"],
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
  analyzerCodes: <String>["CONST_EVAL_THROWS_EXCEPTION"],
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
  analyzerCodes: <String>["CONST_EVAL_THROWS_EXCEPTION"],
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
  analyzerCodes: <String>["CONST_EVAL_THROWS_EXCEPTION"],
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
  analyzerCodes: <String>["CONST_EVAL_TYPE_BOOL_NUM_STRING"],
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
  analyzerCodes: <String>["CONST_EVAL_THROWS_EXCEPTION"],
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
  analyzerCodes: <String>["CONST_MAP_KEY_EXPRESSION_TYPE_IMPLEMENTS_EQUALS"],
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
  analyzerCodes: <String>["TYPE_ANNOTATION_DEFERRED_CLASS"],
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
  analyzerCodes: <String>["FOR_IN_OF_INVALID_ELEMENT_TYPE"],
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
  analyzerCodes: <String>["FOR_IN_OF_INVALID_TYPE"],
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
  analyzerCodes: <String>["GENERIC_FUNCTION_CANNOT_BE_TYPE_ARGUMENT"],
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
  analyzerCodes: <String>["GENERIC_FUNCTION_CANNOT_BE_TYPE_ARGUMENT"],
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
  analyzerCodes: <String>["IMPLICIT_CALL_OF_NON_METHOD"],
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
  analyzerCodes: <String>["REDIRECT_TO_INVALID_TYPE"],
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
  analyzerCodes: <String>["TYPE_ARGUMENT_NOT_MATCHING_BOUNDS"],
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
  analyzerCodes: <String>["TYPE_ARGUMENT_NOT_MATCHING_BOUNDS"],
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
  analyzerCodes: <String>["TYPE_ARGUMENT_NOT_MATCHING_BOUNDS"],
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
  analyzerCodes: <String>["TYPE_ARGUMENT_NOT_MATCHING_BOUNDS"],
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
  analyzerCodes: <String>["TYPE_ARGUMENT_NOT_MATCHING_BOUNDS"],
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
  analyzerCodes: <String>["TYPE_ARGUMENT_NOT_MATCHING_BOUNDS"],
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
  analyzerCodes: <String>["INVALID_PARAMETER_DECLARATION"],
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
  analyzerCodes: <String>["DISALLOWED_TYPE_INSTANTIATION_EXPRESSION"],
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
  analyzerCodes: <String>["INVALID_ASSIGNMENT"],
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
  analyzerCodes: <String>["INVALID_CAST_FUNCTION_EXPR"],
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
  analyzerCodes: <String>["INVALID_CAST_LITERAL_LIST"],
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
  analyzerCodes: <String>["INVALID_CAST_LITERAL_MAP"],
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
  analyzerCodes: <String>["INVALID_CAST_LITERAL_SET"],
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
  analyzerCodes: <String>["INVALID_CAST_FUNCTION"],
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
  analyzerCodes: <String>["INVALID_CAST_NEW_EXPR"],
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
  analyzerCodes: <String>["INVALID_CAST_METHOD"],
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
  analyzerCodes: <String>["INVALID_CAST_FUNCTION"],
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
const Template<
  Message Function(DartType type),
  Message Function({required DartType type})
>
codeJsInteropFunctionToJSRequiresStaticType = const Template(
  "JsInteropFunctionToJSRequiresStaticType",
  problemMessageTemplate:
      r"""`Function.toJS` requires a statically known function type, but Type '#type' is not a precise function type, e.g., `void Function()`.""",
  correctionMessageTemplate:
      r"""Insert an explicit cast to the expected function type.""",
  withArgumentsOld: _withArgumentsOldJsInteropFunctionToJSRequiresStaticType,
  withArguments: _withArgumentsJsInteropFunctionToJSRequiresStaticType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropFunctionToJSRequiresStaticType({
  required DartType type,
}) {
  TypeLabeler labeler = new TypeLabeler();
  var type_0 = labeler.labelType(type);
  return new Message(
    codeJsInteropFunctionToJSRequiresStaticType,
    problemMessage:
        """`Function.toJS` requires a statically known function type, but Type '${type_0}' is not a precise function type, e.g., `void Function()`.""" +
        labeler.originMessages,
    correctionMessage:
        """Insert an explicit cast to the expected function type.""",
    arguments: {'type': type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldJsInteropFunctionToJSRequiresStaticType(
  DartType type,
) => _withArgumentsJsInteropFunctionToJSRequiresStaticType(type: type);

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
  analyzerCodes: <String>["MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE"],
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
  analyzerCodes: <String>["MIXIN_INFERENCE_NO_POSSIBLE_SUBSTITUTION"],
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
  analyzerCodes: <String>["NON_EXHAUSTIVE_SWITCH_EXPRESSION"],
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
  analyzerCodes: <String>["NON_EXHAUSTIVE_SWITCH_STATEMENT"],
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
  analyzerCodes: <String>["MISSING_DEFAULT_VALUE_FOR_PARAMETER"],
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
  analyzerCodes: <String>["INVALID_METHOD_OVERRIDE"],
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
  analyzerCodes: <String>["INVALID_METHOD_OVERRIDE"],
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
  analyzerCodes: <String>["INVALID_METHOD_OVERRIDE"],
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
  analyzerCodes: <String>["PATTERN_TYPE_MISMATCH_IN_IRREFUTABLE_CONTEXT"],
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
  analyzerCodes: <String>["TYPE_ARGUMENT_NOT_MATCHING_BOUNDS"],
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
  Message Function(DartType type, DartType type2),
  Message Function({required DartType type, required DartType type2})
>
codeSpreadElementTypeMismatch = const Template(
  "SpreadElementTypeMismatch",
  problemMessageTemplate:
      r"""Can't assign spread elements of type '#type' to collection elements of type '#type2'.""",
  withArgumentsOld: _withArgumentsOldSpreadElementTypeMismatch,
  withArguments: _withArgumentsSpreadElementTypeMismatch,
  analyzerCodes: <String>["LIST_ELEMENT_TYPE_NOT_ASSIGNABLE"],
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
  analyzerCodes: <String>["MAP_KEY_TYPE_NOT_ASSIGNABLE"],
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
  analyzerCodes: <String>["MAP_VALUE_TYPE_NOT_ASSIGNABLE"],
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
  Message Function(String name, DartType type),
  Message Function({required String name, required DartType type})
>
codeSupertypeIsIllegalAliased = const Template(
  "SupertypeIsIllegalAliased",
  problemMessageTemplate:
      r"""The type '#name' which is an alias of '#type' can't be used as supertype.""",
  withArgumentsOld: _withArgumentsOldSupertypeIsIllegalAliased,
  withArguments: _withArgumentsSupertypeIsIllegalAliased,
  analyzerCodes: <String>["EXTENDS_NON_CLASS"],
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
  analyzerCodes: <String>["EXTENDS_NON_CLASS"],
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
  analyzerCodes: <String>["UNDEFINED_GETTER"],
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
  analyzerCodes: <String>["UNDEFINED_METHOD"],
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
  analyzerCodes: <String>["UNDEFINED_METHOD"],
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
  analyzerCodes: <String>["UNDEFINED_SETTER"],
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
  analyzerCodes: <String>["WRONG_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE"],
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
