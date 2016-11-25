// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-enum

import 'package:expect/expect.dart';

enum ErrorContext { general, name, description, targets }

void main() {
  Expect.equals(ErrorContext.name, ErrorContext.name);
}
