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
      ++current_pos_;
      if (*current_pos_ == '"') {
        // Consume escaped double quote.
        ++current_pos_;
      }
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


bool JSONReader::CheckMessage() {
  scanner_.SetText(json_object_);
  scanner_.Scan();
  CheckObject();
  return true;
}


void JSONReader::CheckValue() {
  switch (scanner_.CurrentToken()) {
    case JSONScanner::TokenLBrace:
      CheckObject();
      break;
    case JSONScanner::TokenLBrack:
      CheckArray();
      break;
    case JSONScanner::TokenString: {
      // Check the encoding.
      const char* s = ValueChars();
      int remaining = ValueLen();
      while (remaining > 0) {
        if ((*s == '\n') || (*s == '\t')) {
          OS::Print("Un-escaped character in JSON string: '%s'\n",
                    ValueChars());
          FATAL("illegal character in JSON string value");
        }
        s++;
        remaining--;
      }
      scanner_.Scan();
      break;
    }
    case JSONScanner::TokenInteger:
    case JSONScanner::TokenTrue:
    case JSONScanner::TokenFalse:
    case JSONScanner::TokenNull:
      scanner_.Scan();
      break;
    default:
      OS::Print("Malformed JSON: expected a value but got '%s'\n",
                scanner_.TokenChars());
      FATAL("illegal JSON value found");
  }
}


