// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/compiler/backend/il_deserializer.h"

#include <ctype.h>
#include "platform/utils.h"
#include "vm/object.h"

namespace dart {

const char* const SExpParser::ErrorStrings::kOpenString =
    "unterminated quoted string starting at position %" Pd "";
const char* const SExpParser::ErrorStrings::kBadUnicodeEscape =
    "malformed Unicode escape";
const char* const SExpParser::ErrorStrings::kOpenSExpList =
    "unterminated S-expression list starting at position %" Pd "";
const char* const SExpParser::ErrorStrings::kOpenMap =
    "unterminated extra info map starting at position %" Pd "";
const char* const SExpParser::ErrorStrings::kNestedMap =
    "extra info map start when already within extra info map";
const char* const SExpParser::ErrorStrings::kMapOutsideList =
    "extra info map start not within S-expression list";
const char* const SExpParser::ErrorStrings::kNonSymbolLabel =
    "non-symbol in label position for extra info map";
const char* const SExpParser::ErrorStrings::kNoMapLabel =
    "no extra info map label provided";
const char* const SExpParser::ErrorStrings::kRepeatedMapLabel =
    "extra info map label %s provided more than once";
const char* const SExpParser::ErrorStrings::kNoMapValue =
    "no value provided for extra info map label %s";
const char* const SExpParser::ErrorStrings::kExtraMapValue =
    "extra value following label %s in extra info map";
const char* const SExpParser::ErrorStrings::kUnexpectedComma =
    "comma found outside extra info map";
const char* const SExpParser::ErrorStrings::kUnexpectedRightParen =
    "unexpected closing parenthesis";
const char* const SExpParser::ErrorStrings::kUnexpectedRightCurly =
    "unexpected closing curly brace";

#define PARSE_ERROR(x, ...)                                                    \
  StoreError(x, __VA_ARGS__);                                                  \
  return nullptr

SExpression* SExpParser::Parse() {
  Reset();
  while (auto token = GetNextToken()) {
    const intptr_t start_pos = token->cstr() - buffer_;
    switch (token->type()) {
      case kLeftParen: {
        if (in_extra_) {
          if (cur_label_ == nullptr) {
            PARSE_ERROR(start_pos, ErrorStrings::kNonSymbolLabel);
          } else if (cur_value_ != nullptr) {
            PARSE_ERROR(start_pos, ErrorStrings::kExtraMapValue, cur_label_);
          }
        }
        auto sexp = new (zone_) SExpList(zone_, start_pos);
        list_stack_.Add(sexp);
        in_extra_stack_.Add(in_extra_);
        extra_start_stack_.Add(extra_start_);
        cur_label_stack_.Add(cur_label_);
        in_extra_ = false;
        extra_start_ = -1;
        cur_label_ = nullptr;
        break;
      }
      case kRightParen: {
        if (list_stack_.is_empty()) {
          PARSE_ERROR(start_pos, ErrorStrings::kUnexpectedRightParen);
        }
        if (in_extra_) {
          PARSE_ERROR(start_pos, ErrorStrings::kOpenMap, extra_start_);
        }
        auto sexp = list_stack_.RemoveLast();
        in_extra_ = in_extra_stack_.RemoveLast();
        extra_start_ = extra_start_stack_.RemoveLast();
        cur_label_ = cur_label_stack_.RemoveLast();
        if (list_stack_.is_empty()) return sexp;
        if (in_extra_) {
          if (cur_label_ == nullptr) {
            PARSE_ERROR(start_pos, ErrorStrings::kOpenMap, extra_start_);
          }
          cur_value_ = sexp;
        } else {
          list_stack_.Last()->Add(sexp);
        }
        break;
      }
      case kLeftCurly:
        if (in_extra_) {
          PARSE_ERROR(start_pos, ErrorStrings::kNestedMap);
        }
        if (list_stack_.is_empty()) {
          PARSE_ERROR(start_pos, ErrorStrings::kMapOutsideList);
        }
        extra_start_ = start_pos;
        in_extra_ = true;
        break;
      case kRightCurly:
        if (!in_extra_ || list_stack_.is_empty()) {
          PARSE_ERROR(start_pos, ErrorStrings::kUnexpectedRightCurly);
        }
        if (cur_label_ != nullptr) {
          if (cur_value_ == nullptr) {
            PARSE_ERROR(start_pos, ErrorStrings::kNoMapValue, cur_label_);
          }
          list_stack_.Last()->AddExtra(cur_label_, cur_value_);
          cur_label_ = nullptr;
          cur_value_ = nullptr;
        }
        in_extra_ = false;
        extra_start_ = -1;
        break;
      case kComma: {
        if (!in_extra_ || list_stack_.is_empty()) {
          PARSE_ERROR(start_pos, ErrorStrings::kUnexpectedComma);
        }
        if (cur_label_ == nullptr) {
          PARSE_ERROR(start_pos, ErrorStrings::kNoMapLabel);
        } else if (cur_value_ == nullptr) {
          PARSE_ERROR(start_pos, ErrorStrings::kNoMapValue, cur_label_);
        }
        list_stack_.Last()->AddExtra(cur_label_, cur_value_);
        cur_label_ = nullptr;
        cur_value_ = nullptr;
        break;
      }
      case kSymbol: {
        auto sexp = TokenToSExpression(token);
        ASSERT(sexp->IsSymbol());
        if (in_extra_) {
          if (cur_value_ != nullptr) {
            PARSE_ERROR(start_pos, ErrorStrings::kExtraMapValue, cur_label_);
          }
          if (cur_label_ == nullptr) {
            const char* const label = sexp->AsSymbol()->value();
            if (list_stack_.Last()->ExtraHasKey(label)) {
              PARSE_ERROR(start_pos, ErrorStrings::kRepeatedMapLabel, label);
            }
            cur_label_ = sexp->AsSymbol()->value();
          } else {
            cur_value_ = sexp;
          }
        } else if (!list_stack_.is_empty()) {
          list_stack_.Last()->Add(sexp);
        } else {
          return sexp;
        }
        break;
      }
      case kBoolean:
      case kNumber:
      case kQuotedString: {
        auto sexp = TokenToSExpression(token);
        // TokenToSExpression has already set the error info, so just return.
        if (sexp == nullptr) return nullptr;
        if (in_extra_) {
          if (cur_label_ == nullptr) {
            PARSE_ERROR(start_pos, ErrorStrings::kNonSymbolLabel);
          } else if (cur_value_ != nullptr) {
            PARSE_ERROR(start_pos, ErrorStrings::kExtraMapValue, cur_label_);
          }
          cur_value_ = sexp;
        } else if (!list_stack_.is_empty()) {
          list_stack_.Last()->Add(sexp);
        } else {
          return sexp;
        }
        break;
      }
      default:
        UNREACHABLE();
    }
  }
  if (in_extra_) {
    PARSE_ERROR(buffer_size_, ErrorStrings::kOpenMap, extra_start_);
  } else if (!list_stack_.is_empty()) {
    const intptr_t list_start = list_stack_.Last()->start();
    PARSE_ERROR(buffer_size_, ErrorStrings::kOpenSExpList, list_start);
  }
  UNREACHABLE();
}

SExpression* SExpParser::TokenToSExpression(Token* token) {
  const intptr_t start_pos = token->cstr() - buffer_;
  switch (token->type()) {
    case kSymbol:
      return new (zone_) SExpSymbol(token->ToCString(zone_), start_pos);
    case kNumber: {
      const char* cstr = token->ToCString(zone_);
      int64_t val;
      if (!OS::StringToInt64(cstr, &val)) return nullptr;
      return new (zone_) SExpInteger(val, start_pos);
    }
    case kBoolean: {
      const char* cstr = token->ToCString(zone_);
      return new (zone_) SExpBool(strcmp(cstr, "true") == 0, start_pos);
    }
    case kQuotedString: {
      const char* const cstr = token->cstr();
      char* const buf = zone_->Alloc<char>(token->length());
      // Skip the initial quote
      ASSERT(cstr[0] == '"');
      intptr_t old_pos = 1;
      intptr_t new_pos = 0;
      // The string _should_ end in a quote.
      while (old_pos < token->length() - 1) {
        if (cstr[old_pos] == '"') break;
        if (cstr[old_pos] != '\\') {
          buf[new_pos++] = cstr[old_pos++];
          continue;
        }
        old_pos++;
        if (old_pos >= token->length()) {
          PARSE_ERROR(start_pos + old_pos, ErrorStrings::kOpenString,
                      start_pos);
        }
        const intptr_t escape_pos = start_pos + old_pos - 1;
        switch (cstr[old_pos]) {
          case 'b':
            buf[new_pos] = '\b';
            break;
          case 'f':
            buf[new_pos] = '\f';
            break;
          case 'n':
            buf[new_pos] = '\n';
            break;
          case 'r':
            buf[new_pos] = '\r';
            break;
          case 't':
            buf[new_pos] = '\t';
            break;
          case 'u': {
            if (old_pos + 4 >= token->length()) {
              PARSE_ERROR(escape_pos, ErrorStrings::kBadUnicodeEscape);
            }
            intptr_t val = 0;
            for (intptr_t i = old_pos + 4; i > old_pos; old_pos--) {
              val *= 16;
              if (!Utils::IsHexDigit(i)) {
                PARSE_ERROR(escape_pos, ErrorStrings::kBadUnicodeEscape);
              }
              val += Utils::HexDigitToInt(i);
            }
            // Currently, just handle encoded ASCII instead of doing
            // handling Unicode characters.
            // (TextBuffer::AddEscapedString uses this for characters < 0x20.)
            ASSERT(val <= 0x7F);
            old_pos += 5;
            buf[new_pos] = val;
            break;
          }
          default:
            // Identity escapes.
            buf[new_pos] = cstr[old_pos];
            break;
        }
        old_pos++;
        new_pos++;
      }
      if (cstr[old_pos] != '"') {
        PARSE_ERROR(start_pos + token->length(), ErrorStrings::kOpenString,
                    start_pos);
      }
      buf[new_pos] = '\0';
      return new (zone_) SExpString(buf, start_pos);
    }
    default:
      UNREACHABLE();
  }
}

#undef PARSE_ERROR

SExpParser::Token* SExpParser::GetNextToken() {
  intptr_t start_pos = cur_pos_;
  while (start_pos < buffer_size_) {
    if (!isspace(buffer_[start_pos])) break;
    start_pos++;
  }
  if (start_pos >= buffer_size_) return nullptr;
  const char* start = buffer_ + start_pos;
  switch (*start) {
    case '(':
      cur_pos_ = start_pos + 1;
      return new (zone_) Token(kLeftParen, start, 1);
    case ')':
      cur_pos_ = start_pos + 1;
      return new (zone_) Token(kRightParen, start, 1);
    case ',':
      cur_pos_ = start_pos + 1;
      return new (zone_) Token(kComma, start, 1);
    case '{':
      cur_pos_ = start_pos + 1;
      return new (zone_) Token(kLeftCurly, start, 1);
    case '}':
      cur_pos_ = start_pos + 1;
      return new (zone_) Token(kRightCurly, start, 1);
    case '"': {
      intptr_t len = 1;
      while (start_pos + len < buffer_size_) {
        char curr = start[len];
        len++;  // Length should include the quote, if any.
        if (curr == '\\') {
          // Skip past next character (if any), since it cannot
          // end the quoted string due to being escaped.
          if (start_pos + len >= buffer_size_) break;
          len++;
          continue;
        }
        if (curr == '"') break;
      }
      cur_pos_ = start_pos + len;
      return new (zone_) Token(kQuotedString, start, len);
    }
    default:
      break;
  }
  if (isdigit(*start)) {
    intptr_t len = 1;
    while (start_pos + len < buffer_size_) {
      if (!isdigit(start[len])) break;
      len++;
    }
    cur_pos_ = start_pos + len;
    return new (zone_) Token(kNumber, start, len);
  }
  intptr_t len = 1;
  while (start_pos + len < buffer_size_) {
    if (!IsSymbolContinue(start[len])) break;
    len++;
  }
  cur_pos_ = start_pos + len;
  if (len == 4 && strncmp(start, "true", 4) == 0) {
    return new (zone_) Token(kBoolean, start, len);
  } else if (len == 5 && strncmp(start, "false", 5) == 0) {
    return new (zone_) Token(kBoolean, start, len);
  }
  return new (zone_) Token(kSymbol, start, len);
}

bool SExpParser::IsSymbolContinue(char c) {
  return !isspace(c) && c != '(' && c != ')' && c != ',' && c != '{' &&
         c != '}' && c != '"';
}

const char* const SExpParser::Token::TokenNames[kMaxTokens] = {
#define S_EXP_TOKEN_NAME_STRING(name) #name,
    S_EXP_TOKEN_LIST(S_EXP_TOKEN_NAME_STRING)
#undef S_EXP_TOKEN_NAME_STRING
};

const char* SExpParser::Token::ToCString(Zone* zone) {
  char* const buffer = zone->Alloc<char>(len_ + 1);
  strncpy(buffer, cstr_, len_);
  buffer[len_] = '\0';
  return buffer;
}

void SExpParser::Reset() {
  cur_pos_ = 0;
  in_extra_ = false;
  extra_start_ = -1;
  cur_label_ = nullptr;
  cur_value_ = nullptr;
  list_stack_.Clear();
  in_extra_stack_.Clear();
  extra_start_stack_.Clear();
  cur_label_stack_.Clear();
  error_pos_ = -1;
  error_message_ = nullptr;
}

void SExpParser::StoreError(intptr_t pos, const char* format, ...) {
  va_list args;
  va_start(args, format);
  const char* const message = OS::VSCreate(zone_, format, args);
  va_end(args);
  error_pos_ = pos;
  error_message_ = message;
}

void SExpParser::ReportError() const {
  ASSERT(error_message_ != nullptr);
  ASSERT(error_pos_ >= 0);
  // Throw a FormatException on parsing failures.
  const Array& eargs = Array::Handle(Array::New(3));
  eargs.SetAt(0, String::Handle(String::New(error_message_)));
  eargs.SetAt(1, String::Handle(String::FromUTF8(
                     reinterpret_cast<const uint8_t*>(buffer_), buffer_size_)));
  eargs.SetAt(2, Smi::Handle(Smi::New(error_pos_)));
  Exceptions::ThrowByType(Exceptions::kFormat, eargs);
  UNREACHABLE();
}

}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
