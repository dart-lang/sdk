// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library docgen.models.closure;

import '../exports/source_mirrors.dart';

import 'doc_gen_type.dart';
import 'indexable.dart';
import 'mirror_based.dart';
import 'model_helpers.dart';
import 'parameter.dart';

/// A class containing the properties of a function to be called (used in our
/// case specifically to illustrate evidence of the type of function for a
/// parameter).
class Closure extends MirrorBased<FunctionTypeMirror> {

  /// Parameters for this method.
  final Map<String, Parameter> parameters;
  final DocGenType returnType;
  final FunctionTypeMirror mirror;

  Closure(FunctionTypeMirror mirror, Indexable owner)
    : returnType = new DocGenType(mirror.returnType, owner.owningLibrary),
      parameters = createParameters(mirror.parameters, owner),
      mirror = mirror;

  /// Generates a map describing the [Method] object.
  Map toMap() => {
    'return': [returnType.toMap()],
    'parameters': recurseMap(parameters),
  };
}