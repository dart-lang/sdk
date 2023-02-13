// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "core_patch.dart";

@patch
class StackTrace {
  @patch
  @pragma("wasm:entry-point")
  static StackTrace get current {
    // `Error` should be supported in most browsers.  A possible future
    // optimization we could do is to just save the `Error` object here, and
    // stringify the stack trace when it is actually used
    //
    // Note:  We remove the last three lines of the stack trace to prevent
    // including `Error`, `getCurrentStackTrace`, and `StackTrace.current` in
    // the stack trace.
    return _StringStackTrace(JS<String>(r"""() => {
          let stackString = new Error().stack.toString();
          let userStackString = stackString.split('\n').slice(3).join('\n');
          return stringToDartString(userStackString);
        }"""));
  }
}
