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
/// This test file covers uses of annotations through dart:mirrors.
@MirrorsUsed(override: '*')
import 'dart:mirrors';
import 'reflect_multiple_annotations_lib1.dart' deferred as lib1;
import 'reflect_multiple_annotations_lib2.dart' deferred as lib2;
import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';

main() {
  asyncTest(() async {
    await lib1.loadLibrary();
    await lib2.loadLibrary();

    MethodMirror m1 =
        findTopLevel('multiple_annotations_lib1.dart', #myFunction1);
    Expect.equals(m1.metadata.length, 2);

    Expect.equals(m1.parameters.length, 1);
    Expect.equals(m1.parameters[0].simpleName, #f1);
    Expect.isFalse(m1.parameters[0].hasDefaultValue);
    Expect.equals(m1.parameters[0].metadata.length, 1);

    // Note: currently m1.metadata[*].reflectee is null, even though this works
    // when not using deferred libraries.
    // TODO(sigmund): fix if we do not move forward with Issue #30538.
    //Expect.isTrue(lib1.MetaA.isCheck(m1.metadata[0].reflectee));
    //Expect.isTrue(lib1.MetaA.isCheck(m1.metadata[1].reflectee));
    //Expect.equals(m1.metadata[0].reflectee.value, "one");
    //Expect.equals(m1.metadata[1].reflectee.value, lib1.topLevelF);
    //Expect.isTrue(lib1.MetaA.isCheck(m1.parameters[0].metadata[0].reflectee));
    //Expect.equals(m1.parameters[0].metadata[0].reflectee.value, "param");

    LibraryMirror l2 = findLibrary('multiple_annotations_lib2.dart');
    Expect.equals(l2.metadata.length, 1);
    print(l2.metadata[0].reflectee);
    Expect.equals(l2.metadata[0].reflectee.value, "lib");

    ClassMirror c2 = findClass('multiple_annotations_lib2.dart', #A);
    Expect.equals(c2.simpleName, #A);
    Expect.equals(c2.metadata.length, 1);
    print(c2.metadata[0].reflectee);
    Expect.equals(c2.metadata[0].reflectee.value, "class");
  });
}

MethodMirror findTopLevel(String uriSuffix, Symbol name) {
  MethodMirror method;
  currentMirrorSystem().libraries.forEach((uri, lib) {
    if (uri.path.endsWith(uriSuffix)) method = lib.declarations[name];
  });
  return method;
}

ClassMirror findClass(String uriSuffix, Symbol name) {
  ClassMirror cls;
  currentMirrorSystem().libraries.forEach((uri, lib) {
    if (uri.path.endsWith(uriSuffix)) cls = lib.declarations[name];
  });
  return cls;
}

LibraryMirror findLibrary(String uriSuffix) {
  LibraryMirror lib;
  currentMirrorSystem().libraries.forEach((uri, l) {
    if (uri.path.endsWith(uriSuffix)) lib = l;
  });
  return lib;
}
