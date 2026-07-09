// Copyright 2012 the V8 project authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "vm/regexp/regexp-macro-assembler.h"

#include <limits>

#include "vm/regexp/base.h"
#include "vm/regexp/label.h"
#include "vm/regexp/special-case.h"

#ifdef V8_INTL_SUPPORT
#include "unicode/uchar.h"
#include "unicode/unistr.h"
#endif  // V8_INTL_SUPPORT

namespace dart {

RegExpMacroAssembler::RegExpMacroAssembler(Isolate* isolate,
                                           Zone* zone,
                                           Mode mode)
    : slow_safe_compiler_(false),
      backtrack_limit_(JSRegExp::kNoBacktrackLimit),
      global_mode_(NOT_GLOBAL),
      isolate_(isolate),
      zone_(zone),
      mode_(mode) {}

bool RegExpMacroAssembler::has_backtrack_limit() const {
  return backtrack_limit_ != JSRegExp::kNoBacktrackLimit;
}

int RegExpMacroAssembler::stack_limit_slack_slot_count() const {
  return 32;
}

bool RegExpMacroAssembler::CanReadUnaligned() const {
  return true;
}

// static
int RegExpMacroAssembler::CaseInsensitiveCompareNonUnicode(Address byte_offset1,
                                                           Address byte_offset2,
                                                           size_t byte_length,
                                                           Isolate* isolate) {
#ifdef V8_INTL_SUPPORT
  DCHECK_EQ(0, byte_length % 2);
  size_t length = byte_length / 2;
  uint16_t* substring1 = reinterpret_cast<uint16_t*>(byte_offset1);
  uint16_t* substring2 = reinterpret_cast<uint16_t*>(byte_offset2);

  for (size_t i = 0; i < length; i++) {
    UChar32 c1 = RegExpCaseFolding::Canonicalize(substring1[i]);
    UChar32 c2 = RegExpCaseFolding::Canonicalize(substring2[i]);
    if (c1 != c2) {
      return 0;
    }
  }
  return 1;
#else
  return CaseInsensitiveCompareUnicode(byte_offset1, byte_offset2, byte_length,
                                       isolate);
#endif
}

// static
int RegExpMacroAssembler::CaseInsensitiveCompareUnicode(Address byte_offset1,
                                                        Address byte_offset2,
                                                        size_t byte_length,
                                                        Isolate* isolate) {
  // This function is not allowed to cause a garbage collection.
  // A GC might move the calling generated code and invalidate the
  // return address on the stack.
  DCHECK_EQ(0, byte_length % 2);

#ifdef V8_INTL_SUPPORT
  int32_t length = static_cast<int32_t>(byte_length >> 1);
  icu::UnicodeString uni_str_1(reinterpret_cast<const char16_t*>(byte_offset1),
                               length);
  return uni_str_1.caseCompare(reinterpret_cast<const char16_t*>(byte_offset2),
                               length, U_FOLD_CASE_DEFAULT) == 0;
#else
  uint16_t* substring1 = reinterpret_cast<uint16_t*>(byte_offset1);
  uint16_t* substring2 = reinterpret_cast<uint16_t*>(byte_offset2);
  size_t length = byte_length >> 1;
  DCHECK_NOT_NULL(isolate);
  unibrow::Mapping<unibrow::Ecma262Canonicalize>* canonicalize =
      isolate->regexp_macro_assembler_canonicalize();
  for (size_t i = 0; i < length; i++) {
    unibrow::uchar c1 = substring1[i];
    unibrow::uchar c2 = substring2[i];
    if (c1 != c2) {
      unibrow::uchar s1[1] = {c1};
      canonicalize->get(c1, '\0', s1);
      if (s1[0] != c2) {
        unibrow::uchar s2[1] = {c2};
        canonicalize->get(c2, '\0', s2);
        if (s1[0] != s2[0]) {
          return 0;
        }
      }
    }
  }
  return 1;
#endif  // V8_INTL_SUPPORT
}

namespace {

uint32_t Hash(const ZoneList<CharacterRange>* ranges) {
  size_t seed = 0;
  for (int i = 0; i < ranges->length(); i++) {
    const CharacterRange& r = ranges->at(i);
    seed ^= r.from();
    seed ^= r.to();
  }
  return static_cast<uint32_t>(seed);
}

constexpr uint32_t MaskEndOfRangeMarker(uint32_t c) {
  // CharacterRanges may use 0x10ffff as the end-of-range marker irrespective
  // of whether the regexp IsUnicode or not; translate the marker value here.
  DCHECK_IMPLIES(c > kMaxUint16, c == String::kMaxCodePoint);
  return c & 0xffff;
}

int RangeArrayLengthFor(const ZoneList<CharacterRange>* ranges) {
  const int ranges_length = ranges->length();
  return MaskEndOfRangeMarker(ranges->at(ranges_length - 1).to()) == kMaxUint16
             ? ranges_length * 2 - 1
             : ranges_length * 2;
}

bool Equals(const ZoneList<CharacterRange>* lhs, const TypedData& rhs) {
  ASSERT(rhs.ElementSizeInBytes() == 2);  // uint16
  const int rhs_length = rhs.Length();
  if (rhs_length != RangeArrayLengthFor(lhs)) return false;
  for (int i = 0; i < lhs->length(); i++) {
    const CharacterRange& r = lhs->at(i);
    if (rhs.GetUint16(i * 2 + 0) != r.from()) return false;
    if (i * 2 + 1 == rhs_length) break;
    if (rhs.GetUint16(i * 2 + 1) != r.to() + 1) return false;
  }
  return true;
}

TypedDataPtr MakeRangeArray(Isolate* isolate,
                            const ZoneList<CharacterRange>* ranges) {
  const int ranges_length = ranges->length();
  const int range_array_length = RangeArrayLengthFor(ranges);
  TypedData& range_array = TypedData::Handle(
      TypedData::New(kTypedDataUint16ArrayCid, range_array_length));
  for (int i = 0; i < ranges_length; i++) {
    const CharacterRange& r = ranges->at(i);
    DCHECK_LE(r.from(), kMaxUint16);
    range_array.SetUint16(i * 2 + 0, r.from());
    const uint32_t to = MaskEndOfRangeMarker(r.to());
    if (i == ranges_length - 1 && to == kMaxUint16) {
      DCHECK_EQ(range_array_length, ranges_length * 2 - 1);
      break;  // Avoid overflow by leaving the last range open-ended.
    }
    DCHECK_LT(to, kMaxUint16);
    range_array.SetUint16(i * 2 + 1, to + 1);  // Exclusive.
  }
  return range_array.ptr();
}

}  // namespace

TypedDataPtr NativeRegExpMacroAssembler::GetOrAddRangeArray(
    const ZoneList<CharacterRange>* ranges) {
  const uint32_t hash = Hash(ranges);

  if (range_array_cache_.count(hash) != 0) {
    TypedData* range_array = range_array_cache_[hash];
    if (Equals(ranges, *range_array)) return range_array->ptr();
  }

  TypedDataPtr range_array = MakeRangeArray(isolate(), ranges);
  range_array_cache_[hash] = &TypedData::Handle(range_array);
  return range_array;
}

// static
uint32_t RegExpMacroAssembler::IsCharacterInRangeArray(uint32_t current_char,
                                                       Address raw_byte_array) {
  // Use uint32_t to avoid complexity around bool return types (which may be
  // optimized to use only the least significant byte).
  static constexpr uint32_t kTrue = 1;
  static constexpr uint32_t kFalse = 0;

  // Uint16
  const TypedData& ranges = TypedData::CheckedHandle(
      Thread::Current()->zone(), UntaggedObject::FromAddr(raw_byte_array));
  DCHECK_GE(ranges.Length(), 1);

  // Shortcut for fully out of range chars.
  if (current_char < ranges.GetUint16(0)) return kFalse;
  if (current_char >= ranges.GetUint16(ranges.Length() - 1)) {
    // The last range may be open-ended.
    return (ranges.Length() % 2) == 0 ? kFalse : kTrue;
  }

  // Binary search for the matching range. `ranges` is encoded as
  // [from0, to0, from1, to1, ..., fromN, toN], or
  // [from0, to0, from1, to1, ..., fromN] (open-ended last interval).

  int mid, lower = 0, upper = ranges.Length();
  do {
    mid = lower + (upper - lower) / 2;
    const uint16_t elem = ranges.GetUint16(mid);
    if (current_char < elem) {
      upper = mid;
    } else if (current_char > elem) {
      lower = mid + 1;
    } else {
      DCHECK_EQ(current_char, elem);
      break;
    }
  } while (lower < upper);

  const bool current_char_ge_last_elem = current_char >= ranges.GetUint16(mid);
  const int current_range_start_index =
      current_char_ge_last_elem ? mid : mid - 1;

  // Ranges start at even indices and end at odd indices.
  return (current_range_start_index % 2) == 0 ? kTrue : kFalse;
}

void RegExpMacroAssembler::CheckNotInSurrogatePair(int cp_offset,
                                                   V8Label* on_failure) {
  V8Label ok;
  // Check that current character is not a trail surrogate.
  LoadCurrentCharacter(cp_offset, &ok);
  CheckCharacterNotInRange(kTrailSurrogateStart, kTrailSurrogateEnd, &ok);
  // Check that previous character is not a lead surrogate.
  LoadCurrentCharacter(cp_offset - 1, &ok);
  CheckCharacterInRange(kLeadSurrogateStart, kLeadSurrogateEnd, on_failure);
  Bind(&ok);
}

void RegExpMacroAssembler::LoadCurrentCharacter(int cp_offset,
                                                V8Label* on_end_of_input,
                                                bool check_bounds,
                                                int characters,
                                                int eats_at_least) {
  // By default, eats_at_least = characters.
  if (eats_at_least == kUseCharactersValue) {
    eats_at_least = characters;
  }

  LoadCurrentCharacterImpl(cp_offset, on_end_of_input, check_bounds, characters,
                           eats_at_least);
}

void NativeRegExpMacroAssembler::LoadCurrentCharacterImpl(
    int cp_offset,
    V8Label* on_end_of_input,
    bool check_bounds,
    int characters,
    int eats_at_least) {
  // It's possible to preload a small number of characters when each success
  // path requires a large number of characters, but not the reverse.
  DCHECK_GE(eats_at_least, characters);

  CHECK(base::IsInRange(cp_offset, kMinCPOffset, kMaxCPOffset));
  if (check_bounds) {
    if (cp_offset >= 0) {
      CheckPosition(cp_offset + eats_at_least - 1, on_end_of_input);
    } else {
      CheckPosition(cp_offset, on_end_of_input);
    }
  }
  LoadCurrentCharacterUnchecked(cp_offset, characters);
}

void RegExpMacroAssembler::SkipUntilCharAnd(int cp_offset,
                                            int advance_by,
                                            unsigned character,
                                            unsigned mask,
                                            int eats_at_least,
                                            V8Label* on_match,
                                            V8Label* on_no_match) {
  V8Label loop;
  Bind(&loop);
  LoadCurrentCharacter(cp_offset, on_no_match, true, 1, eats_at_least);
  CheckCharacterAfterAnd(character, mask, on_match);
  AdvanceCurrentPosition(advance_by);
  GoTo(&loop);
}

void RegExpMacroAssembler::SkipUntilChar(int cp_offset,
                                         int advance_by,
                                         unsigned character,
                                         V8Label* on_match,
                                         V8Label* on_no_match) {
  V8Label loop;
  Bind(&loop);
  LoadCurrentCharacter(cp_offset, on_no_match, true);
  CheckCharacter(character, on_match);
  AdvanceCurrentPosition(advance_by);
  GoTo(&loop);
}

void RegExpMacroAssembler::SkipUntilCharPosChecked(int cp_offset,
                                                   int advance_by,
                                                   unsigned character,
                                                   int eats_at_least,
                                                   V8Label* on_match,
                                                   V8Label* on_no_match) {
  V8Label loop;
  Bind(&loop);
  LoadCurrentCharacter(cp_offset, on_no_match, true, 1, eats_at_least);
  CheckCharacter(character, on_match);
  AdvanceCurrentPosition(advance_by);
  GoTo(&loop);
}

void RegExpMacroAssembler::SkipUntilCharOrChar(int cp_offset,
                                               int advance_by,
                                               unsigned char1,
                                               unsigned char2,
                                               V8Label* on_match,
                                               V8Label* on_no_match) {
  V8Label loop;
  Bind(&loop);
  LoadCurrentCharacter(cp_offset, on_no_match, true);
  CheckCharacter(char1, on_match);
  CheckCharacter(char2, on_match);
  AdvanceCurrentPosition(advance_by);
  GoTo(&loop);
}

void RegExpMacroAssembler::SkipUntilGtOrNotBitInTable(int cp_offset,
                                                      int advance_by,
                                                      unsigned character,
                                                      const TypedData& table,
                                                      V8Label* on_match,
                                                      V8Label* on_no_match) {
  ASSERT(base::IsInRange(character, std::numeric_limits<uint16_t>::min(),
                         std::numeric_limits<uint16_t>::max()));
  V8Label loop, advance_and_continue;
  Bind(&loop);
  LoadCurrentCharacter(cp_offset, on_no_match, true);
  CheckCharacterGT(character, on_match);
  CheckBitInTable(table, &advance_and_continue);
  GoTo(on_match);
  Bind(&advance_and_continue);
  AdvanceCurrentPosition(advance_by);
  GoTo(&loop);
}

void RegExpMacroAssembler::SkipUntilOneOfMasked(int cp_offset,
                                                int advance_by,
                                                unsigned both_chars,
                                                unsigned both_mask,
                                                int max_offset,
                                                unsigned chars1,
                                                unsigned mask1,
                                                unsigned chars2,
                                                unsigned mask2,
                                                V8Label* on_match1,
                                                V8Label* on_match2,
                                                V8Label* on_failure) {
  V8Label loop, found;
  Bind(&loop);
  CheckPosition(max_offset, on_failure);
  LoadCurrentCharacter(cp_offset, on_failure, false, 4);
  CheckCharacterAfterAnd(both_chars, both_mask, &found);
  AdvanceCurrentPosition(advance_by);
  GoTo(&loop);
  Bind(&found);
  CheckCharacterAfterAnd(chars1, mask1, on_match1);
  CheckCharacterAfterAnd(chars2, mask2, on_match2);
  AdvanceCurrentPosition(advance_by);
  GoTo(&loop);
}

bool RegExpMacroAssembler::CanOptimizeSpecialClassRanges(
    StandardCharacterSet character_set) const {
  if (character_set == StandardCharacterSet::kNotWhitespace) {
    // The emitted code for generic character classes is good enough.
    return false;
  }
  if (character_set == StandardCharacterSet::kWhitespace &&
      mode() != Mode::LATIN1) {
    // TODO(pthier): Support \s for 2-byte inputs.
    return false;
  }
  return true;
}

void RegExpMacroAssembler::SkipUntilOneOfMasked3(
    const SkipUntilOneOfMasked3Args& args) {
  // The base implementation for architectures that don't implement simd
  // optimizations.
  //
  // See the definition of the kSkipUntilOneOfMasked3 peephole bytecode
  // for more context. The initial bytecode sequence is:
  //
  // sequence offset name
  // bc0   0  SkipUntilBitInTable
  // bc1  20  CheckPosition
  // bc2  28  Load4CurrentCharsUnchecked
  // bc3  2c  AndCheck4Chars
  // bc4  3c  AdvanceCpAndGoto
  // bc5  48  Load4CurrentChars
  // bc6  4c  AndCheck4Chars
  // bc7  5c  AndCheck4Chars
  // bc8  6c  AndCheckNot4Chars

  V8Label bc0_skip_until_bit_in_table, bc1_check_current_position,
      bc4_advance_cp_and_goto, bc5_load_4_current_chars;
  Bind(&bc0_skip_until_bit_in_table);
  SkipUntilBitInTable(args.bc0_cp_offset, *args.bc0_table,
                      *args.bc0_nibble_table, args.bc0_advance_by,
                      &bc1_check_current_position, &bc1_check_current_position);
  Bind(&bc1_check_current_position);
  CheckPosition(args.bc1_cp_offset, args.bc1_on_failure);
  LoadCurrentCharacter(args.bc2_cp_offset, nullptr, false, 4);
  CheckCharacterAfterAnd(args.bc3_characters, args.bc3_mask,
                         &bc5_load_4_current_chars);
  Bind(&bc4_advance_cp_and_goto);
  AdvanceCurrentPosition(args.bc4_by);
  GoTo(&bc0_skip_until_bit_in_table);
  Bind(&bc5_load_4_current_chars);
  LoadCurrentCharacter(args.bc5_cp_offset, &bc4_advance_cp_and_goto, true, 4);
  CheckCharacterAfterAnd(args.bc6_characters, args.bc6_mask, args.bc6_on_equal);
  CheckCharacterAfterAnd(args.bc7_characters, args.bc7_mask, args.bc7_on_equal);
  CheckNotCharacterAfterAnd(args.bc8_characters, args.bc8_mask,
                            &bc4_advance_cp_and_goto);
  GoTo(args.fallthrough_jump_target);
}

#ifndef COMPILING_IRREGEXP_FOR_EXTERNAL_EMBEDDER

// Returns a {Result} sentinel, or the number of successful matches.
int NativeRegExpMacroAssembler::Match(DirectHandle<IrRegExpData> regexp_data,
                                      const String\DirectHandle<String> subject,
                                      int* offsets_vector,
                                      int offsets_vector_length,
                                      int previous_index,
                                      Isolate* isolate) {
  ASSERT(subject->IsFlat());
  DCHECK_LE(0, previous_index);
  DCHECK_LE(previous_index, subject->length());

  // No allocations before calling the regexp, but we can't use
  // DisallowGarbageCollection, since regexps might be preempted, and another
  // thread might do allocation anyway.

  Tagged<String> subject_ptr = *subject;
  // Character offsets into string.
  int start_offset = previous_index;
  int char_length = subject_ptr->length() - start_offset;
  int slice_offset = 0;

  // The string has been flattened, so if it is a cons string it contains the
  // full string in the first part.
  if (StringShape(subject_ptr).IsCons()) {
    DCHECK_EQ(0, Cast<ConsString>(subject_ptr)->second()->length());
    subject_ptr = Cast<ConsString>(subject_ptr)->first();
  } else if (StringShape(subject_ptr).IsSliced()) {
    Tagged<SlicedString> slice = Cast<SlicedString>(subject_ptr);
    subject_ptr = slice->parent();
    slice_offset = slice->offset();
  }
  if (StringShape(subject_ptr).IsThin()) {
    subject_ptr = Cast<ThinString>(subject_ptr)->actual();
  }
  // Ensure that an underlying string has the same representation.
  bool is_one_byte = subject_ptr->IsOneByteRepresentation();
  ASSERT(IsExternalString(subject_ptr) || IsSeqString(subject_ptr));
  // String is now either Sequential or External
  int char_size_shift = is_one_byte ? 0 : 1;

  DisallowGarbageCollection no_gc;
  const uint8_t* input_start =
      subject_ptr->AddressOfCharacterAt(start_offset + slice_offset, no_gc);
  int byte_length = char_length << char_size_shift;
  const uint8_t* input_end = input_start + byte_length;
  return Execute(*subject, start_offset, input_start, input_end, offsets_vector,
                 offsets_vector_length, isolate, *regexp_data);
}

// static
int NativeRegExpMacroAssembler::ExecuteForTesting(Tagged<String> input,
                                                  int start_offset,
                                                  const uint8_t* input_start,
                                                  const uint8_t* input_end,
                                                  int* output,
                                                  int output_size,
                                                  Isolate* isolate,
                                                  Tagged<JSRegExp> regexp) {
  Tagged<RegExpData> data = regexp->data(isolate);
  return Execute(input, start_offset, input_start, input_end, output,
                 output_size, isolate, SbxCast<IrRegExpData>(data));
}

// Returns a {Result} sentinel, or the number of successful matches.
int NativeRegExpMacroAssembler::Execute(
    Tagged<String>
        input,  // This needs to be the unpacked (sliced, cons) string.
    int start_offset,
    const uint8_t* input_start,
    const uint8_t* input_end,
    int* output,
    int output_size,
    Isolate* isolate,
    Tagged<IrRegExpData> regexp_data) {
  bool is_one_byte = String::IsOneByteRepresentationUnderneath(input);
  Tagged<Code> code = regexp_data->code(isolate, is_one_byte);
  RegExp::CallOrigin call_origin = RegExp::CallOrigin::kFromRuntime;

  using RegexpMatcherSig =
      // NOLINTNEXTLINE(readability/casting)
      int(Address input_string, int start_offset, const uint8_t* input_start,
          const uint8_t* input_end, int* output, int output_size,
          int call_origin, Isolate* isolate, Address regexp_data);

  auto fn = GeneratedCode<RegexpMatcherSig>::FromCode(isolate, code);
  int result = fn.CallSandboxed(input.ptr(), start_offset, input_start,
                                input_end, output, output_size, call_origin,
                                isolate, regexp_data.ptr());
  DCHECK_GE(result, SMALLEST_REGEXP_RESULT);

  if (result == EXCEPTION && !isolate->has_exception()) {
    // We detected a stack overflow (on the backtrack stack) in RegExp code,
    // but haven't created the exception yet. Additionally, we allow heap
    // allocation because even though it invalidates {input_start} and
    // {input_end}, we are about to return anyway.
    AllowGarbageCollection allow_allocation;
    isolate->StackOverflow();
  }
  return result;
}

#endif  // !COMPILING_IRREGEXP_FOR_EXTERNAL_EMBEDDER

// clang-format off
const uint8_t RegExpMacroAssembler::word_character_map_[] = {
    0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u,
    0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u,
    0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u,
    0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u,

    0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u,
    0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u,
    0xFFu, 0xFFu, 0xFFu, 0xFFu, 0xFFu, 0xFFu, 0xFFu, 0xFFu,  // '0' - '7'
    0xFFu, 0xFFu, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u,  // '8' - '9'

    0x00u, 0xFFu, 0xFFu, 0xFFu, 0xFFu, 0xFFu, 0xFFu, 0xFFu,  // 'A' - 'G'
    0xFFu, 0xFFu, 0xFFu, 0xFFu, 0xFFu, 0xFFu, 0xFFu, 0xFFu,  // 'H' - 'O'
    0xFFu, 0xFFu, 0xFFu, 0xFFu, 0xFFu, 0xFFu, 0xFFu, 0xFFu,  // 'P' - 'W'
    0xFFu, 0xFFu, 0xFFu, 0x00u, 0x00u, 0x00u, 0x00u, 0xFFu,  // 'X' - 'Z', '_'

    0x00u, 0xFFu, 0xFFu, 0xFFu, 0xFFu, 0xFFu, 0xFFu, 0xFFu,  // 'a' - 'g'
    0xFFu, 0xFFu, 0xFFu, 0xFFu, 0xFFu, 0xFFu, 0xFFu, 0xFFu,  // 'h' - 'o'
    0xFFu, 0xFFu, 0xFFu, 0xFFu, 0xFFu, 0xFFu, 0xFFu, 0xFFu,  // 'p' - 'w'
    0xFFu, 0xFFu, 0xFFu, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u,  // 'x' - 'z'
    // Latin-1 range
    0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u,
    0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u,
    0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u,
    0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u,

    0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u,
    0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u,
    0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u,
    0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u,

    0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u,
    0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u,
    0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u,
    0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u,

    0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u,
    0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u,
    0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u,
    0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u,
};
// clang-format on

}  // namespace dart
