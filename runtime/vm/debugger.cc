// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/debugger.h"

#include "include/dart_api.h"

#include "vm/code_descriptors.h"
#include "vm/code_patcher.h"
#include "vm/compiler/api/deopt_id.h"
#include "vm/compiler/assembler/disassembler.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/dart_entry.h"
#include "vm/flags.h"
#include "vm/globals.h"
#include "vm/isolate_reload.h"
#include "vm/json_stream.h"
#include "vm/kernel.h"
#include "vm/longjump.h"
#include "vm/message_handler.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/os.h"
#include "vm/parser.h"
#include "vm/port.h"
#include "vm/runtime_entry.h"
#include "vm/service.h"
#include "vm/service_event.h"
#include "vm/service_isolate.h"
#include "vm/stack_frame.h"
#include "vm/stack_trace.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"
#include "vm/thread_interrupter.h"
#include "vm/timeline.h"
#include "vm/token_position.h"
#include "vm/visitor.h"

#if !defined(DART_PRECOMPILED_RUNTIME)
#include "vm/deopt_instructions.h"
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

namespace dart {

DEFINE_FLAG(bool,
            trace_debugger_stacktrace,
            false,
            "Trace debugger stacktrace collection");
DEFINE_FLAG(bool, trace_rewind, false, "Trace frame rewind");
DEFINE_FLAG(bool, verbose_debug, false, "Verbose debugger messages");

DECLARE_FLAG(bool, trace_deoptimization);
DECLARE_FLAG(bool, warn_on_pause_with_no_debugger);

#ifndef PRODUCT

// Create an unresolved breakpoint in given token range and script.
BreakpointLocation::BreakpointLocation(const Script& script,
                                       TokenPosition token_pos,
                                       TokenPosition end_token_pos,
                                       intptr_t requested_line_number,
                                       intptr_t requested_column_number)
    : script_(script.raw()),
      url_(script.url()),
      token_pos_(token_pos),
      end_token_pos_(end_token_pos),
      next_(NULL),
      conditions_(NULL),
      requested_line_number_(requested_line_number),
      requested_column_number_(requested_column_number),
      function_(Function::null()),
      code_token_pos_(TokenPosition::kNoSource) {
  ASSERT(!script.IsNull());
  ASSERT(token_pos_.IsReal());
}

// Create a latent breakpoint at given url and line number.
BreakpointLocation::BreakpointLocation(const String& url,
                                       intptr_t requested_line_number,
                                       intptr_t requested_column_number)
    : script_(Script::null()),
      url_(url.raw()),
      token_pos_(TokenPosition::kNoSource),
      end_token_pos_(TokenPosition::kNoSource),
      next_(NULL),
      conditions_(NULL),
      requested_line_number_(requested_line_number),
      requested_column_number_(requested_column_number),
      function_(Function::null()),
      code_token_pos_(TokenPosition::kNoSource) {
  ASSERT(requested_line_number_ >= 0);
}

BreakpointLocation::~BreakpointLocation() {
  Breakpoint* bpt = breakpoints();
  while (bpt != NULL) {
    Breakpoint* temp = bpt;
    bpt = bpt->next();
    delete temp;
  }
}

bool BreakpointLocation::AnyEnabled() const {
  return breakpoints() != NULL;
}

void BreakpointLocation::SetResolved(const Function& func,
                                     TokenPosition token_pos) {
  ASSERT(!IsLatent());
  ASSERT(func.script() == script_);
  ASSERT(token_pos.IsWithin(func.token_pos(), func.end_token_pos()));
  ASSERT(func.is_debuggable());
  function_ = func.raw();
  token_pos_ = token_pos;
  end_token_pos_ = token_pos;
  code_token_pos_ = token_pos;
}

void BreakpointLocation::GetCodeLocation(Script* script,
                                         TokenPosition* pos) const {
  if (IsLatent()) {
    *script = Script::null();
    *pos = TokenPosition::kNoSource;
  } else {
    *script = this->script();
    *pos = token_pos_;
  }
}

void Breakpoint::set_bpt_location(BreakpointLocation* new_bpt_location) {
  // Only latent breakpoints can be moved.
  ASSERT((new_bpt_location == NULL) || bpt_location_->IsLatent());
  bpt_location_ = new_bpt_location;
}

void Breakpoint::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  visitor->VisitPointer(reinterpret_cast<ObjectPtr*>(&closure_));
}

void BreakpointLocation::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  visitor->VisitPointer(reinterpret_cast<ObjectPtr*>(&script_));
  visitor->VisitPointer(reinterpret_cast<ObjectPtr*>(&url_));
  visitor->VisitPointer(reinterpret_cast<ObjectPtr*>(&function_));

  Breakpoint* bpt = conditions_;
  while (bpt != NULL) {
    bpt->VisitObjectPointers(visitor);
    bpt = bpt->next();
  }
}

void Breakpoint::PrintJSON(JSONStream* stream) {
  JSONObject jsobj(stream);
  jsobj.AddProperty("type", "Breakpoint");

  jsobj.AddFixedServiceId("breakpoints/%" Pd "", id());
  jsobj.AddProperty("breakpointNumber", id());
  if (is_synthetic_async()) {
    jsobj.AddProperty("isSyntheticAsyncContinuation", is_synthetic_async());
  }
  jsobj.AddProperty("resolved", bpt_location_->IsResolved());
  if (bpt_location_->IsResolved()) {
    jsobj.AddLocation(bpt_location_);
  } else {
    jsobj.AddUnresolvedLocation(bpt_location_);
  }
}

void CodeBreakpoint::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  visitor->VisitPointer(reinterpret_cast<ObjectPtr*>(&code_));
  visitor->VisitPointer(reinterpret_cast<ObjectPtr*>(&saved_value_));
}

ActivationFrame::ActivationFrame(uword pc,
                                 uword fp,
                                 uword sp,
                                 const Code& code,
                                 const Array& deopt_frame,
                                 intptr_t deopt_frame_offset,
                                 ActivationFrame::Kind kind)
    : pc_(pc),
      fp_(fp),
      sp_(sp),
      ctx_(Context::ZoneHandle()),
      code_(Code::ZoneHandle(code.raw())),
      function_(Function::ZoneHandle(code.function())),
      live_frame_((kind == kRegular) || (kind == kAsyncActivation)),
      token_pos_initialized_(false),
      token_pos_(TokenPosition::kNoSource),
      try_index_(-1),
      deopt_id_(DeoptId::kNone),
      line_number_(-1),
      column_number_(-1),
      context_level_(-1),
      deopt_frame_(Array::ZoneHandle(deopt_frame.raw())),
      deopt_frame_offset_(deopt_frame_offset),
      kind_(kind),
      vars_initialized_(false),
      var_descriptors_(LocalVarDescriptors::ZoneHandle()),
      desc_indices_(8),
      pc_desc_(PcDescriptors::ZoneHandle()) {
  ASSERT(!function_.IsNull());
}

ActivationFrame::ActivationFrame(Kind kind)
    : pc_(0),
      fp_(0),
      sp_(0),
      ctx_(Context::ZoneHandle()),
      code_(Code::ZoneHandle()),
      function_(Function::ZoneHandle()),
      live_frame_(kind == kRegular),
      token_pos_initialized_(false),
      token_pos_(TokenPosition::kNoSource),
      try_index_(-1),
      deopt_id_(DeoptId::kNone),
      line_number_(-1),
      column_number_(-1),
      context_level_(-1),
      deopt_frame_(Array::ZoneHandle()),
      deopt_frame_offset_(0),
      kind_(kind),
      vars_initialized_(false),
      var_descriptors_(LocalVarDescriptors::ZoneHandle()),
      desc_indices_(8),
      pc_desc_(PcDescriptors::ZoneHandle()) {}

ActivationFrame::ActivationFrame(const Closure& async_activation)
    : pc_(0),
      fp_(0),
      sp_(0),
      ctx_(Context::ZoneHandle()),
      code_(Code::ZoneHandle()),
      function_(Function::ZoneHandle()),
      live_frame_(false),
      token_pos_initialized_(false),
      token_pos_(TokenPosition::kNoSource),
      try_index_(-1),
      deopt_id_(DeoptId::kNone),
      line_number_(-1),
      column_number_(-1),
      context_level_(-1),
      deopt_frame_(Array::ZoneHandle()),
      deopt_frame_offset_(0),
      kind_(kAsyncActivation),
      vars_initialized_(false),
      var_descriptors_(LocalVarDescriptors::ZoneHandle()),
      desc_indices_(8),
      pc_desc_(PcDescriptors::ZoneHandle()) {
  // Extract the function and the code from the asynchronous activation.
  function_ = async_activation.function();
  // Force-optimize functions should not be debuggable.
  ASSERT(!function_.ForceOptimize());
  function_.EnsureHasCompiledUnoptimizedCode();
  code_ = function_.unoptimized_code();
  ctx_ = async_activation.context();
  ASSERT(fp_ == 0);
  ASSERT(!ctx_.IsNull());
}

bool Debugger::NeedsIsolateEvents() {
  return !Isolate::IsSystemIsolate(isolate_) &&
         Service::isolate_stream.enabled();
}

bool Debugger::NeedsDebugEvents() {
  ASSERT(!Isolate::IsSystemIsolate(isolate_));
  return FLAG_warn_on_pause_with_no_debugger || Service::debug_stream.enabled();
}

void Debugger::InvokeEventHandler(ServiceEvent* event) {
  ASSERT(!event->IsPause());  // For pause events, call Pause instead.
  Service::HandleEvent(event);
}

ErrorPtr Debugger::PauseInterrupted() {
  return PauseRequest(ServiceEvent::kPauseInterrupted);
}

ErrorPtr Debugger::PausePostRequest() {
  return PauseRequest(ServiceEvent::kPausePostRequest);
}

ErrorPtr Debugger::PauseRequest(ServiceEvent::EventKind kind) {
  if (ignore_breakpoints_ || IsPaused()) {
    // We don't let the isolate get interrupted if we are already
    // paused or ignoring breakpoints.
    return Thread::Current()->StealStickyError();
  }
  ServiceEvent event(isolate_, kind);
  DebuggerStackTrace* trace = CollectStackTrace();
  if (trace->Length() > 0) {
    event.set_top_frame(trace->FrameAt(0));
  }
  CacheStackTraces(trace, CollectAsyncCausalStackTrace(),
                   CollectAwaiterReturnStackTrace());
  resume_action_ = kContinue;
  Pause(&event);
  HandleSteppingRequest(trace);
  ClearCachedStackTraces();

  // If any error occurred while in the debug message loop, return it here.
  NoSafepointScope no_safepoint;
  ErrorPtr error = Thread::Current()->StealStickyError();
  ASSERT((error == Error::null()) || error->IsUnwindError());
  return error;
}

void Debugger::SendBreakpointEvent(ServiceEvent::EventKind kind,
                                   Breakpoint* bpt) {
  if (NeedsDebugEvents()) {
    // TODO(turnidge): Currently we send single-shot breakpoint events
    // to the vm service.  Do we want to change this?
    ServiceEvent event(isolate_, kind);
    event.set_breakpoint(bpt);
    InvokeEventHandler(&event);
  }
}

void BreakpointLocation::AddBreakpoint(Breakpoint* bpt, Debugger* dbg) {
  bpt->set_next(breakpoints());
  set_breakpoints(bpt);

  dbg->SyncBreakpointLocation(this);
  dbg->SendBreakpointEvent(ServiceEvent::kBreakpointAdded, bpt);
}

Breakpoint* BreakpointLocation::AddRepeated(Debugger* dbg) {
  Breakpoint* bpt = breakpoints();
  while (bpt != NULL) {
    if (bpt->IsRepeated()) break;
    bpt = bpt->next();
  }
  if (bpt == NULL) {
    bpt = new Breakpoint(dbg->nextId(), this);
    bpt->SetIsRepeated();
    AddBreakpoint(bpt, dbg);
  }
  return bpt;
}

Breakpoint* BreakpointLocation::AddSingleShot(Debugger* dbg) {
  Breakpoint* bpt = breakpoints();
  while (bpt != NULL) {
    if (bpt->IsSingleShot()) break;
    bpt = bpt->next();
  }
  if (bpt == NULL) {
    bpt = new Breakpoint(dbg->nextId(), this);
    bpt->SetIsSingleShot();
    AddBreakpoint(bpt, dbg);
  }
  return bpt;
}

Breakpoint* BreakpointLocation::AddPerClosure(Debugger* dbg,
                                              const Instance& closure,
                                              bool for_over_await) {
  Breakpoint* bpt = NULL;
  // Do not reuse existing breakpoints for stepping over await clauses.
  // A second async step-over command will set a new breakpoint before
  // the existing one gets deleted when first async step-over resumes.
  if (!for_over_await) {
    bpt = breakpoints();
    while (bpt != NULL) {
      if (bpt->IsPerClosure() && (bpt->closure() == closure.raw())) break;
      bpt = bpt->next();
    }
  }
  if (bpt == NULL) {
    bpt = new Breakpoint(dbg->nextId(), this);
    bpt->SetIsPerClosure(closure);
    bpt->set_is_synthetic_async(for_over_await);
    AddBreakpoint(bpt, dbg);
  }
  return bpt;
}

const char* Debugger::QualifiedFunctionName(const Function& func) {
  const String& func_name = String::Handle(func.name());
  Class& func_class = Class::Handle(func.Owner());
  String& class_name = String::Handle(func_class.Name());

  return OS::SCreate(Thread::Current()->zone(), "%s%s%s",
                     func_class.IsTopLevel() ? "" : class_name.ToCString(),
                     func_class.IsTopLevel() ? "" : ".", func_name.ToCString());
}

// Returns true if the function |func| overlaps the token range
// [|token_pos|, |end_token_pos|] in |script|.
static bool FunctionOverlaps(const Function& func,
                             const Script& script,
                             TokenPosition token_pos,
                             TokenPosition end_token_pos) {
  const TokenPosition& func_start = func.token_pos();
  if (token_pos.IsWithin(func_start, func.end_token_pos()) ||
      func_start.IsWithin(token_pos, end_token_pos)) {
    // Check script equality last because it allocates handles as a side effect.
    return func.script() == script.raw();
  }
  return false;
}

static bool IsImplicitFunction(const Function& func) {
  switch (func.kind()) {
    case FunctionLayout::kImplicitGetter:
    case FunctionLayout::kImplicitSetter:
    case FunctionLayout::kImplicitStaticGetter:
    case FunctionLayout::kFieldInitializer:
    case FunctionLayout::kMethodExtractor:
    case FunctionLayout::kNoSuchMethodDispatcher:
    case FunctionLayout::kInvokeFieldDispatcher:
    case FunctionLayout::kIrregexpFunction:
      return true;
    default:
      if (func.token_pos() == func.end_token_pos()) {
        // |func| could be an implicit constructor for example.
        return true;
      }
  }
  return false;
}

