// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';

import 'package:dart2wasm/js_runtime_blob.dart';

// TODO(joshualitt): Breakup the runtime blob and tree shake unused JS from the
// runtime.
String generateJSRuntime(Component component, CoreTypes coreTypes) {
  return jsRuntimeBlob;
}
