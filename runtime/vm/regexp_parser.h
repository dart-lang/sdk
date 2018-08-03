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
  RegExpBuilder();

  void AddCharacter(uint16_t character);
  // "Adds" an empty expression. Does nothing except consume a
  // following quantifier
  void AddEmpty();
  void AddAtom(RegExpTree* tree);
  void AddAssertion(RegExpTree* tree);
  void NewAlternative();  // '|'
  void AddQuantifierToAtom(intptr_t min,
                           intptr_t max,
                           RegExpQuantifier::QuantifierType type);
  RegExpTree* ToRegExp();

 private:
  void FlushCharacters();
  void FlushText();
  void FlushTerms();

  Zone* zone() const { return zone_; }

  Zone* zone_;
  bool pending_empty_;
  ZoneGrowableArray<uint16_t>* characters_;
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

class RegExpParser : public ValueObject {
 public:
  RegExpParser(const String& in, String* error, bool multiline_mode);

  static bool ParseRegExp(const String& input,
                          bool multiline,
                          RegExpCompileData* result);

  RegExpTree* ParsePattern();
  RegExpTree* ParseDisjunction();
  RegExpTree* ParseGroup();
  RegExpTree* ParseCharacterClass();

  // Parses a {...,...} quantifier and stores the range in the given
  // out parameters.
  bool ParseIntervalQuantifier(intptr_t* min_out, intptr_t* max_out);

  // Parses and returns a single escaped character.  The character
  // must not be 'b' or 'B' since they are usually handle specially.
  uint32_t ParseClassCharacterEscape();

  // Checks whether the following is a length-digit hexadecimal number,
  // and sets the value if it is.
  bool ParseHexEscape(intptr_t length, uint32_t* value);

  uint32_t ParseOctalLiteral();

  // Tries to parse the input as a back reference.  If successful it
  // stores the result in the output parameter and returns true.  If
  // it fails it will push back the characters read so the same characters
  // can be reparsed.
  bool ParseBackReferenceIndex(intptr_t* index_out);

  CharacterRange ParseClassAtom(uint16_t* char_class);
  void ReportError(const char* message);
  void Advance();
  void Advance(intptr_t dist);
  void Reset(intptr_t pos);

  // Reports whether the pattern might be used as a literal search string.
  // Only use if the result of the parse is a single atom node.
  bool simple();
  bool contains_anchor() { return contains_anchor_; }
  void set_contains_anchor() { contains_anchor_ = true; }
  intptr_t captures_started() {
    return captures_ == NULL ? 0 : captures_->length();
  }
  intptr_t position() { return next_pos_ - 1; }
  bool failed() { return failed_; }

  static const intptr_t kMaxCaptures = 1 << 16;
  static const uint32_t kEndMarker = (1 << 21);

 private:
  enum SubexpressionType {
    INITIAL,
    CAPTURE,  // All positive values represent captures.
    POSITIVE_LOOKAHEAD,
    NEGATIVE_LOOKAHEAD,
    GROUPING
  };

  class RegExpParserState : public ZoneAllocated {
   public:
    RegExpParserState(RegExpParserState* previous_state,
                      SubexpressionType group_type,
                      intptr_t disjunction_capture_index,
                      Zone* zone)
        : previous_state_(previous_state),
          builder_(new (zone) RegExpBuilder()),
          group_type_(group_type),
          disjunction_capture_index_(disjunction_capture_index) {}
    // Parser state of containing expression, if any.
    RegExpParserState* previous_state() { return previous_state_; }
    bool IsSubexpression() { return previous_state_ != NULL; }
    // RegExpBuilder building this regexp's AST.
    RegExpBuilder* builder() { return builder_; }
    // Type of regexp being parsed (parenthesized group or entire regexp).
    SubexpressionType group_type() { return group_type_; }
    // Index in captures array of first capture in this sub-expression, if any.
    // Also the capture index of this sub-expression itself, if group_type
    // is CAPTURE.
    intptr_t capture_index() { return disjunction_capture_index_; }

   private:
    // Linked list implementation of stack of states.
    RegExpParserState* previous_state_;
    // Builder for the stored disjunction.
    RegExpBuilder* builder_;
    // Stored disjunction type (capture, look-ahead or grouping), if any.
    SubexpressionType group_type_;
    // Stored disjunction's capture index (if any).
    intptr_t disjunction_capture_index_;
  };

  Zone* zone() { return zone_; }

  uint32_t current() { return current_; }
  bool has_more() { return has_more_; }
  bool has_next() { return next_pos_ < in().Length(); }
  uint32_t Next();
  const String& in() { return in_; }
  void ScanForCaptures();

  Zone* zone_;
  String* error_;
  ZoneGrowableArray<RegExpCapture*>* captures_;
  const String& in_;
  uint32_t current_;
  intptr_t next_pos_;
  // The capture count is only valid after we have scanned for captures.
  intptr_t capture_count_;
  bool has_more_;
  bool multiline_;
  bool simple_;
  bool contains_anchor_;
  bool is_scanned_for_captures_;
  bool failed_;
};

}  // namespace dart

#endif  // RUNTIME_VM_REGEXP_PARSER_H_
