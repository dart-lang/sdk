// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"

#include "include/dart_api.h"
#include "platform/unicode.h"
#include "vm/dart_api_impl.h"
#include "vm/exceptions.h"
#include "vm/isolate.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/symbols.h"

#if defined(TARGET_ARCH_ARM64)
#include <arm_neon.h>
#endif
#include <cstdint>

namespace dart {

class NativeStringDataAccess {
 public:
  static uint8_t* OneByteDataStart(const String& str) {
    return OneByteString::DataStart(str);
  }

  static uint16_t* TwoByteDataStart(const String& str) {
    return TwoByteString::DataStart(str);
  }
};

DEFINE_NATIVE_ENTRY(String_fromEnvironment, 0, 3) {
  GET_NON_NULL_NATIVE_ARGUMENT(String, name, arguments->NativeArgAt(1));
  GET_NATIVE_ARGUMENT(String, default_value, arguments->NativeArgAt(2));
  // Call the embedder to supply us with the environment.
  const String& env_value =
      String::Handle(Api::GetEnvironmentValue(thread, name));
  if (!env_value.IsNull()) {
    return Symbols::New(thread, env_value);
  }
  return default_value.ptr();
}

DEFINE_NATIVE_ENTRY(StringBase_createFromCodePoints, 0, 3) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, list, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, start_obj, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, end_obj, arguments->NativeArgAt(2));

  Array& a = Array::Handle();
  intptr_t length;
  if (list.IsGrowableObjectArray()) {
    const GrowableObjectArray& growableArray = GrowableObjectArray::Cast(list);
    a = growableArray.data();
    length = growableArray.Length();
  } else if (list.IsArray()) {
    a = Array::Cast(list).ptr();
    length = a.Length();
  } else {
    Exceptions::ThrowArgumentError(list);
    return nullptr;  // Unreachable.
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

DEFINE_NATIVE_ENTRY(StringBase_substringUnchecked, 0, 3) {
  const String& receiver =
      String::CheckedHandle(zone, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, start_obj, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, end_obj, arguments->NativeArgAt(2));

  intptr_t start = start_obj.Value();
  intptr_t end = end_obj.Value();
  return String::SubString(receiver, start, (end - start));
}

static intptr_t FindJsonStringTerminatorOneByte(const uint8_t* data,
                                                intptr_t start,
                                                intptr_t end) {
  const uint8_t* cursor = data + start;
  const uint8_t* limit = data + end;

#if defined(TARGET_ARCH_ARM64)
  if (end - start >= 16) {
    const uint8_t* simd_end = limit - 16;
    const uint8x16_t quote = vdupq_n_u8('"');
    const uint8x16_t backslash = vdupq_n_u8('\\');
    const uint8x16_t space = vdupq_n_u8(0x20);
    while (cursor <= simd_end) {
      const uint8x16_t block = vld1q_u8(cursor);
      const uint8x16_t is_quote = vceqq_u8(block, quote);
      const uint8x16_t is_backslash = vceqq_u8(block, backslash);
      const uint8x16_t is_ctrl = vcltq_u8(block, space);
      const uint8x16_t mask =
          vorrq_u8(is_ctrl, vorrq_u8(is_quote, is_backslash));
      if (vmaxvq_u8(mask) != 0) {
        alignas(16) uint8_t lanes[16];
        vst1q_u8(lanes, mask);
        for (intptr_t i = 0; i < 16; i++) {
          if (lanes[i] != 0) return (cursor - data) + i;
        }
      }
      cursor += 16;
    }
  }
#endif

  while (cursor < limit) {
    const uint8_t ch = *cursor;
    if (ch == '"' || ch == '\\' || ch < 0x20) break;
    cursor++;
  }
  return cursor - data;
}

static intptr_t FindJsonStringTerminatorTwoByte(const uint16_t* data,
                                                intptr_t start,
                                                intptr_t end) {
  const uint16_t* cursor = data + start;
  const uint16_t* limit = data + end;

#if defined(TARGET_ARCH_ARM64) && !defined(DEBUG)
  if (end - start >= 8) {
    const uint16_t* simd_end = limit - 8;
    const uint16x8_t quote = vdupq_n_u16('"');
    const uint16x8_t backslash = vdupq_n_u16('\\');
    const uint16x8_t space = vdupq_n_u16(0x20);
    while (cursor <= simd_end) {
      const uint16x8_t block = vld1q_u16(cursor);
      const uint16x8_t is_quote = vceqq_u16(block, quote);
      const uint16x8_t is_backslash = vceqq_u16(block, backslash);
      const uint16x8_t is_ctrl = vcltq_u16(block, space);
      const uint16x8_t mask =
          vorrq_u16(is_ctrl, vorrq_u16(is_quote, is_backslash));
      if (vmaxvq_u16(mask) != 0) {
        alignas(16) uint16_t lanes[8];
        vst1q_u16(lanes, mask);
        for (intptr_t i = 0; i < 8; i++) {
          if (lanes[i] != 0) return (cursor - data) + i;
        }
      }
      cursor += 8;
    }
  }
#endif

  while (cursor < limit) {
    const uint16_t ch = *cursor;
    if (ch == '"' || ch == '\\' || ch < 0x20) break;
    cursor++;
  }
  return cursor - data;
}

static constexpr uint32_t kUnusedPair = 0;
static constexpr uint32_t kDeletedPair = 1;

static inline uint32_t HashPattern(uint32_t full_hash,
                                   uint32_t hash_mask,
                                   intptr_t size) {
  const uint32_t masked = full_hash & hash_mask;
  return masked == 0 ? static_cast<uint32_t>(size >> 1)
                     : masked * static_cast<uint32_t>(size >> 1);
}

static inline intptr_t FirstProbe(uint32_t full_hash, intptr_t size_mask) {
  intptr_t i = full_hash & static_cast<uint32_t>(size_mask);
  return ((i << 1) + i) & size_mask;
}

class JsonMapBuilder {
 public:
  JsonMapBuilder(Thread* thread, Zone* zone)
      : thread_(thread),
        zone_(zone),
        data_(Array::Handle(zone_)),
        index_(TypedData::Handle(zone_)),
        existing_key_obj_(Object::Handle(zone_)),
        size_(0),
        size_mask_(0),
        max_entries_(0),
        used_pairs_(0),
        hash_mask_(0) {
    Init(LinkedHashBase::kInitialIndexSize);
  }

  void Add(const String& key, const Object& value) {
    if (used_pairs_ >= max_entries_) {
      Grow();
    }
    Insert(key, value);
  }

  MapPtr Build(const TypeArguments& type_args) const {
    const Map& map = Map::Handle(
        zone_, Map::New(kMapCid, data_, index_, hash_mask_, used_pairs_ << 1, 0,
                        Heap::kNew));
    map.SetTypeArguments(type_args);
    return map.ptr();
  }

  const TypedData& index() const { return index_; }
  intptr_t index_size() const { return size_; }

 private:
  void Init(intptr_t size) {
    size_ = size;
    size_mask_ = size_ - 1;
    max_entries_ = size_ >> 1;
    data_ = Array::New(size_);
    index_ = TypedData::New(kTypedDataUint32ArrayCid, size_);
    hash_mask_ = static_cast<uint32_t>(
        LinkedHashBase::IndexSizeToHashMask(size_));

    NoSafepointScope no_safepoint;
    memset(Array::DataOf(data_.ptr()), 0,
           size_ * sizeof(CompressedObjectPtr));
    memset(index_.DataAddr(0), 0, size_ * sizeof(uint32_t));
    used_pairs_ = 0;
  }

  void Grow() {
    const Array& old_data = Array::Handle(zone_, data_.ptr());
    const intptr_t old_used_pairs = used_pairs_;
    Init(size_ << 1);
    for (intptr_t i = 0; i < old_used_pairs; i++) {
      const intptr_t d = i << 1;
      const String& key = String::Cast(Object::Handle(zone_, old_data.At(d)));
      const Object& value = Object::Handle(zone_, old_data.At(d + 1));
      Insert(key, value);
    }
  }

  void Insert(const String& key, const Object& value) {
    const uint32_t full_hash = static_cast<uint32_t>(key.Hash());
    const uint32_t hash_pattern = HashPattern(full_hash, hash_mask_, size_);
    intptr_t probe = FirstProbe(full_hash, size_mask_);
    NoSafepointScope no_safepoint;
    uint32_t* index_data =
        reinterpret_cast<uint32_t*>(index_.DataAddr(0));
    while (true) {
      const uint32_t entry = index_data[probe];
      if (entry == kUnusedPair) {
        index_data[probe] = hash_pattern ^ static_cast<uint32_t>(used_pairs_);
        data_.SetAt(used_pairs_ << 1, key, thread_);
        data_.SetAt((used_pairs_ << 1) + 1, value, thread_);
        used_pairs_++;
        return;
      }
      if (entry != kDeletedPair) {
        const intptr_t entry_index =
            static_cast<intptr_t>(hash_pattern ^ entry);
        if (entry_index < max_entries_) {
          const intptr_t d = entry_index << 1;
          const ObjectPtr existing_key = data_.At(d);
          if (existing_key == key.ptr()) {
            data_.SetAt(d + 1, value, thread_);
            return;
          }
          existing_key_obj_ = existing_key;
          if (String::Cast(existing_key_obj_).Equals(key)) {
            data_.SetAt(d + 1, value, thread_);
            return;
          }
        }
      }
      probe = (probe + 1) & size_mask_;
    }
  }

  Thread* thread_;
  Zone* zone_;
  Array& data_;
  TypedData& index_;
  Object& existing_key_obj_;
  intptr_t size_;
  intptr_t size_mask_;
  intptr_t max_entries_;
  intptr_t used_pairs_;
  uint32_t hash_mask_;
};

class JsonArrayBuilder {
 public:
  JsonArrayBuilder(Thread* thread, Zone* zone, intptr_t initial_capacity = 16)
      : thread_(thread),
        zone_(zone),
        array_(Array::Handle(zone_, Array::New(initial_capacity))),
        length_(0) {}

  void Add(const Object& value) {
    if (length_ == array_.Length()) {
      Grow();
    }
    array_.SetAt(length_, value, thread_);
    length_++;
  }

  ObjectPtr Build() const {
    const GrowableObjectArray& list =
        GrowableObjectArray::Handle(zone_, GrowableObjectArray::New(array_));
    list.SetLength(length_);
    return list.ptr();
  }

 private:
  void Grow() {
    const intptr_t old_capacity = array_.Length();
    const intptr_t new_capacity = (old_capacity * 2) | 1;
    array_ = Array::Grow(array_, new_capacity, Heap::kNew);
  }

  Thread* thread_;
  Zone* zone_;
  Array& array_;
  intptr_t length_;
};

static MapPtr BuildMapFromPairs(Thread* thread,
                                const Array& pair_data,
                                intptr_t pair_len,
                                const TypeArguments& type_args) {
  Zone* zone = thread->zone();
  intptr_t size = 1;
  while (size < pair_len) {
    size <<= 1;
  }
  if (size < LinkedHashBase::kInitialIndexSize) {
    size = LinkedHashBase::kInitialIndexSize;
  }

  const Array& data = Array::Handle(zone, Array::New(size));
  const TypedData& index =
      TypedData::Handle(zone, TypedData::New(kTypedDataUint32ArrayCid, size));
  const uint32_t hash_mask = static_cast<uint32_t>(
      LinkedHashBase::IndexSizeToHashMask(size));
  const intptr_t size_mask = size - 1;
  const intptr_t max_entries = size >> 1;

  {
    NoSafepointScope no_safepoint;
    memset(Array::DataOf(data.ptr()), 0,
           size * sizeof(CompressedObjectPtr));
    memset(index.DataAddr(0), 0, size * sizeof(uint32_t));
  }

  intptr_t used_pairs = 0;
  Object& key_obj = Object::Handle(zone);
  Object& value_obj = Object::Handle(zone);
  Object& existing_key_obj = Object::Handle(zone);
  NoSafepointScope no_safepoint;
  uint32_t* index_data =
      reinterpret_cast<uint32_t*>(index.DataAddr(0));
  for (intptr_t i = 0; i < pair_len; i += 2) {
    key_obj = pair_data.At(i);
    const String& key = String::Cast(key_obj);
    value_obj = pair_data.At(i + 1);

    const uint32_t full_hash = static_cast<uint32_t>(key.Hash());
    const uint32_t hash_pattern = HashPattern(full_hash, hash_mask, size);
    intptr_t probe = FirstProbe(full_hash, size_mask);
    while (true) {
      const uint32_t entry = index_data[probe];
      if (entry == kUnusedPair) {
        index_data[probe] =
            hash_pattern ^ static_cast<uint32_t>(used_pairs);
        data.SetAt(used_pairs << 1, key, thread);
        data.SetAt((used_pairs << 1) + 1, value_obj, thread);
        used_pairs++;
        break;
      }
      if (entry != kDeletedPair) {
        const intptr_t entry_index =
            static_cast<intptr_t>(hash_pattern ^ entry);
        if (entry_index < max_entries) {
          const intptr_t d = entry_index << 1;
          const ObjectPtr existing_key = data.At(d);
          if (existing_key == key.ptr()) {
            data.SetAt(d + 1, value_obj, thread);
            break;
          }
          existing_key_obj = existing_key;
          if (String::Cast(existing_key_obj).Equals(key)) {
            data.SetAt(d + 1, value_obj, thread);
            break;
          }
        }
      }
      probe = (probe + 1) & size_mask;
    }
  }

  const Map& map = Map::Handle(
      zone, Map::New(kMapCid, data, index, hash_mask, used_pairs << 1, 0,
                     Heap::kNew));
  map.SetTypeArguments(type_args);
  return map.ptr();
}

class JsonFastParser {
 public:
  JsonFastParser(Thread* thread, const String& str, const Object& failure)
      : thread_(thread),
        zone_(thread->zone()),
        str_(String::Handle(zone_, str.ptr())),
        failure_(Object::Handle(zone_, failure.ptr())),
        length_(str_.Length()),
        pos_(0),
        map_type_args_(TypeArguments::Handle(
            zone_, thread_->isolate_group()->object_store()->type_argument_string_dynamic())) {}

  ObjectPtr Parse() {
    SkipWhitespace();
    ObjectPtr value = ParseValue();
    if (value == failure_.ptr()) return failure_.ptr();
    SkipWhitespace();
    if (pos_ != length_) return failure_.ptr();
    return value;
  }

 private:
  void SkipWhitespace() {
    while (pos_ < length_) {
      const uint8_t ch = OneByteString::CharAt(str_, pos_);
      if (ch == ' ' || ch == '\n' || ch == '\r' || ch == '\t') {
        pos_++;
      } else {
        break;
      }
    }
  }

  ObjectPtr ParseValue() {
    SkipWhitespace();
    if (pos_ >= length_) return failure_.ptr();
    const uint8_t ch = OneByteString::CharAt(str_, pos_);
    switch (ch) {
      case '{':
        pos_++;
        return ParseObject();
      case '[':
        pos_++;
        return ParseArray();
      case '"':
        return ParseString();
      case 't':
        return MatchKeyword("true", 4, Bool::True().ptr());
      case 'f':
        return MatchKeyword("false", 5, Bool::False().ptr());
      case 'n':
        return MatchKeyword("null", 4, Object::null());
      default:
        if (ch == '-' || (ch >= '0' && ch <= '9')) {
          return ParseNumber();
        }
        return failure_.ptr();
    }
  }

  ObjectPtr MatchKeyword(const char* keyword,
                         intptr_t length,
                         ObjectPtr value) {
    if (pos_ + length > length_) return failure_.ptr();
    for (intptr_t i = 0; i < length; i++) {
      if (OneByteString::CharAt(str_, pos_ + i) != keyword[i]) {
        return failure_.ptr();
      }
    }
    pos_ += length;
    return value;
  }

  ObjectPtr ParseObject() {
    SkipWhitespace();
    JsonMapBuilder map_builder(thread_, zone_);
    Object& key_obj = Object::Handle(zone_);
    Object& value_obj = Object::Handle(zone_);
    if (pos_ < length_ && OneByteString::CharAt(str_, pos_) == '}') {
      pos_++;
      return map_builder.Build(map_type_args_);
    }
    while (true) {
      SkipWhitespace();
      if (pos_ >= length_ || OneByteString::CharAt(str_, pos_) != '"') {
        return failure_.ptr();
      }
      key_obj = ParseKeyString();
      if (key_obj.ptr() == failure_.ptr()) return failure_.ptr();
#if defined(DEBUG)
      ASSERT(key_obj.IsString());
#endif
      SkipWhitespace();
      if (pos_ >= length_ || OneByteString::CharAt(str_, pos_) != ':') {
        return failure_.ptr();
      }
      pos_++;
      value_obj = ParseValue();
      if (value_obj.ptr() == failure_.ptr()) return failure_.ptr();

      map_builder.Add(String::Cast(key_obj), value_obj);

      SkipWhitespace();
      if (pos_ >= length_) return failure_.ptr();
      const uint8_t ch = OneByteString::CharAt(str_, pos_);
      if (ch == ',') {
        pos_++;
        continue;
      }
      if (ch == '}') {
        pos_++;
        return map_builder.Build(map_type_args_);
      }
      return failure_.ptr();
    }
  }

  ObjectPtr ParseArray() {
    SkipWhitespace();
    JsonArrayBuilder list_builder(thread_, zone_);
    Object& temp = Object::Handle(zone_);
    if (pos_ < length_ && OneByteString::CharAt(str_, pos_) == ']') {
      pos_++;
      return list_builder.Build();
    }
    while (true) {
      temp = ParseValue();
      if (temp.ptr() == failure_.ptr()) return failure_.ptr();
      list_builder.Add(temp);
      SkipWhitespace();
      if (pos_ >= length_) return failure_.ptr();
      const uint8_t ch = OneByteString::CharAt(str_, pos_);
      if (ch == ',') {
        pos_++;
        continue;
      }
      if (ch == ']') {
        pos_++;
        return list_builder.Build();
      }
      return failure_.ptr();
    }
  }

  ObjectPtr ParseString() {
    ASSERT(OneByteString::CharAt(str_, pos_) == '"');
    pos_++;
    const intptr_t start = pos_;
    intptr_t scan = start;
    {
      NoSafepointScope no_safepoint;
      const uint8_t* data = NativeStringDataAccess::OneByteDataStart(str_);
      scan = FindJsonStringTerminatorOneByte(data, start, length_);
    }
    if (scan >= length_) return failure_.ptr();
    const uint8_t terminator = OneByteString::CharAt(str_, scan);
    if (terminator == '"') {
      pos_ = scan + 1;
      return OneByteString::SubStringUnchecked(
          str_, start, scan - start, Heap::kNew);
    }
    if (terminator == '\\') {
      return ParseStringWithEscapes(start);
    }
    return failure_.ptr();
  }

  ObjectPtr ParseKeyString() {
    ASSERT(OneByteString::CharAt(str_, pos_) == '"');
    pos_++;
    const intptr_t start = pos_;
    intptr_t scan = start;
    {
      NoSafepointScope no_safepoint;
      const uint8_t* data = NativeStringDataAccess::OneByteDataStart(str_);
      scan = FindJsonStringTerminatorOneByte(data, start, length_);
    }
    if (scan >= length_) return failure_.ptr();
    const uint8_t terminator = OneByteString::CharAt(str_, scan);
    if (terminator == '"') {
      const intptr_t len = scan - start;
      if (len > 0 && len <= 3) {
        uint8_t buf[3];
        bool all_digits = true;
        for (intptr_t i = 0; i < len; i++) {
          const uint8_t ch = OneByteString::CharAt(str_, start + i);
          if (ch < '0' || ch > '9') {
            all_digits = false;
            break;
          }
          buf[i] = ch;
        }
        if (all_digits) {
          pos_ = scan + 1;
          return Symbols::FromLatin1(thread_, buf, len);
        }
      }
      pos_ = scan + 1;
      return OneByteString::SubStringUnchecked(
          str_, start, scan - start, Heap::kNew);
    }
    if (terminator == '\\') {
      return ParseStringWithEscapes(start);
    }
    return failure_.ptr();
  }

  ObjectPtr ParseNumber() {
    const intptr_t start = pos_;
    bool neg = false;
    if (OneByteString::CharAt(str_, pos_) == '-') {
      neg = true;
      pos_++;
      if (pos_ >= length_) return failure_.ptr();
    }

    uint8_t ch = OneByteString::CharAt(str_, pos_);
    bool is_double = false;
    bool overflow = false;
    int64_t value = 0;
    if (ch == '0') {
      pos_++;
      if (pos_ < length_) {
        ch = OneByteString::CharAt(str_, pos_);
        if (ch >= '0' && ch <= '9') return failure_.ptr();
      }
    } else if (ch >= '1' && ch <= '9') {
      while (pos_ < length_) {
        ch = OneByteString::CharAt(str_, pos_);
        if (ch < '0' || ch > '9') break;
        const int digit = ch - '0';
        if (value > (INT64_MAX - digit) / 10) {
          overflow = true;
        } else {
          value = value * 10 + digit;
        }
        pos_++;
      }
    } else {
      return failure_.ptr();
    }

    if (pos_ < length_) {
      ch = OneByteString::CharAt(str_, pos_);
      if (ch == '.') {
        is_double = true;
        pos_++;
        if (pos_ >= length_) return failure_.ptr();
        ch = OneByteString::CharAt(str_, pos_);
        if (ch < '0' || ch > '9') return failure_.ptr();
        while (pos_ < length_) {
          ch = OneByteString::CharAt(str_, pos_);
          if (ch < '0' || ch > '9') break;
          pos_++;
        }
      }
    }

    if (pos_ < length_) {
      ch = OneByteString::CharAt(str_, pos_);
      if (ch == 'e' || ch == 'E') {
        is_double = true;
        pos_++;
        if (pos_ >= length_) return failure_.ptr();
        ch = OneByteString::CharAt(str_, pos_);
        if (ch == '+' || ch == '-') {
          pos_++;
          if (pos_ >= length_) return failure_.ptr();
          ch = OneByteString::CharAt(str_, pos_);
        }
        if (ch < '0' || ch > '9') return failure_.ptr();
        while (pos_ < length_) {
          ch = OneByteString::CharAt(str_, pos_);
          if (ch < '0' || ch > '9') break;
          pos_++;
        }
      }
    }

    if (!is_double && !overflow) {
      const int64_t signed_value = neg ? -value : value;
      return Integer::New(signed_value, Heap::kNew);
    }

    const String& num_str =
        String::Handle(zone_, String::SubString(str_, start, pos_ - start));
    return Double::New(num_str, Heap::kNew);
  }

  ObjectPtr ParseStringWithEscapes(intptr_t start) {
    intptr_t i = start;
    const intptr_t max_len = length_ - start;
    uint16_t* buffer = zone_->Alloc<uint16_t>(max_len);
    intptr_t out = 0;
    bool is_one_byte = true;
    while (i < length_) {
      uint8_t ch = OneByteString::CharAt(str_, i++);
      if (ch == '"') {
        pos_ = i;
        return BuildString(buffer, out, is_one_byte);
      }
      if (ch == '\\') {
        if (i >= length_) return failure_.ptr();
        ch = OneByteString::CharAt(str_, i++);
        switch (ch) {
          case '"':
          case '\\':
          case '/':
            break;
          case 'b':
            ch = '\b';
            break;
          case 'f':
            ch = '\f';
            break;
          case 'n':
            ch = '\n';
            break;
          case 'r':
            ch = '\r';
            break;
          case 't':
            ch = '\t';
            break;
          case 'u': {
            if (i + 4 > length_) return failure_.ptr();
            int value = 0;
            for (int j = 0; j < 4; j++) {
              const int digit = HexValue(OneByteString::CharAt(str_, i + j));
              if (digit < 0) return failure_.ptr();
              value = (value << 4) | digit;
            }
            i += 4;
            buffer[out++] = static_cast<uint16_t>(value);
            if (value > 0xFF) is_one_byte = false;
            continue;
          }
          default:
            return failure_.ptr();
        }
      } else if (ch < 0x20) {
        return failure_.ptr();
      }
      buffer[out++] = ch;
    }
    return failure_.ptr();
  }

  static int HexValue(uint8_t ch) {
    if (ch >= '0' && ch <= '9') return ch - '0';
    ch |= 0x20;
    if (ch >= 'a' && ch <= 'f') return 10 + (ch - 'a');
    return -1;
  }

  StringPtr BuildString(uint16_t* buffer,
                        intptr_t length,
                        bool is_one_byte) {
    if (is_one_byte) {
      return OneByteString::New(buffer, length, Heap::kNew);
    }
    return TwoByteString::New(buffer, length, Heap::kNew);
  }

  ObjectPtr CreateMapFromPairs(const GrowableObjectArray& pairs) {
    const Array& pair_data = Array::Handle(zone_, pairs.data());
    return BuildMapFromPairs(thread_, pair_data, pairs.Length(), map_type_args_);
  }

  Thread* thread_;
  Zone* zone_;
  const String& str_;
  const Object& failure_;
  const intptr_t length_;
  intptr_t pos_;
  const TypeArguments& map_type_args_;
};

class JsonFastParserTwoByte {
 public:
  JsonFastParserTwoByte(Thread* thread, const String& str, const Object& failure)
      : thread_(thread),
        zone_(thread->zone()),
        str_(String::Handle(zone_, str.ptr())),
        failure_(Object::Handle(zone_, failure.ptr())),
        length_(str_.Length()),
        pos_(0),
        key_cache_len_(0),
        shape_cache_len_(0),
        map_type_args_(TypeArguments::Handle(
            zone_, thread_->isolate_group()->object_store()->type_argument_string_dynamic())) {
    for (intptr_t i = 0; i < kSmallObjectMaxKeys; i++) {
      small_keys_[i] = &Object::Handle(zone_);
      small_values_[i] = &Object::Handle(zone_);
    }
    for (intptr_t i = 0; i < kKeyCacheMaxEntries; i++) {
      key_cache_[i] = &String::Handle(zone_);
    }
    for (intptr_t i = 0; i < 10; i++) {
      digit_key1_[i] = &String::Handle(zone_);
    }
    for (intptr_t i = 0; i < 100; i++) {
      digit_key2_[i] = &String::Handle(zone_);
    }
    for (intptr_t i = 0; i < kShapeCacheMaxEntries; i++) {
      shape_cache_[i] = &Array::Handle(zone_);
    }
  }

  ObjectPtr Parse() {
    AssertValidPos();
    SkipWhitespace();
    ObjectPtr value = ParseValue();
    if (value == failure_.ptr()) return failure_.ptr();
    SkipWhitespace();
    AssertValidPos();
    if (pos_ != length_) return failure_.ptr();
    return value;
  }

 private:
  void AssertValidPos() const {
    ASSERT(pos_ >= 0);
    ASSERT(pos_ <= length_);
  }

  void SkipWhitespace() {
    AssertValidPos();
    while (pos_ < length_) {
      const uint16_t ch = TwoByteString::CharAt(str_, pos_);
      if (ch == ' ' || ch == '\n' || ch == '\r' || ch == '\t') {
        pos_++;
      } else {
        break;
      }
    }
  }

  ObjectPtr ParseValue() {
    AssertValidPos();
    SkipWhitespace();
    return ParseValueNoWhitespace();
  }

  ObjectPtr ParseValueNoWhitespace() {
    AssertValidPos();
    if (pos_ >= length_) return failure_.ptr();
    const uint16_t ch = TwoByteString::CharAt(str_, pos_);
    switch (ch) {
      case '{':
        pos_++;
        return ParseObject();
      case '[':
        pos_++;
        return ParseArray();
      case '"':
        return ParseString();
      case 't':
        return MatchKeyword("true", 4, Bool::True().ptr());
      case 'f':
        return MatchKeyword("false", 5, Bool::False().ptr());
      case 'n':
        return MatchKeyword("null", 4, Object::null());
      default:
        if (ch == '-' || (ch >= '0' && ch <= '9')) {
          return ParseNumber();
        }
        return failure_.ptr();
    }
  }

  ObjectPtr MatchKeyword(const char* keyword,
                         intptr_t length,
                         ObjectPtr value) {
    if (pos_ + length > length_) return failure_.ptr();
    for (intptr_t i = 0; i < length; i++) {
      if (TwoByteString::CharAt(str_, pos_ + i) != keyword[i]) {
        return failure_.ptr();
      }
    }
    pos_ += length;
    return value;
  }

  ObjectPtr ParseObject() {
    AssertValidPos();
    SkipWhitespace();
    Object& key_obj = Object::Handle(zone_);
    Object& value_obj = Object::Handle(zone_);
    JsonMapBuilder* map_builder = nullptr;
    bool use_small = true;
    intptr_t count = 0;
    if (pos_ < length_ && TwoByteString::CharAt(str_, pos_) == '}') {
      pos_++;
      JsonMapBuilder empty_builder(thread_, zone_);
      return empty_builder.Build(map_type_args_);
    }
    while (true) {
      SkipWhitespace();
      if (pos_ >= length_ || TwoByteString::CharAt(str_, pos_) != '"') {
        return failure_.ptr();
      }
      key_obj = ParseKeyString();
      if (key_obj.ptr() == failure_.ptr()) return failure_.ptr();
#if defined(DEBUG)
      ASSERT(key_obj.IsString());
#endif
      if (pos_ >= length_) return failure_.ptr();
      uint16_t ch = TwoByteString::CharAt(str_, pos_);
      if (ch != ':') {
        SkipWhitespace();
        if (pos_ >= length_ || TwoByteString::CharAt(str_, pos_) != ':') {
          return failure_.ptr();
        }
      }
      pos_++;
      if (pos_ < length_) {
        const uint16_t next = TwoByteString::CharAt(str_, pos_);
        if (next == ' ' || next == '\n' || next == '\r' || next == '\t') {
          SkipWhitespace();
        }
      }
      value_obj = ParseValueNoWhitespace();
      if (value_obj.ptr() == failure_.ptr()) return failure_.ptr();

      if (use_small) {
        const String& key = String::Cast(key_obj);
        if (key.Length() > kKeyCacheMaxLength) {
          use_small = false;
        } else {
          intptr_t dup_index = -1;
          for (intptr_t i = 0; i < count; i++) {
            if (small_keys_[i]->ptr() == key.ptr()) {
              dup_index = i;
              break;
            }
          }
          if (dup_index >= 0) {
            *small_values_[dup_index] = value_obj.ptr();
          } else if (count < kSmallObjectMaxKeys) {
            *small_keys_[count] = key_obj.ptr();
            *small_values_[count] = value_obj.ptr();
            count++;
          } else {
            use_small = false;
          }
        }
        if (!use_small) {
          map_builder = new (zone_->Alloc<JsonMapBuilder>(1))
              JsonMapBuilder(thread_, zone_);
          for (intptr_t i = 0; i < count; i++) {
            map_builder->Add(String::Cast(*small_keys_[i]), *small_values_[i]);
          }
          map_builder->Add(String::Cast(key_obj), value_obj);
        }
      } else {
        if (map_builder == nullptr) {
          map_builder = new (zone_->Alloc<JsonMapBuilder>(1))
              JsonMapBuilder(thread_, zone_);
        }
        map_builder->Add(String::Cast(key_obj), value_obj);
      }

      if (pos_ >= length_) return failure_.ptr();
      ch = TwoByteString::CharAt(str_, pos_);
      if (ch == ',') {
        pos_++;
        continue;
      }
      if (ch == '}') {
        pos_++;
        if (use_small) {
          return BuildSmallObjectMap(count);
        }
        return map_builder->Build(map_type_args_);
      }
      SkipWhitespace();
      if (pos_ >= length_) return failure_.ptr();
      ch = TwoByteString::CharAt(str_, pos_);
      if (ch == ',') {
        pos_++;
        continue;
      }
      if (ch == '}') {
        pos_++;
        if (use_small) {
          return BuildSmallObjectMap(count);
        }
        return map_builder->Build(map_type_args_);
      }
      return failure_.ptr();
    }
  }

  ObjectPtr ParseArray() {
    AssertValidPos();
    SkipWhitespace();
    JsonArrayBuilder list_builder(thread_, zone_);
    Object& temp = Object::Handle(zone_);
    if (pos_ < length_ && TwoByteString::CharAt(str_, pos_) == ']') {
      pos_++;
      return list_builder.Build();
    }
    while (true) {
      if (pos_ < length_) {
        const uint16_t next = TwoByteString::CharAt(str_, pos_);
        if (next == ' ' || next == '\n' || next == '\r' || next == '\t') {
          SkipWhitespace();
        }
      }
      temp = ParseValueNoWhitespace();
      if (temp.ptr() == failure_.ptr()) return failure_.ptr();
      list_builder.Add(temp);
      if (pos_ >= length_) return failure_.ptr();
      uint16_t ch = TwoByteString::CharAt(str_, pos_);
      if (ch == ',') {
        pos_++;
        continue;
      }
      if (ch == ']') {
        pos_++;
        return list_builder.Build();
      }
      SkipWhitespace();
      if (pos_ >= length_) return failure_.ptr();
      ch = TwoByteString::CharAt(str_, pos_);
      if (ch == ',') {
        pos_++;
        continue;
      }
      if (ch == ']') {
        pos_++;
        return list_builder.Build();
      }
      return failure_.ptr();
    }
  }

  ObjectPtr ParseString() {
    AssertValidPos();
    ASSERT(TwoByteString::CharAt(str_, pos_) == '"');
    pos_++;
    const intptr_t start = pos_;
    intptr_t scan = start;
    {
      NoSafepointScope no_safepoint;
      const uint16_t* data = NativeStringDataAccess::TwoByteDataStart(str_);
      scan = FindJsonStringTerminatorTwoByte(data, start, length_);
    }
    ASSERT(scan >= start);
    if (scan >= length_) return failure_.ptr();
    const uint16_t terminator = TwoByteString::CharAt(str_, scan);
    if (terminator == '"') {
      pos_ = scan + 1;
      ASSERT(scan >= start);
      ASSERT(scan <= length_);
      const intptr_t len = scan - start;
      if (len <= kValueStringOneByteMax) {
        return BuildAsciiSubString(start, len);
      }
      return TwoByteString::SubStringUnchecked(str_, start, len, Heap::kNew);
    }
    if (terminator == '\\') {
      return ParseStringWithEscapes(start);
    }
    return failure_.ptr();
  }

  ObjectPtr ParseKeyString() {
    AssertValidPos();
    ASSERT(TwoByteString::CharAt(str_, pos_) == '"');
    pos_++;
    const intptr_t start = pos_;
    if (pos_ + 1 < length_) {
      const uint16_t ch0 = TwoByteString::CharAt(str_, pos_);
      if (ch0 != '"' && ch0 != '\\' && ch0 >= 0x20 && ch0 <= 0xFF) {
        const uint16_t ch1 = TwoByteString::CharAt(str_, pos_ + 1);
        if (ch1 == '"') {
          pos_ += 2;
          if (ch0 >= '0' && ch0 <= '9') {
            return LookupOrCreateDigitKey(ch0 - '0', 0, 1);
          }
          return LookupOrCreateShortKey(ch0, 0, 1);
        }
        if (ch1 != '"' && ch1 != '\\' && ch1 >= 0x20 && ch1 <= 0xFF) {
          if (pos_ + 2 < length_ &&
              TwoByteString::CharAt(str_, pos_ + 2) == '"') {
            pos_ += 3;
            if (ch0 >= '0' && ch0 <= '9' && ch1 >= '0' && ch1 <= '9') {
              return LookupOrCreateDigitKey(ch0 - '0', ch1 - '0', 2);
            }
            return LookupOrCreateShortKey(ch0, ch1, 2);
          }
        }
      }
    }
    intptr_t scan = start;
    {
      NoSafepointScope no_safepoint;
      const uint16_t* data = NativeStringDataAccess::TwoByteDataStart(str_);
      scan = FindJsonStringTerminatorTwoByte(data, start, length_);
    }
    ASSERT(scan >= start);
    if (scan >= length_) return failure_.ptr();
    const uint16_t terminator = TwoByteString::CharAt(str_, scan);
    if (terminator == '"') {
      pos_ = scan + 1;
      ASSERT(scan >= start);
      ASSERT(scan <= length_);
      const intptr_t len = scan - start;
      if (len <= kKeyCacheMaxLength) {
        for (intptr_t i = 0; i < key_cache_len_; i++) {
          if (SliceEqualsKey(start, len, *key_cache_[i])) {
            return key_cache_[i]->ptr();
          }
        }
      }
      const String& key =
          String::Handle(zone_, BuildAsciiSubString(start, len));
      if (len <= kKeyCacheMaxLength && key_cache_len_ < kKeyCacheMaxEntries) {
        *key_cache_[key_cache_len_++] = key.ptr();
      }
      return key.ptr();
    }
    if (terminator == '\\') {
      return ParseStringWithEscapes(start);
    }
    return failure_.ptr();
  }

  ObjectPtr ParseNumber() {
    AssertValidPos();
    const intptr_t start = pos_;
    bool neg = false;
    if (TwoByteString::CharAt(str_, pos_) == '-') {
      neg = true;
      pos_++;
      if (pos_ >= length_) return failure_.ptr();
    }

    uint16_t ch = 0;
    bool is_double = false;
    bool overflow = false;
    int64_t value = 0;
    {
      NoSafepointScope no_safepoint;
      const uint16_t* data = NativeStringDataAccess::TwoByteDataStart(str_);
      intptr_t p = pos_;
      ch = data[p];
      if (ch == '-') return failure_.ptr();
      if (ch == '0') {
        p++;
        if (p < length_) {
          ch = data[p];
          if (ch >= '0' && ch <= '9') return failure_.ptr();
        }
      } else if (ch >= '1' && ch <= '9') {
        while (p < length_) {
          ch = data[p];
          if (ch < '0' || ch > '9') break;
          const int digit = ch - '0';
          if (value > (INT64_MAX - digit) / 10) {
            overflow = true;
          } else {
            value = value * 10 + digit;
          }
          p++;
        }
      } else {
        return failure_.ptr();
      }

      if (p < length_) {
        ch = data[p];
        if (ch == '.') {
          is_double = true;
          p++;
          if (p >= length_) return failure_.ptr();
          ch = data[p];
          if (ch < '0' || ch > '9') return failure_.ptr();
          while (p < length_) {
            ch = data[p];
            if (ch < '0' || ch > '9') break;
            p++;
          }
        }
      }

      if (p < length_) {
        ch = data[p];
        if (ch == 'e' || ch == 'E') {
          is_double = true;
          p++;
          if (p >= length_) return failure_.ptr();
          ch = data[p];
          if (ch == '+' || ch == '-') {
            p++;
            if (p >= length_) return failure_.ptr();
            ch = data[p];
          }
          if (ch < '0' || ch > '9') return failure_.ptr();
          while (p < length_) {
            ch = data[p];
            if (ch < '0' || ch > '9') break;
            p++;
          }
        }
      }
      pos_ = p;
    }

    if (!is_double && !overflow) {
      const int64_t signed_value = neg ? -value : value;
      return Integer::New(signed_value, Heap::kNew);
    }

    ASSERT(pos_ >= start);
    const String& num_str =
        String::Handle(zone_, BuildAsciiSubString(start, pos_ - start));
    return Double::New(num_str, Heap::kNew);
  }

  ObjectPtr ParseStringWithEscapes(intptr_t start) {
    AssertValidPos();
    ASSERT(start >= 0);
    ASSERT(start <= length_);
    intptr_t i = start;
    const intptr_t max_len = length_ - start;
    uint16_t* buffer = zone_->Alloc<uint16_t>(max_len);
    intptr_t out = 0;
    bool is_one_byte = true;
    while (i < length_) {
      ASSERT(i <= length_);
      uint16_t ch = TwoByteString::CharAt(str_, i++);
      if (ch == '"') {
        pos_ = i;
        return BuildString(buffer, out, is_one_byte);
      }
      if (ch == '\\') {
        if (i >= length_) return failure_.ptr();
        ch = TwoByteString::CharAt(str_, i++);
        switch (ch) {
          case '"':
          case '\\':
          case '/':
            break;
          case 'b':
            ch = '\b';
            break;
          case 'f':
            ch = '\f';
            break;
          case 'n':
            ch = '\n';
            break;
          case 'r':
            ch = '\r';
            break;
          case 't':
            ch = '\t';
            break;
          case 'u': {
            if (i + 4 > length_) return failure_.ptr();
            int value = 0;
            for (int j = 0; j < 4; j++) {
              const int digit = HexValue(TwoByteString::CharAt(str_, i + j));
              if (digit < 0) return failure_.ptr();
              value = (value << 4) | digit;
            }
            i += 4;
            ch = static_cast<uint16_t>(value);
            break;
          }
          default:
            return failure_.ptr();
        }
      } else if (ch < 0x20) {
        return failure_.ptr();
      }
      if (ch > 0xFF) is_one_byte = false;
      ASSERT(out < max_len);
      buffer[out++] = ch;
    }
    return failure_.ptr();
  }

  static int HexValue(uint16_t ch) {
    if (ch >= '0' && ch <= '9') return ch - '0';
    ch |= 0x20;
    if (ch >= 'a' && ch <= 'f') return 10 + (ch - 'a');
    return -1;
  }

  StringPtr BuildString(uint16_t* buffer,
                        intptr_t length,
                        bool is_one_byte) {
    if (is_one_byte) {
      return OneByteString::New(buffer, length, Heap::kNew);
    }
    return TwoByteString::New(buffer, length, Heap::kNew);
  }

  ObjectPtr CreateMapFromPairs(const GrowableObjectArray& pairs) {
    const Array& pair_data = Array::Handle(zone_, pairs.data());
    return BuildMapFromPairs(thread_, pair_data, pairs.Length(), map_type_args_);
  }

  ObjectPtr BuildSmallObjectMap(intptr_t count) {
    if (count == 0) {
      JsonMapBuilder empty_builder(thread_, zone_);
      return empty_builder.Build(map_type_args_);
    }
    for (intptr_t i = 0; i < shape_cache_len_; i++) {
      Array& shape = *shape_cache_[i];
      if (shape.Length() != count + 2) continue;
      bool match = true;
      for (intptr_t j = 0; j < count; j++) {
        if (shape.At(j + 2) != small_keys_[j]->ptr()) {
          match = false;
          break;
        }
      }
      if (match) {
        return BuildMapFromShape(shape, count);
      }
    }

    JsonMapBuilder builder(thread_, zone_);
    for (intptr_t i = 0; i < count; i++) {
      builder.Add(String::Cast(*small_keys_[i]), *small_values_[i]);
    }
    const MapPtr map = builder.Build(map_type_args_);
    if (shape_cache_len_ < kShapeCacheMaxEntries) {
      const intptr_t size = builder.index_size();
      const TypedData& index_copy = TypedData::Handle(
          zone_, TypedData::New(kTypedDataUint32ArrayCid, size));
      {
        NoSafepointScope no_safepoint;
        memcpy(index_copy.DataAddr(0), builder.index().DataAddr(0),
               size * sizeof(uint32_t));
      }
      const Array& shape =
          Array::Handle(zone_, Array::New(count + 2, Heap::kNew));
      shape.SetAt(0, index_copy, thread_);
      shape.SetAt(1, Smi::Handle(zone_, Smi::New(count)), thread_);
      for (intptr_t i = 0; i < count; i++) {
        shape.SetAt(i + 2, *small_keys_[i], thread_);
      }
      *shape_cache_[shape_cache_len_++] = shape.ptr();
    }
    return map;
  }

  ObjectPtr BuildMapFromShape(const Array& shape, intptr_t count) {
    const TypedData& index_template =
        TypedData::Cast(Object::Handle(zone_, shape.At(0)));
    const intptr_t size = index_template.Length();
    const uint32_t hash_mask = static_cast<uint32_t>(
        LinkedHashBase::IndexSizeToHashMask(size));

    const Array& data = Array::Handle(zone_, Array::New(size));
    const TypedData& index =
        TypedData::Handle(zone_, TypedData::New(kTypedDataUint32ArrayCid, size));
    {
      NoSafepointScope no_safepoint;
      memset(Array::DataOf(data.ptr()), 0,
             size * sizeof(CompressedObjectPtr));
      memcpy(index.DataAddr(0), index_template.DataAddr(0),
             size * sizeof(uint32_t));
      CompressedObjectPtr* slots = Array::DataOf(data.ptr());
      for (intptr_t i = 0; i < count; i++) {
        const intptr_t d = i << 1;
        slots[d] = small_keys_[i]->ptr();
        slots[d + 1] = small_values_[i]->ptr();
      }
    }
    const Map& map = Map::Handle(
        zone_, Map::New(kMapCid, data, index, hash_mask, count << 1, 0,
                        Heap::kNew));
    map.SetTypeArguments(map_type_args_);
    return map.ptr();
  }

  StringPtr BuildAsciiSubString(intptr_t start, intptr_t length) {
    ASSERT(start >= 0);
    ASSERT(length >= 0);
    if (length == 0) return Symbols::Empty().ptr();
    OneByteStringPtr one_byte = OneByteString::New(length, Heap::kNew);
    const String& one_handle = String::Handle(zone_, one_byte);
    bool is_one_byte = true;
    {
      NoSafepointScope no_safepoint;
      const uint16_t* src =
          NativeStringDataAccess::TwoByteDataStart(str_) + start;
      uint8_t* dst = NativeStringDataAccess::OneByteDataStart(one_handle);
#if defined(TARGET_ARCH_ARM64)
      intptr_t i = 0;
      const intptr_t simd_len = length & ~static_cast<intptr_t>(7);
      for (; i < simd_len; i += 8) {
        const uint16x8_t block = vld1q_u16(src + i);
        const uint16x8_t high = vshrq_n_u16(block, 8);
        if (vmaxvq_u16(high) != 0) {
          is_one_byte = false;
          break;
        }
        const uint8x8_t narrowed = vmovn_u16(block);
        vst1_u8(dst + i, narrowed);
      }
      if (is_one_byte) {
        for (; i < length; i++) {
          const uint16_t ch = src[i];
          if (ch > 0xFF) {
            is_one_byte = false;
            break;
          }
          dst[i] = static_cast<uint8_t>(ch);
        }
      }
#else
      for (intptr_t i = 0; i < length; i++) {
        const uint16_t ch = src[i];
        if (ch > 0xFF) {
          is_one_byte = false;
          break;
        }
        dst[i] = static_cast<uint8_t>(ch);
      }
#endif
    }
    if (is_one_byte) return one_byte;
    return TwoByteString::SubStringUnchecked(str_, start, length, Heap::kNew);
  }

  bool SliceEqualsKey(intptr_t start, intptr_t len, const String& key) {
    if (key.Length() != len) return false;
    if (len == 0) return true;
    NoSafepointScope no_safepoint;
    const uint16_t* src =
        NativeStringDataAccess::TwoByteDataStart(str_) + start;
    if (key.IsOneByteString()) {
      const uint8_t* dst = NativeStringDataAccess::OneByteDataStart(key);
      for (intptr_t i = 0; i < len; i++) {
        if (src[i] != dst[i]) return false;
      }
      return true;
    }
    const uint16_t* dst = NativeStringDataAccess::TwoByteDataStart(key);
    for (intptr_t i = 0; i < len; i++) {
      if (src[i] != dst[i]) return false;
    }
    return true;
  }

  StringPtr LookupOrCreateShortKey(uint16_t ch0, uint16_t ch1, intptr_t len) {
    if (len <= kKeyCacheMaxLength) {
      NoSafepointScope no_safepoint;
      for (intptr_t i = 0; i < key_cache_len_; i++) {
        const String& cached = *key_cache_[i];
        if (cached.Length() != len || !cached.IsOneByteString()) continue;
        const uint8_t* data = NativeStringDataAccess::OneByteDataStart(cached);
        if (data[0] != static_cast<uint8_t>(ch0)) continue;
        if (len == 2 && data[1] != static_cast<uint8_t>(ch1)) continue;
        return cached.ptr();
      }
    }
    OneByteStringPtr one_byte = OneByteString::New(len, Heap::kNew);
    const String& handle = String::Handle(zone_, one_byte);
    {
      NoSafepointScope no_safepoint;
      uint8_t* dst = NativeStringDataAccess::OneByteDataStart(handle);
      dst[0] = static_cast<uint8_t>(ch0);
      if (len == 2) dst[1] = static_cast<uint8_t>(ch1);
    }
    if (len <= kKeyCacheMaxLength && key_cache_len_ < kKeyCacheMaxEntries) {
      *key_cache_[key_cache_len_++] = one_byte;
    }
    return one_byte;
  }

  StringPtr LookupOrCreateDigitKey(uint16_t digit0,
                                   uint16_t digit1,
                                   intptr_t len) {
    if (len == 1) {
      String& cached = *digit_key1_[digit0];
      if (!cached.IsNull()) return cached.ptr();
      OneByteStringPtr one_byte = OneByteString::New(1, Heap::kNew);
      const String& handle = String::Handle(zone_, one_byte);
      {
        NoSafepointScope no_safepoint;
        uint8_t* dst = NativeStringDataAccess::OneByteDataStart(handle);
        dst[0] = static_cast<uint8_t>('0' + digit0);
      }
      cached = one_byte;
      return one_byte;
    }
    const uint16_t index = static_cast<uint16_t>(digit0 * 10 + digit1);
    String& cached = *digit_key2_[index];
    if (!cached.IsNull()) return cached.ptr();
    OneByteStringPtr one_byte = OneByteString::New(2, Heap::kNew);
    const String& handle = String::Handle(zone_, one_byte);
    {
      NoSafepointScope no_safepoint;
      uint8_t* dst = NativeStringDataAccess::OneByteDataStart(handle);
      dst[0] = static_cast<uint8_t>('0' + digit0);
      dst[1] = static_cast<uint8_t>('0' + digit1);
    }
    cached = one_byte;
    return one_byte;
  }

  Thread* thread_;
  Zone* zone_;
  const String& str_;
  const Object& failure_;
  const intptr_t length_;
  intptr_t pos_;
  static constexpr intptr_t kKeyCacheMaxEntries = 64;
  static constexpr intptr_t kKeyCacheMaxLength = 32;
  static constexpr intptr_t kSmallObjectMaxKeys = 8;
  static constexpr intptr_t kShapeCacheMaxEntries = 16;
  static constexpr intptr_t kValueStringOneByteMax = 32;
  String* key_cache_[kKeyCacheMaxEntries];
  intptr_t key_cache_len_;
  String* digit_key1_[10];
  String* digit_key2_[100];
  Array* shape_cache_[kShapeCacheMaxEntries];
  intptr_t shape_cache_len_;
  const TypeArguments& map_type_args_;
  Object* small_keys_[kSmallObjectMaxKeys];
  Object* small_values_[kSmallObjectMaxKeys];
};

DEFINE_NATIVE_ENTRY(Json_findStringTerminator, 0, 3) {
  GET_NON_NULL_NATIVE_ARGUMENT(String, str, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, start_obj, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, end_obj, arguments->NativeArgAt(2));

  const intptr_t start = start_obj.Value();
  const intptr_t end = end_obj.Value();
  if (start < 0 || end < start || end > str.Length()) {
    Exceptions::ThrowArgumentError(start_obj);
  }

  if (!str.IsOneByteString()) {
    NoSafepointScope no_safepoint;
    const uint16_t* data = NativeStringDataAccess::TwoByteDataStart(str);
    const intptr_t index = FindJsonStringTerminatorTwoByte(data, start, end);
    return Smi::New(index);
  }

  NoSafepointScope no_safepoint;
  const uint8_t* data = NativeStringDataAccess::OneByteDataStart(str);
  const intptr_t index = FindJsonStringTerminatorOneByte(data, start, end);
  return Smi::New(index);
}

DEFINE_NATIVE_ENTRY(Json_findStringTerminatorUtf8, 0, 3) {
  GET_NON_NULL_NATIVE_ARGUMENT(TypedDataBase, bytes, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, start_obj, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, end_obj, arguments->NativeArgAt(2));

  const intptr_t start = start_obj.Value();
  const intptr_t end = end_obj.Value();
  if (start < 0 || end < start || end > bytes.Length()) {
    Exceptions::ThrowArgumentError(start_obj);
  }
  if (bytes.ElementType() != kUint8ArrayElement) {
    Exceptions::ThrowArgumentError(bytes);
  }

  NoSafepointScope no_safepoint;
  const uint8_t* data =
      reinterpret_cast<const uint8_t*>(bytes.DataAddr(0));
  const intptr_t index = FindJsonStringTerminatorOneByte(data, start, end);
  return Smi::New(index);
}

DEFINE_NATIVE_ENTRY(Json_parseOneByteFast, 0, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(String, str, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, failure, arguments->NativeArgAt(1));

  if (!str.IsOneByteString()) return failure.ptr();

  const Object& failure_object = Object::Handle(zone, failure.ptr());
  JsonFastParser parser(thread, str, failure_object);
  return parser.Parse();
}

DEFINE_NATIVE_ENTRY(Json_parseTwoByteFast, 0, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(String, str, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, failure, arguments->NativeArgAt(1));

  if (!str.IsTwoByteString()) return failure.ptr();

  const Object& failure_object = Object::Handle(zone, failure.ptr());
  JsonFastParserTwoByte parser(thread, str, failure_object);
  return parser.Parse();
}

DEFINE_NATIVE_ENTRY(CompactHash_createMapFromKeyValueListUnsafe, 2, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, list, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, failure, arguments->NativeArgAt(1));

  Array& pair_data = Array::Handle(zone);
  intptr_t pair_len = 0;
  if (list.IsGrowableObjectArray()) {
    const GrowableObjectArray& pairs = GrowableObjectArray::Cast(list);
    pair_len = pairs.Length();
    pair_data = pairs.data();
  } else if (list.IsArray()) {
    pair_data = Array::Cast(list).ptr();
    pair_len = pair_data.Length();
  } else {
    return failure.ptr();
  }

  if ((pair_len & 1) != 0) return failure.ptr();
  for (intptr_t i = 0; i < pair_len; i += 2) {
    const Object& key_obj = Object::Handle(zone, pair_data.At(i));
    if (!key_obj.IsString()) return failure.ptr();
  }

  TypeArguments& type_args =
      TypeArguments::Handle(zone, arguments->NativeTypeArgs());
  if (!type_args.IsNull() && !type_args.IsCanonical()) {
    type_args = type_args.Canonicalize(thread);
  }
  return BuildMapFromPairs(thread, pair_data, pair_len, type_args);
}

