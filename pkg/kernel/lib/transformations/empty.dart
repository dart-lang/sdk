// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.transformations.empty;

import '../ast.dart';
import '../kernel.dart';
import '../visitor.dart';

Component transformComponent(Component component) {
  new EmptyTransformer().visitComponent(component);
  return component;
}

class EmptyTransformer extends Transformer {}
