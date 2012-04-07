// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/debugger.h"

#include "vm/code_index_table.h"
#include "vm/code_generator.h"
#include "vm/code_patcher.h"
#include "vm/compiler.h"
#include "vm/dart_entry.h"
#include "vm/flags.h"
#include "vm/globals.h"
#include "vm/longjump.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/os.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"
#include "vm/visitor.h"


namespace dart {

static const bool verbose = false;


SourceBreakpoint::SourceBreakpoint(const Function& func, intptr_t token_index)
    : function_(func.raw()),
      token_index_(token_index),
      line_number_(-1),
      is_enabled_(false),
      next_(NULL) {
  ASSERT(!func.IsNull());
  ASSERT((func.token_index() <= token_index_) &&
         (token_index_ < func.end_token_index()));
}


void SourceBreakpoint::Enable() {
  is_enabled_ = true;
  Isolate::Current()->debugger()->SyncBreakpoint(this);
}


void SourceBreakpoint::Disable() {
  is_enabled_ = false;
  Isolate::Current()->debugger()->SyncBreakpoint(this);
}


RawScript* SourceBreakpoint::SourceCode() {
  const Function& func = Function::Handle(function_);
  const Class& cls = Class::Handle(func.owner());
  return cls.script();
}


RawString* SourceBreakpoint::SourceUrl() {
  const Script& script = Script::Handle(SourceCode());
  return script.url();
}


intptr_t SourceBreakpoint::LineNumber() {
  // Compute line number lazily since it causes scanning of the script.
  if (line_number_ < 0) {
    const Script& script = Script::Handle(SourceCode());
    intptr_t ignore_column;
    script.GetTokenLocation(token_index_, &line_number_, &ignore_column);
  }
  return line_number_;
}


void SourceBreakpoint::set_function(const Function& func) {
  function_ = func.raw();
}


void SourceBreakpoint::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  visitor->VisitPointer(reinterpret_cast<RawObject**>(&function_));
}



void CodeBreakpoint::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  visitor->VisitPointer(reinterpret_cast<RawObject**>(&function_));
}


ActivationFrame::ActivationFrame(uword pc, uword fp, uword sp)
    : pc_(pc), fp_(fp), sp_(sp),
      function_(Function::ZoneHandle()),
      token_index_(-1),
      line_number_(-1),
      var_descriptors_(NULL),
      desc_indices_(8) {
}


const Function& ActivationFrame::DartFunction() {
  if (function_.IsNull()) {
    ASSERT(Isolate::Current() != NULL);
    CodeIndexTable* code_index_table = Isolate::Current()->code_index_table();
    ASSERT(code_index_table != NULL);
    const Code& code = Code::Handle(code_index_table->LookupCode(pc_));
    function_ = code.function();
  }
  return function_;
}


const char* Debugger::QualifiedFunctionName(const Function& func) {
  const String& func_name = String::Handle(func.name());
  Class& func_class = Class::Handle(func.owner());
  String& class_name = String::Handle(func_class.Name());

  const char* kFormat = "%s%s%s";
  intptr_t len = OS::SNPrint(NULL, 0, kFormat,
      func_class.IsTopLevel() ? "" : class_name.ToCString(),
      func_class.IsTopLevel() ? "" : ".",
      func_name.ToCString());
  len++;  // String terminator.
  char* chars = reinterpret_cast<char*>(
      Isolate::Current()->current_zone()->Allocate(len));
  OS::SNPrint(chars, len, kFormat,
              func_class.IsTopLevel() ? "" : class_name.ToCString(),
              func_class.IsTopLevel() ? "" : ".",
              func_name.ToCString());
  return chars;
}


RawString* ActivationFrame::QualifiedFunctionName() {
  const Function& func = DartFunction();
  return String::New(Debugger::QualifiedFunctionName(func));
}


RawString* ActivationFrame::SourceUrl() {
  const Script& script = Script::Handle(SourceScript());
  return script.url();
}


RawScript* ActivationFrame::SourceScript() {
  const Function& func = DartFunction();
  const Class& cls = Class::Handle(func.owner());
  return cls.script();
}


intptr_t ActivationFrame::TokenIndex() {
  if (token_index_ < 0) {
    const Function& func = DartFunction();
    ASSERT(!func.HasOptimizedCode());
    Code& code = Code::Handle(func.unoptimized_code());
    ASSERT(!code.IsNull());
    PcDescriptors& desc = PcDescriptors::Handle(code.pc_descriptors());
    for (int i = 0; i < desc.Length(); i++) {
      if (desc.PC(i) == pc_) {
        token_index_ = desc.TokenIndex(i);
        break;
      }
    }
    ASSERT(token_index_ >= 0);
  }
  return token_index_;
}


