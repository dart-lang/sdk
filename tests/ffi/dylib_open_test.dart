// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:io';

import 'package:expect/expect.dart';

import 'dylib_utils.dart';

void main() {
  testDoesNotExist();
}

void testDoesNotExist() {
  final exception = Expect.throws<ArgumentError>(
    () => DynamicLibrary.open(dylibName('doesnotexist1234')),
  );

  if (Platform.isWindows) {
    Expect.contains(
      'The specified module could not be found.',
      exception.message,
    );
    Expect.contains('(error code: 126)', exception.message);
  } else if (Platform.isLinux) {
    Expect.contains(
      'cannot open shared object file: No such file or directory',
      exception.message,
    );
  } else if (Platform.isMacOS) {
    Expect.contains('libdoesnotexist1234.dylib', exception.message);
    Expect.containsAny(['no such file', 'image not found'], exception.message);
  }
}
