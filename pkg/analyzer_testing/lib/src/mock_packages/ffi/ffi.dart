// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

/// The set of compilation units that make up the mock 'ffi' package.
final List<MockLibraryUnit> units = [_ffiUnit];

final _ffiUnit = MockLibraryUnit('lib/ffi.dart', r'''
import 'dart:ffi';

const CallocAllocator calloc = CallocAllocator._();

final class CallocAllocator implements Allocator {}

final class Utf8 extends Opaque {}
''');
