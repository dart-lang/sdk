// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of deferred_load;

/// The deferred_load algorithm work queue.
class WorkQueue {
  /// The actual queue of work that needs to be done.
  final Queue<WorkItem> queue = Queue();

  /// An index to find work items in the queue corresponding to a class.
  final Map<ClassEntity, WorkItem> pendingClasses = {};

  /// An index to find work items in the queue corresponding to an
  /// [InterfaceType] represented here by its [ClassEntitiy].
  final Map<ClassEntity, WorkItem> pendingClassType = {};

  /// An index to find work items in the queue corresponding to a member.
  final Map<MemberEntity, WorkItem> pendingMembers = {};

  /// An index to find work items in the queue corresponding to a constant.
  final Map<ConstantValue, WorkItem> pendingConstants = {};

  /// Lattice used to compute unions of [ImportSet]s.
  final ImportSetLattice _importSets;

  WorkQueue(this._importSets);

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
  void addClass(ClassEntity element, ImportSet importSet) {
    var item = pendingClasses[element];
    if (item == null) {
      item = ClassWorkItem(element, importSet);
      pendingClasses[element] = item;
      queue.add(item);
    } else {
      item.importsToAdd = _importSets.union(item.importsToAdd, importSet);
    }
  }

  /// Add to the queue that class type (represented by [element]) should be
  /// updated to include all imports in [importSet]. If there is already a
  /// work item in the queue for [element], this makes sure that the work
  /// item now includes the union of [importSet] and the existing work
  /// item's import set.
  void addClassType(ClassEntity element, ImportSet importSet) {
    var item = pendingClassType[element];
    if (item == null) {
      item = ClassTypeWorkItem(element, importSet);
      pendingClassType[element] = item;
      queue.add(item);
    } else {
      item.importsToAdd = _importSets.union(item.importsToAdd, importSet);
    }
  }

  /// Add to the queue that [element] should be updated to include all imports
  /// in [importSet]. If there is already a work item in the queue for
  /// [element], this makes sure that the work item now includes the union of
  /// [importSet] and the existing work item's import set.
  void addMember(MemberEntity element, ImportSet importSet) {
    var item = pendingMembers[element];
    if (item == null) {
      item = MemberWorkItem(element, importSet);
      pendingMembers[element] = item;
      queue.add(item);
    } else {
      item.importsToAdd = _importSets.union(item.importsToAdd, importSet);
    }
  }

  /// Add to the queue that [constant] should be updated to include all imports
  /// in [importSet]. If there is already a work item in the queue for
  /// [constant], this makes sure that the work item now includes the union of
  /// [importSet] and the existing work item's import set.
  void addConstant(ConstantValue constant, ImportSet importSet) {
    var item = pendingConstants[constant];
    if (item == null) {
      item = ConstantWorkItem(constant, importSet);
      pendingConstants[constant] = item;
      queue.add(item);
    } else {
      item.importsToAdd = _importSets.union(item.importsToAdd, importSet);
    }
  }
}

/// Summary of the work that needs to be done on a class, member, or constant.
abstract class WorkItem {
  /// Additional imports that use [element] or [value] and need to be added by
  /// the algorithm.
  ///
  /// This is non-final in case we add more deferred imports to the set before
  /// the work item is applied (see [WorkQueue.addElement] and
  /// [WorkQueue.addConstant]).
  ImportSet importsToAdd;

  WorkItem(this.importsToAdd);

  void update(DeferredLoadTask task, KClosedWorld closedWorld, WorkQueue queue);
}

/// Summary of the work that needs to be done on a class.
class ClassWorkItem extends WorkItem {
  /// Class to be recursively updated.
  final ClassEntity cls;

  ClassWorkItem(this.cls, ImportSet newSet) : super(newSet);

  @override
  void update(
      DeferredLoadTask task, KClosedWorld closedWorld, WorkQueue queue) {
    queue.pendingClasses.remove(cls);
    ImportSet oldSet = task._classToSet[cls];
    ImportSet newSet = task.importSets.union(oldSet, importsToAdd);
    task._updateClassRecursive(closedWorld, cls, oldSet, newSet, queue);
  }
}

/// Summary of the work that needs to be done on a class.
class ClassTypeWorkItem extends WorkItem {
  /// Class to be recursively updated.
  final ClassEntity cls;

  ClassTypeWorkItem(this.cls, ImportSet newSet) : super(newSet);

  @override
  void update(
      DeferredLoadTask task, KClosedWorld closedWorld, WorkQueue queue) {
    queue.pendingClassType.remove(cls);
    ImportSet oldSet = task._classTypeToSet[cls];
    ImportSet newSet = task.importSets.union(oldSet, importsToAdd);
    task._updateClassTypeRecursive(closedWorld, cls, oldSet, newSet, queue);
  }
}

/// Summary of the work that needs to be done on a member.
class MemberWorkItem extends WorkItem {
  /// Member to be recursively updated.
  final MemberEntity member;

  MemberWorkItem(this.member, ImportSet newSet) : super(newSet);

  @override
  void update(
      DeferredLoadTask task, KClosedWorld closedWorld, WorkQueue queue) {
    queue.pendingMembers.remove(member);
    ImportSet oldSet = task._memberToSet[member];
    ImportSet newSet = task.importSets.union(oldSet, importsToAdd);
    task._updateMemberRecursive(closedWorld, member, oldSet, newSet, queue);
  }
}

/// Summary of the work that needs to be done on a constant.
class ConstantWorkItem extends WorkItem {
  /// Constant to be recursively updated.
  final ConstantValue constant;

  ConstantWorkItem(this.constant, ImportSet newSet) : super(newSet);

  @override
  void update(
      DeferredLoadTask task, KClosedWorld closedWorld, WorkQueue queue) {
    queue.pendingConstants.remove(constant);
    ImportSet oldSet = task._constantToSet[constant];
    ImportSet newSet = task.importSets.union(oldSet, importsToAdd);
    task._updateConstantRecursive(closedWorld, constant, oldSet, newSet, queue);
  }
}
