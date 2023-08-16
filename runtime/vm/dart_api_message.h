// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_DART_API_MESSAGE_H_
#define RUNTIME_VM_DART_API_MESSAGE_H_

#include "include/dart_native_api.h"
#include "platform/utils.h"
#include "vm/allocation.h"
#include "vm/dart_api_state.h"
#include "vm/message.h"
#include "vm/raw_object.h"
#include "vm/snapshot.h"

namespace dart {

// This class handles translation of certain ObjectPtrs to CObjects for
// NativeMessageHandlers.
//
// TODO(zra): Expand to support not only null, but also other VM heap objects
// as well.
class ApiObjectConverter : public AllStatic {
 public:
  static bool CanConvert(const ObjectPtr raw_obj) {
    return !raw_obj->IsHeapObject() || (raw_obj == Object::null());
  }

  static bool Convert(const ObjectPtr raw_obj, Dart_CObject* c_obj) {
    if (!raw_obj->IsHeapObject()) {
      ConvertSmi(static_cast<const SmiPtr>(raw_obj), c_obj);
    } else if (raw_obj == Object::null()) {
      ConvertNull(c_obj);
    } else {
      return false;
    }
    return true;
  }

 private:
  static void ConvertSmi(const SmiPtr raw_smi, Dart_CObject* c_obj) {
    ASSERT(!raw_smi->IsHeapObject());
    intptr_t value = Smi::Value(raw_smi);
    if (Utils::IsInt(31, value)) {
      c_obj->type = Dart_CObject_kInt32;
      c_obj->value.as_int32 = static_cast<int32_t>(value);
    } else {
      c_obj->type = Dart_CObject_kInt64;
      c_obj->value.as_int64 = static_cast<int64_t>(value);
    }
  }

  static void ConvertNull(Dart_CObject* c_obj) {
    c_obj->type = Dart_CObject_kNull;
    c_obj->value.as_int64 = 0;
  }
};

}  // namespace dart

#endif  // RUNTIME_VM_DART_API_MESSAGE_H_
