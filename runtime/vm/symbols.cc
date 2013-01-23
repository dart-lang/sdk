// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/symbols.h"

#include "vm/handles.h"
#include "vm/handles_impl.h"
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
};

intptr_t Symbols::num_of_grows_;
intptr_t Symbols::collision_count_[kMaxCollisionBuckets];

DEFINE_FLAG(bool, dump_symbol_stats, false, "Dump symbol table statistics");


const char* Symbols::Name(SymbolId symbol) {
  ASSERT((symbol > kIllegal) && (symbol < kNullCharId));
  return names[symbol];
}


void Symbols::InitOnce(Isolate* isolate) {
  // Should only be run by the vm isolate.
  ASSERT(isolate == Dart::vm_isolate());

  if (FLAG_dump_symbol_stats) {
    num_of_grows_ = 0;
    for (intptr_t i = 0; i < kMaxCollisionBuckets; i++) {
      collision_count_[i] = 0;
    }
  }

  // Create and setup a symbol table in the vm isolate.
  SetupSymbolTable(isolate);

  // Create all predefined symbols.
  ASSERT((sizeof(names) / sizeof(const char*)) == Symbols::kNullCharId);
  ObjectStore* object_store = isolate->object_store();
  Array& symbol_table = Array::Handle();


  // First set up all the predefined string symbols.
  for (intptr_t i = 1; i < Symbols::kNullCharId; i++) {
    // The symbol_table needs to be reloaded as it might have grown in the
    // previous iteration.
    symbol_table = object_store->symbol_table();
    String* str = String::ReadOnlyHandle(isolate);
    *str = OneByteString::New(names[i], Heap::kOld);
    Add(symbol_table, *str);
    symbol_handles_[i] = str;
  }
  Object::RegisterSingletonClassNames();

  // Add Latin1 characters as Symbols, so that Symbols::FromCharCode is fast.
  for (intptr_t c = 0; c < kNumberOfOneCharCodeSymbols; c++) {
    // The symbol_table needs to be reloaded as it might have grown in the
    // previous iteration.
    symbol_table = object_store->symbol_table();
    intptr_t idx = (kNullCharId + c);
    ASSERT(idx < kMaxPredefinedId);
    ASSERT(Utf::IsLatin1(c));
    uint8_t ch = static_cast<uint8_t>(c);
    String* str = String::ReadOnlyHandle(isolate);
    *str = OneByteString::New(&ch, 1, Heap::kOld);
    Add(symbol_table, *str);
    predefined_[c] = str->raw();
    symbol_handles_[idx] = str;
  }
}


void Symbols::SetupSymbolTable(Isolate* isolate) {
  ASSERT(isolate != NULL);

  // Setup the symbol table used within the String class.
  const int initial_size = (isolate == Dart::vm_isolate()) ?
      kInitialVMIsolateSymtabSize : kInitialSymtabSize;
  const Array& array = Array::Handle(Array::New(initial_size + 1));

  // Last element contains the count of used slots.
  array.SetAt(initial_size, Smi::Handle(Smi::New(0)));
  isolate->object_store()->set_symbol_table(array);
}


intptr_t Symbols::Size(Isolate* isolate) {
  ASSERT(isolate != NULL);
  Array& symbol_table = Array::Handle(isolate,
                                      isolate->object_store()->symbol_table());
  intptr_t table_size_index = symbol_table.Length() - 1;
  dart::Smi& used = Smi::Handle();
  used ^= symbol_table.At(table_size_index);
  return used.Value();
}


void Symbols::Add(const Array& symbol_table, const String& str) {
  // Should only be run by the vm isolate.
  ASSERT(Isolate::Current() == Dart::vm_isolate());
  intptr_t hash = str.Hash();
  intptr_t index = FindIndex(symbol_table, str, 0, str.Length(), hash);
  ASSERT(symbol_table.At(index) == String::null());
  InsertIntoSymbolTable(symbol_table, str, index);
}


RawString* Symbols::New(const char* cstr) {
  ASSERT(cstr != NULL);
  intptr_t array_len = strlen(cstr);
  const uint8_t* utf8_array = reinterpret_cast<const uint8_t*>(cstr);
  return Symbols::FromUTF8(utf8_array, array_len);
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
  return NewSymbol(latin1_array, len, String::FromLatin1);
}


RawString* Symbols::FromUTF16(const uint16_t* utf16_array, intptr_t len) {
  return NewSymbol(utf16_array, len, String::FromUTF16);
}


RawString* Symbols::FromUTF32(const int32_t* utf32_array, intptr_t len) {
  return NewSymbol(utf32_array, len, String::FromUTF32);
}


