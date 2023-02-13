// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of touch;

/// Represents a point in 2 dimensional space.
class Coordinate {
  /// X-value
  num x;

  /// Y-value
  num y;

  Coordinate([this.x = 0, this.y = 0]);

  /// Gets the coordinates of a touch's location relative to the window's
  /// viewport. [input] is either a touch object or an event object.
  Coordinate.fromClient(var input) : this(input.client.x, input.client.y);

  static Coordinate difference(Coordinate a, Coordinate b) {
    return Coordinate(a.x - b.x, a.y - b.y);
  }

  static num distance(Coordinate a, Coordinate b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return Math.sqrt(dx * dx + dy * dy);
  }

  @override
  bool operator ==(covariant Coordinate other) {
    return x == other.x && y == other.y;
  }

  @override
  int get hashCode => throw UnimplementedError();

  static num squaredDistance(Coordinate a, Coordinate b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return dx * dx + dy * dy;
  }

  static Coordinate sum(Coordinate a, Coordinate b) {
    return Coordinate(a.x + b.x, a.y + b.y);
  }

  /// Returns a new copy of the coordinate.
  Coordinate clone() => Coordinate(x, y);

  @override
  String toString() => "($x, $y)";
}

/// Represents the interval { x | start <= x < end }.
class Interval<T extends num> {
  final T start;
  final T end;

  Interval(this.start, this.end);

  num get length {
    return end - start;
  }

  @override
  bool operator ==(covariant Interval other) {
    return other.start == start && other.end == end;
  }

  @override
  int get hashCode => throw UnimplementedError();

  Interval<T> union(Interval<T> other) {
    return Interval<T>(Math.min(start, other.start), Math.max(end, other.end));
  }

  bool contains(num value) {
    return value >= start && value < end;
  }

  @override
  String toString() {
    return '($start, $end)';
  }
}
