// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library invalid_uri_test;

 // Should not contain "//".
import 'package://lib1.dart'; //# 01: compile-time error

void main() {}
