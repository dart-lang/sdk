// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library ordered_typeset;

import 'package:front_end/src/api_unstable/dart2js.dart'
    show Link, LinkBuilder, LinkEntry;

import 'common.dart';
import 'elements/entities.dart';
import 'elements/types.dart';
import 'serialization/serialization_interfaces.dart';

/// An ordered set of the supertypes of a class. The supertypes of a class are
/// ordered by decreasing hierarchy depth and by the order they are extended,
/// mixed in, or implemented.
///
/// For these classes
///
///     class A {} // Depth = 1.
///     class B {} // Depth = 1.
///     class C extends B implements A {} // Depth 2.
///
/// the ordered supertypes are
///
///     A: [A, Object]
///     B: [B, Object]
///     C: [C, B, A, Object]
class OrderedTypeSet {
  /// Tag used for identifying serialized [OrderedTypeSet] objects in a
  /// debugging data stream.
  static const String tag = 'ordered-type-set';

  final List<Link<InterfaceType>> _levels;
  final LinkEntry<InterfaceType> types;

  OrderedTypeSet._(this._levels, this.types);

  /// Deserializes a [OrderedTypeSet] object from [source].
  factory OrderedTypeSet.readFromDataSource(DataSourceReader source) {
    // TODO(johnniwinther): Make the deserialized type sets share their
    // internal links like the original type sets do?
    source.begin(tag);
    int typesCount = source.readInt();
    LinkBuilder<InterfaceType> typeLinkBuilder = LinkBuilder<InterfaceType>();
    List<Link<InterfaceType>> links = [];
    for (int i = 0; i < typesCount; i++) {
      links
          .add(typeLinkBuilder.addLast(source.readDartType() as InterfaceType));
    }
    final types = typeLinkBuilder.toLink(const Link<InterfaceType>())
        as LinkEntry<InterfaceType>;
    links.add(const Link<InterfaceType>());

    int levelCount = source.readInt();
    List<Link<InterfaceType>> levels = List<Link<InterfaceType>>.generate(
        levelCount, (index) => links[source.readInt()],
        growable: false);
    source.end(tag);
    return OrderedTypeSet._(levels, types);
  }

  /// Serializes this [OrderedTypeSet] to [sink].
  void writeToDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    List<InterfaceType> typeList = types.toList();
    sink.writeInt(typeList.length);
    for (InterfaceType type in typeList) {
      sink.writeDartType(type);
    }
    List<int> levelList = [];
    Link<InterfaceType>? link = types;
    while (link != null) {
      int index = _levels.indexOf(link);
      if (index != -1) {
        levelList.add(index);
      }
      link = link.tail;
    }
    sink.writeInt(levelList.length);
    for (int level in levelList) {
      sink.writeInt(level);
    }
    sink.end(tag);
  }

  factory OrderedTypeSet.singleton(InterfaceType type) {
    final types = LinkEntry<InterfaceType>(type, const Link<InterfaceType>());
    List<Link<InterfaceType>> list = List<Link<InterfaceType>>.filled(1, types);
    return OrderedTypeSet._(list, types);
  }

  /// Creates a new [OrderedTypeSet] for [type] when it directly extends the
  /// class which this set represents. This is for instance used to create the
  /// type set for [ClosureClassElement] which extends [Closure].
  OrderedTypeSet extendClass(DartTypes dartTypes, InterfaceType type) {
    assert(
        dartTypes.treatAsRawType(types.head),
        failedAt(
            type.element,
            'Cannot extend generic class ${types.head} using '
            'OrderedTypeSet.extendClass'));
    final extendedTypes = LinkEntry<InterfaceType>(type, types);
    List<Link<InterfaceType>> list =
        _levels.followedBy([extendedTypes]).toList(growable: false);
    return OrderedTypeSet._(list, extendedTypes);
  }

  Link<InterfaceType>? get supertypes => types.tail;

  int get levels => _levels.length;

  int get maxDepth => levels - 1;

  Link<InterfaceType> operator [](int index) {
    if (index < levels) {
      return _levels[index];
    }
    return const Link<InterfaceType>();
  }

  /// Returns the offsets into [types] at which each level begins.
  List<int> get levelOffsets {
    List<int> offsets = List.filled(levels, -1);
    int offset = 0;
    Link<InterfaceType> pointer = types;
    for (int depth = maxDepth; depth >= 0; depth--) {
      while (!identical(pointer, _levels[depth])) {
        pointer = pointer.tail!;
        offset++;
      }
      offsets[depth] = offset;
    }
    return offsets;
  }

  void forEach(int level, void f(InterfaceType type)) {
    if (level < levels) {
      Link<InterfaceType> pointer = _levels[level];
      Link<InterfaceType> end =
          level > 0 ? _levels[level - 1] : const Link<InterfaceType>();
      // TODO(het): checking `isNotEmpty` should be unnecessary, remove when
      // constants are properly canonicalized
      while (pointer.isNotEmpty && !identical(pointer, end)) {
        f(pointer.head);
        pointer = pointer.tail!;
      }
    }
  }

  InterfaceType? asInstanceOf(ClassEntity cls, int hierarchyDepth) {
    int level = hierarchyDepth;
    if (level < levels) {
      Link<InterfaceType> pointer = _levels[level];
      Link<InterfaceType> end =
          level > 0 ? _levels[level - 1] : const Link<InterfaceType>();
      // TODO(het): checking `isNotEmpty` should be unnecessary, remove when
      // constants are properly canonicalized
      while (pointer.isNotEmpty && !identical(pointer, end)) {
        if (cls == pointer.head.element) {
          return pointer.head;
        }
        pointer = pointer.tail!;
      }
    }
    return null;
  }

  @override
  String toString() => types.toString();
}

