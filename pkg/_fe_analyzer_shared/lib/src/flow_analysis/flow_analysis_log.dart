// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:_fe_analyzer_shared/src/flow_analysis/flow_link.dart';
import 'package:_fe_analyzer_shared/src/type_inference/promotion_key_store.dart';
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:meta/meta.dart';

/// A flow analysis log records the intermediate inference states of flow
/// analysis, in a form that can be queried based on source offset.
class FlowAnalysisLog {
  /// List of offsets at which the [PromotionInfo] tracked by flow analysis may
  /// have changed.
  ///
  /// If this list is empty, then the code that was analyzed had no flow
  /// analysis effects, and so the [PromotionInfo] tracked by flow analysis was
  /// `null` throughout analysis.
  ///
  /// This list and [_promotionInfoValues] are gathered in the order in which
  /// the user's program is visited by type analysis, which is not necessarily
  /// the same as source order, due to the "updater" part of a "for" loop being
  /// visited after the body. The lists are sorted by offset before executing
  /// the first query. [_areListsSorted] indicates whether the sort has occurred
  /// yet.
  final List<int> _promotionInfoOffsets = [];

  /// List of [PromotionInfo] pointers, corresponding to the offsets in
  /// [_promotionInfoOffsets].
  final List<PromotionInfo?> _promotionInfoValues = [];

  /// List of offsets at which the binding of `this` may have changed.
  ///
  /// If this list is empty, then the code that was analyzed had neither
  /// rebindings of `this` nor promotions of it, and so flow analysis did not
  /// see fit to track the binding of `this`; in this case, `this` was
  /// unpromoted throughout the code that was analyzed.
  ///
  /// This list and [_thisBindingValues] are gathered in the order in which the
  /// user's program is visited by type analysis, which is not necessarily the
  /// same as source order, due to the "updater" part of a "for" loop being
  /// visited after the body. The lists are sorted by offset before executing
  /// the first query. [_areListsSorted] indicates whether the sort has occurred
  /// yet.
  final List<int> _thisBindingOffsets = [];

  /// List of promotion keys bound to `this`, corresponding to the offsets in
  /// [_thisBindingOffsets].
  final List<PromotionKey> _thisBindingValues = [];

  /// The promotion key bound to `this` at the beginning of flow analysis, prior
  /// to any changes noted in [_thisBindingValues] and [_thisBindingOffsets].
  PromotionKey? _initialThisBinding;

  /// Whether the lists [_promotionInfoOffsets], [_promotionInfoValues],
  /// [_thisBindingOffsets], and [_thisBindingValues] have been sorted by offset
  /// yet.
  bool _areListsSorted = false;

  /// [FlowLinkReader] object for efficiently looking up [PromotionModel]
  /// objects in [FlowModel.promotionInfo] structures.
  late final FlowLinkReader<PromotionInfo> _reader =
      new FlowLinkReader<PromotionInfo>();

  FlowAnalysisLog._();

  /// Retrieves the full [PromotionInfo] map that was in effect at the given
  /// source code [offset].
  ///
  /// If one or more state transitions occurred precisely at [offset], the
  /// promotion info that is returned is the promotion info that was in effect
  /// just to the left of [offset].
  @visibleForTesting
  PromotionInfo? getPromotionInfo(int offset) {
    if (!_areListsSorted) {
      _sortList(values: _promotionInfoValues, offsets: _promotionInfoOffsets);
      _sortList(values: _thisBindingValues, offsets: _thisBindingOffsets);
      _areListsSorted = true;
    }
    return _lookupInList<PromotionInfo?>(
      values: _promotionInfoValues,
      offsets: _promotionInfoOffsets,
      offset: offset,
    );
  }

  /// Retrieves the promotion key for `this` that was in effect at the given
  /// source code [offset].
  ///
  /// If there was no reference to `this` that was relevant to flow analysis in
  /// the code that was analyzed, `null` is returned.
  ///
  /// If one or more changes to the binding of `this` occurred precisely at
  /// [offset], the promotion key that is returned is the promotion key for
  /// `this` that was in effect just to the left of [offset].
  @visibleForTesting
  PromotionKey? getThisBinding(int offset) {
    if (!_areListsSorted) {
      _sortList(values: _promotionInfoValues, offsets: _promotionInfoOffsets);
      _sortList(values: _thisBindingValues, offsets: _thisBindingOffsets);
      _areListsSorted = true;
    }
    return _lookupInList(
          values: _thisBindingValues,
          offsets: _thisBindingOffsets,
          offset: offset,
        ) ??
        _initialThisBinding;
  }

  /// Retrieves the promoted type of `this` that was in effect at the given
  /// source code [offset].
  ///
  /// If `this` was not promoted at the given [offset], `null` is returned.
  ///
  /// If one or more changes to the promotion of `this` occurred precisely at
  /// [offset], the type that is returned is the promoted type of `this` that
  /// was in effect just to the left of [offset].
  SharedTypeView? lookupPromotedThisType({required int offset}) {
    PromotionKey? thisBinding = getThisBinding(offset);
    if (thisBinding == null) return null;
    return _reader
        .get(getPromotionInfo(offset), thisBinding.index)
        ?.model
        .promotedTypes
        .lastOrNull;
  }

