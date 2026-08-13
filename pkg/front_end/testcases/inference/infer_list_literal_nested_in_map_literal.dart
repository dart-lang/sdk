// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

class Folder {}

class Resource extends Folder {}

Resource getResource(String str) => throw '';

class Foo<T> {
  Foo(T t);
}

test() {
  // List inside map
  var map = <String, List<Folder>>{
    'pkgA': [getResource('/pkgA/lib/')],
    'pkgB': [getResource('/pkgB/lib/')],
  };
  // Also try map inside list
  var list = <Map<String, Folder>>[
    {'pkgA': getResource('/pkgA/lib/')},
    {'pkgB': getResource('/pkgB/lib/')},
  ];
  // Instance creation too
  var foo = new Foo<List<Folder>>([getResource('/pkgA/lib/')]);
}
