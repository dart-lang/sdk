// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tests that the Node.js check for Windows `Uri` semantics is only compiled
/// into programs built with `--server-mode`, regardless of whether deprecated
/// JS interop is enabled.

import 'package:compiler/compiler_api.dart' as api;
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/util/memory_compiler.dart';
import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';

/// A program whose output depends on whether `Uri` uses Windows semantics.
const Map<String, String> _sources = {
  'main.dart': '''
void main() {
  print(Uri.file('a/b').toFilePath());
}
''',
};

/// Part of the check for whether a program is running on Node.js on Windows.
const String _windowsCheck = 'process.platform == "win32"';

void main() {
  asyncTest(() async {
    await _expectWindowsCheck([], isIncluded: false);
    await _expectWindowsCheck([Flags.noDeprecatedJsInterop], isIncluded: false);
    await _expectWindowsCheck([Flags.serverMode], isIncluded: true);
    await _expectWindowsCheck([
      Flags.serverMode,
      Flags.noDeprecatedJsInterop,
    ], isIncluded: true);
  });
}

/// Compiles [_sources] with [options] and expects the Windows check to be
/// included in the output if [isIncluded] is `true`.
Future<void> _expectWindowsCheck(
  List<String> options, {
  required bool isIncluded,
}) async {
  final output = await _compile(options);
  Expect.equals(isIncluded, output.contains(_windowsCheck), '$options');
}

/// Compiles [_sources] with [options] and returns the JavaScript output.
Future<String> _compile(List<String> options) async {
  final collector = OutputCollector();
  final result = await runCompiler(
    memorySourceFiles: _sources,
    outputProvider: collector,
    options: options,
  );
  Expect.isTrue(result.isSuccess, '$options');
  return collector.getOutput('', api.OutputType.js)!;
}
