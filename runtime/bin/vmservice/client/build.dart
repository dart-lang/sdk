// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:polymer/builder.dart';
import 'dart:io';
import 'dart:async';

main() {
  lint()
    .then((_) => deploy()).then(compileToJs);
}

compileToJs(_) {
  print("Running dart2js");
	var dart_path = Platform.executable;
	var bin_path = dart_path.substring(0, dart_path.lastIndexOf(Platform.pathSeparator));
	var dart2js_path = "$bin_path${Platform.pathSeparator}dart2js";
  var result =
    Process.runSync(dart2js_path,
        [ '--minify', '-o', 'out/web/index.html_bootstrap.dart.js',
        'out/web/index.html_bootstrap.dart'], runInShell: true);
  print(result.stdout);
  print(result.stderr);
  if (result.exitCode != 0) {
    print("Running dart2js failed.");
    exit(result.exitCode);
  }
  print("Done");
}
