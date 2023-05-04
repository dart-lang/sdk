// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'static_type.dart';

/// A value that defines the key of an additional field.
///
/// This is used for accessing entries in maps and elements in lists.
abstract class Key implements Comparable<Key> {
  String get name;
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

  @override
  int compareTo(Key other) {
    if (other is MapKey) {
      return valueAsText.compareTo(other.valueAsText);
    } else if (other is HeadKey || other is RestKey || other is TailKey) {
      // Map keys after list keys.
      return 1;
    } else {
      // Map keys before record index, name and extension keys,
      return -1;
    }
  }
}

/// Tagging interface for the list specific keys [HeadKey], [RestKey], and
/// [TailKey].
abstract class ListKey implements Key {}

/// An element in a list accessed by an [index] from the start of the list.
class HeadKey extends Key implements ListKey {
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

  @override
  int compareTo(Key other) {
    if (other is HeadKey) {
      return index.compareTo(other.index);
    } else {
      // Head keys before other keys,
      return -1;
    }
  }
}

/// An element in a list accessed by an [index] from the end of the list, that
/// is, the [index]th last element.
class TailKey extends Key implements ListKey {
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

  @override
  int compareTo(Key other) {
    if (other is TailKey) {
      return -index.compareTo(other.index);
    } else if (other is HeadKey || other is RestKey) {
      // Tail keys after head and rest keys.
      return 1;
    } else {
      // Tail keys before map, record index, name and extension keys,
      return -1;
    }
  }
}

/// A sublist of a list from the [headSize]th index to the [tailSize]th last
/// index.
class RestKey extends Key implements ListKey {
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

  @override
  int compareTo(Key other) {
    if (other is RestKey) {
      int result = headSize.compareTo(other.headSize);
      if (result == 0) {
        result = -tailSize.compareTo(other.tailSize);
      }
      return result;
    } else if (other is HeadKey) {
      // Rest keys after head keys.
      return 1;
    } else {
      // Rest keys before tail, map, record index, name and extension keys,
      return -1;
    }
  }
}

/// Key for a regular object member.
class NameKey extends Key {
  @override
  final String name;

  NameKey(this.name);

  @override
  int get hashCode => name.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NameKey && name == other.name;
  }

  @override
  String toString() => 'NameKey($name)';

  @override
  int compareTo(Key other) {
    if (other is RecordIndexKey) {
      // Name keys after record index keys.
      return 1;
    } else if (other is NameKey) {
      return name.compareTo(other.name);
    } else if (other is ExtensionKey) {
      // Name keys before extension keys.
      return -1;
    } else {
      // Name keys after other keys.
      return 1;
    }
  }
}

/// Tagging interface for the record specific keys [RecordIndexKey] and
/// [RecordNameKey].
abstract class RecordKey implements Key {}

/// Specialized [NameKey] for an indexed record field.
class RecordIndexKey extends NameKey implements RecordKey {
  final int index;

  RecordIndexKey(this.index) : super('\$${index + 1}');

  @override
  int compareTo(Key other) {
    if (other is RecordIndexKey) {
      return index.compareTo(other.index);
    } else if (other is NameKey) {
      // Record index keys before name keys.
      return -1;
    } else if (other is ExtensionKey) {
      // Record index keys before extension keys.
      return -1;
    } else {
      // Record index keys after other keys.
      return 1;
    }
  }
}

/// Specialized [NameKey] for a named record field.
class RecordNameKey extends NameKey implements RecordKey {
  RecordNameKey(super.name);
}

class ExtensionKey implements Key {
  final StaticType receiverType;
  @override
  final String name;
  final StaticType type;

  ExtensionKey(this.receiverType, this.name, this.type);

  @override
  int compareTo(Key other) {
    if (other is ExtensionKey) {
      // Sorting is only used for a stable choice of witness, so it's ok that in
      // edge cases `receiverType.name` is not unique.
      int result = receiverType.name.compareTo(other.receiverType.name);
      if (result == 0) {
        result = name.compareTo(other.name);
      }
      return result;
    } else {
      // Extension keys after other keys.
      return 1;
    }
  }

  @override
  int get hashCode => Object.hash(receiverType, name);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExtensionKey &&
        receiverType == other.receiverType &&
        name == other.name;
  }

  @override
  String toString() => 'ExtensionKey($receiverType.$name:$type)';
}
