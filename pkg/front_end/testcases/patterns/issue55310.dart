// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Other {
  String text = 42.toString();
}

class Inner {
  Other? other = int.parse('3') == 3 ? Other() : null;
}

sealed class Wrapper {}

class WrapperA extends Wrapper {
  Inner inner = Inner();
}

class WrapperB extends Wrapper {
  Inner inner = Inner();
}

var obj = int.parse('1') == 1 ? WrapperB() : WrapperA();

void main() {
  foo(obj);
}

void foo(Wrapper wrapper) {
  print(switch (wrapper) {
    WrapperA(inner: Inner(other: final Other other)) => other.text,
    WrapperA(inner: Inner(other: null)) => "no other",
    WrapperB(inner: Inner(other: final Other other)) => other.text,
    WrapperB(inner: Inner(other: null)) => "no other",
  });
}
