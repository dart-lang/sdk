// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library docgen.models.generic;

import '../exports/source_mirrors.dart';
import '../exports/mirrors_util.dart' as dart2js_util;

import 'mirror_based.dart';

/// A Docgen wrapper around the dart2js mirror for a generic type.
class Generic extends MirrorBased<TypeVariableMirror> {
  final TypeVariableMirror mirror;

  Generic(this.mirror);

  Map toMap() => {
    'name': dart2js_util.nameOf(mirror),
    'type': dart2js_util.qualifiedNameOf(mirror.upperBound)
  };
}
