// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that we can `import()` a `TrustedScriptURL`.

import 'dart:js_interop';

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

extension type Module(JSObject _) implements JSObject {
  external String testModuleFunction();
}

@JS()
external TrustedTypePolicyFactory get trustedTypes;

extension type TrustedTypePolicyFactory._(JSObject _) implements JSObject {
  external TrustedTypePolicy createPolicy(String policyName,
      [TrustedTypePolicyOptions policyOptions]);
}

extension type TrustedTypePolicyOptions._(JSObject _) implements JSObject {
  external factory TrustedTypePolicyOptions({JSFunction createScriptURL});
}

extension type TrustedTypePolicy._(JSObject _) implements JSObject {
  external TrustedScriptURL createScriptURL(String input);
}

extension type TrustedScriptURL._(JSObject _) implements JSObject {}

void main() {
  asyncTest(() async {
    final trustedScriptURL = trustedTypes
        .createPolicy(
            'scriptUrl',
            TrustedTypePolicyOptions(
                createScriptURL: ((JSString url) => url).toJS))
        .createScriptURL(
            '/root_dart/tests/lib/js/static_interop_test/import/module.mjs');
    final module = Module(await importModule(trustedScriptURL).toDart);
    Expect.equals(module.testModuleFunction(), 'success');
  });
}
