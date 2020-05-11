// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_REGEXP_PARSER_H_
#define RUNTIME_VM_REGEXP_PARSER_H_

#include "vm/allocation.h"
#include "vm/growable_array.h"
#include "vm/regexp_ast.h"

namespace dart {

// Accumulates RegExp atoms and assertions into lists of terms and alternatives.
class RegExpBuilder : public ZoneAllocated {
 public:
  explicit RegExpBuilder(RegExpFlags flags);

  void AddCharacter(uint16_t character);
  void AddUnicodeCharacter(uint32_t character);
  void AddEscapedUnicodeCharacter(uint32_t character);
  // "Adds" an empty expression. Does nothing except consume a
  // following quantifier
  void AddEmpty();
  void AddCharacterClass(RegExpCharacterClass* cc);
  void AddCharacterClassForDesugaring(uint32_t c);
  void AddAtom(RegExpTree* tree);
  void AddTerm(RegExpTree* tree);
  void AddAssertion(RegExpTree* tree);
  void NewAlternative();  // '|'
  // Attempt to add a quantifier to the last atom added. The return value
  // denotes whether the attempt succeeded, since some atoms like lookbehind
  // cannot be quantified.
  bool AddQuantifierToAtom(intptr_t min,
                           intptr_t max,
                           RegExpQuantifier::QuantifierType type);
  RegExpTree* ToRegExp();
  RegExpFlags flags() const { return flags_; }
  bool ignore_case() const { return flags_.IgnoreCase(); }
  bool is_multi_line() const { return flags_.IsMultiLine(); }
  bool is_dot_all() const { return flags_.IsDotAll(); }

 private:
  static const uint16_t kNoPendingSurrogate = 0;
  void AddLeadSurrogate(uint16_t lead_surrogate);
  void AddTrailSurrogate(uint16_t trail_surrogate);
  void FlushPendingSurrogate();
  void FlushCharacters();
  void FlushText();
  void FlushTerms();
  bool NeedsDesugaringForUnicode(RegExpCharacterClass* cc);
  bool NeedsDesugaringForIgnoreCase(uint32_t c);

  Zone* zone() const { return zone_; }
  bool is_unicode() const { return flags_.IsUnicode(); }

  Zone* zone_;
  bool pending_empty_;
  RegExpFlags flags_;
  ZoneGrowableArray<uint16_t>* characters_;
  uint16_t pending_surrogate_;
  GrowableArray<RegExpTree*> terms_;
  GrowableArray<RegExpTree*> text_;
  GrowableArray<RegExpTree*> alternatives_;
#ifdef DEBUG
  enum {ADD_NONE, ADD_CHAR, ADD_TERM, ADD_ASSERT, ADD_ATOM} last_added_;
#define LAST(x) last_added_ = x;
#else
#define LAST(x)
#endif
};

using RegExpCaptureName = ZoneGrowableArray<uint16_t>;

class RegExpParser : public ValueObject {
 public:
  RegExpParser(const String& in, String* error, RegExpFlags regexp_flags);

  static void ParseRegExp(const String& input,
                          RegExpFlags regexp_flags,
                          RegExpCompileData* result);

  RegExpTree* ParsePattern();
  RegExpTree* ParseDisjunction();
  RegExpTree* ParseGroup();

  // Parses a {...,...} quantifier and stores the range in the given
  // out parameters.
  bool ParseIntervalQuantifier(intptr_t* min_out, intptr_t* max_out);

  // Parses and returns a single escaped character.  The character
  // must not be 'b' or 'B' since they are usually handle specially.
  uint32_t ParseClassCharacterEscape();

  // Checks whether the following is a length-digit hexadecimal number,
  // and sets the value if it is.
  bool ParseHexEscape(intptr_t length, uint32_t* value);
  bool ParseUnicodeEscape(uint32_t* value);
  bool ParseUnlimitedLengthHexNumber(uint32_t max_value, uint32_t* value);

  // Parses either {UNICODE_PROPERTY_NAME=UNICODE_PROPERTY_VALUE} or
  // the shorthand {UNICODE_PROPERTY_NAME_OR_VALUE} and stores the
  // result in the given out parameters. If the shorthand is used,
  // nothing will be added to name_2.
  bool ParsePropertyClassName(ZoneGrowableArray<char>* name_1,
                              ZoneGrowableArray<char>* name_2);
  // Adds the specified unicode property to the provided character range.
  bool AddPropertyClassRange(ZoneGrowableArray<CharacterRange>* add_to,
                             bool negate,
                             ZoneGrowableArray<char>* name_1,
                             ZoneGrowableArray<char>* name_2);
  // Returns a regexp node that corresponds to one of these unicode
  // property sequences: "Any", "ASCII", "Assigned".
  RegExpTree* GetPropertySequence(ZoneGrowableArray<char>* name_1);
  RegExpTree* ParseCharacterClass(const RegExpBuilder* builder);

  uint32_t ParseOctalLiteral();

  // Tries to parse the input as a back reference.  If successful it
  // stores the result in the output parameter and returns true.  If
  // it fails it will push back the characters read so the same characters
  // can be reparsed.
  bool ParseBackReferenceIndex(intptr_t* index_out);

  // Attempts to parse a possible escape within a character class.
  bool ParseClassEscape(ZoneGrowableArray<CharacterRange>* ranges,
                        bool add_unicode_case_equivalents,
                        uint32_t* char_out);
  void ReportError(const char* message);
  void Advance();
  void Advance(intptr_t dist);
  void Reset(intptr_t pos);

