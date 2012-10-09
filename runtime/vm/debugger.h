// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_DEBUGGER_H_
#define VM_DEBUGGER_H_

#include "include/dart_debugger_api.h"

#include "vm/object.h"
#include "vm/port.h"

namespace dart {

class SourceBreakpoint;
class CodeBreakpoint;
class Isolate;
class ObjectPointerVisitor;
class ActiveVariables;
class RemoteObjectCache;

// SourceBreakpoint represents a user-specified breakpoint location in
// Dart source. There may be more than one CodeBreakpoint object per
// SourceBreakpoint.
class SourceBreakpoint {
 public:
  SourceBreakpoint(intptr_t id, const Function& func, intptr_t token_pos);

  RawFunction* function() const { return function_; }
  intptr_t token_pos() const { return token_pos_; }
  intptr_t id() const { return id_; }

  RawScript* SourceCode();
  RawString* SourceUrl();
  intptr_t LineNumber();

  void Enable();
  void Disable();
  bool IsEnabled() const { return is_enabled_; }

 private:
  void VisitObjectPointers(ObjectPointerVisitor* visitor);

  void set_function(const Function& func);
  void set_next(SourceBreakpoint* value) { next_ = value; }
  SourceBreakpoint* next() const { return this->next_; }

  const intptr_t id_;
  RawFunction* function_;
  const intptr_t token_pos_;
  intptr_t line_number_;
  bool is_enabled_;

  SourceBreakpoint* next_;

  friend class Debugger;
  DISALLOW_COPY_AND_ASSIGN(SourceBreakpoint);
};


// CodeBreakpoint represents a location in compiled code. There may be
// more than one CodeBreakpoint for one SourceBreakpoint, e.g. when a
// function gets compiled as a regular function and as a closure.
class CodeBreakpoint {
 public:
  CodeBreakpoint(const Function& func, intptr_t pc_desc_index);
  ~CodeBreakpoint();

  RawFunction* function() const { return function_; }
  uword pc() const { return pc_; }
  intptr_t token_pos() const { return token_pos_; }
  bool IsInternal() const { return src_bpt_ == NULL; }

  RawScript* SourceCode();
  RawString* SourceUrl();
  intptr_t LineNumber();

  void Enable();
  void Disable();
  bool IsEnabled() const { return is_enabled_; }

 private:
  void VisitObjectPointers(ObjectPointerVisitor* visitor);

  SourceBreakpoint* src_bpt() const { return src_bpt_; }
  void set_src_bpt(SourceBreakpoint* value) { src_bpt_ = value; }

  void set_next(CodeBreakpoint* value) { next_ = value; }
  CodeBreakpoint* next() const { return this->next_; }
  intptr_t pc_desc_index() const { return pc_desc_index_; }

  void PatchCode();
  void RestoreCode();
  void PatchFunctionReturn();
  void RestoreFunctionReturn();

  RawFunction* function_;
  intptr_t pc_desc_index_;
  intptr_t token_pos_;
  uword pc_;
  intptr_t line_number_;
  bool is_enabled_;

  SourceBreakpoint* src_bpt_;
  CodeBreakpoint* next_;

  PcDescriptors::Kind breakpoint_kind_;
  union {
    uword target_address_;
    uint8_t raw[2 * sizeof(uword)];
  } saved_bytes_;

  friend class Debugger;
  DISALLOW_COPY_AND_ASSIGN(CodeBreakpoint);
};


// ActivationFrame represents one dart function activation frame
// on the call stack.
class ActivationFrame : public ZoneAllocated {
 public:
  explicit ActivationFrame(uword pc, uword fp, uword sp, const Context& ctx);

  uword pc() const { return pc_; }
  uword fp() const { return fp_; }
  uword sp() const { return sp_; }

  const Function& DartFunction();
  RawString* QualifiedFunctionName();
  RawString* SourceUrl();
  RawScript* SourceScript();
  RawLibrary* Library();
  intptr_t TokenPos();
  intptr_t LineNumber();

