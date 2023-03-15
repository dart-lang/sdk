// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A value that defines the key of an additional field.
///
/// This is used for accessing entries in maps and elements in lists.
abstract class Key implements Comparable<Key> {
  String get name;

  @override
  int compareTo(Key other) {
    return name.compareTo(name);
  }
}

/// An entry in a map whose key is a constant [value].
class MapKey extends Key {
  final Object value;
  final String valueAsText;

  MapKey(this.value, this.valueAsText);

  @override
  String get name => '[$valueAsText]';

  @override
  int get hashCode => value.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MapKey && value == other.value;
  }

  @override
  String toString() => valueAsText;
}

/// An element in a list accessed by an [index] from the start of the list.
class HeadKey extends Key {
  final int index;

  HeadKey(this.index);

  @override
  String get name => '[$index]';

  @override
  int get hashCode => index.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HeadKey && index == other.index;
  }

  @override
  String toString() => 'HeadKey($index)';
}

/// An element in a list accessed by an [index] from the end of the list, that
/// is, the [index]th last element.
class TailKey extends Key {
  final int index;

  TailKey(this.index);

  @override
  String get name => '[${-(index + 1)}]';

  @override
  int get hashCode => index.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TailKey && index == other.index;
  }

  @override
  String toString() => 'TailKey($index)';
}

/// A sublist of a list from the [headSize]th index to the [tailSize]th last
/// index.
class RestKey extends Key {
  final int headSize;
  final int tailSize;

  RestKey(this.headSize, this.tailSize);

  @override
  String get name => '[$headSize:${-tailSize}]';

  @override
  int get hashCode => Object.hash(headSize, tailSize);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RestKey &&
        headSize == other.headSize &&
        tailSize == other.tailSize;
  }

  @override
  String toString() => 'RestKey($headSize,$tailSize)';
}
