// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/cha.h"
#include "vm/class_table.h"
#include "vm/flags.h"
#include "vm/freelist.h"
#include "vm/object.h"
#include "vm/raw_object.h"
#include "vm/visitor.h"

namespace dart {

void CHA::AddToLeafClasses(const Class& cls) {
  for (intptr_t i = 0; i < leaf_classes_.length(); i++) {
    if (leaf_classes_[i]->raw() == cls.raw()) {
      return;
    }
  }
  leaf_classes_.Add(&Class::ZoneHandle(thread_->zone(), cls.raw()));
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


bool CHA::IsImplemented(const Class& cls) {
  // Signature classes have different type checking rules.
  ASSERT(!cls.IsSignatureClass());
  // Can't track dependencies for classes on the VM heap since those are
  // read-only.
  // TODO(fschneider): Enable tracking of CHA dependent code for VM heap
  // classes.
  if (cls.InVMHeap()) return true;

  return cls.is_implemented();
}


bool CHA::HasOverride(const Class& cls, const String& function_name) {
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
    if (direct_subclass.is_finalized() &&
        (direct_subclass.LookupDynamicFunction(function_name) !=
         Function::null())) {
      return true;
    }
    if (HasOverride(direct_subclass, function_name)) {
      return true;
    }
  }
  return false;
}

}  // namespace dart
