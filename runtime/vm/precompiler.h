// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_PRECOMPILER_H_
#define VM_PRECOMPILER_H_

#include "vm/allocation.h"

namespace dart {

// Forward declarations.
class Class;
class Error;
class Field;
class Function;
class GrowableObjectArray;
class RawError;
class String;

class Precompiler : public ValueObject {
 public:
  static RawError* CompileAll();

 private:
  explicit Precompiler(Thread* thread);

  void DoCompileAll();
  void ClearAllCode();
  void AddRoots();
  void Iterate();
  void CleanUp();

  void AddCalleesOf(const Function& function);
  void AddField(const Field& field);
  void AddFunction(const Function& function);
  void AddClass(const Class& cls);
  void AddSelector(const String& selector);
  bool IsSent(const String& selector);

  void ProcessFunction(const Function& function);
  void CheckForNewDynamicFunctions();

  Thread* thread() const { return thread_; }
  Zone* zone() const { return zone_; }
  Isolate* isolate() const { return isolate_; }

  Thread* thread_;
  Zone* zone_;
  Isolate* isolate_;

  bool changed_;
  intptr_t function_count_;
  intptr_t class_count_;

  const GrowableObjectArray& libraries_;
  const GrowableObjectArray& pending_functions_;
  const GrowableObjectArray& collected_closures_;
  const GrowableObjectArray& sent_selectors_;
  Error& error_;
};

}  // namespace dart

#endif  // VM_PRECOMPILER_H_
