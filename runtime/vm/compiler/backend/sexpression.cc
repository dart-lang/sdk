// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/backend/sexpression.h"

#include <ctype.h>
#include "platform/utils.h"
#include "vm/double_conversion.h"
#include "vm/zone_text_buffer.h"

namespace dart {

SExpression* SExpression::FromCString(Zone* zone, const char* str) {
  SExpParser parser(zone, str);
  auto sexp = parser.Parse();
  if (sexp == nullptr) parser.ReportError();
  return sexp;
}

const char* SExpression::ToCString(Zone* zone) const {
  ZoneTextBuffer buf(zone, 1 * KB);
  SerializeToLine(&buf);
  return buf.buffer();
}

bool SExpBool::Equals(SExpression* sexp) const {
  if (auto const b = sexp->AsBool()) return b->Equals(value());
  return false;
}

bool SExpBool::Equals(bool val) const {
  return value() == val;
}

void SExpBool::SerializeToLine(BaseTextBuffer* buffer) const {
  buffer->AddString(value() ? SExpParser::kBoolTrueSymbol
                            : SExpParser::kBoolFalseSymbol);
}

bool SExpDouble::Equals(SExpression* sexp) const {
  if (auto const d = sexp->AsDouble()) return d->Equals(value());
  return false;
}

bool SExpDouble::Equals(double val) const {
  return value() == val;
}

void SExpDouble::SerializeToLine(BaseTextBuffer* buffer) const {
  // Use existing Dart serialization for Doubles.
  const intptr_t kBufSize = 128;
  char strbuf[kBufSize];
  DoubleToCString(value(), strbuf, kBufSize);
  buffer->Printf("%s", strbuf);
}

bool SExpInteger::Equals(SExpression* sexp) const {
  if (auto const i = sexp->AsInteger()) return i->Equals(value());
  return false;
}

bool SExpInteger::Equals(int64_t val) const {
  return value() == val;
}

void SExpInteger::SerializeToLine(BaseTextBuffer* buffer) const {
  buffer->Printf("%" Pd64 "", value());
}

bool SExpString::Equals(SExpression* sexp) const {
  if (auto const s = sexp->AsString()) return s->Equals(value());
  return false;
}

bool SExpString::Equals(const char* str) const {
  return strcmp(value(), str) == 0;
}

void SExpString::SerializeToLine(BaseTextBuffer* buffer) const {
  TextBuffer buf(80);
  buf.AddChar('"');
  buf.AddEscapedString(value());
  buf.AddChar('"');
  buffer->AddString(buf.buffer());
}

bool SExpSymbol::Equals(SExpression* sexp) const {
  if (auto const s = sexp->AsSymbol()) return s->Equals(value());
  return false;
}

bool SExpSymbol::Equals(const char* str) const {
  return strcmp(value(), str) == 0;
}

void SExpSymbol::SerializeToLine(BaseTextBuffer* buffer) const {
  buffer->AddString(value());
}

void SExpList::Add(SExpression* sexp) {
  contents_.Add(sexp);
}

void SExpList::AddExtra(const char* label, SExpression* value) {
  ASSERT(!extra_info_.HasKey(label));
  extra_info_.Insert({label, value});
}

bool SExpList::Equals(SExpression* sexp) const {
  if (!sexp->IsList()) return false;
  auto list = sexp->AsList();
  if (Length() != list->Length()) return false;
  if (ExtraLength() != list->ExtraLength()) return false;
  for (intptr_t i = 0; i < Length(); i++) {
    if (!At(i)->Equals(list->At(i))) return false;
  }
  auto this_it = ExtraIterator();
  while (auto kv = this_it.Next()) {
    if (!list->ExtraHasKey(kv->key)) return false;
    if (!kv->value->Equals(list->ExtraLookupValue(kv->key))) return false;
  }
  return true;
}

const char* const SExpList::kElemIndent = " ";
const char* const SExpList::kExtraIndent = "  ";

static intptr_t HandleLineBreaking(Zone* zone,
                                   BaseTextBuffer* buffer,
                                   SExpression* element,
                                   BaseTextBuffer* line_buffer,
                                   const char* sub_indent,
                                   intptr_t width,
                                   bool leading_space,
                                   intptr_t remaining) {
  element->SerializeToLine(line_buffer);
  const intptr_t single_line_width = line_buffer->length();
  const intptr_t leading_length = leading_space ? 1 : 0;

  if ((leading_length + single_line_width) < remaining) {
    if (leading_space) buffer->AddChar(' ');
    buffer->AddString(line_buffer->buffer());
    line_buffer->Clear();
    return remaining - (leading_length + single_line_width);
  }
  const intptr_t old_length = buffer->length();
  buffer->Printf("\n%s", sub_indent);
  const intptr_t line_used = buffer->length() - old_length + 1;
  remaining = width - line_used;
  if ((single_line_width < remaining) || element->IsAtom()) {
    buffer->AddString(line_buffer->buffer());
    line_buffer->Clear();
    return remaining - single_line_width;
  }
  line_buffer->Clear();
  element->SerializeTo(zone, buffer, sub_indent, width);
  return 0;
}

// Assumes that we are starting on a line after [indent] amount of space.
void SExpList::SerializeTo(Zone* zone,
                           BaseTextBuffer* buffer,
                           const char* indent,
                           intptr_t width) const {
  TextBuffer single_line(width);
  const char* sub_indent = OS::SCreate(zone, "%s%s", indent, kElemIndent);

  buffer->AddChar('(');
  intptr_t remaining = width - strlen(indent) - 1;
  for (intptr_t i = 0; i < contents_.length(); i++) {
    remaining = HandleLineBreaking(zone, buffer, contents_.At(i), &single_line,
                                   sub_indent, width, i != 0, remaining);
  }

  if (!extra_info_.IsEmpty()) {
    SerializeExtraInfoToLine(&single_line);
    if (single_line.length() < remaining - 1) {
      buffer->Printf(" %s", single_line.buffer());
    } else {
      const intptr_t old_length = buffer->length();
      buffer->Printf("\n%s", sub_indent);
      const intptr_t line_used = buffer->length() - old_length + 1;
      remaining = width - line_used;
      if (single_line.length() < remaining) {
        buffer->AddString(single_line.buffer());
      } else {
        SerializeExtraInfoTo(zone, buffer, sub_indent, width);
      }
    }
  }
  buffer->AddChar(')');
}

void SExpList::SerializeToLine(BaseTextBuffer* buffer) const {
  buffer->AddChar('(');
  for (intptr_t i = 0; i < contents_.length(); i++) {
    if (i != 0) buffer->AddChar(' ');
    contents_.At(i)->SerializeToLine(buffer);
  }
  if (!extra_info_.IsEmpty()) {
    buffer->AddChar(' ');
    SerializeExtraInfoToLine(buffer);
  }
  buffer->AddChar(')');
}

void SExpList::SerializeExtraInfoTo(Zone* zone,
                                    BaseTextBuffer* buffer,
                                    const char* indent,
                                    int width) const {
  const char* sub_indent = OS::SCreate(zone, "%s%s", indent, kExtraIndent);
  TextBuffer single_line(width);

  buffer->AddChar('{');
  auto it = ExtraIterator();
  while (auto kv = it.Next()) {
    const intptr_t old_length = buffer->length();
    buffer->Printf("\n%s%s", sub_indent, kv->key);
    const intptr_t remaining = width - (buffer->length() - old_length + 1);
    HandleLineBreaking(zone, buffer, kv->value, &single_line, sub_indent, width,
                       /*leading_space=*/true, remaining);
    buffer->AddChar(',');
  }
  buffer->Printf("\n%s}", indent);
}

void SExpList::SerializeExtraInfoToLine(BaseTextBuffer* buffer) const {
  buffer->AddString("{");
  auto it = ExtraIterator();
  while (auto kv = it.Next()) {
    buffer->Printf(" %s ", kv->key);
    kv->value->SerializeToLine(buffer);
    buffer->AddChar(',');
  }
  buffer->AddString(" }");
}

const char* const SExpParser::kBoolTrueSymbol = "true";
const char* const SExpParser::kBoolFalseSymbol = "false";
char const SExpParser::kDoubleExponentChar =
    DoubleToStringConstants::kExponentChar;
const char* const SExpParser::kDoubleInfinitySymbol =
    DoubleToStringConstants::kInfinitySymbol;
const char* const SExpParser::kDoubleNaNSymbol =
    DoubleToStringConstants::kNaNSymbol;

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
      case kInteger:
      case kDouble:
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
    case kInteger: {
      const char* cstr = token->ToCString(zone_);
      int64_t val;
      if (!OS::StringToInt64(cstr, &val)) return nullptr;
      return new (zone_) SExpInteger(val, start_pos);
    }
    case kBoolean: {
      const bool is_true =
          strncmp(token->cstr(), kBoolTrueSymbol, token->length()) == 0;
      ASSERT(is_true ||
             strncmp(token->cstr(), kBoolFalseSymbol, token->length()) == 0);
      return new (zone_) SExpBool(is_true, start_pos);
    }
    case kDouble: {
      double val;
      if (!CStringToDouble(token->cstr(), token->length(), &val)) {
        return nullptr;
      }
      return new (zone_) SExpDouble(val, start_pos);
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
            const intptr_t first = old_pos + 1;
            const intptr_t last = old_pos + 4;
            if (last >= token->length()) {
              PARSE_ERROR(escape_pos, ErrorStrings::kBadUnicodeEscape);
            }
            intptr_t val = 0;
            for (const char *cursor = cstr + first, *end = cstr + last + 1;
                 cursor < end; cursor++) {
              val *= 16;
              if (!Utils::IsHexDigit(*cursor)) {
                PARSE_ERROR(escape_pos, ErrorStrings::kBadUnicodeEscape);
              }
              val += Utils::HexDigitToInt(*cursor);
            }
            // Currently, just handle encoded ASCII instead of doing
            // handling Unicode characters.
            // (TextBuffer::AddEscapedString uses this for characters < 0x20.)
            ASSERT(val <= 0x7F);
            old_pos = last;
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
    if (isspace(buffer_[start_pos]) == 0) break;
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
  intptr_t len = 0;
  // Start number detection after possible negation sign.
  if (start[len] == '-') {
    len++;
    if ((start_pos + len) >= buffer_size_) {
      cur_pos_ = start_pos + len;
      return new (zone_) Token(kSymbol, start, len);
    }
  }
  // Keep the currently detected token type. Start off by assuming we have
  // an integer, then fall back to doubles if we see parts appropriate for
  // those but not integers, and fall back to symbols otherwise.
  TokenType type = kInteger;
  bool saw_exponent = false;
  while ((start_pos + len) < buffer_size_) {
    // Both numbers and symbols cannot contain these values, so we are at the
    // end of whichever one we're in.
    if (!IsSymbolContinue(start[len])) break;
    if (type == kInteger && start[len] == '.') {
      type = kDouble;
      len++;
      continue;
    }
    if (type != kSymbol && !saw_exponent && start[len] == kDoubleExponentChar) {
      saw_exponent = true;
      type = kDouble;
      len++;
      // Skip past negation in exponent if any.
      if ((start_pos + len) < buffer_size_ && start[len] == '-') len++;
      continue;
    }
    // If we find a character that can't appear in a number, then fall back
    // to symbol-ness.
    if (isdigit(start[len]) == 0) type = kSymbol;
    len++;
  }
  cur_pos_ = start_pos + len;
  // Skip special symbol detection if we don't have a symbol.
  if (type != kSymbol) return new (zone_) Token(type, start, len);
  // Check for special symbols used for booleans and certain Double values.
  switch (len) {
    case 3:
      if (strncmp(start, kDoubleNaNSymbol, len) == 0) type = kDouble;
      break;
    case 4:
      if (strncmp(start, kBoolTrueSymbol, len) == 0) type = kBoolean;
      break;
    case 5:
      if (strncmp(start, kBoolFalseSymbol, len) == 0) type = kBoolean;
      break;
    case 8:
      if (strncmp(start, kDoubleInfinitySymbol, len) == 0) type = kDouble;
      break;
    case 9:
      if (start[0] == '-' &&
          strncmp(start + 1, kDoubleInfinitySymbol, len - 1) == 0) {
        type = kDouble;
      }
      break;
    default:
      break;
  }
  return new (zone_) Token(type, start, len);
}

bool SExpParser::IsSymbolContinue(char c) {
  return (isspace(c) == 0) && c != '(' && c != ')' && c != ',' && c != '{' &&
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
  OS::PrintErr("Unable to parse s-expression: %s\n", buffer_);
  OS::PrintErr("Error at character %" Pd ": %s\n", error_pos_, error_message_);
  OS::Abort();
}

}  // namespace dart
