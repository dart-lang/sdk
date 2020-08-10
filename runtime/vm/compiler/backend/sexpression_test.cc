// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/backend/sexpression.h"

#include <cmath>
#include "platform/assert.h"
#include "vm/unit_test.h"

namespace dart {

#define EXPECT_SEXP_PARSE_ERROR(sexp, parser, pos, message)                    \
  do {                                                                         \
    if (sexp != nullptr) {                                                     \
      dart::Expect(__FILE__, __LINE__)                                         \
          .Fail("parse unexpectedly succeeded for \"%s\"", parser.Input());    \
    }                                                                          \
    EXPECT_EQ(pos, parser.error_pos());                                        \
    EXPECT_STREQ(message, parser.error_message());                             \
  } while (false);

#define EXPECT_SEXP_PARSE_SUCCESS(sexp, parser)                                \
  do {                                                                         \
    if (sexp == nullptr) {                                                     \
      EXPECT_NOTNULL(parser.error_message());                                  \
      dart::Expect(__FILE__, __LINE__)                                         \
          .Fail("parse unexpectedly failed at \"%s\": %" Pd ": %s",            \
                parser.Input() + parser.error_pos(), parser.error_pos(),       \
                parser.error_message());                                       \
    }                                                                          \
  } while (false);

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
    EXPECT_SEXP_PARSE_SUCCESS(sexp, parser);
    EXPECT(sexp->IsList());
    EXPECT_EQ(1, sexp->AsList()->ExtraLength());
    EXPECT(sexp->AsList()->ExtraHasKey("foo"));
    auto val = sexp->AsList()->ExtraLookupValue("foo");
    EXPECT(val->IsString());
    EXPECT_STREQ("123\\", val->AsString()->value());
  }
  // Valid unicode escapes are properly handled.
  {
    const char* const cstr =
        "(def v0 (Constant 3) { foo \"\\u0001\\u0020\\u0054\" })";
    SExpParser parser(zone, cstr, strlen(cstr));
    SExpression* const sexp = parser.Parse();
    EXPECT_SEXP_PARSE_SUCCESS(sexp, parser);
    EXPECT(sexp->IsList());
    EXPECT_EQ(1, sexp->AsList()->ExtraLength());
    EXPECT(sexp->AsList()->ExtraHasKey("foo"));
    auto val = sexp->AsList()->ExtraLookupValue("foo");
    EXPECT(val->IsString());
    EXPECT_STREQ("\x01 T", val->AsString()->value());
  }
}

ISOLATE_UNIT_TEST_CASE(DeserializeSExpNumbers) {
  Zone* const zone = Thread::Current()->zone();

  // Negative integers are handled.
  {
    const char* const cstr = "(-4 -50 -1414243)";
    SExpParser parser(zone, cstr, strlen(cstr));
    SExpression* const sexp = parser.Parse();
    EXPECT_SEXP_PARSE_SUCCESS(sexp, parser);
    EXPECT(sexp->IsList());
    auto list = sexp->AsList();
    EXPECT_EQ(3, list->Length());
    EXPECT_EQ(0, list->ExtraLength());
    for (intptr_t i = 0; i < list->Length(); i++) {
      EXPECT(list->At(i)->IsInteger());
      EXPECT(list->At(i)->AsInteger()->value() < 0);
    }
  }

  // Various decimal/exponent Doubles are appropriately handled.
  {
    const char* const cstr = "(1.05 0.05 .03 1e100 1e-100)";
    SExpParser parser(zone, cstr, strlen(cstr));
    SExpression* const sexp = parser.Parse();
    EXPECT_SEXP_PARSE_SUCCESS(sexp, parser);
    EXPECT(sexp->IsList());
    auto list = sexp->AsList();
    EXPECT_EQ(5, list->Length());
    EXPECT_EQ(0, list->ExtraLength());
    EXPECT(list->At(0)->IsDouble());
    double val = list->At(0)->AsDouble()->value();
    EXPECT(val > 1.04 && val < 1.06);
    EXPECT(list->At(1)->IsDouble());
    val = list->At(1)->AsDouble()->value();
    EXPECT(val > 0.04 && val < 0.06);
    EXPECT(list->At(2)->IsDouble());
    val = list->At(2)->AsDouble()->value();
    EXPECT(val > 0.02 && val < 0.04);
    EXPECT(list->At(3)->IsDouble());
    val = list->At(3)->AsDouble()->value();
    EXPECT(val > 0.9e100 && val < 1.1e100);
    EXPECT(list->At(4)->IsDouble());
    val = list->At(4)->AsDouble()->value();
    EXPECT(val > 0.9e-100 && val < 1.1e-100);
  }

  // Special Double symbols are appropriately handled.
  {
    const char* const cstr = "(NaN Infinity -Infinity)";
    SExpParser parser(zone, cstr, strlen(cstr));
    SExpression* const sexp = parser.Parse();
    EXPECT_SEXP_PARSE_SUCCESS(sexp, parser);
    EXPECT(sexp->IsList());
    auto list = sexp->AsList();
    EXPECT_EQ(3, list->Length());
    EXPECT_EQ(0, list->ExtraLength());
    EXPECT(list->At(0)->IsDouble());
    double val = list->At(0)->AsDouble()->value();
    EXPECT(isnan(val));
    EXPECT(list->At(1)->IsDouble());
    val = list->At(1)->AsDouble()->value();
    EXPECT(val > 0.0);
    EXPECT(isinf(val));
    EXPECT(list->At(2)->IsDouble());
    val = list->At(2)->AsDouble()->value();
    EXPECT(val < 0.0);
    EXPECT(isinf(val));
  }
}

