// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library docgen.models.annotation;

import '../exports/mirrors_util.dart' as dart2js_util;
import '../exports/source_mirrors.dart';

import '../library_helpers.dart';

import 'library.dart';
import 'mirror_based.dart';

/// Holds the name of the annotation, and its parameters.
class Annotation extends MirrorBased {
  /// The class of this annotation.
  final ClassMirror mirror;
  final Library owningLibrary;
  List<String> parameters;

  Annotation(InstanceMirror originalMirror, this.owningLibrary)
      : mirror = originalMirror.type {
    parameters = dart2js_util.variablesOf(originalMirror.type.declarations)
        .where((e) => e.isFinal)
        .map((e) => originalMirror.getField(e.simpleName).reflectee)
        .where((e) => e != null)
        .toList();
  }

  Map toMap() => {
    'name': getDocgenObject(mirror, owningLibrary).docName,
    'parameters': parameters
  };
}
