// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/file_source.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/test_utilities/test_library_builder.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GenericFunctionInferenceTest);
  });
}

@reflectiveTest
class GenericFunctionInferenceTest extends AbstractTypeSystemTest {
  void test_boundedByAnotherTypeParameter() {
    // <TFrom, TTo extends Iterable<TFrom>>(TFrom) -> TTo
    var cast = parseFunctionType(
      'TTo Function<TFrom, TTo extends Iterable<TFrom>>(TFrom)',
    );
    _assertTypes(_inferCall(cast, [parseType('String')]), [
      parseType('String'),
      parseType('Iterable<String>'),
    ]);
  }

  void test_boundedByOuterClass() {
    // Regression test for https://github.com/dart-lang/sdk/issues/25740.

    buildTestLibrary(
      classes: [
        ClassSpec('class A'),
        ClassSpec('class B extends A'),
        ClassSpec(
          'class C<T extends A>',
          methods: [MethodSpec('S m<S extends T>(S _)')],
        ),
      ],
    );

    // class B extends A {}
    var typeB = parseInterfaceType('B');

    // class C<T extends A> { S m<S extends T>(S); }
    // C<Object> cOfObject;
    var cOfObject = parseInterfaceType('C<Object>');
    // C<A> cOfA;
    var cOfA = parseInterfaceType('C<A>');
    // C<B> cOfB;
    var cOfB = parseInterfaceType('C<B>');
    // B b;
    // cOfB.m(b); // infer <B>
    _assertType(
      _inferCall2(cOfB.getMethod('m')!.type, [typeB]),
      'B Function(B)',
    );
    // cOfA.m(b); // infer <B>
    _assertType(
      _inferCall2(cOfA.getMethod('m')!.type, [typeB]),
      'B Function(B)',
    );
    // cOfObject.m(b); // infer <B>
    _assertType(
      _inferCall2(cOfObject.getMethod('m')!.type, [typeB]),
      'B Function(B)',
    );
  }

  void test_boundedByOuterClassSubstituted() {
    // Regression test for https://github.com/dart-lang/sdk/issues/25740.

    buildTestLibrary(
      classes: [
        ClassSpec('class A'),
        ClassSpec('class B extends A'),
        ClassSpec(
          'class C<T extends A>',
          methods: [MethodSpec('S m<S extends Iterable<T>>(S _)')],
        ),
      ],
    );

    // class C<T extends A> { S m<S extends Iterable<T>>(S); }
    // C<Object> cOfObject;
    var cOfObject = parseInterfaceType('C<Object>');
    // C<A> cOfA;
    var cOfA = parseInterfaceType('C<A>');
    // C<B> cOfB;
    var cOfB = parseInterfaceType('C<B>');
    // List<B> b;
    var listOfB = parseType('List<B>');
    // cOfB.m(b); // infer <B>
    _assertType(
      _inferCall2(cOfB.getMethod('m')!.type, [listOfB]),
      'List<B> Function(List<B>)',
    );
    // cOfA.m(b); // infer <B>
    _assertType(
      _inferCall2(cOfA.getMethod('m')!.type, [listOfB]),
      'List<B> Function(List<B>)',
    );
    // cOfObject.m(b); // infer <B>
    _assertType(
      _inferCall2(cOfObject.getMethod('m')!.type, [listOfB]),
      'List<B> Function(List<B>)',
    );
  }

  void test_boundedRecursively() {
    buildTestLibrary(
      classes: [
        ClassSpec('class Cloneable<T extends Cloneable<T>>'),
        ClassSpec('class B extends Cloneable<B>'),
      ],
    );

    // class Cloneable<T extends Cloneable<T>>

    // class B extends A<B> {}
    var typeB = parseInterfaceType('B');

    // (S, S) -> S
    var clone = parseFunctionType('S Function<S extends Cloneable<S>>(S, S)');
    _assertTypes(_inferCall(clone, [typeB, typeB]), [typeB]);

    // Something invalid...
    _assertTypes(
      _inferCall(clone, [
        parseType('String'),
        parseType('num'),
      ], expectError: true),
      [parseInterfaceType('Cloneable<Object?>')],
    );
  }

  void test_buildTestLibrary_topLevelFunctionHeader() {
    buildTestLibrary(functions: [TopLevelFunctionSpec('T f<T>(T value)')]);

    _assertType(testLibrary.topLevelFunctions.single.type, 'T Function<T>(T)');
  }

