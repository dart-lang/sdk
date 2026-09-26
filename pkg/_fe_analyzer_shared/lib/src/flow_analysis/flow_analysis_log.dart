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
  /// This list is in non-decreasing order. Type analysis doesn't always visit
  /// the user's program in source order (for example, the "updater" part of a
  /// "for" loop is visited after the body), but each such construct is recorded
  /// as an *out of order region* (see
  /// [FlowAnalysisLogBuilder.beginOutOfOrderRegion]), and the region's entries
  /// are moved into their proper place as soon as the region is complete.
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
  /// As with [_promotionInfoOffsets], this list is in non-decreasing order.
  final List<int> _thisBindingOffsets = [];

  /// List of promotion keys bound to `this`, and the corresponding unpromoted
  /// types, corresponding to the offsets in [_thisBindingOffsets].
  final List<({PromotionKey promotionKey, SharedTypeView unpromotedType})?>
  _thisBindingValues = [];

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
    return _lookupInList<PromotionInfo?>(
      values: _promotionInfoValues,
      offsets: _promotionInfoOffsets,
      offset: offset,
    );
  }

  /// Retrieves the promotion key for `this`, and the corresponding unpromoted
  /// type, that was in effect at the given source code [offset].
  ///
  /// If one or more changes to the binding of `this` occurred precisely at
  /// [offset], the promotion key that is returned is the promotion key for
  /// `this` that was in effect just to the left of [offset].
  @visibleForTesting
  ({PromotionKey promotionKey, SharedTypeView unpromotedType})? getThisBinding(
    int offset,
  ) {
    return _lookupInList<
      ({PromotionKey promotionKey, SharedTypeView unpromotedType})?
    >(values: _thisBindingValues, offsets: _thisBindingOffsets, offset: offset);
  }

  /// Retrieves the promoted type of `this` that was in effect at the given
  /// source code [offset].
  ///
  /// If `this` was not promoted at the given [offset], `null` is returned.
  ///
  /// If one or more changes to the promotion of `this` occurred precisely at
  /// [offset], the type that is returned is the promoted type of `this` that
  /// was in effect just to the left of [offset].
  SharedTypeView? lookupThisType({required int offset}) {
    ({PromotionKey promotionKey, SharedTypeView unpromotedType})? thisBinding =
        getThisBinding(offset);
    if (thisBinding == null) return null;
    return _reader
            .get(getPromotionInfo(offset), thisBinding.promotionKey.index)
            ?.model
            .promotedTypes
            .lastOrNull ??
        thisBinding.unpromotedType;
  }

  /// Binary searches the sub-range `[minIndex, maxIndex)` of [offsets] and
  /// returns the index at which an entry with the given [offset] belongs.
  ///
  /// Pre-condition: the sub-range of [offsets] being searched must be in
  /// non-decreasing order.
  ///
  /// If the sub-range already contains entries whose offset is exactly
  /// [offset], the index that's returned is after them if [after] is `true`,
  /// and before them if [after] is `false`.
  static int _findInsertionIndex(
    List<int> offsets, {
    required int offset,
    required int minIndex,
    required int maxIndex,
    required bool after,
  }) {
    // Loop invariants (where `low` and `high` are the values [minIndex] and
    // [maxIndex] were called with):
    // - minIndex == low || offsets[minIndex - 1] belongs before the insertion
    //   point
    // - maxIndex == high || offsets[maxIndex] belongs after the insertion point
    while (minIndex < maxIndex) {
      int probeIndex = minIndex + (maxIndex - minIndex) ~/ 2;
      int probeOffset = offsets[probeIndex];
      if (after ? probeOffset <= offset : probeOffset < offset) {
        minIndex = probeIndex + 1;
      } else {
        maxIndex = probeIndex;
      }
    }
    return minIndex;
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
    assert(values.length == offsets.length);
    // Each entry describes the state from its offset onwards, and the state
    // that's wanted is the one just to the left of [offset], so entries whose
    // offset is exactly [offset] have to fall after the insertion point (hence
    // `after: false`), and the entry that's wanted is the one just before it.
    int index = _findInsertionIndex(
      offsets,
      offset: offset,
      minIndex: 0,
      maxIndex: offsets.length,
      after: false,
    );
    return index == 0 ? null : values[index - 1];
  }
}

