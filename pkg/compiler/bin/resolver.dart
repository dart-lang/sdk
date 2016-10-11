// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:compiler/src/filenames.dart';

import 'package:compiler/src/dart2js_resolver.dart';

main(var argv) async {
  var parser = new ArgParser();
  parser.addOption('deps', abbr: 'd', allowMultiple: true);
  parser.addOption('out', abbr: 'o');
  parser.addOption('library-root', abbr: 'l');
  parser.addOption('packages', abbr: 'p');
  parser.addOption('bazel-paths', abbr: 'I', allowMultiple: true);
  var args = parser.parse(argv);

  if (args.rest.isEmpty) {
    print('missing input files');
    exit(1);
  }

  var inputs = args.rest
      .map((uri) => currentDirectory.resolve(nativeToUriPath(uri)))
      .toList();

  var text = await resolve(
      inputs,
      deps: args['deps'],
      root: args['library-root'],
      packages: args['packages'],
      bazelSearchPaths: args['bazel-paths']);

  var outFile = args['out'] ?? 'out.data';

  await new File(outFile).writeAsString(text);
}
