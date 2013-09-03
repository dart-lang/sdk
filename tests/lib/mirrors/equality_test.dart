// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.class_equality_test;

import 'dart:mirrors';

import 'package:expect/expect.dart';

class A<T> {}
class B extends A<int> {}

checkEquality(List<Map> equivalenceClasses) {
  for (var equivalenceClass in equivalenceClasses) {
    equivalenceClass.forEach((name, member) {
      equivalenceClass.forEach((otherName, otherMember) {
        // Reflexivity, symmetry and transitivity.
        Expect.equals(member, 
                      otherMember,
                      "$name == $otherName");
        Expect.equals(member.hashCode,
                      otherMember.hashCode,
                      "$name.hashCode == $otherName.hashCode");
      });
      for (var otherEquivalenceClass in equivalenceClasses) {
        if (otherEquivalenceClass == equivalenceClass) continue;
        otherEquivalenceClass.forEach((otherName, otherMember) {
          Expect.notEquals(member,
                           otherMember,
                           "$name != $otherName");  // Exclusion.
          // Hash codes may or may not be equal.
        });
      }
    });
  }
}

void subroutine() {
}

main() {
  LibraryMirror thisLibrary =
      currentMirrorSystem()
      .findLibrary(const Symbol('test.class_equality_test'))
      .single;

  Object o1 = new Object();
  Object o2 = new Object();

  checkEquality([
    {'reflect(o1)' : reflect(o1),
     'reflect(o1), again' : reflect(o1)},

    {'reflect(o2)' : reflect(o2),
     'reflect(o2), again' : reflect(o2)},

    {'reflect(3+4)' : reflect(3+4),
     'reflect(6+1)' : reflect(6+1)},

    {'currentMirrorSystem().voidType' : currentMirrorSystem().voidType,
     'thisLibrary.functions[#subroutine].returnType' :
          thisLibrary.functions[const Symbol('subroutine')].returnType},

    {'currentMirrorSystem().dynamicType' : currentMirrorSystem().dynamicType,
     'thisLibrary.functions[#main].returnType' :
          thisLibrary.functions[const Symbol('main')].returnType},

    {'reflectClass(A)' : reflectClass(A),
     'thisLibrary.classes[#A]' : thisLibrary.classes[const Symbol('A')],
     'reflect(new A<int>()).type.originalDeclaration' :
          reflect(new A<int>()).type.originalDeclaration},

    {'reflectClass(B).superclass' : reflectClass(B).superclass,
     'reflect(new A<int>()).type' : reflect(new A<int>()).type},

    {'reflectClass(B)' : reflectClass(B),
     'thisLibrary.classes[#B]' : thisLibrary.classes[const Symbol('B')],
     'reflect(new B()).type' : reflect(new B()).type},

    {'thisLibrary' : thisLibrary,
     'reflectClass(A).owner' : reflectClass(A).owner,
     'reflectClass(B).owner' : reflectClass(B).owner,
     'reflect(new A()).type.owner' : reflect(new A()).type.owner,
     'reflect(new A()).type.owner' : reflect(new A()).type.owner},
  ]);
}
