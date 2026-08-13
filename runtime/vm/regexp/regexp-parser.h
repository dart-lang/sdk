// Copyright 2016 the V8 project authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef V8_REGEXP_REGEXP_PARSER_H_
#define V8_REGEXP_REGEXP_PARSER_H_

#include "vm/allocation.h"
#include "vm/growable_array.h"
#include "vm/regexp/regexp-ast.h"
#include "vm/regexp/regexp-flags.h"

namespace dart {

class String;
class Zone;

struct RegExpCompileData;

class RegExpParser : public AllStatic {
 public:
  static bool ParseRegExpFromHeapString(Isolate* isolate,
                                        Zone* zone,
                                        const String& input,
                                        RegExpFlags flags,
                                        RegExpCompileData* result);

  template <class CharT>
  static bool VerifyRegExpSyntax(Zone* zone,
                                 uintptr_t stack_limit,
                                 const CharT* input,
                                 int input_length,
                                 RegExpFlags flags,
                                 RegExpCompileData* result);
};

}  // namespace dart

#endif  // V8_REGEXP_REGEXP_PARSER_H_
