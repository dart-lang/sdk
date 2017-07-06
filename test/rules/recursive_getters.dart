// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N recursive_getters`

class C {
  final int _field = 0;

  int get field => field; // LINT

  int get otherField {
    return otherField; // LINT
  }

  int get correct => _field;

  int get correctBody {
    return _field;
  }

  int someMethod() => someMethod();

  int get value => plusOne(value); // LINT
}

int _field = 0;

int get field => field; // LINT

int get otherField {
  return otherField; // LINT
}

int get correct => _field;

int get correctBody {
  return _field;
}

int get value => _field == null ? 0 : value; // LINT

int plusOne(int arg) => 0;

// https://github.com/dart-lang/linter/issues/586
class Nested {
  final Nested _parent;

  Nested(this._parent);

  Nested get ancestor => _parent.ancestor; //OK

  Nested get thisRecursive => this.thisRecursive; // LINT

  Nested get recursive => recursive; // LINT
}
