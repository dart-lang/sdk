// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_PROGRAM_VISITOR_H_
#define RUNTIME_VM_PROGRAM_VISITOR_H_

#include "vm/allocation.h"

namespace dart {

// Currently, we have three types of abstract visitors that can be extended and
// used for program walking:
//
// * ClassVisitor, a visitor for classes in the program.
// * FunctionVisitor, a visitor for functions in the program.
// * CodeVisitor, a visitor for code objects in the program.
//
// To find the functions in a program, we must traverse the classes in the
// program, and similarly for code objects and functions. Thus, each
// FunctionVisitor is also a ClassVisitor, and each CodeVisitor is also a
// FunctionVisitor (and thus a ClassVisitor).
//
// Only the most specific visitor method is abstract. Derived visitors have a
// default empty implementation for base visitor methods to limit boilerplate
// needed when extending. For example, subclasses of CodeVisitor that only do
// per-Code work do not need to add empty implementations for VisitClass and
// VisitFunction.
//
// There are no guarantees for the order in which objects of a given type will
// be visited, but each object will be visited only once. In addition, each
// object is visited before any visitable sub-objects it contains. For example,
// this means a FunctionVisitor with a VisitClass implementation that drops
// methods from a class will not visit the dropped methods unless they are also
// found via another source of function objects.
//
// Note that WalkProgram only visits objects in the isolate heap. Deduplicating
// visitors that want to use VM objects as canonical when possible should
// instead add the appropriate VM objects first in their constructor.

class Class;
class Code;
class Function;

class CodeVisitor;
class FunctionVisitor;

class ClassVisitor : public ValueObject {
 public:
  virtual ~ClassVisitor() {}

  virtual bool IsFunctionVisitor() const { return false; }
  const FunctionVisitor* AsFunctionVisitor() const {
    return const_cast<FunctionVisitor*>(
      const_cast<ClassVisitor*>(this)->AsFunctionVisitor());
  }
  FunctionVisitor* AsFunctionVisitor() {
    if (!IsFunctionVisitor()) return nullptr;
    return reinterpret_cast<FunctionVisitor*>(this);
  }

  virtual bool IsCodeVisitor() const { return false; }
  const CodeVisitor* AsCodeVisitor() const {
    return const_cast<CodeVisitor*>(
      const_cast<ClassVisitor*>(this)->AsCodeVisitor());
  }
  CodeVisitor* AsCodeVisitor() {
    if (!IsCodeVisitor()) return nullptr;
    return reinterpret_cast<CodeVisitor*>(this);
  }

  virtual void VisitClass(const Class& cls) = 0;
};

class FunctionVisitor : public ClassVisitor {
 public:
  bool IsFunctionVisitor() const { return true; }
  virtual void VisitClass(const Class& cls) {}
  virtual void VisitFunction(const Function& function) = 0;
};

class CodeVisitor : public FunctionVisitor {
 public:
  bool IsCodeVisitor() const { return true; }
  virtual void VisitFunction(const Function& function) {}
  virtual void VisitCode(const Code& code) = 0;
};

class Thread;
class Isolate;

class ProgramVisitor : public AllStatic {
 public:
  // Walks all non-null class, function, and code objects in the program as
  // necessary for the given visitor.
  static void WalkProgram(Zone* zone, Isolate* isolate, ClassVisitor* visitor);

  static void Dedup(Thread* thread);
#if defined(DART_PRECOMPILER)
  static void AssignUnits(Thread* thread);
  static uint32_t Hash(Thread* thread);
#endif

 private:
#if !defined(DART_PRECOMPILED_RUNTIME)
  static void BindStaticCalls(Zone* zone, Isolate* isolate);
  static void ShareMegamorphicBuckets(Zone* zone, Isolate* isolate);
  static void NormalizeAndDedupCompressedStackMaps(Zone* zone,
                                                   Isolate* isolate);
  static void DedupPcDescriptors(Zone* zone, Isolate* isolate);
  static void DedupDeoptEntries(Zone* zone, Isolate* isolate);
#if defined(DART_PRECOMPILER)
  static void DedupCatchEntryMovesMaps(Zone* zone, Isolate* isolate);
  static void DedupUnlinkedCalls(Zone* zone, Isolate* isolate);
#endif
  static void DedupCodeSourceMaps(Zone* zone, Isolate* isolate);
  static void DedupLists(Zone* zone, Isolate* isolate);
  static void DedupInstructions(Zone* zone, Isolate* isolate);
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
};

}  // namespace dart

#endif  // RUNTIME_VM_PROGRAM_VISITOR_H_
