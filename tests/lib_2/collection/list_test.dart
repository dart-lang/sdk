// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import "package:expect/expect.dart";

class MyList<E> extends Object with ListMixin<E> implements List<E> {
  List<E> _list;

  MyList(List<E> this._list);

  int get length => _list.length;

  void set length(int x) {
    _list.length = x;
  }

  E operator [](int idx) => _list[idx];

  void operator []=(int idx, E value) {
    _list[idx] = value;
  }
}

class MyNoSuchMethodList<E> extends Object
    with ListMixin<E>
    implements List<E> {
  List<E> _list;

  MyNoSuchMethodList(List<E> this._list);

  noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #length && invocation.isGetter) {
      return _list.length;
    }
    if (invocation.memberName == const Symbol("length=") &&
        invocation.isSetter) {
      _list.length = invocation.positionalArguments.first;
      return null;
    }
    if (invocation.memberName == const Symbol("[]") &&
        invocation.positionalArguments.length == 1) {
      return _list[invocation.positionalArguments.first];
    }
    if (invocation.memberName == const Symbol("[]=") &&
        invocation.positionalArguments.length == 2) {
      _list[invocation.positionalArguments.first] =
          invocation.positionalArguments[1];
      return null;
    }
    return super.noSuchMethod(invocation);
  }
}

// Class that behaves like a list but does not implement List.
class MyIndexableNoSuchMethod<E> {
  List<E> _list;

  MyIndexableNoSuchMethod(List<E> this._list);

  noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #length && invocation.isGetter) {
      return _list.length;
    }
    if (invocation.memberName == const Symbol("length=") &&
        invocation.isSetter) {
      _list.length = invocation.positionalArguments.first;
      return null;
    }
    if (invocation.memberName == const Symbol("prototype")) {
      return 42;
    }

    if (invocation.memberName == const Symbol("[]") &&
        invocation.positionalArguments.length == 1) {
      return _list[invocation.positionalArguments.first];
    }
    if (invocation.memberName == const Symbol("[]=") &&
        invocation.positionalArguments.length == 2) {
      _list[invocation.positionalArguments.first] =
          invocation.positionalArguments[1];
      return null;
    }
    return super.noSuchMethod(invocation);
  }
}

void testRetainWhere() {
  List<int> list = <int>[1, 2, 3];
  list.retainWhere((x) => x % 2 == 0);
  Expect.equals(1, list.length);
  Expect.equals(2, list.first);
  Expect.equals(2, list[0]);

  list = new MyList<int>([1, 2, 3]);
  list.retainWhere((x) => x % 2 == 0);
  Expect.equals(1, list.length);
  Expect.equals(2, list.first);
  Expect.equals(2, list[0]);

  list = new MyNoSuchMethodList<int>([1, 2, 3]);
  list.retainWhere((x) => x % 2 == 0);
  Expect.equals(1, list.length);
  Expect.equals(2, list.first);
  Expect.equals(2, list[0]);

  // Equivalent tests where the type of the List is known statically.
  {
    var l = new MyList<int>([1, 2, 3]);
    l.retainWhere((x) => x % 2 == 0);
    Expect.equals(1, l.length);
    Expect.equals(2, l.first);
    Expect.equals(2, l[0]);
  }

  {
    var l = new MyNoSuchMethodList<int>([1, 2, 3]);
    l.retainWhere((x) => x % 2 == 0);
    Expect.equals(1, l.length);
    Expect.equals(2, l.first);
    Expect.equals(2, l[0]);
  }

  // Equivalent tests where the type of the List is not known.
  {
    dynamic l = new MyList<int>([1, 2, 3]);
    l.retainWhere((x) => x % 2 == 0);
    Expect.equals(1, l.length);
    Expect.equals(2, l.first);
    Expect.equals(2, l[0]);
  }

  {
    dynamic l = new MyNoSuchMethodList<int>([1, 2, 3]);
    l.retainWhere((x) => x % 2 == 0);
    Expect.equals(1, l.length);
    Expect.equals(2, l.first);
    Expect.equals(2, l[0]);
  }

  {
    dynamic indexable = new MyIndexableNoSuchMethod<int>([1, 2, 3]);
    Expect.equals(3, indexable.length);
    Expect.equals(1, indexable[0]);
    Expect.equals(3, indexable[2]);
    indexable.length = 2;
    Expect.equals(2, indexable.length);
    Expect.equals(42, indexable.prototype);
  }
}

void main() {
  testRetainWhere();
}