// Return the bitwise-or of all characters in the slice from start to end.
static uint16_t CharacterLimit(const String& string,
                               intptr_t start,
                               intptr_t end) {
  ASSERT(string.IsTwoByteString());
  // Maybe do loop unrolling, and handle two uint16_t in a single uint32_t
  // operation.
  NoSafepointScope no_safepoint;
  uint16_t result = 0;
  for (intptr_t i = start; i < end; i++) {
    result |= TwoByteString::CharAt(string, i);
  }
  return result;
}

static constexpr intptr_t kLengthSize = 11;
static constexpr intptr_t kLengthMask = (1 << kLengthSize) - 1;

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

DEFINE_NATIVE_ENTRY(StringBase_joinReplaceAllResult, 0, 4) {
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
    if (!base.IsOneByteString()) {
      is_onebyte = CheckSlicesOneByte(base, matches, len);
    }
  }

  const intptr_t base_length = base.Length();
  String& result = String::Handle(zone);
  if (is_onebyte) {
    result = OneByteString::New(length, Heap::kNew);
  } else {
    result = TwoByteString::New(length, Heap::kNew);
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
  return result.ptr();
}

DEFINE_NATIVE_ENTRY(StringBase_intern, 0, 1) {
  const String& receiver =
      String::CheckedHandle(zone, arguments->NativeArgAt(0));
  return Symbols::New(thread, receiver);
}

