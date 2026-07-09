// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test is always used with a custom package_config.json, so don't validate
// the imports against the pubspec.yaml.
// @skip_package_deps_validation

import 'package:const_finder_fixtures/target.dart';

void createTargetInPackage() {
  const Target target = Target('package', -1, null);
  target.hit();
}

void createNonConstTargetInPackage() {
  final Target target = Target('package_non', -2, null);
  target.hit();
}
