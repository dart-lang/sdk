// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// part of "developer.dart";

@patch
class UserTag {
  @patch
  factory UserTag(String label) {
    return new _UserTag(label);
  }
  @patch
  static UserTag get defaultTag => _getDefaultTag();
}

@pragma("vm:entry-point")
class _UserTag implements UserTag {
  factory _UserTag(String label) native "UserTag_new";
  String get label native "UserTag_label";
  @pragma("vm:recognized", "asm-intrinsic")
  UserTag makeCurrent() native "UserTag_makeCurrent";
}

@patch
UserTag getCurrentTag() => _getCurrentTag();
@pragma("vm:recognized", "asm-intrinsic")
UserTag _getCurrentTag() native "Profiler_getCurrentTag";

@pragma("vm:recognized", "asm-intrinsic")
UserTag _getDefaultTag() native "UserTag_defaultTag";