DEFINE_NATIVE_ENTRY(OneByteString_substringUnchecked, 0, 3) {
  const String& receiver =
      String::CheckedHandle(zone, arguments->NativeArgAt(0));
  ASSERT(receiver.IsOneByteString());
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, start_obj, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, end_obj, arguments->NativeArgAt(2));

  const intptr_t start = start_obj.Value();
  const intptr_t end = end_obj.Value();
  return OneByteString::New(receiver, start, end - start, Heap::kNew);
}

DEFINE_NATIVE_ENTRY(Internal_allocateOneByteString, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, length_obj, arguments->NativeArgAt(0));
  const int64_t length = length_obj.Value();
  if ((length < 0) || (length > OneByteString::kMaxElements)) {
    // Assume that negative lengths are the result of wrapping in code in
    // string_patch.dart.
    const Instance& exception = Instance::Handle(
        thread->isolate_group()->object_store()->out_of_memory());
    Exceptions::Throw(thread, exception);
    UNREACHABLE();
  }
  return OneByteString::New(static_cast<intptr_t>(length), Heap::kNew);
}

DEFINE_NATIVE_ENTRY(Internal_allocateTwoByteString, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, length_obj, arguments->NativeArgAt(0));
  const int64_t length = length_obj.Value();
  if ((length < 0) || (length > TwoByteString::kMaxElements)) {
    // Assume that negative lengths are the result of wrapping in code in
    // string_patch.dart.
    const Instance& exception = Instance::Handle(
        thread->isolate_group()->object_store()->out_of_memory());
    Exceptions::Throw(thread, exception);
    UNREACHABLE();
  }
  return TwoByteString::New(static_cast<intptr_t>(length), Heap::kNew);
}

