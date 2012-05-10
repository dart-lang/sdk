// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/json.h"

#include "platform/assert.h"
#include "platform/globals.h"
#include "platform/utils.h"
#include "vm/os.h"

namespace dart {


JSONScanner::JSONScanner(const char* json_text) {
  SetText(json_text);
}


void JSONScanner::SetText(const char* json_text) {
  current_pos_ = json_text;
  token_start_ = json_text;
  token_length_ = 0;
  token_ = TokenIllegal;
}


void JSONScanner::Recognize(Token t) {
  ++current_pos_;
  token_ = t;
}


bool JSONScanner::IsLetter(char ch) const {
  return (('A' <= ch) && (ch <= 'Z')) || (('a' <= ch) && (ch <= 'z'));
}


bool JSONScanner::IsDigit(char ch) const {
  return ('0' <= ch) && (ch <= '9');
}


bool JSONScanner::IsLiteral(const char* literal) {
  int i = 0;
  while ((literal[i] != '\0') && (current_pos_[i] == literal[i])) {
    i++;
  }
  if ((literal[i] == '\0') && !IsLetter(current_pos_[i])) {
    current_pos_ += i;
    return true;
  }
  return false;
}


bool JSONScanner::IsStringLiteral(const char* literal) const {
  if (token_ != TokenString) {
    return false;
  }
  int i = 0;
  while ((i < token_length_) && (token_start_[i] == literal[i])) {
    i++;
  }
  return (i == token_length_) && (literal[i] == '\0');
}


void JSONScanner::Skip(Token matching_token) {
  while (!EOM() && (token_ != TokenIllegal)) {
    Scan();
    if (token_ == TokenLBrace) {
      Skip(TokenRBrace);
    } else if (token_ == TokenLBrack) {
      Skip(TokenRBrack);
    } else if (token_ == matching_token) {
      return;
    } else if ((token_ == TokenRBrace) || (token_ == TokenRBrack)) {
      // Mismatched brace or bracket.
      token_ = TokenIllegal;
    }
  }
}


void JSONScanner::ScanString() {
  ASSERT(*current_pos_ == '"');
  ++current_pos_;
  token_start_ = current_pos_;
  while (*current_pos_ != '"') {
    if (*current_pos_ == '\0') {
      token_length_ = 0;
      token_ = TokenIllegal;
      return;
    } else if (*current_pos_ == '\\') {
      // TODO(hausner): Implement escape sequence.
      UNIMPLEMENTED();
    } else if (*current_pos_ < 0) {
      // UTF-8 not supported.
      token_length_ = 0;
      token_ = TokenIllegal;
      return;
    } else {
      ++current_pos_;
    }
  }
  token_ = TokenString;
  token_length_ = current_pos_ - token_start_;
  ++current_pos_;
}


void JSONScanner::ScanNumber() {
  if (*current_pos_ == '-') {
    ++current_pos_;
  }
  if (!IsDigit(*current_pos_)) {
    token_ = TokenIllegal;
    token_length_ = 0;
    return;
  }
  while (IsDigit(*current_pos_)) {
    ++current_pos_;
  }
  if ((*current_pos_ == '.') ||
      (*current_pos_ == 'e') ||
      (*current_pos_ == 'E')) {
    // Floating point numbers not supported.
    token_ = TokenIllegal;
    token_length_ = 0;
    return;
  }
  token_ = TokenInteger;
  token_length_ = current_pos_ - token_start_;
}


void JSONScanner::Scan() {
  while ((*current_pos_ == ' ') ||
         (*current_pos_ == '\t') ||
         (*current_pos_ == '\n')) {
    ++current_pos_;
  }
  token_start_ = current_pos_;
  if (*current_pos_ == '\0') {
    token_length_ = 0;
    token_ = TokenEOM;
    return;
  }
  switch (*current_pos_) {
    case '{':
      Recognize(TokenLBrace);
      break;
    case '}':
      Recognize(TokenRBrace);
      break;
    case '[':
      Recognize(TokenLBrack);
      break;
    case ']':
      Recognize(TokenRBrack);
      break;
    case ':':
      Recognize(TokenColon);
      break;
    case ',':
      Recognize(TokenComma);
      break;
    case '"':
      ScanString();
      break;
    case '0':
    case '1':
    case '2':
    case '3':
    case '4':
    case '5':
    case '6':
    case '7':
    case '8':
    case '9':
    case '-':
      ScanNumber();
      break;
    default:
      if (IsLiteral("true")) {
        token_ = TokenTrue;
        token_length_ = 4;
      } else if (IsLiteral("false")) {
        token_ = TokenFalse;
        token_length_ = 5;
      } else if (IsLiteral("null")) {
        token_ = TokenNull;
        token_length_ = 4;
      } else {
        token_length_ = 0;
        token_ = TokenIllegal;
      }
  }
}


JSONReader::JSONReader(const char* json_object)
: scanner_(json_object) {
  Set(json_object);
}

void JSONReader::Set(const char* json_object) {
  scanner_.SetText(json_object);
  json_object_ = json_object;
  error_ = false;
}


bool JSONReader::Seek(const char* name) {
  error_ = false;
  scanner_.SetText(json_object_);
  scanner_.Scan();
  if (scanner_.CurrentToken() != JSONScanner::TokenLBrace) {
    error_ = true;
    return false;
  }
  scanner_.Scan();
  if (scanner_.CurrentToken() == JSONScanner::TokenRBrace) {
    return false;
  }
  while (scanner_.CurrentToken() == JSONScanner::TokenString) {
    bool found = scanner_.IsStringLiteral(name);
    scanner_.Scan();
    if (scanner_.CurrentToken() != JSONScanner::TokenColon) {
      error_ = true;
      return false;
    }
    scanner_.Scan();
    switch (scanner_.CurrentToken()) {
      case JSONScanner::TokenString:
      case JSONScanner::TokenInteger:
      case JSONScanner::TokenLBrace:
      case JSONScanner::TokenLBrack:
      case JSONScanner::TokenTrue:
      case JSONScanner::TokenFalse:
      case JSONScanner::TokenNull:
        // Found a legal value.
        if (found) {
          return true;
        }
        break;
      default:
        error_ = true;
        return false;
    }
    // Skip the value.
    if (scanner_.CurrentToken() == JSONScanner::TokenLBrace) {
      scanner_.Skip(JSONScanner::TokenRBrace);
      if (scanner_.CurrentToken() != JSONScanner::TokenRBrace) {
        error_ = true;
        return false;
      }
    } else if (scanner_.CurrentToken() == JSONScanner::TokenLBrack) {
      scanner_.Skip(JSONScanner::TokenRBrack);
      if (scanner_.CurrentToken() != JSONScanner::TokenRBrack) {
        error_ = true;
        return false;
      }
    }
    scanner_.Scan();  // Value or closing brace or bracket.
    if (scanner_.CurrentToken() == JSONScanner::TokenComma) {
      scanner_.Scan();
    } else if (scanner_.CurrentToken() == JSONScanner::TokenRBrace) {
      return false;
    } else {
      error_ = true;
      return false;
    }
  }
  error_ = true;
  return false;
}


const char* JSONReader::EndOfObject() {
  bool found = Seek("***");  // Look for illegally named value.
  ASSERT(!found);
  if (!found && !error_) {
    const char* s = scanner_.TokenChars();
    ASSERT(*s == '}');
    return s;
  }
  return NULL;
}


JSONReader::JSONType JSONReader::Type() const {
  if (error_) {
    return kNone;
  }
  switch (scanner_.CurrentToken()) {
    case JSONScanner::TokenString:
      return kString;
    case JSONScanner::TokenInteger:
      return kInteger;
    case JSONScanner::TokenLBrace:
      return kObject;
    case JSONScanner::TokenLBrack:
      return kArray;
    case JSONScanner::TokenTrue:
    case JSONScanner::TokenFalse:
    case JSONScanner::TokenNull:
      return kLiteral;
    default:
      return kNone;
  }
}


void JSONReader::GetValueChars(char* buf, intptr_t buflen) const {
  if (Type() == kNone) {
    return;
  }
  intptr_t max = buflen - 1;
  if (ValueLen() < max) {
    max = ValueLen();
  }
  const char* val = ValueChars();
  intptr_t i = 0;
  for (; i < max; i++) {
    buf[i] = val[i];
  }
  buf[i] = '\0';
}


TextBuffer::TextBuffer(intptr_t buf_size) {
  ASSERT(buf_size > 0);
  buf_ = reinterpret_cast<char*>(malloc(buf_size));
  buf_size_ = buf_size;
  Clear();
}


TextBuffer::~TextBuffer() {
  free(buf_);
  buf_ = NULL;
}


void TextBuffer::Clear() {
  msg_len_ = 0;
  buf_[0] = '\0';
}


intptr_t TextBuffer::Printf(const char* format, va_list args) {
  va_list args1;
  va_copy(args1, args);
  intptr_t remaining = buf_size_ - msg_len_;
  ASSERT(remaining >= 0);
  intptr_t len = OS::VSNPrint(buf_ + msg_len_, remaining, format, args1);
  va_end(args1);
  if (len >= remaining) {
    const int kBufferSpareCapacity = 64;  // Somewhat arbitrary.
    GrowBuffer(len + kBufferSpareCapacity);
    remaining = buf_size_ - msg_len_;
    ASSERT(remaining > len);
    va_list args2;
    va_copy(args2, args);
    intptr_t len2 = OS::VSNPrint(buf_ + msg_len_, remaining, format, args2);
    va_end(args2);
    ASSERT(len == len2);
  }
  msg_len_ += len;
  buf_[msg_len_] = '\0';
  return len;
}


intptr_t TextBuffer::Printf(const char* format, ...) {
  va_list args;
  va_start(args, format);
  intptr_t len = this->Printf(format, args);
  va_end(args);
  return len;
}


void TextBuffer::GrowBuffer(intptr_t len) {
  intptr_t new_size = buf_size_ + len;
  char* new_buf = reinterpret_cast<char*>(realloc(buf_, new_size));
  ASSERT(new_buf != NULL);
  buf_ = new_buf;
  buf_size_ = new_size;
}

}  // namespace dart