bool Debugger::HasBreakpoint(const Function& func, Zone* zone) {
  if (!func.HasCode()) {
    // If the function is not compiled yet, just check whether there
    // is a user-defined breakpoint that falls into the token
    // range of the function. This may be a false positive: the breakpoint
    // might be inside a local closure.
    Script& script = Script::Handle(zone);
    BreakpointLocation* sbpt = breakpoint_locations_;
    while (sbpt != NULL) {
      script = sbpt->script();
      if (FunctionOverlaps(func, script, sbpt->token_pos(),
                           sbpt->end_token_pos())) {
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

bool Debugger::HasBreakpoint(const Code& code) {
  CodeBreakpoint* cbpt = code_breakpoints_;
  while (cbpt != NULL) {
    if (code.raw() == cbpt->code_) {
      return true;
    }
    cbpt = cbpt->next_;
  }
  return false;
}

void Debugger::PrintBreakpointsToJSONArray(JSONArray* jsarr) const {
  PrintBreakpointsListToJSONArray(breakpoint_locations_, jsarr);
  PrintBreakpointsListToJSONArray(latent_locations_, jsarr);
}

void Debugger::PrintBreakpointsListToJSONArray(BreakpointLocation* sbpt,
                                               JSONArray* jsarr) const {
  while (sbpt != NULL) {
    Breakpoint* bpt = sbpt->breakpoints();
    while (bpt != NULL) {
      jsarr->AddValue(bpt);
      bpt = bpt->next();
    }
    sbpt = sbpt->next_;
  }
}

void Debugger::PrintSettingsToJSONObject(JSONObject* jsobj) const {
  // This won't cut it when we support filtering by class, etc.
  switch (GetExceptionPauseInfo()) {
    case kNoPauseOnExceptions:
      jsobj->AddProperty("_exceptions", "none");
      break;
    case kPauseOnAllExceptions:
      jsobj->AddProperty("_exceptions", "all");
      break;
    case kPauseOnUnhandledExceptions:
      jsobj->AddProperty("_exceptions", "unhandled");
      break;
    default:
      UNREACHABLE();
  }
}

ActivationFrame::Relation ActivationFrame::CompareTo(uword other_fp) const {
  if (fp() == other_fp) {
    return kSelf;
  }
  return IsCalleeFrameOf(other_fp, fp()) ? kCallee : kCaller;
}

StringPtr ActivationFrame::QualifiedFunctionName() {
  return String::New(Debugger::QualifiedFunctionName(function()));
}

StringPtr ActivationFrame::SourceUrl() {
  const Script& script = Script::Handle(SourceScript());
  return script.url();
}

ScriptPtr ActivationFrame::SourceScript() {
  return function().script();
}

LibraryPtr ActivationFrame::Library() {
  const Class& cls = Class::Handle(function().origin());
  return cls.library();
}

void ActivationFrame::GetPcDescriptors() {
  if (pc_desc_.IsNull()) {
    pc_desc_ = code().pc_descriptors();
    ASSERT(!pc_desc_.IsNull());
  }
}

// If not token_pos_initialized_, compute token_pos_, try_index_ and
// deopt_id_.
TokenPosition ActivationFrame::TokenPos() {
  if (!token_pos_initialized_) {
    token_pos_initialized_ = true;
    token_pos_ = TokenPosition::kNoSource;
    GetPcDescriptors();
    PcDescriptors::Iterator iter(pc_desc_, PcDescriptorsLayout::kAnyKind);
    const uword pc_offset = pc_ - code().PayloadStart();
    while (iter.MoveNext()) {
      if (iter.PcOffset() == pc_offset) {
        try_index_ = iter.TryIndex();
        token_pos_ = iter.TokenPos();
        deopt_id_ = iter.DeoptId();
        break;
      }
    }
  }
  return token_pos_;
}

intptr_t ActivationFrame::TryIndex() {
  if (!token_pos_initialized_) {
    TokenPos();  // Side effect: computes token_pos_initialized_, try_index_.
  }
  return try_index_;
}

intptr_t ActivationFrame::DeoptId() {
  if (!token_pos_initialized_) {
    TokenPos();  // Side effect: computes token_pos_initialized_, try_index_.
  }
  return deopt_id_;
}

intptr_t ActivationFrame::LineNumber() {
  // Compute line number lazily since it causes scanning of the script.
  const TokenPosition& token_pos = TokenPos();
  if ((line_number_ < 0) && token_pos.IsReal()) {
    const Script& script = Script::Handle(SourceScript());
    script.GetTokenLocation(token_pos, &line_number_, &column_number_);
  }
  return line_number_;
}

intptr_t ActivationFrame::ColumnNumber() {
  // Compute column number lazily since it causes scanning of the script.
  const TokenPosition& token_pos = TokenPos();
  if ((column_number_ < 0) && token_pos.IsReal()) {
    const Script& script = Script::Handle(SourceScript());
    script.GetTokenLocation(token_pos, &line_number_, &column_number_);
  }
  return column_number_;
}

void ActivationFrame::GetVarDescriptors() {
  if (var_descriptors_.IsNull()) {
    Code& unoptimized_code = Code::Handle(function().unoptimized_code());
    if (unoptimized_code.IsNull()) {
      Thread* thread = Thread::Current();
      Zone* zone = thread->zone();
      const Error& error = Error::Handle(
          zone, Compiler::EnsureUnoptimizedCode(thread, function()));
      if (!error.IsNull()) {
        Exceptions::PropagateError(error);
      }
      unoptimized_code = function().unoptimized_code();
    }
    ASSERT(!unoptimized_code.IsNull());
    var_descriptors_ = unoptimized_code.GetLocalVarDescriptors();
    ASSERT(!var_descriptors_.IsNull());
  }
}

bool ActivationFrame::IsDebuggable() const {
  ASSERT(!function().IsNull());
  return Debugger::IsDebuggable(function());
}

void ActivationFrame::PrintDescriptorsError(const char* message) {
  OS::PrintErr("Bad descriptors: %s\n", message);
  OS::PrintErr("function %s\n", function().ToQualifiedCString());
  OS::PrintErr("pc_ %" Px "\n", pc_);
  OS::PrintErr("deopt_id_ %" Px "\n", deopt_id_);
  OS::PrintErr("context_level_ %" Px "\n", context_level_);
  OS::PrintErr("token_pos_ %s\n", token_pos_.ToCString());
  {
    DisassembleToStdout formatter;
    code().Disassemble(&formatter);
    PcDescriptors::Handle(code().pc_descriptors()).Print();
  }
  StackFrameIterator frames(ValidationPolicy::kDontValidateFrames,
                            Thread::Current(),
                            StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* frame = frames.NextFrame();
  while (frame != NULL) {
    OS::PrintErr("%s\n", frame->ToCString());
    frame = frames.NextFrame();
  }
  OS::Abort();
}

// Calculate the context level at the current pc of the frame.
intptr_t ActivationFrame::ContextLevel() {
  ASSERT(live_frame_);
  const Context& ctx = GetSavedCurrentContext();
  if (context_level_ < 0 && !ctx.IsNull()) {
    ASSERT(!code_.is_optimized());
    GetVarDescriptors();
    intptr_t deopt_id = DeoptId();
    if (deopt_id == DeoptId::kNone) {
      PrintDescriptorsError("Missing deopt id");
    }
    intptr_t var_desc_len = var_descriptors_.Length();
    bool found = false;
    // We store the deopt ids as real token positions.
    const auto to_compare = TokenPosition::Deserialize(deopt_id);
    for (intptr_t cur_idx = 0; cur_idx < var_desc_len; cur_idx++) {
      LocalVarDescriptorsLayout::VarInfo var_info;
      var_descriptors_.GetInfo(cur_idx, &var_info);
      const int8_t kind = var_info.kind();
      if ((kind == LocalVarDescriptorsLayout::kContextLevel) &&
          to_compare.IsWithin(var_info.begin_pos, var_info.end_pos)) {
        context_level_ = var_info.index();
        found = true;
        break;
      }
    }
    if (!found) {
      PrintDescriptorsError("Missing context level in var descriptors");
    }
    ASSERT(context_level_ >= 0);
  }
  return context_level_;
}

ObjectPtr ActivationFrame::GetAsyncContextVariable(const String& name) {
  if (!function_.IsAsyncClosure() && !function_.IsAsyncGenClosure()) {
    return Object::null();
  }
  GetVarDescriptors();
  intptr_t var_ctxt_level = -1;
  intptr_t ctxt_slot = -1;
  intptr_t var_desc_len = var_descriptors_.Length();
  for (intptr_t i = 0; i < var_desc_len; i++) {
    LocalVarDescriptorsLayout::VarInfo var_info;
    var_descriptors_.GetInfo(i, &var_info);
    if (var_descriptors_.GetName(i) == name.raw()) {
      const int8_t kind = var_info.kind();
      if (!live_frame_) {
        ASSERT(kind == LocalVarDescriptorsLayout::kContextVar);
      }
      const auto variable_index = VariableIndex(var_info.index());
      if (kind == LocalVarDescriptorsLayout::kStackVar) {
        return GetStackVar(variable_index);
      } else {
        ASSERT(kind == LocalVarDescriptorsLayout::kContextVar);
        var_ctxt_level = var_info.scope_id;
        ctxt_slot = variable_index.value();
        break;
      }
    }
  }
  if (var_ctxt_level >= 0) {
    if (!live_frame_) {
      ASSERT(!ctx_.IsNull());
      // Compiled code uses relative context levels, i.e. the frame context
      // level is always 0 on entry.
      const intptr_t frame_ctx_level = 0;
      return GetRelativeContextVar(var_ctxt_level, ctxt_slot, frame_ctx_level);
    }
    return GetContextVar(var_ctxt_level, ctxt_slot);
  }
  return Object::null();
}

ObjectPtr ActivationFrame::GetAsyncAwaiter(
    CallerClosureFinder* caller_closure_finder) {
  if (!function_.IsNull() &&
      (function_.IsAsyncClosure() || function_.IsAsyncGenClosure())) {
    // This is only possible for frames that are active on the stack.
    if (fp() == 0) {
      return Object::null();
    }

    // Look up caller's closure on the stack.
    ObjectPtr* last_caller_obj = reinterpret_cast<ObjectPtr*>(GetCallerSp());
    Closure& closure = Closure::Handle();
    closure = StackTraceUtils::FindClosureInFrame(last_caller_obj, function_);

    if (!closure.IsNull() && caller_closure_finder->IsRunningAsync(closure)) {
      closure = caller_closure_finder->FindCaller(closure);
      return closure.raw();
    }
  }

  return Object::null();
}

bool ActivationFrame::HandlesException(const Instance& exc_obj) {
  if ((kind_ == kAsyncSuspensionMarker) || (kind_ == kAsyncCausal)) {
    // These frames are historical.
    return false;
  }
  intptr_t try_index = TryIndex();
  if (try_index < 0) {
    return false;
  }
  ExceptionHandlers& handlers = ExceptionHandlers::Handle();
  Array& handled_types = Array::Handle();
  AbstractType& type = Type::Handle();
  const bool is_async =
      function().IsAsyncClosure() || function().IsAsyncGenClosure();
  handlers = code().exception_handlers();
  ASSERT(!handlers.IsNull());
  intptr_t num_handlers_checked = 0;
  while (try_index != kInvalidTryIndex) {
    // Detect circles in the exception handler data.
    num_handlers_checked++;
    ASSERT(num_handlers_checked <= handlers.num_entries());
    // Only consider user written handlers for async methods.
    if (!is_async || !handlers.IsGenerated(try_index)) {
      handled_types = handlers.GetHandledTypes(try_index);
      const intptr_t num_types = handled_types.Length();
      for (intptr_t k = 0; k < num_types; k++) {
        type ^= handled_types.At(k);
        ASSERT(!type.IsNull());
        // Uninstantiated types are not added to ExceptionHandlers data.
        ASSERT(type.IsInstantiated());
        if (type.IsDynamicType()) {
          return true;
        }
        if (exc_obj.IsInstanceOf(type, Object::null_type_arguments(),
                                 Object::null_type_arguments())) {
          return true;
        }
      }
    }
    try_index = handlers.OuterTryIndex(try_index);
  }
  return false;
}

intptr_t ActivationFrame::GetAwaitJumpVariable() {
  GetVarDescriptors();
  intptr_t var_ctxt_level = -1;
  intptr_t ctxt_slot = -1;
  intptr_t var_desc_len = var_descriptors_.Length();
  intptr_t await_jump_var = -1;
  for (intptr_t i = 0; i < var_desc_len; i++) {
    LocalVarDescriptorsLayout::VarInfo var_info;
    var_descriptors_.GetInfo(i, &var_info);
    const int8_t kind = var_info.kind();
    if (var_descriptors_.GetName(i) == Symbols::AwaitJumpVar().raw()) {
      ASSERT(kind == LocalVarDescriptorsLayout::kContextVar);
      ASSERT(!ctx_.IsNull());
      var_ctxt_level = var_info.scope_id;
      ctxt_slot = var_info.index();
      break;
    }
  }
  if (var_ctxt_level >= 0) {
    Object& await_jump_index = Object::Handle(ctx_.At(ctxt_slot));
    ASSERT(await_jump_index.IsSmi());
    await_jump_var = Smi::Cast(await_jump_index).Value();
  }
  return await_jump_var;
}

void ActivationFrame::ExtractTokenPositionFromAsyncClosure() {
  // Attempt to determine the token pos and try index from the async closure.
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();

  ASSERT(function_.IsAsyncGenClosure() || function_.IsAsyncClosure());
  // This should only be called on frames that aren't active on the stack.
  ASSERT(fp() == 0);

  const intptr_t await_jump_var = GetAwaitJumpVariable();
  if (await_jump_var < 0) {
    return;
  }

  const auto& pc_descriptors =
      PcDescriptors::Handle(zone, code().pc_descriptors());
  ASSERT(!pc_descriptors.IsNull());
  PcDescriptors::Iterator it(pc_descriptors, PcDescriptorsLayout::kOther);
  while (it.MoveNext()) {
    if (it.YieldIndex() == await_jump_var) {
      try_index_ = it.TryIndex();
      token_pos_ = it.TokenPos();
      token_pos_initialized_ = true;
      return;
    }
  }
}

bool ActivationFrame::IsAsyncMachinery() const {
  ASSERT(!function_.IsNull());
  Isolate* isolate = Isolate::Current();
  if (function_.raw() == isolate->object_store()->complete_on_async_return()) {
    // We are completing an async function's completer.
    return true;
  }
  if (function_.Owner() ==
      isolate->object_store()->async_star_stream_controller()) {
    // We are inside the async* stream controller code.
    return true;
  }
  return false;
}

// Get the saved current context of this activation.
const Context& ActivationFrame::GetSavedCurrentContext() {
  if (!ctx_.IsNull()) return ctx_;
  GetVarDescriptors();
  intptr_t var_desc_len = var_descriptors_.Length();
  Object& obj = Object::Handle();
  for (intptr_t i = 0; i < var_desc_len; i++) {
    LocalVarDescriptorsLayout::VarInfo var_info;
    var_descriptors_.GetInfo(i, &var_info);
    const int8_t kind = var_info.kind();
    if (kind == LocalVarDescriptorsLayout::kSavedCurrentContext) {
      if (FLAG_trace_debugger_stacktrace) {
        OS::PrintErr("\tFound saved current ctx at index %d\n",
                     var_info.index());
      }
      const auto variable_index = VariableIndex(var_info.index());
      obj = GetStackVar(variable_index);
      if (obj.IsClosure()) {
        ASSERT(function().name() == Symbols::Call().raw());
        ASSERT(function().IsInvokeFieldDispatcher());
        // Closure.call frames.
        ctx_ = Closure::Cast(obj).context();
      } else if (obj.IsContext()) {
        ctx_ = Context::Cast(obj).raw();
      } else {
        ASSERT(obj.IsNull() || obj.raw() == Symbols::OptimizedOut().raw());
        ctx_ = Context::null();
      }
      return ctx_;
    }
  }
  return ctx_;
}

ObjectPtr ActivationFrame::GetAsyncOperation() {
  if (function().name() == Symbols::AsyncOperation().raw()) {
    return GetParameter(0);
  }
  return Object::null();
}

ActivationFrame* DebuggerStackTrace::GetHandlerFrame(
    const Instance& exc_obj) const {
  for (intptr_t frame_index = 0; frame_index < Length(); frame_index++) {
    ActivationFrame* frame = FrameAt(frame_index);
    if (FLAG_trace_debugger_stacktrace) {
      OS::PrintErr("GetHandlerFrame: #%04" Pd " %s", frame_index,
                   frame->ToCString());
    }
    if (frame->HandlesException(exc_obj)) {
      return frame;
    }
  }
  return NULL;
}

void ActivationFrame::GetDescIndices() {
  if (vars_initialized_) {
    return;
  }
  GetVarDescriptors();

  TokenPosition activation_token_pos = TokenPos();
  if (!activation_token_pos.IsDebugPause() || !live_frame_) {
    // We don't have a token position for this frame, so can't determine
    // which variables are visible.
    vars_initialized_ = true;
    return;
  }

  GrowableArray<String*> var_names(8);
  intptr_t var_desc_len = var_descriptors_.Length();
  for (intptr_t cur_idx = 0; cur_idx < var_desc_len; cur_idx++) {
    ASSERT(var_names.length() == desc_indices_.length());
    LocalVarDescriptorsLayout::VarInfo var_info;
    var_descriptors_.GetInfo(cur_idx, &var_info);
    const int8_t kind = var_info.kind();
    if ((kind != LocalVarDescriptorsLayout::kStackVar) &&
        (kind != LocalVarDescriptorsLayout::kContextVar)) {
      continue;
    }
    if (!activation_token_pos.IsWithin(var_info.begin_pos, var_info.end_pos)) {
      continue;
    }
    if ((kind == LocalVarDescriptorsLayout::kContextVar) &&
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
    for (intptr_t i = 0; i < indices_len; i++) {
      if (var_name.Equals(*var_names[i])) {
        // Found two local variables with the same name. Now determine
        // which one is shadowed.
        name_match_found = true;
        LocalVarDescriptorsLayout::VarInfo i_var_info;
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
  vars_initialized_ = true;
}

intptr_t ActivationFrame::NumLocalVariables() {
  GetDescIndices();
  return desc_indices_.length();
}

DART_FORCE_INLINE static ObjectPtr GetVariableValue(uword addr) {
  return *reinterpret_cast<ObjectPtr*>(addr);
}

// Caution: GetParameter only works for fixed parameters.
ObjectPtr ActivationFrame::GetParameter(intptr_t index) {
  intptr_t num_parameters = function().num_fixed_parameters();
  ASSERT(0 <= index && index < num_parameters);

  if (function().NumOptionalParameters() > 0) {
    // If the function has optional parameters, the first positional parameter
    // can be in a number of places in the caller's frame depending on how many
    // were actually supplied at the call site, but they are copied to a fixed
    // place in the callee's frame.

    return GetVariableValue(LocalVarAddress(
        fp(), runtime_frame_layout.FrameSlotForVariableIndex(-index)));
  } else {
    intptr_t reverse_index = num_parameters - index;
    return GetVariableValue(ParamAddress(fp(), reverse_index));
  }
}

ObjectPtr ActivationFrame::GetClosure() {
  ASSERT(function().IsClosureFunction());
  return GetParameter(0);
}

ObjectPtr ActivationFrame::GetStackVar(VariableIndex variable_index) {
  const intptr_t slot_index =
      runtime_frame_layout.FrameSlotForVariableIndex(variable_index.value());
  if (deopt_frame_.IsNull()) {
    return GetVariableValue(LocalVarAddress(fp(), slot_index));
  } else {
    return deopt_frame_.At(LocalVarIndex(deopt_frame_offset_, slot_index));
  }
}

bool ActivationFrame::IsRewindable() const {
  if (deopt_frame_.IsNull()) {
    return true;
  }
  // TODO(turnidge): This is conservative.  It looks at all values in
  // the deopt_frame_ even though some of them may correspond to other
  // inlined frames.
  Object& obj = Object::Handle();
  for (int i = 0; i < deopt_frame_.Length(); i++) {
    obj = deopt_frame_.At(i);
    if (obj.raw() == Symbols::OptimizedOut().raw()) {
      return false;
    }
  }
  return true;
}

void ActivationFrame::PrintContextMismatchError(intptr_t ctx_slot,
                                                intptr_t frame_ctx_level,
                                                intptr_t var_ctx_level) {
  OS::PrintErr(
      "-------------------------\n"
      "Encountered context mismatch\n"
      "\tctx_slot: %" Pd
      "\n"
      "\tframe_ctx_level: %" Pd
      "\n"
      "\tvar_ctx_level: %" Pd "\n\n",
      ctx_slot, frame_ctx_level, var_ctx_level);

  OS::PrintErr(
      "-------------------------\n"
      "Current frame:\n%s\n",
      this->ToCString());

  OS::PrintErr(
      "-------------------------\n"
      "Context contents:\n");
  const Context& ctx = GetSavedCurrentContext();
  ctx.Dump(8);

  OS::PrintErr(
      "-------------------------\n"
      "Debugger stack trace...\n\n");
  DebuggerStackTrace* stack = Isolate::Current()->debugger()->StackTrace();
  intptr_t num_frames = stack->Length();
  for (intptr_t i = 0; i < num_frames; i++) {
    ActivationFrame* frame = stack->FrameAt(i);
    OS::PrintErr("#%04" Pd " %s", i, frame->ToCString());
  }

  OS::PrintErr(
      "-------------------------\n"
      "All frames...\n\n");
  StackFrameIterator iterator(ValidationPolicy::kDontValidateFrames,
                              Thread::Current(),
                              StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* frame = iterator.NextFrame();
  intptr_t num = 0;
  while ((frame != NULL)) {
    OS::PrintErr("#%04" Pd " %s\n", num++, frame->ToCString());
    frame = iterator.NextFrame();
  }
}

void ActivationFrame::VariableAt(intptr_t i,
                                 String* name,
                                 TokenPosition* declaration_token_pos,
                                 TokenPosition* visible_start_token_pos,
                                 TokenPosition* visible_end_token_pos,
                                 Object* value) {
  GetDescIndices();
  ASSERT(i < desc_indices_.length());
  intptr_t desc_index = desc_indices_[i];
  ASSERT(name != NULL);

  *name = var_descriptors_.GetName(desc_index);

  LocalVarDescriptorsLayout::VarInfo var_info;
  var_descriptors_.GetInfo(desc_index, &var_info);
  ASSERT(declaration_token_pos != NULL);
  *declaration_token_pos = var_info.declaration_pos;
  ASSERT(visible_start_token_pos != NULL);
  *visible_start_token_pos = var_info.begin_pos;
  ASSERT(visible_end_token_pos != NULL);
  *visible_end_token_pos = var_info.end_pos;
  ASSERT(value != NULL);
  const int8_t kind = var_info.kind();
  const auto variable_index = VariableIndex(var_info.index());
  if (kind == LocalVarDescriptorsLayout::kStackVar) {
    *value = GetStackVar(variable_index);
  } else {
    ASSERT(kind == LocalVarDescriptorsLayout::kContextVar);
    *value = GetContextVar(var_info.scope_id, variable_index.value());
  }
}

ObjectPtr ActivationFrame::GetContextVar(intptr_t var_ctx_level,
                                         intptr_t ctx_slot) {
  // The context level at the PC/token index of this activation frame.
  intptr_t frame_ctx_level = ContextLevel();

  return GetRelativeContextVar(var_ctx_level, ctx_slot, frame_ctx_level);
}

ObjectPtr ActivationFrame::GetRelativeContextVar(intptr_t var_ctx_level,
                                                 intptr_t ctx_slot,
                                                 intptr_t frame_ctx_level) {
  const Context& ctx = GetSavedCurrentContext();

  // It's possible that ctx was optimized out as no locals were captured by the
  // context. See issue #38182.
  if (ctx.IsNull()) {
    return Symbols::OptimizedOut().raw();
  }

  intptr_t level_diff = frame_ctx_level - var_ctx_level;
  if (level_diff == 0) {
    if ((ctx_slot < 0) || (ctx_slot >= ctx.num_variables())) {
      PrintContextMismatchError(ctx_slot, frame_ctx_level, var_ctx_level);
    }
    ASSERT((ctx_slot >= 0) && (ctx_slot < ctx.num_variables()));
    return ctx.At(ctx_slot);
  } else if (level_diff > 0) {
    Context& var_ctx = Context::Handle(ctx.raw());
    while (level_diff > 0 && !var_ctx.IsNull()) {
      level_diff--;
      var_ctx = var_ctx.parent();
    }
    if (var_ctx.IsNull() || (ctx_slot < 0) ||
        (ctx_slot >= var_ctx.num_variables())) {
      PrintContextMismatchError(ctx_slot, frame_ctx_level, var_ctx_level);
    }
    ASSERT(!var_ctx.IsNull());
    ASSERT((ctx_slot >= 0) && (ctx_slot < var_ctx.num_variables()));
    return var_ctx.At(ctx_slot);
  } else {
    PrintContextMismatchError(ctx_slot, frame_ctx_level, var_ctx_level);
    return Object::null();
  }
}

ArrayPtr ActivationFrame::GetLocalVariables() {
  GetDescIndices();
  intptr_t num_variables = desc_indices_.length();
  String& var_name = String::Handle();
  Object& value = Instance::Handle();
  const Array& list = Array::Handle(Array::New(2 * num_variables));
  for (intptr_t i = 0; i < num_variables; i++) {
    TokenPosition ignore = TokenPosition::kNoSource;
    VariableAt(i, &var_name, &ignore, &ignore, &ignore, &value);
    list.SetAt(2 * i, var_name);
    list.SetAt((2 * i) + 1, value);
  }
  return list.raw();
}

ObjectPtr ActivationFrame::GetReceiver() {
  GetDescIndices();
  intptr_t num_variables = desc_indices_.length();
  String& var_name = String::Handle();
  Instance& value = Instance::Handle();
  for (intptr_t i = 0; i < num_variables; i++) {
    TokenPosition ignore = TokenPosition::kNoSource;
    VariableAt(i, &var_name, &ignore, &ignore, &ignore, &value);
    if (var_name.Equals(Symbols::This())) {
      return value.raw();
    }
  }
  return Symbols::OptimizedOut().raw();
}

static bool IsSyntheticVariableName(const String& var_name) {
  return (var_name.Length() >= 1) && (var_name.CharAt(0) == ':');
}

static bool IsPrivateVariableName(const String& var_name) {
  return (var_name.Length() >= 1) && (var_name.CharAt(0) == '_');
}

ObjectPtr ActivationFrame::EvaluateCompiledExpression(
    const ExternalTypedData& kernel_buffer,
    const Array& type_definitions,
    const Array& arguments,
    const TypeArguments& type_arguments) {
  if (function().is_static()) {
    const Class& cls = Class::Handle(function().Owner());
    return cls.EvaluateCompiledExpression(kernel_buffer, type_definitions,
                                          arguments, type_arguments);
  } else {
    const Object& receiver = Object::Handle(GetReceiver());
    const Class& method_cls = Class::Handle(function().origin());
    ASSERT(receiver.IsInstance() || receiver.IsNull());
    if (!(receiver.IsInstance() || receiver.IsNull())) {
      return Object::null();
    }
    const Instance& inst = Instance::Cast(receiver);
    return inst.EvaluateCompiledExpression(
        method_cls, kernel_buffer, type_definitions, arguments, type_arguments);
  }
}

TypeArgumentsPtr ActivationFrame::BuildParameters(
    const GrowableObjectArray& param_names,
    const GrowableObjectArray& param_values,
    const GrowableObjectArray& type_params_names) {
  GetDescIndices();
  bool type_arguments_available = false;
  String& name = String::Handle();
  String& existing_name = String::Handle();
  Object& value = Instance::Handle();
  TypeArguments& type_arguments = TypeArguments::Handle();
  intptr_t num_variables = desc_indices_.length();
  for (intptr_t i = 0; i < num_variables; i++) {
    TokenPosition ignore = TokenPosition::kNoSource;
    VariableAt(i, &name, &ignore, &ignore, &ignore, &value);
    if (name.Equals(Symbols::FunctionTypeArgumentsVar())) {
      type_arguments_available = true;
      type_arguments ^= value.raw();
    } else if (!name.Equals(Symbols::This()) &&
               !IsSyntheticVariableName(name)) {
      if (IsPrivateVariableName(name)) {
        name = Symbols::New(Thread::Current(), String::ScrubName(name));
      }
      bool conflict = false;
      for (intptr_t j = 0; j < param_names.Length(); j++) {
        existing_name ^= param_names.At(j);
        if (name.Equals(existing_name)) {
          conflict = true;
          break;
        }
      }
      // If local has the same name as a binding in the incoming scope, prefer
      // the one from the incoming scope, since it is logically a child scope
      // of the activation's current scope.
      if (!conflict) {
        param_names.Add(name);
        param_values.Add(value);
      }
    }
  }

  if ((function().IsGeneric() || function().HasGenericParent()) &&
      type_arguments_available) {
    intptr_t num_vars =
        function().NumTypeParameters() + function().NumParentTypeParameters();
    type_params_names.Grow(num_vars);
    type_params_names.SetLength(num_vars);
    TypeArguments& type_params = TypeArguments::Handle();
    TypeParameter& type_param = TypeParameter::Handle();
    Function& current = Function::Handle(function().raw());
    intptr_t mapping_offset = num_vars;
    for (intptr_t i = 0; !current.IsNull(); i += current.NumTypeParameters(),
                  current = current.parent_function()) {
      type_params = current.type_parameters();
      intptr_t size = current.NumTypeParameters();
      ASSERT(mapping_offset >= size);
      mapping_offset -= size;
      for (intptr_t j = 0; j < size; ++j) {
        type_param = TypeParameter::RawCast(type_params.TypeAt(j));
        name = type_param.name();
        // Write the names in backwards in terms of chain of functions.
        // But keep the order of names within the same function. so they
        // match up with the order of the types in 'type_arguments'.
        // Index:0 1 2 3 ...
        //       |Names in Grandparent| |Names in Parent| ..|Names in Child|
        type_params_names.SetAt(mapping_offset + j, name);
      }
    }
    if (!type_arguments.IsNull()) {
      if (type_arguments.Length() == 0) {
        for (intptr_t i = 0; i < num_vars; ++i) {
          type_arguments.SetTypeAt(i, Object::dynamic_type());
        }
      }
      ASSERT(type_arguments.Length() == num_vars);
    }
  }

  return type_arguments.raw();
}

const char* ActivationFrame::ToCString() {
  if (function().IsNull()) {
    return Thread::Current()->zone()->PrintToString("[ Frame kind: %s]\n",
                                                    KindToCString(kind_));
  }
  const String& url = String::Handle(SourceUrl());
  intptr_t line = LineNumber();
  const char* func_name = function().ToFullyQualifiedCString();
  if (live_frame_) {
    return Thread::Current()->zone()->PrintToString(
        "[ Frame pc(0x%" Px " code offset:0x%" Px ") fp(0x%" Px ") sp(0x%" Px
        ")\n"
        "\tfunction = %s\n"
        "\turl = %s\n"
        "\tline = %" Pd
        "\n"
        "\tcontext = %s\n"
        "\tcontext level = %" Pd " ]\n",
        pc(), pc() - code().PayloadStart(), fp(), sp(), func_name,
        url.ToCString(), line, ctx_.ToCString(), ContextLevel());
  } else {
    return Thread::Current()->zone()->PrintToString(
        "[ Frame code function = %s\n"
        "\turl = %s\n"
        "\tline = %" Pd
        "\n"
        "\tcontext = %s]\n",
        func_name, url.ToCString(), line, ctx_.ToCString());
  }
}

void ActivationFrame::PrintToJSONObject(JSONObject* jsobj) {
  if (kind_ == kRegular || kind_ == kAsyncActivation) {
    PrintToJSONObjectRegular(jsobj);
  } else if (kind_ == kAsyncCausal) {
    PrintToJSONObjectAsyncCausal(jsobj);
  } else if (kind_ == kAsyncSuspensionMarker) {
    PrintToJSONObjectAsyncSuspensionMarker(jsobj);
  } else {
    UNIMPLEMENTED();
  }
}

void ActivationFrame::PrintToJSONObjectRegular(JSONObject* jsobj) {
  const Script& script = Script::Handle(SourceScript());
  jsobj->AddProperty("type", "Frame");
  jsobj->AddProperty("kind", KindToCString(kind_));
  const TokenPosition& pos = TokenPos();
  jsobj->AddLocation(script, pos);
  jsobj->AddProperty("function", function());
  jsobj->AddProperty("code", code());
  {
    JSONArray jsvars(jsobj, "vars");
    const int num_vars = NumLocalVariables();
    for (intptr_t v = 0; v < num_vars; v++) {
      String& var_name = String::Handle();
      Instance& var_value = Instance::Handle();
      TokenPosition declaration_token_pos = TokenPosition::kNoSource;
      TokenPosition visible_start_token_pos = TokenPosition::kNoSource;
      TokenPosition visible_end_token_pos = TokenPosition::kNoSource;
      VariableAt(v, &var_name, &declaration_token_pos, &visible_start_token_pos,
                 &visible_end_token_pos, &var_value);
      if (!IsSyntheticVariableName(var_name)) {
        JSONObject jsvar(&jsvars);
        jsvar.AddProperty("type", "BoundVariable");
        const char* scrubbed_var_name = String::ScrubName(var_name);
        jsvar.AddProperty("name", scrubbed_var_name);
        jsvar.AddProperty("value", var_value);
        // Where was the variable declared?
        jsvar.AddProperty("declarationTokenPos", declaration_token_pos);
        // When the variable becomes visible to the scope.
        jsvar.AddProperty("scopeStartTokenPos", visible_start_token_pos);
        // When the variable stops being visible to the scope.
        jsvar.AddProperty("scopeEndTokenPos", visible_end_token_pos);
      }
    }
  }
}

void ActivationFrame::PrintToJSONObjectAsyncCausal(JSONObject* jsobj) {
  jsobj->AddProperty("type", "Frame");
  jsobj->AddProperty("kind", KindToCString(kind_));
  const Script& script = Script::Handle(SourceScript());
  const TokenPosition& pos = TokenPos();
  jsobj->AddLocation(script, pos);
  jsobj->AddProperty("function", function());
  jsobj->AddProperty("code", code());
}

void ActivationFrame::PrintToJSONObjectAsyncSuspensionMarker(
    JSONObject* jsobj) {
  jsobj->AddProperty("type", "Frame");
  jsobj->AddProperty("kind", KindToCString(kind_));
  jsobj->AddProperty("marker", "AsynchronousSuspension");
}

static bool IsFunctionVisible(const Function& function) {
  return FLAG_show_invisible_frames || function.is_visible();
}

void DebuggerStackTrace::AddActivation(ActivationFrame* frame) {
  if (IsFunctionVisible(frame->function())) {
    trace_.Add(frame);
  }
}

void DebuggerStackTrace::AddMarker(ActivationFrame::Kind marker) {
  ASSERT(marker == ActivationFrame::kAsyncSuspensionMarker);
  trace_.Add(new ActivationFrame(marker));
}

void DebuggerStackTrace::AddAsyncCausalFrame(uword pc, const Code& code) {
  trace_.Add(new ActivationFrame(pc, 0, 0, code, Array::Handle(), 0,
                                 ActivationFrame::kAsyncCausal));
}

const uint8_t kSafepointKind = PcDescriptorsLayout::kIcCall |
                               PcDescriptorsLayout::kUnoptStaticCall |
                               PcDescriptorsLayout::kRuntimeCall;

CodeBreakpoint::CodeBreakpoint(const Code& code,
                               TokenPosition token_pos,
                               uword pc,
                               PcDescriptorsLayout::Kind kind)
    : code_(code.raw()),
      token_pos_(token_pos),
      pc_(pc),
      line_number_(-1),
      is_enabled_(false),
      bpt_location_(NULL),
      next_(NULL),
      breakpoint_kind_(kind),
      saved_value_(Code::null()) {
  ASSERT(!code.IsNull());
  ASSERT(token_pos_.IsReal());
  ASSERT(pc_ != 0);
  ASSERT((breakpoint_kind_ & kSafepointKind) != 0);
}

CodeBreakpoint::~CodeBreakpoint() {
  // Make sure we don't leave patched code behind.
  ASSERT(!IsEnabled());
// Poison the data so we catch use after free errors.
#ifdef DEBUG
  code_ = Code::null();
  pc_ = 0ul;
  bpt_location_ = NULL;
  next_ = NULL;
  breakpoint_kind_ = PcDescriptorsLayout::kOther;
#endif
}

FunctionPtr CodeBreakpoint::function() const {
  return Code::Handle(code_).function();
}

ScriptPtr CodeBreakpoint::SourceCode() {
  const Function& func = Function::Handle(this->function());
  return func.script();
}

StringPtr CodeBreakpoint::SourceUrl() {
  const Script& script = Script::Handle(SourceCode());
  return script.url();
}

intptr_t CodeBreakpoint::LineNumber() {
  // Compute line number lazily since it causes scanning of the script.
  if (line_number_ < 0) {
    const Script& script = Script::Handle(SourceCode());
    script.GetTokenLocation(token_pos_, &line_number_);
  }
  return line_number_;
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

Debugger::Debugger(Isolate* isolate)
    : isolate_(isolate),
      next_id_(1),
      latent_locations_(NULL),
      breakpoint_locations_(NULL),
      code_breakpoints_(NULL),
      resume_action_(kContinue),
      resume_frame_index_(-1),
      post_deopt_frame_index_(-1),
      ignore_breakpoints_(false),
      pause_event_(NULL),
      stack_trace_(NULL),
      async_causal_stack_trace_(NULL),
      awaiter_stack_trace_(NULL),
      stepping_fp_(0),
      last_stepping_fp_(0),
      last_stepping_pos_(TokenPosition::kNoSource),
      async_stepping_fp_(0),
      top_frame_awaiter_(Object::null()),
      skip_next_step_(false),
      needs_breakpoint_cleanup_(false),
      synthetic_async_breakpoint_(NULL),
      exc_pause_info_(kNoPauseOnExceptions) {}

Debugger::~Debugger() {
  ASSERT(!IsPaused());
  ASSERT(latent_locations_ == NULL);
  ASSERT(breakpoint_locations_ == NULL);
  ASSERT(code_breakpoints_ == NULL);
  ASSERT(stack_trace_ == NULL);
  ASSERT(async_causal_stack_trace_ == NULL);
  ASSERT(synthetic_async_breakpoint_ == NULL);
}

void Debugger::Shutdown() {
  // TODO(johnmccutchan): Do not create a debugger for isolates that don't need
  // them. Then, assert here that isolate_ is not one of those isolates.
  if (Isolate::IsSystemIsolate(isolate_)) {
    return;
  }
  while (breakpoint_locations_ != NULL) {
    BreakpointLocation* loc = breakpoint_locations_;
    breakpoint_locations_ = breakpoint_locations_->next();
    delete loc;
  }
  while (latent_locations_ != NULL) {
    BreakpointLocation* loc = latent_locations_;
    latent_locations_ = latent_locations_->next();
    delete loc;
  }
  while (code_breakpoints_ != NULL) {
    CodeBreakpoint* cbpt = code_breakpoints_;
    code_breakpoints_ = code_breakpoints_->next();
    cbpt->Disable();
    delete cbpt;
  }
  if (NeedsIsolateEvents()) {
    ServiceEvent event(isolate_, ServiceEvent::kIsolateExit);
    InvokeEventHandler(&event);
  }
}

bool Debugger::SetupStepOverAsyncSuspension(const char** error) {
  ActivationFrame* top_frame = TopDartFrame();
  if (!IsAtAsyncJump(top_frame)) {
    // Not at an async operation.
    if (error != nullptr) {
      *error = "Isolate must be paused at an async suspension point";
    }
    return false;
  }
  Object& closure = Object::Handle(top_frame->GetAsyncOperation());
  ASSERT(!closure.IsNull());
  ASSERT(closure.IsInstance());
  ASSERT(Instance::Cast(closure).IsClosure());
  Breakpoint* bpt = SetBreakpointAtActivation(Instance::Cast(closure), true);
  if (bpt == NULL) {
    // Unable to set the breakpoint.
    if (error != nullptr) {
      *error = "Unable to set breakpoint at async suspension point";
    }
    return false;
  }
  return true;
}

bool Debugger::SetResumeAction(ResumeAction action,
                               intptr_t frame_index,
                               const char** error) {
  if (error != nullptr) {
    *error = NULL;
  }
  resume_frame_index_ = -1;
  switch (action) {
    case kStepInto:
    case kStepOver:
    case kStepOut:
    case kContinue:
      resume_action_ = action;
      return true;
    case kStepRewind:
      if (!CanRewindFrame(frame_index, error)) {
        return false;
      }
      resume_action_ = kStepRewind;
      resume_frame_index_ = frame_index;
      return true;
    case kStepOverAsyncSuspension:
      return SetupStepOverAsyncSuspension(error);
    default:
      UNREACHABLE();
      return false;
  }
}

// Deoptimize all functions in the isolate.
// TODO(hausner): Actually we only need to deoptimize those functions
// that inline the function that contains the newly created breakpoint.
// We currently don't have this info so we deoptimize all functions.
void Debugger::DeoptimizeWorld() {
#if defined(DART_PRECOMPILED_RUNTIME)
  UNREACHABLE();
#else
  BackgroundCompiler::Stop(isolate_);
  if (FLAG_trace_deoptimization) {
    THR_Print("Deopt for debugger\n");
  }
  isolate_->set_has_attempted_stepping(true);

  DeoptimizeFunctionsOnStack();

  // Iterate over all classes, deoptimize functions.
  // TODO(hausner): Could possibly be combined with RemoveOptimizedCode()
  const ClassTable& class_table = *isolate_->class_table();
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  CallSiteResetter resetter(zone);
  Class& cls = Class::Handle(zone);
  Array& functions = Array::Handle(zone);
  GrowableObjectArray& closures = GrowableObjectArray::Handle(zone);
  Function& function = Function::Handle(zone);
  Code& code = Code::Handle(zone);

  const intptr_t num_classes = class_table.NumCids();
  const intptr_t num_tlc_classes = class_table.NumTopLevelCids();
  // TODO(dartbug.com/36097): Need to stop other mutators running in same IG
  // before deoptimizing the world.
  SafepointWriteRwLocker ml(thread, thread->isolate_group()->program_lock());
  for (intptr_t i = 1; i < num_classes + num_tlc_classes; i++) {
    const classid_t cid =
        i < num_classes ? i : ClassTable::CidFromTopLevelIndex(i - num_classes);
    if (class_table.HasValidClassAt(cid)) {
      cls = class_table.At(cid);

      // Disable optimized functions.
      functions = cls.functions();
      if (!functions.IsNull()) {
        intptr_t num_functions = functions.Length();
        for (intptr_t pos = 0; pos < num_functions; pos++) {
          function ^= functions.At(pos);
          ASSERT(!function.IsNull());
          // Force-optimized functions don't have unoptimized code and can't
          // deoptimize. Their optimized codes are still valid.
          if (function.ForceOptimize()) {
            ASSERT(!function.HasImplicitClosureFunction());
            continue;
          }
          if (function.HasOptimizedCode()) {
            function.SwitchToUnoptimizedCode();
          }
          code = function.unoptimized_code();
          if (!code.IsNull()) {
            resetter.ResetSwitchableCalls(code);
          }
          // Also disable any optimized implicit closure functions.
          if (function.HasImplicitClosureFunction()) {
            function = function.ImplicitClosureFunction();
            if (function.HasOptimizedCode()) {
              function.SwitchToUnoptimizedCode();
            }
            code = function.unoptimized_code();
            if (!code.IsNull()) {
              resetter.ResetSwitchableCalls(code);
            }
          }
        }
      }
    }
  }

  // Disable optimized closure functions.
  closures = isolate_->object_store()->closure_functions();
  const intptr_t num_closures = closures.Length();
  for (intptr_t pos = 0; pos < num_closures; pos++) {
    function ^= closures.At(pos);
    ASSERT(!function.IsNull());
    if (function.HasOptimizedCode()) {
      function.SwitchToUnoptimizedCode();
    }
    code = function.unoptimized_code();
    if (!code.IsNull()) {
      resetter.ResetSwitchableCalls(code);
    }
  }
#endif  // defined(DART_PRECOMPILED_RUNTIME)
}

void Debugger::NotifySingleStepping(bool value) const {
  isolate_->set_single_step(value);
}

ActivationFrame* Debugger::CollectDartFrame(Isolate* isolate,
                                            uword pc,
                                            StackFrame* frame,
                                            const Code& code,
                                            const Array& deopt_frame,
                                            intptr_t deopt_frame_offset,
                                            ActivationFrame::Kind kind) {
  ASSERT(code.ContainsInstructionAt(pc));
  ActivationFrame* activation =
      new ActivationFrame(pc, frame->fp(), frame->sp(), code, deopt_frame,
                          deopt_frame_offset, kind);
  if (FLAG_trace_debugger_stacktrace) {
    const Context& ctx = activation->GetSavedCurrentContext();
    OS::PrintErr("\tUsing saved context: %s\n", ctx.ToCString());
    OS::PrintErr("\tLine number: %" Pd "\n", activation->LineNumber());
  }
  return activation;
}

#if !defined(DART_PRECOMPILED_RUNTIME)
ArrayPtr Debugger::DeoptimizeToArray(Thread* thread,
                                     StackFrame* frame,
                                     const Code& code) {
  ASSERT(code.is_optimized() && !code.is_force_optimized());
  Isolate* isolate = thread->isolate();
  // Create the DeoptContext for this deoptimization.
  DeoptContext* deopt_context =
      new DeoptContext(frame, code, DeoptContext::kDestIsAllocated, NULL, NULL,
                       true, false /* deoptimizing_code */);
  isolate->set_deopt_context(deopt_context);

  deopt_context->FillDestFrame();
  deopt_context->MaterializeDeferredObjects();
  const Array& dest_frame =
      Array::Handle(thread->zone(), deopt_context->DestFrameAsArray());

  isolate->set_deopt_context(NULL);
  delete deopt_context;

  return dest_frame.raw();
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

DebuggerStackTrace* Debugger::CollectStackTrace() {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();
  DebuggerStackTrace* stack_trace = new DebuggerStackTrace(8);
  StackFrameIterator iterator(ValidationPolicy::kDontValidateFrames,
                              Thread::Current(),
                              StackFrameIterator::kNoCrossThreadIteration);
  Code& code = Code::Handle(zone);
  Code& inlined_code = Code::Handle(zone);
  Array& deopt_frame = Array::Handle(zone);

  for (StackFrame* frame = iterator.NextFrame(); frame != NULL;
       frame = iterator.NextFrame()) {
    ASSERT(frame->IsValid());
    if (FLAG_trace_debugger_stacktrace) {
      OS::PrintErr("CollectStackTrace: visiting frame:\n\t%s\n",
                   frame->ToCString());
    }
    if (frame->IsDartFrame()) {
      code = frame->LookupDartCode();
      AppendCodeFrames(thread, isolate, zone, stack_trace, frame, &code,
                       &inlined_code, &deopt_frame);
    }
  }
  return stack_trace;
}

void Debugger::AppendCodeFrames(Thread* thread,
                                Isolate* isolate,
                                Zone* zone,
                                DebuggerStackTrace* stack_trace,
                                StackFrame* frame,
                                Code* code,
                                Code* inlined_code,
                                Array* deopt_frame) {
#if !defined(DART_PRECOMPILED_RUNTIME)
  if (code->is_optimized()) {
    if (code->is_force_optimized()) {
      if (FLAG_trace_debugger_stacktrace) {
        const Function& function = Function::Handle(zone, code->function());
        ASSERT(!function.IsNull());
        OS::PrintErr(
            "CollectStackTrace: skipping force-optimized function: %s\n",
            function.ToFullyQualifiedCString());
      }
      return;  // Skip frame of force-optimized (and non-debuggable) function.
    }
    // TODO(rmacnak): Use CodeSourceMap
    *deopt_frame = DeoptimizeToArray(thread, frame, *code);
    for (InlinedFunctionsIterator it(*code, frame->pc()); !it.Done();
         it.Advance()) {
      *inlined_code = it.code();
      if (FLAG_trace_debugger_stacktrace) {
        const Function& function = Function::Handle(zone, it.function());
        ASSERT(!function.IsNull());
        OS::PrintErr("CollectStackTrace: visiting inlined function: %s\n",
                     function.ToFullyQualifiedCString());
      }
      intptr_t deopt_frame_offset = it.GetDeoptFpOffset();
      stack_trace->AddActivation(CollectDartFrame(isolate, it.pc(), frame,
                                                  *inlined_code, *deopt_frame,
                                                  deopt_frame_offset));
    }
    return;
  }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
  stack_trace->AddActivation(CollectDartFrame(isolate, frame->pc(), frame,
                                              *code, Object::null_array(), 0));
}

DebuggerStackTrace* Debugger::CollectAsyncCausalStackTrace() {
  if (FLAG_lazy_async_stacks) {
    return CollectAsyncLazyStackTrace();
  }
  if (!FLAG_causal_async_stacks) {
    return nullptr;
  }
  UNREACHABLE();  //  FLAG_causal_async_stacks is deprecated.
}

DebuggerStackTrace* Debugger::CollectAsyncLazyStackTrace() {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();

  Code& code = Code::Handle(zone);
  Code& inlined_code = Code::Handle(zone);
  Array& deopt_frame = Array::Handle(zone);
  Smi& offset = Smi::Handle(zone);
  Function& function = Function::Handle(zone);

  constexpr intptr_t kDefaultStackAllocation = 8;
  auto stack_trace = new DebuggerStackTrace(kDefaultStackAllocation);

  const auto& code_array = GrowableObjectArray::ZoneHandle(
      zone, GrowableObjectArray::New(kDefaultStackAllocation));
  const auto& pc_offset_array = GrowableObjectArray::ZoneHandle(
      zone, GrowableObjectArray::New(kDefaultStackAllocation));
  bool has_async = false;

  std::function<void(StackFrame*)> on_sync_frame = [&](StackFrame* frame) {
    code = frame->LookupDartCode();
    AppendCodeFrames(thread, isolate, zone, stack_trace, frame, &code,
                     &inlined_code, &deopt_frame);
  };

  StackTraceUtils::CollectFramesLazy(thread, code_array, pc_offset_array,
                                     /*skip_frames=*/0, &on_sync_frame,
                                     &has_async);

  // If the entire stack is sync, return no trace.
  if (!has_async) {
    return nullptr;
  }

  const intptr_t length = code_array.Length();
  bool async_frames = false;
  for (intptr_t i = 0; i < length; ++i) {
    code ^= code_array.At(i);

    if (code.raw() == StubCode::AsynchronousGapMarker().raw()) {
      stack_trace->AddMarker(ActivationFrame::kAsyncSuspensionMarker);
      // Once we reach a gap, the rest is async.
      async_frames = true;
      continue;
    }

    // Skip the sync frames since they've been added (and un-inlined) above.
    if (!async_frames) {
      continue;
    }

    if (!code.IsFunctionCode()) {
      continue;
    }

    // Skip invisible function frames.
    function ^= code.function();
    if (!function.is_visible()) {
      continue;
    }

    offset ^= pc_offset_array.At(i);
    const uword absolute_pc = code.PayloadStart() + offset.Value();
    stack_trace->AddAsyncCausalFrame(absolute_pc, code);
  }

  return stack_trace;
}

DebuggerStackTrace* Debugger::CollectAwaiterReturnStackTrace() {
#if defined(DART_PRECOMPILED_RUNTIME)
  // Causal async stacks are not supported in the AOT runtime.
  ASSERT(!FLAG_async_debugger);
  return nullptr;
#else
  if (!FLAG_async_debugger) {
    return nullptr;
  }

  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();
  DebuggerStackTrace* stack_trace = new DebuggerStackTrace(8);

  StackFrameIterator iterator(ValidationPolicy::kDontValidateFrames,
                              Thread::Current(),
                              StackFrameIterator::kNoCrossThreadIteration);

  Code& code = Code::Handle(zone);
  Function& function = Function::Handle(zone);
  Code& inlined_code = Code::Handle(zone);
  Closure& async_activation = Closure::Handle(zone);
  Object& next_async_activation = Object::Handle(zone);
  Array& deopt_frame = Array::Handle(zone);
  bool stack_has_async_function = false;
  Closure& closure = Closure::Handle();

  CallerClosureFinder caller_closure_finder(zone);

  for (StackFrame* frame = iterator.NextFrame(); frame != nullptr;
       frame = iterator.NextFrame()) {
    ASSERT(frame->IsValid());
    if (FLAG_trace_debugger_stacktrace) {
      OS::PrintErr("CollectAwaiterReturnStackTrace: visiting frame:\n\t%s\n",
                   frame->ToCString());
    }

    if (!frame->IsDartFrame()) {
      continue;
    }

    code = frame->LookupDartCode();

    // Simple frame. Just add the one.
    if (!code.is_optimized()) {
      function = code.function();
      if (function.IsAsyncClosure() || function.IsAsyncGenClosure()) {
        ActivationFrame* activation = CollectDartFrame(
            isolate, frame->pc(), frame, code, Object::null_array(), 0,
            ActivationFrame::kAsyncActivation);
        ASSERT(activation != nullptr);
        stack_trace->AddActivation(activation);
        stack_has_async_function = true;
        // Grab the awaiter.
        async_activation ^= activation->GetAsyncAwaiter(&caller_closure_finder);
        // Bail if we've reach the end of sync execution stack.
        ObjectPtr* last_caller_obj =
            reinterpret_cast<ObjectPtr*>(frame->GetCallerSp());
        closure =
            StackTraceUtils::FindClosureInFrame(last_caller_obj, function);
        if (caller_closure_finder.IsRunningAsync(closure)) {
          break;
        }
      } else {
        stack_trace->AddActivation(CollectDartFrame(
            isolate, frame->pc(), frame, code, Object::null_array(), 0));
      }

      continue;
    }

    if (code.is_force_optimized()) {
      if (FLAG_trace_debugger_stacktrace) {
        function = code.function();
        ASSERT(!function.IsNull());
        OS::PrintErr(
            "CollectAwaiterReturnStackTrace: "
            "skipping force-optimized function: %s\n",
            function.ToFullyQualifiedCString());
      }
      // Skip frame of force-optimized (and non-debuggable) function.
      continue;
    }

    deopt_frame = DeoptimizeToArray(thread, frame, code);
    bool found_async_awaiter = false;
    bool abort_attempt_to_navigate_through_sync_async = false;
    for (InlinedFunctionsIterator it(code, frame->pc()); !it.Done();
         it.Advance()) {
      inlined_code = it.code();
      function = it.function();

      if (FLAG_trace_debugger_stacktrace) {
        ASSERT(!function.IsNull());
        OS::PrintErr(
            "CollectAwaiterReturnStackTrace: "
            "visiting inlined function: %s\n ",
            function.ToFullyQualifiedCString());
      }

      intptr_t deopt_frame_offset = it.GetDeoptFpOffset();
      if (function.IsAsyncClosure() || function.IsAsyncGenClosure()) {
        ActivationFrame* activation = CollectDartFrame(
            isolate, it.pc(), frame, inlined_code, deopt_frame,
            deopt_frame_offset, ActivationFrame::kAsyncActivation);
        ASSERT(activation != NULL);
        stack_trace->AddActivation(activation);
        stack_has_async_function = true;
        // Grab the awaiter.
        async_activation ^= activation->GetAsyncAwaiter(&caller_closure_finder);
        found_async_awaiter = true;
      } else {
        stack_trace->AddActivation(CollectDartFrame(isolate, it.pc(), frame,
                                                    inlined_code, deopt_frame,
                                                    deopt_frame_offset));
      }
    }

    // Break out of outer loop.
    if (found_async_awaiter || abort_attempt_to_navigate_through_sync_async) {
      break;
    }
  }

  // If the stack doesn't have any async functions on it, return nullptr.
  if (!stack_has_async_function) {
    return nullptr;
  }

  // Append the awaiter return call stack.
  while (!async_activation.IsNull() &&
         async_activation.context() != Object::null()) {
    ActivationFrame* activation = new (zone) ActivationFrame(async_activation);

    if (!(activation->function().IsAsyncClosure() ||
          activation->function().IsAsyncGenClosure())) {
      break;
    }

    activation->ExtractTokenPositionFromAsyncClosure();
    stack_trace->AddActivation(activation);
    if (FLAG_trace_debugger_stacktrace) {
      OS::PrintErr(
          "CollectAwaiterReturnStackTrace: visiting awaiter return "
          "closures:\n\t%s\n",
          activation->function().ToFullyQualifiedCString());
    }

    next_async_activation = activation->GetAsyncAwaiter(&caller_closure_finder);
    if (next_async_activation.IsNull()) {
      break;
    }

    async_activation = Closure::RawCast(next_async_activation.raw());
  }

  return stack_trace;
#endif  // defined(DART_PRECOMPILED_RUNTIME)
}

ActivationFrame* Debugger::TopDartFrame() const {
  StackFrameIterator iterator(ValidationPolicy::kDontValidateFrames,
                              Thread::Current(),
                              StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* frame;
  while (true) {
    frame = iterator.NextFrame();
    RELEASE_ASSERT(frame != nullptr);
    if (!frame->IsDartFrame()) {
      continue;
    }
    Code& code = Code::Handle(frame->LookupDartCode());
    ActivationFrame* activation = new ActivationFrame(
        frame->pc(), frame->fp(), frame->sp(), code, Object::null_array(), 0);
    return activation;
  }
}

DebuggerStackTrace* Debugger::StackTrace() {
  return (stack_trace_ != NULL) ? stack_trace_ : CollectStackTrace();
}

DebuggerStackTrace* Debugger::CurrentStackTrace() {
  return CollectStackTrace();
}

DebuggerStackTrace* Debugger::AsyncCausalStackTrace() {
  return (async_causal_stack_trace_ != NULL) ? async_causal_stack_trace_
                                             : CollectAsyncCausalStackTrace();
}

DebuggerStackTrace* Debugger::CurrentAsyncCausalStackTrace() {
  return CollectAsyncCausalStackTrace();
}

DebuggerStackTrace* Debugger::AwaiterStackTrace() {
  return (awaiter_stack_trace_ != NULL) ? awaiter_stack_trace_
                                        : CollectAwaiterReturnStackTrace();
}

DebuggerStackTrace* Debugger::CurrentAwaiterStackTrace() {
  return CollectAwaiterReturnStackTrace();
}

DebuggerStackTrace* Debugger::StackTraceFrom(const class StackTrace& ex_trace) {
  DebuggerStackTrace* stack_trace = new DebuggerStackTrace(8);
  Function& function = Function::Handle();
  Object& code_object = Object::Handle();
  Code& code = Code::Handle();

  const uword fp = 0;
  const uword sp = 0;
  const Array& deopt_frame = Array::Handle();
  const intptr_t deopt_frame_offset = -1;

  for (intptr_t i = 0; i < ex_trace.Length(); i++) {
    code_object = ex_trace.CodeAtFrame(i);
    // Pre-allocated StackTraces may include empty slots, either (a) to indicate
    // where frames were omitted in the case a stack has more frames than the
    // pre-allocated trace (such as a stack overflow) or (b) because a stack has
    // fewer frames that the pre-allocated trace (such as memory exhaustion with
    // a shallow stack).
    if (!code_object.IsNull()) {
      code ^= code_object.raw();
      ASSERT(code.IsFunctionCode());
      function = code.function();
      if (function.is_visible()) {
        ASSERT(function.raw() == code.function());
        uword pc =
            code.PayloadStart() + Smi::Value(ex_trace.PcOffsetAtFrame(i));
        if (code.is_optimized() && ex_trace.expand_inlined()) {
          // Traverse inlined frames.
          for (InlinedFunctionsIterator it(code, pc); !it.Done();
               it.Advance()) {
            function = it.function();
            code = it.code();
            ASSERT(function.raw() == code.function());
            uword pc = it.pc();
            ASSERT(pc != 0);
            ASSERT(code.PayloadStart() <= pc);
            ASSERT(pc < (code.PayloadStart() + code.Size()));

            ActivationFrame* activation = new ActivationFrame(
                pc, fp, sp, code, deopt_frame, deopt_frame_offset);
            stack_trace->AddActivation(activation);
          }
        } else {
          ActivationFrame* activation = new ActivationFrame(
              pc, fp, sp, code, deopt_frame, deopt_frame_offset);
          stack_trace->AddActivation(activation);
        }
      }
    }
  }
  return stack_trace;
}

void Debugger::SetExceptionPauseInfo(Dart_ExceptionPauseInfo pause_info) {
  ASSERT((pause_info == kNoPauseOnExceptions) ||
         (pause_info == kPauseOnUnhandledExceptions) ||
         (pause_info == kPauseOnAllExceptions));
  exc_pause_info_ = pause_info;
}

Dart_ExceptionPauseInfo Debugger::GetExceptionPauseInfo() const {
  return exc_pause_info_;
}

bool Debugger::ShouldPauseOnException(DebuggerStackTrace* stack_trace,
                                      const Instance& exception) {
  if (exc_pause_info_ == kNoPauseOnExceptions) {
    return false;
  }
  if (exc_pause_info_ == kPauseOnAllExceptions) {
    return true;
  }
  ASSERT(exc_pause_info_ == kPauseOnUnhandledExceptions);
  // Exceptions coming from invalid token positions should be skipped
  ActivationFrame* top_frame = stack_trace->FrameAt(0);
  if (!top_frame->TokenPos().IsReal() && top_frame->TryIndex() != -1) {
    return false;
  }
  ActivationFrame* handler_frame = stack_trace->GetHandlerFrame(exception);
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

void Debugger::PauseException(const Instance& exc) {
  if (FLAG_stress_async_stacks) {
    CollectAwaiterReturnStackTrace();
  }
  // We ignore this exception event when the VM is executing code invoked
  // by the debugger to evaluate variables values, when we see a nested
  // breakpoint or exception event, or if the debugger is not
  // interested in exception events.
  if (ignore_breakpoints_ || IsPaused() ||
      (exc_pause_info_ == kNoPauseOnExceptions)) {
    return;
  }
  DebuggerStackTrace* awaiter_stack_trace = CollectAwaiterReturnStackTrace();
  DebuggerStackTrace* stack_trace = CollectStackTrace();
  if (awaiter_stack_trace != NULL) {
    if (!ShouldPauseOnException(awaiter_stack_trace, exc)) {
      return;
    }
  } else {
    if (!ShouldPauseOnException(stack_trace, exc)) {
      return;
    }
  }
  ServiceEvent event(isolate_, ServiceEvent::kPauseException);
  event.set_exception(&exc);
  if (stack_trace->Length() > 0) {
    event.set_top_frame(stack_trace->FrameAt(0));
  }
  CacheStackTraces(stack_trace, CollectAsyncCausalStackTrace(),
                   CollectAwaiterReturnStackTrace());
  Pause(&event);
  HandleSteppingRequest(stack_trace_);  // we may get a rewind request
  ClearCachedStackTraces();
}

// Helper to refine the resolved token pos.
static void RefineBreakpointPos(const Script& script,
                                TokenPosition pos,
                                TokenPosition next_closest_token_position,
                                TokenPosition requested_token_pos,
                                TokenPosition last_token_pos,
                                intptr_t requested_column,
                                TokenPosition exact_token_pos,
                                TokenPosition* best_fit_pos,
                                intptr_t* best_column,
                                intptr_t* best_line,
                                TokenPosition* best_token_pos) {
  intptr_t token_start_column = -1;
  intptr_t token_line = -1;
  if (requested_column >= 0) {
    TokenPosition ignored = TokenPosition::kNoSource;
    TokenPosition end_of_line_pos = TokenPosition::kNoSource;
    script.GetTokenLocation(pos, &token_line, &token_start_column);
    script.TokenRangeAtLine(token_line, &ignored, &end_of_line_pos);
    TokenPosition token_end_pos =
        TokenPosition::Min(next_closest_token_position, end_of_line_pos);

    if ((token_end_pos.IsReal() && exact_token_pos.IsReal() &&
         (token_end_pos < exact_token_pos)) ||
        (token_start_column > *best_column)) {
      // Prefer the token with the lowest column number compatible
      // with the requested column.
      return;
    }
  }

  // Prefer the lowest (first) token pos.
  if (pos < *best_fit_pos) {
    *best_fit_pos = pos;
    *best_line = token_line;
    *best_column = token_start_column;
    // best_token_pos should only be real when the column number is specified.
    if (requested_column >= 0 && exact_token_pos.IsReal()) {
      *best_token_pos = TokenPosition::Deserialize(
          exact_token_pos.Pos() - (requested_column - *best_column));
    }
  }
}

// Returns the best fit token position for a breakpoint.
//
// Takes a range of tokens [requested_token_pos, last_token_pos] and
// an optional column (requested_column).  The range of tokens usually
// represents one line of the program text, but can represent a larger
// range on recursive calls.
//
// The best fit is found in two passes.
//
// The first pass finds a candidate token which:
//
//   - is a safepoint,
//   - has the lowest column number compatible with the requested column
//     if a column has been specified,
// and:
//   - has the lowest token position number which satisfies the above.
//
// When we consider a column number, we look for the token which
// intersects the desired column.  For example:
//
//          1         2         3
// 12345678901234567890         0
//
//   var x = function(function(y));
//              ^
//
// If we request a breakpoint at column 14, the lowest column number
// compatible with that would for column 11 (beginning of the
// 'function' token) in the example above.
//
// Once this candidate token from the first pass is found, we then
// have a second pass which considers only those tokens on the same
// line as the candidate token.
//
// The second pass finds a best fit token which:
//
//   - is a safepoint,
//   - has the same column number as the candidate token (perhaps
//     more than one token has the same column number),
// and:
//   - has the lowest code address in the generated code.
//
// We prefer the lowest compiled code address, because this tends to
// select the first subexpression on a line.  For example in a line
// with nested function calls f(g(x)), the call to g() will have a
// lower compiled code address than the call to f().
//
// If no best fit token can be found, the search is expanded,
// searching through the rest of the current function by calling this
// function recursively.
//
// TODO(turnidge): Given that we usually call this function with a
// token range restricted to a single line, this could be a one-pass
// algorithm, which would be simpler.  I believe that it only needs
// two passes to support the recursive try-the-whole-function case.
// Rewrite this later, once there are more tests in place.
TokenPosition Debugger::ResolveBreakpointPos(const Function& func,
                                             TokenPosition requested_token_pos,
                                             TokenPosition last_token_pos,
                                             intptr_t requested_column,
                                             TokenPosition exact_token_pos) {
  ASSERT(!func.HasOptimizedCode());

  requested_token_pos =
      TokenPosition::Max(requested_token_pos, func.token_pos());
  last_token_pos = TokenPosition::Min(last_token_pos, func.end_token_pos());

  Zone* zone = Thread::Current()->zone();
  Script& script = Script::Handle(zone, func.script());
  Code& code = Code::Handle(zone);
  PcDescriptors& desc = PcDescriptors::Handle(zone);
  ASSERT(func.HasCode());
  code = func.unoptimized_code();
  ASSERT(!code.IsNull());
  desc = code.pc_descriptors();

  // First pass: find the safe point which is closest to the beginning
  // of the given token range.
  TokenPosition best_fit_pos = TokenPosition::kMaxSource;
  intptr_t best_column = INT_MAX;
  intptr_t best_line = INT_MAX;
  // best_token_pos is only set to a real position if a real exact_token_pos
  // and a column number are provided.
  TokenPosition best_token_pos = TokenPosition::kNoSource;

  PcDescriptors::Iterator iter(desc, kSafepointKind);
  while (iter.MoveNext()) {
    const TokenPosition& pos = iter.TokenPos();
    if (pos.IsSynthetic() && pos == requested_token_pos) {
      // if there's a safepoint for a synthetic function start and the start
      // was requested, we're done.
      return pos;
    }
    if (!pos.IsWithin(requested_token_pos, last_token_pos)) {
      // Token is not in the target range.
      continue;
    }
    TokenPosition next_closest_token_position = TokenPosition::kMaxSource;
    if (requested_column >= 0) {
      // Find next closest safepoint
      PcDescriptors::Iterator iter2(desc, kSafepointKind);
      while (iter2.MoveNext()) {
        const TokenPosition& next = iter2.TokenPos();
        if (!next.IsReal()) continue;
        if ((pos < next) && (next < next_closest_token_position)) {
          next_closest_token_position = next;
        }
      }
    }
    RefineBreakpointPos(script, pos, next_closest_token_position,
                        requested_token_pos, last_token_pos, requested_column,
                        exact_token_pos, &best_fit_pos, &best_column,
                        &best_line, &best_token_pos);
  }

  // Second pass (if we found a safe point in the first pass).  Find
  // the token on the line which is at the best fit column (if column
  // was specified) and has the lowest code address.
  if (best_fit_pos != TokenPosition::kMaxSource) {
    ASSERT(best_fit_pos.IsReal());
    const Script& script = Script::Handle(zone, func.script());
    const TokenPosition begin_pos = best_fit_pos;

    TokenPosition end_of_line_pos = TokenPosition::kNoSource;
    if (best_line < 0) {
      script.GetTokenLocation(begin_pos, &best_line);
    }
    ASSERT(best_line > 0);
    TokenPosition ignored = TokenPosition::kNoSource;
    script.TokenRangeAtLine(best_line, &ignored, &end_of_line_pos);
    end_of_line_pos = TokenPosition::Max(end_of_line_pos, begin_pos);

    uword lowest_pc_offset = kUwordMax;
    PcDescriptors::Iterator iter(desc, kSafepointKind);
    while (iter.MoveNext()) {
      const TokenPosition& pos = iter.TokenPos();
      if (best_token_pos.IsReal()) {
        if (pos != best_token_pos) {
          // Not an match for the requested column.
          continue;
        }
      } else if (!pos.IsWithin(begin_pos, end_of_line_pos)) {
        // Token is not on same line as best fit.
        continue;
      }

      // Prefer the lowest pc offset.
      if (iter.PcOffset() < lowest_pc_offset) {
        lowest_pc_offset = iter.PcOffset();
        best_fit_pos = pos;
      }
    }
    return best_fit_pos;
  }

  // We didn't find a safe point in the given token range. Try and
  // find a safe point in the remaining source code of the function.
  // Since we have moved to the next line of the function, we no
  // longer are requesting a specific column number.
  if (last_token_pos < func.end_token_pos()) {
    return ResolveBreakpointPos(func, last_token_pos, func.end_token_pos(),
                                -1 /* no column */, TokenPosition::kNoSource);
  }
  return TokenPosition::kNoSource;
}

void Debugger::MakeCodeBreakpointAt(const Function& func,
                                    BreakpointLocation* loc) {
  ASSERT(loc->token_pos_.IsReal());
  ASSERT((loc != NULL) && loc->IsResolved());
  ASSERT(!func.HasOptimizedCode());
  ASSERT(func.HasCode());
  Code& code = Code::Handle(func.unoptimized_code());
  ASSERT(!code.IsNull());
  PcDescriptors& desc = PcDescriptors::Handle(code.pc_descriptors());
  uword lowest_pc_offset = kUwordMax;
  PcDescriptorsLayout::Kind lowest_kind = PcDescriptorsLayout::kAnyKind;
  // Find the safe point with the lowest compiled code address
  // that maps to the token position of the source breakpoint.
  PcDescriptors::Iterator iter(desc, kSafepointKind);
  while (iter.MoveNext()) {
    if (iter.TokenPos() == loc->token_pos_) {
      if (iter.PcOffset() < lowest_pc_offset) {
        lowest_pc_offset = iter.PcOffset();
        lowest_kind = iter.Kind();
      }
    }
  }
  if (lowest_pc_offset != kUwordMax) {
    uword lowest_pc = code.PayloadStart() + lowest_pc_offset;
    CodeBreakpoint* code_bpt = GetCodeBreakpoint(lowest_pc);
    if (code_bpt == NULL) {
      // No code breakpoint for this code exists; create one.
      code_bpt =
          new CodeBreakpoint(code, loc->token_pos_, lowest_pc, lowest_kind);
      if (FLAG_verbose_debug) {
        OS::PrintErr("Setting code breakpoint at pos %s pc %#" Px
                     " offset %#" Px "\n",
                     loc->token_pos_.ToCString(), lowest_pc,
                     lowest_pc - code.PayloadStart());
      }
      RegisterCodeBreakpoint(code_bpt);
    }
    code_bpt->set_bpt_location(loc);
    if (loc->AnyEnabled()) {
      code_bpt->Enable();
    }
  }
}

void Debugger::FindCompiledFunctions(
    const Script& script,
    TokenPosition start_pos,
    TokenPosition end_pos,
    GrowableObjectArray* code_function_list) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Class& cls = Class::Handle(zone);
  Array& functions = Array::Handle(zone);
  GrowableObjectArray& closures = GrowableObjectArray::Handle(zone);
  Function& function = Function::Handle(zone);

  closures = isolate_->object_store()->closure_functions();
  const intptr_t num_closures = closures.Length();
  for (intptr_t pos = 0; pos < num_closures; pos++) {
    function ^= closures.At(pos);
    ASSERT(!function.IsNull());
    if ((function.token_pos() == start_pos) &&
        (function.end_token_pos() == end_pos) &&
        (function.script() == script.raw())) {
      if (function.is_debuggable()) {
        if (function.HasCode()) {
          code_function_list->Add(function);
        }
      }
      if (function.HasImplicitClosureFunction()) {
        function = function.ImplicitClosureFunction();
        if (function.is_debuggable()) {
          if (function.HasCode()) {
            code_function_list->Add(function);
          }
        }
      }
    }
  }

  const ClassTable& class_table = *isolate_->class_table();
  const intptr_t num_classes = class_table.NumCids();
  const intptr_t num_tlc_classes = class_table.NumTopLevelCids();
  for (intptr_t i = 1; i < num_classes + num_tlc_classes; i++) {
    const classid_t cid =
        i < num_classes ? i : ClassTable::CidFromTopLevelIndex(i - num_classes);
    if (class_table.HasValidClassAt(cid)) {
      cls = class_table.At(cid);
      // If the class is not finalized, e.g. if it hasn't been parsed
      // yet entirely, we can ignore it. If it contains a function with
      // an unresolved breakpoint, we will detect it if and when the
      // function gets compiled.
      if (!cls.is_finalized()) {
        continue;
      }
      // Note: we need to check the functions of this class even if
      // the class is defined in a different 'script'. There could
      // be mixin functions from the given script in this class.
      functions = cls.current_functions();
      if (!functions.IsNull()) {
        const intptr_t num_functions = functions.Length();
        for (intptr_t pos = 0; pos < num_functions; pos++) {
          function ^= functions.At(pos);
          ASSERT(!function.IsNull());
          bool function_added = false;
          if (function.is_debuggable() && function.HasCode() &&
              function.token_pos() == start_pos &&
              function.end_token_pos() == end_pos &&
              function.script() == script.raw()) {
            code_function_list->Add(function);
            function_added = true;
          }
          if (function_added && function.HasImplicitClosureFunction()) {
            function = function.ImplicitClosureFunction();
            if (function.is_debuggable() && function.HasCode()) {
              code_function_list->Add(function);
            }
          }
        }
      }
    }
  }
}

static void UpdateBestFit(Function* best_fit, const Function& func) {
  if (best_fit->IsNull()) {
    *best_fit = func.raw();
  } else if ((best_fit->token_pos().IsSynthetic() ||
              func.token_pos().IsSynthetic() ||
              (best_fit->token_pos() < func.token_pos())) &&
             (func.end_token_pos() <= best_fit->end_token_pos())) {
    *best_fit = func.raw();
  }
}

// Returns true if a best fit is found. A best fit can either be a function
// or a field. If it is a function, then the best fit function is returned
// in |best_fit|. If a best fit is a field, it means that a latent
// breakpoint can be set in the range |token_pos| to |last_token_pos|.
bool Debugger::FindBestFit(const Script& script,
                           TokenPosition token_pos,
                           TokenPosition last_token_pos,
                           Function* best_fit) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Class& cls = Class::Handle(zone);

  // A single script can belong to several libraries because of mixins.
  // Go through all libraries and for each that contains the script, try to find
  // a fit there.
  // Return the first fit found, but if a library doesn't contain a fit,
  // process the next one.
  const GrowableObjectArray& libs = GrowableObjectArray::Handle(
      zone, thread->isolate()->object_store()->libraries());
  Library& lib = Library::Handle(zone);
  for (int i = 0; i < libs.Length(); i++) {
    lib ^= libs.At(i);
    ASSERT(!lib.IsNull());
    const Array& scripts = Array::Handle(zone, lib.LoadedScripts());
    bool lib_has_script = false;
    for (intptr_t j = 0; j < scripts.Length(); j++) {
      if (scripts.At(j) == script.raw()) {
        lib_has_script = true;
        break;
      }
    }
    if (!lib_has_script) {
      continue;
    }

    if (!lib.IsDebuggable()) {
      if (FLAG_verbose_debug) {
        OS::PrintErr("Library '%s' has been marked as non-debuggable\n",
                     lib.ToCString());
      }
      continue;
    }
    const GrowableObjectArray& closures = GrowableObjectArray::Handle(
        zone, isolate_->object_store()->closure_functions());
    Array& functions = Array::Handle(zone);
    Function& function = Function::Handle(zone);
    Array& fields = Array::Handle(zone);
    Field& field = Field::Handle(zone);
    Error& error = Error::Handle(zone);

    const intptr_t num_closures = closures.Length();
    for (intptr_t i = 0; i < num_closures; i++) {
      function ^= closures.At(i);
      if (FunctionOverlaps(function, script, token_pos, last_token_pos)) {
        // Select the inner most closure.
        UpdateBestFit(best_fit, function);
      }
    }
    if (!best_fit->IsNull()) {
      // The inner most closure found will be the best fit. Going
      // over class functions below will not help in any further
      // narrowing.
      return true;
    }

    const ClassTable& class_table = *isolate_->class_table();
    const intptr_t num_classes = class_table.NumCids();
    const intptr_t num_tlc_classes = class_table.NumTopLevelCids();
    for (intptr_t i = 1; i < num_classes + num_tlc_classes; i++) {
      const classid_t cid =
          i < num_classes ? i
                          : ClassTable::CidFromTopLevelIndex(i - num_classes);
      if (!class_table.HasValidClassAt(cid)) {
        continue;
      }
      cls = class_table.At(cid);
      // This class is relevant to us only if it belongs to the
      // library to which |script| belongs.
      if (cls.library() != lib.raw()) {
        continue;
      }
      // Parse class definition if not done yet.
      error = cls.EnsureIsFinalized(Thread::Current());
      if (!error.IsNull()) {
        // Ignore functions in this class.
        // TODO(hausner): Should we propagate this error? How?
        // EnsureIsFinalized only returns an error object if there
        // is no longjump base on the stack.
        continue;
      }
      functions = cls.current_functions();
      if (!functions.IsNull()) {
        const intptr_t num_functions = functions.Length();
        for (intptr_t pos = 0; pos < num_functions; pos++) {
          function ^= functions.At(pos);
          ASSERT(!function.IsNull());
          if (IsImplicitFunction(function)) {
            // Implicit functions do not have a user specifiable source
            // location.
            continue;
          }
          if (FunctionOverlaps(function, script, token_pos, last_token_pos)) {
            // Closures and inner functions within a class method are not
            // present in the functions of a class. Hence, we can return
            // right away as looking through other functions of a class
            // will not narrow down to any inner function/closure.
            *best_fit = function.raw();
            return true;
          }
        }
      }
      // If none of the functions in the class contain token_pos, then we
      // check if it falls within a function literal initializer of a field
      // that has not been initialized yet. If the field (and hence the
      // function literal initializer) has already been initialized, then
      // it would have been found above in the object store as a closure.
      fields = cls.fields();
      if (!fields.IsNull()) {
        const intptr_t num_fields = fields.Length();
        for (intptr_t pos = 0; pos < num_fields; pos++) {
          TokenPosition start = TokenPosition::kNoSource;
          TokenPosition end = TokenPosition::kNoSource;
          field ^= fields.At(pos);
          ASSERT(!field.IsNull());
          if (field.Script() != script.raw()) {
            // The field should be defined in the script we want to set
            // the breakpoint in.
            continue;
          }
          if (!field.has_nontrivial_initializer()) {
            continue;
          }
          start = field.token_pos();
          end = field.end_token_pos();
          if (token_pos.IsWithin(start, end) ||
              start.IsWithin(token_pos, last_token_pos)) {
            return true;
          }
        }
      }
    }
  }
  return false;
}

BreakpointLocation* Debugger::SetCodeBreakpoints(
    const Script& script,
    TokenPosition token_pos,
    TokenPosition last_token_pos,
    intptr_t requested_line,
    intptr_t requested_column,
    TokenPosition exact_token_pos,
    const GrowableObjectArray& functions) {
  Function& function = Function::Handle();
  function ^= functions.At(0);
  TokenPosition breakpoint_pos = ResolveBreakpointPos(
      function, token_pos, last_token_pos, requested_column, exact_token_pos);
  if (!breakpoint_pos.IsReal()) {
    return NULL;
  }
  // Find an existing resolved breakpoint location.
  BreakpointLocation* loc =
      GetBreakpointLocation(script, TokenPosition::kNoSource,
                            /* requested_line = */ -1,
                            /* requested_column = */ -1, breakpoint_pos);
  if (loc == NULL) {
    // Find an existing unresolved breakpoint location.
    loc = GetBreakpointLocation(script, token_pos, requested_line,
                                requested_column);
  }
  if (loc == NULL) {
    loc = new BreakpointLocation(script, breakpoint_pos, breakpoint_pos,
                                 requested_line, requested_column);
    RegisterBreakpointLocation(loc);
  }
  // A source breakpoint for this location may already exists, but it may
  // not yet be resolved in code.
  if (loc->IsResolved()) {
    return loc;
  }
  loc->SetResolved(function, breakpoint_pos);

  // Create code breakpoints for all compiled functions we found.
  Function& func = Function::Handle();
  const intptr_t num_functions = functions.Length();
  for (intptr_t i = 0; i < num_functions; i++) {
    func ^= functions.At(i);
    ASSERT(func.HasCode());
    MakeCodeBreakpointAt(func, loc);
  }
  if (FLAG_verbose_debug) {
    intptr_t line_number = -1;
    intptr_t column_number = -1;
    script.GetTokenLocation(breakpoint_pos, &line_number, &column_number);
    OS::PrintErr("Resolved code breakpoint for function '%s' at line %" Pd
                 " col %" Pd "\n",
                 func.ToFullyQualifiedCString(), line_number, column_number);
  }
  return loc;
}

BreakpointLocation* Debugger::SetBreakpoint(const Script& script,
                                            TokenPosition token_pos,
                                            TokenPosition last_token_pos,
                                            intptr_t requested_line,
                                            intptr_t requested_column,
                                            const Function& function) {
  Function& func = Function::Handle();
  if (function.IsNull()) {
    if (!FindBestFit(script, token_pos, last_token_pos, &func)) {
      return NULL;
    }
    // If func was not set (still Null), the best fit is a field.
  } else {
    func = function.raw();
    if (!func.token_pos().IsReal()) {
      return NULL;  // Missing source positions?
    }
  }
  if (!func.IsNull()) {
    // There may be more than one function object for a given function
    // in source code. There may be implicit closure functions, and
    // there may be copies of mixin functions. Collect all compiled
    // functions whose source code range matches exactly the best fit
    // function we found.
    GrowableObjectArray& code_functions =
        GrowableObjectArray::Handle(GrowableObjectArray::New());
    FindCompiledFunctions(script, func.token_pos(), func.end_token_pos(),
                          &code_functions);

    if (code_functions.Length() > 0) {
      // One or more function object containing this breakpoint location
      // have already been compiled. We can resolve the breakpoint now.
      // If requested_column is larger than zero, [token_pos, last_token_pos]
      // governs one single line of code.
      TokenPosition exact_token_pos = TokenPosition::kNoSource;
      if (token_pos != last_token_pos && requested_column >= 0) {
#if !defined(DART_PRECOMPILED_RUNTIME)
        exact_token_pos =
            FindExactTokenPosition(script, token_pos, requested_column);
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
      }
      DeoptimizeWorld();
      BreakpointLocation* loc =
          SetCodeBreakpoints(script, token_pos, last_token_pos, requested_line,
                             requested_column, exact_token_pos, code_functions);
      if (loc != NULL) {
        return loc;
      }
    }
  }
  // There is either an uncompiled function, or an uncompiled function literal
  // initializer of a field at |token_pos|. Hence, Register an unresolved
  // breakpoint.
  if (FLAG_verbose_debug) {
    intptr_t line_number = -1;
    intptr_t column_number = -1;
    script.GetTokenLocation(token_pos, &line_number, &column_number);
    if (func.IsNull()) {
      OS::PrintErr(
          "Registering pending breakpoint for "
          "an uncompiled function literal at line %" Pd " col %" Pd "\n",
          line_number, column_number);
    } else {
      OS::PrintErr(
          "Registering pending breakpoint for "
          "uncompiled function '%s' at line %" Pd " col %" Pd "\n",
          func.ToFullyQualifiedCString(), line_number, column_number);
    }
  }
  BreakpointLocation* loc =
      GetBreakpointLocation(script, token_pos, -1, requested_column);
  if (loc == NULL) {
    loc = new BreakpointLocation(script, token_pos, last_token_pos,
                                 requested_line, requested_column);
    RegisterBreakpointLocation(loc);
  }
  return loc;
}

// Synchronize the enabled/disabled state of all code breakpoints
// associated with the breakpoint location loc.
void Debugger::SyncBreakpointLocation(BreakpointLocation* loc) {
  bool any_enabled = loc->AnyEnabled();

  CodeBreakpoint* cbpt = code_breakpoints_;
  while (cbpt != NULL) {
    if (loc == cbpt->bpt_location()) {
      if (any_enabled) {
        cbpt->Enable();
      } else {
        cbpt->Disable();
      }
    }
    cbpt = cbpt->next();
  }
}

Breakpoint* Debugger::SetBreakpointAtEntry(const Function& target_function,
                                           bool single_shot) {
  ASSERT(!target_function.IsNull());
  // AsyncFunction is marked not debuggable. When target_function is an async
  // function, it is actually referring the inner async_op. Allow the
  // breakpoint to be set, it will get resolved correctly when inner async_op
  // gets compiled.
  if (!target_function.is_debuggable() && !target_function.IsAsyncFunction()) {
    return NULL;
  }
  const Script& script = Script::Handle(target_function.script());
  BreakpointLocation* bpt_location = SetBreakpoint(
      script, target_function.token_pos(), target_function.end_token_pos(), -1,
      -1 /* no requested line/col */, target_function);
  if (bpt_location == NULL) {
    return NULL;
  }

  if (single_shot) {
    return bpt_location->AddSingleShot(this);
  } else {
    return bpt_location->AddRepeated(this);
  }
}

Breakpoint* Debugger::SetBreakpointAtActivation(const Instance& closure,
                                                bool for_over_await) {
  if (!closure.IsClosure()) {
    return NULL;
  }
  const Function& func = Function::Handle(Closure::Cast(closure).function());
  const Script& script = Script::Handle(func.script());
  BreakpointLocation* bpt_location =
      SetBreakpoint(script, func.token_pos(), func.end_token_pos(), -1,
                    -1 /* no line/col */, func);
  return bpt_location->AddPerClosure(this, closure, for_over_await);
}

Breakpoint* Debugger::SetBreakpointAtAsyncOp(const Function& async_op) {
  const Script& script = Script::Handle(async_op.script());
  BreakpointLocation* bpt_location =
      SetBreakpoint(script, async_op.token_pos(), async_op.end_token_pos(), -1,
                    -1 /* no line/col */, async_op);
  auto bpt = bpt_location->AddSingleShot(this);
  bpt->set_is_synthetic_async(true);
  return bpt;
}

Breakpoint* Debugger::BreakpointAtActivation(const Instance& closure) {
  if (!closure.IsClosure()) {
    return NULL;
  }

  BreakpointLocation* loc = breakpoint_locations_;
  while (loc != NULL) {
    Breakpoint* bpt = loc->breakpoints();
    while (bpt != NULL) {
      if (bpt->IsPerClosure()) {
        if (closure.raw() == bpt->closure()) {
          return bpt;
        }
      }
      bpt = bpt->next();
    }
    loc = loc->next();
  }

  return NULL;
}

Breakpoint* Debugger::SetBreakpointAtLine(const String& script_url,
                                          intptr_t line_number) {
  // Prevent future tests from calling this function in the wrong
  // execution state.  If you hit this assert, consider using
  // Dart_SetBreakpoint instead.
  ASSERT(Thread::Current()->execution_state() == Thread::kThreadInVM);

  BreakpointLocation* loc =
      BreakpointLocationAtLineCol(script_url, line_number, -1 /* no column */);
  if (loc != NULL) {
    return loc->AddRepeated(this);
  }
  return NULL;
}

Breakpoint* Debugger::SetBreakpointAtLineCol(const String& script_url,
                                             intptr_t line_number,
                                             intptr_t column_number) {
  // Prevent future tests from calling this function in the wrong
  // execution state.  If you hit this assert, consider using
  // Dart_SetBreakpoint instead.
  ASSERT(Thread::Current()->execution_state() == Thread::kThreadInVM);

  BreakpointLocation* loc =
      BreakpointLocationAtLineCol(script_url, line_number, column_number);
  if (loc != NULL) {
    return loc->AddRepeated(this);
  }
  return NULL;
}

BreakpointLocation* Debugger::BreakpointLocationAtLineCol(
    const String& script_url,
    intptr_t line_number,
    intptr_t column_number) {
  Zone* zone = Thread::Current()->zone();
  Library& lib = Library::Handle(zone);
  Script& script = Script::Handle(zone);
  const GrowableObjectArray& libs =
      GrowableObjectArray::Handle(isolate_->object_store()->libraries());
  bool is_package = script_url.StartsWith(Symbols::PackageScheme());
  Script& script_for_lib = Script::Handle(zone);
  for (intptr_t i = 0; i < libs.Length(); i++) {
    lib ^= libs.At(i);
    // Ensure that all top-level members are loaded so their scripts
    // are available for look up. When certain script only contains
    // top level functions, scripts could still be loaded correctly.
    lib.EnsureTopLevelClassIsFinalized();
    script_for_lib = lib.LookupScript(script_url, !is_package);
    if (!script_for_lib.IsNull()) {
      if (script.IsNull()) {
        script = script_for_lib.raw();
      } else if (script.raw() != script_for_lib.raw()) {
        if (FLAG_verbose_debug) {
          OS::PrintErr("Multiple scripts match url '%s'\n",
                       script_url.ToCString());
        }
        return NULL;
      }
    }
  }
  if (script.IsNull()) {
    // No script found with given url. Create a latent breakpoint which
    // will be set if the url is loaded later.
    BreakpointLocation* latent_bpt =
        GetLatentBreakpoint(script_url, line_number, column_number);
    if (FLAG_verbose_debug) {
      OS::PrintErr(
          "Set latent breakpoint in url '%s' at "
          "line %" Pd " col %" Pd "\n",
          script_url.ToCString(), line_number, column_number);
    }
    return latent_bpt;
  }
  TokenPosition first_token_idx = TokenPosition::kNoSource;
  TokenPosition last_token_idx = TokenPosition::kNoSource;
  script.TokenRangeAtLine(line_number, &first_token_idx, &last_token_idx);
  if (!first_token_idx.IsReal()) {
    // Script does not contain the given line number.
    if (FLAG_verbose_debug) {
      OS::PrintErr("Script '%s' does not contain line number %" Pd "\n",
                   script_url.ToCString(), line_number);
    }
    return NULL;
  } else if (!last_token_idx.IsReal()) {
    // Line does not contain any tokens.
    if (FLAG_verbose_debug) {
      OS::PrintErr("No executable code at line %" Pd " in '%s'\n", line_number,
                   script_url.ToCString());
    }
    return NULL;
  }

  BreakpointLocation* loc = NULL;
  ASSERT(first_token_idx <= last_token_idx);
  while ((loc == NULL) && (first_token_idx <= last_token_idx)) {
    loc = SetBreakpoint(script, first_token_idx, last_token_idx, line_number,
                        column_number, Function::Handle());
    first_token_idx = first_token_idx.Next();
  }
  if ((loc == NULL) && FLAG_verbose_debug) {
    OS::PrintErr("No executable code at line %" Pd " in '%s'\n", line_number,
                 script_url.ToCString());
  }
  return loc;
}

// static
void Debugger::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  ASSERT(visitor != NULL);
  BreakpointLocation* loc = breakpoint_locations_;
  while (loc != NULL) {
    loc->VisitObjectPointers(visitor);
    loc = loc->next();
  }
  loc = latent_locations_;
  while (loc != NULL) {
    loc->VisitObjectPointers(visitor);
    loc = loc->next();
  }
  CodeBreakpoint* cbpt = code_breakpoints_;
  while (cbpt != NULL) {
    cbpt->VisitObjectPointers(visitor);
    cbpt = cbpt->next();
  }
  visitor->VisitPointer(reinterpret_cast<ObjectPtr*>(&top_frame_awaiter_));
}

void Debugger::Pause(ServiceEvent* event) {
  ASSERT(event->IsPause());      // Should call InvokeEventHandler instead.
  ASSERT(!ignore_breakpoints_);  // We shouldn't get here when ignoring bpts.
  ASSERT(!IsPaused());           // No recursive pausing.

  pause_event_ = event;
  pause_event_->UpdateTimestamp();

  // We are about to invoke the debugger's event handler. Disable
  // interrupts for this thread while waiting for debug commands over
  // the service protocol.
  {
    Thread* thread = Thread::Current();
    DisableThreadInterruptsScope dtis(thread);
    TIMELINE_DURATION(thread, Debugger, "Debugger Pause");

    // Send the pause event.
    Service::HandleEvent(event);

    {
      TransitionVMToNative transition(thread);
      isolate_->PauseEventHandler();
    }

    // Notify the service that we have resumed.
    const Error& error = Error::Handle(Thread::Current()->sticky_error());
    ASSERT(error.IsNull() || error.IsUnwindError() ||
           error.IsUnhandledException());

    // Only send a resume event when the isolate is not unwinding.
    if (!error.IsUnwindError()) {
      ServiceEvent resume_event(event->isolate(), ServiceEvent::kResume);
      resume_event.set_top_frame(event->top_frame());
      Service::HandleEvent(&resume_event);
    }
  }

  if (needs_breakpoint_cleanup_) {
    RemoveUnlinkedCodeBreakpoints();
  }
  pause_event_ = NULL;
}

void Debugger::EnterSingleStepMode() {
  ResetSteppingFramePointers();
  DeoptimizeWorld();
  NotifySingleStepping(true);
}

void Debugger::ResetSteppingFramePointers() {
  stepping_fp_ = 0;
  async_stepping_fp_ = 0;
}

bool Debugger::SteppedForSyntheticAsyncBreakpoint() const {
  return synthetic_async_breakpoint_ != NULL;
}

void Debugger::CleanupSyntheticAsyncBreakpoint() {
  if (synthetic_async_breakpoint_ != NULL) {
    RemoveBreakpoint(synthetic_async_breakpoint_->id());
    synthetic_async_breakpoint_ = NULL;
  }
}

void Debugger::RememberTopFrameAwaiter() {
  if (!FLAG_async_debugger) {
    return;
  }
  if (stack_trace_->Length() > 0) {
    CallerClosureFinder caller_closure_finder(Thread::Current()->zone());
    top_frame_awaiter_ =
        stack_trace_->FrameAt(0)->GetAsyncAwaiter(&caller_closure_finder);
  } else {
    top_frame_awaiter_ = Object::null();
  }
}

void Debugger::SetAsyncSteppingFramePointer(DebuggerStackTrace* stack_trace) {
  if (!FLAG_async_debugger) {
    return;
  }
  if ((stack_trace->Length()) > 0 &&
      (stack_trace->FrameAt(0)->function().IsAsyncClosure() ||
       stack_trace->FrameAt(0)->function().IsAsyncGenClosure())) {
    async_stepping_fp_ = stack_trace->FrameAt(0)->fp();
  } else {
    async_stepping_fp_ = 0;
  }
}

void Debugger::SetSyncSteppingFramePointer(DebuggerStackTrace* stack_trace) {
  if (stack_trace->Length() > 0) {
    stepping_fp_ = stack_trace->FrameAt(0)->fp();
  } else {
    stepping_fp_ = 0;
  }
}

void Debugger::HandleSteppingRequest(DebuggerStackTrace* stack_trace,
                                     bool skip_next_step) {
  ResetSteppingFramePointers();
  RememberTopFrameAwaiter();
  if (resume_action_ == kStepInto) {
    // When single stepping, we need to deoptimize because we might be
    // stepping into optimized code.  This happens in particular if
    // the isolate has been interrupted, but can happen in other cases
    // as well.  We need to deoptimize the world in case we are about
    // to call an optimized function.
    DeoptimizeWorld();
    NotifySingleStepping(true);
    skip_next_step_ = skip_next_step;
    SetAsyncSteppingFramePointer(stack_trace);
    if (FLAG_verbose_debug) {
      OS::PrintErr("HandleSteppingRequest- kStepInto\n");
    }
  } else if (resume_action_ == kStepOver) {
    DeoptimizeWorld();
    NotifySingleStepping(true);
    skip_next_step_ = skip_next_step;
    SetSyncSteppingFramePointer(stack_trace);
    SetAsyncSteppingFramePointer(stack_trace);
    if (FLAG_verbose_debug) {
      OS::PrintErr("HandleSteppingRequest- kStepOver %" Px "\n", stepping_fp_);
    }
  } else if (resume_action_ == kStepOut) {
    if (FLAG_async_debugger) {
      if (stack_trace->FrameAt(0)->function().IsAsyncClosure() ||
          stack_trace->FrameAt(0)->function().IsAsyncGenClosure()) {
        CallerClosureFinder caller_closure_finder(Thread::Current()->zone());
        // Request to step out of an async/async* closure.
        const Object& async_op = Object::Handle(
            stack_trace->FrameAt(0)->GetAsyncAwaiter(&caller_closure_finder));
        if (!async_op.IsNull()) {
          // Step out to the awaiter.
          ASSERT(async_op.IsClosure());
          AsyncStepInto(Closure::Cast(async_op));
          if (FLAG_verbose_debug) {
            OS::PrintErr("HandleSteppingRequest- kContinue to async_op %s\n",
                         Function::Handle(Closure::Cast(async_op).function())
                             .ToFullyQualifiedCString());
          }
          return;
        }
      }
    }
    // Fall through to synchronous stepping.
    DeoptimizeWorld();
    NotifySingleStepping(true);
    // Find topmost caller that is debuggable.
    for (intptr_t i = 1; i < stack_trace->Length(); i++) {
      ActivationFrame* frame = stack_trace->FrameAt(i);
      if (frame->IsDebuggable()) {
        stepping_fp_ = frame->fp();
        break;
      }
    }
    if (FLAG_verbose_debug) {
      OS::PrintErr("HandleSteppingRequest- kStepOut %" Px "\n", stepping_fp_);
    }
  } else if (resume_action_ == kStepRewind) {
    if (FLAG_trace_rewind) {
      OS::PrintErr("Rewinding to frame %" Pd "\n", resume_frame_index_);
      OS::PrintErr(
          "-------------------------\n"
          "All frames...\n\n");
      StackFrameIterator iterator(ValidationPolicy::kDontValidateFrames,
                                  Thread::Current(),
                                  StackFrameIterator::kNoCrossThreadIteration);
      StackFrame* frame = iterator.NextFrame();
      intptr_t num = 0;
      while ((frame != NULL)) {
        OS::PrintErr("#%04" Pd " %s\n", num++, frame->ToCString());
        frame = iterator.NextFrame();
      }
    }
    RewindToFrame(resume_frame_index_);
    UNREACHABLE();
  }
}

void Debugger::CacheStackTraces(DebuggerStackTrace* stack_trace,
                                DebuggerStackTrace* async_causal_stack_trace,
                                DebuggerStackTrace* awaiter_stack_trace) {
  ASSERT(stack_trace_ == NULL);
  stack_trace_ = stack_trace;
  ASSERT(async_causal_stack_trace_ == NULL);
  async_causal_stack_trace_ = async_causal_stack_trace;
  ASSERT(awaiter_stack_trace_ == NULL);
  awaiter_stack_trace_ = awaiter_stack_trace;
}

void Debugger::ClearCachedStackTraces() {
  stack_trace_ = NULL;
  async_causal_stack_trace_ = NULL;
  awaiter_stack_trace_ = NULL;
}

static intptr_t FindNextRewindFrameIndex(DebuggerStackTrace* stack,
                                         intptr_t frame_index) {
  for (intptr_t i = frame_index + 1; i < stack->Length(); i++) {
    ActivationFrame* frame = stack->FrameAt(i);
    if (frame->IsRewindable()) {
      return i;
    }
  }
  return -1;
}

// Can the top frame be rewound?
bool Debugger::CanRewindFrame(intptr_t frame_index, const char** error) const {
  // check rewind pc is found
  DebuggerStackTrace* stack = Isolate::Current()->debugger()->StackTrace();
  intptr_t num_frames = stack->Length();
  if (frame_index < 1 || frame_index >= num_frames) {
    if (error != nullptr) {
      *error = Thread::Current()->zone()->PrintToString(
          "Frame must be in bounds [1..%" Pd
          "]: "
          "saw %" Pd "",
          num_frames - 1, frame_index);
    }
    return false;
  }
  ActivationFrame* frame = stack->FrameAt(frame_index);
  if (!frame->IsRewindable()) {
    intptr_t next_index = FindNextRewindFrameIndex(stack, frame_index);
    if (next_index > 0) {
      *error = Thread::Current()->zone()->PrintToString(
          "Cannot rewind to frame %" Pd
          " due to conflicting compiler "
          "optimizations. "
          "Run the vm with --no-prune-dead-locals to disallow these "
          "optimizations. "
          "Next valid rewind frame is %" Pd ".",
          frame_index, next_index);
    } else {
      *error = Thread::Current()->zone()->PrintToString(
          "Cannot rewind to frame %" Pd
          " due to conflicting compiler "
          "optimizations. "
          "Run the vm with --no-prune-dead-locals to disallow these "
          "optimizations.",
          frame_index);
    }
    return false;
  }
  return true;
}

// Given a return address, find the "rewind" pc, which is the pc
// before the corresponding call.
static uword LookupRewindPc(const Code& code, uword return_address) {
  ASSERT(!code.is_optimized());
  ASSERT(code.ContainsInstructionAt(return_address));

  uword pc_offset = return_address - code.PayloadStart();
  const PcDescriptors& descriptors =
      PcDescriptors::Handle(code.pc_descriptors());
  PcDescriptors::Iterator iter(
      descriptors, PcDescriptorsLayout::kRewind | PcDescriptorsLayout::kIcCall |
                       PcDescriptorsLayout::kUnoptStaticCall);
  intptr_t rewind_deopt_id = -1;
  uword rewind_pc = 0;
  while (iter.MoveNext()) {
    if (iter.Kind() == PcDescriptorsLayout::kRewind) {
      // Remember the last rewind so we don't need to iterator twice.
      rewind_pc = code.PayloadStart() + iter.PcOffset();
      rewind_deopt_id = iter.DeoptId();
    }
    if ((pc_offset == iter.PcOffset()) && (iter.DeoptId() == rewind_deopt_id)) {
      return rewind_pc;
    }
  }
  return 0;
}

void Debugger::RewindToFrame(intptr_t frame_index) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Code& code = Code::Handle(zone);
  Function& function = Function::Handle(zone);

  // Find the requested frame.
  StackFrameIterator iterator(ValidationPolicy::kDontValidateFrames,
                              Thread::Current(),
                              StackFrameIterator::kNoCrossThreadIteration);
  intptr_t current_frame = 0;
  for (StackFrame* frame = iterator.NextFrame(); frame != NULL;
       frame = iterator.NextFrame()) {
    ASSERT(frame->IsValid());
    if (frame->IsDartFrame()) {
      code = frame->LookupDartCode();
      function = code.function();
      if (!IsFunctionVisible(function)) {
        continue;
      }
      if (code.is_optimized()) {
        intptr_t sub_index = 0;
        for (InlinedFunctionsIterator it(code, frame->pc()); !it.Done();
             it.Advance()) {
          if (current_frame == frame_index) {
            RewindToOptimizedFrame(frame, code, sub_index);
            UNREACHABLE();
          }
          current_frame++;
          sub_index++;
        }
      } else {
        if (current_frame == frame_index) {
          // We are rewinding to an unoptimized frame.
          RewindToUnoptimizedFrame(frame, code);
          UNREACHABLE();
        }
        current_frame++;
      }
    }
  }
  UNIMPLEMENTED();
}

void Debugger::RewindToUnoptimizedFrame(StackFrame* frame, const Code& code) {
  // We will be jumping out of the debugger rather than exiting this
  // function, so prepare the debugger state.
  ClearCachedStackTraces();
  resume_action_ = kContinue;
  resume_frame_index_ = -1;
  EnterSingleStepMode();

  uword rewind_pc = LookupRewindPc(code, frame->pc());
  if (FLAG_trace_rewind && rewind_pc == 0) {
    OS::PrintErr("Unable to find rewind pc for pc(%" Px ")\n", frame->pc());
  }
  ASSERT(rewind_pc != 0);
  if (FLAG_trace_rewind) {
    OS::PrintErr(
        "===============================\n"
        "Rewinding to unoptimized frame:\n"
        "    rewind_pc(0x%" Px " offset:0x%" Px ") sp(0x%" Px ") fp(0x%" Px
        ")\n"
        "===============================\n",
        rewind_pc, rewind_pc - code.PayloadStart(), frame->sp(), frame->fp());
  }
  Exceptions::JumpToFrame(Thread::Current(), rewind_pc, frame->sp(),
                          frame->fp(), true /* clear lazy deopt at target */);
  UNREACHABLE();
}

void Debugger::RewindToOptimizedFrame(StackFrame* frame,
                                      const Code& optimized_code,
                                      intptr_t sub_index) {
  post_deopt_frame_index_ = sub_index;

  // We will be jumping out of the debugger rather than exiting this
  // function, so prepare the debugger state.
  ClearCachedStackTraces();
  resume_action_ = kContinue;
  resume_frame_index_ = -1;
  EnterSingleStepMode();

  if (FLAG_trace_rewind) {
    OS::PrintErr(
        "===============================\n"
        "Deoptimizing frame for rewind:\n"
        "    deopt_pc(0x%" Px ") sp(0x%" Px ") fp(0x%" Px
        ")\n"
        "===============================\n",
        frame->pc(), frame->sp(), frame->fp());
  }
  Thread* thread = Thread::Current();
  thread->set_resume_pc(frame->pc());
  uword deopt_stub_pc = StubCode::DeoptForRewind().EntryPoint();
  Exceptions::JumpToFrame(thread, deopt_stub_pc, frame->sp(), frame->fp(),
                          true /* clear lazy deopt at target */);
  UNREACHABLE();
}

void Debugger::RewindPostDeopt() {
  intptr_t rewind_frame = post_deopt_frame_index_;
  post_deopt_frame_index_ = -1;
  if (FLAG_trace_rewind) {
    OS::PrintErr("Post deopt, jumping to frame %" Pd "\n", rewind_frame);
    OS::PrintErr(
        "-------------------------\n"
        "All frames...\n\n");
    StackFrameIterator iterator(ValidationPolicy::kDontValidateFrames,
                                Thread::Current(),
                                StackFrameIterator::kNoCrossThreadIteration);
    StackFrame* frame = iterator.NextFrame();
    intptr_t num = 0;
    while ((frame != NULL)) {
      OS::PrintErr("#%04" Pd " %s\n", num++, frame->ToCString());
      frame = iterator.NextFrame();
    }
  }

  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Code& code = Code::Handle(zone);

  StackFrameIterator iterator(ValidationPolicy::kDontValidateFrames,
                              Thread::Current(),
                              StackFrameIterator::kNoCrossThreadIteration);
  intptr_t current_frame = 0;
  for (StackFrame* frame = iterator.NextFrame(); frame != NULL;
       frame = iterator.NextFrame()) {
    ASSERT(frame->IsValid());
    if (frame->IsDartFrame()) {
      code = frame->LookupDartCode();
      ASSERT(!code.is_optimized());
      if (current_frame == rewind_frame) {
        RewindToUnoptimizedFrame(frame, code);
        UNREACHABLE();
      }
      current_frame++;
    }
  }
}

// static
bool Debugger::IsDebuggable(const Function& func) {
  if (!func.is_debuggable()) {
    return false;
  }
  const Class& cls = Class::Handle(func.Owner());
  const Library& lib = Library::Handle(cls.library());
  return lib.IsDebuggable();
}

bool Debugger::IsDebugging(Thread* thread, const Function& func) {
  Debugger* debugger = thread->isolate()->debugger();
  return debugger->IsStepping() ||
         debugger->HasBreakpoint(func, thread->zone());
}

void Debugger::SignalPausedEvent(ActivationFrame* top_frame, Breakpoint* bpt) {
  resume_action_ = kContinue;
  ResetSteppingFramePointers();
  NotifySingleStepping(false);
  ASSERT(!IsPaused());
  if ((bpt != NULL) && bpt->IsSingleShot()) {
    RemoveBreakpoint(bpt->id());
    bpt = NULL;
  }

  ServiceEvent event(isolate_, ServiceEvent::kPauseBreakpoint);
  event.set_top_frame(top_frame);
  event.set_breakpoint(bpt);
  event.set_at_async_jump(IsAtAsyncJump(top_frame));
  Pause(&event);
}

bool Debugger::IsAtAsyncJump(ActivationFrame* top_frame) {
  Zone* zone = Thread::Current()->zone();
  Object& closure_or_null =
      Object::Handle(zone, top_frame->GetAsyncOperation());
  if (!closure_or_null.IsNull()) {
    ASSERT(top_frame->function().IsAsyncClosure() ||
           top_frame->function().IsAsyncGenClosure());
    ASSERT(closure_or_null.IsInstance());
    ASSERT(Instance::Cast(closure_or_null).IsClosure());
    const auto& pc_descriptors =
        PcDescriptors::Handle(zone, top_frame->code().pc_descriptors());
    if (pc_descriptors.IsNull()) {
      return false;
    }
    const TokenPosition looking_for = top_frame->TokenPos();
    PcDescriptors::Iterator it(pc_descriptors, PcDescriptorsLayout::kOther);
    while (it.MoveNext()) {
      if (it.TokenPos() == looking_for &&
          it.YieldIndex() != PcDescriptorsLayout::kInvalidYieldIndex) {
        return true;
      }
    }
  }
  return false;
}

ErrorPtr Debugger::PauseStepping() {
  ASSERT(isolate_->single_step());
  // Don't pause recursively.
  if (IsPaused()) {
    return Error::null();
  }
  if (skip_next_step_) {
    skip_next_step_ = false;
    return Error::null();
  }

  // Check whether we are in a Dart function that the user is
  // interested in. If we saved the frame pointer of a stack frame
  // the user is interested in, we ignore the single step if we are
  // in a callee of that frame. Note that we assume that the stack
  // grows towards lower addresses.
  ActivationFrame* frame = TopDartFrame();
  ASSERT(frame != NULL);

  if (FLAG_async_debugger) {
    if ((async_stepping_fp_ != 0) && (top_frame_awaiter_ != Object::null())) {
      // Check if the user has single stepped out of an async function with
      // an awaiter. The first check handles the case of calling into the
      // async machinery as we finish the async function. The second check
      // handles the case of returning from an async function.
      const ActivationFrame::Relation relation =
          frame->CompareTo(async_stepping_fp_);
      const bool exited_async_function =
          (relation == ActivationFrame::kCallee && frame->IsAsyncMachinery()) ||
          relation == ActivationFrame::kCaller;
      if (exited_async_function) {
        // Step to the top frame awaiter.
        const Object& async_op = Object::Handle(top_frame_awaiter_);
        top_frame_awaiter_ = Object::null();
        AsyncStepInto(Closure::Cast(async_op));
        return Error::null();
      }
    }
  }

  if (stepping_fp_ != 0) {
    // There is an "interesting frame" set. Only pause at appropriate
    // locations in this frame.
    const ActivationFrame::Relation relation = frame->CompareTo(stepping_fp_);
    if (relation == ActivationFrame::kCallee) {
      // We are in a callee of the frame we're interested in.
      // Ignore this stepping break.
      return Error::null();
    } else if (relation == ActivationFrame::kCaller) {
      // We returned from the "interesting frame", there can be no more
      // stepping breaks for it. Pause at the next appropriate location
      // and let the user set the "interesting" frame again.
      ResetSteppingFramePointers();
    }
  }

  // We need to manually set a synthetic breakpoint for async_op before entry.
  if (FLAG_lazy_async_stacks) {
    // async and async* functions always contain synthetic async_ops.
    if ((frame->function().IsAsyncFunction() ||
         frame->function().IsAsyncGenerator())) {
      ASSERT(!frame->GetSavedCurrentContext().IsNull());
      ASSERT(frame->GetSavedCurrentContext().num_variables() >
             Context::kAsyncFutureIndex);

      const Object& async_future = Object::Handle(
          frame->GetSavedCurrentContext().At(Context::kAsyncFutureIndex));

      // Only set breakpoint when entering async_op the first time.
      // :async_future should be uninitialised at this point:
      if (async_future.IsNull()) {
        const Function& async_op =
            Function::Handle(frame->function().GetGeneratedClosure());
        if (!async_op.IsNull()) {
          SetBreakpointAtAsyncOp(async_op);
          // After setting the breakpoint we stop stepping and continue the
          // debugger until the next breakpoint, to step over all the
          // synthetic code.
          Continue();
          return Error::null();
        }
      }
    }
  }

  if (!frame->IsDebuggable()) {
    return Error::null();
  }
  if (!frame->TokenPos().IsDebugPause()) {
    return Error::null();
  }

  if (frame->fp() == last_stepping_fp_ &&
      frame->TokenPos() == last_stepping_pos_) {
    // Do not stop multiple times for the same token position.
    // Several 'debug checked' opcodes may be issued in the same token range.
    return Error::null();
  }

  // We are stopping in this frame at the token pos.
  last_stepping_fp_ = frame->fp();
  last_stepping_pos_ = frame->TokenPos();

  // If there is an active breakpoint at this pc, then we should have
  // already bailed out of this function in the skip_next_step_ test
  // above.
  ASSERT(!HasActiveBreakpoint(frame->pc()));

  if (FLAG_verbose_debug) {
    OS::PrintErr(">>> single step break at %s:%" Pd ":%" Pd
                 " (func %s token %s address %#" Px " offset %#" Px ")\n",
                 String::Handle(frame->SourceUrl()).ToCString(),
                 frame->LineNumber(), frame->ColumnNumber(),
                 String::Handle(frame->QualifiedFunctionName()).ToCString(),
                 frame->TokenPos().ToCString(), frame->pc(),
                 frame->pc() - frame->code().PayloadStart());
  }

  CacheStackTraces(CollectStackTrace(), CollectAsyncCausalStackTrace(),
                   CollectAwaiterReturnStackTrace());
  if (SteppedForSyntheticAsyncBreakpoint()) {
    CleanupSyntheticAsyncBreakpoint();
  }
  SignalPausedEvent(frame, NULL);
  HandleSteppingRequest(stack_trace_);
  ClearCachedStackTraces();

  // If any error occurred while in the debug message loop, return it here.
  return Thread::Current()->StealStickyError();
}

ErrorPtr Debugger::PauseBreakpoint() {
  // We ignore this breakpoint when the VM is executing code invoked
  // by the debugger to evaluate variables values, or when we see a nested
  // breakpoint or exception event.
  if (ignore_breakpoints_ || IsPaused()) {
    return Error::null();
  }
  DebuggerStackTrace* stack_trace = CollectStackTrace();
  ASSERT(stack_trace->Length() > 0);
  ActivationFrame* top_frame = stack_trace->FrameAt(0);
  ASSERT(top_frame != NULL);
  CodeBreakpoint* cbpt = GetCodeBreakpoint(top_frame->pc());
  ASSERT(cbpt != NULL);

  if (!Library::Handle(top_frame->Library()).IsDebuggable()) {
    return Error::null();
  }

  Breakpoint* bpt_hit = FindHitBreakpoint(cbpt->bpt_location_, top_frame);
  if (bpt_hit == NULL) {
    return Error::null();
  }

  if (bpt_hit->is_synthetic_async()) {
    DebuggerStackTrace* stack_trace = CollectStackTrace();
    ASSERT(stack_trace->Length() > 0);
    CacheStackTraces(stack_trace, CollectAsyncCausalStackTrace(),
                     CollectAwaiterReturnStackTrace());

    // Hit a synthetic async breakpoint.
    if (FLAG_verbose_debug) {
      OS::PrintErr(
          ">>> hit synthetic breakpoint at %s:%" Pd
          " (func %s token %s address %#" Px " offset %#" Px ")\n",
          String::Handle(cbpt->SourceUrl()).ToCString(), cbpt->LineNumber(),
          String::Handle(top_frame->QualifiedFunctionName()).ToCString(),
          cbpt->token_pos().ToCString(), top_frame->pc(),
          top_frame->pc() - top_frame->code().PayloadStart());
    }

    ASSERT(synthetic_async_breakpoint_ == NULL);
    synthetic_async_breakpoint_ = bpt_hit;
    bpt_hit = NULL;

    // We are at the entry of an async function.
    // We issue a step over to resume at the point after the await statement.
    SetResumeAction(kStepOver);
    // When we single step from a user breakpoint, our next stepping
    // point will be at the exact same pc.  Skip it.
    HandleSteppingRequest(stack_trace_, true /* skip next step */);
    ClearCachedStackTraces();
    return Error::null();
  }

  if (FLAG_verbose_debug) {
    OS::PrintErr(">>> hit breakpoint %" Pd " at %s:%" Pd
                 " (func %s token %s address %#" Px " offset %#" Px ")\n",
                 bpt_hit->id(), String::Handle(cbpt->SourceUrl()).ToCString(),
                 cbpt->LineNumber(),
                 String::Handle(top_frame->QualifiedFunctionName()).ToCString(),
                 cbpt->token_pos().ToCString(), top_frame->pc(),
                 top_frame->pc() - top_frame->code().PayloadStart());
  }

  CacheStackTraces(stack_trace, CollectAsyncCausalStackTrace(),
                   CollectAwaiterReturnStackTrace());
  SignalPausedEvent(top_frame, bpt_hit);
  // When we single step from a user breakpoint, our next stepping
  // point will be at the exact same pc.  Skip it.
  HandleSteppingRequest(stack_trace_, true /* skip next step */);
  ClearCachedStackTraces();

  // If any error occurred while in the debug message loop, return it here.
  return Thread::Current()->StealStickyError();
}

Breakpoint* Debugger::FindHitBreakpoint(BreakpointLocation* location,
                                        ActivationFrame* top_frame) {
  if (location == NULL) {
    return NULL;
  }
  // There may be more than one applicable breakpoint at this location, but we
  // will report only one as reached. If there is a single-shot breakpoint, we
  // favor it; then a closure-specific breakpoint ; then an general breakpoint.

  // First check for a single-shot breakpoint.
  Breakpoint* bpt = location->breakpoints();
  while (bpt != NULL) {
    if (bpt->IsSingleShot()) {
      return bpt;
    }
    bpt = bpt->next();
  }

  // Now check for a closure-specific breakpoint.
  bpt = location->breakpoints();
  while (bpt != NULL) {
    if (bpt->IsPerClosure()) {
      Object& closure = Object::Handle(top_frame->GetClosure());
      ASSERT(closure.IsInstance());
      ASSERT(Instance::Cast(closure).IsClosure());
      if (closure.raw() == bpt->closure()) {
        return bpt;
      }
    }
    bpt = bpt->next();
  }

  // Finally, check for a general breakpoint.
  bpt = location->breakpoints();
  while (bpt != NULL) {
    if (bpt->IsRepeated()) {
      return bpt;
    }
    bpt = bpt->next();
  }

  return NULL;
}

void Debugger::PauseDeveloper(const String& msg) {
  // We ignore this breakpoint when the VM is executing code invoked
  // by the debugger to evaluate variables values, or when we see a nested
  // breakpoint or exception event.
  if (ignore_breakpoints_ || IsPaused()) {
    return;
  }

  DebuggerStackTrace* stack_trace = CollectStackTrace();
  ASSERT(stack_trace->Length() > 0);
  CacheStackTraces(stack_trace, CollectAsyncCausalStackTrace(),
                   CollectAwaiterReturnStackTrace());
  // TODO(johnmccutchan): Send |msg| to Observatory.

  // We are in the native call to Developer_debugger.  the developer
  // gets a better experience by not seeing this call. To accomplish
  // this, we continue execution until the call exits (step out).
  SetResumeAction(kStepOut);
  HandleSteppingRequest(stack_trace_);
  ClearCachedStackTraces();
}

void Debugger::NotifyIsolateCreated() {
  if (NeedsIsolateEvents()) {
    ServiceEvent event(isolate_, ServiceEvent::kIsolateStart);
    InvokeEventHandler(&event);
  }
}

// Return innermost closure contained in 'function' that contains
// the given token position.
FunctionPtr Debugger::FindInnermostClosure(const Function& function,
                                           TokenPosition token_pos) {
  ASSERT(function.end_token_pos().IsReal());
  const TokenPosition& func_start = function.token_pos();
  Zone* zone = Thread::Current()->zone();
  const Script& outer_origin = Script::Handle(zone, function.script());
  const GrowableObjectArray& closures = GrowableObjectArray::Handle(
      zone, Isolate::Current()->object_store()->closure_functions());
  const intptr_t num_closures = closures.Length();
  Function& closure = Function::Handle(zone);
  Function& best_fit = Function::Handle(zone);
  for (intptr_t i = 0; i < num_closures; i++) {
    closure ^= closures.At(i);
    const TokenPosition& closure_start = closure.token_pos();
    const TokenPosition& closure_end = closure.end_token_pos();
    // We're only interested in closures that have real ending token positions.
    // The starting token position can be synthetic.
    if (closure_end.IsReal() && (function.end_token_pos() > closure_end) &&
        (!closure_start.IsReal() || !func_start.IsReal() ||
         (closure_start > func_start)) &&
        token_pos.IsWithin(closure_start, closure_end) &&
        (closure.script() == outer_origin.raw())) {
      UpdateBestFit(&best_fit, closure);
    }
  }
  return best_fit.raw();
}

#if !defined(DART_PRECOMPILED_RUNTIME)
// On single line of code with given column number,
// Calculate exact tokenPosition
TokenPosition Debugger::FindExactTokenPosition(const Script& script,
                                               TokenPosition start_of_line,
                                               intptr_t column_number) {
  intptr_t line;
  intptr_t col;
  if (script.GetTokenLocation(start_of_line, &line, &col)) {
    return TokenPosition::Deserialize(start_of_line.Pos() +
                                      (column_number - col));
  }
  return TokenPosition::kNoSource;
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

void Debugger::NotifyCompilation(const Function& func) {
  if (breakpoint_locations_ == NULL) {
    // Return with minimal overhead if there are no breakpoints.
    return;
  }
  if (!func.is_debuggable()) {
    // Nothing to do if the function is not debuggable. If there is
    // a pending breakpoint in an inner function (that is debuggable),
    // we'll resolve the breakpoint when the inner function is compiled.
    return;
  }
  // Iterate over all source breakpoints to check whether breakpoints
  // need to be set in the newly compiled function.
  Zone* zone = Thread::Current()->zone();
  Script& script = Script::Handle(zone);
  for (BreakpointLocation* loc = breakpoint_locations_; loc != NULL;
       loc = loc->next()) {
    script = loc->script();
    if (FunctionOverlaps(func, script, loc->token_pos(),
                         loc->end_token_pos())) {
      TokenPosition token_pos = loc->token_pos();
      TokenPosition end_token_pos = loc->end_token_pos();
      if (token_pos != end_token_pos && loc->requested_column_number() >= 0) {
#if !defined(DART_PRECOMPILED_RUNTIME)
        // Narrow down the token position range to a single value
        // if requested column number is provided so that inner
        // Closure won't be missed.
        token_pos = FindExactTokenPosition(script, token_pos,
                                           loc->requested_column_number());
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
      }
      const Function& inner_function =
          Function::Handle(zone, FindInnermostClosure(func, token_pos));
      if (!inner_function.IsNull()) {
        if (FLAG_verbose_debug) {
          OS::PrintErr(
              "Pending breakpoint remains unresolved in "
              "inner function '%s'\n",
              inner_function.ToFullyQualifiedCString());
        }
        continue;
      }

      // There is no local function within func that contains the
      // breakpoint token position. Resolve the breakpoint if necessary
      // and set the code breakpoints.
      if (!loc->IsResolved()) {
        // Resolve source breakpoint in the newly compiled function.
        TokenPosition bp_pos =
            ResolveBreakpointPos(func, loc->token_pos(), loc->end_token_pos(),
                                 loc->requested_column_number(), token_pos);
        if (!bp_pos.IsDebugPause()) {
          if (FLAG_verbose_debug) {
            OS::PrintErr("Failed resolving breakpoint for function '%s'\n",
                         func.ToFullyQualifiedCString());
          }
          continue;
        }
        TokenPosition requested_pos = loc->token_pos();
        TokenPosition requested_end_pos = loc->end_token_pos();
        loc->SetResolved(func, bp_pos);
        Breakpoint* bpt = loc->breakpoints();
        while (bpt != NULL) {
          if (FLAG_verbose_debug) {
            OS::PrintErr(
                "Resolved breakpoint %" Pd
                " to pos %s, function '%s' (requested range %s-%s, "
                "requested col %" Pd ")\n",
                bpt->id(), loc->token_pos().ToCString(),
                func.ToFullyQualifiedCString(), requested_pos.ToCString(),
                requested_end_pos.ToCString(), loc->requested_column_number());
          }
          SendBreakpointEvent(ServiceEvent::kBreakpointResolved, bpt);
          bpt = bpt->next();
        }
      }
      ASSERT(loc->IsResolved());
      if (FLAG_verbose_debug) {
        Breakpoint* bpt = loc->breakpoints();
        while (bpt != NULL) {
          OS::PrintErr("Setting breakpoint %" Pd " for %s '%s'\n", bpt->id(),
                       func.IsClosureFunction() ? "closure" : "function",
                       func.ToFullyQualifiedCString());
          bpt = bpt->next();
        }
      }
      MakeCodeBreakpointAt(func, loc);
    }
  }
}

void Debugger::NotifyDoneLoading() {
  if (latent_locations_ == NULL) {
    // Common, fast path.
    return;
  }
  Zone* zone = Thread::Current()->zone();
  Library& lib = Library::Handle(zone);
  Script& script = Script::Handle(zone);
  String& url = String::Handle(zone);
  BreakpointLocation* loc = latent_locations_;
  BreakpointLocation* prev_loc = NULL;
  const GrowableObjectArray& libs =
      GrowableObjectArray::Handle(isolate_->object_store()->libraries());
  while (loc != NULL) {
    url = loc->url();
    bool found_match = false;
    bool is_package = url.StartsWith(Symbols::PackageScheme());
    for (intptr_t i = 0; i < libs.Length(); i++) {
      lib ^= libs.At(i);
      script = lib.LookupScript(url, !is_package);
      if (!script.IsNull()) {
        // Found a script with matching url for this latent breakpoint.
        // Unlink the latent breakpoint from the list.
        found_match = true;
        BreakpointLocation* matched_loc = loc;
        loc = loc->next();
        if (prev_loc == NULL) {
          latent_locations_ = loc;
        } else {
          prev_loc->set_next(loc);
        }
        // Now find the token range at the requested line and make a
        // new unresolved source breakpoint.
        intptr_t line_number = matched_loc->requested_line_number();
        intptr_t column_number = matched_loc->requested_column_number();
        ASSERT(line_number >= 0);
        TokenPosition first_token_pos = TokenPosition::kNoSource;
        TokenPosition last_token_pos = TokenPosition::kNoSource;
        script.TokenRangeAtLine(line_number, &first_token_pos, &last_token_pos);
        if (!first_token_pos.IsDebugPause() || !last_token_pos.IsDebugPause()) {
          // Script does not contain the given line number or there are no
          // tokens on the line. Drop the breakpoint silently.
          Breakpoint* bpt = matched_loc->breakpoints();
          while (bpt != NULL) {
            if (FLAG_verbose_debug) {
              OS::PrintErr("No code found at line %" Pd
                           ": "
                           "dropping latent breakpoint %" Pd " in '%s'\n",
                           line_number, bpt->id(), url.ToCString());
            }
            Breakpoint* prev = bpt;
            bpt = bpt->next();
            delete prev;
          }
          delete matched_loc;
        } else {
          // We don't expect to already have a breakpoint for this location.
          // If there is one, assert in debug build but silently drop
          // the latent breakpoint in release build.
          BreakpointLocation* existing_loc =
              GetBreakpointLocation(script, first_token_pos, -1, column_number);
          ASSERT(existing_loc == NULL);
          if (existing_loc == NULL) {
            // Create and register a new source breakpoint for the
            // latent breakpoint.
            BreakpointLocation* unresolved_loc =
                new BreakpointLocation(script, first_token_pos, last_token_pos,
                                       line_number, column_number);
            RegisterBreakpointLocation(unresolved_loc);

            // Move breakpoints over.
            Breakpoint* bpt = matched_loc->breakpoints();
            unresolved_loc->set_breakpoints(bpt);
            matched_loc->set_breakpoints(NULL);
            while (bpt != NULL) {
              bpt->set_bpt_location(unresolved_loc);
              if (FLAG_verbose_debug) {
                OS::PrintErr(
                    "Converted latent breakpoint "
                    "%" Pd " in '%s' at line %" Pd " col %" Pd "\n",
                    bpt->id(), url.ToCString(), line_number, column_number);
              }
              bpt = bpt->next();
            }
            SyncBreakpointLocation(unresolved_loc);
          }
          delete matched_loc;
          // Break out of the iteration over loaded libraries. If the
          // same url has been loaded into more than one library, we
          // only set a breakpoint in the first one.
          // TODO(hausner): There is one possible pitfall here.
          // If the user sets a latent breakpoint using a partial url that
          // ends up matching more than one script, the breakpoint might
          // get set in the wrong script.
          // It would be better if we could warn the user if multiple
          // scripts are matching.
          break;
        }
      }
    }
    if (!found_match) {
      // No matching url found in any of the libraries.
      if (FLAG_verbose_debug) {
        Breakpoint* bpt = loc->breakpoints();
        while (bpt != NULL) {
          OS::PrintErr(
              "No match found for latent breakpoint id "
              "%" Pd " with url '%s'\n",
              bpt->id(), url.ToCString());
          bpt = bpt->next();
        }
      }
      loc = loc->next();
    }
  }
}

// TODO(hausner): Could potentially make this faster by checking
// whether the call target at pc is a debugger stub.
bool Debugger::HasActiveBreakpoint(uword pc) {
  CodeBreakpoint* cbpt = GetCodeBreakpoint(pc);
  return (cbpt != NULL) && (cbpt->IsEnabled());
}

CodeBreakpoint* Debugger::GetCodeBreakpoint(uword breakpoint_address) {
  CodeBreakpoint* cbpt = code_breakpoints_;
  while (cbpt != NULL) {
    if (cbpt->pc() == breakpoint_address) {
      return cbpt;
    }
    cbpt = cbpt->next();
  }
  return NULL;
}

CodePtr Debugger::GetPatchedStubAddress(uword breakpoint_address) {
  CodeBreakpoint* cbpt = GetCodeBreakpoint(breakpoint_address);
  if (cbpt != NULL) {
    return cbpt->OrigStubAddress();
  }
  UNREACHABLE();
  return Code::null();
}

// Remove and delete the source breakpoint bpt and its associated
// code breakpoints.
void Debugger::RemoveBreakpoint(intptr_t bp_id) {
  if (RemoveBreakpointFromTheList(bp_id, &breakpoint_locations_)) {
    return;
  }
  RemoveBreakpointFromTheList(bp_id, &latent_locations_);
}

// Remove and delete the source breakpoint bpt and its associated
// code breakpoints. Returns true, if breakpoint was found and removed,
// returns false, if breakpoint was not found.
bool Debugger::RemoveBreakpointFromTheList(intptr_t bp_id,
                                           BreakpointLocation** list) {
  BreakpointLocation* prev_loc = NULL;
  BreakpointLocation* curr_loc = *list;
  while (curr_loc != NULL) {
    Breakpoint* prev_bpt = NULL;
    Breakpoint* curr_bpt = curr_loc->breakpoints();
    while (curr_bpt != NULL) {
      if (curr_bpt->id() == bp_id) {
        if (prev_bpt == NULL) {
          curr_loc->set_breakpoints(curr_bpt->next());
        } else {
          prev_bpt->set_next(curr_bpt->next());
        }

        // Send event to client before the breakpoint's fields are
        // poisoned and deleted.
        SendBreakpointEvent(ServiceEvent::kBreakpointRemoved, curr_bpt);

        curr_bpt->set_next(NULL);
        curr_bpt->set_bpt_location(NULL);
        // Remove possible references to the breakpoint.
        if (pause_event_ != NULL && pause_event_->breakpoint() == curr_bpt) {
          pause_event_->set_breakpoint(NULL);
        }
        if (synthetic_async_breakpoint_ == curr_bpt) {
          synthetic_async_breakpoint_ = NULL;
        }
        delete curr_bpt;
        curr_bpt = NULL;

        // Delete the breakpoint location object if there are no more
        // breakpoints at that location.
        if (curr_loc->breakpoints() == NULL) {
          if (prev_loc == NULL) {
            *list = curr_loc->next();
          } else {
            prev_loc->set_next(curr_loc->next());
          }

          if (!curr_loc->IsLatent()) {
            // Remove references from code breakpoints to this breakpoint
            // location and disable them.
            // Latent breakpoint locations won't have code breakpoints.
            UnlinkCodeBreakpoints(curr_loc);
          }
          BreakpointLocation* next_loc = curr_loc->next();
          delete curr_loc;
          curr_loc = next_loc;
        }

        // The code breakpoints will be deleted when the VM resumes
        // after the pause event.
        return true;
      }

      prev_bpt = curr_bpt;
      curr_bpt = curr_bpt->next();
    }
    prev_loc = curr_loc;
    curr_loc = curr_loc->next();
  }
  // breakpoint with bp_id does not exist, nothing to do.
  return false;
}

// Unlink code breakpoints from the given breakpoint location.
// They will later be deleted when control returns from the pause event
// callback. Also, disable the breakpoint so it no longer fires if it
// should be hit before it gets deleted.
void Debugger::UnlinkCodeBreakpoints(BreakpointLocation* bpt_location) {
  ASSERT(bpt_location != NULL);
  CodeBreakpoint* curr_bpt = code_breakpoints_;
  while (curr_bpt != NULL) {
    if (curr_bpt->bpt_location() == bpt_location) {
      curr_bpt->Disable();
      curr_bpt->set_bpt_location(NULL);
      needs_breakpoint_cleanup_ = true;
    }
    curr_bpt = curr_bpt->next();
  }
}

// Remove and delete unlinked code breakpoints, i.e. breakpoints that
// are not associated with a breakpoint location.
void Debugger::RemoveUnlinkedCodeBreakpoints() {
  CodeBreakpoint* prev_bpt = NULL;
  CodeBreakpoint* curr_bpt = code_breakpoints_;
  while (curr_bpt != NULL) {
    if (curr_bpt->bpt_location() == NULL) {
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
  needs_breakpoint_cleanup_ = false;
}

BreakpointLocation* Debugger::GetBreakpointLocation(
    const Script& script,
    TokenPosition token_pos,
    intptr_t requested_line,
    intptr_t requested_column,
    TokenPosition code_token_pos) {
  BreakpointLocation* loc = breakpoint_locations_;
  while (loc != NULL) {
    if (loc->script_ == script.raw() &&
        (!token_pos.IsReal() || (loc->token_pos_ == token_pos)) &&
        ((requested_line == -1) ||
         (loc->requested_line_number_ == requested_line)) &&
        ((requested_column == -1) ||
         (loc->requested_column_number_ == requested_column)) &&
        (!code_token_pos.IsReal() ||
         (loc->code_token_pos_ == code_token_pos))) {
      return loc;
    }
    loc = loc->next();
  }
  return NULL;
}

Breakpoint* Debugger::GetBreakpointById(intptr_t id) {
  Breakpoint* bpt = GetBreakpointByIdInTheList(id, breakpoint_locations_);
  if (bpt != NULL) {
    return bpt;
  }
  return GetBreakpointByIdInTheList(id, latent_locations_);
}

Breakpoint* Debugger::GetBreakpointByIdInTheList(intptr_t id,
                                                 BreakpointLocation* list) {
  BreakpointLocation* loc = list;
  while (loc != NULL) {
    Breakpoint* bpt = loc->breakpoints();
    while (bpt != NULL) {
      if (bpt->id() == id) {
        return bpt;
      }
      bpt = bpt->next();
    }
    loc = loc->next();
  }
  return NULL;
}

void Debugger::MaybeAsyncStepInto(const Closure& async_op) {
  if (FLAG_async_debugger && IsSingleStepping()) {
    // We are single stepping, set a breakpoint on the closure activation
    // and resume execution so we can hit the breakpoint.
    AsyncStepInto(async_op);
  }
}

void Debugger::AsyncStepInto(const Closure& async_op) {
  SetBreakpointAtActivation(async_op, true);
  Continue();
}

void Debugger::Continue() {
  SetResumeAction(kContinue);
  ResetSteppingFramePointers();
  NotifySingleStepping(false);
}

BreakpointLocation* Debugger::GetLatentBreakpoint(const String& url,
                                                  intptr_t line,
                                                  intptr_t column) {
  BreakpointLocation* loc = latent_locations_;
  String& bpt_url = String::Handle();
  while (loc != NULL) {
    bpt_url = loc->url();
    if (bpt_url.Equals(url) && (loc->requested_line_number() == line) &&
        (loc->requested_column_number() == column)) {
      return loc;
    }
    loc = loc->next();
  }
  // No breakpoint for this location requested. Allocate new one.
  loc = new BreakpointLocation(url, line, column);
  loc->set_next(latent_locations_);
  latent_locations_ = loc;
  return loc;
}

void Debugger::RegisterBreakpointLocation(BreakpointLocation* loc) {
  ASSERT(loc->next() == NULL);
  loc->set_next(breakpoint_locations_);
  breakpoint_locations_ = loc;
}

void Debugger::RegisterCodeBreakpoint(CodeBreakpoint* cbpt) {
  ASSERT(cbpt->next() == NULL);
  cbpt->set_next(code_breakpoints_);
  code_breakpoints_ = cbpt;
}

#endif  // !PRODUCT

}  // namespace dart
