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
  // Returns True in case of a success, False in case of a failure,
  // Null in case of internal exception,
  // Error in case VM error has to propagated up to the caller.
  static ObjectPtr Match(const TypedData& bytecode,
                         const String& subject,
                         int32_t* captures,
                         intptr_t start_position);
};

}  // namespace dart

#endif  // RUNTIME_VM_REGEXP_INTERPRETER_H_
