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

class Debugger {
 public:
  Debugger();

  void Initialize(Isolate* isolate);

  // Set breakpoint at closest location to function entry.
  void SetBreakpointAtEntry(const String& class_name,
                            const String& function_name);

  void VisitObjectPointers(ObjectPointerVisitor* visitor);

  // Returns NULL if no breakpoint exists for the given address.
  Breakpoint* GetBreakpoint(uword breakpoint_address);

 private:
  void AddBreakpoint(Breakpoint* bpt);

  bool initialized_;
  Breakpoint* breakpoints_;
  DISALLOW_COPY_AND_ASSIGN(Debugger);
};


}  // namespace dart

#endif  // VM_DEBUGGER_H_
