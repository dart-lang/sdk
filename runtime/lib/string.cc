// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"

#include "vm/exceptions.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/symbols.h"
#include "vm/unicode.h"

namespace dart {

DEFINE_NATIVE_ENTRY(StringBase_createFromCodePoints, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, list, arguments->NativeArgAt(0));
  if (!list.IsGrowableObjectArray() && !list.IsArray()) {
    const Array& args = Array::Handle(Array::New(1));
    args.SetAt(0, list);
    Exceptions::ThrowByType(Exceptions::kArgument, args);
  }
  // TODO(srdjan): Check that parameterized type is an int.

  Array& a = Array::Handle();
  intptr_t array_len;
  if (list.IsGrowableObjectArray()) {
    const GrowableObjectArray& growableArray = GrowableObjectArray::Cast(list);
    a ^= growableArray.data();
    array_len = growableArray.Length();
  } else {
    a ^= Array::Cast(list).raw();
    array_len = a.Length();
  }

  Zone* zone = isolate->current_zone();

  // Unbox the array and determine the maximum element width.
  bool is_one_byte_string = true;
  intptr_t utf16_len = array_len;
  int32_t* utf32_array = zone->Alloc<int32_t>(array_len);
  Object& index_object = Object::Handle(isolate);
  for (intptr_t i = 0; i < array_len; i++) {
    index_object = a.At(i);
    if (!index_object.IsSmi()) {
      const Array& args = Array::Handle(Array::New(1));
      args.SetAt(0, index_object);
      Exceptions::ThrowByType(Exceptions::kArgument, args);
    }
    intptr_t value = Smi::Cast(index_object).Value();
    if (Utf::IsOutOfRange(value)) {
      Exceptions::ThrowByType(Exceptions::kArgument, Object::empty_array());
    } else {
      if (!Utf::IsLatin1(value)) {
        is_one_byte_string = false;
        if (Utf::IsSupplementary(value)) {
          utf16_len += 1;
        }
      }
    }
    utf32_array[i] = value;
  }
  if (is_one_byte_string) {
    return OneByteString::New(utf32_array, array_len, Heap::kNew);
  }
  return TwoByteString::New(utf16_len, utf32_array, array_len, Heap::kNew);
}


DEFINE_NATIVE_ENTRY(StringBase_substringUnchecked, 3) {
  const String& receiver = String::CheckedHandle(arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, start_obj, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, end_obj, arguments->NativeArgAt(2));

  intptr_t start = start_obj.Value();
  intptr_t end = end_obj.Value();
  return String::SubString(receiver, start, (end - start));
}


DEFINE_NATIVE_ENTRY(OneByteString_substringUnchecked, 3) {
  const String& receiver = String::CheckedHandle(arguments->NativeArgAt(0));
  ASSERT(receiver.IsOneByteString());
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, start_obj, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, end_obj, arguments->NativeArgAt(2));

  const intptr_t start = start_obj.Value();
  const intptr_t end = end_obj.Value();
  return OneByteString::New(receiver, start, end - start, Heap::kNew);
}


// This is high-performance code.
DEFINE_NATIVE_ENTRY(OneByteString_splitWithCharCode, 2) {
  const String& receiver = String::CheckedHandle(isolate,
                                                 arguments->NativeArgAt(0));
  ASSERT(receiver.IsOneByteString());
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, smi_split_code, arguments->NativeArgAt(1));
  const intptr_t len = receiver.Length();
  const intptr_t split_code = smi_split_code.Value();
  const GrowableObjectArray& result = GrowableObjectArray::Handle(
      isolate,
      GrowableObjectArray::New(16, Heap::kNew));
  String& str = String::Handle(isolate);
  intptr_t start = 0;
  intptr_t i = 0;
  for (; i < len; i++) {
    if (split_code == OneByteString::CharAt(receiver, i)) {
      str = OneByteString::SubStringUnchecked(receiver,
                                              start,
                                              (i - start),
                                              Heap::kNew);
      result.Add(str);
      start = i + 1;
    }
  }
  str = OneByteString::SubStringUnchecked(receiver,
                                          start,
                                          (i - start),
                                          Heap::kNew);
  result.Add(str);
  return result.raw();
}


