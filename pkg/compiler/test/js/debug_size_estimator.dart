// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/js/size_estimator.dart';

/// This class is supposed to be identical to [SizeEstimator] with the sole
/// difference that it builds up strings to help debug estimates.
class DebugSizeEstimator extends SizeEstimator {
  StringBuffer resultBuffer = StringBuffer();
  String get resultString => resultBuffer.toString();

  @override
  void emit(String s) {
    resultBuffer.write(s);
    super.emit(s);
  }
}
