// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/source.dart';

abstract class WorkspacePackage {
  /// Whether this package can have public APIs, that is, the package has marker
  /// files like 'pubspec.yaml' or 'BUILD'.
  bool get canHavePublicApi;

  /// The path to the root of this package.
  Folder get root;

  /// Whether this package contains [source].
  bool contains(Source source);

  /// Whether [file] is in a "test" directory of this package.
  bool isInTestDirectory(File file);
}