template<typename CharacterType, typename CallbackType>
RawString* Symbols::NewSymbol(const CharacterType* characters,
                              intptr_t len,
                              CallbackType new_string) {
  Isolate* isolate = Isolate::Current();
  String& symbol = String::Handle(isolate, String::null());
  Array& symbol_table = Array::Handle(isolate, Array::null());

  // Calculate the String hash for this sequence of characters.
  intptr_t hash = String::Hash(characters, len);

  // First check if a symbol exists in the vm isolate for these characters.
  symbol_table = Dart::vm_isolate()->object_store()->symbol_table();
  intptr_t index = FindIndex(symbol_table, characters, len, hash);
  symbol ^= symbol_table.At(index);
  if (symbol.IsNull()) {
    // Now try in the symbol table of the current isolate.
    symbol_table = isolate->object_store()->symbol_table();
    index = FindIndex(symbol_table, characters, len, hash);
    // Since we leave enough room in the table to guarantee, that we find an
    // empty spot, index is the insertion point if symbol is null.
    symbol ^= symbol_table.At(index);
    if (symbol.IsNull()) {
      // Allocate new result string.
      symbol = (*new_string)(characters, len, Heap::kOld);
      symbol.SetHash(hash);  // Remember the calculated hash value.
      InsertIntoSymbolTable(symbol_table, symbol, index);
    }
  }
  ASSERT(symbol.IsSymbol());
  return symbol.raw();
}


template RawString* Symbols::NewSymbol(const uint8_t* characters,
                                       intptr_t len,
                                       RawString* (*new_string)(const uint8_t*,
                                                                intptr_t,
                                                                Heap::Space));
template RawString* Symbols::NewSymbol(const uint16_t* characters,
                                       intptr_t len,
                                       RawString* (*new_string)(const uint16_t*,
                                                                intptr_t,
                                                                Heap::Space));
template RawString* Symbols::NewSymbol(const int32_t* characters,
                                       intptr_t len,
                                       RawString* (*new_string)(const int32_t*,
                                                                intptr_t,
                                                                Heap::Space));


RawString* Symbols::New(const String& str) {
  if (str.IsSymbol()) {
    return str.raw();
  }
  return New(str, 0, str.Length());
}


RawString* Symbols::New(const String& str, intptr_t begin_index, intptr_t len) {
  ASSERT(begin_index >= 0);
  ASSERT(len >= 0);
  ASSERT((begin_index + len) <= str.Length());
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != Dart::vm_isolate());
  String& symbol = String::Handle(isolate, String::null());
  Array& symbol_table = Array::Handle(isolate, Array::null());

  // Calculate the String hash for this sequence of characters.
  intptr_t hash = (begin_index == 0 && len == str.Length()) ? str.Hash() :
      String::Hash(str, begin_index, len);

  // First check if a symbol exists in the vm isolate for these characters.
  symbol_table = Dart::vm_isolate()->object_store()->symbol_table();
  intptr_t index = FindIndex(symbol_table, str, begin_index, len, hash);
  symbol ^= symbol_table.At(index);
  if (symbol.IsNull()) {
    // Now try in the symbol table of the current isolate.
    symbol_table = isolate->object_store()->symbol_table();
    index = FindIndex(symbol_table, str, begin_index, len, hash);
    // Since we leave enough room in the table to guarantee, that we find an
    // empty spot, index is the insertion point if symbol is null.
    symbol ^= symbol_table.At(index);
    if (symbol.IsNull()) {
      if (str.IsOld() && begin_index == 0 && len == str.Length()) {
        // Reuse the incoming str as the symbol value.
        symbol = str.raw();
      } else {
        // Allocate a copy in old space.
        symbol = String::SubString(str, begin_index, len, Heap::kOld);
        symbol.SetHash(hash);
      }
      InsertIntoSymbolTable(symbol_table, symbol, index);
    }
  }
  ASSERT(symbol.IsSymbol());
  return symbol.raw();
}


RawString* Symbols::FromCharCode(int32_t char_code) {
  if (char_code > kMaxOneCharCodeSymbol) {
    return FromUTF32(&char_code, 1);
  }
  return predefined_[char_code];
}


void Symbols::DumpStats() {
  if (FLAG_dump_symbol_stats) {
    intptr_t table_size = 0;
    dart::Smi& used = Smi::Handle();
    Array& symbol_table = Array::Handle(Array::null());

    // First dump VM symbol table stats.
    symbol_table = Dart::vm_isolate()->object_store()->symbol_table();
    table_size = symbol_table.Length() - 1;
    used ^= symbol_table.At(table_size);
    OS::Print("VM Isolate: Number of symbols : %"Pd"\n", used.Value());
    OS::Print("VM Isolate: Symbol table capacity : %"Pd"\n", table_size);

    // Now dump regular isolate symbol table stats.
    symbol_table = Isolate::Current()->object_store()->symbol_table();
    table_size = symbol_table.Length() - 1;
    used ^= symbol_table.At(table_size);
    OS::Print("Isolate: Number of symbols : %"Pd"\n", used.Value());
    OS::Print("Isolate: Symbol table capacity : %"Pd"\n", table_size);

    // Dump overall collision and growth counts.
    OS::Print("Number of symbol table grows = %"Pd"\n", num_of_grows_);
    OS::Print("Collision counts on add and lookup :\n");
    intptr_t i = 0;
    for (i = 0; i < (kMaxCollisionBuckets - 1); i++) {
      OS::Print("  %"Pd" collisions => %"Pd"\n", i, collision_count_[i]);
    }
    OS::Print("  > %"Pd" collisions => %"Pd"\n", i, collision_count_[i]);
  }
}


