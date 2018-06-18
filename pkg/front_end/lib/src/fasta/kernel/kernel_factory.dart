// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' show Statement, Expression, Initializer;

import 'factory.dart' show Factory;

/// Implementation of [Factory] that builds source code into a kernel
/// representation.
class KernelFactory implements Factory<Statement, Expression, Initializer> {}
