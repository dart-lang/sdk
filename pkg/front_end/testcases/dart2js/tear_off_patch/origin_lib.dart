// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class<T> {
  external Class({bool defaultValue: true, required T value});
  external factory Class.fact({bool defaultValue: true, required T value});
  external factory Class.redirect({bool defaultValue, required T value});
  external factory Class.redirect2({bool defaultValue, required T value});
}

class ClassImpl<T> implements Class<T> {
  ClassImpl({bool defaultValue: true, required T value});

  external ClassImpl.patched({bool defaultValue: true, required T value});
}

typedef Alias<T extends num> = Class<T>;
typedef AliasImpl<T extends num> = ClassImpl<T>;
