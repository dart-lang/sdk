// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.toplevel_members;

import 'dart:mirrors';
import 'package:expect/expect.dart';

import 'stringify.dart';
import 'declarations_model.dart' as declarations_model;

selectKeys(map, predicate) {
  return map.keys.where((key) => predicate(map[key]));
}

main() {
  LibraryMirror lm =
      currentMirrorSystem().findLibrary(#test.declarations_model);

  Expect.setEquals(
    [#libraryVariable,
     const Symbol('libraryVariable='),
     #libraryGetter,
     const Symbol('librarySetter='),
     #libraryMethod,
     MirrorSystem.getSymbol('_libraryVariable', lm),
     MirrorSystem.getSymbol('_libraryVariable=', lm),
     MirrorSystem.getSymbol('_libraryGetter', lm),
     MirrorSystem.getSymbol('_librarySetter=', lm),
     MirrorSystem.getSymbol('_libraryMethod', lm),
     #Predicate,  /// 01: ok
     #Superclass,  /// 01: continued
     #Interface,  /// 01: continued
     #Mixin,  /// 01: continued
     #Class,  /// 01: continued
     MirrorSystem.getSymbol('_PrivateClass', lm),  /// 01: continued
     #ConcreteClass  /// 01: continued
     ],
    selectKeys(lm.topLevelMembers, (dm) => true));

  Expect.setEquals(
    [#libraryVariable,
     const Symbol('libraryVariable='),
     MirrorSystem.getSymbol('_libraryVariable', lm),
     MirrorSystem.getSymbol('_libraryVariable=', lm),
     #Predicate,  /// 01: continued
     #Superclass,  /// 01: continued
     #Interface,  /// 01: continued
     #Mixin,  /// 01: continued
     #Class,  /// 01: continued
     MirrorSystem.getSymbol('_PrivateClass', lm),  /// 01: continued
     #ConcreteClass  /// 01: continued
     ],
    selectKeys(lm.topLevelMembers, (dm) => dm.isSynthetic));
}
