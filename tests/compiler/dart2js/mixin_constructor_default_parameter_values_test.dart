// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Ensure that the inferrer looks at default values for parameters in
// synthetic constructors using the correct context. If the constructor call 
// to D without optional parameters is inferred using D's context, the default
// value `_SECRET` will not be visible and compilation will fail.

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'memory_compiler.dart';

const Map MEMORY_SOURCE_FILES = const {
  "main.dart": r"""
  import "liba.dart";

  class Mixin {
      String get foo => "Mixin:$this";
  }

  class D = C with Mixin;

  main() {
    print(new D.a(42).foo);
    print(new D.b(42).foo);
    print(new D.a(42, "overt").foo);
    print(new D.b(42, b:"odvert").foo);
  }
""",
  "liba.dart": r"""
  class _SECRET { const _SECRET(); String toString() => "SECRET!"; }

  class C {
    final int x;
    final y;
    C.a(int x, [var b = const _SECRET()]) : this.x = x, this.y = b;
    C.b(int x, {var b : const _SECRET()}) : this.x = x, this.y = b;
    String toString() => "C($x,$y)";
  }
"""
};

main() {
  var compiler = compilerFor(MEMORY_SOURCE_FILES);  
  asyncTest(() => compiler.run(Uri.parse('memory:main.dart')));
}

