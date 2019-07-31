// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/compiler/backend/sexpression.h"

#include "vm/compiler/backend/il_deserializer.h"
#include "vm/double_conversion.h"

namespace dart {

SExpression* SExpression::FromCString(Zone* zone, const char* str) {
  SExpParser parser(zone, str);
  auto sexp = parser.Parse();
  if (sexp == nullptr) parser.ReportError();
  return sexp;
}

bool SExpBool::Equals(SExpression* sexp) const {
  if (!sexp->IsBool()) return false;
  return this->value() == sexp->AsBool()->value();
}

void SExpBool::SerializeToLine(TextBuffer* buffer) const {
  buffer->AddString(value() ? SExpParser::kBoolTrueSymbol
                            : SExpParser::kBoolFalseSymbol);
}

bool SExpDouble::Equals(SExpression* sexp) const {
  if (!sexp->IsDouble()) return false;
  return this->value() == sexp->AsDouble()->value();
}

void SExpDouble::SerializeToLine(TextBuffer* buffer) const {
  // Use existing Dart serialization for Doubles.
  const intptr_t kBufSize = 128;
  char strbuf[kBufSize];
  DoubleToCString(value(), strbuf, kBufSize);
  buffer->Printf("%s", strbuf);
}

bool SExpInteger::Equals(SExpression* sexp) const {
  if (!sexp->IsInteger()) return false;
  return this->value() == sexp->AsInteger()->value();
}

void SExpInteger::SerializeToLine(TextBuffer* buffer) const {
  buffer->Printf("%" Pd "", value());
}

bool SExpString::Equals(SExpression* sexp) const {
  if (!sexp->IsString()) return false;
  return strcmp(this->value(), sexp->AsString()->value()) == 0;
}

void SExpString::SerializeToLine(TextBuffer* buffer) const {
  buffer->AddChar('"');
  buffer->AddEscapedString(value());
  buffer->AddChar('"');
}

bool SExpSymbol::Equals(SExpression* sexp) const {
  if (!sexp->IsSymbol()) return false;
  return strcmp(this->value(), sexp->AsSymbol()->value()) == 0;
}

void SExpSymbol::SerializeToLine(TextBuffer* buffer) const {
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
                                   TextBuffer* buffer,
                                   SExpression* element,
                                   TextBuffer* line_buffer,
                                   const char* sub_indent,
                                   intptr_t width,
                                   bool leading_space,
                                   intptr_t remaining) {
  element->SerializeToLine(line_buffer);
  const intptr_t single_line_width = line_buffer->length();
  const intptr_t leading_length = leading_space ? 1 : 0;

  if ((leading_length + single_line_width) < remaining) {
    if (leading_space != 0) buffer->AddChar(' ');
    buffer->AddString(line_buffer->buf());
    line_buffer->Clear();
    return remaining - (leading_length + single_line_width);
  }
  const intptr_t old_length = buffer->length();
  buffer->Printf("\n%s", sub_indent);
  const intptr_t line_used = buffer->length() - old_length + 1;
  remaining = width - line_used;
  if ((single_line_width < remaining) || element->IsAtom()) {
    buffer->AddString(line_buffer->buf());
    line_buffer->Clear();
    return remaining - single_line_width;
  }
  line_buffer->Clear();
  element->SerializeTo(zone, buffer, sub_indent, width);
  return 0;
}

// Assumes that we are starting on a line after [indent] amount of space.
void SExpList::SerializeTo(Zone* zone,
                           TextBuffer* buffer,
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
      buffer->Printf(" %s", single_line.buf());
    } else {
      const intptr_t old_length = buffer->length();
      buffer->Printf("\n%s", sub_indent);
      const intptr_t line_used = buffer->length() - old_length + 1;
      remaining = width - line_used;
      if (single_line.length() < remaining) {
        buffer->AddString(single_line.buf());
      } else {
        SerializeExtraInfoTo(zone, buffer, sub_indent, width);
      }
    }
  }
  buffer->AddChar(')');
}

void SExpList::SerializeToLine(TextBuffer* buffer) const {
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
                                    TextBuffer* buffer,
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

void SExpList::SerializeExtraInfoToLine(TextBuffer* buffer) const {
  buffer->AddString("{");
  auto it = ExtraIterator();
  while (auto kv = it.Next()) {
    buffer->Printf(" %s ", kv->key);
    kv->value->SerializeToLine(buffer);
    buffer->AddChar(',');
  }
  buffer->AddString(" }");
}

}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
