// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/scanner.h"

#include "platform/assert.h"
#include "vm/dart.h"
#include "vm/flags.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/symbols.h"
#include "vm/token.h"
#include "vm/unicode.h"

namespace dart {

DEFINE_FLAG(bool, print_tokens, false, "Print scanned tokens.");


// Quick access to the locally defined isolate() method.
#define I (isolate())


class ScanContext : public ZoneAllocated {
 public:
  explicit ScanContext(Scanner* scanner)
      :  next_(scanner->saved_context_),
         string_delimiter_(scanner->string_delimiter_),
         string_is_multiline_(scanner->string_is_multiline_),
         brace_level_(scanner->brace_level_) {}

  void CopyTo(Scanner* scanner) {
    scanner->string_delimiter_ = string_delimiter_;
    scanner->string_is_multiline_ = string_is_multiline_;
    scanner->brace_level_ = brace_level_;
  }

  ScanContext* next() const { return next_; }

 private:
  ScanContext* next_;
  const char string_delimiter_;
  const bool string_is_multiline_;
  const int brace_level_;
};


Scanner::KeywordTable Scanner::keywords_[Token::kNumKeywords];
int Scanner::keywords_char_offset_[Scanner::kNumLowercaseChars];


void Scanner::Reset() {
  // Non-changing newline properties.
  newline_token_.kind = Token::kNEWLINE;
  newline_token_.literal = NULL;
  // We don't preserve the column information.
  newline_token_.position.column = 0;

  // Non-changing empty string token properties.
  empty_string_token_.kind = Token::kSTRING;
  empty_string_token_.literal = &Symbols::Empty();
  empty_string_token_.position.column = 0;

  lookahead_pos_ = -1;
  token_start_ = 0;
  c0_ = '\0';
  newline_seen_ = false;
  prev_token_line_ = 1;
  saved_context_ = NULL;
  string_delimiter_ = '\0';
  string_is_multiline_ = false;
  brace_level_ = 0;
  c0_pos_.line = 1;
  c0_pos_.column = 0;
  ReadChar();
}


Scanner::Scanner(const String& src, const String& private_key)
    : source_(src),
      source_length_(src.Length()),
      saved_context_(NULL),
      private_key_(String::ZoneHandle(private_key.raw())),
      char_at_func_(src.CharAtFunc()),
      isolate_(Isolate::Current()) {
  Reset();
}


Scanner::~Scanner() {}


void Scanner::ErrorMsg(const char* msg) {
  current_token_.kind = Token::kERROR;
  current_token_.literal = &String::ZoneHandle(I, Symbols::New(msg));
  current_token_.position = c0_pos_;
  token_start_ = lookahead_pos_;
  current_token_.offset = lookahead_pos_;
}


void Scanner::PushContext() {
  ScanContext* ctx = new(I) ScanContext(this);
  saved_context_ = ctx;
  string_delimiter_ = '\0';
  string_is_multiline_ = false;
  brace_level_ = 1;  // Account for the opening ${ token.
}


void Scanner::PopContext() {
  ASSERT(saved_context_ != NULL);
  ASSERT(brace_level_ == 0);
  ASSERT(string_delimiter_ == '\0');
  ScanContext* ctx = saved_context_;
  ctx->CopyTo(this);
  saved_context_ = ctx->next();
  ASSERT(string_delimiter_ != '\0');
}


void Scanner::BeginStringLiteral(const char delimiter) {
  string_delimiter_ = delimiter;
}


void Scanner::EndStringLiteral() {
  string_delimiter_ = '\0';
  string_is_multiline_ = false;
}


bool Scanner::IsLetter(int32_t c) {
  return (('A' <= c) && (c <= 'Z')) || (('a' <= c) && (c <= 'z'));
}


bool Scanner::IsDecimalDigit(int32_t c) {
  return '0' <= c && c <= '9';
}


bool Scanner::IsNumberStart(int32_t ch) {
  return IsDecimalDigit(ch) || ch == '.';
}


bool Scanner::IsHexDigit(int32_t c) {
  return IsDecimalDigit(c)
         || (('A' <= c) && (c <= 'F'))
         || (('a' <= c) && (c <= 'f'));
}


bool Scanner::IsIdentStartChar(int32_t c) {
  return IsLetter(c) || (c == '_') || (c == '$');
}


bool Scanner::IsIdentChar(int32_t c) {
  return IsLetter(c) || IsDecimalDigit(c) || (c == '_') || (c == '$');
}


bool Scanner::IsIdent(const String& str) {
  if (!str.IsOneByteString()) {
    return false;
  }
  if (str.Length() == 0 || !IsIdentStartChar(CallCharAt()(str, 0))) {
    return false;
  }
  for (int i =  1; i < str.Length(); i++) {
    if (!IsIdentChar(CallCharAt()(str, i))) {
      return false;
    }
  }
  return true;
}


// This method is used when parsing integers and doubles in Dart code. We
// are reusing the Scanner's handling of number literals in that situation.
bool Scanner::IsValidLiteral(const Scanner::GrowableTokenStream& tokens,
                             Token::Kind literal_kind,
                             bool* is_positive,
                             const String** value) {
  if ((tokens.length() == 2) &&
      (tokens[0].kind == literal_kind) &&
      (tokens[1].kind == Token::kEOS)) {
    *is_positive = true;
    *value = tokens[0].literal;
    return true;
  }
  if ((tokens.length() == 3) &&
      ((tokens[0].kind == Token::kADD) ||
       (tokens[0].kind == Token::kSUB)) &&
      (tokens[1].kind == literal_kind) &&
      (tokens[2].kind == Token::kEOS)) {
    // Check there is no space between "+/-" and number.
    if ((tokens[0].offset + 1) != tokens[1].offset) {
      return false;
    }
    *is_positive = tokens[0].kind == Token::kADD;
    *value = tokens[1].literal;
    return true;
  }
  return false;
}


void Scanner::ReadChar() {
  if (lookahead_pos_ < source_length_) {
    if (c0_ == '\n') {
      newline_seen_ = true;
      c0_pos_.line++;
      c0_pos_.column = 0;
      if (CallCharAt()(source_, lookahead_pos_) == '\r') {
        // Replace a sequence of '\r' '\n' with a single '\n'.
        if (LookaheadChar(1) == '\n') {
          lookahead_pos_++;
        }
      }
    }
    lookahead_pos_++;
    c0_pos_.column++;
    c0_ = LookaheadChar(0);
    // Replace '\r' with '\n'.
    if (c0_ == '\r') {
      c0_ = '\n';
    }
  }
}


// Look ahead 'how_many' characters. Returns the character, or '\0' if
// the lookahead position is beyond the end of the string. Does not
// normalize line end characters into '\n'.
int32_t Scanner::LookaheadChar(int how_many) {
  ASSERT(how_many >= 0);
  int32_t lookahead_char = '\0';
  if (lookahead_pos_ + how_many < source_length_) {
    lookahead_char = CallCharAt()(source_, lookahead_pos_ + how_many);
  }
  return lookahead_char;
}


void Scanner::ConsumeWhiteSpace() {
  while (c0_ == ' ' || c0_ == '\t' || c0_ == '\n') {
    ReadChar();
  }
}


void Scanner::ConsumeLineComment() {
  ASSERT(c0_ == '/');
  while (c0_ != '\n' && c0_ != '\0') {
    ReadChar();
  }
  ReadChar();
  current_token_.kind = Token::kWHITESP;
}


void Scanner::ConsumeBlockComment() {
  ASSERT(c0_ == '*');
  ReadChar();
  int nesting_level = 1;

  while (true) {
    const char c = c0_;
    ReadChar();
    if (c0_ == '\0') {
      break;
    }
    if (c == '/' && c0_ == '*') {
      nesting_level++;
      ReadChar();  // Consume asterisk.
    } else if (c == '*' && c0_ == '/') {
      nesting_level--;
      ReadChar();  // Consume slash.
      if (nesting_level == 0) {
        break;
      }
    }
  }
  current_token_.kind =
    (nesting_level == 0) ? Token::kWHITESP : Token::kILLEGAL;
}


void Scanner::ScanIdentChars(bool allow_dollar) {
  ASSERT(IsIdentStartChar(c0_));
  ASSERT(allow_dollar || (c0_ != '$'));
  int ident_length = 0;
  int ident_pos = lookahead_pos_;
  int32_t ident_char0 = CallCharAt()(source_, ident_pos);
  while (IsIdentChar(c0_) && (allow_dollar || (c0_ != '$'))) {
    ReadChar();
    ident_length++;
  }

  // Check whether the characters we read are a known keyword.
  // Note, can't use strcmp since token_chars is not null-terminated.
  if (('a' <= ident_char0) && (ident_char0 <= 'z')) {
    int i = keywords_char_offset_[ident_char0 - 'a'];
    while ((i < Token::kNumKeywords) &&
           (keywords_[i].keyword_chars[0] <= ident_char0)) {
      if (keywords_[i].keyword_len == ident_length) {
        const char* keyword = keywords_[i].keyword_chars;
        int char_pos = 1;
        while ((char_pos < ident_length) &&
               (keyword[char_pos] ==
                   CallCharAt()(source_, ident_pos + char_pos))) {
          char_pos++;
        }
        if (char_pos == ident_length) {
          current_token_.literal = keywords_[i].keyword_symbol;
          current_token_.kind = keywords_[i].kind;
          return;
        }
      }
      i++;
    }
  }

  // We did not read a keyword.
  current_token_.kind = Token::kIDENT;
  String& literal =
      String::ZoneHandle(I, Symbols::New(source_, ident_pos, ident_length));
  if (ident_char0 == Library::kPrivateIdentifierStart) {
    // Private identifiers are mangled on a per library basis.
    literal = String::Concat(literal, private_key_);
    literal = Symbols::New(literal);
  }
  current_token_.literal = &literal;
}


// Parse integer or double number literal of format:
// NUMBER = INTEGER | DOUBLE
// INTEGER = D+ | (("0x" | "0X") H+)
// DOUBLE = ((D+ ["." D*]) | ("." D+)) [ EXPONENT ]
// EXPONENT = ("e" | "E") ["+" | "-"] D+
void Scanner::ScanNumber(bool dec_point_seen) {
  ASSERT(IsDecimalDigit(c0_));
  char first_digit = c0_;

  Recognize(dec_point_seen ? Token::kDOUBLE : Token::kINTEGER);
  if (!dec_point_seen && first_digit == '0' && (c0_ == 'x' || c0_ == 'X')) {
    ReadChar();
    if (!IsHexDigit(c0_)) {
      ErrorMsg("hexadecimal digit expected");
      return;
    }
    while (IsHexDigit(c0_)) {
      ReadChar();
    }
  } else {
    while (IsDecimalDigit(c0_)) {
      ReadChar();
    }
    if (c0_ == '.' && !dec_point_seen && IsDecimalDigit(LookaheadChar(1))) {
      Recognize(Token::kDOUBLE);
      while (IsDecimalDigit(c0_)) {
        ReadChar();
      }
    }
    if (((c0_ == 'e') || (c0_ == 'E')) &&
        (IsDecimalDigit(LookaheadChar(1)) ||
         (LookaheadChar(1) == '-') ||
         (LookaheadChar(1) == '+'))) {
      Recognize(Token::kDOUBLE);
      if ((c0_ == '-') || (c0_ == '+')) {
        ReadChar();
      }
      if (!IsDecimalDigit(c0_)) {
        ErrorMsg("missing exponent digits");
        return;
      }
      while (IsDecimalDigit(c0_)) {
        ReadChar();
      }
    }
  }
  if (current_token_.kind != Token::kILLEGAL) {
    intptr_t len = lookahead_pos_ - token_start_;
    String& str = String::ZoneHandle(I,
        String::SubString(source_, token_start_, len, Heap::kOld));
    str = Symbols::New(str);
    current_token_.literal = &str;
  }
}


void Scanner::SkipLine() {
  while (c0_ != '\n' && c0_ != '\0') {
    ReadChar();
  }
}


void Scanner::ScanScriptTag() {
  ReadChar();
  ASSERT(c0_ == '!');
  Recognize(Token::kSCRIPTTAG);
  // The script tag extends to the end of the line. Just treat this
  // similar to a line comment.
  SkipLine();
}


void Scanner::ScanLiteralString(bool is_raw) {
  ASSERT(!IsScanningString());
  ASSERT(c0_ == '"' || c0_ == '\'');

  // Entering string scanning mode.
  BeginStringLiteral(c0_);
  ReadChar();

  if ((c0_ == string_delimiter_) && (LookaheadChar(1) == string_delimiter_)) {
    string_is_multiline_ = true;
    ReadChar();  // Skip two additional string delimiters.
    ReadChar();
  }
  ScanLiteralStringChars(is_raw, string_is_multiline_);
}


bool Scanner::ScanHexDigits(int digits, int32_t* value) {
  *value = 0;
  for (int i = 0; i < digits; ++i) {
    ReadChar();
    if (!IsHexDigit(c0_)) {
      ErrorMsg("too few hexadecimal digits");
      return false;
    }
    *value <<= 4;
    *value |= Utils::HexDigitToInt(c0_);
  }
  return true;
}


bool Scanner::ScanHexDigits(int min_digits, int max_digits, int32_t* value) {
  *value = 0;
  ReadChar();
  for (int i = 0; i < max_digits; ++i) {
    if (!IsHexDigit(c0_)) {
      if (i < min_digits) {
        ErrorMsg("hexadecimal digit expected");
        return false;
      }
      break;
    }
    *value <<= 4;
    *value |= Utils::HexDigitToInt(c0_);
    ReadChar();
  }
  return true;
}


void Scanner::ScanEscapedCodePoint(int32_t* code_point) {
  ASSERT(c0_ == 'u' || c0_ == 'x');
  bool is_valid;
  if (c0_ == 'x') {
    is_valid = ScanHexDigits(2, code_point);
  } else if (c0_ == 'u' && LookaheadChar(1) != '{') {
    is_valid = ScanHexDigits(4, code_point);
  } else {
    ReadChar();  // Skip left curly bracket.
    is_valid = ScanHexDigits(1, 6, code_point);
    if (is_valid) {
      if (c0_ != '}') {
        ErrorMsg("expected '}' after character code");
        return;
      }
    }
  }
  if (is_valid &&
      ((Utf::IsOutOfRange(*code_point) ||
        (Utf16::IsSurrogate(*code_point))))) {
    ErrorMsg("invalid code point");
  }
}


void Scanner::ScanLiteralStringChars(bool is_raw, bool remove_whitespace) {
  GrowableArray<int32_t> string_chars(64);

  ASSERT(IsScanningString());
  // We are at the first character of a string literal piece. A string literal
  // can be broken up into multiple pieces by string interpolation.
  while (true) {
    if ((c0_ == '\0') || ((c0_ == '\n') && !string_is_multiline_)) {
      ErrorMsg("unterminated string literal");
      EndStringLiteral();
      return;
    }
    if (c0_ == '\\' && !is_raw) {
      // Parse escape sequence.
      int32_t escape_char = '\0';
      ReadChar();
      switch (c0_) {
        case 'n':
          escape_char = '\n';
          break;
        case 'r':
          escape_char = '\r';
          break;
        case 'f':
          escape_char = '\f';
          break;
        case 't':
          escape_char = '\t';
          break;
        case 'b':
          escape_char = '\b';
          break;
        case 'v':
          escape_char = '\v';
          break;
        case 'u':
        case 'x': {
          ScanEscapedCodePoint(&escape_char);
          break;
        }
        default:
          if ((c0_ == '\0') || ((c0_ == '\n') && !string_is_multiline_)) {
            ErrorMsg("unterminated string literal");
            EndStringLiteral();
            return;
          }
          escape_char = c0_;
          break;
      }
      string_chars.Add(escape_char);
    } else if (c0_ == '$' && !is_raw) {
      // Scanned a string piece.
      ASSERT(string_chars.data() != NULL);
      // Strings are canonicalized: Allocate a symbol.
      current_token_.literal = &String::ZoneHandle(I,
          Symbols::FromUTF32(string_chars.data(), string_chars.length()));
      // Preserve error tokens.
      if (current_token_.kind != Token::kERROR) {
        current_token_.kind = Token::kSTRING;
      }
      return;
    } else if (c0_ == string_delimiter_) {
      // Check if we are at the end of the string literal.
      if (!string_is_multiline_ ||
          ((LookaheadChar(1) == string_delimiter_) &&
           (LookaheadChar(2) == string_delimiter_))) {
        if (string_is_multiline_) {
          ReadChar();  // Skip two string delimiters.
          ReadChar();
        }
        // Preserve error tokens.
        if (current_token_.kind == Token::kERROR) {
          ReadChar();
        } else {
          Recognize(Token::kSTRING);
          ASSERT(string_chars.data() != NULL);
          // Strings are canonicalized: Allocate a symbol.
          current_token_.literal = &String::ZoneHandle(I,
              Symbols::FromUTF32(string_chars.data(), string_chars.length()));
        }
        EndStringLiteral();
        return;
      } else {
        string_chars.Add(string_delimiter_);
      }
    } else {
      // Test for a two part utf16 sequence, and decode to a code point
      // if we find one.
      int32_t ch1 = c0_;
      if (Utf16::IsLeadSurrogate(ch1)) {
        const int32_t ch2 = LookaheadChar(1);
        if (Utf16::IsTrailSurrogate(ch2)) {
          ch1 = Utf16::Decode(ch1, ch2);
          ReadChar();
        }
      }
      string_chars.Add(ch1);
    }
    // The first line of a multi-line string is discarded if it only
    // contains whitespace.
    if (remove_whitespace && (string_chars.Last() == '\n')) {
      bool whitespace_only = true;
      // Last character is the newline, don't inspect it.
      const intptr_t len = string_chars.length() - 1;
      for (int i = 0; i < len; i++) {
        int32_t ch = string_chars[i];
        if ((ch != ' ') && (ch != '\t')) {
          // Non-whitespace character, keep the first line.
          whitespace_only = false;
          break;
        }
      }
      if (whitespace_only) {
        string_chars.Clear();  // Discard characters on first line.
      }
      remove_whitespace = false;
    }
    ReadChar();
  }
}


void Scanner::Scan() {
  newline_seen_ = false;

  do {
    if (!IsScanningString()) {
      ConsumeWhiteSpace();
    }
    token_start_ = lookahead_pos_;
    current_token_.offset = lookahead_pos_;
    current_token_.position = c0_pos_;
    current_token_.literal = NULL;
    current_token_.kind = Token::kILLEGAL;
    if (IsScanningString()) {
      if (c0_ == '$') {
        ReadChar();  // Skip the '$' character.
        if (IsIdentStartChar(c0_) && (c0_ != '$')) {
          ScanIdentNoDollar();
          current_token_.kind = Token::kINTERPOL_VAR;
        } else if (c0_ == '{') {
          Recognize(Token::kINTERPOL_START);
          PushContext();
        } else {
          ErrorMsg("illegal character after $ in string interpolation");
          EndStringLiteral();
          break;
        }
      } else {
        ScanLiteralStringChars(false, false);
      }
      break;
    }
    switch (c0_) {
      case '\0':
        current_token_.kind = Token::kEOS;
        break;

      case '+':  // +  ++  +=
        Recognize(Token::kADD);
        if (c0_ == '+') {
          Recognize(Token::kINCR);
        } else if (c0_ == '=') {
          Recognize(Token::kASSIGN_ADD);
        }
        break;

      case '-':  // -  --  -=
        Recognize(Token::kSUB);
        if (c0_ == '-') {
          Recognize(Token::kDECR);
        } else if (c0_ == '=') {
          Recognize(Token::kASSIGN_SUB);
        }
        break;

      case '*':  // *  *=
        Recognize(Token::kMUL);
        if (c0_ == '=') {
          Recognize(Token::kASSIGN_MUL);
        }
        break;

      case '%':  // %  %=
        Recognize(Token::kMOD);
        if (c0_ == '=') {
          Recognize(Token::kASSIGN_MOD);
        }
        break;

      case '/':  //  /  /=  //  /*
        Recognize(Token::kDIV);
        if (c0_ == '/') {
          ConsumeLineComment();
        } else if (c0_ == '*') {
          ConsumeBlockComment();
        } else if (c0_ == '=') {
          Recognize(Token::kASSIGN_DIV);
        }
        break;

      case '&':  // &  &=  &&
        Recognize(Token::kBIT_AND);
        if (c0_ == '=') {
          Recognize(Token::kASSIGN_AND);
        } else if (c0_ == '&') {
          Recognize(Token::kAND);
        }
        break;

      case '|':  // |  |=  ||
        Recognize(Token::kBIT_OR);
        if (c0_ == '=') {
          Recognize(Token::kASSIGN_OR);
        } else if (c0_ == '|') {
          Recognize(Token::kOR);
        }
        break;

      case '^':  // ^  ^=
        Recognize(Token::kBIT_XOR);
        if (c0_ == '=') {
          Recognize(Token::kASSIGN_XOR);
        }
        break;

      case '[':  // [  []  []=
        Recognize(Token::kLBRACK);
        if (c0_ == ']') {
          Recognize(Token::kINDEX);
          if (c0_ == '=') {
            Recognize(Token::kASSIGN_INDEX);
          }
        }
        break;

      case ']':  //  ]
        Recognize(Token::kRBRACK);
        break;

      case '<':  // <  <=  <<  <<=
        Recognize(Token::kLT);
        if (c0_ == '=') {
          Recognize(Token::kLTE);
        } else if (c0_ == '<') {
          Recognize(Token::kSHL);
          if (c0_ == '=') {
            Recognize(Token::kASSIGN_SHL);
          }
        }
        break;

      case '>':  // >  >=  >>  >>=
        Recognize(Token::kGT);
        if (c0_ == '=') {
          Recognize(Token::kGTE);
        } else if (c0_ == '>') {
          Recognize(Token::kSHR);
          if (c0_ == '=') {
            Recognize(Token::kASSIGN_SHR);
          }
        }
        break;

      case '!':  // !  !=
        Recognize(Token::kNOT);
        if (c0_ == '=') {
          Recognize(Token::kNE);
        }
        break;

      case '~':
        Recognize(Token::kBIT_NOT);
        if (c0_ == '/') {
          Recognize(Token::kTRUNCDIV);
          if (c0_ == '=') {
            Recognize(Token::kASSIGN_TRUNCDIV);
          }
        }
        break;

      case '=':  // =  ==  =>
        Recognize(Token::kASSIGN);
        if (c0_ == '=') {
          Recognize(Token::kEQ);
        } else if (c0_ == '>') {
          Recognize(Token::kARROW);
        }
        break;

      case '.':  // .  ..  Number
        Recognize(Token::kPERIOD);
        if (c0_ == '.') {
          Recognize(Token::kCASCADE);
        } else if (IsDecimalDigit(c0_)) {
          ScanNumber(true);
        }
        break;

      case '?':
        Recognize(Token::kCONDITIONAL);
        break;

      case ':':
        Recognize(Token::kCOLON);
        break;

      case ';':
        Recognize(Token::kSEMICOLON);
        break;

      case '{':
        Recognize(Token::kLBRACE);
        if (IsNestedContext()) {
          brace_level_++;
        }
        break;

      case '}':
        Recognize(Token::kRBRACE);
        if (IsNestedContext()) {
          ASSERT(brace_level_ > 0);
          brace_level_--;
          if (brace_level_ == 0) {
            current_token_.kind = Token::kINTERPOL_END;
            PopContext();
          }
        }
        break;

      case '(':
        Recognize(Token::kLPAREN);
        break;

      case ')':
        Recognize(Token::kRPAREN);
        break;

      case ',':
        Recognize(Token::kCOMMA);
        break;

      case '@':
        Recognize(Token::kAT);
        break;

      case 'r':
        if ((LookaheadChar(1) == '"') || (LookaheadChar(1) == '\'')) {
          ReadChar();
          ScanLiteralString(true);
        } else {
          ScanIdent();
        }
        break;

      case '"':
      case '\'':
        ScanLiteralString(false);
        break;

      case '#':
        if (LookaheadChar(1) == '!') {
          ScanScriptTag();
        } else {
          Recognize(Token::kHASH);
        }
        break;

      default:
        if (IsIdentStartChar(c0_)) {
          ScanIdent();
        } else if (IsDecimalDigit(c0_)) {
          ScanNumber(false);
        } else {
          char msg[128];
          char utf8_char[5];
          int len = Utf8::Encode(c0_, utf8_char);
          utf8_char[len] = '\0';
          OS::SNPrint(msg, sizeof(msg),
                      "unexpected character: '%s' (U+%04X)\n", utf8_char, c0_);
          ErrorMsg(msg);
          ReadChar();
        }
    }
  } while (current_token_.kind == Token::kWHITESP);
}


void Scanner::ScanAll(GrowableTokenStream* token_stream) {
  Reset();
  do {
    Scan();

    bool inserted_new_lines = false;
    for (intptr_t diff = current_token_.position.line - prev_token_line_;
         diff > 0;
         diff--) {
      newline_token_.position.line = current_token_.position.line - diff;
      token_stream->Add(newline_token_);
      inserted_new_lines = true;
    }

    if (inserted_new_lines &&
        ((current_token_.kind == Token::kINTERPOL_VAR) ||
         (current_token_.kind == Token::kINTERPOL_START))) {
      // NOTE: If this changes, be sure to update
      // Script::GenerateLineNumberArray to stay in sync.
      empty_string_token_.position.line = current_token_.position.line;
      token_stream->Add(empty_string_token_);
    }
    token_stream->Add(current_token_);
    prev_token_line_ = current_token_.position.line;
  } while (current_token_.kind != Token::kEOS);
}


void Scanner::ScanTo(intptr_t token_index) {
  int index = 0;
  Reset();
  do {
    Scan();

    bool inserted_new_lines = false;
    for (intptr_t diff = current_token_.position.line - prev_token_line_;
         diff > 0;
         diff--) {
      index++;  // Advance the index to account for tokens added in ScanAll.
      inserted_new_lines = true;
    }

    if (inserted_new_lines &&
        ((current_token_.kind == Token::kINTERPOL_VAR) ||
         (current_token_.kind == Token::kINTERPOL_START))) {
          index++;  // Advance the index to account for tokens added in ScanAll.
    }
    index++;
    prev_token_line_ = current_token_.position.line;
  } while ((token_index >= index) && (current_token_.kind != Token::kEOS));
}


const Scanner::GrowableTokenStream& Scanner::GetStream() {
  GrowableTokenStream* ts = new(I) GrowableTokenStream(128);
  ScanAll(ts);
  if (FLAG_print_tokens) {
    Scanner::PrintTokens(*ts);
  }
  return *ts;
}


void Scanner::PrintTokens(const GrowableTokenStream& ts) {
  int currentLine = -1;
  for (int i = 0; i < ts.length(); i++) {
    const TokenDescriptor& td = ts[i];
    if (currentLine != td.position.line) {
      currentLine = td.position.line;
      OS::Print("\n%d (%d): ", currentLine, i);
    }
    OS::Print("%s ", Token::Name(td.kind));
  }
  OS::Print("\n");
}


void Scanner::InitOnce() {
  ASSERT(Isolate::Current() == Dart::vm_isolate());
  for (int i = 0; i < kNumLowercaseChars; i++) {
    keywords_char_offset_[i] = Token::kNumKeywords;
  }
  for (int i = 0; i < Token::kNumKeywords; i++) {
    Token::Kind token = static_cast<Token::Kind>(Token::kFirstKeyword + i);
    keywords_[i].kind = token;
    keywords_[i].keyword_chars = Token::Str(token);
    keywords_[i].keyword_len = strlen(Token::Str(token));
    keywords_[i].keyword_symbol = &Symbols::Keyword(token);

    int ch = keywords_[i].keyword_chars[0] - 'a';
    if (keywords_char_offset_[ch] == Token::kNumKeywords) {
      keywords_char_offset_[ch] = i;
    }
  }
}

}  // namespace dart