ISOLATE_UNIT_TEST_CASE(DeserializeSExpRoundTrip) {
  Zone* const zone = Thread::Current()->zone();
  SExpression* sexp = SExpression::FromCString(zone, shared_sexp_cstr);

  TextBuffer buf(100);
  sexp->SerializeTo(zone, &buf, "", 9999);
  SExpression* round_trip = SExpression::FromCString(zone, buf.buffer());
  CheckDeserializedSExpParts(round_trip);
  EXPECT(sexp->Equals(round_trip));

  char* const old_serialization = buf.Steal();
  round_trip->SerializeTo(zone, &buf, "", 9999);
  char* const new_serialization = buf.buffer();
  EXPECT_STREQ(old_serialization, new_serialization);
  free(old_serialization);
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
    const char* const expected_message =
        OS::SCreate(zone, SExpParser::ErrorStrings::kOpenSExpList, start_pos);
    EXPECT_SEXP_PARSE_ERROR(sexp, parser, error_pos, expected_message);
  }
  // Non-symbol label in map pair
  {
    const char* const before_error = "(def v0 (Constant 3) { ";
    const intptr_t error_pos = strlen(before_error);
    const char* const error = "3 4 })";
    const char* const cstr = OS::SCreate(zone, "%s%s", before_error, error);
    SExpParser parser(zone, cstr, strlen(cstr));
    SExpression* const sexp = parser.Parse();
    const char* const expected_message =
        SExpParser::ErrorStrings::kNonSymbolLabel;
    EXPECT_SEXP_PARSE_ERROR(sexp, parser, error_pos, expected_message);
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
    const char* const expected_message =
        OS::SCreate(zone, SExpParser::ErrorStrings::kNoMapValue, label);
    EXPECT_SEXP_PARSE_ERROR(sexp, parser, error_pos, expected_message);
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
    const char* const expected_message =
        OS::SCreate(zone, SExpParser::ErrorStrings::kExtraMapValue, label);
    EXPECT_SEXP_PARSE_ERROR(sexp, parser, error_pos, expected_message);
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
    const char* const expected_message =
        OS::SCreate(zone, SExpParser::ErrorStrings::kOpenString, string_pos);
    EXPECT_SEXP_PARSE_ERROR(sexp, parser, error_pos, expected_message);
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
    const char* const expected_message =
        OS::SCreate(zone, SExpParser::ErrorStrings::kOpenMap, map_pos);
    EXPECT_SEXP_PARSE_ERROR(sexp, parser, error_pos, expected_message);
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
    const char* const expected_message =
        OS::SCreate(zone, SExpParser::ErrorStrings::kRepeatedMapLabel, label);
    EXPECT_SEXP_PARSE_ERROR(sexp, parser, error_pos, expected_message);
  }
  // Unicode escape with non-hex digits.
  {
    const char* const before_error = "(def v0 (Constant 3) { foo \"123";
    const intptr_t error_pos = strlen(before_error);
    const char* const error = "\\u12FG\" })";
    const char* const cstr = OS::SCreate(zone, "%s%s", before_error, error);
    SExpParser parser(zone, cstr, strlen(cstr));
    SExpression* const sexp = parser.Parse();
    const char* const expected_message =
        SExpParser::ErrorStrings::kBadUnicodeEscape;
    EXPECT_SEXP_PARSE_ERROR(sexp, parser, error_pos, expected_message);
  }
  // Unicode escape with less than four hex digits.
  {
    const char* const before_error = "(def v0 (Constant 3) { foo \"123";
    const intptr_t error_pos = strlen(before_error);
    const char* const error = "\\u12\" })";
    const char* const cstr = OS::SCreate(zone, "%s%s", before_error, error);
    SExpParser parser(zone, cstr, strlen(cstr));
    SExpression* const sexp = parser.Parse();
    const char* const expected_message =
        SExpParser::ErrorStrings::kBadUnicodeEscape;
    EXPECT_SEXP_PARSE_ERROR(sexp, parser, error_pos, expected_message);
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
    const char* const expected_message =
        OS::SCreate(zone, SExpParser::ErrorStrings::kOpenString, string_pos);
    EXPECT_SEXP_PARSE_ERROR(sexp, parser, error_pos, expected_message);
  }
}

}  // namespace dart
