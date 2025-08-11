// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common.dart';
import '../common/elements.dart';
import '../constants/constant_system.dart' as constant_system;
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../js/js.dart' as js_ast;
import '../js/js.dart' show js;
import '../js_backend/field_analysis.dart';
import '../js_backend/type_reference.dart' show TypeReference;
import '../js_backend/string_reference.dart'
    show StringReference, StringReferencePolicy;
import '../js_emitter/js_emitter.dart' show Emitter;
import '../js_model/elements.dart';
import '../js_model/records.dart';
import '../js_model/type_recipe.dart' show TypeExpressionRecipe;
import '../options.dart';
import 'namer.dart';
import 'runtime_types_new.dart' show RecipeEncoder;
import 'runtime_types_resolution.dart';

typedef _ConstantReferenceGenerator =
    js_ast.Expression Function(ConstantValue constant);

typedef _ConstantListGenerator =
    js_ast.Expression Function(
      js_ast.Expression array,
      js_ast.Expression reifiedType,
    );

/// Visitor that creates [js_ast.Expression]s for constants that are inlined
/// and therefore can be created during modular code generation.
class ModularConstantEmitter
    implements ConstantValueVisitor<js_ast.Expression?, Null> {
  final CompilerOptions _options;
  final ModularNamer _namer;

  ModularConstantEmitter(this._options, this._namer);

  /// Constructs a literal expression that evaluates to the constant. Uses a
  /// canonical name unless the constant can be emitted multiple times (as for
  /// numbers and strings).
  js_ast.Expression? generate(ConstantValue constant) {
    return _visit(constant);
  }

  js_ast.Expression? _visit(ConstantValue constant) {
    return constant.accept(this, null);
  }

  @override
  js_ast.Expression visitFunction(FunctionConstantValue constant, [_]) {
    throw failedAt(
      noLocationSpannable,
      "The function constant does not need specific JS code.",
    );
  }

  @override
  js_ast.Expression visitNull(NullConstantValue constant, [_]) {
    return js_ast.LiteralNull();
  }

  static final _exponentialRE = RegExp(
    '^'
    '([-+]?)' // 1: sign
    '([0-9]+)' // 2: leading digit(s)
    '(.([0-9]*))?' // 4: fraction digits
    'e([-+]?[0-9]+)' // 5: exponent with sign
    r'$',
  );

  /// Reduces the size of exponential representations when minification is
  /// enabled.
  ///
  /// Removes the "+" after the exponential sign, and removes the "." before the
  /// "e". For example `1.23e+5` is changed to `123e3`.
  String _shortenExponentialRepresentation(String numberString) {
    final match = _exponentialRE.firstMatch(numberString);
    if (match == null) return numberString;
    final sign = match[1]!;
    final leadingDigits = match[2]!;
    String? fractionDigits = match[4];
    int exponent = int.parse(match[5]!);
    fractionDigits ??= '';
    exponent -= fractionDigits.length;
    String result = '$sign$leadingDigits${fractionDigits}e$exponent';
    assert(double.parse(result) == double.parse(numberString));
    return result;
  }

  @override
  js_ast.Expression visitInt(IntConstantValue constant, [_]) {
    BigInt value = constant.intValue;
    // Since we are in JavaScript we can shorten long integers to their shorter
    // exponential representation, for example: "1e4" is shorter than "10000".
    //
    // Note that this shortening apparently loses precision for big numbers
    // (like 1234567890123456789012345 which becomes 12345678901234568e8).
    // However, since JavaScript engines represent all numbers as doubles, these
    // digits are lost anyway.
    String representation = value.toString();
    String? alternative;
    int cutoff = _options.enableMinification ? 10000 : 1e10.toInt();
    if (value.abs() >= BigInt.from(cutoff)) {
      alternative = _shortenExponentialRepresentation(
        value.toDouble().toStringAsExponential(),
      );
    }
    if (alternative != null && alternative.length < representation.length) {
      representation = alternative;
    }
    return js_ast.LiteralNumber(representation);
  }

  @override
  js_ast.Expression visitDouble(DoubleConstantValue constant, [_]) {
    double value = constant.doubleValue;
    if (value.isNaN) {
      return js("0/0");
    } else if (value == double.infinity) {
      return js("1/0");
    } else if (value == -double.infinity) {
      return js("-1/0");
    } else {
      String shortened = _shortenExponentialRepresentation("$value");
      return js_ast.LiteralNumber(shortened);
    }
  }

  @override
  js_ast.Expression visitBool(BoolConstantValue constant, [_]) {
    if (_options.enableMinification) {
      if (constant is TrueConstantValue) {
        // Use !0 for true.
        return js("!0");
      } else {
        // Use !1 for false.
        return js("!1");
      }
    } else {
      return constant is TrueConstantValue
          ? js_ast.LiteralBool(true)
          : js_ast.LiteralBool(false);
    }
  }

  /// Write the contents of the quoted string to a [CodeBuffer] in
  /// a form that is valid as JavaScript string literal content.
  /// The string is assumed quoted by double quote characters.
  @override
  js_ast.Expression visitString(StringConstantValue constant, [_]) {
    String value = constant.stringValue;
    if (value.length < StringReferencePolicy.minimumLength) {
      return js.string(value);
    }
    return StringReference(constant);
  }

  @override
  js_ast.Expression visitDummy(DummyConstantValue constant, [_]) {
    return js_ast.LiteralNumber('0');
  }

  @override
  js_ast.Expression visitLateSentinel(
    LateSentinelConstantValue constant, [
    _,
  ]) => _namer.globalObjectForStaticState();

  @override
  js_ast.Expression visitUnreachable(UnreachableConstantValue constant, [_]) {
    // Unreachable constants should be rare in generated code, so we use
    // `undefined` encoded as `void 1' to make them distinctive.
    return js('void 1');
  }

  @override
  js_ast.Expression visitJsName(JsNameConstantValue constant, [_]) {
    return constant.name;
  }

  @override
  js_ast.Expression? visitInstantiation(
    InstantiationConstantValue constant, [
    _,
  ]) => null;

  @override
  js_ast.Expression? visitDeferredGlobal(
    DeferredGlobalConstantValue constant, [
    _,
  ]) => null;

  @override
  js_ast.Expression? visitInterceptor(InterceptorConstantValue constant, [_]) =>
      null;

  @override
  js_ast.Expression? visitType(TypeConstantValue constant, [_]) => null;

  @override
  js_ast.Expression? visitConstructed(ConstructedConstantValue constant, [_]) =>
      null;

  @override
  js_ast.Expression? visitMap(MapConstantValue constant, [_]) => null;

  @override
  js_ast.Expression? visitSet(SetConstantValue constant, [_]) => null;

  @override
  js_ast.Expression? visitList(ListConstantValue constant, [_]) => null;

  @override
  js_ast.Expression? visitRecord(RecordConstantValue constant, [_]) => null;

  @override
  js_ast.Expression? visitJavaScriptObject(
    JavaScriptObjectConstantValue constant, [
    _,
  ]) => null;
}

