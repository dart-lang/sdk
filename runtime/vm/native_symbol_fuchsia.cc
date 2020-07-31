// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(HOST_OS_FUCHSIA)

#include "platform/memory_sanitizer.h"
#include "vm/native_symbol.h"

#include <dlfcn.h>   // NOLINT

namespace dart {

// On Fuchsia, in lieu of the ELF dynamic symbol table consumed through dladdr,
// we consumes symbols produced by //topaz/runtime/dart/profiler_symbols and
// provided to the VM by the embedder through Dart_AddSymbols. They have the
// format
//
// struct {
//    uint32_t num_entries;
//    struct {
//      uint32_t offset;
//      uint32_t size;
//      uint32_t string_table_offset;
//    } entries[num_entries];
//    const char* string_table;
// }
//
// Entries are sorted by offset. String table entries are NUL-terminated.
class NativeSymbols {
 public:
  NativeSymbols(const char* dso_name, void* buffer, size_t size)
      : next_(NULL), dso_name_(dso_name) {
    num_entries_ = *reinterpret_cast<uint32_t*>(buffer);
    entries_ =
        reinterpret_cast<Entry*>(reinterpret_cast<uint32_t*>(buffer) + 1);
    name_table_ = reinterpret_cast<const char*>(entries_ + num_entries_);
  }

  NativeSymbols* next() const { return next_; }
  void set_next(NativeSymbols* symbols) { next_ = symbols; }

  bool Lookup(const char* dso_name,
              uword dso_offset,
              uword* start_offset,
              const char** name) {
    if (strcmp(dso_name, dso_name_) != 0) {
      return false;
    }

    intptr_t lo = 0;
    intptr_t hi = num_entries_ - 1;
    while (lo <= hi) {
      intptr_t mid = (hi - lo + 1) / 2 + lo;
      ASSERT(mid >= lo);
      ASSERT(mid <= hi);
      const Entry& entry = entries_[mid];
      if (dso_offset < entry.offset) {
        hi = mid - 1;
      } else if (dso_offset >= (entry.offset + entry.size)) {
        lo = mid + 1;
      } else {
        *start_offset = entry.offset;
        *name = &name_table_[entry.name_offset];
        return true;
      }
    }

    return false;
  }

 private:
  struct Entry {
    uint32_t offset;
    uint32_t size;
    uint32_t name_offset;
  };

  NativeSymbols* next_;
  const char* const dso_name_;
  intptr_t num_entries_;
  Entry* entries_;
  const char* name_table_;

  DISALLOW_COPY_AND_ASSIGN(NativeSymbols);
};

static NativeSymbols* symbols_ = NULL;

void NativeSymbolResolver::Init() {}

void NativeSymbolResolver::Cleanup() {
  NativeSymbols* symbols = symbols_;
  symbols_ = NULL;
  while (symbols != NULL) {
    NativeSymbols* next = symbols->next();
    delete symbols;
    symbols = next;
  }
}

char* NativeSymbolResolver::LookupSymbolName(uword pc, uword* start) {
  Dl_info info;
  int r = dladdr(reinterpret_cast<void*>(pc), &info);
  if (r == 0) {
    return NULL;
  }

  auto const dso_name = info.dli_fname;
  const auto dso_base = reinterpret_cast<uword>(info.dli_fbase);
  const auto dso_offset = pc - dso_base;

  for (NativeSymbols* symbols = symbols_; symbols != NULL;
       symbols = symbols->next()) {
    uword symbol_start_offset;
    const char* symbol_name;
    if (symbols->Lookup(dso_name, dso_offset, &symbol_start_offset,
                        &symbol_name)) {
      if (start != NULL) {
        *start = symbol_start_offset + dso_base;
      }
      return strdup(symbol_name);
    }
  }

  return NULL;
}

void NativeSymbolResolver::FreeSymbolName(char* name) {
  free(name);
}

bool NativeSymbolResolver::LookupSharedObject(uword pc,
                                              uword* dso_base,
                                              char** dso_name) {
  Dl_info info;
  int r = dladdr(reinterpret_cast<void*>(pc), &info);
  if (r == 0) {
    return false;
  }
  if (dso_base != nullptr) {
    *dso_base = reinterpret_cast<uword>(info.dli_fbase);
  }
  if (dso_name != nullptr) {
    *dso_name = strdup(info.dli_fname);
  }
  return true;
}

void NativeSymbolResolver::AddSymbols(const char* dso_name,
                                      void* buffer, size_t size) {
  NativeSymbols* symbols = new NativeSymbols(dso_name, buffer, size);
  symbols->set_next(symbols_);
  symbols_ = symbols;
}

}  // namespace dart

#endif  // defined(HOST_OS_FUCHSIA)
