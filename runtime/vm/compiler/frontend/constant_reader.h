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

  // Peeks to see if constant at the given offset will evaluate to
  // instance of the given clazz.
  bool IsInstanceConstant(intptr_t constant_offset, const Class& clazz);

  // Reads a constant at the given offset (possibly by recursing
  // into sub-constants).
  InstancePtr ReadConstant(intptr_t constant_offset);

 private:
  InstancePtr ReadConstantInternal(intptr_t constant_offset);

  KernelReaderHelper* helper_;
  Zone* zone_;
  TranslationHelper& translation_helper_;
  ActiveClass* active_class_;
  const Script& script_;
  Instance& result_;

  DISALLOW_COPY_AND_ASSIGN(ConstantReader);
};

class KernelConstMapKeyEqualsTraits : public AllStatic {
 public:
  static const char* Name() { return "KernelConstMapKeyEqualsTraits"; }
  static bool ReportStats() { return false; }

  static bool IsMatch(const Object& a, const Object& b) {
    const Smi& key1 = Smi::Cast(a);
    const Smi& key2 = Smi::Cast(b);
    return (key1.Value() == key2.Value());
  }
  static bool IsMatch(const intptr_t key1, const Object& b) {
    return KeyAsSmi(key1) == Smi::Cast(b).raw();
  }
  static uword Hash(const Object& obj) {
    const Smi& key = Smi::Cast(obj);
    return HashValue(key.Value());
  }
  static uword Hash(const intptr_t key) {
    return HashValue(Smi::Value(KeyAsSmi(key)));
  }
  static ObjectPtr NewKey(const intptr_t key) { return KeyAsSmi(key); }

 private:
  static uword HashValue(intptr_t pos) { return pos % (Smi::kMaxValue - 13); }

  static SmiPtr KeyAsSmi(const intptr_t key) {
    ASSERT(key >= 0);
    return Smi::New(key);
  }
};
typedef UnorderedHashMap<KernelConstMapKeyEqualsTraits> KernelConstantsMap;

}  // namespace kernel
}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_FRONTEND_CONSTANT_READER_H_
