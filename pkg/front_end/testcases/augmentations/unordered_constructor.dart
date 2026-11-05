// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part 'unordered_constructor_part1.dart';
part 'unordered_constructor_part2.dart';

const annotation1 = 1;
const annotation2 = 2;

class Class1 {
  new() {
    print('Class1.new');
  }

  new alias() : this();

  factory fact() {
    print('Class1.fact');
    return Class1();
  }

  factory redirect() = Class1;
}

class Class2 {
  @annotation1
  new();

  @annotation1
  new alias();

  @annotation1
  factory fact();

  @annotation1
  factory redirect();
}

class Class3 {
  @annotation1
  new();

  @annotation1
  new alias();

  @annotation1
  factory fact();

  @annotation1
  factory redirect();
}

