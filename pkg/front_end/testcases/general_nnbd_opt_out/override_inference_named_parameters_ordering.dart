// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

// The test checks that override-based inference for named parameters isn't
// affected by the name-based ordering of the parameters.

class A {
  foo({bool c = true, bool a}) {}
}

class B extends A {
  foo({c = true, bool a}) {}
}

class C extends B {
  foo({bool c = true, bool a}) {}
}

// A1, B1, and C1 are similar to A, B, and C, only they have the names of the
// named parameters swapped, to test that the alternative ordering works.

class A1 {
  foo({bool a = true, bool c}) {}
}

class B1 extends A1 {
  foo({a = true, bool c}) {}
}

class C1 extends B1 {
  foo({bool a = true, bool c}) {}
}

main() {}
