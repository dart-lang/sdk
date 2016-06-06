// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/inspect.dart';
import 'package:args/args.dart';

main(List<String> args) {
  ArgParser argParser = new ArgParser()..addFlag('raw');
  ArgResults argResults = argParser.parse(args);
  if (argResults.rest.length != 1) {
    print(argParser.usage);
    exitCode = 1;
    return;
  }
  String path = argResults.rest[0];
  List<int> bytes = new File(path).readAsBytesSync();
  PackageBundle bundle = new PackageBundle.fromBuffer(bytes);
  SummaryInspector inspector = new SummaryInspector(argResults['raw']);
  print(inspector.dumpPackageBundle(bundle).join('\n'));
}
