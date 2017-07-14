// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"

#include "include/dart_api.h"
#include "vm/dart_api_impl.h"
#include "vm/exceptions.h"
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
      String::Handle(Api::GetEnvironmentValue(thread, name));
  if (!env_value.IsNull()) {
    return Symbols::New(thread, env_value);
  }
  return default_value.raw();
}

DEFINE_NATIVE_ENTRY(StringBase_createFromCodePoints, 3) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, list, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, start_obj, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, end_obj, arguments->NativeArgAt(2));

  Array& a = Array::Handle();
  intptr_t length;
  if (list.IsGrowableObjectArray()) {
    const GrowableObjectArray& growableArray = GrowableObjectArray::Cast(list);
    a ^= growableArray.data();
    length = growableArray.Length();
  } else if (list.IsArray()) {
    a ^= Array::Cast(list).raw();
    length = a.Length();
  } else {
    Exceptions::ThrowArgumentError(list);
    return NULL;  // Unreachable.
  }

  intptr_t start = start_obj.Value();
  if ((start < 0) || (start > length)) {
    Exceptions::ThrowArgumentError(start_obj);
  }

  intptr_t end = end_obj.Value();
  if ((end < start) || (end > length)) {
    Exceptions::ThrowArgumentError(end_obj);
  }

  // Unbox the array and determine the maximum element width.
  bool is_one_byte_string = true;
  intptr_t array_len = end - start;
  intptr_t utf16_len = array_len;
  int32_t* utf32_array = zone->Alloc<int32_t>(array_len);
  Instance& index_object = Instance::Handle(zone);
  for (intptr_t i = 0; i < array_len; i++) {
    index_object ^= a.At(start + i);
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
  const String& receiver =
      String::CheckedHandle(zone, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, start_obj, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, end_obj, arguments->NativeArgAt(2));

  intptr_t start = start_obj.Value();
  intptr_t end = end_obj.Value();
  return String::SubString(receiver, start, (end - start));
}

// Return the bitwise-or of all characters in the slice from start to end.
static uint16_t CharacterLimit(const String& string,
                               intptr_t start,
                               intptr_t end) {
  ASSERT(string.IsTwoByteString() || string.IsExternalTwoByteString());
  // Maybe do loop unrolling, and handle two uint16_t in a single uint32_t
  // operation.
  NoSafepointScope no_safepoint;
  uint16_t result = 0;
  if (string.IsTwoByteString()) {
    for (intptr_t i = start; i < end; i++) {
      result |= TwoByteString::CharAt(string, i);
    }
  } else {
    for (intptr_t i = start; i < end; i++) {
      result |= ExternalTwoByteString::CharAt(string, i);
    }
  }
  return result;
}

static const intptr_t kLengthSize = 11;
static const intptr_t kLengthMask = (1 << kLengthSize) - 1;

static bool CheckSlicesOneByte(const String& base,
                               const Array& matches,
                               const int len) {
  Instance& object = Instance::Handle();
  // Check each slice for one-bytedness.
  for (intptr_t i = 0; i < len; i++) {
    object ^= matches.At(i);
    if (object.IsSmi()) {
      intptr_t slice_start = Smi::Cast(object).Value();
      intptr_t slice_end;
      if (slice_start < 0) {
        intptr_t bits = -slice_start;
        slice_start = bits >> kLengthSize;
        slice_end = slice_start + (bits & kLengthMask);
      } else {
        i++;
        if (i >= len) {
          // Bad format, handled later.
          return false;
        }
        object ^= matches.At(i);
        if (!object.IsSmi()) {
          // Bad format, handled later.
          return false;
        }
        slice_end = Smi::Cast(object).Value();
      }
      uint16_t char_limit = CharacterLimit(base, slice_start, slice_end);
      if (char_limit > 0xff) {
        return false;
      }
    }
  }
  return true;
}

