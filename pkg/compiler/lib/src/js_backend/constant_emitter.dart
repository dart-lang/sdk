// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common.dart';
import '../common_elements.dart';
import '../constants/constant_system.dart' as constant_system;
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../io/code_output.dart';
import '../js/js.dart' as jsAst;
import '../js/js.dart' show js;
import '../js_backend/field_analysis.dart';
import '../js_backend/type_reference.dart' show TypeReference;
import '../js_backend/string_reference.dart'
    show StringReference, StringReferencePolicy;
import '../js_emitter/code_emitter_task.dart';
import '../js_model/type_recipe.dart' show TypeExpressionRecipe;
import '../options.dart';
import 'field_analysis.dart' show JFieldAnalysis;
import 'runtime_types_new.dart' show RecipeEncoder;
import 'runtime_types_resolution.dart';

typedef jsAst.Expression _ConstantReferenceGenerator(ConstantValue constant);

typedef jsAst.Expression _ConstantListGenerator(jsAst.Expression array);

/// Visitor that creates [jsAst.Expression]s for constants that are inlined
/// and therefore can be created during modular code generation.
class ModularConstantEmitter
    implements ConstantValueVisitor<jsAst.Expression, Null> {
  final CompilerOptions _options;

  ModularConstantEmitter(this._options);

  /// Constructs a literal expression that evaluates to the constant. Uses a
  /// canonical name unless the constant can be emitted multiple times (as for
  /// numbers and strings).
  jsAst.Expression generate(ConstantValue constant) {
    return _visit(constant);
  }

  jsAst.Expression _visit(ConstantValue constant) {
    return constant.accept(this, null);
  }

  @override
  jsAst.Expression visitFunction(FunctionConstantValue constant, [_]) {
    throw failedAt(NO_LOCATION_SPANNABLE,
        "The function constant does not need specific JS code.");
  }

  @override
  jsAst.Expression visitNull(NullConstantValue constant, [_]) {
    return new jsAst.LiteralNull();
  }

  @override
  jsAst.Expression visitNonConstant(NonConstantValue constant, [_]) {
    return new jsAst.LiteralNull();
  }

  static final _exponentialRE = new RegExp('^'
      '\([-+]?\)' // 1: sign
      '\([0-9]+\)' // 2: leading digit(s)
      '\(\.\([0-9]*\)\)?' // 4: fraction digits
      'e\([-+]?[0-9]+\)' // 5: exponent with sign
      r'$');

  /// Reduces the size of exponential representations when minification is
  /// enabled.
  ///
  /// Removes the "+" after the exponential sign, and removes the "." before the
  /// "e". For example `1.23e+5` is changed to `123e3`.
  String _shortenExponentialRepresentation(String numberString) {
    Match match = _exponentialRE.firstMatch(numberString);
    if (match == null) return numberString;
    String sign = match[1];
    String leadingDigits = match[2];
    String fractionDigits = match[4];
    int exponent = int.parse(match[5]);
    if (fractionDigits == null) fractionDigits = '';
    exponent -= fractionDigits.length;
    String result = '${sign}${leadingDigits}${fractionDigits}e${exponent}';
    assert(double.parse(result) == double.parse(numberString));
    return result;
  }

  @override
  jsAst.Expression visitInt(IntConstantValue constant, [_]) {
    BigInt value = constant.intValue;
    // Since we are in JavaScript we can shorten long integers to their shorter
    // exponential representation, for example: "1e4" is shorter than "10000".
    //
    // Note that this shortening apparently loses precision for big numbers
    // (like 1234567890123456789012345 which becomes 12345678901234568e8).
    // However, since JavaScript engines represent all numbers as doubles, these
    // digits are lost anyway.
    String representation = value.toString();
    String alternative = null;
    int cutoff = _options.enableMinification ? 10000 : 1e10.toInt();
    if (value.abs() >= new BigInt.from(cutoff)) {
      alternative = _shortenExponentialRepresentation(
          value.toDouble().toStringAsExponential());
    }
    if (alternative != null && alternative.length < representation.length) {
      representation = alternative;
    }
    return new jsAst.LiteralNumber(representation);
  }

  @override
  jsAst.Expression visitDouble(DoubleConstantValue constant, [_]) {
    double value = constant.doubleValue;
    if (value.isNaN) {
      return js("0/0");
    } else if (value == double.infinity) {
      return js("1/0");
    } else if (value == -double.infinity) {
      return js("-1/0");
    } else {
      String shortened = _shortenExponentialRepresentation("$value");
      return new jsAst.LiteralNumber(shortened);
    }
  }

  @override
  jsAst.Expression visitBool(BoolConstantValue constant, [_]) {
    if (_options.enableMinification) {
      if (constant.isTrue) {
        // Use !0 for true.
        return js("!0");
      } else {
        // Use !1 for false.
        return js("!1");
      }
    } else {
      return constant.isTrue ? js('true') : js('false');
    }
  }

  /// Write the contents of the quoted string to a [CodeBuffer] in
  /// a form that is valid as JavaScript string literal content.
  /// The string is assumed quoted by double quote characters.
  @override
  jsAst.Expression visitString(StringConstantValue constant, [_]) {
    String value = constant.stringValue;
    if (value.length < StringReferencePolicy.minimumLength) {
      return js.escapedString(value, ascii: true);
    }
    return StringReference(constant);
  }

  @override
  jsAst.Expression visitDummyInterceptor(DummyInterceptorConstantValue constant,
      [_]) {
    return new jsAst.LiteralNumber('0');
  }

  @override
  jsAst.Expression visitUnreachable(UnreachableConstantValue constant, [_]) {
    // Unreachable constants should be rare in generated code, so we use
    // `undefined` encoded as `void 1' to make them distinctive.
    return js('void 1');
  }

  @override
  jsAst.Expression visitJsName(JsNameConstantValue constant, [_]) {
    return constant.name;
  }

  @override
  jsAst.Expression visitInstantiation(InstantiationConstantValue constant,
          [_]) =>
      null;

  @override
  jsAst.Expression visitDeferredGlobal(DeferredGlobalConstantValue constant,
          [_]) =>
      null;

  @override
  jsAst.Expression visitInterceptor(InterceptorConstantValue constant, [_]) =>
      null;

  @override
  jsAst.Expression visitType(TypeConstantValue constant, [_]) => null;

  @override
  jsAst.Expression visitConstructed(ConstructedConstantValue constant, [_]) =>
      null;

  @override
  jsAst.Expression visitMap(MapConstantValue constant, [_]) => null;

  @override
  jsAst.Expression visitSet(SetConstantValue constant, [_]) => null;

  @override
  jsAst.Expression visitList(ListConstantValue constant, [_]) => null;
}

