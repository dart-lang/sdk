// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_visitor.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/elements_types_mixin.dart';
import '../../../generated/test_analysis_context.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BoundsHelperPredicatesTest);
  });
}

@reflectiveTest
class BoundsHelperPredicatesTest extends _SubtypingTestBase {
  static final Map<String, StackTrace> _isMoreBottomChecked = {};
  static final Map<String, StackTrace> _isMoreTopChecked = {};

  @override
  FeatureSet get testFeatureSet {
    return FeatureSet.forTesting(
      additionalFeatures: [Feature.non_nullable],
    );
  }

  void isBottom(DartType type) {
    expect(typeSystem.isBottom(type), isTrue, reason: _typeString(type));
  }

  void isMoreBottom(DartType T, DartType S) {
    _assertIsBottomOrNull(T);
    _assertIsBottomOrNull(S);

    var str = _typeString(T) + ' vs ' + _typeString(S);
    _checkUniqueTypeStr(_isMoreBottomChecked, str);

    expect(typeSystem.isMoreBottom(T, S), isTrue, reason: str);
  }

  void isMoreTop(DartType T, DartType S) {
    _assertIsTopOrObject(T);
    _assertIsTopOrObject(S);

    var str = _typeString(T) + ' vs ' + _typeString(S);
    _checkUniqueTypeStr(_isMoreTopChecked, str);

    expect(typeSystem.isMoreTop(T, S), isTrue, reason: str);
  }

  void isNotBottom(DartType type) {
    expect(typeSystem.isBottom(type), isFalse, reason: _typeString(type));
  }

  void isNotMoreBottom(DartType T, DartType S) {
    _assertIsBottomOrNull(T);
    _assertIsBottomOrNull(S);

    var str = _typeString(T) + ' vs ' + _typeString(S);
    _checkUniqueTypeStr(_isMoreBottomChecked, str);

    expect(typeSystem.isMoreBottom(T, S), isFalse, reason: str);
  }

  void isNotMoreTop(DartType T, DartType S) {
    _assertIsTopOrObject(T);
    _assertIsTopOrObject(S);

    var str = _typeString(T) + ' vs ' + _typeString(S);
    _checkUniqueTypeStr(_isMoreTopChecked, str);

    expect(typeSystem.isMoreTop(T, S), isFalse, reason: str);
  }

  void isNotNull(DartType type) {
    expect(typeSystem.isNull(type), isFalse, reason: _typeString(type));
  }

  void isNotObject(DartType type) {
    expect(typeSystem.isObject(type), isFalse, reason: _typeString(type));
  }

  void isNotTop(DartType type) {
    expect(typeSystem.isTop(type), isFalse, reason: _typeString(type));
  }

  void isNull(DartType type) {
    expect(typeSystem.isNull(type), isTrue, reason: _typeString(type));
  }

  void isObject(DartType type) {
    expect(typeSystem.isObject(type), isTrue, reason: _typeString(type));
  }

  void isTop(DartType type) {
    expect(typeSystem.isTop(type), isTrue, reason: _typeString(type));
  }

  test_isBottom() {
    TypeParameterElement T;
    TypeParameterMember T2;

    // BOTTOM(Never) is true
    isBottom(neverNone);
    isNotBottom(neverQuestion);
    isNotBottom(neverStar);

    // BOTTOM(X&T) is true iff BOTTOM(T)
    T = typeParameter('T', bound: objectQuestion);

    T2 = promoteTypeParameter(T, neverNone);
    isBottom(typeParameterTypeNone(T2));
    isBottom(typeParameterTypeQuestion(T2));
    isBottom(typeParameterTypeStar(T2));

    T2 = promoteTypeParameter(T, neverQuestion);
    isNotBottom(typeParameterTypeNone(T2));
    isNotBottom(typeParameterTypeQuestion(T2));
    isNotBottom(typeParameterTypeStar(T2));

    // BOTTOM(X extends T) is true iff BOTTOM(T)
    T = typeParameter('T', bound: neverNone);
    isBottom(typeParameterTypeNone(T));
    isBottom(typeParameterTypeQuestion(T));
    isBottom(typeParameterTypeStar(T));

    T = typeParameter('T', bound: neverQuestion);
    isNotBottom(typeParameterTypeNone(T));
    isNotBottom(typeParameterTypeQuestion(T));
    isNotBottom(typeParameterTypeStar(T));

    // BOTTOM(T) is false otherwise
    isNotBottom(dynamicNone);
    isNotBottom(voidNone);

    isNotBottom(objectNone);
    isNotBottom(objectQuestion);
    isNotBottom(objectStar);

    isNotBottom(intNone);
    isNotBottom(intQuestion);
    isNotBottom(intStar);

    T = typeParameter('T', bound: numNone);
    isNotBottom(typeParameterTypeNone(T));
    isNotBottom(typeParameterTypeQuestion(T));
    isNotBottom(typeParameterTypeStar(T));

    T = typeParameter('T', bound: numStar);
    isNotBottom(typeParameterTypeNone(T));
    isNotBottom(typeParameterTypeQuestion(T));
    isNotBottom(typeParameterTypeStar(T));

    T2 = promoteTypeParameter(typeParameter('T'), intNone);
    isNotBottom(typeParameterTypeNone(T2));
    isNotBottom(typeParameterTypeQuestion(T2));
    isNotBottom(typeParameterTypeStar(T2));
  }

