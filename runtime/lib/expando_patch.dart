// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch class Expando<T> {
  /* patch */ Expando([this.name]) : _data = new List();

  /* patch */ T operator[](Object object) {
    _checkType(object);
    var doCompact = false;
    var result = null;
    for (int i = 0; i < _data.length; ++i) {
      var key = _data[i].key;
      if (key === object) {
        result = _data[i].value;
        break;
      }
      if (key === null) {
        doCompact = true;
        _data[i] = null;
      }
    }
    if (doCompact) {
      _data = _data.filter((e) => (e !== null));
    }
    return result;
  }

  /* patch */ void operator[]=(Object object, T value) {
    _checkType(object);
    var doCompact = false;
    int i = 0;
    for (; i < _data.length; ++i) {
      var key = _data[i].key;
      if (key === object) {
        break;
      }
      if (key === null) {
        doCompact = true;
        _data[i] = null;
      }
    }
    if (i !== _data.length && value === null) {
      doCompact = true;
      _data[i] = null;
    } else if (i !== _data.length) {
      _data[i].value = value;
    } else {
      _data.add(new _WeakProperty(object, value));
    }
    if (doCompact) {
      _data = _data.filter((e) => (e !== null));
    }
  }

  static _checkType(object) {
    if (object === null) {
      throw new NullPointerException();
    }
    if (object is bool || object is num || object is String) {
      throw new ArgumentError(object);
    }
  }

  List _data;
}
