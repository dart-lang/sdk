// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "core_patch.dart";

@patch
class StackTrace {
  @patch
  @pragma("wasm:entry-point")
  static StackTrace get current =>
      _JavaScriptStack(JS<WasmExternRef?>("() => new Error().stack"));
}

class _JavaScriptStack implements StackTrace {
  // May be null.
  final WasmExternRef? stack;

  // Note: We remove the first two frames to prevent including
  // `StackTrace.current` and the JS interop function. On Chrome, the first line
  // is not a frame but a line with just "Error", sometimes with details:
  // "Error: ...". Also remove that line.
  late final String _stringified = stack.isNull
      ? ""
      : JSStringImpl.fromRefUnchecked(
          JS<WasmExternRef?>(r"""(exn) => {
            let stackString = exn.toString();
            let frames = stackString.split('\n');
            let drop = 2;
            if (frames[0].startsWith('Error')) {
                drop += 1;
            }
            return frames.slice(drop).join('\n');
          }""", stack),
        );

  _JavaScriptStack(this.stack);

  @override
  String toString() => _stringified;
}
