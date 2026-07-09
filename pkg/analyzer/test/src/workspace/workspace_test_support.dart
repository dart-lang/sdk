// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/workspace/workspace.dart';
import 'package:analyzer/workspace/workspace.dart';
import 'package:analyzer_testing/resource_provider_mixin.dart';

/// Utilities for tests of subclasses of [WorkspacePackage].
abstract class WorkspacePackageTest with ResourceProviderMixin {
  /// The workspace containing the packages.
  late final Workspace workspace;

  /// Return the package containing the given [path], or `null` if there is no
  /// such package in the [workspace].
  WorkspacePackageImpl? findPackage(String path) =>
      workspace.findPackageFor(convertPath(path));
}