/// Generates the JavaScript expressions for constants.
///
/// It uses a given [_constantReferenceGenerator] to reference nested constants
/// (if there are some). It is hence up to that function to decide which
/// constants should be inlined or not.
class ConstantEmitter extends ModularConstantEmitter {
  final JCommonElements _commonElements;
  final JElementEnvironment _elementEnvironment;
  final RuntimeTypesNeed _rtiNeed;
  final RecipeEncoder _rtiRecipeEncoder;
  final JFieldAnalysis _fieldAnalysis;
  final RecordData _recordData;
  final Emitter _emitter;
  final _ConstantReferenceGenerator _constantReferenceGenerator;
  final _ConstantListGenerator _makeConstantList;

  /// The given [_constantReferenceGenerator] function must, when invoked with a
  /// constant, either return a reference or return its literal expression if it
  /// can be inlined.
  ConstantEmitter(
    super.options,
    super._namer,
    this._commonElements,
    this._elementEnvironment,
    this._rtiNeed,
    this._rtiRecipeEncoder,
    this._fieldAnalysis,
    this._recordData,
    this._emitter,
    this._constantReferenceGenerator,
    this._makeConstantList,
  );

  @override
  js_ast.Expression visitList(ListConstantValue constant, [_]) {
    List<js_ast.Expression> elements = constant.entries
        .map(_constantReferenceGenerator)
        .toList(growable: false);
    final array = js_ast.ArrayInitializer(elements);
    final type = constant.type;
    assert(constant.type.element == _commonElements.jsArrayClass);
    final rti = _rtiNeed.classNeedsTypeArguments(type.element)
        ? _reifiedType(type)
        : js_ast.LiteralNull();
    return _makeConstantList(array, rti);
  }