  test_isMoreBottom() {
    // MOREBOTTOM(Never, T) = true
    isMoreBottom(neverNone, neverNone);
    isMoreBottom(neverNone, neverQuestion);
    isMoreBottom(neverNone, neverStar);

    isMoreBottom(neverNone, nullNone);
    isMoreBottom(neverNone, nullQuestion);
    isMoreBottom(neverNone, nullStar);

    // MOREBOTTOM(T, Never) = false
    isNotMoreBottom(neverQuestion, neverNone);
    isNotMoreBottom(neverStar, neverNone);

    isNotMoreBottom(nullNone, neverNone);
    isNotMoreBottom(nullQuestion, neverNone);
    isNotMoreBottom(nullStar, neverNone);

    // MOREBOTTOM(Null, T) = true
    isMoreBottom(nullNone, neverQuestion);
    isMoreBottom(nullNone, neverStar);

    isMoreBottom(nullNone, nullNone);
    isMoreBottom(nullNone, nullQuestion);
    isMoreBottom(nullNone, nullStar);

    // MOREBOTTOM(T, Null) = false
    isNotMoreBottom(neverQuestion, nullNone);
    isNotMoreBottom(neverStar, nullNone);

    isNotMoreBottom(nullQuestion, nullNone);
    isNotMoreBottom(nullStar, nullNone);

    // MOREBOTTOM(T?, S?) = MOREBOTTOM(T, S)
    isMoreBottom(neverQuestion, nullQuestion);
    isNotMoreBottom(nullQuestion, neverQuestion);

    // MOREBOTTOM(T, S?) = true
    isMoreBottom(neverStar, nullQuestion);
    isMoreBottom(nullStar, neverQuestion);

    // MOREBOTTOM(T?, S) = false
    isNotMoreBottom(neverQuestion, nullStar);
    isNotMoreBottom(nullQuestion, neverStar);

    // MOREBOTTOM(T*, S*) = MOREBOTTOM(T, S)
    isMoreBottom(neverStar, nullStar);
    isNotMoreBottom(nullStar, neverStar);

    // MOREBOTTOM(T, S*) = true
    isMoreBottom(
      typeParameterTypeNone(
        typeParameter('S', bound: neverNone),
      ),
      nullStar,
    );

    // MOREBOTTOM(T*, S) = false
    isNotMoreBottom(
      nullStar,
      typeParameterTypeNone(
        typeParameter('S', bound: neverNone),
      ),
    );

    // MOREBOTTOM(X&T, Y&S) = MOREBOTTOM(T, S)
    isMoreBottom(
      typeParameterTypeNone(
        promoteTypeParameter(
          typeParameter('T', bound: objectQuestion),
          neverNone,
        ),
      ),
      typeParameterTypeQuestion(
        promoteTypeParameter(
          typeParameter('S', bound: objectQuestion),
          neverNone,
        ),
      ),
    );

    // MOREBOTTOM(X&T, S) = true
    isMoreBottom(
      typeParameterTypeNone(
        promoteTypeParameter(
          typeParameter('T', bound: objectQuestion),
          neverNone,
        ),
      ),
      typeParameterTypeNone(
        typeParameter('S', bound: neverNone),
      ),
    );

    // MOREBOTTOM(T, X&S) = false
    isNotMoreBottom(
      typeParameterTypeNone(
        typeParameter('T', bound: neverNone),
      ),
      typeParameterTypeNone(
        promoteTypeParameter(
          typeParameter('S', bound: objectQuestion),
          neverNone,
        ),
      ),
    );

    // MOREBOTTOM(X extends T, Y extends S) = MOREBOTTOM(T, S)
    isMoreBottom(
      typeParameterTypeNone(
        typeParameter('T', bound: neverNone),
      ),
      typeParameterTypeQuestion(
        typeParameter('S', bound: neverNone),
      ),
    );
  }

