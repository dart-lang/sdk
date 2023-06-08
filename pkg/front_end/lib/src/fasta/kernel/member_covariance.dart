// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:kernel/ast.dart';

/// Class that holds the covariant and generic-covariant-impl information for
/// a member.
// TODO(johnniwinther): Cache this in ClassMember.
// TODO(johnniwinther): Maybe compact initial positional masks into a single
//  int.
class Covariance {
  static const int GenericCovariantImpl = 1;
  static const int Covariant = 2;

  /// Returns the covariance mask for [parameter].
  static int covarianceFromParameter(VariableDeclaration parameter) =>
      (parameter.isCovariantByDeclaration ? Covariant : 0) |
      (parameter.isCovariantByClass ? GenericCovariantImpl : 0);

  /// Returns the covariance mask for [field].
  static int covarianceFromField(Field field) =>
      (field.isCovariantByDeclaration ? Covariant : 0) |
      (field.isCovariantByClass ? GenericCovariantImpl : 0);

  /// Applies the [covariance] mask to [parameter].
  static void covarianceToParameter(
      int covariance, VariableDeclaration parameter) {
    if ((covariance & Covariant) != 0) {
      parameter.isCovariantByDeclaration = true;
    }
    if ((covariance & GenericCovariantImpl) != 0) {
      parameter.isCovariantByClass = true;
    }
  }

  /// Applies the [covariance] mask to parameter.
  static void covarianceToField(int covariance, Field field) {
    if ((covariance & Covariant) != 0) {
      field.isCovariantByDeclaration = true;
    }
    if ((covariance & GenericCovariantImpl) != 0) {
      field.isCovariantByClass = true;
    }
  }

  /// The covariance mask for the positional parameters.
  ///
  /// If no positional parameters have covariance, this is `null`.
  final List<int>? _positionalParameters;

  /// The covariance mask for the named parameters with name covariance.
  ///
  /// If no named parameters have covariance, this is `null`.
  final Map<String, int>? _namedParameters;

  /// The generic-covariant-impl state for the type parameters.
  ///
  /// If no type parameters are generic-covariant-impl, this is `null`.
  final List<bool>? _typeParameters;

  Covariance.internal(
      this._positionalParameters, this._namedParameters, this._typeParameters) {
    assert(_positionalParameters == null ||
        _positionalParameters!.any((element) => element != 0));
    assert(_namedParameters == null ||
        _namedParameters!.values.isNotEmpty &&
            _namedParameters!.values.every((element) => element != 0));
    assert(
        _typeParameters == null || _typeParameters!.any((element) => element));
  }

  /// The empty covariance.
  ///
  /// This is used for all members that do not use any covariance, regardless
  /// of parameter structure.
  const Covariance.empty()
      : _positionalParameters = null,
        _namedParameters = null,
        _typeParameters = null;

  /// Computes the covariance for the setter aspect of [field].
  ///
  /// The getter aspect of a field never uses covariance.
  factory Covariance.fromField(Field field) {
    int covariance = covarianceFromField(field);
    if (covariance == 0) {
      return const Covariance.empty();
    }
    return new Covariance.internal(<int>[covariance], null, null);
  }

  /// Computes the covariance for the [setter].
  factory Covariance.fromSetter(Procedure setter) {
    int covariance =
        covarianceFromParameter(setter.function.positionalParameters.first);
    if (covariance == 0) {
      return const Covariance.empty();
    }
    return new Covariance.internal(<int>[covariance], null, null);
  }

  /// Computes the covariance for the [procedure].
  factory Covariance.fromMethod(Procedure procedure) {
    FunctionNode function = procedure.function;
    List<int>? positionalParameters;
    if (function.positionalParameters.isNotEmpty) {
      for (int index = 0;
          index < function.positionalParameters.length;
          index++) {
        int covariance =
            covarianceFromParameter(function.positionalParameters[index]);
        if (covariance != 0) {
          positionalParameters ??=
              new List<int>.filled(function.positionalParameters.length, 0);
          positionalParameters[index] = covariance;
        }
      }
    }
    Map<String, int>? namedParameters;
    if (function.namedParameters.isNotEmpty) {
      for (int index = 0; index < function.namedParameters.length; index++) {
        VariableDeclaration parameter = function.namedParameters[index];
        int covariance = covarianceFromParameter(parameter);
        if (covariance != 0) {
          namedParameters ??= {};
          namedParameters[parameter.name!] = covariance;
        }
      }
    }
    List<bool>? typeParameters;
    if (function.typeParameters.isNotEmpty) {
      for (int index = 0; index < function.typeParameters.length; index++) {
        if (function.typeParameters[index].isCovariantByClass) {
          typeParameters ??=
              new List<bool>.filled(function.typeParameters.length, false);
          typeParameters[index] = true;
        }
      }
    }
    if (positionalParameters == null &&
        namedParameters == null &&
        typeParameters == null) {
      return const Covariance.empty();
    }
    return new Covariance.internal(
        positionalParameters, namedParameters, typeParameters);
  }

