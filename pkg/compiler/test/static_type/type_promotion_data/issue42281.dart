// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

class Class {
  final Type componentType;

  Class(this.componentType);
}

class SubClass extends Class {
  SubClass(Type componentType) : super(/*{}*/ componentType);
}

method1(Class c, Type type, [o]) {
  if (/*{}*/ c == null) {
    if (/*{c:[{false:Class}|Class]}*/ o != null) {
      c = new Class(String);
    }
    /*{}*/ c;
    print(/*{}*/ type == /*{}*/ c?.componentType);
  }
}

method2(Class c, Type type, [o]) {
  if (/*{}*/ c == null) {
    if (/*{c:[{false:Class}|Class]}*/ o != null) {
      c = new SubClass(String);
    }
    /*{}*/ c;
    print(/*{}*/ type == /*{}*/ c?.componentType);
  }
}

method3(Class c, Type type, [o]) {
  if (/*{}*/ c is SubClass) {
    if (/*{c:[{true:SubClass}|SubClass]}*/ c == null) {
      if (/*{c:[{true:SubClass,false:Class}|SubClass,Class]}*/ o != null) {
        c = new SubClass(String);
      }
      /*{c:[{true:SubClass},{false:Class}|SubClass,Class]}*/ c;
      print(
          /*{c:[{true:SubClass},{false:Class}|SubClass,Class]}*/ type ==
              /*{c:[{true:SubClass},{false:Class}|SubClass,Class]}*/ c
                  ?.componentType);
    }
  }
}

main() {
  method1(new Class(Object), Object);
  method1(new Class(Object), Object, true);
  method1(null, Object);
  method1(null, Object, true);

  method2(new Class(Object), Object);
  method2(new Class(Object), Object, true);
  method2(null, Object);
  method2(null, Object, true);

  method3(new Class(Object), Object);
  method3(new Class(Object), Object, true);
  method3(null, Object);
  method3(null, Object, true);
}
