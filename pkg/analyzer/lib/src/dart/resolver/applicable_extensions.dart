// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/generic_inferrer.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/resolver/extension_member_resolver.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/generated/inference_log.dart';

class InstantiatedExtensionWithMember {
  final _NotInstantiatedExtensionWithMember candidate;
  final MapSubstitution substitution;
  final DartType extendedType;

  InstantiatedExtensionWithMember(
    this.candidate,
    this.substitution,
    this.extendedType,
  );

  ExtensionResolutionResult get asResolutionResult {
    return SingleExtensionResolutionResult(
      getter2: getter,
      setter2: setter,
    );
  }

  ExtensionElement2 get extension => candidate.extension;

  ExecutableElement2? get getter {
    var getter = candidate.getter;
    if (getter == null) {
      return null;
    }
    return ExecutableMember.from(getter, substitution);
  }

  ExecutableElement2? get setter {
    var setter = candidate.setter;
    if (setter == null) {
      return null;
    }
    return ExecutableMember.from(setter, substitution);
  }
}

class InstantiatedExtensionWithoutMember {
  final ExtensionElement2 extension;
  final MapSubstitution substitution;
  final DartType extendedType;

  InstantiatedExtensionWithoutMember(
    this.extension,
    this.substitution,
    this.extendedType,
  );
}

abstract class _NotInstantiatedExtension<R> {
  final ExtensionElementImpl2 extension;

  _NotInstantiatedExtension(this.extension);

  R instantiate({
    required MapSubstitution substitution,
    required DartType extendedType,
  });
}

class _NotInstantiatedExtensionWithMember
    extends _NotInstantiatedExtension<InstantiatedExtensionWithMember> {
  final ExecutableElement2? getter;
  final ExecutableElement2? setter;

  _NotInstantiatedExtensionWithMember(super.extension,
      {this.getter, this.setter})
      : assert(getter != null || setter != null);

  @override
  InstantiatedExtensionWithMember instantiate({
    required MapSubstitution substitution,
    required DartType extendedType,
  }) {
    return InstantiatedExtensionWithMember(this, substitution, extendedType);
  }
}

/// [_NotInstantiatedExtension] for any [ExtensionElement2].
class _NotInstantiatedExtensionWithoutMember
    extends _NotInstantiatedExtension<InstantiatedExtensionWithoutMember> {
  _NotInstantiatedExtensionWithoutMember(super.extension);

  @override
  InstantiatedExtensionWithoutMember instantiate({
    required MapSubstitution substitution,
    required DartType extendedType,
  }) {
    return InstantiatedExtensionWithoutMember(
        extension, substitution, extendedType);
  }
}

extension ExtensionsExtensions on Iterable<ExtensionElement2> {
  /// Extensions that can be applied, within [targetLibrary], to [targetType].
  List<InstantiatedExtensionWithoutMember> applicableTo({
    required LibraryElement2 targetLibrary,
    required TypeImpl targetType,
    required bool strictCasts,
  }) {
    targetLibrary as LibraryElementImpl;
    return map((e) => _NotInstantiatedExtensionWithoutMember(
            // TODO(paulberry): eliminate this cast by changing the extension to
            // apply only to `Iterable<ExtensionElementImpl>`.
            e as ExtensionElementImpl2))
        .applicableTo(targetLibrary: targetLibrary, targetType: targetType);
  }

  /// Returns the sublist of [ExtensionElement2]s that have an instance member
  /// named [baseName].
  List<_NotInstantiatedExtensionWithMember> havingMemberWithBaseName(
    Name baseName,
  ) {
    var result = <_NotInstantiatedExtensionWithMember>[];
    for (var extension in this) {
      if (baseName.name == '[]') {
        ExecutableElement2? getter;
        ExecutableElement2? setter;
        for (var method in extension.methods2) {
          if (method.name3 == '[]') {
            getter = method;
          } else if (method.name3 == '[]=') {
            setter = method;
          }
        }
        if (getter != null || setter != null) {
          result.add(
            _NotInstantiatedExtensionWithMember(
              // TODO(paulberry): eliminate this cast by changing the extension
              // to apply only to `Iterable<ExtensionElementImpl>`.
              extension as ExtensionElementImpl2,
              getter: getter,
              setter: setter,
            ),
          );
        }
      } else {
        for (var field in extension.fields2) {
          if (field.isStatic) {
            continue;
          }
          var fieldName = Name.forElement(field);
          if (fieldName == baseName) {
            result.add(
              _NotInstantiatedExtensionWithMember(
                // TODO(paulberry): eliminate this cast by changing the
                // extension to apply only to `Iterable<ExtensionElementImpl>`.
                extension as ExtensionElementImpl2,
                getter: field.getter2,
                setter: field.setter2,
              ),
            );
            break;
          }
        }
        for (var method in extension.methods2) {
          if (method.isStatic) {
            continue;
          }
          var methodName = Name.forElement(method);
          if (methodName == baseName) {
            result.add(
              _NotInstantiatedExtensionWithMember(
                // TODO(paulberry): eliminate this cast by changing the
                // extension to apply only to `Iterable<ExtensionElementImpl>`.
                extension as ExtensionElementImpl2,
                getter: method,
              ),
            );
            break;
          }
        }
      }
    }
    return result;
  }
}

extension NotInstantiatedExtensionsExtensions<R>
    on Iterable<_NotInstantiatedExtension<R>> {
  /// Extensions that can be applied, within [targetLibrary], to [targetType].
  List<R> applicableTo({
    required LibraryElement2 targetLibrary,
    required TypeImpl targetType,
  }) {
    if (identical(targetType, NeverTypeImpl.instance)) {
      return <R>[];
    }

    targetLibrary as LibraryElementImpl;
    var typeSystem = targetLibrary.typeSystem;
    var genericMetadataIsEnabled = targetLibrary.featureSet.isEnabled(
      Feature.generic_metadata,
    );
    var inferenceUsingBoundsIsEnabled = targetLibrary.featureSet.isEnabled(
      Feature.inference_using_bounds,
    );

    var instantiated = <R>[];

    for (var notInstantiated in this) {
      var extension = notInstantiated.extension;

      var freshTypes = getFreshTypeParameters2(extension.typeParameters2);
      var freshTypeParameters = freshTypes.freshTypeParameters;
      var rawExtendedType = freshTypes.substitute(extension.extendedType);
      // Casts aren't relevant in extension applicability.
      var typeSystemOperations =
          TypeSystemOperations(typeSystem, strictCasts: false);

      inferenceLogWriter?.enterGenericInference(
          freshTypeParameters, rawExtendedType);
      var inferrer = GenericInferrer(
        typeSystem,
        freshTypeParameters,
        genericMetadataIsEnabled: genericMetadataIsEnabled,
        inferenceUsingBoundsIsEnabled: inferenceUsingBoundsIsEnabled,
        strictInference: false,
        typeSystemOperations: typeSystemOperations,
        dataForTesting: null,
      );
      inferrer.constrainArgument(
        targetType,
        rawExtendedType,
        'extendedType',
        nodeForTesting: null,
      );
      var inferredTypes = inferrer.tryChooseFinalTypes();
      if (inferredTypes == null) {
        continue;
      }

      var substitution = Substitution.fromPairs2(
        extension.typeParameters2,
        inferredTypes,
      );
      var extendedType = substitution.substituteType(
        extension.extendedType,
      );

      if (!typeSystem.isSubtypeOf(targetType, extendedType)) {
        continue;
      }

      instantiated.add(
        notInstantiated.instantiate(
          substitution: substitution,
          extendedType: extendedType,
        ),
      );
    }

    return instantiated;
  }
}
