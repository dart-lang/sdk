// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This test is indirectly testing invariants of the generated code of dart2js.
/// It ensures that indices to metadata information from **multiple** deferred
/// fragments is kept separate, but that when they are loaded (and the metadata
/// array is merged) all accesses to the metadata array is done correctly.
///
/// This kind of metadata is generated either when using Function.apply (to
/// store default values and parameter names) or when using dart:mirrors
/// (annotations and unmangled names also need to be stored).
///
/// This test covers uses of default values and parameter names via
/// Function.apply.
import 'multiple_default_arg_lib1.dart' deferred as lib1;
import 'multiple_default_arg_lib2.dart' deferred as lib2;
import 'multiple_default_arg_lib3.dart' deferred as lib3;
import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';

main() {
  asyncTest(() async {
    await lib1.loadLibrary();
    await lib2.loadLibrary();

    Expect.equals(
        Function.apply(lib1.myFunction1, [], {#argumentName1: () => "A"}),
        "A - 2");

    Expect.equals(
        Function.apply(lib2.myFunction2, [], {#argumentName4: () => "B"}),
        "3 - B");

    await lib3.loadLibrary();

    Expect.equals(
        Function
            .apply(lib3.myFunction3, ["x", "y"], {#argumentName4: () => "C"}),
        "x y 3b - C");

    Expect.equals(
        Function.apply(lib3.myFunction3, ["x", "y"], {}), "x y 3b - 4b");

    Expect.equals(Function.apply(lib3.myFunction4, ["x", "y"], {}), 5);
    Expect.equals(
        Function.apply(
            lib3.myFunction4, ["x", "y"], {#argumentName5: new lib3.X(4)}),
        4);
    Expect.equals(
        Function
            .apply(lib3.myFunction4, ["x", "y"], {#argumentName5: lib3.value3}),
        3);
  });
}
