// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// API to get results from a static analysis of the source program.
library compiler.src.stats.analysis_result;

import '../tree/tree.dart' show Node;
import '../universe/selector.dart' show Selector;

/// A three-value logic bool (yes, no, maybe). We say that `yes` and `maybe` are
/// "truthy", while `no` and `maybe` are "falsy".
// TODO(sigmund): is it worth using an enum? or switch to true/false/null?
enum Boolish { yes, no, maybe }

/// Specifies results of some kind of static analysis on a source program.
abstract class AnalysisResult {
  /// Information computed about a specific [receiver].
  ReceiverInfo infoForReceiver(Node receiver);

  /// Information computed about a specific [selector] applied to a specific
  /// [receiver].
  SelectorInfo infoForSelector(Node receiver, Selector selector);
}

/// Analysis information about a receiver of a send.
abstract class ReceiverInfo {
  /// Receiver node for which this information is computed.
  Node get receiver;

  /// Return whether [receiver] resolves to a value that implements no such
  /// method. The answer is `yes` if all values that [receiver] could evaluate
  /// to at runtime contain it, or `no` if none of them does. Maybe if it
  /// depends on some context or we can't determine this information precisely.
  Boolish get hasNoSuchMethod;

  /// When [hasNoSuchMethod] is yes, the precise number of possible noSuchMethod
  /// handlers for this receiver.
  int get possibleNsmTargets;

  /// Return whether [receiver] may ever be null.
  Boolish get isNull;
}

/// Information about a specific selector applied to a specific receiver.
abstract class SelectorInfo {
  /// Receiver node of the [selector].
  Node get receiver;

  /// Specific selector on [receiver] for which this information is computed.
  Selector get selector;

  /// Whether a member matching [selector] exists in [receiver].
  Boolish get exists;

  /// Whether [receiver] needs an interceptor to implement [selector].
  Boolish get usesInterceptor;

  /// Possible total number of methods that could be the target of the selector.
  /// This needs to be combined with [isAccurate] to correctly understand the
  /// value. Some invariants:
  ///
  ///   * If [exists] is `no`, the value here should be 0, regardless of
  ///   accuracy.
  ///   * If [exists] is `yes`, the value is always considered 1 or more.
  ///     If [isAccurate] is false, we treat it as there may be many possible
  ///     targets.
  ///   * If [exists] is `maybe`, the value is considered 0 or more.
  int get possibleTargets;

  /// Whether the information about [possibleTargets] is accurate.
  bool get isAccurate;
}
