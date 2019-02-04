// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_PROGRAM_VISITOR_H_
#define RUNTIME_VM_PROGRAM_VISITOR_H_

#include "vm/allocation.h"

namespace dart {

class Function;
class Class;

template <typename T>
class Visitor : public ValueObject {
 public:
  virtual ~Visitor() {}
  virtual void Visit(const T& obj) = 0;
};

typedef Visitor<Function> FunctionVisitor;
typedef Visitor<Class> ClassVisitor;

class ProgramVisitor : public AllStatic {
 public:
  static void VisitFunctions(FunctionVisitor* visitor);
  static void VisitClasses(ClassVisitor* visitor);

  static void Dedup();

 private:
#if !defined(DART_PRECOMPILED_RUNTIME)
  static void BindStaticCalls();
  static void ShareMegamorphicBuckets();
  static void DedupStackMaps();
  static void DedupPcDescriptors();
  static void DedupDeoptEntries();
#if defined(DART_PRECOMPILER)
  static void DedupCatchEntryMovesMaps();
#endif
  static void DedupCodeSourceMaps();
  static void DedupLists();
  static void DedupInstructions();
  static void DedupInstructionsWithSameMetadata();
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
};

}  // namespace dart

#endif  // RUNTIME_VM_PROGRAM_VISITOR_H_