intptr_t ActivationFrame::LineNumber() {
  // Compute line number lazily since it causes scanning of the script.
  if (line_number_ < 0) {
    const Script& script = Script::Handle(SourceScript());
    intptr_t ignore_column;
    script.GetTokenLocation(TokenIndex(), &line_number_, &ignore_column);
  }
  return line_number_;
}


void ActivationFrame::GetDescIndices() {
  if (var_descriptors_ == NULL) {
    ASSERT(!DartFunction().HasOptimizedCode());
    const Code& code = Code::Handle(DartFunction().unoptimized_code());
    var_descriptors_ =
        &LocalVarDescriptors::ZoneHandle(code.var_descriptors());
    // TODO(Hausner): Consider replacing this GrowableArray.
    GrowableArray<String*> var_names(8);
    intptr_t activation_token_pos = TokenIndex();
    intptr_t var_desc_len = var_descriptors_->Length();
    for (int cur_idx = 0; cur_idx < var_desc_len; cur_idx++) {
      ASSERT(var_names.length() == desc_indices_.length());
      intptr_t scope_id, begin_pos, end_pos;
      var_descriptors_->GetScopeInfo(cur_idx, &scope_id, &begin_pos, &end_pos);
      if ((begin_pos <= activation_token_pos) &&
          (activation_token_pos <= end_pos)) {
        // The current variable is textually in scope. Now check whether
        // there is another local variable with the same name that shadows
        // or is shadowed by this variable.
        String& var_name = String::Handle(var_descriptors_->GetName(cur_idx));
        intptr_t indices_len = desc_indices_.length();
        bool name_match_found = false;
        for (int i = 0; i < indices_len; i++) {
          if (var_name.Equals(*var_names[i])) {
            // Found two local variables with the same name. Now determine
            // which one is shadowed.
            name_match_found = true;
            intptr_t i_begin_pos, ignore;
            var_descriptors_->GetScopeInfo(
                desc_indices_[i], &ignore, &i_begin_pos, &ignore);
            if (i_begin_pos < begin_pos) {
              // The variable we found earlier is in an outer scope
              // and is shadowed by the current variable. Replace the
              // descriptor index of the previously found variable
              // with the descriptor index of the current variable.
              desc_indices_[i] = cur_idx;
            } else {
              // The variable we found earlier is in an inner scope
              // and shadows the current variable. Skip the current
              // variable. (Nothing to do.)
            }
            break;  // Stop looking for name matches.
          }
        }
        if (!name_match_found) {
          // No duplicate name found. Add the current descriptor index to the
          // list of visible variables.
          desc_indices_.Add(cur_idx);
          var_names.Add(&var_name);
        }
      }
    }
  }
}


intptr_t ActivationFrame::NumLocalVariables() {
  GetDescIndices();
  return desc_indices_.length();
}


void ActivationFrame::VariableAt(intptr_t i,
                                 String* name,
                                 intptr_t* token_pos,
                                 intptr_t* end_pos,
                                 Instance* value) {
  GetDescIndices();
  ASSERT(i < desc_indices_.length());
  ASSERT(name != NULL);
  intptr_t desc_index = desc_indices_[i];
  *name ^= var_descriptors_->GetName(desc_index);
  intptr_t scope_id;
  var_descriptors_->GetScopeInfo(desc_index, &scope_id, token_pos, end_pos);
  ASSERT(value != NULL);
  *value = GetLocalVarValue(var_descriptors_->GetSlotIndex(desc_index));
}


RawArray* ActivationFrame::GetLocalVariables() {
  GetDescIndices();
  intptr_t num_variables = desc_indices_.length();
  String& var_name = String::Handle();
  Instance& value = Instance::Handle();
  const Array& list = Array::Handle(Array::New(2 * num_variables));
  for (int i = 0; i < num_variables; i++) {
    var_name = var_descriptors_->GetName(i);
    list.SetAt(2 * i, var_name);
    value = GetLocalVarValue(var_descriptors_->GetSlotIndex(i));
    list.SetAt((2 * i) + 1, value);
  }
  return list.raw();
}


const char* ActivationFrame::ToCString() {
  const char* kFormat = "Function: '%s' url: '%s' line: %d";

  const Function& func = DartFunction();
  const String& url = String::Handle(SourceUrl());
  intptr_t line = LineNumber();
  const char* func_name = Debugger::QualifiedFunctionName(func);

  intptr_t len =
      OS::SNPrint(NULL, 0, kFormat, func_name, url.ToCString(), line);
  len++;  // String terminator.
  char* chars = reinterpret_cast<char*>(
      Isolate::Current()->current_zone()->Allocate(len));
  OS::SNPrint(chars, len, kFormat, func_name, url.ToCString(), line);
  return chars;
}


