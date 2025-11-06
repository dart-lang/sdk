// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/error/element_usage_detector.dart';

/// Algorithm for detecting the usage frontier of a set of elements.
///
/// The "usage frontier" of a set of elements is defined as the locations in
/// source code where elements that are _not_ in the set make use of elements
/// that _are_ in the set.
class ElementUsageFrontierDetector<TagInfo extends Object>
    extends ElementUsageDetector<TagInfo> {
  /// Stack corresponding to elements being visited that might be in
  /// [elementUsageSet].
  ///
  /// Each element indicates whether the corresponding element is in
  /// [elementUsageSet] or not.
  final List<bool> _inElementStack = [false];

  ElementUsageFrontierDetector({
    required super.workspacePackage,
    required super.elementUsageSet,
    required super.elementUsageReporter,
  });

  @override
  void checkUsage(Element? element, AstNode node) {
    if (_inElementStack.last) {
      return;
    }

    super.checkUsage(element, node);
  }

  void popElement() {
    _inElementStack.removeLast();
  }

  void pushElement(Element? element) {
    var value = element != null && elementUsageSet.getTagInfo(element) != null;
    var newValue = _inElementStack.last || value;
    _inElementStack.add(newValue);
  }
}
