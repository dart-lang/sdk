// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"

#include "vm/exceptions.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/symbols.h"

namespace dart {

DEFINE_NATIVE_ENTRY(StringBase_createFromCodePoints, 1) {
  GET_NATIVE_ARGUMENT(Array, a, arguments->At(0));
  // TODO(srdjan): Check that parameterized type is an int.
  Zone* zone = isolate->current_zone();
  intptr_t len = a.Length();

  // Unbox the array and determine the maximum element width.
  bool is_one_byte_string = true;
  bool is_two_byte_string = true;
  uint32_t* temp = zone->Alloc<uint32_t>(len);
  Object& index_object = Object::Handle(isolate);
  for (intptr_t i = 0; i < len; i++) {
    index_object = a.At(i);
    if (!index_object.IsSmi()) {
      GrowableArray<const Object*> args;
      args.Add(&index_object);
      Exceptions::ThrowByType(Exceptions::kArgument, args);
    }
    intptr_t value = Smi::Cast(index_object).Value();
    if (value < 0) {
      GrowableArray<const Object*> args;
      Exceptions::ThrowByType(Exceptions::kArgument, args);
    } else if (value > 0xFFFF) {
      is_one_byte_string = false;
      is_two_byte_string = false;
    } else if (value > 0xFF) {
      is_one_byte_string = false;
    }
    temp[i] = value;
  }
  if (is_one_byte_string) {
    return OneByteString::New(temp, len, Heap::kNew);
  } else if (is_two_byte_string) {
    return TwoByteString::New(temp, len, Heap::kNew);
  } else {
    return FourByteString::New(temp, len, Heap::kNew);
  }
}


DEFINE_NATIVE_ENTRY(StringBase_substringUnchecked, 3) {
  GET_NATIVE_ARGUMENT(String, receiver, arguments->At(0));
  GET_NATIVE_ARGUMENT(Smi, start_obj, arguments->At(1));
  GET_NATIVE_ARGUMENT(Smi, end_obj, arguments->At(2));

  intptr_t start = start_obj.Value();
  intptr_t end = end_obj.Value();
  return String::SubString(receiver, start, (end - start));
}


DEFINE_NATIVE_ENTRY(String_getHashCode, 1) {
  const String& receiver = String::CheckedHandle(arguments->At(0));
  intptr_t hash_val = receiver.Hash();
  ASSERT(hash_val > 0);
  ASSERT(Smi::IsValid(hash_val));
  return Smi::New(hash_val);
}


DEFINE_NATIVE_ENTRY(String_getLength, 1) {
  const String& receiver = String::CheckedHandle(arguments->At(0));
  return Smi::New(receiver.Length());
}


static int32_t StringValueAt(const String& str, const Integer& index) {
  if (index.IsSmi()) {
    Smi& smi = Smi::Handle();
    smi ^= index.raw();
    int32_t index = smi.Value();
    if ((index < 0) || (index >= str.Length())) {
      GrowableArray<const Object*> arguments;
      arguments.Add(&smi);
      Exceptions::ThrowByType(Exceptions::kIndexOutOfRange, arguments);
    }
    return str.CharAt(index);
  } else {
    // An index larger than Smi is always illegal.
    GrowableArray<const Object*> arguments;
    arguments.Add(&index);
    Exceptions::ThrowByType(Exceptions::kIndexOutOfRange, arguments);
    return 0;
  }
}


DEFINE_NATIVE_ENTRY(String_charAt, 2) {
  const String& receiver = String::CheckedHandle(arguments->At(0));
  GET_NATIVE_ARGUMENT(Integer, index, arguments->At(1));
  uint32_t value = StringValueAt(receiver, index);
  ASSERT(value <= 0x10FFFF);
  return Symbols::New(&value, 1);
}

DEFINE_NATIVE_ENTRY(String_charCodeAt, 2) {
  const String& receiver = String::CheckedHandle(arguments->At(0));
  GET_NATIVE_ARGUMENT(Integer, index, arguments->At(1));
  int32_t value = StringValueAt(receiver, index);
  ASSERT(value >= 0);
  ASSERT(value <= 0x10FFFF);
  return Smi::New(value);
}


DEFINE_NATIVE_ENTRY(String_concat, 2) {
  const String& receiver = String::CheckedHandle(arguments->At(0));
  GET_NATIVE_ARGUMENT(String, b, arguments->At(1));
  return String::Concat(receiver, b);
}


DEFINE_NATIVE_ENTRY(String_toLowerCase, 1) {
  const String& receiver = String::CheckedHandle(arguments->At(0));
  ASSERT(!receiver.IsNull());
  return String::ToLowerCase(receiver);
}


DEFINE_NATIVE_ENTRY(String_toUpperCase, 1) {
  const String& receiver = String::CheckedHandle(arguments->At(0));
  ASSERT(!receiver.IsNull());
  return String::ToUpperCase(receiver);
}


DEFINE_NATIVE_ENTRY(Strings_concatAll, 1) {
  GET_NATIVE_ARGUMENT(Array, strings, arguments->At(0));
  ASSERT(!strings.IsNull());
  // Check that the array contains strings.
  Instance& elem = Instance::Handle();
  for (intptr_t i = 0; i < strings.Length(); i++) {
    elem ^= strings.At(i);
    if (elem.IsNull()) {
      GrowableArray<const Object*> args;
      Exceptions::ThrowByType(Exceptions::kNullPointer, args);
    }
    if (!elem.IsString()) {
      GrowableArray<const Object*> args;
      args.Add(&elem);
      Exceptions::ThrowByType(Exceptions::kArgument, args);
    }
  }
  return String::ConcatAll(strings);
}

}  // namespace dart
