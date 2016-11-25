// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_DEBUGGER_H_
#define RUNTIME_VM_DEBUGGER_H_

#include "include/dart_tools_api.h"

#include "vm/object.h"
#include "vm/port.h"
#include "vm/service_event.h"

namespace dart {

class CodeBreakpoint;
class Isolate;
class JSONArray;
class JSONStream;
class ObjectPointerVisitor;
class RemoteObjectCache;
class BreakpointLocation;
class StackFrame;

// A user-defined breakpoint, which either fires once, for a particular closure,
// or always. The API's notion of a breakpoint corresponds to this object.
class Breakpoint {
 public:
  Breakpoint(intptr_t id, BreakpointLocation* bpt_location)
      : id_(id),
        kind_(Breakpoint::kNone),
        next_(NULL),
        closure_(Instance::null()),
        bpt_location_(bpt_location),
        is_synthetic_async_(false) {}

  intptr_t id() const { return id_; }
  Breakpoint* next() const { return next_; }
  void set_next(Breakpoint* n) { next_ = n; }

  BreakpointLocation* bpt_location() const { return bpt_location_; }
  void set_bpt_location(BreakpointLocation* new_bpt_location);

  bool IsRepeated() const { return kind_ == kRepeated; }
  bool IsSingleShot() const { return kind_ == kSingleShot; }
  bool IsPerClosure() const { return kind_ == kPerClosure; }
  RawInstance* closure() const { return closure_; }

  void SetIsRepeated() {
    ASSERT(kind_ == kNone);
    kind_ = kRepeated;
  }

  void SetIsSingleShot() {
    ASSERT(kind_ == kNone);
    kind_ = kSingleShot;
  }

  void SetIsPerClosure(const Instance& closure) {
    ASSERT(kind_ == kNone);
    kind_ = kPerClosure;
    closure_ = closure.raw();
  }

  // Mark that this breakpoint is a result of a step OverAwait request.
  void set_is_synthetic_async(bool is_synthetic_async) {
    is_synthetic_async_ = is_synthetic_async;
  }
  bool is_synthetic_async() const { return is_synthetic_async_; }

  void PrintJSON(JSONStream* stream);

 private:
  void VisitObjectPointers(ObjectPointerVisitor* visitor);

  enum ConditionKind {
    kNone,
    kRepeated,
    kSingleShot,
    kPerClosure,
  };

  intptr_t id_;
  ConditionKind kind_;
  Breakpoint* next_;
  RawInstance* closure_;
  BreakpointLocation* bpt_location_;
  bool is_synthetic_async_;

  friend class BreakpointLocation;
  DISALLOW_COPY_AND_ASSIGN(Breakpoint);
};


// BreakpointLocation represents a collection of breakpoint conditions at the
// same token position in Dart source. There may be more than one CodeBreakpoint
// object per BreakpointLocation.
// An unresolved breakpoint is one where the underlying code has not
// been compiled yet. Since the code has not been compiled, we don't know
// the definitive source location yet. The requested source location may
// change when the underlying code gets compiled.
// A latent breakpoint represents a breakpoint location in Dart source
// that is not loaded in the VM when the breakpoint is requested.
// When a script with matching url is loaded, a latent breakpoint
// becomes an unresolved breakpoint.
class BreakpointLocation {
 public:
  // Create a new unresolved breakpoint.
  BreakpointLocation(const Script& script,
                     TokenPosition token_pos,
                     TokenPosition end_token_pos,
                     intptr_t requested_line_number,
                     intptr_t requested_column_number);
  // Create a new latent breakpoint.
  BreakpointLocation(const String& url,
                     intptr_t requested_line_number,
                     intptr_t requested_column_number);

  ~BreakpointLocation();

  RawFunction* function() const { return function_; }
  TokenPosition token_pos() const { return token_pos_; }
  TokenPosition end_token_pos() const { return end_token_pos_; }

  RawScript* script() const { return script_; }
  RawString* url() const { return url_; }

  intptr_t requested_line_number() const { return requested_line_number_; }
  intptr_t requested_column_number() const { return requested_column_number_; }

  intptr_t LineNumber();
  intptr_t ColumnNumber();

  void GetCodeLocation(Library* lib,
                       Script* script,
                       TokenPosition* token_pos) const;

  Breakpoint* AddRepeated(Debugger* dbg);
  Breakpoint* AddSingleShot(Debugger* dbg);
  Breakpoint* AddPerClosure(Debugger* dbg,
                            const Instance& closure,
                            bool for_over_await);

