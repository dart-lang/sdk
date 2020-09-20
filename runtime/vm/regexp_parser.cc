// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/regexp_parser.h"

#include "unicode/uchar.h"
#include "unicode/uniset.h"

#include "platform/unicode.h"

#include "vm/longjump.h"
#include "vm/object_store.h"

namespace dart {

#define Z zone()

// Enables possessive quantifier syntax for testing.
static const bool FLAG_regexp_possessive_quantifier = false;

RegExpBuilder::RegExpBuilder(RegExpFlags flags)
    : zone_(Thread::Current()->zone()),
      pending_empty_(false),
      flags_(flags),
      characters_(NULL),
      pending_surrogate_(kNoPendingSurrogate),
      terms_(),
      text_(),
      alternatives_()
#ifdef DEBUG
      ,
      last_added_(ADD_NONE)
#endif
{
}

void RegExpBuilder::AddLeadSurrogate(uint16_t lead_surrogate) {
  ASSERT(Utf16::IsLeadSurrogate(lead_surrogate));
  FlushPendingSurrogate();
  // Hold onto the lead surrogate, waiting for a trail surrogate to follow.
  pending_surrogate_ = lead_surrogate;
}

void RegExpBuilder::AddTrailSurrogate(uint16_t trail_surrogate) {
  ASSERT(Utf16::IsTrailSurrogate(trail_surrogate));
  if (pending_surrogate_ != kNoPendingSurrogate) {
    uint16_t lead_surrogate = pending_surrogate_;
    pending_surrogate_ = kNoPendingSurrogate;
    ASSERT(Utf16::IsLeadSurrogate(lead_surrogate));
    uint32_t combined = Utf16::Decode(lead_surrogate, trail_surrogate);
    if (NeedsDesugaringForIgnoreCase(combined)) {
      AddCharacterClassForDesugaring(combined);
    } else {
      auto surrogate_pair = new (Z) ZoneGrowableArray<uint16_t>(2);
      surrogate_pair->Add(lead_surrogate);
      surrogate_pair->Add(trail_surrogate);
      RegExpAtom* atom = new (Z) RegExpAtom(surrogate_pair, flags_);
      AddAtom(atom);
    }
  } else {
    pending_surrogate_ = trail_surrogate;
    FlushPendingSurrogate();
  }
}

void RegExpBuilder::FlushPendingSurrogate() {
  if (pending_surrogate_ != kNoPendingSurrogate) {
    ASSERT(is_unicode());
    uint32_t c = pending_surrogate_;
    pending_surrogate_ = kNoPendingSurrogate;
    AddCharacterClassForDesugaring(c);
  }
}

void RegExpBuilder::FlushCharacters() {
  FlushPendingSurrogate();
  pending_empty_ = false;
  if (characters_ != NULL) {
    RegExpTree* atom = new (Z) RegExpAtom(characters_, flags_);
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
  FlushPendingSurrogate();
  pending_empty_ = false;
  if (NeedsDesugaringForIgnoreCase(c)) {
    AddCharacterClassForDesugaring(c);
  } else {
    if (characters_ == NULL) {
      characters_ = new (Z) ZoneGrowableArray<uint16_t>(4);
    }
    characters_->Add(c);
    LAST(ADD_CHAR);
  }
}

void RegExpBuilder::AddUnicodeCharacter(uint32_t c) {
  if (c > static_cast<uint32_t>(Utf16::kMaxCodeUnit)) {
    ASSERT(is_unicode());
    uint16_t surrogates[2];
    Utf16::Encode(c, surrogates);
    AddLeadSurrogate(surrogates[0]);
    AddTrailSurrogate(surrogates[1]);
  } else if (is_unicode() && Utf16::IsLeadSurrogate(c)) {
    AddLeadSurrogate(c);
  } else if (is_unicode() && Utf16::IsTrailSurrogate(c)) {
    AddTrailSurrogate(c);
  } else {
    AddCharacter(static_cast<uint16_t>(c));
  }
}

void RegExpBuilder::AddEscapedUnicodeCharacter(uint32_t character) {
  // A lead or trail surrogate parsed via escape sequence will not
  // pair up with any preceding lead or following trail surrogate.
  FlushPendingSurrogate();
  AddUnicodeCharacter(character);
  FlushPendingSurrogate();
}

void RegExpBuilder::AddEmpty() {
  pending_empty_ = true;
}

void RegExpBuilder::AddCharacterClass(RegExpCharacterClass* cc) {
  if (NeedsDesugaringForUnicode(cc)) {
    // With /u, character class needs to be desugared, so it
    // must be a standalone term instead of being part of a RegExpText.
    AddTerm(cc);
  } else {
    AddAtom(cc);
  }
}

void RegExpBuilder::AddCharacterClassForDesugaring(uint32_t c) {
  auto ranges = CharacterRange::List(Z, CharacterRange::Singleton(c));
  AddTerm(new (Z) RegExpCharacterClass(ranges, flags_));
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

void RegExpBuilder::AddTerm(RegExpTree* term) {
  FlushText();
  terms_.Add(term);
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

bool RegExpBuilder::NeedsDesugaringForUnicode(RegExpCharacterClass* cc) {
  if (!is_unicode()) return false;
  // TODO(yangguo): we could be smarter than this. Case-insensitivity does not
  // necessarily mean that we need to desugar. It's probably nicer to have a
  // separate pass to figure out unicode desugarings.
  if (ignore_case()) return true;
  ZoneGrowableArray<CharacterRange>* ranges = cc->ranges();
  CharacterRange::Canonicalize(ranges);
  for (int i = ranges->length() - 1; i >= 0; i--) {
    uint32_t from = ranges->At(i).from();
    uint32_t to = ranges->At(i).to();
    // Check for non-BMP characters.
    if (to >= Utf16::kMaxCodeUnit) return true;
    // Check for lone surrogates.
    if (from <= Utf16::kTrailSurrogateEnd && to >= Utf16::kLeadSurrogateStart) {
      return true;
    }
  }
  return false;
}

bool RegExpBuilder::NeedsDesugaringForIgnoreCase(uint32_t c) {
  if (is_unicode() && ignore_case()) {
    icu::UnicodeSet set(c, c);
    set.closeOver(USET_CASE_INSENSITIVE);
    set.removeAllStrings();
    return set.size() > 1;
  }
  return false;
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

bool RegExpBuilder::AddQuantifierToAtom(
    intptr_t min,
    intptr_t max,
    RegExpQuantifier::QuantifierType quantifier_type) {
  if (pending_empty_) {
    pending_empty_ = false;
    return true;
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
      text_.Add(new (Z) RegExpAtom(prefix, flags_));
      ZoneGrowableArray<uint16_t>* tail = new (Z) ZoneGrowableArray<uint16_t>();
      tail->Add(char_vector->At(num_chars - 1));
      char_vector = tail;
    }
    characters_ = NULL;
    atom = new (Z) RegExpAtom(char_vector, flags_);
    FlushText();
  } else if (text_.length() > 0) {
    DEBUG_ASSERT(last_added_ == ADD_ATOM);
    atom = text_.RemoveLast();
    FlushText();
  } else if (terms_.length() > 0) {
    DEBUG_ASSERT(last_added_ == ADD_ATOM);
    atom = terms_.RemoveLast();
    if (auto lookaround = atom->AsLookaround()) {
      // With /u, lookarounds are not quantifiable.
      if (is_unicode()) return false;
      // Lookbehinds are not quantifiable.
      if (lookaround->type() == RegExpLookaround::LOOKBEHIND) {
        return false;
      }
    }
    if (atom->max_match() == 0) {
      // Guaranteed to only match an empty string.
      LAST(ADD_TERM);
      if (min == 0) {
        return true;
      }
      terms_.Add(atom);
      return true;
    }
  } else {
    // Only call immediately after adding an atom or character!
    UNREACHABLE();
  }
  terms_.Add(new (Z) RegExpQuantifier(min, max, quantifier_type, atom));
  LAST(ADD_TERM);
  return true;
}

// ----------------------------------------------------------------------------
// Implementation of Parser

RegExpParser::RegExpParser(const String& in, String* error, RegExpFlags flags)
    : zone_(Thread::Current()->zone()),
      captures_(nullptr),
      named_captures_(nullptr),
      named_back_references_(nullptr),
      in_(in),
      current_(kEndMarker),
      next_pos_(0),
      captures_started_(0),
      capture_count_(0),
      has_more_(true),
      top_level_flags_(flags),
      simple_(false),
      contains_anchor_(false),
      is_scanned_for_captures_(false),
      has_named_captures_(false) {
  Advance();
}

inline uint32_t RegExpParser::ReadNext(bool update_position) {
  intptr_t position = next_pos_;
  const uint16_t c0 = in().CharAt(position);
  uint32_t c = c0;
  position++;
  if (is_unicode() && position < in().Length() && Utf16::IsLeadSurrogate(c0)) {
    const uint16_t c1 = in().CharAt(position);
    if (Utf16::IsTrailSurrogate(c1)) {
      c = Utf16::Decode(c0, c1);
      position++;
    }
  }
  if (update_position) next_pos_ = position;
  return c;
}

uint32_t RegExpParser::Next() {
  if (has_next()) {
    return ReadNext(false);
  } else {
    return kEndMarker;
  }
}

void RegExpParser::Advance() {
  if (has_next()) {
    current_ = ReadNext(true);
  } else {
    current_ = kEndMarker;
    // Advance so that position() points to 1 after the last character. This is
    // important so that Reset() to this position works correctly.
    next_pos_ = in().Length() + 1;
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

bool RegExpParser::IsSyntaxCharacterOrSlash(uint32_t c) {
  switch (c) {
    case '^':
    case '$':
    case '\\':
    case '.':
    case '*':
    case '+':
    case '?':
    case '(':
    case ')':
    case '[':
    case ']':
    case '{':
    case '}':
    case '|':
    case '/':
      return true;
    default:
      break;
  }
  return false;
}

void RegExpParser::ReportError(const char* message) {
  // Zip to the end to make sure the no more input is read.
  current_ = kEndMarker;
  next_pos_ = in().Length();

  // Throw a FormatException on parsing failures.
  const String& msg = String::Handle(
      String::Concat(String::Handle(String::New(message)), in()));
  const Array& args = Array::Handle(Array::New(1));
  args.SetAt(0, msg);
  Exceptions::ThrowByType(Exceptions::kFormat, args);
  UNREACHABLE();
}

// Pattern ::
//   Disjunction
RegExpTree* RegExpParser::ParsePattern() {
  RegExpTree* result = ParseDisjunction();
  PatchNamedBackReferences();
  ASSERT(!has_more());
  // If the result of parsing is a literal string atom, and it has the
  // same length as the input, then the atom is identical to the input.
  if (result->IsAtom() && result->AsAtom()->length() == in().Length()) {
    simple_ = true;
  }
  return result;
}

// Used for error messages where we would have fallen back on treating an
// escape as the identity escape, but we are in Unicode mode.
static const char* kUnicodeIdentity =
    "Invalid identity escape in Unicode pattern";

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
  RegExpParserState initial_state(nullptr, INITIAL, RegExpLookaround::LOOKAHEAD,
                                  0, nullptr, top_level_flags_, Z);
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

        // Build result of subexpression.
        if (group_type == CAPTURE) {
          if (stored_state->IsNamedCapture()) {
            CreateNamedCaptureAtIndex(stored_state->capture_name(),
                                      capture_index);
          }
          RegExpCapture* capture = GetCapture(capture_index);
          capture->set_body(body);
          body = capture;
        } else if (group_type != GROUPING) {
          ASSERT(group_type == POSITIVE_LOOKAROUND ||
                 group_type == NEGATIVE_LOOKAROUND);
          bool is_positive = (group_type == POSITIVE_LOOKAROUND);
          body = new (Z) RegExpLookaround(
              body, is_positive, end_capture_index - capture_index,
              capture_index, stored_state->lookaround_type());
        }

        // Restore previous state.
        stored_state = stored_state->previous_state();
        builder = stored_state->builder();

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
        if (builder->is_multi_line()) {
          builder->AddAssertion(new (Z) RegExpAssertion(
              RegExpAssertion::START_OF_LINE, builder->flags()));
        } else {
          builder->AddAssertion(new (Z) RegExpAssertion(
              RegExpAssertion::START_OF_INPUT, builder->flags()));
          set_contains_anchor();
        }
        continue;
      }
      case '$': {
        Advance();
        RegExpAssertion::AssertionType assertion_type =
            builder->is_multi_line() ? RegExpAssertion::END_OF_LINE
                                     : RegExpAssertion::END_OF_INPUT;
        builder->AddAssertion(
            new (Z) RegExpAssertion(assertion_type, builder->flags()));
        continue;
      }
      case '.': {
        Advance();
        auto ranges = new (Z) ZoneGrowableArray<CharacterRange>(2);
        if (builder->is_dot_all()) {
          // Everything.
          CharacterRange::AddClassEscape(
              '*', ranges,
              /*add_unicode_case_equivalents=*/false);
        } else {
          // everything except \x0a, \x0d, \u2028 and \u2029
          CharacterRange::AddClassEscape(
              '.', ranges,
              /*add_unicode_case_equivalents=*/false);
        }
        RegExpCharacterClass* cc =
            new (Z) RegExpCharacterClass(ranges, builder->flags());
        builder->AddCharacterClass(cc);
        break;
      }
      case '(': {
        stored_state = ParseOpenParenthesis(stored_state);
        builder = stored_state->builder();
        continue;
      }
      case '[': {
        RegExpTree* atom = ParseCharacterClass(builder);
        builder->AddCharacterClass(atom->AsCharacterClass());
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
            builder->AddAssertion(new (Z) RegExpAssertion(
                RegExpAssertion::BOUNDARY, builder->flags()));
            continue;
          case 'B':
            Advance(2);
            builder->AddAssertion(new (Z) RegExpAssertion(
                RegExpAssertion::NON_BOUNDARY, builder->flags()));
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
            auto ranges = new (Z) ZoneGrowableArray<CharacterRange>(2);
            CharacterRange::AddClassEscape(
                c, ranges, is_unicode() && builder->ignore_case());
            RegExpCharacterClass* cc =
                new (Z) RegExpCharacterClass(ranges, builder->flags());
            builder->AddCharacterClass(cc);
            break;
          }
          case 'p':
          case 'P': {
            uint32_t p = Next();
            Advance(2);

            if (is_unicode()) {
              auto name_1 = new (Z) ZoneGrowableArray<char>();
              auto name_2 = new (Z) ZoneGrowableArray<char>();
              auto ranges = new (Z) ZoneGrowableArray<CharacterRange>(2);
              if (ParsePropertyClassName(name_1, name_2)) {
                if (AddPropertyClassRange(ranges, p == 'P', name_1, name_2)) {
                  RegExpCharacterClass* cc =
                      new (Z) RegExpCharacterClass(ranges, builder->flags());
                  builder->AddCharacterClass(cc);
                  break;
                }
              }
              ReportError("Invalid property name");
              UNREACHABLE();
            } else {
              builder->AddCharacter(p);
            }
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
              if (stored_state->IsInsideCaptureGroup(index)) {
                // The back reference is inside the capture group it refers to.
                // Nothing can possibly have been captured yet, so we use empty
                // instead. This ensures that, when checking a back reference,
                // the capture registers of the referenced capture are either
                // both set or both cleared.
                builder->AddEmpty();
              } else {
                RegExpCapture* capture = GetCapture(index);
                RegExpTree* atom =
                    new (Z) RegExpBackReference(capture, builder->flags());
                builder->AddAtom(atom);
              }
              break;
            }
            // With /u, no identity escapes except for syntax characters are
            // allowed. Otherwise, all identity escapes are allowed.
            if (is_unicode()) {
              ReportError(kUnicodeIdentity);
              UNREACHABLE();
            }
            uint32_t first_digit = Next();
            if (first_digit == '8' || first_digit == '9') {
              builder->AddCharacter(first_digit);
              Advance(2);
              break;
            }
          }
            FALL_THROUGH;
          case '0': {
            Advance();
            if (is_unicode() && Next() >= '0' && Next() <= '9') {
              // With /u, decimal escape with leading 0 are not parsed as octal.
              ReportError("Invalid decimal escape");
              UNREACHABLE();
            }
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
              if (is_unicode()) {
                // With /u, invalid escapes are not treated as identity escapes.
                ReportError(kUnicodeIdentity);
                UNREACHABLE();
              }
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
            } else if (!is_unicode()) {
              builder->AddCharacter('x');
            } else {
              // With /u, invalid escapes are not treated as identity escapes.
              ReportError(kUnicodeIdentity);
              UNREACHABLE();
            }
            break;
          }
          case 'u': {
            Advance(2);
            uint32_t value;
            if (ParseUnicodeEscape(&value)) {
              builder->AddEscapedUnicodeCharacter(value);
            } else if (!is_unicode()) {
              builder->AddCharacter('u');
            } else {
              // With /u, invalid escapes are not treated as identity escapes.
              ReportError(kUnicodeIdentity);
              UNREACHABLE();
            }
            break;
          }
          case 'k':
            // Either an identity escape or a named back-reference.  The two
            // interpretations are mutually exclusive: '\k' is interpreted as
            // an identity escape for non-Unicode patterns without named
            // capture groups, and as the beginning of a named back-reference
            // in all other cases.
            if (is_unicode() || HasNamedCaptures()) {
              Advance(2);
              ParseNamedBackReference(builder, stored_state);
              break;
            }
            FALL_THROUGH;
          default:
            Advance();
            // With the unicode flag, no identity escapes except for syntax
            // characters are allowed. Otherwise, all identity escapes are
            // allowed.
            if (!is_unicode() || IsSyntaxCharacterOrSlash(current())) {
              builder->AddCharacter(current());
              Advance();
            } else {
              ReportError(kUnicodeIdentity);
              UNREACHABLE();
            }
            break;
        }
        break;
      case '{': {
        intptr_t dummy;
        if (ParseIntervalQuantifier(&dummy, &dummy)) {
          ReportError("Nothing to repeat");
          UNREACHABLE();
        }
      }
        FALL_THROUGH;
      case '}':
      case ']':
        if (is_unicode()) {
          ReportError("Lone quantifier brackets");
          UNREACHABLE();
        }
        FALL_THROUGH;
      default:
        builder->AddUnicodeCharacter(current());
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
    if (!builder->AddQuantifierToAtom(min, max, quantifier_type)) {
      ReportError("invalid quantifier.");
      UNREACHABLE();
    }
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

RegExpParser::RegExpParserState* RegExpParser::ParseOpenParenthesis(
    RegExpParserState* state) {
  RegExpLookaround::Type lookaround_type = state->lookaround_type();
  bool is_named_capture = false;
  const RegExpCaptureName* capture_name = nullptr;
  SubexpressionType subexpr_type = CAPTURE;
  Advance();
  if (current() == '?') {
    switch (Next()) {
      case ':':
        Advance(2);
        subexpr_type = GROUPING;
        break;
      case '=':
        Advance(2);
        lookaround_type = RegExpLookaround::LOOKAHEAD;
        subexpr_type = POSITIVE_LOOKAROUND;
        break;
      case '!':
        Advance(2);
        lookaround_type = RegExpLookaround::LOOKAHEAD;
        subexpr_type = NEGATIVE_LOOKAROUND;
        break;
      case '<':
        Advance();
        if (Next() == '=') {
          Advance(2);
          lookaround_type = RegExpLookaround::LOOKBEHIND;
          subexpr_type = POSITIVE_LOOKAROUND;
          break;
        } else if (Next() == '!') {
          Advance(2);
          lookaround_type = RegExpLookaround::LOOKBEHIND;
          subexpr_type = NEGATIVE_LOOKAROUND;
          break;
        }
        is_named_capture = true;
        has_named_captures_ = true;
        Advance();
        break;
      default:
        ReportError("Invalid group");
        UNREACHABLE();
    }
  }

  if (subexpr_type == CAPTURE) {
    if (captures_started_ >= kMaxCaptures) {
      ReportError("Too many captures");
      UNREACHABLE();
    }
    captures_started_++;

    if (is_named_capture) {
      capture_name = ParseCaptureGroupName();
    }
  }
  // Store current state and begin new disjunction parsing.
  return new (Z)
      RegExpParserState(state, subexpr_type, lookaround_type, captures_started_,
                        capture_name, state->builder()->flags(), Z);
}

// In order to know whether an escape is a backreference or not we have to scan
// the entire regexp and find the number of capturing parentheses.  However we
// don't want to scan the regexp twice unless it is necessary.  This mini-parser
// is called when needed.  It can see the difference between capturing and
// noncapturing parentheses and can skip character classes and backslash-escaped
// characters.
void RegExpParser::ScanForCaptures() {
  ASSERT(!is_scanned_for_captures_);
  const intptr_t saved_position = position();
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
        // At this point we could be in
        // * a non-capturing group '(:',
        // * a lookbehind assertion '(?<=' '(?<!'
        // * or a named capture '(?<'.
        //
        // Of these, only named captures are capturing groups.
        if (current() == '?') {
          Advance();
          if (current() != '<') break;

          Advance();
          if (current() == '=' || current() == '!') break;

          // Found a possible named capture. It could turn out to be a syntax
          // error (e.g. an unterminated or invalid name), but that distinction
          // does not matter for our purposes.
          has_named_captures_ = true;
        }
        capture_count++;
        break;
    }
  }
  capture_count_ = capture_count;
  is_scanned_for_captures_ = true;
  Reset(saved_position);
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
    if (Utils::IsDecimalDigit(c)) {
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
    if (!is_scanned_for_captures_) ScanForCaptures();
    if (value > capture_count_) {
      Reset(start);
      return false;
    }
  }
  *index_out = value;
  return true;
}

