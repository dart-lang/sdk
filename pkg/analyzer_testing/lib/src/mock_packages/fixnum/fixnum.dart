// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

/// The set of units that make up the mock 'fixnum' package.
final List<MockLibraryUnit> units = [_fixnumLibrary];

final _fixnumLibrary = MockLibraryUnit('lib/fixnum.dart', r'''
library fixnum;

class Int32 {}

class Int64 {}
''');
