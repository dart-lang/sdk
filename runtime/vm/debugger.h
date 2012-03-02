// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_DEBUGGER_H_
#define VM_DEBUGGER_H_

#include "vm/object.h"

namespace dart {

class Breakpoint;
class Isolate;
class ObjectPointerVisitor;
class ActiveVariables;


// Breakpoint represents a location in Dart source and the corresponding
// address in compiled code.
class Breakpoint {
 public:
  Breakpoint(const Function& func, intptr_t pc_desc_index);

  RawFunction* function() const { return function_; }
  uword pc() const { return pc_; }
  intptr_t token_index() const { return token_index_; }
  bool is_temporary() const { return is_temporary_; }
  void set_temporary(bool value) { is_temporary_ = value; }

  RawScript* SourceCode();
  RawString* SourceUrl();
  intptr_t LineNumber();

  void SetActive(bool value);
  bool IsActive();

 private:
  void VisitObjectPointers(ObjectPointerVisitor* visitor);

  void set_next(Breakpoint* value) { next_ = value; }
  Breakpoint* next() const { return this->next_; }
  intptr_t pc_desc_index() const { return pc_desc_index_; }

  void PatchCode();
  void RestoreCode();
  void PatchFunctionReturn();
  void RestoreFunctionReturn();

  RawFunction* function_;
  intptr_t pc_desc_index_;
  intptr_t token_index_;
  uword pc_;
  intptr_t line_number_;
  bool is_temporary_;

  bool is_patched_;
  PcDescriptors::Kind breakpoint_kind_;
  union {
    uword target_address_;
    uint8_t raw[2 * sizeof(uword)];
  } saved_bytes_;

  Breakpoint* next_;

  friend class Debugger;
  DISALLOW_COPY_AND_ASSIGN(Breakpoint);
};


// ActivationFrame represents one dart function activation frame
// on the call stack.
class ActivationFrame : public ZoneAllocated {
 public:
  explicit ActivationFrame(uword pc, uword fp, uword sp);

  uword pc() const { return pc_; }
  uword fp() const { return fp_; }
  uword sp() const { return sp_; }

  const Function& DartFunction();
  RawString* QualifiedFunctionName();
  RawString* SourceUrl();
  RawScript* SourceScript();
  intptr_t TokenIndex();
  intptr_t LineNumber();
  const char* ToCString();

  intptr_t NumLocalVariables();

  void VariableAt(intptr_t i,
                  String* name,
                  intptr_t* token_pos,
                  intptr_t* end_pos,
                  Instance* value);

  RawArray* GetLocalVariables();

 private:
  void GetDescIndices();
  RawInstance* GetLocalVarValue(intptr_t slot_index);
  RawInstance* GetInstanceCallReceiver(intptr_t num_actual_args);

  uword pc_;
  uword fp_;
  uword sp_;
  Function& function_;
  intptr_t token_index_;
  intptr_t line_number_;

  LocalVarDescriptors* var_descriptors_;
  ZoneGrowableArray<intptr_t> desc_indices_;

  friend class Debugger;
  DISALLOW_COPY_AND_ASSIGN(ActivationFrame);
};


// Array of function activations on the call stack.
class StackTrace : public ZoneAllocated {
 public:
  explicit StackTrace(int capacity) : trace_(capacity) { }

  intptr_t Length() const { return trace_.length(); }

  ActivationFrame* ActivationFrameAt(int i) const {
    ASSERT(i < trace_.length());
    return trace_[i];
  }
 private:
  void AddActivation(ActivationFrame* frame);
  ZoneGrowableArray<ActivationFrame*> trace_;

  friend class Debugger;
  DISALLOW_COPY_AND_ASSIGN(StackTrace);
};


typedef void BreakpointHandler(Breakpoint* bpt, StackTrace* stack);


class Debugger {
 public:
  Debugger();
  ~Debugger();

  void Initialize(Isolate* isolate);
  void Shutdown();
  bool IsActive();

  void SetBreakpointHandler(BreakpointHandler* handler);

  RawFunction* ResolveFunction(const Library& library,
                               const String& class_name,
                               const String& function_name);

  // Set breakpoint at closest location to function entry.
  Breakpoint* SetBreakpointAtEntry(const Function& target_function,
                                   Error* error);
  Breakpoint* SetBreakpointAtLine(const String& script_url,
                                  intptr_t line_number,
                                  Error* error);

  void RemoveBreakpoint(Breakpoint* bpt);

  void SetStepOver() { resume_action_ = kStepOver; }
  void SetStepInto() { resume_action_ = kStepInto; }
  void SetStepOut() { resume_action_ = kStepOut; }

  void VisitObjectPointers(ObjectPointerVisitor* visitor);

  // Returns NULL if no breakpoint exists for the given address.
  Breakpoint* GetBreakpoint(uword breakpoint_address);

  // Called from Runtime when a breakpoint in Dart code is reached.
  void BreakpointCallback();

  RawArray* GetInstanceFields(const Instance& obj);
  RawArray* GetStaticFields(const Class& cls);

  // Utility functions.
  static const char* QualifiedFunctionName(const Function& func);

  RawObject* GetInstanceField(const Class& cls,
                              const String& field_name,
                              const Instance& object);
  RawObject* GetStaticField(const Class& cls,
                            const String& field_name);

 private:
  enum ResumeAction {
    kContinue,
    kStepOver,
    kStepInto,
    kStepOut
  };

  void InstrumentForStepping(const Function &target_function);
  Breakpoint* SetBreakpoint(const Function& target_function,
                            intptr_t token_index,
                            Error* error);
  void UnsetBreakpoint(Breakpoint* bpt);
  void RemoveTemporaryBreakpoints();
  Breakpoint* NewBreakpoint(const Function& func, intptr_t pc_desc_index);
  void RegisterBreakpoint(Breakpoint* bpt);
  Breakpoint* GetBreakpointByFunction(const Function& func,
                                      intptr_t token_index);

  Isolate* isolate_;
  bool initialized_;
  BreakpointHandler* bp_handler_;
  Breakpoint* breakpoints_;

  // Tells debugger what to do when resuming execution after a breakpoint.
  ResumeAction resume_action_;

  DISALLOW_COPY_AND_ASSIGN(Debugger);
};


}  // namespace dart

#endif  // VM_DEBUGGER_H_