DEFINE_NATIVE_ENTRY(OneByteString_allocateFromOneByteList, 0, 3) {
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
  ASSERT(length >= 0);

  Heap::Space space = Heap::kNew;
  if (list.IsTypedDataBase()) {
    const TypedDataBase& array = TypedDataBase::Cast(list);
    if (array.ElementType() != kUint8ArrayElement) {
      Exceptions::ThrowArgumentError(list);
    }
    if (end > array.Length()) {
      Exceptions::ThrowArgumentError(end_obj);
    }
    return OneByteString::New(array, start, length, space);
  } else if (list.IsArray()) {
    const Array& array = Array::Cast(list);
    if (end > array.Length()) {
      Exceptions::ThrowArgumentError(end_obj);
    }
    String& string = String::Handle(OneByteString::New(length, space));
    for (int i = 0; i < length; i++) {
      intptr_t value = Smi::Value(static_cast<SmiPtr>(array.At(start + i)));
      OneByteString::SetCharAt(string, i, value);
    }
    return string.ptr();
  } else if (list.IsGrowableObjectArray()) {
    const GrowableObjectArray& array = GrowableObjectArray::Cast(list);
    if (end > array.Length()) {
      Exceptions::ThrowArgumentError(end_obj);
    }
    String& string = String::Handle(OneByteString::New(length, space));
    for (int i = 0; i < length; i++) {
      intptr_t value = Smi::Value(static_cast<SmiPtr>(array.At(start + i)));
      OneByteString::SetCharAt(string, i, value);
    }
    return string.ptr();
  }
  UNREACHABLE();
  return Object::null();
}

