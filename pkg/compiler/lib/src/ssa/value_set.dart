// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../universe/side_effects.dart' show SideEffects;
import '../util/bitset.dart';
import 'nodes.dart';

class ValueSet {
  int size = 0;
  List<HInstruction?> table = List.filled(8, null);
  ValueSetNode? collisions;
  ValueSet();

  bool get isEmpty => size == 0;
  int get length => size;

  void add(HInstruction instruction) {
    assert(lookup(instruction) == null);
    int hashCode = instruction.gvnHashCode();
    int capacity = table.length;
    // Resize when half of the hash table is in use.
    if (size >= capacity >> 1) {
      capacity = capacity << 1;
      resize(capacity);
    }
    // Try to insert in the hash table first.
    int index = hashCode % capacity;
    if (table[index] == null) {
      table[index] = instruction;
    } else {
      collisions = ValueSetNode(instruction, hashCode, collisions);
    }
    size++;
  }

  HInstruction? lookup(HInstruction instruction) {
    int hashCode = instruction.gvnHashCode();
    int index = hashCode % table.length;
    // Look in the hash table.
    HInstruction? probe = table[index];
    if (probe != null && probe.gvnEquals(instruction)) return probe;
    // Look in the collisions list.
    for (ValueSetNode? node = collisions; node != null; node = node.next) {
      if (node.hashCode == hashCode) {
        HInstruction cached = node.value;
        if (cached.gvnEquals(instruction)) return cached;
      }
    }
    return null;
  }

  void kill(Bitset flags) {
    if (flags.isEmpty) return;
    final depends = SideEffects.computeDependsOnFlags(flags);
    // Remove entries from the hash table that depend on the 'killed' effect
    // flags. Keep idempotent (allowCSE) entries.
    for (int index = 0, length = table.length; index < length; index++) {
      HInstruction? instruction = table[index];
      if (instruction != null) {
        if (!instruction.allowCSE &&
            instruction.sideEffects.dependsOn(depends)) {
          table[index] = null;
          size--;
        }
      }
    }
    // Kill in the collisions list.
    ValueSetNode? previous;
    ValueSetNode? current = collisions;
    while (current != null) {
      ValueSetNode? next = current.next;
      HInstruction cached = current.value;
      if (!cached.allowCSE && cached.sideEffects.dependsOn(depends)) {
        if (previous == null) {
          collisions = next;
        } else {
          previous.next = next;
        }
        size--;
      } else {
        previous = current;
      }
      current = next;
    }
  }

  ValueSet copy() {
    return copyTo(ValueSet(), table, collisions);
  }

  List<HInstruction> toList() {
    List<HInstruction> result = [];
    // Copy elements from the hash table.
    for (final instruction in table) {
      if (instruction != null) result.add(instruction);
    }
    // Copy elements from the collision list.
    for (var current = collisions; current != null; current = current.next) {
      result.add(current.value);
    }
    return result;
  }

  // Copy the instructions in value set defined by [table] and
  // [collisions] into [other] and returns [other]. The copy is done
  // by iterating through the hash table and the collisions list and
  // calling [:other.add:].
  static ValueSet copyTo(
    ValueSet other,
    List<HInstruction?> table,
    ValueSetNode? collisions,
  ) {
    // Copy elements from the hash table.
    for (final instruction in table) {
      if (instruction != null) other.add(instruction);
    }
    // Copy elements from the collision list.
    for (var current = collisions; current != null; current = current.next) {
      // TODO(kasperl): Maybe find a way of reusing the hash code
      // rather than recomputing it every time.
      other.add(current.value);
    }
    return other;
  }

  ValueSet intersection(ValueSet other) {
    if (size > other.size) return other.intersection(this);
    ValueSet result = ValueSet();
    // Look in the hash table.
    for (int index = 0, length = table.length; index < length; index++) {
      HInstruction? instruction = table[index];
      if (instruction != null && other.lookup(instruction) != null) {
        result.add(instruction);
      }
    }
    // Look in the collision list.
    ValueSetNode? current = collisions;
    while (current != null) {
      HInstruction value = current.value;
      if (other.lookup(value) != null) {
        result.add(value);
      }
      current = current.next;
    }
    return result;
  }

  void resize(int capacity) {
    var oldSize = size;
    var oldTable = table;
    var oldCollisions = collisions;
    // Reset the table with a bigger capacity.
    assert(capacity > table.length);
    size = 0;
    table = List.filled(capacity, null);
    collisions = null;
    // Add the old instructions to the new table.
    copyTo(this, oldTable, oldCollisions);
    // Make sure we preserved all elements and that no resizing
    // happened as part of this resizing.
    assert(size == oldSize);
    assert(table.length == capacity);
  }
}

class ValueSetNode {
  final HInstruction value;
  final int hash;
  @override
  int get hashCode => hash;
  ValueSetNode? next;
  ValueSetNode(this.value, this.hash, this.next);

  @override
  bool operator ==(other) => identical(this, other);
}
