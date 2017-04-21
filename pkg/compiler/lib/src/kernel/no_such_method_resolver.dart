// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.kernel.world_builder;

class KernelNoSuchMethodResolver implements NoSuchMethodResolver {
  final KernelWorldBuilder _worldBuilder;

  KernelNoSuchMethodResolver(this._worldBuilder);

  @override
  bool hasForwardingSyntax(KFunction method) {
    throw new UnimplementedError(
        "KernelNoSuchMethodResolver.hasForwardingSyntax");
  }

  @override
  bool hasThrowingSyntax(KFunction method) {
    throw new UnimplementedError(
        "KernelNoSuchMethodResolver.hasThrowingSyntax");
  }

  @override
  FunctionEntity getSuperNoSuchMethod(FunctionEntity method) {
    throw new UnimplementedError(
        "KernelNoSuchMethodResolver.getSuperNoSuchMethod");
  }
}
