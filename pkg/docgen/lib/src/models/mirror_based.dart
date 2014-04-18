// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library docgen.models.mirror_based;

import '../exports/source_mirrors.dart';

/// Docgen representation of an item to be documented, that wraps around a
/// dart2js mirror.
abstract class MirrorBased<TMirror extends DeclarationMirror> {
  /// The original dart2js mirror around which this object wraps.
  TMirror get mirror;

  /// Return an informative [Object.toString] for debugging.
  String toString() => "${super.toString()} - $mirror";
}
