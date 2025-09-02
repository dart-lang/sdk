// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/diagnostic/diagnostic_factory.dart';
import 'package:analyzer/src/error/codes.dart';

class CorrectOverrideHelper {
  final TypeSystemImpl _typeSystem;

  final InternalExecutableElement _thisMember;
  FunctionTypeImpl? _thisTypeForSubtype;

  final DiagnosticFactory _diagnosticFactory = DiagnosticFactory();

  CorrectOverrideHelper({
    required TypeSystemImpl typeSystem,
    required InternalExecutableElement thisMember,
  }) : _typeSystem = typeSystem,
       _thisMember = thisMember {
    _computeThisTypeForSubtype();
  }

  /// Return `true` if [_thisMember] is a correct override of [superMember].
  bool isCorrectOverrideOf({required ExecutableElement superMember}) {
    var superType = superMember.type as TypeImpl;
    return _typeSystem.isSubtypeOf(_thisTypeForSubtype!, superType);
  }

  /// If [_thisMember] is not a correct override of [superMember], report the
  /// error.
  void verify({
    required ExecutableElement superMember,
    required DiagnosticReporter diagnosticReporter,
    required SyntacticEntity errorNode,
    required DiagnosticCode diagnosticCode,
  }) {
    var isCorrect = isCorrectOverrideOf(superMember: superMember);
    if (!isCorrect) {
      var member = _thisMember;
      var memberName = member.name;
      if (memberName != null) {
        diagnosticReporter.reportError(
          _diagnosticFactory.invalidOverride(
            diagnosticReporter.source,
            diagnosticCode,
            errorNode,
            _thisMember,
            superMember,
            memberName,
          ),
        );
      }
    }
  }

  /// Fill [_thisTypeForSubtype]. If [_thisMember] has covariant formal
  /// parameters, replace their types with `Object?` or `Object`.
  void _computeThisTypeForSubtype() {
    var type = _thisMember.type;
    var parameters = type.formalParameters;

    List<InternalFormalParameterElement>? newParameters;
    for (var i = 0; i < parameters.length; i++) {
      var parameter = parameters[i];
      if (parameter.isCovariant) {
        newParameters ??= parameters.toList(growable: false);
        newParameters[i] = parameter.copyWith(type: _typeSystem.objectQuestion);
      }
    }

    if (newParameters != null) {
      _thisTypeForSubtype = FunctionTypeImpl.v2(
        typeParameters: type.typeParameters,
        formalParameters: newParameters,
        returnType: type.returnType,
        nullabilitySuffix: type.nullabilitySuffix,
      );
    } else {
      _thisTypeForSubtype = type;
    }
  }
}

class CovariantParametersVerifier {
  final AnalysisSessionImpl _session;
  final TypeSystemImpl _typeSystem;

  final InternalExecutableElement _thisMember;

  CovariantParametersVerifier({required InternalExecutableElement thisMember})
    : _session = thisMember.library.session as AnalysisSessionImpl,
      _typeSystem = thisMember.library.typeSystem as TypeSystemImpl,
      _thisMember = thisMember;

  void verify({
    required DiagnosticReporter errorReporter,
    required SyntacticEntity errorEntity,
  }) {
    var superParameters = _superParameters();
    for (var entry in superParameters.entries) {
      var parameter = entry.key;
      for (var superParameter in entry.value) {
        var thisType = parameter.type;
        var superType = superParameter.type;
        if (!_typeSystem.isSubtypeOf(superType, thisType) &&
            !_typeSystem.isSubtypeOf(thisType, superType)) {
          var superMember = superParameter.member;
          // Elements enclosing members that can participate in overrides are
          // always named, so we can safely assume
          // `_thisMember.enclosingElement3.name` and
          // `superMember.enclosingElement3.name` are non-`null`.
          errorReporter.atEntity(
            errorEntity,
            CompileTimeErrorCode.invalidOverride,
            arguments: [
              _thisMember.name!,
              _thisMember.enclosingElement!.name!,
              _thisMember.type,
              superMember.enclosingElement!.name!,
              superMember.type,
            ],
          );
        }
      }
    }
  }