/// Generates the JavaScript expressions for constants.
///
/// It uses a given [_constantReferenceGenerator] to reference nested constants
/// (if there are some). It is hence up to that function to decide which
/// constants should be inlined or not.
class ConstantEmitter extends ModularConstantEmitter {
  // Matches blank lines, comment lines and trailing comments that can't be part
  // of a string.
  static final RegExp COMMENT_RE =
      new RegExp(r'''^ *(//.*)?\n|  *//[^''"\n]*$''', multiLine: true);

  final JCommonElements _commonElements;
  final JElementEnvironment _elementEnvironment;
  final RuntimeTypesNeed _rtiNeed;
  final RecipeEncoder _rtiRecipeEncoder;
  final JFieldAnalysis _fieldAnalysis;
  final Emitter _emitter;
  final _ConstantReferenceGenerator _constantReferenceGenerator;
  final _ConstantListGenerator _makeConstantList;

  /// The given [_constantReferenceGenerator] function must, when invoked with a
  /// constant, either return a reference or return its literal expression if it
  /// can be inlined.
  ConstantEmitter(
      CompilerOptions options,
      this._commonElements,
      this._elementEnvironment,
      this._rtiNeed,
      this._rtiRecipeEncoder,
      this._fieldAnalysis,
      this._emitter,
      this._constantReferenceGenerator,
      this._makeConstantList)
      : super(options);

