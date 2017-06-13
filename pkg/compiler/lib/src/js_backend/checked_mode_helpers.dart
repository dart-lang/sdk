// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common.dart';
import '../common_elements.dart';
import '../elements/elements.dart' show ErroneousElement;
import '../elements/entities.dart';
import '../elements/resolution_types.dart' show MalformedType;
import '../elements/types.dart';
import '../js/js.dart' as jsAst;
import '../js/js.dart' show js;
import '../ssa/codegen.dart' show SsaCodeGenerator;
import '../ssa/nodes.dart' show HTypeConversion;
import '../universe/call_structure.dart' show CallStructure;
import '../universe/use.dart' show StaticUse;
import 'namer.dart' show Namer;

class CheckedModeHelper {
  final String name;

  const CheckedModeHelper(String this.name);

  StaticUse getStaticUse(CommonElements commonElements) {
    // TODO(johnniwinther): Refactor this to avoid looking up directly in the
    // js helper library but instead access commonElements.
    return new StaticUse.staticInvoke(
        commonElements.findHelperFunction(name), callStructure);
  }

  CallStructure get callStructure => CallStructure.ONE_ARG;

  void generateAdditionalArguments(SsaCodeGenerator codegen, Namer namer,
      HTypeConversion node, List<jsAst.Expression> arguments) {
    // No additional arguments needed.
  }
}

class MalformedCheckedModeHelper extends CheckedModeHelper {
  const MalformedCheckedModeHelper(String name) : super(name);

  CallStructure get callStructure => CallStructure.TWO_ARGS;

  void generateAdditionalArguments(SsaCodeGenerator codegen, Namer namer,
      HTypeConversion node, List<jsAst.Expression> arguments) {
    // TODO(johnniwinther): Support malformed types in [types.dart].
    MalformedType type = node.typeExpression;
    ErroneousElement element = type.element;
    arguments.add(js.escapedString(element.message));
  }
}

class PropertyCheckedModeHelper extends CheckedModeHelper {
  const PropertyCheckedModeHelper(String name) : super(name);

  CallStructure get callStructure => CallStructure.TWO_ARGS;

  void generateAdditionalArguments(SsaCodeGenerator codegen, Namer namer,
      HTypeConversion node, List<jsAst.Expression> arguments) {
    DartType type = node.typeExpression;
    jsAst.Name additionalArgument = namer.operatorIsType(type);
    arguments.add(js.quoteName(additionalArgument));
  }
}

class TypeVariableCheckedModeHelper extends CheckedModeHelper {
  const TypeVariableCheckedModeHelper(String name) : super(name);

  CallStructure get callStructure => CallStructure.TWO_ARGS;

  void generateAdditionalArguments(SsaCodeGenerator codegen, Namer namer,
      HTypeConversion node, List<jsAst.Expression> arguments) {
    assert(node.typeExpression.isTypeVariable);
    codegen.use(node.typeRepresentation);
    arguments.add(codegen.pop());
  }
}

class FunctionTypeRepresentationCheckedModeHelper extends CheckedModeHelper {
  const FunctionTypeRepresentationCheckedModeHelper(String name) : super(name);

  CallStructure get callStructure => CallStructure.TWO_ARGS;

  void generateAdditionalArguments(SsaCodeGenerator codegen, Namer namer,
      HTypeConversion node, List<jsAst.Expression> arguments) {
    assert(node.typeExpression.isFunctionType);
    codegen.use(node.typeRepresentation);
    arguments.add(codegen.pop());
  }
}

class SubtypeCheckedModeHelper extends CheckedModeHelper {
  const SubtypeCheckedModeHelper(String name) : super(name);

  CallStructure get callStructure => const CallStructure.unnamed(4);

  void generateAdditionalArguments(SsaCodeGenerator codegen, Namer namer,
      HTypeConversion node, List<jsAst.Expression> arguments) {
    // TODO(sra): Move these calls into the SSA graph so that the arguments can
    // be optimized, e,g, GVNed.
    InterfaceType type = node.typeExpression;
    ClassEntity element = type.element;
    jsAst.Name isField = namer.operatorIs(element);
    arguments.add(js.quoteName(isField));
    codegen.use(node.typeRepresentation);
    arguments.add(codegen.pop());
    jsAst.Name asField = namer.substitutionName(element);
    arguments.add(js.quoteName(asField));
  }
}

class CheckedModeHelpers {
  final CommonElements _commonElements;

  CheckedModeHelpers(this._commonElements);

  /// All the checked mode helpers.
  static const List<CheckedModeHelper> helpers = const <CheckedModeHelper>[
    const MalformedCheckedModeHelper('checkMalformedType'),
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
    const PropertyCheckedModeHelper('propertyTypeCheck'),
    const FunctionTypeRepresentationCheckedModeHelper('functionTypeCast'),
    const FunctionTypeRepresentationCheckedModeHelper('functionTypeCheck'),
  ];

