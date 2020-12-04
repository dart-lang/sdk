// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing native extensions.

// @dart = 2.9

// OtherResources=../sample_synchronous_extension.dart
// OtherResources=../sample_asynchronous_extension.dart
// OtherResources=../test_sample_synchronous_extension.dart
// OtherResources=../test_sample_asynchronous_extension.dart

import 'sample_extension_test_helper.dart';

void main() {
  testNativeExtensions("app-jit");
}
