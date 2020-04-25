// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/regexp_assembler.h"

#include "unicode/uchar.h"

#include "platform/unicode.h"

#include "vm/flags.h"
#include "vm/regexp.h"
#include "vm/runtime_entry.h"
#include "vm/unibrow-inl.h"

namespace dart {

void PrintUtf16(uint16_t c) {
  const char* format =
      (0x20 <= c && c <= 0x7F) ? "%c" : (c <= 0xff) ? "\\x%02x" : "\\u%04x";
  OS::PrintErr(format, c);
}

uword /*BoolPtr*/ CaseInsensitiveCompareUCS2(uword /*StringPtr*/ str_raw,
                                             uword /*SmiPtr*/ lhs_index_raw,
                                             uword /*SmiPtr*/ rhs_index_raw,
                                             uword /*SmiPtr*/ length_raw) {
  const String& str = String::Handle(static_cast<StringPtr>(str_raw));
  const Smi& lhs_index = Smi::Handle(static_cast<SmiPtr>(lhs_index_raw));
  const Smi& rhs_index = Smi::Handle(static_cast<SmiPtr>(rhs_index_raw));
  const Smi& length = Smi::Handle(static_cast<SmiPtr>(length_raw));

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
          return static_cast<uword>(Bool::False().raw());
        }
      }
    }
  }
  return static_cast<uword>(Bool::True().raw());
}

uword /*BoolPtr*/ CaseInsensitiveCompareUTF16(uword /*StringPtr*/ str_raw,
                                              uword /*SmiPtr*/ lhs_index_raw,
                                              uword /*SmiPtr*/ rhs_index_raw,
                                              uword /*SmiPtr*/ length_raw) {
  const String& str = String::Handle(static_cast<StringPtr>(str_raw));
  const Smi& lhs_index = Smi::Handle(static_cast<SmiPtr>(lhs_index_raw));
  const Smi& rhs_index = Smi::Handle(static_cast<SmiPtr>(rhs_index_raw));
  const Smi& length = Smi::Handle(static_cast<SmiPtr>(length_raw));

  for (intptr_t i = 0; i < length.Value(); i++) {
    int32_t c1 = str.CharAt(lhs_index.Value() + i);
    int32_t c2 = str.CharAt(rhs_index.Value() + i);
    if (Utf16::IsLeadSurrogate(c1)) {
      // Non-BMP characters do not have case-equivalents in the BMP.
      // Both have to be non-BMP for them to be able to match.
      if (!Utf16::IsLeadSurrogate(c2))
        return static_cast<uword>(Bool::False().raw());
      if (i + 1 < length.Value()) {
        uint16_t c1t = str.CharAt(lhs_index.Value() + i + 1);
        uint16_t c2t = str.CharAt(rhs_index.Value() + i + 1);
        if (Utf16::IsTrailSurrogate(c1t) && Utf16::IsTrailSurrogate(c2t)) {
          c1 = Utf16::Decode(c1, c1t);
          c2 = Utf16::Decode(c2, c2t);
          i++;
        }
      }
    }
    c1 = u_foldCase(c1, U_FOLD_CASE_DEFAULT);
    c2 = u_foldCase(c2, U_FOLD_CASE_DEFAULT);
    if (c1 != c2) return static_cast<uword>(Bool::False().raw());
  }
  return static_cast<uword>(Bool::True().raw());
}

DEFINE_RAW_LEAF_RUNTIME_ENTRY(
    CaseInsensitiveCompareUCS2,
    4,
    false /* is_float */,
    reinterpret_cast<RuntimeFunction>(&CaseInsensitiveCompareUCS2));

DEFINE_RAW_LEAF_RUNTIME_ENTRY(
    CaseInsensitiveCompareUTF16,
    4,
    false /* is_float */,
    reinterpret_cast<RuntimeFunction>(&CaseInsensitiveCompareUTF16));

BlockLabel::BlockLabel() {
#if !defined(DART_PRECOMPILED_RUNTIME)
  if (!FLAG_interpret_irregexp) {
    // Only needed by the compiled IR backend.
    block_ =
        new JoinEntryInstr(-1, -1, CompilerState::Current().GetNextDeoptId());
  }
#endif
}

RegExpMacroAssembler::RegExpMacroAssembler(Zone* zone)
    : slow_safe_compiler_(false), global_mode_(NOT_GLOBAL), zone_(zone) {}

RegExpMacroAssembler::~RegExpMacroAssembler() {}

void RegExpMacroAssembler::CheckNotInSurrogatePair(intptr_t cp_offset,
                                                   BlockLabel* on_failure) {
  BlockLabel ok;
  // Check that current character is not a trail surrogate.
  LoadCurrentCharacter(cp_offset, &ok);
  CheckCharacterNotInRange(Utf16::kTrailSurrogateStart,
                           Utf16::kTrailSurrogateEnd, &ok);
  // Check that previous character is not a lead surrogate.
  LoadCurrentCharacter(cp_offset - 1, &ok);
  CheckCharacterInRange(Utf16::kLeadSurrogateStart, Utf16::kLeadSurrogateEnd,
                        on_failure);
  BindBlock(&ok);
}

}  // namespace dart
