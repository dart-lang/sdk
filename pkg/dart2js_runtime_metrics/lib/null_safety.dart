// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

export '_null_safety_other.dart'
    if (dart.library._dart2js_runtime_metrics) '_null_safety_dart2js.dart'
    if (dart.library.js) '_null_safety_dartdevc.dart';
