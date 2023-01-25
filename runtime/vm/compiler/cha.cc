// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/cha.h"
#include "vm/class_table.h"
#include "vm/compiler/compiler_state.h"
#include "vm/flags.h"
#include "vm/log.h"
#include "vm/object.h"
#include "vm/raw_object.h"
#include "vm/visitor.h"

namespace dart {

void CHA::AddToGuardedClasses(const Class& cls, intptr_t subclass_count) {
  ASSERT(subclass_count >= 0);
  for (intptr_t i = 0; i < guarded_classes_.length(); i++) {
    if (guarded_classes_[i].cls->ptr() == cls.ptr()) {
      // Was added as an interface guard.
      if (guarded_classes_[i].subclass_count == -1) {
        guarded_classes_[i].subclass_count = subclass_count;
      }
      return;
    }
  }
  GuardedClassInfo info = {&Class::ZoneHandle(thread_->zone(), cls.ptr()),
                           subclass_count, kIllegalCid};
  guarded_classes_.Add(info);
}

void CHA::AddToGuardedInterfaces(const Class& cls, intptr_t implementor_cid) {
  ASSERT(implementor_cid != kIllegalCid);
  ASSERT(implementor_cid != kDynamicCid);
  for (intptr_t i = 0; i < guarded_classes_.length(); i++) {
    if (guarded_classes_[i].cls->ptr() == cls.ptr()) {
      // Was added as a subclass guard.
      if (guarded_classes_[i].implementor_cid == kIllegalCid) {
        guarded_classes_[i].implementor_cid = implementor_cid;
      }
      return;
    }
  }
  GuardedClassInfo info = {&Class::ZoneHandle(thread_->zone(), cls.ptr()), -1,
                           implementor_cid};
  guarded_classes_.Add(info);
}

bool CHA::IsGuardedClass(intptr_t cid) const {
  for (intptr_t i = 0; i < guarded_classes_.length(); ++i) {
    if (guarded_classes_[i].cls->id() == cid) return true;
  }
  return false;
}

bool CHA::HasSubclasses(const Class& cls) {
  ASSERT(!cls.IsNull());
  ASSERT(!IsInternalOnlyClassId(cls.id()));
  // Can't track dependencies for classes on the VM heap since those are
  // read-only.
  // TODO(fschneider): Enable tracking of CHA dependent code for VM heap
  // classes.
  if (cls.InVMIsolateHeap()) return true;

  if (cls.IsObjectClass()) {
    // Class Object has subclasses, although we do not keep track of them.
    return true;
  }
  Thread* thread = Thread::Current();
  SafepointReadRwLocker ml(thread, thread->isolate_group()->program_lock());
  const GrowableObjectArray& direct_subclasses =
      GrowableObjectArray::Handle(cls.direct_subclasses());
  return !direct_subclasses.IsNull() && (direct_subclasses.Length() > 0);
}

bool CHA::HasSubclasses(intptr_t cid) const {
  const ClassTable& class_table = *thread_->isolate_group()->class_table();
  Class& cls = Class::Handle(thread_->zone(), class_table.At(cid));
  return HasSubclasses(cls);
}

bool CHA::ConcreteSubclasses(const Class& cls,
                             GrowableArray<intptr_t>* class_ids) {
  if (cls.InVMIsolateHeap()) return false;
  if (cls.IsObjectClass()) return false;

  if (!cls.is_abstract()) {
    class_ids->Add(cls.id());
  }

  // This is invoked from precompiler only, we can use unsafe version of
  // Class::direct_subclasses getter.
  ASSERT(FLAG_precompiled_mode);
  const GrowableObjectArray& direct_subclasses =
      GrowableObjectArray::Handle(cls.direct_subclasses_unsafe());
  if (direct_subclasses.IsNull()) {
    return true;
  }
  Class& subclass = Class::Handle();
  for (intptr_t i = 0; i < direct_subclasses.Length(); i++) {
    subclass ^= direct_subclasses.At(i);
    if (!ConcreteSubclasses(subclass, class_ids)) {
      return false;
    }
  }
  return true;
}

bool CHA::IsImplemented(const Class& cls) {
  // Can't track dependencies for classes on the VM heap since those are
  // read-only.
  // TODO(fschneider): Enable tracking of CHA dependent code for VM heap
  // classes.
  if (cls.InVMIsolateHeap()) return true;

  return cls.is_implemented();
}

bool CHA::HasSingleConcreteImplementation(const Class& interface,
                                          intptr_t* implementation_cid) {
  intptr_t cid = interface.implementor_cid();
  if ((cid == kIllegalCid) || (cid == kDynamicCid)) {
    // No implementations / multiple implementations.
    *implementation_cid = kDynamicCid;
    return false;
  }

  Thread* thread = Thread::Current();
  if (FLAG_use_cha_deopt || thread->isolate_group()->all_classes_finalized()) {
    if (FLAG_trace_cha) {
      THR_Print("  **(CHA) Type has one implementation: %s\n",
                interface.ToCString());
    }
    if (FLAG_use_cha_deopt) {
      CHA& cha = thread->compiler_state().cha();
      cha.AddToGuardedInterfaces(interface, cid);
    }
    *implementation_cid = cid;
    return true;
  } else {
    *implementation_cid = kDynamicCid;
    return false;
  }
}

static intptr_t CountFinalizedSubclasses(Thread* thread, const Class& cls) {
  intptr_t count = 0;
  const GrowableObjectArray& cls_direct_subclasses =
      GrowableObjectArray::Handle(thread->zone(), cls.direct_subclasses());
  if (cls_direct_subclasses.IsNull()) return count;
  Class& direct_subclass = Class::Handle(thread->zone());
  for (intptr_t i = 0; i < cls_direct_subclasses.Length(); i++) {
    direct_subclass ^= cls_direct_subclasses.At(i);
    // Unfinalized classes are treated as nonexistent for CHA purposes,
    // as that means that no instance of that class exists at runtime.
    if (!direct_subclass.is_finalized()) {
      continue;
    }

    count += 1 + CountFinalizedSubclasses(thread, direct_subclass);
  }
  return count;
}

bool CHA::IsConsistentWithCurrentHierarchy() const {
  for (intptr_t i = 0; i < guarded_classes_.length(); i++) {
    if (guarded_classes_[i].subclass_count != -1) {
      intptr_t current_subclass_count =
          CountFinalizedSubclasses(thread_, *guarded_classes_[i].cls);
      if (guarded_classes_[i].subclass_count != current_subclass_count) {
        return false;  // New subclass appeared during compilation.
      }
    }
    if (guarded_classes_[i].implementor_cid != kIllegalCid) {
      intptr_t current_implementor_cid =
          guarded_classes_[i].cls->implementor_cid();
      if (guarded_classes_[i].implementor_cid != current_implementor_cid) {
        return false;  // New implementor appeared during compilation.
      }
    }
  }
  return true;
}

bool CHA::HasOverride(const Class& cls,
                      const String& function_name,
                      intptr_t* subclasses_count) {
  // Can't track dependencies for classes on the VM heap since those are
  // read-only.
  // TODO(fschneider): Enable tracking of CHA dependent code for VM heap
  // classes.
  if (cls.InVMIsolateHeap()) return true;

  // Subclasses of Object are not tracked by CHA. Safely assume that overrides
  // exist.
  if (cls.IsObjectClass()) {
    return true;
  }

  SafepointReadRwLocker ml(thread_, thread_->isolate_group()->program_lock());
  const GrowableObjectArray& cls_direct_subclasses =
      GrowableObjectArray::Handle(thread_->zone(), cls.direct_subclasses());
  if (cls_direct_subclasses.IsNull()) {
    return false;
  }
  Class& direct_subclass = Class::Handle(thread_->zone());
  for (intptr_t i = 0; i < cls_direct_subclasses.Length(); i++) {
    direct_subclass ^= cls_direct_subclasses.At(i);
    // Unfinalized classes are treated as nonexistent for CHA purposes,
    // as that means that no instance of that class exists at runtime.
    if (!direct_subclass.is_finalized()) {
      continue;
    }

    if (direct_subclass.LookupDynamicFunctionUnsafe(function_name) !=
        Function::null()) {
      return true;
    }

    if (HasOverride(direct_subclass, function_name, subclasses_count)) {
      return true;
    }

    (*subclasses_count)++;
  }

  return false;
}

void CHA::RegisterDependencies(const Code& code) const {
  for (intptr_t i = 0; i < guarded_classes_.length(); ++i) {
    guarded_classes_[i].cls->RegisterCHACode(code);
  }
}

}  // namespace dart
