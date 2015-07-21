// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/debugger.h"

#include "include/dart_api.h"

#include "vm/code_generator.h"
#include "vm/code_patcher.h"
#include "vm/compiler.h"
#include "vm/dart_entry.h"
#include "vm/deopt_instructions.h"
#include "vm/flags.h"
#include "vm/globals.h"
#include "vm/longjump.h"
#include "vm/json_stream.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/os.h"
#include "vm/port.h"
#include "vm/service_event.h"
#include "vm/service_isolate.h"
#include "vm/service.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"
#include "vm/thread_interrupter.h"
#include "vm/visitor.h"


namespace dart {

DEFINE_FLAG(bool, show_invisible_frames, false,
            "Show invisible frames in debugger stack traces");
DEFINE_FLAG(bool, trace_debugger_stacktrace, false,
            "Trace debugger stacktrace collection");
DEFINE_FLAG(bool, verbose_debug, false, "Verbose debugger messages");
DEFINE_FLAG(bool, steal_breakpoints, false,
            "Intercept breakpoints and other pause events before they "
            "are sent to the embedder and use a generic VM breakpoint "
            "handler instead.  This handler dispatches breakpoints to "
            "the VM service.");


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


// Create an unresolved breakpoint in given token range and script.
BreakpointLocation::BreakpointLocation(const Script& script,
                                       intptr_t token_pos,
                                       intptr_t end_token_pos)
    : script_(script.raw()),
      url_(script.url()),
      token_pos_(token_pos),
      end_token_pos_(end_token_pos),
      is_resolved_(false),
      next_(NULL),
      conditions_(NULL),
      function_(Function::null()),
      line_number_(-1) {
  ASSERT(!script.IsNull());
  ASSERT(token_pos_ >= 0);
}

// Create a latent breakpoint at given url and line number.
BreakpointLocation::BreakpointLocation(const String& url,
                                       intptr_t line_number)
    : script_(Script::null()),
      url_(url.raw()),
      token_pos_(-1),
      end_token_pos_(-1),
      is_resolved_(false),
      next_(NULL),
      conditions_(NULL),
      function_(Function::null()),
      line_number_(line_number) {
  ASSERT(line_number_ >= 0);
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


void BreakpointLocation::SetResolved(const Function& func, intptr_t token_pos) {
  ASSERT(!IsLatent());
  ASSERT(func.script() == script_);
  ASSERT((func.token_pos() <= token_pos) &&
         (token_pos <= func.end_token_pos()));
  ASSERT(func.is_debuggable());
  function_ = func.raw();
  token_pos_ = token_pos;
  end_token_pos_ = token_pos;
  line_number_ = -1;  // Recalculate lazily.
  is_resolved_ = true;
}


// TODO(hausner): Get rid of library parameter. A source breakpoint location
// does not imply a library, since the same source code can be included
// in more than one library, e.g. the text location of mixin functions.
void BreakpointLocation::GetCodeLocation(Library* lib,
                                         Script* script,
                                         intptr_t* pos) {
  if (IsLatent()) {
    *lib = Library::null();
    *script = Script::null();
    *pos = -1;
  } else {
    *script = this->script();
    *pos = token_pos_;
    if (IsResolved()) {
      const Function& func = Function::Handle(function_);
      ASSERT(!func.IsNull());
      const Class& cls = Class::Handle(func.origin());
      *lib = cls.library();
    } else {
      *lib = Library::null();
    }
  }
}


intptr_t BreakpointLocation::LineNumber() {
  // Latent breakpoints must have a requested line number >= 0.
  ASSERT(!IsLatent() || line_number_ >= 0);
  // Compute line number lazily since it causes scanning of the script.
  if (line_number_ < 0) {
    const Script& script = Script::Handle(this->script());
    script.GetTokenLocation(token_pos_, &line_number_, NULL);
  }
  return line_number_;
}


void Breakpoint::set_bpt_location(BreakpointLocation* new_bpt_location) {
  ASSERT(bpt_location_->IsLatent());  // Only reason to move.
  bpt_location_ = new_bpt_location;
}


void Breakpoint::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  visitor->VisitPointer(reinterpret_cast<RawObject**>(&closure_));
}


void BreakpointLocation::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  visitor->VisitPointer(reinterpret_cast<RawObject**>(&script_));
  visitor->VisitPointer(reinterpret_cast<RawObject**>(&url_));
  visitor->VisitPointer(reinterpret_cast<RawObject**>(&function_));

  Breakpoint* bpt = conditions_;
  while (bpt != NULL) {
    bpt -> VisitObjectPointers(visitor);
    bpt = bpt->next();
  }
}


void Breakpoint::PrintJSON(JSONStream* stream) {
  Isolate* isolate = Isolate::Current();

  JSONObject jsobj(stream);
  jsobj.AddProperty("type", "Breakpoint");

  jsobj.AddFixedServiceId("breakpoints/%" Pd "", id());
  jsobj.AddProperty("breakpointNumber", id());
  jsobj.AddProperty("resolved", bpt_location_->IsResolved());

  Library& library = Library::Handle(isolate);
  Script& script = Script::Handle(isolate);
  intptr_t token_pos;
  bpt_location_->GetCodeLocation(&library, &script, &token_pos);
  jsobj.AddLocation(script, token_pos);
}


void CodeBreakpoint::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  visitor->VisitPointer(reinterpret_cast<RawObject**>(&code_));
}


ActivationFrame::ActivationFrame(
    uword pc,
    uword fp,
    uword sp,
    const Code& code,
    const Array& deopt_frame,
    intptr_t deopt_frame_offset)
    : pc_(pc), fp_(fp), sp_(sp),
      ctx_(Context::ZoneHandle()),
      code_(Code::ZoneHandle(code.raw())),
      function_(Function::ZoneHandle(code.function())),
      token_pos_initialized_(false),
      token_pos_(-1),
      try_index_(-1),
      line_number_(-1),
      column_number_(-1),
      context_level_(-1),
      deopt_frame_(Array::ZoneHandle(deopt_frame.raw())),
      deopt_frame_offset_(deopt_frame_offset),
      vars_initialized_(false),
      var_descriptors_(LocalVarDescriptors::ZoneHandle()),
      desc_indices_(8),
      pc_desc_(PcDescriptors::ZoneHandle()) {
}


bool Debugger::HasEventHandler() {
  return ((event_handler_ != NULL) ||
          Service::isolate_stream.enabled() ||
          Service::debug_stream.enabled());
}


static bool ServiceNeedsDebuggerEvent(DebuggerEvent::EventType type) {
  switch (type) {
    case DebuggerEvent::kBreakpointResolved:
      // kBreakpointResolved events are handled differently in the vm
      // service, so suppress them here.
      return false;

    case DebuggerEvent::kBreakpointReached:
    case DebuggerEvent::kExceptionThrown:
    case DebuggerEvent::kIsolateInterrupted:
      return Service::debug_stream.enabled();

    case DebuggerEvent::kIsolateCreated:
    case DebuggerEvent::kIsolateShutdown:
      return Service::isolate_stream.enabled();

    default:
      UNREACHABLE();
      return false;
  }
}


void Debugger::InvokeEventHandler(DebuggerEvent* event) {
  ASSERT(HasEventHandler());

  // Give the event to the Service first, as the debugger event handler
  // may go into a message loop and the Service will not.
  //
  // kBreakpointResolved events are handled differently in the vm
  // service, so suppress them here.
  if (ServiceNeedsDebuggerEvent(event->type())) {
    ServiceEvent service_event(event);
    Service::HandleEvent(&service_event);
  }

  if (FLAG_steal_breakpoints && event->IsPauseEvent()) {
    // We allow the embedder's default breakpoint handler to be overridden.
    isolate_->PauseEventHandler();
  } else if (event_handler_ != NULL) {
    (*event_handler_)(event);
  }

  if (ServiceNeedsDebuggerEvent(event->type()) && event->IsPauseEvent()) {
    // If we were paused, notify the service that we have resumed.
    ServiceEvent service_event(event->isolate(), ServiceEvent::kResume);
    service_event.set_top_frame(event->top_frame());
    Service::HandleEvent(&service_event);
  }
}


void Debugger::SignalIsolateEvent(DebuggerEvent::EventType type) {
  if (HasEventHandler()) {
    DebuggerEvent event(isolate_, type);
    ASSERT(event.isolate_id() != ILLEGAL_ISOLATE_ID);
    if (type == DebuggerEvent::kIsolateInterrupted) {
      DebuggerStackTrace* trace = CollectStackTrace();
      ASSERT(trace->Length() > 0);
      event.set_top_frame(trace->FrameAt(0));
      ASSERT(stack_trace_ == NULL);
      stack_trace_ = trace;
      resume_action_ = kContinue;
      Pause(&event);
      HandleSteppingRequest(trace);
      stack_trace_ = NULL;
    } else {
      InvokeEventHandler(&event);
    }
  }
}


void Debugger::SignalIsolateInterrupted() {
  if (HasEventHandler()) {
    Debugger* debugger = Isolate::Current()->debugger();
    debugger->SignalIsolateEvent(DebuggerEvent::kIsolateInterrupted);
  }
}


// The vm service handles breakpoint notifications in a different way
// than the regular debugger breakpoint notifications.
static void SendServiceBreakpointEvent(ServiceEvent::EventKind kind,
                                       Breakpoint* bpt) {
  if (Service::debug_stream.enabled()) {
    ServiceEvent service_event(Isolate::Current(), kind);
    service_event.set_breakpoint(bpt);
    Service::HandleEvent(&service_event);
  }
}


