// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:smith/smith.dart';

/// A rudimentary script to print the configurations in the given test matrix
/// file.
void main(List<String> arguments) {
  // TODO(rnystrom): Validate args. Usage.
  var matrix = TestMatrix.fromPath(arguments[0]);
  for (var configuration in matrix.configurations) {
    print(configuration);
  }
}
