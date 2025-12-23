// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

/// An enumeration of quick fix kinds found in a pubspec file.
abstract final class PubspecFixKind {
  static const addName = FixKind(
    'pubspec.fix.add.name',
    PubspecFixKindPriority._default,
    "Add 'name' key",
  );
  static const addDependency = FixKind(
    'pubspec.fix.add.dependency',
    PubspecFixKindPriority._default,
    'Update pubspec with the missing dependencies',
  );
  // Sorts dependencies alphabetically in the pubspec.yaml file.
  static const sortDependencies = FixKind(
    'pubspec.fix.sort.dependencies',
    PubspecFixKindPriority._default,
    'Sort dependencies alphabetically',
  );
}

abstract final class PubspecFixKindPriority {
  static const int _default = 50;
}
