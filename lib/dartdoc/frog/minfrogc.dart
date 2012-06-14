// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('minfrogc');

#import('dart:io');
#import('file_system_vm.dart');
#import('lang.dart');

main() {
  List<String> argv = (new Options()).arguments;

  // Infer --out if there is none defined.
  var outFileDefined = false;
  for (var arg in argv) {
    if (arg.startsWith('--out=')) outFileDefined = true;
  }

  if (!outFileDefined) {
    argv.insertRange(0, 1, "--out=${argv[argv.length-1]}.js");
  }

  // TODO(dgrove) we're simulating node by placing the arguments to frogc
  // starting at index 2.
  argv.insertRange(0, 2, null);

  // TODO(dgrove) Until we have a way of getting the executable's path, we'll
  // run from '.'
  var homedir = (new File('.')).fullPathSync();

  if (!compile(homedir, argv, new VMFileSystem())) {
    print("Compilation failed");
    exit(1);
  }
}
