// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'unordered_constructor.dart';

augment class Class1 {
  @annotation1
  augment new();

  @annotation1
  augment new alias();

  @annotation1
  augment factory fact();

  @annotation1
  augment factory redirect();
}

augment class Class2 {
  augment new() {
    print('Class2.new');
  }

  augment new alias() : this();

  augment factory fact() {
    print('Class2.fact');
    return Class2();
  }

  augment factory redirect() = Class2;
}

augment class Class3 {
  @annotation2
  augment new();

  @annotation2
  augment new alias();

  @annotation2
  augment factory fact();

  @annotation2
  augment factory redirect();
}

