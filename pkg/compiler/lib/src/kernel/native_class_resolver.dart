// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.kernel.world_builder;

/// Interface for computing all native classes in a set of libraries.
class KernelNativeClassResolver implements NativeClassResolver {
  final KernelWorldBuilder _worldBuilder;

  KernelNativeClassResolver(this._worldBuilder);

  Iterable<ClassEntity> computeNativeClasses(
      Iterable<LibraryEntity> libraries) {
    // TODO(johnniwinther): Implement this.
    return const <ClassEntity>[];
  }
}