DEFINE_NATIVE_ENTRY(Internal_writeIntoOneByteString, 0, 3) {
  GET_NON_NULL_NATIVE_ARGUMENT(String, receiver, arguments->NativeArgAt(0));
  ASSERT(receiver.IsOneByteString());
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, index_obj, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, code_point_obj, arguments->NativeArgAt(2));
  OneByteString::SetCharAt(receiver, index_obj.Value(),
                           code_point_obj.Value() & 0xFF);
  return Object::null();
}

DEFINE_NATIVE_ENTRY(Internal_writeIntoTwoByteString, 0, 3) {
  GET_NON_NULL_NATIVE_ARGUMENT(String, receiver, arguments->NativeArgAt(0));
  ASSERT(receiver.IsTwoByteString());
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, index_obj, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, code_point_obj, arguments->NativeArgAt(2));
  TwoByteString::SetCharAt(receiver, index_obj.Value(),
                           code_point_obj.Value() & 0xFFFF);
  return Object::null();
}

DEFINE_NATIVE_ENTRY(Internal_decodeUtf8ToOneByteString, 0, 4) {
  GET_NON_NULL_NATIVE_ARGUMENT(TypedDataBase, bytes, arguments->NativeArgAt(0));
  if (bytes.ElementType() != kUint8ArrayElement) {
    Exceptions::ThrowArgumentError(bytes);
  }
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, start_obj, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, end_obj, arguments->NativeArgAt(2));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, size_obj, arguments->NativeArgAt(3));

  const intptr_t start = start_obj.Value();
  const intptr_t end = end_obj.Value();
  const intptr_t length = size_obj.Value();
  if ((start < 0) || (end < start) || (end > bytes.Length())) {
    Exceptions::ThrowArgumentError(end_obj);
  }
  if ((length < 0) || (length > OneByteString::kMaxElements)) {
    const Instance& exception = Instance::Handle(
        thread->isolate_group()->object_store()->out_of_memory());
    Exceptions::Throw(thread, exception);
    UNREACHABLE();
  }

  const String& result =
      String::Handle(OneByteString::New(length, Heap::kNew));
  if (length == 0) {
    return result.ptr();
  }

  NoSafepointScope no_safepoint;
  const uint8_t* src =
      reinterpret_cast<const uint8_t*>(bytes.DataAddr(start));
  const intptr_t byte_len = end - start;
  if (!Utf8::DecodeToLatin1(
          src, byte_len, NativeStringDataAccess::OneByteDataStart(result),
          length)) {
    return Object::null();
  }
  return result.ptr();
}

