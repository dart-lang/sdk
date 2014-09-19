// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"

#include "include/dart_api.h"
#include "vm/exceptions.h"
#include "vm/dart_api_impl.h"
#include "vm/isolate.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/symbols.h"
#include "vm/unicode.h"

namespace dart {

DEFINE_NATIVE_ENTRY(String_fromEnvironment, 3) {
  GET_NON_NULL_NATIVE_ARGUMENT(String, name, arguments->NativeArgAt(1));
  GET_NATIVE_ARGUMENT(String, default_value, arguments->NativeArgAt(2));
  // Call the embedder to supply us with the environment.
  const String& env_value =
      String::Handle(Api::CallEnvironmentCallback(isolate, name));
  if (!env_value.IsNull()) {
    return Symbols::New(env_value);
  }
  return default_value.raw();
}


DEFINE_NATIVE_ENTRY(StringBase_createFromCodePoints, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, list, arguments->NativeArgAt(0));
  if (!list.IsGrowableObjectArray() && !list.IsArray()) {
    Exceptions::ThrowArgumentError(list);
  }

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
  Instance& index_object = Instance::Handle(isolate);
  for (intptr_t i = 0; i < array_len; i++) {
    index_object ^= a.At(i);
    if (!index_object.IsSmi()) {
      Exceptions::ThrowArgumentError(index_object);
    }
    intptr_t value = Smi::Cast(index_object).Value();
    if (Utf::IsOutOfRange(value)) {
      Exceptions::ThrowByType(Exceptions::kArgument, Object::empty_array());
      UNREACHABLE();
    }
    // Now it is safe to cast the value.
    int32_t value32 = static_cast<int32_t>(value);
    if (!Utf::IsLatin1(value32)) {
      is_one_byte_string = false;
      if (Utf::IsSupplementary(value32)) {
        utf16_len += 1;
      }
    }
    utf32_array[i] = value32;
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


DEFINE_NATIVE_ENTRY(OneByteString_allocate, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, length_obj, arguments->NativeArgAt(0));
  Heap::Space space = isolate->heap()->SpaceForAllocation(kOneByteStringCid);
  return OneByteString::New(length_obj.Value(), space);
}


DEFINE_NATIVE_ENTRY(OneByteString_allocateFromOneByteList, 1) {
  Instance& list = Instance::CheckedHandle(arguments->NativeArgAt(0));
  Heap::Space space = isolate->heap()->SpaceForAllocation(kOneByteStringCid);
  if (list.IsTypedData()) {
    const TypedData& array = TypedData::Cast(list);
    intptr_t length = array.LengthInBytes();
    return OneByteString::New(array, 0, length, space);
  } else if (list.IsExternalTypedData()) {
    const ExternalTypedData& array = ExternalTypedData::Cast(list);
    intptr_t length = array.LengthInBytes();
    return OneByteString::New(array, 0, length, space);
  } else if (RawObject::IsTypedDataViewClassId(list.GetClassId())) {
    const Instance& view = Instance::Cast(list);
    intptr_t length = Smi::Value(TypedDataView::Length(view));
    const Instance& data_obj = Instance::Handle(TypedDataView::Data(view));
    intptr_t data_offset = Smi::Value(TypedDataView::OffsetInBytes(view));
    if (data_obj.IsTypedData()) {
      const TypedData& array = TypedData::Cast(data_obj);
      return OneByteString::New(array, data_offset, length, space);
    } else if (data_obj.IsExternalTypedData()) {
      const ExternalTypedData& array = ExternalTypedData::Cast(data_obj);
      return OneByteString::New(array, data_offset, length, space);
    }
  } else if (list.IsArray()) {
    const Array& array = Array::Cast(list);
    intptr_t length = array.Length();
    String& string = String::Handle(OneByteString::New(length, space));
    for (int i = 0; i < length; i++) {
      intptr_t value = Smi::Value(reinterpret_cast<RawSmi*>(array.At(i)));
      OneByteString::SetCharAt(string, i, value);
    }
    return string.raw();
  } else if (list.IsGrowableObjectArray()) {
    const GrowableObjectArray& array = GrowableObjectArray::Cast(list);
    intptr_t length = array.Length();
    String& string = String::Handle(OneByteString::New(length, space));
    for (int i = 0; i < length; i++) {
      intptr_t value = Smi::Value(reinterpret_cast<RawSmi*>(array.At(i)));
      OneByteString::SetCharAt(string, i, value);
    }
    return string.raw();
  }
  UNREACHABLE();
  return Object::null();
}


DEFINE_NATIVE_ENTRY(OneByteString_setAt, 3) {
  GET_NON_NULL_NATIVE_ARGUMENT(String, receiver, arguments->NativeArgAt(0));
  ASSERT(receiver.IsOneByteString());
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, index_obj, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, code_point_obj, arguments->NativeArgAt(2));
  ASSERT((0 <= code_point_obj.Value()) && (code_point_obj.Value() <= 0xFF));
  OneByteString::SetCharAt(receiver, index_obj.Value(), code_point_obj.Value());
  return Object::null();
}