namespace {

static inline constexpr bool IsAsciiIdentifierPart(uint32_t ch) {
  return Utils::IsAlphaNumeric(ch) || ch == '_' || ch == '$';
}

// ES#sec-names-and-keywords Names and Keywords
// UnicodeIDStart, '$', '_' and '\'
static bool IsIdentifierStartSlow(uint32_t c) {
  // cannot use u_isIDStart because it does not work for
  // Other_ID_Start characters.
  return u_hasBinaryProperty(c, UCHAR_ID_START) ||
         (c < 0x60 && (c == '$' || c == '\\' || c == '_'));
}

// ES#sec-names-and-keywords Names and Keywords
// UnicodeIDContinue, '$', '_', '\', ZWJ, and ZWNJ
static bool IsIdentifierPartSlow(uint32_t c) {
  const uint32_t kZeroWidthNonJoiner = 0x200C;
  const uint32_t kZeroWidthJoiner = 0x200D;
  // Can't use u_isIDPart because it does not work for
  // Other_ID_Continue characters.
  return u_hasBinaryProperty(c, UCHAR_ID_CONTINUE) ||
         (c < 0x60 && (c == '$' || c == '\\' || c == '_')) ||
         c == kZeroWidthNonJoiner || c == kZeroWidthJoiner;
}

static inline bool IsIdentifierStart(uint32_t c) {
  if (c > 127) return IsIdentifierStartSlow(c);
  return IsAsciiIdentifierPart(c) && !Utils::IsDecimalDigit(c);
}

static inline bool IsIdentifierPart(uint32_t c) {
  if (c > 127) return IsIdentifierPartSlow(c);
  return IsAsciiIdentifierPart(c);
}

static bool IsSameName(const RegExpCaptureName* name1,
                       const RegExpCaptureName* name2) {
  if (name1->length() != name2->length()) return false;
  for (intptr_t i = 0; i < name1->length(); i++) {
    if (name1->At(i) != name2->At(i)) return false;
  }
  return true;
}

}  // end namespace

