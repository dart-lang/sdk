// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:convert';

final LINUX_COMBINATIONS = [
  {
    'runtimes': ['none'],
    'modes': ['release'],
    'archs': ['x64'],
    'compiler': 'dart2analyzer'
  },
  {
    'runtimes': ['vm'],
    'modes': ['debug', 'release'],
    'archs': ['ia32', 'x64', 'simarm', 'simmips'],
    'compiler': 'none'
  },
  {
    'runtimes': ['d8', 'jsshell', 'chrome', 'ff'],
    'modes': ['release'],
    'archs': ['ia32'],
    'compiler': 'dart2js'
  },
  {
    'runtimes': ['dartium'],
    'modes': ['release', 'debug'],
    'archs': ['ia32'],
    'compiler': 'none'
  },
  {
    'runtimes': ['flutter_engine'],
    'modes': ['debug', 'release'],
    'archs': ['x64'],
    'compiler': 'none'
  },
];

final MACOS_COMBINATIONS = [
  {
    'runtimes': ['vm'],
    'modes': ['debug', 'release'],
    'archs': ['ia32', 'x64'],
    'compiler': 'none'
  },
  {
    'runtimes': ['safari', 'safarimobilesim'],
    'modes': ['release'],
    'archs': ['ia32'],
    'compiler': 'dart2js'
  },
  {
    'runtimes': ['dartium'],
    'modes': ['release', 'debug'],
    'archs': ['ia32'],
    'compiler': 'none'
  },
];

final WINDOWS_COMBINATIONS = [
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
  {
    'runtimes': ['dartium'],
    'modes': ['release', 'debug'],
    'archs': ['ia32'],
    'compiler': 'none'
  },
];

final COMBINATIONS = {
  'linux': LINUX_COMBINATIONS,
  'windows': WINDOWS_COMBINATIONS,
  'macos': MACOS_COMBINATIONS
};

List<Map> getCombinations() {
  return COMBINATIONS[Platform.operatingSystem];
}

void ensureBuild(Iterable<String> modes, Iterable<String> archs) {
  print('Building many platforms. Please be patient.');

  var archString = '-a${archs.join(',')}';

  var modeString = '-m${modes.join(',')}';

  var args = [
    'tools/build.py',
    modeString,
    archString,
    'create_sdk',
    // We build runtime to be able to list cc tests
    'runtime'
  ];

  print('Running: python ${args.join(" ")}');

  var result = Process.runSync('python', args);

  if (result.exitCode != 0) {
    print('ERROR');
    print(result.stderr);
    throw new Exception('Error while building.');
  }
  print('Done building.');
}

void sanityCheck(String output) {
  LineSplitter splitter = new LineSplitter();
  var lines = splitter.convert(output);
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
    throw new Exception(
        'Count and total do not align. Please validate manually.');
  }
}

void main(List<String> args) {
  var combinations = getCombinations();

  var arches = new Set<String>();
  var modes = new Set<String>();

  if (args.contains('--simple')) {
    arches = ['ia32'].toSet();
    modes = ['release'].toSet();
  } else {
    for (var combo in combinations) {
      arches.addAll(combo['archs']);
      modes.addAll(combo['modes']);
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
          var compiler = combination['compiler'];

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
            throw new Exception("Error running: ${args.join(" ")}");
          }

          // Find "JSON:"
          // Everything after will the JSON-formatted output
          // per --report-in-json flag above
          var totalIndex = result.stdout.indexOf('JSON:');
          var report = result.stdout.substring(totalIndex + 5);

          var map = JSON.decode(report) as Map<String, int>;

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
