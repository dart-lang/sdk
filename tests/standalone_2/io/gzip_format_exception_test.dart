// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:expect/expect.dart';

// This tests whether a FormatException is thrown on bad data.
main() {
  Expect.throwsFormatException(() => GZipCodec().decoder.convert([10, 20, 30]));
}
