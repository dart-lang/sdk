// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_CODE_COMMENTS_H_
#define RUNTIME_VM_CODE_COMMENTS_H_

#include "vm/globals.h"  // For INCLUDE_IL_PRINTER
#if defined(INCLUDE_IL_PRINTER)

namespace dart {

// An abstract representation of comments associated with the given code
// object. We assume that comments are sorted by PCOffset.
class CodeComments {
 public:
  CodeComments() = default;
  virtual ~CodeComments() = default;

  virtual intptr_t Length() const = 0;
  virtual intptr_t PCOffsetAt(intptr_t index) const = 0;
  virtual const char* CommentAt(intptr_t index) const = 0;
};

#if !defined(DART_PRECOMPILED_RUNTIME)
namespace compiler {
class Assembler;
}
const CodeComments& CreateCommentsFrom(compiler::Assembler* assembler);
#endif

}  // namespace dart

#endif  // defined(INCLUDE_IL_PRINTER)
#endif  // RUNTIME_VM_CODE_COMMENTS_H_
