// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'class_hierarchy.dart';
import 'core_types.dart';
import 'kernel.dart';
import 'type_checker.dart' as type_checker;
import 'type_algebra.dart';

abstract class FailureListener {
  void reportFailure(TreeNode node, String message);
  void reportNotAssignable(TreeNode node, DartType first, DartType second);
  void reportInvalidOverride(Member member, Member inherited, String message);
}

class StrongModeTypeChecker extends type_checker.TypeChecker {
  final FailureListener failures;

  StrongModeTypeChecker(FailureListener failures, Program program,
      {bool ignoreSdk: false})
      : this._(failures, new CoreTypes(program),
            new ClosedWorldClassHierarchy(program), ignoreSdk);

  StrongModeTypeChecker._(this.failures, CoreTypes coreTypes,
      ClassHierarchy hierarchy, bool ignoreSdk)
      : super(coreTypes, hierarchy, strongMode: true, ignoreSdk: ignoreSdk);

  // TODO(vegorov) this only gets called for immediate overrides which leads
  // to less strict checking that Dart 2.0 specification demands for covariant
  // parameters.
  @override
  void checkOverride(
      Class host, Member ownMember, Member superMember, bool isSetter) {
    final ownMemberIsFieldOrAccessor =
        ownMember is Field || (ownMember as Procedure).isAccessor;
    final superMemberIsFieldOrAccessor =
        superMember is Field || (superMember as Procedure).isAccessor;

    // TODO: move to error reporting code
    String _memberKind(Member m) {
      if (m is Field) {
        return 'field';
      } else {
        final p = m as Procedure;
        if (p.isGetter) {
          return 'getter';
        } else if (p.isSetter) {
          return 'setter';
        } else {
          return 'method';
        }
      }
    }

    // First check if we are overriding field/accessor with a normal method
    // or other way around.
    if (ownMemberIsFieldOrAccessor != superMemberIsFieldOrAccessor) {
      return failures.reportInvalidOverride(ownMember, superMember, '''
${ownMember} is a ${_memberKind(ownMember)}
${superMember} is a ${_memberKind(superMember)}
''');
    }

    if (ownMemberIsFieldOrAccessor) {
      if (isSetter) {
        final DartType ownType = setterType(host, ownMember);
        final DartType superType = setterType(host, superMember);
        final isCovariant = ownMember is Field
            ? ownMember.isCovariant
            : ownMember.function.positionalParameters[0].isCovariant;
        if (!_isValidParameterOverride(isCovariant, ownType, superType)) {
          if (isCovariant) {
            return failures.reportInvalidOverride(ownMember, superMember, '''
${ownType} is neither a subtype nor supertype of ${superType}
''');
          } else {
            return failures.reportInvalidOverride(ownMember, superMember, '''
${ownType} is not a subtype of ${superType}
''');
          }
        }
      } else {
        final DartType ownType = getterType(host, ownMember);
        final DartType superType = getterType(host, superMember);
        if (!environment.isSubtypeOf(ownType, superType)) {
          return failures.reportInvalidOverride(ownMember, superMember, '''
${ownType} is not a subtype of ${superType}
''');
        }
      }
    } else {
      final msg = _checkFunctionOverride(host, ownMember, superMember);
      if (msg != null) {
        return failures.reportInvalidOverride(ownMember, superMember, msg);
      }
    }
  }

  /// Check if [subtype] is subtype of [supertype] after applying
  /// type parameter [substitution].
  bool _isSubtypeOf(DartType subtype, DartType supertype) =>
      environment.isSubtypeOf(subtype, supertype);

  Substitution _makeSubstitutionForMember(Class host, Member member) {
    final hostType =
        hierarchy.getClassAsInstanceOf(host, member.enclosingClass);
    return Substitution.fromSupertype(hostType);
  }