  @override
  jsAst.Expression visitList(ListConstantValue constant, [_]) {
    List<jsAst.Expression> elements = constant.entries
        .map(_constantReferenceGenerator)
        .toList(growable: false);
    jsAst.ArrayInitializer array = new jsAst.ArrayInitializer(elements);
    jsAst.Expression value = _makeConstantList(array);
    return maybeAddListTypeArgumentsNewRti(constant, constant.type, value);
  }

  @override
  jsAst.Expression visitSet(constant_system.JavaScriptSetConstant constant,
      [_]) {
    InterfaceType sourceType = constant.type;
    ClassEntity classElement = sourceType.element;
    String className = classElement.name;
    if (!identical(classElement, _commonElements.constSetLiteralClass)) {
      failedAt(
          classElement, "Compiler encoutered unexpected set class $className");
    }

    List<jsAst.Expression> arguments = <jsAst.Expression>[
      _constantReferenceGenerator(constant.entries),
    ];

    if (_rtiNeed.classNeedsTypeArguments(classElement)) {
      arguments.add(_reifiedTypeNewRti(sourceType));
    }

    jsAst.Expression constructor = _emitter.constructorAccess(classElement);
    return new jsAst.New(constructor, arguments);
  }

  @override
  jsAst.Expression visitMap(constant_system.JavaScriptMapConstant constant,
      [_]) {
    jsAst.Expression jsMap() {
      List<jsAst.Property> properties = <jsAst.Property>[];
      for (int i = 0; i < constant.length; i++) {
        StringConstantValue key = constant.keys[i];
        if (key.stringValue ==
            constant_system.JavaScriptMapConstant.PROTO_PROPERTY) {
          continue;
        }

        // Keys in literal maps must be emitted in place.
        jsAst.Literal keyExpression =
            js.escapedString(key.stringValue, ascii: true);
        jsAst.Expression valueExpression =
            _constantReferenceGenerator(constant.values[i]);
        properties.add(new jsAst.Property(keyExpression, valueExpression));
      }
      return new jsAst.ObjectInitializer(properties);
    }

    jsAst.Expression jsGeneralMap() {
      List<jsAst.Expression> data = <jsAst.Expression>[];
      for (int i = 0; i < constant.keys.length; i++) {
        jsAst.Expression keyExpression =
            _constantReferenceGenerator(constant.keys[i]);
        jsAst.Expression valueExpression =
            _constantReferenceGenerator(constant.values[i]);
        data.add(keyExpression);
        data.add(valueExpression);
      }
      return new jsAst.ArrayInitializer(data);
    }

    ClassEntity classElement = constant.type.element;
    String className = classElement.name;

    List<jsAst.Expression> arguments = <jsAst.Expression>[];

    // The arguments of the JavaScript constructor for any given Dart class
    // are in the same order as the members of the class element.
    int emittedArgumentCount = 0;
    _elementEnvironment.forEachInstanceField(classElement,
        (ClassEntity enclosing, FieldEntity field) {
      if (_fieldAnalysis.getFieldData(field).isElided) return;
      if (field.name == constant_system.JavaScriptMapConstant.LENGTH_NAME) {
        arguments
            .add(new jsAst.LiteralNumber('${constant.keyList.entries.length}'));
      } else if (field.name ==
          constant_system.JavaScriptMapConstant.JS_OBJECT_NAME) {
        arguments.add(jsMap());
      } else if (field.name ==
          constant_system.JavaScriptMapConstant.KEYS_NAME) {
        arguments.add(_constantReferenceGenerator(constant.keyList));
      } else if (field.name ==
          constant_system.JavaScriptMapConstant.PROTO_VALUE) {
        assert(constant.protoValue != null);
        arguments.add(_constantReferenceGenerator(constant.protoValue));
      } else if (field.name ==
          constant_system.JavaScriptMapConstant.JS_DATA_NAME) {
        arguments.add(jsGeneralMap());
      } else {
        failedAt(field,
            "Compiler has unexpected field ${field.name} for ${className}.");
      }
      emittedArgumentCount++;
    });
    if ((className == constant_system.JavaScriptMapConstant.DART_STRING_CLASS &&
            emittedArgumentCount != 3) ||
        (className == constant_system.JavaScriptMapConstant.DART_PROTO_CLASS &&
            emittedArgumentCount != 4) ||
        (className ==
                constant_system.JavaScriptMapConstant.DART_GENERAL_CLASS &&
            emittedArgumentCount != 1)) {
      failedAt(classElement,
          "Compiler and ${className} disagree on number of fields.");
    }

    if (_rtiNeed.classNeedsTypeArguments(classElement)) {
      arguments.add(_reifiedTypeNewRti(constant.type));
    }

    jsAst.Expression constructor = _emitter.constructorAccess(classElement);
    jsAst.Expression value = new jsAst.New(constructor, arguments);
    return value;
  }

