// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

String _message = "foo";

String foo() => _message;

void set message(String variable) {
  _message = variable;
}

augment String foo() {
  return "augment1-get: ${augment super()}";
}

augment void set message(String value) {
  augment super = value;
  _message = "augment1-set: ${_message}";
}

augment String foo() {
  return "augment2-get: ${augment super()}";
}

augment void set message(String value) {
  augment super = value;
  _message = "augment2-set: ${_message}";
}
