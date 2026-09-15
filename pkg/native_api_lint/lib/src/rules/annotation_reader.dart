// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Reads `@ExternalVersions` annotation metadata from resolved Dart elements.
library;

import 'package:analyzer/dart/element/element.dart';

/// Utility for extracting `@ExternalVersions` annotation data from analyzer
/// element model objects.
///
/// The annotation is defined in `package:native_interop_annotation` and applied
/// to generated Dart bindings by `ffigen`. At analysis time it is available as
/// a resolved `ElementAnnotation` on the element's `metadata` list.
abstract final class AnnotationReader {
  /// The fully-qualified class name of the `ExternalVersions` annotation.
  static const String _annotationClass = 'ExternalVersions';

  /// The fully-qualified class name of the `ExternalVersion` class.
  static const String _versionClass = 'ExternalVersion';

  /// The package URI of the annotation library.
  static const String _packageUri =
      'package:native_interop_annotation/native_interop_annotation.dart';

  /// Reads `@ExternalVersions` from [element]'s metadata (or the enclosing
  /// class's metadata, for class-level annotation inheritance).
  ///
  /// Returns a `Map<String, Map<String, String?>>` where:
  /// - Outer key: platform name (e.g. `'ios'`, `'macos'`)
  /// - Inner keys: `'min'`, `'max'`, `'deprecationMessage'`
  ///
  /// Returns `null` if no `@ExternalVersions` annotation is present on
  /// [element] or its enclosing class.
  static Map<String, Map<String, String?>>? readExternalVersions(
      Element element) {
    // 1. Check direct annotations on the element.
    var result = _fromMetadata(element.metadata);
    if (result != null) return result;

    // 2. Inherit from enclosing class (ObjC interface annotation applies to
    //    all methods when the method itself has no annotation).
    final enclosingElement = element.enclosingElement;
    if (enclosingElement is ClassElement) {
      result = _fromMetadata(enclosingElement.metadata);
      if (result != null) return result;
    }

    return null;
  }

  static Map<String, Map<String, String?>>? _fromMetadata(
      List<ElementAnnotation> metadata) {
    for (final annotation in metadata) {
      final value = annotation.computeConstantValue();
      if (value == null) continue;

      final type = value.type;
      if (type == null) continue;

      // Check that this is ExternalVersions from the right library.
      if (type.element?.name != _annotationClass) continue;
      if (type.element?.library?.identifier != _packageUri) continue;

      // Read the `platforms` map field.
      final platformsField = value.getField('platforms');
      if (platformsField == null) continue;

      final platformMap = platformsField.toMapValue();
      if (platformMap == null) continue;

      final result = <String, Map<String, String?>>{};

      for (final entry in platformMap.entries) {
        final platformKey = entry.key?.toStringValue();
        if (platformKey == null) continue;

        final versionValue = entry.value;
        if (versionValue == null) continue;

        // Verify this is an ExternalVersion instance.
        if (versionValue.type?.element?.name != _versionClass) continue;

        final min = versionValue.getField('min')?.toStringValue();
        final max = versionValue.getField('max')?.toStringValue();
        final msg =
            versionValue.getField('deprecationMessage')?.toStringValue();

        result[platformKey] = {
          'min': min,
          'max': max,
          'deprecationMessage': msg,
        };
      }

      return result.isEmpty ? null : result;
    }
    return null;
  }
}