  void test_buildTestLibrary_topLevelFunctionHeader_namedParameters() {
    buildTestLibrary(
      functions: [
        TopLevelFunctionSpec('void f({int optional, required int required})'),
      ],
    );

    _assertType(
      testLibrary.topLevelFunctions.single.type,
      'void Function({int optional, required int required})',
    );
  }

  /// https://github.com/dart-lang/language/issues/1182#issuecomment-702272641
  void test_demoteType() {
    // <T>(T x) -> void
    var rawType = parseFunctionType('void Function<T>(T)');

    withTypeParameterScope('S', (scope) {
      var S = scope.typeParameter('S');
      var S_and_int = scope.parseTypeParameterType('S & int');

      var inferredTypes = _inferCall(rawType, [S_and_int]);
      var inferredType = inferredTypes[0] as TypeParameterTypeImpl;
      expect(inferredType.element, S);
      expect(inferredType.promotedBound, isNull);
    });
  }

  void test_genericCastFunction() {
    // <TFrom, TTo>(TFrom) -> TTo
    var cast = parseFunctionType('TTo Function<TFrom, TTo>(TFrom)');
    _assertTypes(_inferCall(cast, [parseType('int')]), [
      parseType('int'),
      parseType('dynamic'),
    ]);
  }

  void test_genericCastFunctionWithUpperBound() {
    // <TFrom, TTo extends TFrom>(TFrom) -> TTo
    var cast = parseFunctionType(
      'TTo Function<TFrom, TTo extends TFrom>(TFrom)',
    );
    _assertTypes(_inferCall(cast, [parseType('int')]), [
      parseType('int'),
      parseType('int'),
    ]);
  }

  void test_parameter_contravariantUseUpperBound() {
    // <T>(T x, void Function(T) y) -> T
    // Generates constraints int <: T <: num.
    // Since T is contravariant, choose num.
    var numFunction = parseFunctionType('void Function(num)');
    var function = parseFunctionType('T Function<in T>(T, void Function(T))');

    _assertTypes(_inferCall(function, [parseType('int'), numFunction]), [
      parseType('num'),
    ]);
  }

  void test_parameter_covariantUseLowerBound() {
    // <T>(T x, void Function(T) y) -> T
    // Generates constraints int <: T <: num.
    // Since T is covariant, choose int.
    var numFunction = parseFunctionType('void Function(num)');
    var function = parseFunctionType('T Function<out T>(T, void Function(T))');

    _assertTypes(_inferCall(function, [parseType('int'), numFunction]), [
      parseType('int'),
    ]);
  }

  void test_parametersToFunctionParam() {
    // <T>(f(T t)) -> T
    var cast = parseFunctionType('T Function<T>(dynamic Function(T))');
    _assertTypes(
      _inferCall(cast, [parseFunctionType('dynamic Function(num)')]),
      [parseType('num')],
    );
  }

  void test_parametersUseLeastUpperBound() {
    // <T>(T x, T y) -> T
    var cast = parseFunctionType('T Function<T>(T, T)');
    _assertTypes(_inferCall(cast, [parseType('int'), parseType('double')]), [
      parseType('num'),
    ]);
  }

  void test_parameterTypeUsesUpperBound() {
    // <T extends num>(T) -> dynamic
    var f = parseFunctionType('dynamic Function<T extends num>(T)');
    _assertTypes(_inferCall(f, [parseType('int')]), [parseType('int')]);
  }

  void test_returnFunctionWithGenericParameter() {
    // <T>(T -> T) -> (T -> void)
    var f = parseFunctionType('void Function(T) Function<T>(T Function(T))');
    _assertTypes(_inferCall(f, [parseFunctionType('int Function(num)')]), [
      parseType('int'),
    ]);
  }

  void test_returnFunctionWithGenericParameterAndContext() {
    // <T>(T -> T) -> (T -> Null)
    var f = parseFunctionType('Null Function(T) Function<T>(T Function(T))');
    _assertTypes(
      _inferCall(f, [], returnType: parseFunctionType('int? Function(num)')),
      [parseType('num')],
    );
  }

  void test_returnFunctionWithGenericParameterAndReturn() {
    // <T>(T -> T) -> (T -> T)
    var f = parseFunctionType('T Function(T) Function<T>(T Function(T))');
    _assertTypes(_inferCall(f, [parseFunctionType('int Function(num)')]), [
      parseType('int'),
    ]);
  }

