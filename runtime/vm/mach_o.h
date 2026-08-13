// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_MACH_O_H_
#define RUNTIME_VM_MACH_O_H_

#include "platform/globals.h"

#if defined(DART_PRECOMPILER)

#include "vm/allocation.h"
#include "vm/compiler/runtime_api.h"
#include "vm/datastream.h"
#include "vm/growable_array.h"
#include "vm/so_writer.h"
#include "vm/zone.h"

namespace dart {

class MachOHeader;
class MachOSymbolTable;
class MachOWriteStream;

class MachOWriter : public SharedObjectWriter {
 public:
  MachOWriter(Zone* zone,
              BaseWriteStream* stream,
              Type type,
              const char* id,
              const char* path = nullptr,
              Dwarf* dwarf = nullptr,
              MachOWriter* object = nullptr);

#if defined(TARGET_ARCH_ARM64)
  static constexpr intptr_t kPageSize = 16 * KB;
#else
  static constexpr intptr_t kPageSize = 4 * KB;
#endif
  intptr_t page_size() const override { return kPageSize; }

  Output output() const override { return Output::MachO; }
  const MachOHeader& header() const { return header_; }

  void AddText(const char* name,
               intptr_t label,
               const uint8_t* bytes,
               intptr_t size,
               const ZoneGrowableArray<Relocation>* relocations,
               const ZoneGrowableArray<SymbolData>* symbol) override;
  void AddROData(const char* name,
                 intptr_t label,
                 const uint8_t* bytes,
                 intptr_t size,
                 const ZoneGrowableArray<Relocation>* relocations,
                 const ZoneGrowableArray<SymbolData>* symbols) override;

  void Finalize() override;

  void AssertConsistency(const SharedObjectWriter* debug) const override;

  const MachOWriter* AsMachOWriter() const override { return this; }

 private:
  static void AssertConsistency(const MachOWriter* snapshot,
                                const MachOWriter* debug_info);

  MachOWriter* const object_writer_;
  MachOHeader& header_;
};

}  // namespace dart

#endif  // DART_PRECOMPILER

#endif  // RUNTIME_VM_MACH_O_H_