DEFINE_NATIVE_ENTRY(ExternalOneByteString_getCid, 0) {
  return Smi::New(kExternalOneByteStringCid);
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


static uint16_t StringValueAt(const String& str, const Integer& index) {
  if (index.IsSmi()) {
    const intptr_t index_value = Smi::Cast(index).Value();
    if ((0 <= index_value) && (index_value < str.Length())) {
      return str.CharAt(index_value);
    }
  }

  // An index larger than Smi is always illegal.
  Exceptions::ThrowRangeError("index", index, 0, str.Length());
  return 0;
}


DEFINE_NATIVE_ENTRY(String_charAt, 2) {
  const String& receiver = String::CheckedHandle(arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, index, arguments->NativeArgAt(1));
  uint16_t value = StringValueAt(receiver, index);
  return Symbols::FromCharCode(static_cast<int32_t>(value));
}


// Returns the 16-bit UTF-16 code unit at the given index.
DEFINE_NATIVE_ENTRY(String_codeUnitAt, 2) {
  const String& receiver = String::CheckedHandle(arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, index, arguments->NativeArgAt(1));
  uint16_t value = StringValueAt(receiver, index);
  return Smi::New(static_cast<intptr_t>(value));
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


DEFINE_NATIVE_ENTRY(String_concatRange, 3) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, argument, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, start, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, end, arguments->NativeArgAt(2));
  const intptr_t start_ix = start.Value();
  const intptr_t end_ix = end.Value();
  if (start_ix < 0) {
    Exceptions::ThrowArgumentError(start);
  }
  Array& strings = Array::Handle();
  intptr_t length = -1;
  if (argument.IsArray()) {
    strings ^= argument.raw();
    length = strings.Length();
  } else if (argument.IsGrowableObjectArray()) {
    const GrowableObjectArray& g_array = GrowableObjectArray::Cast(argument);
    strings = g_array.data();
    length =  g_array.Length();
  } else {
    Exceptions::ThrowArgumentError(argument);
  }
  if (end_ix > length) {
    Exceptions::ThrowArgumentError(end);
  }
#if defined(DEBUG)
  // Check that the array contains strings.
  Instance& elem = Instance::Handle();
  for (intptr_t i = start_ix; i < end_ix; i++) {
    elem ^= strings.At(i);
    ASSERT(elem.IsString());
  }
#endif
  return String::ConcatAllRange(strings, start_ix, end_ix, Heap::kNew);
}


DEFINE_NATIVE_ENTRY(StringBuffer_createStringFromUint16Array, 3) {
  GET_NON_NULL_NATIVE_ARGUMENT(TypedData, codeUnits, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, length, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Bool, isLatin1, arguments->NativeArgAt(2));
  intptr_t array_length = codeUnits.Length();
  intptr_t length_value = length.Value();
  if (length_value < 0 || length_value > array_length) {
    Exceptions::ThrowRangeError("length", length, 0, array_length + 1);
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
