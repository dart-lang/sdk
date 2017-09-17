// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:front_end/src/base/instrumentation.dart';
import 'package:front_end/src/fasta/problems.dart';
import 'package:front_end/src/fasta/type_inference/type_inferrer.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';

/// Helper class in charge of propagating covariance bits (isCovariant and
/// isGenericCovariantImpl) through the class hierarchy.
///
/// Handles ordinary method parameters, type parameters, and synthetic
/// parameters associated with the setters of fields.
class CovariancePropagator {
  final ClassHierarchy _classHierarchy;
  final Class _class;
  final Instrumentation _instrumentation;

  CovariancePropagator(
      this._classHierarchy, this._class, this._instrumentation);

  /// Runs the full covariance propagation algorithm for [_class].
  void run() {
    _walkCovarianceTargetPairs();
    // TODO(paulberry): create forwarding stubs
    if (_instrumentation != null) {
      _recordInstrumentation();
    }
  }

  /// Handles a single pair of [_CovarianceTarget]s.
  ///
  /// If the covariance bits can be propagated immediately, they are propagated.
  /// If they can't (because a forwarding stub is needed), they are deferred
  /// until later.
  void _handlePair(
      _CovarianceTarget declaredTarget, _CovarianceTarget interfaceTarget) {
    if (!identical(declaredTarget.containingClass, _class)) {
      // We will have to create a forwarding stub; deal with this pair later.
      // TODO(paulberry): record the pair for easier processing later.
      return;
    }
    _propagateCovariance(declaredTarget, interfaceTarget);
  }

  /// Propagates covariance bits from single parameter represented by
  /// [interfaceTarget] to the parameter represented by [declaredTarget].
  void _propagateCovariance(
      _CovarianceTarget declaredTarget, _CovarianceTarget interfaceTarget) {
    if (interfaceTarget.isExplicitlyCovariant) {
      declaredTarget.makeExplicitlyCovariant();
    }
    if (interfaceTarget.isGenericCovariantImpl) {
      declaredTarget.makeGenericCovariantImpl();
    }
  }

  /// Records the covariance bits for the entire class to [_instrumentation].
  ///
  /// Caller is responsible for checking whether [_instrumentation] is `null`.
  void _recordInstrumentation() {
    var uri = Uri.parse(_class.fileUri);
    void recordCovariance(int fileOffset, bool isExplicitlyCovariant,
        bool isGenericCovariantInterface, bool isGenericCovariantImpl) {
      var covariance = <String>[];
      if (isExplicitlyCovariant) covariance.add('explicit');
      if (isGenericCovariantInterface) covariance.add('genericInterface');
      if (!isExplicitlyCovariant && isGenericCovariantImpl) {
        covariance.add('genericImpl');
      }
      if (covariance.isNotEmpty) {
        _instrumentation.record(uri, fileOffset, 'covariance',
            new InstrumentationValueLiteral(covariance.join(', ')));
      }
    }

    for (var procedure in _class.procedures) {
      if (procedure.isStatic) continue;
      void recordFormalAnnotations(VariableDeclaration formal) {
        recordCovariance(formal.fileOffset, formal.isCovariant,
            formal.isGenericCovariantInterface, formal.isGenericCovariantImpl);
      }

      void recordTypeParameterAnnotations(TypeParameter typeParameter) {
        recordCovariance(
            typeParameter.fileOffset,
            false,
            typeParameter.isGenericCovariantInterface,
            typeParameter.isGenericCovariantImpl);
      }

      procedure.function.positionalParameters.forEach(recordFormalAnnotations);
      procedure.function.namedParameters.forEach(recordFormalAnnotations);
      procedure.function.typeParameters.forEach(recordTypeParameterAnnotations);
    }
    for (var field in _class.fields) {
      if (field.isStatic) continue;
      recordCovariance(field.fileOffset, field.isCovariant,
          field.isGenericCovariantInterface, field.isGenericCovariantImpl);
    }
  }

  /// Creates the appropriate [_CovarianceTarget] for [member], which is either
  /// a setter or a field.
  _CovarianceTarget _targetForSetter(Member member) {
    if (member is Field) {
      return new _FieldCovarianceTarget(member);
    }
    if (member is Procedure) {
      var positionalParameters = member.function.positionalParameters;
      if (positionalParameters.length >= 1) {
        return new _ParameterCovarianceTarget(positionalParameters[0]);
      }
    }
    // Can only happen if the user's code was erroneous; return `null` to
    // trigger error recovery.
    return null;
  }

