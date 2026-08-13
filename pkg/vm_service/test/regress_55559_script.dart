// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

void main() {
  // Block the thread so the isolate can't response to service requests.
  sleep(const Duration(hours: 1));
}
