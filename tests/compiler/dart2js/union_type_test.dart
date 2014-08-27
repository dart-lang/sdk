// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import "compiler_helper.dart";
import "parser_helper.dart";

import "package:compiler/implementation/types/types.dart";
import "package:compiler/implementation/dart_types.dart";

main() {
  asyncTest(() => MockCompiler.create((MockCompiler compiler) {
    compiler.intClass.ensureResolved(compiler);
    compiler.stringClass.ensureResolved(compiler);

    FlatTypeMask mask1 =
        new FlatTypeMask.exact(compiler.intClass);
    FlatTypeMask mask2 =
        new FlatTypeMask.exact(compiler.stringClass);
    UnionTypeMask union1 = mask1.nonNullable().union(mask2, compiler.world);
    UnionTypeMask union2 = mask2.nonNullable().union(mask1, compiler.world);
    Expect.equals(union1, union2);
  }));
}
