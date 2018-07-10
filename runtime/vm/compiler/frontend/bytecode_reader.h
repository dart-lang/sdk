// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_FRONTEND_BYTECODE_READER_H_
#define RUNTIME_VM_COMPILER_FRONTEND_BYTECODE_READER_H_

#include "vm/compiler/frontend/kernel_translation_helper.h"
#include "vm/object.h"

#if !defined(DART_PRECOMPILED_RUNTIME)
#if defined(DART_USE_INTERPRETER)

namespace dart {
namespace kernel {

// Helper class which provides access to bytecode metadata.
class BytecodeMetadataHelper : public MetadataHelper {
 public:
  static const char* tag() { return "vm.bytecode"; }

  explicit BytecodeMetadataHelper(KernelReaderHelper* helper,
                                  TypeTranslator* type_translator,
                                  ActiveClass* active_class);

  void ReadMetadata(const Function& function);

 private:
  // Returns the index of the last read pool entry.
  intptr_t ReadPoolEntries(const Function& function,
                           const Function& inner_function,
                           const ObjectPool& pool,
                           intptr_t from_index);
  RawCode* ReadBytecode(const ObjectPool& pool);
  void ReadExceptionsTable(const Code& bytecode);
  RawTypedData* NativeEntry(const Function& function,
                            const String& external_name);

  TypeTranslator& type_translator_;
  ActiveClass* const active_class_;
};

}  // namespace kernel
}  // namespace dart

#endif  // defined(DART_USE_INTERPRETER)
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
#endif  // RUNTIME_VM_COMPILER_FRONTEND_BYTECODE_READER_H_
