// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of repositories;

/// Static settings database.
class _Settings {
  static Storage _storage = window.localStorage;

  /// Associated [value] with [key]. [value] must be JSON encodable.
  static void set(String key, dynamic value) {
    _storage.setItem(key, json.encode(value));
  }

  /// Get value associated with [key]. Return value will be a JSON encodable
  /// object.
  static dynamic get(String key) {
    var value = _storage.getItem(key);
    if (value == null) {
      return null;
    }
    return json.decode(value);
  }
}

/// A group of settings each prefixed with group name and a dot.
class SettingsRepository {
  /// Group name
  final String group;

  SettingsRepository(this.group);

  String _fullKey(String key) => '$group.$key';

  void set(String key, dynamic value) {
    var fullKey = _fullKey(key);
    _Settings.set(fullKey, value);
  }

  dynamic get(String key) {
    var fullKey = _fullKey(key);
    return _Settings.get(fullKey);
  }
}