  test_isMoreTop() {
    // MORETOP(void, T) = true
    isMoreTop(voidNone, voidNone);
    isMoreTop(voidNone, dynamicNone);
    isMoreTop(voidNone, objectNone);
    isMoreTop(voidNone, objectQuestion);
    isMoreTop(voidNone, objectStar);
    isMoreTop(voidNone, futureOrNone(objectNone));
    isMoreTop(voidNone, futureOrNone(objectQuestion));
    isMoreTop(voidNone, futureOrNone(objectStar));

    // MORETOP(T, void) = false
    isNotMoreTop(dynamicNone, voidNone);
    isNotMoreTop(objectNone, voidNone);
    isNotMoreTop(objectQuestion, voidNone);
    isNotMoreTop(objectStar, voidNone);
    isNotMoreTop(futureOrNone(objectNone), voidNone);
    isNotMoreTop(futureOrNone(objectQuestion), voidNone);
    isNotMoreTop(futureOrNone(objectStar), voidNone);

    // MORETOP(dynamic, T) = true
    isMoreTop(dynamicNone, dynamicNone);
    isMoreTop(dynamicNone, objectNone);
    isMoreTop(dynamicNone, objectQuestion);
    isMoreTop(dynamicNone, objectStar);
    isMoreTop(dynamicNone, futureOrNone(objectNone));
    isMoreTop(dynamicNone, futureOrNone(objectQuestion));
    isMoreTop(dynamicNone, futureOrNone(objectStar));

    // MORETOP(T, dynamic) = false
    isNotMoreTop(objectNone, dynamicNone);
    isNotMoreTop(objectQuestion, dynamicNone);
    isNotMoreTop(objectStar, dynamicNone);
    isNotMoreTop(futureOrNone(objectNone), dynamicNone);
    isNotMoreTop(futureOrNone(objectQuestion), dynamicNone);
    isNotMoreTop(futureOrNone(objectStar), dynamicNone);

    // MORETOP(Object, T) = true
    isMoreTop(objectNone, objectNone);
    isMoreTop(objectNone, objectQuestion);
    isMoreTop(objectNone, objectStar);
    isMoreTop(objectNone, futureOrNone(objectNone));
    isMoreTop(objectNone, futureOrQuestion(objectNone));
    isMoreTop(objectNone, futureOrStar(objectNone));

    // MORETOP(T, Object) = false
    isNotMoreTop(objectQuestion, objectNone);
    isNotMoreTop(objectStar, objectNone);
    isNotMoreTop(futureOrNone(objectNone), objectNone);
    isNotMoreTop(futureOrQuestion(objectNone), objectNone);
    isNotMoreTop(futureOrStar(objectNone), objectNone);

    // MORETOP(T*, S*) = MORETOP(T, S)
    isMoreTop(objectStar, objectStar);
    isMoreTop(objectStar, futureOrStar(objectNone));
    isMoreTop(objectStar, futureOrStar(objectQuestion));
    isMoreTop(objectStar, futureOrStar(objectStar));
    isMoreTop(futureOrStar(objectNone), futureOrStar(objectNone));

    // MORETOP(T, S*) = true
    isMoreTop(futureOrNone(objectNone), futureOrStar(voidNone));
    isMoreTop(futureOrNone(objectNone), futureOrStar(dynamicNone));
    isMoreTop(futureOrNone(objectNone), futureOrStar(objectNone));
    isMoreTop(futureOrQuestion(objectNone), futureOrStar(voidNone));
    isMoreTop(futureOrQuestion(objectNone), futureOrStar(dynamicNone));
    isMoreTop(futureOrQuestion(objectNone), futureOrStar(objectNone));

    // MORETOP(T*, S) = false
    isNotMoreTop(futureOrStar(voidNone), futureOrNone(objectNone));
    isNotMoreTop(futureOrStar(dynamicNone), futureOrNone(objectNone));
    isNotMoreTop(futureOrStar(objectNone), futureOrNone(objectNone));
    isNotMoreTop(futureOrStar(voidNone), futureOrQuestion(objectNone));
    isNotMoreTop(futureOrStar(dynamicNone), futureOrQuestion(objectNone));
    isNotMoreTop(futureOrStar(objectNone), futureOrQuestion(objectNone));

    // MORETOP(T?, S?) = MORETOP(T, S)
    isMoreTop(objectQuestion, objectQuestion);
    isMoreTop(futureOrQuestion(voidNone), futureOrQuestion(voidNone));
    isMoreTop(futureOrQuestion(voidNone), futureOrQuestion(dynamicNone));
    isMoreTop(futureOrQuestion(voidNone), futureOrQuestion(objectNone));

    // MORETOP(T, S?) = true
    isMoreTop(futureOrNone(objectNone), futureOrQuestion(voidNone));
    isMoreTop(futureOrNone(objectNone), futureOrQuestion(dynamicNone));
    isMoreTop(futureOrNone(objectNone), futureOrQuestion(objectNone));

    // MORETOP(T?, S) = false
    isNotMoreTop(futureOrQuestion(voidNone), futureOrNone(objectNone));
    isNotMoreTop(futureOrQuestion(dynamicNone), futureOrNone(objectNone));
    isNotMoreTop(futureOrQuestion(objectNone), futureOrNone(objectNone));

    // MORETOP(FutureOr<T>, FutureOr<S>) = MORETOP(T, S)
    isMoreTop(futureOrNone(voidNone), futureOrNone(voidNone));
    isMoreTop(futureOrNone(voidNone), futureOrNone(dynamicNone));
    isMoreTop(futureOrNone(voidNone), futureOrNone(objectNone));
    isNotMoreTop(futureOrNone(dynamicNone), futureOrNone(voidNone));
    isNotMoreTop(futureOrNone(objectNone), futureOrNone(voidNone));
  }

