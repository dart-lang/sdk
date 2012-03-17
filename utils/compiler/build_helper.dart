// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import('dart:io');
#import('dart:uri');

main() {
  List<String> arguments = new Options().arguments;
  Uri uri = new Uri(scheme: 'file', path: '${arguments[0]}/');
  String dartVmLocation = uri.resolve(arguments[1]).path;
  String productionLauncherLocation = uri.resolve(arguments[2]).path;
  String developerLauncherLocation = uri.resolve(arguments[3]).path;
  String productionLaunch = '#!$dartVmLocation\n';
  String developerLaunch = '#!$dartVmLocation --enable_checked_mode\n';
  String launcherScript = """

#import('dart:io');

#import('${uri.resolve('../../frog/file_system_vm.dart').path}', prefix: 'fs');
#import('${uri.resolve('../../frog/lang.dart').path}', prefix: 'lang');
#import('${uri.resolve('../../frog/leg/frog_leg.dart').path}', prefix: 'leg');

void main() {
  lang.legCompile = leg.compile;
  try {

    List<String> argv = (new Options()).arguments;

    // Infer --out if there is none defined.
    var outFileDefined = false;
    for (var arg in argv) {
      if (arg.startsWith('--out=')) outFileDefined = true;
    }

    if (!outFileDefined) {
      argv.insertRange(0, 1, '--out=' + argv[argv.length-1] + '.js');
    }

    // TODO(dgrove) we're simulating node by placing the arguments to frogc
    // starting at index 2.
    argv.insertRange(0, 4, null);

    argv[2] = '--leg';
    argv[3] = '--libdir=${uri.resolve('../../frog/lib').path}';

    // TODO(dgrove) Until we have a way of getting the executable's path, we'll
    // run from '.'
    var homedir = (new File('.')).fullPathSync();

    if (!lang.compile(homedir, argv, new fs.VMFileSystem())) {
      print('Compilation failed');
      exit(1);
    }
  } catch (var exception, var trace) {
    try {
      print('Internal error: \$exception');
    } catch (var ignored) {
      print('Internal error: error while printing exception');
    }
    try {
      print(trace);
    } finally {
      exit(253);
    }
  }
}
""";
  var f = new File(productionLauncherLocation);
  var stream = f.openSync(FileMode.WRITE);
  stream.writeStringSync(productionLaunch);
  stream.writeStringSync(launcherScript);
  stream.closeSync();
  f = new File(developerLauncherLocation);
  stream = f.openSync(FileMode.WRITE);
  stream.writeStringSync(developerLaunch);
  stream.writeStringSync(launcherScript);
  stream.closeSync();
  // TODO(ahe): Make scripts executable.
  // TODO(ahe): Also make .bat files for Windows.
}
