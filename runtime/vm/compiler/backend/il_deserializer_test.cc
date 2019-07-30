// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/backend/il_deserializer.h"
#include "vm/compiler/backend/il_serializer.h"

#include "platform/assert.h"
#include "vm/unit_test.h"

namespace dart {

static const char* const shared_sexp_cstr =
    "(def v0 (Constant 3) { type (CompileType 147 { nullable false, name "
    "\"T{Smi}\"}), })";

static void CheckDeserializedSExpParts(SExpression* sexp) {
  EXPECT_NOTNULL(sexp);
  EXPECT(sexp->IsList());
  SExpList* list = sexp->AsList();
  EXPECT_EQ(3, list->Length());
  EXPECT_NOTNULL(list->At(0));
  EXPECT(list->At(0)->IsSymbol());
  EXPECT_STREQ("def", list->At(0)->AsSymbol()->value());
  EXPECT_NOTNULL(list->At(1));
  EXPECT(list->At(1)->IsSymbol());
  EXPECT_STREQ("v0", list->At(1)->AsSymbol()->value());
  EXPECT_NOTNULL(list->At(2));
  EXPECT(list->At(2)->IsList());

  SExpList* sublist = list->At(2)->AsList();
  EXPECT_EQ(2, sublist->Length());
  EXPECT_NOTNULL(sublist->At(0));
  EXPECT(sublist->At(0)->IsSymbol());
  EXPECT_STREQ("Constant", sublist->At(0)->AsSymbol()->value());
  EXPECT_NOTNULL(sublist->At(1));
  EXPECT(sublist->At(1)->IsInteger());
  EXPECT_EQ(3, sublist->At(1)->AsInteger()->value());
  EXPECT_EQ(0, sublist->ExtraLength());

  EXPECT_EQ(1, list->ExtraLength());
  EXPECT(list->ExtraHasKey("type"));
  EXPECT(list->ExtraLookupValue("type")->IsList());

  SExpList* ctype = list->ExtraLookupValue("type")->AsList();
  EXPECT_EQ(2, ctype->Length());
  EXPECT_NOTNULL(ctype->At(0));
  EXPECT(ctype->At(0)->IsSymbol());
  EXPECT_STREQ("CompileType", ctype->At(0)->AsSymbol()->value());
  EXPECT_NOTNULL(ctype->At(1));
  EXPECT(ctype->At(1)->IsInteger());
  EXPECT_EQ(147, ctype->At(1)->AsInteger()->value());

  EXPECT_EQ(2, ctype->ExtraLength());
  EXPECT(ctype->ExtraHasKey("nullable"));
  EXPECT(ctype->ExtraLookupValue("nullable")->IsBool());
  EXPECT(!ctype->ExtraLookupValue("nullable")->AsBool()->value());
  EXPECT(ctype->ExtraHasKey("name"));
  EXPECT(ctype->ExtraLookupValue("name")->IsString());
  EXPECT_STREQ(ctype->ExtraLookupValue("name")->AsString()->value(), "T{Smi}");
}

ISOLATE_UNIT_TEST_CASE(DeserializeSExp) {
  Zone* const zone = Thread::Current()->zone();
  SExpression* sexp = SExpression::FromCString(zone, shared_sexp_cstr);
  CheckDeserializedSExpParts(sexp);

  // Treating escaped backslash appropriately so string is terminated.
  {
    const char* const cstr = "(def v0 (Constant 3) { foo \"123\\\\\" })";
    SExpParser parser(zone, cstr, strlen(cstr));
    SExpression* const sexp = parser.Parse();
    EXPECT_NOTNULL(sexp);
    EXPECT(sexp->IsList());
    EXPECT_EQ(1, sexp->AsList()->ExtraLength());
    EXPECT(sexp->AsList()->ExtraHasKey("foo"));
    auto val = sexp->AsList()->ExtraLookupValue("foo");
    EXPECT(val->IsString());
    EXPECT_STREQ("123\\", val->AsString()->value());
  }
}

ISOLATE_UNIT_TEST_CASE(DeserializeSExpRoundTrip) {
  Zone* const zone = Thread::Current()->zone();
  SExpression* sexp = SExpression::FromCString(zone, shared_sexp_cstr);

  TextBuffer buf(100);
  sexp->SerializeTo(zone, &buf, "", 9999);
  SExpression* round_trip = SExpression::FromCString(zone, buf.buf());
  CheckDeserializedSExpParts(round_trip);
  EXPECT(sexp->Equals(round_trip));

  const char* old_serialization = buf.Steal();
  round_trip->SerializeTo(zone, &buf, "", 9999);
  const char* new_serialization = buf.buf();
  EXPECT_STREQ(old_serialization, new_serialization);
  delete old_serialization;
}

ISOLATE_UNIT_TEST_CASE(DeserializeSExpMapsJoined) {
  Zone* const zone = Thread::Current()->zone();
  // Same as shared_sexp_cstr except we split the map on the CompileType into
  // two parts.
  const char* const cstr =
      "(def v0 (Constant 3) { type (CompileType { nullable false } 147 { name "
      "\"T{Smi}\"}), })";
  SExpression* sexp = SExpression::FromCString(zone, cstr);
  CheckDeserializedSExpParts(sexp);
}

ISOLATE_UNIT_TEST_CASE(DeserializeSExpFailures) {
  Zone* const zone = Thread::Current()->zone();
  // Unterminated s-exp list
  {
    const char* const before_start = "(def v0 ";
    const char* const after_start = "(Constant 3";
    const char* const cstr =
        OS::SCreate(zone, "%s%s", before_start, after_start);
    const intptr_t start_pos = strlen(before_start);
    const intptr_t error_pos = strlen(cstr);
    SExpParser parser(zone, cstr, strlen(cstr));
    SExpression* const sexp = parser.Parse();
    EXPECT_NULLPTR(sexp);
    EXPECT_EQ(error_pos, parser.error_pos());
    const char* const expected_message =
        OS::SCreate(zone, SExpParser::ErrorStrings::kOpenSExpList, start_pos);
    EXPECT_STREQ(expected_message, parser.error_message());
  }
  // Non-symbol label in map pair
  {
    const char* const before_error = "(def v0 (Constant 3) { ";
    const intptr_t error_pos = strlen(before_error);
    const char* const error = "3 4 })";
    const char* const cstr = OS::SCreate(zone, "%s%s", before_error, error);
    SExpParser parser(zone, cstr, strlen(cstr));
    SExpression* const sexp = parser.Parse();
    EXPECT_NULLPTR(sexp);
    EXPECT_EQ(error_pos, parser.error_pos());
    const char* const expected_message =
        SExpParser::ErrorStrings::kNonSymbolLabel;
    EXPECT_STREQ(expected_message, parser.error_message());
  }
  // No values in a map pair
  {
    const char* const label = "foo";
    const char* const before_error =
        OS::SCreate(zone, "(def v0 (Constant 3) { %s ", label);
    const intptr_t error_pos = strlen(before_error);
    const char* const error = "})";
    const char* const cstr = OS::SCreate(zone, "%s%s", before_error, error);
    SExpParser parser(zone, cstr, strlen(cstr));
    SExpression* const sexp = parser.Parse();
    EXPECT_NULLPTR(sexp);
    EXPECT_EQ(error_pos, parser.error_pos());
    const char* const expected_message =
        OS::SCreate(zone, SExpParser::ErrorStrings::kNoMapValue, label);
    EXPECT_STREQ(expected_message, parser.error_message());
  }
  // Multiple values in a map pair
  {
    const char* const label = "foo";
    const char* const before_error =
        OS::SCreate(zone, "(def v0 (Constant 3) { %s 4 ", label);
    const intptr_t error_pos = strlen(before_error);
    const char* const error = "5, })";
    const char* const cstr = OS::SCreate(zone, "%s%s", before_error, error);
    SExpParser parser(zone, cstr, strlen(cstr));
    SExpression* const sexp = parser.Parse();
    EXPECT_NULLPTR(sexp);
    EXPECT_EQ(error_pos, parser.error_pos());
    const char* const expected_message =
        OS::SCreate(zone, SExpParser::ErrorStrings::kExtraMapValue, label);
    EXPECT_STREQ(expected_message, parser.error_message());
  }
  // Unterminated quoted string
  {
    const char* const before_string =
        OS::SCreate(zone, "(def v0 (Constant 3) { foo ");
    const intptr_t string_pos = strlen(before_string);
    const char* const error = "\"abc })";
    const char* const cstr = OS::SCreate(zone, "%s%s", before_string, error);
    const intptr_t error_pos = strlen(cstr);
    SExpParser parser(zone, cstr, strlen(cstr));
    SExpression* const sexp = parser.Parse();
    EXPECT_NULLPTR(sexp);
    EXPECT_EQ(error_pos, parser.error_pos());
    const char* const expected_message =
        OS::SCreate(zone, SExpParser::ErrorStrings::kOpenString, string_pos);
    EXPECT_STREQ(expected_message, parser.error_message());
  }
  // Unterminated extra info map
  {
    const char* const before_map = "(def v0 (Constant 3) ";
    const intptr_t map_pos = strlen(before_map);
    const char* const map_start = "{ foo 3, ";
    const char* const before_error =
        OS::SCreate(zone, "%s%s", before_map, map_start);
    const intptr_t error_pos = strlen(before_error);
    const char* const error = ")";
    const char* const cstr = OS::SCreate(zone, "%s%s", before_error, error);
    SExpParser parser(zone, cstr, strlen(cstr));
    SExpression* const sexp = parser.Parse();
    EXPECT_NULLPTR(sexp);
    EXPECT_EQ(error_pos, parser.error_pos());
    const char* const expected_message =
        OS::SCreate(zone, SExpParser::ErrorStrings::kOpenMap, map_pos);
    EXPECT_STREQ(expected_message, parser.error_message());
  }
  // Repeated extra info map label
  {
    const char* const label = "foo";
    const char* const before_error =
        OS::SCreate(zone, "(def v0 (Constant 3) { %s 3, ", label);
    const intptr_t error_pos = strlen(before_error);
    const char* const error = OS::SCreate(zone, "%s 4, })", label);
    const char* const cstr = OS::SCreate(zone, "%s%s", before_error, error);
    SExpParser parser(zone, cstr, strlen(cstr));
    SExpression* const sexp = parser.Parse();
    EXPECT_NULLPTR(sexp);
    EXPECT_EQ(error_pos, parser.error_pos());
    const char* const expected_message =
        OS::SCreate(zone, SExpParser::ErrorStrings::kRepeatedMapLabel, label);
    EXPECT_STREQ(expected_message, parser.error_message());
  }
  // Unicode escape with non-hex digits.
  {
    const char* const before_error = "(def v0 (Constant 3) { foo \"123";
    const intptr_t error_pos = strlen(before_error);
    const char* const error = "\\u12FG\" })";
    const char* const cstr = OS::SCreate(zone, "%s%s", before_error, error);
    SExpParser parser(zone, cstr, strlen(cstr));
    SExpression* const sexp = parser.Parse();
    EXPECT_NULLPTR(sexp);
    EXPECT_EQ(error_pos, parser.error_pos());
    const char* const expected_message =
        SExpParser::ErrorStrings::kBadUnicodeEscape;
    EXPECT_STREQ(expected_message, parser.error_message());
  }
  // Unicode escape with less than four hex digits.
  {
    const char* const before_error = "(def v0 (Constant 3) { foo \"123";
    const intptr_t error_pos = strlen(before_error);
    const char* const error = "\\u12\" })";
    const char* const cstr = OS::SCreate(zone, "%s%s", before_error, error);
    SExpParser parser(zone, cstr, strlen(cstr));
    SExpression* const sexp = parser.Parse();
    EXPECT_NULLPTR(sexp);
    EXPECT_EQ(error_pos, parser.error_pos());
    const char* const expected_message =
        SExpParser::ErrorStrings::kBadUnicodeEscape;
    EXPECT_STREQ(expected_message, parser.error_message());
  }
  // Treating backslashed quote appropriately to detect unterminated string
  {
    const char* const before_string = "(def v0 (Constant 3) { foo ";
    const intptr_t string_pos = strlen(before_string);
    const char* const error = "\"123\\\" })";
    const char* const cstr = OS::SCreate(zone, "%s%s", before_string, error);
    const intptr_t error_pos = strlen(cstr);
    SExpParser parser(zone, cstr, strlen(cstr));
    SExpression* const sexp = parser.Parse();
    EXPECT_NULLPTR(sexp);
    EXPECT_EQ(error_pos, parser.error_pos());
    const char* const expected_message =
        OS::SCreate(zone, SExpParser::ErrorStrings::kOpenString, string_pos);
    EXPECT_STREQ(expected_message, parser.error_message());
  }
}

}  // namespace dart
