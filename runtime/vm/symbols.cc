// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/symbols.h"

#include "vm/handles.h"
#include "vm/handles_impl.h"
#include "vm/hash_table.h"
#include "vm/isolate.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/raw_object.h"
#include "vm/snapshot_ids.h"
#include "vm/unicode.h"
#include "vm/visitor.h"

namespace dart {

RawString* Symbols::predefined_[Symbols::kNumberOfOneCharCodeSymbols];
String* Symbols::symbol_handles_[Symbols::kMaxPredefinedId];

static const char* names[] = {
  NULL,

#define DEFINE_SYMBOL_LITERAL(symbol, literal)                                 \
  literal,
PREDEFINED_SYMBOLS_LIST(DEFINE_SYMBOL_LITERAL)
#undef DEFINE_SYMBOL_LITERAL

  "",  // matches kKwTableStart.

#define DEFINE_KEYWORD_SYMBOL_INDEX(t, s, p, a)                                \
  s,
  DART_KEYWORD_LIST(DEFINE_KEYWORD_SYMBOL_INDEX)
#undef DEFINE_KEYWORD_SYMBOL_INDEX
};

DEFINE_FLAG(bool, dump_symbol_stats, false, "Dump symbol table statistics");


RawString* StringFrom(const uint8_t* data, intptr_t len, Heap::Space space) {
  return String::FromLatin1(data, len, space);
}
RawString* StringFrom(const uint16_t* data, intptr_t len, Heap::Space space) {
  return String::FromUTF16(data, len, space);
}
RawString* StringFrom(const int32_t* data, intptr_t len, Heap::Space space) {
  return String::FromUTF32(data, len, space);
}


template<typename CharType>
class CharArray {
 public:
  CharArray(const CharType* data, intptr_t len)
      : data_(data), len_(len) {
    hash_ = String::Hash(data, len);
  }
  RawString* ToSymbol() const {
    String& result = String::Handle(StringFrom(data_, len_, Heap::kOld));
    result.SetCanonical();
    result.SetHash(hash_);
    return result.raw();
  }
  bool Equals(const String& other) const {
    return other.Equals(data_, len_);
  }
  intptr_t Hash() const { return hash_; }
 private:
  const CharType* data_;
  intptr_t len_;
  intptr_t hash_;
};
typedef CharArray<uint8_t> Latin1Array;
typedef CharArray<uint16_t> UTF16Array;
typedef CharArray<int32_t> UTF32Array;


class StringSlice {
 public:
  StringSlice(const String& str, intptr_t begin_index, intptr_t length)
      : str_(str), begin_index_(begin_index), len_(length) {
    hash_ = is_all() ? str.Hash() : String::Hash(str, begin_index, length);
  }
  RawString* ToSymbol() const;
  bool Equals(const String& other) const {
    return other.Equals(str_, begin_index_, len_);
  }
  intptr_t Hash() const { return hash_; }
 private:
  bool is_all() const { return begin_index_ == 0 && len_ == str_.Length(); }
  const String& str_;
  intptr_t begin_index_;
  intptr_t len_;
  intptr_t hash_;
};


RawString* StringSlice::ToSymbol() const {
  if (is_all() && str_.IsOld()) {
    str_.SetCanonical();
    return str_.raw();
  } else {
    String& result = String::Handle(
        String::SubString(str_, begin_index_, len_, Heap::kOld));
    result.SetCanonical();
    result.SetHash(hash_);
    return result.raw();
  }
}


class ConcatString {
 public:
  ConcatString(const String& str1, const String& str2)
      : str1_(str1), str2_(str2), hash_(String::HashConcat(str1, str2)) {}
  RawString* ToSymbol() const;
  bool Equals(const String& other) const {
    return other.EqualsConcat(str1_, str2_);
  }
  intptr_t Hash() const { return hash_; }
 private:
  const String& str1_;
  const String& str2_;
  intptr_t hash_;
};


RawString* ConcatString::ToSymbol() const {
  String& result = String::Handle(String::Concat(str1_, str2_, Heap::kOld));
  result.SetCanonical();
  result.SetHash(hash_);
  return result.raw();
}


class SymbolTraits {
 public:
  static bool IsMatch(const Object& a, const Object& b) {
    return String::Cast(a).Equals(String::Cast(b));
  }
  template<typename CharType>
  static bool IsMatch(const CharArray<CharType>& array, const Object& obj) {
    return array.Equals(String::Cast(obj));
  }
  static bool IsMatch(const StringSlice& slice, const Object& obj) {
    return slice.Equals(String::Cast(obj));
  }
  static bool IsMatch(const ConcatString& concat, const Object& obj) {
    return concat.Equals(String::Cast(obj));
  }
  static uword Hash(const Object& key) {
    return String::Cast(key).Hash();
  }
  template<typename CharType>
  static uword Hash(const CharArray<CharType>& array) {
    return array.Hash();
  }
  static uword Hash(const StringSlice& slice) {
    return slice.Hash();
  }
  static uword Hash(const ConcatString& concat) {
    return concat.Hash();
  }
  template<typename CharType>
  static RawObject* NewKey(const CharArray<CharType>& array) {
    return array.ToSymbol();
  }
  static RawObject* NewKey(const StringSlice& slice) {
    return slice.ToSymbol();
  }
  static RawObject* NewKey(const ConcatString& concat) {
    return concat.ToSymbol();
  }
};
typedef UnorderedHashSet<SymbolTraits> SymbolTable;


const char* Symbols::Name(SymbolId symbol) {
  ASSERT((symbol > kIllegal) && (symbol < kNullCharId));
  return names[symbol];
}


const String& Symbols::Keyword(Token::Kind keyword) {
  const int kw_index = keyword - Token::kFirstKeyword;
  ASSERT((0 <= kw_index) && (kw_index < Token::kNumKeywords));
  // First keyword symbol is in symbol_handles_[kKwTableStart + 1].
  const intptr_t keyword_id = Symbols::kKwTableStart + 1 + kw_index;
  ASSERT(symbol_handles_[keyword_id] != NULL);
  return *symbol_handles_[keyword_id];
}


void Symbols::InitOnce(Isolate* vm_isolate) {
  // Should only be run by the vm isolate.
  ASSERT(Isolate::Current() == Dart::vm_isolate());
  ASSERT(vm_isolate == Dart::vm_isolate());
  Zone* zone = Thread::Current()->zone();

  // Create and setup a symbol table in the vm isolate.
  SetupSymbolTable(vm_isolate);

  // Create all predefined symbols.
  ASSERT((sizeof(names) / sizeof(const char*)) == Symbols::kNullCharId);

  SymbolTable table(zone, vm_isolate->object_store()->symbol_table());

  // First set up all the predefined string symbols.
  // Create symbols for language keywords. Some keywords are equal to
  // symbols we already created, so use New() instead of Add() to ensure
  // that the symbols are canonicalized.
  for (intptr_t i = 1; i < Symbols::kNullCharId; i++) {
    String* str = String::ReadOnlyHandle();
    *str = OneByteString::New(names[i], Heap::kOld);
    str->Hash();
    str->SetCanonical();
    bool present = table.Insert(*str);
    ASSERT(!present);
    symbol_handles_[i] = str;
  }

  // Add Latin1 characters as Symbols, so that Symbols::FromCharCode is fast.
  for (intptr_t c = 0; c < kNumberOfOneCharCodeSymbols; c++) {
    intptr_t idx = (kNullCharId + c);
    ASSERT(idx < kMaxPredefinedId);
    ASSERT(Utf::IsLatin1(c));
    uint8_t ch = static_cast<uint8_t>(c);
    String* str = String::ReadOnlyHandle();
    *str = OneByteString::New(&ch, 1, Heap::kOld);
    str->Hash();
    str->SetCanonical();
    bool present = table.Insert(*str);
    ASSERT(!present);
    predefined_[c] = str->raw();
    symbol_handles_[idx] = str;
  }

  vm_isolate->object_store()->set_symbol_table(table.Release());
}


void Symbols::InitOnceFromSnapshot(Isolate* vm_isolate) {
  // Should only be run by the vm isolate.
  ASSERT(Isolate::Current() == Dart::vm_isolate());
  ASSERT(vm_isolate == Dart::vm_isolate());
  Zone* zone = Thread::Current()->zone();

  SymbolTable table(zone, vm_isolate->object_store()->symbol_table());

  // Lookup all the predefined string symbols and language keyword symbols
  // and cache them in the read only handles for fast access.
  for (intptr_t i = 1; i < Symbols::kNullCharId; i++) {
    String* str = String::ReadOnlyHandle();
    const unsigned char* name =
        reinterpret_cast<const unsigned char*>(names[i]);
    *str ^= table.GetOrNull(Latin1Array(name, strlen(names[i])));
    ASSERT(!str->IsNull());
    ASSERT(str->HasHash());
    ASSERT(str->IsCanonical());
    symbol_handles_[i] = str;
  }

  // Lookup Latin1 character Symbols and cache them in read only handles,
  // so that Symbols::FromCharCode is fast.
  for (intptr_t c = 0; c < kNumberOfOneCharCodeSymbols; c++) {
    intptr_t idx = (kNullCharId + c);
    ASSERT(idx < kMaxPredefinedId);
    ASSERT(Utf::IsLatin1(c));
    uint8_t ch = static_cast<uint8_t>(c);
    String* str = String::ReadOnlyHandle();
    *str ^= table.GetOrNull(Latin1Array(&ch, 1));
    ASSERT(!str->IsNull());
    ASSERT(str->HasHash());
    ASSERT(str->IsCanonical());
    predefined_[c] = str->raw();
    symbol_handles_[idx] = str;
  }

  vm_isolate->object_store()->set_symbol_table(table.Release());
}


void Symbols::AddPredefinedSymbolsToIsolate() {
  // Should only be run by regular Dart isolates.
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  Zone* zone = thread->zone();
  ASSERT(isolate != Dart::vm_isolate());
  String& str = String::Handle(zone);

  SymbolTable table(zone, isolate->object_store()->symbol_table());

  // Set up all the predefined string symbols and create symbols for
  // language keywords.
  for (intptr_t i = 1; i < Symbols::kNullCharId; i++) {
    str = OneByteString::New(names[i], Heap::kOld);
    str.Hash();
    str.SetCanonical();
    bool present = table.Insert(str);
    ASSERT(!present);
  }

  // Add Latin1 characters as Symbols, so that Symbols::FromCharCode is fast.
  for (intptr_t c = 0; c < kNumberOfOneCharCodeSymbols; c++) {
    intptr_t idx = (kNullCharId + c);
    ASSERT(idx < kMaxPredefinedId);
    ASSERT(Utf::IsLatin1(c));
    uint8_t ch = static_cast<uint8_t>(c);
    str = OneByteString::New(&ch, 1, Heap::kOld);
    str.Hash();
    str.SetCanonical();
    bool present = table.Insert(str);
    ASSERT(!present);
  }

  isolate->object_store()->set_symbol_table(table.Release());
}


void Symbols::SetupSymbolTable(Isolate* isolate) {
  ASSERT(isolate != NULL);

  // Setup the symbol table used within the String class.
  const intptr_t initial_size = (isolate == Dart::vm_isolate()) ?
      kInitialVMIsolateSymtabSize : kInitialSymtabSize;
  Array& array =
      Array::Handle(HashTables::New<SymbolTable>(initial_size, Heap::kOld));
  isolate->object_store()->set_symbol_table(array);
}


void Symbols::GetStats(Isolate* isolate, intptr_t* size, intptr_t* capacity) {
  ASSERT(isolate != NULL);
  SymbolTable table(isolate->object_store()->symbol_table());
  *size = table.NumOccupied();
  *capacity = table.NumEntries();
  table.Release();
}


RawString* Symbols::New(const char* cstr, intptr_t len) {
  ASSERT((cstr != NULL) && (len >= 0));
  const uint8_t* utf8_array = reinterpret_cast<const uint8_t*>(cstr);
  return Symbols::FromUTF8(utf8_array, len);
}


RawString* Symbols::FromUTF8(const uint8_t* utf8_array, intptr_t array_len) {
  if (array_len == 0 || utf8_array == NULL) {
    return FromLatin1(reinterpret_cast<uint8_t*>(NULL), 0);
  }
  Utf8::Type type;
  intptr_t len = Utf8::CodeUnitCount(utf8_array, array_len, &type);
  ASSERT(len != 0);
  Zone* zone = Thread::Current()->zone();
  if (type == Utf8::kLatin1) {
    uint8_t* characters = zone->Alloc<uint8_t>(len);
    Utf8::DecodeToLatin1(utf8_array, array_len, characters, len);
    return FromLatin1(characters, len);
  }
  ASSERT((type == Utf8::kBMP) || (type == Utf8::kSupplementary));
  uint16_t* characters = zone->Alloc<uint16_t>(len);
  Utf8::DecodeToUTF16(utf8_array, array_len, characters, len);
  return FromUTF16(characters, len);
}


RawString* Symbols::FromLatin1(const uint8_t* latin1_array, intptr_t len) {
  return NewSymbol(Latin1Array(latin1_array, len));
}


RawString* Symbols::FromUTF16(const uint16_t* utf16_array, intptr_t len) {
  return NewSymbol(UTF16Array(utf16_array, len));
}


RawString* Symbols::FromUTF32(const int32_t* utf32_array, intptr_t len) {
  return NewSymbol(UTF32Array(utf32_array, len));
}


RawString* Symbols::FromConcat(const String& str1, const String& str2) {
  if (str1.Length() == 0) {
    return New(str2);
  } else if (str2.Length() == 0) {
    return New(str1);
  } else {
    return NewSymbol(ConcatString(str1, str2));
  }
}


// TODO(srdjan): If this becomes performance critical code, consider looking
// up symbol from hash of pieces instead of concatenating them first into
// a string.
RawString* Symbols::FromConcatAll(
    const GrowableHandlePtrArray<const String>& strs) {
  const intptr_t strs_length = strs.length();
  GrowableArray<intptr_t> lengths(strs_length);

  intptr_t len_sum = 0;
  const intptr_t kOneByteChar = 1;
  intptr_t char_size = kOneByteChar;

  for (intptr_t i = 0; i < strs_length; i++) {
    const String& str = strs[i];
    const intptr_t str_len = str.Length();
    if ((String::kMaxElements - len_sum) < str_len) {
      Exceptions::ThrowOOM();
      UNREACHABLE();
    }
    len_sum += str_len;
    lengths.Add(str_len);
    char_size = Utils::Maximum(char_size, str.CharSize());
  }
  const bool is_one_byte_string = char_size == kOneByteChar;

  Zone* zone = Thread::Current()->zone();
  if (is_one_byte_string) {
    uint8_t* buffer = zone->Alloc<uint8_t>(len_sum);
    const uint8_t* const orig_buffer = buffer;
    for (intptr_t i = 0; i < strs_length; i++) {
      NoSafepointScope no_safepoint;
      intptr_t str_len = lengths[i];
      if (str_len > 0) {
        const String& str = strs[i];
        ASSERT(str.IsOneByteString() || str.IsExternalOneByteString());
        const uint8_t* src_p = str.IsOneByteString() ?
            OneByteString::CharAddr(str, 0) :
            ExternalOneByteString::CharAddr(str, 0);
        memmove(buffer, src_p, str_len);
        buffer += str_len;
      }
    }
    ASSERT(len_sum == buffer - orig_buffer);
    return Symbols::FromLatin1(orig_buffer, len_sum);
  } else {
    uint16_t* buffer = zone->Alloc<uint16_t>(len_sum);
    const uint16_t* const orig_buffer = buffer;
    for (intptr_t i = 0; i < strs_length; i++) {
      NoSafepointScope no_safepoint;
      intptr_t str_len = lengths[i];
      if (str_len > 0) {
        const String& str = strs[i];
        if (str.IsTwoByteString()) {
          memmove(buffer, TwoByteString::CharAddr(str, 0), str_len * 2);
        } else if (str.IsExternalTwoByteString()) {
          memmove(buffer, ExternalTwoByteString::CharAddr(str, 0), str_len * 2);
        } else {
          // One-byte to two-byte string copy.
          ASSERT(str.IsOneByteString() || str.IsExternalOneByteString());
          const uint8_t* src_p = str.IsOneByteString() ?
              OneByteString::CharAddr(str, 0) :
              ExternalOneByteString::CharAddr(str, 0);
          for (int n = 0; n < str_len; n++) {
            buffer[n] = src_p[n];
          }
        }
        buffer += str_len;
      }
    }
    ASSERT(len_sum == buffer - orig_buffer);
    return Symbols::FromUTF16(orig_buffer, len_sum);
  }
}


// StringType can be StringSlice, ConcatString, or {Latin1,UTF16,UTF32}Array.
template<typename StringType>
RawString* Symbols::NewSymbol(const StringType& str) {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  Zone* zone = thread->zone();
  String& symbol = String::Handle(zone);
  {
    Isolate* vm_isolate = Dart::vm_isolate();
    SymbolTable table(zone, vm_isolate->object_store()->symbol_table());
    symbol ^= table.GetOrNull(str);
    table.Release();
  }
  if (symbol.IsNull()) {
    SymbolTable table(zone, isolate->object_store()->symbol_table());
    symbol ^= table.InsertNewOrGet(str);
    isolate->object_store()->set_symbol_table(table.Release());
  }
  ASSERT(symbol.IsSymbol());
  ASSERT(symbol.HasHash());
  return symbol.raw();
}


template<typename StringType>
RawString* Symbols::Lookup(const StringType& str) {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  Zone* zone = thread->zone();
  String& symbol = String::Handle(zone);
  {
    Isolate* vm_isolate = Dart::vm_isolate();
    SymbolTable table(zone, vm_isolate->object_store()->symbol_table());
    symbol ^= table.GetOrNull(str);
    table.Release();
  }
  if (symbol.IsNull()) {
    SymbolTable table(zone, isolate->object_store()->symbol_table());
    symbol ^= table.GetOrNull(str);
    table.Release();
  }

  ASSERT(symbol.IsNull() || symbol.IsSymbol());
  ASSERT(symbol.IsNull() || symbol.HasHash());
  return symbol.raw();
}


RawString* Symbols::LookupFromConcat(const String& str1, const String& str2) {
  if (str1.Length() == 0) {
    return Lookup(str2);
  } else if (str2.Length() == 0) {
    return Lookup(str1);
  } else {
    return Lookup(ConcatString(str1, str2));
  }
}


RawString* Symbols::New(const String& str) {
  if (str.IsSymbol()) {
    return str.raw();
  }
  return New(str, 0, str.Length());
}


RawString* Symbols::New(const String& str, intptr_t begin_index, intptr_t len) {
  return NewSymbol(StringSlice(str, begin_index, len));
}



RawString* Symbols::NewFormatted(const char* format, ...) {
  va_list args;
  va_start(args, format);
  RawString* result = NewFormattedV(format, args);
  NoSafepointScope no_safepoint;
  va_end(args);
  return result;
}


RawString* Symbols::NewFormattedV(const char* format, va_list args) {
  va_list args_copy;
  va_copy(args_copy, args);
  intptr_t len = OS::VSNPrint(NULL, 0, format, args_copy);
  va_end(args_copy);

  Zone* zone = Thread::Current()->zone();
  char* buffer = zone->Alloc<char>(len + 1);
  OS::VSNPrint(buffer, (len + 1), format, args);

  return Symbols::New(buffer);
}


RawString* Symbols::FromCharCode(int32_t char_code) {
  if (char_code > kMaxOneCharCodeSymbol) {
    return FromUTF32(&char_code, 1);
  }
  return predefined_[char_code];
}


void Symbols::DumpStats() {
  if (FLAG_dump_symbol_stats) {
    intptr_t size = -1;
    intptr_t capacity = -1;
    // First dump VM symbol table stats.
    GetStats(Dart::vm_isolate(), &size, &capacity);
    OS::Print("VM Isolate: Number of symbols : %" Pd "\n", size);
    OS::Print("VM Isolate: Symbol table capacity : %" Pd "\n", capacity);
    // Now dump regular isolate symbol table stats.
    GetStats(Isolate::Current(), &size, &capacity);
    OS::Print("Isolate: Number of symbols : %" Pd "\n", size);
    OS::Print("Isolate: Symbol table capacity : %" Pd "\n", capacity);
    // TODO(koda): Consider recording growth and collision stats in HashTable,
    // in DEBUG mode.
  }
}


intptr_t Symbols::LookupVMSymbol(RawObject* obj) {
  for (intptr_t i = 1; i < Symbols::kMaxPredefinedId; i++) {
    if (symbol_handles_[i]->raw() == obj) {
      return (i + kMaxPredefinedObjectIds);
    }
  }
  return kInvalidIndex;
}


RawObject* Symbols::GetVMSymbol(intptr_t object_id) {
  ASSERT(IsVMSymbolId(object_id));
  intptr_t i = (object_id - kMaxPredefinedObjectIds);
  if ((i > kIllegal) && (i < Symbols::kMaxPredefinedId)) {
    return symbol_handles_[i]->raw();
  }
  return Object::null();
}

}  // namespace dart
