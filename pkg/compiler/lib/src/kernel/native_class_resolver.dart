// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.kernel.element_map;

/// Interface for computing all native classes in a set of libraries.
class KernelNativeClassResolver implements NativeClassResolver {
  final KernelToElementMap elementMap;

  KernelNativeClassResolver(this.elementMap);

  Iterable<ClassEntity> computeNativeClasses(
      Iterable<LibraryEntity> libraries) {
    // TODO(johnniwinther): Implement this.
    return const <ClassEntity>[];
  }
}
