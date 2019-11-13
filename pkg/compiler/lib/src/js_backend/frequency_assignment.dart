// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection' show SplayTreeMap;

/// Assigns names from [nameSequence] to items using a naive algorithm.
///
/// Items are assigned the next available name in decreasing frequency
/// order. This allocation order is unstable in that small changes in the input
/// cause large changes in the output. To see this, consider a typical
/// distribution that has a 'tail' where large numbers of items occur two or
/// three times. If the small change causes one of the items that occurs twice
/// to occur four times, of then all the items that occur three times will be
/// assigned names that are 'shifted down' in the allocation order, as will many
/// of the items that occur twice.
///
/// See [semistableFrequencyAssignment] for meaning of parameters.
void naiveFrequencyAssignment(
    int items,
    Iterable<String> nameSequence,
    int Function(int) hashOf,
    int Function(int) countOf,
    void Function(int, String) assign) {
  Iterator<String> nameIterator = nameSequence.iterator..moveNext();

  for (int item = 0; item < items; item++) {
    assign(item, nameIterator.current);
    nameIterator.moveNext();
  }
}

/// Assigns names from [nameSequence] to items, trying to avoid the unstable
/// allocation of [naiveFrequencyAssignment] by assigning items to their
/// hashing-based 'preferred' slots if possible.
///
/// - [items]: number of items to be assigned names. Items are numbered from
///   zero. Items must be sorted in order of decreasing [countOf].
///
/// - [nameSequence]: Potentially unbounded sequence of valid names in
///   increasing size.
///
/// - [hashOf]: Function returning a stable hash code for item `i`.
///
/// - [countOf]: Function returning the frequency or number of occurences of
///   item `i`.
///
/// - [assign]: Function to register the assignment of a name to item `i`.
void semistableFrequencyAssignment(
    int items,
    Iterable<String> nameSequence,
    int Function(int) hashOf,
    int Function(int) countOf,
    void Function(int, String) assign) {
  // Overallocate 3x the number of names so that the last pool is large enough
  // to substantially reduce collisions. Round up to the next power of two so
  // that slightly changing the number of items does not usually change the size
  // of the largest pool.
  int maxIndex = 1 << (items * 3).bitLength;
  List<String> names = nameSequence.take(maxIndex).toList(growable: false);
  List<_Pool> pools = _Pool.makePools(names);

  // First cohort with unassigned items.
  _Cohort firstCohort = _Cohort.makeCohorts(items, countOf);

  for (var pool in pools) {
    // Completely allocate smaller pools before allocating larger
    // pools. Completely allocate each cohort in turn.

    // TODO(sra): If the next several cohorts all fit in the current pool, the
    // allocation will not change the bytes saved by minification.  Consider
    // allocating the preferred slot from several cohorts before allocating a
    // non-preferred slot. This should increase the number of items allocated to
    // their preferred slot.
    firstCohort = firstCohort?.skipEmpty();
    for (var startCohort = firstCohort;
        startCohort != null;
        startCohort = startCohort.next) {
      if (pool.remaining == 0) break;

      // Pass 1: assign members of cohort their preferred slot if available.
      List<int> assigned = [];
      for (var item in startCohort.unassigned) {
        if (pool.remaining == 0) break;
        int hash = hashOf(item);
        int slot = hash % pool.size;
        if (pool.slotIsAvailable(slot)) {
          assign(item, pool.allocate(slot));
          assigned.add(item);
        }
      }
      startCohort.unassigned.removeAll(assigned);
      // Pass 2: assign members of cohort their second 'rehash' slot if
      // available, or the next available slot.
      assigned.clear();
      for (var item in startCohort.unassigned) {
        if (pool.remaining == 0) break;
        int hash = hashOf(item);
        int rehashSlot = (5 * hash + 7) % pool.size;
        int slot = pool.firstAvailableSlotFrom(rehashSlot);
        assign(item, pool.allocate(slot));
        assigned.add(item);
      }
      startCohort.unassigned.removeAll(assigned);
    }
  }

  // Perform naive assignment of any items left unassigned above (should be
  // none).
  for (var pool in pools) {
    while (pool.remaining > 0) {
      firstCohort = firstCohort?.skipEmpty();
      if (firstCohort == null) break;

      var item = firstCohort.unassigned.first;
      String name = pool.allocate(pool.firstAvailableSlot());
      assign(item, name);
      firstCohort.unassigned.remove(item);
    }
  }
}

/// A [_Pool] is a set of identifiers of the same length from which names are
/// allocated.
class _Pool {
  final List<String /*?*/ > _names = [];

  // Keep the unused (available) slots in an ordered set for efficiently finding
  // the next available slot (i.e. linear rehash).  We are concerned about
  // efficiency because the smaller pools are completely allocated, making
  // worst-case linear rehashing quadratic. Using an ordered map brings this
  // down to O(N log N).
  //
  // We would prefer an ordered Set, but SplayTreeSet does not have methods to
  // find keys adjacent to a query key.
  final SplayTreeMap<int, bool> _availableSlots = SplayTreeMap();

  static List<_Pool> makePools(Iterable<String> names) {
    List<_Pool> pools = [];
    for (var name in names) {
      int length = name.length;
      while (pools.length < length) pools.add(_Pool());
      _Pool pool = pools[length - 1];
      pool._availableSlots[pool._names.length] = true;
      pool._names.add(name);
    }
    return pools;
  }

  int get size => _names.length;
  int get remaining => _availableSlots.length;

  bool slotIsAvailable(int slot) => _names[slot] != null;

  int firstAvailableSlot() => _availableSlots.keys.first;

  /// Returns [start] if slot [start] is free, otherwise returns the next
  /// available slot.
  int firstAvailableSlotFrom(int start) =>
      _availableSlots.firstKeyAfter(start - 1) ??
      _availableSlots.firstKeyAfter(-1) ??
      (throw StateError('No entries left in pool'));

  String allocate(int slot) {
    String name = _names[slot];
    assert(name != null);
    _names[slot] = null;
    _availableSlots.remove(slot);
    return name;
  }

  @override
  String toString() => '_Pool(${_names.length}, ${_availableSlots.length})';
}

/// A [_Cohort] is a set of entities which occur with the same frequency. The
/// entities are identified by integers.
class _Cohort {
  _Cohort next; // Next cohort in decreasing frequency.
  final int count; // This is the cohort of items occuring [count] times.
  Set<int> unassigned = Set();

  _Cohort(this.count);

  _Cohort skipEmpty() {
    _Cohort cohort = this;
    while (cohort != null && cohort.remaining == 0) cohort = cohort.next;
    return cohort;
  }

  int get remaining => unassigned.length;

  static _Cohort makeCohorts(int items, int Function(int) countOf) {
    // Build _Cohorts.
    _Cohort first, current;
    int lastCount = -1;
    for (int item = 0; item < items; item++) {
      int count = countOf(item);
      if (count != lastCount) {
        lastCount = count;
        _Cohort next = _Cohort(count);
        if (current == null) {
          first = next;
        } else {
          current.next = next;
        }
        current = next;
      }
      current.unassigned.add(item);
    }
    return first;
  }

  @override
  String toString() => '_Cohort($count, $remaining)';
}