static void PushCodeUnit(RegExpCaptureName* v, uint32_t code_unit) {
  if (code_unit <= Utf16::kMaxCodeUnit) {
    v->Add(code_unit);
  } else {
    uint16_t units[2];
    Utf16::Encode(code_unit, units);
    v->Add(units[0]);
    v->Add(units[1]);
  }
}

const RegExpCaptureName* RegExpParser::ParseCaptureGroupName() {
  auto name = new (Z) RegExpCaptureName();

  bool at_start = true;
  while (true) {
    uint32_t c = current();
    Advance();

    // Convert unicode escapes.
    if (c == '\\' && current() == 'u') {
      Advance();
      if (!ParseUnicodeEscape(&c)) {
        ReportError("Invalid Unicode escape sequence");
        UNREACHABLE();
      }
    }

    // The backslash char is misclassified as both ID_Start and ID_Continue.
    if (c == '\\') {
      ReportError("Invalid capture group name");
      UNREACHABLE();
    }

    if (at_start) {
      if (!IsIdentifierStart(c)) {
        ReportError("Invalid capture group name");
        UNREACHABLE();
      }
      PushCodeUnit(name, c);
      at_start = false;
    } else {
      if (c == '>') {
        break;
      } else if (IsIdentifierPart(c)) {
        PushCodeUnit(name, c);
      } else {
        ReportError("Invalid capture group name");
        UNREACHABLE();
      }
    }
  }

  return name;
}

