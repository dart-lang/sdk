// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library ordered_typeset;

import 'common.dart';
import 'diagnostics/diagnostic_listener.dart' show DiagnosticReporter;
import 'elements/elements.dart' show ClassElement;
import 'elements/entities.dart';
import 'elements/resolution_types.dart';
import 'elements/types.dart';
import 'util/util.dart' show Link, LinkBuilder;
import 'package:front_end/src/fasta/util/link_implementation.dart'
    show LinkEntry;

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
  final List<Link<InterfaceType>> _levels;
  final Link<InterfaceType> types;
  final Link<InterfaceType> _supertypes;

  OrderedTypeSet.internal(List<Link<InterfaceType>> this._levels,
      Link<InterfaceType> this.types, Link<InterfaceType> this._supertypes);

  factory OrderedTypeSet.singleton(InterfaceType type) {
    Link<InterfaceType> types =
        new LinkEntry<InterfaceType>(type, const Link<InterfaceType>());
    List<Link<InterfaceType>> list = new List<Link<InterfaceType>>(1);
    list[0] = types;
    return new OrderedTypeSet.internal(
        list, types, const Link<InterfaceType>());
  }

  /// Creates a new [OrderedTypeSet] for [type] when it directly extends the
  /// class which this set represents. This is for instance used to create the
  /// type set for [ClosureClassElement] which extends [Closure].
  OrderedTypeSet extendClass(InterfaceType type) {
    assert(invariant(type.element, types.head.treatAsRaw,
        message: 'Cannot extend generic class ${types.head} using '
            'OrderedTypeSet.extendClass'));
    Link<InterfaceType> extendedTypes =
        new LinkEntry<InterfaceType>(type, types);
    List<Link<InterfaceType>> list = new List<Link<InterfaceType>>(levels + 1);
    for (int i = 0; i < levels; i++) {
      list[i] = _levels[i];
    }
    list[levels] = extendedTypes;
    return new OrderedTypeSet.internal(
        list, extendedTypes, _supertypes.prepend(types.head));
  }

  Link<InterfaceType> get supertypes => _supertypes;

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
    List<int> offsets = new List.filled(levels, -1);
    int offset = 0;
    Link<InterfaceType> pointer = types;
    for (int depth = maxDepth; depth >= 0; depth--) {
      while (!identical(pointer, _levels[depth])) {
        pointer = pointer.tail;
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
        pointer = pointer.tail;
      }
    }
  }

  InterfaceType asInstanceOf(ClassEntity cls, int hierarchyDepth) {
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
abstract class OrderedTypeSetBuilder {
  OrderedTypeSet createOrderedTypeSet(
      InterfaceType supertype, Link<DartType> interfaces);
}

abstract class OrderedTypeSetBuilderBase implements OrderedTypeSetBuilder {
  Map<int, LinkEntry<InterfaceType>> map =
      new Map<int, LinkEntry<InterfaceType>>();
  // TODO(15296): Avoid computing this order on the side when member
  // lookup handles multiply inherited members correctly.
  LinkBuilder<InterfaceType> allSupertypes = new LinkBuilder<InterfaceType>();
  int maxDepth = -1;

  final DiagnosticReporter reporter;
  final ClassEntity cls;
  InterfaceType _objectType;

  // TODO(johnniwinther): Provide access to `Object` in deserialization and
  // make [objectType] mandatory.
  OrderedTypeSetBuilderBase(this.cls, {this.reporter, InterfaceType objectType})
      : this._objectType = objectType;

  InterfaceType getThisType(ClassEntity cls);
  InterfaceType substByContext(InterfaceType type, InterfaceType context);
  int getHierarchyDepth(ClassEntity cls);
  OrderedTypeSet getOrderedTypeSet(ClassEntity cls);

  OrderedTypeSet createOrderedTypeSet(
      InterfaceType supertype, Link<DartType> interfaces) {
    // TODO(15296): Collapse these iterations to one when the order is not
    // needed.
    add(supertype);
    for (Link<DartType> link = interfaces; !link.isEmpty; link = link.tail) {
      add(link.head);
    }

    _addAllSupertypes(supertype);
    for (Link<DartType> link = interfaces; !link.isEmpty; link = link.tail) {
      _addAllSupertypes(link.head);
    }
    add(getThisType(cls));
    return toTypeSet();
  }

  /**
   * Adds [type] and all supertypes of [type] to [allSupertypes] while
   * substituting type variables.
   */
  void _addAllSupertypes(InterfaceType type) {
    ClassEntity classElement = type.element;
    Link<InterfaceType> supertypes = getOrderedTypeSet(classElement).supertypes;
    assert(invariant(cls, supertypes != null,
        message: "Supertypes not computed on $classElement "
            "during resolution of $cls"));
    while (!supertypes.isEmpty) {
      InterfaceType supertype = supertypes.head;
      add(substByContext(supertype, type));
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
      _addAtDepth(type, getHierarchyDepth(type.element));
    }
  }

  void _addAtDepth(InterfaceType type, int depth) {
    LinkEntry<InterfaceType> prev = null;
    LinkEntry<InterfaceType> link = map[depth];
    while (link != null) {
      InterfaceType existingType = link.head;
      if (existingType == type) return;
      if (existingType.element == type.element) {
        if (reporter != null) {
          reporter.reportErrorMessage(cls, MessageKind.MULTI_INHERITANCE, {
            'thisType': getThisType(cls),
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
    LinkEntry<InterfaceType> next = new LinkEntry<InterfaceType>(type);
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
    List<Link<InterfaceType>> levels =
        new List<Link<InterfaceType>>(maxDepth + 1);
    if (maxDepth < 0) {
      return new OrderedTypeSet.internal(
          levels, const Link<InterfaceType>(), const Link<InterfaceType>());
    }
    Link<InterfaceType> next = const Link<InterfaceType>();
    for (int depth = 0; depth <= maxDepth; depth++) {
      LinkEntry<InterfaceType> first = map[depth];
      if (first == null) {
        levels[depth] = next;
      } else {
        levels[depth] = first;
        LinkEntry<InterfaceType> last = first;
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
      LinkEntry<InterfaceType> first = map[depth];
      if (first.isNotEmpty) {
        sb.write('${first.head}');
        while (first.tail.isNotEmpty) {
          sb.write(', ${first.tail.head}');
          first = first.tail;
        }
      }
      sb.write('\n');
    }
    return sb.toString();
  }
}

class ResolutionOrderedTypeSetBuilder extends OrderedTypeSetBuilderBase {
  ResolutionOrderedTypeSetBuilder(ClassElement cls,
      {DiagnosticReporter reporter, InterfaceType objectType})
      : super(cls, reporter: reporter, objectType: objectType);

  InterfaceType getThisType(ClassElement cls) => cls.thisType;

  ResolutionInterfaceType substByContext(
      ResolutionInterfaceType type, ResolutionInterfaceType context) {
    return type.substByContext(context);
  }

  int getHierarchyDepth(ClassElement cls) => cls.hierarchyDepth;

  OrderedTypeSet getOrderedTypeSet(ClassElement cls) =>
      cls.allSupertypesAndSelf;

  OrderedTypeSet createOrderedTypeSet(
      InterfaceType supertype, Link<DartType> interfaces) {
    if (_objectType == null) {
      // Find `Object` through in hierarchy. This is used for serialization
      // where it is assumed that the hierarchy is valid.
      ResolutionInterfaceType objectType = supertype;
      while (!objectType.isObject) {
        objectType = objectType.element.supertype;
      }
      _objectType = objectType;
    }
    return super.createOrderedTypeSet(supertype, interfaces);
  }
}