DEFINE_NATIVE_ENTRY(Internal_decodeUtf8ToTwoByteString, 0, 4) {
  GET_NON_NULL_NATIVE_ARGUMENT(TypedDataBase, bytes, arguments->NativeArgAt(0));
  if (bytes.ElementType() != kUint8ArrayElement) {
    Exceptions::ThrowArgumentError(bytes);
  }
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, start_obj, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, end_obj, arguments->NativeArgAt(2));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, size_obj, arguments->NativeArgAt(3));

  const intptr_t start = start_obj.Value();
  const intptr_t end = end_obj.Value();
  const intptr_t length = size_obj.Value();
  if ((start < 0) || (end < start) || (end > bytes.Length())) {
    Exceptions::ThrowArgumentError(end_obj);
  }
  if ((length < 0) || (length > TwoByteString::kMaxElements)) {
    const Instance& exception = Instance::Handle(
        thread->isolate_group()->object_store()->out_of_memory());
    Exceptions::Throw(thread, exception);
    UNREACHABLE();
  }

  const String& result =
      String::Handle(TwoByteString::New(length, Heap::kNew));
  if (length == 0) {
    return result.ptr();
  }

  NoSafepointScope no_safepoint;
  const uint8_t* src =
      reinterpret_cast<const uint8_t*>(bytes.DataAddr(start));
  const intptr_t byte_len = end - start;
  if (!Utf8::DecodeToUTF16(
          src, byte_len, NativeStringDataAccess::TwoByteDataStart(result),
          length)) {
    return Object::null();
  }
  return result.ptr();
}

