// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:unified_analytics/unified_analytics.dart';

import 'sdk.dart';

/// Create the `Analytics` instance to be used to report analytics.
Analytics createUnifiedAnalytics() {
  return Analytics(
      tool: DashTool.dartTools, dartVersion: Runtime.runtime.version);
}
