// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'unordered_constructor.dart';

augment class Class1 {
  @annotation2
  augment new();

  @annotation2
  augment new alias();

  @annotation2
  augment factory fact();

  @annotation2
  augment factory redirect();
}

augment class Class2 {
  @annotation2
  augment new();

  @annotation2
  augment new alias();

  @annotation2
  augment factory fact();

  @annotation2
  augment factory redirect();
}

augment class Class3 {
  augment new() {
    print('Class3.new');
  }

  augment new alias() : this();

  augment factory fact() {
    print('Class3.fact');
    return Class3();
  }

  augment factory redirect() = Class3;
}

