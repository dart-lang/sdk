// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'utils/suite_utils.dart' show limitToArgument;
import "vm_service_for_leak_detection.dart" as helper;

Future<void> main(List<String> args) async {
  /// Run just a single test from the incremental suite (with finding leaks) to
  /// verify that leak finding actually works and that - e.g. a move of kernel
  /// stuff - makes it inoperable. Note that we require, for instance,
  /// the Library class in the kernel ast to be found.
  await helper.createNewLeakFinder(helper.getInterests()).start([
    "--enable-asserts",
    Platform.script.resolve("incremental_suite.dart").toString(),
    "${limitToArgument}1",
    "-DaddDebugBreaks=true",
  ]);
}
