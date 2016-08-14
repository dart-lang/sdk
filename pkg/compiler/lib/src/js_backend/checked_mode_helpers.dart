// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../compiler.dart' show Compiler;
import '../dart_types.dart';
import '../elements/elements.dart';
import '../js/js.dart' as jsAst;
import '../js/js.dart' show js;
import '../ssa/codegen.dart' show SsaCodeGenerator;
import '../ssa/nodes.dart' show HTypeConversion;
import '../universe/call_structure.dart' show CallStructure;
import '../universe/use.dart' show StaticUse;
import 'backend.dart';

class CheckedModeHelper {
  final String name;

  const CheckedModeHelper(String this.name);

  StaticUse getStaticUse(Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    return new StaticUse.staticInvoke(
        backend.helpers.findHelper(name), callStructure);
  }

  CallStructure get callStructure => CallStructure.ONE_ARG;

  jsAst.Expression generateCall(
      SsaCodeGenerator codegen, HTypeConversion node) {
    StaticUse staticUse = getStaticUse(codegen.compiler);
    codegen.registry.registerStaticUse(staticUse);
    List<jsAst.Expression> arguments = <jsAst.Expression>[];
    codegen.use(node.checkedInput);
    arguments.add(codegen.pop());
    generateAdditionalArguments(codegen, node, arguments);
    jsAst.Expression helper =
        codegen.backend.emitter.staticFunctionAccess(staticUse.element);
    return new jsAst.Call(helper, arguments);
  }

  void generateAdditionalArguments(SsaCodeGenerator codegen,
      HTypeConversion node, List<jsAst.Expression> arguments) {
    // No additional arguments needed.
  }

  static const List<CheckedModeHelper> helpers = const <CheckedModeHelper>[
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
    const PropertyCheckedModeHelper('propertyTypeCheck')
  ];
}

class MalformedCheckedModeHelper extends CheckedModeHelper {
  const MalformedCheckedModeHelper(String name) : super(name);

  CallStructure get callStructure => CallStructure.TWO_ARGS;

  void generateAdditionalArguments(SsaCodeGenerator codegen,
      HTypeConversion node, List<jsAst.Expression> arguments) {
    ErroneousElement element = node.typeExpression.element;
    arguments.add(js.escapedString(element.message));
  }
}

class PropertyCheckedModeHelper extends CheckedModeHelper {
  const PropertyCheckedModeHelper(String name) : super(name);

  CallStructure get callStructure => CallStructure.TWO_ARGS;

  void generateAdditionalArguments(SsaCodeGenerator codegen,
      HTypeConversion node, List<jsAst.Expression> arguments) {
    DartType type = node.typeExpression;
    jsAst.Name additionalArgument = codegen.backend.namer.operatorIsType(type);
    arguments.add(js.quoteName(additionalArgument));
  }
}

class TypeVariableCheckedModeHelper extends CheckedModeHelper {
  const TypeVariableCheckedModeHelper(String name) : super(name);

  CallStructure get callStructure => CallStructure.TWO_ARGS;

  void generateAdditionalArguments(SsaCodeGenerator codegen,
      HTypeConversion node, List<jsAst.Expression> arguments) {
    assert(node.typeExpression.isTypeVariable);
    codegen.use(node.typeRepresentation);
    arguments.add(codegen.pop());
  }
}

class SubtypeCheckedModeHelper extends CheckedModeHelper {
  const SubtypeCheckedModeHelper(String name) : super(name);

  CallStructure get callStructure => const CallStructure.unnamed(4);

  void generateAdditionalArguments(SsaCodeGenerator codegen,
      HTypeConversion node, List<jsAst.Expression> arguments) {
    DartType type = node.typeExpression;
    Element element = type.element;
    jsAst.Name isField = codegen.backend.namer.operatorIs(element);
    arguments.add(js.quoteName(isField));
    codegen.use(node.typeRepresentation);
    arguments.add(codegen.pop());
    jsAst.Name asField = codegen.backend.namer.substitutionName(element);
    arguments.add(js.quoteName(asField));
  }
}
