// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'private_member_access_lib.dart';

method(Class c) {
  c._privateField;
  c._privateField = 42;
  c._privateMethod;
  c._privateMethod();
  c._privateField += 42;
}
