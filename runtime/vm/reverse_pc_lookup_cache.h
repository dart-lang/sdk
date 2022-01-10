// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_REVERSE_PC_LOOKUP_CACHE_H_
#define RUNTIME_VM_REVERSE_PC_LOOKUP_CACHE_H_

#include "vm/allocation.h"
#include "vm/globals.h"
#include "vm/tagged_pointer.h"

namespace dart {

class IsolateGroup;

// This class provides mechanism to find Code and CompressedStackMaps
// objects corresponding to the given PC.
// Can only be used in AOT runtime with bare instructions.
class ReversePc : public AllStatic {
 public:
  // Looks for Code object corresponding to |pc| in the
  // given isolate |group| and vm isolate group.
  static CodePtr Lookup(IsolateGroup* group, uword pc, bool is_return_address);

  // Looks for CompressedStackMaps corresponding to |pc| in the
  // given isolate |group| and vm isolate group.
  // Sets |code_start| to the beginning of the instructions corresponding
  // to |pc| (like Code::PayloadStart()).
  static CompressedStackMapsPtr FindCompressedStackMaps(IsolateGroup* group,
                                                        uword pc,
                                                        bool is_return_address,
                                                        uword* code_start);

 private:
  static ObjectPtr FindCodeDescriptorInGroup(IsolateGroup* group,
                                             uword pc,
                                             bool is_return_address,
                                             uword* code_start);
  static ObjectPtr FindCodeDescriptor(IsolateGroup* group,
                                      uword pc,
                                      bool is_return_address,
                                      uword* code_start);
};

}  // namespace dart

#endif  // RUNTIME_VM_REVERSE_PC_LOOKUP_CACHE_H_
