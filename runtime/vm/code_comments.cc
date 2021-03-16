// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
#include "vm/globals.h"  // For INCLUDE_IL_PRINTER
#if defined(INCLUDE_IL_PRINTER)

#include "vm/code_comments.h"
#if !defined(DART_PRECOMPILED_RUNTIME)
#include "vm/compiler/assembler/assembler.h"
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
#include "vm/object.h"

namespace dart {

#if !defined(DART_PRECOMPILED_RUNTIME)
const CodeComments& CreateCommentsFrom(compiler::Assembler* assembler) {
  const auto& comments = assembler->comments();
  Code::Comments& result = Code::Comments::New(comments.length());

  for (intptr_t i = 0; i < comments.length(); i++) {
    result.SetPCOffsetAt(i, comments[i]->pc_offset());
    result.SetCommentAt(i, comments[i]->comment());
  }

  return result;
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

}  // namespace dart
#endif  // defined(INCLUDE_IL_PRINTER)
