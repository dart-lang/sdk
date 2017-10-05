// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// part of "core_patch.dart";

class _WeakProperty {
  factory _WeakProperty(key, value) => _new(key, value);

  get key => _getKey();
  get value => _getValue();
  set value(value) => _setValue(value);

  static _WeakProperty _new(key, value) native "WeakProperty_new";

  _getKey() native "WeakProperty_getKey";
  _getValue() native "WeakProperty_getValue";
  _setValue(value) native "WeakProperty_setValue";
}
