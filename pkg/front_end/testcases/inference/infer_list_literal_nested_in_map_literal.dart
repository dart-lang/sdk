// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class Resource {}

class Folder extends Resource {}

Resource getResource(String str) => null;

class Foo<T> {
  Foo(T t);
}

main() {
  // List inside map
  var /*@type=Map<String, List<Folder>>*/ map = <String, List<Folder>>{
    'pkgA': /*@typeArgs=Folder*/ [
      /*info:DOWN_CAST_IMPLICIT*/ getResource('/pkgA/lib/')
    ],
    'pkgB': /*@typeArgs=Folder*/ [
      /*info:DOWN_CAST_IMPLICIT*/ getResource('/pkgB/lib/')
    ]
  };
  // Also try map inside list
  var /*@type=List<Map<String, Folder>>*/ list = <Map<String, Folder>>[
    /*@typeArgs=String, Folder*/ {
      'pkgA': /*info:DOWN_CAST_IMPLICIT*/ getResource('/pkgA/lib/')
    },
    /*@typeArgs=String, Folder*/ {
      'pkgB': /*info:DOWN_CAST_IMPLICIT*/ getResource('/pkgB/lib/')
    },
  ];
  // Instance creation too
  var /*@type=Foo<List<Folder>>*/ foo = new Foo<List<Folder>>(
      /*@typeArgs=Folder*/ [
        /*info:DOWN_CAST_IMPLICIT*/ getResource('/pkgA/lib/')
      ]);
}