DEFINE_NATIVE_ENTRY(StringBase_joinReplaceAllResult, 4) {
  const String& base = String::CheckedHandle(zone, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(GrowableObjectArray, matches_growable,
                               arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, length_obj, arguments->NativeArgAt(2));
  GET_NON_NULL_NATIVE_ARGUMENT(Bool, is_onebyte_obj, arguments->NativeArgAt(3));

  intptr_t len = matches_growable.Length();
  const Array& matches = Array::Handle(zone, matches_growable.data());

  const intptr_t length = length_obj.Value();
  if (length < 0) {
    Exceptions::ThrowArgumentError(length_obj);
  }

  // Start out assuming result is one-byte if replacements are.
  bool is_onebyte = is_onebyte_obj.value();
  if (is_onebyte) {
    // If any of the base string slices are not one-byte, the result will be
    // a two-byte string.
    if (!base.IsOneByteString() && !base.IsExternalOneByteString()) {
      is_onebyte = CheckSlicesOneByte(base, matches, len);
    }
  }

  const intptr_t base_length = base.Length();
  String& result = String::Handle(zone);
  if (is_onebyte) {
    result ^= OneByteString::New(length, Heap::kNew);
  } else {
    result ^= TwoByteString::New(length, Heap::kNew);
  }
  Instance& object = Instance::Handle(zone);
  intptr_t write_index = 0;
  for (intptr_t i = 0; i < len; i++) {
    object ^= matches.At(i);
    if (object.IsSmi()) {
      intptr_t slice_start = Smi::Cast(object).Value();
      intptr_t slice_length = -1;
      // Slices with limited ranges are stored in a single negative Smi.
      if (slice_start < 0) {
        intptr_t bits = -slice_start;
        slice_start = bits >> kLengthSize;
        slice_length = bits & kLengthMask;
      } else {
        i++;
        if (i < len) {  // Otherwise slice_length stays at -1.
          object ^= matches.At(i);
          if (object.IsSmi()) {
            intptr_t slice_end = Smi::Cast(object).Value();
            slice_length = slice_end - slice_start;
          }
        }
      }
      if (slice_length > 0) {
        if (0 <= slice_start && slice_start + slice_length <= base_length &&
            write_index + slice_length <= length) {
          String::Copy(result, write_index, base, slice_start, slice_length);
          write_index += slice_length;
          continue;
        }
      }
      // Either the slice_length was zero,
      // or the first smi was positive and not followed by another smi,
      // or the smis were not a valid slice of the base string,
      // or the slice was too large to fit in the result.
      // Something is wrong with the matches array!
      Exceptions::ThrowArgumentError(matches_growable);
    } else if (object.IsString()) {
      const String& replacement = String::Cast(object);
      intptr_t replacement_length = replacement.Length();
      if (write_index + replacement_length > length) {
        // Invalid input data, either in matches list or the total length.
        Exceptions::ThrowArgumentError(matches_growable);
      }
      String::Copy(result, write_index, replacement, 0, replacement_length);
      write_index += replacement_length;
    }
  }
  if (write_index < length) {
    Exceptions::ThrowArgumentError(matches_growable);
  }
  return result.raw();
}

DEFINE_NATIVE_ENTRY(OneByteString_substringUnchecked, 3) {
  const String& receiver =
      String::CheckedHandle(zone, arguments->NativeArgAt(0));
  ASSERT(receiver.IsOneByteString());
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, start_obj, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, end_obj, arguments->NativeArgAt(2));

  const intptr_t start = start_obj.Value();
  const intptr_t end = end_obj.Value();
  return OneByteString::New(receiver, start, end - start, Heap::kNew);
}

// This is high-performance code.
DEFINE_NATIVE_ENTRY(OneByteString_splitWithCharCode, 2) {
  const String& receiver =
      String::CheckedHandle(zone, arguments->NativeArgAt(0));
  ASSERT(receiver.IsOneByteString());
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, smi_split_code, arguments->NativeArgAt(1));
  const intptr_t len = receiver.Length();
  const intptr_t split_code = smi_split_code.Value();
  const GrowableObjectArray& result = GrowableObjectArray::Handle(
      zone, GrowableObjectArray::New(16, Heap::kNew));
  String& str = String::Handle(zone);
  intptr_t start = 0;
  intptr_t i = 0;
  for (; i < len; i++) {
    if (split_code == OneByteString::CharAt(receiver, i)) {
      str = OneByteString::SubStringUnchecked(receiver, start, (i - start),
                                              Heap::kNew);
      result.Add(str);
      start = i + 1;
    }
  }
  str = OneByteString::SubStringUnchecked(receiver, start, (i - start),
                                          Heap::kNew);
  result.Add(str);
  return result.raw();
}

DEFINE_NATIVE_ENTRY(OneByteString_allocate, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, length_obj, arguments->NativeArgAt(0));
  return OneByteString::New(length_obj.Value(), Heap::kNew);
}

