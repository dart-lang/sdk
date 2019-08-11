// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

final _combinations = {
  'linux': [
    {
      'runtimes': ['none'],
      'modes': ['release'],
      'archs': ['x64'],
      'compiler': 'dart2analyzer'
    },
    {
      'runtimes': ['none'],
      'modes': ['release'],
      'archs': ['x64'],
      'compiler': 'compare_analyzer_cfe'
    },
    {
      'runtimes': ['vm'],
      'modes': ['debug', 'release'],
      'archs': ['ia32', 'x64', 'simarm'],
      'compiler': 'none'
    },
    {
      'runtimes': ['d8', 'jsshell', 'chrome', 'ff'],
      'modes': ['release'],
      'archs': ['ia32'],
      'compiler': 'dart2js'
    },
  ],
  'windows': [
    {
      'runtimes': ['vm'],
      'modes': ['debug', 'release'],
      'archs': ['ia32', 'x64'],
      'compiler': 'none'
    },
    {
      'runtimes': ['chrome', 'ff', 'ie11', 'ie10'],
      'modes': ['release'],
      'archs': ['ia32'],
      'compiler': 'dart2js'
    },
  ],
  'macos': [
    {
      'runtimes': ['vm'],
      'modes': ['debug', 'release'],
      'archs': ['ia32', 'x64'],
      'compiler': 'none'
    },
    {
      'runtimes': ['safari'],
      'modes': ['release'],
      'archs': ['ia32'],
      'compiler': 'dart2js'
    },
  ]
};

void ensureBuild(Iterable<String> modes, Iterable<String> archs) {
  print('Building many platforms. Please be patient.');

  var archString = '-a${archs.join(',')}';
  var modeString = '-m${modes.join(',')}';

  var args = [
    'tools/build.py',
    modeString,
    archString,
    'create_sdk',
    // We build runtime to be able to list cc tests.
    'runtime'
  ];

  print('Running: python ${args.join(" ")}');

  var result = Process.runSync('python', args);

  if (result.exitCode != 0) {
    print('ERROR');
    print(result.stderr);
    throw Exception('Error while building.');
  }
  print('Done building.');
}

void sanityCheck(String output) {
  var lines = const LineSplitter().convert(output);
  // Looks like this:
  // Total: 15556 tests
  var total = int.parse(lines[0].split(' ')[1].trim());
  var count = 0;
  for (var i = 1; i < lines.length; i++) {
    if (lines[i] == '') continue;
    // Looks like this:
    //  * 3218 tests will be skipped (3047 skipped by design)
    count += int.parse(lines[i].split(' ')[2].trim());
  }
  if (count != total) {
    print('Count: $count, total: $total');
    throw Exception('Count and total do not align. Please validate manually.');
  }
}

void main(List<String> args) {
  var combinations = _combinations[Platform.operatingSystem];

  var arches = <String>{};
  var modes = <String>{};

  if (args.contains('--simple')) {
    arches = {'ia32'};
    modes = {'release'};
  } else {
    for (var combination in combinations) {
      arches.addAll(combination['archs'] as List<String>);
      modes.addAll(combination['modes'] as List<String>);
    }
  }

  ensureBuild(modes, arches);

  List<String> keys;
  for (var combination in combinations) {
    for (var mode in combination['modes']) {
      if (!modes.contains(mode)) {
        continue;
      }

      for (var arch in combination['archs']) {
        if (!arches.contains(arch)) {
          continue;
        }

        for (var runtime in combination['runtimes']) {
          var compiler = combination['compiler'] as String;

          var args = [
            'tools/test.py',
            '-m$mode',
            '-c$compiler',
            '-r$runtime',
            '-a$arch',
            '--report-in-json',
            '--use-sdk'
          ];
          var result = Process.runSync('python', args);
          if (result.exitCode != 0) {
            print(result.stdout);
            print(result.stderr);
            throw Exception("Error running: ${args.join(" ")}");
          }

          // Find "JSON:"
          // Everything after will the JSON-formatted output
          // per --report-in-json flag above
          var totalIndex = (result.stdout as String).indexOf('JSON:');
          var report = (result.stdout as String).substring(totalIndex + 5);

          var map = jsonDecode(report) as Map<String, int>;

          if (keys == null) {
            keys = map.keys.toList();
            var firstKey = keys.removeAt(0);
            if (firstKey != 'total') {
              throw '"total" should be the first key';
            }

            var headers = ['compiler', 'runtime', 'arch', 'mode', 'total'];
            for (var k in keys) {
              headers.addAll([k, '${k}_pct']);
            }
            print(headers.join(','));
          }

          var total = map['total'];
          var values = [compiler, runtime, arch, mode, total];

          for (var key in keys) {
            var value = map[key];
            values.add(value);
            var pct = 100 * (value / total);
            values.add('${pct.toStringAsFixed(3)}%');
          }

          print(values.join(','));
        }
      }
    }
  }
}
