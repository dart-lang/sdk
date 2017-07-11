// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/longjump.h"
#include "vm/object_store.h"
#include "vm/regexp_parser.h"

namespace dart {

#define Z zone()

// Enables possessive quantifier syntax for testing.
static const bool FLAG_regexp_possessive_quantifier = false;

RegExpBuilder::RegExpBuilder()
    : zone_(Thread::Current()->zone()),
      pending_empty_(false),
      characters_(NULL),
      terms_(),
      text_(),
      alternatives_()
#ifdef DEBUG
      ,
      last_added_(ADD_NONE)
#endif
{
}


void RegExpBuilder::FlushCharacters() {
  pending_empty_ = false;
  if (characters_ != NULL) {
    RegExpTree* atom = new (Z) RegExpAtom(characters_);
    characters_ = NULL;
    text_.Add(atom);
    LAST(ADD_ATOM);
  }
}


void RegExpBuilder::FlushText() {
  FlushCharacters();
  intptr_t num_text = text_.length();
  if (num_text == 0) {
    return;
  } else if (num_text == 1) {
    terms_.Add(text_.Last());
  } else {
    RegExpText* text = new (Z) RegExpText();
    for (intptr_t i = 0; i < num_text; i++)
      text_[i]->AppendToText(text);
    terms_.Add(text);
  }
  text_.Clear();
}


void RegExpBuilder::AddCharacter(uint16_t c) {
  pending_empty_ = false;
  if (characters_ == NULL) {
    characters_ = new (Z) ZoneGrowableArray<uint16_t>(4);
  }
  characters_->Add(c);
  LAST(ADD_CHAR);
}


void RegExpBuilder::AddEmpty() {
  pending_empty_ = true;
}


void RegExpBuilder::AddAtom(RegExpTree* term) {
  if (term->IsEmpty()) {
    AddEmpty();
    return;
  }
  if (term->IsTextElement()) {
    FlushCharacters();
    text_.Add(term);
  } else {
    FlushText();
    terms_.Add(term);
  }
  LAST(ADD_ATOM);
}


void RegExpBuilder::AddAssertion(RegExpTree* assert) {
  FlushText();
  terms_.Add(assert);
  LAST(ADD_ASSERT);
}


void RegExpBuilder::NewAlternative() {
  FlushTerms();
}


void RegExpBuilder::FlushTerms() {
  FlushText();
  intptr_t num_terms = terms_.length();
  RegExpTree* alternative;
  if (num_terms == 0) {
    alternative = RegExpEmpty::GetInstance();
  } else if (num_terms == 1) {
    alternative = terms_.Last();
  } else {
    ZoneGrowableArray<RegExpTree*>* terms =
        new (Z) ZoneGrowableArray<RegExpTree*>();
    for (intptr_t i = 0; i < terms_.length(); i++) {
      terms->Add(terms_[i]);
    }
    alternative = new (Z) RegExpAlternative(terms);
  }
  alternatives_.Add(alternative);
  terms_.Clear();
  LAST(ADD_NONE);
}


RegExpTree* RegExpBuilder::ToRegExp() {
  FlushTerms();
  intptr_t num_alternatives = alternatives_.length();
  if (num_alternatives == 0) {
    return RegExpEmpty::GetInstance();
  }
  if (num_alternatives == 1) {
    return alternatives_.Last();
  }
  ZoneGrowableArray<RegExpTree*>* alternatives =
      new (Z) ZoneGrowableArray<RegExpTree*>();
  for (intptr_t i = 0; i < alternatives_.length(); i++) {
    alternatives->Add(alternatives_[i]);
  }
  return new (Z) RegExpDisjunction(alternatives);
}


void RegExpBuilder::AddQuantifierToAtom(
    intptr_t min,
    intptr_t max,
    RegExpQuantifier::QuantifierType quantifier_type) {
  if (pending_empty_) {
    pending_empty_ = false;
    return;
  }
  RegExpTree* atom;
  if (characters_ != NULL) {
    DEBUG_ASSERT(last_added_ == ADD_CHAR);
    // Last atom was character.

    ZoneGrowableArray<uint16_t>* char_vector =
        new (Z) ZoneGrowableArray<uint16_t>();
    char_vector->AddArray(*characters_);
    intptr_t num_chars = char_vector->length();
    if (num_chars > 1) {
      ZoneGrowableArray<uint16_t>* prefix =
          new (Z) ZoneGrowableArray<uint16_t>();
      for (intptr_t i = 0; i < num_chars - 1; i++) {
        prefix->Add(char_vector->At(i));
      }
      text_.Add(new (Z) RegExpAtom(prefix));
      ZoneGrowableArray<uint16_t>* tail = new (Z) ZoneGrowableArray<uint16_t>();
      tail->Add(char_vector->At(num_chars - 1));
      char_vector = tail;
    }
    characters_ = NULL;
    atom = new (Z) RegExpAtom(char_vector);
    FlushText();
  } else if (text_.length() > 0) {
    DEBUG_ASSERT(last_added_ == ADD_ATOM);
    atom = text_.RemoveLast();
    FlushText();
  } else if (terms_.length() > 0) {
    DEBUG_ASSERT(last_added_ == ADD_ATOM);
    atom = terms_.RemoveLast();
    if (atom->max_match() == 0) {
      // Guaranteed to only match an empty string.
      LAST(ADD_TERM);
      if (min == 0) {
        return;
      }
      terms_.Add(atom);
      return;
    }
  } else {
    // Only call immediately after adding an atom or character!
    UNREACHABLE();
    return;
  }
  terms_.Add(new (Z) RegExpQuantifier(min, max, quantifier_type, atom));
  LAST(ADD_TERM);
}

// ----------------------------------------------------------------------------
// Implementation of Parser

RegExpParser::RegExpParser(const String& in, String* error, bool multiline)
    : zone_(Thread::Current()->zone()),
      error_(error),
      captures_(NULL),
      in_(in),
      current_(kEndMarker),
      next_pos_(0),
      capture_count_(0),
      has_more_(true),
      multiline_(multiline),
      simple_(false),
      contains_anchor_(false),
      is_scanned_for_captures_(false),
      failed_(false) {
  Advance();
}


uint32_t RegExpParser::Next() {
  if (has_next()) {
    return in().CharAt(next_pos_);
  } else {
    return kEndMarker;
  }
}


void RegExpParser::Advance() {
  if (next_pos_ < in().Length()) {
    current_ = in().CharAt(next_pos_);
    next_pos_++;
  } else {
    current_ = kEndMarker;
    has_more_ = false;
  }
}


void RegExpParser::Reset(intptr_t pos) {
  next_pos_ = pos;
  has_more_ = (pos < in().Length());
  Advance();
}


void RegExpParser::Advance(intptr_t dist) {
  next_pos_ += dist - 1;
  Advance();
}


bool RegExpParser::simple() {
  return simple_;
}


void RegExpParser::ReportError(const char* message) {
  failed_ = true;
  *error_ = String::New(message);
  // Zip to the end to make sure the no more input is read.
  current_ = kEndMarker;
  next_pos_ = in().Length();

  const Error& error = Error::Handle(LanguageError::New(*error_));
  Report::LongJump(error);
  UNREACHABLE();
}


// Pattern ::
//   Disjunction
RegExpTree* RegExpParser::ParsePattern() {
  RegExpTree* result = ParseDisjunction();
  ASSERT(!has_more());
  // If the result of parsing is a literal string atom, and it has the
  // same length as the input, then the atom is identical to the input.
  if (result->IsAtom() && result->AsAtom()->length() == in().Length()) {
    simple_ = true;
  }
  return result;
}


// Disjunction ::
//   Alternative
//   Alternative | Disjunction
// Alternative ::
//   [empty]
//   Term Alternative
// Term ::
//   Assertion
//   Atom
//   Atom Quantifier
RegExpTree* RegExpParser::ParseDisjunction() {
  // Used to store current state while parsing subexpressions.
  RegExpParserState initial_state(NULL, INITIAL, 0, Z);
  RegExpParserState* stored_state = &initial_state;
  // Cache the builder in a local variable for quick access.
  RegExpBuilder* builder = initial_state.builder();
  while (true) {
    switch (current()) {
      case kEndMarker:
        if (stored_state->IsSubexpression()) {
          // Inside a parenthesized group when hitting end of input.
          ReportError("Unterminated group");
          UNREACHABLE();
        }
        ASSERT(INITIAL == stored_state->group_type());
        // Parsing completed successfully.
        return builder->ToRegExp();
      case ')': {
        if (!stored_state->IsSubexpression()) {
          ReportError("Unmatched ')'");
          UNREACHABLE();
        }
        ASSERT(INITIAL != stored_state->group_type());

        Advance();
        // End disjunction parsing and convert builder content to new single
        // regexp atom.
        RegExpTree* body = builder->ToRegExp();

        intptr_t end_capture_index = captures_started();

        intptr_t capture_index = stored_state->capture_index();
        SubexpressionType group_type = stored_state->group_type();

        // Restore previous state.
        stored_state = stored_state->previous_state();
        builder = stored_state->builder();

        // Build result of subexpression.
        if (group_type == CAPTURE) {
          RegExpCapture* capture = new (Z) RegExpCapture(body, capture_index);
          (*captures_)[capture_index - 1] = capture;
          body = capture;
        } else if (group_type != GROUPING) {
          ASSERT(group_type == POSITIVE_LOOKAHEAD ||
                 group_type == NEGATIVE_LOOKAHEAD);
          bool is_positive = (group_type == POSITIVE_LOOKAHEAD);
          body = new (Z)
              RegExpLookahead(body, is_positive,
                              end_capture_index - capture_index, capture_index);
        }
        builder->AddAtom(body);
        // For compatibility with JSC and ES3, we allow quantifiers after
        // lookaheads, and break in all cases.
        break;
      }
      case '|': {
        Advance();
        builder->NewAlternative();
        continue;
      }
      case '*':
      case '+':
      case '?':
        ReportError("Nothing to repeat");
        UNREACHABLE();
      case '^': {
        Advance();
        if (multiline_) {
          builder->AddAssertion(
              new (Z) RegExpAssertion(RegExpAssertion::START_OF_LINE));
        } else {
          builder->AddAssertion(
              new (Z) RegExpAssertion(RegExpAssertion::START_OF_INPUT));
          set_contains_anchor();
        }
        continue;
      }
      case '$': {
        Advance();
        RegExpAssertion::AssertionType assertion_type =
            multiline_ ? RegExpAssertion::END_OF_LINE
                       : RegExpAssertion::END_OF_INPUT;
        builder->AddAssertion(new RegExpAssertion(assertion_type));
        continue;
      }
      case '.': {
        Advance();
        // everything except \x0a, \x0d, \u2028 and \u2029
        ZoneGrowableArray<CharacterRange>* ranges =
            new ZoneGrowableArray<CharacterRange>(2);
        CharacterRange::AddClassEscape('.', ranges);
        RegExpTree* atom = new RegExpCharacterClass(ranges, false);
        builder->AddAtom(atom);
        break;
      }
      case '(': {
        SubexpressionType subexpr_type = CAPTURE;
        Advance();
        if (current() == '?') {
          switch (Next()) {
            case ':':
              subexpr_type = GROUPING;
              break;
            case '=':
              subexpr_type = POSITIVE_LOOKAHEAD;
              break;
            case '!':
              subexpr_type = NEGATIVE_LOOKAHEAD;
              break;
            default:
              ReportError("Invalid group");
              UNREACHABLE();
          }
          Advance(2);
        } else {
          if (captures_ == NULL) {
            captures_ = new ZoneGrowableArray<RegExpCapture*>(2);
          }
          if (captures_started() >= kMaxCaptures) {
            ReportError("Too many captures");
            UNREACHABLE();
          }
          captures_->Add(NULL);
        }
        // Store current state and begin new disjunction parsing.
        stored_state = new RegExpParserState(stored_state, subexpr_type,
                                             captures_started(), Z);
        builder = stored_state->builder();
        continue;
      }
      case '[': {
        RegExpTree* atom = ParseCharacterClass();
        builder->AddAtom(atom);
        break;
      }
      // Atom ::
      //   \ AtomEscape
      case '\\':
        switch (Next()) {
          case kEndMarker:
            ReportError("\\ at end of pattern");
            UNREACHABLE();
          case 'b':
            Advance(2);
            builder->AddAssertion(
                new RegExpAssertion(RegExpAssertion::BOUNDARY));
            continue;
          case 'B':
            Advance(2);
            builder->AddAssertion(
                new RegExpAssertion(RegExpAssertion::NON_BOUNDARY));
            continue;
          // AtomEscape ::
          //   CharacterClassEscape
          //
          // CharacterClassEscape :: one of
          //   d D s S w W
          case 'd':
          case 'D':
          case 's':
          case 'S':
          case 'w':
          case 'W': {
            uint32_t c = Next();
            Advance(2);
            ZoneGrowableArray<CharacterRange>* ranges =
                new ZoneGrowableArray<CharacterRange>(2);
            CharacterRange::AddClassEscape(c, ranges);
            RegExpTree* atom = new RegExpCharacterClass(ranges, false);
            builder->AddAtom(atom);
            break;
          }
          case '1':
          case '2':
          case '3':
          case '4':
          case '5':
          case '6':
          case '7':
          case '8':
          case '9': {
            intptr_t index = 0;
            if (ParseBackReferenceIndex(&index)) {
              RegExpCapture* capture = NULL;
              if (captures_ != NULL && index <= captures_->length()) {
                capture = captures_->At(index - 1);
              }
              if (capture == NULL) {
                builder->AddEmpty();
                break;
              }
              RegExpTree* atom = new RegExpBackReference(capture);
              builder->AddAtom(atom);
              break;
            }
            uint32_t first_digit = Next();
            if (first_digit == '8' || first_digit == '9') {
              // Treat as identity escape
              builder->AddCharacter(first_digit);
              Advance(2);
              break;
            }
          }
          // FALLTHROUGH
          case '0': {
            Advance();
            uint32_t octal = ParseOctalLiteral();
            builder->AddCharacter(octal);
            break;
          }
          // ControlEscape :: one of
          //   f n r t v
          case 'f':
            Advance(2);
            builder->AddCharacter('\f');
            break;
          case 'n':
            Advance(2);
            builder->AddCharacter('\n');
            break;
          case 'r':
            Advance(2);
            builder->AddCharacter('\r');
            break;
          case 't':
            Advance(2);
            builder->AddCharacter('\t');
            break;
          case 'v':
            Advance(2);
            builder->AddCharacter('\v');
            break;
          case 'c': {
            Advance();
            uint32_t controlLetter = Next();
            // Special case if it is an ASCII letter.
            // Convert lower case letters to uppercase.
            uint32_t letter = controlLetter & ~('a' ^ 'A');
            if (letter < 'A' || 'Z' < letter) {
              // controlLetter is not in range 'A'-'Z' or 'a'-'z'.
              // This is outside the specification. We match JSC in
              // reading the backslash as a literal character instead
              // of as starting an escape.
              builder->AddCharacter('\\');
            } else {
              Advance(2);
              builder->AddCharacter(controlLetter & 0x1f);
            }
            break;
          }
          case 'x': {
            Advance(2);
            uint32_t value;
            if (ParseHexEscape(2, &value)) {
              builder->AddCharacter(value);
            } else {
              builder->AddCharacter('x');
            }
            break;
          }
          case 'u': {
            Advance(2);
            uint32_t value;
            if (ParseHexEscape(4, &value)) {
              builder->AddCharacter(value);
            } else {
              builder->AddCharacter('u');
            }
            break;
          }
          default:
            // Identity escape.
            builder->AddCharacter(Next());
            Advance(2);
            break;
        }
        break;
      case '{': {
        intptr_t dummy;
        if (ParseIntervalQuantifier(&dummy, &dummy)) {
          ReportError("Nothing to repeat");
          UNREACHABLE();
        }
        // fallthrough
      }
      default:
        builder->AddCharacter(current());
        Advance();
        break;
    }  // end switch(current())

    intptr_t min;
    intptr_t max;
    switch (current()) {
      // QuantifierPrefix ::
      //   *
      //   +
      //   ?
      //   {
      case '*':
        min = 0;
        max = RegExpTree::kInfinity;
        Advance();
        break;
      case '+':
        min = 1;
        max = RegExpTree::kInfinity;
        Advance();
        break;
      case '?':
        min = 0;
        max = 1;
        Advance();
        break;
      case '{':
        if (ParseIntervalQuantifier(&min, &max)) {
          if (max < min) {
            ReportError("numbers out of order in {} quantifier.");
            UNREACHABLE();
          }
          break;
        } else {
          continue;
        }
      default:
        continue;
    }
    RegExpQuantifier::QuantifierType quantifier_type = RegExpQuantifier::GREEDY;
    if (current() == '?') {
      quantifier_type = RegExpQuantifier::NON_GREEDY;
      Advance();
    } else if (FLAG_regexp_possessive_quantifier && current() == '+') {
      // FLAG_regexp_possessive_quantifier is a debug-only flag.
      quantifier_type = RegExpQuantifier::POSSESSIVE;
      Advance();
    }
    builder->AddQuantifierToAtom(min, max, quantifier_type);
  }
}


#ifdef DEBUG
// Currently only used in an ASSERT.
static bool IsSpecialClassEscape(uint32_t c) {
  switch (c) {
    case 'd':
    case 'D':
    case 's':
    case 'S':
    case 'w':
    case 'W':
      return true;
    default:
      return false;
  }
}
#endif


// In order to know whether an escape is a backreference or not we have to scan
// the entire regexp and find the number of capturing parentheses.  However we
// don't want to scan the regexp twice unless it is necessary.  This mini-parser
// is called when needed.  It can see the difference between capturing and
// noncapturing parentheses and can skip character classes and backslash-escaped
// characters.
void RegExpParser::ScanForCaptures() {
  // Start with captures started previous to current position
  intptr_t capture_count = captures_started();
  // Add count of captures after this position.
  uintptr_t n;
  while ((n = current()) != kEndMarker) {
    Advance();
    switch (n) {
      case '\\':
        Advance();
        break;
      case '[': {
        uintptr_t c;
        while ((c = current()) != kEndMarker) {
          Advance();
          if (c == '\\') {
            Advance();
          } else {
            if (c == ']') break;
          }
        }
        break;
      }
      case '(':
        if (current() != '?') capture_count++;
        break;
    }
  }
  capture_count_ = capture_count;
  is_scanned_for_captures_ = true;
}


static inline bool IsDecimalDigit(int32_t c) {
  return '0' <= c && c <= '9';
}


bool RegExpParser::ParseBackReferenceIndex(intptr_t* index_out) {
  ASSERT('\\' == current());
  ASSERT('1' <= Next() && Next() <= '9');
  // Try to parse a decimal literal that is no greater than the total number
  // of left capturing parentheses in the input.
  intptr_t start = position();
  intptr_t value = Next() - '0';
  Advance(2);
  while (true) {
    uint32_t c = current();
    if (IsDecimalDigit(c)) {
      value = 10 * value + (c - '0');
      if (value > kMaxCaptures) {
        Reset(start);
        return false;
      }
      Advance();
    } else {
      break;
    }
  }
  if (value > captures_started()) {
    if (!is_scanned_for_captures_) {
      intptr_t saved_position = position();
      ScanForCaptures();
      Reset(saved_position);
    }
    if (value > capture_count_) {
      Reset(start);
      return false;
    }
  }
  *index_out = value;
  return true;
}


// QuantifierPrefix ::
//   { DecimalDigits }
//   { DecimalDigits , }
//   { DecimalDigits , DecimalDigits }
//
// Returns true if parsing succeeds, and set the min_out and max_out
// values. Values are truncated to RegExpTree::kInfinity if they overflow.
bool RegExpParser::ParseIntervalQuantifier(intptr_t* min_out,
                                           intptr_t* max_out) {
  ASSERT(current() == '{');
  intptr_t start = position();
  Advance();
  intptr_t min = 0;
  if (!IsDecimalDigit(current())) {
    Reset(start);
    return false;
  }
  while (IsDecimalDigit(current())) {
    intptr_t next = current() - '0';
    if (min > (RegExpTree::kInfinity - next) / 10) {
      // Overflow. Skip past remaining decimal digits and return -1.
      do {
        Advance();
      } while (IsDecimalDigit(current()));
      min = RegExpTree::kInfinity;
      break;
    }
    min = 10 * min + next;
    Advance();
  }
  intptr_t max = 0;
  if (current() == '}') {
    max = min;
    Advance();
  } else if (current() == ',') {
    Advance();
    if (current() == '}') {
      max = RegExpTree::kInfinity;
      Advance();
    } else {
      while (IsDecimalDigit(current())) {
        intptr_t next = current() - '0';
        if (max > (RegExpTree::kInfinity - next) / 10) {
          do {
            Advance();
          } while (IsDecimalDigit(current()));
          max = RegExpTree::kInfinity;
          break;
        }
        max = 10 * max + next;
        Advance();
      }
      if (current() != '}') {
        Reset(start);
        return false;
      }
      Advance();
    }
  } else {
    Reset(start);
    return false;
  }
  *min_out = min;
  *max_out = max;
  return true;
}


uint32_t RegExpParser::ParseOctalLiteral() {
  ASSERT(('0' <= current() && current() <= '7') || current() == kEndMarker);
  // For compatibility with some other browsers (not all), we parse
  // up to three octal digits with a value below 256.
  uint32_t value = current() - '0';
  Advance();
  if ('0' <= current() && current() <= '7') {
    value = value * 8 + current() - '0';
    Advance();
    if (value < 32 && '0' <= current() && current() <= '7') {
      value = value * 8 + current() - '0';
      Advance();
    }
  }
  return value;
}


// Returns the value (0 .. 15) of a hexadecimal character c.
// If c is not a legal hexadecimal character, returns a value < 0.
static inline intptr_t HexValue(uint32_t c) {
  c -= '0';
  if (static_cast<unsigned>(c) <= 9) return c;
  c = (c | 0x20) - ('a' - '0');  // detect 0x11..0x16 and 0x31..0x36.
  if (static_cast<unsigned>(c) <= 5) return c + 10;
  return -1;
}


bool RegExpParser::ParseHexEscape(intptr_t length, uint32_t* value) {
  intptr_t start = position();
  uint32_t val = 0;
  bool done = false;
  for (intptr_t i = 0; !done; i++) {
    uint32_t c = current();
    intptr_t d = HexValue(c);
    if (d < 0) {
      Reset(start);
      return false;
    }
    val = val * 16 + d;
    Advance();
    if (i == length - 1) {
      done = true;
    }
  }
  *value = val;
  return true;
}


uint32_t RegExpParser::ParseClassCharacterEscape() {
  ASSERT(current() == '\\');
  DEBUG_ASSERT(has_next() && !IsSpecialClassEscape(Next()));
  Advance();
  switch (current()) {
    case 'b':
      Advance();
      return '\b';
    // ControlEscape :: one of
    //   f n r t v
    case 'f':
      Advance();
      return '\f';
    case 'n':
      Advance();
      return '\n';
    case 'r':
      Advance();
      return '\r';
    case 't':
      Advance();
      return '\t';
    case 'v':
      Advance();
      return '\v';
    case 'c': {
      uint32_t controlLetter = Next();
      uint32_t letter = controlLetter & ~('A' ^ 'a');
      // For compatibility with JSC, inside a character class
      // we also accept digits and underscore as control characters.
      if ((controlLetter >= '0' && controlLetter <= '9') ||
          controlLetter == '_' || (letter >= 'A' && letter <= 'Z')) {
        Advance(2);
        // Control letters mapped to ASCII control characters in the range
        // 0x00-0x1f.
        return controlLetter & 0x1f;
      }
      // We match JSC in reading the backslash as a literal
      // character instead of as starting an escape.
      return '\\';
    }
    case '0':
    case '1':
    case '2':
    case '3':
    case '4':
    case '5':
    case '6':
    case '7':
      // For compatibility, we interpret a decimal escape that isn't
      // a back reference (and therefore either \0 or not valid according
      // to the specification) as a 1..3 digit octal character code.
      return ParseOctalLiteral();
    case 'x': {
      Advance();
      uint32_t value;
      if (ParseHexEscape(2, &value)) {
        return value;
      }
      // If \x is not followed by a two-digit hexadecimal, treat it
      // as an identity escape.
      return 'x';
    }
    case 'u': {
      Advance();
      uint32_t value;
      if (ParseHexEscape(4, &value)) {
        return value;
      }
      // If \u is not followed by a four-digit hexadecimal, treat it
      // as an identity escape.
      return 'u';
    }
    default: {
      // Extended identity escape. We accept any character that hasn't
      // been matched by a more specific case, not just the subset required
      // by the ECMAScript specification.
      uint32_t result = current();
      Advance();
      return result;
    }
  }
  return 0;
}


CharacterRange RegExpParser::ParseClassAtom(uint16_t* char_class) {
  ASSERT(0 == *char_class);
  uint32_t first = current();
  if (first == '\\') {
    switch (Next()) {
      case 'w':
      case 'W':
      case 'd':
      case 'D':
      case 's':
      case 'S': {
        *char_class = Next();
        Advance(2);
        return CharacterRange::Singleton(0);  // Return dummy value.
      }
      case kEndMarker:
        ReportError("\\ at end of pattern");
        UNREACHABLE();
      default:
        uint32_t c = ParseClassCharacterEscape();
        return CharacterRange::Singleton(c);
    }
  } else {
    Advance();
    return CharacterRange::Singleton(first);
  }
}


static const uint16_t kNoCharClass = 0;

// Adds range or pre-defined character class to character ranges.
// If char_class is not kInvalidClass, it's interpreted as a class
// escape (i.e., 's' means whitespace, from '\s').
static inline void AddRangeOrEscape(ZoneGrowableArray<CharacterRange>* ranges,
                                    uint16_t char_class,
                                    CharacterRange range) {
  if (char_class != kNoCharClass) {
    CharacterRange::AddClassEscape(char_class, ranges);
  } else {
    ranges->Add(range);
  }
}


RegExpTree* RegExpParser::ParseCharacterClass() {
  static const char* kUnterminated = "Unterminated character class";
  static const char* kRangeOutOfOrder = "Range out of order in character class";

  ASSERT(current() == '[');
  Advance();
  bool is_negated = false;
  if (current() == '^') {
    is_negated = true;
    Advance();
  }
  ZoneGrowableArray<CharacterRange>* ranges =
      new (Z) ZoneGrowableArray<CharacterRange>(2);
  while (has_more() && current() != ']') {
    uint16_t char_class = kNoCharClass;
    CharacterRange first = ParseClassAtom(&char_class);
    if (current() == '-') {
      Advance();
      if (current() == kEndMarker) {
        // If we reach the end we break out of the loop and let the
        // following code report an error.
        break;
      } else if (current() == ']') {
        AddRangeOrEscape(ranges, char_class, first);
        ranges->Add(CharacterRange::Singleton('-'));
        break;
      }
      uint16_t char_class_2 = kNoCharClass;
      CharacterRange next = ParseClassAtom(&char_class_2);
      if (char_class != kNoCharClass || char_class_2 != kNoCharClass) {
        // Either end is an escaped character class. Treat the '-' verbatim.
        AddRangeOrEscape(ranges, char_class, first);
        ranges->Add(CharacterRange::Singleton('-'));
        AddRangeOrEscape(ranges, char_class_2, next);
        continue;
      }
      if (first.from() > next.to()) {
        ReportError(kRangeOutOfOrder);
        UNREACHABLE();
      }
      ranges->Add(CharacterRange::Range(first.from(), next.to()));
    } else {
      AddRangeOrEscape(ranges, char_class, first);
    }
  }
  if (!has_more()) {
    ReportError(kUnterminated);
    UNREACHABLE();
  }
  Advance();
  if (ranges->length() == 0) {
    ranges->Add(CharacterRange::Everything());
    is_negated = !is_negated;
  }
  return new (Z) RegExpCharacterClass(ranges, is_negated);
}


// ----------------------------------------------------------------------------
// The Parser interface.

bool RegExpParser::ParseRegExp(const String& input,
                               bool multiline,
                               RegExpCompileData* result) {
  ASSERT(result != NULL);
  LongJumpScope jump;
  RegExpParser parser(input, &result->error, multiline);
  if (setjmp(*jump.Set()) == 0) {
    RegExpTree* tree = parser.ParsePattern();
    ASSERT(tree != NULL);
    ASSERT(result->error.IsNull());
    result->tree = tree;
    intptr_t capture_count = parser.captures_started();
    result->simple = tree->IsAtom() && parser.simple() && capture_count == 0;
    result->contains_anchor = parser.contains_anchor();
    result->capture_count = capture_count;
  } else {
    ASSERT(!result->error.IsNull());
    Thread::Current()->clear_sticky_error();

    // Throw a FormatException on parsing failures.
    const String& message =
        String::Handle(String::Concat(result->error, input));
    const Array& args = Array::Handle(Array::New(1));
    args.SetAt(0, message);

    Exceptions::ThrowByType(Exceptions::kFormat, args);
  }
  return !parser.failed();
}

}  // namespace dart
