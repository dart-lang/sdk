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

// Return true if the class is private to our internal libraries (not extendable
// or implementable after startup). Therefore, we don't need to register
// optimized code for invalidation for those classes.
// TODO(fschneider): Allow more libraries.
static bool IsKnownPrivateClass(const Class& type_class) {
  if (!Library::IsPrivate(String::Handle(type_class.Name()))) return false;
  const Library& library = Library::Handle(type_class.library());
  if (library.raw() == Library::CoreLibrary()) return true;
  if (library.raw() == Library::CollectionLibrary()) return true;
  if (library.raw() == Library::TypedDataLibrary()) return true;
  if (library.raw() == Library::MathLibrary()) return true;
  return false;
}


void CHA::AddToLeafClasses(const Class& cls) {
  if (IsKnownPrivateClass(cls)) return;

  for (intptr_t i = 0; i < leaf_classes_.length(); i++) {
    if (leaf_classes_[i]->raw() == cls.raw()) {
      return;
    }
  }
  leaf_classes_.Add(&Class::ZoneHandle(isolate_, cls.raw()));
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
      GrowableObjectArray::Handle(isolate_, cls.direct_subclasses());
  bool result =
      !direct_subclasses.IsNull() && (direct_subclasses.Length() > 0);
  if (!result) {
    AddToLeafClasses(cls);
  }
  return result;
}


bool CHA::HasSubclasses(intptr_t cid) {
  const ClassTable& class_table = *isolate_->class_table();
  Class& cls = Class::Handle(isolate_, class_table.At(cid));
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

  bool result = cls.is_implemented();
  if (!result) {
    AddToLeafClasses(cls);
  }
  return result;
}


bool CHA::HasOverride(const Class& cls, const String& function_name) {
  const GrowableObjectArray& cls_direct_subclasses =
      GrowableObjectArray::Handle(isolate_, cls.direct_subclasses());
  // Subclasses of Object are not tracked by CHA. Safely assume that overrides
  // exist.
  if (cls.IsObjectClass()) {
    return true;
  }

  if (cls_direct_subclasses.IsNull()) {
    AddToLeafClasses(cls);
    return false;
  }
  Class& direct_subclass = Class::Handle(isolate_);
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
  AddToLeafClasses(cls);
  return false;
}

}  // namespace dart
