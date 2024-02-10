// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

export '_runtime_metrics_unknown.dart'
    if (dart.library._dart2js_only) '_runtime_metrics_dart2js.dart'
    if (dart.library._ddc_only) '_runtime_metrics_dartdevc.dart';