/// Interface used by [FlowAnalysis] to build a [FlowAnalysisLog].
class FlowAnalysisLogBuilder extends FlowAnalysisLog {
  /// The out of order regions that are currently being recorded, in the order
  /// in which they were begun (so the innermost region is last).
  ///
  /// See [beginOutOfOrderRegion].
  final List<_OutOfOrderRegion> _regionStack = [];

  /// The minimum offset value that will be accepted by [checkOffset] without an
  /// assertion failure.
  ///
  /// Debug only: this variable is only accessed from within asserts.
  ///
  /// This is used as a safety check to verify that the offsets being recorded
  /// in the log are sensible.
  int _minValidOffset = 0;

  FlowAnalysisLogBuilder() : super._();

  /// Records that type analysis is about to visit a construct whose source
  /// range begins at [offset], even though that's not the range that would be
  /// expected based on the order in which type analysis is visiting the user's
  /// program.
  ///
  /// For example, type analysis visits the body of a classic `for` loop before
  /// the updaters (even though the updaters appear before the body in the
  /// source code). Therefore, this method should be called after visiting the
  /// body and before visiting the updaters, and [endOutOfOrderRegion] should be
  /// called once the updaters have been visited.
  ///
  /// Every entry that is recorded between this call and the matching call to
  /// [endOutOfOrderRegion] is understood to describe the source range
  /// `[offset, endOffset]`, where `endOffset` is the offset passed to
  /// [endOutOfOrderRegion]. When the region is complete, its entries are moved
  /// into their proper place in the log, so that the log remains ordered by
  /// source offset.
  ///
  /// [promotionInfo] and [thisBinding] should be the promotion info and the
  /// binding for `this` that are currently in effect; they are used to record
  /// the state that should be considered to be in effect at the beginning of
  /// the region (which, since the region is being visited out of order, is not
  /// necessarily the state that was in effect at the end of whatever construct
  /// precedes the region in the source code).
  ///
  /// Out of order regions may be nested, but they may not partially overlap.
  void beginOutOfOrderRegion({
    required int offset,
    required PromotionInfo? promotionInfo,
    required ({PromotionKey promotionKey, SharedTypeView unpromotedType})?
    thisBinding,
  }) {
    _regionStack.add(
      new _OutOfOrderRegion(
        startOffset: offset,
        promotionInfoIndex: _promotionInfoOffsets.length,
        thisBindingIndex: _thisBindingOffsets.length,
        promotionInfoAtStart: promotionInfo,
        thisBindingAtStart: thisBinding,
        savedMinValidOffset: _minValidOffset,
      ),
    );
    assert(() {
      _minValidOffset = offset;
      return true;
    }());
  }

  /// Sanity checks the given [offset], making sure that offsets are always in
  /// nondecreasing order.
  ///
  /// The sanity check is done using an assertion, so this method has no effect
  /// when assertions are disabled.
  ///
  /// Note that the check is performed independently for each out of order
  /// region (see [beginOutOfOrderRegion]); within a region, offsets must be
  /// nondecreasing, but the first offset in a region is permitted to be less
  /// than the offsets that preceded it.
  void checkOffset(int offset) {
    assert(
      offset >= _minValidOffset,
      'Offsets out of order ($offset < $_minValidOffset)',
    );
    assert(() {
      _minValidOffset = offset;
      return true;
    }());
  }

