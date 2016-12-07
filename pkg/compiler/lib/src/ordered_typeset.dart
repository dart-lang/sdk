// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library ordered_typeset;

import 'common.dart';
import 'dart_types.dart';
import 'diagnostics/diagnostic_listener.dart' show DiagnosticReporter;
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

  OrderedTypeSet.internal(List<Link<DartType>> this._levels,
      Link<DartType> this.types, Link<DartType> this._supertypes);

  factory OrderedTypeSet.singleton(DartType type) {
    Link<DartType> types =
        new LinkEntry<DartType>(type, const Link<DartType>());
    List<Link<DartType>> list = new List<Link<DartType>>(1);
    list[0] = types;
    return new OrderedTypeSet.internal(list, types, const Link<DartType>());
  }

  /// Creates a new [OrderedTypeSet] for [type] when it directly extends the
  /// class which this set represents. This is for instance used to create the
  /// type set for [ClosureClassElement] which extends [Closure].
  OrderedTypeSet extendClass(InterfaceType type) {
    assert(invariant(type.element, types.head.treatAsRaw,
        message: 'Cannot extend generic class ${types.head} using '
            'OrderedTypeSet.extendClass'));
    Link<DartType> extendedTypes = new LinkEntry<DartType>(type, types);
    List<Link<DartType>> list = new List<Link<DartType>>(levels + 1);
    for (int i = 0; i < levels; i++) {
      list[i] = _levels[i];
    }
    list[levels] = extendedTypes;
    return new OrderedTypeSet.internal(
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

  /// Returns the offsets into [types] at which each level begins.
  List<int> get levelOffsets {
    List<int> offsets = new List.filled(levels, -1);
    int offset = 0;
    Link<DartType> pointer = types;
    for (int depth = maxDepth; depth >= 0; depth--) {
      while (!identical(pointer, _levels[depth])) {
        pointer = pointer.tail;
        offset++;
      }
      offsets[depth] = offset;
    }
    return offsets;
  }

  void forEach(int level, void f(DartType type)) {
    if (level < levels) {
      Link<DartType> pointer = _levels[level];
      Link<DartType> end =
          level > 0 ? _levels[level - 1] : const Link<DartType>();
      // TODO(het): checking `isNotEmpty` should be unnecessary, remove when
      // constants are properly canonicalized
      while (pointer.isNotEmpty && !identical(pointer, end)) {
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
      // TODO(het): checking `isNotEmpty` should be unnecessary, remove when
      // constants are properly canonicalized
      while (pointer.isNotEmpty && !identical(pointer, end)) {
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

  final DiagnosticReporter reporter;
  final ClassElement cls;
  InterfaceType _objectType;

  // TODO(johnniwinther): Provide access to `Object` in deserialization and
  // make [objectType] mandatory.
  OrderedTypeSetBuilder(this.cls, {this.reporter, InterfaceType objectType})
      : this._objectType = objectType;

  OrderedTypeSet createOrderedTypeSet(
      InterfaceType supertype, Link<DartType> interfaces) {
    if (_objectType == null) {
      // Find `Object` through in hierarchy. This is used for serialization
      // where it is assumed that the hierarchy is valid.
      _objectType = supertype;
      while (!_objectType.isObject) {
        _objectType = _objectType.element.supertype;
      }
    }

    // TODO(15296): Collapse these iterations to one when the order is not
    // needed.
    add(supertype);
    for (Link<DartType> link = interfaces; !link.isEmpty; link = link.tail) {
      add(link.head);
    }

    addAllSupertypes(supertype);
    for (Link<DartType> link = interfaces; !link.isEmpty; link = link.tail) {
      addAllSupertypes(link.head);
    }
    add(cls.thisType);
    return toTypeSet();
  }

  /**
   * Adds [type] and all supertypes of [type] to [allSupertypes] while
   * substituting type variables.
   */
  void addAllSupertypes(InterfaceType type) {
    ClassElement classElement = type.element;
    Link<DartType> supertypes = classElement.allSupertypes;
    assert(invariant(cls, supertypes != null,
        message: "Supertypes not computed on $classElement "
            "during resolution of $cls"));
    while (!supertypes.isEmpty) {
      DartType supertype = supertypes.head;
      add(supertype.substByContext(type));
      supertypes = supertypes.tail;
    }
  }

  void add(InterfaceType type) {
    if (type.element == cls) {
      if (type != _objectType) {
        allSupertypes.addLast(_objectType);
      }
      _addAtDepth(type, maxDepth + 1);
    } else {
      if (type != _objectType) {
        allSupertypes.addLast(type);
      }
      _addAtDepth(type, type.element.hierarchyDepth);
    }
  }

  void _addAtDepth(InterfaceType type, int depth) {
    LinkEntry<DartType> prev = null;
    LinkEntry<DartType> link = map[depth];
    while (link != null) {
      DartType existingType = link.head;
      if (existingType == type) return;
      if (existingType.element == type.element) {
        if (reporter != null) {
          reporter.reportErrorMessage(cls, MessageKind.MULTI_INHERITANCE, {
            'thisType': cls.thisType,
            'firstType': existingType,
            'secondType': type
          });
        } else {
          assert(invariant(cls, false,
              message: 'Invalid ordered typeset for $cls'));
        }
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
      return new OrderedTypeSet.internal(
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
    return new OrderedTypeSet.internal(
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