DEFINE_NATIVE_ENTRY(TwoByteString_allocateFromTwoByteList, 0, 3) {
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
  if (list.IsTypedDataBase()) {
    const TypedDataBase& array = TypedDataBase::Cast(list);
    if (array.ElementType() != kUint16ArrayElement) {
      Exceptions::ThrowArgumentError(list);
    }
    if (end > array.Length()) {
      Exceptions::ThrowArgumentError(end_obj);
    }
    return TwoByteString::New(array, start * sizeof(uint16_t), length, space);
  } else if (list.IsArray()) {
    const Array& array = Array::Cast(list);
    if (end > array.Length()) {
      Exceptions::ThrowArgumentError(end_obj);
    }
    const String& string =
        String::Handle(zone, TwoByteString::New(length, space));
    for (int i = 0; i < length; i++) {
      intptr_t value = Smi::Value(static_cast<SmiPtr>(array.At(start + i)));
      TwoByteString::SetCharAt(string, i, value);
    }
    return string.ptr();
  } else if (list.IsGrowableObjectArray()) {
    const GrowableObjectArray& array = GrowableObjectArray::Cast(list);
    if (end > array.Length()) {
      Exceptions::ThrowArgumentError(end_obj);
    }
    const String& string =
        String::Handle(zone, TwoByteString::New(length, space));
    for (int i = 0; i < length; i++) {
      intptr_t value = Smi::Value(static_cast<SmiPtr>(array.At(start + i)));
      TwoByteString::SetCharAt(string, i, value);
    }
    return string.ptr();
  }
  UNREACHABLE();
  return Object::null();
}

