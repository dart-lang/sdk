// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Scanner class for the Dart language. The scanner reads source text
// and produces a stream of tokens which is used by the parser.
//

#ifndef VM_SCANNER_H_
#define VM_SCANNER_H_

#include "vm/growable_array.h"
#include "vm/token.h"

namespace dart {

// Forward declarations.
class Array;
class Library;
class RawString;
class String;

// A call to Scan() scans the source one token at at time.
// The scanned token is returned by cur_token().
// GetStream() scans the entire source text and returns a stream of tokens.
class Scanner : ValueObject {
 public:
  typedef int32_t (*CharAtFunc)(const String& str, intptr_t index);

  // SourcePosition describes a text location in user friendly
  // terms of line number and column.
  struct SourcePosition {
    int line;
    int column;
  };

  // TokenDesc defines the kind of a token and its location in
  // the source text.
  struct TokenDescriptor {
    Token::Kind kind;
    int offset;               // Offset in source string.
    SourcePosition position;  // Text position in source.
    const String* literal;    // Identifier, number or string literal.
  };

  // Dummy token index reflecting an unknown source position.
  static const intptr_t kNoSourcePos = 0;

  typedef ZoneGrowableArray<TokenDescriptor> GrowableTokenStream;

  // Initializes scanner to scan string source.
  Scanner(const String& source, const String& private_key);
  ~Scanner();

  // Scans one token at a time.
  void Scan();

  // Scans to specified token position.
  // Use CurrentPosition() to extract position.
  void ScanTo(intptr_t token_index);

  // Scans entire source and returns a stream of tokens.
  // Should be called only once.
  const GrowableTokenStream& GetStream();

  // Info about most recently recognized token.
  const TokenDescriptor& current_token() const { return current_token_; }

  // Was there a line break before the current token?
  bool NewlineBeforeToken() const { return newline_seen_; }

  // Source code line number and column of current token.
  const SourcePosition& CurrentPosition() const {
    return current_token_.position;
  }

  static void InitOnce();

  // Return true if str is an identifier.
  bool IsIdent(const String& str);

  // Does the token stream contain a valid literal. This is used to implement
  // the Dart methods int.parse and double.parse.
  static bool IsValidLiteral(const Scanner::GrowableTokenStream& tokens,
                             Token::Kind literal_kind,
                             bool* is_positive,
                             const String** value);

 private:
  static const int kNumLowercaseChars = 26;

  struct ScanContext {
    ScanContext* next;
    char string_delimiter;
    bool string_is_multiline;
    int  brace_level;
  };

  struct KeywordTable {
    Token::Kind kind;
    const char* keyword_chars;
    int keyword_len;
    const String* keyword_symbol;
  };

  // Rewind scanner position to token 0.
  void Reset();

  // Reads next lookahead character.
  void ReadChar();

  // Read and discard characters up to end of line.
  void SkipLine();

  // Recognizes token 'kind' and reads next character in input.
  void Recognize(Token::Kind kind) {
    ReadChar();
    current_token_.kind = kind;
  }

  int32_t LookaheadChar(int how_many);

  void ErrorMsg(const char* msg);

  // Scans entire source into a given stream of tokens.
  void ScanAll(GrowableTokenStream* token_stream);

  // These functions return true if the given character is a letter,
  // a decimal digit, a hexadecimal digit, etc.
  static bool IsLetter(int32_t c);
  static bool IsDecimalDigit(int32_t c);
  static bool IsNumberStart(int32_t);
  static bool IsHexDigit(int32_t c);
  static bool IsIdentStartChar(int32_t c);
  static bool IsIdentChar(int32_t c);

  // Skips up to next non-whitespace character.
  void ConsumeWhiteSpace();

  // Skips characters up to end of line.
  void ConsumeLineComment();

  // Skips characters up to matching '*/'.
  void ConsumeBlockComment();

  // Is this scanner currently scanning a string literal.
  bool IsScanningString() const { return string_delimiter_ != '\0'; }
  void BeginStringLiteral(const char delimiter);
  void EndStringLiteral();

  // Is this scanner currently scanning a string interpolation expression.
  bool IsNestedContext() const { return saved_context_ != NULL; }
  void PushContext();
  void PopContext();

  // Starts reading a string literal.
  void ScanLiteralString(bool is_raw);

  // Read the characters of a string literal. Remove whitespace up to
  // and including the first newline character if remove_whitespace
  // is true.
  void ScanLiteralStringChars(bool is_raw, bool remove_whitespace);

  // Reads a fixed number of hexadecimal digits.
  bool ScanHexDigits(int digits, int32_t* value);

  // Reads a variable number of hexadecimal digits.
  bool ScanHexDigits(int min_digits, int max_digits, int32_t* value);

  // Reads an escaped code point from within a string literal.
  void ScanEscapedCodePoint(int32_t* escaped_char);

  // Reads identifier.
  void ScanIdentChars(bool allow_dollar);
  void ScanIdent() {
    ScanIdentChars(true);
  }
  void ScanIdentNoDollar() {
    ScanIdentChars(false);
  }

  // Reads a number literal.
  void ScanNumber(bool dec_point_seen);

  void ScanScriptTag();

  CharAtFunc CallCharAt() const { return char_at_func_; }

  Isolate* isolate() const { return isolate_; }

  static void PrintTokens(const GrowableTokenStream& ts);

  TokenDescriptor current_token_;  // Current token.
  TokenDescriptor newline_token_;  // Newline token.
  TokenDescriptor empty_string_token_;  // Token for "".
  const String& source_;           // The source text being tokenized.
  intptr_t source_length_;         // The length of the source text.
  intptr_t lookahead_pos_;         // Position of lookahead character
                                   // within source_.
  intptr_t token_start_;           // Begin of current token in src_.
  int32_t c0_;                     // Lookahead character.
  bool newline_seen_;              // Newline before current token.
  intptr_t prev_token_line_;       // Line number of the previous token.

  // The following fields keep track whether we are scanning a string literal
  // and its interpolated expressions.
  ScanContext* saved_context_;
  int32_t string_delimiter_;
  bool string_is_multiline_;
  int brace_level_;

  const String& private_key_;

  SourcePosition c0_pos_;      // Source position of lookahead character c0_.

  const CharAtFunc char_at_func_;

  Isolate* isolate_;

  static KeywordTable keywords_[Token::kNumKeywords];
  static int keywords_char_offset_[kNumLowercaseChars];
};


}  // namespace dart

#endif  // VM_SCANNER_H_
