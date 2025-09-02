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
import 'package:analyzer/src/dart/resolver/extension_member_resolver.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/generated/inference_log.dart';

class InstantiatedExtensionWithMember {
  final _NotInstantiatedExtensionWithMember candidate;
  final MapSubstitution substitution;
  final TypeImpl extendedType;

  InstantiatedExtensionWithMember(
    this.candidate,
    this.substitution,
    this.extendedType,
  );

  ExtensionResolutionResult get asResolutionResult {
    return SingleExtensionResolutionResult(getter2: getter, setter2: setter);
  }

  ExtensionElement get extension => candidate.extension;

  InternalExecutableElement? get getter {
    var getter = candidate.getter;
    if (getter == null) {
      return null;
    }
    return SubstitutedExecutableElementImpl.from(getter, substitution);
  }

  InternalExecutableElement? get setter {
    var setter = candidate.setter;
    if (setter == null) {
      return null;
    }
    return SubstitutedExecutableElementImpl.from(setter, substitution);
  }
}

class InstantiatedExtensionWithoutMember {
  final ExtensionElement extension;
  final MapSubstitution substitution;
  final DartType extendedType;

  InstantiatedExtensionWithoutMember(
    this.extension,
    this.substitution,
    this.extendedType,
  );
}

abstract class _NotInstantiatedExtension<R> {
  final ExtensionElementImpl extension;

  _NotInstantiatedExtension(this.extension);

  R instantiate({
    required MapSubstitution substitution,
    required TypeImpl extendedType,
  });
}

class _NotInstantiatedExtensionWithMember
    extends _NotInstantiatedExtension<InstantiatedExtensionWithMember> {
  final ExecutableElement? getter;
  final ExecutableElement? setter;

  _NotInstantiatedExtensionWithMember(
    super.extension, {
    this.getter,
    this.setter,
  }) : assert(getter != null || setter != null);

  @override
  InstantiatedExtensionWithMember instantiate({
    required MapSubstitution substitution,
    required TypeImpl extendedType,
  }) {
    return InstantiatedExtensionWithMember(this, substitution, extendedType);
  }
}

/// [_NotInstantiatedExtension] for any [ExtensionElement].
class _NotInstantiatedExtensionWithoutMember
    extends _NotInstantiatedExtension<InstantiatedExtensionWithoutMember> {
  _NotInstantiatedExtensionWithoutMember(super.extension);

  @override
  InstantiatedExtensionWithoutMember instantiate({
    required MapSubstitution substitution,
    required DartType extendedType,
  }) {
    return InstantiatedExtensionWithoutMember(
      extension,
      substitution,
      extendedType,
    );
  }
}

extension ExtensionsExtensions on Iterable<ExtensionElement> {
  /// Extensions that can be applied, within [targetLibrary], to [targetType].
  List<InstantiatedExtensionWithoutMember> applicableTo({
    required LibraryElement targetLibrary,
    required TypeImpl targetType,
    required bool strictCasts,
  }) {
    targetLibrary as LibraryElementImpl;
    return map(
      (e) => _NotInstantiatedExtensionWithoutMember(
        // TODO(paulberry): eliminate this cast by changing the extension to
        // apply only to `Iterable<ExtensionElementImpl>`.
        e as ExtensionElementImpl,
      ),
    ).applicableTo(targetLibrary: targetLibrary, targetType: targetType);
  }

  /// Returns the sublist of [ExtensionElement]s that have an instance member
  /// named [baseName].
  List<_NotInstantiatedExtensionWithMember> havingMemberWithBaseName(
    Name baseName,
  ) {
    var result = <_NotInstantiatedExtensionWithMember>[];
    for (var extension in this) {
      if (!baseName.isAccessibleFor(extension.library.uri)) {
        continue;
      }

      if (baseName.name == '[]') {
        var getter = extension.getMethod('[]');
        var setter = extension.getMethod('[]=');
        if (getter != null || setter != null) {
          result.add(
            _NotInstantiatedExtensionWithMember(
              // TODO(paulberry): eliminate this cast by changing the extension
              // to apply only to `Iterable<ExtensionElementImpl>`.
              extension as ExtensionElementImpl,
              getter: getter,
              setter: setter,
            ),
          );
        }
      } else {
        var field = extension.getField(baseName.name);
        if (field != null && !field.isStatic) {
          result.add(
            _NotInstantiatedExtensionWithMember(
              // TODO(paulberry): eliminate this cast by changing the
              // extension to apply only to `Iterable<ExtensionElementImpl>`.
              extension as ExtensionElementImpl,
              getter: field.getter,
              setter: field.setter,
            ),
          );
        }

        var method = extension.getMethod(baseName.name);
        if (method != null && !method.isStatic) {
          result.add(
            _NotInstantiatedExtensionWithMember(
              // TODO(paulberry): eliminate this cast by changing the
              // extension to apply only to `Iterable<ExtensionElementImpl>`.
              extension as ExtensionElementImpl,
              getter: method,
            ),
          );
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
    required LibraryElement targetLibrary,
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

      var freshTypes = getFreshTypeParameters(extension.typeParameters);
      var freshTypeParameters = freshTypes.freshTypeParameters;
      var rawExtendedType = freshTypes.substitute(extension.extendedType);
      // Casts aren't relevant in extension applicability.
      var typeSystemOperations = TypeSystemOperations(
        typeSystem,
        strictCasts: false,
      );

      inferenceLogWriter?.enterGenericInference(
        freshTypeParameters,
        rawExtendedType,
      );
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
        extension.typeParameters,
        inferredTypes,
      );
      var extendedType = substitution.substituteType(extension.extendedType);

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
