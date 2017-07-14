// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter.sorter;

import '../elements/elements.dart';
import '../elements/entities.dart';

/// Sorting strategy for libraries, classes and members.
abstract class Sorter {
  /// Returns a sorted list of [libraries].
  Iterable<LibraryEntity> sortLibraries(Iterable<LibraryEntity> libraries);

  /// Returns a sorted list of [classes].
  Iterable<ClassEntity> sortClasses(Iterable<ClassEntity> classes);

  /// Returns a sorted list of [typedefs].
  Iterable<TypedefEntity> sortTypedefs(Iterable<TypedefEntity> typedefs);

  /// Returns a sorted list of [members].
  Iterable<MemberEntity> sortMembers(Iterable<MemberEntity> members);
}

class ElementSorter implements Sorter {
  const ElementSorter();

  @override
  List<LibraryEntity> sortLibraries(Iterable<LibraryEntity> libraries) {
    return Elements.sortedByPosition(new List.from(libraries, growable: false));
  }

  @override
  List<ClassEntity> sortClasses(Iterable<ClassEntity> classes) {
    return Elements.sortedByPosition(new List.from(classes, growable: false));
  }

  @override
  Iterable<TypedefEntity> sortTypedefs(Iterable<TypedefEntity> typedefs) {
    return Elements.sortedByPosition(new List.from(typedefs, growable: false));
  }

  @override
  List<MemberEntity> sortMembers(Iterable<MemberEntity> members) {
    return Elements.sortedByPosition(new List.from(members, growable: false));
  }
}
