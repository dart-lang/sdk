// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_AOT_PRECOMPILER_TRACER_H_
#define RUNTIME_VM_COMPILER_AOT_PRECOMPILER_TRACER_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#include "vm/allocation.h"
#include "vm/hash_table.h"
#include "vm/symbols.h"

namespace dart {

// Forward declarations.
class Precompiler;

#if defined(DART_PRECOMPILER)
// Tracer which produces machine readable precompiler tracer, which captures
// information about all compiled functions and dependencies between them.
// See pkg/vm_snapshot_analysis/README.md for the definition of the
// format.
class PrecompilerTracer : public ZoneAllocated {
 public:
  static PrecompilerTracer* StartTracingIfRequested(Precompiler* precompiler);

  void Finalize();

  void WriteEntityRef(const Object& field) {
    Write("%" Pd ",", InternEntity(field));
  }

  void WriteFieldRef(const Field& field) { WriteEntityRef(field); }

  void WriteFunctionRef(const Function& function) { WriteEntityRef(function); }

  void WriteSelectorRef(const String& selector) {
    Write("\"S\",%" Pd ",", InternString(selector));
  }

  void WriteTableSelectorRef(intptr_t id) { Write("\"T\",%" Pd ",", id); }

  void WriteClassInstantiationRef(const Class& cls) { WriteEntityRef(cls); }

  void WriteCompileFunctionEvent(const Function& function) {
    Write("\"C\",");
    WriteEntityRef(function);
  }

 private:
  struct CString {
    const char* str;
    const intptr_t length;
    intptr_t hash;
  };

  struct StringTableTraits {
    static bool ReportStats() { return false; }
    static const char* Name() { return "StringTableTraits"; }

    static bool IsMatch(const Object& a, const Object& b) {
      return String::Cast(a).Equals(String::Cast(b));
    }

    static bool IsMatch(const CString& cstr, const Object& other) {
      const String& other_str = String::Cast(other);
      if (other_str.Hash() != cstr.hash) {
        return false;
      }

      if (other_str.Length() != cstr.length) {
        return false;
      }

      return other_str.Equals(cstr.str);
    }

    static uword Hash(const CString& cstr) { return cstr.hash; }

    static uword Hash(const Object& obj) { return String::Cast(obj).Hash(); }

    static ObjectPtr NewKey(const CString& cstr) {
      return Symbols::New(Thread::Current(), cstr.str);
    }
  };

  struct EntityTableTraits {
    static bool ReportStats() { return false; }
    static const char* Name() { return "EntityTableTraits"; }

    static bool IsMatch(const Object& a, const Object& b) {
      return a.raw() == b.raw();
    }

    static uword Hash(const Object& obj) {
      if (obj.IsFunction()) {
        return Function::Cast(obj).Hash();
      } else if (obj.IsClass()) {
        return String::HashRawSymbol(Class::Cast(obj).Name());
      } else if (obj.IsField()) {
        return String::HashRawSymbol(Field::Cast(obj).name());
      }
      return obj.GetClassId();
    }
  };

  using StringTable = UnorderedHashMap<StringTableTraits>;
  using EntityTable = UnorderedHashMap<EntityTableTraits>;

  PrecompilerTracer(Precompiler* precompiler, void* stream);

  intptr_t InternString(const CString& cstr);
  intptr_t InternString(const String& str);
  intptr_t InternEntity(const Object& obj);

  void Write(const char* format, ...) PRINTF_ATTRIBUTE(2, 3) {
    va_list va;
    va_start(va, format);
    buffer_.VPrintf(format, va);
    va_end(va);
  }

  CString NameForTrace(const Function& f);

  void WriteEntityTable();
  void WriteStringTable();

  Zone* zone_;
  Precompiler* precompiler_;
  TextBuffer buffer_;
  void* stream_;
  StringTable strings_;
  EntityTable entities_;

  Object& object_;
  Class& cls_;
};
#endif  // defined(DART_PRECOMPILER)

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_AOT_PRECOMPILER_TRACER_H_