void DebuggerStackTrace::AddActivation(ActivationFrame* frame) {
  trace_.Add(frame);
}


CodeBreakpoint::CodeBreakpoint(const Function& func, intptr_t pc_desc_index)
    : function_(func.raw()),
      pc_desc_index_(pc_desc_index),
      pc_(0),
      line_number_(-1),
      is_enabled_(false),
      src_bpt_(NULL),
      next_(NULL) {
  ASSERT(!func.HasOptimizedCode());
  Code& code = Code::Handle(func.unoptimized_code());
  ASSERT(!code.IsNull());  // Function must be compiled.
  PcDescriptors& desc = PcDescriptors::Handle(code.pc_descriptors());
  ASSERT(pc_desc_index < desc.Length());
  token_index_ = desc.TokenIndex(pc_desc_index);
  ASSERT(token_index_ >= 0);
  pc_ = desc.PC(pc_desc_index);
  ASSERT(pc_ != 0);
  breakpoint_kind_ = desc.DescriptorKind(pc_desc_index);
  ASSERT((breakpoint_kind_ == PcDescriptors::kIcCall) ||
         (breakpoint_kind_ == PcDescriptors::kFuncCall) ||
         (breakpoint_kind_ == PcDescriptors::kReturn));
}


CodeBreakpoint::~CodeBreakpoint() {
  // Make sure we don't leave patched code behind.
  ASSERT(!IsEnabled());
  // Poison the data so we catch use after free errors.
#ifdef DEBUG
  function_ = Function::null();
  pc_ = 0ul;
  src_bpt_ = NULL;
  next_ = NULL;
  breakpoint_kind_ = PcDescriptors::kOther;
#endif
}


RawScript* CodeBreakpoint::SourceCode() {
  const Function& func = Function::Handle(function_);
  const Class& cls = Class::Handle(func.owner());
  return cls.script();
}


RawString* CodeBreakpoint::SourceUrl() {
  const Script& script = Script::Handle(SourceCode());
  return script.url();
}


intptr_t CodeBreakpoint::LineNumber() {
  // Compute line number lazily since it causes scanning of the script.
  if (line_number_ < 0) {
    const Script& script = Script::Handle(SourceCode());
    intptr_t ignore_column;
    script.GetTokenLocation(token_index_, &line_number_, &ignore_column);
  }
  return line_number_;
}


void CodeBreakpoint::PatchCode() {
  ASSERT(!is_enabled_);
  switch (breakpoint_kind_) {
    case PcDescriptors::kIcCall: {
      int num_args, num_named_args;
      CodePatcher::GetInstanceCallAt(pc_,
          NULL, &num_args, &num_named_args,
          &saved_bytes_.target_address_);
      CodePatcher::PatchInstanceCallAt(
          pc_, StubCode::BreakpointDynamicEntryPoint());
      break;
    }
    case PcDescriptors::kFuncCall: {
      Function& func = Function::Handle();
      CodePatcher::GetStaticCallAt(pc_, &func, &saved_bytes_.target_address_);
      CodePatcher::PatchStaticCallAt(pc_,
          StubCode::BreakpointStaticEntryPoint());
      break;
    }
    case PcDescriptors::kReturn:
      PatchFunctionReturn();
      break;
    default:
      UNREACHABLE();
  }
  is_enabled_ = true;
}


void CodeBreakpoint::RestoreCode() {
  ASSERT(is_enabled_);
  switch (breakpoint_kind_) {
    case PcDescriptors::kIcCall:
      CodePatcher::PatchInstanceCallAt(pc_, saved_bytes_.target_address_);
      break;
    case PcDescriptors::kFuncCall:
      CodePatcher::PatchStaticCallAt(pc_, saved_bytes_.target_address_);
      break;
    case PcDescriptors::kReturn:
      RestoreFunctionReturn();
      break;
    default:
      UNREACHABLE();
  }
  is_enabled_ = false;
}


void CodeBreakpoint::Enable() {
  if (!is_enabled_) {
    PatchCode();
  }
  ASSERT(is_enabled_);
}


void CodeBreakpoint::Disable() {
  if (is_enabled_) {
    RestoreCode();
  }
  ASSERT(!is_enabled_);
}


Debugger::Debugger()
    : isolate_(NULL),
      initialized_(false),
      bp_handler_(NULL),
      src_breakpoints_(NULL),
      code_breakpoints_(NULL),
      resume_action_(kContinue),
      ignore_breakpoints_(false) {
}


Debugger::~Debugger() {
  ASSERT(src_breakpoints_ == NULL);
  ASSERT(code_breakpoints_ == NULL);
}


