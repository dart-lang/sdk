// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test_common;

import 'dart:collection';

import 'package:unittest/unittest.dart';

class Widget {
  int price;
}

class HasPrice extends CustomMatcher {
  HasPrice(matcher) :
    super("Widget with a price that is", "price", matcher);
  featureValueOf(actual) => actual.price;
}

class SimpleIterable extends IterableBase {
  int count;
  SimpleIterable(this.count);

  bool contains(int val) => count < val ? false : true;

  bool any(bool f(element)) {
    for (var i = 0; i <= count; i++) {
      if (f(i)) return true;
    }
    return false;
  }

  String toString() => "<[$count]>";

  Iterator get iterator {
    return new SimpleIterator(count);
  }
}

class SimpleIterator implements Iterator {
  int _count;
  int _current;

  SimpleIterator(this._count);

  bool moveNext() {
    if (_count > 0) {
      _current = _count;
      _count--;
      return true;
    }
    _current = null;
    return false;
  }

  get current => _current;
}

