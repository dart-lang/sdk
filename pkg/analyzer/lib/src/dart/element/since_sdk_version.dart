// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:collection/collection.dart';
import 'package:pub_semver/pub_semver.dart';

class SinceSdkVersionComputer {
  static final RegExp _asLanguageVersion = RegExp(r'^\d+\.\d+$');

  /// The [element] is a `dart:xyz` library, so it can have `@Since` annotations.
  /// Evaluates its annotations and returns the version.
  Version? compute(ElementImpl element) {
    // Must be in a `dart:` library.
    final librarySource = element.librarySource;
    if (librarySource == null || !librarySource.uri.isScheme('dart')) {
      return null;
    }

    // Fields cannot be referenced outside.
    if (element is FieldElementImpl && element.isSynthetic) {
      return null;
    }

    // We cannot add required parameters.
    if (element is ParameterElementImpl && element.isRequired) {
      return null;
    }

    final specified = _specifiedVersion(element);
    final enclosing = element.enclosingElement2?.sinceSdkVersion;
    return specified.maxWith(enclosing);
  }

  /// Returns the parsed [Version], or `null` if wrong format.
  static Version? _parseVersion(String versionStr) {
    // 2.15
    if (_asLanguageVersion.hasMatch(versionStr)) {
      return Version.parse('$versionStr.0');
    }

    // 2.19.3 or 3.0.0-dev.4
    try {
      return Version.parse(versionStr);
    } on FormatException {
      return null;
    }
  }

  /// Returns the maximal specified `@Since()` version, `null` if none.
  static Version? _specifiedVersion(ElementImpl element) {
    Version? result;
    for (final annotation in element.metadata) {
      annotation as ElementAnnotationImpl;
      if (annotation.isDartInternalSince) {
        final arguments = annotation.annotationAst.arguments?.arguments;
        final versionNode = arguments?.singleOrNull;
        if (versionNode is SimpleStringLiteralImpl) {
          final versionStr = versionNode.value;
          final version = _parseVersion(versionStr);
          if (version != null) {
            result = result.maxWith(version);
          }
        }
      }
    }
    return result;
  }
}

extension on Version? {
  Version? maxWith(Version? other) {
    final self = this;
    if (self == null) {
      return other;
    } else if (other == null) {
      return self;
    } else if (self >= other) {
      return self;
    } else {
      return other;
    }
  }
}
