// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of layout;

// This file has classes representing the grid sizing functions

/**
 * Represents the sizing function used for the min or max of a row or column.
 */
// TODO(jmesserly): rename to GridSizing, or make internal
class SizingFunction {
  const SizingFunction();

  bool get isContentSized => isMinContentSized || isMaxContentSized;
  bool get isMinContentSized => false;
  bool get isMaxContentSized => false;
  bool get isFraction => false;

  num resolveLength(num gridSize) => 0;

  num get fractionValue => 0;

  // TODO(jmesserly): this is only needed because FixedSizing is mutable
  SizingFunction clone() => this;
}

/**
 * Fixed size reprensents a length as defined by CSS3 Values spec.
 * Can also be a percentage of the Grid element's logical width (for columns)
 * or logical height (for rows). When the width or height of the Grid element
 * is undefined, the percentage is ignored and the Grid Track will be
 * auto-sized.
 */
class FixedSizing extends SizingFunction {
  final String units;
  final num length;

  // TODO(jmesserly): kind of ugly to have this mutable property here, but
  // we need to correctly track whether we're content sized during a layout
  bool _contentSized;

  FixedSizing(this.length, [this.units = 'px'])
      : super(),
        _contentSized = false {
    if (units != 'px' && units != '%') {
      // TODO(jmesserly): support other unit types
      throw new UnsupportedError('Units other than px and %');
    }
  }

  // TODO(jmesserly): this is only needed because of our mutable property
  FixedSizing clone() => new FixedSizing(length, units);

  bool get isMinContentSized => _contentSized;

  num resolveLength(num gridSize) {
    if (units == '%') {
      if (gridSize == null) {
        // Use content size when the grid doesn't have an absolute size in this
        // dimension
        _contentSized = true;
        return 0;
      }
      _contentSized = false;
      return (length / 100) * gridSize;
    } else {
      return length;
    }
  }

  String toString() => 'FixedSizing: ${length}${units} $_contentSized';
}

/**
 * Fraction is a non-negative floating-point number followed by 'fr'. Each
 * fraction value takes a share of the remaining space proportional to its
 * number.
 */
class FractionSizing extends SizingFunction {
  final num fractionValue;
  FractionSizing(this.fractionValue) : super() {}

  bool get isFraction => true;

  String toString() => 'FixedSizing: ${fractionValue}fr';
}

class MinContentSizing extends SizingFunction {
  const MinContentSizing() : super();

  bool get isMinContentSized => true;

  String toString() => 'MinContentSizing';
}

class MaxContentSizing extends SizingFunction {
  const MaxContentSizing() : super();

  bool get isMaxContentSized {
    return true;
  }

  String toString() => 'MaxContentSizing';
}

/** The min and max sizing functions for a track. */
class TrackSizing {
  /** The min sizing function for the track. */
  final SizingFunction min;

  /** The min sizing function for the track. */
  final SizingFunction max;

  const TrackSizing.auto()
      : min = const MinContentSizing(),
        max = const MaxContentSizing();

  TrackSizing(this.min, this.max) {}

  // TODO(jmesserly): this is only needed because FixedSizing is mutable
  TrackSizing clone() => new TrackSizing(min.clone(), max.clone());
}

/** Represents a GridTrack breadth property. */
// TODO(jmesserly): these classes could be replaced with reflection/mirrors
abstract class _BreadthAccumulator {
  void setSize(GridTrack t, num value);
  num getSize(GridTrack t);

  SizingFunction getSizingFunction(GridTrack t);
}

class _UsedBreadthAccumulator implements _BreadthAccumulator {
  const _UsedBreadthAccumulator();

  void setSize(GridTrack t, num value) {
    t.usedBreadth = value;
  }

  num getSize(GridTrack t) => t.usedBreadth;

  SizingFunction getSizingFunction(GridTrack t) => t.minSizing;
}

class _MaxBreadthAccumulator implements _BreadthAccumulator {
  const _MaxBreadthAccumulator();

  void setSize(GridTrack t, num value) {
    t.maxBreadth = value;
  }

  num getSize(GridTrack t) => t.maxBreadth;

  SizingFunction getSizingFunction(GridTrack t) => t.maxSizing;
}