intptr_t RegExpParser::GetNamedCaptureIndex(const RegExpCaptureName* name) {
  for (const auto& capture : *named_captures_) {
    if (IsSameName(name, capture->name())) return capture->index();
  }
  return -1;
}

void RegExpParser::CreateNamedCaptureAtIndex(const RegExpCaptureName* name,
                                             intptr_t index) {
  ASSERT(0 < index && index <= captures_started_);
  ASSERT(name != nullptr);

  if (named_captures_ == nullptr) {
    named_captures_ = new (Z) ZoneGrowableArray<RegExpCapture*>(1);
  } else {
    // Check for duplicates and bail if we find any. Currently O(n^2).
    if (GetNamedCaptureIndex(name) >= 0) {
      ReportError("Duplicate capture group name");
      UNREACHABLE();
    }
  }

  RegExpCapture* capture = GetCapture(index);
  ASSERT(capture->name() == nullptr);

  capture->set_name(name);
  named_captures_->Add(capture);
}

bool RegExpParser::ParseNamedBackReference(RegExpBuilder* builder,
                                           RegExpParserState* state) {
  // The parser is assumed to be on the '<' in \k<name>.
  if (current() != '<') {
    ReportError("Invalid named reference");
    UNREACHABLE();
  }

  Advance();
  const RegExpCaptureName* name = ParseCaptureGroupName();
  if (name == nullptr) {
    return false;
  }

  if (state->IsInsideCaptureGroup(name)) {
    builder->AddEmpty();
  } else {
    RegExpBackReference* atom = new (Z) RegExpBackReference(builder->flags());
    atom->set_name(name);

    builder->AddAtom(atom);

    if (named_back_references_ == nullptr) {
      named_back_references_ =
          new (Z) ZoneGrowableArray<RegExpBackReference*>(1);
    }
    named_back_references_->Add(atom);
  }

  return true;
}