  /// Binary searches in [offsets] to find the given [offset], and returns the
  /// corresponding value from [values].
  ///
  /// Pre-condition: [offsets] must be in non-decreasing order.
  ///
  /// More precisely:
  /// - If [offset] is less than or equal to all elements of [offsets]
  ///   (or [offsets] is empty), `null` is returned.
  /// - Otherwise, if [offset] is greater than all values in [offsets] (and
  ///   [offsets] is non-empty), the last entry in [offsets] is returned.
  /// - Otherwise, this method finds the unique index `i` such that
  ///   `offsets[i] < offset <= offsets[i + 1]`, and returns the corresponding
  ///   `values[i]`.
  T? _lookupInList<T>({
    required List<T> values,
    required List<int> offsets,
    required int offset,
  }) {
    int len = offsets.length;
    assert(values.length == len);
    if (offsets.isEmpty || offset <= offsets.first) return null;
    int minIndex = 0;
    int maxIndex = len;
    // Loop invariants:
    // - offsets[minIndex] < offset
    // - maxIndex == len || offset <= offsets[maxIndex]
    while (true) {
      int span = maxIndex - minIndex;
      if (span < 2) return values[minIndex];
      int probeIndex = minIndex + span ~/ 2;
      if (offsets[probeIndex] < offset) {
        minIndex = probeIndex;
      } else {
        maxIndex = probeIndex;
      }
    }
  }

  /// Stably sorts the lists [offsets] and [values] in parallel, using the
  /// integers in [offsets] as a sort key.
  void _sortList<T>({required List<T> values, required List<int> offsets}) {
    // There's no built-in method that stably sorts two lists in parallel, so
    // the most straightforward way to do the sort is to combine the lists into
    // a list of tuples, sort the list of tuples, and then copy the values from
    // the sorted list of tuples back to the original lists.
    //
    // Note that it would be possible to improve performance by writing a custom
    // sort algorithm that sorts the lists in place, but it's not worth it,
    // since this code is only exercised in response to direct user action (code
    // completion in the analysis server, expression evaluation in the
    // debugger).
    assert(values.length == offsets.length);
    List<(int, int, T)> triples = [
      // Ensure stability by including `i` in the tuple (`List.sort` does not
      // natively guarantee a stable sort).
      for (int i = 0; i < values.length; i++) (offsets[i], i, values[i]),
    ];
    // Sort first by offset, then by original array position (to ensure a
    // stable sort)
    triples.sort((x, y) {
      if (x.$1.compareTo(y.$1) case var result when result != 0) return result;
      return x.$2.compareTo(y.$2);
    });
    // Rebuild the input arrays.
    for (int i = 0; i < values.length; i++) {
      values[i] = triples[i].$3;
      offsets[i] = triples[i].$1;
    }
  }
}

/// Interface used by [FlowAnalysis] to build a [FlowAnalysisLog].
class FlowAnalysisLogBuilder extends FlowAnalysisLog {
  /// The minimum offset value that will be accepted by [checkOffset] without an
  /// assertion failure.
  ///
  /// Debug only: this variable is only accessed from within asserts.
  ///
  /// This is used as a safety check to verify that the offsets being recorded
  /// in the log are sensible.
  int _minValidOffset = 0;

  FlowAnalysisLogBuilder() : super._();

  /// Resets [_minValidOffset], allowing the next call to [checkOffset] to
  /// violate the usual requirement that offsets must be nondecreasing.
  ///
  /// This method has no effect when asserts are disabled.
  ///
  /// This method should be called whenever type analysis visits the parts of a
  /// construct in a different order from the order in which it's written. For
  /// example, type analysis visits the body of a classic `for` loop before the
  /// updaters (even though the updaters appear before the body in the source
  /// code). Therefore, this method should be called after visiting the body and
  /// before visiting the updaters, to avoid a spurious assertion from
  /// [checkOffset] during analysis of the updaters.
  void allowOutOfOrderOffsets() {
    assert(() {
      _minValidOffset = 0;
      return true;
    }());
  }

  /// Sanity checks the given [offset], making sure that offsets are always in
  /// nondecreasing order.
  ///
  /// The sanity check is done using an assertion, so this method has no effect
  /// when assertions are disabled.
  void checkOffset(int offset) {
    assert(offset >= _minValidOffset, 'Offsets out of order');
    assert(() {
      _minValidOffset = offset;
      return true;
    }());
  }

  /// Returns the fully created [FlowAnalysisLog].
  FlowAnalysisLog finish() => this;

  /// Records that at [offset], the promotion info changed to [promotionInfo].
  void promotionInfoChanged(
    PromotionInfo? promotionInfo, {
    required int offset,
  }) {
    assert(
      !_areListsSorted,
      'For efficiency, all flow analysis should be completed before sorting '
      'the flow analysis logs.',
    );
    checkOffset(offset);
    _promotionInfoOffsets.add(offset);
    _promotionInfoValues.add(promotionInfo);
  }

  /// Records that the initial binding for `this` was [thisPromotionKey].
  void recordInitialThisBinding(PromotionKey thisPromotionKey) {
    assert(
      !_areListsSorted,
      'For efficiency, all flow analysis should be completed before sorting '
      'the flow analysis logs.',
    );
    // Note: no call to `checkOffset` because the initial `this` binding is
    // deliberately set lazily.
    assert(
      _thisBindingOffsets.isEmpty,
      'The initial `this` binding should be established before any other '
      '`this` bindings are recorded.',
    );
    assert(
      _initialThisBinding == null,
      'The initial `this` binding should only be set once.',
    );
    _initialThisBinding = thisPromotionKey;
  }

  /// Records that at [offset], the binding for `this` changed to
  /// [thisPromotionKey].
  void thisBindingChanged(
    PromotionKey thisPromotionKey, {
    required int offset,
  }) {
    assert(
      !_areListsSorted,
      'For efficiency, all flow analysis should be completed before sorting '
      'the flow analysis logs.',
    );
    assert(
      _initialThisBinding != null,
      'The initial `this` binding should be established before any other '
      '`this` bindings are recorded.',
    );
    checkOffset(offset);
    _thisBindingOffsets.add(offset);
    _thisBindingValues.add(thisPromotionKey);
  }
}
