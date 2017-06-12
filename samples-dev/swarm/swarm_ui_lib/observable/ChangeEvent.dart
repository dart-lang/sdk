// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of observable;

/** A change to an observable instance. */
class ChangeEvent {
  // TODO(sigmund): capture language issues around enums & create a canonical
  // Dart enum design.
  /** Type denoting an in-place update event. */
  static const UPDATE = 0;

  /** Type denoting an insertion event. */
  static const INSERT = 1;

  /** Type denoting a single-remove event. */
  static const REMOVE = 2;

  /**
   * Type denoting events that affect the entire observable instance. For
   * example, a list operation like clear or sort.
   */
  static const GLOBAL = 3;

  /** The observable instance that changed. */
  final Observable target;

  /** Whether the change was an [INSERT], [REMOVE], or [UPDATE]. */
  final int type;

  /** The value after the change (or inserted value in a list). */
  final newValue;

  /** The value before the change (or removed value from a list). */
  final oldValue;

  /** Property that changed (null for list changes). */
  final String propertyName;

  /**
   * Index of the list operation. Insertions prepend in front of the given
   * index (insert at 0 means an insertion at the beginning of the list).
   */
  final int index;

  /** Factory constructor for property change events. */
  ChangeEvent.property(
      this.target, this.propertyName, this.newValue, this.oldValue)
      : type = UPDATE,
        index = null;

  /** Factory constructor for list change events. */
  ChangeEvent.list(
      this.target, this.type, this.index, this.newValue, this.oldValue)
      : propertyName = null;

  /** Factory constructor for [GLOBAL] change events. */
  ChangeEvent.global(this.target)
      : type = GLOBAL,
        newValue = null,
        oldValue = null,
        propertyName = null,
        index = null;
}

/** A collection of change events on a single observable instance. */
class EventSummary {
  final Observable target;

  // TODO(sigmund): evolve this to track changes per property.
  List<ChangeEvent> events;

  EventSummary(this.target) : events = new List<ChangeEvent>();

  void addEvent(ChangeEvent e) {
    events.add(e);
  }

  /** Notify listeners of [target] and parents of [target] about all changes. */
  void notify() {
    if (!events.isEmpty) {
      for (Observable obj = target; obj != null; obj = obj.parent) {
        for (final listener in obj.listeners) {
          listener(this);
        }
      }
    }
  }
}

/** A listener of change events. */
typedef void ChangeListener(EventSummary events);