  bool AnyEnabled() const;
  bool IsResolved() const { return is_resolved_; }
  bool IsLatent() const { return !token_pos_.IsReal(); }

 private:
  void VisitObjectPointers(ObjectPointerVisitor* visitor);

  void SetResolved(const Function& func, TokenPosition token_pos);

  BreakpointLocation* next() const { return this->next_; }
  void set_next(BreakpointLocation* value) { next_ = value; }

  void AddBreakpoint(Breakpoint* bpt, Debugger* dbg);

  Breakpoint* breakpoints() const { return this->conditions_; }
  void set_breakpoints(Breakpoint* head) { this->conditions_ = head; }

  RawScript* script_;
  RawString* url_;
  TokenPosition token_pos_;
  TokenPosition end_token_pos_;
  bool is_resolved_;
  BreakpointLocation* next_;
  Breakpoint* conditions_;
  intptr_t requested_line_number_;
  intptr_t requested_column_number_;

  // Valid for resolved breakpoints:
  RawFunction* function_;
  intptr_t line_number_;
  intptr_t column_number_;

  friend class Debugger;
  DISALLOW_COPY_AND_ASSIGN(BreakpointLocation);
};


// CodeBreakpoint represents a location in compiled code. There may be
// more than one CodeBreakpoint for one BreakpointLocation, e.g. when a
// function gets compiled as a regular function and as a closure.
class CodeBreakpoint {
 public:
  CodeBreakpoint(const Code& code,
                 TokenPosition token_pos,
                 uword pc,
                 RawPcDescriptors::Kind kind);
  ~CodeBreakpoint();

  RawFunction* function() const;
  uword pc() const { return pc_; }
  TokenPosition token_pos() const { return token_pos_; }
  bool IsInternal() const { return bpt_location_ == NULL; }

  RawScript* SourceCode();
  RawString* SourceUrl();
  intptr_t LineNumber();

  void Enable();
  void Disable();
  bool IsEnabled() const { return is_enabled_; }

  RawCode* OrigStubAddress() const;

 private:
  void VisitObjectPointers(ObjectPointerVisitor* visitor);

  BreakpointLocation* bpt_location() const { return bpt_location_; }
  void set_bpt_location(BreakpointLocation* value) { bpt_location_ = value; }

  void set_next(CodeBreakpoint* value) { next_ = value; }
  CodeBreakpoint* next() const { return this->next_; }

  void PatchCode();
  void RestoreCode();

  RawCode* code_;
  TokenPosition token_pos_;
  uword pc_;
  intptr_t line_number_;
  bool is_enabled_;

  BreakpointLocation* bpt_location_;
  CodeBreakpoint* next_;

  RawPcDescriptors::Kind breakpoint_kind_;
#if !defined(TARGET_ARCH_DBC)
  RawCode* saved_value_;
#else
  // When running on the DBC interpreter we patch bytecode in place with
  // DebugBreak. This is an instruction that was replaced. DebugBreak
  // will execute it after the breakpoint.
  Instr saved_value_;
  Instr saved_value_fastsmi_;
#endif

  friend class Debugger;
  DISALLOW_COPY_AND_ASSIGN(CodeBreakpoint);
};


// ActivationFrame represents one dart function activation frame
// on the call stack.
class ActivationFrame : public ZoneAllocated {
 public:
  ActivationFrame(uword pc,
                  uword fp,
                  uword sp,
                  const Code& code,
                  const Array& deopt_frame,
                  intptr_t deopt_frame_offset);

  uword pc() const { return pc_; }
  uword fp() const { return fp_; }
  uword sp() const { return sp_; }
  const Function& function() const {
    ASSERT(!function_.IsNull());
    return function_;
  }
  const Code& code() const {
    ASSERT(!code_.IsNull());
    return code_;
  }

  RawString* QualifiedFunctionName();
  RawString* SourceUrl();
  RawScript* SourceScript();
  RawLibrary* Library();
  TokenPosition TokenPos();
  intptr_t LineNumber();
  intptr_t ColumnNumber();

  // Returns true if this frame is for a function that is visible
  // to the user and can be debugged.
  bool IsDebuggable() const;

  // The context level of a frame is the context level at the
  // PC/token index of the frame. It determines the depth of the context
  // chain that belongs to the function of this activation frame.
  intptr_t ContextLevel();