DEFINE_NATIVE_ENTRY(String_getHashCode, 0, 1) {
  const String& receiver =
      String::CheckedHandle(zone, arguments->NativeArgAt(0));
  intptr_t hash_val = receiver.Hash();
  ASSERT(hash_val > 0);
  ASSERT(Smi::IsValid(hash_val));
  return Smi::New(hash_val);
}

DEFINE_NATIVE_ENTRY(String_getLength, 0, 1) {
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

DEFINE_NATIVE_ENTRY(String_charAt, 0, 2) {
  const String& receiver =
      String::CheckedHandle(zone, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, index, arguments->NativeArgAt(1));
  uint16_t value = StringValueAt(receiver, index);
  return Symbols::FromCharCode(thread, static_cast<int32_t>(value));
}

DEFINE_NATIVE_ENTRY(String_concat, 0, 2) {
  const String& receiver =
      String::CheckedHandle(zone, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(String, b, arguments->NativeArgAt(1));
  return String::Concat(receiver, b);
}

DEFINE_NATIVE_ENTRY(String_toLowerCase, 0, 1) {
  const String& receiver =
      String::CheckedHandle(zone, arguments->NativeArgAt(0));
  ASSERT(!receiver.IsNull());
  return String::ToLowerCase(receiver);
}

DEFINE_NATIVE_ENTRY(String_toUpperCase, 0, 1) {
  const String& receiver =
      String::CheckedHandle(zone, arguments->NativeArgAt(0));
  ASSERT(!receiver.IsNull());
  return String::ToUpperCase(receiver);
}

DEFINE_NATIVE_ENTRY(String_concatRange, 0, 3) {
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
    strings ^= argument.ptr();
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

DEFINE_NATIVE_ENTRY(StringBuffer_createStringFromUint16Array, 0, 3) {
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
  return result.ptr();
}

}  // namespace dart
