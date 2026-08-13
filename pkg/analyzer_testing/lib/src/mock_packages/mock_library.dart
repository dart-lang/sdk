// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class MockLibraryUnit {
  /// The relative path of this compilation unit, relative to the package root.
  ///
  /// Typically, this will start with 'lib/'.
  final String path;

  /// The source content of the compilation unit.
  final String content;

  MockLibraryUnit(this.path, this.content);
}
