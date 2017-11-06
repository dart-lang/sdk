// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.deferred_load_data;

import '../compiler.dart' show Compiler;
import '../constants/values.dart' show ConstantValue;
import '../deferred_load.dart';
import '../elements/entities.dart';
import '../elements/elements.dart';

class KernelDeferredLoadTask extends DeferredLoadTask {
  KernelDeferredLoadTask(Compiler compiler) : super(compiler);

  Iterable<ImportElement> importsTo(Element element, LibraryElement library) {
    throw new UnimplementedError("KernelDeferredLoadTask.importsTo");
  }

  String computeImportDeferName(ImportElement declaration, Compiler compiler) {
    throw new UnimplementedError(
        "KernelDeferredLoadTask.computeImportDeferName");
  }

  void checkForDeferredErrorCases(LibraryElement library) {
    // Nothing to do. The FE checks for error cases upfront.
  }

  void collectConstantsInBody(Element element, Set<ConstantValue> constants) {
    throw new UnimplementedError(
        "KernelDeferredLoadTask.collectConstantsInBody");
  }

  /// Adds extra dependencies coming from mirror usage.
  void addDeferredMirrorElements(WorkQueue queue) {
    throw new UnsupportedError(
        "KernelDeferredLoadTask.addDeferredMirrorElements");
  }

  /// Add extra dependencies coming from mirror usage in [root] marking it with
  /// [newSet].
  void addMirrorElementsForLibrary(
      WorkQueue queue, LibraryEntity root, ImportSet newSet) {
    throw new UnsupportedError(
        "KernelDeferredLoadTask.addMirrorElementsForLibrary");
  }
}