void Debugger::Shutdown() {
  while (src_breakpoints_ != NULL) {
    SourceBreakpoint* bpt = src_breakpoints_;
    src_breakpoints_ = src_breakpoints_->next();
    delete bpt;
  }
  while (code_breakpoints_ != NULL) {
    CodeBreakpoint* bpt = code_breakpoints_;
    code_breakpoints_ = code_breakpoints_->next();
    bpt->Disable();
    delete bpt;
  }
}


bool Debugger::IsActive() {
  // TODO(hausner): The code generator uses this function to prevent
  // generation of optimized code when Dart code is being debugged.
  // This is probably not conservative enough (we could set the first
  // breakpoint after optimized code has already been produced).
  // Long-term, we need to be able to de-optimize code.
  return (src_breakpoints_ != NULL) || (code_breakpoints_ != NULL);
}


static RawFunction* ResolveLibraryFunction(
                        const Library& library,
                        const String& fname) {
  ASSERT(!library.IsNull());
  Function& function = Function::Handle();
  const Object& object = Object::Handle(library.LookupObject(fname));
  if (!object.IsNull() && object.IsFunction()) {
    function ^= object.raw();
  }
  return function.raw();
}


RawFunction* Debugger::ResolveFunction(const Library& library,
                                       const String& class_name,
                                       const String& function_name) {
  ASSERT(!library.IsNull());
  ASSERT(!class_name.IsNull());
  ASSERT(!function_name.IsNull());
  if (class_name.Length() == 0) {
    return ResolveLibraryFunction(library, function_name);
  }
  const Class& cls = Class::Handle(library.LookupClass(class_name));
  Function& function = Function::Handle();
  if (!cls.IsNull()) {
    function = cls.LookupStaticFunction(function_name);
    if (function.IsNull()) {
      function = cls.LookupDynamicFunction(function_name);
    }
  }
  return function.raw();
}


// Deoptimize function if necessary. Does not patch return addresses on the
// stack. If there are activation frames of this function on the stack,
// the optimized code will be executed when the callee returns.
void Debugger::EnsureFunctionIsDeoptimized(const Function& func) {
  if (func.HasOptimizedCode()) {
    if (verbose) {
      OS::Print("Deoptimizing function %s\n",
                String::Handle(func.name()).ToCString());
    }
    func.set_usage_counter(0);
    func.set_deoptimization_counter(func.deoptimization_counter() + 1);
    Compiler::CompileFunction(func);
    ASSERT(!func.HasOptimizedCode());
  }
}


void Debugger::InstrumentForStepping(const Function& target_function) {
  if (target_function.HasCode()) {
    EnsureFunctionIsDeoptimized(target_function);
  } else {
    Compiler::CompileFunction(target_function);
    // If there were any errors, ignore them silently and return without
    // adding breakpoints to target.
    if (!target_function.HasCode()) {
      return;
    }
  }
  Code& code = Code::Handle(target_function.unoptimized_code());
  ASSERT(!code.IsNull());
  PcDescriptors& desc = PcDescriptors::Handle(code.pc_descriptors());
  for (int i = 0; i < desc.Length(); i++) {
    CodeBreakpoint* bpt = GetCodeBreakpoint(desc.PC(i));
    if (bpt != NULL) {
      // There is already a breakpoint for this address. Leave it alone.
      continue;
    }
    PcDescriptors::Kind kind = desc.DescriptorKind(i);
    if ((kind == PcDescriptors::kIcCall) ||
        (kind == PcDescriptors::kFuncCall) ||
        (kind == PcDescriptors::kReturn)) {
      bpt = new CodeBreakpoint(target_function, i);
      RegisterCodeBreakpoint(bpt);
      bpt->Enable();
    }
  }
}


CodeBreakpoint* Debugger::MakeCodeBreakpoint(const Function& func,
                                             intptr_t token_index) {
  ASSERT(func.HasCode());
  ASSERT(!func.HasOptimizedCode());
  Code& code = Code::Handle(func.unoptimized_code());
  ASSERT(!code.IsNull());
  PcDescriptors& desc = PcDescriptors::Handle(code.pc_descriptors());
  intptr_t best_fit_index = -1;
  intptr_t best_fit = INT_MAX;
  for (int i = 0; i < desc.Length(); i++) {
    intptr_t desc_token_index = desc.TokenIndex(i);
    if (desc_token_index < token_index) {
      continue;
    }
    PcDescriptors::Kind kind = desc.DescriptorKind(i);
    if ((kind == PcDescriptors::kIcCall) ||
        (kind == PcDescriptors::kFuncCall) ||
        (kind == PcDescriptors::kReturn)) {
      if ((desc_token_index - token_index) < best_fit) {
        best_fit = desc_token_index - token_index;
        ASSERT(best_fit >= 0);
        best_fit_index = i;
      }
    }
  }
  if (best_fit_index >= 0) {
    CodeBreakpoint* bpt = GetCodeBreakpoint(desc.PC(best_fit_index));
    // We should only ever have one code breakpoint at the same address.
    // If we find an existing breakpoint, it must be an internal one which
    // is used for stepping.
    if (bpt != NULL) {
      ASSERT(bpt->src_bpt() == NULL);
      return bpt;
    }

    bpt = new CodeBreakpoint(func, best_fit_index);
    if (verbose) {
      OS::Print("Setting breakpoint in function '%s' (%s:%d) (PC %p)\n",
                String::Handle(func.name()).ToCString(),
                String::Handle(bpt->SourceUrl()).ToCString(),
                bpt->LineNumber(),
                bpt->pc());
    }
    RegisterCodeBreakpoint(bpt);
    return bpt;
  }
  return NULL;
}