DEFINE_NATIVE_ENTRY(String_getHashCode, 1) {
  const String& receiver = String::CheckedHandle(arguments->NativeArgAt(0));
  intptr_t hash_val = receiver.Hash();
  ASSERT(hash_val > 0);
  ASSERT(Smi::IsValid(hash_val));
  return Smi::New(hash_val);
}


DEFINE_NATIVE_ENTRY(String_getLength, 1) {
  const String& receiver = String::CheckedHandle(arguments->NativeArgAt(0));
  return Smi::New(receiver.Length());
}


static int32_t StringValueAt(const String& str, const Integer& index) {
  if (index.IsSmi()) {
    const Smi& smi = Smi::Cast(index);
    int32_t index = smi.Value();
    if ((index < 0) || (index >= str.Length())) {
      const Array& args = Array::Handle(Array::New(1));
      args.SetAt(0, smi);
      Exceptions::ThrowByType(Exceptions::kRange, args);
    }
    return str.CharAt(index);
  } else {
    // An index larger than Smi is always illegal.
    const Array& args = Array::Handle(Array::New(1));
    args.SetAt(0, index);
    Exceptions::ThrowByType(Exceptions::kRange, args);
    return 0;
  }
}


DEFINE_NATIVE_ENTRY(String_charAt, 2) {
  const String& receiver = String::CheckedHandle(arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, index, arguments->NativeArgAt(1));
  uint32_t value = StringValueAt(receiver, index);
  ASSERT(value <= 0x10FFFF);
  return Symbols::FromCharCode(value);
}

DEFINE_NATIVE_ENTRY(String_codeUnitAt, 2) {
  const String& receiver = String::CheckedHandle(arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, index, arguments->NativeArgAt(1));

  int32_t value = StringValueAt(receiver, index);
  ASSERT(value >= 0);
  ASSERT(value <= 0xFFFF);
  return Smi::New(value);
}


DEFINE_NATIVE_ENTRY(String_concat, 2) {
  const String& receiver = String::CheckedHandle(arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(String, b, arguments->NativeArgAt(1));
  return String::Concat(receiver, b);
}


DEFINE_NATIVE_ENTRY(String_toLowerCase, 1) {
  const String& receiver = String::CheckedHandle(arguments->NativeArgAt(0));
  ASSERT(!receiver.IsNull());
  return String::ToLowerCase(receiver);
}


DEFINE_NATIVE_ENTRY(String_toUpperCase, 1) {
  const String& receiver = String::CheckedHandle(arguments->NativeArgAt(0));
  ASSERT(!receiver.IsNull());
  return String::ToUpperCase(receiver);
}


DEFINE_NATIVE_ENTRY(Strings_concatAll, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Array, strings, arguments->NativeArgAt(0));
  ASSERT(!strings.IsNull());
  // Check that the array contains strings.
  Instance& elem = Instance::Handle();
  for (intptr_t i = 0; i < strings.Length(); i++) {
    elem ^= strings.At(i);
    if (!elem.IsString()) {
      const Array& args = Array::Handle(Array::New(1));
      args.SetAt(0, elem);
      Exceptions::ThrowByType(Exceptions::kArgument, args);
    }
  }
  return String::ConcatAll(strings);
}


DEFINE_NATIVE_ENTRY(StringBuffer_createStringFromUint16Array, 3) {
  GET_NON_NULL_NATIVE_ARGUMENT(TypedData, codeUnits, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, length, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Bool, isLatin1, arguments->NativeArgAt(2));
  intptr_t array_length = codeUnits.Length();
  intptr_t length_value = length.Value();
  if (length_value < 0 || length_value > array_length) {
    const Array& args = Array::Handle(Array::New(1));
    args.SetAt(0, length);
    Exceptions::ThrowByType(Exceptions::kRange, args);
  }
  const String& result = isLatin1.value()
      ? String::Handle(OneByteString::New(length_value, Heap::kNew))
      : String::Handle(TwoByteString::New(length_value, Heap::kNew));
  NoGCScope no_gc;

  uint16_t* data_position = reinterpret_cast<uint16_t*>(codeUnits.DataAddr(0));
  String::Copy(result, 0, data_position, length_value);
  return result.raw();
}

}  // namespace dart
