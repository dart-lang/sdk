// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

import 'function_builder.dart';

abstract class ConstructorBuilder implements FunctionBuilder {
  /// The member target used for tearing of the constructor.
  @override
  Member get readTarget;

  /// The member target used for calling the constructor.
  @override
  Member get invokeTarget;
}