  // Checked mode helpers indexed by name.
  static final Map<String, CheckedModeHelper> checkedModeHelperByName =
      new Map<String, CheckedModeHelper>.fromIterable(helpers,
          key: (helper) => helper.name);

  /**
   * Returns the checked mode helper that will be needed to do a type check/type
   * cast on [type] at runtime. Note that this method is being called both by
   * the resolver with interface types (int, String, ...), and by the SSA
   * backend with implementation types (JSInt, JSString, ...).
   */
  CheckedModeHelper getCheckedModeHelper(DartType type, {bool typeCast}) {
    return getCheckedModeHelperInternal(type,
        typeCast: typeCast, nativeCheckOnly: false);
  }

  /**
   * Returns the native checked mode helper that will be needed to do a type
   * check/type cast on [type] at runtime. If no native helper exists for
   * [type], [:null:] is returned.
   */
  CheckedModeHelper getNativeCheckedModeHelper(DartType type, {bool typeCast}) {
    return getCheckedModeHelperInternal(type,
        typeCast: typeCast, nativeCheckOnly: true);
  }

  /**
   * Returns the checked mode helper for the type check/type cast for [type]. If
   * [nativeCheckOnly] is [:true:], only names for native helpers are returned.
   */
  CheckedModeHelper getCheckedModeHelperInternal(DartType type,
      {bool typeCast, bool nativeCheckOnly}) {
    String name = getCheckedModeHelperNameInternal(type,
        typeCast: typeCast, nativeCheckOnly: nativeCheckOnly);
    if (name == null) return null;
    CheckedModeHelper helper = checkedModeHelperByName[name];
    assert(helper != null);
    return helper;
  }

  String getCheckedModeHelperNameInternal(DartType type,
      {bool typeCast, bool nativeCheckOnly}) {
    assert(!type.isTypedef);
    if (type.isMalformed) {
      // The same error is thrown for type test and type cast of a malformed
      // type so we only need one check method.
      return 'checkMalformedType';
    }

    if (type.isTypeVariable) {
      return typeCast
          ? 'subtypeOfRuntimeTypeCast'
          : 'assertSubtypeOfRuntimeType';
    }

    if (type.isFunctionType) {
      return typeCast ? 'functionTypeCast' : 'functionTypeCheck';
    }

    assert(type.isInterfaceType,
        failedAt(NO_LOCATION_SPANNABLE, "Unexpected type: $type"));
    InterfaceType interfaceType = type;
    ClassEntity element = interfaceType.element;
    bool nativeCheck = true;
    // TODO(13955), TODO(9731).  The test for non-primitive types should use an
    // interceptor.  The interceptor should be an argument to HTypeConversion so
    // that it can be optimized by standard interceptor optimizations.
    //  nativeCheckOnly || emitter.nativeEmitter.requiresNativeIsCheck(element);

    var suffix = typeCast ? 'TypeCast' : 'TypeCheck';
    if (element == _commonElements.jsStringClass ||
        element == _commonElements.stringClass) {
      if (nativeCheckOnly) return null;
      return 'string$suffix';
    }

    if (element == _commonElements.jsDoubleClass ||
        element == _commonElements.doubleClass) {
      if (nativeCheckOnly) return null;
      return 'double$suffix';
    }

    if (element == _commonElements.jsNumberClass ||
        element == _commonElements.numClass) {
      if (nativeCheckOnly) return null;
      return 'num$suffix';
    }

    if (element == _commonElements.jsBoolClass ||
        element == _commonElements.boolClass) {
      if (nativeCheckOnly) return null;
      return 'bool$suffix';
    }

    if (element == _commonElements.jsIntClass ||
        element == _commonElements.intClass ||
        element == _commonElements.jsUInt32Class ||
        element == _commonElements.jsUInt31Class ||
        element == _commonElements.jsPositiveIntClass) {
      if (nativeCheckOnly) return null;
      return 'int$suffix';
    }

    if (_commonElements.isNumberOrStringSupertype(element)) {
      return nativeCheck
          ? 'numberOrStringSuperNative$suffix'
          : 'numberOrStringSuper$suffix';
    }

    if (_commonElements.isStringOnlySupertype(element)) {
      return nativeCheck ? 'stringSuperNative$suffix' : 'stringSuper$suffix';
    }

    if ((element == _commonElements.listClass ||
            element == _commonElements.jsArrayClass) &&
        type.treatAsRaw) {
      if (nativeCheckOnly) return null;
      return 'list$suffix';
    }

    if (_commonElements.isListSupertype(element)) {
      return nativeCheck ? 'listSuperNative$suffix' : 'listSuper$suffix';
    }

    if (type.isInterfaceType && !type.treatAsRaw) {
      return typeCast ? 'subtypeCast' : 'assertSubtype';
    }

    if (nativeCheck) {
      // TODO(karlklose): can we get rid of this branch when we use
      // interceptors?
      return 'intercepted$suffix';
    } else {
      return 'property$suffix';
    }
  }
}
