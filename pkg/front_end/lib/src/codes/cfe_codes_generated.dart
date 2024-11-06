// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// NOTE: THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/front_end/messages.yaml' and run
// 'pkg/front_end/tool/fasta generate-messages' to update.

// ignore_for_file: lines_longer_than_80_chars

part of 'cfe_codes.dart';

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, DartType _type)>
templateAmbiguousExtensionMethod = const Template<
  Message Function(String name, DartType _type)
>(
  "AmbiguousExtensionMethod",
  problemMessageTemplate:
      r"""The method '#name' is defined in multiple extensions for '#type' and neither is more specific.""",
  correctionMessageTemplate:
      r"""Try using an explicit extension application of the wanted extension or hiding unwanted extensions from scope.""",
  withArguments: _withArgumentsAmbiguousExtensionMethod,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, DartType _type)>
codeAmbiguousExtensionMethod =
    const Code<Message Function(String name, DartType _type)>(
      "AmbiguousExtensionMethod",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsAmbiguousExtensionMethod(String name, DartType _type) {
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
templateAmbiguousExtensionOperator = const Template<
  Message Function(String name, DartType _type)
>(
  "AmbiguousExtensionOperator",
  problemMessageTemplate:
      r"""The operator '#name' is defined in multiple extensions for '#type' and neither is more specific.""",
  correctionMessageTemplate:
      r"""Try using an explicit extension application of the wanted extension or hiding unwanted extensions from scope.""",
  withArguments: _withArgumentsAmbiguousExtensionOperator,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, DartType _type)>
codeAmbiguousExtensionOperator =
    const Code<Message Function(String name, DartType _type)>(
      "AmbiguousExtensionOperator",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsAmbiguousExtensionOperator(String name, DartType _type) {
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
templateAmbiguousExtensionProperty = const Template<
  Message Function(String name, DartType _type)
>(
  "AmbiguousExtensionProperty",
  problemMessageTemplate:
      r"""The property '#name' is defined in multiple extensions for '#type' and neither is more specific.""",
  correctionMessageTemplate:
      r"""Try using an explicit extension application of the wanted extension or hiding unwanted extensions from scope.""",
  withArguments: _withArgumentsAmbiguousExtensionProperty,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, DartType _type)>
codeAmbiguousExtensionProperty =
    const Code<Message Function(String name, DartType _type)>(
      "AmbiguousExtensionProperty",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsAmbiguousExtensionProperty(String name, DartType _type) {
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
templateAmbiguousSupertypes = const Template<
  Message Function(String name, DartType _type, DartType _type2)
>(
  "AmbiguousSupertypes",
  problemMessageTemplate:
      r"""'#name' can't implement both '#type' and '#type2'""",
  withArguments: _withArgumentsAmbiguousSupertypes,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, DartType _type, DartType _type2)>
codeAmbiguousSupertypes =
    const Code<Message Function(String name, DartType _type, DartType _type2)>(
      "AmbiguousSupertypes",
      analyzerCodes: <String>["AMBIGUOUS_SUPERTYPES"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsAmbiguousSupertypes(
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
templateArgumentTypeNotAssignable = const Template<
  Message Function(DartType _type, DartType _type2)
>(
  "ArgumentTypeNotAssignable",
  problemMessageTemplate:
      r"""The argument type '#type' can't be assigned to the parameter type '#type2'.""",
  withArguments: _withArgumentsArgumentTypeNotAssignable,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
codeArgumentTypeNotAssignable =
    const Code<Message Function(DartType _type, DartType _type2)>(
      "ArgumentTypeNotAssignable",
      analyzerCodes: <String>["ARGUMENT_TYPE_NOT_ASSIGNABLE"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsArgumentTypeNotAssignable(
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
const Template<Message Function(DartType _type, DartType _type2)>
templateArgumentTypeNotAssignableNullability = const Template<
  Message Function(DartType _type, DartType _type2)
>(
  "ArgumentTypeNotAssignableNullability",
  problemMessageTemplate:
      r"""The argument type '#type' can't be assigned to the parameter type '#type2' because '#type' is nullable and '#type2' isn't.""",
  withArguments: _withArgumentsArgumentTypeNotAssignableNullability,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
codeArgumentTypeNotAssignableNullability =
    const Code<Message Function(DartType _type, DartType _type2)>(
      "ArgumentTypeNotAssignableNullability",
      analyzerCodes: <String>["ARGUMENT_TYPE_NOT_ASSIGNABLE"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsArgumentTypeNotAssignableNullability(
  DartType _type,
  DartType _type2,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeArgumentTypeNotAssignableNullability,
    problemMessage:
        """The argument type '${type}' can't be assigned to the parameter type '${type2}' because '${type}' is nullable and '${type2}' isn't.""" +
        labeler.originMessages,
    arguments: {'type': _type, 'type2': _type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type)>
templateArgumentTypeNotAssignableNullabilityNull = const Template<
  Message Function(DartType _type)
>(
  "ArgumentTypeNotAssignableNullabilityNull",
  problemMessageTemplate:
      r"""The value 'null' can't be assigned to the parameter type '#type' because '#type' is not nullable.""",
  withArguments: _withArgumentsArgumentTypeNotAssignableNullabilityNull,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type)>
codeArgumentTypeNotAssignableNullabilityNull =
    const Code<Message Function(DartType _type)>(
      "ArgumentTypeNotAssignableNullabilityNull",
      analyzerCodes: <String>["ARGUMENT_TYPE_NOT_ASSIGNABLE"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsArgumentTypeNotAssignableNullabilityNull(DartType _type) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeArgumentTypeNotAssignableNullabilityNull,
    problemMessage:
        """The value 'null' can't be assigned to the parameter type '${type}' because '${type}' is not nullable.""" +
        labeler.originMessages,
    arguments: {'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, DartType _type2)>
templateArgumentTypeNotAssignableNullabilityNullType = const Template<
  Message Function(DartType _type, DartType _type2)
>(
  "ArgumentTypeNotAssignableNullabilityNullType",
  problemMessageTemplate:
      r"""The argument type '#type' can't be assigned to the parameter type '#type2' because '#type2' is not nullable.""",
  withArguments: _withArgumentsArgumentTypeNotAssignableNullabilityNullType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
codeArgumentTypeNotAssignableNullabilityNullType =
    const Code<Message Function(DartType _type, DartType _type2)>(
      "ArgumentTypeNotAssignableNullabilityNullType",
      analyzerCodes: <String>["ARGUMENT_TYPE_NOT_ASSIGNABLE"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsArgumentTypeNotAssignableNullabilityNullType(
  DartType _type,
  DartType _type2,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeArgumentTypeNotAssignableNullabilityNullType,
    problemMessage:
        """The argument type '${type}' can't be assigned to the parameter type '${type2}' because '${type2}' is not nullable.""" +
        labeler.originMessages,
    arguments: {'type': _type, 'type2': _type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(
    DartType _type,
    DartType _type2,
    DartType _type3,
    DartType _type4,
  )
>
templateArgumentTypeNotAssignablePartNullability = const Template<
  Message Function(
    DartType _type,
    DartType _type2,
    DartType _type3,
    DartType _type4,
  )
>(
  "ArgumentTypeNotAssignablePartNullability",
  problemMessageTemplate:
      r"""The argument type '#type' can't be assigned to the parameter type '#type2' because '#type3' is nullable and '#type4' isn't.""",
  withArguments: _withArgumentsArgumentTypeNotAssignablePartNullability,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
  Message Function(
    DartType _type,
    DartType _type2,
    DartType _type3,
    DartType _type4,
  )
>
codeArgumentTypeNotAssignablePartNullability = const Code<
  Message Function(
    DartType _type,
    DartType _type2,
    DartType _type3,
    DartType _type4,
  )
>(
  "ArgumentTypeNotAssignablePartNullability",
  analyzerCodes: <String>["ARGUMENT_TYPE_NOT_ASSIGNABLE"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsArgumentTypeNotAssignablePartNullability(
  DartType _type,
  DartType _type2,
  DartType _type3,
  DartType _type4,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  List<Object> type3Parts = labeler.labelType(_type3);
  List<Object> type4Parts = labeler.labelType(_type4);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  String type3 = type3Parts.join();
  String type4 = type4Parts.join();
  return new Message(
    codeArgumentTypeNotAssignablePartNullability,
    problemMessage:
        """The argument type '${type}' can't be assigned to the parameter type '${type2}' because '${type3}' is nullable and '${type4}' isn't.""" +
        labeler.originMessages,
    arguments: {
      'type': _type,
      'type2': _type2,
      'type3': _type3,
      'type4': _type4,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Constant _constant)>
templateConstEvalCaseImplementsEqual = const Template<
  Message Function(Constant _constant)
>(
  "ConstEvalCaseImplementsEqual",
  problemMessageTemplate:
      r"""Case expression '#constant' does not have a primitive operator '=='.""",
  withArguments: _withArgumentsConstEvalCaseImplementsEqual,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Constant _constant)>
codeConstEvalCaseImplementsEqual =
    const Code<Message Function(Constant _constant)>(
      "ConstEvalCaseImplementsEqual",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalCaseImplementsEqual(Constant _constant) {
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
templateConstEvalDuplicateElement = const Template<
  Message Function(Constant _constant)
>(
  "ConstEvalDuplicateElement",
  problemMessageTemplate:
      r"""The element '#constant' conflicts with another existing element in the set.""",
  withArguments: _withArgumentsConstEvalDuplicateElement,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Constant _constant)> codeConstEvalDuplicateElement =
    const Code<Message Function(Constant _constant)>(
      "ConstEvalDuplicateElement",
      analyzerCodes: <String>["EQUAL_ELEMENTS_IN_CONST_SET"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalDuplicateElement(Constant _constant) {
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
templateConstEvalDuplicateKey = const Template<
  Message Function(Constant _constant)
>(
  "ConstEvalDuplicateKey",
  problemMessageTemplate:
      r"""The key '#constant' conflicts with another existing key in the map.""",
  withArguments: _withArgumentsConstEvalDuplicateKey,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Constant _constant)> codeConstEvalDuplicateKey =
    const Code<Message Function(Constant _constant)>(
      "ConstEvalDuplicateKey",
      analyzerCodes: <String>["EQUAL_KEYS_IN_CONST_MAP"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalDuplicateKey(Constant _constant) {
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
templateConstEvalElementImplementsEqual = const Template<
  Message Function(Constant _constant)
>(
  "ConstEvalElementImplementsEqual",
  problemMessageTemplate:
      r"""The element '#constant' does not have a primitive operator '=='.""",
  withArguments: _withArgumentsConstEvalElementImplementsEqual,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Constant _constant)>
codeConstEvalElementImplementsEqual =
    const Code<Message Function(Constant _constant)>(
      "ConstEvalElementImplementsEqual",
      analyzerCodes: <String>["CONST_SET_ELEMENT_TYPE_IMPLEMENTS_EQUALS"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalElementImplementsEqual(Constant _constant) {
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
templateConstEvalElementNotPrimitiveEquality =
    const Template<Message Function(Constant _constant)>(
      "ConstEvalElementNotPrimitiveEquality",
      problemMessageTemplate:
          r"""The element '#constant' does not have a primitive equality.""",
      withArguments: _withArgumentsConstEvalElementNotPrimitiveEquality,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Constant _constant)>
codeConstEvalElementNotPrimitiveEquality =
    const Code<Message Function(Constant _constant)>(
      "ConstEvalElementNotPrimitiveEquality",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalElementNotPrimitiveEquality(Constant _constant) {
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
templateConstEvalEqualsOperandNotPrimitiveEquality = const Template<
  Message Function(Constant _constant, DartType _type)
>(
  "ConstEvalEqualsOperandNotPrimitiveEquality",
  problemMessageTemplate:
      r"""Binary operator '==' requires receiver constant '#constant' of a type with primitive equality or type 'double', but was of type '#type'.""",
  withArguments: _withArgumentsConstEvalEqualsOperandNotPrimitiveEquality,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Constant _constant, DartType _type)>
codeConstEvalEqualsOperandNotPrimitiveEquality =
    const Code<Message Function(Constant _constant, DartType _type)>(
      "ConstEvalEqualsOperandNotPrimitiveEquality",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalEqualsOperandNotPrimitiveEquality(
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
const Template<Message Function(DartType _type)>
templateConstEvalFreeTypeParameter = const Template<
  Message Function(DartType _type)
>(
  "ConstEvalFreeTypeParameter",
  problemMessageTemplate:
      r"""The type '#type' is not a constant because it depends on a type parameter, only instantiated types are allowed.""",
  withArguments: _withArgumentsConstEvalFreeTypeParameter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type)> codeConstEvalFreeTypeParameter =
    const Code<Message Function(DartType _type)>("ConstEvalFreeTypeParameter");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalFreeTypeParameter(DartType _type) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeConstEvalFreeTypeParameter,
    problemMessage:
        """The type '${type}' is not a constant because it depends on a type parameter, only instantiated types are allowed.""" +
        labeler.originMessages,
    arguments: {'type': _type},
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
templateConstEvalInvalidBinaryOperandType = const Template<
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
  withArguments: _withArgumentsConstEvalInvalidBinaryOperandType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
  Message Function(
    String stringOKEmpty,
    Constant _constant,
    DartType _type,
    DartType _type2,
  )
>
codeConstEvalInvalidBinaryOperandType = const Code<
  Message Function(
    String stringOKEmpty,
    Constant _constant,
    DartType _type,
    DartType _type2,
  )
>("ConstEvalInvalidBinaryOperandType");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalInvalidBinaryOperandType(
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
templateConstEvalInvalidEqualsOperandType = const Template<
  Message Function(Constant _constant, DartType _type)
>(
  "ConstEvalInvalidEqualsOperandType",
  problemMessageTemplate:
      r"""Binary operator '==' requires receiver constant '#constant' of type 'Null', 'bool', 'int', 'double', or 'String', but was of type '#type'.""",
  withArguments: _withArgumentsConstEvalInvalidEqualsOperandType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Constant _constant, DartType _type)>
codeConstEvalInvalidEqualsOperandType =
    const Code<Message Function(Constant _constant, DartType _type)>(
      "ConstEvalInvalidEqualsOperandType",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalInvalidEqualsOperandType(
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
templateConstEvalInvalidMethodInvocation = const Template<
  Message Function(String stringOKEmpty, Constant _constant)
>(
  "ConstEvalInvalidMethodInvocation",
  problemMessageTemplate:
      r"""The method '#stringOKEmpty' can't be invoked on '#constant' in a constant expression.""",
  withArguments: _withArgumentsConstEvalInvalidMethodInvocation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String stringOKEmpty, Constant _constant)>
codeConstEvalInvalidMethodInvocation =
    const Code<Message Function(String stringOKEmpty, Constant _constant)>(
      "ConstEvalInvalidMethodInvocation",
      analyzerCodes: <String>["UNDEFINED_OPERATOR"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalInvalidMethodInvocation(
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
templateConstEvalInvalidPropertyGet = const Template<
  Message Function(String stringOKEmpty, Constant _constant)
>(
  "ConstEvalInvalidPropertyGet",
  problemMessageTemplate:
      r"""The property '#stringOKEmpty' can't be accessed on '#constant' in a constant expression.""",
  withArguments: _withArgumentsConstEvalInvalidPropertyGet,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String stringOKEmpty, Constant _constant)>
codeConstEvalInvalidPropertyGet =
    const Code<Message Function(String stringOKEmpty, Constant _constant)>(
      "ConstEvalInvalidPropertyGet",
      analyzerCodes: <String>["CONST_EVAL_THROWS_EXCEPTION"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalInvalidPropertyGet(
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
templateConstEvalInvalidRecordIndexGet = const Template<
  Message Function(String stringOKEmpty, Constant _constant)
>(
  "ConstEvalInvalidRecordIndexGet",
  problemMessageTemplate:
      r"""The property '#stringOKEmpty' can't be accessed on '#constant' in a constant expression.""",
  withArguments: _withArgumentsConstEvalInvalidRecordIndexGet,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String stringOKEmpty, Constant _constant)>
codeConstEvalInvalidRecordIndexGet =
    const Code<Message Function(String stringOKEmpty, Constant _constant)>(
      "ConstEvalInvalidRecordIndexGet",
      analyzerCodes: <String>["CONST_EVAL_THROWS_EXCEPTION"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalInvalidRecordIndexGet(
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
templateConstEvalInvalidRecordNameGet = const Template<
  Message Function(String stringOKEmpty, Constant _constant)
>(
  "ConstEvalInvalidRecordNameGet",
  problemMessageTemplate:
      r"""The property '#stringOKEmpty' can't be accessed on '#constant' in a constant expression.""",
  withArguments: _withArgumentsConstEvalInvalidRecordNameGet,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String stringOKEmpty, Constant _constant)>
codeConstEvalInvalidRecordNameGet =
    const Code<Message Function(String stringOKEmpty, Constant _constant)>(
      "ConstEvalInvalidRecordNameGet",
      analyzerCodes: <String>["CONST_EVAL_THROWS_EXCEPTION"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalInvalidRecordNameGet(
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
templateConstEvalInvalidStringInterpolationOperand = const Template<
  Message Function(Constant _constant)
>(
  "ConstEvalInvalidStringInterpolationOperand",
  problemMessageTemplate:
      r"""The constant value '#constant' can't be used as part of a string interpolation in a constant expression.
Only values of type 'null', 'bool', 'int', 'double', or 'String' can be used.""",
  withArguments: _withArgumentsConstEvalInvalidStringInterpolationOperand,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Constant _constant)>
codeConstEvalInvalidStringInterpolationOperand =
    const Code<Message Function(Constant _constant)>(
      "ConstEvalInvalidStringInterpolationOperand",
      analyzerCodes: <String>["CONST_EVAL_TYPE_BOOL_NUM_STRING"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalInvalidStringInterpolationOperand(
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
templateConstEvalInvalidSymbolName = const Template<
  Message Function(Constant _constant)
>(
  "ConstEvalInvalidSymbolName",
  problemMessageTemplate:
      r"""The symbol name must be a valid public Dart member name, public constructor name, or library name, optionally qualified, but was '#constant'.""",
  withArguments: _withArgumentsConstEvalInvalidSymbolName,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Constant _constant)>
codeConstEvalInvalidSymbolName =
    const Code<Message Function(Constant _constant)>(
      "ConstEvalInvalidSymbolName",
      analyzerCodes: <String>["CONST_EVAL_THROWS_EXCEPTION"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalInvalidSymbolName(Constant _constant) {
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
templateConstEvalInvalidType = const Template<
  Message Function(Constant _constant, DartType _type, DartType _type2)
>(
  "ConstEvalInvalidType",
  problemMessageTemplate:
      r"""Expected constant '#constant' to be of type '#type', but was of type '#type2'.""",
  withArguments: _withArgumentsConstEvalInvalidType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
  Message Function(Constant _constant, DartType _type, DartType _type2)
>
codeConstEvalInvalidType = const Code<
  Message Function(Constant _constant, DartType _type, DartType _type2)
>("ConstEvalInvalidType");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalInvalidType(
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
templateConstEvalKeyImplementsEqual =
    const Template<Message Function(Constant _constant)>(
      "ConstEvalKeyImplementsEqual",
      problemMessageTemplate:
          r"""The key '#constant' does not have a primitive operator '=='.""",
      withArguments: _withArgumentsConstEvalKeyImplementsEqual,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Constant _constant)>
codeConstEvalKeyImplementsEqual =
    const Code<Message Function(Constant _constant)>(
      "ConstEvalKeyImplementsEqual",
      analyzerCodes: <String>[
        "CONST_MAP_KEY_EXPRESSION_TYPE_IMPLEMENTS_EQUALS",
      ],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalKeyImplementsEqual(Constant _constant) {
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
templateConstEvalKeyNotPrimitiveEquality =
    const Template<Message Function(Constant _constant)>(
      "ConstEvalKeyNotPrimitiveEquality",
      problemMessageTemplate:
          r"""The key '#constant' does not have a primitive equality.""",
      withArguments: _withArgumentsConstEvalKeyNotPrimitiveEquality,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Constant _constant)>
codeConstEvalKeyNotPrimitiveEquality =
    const Code<Message Function(Constant _constant)>(
      "ConstEvalKeyNotPrimitiveEquality",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalKeyNotPrimitiveEquality(Constant _constant) {
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
templateConstEvalUnhandledException =
    const Template<Message Function(Constant _constant)>(
      "ConstEvalUnhandledException",
      problemMessageTemplate: r"""Unhandled exception: #constant""",
      withArguments: _withArgumentsConstEvalUnhandledException,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Constant _constant)>
codeConstEvalUnhandledException =
    const Code<Message Function(Constant _constant)>(
      "ConstEvalUnhandledException",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalUnhandledException(Constant _constant) {
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
templateDeferredTypeAnnotation = const Template<
  Message Function(DartType _type, String name)
>(
  "DeferredTypeAnnotation",
  problemMessageTemplate:
      r"""The type '#type' is deferred loaded via prefix '#name' and can't be used as a type annotation.""",
  correctionMessageTemplate:
      r"""Try removing 'deferred' from the import of '#name' or use a supertype of '#type' that isn't deferred.""",
  withArguments: _withArgumentsDeferredTypeAnnotation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, String name)>
codeDeferredTypeAnnotation =
    const Code<Message Function(DartType _type, String name)>(
      "DeferredTypeAnnotation",
      analyzerCodes: <String>["TYPE_ANNOTATION_DEFERRED_CLASS"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDeferredTypeAnnotation(DartType _type, String name) {
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
const Template<Message Function(DartType _type, DartType _type2)>
templateFfiDartTypeMismatch =
    const Template<Message Function(DartType _type, DartType _type2)>(
      "FfiDartTypeMismatch",
      problemMessageTemplate:
          r"""Expected '#type' to be a subtype of '#type2'.""",
      withArguments: _withArgumentsFfiDartTypeMismatch,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
codeFfiDartTypeMismatch =
    const Code<Message Function(DartType _type, DartType _type2)>(
      "FfiDartTypeMismatch",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiDartTypeMismatch(DartType _type, DartType _type2) {
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
templateFfiExpectedExceptionalReturn = const Template<
  Message Function(DartType _type)
>(
  "FfiExpectedExceptionalReturn",
  problemMessageTemplate:
      r"""Expected an exceptional return value for a native callback returning '#type'.""",
  withArguments: _withArgumentsFfiExpectedExceptionalReturn,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type)> codeFfiExpectedExceptionalReturn =
    const Code<Message Function(DartType _type)>(
      "FfiExpectedExceptionalReturn",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiExpectedExceptionalReturn(DartType _type) {
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
templateFfiExpectedNoExceptionalReturn = const Template<
  Message Function(DartType _type)
>(
  "FfiExpectedNoExceptionalReturn",
  problemMessageTemplate:
      r"""Exceptional return value cannot be provided for a native callback returning '#type'.""",
  withArguments: _withArgumentsFfiExpectedNoExceptionalReturn,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type)>
codeFfiExpectedNoExceptionalReturn =
    const Code<Message Function(DartType _type)>(
      "FfiExpectedNoExceptionalReturn",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiExpectedNoExceptionalReturn(DartType _type) {
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
templateFfiNativeCallableListenerReturnVoid = const Template<
  Message Function(DartType _type)
>(
  "FfiNativeCallableListenerReturnVoid",
  problemMessageTemplate:
      r"""The return type of the function passed to NativeCallable.listener must be void rather than '#type'.""",
  withArguments: _withArgumentsFfiNativeCallableListenerReturnVoid,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type)>
codeFfiNativeCallableListenerReturnVoid =
    const Code<Message Function(DartType _type)>(
      "FfiNativeCallableListenerReturnVoid",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiNativeCallableListenerReturnVoid(DartType _type) {
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
templateFfiTypeInvalid = const Template<Message Function(DartType _type)>(
  "FfiTypeInvalid",
  problemMessageTemplate:
      r"""Expected type '#type' to be a valid and instantiated subtype of 'NativeType'.""",
  withArguments: _withArgumentsFfiTypeInvalid,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type)> codeFfiTypeInvalid =
    const Code<Message Function(DartType _type)>("FfiTypeInvalid");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiTypeInvalid(DartType _type) {
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
templateFfiTypeMismatch = const Template<
  Message Function(DartType _type, DartType _type2, DartType _type3)
>(
  "FfiTypeMismatch",
  problemMessageTemplate:
      r"""Expected type '#type' to be '#type2', which is the Dart type corresponding to '#type3'.""",
  withArguments: _withArgumentsFfiTypeMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2, DartType _type3)>
codeFfiTypeMismatch = const Code<
  Message Function(DartType _type, DartType _type2, DartType _type3)
>("FfiTypeMismatch");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiTypeMismatch(
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
templateFieldNonNullableNotInitializedByConstructorError = const Template<
  Message Function(String name, DartType _type)
>(
  "FieldNonNullableNotInitializedByConstructorError",
  problemMessageTemplate:
      r"""This constructor should initialize field '#name' because its type '#type' doesn't allow null.""",
  withArguments: _withArgumentsFieldNonNullableNotInitializedByConstructorError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, DartType _type)>
codeFieldNonNullableNotInitializedByConstructorError =
    const Code<Message Function(String name, DartType _type)>(
      "FieldNonNullableNotInitializedByConstructorError",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFieldNonNullableNotInitializedByConstructorError(
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
templateFieldNonNullableWithoutInitializerError = const Template<
  Message Function(String name, DartType _type)
>(
  "FieldNonNullableWithoutInitializerError",
  problemMessageTemplate:
      r"""Field '#name' should be initialized because its type '#type' doesn't allow null.""",
  withArguments: _withArgumentsFieldNonNullableWithoutInitializerError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, DartType _type)>
codeFieldNonNullableWithoutInitializerError =
    const Code<Message Function(String name, DartType _type)>(
      "FieldNonNullableWithoutInitializerError",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFieldNonNullableWithoutInitializerError(
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
templateForInLoopElementTypeNotAssignable = const Template<
  Message Function(DartType _type, DartType _type2)
>(
  "ForInLoopElementTypeNotAssignable",
  problemMessageTemplate:
      r"""A value of type '#type' can't be assigned to a variable of type '#type2'.""",
  correctionMessageTemplate: r"""Try changing the type of the variable.""",
  withArguments: _withArgumentsForInLoopElementTypeNotAssignable,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
codeForInLoopElementTypeNotAssignable =
    const Code<Message Function(DartType _type, DartType _type2)>(
      "ForInLoopElementTypeNotAssignable",
      analyzerCodes: <String>["FOR_IN_OF_INVALID_ELEMENT_TYPE"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsForInLoopElementTypeNotAssignable(
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
templateForInLoopElementTypeNotAssignableNullability = const Template<
  Message Function(DartType _type, DartType _type2)
>(
  "ForInLoopElementTypeNotAssignableNullability",
  problemMessageTemplate:
      r"""A value of type '#type' can't be assigned to a variable of type '#type2' because '#type' is nullable and '#type2' isn't.""",
  correctionMessageTemplate: r"""Try changing the type of the variable.""",
  withArguments: _withArgumentsForInLoopElementTypeNotAssignableNullability,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
codeForInLoopElementTypeNotAssignableNullability =
    const Code<Message Function(DartType _type, DartType _type2)>(
      "ForInLoopElementTypeNotAssignableNullability",
      analyzerCodes: <String>["FOR_IN_OF_INVALID_ELEMENT_TYPE"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsForInLoopElementTypeNotAssignableNullability(
  DartType _type,
  DartType _type2,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeForInLoopElementTypeNotAssignableNullability,
    problemMessage:
        """A value of type '${type}' can't be assigned to a variable of type '${type2}' because '${type}' is nullable and '${type2}' isn't.""" +
        labeler.originMessages,
    correctionMessage: """Try changing the type of the variable.""",
    arguments: {'type': _type, 'type2': _type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(
    DartType _type,
    DartType _type2,
    DartType _type3,
    DartType _type4,
  )
>
templateForInLoopElementTypeNotAssignablePartNullability = const Template<
  Message Function(
    DartType _type,
    DartType _type2,
    DartType _type3,
    DartType _type4,
  )
>(
  "ForInLoopElementTypeNotAssignablePartNullability",
  problemMessageTemplate:
      r"""A value of type '#type' can't be assigned to a variable of type '#type2' because '#type3' is nullable and '#type4' isn't.""",
  correctionMessageTemplate: r"""Try changing the type of the variable.""",
  withArguments: _withArgumentsForInLoopElementTypeNotAssignablePartNullability,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
  Message Function(
    DartType _type,
    DartType _type2,
    DartType _type3,
    DartType _type4,
  )
>
codeForInLoopElementTypeNotAssignablePartNullability = const Code<
  Message Function(
    DartType _type,
    DartType _type2,
    DartType _type3,
    DartType _type4,
  )
>(
  "ForInLoopElementTypeNotAssignablePartNullability",
  analyzerCodes: <String>["FOR_IN_OF_INVALID_ELEMENT_TYPE"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsForInLoopElementTypeNotAssignablePartNullability(
  DartType _type,
  DartType _type2,
  DartType _type3,
  DartType _type4,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  List<Object> type3Parts = labeler.labelType(_type3);
  List<Object> type4Parts = labeler.labelType(_type4);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  String type3 = type3Parts.join();
  String type4 = type4Parts.join();
  return new Message(
    codeForInLoopElementTypeNotAssignablePartNullability,
    problemMessage:
        """A value of type '${type}' can't be assigned to a variable of type '${type2}' because '${type3}' is nullable and '${type4}' isn't.""" +
        labeler.originMessages,
    correctionMessage: """Try changing the type of the variable.""",
    arguments: {
      'type': _type,
      'type2': _type2,
      'type3': _type3,
      'type4': _type4,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, DartType _type2)>
templateForInLoopTypeNotIterable = const Template<
  Message Function(DartType _type, DartType _type2)
>(
  "ForInLoopTypeNotIterable",
  problemMessageTemplate:
      r"""The type '#type' used in the 'for' loop must implement '#type2'.""",
  withArguments: _withArgumentsForInLoopTypeNotIterable,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
codeForInLoopTypeNotIterable =
    const Code<Message Function(DartType _type, DartType _type2)>(
      "ForInLoopTypeNotIterable",
      analyzerCodes: <String>["FOR_IN_OF_INVALID_TYPE"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsForInLoopTypeNotIterable(
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
templateForInLoopTypeNotIterableNullability = const Template<
  Message Function(DartType _type, DartType _type2)
>(
  "ForInLoopTypeNotIterableNullability",
  problemMessageTemplate:
      r"""The type '#type' used in the 'for' loop must implement '#type2' because '#type' is nullable and '#type2' isn't.""",
  withArguments: _withArgumentsForInLoopTypeNotIterableNullability,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
codeForInLoopTypeNotIterableNullability =
    const Code<Message Function(DartType _type, DartType _type2)>(
      "ForInLoopTypeNotIterableNullability",
      analyzerCodes: <String>["FOR_IN_OF_INVALID_TYPE"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsForInLoopTypeNotIterableNullability(
  DartType _type,
  DartType _type2,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeForInLoopTypeNotIterableNullability,
    problemMessage:
        """The type '${type}' used in the 'for' loop must implement '${type2}' because '${type}' is nullable and '${type2}' isn't.""" +
        labeler.originMessages,
    arguments: {'type': _type, 'type2': _type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(
    DartType _type,
    DartType _type2,
    DartType _type3,
    DartType _type4,
  )
>
templateForInLoopTypeNotIterablePartNullability = const Template<
  Message Function(
    DartType _type,
    DartType _type2,
    DartType _type3,
    DartType _type4,
  )
>(
  "ForInLoopTypeNotIterablePartNullability",
  problemMessageTemplate:
      r"""The type '#type' used in the 'for' loop must implement '#type2' because '#type3' is nullable and '#type4' isn't.""",
  withArguments: _withArgumentsForInLoopTypeNotIterablePartNullability,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
  Message Function(
    DartType _type,
    DartType _type2,
    DartType _type3,
    DartType _type4,
  )
>
codeForInLoopTypeNotIterablePartNullability = const Code<
  Message Function(
    DartType _type,
    DartType _type2,
    DartType _type3,
    DartType _type4,
  )
>(
  "ForInLoopTypeNotIterablePartNullability",
  analyzerCodes: <String>["FOR_IN_OF_INVALID_TYPE"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsForInLoopTypeNotIterablePartNullability(
  DartType _type,
  DartType _type2,
  DartType _type3,
  DartType _type4,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  List<Object> type3Parts = labeler.labelType(_type3);
  List<Object> type4Parts = labeler.labelType(_type4);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  String type3 = type3Parts.join();
  String type4 = type4Parts.join();
  return new Message(
    codeForInLoopTypeNotIterablePartNullability,
    problemMessage:
        """The type '${type}' used in the 'for' loop must implement '${type2}' because '${type3}' is nullable and '${type4}' isn't.""" +
        labeler.originMessages,
    arguments: {
      'type': _type,
      'type2': _type2,
      'type3': _type3,
      'type4': _type4,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, DartType _type2)>
templateGenericFunctionTypeAsTypeArgumentThroughTypedef = const Template<
  Message Function(DartType _type, DartType _type2)
>(
  "GenericFunctionTypeAsTypeArgumentThroughTypedef",
  problemMessageTemplate:
      r"""Generic function type '#type' used as a type argument through typedef '#type2'.""",
  correctionMessageTemplate:
      r"""Try providing a non-generic function type explicitly.""",
  withArguments: _withArgumentsGenericFunctionTypeAsTypeArgumentThroughTypedef,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
codeGenericFunctionTypeAsTypeArgumentThroughTypedef =
    const Code<Message Function(DartType _type, DartType _type2)>(
      "GenericFunctionTypeAsTypeArgumentThroughTypedef",
      analyzerCodes: <String>["GENERIC_FUNCTION_CANNOT_BE_TYPE_ARGUMENT"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsGenericFunctionTypeAsTypeArgumentThroughTypedef(
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
templateGenericFunctionTypeInferredAsActualTypeArgument =
    const Template<Message Function(DartType _type)>(
      "GenericFunctionTypeInferredAsActualTypeArgument",
      problemMessageTemplate:
          r"""Generic function type '#type' inferred as a type argument.""",
      correctionMessageTemplate:
          r"""Try providing a non-generic function type explicitly.""",
      withArguments:
          _withArgumentsGenericFunctionTypeInferredAsActualTypeArgument,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type)>
codeGenericFunctionTypeInferredAsActualTypeArgument =
    const Code<Message Function(DartType _type)>(
      "GenericFunctionTypeInferredAsActualTypeArgument",
      analyzerCodes: <String>["GENERIC_FUNCTION_CANNOT_BE_TYPE_ARGUMENT"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsGenericFunctionTypeInferredAsActualTypeArgument(
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
templateImplicitCallOfNonMethod = const Template<
  Message Function(DartType _type)
>(
  "ImplicitCallOfNonMethod",
  problemMessageTemplate:
      r"""Cannot invoke an instance of '#type' because it declares 'call' to be something other than a method.""",
  correctionMessageTemplate:
      r"""Try changing 'call' to a method or explicitly invoke 'call'.""",
  withArguments: _withArgumentsImplicitCallOfNonMethod,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type)> codeImplicitCallOfNonMethod =
    const Code<Message Function(DartType _type)>(
      "ImplicitCallOfNonMethod",
      analyzerCodes: <String>["IMPLICIT_CALL_OF_NON_METHOD"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsImplicitCallOfNonMethod(DartType _type) {
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
templateImplicitReturnNull = const Template<Message Function(DartType _type)>(
  "ImplicitReturnNull",
  problemMessageTemplate:
      r"""A non-null value must be returned since the return type '#type' doesn't allow null.""",
  withArguments: _withArgumentsImplicitReturnNull,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type)> codeImplicitReturnNull =
    const Code<Message Function(DartType _type)>("ImplicitReturnNull");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsImplicitReturnNull(DartType _type) {
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
templateIncompatibleRedirecteeFunctionType = const Template<
  Message Function(DartType _type, DartType _type2)
>(
  "IncompatibleRedirecteeFunctionType",
  problemMessageTemplate:
      r"""The constructor function type '#type' isn't a subtype of '#type2'.""",
  withArguments: _withArgumentsIncompatibleRedirecteeFunctionType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
codeIncompatibleRedirecteeFunctionType =
    const Code<Message Function(DartType _type, DartType _type2)>(
      "IncompatibleRedirecteeFunctionType",
      analyzerCodes: <String>["REDIRECT_TO_INVALID_TYPE"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIncompatibleRedirecteeFunctionType(
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
templateIncorrectTypeArgument = const Template<
  Message Function(DartType _type, DartType _type2, String name, String name2)
>(
  "IncorrectTypeArgument",
  problemMessageTemplate:
      r"""Type argument '#type' doesn't conform to the bound '#type2' of the type variable '#name' on '#name2'.""",
  correctionMessageTemplate:
      r"""Try changing type arguments so that they conform to the bounds.""",
  withArguments: _withArgumentsIncorrectTypeArgument,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
  Message Function(DartType _type, DartType _type2, String name, String name2)
>
codeIncorrectTypeArgument = const Code<
  Message Function(DartType _type, DartType _type2, String name, String name2)
>(
  "IncorrectTypeArgument",
  analyzerCodes: <String>["TYPE_ARGUMENT_NOT_MATCHING_BOUNDS"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIncorrectTypeArgument(
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
templateIncorrectTypeArgumentInferred = const Template<
  Message Function(DartType _type, DartType _type2, String name, String name2)
>(
  "IncorrectTypeArgumentInferred",
  problemMessageTemplate:
      r"""Inferred type argument '#type' doesn't conform to the bound '#type2' of the type variable '#name' on '#name2'.""",
  correctionMessageTemplate:
      r"""Try specifying type arguments explicitly so that they conform to the bounds.""",
  withArguments: _withArgumentsIncorrectTypeArgumentInferred,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
  Message Function(DartType _type, DartType _type2, String name, String name2)
>
codeIncorrectTypeArgumentInferred = const Code<
  Message Function(DartType _type, DartType _type2, String name, String name2)
>(
  "IncorrectTypeArgumentInferred",
  analyzerCodes: <String>["TYPE_ARGUMENT_NOT_MATCHING_BOUNDS"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIncorrectTypeArgumentInferred(
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
templateIncorrectTypeArgumentInstantiation = const Template<
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
  withArguments: _withArgumentsIncorrectTypeArgumentInstantiation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
  Message Function(
    DartType _type,
    DartType _type2,
    String name,
    DartType _type3,
  )
>
codeIncorrectTypeArgumentInstantiation = const Code<
  Message Function(
    DartType _type,
    DartType _type2,
    String name,
    DartType _type3,
  )
>(
  "IncorrectTypeArgumentInstantiation",
  analyzerCodes: <String>["TYPE_ARGUMENT_NOT_MATCHING_BOUNDS"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIncorrectTypeArgumentInstantiation(
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
templateIncorrectTypeArgumentInstantiationInferred = const Template<
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
  withArguments: _withArgumentsIncorrectTypeArgumentInstantiationInferred,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
  Message Function(
    DartType _type,
    DartType _type2,
    String name,
    DartType _type3,
  )
>
codeIncorrectTypeArgumentInstantiationInferred = const Code<
  Message Function(
    DartType _type,
    DartType _type2,
    String name,
    DartType _type3,
  )
>(
  "IncorrectTypeArgumentInstantiationInferred",
  analyzerCodes: <String>["TYPE_ARGUMENT_NOT_MATCHING_BOUNDS"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIncorrectTypeArgumentInstantiationInferred(
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
templateIncorrectTypeArgumentQualified = const Template<
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
  withArguments: _withArgumentsIncorrectTypeArgumentQualified,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
  Message Function(
    DartType _type,
    DartType _type2,
    String name,
    DartType _type3,
    String name2,
  )
>
codeIncorrectTypeArgumentQualified = const Code<
  Message Function(
    DartType _type,
    DartType _type2,
    String name,
    DartType _type3,
    String name2,
  )
>(
  "IncorrectTypeArgumentQualified",
  analyzerCodes: <String>["TYPE_ARGUMENT_NOT_MATCHING_BOUNDS"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIncorrectTypeArgumentQualified(
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
templateIncorrectTypeArgumentQualifiedInferred = const Template<
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
  withArguments: _withArgumentsIncorrectTypeArgumentQualifiedInferred,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
  Message Function(
    DartType _type,
    DartType _type2,
    String name,
    DartType _type3,
    String name2,
  )
>
codeIncorrectTypeArgumentQualifiedInferred = const Code<
  Message Function(
    DartType _type,
    DartType _type2,
    String name,
    DartType _type3,
    String name2,
  )
>(
  "IncorrectTypeArgumentQualifiedInferred",
  analyzerCodes: <String>["TYPE_ARGUMENT_NOT_MATCHING_BOUNDS"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIncorrectTypeArgumentQualifiedInferred(
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
templateIndexOutOfBoundInRecordIndexGet = const Template<
  Message Function(int count, int count2, DartType _type)
>(
  "IndexOutOfBoundInRecordIndexGet",
  problemMessageTemplate:
      r"""Index #count is out of range 0..#count2 of positional fields of records #type.""",
  withArguments: _withArgumentsIndexOutOfBoundInRecordIndexGet,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(int count, int count2, DartType _type)>
codeIndexOutOfBoundInRecordIndexGet =
    const Code<Message Function(int count, int count2, DartType _type)>(
      "IndexOutOfBoundInRecordIndexGet",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIndexOutOfBoundInRecordIndexGet(
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
templateInitializingFormalTypeMismatch = const Template<
  Message Function(String name, DartType _type, DartType _type2)
>(
  "InitializingFormalTypeMismatch",
  problemMessageTemplate:
      r"""The type of parameter '#name', '#type' is not a subtype of the corresponding field's type, '#type2'.""",
  correctionMessageTemplate:
      r"""Try changing the type of parameter '#name' to a subtype of '#type2'.""",
  withArguments: _withArgumentsInitializingFormalTypeMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, DartType _type, DartType _type2)>
codeInitializingFormalTypeMismatch =
    const Code<Message Function(String name, DartType _type, DartType _type2)>(
      "InitializingFormalTypeMismatch",
      analyzerCodes: <String>["INVALID_PARAMETER_DECLARATION"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInitializingFormalTypeMismatch(
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
templateInstantiationNonGenericFunctionType = const Template<
  Message Function(DartType _type)
>(
  "InstantiationNonGenericFunctionType",
  problemMessageTemplate:
      r"""The static type of the explicit instantiation operand must be a generic function type but is '#type'.""",
  correctionMessageTemplate:
      r"""Try changing the operand or remove the type arguments.""",
  withArguments: _withArgumentsInstantiationNonGenericFunctionType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type)>
codeInstantiationNonGenericFunctionType =
    const Code<Message Function(DartType _type)>(
      "InstantiationNonGenericFunctionType",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInstantiationNonGenericFunctionType(DartType _type) {
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
templateInstantiationNullableGenericFunctionType = const Template<
  Message Function(DartType _type)
>(
  "InstantiationNullableGenericFunctionType",
  problemMessageTemplate:
      r"""The static type of the explicit instantiation operand must be a non-null generic function type but is '#type'.""",
  correctionMessageTemplate:
      r"""Try changing the operand or remove the type arguments.""",
  withArguments: _withArgumentsInstantiationNullableGenericFunctionType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type)>
codeInstantiationNullableGenericFunctionType =
    const Code<Message Function(DartType _type)>(
      "InstantiationNullableGenericFunctionType",
      analyzerCodes: <String>["DISALLOWED_TYPE_INSTANTIATION_EXPRESSION"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInstantiationNullableGenericFunctionType(DartType _type) {
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
templateInternalProblemUnsupportedNullability =
    const Template<Message Function(String string, DartType _type)>(
      "InternalProblemUnsupportedNullability",
      problemMessageTemplate:
          r"""Unsupported nullability value '#string' on type '#type'.""",
      withArguments: _withArgumentsInternalProblemUnsupportedNullability,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string, DartType _type)>
codeInternalProblemUnsupportedNullability =
    const Code<Message Function(String string, DartType _type)>(
      "InternalProblemUnsupportedNullability",
      severity: Severity.internalProblem,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemUnsupportedNullability(
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
templateInvalidAssignmentError = const Template<
  Message Function(DartType _type, DartType _type2)
>(
  "InvalidAssignmentError",
  problemMessageTemplate:
      r"""A value of type '#type' can't be assigned to a variable of type '#type2'.""",
  withArguments: _withArgumentsInvalidAssignmentError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
codeInvalidAssignmentError =
    const Code<Message Function(DartType _type, DartType _type2)>(
      "InvalidAssignmentError",
      analyzerCodes: <String>["INVALID_ASSIGNMENT"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidAssignmentError(DartType _type, DartType _type2) {
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
templateInvalidAssignmentErrorNullability = const Template<
  Message Function(DartType _type, DartType _type2)
>(
  "InvalidAssignmentErrorNullability",
  problemMessageTemplate:
      r"""A value of type '#type' can't be assigned to a variable of type '#type2' because '#type' is nullable and '#type2' isn't.""",
  withArguments: _withArgumentsInvalidAssignmentErrorNullability,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
codeInvalidAssignmentErrorNullability =
    const Code<Message Function(DartType _type, DartType _type2)>(
      "InvalidAssignmentErrorNullability",
      analyzerCodes: <String>["INVALID_ASSIGNMENT"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidAssignmentErrorNullability(
  DartType _type,
  DartType _type2,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeInvalidAssignmentErrorNullability,
    problemMessage:
        """A value of type '${type}' can't be assigned to a variable of type '${type2}' because '${type}' is nullable and '${type2}' isn't.""" +
        labeler.originMessages,
    arguments: {'type': _type, 'type2': _type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type)>
templateInvalidAssignmentErrorNullabilityNull = const Template<
  Message Function(DartType _type)
>(
  "InvalidAssignmentErrorNullabilityNull",
  problemMessageTemplate:
      r"""The value 'null' can't be assigned to a variable of type '#type' because '#type' is not nullable.""",
  withArguments: _withArgumentsInvalidAssignmentErrorNullabilityNull,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type)>
codeInvalidAssignmentErrorNullabilityNull =
    const Code<Message Function(DartType _type)>(
      "InvalidAssignmentErrorNullabilityNull",
      analyzerCodes: <String>["INVALID_ASSIGNMENT"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidAssignmentErrorNullabilityNull(DartType _type) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeInvalidAssignmentErrorNullabilityNull,
    problemMessage:
        """The value 'null' can't be assigned to a variable of type '${type}' because '${type}' is not nullable.""" +
        labeler.originMessages,
    arguments: {'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, DartType _type2)>
templateInvalidAssignmentErrorNullabilityNullType = const Template<
  Message Function(DartType _type, DartType _type2)
>(
  "InvalidAssignmentErrorNullabilityNullType",
  problemMessageTemplate:
      r"""A value of type '#type' can't be assigned to a variable of type '#type2' because '#type2' is not nullable.""",
  withArguments: _withArgumentsInvalidAssignmentErrorNullabilityNullType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
codeInvalidAssignmentErrorNullabilityNullType =
    const Code<Message Function(DartType _type, DartType _type2)>(
      "InvalidAssignmentErrorNullabilityNullType",
      analyzerCodes: <String>["INVALID_ASSIGNMENT"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidAssignmentErrorNullabilityNullType(
  DartType _type,
  DartType _type2,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeInvalidAssignmentErrorNullabilityNullType,
    problemMessage:
        """A value of type '${type}' can't be assigned to a variable of type '${type2}' because '${type2}' is not nullable.""" +
        labeler.originMessages,
    arguments: {'type': _type, 'type2': _type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(
    DartType _type,
    DartType _type2,
    DartType _type3,
    DartType _type4,
  )
>
templateInvalidAssignmentErrorPartNullability = const Template<
  Message Function(
    DartType _type,
    DartType _type2,
    DartType _type3,
    DartType _type4,
  )
>(
  "InvalidAssignmentErrorPartNullability",
  problemMessageTemplate:
      r"""A value of type '#type' can't be assigned to a variable of type '#type2' because '#type3' is nullable and '#type4' isn't.""",
  withArguments: _withArgumentsInvalidAssignmentErrorPartNullability,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
  Message Function(
    DartType _type,
    DartType _type2,
    DartType _type3,
    DartType _type4,
  )
>
codeInvalidAssignmentErrorPartNullability = const Code<
  Message Function(
    DartType _type,
    DartType _type2,
    DartType _type3,
    DartType _type4,
  )
>(
  "InvalidAssignmentErrorPartNullability",
  analyzerCodes: <String>["INVALID_ASSIGNMENT"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidAssignmentErrorPartNullability(
  DartType _type,
  DartType _type2,
  DartType _type3,
  DartType _type4,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  List<Object> type3Parts = labeler.labelType(_type3);
  List<Object> type4Parts = labeler.labelType(_type4);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  String type3 = type3Parts.join();
  String type4 = type4Parts.join();
  return new Message(
    codeInvalidAssignmentErrorPartNullability,
    problemMessage:
        """A value of type '${type}' can't be assigned to a variable of type '${type2}' because '${type3}' is nullable and '${type4}' isn't.""" +
        labeler.originMessages,
    arguments: {
      'type': _type,
      'type2': _type2,
      'type3': _type3,
      'type4': _type4,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, DartType _type2)>
templateInvalidCastFunctionExpr = const Template<
  Message Function(DartType _type, DartType _type2)
>(
  "InvalidCastFunctionExpr",
  problemMessageTemplate:
      r"""The function expression type '#type' isn't of expected type '#type2'.""",
  correctionMessageTemplate:
      r"""Change the type of the function expression or the context in which it is used.""",
  withArguments: _withArgumentsInvalidCastFunctionExpr,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
codeInvalidCastFunctionExpr =
    const Code<Message Function(DartType _type, DartType _type2)>(
      "InvalidCastFunctionExpr",
      analyzerCodes: <String>["INVALID_CAST_FUNCTION_EXPR"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidCastFunctionExpr(DartType _type, DartType _type2) {
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
templateInvalidCastLiteralList = const Template<
  Message Function(DartType _type, DartType _type2)
>(
  "InvalidCastLiteralList",
  problemMessageTemplate:
      r"""The list literal type '#type' isn't of expected type '#type2'.""",
  correctionMessageTemplate:
      r"""Change the type of the list literal or the context in which it is used.""",
  withArguments: _withArgumentsInvalidCastLiteralList,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
codeInvalidCastLiteralList =
    const Code<Message Function(DartType _type, DartType _type2)>(
      "InvalidCastLiteralList",
      analyzerCodes: <String>["INVALID_CAST_LITERAL_LIST"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidCastLiteralList(DartType _type, DartType _type2) {
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
templateInvalidCastLiteralMap = const Template<
  Message Function(DartType _type, DartType _type2)
>(
  "InvalidCastLiteralMap",
  problemMessageTemplate:
      r"""The map literal type '#type' isn't of expected type '#type2'.""",
  correctionMessageTemplate:
      r"""Change the type of the map literal or the context in which it is used.""",
  withArguments: _withArgumentsInvalidCastLiteralMap,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
codeInvalidCastLiteralMap =
    const Code<Message Function(DartType _type, DartType _type2)>(
      "InvalidCastLiteralMap",
      analyzerCodes: <String>["INVALID_CAST_LITERAL_MAP"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidCastLiteralMap(DartType _type, DartType _type2) {
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
templateInvalidCastLiteralSet = const Template<
  Message Function(DartType _type, DartType _type2)
>(
  "InvalidCastLiteralSet",
  problemMessageTemplate:
      r"""The set literal type '#type' isn't of expected type '#type2'.""",
  correctionMessageTemplate:
      r"""Change the type of the set literal or the context in which it is used.""",
  withArguments: _withArgumentsInvalidCastLiteralSet,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
codeInvalidCastLiteralSet =
    const Code<Message Function(DartType _type, DartType _type2)>(
      "InvalidCastLiteralSet",
      analyzerCodes: <String>["INVALID_CAST_LITERAL_SET"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidCastLiteralSet(DartType _type, DartType _type2) {
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
templateInvalidCastLocalFunction = const Template<
  Message Function(DartType _type, DartType _type2)
>(
  "InvalidCastLocalFunction",
  problemMessageTemplate:
      r"""The local function has type '#type' that isn't of expected type '#type2'.""",
  correctionMessageTemplate:
      r"""Change the type of the function or the context in which it is used.""",
  withArguments: _withArgumentsInvalidCastLocalFunction,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
codeInvalidCastLocalFunction =
    const Code<Message Function(DartType _type, DartType _type2)>(
      "InvalidCastLocalFunction",
      analyzerCodes: <String>["INVALID_CAST_FUNCTION"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidCastLocalFunction(
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
templateInvalidCastNewExpr = const Template<
  Message Function(DartType _type, DartType _type2)
>(
  "InvalidCastNewExpr",
  problemMessageTemplate:
      r"""The constructor returns type '#type' that isn't of expected type '#type2'.""",
  correctionMessageTemplate:
      r"""Change the type of the object being constructed or the context in which it is used.""",
  withArguments: _withArgumentsInvalidCastNewExpr,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
codeInvalidCastNewExpr =
    const Code<Message Function(DartType _type, DartType _type2)>(
      "InvalidCastNewExpr",
      analyzerCodes: <String>["INVALID_CAST_NEW_EXPR"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidCastNewExpr(DartType _type, DartType _type2) {
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
templateInvalidCastStaticMethod = const Template<
  Message Function(DartType _type, DartType _type2)
>(
  "InvalidCastStaticMethod",
  problemMessageTemplate:
      r"""The static method has type '#type' that isn't of expected type '#type2'.""",
  correctionMessageTemplate:
      r"""Change the type of the method or the context in which it is used.""",
  withArguments: _withArgumentsInvalidCastStaticMethod,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
codeInvalidCastStaticMethod =
    const Code<Message Function(DartType _type, DartType _type2)>(
      "InvalidCastStaticMethod",
      analyzerCodes: <String>["INVALID_CAST_METHOD"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidCastStaticMethod(DartType _type, DartType _type2) {
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
templateInvalidCastTopLevelFunction = const Template<
  Message Function(DartType _type, DartType _type2)
>(
  "InvalidCastTopLevelFunction",
  problemMessageTemplate:
      r"""The top level function has type '#type' that isn't of expected type '#type2'.""",
  correctionMessageTemplate:
      r"""Change the type of the function or the context in which it is used.""",
  withArguments: _withArgumentsInvalidCastTopLevelFunction,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
codeInvalidCastTopLevelFunction =
    const Code<Message Function(DartType _type, DartType _type2)>(
      "InvalidCastTopLevelFunction",
      analyzerCodes: <String>["INVALID_CAST_FUNCTION"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidCastTopLevelFunction(
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
templateInvalidExtensionTypeSuperExtensionType = const Template<
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
  withArguments: _withArgumentsInvalidExtensionTypeSuperExtensionType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
  Message Function(
    DartType _type,
    String name,
    DartType _type2,
    DartType _type3,
  )
>
codeInvalidExtensionTypeSuperExtensionType = const Code<
  Message Function(
    DartType _type,
    String name,
    DartType _type2,
    DartType _type3,
  )
>("InvalidExtensionTypeSuperExtensionType");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidExtensionTypeSuperExtensionType(
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
templateInvalidExtensionTypeSuperInterface = const Template<
  Message Function(DartType _type, DartType _type2, String name)
>(
  "InvalidExtensionTypeSuperInterface",
  problemMessageTemplate:
      r"""The implemented interface '#type' must be a supertype of the representation type '#type2' of extension type '#name'.""",
  correctionMessageTemplate:
      r"""Try changing the interface type to a supertype of '#type2' or the representation type to a subtype of '#type'.""",
  withArguments: _withArgumentsInvalidExtensionTypeSuperInterface,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2, String name)>
codeInvalidExtensionTypeSuperInterface =
    const Code<Message Function(DartType _type, DartType _type2, String name)>(
      "InvalidExtensionTypeSuperInterface",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidExtensionTypeSuperInterface(
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
templateInvalidGetterSetterType = const Template<
  Message Function(DartType _type, String name, DartType _type2, String name2)
>(
  "InvalidGetterSetterType",
  problemMessageTemplate:
      r"""The type '#type' of the getter '#name' is not a subtype of the type '#type2' of the setter '#name2'.""",
  withArguments: _withArgumentsInvalidGetterSetterType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
  Message Function(DartType _type, String name, DartType _type2, String name2)
>
codeInvalidGetterSetterType = const Code<
  Message Function(DartType _type, String name, DartType _type2, String name2)
>("InvalidGetterSetterType");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidGetterSetterType(
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
templateInvalidGetterSetterTypeBothInheritedField = const Template<
  Message Function(DartType _type, String name, DartType _type2, String name2)
>(
  "InvalidGetterSetterTypeBothInheritedField",
  problemMessageTemplate:
      r"""The type '#type' of the inherited field '#name' is not a subtype of the type '#type2' of the inherited setter '#name2'.""",
  withArguments: _withArgumentsInvalidGetterSetterTypeBothInheritedField,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
  Message Function(DartType _type, String name, DartType _type2, String name2)
>
codeInvalidGetterSetterTypeBothInheritedField = const Code<
  Message Function(DartType _type, String name, DartType _type2, String name2)
>("InvalidGetterSetterTypeBothInheritedField");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidGetterSetterTypeBothInheritedField(
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
templateInvalidGetterSetterTypeBothInheritedGetter = const Template<
  Message Function(DartType _type, String name, DartType _type2, String name2)
>(
  "InvalidGetterSetterTypeBothInheritedGetter",
  problemMessageTemplate:
      r"""The type '#type' of the inherited getter '#name' is not a subtype of the type '#type2' of the inherited setter '#name2'.""",
  withArguments: _withArgumentsInvalidGetterSetterTypeBothInheritedGetter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
  Message Function(DartType _type, String name, DartType _type2, String name2)
>
codeInvalidGetterSetterTypeBothInheritedGetter = const Code<
  Message Function(DartType _type, String name, DartType _type2, String name2)
>("InvalidGetterSetterTypeBothInheritedGetter");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidGetterSetterTypeBothInheritedGetter(
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
templateInvalidGetterSetterTypeFieldInherited = const Template<
  Message Function(DartType _type, String name, DartType _type2, String name2)
>(
  "InvalidGetterSetterTypeFieldInherited",
  problemMessageTemplate:
      r"""The type '#type' of the inherited field '#name' is not a subtype of the type '#type2' of the setter '#name2'.""",
  withArguments: _withArgumentsInvalidGetterSetterTypeFieldInherited,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
  Message Function(DartType _type, String name, DartType _type2, String name2)
>
codeInvalidGetterSetterTypeFieldInherited = const Code<
  Message Function(DartType _type, String name, DartType _type2, String name2)
>("InvalidGetterSetterTypeFieldInherited");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidGetterSetterTypeFieldInherited(
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
templateInvalidGetterSetterTypeGetterInherited = const Template<
  Message Function(DartType _type, String name, DartType _type2, String name2)
>(
  "InvalidGetterSetterTypeGetterInherited",
  problemMessageTemplate:
      r"""The type '#type' of the inherited getter '#name' is not a subtype of the type '#type2' of the setter '#name2'.""",
  withArguments: _withArgumentsInvalidGetterSetterTypeGetterInherited,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
  Message Function(DartType _type, String name, DartType _type2, String name2)
>
codeInvalidGetterSetterTypeGetterInherited = const Code<
  Message Function(DartType _type, String name, DartType _type2, String name2)
>("InvalidGetterSetterTypeGetterInherited");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidGetterSetterTypeGetterInherited(
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
templateInvalidGetterSetterTypeSetterInheritedField = const Template<
  Message Function(DartType _type, String name, DartType _type2, String name2)
>(
  "InvalidGetterSetterTypeSetterInheritedField",
  problemMessageTemplate:
      r"""The type '#type' of the field '#name' is not a subtype of the type '#type2' of the inherited setter '#name2'.""",
  withArguments: _withArgumentsInvalidGetterSetterTypeSetterInheritedField,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
  Message Function(DartType _type, String name, DartType _type2, String name2)
>
codeInvalidGetterSetterTypeSetterInheritedField = const Code<
  Message Function(DartType _type, String name, DartType _type2, String name2)
>("InvalidGetterSetterTypeSetterInheritedField");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidGetterSetterTypeSetterInheritedField(
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
templateInvalidGetterSetterTypeSetterInheritedGetter = const Template<
  Message Function(DartType _type, String name, DartType _type2, String name2)
>(
  "InvalidGetterSetterTypeSetterInheritedGetter",
  problemMessageTemplate:
      r"""The type '#type' of the getter '#name' is not a subtype of the type '#type2' of the inherited setter '#name2'.""",
  withArguments: _withArgumentsInvalidGetterSetterTypeSetterInheritedGetter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
  Message Function(DartType _type, String name, DartType _type2, String name2)
>
codeInvalidGetterSetterTypeSetterInheritedGetter = const Code<
  Message Function(DartType _type, String name, DartType _type2, String name2)
>("InvalidGetterSetterTypeSetterInheritedGetter");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidGetterSetterTypeSetterInheritedGetter(
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
templateInvalidReturn = const Template<
  Message Function(DartType _type, DartType _type2)
>(
  "InvalidReturn",
  problemMessageTemplate:
      r"""A value of type '#type' can't be returned from a function with return type '#type2'.""",
  withArguments: _withArgumentsInvalidReturn,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
codeInvalidReturn =
    const Code<Message Function(DartType _type, DartType _type2)>(
      "InvalidReturn",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidReturn(DartType _type, DartType _type2) {
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
templateInvalidReturnAsync = const Template<
  Message Function(DartType _type, DartType _type2)
>(
  "InvalidReturnAsync",
  problemMessageTemplate:
      r"""A value of type '#type' can't be returned from an async function with return type '#type2'.""",
  withArguments: _withArgumentsInvalidReturnAsync,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
codeInvalidReturnAsync =
    const Code<Message Function(DartType _type, DartType _type2)>(
      "InvalidReturnAsync",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidReturnAsync(DartType _type, DartType _type2) {
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
const Template<Message Function(DartType _type, DartType _type2)>
templateInvalidReturnAsyncNullability = const Template<
  Message Function(DartType _type, DartType _type2)
>(
  "InvalidReturnAsyncNullability",
  problemMessageTemplate:
      r"""A value of type '#type' can't be returned from an async function with return type '#type2' because '#type' is nullable and '#type2' isn't.""",
  withArguments: _withArgumentsInvalidReturnAsyncNullability,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
codeInvalidReturnAsyncNullability =
    const Code<Message Function(DartType _type, DartType _type2)>(
      "InvalidReturnAsyncNullability",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidReturnAsyncNullability(
  DartType _type,
  DartType _type2,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeInvalidReturnAsyncNullability,
    problemMessage:
        """A value of type '${type}' can't be returned from an async function with return type '${type2}' because '${type}' is nullable and '${type2}' isn't.""" +
        labeler.originMessages,
    arguments: {'type': _type, 'type2': _type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type)>
templateInvalidReturnAsyncNullabilityNull = const Template<
  Message Function(DartType _type)
>(
  "InvalidReturnAsyncNullabilityNull",
  problemMessageTemplate:
      r"""The value 'null' can't be returned from an async function with return type '#type' because '#type' is not nullable.""",
  withArguments: _withArgumentsInvalidReturnAsyncNullabilityNull,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type)>
codeInvalidReturnAsyncNullabilityNull =
    const Code<Message Function(DartType _type)>(
      "InvalidReturnAsyncNullabilityNull",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidReturnAsyncNullabilityNull(DartType _type) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeInvalidReturnAsyncNullabilityNull,
    problemMessage:
        """The value 'null' can't be returned from an async function with return type '${type}' because '${type}' is not nullable.""" +
        labeler.originMessages,
    arguments: {'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, DartType _type2)>
templateInvalidReturnAsyncNullabilityNullType = const Template<
  Message Function(DartType _type, DartType _type2)
>(
  "InvalidReturnAsyncNullabilityNullType",
  problemMessageTemplate:
      r"""A value of type '#type' can't be returned from an async function with return type '#type2' because '#type2' is not nullable.""",
  withArguments: _withArgumentsInvalidReturnAsyncNullabilityNullType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
codeInvalidReturnAsyncNullabilityNullType =
    const Code<Message Function(DartType _type, DartType _type2)>(
      "InvalidReturnAsyncNullabilityNullType",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidReturnAsyncNullabilityNullType(
  DartType _type,
  DartType _type2,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeInvalidReturnAsyncNullabilityNullType,
    problemMessage:
        """A value of type '${type}' can't be returned from an async function with return type '${type2}' because '${type2}' is not nullable.""" +
        labeler.originMessages,
    arguments: {'type': _type, 'type2': _type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(
    DartType _type,
    DartType _type2,
    DartType _type3,
    DartType _type4,
  )
>
templateInvalidReturnAsyncPartNullability = const Template<
  Message Function(
    DartType _type,
    DartType _type2,
    DartType _type3,
    DartType _type4,
  )
>(
  "InvalidReturnAsyncPartNullability",
  problemMessageTemplate:
      r"""A value of type '#type' can't be returned from an async function with return type '#type2' because '#type3' is nullable and '#type4' isn't.""",
  withArguments: _withArgumentsInvalidReturnAsyncPartNullability,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
  Message Function(
    DartType _type,
    DartType _type2,
    DartType _type3,
    DartType _type4,
  )
>
codeInvalidReturnAsyncPartNullability = const Code<
  Message Function(
    DartType _type,
    DartType _type2,
    DartType _type3,
    DartType _type4,
  )
>("InvalidReturnAsyncPartNullability");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidReturnAsyncPartNullability(
  DartType _type,
  DartType _type2,
  DartType _type3,
  DartType _type4,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  List<Object> type3Parts = labeler.labelType(_type3);
  List<Object> type4Parts = labeler.labelType(_type4);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  String type3 = type3Parts.join();
  String type4 = type4Parts.join();
  return new Message(
    codeInvalidReturnAsyncPartNullability,
    problemMessage:
        """A value of type '${type}' can't be returned from an async function with return type '${type2}' because '${type3}' is nullable and '${type4}' isn't.""" +
        labeler.originMessages,
    arguments: {
      'type': _type,
      'type2': _type2,
      'type3': _type3,
      'type4': _type4,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, DartType _type2)>
templateInvalidReturnNullability = const Template<
  Message Function(DartType _type, DartType _type2)
>(
  "InvalidReturnNullability",
  problemMessageTemplate:
      r"""A value of type '#type' can't be returned from a function with return type '#type2' because '#type' is nullable and '#type2' isn't.""",
  withArguments: _withArgumentsInvalidReturnNullability,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
codeInvalidReturnNullability =
    const Code<Message Function(DartType _type, DartType _type2)>(
      "InvalidReturnNullability",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidReturnNullability(
  DartType _type,
  DartType _type2,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeInvalidReturnNullability,
    problemMessage:
        """A value of type '${type}' can't be returned from a function with return type '${type2}' because '${type}' is nullable and '${type2}' isn't.""" +
        labeler.originMessages,
    arguments: {'type': _type, 'type2': _type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type)>
templateInvalidReturnNullabilityNull = const Template<
  Message Function(DartType _type)
>(
  "InvalidReturnNullabilityNull",
  problemMessageTemplate:
      r"""The value 'null' can't be returned from a function with return type '#type' because '#type' is not nullable.""",
  withArguments: _withArgumentsInvalidReturnNullabilityNull,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type)> codeInvalidReturnNullabilityNull =
    const Code<Message Function(DartType _type)>(
      "InvalidReturnNullabilityNull",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidReturnNullabilityNull(DartType _type) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeInvalidReturnNullabilityNull,
    problemMessage:
        """The value 'null' can't be returned from a function with return type '${type}' because '${type}' is not nullable.""" +
        labeler.originMessages,
    arguments: {'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, DartType _type2)>
templateInvalidReturnNullabilityNullType = const Template<
  Message Function(DartType _type, DartType _type2)
>(
  "InvalidReturnNullabilityNullType",
  problemMessageTemplate:
      r"""A value of type '#type' can't be returned from a function with return type '#type2' because '#type2' is not nullable.""",
  withArguments: _withArgumentsInvalidReturnNullabilityNullType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
codeInvalidReturnNullabilityNullType =
    const Code<Message Function(DartType _type, DartType _type2)>(
      "InvalidReturnNullabilityNullType",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidReturnNullabilityNullType(
  DartType _type,
  DartType _type2,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeInvalidReturnNullabilityNullType,
    problemMessage:
        """A value of type '${type}' can't be returned from a function with return type '${type2}' because '${type2}' is not nullable.""" +
        labeler.originMessages,
    arguments: {'type': _type, 'type2': _type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(
    DartType _type,
    DartType _type2,
    DartType _type3,
    DartType _type4,
  )
>
templateInvalidReturnPartNullability = const Template<
  Message Function(
    DartType _type,
    DartType _type2,
    DartType _type3,
    DartType _type4,
  )
>(
  "InvalidReturnPartNullability",
  problemMessageTemplate:
      r"""A value of type '#type' can't be returned from a function with return type '#type2' because '#type3' is nullable and '#type4' isn't.""",
  withArguments: _withArgumentsInvalidReturnPartNullability,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
  Message Function(
    DartType _type,
    DartType _type2,
    DartType _type3,
    DartType _type4,
  )
>
codeInvalidReturnPartNullability = const Code<
  Message Function(
    DartType _type,
    DartType _type2,
    DartType _type3,
    DartType _type4,
  )
>("InvalidReturnPartNullability");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidReturnPartNullability(
  DartType _type,
  DartType _type2,
  DartType _type3,
  DartType _type4,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  List<Object> type3Parts = labeler.labelType(_type3);
  List<Object> type4Parts = labeler.labelType(_type4);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  String type3 = type3Parts.join();
  String type4 = type4Parts.join();
  return new Message(
    codeInvalidReturnPartNullability,
    problemMessage:
        """A value of type '${type}' can't be returned from a function with return type '${type2}' because '${type3}' is nullable and '${type4}' isn't.""" +
        labeler.originMessages,
    arguments: {
      'type': _type,
      'type2': _type2,
      'type3': _type3,
      'type4': _type4,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type)>
templateJsInteropExportInvalidInteropTypeArgument =
    const Template<Message Function(DartType _type)>(
      "JsInteropExportInvalidInteropTypeArgument",
      problemMessageTemplate:
          r"""Type argument '#type' needs to be a non-JS interop type.""",
      correctionMessageTemplate:
          r"""Use a non-JS interop class that uses `@JSExport` instead.""",
      withArguments: _withArgumentsJsInteropExportInvalidInteropTypeArgument,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type)>
codeJsInteropExportInvalidInteropTypeArgument =
    const Code<Message Function(DartType _type)>(
      "JsInteropExportInvalidInteropTypeArgument",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropExportInvalidInteropTypeArgument(
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
templateJsInteropExportInvalidTypeArgument =
    const Template<Message Function(DartType _type)>(
      "JsInteropExportInvalidTypeArgument",
      problemMessageTemplate:
          r"""Type argument '#type' needs to be an interface type.""",
      correctionMessageTemplate:
          r"""Use a non-JS interop class that uses `@JSExport` instead.""",
      withArguments: _withArgumentsJsInteropExportInvalidTypeArgument,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type)>
codeJsInteropExportInvalidTypeArgument =
    const Code<Message Function(DartType _type)>(
      "JsInteropExportInvalidTypeArgument",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropExportInvalidTypeArgument(DartType _type) {
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
templateJsInteropExtensionTypeNotInterop = const Template<
  Message Function(String name, DartType _type)
>(
  "JsInteropExtensionTypeNotInterop",
  problemMessageTemplate:
      r"""Extension type '#name' is marked with a '@JS' annotation, but its representation type is not a valid JS interop type: '#type'.""",
  correctionMessageTemplate:
      r"""Try declaring a valid JS interop representation type, which may include 'dart:js_interop' types, '@staticInterop' types, 'dart:html' types, or other interop extension types.""",
  withArguments: _withArgumentsJsInteropExtensionTypeNotInterop,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, DartType _type)>
codeJsInteropExtensionTypeNotInterop =
    const Code<Message Function(String name, DartType _type)>(
      "JsInteropExtensionTypeNotInterop",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropExtensionTypeNotInterop(
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
templateJsInteropFunctionToJSRequiresStaticType = const Template<
  Message Function(DartType _type)
>(
  "JsInteropFunctionToJSRequiresStaticType",
  problemMessageTemplate:
      r"""`Function.toJS` requires a statically known function type, but Type '#type' is not a precise function type, e.g., `void Function()`.""",
  correctionMessageTemplate:
      r"""Insert an explicit cast to the expected function type.""",
  withArguments: _withArgumentsJsInteropFunctionToJSRequiresStaticType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type)>
codeJsInteropFunctionToJSRequiresStaticType =
    const Code<Message Function(DartType _type)>(
      "JsInteropFunctionToJSRequiresStaticType",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropFunctionToJSRequiresStaticType(DartType _type) {
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
templateJsInteropIsAInvalidTypeVariable = const Template<
  Message Function(DartType _type)
>(
  "JsInteropIsAInvalidTypeVariable",
  problemMessageTemplate:
      r"""Type argument '#type' provided to 'isA' cannot be a type variable and must be an interop extension type that can be determined at compile-time.""",
  correctionMessageTemplate:
      r"""Use a valid interop extension type that can be determined at compile-time as the type argument instead.""",
  withArguments: _withArgumentsJsInteropIsAInvalidTypeVariable,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type)>
codeJsInteropIsAInvalidTypeVariable =
    const Code<Message Function(DartType _type)>(
      "JsInteropIsAInvalidTypeVariable",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropIsAInvalidTypeVariable(DartType _type) {
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
templateJsInteropIsAObjectLiteralType = const Template<
  Message Function(DartType _type)
>(
  "JsInteropIsAObjectLiteralType",
  problemMessageTemplate:
      r"""Type argument '#type' has an object literal constructor. Because 'isA' uses the type's name or '@JS()' rename, this may result in an incorrect type check.""",
  correctionMessageTemplate:
      r"""Use 'JSObject' as the type argument instead.""",
  withArguments: _withArgumentsJsInteropIsAObjectLiteralType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type)> codeJsInteropIsAObjectLiteralType =
    const Code<Message Function(DartType _type)>(
      "JsInteropIsAObjectLiteralType",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropIsAObjectLiteralType(DartType _type) {
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
templateJsInteropIsAPrimitiveExtensionType = const Template<
  Message Function(DartType _type, String string)
>(
  "JsInteropIsAPrimitiveExtensionType",
  problemMessageTemplate:
      r"""Type argument '#type' wraps primitive JS type '#string', which is specially handled using 'typeof'.""",
  correctionMessageTemplate:
      r"""Use the primitive JS type '#string' as the type argument instead.""",
  withArguments: _withArgumentsJsInteropIsAPrimitiveExtensionType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, String string)>
codeJsInteropIsAPrimitiveExtensionType =
    const Code<Message Function(DartType _type, String string)>(
      "JsInteropIsAPrimitiveExtensionType",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropIsAPrimitiveExtensionType(
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
templateJsInteropStaticInteropExternalAccessorTypeViolation = const Template<
  Message Function(DartType _type)
>(
  "JsInteropStaticInteropExternalAccessorTypeViolation",
  problemMessageTemplate:
      r"""External JS interop member contains an invalid type: '#type'.""",
  correctionMessageTemplate:
      r"""Use one of these valid types instead: JS types from 'dart:js_interop', ExternalDartReference, void, bool, num, double, int, String, extension types that erase to one of these types, '@staticInterop' types, 'dart:html' types when compiling to JS, or a type parameter that is a subtype of a valid non-primitive type.""",
  withArguments:
      _withArgumentsJsInteropStaticInteropExternalAccessorTypeViolation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type)>
codeJsInteropStaticInteropExternalAccessorTypeViolation =
    const Code<Message Function(DartType _type)>(
      "JsInteropStaticInteropExternalAccessorTypeViolation",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropStaticInteropExternalAccessorTypeViolation(
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
templateJsInteropStaticInteropMockNotStaticInteropType =
    const Template<Message Function(DartType _type)>(
      "JsInteropStaticInteropMockNotStaticInteropType",
      problemMessageTemplate:
          r"""Type argument '#type' needs to be a `@staticInterop` type.""",
      correctionMessageTemplate: r"""Use a `@staticInterop` class instead.""",
      withArguments:
          _withArgumentsJsInteropStaticInteropMockNotStaticInteropType,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type)>
codeJsInteropStaticInteropMockNotStaticInteropType =
    const Code<Message Function(DartType _type)>(
      "JsInteropStaticInteropMockNotStaticInteropType",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropStaticInteropMockNotStaticInteropType(
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
templateJsInteropStaticInteropMockTypeParametersNotAllowed = const Template<
  Message Function(DartType _type)
>(
  "JsInteropStaticInteropMockTypeParametersNotAllowed",
  problemMessageTemplate:
      r"""Type argument '#type' has type parameters that do not match their bound. createStaticInteropMock requires instantiating all type parameters to their bound to ensure mocking conformance.""",
  correctionMessageTemplate:
      r"""Remove the type parameter in the type argument or replace it with its bound.""",
  withArguments:
      _withArgumentsJsInteropStaticInteropMockTypeParametersNotAllowed,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type)>
codeJsInteropStaticInteropMockTypeParametersNotAllowed =
    const Code<Message Function(DartType _type)>(
      "JsInteropStaticInteropMockTypeParametersNotAllowed",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropStaticInteropMockTypeParametersNotAllowed(
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
templateMainWrongParameterType = const Template<
  Message Function(DartType _type, DartType _type2)
>(
  "MainWrongParameterType",
  problemMessageTemplate:
      r"""The type '#type' of the first parameter of the 'main' method is not a supertype of '#type2'.""",
  withArguments: _withArgumentsMainWrongParameterType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
codeMainWrongParameterType =
    const Code<Message Function(DartType _type, DartType _type2)>(
      "MainWrongParameterType",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMainWrongParameterType(DartType _type, DartType _type2) {
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
templateMainWrongParameterTypeExported = const Template<
  Message Function(DartType _type, DartType _type2)
>(
  "MainWrongParameterTypeExported",
  problemMessageTemplate:
      r"""The type '#type' of the first parameter of the exported 'main' method is not a supertype of '#type2'.""",
  withArguments: _withArgumentsMainWrongParameterTypeExported,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
codeMainWrongParameterTypeExported =
    const Code<Message Function(DartType _type, DartType _type2)>(
      "MainWrongParameterTypeExported",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMainWrongParameterTypeExported(
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
templateMixinApplicationIncompatibleSupertype = const Template<
  Message Function(DartType _type, DartType _type2, DartType _type3)
>(
  "MixinApplicationIncompatibleSupertype",
  problemMessageTemplate:
      r"""'#type' doesn't implement '#type2' so it can't be used with '#type3'.""",
  withArguments: _withArgumentsMixinApplicationIncompatibleSupertype,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2, DartType _type3)>
codeMixinApplicationIncompatibleSupertype = const Code<
  Message Function(DartType _type, DartType _type2, DartType _type3)
>(
  "MixinApplicationIncompatibleSupertype",
  analyzerCodes: <String>["MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMixinApplicationIncompatibleSupertype(
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
templateMixinInferenceNoMatchingClass = const Template<
  Message Function(String name, String name2, DartType _type)
>(
  "MixinInferenceNoMatchingClass",
  problemMessageTemplate:
      r"""Type parameters couldn't be inferred for the mixin '#name' because '#name2' does not implement the mixin's supertype constraint '#type'.""",
  withArguments: _withArgumentsMixinInferenceNoMatchingClass,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String name2, DartType _type)>
codeMixinInferenceNoMatchingClass =
    const Code<Message Function(String name, String name2, DartType _type)>(
      "MixinInferenceNoMatchingClass",
      analyzerCodes: <String>["MIXIN_INFERENCE_NO_POSSIBLE_SUBSTITUTION"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMixinInferenceNoMatchingClass(
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
templateNameNotFoundInRecordNameGet =
    const Template<Message Function(String string, DartType _type)>(
      "NameNotFoundInRecordNameGet",
      problemMessageTemplate:
          r"""Field name #string isn't found in records of type #type.""",
      withArguments: _withArgumentsNameNotFoundInRecordNameGet,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string, DartType _type)>
codeNameNotFoundInRecordNameGet =
    const Code<Message Function(String string, DartType _type)>(
      "NameNotFoundInRecordNameGet",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNameNotFoundInRecordNameGet(
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
templateNonExhaustiveSwitchExpression = const Template<
  Message Function(DartType _type, String string, String string2)
>(
  "NonExhaustiveSwitchExpression",
  problemMessageTemplate:
      r"""The type '#type' is not exhaustively matched by the switch cases since it doesn't match '#string'.""",
  correctionMessageTemplate:
      r"""Try adding a wildcard pattern or cases that match '#string2'.""",
  withArguments: _withArgumentsNonExhaustiveSwitchExpression,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, String string, String string2)>
codeNonExhaustiveSwitchExpression =
    const Code<Message Function(DartType _type, String string, String string2)>(
      "NonExhaustiveSwitchExpression",
      analyzerCodes: <String>["NON_EXHAUSTIVE_SWITCH_EXPRESSION"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonExhaustiveSwitchExpression(
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
templateNonExhaustiveSwitchStatement = const Template<
  Message Function(DartType _type, String string, String string2)
>(
  "NonExhaustiveSwitchStatement",
  problemMessageTemplate:
      r"""The type '#type' is not exhaustively matched by the switch cases since it doesn't match '#string'.""",
  correctionMessageTemplate:
      r"""Try adding a default case or cases that match '#string2'.""",
  withArguments: _withArgumentsNonExhaustiveSwitchStatement,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, String string, String string2)>
codeNonExhaustiveSwitchStatement =
    const Code<Message Function(DartType _type, String string, String string2)>(
      "NonExhaustiveSwitchStatement",
      analyzerCodes: <String>["NON_EXHAUSTIVE_SWITCH_STATEMENT"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonExhaustiveSwitchStatement(
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
const Template<Message Function(DartType _type)>
templateNonNullAwareSpreadIsNull =
    const Template<Message Function(DartType _type)>(
      "NonNullAwareSpreadIsNull",
      problemMessageTemplate:
          r"""Can't spread a value with static type '#type'.""",
      withArguments: _withArgumentsNonNullAwareSpreadIsNull,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type)> codeNonNullAwareSpreadIsNull =
    const Code<Message Function(DartType _type)>("NonNullAwareSpreadIsNull");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonNullAwareSpreadIsNull(DartType _type) {
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
templateNullableExpressionCallError = const Template<
  Message Function(DartType _type)
>(
  "NullableExpressionCallError",
  problemMessageTemplate:
      r"""Can't use an expression of type '#type' as a function because it's potentially null.""",
  correctionMessageTemplate: r"""Try calling using ?.call instead.""",
  withArguments: _withArgumentsNullableExpressionCallError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type)> codeNullableExpressionCallError =
    const Code<Message Function(DartType _type)>("NullableExpressionCallError");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNullableExpressionCallError(DartType _type) {
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
templateNullableMethodCallError = const Template<
  Message Function(String name, DartType _type)
>(
  "NullableMethodCallError",
  problemMessageTemplate:
      r"""Method '#name' cannot be called on '#type' because it is potentially null.""",
  correctionMessageTemplate: r"""Try calling using ?. instead.""",
  withArguments: _withArgumentsNullableMethodCallError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, DartType _type)>
codeNullableMethodCallError =
    const Code<Message Function(String name, DartType _type)>(
      "NullableMethodCallError",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNullableMethodCallError(String name, DartType _type) {
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
templateNullableOperatorCallError = const Template<
  Message Function(String name, DartType _type)
>(
  "NullableOperatorCallError",
  problemMessageTemplate:
      r"""Operator '#name' cannot be called on '#type' because it is potentially null.""",
  withArguments: _withArgumentsNullableOperatorCallError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, DartType _type)>
codeNullableOperatorCallError =
    const Code<Message Function(String name, DartType _type)>(
      "NullableOperatorCallError",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNullableOperatorCallError(String name, DartType _type) {
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
templateNullablePropertyAccessError = const Template<
  Message Function(String name, DartType _type)
>(
  "NullablePropertyAccessError",
  problemMessageTemplate:
      r"""Property '#name' cannot be accessed on '#type' because it is potentially null.""",
  correctionMessageTemplate: r"""Try accessing using ?. instead.""",
  withArguments: _withArgumentsNullablePropertyAccessError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, DartType _type)>
codeNullablePropertyAccessError =
    const Code<Message Function(String name, DartType _type)>(
      "NullablePropertyAccessError",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNullablePropertyAccessError(String name, DartType _type) {
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
templateOptionalNonNullableWithoutInitializerError = const Template<
  Message Function(String name, DartType _type)
>(
  "OptionalNonNullableWithoutInitializerError",
  problemMessageTemplate:
      r"""The parameter '#name' can't have a value of 'null' because of its type '#type', but the implicit default value is 'null'.""",
  correctionMessageTemplate:
      r"""Try adding either an explicit non-'null' default value or the 'required' modifier.""",
  withArguments: _withArgumentsOptionalNonNullableWithoutInitializerError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, DartType _type)>
codeOptionalNonNullableWithoutInitializerError =
    const Code<Message Function(String name, DartType _type)>(
      "OptionalNonNullableWithoutInitializerError",
      analyzerCodes: <String>["MISSING_DEFAULT_VALUE_FOR_PARAMETER"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOptionalNonNullableWithoutInitializerError(
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
templateOptionalSuperParameterWithoutInitializer = const Template<
  Message Function(DartType _type, String name)
>(
  "OptionalSuperParameterWithoutInitializer",
  problemMessageTemplate:
      r"""Type '#type' of the optional super-initializer parameter '#name' doesn't allow 'null', but the parameter doesn't have a default value, and the default value can't be copied from the corresponding parameter of the super constructor.""",
  withArguments: _withArgumentsOptionalSuperParameterWithoutInitializer,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, String name)>
codeOptionalSuperParameterWithoutInitializer =
    const Code<Message Function(DartType _type, String name)>(
      "OptionalSuperParameterWithoutInitializer",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOptionalSuperParameterWithoutInitializer(
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
templateOverrideTypeMismatchParameter = const Template<
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
  withArguments: _withArgumentsOverrideTypeMismatchParameter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
  Message Function(
    String name,
    String name2,
    DartType _type,
    DartType _type2,
    String name3,
  )
>
codeOverrideTypeMismatchParameter = const Code<
  Message Function(
    String name,
    String name2,
    DartType _type,
    DartType _type2,
    String name3,
  )
>(
  "OverrideTypeMismatchParameter",
  analyzerCodes: <String>["INVALID_METHOD_OVERRIDE"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideTypeMismatchParameter(
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
templateOverrideTypeMismatchReturnType = const Template<
  Message Function(String name, DartType _type, DartType _type2, String name2)
>(
  "OverrideTypeMismatchReturnType",
  problemMessageTemplate:
      r"""The return type of the method '#name' is '#type', which does not match the return type, '#type2', of the overridden method, '#name2'.""",
  correctionMessageTemplate: r"""Change to a subtype of '#type2'.""",
  withArguments: _withArgumentsOverrideTypeMismatchReturnType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
  Message Function(String name, DartType _type, DartType _type2, String name2)
>
codeOverrideTypeMismatchReturnType = const Code<
  Message Function(String name, DartType _type, DartType _type2, String name2)
>(
  "OverrideTypeMismatchReturnType",
  analyzerCodes: <String>["INVALID_METHOD_OVERRIDE"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideTypeMismatchReturnType(
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
templateOverrideTypeMismatchSetter = const Template<
  Message Function(String name, DartType _type, DartType _type2, String name2)
>(
  "OverrideTypeMismatchSetter",
  problemMessageTemplate:
      r"""The field '#name' has type '#type', which does not match the corresponding type, '#type2', in the overridden setter, '#name2'.""",
  withArguments: _withArgumentsOverrideTypeMismatchSetter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
  Message Function(String name, DartType _type, DartType _type2, String name2)
>
codeOverrideTypeMismatchSetter = const Code<
  Message Function(String name, DartType _type, DartType _type2, String name2)
>(
  "OverrideTypeMismatchSetter",
  analyzerCodes: <String>["INVALID_METHOD_OVERRIDE"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideTypeMismatchSetter(
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
templateOverrideTypeParametersBoundMismatch = const Template<
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
  withArguments: _withArgumentsOverrideTypeParametersBoundMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
  Message Function(
    DartType _type,
    String name,
    String name2,
    DartType _type2,
    String name3,
  )
>
codeOverrideTypeParametersBoundMismatch = const Code<
  Message Function(
    DartType _type,
    String name,
    String name2,
    DartType _type2,
    String name3,
  )
>("OverrideTypeParametersBoundMismatch");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideTypeParametersBoundMismatch(
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
templatePatternTypeMismatchInIrrefutableContext = const Template<
  Message Function(DartType _type, DartType _type2)
>(
  "PatternTypeMismatchInIrrefutableContext",
  problemMessageTemplate:
      r"""The matched value of type '#type' isn't assignable to the required type '#type2'.""",
  correctionMessageTemplate:
      r"""Try changing the required type of the pattern, or the matched value type.""",
  withArguments: _withArgumentsPatternTypeMismatchInIrrefutableContext,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
codePatternTypeMismatchInIrrefutableContext =
    const Code<Message Function(DartType _type, DartType _type2)>(
      "PatternTypeMismatchInIrrefutableContext",
      analyzerCodes: <String>["PATTERN_TYPE_MISMATCH_IN_IRREFUTABLE_CONTEXT"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsPatternTypeMismatchInIrrefutableContext(
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
templateRedirectingFactoryIncompatibleTypeArgument =
    const Template<Message Function(DartType _type, DartType _type2)>(
      "RedirectingFactoryIncompatibleTypeArgument",
      problemMessageTemplate: r"""The type '#type' doesn't extend '#type2'.""",
      correctionMessageTemplate: r"""Try using a different type as argument.""",
      withArguments: _withArgumentsRedirectingFactoryIncompatibleTypeArgument,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
codeRedirectingFactoryIncompatibleTypeArgument =
    const Code<Message Function(DartType _type, DartType _type2)>(
      "RedirectingFactoryIncompatibleTypeArgument",
      analyzerCodes: <String>["TYPE_ARGUMENT_NOT_MATCHING_BOUNDS"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsRedirectingFactoryIncompatibleTypeArgument(
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
templateSpreadElementTypeMismatch = const Template<
  Message Function(DartType _type, DartType _type2)
>(
  "SpreadElementTypeMismatch",
  problemMessageTemplate:
      r"""Can't assign spread elements of type '#type' to collection elements of type '#type2'.""",
  withArguments: _withArgumentsSpreadElementTypeMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
codeSpreadElementTypeMismatch =
    const Code<Message Function(DartType _type, DartType _type2)>(
      "SpreadElementTypeMismatch",
      analyzerCodes: <String>["LIST_ELEMENT_TYPE_NOT_ASSIGNABLE"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSpreadElementTypeMismatch(
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
templateSpreadElementTypeMismatchNullability = const Template<
  Message Function(DartType _type, DartType _type2)
>(
  "SpreadElementTypeMismatchNullability",
  problemMessageTemplate:
      r"""Can't assign spread elements of type '#type' to collection elements of type '#type2' because '#type' is nullable and '#type2' isn't.""",
  withArguments: _withArgumentsSpreadElementTypeMismatchNullability,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
codeSpreadElementTypeMismatchNullability =
    const Code<Message Function(DartType _type, DartType _type2)>(
      "SpreadElementTypeMismatchNullability",
      analyzerCodes: <String>["LIST_ELEMENT_TYPE_NOT_ASSIGNABLE"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSpreadElementTypeMismatchNullability(
  DartType _type,
  DartType _type2,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeSpreadElementTypeMismatchNullability,
    problemMessage:
        """Can't assign spread elements of type '${type}' to collection elements of type '${type2}' because '${type}' is nullable and '${type2}' isn't.""" +
        labeler.originMessages,
    arguments: {'type': _type, 'type2': _type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(
    DartType _type,
    DartType _type2,
    DartType _type3,
    DartType _type4,
  )
>
templateSpreadElementTypeMismatchPartNullability = const Template<
  Message Function(
    DartType _type,
    DartType _type2,
    DartType _type3,
    DartType _type4,
  )
>(
  "SpreadElementTypeMismatchPartNullability",
  problemMessageTemplate:
      r"""Can't assign spread elements of type '#type' to collection elements of type '#type2' because '#type3' is nullable and '#type4' isn't.""",
  withArguments: _withArgumentsSpreadElementTypeMismatchPartNullability,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
  Message Function(
    DartType _type,
    DartType _type2,
    DartType _type3,
    DartType _type4,
  )
>
codeSpreadElementTypeMismatchPartNullability = const Code<
  Message Function(
    DartType _type,
    DartType _type2,
    DartType _type3,
    DartType _type4,
  )
>(
  "SpreadElementTypeMismatchPartNullability",
  analyzerCodes: <String>["LIST_ELEMENT_TYPE_NOT_ASSIGNABLE"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSpreadElementTypeMismatchPartNullability(
  DartType _type,
  DartType _type2,
  DartType _type3,
  DartType _type4,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  List<Object> type3Parts = labeler.labelType(_type3);
  List<Object> type4Parts = labeler.labelType(_type4);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  String type3 = type3Parts.join();
  String type4 = type4Parts.join();
  return new Message(
    codeSpreadElementTypeMismatchPartNullability,
    problemMessage:
        """Can't assign spread elements of type '${type}' to collection elements of type '${type2}' because '${type3}' is nullable and '${type4}' isn't.""" +
        labeler.originMessages,
    arguments: {
      'type': _type,
      'type2': _type2,
      'type3': _type3,
      'type4': _type4,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, DartType _type2)>
templateSpreadMapEntryElementKeyTypeMismatch = const Template<
  Message Function(DartType _type, DartType _type2)
>(
  "SpreadMapEntryElementKeyTypeMismatch",
  problemMessageTemplate:
      r"""Can't assign spread entry keys of type '#type' to map entry keys of type '#type2'.""",
  withArguments: _withArgumentsSpreadMapEntryElementKeyTypeMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
codeSpreadMapEntryElementKeyTypeMismatch =
    const Code<Message Function(DartType _type, DartType _type2)>(
      "SpreadMapEntryElementKeyTypeMismatch",
      analyzerCodes: <String>["MAP_KEY_TYPE_NOT_ASSIGNABLE"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSpreadMapEntryElementKeyTypeMismatch(
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
templateSpreadMapEntryElementKeyTypeMismatchNullability = const Template<
  Message Function(DartType _type, DartType _type2)
>(
  "SpreadMapEntryElementKeyTypeMismatchNullability",
  problemMessageTemplate:
      r"""Can't assign spread entry keys of type '#type' to map entry keys of type '#type2' because '#type' is nullable and '#type2' isn't.""",
  withArguments: _withArgumentsSpreadMapEntryElementKeyTypeMismatchNullability,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
codeSpreadMapEntryElementKeyTypeMismatchNullability =
    const Code<Message Function(DartType _type, DartType _type2)>(
      "SpreadMapEntryElementKeyTypeMismatchNullability",
      analyzerCodes: <String>["MAP_KEY_TYPE_NOT_ASSIGNABLE"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSpreadMapEntryElementKeyTypeMismatchNullability(
  DartType _type,
  DartType _type2,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeSpreadMapEntryElementKeyTypeMismatchNullability,
    problemMessage:
        """Can't assign spread entry keys of type '${type}' to map entry keys of type '${type2}' because '${type}' is nullable and '${type2}' isn't.""" +
        labeler.originMessages,
    arguments: {'type': _type, 'type2': _type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(
    DartType _type,
    DartType _type2,
    DartType _type3,
    DartType _type4,
  )
>
templateSpreadMapEntryElementKeyTypeMismatchPartNullability = const Template<
  Message Function(
    DartType _type,
    DartType _type2,
    DartType _type3,
    DartType _type4,
  )
>(
  "SpreadMapEntryElementKeyTypeMismatchPartNullability",
  problemMessageTemplate:
      r"""Can't assign spread entry keys of type '#type' to map entry keys of type '#type2' because '#type3' is nullable and '#type4' isn't.""",
  withArguments:
      _withArgumentsSpreadMapEntryElementKeyTypeMismatchPartNullability,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
  Message Function(
    DartType _type,
    DartType _type2,
    DartType _type3,
    DartType _type4,
  )
>
codeSpreadMapEntryElementKeyTypeMismatchPartNullability = const Code<
  Message Function(
    DartType _type,
    DartType _type2,
    DartType _type3,
    DartType _type4,
  )
>(
  "SpreadMapEntryElementKeyTypeMismatchPartNullability",
  analyzerCodes: <String>["MAP_KEY_TYPE_NOT_ASSIGNABLE"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSpreadMapEntryElementKeyTypeMismatchPartNullability(
  DartType _type,
  DartType _type2,
  DartType _type3,
  DartType _type4,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  List<Object> type3Parts = labeler.labelType(_type3);
  List<Object> type4Parts = labeler.labelType(_type4);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  String type3 = type3Parts.join();
  String type4 = type4Parts.join();
  return new Message(
    codeSpreadMapEntryElementKeyTypeMismatchPartNullability,
    problemMessage:
        """Can't assign spread entry keys of type '${type}' to map entry keys of type '${type2}' because '${type3}' is nullable and '${type4}' isn't.""" +
        labeler.originMessages,
    arguments: {
      'type': _type,
      'type2': _type2,
      'type3': _type3,
      'type4': _type4,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, DartType _type2)>
templateSpreadMapEntryElementValueTypeMismatch = const Template<
  Message Function(DartType _type, DartType _type2)
>(
  "SpreadMapEntryElementValueTypeMismatch",
  problemMessageTemplate:
      r"""Can't assign spread entry values of type '#type' to map entry values of type '#type2'.""",
  withArguments: _withArgumentsSpreadMapEntryElementValueTypeMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
codeSpreadMapEntryElementValueTypeMismatch =
    const Code<Message Function(DartType _type, DartType _type2)>(
      "SpreadMapEntryElementValueTypeMismatch",
      analyzerCodes: <String>["MAP_VALUE_TYPE_NOT_ASSIGNABLE"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSpreadMapEntryElementValueTypeMismatch(
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
const Template<Message Function(DartType _type, DartType _type2)>
templateSpreadMapEntryElementValueTypeMismatchNullability = const Template<
  Message Function(DartType _type, DartType _type2)
>(
  "SpreadMapEntryElementValueTypeMismatchNullability",
  problemMessageTemplate:
      r"""Can't assign spread entry values of type '#type' to map entry values of type '#type2' because '#type' is nullable and '#type2' isn't.""",
  withArguments:
      _withArgumentsSpreadMapEntryElementValueTypeMismatchNullability,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
codeSpreadMapEntryElementValueTypeMismatchNullability =
    const Code<Message Function(DartType _type, DartType _type2)>(
      "SpreadMapEntryElementValueTypeMismatchNullability",
      analyzerCodes: <String>["MAP_VALUE_TYPE_NOT_ASSIGNABLE"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSpreadMapEntryElementValueTypeMismatchNullability(
  DartType _type,
  DartType _type2,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeSpreadMapEntryElementValueTypeMismatchNullability,
    problemMessage:
        """Can't assign spread entry values of type '${type}' to map entry values of type '${type2}' because '${type}' is nullable and '${type2}' isn't.""" +
        labeler.originMessages,
    arguments: {'type': _type, 'type2': _type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(
    DartType _type,
    DartType _type2,
    DartType _type3,
    DartType _type4,
  )
>
templateSpreadMapEntryElementValueTypeMismatchPartNullability = const Template<
  Message Function(
    DartType _type,
    DartType _type2,
    DartType _type3,
    DartType _type4,
  )
>(
  "SpreadMapEntryElementValueTypeMismatchPartNullability",
  problemMessageTemplate:
      r"""Can't assign spread entry values of type '#type' to map entry values of type '#type2' because '#type3' is nullable and '#type4' isn't.""",
  withArguments:
      _withArgumentsSpreadMapEntryElementValueTypeMismatchPartNullability,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
  Message Function(
    DartType _type,
    DartType _type2,
    DartType _type3,
    DartType _type4,
  )
>
codeSpreadMapEntryElementValueTypeMismatchPartNullability = const Code<
  Message Function(
    DartType _type,
    DartType _type2,
    DartType _type3,
    DartType _type4,
  )
>(
  "SpreadMapEntryElementValueTypeMismatchPartNullability",
  analyzerCodes: <String>["MAP_VALUE_TYPE_NOT_ASSIGNABLE"],
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSpreadMapEntryElementValueTypeMismatchPartNullability(
  DartType _type,
  DartType _type2,
  DartType _type3,
  DartType _type4,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  List<Object> type3Parts = labeler.labelType(_type3);
  List<Object> type4Parts = labeler.labelType(_type4);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  String type3 = type3Parts.join();
  String type4 = type4Parts.join();
  return new Message(
    codeSpreadMapEntryElementValueTypeMismatchPartNullability,
    problemMessage:
        """Can't assign spread entry values of type '${type}' to map entry values of type '${type2}' because '${type3}' is nullable and '${type4}' isn't.""" +
        labeler.originMessages,
    arguments: {
      'type': _type,
      'type2': _type2,
      'type3': _type3,
      'type4': _type4,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type)>
templateSpreadMapEntryTypeMismatch = const Template<
  Message Function(DartType _type)
>(
  "SpreadMapEntryTypeMismatch",
  problemMessageTemplate:
      r"""Unexpected type '#type' of a map spread entry.  Expected 'dynamic' or a Map.""",
  withArguments: _withArgumentsSpreadMapEntryTypeMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type)> codeSpreadMapEntryTypeMismatch =
    const Code<Message Function(DartType _type)>("SpreadMapEntryTypeMismatch");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSpreadMapEntryTypeMismatch(DartType _type) {
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
templateSpreadTypeMismatch = const Template<Message Function(DartType _type)>(
  "SpreadTypeMismatch",
  problemMessageTemplate:
      r"""Unexpected type '#type' of a spread.  Expected 'dynamic' or an Iterable.""",
  withArguments: _withArgumentsSpreadTypeMismatch,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type)> codeSpreadTypeMismatch =
    const Code<Message Function(DartType _type)>("SpreadTypeMismatch");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSpreadTypeMismatch(DartType _type) {
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
templateSuperBoundedHint = const Template<
  Message Function(DartType _type, DartType _type2)
>(
  "SuperBoundedHint",
  problemMessageTemplate:
      r"""If you want '#type' to be a super-bounded type, note that the inverted type '#type2' must then satisfy its bounds, which it does not.""",
  withArguments: _withArgumentsSuperBoundedHint,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
codeSuperBoundedHint =
    const Code<Message Function(DartType _type, DartType _type2)>(
      "SuperBoundedHint",
      severity: Severity.context,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperBoundedHint(DartType _type, DartType _type2) {
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
templateSuperExtensionTypeIsIllegalAliased = const Template<
  Message Function(String name, DartType _type)
>(
  "SuperExtensionTypeIsIllegalAliased",
  problemMessageTemplate:
      r"""The type '#name' which is an alias of '#type' can't be implemented by an extension type.""",
  withArguments: _withArgumentsSuperExtensionTypeIsIllegalAliased,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, DartType _type)>
codeSuperExtensionTypeIsIllegalAliased =
    const Code<Message Function(String name, DartType _type)>(
      "SuperExtensionTypeIsIllegalAliased",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperExtensionTypeIsIllegalAliased(
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
templateSuperExtensionTypeIsNullableAliased = const Template<
  Message Function(String name, DartType _type)
>(
  "SuperExtensionTypeIsNullableAliased",
  problemMessageTemplate:
      r"""The type '#name' which is an alias of '#type' can't be implemented by an extension type because it is nullable.""",
  withArguments: _withArgumentsSuperExtensionTypeIsNullableAliased,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, DartType _type)>
codeSuperExtensionTypeIsNullableAliased =
    const Code<Message Function(String name, DartType _type)>(
      "SuperExtensionTypeIsNullableAliased",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperExtensionTypeIsNullableAliased(
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
templateSupertypeIsIllegalAliased = const Template<
  Message Function(String name, DartType _type)
>(
  "SupertypeIsIllegalAliased",
  problemMessageTemplate:
      r"""The type '#name' which is an alias of '#type' can't be used as supertype.""",
  withArguments: _withArgumentsSupertypeIsIllegalAliased,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, DartType _type)>
codeSupertypeIsIllegalAliased =
    const Code<Message Function(String name, DartType _type)>(
      "SupertypeIsIllegalAliased",
      analyzerCodes: <String>["EXTENDS_NON_CLASS"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSupertypeIsIllegalAliased(String name, DartType _type) {
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
templateSupertypeIsNullableAliased = const Template<
  Message Function(String name, DartType _type)
>(
  "SupertypeIsNullableAliased",
  problemMessageTemplate:
      r"""The type '#name' which is an alias of '#type' can't be used as supertype because it is nullable.""",
  withArguments: _withArgumentsSupertypeIsNullableAliased,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, DartType _type)>
codeSupertypeIsNullableAliased =
    const Code<Message Function(String name, DartType _type)>(
      "SupertypeIsNullableAliased",
      analyzerCodes: <String>["EXTENDS_NON_CLASS"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSupertypeIsNullableAliased(String name, DartType _type) {
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
templateSwitchExpressionNotAssignable = const Template<
  Message Function(DartType _type, DartType _type2)
>(
  "SwitchExpressionNotAssignable",
  problemMessageTemplate:
      r"""Type '#type' of the switch expression isn't assignable to the type '#type2' of this case expression.""",
  withArguments: _withArgumentsSwitchExpressionNotAssignable,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
codeSwitchExpressionNotAssignable =
    const Code<Message Function(DartType _type, DartType _type2)>(
      "SwitchExpressionNotAssignable",
      analyzerCodes: <String>["SWITCH_EXPRESSION_NOT_ASSIGNABLE"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSwitchExpressionNotAssignable(
  DartType _type,
  DartType _type2,
) {
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  List<Object> type2Parts = labeler.labelType(_type2);
  String type = typeParts.join();
  String type2 = type2Parts.join();
  return new Message(
    codeSwitchExpressionNotAssignable,
    problemMessage:
        """Type '${type}' of the switch expression isn't assignable to the type '${type2}' of this case expression.""" +
        labeler.originMessages,
    arguments: {'type': _type, 'type2': _type2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(DartType _type, DartType _type2)>
templateSwitchExpressionNotSubtype = const Template<
  Message Function(DartType _type, DartType _type2)
>(
  "SwitchExpressionNotSubtype",
  problemMessageTemplate:
      r"""Type '#type' of the case expression is not a subtype of type '#type2' of this switch expression.""",
  withArguments: _withArgumentsSwitchExpressionNotSubtype,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type, DartType _type2)>
codeSwitchExpressionNotSubtype =
    const Code<Message Function(DartType _type, DartType _type2)>(
      "SwitchExpressionNotSubtype",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSwitchExpressionNotSubtype(
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
templateThrowingNotAssignableToObjectError = const Template<
  Message Function(DartType _type)
>(
  "ThrowingNotAssignableToObjectError",
  problemMessageTemplate:
      r"""Can't throw a value of '#type' since it is neither dynamic nor non-nullable.""",
  withArguments: _withArgumentsThrowingNotAssignableToObjectError,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(DartType _type)>
codeThrowingNotAssignableToObjectError =
    const Code<Message Function(DartType _type)>(
      "ThrowingNotAssignableToObjectError",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsThrowingNotAssignableToObjectError(DartType _type) {
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
templateUndefinedExtensionGetter = const Template<
  Message Function(String name, DartType _type)
>(
  "UndefinedExtensionGetter",
  problemMessageTemplate:
      r"""The getter '#name' isn't defined for the extension '#type'.""",
  correctionMessageTemplate:
      r"""Try correcting the name to the name of an existing getter, or defining a getter or field named '#name'.""",
  withArguments: _withArgumentsUndefinedExtensionGetter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, DartType _type)>
codeUndefinedExtensionGetter =
    const Code<Message Function(String name, DartType _type)>(
      "UndefinedExtensionGetter",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUndefinedExtensionGetter(String name, DartType _type) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeUndefinedExtensionGetter,
    problemMessage:
        """The getter '${name}' isn't defined for the extension '${type}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try correcting the name to the name of an existing getter, or defining a getter or field named '${name}'.""",
    arguments: {'name': name, 'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, DartType _type)>
templateUndefinedExtensionMethod = const Template<
  Message Function(String name, DartType _type)
>(
  "UndefinedExtensionMethod",
  problemMessageTemplate:
      r"""The method '#name' isn't defined for the extension '#type'.""",
  correctionMessageTemplate:
      r"""Try correcting the name to the name of an existing method, or defining a method name '#name'.""",
  withArguments: _withArgumentsUndefinedExtensionMethod,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, DartType _type)>
codeUndefinedExtensionMethod =
    const Code<Message Function(String name, DartType _type)>(
      "UndefinedExtensionMethod",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUndefinedExtensionMethod(String name, DartType _type) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeUndefinedExtensionMethod,
    problemMessage:
        """The method '${name}' isn't defined for the extension '${type}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try correcting the name to the name of an existing method, or defining a method name '${name}'.""",
    arguments: {'name': name, 'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, DartType _type)>
templateUndefinedExtensionOperator = const Template<
  Message Function(String name, DartType _type)
>(
  "UndefinedExtensionOperator",
  problemMessageTemplate:
      r"""The operator '#name' isn't defined for the extension '#type'.""",
  correctionMessageTemplate:
      r"""Try correcting the operator to an existing operator, or defining a '#name' operator.""",
  withArguments: _withArgumentsUndefinedExtensionOperator,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, DartType _type)>
codeUndefinedExtensionOperator =
    const Code<Message Function(String name, DartType _type)>(
      "UndefinedExtensionOperator",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUndefinedExtensionOperator(String name, DartType _type) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeUndefinedExtensionOperator,
    problemMessage:
        """The operator '${name}' isn't defined for the extension '${type}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try correcting the operator to an existing operator, or defining a '${name}' operator.""",
    arguments: {'name': name, 'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, DartType _type)>
templateUndefinedExtensionSetter = const Template<
  Message Function(String name, DartType _type)
>(
  "UndefinedExtensionSetter",
  problemMessageTemplate:
      r"""The setter '#name' isn't defined for the extension '#type'.""",
  correctionMessageTemplate:
      r"""Try correcting the name to the name of an existing setter, or defining a setter or field named '#name'.""",
  withArguments: _withArgumentsUndefinedExtensionSetter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, DartType _type)>
codeUndefinedExtensionSetter =
    const Code<Message Function(String name, DartType _type)>(
      "UndefinedExtensionSetter",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUndefinedExtensionSetter(String name, DartType _type) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeUndefinedExtensionSetter,
    problemMessage:
        """The setter '${name}' isn't defined for the extension '${type}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try correcting the name to the name of an existing setter, or defining a setter or field named '${name}'.""",
    arguments: {'name': name, 'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, DartType _type)>
templateUndefinedGetter = const Template<
  Message Function(String name, DartType _type)
>(
  "UndefinedGetter",
  problemMessageTemplate:
      r"""The getter '#name' isn't defined for the class '#type'.""",
  correctionMessageTemplate:
      r"""Try correcting the name to the name of an existing getter, or defining a getter or field named '#name'.""",
  withArguments: _withArgumentsUndefinedGetter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, DartType _type)> codeUndefinedGetter =
    const Code<Message Function(String name, DartType _type)>(
      "UndefinedGetter",
      analyzerCodes: <String>["UNDEFINED_GETTER"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUndefinedGetter(String name, DartType _type) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeUndefinedGetter,
    problemMessage:
        """The getter '${name}' isn't defined for the class '${type}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try correcting the name to the name of an existing getter, or defining a getter or field named '${name}'.""",
    arguments: {'name': name, 'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, DartType _type)>
templateUndefinedMethod = const Template<
  Message Function(String name, DartType _type)
>(
  "UndefinedMethod",
  problemMessageTemplate:
      r"""The method '#name' isn't defined for the class '#type'.""",
  correctionMessageTemplate:
      r"""Try correcting the name to the name of an existing method, or defining a method named '#name'.""",
  withArguments: _withArgumentsUndefinedMethod,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, DartType _type)> codeUndefinedMethod =
    const Code<Message Function(String name, DartType _type)>(
      "UndefinedMethod",
      analyzerCodes: <String>["UNDEFINED_METHOD"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUndefinedMethod(String name, DartType _type) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeUndefinedMethod,
    problemMessage:
        """The method '${name}' isn't defined for the class '${type}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try correcting the name to the name of an existing method, or defining a method named '${name}'.""",
    arguments: {'name': name, 'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, DartType _type)>
templateUndefinedOperator = const Template<
  Message Function(String name, DartType _type)
>(
  "UndefinedOperator",
  problemMessageTemplate:
      r"""The operator '#name' isn't defined for the class '#type'.""",
  correctionMessageTemplate:
      r"""Try correcting the operator to an existing operator, or defining a '#name' operator.""",
  withArguments: _withArgumentsUndefinedOperator,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, DartType _type)>
codeUndefinedOperator =
    const Code<Message Function(String name, DartType _type)>(
      "UndefinedOperator",
      analyzerCodes: <String>["UNDEFINED_METHOD"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUndefinedOperator(String name, DartType _type) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeUndefinedOperator,
    problemMessage:
        """The operator '${name}' isn't defined for the class '${type}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try correcting the operator to an existing operator, or defining a '${name}' operator.""",
    arguments: {'name': name, 'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, DartType _type)>
templateUndefinedSetter = const Template<
  Message Function(String name, DartType _type)
>(
  "UndefinedSetter",
  problemMessageTemplate:
      r"""The setter '#name' isn't defined for the class '#type'.""",
  correctionMessageTemplate:
      r"""Try correcting the name to the name of an existing setter, or defining a setter or field named '#name'.""",
  withArguments: _withArgumentsUndefinedSetter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, DartType _type)> codeUndefinedSetter =
    const Code<Message Function(String name, DartType _type)>(
      "UndefinedSetter",
      analyzerCodes: <String>["UNDEFINED_SETTER"],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUndefinedSetter(String name, DartType _type) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  TypeLabeler labeler = new TypeLabeler();
  List<Object> typeParts = labeler.labelType(_type);
  String type = typeParts.join();
  return new Message(
    codeUndefinedSetter,
    problemMessage:
        """The setter '${name}' isn't defined for the class '${type}'.""" +
        labeler.originMessages,
    correctionMessage:
        """Try correcting the name to the name of an existing setter, or defining a setter or field named '${name}'.""",
    arguments: {'name': name, 'type': _type},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, DartType _type)>
templateWrongTypeParameterVarianceInSuperinterface = const Template<
  Message Function(String name, DartType _type)
>(
  "WrongTypeParameterVarianceInSuperinterface",
  problemMessageTemplate:
      r"""'#name' can't be used contravariantly or invariantly in '#type'.""",
  withArguments: _withArgumentsWrongTypeParameterVarianceInSuperinterface,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, DartType _type)>
codeWrongTypeParameterVarianceInSuperinterface =
    const Code<Message Function(String name, DartType _type)>(
      "WrongTypeParameterVarianceInSuperinterface",
      analyzerCodes: <String>[
        "WRONG_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE",
      ],
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsWrongTypeParameterVarianceInSuperinterface(
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
