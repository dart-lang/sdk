// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer2dart.closedWorld;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/element.dart';

/**
 * Container for the elements and AST nodes which have been determined by
 * tree shaking to be reachable by the program being compiled.
 */
class ClosedWorld {
  // TODO(paulberry): is it a problem to hold on to all the AST's for the
  // duration of tree shaking & CPS generation?
  Map<Element, AstNode> elements = <Element, AstNode>{};
  ClosedWorld();
}
