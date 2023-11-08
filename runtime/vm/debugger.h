// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_DEBUGGER_H_
#define RUNTIME_VM_DEBUGGER_H_

#include <memory>

#include "include/dart_tools_api.h"

#include "vm/compiler/api/deopt_id.h"
#include "vm/kernel_isolate.h"
#include "vm/object.h"
#include "vm/port.h"
#include "vm/scopes.h"
#include "vm/service_event.h"
#include "vm/simulator.h"
#include "vm/stack_frame.h"
#include "vm/stack_trace.h"

#if !defined(PRODUCT)

DECLARE_FLAG(bool, verbose_debug);

// 'Trace Debugger' TD_Print.
#if defined(_MSC_VER)
#define TD_Print(format, ...)                                                  \
  if (FLAG_verbose_debug) Log::Current()->Print(format, __VA_ARGS__)
#else
#define TD_Print(format, ...)                                                  \
  if (FLAG_verbose_debug) Log::Current()->Print(format, ##__VA_ARGS__)
#endif

namespace dart {

class CodeBreakpoint;
class Isolate;
class JSONArray;
class JSONStream;
class ObjectPointerVisitor;
class BreakpointLocation;
class StackFrame;

// A user-defined breakpoint, which can be set for a particular closure
// (if |closure| is not |null|) and can fire one (|is_single_shot| is |true|)
// or many times.
class Breakpoint {
 public:
  Breakpoint(intptr_t id,
             BreakpointLocation* bpt_location,
             bool is_single_shot,
             const Closure& closure)
      : id_(id),
        next_(nullptr),
        closure_(closure.ptr()),
        bpt_location_(bpt_location),
        is_single_shot_(is_single_shot) {}

  intptr_t id() const { return id_; }
  Breakpoint* next() const { return next_; }
  void set_next(Breakpoint* n) { next_ = n; }

  BreakpointLocation* bpt_location() const { return bpt_location_; }
  void set_bpt_location(BreakpointLocation* new_bpt_location);

  bool is_single_shot() const { return is_single_shot_; }
  ClosurePtr closure() const { return closure_; }

  void Enable() {
    ASSERT(!enabled_);
    enabled_ = true;
  }

  void Disable() {
    ASSERT(enabled_);
    enabled_ = false;
  }

  bool is_enabled() const { return enabled_; }

  void PrintJSON(JSONStream* stream);

 private:
  void VisitObjectPointers(ObjectPointerVisitor* visitor);

  intptr_t id_;
  Breakpoint* next_;
  ClosurePtr closure_;
  BreakpointLocation* bpt_location_;
  bool is_single_shot_;
  bool enabled_ = false;

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
  BreakpointLocation(Debugger* debugger,
                     const GrowableHandlePtrArray<const Script>& scripts,
                     TokenPosition token_pos,
                     TokenPosition end_token_pos,
                     intptr_t requested_line_number,
                     intptr_t requested_column_number);
  // Create a new latent breakpoint.
  BreakpointLocation(Debugger* debugger,
                     const String& url,
                     intptr_t requested_line_number,
                     intptr_t requested_column_number);

  ~BreakpointLocation();

  TokenPosition token_pos() const { return token_pos_.load(); }
  intptr_t line_number();
  TokenPosition end_token_pos() const { return end_token_pos_.load(); }

  ScriptPtr script() const {
    if (scripts_.length() == 0) {
      return Script::null();
    }
    return scripts_.At(0);
  }
  StringPtr url() const { return url_; }

  intptr_t requested_line_number() const { return requested_line_number_; }
  intptr_t requested_column_number() const { return requested_column_number_; }

  void GetCodeLocation(Script* script, TokenPosition* token_pos) const;

  Breakpoint* AddRepeated(Debugger* dbg);
  Breakpoint* AddSingleShot(Debugger* dbg);
  Breakpoint* AddBreakpoint(Debugger* dbg,
                            const Closure& closure,
                            bool single_shot);

  bool AnyEnabled() const;
  bool IsResolved() const { return code_token_pos_.IsReal(); }
  bool IsLatent() const { return !token_pos().IsReal(); }

  bool EnsureIsResolved(const Function& target_function,
                        TokenPosition exact_token_pos);

  Debugger* debugger() { return debugger_; }

 private:
  void VisitObjectPointers(ObjectPointerVisitor* visitor);

  void SetResolved(const Function& func, TokenPosition token_pos);

  BreakpointLocation* next() const { return this->next_; }
  void set_next(BreakpointLocation* value) { next_ = value; }

  void AddBreakpoint(Breakpoint* bpt, Debugger* dbg);

  Breakpoint* breakpoints() const { return this->conditions_; }
  void set_breakpoints(Breakpoint* head) { this->conditions_ = head; }

  // Finds the breakpoint we hit at |location|.
  Breakpoint* FindHitBreakpoint(ActivationFrame* top_frame);

  SafepointRwLock* line_number_lock() { return line_number_lock_.get(); }

  Debugger* debugger_;
  MallocGrowableArray<ScriptPtr> scripts_;
  StringPtr url_;
  std::unique_ptr<SafepointRwLock> line_number_lock_;
  intptr_t line_number_;  // lazily computed for token_pos_
  std::atomic<TokenPosition> token_pos_;
  std::atomic<TokenPosition> end_token_pos_;
  BreakpointLocation* next_;
  Breakpoint* conditions_;
  intptr_t requested_line_number_;
  intptr_t requested_column_number_;

  // Valid for resolved breakpoints:
  TokenPosition code_token_pos_;

  friend class Debugger;
  friend class GroupDebugger;
  DISALLOW_COPY_AND_ASSIGN(BreakpointLocation);
};

// CodeBreakpoint represents a location in compiled code.
// There may be more than one CodeBreakpoint for one BreakpointLocation,
// e.g. when a function gets compiled as a regular function and as a closure.
// There may be more than one BreakpointLocation associated with CodeBreakpoint,
// one for every isolate in a group that sets a breakpoint at particular
// code location represented by the CodeBreakpoint.
// Each BreakpointLocation might be enabled/disabled based on whether it has
// any actual breakpoints associated with it.
// The CodeBreakpoint is enabled if it has any such BreakpointLocations
// associated with it.
// The class is not thread-safe - users of this class need to ensure the access
// is synchronized, guarded by mutexes or run inside of a safepoint scope.
class CodeBreakpoint {
 public:
  // Unless CodeBreakpoint is unlinked and is no longer used there should be at
  // least one BreakpointLocation associated with CodeBreakpoint. If there are
  // more BreakpointLocation added assumption is is that all of them point to
  // the same source so have the same token pos.
  CodeBreakpoint(const Code& code,
                 BreakpointLocation* loc,
                 uword pc,
                 UntaggedPcDescriptors::Kind kind);
  ~CodeBreakpoint();

  // Used by GroupDebugger to find CodeBreakpoint associated with
  // particular function.
  FunctionPtr function() const { return Code::Handle(code_).function(); }

  uword pc() const { return pc_; }
  bool HasBreakpointLocation(BreakpointLocation* breakpoint_location);
  bool FindAndDeleteBreakpointLocation(BreakpointLocation* breakpoint_location);
  bool HasNoBreakpointLocations() {
    return breakpoint_locations_.length() == 0;
  }

  void Enable();
  void Disable();
  bool IsEnabled() const { return enabled_count_ > 0; }

  CodePtr OrigStubAddress() const;

  const char* ToCString() const;

 private:
  void VisitObjectPointers(ObjectPointerVisitor* visitor);

  // Finds right BreakpointLocation for a given Isolate's debugger.
  BreakpointLocation* FindBreakpointForDebugger(Debugger* debugger);
  // Adds new BreakpointLocation for another isolate that wants to
  // break at the same function/code location that this CodeBreakpoint
  // represents.
  void AddBreakpointLocation(BreakpointLocation* breakpoint_location) {
    ASSERT(breakpoint_locations_.length() == 0 ||
           (breakpoint_location->token_pos() ==
                breakpoint_locations_.At(0)->token_pos() &&
            breakpoint_location->url() == breakpoint_locations_.At(0)->url()));
    breakpoint_locations_.Add(breakpoint_location);
  }

  void set_next(CodeBreakpoint* value) { next_ = value; }
  CodeBreakpoint* next() const { return this->next_; }

  void PatchCode();
  void RestoreCode();

  CodePtr code_;
  uword pc_;
  int enabled_count_;  // incremented for every enabled breakpoint location

  // Breakpoint locations from different debuggers/isolates that
  // point to this code breakpoint.
  MallocGrowableArray<BreakpointLocation*> breakpoint_locations_;
  CodeBreakpoint* next_;

  UntaggedPcDescriptors::Kind breakpoint_kind_;
  CodePtr saved_value_;

  friend class Debugger;
  friend class GroupDebugger;
  DISALLOW_COPY_AND_ASSIGN(CodeBreakpoint);
};

// ActivationFrame represents one dart function activation frame
// on the call stack.
class ActivationFrame : public ZoneAllocated {
 public:
  enum Kind {
    kRegular,
    kAsyncSuspensionMarker,
    kAsyncAwaiter,
  };

  ActivationFrame(uword pc,
                  uword fp,
                  uword sp,
                  const Code& code,
                  const Array& deopt_frame,
                  intptr_t deopt_frame_offset);

  // Create a |kAsyncAwaiter| frame representing asynchronous awaiter
  // waiting for the completion of a |Future|.
  //
  // |closure| is the listener which will be invoked when awaited
  // computation completes.
  ActivationFrame(uword pc, const Code& code, const Closure& closure);

  explicit ActivationFrame(Kind kind);

  Kind kind() const { return kind_; }

  uword pc() const { return pc_; }
  uword fp() const { return fp_; }
  uword sp() const { return sp_; }

  uword GetCallerSp() const { return fp() + (kCallerSpSlotFromFp * kWordSize); }

  // For |kAsyncAwaiter| frames this is the listener which will be invoked
  // when the frame below (callee) completes.
  const Closure& closure() const { return closure_; }

  const Function& function() const {
    return function_;
  }
  const Code& code() const {
    ASSERT(!code_.IsNull());
    return code_;
  }

  enum Relation {
    kCallee,
    kSelf,
    kCaller,
  };

  Relation CompareTo(uword other_fp) const;

  StringPtr QualifiedFunctionName();
  StringPtr SourceUrl();
  ScriptPtr SourceScript();
  LibraryPtr Library();
  TokenPosition TokenPos();
  intptr_t LineNumber();
  intptr_t ColumnNumber();

  // Returns true if this frame is for a function that is visible
  // to the user and can be debugged.
  bool IsDebuggable() const;

  // Returns true if it is possible to rewind the debugger to this frame.
  bool IsRewindable() const;

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

  ArrayPtr GetLocalVariables();
  ObjectPtr GetParameter(intptr_t index);
  ClosurePtr GetClosure();
  ObjectPtr GetReceiver();

  const Context& GetSavedCurrentContext();
  ObjectPtr GetSuspendStateVar();
  ObjectPtr GetSuspendableFunctionData();

  TypeArgumentsPtr BuildParameters(
      const GrowableObjectArray& param_names,
      const GrowableObjectArray& param_values,
      const GrowableObjectArray& type_params_names,
      const GrowableObjectArray& type_params_bounds,
      const GrowableObjectArray& type_params_defaults);

  ObjectPtr EvaluateCompiledExpression(const ExternalTypedData& kernel_data,
                                       const Array& arguments,
                                       const Array& type_definitions,
                                       const TypeArguments& type_arguments);

  void PrintToJSONObject(JSONObject* jsobj);

  bool HandlesException(const Instance& exc_obj);

  bool has_catch_error() const { return has_catch_error_; }
  void set_has_catch_error(bool value) { has_catch_error_ = value; }

 private:
  void PrintToJSONObjectRegular(JSONObject* jsobj);
  void PrintToJSONObjectAsyncAwaiter(JSONObject* jsobj);
  void PrintToJSONObjectAsyncSuspensionMarker(JSONObject* jsobj);
  void PrintContextMismatchError(intptr_t ctx_slot,
                                 intptr_t frame_ctx_level,
                                 intptr_t var_ctx_level);
  void PrintDescriptorsError(const char* message);

  intptr_t TryIndex();
  intptr_t DeoptId();
  void GetPcDescriptors();
  void GetVarDescriptors();
  void GetDescIndices();

  static const char* KindToCString(Kind kind) {
    switch (kind) {
      case kRegular:
        return "Regular";
      case kAsyncAwaiter:
        // Keeping the legacy name in the protocol itself.
        return "AsyncCausal";
      case kAsyncSuspensionMarker:
        return "AsyncSuspensionMarker";
      default:
        UNREACHABLE();
        return "";
    }
  }

  ObjectPtr GetStackVar(VariableIndex var_index);
  ObjectPtr GetRelativeContextVar(intptr_t ctxt_level,
                                  intptr_t slot_index,
                                  intptr_t frame_ctx_level);
  ObjectPtr GetContextVar(intptr_t ctxt_level, intptr_t slot_index);

  uword pc_ = 0;
  uword fp_ = 0;
  uword sp_ = 0;

  // The anchor of the context chain for this function.
  Context& ctx_ = Context::ZoneHandle();
  const Code& code_;
  const Function& function_;
  const Closure& closure_;

  bool token_pos_initialized_ = false;
  TokenPosition token_pos_ = TokenPosition::kNoSource;
  intptr_t try_index_ = -1;
  intptr_t deopt_id_ = dart::DeoptId::kNone;

  intptr_t line_number_ = -1;
  intptr_t column_number_ = -1;
  intptr_t context_level_ = -1;

  // Some frames are deoptimized into a side array in order to inspect them.
  const Array& deopt_frame_;
  const intptr_t deopt_frame_offset_;

  Kind kind_;

  bool vars_initialized_ = false;
  LocalVarDescriptors& var_descriptors_ = LocalVarDescriptors::ZoneHandle();
  ZoneGrowableArray<intptr_t> desc_indices_;
  PcDescriptors& pc_desc_ = PcDescriptors::ZoneHandle();

  bool has_catch_error_ = false;

  friend class Debugger;
  friend class DebuggerStackTrace;
  DISALLOW_COPY_AND_ASSIGN(ActivationFrame);
};

// Array of function activations on the call stack.
class DebuggerStackTrace : public ZoneAllocated {
 public:
  explicit DebuggerStackTrace(int capacity)
      : thread_(Thread::Current()), zone_(thread_->zone()), trace_(capacity) {}

  intptr_t Length() const { return trace_.length(); }

  ActivationFrame* FrameAt(int i) const { return trace_[i]; }

  ActivationFrame* GetHandlerFrame(const Instance& exc_obj) const;

  static DebuggerStackTrace* Collect();
  static DebuggerStackTrace* CollectAsyncAwaiters();

  // Returns a debugger stack trace corresponding to a dart.core.StackTrace.
  // Frames corresponding to invisible functions are omitted. It is not valid
  // to query local variables in the returned stack.
  static DebuggerStackTrace* From(const class StackTrace& ex_trace);

 private:
  void AddActivation(ActivationFrame* frame);
  void AddAsyncSuspension(bool has_catch_error);
  void AddAsyncAwaiterFrame(uword pc, const Code& code, const Closure& closure);

  void AppendCodeFrames(StackFrame* frame, const Code& code);

  Thread* thread_;
  Zone* zone_;
  Code& inlined_code_ = Code::Handle();
  Array& deopt_frame_ = Array::Handle();
  ZoneGrowableArray<ActivationFrame*> trace_;

  friend class Debugger;

  DISALLOW_COPY_AND_ASSIGN(DebuggerStackTrace);
};

// On which exceptions to pause.
typedef enum {
  kNoPauseOnExceptions = 1,
  kPauseOnUnhandledExceptions,
  kPauseOnAllExceptions,
  kInvalidExceptionPauseInfo
} Dart_ExceptionPauseInfo;

class DebuggerKeyValueTrait : public AllStatic {
 public:
  typedef const Debugger* Key;
  typedef bool Value;

  struct Pair {
    Key key;
    Value value;
    Pair() : key(nullptr), value(false) {}
    Pair(const Key key, const Value& value) : key(key), value(value) {}
    Pair(const Pair& other) : key(other.key), value(other.value) {}
    Pair& operator=(const Pair&) = default;
  };

  static Key KeyOf(Pair kv) { return kv.key; }
  static Value ValueOf(Pair kv) { return kv.value; }
  static uword Hash(Key key) {
    return Utils::WordHash(reinterpret_cast<intptr_t>(key));
  }
  static bool IsKeyEqual(Pair kv, Key key) { return kv.key == key; }
};

class DebuggerSet : public MallocDirectChainedHashMap<DebuggerKeyValueTrait> {
 public:
  typedef DebuggerKeyValueTrait::Key Key;
  typedef DebuggerKeyValueTrait::Value Value;
  typedef DebuggerKeyValueTrait::Pair Pair;

  virtual ~DebuggerSet() { Clear(); }

  void Insert(const Key& key) {
    Pair pair(key, /*value=*/true);
    MallocDirectChainedHashMap<DebuggerKeyValueTrait>::Insert(pair);
  }

  void Remove(const Key& key) {
    MallocDirectChainedHashMap<DebuggerKeyValueTrait>::Remove(key);
  }
};

class BoolCallable : public ValueObject {
 public:
  BoolCallable() {}
  virtual ~BoolCallable() {}

  virtual bool Call() = 0;

 private:
  DISALLOW_COPY_AND_ASSIGN(BoolCallable);
};

template <typename T>
class LambdaBoolCallable : public BoolCallable {
 public:
  explicit LambdaBoolCallable(T& lambda) : lambda_(lambda) {}
  bool Call() { return lambda_(); }

 private:
  T& lambda_;
  DISALLOW_COPY_AND_ASSIGN(LambdaBoolCallable);
};

class GroupDebugger {
 public:
  explicit GroupDebugger(IsolateGroup* isolate_group);
  ~GroupDebugger();

  void MakeCodeBreakpointAt(const Function& func, BreakpointLocation* bpt);

  // Returns [nullptr] if no breakpoint exists for the given address.
  CodeBreakpoint* GetCodeBreakpoint(uword breakpoint_address);
  BreakpointLocation* GetBreakpointLocationFor(Debugger* debugger,
                                               uword breakpoint_address,
                                               CodeBreakpoint** pcbpt);
  CodePtr GetPatchedStubAddress(uword breakpoint_address);

  void RegisterBreakpointLocation(BreakpointLocation* location);
  void UnregisterBreakpointLocation(BreakpointLocation* location);

  void RemoveBreakpointLocation(BreakpointLocation* bpt_location);
  void UnlinkCodeBreakpoints(BreakpointLocation* bpt_location);

  // Returns true if the call at address pc is patched to point to
  // a debugger stub.
  bool HasActiveBreakpoint(uword pc);
  bool HasCodeBreakpointInFunction(const Function& func);
  bool HasCodeBreakpointInCode(const Code& code);

  bool HasBreakpointInFunction(const Function& func);
  bool HasBreakpointInCode(const Code& code);

  void SyncBreakpointLocation(BreakpointLocation* loc);

  void Pause();

  bool EnsureLocationIsInFunction(Zone* zone,
                                  const Function& function,
                                  BreakpointLocation* location);
  void NotifyCompilation(const Function& func);

  void VisitObjectPointers(ObjectPointerVisitor* visitor);

  RwLock* code_breakpoints_lock() { return code_breakpoints_lock_.get(); }

  RwLock* breakpoint_locations_lock() {
    return breakpoint_locations_lock_.get();
  }

  RwLock* single_stepping_set_lock() { return single_stepping_set_lock_.get(); }

  void RegisterSingleSteppingDebugger(Thread* thread, const Debugger* debugger);
  void UnregisterSingleSteppingDebugger(Thread* thread,
                                        const Debugger* debugger);

  // Returns [true] if there is at least one breakpoint set in function or code.
  // Checks for both user-defined and internal temporary breakpoints.
  bool HasBreakpoint(Thread* thread, const Function& function);
  bool IsDebugging(Thread* thread, const Function& function);

 private:
  IsolateGroup* isolate_group_;

  std::unique_ptr<RwLock> code_breakpoints_lock_;
  CodeBreakpoint* code_breakpoints_;

  // Secondary list of all breakpoint_locations_(primary is in Debugger class).
  // This list is kept in sync with all the lists in Isolate Debuggers and is
  // used to quickly scan BreakpointLocations when new Function is compiled.
  std::unique_ptr<RwLock> breakpoint_locations_lock_;
  MallocGrowableArray<BreakpointLocation*> breakpoint_locations_;

  std::unique_ptr<RwLock> single_stepping_set_lock_;
  DebuggerSet single_stepping_set_;

  void RemoveUnlinkedCodeBreakpoints();
  void RegisterCodeBreakpoint(CodeBreakpoint* bpt);

  bool needs_breakpoint_cleanup_;
};

class Debugger {
 public:
  enum ResumeAction {
    kContinue,
    kStepInto,
    kStepOver,
    kStepOut,
    kStepRewind,
    kStepOverAsyncSuspension,
  };

  explicit Debugger(Isolate* isolate);
  ~Debugger();

  Isolate* isolate() const { return isolate_; }

  void NotifyIsolateCreated();
  void Shutdown();

  void NotifyDoneLoading();

  // Set breakpoint at closest location to function entry.
  Breakpoint* SetBreakpointAtEntry(const Function& target_function,
                                   bool single_shot);
  Breakpoint* SetBreakpointAtActivation(const Instance& closure,
                                        bool single_shot);
  Breakpoint* BreakpointAtActivation(const Instance& closure);

  // TODO(turnidge): script_url may no longer be specific enough.
  Breakpoint* SetBreakpointAtLine(const String& script_url,
                                  intptr_t line_number);
  Breakpoint* SetBreakpointAtLineCol(const String& script_url,
                                     intptr_t line_number,
                                     intptr_t column_number);

  BreakpointLocation* BreakpointLocationAtLineCol(const String& script_url,
                                                  intptr_t line_number,
                                                  intptr_t column_number);

  // Returns true if the breakpoint's state changed.
  bool SetBreakpointState(Breakpoint* bpt, bool enable);

  void RemoveBreakpoint(intptr_t bp_id);
  Breakpoint* GetBreakpointById(intptr_t id);

  void AsyncStepInto(const Closure& awaiter);

  void Continue();

  bool SetResumeAction(ResumeAction action,
                       intptr_t frame_index = 1,
                       const char** error = nullptr);

  bool IsStepping() const { return resume_action_ != kContinue; }

  bool IsSingleStepping() const { return resume_action_ == kStepInto; }

  bool IsPaused() const { return pause_event_ != nullptr; }

  bool ignore_breakpoints() const { return ignore_breakpoints_; }
  void set_ignore_breakpoints(bool ignore_breakpoints) {
    ignore_breakpoints_ = ignore_breakpoints;
  }

  // Put the isolate into single stepping mode when Dart code next runs.
  //
  // This is used by the vm service to allow the user to step while
  // paused at isolate start.
  void EnterSingleStepMode();

  // Indicates why the debugger is currently paused.  If the debugger
  // is not paused, this returns nullptr.  Note that the debugger can be
  // paused for breakpoints, isolate interruption, and (sometimes)
  // exceptions.
  const ServiceEvent* PauseEvent() const { return pause_event_; }

  void SetExceptionPauseInfo(Dart_ExceptionPauseInfo pause_info);
  Dart_ExceptionPauseInfo GetExceptionPauseInfo() const;

  void VisitObjectPointers(ObjectPointerVisitor* visitor);

  // Returns a stack trace with frames corresponding to invisible functions
  // omitted. CurrentStackTrace always returns a new trace on the current stack.
  // The trace returned by StackTrace may have been cached; it is suitable for
  // use when stepping, but otherwise may be out of sync with the current stack.
  DebuggerStackTrace* StackTrace();

  DebuggerStackTrace* AsyncAwaiterStackTrace();

  // Pause execution for a breakpoint.  Called from generated code.
  ErrorPtr PauseBreakpoint();

  // Pause execution due to stepping.  Called from generated code.
  ErrorPtr PauseStepping();

  // Pause execution due to isolate interrupt.
  ErrorPtr PauseInterrupted();

  // Pause after a reload request.
  ErrorPtr PausePostRequest();

  // Pause execution due to an uncaught exception.
  void PauseException(const Instance& exc);

  // Pause execution due to a call to the debugger() function from
  // Dart.
  void PauseDeveloper(const String& msg);

  void PrintBreakpointsToJSONArray(JSONArray* jsarr) const;
  void PrintSettingsToJSONObject(JSONObject* jsobj) const;

  static bool IsDebuggable(const Function& func);

  intptr_t limitBreakpointId() { return next_id_; }

  // Callback to the debugger to continue frame rewind, post-deoptimization.
  void RewindPostDeopt();

  // Sets breakpoint at resumption of a suspendable function
  // with given function data (such as _Future or _AsyncStarStreamController).
  void SetBreakpointAtResumption(const Object& function_data);

  // Check breakpoints at frame resumption. Called from generated code.
  void ResumptionBreakpoint();

 private:
  ErrorPtr PauseRequest(ServiceEvent::EventKind kind);

  // Will return false if we are not at an await.
  bool SetupStepOverAsyncSuspension(const char** error);

  bool NeedsIsolateEvents();
  bool NeedsDebugEvents();

  void SendBreakpointEvent(ServiceEvent::EventKind kind, Breakpoint* bpt);

  void FindCompiledFunctions(
      const GrowableHandlePtrArray<const Script>& scripts,
      TokenPosition start_pos,
      TokenPosition end_pos,
      GrowableObjectArray* code_function_list);
  bool FindBestFit(const Script& script,
                   TokenPosition token_pos,
                   TokenPosition last_token_pos,
                   Function* best_fit);
  void DeoptimizeWorld();
  void NotifySingleStepping(bool value) const;
  BreakpointLocation* SetCodeBreakpoints(
      const GrowableHandlePtrArray<const Script>& scripts,
      TokenPosition token_pos,
      TokenPosition last_token_pos,
      intptr_t requested_line,
      intptr_t requested_column,
      TokenPosition exact_token_pos,
      const GrowableObjectArray& functions);
  BreakpointLocation* SetBreakpoint(const Script& script,
                                    TokenPosition token_pos,
                                    TokenPosition last_token_pos,
                                    intptr_t requested_line,
                                    intptr_t requested_column,
                                    const Function& function);
  BreakpointLocation* SetBreakpoint(
      const GrowableHandlePtrArray<const Script>& scripts,
      TokenPosition token_pos,
      TokenPosition last_token_pos,
      intptr_t requested_line,
      intptr_t requested_column,
      const Function& function);
  bool RemoveBreakpointFromTheList(intptr_t bp_id, BreakpointLocation** list);
  Breakpoint* GetBreakpointByIdInTheList(intptr_t id, BreakpointLocation* list);
  BreakpointLocation* GetLatentBreakpoint(const String& url,
                                          intptr_t line,
                                          intptr_t column);
  void RegisterBreakpointLocation(BreakpointLocation* bpt);
  BreakpointLocation* GetResolvedBreakpointLocation(
      const String& script_url,
      TokenPosition code_token_pos);
  BreakpointLocation* GetBreakpointLocation(
      const String& script_url,
      TokenPosition token_pos,
      intptr_t requested_line,
      intptr_t requested_column,
      TokenPosition code_token_pos = TokenPosition::kNoSource);

  void PrintBreakpointsListToJSONArray(BreakpointLocation* sbpt,
                                       JSONArray* jsarr) const;

  void SignalPausedEvent(ActivationFrame* top_frame, Breakpoint* bpt);

  intptr_t nextId() { return next_id_++; }

  bool ShouldPauseOnException(DebuggerStackTrace* stack_trace,
                              const Instance& exc);

  // Handles any events which pause vm execution.  Breakpoints,
  // interrupts, etc.
  void Pause(ServiceEvent* event);

  void HandleSteppingRequest(bool skip_next_step = false);

  void CacheStackTraces(DebuggerStackTrace* stack_trace,
                        DebuggerStackTrace* async_awaiter_stack_trace);
  void ClearCachedStackTraces();

  void RewindToFrame(intptr_t frame_index);
  void RewindToUnoptimizedFrame(StackFrame* frame, const Code& code);
  void RewindToOptimizedFrame(StackFrame* frame,
                              const Code& code,
                              intptr_t post_deopt_frame_index);

  void ResetSteppingFramePointer();
  void SetSyncSteppingFramePointer(DebuggerStackTrace* stack_trace);

  GroupDebugger* group_debugger() { return isolate_->group()->debugger(); }

  Isolate* isolate_;

  // ID number generator.
  intptr_t next_id_;

  BreakpointLocation* latent_locations_;
  BreakpointLocation* breakpoint_locations_;

  // Tells debugger what to do when resuming execution after a breakpoint.
  ResumeAction resume_action_;
  void set_resume_action(ResumeAction action);
  intptr_t resume_frame_index_;
  intptr_t post_deopt_frame_index_;

  // Do not call back to breakpoint handler if this flag is set.
  // Effectively this means ignoring breakpoints. Set when Dart code may
  // be run as a side effect of getting values of fields.
  bool ignore_breakpoints_;

  // Indicates why the debugger is currently paused.  If the debugger
  // is not paused, this is nullptr.  Note that the debugger can be
  // paused for breakpoints, isolate interruption, and (sometimes)
  // exceptions.
  ServiceEvent* pause_event_;

  // Current stack trace. Valid only while IsPaused().
  DebuggerStackTrace* stack_trace_;
  DebuggerStackTrace* async_awaiter_stack_trace_;

  // When stepping through code, only pause the program if the top
  // frame corresponds to this fp value, or if the top frame is
  // lower on the stack.
  uword stepping_fp_;

  // When stepping through code, do not stop more than once in the same
  // token position range.
  uword last_stepping_fp_;
  TokenPosition last_stepping_pos_;

  // If we step while at a breakpoint, we would hit the same pc twice.
  // We use this field to let us skip the next single-step after a
  // breakpoint.
  bool skip_next_step_;

  Dart_ExceptionPauseInfo exc_pause_info_;

  // Holds function data corresponding to suspendable
  // function which should be stopped when resumed.
  MallocGrowableArray<ObjectPtr> breakpoints_at_resumption_;

  friend class Isolate;
  friend class BreakpointLocation;
  DISALLOW_COPY_AND_ASSIGN(Debugger);
};

class DisableBreakpointsScope : public ValueObject {
 public:
  DisableBreakpointsScope(Debugger* debugger, bool disable)
      : debugger_(debugger) {
    ASSERT(debugger_ != nullptr);
    initial_state_ = debugger_->ignore_breakpoints();
    debugger_->set_ignore_breakpoints(disable);
  }

  ~DisableBreakpointsScope() {
    debugger_->set_ignore_breakpoints(initial_state_);
  }

 private:
  Debugger* debugger_;
  bool initial_state_;

  DISALLOW_COPY_AND_ASSIGN(DisableBreakpointsScope);
};

}  // namespace dart

#endif  // !defined(PRODUCT)

#endif  // RUNTIME_VM_DEBUGGER_H_
