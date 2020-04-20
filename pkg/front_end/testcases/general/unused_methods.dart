// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class UnusedClass {
  UnusedClass() {
    print('Unused');
  }
}

abstract class UsedAsBaseClass {
  void usedInSubclass() {
    print('Unused');
  }

  void calledFromB() {
    this.calledFromSubclass();
  }

  void calledFromSubclass() {
    print('Unused');
  }
}

class UsedAsInterface {
  void usedInSubclass() {
    print('Unused');
  }
}

class InstantiatedButMethodsUnused {
  void usedInSubclass() {
    print('Unused');
  }
}

class ClassA extends UsedAsBaseClass
    implements UsedAsInterface, InstantiatedButMethodsUnused {
  void usedInSubclass() {
    print('A');
  }
}

class ClassB extends UsedAsBaseClass
    implements UsedAsInterface, InstantiatedButMethodsUnused {
  void usedInSubclass() {
    print('B');
    calledFromB();
  }

  void calledFromSubclass() {}
}

void baseClassCall(UsedAsBaseClass object) {
  object.usedInSubclass();
}

void interfaceCall(UsedAsInterface object) {
  object.usedInSubclass();
}

void exactCallA(ClassA object) {
  object.usedInSubclass();
}

void exactCallB(ClassB object) {
  object.usedInSubclass();
}

unusedTopLevel() {
  print('Unused');
}

usedTopLevel() {}

main() {
  usedTopLevel();

  ClassA a = new ClassA();
  exactCallA(a);
  baseClassCall(a);
  interfaceCall(a);

  ClassB b = new ClassB();
  exactCallB(b);
  baseClassCall(b);
  interfaceCall(b);

  new InstantiatedButMethodsUnused();
}
