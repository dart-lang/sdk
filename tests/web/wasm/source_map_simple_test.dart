// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=--extra-compiler-option=-DTEST_COMPILATION_DIR=$TEST_COMPILATION_DIR

import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:convert';

import 'package:source_maps/parser.dart';

void f() {
  g();
}

void g() {
  throw 'hi';
}

void main() {
  // Read source map of the current program.
  final compilationDir = const String.fromEnvironment("TEST_COMPILATION_DIR");
  final sourceMapFileContents =
      readfile('$compilationDir/source_map_simple_test.wasm.map');
  final mapping = parse(utf8.decode(sourceMapFileContents)) as SingleMapping;

  // Get some simple stack trace.
  String? stackTraceString;
  try {
    f();
  } catch (e, st) {
    stackTraceString = st.toString();
  }

  // Print the stack trace to make it easy to update the test.
  print("-----");
  print(stackTraceString);
  print("-----");

  final stackTraceLines = stackTraceString!.split('\n');

  // Stack trace should look like:
  //
  //   at Error._throwWithCurrentStackTrace (wasm://wasm/00118b26:wasm-function[144]:0x163e0)
  //   at f (wasm://wasm/00118b26:wasm-function[996]:0x243dd)
  //   at main (wasm://wasm/00118b26:wasm-function[988]:0x241dc)
  //   at main tear-off trampoline (wasm://wasm/00118b26:wasm-function[990]:0x24340)
  //   at _invokeMain (wasm://wasm/00118b26:wasm-function[104]:0x15327)
  //   at Module.invoke (/usr/local/google/home/omersa/dart/sdk/test/test.mjs:317:26)
  //   at main (/usr/local/google/home/omersa/dart/sdk/sdk/pkg/dart2wasm/bin/run_wasm.js:421:21)
  //   at async action (/usr/local/google/home/omersa/dart/sdk/sdk/pkg/dart2wasm/bin/run_wasm.js:350:37)
  //
  // The first 5 frames are in Wasm, but "main tear-off trampoline" shouldn't
  // have a source mapping as it's compiler generated.

  // (function name, line, column) of the frames we check.
  //
  // Information we don't check are "null": we don't want to check line/column
  // of standard library functions to avoid breaking the test with unrelated
  // changes to the standard library.
  const List<(String, int?, int?)?> frameDetails = [
    ("_throwWithCurrentStackTrace", null, null),
    ("g", 18, 3),
    ("f", 14, 3),
    ("main", 31, 5),
    null, // compiler generated, not mapped
    ("_invokeMain", null, null),
  ];

  for (int frameIdx = 0; frameIdx < frameDetails.length; frameIdx += 1) {
    final line = stackTraceLines[frameIdx];
    final hexOffsetMatch = stackTraceHexOffsetRegExp.firstMatch(line);
    if (hexOffsetMatch == null) {
      throw "Unable to parse hex offset from stack frame $frameIdx";
    }
    final hexOffsetStr = hexOffsetMatch.group(1)!; // includes '0x'
    final offset = int.tryParse(hexOffsetStr);
    if (offset == null) {
      throw "Unable to parse hex number in frame $frameIdx: $hexOffsetStr";
    }
    final span = mapping.spanFor(0, offset);
    final frameInfo = frameDetails[frameIdx];
    if (frameInfo == null) {
      if (span != null) {
        throw "Stack frame $frameIdx should not have a source span, but it is mapped: $span";
      }
      continue;
    }
    if (span == null) {
      throw "Stack frame $frameIdx does not have source mapping";
    }
    final funName = span.text;
    if (frameInfo.$1 != funName) {
      throw "Stack frame $frameIdx does not have expected name: expected ${frameInfo.$1}, found $funName";
    }
    if (frameInfo.$2 != null) {
      if (span.start.line + 1 != frameInfo.$2) {
        throw "Stack frame $frameIdx is expected to have line ${frameInfo.$2}, but it has line ${span.start.line + 1}";
      }
    }
    if (frameInfo.$3 != null) {
      if (span.start.column + 1 != frameInfo.$3) {
        throw "Stack frame $frameIdx is expected to have column ${frameInfo.$3}, but it has column ${span.start.column + 1}";
      }
    }
  }
}

/// Read the file at the given [path].
///
/// This relies on the `readbuffer` function provided by d8.
@JS()
external JSArrayBuffer readbuffer(JSString path);

/// Read the file at the given [path].
Uint8List readfile(String path) => Uint8List.view(readbuffer(path.toJS).toDart);

final stackTraceHexOffsetRegExp = RegExp(r'wasm-function.*(0x[0-9a-fA-F]+)\)$');