SourceBreakpoint* Debugger::SetBreakpoint(const Function& target_function,
                                          intptr_t token_index) {
  if ((token_index < target_function.token_index()) ||
      (target_function.end_token_index() <= token_index)) {
    // The given token position is not within the target function.
    return NULL;
  }
  EnsureFunctionIsDeoptimized(target_function);
  SourceBreakpoint* bpt = GetSourceBreakpoint(target_function, token_index);
  if (bpt != NULL) {
    // A breakpoint for this location already exists, return it.
    return bpt;
  }
  bpt = new SourceBreakpoint(target_function, token_index);
  RegisterSourceBreakpoint(bpt);
  if (verbose && !target_function.HasCode()) {
    OS::Print("Registering breakpoint for uncompiled function '%s'"
              " (%s:%d)\n",
              String::Handle(target_function.name()).ToCString(),
              String::Handle(bpt->SourceUrl()).ToCString(),
              bpt->LineNumber());
  }

  if (target_function.HasCode()) {
    CodeBreakpoint* cbpt = MakeCodeBreakpoint(target_function, token_index);
    if (cbpt != NULL) {
      ASSERT(cbpt->src_bpt() == NULL);
      cbpt->set_src_bpt(bpt);
    } else {
      if (verbose) {
        OS::Print("Failed to set breakpoint at '%s' line %d\n",
                  String::Handle(bpt->SourceUrl()).ToCString(),
                  bpt->LineNumber());
      }
    }
  }
  bpt->Enable();
  return bpt;
}


// Synchronize the enabled/disabled state of all code breakpoints
// associated with the source breakpoint bpt.
void Debugger::SyncBreakpoint(SourceBreakpoint* bpt) {
  CodeBreakpoint* cbpt = code_breakpoints_;
  while (cbpt != NULL) {
    if (bpt == cbpt->src_bpt()) {
      if (bpt->IsEnabled()) {
        cbpt->Enable();
      } else {
        cbpt->Disable();
      }
    }
    cbpt = cbpt->next();
  }
}


SourceBreakpoint* Debugger::SetBreakpointAtEntry(
      const Function& target_function) {
  ASSERT(!target_function.IsNull());
  return SetBreakpoint(target_function, target_function.token_index());
}


SourceBreakpoint* Debugger::SetBreakpointAtLine(const String& script_url,
                                          intptr_t line_number) {
  Library& lib = Library::Handle();
  Script& script = Script::Handle();
  lib = isolate_->object_store()->registered_libraries();
  while (!lib.IsNull()) {
    script = lib.LookupScript(script_url);
    if (!script.IsNull()) {
      break;
    }
    lib = lib.next_registered();
  }
  if (script.IsNull()) {
    if (verbose) {
      OS::Print("Failed to find script with url '%s'\n",
                script_url.ToCString());
    }
    return NULL;
  }
  intptr_t token_index_at_line = script.TokenIndexAtLine(line_number);
  if (token_index_at_line < 0) {
    // Script does not contain the given line number.
    if (verbose) {
      OS::Print("Script '%s' does not contain line number %d\n",
                script_url.ToCString(), line_number);
    }
    return NULL;
  }
  const Function& func =
      Function::Handle(lib.LookupFunctionInScript(script, token_index_at_line));
  if (func.IsNull()) {
    if (verbose) {
      OS::Print("No executable code at line %d in '%s'\n",
                line_number, script_url.ToCString());
    }
    return NULL;
  }
  return SetBreakpoint(func, token_index_at_line);
}