void RegExpParser::PatchNamedBackReferences() {
  if (named_back_references_ == nullptr) return;

  if (named_captures_ == nullptr) {
    ReportError("Invalid named capture referenced");
    return;
  }

  // Look up and patch the actual capture for each named back reference.
  // Currently O(n^2), optimize if necessary.
  for (intptr_t i = 0; i < named_back_references_->length(); i++) {
    RegExpBackReference* ref = named_back_references_->At(i);
    intptr_t index = GetNamedCaptureIndex(ref->name());

    if (index < 0) {
      ReportError("Invalid named capture referenced");
      UNREACHABLE();
    }
    ref->set_capture(GetCapture(index));
  }
}

RegExpCapture* RegExpParser::GetCapture(intptr_t index) {
  // The index for the capture groups are one-based. Its index in the list is
  // zero-based.
  const intptr_t know_captures =
      is_scanned_for_captures_ ? capture_count_ : captures_started_;
  ASSERT(index <= know_captures);
  if (captures_ == nullptr) {
    captures_ = new (Z) ZoneGrowableArray<RegExpCapture*>(know_captures);
  }
  while (captures_->length() < know_captures) {
    captures_->Add(new (Z) RegExpCapture(captures_->length() + 1));
  }
  return captures_->At(index - 1);
}

ArrayPtr RegExpParser::CreateCaptureNameMap() {
  if (named_captures_ == nullptr || named_captures_->is_empty()) {
    return Array::null();
  }

  const intptr_t len = named_captures_->length() * 2;

  const Array& array = Array::Handle(Array::New(len));

  auto& name = String::Handle();
  auto& smi = Smi::Handle();
  for (intptr_t i = 0; i < named_captures_->length(); i++) {
    RegExpCapture* capture = named_captures_->At(i);
    name =
        String::FromUTF16(capture->name()->data(), capture->name()->length());
    smi = Smi::New(capture->index());
    array.SetAt(i * 2, name);
    array.SetAt(i * 2 + 1, smi);
  }

  return array.raw();
}

bool RegExpParser::HasNamedCaptures() {
  if (has_named_captures_ || is_scanned_for_captures_) {
    return has_named_captures_;
  }

  ScanForCaptures();
  ASSERT(is_scanned_for_captures_);
  return has_named_captures_;
}

bool RegExpParser::RegExpParserState::IsInsideCaptureGroup(intptr_t index) {
  for (RegExpParserState* s = this; s != nullptr; s = s->previous_state()) {
    if (s->group_type() != CAPTURE) continue;
    // Return true if we found the matching capture index.
    if (index == s->capture_index()) return true;
    // Abort if index is larger than what has been parsed up till this state.
    if (index > s->capture_index()) return false;
  }
  return false;
}

