// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test emits non-UTF8 formatted data.
// It should have the test expectation: NonUtf8Output.

import 'dart:io';

main() {
  String german = "German characters: aäbcdefghijklmnoöpqrsßtuüvwxyz";
  stdout.add(german.runes.toList());
}
