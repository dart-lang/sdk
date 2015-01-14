// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:convert';

List<Map> LINUX_COMBINATIONS = [
    {
      'runtimes' : ['none'],
      'modes' : ['release'],
      'archs' : ['ia32'],
      'compiler' : 'dartanalyzer'
    },
    {
      'runtimes' : ['vm'],
      'modes' : ['debug', 'release'],
      'archs' : ['ia32', 'x64', 'simarm', 'simmips'],
      'compiler' : 'none'
    },
    {
      'runtimes' : ['vm'],
      'modes' : ['release'],
      'archs' : ['ia32', 'x64'],
      'compiler' : 'dart2dart'
    },
    {
      'runtimes' : ['d8', 'jsshell', 'chrome', 'ff'],
      'modes' : ['release'],
      'archs' : ['ia32'],
      'compiler' : 'dart2js'
    },
    {
      'runtimes' : ['dartium'],
      'modes' : ['release', 'debug'],
      'archs' : ['ia32'],
      'compiler' : 'none'
    },
];

List<Map> MACOS_COMBINATIONS = [
    {
      'runtimes' : ['vm'],
      'modes' : ['debug', 'release'],
      'archs' : ['ia32', 'x64'],
      'compiler' : 'none'
    },
    {
      'runtimes' : ['safari', 'safarimobilesim'],
      'modes' : ['release'],
      'archs' : ['ia32'],
      'compiler' : 'dart2js'
    },
    {
      'runtimes' : ['dartium'],
      'modes' : ['release', 'debug'],
      'archs' : ['ia32'],
      'compiler' : 'none'
    },
];

List<Map> WINDOWS_COMBINATIONS = [
    {
      'runtimes' : ['vm'],
      'modes' : ['debug', 'release'],
      'archs' : ['ia32', 'x64'],
      'compiler' : 'none'
    },
    {
      'runtimes' : ['chrome', 'ff', 'ie11', 'ie10'],
      'modes' : ['release'],
      'archs' : ['ia32'],
      'compiler' : 'dart2js'
    },
    {
      'runtimes' : ['dartium'],
      'modes' : ['release', 'debug'],
      'archs' : ['ia32'],
      'compiler' : 'none'
    },
];

Map<String, List<Map>> COMBINATIONS = {
  'linux' : LINUX_COMBINATIONS,
  'windows' : WINDOWS_COMBINATIONS,
  'macos' : MACOS_COMBINATIONS
};

List<Map> getCombinations() {
  return COMBINATIONS[Platform.operatingSystem];
}

void ensureBuild() {
  print('Building many platforms. Please be patient.');
  var archs = Platform.operatingSystem == 'linux'
    ? '-aia32,x64,simarm,simmips'
    : '-aia32,x64';

  var result = Process.runSync('python',
      ['tools/build.py', '-mrelease,debug', archs, 'create_sdk',
      // We build runtime to be able to list cc tests
      'runtime']);

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
  ensureBuild();

  List<String> keys;
  for (var combination in getCombinations()) {
    for (var mode in combination['modes']) {
      for (var arch in combination['archs']) {
        for (var runtime in combination['runtimes']) {
          var compiler = combination['compiler'];

          var args = ['tools/test.py', '-m$mode', '-c$compiler', '-r$runtime',
                      '-a$arch', '--report-in-json', '--use-sdk'];
          var result = Process.runSync('python', args);
          if (result.exitCode != 0) {
            print(result.stdout);
            print(result.stderr);
            throw new Exception("Error running: ${args.join(" ")}");
          }

          // Find Total: 15063 tests
          // Everything after this will be the report.
          var totalIndex = result.stdout.indexOf('JSON:');
          var report = result.stdout.substring(totalIndex + 5);

          var map = JSON.decode(report) as Map;

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
            var pct = 100*(value/total);
            values.add('${pct.toStringAsFixed(3)}%');
          }

          print(values.join(','));
        }
      }
    }
  }
}
