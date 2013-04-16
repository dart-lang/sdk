// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library yaml_exception;

/// An error thrown by the YAML processor.
class YamlException implements Exception {
  final String _msg;

  YamlException(this._msg);

  String toString() => _msg;
}

