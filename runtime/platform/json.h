// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef PLATFORM_JSON_H_
#define PLATFORM_JSON_H_

#include "vm/allocation.h"
#include "vm/globals.h"

namespace dart {


// A low level interface to tokenize JSON strings.
class JSONScanner : ValueObject {
 public:
  enum Token {
    TokenIllegal = 0,
    TokenLBrace,
    TokenRBrace,
    TokenLBrack,
    TokenRBrack,
    TokenColon,
    TokenComma,
    TokenString,
    TokenInteger,
    TokenTrue,
    TokenFalse,
    TokenNull,
    TokenEOM
  };
  explicit JSONScanner(const char* json_text);

  void SetText(const char* json_text);
  void Scan();
  Token CurrentToken() const { return token_; }
  bool EOM() const { return token_ == TokenEOM; }
  const char* TokenChars() const { return token_start_; }
  int TokenLen() const { return token_length_; }
  bool IsStringLiteral(const char* literal) const;
  void Skip(Token matching_token);

 private:
  bool IsLetter(char ch) const;
  bool IsDigit(char ch) const;
  bool IsLiteral(const char* literal);
  void ScanNumber();
  void ScanString();
  void Recognize(Token t);

  const char* current_pos_;
  const char* token_start_;
  int token_length_;
  Token token_;
};


// JSONReader is a higher level interface that allows for lookup of
// name-value pairs in JSON objects.
class JSONReader : ValueObject {
 public:
  enum JSONType {
    kString,
    kInteger,
    kObject,
    kArray,
    kLiteral,
    kNone
  };

  explicit JSONReader(const char* json_object);
  void Set(const char* json_object);

  // Returns true if a pair with the given name was found.
  bool Seek(const char* name);

  // Returns true if a syntax error was found.
  bool Error() const { return error_; }

  // Returns a pointer to the matching closing brace if the text starts
  // with a valid JSON object. Returns NULL otherwise.
  const char* EndOfObject();

  JSONType Type() const;
  const char* ValueChars() const {
    return (Type() != kNone) ? scanner_.TokenChars() : NULL;
  }
  int ValueLen() const {
    return (Type() != kNone) ? scanner_.TokenLen() : 0;
  }
  void GetRawValueChars(char* buf, intptr_t buflen) const;
  void GetDecodedValueChars(char* buf, intptr_t buflen) const;
  bool IsStringLiteral(const char* literal) const {
    return scanner_.IsStringLiteral(literal);
  }
  bool IsTrue() const {
    return scanner_.CurrentToken() == JSONScanner::TokenTrue;
  }
  bool IsFalse() const {
    return scanner_.CurrentToken() == JSONScanner::TokenFalse;
  }
  bool IsNull() const {
    return scanner_.CurrentToken() == JSONScanner::TokenNull;
  }

  // Debugging method to check for validity of a JSON message.
  bool CheckMessage();

 private:
  void CheckObject();
  void CheckArray();
  void CheckValue();

  JSONScanner scanner_;
  const char* json_object_;
  bool error_;
};


// TextBuffer maintains a dynamic character buffer with a printf-style way to
// append text.
class TextBuffer : ValueObject {
 public:
  explicit TextBuffer(intptr_t buf_size);
  ~TextBuffer();

  intptr_t Printf(const char* format, ...) PRINTF_ATTRIBUTE(2, 3);
  void AddChar(char ch);
  void EscapeAndAddCodeUnit(uint32_t cu);
  void AddString(const char* s);
  void AddEscapedString(const char* s);

  void Clear();

  char* buf() { return buf_; }
  intptr_t length() { return msg_len_; }

  // Steal ownership of the buffer pointer.
  // NOTE: TextBuffer is empty afterwards.
  const char* Steal();

 private:
  void EnsureCapacity(intptr_t len);
  char* buf_;
  intptr_t buf_size_;
  intptr_t msg_len_;
};

}  // namespace dart

#endif  // PLATFORM_JSON_H_
