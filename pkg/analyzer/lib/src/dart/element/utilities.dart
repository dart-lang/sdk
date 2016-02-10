// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.dart.element.utilities;

import 'dart:collection';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';

/**
 * A visitor that can be used to collect all of the non-synthetic elements in an
 * element model.
 */
class ElementGatherer extends GeneralizingElementVisitor {
  /**
   * The set in which the elements are collected.
   */
  final Set<Element> elements = new HashSet<Element>();

  /**
   * Initialize the visitor.
   */
  ElementGatherer();

  @override
  void visitElement(Element element) {
    if (!element.isSynthetic) {
      elements.add(element);
    }
    super.visitElement(element);
  }
}