void BreakpointLocation::AddBreakpoint(Breakpoint* bpt, Debugger* dbg) {
  bpt->set_next(breakpoints());
  set_breakpoints(bpt);

  dbg->SyncBreakpointLocation(this);

  if (IsResolved()) {
    dbg->SignalBpResolved(bpt);
  }
  SendServiceBreakpointEvent(ServiceEvent::kBreakpointAdded, bpt);
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
                                              const Instance& closure) {
  Breakpoint* bpt = breakpoints();
  while (bpt != NULL) {
    if (bpt->IsPerClosure() && bpt->closure() == closure.raw()) break;
    bpt = bpt->next();
  }
  if (bpt == NULL) {
    bpt = new Breakpoint(dbg->nextId(), this);
    bpt->SetIsPerClosure(closure);
    AddBreakpoint(bpt, dbg);
  }
  return bpt;
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
  char* chars = Thread::Current()->zone()->Alloc<char>(len);
  OS::SNPrint(chars, len, kFormat,
              func_class.IsTopLevel() ? "" : class_name.ToCString(),
              func_class.IsTopLevel() ? "" : ".",
              func_name.ToCString());
  return chars;
}


// Returns true if function contains the token position in the given script.
static bool FunctionContains(const Function& func,
                             const Script& script,
                             intptr_t token_pos) {
  if ((func.token_pos() <= token_pos) && (token_pos <= func.end_token_pos())) {
    // Check script equality second because it allocates
    // handles as a side effect.
    return func.script() == script.raw();
  }
  return false;
}