  // Reports whether the pattern might be used as a literal search string.
  // Only use if the result of the parse is a single atom node.
  bool simple();
  bool contains_anchor() { return contains_anchor_; }
  void set_contains_anchor() { contains_anchor_ = true; }
  intptr_t captures_started() { return captures_started_; }
  intptr_t position() { return next_pos_ - 1; }
  bool is_unicode() const { return top_level_flags_.IsUnicode(); }

  static bool IsSyntaxCharacterOrSlash(uint32_t c);

  static const intptr_t kMaxCaptures = 1 << 16;
  static const uint32_t kEndMarker = (1 << 21);

 private:
  enum SubexpressionType {
    INITIAL,
    CAPTURE,  // All positive values represent captures.
    POSITIVE_LOOKAROUND,
    NEGATIVE_LOOKAROUND,
    GROUPING
  };

  class RegExpParserState : public ZoneAllocated {
   public:
    RegExpParserState(RegExpParserState* previous_state,
                      SubexpressionType group_type,
                      RegExpLookaround::Type lookaround_type,
                      intptr_t disjunction_capture_index,
                      const RegExpCaptureName* capture_name,
                      RegExpFlags flags,
                      Zone* zone)
        : previous_state_(previous_state),
          builder_(new (zone) RegExpBuilder(flags)),
          group_type_(group_type),
          lookaround_type_(lookaround_type),
          disjunction_capture_index_(disjunction_capture_index),
          capture_name_(capture_name) {}
    // Parser state of containing expression, if any.
    RegExpParserState* previous_state() { return previous_state_; }
    bool IsSubexpression() { return previous_state_ != NULL; }
    // RegExpBuilder building this regexp's AST.
    RegExpBuilder* builder() { return builder_; }
    // Type of regexp being parsed (parenthesized group or entire regexp).
    SubexpressionType group_type() { return group_type_; }
    // Lookahead or lookbehind.
    RegExpLookaround::Type lookaround_type() { return lookaround_type_; }
    // Index in captures array of first capture in this sub-expression, if any.
    // Also the capture index of this sub-expression itself, if group_type
    // is CAPTURE.
    intptr_t capture_index() { return disjunction_capture_index_; }
    const RegExpCaptureName* capture_name() const { return capture_name_; }

    bool IsNamedCapture() const { return capture_name_ != nullptr; }

    // Check whether the parser is inside a capture group with the given index.
    bool IsInsideCaptureGroup(intptr_t index);
    // Check whether the parser is inside a capture group with the given name.
    bool IsInsideCaptureGroup(const RegExpCaptureName* name);

   private:
    // Linked list implementation of stack of states.
    RegExpParserState* previous_state_;
    // Builder for the stored disjunction.
    RegExpBuilder* builder_;
    // Stored disjunction type (capture, look-ahead or grouping), if any.
    SubexpressionType group_type_;
    // Stored read direction.
    const RegExpLookaround::Type lookaround_type_;
    // Stored disjunction's capture index (if any).
    intptr_t disjunction_capture_index_;
    // Stored capture name (if any).
    const RegExpCaptureName* const capture_name_;
  };

  // Return the 1-indexed RegExpCapture object, allocate if necessary.
  RegExpCapture* GetCapture(intptr_t index);

  // Creates a new named capture at the specified index. Must be called exactly
  // once for each named capture. Fails if a capture with the same name is
  // encountered.
  void CreateNamedCaptureAtIndex(const RegExpCaptureName* name, intptr_t index);

  // Parses the name of a capture group (?<name>pattern). The name must adhere
  // to IdentifierName in the ECMAScript standard.
  const RegExpCaptureName* ParseCaptureGroupName();

  bool ParseNamedBackReference(RegExpBuilder* builder,
                               RegExpParserState* state);
  RegExpParserState* ParseOpenParenthesis(RegExpParserState* state);
  intptr_t GetNamedCaptureIndex(const RegExpCaptureName* name);

  // After the initial parsing pass, patch corresponding RegExpCapture objects
  // into all RegExpBackReferences. This is done after initial parsing in order
  // to avoid complicating cases in which references come before the capture.
  void PatchNamedBackReferences();

  ArrayPtr CreateCaptureNameMap();

  // Returns true iff the pattern contains named captures. May call
  // ScanForCaptures to look ahead at the remaining pattern.
  bool HasNamedCaptures();

  Zone* zone() { return zone_; }

  uint32_t current() { return current_; }
  bool has_more() { return has_more_; }
  bool has_next() { return next_pos_ < in().Length(); }
  uint32_t Next();
  uint32_t ReadNext(bool update_position);
  const String& in() { return in_; }
  void ScanForCaptures();

  Zone* zone_;
  ZoneGrowableArray<RegExpCapture*>* captures_;
  ZoneGrowableArray<RegExpCapture*>* named_captures_;
  ZoneGrowableArray<RegExpBackReference*>* named_back_references_;
  const String& in_;
  uint32_t current_;
  intptr_t next_pos_;
  intptr_t captures_started_;
  // The capture count is only valid after we have scanned for captures.
  intptr_t capture_count_;
  bool has_more_;
  RegExpFlags top_level_flags_;
  bool simple_;
  bool contains_anchor_;
  bool is_scanned_for_captures_;
  bool has_named_captures_;
};

}  // namespace dart

#endif  // RUNTIME_VM_REGEXP_PARSER_H_