  /// Finds all of the pairs of [_CovarianceTarget]s for which covariance bits
  /// need to be propagated, and takes appopriate action.
  ///
  /// If the covariance bits can be propagated immediately, they are propagated.
  /// If they can't (because a forwarding stub is needed), they are deferred
  /// until later.
  void _walkCovarianceTargetPairs() {
    _classHierarchy.forEachOverridePair(_class,
        (declaredMember, interfaceMember, isSetter) {
      // Match up parameters between the declared and interface members, and
      // send the pairs to [walkPair].
      if (isSetter) {
        var declaredTarget = _targetForSetter(declaredMember);
        var interfaceTarget = _targetForSetter(interfaceMember);
        if (declaredTarget != null && interfaceTarget != null) {
          _handlePair(declaredTarget, interfaceTarget);
        }
      } else if (declaredMember is Procedure && interfaceMember is Procedure) {
        var declaredFunction = declaredMember.function;
        var interfaceFunction = interfaceMember.function;
        var declaredPositionalParameters =
            declaredFunction.positionalParameters;
        var interfacePositionalParameters =
            interfaceFunction.positionalParameters;
        for (int i = 0;
            i < declaredPositionalParameters.length &&
                i < interfacePositionalParameters.length;
            i++) {
          _handlePair(
              new _ParameterCovarianceTarget(declaredPositionalParameters[i]),
              new _ParameterCovarianceTarget(interfacePositionalParameters[i]));
        }
        for (var namedParameter in declaredFunction.namedParameters) {
          var overriddenParameter =
              getNamedFormal(interfaceFunction, namedParameter.name);
          if (overriddenParameter != null) {
            _handlePair(new _ParameterCovarianceTarget(namedParameter),
                new _ParameterCovarianceTarget(overriddenParameter));
          }
        }
        var declaredTypeParameters = declaredFunction.typeParameters;
        var interfaceTypeParameters = interfaceFunction.typeParameters;
        for (int i = 0;
            i < declaredTypeParameters.length &&
                i < interfaceTypeParameters.length;
            i++) {
          _handlePair(
              new _TypeParameterCovarianceTarget(declaredTypeParameters[i]),
              new _TypeParameterCovarianceTarget(interfaceTypeParameters[i]));
        }
      } else {
        // If we reach here, then either the declaredMember or the
        // interfaceMember is a getter, so there are no parameters to match up.
      }
    });
  }
}

/// Base class representing a thing that can record covariance information.
///
/// This might be an ordinary method parameter, a type parameter, or a field.
/// (In the case of a field, it records covariance information about the value
/// parameter of the field's implicit setter).
abstract class _CovarianceTarget {
  Class get containingClass;

  bool get isExplicitlyCovariant;

  bool get isGenericCovariantImpl;

  void makeExplicitlyCovariant();

  void makeGenericCovariantImpl();
}

/// [_CovarianceTarget] representing a field.
class _FieldCovarianceTarget extends _CovarianceTarget {
  final Field field;

  _FieldCovarianceTarget(this.field);

  @override
  Class get containingClass => field.parent;

  @override
  bool get isExplicitlyCovariant => field.isCovariant;

  @override
  bool get isGenericCovariantImpl => field.isGenericCovariantImpl;

  @override
  void makeExplicitlyCovariant() {
    field.isCovariant = true;
  }

  @override
  void makeGenericCovariantImpl() {
    field.isGenericCovariantImpl = true;
  }
}

/// [_CovarianceTarget] representing an ordinary method parameter.
class _ParameterCovarianceTarget extends _CovarianceTarget {
  final VariableDeclaration parameter;

  _ParameterCovarianceTarget(this.parameter);

  @override
  Class get containingClass => parameter.parent.parent.parent;

  @override
  bool get isExplicitlyCovariant => parameter.isCovariant;

  @override
  bool get isGenericCovariantImpl => parameter.isGenericCovariantImpl;

  @override
  void makeExplicitlyCovariant() {
    parameter.isCovariant = true;
  }

  @override
  void makeGenericCovariantImpl() {
    parameter.isGenericCovariantImpl = true;
  }
}

/// [_CovarianceTarget] representing a generic method's type parameter.
class _TypeParameterCovarianceTarget extends _CovarianceTarget {
  final TypeParameter typeParameter;

  _TypeParameterCovarianceTarget(this.typeParameter);

  @override
  Class get containingClass => typeParameter.parent.parent.parent;

  @override
  bool get isExplicitlyCovariant {
    // Type parameters can't be explicitly covariant.
    return false;
  }

  @override
  bool get isGenericCovariantImpl => typeParameter.isGenericCovariantImpl;

  @override
  void makeExplicitlyCovariant() {
    // Type parameters can't be explicitly covariant.  Since we only propagate
    // covariance from type parameters to other type parameters, this method
    // should never be called.
    unhandled('makeExplicitlyCovariant', typeParameter.toString(), -1, null);
  }

  @override
  void makeGenericCovariantImpl() {
    typeParameter.isGenericCovariantImpl = true;
  }
}
