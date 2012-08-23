// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _Expando<T> implements Expando<T> {
  final String name;

  const _Expando([String this.name]);

  T operator[](Object object) {
    checkType(object);
    var weak_property = find(this);
    var list = weak_property.value;
    var do_compact = false;
    var result = null;
    for (int i = 0; i < list.length; ++i) {
      var key = list[i].key;
      if (key === object) {
        result = list[i].value;
        break;
      }
      if (key === null) {
        do_compact = true;
        list[i] = null;
      }
    }
    if (do_compact) {
      weak_property.value = list.filter((e) => (e !== null));
    }
    return result;
  }

  void operator[]=(Object object, T value) {
    checkType(object);
    var weak_property = find(this);
    var list = weak_property.value;
    var do_compact = false;
    int i = 0;
    for (; i < list.length; ++i) {
      var key = list[i].key;
      if (key === object) {
        break;
      }
      if (key === null) {
        do_compact = true;
        list[i] = null;
      }
    }
    if (i !== list.length && value === null) {
      do_compact = true;
      list[i] = null;
    } else if (i !== list.length) {
      list[i].value = value;
    } else {
      list.add(new _WeakProperty(object, value));
    }
    if (do_compact) {
      weak_property.value = list.filter((e) => (e !== null));
    }
  }

  String toString() => "Expando:$name";

  static checkType(object) {
    if (object === null) {
      throw new NullPointerException();
    }
    if (object is bool || object is num || object is String) {
      throw new IllegalArgumentException(object);
    }
  }

  static find(expando) {
    if (data === null) data = new List();
    var do_compact = false;
    int i = 0;
    for (; i < data.length; ++i) {
      var key = data[i].key;
      if (key == expando) {
        break;
      }
      if (key === null) {
        do_compact = true;
        data[i] = null;
      }
    }
    if (i == data.length) {
      data.add(new _WeakProperty(expando, new List()));
    }
    var result = data[i];
    if (do_compact) {
      data = data.filter((e) => (e !== null));
    }
    return result;
  }

  static List data;
}
