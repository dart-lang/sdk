// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"

#include "vm/assembler.h"
#include "vm/bootstrap_natives.h"
#include "vm/exceptions.h"
#include "vm/flags.h"
#include "vm/native_entry.h"
#include "vm/object.h"

namespace dart {

DEFINE_FLAG(bool, use_internal_hash_map, false, "Use internal hash map.");

DEFINE_NATIVE_ENTRY(LinkedHashMap_allocate, 1) {
  const TypeArguments& type_arguments =
      TypeArguments::CheckedHandle(arguments->NativeArgAt(0));
  const LinkedHashMap& map =
    LinkedHashMap::Handle(LinkedHashMap::New());
  map.SetTypeArguments(type_arguments);
  return map.raw();
}


DEFINE_NATIVE_ENTRY(LinkedHashMap_getLength, 1) {
  const LinkedHashMap& map =
      LinkedHashMap::CheckedHandle(arguments->NativeArgAt(0));
  return Smi::New(map.Length());
}


DEFINE_NATIVE_ENTRY(LinkedHashMap_lookUp, 2) {
  const LinkedHashMap& map =
      LinkedHashMap::CheckedHandle(arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, key, arguments->NativeArgAt(1));
  return map.LookUp(key);
}


DEFINE_NATIVE_ENTRY(LinkedHashMap_containsKey, 2) {
  const LinkedHashMap& map =
      LinkedHashMap::CheckedHandle(arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, key, arguments->NativeArgAt(1));
  return Bool::Get(map.Contains(key)).raw();
}


DEFINE_NATIVE_ENTRY(LinkedHashMap_insertOrUpdate, 3) {
  LinkedHashMap& map =
      LinkedHashMap::CheckedHandle(arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, key, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, value, arguments->NativeArgAt(2));
  map.InsertOrUpdate(key, value);
  return Object::null();
}


DEFINE_NATIVE_ENTRY(LinkedHashMap_remove, 2) {
  const LinkedHashMap& map =
      LinkedHashMap::CheckedHandle(arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, key, arguments->NativeArgAt(1));
  return map.Remove(key);
}


DEFINE_NATIVE_ENTRY(LinkedHashMap_clear, 1) {
  const LinkedHashMap& map =
      LinkedHashMap::CheckedHandle(arguments->NativeArgAt(0));
  map.Clear();
  return Object::null();
}


DEFINE_NATIVE_ENTRY(LinkedHashMap_toArray, 1) {
  const LinkedHashMap& map =
      LinkedHashMap::CheckedHandle(arguments->NativeArgAt(0));
  return map.ToArray();
}


DEFINE_NATIVE_ENTRY(LinkedHashMap_getModMark, 2) {
  const LinkedHashMap& map =
      LinkedHashMap::CheckedHandle(arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Bool, create, arguments->NativeArgAt(1));
  return map.GetModificationMark(create.value());
}


DEFINE_NATIVE_ENTRY(LinkedHashMap_useInternal, 0) {
  return Bool::Get(FLAG_use_internal_hash_map).raw();
}

}  // namespace dart
