// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';

import 'package:heapsnapshot/src/cli.dart';
import 'package:path/path.dart' as path;

import 'package:test/test.dart';

import 'utils.dart';

class ErrorCollector extends Output {
  final errors = <String>[];
  final output = <String>[];
  final all = <String>[];

  void printError(String error) {
    errors.add(error);
    all.add(error);
  }

  void print(String message) {
    output.add(message);
    all.add(message);
  }

  void clear() {
    errors.clear();
    output.clear();
    all.clear();
  }

  String get log => all.join('\n');
}

main([List<String> args = const []]) {
  if (!args.isEmpty) {
    // We're in the child.
    if (args.single != '--child') throw 'failed';

    // Force initialize of the data we want in the heapsnapshot.
    print(global.use);
    print(weakTest.use);
    if (supportsExternalTypedDataTest) {
      print(externalTypedData1234567.length);
    }
    print('Child ready');
    return;
  }

  group('cli', () {
    late Testee testee;
    late String testeeUrl;
    late Directory snapshotDir;
    late String heapsnapshotFile;
    late ErrorCollector errorCollector;
    late CliState cliState;

    setUpAll(() async {
      snapshotDir = Directory.systemTemp.createTempSync('snapshot');
      heapsnapshotFile = path.join(snapshotDir.path, 'current.heapsnapshot');

      testee = Testee('test/cli_test.dart');
      testeeUrl = await testee.start(['--child']);
      await testee.getHeapsnapshotAndWriteTo(heapsnapshotFile);

      errorCollector = ErrorCollector();
      cliState = CliState(errorCollector);
    });

    tearDownAll(() async {
      snapshotDir.deleteSync(recursive: true);
      await testee.close();
    });

    late String log;
    Future run(String commandString) async {
      final args = commandString.split(' ').where((p) => !p.isEmpty).toList();
      print('-----------------------');
      print('Running: $commandString');
      await cliCommandRunner.run(cliState, args);
      log = errorCollector.log;
      print(log.trim());
      errorCollector.clear();
    }

    expectLog(String expected) {
      expect(log.trim(), expected.trim());
    }

    expectLogPattern(String pattern) {
      final logLines = log
          .split('\n')
          .map((p) => p.trim())
          .where((p) => !p.isEmpty)
          .toList();
      final patternLines = pattern
          .split('\n')
          .map((p) => p.trim())
          .where((p) => !p.isEmpty)
          .toList();
      if (logLines.length != patternLines.length) {
        print('Expected pattern:');
        print('  ' + patternLines.join('\n  '));
        print('But got:');
        print('  ' + logLines.join('\n  '));
      }
      for (int i = 0; i < logLines.length; ++i) {
        final log = logLines[i];
        final pattern = patternLines[i];
        if (!RegExp(pattern).hasMatch(log)) {
          print('[$i] $log does not match pattern "$pattern"');
          expect(false, true);
        }
      }
    }

    const sp = r'\{#\d+\}';

    test('cli commands', () async {
      // Test loading from Uri & search for the Global object.
      await run('load $testeeUrl');
      expectLog('Loaded heapsnapshot from "$testeeUrl".');

      await run('stat filter (closure roots) Global');
      expectLogPattern(r'''
  size       count     class
  --------   --------  --------
  0 kb       1    Global .*/cli_test.dart
    ''');

      // Test loading from file & do remaining tests.

      await run('load $heapsnapshotFile');
      expectLog('Loaded heapsnapshot from "$heapsnapshotFile".');

      await run('info');
      expectLogPattern('''
Known named sets:
    roots  $sp
    ''');

      await run('eval all = closure roots');
      expectLogPattern('all $sp');

      await run('info');
      expectLogPattern('''
Known named sets:
    roots  $sp
    all    $sp
    ''');

      await run('global = filter all Global');
      expectLogPattern(r'global \{#1\}');

      await run('stats global');
      expectLogPattern('''
size *count *class
-------- *-------- *--------
0 kb *1 *Global .*cli_test.dart
    ''');

      await run('dstats -c filter (closure global) String');
      expectLogPattern('''
size       unique-size  count     class           data
--------   --------     --------  --------        --------
     0 kb       0 kb         4    _OneByteString  #nonSharedString#
     0 kb       0 kb         2    _OneByteString  #fooUniqueString
     0 kb       0 kb         2    _OneByteString  #barUniqueString
     0 kb       0 kb         1    _OneByteString  #sharedString
--------   --------     --------
     0 kb       0 kb         9
    ''');

      await run('lists = filter (closure global) _List');
      expectLogPattern('lists $sp');

      await run('dstats -c lists');
      expectLogPattern('''
size       unique-size  count     class     data
--------   --------     --------  --------  --------
     0 kb       0 kb         1    _List     len:0
     0 kb       0 kb         1    _List     len:0
     0 kb       0 kb         1    _List     len:2
     0 kb       0 kb         1    _List     len:1
     0 kb       0 kb         1    _List     len:1
     0 kb       0 kb         1    _List     len:2
--------   --------     --------
     0 kb       0 kb         6
    ''');

      if (supportsExternalTypedDataTest) {
        await run('etd = dfilter (filter all _ExternalUint8Array) ==1234567');
        expectLogPattern('etd $sp');

        await run('stats etd');
        expectLogPattern('''
size       count     class
--------   --------  --------
  1205 kb       1    _ExternalUint8Array dart:typed_data
    ''');

        await run('dstats etd');
        expectLogPattern('''
size       unique-size  count     class                data
--------   --------     --------  --------             --------
  1205 kb    1205 kb         1    _ExternalUint8Array  len:1234567
    ''');
      }

      await run(
          'stats foobar = (follow (follow global) ^:type_arguments ^Root ^Smi)');
      expectLogPattern('''
size       count     class
--------   --------  --------
     0 kb       2    Foo .*cli_test.dart
     0 kb       2    Bar .*cli_test.dart
--------   --------
     0 kb       4
    ''');

      await run('examine users foobar');
      expectLogPattern(r'''
  _List@\d+ .* {
    type_arguments_
    length_
    \[0\] *Foo@\d+ .*/cli_test.dart
    \[1\] *Foo@\d+ .*/cli_test.dart
  }
  _List@\d+ .* {
    type_arguments_
    length_
    \[0\] *Bar@\d+ .*/cli_test.dart
    \[1\] *Bar@\d+ .*/cli_test.dart
  }
    ''');

      await run('examine users users foobar');
      expectLogPattern(r'''
Global@\d+ .*/cli_test.dart.* {
  foos  _List@\d+
  bars  _List@\d+
}
    ''');

      await run('users (follow global :bars)');

      await run('retainers -n10 filter (closure global) String');

      expectLogPattern(r'''
There are 2 retaining paths of
_OneByteString
⮑ ・Foo.fooLocal .*/cli_test.dart
    ⮑ ・_List
        ⮑ ・Global.foos .*/cli_test.dart
            ⮑ ・Isolate.global
                ⮑ ・Root


There are 2 retaining paths of
_OneByteString
⮑ ・Foo.fooUnique .*/cli_test.dart
    ⮑ ・_List
        ⮑ ・Global.foos .*/cli_test.dart
            ⮑ ・Isolate.global
                ⮑ ・Root


There are 2 retaining paths of
_OneByteString
⮑ ・Bar.barLocal .*/cli_test.dart
    ⮑ ・_List
        ⮑ ・Global.bars .*/cli_test.dart
            ⮑ ・Isolate.global
                ⮑ ・Root


There are 2 retaining paths of
_OneByteString
⮑ ・Bar.barUnique .*/cli_test.dart
    ⮑ ・_List
        ⮑ ・Global.bars .*/cli_test.dart
            ⮑ ・Isolate.global
                ⮑ ・Root


There are 1 retaining paths of
_OneByteString
⮑ ﹢Foo.fooShared .*/cli_test.dart
    ⮑ ・_List
        ⮑ ・Global.foos .*/cli_test.dart
            ⮑ ・Isolate.global
                ⮑ ・Root
    ''');

      await run('describe-filter Foo:List ^Bar');

      expectLogPattern(r'''
The traverse filter expression "Foo:List \^Bar" matches:

\[\-\] Bar
\[ \] Foo
\[\+\]   \.fooList0
    ''');

      await run('weakly-held-object = follow (filter all WeakTest) :object');
      await run('stats uclosure weakly-held-object');

      expectLogPattern(r'''
size       count     class
--------   --------  --------
0 kb       1    WeakTest .*/cli_test.dart
0 kb       1    Object dart:core
0 kb       1    Root
0 kb       1    Isolate
--------   --------
0 kb       4
    ''');
    });
  });
}