/// Builder for creation an ordered set of the supertypes of a class. The
/// supertypes are ordered by decreasing hierarchy depth and by the order they
/// are extended, mixed in, or implemented.
///
/// For these classes
///
///     class A {} // Depth = 1.
///     class B {} // Depth = 1.
///     class C extends B implements A {} // Depth 2.
///
/// the ordered supertypes are
///
///     A: [A, Object]
///     B: [B, Object]
///     C: [C, B, A, Object]
abstract class OrderedTypeSetBuilder {
  OrderedTypeSet createOrderedTypeSet(Set<InterfaceType> canonicalSupertypes);
}

abstract class OrderedTypeSetBuilderBase implements OrderedTypeSetBuilder {
  Map<int, LinkEntry<InterfaceType>> map = Map<int, LinkEntry<InterfaceType>>();
  int maxDepth = -1;

  final ClassEntity cls;

  OrderedTypeSetBuilderBase(this.cls);

  InterfaceType getThisType(covariant ClassEntity cls);
  InterfaceType substByContext(
      covariant InterfaceType type, covariant InterfaceType context);
  int getHierarchyDepth(covariant ClassEntity cls);
  OrderedTypeSet getOrderedTypeSet(covariant ClassEntity cls);

  @override
  OrderedTypeSet createOrderedTypeSet(Set<InterfaceType> canonicalSupertypes) {
    for (InterfaceType supertype in canonicalSupertypes) {
      add(supertype);
    }
    add(getThisType(cls));
    return toTypeSet();
  }

  void add(InterfaceType type) {
    if (type.element == cls) {
      _addAtDepth(type, maxDepth + 1);
    } else {
      _addAtDepth(type, getHierarchyDepth(type.element));
    }
  }

  void _addAtDepth(InterfaceType type, int depth) {
    LinkEntry<InterfaceType>? prev;
    Link<InterfaceType>? link = map[depth];
    while (link != null && link is LinkEntry) {
      InterfaceType existingType = link.head;
      if (existingType == type) return;
      if (existingType.element == type.element) {
        assert(false, failedAt(cls, 'Invalid ordered typeset for $cls'));
        return;
      }
      prev = link as LinkEntry<InterfaceType>;
      link = link.tail;
    }
    LinkEntry<InterfaceType> next = LinkEntry<InterfaceType>(type);
    if (prev == null) {
      map[depth] = next;
    } else {
      prev.tail = next;
    }
    if (depth > maxDepth) {
      maxDepth = depth;
    }
  }

  OrderedTypeSet toTypeSet() {
    assert(maxDepth >= 0);
    Link<InterfaceType> next = const Link<InterfaceType>();

    List<Link<InterfaceType>> levels =
        List<Link<InterfaceType>>.generate(maxDepth + 1, (depth) {
      LinkEntry<InterfaceType>? first = map[depth];
      if (first == null) {
        return next;
      } else {
        final value = first;
        LinkEntry<InterfaceType> last = first;
        while (last.tail != const Link<Never>()) {
          last = last.tail as LinkEntry<InterfaceType>;
        }
        last.tail = next;
        next = first;
        return value;
      }
    });
    return OrderedTypeSet._(levels, levels.last as LinkEntry<InterfaceType>);
  }

  @override
  String toString() {
    StringBuffer sb = StringBuffer();
    for (int depth = 0; depth <= maxDepth; depth++) {
      sb.write('$depth: ');
      LinkEntry<InterfaceType> first = map[depth]!;
      first.printOn(sb, ", ");
      sb.write('\n');
    }
    return sb.toString();
  }
}
