// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    hide AnalysisError;
import 'package:analyzer_plugin/utilities/outline/outline.dart';

/**
 * A concrete implementation of [DartOutlineRequest].
 */
class DartOutlineRequestImpl implements DartOutlineRequest {
  @override
  final ResourceProvider resourceProvider;

  @override
  final ResolveResult result;

  /**
   * Initialize a newly create request with the given data.
   */
  DartOutlineRequestImpl(this.resourceProvider, this.result);

  @override
  String get path => result.path;
}

/**
 * A concrete implementation of [OutlineCollector].
 */
class OutlineCollectorImpl implements OutlineCollector {
  /**
   * A list containing the top-level outline nodes.
   */
  List<Outline> outlines = <Outline>[];

  /**
   * A stack keeping track of the outline nodes that have been started but not
   * yet ended.
   */
  List<Outline> outlineStack = <Outline>[];

  @override
  void endElement() {
    outlineStack.removeLast();
  }

  @override
  void startElement(Element element, int offset, int length) {
    Outline outline = new Outline(element, offset, length);
    if (outlineStack.isEmpty) {
      outlines.add(outline);
    } else {
      List<Outline> children = outlineStack.last.children;
      if (children == null) {
        children = <Outline>[];
        outlineStack.last.children = children;
      }
      children.add(outline);
    }
    outlineStack.add(outline);
  }
}
