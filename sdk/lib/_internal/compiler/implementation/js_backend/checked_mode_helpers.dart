// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of js_backend;

class CheckedModeHelper {
  final String name;

  const CheckedModeHelper(String this.name);

  Element getElement(Compiler compiler) => compiler.findHelper(name);

  jsAst.Expression generateCall(SsaCodeGenerator codegen,
                                HTypeConversion node) {
    Element helperElement = getElement(codegen.compiler);
    codegen.world.registerStaticUse(helperElement);
    List<jsAst.Expression> arguments = <jsAst.Expression>[];
    codegen.use(node.checkedInput);
    arguments.add(codegen.pop());
    generateAdditionalArguments(codegen, node, arguments);
    jsAst.Expression helper = codegen.backend.namer.elementAccess(helperElement);
    return new jsAst.Call(helper, arguments);
  }

  void generateAdditionalArguments(SsaCodeGenerator codegen,
                                   HTypeConversion node,
                                   List<jsAst.Expression> arguments) {
    // No additional arguments needed.
  }

  static const List<CheckedModeHelper> helpers = const <CheckedModeHelper> [
      const MalformedCheckedModeHelper('checkMalformedType'),
      const CheckedModeHelper('voidTypeCheck'),
      const CheckedModeHelper('stringTypeCast'),
      const CheckedModeHelper('stringTypeCheck'),
      const CheckedModeHelper('doubleTypeCast'),
      const CheckedModeHelper('doubleTypeCheck'),
      const CheckedModeHelper('numTypeCast'),
      const CheckedModeHelper('numTypeCheck'),
      const CheckedModeHelper('boolTypeCast'),
      const CheckedModeHelper('boolTypeCheck'),
      const CheckedModeHelper('intTypeCast'),
      const CheckedModeHelper('intTypeCheck'),
      const PropertyCheckedModeHelper('numberOrStringSuperNativeTypeCast'),
      const PropertyCheckedModeHelper('numberOrStringSuperNativeTypeCheck'),
      const PropertyCheckedModeHelper('numberOrStringSuperTypeCast'),
      const PropertyCheckedModeHelper('numberOrStringSuperTypeCheck'),
      const PropertyCheckedModeHelper('stringSuperNativeTypeCast'),
      const PropertyCheckedModeHelper('stringSuperNativeTypeCheck'),
      const PropertyCheckedModeHelper('stringSuperTypeCast'),
      const PropertyCheckedModeHelper('stringSuperTypeCheck'),
      const CheckedModeHelper('listTypeCast'),
      const CheckedModeHelper('listTypeCheck'),
      const PropertyCheckedModeHelper('listSuperNativeTypeCast'),
      const PropertyCheckedModeHelper('listSuperNativeTypeCheck'),
      const PropertyCheckedModeHelper('listSuperTypeCast'),
      const PropertyCheckedModeHelper('listSuperTypeCheck'),
      const PropertyCheckedModeHelper('interceptedTypeCast'),
      const PropertyCheckedModeHelper('interceptedTypeCheck'),
      const SubtypeCheckedModeHelper('subtypeCast'),
      const SubtypeCheckedModeHelper('assertSubtype'),
      const TypeVariableCheckedModeHelper('subtypeOfRuntimeTypeCast'),
      const TypeVariableCheckedModeHelper('assertSubtypeOfRuntimeType'),
      const PropertyCheckedModeHelper('propertyTypeCast'),
      const PropertyCheckedModeHelper('propertyTypeCheck')];
}

class MalformedCheckedModeHelper extends CheckedModeHelper {
  const MalformedCheckedModeHelper(String name) : super(name);

  void generateAdditionalArguments(SsaCodeGenerator codegen,
                                   HTypeConversion node,
                                   List<jsAst.Expression> arguments) {
    ErroneousElement element = node.typeExpression.element;
    arguments.add(js.escapedString(element.message));
  }
}

class PropertyCheckedModeHelper extends CheckedModeHelper {
  const PropertyCheckedModeHelper(String name) : super(name);

  void generateAdditionalArguments(SsaCodeGenerator codegen,
                                   HTypeConversion node,
                                   List<jsAst.Expression> arguments) {
    DartType type = node.typeExpression;
    String additionalArgument = codegen.backend.namer.operatorIsType(type);
    arguments.add(js.string(additionalArgument));
  }
}

class TypeVariableCheckedModeHelper extends CheckedModeHelper {
  const TypeVariableCheckedModeHelper(String name) : super(name);

  void generateAdditionalArguments(SsaCodeGenerator codegen,
                                   HTypeConversion node,
                                   List<jsAst.Expression> arguments) {
    assert(node.typeExpression.kind == TypeKind.TYPE_VARIABLE);
    codegen.use(node.typeRepresentation);
    arguments.add(codegen.pop());
  }
}

class SubtypeCheckedModeHelper extends CheckedModeHelper {
  const SubtypeCheckedModeHelper(String name) : super(name);

  void generateAdditionalArguments(SsaCodeGenerator codegen,
                                   HTypeConversion node,
                                   List<jsAst.Expression> arguments) {
    DartType type = node.typeExpression;
    Element element = type.element;
    String isField = codegen.backend.namer.operatorIs(element);
    arguments.add(js.string(isField));
    codegen.use(node.typeRepresentation);
    arguments.add(codegen.pop());
    String asField = codegen.backend.namer.substitutionName(element);
    arguments.add(js.string(asField));
  }
}
