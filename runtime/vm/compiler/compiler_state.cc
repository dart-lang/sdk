// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/compiler_state.h"

#include <functional>

#include "vm/compiler/aot/precompiler.h"
#include "vm/compiler/backend/flow_graph_compiler.h"
#include "vm/compiler/backend/il_printer.h"
#include "vm/compiler/backend/slot.h"
#include "vm/growable_array.h"
#include "vm/scopes.h"

namespace dart {

template <typename T>
T* PutIfAbsent(Thread* thread,
               ZoneGrowableArray<T*>** array_slot,
               intptr_t index,
               std::function<T*()> create) {
  auto array = *array_slot;

  if (array == nullptr) {
    Zone* const Z = thread->zone();
    *array_slot = array = new (Z) ZoneGrowableArray<T*>(Z, index + 1);
  }

  while (array->length() <= index) {
    array->Add(nullptr);
  }

  if (array->At(index) == nullptr) {
    (*array)[index] = create();
  }
  return array->At(index);
}

LocalVariable* CompilerState::GetDummyCapturedVariable(intptr_t context_id,
                                                       intptr_t index) {
  return PutIfAbsent<LocalVariable>(
      thread(), &dummy_captured_vars_, index, [&]() {
        Zone* const Z = thread()->zone();
        const AbstractType& dynamic_type =
            AbstractType::ZoneHandle(Z, Type::DynamicType());
        const String& name = String::ZoneHandle(
            Z, Symbols::NewFormatted(thread(), ":context_var%" Pd, index));
        LocalVariable* var =
            new (Z) LocalVariable(TokenPosition::kNoSource,
                                  TokenPosition::kNoSource, name, dynamic_type);
        var->set_is_captured();
        var->set_index(VariableIndex(index));
        return var;
      });
}

const ZoneGrowableArray<const Slot*>& CompilerState::GetDummyContextSlots(
    intptr_t context_id,
    intptr_t num_context_variables) {
  return *PutIfAbsent<ZoneGrowableArray<const Slot*>>(
      thread(), &dummy_slots_, num_context_variables, [&]() {
        Zone* const Z = thread()->zone();

        auto slots =
            new (Z) ZoneGrowableArray<const Slot*>(num_context_variables);
        for (intptr_t i = 0; i < num_context_variables; i++) {
          LocalVariable* var = GetDummyCapturedVariable(context_id, i);
          slots->Add(&Slot::GetContextVariableSlotFor(thread(), *var));
        }

        return slots;
      });
}

CompilerTracing CompilerState::ShouldTrace(const Function& func) {
  return FlowGraphPrinter::ShouldPrint(func) ? CompilerTracing::kOn
                                             : CompilerTracing::kOff;
}

const Class& CompilerState::ComparableClass() {
  if (comparable_class_ == nullptr) {
    Thread* thread = Thread::Current();
    Zone* zone = thread->zone();

    // When obfuscation is enabled we need to obfuscate the name of the
    // class before looking it up.
    String& name = String::Handle(zone, Symbols::New(thread, "Comparable"));
    if (thread->isolate_group()->obfuscate()) {
      Obfuscator obfuscator(thread, Object::null_string());
      name = obfuscator.Rename(name);
    }

    const Library& lib = Library::Handle(zone, Library::CoreLibrary());
    const Class& cls = Class::ZoneHandle(zone, lib.LookupClass(name));
    ASSERT(!cls.IsNull());
    comparable_class_ = &cls;
  }
  return *comparable_class_;
}

const Function& CompilerState::StringBaseInterpolateSingle() {
  if (interpolate_single_ == nullptr) {
    Thread* thread = Thread::Current();
    Zone* zone = thread->zone();

    const Class& cls =
        Class::Handle(Library::LookupCoreClass(Symbols::StringBase()));
    ASSERT(!cls.IsNull());
    interpolate_single_ = &Function::ZoneHandle(
        zone, cls.LookupFunctionAllowPrivate(Symbols::InterpolateSingle()));
    ASSERT(!interpolate_single_->IsNull());
  }
  return *interpolate_single_;
}

const Function& CompilerState::StringBaseInterpolate() {
  if (interpolate_ == nullptr) {
    Thread* thread = Thread::Current();
    Zone* zone = thread->zone();

    const Class& cls =
        Class::Handle(Library::LookupCoreClass(Symbols::StringBase()));
    ASSERT(!cls.IsNull());
    interpolate_ = &Function::ZoneHandle(
        zone, cls.LookupFunctionAllowPrivate(Symbols::Interpolate()));
    ASSERT(!interpolate_->IsNull());
  }
  return *interpolate_;
}

void CompilerState::ReportCrash() {
  OS::PrintErr("=== Crash occurred when compiling %s in %s mode in %s pass\n",
               function() != nullptr ? function()->ToFullyQualifiedCString()
                                     : "unknown function",
               is_aot()          ? "AOT"
               : is_optimizing() ? "optimizing JIT"
                                 : "unoptimized JIT",
               pass() != nullptr ? pass()->name() : "unknown");
  if (pass_state() != nullptr && pass()->id() == CompilerPass::kGenerateCode) {
    if (pass_state()->graph_compiler->current_block() != nullptr) {
      OS::PrintErr("=== When compiling block %s\n",
                   pass_state()->graph_compiler->current_block()->ToCString());
    }
    if (pass_state()->graph_compiler->current_instruction() != nullptr) {
      OS::PrintErr(
          "=== When compiling instruction %s\n",
          pass_state()->graph_compiler->current_instruction()->ToCString());
    }
  }
  if (pass_state() != nullptr && pass_state()->flow_graph() != nullptr) {
    pass_state()->flow_graph()->Print(pass()->name());
  } else {
    OS::PrintErr("=== Flow Graph not available\n");
  }
}

}  // namespace dart
