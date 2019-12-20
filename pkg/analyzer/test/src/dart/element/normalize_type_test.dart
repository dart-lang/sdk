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
    defineReflectiveTests(NormalizeTypeTest);
  });
}

@reflectiveTest
class NormalizeTypeTest with ElementsTypesMixin {
  @override
  TypeProvider typeProvider;

  TypeSystemImpl typeSystem;

  FeatureSet get testFeatureSet {
    return FeatureSet.forTesting(
      additionalFeatures: [Feature.non_nullable],
    );
  }

  void setUp() {
    var analysisContext = TestAnalysisContext(
      featureSet: testFeatureSet,
    );
    typeProvider = analysisContext.typeProviderNonNullableByDefault;
    typeSystem = analysisContext.typeSystemNonNullableByDefault;
  }

  test_functionType() {
    _check(
      functionTypeNone(
        returnType: intNone,
        typeFormals: [
          typeParameter('T', bound: numNone),
        ],
        parameters: [
          requiredParameter(type: intNone),
        ],
      ),
      functionTypeNone(
        returnType: intNone,
        typeFormals: [
          typeParameter('T', bound: numNone),
        ],
        parameters: [
          requiredParameter(type: intNone),
        ],
      ),
    );

    _check(
      functionTypeNone(
        returnType: futureOrNone(objectNone),
        typeFormals: [
          typeParameter('T', bound: futureOrNone(objectNone)),
        ],
        parameters: [
          requiredParameter(type: futureOrNone(objectNone)),
        ],
      ),
      functionTypeNone(
        returnType: objectNone,
        typeFormals: [
          typeParameter('T', bound: objectNone),
        ],
        parameters: [
          requiredParameter(type: objectNone),
        ],
      ),
    );
  }

  /// NORM(FutureOr<T>)
  /// * let S be NORM(T)
  test_futureOr() {
    void check(DartType T, DartType expected) {
      var input = futureOrNone(T);
      _check(input, expected);
    }

    // * if S is a top type then S
    check(dynamicNone, dynamicNone);
    check(voidNone, voidNone);
    check(objectQuestion, objectQuestion);

    // * if S is Object then S
    check(objectNone, objectNone);

    // * if S is Object* then S
    check(objectStar, objectStar);

    // * if S is Never then Future<Never>
    check(neverNone, futureNone(neverNone));

    // * if S is Null then Future<Null>?
    check(nullNone, futureQuestion(nullNone));

    // * else FutureOr<S>
    check(intNone, futureOrNone(intNone));
  }

  test_interfaceType() {
    _check(listNone(intNone), listNone(intNone));

    _check(
      listNone(
        futureOrNone(objectNone),
      ),
      listNone(objectNone),
    );
  }

  test_primitive() {
    _check(dynamicNone, dynamicNone);
    _check(neverNone, neverNone);
    _check(voidNone, voidNone);
    _check(intNone, intNone);
  }

  /// NORM(T?)
  /// * let S be NORM(T)
  test_question() {
    void check(DartType T, DartType expected) {
      _assertNullabilityQuestion(T);
      _check(T, expected);
    }

    // * if S is a top type then S
    check(futureOrQuestion(dynamicNone), dynamicNone);
    check(futureOrQuestion(voidNone), voidNone);
    check(futureOrQuestion(objectQuestion), objectQuestion);

    // * if S is Never then Null
    check(neverQuestion, nullNone);

    // * if S is Never* then Null
    // Analyzer: impossible, we have only one suffix

    // * if S is Null then Null
    check(nullQuestion, nullNone);

    // * if S is FutureOr<R> and R is nullable then S
    check(futureOrQuestion(intQuestion), futureOrNone(intQuestion));

    // * if S is FutureOr<R>* and R is nullable then FutureOr<R>
    // Analyzer: impossible, we have only one suffix

    // * if S is R? then R?
    // * if S is R* then R?
    // * else S?
    check(intQuestion, intQuestion);
    check(objectQuestion, objectQuestion);
    check(futureOrQuestion(objectNone), objectQuestion);
    check(futureOrQuestion(objectStar), objectStar);
  }

