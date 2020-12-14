// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// part of "core_patch.dart";

@pragma("vm:entry-point")
class _WeakProperty {
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  get key native "WeakProperty_getKey";
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  set key(k) native "WeakProperty_setKey";

  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  get value native "WeakProperty_getValue";
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  set value(v) native "WeakProperty_setValue";
}
