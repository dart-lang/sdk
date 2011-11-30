// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/debugger.h"

#include "vm/code_patcher.h"
#include "vm/compiler.h"
#include "vm/flags.h"
#include "vm/globals.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/os.h"
#include "vm/stub_code.h"
#include "vm/visitor.h"


namespace dart {

DEFINE_FLAG(bool, debugger, false, "Debug breakpoint at main");
DEFINE_FLAG(charp, bpt, NULL, "Debug breakpoint at <func>");


class Breakpoint {
 public:
  Breakpoint(const Function& func, intptr_t pc_desc_index, uword pc)
      : function_(func.raw()),
        pc_desc_index_(pc_desc_index),
        pc_(pc),
        next_(NULL) {
  }

  RawFunction* function() const { return function_; }
  uword pc() const { return pc_; }

  void set_next(Breakpoint* value) { next_ = value; }
  Breakpoint* next() const { return this->next_; }

  void VisitObjectPointers(ObjectPointerVisitor* visitor) {
    visitor->VisitPointer(reinterpret_cast<RawObject**>(&function_));
  }

 private:
  RawFunction* function_;
  intptr_t pc_desc_index_;
  uword pc_;
  Breakpoint* next_;
  DISALLOW_COPY_AND_ASSIGN(Breakpoint);
};


Debugger::Debugger()
    : initialized_(false),
      breakpoints_(NULL) {
}


static RawFunction* ResolveLibraryFunction(const String& fname) {
  Isolate* isolate = Isolate::Current();
  const Library& root_lib =
      Library::Handle(isolate->object_store()->root_library());
  ASSERT(!root_lib.IsNull());
  Function& function = Function::Handle();
  const Object& object = Object::Handle(root_lib.LookupObject(fname));
  if (!object.IsNull() && object.IsFunction()) {
    function ^= object.raw();
  }
  return function.raw();
}


static RawFunction* ResolveFunction(const String& class_name,
                                    const String& function_name) {
  Isolate* isolate = Isolate::Current();
  const Library& root_lib =
      Library::Handle(isolate->object_store()->root_library());
  const Class& cls = Class::Handle(root_lib.LookupClass(class_name));

  Function& function = Function::Handle();
  if (!cls.IsNull()) {
    function = cls.LookupStaticFunction(function_name);
    if (function.IsNull()) {
      function = cls.LookupDynamicFunction(function_name);
    }
  }
  return function.raw();
}



void Debugger::SetBreakpointAtEntry(const String& class_name,
                                    const String& function_name) {
  Function& func = Function::Handle();
  if (class_name.IsNull() || (class_name.Length() == 0)) {
    func = ResolveLibraryFunction(function_name);
  } else {
    func = ResolveFunction(class_name, function_name);
  }
  if (func.IsNull()) {
    OS::Print("could not find function '%s' in class '%s'\n",
      function_name.ToCString(), class_name.ToCString());
    return;
  }
  if (!func.HasCode()) {
    Compiler::CompileFunction(func);
  }
  Code& code = Code::Handle(func.code());
  ASSERT(!code.IsNull());
  PcDescriptors& desc = PcDescriptors::Handle(code.pc_descriptors());
  for (int i = 0; i < desc.Length(); i++) {
    PcDescriptors::Kind kind = desc.DescriptorKind(i);
    if (kind == PcDescriptors::kIcCall) {
      OS::Print("patching dynamic call at %p\n", desc.PC(i));
      CodePatcher::PatchInstanceCallAt(
          desc.PC(i), StubCode::BreakpointDynamicEntryPoint());
      AddBreakpoint(new Breakpoint(func, i, desc.PC(i)));
      return;
    } else if (kind == PcDescriptors::kOther) {
      if (CodePatcher::IsDartCall(desc.PC(i))) {
        OS::Print("patching static call at %p\n", desc.PC(i));
        CodePatcher::PatchStaticCallAt(
            desc.PC(i), StubCode::BreakpointStaticEntryPoint());
        AddBreakpoint(new Breakpoint(func, i, desc.PC(i)));
        return;
      }
    }
  }
  OS::Print("no breakpoint location found in function '%s'\n",
         function_name.ToCString());
}


void Debugger::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  ASSERT(visitor != NULL);
  Breakpoint* bpt = this->breakpoints_;
  while (bpt != NULL) {
    bpt->VisitObjectPointers(visitor);
    bpt = bpt->next();
  }
}


void Debugger::Initialize(Isolate* isolate) {
  if (initialized_) {
    return;
  }
  initialized_ = true;
  if (!FLAG_debugger) {
    return;
  }
  if (FLAG_bpt == NULL) {
    FLAG_bpt = "main";
  }
  String& cname = String::Handle();
  String& fname = String::Handle();
  const char* dot = strchr(FLAG_bpt, '.');
  if (dot == NULL) {
    fname = String::New(FLAG_bpt);
  } else {
    fname = String::New(dot + 1);
    cname = String::New(reinterpret_cast<const uint8_t*>(FLAG_bpt),
                        dot - FLAG_bpt);
  }
  SetBreakpointAtEntry(cname, fname);
}


Breakpoint* Debugger::GetBreakpoint(uword breakpoint_address) {
  Breakpoint* bpt = this->breakpoints_;
  while (bpt != NULL) {
    if (bpt->pc() == breakpoint_address) {
      return bpt;
    }
    bpt = bpt->next();
  }
  return NULL;
}


void Debugger::AddBreakpoint(Breakpoint* bpt) {
  ASSERT(bpt->next() == NULL);
  bpt->set_next(this->breakpoints_);
  this->breakpoints_ = bpt;
}


}  // namespace dart
