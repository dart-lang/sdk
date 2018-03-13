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

class _UserTag implements UserTag {
  factory _UserTag(String label) native "UserTag_new";
  String get label native "UserTag_label";
  UserTag makeCurrent() native "UserTag_makeCurrent";
}

@patch
UserTag getCurrentTag() => _getCurrentTag();
UserTag _getCurrentTag() native "Profiler_getCurrentTag";

UserTag _getDefaultTag() native "UserTag_defaultTag";