  test_isNull() {
    // NULL(Null) is true
    isNull(nullNone);

    // NULL(T?) is true iff NULL(T) or BOTTOM(T)
    isNull(nullQuestion);
    isNull(neverQuestion);
    isNull(
      typeParameterTypeQuestion(
        typeParameter('T', bound: neverNone),
      ),
    );

    // NULL(T*) is true iff NULL(T) or BOTTOM(T)
    isNull(nullStar);
    isNull(neverStar);
    isNull(
      typeParameterTypeStar(
        typeParameter('T', bound: neverNone),
      ),
    );

    // NULL(T) is false otherwise
    isNotNull(dynamicNone);
    isNotNull(voidNone);

    isNotNull(objectNone);
    isNotNull(objectQuestion);
    isNotNull(objectStar);

    isNotNull(intNone);
    isNotNull(intQuestion);
    isNotNull(intStar);

    isNotNull(futureOrNone(nullNone));
    isNotNull(futureOrNone(nullQuestion));
    isNotNull(futureOrNone(nullStar));

    isNotNull(futureOrQuestion(nullNone));
    isNotNull(futureOrQuestion(nullQuestion));
    isNotNull(futureOrQuestion(nullStar));

    isNotNull(futureOrStar(nullNone));
    isNotNull(futureOrStar(nullQuestion));
    isNotNull(futureOrStar(nullStar));
  }

  test_isObject() {
    // OBJECT(Object) is true
    isObject(objectNone);
    isNotObject(objectQuestion);
    isNotObject(objectStar);

    // OBJECT(FutureOr<T>) is OBJECT(T)
    isObject(futureOrNone(objectNone));
    isNotObject(futureOrNone(objectQuestion));
    isNotObject(futureOrNone(objectStar));

    isNotObject(futureOrQuestion(objectNone));
    isNotObject(futureOrQuestion(objectQuestion));
    isNotObject(futureOrQuestion(objectStar));

    isNotObject(futureOrStar(objectNone));
    isNotObject(futureOrStar(objectQuestion));
    isNotObject(futureOrStar(objectStar));

    // OBJECT(T) is false otherwise
    isNotObject(dynamicNone);
    isNotObject(voidNone);
    isNotObject(intNone);
  }

