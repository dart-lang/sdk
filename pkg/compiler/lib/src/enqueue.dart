// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.10

library dart2js.enqueue;

import 'common/elements.dart' show ElementEnvironment;
import 'common/tasks.dart' show CompilerTask;
import 'common/work.dart' show WorkItem;
import 'constants/values.dart';
import 'elements/entities.dart';
import 'elements/types.dart';
import 'universe/use.dart' show ConstantUse, DynamicUse, StaticUse, TypeUse;
import 'universe/world_impact.dart' show WorldImpact;

abstract class EnqueuerListener {
  /// Called to instruct to the backend that [type] has been instantiated.
  void registerInstantiatedType(InterfaceType type,
      {bool isGlobal = false, bool nativeUsage = false});

  /// Called to notify to the backend that a class is being instantiated. Any
  /// backend specific [WorldImpact] of this is returned.
  WorldImpact registerInstantiatedClass(ClassEntity cls);

  /// Called to notify to the backend that a class is implemented by an
  /// instantiated class. Any backend specific [WorldImpact] of this is
  /// returned.
  WorldImpact registerImplementedClass(ClassEntity cls);

  /// Called to register that a static function has been closurized. Any backend
  /// specific [WorldImpact] of this is returned.
  WorldImpact registerGetOfStaticFunction();

  /// Called to register that [function] has been closurized. Any backend
  /// specific [WorldImpact] of this is returned.
  WorldImpact registerClosurizedMember(FunctionEntity function);

  /// Called to register that [element] is statically known to be used. Any
  /// backend specific [WorldImpact] of this is returned.
  WorldImpact registerUsedElement(MemberEntity member);

  /// Called to register that [value] is statically known to be used. Any
  /// backend specific [WorldImpact] of this is returned.
  WorldImpact registerUsedConstant(ConstantValue value);

  void onQueueOpen(
      Enqueuer enqueuer, FunctionEntity mainMethod, Iterable<Uri> libraries);

  /// Called when [enqueuer]'s queue is empty, but before it is closed.
  ///
  /// This is used, for example, by the JS backend to enqueue additional
  /// elements needed for reflection. [recentClasses] is a collection of
  /// all classes seen for the first time by the [enqueuer] since the last call
  /// to [onQueueEmpty].
  ///
  /// A return value of `true` indicates that [recentClasses] has been
  /// processed and its elements do not need to be seen in the next round. When
  /// `false` is returned, [onQueueEmpty] will be called again once the
  /// resolution queue has drained and [recentClasses] will be a superset of the
  /// current value.
  ///
  /// There is no guarantee that a class is only present once in
  /// [recentClasses], but every class seen by the [enqueuer] will be present in
  /// [recentClasses] at least once.
  bool onQueueEmpty(Enqueuer enqueuer, Iterable<ClassEntity> recentClasses);

  /// Called when to the queue has been closed.
  void onQueueClosed();

  /// Called after the queue has been emptied.
  void logSummary(void log(String message));
}

abstract class Enqueuer {
  /// If `true` the checking for unenqueued members is skipped. The current
  /// implementation registers parameter usages as a side-effect so unit
  /// testing of member usage we need to test both with and without the
  /// enqueuer check.
  // TODO(johnniwinther): [checkEnqueuerConsistency] should not have
  // side-effects.
  static bool skipEnqueuerCheckForTesting = false;

  bool queueIsClosed;

  bool get queueIsEmpty;

  void forEach(void f(WorkItem work));

  /// Apply the [worldImpact] to this enqueuer.
  void applyImpact(WorldImpact worldImpact) {
    if (worldImpact.isEmpty) return;
    worldImpact.forEachStaticUse(processStaticUse);
    worldImpact.forEachDynamicUse((_, use) => processDynamicUse(use));
    worldImpact.forEachTypeUse(processTypeUse);
    worldImpact.forEachConstantUse((_, use) => processConstantUse(use));
  }

  bool checkNoEnqueuedInvokedInstanceMethods(
      ElementEnvironment elementEnvironment);

  /// Check the enqueuer queue is empty or fail otherwise.
  void checkQueueIsEmpty();
  void logSummary(void log(String message));

  Iterable<MemberEntity> get processedEntities;

  Iterable<ClassEntity> get directlyInstantiatedClasses;

  CompilerTask get task;
  void checkClass(ClassEntity cls);
  void processStaticUse(MemberEntity member, StaticUse staticUse);
  void processTypeUse(MemberEntity member, TypeUse typeUse);
  void processDynamicUse(DynamicUse dynamicUse);
  void processConstantUse(ConstantUse constantUse);
  EnqueuerListener get listener;

  void open(FunctionEntity mainMethod, Iterable<Uri> libraries) {
    listener.onQueueOpen(this, mainMethod, libraries);
  }

  void close() {
    listener.onQueueClosed();
  }

  /// Check enqueuer consistency after the queue has been closed.
  bool checkEnqueuerConsistency(ElementEnvironment elementEnvironment) {
    task.measureSubtask('resolution.check', () {
      // Run through the classes and see if we need to enqueue more methods.
      for (ClassEntity classElement in directlyInstantiatedClasses) {
        for (ClassEntity currentClass = classElement;
            currentClass != null;
            currentClass = elementEnvironment.getSuperClass(currentClass)) {
          checkClass(currentClass);
        }
      }
    });
    return true;
  }
}

/// Interface for creating work items for enqueued member entities.
abstract class WorkItemBuilder {
  WorkItem createWorkItem(covariant MemberEntity entity);
}
