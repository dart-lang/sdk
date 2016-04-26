// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_CHA_H_
#define VM_CHA_H_

#include "vm/allocation.h"
#include "vm/growable_array.h"
#include "vm/thread.h"

namespace dart {

class Class;
class Function;
template <typename T> class ZoneGrowableArray;
class String;

class CHA : public StackResource {
 public:
  explicit CHA(Thread* thread)
      : StackResource(thread),
        thread_(thread),
        leaf_classes_(thread->zone(), 1),
        previous_(thread->cha()) {
    thread->set_cha(this);
  }

  ~CHA() {
    ASSERT(thread_->cha() == this);
    thread_->set_cha(previous_);
  }

  // Returns true if the class has subclasses.
  static bool HasSubclasses(const Class& cls);
  bool HasSubclasses(intptr_t cid) const;

  // Collect the concrete subclasses of 'cls' into 'class_ids'. Return true if
  // the result is valid (may be invalid because we don't track the subclasses
  // of classes allocated in the VM isolate or class Object).
  bool ConcreteSubclasses(const Class& cls, GrowableArray<intptr_t> *class_ids);

  // Return true if the class is implemented by some other class.
  static bool IsImplemented(const Class& cls);

  // Returns true if any subclass of 'cls' contains the function.
  bool HasOverride(const Class& cls, const String& function_name);

  const GrowableArray<Class*>& leaf_classes() const {
    return leaf_classes_;
  }

  // Adds class 'cls' to the list of guarded leaf classes, deoptimization occurs
  // if any of those leaf classes gets subclassed through later loaded/finalized
  // libraries. Only classes that were used for CHA optimizations are added.
  void AddToLeafClasses(const Class& cls);

 private:
  Thread* thread_;
  GrowableArray<Class*> leaf_classes_;
  CHA* previous_;
};

}  // namespace dart

#endif  // VM_CHA_H_
