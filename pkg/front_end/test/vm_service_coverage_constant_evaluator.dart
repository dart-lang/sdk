// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'vm_service_coverage.dart' as helper;

Future<void> main(List<String> args) async {
  CoverageHelper coverageHelper = new CoverageHelper();

  List<String> allArgs = <String>[];
  allArgs.addAll([
    "--disable-dart-dev",
    "--enable-asserts",
    "--pause_isolates_on_exit",
  ]);
  allArgs.addAll(args);

  await coverageHelper.start(allArgs);
}

class CoverageHelper extends helper.CoverageHelper {
  CoverageHelper() : super(printHits: false);

  @override
  bool includeCoverageFor(Uri uri) {
    if (!uri.isScheme("package")) return false;
    if (uri.path.startsWith("front_end/src/fasta/kernel/constant_")) {
      return true;
    }
    return false;
  }
}
