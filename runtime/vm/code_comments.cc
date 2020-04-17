// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
#if !defined(DART_PRECOMPILED_RUNTIME) &&                                      \
    (!defined(PRODUCT) || defined(FORCE_INCLUDE_DISASSEMBLER))

#include "vm/code_comments.h"

namespace dart {

const Code::Comments& CreateCommentsFrom(compiler::Assembler* assembler) {
  const auto& comments = assembler->comments();
  Code::Comments& result = Code::Comments::New(comments.length());

  for (intptr_t i = 0; i < comments.length(); i++) {
    result.SetPCOffsetAt(i, comments[i]->pc_offset());
    result.SetCommentAt(i, comments[i]->comment());
  }

  return result;
}

}  // namespace dart
#endif  // !defined(DART_PRECOMPILED_RUNTIME) &&                               \
        // (!defined(PRODUCT) || defined(FORCE_INCLUDE_DISASSEMBLER))
