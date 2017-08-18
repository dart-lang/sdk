// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/regexp_assembler.h"

#include "vm/flags.h"
#include "vm/regexp.h"
#include "vm/unibrow-inl.h"

namespace dart {

void PrintUtf16(uint16_t c) {
  const char* format =
      (0x20 <= c && c <= 0x7F) ? "%c" : (c <= 0xff) ? "\\x%02x" : "\\u%04x";
  OS::Print(format, c);
}


static RawBool* CaseInsensitiveCompareUC16(RawString* str_raw,
                                           RawSmi* lhs_index_raw,
                                           RawSmi* rhs_index_raw,
                                           RawSmi* length_raw) {
  const String& str = String::Handle(str_raw);
  const Smi& lhs_index = Smi::Handle(lhs_index_raw);
  const Smi& rhs_index = Smi::Handle(rhs_index_raw);
  const Smi& length = Smi::Handle(length_raw);

  // TODO(zerny): Optimize as single instance. V8 has this as an
  // isolate member.
  unibrow::Mapping<unibrow::Ecma262Canonicalize> canonicalize;

  for (intptr_t i = 0; i < length.Value(); i++) {
    int32_t c1 = str.CharAt(lhs_index.Value() + i);
    int32_t c2 = str.CharAt(rhs_index.Value() + i);
    if (c1 != c2) {
      int32_t s1[1] = {c1};
      canonicalize.get(c1, '\0', s1);
      if (s1[0] != c2) {
        int32_t s2[1] = {c2};
        canonicalize.get(c2, '\0', s2);
        if (s1[0] != s2[0]) {
          return Bool::False().raw();
        }
      }
    }
  }
  return Bool::True().raw();
}


DEFINE_RAW_LEAF_RUNTIME_ENTRY(
    CaseInsensitiveCompareUC16,
    4,
    false /* is_float */,
    reinterpret_cast<RuntimeFunction>(&CaseInsensitiveCompareUC16));


BlockLabel::BlockLabel()
    : block_(NULL), is_bound_(false), is_linked_(false), pos_(-1) {
#if !defined(DART_PRECOMPILED_RUNTIME)
  if (!FLAG_interpret_irregexp) {
    // Only needed by the compiled IR backend.
    block_ = new JoinEntryInstr(-1, -1, Thread::Current()->GetNextDeoptId());
  }
#endif
}

RegExpMacroAssembler::RegExpMacroAssembler(Zone* zone)
    : slow_safe_compiler_(false), global_mode_(NOT_GLOBAL), zone_(zone) {}

RegExpMacroAssembler::~RegExpMacroAssembler() {}

}  // namespace dart
