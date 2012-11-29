// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/code_observers.h"

#include "vm/dart.h"
#include "vm/debuginfo.h"
#include "vm/flags.h"
#include "vm/isolate.h"
#include "vm/os.h"
#include "vm/vtune.h"
#include "vm/zone.h"

namespace dart {

DEFINE_FLAG(bool, generate_gdb_symbols, false,
    "Generate symbols of generated dart functions for debugging with GDB");

intptr_t CodeObservers::observers_length_ = 0;
CodeObserver** CodeObservers::observers_ = NULL;


void CodeObservers::Register(CodeObserver* observer) {
  observers_length_++;
  observers_ = reinterpret_cast<CodeObserver**>(
      realloc(observers_, sizeof(observer) * observers_length_));
  if (observers_ == NULL) {
    FATAL("failed to grow code observers array");
  }
  observers_[observers_length_ - 1] = observer;
}


void CodeObservers::NotifyAll(const char* name,
                              uword base,
                              uword prologue_offset,
                              uword size,
                              bool optimized) {
  ASSERT(!AreActive() || (strlen(name) != 0));
  for (intptr_t i = 0; i < observers_length_; i++) {
    if (observers_[i]->IsActive()) {
      observers_[i]->Notify(name, base, prologue_offset, size, optimized);
    }
  }
}


bool CodeObservers::AreActive() {
  for (intptr_t i = 0; i < observers_length_; i++) {
    if (observers_[i]->IsActive()) return true;
  }
  return false;
}


class PerfCodeObserver : public CodeObserver {
 public:
  virtual bool IsActive() const {
    return Dart::perf_events_writer() != NULL;
  }

  virtual void Notify(const char* name,
                      uword base,
                      uword prologue_offset,
                      uword size,
                      bool optimized) {
    Dart_FileWriterFunction perf_events_writer = Dart::perf_events_writer();
    ASSERT(perf_events_writer != NULL);

    const char* format = "%"Px" %"Px" %s%s\n";
    const char* marker = optimized ? "*" : "";
    intptr_t len = OS::SNPrint(NULL, 0, format, base, size, marker, name);
    char* buffer = Isolate::Current()->current_zone()->Alloc<char>(len + 1);
    OS::SNPrint(buffer, len + 1, format, base, size, marker, name);
    (*perf_events_writer)(buffer, len);
  }
};


class PprofCodeObserver : public CodeObserver {
 public:
  virtual bool IsActive() const {
    return Dart::pprof_symbol_generator() != NULL;
  }

  virtual void Notify(const char* name,
                      uword base,
                      uword prologue_offset,
                      uword size,
                      bool optimized) {
    DebugInfo* pprof_symbol_generator = Dart::pprof_symbol_generator();
    ASSERT(pprof_symbol_generator != NULL);
    pprof_symbol_generator->AddCode(base, size);
    pprof_symbol_generator->AddCodeRegion(name, base, size);
  }
};


class GdbCodeObserver : public CodeObserver {
 public:
  virtual bool IsActive() const {
    return FLAG_generate_gdb_symbols;
  }

  virtual void Notify(const char* name,
                      uword base,
                      uword prologue_offset,
                      uword size,
                      bool optimized) {
    if (prologue_offset > 0) {
      // In order to ensure that gdb sees the first instruction of a function
      // as the prologue sequence we register two symbols for the cases when
      // the prologue sequence is not the first instruction:
      // <name>_entry is used for code preceding the prologue sequence.
      // <name> for rest of the code (first instruction is prologue sequence).
      const char* kFormat = "%s_%s";
      intptr_t len = OS::SNPrint(NULL, 0, kFormat, name, "entry");
      char* pname = Isolate::Current()->current_zone()->Alloc<char>(len + 1);
      OS::SNPrint(pname, (len + 1), kFormat, name, "entry");
      DebugInfo::RegisterSection(pname, base, size);
      DebugInfo::RegisterSection(name,
                                 (base + prologue_offset),
                                 (size - prologue_offset));
    } else {
      DebugInfo::RegisterSection(name, base, size);
    }
  }
};


void CodeObservers::InitOnce() {
  Register(new PerfCodeObserver);
  Register(new PprofCodeObserver);
  Register(new GdbCodeObserver);
#if defined(DART_VTUNE_SUPPORT)
  Register(new VTuneCodeObserver);
#endif
}


}  // namespace dart
