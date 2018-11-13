// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_FRONTEND_BYTECODE_READER_H_
#define RUNTIME_VM_COMPILER_FRONTEND_BYTECODE_READER_H_

#include "vm/compiler/frontend/kernel_translation_helper.h"
#include "vm/object.h"

#if !defined(DART_PRECOMPILED_RUNTIME)

namespace dart {
namespace kernel {

// Helper class which provides access to bytecode metadata.
class BytecodeMetadataHelper : public MetadataHelper {
 public:
  static const char* tag() { return "vm.bytecode"; }

  explicit BytecodeMetadataHelper(KernelReaderHelper* helper,
                                  TypeTranslator* type_translator,
                                  ActiveClass* active_class);

  bool HasBytecode(intptr_t node_offset);

  void ReadMetadata(const Function& function);

 private:
  // Returns the index of the last read pool entry.
  intptr_t ReadPoolEntries(const Function& function,
                           const Function& inner_function,
                           const ObjectPool& pool,
                           intptr_t from_index);
  RawCode* ReadBytecode(const ObjectPool& pool);
  void ReadExceptionsTable(const Code& bytecode,
                           bool has_exceptions_table = true);
  RawTypedData* NativeEntry(const Function& function,
                            const String& external_name);

  TypeTranslator& type_translator_;
  ActiveClass* const active_class_;

  DISALLOW_COPY_AND_ASSIGN(BytecodeMetadataHelper);
};

class BytecodeReader : public AllStatic {
 public:
  // Reads bytecode for the given function and sets its bytecode field.
  // Returns error (if any), or null.
  static RawError* ReadFunctionBytecode(Thread* thread,
                                        const Function& function);
};

}  // namespace kernel
}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
#endif  // RUNTIME_VM_COMPILER_FRONTEND_BYTECODE_READER_H_
