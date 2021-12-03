// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

export '_startup_metrics_unknown.dart'
    if (dart.library._dart2js_runtime_metrics) '_startup_metrics_dart2js.dart'
    if (dart.library.ffi) '_startup_metrics_vm.dart'
    if (dart.library.js) '_startup_metrics_dartdevc.dart';