// TODO(hausner): Merge some of this functionality with the code in
// dart_api_impl.cc.
RawObject* Debugger::GetInstanceField(const Class& cls,
                                      const String& field_name,
                                      const Instance& object) {
  const Function& getter_func =
      Function::Handle(cls.LookupGetterFunction(field_name));
  ASSERT(!getter_func.IsNull());

  Object& result = Object::Handle();
  LongJump* base = isolate_->long_jump_base();
  LongJump jump;
  isolate_->set_long_jump_base(&jump);
  bool saved_ignore_flag = ignore_breakpoints_;
  ignore_breakpoints_ = true;
  if (setjmp(*jump.Set()) == 0) {
    GrowableArray<const Object*> noArguments;
    const Array& noArgumentNames = Array::Handle();
    result = DartEntry::InvokeDynamic(object, getter_func,
                                      noArguments, noArgumentNames);
  } else {
    result = isolate_->object_store()->sticky_error();
  }
  ignore_breakpoints_ = saved_ignore_flag;
  isolate_->set_long_jump_base(base);
  return result.raw();
}


RawObject* Debugger::GetStaticField(const Class& cls,
                                    const String& field_name) {
  const Field& fld = Field::Handle(cls.LookupStaticField(field_name));
  if (!fld.IsNull()) {
    // Return the value in the field if it has been initialized already.
    const Instance& value = Instance::Handle(fld.value());
    ASSERT(value.raw() != Object::transition_sentinel());
    if (value.raw() != Object::sentinel()) {
      return value.raw();
    }
  }
  // There is no field or the field has not been initialized yet.
  // We must have a getter. Run the getter.
  const Function& getter_func =
      Function::Handle(cls.LookupGetterFunction(field_name));
  ASSERT(!getter_func.IsNull());
  if (getter_func.IsNull()) {
    return Object::null();
  }

  Object& result = Object::Handle();
  LongJump* base = isolate_->long_jump_base();
  LongJump jump;
  isolate_->set_long_jump_base(&jump);
  bool saved_ignore_flag = ignore_breakpoints_;
  ignore_breakpoints_ = true;
  if (setjmp(*jump.Set()) == 0) {
    GrowableArray<const Object*> noArguments;
    const Array& noArgumentNames = Array::Handle();
    result = DartEntry::InvokeStatic(getter_func, noArguments, noArgumentNames);
  } else {
    result = isolate_->object_store()->sticky_error();
  }
  ignore_breakpoints_ = saved_ignore_flag;
  isolate_->set_long_jump_base(base);
  return result.raw();
}


RawArray* Debugger::GetInstanceFields(const Instance& obj) {
  Class& cls = Class::Handle(obj.clazz());
  Array& fields = Array::Handle();
  Field& field = Field::Handle();
  const GrowableObjectArray& field_list =
      GrowableObjectArray::Handle(GrowableObjectArray::New(8));
  String& field_name = String::Handle();
  Object& field_value = Object::Handle();
  // Iterate over fields in class hierarchy to count all instance fields.
  while (!cls.IsNull()) {
    fields = cls.fields();
    for (int i = 0; i < fields.Length(); i++) {
      field ^= fields.At(i);
      if (!field.is_static()) {
        field_name = field.name();
        field_list.Add(field_name);
        field_value = GetInstanceField(cls, field_name, obj);
        field_list.Add(field_value);
      }
    }
    cls = cls.SuperClass();
  }
  return Array::MakeArray(field_list);
}


RawArray* Debugger::GetStaticFields(const Class& cls) {
  const GrowableObjectArray& field_list =
      GrowableObjectArray::Handle(GrowableObjectArray::New(8));
  Array& fields = Array::Handle(cls.fields());
  Field& field = Field::Handle();
  String& field_name = String::Handle();
  Object& field_value = Object::Handle();
  for (int i = 0; i < fields.Length(); i++) {
    field ^= fields.At(i);
    if (field.is_static()) {
      field_name = field.name();
      field_value = GetStaticField(cls, field_name);
      field_list.Add(field_name);
      field_list.Add(field_value);
    }
  }
  return Array::MakeArray(field_list);
}


void Debugger::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  ASSERT(visitor != NULL);
  SourceBreakpoint* bpt = src_breakpoints_;
  while (bpt != NULL) {
    bpt->VisitObjectPointers(visitor);
    bpt = bpt->next();
  }
  CodeBreakpoint* cbpt = code_breakpoints_;
  while (cbpt != NULL) {
    cbpt->VisitObjectPointers(visitor);
    cbpt = cbpt->next();
  }
}


static void DefaultBreakpointHandler(SourceBreakpoint* bpt,
                                     DebuggerStackTrace* stack) {
  String& var_name = String::Handle();
  Instance& value = Instance::Handle();
  for (intptr_t i = 0; i < stack->Length(); i++) {
    ActivationFrame* frame = stack->ActivationFrameAt(i);
    OS::Print("   %d. %s\n",
              i + 1, frame->ToCString());
    intptr_t num_locals = frame->NumLocalVariables();
    for (intptr_t i = 0; i < num_locals; i++) {
      intptr_t token_pos, end_pos;
      frame->VariableAt(i, &var_name, &token_pos, &end_pos, &value);
      OS::Print("      var %s (pos %d) = %s\n",
                var_name.ToCString(), token_pos, value.ToCString());
    }
  }
}