  // The context level of a frame is the context level at the
  // PC/token index of the frame. It determines the depth of the context
  // chain that belongs to the function of this activation frame.
  intptr_t ContextLevel();

  const char* ToCString();

  intptr_t NumLocalVariables();

  void VariableAt(intptr_t i,
                  String* name,
                  intptr_t* token_pos,
                  intptr_t* end_pos,
                  Instance* value);

  RawArray* GetLocalVariables();
  RawContext* CallerContext();

 private:
  intptr_t PcDescIndex();
  void GetPcDescriptors();
  void GetVarDescriptors();
  void GetDescIndices();
  RawInstance* GetLocalVarValue(intptr_t slot_index);
  RawInstance* GetInstanceCallReceiver(intptr_t num_actual_args);

  uword pc_;
  uword fp_;
  uword sp_;

  // The anchor of the context chain for this function.
  const Context& ctx_;

  Function& function_;
  intptr_t token_pos_;
  intptr_t pc_desc_index_;
  intptr_t line_number_;
  intptr_t context_level_;

  bool vars_initialized_;
  LocalVarDescriptors& var_descriptors_;
  ZoneGrowableArray<intptr_t> desc_indices_;
  PcDescriptors& pc_desc_;

  friend class Debugger;
  DISALLOW_COPY_AND_ASSIGN(ActivationFrame);
};


// Array of function activations on the call stack.
class DebuggerStackTrace : public ZoneAllocated {
 public:
  explicit DebuggerStackTrace(int capacity)
      : trace_(capacity) { }

  intptr_t Length() const { return trace_.length(); }

  ActivationFrame* ActivationFrameAt(int i) const {
    ASSERT(i < trace_.length());
    return trace_[i];
  }
 private:
  void AddActivation(ActivationFrame* frame);
  ZoneGrowableArray<ActivationFrame*> trace_;

  friend class Debugger;
  DISALLOW_COPY_AND_ASSIGN(DebuggerStackTrace);
};


typedef void BreakpointHandler(Dart_Port isolate_id,
                               SourceBreakpoint* bpt,
                               DebuggerStackTrace* stack);


class Debugger {
 public:
  enum EventType {
    kBreakpointReached = 1,
    kBreakpointResolved = 2,
    kExceptionThrown = 3,
    kIsolateCreated = 4,
    kIsolateShutdown = 5,
    kIsolateInterrupted = 6,
  };
  struct DebuggerEvent {
    EventType type;
    union {
      DebuggerStackTrace* stack_trace;
      SourceBreakpoint* breakpoint;
      const Object* exception;
      Dart_Port isolate_id;
    };
  };
  typedef void EventHandler(DebuggerEvent *event);

  Debugger();
  ~Debugger();

  void Initialize(Isolate* isolate);
  void Shutdown();
  bool IsActive();

  void NotifyCompilation(const Function& func);

  RawFunction* ResolveFunction(const Library& library,
                               const String& class_name,
                               const String& function_name);

  // Set breakpoint at closest location to function entry.
  SourceBreakpoint* SetBreakpointAtEntry(const Function& target_function);
  SourceBreakpoint* SetBreakpointAtLine(const String& script_url,
                                        intptr_t line_number);

  void RemoveBreakpoint(intptr_t bp_id);
  SourceBreakpoint* GetBreakpointById(intptr_t id);

  void SetStepOver() { resume_action_ = kStepOver; }
  void SetStepInto() { resume_action_ = kStepInto; }
  void SetStepOut() { resume_action_ = kStepOut; }

  void SetExceptionPauseInfo(Dart_ExceptionPauseInfo pause_info);
  Dart_ExceptionPauseInfo GetExceptionPauseInfo();

  void VisitObjectPointers(ObjectPointerVisitor* visitor);

  // Called from Runtime when a breakpoint in Dart code is reached.
  void BreakpointCallback();

