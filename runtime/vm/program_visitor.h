// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_PROGRAM_VISITOR_H_
#define RUNTIME_VM_PROGRAM_VISITOR_H_

#include "vm/allocation.h"

namespace dart {

class Class;
class Code;
class Function;

template <typename T>
class Visitor : public ValueObject {
 public:
  virtual ~Visitor() {}
  virtual void Visit(const T& obj) = 0;
};

using ClassVisitor = Visitor<Class>;
using CodeVisitor = Visitor<Code>;
using FunctionVisitor = Visitor<Function>;

class ProgramVisitor : public AllStatic {
 public:
  // Currently visits the following code objects:
  // * Code objects for functions (visited via VisitFunctions) where HasCode()
  //   is true.
  // * Code objects for entries in the dispatch table (if applicable).
  //
  // Notably, it does not visit any stubs not reachable via these routes.
  static void VisitCode(CodeVisitor* visitor);
  static void VisitFunctions(FunctionVisitor* visitor);
  static void VisitClasses(ClassVisitor* visitor);

  static void Dedup();

 private:
#if !defined(DART_PRECOMPILED_RUNTIME)
  static void BindStaticCalls();
  static void ShareMegamorphicBuckets();
  static void NormalizeAndDedupCompressedStackMaps();
  static void DedupPcDescriptors();
  static void DedupDeoptEntries();
#if defined(DART_PRECOMPILER)
  static void DedupCatchEntryMovesMaps();
  static void DedupUnlinkedCalls();
#endif
  static void DedupCodeSourceMaps();
  static void DedupLists();
  static void DedupInstructions();
  static void DedupInstructionsWithSameMetadata();
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
};

}  // namespace dart

#endif  // RUNTIME_VM_PROGRAM_VISITOR_H_
