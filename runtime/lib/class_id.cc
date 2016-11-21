// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "vm/bootstrap_natives.h"

namespace dart {

DEFINE_NATIVE_ENTRY(ClassID_getID, 1) {
  const Instance& instance =
      Instance::CheckedHandle(zone, arguments->NativeArgAt(0));
  return Smi::New(instance.GetClassId());
}


DEFINE_NATIVE_ENTRY(ClassID_byName, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(String, name, arguments->NativeArgAt(0));

#define CLASS_LIST_WITH_NULL(V)                                                \
  V(Null)                                                                      \
  CLASS_LIST_NO_OBJECT(V)

#define COMPARE(clazz)                                                         \
  if (name.Equals(#clazz)) return Smi::New(k##clazz##Cid);

  CLASS_LIST_WITH_NULL(COMPARE)

#undef COMPARE
#undef CLASS_LIST_WITH_NULL

  UNREACHABLE();
  return Smi::New(-1);
}

}  // namespace dart
