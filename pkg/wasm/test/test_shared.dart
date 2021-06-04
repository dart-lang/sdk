// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:wasm/src/wasm_error.dart';

Matcher throwsWasmError(Object messageMatcher) => throwsA(
      isA<WasmError>().having((p0) => p0.message, 'message', messageMatcher),
    );