  /// Check if function node [ownMember] is a valid override for [superMember].
  /// Returns [null] if override is valid or an error message.
  ///
  /// Note: this function is a copy of [SubtypeTester._isFunctionSubtypeOf]
  /// but it additionally accounts for parameter covariance.
  String _checkFunctionOverride(
      Class host, Member ownMember, Member superMember) {
    final FunctionNode ownFunction = ownMember.function;
    final FunctionNode superFunction = superMember.function;
    Substitution ownSubstitution = _makeSubstitutionForMember(host, ownMember);
    final Substitution superSubstitution =
        _makeSubstitutionForMember(host, superMember);

    if (ownFunction.requiredParameterCount >
        superFunction.requiredParameterCount) {
      return 'override has more required parameters';
    }
    if (ownFunction.positionalParameters.length <
        superFunction.positionalParameters.length) {
      return 'super method has more positional parameters';
    }
    if (ownFunction.typeParameters.length !=
        superFunction.typeParameters.length) {
      return 'methods have different type parameters counts';
    }

    if (ownFunction.typeParameters.isNotEmpty) {
      final typeParameterMap = <TypeParameter, DartType>{};
      for (int i = 0; i < ownFunction.typeParameters.length; ++i) {
        var subParameter = ownFunction.typeParameters[i];
        var superParameter = superFunction.typeParameters[i];
        typeParameterMap[subParameter] = new TypeParameterType(superParameter);
      }

      ownSubstitution = Substitution.combine(
          ownSubstitution, Substitution.fromMap(typeParameterMap));
      for (int i = 0; i < ownFunction.typeParameters.length; ++i) {
        var subParameter = ownFunction.typeParameters[i];
        var superParameter = superFunction.typeParameters[i];
        var subBound = ownSubstitution.substituteType(subParameter.bound);
        if (!_isSubtypeOf(
            superSubstitution.substituteType(superParameter.bound), subBound)) {
          return 'type parameters have incompatible bounds';
        }
      }
    }

    if (!_isSubtypeOf(ownSubstitution.substituteType(ownFunction.returnType),
        superSubstitution.substituteType(superFunction.returnType))) {
      return 'return type of override ${ownFunction
          .returnType} is not a subtype'
          ' of ${superFunction.returnType}';
    }

    for (int i = 0; i < superFunction.positionalParameters.length; ++i) {
      final ownParameter = ownFunction.positionalParameters[i];
      final superParameter = superFunction.positionalParameters[i];
      if (!_isValidParameterOverride(
          ownParameter.isCovariant,
          ownSubstitution.substituteType(ownParameter.type),
          superSubstitution.substituteType(superParameter.type))) {
        return '''
type of parameter ${ownParameter.name} is incompatible
override declares ${ownParameter.type}
super method declares ${superParameter.type}
''';
      }
    }

    if (superFunction.namedParameters.isEmpty) {
      return null;
    }

    // Note: FunctionNode.namedParameters are not sorted so we convert them
    // to map to make lookup faster.
    final ownParameters = new Map<String, VariableDeclaration>.fromIterable(
        ownFunction.namedParameters,
        key: (v) => v.name);
    for (VariableDeclaration superParameter in superFunction.namedParameters) {
      final ownParameter = ownParameters[superParameter.name];
      if (ownParameter == null) {
        return 'override is missing ${superParameter.name} parameter';
      }

      if (!_isValidParameterOverride(
          ownParameter.isCovariant,
          ownSubstitution.substituteType(ownParameter.type),
          superSubstitution.substituteType(superParameter.type))) {
        return '''
type of parameter ${ownParameter.name} is incompatible
override declares ${ownParameter.type}
super method declares ${superParameter.type}
''';
      }
    }

    return null;
  }

  /// Checks whether parameter with [ownParameterType] type is a valid override
  /// for parameter with [superParameterType] type taking into account its
  /// covariance and applying type parameter [substitution] if necessary.
  bool _isValidParameterOverride(bool isCovariant, DartType ownParameterType,
      DartType superParameterType) {
    if (_isSubtypeOf(superParameterType, ownParameterType)) {
      return true;
    } else if (isCovariant &&
        _isSubtypeOf(ownParameterType, superParameterType)) {
      return true;
    } else {
      return false;
    }
  }

  @override
  void checkAssignable(TreeNode where, DartType from, DartType to) {
    // Note: we permit implicit downcasts.
    if (from != to &&
        !environment.isSubtypeOf(from, to) &&
        !environment.isSubtypeOf(to, from)) {
      failures.reportNotAssignable(where, from, to);
    }
  }

  @override
  void checkUnresolvedInvocation(DartType receiver, TreeNode where) {
    if (receiver is DynamicType) {
      return;
    }

    // Permit any invocation on Function type.
    if (receiver == environment.rawFunctionType &&
        where is MethodInvocation &&
        where.name.name == 'call') {
      return;
    }

    fail(where, 'Unresolved method invocation');
  }

  @override
  void fail(TreeNode where, String message) {
    failures.reportFailure(where, message);
  }
}
