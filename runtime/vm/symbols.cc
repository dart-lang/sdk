// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/symbols.h"

#include "vm/isolate.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/raw_object.h"
#include "vm/snapshot_ids.h"
#include "vm/unicode.h"
#include "vm/visitor.h"

namespace dart {

RawString* Symbols::predefined_[Symbols::kMaxId];

// Turn off population of symbols in the VM symbol table, so that we
// don't find these symbols while doing a Symbols::New(...).
static const char* names[] = {
  NULL,

#define DEFINE_SYMBOL_LITERAL(symbol, literal)                                 \
  literal,
PREDEFINED_SYMBOLS_LIST(DEFINE_SYMBOL_LITERAL)
#undef DEFINE_SYMBOL_LITERAL
};


const char* Symbols::Name(intptr_t symbol) {
  ASSERT((symbol > kIllegal) && (symbol < kMaxId));
  return names[symbol];
}


void Symbols::InitOnce(Isolate* isolate) {
  // Should only be run by the vm isolate.
  ASSERT(isolate == Dart::vm_isolate());

  // Create and setup a symbol table in the vm isolate.
  SetupSymbolTable(isolate);

  // Turn off population of symbols in the VM symbol table, so that we
  // don't find these symbols while doing a Symbols::New(...).
  // Create all predefined symbols.
  ASSERT((sizeof(names) / sizeof(const char*)) == Symbols::kMaxId);
  const Array& symbol_table =
      Array::Handle(isolate->object_store()->symbol_table());
  dart::OneByteString& str = OneByteString::Handle();

  for (intptr_t i = 1; i < Symbols::kMaxId; i++) {
    str = OneByteString::New(names[i], Heap::kOld);
    Add(symbol_table, str);
    predefined_[i] = str.raw();
  }
  Object::RegisterSingletonClassNames();
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


RawString* Symbols::New(const char* str) {
  intptr_t width = 0;
  intptr_t len = Utf8::CodePointCount(str, &width);
  Zone* zone = Isolate::Current()->current_zone();
  if (len == 0) {
    return Symbols::New(reinterpret_cast<uint8_t*>(NULL), 0);
  } else if (width == 1) {
    uint8_t* characters = zone->Alloc<uint8_t>(len);
    Utf8::Decode(str, characters, len);
    return New(characters, len);
  } else if (width == 2) {
    uint16_t* characters = zone->Alloc<uint16_t>(len);
    Utf8::Decode(str, characters, len);
    return New(characters, len);
  }
  ASSERT(width == 4);
  uint32_t* characters = zone->Alloc<uint32_t>(len);
  Utf8::Decode(str, characters, len);
  return New(characters, len);
}


template<typename T>
RawString* Symbols::New(const T* characters, intptr_t len) {
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != Dart::vm_isolate());
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
      symbol = String::New(characters, len, Heap::kOld);
      symbol.SetHash(hash);  // Remember the calculated hash value.
      InsertIntoSymbolTable(symbol_table, symbol, index);
    }
  }
  ASSERT(symbol.IsSymbol());
  return symbol.raw();
}

template RawString* Symbols::New(const uint8_t* characters, intptr_t len);
template RawString* Symbols::New(const uint16_t* characters, intptr_t len);
template RawString* Symbols::New(const uint32_t* characters, intptr_t len);


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


void Symbols::GrowSymbolTable(const Array& symbol_table) {
  // TODO(iposva): Avoid exponential growth.
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
      while (!new_element.IsNull()) {
        index = (index + 1) % new_table_size;  // Move to next element.
        new_element = new_symbol_table.At(index);
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

  String& symbol = String::Handle();
  symbol ^= symbol_table.At(index);
  while (!symbol.IsNull() && !symbol.Equals(characters, len)) {
    index = (index + 1) % table_size;  // Move to next element.
    symbol ^= symbol_table.At(index);
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
                                     const uint32_t* characters,
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

  String& symbol = String::Handle();
  symbol ^= symbol_table.At(index);
  while (!symbol.IsNull() && !symbol.Equals(str, begin_index, len)) {
    index = (index + 1) % table_size;  // Move to next element.
    symbol ^= symbol_table.At(index);
  }
  return index;  // Index of symbol if found or slot into which to add symbol.
}


intptr_t Symbols::LookupVMSymbol(RawObject* obj) {
  for (intptr_t i = 1;  i < Symbols::kMaxId; i++) {
    if (predefined_[i] == obj) {
      return (i + kMaxPredefinedObjectIds);
    }
  }
  return kInvalidIndex;
}


RawObject* Symbols::GetVMSymbol(intptr_t object_id) {
  ASSERT(IsVMSymbolId(object_id));
  intptr_t i = (object_id - kMaxPredefinedObjectIds);
  return (i > 0 && i < Symbols::kMaxId) ? predefined_[i] : Object::null();
}

}  // namespace dart
