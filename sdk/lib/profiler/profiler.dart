// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart.profiler;

/// A UserTag can be used to group samples in the Observatory profiler.
abstract class UserTag {
  /// The maximum number of UserTag instances that can be created by a program.
  static const MAX_USER_TAGS = 64;

  factory UserTag(String label) => new _FakeUserTag(label);

  /// Label of [this].
  String get label;

  /// Make [this] the current tag for the isolate. Returns the current tag
  /// before setting.
  UserTag makeCurrent();

  /// The default [UserTag] with label 'Default'.
  static UserTag get defaultTag => _FakeUserTag._defaultTag;
}

// This is a fake implementation of UserTag so that code can compile and run
// in dart2js.
class _FakeUserTag implements UserTag {
  static Map _instances = {};

  _FakeUserTag.real(this.label);

  factory _FakeUserTag(String label) {
    // Canonicalize by name.
    var existingTag = _instances[label];
    if (existingTag != null) {
      return existingTag;
    }
    // Throw an exception if we've reached the maximum number of user tags.
    if (_instances.length == UserTag.MAX_USER_TAGS) {
      throw new UnsupportedError(
          'UserTag instance limit (${UserTag.MAX_USER_TAGS}) reached.');
    }
    // Create a new instance and add it to the instance map.
    var instance = new _FakeUserTag.real(label);
    _instances[label] = instance;
    return instance;
  }

  final String label;

  UserTag makeCurrent() {
    var old = _currentTag;
    _currentTag = this;
    return old;
  }

  static final UserTag _defaultTag = new _FakeUserTag('Default');
}

var _currentTag = _FakeUserTag._defaultTag;

/// Returns the current [UserTag] for the isolate.
UserTag getCurrentTag() {
  return _currentTag;
}
