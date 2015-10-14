// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.common.work;

import '../common.dart';
import '../compiler.dart' show
    Compiler;
import '../elements/elements.dart' show
    AstElement;
import '../enqueue.dart' show
    Enqueuer,
    WorldImpact;


/**
 * Contains backend-specific data that is used throughout the compilation of
 * one work item.
 */
class ItemCompilationContext {
}

abstract class WorkItem {
  final ItemCompilationContext compilationContext;
  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: [element] must be a declaration element.
   */
  final AstElement element;

  WorkItem(this.element, this.compilationContext) {
    assert(invariant(element, element.isDeclaration));
  }

  WorldImpact run(Compiler compiler, Enqueuer world);
}
