// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/debugger.h"

#include "include/dart_api.h"

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
#include "vm/port.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"
#include "vm/visitor.h"


namespace dart {

DEFINE_FLAG(bool, verbose_debug, false, "Verbose debugger messages");


Debugger::EventHandler* Debugger::event_handler_ = NULL;


class RemoteObjectCache : public ZoneAllocated {
 public:
  explicit RemoteObjectCache(intptr_t initial_size);
  intptr_t AddObject(const Object& obj);
  RawObject* GetObj(intptr_t obj_id) const;
  bool IsValidId(intptr_t obj_id) const {
    return obj_id < objs_->Length();
  }

 private:
  GrowableObjectArray* objs_;

  DISALLOW_COPY_AND_ASSIGN(RemoteObjectCache);
};


SourceBreakpoint::SourceBreakpoint(intptr_t id,
                                   const Function& func,
                                   intptr_t token_pos)
    : id_(id),
      function_(func.raw()),
      token_pos_(token_pos),
      line_number_(-1),
      is_enabled_(false),
      next_(NULL) {
  ASSERT(!func.IsNull());
  ASSERT((func.token_pos() <= token_pos_) &&
         (token_pos_ < func.end_token_pos()));
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
  return func.script();
}


void SourceBreakpoint::GetCodeLocation(
    Library* lib,
    Script* script,
    intptr_t* pos) {
  const Function& func = Function::Handle(function_);
  const Class& cls = Class::Handle(func.origin());
  *lib = cls.library();
  *script = func.script();
  *pos = token_pos();
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
    script.GetTokenLocation(token_pos_, &line_number_, &ignore_column);
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


ActivationFrame::ActivationFrame(uword pc, uword fp, uword sp, const Code& code)
    : pc_(pc), fp_(fp), sp_(sp),
      ctx_(Context::ZoneHandle()),
      code_(Code::ZoneHandle(code.raw())),
      function_(Function::ZoneHandle(code.function())),
      token_pos_(-1),
      pc_desc_index_(-1),
      line_number_(-1),
      context_level_(-1),
      vars_initialized_(false),
      var_descriptors_(LocalVarDescriptors::ZoneHandle()),
      desc_indices_(8),
      pc_desc_(PcDescriptors::ZoneHandle()) {
}


void Debugger::SignalIsolateEvent(EventType type) {
  if (event_handler_ != NULL) {
    Debugger* debugger = Isolate::Current()->debugger();
    ASSERT(debugger != NULL);
    DebuggerEvent event;
    event.type = type;
    event.isolate_id = debugger->GetIsolateId();
    ASSERT(event.isolate_id != ILLEGAL_ISOLATE_ID);
    if (type == kIsolateInterrupted) {
      DebuggerStackTrace* stack_trace = debugger->CollectStackTrace();
      ASSERT(stack_trace->Length() > 0);
      ASSERT(debugger->stack_trace_ == NULL);
      ASSERT(debugger->obj_cache_ == NULL);
      debugger->obj_cache_ = new RemoteObjectCache(64);
      debugger->stack_trace_ = stack_trace;
      (*event_handler_)(&event);
      debugger->stack_trace_ = NULL;
      debugger->obj_cache_ = NULL;  // Remote object cache is zone allocated.
      // TODO(asiva): Need some work here to be able to single step after
      // an interrupt.
    } else {
      (*event_handler_)(&event);
    }
  }
}


const char* Debugger::QualifiedFunctionName(const Function& func) {
  const String& func_name = String::Handle(func.name());
  Class& func_class = Class::Handle(func.Owner());
  String& class_name = String::Handle(func_class.Name());

  const char* kFormat = "%s%s%s";
  intptr_t len = OS::SNPrint(NULL, 0, kFormat,
      func_class.IsTopLevel() ? "" : class_name.ToCString(),
      func_class.IsTopLevel() ? "" : ".",
      func_name.ToCString());
  len++;  // String terminator.
  char* chars = Isolate::Current()->current_zone()->Alloc<char>(len);
  OS::SNPrint(chars, len, kFormat,
              func_class.IsTopLevel() ? "" : class_name.ToCString(),
              func_class.IsTopLevel() ? "" : ".",
              func_name.ToCString());
  return chars;
}


bool Debugger::HasBreakpoint(const Function& func) {
  if (!func.HasCode()) {
    // If the function is not compiled yet, just check whether there
    // is a user-defined latent breakpoint.
    SourceBreakpoint* sbpt = src_breakpoints_;
    while (sbpt != NULL) {
      if (func.raw() == sbpt->function()) {
        return true;
      }
      sbpt = sbpt->next_;
    }
    return false;
  }
  CodeBreakpoint* cbpt = code_breakpoints_;
  while (cbpt != NULL) {
    if (func.raw() == cbpt->function()) {
      return true;
    }
    cbpt = cbpt->next_;
  }
  return false;
}


RawString* ActivationFrame::QualifiedFunctionName() {
  return String::New(Debugger::QualifiedFunctionName(function()));
}


RawString* ActivationFrame::SourceUrl() {
  const Script& script = Script::Handle(SourceScript());
  return script.url();
}


RawScript* ActivationFrame::SourceScript() {
  return function().script();
}


RawLibrary* ActivationFrame::Library() {
  const Class& cls = Class::Handle(function().Owner());
  return cls.library();
}


void ActivationFrame::GetPcDescriptors() {
  if (pc_desc_.IsNull()) {
    pc_desc_ = code().pc_descriptors();
    ASSERT(!pc_desc_.IsNull());
  }
}


// Compute token_pos_ and pc_desc_index_.
intptr_t ActivationFrame::TokenPos() {
  if (token_pos_ < 0) {
    GetPcDescriptors();
    for (int i = 0; i < pc_desc_.Length(); i++) {
      if (pc_desc_.PC(i) == pc_) {
        pc_desc_index_ = i;
        token_pos_ = pc_desc_.TokenPos(i);
        break;
      }
    }
  }
  return token_pos_;
}


intptr_t ActivationFrame::PcDescIndex() {
  if (pc_desc_index_ < 0) {
    TokenPos();  // Sets pc_desc_index_ as a side effect.
  }
  return pc_desc_index_;
}


intptr_t ActivationFrame::TryIndex() {
  intptr_t desc_index = PcDescIndex();
  if (desc_index < 0) {
    return -1;
  } else {
    return pc_desc_.TryIndex(desc_index);
  }
}


intptr_t ActivationFrame::LineNumber() {
  // Compute line number lazily since it causes scanning of the script.
  if ((line_number_ < 0) && (TokenPos() >= 0)) {
    const Script& script = Script::Handle(SourceScript());
    intptr_t ignore_column;
    script.GetTokenLocation(TokenPos(), &line_number_, &ignore_column);
  }
  return line_number_;
}


void ActivationFrame::GetVarDescriptors() {
  if (var_descriptors_.IsNull()) {
    var_descriptors_ = code().var_descriptors();
    ASSERT(!var_descriptors_.IsNull());
  }
}


// Calculate the context level at the current token index of the frame.
intptr_t ActivationFrame::ContextLevel() {
  if (context_level_ < 0 && !ctx_.IsNull()) {
    ASSERT(!code_.is_optimized());
    context_level_ = 0;
    intptr_t pc_desc_idx = PcDescIndex();
    // TODO(hausner): What to do if there is no descriptor entry
    // for the code position of the frame? For now say we are at context
    // level 0.
    if (pc_desc_idx < 0) {
      return context_level_;
    }
    ASSERT(!pc_desc_.IsNull());
    if (pc_desc_.DescriptorKind(pc_desc_idx) == PcDescriptors::kReturn) {
      // Special case: the context chain has already been deallocated.
      // The context level is 0.
      return context_level_;
    }
    intptr_t innermost_begin_pos = 0;
    intptr_t activation_token_pos = TokenPos();
    ASSERT(activation_token_pos >= 0);
    GetVarDescriptors();
    intptr_t var_desc_len = var_descriptors_.Length();
    for (int cur_idx = 0; cur_idx < var_desc_len; cur_idx++) {
      RawLocalVarDescriptors::VarInfo var_info;
      var_descriptors_.GetInfo(cur_idx, &var_info);
      if ((var_info.kind == RawLocalVarDescriptors::kContextLevel) &&
          (var_info.begin_pos <= activation_token_pos) &&
          (activation_token_pos < var_info.end_pos)) {
        // This var_descriptors_ entry is a context scope which is in scope
        // of the current token position. Now check whether it is shadowing
        // the previous context scope.
        if (innermost_begin_pos < var_info.begin_pos) {
          innermost_begin_pos = var_info.begin_pos;
          context_level_ = var_info.index;
        }
      }
    }
    ASSERT(context_level_ >= 0);
  }
  return context_level_;
}


RawContext* ActivationFrame::GetSavedContext() {
  GetVarDescriptors();
  intptr_t var_desc_len = var_descriptors_.Length();
  for (int i = 0; i < var_desc_len; i++) {
    RawLocalVarDescriptors::VarInfo var_info;
    var_descriptors_.GetInfo(i, &var_info);
    if (var_info.kind == RawLocalVarDescriptors::kContextChain) {
      return reinterpret_cast<RawContext*>(GetLocalVarValue(var_info.index));
    }
  }
  UNREACHABLE();
  return Context::null();
}


ActivationFrame* DebuggerStackTrace::GetHandlerFrame(
    const Instance& exc_obj) const {
  ExceptionHandlers& handlers = ExceptionHandlers::Handle();
  Array& handled_types = Array::Handle();
  AbstractType& type = Type::Handle();
  const TypeArguments& no_instantiator = TypeArguments::Handle();
  for (int frame_index = 0; frame_index < Length(); frame_index++) {
    ActivationFrame* frame = trace_[frame_index];
    intptr_t try_index = frame->TryIndex();
    if (try_index < 0) continue;
    handlers = frame->code().exception_handlers();
    ASSERT(!handlers.IsNull());
    intptr_t num_handlers_checked = 0;
    while (try_index >= 0) {
      // Detect circles in the exception handler data.
      num_handlers_checked++;
      ASSERT(num_handlers_checked <= handlers.Length());
      handled_types = handlers.GetHandledTypes(try_index);
      const intptr_t num_types = handled_types.Length();
      for (int k = 0; k < num_types; k++) {
        type ^= handled_types.At(k);
        ASSERT(!type.IsNull());
        // Uninstantiated types are not added to ExceptionHandlers data.
        ASSERT(type.IsInstantiated());
        if (type.IsDynamicType()) return frame;
        if (type.IsMalformed()) continue;
        if (exc_obj.IsInstanceOf(type, no_instantiator, NULL)) {
          return frame;
        }
      }
      try_index = handlers.OuterTryIndex(try_index);
    }
  }
  return NULL;
}


void ActivationFrame::GetDescIndices() {
  if (vars_initialized_) {
    return;
  }
  GetVarDescriptors();

  // We don't trust variable descriptors in optimized code.
  // Rather than potentially displaying incorrect values, we
  // pretend that there are no variables in the frame.
  // We should be more clever about this in the future.
  if (code().is_optimized()) {
    vars_initialized_ = true;
    return;
  }

  intptr_t activation_token_pos = TokenPos();
  if (activation_token_pos < 0) {
    // We don't have a token position for this frame, so can't determine
    // which variables are visible.
    vars_initialized_ = true;
    return;
  }

  GrowableArray<String*> var_names(8);
  intptr_t var_desc_len = var_descriptors_.Length();
  for (int cur_idx = 0; cur_idx < var_desc_len; cur_idx++) {
    ASSERT(var_names.length() == desc_indices_.length());
    RawLocalVarDescriptors::VarInfo var_info;
    var_descriptors_.GetInfo(cur_idx, &var_info);
    if ((var_info.kind != RawLocalVarDescriptors::kStackVar) &&
        (var_info.kind != RawLocalVarDescriptors::kContextVar)) {
      continue;
    }
    if ((var_info.begin_pos <= activation_token_pos) &&
        (activation_token_pos <= var_info.end_pos)) {
      if ((var_info.kind == RawLocalVarDescriptors::kContextVar) &&
          (ContextLevel() < var_info.scope_id)) {
        // The variable is textually in scope but the context level
        // at the activation frame's PC is lower than the context
        // level of the variable. The context containing the variable
        // has already been removed from the chain. This can happen when we
        // break at a return statement, since the contexts get discarded
        // before the debugger gets called.
        continue;
      }
      // The current variable is textually in scope. Now check whether
      // there is another local variable with the same name that shadows
      // or is shadowed by this variable.
      String& var_name = String::Handle(var_descriptors_.GetName(cur_idx));
      intptr_t indices_len = desc_indices_.length();
      bool name_match_found = false;
      for (int i = 0; i < indices_len; i++) {
        if (var_name.Equals(*var_names[i])) {
          // Found two local variables with the same name. Now determine
          // which one is shadowed.
          name_match_found = true;
          RawLocalVarDescriptors::VarInfo i_var_info;
          var_descriptors_.GetInfo(desc_indices_[i], &i_var_info);
          if (i_var_info.begin_pos < var_info.begin_pos) {
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
  vars_initialized_ = true;
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
  intptr_t desc_index = desc_indices_[i];
  ASSERT(name != NULL);
  *name ^= var_descriptors_.GetName(desc_index);
  RawLocalVarDescriptors::VarInfo var_info;
  var_descriptors_.GetInfo(desc_index, &var_info);
  ASSERT(token_pos != NULL);
  *token_pos = var_info.begin_pos;
  ASSERT(end_pos != NULL);
  *end_pos = var_info.end_pos;
  ASSERT(value != NULL);
  if (var_info.kind == RawLocalVarDescriptors::kStackVar) {
    *value = GetLocalVarValue(var_info.index);
  } else {
    ASSERT(var_info.kind == RawLocalVarDescriptors::kContextVar);
    // The context level at the PC/token index of this activation frame.
    intptr_t frame_ctx_level = ContextLevel();
    if (ctx_.IsNull()) {
      *value = Symbols::New("<unknown>");
      return;
    }
    // The context level of the variable.
    intptr_t var_ctx_level = var_info.scope_id;
    intptr_t level_diff = frame_ctx_level - var_ctx_level;
    intptr_t ctx_slot = var_info.index;
    if (level_diff == 0) {
      *value = ctx_.At(ctx_slot);
    } else {
      ASSERT(level_diff > 0);
      Context& ctx = Context::Handle(ctx_.raw());
      while (level_diff > 0) {
        ASSERT(!ctx.IsNull());
        level_diff--;
        ctx = ctx.parent();
      }
      ASSERT(!ctx.IsNull());
      *value = ctx.At(ctx_slot);
    }
  }
}


RawArray* ActivationFrame::GetLocalVariables() {
  GetDescIndices();
  intptr_t num_variables = desc_indices_.length();
  String& var_name = String::Handle();
  Instance& value = Instance::Handle();
  const Array& list = Array::Handle(Array::New(2 * num_variables));
  for (int i = 0; i < num_variables; i++) {
    intptr_t ignore;
    VariableAt(i, &var_name, &ignore, &ignore, &value);
    list.SetAt(2 * i, var_name);
    list.SetAt((2 * i) + 1, value);
  }
  return list.raw();
}


const char* ActivationFrame::ToCString() {
  const char* kFormat = "Function: '%s' url: '%s' line: %d";

  const String& url = String::Handle(SourceUrl());
  intptr_t line = LineNumber();
  const char* func_name = Debugger::QualifiedFunctionName(function());

  intptr_t len =
      OS::SNPrint(NULL, 0, kFormat, func_name, url.ToCString(), line);
  len++;  // String terminator.
  char* chars = Isolate::Current()->current_zone()->Alloc<char>(len);
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
  token_pos_ = desc.TokenPos(pc_desc_index);
  ASSERT(token_pos_ >= 0);
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
  return func.script();
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
    script.GetTokenLocation(token_pos_, &line_number_, &ignore_column);
  }
  return line_number_;
}


void CodeBreakpoint::PatchCode() {
  ASSERT(!is_enabled_);
  switch (breakpoint_kind_) {
    case PcDescriptors::kIcCall: {
      const Code& code =
          Code::Handle(Function::Handle(function_).unoptimized_code());
      saved_bytes_.target_address_ =
          CodePatcher::GetInstanceCallAt(pc_, code, NULL, NULL);
      CodePatcher::PatchInstanceCallAt(pc_, code,
                                       StubCode::BreakpointDynamicEntryPoint());
      break;
    }
    case PcDescriptors::kFuncCall: {
      const Code& code =
          Code::Handle(Function::Handle(function_).unoptimized_code());
      saved_bytes_.target_address_ =
          CodePatcher::GetStaticCallTargetAt(pc_, code);
      CodePatcher::PatchStaticCallAt(pc_, code,
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
    case PcDescriptors::kIcCall: {
      const Code& code =
          Code::Handle(Function::Handle(function_).unoptimized_code());
      CodePatcher::PatchInstanceCallAt(pc_, code,
                                       saved_bytes_.target_address_);
      break;
    }
    case PcDescriptors::kFuncCall: {
      const Code& code =
          Code::Handle(Function::Handle(function_).unoptimized_code());
      CodePatcher::PatchStaticCallAt(pc_, code,
                                     saved_bytes_.target_address_);
      break;
    }
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


RemoteObjectCache::RemoteObjectCache(intptr_t initial_size) {
  objs_ = &GrowableObjectArray::ZoneHandle(
              GrowableObjectArray::New(initial_size));
}


intptr_t RemoteObjectCache::AddObject(const Object& obj) {
  intptr_t len = objs_->Length();
  for (int i = 0; i < len; i++) {
    if (objs_->At(i) == obj.raw()) {
      return i;
    }
  }
  objs_->Add(obj);
  return len;
}


RawObject* RemoteObjectCache::GetObj(intptr_t obj_id) const {
  ASSERT(IsValidId(obj_id));
  return objs_->At(obj_id);
}


Debugger::Debugger()
    : isolate_(NULL),
      isolate_id_(ILLEGAL_ISOLATE_ID),
      initialized_(false),
      next_id_(1),
      stack_trace_(NULL),
      obj_cache_(NULL),
      src_breakpoints_(NULL),
      code_breakpoints_(NULL),
      resume_action_(kContinue),
      last_bpt_line_(-1),
      ignore_breakpoints_(false),
      exc_pause_info_(kNoPauseOnExceptions) {
}


Debugger::~Debugger() {
  PortMap::ClosePort(isolate_id_);
  isolate_id_ = ILLEGAL_ISOLATE_ID;
  ASSERT(src_breakpoints_ == NULL);
  ASSERT(code_breakpoints_ == NULL);
  ASSERT(stack_trace_ == NULL);
  ASSERT(obj_cache_ == NULL);
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
  // Signal isolate shutdown event.
  SignalIsolateEvent(Debugger::kIsolateShutdown);
}


static RawFunction* ResolveLibraryFunction(
                        const Library& library,
                        const String& fname) {
  ASSERT(!library.IsNull());
  const Object& object = Object::Handle(library.LookupObject(fname));
  if (!object.IsNull() && object.IsFunction()) {
    return Function::Cast(object).raw();
  }
  return Function::null();
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


// Deoptimize all functions in the isolate.
// TODO(hausner): Actually we only need to deoptimize those functions
// that inline the function that contains the newly created breakpoint.
// We currently don't have this info so we deoptimize all functions.
void Debugger::DeoptimizeWorld() {
  // Deoptimize all functions in stack activation frames.
  DeoptimizeAll();
  // Iterate over all classes, deoptimize functions.
  // TODO(hausner): Could possibly be combined with RemoveOptimizedCode()
  const ClassTable& class_table = *isolate_->class_table();
  Class& cls = Class::Handle();
  Array& functions = Array::Handle();
  Function& function = Function::Handle();
  intptr_t num_classes = class_table.NumCids();
  for (intptr_t i = 1; i < num_classes; i++) {
    if (class_table.HasValidClassAt(i)) {
      cls = class_table.At(i);
      functions = cls.functions();
      intptr_t num_functions = functions.IsNull() ? 0 : functions.Length();
      for (intptr_t f = 0; f < num_functions; f++) {
        function ^= functions.At(f);
        ASSERT(!function.IsNull());
        if (function.HasOptimizedCode()) {
          function.SwitchToUnoptimizedCode();
        }
      }
    }
  }
}


void Debugger::InstrumentForStepping(const Function& target_function) {
  if (!target_function.HasCode()) {
    Compiler::CompileFunction(target_function);
    // If there were any errors, ignore them silently and return without
    // adding breakpoints to target.
    if (!target_function.HasCode()) {
      return;
    }
  }
  DeoptimizeWorld();
  ASSERT(!target_function.HasOptimizedCode());
  Code& code = Code::Handle(target_function.unoptimized_code());
  ASSERT(!code.IsNull());
  PcDescriptors& desc = PcDescriptors::Handle(code.pc_descriptors());
  for (int i = 0; i < desc.Length(); i++) {
    CodeBreakpoint* bpt = GetCodeBreakpoint(desc.PC(i));
    if (bpt != NULL) {
      // There is already a breakpoint for this address. Make sure
      // it is enabled.
      bpt->Enable();
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


void Debugger::SignalBpResolved(SourceBreakpoint* bpt) {
  if (event_handler_ != NULL) {
    DebuggerEvent event;
    event.type = kBreakpointResolved;
    event.breakpoint = bpt;
    (*event_handler_)(&event);
  }
}


DebuggerStackTrace* Debugger::CollectStackTrace() {
  Isolate* isolate = Isolate::Current();
  DebuggerStackTrace* stack_trace = new DebuggerStackTrace(8);
  Context& ctx = Context::Handle(isolate->top_context());
  Code& code = Code::Handle(isolate);
  StackFrameIterator iterator(false);
  StackFrame* frame = iterator.NextFrame();
  bool get_saved_context = false;
  bool optimized_frame_found = false;
  while (frame != NULL) {
    ASSERT(frame->IsValid());
    if (frame->IsDartFrame()) {
      code = frame->LookupDartCode();
      ActivationFrame* activation = new ActivationFrame(frame->pc(),
                                                        frame->fp(),
                                                        frame->sp(),
                                                        code);
      if (optimized_frame_found || code.is_optimized()) {
        // Set context to null, to avoid returning bad context variable values.
        activation->SetContext(Context::Handle());
        optimized_frame_found = true;
      } else {
        if (get_saved_context) {
          ctx = activation->GetSavedContext();
        }
        activation->SetContext(ctx);
      }
      stack_trace->AddActivation(activation);
      get_saved_context = activation->function().IsClosureFunction();
    } else if (frame->IsEntryFrame()) {
      ctx = reinterpret_cast<EntryFrame*>(frame)->SavedContext();
      get_saved_context = false;
    }
    frame = iterator.NextFrame();
  }
  return stack_trace;
}


void Debugger::SetExceptionPauseInfo(Dart_ExceptionPauseInfo pause_info) {
  ASSERT((pause_info == kNoPauseOnExceptions) ||
         (pause_info == kPauseOnUnhandledExceptions) ||
         (pause_info == kPauseOnAllExceptions));
  exc_pause_info_ = pause_info;
}


Dart_ExceptionPauseInfo Debugger::GetExceptionPauseInfo() {
  return (Dart_ExceptionPauseInfo)exc_pause_info_;
}


bool Debugger::ShouldPauseOnException(DebuggerStackTrace* stack_trace,
                                      const Instance& exc) {
  if (exc_pause_info_ == kNoPauseOnExceptions) {
    return false;
  }
  if (exc_pause_info_ == kPauseOnAllExceptions) {
    return true;
  }
  ASSERT(exc_pause_info_ == kPauseOnUnhandledExceptions);
  ActivationFrame* handler_frame = stack_trace->GetHandlerFrame(exc);
  if (handler_frame == NULL) {
    // Did not find an exception handler that catches this exception.
    // Note that this check is not precise, since we can't check
    // uninstantiated types, i.e. types containing type parameters.
    // Thus, we may report an exception as unhandled when in fact
    // it will be caught once we unwind the stack.
    return true;
  }
  return false;
}


void Debugger::SignalExceptionThrown(const Instance& exc) {
  // We ignore this exception event when the VM is executing code invoked
  // by the debugger to evaluate variables values, when we see a nested
  // breakpoint or exception event, or if the debugger is not
  // interested in exception events.
  if (ignore_breakpoints_ ||
      (stack_trace_ != NULL) ||
      (event_handler_ == NULL) ||
      (exc_pause_info_ == kNoPauseOnExceptions)) {
    return;
  }
  DebuggerStackTrace* stack_trace = CollectStackTrace();
  if (!ShouldPauseOnException(stack_trace, exc)) {
    return;
  }
  // No single-stepping possible after this pause event.
  last_bpt_line_ = -1;
  ASSERT(stack_trace_ == NULL);
  stack_trace_ = stack_trace;
  ASSERT(obj_cache_ == NULL);
  obj_cache_ = new RemoteObjectCache(64);
  DebuggerEvent event;
  event.type = kExceptionThrown;
  event.exception = &exc;
  ASSERT(event_handler_ != NULL);
  (*event_handler_)(&event);
  stack_trace_ = NULL;
  obj_cache_ = NULL;  // Remote object cache is zone allocated.
}


CodeBreakpoint* Debugger::MakeCodeBreakpoint(const Function& func,
                                             intptr_t first_token_pos,
                                             intptr_t last_token_pos) {
  ASSERT(func.HasCode());
  ASSERT(!func.HasOptimizedCode());
  Code& code = Code::Handle(func.unoptimized_code());
  ASSERT(!code.IsNull());
  PcDescriptors& desc = PcDescriptors::Handle(code.pc_descriptors());
  // We attempt to find the PC descriptor that is closest to the
  // beginning of the token range, in terms of native code address. If we
  // don't find a PC descriptor within the given range, we pick the
  // nearest one to the beginning of the range, in terms of token position.
  intptr_t best_fit_index = -1;
  intptr_t best_fit = INT_MAX;
  uword lowest_pc = kUwordMax;
  intptr_t lowest_pc_index = -1;
  for (int i = 0; i < desc.Length(); i++) {
    intptr_t desc_token_pos = desc.TokenPos(i);
    ASSERT(desc_token_pos >= 0);
    if (desc_token_pos < first_token_pos) {
      continue;
    }
    PcDescriptors::Kind kind = desc.DescriptorKind(i);
    if ((kind == PcDescriptors::kIcCall) ||
        (kind == PcDescriptors::kFuncCall) ||
        (kind == PcDescriptors::kReturn)) {
      if ((desc_token_pos - first_token_pos) < best_fit) {
        best_fit = desc_token_pos - first_token_pos;
        ASSERT(best_fit >= 0);
        best_fit_index = i;
      }
      if ((first_token_pos <= desc_token_pos) &&
          (desc_token_pos <= last_token_pos) &&
          (desc.PC(i) < lowest_pc)) {
        lowest_pc = desc.PC(i);
        lowest_pc_index = i;
      }
    }
  }
  if (lowest_pc_index >= 0) {
    // We found the the pc descriptor within the given token range that
    // has the lowest execution address. This is the first possible
    // breakpoint on the line. We use this instead of the nearest
    // PC descriptor measured in token index distance.
    best_fit_index = lowest_pc_index;
  }
  if (best_fit_index >= 0) {
    CodeBreakpoint* bpt = GetCodeBreakpoint(desc.PC(best_fit_index));
    // We should only ever have one code breakpoint at the same address.
    if (bpt != NULL) {
      return bpt;
    }

    bpt = new CodeBreakpoint(func, best_fit_index);
    if (FLAG_verbose_debug) {
      OS::Print("Setting breakpoint in function '%s' "
                "(%s:%"Pd") (Token %"Pd") (PC %#"Px")\n",
                String::Handle(func.name()).ToCString(),
                String::Handle(bpt->SourceUrl()).ToCString(),
                bpt->LineNumber(),
                bpt->token_pos(),
                bpt->pc());
    }
    RegisterCodeBreakpoint(bpt);
    return bpt;
  }
  return NULL;
}


SourceBreakpoint* Debugger::SetBreakpoint(const Function& target_function,
                                          intptr_t first_token_pos,
                                          intptr_t last_token_pos) {
  if ((last_token_pos < target_function.token_pos()) ||
      (target_function.end_token_pos() < first_token_pos)) {
    // The given token position is not within the target function.
    return NULL;
  }
  DeoptimizeWorld();
  ASSERT(!target_function.HasOptimizedCode());

  CodeBreakpoint* cbpt = NULL;
  SourceBreakpoint* source_bpt = NULL;
  if (target_function.HasCode()) {
    cbpt = MakeCodeBreakpoint(target_function, first_token_pos, last_token_pos);
    if (cbpt != NULL) {
      if (cbpt->src_bpt() != NULL) {
        // There is already a source breakpoint for the location.
        ASSERT(cbpt->src_bpt() ==
               GetSourceBreakpoint(target_function, cbpt->token_pos()));
        return cbpt->src_bpt();
      }
      // No source breakpoint exists yet that is associated with the code
      // breakpoint we found. (This is an internal breakpoint.) Adjust
      // the breakpoint location to the actual position where breakpoint
      // got set.
      first_token_pos = cbpt->token_pos();
    }
  } else {
    source_bpt = GetSourceBreakpoint(target_function, first_token_pos);
    if (source_bpt != NULL) {
      // A source breakpoint for this uncompiled location already
      // exists.
      return source_bpt;
    }
  }
  source_bpt = new SourceBreakpoint(nextId(), target_function, first_token_pos);
  RegisterSourceBreakpoint(source_bpt);
  if (FLAG_verbose_debug && !target_function.HasCode()) {
    OS::Print("Registering breakpoint for "
              "uncompiled function '%s' at line %"Pd"\n",
              target_function.ToFullyQualifiedCString(),
              source_bpt->LineNumber());
  }

  if (cbpt != NULL) {
    ASSERT(cbpt->src_bpt() == NULL);
    cbpt->set_src_bpt(source_bpt);
    SignalBpResolved(source_bpt);
  } else {
    if (FLAG_verbose_debug) {
      OS::Print("Failed to set breakpoint at '%s' line %"Pd"\n",
                String::Handle(source_bpt->SourceUrl()).ToCString(),
                source_bpt->LineNumber());
    }
  }

  if (target_function.HasImplicitClosureFunction()) {
    // There is a closurized version of this function. If the closure
    // is already compiled, we need to set a code breakpoint in its
    // code.
    const Function& closure =
        Function::Handle(target_function.ImplicitClosureFunction());
    if (closure.HasCode()) {
      ASSERT(!closure.HasOptimizedCode());
      CodeBreakpoint* closure_bpt =
          MakeCodeBreakpoint(closure, first_token_pos, last_token_pos);
      if ((closure_bpt != NULL) && (closure_bpt->src_bpt() == NULL)) {
        closure_bpt->set_src_bpt(source_bpt);
      }
    }
  }
  source_bpt->Enable();
  return source_bpt;
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


void Debugger::OneTimeBreakAtEntry(const Function& target_function) {
  InstrumentForStepping(target_function);
}


SourceBreakpoint* Debugger::SetBreakpointAtEntry(
      const Function& target_function) {
  ASSERT(!target_function.IsNull());
  return SetBreakpoint(target_function,
                       target_function.token_pos(),
                       target_function.end_token_pos());
}


SourceBreakpoint* Debugger::SetBreakpointAtLine(const String& script_url,
                                          intptr_t line_number) {
  Library& lib = Library::Handle();
  Script& script = Script::Handle();
  const GrowableObjectArray& libs =
      GrowableObjectArray::Handle(isolate_->object_store()->libraries());
  for (int i = 0; i < libs.Length(); i++) {
    lib ^= libs.At(i);
    script = lib.LookupScript(script_url);
    if (!script.IsNull()) {
      break;
    }
  }
  if (script.IsNull()) {
    if (FLAG_verbose_debug) {
      OS::Print("Failed to find script with url '%s'\n",
                script_url.ToCString());
    }
    return NULL;
  }
  intptr_t first_token_idx, last_token_idx;
  script.TokenRangeAtLine(line_number, &first_token_idx, &last_token_idx);
  if (first_token_idx < 0) {
    // Script does not contain the given line number.
    if (FLAG_verbose_debug) {
      OS::Print("Script '%s' does not contain line number %"Pd"\n",
                script_url.ToCString(), line_number);
    }
    return NULL;
  }
  const Function& func =
      Function::Handle(lib.LookupFunctionInScript(script, first_token_idx));
  if (func.IsNull()) {
    if (FLAG_verbose_debug) {
      OS::Print("No executable code at line %"Pd" in '%s'\n",
                line_number, script_url.ToCString());
    }
    return NULL;
  }
  if (last_token_idx < 0) {
    // The token at first_token_index is past the requested source line.
    // Set the breakpoint at the closest position after that line.
    last_token_idx = func.end_token_pos();
  }
  return SetBreakpoint(func, first_token_idx, last_token_idx);
}


intptr_t Debugger::CacheObject(const Object& obj) {
  ASSERT(obj_cache_ != NULL);
  return obj_cache_->AddObject(obj);
}


bool Debugger::IsValidObjectId(intptr_t obj_id) {
  ASSERT(obj_cache_ != NULL);
  return obj_cache_->IsValidId(obj_id);
}


RawObject* Debugger::GetCachedObject(intptr_t obj_id) {
  ASSERT(obj_cache_ != NULL);
  return obj_cache_->GetObj(obj_id);
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
    const Array& args = Array::Handle(Array::New(1));
    args.SetAt(0, object);
    result = DartEntry::InvokeFunction(getter_func, args);
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
    ASSERT(value.raw() != Object::transition_sentinel().raw());
    if (value.raw() != Object::sentinel().raw()) {
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
    result = DartEntry::InvokeFunction(getter_func, Object::empty_array());
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


void Debugger::CollectLibraryFields(const GrowableObjectArray& field_list,
                                    const Library& lib,
                                    const String& prefix,
                                    bool include_private_fields) {
  DictionaryIterator it(lib);
  Object& entry = Object::Handle(isolate_);
  Field& field = Field::Handle(isolate_);
  Class& cls = Class::Handle(isolate_);
  String& field_name = String::Handle(isolate_);
  Object& field_value = Object::Handle(isolate_);
  while (it.HasNext()) {
    entry = it.GetNext();
    if (entry.IsField()) {
      field ^= entry.raw();
      cls = field.owner();
      ASSERT(field.is_static());
      field_name = field.name();
      if ((field_name.CharAt(0) == '_') && !include_private_fields) {
        // Skip library-private field.
        continue;
      }
      field_value = GetStaticField(cls, field_name);
      if (!prefix.IsNull()) {
        field_name = String::Concat(prefix, field_name);
      }
      field_list.Add(field_name);
      field_list.Add(field_value);
    }
  }
}


RawArray* Debugger::GetLibraryFields(const Library& lib) {
  const GrowableObjectArray& field_list =
      GrowableObjectArray::Handle(GrowableObjectArray::New(8));
  CollectLibraryFields(field_list, lib, String::Handle(isolate_), true);
  return Array::MakeArray(field_list);
}


RawArray* Debugger::GetGlobalFields(const Library& lib) {
  const GrowableObjectArray& field_list =
      GrowableObjectArray::Handle(GrowableObjectArray::New(8));
  String& prefix_name = String::Handle(isolate_);
  CollectLibraryFields(field_list, lib, prefix_name, true);
  Library& imported = Library::Handle(isolate_);
  intptr_t num_imports = lib.num_imports();
  for (int i = 0; i < num_imports; i++) {
    imported = lib.ImportLibraryAt(i);
    ASSERT(!imported.IsNull());
    CollectLibraryFields(field_list, imported, prefix_name, false);
  }
  LibraryPrefix& prefix = LibraryPrefix::Handle(isolate_);
  LibraryPrefixIterator it(lib);
  while (it.HasNext()) {
    prefix = it.GetNext();
    prefix_name = prefix.name();
    ASSERT(!prefix_name.IsNull());
    prefix_name = String::Concat(prefix_name, Symbols::Dot());
    for (int i = 0; i < prefix.num_imports(); i++) {
      imported = prefix.GetLibrary(i);
      CollectLibraryFields(field_list, imported, prefix_name, false);
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


void Debugger::SetEventHandler(EventHandler* handler) {
  event_handler_ = handler;
}


bool Debugger::IsDebuggable(const Function& func) {
  RawFunction::Kind fkind = func.kind();
  if ((fkind == RawFunction::kImplicitGetter) ||
      (fkind == RawFunction::kImplicitSetter) ||
      (fkind == RawFunction::kConstImplicitGetter) ||
      (fkind == RawFunction::kMethodExtractor)) {
    return false;
  }
  const Class& cls = Class::Handle(func.Owner());
  const Library& lib = Library::Handle(cls.library());
  return lib.IsDebuggable();
}


void Debugger::SignalBpReached() {
  // We ignore this breakpoint when the VM is executing code invoked
  // by the debugger to evaluate variables values, or when we see a nested
  // breakpoint or exception event.
  if (ignore_breakpoints_ || (stack_trace_ != NULL)) {
    return;
  }
  DebuggerStackTrace* stack_trace = CollectStackTrace();
  ASSERT(stack_trace->Length() > 0);
  ActivationFrame* top_frame = stack_trace->ActivationFrameAt(0);
  ASSERT(top_frame != NULL);
  CodeBreakpoint* bpt = GetCodeBreakpoint(top_frame->pc());
  ASSERT(bpt != NULL);
  if (FLAG_verbose_debug) {
    OS::Print(">>> hit %s breakpoint at %s:%"Pd" "
              "(token %"Pd") (address %#"Px")\n",
              bpt->IsInternal() ? "internal" : "user",
              String::Handle(bpt->SourceUrl()).ToCString(),
              bpt->LineNumber(),
              bpt->token_pos(),
              top_frame->pc());
  }

  if (!bpt->IsInternal()) {
    // This is a user-defined breakpoint so we call the breakpoint
    // callback even if it is on the same line as the previous breakpoint.
    last_bpt_line_ = -1;
  }

  bool notify_frontend =
    (last_bpt_line_ < 0) || (last_bpt_line_ != bpt->LineNumber());

  if (notify_frontend) {
    resume_action_ = kContinue;
    if (event_handler_ != NULL) {
      ASSERT(stack_trace_ == NULL);
      ASSERT(obj_cache_ == NULL);
      obj_cache_ = new RemoteObjectCache(64);
      stack_trace_ = stack_trace;
      DebuggerEvent event;
      event.type = kBreakpointReached;
      ASSERT(stack_trace->Length() > 0);
      event.top_frame = stack_trace->ActivationFrameAt(0);
      (*event_handler_)(&event);
      stack_trace_ = NULL;
      obj_cache_ = NULL;  // Remote object cache is zone allocated.
      last_bpt_line_ = bpt->LineNumber();
    }
  }

  Function& currently_instrumented_func = Function::Handle();
  if (bpt->IsInternal()) {
    currently_instrumented_func = bpt->function();
  }
  Function& func_to_instrument = Function::Handle();
  if (resume_action_ == kContinue) {
    // Nothing to do here, any potential instrumentation will be removed
    // below.
  } else if (resume_action_ == kStepOver) {
    func_to_instrument = bpt->function();
    if (bpt->breakpoint_kind_ == PcDescriptors::kReturn) {
      // If we are at the function return, do a StepOut action.
      if (stack_trace->Length() > 1) {
        ActivationFrame* caller_frame = stack_trace->ActivationFrameAt(1);
        func_to_instrument = caller_frame->function().raw();
      }
    }
  } else if (resume_action_ == kStepInto) {
    // If the call target is not debuggable, we treat StepInto like
    // a StepOver, that is we instrument the current function.
    if (bpt->breakpoint_kind_ == PcDescriptors::kIcCall) {
      func_to_instrument = bpt->function();
      ICData& ic_data = ICData::Handle();
      Array& descriptor = Array::Handle();
      const Code& code =
          Code::Handle(Function::Handle(bpt->function_).unoptimized_code());
      CodePatcher::GetInstanceCallAt(bpt->pc_, code, &ic_data, &descriptor);
      ArgumentsDescriptor arg_descriptor(descriptor);
      ActivationFrame* top_frame = stack_trace->ActivationFrameAt(0);
      intptr_t num_args = arg_descriptor.Count();
      Instance& receiver =
          Instance::Handle(top_frame->GetInstanceCallReceiver(num_args));
      Code& target_code =
          Code::Handle(ResolveCompileInstanceCallTarget(receiver,
                                                        ic_data,
                                                        descriptor));
      if (!target_code.IsNull()) {
        Function& callee = Function::Handle(target_code.function());
        if (IsDebuggable(callee)) {
          func_to_instrument = callee.raw();
        }
      }
    } else if (bpt->breakpoint_kind_ == PcDescriptors::kFuncCall) {
      func_to_instrument = bpt->function();
      const Code& code = Code::Handle(func_to_instrument.CurrentCode());
      const Function& callee =
          Function::Handle(code.GetStaticCallTargetFunctionAt(bpt->pc_));
      ASSERT(!callee.IsNull());
      if (IsDebuggable(callee)) {
        func_to_instrument = callee.raw();
      }
    } else {
      ASSERT(bpt->breakpoint_kind_ == PcDescriptors::kReturn);
      // Treat like stepping out to caller.
      if (stack_trace->Length() > 1) {
        ActivationFrame* caller_frame = stack_trace->ActivationFrameAt(1);
        func_to_instrument = caller_frame->function().raw();
      }
    }
  } else {
    ASSERT(resume_action_ == kStepOut);
    // Set stepping breakpoints in the caller.
    if (stack_trace->Length() > 1) {
      ActivationFrame* caller_frame = stack_trace->ActivationFrameAt(1);
      func_to_instrument = caller_frame->function().raw();
    }
  }

  if (func_to_instrument.IsNull() ||
      (func_to_instrument.raw() != currently_instrumented_func.raw())) {
    last_bpt_line_ = -1;
    RemoveInternalBreakpoints();  // *bpt is now invalid.
    if (!func_to_instrument.IsNull()) {
      InstrumentForStepping(func_to_instrument);
    }
  }
}


void Debugger::Initialize(Isolate* isolate) {
  if (initialized_) {
    return;
  }
  isolate_ = isolate;
  // Create a port here, we don't expect to receive any messages on this port.
  // This port will be used as a unique ID to represet the isolate in the
  // debugger wire protocol messages.
  // NOTE: SetLive is never called on this port.
  isolate_id_ = PortMap::CreatePort(isolate->message_handler());
  initialized_ = true;

  // Signal isolate creation event.
  SignalIsolateEvent(Debugger::kIsolateCreated);
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
      Class& owner = Class::Handle(lookup_function.Owner());
      Function& closure =
          Function::Handle(owner.LookupClosureFunction(bpt->token_pos()));
      if (!closure.IsNull() && (closure.raw() != lookup_function.raw())) {
        if (FLAG_verbose_debug) {
          OS::Print("Resetting pending breakpoint to function %s\n",
                    closure.ToFullyQualifiedCString());
        }
        bpt->set_function(closure);
      } else {
        if (FLAG_verbose_debug) {
          OS::Print("Enable pending breakpoint for function '%s'\n",
                    String::Handle(lookup_function.name()).ToCString());
        }
        // Set breakpoint in newly compiled code of function func.
        CodeBreakpoint* cbpt =
            MakeCodeBreakpoint(func, bpt->token_pos(), func.end_token_pos());
        if (cbpt != NULL) {
          cbpt->set_src_bpt(bpt);
          SignalBpResolved(bpt);
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
void Debugger::RemoveBreakpoint(intptr_t bp_id) {
  ASSERT(src_breakpoints_ != NULL);
  SourceBreakpoint* prev_bpt = NULL;
  SourceBreakpoint* curr_bpt = src_breakpoints_;
  while (curr_bpt != NULL) {
    if (curr_bpt->id() == bp_id) {
      if (prev_bpt == NULL) {
        src_breakpoints_ = src_breakpoints_->next();
      } else {
        prev_bpt->set_next(curr_bpt->next());
      }
      // Remove references from code breakpoints to this source breakpoint,
      // and disable the code breakpoints.
      UnlinkCodeBreakpoints(curr_bpt);
      delete curr_bpt;
      return;
    }
    prev_bpt = curr_bpt;
    curr_bpt = curr_bpt->next();
  }
  // bpt is not a registered breakpoint, nothing to do.
}


// Turn code breakpoints associated with the given source breakpoint into
// internal breakpoints. They will later be deleted when control
// returns from the user-defined breakpoint callback. Also, disable the
// breakpoint so it no longer fires if it should be hit before it gets
// deleted.
void Debugger::UnlinkCodeBreakpoints(SourceBreakpoint* src_bpt) {
  ASSERT(src_bpt != NULL);
  CodeBreakpoint* curr_bpt = code_breakpoints_;
  while (curr_bpt != NULL) {
    if (curr_bpt->src_bpt() == src_bpt) {
      curr_bpt->Disable();
      curr_bpt->set_src_bpt(NULL);
    }
    curr_bpt = curr_bpt->next();
  }
}


// Remove and delete internal breakpoints, i.e. breakpoints that
// are not associated with a source breakpoint.
void Debugger::RemoveInternalBreakpoints() {
  CodeBreakpoint* prev_bpt = NULL;
  CodeBreakpoint* curr_bpt = code_breakpoints_;
  while (curr_bpt != NULL) {
    if (curr_bpt->src_bpt() == NULL) {
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


SourceBreakpoint* Debugger::GetSourceBreakpoint(const Function& func,
                                                intptr_t token_pos) {
  SourceBreakpoint* bpt = src_breakpoints_;
  while (bpt != NULL) {
    if ((bpt->function() == func.raw()) &&
        (bpt->token_pos() == token_pos)) {
      return bpt;
    }
    bpt = bpt->next();
  }
  return NULL;
}


SourceBreakpoint* Debugger::GetBreakpointById(intptr_t id) {
  SourceBreakpoint* bpt = src_breakpoints_;
  while (bpt != NULL) {
    if (bpt->id() == id) {
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