void Symbols::GrowSymbolTable(const Array& symbol_table) {
  // TODO(iposva): Avoid exponential growth.
  num_of_grows_ += 1;
  intptr_t table_size = symbol_table.Length() - 1;
  intptr_t new_table_size = table_size * 2;
  Array& new_symbol_table = Array::Handle(Array::New(new_table_size + 1));
  // Copy all elements from the original symbol table to the newly allocated
  // array.
  String& element = String::Handle();
  dart::Object& new_element = Object::Handle();
  for (intptr_t i = 0; i < table_size; i++) {
    element ^= symbol_table.At(i);
    if (!element.IsNull()) {
      intptr_t hash = element.Hash();
      intptr_t index = hash % new_table_size;
      new_element = new_symbol_table.At(index);
      intptr_t num_collisions = 0;
      while (!new_element.IsNull()) {
        index = (index + 1) % new_table_size;  // Move to next element.
        new_element = new_symbol_table.At(index);
        num_collisions += 1;
      }
      if (FLAG_dump_symbol_stats) {
        if (num_collisions >= kMaxCollisionBuckets) {
          num_collisions = (kMaxCollisionBuckets - 1);
        }
        collision_count_[num_collisions] += 1;
      }
      new_symbol_table.SetAt(index, element);
    }
  }
  // Copy used count.
  new_element = symbol_table.At(table_size);
  new_symbol_table.SetAt(new_table_size, new_element);
  // Remember the new symbol table now.
  Isolate::Current()->object_store()->set_symbol_table(new_symbol_table);
}


void Symbols::InsertIntoSymbolTable(const Array& symbol_table,
                                    const String& symbol,
                                    intptr_t index) {
  intptr_t table_size = symbol_table.Length() - 1;
  symbol.SetCanonical();  // Mark object as being canonical.
  symbol_table.SetAt(index, symbol);  // Remember the new symbol.
  dart::Smi& used = Smi::Handle();
  used ^= symbol_table.At(table_size);
  intptr_t used_elements = used.Value() + 1;  // One more element added.
  used = Smi::New(used_elements);
  symbol_table.SetAt(table_size, used);  // Update used count.

  // Rehash if symbol_table is 75% full.
  if (used_elements > ((table_size / 4) * 3)) {
    GrowSymbolTable(symbol_table);
  }
}


template<typename T>
intptr_t Symbols::FindIndex(const Array& symbol_table,
                            const T* characters,
                            intptr_t len,
                            intptr_t hash) {
  // Last element of the array is the number of used elements.
  intptr_t table_size = symbol_table.Length() - 1;
  intptr_t index = hash % table_size;
  intptr_t num_collisions = 0;

  String& symbol = String::Handle();
  symbol ^= symbol_table.At(index);
  while (!symbol.IsNull() && !symbol.Equals(characters, len)) {
    index = (index + 1) % table_size;  // Move to next element.
    symbol ^= symbol_table.At(index);
    num_collisions += 1;
  }
  if (FLAG_dump_symbol_stats) {
    if (num_collisions >= kMaxCollisionBuckets) {
      num_collisions = (kMaxCollisionBuckets - 1);
    }
    collision_count_[num_collisions] += 1;
  }
  return index;  // Index of symbol if found or slot into which to add symbol.
}


template intptr_t Symbols::FindIndex(const Array& symbol_table,
                                     const uint8_t* characters,
                                     intptr_t len,
                                     intptr_t hash);
template intptr_t Symbols::FindIndex(const Array& symbol_table,
                                     const uint16_t* characters,
                                     intptr_t len,
                                     intptr_t hash);
template intptr_t Symbols::FindIndex(const Array& symbol_table,
                                     const int32_t* characters,
                                     intptr_t len,
                                     intptr_t hash);


intptr_t Symbols::FindIndex(const Array& symbol_table,
                            const String& str,
                            intptr_t begin_index,
                            intptr_t len,
                            intptr_t hash) {
  // Last element of the array is the number of used elements.
  intptr_t table_size = symbol_table.Length() - 1;
  intptr_t index = hash % table_size;
  intptr_t num_collisions = 0;

  String& symbol = String::Handle();
  symbol ^= symbol_table.At(index);
  while (!symbol.IsNull() && !symbol.Equals(str, begin_index, len)) {
    index = (index + 1) % table_size;  // Move to next element.
    symbol ^= symbol_table.At(index);
    num_collisions += 1;
  }
  if (FLAG_dump_symbol_stats) {
    if (num_collisions >= kMaxCollisionBuckets) {
      num_collisions = (kMaxCollisionBuckets - 1);
    }
    collision_count_[num_collisions] += 1;
  }
  return index;  // Index of symbol if found or slot into which to add symbol.
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
