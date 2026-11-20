// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore: invalid_language_version_override
// @dart = 3.6

part of 'library_dependency_shared_prefix_part1.dart';

// This deferred import shadows the import with the same prefix in part1.
import 'dart:math' deferred as l;

Future<void> usePrefixes() async {
  await l.loadLibrary();
  print(l.max(1, 2));
}
