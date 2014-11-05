// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library ordered_typeset;

import 'dart2jslib.dart' show Compiler, MessageKind, invariant;
import 'dart_types.dart';
import 'elements/elements.dart' show ClassElement;
import 'util/util.dart' show Link, LinkBuilder;
import 'util/util_implementation.dart' show LinkEntry;

/**
 * An ordered set of the supertypes of a class. The supertypes of a class are
 * ordered by decreasing hierarchy depth and by the order they are extended,
 * mixed in, or implemented.
 *
 * For these classes
 *
 *     class A {} // Depth = 1.
 *     class B {} // Depth = 1.
 *     class C extends B implements A {} // Depth 2.
 *
 * the ordered supertypes are
 *
 *     A: [A, Object]
 *     B: [B, Object]
 *     C: [C, B, A, Object]
 */
class OrderedTypeSet {
  final List<Link<DartType>> _levels;
  final Link<DartType> types;
  final Link<DartType> _supertypes;

  OrderedTypeSet._internal(List<Link<DartType>> this._levels,
                           Link<DartType> this.types,
                           Link<DartType> this._supertypes);

  factory OrderedTypeSet.singleton(DartType type) {
    Link<DartType> types =
        new LinkEntry<DartType>(type, const Link<DartType>());
    List<Link<DartType>> list = new List<Link<DartType>>(1);
    list[0] = types;
    return new OrderedTypeSet._internal(list, types, const Link<DartType>());
  }

  /// Creates a new [OrderedTypeSet] for [type] when it directly extends the
  /// class which this set represents. This is for instance used to create the
  /// type set for [ClosureClassElement] which extends [Closure].
  OrderedTypeSet extendClass(InterfaceType type) {
    assert(invariant(type.element, types.head.treatAsRaw,
        message: 'Cannot extend generic class ${types.head} using '
                 'OrderedTypeSet.extendClass'));
    Link<DartType> extendedTypes =
        new LinkEntry<DartType>(type, types);
    List<Link<DartType>> list = new List<Link<DartType>>(levels + 1);
    for (int i = 0; i < levels; i++) {
      list[i] = _levels[i];
    }
    list[levels] = extendedTypes;
    return new OrderedTypeSet._internal(
        list, extendedTypes, _supertypes.prepend(types.head));
  }

  Link<DartType> get supertypes => _supertypes;

  int get levels => _levels.length;

  int get maxDepth => levels - 1;

  Link<DartType> operator [](int index) {
    if (index < levels) {
      return _levels[index];
    }
    return const Link<DartType>();
  }

  void forEach(int level, void f(DartType type)) {
    if (level < levels) {
      Link<DartType> pointer = _levels[level];
      Link<DartType> end =
          level > 0 ? _levels[level - 1] : const Link<DartType>();
      while (!identical(pointer, end)) {
        f(pointer.head);
        pointer = pointer.tail;
      }
    }
  }

  InterfaceType asInstanceOf(ClassElement cls) {
    int level = cls.hierarchyDepth;
    if (level < levels) {
      Link<DartType> pointer = _levels[level];
      Link<DartType> end =
          level > 0 ? _levels[level - 1] : const Link<DartType>();
      while (!identical(pointer, end)) {
        if (cls == pointer.head.element) {
          return pointer.head;
        }
        pointer = pointer.tail;
      }
    }
    return null;
  }

  String toString() => types.toString();
}

/**
 * Builder for creation an ordered set of the supertypes of a class. The
 * supertypes are ordered by decreasing hierarchy depth and by the order they
 * are extended, mixed in, or implemented.
 *
 * For these classes
 *
 *     class A {} // Depth = 1.
 *     class B {} // Depth = 1.
 *     class C extends B implements A {} // Depth 2.
 *
 * the ordered supertypes are
 *
 *     A: [A, Object]
 *     B: [B, Object]
 *     C: [C, B, A, Object]
 */
class OrderedTypeSetBuilder {
  Map<int, LinkEntry<DartType>> map = new Map<int, LinkEntry<DartType>>();
  // TODO(15296): Avoid computing this order on the side when member
  // lookup handles multiply inherited members correctly.
  LinkBuilder<DartType> allSupertypes = new LinkBuilder<DartType>();
  int maxDepth = -1;

  final ClassElement cls;

  OrderedTypeSetBuilder(this.cls);

  void add(Compiler compiler, InterfaceType type) {
    if (type.element == cls) {
      if (type.element != compiler.objectClass) {
        allSupertypes.addLast(compiler.objectClass.rawType);
      }
      _addAtDepth(compiler, type, maxDepth + 1);
    } else {
      if (type.element != compiler.objectClass) {
        allSupertypes.addLast(type);
      }
      _addAtDepth(compiler, type, type.element.hierarchyDepth);
    }
  }

  void _addAtDepth(Compiler compiler, InterfaceType type, int depth) {
    LinkEntry<DartType> prev = null;
    LinkEntry<DartType> link = map[depth];
    while (link != null) {
      DartType existingType = link.head;
      if (existingType == type) return;
      if (existingType.element == type.element) {
        compiler.reportError(cls,
            MessageKind.MULTI_INHERITANCE,
            {'thisType': cls.thisType,
             'firstType': existingType,
             'secondType': type});
        return;
      }
      prev = link;
      link = link.tail;
    }
    LinkEntry<DartType> next = new LinkEntry<DartType>(type);
    next.tail = null;
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
    List<Link<DartType>> levels = new List<Link<DartType>>(maxDepth + 1);
    if (maxDepth < 0) {
      return new OrderedTypeSet._internal(
          levels, const Link<DartType>(), const Link<DartType>());
    }
    Link<DartType> next = const Link<DartType>();
    for (int depth = 0; depth <= maxDepth; depth++) {
      LinkEntry<DartType> first = map[depth];
      if (first == null) {
        levels[depth] = next;
      } else {
        levels[depth] = first;
        LinkEntry<DartType> last = first;
        while (last.tail != null) {
          last = last.tail;
        }
        last.tail = next;
        next = first;
      }
    }
    return new OrderedTypeSet._internal(
        levels, levels.last, allSupertypes.toLink());
  }

  String toString() {
    StringBuffer sb = new StringBuffer();
    for (int depth = 0; depth <= maxDepth; depth++) {
      sb.write('$depth: ');
      LinkEntry<DartType> first = map[depth];
      if (first != null) {
        sb.write('${first.head}');
        while (first.tail != null) {
          sb.write(', ${first.tail.head}');
          first = first.tail;
        }
      }
      sb.write('\n');
    }
    return sb.toString();
  }
}
