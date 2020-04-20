// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter.sorter;

import '../elements/entities.dart';

/// Sorting strategy for libraries, classes and members.
abstract class Sorter {
  /// Returns a sorted list of [libraries].
  Iterable<LibraryEntity> sortLibraries(Iterable<LibraryEntity> libraries);

  /// Returns a sorted list of [classes].
  Iterable<ClassEntity> sortClasses(Iterable<ClassEntity> classes);

  /// Returns a sorted list of [members].
  Iterable<T> sortMembers<T extends MemberEntity>(Iterable<T> members);

  int compareLibrariesByLocation(LibraryEntity a, LibraryEntity b);
  int compareClassesByLocation(ClassEntity a, ClassEntity b);
  int compareMembersByLocation(MemberEntity a, MemberEntity b);
}
