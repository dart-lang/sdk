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
  explicit ActivationFrame(uword pc);

  uword pc() const { return pc_; }

  RawFunction* DartFunction();
  RawString* SourceUrl();
  RawScript* SourceScript();
  intptr_t TokenIndex();
  intptr_t LineNumber();
  const char* ToCString();

  // Returns an array of String values containing variable names
  // in this activation frame.
  RawArray* Variables();

  // Returns the value of the given variable in the context of the
  // activation frame.
  RawInstance* Value(const String& variable_name);

 private:
  uword pc_;
  RawFunction* function_;
  intptr_t token_index_;
  intptr_t line_number_;

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

  void SetBreakpointHandler(BreakpointHandler* handler);

  // Set breakpoint at closest location to function entry.
  void SetBreakpointAtEntry(const String& class_name,
                            const String& function_name);

  void VisitObjectPointers(ObjectPointerVisitor* visitor);

  // Returns NULL if no breakpoint exists for the given address.
  Breakpoint* GetBreakpoint(uword breakpoint_address);

  // Called from Runtime when a breakpoint in Dart code is reached.
  void BreakpointCallback();

 private:
  void AddBreakpoint(Breakpoint* bpt);

  bool initialized_;
  BreakpointHandler* bp_handler_;
  Breakpoint* breakpoints_;
  DISALLOW_COPY_AND_ASSIGN(Debugger);
};


}  // namespace dart

#endif  // VM_DEBUGGER_H_
