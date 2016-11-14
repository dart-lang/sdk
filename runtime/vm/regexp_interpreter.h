// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A simple interpreter for the Irregexp byte code.

#ifndef RUNTIME_VM_REGEXP_INTERPRETER_H_
#define RUNTIME_VM_REGEXP_INTERPRETER_H_

#include "vm/allocation.h"
#include "vm/object.h"
#include "vm/zone.h"

namespace dart {

class IrregexpInterpreter : public AllStatic {
 public:
  enum IrregexpResult { RE_FAILURE = 0, RE_SUCCESS = 1, RE_EXCEPTION = -1 };

  static IrregexpResult Match(const TypedData& bytecode,
                              const String& subject,
                              int32_t* captures,
                              intptr_t start_position,
                              Zone* zone);
};

}  // namespace dart

#endif  // RUNTIME_VM_REGEXP_INTERPRETER_H_
