// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_FRONTEND_CONSTANT_READER_H_
#define RUNTIME_VM_COMPILER_FRONTEND_CONSTANT_READER_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#include "vm/compiler/frontend/kernel_translation_helper.h"
#include "vm/hash_table.h"
#include "vm/object.h"

namespace dart {
namespace kernel {

// Reads and caches constants from the kernel constant pool.
class ConstantReader {
 public:
  ConstantReader(KernelReaderHelper* helper, ActiveClass* active_class);

  virtual ~ConstantReader() {}

  InstancePtr ReadConstantInitializer();
  InstancePtr ReadConstantExpression();
  ObjectPtr ReadAnnotations();

  // Peeks to see if constant at the given index will evaluate to
  // instance of the given clazz.
  bool IsInstanceConstant(intptr_t constant_index, const Class& clazz);

  // Reads a constant at the given index (possibly by recursing
  // into sub-constants).
  InstancePtr ReadConstant(intptr_t constant_index);

  intptr_t NumConstants();

 private:
  InstancePtr ReadConstantInternal(intptr_t constant_index);
  intptr_t NavigateToIndex(KernelReaderHelper* reader, intptr_t constant_index);
  intptr_t NumConstants(KernelReaderHelper* reader);

  KernelReaderHelper* helper_;
  Zone* zone_;
  TranslationHelper& translation_helper_;
  ActiveClass* active_class_;
  const Script& script_;
  Object& result_;

  DISALLOW_COPY_AND_ASSIGN(ConstantReader);
};

}  // namespace kernel
}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_FRONTEND_CONSTANT_READER_H_
