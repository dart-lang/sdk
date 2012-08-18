// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class WeakProperty {
  factory WeakProperty(key, value) => _new(key, value);

  get key() => _getKey();
  get value() => _getValue();

  static WeakProperty _new(key, value) native "WeakProperty_new";

  _getKey() native "WeakProperty_getKey";
  _getValue() native "WeakProperty_getValue";
}
