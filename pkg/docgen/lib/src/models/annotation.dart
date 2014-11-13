// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library docgen.models.annotation;

import '../exports/source_mirrors.dart';

import '../library_helpers.dart';

import 'library.dart';
import 'mirror_based.dart';

import 'dart:mirrors';

/// Holds the name of the annotation, and its parameters.
class Annotation extends MirrorBased<ClassMirror> {
  /// The class of this annotation.
  DeclarationMirror mirror;
  final Library owningLibrary;
  List<String> parameters;

  Annotation(this.owningLibrary, this.mirror,
             [List<String> this.parameters = const <String>[]]);

  Map toMap() => {
    'name': owningLibrary.packagePrefix +
        getDocgenObject(mirror, owningLibrary).docName,
    'parameters': parameters
  };
}

