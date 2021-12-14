// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_utilities/check/check_target.dart';
import 'package:meta/meta.dart';

export 'package:analyzer_utilities/check/bool.dart';
export 'package:analyzer_utilities/check/check_target.dart';
export 'package:analyzer_utilities/check/equality.dart';
export 'package:analyzer_utilities/check/int.dart';
export 'package:analyzer_utilities/check/iterable.dart';
export 'package:analyzer_utilities/check/nullability.dart';
export 'package:analyzer_utilities/check/string.dart';
export 'package:analyzer_utilities/check/type.dart';

@useResult
CheckTarget<T> check<T>(T value) {
  return CheckTarget(value, 0, () => '$value');
}
