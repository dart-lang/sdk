// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_CODE_COMMENTS_H_
#define RUNTIME_VM_CODE_COMMENTS_H_

#if !defined(DART_PRECOMPILED_RUNTIME) &&                                      \
    (!defined(PRODUCT) || defined(FORCE_INCLUDE_DISASSEMBLER))

#include "vm/code_observers.h"
#include "vm/compiler/assembler/assembler.h"
#include "vm/object.h"

namespace dart {

class CodeCommentsWrapper final : public CodeComments {
 public:
  explicit CodeCommentsWrapper(const Code::Comments& comments)
      : comments_(comments), string_(String::Handle()) {}

  intptr_t Length() const override { return comments_.Length(); }

  intptr_t PCOffsetAt(intptr_t i) const override {
    return comments_.PCOffsetAt(i);
  }

  const char* CommentAt(intptr_t i) const override {
    string_ = comments_.CommentAt(i);
    return string_.ToCString();
  }

 private:
  const Code::Comments& comments_;
  String& string_;
};

const Code::Comments& CreateCommentsFrom(compiler::Assembler* assembler);


}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME) &&                               \
        // (!defined(PRODUCT) || defined(FORCE_INCLUDE_DISASSEMBLER))
#endif  // RUNTIME_VM_CODE_COMMENTS_H_