  @override
  js_ast.Expression visitSet(
    constant_system.JavaScriptSetConstant constant, [
    _,
  ]) {
    InterfaceType sourceType = constant.type;
    ClassEntity classElement = sourceType.element;
    String className = classElement.name;

    if (constant.indexObject != null) {
      if (!identical(classElement, _commonElements.constantStringSetClass)) {
        failedAt(
          classElement,
          "Compiler encountered unexpected set class $className",
        );
      }
      List<js_ast.Expression> arguments = [
        _constantReferenceGenerator(constant.indexObject!),
        js.number(constant.length),
        if (_rtiNeed.classNeedsTypeArguments(classElement))
          _reifiedType(sourceType),
      ];
      js_ast.Expression constructor = _emitter.constructorAccess(classElement);
      return js_ast.New(constructor, arguments);
    } else {
      if (!identical(classElement, _commonElements.generalConstantSetClass)) {
        failedAt(
          classElement,
          "Compiler encountered unexpected set class $className",
        );
      }
      List<js_ast.Expression> arguments = [
        js_ast.ArrayInitializer([
          for (final value in constant.values)
            _constantReferenceGenerator(value),
        ]),
        if (_rtiNeed.classNeedsTypeArguments(classElement))
          _reifiedType(sourceType),
      ];
      js_ast.Expression constructor = _emitter.constructorAccess(classElement);
      return js_ast.New(constructor, arguments);
    }
  }

  @override
  js_ast.Expression visitMap(
    constant_system.JavaScriptMapConstant constant, [
    _,
  ]) {
    js_ast.Expression jsMap() {
      List<js_ast.Property> properties = [];
      for (int i = 0; i < constant.length; i++) {
        final key = constant.keys[i] as StringConstantValue;
        if (key.stringValue ==
            constant_system.JavaScriptMapConstant.protoProperty) {
          continue;
        }

        // Keys in literal maps must be emitted in place.
        js_ast.Literal keyExpression = js.string(key.stringValue);
        js_ast.Expression valueExpression = _constantReferenceGenerator(
          constant.values[i],
        );
        properties.add(js_ast.Property(keyExpression, valueExpression));
      }
      return js_ast.ObjectInitializer(properties);
    }

    js_ast.Expression jsGeneralMap() {
      List<js_ast.Expression> data = [];
      for (int i = 0; i < constant.keys.length; i++) {
        js_ast.Expression keyExpression = _constantReferenceGenerator(
          constant.keys[i],
        );
        js_ast.Expression valueExpression = _constantReferenceGenerator(
          constant.values[i],
        );
        data.add(keyExpression);
        data.add(valueExpression);
      }
      return js_ast.ArrayInitializer(data);
    }

    js_ast.Expression jsValuesArray() {
      return js_ast.ArrayInitializer([
        for (final value in constant.values) _constantReferenceGenerator(value),
      ]);
    }

    ClassEntity classElement = constant.type.element;
    String className = classElement.name;

    List<js_ast.Expression> arguments = [];

    // The arguments of the JavaScript constructor for any given Dart class
    // are in the same order as the members of the class element.
    int emittedArgumentCount = 0;
    _elementEnvironment.forEachInstanceField(classElement, (
      ClassEntity enclosing,
      FieldEntity field,
    ) {
      if (_fieldAnalysis.getFieldData(field as JField).isElided) return;
      final name = field.name;
      if (name == constant_system.JavaScriptMapConstant.lengthName) {
        arguments.add(
          js_ast.LiteralNumber('${constant.keyList.entries.length}'),
        );
      } else if (name == constant_system.JavaScriptMapConstant.jsObjectName) {
        arguments.add(jsMap());
      } else if (name == constant_system.JavaScriptMapConstant.keysName) {
        arguments.add(_constantReferenceGenerator(constant.keyList));
      } else if (name == constant_system.JavaScriptMapConstant.jsDataName) {
        arguments.add(jsGeneralMap());
      } else if (name == constant_system.JavaScriptMapConstant.valuesName) {
        arguments.add(jsValuesArray());
      } else if (name == constant_system.JavaScriptMapConstant.jsIndexName) {
        arguments.add(_constantReferenceGenerator(constant.indexObject!));
      } else {
        failedAt(
          field,
          "Compiler has unexpected field ${field.name} for $className.",
        );
      }
      emittedArgumentCount++;
    });
    if ((className == constant_system.JavaScriptMapConstant.dartStringClass &&
            emittedArgumentCount != 2) ||
        (className == constant_system.JavaScriptMapConstant.dartGeneralClass &&
            emittedArgumentCount != 1)) {
      failedAt(
        classElement,
        "Compiler and $className disagree on number of fields.",
      );
    }

    if (_rtiNeed.classNeedsTypeArguments(classElement)) {
      arguments.add(_reifiedType(constant.type));
    }

    js_ast.Expression constructor = _emitter.constructorAccess(classElement);
    js_ast.Expression value = js_ast.New(constructor, arguments);
    return value;
  }

