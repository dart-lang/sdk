// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/generic_inferrer.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/resolution_result.dart';

/// Extensions that can be applied, within the [targetLibrary], to the
/// [targetType], and that define a member with the base [memberName].
class ApplicableExtensions {
  final LibraryElementImpl targetLibrary;
  final DartType targetType;
  final String memberName;

  ApplicableExtensions({
    required LibraryElement targetLibrary,
    required this.targetType,
    required this.memberName,
  }) : targetLibrary = targetLibrary as LibraryElementImpl;

  bool get _genericMetadataIsEnabled {
    return targetLibrary.featureSet.isEnabled(
      Feature.generic_metadata,
    );
  }

  TypeSystemImpl get _typeSystem {
    return targetLibrary.typeSystem;
  }

  /// Return [extensions] that match the configuration.
  List<InstantiatedExtension> instantiate(
    Iterable<ExtensionElement> extensions,
  ) {
    if (identical(targetType, NeverTypeImpl.instance)) {
      return const <InstantiatedExtension>[];
    }

    var instantiatedExtensions = <InstantiatedExtension>[];

    var candidates = _withMember(extensions);
    for (var candidate in candidates) {
      var extension = candidate.extension;

      var freshTypes = getFreshTypeParameters(extension.typeParameters);
      var freshTypeParameters = freshTypes.freshTypeParameters;
      var rawExtendedType = freshTypes.substitute(extension.extendedType);

      var inferrer = GenericInferrer(_typeSystem, freshTypeParameters);
      inferrer.constrainArgument(
        targetType,
        rawExtendedType,
        'extendedType',
      );
      var typeArguments = inferrer.infer(
        freshTypeParameters,
        failAtError: true,
        genericMetadataIsEnabled: _genericMetadataIsEnabled,
      );
      if (typeArguments == null) {
        continue;
      }

      var substitution = Substitution.fromPairs(
        extension.typeParameters,
        typeArguments,
      );
      var extendedType = substitution.substituteType(
        extension.extendedType,
      );

      if (!_typeSystem.isSubtypeOf(targetType, extendedType)) {
        continue;
      }

      instantiatedExtensions.add(
        InstantiatedExtension(candidate, substitution, extendedType),
      );
    }

    return instantiatedExtensions;
  }

  /// Return [extensions] that define a member with the [memberName].
  List<_CandidateExtension> _withMember(
    Iterable<ExtensionElement> extensions,
  ) {
    var result = <_CandidateExtension>[];
    for (var extension in extensions) {
      for (var field in extension.fields) {
        if (field.name == memberName) {
          result.add(
            _CandidateExtension(
              extension,
              getter: field.getter,
              setter: field.setter,
            ),
          );
          break;
        }
      }
      if (memberName == '[]') {
        ExecutableElement? getter;
        ExecutableElement? setter;
        for (var method in extension.methods) {
          if (method.name == '[]') {
            getter = method;
          } else if (method.name == '[]=') {
            setter = method;
          }
        }
        if (getter != null || setter != null) {
          result.add(
            _CandidateExtension(extension, getter: getter, setter: setter),
          );
        }
      } else {
        for (var method in extension.methods) {
          if (method.name == memberName) {
            result.add(
              _CandidateExtension(extension, getter: method),
            );
            break;
          }
        }
      }
    }
    return result;
  }
}

class InstantiatedExtension {
  final _CandidateExtension candidate;
  final MapSubstitution substitution;
  final DartType extendedType;

  InstantiatedExtension(this.candidate, this.substitution, this.extendedType);

  ResolutionResult get asResolutionResult {
    return ResolutionResult(getter: getter, setter: setter);
  }

  ExtensionElement get extension => candidate.extension;

  ExecutableElement? get getter {
    var getter = candidate.getter;
    if (getter == null) {
      return null;
    }
    return ExecutableMember.from2(getter, substitution);
  }

  ExecutableElement? get setter {
    var setter = candidate.setter;
    if (setter == null) {
      return null;
    }
    return ExecutableMember.from2(setter, substitution);
  }
}

class _CandidateExtension {
  final ExtensionElement extension;
  final ExecutableElement? getter;
  final ExecutableElement? setter;

  _CandidateExtension(this.extension, {this.getter, this.setter})
      : assert(getter != null || setter != null);
}
