// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// V8 runner support used by dartdevrun.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart' show Version;

import '../options.dart' show CompilerOptions;
import 'runtime_utils.dart' show getRuntimeFileAlias;

_parseV8Version(String version) =>
    new Version.parse(version.split('.').getRange(0, 3).join('.'));

final _MIN_SUPPORTED_V8_VERSION = _parseV8Version("4.5.103.30");

/// TODO(ochafik): Move to dart_library.js
const _GLOBALS = r'''
  if (typeof global == 'undefined') var global = this;
  if (typeof alert == 'undefined') var alert = x => console.log(`ALERT: ${x}`);
  if (typeof console == 'undefined') var console = { log: print, error: print };
''';

/// Runner for v8-based JS interpreter binaries.
abstract class V8Runner {
  final CompilerOptions _options;
  V8Runner._(this._options);

  factory V8Runner(CompilerOptions options) {
    String bin = options.runnerOptions.v8Binary;
    switch (basename(bin)) {
      case "iojs":
      case "node":
        return new _NodeRunner(options).._checkVersion();
      case "d8":
        return new _D8Runner(options).._checkVersion();
      default:
        throw new UnsupportedError("Unknown v8-based binary: $bin");
    }
  }

  List<String> get _v8VersionArgs;
  List<String> _getLoadStatements(List<File> files);

  String get _v8Binary => _options.runnerOptions.v8Binary;

  Future<Process> start(List<File> files, String startStatement) =>
      Process.start(
          _v8Binary,
          [
            "--harmony",
            "-e",
            _GLOBALS + _getLoadStatements(files).join() + startStatement
          ],
          workingDirectory: _options.codegenOptions.outputDir);

  /// Throws if the v8 version of this runner is not supported, or if the runner
  /// is not in the path.
  void _checkVersion() {
    ProcessResult result = Process.runSync(_v8Binary, _v8VersionArgs);
    if (result.exitCode != 0) {
      throw new StateError("Failed to run $_v8Binary: ${result.stderr}");
    }
    String v8Version = result.stdout.trim();
    if (_parseV8Version(v8Version).compareTo(_MIN_SUPPORTED_V8_VERSION) < 0) {
      throw new StateError(
          "V8 version $v8Version in $_v8Binary does not meet the required "
          "minimum $_MIN_SUPPORTED_V8_VERSION.");
    }
  }
}

/// Runner for d8 (see https://developers.google.com/v8/build).
class _D8Runner extends V8Runner {
  _D8Runner(options) : super._(options);

  @override
  get _v8VersionArgs => ['-e', 'print(version())'];

  @override
  _getLoadStatements(List<File> files) =>
      files.map((file) => 'load("${file.path}");');
}

/// Runner for iojs (see https://iojs.org/download/next-nightly/) and node.
class _NodeRunner extends V8Runner {
  _NodeRunner(options) : super._(options);

  @override
  get _v8VersionArgs => ['-p', 'process.versions.v8'];

  @override
  _getLoadStatements(List<File> files) => files.map((file) {
        String alias = getRuntimeFileAlias(_options, file);
        return (alias != null ? 'var $alias = ' : '') +
            'require("${file.path}");';
      });
}
