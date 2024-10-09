// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/type_inference/nullability_suffix.dart';
import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer_operations.dart';
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';

import '../mini_ast.dart';
import '../mini_types.dart';

main() {
  setUp(() {
    TypeRegistry.init();
    TypeRegistry.addInterfaceTypeName('Contravariant');
    TypeRegistry.addInterfaceTypeName('Invariant');
    TypeRegistry.addInterfaceTypeName('MyListOfInt');
    TypeRegistry.addInterfaceTypeName('Unrelated');
  });

  tearDown(() {
    TypeRegistry.uninit();
  });

  group('performSubtypeConstraintGenerationForFunctionTypes:', () {
    test('Matching functions with no parameters', () {
      var tcg = _TypeConstraintGatherer({});
      check(tcg.performSubtypeConstraintGenerationForFunctionTypes(
              Type('void Function()'), Type('void Function()'),
              leftSchema: false, astNodeForTesting: Node.placeholder()))
          .equals(true);
      check(tcg._constraints).isEmpty();
    });

    group('Matching functions with positional parameters:', () {
      test('None optional', () {
        var tcg = _TypeConstraintGatherer({'T', 'U'});
        check(tcg.performSubtypeConstraintGenerationForFunctionTypes(
                Type('void Function(int, String)'), Type('void Function(T, U)'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .equals(true);
        check(tcg._constraints).unorderedEquals(['T <: int', 'U <: String']);
      });

      test('Some optional on LHS', () {
        var tcg = _TypeConstraintGatherer({'T', 'U'});
        check(tcg.performSubtypeConstraintGenerationForFunctionTypes(
                Type('void Function(int, [String])'),
                Type('void Function(T, U)'),
                leftSchema: false,
                astNodeForTesting: Node.placeholder()))
            .equals(true);
        check(tcg._constraints).unorderedEquals(['T <: int', 'U <: String']);
      });
    });

    group('Non-matching functions with positional parameters:', () {
      test('Non-matching due to return types', () {
        var tcg = _TypeConstraintGatherer({});
        check(tcg.performSubtypeConstraintGenerationForFunctionTypes(
                Type('int Function(int)'), Type('String Function(int)'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .isFalse();
        check(tcg._constraints).isEmpty();
      });

      test('Non-matching due to parameter types', () {
        var tcg = _TypeConstraintGatherer({});
        check(tcg.performSubtypeConstraintGenerationForFunctionTypes(
                Type('void Function(int)'), Type('void Function(String)'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .isFalse();
        check(tcg._constraints).isEmpty();
      });

      test('Non-matching due to optional parameters on RHS', () {
        var tcg = _TypeConstraintGatherer({});
        check(tcg.performSubtypeConstraintGenerationForFunctionTypes(
                Type('void Function()'), Type('void Function([int])'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .isFalse();
        check(tcg._constraints).isEmpty();
      });

      test('Non-matching due to more parameters being required on LHS', () {
        var tcg = _TypeConstraintGatherer({});
        check(tcg.performSubtypeConstraintGenerationForFunctionTypes(
                Type('void Function(int)'), Type('void Function([int])'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .isFalse();
        check(tcg._constraints).isEmpty();
      });
    });

    group('Matching functions with named parameters:', () {
      test('None optional', () {
        var tcg = _TypeConstraintGatherer({'T', 'U'});
        check(tcg.performSubtypeConstraintGenerationForFunctionTypes(
                Type('void Function({required int x, required String y})'),
                Type('void Function({required T x, required U y})'),
                leftSchema: false,
                astNodeForTesting: Node.placeholder()))
            .equals(true);
        check(tcg._constraints).unorderedEquals(['T <: int', 'U <: String']);
      });

      test('Some optional on LHS', () {
        var tcg = _TypeConstraintGatherer({'T', 'U'});
        check(tcg.performSubtypeConstraintGenerationForFunctionTypes(
                Type('void Function({required int x, String y})'),
                Type('void Function({required T x, required U y})'),
                leftSchema: false,
                astNodeForTesting: Node.placeholder()))
            .equals(true);
        check(tcg._constraints).unorderedEquals(['T <: int', 'U <: String']);
      });

      test('Optional named parameter on LHS', () {
        var tcg = _TypeConstraintGatherer({'T'});
        check(tcg.performSubtypeConstraintGenerationForFunctionTypes(
                Type('void Function(int, {String x})'),
                Type('void Function(T)'),
                leftSchema: false,
                astNodeForTesting: Node.placeholder()))
            .equals(true);
        check(tcg._constraints).unorderedEquals(['T <: int']);
      });

      test('Extra optional named parameter on LHS', () {
        var tcg = _TypeConstraintGatherer({'T'});
        check(tcg.performSubtypeConstraintGenerationForFunctionTypes(
                Type('void Function({String x, int y})'),
                Type('void Function({T y})'),
                leftSchema: false,
                astNodeForTesting: Node.placeholder()))
            .equals(true);
        check(tcg._constraints).unorderedEquals(['T <: int']);
      });
    });

    group('Non-matching functions with named parameters:', () {
      test('Non-matching due to return types', () {
        var tcg = _TypeConstraintGatherer({});
        check(tcg.performSubtypeConstraintGenerationForFunctionTypes(
                Type('int Function({int x})'), Type('String Function({int x})'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .isFalse();
        check(tcg._constraints).isEmpty();
      });

      test('Non-matching due to named parameter types', () {
        var tcg = _TypeConstraintGatherer({});
        check(tcg.performSubtypeConstraintGenerationForFunctionTypes(
                Type('void Function({int x})'),
                Type('void Function({String x})'),
                leftSchema: false,
                astNodeForTesting: Node.placeholder()))
            .isFalse();
        check(tcg._constraints).isEmpty();
      });

      test('Non-matching due to required named parameter on LHS', () {
        var tcg = _TypeConstraintGatherer({});
        check(tcg.performSubtypeConstraintGenerationForFunctionTypes(
                Type('void Function({required int x})'),
                Type('void Function()'),
                leftSchema: false,
                astNodeForTesting: Node.placeholder()))
            .isFalse();
        check(tcg._constraints).isEmpty();
      });

      test('Non-matching due to optional named parameter on RHS', () {
        var tcg = _TypeConstraintGatherer({});
        check(tcg.performSubtypeConstraintGenerationForFunctionTypes(
                Type('void Function()'), Type('void Function({int x})'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .isFalse();
        check(tcg._constraints).isEmpty();
      });

      test('Non-matching due to named parameter on RHS, with decoys on LHS',
          () {
        var tcg = _TypeConstraintGatherer({});
        check(tcg.performSubtypeConstraintGenerationForFunctionTypes(
                Type('void Function({int x, int y})'),
                Type('void Function({int z})'),
                leftSchema: false,
                astNodeForTesting: Node.placeholder()))
            .isFalse();
        check(tcg._constraints).isEmpty();
      });
    });

    test('Matching functions with named and positional parameters', () {
      var tcg = _TypeConstraintGatherer({'T', 'U'});
      check(tcg.performSubtypeConstraintGenerationForFunctionTypes(
              Type('void Function(int, {String y})'),
              Type('void Function(T, {U y})'),
              leftSchema: false,
              astNodeForTesting: Node.placeholder()))
          .equals(true);
      check(tcg._constraints).unorderedEquals(['T <: int', 'U <: String']);
    });

    group('Non-matching functions with named and positional parameters:', () {
      test(
          'Non-matching due to LHS not accepting optional positional parameter',
          () {
        var tcg = _TypeConstraintGatherer({});
        check(tcg.performSubtypeConstraintGenerationForFunctionTypes(
                Type('void Function(int, {String x})'),
                Type('void Function(int, [String])'),
                leftSchema: false,
                astNodeForTesting: Node.placeholder()))
            .isFalse();
        check(tcg._constraints).isEmpty();
      });

      test('Non-matching due to positional parameter length mismatch', () {
        var tcg = _TypeConstraintGatherer({});
        check(tcg.performSubtypeConstraintGenerationForFunctionTypes(
                Type('void Function(int, {String x})'),
                Type('void Function(int, String)'),
                leftSchema: false,
                astNodeForTesting: Node.placeholder()))
            .isFalse();
        check(tcg._constraints).isEmpty();
      });
    });
  });

  group('performSubtypeConstraintGenerationForFutureOr:', () {
    test('FutureOr matches FutureOr with constraints based on arguments', () {
      // `FutureOr<T> <# FutureOr<int>` reduces to `T <# int`
      var tcg = _TypeConstraintGatherer({'T'});
      check(tcg.performSubtypeConstraintGenerationForFutureOr(
              Type('FutureOr<T>'), Type('FutureOr<int>'),
              leftSchema: false, astNodeForTesting: Node.placeholder()))
          .isTrue();
      check(tcg._constraints).deepEquals(['T <: int']);
    });

    test('FutureOr does not match FutureOr because arguments fail to match',
        () {
      // `FutureOr<int> <# FutureOr<String>` reduces to `int <# String`
      var tcg = _TypeConstraintGatherer({});
      check(tcg.performSubtypeConstraintGenerationForFutureOr(
              Type('FutureOr<int>'), Type('FutureOr<String>'),
              leftSchema: false, astNodeForTesting: Node.placeholder()))
          .isFalse();
      check(tcg._constraints).isEmpty();
    });

    test('Future matches FutureOr favoring Future branch', () {
      // `Future<int> <# FutureOr<T>` could match in two possible ways:
      // - `Future<int> <# Future<T>` (taking the "Future" branch of the
      //   FutureOr), producing `int <: T`
      // - `Future<int> <# T` (taking the "non-Future" branch of the FutureOr),
      //   producing `Future<int> <: T`
      // In cases where both branches produce a constraint, the "Future" branch
      // is favored.
      var tcg = _TypeConstraintGatherer({'T'});
      check(tcg.performSubtypeConstraintGenerationForFutureOr(
              Type('Future<int>'), Type('FutureOr<T>'),
              leftSchema: false, astNodeForTesting: Node.placeholder()))
          .isTrue();
      check(tcg._constraints).deepEquals(['int <: T']);
    });

    test('Future matches FutureOr preferring to generate constraints', () {
      // `Future<_> <# FutureOr<T>` could match in two possible ways:
      // - `Future<_> <# Future<T>` (taking the "Future" branch of the
      //   FutureOr), producing no constraints
      // - `Future<_> <# T` (taking the "non-Future" branch of the FutureOr),
      //   producing `Future<_> <: T`
      // In cases where only one branch produces a constraint, that branch is
      // favored.
      var tcg = _TypeConstraintGatherer({'T'});
      check(tcg.performSubtypeConstraintGenerationForFutureOr(
              Type('Future<_>'), Type('FutureOr<T>'),
              leftSchema: true, astNodeForTesting: Node.placeholder()))
          .isTrue();
      check(tcg._constraints).deepEquals(['Future<_> <: T']);
    });

    test('Type matches FutureOr favoring the Future branch', () {
      // `T <# FutureOr<int>` could match in two possible ways:
      // - `T <# Future<int>` (taking the "Future" branch of the FutureOr),
      //   producing `T <: Future<int>`
      // - `T <# int` (taking the "non-Future" branch of the FutureOr),
      //   producing `T <: int`
      // In cases where both branches produce a constraint, the "Future" branch
      // is favored.
      var tcg = _TypeConstraintGatherer({'T'});
      check(tcg.performSubtypeConstraintGenerationForFutureOr(
              Type('T'), Type('FutureOr<int>'),
              leftSchema: false, astNodeForTesting: Node.placeholder()))
          .isTrue();
      check(tcg._constraints).deepEquals(['T <: Future<int>']);
    });

    test('Future matches FutureOr with no constraints', () {
      // `Future<int> <# FutureOr<int>` matches (taking the "Future" branch of
      // the FutureOr) without generating any constraints.
      var tcg = _TypeConstraintGatherer({});
      check(tcg.performSubtypeConstraintGenerationForFutureOr(
              Type('Future<int>'), Type('FutureOr<int>'),
              leftSchema: false, astNodeForTesting: Node.placeholder()))
          .isTrue();
      check(tcg._constraints).isEmpty();
    });

    test('Type matches FutureOr favoring the branch that matches', () {
      // `List<T> <# FutureOr<List<int>>` could only match by taking the
      // "non-Future" branch of the FutureOr, so the constraint `T <: int` is
      // produced.
      var tcg = _TypeConstraintGatherer({'T'});
      check(tcg.performSubtypeConstraintGenerationForFutureOr(
              Type('List<T>'), Type('FutureOr<List<int>>'),
              leftSchema: false, astNodeForTesting: Node.placeholder()))
          .isTrue();
      check(tcg._constraints).deepEquals(['T <: int']);
    });

    group('Nullable FutureOr on RHS:', () {
      test('Does not match, according to spec', () {
        var tcg = _TypeConstraintGatherer({'T'});
        check(tcg.performSubtypeConstraintGenerationForFutureOr(
                Type('FutureOr<T>'), Type('FutureOr<int>?'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .isFalse();
        check(tcg._constraints).isEmpty();
      });

      test('Matches, according to CFE discrepancy', () {
        var tcg = _TypeConstraintGatherer({'T'},
            enableDiscrepantObliviousnessOfNullabilitySuffixOfFutureOr: true);
        check(tcg.performSubtypeConstraintGenerationForFutureOr(
                Type('FutureOr<T>'), Type('FutureOr<int>?'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .isTrue();
        check(tcg._constraints).deepEquals(['T <: int']);
      });
    });

    group('Nullable FutureOr on LHS:', () {
      test('Does not match, according to spec', () {
        var tcg = _TypeConstraintGatherer({'T'});
        check(tcg.performSubtypeConstraintGenerationForFutureOr(
                Type('FutureOr<T>?'), Type('FutureOr<int>'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .isFalse();
        check(tcg._constraints).isEmpty();
      });

      test('Matches, according to CFE discrepancy', () {
        var tcg = _TypeConstraintGatherer({'T'},
            enableDiscrepantObliviousnessOfNullabilitySuffixOfFutureOr: true);
        check(tcg.performSubtypeConstraintGenerationForFutureOr(
                Type('FutureOr<T>?'), Type('FutureOr<int>'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .isTrue();
        check(tcg._constraints).deepEquals(['T <: int']);
      });
    });
  });

  group('performSubtypeConstraintGenerationForTypeDeclarationTypes', () {
    group('Same base type on both sides:', () {
      test('Covariant, matching', () {
        var tcg = _TypeConstraintGatherer({'T', 'U'});
        check(tcg.performSubtypeConstraintGenerationForTypeDeclarationTypes(
                Type('Map<T, U>'), Type('Map<int, String>'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .equals(true);
        check(tcg._constraints).unorderedEquals(['T <: int', 'U <: String']);
      });

      test('Covariant, not matching', () {
        var tcg = _TypeConstraintGatherer({'T'});
        check(tcg.performSubtypeConstraintGenerationForTypeDeclarationTypes(
                Type('Map<T, int>'), Type('Map<int, String>'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .equals(false);
        check(tcg._constraints).isEmpty();
      });

      test('Contravariant, matching', () {
        var tcg = _TypeConstraintGatherer({'T', 'U'});
        tcg.typeAnalyzerOperations.addVariance(
            'Contravariant', [Variance.contravariant, Variance.contravariant]);
        check(tcg.performSubtypeConstraintGenerationForTypeDeclarationTypes(
                Type('Contravariant<T, U>'), Type('Contravariant<int, String>'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .equals(true);
        check(tcg._constraints).unorderedEquals(['int <: T', 'String <: U']);
      });

      test('Contravariant, not matching', () {
        var tcg = _TypeConstraintGatherer({'T'});
        tcg.typeAnalyzerOperations.addVariance(
            'Contravariant', [Variance.contravariant, Variance.contravariant]);
        check(tcg.performSubtypeConstraintGenerationForTypeDeclarationTypes(
                Type('Contravariant<T, int>'),
                Type('Contravariant<int, String>'),
                leftSchema: false,
                astNodeForTesting: Node.placeholder()))
            .equals(false);
        check(tcg._constraints).isEmpty();
      });

      test('Invariant, matching', () {
        var tcg = _TypeConstraintGatherer({'T', 'U'});
        tcg.typeAnalyzerOperations
            .addVariance('Invariant', [Variance.invariant, Variance.invariant]);
        check(tcg.performSubtypeConstraintGenerationForTypeDeclarationTypes(
                Type('Invariant<T, U>'), Type('Invariant<int, String>'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .equals(true);
        check(tcg._constraints).unorderedEquals(
            ['T <: int', 'U <: String', 'int <: T', 'String <: U']);
      });

      test('Invariant, not matching', () {
        var tcg = _TypeConstraintGatherer({'T'});
        tcg.typeAnalyzerOperations
            .addVariance('Invariant', [Variance.invariant, Variance.invariant]);
        check(tcg.performSubtypeConstraintGenerationForTypeDeclarationTypes(
                Type('Invariant<T, int>'), Type('Invariant<int, String>'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .equals(false);
        check(tcg._constraints).isEmpty();
      });

      test('Unrelated, matchable', () {
        // When the variance is "unrelated", type inference doesn't even try to
        // match up the type parameters; they are always considered to match.
        var tcg = _TypeConstraintGatherer({'T', 'U'});
        tcg.typeAnalyzerOperations
            .addVariance('Unrelated', [Variance.unrelated, Variance.unrelated]);
        check(tcg.performSubtypeConstraintGenerationForTypeDeclarationTypes(
                Type('Unrelated<T, U>'), Type('Unrelated<int, String>'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .equals(true);
        check(tcg._constraints).isEmpty();
      });

      test('Unrelated, not matchable', () {
        // When the variance is "unrelated", type inference doesn't even try to
        // match up the type parameters; they are always considered to match.
        var tcg = _TypeConstraintGatherer({'T'});
        tcg.typeAnalyzerOperations
            .addVariance('Unrelated', [Variance.unrelated, Variance.unrelated]);
        check(tcg.performSubtypeConstraintGenerationForTypeDeclarationTypes(
                Type('Unrelated<T, int>'), Type('Unrelated<int, String>'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .equals(true);
        check(tcg._constraints).isEmpty();
      });
    });

    group('Related types on both sides:', () {
      test('No change in type args', () {
        var tcg = _TypeConstraintGatherer({'T'});
        check(tcg.performSubtypeConstraintGenerationForTypeDeclarationTypes(
                Type('List<T>'), Type('Iterable<int>'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .equals(true);
        check(tcg._constraints).deepEquals(['T <: int']);
      });

      test('Change in type args', () {
        var tcg = _TypeConstraintGatherer({'T'});
        check(tcg.performSubtypeConstraintGenerationForTypeDeclarationTypes(
                Type('MyListOfInt'), Type('List<T>'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .equals(true);
        check(tcg._constraints).deepEquals(['int <: T']);
      });

      test('LHS nullable', () {
        // When the LHS is a nullable type,
        // performSubtypeConstraintGenerationForTypeDeclarationTypes considers
        // it not to match (this is handled by other parts of the subtyping
        // algorithm)
        var tcg = _TypeConstraintGatherer({'T'});
        check(tcg.performSubtypeConstraintGenerationForTypeDeclarationTypes(
                Type('List<T>?'), Type('Iterable<int>'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .equals(false);
        check(tcg._constraints).isEmpty();
      });

      test('RHS nullable', () {
        // When the RHS is a nullable type,
        // performSubtypeConstraintGenerationForTypeDeclarationTypes considers
        // it not to match (this is handled by other parts of the subtyping
        // algorithm)
        var tcg = _TypeConstraintGatherer({'T'});
        check(tcg.performSubtypeConstraintGenerationForTypeDeclarationTypes(
                Type('List<T>'), Type('Iterable<int>?'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .equals(false);
        check(tcg._constraints).isEmpty();
      });
    });

    test('Non-interface type on LHS', () {
      var tcg = _TypeConstraintGatherer({});
      check(tcg.performSubtypeConstraintGenerationForTypeDeclarationTypes(
              Type('void Function()'), Type('int'),
              leftSchema: false, astNodeForTesting: Node.placeholder()))
          .isNull();
      check(tcg._constraints).isEmpty();
    });

    test('Non-interface type on RHS', () {
      var tcg = _TypeConstraintGatherer({});
      check(tcg.performSubtypeConstraintGenerationForTypeDeclarationTypes(
              Type('int'), Type('void Function()'),
              leftSchema: false, astNodeForTesting: Node.placeholder()))
          .isNull();
      check(tcg._constraints).isEmpty();
    });
  });
}

class _TypeConstraintGatherer extends TypeConstraintGenerator<Type,
        NamedFunctionParameter, Var, TypeParameter, Type, String, Node>
    with
        TypeConstraintGeneratorMixin<Type, NamedFunctionParameter, Var,
            TypeParameter, Type, String, Node> {
  final _typeVariablesBeingConstrained = <TypeParameter>{};

  @override
  final bool enableDiscrepantObliviousnessOfNullabilitySuffixOfFutureOr;

  @override
  final MiniAstOperations typeAnalyzerOperations = MiniAstOperations();

  final _constraints = <String>[];

  _TypeConstraintGatherer(Set<String> typeVariablesBeingConstrained,
      {this.enableDiscrepantObliviousnessOfNullabilitySuffixOfFutureOr =
          false}) {
    for (var typeVariableName in typeVariablesBeingConstrained) {
      _typeVariablesBeingConstrained
          .add(TypeRegistry.addTypeParameter(typeVariableName));
    }
  }

  @override
  TypeConstraintGeneratorState get currentState =>
      TypeConstraintGeneratorState(_constraints.length);

  @override
  List<Type>? getTypeArgumentsAsInstanceOf(Type type, String typeDeclaration) {
    // We just have a few cases hardcoded here to make the tests work.
    // TODO(paulberry): if this gets too unwieldy, replace it with a more
    // general implementation.
    switch ((type, typeDeclaration)) {
      case (PrimaryType(name: 'List', :var args), 'Iterable'):
        // List<T> inherits from Iterable<T>
        return args;
      case (PrimaryType(name: 'MyListOfInt'), 'List'):
        // MyListOfInt inherits from List<int>
        return [Type('int')];
      case (PrimaryType(name: 'Future'), 'int'):
      case (PrimaryType(name: 'int'), 'String'):
      case (PrimaryType(name: 'List'), 'Future'):
      case (PrimaryType(name: 'String'), 'int'):
        // Unrelated types
        return null;
      default:
        throw UnimplementedError(
            'getTypeArgumentsAsInstanceOf($type, $typeDeclaration)');
    }
  }

  @override
  bool performSubtypeConstraintGenerationInternal(Type p, Type q,
      {required bool leftSchema, required Node? astNodeForTesting}) {
    // If `P` is `_` then the match holds with no constraints.
    if (p is SharedUnknownTypeStructure) {
      return true;
    }

    // If `Q` is `_` then the match holds with no constraints.
    if (q is SharedUnknownTypeStructure) {
      return true;
    }

    // If T is a type variable being constrained, then `T <# Q` matches,
    // generating the constraint `T <: Q`.
    if (typeAnalyzerOperations.matchInferableParameter(SharedTypeView(p))
        case var typeVar?
        when p.nullabilitySuffix == NullabilitySuffix.none &&
            _typeVariablesBeingConstrained.contains(typeVar)) {
      _constraints.add('$typeVar <: $q');
      return true;
    }

    // If T is a type variable being constrained, then `P <# T` matches,
    // generating the constraint `P <: T`.
    if (typeAnalyzerOperations.matchInferableParameter(SharedTypeView(q))
        case var typeVar?
        when q.nullabilitySuffix == NullabilitySuffix.none &&
            _typeVariablesBeingConstrained.contains(typeVar)) {
      _constraints.add('$p <: $typeVar');
      return true;
    }

    // If `P` and `Q` are identical types, then the subtype match holds
    // under no constraints.
    if (p == q) {
      return true;
    }

    bool? result = performSubtypeConstraintGenerationForTypeDeclarationTypes(
        p, q,
        leftSchema: leftSchema, astNodeForTesting: astNodeForTesting);
    if (result != null) {
      return result;
    }

    // Assume for the moment that nothing else matches.
    // TODO(paulberry): expand this as needed.
    return false;
  }

  @override
  void restoreState(TypeConstraintGeneratorState state) {
    _constraints.length = state.count;
  }
}
