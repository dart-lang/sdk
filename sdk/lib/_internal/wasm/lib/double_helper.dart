// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart._double_helper;

/// Wasm i64.trunc_sat_f64_s instruction
external int toInt(double value);

/// Wasm f64.copysign instruction
external double copysign(double value, double other);
