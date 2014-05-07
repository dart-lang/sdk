// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library docgen.models.parameter;

import '../exports/mirrors_util.dart' as dart2js_util;
import '../exports/source_mirrors.dart';

import 'annotation.dart';
import 'closure.dart';
import 'doc_gen_type.dart';
import 'library.dart';
import 'mirror_based.dart';
import 'model_helpers.dart';

/// Docgen wrapper around the dart2js mirror for a Dart
/// method/function parameter.
class Parameter extends MirrorBased {
  final ParameterMirror mirror;
  final String name;
  final bool isOptional;
  final bool isNamed;
  final bool hasDefaultValue;
  final DocGenType type;
  final String defaultValue;
  /// List of the meta annotations on the parameter.
  final List<Annotation> annotations;
  final Library owningLibrary;
  // Only non-null if this parameter is a function declaration.
  Closure functionDeclaration;

  Parameter(ParameterMirror mirror, Library owningLibrary)
      : this.mirror = mirror,
        name = dart2js_util.nameOf(mirror),
        isOptional = mirror.isOptional,
        isNamed = mirror.isNamed,
        hasDefaultValue = mirror.hasDefaultValue,
        defaultValue = getDefaultValue(mirror),
        type = new DocGenType(mirror.type, owningLibrary),
        annotations = createAnnotations(mirror, owningLibrary),
        owningLibrary = owningLibrary {
    if (mirror.type is FunctionTypeMirror) {
      functionDeclaration =
          new Closure(mirror.type as FunctionTypeMirror, owningLibrary);
    }
  }

  /// Generates a map describing the [Parameter] object.
  Map toMap() {
    var map = {
      'name': name,
      'optional': isOptional,
      'named': isNamed,
      'default': hasDefaultValue,
      'type': new List.filled(1, type.toMap()),
      'value': defaultValue,
      'annotations': annotations.map((a) => a.toMap()).toList()
    };
    if (functionDeclaration != null) {
      map['functionDeclaration'] = functionDeclaration.toMap();
    }
    return map;
  }
}