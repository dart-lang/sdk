// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_internal" show patch;

@pragma("wasm:import", "dart2wasm.parseDouble")
external double _parseDoubleJS(String source);

@patch
double _parseDouble(String source, int start, int end) =>
    _parseDoubleJS(source.substring(start, end));
