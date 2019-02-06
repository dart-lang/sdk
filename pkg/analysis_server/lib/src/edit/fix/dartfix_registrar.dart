// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/edit/fix/dartfix_info.dart';
import 'package:analysis_server/src/edit/fix/fix_error_task.dart';
import 'package:analyzer/error/error.dart';

/// Fixes use this API to register tasks. See [DartFixInfo.setup].
abstract class DartFixRegistrar {
  /// Register the specified task to fix the given error condition.
  void registerErrorTask(ErrorCode errorCode, FixErrorTask task);
}
