// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../lib/path.dart' as path;

void runBenchmark(String name, Function func, List files) {
  // Warmup.
  for (int i = 0; i < 10000; i++) {
    for (var p in files) {
      func(p);
    }
  }
  var count = 100000;
  var sw = new Stopwatch()..start();
  for (int i = 0; i < count; i++) {
    for (var p in files) {
      func(p);
    }
  }
  print("$name: ${count / sw.elapsedMicroseconds} iter/us (${sw.elapsed})");
}

main(args) {
  for (var style in [path.Style.posix, path.Style.url, path.Style.windows]) {
    var context = new path.Context(style: style);
    var files = COMMON_PATHS.toList()..addAll(STYLE_PATHS[style]);

    void benchmark(name, func) {
      name = style.name + '-' + name;
      if (args.isEmpty || args.any((arg) => name.contains(arg))) {
        runBenchmark(name, func, files);
      }
    }

    benchmark('basename', context.basename);
    benchmark('basenameWithoutExtension', context.basenameWithoutExtension);
    benchmark('dirname', context.dirname);
    benchmark('extension', context.extension);
    benchmark('rootPrefix', context.rootPrefix);
    benchmark('isAbsolute', context.isAbsolute);
    benchmark('isRelative', context.isRelative);
    benchmark('isRootRelative', context.isRootRelative);
    benchmark('normalize', context.normalize);
    benchmark('relative', context.relative);
    benchmark('toUri', context.toUri);
    benchmark('prettyUri', context.prettyUri);
  }
}

const COMMON_PATHS = const [
  '.',
  '..',
  'out/ReleaseIA32/packages',
];

final STYLE_PATHS = {
  path.Style.posix: [
    '/home/user/dart/sdk/lib/indexed_db/dart2js/indexed_db_dart2js.dart',
  ],
  path.Style.url: [
    'https://example.server.org/443643002/path?top=yes#fragment',
  ],
  path.Style.windows: [
    r'C:\User\me\',
    r'\\server\share\my\folders\some\file.data',
  ],
};
