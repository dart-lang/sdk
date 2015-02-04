// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.validator.size;

import 'dart:async';
import 'dart:math' as math;

import '../entrypoint.dart';
import '../validator.dart';

/// The maximum size of the package to upload (10 MB).
const _MAX_SIZE = 10 * 1024 * 1024;

/// A validator that validates that a package isn't too big.
class SizeValidator extends Validator {
  final Future<int> packageSize;

  SizeValidator(Entrypoint entrypoint, this.packageSize)
      : super(entrypoint);

  Future validate() {
    return packageSize.then((size) {
      if (size <= _MAX_SIZE) return;
      var sizeInMb = (size / math.pow(2, 20)).toStringAsPrecision(4);
      errors.add(
          "Your package is $sizeInMb MB. Hosted packages must be " "smaller than 10 MB.");
    });
  }
}

