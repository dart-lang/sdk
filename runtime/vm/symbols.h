// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_SYMBOLS_H_
#define VM_SYMBOLS_H_

#include "vm/object.h"

namespace dart {

// Forward declarations.
class Isolate;
class ObjectPointerVisitor;

// Contains a list of frequently used strings in a canonicalized form. This
// list is kept in the vm_isolate in order to share the copy across isolates
// without having to maintain copies in each isolate.
class Symbols : public AllStatic {
 public:
  // List of strings that are pre created in the vm isolate.
  static const char* kDot;

  // Access methods for symbols stored in the vm isolate.
  static RawString* Dot() { return dot_; }

  // Initialize frequently used symbols in the vm isolate.
  static void InitOnce(Isolate* isolate);

  // Initialize and setup a symbol table for the isolate.
  static void SetupSymbolTable(Isolate* isolate);

  // Helper functions to create a symbol given a string or set of characters.
  static RawString* New(const char* str);
  template<typename T>
  static RawString* New(const T* characters, intptr_t len);
  static RawString* New(const String& str);
  static RawString* New(const String& str,
                        intptr_t begin_index,
                        intptr_t length);


 private:
  static const int kInitialSymbolTableSize = 16;

  // Add the string into the VM isolate symbol table.
  static void Add(const Array& symbol_table, const String& str);

  // Insert symbol into symbol table, growing it if necessary.
  static void InsertIntoSymbolTable(const Array& symbol_table,
                                    const String& symbol,
                                    intptr_t index);

  // Grow the symbol table.
  static void GrowSymbolTable(const Array& symbol_table);

  // Return index in symbol table if the symbol already exists or
  // return the index into which the new symbol can be added.
  template<typename T>
  static intptr_t FindIndex(const Array& symbol_table,
                            const T* characters,
                            intptr_t len,
                            intptr_t hash);
  static intptr_t FindIndex(const Array& symbol_table,
                            const String& str,
                            intptr_t begin_index,
                            intptr_t len,
                            intptr_t hash);

  // List of symbols that are stored in the vm isolate for easy access.
  static RawString* dot_;  // "." string.

  friend class SnapshotReader;

  DISALLOW_COPY_AND_ASSIGN(Symbols);
};

}  // namespace dart

#endif  // VM_SYMBOLS_H_
