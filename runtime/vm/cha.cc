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

bool CHA::HasSubclasses(intptr_t cid) {
  const ClassTable& class_table = *Isolate::Current()->class_table();
  const Class& cls = Class::Handle(class_table.At(cid));
  ASSERT(!cls.IsNull());
  // TODO(regis): Add ASSERT(cid > kDartObjectCid).
  if (cls.IsObjectClass()) {
    // Class Object has subclasses, although we do not keep track of them.
    return true;
  }
  const GrowableObjectArray& cls_direct_subclasses =
      GrowableObjectArray::Handle(cls.direct_subclasses());
  return
      !cls_direct_subclasses.IsNull() && (cls_direct_subclasses.Length() > 0);
}


// Returns true if the given array of cids contains the given cid.
static bool ContainsCid(ZoneGrowableArray<intptr_t>* cids, intptr_t cid) {
  for (intptr_t i = 0; i < cids->length(); i++) {
    if ((*cids)[i] == cid) {
      return true;
    }
  }
  return false;
}


// Recursively collect direct and indirect subclass ids of cls.
static void CollectSubclassIds(ZoneGrowableArray<intptr_t>* cids,
                               const Class& cls) {
  const GrowableObjectArray& cls_direct_subclasses =
      GrowableObjectArray::Handle(cls.direct_subclasses());
  if (cls_direct_subclasses.IsNull()) {
    return;
  }
  Class& direct_subclass = Class::Handle();
  for (intptr_t i = 0; i < cls_direct_subclasses.Length(); i++) {
    direct_subclass ^= cls_direct_subclasses.At(i);
    intptr_t direct_subclass_id = direct_subclass.id();
    if (!ContainsCid(cids, direct_subclass_id)) {
      cids->Add(direct_subclass_id);
      CollectSubclassIds(cids, direct_subclass);
    }
  }
}


ZoneGrowableArray<intptr_t>* CHA::GetSubclassIdsOf(intptr_t cid) {
  const ClassTable& class_table = *Isolate::Current()->class_table();
  const Class& cls = Class::Handle(class_table.At(cid));
  ASSERT(!cls.IsNull());
  // TODO(regis): Replace assert below with ASSERT(cid > kDartObjectCid).
  ASSERT(!cls.IsObjectClass());
  ZoneGrowableArray<intptr_t>* ids = new ZoneGrowableArray<intptr_t>();
  CollectSubclassIds(ids, cls);
  return ids;
}


ZoneGrowableArray<Function*>* CHA::GetNamedInstanceFunctionsOf(
    const ZoneGrowableArray<intptr_t>& cids,
    const String& function_name) {
  ASSERT(!function_name.IsNull());
  const ClassTable& class_table = *Isolate::Current()->class_table();
  ZoneGrowableArray<Function*>* functions = new ZoneGrowableArray<Function*>();
  Class& cls = Class::Handle();
  Function& cls_function = Function::Handle();
  for (intptr_t i = 0; i < cids.length(); i++) {
    const intptr_t cid = cids[i];
    cls = class_table.At(cid);
    // TODO(regis): Replace assert below with ASSERT(cid > kDartObjectCid).
    ASSERT(!cls.IsObjectClass());
    cls_function = cls.LookupDynamicFunction(function_name);
    if (!cls_function.IsNull()) {
      functions->Add(&Function::ZoneHandle(cls_function.raw()));
    }
  }
  return functions;
}


ZoneGrowableArray<Function*>* CHA::GetOverridesOf(const Function& function) {
  ASSERT(!function.IsNull());
  ASSERT(function.IsDynamicFunction());
  const Class& function_owner = Class::Handle(function.Owner());
  const String& function_name = String::Handle(function.name());
  ZoneGrowableArray<intptr_t>* cids = new ZoneGrowableArray<intptr_t>();
  CollectSubclassIds(cids, function_owner);
  return GetNamedInstanceFunctionsOf(*cids, function_name);
}

}  // namespace dart
