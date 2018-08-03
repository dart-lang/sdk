// Copyright (c) 2015, the Dart Team. All rights reserved. Use of this
// source code is governed by a BSD-style license that can be found in
// the LICENSE file.

library lib1;

import "deferred_type_dependency_lib3.dart";

bool fooIs(x) {
  return x is A;
}

bool fooAs(x) {
  try {
    return (x as A).p;
  } on CastError catch (e) {
    return false;
  }
}

bool fooAnnotation(x) {
  try {
    A y = x;
    return y is! String;
  } on TypeError catch (e) {
    return false;
  }
}
