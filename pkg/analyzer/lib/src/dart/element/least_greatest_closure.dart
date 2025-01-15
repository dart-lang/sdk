// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/replacement_visitor.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_system.dart';

class LeastGreatestClosureHelper extends ReplacementVisitor {
  final TypeSystemImpl typeSystem;
  final DartType topType;
  final DartType topFunctionType;
  final DartType bottomType;
  final Set<TypeParameterElementImpl2> eliminationTargets;

  late final bool _isLeastClosure;
  bool _isCovariant = true;

  LeastGreatestClosureHelper({
    required this.typeSystem,
    required this.topType,
    required this.topFunctionType,
    required this.bottomType,
    required this.eliminationTargets,
  });

  DartType get _functionReplacement {
    return _isLeastClosure && _isCovariant ||
            (!_isLeastClosure && !_isCovariant)
        ? bottomType
        : topFunctionType;
  }

  DartType get _typeParameterReplacement {
    return _isLeastClosure && _isCovariant ||
            (!_isLeastClosure && !_isCovariant)
        ? bottomType
        : topType;
  }

  @override
  void changeVariance() {
    _isCovariant = !_isCovariant;
  }

  /// Returns a supertype of [type] for all values of [eliminationTargets].
  TypeImpl eliminateToGreatest(DartType type) {
    _isCovariant = true;
    _isLeastClosure = false;
    // TODO(paulberry): make this cast unnecessary by changing the type of
    // `type` and by changing `ReplacementVisitor` to implement
    // `TypeVisitor<TypeImpl?>`.
    return (type.accept(this) ?? type) as TypeImpl;
  }

  /// Returns a subtype of [type] for all values of [eliminationTargets].
  TypeImpl eliminateToLeast(DartType type) {
    _isCovariant = true;
    _isLeastClosure = true;
    // TODO(paulberry): make this cast unnecessary by changing the type of
    // `type` and by changing `ReplacementVisitor` to implement
    // `TypeVisitor<TypeImpl?>`.
    return (type.accept(this) ?? type) as TypeImpl;
  }

  @override
  DartType? visitFunctionType(FunctionType node) {
    // - if `S` is
    //   `T Function<X0 extends B0, ...., Xk extends Bk>(T0 x0, ...., Tn xn,
    //       [Tn+1 xn+1, ..., Tm xm])`
    //   or `T Function<X0 extends B0, ...., Xk extends Bk>(T0 x0, ...., Tn xn,
    //       {Tn+1 xn+1, ..., Tm xm})`
    //   and `L` contains any free type variables from any of the `Bi`:
    //  - The least closure of `S` with respect to `L` is `Never`
    //  - The greatest closure of `S` with respect to `L` is `Function`
    for (var typeParameter in node.typeParameters) {
      if (typeParameter.bound case TypeImpl bound?
          when bound.referencesAny2(eliminationTargets)) {
        return _functionReplacement;
      }
    }

    return super.visitFunctionType(node);
  }

  @override
  DartType? visitTypeParameterType(TypeParameterType type) {
    if (eliminationTargets.contains(type.element3)) {
      var replacement = _typeParameterReplacement as TypeImpl;
      return replacement.withNullability(
        uniteNullabilities(
          replacement.nullabilitySuffix,
          type.nullabilitySuffix,
        ),
      );
    }
    return super.visitTypeParameterType(type);
  }
}

class PatternGreatestClosureHelper extends ReplacementVisitor {
  final TypeImpl topType;
  final TypeImpl bottomType;
  bool _isCovariant = true;

  PatternGreatestClosureHelper({
    required this.topType,
    required this.bottomType,
  });

  @override
  void changeVariance() {
    _isCovariant = !_isCovariant;
  }

  /// Returns a supertype of [type] for all values of type parameters.
  DartType eliminateToGreatest(DartType type) {
    _isCovariant = true;
    return type.accept(this) ?? type;
  }

  @override
  DartType? visitTypeParameterType(TypeParameterType type) {
    var replacement = _isCovariant ? topType : bottomType;
    return replacement.withNullability(
      uniteNullabilities(
        replacement.nullabilitySuffix,
        type.nullabilitySuffix,
      ),
    );
  }
}
