// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.backend_strategy;

import 'compiler.dart';
import 'js_emitter/sorter.dart';
import 'world.dart';

/// Strategy pattern that defines the element model used in type inference
/// and code generation.
abstract class BackendStrategy {
  /// Create the [ClosedWorldRefiner] for [closedWorld].
  ClosedWorldRefiner createClosedWorldRefiner(ClosedWorld closedWorld);

  /// Create closure classes for local functions.
  void convertClosures(ClosedWorldRefiner closedWorldRefiner);

  /// The [Sorter] used for sorting elements in the generated code.
  Sorter get sorter;
}

/// Strategy for using the [Element] model from the resolver as the backend
/// model.
class ElementBackendStrategy implements BackendStrategy {
  final Compiler _compiler;

  ElementBackendStrategy(this._compiler);

  ClosedWorldRefiner createClosedWorldRefiner(ClosedWorldImpl closedWorld) =>
      closedWorld;

  Sorter get sorter => const ElementSorter();

  void convertClosures(ClosedWorldRefiner closedWorldRefiner) {
    _compiler.closureToClassMapper.createClosureClasses(closedWorldRefiner);
  }
}