bool RegExpParser::RegExpParserState::IsInsideCaptureGroup(
    const RegExpCaptureName* name) {
  ASSERT(name != nullptr);
  for (RegExpParserState* s = this; s != nullptr; s = s->previous_state()) {
    if (s->capture_name() == nullptr) continue;
    if (IsSameName(s->capture_name(), name)) return true;
  }
  return false;
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
  if (!Utils::IsDecimalDigit(current())) {
    Reset(start);
    return false;
  }
  while (Utils::IsDecimalDigit(current())) {
    intptr_t next = current() - '0';
    if (min > (RegExpTree::kInfinity - next) / 10) {
      // Overflow. Skip past remaining decimal digits and return -1.
      do {
        Advance();
      } while (Utils::IsDecimalDigit(current()));
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
      while (Utils::IsDecimalDigit(current())) {
        intptr_t next = current() - '0';
        if (max > (RegExpTree::kInfinity - next) / 10) {
          do {
            Advance();
          } while (Utils::IsDecimalDigit(current()));
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

// This parses RegExpUnicodeEscapeSequence as described in ECMA262.
bool RegExpParser::ParseUnicodeEscape(uint32_t* value) {
  // Accept both \uxxxx and \u{xxxxxx} (if harmony unicode escapes are
  // allowed). In the latter case, the number of hex digits between { } is
  // arbitrary. \ and u have already been read.
  if (current() == '{' && is_unicode()) {
    int start = position();
    Advance();
    if (ParseUnlimitedLengthHexNumber(Utf::kMaxCodePoint, value)) {
      if (current() == '}') {
        Advance();
        return true;
      }
    }
    Reset(start);
    return false;
  }
  // \u but no {, or \u{...} escapes not allowed.
  bool result = ParseHexEscape(4, value);
  if (result && is_unicode() && Utf16::IsLeadSurrogate(*value) &&
      current() == '\\') {
    // Attempt to read trail surrogate.
    int start = position();
    if (Next() == 'u') {
      Advance(2);
      uint32_t trail;
      if (ParseHexEscape(4, &trail) && Utf16::IsTrailSurrogate(trail)) {
        *value = Utf16::Decode(static_cast<uint16_t>(*value),
                               static_cast<uint16_t>(trail));
        return true;
      }
    }
    Reset(start);
  }
  return result;
}

namespace {

bool IsExactPropertyAlias(const char* property_name, UProperty property) {
  const char* short_name = u_getPropertyName(property, U_SHORT_PROPERTY_NAME);
  if (short_name != nullptr && strcmp(property_name, short_name) == 0) {
    return true;
  }
  for (int i = 0;; i++) {
    const char* long_name = u_getPropertyName(
        property, static_cast<UPropertyNameChoice>(U_LONG_PROPERTY_NAME + i));
    if (long_name == nullptr) break;
    if (strcmp(property_name, long_name) == 0) return true;
  }
  return false;
}

bool IsExactPropertyValueAlias(const char* property_value_name,
                               UProperty property,
                               int32_t property_value) {
  const char* short_name =
      u_getPropertyValueName(property, property_value, U_SHORT_PROPERTY_NAME);
  if (short_name != nullptr && strcmp(property_value_name, short_name) == 0) {
    return true;
  }
  for (int i = 0;; i++) {
    const char* long_name = u_getPropertyValueName(
        property, property_value,
        static_cast<UPropertyNameChoice>(U_LONG_PROPERTY_NAME + i));
    if (long_name == nullptr) break;
    if (strcmp(property_value_name, long_name) == 0) return true;
  }
  return false;
}

bool LookupPropertyValueName(UProperty property,
                             const char* property_value_name,
                             bool negate,
                             ZoneGrowableArray<CharacterRange>* result) {
  UProperty property_for_lookup = property;
  if (property_for_lookup == UCHAR_SCRIPT_EXTENSIONS) {
    // For the property Script_Extensions, we have to do the property value
    // name lookup as if the property is Script.
    property_for_lookup = UCHAR_SCRIPT;
  }
  int32_t property_value =
      u_getPropertyValueEnum(property_for_lookup, property_value_name);
  if (property_value == UCHAR_INVALID_CODE) return false;

  // We require the property name to match exactly to one of the property value
  // aliases. However, u_getPropertyValueEnum uses loose matching.
  if (!IsExactPropertyValueAlias(property_value_name, property_for_lookup,
                                 property_value)) {
    return false;
  }

  UErrorCode ec = U_ZERO_ERROR;
  icu::UnicodeSet set;
  set.applyIntPropertyValue(property, property_value, ec);
  bool success = ec == U_ZERO_ERROR && (set.isEmpty() == 0);

  if (success) {
    set.removeAllStrings();
    if (negate) set.complement();
    for (int i = 0; i < set.getRangeCount(); i++) {
      result->Add(
          CharacterRange::Range(set.getRangeStart(i), set.getRangeEnd(i)));
    }
  }
  return success;
}

template <size_t N>
inline bool NameEquals(const char* name, const char (&literal)[N]) {
  return strncmp(name, literal, N + 1) == 0;
}

bool LookupSpecialPropertyValueName(const char* name,
                                    ZoneGrowableArray<CharacterRange>* result,
                                    bool negate) {
  if (NameEquals(name, "Any")) {
    if (negate) {
      // Leave the list of character ranges empty, since the negation of 'Any'
      // is the empty set.
    } else {
      result->Add(CharacterRange::Everything());
    }
  } else if (NameEquals(name, "ASCII")) {
    result->Add(negate ? CharacterRange::Range(0x80, Utf::kMaxCodePoint)
                       : CharacterRange::Range(0x0, 0x7F));
  } else if (NameEquals(name, "Assigned")) {
    return LookupPropertyValueName(UCHAR_GENERAL_CATEGORY, "Unassigned",
                                   !negate, result);
  } else {
    return false;
  }
  return true;
}

// Explicitly list supported binary properties. The spec forbids supporting
// properties outside of this set to ensure interoperability.
bool IsSupportedBinaryProperty(UProperty property) {
  switch (property) {
    case UCHAR_ALPHABETIC:
    // 'Any' is not supported by ICU. See LookupSpecialPropertyValueName.
    // 'ASCII' is not supported by ICU. See LookupSpecialPropertyValueName.
    case UCHAR_ASCII_HEX_DIGIT:
    // 'Assigned' is not supported by ICU. See LookupSpecialPropertyValueName.
    case UCHAR_BIDI_CONTROL:
    case UCHAR_BIDI_MIRRORED:
    case UCHAR_CASE_IGNORABLE:
    case UCHAR_CASED:
    case UCHAR_CHANGES_WHEN_CASEFOLDED:
    case UCHAR_CHANGES_WHEN_CASEMAPPED:
    case UCHAR_CHANGES_WHEN_LOWERCASED:
    case UCHAR_CHANGES_WHEN_NFKC_CASEFOLDED:
    case UCHAR_CHANGES_WHEN_TITLECASED:
    case UCHAR_CHANGES_WHEN_UPPERCASED:
    case UCHAR_DASH:
    case UCHAR_DEFAULT_IGNORABLE_CODE_POINT:
    case UCHAR_DEPRECATED:
    case UCHAR_DIACRITIC:
    case UCHAR_EMOJI:
    case UCHAR_EMOJI_COMPONENT:
    case UCHAR_EMOJI_MODIFIER_BASE:
    case UCHAR_EMOJI_MODIFIER:
    case UCHAR_EMOJI_PRESENTATION:
    case UCHAR_EXTENDED_PICTOGRAPHIC:
    case UCHAR_EXTENDER:
    case UCHAR_GRAPHEME_BASE:
    case UCHAR_GRAPHEME_EXTEND:
    case UCHAR_HEX_DIGIT:
    case UCHAR_ID_CONTINUE:
    case UCHAR_ID_START:
    case UCHAR_IDEOGRAPHIC:
    case UCHAR_IDS_BINARY_OPERATOR:
    case UCHAR_IDS_TRINARY_OPERATOR:
    case UCHAR_JOIN_CONTROL:
    case UCHAR_LOGICAL_ORDER_EXCEPTION:
    case UCHAR_LOWERCASE:
    case UCHAR_MATH:
    case UCHAR_NONCHARACTER_CODE_POINT:
    case UCHAR_PATTERN_SYNTAX:
    case UCHAR_PATTERN_WHITE_SPACE:
    case UCHAR_QUOTATION_MARK:
    case UCHAR_RADICAL:
    case UCHAR_REGIONAL_INDICATOR:
    case UCHAR_S_TERM:
    case UCHAR_SOFT_DOTTED:
    case UCHAR_TERMINAL_PUNCTUATION:
    case UCHAR_UNIFIED_IDEOGRAPH:
    case UCHAR_UPPERCASE:
    case UCHAR_VARIATION_SELECTOR:
    case UCHAR_WHITE_SPACE:
    case UCHAR_XID_CONTINUE:
    case UCHAR_XID_START:
      return true;
    default:
      break;
  }
  return false;
}

bool IsUnicodePropertyValueCharacter(char c) {
  // https://tc39.github.io/proposal-regexp-unicode-property-escapes/
  //
  // Note that using this to validate each parsed char is quite conservative.
  // A possible alternative solution would be to only ensure the parsed
  // property name/value candidate string does not contain '\0' characters and
  // let ICU lookups trigger the final failure.
  if (Utils::IsAlphaNumeric(c)) return true;
  return (c == '_');
}

}  // anonymous namespace

bool RegExpParser::ParsePropertyClassName(ZoneGrowableArray<char>* name_1,
                                          ZoneGrowableArray<char>* name_2) {
  ASSERT(name_1->is_empty());
  ASSERT(name_2->is_empty());
  // Parse the property class as follows:
  // - In \p{name}, 'name' is interpreted
  //   - either as a general category property value name.
  //   - or as a binary property name.
  // - In \p{name=value}, 'name' is interpreted as an enumerated property name,
  //   and 'value' is interpreted as one of the available property value names.
  // - Aliases in PropertyAlias.txt and PropertyValueAlias.txt can be used.
  // - Loose matching is not applied.
  if (current() == '{') {
    // Parse \p{[PropertyName=]PropertyNameValue}
    for (Advance(); current() != '}' && current() != '='; Advance()) {
      if (!IsUnicodePropertyValueCharacter(current())) return false;
      if (!has_next()) return false;
      name_1->Add(static_cast<char>(current()));
    }
    if (current() == '=') {
      for (Advance(); current() != '}'; Advance()) {
        if (!IsUnicodePropertyValueCharacter(current())) return false;
        if (!has_next()) return false;
        name_2->Add(static_cast<char>(current()));
      }
      name_2->Add(0);  // null-terminate string.
    }
  } else {
    return false;
  }
  Advance();
  name_1->Add(0);  // null-terminate string.

  ASSERT(static_cast<size_t>(name_1->length() - 1) == strlen(name_1->data()));
  ASSERT(name_2->is_empty() ||
         static_cast<size_t>(name_2->length() - 1) == strlen(name_2->data()));
  return true;
}

bool RegExpParser::AddPropertyClassRange(
    ZoneGrowableArray<CharacterRange>* add_to,
    bool negate,
    ZoneGrowableArray<char>* name_1,
    ZoneGrowableArray<char>* name_2) {
  ASSERT(name_1->At(name_1->length() - 1) == '\0');
  ASSERT(name_2->is_empty() || name_2->At(name_2->length() - 1) == '\0');
  if (name_2->is_empty()) {
    // First attempt to interpret as general category property value name.
    const char* name = name_1->data();
    if (LookupPropertyValueName(UCHAR_GENERAL_CATEGORY_MASK, name, negate,
                                add_to)) {
      return true;
    }
    // Interpret "Any", "ASCII", and "Assigned".
    if (LookupSpecialPropertyValueName(name, add_to, negate)) {
      return true;
    }
    // Then attempt to interpret as binary property name with value name 'Y'.
    UProperty property = u_getPropertyEnum(name);
    if (!IsSupportedBinaryProperty(property)) return false;
    if (!IsExactPropertyAlias(name, property)) return false;
    return LookupPropertyValueName(property, negate ? "N" : "Y", false, add_to);
  } else {
    // Both property name and value name are specified. Attempt to interpret
    // the property name as enumerated property.
    const char* property_name = name_1->data();
    const char* value_name = name_2->data();
    UProperty property = u_getPropertyEnum(property_name);
    if (!IsExactPropertyAlias(property_name, property)) return false;
    if (property == UCHAR_GENERAL_CATEGORY) {
      // We want to allow aggregate value names such as "Letter".
      property = UCHAR_GENERAL_CATEGORY_MASK;
    } else if (property != UCHAR_SCRIPT &&
               property != UCHAR_SCRIPT_EXTENSIONS) {
      return false;
    }
    return LookupPropertyValueName(property, value_name, negate, add_to);
  }
}

bool RegExpParser::ParseUnlimitedLengthHexNumber(uint32_t max_value,
                                                 uint32_t* value) {
  uint32_t x = 0;
  int d = HexValue(current());
  if (d < 0) {
    return false;
  }
  while (d >= 0) {
    x = x * 16 + d;
    if (x > max_value) {
      return false;
    }
    Advance();
    d = HexValue(current());
  }
  *value = x;
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
      if (letter >= 'A' && letter <= 'Z') {
        Advance(2);
        // Control letters mapped to ASCII control characters in the range
        // 0x00-0x1f.
        return controlLetter & 0x1f;
      }
      if (is_unicode()) {
        // With /u, \c# or \c_ are invalid.
        ReportError("Invalid class escape");
        UNREACHABLE();
      }
      if (Utils::IsDecimalDigit(controlLetter) || controlLetter == '_') {
        Advance(2);
        return controlLetter & 0x1f;
      }
      // We match JSC in reading the backslash as a literal
      // character instead of as starting an escape.
      return '\\';
    }
    case '0':
      // With /u, \0 is interpreted as NUL if not followed by another digit.
      if (is_unicode() && !(Next() >= '0' && Next() <= '9')) {
        Advance();
        return 0;
      }
      FALL_THROUGH;
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
      if (is_unicode()) {
        // With \u, decimal escape is not interpreted as octal character code.
        ReportError("Invalid class escape");
        UNREACHABLE();
      }
      return ParseOctalLiteral();
    case 'x': {
      Advance();
      uint32_t value;
      if (ParseHexEscape(2, &value)) {
        return value;
      }
      if (is_unicode()) {
        // With \u, invalid escapes are not treated as identity escapes.
        ReportError("Invalid escape");
        UNREACHABLE();
      }
      // If \x is not followed by a two-digit hexadecimal, treat it
      // as an identity escape.
      return 'x';
    }
    case 'u': {
      Advance();
      uint32_t value;
      if (ParseUnicodeEscape(&value)) {
        return value;
      }
      if (is_unicode()) {
        // With \u, invalid escapes are not treated as identity escapes.
        ReportError(kUnicodeIdentity);
        UNREACHABLE();
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
      if (!is_unicode() || IsSyntaxCharacterOrSlash(result) || result == '-') {
        Advance();
        return result;
      }
      ReportError(kUnicodeIdentity);
      UNREACHABLE();
    }
  }
  return 0;
}

bool RegExpParser::ParseClassEscape(ZoneGrowableArray<CharacterRange>* ranges,
                                    bool add_unicode_case_equivalents,
                                    uint32_t* char_out) {
  uint32_t first = current();
  if (first == '\\') {
    switch (Next()) {
      case 'w':
      case 'W':
      case 'd':
      case 'D':
      case 's':
      case 'S': {
        CharacterRange::AddClassEscape(static_cast<uint16_t>(Next()), ranges,
                                       add_unicode_case_equivalents);
        Advance(2);
        return true;
      }
      case 'p':
      case 'P': {
        if (!is_unicode()) break;
        bool negate = Next() == 'P';
        Advance(2);
        auto name_1 = new (Z) ZoneGrowableArray<char>();
        auto name_2 = new (Z) ZoneGrowableArray<char>();
        if (!ParsePropertyClassName(name_1, name_2) ||
            !AddPropertyClassRange(ranges, negate, name_1, name_2)) {
          ReportError("Invalid property name in character class");
          UNREACHABLE();
        }
        return true;
      }
      case kEndMarker:
        ReportError("\\ at end of pattern");
        UNREACHABLE();
      default:
        break;
    }
    *char_out = ParseClassCharacterEscape();
    return false;
  }
  Advance();
  *char_out = first;
  return false;
}

RegExpTree* RegExpParser::ParseCharacterClass(const RegExpBuilder* builder) {
  static const char* kUnterminated = "Unterminated character class";
  static const char* kRangeInvalid = "Invalid character class";
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
  bool add_unicode_case_equivalents = is_unicode() && builder->ignore_case();
  while (has_more() && current() != ']') {
    uint32_t char_1 = 0;
    bool is_class_1 =
        ParseClassEscape(ranges, add_unicode_case_equivalents, &char_1);
    if (current() == '-') {
      Advance();
      if (current() == kEndMarker) {
        // If we reach the end we break out of the loop and let the
        // following code report an error.
        break;
      } else if (current() == ']') {
        if (!is_class_1) ranges->Add(CharacterRange::Singleton(char_1));
        ranges->Add(CharacterRange::Singleton('-'));
        break;
      }
      uint32_t char_2 = 0;
      bool is_class_2 =
          ParseClassEscape(ranges, add_unicode_case_equivalents, &char_2);
      if (is_class_1 || is_class_2) {
        // Either end is an escaped character class. Treat the '-' verbatim.
        if (is_unicode()) {
          // ES2015 21.2.2.15.1 step 1.
          ReportError(kRangeInvalid);
          UNREACHABLE();
        }
        if (!is_class_1) ranges->Add(CharacterRange::Singleton(char_1));
        ranges->Add(CharacterRange::Singleton('-'));
        if (!is_class_2) ranges->Add(CharacterRange::Singleton(char_2));
        continue;
      }
      if (char_1 > char_2) {
        ReportError(kRangeOutOfOrder);
        UNREACHABLE();
      }
      ranges->Add(CharacterRange::Range(char_1, char_2));
    } else {
      if (!is_class_1) ranges->Add(CharacterRange::Singleton(char_1));
    }
  }
  if (!has_more()) {
    ReportError(kUnterminated);
    UNREACHABLE();
  }
  Advance();
  RegExpCharacterClass::CharacterClassFlags character_class_flags =
      RegExpCharacterClass::DefaultFlags();
  if (is_negated) character_class_flags |= RegExpCharacterClass::NEGATED;
  return new (Z)
      RegExpCharacterClass(ranges, builder->flags(), character_class_flags);
}

// ----------------------------------------------------------------------------
// The Parser interface.

void RegExpParser::ParseRegExp(const String& input,
                               RegExpFlags flags,
                               RegExpCompileData* result) {
  ASSERT(result != NULL);
  RegExpParser parser(input, &result->error, flags);
  // Throws an exception if 'input' is not valid.
  RegExpTree* tree = parser.ParsePattern();
  ASSERT(tree != NULL);
  ASSERT(result->error.IsNull());
  result->tree = tree;
  intptr_t capture_count = parser.captures_started();
  result->simple = tree->IsAtom() && parser.simple() && capture_count == 0;
  result->contains_anchor = parser.contains_anchor();
  result->capture_name_map = parser.CreateCaptureNameMap();
  result->capture_count = capture_count;
}

}  // namespace dart