  void test_returnFunctionWithGenericReturn() {
    // <T>(T -> T) -> (() -> T)
    var f = parseFunctionType('T Function() Function<T>(T Function(T))');
    _assertTypes(_inferCall(f, [parseFunctionType('int Function(num)')]), [
      parseType('int'),
    ]);
  }

  void test_returnTypeFromContext() {
    // <T>() -> T
    var f = parseFunctionType('T Function<T>()');
    _assertTypes(_inferCall(f, [], returnType: parseType('String')), [
      parseType('String'),
    ]);
  }

  void test_returnTypeWithBoundFromContext() {
    // <T extends num>() -> T
    var f = parseFunctionType('T Function<T extends num>()');
    _assertTypes(_inferCall(f, [], returnType: parseType('double')), [
      parseType('double'),
    ]);
  }

  void test_returnTypeWithBoundFromInvalidContext() {
    // <T extends num>() -> T
    var f = parseFunctionType('T Function<T extends num>()');
    _assertTypes(_inferCall(f, [], returnType: parseType('String')), [
      parseType('Never'),
    ]);
  }

  void test_unifyParametersToFunctionParam() {
    // <T>(f(T t), g(T t)) -> T
    var cast = parseFunctionType(
      'T Function<T>(dynamic Function(T), dynamic Function(T))',
    );
    _assertTypes(
      _inferCall(cast, [
        parseFunctionType('dynamic Function(int)'),
        parseFunctionType('dynamic Function(double)'),
      ]),
      [parseType('Never')],
    );
  }

  void test_unusedReturnTypeIsDynamic() {
    // <T>() -> T
    var f = parseFunctionType('T Function<T>()');
    _assertTypes(_inferCall(f, []), [parseType('dynamic')]);
  }

  void test_unusedReturnTypeWithUpperBound() {
    // <T extends num>() -> T
    var f = parseFunctionType('T Function<T extends num>()');
    _assertTypes(_inferCall(f, []), [parseType('num')]);
  }

  void _assertType(DartType type, String expected) {
    var typeStr = type.getDisplayString();
    expect(typeStr, expected);
  }

  void _assertTypes(List<DartType> actual, List<DartType> expected) {
    var actualStr = actual.map((e) {
      return e.getDisplayString();
    }).toList();

    var expectedStr = expected.map((e) {
      return e.getDisplayString();
    }).toList();

    expect(actualStr, expectedStr);
  }

  List<DartType> _inferCall(
    FunctionTypeImpl ft,
    List<TypeImpl> arguments, {
    TypeImpl returnType = UnknownInferredType.instance,
    bool expectError = false,
  }) {
    var listener = RecordingDiagnosticListener();

    var file = newFile('/test.dart', '');
    var fileSource = FileSource(file);
    var reporter = DiagnosticReporter(listener, fileSource);

    var inferrer = typeSystem.setupGenericTypeInference(
      typeParameters: ft.typeParameters,
      declaredReturnType: ft.returnType,
      contextReturnType: returnType,
      diagnosticReporter: reporter,
      errorEntity: NullLiteralImpl(literal: KeywordToken(Keyword.NULL, 0)),
      genericMetadataIsEnabled: true,
      inferenceUsingBoundsIsEnabled: true,
      strictInference: false,
      strictCasts: false,
      typeSystemOperations: typeSystemOperations,
      dataForTesting: null,
      nodeForTesting: null,
    );
    inferrer.constrainArguments2(
      parameters: ft.formalParameters,
      argumentTypes: arguments,
      nodeForTesting: null,
    );
    var typeArguments = inferrer.chooseFinalTypes();

    if (expectError) {
      expect(
        listener.diagnostics.map((e) => e.diagnosticCode).toList(),
        [diag.couldNotInfer],
        reason: 'expected exactly 1 could not infer error.',
      );
    } else {
      expect(
        listener.diagnostics,
        isEmpty,
        reason: 'did not expect any errors.',
      );
    }
    return typeArguments;
  }

  FunctionType _inferCall2(
    FunctionTypeImpl ft,
    List<TypeImpl> arguments, {
    TypeImpl returnType = UnknownInferredType.instance,
    bool expectError = false,
  }) {
    var typeArguments = _inferCall(
      ft,
      arguments,
      returnType: returnType,
      expectError: expectError,
    );
    return ft.instantiate(typeArguments);
  }
}
