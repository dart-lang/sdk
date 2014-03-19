// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library docgen.models;

import '../../../../sdk/lib/_internal/compiler/implementation/mirrors/source_mirrors.dart';
import '../../../../sdk/lib/_internal/compiler/implementation/mirrors/mirrors_util.dart'
    as dart2js_util;

/// Docgen representation of an item to be documented, that wraps around a
/// dart2js mirror.
abstract class MirrorBased {
  /// The original dart2js mirror around which this object wraps.
  DeclarationMirror get mirror;
}

/// A Docgen wrapper around the dart2js mirror for a generic type.
class Generic extends MirrorBased {
  final TypeVariableMirror mirror;

  Generic(this.mirror);

  Map toMap() => {
    'name': dart2js_util.nameOf(mirror),
    'type': dart2js_util.qualifiedNameOf(mirror.upperBound)
  };
}
