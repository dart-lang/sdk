// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"

#include "include/dart_api.h"

#include "vm/bigint_operations.h"
#include "vm/exceptions.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/object_store.h"

namespace dart {

DECLARE_FLAG(bool, trace_intrinsified_natives);

// dart:profiler.

DEFINE_NATIVE_ENTRY(UserTag_new, 2) {
  ASSERT(TypeArguments::CheckedHandle(arguments->NativeArgAt(0)).IsNull());
  GET_NON_NULL_NATIVE_ARGUMENT(String, tag_label, arguments->NativeArgAt(1));
  return UserTag::New(tag_label);
}


DEFINE_NATIVE_ENTRY(UserTag_label, 1) {
  const UserTag& self = UserTag::CheckedHandle(arguments->NativeArgAt(0));
  return self.label();
}


DEFINE_NATIVE_ENTRY(UserTag_makeCurrent, 1) {
  const UserTag& self = UserTag::CheckedHandle(arguments->NativeArgAt(0));
  if (FLAG_trace_intrinsified_natives) {
    OS::Print("UserTag_makeCurrent: %s\n", self.ToCString());
  }
  self.MakeActive();
  return Object::null();
}


DEFINE_NATIVE_ENTRY(Profiler_getCurrentTag, 0) {
  if (FLAG_trace_intrinsified_natives) {
    OS::Print("Profiler_getCurrentTag\n");
  }
  return isolate->current_tag();
}


DEFINE_NATIVE_ENTRY(Profiler_clearCurrentTag, 0) {
  // Use a NoGCScope to avoid creating a handle for the old current.
  NoGCScope no_gc;
  RawUserTag* old_current = isolate->current_tag();
  UserTag::ClearActive();
  if (FLAG_trace_intrinsified_natives) {
    OS::Print("Profiler_clearCurrentTag\n");
  }
  return old_current;
}

}  // namespace dart
