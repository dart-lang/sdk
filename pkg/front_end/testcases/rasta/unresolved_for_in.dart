// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'dart:collection' as collection;

typedef void VoidFunction();

class Fisk {
  it1(x) {
    for (key in x) {
      print(key);
    }
    for (Fisk in x) {
      print(Fisk);
    }
    for (collection in x) {
      print(collection);
    }
    for (VoidFunction in x) {
      print(VoidFunction);
    }
    for (1 in x) {
      print(key);
    }
  }
}

main(arguments) {
  new Fisk();
  for (key in arguments) {
    print(key);
  }
  for (Fisk in arguments) {
    print(Fisk);
  }
  for (collection in arguments) {
    print(collection);
  }
  for (VoidFunction in arguments) {
    print(VoidFunction);
  }
  for (1 in arguments) {
    print(key);
  }
}