  DebuggerStackTrace* StackTrace() const { return stack_trace_; }

  RawArray* GetInstanceFields(const Instance& obj);
  RawArray* GetStaticFields(const Class& cls);
  RawArray* GetLibraryFields(const Library& lib);
  RawArray* GetGlobalFields(const Library& lib);

  intptr_t CacheObject(const Object& obj);
  RawObject* GetCachedObject(intptr_t obj_id);
  bool IsValidObjectId(intptr_t obj_id);

  Dart_Port GetIsolateId() { return isolate_id_; }

  static void SetEventHandler(EventHandler* handler);
  static void SetBreakpointHandler(BreakpointHandler* handler);

  // Utility functions.
  static const char* QualifiedFunctionName(const Function& func);

  RawObject* GetInstanceField(const Class& cls,
                              const String& field_name,
                              const Instance& object);
  RawObject* GetStaticField(const Class& cls,
                            const String& field_name);

  void SignalBpReached();
  void SignalExceptionThrown(const Object& exc);
  static void SignalIsolateEvent(EventType type);

 private:
  enum ResumeAction {
    kContinue,
    kStepOver,
    kStepInto,
    kStepOut
  };

  void EnsureFunctionIsDeoptimized(const Function& func);
  void InstrumentForStepping(const Function& target_function);
  SourceBreakpoint* SetBreakpoint(const Function& target_function,
                                  intptr_t first_token_pos,
                                  intptr_t last_token_pos);
  void RemoveInternalBreakpoints();
  void UnlinkCodeBreakpoints(SourceBreakpoint* src_bpt);
  void RegisterSourceBreakpoint(SourceBreakpoint* bpt);
  void RegisterCodeBreakpoint(CodeBreakpoint* bpt);
  SourceBreakpoint* GetSourceBreakpoint(const Function& func,
                                        intptr_t token_pos);
  CodeBreakpoint* MakeCodeBreakpoint(const Function& func,
                                     intptr_t first_token_pos,
                                     intptr_t last_token_pos);

  // Returns NULL if no breakpoint exists for the given address.
  CodeBreakpoint* GetCodeBreakpoint(uword breakpoint_address);

  void SyncBreakpoint(SourceBreakpoint* bpt);

  DebuggerStackTrace* CollectStackTrace();
  void SignalBpResolved(SourceBreakpoint *bpt);

  bool IsDebuggable(const Function& func);

  intptr_t nextId() { return next_id_++; }

  bool ShouldPauseOnException(DebuggerStackTrace* stack_trace,
                              const Object& exc);

  void CollectLibraryFields(const GrowableObjectArray& field_list,
                            const Library& lib,
                            const String& prefix,
                            bool include_private_fields);

  Isolate* isolate_;
  Dart_Port isolate_id_;  // A unique ID for the isolate in the debugger.
  bool initialized_;

  // ID number generator.
  intptr_t next_id_;

  // Current stack trace. Valid while executing breakpoint callback code.
  DebuggerStackTrace* stack_trace_;

  RemoteObjectCache* obj_cache_;

  SourceBreakpoint* src_breakpoints_;
  CodeBreakpoint* code_breakpoints_;

  // Tells debugger what to do when resuming execution after a breakpoint.
  ResumeAction resume_action_;

  // If >= 0, last_bpt_line contains the line number of the last breakpoint
  // location for which the breakpoint callback function was called.
  intptr_t last_bpt_line_;

  // Do not call back to breakpoint handler if this flag is set.
  // Effectively this means ignoring breakpoints. Set when Dart code may
  // be run as a side effect of getting values of fields.
  bool ignore_breakpoints_;

  intptr_t exc_pause_info_;

  static BreakpointHandler* bp_handler_;
  static EventHandler* event_handler_;

  friend class SourceBreakpoint;
  DISALLOW_COPY_AND_ASSIGN(Debugger);
};


}  // namespace dart

#endif  // VM_DEBUGGER_H_
