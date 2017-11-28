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
/// This test file covers uses of parameter names and default values through
/// dart:mirrors.
@MirrorsUsed(override: '*')
import 'dart:mirrors';
import 'reflect_multiple_default_arg_lib1.dart' deferred as lib1;
import 'reflect_multiple_default_arg_lib2.dart' deferred as lib2;
import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';

main() {
  asyncTest(() async {
    await lib1.loadLibrary();
    await lib2.loadLibrary();

    Expect.equals(Function.apply(lib1.myFunction1, []), 1);
    Expect.equals(Function.apply(lib2.myFunction2, []), 2);

    MethodMirror m1 =
        findTopLevel('multiple_default_arg_lib1.dart', #myFunction1);
    Expect.equals(m1.parameters.length, 1);
    Expect.equals(m1.parameters[0].simpleName, #argumentName1);
    Expect.isTrue(m1.parameters[0].hasDefaultValue);
    Expect.equals((m1.parameters[0].defaultValue.reflectee)(), 1);

    MethodMirror m2 =
        findTopLevel('multiple_default_arg_lib2.dart', #myFunction2);
    Expect.equals(m2.parameters.length, 1);
    Expect.equals(m2.parameters[0].simpleName, #argumentName2);
    Expect.isTrue(m2.parameters[0].hasDefaultValue);
    Expect.equals((m2.parameters[0].defaultValue.reflectee)(), 2);
  });
}

MethodMirror findTopLevel(String uriSuffix, Symbol name) {
  MethodMirror method;
  currentMirrorSystem().libraries.forEach((uri, lib) {
    if (uri.path.endsWith(uriSuffix)) method = lib.declarations[name];
  });
  print(method);
  return method;
}