  /// Records that type analysis has finished visiting the out of order
  /// construct that was begun by the most recent call to
  /// [beginOutOfOrderRegion], and that the construct's source range ends at
  /// [offset].
  ///
  /// The entries that were recorded while the region was open are moved into
  /// their proper place in the log, and entries are inserted at the beginning
  /// and the end of the region as necessary, so that:
  /// - queries in the range `(startOffset, offset]` see the state that flow
  ///   analysis was actually using while it was visiting the region, and
  /// - queries after `offset` see the state that was in effect, in source
  ///   order, just before the region.
  void endOutOfOrderRegion({required int offset}) {
    _OutOfOrderRegion region = _regionStack.removeLast();
    assert(
      offset >= region.startOffset,
      'Out of order region ends before it begins',
    );
    // The region needs to be spliced in among the entries belonging to the
    // enclosing region (or, if there is no enclosing region, among the entries
    // at the top level of the log).
    _OutOfOrderRegion? enclosingRegion = _regionStack.lastOrNull;
    _spliceRegion<PromotionInfo>(
      offsets: _promotionInfoOffsets,
      values: _promotionInfoValues,
      enclosingRegionIndex: enclosingRegion?.promotionInfoIndex ?? 0,
      enclosingValueAtStart: enclosingRegion?.promotionInfoAtStart,
      regionIndex: region.promotionInfoIndex,
      startOffset: region.startOffset,
      endOffset: offset,
      valueAtStart: region.promotionInfoAtStart,
    );
    _spliceRegion<({PromotionKey promotionKey, SharedTypeView unpromotedType})>(
      offsets: _thisBindingOffsets,
      values: _thisBindingValues,
      enclosingRegionIndex: enclosingRegion?.thisBindingIndex ?? 0,
      enclosingValueAtStart: enclosingRegion?.thisBindingAtStart,
      regionIndex: region.thisBindingIndex,
      startOffset: region.startOffset,
      endOffset: offset,
      valueAtStart: region.thisBindingAtStart,
    );
    assert(() {
      _minValidOffset = region.savedMinValidOffset;
      return true;
    }());
  }

  /// Returns the fully created [FlowAnalysisLog].
  FlowAnalysisLog finish() {
    assert(_regionStack.isEmpty, 'Unterminated out of order region');
    return this;
  }

  /// Records that at [offset], the promotion info changed to [promotionInfo].
  void promotionInfoChanged(
    PromotionInfo? promotionInfo, {
    required int offset,
  }) {
    checkOffset(offset);
    _record<PromotionInfo>(
      offsets: _promotionInfoOffsets,
      values: _promotionInfoValues,
      offset: offset,
      value: promotionInfo,
    );
  }

  /// Records that at [offset], the binding for `this` changed to [binding].
  ///
  /// [binding] should either be a record consisting of the promotion key for
  /// `this` and the corresponding unpromoted type, or `null` in the case where
  /// there is no binding for `this` in effect.
  void thisBindingChanged(
    ({PromotionKey promotionKey, SharedTypeView unpromotedType})? binding, {
    required int offset,
  }) {
    checkOffset(offset);
    _record<({PromotionKey promotionKey, SharedTypeView unpromotedType})>(
      offsets: _thisBindingOffsets,
      values: _thisBindingValues,
      offset: offset,
      value: binding,
    );
  }

  /// Appends the entry ([offset], [value]) to the parallel lists [offsets] and
  /// [values], unless it would be redundant.
  ///
  /// An entry is redundant if it doesn't change the value that's in effect;
  /// dropping such entries keeps the log small (and is what makes it cheap for
  /// callers to record the current state unconditionally).
  static void _record<T extends Object>({
    required List<int> offsets,
    required List<T?> values,
    required int offset,
    required T? value,
  }) {
    if (values.isEmpty ? value == null : values.last == value) return;
    offsets.add(offset);
    values.add(value);
  }