bool Debugger::HasBreakpoint(const Function& func) {
  if (!func.HasCode()) {
    // If the function is not compiled yet, just check whether there
    // is a user-defined breakpoint that falls into the token
    // range of the function. This may be a false positive: the breakpoint
    // might be inside a local closure.
    Script& script = Script::Handle(isolate_);
    BreakpointLocation* sbpt = breakpoint_locations_;
    while (sbpt != NULL) {
      script = sbpt->script();
      if (FunctionContains(func, script, sbpt->token_pos())) {
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
  BreakpointLocation* sbpt = breakpoint_locations_;
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
  const Class& cls = Class::Handle(function().origin());
  return cls.library();
}


void ActivationFrame::GetPcDescriptors() {
  if (pc_desc_.IsNull()) {
    pc_desc_ = code().pc_descriptors();
    ASSERT(!pc_desc_.IsNull());
  }
}


// Compute token_pos_ and try_index_ and token_pos_initialized_.
intptr_t ActivationFrame::TokenPos() {
  if (!token_pos_initialized_) {
    token_pos_initialized_ = true;
    token_pos_ = Scanner::kNoSourcePos;
    GetPcDescriptors();
    PcDescriptors::Iterator iter(pc_desc_, RawPcDescriptors::kAnyKind);
    uword pc_offset = pc_ - code().EntryPoint();
    while (iter.MoveNext()) {
      if (iter.PcOffset() == pc_offset) {
        try_index_ = iter.TryIndex();
        token_pos_ = iter.TokenPos();
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


intptr_t ActivationFrame::LineNumber() {
  // Compute line number lazily since it causes scanning of the script.
  if ((line_number_ < 0) && (TokenPos() >= 0)) {
    const Script& script = Script::Handle(SourceScript());
    script.GetTokenLocation(TokenPos(), &line_number_, NULL);
  }
  return line_number_;
}


intptr_t ActivationFrame::ColumnNumber() {
  // Compute column number lazily since it causes scanning of the script.
  if ((column_number_ < 0) && (TokenPos() >= 0)) {
    const Script& script = Script::Handle(SourceScript());
    if (script.HasSource()) {
      script.GetTokenLocation(TokenPos(), &line_number_, &column_number_);
    } else {
      column_number_ = -1;
    }
  }
  return column_number_;
}


void ActivationFrame::GetVarDescriptors() {
  if (var_descriptors_.IsNull()) {
    if (code().is_optimized()) {
      Thread* thread = Thread::Current();
      Zone* zone = thread->zone();
      const Error& error = Error::Handle(zone,
          Compiler::EnsureUnoptimizedCode(thread, function()));
      if (!error.IsNull()) {
        Exceptions::PropagateError(error);
      }
    }
    var_descriptors_ =
        Code::Handle(function().unoptimized_code()).GetLocalVarDescriptors();
    ASSERT(!var_descriptors_.IsNull());
  }
}


bool ActivationFrame::IsDebuggable() const {
  return Debugger::IsDebuggable(function());
}


// Calculate the context level at the current token index of the frame.
intptr_t ActivationFrame::ContextLevel() {
  const Context& ctx = GetSavedCurrentContext();
  if (context_level_ < 0 && !ctx.IsNull()) {
    ASSERT(!code_.is_optimized());
    context_level_ = 0;
    // TODO(hausner): What to do if there is no descriptor entry
    // for the code position of the frame? For now say we are at context
    // level 0.
    TokenPos();
    if (token_pos_ == -1) {
      // No PcDescriptor.
      return context_level_;
    }
    ASSERT(!pc_desc_.IsNull());
    intptr_t innermost_begin_pos = 0;
    intptr_t activation_token_pos = TokenPos();
    ASSERT(activation_token_pos >= 0);
    GetVarDescriptors();
    intptr_t var_desc_len = var_descriptors_.Length();
    for (intptr_t cur_idx = 0; cur_idx < var_desc_len; cur_idx++) {
      RawLocalVarDescriptors::VarInfo var_info;
      var_descriptors_.GetInfo(cur_idx, &var_info);
      const int8_t kind = var_info.kind();
      if ((kind == RawLocalVarDescriptors::kContextLevel) &&
          (var_info.begin_pos <= activation_token_pos) &&
          (activation_token_pos < var_info.end_pos)) {
        // This var_descriptors_ entry is a context scope which is in scope
        // of the current token position. Now check whether it is shadowing
        // the previous context scope.
        if (innermost_begin_pos < var_info.begin_pos) {
          innermost_begin_pos = var_info.begin_pos;
          context_level_ = var_info.index();
        }
      }
    }
    ASSERT(context_level_ >= 0);
  }
  return context_level_;
}


// Get the saved current context of this activation.
const Context& ActivationFrame::GetSavedCurrentContext() {
  if (!ctx_.IsNull()) return ctx_;
  GetVarDescriptors();
  intptr_t var_desc_len = var_descriptors_.Length();
  for (intptr_t i = 0; i < var_desc_len; i++) {
    RawLocalVarDescriptors::VarInfo var_info;
    var_descriptors_.GetInfo(i, &var_info);
    const int8_t kind = var_info.kind();
    if (kind == RawLocalVarDescriptors::kSavedCurrentContext) {
      if (FLAG_trace_debugger_stacktrace) {
        OS::PrintErr("\tFound saved current ctx at index %d\n",
            var_info.index());
      }
      ctx_ ^= GetStackVar(var_info.index());
      return ctx_;
    }
  }
  UNREACHABLE();
  return Context::ZoneHandle(Context::null());
}


RawObject* ActivationFrame::GetAsyncOperation() {
  GetVarDescriptors();
  intptr_t var_desc_len = var_descriptors_.Length();
  for (intptr_t i = 0; i < var_desc_len; i++) {
    RawLocalVarDescriptors::VarInfo var_info;
    var_descriptors_.GetInfo(i, &var_info);
    const int8_t kind = var_info.kind();
    if (kind == RawLocalVarDescriptors::kAsyncOperation) {
      return GetContextVar(var_info.scope_id, var_info.index());
    }
  }
  return Object::null();
}


ActivationFrame* DebuggerStackTrace::GetHandlerFrame(
    const Instance& exc_obj) const {
  ExceptionHandlers& handlers = ExceptionHandlers::Handle();
  Array& handled_types = Array::Handle();
  AbstractType& type = Type::Handle();
  const TypeArguments& no_instantiator = TypeArguments::Handle();
  for (intptr_t frame_index = 0;
       frame_index < Length();
       frame_index++) {
    ActivationFrame* frame = FrameAt(frame_index);
    intptr_t try_index = frame->TryIndex();
    if (try_index < 0) continue;
    handlers = frame->code().exception_handlers();
    ASSERT(!handlers.IsNull());
    intptr_t num_handlers_checked = 0;
    while (try_index >= 0) {
      // Detect circles in the exception handler data.
      num_handlers_checked++;
      ASSERT(num_handlers_checked <= handlers.num_entries());
      handled_types = handlers.GetHandledTypes(try_index);
      const intptr_t num_types = handled_types.Length();
      for (intptr_t k = 0; k < num_types; k++) {
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

  intptr_t activation_token_pos = TokenPos();
  if (activation_token_pos < 0) {
    // We don't have a token position for this frame, so can't determine
    // which variables are visible.
    vars_initialized_ = true;
    return;
  }

  GrowableArray<String*> var_names(8);
  intptr_t var_desc_len = var_descriptors_.Length();
  for (intptr_t cur_idx = 0; cur_idx < var_desc_len; cur_idx++) {
    ASSERT(var_names.length() == desc_indices_.length());
    RawLocalVarDescriptors::VarInfo var_info;
    var_descriptors_.GetInfo(cur_idx, &var_info);
    const int8_t kind = var_info.kind();
    if ((kind != RawLocalVarDescriptors::kStackVar) &&
        (kind != RawLocalVarDescriptors::kContextVar)) {
      continue;
    }
    if ((var_info.begin_pos <= activation_token_pos) &&
        (activation_token_pos <= var_info.end_pos)) {
      if ((kind == RawLocalVarDescriptors::kContextVar) &&
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


RawObject* ActivationFrame::GetParameter(intptr_t index) {
  intptr_t num_parameters = function().num_fixed_parameters();
  ASSERT(0 <= index && index < num_parameters);
  intptr_t reverse_index = num_parameters - index;

  if (function().NumOptionalParameters() > 0) {
    // If the function has optional parameters, the first positional parameter
    // can be in a number of places in the caller's frame depending on how many
    // were actually supplied at the call site, but they are copied to a fixed
    // place in the callee's frame.
    uword var_address = fp() + ((kFirstLocalSlotFromFp - index) * kWordSize);
    return reinterpret_cast<RawObject*>(
        *reinterpret_cast<uword*>(var_address));
  } else {
    uword var_address = fp() + (kParamEndSlotFromFp * kWordSize)
                             + (reverse_index * kWordSize);
    return reinterpret_cast<RawObject*>(
        *reinterpret_cast<uword*>(var_address));
  }
}


RawObject* ActivationFrame::GetClosure() {
  ASSERT(function().IsClosureFunction());
  return GetParameter(0);
}


RawObject* ActivationFrame::GetStackVar(intptr_t slot_index) {
  if (deopt_frame_.IsNull()) {
    uword var_address = fp() + slot_index * kWordSize;
    return reinterpret_cast<RawObject*>(
        *reinterpret_cast<uword*>(var_address));
  } else {
    return deopt_frame_.At(deopt_frame_offset_ + slot_index);
  }
}


void ActivationFrame::PrintContextMismatchError(
    intptr_t ctx_slot,
    intptr_t frame_ctx_level,
    intptr_t var_ctx_level) {
  OS::PrintErr("-------------------------\n"
               "Encountered context mismatch\n"
               "\tctx_slot: %" Pd "\n"
               "\tframe_ctx_level: %" Pd "\n"
               "\tvar_ctx_level: %" Pd "\n\n",
               ctx_slot,
               frame_ctx_level,
               var_ctx_level);

  OS::PrintErr("-------------------------\n"
               "Current frame:\n%s\n",
               this->ToCString());

  OS::PrintErr("-------------------------\n"
               "Context contents:\n");
  const Context& ctx = GetSavedCurrentContext();
  ctx.Dump(8);

  OS::PrintErr("-------------------------\n"
               "Debugger stack trace...\n\n");
  DebuggerStackTrace* stack =
      Isolate::Current()->debugger()->StackTrace();
  intptr_t num_frames = stack->Length();
  for (intptr_t i = 0; i < num_frames; i++) {
    ActivationFrame* frame = stack->FrameAt(i);
    OS::PrintErr("#%04" Pd " %s", i, frame->ToCString());
  }

  OS::PrintErr("-------------------------\n"
               "All frames...\n\n");
  StackFrameIterator iterator(false);
  StackFrame* frame = iterator.NextFrame();
  intptr_t num = 0;
  while ((frame != NULL)) {
    OS::PrintErr("#%04" Pd " %s\n", num++, frame->ToCString());
    frame = iterator.NextFrame();
  }
}


void ActivationFrame::VariableAt(intptr_t i,
                                 String* name,
                                 intptr_t* token_pos,
                                 intptr_t* end_pos,
                                 Object* value) {
  GetDescIndices();
  ASSERT(i < desc_indices_.length());
  intptr_t desc_index = desc_indices_[i];
  ASSERT(name != NULL);

  const String& tmp = String::Handle(var_descriptors_.GetName(desc_index));
  *name ^= String::IdentifierPrettyName(tmp);

  RawLocalVarDescriptors::VarInfo var_info;
  var_descriptors_.GetInfo(desc_index, &var_info);
  ASSERT(token_pos != NULL);
  *token_pos = var_info.begin_pos;
  ASSERT(end_pos != NULL);
  *end_pos = var_info.end_pos;
  ASSERT(value != NULL);
  const int8_t kind = var_info.kind();
  if (kind == RawLocalVarDescriptors::kStackVar) {
    *value = GetStackVar(var_info.index());
  } else {
    ASSERT(kind == RawLocalVarDescriptors::kContextVar);
    *value = GetContextVar(var_info.scope_id, var_info.index());
  }
}


RawObject* ActivationFrame::GetContextVar(intptr_t var_ctx_level,
                                          intptr_t ctx_slot) {
  const Context& ctx = GetSavedCurrentContext();
  ASSERT(!ctx.IsNull());

  // The context level at the PC/token index of this activation frame.
  intptr_t frame_ctx_level = ContextLevel();

  intptr_t level_diff = frame_ctx_level - var_ctx_level;
  if (level_diff == 0) {
    if ((ctx_slot < 0) ||
        (ctx_slot >= ctx.num_variables())) {
      PrintContextMismatchError(ctx_slot, frame_ctx_level, var_ctx_level);
    }
    ASSERT((ctx_slot >= 0) && (ctx_slot < ctx.num_variables()));
    return ctx.At(ctx_slot);
  } else {
    ASSERT(level_diff > 0);
    Context& var_ctx = Context::Handle(ctx.raw());
    while (level_diff > 0 && !var_ctx.IsNull()) {
      level_diff--;
      var_ctx = var_ctx.parent();
    }
    if (var_ctx.IsNull() ||
        (ctx_slot < 0) ||
        (ctx_slot >= var_ctx.num_variables())) {
      PrintContextMismatchError(ctx_slot, frame_ctx_level, var_ctx_level);
    }
    ASSERT(!var_ctx.IsNull());
    ASSERT((ctx_slot >= 0) && (ctx_slot < var_ctx.num_variables()));
    return var_ctx.At(ctx_slot);
  }
}


RawArray* ActivationFrame::GetLocalVariables() {
  GetDescIndices();
  intptr_t num_variables = desc_indices_.length();
  String& var_name = String::Handle();
  Object& value = Instance::Handle();
  const Array& list = Array::Handle(Array::New(2 * num_variables));
  for (intptr_t i = 0; i < num_variables; i++) {
    intptr_t ignore;
    VariableAt(i, &var_name, &ignore, &ignore, &value);
    list.SetAt(2 * i, var_name);
    list.SetAt((2 * i) + 1, value);
  }
  return list.raw();
}


RawObject* ActivationFrame::GetReceiver() {
  GetDescIndices();
  intptr_t num_variables = desc_indices_.length();
  String& var_name = String::Handle();
  Instance& value = Instance::Handle();
  for (intptr_t i = 0; i < num_variables; i++) {
    intptr_t ignore;
    VariableAt(i, &var_name, &ignore, &ignore, &value);
    if (var_name.Equals(Symbols::This())) {
      return value.raw();
    }
  }
  return Object::null();
}


RawObject* ActivationFrame::Evaluate(const String& expr) {
  GetDescIndices();
  const GrowableObjectArray& param_names =
      GrowableObjectArray::Handle(GrowableObjectArray::New());
  const GrowableObjectArray& param_values =
      GrowableObjectArray::Handle(GrowableObjectArray::New());
  String& name = String::Handle();
  Object& value = Instance::Handle();
  intptr_t num_variables = desc_indices_.length();
  for (intptr_t i = 0; i < num_variables; i++) {
    intptr_t ignore;
    VariableAt(i, &name, &ignore, &ignore, &value);
    if (!name.Equals(Symbols::This())) {
      param_names.Add(name);
      param_values.Add(value);
    }
  }

  if (function().is_static()) {
    const Class& cls = Class::Handle(function().Owner());
    return cls.Evaluate(expr,
                        Array::Handle(Array::MakeArray(param_names)),
                        Array::Handle(Array::MakeArray(param_values)));
  } else {
    const Object& receiver = Object::Handle(GetReceiver());
    ASSERT(receiver.IsInstance());
    if (!receiver.IsInstance()) {
      return Object::null();
    }
    const Instance& inst = Instance::Cast(receiver);
    return inst.Evaluate(expr,
                         Array::Handle(Array::MakeArray(param_names)),
                         Array::Handle(Array::MakeArray(param_values)));
  }
  UNREACHABLE();
  return Object::null();
}


const char* ActivationFrame::ToCString() {
  const String& url = String::Handle(SourceUrl());
  intptr_t line = LineNumber();
  const char* func_name = Debugger::QualifiedFunctionName(function());
  return Thread::Current()->zone()->
      PrintToString("[ Frame pc(0x%" Px ") fp(0x%" Px ") sp(0x%" Px ")\n"
                    "\tfunction = %s\n"
                    "\turl = %s\n"
                    "\tline = %" Pd "\n"
                    "\tcontext = %s\n"
                    "\tcontext level = %" Pd " ]\n",
                    pc(), fp(), sp(),
                    func_name,
                    url.ToCString(),
                    line,
                    ctx_.ToCString(),
                    ContextLevel());
}


void ActivationFrame::PrintToJSONObject(JSONObject* jsobj,
                                        bool full) {
  const Script& script = Script::Handle(SourceScript());
  jsobj->AddProperty("type", "Frame");
  jsobj->AddLocation(script, TokenPos());
  jsobj->AddProperty("function", function(), !full);
  jsobj->AddProperty("code", code());
  if (full) {
    // TODO(cutch): The old "full" script usage no longer fits
    // in the world where we pass the script as part of the
    // location.
    jsobj->AddProperty("script", script, !full);
  }
  {
    JSONArray jsvars(jsobj, "vars");
    const int num_vars = NumLocalVariables();
    for (intptr_t v = 0; v < num_vars; v++) {
      JSONObject jsvar(&jsvars);
      String& var_name = String::Handle();
      Instance& var_value = Instance::Handle();
      intptr_t token_pos;
      intptr_t end_token_pos;
      VariableAt(v, &var_name, &token_pos, &end_token_pos, &var_value);
      jsvar.AddProperty("name", var_name.ToCString());
      jsvar.AddProperty("value", var_value, !full);
      // TODO(turnidge): Do we really want to provide this on every
      // stack dump?  Should be associated with the function object, I
      // think, and not the stack frame.
      jsvar.AddProperty("_tokenPos", token_pos);
      jsvar.AddProperty("_endTokenPos", end_token_pos);
    }
  }
}



void DebuggerStackTrace::AddActivation(ActivationFrame* frame) {
  if (FLAG_show_invisible_frames || frame->function().is_visible()) {
    trace_.Add(frame);
  }
}


const uint8_t kSafepointKind = RawPcDescriptors::kIcCall
                             | RawPcDescriptors::kUnoptStaticCall
                             | RawPcDescriptors::kRuntimeCall;


CodeBreakpoint::CodeBreakpoint(const Code& code,
                               intptr_t token_pos,
                               uword pc,
                               RawPcDescriptors::Kind kind)
    : code_(code.raw()),
      token_pos_(token_pos),
      pc_(pc),
      line_number_(-1),
      is_enabled_(false),
      bpt_location_(NULL),
      next_(NULL),
      breakpoint_kind_(kind),
      saved_value_(0) {
  ASSERT(!code.IsNull());
  ASSERT(token_pos_ > 0);
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
  breakpoint_kind_ = RawPcDescriptors::kOther;
#endif
}


RawFunction* CodeBreakpoint::function() const {
  return Code::Handle(code_).function();
}


RawScript* CodeBreakpoint::SourceCode() {
  const Function& func = Function::Handle(this->function());
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
    script.GetTokenLocation(token_pos_, &line_number_, NULL);
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


RemoteObjectCache::RemoteObjectCache(intptr_t initial_size) {
  objs_ = &GrowableObjectArray::ZoneHandle(
              GrowableObjectArray::New(initial_size));
}


intptr_t RemoteObjectCache::AddObject(const Object& obj) {
  intptr_t len = objs_->Length();
  for (intptr_t i = 0; i < len; i++) {
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
      latent_locations_(NULL),
      breakpoint_locations_(NULL),
      code_breakpoints_(NULL),
      resume_action_(kContinue),
      ignore_breakpoints_(false),
      pause_event_(NULL),
      obj_cache_(NULL),
      stack_trace_(NULL),
      stepping_fp_(0),
      exc_pause_info_(kNoPauseOnExceptions) {
}


Debugger::~Debugger() {
  isolate_id_ = ILLEGAL_ISOLATE_ID;
  ASSERT(!IsPaused());
  ASSERT(latent_locations_ == NULL);
  ASSERT(breakpoint_locations_ == NULL);
  ASSERT(code_breakpoints_ == NULL);
  ASSERT(stack_trace_ == NULL);
  ASSERT(obj_cache_ == NULL);
}


void Debugger::Shutdown() {
  while (breakpoint_locations_ != NULL) {
    BreakpointLocation* bpt = breakpoint_locations_;
    breakpoint_locations_ = breakpoint_locations_->next();
    delete bpt;
  }
  while (latent_locations_ != NULL) {
    BreakpointLocation* bpt = latent_locations_;
    latent_locations_ = latent_locations_->next();
    delete bpt;
  }
  while (code_breakpoints_ != NULL) {
    CodeBreakpoint* bpt = code_breakpoints_;
    code_breakpoints_ = code_breakpoints_->next();
    bpt->Disable();
    delete bpt;
  }
  // Signal isolate shutdown event.
  if (!ServiceIsolate::IsServiceIsolateDescendant(isolate_)) {
    SignalIsolateEvent(DebuggerEvent::kIsolateShutdown);
  }
}


static RawFunction* ResolveLibraryFunction(
                        const Library& library,
                        const String& fname) {
  ASSERT(!library.IsNull());
  const Object& object = Object::Handle(library.ResolveName(fname));
  if (!object.IsNull() && object.IsFunction()) {
    return Function::Cast(object).raw();
  }
  return Function::null();
}


void Debugger::SetSingleStep() {
  resume_action_ = kSingleStep;
}


void Debugger::SetStepOver() {
  resume_action_ = kStepOver;
}


void Debugger::SetStepOut() {
  resume_action_ = kStepOut;
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
  DeoptimizeFunctionsOnStack();
  // Iterate over all classes, deoptimize functions.
  // TODO(hausner): Could possibly be combined with RemoveOptimizedCode()
  const ClassTable& class_table = *isolate_->class_table();
  Class& cls = Class::Handle();
  Array& functions = Array::Handle();
  GrowableObjectArray& closures = GrowableObjectArray::Handle();
  Function& function = Function::Handle();
  intptr_t num_classes = class_table.NumCids();
  for (intptr_t i = 1; i < num_classes; i++) {
    if (class_table.HasValidClassAt(i)) {
      cls = class_table.At(i);

      // Disable optimized functions.
      functions = cls.functions();
      if (!functions.IsNull()) {
        intptr_t num_functions = functions.Length();
        for (intptr_t pos = 0; pos < num_functions; pos++) {
          function ^= functions.At(pos);
          ASSERT(!function.IsNull());
          if (function.HasOptimizedCode()) {
            function.SwitchToUnoptimizedCode();
          }
          // Also disable any optimized implicit closure functions.
          if (function.HasImplicitClosureFunction()) {
            function = function.ImplicitClosureFunction();
            if (function.HasOptimizedCode()) {
              function.SwitchToUnoptimizedCode();
            }
          }
        }
      }

      // Disable other optimized closure functions.
      closures = cls.closures();
      if (!closures.IsNull()) {
        intptr_t num_closures = closures.Length();
        for (intptr_t pos = 0; pos < num_closures; pos++) {
          function ^= closures.At(pos);
          ASSERT(!function.IsNull());
          if (function.HasOptimizedCode()) {
            function.SwitchToUnoptimizedCode();
          }
        }
      }
    }
  }
}


void Debugger::SignalBpResolved(Breakpoint* bpt) {
  if (HasEventHandler() && !bpt->IsSingleShot()) {
    DebuggerEvent event(isolate_, DebuggerEvent::kBreakpointResolved);
    event.set_breakpoint(bpt);
    InvokeEventHandler(&event);
  }
}


ActivationFrame* Debugger::CollectDartFrame(Isolate* isolate,
                                            uword pc,
                                            StackFrame* frame,
                                            const Code& code,
                                            const Array& deopt_frame,
                                            intptr_t deopt_frame_offset) {
  ASSERT(code.ContainsInstructionAt(pc));
  ActivationFrame* activation =
      new ActivationFrame(pc, frame->fp(), frame->sp(), code,
                          deopt_frame, deopt_frame_offset);
  if (FLAG_trace_debugger_stacktrace) {
    const Context& ctx = activation->GetSavedCurrentContext();
    OS::PrintErr("\tUsing saved context: %s\n", ctx.ToCString());
  }
  if (FLAG_trace_debugger_stacktrace) {
    OS::PrintErr("\tLine number: %" Pd "\n", activation->LineNumber());
  }
  return activation;
}


RawArray* Debugger::DeoptimizeToArray(Isolate* isolate,
                                      StackFrame* frame,
                                      const Code& code) {
  ASSERT(code.is_optimized());

  // Create the DeoptContext for this deoptimization.
  DeoptContext* deopt_context =
      new DeoptContext(frame, code,
                       DeoptContext::kDestIsAllocated,
                       NULL, NULL);
  isolate->set_deopt_context(deopt_context);

  deopt_context->FillDestFrame();
  deopt_context->MaterializeDeferredObjects();
  const Array& dest_frame = Array::Handle(isolate,
                                          deopt_context->DestFrameAsArray());

  isolate->set_deopt_context(NULL);
  delete deopt_context;

  return dest_frame.raw();
}


DebuggerStackTrace* Debugger::CollectStackTrace() {
  Isolate* isolate = Isolate::Current();
  DebuggerStackTrace* stack_trace = new DebuggerStackTrace(8);
  StackFrameIterator iterator(false);
  Code& code = Code::Handle(isolate);
  Code& inlined_code = Code::Handle(isolate);
  Array& deopt_frame = Array::Handle(isolate);

  for (StackFrame* frame = iterator.NextFrame();
       frame != NULL;
       frame = iterator.NextFrame()) {
    ASSERT(frame->IsValid());
    if (FLAG_trace_debugger_stacktrace) {
      OS::PrintErr("CollectStackTrace: visiting frame:\n\t%s\n",
                   frame->ToCString());
    }
    if (frame->IsDartFrame()) {
      code = frame->LookupDartCode();
      if (code.is_optimized() && !Compiler::always_optimize()) {
        deopt_frame = DeoptimizeToArray(isolate, frame, code);
        for (InlinedFunctionsIterator it(code, frame->pc());
             !it.Done();
             it.Advance()) {
          inlined_code = it.code();
          if (FLAG_trace_debugger_stacktrace) {
            const Function& function =
                Function::Handle(isolate, inlined_code.function());
            ASSERT(!function.IsNull());
            OS::PrintErr("CollectStackTrace: visiting inlined function: %s\n",
                         function.ToFullyQualifiedCString());
          }
          intptr_t deopt_frame_offset = it.GetDeoptFpOffset();
          stack_trace->AddActivation(CollectDartFrame(isolate,
                                                      it.pc(),
                                                      frame,
                                                      inlined_code,
                                                      deopt_frame,
                                                      deopt_frame_offset));
        }
      } else {
        stack_trace->AddActivation(CollectDartFrame(isolate,
                                                    frame->pc(),
                                                    frame,
                                                    code,
                                                    Object::null_array(),
                                                    0));
      }
    }
  }
  return stack_trace;
}


ActivationFrame* Debugger::TopDartFrame() const {
  StackFrameIterator iterator(false);
  StackFrame* frame = iterator.NextFrame();
  while ((frame != NULL) && !frame->IsDartFrame()) {
    frame = iterator.NextFrame();
  }
  Code& code = Code::Handle(isolate_, frame->LookupDartCode());
  ActivationFrame* activation =
      new ActivationFrame(frame->pc(), frame->fp(), frame->sp(), code,
                          Object::null_array(), 0);
  return activation;
}


DebuggerStackTrace* Debugger::StackTrace() {
  return (stack_trace_ != NULL) ? stack_trace_ : CollectStackTrace();
}

DebuggerStackTrace* Debugger::CurrentStackTrace() {
  return CollectStackTrace();
}

DebuggerStackTrace* Debugger::StackTraceFrom(const Stacktrace& ex_trace) {
  DebuggerStackTrace* stack_trace = new DebuggerStackTrace(8);
  Function& function = Function::Handle();
  Code& code = Code::Handle();

  const uword fp = 0;
  const uword sp = 0;
  const Array& deopt_frame = Array::Handle();
  const intptr_t deopt_frame_offset = -1;

  for (intptr_t i = 0; i < ex_trace.Length(); i++) {
    function = ex_trace.FunctionAtFrame(i);
    // Pre-allocated Stacktraces may include empty slots, either (a) to indicate
    // where frames were omitted in the case a stack has more frames than the
    // pre-allocated trace (such as a stack overflow) or (b) because a stack has
    // fewer frames that the pre-allocated trace (such as memory exhaustion with
    // a shallow stack).
    if (!function.IsNull() && function.is_visible()) {
      code = ex_trace.CodeAtFrame(i);
      ASSERT(function.raw() == code.function());
      uword pc = code.EntryPoint() + Smi::Value(ex_trace.PcOffsetAtFrame(i));
      if (code.is_optimized() && ex_trace.expand_inlined()) {
        // Traverse inlined frames.
        for (InlinedFunctionsIterator it(code, pc); !it.Done(); it.Advance()) {
          function = it.function();
          code = it.code();
          ASSERT(function.raw() == code.function());
          uword pc = it.pc();
          ASSERT(pc != 0);
          ASSERT(code.EntryPoint() <= pc);
          ASSERT(pc < (code.EntryPoint() + code.Size()));

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
      IsPaused() ||
      (!HasEventHandler()) ||
      (exc_pause_info_ == kNoPauseOnExceptions)) {
    return;
  }
  DebuggerStackTrace* stack_trace = CollectStackTrace();
  if (!ShouldPauseOnException(stack_trace, exc)) {
    return;
  }
  DebuggerEvent event(isolate_, DebuggerEvent::kExceptionThrown);
  event.set_exception(&exc);
  ASSERT(stack_trace->Length() > 0);
  event.set_top_frame(stack_trace->FrameAt(0));
  ASSERT(stack_trace_ == NULL);
  stack_trace_ = stack_trace;
  Pause(&event);
  stack_trace_ = NULL;
}


static intptr_t LastTokenOnLine(const TokenStream& tokens, intptr_t pos) {
  TokenStream::Iterator iter(tokens, pos, TokenStream::Iterator::kAllTokens);
  ASSERT(iter.IsValid());
  intptr_t last_pos = pos;
  while ((iter.CurrentTokenKind() != Token::kNEWLINE) &&
      (iter.CurrentTokenKind() != Token::kEOS)) {
    last_pos = iter.CurrentPosition();
    iter.Advance();
  }
  return last_pos;
}


// Given a function and a token range, return the best fit
// token position to set a breakpoint. The best fit is the safe point
// in the line closest to the beginning of the token range, and within
// that line, the safe point with the lowest compiled code address.
intptr_t Debugger::ResolveBreakpointPos(const Function& func,
                                        intptr_t requested_token_pos,
                                        intptr_t last_token_pos) {
  ASSERT(func.HasCode());
  ASSERT(!func.HasOptimizedCode());

  if (requested_token_pos < func.token_pos()) {
    requested_token_pos = func.token_pos();
  }
  if (last_token_pos > func.end_token_pos()) {
    last_token_pos = func.end_token_pos();
  }

  Code& code = Code::Handle(func.unoptimized_code());
  ASSERT(!code.IsNull());
  PcDescriptors& desc = PcDescriptors::Handle(code.pc_descriptors());

  // First pass: find the safe point which is closest to the beginning
  // of the given token range.
  intptr_t best_fit_pos = INT_MAX;
  PcDescriptors::Iterator iter(desc, kSafepointKind);
  while (iter.MoveNext()) {
    const intptr_t desc_token_pos = iter.TokenPos();
    if ((desc_token_pos != Scanner::kNoSourcePos) &&
        (desc_token_pos < best_fit_pos) &&
        (desc_token_pos >= requested_token_pos) &&
        (desc_token_pos <= last_token_pos)) {
       best_fit_pos = desc_token_pos;
    }
  }
  // Second pass (if we found a safe point in the first pass):
  // For all token positions on the same line, select the one
  // with the lowest compiled code address. E.g., in a line with
  // the nested function calls f(g(x)), the call g() will have a lower
  // compiled code address but is not the lowest token position in the
  // line.
  if (best_fit_pos != INT_MAX) {
    const Script& script = Script::Handle(func.script());
    const TokenStream& tokens = TokenStream::Handle(script.tokens());
    const intptr_t begin_pos = best_fit_pos;
    const intptr_t end_of_line_pos = LastTokenOnLine(tokens, begin_pos);
    uword lowest_pc_offset = kUwordMax;
    PcDescriptors::Iterator iter(desc, kSafepointKind);
    while (iter.MoveNext()) {
      const intptr_t pos = iter.TokenPos();
      if ((pos != Scanner::kNoSourcePos) &&
          (begin_pos <= pos) && (pos <= end_of_line_pos) &&
          (iter.PcOffset() < lowest_pc_offset)) {
        lowest_pc_offset = iter.PcOffset();
        best_fit_pos = pos;
      }
    }
    return best_fit_pos;
  }

  // We didn't find a safe point in the given token range. Try and find
  // a safe point in the remaining source code of the function.
  if (last_token_pos < func.end_token_pos()) {
    return ResolveBreakpointPos(func, last_token_pos, func.end_token_pos());
  }
  return -1;
}


void Debugger::MakeCodeBreakpointAt(const Function& func,
                                    BreakpointLocation* loc) {
  ASSERT(loc->token_pos_ != Scanner::kNoSourcePos);
  ASSERT((loc != NULL) && loc->IsResolved());
  ASSERT(!func.HasOptimizedCode());
  Code& code = Code::Handle(func.unoptimized_code());
  ASSERT(!code.IsNull());
  PcDescriptors& desc = PcDescriptors::Handle(code.pc_descriptors());
  uword lowest_pc_offset = kUwordMax;
  RawPcDescriptors::Kind lowest_kind = RawPcDescriptors::kAnyKind;
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
  if (lowest_pc_offset == kUwordMax) {
    return;
  }
  uword lowest_pc = code.EntryPoint() + lowest_pc_offset;
  CodeBreakpoint* code_bpt = GetCodeBreakpoint(lowest_pc);
  if (code_bpt == NULL) {
    // No code breakpoint for this code exists; create one.
    code_bpt = new CodeBreakpoint(code, loc->token_pos_,
                                  lowest_pc, lowest_kind);
    RegisterCodeBreakpoint(code_bpt);
  }
  code_bpt->set_bpt_location(loc);
  if (loc->AnyEnabled()) {
    code_bpt->Enable();
  }
}


void Debugger::FindCompiledFunctions(const Script& script,
                                     intptr_t start_pos,
                                     intptr_t end_pos,
                                     GrowableObjectArray* function_list) {
  Class& cls = Class::Handle(isolate_);
  Array& functions = Array::Handle(isolate_);
  GrowableObjectArray& closures = GrowableObjectArray::Handle(isolate_);
  Function& function = Function::Handle(isolate_);

  const ClassTable& class_table = *isolate_->class_table();
  const intptr_t num_classes = class_table.NumCids();
  for (intptr_t i = 1; i < num_classes; i++) {
    if (class_table.HasValidClassAt(i)) {
      cls = class_table.At(i);
      // If the class is not finalized, e.g. if it hasn't been parsed
      // yet entirely, we can ignore it. If it contains a function with
      // an unresolved breakpoint, we will detect it if and when the
      // function gets compiled.
      if (!cls.is_finalized()) {
        continue;
      }
      // Note: we need to check the functions of this class even if
      // the class is defined in a differenct 'script'. There could
      // be mixin functions from the given script in this class.
      functions = cls.functions();
      if (!functions.IsNull()) {
        const intptr_t num_functions = functions.Length();
        for (intptr_t pos = 0; pos < num_functions; pos++) {
          function ^= functions.At(pos);
          ASSERT(!function.IsNull());
          // Check token position first to avoid unnecessary calls
          // to script() which allocates handles.
          if ((function.token_pos() == start_pos)
              && (function.end_token_pos() == end_pos)
              && (function.script() == script.raw())) {
            if (function.HasCode() && function.is_debuggable()) {
              function_list->Add(function);
            }
            if (function.HasImplicitClosureFunction()) {
              function = function.ImplicitClosureFunction();
              if (function.HasCode() && function.is_debuggable()) {
                function_list->Add(function);
              }
            }
          }
        }
      }
      closures = cls.closures();
      if (!closures.IsNull()) {
        const intptr_t num_closures = closures.Length();
        for (intptr_t pos = 0; pos < num_closures; pos++) {
          function ^= closures.At(pos);
          ASSERT(!function.IsNull());
          if ((function.token_pos() == start_pos)
              && (function.end_token_pos() == end_pos)
              && (function.script() == script.raw())) {
            if (function.HasCode() && function.is_debuggable()) {
              function_list->Add(function);
            }
            if (function.HasImplicitClosureFunction()) {
              function = function.ImplicitClosureFunction();
              if (function.HasCode() && function.is_debuggable()) {
                function_list->Add(function);
              }
            }
          }
        }
      }
    }
  }
}


static void SelectBestFit(Function* best_fit, Function* func) {
  if (best_fit->IsNull()) {
    *best_fit = func->raw();
  } else {
    if ((func->token_pos() > best_fit->token_pos()) &&
        ((func->end_token_pos() <= best_fit->end_token_pos()))) {
      *best_fit = func->raw();
    }
  }
}


RawFunction* Debugger::FindBestFit(const Script& script,
                                   intptr_t token_pos) {
  Class& cls = Class::Handle(isolate_);
  Array& functions = Array::Handle(isolate_);
  GrowableObjectArray& closures = GrowableObjectArray::Handle(isolate_);
  Function& function = Function::Handle(isolate_);
  Function& best_fit = Function::Handle(isolate_);
  Error& error = Error::Handle(isolate_);

  const ClassTable& class_table = *isolate_->class_table();
  const intptr_t num_classes = class_table.NumCids();
  for (intptr_t i = 1; i < num_classes; i++) {
    if (class_table.HasValidClassAt(i)) {
      cls = class_table.At(i);
      // Note: if this class has been parsed and finalized already,
      // we need to check the functions of this class even if
      // it is defined in a differenct 'script'. There could
      // be mixin functions from the given script in this class.
      // However, if this class is not parsed yet (not finalized),
      // we can ignore it and avoid the side effect of parsing it.
      if ((cls.script() != script.raw()) && !cls.is_finalized()) {
        continue;
      }
      // Parse class definition if not done yet.
      error = cls.EnsureIsFinalized(isolate_);
      if (!error.IsNull()) {
        // Ignore functions in this class.
        // TODO(hausner): Should we propagate this error? How?
        // EnsureIsFinalized only returns an error object if there
        // is no longjump base on the stack.
        continue;
      }
      functions = cls.functions();
      if (!functions.IsNull()) {
        const intptr_t num_functions = functions.Length();
        for (intptr_t pos = 0; pos < num_functions; pos++) {
          function ^= functions.At(pos);
          ASSERT(!function.IsNull());
          if (FunctionContains(function, script, token_pos)) {
            SelectBestFit(&best_fit, &function);
          }
        }
      }

      closures = cls.closures();
      if (!closures.IsNull()) {
        const intptr_t num_closures = closures.Length();
        for (intptr_t pos = 0; pos < num_closures; pos++) {
          function ^= closures.At(pos);
          ASSERT(!function.IsNull());
          if (FunctionContains(function, script, token_pos)) {
            SelectBestFit(&best_fit, &function);
          }
        }
      }
    }
  }
  return best_fit.raw();
}


BreakpointLocation* Debugger::SetBreakpoint(const Script& script,
                                            intptr_t token_pos,
                                            intptr_t last_token_pos) {
  Function& func = Function::Handle(isolate_);
  func = FindBestFit(script, token_pos);
  if (func.IsNull()) {
    return NULL;
  }
  // There may be more than one function object for a given function
  // in source code. There may be implicit closure functions, and
  // there may be copies of mixin functions. Collect all compiled
  // functions whose source code range matches exactly the best fit
  // function we found.
  GrowableObjectArray& functions =
      GrowableObjectArray::Handle(GrowableObjectArray::New());
  FindCompiledFunctions(script,
                        func.token_pos(),
                        func.end_token_pos(),
                        &functions);

  if (functions.Length() > 0) {
    // One or more function object containing this breakpoint location
    // have already been compiled. We can resolve the breakpoint now.
    DeoptimizeWorld();
    func ^= functions.At(0);
    intptr_t breakpoint_pos =
        ResolveBreakpointPos(func, token_pos, last_token_pos);
    if (breakpoint_pos >= 0) {
      BreakpointLocation* bpt = GetBreakpointLocation(script, breakpoint_pos);
      if (bpt != NULL) {
        // A source breakpoint for this location already exists.
        return bpt;
      }
      bpt = new BreakpointLocation(script, token_pos, last_token_pos);
      bpt->SetResolved(func, breakpoint_pos);
      RegisterBreakpointLocation(bpt);

      // Create code breakpoints for all compiled functions we found.
      const intptr_t num_functions = functions.Length();
      for (intptr_t i = 0; i < num_functions; i++) {
        func ^= functions.At(i);
        ASSERT(func.HasCode());
        MakeCodeBreakpointAt(func, bpt);
      }
      if (FLAG_verbose_debug) {
        intptr_t line_number;
        script.GetTokenLocation(breakpoint_pos, &line_number, NULL);
        OS::Print("Resolved BP for "
                  "function '%s' at line %" Pd "\n",
                  func.ToFullyQualifiedCString(),
                  line_number);
      }
      return bpt;
    }
  }
  // There is no compiled function at this token position.
  // Register an unresolved breakpoint.
  if (FLAG_verbose_debug && !func.IsNull()) {
    intptr_t line_number;
    script.GetTokenLocation(token_pos, &line_number, NULL);
    OS::Print("Registering pending breakpoint for "
              "uncompiled function '%s' at line %" Pd "\n",
              func.ToFullyQualifiedCString(),
              line_number);
  }
  BreakpointLocation* bpt = GetBreakpointLocation(script, token_pos);
  if (bpt == NULL) {
    bpt = new BreakpointLocation(script, token_pos, last_token_pos);
    RegisterBreakpointLocation(bpt);
  }
  return bpt;
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


RawError* Debugger::OneTimeBreakAtEntry(const Function& target_function) {
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    SetBreakpointAtEntry(target_function, true);
    return Error::null();
  } else {
    return isolate_->object_store()->sticky_error();
  }
}


Breakpoint* Debugger::SetBreakpointAtEntry(const Function& target_function,
                                           bool single_shot) {
  ASSERT(!target_function.IsNull());
  if (!target_function.is_debuggable()) {
    return NULL;
  }
  const Script& script = Script::Handle(target_function.script());
  BreakpointLocation* bpt_location =
      SetBreakpoint(script,
                    target_function.token_pos(),
                    target_function.end_token_pos());
  if (single_shot) {
    return bpt_location->AddSingleShot(this);
  } else {
    return bpt_location->AddRepeated(this);
  }
}


Breakpoint* Debugger::SetBreakpointAtActivation(const Instance& closure) {
  if (!closure.IsClosure()) {
    return NULL;
  }
  const Function& func = Function::Handle(Closure::function(closure));
  const Script& script = Script::Handle(func.script());
  BreakpointLocation* bpt_location = SetBreakpoint(script,
                                                   func.token_pos(),
                                                   func.end_token_pos());
  return bpt_location->AddPerClosure(this, closure);
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
  BreakpointLocation* loc = BreakpointLocationAtLine(script_url, line_number);
  if (loc != NULL) {
    return loc->AddRepeated(this);
  }
  return NULL;
}


BreakpointLocation* Debugger::BreakpointLocationAtLine(const String& script_url,
                                                       intptr_t line_number) {
  Library& lib = Library::Handle(isolate_);
  Script& script = Script::Handle(isolate_);
  const GrowableObjectArray& libs =
      GrowableObjectArray::Handle(isolate_->object_store()->libraries());
  const GrowableObjectArray& scripts =
    GrowableObjectArray::Handle(isolate_, GrowableObjectArray::New());
  for (intptr_t i = 0; i < libs.Length(); i++) {
    lib ^= libs.At(i);
    script = lib.LookupScript(script_url);
    if (!script.IsNull()) {
      scripts.Add(script);
    }
  }
  if (scripts.Length() == 0) {
    // No script found with given url. Create a latent breakpoint which
    // will be set if the url is loaded later.
    BreakpointLocation* latent_bpt = GetLatentBreakpoint(script_url,
                                                         line_number);
    if (FLAG_verbose_debug) {
      OS::Print("Set latent breakpoint in url '%s' at line %" Pd "\n",
                script_url.ToCString(),
                line_number);
    }
    return latent_bpt;
  }
  if (scripts.Length() > 1) {
    if (FLAG_verbose_debug) {
      OS::Print("Multiple scripts match url '%s'\n", script_url.ToCString());
    }
    return NULL;
  }
  script ^= scripts.At(0);
  intptr_t first_token_idx, last_token_idx;
  script.TokenRangeAtLine(line_number, &first_token_idx, &last_token_idx);
  if (first_token_idx < 0) {
    // Script does not contain the given line number.
    if (FLAG_verbose_debug) {
      OS::Print("Script '%s' does not contain line number %" Pd "\n",
                script_url.ToCString(), line_number);
    }
    return NULL;
  } else if (last_token_idx < 0) {
    // Line does not contain any tokens.
    if (FLAG_verbose_debug) {
      OS::Print("No executable code at line %" Pd " in '%s'\n",
                line_number, script_url.ToCString());
    }
    return NULL;
  }

  BreakpointLocation* bpt = NULL;
  ASSERT(first_token_idx <= last_token_idx);
  while ((bpt == NULL) && (first_token_idx <= last_token_idx)) {
    bpt = SetBreakpoint(script, first_token_idx, last_token_idx);
    first_token_idx++;
  }
  if ((bpt == NULL) && FLAG_verbose_debug) {
    OS::Print("No executable code at line %" Pd " in '%s'\n",
                line_number, script_url.ToCString());
  }
  return bpt;
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

  PassiveObject& result = PassiveObject::Handle();
  bool saved_ignore_flag = ignore_breakpoints_;
  ignore_breakpoints_ = true;

  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    const Array& args = Array::Handle(Array::New(1));
    args.SetAt(0, object);
    result = DartEntry::InvokeFunction(getter_func, args);
  } else {
    result = isolate_->object_store()->sticky_error();
  }
  ignore_breakpoints_ = saved_ignore_flag;
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

  PassiveObject& result = PassiveObject::Handle();
  bool saved_ignore_flag = ignore_breakpoints_;
  ignore_breakpoints_ = true;
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    result = DartEntry::InvokeFunction(getter_func, Object::empty_array());
  } else {
    result = isolate_->object_store()->sticky_error();
  }
  ignore_breakpoints_ = saved_ignore_flag;
  return result.raw();
}


RawArray* Debugger::GetInstanceFields(const Instance& obj) {
  Class& cls = Class::Handle(obj.clazz());
  Array& fields = Array::Handle();
  Field& field = Field::Handle();
  const GrowableObjectArray& field_list =
      GrowableObjectArray::Handle(GrowableObjectArray::New(8));
  String& field_name = String::Handle();
  PassiveObject& field_value = PassiveObject::Handle();
  // Iterate over fields in class hierarchy to count all instance fields.
  while (!cls.IsNull()) {
    fields = cls.fields();
    for (intptr_t i = 0; i < fields.Length(); i++) {
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
  PassiveObject& field_value = PassiveObject::Handle();
  for (intptr_t i = 0; i < fields.Length(); i++) {
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
  String& field_name = String::Handle(isolate_);
  PassiveObject& field_value = PassiveObject::Handle(isolate_);
  while (it.HasNext()) {
    entry = it.GetNext();
    if (entry.IsField()) {
      field ^= entry.raw();
      ASSERT(field.is_static());
      field_name = field.name();
      if ((field_name.CharAt(0) == '_') && !include_private_fields) {
        // Skip library-private field.
        continue;
      }
      // If the field is not initialized yet, report the value to be
      // "<not initialized>". We don't want to execute the implicit getter
      // since it may have side effects.
      if ((field.value() == Object::sentinel().raw()) ||
          (field.value() == Object::transition_sentinel().raw())) {
        field_value = Symbols::NotInitialized().raw();
      } else {
        field_value = field.value();
      }
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
  for (intptr_t i = 0; i < num_imports; i++) {
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
    for (int32_t i = 0; i < prefix.num_imports(); i++) {
      imported = prefix.GetLibrary(i);
      CollectLibraryFields(field_list, imported, prefix_name, false);
    }
  }
  return Array::MakeArray(field_list);
}


// static
void Debugger::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  ASSERT(visitor != NULL);
  BreakpointLocation* bpt = breakpoint_locations_;
  while (bpt != NULL) {
    bpt->VisitObjectPointers(visitor);
    bpt = bpt->next();
  }
  bpt = latent_locations_;
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


// static
void Debugger::SetEventHandler(EventHandler* handler) {
  event_handler_ = handler;
}


void Debugger::Pause(DebuggerEvent* event) {
  ASSERT(!IsPaused());  // No recursive pausing.
  ASSERT(obj_cache_ == NULL);

  pause_event_ = event;
  obj_cache_ = new RemoteObjectCache(64);

  InvokeEventHandler(event);

  pause_event_ = NULL;
  obj_cache_ = NULL;    // Zone allocated
}


void Debugger::HandleSteppingRequest(DebuggerStackTrace* stack_trace) {
  stepping_fp_ = 0;
  if (resume_action_ == kSingleStep) {
    // When single stepping, we need to deoptimize because we might be
    // stepping into optimized code.  This happens in particular if
    // the isolate has been interrupted, but can happen in other cases
    // as well.  We need to deoptimize the world in case we are about
    // to call an optimized function.
    DeoptimizeWorld();
    isolate_->set_single_step(true);
  } else if (resume_action_ == kStepOver) {
    DeoptimizeWorld();
    isolate_->set_single_step(true);
    ASSERT(stack_trace->Length() > 0);
    stepping_fp_ = stack_trace->FrameAt(0)->fp();
  } else if (resume_action_ == kStepOut) {
    DeoptimizeWorld();
    isolate_->set_single_step(true);
    // Find topmost caller that is debuggable.
    for (intptr_t i = 1; i < stack_trace->Length(); i++) {
      ActivationFrame* frame = stack_trace->FrameAt(i);
      if (frame->IsDebuggable()) {
        stepping_fp_ = frame->fp();
        break;
      }
    }
  }
  if (!isolate_->single_step()) {
    // We are no longer single stepping, make sure that the ThreadInterrupter
    // is awake.
    ThreadInterrupter::WakeUp();
  }
}


// static
bool Debugger::IsDebuggable(const Function& func) {
  if (!func.is_debuggable()) {
    return false;
  }
  if (ServiceIsolate::IsRunning()) {
    return true;
  }
  const Class& cls = Class::Handle(func.Owner());
  const Library& lib = Library::Handle(cls.library());
  return lib.IsDebuggable();
}


void Debugger::SignalPausedEvent(ActivationFrame* top_frame,
                                 Breakpoint* bpt) {
  resume_action_ = kContinue;
  stepping_fp_ = 0;
  isolate_->set_single_step(false);
  ASSERT(!IsPaused());
  ASSERT(obj_cache_ == NULL);
  if ((bpt != NULL) && bpt->IsSingleShot())  {
    RemoveBreakpoint(bpt->id());
    bpt = NULL;
  }

  DebuggerEvent event(isolate_, DebuggerEvent::kBreakpointReached);
  event.set_top_frame(top_frame);
  event.set_breakpoint(bpt);
  Object& closure_or_null = Object::Handle(top_frame->GetAsyncOperation());
  event.set_async_continuation(&closure_or_null);
  Pause(&event);
}


void Debugger::DebuggerStepCallback() {
  ASSERT(isolate_->single_step());
  // We can't get here unless the debugger event handler enabled
  // single stepping.
  ASSERT(HasEventHandler());
  // Don't pause recursively.
  if (IsPaused()) return;

  // Check whether we are in a Dart function that the user is
  // interested in. If we saved the frame pointer of a stack frame
  // the user is interested in, we ignore the single step if we are
  // in a callee of that frame. Note that we assume that the stack
  // grows towards lower addresses.
  ActivationFrame* frame = TopDartFrame();
  ASSERT(frame != NULL);

  if (stepping_fp_ != 0) {
    // There is an "interesting frame" set. Only pause at appropriate
    // locations in this frame.
    if (stepping_fp_ > frame->fp()) {
      // We are in a callee of the frame we're interested in.
      // Ignore this stepping break.
      return;
    } else if (frame->fp() > stepping_fp_) {
      // We returned from the "interesting frame", there can be no more
      // stepping breaks for it. Pause at the next appropriate location
      // and let the user set the "interesting" frame again.
      stepping_fp_ = 0;
    }
  }

  if (!frame->IsDebuggable()) {
    return;
  }
  if (frame->TokenPos() == Scanner::kNoSourcePos) {
    return;
  }

  // Don't pause for a single step if there is a breakpoint set
  // at this location.
  if (HasActiveBreakpoint(frame->pc())) {
    return;
  }

  if (FLAG_verbose_debug) {
    OS::Print(">>> single step break at %s:%" Pd " (func %s token %" Pd ")\n",
              String::Handle(frame->SourceUrl()).ToCString(),
              frame->LineNumber(),
              String::Handle(frame->QualifiedFunctionName()).ToCString(),
              frame->TokenPos());
  }

  ASSERT(stack_trace_ == NULL);
  stack_trace_ = CollectStackTrace();
  SignalPausedEvent(frame, NULL);
  HandleSteppingRequest(stack_trace_);
  stack_trace_ = NULL;
}


void Debugger::SignalBpReached() {
  // We ignore this breakpoint when the VM is executing code invoked
  // by the debugger to evaluate variables values, or when we see a nested
  // breakpoint or exception event.
  if (ignore_breakpoints_ || IsPaused() || !HasEventHandler()) {
    return;
  }
  DebuggerStackTrace* stack_trace = CollectStackTrace();
  ASSERT(stack_trace->Length() > 0);
  ActivationFrame* top_frame = stack_trace->FrameAt(0);
  ASSERT(top_frame != NULL);
  CodeBreakpoint* cbpt = GetCodeBreakpoint(top_frame->pc());
  ASSERT(cbpt != NULL);

  BreakpointLocation* bpt_location = cbpt->bpt_location_;
  Breakpoint* bpt_hit = NULL;

  // There may be more than one applicable breakpoint at this location, but we
  // will report only one as reached. If there is a single-shot breakpoint, we
  // favor it; then a closure-specific breakpoint ; then an general breakpoint.
  if (bpt_location != NULL) {
    Breakpoint* bpt = bpt_location->breakpoints();
    while (bpt != NULL) {
      if (bpt->IsSingleShot()) {
        bpt_hit = bpt;
        break;
      }
      bpt = bpt->next();
    }

    if (bpt_hit == NULL) {
      bpt = bpt_location->breakpoints();
      while (bpt != NULL) {
        if (bpt->IsPerClosure()) {
          Object& closure = Object::Handle(top_frame->GetClosure());
          ASSERT(closure.IsInstance());
          ASSERT(Instance::Cast(closure).IsClosure());
          if (closure.raw() == bpt->closure()) {
            bpt_hit = bpt;
            break;
          }
        }
        bpt = bpt->next();
      }
    }

    if (bpt_hit == NULL) {
      bpt = bpt_location->breakpoints();
      while (bpt != NULL) {
        if (bpt->IsRepeated()) {
          bpt_hit = bpt;
          break;
        }
        bpt = bpt->next();
      }
    }
  }

  if (bpt_hit == NULL) {
    return;
  }

  if (FLAG_verbose_debug) {
    OS::Print(">>> hit %s breakpoint at %s:%" Pd " "
              "(token %" Pd ") (address %#" Px ")\n",
              cbpt->IsInternal() ? "internal" : "user",
              String::Handle(cbpt->SourceUrl()).ToCString(),
              cbpt->LineNumber(),
              cbpt->token_pos(),
              top_frame->pc());
  }

  ASSERT(stack_trace_ == NULL);
  stack_trace_ = stack_trace;
  SignalPausedEvent(top_frame, bpt_hit);
  HandleSteppingRequest(stack_trace_);
  stack_trace_ = NULL;
  if (cbpt->IsInternal()) {
    RemoveInternalBreakpoints();
  }
}


void Debugger::BreakHere(const String& msg) {
  // We ignore this breakpoint when the VM is executing code invoked
  // by the debugger to evaluate variables values, or when we see a nested
  // breakpoint or exception event.
  if (ignore_breakpoints_ || IsPaused() || !HasEventHandler()) {
    return;
  }

  DebuggerStackTrace* stack_trace = CollectStackTrace();
  ASSERT(stack_trace->Length() > 0);
  ASSERT(stack_trace_ == NULL);
  stack_trace_ = stack_trace;

  // TODO(johnmccutchan): Send |msg| to Observatory.

  // We are in the native call to Debugger_breakHere or Debugger_breakHereIf,
  // the developer gets a better experience by not seeing this call. To
  // accomplish this, we continue execution until the call exits (step out).
  SetStepOut();
  HandleSteppingRequest(stack_trace_);

  stack_trace_ = NULL;
}


void Debugger::Initialize(Isolate* isolate) {
  if (initialized_) {
    return;
  }
  isolate_ = isolate;

  // Use the isolate's control port as the isolate_id for debugging.
  // This port will be used as a unique ID to represent the isolate in the
  // debugger wire protocol messages.
  isolate_id_ = isolate->main_port();
  initialized_ = true;
}


void Debugger::NotifyIsolateCreated() {
  // Signal isolate creation event.
  if (!ServiceIsolate::IsServiceIsolateDescendant(isolate_)) {
    SignalIsolateEvent(DebuggerEvent::kIsolateCreated);
  }
}


// Return innermost closure contained in 'function' that contains
// the given token position.
RawFunction* Debugger::FindInnermostClosure(const Function& function,
                                            intptr_t token_pos) {
  const Class& owner = Class::Handle(isolate_, function.Owner());
  if (owner.closures() == GrowableObjectArray::null()) {
    return Function::null();
  }
  // Note that we need to check that the closure is in the same
  // script as the outer function. We could have closures originating
  // in mixin classes whose source code is contained in a different
  // script.
  const Script& outer_origin = Script::Handle(isolate_, function.script());
  const GrowableObjectArray& closures =
     GrowableObjectArray::Handle(isolate_, owner.closures());
  const intptr_t num_closures = closures.Length();
  Function& closure = Function::Handle(isolate_);
  Function& best_fit = Function::Handle(isolate_);
  for (intptr_t i = 0; i < num_closures; i++) {
    closure ^= closures.At(i);
    if ((function.token_pos() < closure.token_pos()) &&
        (closure.end_token_pos() < function.end_token_pos()) &&
        (closure.token_pos() <= token_pos) &&
        (token_pos <= closure.end_token_pos()) &&
        (closure.script() == outer_origin.raw())) {
      SelectBestFit(&best_fit, &closure);
    }
  }
  return best_fit.raw();
}


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
  Script& script = Script::Handle(isolate_);
  for (BreakpointLocation* loc = breakpoint_locations_;
      loc != NULL;
      loc = loc->next()) {
    script = loc->script();
    if (FunctionContains(func, script, loc->token_pos())) {
      Function& inner_function = Function::Handle(isolate_);
      inner_function = FindInnermostClosure(func, loc->token_pos());
      if (!inner_function.IsNull()) {
        // The local function of a function we just compiled cannot
        // be compiled already.
        ASSERT(!inner_function.HasCode());
        if (FLAG_verbose_debug) {
          OS::Print("Pending BP remains unresolved in inner function '%s'\n",
                    inner_function.ToFullyQualifiedCString());
        }
        continue;
      }

      // TODO(hausner): What should we do if function is optimized?
      // Can we deoptimize the function?
      ASSERT(!func.HasOptimizedCode());

      // There is no local function within func that contains the
      // breakpoint token position. Resolve the breakpoint if necessary
      // and set the code breakpoints.
      if (!loc->IsResolved()) {
        // Resolve source breakpoint in the newly compiled function.
        intptr_t bp_pos =
            ResolveBreakpointPos(func, loc->token_pos(), loc->end_token_pos());
        if (bp_pos < 0) {
          if (FLAG_verbose_debug) {
            OS::Print("Failed resolving breakpoint for function '%s'\n",
                      String::Handle(func.name()).ToCString());
          }
          continue;
        }
        intptr_t requested_pos = loc->token_pos();
        intptr_t requested_end_pos = loc->end_token_pos();
        loc->SetResolved(func, bp_pos);
        Breakpoint* bpt = loc->breakpoints();
        while (bpt != NULL) {
          if (FLAG_verbose_debug) {
            OS::Print("Resolved BP %" Pd " to pos %" Pd ", line %" Pd ", "
                      "function '%s' (requested range %" Pd "-%" Pd ")\n",
                      bpt->id(),
                      loc->token_pos(),
                      loc->LineNumber(),
                      func.ToFullyQualifiedCString(),
                      requested_pos,
                      requested_end_pos);
          }
          SignalBpResolved(bpt);
          SendServiceBreakpointEvent(ServiceEvent::kBreakpointResolved, bpt);
          bpt = bpt->next();
        }
      }
      ASSERT(loc->IsResolved());
      if (FLAG_verbose_debug) {
        Breakpoint* bpt = loc->breakpoints();
        while (bpt != NULL) {
          OS::Print("Setting breakpoint %" Pd " at line %" Pd " for %s '%s'\n",
                    bpt->id(),
                    loc->LineNumber(),
                    func.IsClosureFunction() ? "closure" : "function",
                    String::Handle(func.name()).ToCString());
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
  Library& lib = Library::Handle(isolate_);
  Script& script = Script::Handle(isolate_);
  String& url = String::Handle(isolate_);
  BreakpointLocation* loc = latent_locations_;
  BreakpointLocation* prev_loc = NULL;
  const GrowableObjectArray& libs =
      GrowableObjectArray::Handle(isolate_->object_store()->libraries());
  while (loc != NULL) {
    url = loc->url();
    bool found_match = false;
    for (intptr_t i = 0; i < libs.Length(); i++) {
      lib ^= libs.At(i);
      script = lib.LookupScript(url);
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
        intptr_t line_number = matched_loc->LineNumber();
        ASSERT(line_number >= 0);
        intptr_t first_token_pos, last_token_pos;
        script.TokenRangeAtLine(line_number, &first_token_pos, &last_token_pos);
        if ((first_token_pos < 0) ||
            (last_token_pos < 0)) {
          // Script does not contain the given line number or there are no
          // tokens on the line. Drop the breakpoint silently.
          Breakpoint* bpt = matched_loc->breakpoints();
          while (bpt != NULL) {
            if (FLAG_verbose_debug) {
              OS::Print("No code found at line %" Pd ": "
                        "dropping latent breakpoint %" Pd " in '%s'\n",
                        line_number,
                        bpt->id(),
                        url.ToCString());
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
              GetBreakpointLocation(script, first_token_pos);
          ASSERT(existing_loc == NULL);
          if (existing_loc == NULL) {
            // Create and register a new source breakpoint for the
            // latent breakpoint.
            BreakpointLocation* unresolved_loc =
                new BreakpointLocation(script,
                                       first_token_pos,
                                       last_token_pos);
            RegisterBreakpointLocation(unresolved_loc);

            // Move breakpoints over.
            Breakpoint* bpt = matched_loc->breakpoints();
            unresolved_loc->set_breakpoints(bpt);
            matched_loc->set_breakpoints(NULL);
            while (bpt != NULL) {
              bpt->set_bpt_location(unresolved_loc);
              if (FLAG_verbose_debug) {
                OS::Print("Converted latent breakpoint "
                          "%" Pd " in '%s' at line %" Pd "\n",
                          bpt->id(),
                          url.ToCString(),
                          line_number);
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
          OS::Print("No match found for latent breakpoint id "
                    "%" Pd " with url '%s'\n",
                    bpt->id(),
                    url.ToCString());
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
  CodeBreakpoint* bpt = GetCodeBreakpoint(pc);
  return (bpt != NULL) && (bpt->IsEnabled());
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


uword Debugger::GetPatchedStubAddress(uword breakpoint_address) {
  CodeBreakpoint* bpt = GetCodeBreakpoint(breakpoint_address);
  if (bpt != NULL) {
    return bpt->OrigStubAddress();
  }
  UNREACHABLE();
  return 0L;
}


// Remove and delete the source breakpoint bpt and its associated
// code breakpoints.
void Debugger::RemoveBreakpoint(intptr_t bp_id) {
  BreakpointLocation* prev_loc = NULL;
  BreakpointLocation* curr_loc = breakpoint_locations_;
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

        SendServiceBreakpointEvent(ServiceEvent::kBreakpointRemoved, curr_bpt);

        // Remove references from the current debugger pause event.
        if (pause_event_ != NULL &&
            pause_event_->type() == DebuggerEvent::kBreakpointReached &&
            pause_event_->breakpoint() == curr_bpt) {
          pause_event_->set_breakpoint(NULL);
        }
        return;
      }

      prev_bpt = curr_bpt;
      curr_bpt = curr_bpt->next();
    }

    if (curr_loc->breakpoints() == NULL) {
      if (prev_loc == NULL) {
        breakpoint_locations_ = curr_loc->next();
      } else {
        prev_loc->set_next(curr_loc->next());
      }

      // Remove references from code breakpoints to this source breakpoint,
      // and disable the code breakpoints.
      UnlinkCodeBreakpoints(curr_loc);
      BreakpointLocation* next_loc = curr_loc->next();
      delete curr_loc;
      curr_loc = next_loc;
    } else {
      prev_loc = curr_loc;
      curr_loc = curr_loc->next();
    }
  }
  // bpt is not a registered breakpoint, nothing to do.
}


// Turn code breakpoints associated with the given source breakpoint into
// internal breakpoints. They will later be deleted when control
// returns from the user-defined breakpoint callback. Also, disable the
// breakpoint so it no longer fires if it should be hit before it gets
// deleted.
void Debugger::UnlinkCodeBreakpoints(BreakpointLocation* bpt_location) {
  ASSERT(bpt_location != NULL);
  CodeBreakpoint* curr_bpt = code_breakpoints_;
  while (curr_bpt != NULL) {
    if (curr_bpt->bpt_location() == bpt_location) {
      curr_bpt->Disable();
      curr_bpt->set_bpt_location(NULL);
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
}


BreakpointLocation* Debugger::GetBreakpointLocation(const Script& script,
                                                    intptr_t token_pos) {
  BreakpointLocation* bpt = breakpoint_locations_;
  while (bpt != NULL) {
    if ((bpt->script_ == script.raw()) && (bpt->token_pos_ == token_pos)) {
      return bpt;
    }
    bpt = bpt->next();
  }
  return NULL;
}


Breakpoint* Debugger::GetBreakpointById(intptr_t id) {
  BreakpointLocation* loc = breakpoint_locations_;
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


BreakpointLocation* Debugger::GetLatentBreakpoint(const String& url,
                                                  intptr_t line) {
  BreakpointLocation* bpt = latent_locations_;
  String& bpt_url = String::Handle(isolate_);
  while (bpt != NULL) {
    bpt_url = bpt->url();
    if (bpt_url.Equals(url) && (bpt->LineNumber() == line)) {
      return bpt;
    }
    bpt = bpt->next();
  }
  // No breakpint for this url and line requested. Allocate new one.
  bpt = new BreakpointLocation(url, line);
  bpt->set_next(latent_locations_);
  latent_locations_ = bpt;
  return bpt;
}


void Debugger::RegisterBreakpointLocation(BreakpointLocation* bpt) {
  ASSERT(bpt->next() == NULL);
  bpt->set_next(breakpoint_locations_);
  breakpoint_locations_ = bpt;
}


void Debugger::RegisterCodeBreakpoint(CodeBreakpoint* bpt) {
  ASSERT(bpt->next() == NULL);
  bpt->set_next(code_breakpoints_);
  code_breakpoints_ = bpt;
}

}  // namespace dart
