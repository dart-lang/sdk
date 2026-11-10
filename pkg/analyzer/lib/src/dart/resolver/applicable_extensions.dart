// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/generic_inferrer.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/resolver/extension_member_resolver.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/generated/inference_log.dart';

class InstantiatedExtensionWithMember {
  final _NotInstantiatedExtensionWithMember candidate;
  final MapSubstitution substitution;
  final TypeImpl extendedType;

  new(this.candidate, this.substitution, this.extendedType);

  ExtensionResolutionResult get asResolutionResult {
    return SingleExtensionResolutionResult(getter2: getter, setter2: setter);
  }

  ExtensionElement get extension => candidate.extension;

  InternalExecutableElement? get getter {
    return candidate.getter?.substitute(substitution);
  }

  InternalExecutableElement? get setter {
    return candidate.setter?.substitute(substitution);
  }
}

class InstantiatedExtensionWithoutMember {
  final ExtensionElement extension;
  final MapSubstitution substitution;
  final DartType extendedType;

  new(this.extension, this.substitution, this.extendedType);
}

class _ExtensionWithMemberWithName {
  final ExtensionElementImpl extension;
  final InternalExecutableElement? getter2;
  final InternalExecutableElement? setter2;

  new({required this.extension, required this.getter2, required this.setter2});
}

abstract class _NotInstantiatedExtension<R> {
  final ExtensionElementImpl extension;

  new(this.extension);

  R instantiate({
    required MapSubstitution substitution,
    required TypeImpl extendedType,
  });
}

class _NotInstantiatedExtensionWithMember
    extends _NotInstantiatedExtension<InstantiatedExtensionWithMember> {
  final InternalExecutableElement? getter;
  final InternalExecutableElement? setter;

  new(super.extension, {this.getter, this.setter})
    : assert(getter != null || setter != null);

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
  new(super.extension);

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

extension on List<_NotInstantiatedExtensionWithMember> {
  /// Adds [extension] with its instance members that have the basename
  /// [name], if it has any.
  void addIfHasMemberWithBaseName(ExtensionElementImpl extension, String name) {
    if (name == '[]') {
      var getter = extension.getMethod('[]');
      var setter = extension.getMethod('[]=');
      if (getter != null || setter != null) {
        add(
          _NotInstantiatedExtensionWithMember(
            extension,
            getter: getter,
            setter: setter,
          ),
        );
      }
    } else {
      var field = extension.getField(name);
      if (field != null && !field.isStatic) {
        add(
          _NotInstantiatedExtensionWithMember(
            extension,
            getter: field.getter,
            setter: field.setter,
          ),
        );
      }

      var method = extension.getMethod(name);
      if (method != null && !method.isStatic) {
        add(_NotInstantiatedExtensionWithMember(extension, getter: method));
      }
    }
  }
}

extension ExtensionsExtensions on Iterable<ExtensionElement> {
  /// Extensions that can be applied, within [targetLibrary], to [targetType].
  List<InstantiatedExtensionWithoutMember> applicableTo({
    required LibraryElement targetLibrary,
    required DartType targetType,
  }) {
    targetLibrary as LibraryElementImpl;
    return cast<ExtensionElementImpl>()
        .map((e) => _NotInstantiatedExtensionWithoutMember(e))
        .applicableTo(targetLibrary: targetLibrary, targetType: targetType);
  }

  /// Returns the sublist of [ExtensionElement]s that have an instance member
  /// with basename [baseName].
  List<_NotInstantiatedExtensionWithMember> havingMemberWithBaseName(
    Name baseName,
  ) {
    var result = <_NotInstantiatedExtensionWithMember>[];
    for (var extension in cast<ExtensionElementImpl>()) {
      if (baseName.isAccessibleFor(extension.library.uri)) {
        result.addIfHasMemberWithBaseName(extension, baseName.name);
      }
    }
    return result;
  }

  /// Returns the sublist of [ExtensionElement]s that are declared in another
  /// library than the private [baseName], and have an instance member with
  /// its basename.
  ///
  /// This is for reporting a failed lookup of [baseName]: `_foo` of another
  /// library is a different name, so [havingMemberWithBaseName] skips it.
  List<_NotInstantiatedExtensionWithMember>
  havingPrivateMemberOfOtherLibraryWithBaseName(Name baseName) {
    var result = <_NotInstantiatedExtensionWithMember>[];
    for (var extension in cast<ExtensionElementImpl>()) {
      if (!baseName.isAccessibleFor(extension.library.uri)) {
        result.addIfHasMemberWithBaseName(extension, baseName.name);
      }
    }
    return result;
  }

  /// Returns the sublist of [ExtensionElement]s that have a static member
  /// with name [name].
  List<_ExtensionWithMemberWithName> havingStaticMemberWithName(Name name) {
    var result = <_ExtensionWithMemberWithName>[];
    for (var extension in cast<ExtensionElementImpl>()) {
      if (!name.isAccessibleFor(extension.library.uri)) {
        continue;
      }

      ExecutableElementImpl? lookedUpGetter;
      ExecutableElementImpl? lookedUpSetter;

      if (extension.getGetter(name.name) case var getter2?
          when getter2.isStatic) {
        lookedUpGetter = getter2;
      } else if (extension.getMethod(name.name) case var method2?
          when method2.isStatic) {
        lookedUpGetter = method2;
      }

      if (extension.getSetter(name.name) case var setter2?
          when setter2.isStatic) {
        lookedUpSetter = setter2;
      }

      if (lookedUpGetter != null || lookedUpSetter != null) {
        result.add(
          _ExtensionWithMemberWithName(
            extension: extension,
            getter2: lookedUpGetter,
            setter2: lookedUpSetter,
          ),
        );
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
    required DartType targetType,
  }) {
    targetLibrary as LibraryElementImpl;
    targetType as TypeImpl;

    if (identical(targetType, NeverTypeImpl.instance)) {
      return <R>[];
    }

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
