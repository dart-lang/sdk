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
  /// Stack corresponding to elements being visited that might be in ith
  /// [usagesArbitrary], i.e. the first index corresponds to [usagesArbitrary]
  /// and the second index to the stack depth.
  ///
  /// Each element indicates whether the corresponding element is in ith
  /// [usagesArbitrary] or not.
  final List<List<bool>> _inElementStacksArbitrary = [];

  /// Stack corresponding to elements being visited that might be in ith
  /// [usagesMetadataOnly], i.e. the first index corresponds to
  /// [usagesMetadataOnly] and the second index to the stack depth.
  ///
  /// Each element indicates whether the corresponding element is in ith
  /// [usagesMetadataOnly] or not.
  final List<List<bool>> _inElementStacksMetadataOnly = [];

  ElementUsageFrontierDetector({
    required super.workspacePackage,
    required super.usagesAndReporters,
  }) {
    for (int i = 0; i < usagesArbitrary.length; i++) {
      _inElementStacksArbitrary.add([false]);
    }
    for (int i = 0; i < usagesMetadataOnly.length; i++) {
      _inElementStacksMetadataOnly.add([false]);
    }
  }

  @override
  void checkUsage(Element? element, AstNode node) {
    bool allTrue = true;
    for (var inElementStack in _inElementStacksArbitrary) {
      if (!inElementStack.last) {
        allTrue = false;
        break;
      }
    }
    if (allTrue) {
      for (var inElementStack in _inElementStacksMetadataOnly) {
        if (!inElementStack.last) {
          allTrue = false;
          break;
        }
      }
    }
    if (allTrue) return;

    super.checkUsage(element, node);
  }

  void popElement() {
    for (var inElementStack in _inElementStacksArbitrary) {
      inElementStack.removeLast();
    }
    for (var inElementStack in _inElementStacksMetadataOnly) {
      inElementStack.removeLast();
    }
  }

  void pushElement(Element? element) {
    var elementMetadata = element?.metadata;
    for (int i = 0; i < _inElementStacksArbitrary.length; i++) {
      var inElementStack = _inElementStacksArbitrary[i];
      var newValue = inElementStack.last;
      if (!newValue && element != null) {
        var elementUsageSet = usagesArbitrary[i].elementUsageSet;
        newValue =
            elementUsageSet.getTagInfo(element, elementMetadata!) != null;
      }
      inElementStack.add(newValue);
    }
    for (int i = 0; i < _inElementStacksMetadataOnly.length; i++) {
      var inElementStack = _inElementStacksMetadataOnly[i];
      var newValue = inElementStack.last;
      if (!newValue && element != null) {
        var elementUsageSet = usagesMetadataOnly[i].elementUsageSet;
        newValue =
            elementUsageSet.getTagInfo(element, elementMetadata!) != null;
      }
      inElementStack.add(newValue);
    }
  }

  @override
  bool shouldCheckArbitraryForIndex(int i) {
    return !_inElementStacksArbitrary[i].last;
  }

  @override
  bool shouldCheckMetadataOnlyForIndex(int i) {
    return !_inElementStacksMetadataOnly[i].last;
  }
}