  List<_SuperMember> _superMembers() {
    var classHierarchy = _session.classHierarchy;
    var classElement = _thisMember.enclosingElement as InterfaceElementImpl;
    var interfaces = classHierarchy.implementedInterfaces(classElement);

    var superMembers = <_SuperMember>[];
    for (var interface in interfaces) {
      var superMember = _correspondingMember(interface.element, _thisMember);
      if (superMember != null) {
        superMembers.add(_SuperMember(interface, superMember));
      }
    }

    return superMembers;
  }

  Map<InternalFormalParameterElement, List<_SuperParameter>>
  _superParameters() {
    var result = <InternalFormalParameterElement, List<_SuperParameter>>{};

    List<_SuperMember>? superMembers;
    var parameters = _thisMember.formalParameters;
    for (var i = 0; i < parameters.length; i++) {
      var parameter = parameters[i];
      if (parameter.isCovariant) {
        superMembers ??= _superMembers();
        for (var superMember in superMembers) {
          var superParameter = _correspondingParameter(
            superMember.rawElement.formalParameters,
            parameter,
            i,
          );
          if (superParameter != null) {
            var parameterSuperList = result[parameter] ??= [];
            var superType = _superSubstitution(
              superMember,
            ).substituteType(superParameter.type);
            parameterSuperList.add(_SuperParameter(superParameter, superType));
          }
        }
      }
    }

    return result;
  }

  /// Return the [Substitution] to convert types of [superMember] to types of
  /// [_thisMember].
  Substitution _superSubstitution(_SuperMember superMember) {
    Substitution result = Substitution.fromInterfaceType(superMember.interface);

    // If the executable has type parameters, ensure that super uses the same.
    var thisTypeParameters = _thisMember.typeParameters;
    if (thisTypeParameters.isNotEmpty) {
      var superTypeParameters = superMember.rawElement.typeParameters;
      if (thisTypeParameters.length == superTypeParameters.length) {
        var typeParametersSubstitution = Substitution.fromPairs2(
          superTypeParameters,
          thisTypeParameters.map((e) {
            return e.instantiate(nullabilitySuffix: NullabilitySuffix.none);
          }).toList(),
        );
        result = Substitution.combine(result, typeParametersSubstitution);
      }
    }

    return result;
  }

  /// Return a member from [classElement] that corresponds to the [proto],
  /// or `null` if no such member exist.
  static ExecutableElement? _correspondingMember(
    InterfaceElement classElement,
    ExecutableElement proto,
  ) {
    if (proto is MethodElement) {
      return classElement.getMethod(proto.displayName);
    }
    if (proto is PropertyAccessorElement) {
      if (proto is GetterElement) {
        return classElement.getGetter(proto.displayName);
      }
      return classElement.getSetter(proto.displayName);
    }
    return null;
  }

  /// Return an element of [parameters] that corresponds for the [proto],
  /// or `null` if no such parameter exist.
  static FormalParameterElement? _correspondingParameter(
    List<FormalParameterElement> parameters,
    FormalParameterElement proto,
    int protoIndex,
  ) {
    if (proto.isPositional) {
      if (parameters.length > protoIndex) {
        var parameter = parameters[protoIndex];
        if (parameter.isPositional) {
          return parameter;
        }
      }
    } else {
      assert(proto.isNamed);
      for (var parameter in parameters) {
        if (parameter.isNamed && parameter.name == proto.name) {
          return parameter;
        }
      }
    }
    return null;
  }
}

class _SuperMember {
  final InterfaceType interface;
  final ExecutableElement rawElement;

  _SuperMember(this.interface, this.rawElement);
}

class _SuperParameter {
  final FormalParameterElement element;
  final TypeImpl type;

  _SuperParameter(this.element, this.type);

  ExecutableElement get member => element.enclosingElement as ExecutableElement;
}
