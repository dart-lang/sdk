// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import '../../../../../pkg/front_end/test/tool/reload.dart';

export '../snapshot_test_helper.dart' show withTempDir;

bool get currentVmSupportsReload {
  final executable = Platform.executable;
  return !executable.contains('Product') &&
      !executable.contains('dart_precompiled_runtime');
}

final includeIn = RegExp(r'//\s+@include-in-reload-([0-9]+)([+]?)\s*$');

Future<List<String>> generateDills(String tempDir, String testDartFile) async {
  // We have to compile in serial by always using the same source filename in
  // order to ensure all dills will have the same root Uri.
  final versions = generateReloadVersions(testDartFile);
  final dills = <String>[];
  int i = 0;
  for (final version in versions) {
    final testFile = path.join(tempDir, 'test.dart');
    await File(testFile).writeAsString(version);
    final dillFile = path.join(tempDir, 'test.dart.${i++}.dill');
    await compile(testFile, dillFile);
    dills.add(Uri.file(dillFile).toString());
  }
  return dills;
}

/// We generate several versions of a program by looking at annotations such as:
///     @include-in-reload-<N>
///     @include-in-reload-<N>+
/// Lines with such annotations are included in the <N>th program version and
/// possibly in all following ones (if `+` was used).
List<String> generateReloadVersions(String fileContent) {
  final lines = fileContent.split('\n');

  // Scan for all annotations to find out how many we reloads we need to do.
  final reloadAnnotation = Uint32List(lines.length);
  final reloadPlusAnnotation = List<bool>.filled(lines.length, true);
  for (int i = 0; i < lines.length; ++i) {
    final line = lines[i];
    final m = includeIn.firstMatch(line);
    if (m != null) {
      final annotation = int.parse(m.group(1) as String);
      reloadAnnotation[i] = annotation;
      reloadPlusAnnotation[i] = m.group(2) == '+';
    } else {
      // No annotation means include always.
      reloadPlusAnnotation[i] = true;
    }
  }
  final reloadAnnotationSet = reloadAnnotation.toSet();
  final sortedReloadAnnotations = reloadAnnotationSet.toList()..sort();
  for (int i = 1; i < sortedReloadAnnotations.length; ++i) {
    final int from = sortedReloadAnnotations[i - 1];
    final int to = sortedReloadAnnotations[i];
    if ((from + 1) != to) {
      throw 'Should have strictly increasing reloads without gaps';
    }
  }

  final versions = <String>[];
  for (int i = 0; i < sortedReloadAnnotations.length; ++i) {
    final int reloadIteration = sortedReloadAnnotations[i];
    final sb = StringBuffer();
    for (int j = 0; j < lines.length; ++j) {
      final int annotation = reloadAnnotation[j];
      final bool plus = reloadPlusAnnotation[j];
      if (annotation == reloadIteration ||
          (plus && annotation <= reloadIteration)) {
        final String line = lines[j];
        sb.writeln(line);
      }
    }
    versions.add(sb.toString());
  }
  return versions;
}

Future compile(String from, String to) async {
  final executable = Platform.executable;
  final command = [
    '--packages=.packages',
    '--snapshot-kind=kernel',
    '--snapshot=$to',
    from,
  ];

  print('Launching $executable ${command.join(' ')}');
  final process = await Process.start(executable, command);
  final f1 = process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((line) => print('stdout: $line'))
      .asFuture();
  final f2 = process.stderr
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((line) => print('stderr: $line'))
      .asFuture();
  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    await f1;
    await f2;
    throw 'Compilation failed';
  }
}

Future<Reloader> launchOn(String file, {bool verbose: false}) async {
  final command = [
    if (verbose) '--trace-reload',
    if (verbose) '--trace-reload-verbose',
    '--enable-vm-service:0',
    '--disable-dart-dev',
    '--disable-service-auth-codes',
    file
  ];
  final env = Platform.environment;
  final executable = Platform.executable;

  print('Launching $executable ${command.join(' ')}');
  final process = await Process.start(executable, command, environment: env);
  final reloader = Reloader(process);
  await reloader._waitUntilService();
  return reloader;
}

class Reloader {
  final Process _process;

  final List<String> _stdout = [];
  final Set<_Filter> _stdoutFilters = {};
  final List<String> _stderr = [];
  final Set<_Filter> _stderrFilters = {};

  RemoteVm _remoteVm;
  int _reloadVersion = 0;

  Reloader(this._process) {
    _process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      print('stdout: $line');
      _addStdout(line);
    });
    _process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      print('stderr: $line');
      _addStderr(line);
    });
  }

  Future _waitUntilService() async {
    final needle = 'Observatory listening on ';
    final line = await waitUntilStdoutContains(needle);
    final Uri uri = Uri.parse(line.substring(needle.length));
    assert(_remoteVm == null);
    _remoteVm = RemoteVm(uri.port);
  }

  Future writeToStdin(String line) async {
    _process.stdin.writeln(line);
    await _process.stdin.flush();
  }

  Future<Map> reload(String file) async {
    print('Reload $file (version: ${_reloadVersion++})');
    final Map reloadResult = await _remoteVm.reload(Uri.parse(file));
    print(const JsonEncoder.withIndent('  ').convert(reloadResult));
    return reloadResult;
  }

  Future<int> close() async {
    await _remoteVm.disconnect();
    final exitCode = await _process.exitCode;
    print('ExitCode = $exitCode');
    return exitCode;
  }

  Future<String> waitUntilStdoutContains(String needle) {
    return _waitUntilContains(_stdout, _stdoutFilters, needle, 1);
  }

  Future<String> waitUntilStdoutContainsN(String needle, int N) {
    return _waitUntilContains(_stdout, _stdoutFilters, needle, N);
  }

  Future<String> waitUntilStderrContains(String needle) {
    return _waitUntilContains(_stderr, _stderrFilters, needle, 1);
  }

  Future<String> waitUntilstderrContainsN(String needle, int N) {
    return _waitUntilContains(_stderr, _stderrFilters, needle, N);
  }

  Future<String> _waitUntilContains(
      List<String> lines, Set<_Filter> filterSet, String needle, int N) {
    int count = 0;

    bool handleLine(String line) {
      // Sometimes the prints of the isolates get interleaved, so we allow
      // multiple matches on one line.
      int index = line.indexOf(needle);
      while (index >= 0) {
        if (++count == N) return true;
        index = line.indexOf(needle, index + 1);
      }
      return false;
    }

    for (final line in lines) {
      if (handleLine(line)) return Future.value(line);
    }
    final c = Completer<String>();
    filterSet.add(_Filter(needle, (line) {
      if (handleLine(line)) {
        c.complete(line);
        return true;
      }
      return false;
    }));
    return c.future;
  }

  void _addStdout(String line) {
    _stdout.add(line);
    _handleNewLine(_stdoutFilters, line);
  }

  void _addStderr(String line) {
    _stderr.add(line);
    _handleNewLine(_stderrFilters, line);
  }

  void _handleNewLine(Set<_Filter> filters, String line) {
    final toRemove = <_Filter>[];
    for (final filter in filters) {
      if (line.contains(filter.needle)) {
        if (filter.callback(line)) {
          toRemove.add(filter);
        }
      }
    }
    for (final filter in toRemove) {
      filters.remove(filter);
    }
  }
}

class _Filter {
  final String needle;
  final bool Function(String line) callback;
  _Filter(this.needle, this.callback);
}
