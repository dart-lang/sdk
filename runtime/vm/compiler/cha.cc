// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/compiler/cha.h"
#include "vm/class_table.h"
#include "vm/flags.h"
#include "vm/freelist.h"
#include "vm/object.h"
#include "vm/raw_object.h"
#include "vm/visitor.h"

namespace dart {

void CHA::AddToGuardedClasses(const Class& cls, intptr_t subclass_count) {
  for (intptr_t i = 0; i < guarded_classes_.length(); i++) {
    if (guarded_classes_[i].cls->raw() == cls.raw()) {
      return;
    }
  }
  GuardedClassInfo info = {&Class::ZoneHandle(thread_->zone(), cls.raw()),
                           subclass_count};
  guarded_classes_.Add(info);
  return;
}

bool CHA::IsGuardedClass(intptr_t cid) const {
  for (intptr_t i = 0; i < guarded_classes_.length(); ++i) {
    if (guarded_classes_[i].cls->id() == cid) return true;
  }
  return false;
}

bool CHA::HasSubclasses(const Class& cls) {
  ASSERT(!cls.IsNull());
  ASSERT(cls.id() >= kInstanceCid);
  // Can't track dependencies for classes on the VM heap since those are
  // read-only.
  // TODO(fschneider): Enable tracking of CHA dependent code for VM heap
  // classes.
  if (cls.InVMHeap()) return true;

  if (cls.IsObjectClass()) {
    // Class Object has subclasses, although we do not keep track of them.
    return true;
  }
  const GrowableObjectArray& direct_subclasses =
      GrowableObjectArray::Handle(cls.direct_subclasses());
  return !direct_subclasses.IsNull() && (direct_subclasses.Length() > 0);
}

bool CHA::HasSubclasses(intptr_t cid) const {
  const ClassTable& class_table = *thread_->isolate()->class_table();
  Class& cls = Class::Handle(thread_->zone(), class_table.At(cid));
  return HasSubclasses(cls);
}

bool CHA::ConcreteSubclasses(const Class& cls,
                             GrowableArray<intptr_t>* class_ids) {
  if (cls.InVMHeap()) return false;
  if (cls.IsObjectClass()) return false;

  if (!cls.is_abstract()) {
    class_ids->Add(cls.id());
  }

  const GrowableObjectArray& direct_subclasses =
      GrowableObjectArray::Handle(cls.direct_subclasses());
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
  // Function type aliases have different type checking rules.
  ASSERT(!cls.IsTypedefClass());
  // Can't track dependencies for classes on the VM heap since those are
  // read-only.
  // TODO(fschneider): Enable tracking of CHA dependent code for VM heap
  // classes.
  if (cls.InVMHeap()) return true;

  return cls.is_implemented();
}

static intptr_t CountFinalizedSubclasses(Thread* thread, const Class& cls) {
  intptr_t count = 0;
  const GrowableObjectArray& cls_direct_subclasses =
      GrowableObjectArray::Handle(thread->zone(), cls.direct_subclasses());
  if (cls_direct_subclasses.IsNull()) return count;
  Class& direct_subclass = Class::Handle(thread->zone());
  for (intptr_t i = 0; i < cls_direct_subclasses.Length(); i++) {
    direct_subclass ^= cls_direct_subclasses.At(i);
    // Unfinalized classes are treated as non-existent for CHA purposes,
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
    const intptr_t subclass_count =
        CountFinalizedSubclasses(thread_, *guarded_classes_[i].cls);
    if (guarded_classes_[i].subclass_count != subclass_count) {
      return false;
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
  if (cls.InVMHeap()) return true;

  // Subclasses of Object are not tracked by CHA. Safely assume that overrides
  // exist.
  if (cls.IsObjectClass()) {
    return true;
  }

  const GrowableObjectArray& cls_direct_subclasses =
      GrowableObjectArray::Handle(thread_->zone(), cls.direct_subclasses());
  if (cls_direct_subclasses.IsNull()) {
    return false;
  }
  Class& direct_subclass = Class::Handle(thread_->zone());
  for (intptr_t i = 0; i < cls_direct_subclasses.Length(); i++) {
    direct_subclass ^= cls_direct_subclasses.At(i);
    // Unfinalized classes are treated as non-existent for CHA purposes,
    // as that means that no instance of that class exists at runtime.
    if (!direct_subclass.is_finalized()) {
      continue;
    }

    if (direct_subclass.LookupDynamicFunction(function_name) !=
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

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
