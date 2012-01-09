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

  RawScript* SourceCode();
  RawString* SourceUrl();
  intptr_t LineNumber();

 private:
  void VisitObjectPointers(ObjectPointerVisitor* visitor);

  void set_next(Breakpoint* value) { next_ = value; }
  Breakpoint* next() const { return this->next_; }

  RawFunction* function_;
  intptr_t pc_desc_index_;
  intptr_t token_index_;
  uword pc_;
  intptr_t line_number_;
  Breakpoint* next_;

  friend class Debugger;
  DISALLOW_COPY_AND_ASSIGN(Breakpoint);
};


// ActivationFrame represents one dart function activation frame
// on the call stack.
class ActivationFrame : public ZoneAllocated {
 public:
  explicit ActivationFrame(uword pc, uword fp);

  uword pc() const { return pc_; }
  uword fp() const { return fp_; }

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

 private:
  void GetLocalVariables();
  RawInstance* GetLocalVarValue(intptr_t slot_index);

  uword pc_;
  uword fp_;
  Function& function_;
  intptr_t token_index_;
  intptr_t line_number_;

  LocalVarDescriptors* var_descriptors_;
  ZoneGrowableArray<intptr_t> desc_indices_;

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

  void Initialize(Isolate* isolate);
  bool IsActive();

  void SetBreakpointHandler(BreakpointHandler* handler);

  RawFunction* ResolveFunction(const Library& library,
                               const String& class_name,
                               const String& function_name);

  // Set breakpoint at closest location to function entry.
  Breakpoint* SetBreakpointAtEntry(const Function& target_function);

  void VisitObjectPointers(ObjectPointerVisitor* visitor);

  // Returns NULL if no breakpoint exists for the given address.
  Breakpoint* GetBreakpoint(uword breakpoint_address);

  // Called from Runtime when a breakpoint in Dart code is reached.
  void BreakpointCallback();

  // Utility functions.
  static const char* QualifiedFunctionName(const Function& func);

 private:
  void AddBreakpoint(Breakpoint* bpt);

  bool initialized_;
  BreakpointHandler* bp_handler_;
  Breakpoint* breakpoints_;
  DISALLOW_COPY_AND_ASSIGN(Debugger);
};


}  // namespace dart

#endif  // VM_DEBUGGER_H_