  js_ast.PropertyAccess getHelperProperty(FunctionEntity helper) {
    return _emitter.staticFunctionAccess(helper) as js_ast.PropertyAccess;
  }

  @override
  js_ast.Expression visitJavaScriptObject(
    JavaScriptObjectConstantValue constant, [
    _,
  ]) {
    final List<js_ast.Property> properties = [];
    for (int i = 0; i < constant.keys.length; i++) {
      properties.add(
        js_ast.Property(
          _constantReferenceGenerator(constant.keys[i]),
          _constantReferenceGenerator(constant.values[i]),
        ),
      );
    }
    return js_ast.ObjectInitializer(properties);
  }

  @override
  js_ast.Expression visitType(TypeConstantValue constant, [_]) {
    DartType type = constant.representedType;

    assert(!type.containsTypeVariables);

    js_ast.Expression recipe = _rtiRecipeEncoder.encodeGroundRecipe(
      _emitter,
      TypeExpressionRecipe(type),
    );

    // Generate  `typeLiteral(recipe)`.

    // TODO(sra): `typeLiteral(r)` calls `createRuntimeType(findType(r))`.
    // Find a way to share the `findType` call with methods that also use the
    // type.
    return js('#(#)', [
      getHelperProperty(_commonElements.typeLiteralMaker),
      recipe,
    ]);
  }

  @override
  js_ast.Expression visitInterceptor(InterceptorConstantValue constant, [_]) {
    ClassEntity interceptorClass = constant.cls;
    return _emitter.interceptorPrototypeAccess(interceptorClass);
  }

  @override
  js_ast.Expression visitConstructed(ConstructedConstantValue constant, [_]) {
    ClassEntity element = constant.type.element;
    if (element == _commonElements.jsConstClass) {
      final str = constant.fields.values.single as StringConstantValue;
      String value = str.stringValue;
      return js_ast.LiteralExpression(stripComments(value));
    }
    js_ast.Expression constructor = _emitter.constructorAccess(
      constant.type.element,
    );
    List<js_ast.Expression> fields = [];
    _elementEnvironment.forEachInstanceField(element, (_, FieldEntity field) {
      FieldAnalysisData fieldData = _fieldAnalysis.getFieldData(
        field as JField,
      );
      if (fieldData.isElided) return;
      if (!fieldData.isInitializedInAllocator) {
        fields.add(_constantReferenceGenerator(constant.fields[field]!));
      }
    });
    if (_rtiNeed.classNeedsTypeArguments(constant.type.element)) {
      fields.add(_reifiedType(constant.type));
    }
    return js_ast.New(constructor, fields);
  }

  @override
  js_ast.Expression visitRecord(RecordConstantValue constant, [_]) {
    RecordType recordType = constant.getType(_commonElements) as RecordType;
    RecordRepresentation representation = _recordData
        .representationForStaticType(recordType);
    ClassEntity cls = representation.cls;
    js_ast.Expression constructor = _emitter.constructorAccess(cls);
    List<js_ast.Expression> fields = [
      for (final value in constant.values) _constantReferenceGenerator(value),
    ];
    // TODO(50081): We just trust that the field order is correct. It would be
    // more secure to invert the access paths and use that to look up the slot
    // from the values.
    if (representation.usesList) {
      fields = [js_ast.ArrayInitializer(fields)];
    }
    return js_ast.New(constructor, fields);
  }

  @override
  js_ast.Expression visitInstantiation(
    InstantiationConstantValue constant, [
    _,
  ]) {
    ClassEntity cls = _commonElements.getInstantiationClass(
      constant.typeArguments.length,
    );
    List<js_ast.Expression> fields = [
      _constantReferenceGenerator(constant.function),
    ];
    fields.add(
      _reifiedType(
        _commonElements.dartTypes.interfaceType(cls, constant.typeArguments),
      ),
    );
    js_ast.Expression constructor = _emitter.constructorAccess(cls);
    return js_ast.New(constructor, fields);
  }

  String stripComments(String rawJavaScript) {
    return rawJavaScript.replaceAll(_commentRE, '');
  }

  js_ast.Expression _reifiedType(DartType type) {
    assert(!type.containsTypeVariables);
    return TypeReference(TypeExpressionRecipe(type))..forConstant = true;
  }

  @override
  js_ast.Expression visitDeferredGlobal(
    DeferredGlobalConstantValue constant, [
    _,
  ]) {
    return _constantReferenceGenerator(constant.referenced);
  }
}

// Matches blank lines, comment lines and trailing comments that can't be part
// of a string.
final RegExp _commentRE = RegExp(
  r'''^ *(//.*)?\n|  *//[^''"\n]*$''',
  multiLine: true,
);