void Debugger::SetBreakpointHandler(BreakpointHandler* handler) {
  bp_handler_ = handler;
  if (bp_handler_ == NULL) {
    bp_handler_ = &DefaultBreakpointHandler;
  }
}


void Debugger::BreakpointCallback() {
  ASSERT(initialized_);

  if (ignore_breakpoints_) {
    return;
  }
  DartFrameIterator iterator;
  DartFrame* frame = iterator.NextFrame();
  ASSERT(frame != NULL);
  CodeBreakpoint* bpt = GetCodeBreakpoint(frame->pc());
  ASSERT(bpt != NULL);
  if (verbose) {
    OS::Print(">>> %s breakpoint at %s:%d (Address %p)\n",
              bpt->IsInternal() ? "hit internal" : "hit user",
              bpt ? String::Handle(bpt->SourceUrl()).ToCString() : "?",
              bpt ? bpt->LineNumber() : 0,
              frame->pc());
  }
  DebuggerStackTrace* stack_trace = new DebuggerStackTrace(8);
  while (frame != NULL) {
    ASSERT(frame->IsValid());
    ASSERT(frame->IsDartFrame());
    ActivationFrame* activation =
        new ActivationFrame(frame->pc(), frame->fp(), frame->sp());
    stack_trace->AddActivation(activation);
    frame = iterator.NextFrame();
  }

  resume_action_ = kContinue;
  if (bp_handler_ != NULL) {
    SourceBreakpoint* src_bpt = bpt->src_bpt();
    (*bp_handler_)(src_bpt, stack_trace);
  }

  if (resume_action_ == kContinue) {
    RemoveInternalBreakpoints();
  } else if (resume_action_ == kStepOver) {
    Function& func = Function::Handle(bpt->function());
    if (bpt->breakpoint_kind_ == PcDescriptors::kReturn) {
      // If we are at the function return, do a StepOut action.
      if (stack_trace->Length() > 1) {
        ActivationFrame* caller = stack_trace->ActivationFrameAt(1);
        func = caller->DartFunction().raw();
      }
    }
    RemoveInternalBreakpoints();  // *bpt is now invalid.
    InstrumentForStepping(func);
  } else if (resume_action_ == kStepInto) {
    if (bpt->breakpoint_kind_ == PcDescriptors::kIcCall) {
      int num_args, num_named_args;
      uword target;
      CodePatcher::GetInstanceCallAt(bpt->pc_, NULL,
          &num_args, &num_named_args, &target);
      RemoveInternalBreakpoints();  // *bpt is now invalid.
      ActivationFrame* top_frame = stack_trace->ActivationFrameAt(0);
      Instance& receiver = Instance::Handle(
          top_frame->GetInstanceCallReceiver(num_args));
      Code& code = Code::Handle(
          ResolveCompileInstanceCallTarget(isolate_, receiver));
      if (!code.IsNull()) {
        Function& callee = Function::Handle(code.function());
        InstrumentForStepping(callee);
      }
    } else if (bpt->breakpoint_kind_ == PcDescriptors::kFuncCall) {
      Function& callee = Function::Handle();
      uword target;
      CodePatcher::GetStaticCallAt(bpt->pc_, &callee, &target);
      RemoveInternalBreakpoints();  // *bpt is now invalid.
      InstrumentForStepping(callee);
    } else {
      ASSERT(bpt->breakpoint_kind_ == PcDescriptors::kReturn);
      RemoveInternalBreakpoints();  // *bpt is now invalid.
      // Treat like stepping out to caller.
      if (stack_trace->Length() > 1) {
        ActivationFrame* caller = stack_trace->ActivationFrameAt(1);
        InstrumentForStepping(caller->DartFunction());
      }
    }
  } else {
    ASSERT(resume_action_ == kStepOut);
    RemoveInternalBreakpoints();  // *bpt is now invalid.
    // Set stepping breakpoints in the caller.
    if (stack_trace->Length() > 1) {
      ActivationFrame* caller = stack_trace->ActivationFrameAt(1);
      InstrumentForStepping(caller->DartFunction());
    }
  }
}


void Debugger::Initialize(Isolate* isolate) {
  if (initialized_) {
    return;
  }
  isolate_ = isolate;
  initialized_ = true;
  SetBreakpointHandler(DefaultBreakpointHandler);
}


