// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This tests uses the multi-test "ok" feature:
// none: Trimmed behaviour. Passing on the VM.
// 01: Trimmed version for dart2js.
// 02: Full version passing in the VM.
//
// TODO(rmacnak,ahe): Remove multi-test when VM and dart2js are on par.

library test.class_equality_test;

import 'dart:mirrors';

import 'package:expect/expect.dart';

class A<T> {}
class B extends A<int> {}

class BadEqualityHash {
  int count = 0;
  bool operator ==(other) => true;
  int get hashCode => count++;
}

typedef bool Predicate(Object o);
Predicate somePredicate;

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
      .findLibrary(const Symbol('test.class_equality_test'));

  var o1 = new Object();
  var o2 = new Object();

  var badEqualityHash1 = new BadEqualityHash();
  var badEqualityHash2 = new BadEqualityHash();

  checkEquality([
    {'reflect(o1)' : reflect(o1),
     'reflect(o1), again' : reflect(o1)},

    {'reflect(o2)' : reflect(o2),
     'reflect(o2), again' : reflect(o2)},

    {'reflect(badEqualityHash1)' : reflect(badEqualityHash1),
     'reflect(badEqualityHash1), again' : reflect(badEqualityHash1)},

    {'reflect(badEqualityHash2)' : reflect(badEqualityHash2),
     'reflect(badEqualityHash2), again' : reflect(badEqualityHash2)},

    {'reflect(true)' : reflect(true),
     'reflect(true), again' : reflect(true)},

    {'reflect(false)' : reflect(false),
     'reflect(false), again' : reflect(false)},

    {'reflect(null)' : reflect(null),
     'reflect(null), again' : reflect(null)},

    {'reflect(3.5+4.5)' : reflect(3.5+4.5),
     'reflect(6.5+1.5)' : reflect(6.5+1.5)},

    {'reflect(3+4)' : reflect(3+4),
     'reflect(6+1)' : reflect(6+1)},

    {'reflect("foo")' : reflect("foo"),
     'reflect("foo"), again' : reflect("foo")},

    {'currentMirrorSystem().voidType' : currentMirrorSystem().voidType,
     'thisLibrary.declarations[#subroutine].returnType' :
          (thisLibrary.declarations[#subroutine] as MethodMirror).returnType},

    {'currentMirrorSystem().dynamicType' : currentMirrorSystem().dynamicType,
     'thisLibrary.declarations[#main].returnType' :
          (thisLibrary.declarations[#main] as MethodMirror).returnType},

    {'reflectClass(A)' : reflectClass(A),
     'thisLibrary.declarations[#A]' : thisLibrary.declarations[#A],
     'reflect(new A<int>()).type.originalDeclaration' :
          reflect(new A<int>()).type.originalDeclaration},

    {'reflectClass(B).superclass' : reflectClass(B).superclass,
     'reflect(new A<int>()).type' : reflect(new A<int>()).type},

    {'reflectClass(B)' : reflectClass(B),
     'thisLibrary.declarations[#B]' : thisLibrary.declarations[#B],
     'reflect(new B()).type' : reflect(new B()).type},

    {'reflectClass(BadEqualityHash).declarations[#==]'
        : reflectClass(BadEqualityHash).declarations[#==],
     'reflect(new BadEqualityHash()).type.declarations[#==]'
        : reflect(new BadEqualityHash()).type.declarations[#==]},

    {'reflectClass(BadEqualityHash).declarations[#==].parameters[0]'
        : (reflectClass(BadEqualityHash).
            declarations[#==] as MethodMirror).parameters[0],
     'reflect(new BadEqualityHash()).type.declarations[#==].parameters[0]'
        : (reflect(new BadEqualityHash()).type.
            declarations[#==] as MethodMirror).parameters[0]},

    {'reflectClass(BadEqualityHash).declarations[#count]'
        : reflectClass(BadEqualityHash).declarations[#count],
     'reflect(new BadEqualityHash()).type.declarations[#count]'
        : reflect(new BadEqualityHash()).type.declarations[#count]},

    {'reflectType(Predicate)' : reflectType(Predicate),
     'thisLibrary.declarations[#somePredicate].type'
        : (thisLibrary.declarations[#somePredicate] as VariableMirror).type},

    {'reflectType(Predicate).referent' : (reflectType(Predicate) as TypedefMirror).referent,
     'thisLibrary.declarations[#somePredicate].type.referent'
        : ((thisLibrary.declarations[#somePredicate] as VariableMirror).type as TypedefMirror).referent},

    {'reflectClass(A).typeVariables.single'
        : reflectClass(A).typeVariables.single,
     'reflect(new A<int>()).type.originalDeclaration.typeVariables.single'
        : reflect(new A<int>()).type.originalDeclaration.typeVariables.single},

    {'currentMirrorSystem()' : currentMirrorSystem()},

    {'currentMirrorSystem().isolate' : currentMirrorSystem().isolate},

    {'thisLibrary' : thisLibrary,
     'reflectClass(A).owner' : reflectClass(A).owner,
     'reflectClass(B).owner' : reflectClass(B).owner,
     'reflect(new A()).type.owner' : reflect(new A()).type.owner,
     'reflect(new B()).type.owner' : reflect(new B()).type.owner},
  ]);
}
