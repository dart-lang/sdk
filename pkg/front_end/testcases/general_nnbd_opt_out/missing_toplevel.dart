// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

class EmptyClass {}

var emptyClass = new EmptyClass();

class ClassWithProperty {
  EmptyClass property;
}

var classWithProperty = new ClassWithProperty();

class ClassWithIndexSet {
  operator []=(int index, int value) {}
}

var classWithIndexSet = new ClassWithIndexSet();

class ClassWithIndexGet {
  int operator [](int index) => 42;
}

var classWithIndexGet = new ClassWithIndexGet();

var missingBinary = classWithProperty.property += 2;
var missingIndexGet = classWithIndexSet[0] ??= 2;
var missingIndexSet = classWithIndexGet[0] ??= 2;
var missingPropertyGet = emptyClass.property;
var missingPropertySet = emptyClass.property = 42;

main() {}
