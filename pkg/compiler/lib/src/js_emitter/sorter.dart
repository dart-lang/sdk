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

  int compareLibrariesByLocation(LibraryEntity a, LibraryEntity b);
  int compareClassesByLocation(ClassEntity a, ClassEntity b);
  int compareTypedefsByLocation(TypedefEntity a, TypedefEntity b);
  int compareMembersByLocation(MemberEntity a, MemberEntity b);
}

class ElementSorter implements Sorter {
  const ElementSorter();

  @override
  List<LibraryEntity> sortLibraries(Iterable<LibraryEntity> libraries) {
    return Elements.sortedByPosition(new List.from(libraries, growable: false));
  }

  @override
  List<ClassEntity> sortClasses(Iterable<ClassEntity> classes) {
    List<ClassElement> regularClasses = <ClassElement>[];
    List<MixinApplicationElement> unnamedMixins = <MixinApplicationElement>[];
    for (ClassElement cls in classes) {
      if (cls.isUnnamedMixinApplication) {
        unnamedMixins.add(cls);
      } else {
        regularClasses.add(cls);
      }
    }
    List<ClassEntity> sorted = <ClassEntity>[];
    sorted.addAll(Elements.sortedByPosition<ClassElement>(regularClasses));
    unnamedMixins.sort((a, b) {
      int result = a.name.compareTo(b.name);
      if (result != 0) return result;
      return Elements.compareByPosition(a.mixin, b.mixin);
    });
    sorted.addAll(unnamedMixins);
    return sorted;
  }

  @override
  Iterable<TypedefEntity> sortTypedefs(Iterable<TypedefEntity> typedefs) {
    return Elements.sortedByPosition(new List.from(typedefs, growable: false));
  }

  @override
  List<MemberEntity> sortMembers(Iterable<MemberEntity> members) {
    return Elements.sortedByPosition(new List.from(members, growable: false));
  }

  @override
  int compareLibrariesByLocation(
          covariant LibraryElement a, covariant LibraryElement b) =>
      Elements.compareByPosition(a, b);

  @override
  int compareClassesByLocation(
          covariant ClassElement a, covariant ClassElement b) =>
      Elements.compareByPosition(a, b);

  @override
  int compareTypedefsByLocation(
          covariant TypedefElement a, covariant TypedefElement b) =>
      Elements.compareByPosition(a, b);

  @override
  int compareMembersByLocation(
          covariant MemberElement a, covariant MemberElement b) =>
      Elements.compareByPosition(a, b);
}