  test_isTop() {
    // TOP(T?) is true iff TOP(T) or OBJECT(T)
    isTop(objectQuestion);
    isTop(futureOrQuestion(dynamicNone));
    isTop(futureOrQuestion(voidNone));

    isTop(futureOrQuestion(objectNone));
    isTop(futureOrQuestion(objectQuestion));
    isTop(futureOrQuestion(objectStar));

    isNotTop(futureOrQuestion(intNone));
    isNotTop(futureOrQuestion(intQuestion));
    isNotTop(futureOrQuestion(intStar));

    // TOP(T*) is true iff TOP(T) or OBJECT(T)
    isTop(objectStar);
    isTop(futureOrStar(dynamicNone));
    isTop(futureOrStar(voidNone));

    isTop(futureOrStar(objectNone));
    isTop(futureOrStar(objectQuestion));
    isTop(futureOrStar(objectStar));

    isNotTop(futureOrStar(intNone));
    isNotTop(futureOrStar(intQuestion));
    isNotTop(futureOrStar(intStar));

    // TOP(dynamic) is true
    isTop(dynamicNone);

    // TOP(void) is true
    isTop(voidNone);

    // TOP(FutureOr<T>) is TOP(T)
    isTop(futureOrNone(dynamicNone));
    isTop(futureOrNone(voidNone));

    isNotTop(futureOrNone(objectNone));
    isTop(futureOrNone(objectQuestion));
    isTop(futureOrNone(objectStar));

    // TOP(T) is false otherwise
    isNotTop(objectNone);

    isNotTop(intNone);
    isNotTop(intQuestion);
    isNotTop(intStar);

    isNotTop(neverNone);
    isNotTop(neverQuestion);
    isNotTop(neverStar);
  }

  /// [TypeSystemImpl.isMoreBottom] can be used only for `BOTTOM` or `NULL`
  /// types. No need to check other types.
  void _assertIsBottomOrNull(DartType type) {
    expect(typeSystem.isBottom(type) || typeSystem.isNull(type), isTrue,
        reason: _typeString(type));
  }

  /// [TypeSystemImpl.isMoreTop] can be used only for `TOP` or `OBJECT`
  /// types. No need to check other types.
  void _assertIsTopOrObject(DartType type) {
    expect(typeSystem.isTop(type) || typeSystem.isObject(type), isTrue,
        reason: _typeString(type));
  }

  void _checkUniqueTypeStr(Map<String, StackTrace> map, String str) {
    var previousStack = map[str];
    if (previousStack != null) {
      fail('Not unique: $str\n$previousStack');
    } else {
      map[str] = StackTrace.current;
    }
  }

  String _typeParametersStr(TypeImpl type) {
    var typeStr = '';

    var typeParameterCollector = _TypeParameterCollector();
    DartTypeVisitor.visit(type, typeParameterCollector);
    for (var typeParameter in typeParameterCollector.typeParameters) {
      if (typeParameter is TypeParameterMember) {
        var base = typeParameter.declaration;
        var baseBound = base.bound as TypeImpl;
        if (baseBound != null) {
          var baseBoundStr = baseBound.toString(withNullability: true);
          typeStr += ', ${typeParameter.name} extends ' + baseBoundStr;
        }

        var bound = typeParameter.bound as TypeImpl;
        var boundStr = bound.toString(withNullability: true);
        typeStr += ', ${typeParameter.name} & ' + boundStr;
      } else {
        var bound = typeParameter.bound as TypeImpl;
        if (bound != null) {
          var boundStr = bound.toString(withNullability: true);
          typeStr += ', ${typeParameter.name} extends ' + boundStr;
        }
      }
    }
    return typeStr;
  }
}

@reflectiveTest
class _SubtypingTestBase with ElementsTypesMixin {
  TypeProvider typeProvider;

  TypeSystemImpl typeSystem;

  DartType get dynamicNone => typeProvider.dynamicType;

