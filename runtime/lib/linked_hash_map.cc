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

DEFINE_NATIVE_ENTRY(LinkedHashMap_getIndex, 0, 1) {
  const LinkedHashMap& map =
      LinkedHashMap::CheckedHandle(zone, arguments->NativeArgAt(0));
  return map.index();
}

DEFINE_NATIVE_ENTRY(LinkedHashMap_setIndex, 0, 2) {
  const LinkedHashMap& map =
      LinkedHashMap::CheckedHandle(zone, arguments->NativeArgAt(0));
  const TypedData& index =
      TypedData::CheckedHandle(zone, arguments->NativeArgAt(1));
  map.SetIndex(index);
  return Object::null();
}

DEFINE_NATIVE_ENTRY(LinkedHashMap_getData, 0, 1) {
  const LinkedHashMap& map =
      LinkedHashMap::CheckedHandle(zone, arguments->NativeArgAt(0));
  return map.data();
}

DEFINE_NATIVE_ENTRY(LinkedHashMap_setData, 0, 2) {
  const LinkedHashMap& map =
      LinkedHashMap::CheckedHandle(zone, arguments->NativeArgAt(0));
  const Array& data = Array::CheckedHandle(zone, arguments->NativeArgAt(1));
  map.SetData(data);
  return Object::null();
}

DEFINE_NATIVE_ENTRY(LinkedHashMap_getHashMask, 0, 1) {
  const LinkedHashMap& map =
      LinkedHashMap::CheckedHandle(zone, arguments->NativeArgAt(0));
  return map.hash_mask();
}

DEFINE_NATIVE_ENTRY(LinkedHashMap_setHashMask, 0, 2) {
  const LinkedHashMap& map =
      LinkedHashMap::CheckedHandle(zone, arguments->NativeArgAt(0));
  const Smi& hashMask = Smi::CheckedHandle(zone, arguments->NativeArgAt(1));
  map.SetHashMask(hashMask.Value());
  return Object::null();
}

DEFINE_NATIVE_ENTRY(LinkedHashMap_getDeletedKeys, 0, 1) {
  const LinkedHashMap& map =
      LinkedHashMap::CheckedHandle(zone, arguments->NativeArgAt(0));
  return map.deleted_keys();
}

DEFINE_NATIVE_ENTRY(LinkedHashMap_setDeletedKeys, 0, 2) {
  const LinkedHashMap& map =
      LinkedHashMap::CheckedHandle(zone, arguments->NativeArgAt(0));
  const Smi& deletedKeys = Smi::CheckedHandle(zone, arguments->NativeArgAt(1));
  map.SetDeletedKeys(deletedKeys.Value());
  return Object::null();
}

DEFINE_NATIVE_ENTRY(LinkedHashMap_getUsedData, 0, 1) {
  const LinkedHashMap& map =
      LinkedHashMap::CheckedHandle(zone, arguments->NativeArgAt(0));
  return map.used_data();
}

DEFINE_NATIVE_ENTRY(LinkedHashMap_setUsedData, 0, 2) {
  const LinkedHashMap& map =
      LinkedHashMap::CheckedHandle(zone, arguments->NativeArgAt(0));
  const Smi& usedData = Smi::CheckedHandle(zone, arguments->NativeArgAt(1));
  map.SetUsedData(usedData.Value());
  return Object::null();
}

}  // namespace dart
