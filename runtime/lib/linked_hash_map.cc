// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"

#include "vm/bootstrap_natives.h"
#include "vm/exceptions.h"
#include "vm/flags.h"
#include "vm/native_entry.h"
#include "vm/object.h"

namespace dart {

DEFINE_NATIVE_ENTRY(LinkedHashMap_getIndex, 1) {
  const LinkedHashMap& map =
      LinkedHashMap::CheckedHandle(arguments->NativeArgAt(0));
  return map.index();
}

DEFINE_NATIVE_ENTRY(LinkedHashMap_setIndex, 2) {
  const LinkedHashMap& map =
      LinkedHashMap::CheckedHandle(arguments->NativeArgAt(0));
  const TypedData& index = TypedData::CheckedHandle(arguments->NativeArgAt(1));
  map.SetIndex(index);
  return Object::null();
}

DEFINE_NATIVE_ENTRY(LinkedHashMap_getData, 1) {
  const LinkedHashMap& map =
      LinkedHashMap::CheckedHandle(arguments->NativeArgAt(0));
  return map.data();
}

DEFINE_NATIVE_ENTRY(LinkedHashMap_setData, 2) {
  const LinkedHashMap& map =
      LinkedHashMap::CheckedHandle(arguments->NativeArgAt(0));
  const Array& data = Array::CheckedHandle(arguments->NativeArgAt(1));
  map.SetData(data);
  return Object::null();
}

DEFINE_NATIVE_ENTRY(LinkedHashMap_getHashMask, 1) {
  const LinkedHashMap& map =
      LinkedHashMap::CheckedHandle(arguments->NativeArgAt(0));
  return map.hash_mask();
}

DEFINE_NATIVE_ENTRY(LinkedHashMap_setHashMask, 2) {
  const LinkedHashMap& map =
      LinkedHashMap::CheckedHandle(arguments->NativeArgAt(0));
  const Smi& hashMask = Smi::CheckedHandle(arguments->NativeArgAt(1));
  map.SetHashMask(hashMask.Value());
  return Object::null();
}

DEFINE_NATIVE_ENTRY(LinkedHashMap_getDeletedKeys, 1) {
  const LinkedHashMap& map =
      LinkedHashMap::CheckedHandle(arguments->NativeArgAt(0));
  return map.deleted_keys();
}

DEFINE_NATIVE_ENTRY(LinkedHashMap_setDeletedKeys, 2) {
  const LinkedHashMap& map =
      LinkedHashMap::CheckedHandle(arguments->NativeArgAt(0));
  const Smi& deletedKeys = Smi::CheckedHandle(arguments->NativeArgAt(1));
  map.SetDeletedKeys(deletedKeys.Value());
  return Object::null();
}

DEFINE_NATIVE_ENTRY(LinkedHashMap_getUsedData, 1) {
  const LinkedHashMap& map =
      LinkedHashMap::CheckedHandle(arguments->NativeArgAt(0));
  return map.used_data();
}

DEFINE_NATIVE_ENTRY(LinkedHashMap_setUsedData, 2) {
  const LinkedHashMap& map =
      LinkedHashMap::CheckedHandle(arguments->NativeArgAt(0));
  const Smi& usedData = Smi::CheckedHandle(arguments->NativeArgAt(1));
  map.SetUsedData(usedData.Value());
  return Object::null();
}

}  // namespace dart