  const char* ToCString();

  intptr_t NumLocalVariables();

  void VariableAt(intptr_t i,
                  String* name,
                  TokenPosition* declaration_token_pos,
                  TokenPosition* visible_start_token_pos,
                  TokenPosition* visible_end_token_pos,
                  Object* value);

  RawArray* GetLocalVariables();
  RawObject* GetParameter(intptr_t index);
  RawObject* GetClosure();
  RawObject* GetReceiver();

  const Context& GetSavedCurrentContext();
  RawObject* GetAsyncOperation();

  RawObject* Evaluate(const String& expr);

  // Print the activation frame into |jsobj|. if |full| is false, script
  // and local variable objects are only references. if |full| is true,
  // the complete script, function, and, local variable objects are included.
  void PrintToJSONObject(JSONObject* jsobj, bool full = false);

 private:
  void PrintContextMismatchError(intptr_t ctx_slot,
                                 intptr_t frame_ctx_level,
                                 intptr_t var_ctx_level);

  intptr_t TryIndex();
  void GetPcDescriptors();
  void GetVarDescriptors();
  void GetDescIndices();

  RawObject* GetStackVar(intptr_t slot_index);
  RawObject* GetContextVar(intptr_t ctxt_level, intptr_t slot_index);

  uword pc_;
  uword fp_;
  uword sp_;

  // The anchor of the context chain for this function.
  Context& ctx_;
  const Code& code_;
  const Function& function_;
  bool token_pos_initialized_;
  TokenPosition token_pos_;
  intptr_t try_index_;

  intptr_t line_number_;
  intptr_t column_number_;
  intptr_t context_level_;

  // Some frames are deoptimized into a side array in order to inspect them.
  const Array& deopt_frame_;
  const intptr_t deopt_frame_offset_;

  bool vars_initialized_;
  LocalVarDescriptors& var_descriptors_;
  ZoneGrowableArray<intptr_t> desc_indices_;
  PcDescriptors& pc_desc_;

  friend class Debugger;
  friend class DebuggerStackTrace;
  DISALLOW_COPY_AND_ASSIGN(ActivationFrame);
};


// Array of function activations on the call stack.
class DebuggerStackTrace : public ZoneAllocated {
 public:
  explicit DebuggerStackTrace(int capacity) : trace_(capacity) {}

  intptr_t Length() const { return trace_.length(); }

  ActivationFrame* FrameAt(int i) const { return trace_[i]; }

  ActivationFrame* GetHandlerFrame(const Instance& exc_obj) const;

 private:
  void AddActivation(ActivationFrame* frame);
  ZoneGrowableArray<ActivationFrame*> trace_;

  friend class Debugger;
  DISALLOW_COPY_AND_ASSIGN(DebuggerStackTrace);
};


class Debugger {
 public:
  typedef void EventHandler(ServiceEvent* event);

  Debugger();
  ~Debugger();

  void Initialize(Isolate* isolate);
  void NotifyIsolateCreated();
  void Shutdown();

  void NotifyCompilation(const Function& func);
  void NotifyDoneLoading();

  RawFunction* ResolveFunction(const Library& library,
                               const String& class_name,
                               const String& function_name);

  // Set breakpoint at closest location to function entry.
  Breakpoint* SetBreakpointAtEntry(const Function& target_function,
                                   bool single_shot);
  Breakpoint* SetBreakpointAtActivation(const Instance& closure,
                                        bool for_over_await);
  Breakpoint* BreakpointAtActivation(const Instance& closure);

  // TODO(turnidge): script_url may no longer be specific enough.
  Breakpoint* SetBreakpointAtLine(const String& script_url,
                                  intptr_t line_number);
  Breakpoint* SetBreakpointAtLineCol(const String& script_url,
                                     intptr_t line_number,
                                     intptr_t column_number);
  RawError* OneTimeBreakAtEntry(const Function& target_function);

  BreakpointLocation* BreakpointLocationAtLineCol(const String& script_url,
                                                  intptr_t line_number,
                                                  intptr_t column_number);


  void RemoveBreakpoint(intptr_t bp_id);
  Breakpoint* GetBreakpointById(intptr_t id);

  // Will return false if we are not at an await.
  bool SetupStepOverAsyncSuspension();
  void SetStepOver();
  void SetSingleStep();
  void SetStepOut();
  bool IsStepping() const { return resume_action_ != kContinue; }

