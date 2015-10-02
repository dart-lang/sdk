// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// API to get results from a static analysis of the source program.
// TODO(sigmund): split out implementations out of this file.
library compiler.src.stats.naive_analysis_result;

import 'analysis_result.dart';
import '../tree/tree.dart' show Node;
import '../universe/selector.dart' show Selector;

/// A naive [AnalysisResult] that tells us very little. This is the most
/// conservative we can be when we only use information from the AST structure
/// and from resolution, but no type information.
class NaiveAnalysisResult implements AnalysisResult {
  NaiveAnalysisResult();

  ReceiverInfo infoForReceiver(Node receiver) =>
    new NaiveReceiverInfo(receiver);
  SelectorInfo infoForSelector(Node receiver, Selector selector) =>
    new NaiveSelectorInfo(receiver, selector);
}

class NaiveReceiverInfo implements ReceiverInfo {
  final Node receiver;

  NaiveReceiverInfo(this.receiver);
  Boolish get hasNoSuchMethod => Boolish.maybe;
  Boolish get isNull => Boolish.maybe;
  int get possibleNsmTargets => -1;
}

class NaiveSelectorInfo implements SelectorInfo {
  final Node receiver;
  final Selector selector;

  NaiveSelectorInfo(this.receiver, this.selector);

  Boolish get exists => Boolish.maybe;
  Boolish get usesInterceptor => Boolish.maybe;
  int get possibleTargets => -1;
  bool get isAccurate => false;
}