  InterfaceType get intNone {
    var element = typeProvider.intType.element;
    return element.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceType get intQuestion {
    var element = typeProvider.intType.element;
    return element.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  InterfaceType get intStar {
    var element = typeProvider.intType.element;
    return element.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.star,
    );
  }

  InterfaceType get nullNone {
    var element = typeProvider.nullType.element;
    return element.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceType get nullQuestion {
    var element = typeProvider.nullType.element;
    return element.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  InterfaceType get nullStar {
    var element = typeProvider.nullType.element;
    return element.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.star,
    );
  }

  InterfaceType get numNone {
    var element = typeProvider.numType.element;
    return element.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceType get numQuestion {
    var element = typeProvider.numType.element;
    return element.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  InterfaceType get numStar {
    var element = typeProvider.numType.element;
    return element.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.star,
    );
  }

  InterfaceType get objectNone {
    var element = typeProvider.objectType.element;
    return element.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceType get objectQuestion {
    var element = typeProvider.objectType.element;
    return element.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  InterfaceType get objectStar {
    var element = typeProvider.objectType.element;
    return element.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.star,
    );
  }

  FeatureSet get testFeatureSet {
    return FeatureSet.forTesting();
  }

  VoidType get voidNone => typeProvider.voidType;

  InterfaceTypeImpl futureOrNone(DartType type) {
    return typeProvider.futureOrElement.instantiate(
      typeArguments: [type],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceTypeImpl futureOrQuestion(DartType type) {
    return typeProvider.futureOrElement.instantiate(
      typeArguments: [type],
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  InterfaceTypeImpl futureOrStar(DartType type) {
    return typeProvider.futureOrElement.instantiate(
      typeArguments: [type],
      nullabilitySuffix: NullabilitySuffix.star,
    );
  }

  void setUp() {
    var analysisContext = TestAnalysisContext(
      featureSet: testFeatureSet,
    );
    typeProvider = analysisContext.typeProvider;
    typeSystem = analysisContext.typeSystem;
  }

  String _typeParametersStr(TypeImpl type) {
    var typeStr = '';

    var typeParameterCollector = _TypeParameterCollector();
    DartTypeVisitor.visit(type, typeParameterCollector);
    for (var typeParameter in typeParameterCollector.typeParameters) {
      if (typeParameter is TypeParameterMember) {
        var base = typeParameter.declaration;
        var baseBound = base.bound as TypeImpl;
        if (baseBound != null) {
          var baseBoundStr = baseBound.toString(withNullability: true);
          typeStr += ', ${typeParameter.name} extends ' + baseBoundStr;
        }

        var bound = typeParameter.bound as TypeImpl;
        var boundStr = bound.toString(withNullability: true);
        typeStr += ', ${typeParameter.name} & ' + boundStr;
      } else {
        var bound = typeParameter.bound as TypeImpl;
        if (bound != null) {
          var boundStr = bound.toString(withNullability: true);
          typeStr += ', ${typeParameter.name} extends ' + boundStr;
        }
      }
    }
    return typeStr;
  }

  String _typeString(TypeImpl type) {
    return type.toString(withNullability: true) + _typeParametersStr(type);
  }
}

class _TypeParameterCollector extends DartTypeVisitor<void> {
  final Set<TypeParameterElement> typeParameters = Set();

  /// We don't need to print bounds for these type parameters, because
  /// they are already included into the function type itself, and cannot
  /// be promoted.
  final Set<TypeParameterElement> functionTypeParameters = Set();

  @override
  void defaultDartType(DartType type) {
    throw UnimplementedError('(${type.runtimeType}) $type');
  }

  @override
  void visitDynamicType(DynamicTypeImpl type) {}

  @override
  void visitFunctionType(FunctionType type) {
    functionTypeParameters.addAll(type.typeFormals);
    for (var typeParameter in type.typeFormals) {
      var bound = typeParameter.bound;
      if (bound != null) {
        DartTypeVisitor.visit(bound, this);
      }
    }
    for (var parameter in type.parameters) {
      DartTypeVisitor.visit(parameter.type, this);
    }
    DartTypeVisitor.visit(type.returnType, this);
  }

  @override
  void visitInterfaceType(InterfaceType type) {
    for (var typeArgument in type.typeArguments) {
      DartTypeVisitor.visit(typeArgument, this);
    }
  }

  @override
  void visitNeverType(NeverTypeImpl type) {}

  @override
  void visitTypeParameterType(TypeParameterType type) {
    if (!functionTypeParameters.contains(type.element)) {
      typeParameters.add(type.element);
    }
  }

  @override
  void visitVoidType(VoidType type) {}
}