  /// Computes the covariance for [member].
  ///
  /// If [forSetter] is `true`, the covariance is computed for the setter
  /// aspect of [member]. Otherwise, the covariance for the getter/method aspect
  /// of [member] is computed.
  factory Covariance.fromMember(Member member, {required bool forSetter}) {
    if (member is Procedure) {
      if (member.kind == ProcedureKind.Getter) {
        return const Covariance.empty();
      } else if (member.kind == ProcedureKind.Setter) {
        return new Covariance.fromSetter(member);
      } else {
        return new Covariance.fromMethod(member);
      }
    } else if (member is Field) {
      if (forSetter) {
        return new Covariance.fromField(member);
      } else {
        return const Covariance.empty();
      }
    } else {
      throw new UnsupportedError(
          "Unexpected member $member (${member.runtimeType})");
    }
  }

  /// Returns `true` if this is the empty covariance.
  bool get isEmpty =>
      _positionalParameters == null &&
      _namedParameters == null &&
      _typeParameters == null;

  /// Returns the covariance mask for the [index]th positional parameter.
  int getPositionalVariance(int index) {
    List<int>? positionalParameters = _positionalParameters;
    return positionalParameters != null && index < positionalParameters.length
        ? positionalParameters[index]
        : 0;
  }

  /// Returns the covariance mask for the named parameter with the [name].
  int getNamedVariance(String name) {
    Map<String, int>? namedParameters = _namedParameters;
    return namedParameters != null ? (namedParameters[name] ?? 0) : 0;
  }

  /// Returns `true` if the [index]th type parameter is generic-covariant-impl.
  bool isTypeParameterGenericCovariantImpl(int index) {
    List<bool>? typeParameters = _typeParameters;
    return typeParameters != null && index < typeParameters.length
        ? typeParameters[index]
        : false;
  }

  /// Returns the merge of this covariance with [other] in which parameters are
  /// covariant if they are covariant in either [this] or [other].
  Covariance merge(Covariance other) {
    if (identical(this, other)) return this;
    List<int>? positionalParameters;
    if (_positionalParameters == null) {
      positionalParameters = other._positionalParameters;
    } else if (other._positionalParameters == null) {
      positionalParameters = _positionalParameters;
    } else {
      positionalParameters = new List<int>.filled(
          max(_positionalParameters!.length,
              other._positionalParameters!.length),
          0);
      for (int index = 0; index < positionalParameters.length; index++) {
        positionalParameters[index] =
            getPositionalVariance(index) | other.getPositionalVariance(index);
      }
    }
    Map<String, int>? namedParameters;
    if (_namedParameters == null) {
      namedParameters = other._namedParameters;
    } else if (other._namedParameters == null) {
      namedParameters = _namedParameters;
    } else {
      namedParameters = {};
      Set<String> names = {
        ..._namedParameters!.keys,
        ...other._namedParameters!.keys
      };
      for (String name in names) {
        namedParameters[name] =
            getNamedVariance(name) | other.getNamedVariance(name);
      }
    }
    List<bool>? typeParameters;
    if (_typeParameters == null) {
      typeParameters = other._typeParameters;
    } else if (other._typeParameters == null) {
      typeParameters = _typeParameters;
    } else {
      typeParameters = new List<bool>.filled(
          max(_typeParameters!.length, other._typeParameters!.length), false);
      for (int index = 0; index < typeParameters.length; index++) {
        typeParameters[index] = isTypeParameterGenericCovariantImpl(index) ||
            other.isTypeParameterGenericCovariantImpl(index);
      }
    }
    if (positionalParameters == null &&
        namedParameters == null &&
        typeParameters == null) {
      return const Covariance.empty();
    }
    return new Covariance.internal(
        positionalParameters, namedParameters, typeParameters);
  }

