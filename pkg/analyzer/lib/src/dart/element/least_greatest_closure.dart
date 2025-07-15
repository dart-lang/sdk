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
  final TypeImpl topType;
  final TypeImpl topFunctionType;
  final TypeImpl bottomType;
  final Set<TypeParameterElementImpl> eliminationTargets;

  late final bool _isLeastClosure;
  bool _isCovariant = true;

  LeastGreatestClosureHelper({
    required this.typeSystem,
    required this.topType,
    required this.topFunctionType,
    required this.bottomType,
    required this.eliminationTargets,
  });

  TypeImpl get _functionReplacement {
    return _isLeastClosure && _isCovariant ||
            (!_isLeastClosure && !_isCovariant)
        ? bottomType
        : topFunctionType;
  }

  TypeImpl get _typeParameterReplacement {
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
  TypeImpl eliminateToGreatest(TypeImpl type) {
    _isCovariant = true;
    _isLeastClosure = false;
    return type.accept(this) ?? type;
  }

  /// Returns a subtype of [type] for all values of [eliminationTargets].
  TypeImpl eliminateToLeast(TypeImpl type) {
    _isCovariant = true;
    _isLeastClosure = true;
    return type.accept(this) ?? type;
  }

  @override
  TypeImpl? visitFunctionType(FunctionType node) {
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
          when bound.referencesAny(eliminationTargets)) {
        return _functionReplacement;
      }
    }

    return super.visitFunctionType(node);
  }

  @override
  TypeImpl? visitTypeParameterType(TypeParameterType type) {
    if (eliminationTargets.contains(type.element)) {
      var replacement = _typeParameterReplacement;
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
  TypeImpl eliminateToGreatest(TypeImpl type) {
    _isCovariant = true;
    return type.accept(this) ?? type;
  }

  @override
  TypeImpl? visitTypeParameterType(TypeParameterType type) {
    var replacement = _isCovariant ? topType : bottomType;
    return replacement.withNullability(
      uniteNullabilities(replacement.nullabilitySuffix, type.nullabilitySuffix),
    );
  }
}