  /// Moves the entries of a completed out of order region into their proper
  /// place in the parallel lists [offsets] and [values].
  ///
  /// The region's entries are the entries from [regionIndex] to the end of the
  /// lists. [enclosingRegionIndex] is the index of the first entry belonging to
  /// the enclosing region (or `0` if there is no enclosing region); the region
  /// is spliced in among the entries in
  /// `[enclosingRegionIndex, regionIndex)`, which are guaranteed to be in
  /// source order.
  ///
  /// [valueAtStart] is the value that was in effect when the region was begun
  /// (which is not necessarily the value in effect at the splice point, since
  /// the region is being visited out of order). Similarly,
  /// [enclosingValueAtStart] is the value that was in effect when the enclosing
  /// region was begun (or `null` if there is no enclosing region); it is needed
  /// in the case where the region is spliced in ahead of all of the enclosing
  /// region's entries.
  static void _spliceRegion<T extends Object>({
    required List<int> offsets,
    required List<T?> values,
    required int enclosingRegionIndex,
    required T? enclosingValueAtStart,
    required int regionIndex,
    required int startOffset,
    required int endOffset,
    required T? valueAtStart,
  }) {
    assert(offsets.length == values.length);
    assert(() {
      for (int i = regionIndex; i < offsets.length; i++) {
        assert(
          offsets[i] >= startOffset && offsets[i] <= endOffset,
          'Offset ${offsets[i]} is outside the out of order region '
          '[$startOffset, $endOffset]',
        );
      }
      return true;
    }());
    // Find the splice point among the enclosing region's entries. Entries
    // whose offset is exactly [startOffset] belong to the construct that
    // precedes the region in source order, so the region goes after them;
    // hence `after: true`.
    int spliceIndex = FlowAnalysisLog._findInsertionIndex(
      offsets,
      offset: startOffset,
      minIndex: enclosingRegionIndex,
      maxIndex: regionIndex,
      after: true,
    );
    assert(
      spliceIndex == regionIndex || offsets[spliceIndex] >= endOffset,
      'Out of order region [$startOffset, $endOffset] overlaps an entry at '
      'offset ${offsets[spliceIndex]}',
    );

    // Compute the value that's in effect (in source order) just before the
    // splice point; this is the value that needs to be restored after the
    // region.
    T? valueBeforeRegion = spliceIndex == enclosingRegionIndex
        ? enclosingValueAtStart
        : values[spliceIndex - 1];

    // If the region recorded no entries, and it began with the state that's in
    // effect at the splice point anyway, then it has nothing to contribute to
    // the log. This is a common case: most out of order constructs leave the
    // binding of `this` alone, so the `this` binding list usually takes this
    // path.
    if (regionIndex == offsets.length && valueAtStart == valueBeforeRegion) {
      return;
    }

    // Detach the region's entries.
    List<int> regionOffsets = offsets.sublist(regionIndex);
    List<T?> regionValues = values.sublist(regionIndex);
    offsets.length = regionIndex;
    values.length = regionIndex;

    // Build the list of entries to splice in: an entry establishing the state
    // at the beginning of the region, the region's own entries, and an entry
    // restoring the state that follows the region in source order. Redundant
    // entries are dropped.
    List<int> newOffsets = [];
    List<T?> newValues = [];
    T? valueInEffect = valueBeforeRegion;
    void add(int offset, T? value) {
      if (value == valueInEffect) return;
      newOffsets.add(offset);
      newValues.add(value);
      valueInEffect = value;
    }

    add(startOffset, valueAtStart);
    for (int i = 0; i < regionOffsets.length; i++) {
      add(regionOffsets[i], regionValues[i]);
    }
    add(endOffset, valueBeforeRegion);

    offsets.insertAll(spliceIndex, newOffsets);
    values.insertAll(spliceIndex, newValues);
  }
}

/// Information about an out of order region that is in the process of being
/// recorded in a [FlowAnalysisLogBuilder].
///
/// See [FlowAnalysisLogBuilder.beginOutOfOrderRegion].
class _OutOfOrderRegion {
  /// The source offset at which the region begins.
  final int startOffset;

  /// The index, in [FlowAnalysisLog._promotionInfoOffsets] and
  /// [FlowAnalysisLog._promotionInfoValues], of the first entry belonging to
  /// the region.
  final int promotionInfoIndex;

  /// The index, in [FlowAnalysisLog._thisBindingOffsets] and
  /// [FlowAnalysisLog._thisBindingValues], of the first entry belonging to the
  /// region.
  final int thisBindingIndex;

  /// The promotion info that was in effect when the region was begun.
  final PromotionInfo? promotionInfoAtStart;

  /// The binding for `this` that was in effect when the region was begun.
  final ({PromotionKey promotionKey, SharedTypeView unpromotedType})?
  thisBindingAtStart;

  /// The value of [FlowAnalysisLogBuilder._minValidOffset] that should be
  /// restored when the region ends.
  final int savedMinValidOffset;

  _OutOfOrderRegion({
    required this.startOffset,
    required this.promotionInfoIndex,
    required this.thisBindingIndex,
    required this.promotionInfoAtStart,
    required this.thisBindingAtStart,
    required this.savedMinValidOffset,
  });
}
