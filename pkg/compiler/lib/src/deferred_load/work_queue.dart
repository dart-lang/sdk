// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection' show Queue;

import 'algorithm_state.dart';
import 'entity_data.dart';
import 'import_set.dart';

import '../elements/entities.dart';

/// The entity_data_state work queue.
class WorkQueue {
  /// The actual queue of work that needs to be done.
  final Queue<WorkItem> queue = Queue();

  /// An index to find work items in the queue corresponding to a given
  /// [EntityData].
  final Map<EntityData, WorkItem> pendingWorkItems = {};

  /// Lattice used to compute unions of [ImportSet]s.
  final ImportSetLattice _importSets;

  /// Registry used to create [EntityData].
  final EntityDataRegistry _registry;

  WorkQueue(this._importSets, this._registry);

  /// Whether there are no more work items in the queue.
  bool get isNotEmpty => queue.isNotEmpty;

  /// Pop the next element in the queue.
  WorkItem nextItem() {
    assert(isNotEmpty);
    return queue.removeFirst();
  }

  /// Add to the queue that [element] should be updated to include all imports
  /// in [importSet]. If there is already a work item in the queue for
  /// [element], this makes sure that the work item now includes the union of
  /// [importSet] and the existing work item's import set.
  void addEntityData(EntityData entityData, ImportSet importSet) {
    var item = pendingWorkItems[entityData];
    if (item == null) {
      item = WorkItem(entityData, importSet);
      pendingWorkItems[entityData] = item;
      queue.add(item);
    } else {
      item.importsToAdd = _importSets.union(item.importsToAdd, importSet);
    }
  }

  void addMember(MemberEntity member, ImportSet importSet) {
    addEntityData(_registry.createMemberEntityData(member), importSet);
  }

  void addClass(ClassEntity cls, ImportSet importSet) {
    addEntityData(_registry.createClassEntityData(cls), importSet);
  }

  /// Processes the next item in the queue.
  void processNextItem(AlgorithmState state) {
    var item = nextItem();
    var entityData = item.entityData;
    pendingWorkItems.remove(entityData);
    state.processEntity(entityData);
    ImportSet oldSet = state.entityToSet[entityData];
    ImportSet newSet = _importSets.union(oldSet, item.importsToAdd);
    state.update(entityData, oldSet, newSet);
  }
}

/// Summary of the work that needs to be done on a class, member, or constant.
class WorkItem {
  final EntityData entityData;

  /// Additional imports that use [element] or [value] and need to be added by
  /// the algorithm.
  ///
  /// This is non-final in case we add more deferred imports to the set before
  /// the work item is applied (see [WorkQueue.addElement] and
  /// [WorkQueue.addConstant]).
  ImportSet importsToAdd;

  WorkItem(this.entityData, this.importsToAdd);
}