final global = Global();

var marker = '|';
var sharedString = 'x';

class Foo {
  final fooShared = sharedString;
  final fooLocal = marker + 'nonSharedString' + marker;
  final fooUnique = marker + 'fooUniqueString';
  final fooList0 = List.filled(0, null);

  String get use => 'Foo($fooShared, $fooLocal, $fooUnique, $fooList0)';
}

class Bar {
  final barShared = sharedString;
  final barLocal = marker + 'nonSharedString' + marker;
  final barUnique = marker + 'barUniqueString';
  final barList1 = List.filled(1, null);

  String get use => 'Bar($barShared, $barLocal, $barUnique, $barList1)';
}

class Global {
  late final foos;
  late final bars;

  Global() {
    marker = '#';
    sharedString = marker + 'sharedString';
    foos = [Foo(), Foo()].toList(growable: false);
    bars = [Bar(), Bar()].toList(growable: false);
    sharedString = '';
  }

  String get use =>
      '${foos.map((l) => l.use).toList()}|${bars.map((l) => l.use).toList()}|$sharedString';
}

// In order to create external typed data, we rely on the fact that dart:io will
// produce `Uint8List`s with external typed data if reading files that will not
// report their length (such as /dev/zero).
final bool supportsExternalTypedDataTest = File('/dev/zero').existsSync();

final Uint8List externalTypedData1234567 =
    File('/dev/zero').openSync().readSync(1234567);

final weakTest = WeakTest(Object());

class WeakTest {
  final Object object;
  final List<WeakReference<Object>> weakList;
  final Finalizer finalizer;

  WeakTest(this.object)
      : weakList = List.filled(1, WeakReference(object)),
        finalizer = Finalizer((_) {})..attach(object, Object(), detach: object);

  String get use => '$object|$weakList|$finalizer';
}
