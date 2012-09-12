// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch class Expando<T> {
  /* patch */ T operator[](Object object) {
    _checkType(object);
    var weakProperty = _find(this);
    var list = weakProperty.value;
    var doCompact = false;
    var result = null;
    for (int i = 0; i < list.length; ++i) {
      var key = list[i].key;
      if (key === object) {
        result = list[i].value;
        break;
      }
      if (key === null) {
        doCompact = true;
        list[i] = null;
      }
    }
    if (doCompact) {
      weakProperty.value = list.filter((e) => (e !== null));
    }
    return result;
  }

  /* patch */ void operator[]=(Object object, T value) {
    _checkType(object);
    var weakProperty = _find(this);
    var list = weakProperty.value;
    var doCompact = false;
    int i = 0;
    for (; i < list.length; ++i) {
      var key = list[i].key;
      if (key === object) {
        break;
      }
      if (key === null) {
        doCompact = true;
        list[i] = null;
      }
    }
    if (i !== list.length && value === null) {
      doCompact = true;
      list[i] = null;
    } else if (i !== list.length) {
      list[i].value = value;
    } else {
      list.add(new _WeakProperty(object, value));
    }
    if (doCompact) {
      weakProperty.value = list.filter((e) => (e !== null));
    }
  }

  static _checkType(object) {
    if (object === null) {
      throw new NullPointerException();
    }
    if (object is bool || object is num || object is String) {
      throw new IllegalArgumentException(object);
    }
  }

  static _find(expando) {
    if (_data === null) _data = new List();
    var doCompact = false;
    int i = 0;
    for (; i < _data.length; ++i) {
      var key = _data[i].key;
      if (key == expando) {
        break;
      }
      if (key === null) {
        doCompact = true;
        _data[i] = null;
      }
    }
    if (i == _data.length) {
      _data.add(new _WeakProperty(expando, new List()));
    }
    var result = _data[i];
    if (doCompact) {
      _data = _data.filter((e) => (e !== null));
    }
    return result;
  }

  static List _data;
}