  jsAst.PropertyAccess getHelperProperty(FunctionEntity helper) {
    return _emitter.staticFunctionAccess(helper);
  }

  @override
  jsAst.Expression visitType(TypeConstantValue constant, [_]) {
    DartType type = constant.representedType;

    assert(!type.containsTypeVariables);

    jsAst.Expression recipe = _rtiRecipeEncoder.encodeGroundRecipe(
        _emitter, TypeExpressionRecipe(type));

    // Generate  `typeLiteral(recipe)`.

    // TODO(sra): `typeLiteral(r)` calls `createRuntimeType(findType(r))`.
    // Find a way to share the `findType` call with methods that also use the
    // type.
    return js(
        '#(#)', [getHelperProperty(_commonElements.typeLiteralMaker), recipe]);
  }

  @override
  jsAst.Expression visitInterceptor(InterceptorConstantValue constant, [_]) {
    ClassEntity interceptorClass = constant.cls;
    return _emitter.interceptorPrototypeAccess(interceptorClass);
  }

  @override
  jsAst.Expression visitConstructed(ConstructedConstantValue constant, [_]) {
    ClassEntity element = constant.type.element;
    if (element == _commonElements.jsConstClass) {
      StringConstantValue str = constant.fields.values.single;
      String value = str.stringValue;
      return new jsAst.LiteralExpression(stripComments(value));
    }
    jsAst.Expression constructor =
        _emitter.constructorAccess(constant.type.element);
    List<jsAst.Expression> fields = <jsAst.Expression>[];
    _elementEnvironment.forEachInstanceField(element, (_, FieldEntity field) {
      FieldAnalysisData fieldData = _fieldAnalysis.getFieldData(field);
      if (fieldData.isElided) return;
      if (!fieldData.isInitializedInAllocator) {
        fields.add(_constantReferenceGenerator(constant.fields[field]));
      }
    });
    if (_rtiNeed.classNeedsTypeArguments(constant.type.element)) {
      fields.add(_reifiedTypeNewRti(constant.type));
    }
    return new jsAst.New(constructor, fields);
  }

  @override
  jsAst.Expression visitInstantiation(InstantiationConstantValue constant,
      [_]) {
    ClassEntity cls =
        _commonElements.getInstantiationClass(constant.typeArguments.length);
    List<jsAst.Expression> fields = <jsAst.Expression>[
      _constantReferenceGenerator(constant.function)
    ];
    fields.add(_reifiedTypeNewRti(
        _commonElements.dartTypes.interfaceType(cls, constant.typeArguments)));
    jsAst.Expression constructor = _emitter.constructorAccess(cls);
    return new jsAst.New(constructor, fields);
  }

  String stripComments(String rawJavaScript) {
    return rawJavaScript.replaceAll(COMMENT_RE, '');
  }

  jsAst.Expression maybeAddListTypeArgumentsNewRti(
      ConstantValue constant, InterfaceType type, jsAst.Expression value) {
    assert(type.element == _commonElements.jsArrayClass);
    if (_rtiNeed.classNeedsTypeArguments(type.element)) {
      return new jsAst.Call(
          getHelperProperty(_commonElements.setRuntimeTypeInfo),
          [value, _reifiedTypeNewRti(type)]);
    }
    return value;
  }

  jsAst.Expression _reifiedTypeNewRti(DartType type) {
    assert(!type.containsTypeVariables);
    return TypeReference(TypeExpressionRecipe(type))..forConstant = true;
  }

  @override
  jsAst.Expression visitDeferredGlobal(DeferredGlobalConstantValue constant,
      [_]) {
    return _constantReferenceGenerator(constant.referenced);
  }
}
