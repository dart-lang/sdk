// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test lowerings of function conversions to and from JS. Tests functions with
// 0-6 args (with and without function subtyping) as some of these may be
// optimized.

import 'dart:js_interop';

void main() {
  var jsFunction = () {}.toJS;

  ((int arg1) => arg1).toJS;
  ((([int? arg1]) => arg1) as void Function()).toJS;

  ((int arg1, String arg2) => arg2).toJS;
  ((([int? arg1, String? arg2]) => arg2) as void Function([int])).toJS;

  ((int arg1, String arg2, JSArray arg3) => arg3).toJS;
  (((int arg1, [String? arg2, JSArray? arg3]) => arg3) as void Function(int,
          [String]))
      .toJS;

  ((int arg1, String arg2, JSArray arg3, JSObject arg4) => arg4).toJS;
  (((int arg1, String arg2, JSArray arg3, [JSObject? arg4]) => arg4) as void
          Function(int, String, JSArray))
      .toJS;

  ((int arg1, String arg2, JSArray arg3, JSObject arg4, JSPromise arg5) => arg5)
      .toJS;
  (((int arg1, String arg2, [JSArray? arg3, JSObject? arg4, JSPromise? arg5]) =>
          arg5) as void Function(int, String, [JSArray?, JSObject?]))
      .toJS;

  ((int arg1, String arg2, JSArray arg3, JSObject arg4, JSPromise arg5,
          JSAny arg6) =>
      arg6).toJS;
  (((int arg1, String arg2, JSArray arg3, JSObject arg4,
              [JSPromise? arg5, JSAny? arg6]) =>
          arg6) as void Function(int, String, JSArray, JSObject, [JSPromise?]))
      .toJS;

  jsFunction.toDart;
}