  /// Update [member] to have the covariant flags set with the covariance in
  /// [this].
  ///
  /// No covariance bits are removed from [member] during this process.
  void applyCovariance(Member member) {
    if (isEmpty) return;
    if (member is Procedure) {
      FunctionNode function = member.function;
      List<int>? positionalParameters = _positionalParameters;
      if (positionalParameters != null) {
        for (int index = 0; index < positionalParameters.length; index++) {
          if (index < function.positionalParameters.length) {
            covarianceToParameter(positionalParameters[index],
                function.positionalParameters[index]);
          }
        }
      }
      if (_namedParameters != null) {
        for (VariableDeclaration parameter in function.namedParameters) {
          covarianceToParameter(getNamedVariance(parameter.name!), parameter);
        }
      }
      List<bool>? typeParameters = _typeParameters;
      if (typeParameters != null) {
        for (int index = 0; index < typeParameters.length; index++) {
          if (index < function.typeParameters.length) {
            if (typeParameters[index]) {
              function.typeParameters[index].isCovariantByClass = true;
            }
          }
        }
      }
    } else if (member is Field) {
      if (_positionalParameters != null) {
        covarianceToField(getPositionalVariance(0), member);
      }
    } else {
      throw new UnsupportedError(
          "Unexpected member $member (${member.runtimeType})");
    }
  }

  @override
  int get hashCode {
    int hash = 0;
    List<int>? positionalParameters = _positionalParameters;
    if (positionalParameters != null) {
      for (int covariance in positionalParameters) {
        hash += covariance.hashCode * 17;
      }
    }
    Map<String, int>? namedParameters = _namedParameters;
    if (namedParameters != null) {
      for (String name in namedParameters.keys) {
        hash += name.hashCode * 19 + namedParameters[name].hashCode * 23;
      }
    }
    List<bool>? typeParameters = _typeParameters;
    if (typeParameters != null) {
      for (bool covariance in typeParameters) {
        if (covariance) {
          hash += covariance.hashCode * 31;
        }
      }
    }
    return hash;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is Covariance) {
      if (_positionalParameters != other._positionalParameters) {
        if (_positionalParameters == null ||
            other._positionalParameters == null) {
          return false;
        }
        int positionalParameterCount = max(
            _positionalParameters!.length, other._positionalParameters!.length);
        for (int i = 0; i < positionalParameterCount; i++) {
          if (getPositionalVariance(i) != other.getPositionalVariance(i)) {
            return false;
          }
        }
      }
      if (_namedParameters != other._namedParameters) {
        if (_namedParameters == null || other._namedParameters == null) {
          return false;
        }
        Set<String> names = {
          ..._namedParameters!.keys,
          ...other._namedParameters!.keys
        };
        for (String name in names) {
          if (getNamedVariance(name) != other.getNamedVariance(name)) {
            return false;
          }
        }
      }
      if (_typeParameters != other._typeParameters) {
        if (_typeParameters == null || other._typeParameters == null) {
          return false;
        }
        int typeParameterCount =
            max(_typeParameters!.length, other._typeParameters!.length);
        for (int i = 0; i < typeParameterCount; i++) {
          if (isTypeParameterGenericCovariantImpl(i) !=
              other.isTypeParameterGenericCovariantImpl(i)) {
            return false;
          }
        }
      }
      return true;
    }
    return false;
  }

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    if (isEmpty) {
      sb.write('Covariance.empty()');
    } else {
      sb.write('Covariance(');
      String comma = '';
      List<int>? positionalParameters = _positionalParameters;
      if (positionalParameters != null) {
        for (int index = 0; index < positionalParameters.length; index++) {
          if (positionalParameters[index] != 0) {
            sb.write(comma);
            sb.write('$index:');
            switch (positionalParameters[index]) {
              case GenericCovariantImpl:
                sb.write('GenericCovariantImpl');
                break;
              case Covariant:
                sb.write('Covariant');
                break;
              default:
                sb.write('GenericCovariantImpl+Covariant');
                break;
            }
            comma = ',';
          }
        }
      }
      Map<String, int>? namedParameters = _namedParameters;
      if (namedParameters != null) {
        for (String name in namedParameters.keys) {
          int covariance = namedParameters[name]!;
          if (covariance != 0) {
            sb.write(comma);
            sb.write('$name:');

            switch (covariance) {
              case GenericCovariantImpl:
                sb.write('GenericCovariantImpl');
                break;
              case Covariant:
                sb.write('Covariant');
                break;
              default:
                sb.write('GenericCovariantImpl+Covariant');
                break;
            }
            comma = ',';
          }
        }
      }
      List<bool>? typeParameters = _typeParameters;
      if (typeParameters != null) {
        sb.write(comma);
        sb.write('types:');
        comma = '';
        for (int index = 0; index < typeParameters.length; index++) {
          if (typeParameters[index]) {
            sb.write(comma);
            sb.write('$index');
            comma = ',';
          }
        }
      }
      sb.write(')');
    }
    return sb.toString();
  }
}
