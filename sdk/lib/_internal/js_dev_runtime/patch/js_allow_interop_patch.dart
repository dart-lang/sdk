// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch file for dart:js_util library.
import 'dart:_foreign_helper' show JS;
import 'dart:_internal' show patch;
import 'dart:_runtime' as dart;

Expando<Function> _interopExpando = Expando<Function>();

@patch
F allowInterop<F extends Function>(F f) {
  if (!dart.isDartFunction(f)) return f;
  var ret = _interopExpando[f] as F?;
  if (ret == null) {
    ret = JS<F>(
        '',
        'function (...args) {'
            ' return #(#, args);'
            '}',
        dart.dcall,
        f);
    _interopExpando[f] = ret;
  }
  return ret;
}

Expando<Function> _interopCaptureThisExpando = Expando<Function>();

@patch
Function allowInteropCaptureThis(Function f) {
  if (!dart.isDartFunction(f)) return f;
  var ret = _interopCaptureThisExpando[f];
  if (ret == null) {
    ret = JS<Function>(
        '',
        'function(...arguments) {'
            '  let args = [this];'
            '  args.push.apply(args, arguments);'
            '  return #(#, args);'
            '}',
        dart.dcall,
        f);
    _interopCaptureThisExpando[f] = ret;
  }
  return ret;
}
