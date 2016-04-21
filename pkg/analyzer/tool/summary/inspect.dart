// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/inspect.dart';

main(List<String> args) {
  if (args.length != 1) {
    print('Usage: inspect PATH');
    exitCode = 1;
    return;
  }
  String path = args[0];
  List<int> bytes = new File(path).readAsBytesSync();
  PackageBundle bundle = new PackageBundle.fromBuffer(bytes);
  SummaryInspector inspector = new SummaryInspector();
  print(inspector.dumpPackageBundle(bundle).join('\n'));
}
