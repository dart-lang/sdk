// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void errors() {
  try {} catch (error) {
    error.notAMethodOnObject();
    _takesObject(error);
  }

  try {} catch (error, stackTrace) {
    error.notAMethodOnObject();
    stackTrace.notAMethodOnStackTrace();
    _takesObject(error);
    _takesStackTrace(stackTrace);
  }
}

void _takesObject(Object o) {}

void _takesStackTrace(StackTrace o) {}

void main() {}
