// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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

runtimeFalse() => int.parse('1') == 0;

// `frameDetails` is (line, column) of the frames we check.
//
// Information we don't check are "null": we don't want to check line/column
// of standard library functions to avoid breaking the test with unrelated
// changes to the standard library.
void testMain(String testName, List<(int?, int?)?> frameDetails) {
  // Use `f` and `g` in a few places to make sure wasm-opt won't inline them
  // in the test.
  final fTearOff = f;
  final gTearOff = g;

  if (runtimeFalse()) f();
  if (runtimeFalse()) g();

  // Read source map of the current program.
  final compilationDir = const String.fromEnvironment("TEST_COMPILATION_DIR");
  final sourceMapFileContents =
      readfile('$compilationDir/${testName}_test.wasm.map');
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
      print("Stack frame $frameIdx does not have source mapping");
    } else {
      if (frameInfo.$1 != null) {
        if (span.start.line + 1 != frameInfo.$1) {
          throw "Stack frame $frameIdx is expected to have line ${frameInfo.$1}, but it has line ${span.start.line + 1}";
        }
      }
      if (frameInfo.$2 != null) {
        if (span.start.column + 1 != frameInfo.$2) {
          throw "Stack frame $frameIdx is expected to have column ${frameInfo.$2}, but it has column ${span.start.column + 1}";
        }
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