  bool IsPaused() const { return pause_event_ != NULL; }

  // Put the isolate into single stepping mode when Dart code next runs.
  //
  // This is used by the vm service to allow the user to step while
  // paused at isolate start.
  void EnterSingleStepMode();

  // Indicates why the debugger is currently paused.  If the debugger
  // is not paused, this returns NULL.  Note that the debugger can be
  // paused for breakpoints, isolate interruption, and (sometimes)
  // exceptions.
  const ServiceEvent* PauseEvent() const { return pause_event_; }

  void SetExceptionPauseInfo(Dart_ExceptionPauseInfo pause_info);
  Dart_ExceptionPauseInfo GetExceptionPauseInfo() const;

  void VisitObjectPointers(ObjectPointerVisitor* visitor);

  // Called from Runtime when a breakpoint in Dart code is reached.
  void BreakpointCallback();

  // Returns true if there is at least one breakpoint set in func or code.
  // Checks for both user-defined and internal temporary breakpoints.
  // This may be called from different threads, therefore do not use the,
  // debugger's zone.
  bool HasBreakpoint(const Function& func, Zone* zone);
  bool HasBreakpoint(const Code& code);

  // Returns true if the call at address pc is patched to point to
  // a debugger stub.
  bool HasActiveBreakpoint(uword pc);

  // Returns a stack trace with frames corresponding to invisible functions
  // omitted. CurrentStackTrace always returns a new trace on the current stack.
  // The trace returned by StackTrace may have been cached; it is suitable for
  // use when stepping, but otherwise may be out of sync with the current stack.
  DebuggerStackTrace* StackTrace();
  DebuggerStackTrace* CurrentStackTrace();

  // Returns a debugger stack trace corresponding to a dart.core.Stacktrace.
  // Frames corresponding to invisible functions are omitted. It is not valid
  // to query local variables in the returned stack.
  DebuggerStackTrace* StackTraceFrom(const Stacktrace& dart_stacktrace);

  RawArray* GetInstanceFields(const Instance& obj);
  RawArray* GetStaticFields(const Class& cls);
  RawArray* GetLibraryFields(const Library& lib);
  RawArray* GetGlobalFields(const Library& lib);

  intptr_t CacheObject(const Object& obj);
  RawObject* GetCachedObject(intptr_t obj_id);
  bool IsValidObjectId(intptr_t obj_id);

  Dart_Port GetIsolateId() { return isolate_id_; }

  static void SetEventHandler(EventHandler* handler);

  // Utility functions.
  static const char* QualifiedFunctionName(const Function& func);

  RawObject* GetInstanceField(const Class& cls,
                              const String& field_name,
                              const Instance& object);
  RawObject* GetStaticField(const Class& cls, const String& field_name);

  // Pause execution for a breakpoint.  Called from generated code.
  RawError* PauseBreakpoint();

  // Pause execution due to stepping.  Called from generated code.
  RawError* PauseStepping();

  // Pause execution due to isolate interrupt.
  RawError* PauseInterrupted();

  // Pause after a reload request.
  RawError* PausePostRequest();

  // Pause execution due to an uncaught exception.
  void PauseException(const Instance& exc);

  // Pause execution due to a call to the debugger() function from
  // Dart.
  void PauseDeveloper(const String& msg);

  RawCode* GetPatchedStubAddress(uword breakpoint_address);

  void PrintBreakpointsToJSONArray(JSONArray* jsarr) const;
  void PrintSettingsToJSONObject(JSONObject* jsobj) const;

  static bool IsDebuggable(const Function& func);

  intptr_t limitBreakpointId() { return next_id_; }

 private:
  enum ResumeAction { kContinue, kStepOver, kStepOut, kSingleStep };

  RawError* PauseRequest(ServiceEvent::EventKind kind);

  bool NeedsIsolateEvents();
  bool NeedsDebugEvents();
  void InvokeEventHandler(ServiceEvent* event);

  void SendBreakpointEvent(ServiceEvent::EventKind kind, Breakpoint* bpt);

