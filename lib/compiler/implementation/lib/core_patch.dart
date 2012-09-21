// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch file for dart:core classes.

// Patch for 'print' function.
patch void print(var obj) {
  if (obj is String) {
    Primitives.printString(obj);
  } else {
    Primitives.printString(obj.toString());
  }
}

// Patch for Object implementation.
patch class Object {
  patch int hashCode() => Primitives.objectHashCode(this);

  patch String toString() => Primitives.objectToString(this);

  patch void noSuchMethod(String name, List args) {
    throw new NoSuchMethodError(this, name, args);
  }

  patch Type runtimeType() {
    String key = getRuntimeTypeString(this);
    return getOrCreateCachedRuntimeType(key);
  }
}


// Patch for Expando implementation.
patch class Expando<T> {
  patch Expando([this.name]);

  patch T operator[](Object object) {
    var values = Primitives.getProperty(object, _EXPANDO_PROPERTY_NAME);
    return (values === null) ? null : Primitives.getProperty(values, _getKey());
  }

  patch void operator[]=(Object object, T value) {
    var values = Primitives.getProperty(object, _EXPANDO_PROPERTY_NAME);
    if (values === null) {
      values = new Object();
      Primitives.setProperty(object, _EXPANDO_PROPERTY_NAME, values);
    }
    Primitives.setProperty(values, _getKey(), value);
  }

  String _getKey() {
    String key = Primitives.getProperty(this, _KEY_PROPERTY_NAME);
    if (key === null) {
      key = "expando\$key\$${_keyCount++}";
      Primitives.setProperty(this, _KEY_PROPERTY_NAME, key);
    }
    return key;
  }

  static const String _KEY_PROPERTY_NAME = 'expando\$key';
  static const String _EXPANDO_PROPERTY_NAME = 'expando\$values';
  static int _keyCount = 0;
}

patch class int {
  patch static int parse(String string) => Primitives.parseInt(string);
}

patch class double {
  patch static double parse(String string) => Primitives.parseDouble(string);
}

patch class NoSuchMethodError {
  patch static String _objectToString(Object object) {
    return Primitives.objectToString(object);
  }
}
