// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.12

// Test that static check does not occur before language version 2.13.

@JS()
library language_version_test;

import 'package:js/js.dart';

@JS()
class HTMLDocument {}

void main() {}
