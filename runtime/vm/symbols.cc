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

#define DEFINE_KEYWORD_SYMBOL_INDEX(token, chars, ignore1, ignore2)            \
  chars,
  DART_KEYWORD_LIST(DEFINE_KEYWORD_SYMBOL_INDEX)
#undef DEFINE_KEYWORD_SYMBOL_INDEX
};

DEFINE_FLAG(bool, dump_symbol_stats, false, "Dump symbol table statistics");


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


void Symbols::InitOnce(Isolate* isolate) {
  // Should only be run by the vm isolate.
  ASSERT(isolate == Dart::vm_isolate());

  // Create and setup a symbol table in the vm isolate.
  SetupSymbolTable(isolate);

  // Create all predefined symbols.
  ASSERT((sizeof(names) / sizeof(const char*)) == Symbols::kNullCharId);

  // First set up all the predefined string symbols.
  for (intptr_t i = 1; i < Symbols::kKwTableStart; i++) {
    String* str = String::ReadOnlyHandle();
    *str = OneByteString::New(names[i], Heap::kOld);
    AddToVMIsolate(*str);
    symbol_handles_[i] = str;
  }
  Object::RegisterSingletonClassNames();

  // Create symbols for language keywords. Some keywords are equal to
  // symbols we already created, so use New() instead of Add() to ensure
  // that the symbols are canonicalized.
  for (intptr_t i = Symbols::kKwTableStart; i < Symbols::kNullCharId; i++) {
    String* str = String::ReadOnlyHandle();
    *str = New(names[i]);
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
    AddToVMIsolate(*str);
    predefined_[c] = str->raw();
    symbol_handles_[idx] = str;
  }
}


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
  template<typename CharType>
  static RawObject* NewKey(const CharArray<CharType>& array) {
    return array.ToSymbol();
  }
  static RawObject* NewKey(const StringSlice& slice) {
    return slice.ToSymbol();
  }
};
typedef UnorderedHashSet<SymbolTraits> SymbolTable;


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
  SymbolTable table(Array::Handle(isolate->object_store()->symbol_table()));
  *size = table.NumOccupied();
  *capacity = table.NumEntries();
  table.Release();
}


void Symbols::AddToVMIsolate(const String& str) {
  // Should only be run by the vm isolate.
  ASSERT(Isolate::Current() == Dart::vm_isolate());
  Isolate* isolate = Dart::vm_isolate();
  Array& array = Array::Handle(isolate->object_store()->symbol_table());
  SymbolTable table(array);
  bool present = table.Insert(str);
  str.SetCanonical();
  ASSERT(!present);
  isolate->object_store()->set_symbol_table(array);
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
  Zone* zone = Isolate::Current()->current_zone();
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


// StringType can be StringSlice, Latin1Array, UTF16Array or UTF32Array.
template<typename StringType>
RawString* Symbols::NewSymbol(const StringType& str) {
  String& symbol = String::Handle();
  {
    Isolate* isolate = Dart::vm_isolate();
    Array& array = Array::Handle(isolate->object_store()->symbol_table());
    SymbolTable table(array);
    symbol ^= table.GetOrNull(str);
    table.Release();
  }
  if (symbol.IsNull()) {
    Isolate* isolate = Isolate::Current();
    Array& array = Array::Handle(isolate->object_store()->symbol_table());
    SymbolTable table(array);
    symbol ^= table.InsertNewOrGet(str);
    isolate->object_store()->set_symbol_table(array);
    table.Release();
  }
  ASSERT(symbol.IsSymbol());
  return symbol.raw();
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
