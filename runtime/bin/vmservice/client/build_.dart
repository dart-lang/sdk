// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:polymer/builder.dart';
import 'dart:io';

main() {
  lint()
    .then((_) => deploy()).then(compileToJs);
}

String findDart2JS() {
  var dartPath = Platform.executable;
  var lastIndex = dartPath.lastIndexOf(Platform.pathSeparator);
  if (lastIndex != -1) {
    var binPath = dartPath.substring(0, lastIndex);
    return '$binPath${Platform.pathSeparator}dart2js';
  }
  return 'dart2js';
}

void runDart2JS(String input, String output) {
  var dart2js_path = findDart2JS();
  var result =
    Process.runSync(dart2js_path,
        [ '--minify', '-o', output, input], runInShell: true);
  print(result.stdout);
  print(result.stderr);
  if (result.exitCode != 0) {
    print("Running dart2js failed.");
    exit(result.exitCode);
  }
}

compileToJs(_) {
  print("Running dart2js");
  runDart2JS('out/web/index.html_bootstrap.dart',
             'out/web/index.html_bootstrap.dart.js');
  runDart2JS('out/web/index_devtools.html_bootstrap.dart',
             'out/web/index_devtools.html_bootstrap.dart.js');
  print("Done");
}
