// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Basic test of Symbol class.

main() {
  var x;
  print(x = const Symbol('fisk'));
  try {
    print(const Symbol(0)); //# 01: compile-time error
  } on NoSuchMethodError {
    print('Caught NoSuchMethodError');
  } on TypeError {
    print('Caught TypeError');
  }

  try {
    print(const Symbol('0')); //# 02: compile-time error
  } on ArgumentError catch (e) {
    print('Caught $e');
  }

  try {
    print(const Symbol('_')); //# 03: compile-time error
  } on ArgumentError catch (e) {
    print('Caught $e');
  }

  try {
    var y = 0;
    print(new Symbol(y)); //# 04: compile-time error
    throw 'Expected a NoSuchMethodError or a TypeError'; //# 04: ok
  } on NoSuchMethodError {
    print('Caught NoSuchMethodError');
  } on TypeError {
    print('Caught TypeError');
  }

  try {
    print(new Symbol('0'));
    throw 'Expected an ArgumentError';
  } on ArgumentError catch (e) {
    print('Caught $e');
  }

  try {
    print(new Symbol('_'));
    throw 'Expected an ArgumentError';
  } on ArgumentError catch (e) {
    print('Caught $e');
  }

  if (!identical(const Symbol('fisk'), x)) {
    throw 'Symbol constant is not canonicalized';
  }

  if (const Symbol('fisk') != x) {
    throw 'Symbol constant is not equal to itself';
  }

  if (const Symbol('fisk') != new Symbol('fisk')) {
    throw 'Symbol constant is not equal to its non-const equivalent';
  }

  if (new Symbol('fisk') != new Symbol('fisk')) {
    throw 'new Symbol is not equal to its equivalent';
  }

  if (new Symbol('fisk') == new Symbol('hest')) {
    throw 'unrelated Symbols are equal';
  }

  if (new Symbol('fisk') == new Object()) {
    throw 'unrelated objects are equal';
  }

  x.hashCode as int;

  new Symbol('fisk').hashCode as int;

  if (new Symbol('fisk').hashCode != x.hashCode) {
    throw "non-const Symbol's hashCode not equal to its const equivalent";
  }

  if (new Symbol('') != const Symbol('')) {
    throw 'empty Symbol not equals to itself';
  }
}