DEFINE_NATIVE_ENTRY(OneByteString_allocateFromOneByteList, 3) {
  Instance& list = Instance::CheckedHandle(zone, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, start_obj, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, end_obj, arguments->NativeArgAt(2));

  intptr_t start = start_obj.Value();
  intptr_t end = end_obj.Value();
  if (start < 0) {
    const Array& args = Array::Handle(Array::New(1));
    args.SetAt(0, start_obj);
    Exceptions::ThrowByType(Exceptions::kArgument, args);
  }
  intptr_t length = end - start;
  if (length < 0) {
    const Array& args = Array::Handle(Array::New(1));
    args.SetAt(0, end_obj);
    Exceptions::ThrowByType(Exceptions::kArgument, args);
  }
  ASSERT(length >= 0);

  Heap::Space space = Heap::kNew;
  if (list.IsTypedData()) {
    const TypedData& array = TypedData::Cast(list);
    if (end > array.LengthInBytes()) {
      const Array& args = Array::Handle(Array::New(1));
      args.SetAt(0, end_obj);
      Exceptions::ThrowByType(Exceptions::kArgument, args);
    }
    return OneByteString::New(array, start, length, space);
  } else if (list.IsExternalTypedData()) {
    const ExternalTypedData& array = ExternalTypedData::Cast(list);
    if (end > array.LengthInBytes()) {
      const Array& args = Array::Handle(Array::New(1));
      args.SetAt(0, end_obj);
      Exceptions::ThrowByType(Exceptions::kArgument, args);
    }
    return OneByteString::New(array, start, length, space);
  } else if (RawObject::IsTypedDataViewClassId(list.GetClassId())) {
    const Instance& view = Instance::Cast(list);
    if (end > Smi::Value(TypedDataView::Length(view))) {
      const Array& args = Array::Handle(Array::New(1));
      args.SetAt(0, end_obj);
      Exceptions::ThrowByType(Exceptions::kArgument, args);
    }
    const Instance& data_obj = Instance::Handle(TypedDataView::Data(view));
    intptr_t data_offset = Smi::Value(TypedDataView::OffsetInBytes(view));
    if (data_obj.IsTypedData()) {
      const TypedData& array = TypedData::Cast(data_obj);
      return OneByteString::New(array, data_offset + start, length, space);
    } else if (data_obj.IsExternalTypedData()) {
      const ExternalTypedData& array = ExternalTypedData::Cast(data_obj);
      return OneByteString::New(array, data_offset + start, length, space);
    }
  } else if (list.IsArray()) {
    const Array& array = Array::Cast(list);
    if (end > array.Length()) {
      const Array& args = Array::Handle(Array::New(1));
      args.SetAt(0, end_obj);
      Exceptions::ThrowByType(Exceptions::kArgument, args);
    }
    String& string = String::Handle(OneByteString::New(length, space));
    for (int i = 0; i < length; i++) {
      intptr_t value =
          Smi::Value(reinterpret_cast<RawSmi*>(array.At(start + i)));
      OneByteString::SetCharAt(string, i, value);
    }
    return string.raw();
  } else if (list.IsGrowableObjectArray()) {
    const GrowableObjectArray& array = GrowableObjectArray::Cast(list);
    if (end > array.Length()) {
      const Array& args = Array::Handle(Array::New(1));
      args.SetAt(0, end_obj);
      Exceptions::ThrowByType(Exceptions::kArgument, args);
    }
    String& string = String::Handle(OneByteString::New(length, space));
    for (int i = 0; i < length; i++) {
      intptr_t value =
          Smi::Value(reinterpret_cast<RawSmi*>(array.At(start + i)));
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

DEFINE_NATIVE_ENTRY(TwoByteString_allocateFromTwoByteList, 3) {
  Instance& list = Instance::CheckedHandle(zone, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, start_obj, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, end_obj, arguments->NativeArgAt(2));

  intptr_t start = start_obj.Value();
  intptr_t end = end_obj.Value();
  if (start < 0) {
    Exceptions::ThrowArgumentError(start_obj);
  }
  intptr_t length = end - start;
  if (length < 0) {
    Exceptions::ThrowArgumentError(end_obj);
  }

  Heap::Space space = Heap::kNew;
  if (list.IsTypedData()) {
    const TypedData& array = TypedData::Cast(list);
    if (array.ElementType() != kUint16ArrayElement) {
      Exceptions::ThrowArgumentError(list);
    }
    if (end > array.Length()) {
      Exceptions::ThrowArgumentError(end_obj);
    }
    return TwoByteString::New(array, start * sizeof(uint16_t), length, space);
  } else if (list.IsExternalTypedData()) {
    const ExternalTypedData& array = ExternalTypedData::Cast(list);
    if (array.ElementType() != kUint16ArrayElement) {
      Exceptions::ThrowArgumentError(list);
    }
    if (end > array.Length()) {
      Exceptions::ThrowArgumentError(end_obj);
    }
    return TwoByteString::New(array, start * sizeof(uint16_t), length, space);
  } else if (RawObject::IsTypedDataViewClassId(list.GetClassId())) {
    const intptr_t cid = list.GetClassId();
    if (cid != kTypedDataUint16ArrayViewCid) {
      Exceptions::ThrowArgumentError(list);
    }
    if (end > Smi::Value(TypedDataView::Length(list))) {
      Exceptions::ThrowArgumentError(end_obj);
    }
    const Instance& data_obj =
        Instance::Handle(zone, TypedDataView::Data(list));
    intptr_t data_offset = Smi::Value(TypedDataView::OffsetInBytes(list));
    if (data_obj.IsTypedData()) {
      const TypedData& array = TypedData::Cast(data_obj);
      return TwoByteString::New(array, data_offset + start * sizeof(uint16_t),
                                length, space);
    } else if (data_obj.IsExternalTypedData()) {
      const ExternalTypedData& array = ExternalTypedData::Cast(data_obj);
      return TwoByteString::New(array, data_offset + start * sizeof(uint16_t),
                                length, space);
    }
  } else if (list.IsArray()) {
    const Array& array = Array::Cast(list);
    if (end > array.Length()) {
      Exceptions::ThrowArgumentError(end_obj);
    }
    const String& string =
        String::Handle(zone, TwoByteString::New(length, space));
    for (int i = 0; i < length; i++) {
      intptr_t value =
          Smi::Value(reinterpret_cast<RawSmi*>(array.At(start + i)));
      TwoByteString::SetCharAt(string, i, value);
    }
    return string.raw();
  } else if (list.IsGrowableObjectArray()) {
    const GrowableObjectArray& array = GrowableObjectArray::Cast(list);
    if (end > array.Length()) {
      Exceptions::ThrowArgumentError(end_obj);
    }
    const String& string =
        String::Handle(zone, TwoByteString::New(length, space));
    for (int i = 0; i < length; i++) {
      intptr_t value =
          Smi::Value(reinterpret_cast<RawSmi*>(array.At(start + i)));
      TwoByteString::SetCharAt(string, i, value);
    }
    return string.raw();
  }
  UNREACHABLE();
  return Object::null();
}

DEFINE_NATIVE_ENTRY(String_getHashCode, 1) {
  const String& receiver =
      String::CheckedHandle(zone, arguments->NativeArgAt(0));
  intptr_t hash_val = receiver.Hash();
  ASSERT(hash_val > 0);
  ASSERT(Smi::IsValid(hash_val));
  return Smi::New(hash_val);
}

DEFINE_NATIVE_ENTRY(String_getLength, 1) {
  const String& receiver =
      String::CheckedHandle(zone, arguments->NativeArgAt(0));
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
  Exceptions::ThrowRangeError("index", index, 0, str.Length() - 1);
  return 0;
}

DEFINE_NATIVE_ENTRY(String_charAt, 2) {
  const String& receiver =
      String::CheckedHandle(zone, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, index, arguments->NativeArgAt(1));
  uint16_t value = StringValueAt(receiver, index);
  return Symbols::FromCharCode(thread, static_cast<int32_t>(value));
}

// Returns the 16-bit UTF-16 code unit at the given index.
DEFINE_NATIVE_ENTRY(String_codeUnitAt, 2) {
  const String& receiver =
      String::CheckedHandle(zone, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, index, arguments->NativeArgAt(1));
  uint16_t value = StringValueAt(receiver, index);
  return Smi::New(static_cast<intptr_t>(value));
}

DEFINE_NATIVE_ENTRY(String_concat, 2) {
  const String& receiver =
      String::CheckedHandle(zone, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(String, b, arguments->NativeArgAt(1));
  return String::Concat(receiver, b);
}

DEFINE_NATIVE_ENTRY(String_toLowerCase, 1) {
  const String& receiver =
      String::CheckedHandle(zone, arguments->NativeArgAt(0));
  ASSERT(!receiver.IsNull());
  return String::ToLowerCase(receiver);
}

DEFINE_NATIVE_ENTRY(String_toUpperCase, 1) {
  const String& receiver =
      String::CheckedHandle(zone, arguments->NativeArgAt(0));
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
    length = g_array.Length();
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
    Exceptions::ThrowRangeError("length", length, 0, array_length);
  }
  const String& result =
      isLatin1.value()
          ? String::Handle(OneByteString::New(length_value, Heap::kNew))
          : String::Handle(TwoByteString::New(length_value, Heap::kNew));
  NoSafepointScope no_safepoint;

  uint16_t* data_position = reinterpret_cast<uint16_t*>(codeUnits.DataAddr(0));
  String::Copy(result, 0, data_position, length_value);
  return result.raw();
}

}  // namespace dart