#if defined (DEBUG)
#define CHECK_TOKEN(token)                                                     \
  if (scanner_.CurrentToken() != token) {                                      \
    OS::Print("Malformed JSON: expected %s but got '%s'\n",                    \
              #token, scanner_.TokenChars());                                  \
    intptr_t offset = scanner_.TokenChars() - this->json_object_;              \
    OS::Print("Malformed JSON: expected %s at offset %" Pd "of buffer:\n%s\n", \
              #token, offset, this->json_object_);                             \
    ASSERT(scanner_.CurrentToken() == token);                                  \
  }
#else
#define CHECK_TOKEN(token)
#endif


void JSONReader::CheckArray() {
  CHECK_TOKEN(JSONScanner::TokenLBrack);
  scanner_.Scan();
  while (scanner_.CurrentToken() != JSONScanner::TokenRBrack) {
    CheckValue();
    if (scanner_.CurrentToken() != JSONScanner::TokenComma) {
      break;
    }
    scanner_.Scan();
  }
  CHECK_TOKEN(JSONScanner::TokenRBrack);
  scanner_.Scan();
}


void JSONReader::CheckObject() {
  CHECK_TOKEN(JSONScanner::TokenLBrace);
  scanner_.Scan();
  while (scanner_.CurrentToken() == JSONScanner::TokenString) {
    scanner_.Scan();
    CHECK_TOKEN(JSONScanner::TokenColon);
    scanner_.Scan();
    CheckValue();
    if (scanner_.CurrentToken() != JSONScanner::TokenComma) {
      break;
    }
    scanner_.Scan();
  }
  CHECK_TOKEN(JSONScanner::TokenRBrace);
  scanner_.Scan();
}

#undef CHECK_TOKEN


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


void JSONReader::GetRawValueChars(char* buf, intptr_t buflen) const {
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


void JSONReader::GetDecodedValueChars(char* buf, intptr_t buflen) const {
  if (Type() == kNone) {
    return;
  }
  const intptr_t last_idx = buflen - 1;
  const intptr_t value_len = ValueLen();
  const char* val = ValueChars();
  intptr_t buf_idx = 0;
  intptr_t val_idx = 0;
  while ((buf_idx < last_idx) && (val_idx < value_len)) {
    char ch = val[val_idx];
    val_idx++;
    buf[buf_idx] = ch;
    if ((ch == '\\') && (val_idx < value_len)) {
      switch (val[val_idx]) {
        case '"':
        case '\\':
        case '/':
          buf[buf_idx] = val[val_idx];
          val_idx++;
          break;
        case 'b':
          buf[buf_idx] = '\b';
          val_idx++;
          break;
        case 'f':
          buf[buf_idx] = '\f';
          val_idx++;
          break;
        case 'n':
          buf[buf_idx] = '\n';
          val_idx++;
          break;
        case 'r':
          buf[buf_idx] = '\r';
          val_idx++;
          break;
        case 't':
          buf[buf_idx] = '\t';
          val_idx++;
          break;
        case 'u':
          // \u00XX
          // If the value is malformed or > 255, ignore and copy the
          // encoded characters.
          if ((val_idx < value_len - 4) &&
              (val[val_idx + 1] == '0') && (val[val_idx + 2] == '0') &&
              Utils::IsHexDigit(val[val_idx + 3]) &&
              Utils::IsHexDigit(val[val_idx + 4])) {
            buf[buf_idx] = 16 * Utils::HexDigitToInt(val[val_idx + 3]) +
                Utils::HexDigitToInt(val[val_idx + 4]);
            val_idx += 5;
          }
          break;
        default:
          // Nothing. Copy the character after the backslash
          // in the next loop iteration.
          break;
      }
    }
    buf_idx++;
  }
  buf[buf_idx] = '\0';
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


const char* TextBuffer::Steal() {
  const char* r = buf_;
  buf_ = NULL;
  buf_size_ = 0;
  msg_len_ = 0;
  return r;
}


void TextBuffer::AddChar(char ch) {
  EnsureCapacity(sizeof(ch));
  buf_[msg_len_] = ch;
  msg_len_++;
  buf_[msg_len_] = '\0';
}


intptr_t TextBuffer::Printf(const char* format, ...) {
  va_list args;
  va_start(args, format);
  intptr_t remaining = buf_size_ - msg_len_;
  ASSERT(remaining >= 0);
  intptr_t len = OS::VSNPrint(buf_ + msg_len_, remaining, format, args);
  va_end(args);
  if (len >= remaining) {
    EnsureCapacity(len);
    remaining = buf_size_ - msg_len_;
    ASSERT(remaining > len);
    va_list args2;
    va_start(args2, format);
    intptr_t len2 = OS::VSNPrint(buf_ + msg_len_, remaining, format, args2);
    va_end(args2);
    ASSERT(len == len2);
  }
  msg_len_ += len;
  buf_[msg_len_] = '\0';
  return len;
}


// Write a UTF-16 code unit so it can be read by a JSON parser in a string
// literal. Use escape sequences for characters other than printable ASCII.
void TextBuffer::EscapeAndAddCodeUnit(uint32_t codeunit) {
  switch (codeunit) {
    case '"':
      Printf("%s", "\\\"");
      break;
    case '\\':
      Printf("%s", "\\\\");
      break;
    case '/':
      Printf("%s", "\\/");
      break;
    case '\b':
      Printf("%s", "\\b");
      break;
    case '\f':
      Printf("%s", "\\f");
      break;
    case '\n':
      Printf("%s", "\\n");
      break;
    case '\r':
      Printf("%s", "\\r");
      break;
    case '\t':
      Printf("%s", "\\t");
      break;
    default:
      if (codeunit < 0x20) {
        // Encode character as \u00HH.
        uint32_t digit2 = (codeunit >> 4) & 0xf;
        uint32_t digit3 = (codeunit & 0xf);
        Printf("\\u00%c%c",
               digit2 > 9 ? 'A' + (digit2 - 10) : '0' + digit2,
               digit3 > 9 ? 'A' + (digit3 - 10) : '0' + digit3);
      } else if (codeunit > 127) {
        // Encode character as \uHHHH.
        uint32_t digit0 = (codeunit >> 12) & 0xf;
        uint32_t digit1 = (codeunit >> 8) & 0xf;
        uint32_t digit2 = (codeunit >> 4) & 0xf;
        uint32_t digit3 = (codeunit & 0xf);
        Printf("\\u%c%c%c%c",
               digit0 > 9 ? 'A' + (digit0 - 10) : '0' + digit0,
               digit1 > 9 ? 'A' + (digit1 - 10) : '0' + digit1,
               digit2 > 9 ? 'A' + (digit2 - 10) : '0' + digit2,
               digit3 > 9 ? 'A' + (digit3 - 10) : '0' + digit3);
      } else {
        AddChar(codeunit);
      }
  }
}


void TextBuffer::AddString(const char* s) {
  Printf("%s", s);
}


void TextBuffer::AddEscapedString(const char* s) {
  intptr_t len = strlen(s);
  for (int i = 0; i < len; i++) {
    EscapeAndAddCodeUnit(s[i]);
  }
}


void TextBuffer::EnsureCapacity(intptr_t len) {
  intptr_t remaining = buf_size_ - msg_len_;
  if (remaining <= len) {
    const int kBufferSpareCapacity = 64;  // Somewhat arbitrary.
    // TODO(turnidge): do we need to guard against overflow or other
    // security issues here? Text buffers are used by the debugger
    // to send user-controlled data (e.g. values of string variables) to
    // the debugger front-end.
    intptr_t new_size = buf_size_ + len + kBufferSpareCapacity;
    char* new_buf = reinterpret_cast<char*>(realloc(buf_, new_size));
    ASSERT(new_buf != NULL);
    buf_ = new_buf;
    buf_size_ = new_size;
  }
}

}  // namespace dart