  bool IsAtAsyncJump(ActivationFrame* top_frame);
  void FindCompiledFunctions(const Script& script,
                             TokenPosition start_pos,
                             TokenPosition end_pos,
                             GrowableObjectArray* function_list);
  RawFunction* FindBestFit(const Script& script, TokenPosition token_pos);
  RawFunction* FindInnermostClosure(const Function& function,
                                    TokenPosition token_pos);
  TokenPosition ResolveBreakpointPos(const Function& func,
                                     TokenPosition requested_token_pos,
                                     TokenPosition last_token_pos,
                                     intptr_t requested_column);
  void DeoptimizeWorld();
  BreakpointLocation* SetBreakpoint(const Script& script,
                                    TokenPosition token_pos,
                                    TokenPosition last_token_pos,
                                    intptr_t requested_line,
                                    intptr_t requested_column);
  void RemoveInternalBreakpoints();
  void UnlinkCodeBreakpoints(BreakpointLocation* bpt_location);
  BreakpointLocation* GetLatentBreakpoint(const String& url,
                                          intptr_t line,
                                          intptr_t column);
  void RegisterBreakpointLocation(BreakpointLocation* bpt);
  void RegisterCodeBreakpoint(CodeBreakpoint* bpt);
  BreakpointLocation* GetBreakpointLocation(const Script& script,
                                            TokenPosition token_pos,
                                            intptr_t requested_column);
  void MakeCodeBreakpointAt(const Function& func, BreakpointLocation* bpt);
  // Returns NULL if no breakpoint exists for the given address.
  CodeBreakpoint* GetCodeBreakpoint(uword breakpoint_address);

  void SyncBreakpointLocation(BreakpointLocation* loc);

  ActivationFrame* TopDartFrame() const;
  static ActivationFrame* CollectDartFrame(Isolate* isolate,
                                           uword pc,
                                           StackFrame* frame,
                                           const Code& code,
                                           const Array& deopt_frame,
                                           intptr_t deopt_frame_offset);
  static RawArray* DeoptimizeToArray(Thread* thread,
                                     StackFrame* frame,
                                     const Code& code);
  static DebuggerStackTrace* CollectStackTrace();
  void SignalPausedEvent(ActivationFrame* top_frame, Breakpoint* bpt);

  intptr_t nextId() { return next_id_++; }

  bool ShouldPauseOnException(DebuggerStackTrace* stack_trace,
                              const Instance& exc);

  void CollectLibraryFields(const GrowableObjectArray& field_list,
                            const Library& lib,
                            const String& prefix,
                            bool include_private_fields);

  // Handles any events which pause vm execution.  Breakpoints,
  // interrupts, etc.
  void Pause(ServiceEvent* event);

  void HandleSteppingRequest(DebuggerStackTrace* stack_trace,
                             bool skip_next_step = false);

  Isolate* isolate_;
  Dart_Port isolate_id_;  // A unique ID for the isolate in the debugger.
  bool initialized_;

  // ID number generator.
  intptr_t next_id_;

  BreakpointLocation* latent_locations_;
  BreakpointLocation* breakpoint_locations_;
  CodeBreakpoint* code_breakpoints_;

  // Tells debugger what to do when resuming execution after a breakpoint.
  ResumeAction resume_action_;

  // Do not call back to breakpoint handler if this flag is set.
  // Effectively this means ignoring breakpoints. Set when Dart code may
  // be run as a side effect of getting values of fields.
  bool ignore_breakpoints_;

  // Indicates why the debugger is currently paused.  If the debugger
  // is not paused, this is NULL.  Note that the debugger can be
  // paused for breakpoints, isolate interruption, and (sometimes)
  // exceptions.
  ServiceEvent* pause_event_;

  // An id -> object map.  Valid only while IsPaused().
  RemoteObjectCache* obj_cache_;

  // Current stack trace. Valid only while IsPaused().
  DebuggerStackTrace* stack_trace_;

  // When stepping through code, only pause the program if the top
  // frame corresponds to this fp value, or if the top frame is
  // lower on the stack.
  uword stepping_fp_;

  // If we step while at a breakpoint, we would hit the same pc twice.
  // We use this field to let us skip the next single-step after a
  // breakpoint.
  bool skip_next_step_;

  // We keep this breakpoint alive until after the debugger does the step over
  // async continuation machinery so that we can report that we've stopped
  // at the breakpoint.
  Breakpoint* synthetic_async_breakpoint_;

  Dart_ExceptionPauseInfo exc_pause_info_;

  static EventHandler* event_handler_;

  friend class Isolate;
  friend class BreakpointLocation;
  DISALLOW_COPY_AND_ASSIGN(Debugger);
};


}  // namespace dart

#endif  // RUNTIME_VM_DEBUGGER_H_