  /// NORM(T*)
  /// * let S be NORM(T)
  test_star() {
    void check(DartType T, DartType expected) {
      _assertNullabilityStar(T);
      _check(T, expected);
    }

    // * if S is a top type then S
    check(futureOrStar(dynamicNone), dynamicNone);
    check(futureOrStar(voidNone), voidNone);
    check(futureOrStar(objectQuestion), objectQuestion);

    // * if S is Null then Null
    check(nullStar, nullNone);

    // * if S is R? then R?
    check(futureOrStar(nullNone), futureQuestion(nullNone));

    // * if S is R* then R*
    // * else S*
    check(intStar, intStar);
  }

  test_typeParameter_bound() {
    TypeParameterElement T;

    T = typeParameter('T');
    _check(typeParameterTypeNone(T), typeParameterTypeNone(T));

    T = typeParameter('T', bound: numNone);
    _check(typeParameterTypeNone(T), typeParameterTypeNone(T));

    T = typeParameter('T', bound: futureOrNone(objectNone));
    _check(
      typeParameterTypeNone(T),
      typeParameterTypeNone(
        promoteTypeParameter(T, objectNone),
      ),
    );
  }

  /// NORM(X & T)
  /// * let S be NORM(T)
  test_typeParameter_promoted() {
    var T = typeParameter('T');

    // * if S is Never then Never
    _check(
      typeParameterTypeNone(
        promoteTypeParameter(T, neverNone),
      ),
      neverNone,
    );

    // * if S is a top type then X
    _check(
      typeParameterTypeNone(
        promoteTypeParameter(T, objectQuestion),
      ),
      typeParameterTypeNone(T),
    );
    _check(
      typeParameterTypeNone(
        promoteTypeParameter(T, futureOrQuestion(objectNone)),
      ),
      typeParameterTypeNone(T),
    );

    // * if S is X then X
    _check(
      typeParameterTypeNone(
        promoteTypeParameter(T, typeParameterTypeNone(T)),
      ),
      typeParameterTypeNone(T),
    );

    // * if S is Object and NORM(B) is Object where B is the bound of X then X
    T = typeParameter('T', bound: objectNone);
    _check(
      typeParameterTypeNone(
        promoteTypeParameter(T, futureOrNone(objectNone)),
      ),
      typeParameterTypeNone(T),
    );

    // else X & S
    T = typeParameter('T');
    _check(
      typeParameterTypeNone(
        promoteTypeParameter(T, futureOrNone(neverNone)),
      ),
      typeParameterTypeNone(
        promoteTypeParameter(T, futureNone(neverNone)),
      ),
    );
  }

  void _assertNullability(DartType type, NullabilitySuffix expected) {
    if ((type as TypeImpl).nullabilitySuffix != expected) {
      fail('Expected $expected in ' + _typeString(type));
    }
  }

  void _assertNullabilityQuestion(DartType type) {
    _assertNullability(type, NullabilitySuffix.question);
  }

  void _assertNullabilityStar(DartType type) {
    _assertNullability(type, NullabilitySuffix.star);
  }

  void _check(DartType T, DartType expected) {
    var expectedStr = _typeString(expected);

    var result = typeSystem.normalize(T);
    var resultStr = _typeString(result);
    expect(result, expected, reason: '''
expected: $expectedStr
actual: $resultStr
''');
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
          var baseBoundStr = baseBound.getDisplayString(withNullability: true);
          typeStr += ', ${typeParameter.name} extends ' + baseBoundStr;
        }

        var bound = typeParameter.bound as TypeImpl;
        var boundStr = bound.getDisplayString(withNullability: true);
        typeStr += ', ${typeParameter.name} & ' + boundStr;
      } else {
        var bound = typeParameter.bound as TypeImpl;
        if (bound != null) {
          var boundStr = bound.getDisplayString(withNullability: true);
          typeStr += ', ${typeParameter.name} extends ' + boundStr;
        }
      }
    }
    return typeStr;
  }

  String _typeString(TypeImpl type) {
    if (type == null) return null;
    return type.getDisplayString(withNullability: true) +
        _typeParametersStr(type);
  }
}

class _TypeParameterCollector extends DartTypeVisitor<void> {
  final Set<TypeParameterElement> typeParameters = {};

  /// We don't need to print bounds for these type parameters, because
  /// they are already included into the function type itself, and cannot
  /// be promoted.
  final Set<TypeParameterElement> functionTypeParameters = {};

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
