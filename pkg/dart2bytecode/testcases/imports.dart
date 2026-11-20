// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: unused_import, unused_shown_name

import 'dart:async' show Future, Stream;
import 'dart:collection' hide HashMap, HashSet;
import 'dart:math' as math;
import 'dart:typed_data' as math;
import 'dart:io' as _;
import 'hello.dart' deferred as lib;

export 'dart:convert' show json;
export 'dart:core' hide print;

Future<int> testPrefixes() async {
  await lib.loadLibrary();
  return math.max(1, 2) + math.Uint8List(1).length;
}

main() {}