void Debugger::NotifyCompilation(const Function& func) {
  if (src_breakpoints_ == NULL) {
    // Return with minimal overhead if there are no breakpoints.
    return;
  }
  Function& lookup_function = Function::Handle(func.raw());
  if (func.IsImplicitClosureFunction()) {
    // If the newly compiled function is a an implicit closure (a closure that
    // was formed by assigning a static or instance method to a function
    // object), we need to use the closure's parent function to see whether
    // there are any breakpoints. The parent function is the actual method on
    // which the user sets breakpoints.
    lookup_function = func.parent_function();
    ASSERT(!lookup_function.IsNull());
  }
  SourceBreakpoint* bpt = src_breakpoints_;
  while (bpt != NULL) {
    if (lookup_function.raw() == bpt->function()) {
      // Check if the breakpoint is inside a closure or local function
      // within the newly compiled function.
      Class& owner = Class::Handle(lookup_function.owner());
      Function& closure =
          Function::Handle(owner.LookupClosureFunction(bpt->token_index()));
      if (!closure.IsNull() && (closure.raw() != lookup_function.raw())) {
        if (verbose) {
          OS::Print("Resetting pending breakpoint to function %s\n",
                    String::Handle(closure.name()).ToCString());
        }
        bpt->set_function(closure);
      } else {
        if (verbose) {
          OS::Print("Enable pending breakpoint for function '%s'\n",
                    String::Handle(lookup_function.name()).ToCString());
        }
        // Set breakpoint in newly compiled code of function func.
        CodeBreakpoint* cbpt = MakeCodeBreakpoint(func, bpt->token_index());
        if (cbpt != NULL) {
          cbpt->set_src_bpt(bpt);
        }
      }
      bpt->Enable();  // Enables the code breakpoint as well.
    }
    bpt = bpt->next();
  }
}


CodeBreakpoint* Debugger::GetCodeBreakpoint(uword breakpoint_address) {
  CodeBreakpoint* bpt = code_breakpoints_;
  while (bpt != NULL) {
    if (bpt->pc() == breakpoint_address) {
      return bpt;
    }
    bpt = bpt->next();
  }
  return NULL;
}


// Remove and delete the source breakpoint bpt and its associated
// code breakpoints.
void Debugger::RemoveBreakpoint(SourceBreakpoint* bpt) {
  ASSERT(src_breakpoints_ != NULL);
  SourceBreakpoint* prev_bpt = NULL;
  SourceBreakpoint* curr_bpt = src_breakpoints_;
  while (curr_bpt != NULL) {
    if (bpt == curr_bpt) {
      if (prev_bpt == NULL) {
        src_breakpoints_ = src_breakpoints_->next();
      } else {
        prev_bpt->set_next(curr_bpt->next());
      }
      // Remove the code breakpoints associated with the source breakpoint.
      RemoveCodeBreakpoints(bpt);
      delete bpt;
      return;
    }
    prev_bpt = curr_bpt;
    curr_bpt = curr_bpt->next();
  }
  // bpt is not a registered breakpoint, nothing to do.
}


// Remove and delete the code breakpoints that are associated with given
// source breakpoint bpt. If bpt is null, remove the internal breakpoints.
void Debugger::RemoveCodeBreakpoints(SourceBreakpoint* src_bpt) {
  CodeBreakpoint* prev_bpt = NULL;
  CodeBreakpoint* curr_bpt = code_breakpoints_;
  while (curr_bpt != NULL) {
    if (curr_bpt->src_bpt() == src_bpt) {
      if (prev_bpt == NULL) {
        code_breakpoints_ = code_breakpoints_->next();
      } else {
        prev_bpt->set_next(curr_bpt->next());
      }
      CodeBreakpoint* temp_bpt = curr_bpt;
      curr_bpt = curr_bpt->next();
      temp_bpt->Disable();
      delete temp_bpt;
    } else {
      prev_bpt = curr_bpt;
      curr_bpt = curr_bpt->next();
    }
  }
}


// Remove and delete all breakpoints that are not associated with a
// user-defined source breakpoint.
void Debugger::RemoveInternalBreakpoints() {
  RemoveCodeBreakpoints(NULL);
}


SourceBreakpoint* Debugger::GetSourceBreakpoint(const Function& func,
                                                intptr_t token_index) {
  SourceBreakpoint* bpt = src_breakpoints_;
  while (bpt != NULL) {
    if ((bpt->function() == func.raw()) &&
        (bpt->token_index() == token_index)) {
      return bpt;
    }
    bpt = bpt->next();
  }
  return NULL;
}


void Debugger::RegisterSourceBreakpoint(SourceBreakpoint* bpt) {
  ASSERT(bpt->next() == NULL);
  bpt->set_next(src_breakpoints_);
  src_breakpoints_ = bpt;
}


void Debugger::RegisterCodeBreakpoint(CodeBreakpoint* bpt) {
  ASSERT(bpt->next() == NULL);
  bpt->set_next(code_breakpoints_);
  code_breakpoints_ = bpt;
}

}  // namespace dart
