// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "platform/json.h"
#include "vm/json_stream.h"
#include "vm/unit_test.h"

namespace dart {


TEST_CASE(JSON_ScanJSON) {
  const char* msg = "{ \"id\": 5, \"command\" : \"Debugger.pause\" }";

  JSONScanner scanner(msg);
  EXPECT_EQ(scanner.CurrentToken(), JSONScanner::TokenIllegal);
  scanner.Scan();
  EXPECT_EQ(scanner.CurrentToken(), JSONScanner::TokenLBrace);
  scanner.Scan();
  EXPECT_EQ(scanner.CurrentToken(), JSONScanner::TokenString);
  EXPECT(scanner.IsStringLiteral("id"));
  scanner.Scan();
  EXPECT_EQ(scanner.CurrentToken(), JSONScanner::TokenColon);
  scanner.Scan();
  EXPECT_EQ(scanner.CurrentToken(), JSONScanner::TokenInteger);
  scanner.Scan();
  EXPECT_EQ(scanner.CurrentToken(), JSONScanner::TokenComma);
  scanner.Scan();
  EXPECT_EQ(scanner.CurrentToken(), JSONScanner::TokenString);
  EXPECT(scanner.IsStringLiteral("command"));
  scanner.Scan();
  EXPECT_EQ(scanner.CurrentToken(), JSONScanner::TokenColon);
  scanner.Scan();
  EXPECT_EQ(scanner.CurrentToken(), JSONScanner::TokenString);
  EXPECT(scanner.IsStringLiteral("Debugger.pause"));
  scanner.Scan();
  EXPECT_EQ(scanner.CurrentToken(), JSONScanner::TokenRBrace);
  scanner.Scan();
  EXPECT_EQ(scanner.CurrentToken(), JSONScanner::TokenEOM);
}


TEST_CASE(JSON_SyntaxError) {
    const char* jobj = "{ \"id\": 5, "
                     "  \"command\" : \"Debugger.stop\""  // Missing comma.
                     "  \"params\" : { "
                     "    \"url\" : \"blah.dart\", "  // Missing comma.
                     "    \"line\": 111, "
                     "  },"
                     "  \"foo\": \"outer foo\", "
                     "}";
  JSONReader reader(jobj);
  bool found;

  found = reader.Seek("id");
  EXPECT(found);
  EXPECT_EQ(reader.Type(), JSONReader::kInteger);
  found = reader.Seek("params");
  EXPECT(!found);
  EXPECT(reader.Error());
  EXPECT_EQ(reader.Type(), JSONReader::kNone);
  EXPECT_EQ(0, reader.ValueLen());
  EXPECT(reader.ValueChars() == NULL);
}


TEST_CASE(JSON_JSONReader) {
  const char* jobj = "{ \"id\": 5, "
                     "  \"command\" : \"Debugger.setBreakpoint\","
                     "  \"params\" : { "
                     "    \"url\" : \"blah.dart\", "
                     "    \"foo\" : [null, 1, { }, \"bar\", true, false],"
                     "    \"line\": 111, "
                     "  },"
                     "  \"foo\": \"outer foo\", "
                     "}";

  JSONReader reader(jobj);
  bool found;

  found = reader.Seek("id");
  EXPECT(found);
  EXPECT_EQ(reader.Type(), JSONReader::kInteger);
  found = reader.Seek("foo");
  EXPECT(found);
  EXPECT_EQ(reader.Type(), JSONReader::kString);
  EXPECT(reader.IsStringLiteral("outer foo"));
  found = reader.Seek("line");
  EXPECT(!found);
  found = reader.Seek("params");
  EXPECT(found);
  EXPECT_EQ(reader.Type(), JSONReader::kObject);
  reader.Set(reader.ValueChars());
  found = reader.Seek("foo");
  EXPECT(found);
  EXPECT_EQ(reader.Type(), JSONReader::kArray);
  found = reader.Seek("non-existing");
  EXPECT(!found);
  found = reader.Seek("line");
  EXPECT(found);
  EXPECT_EQ(reader.Type(), JSONReader::kInteger);
}


TEST_CASE(JSON_TextBuffer) {
  TextBuffer w(5);  // Small enough to make buffer grow at least once.
  w.Printf("{ \"%s\" : %d", "length", 175);
  EXPECT_STREQ("{ \"length\" : 175", w.buf());
  w.Printf(", \"%s\" : \"%s\" }", "command", "stopIt");
  EXPECT_STREQ("{ \"length\" : 175, \"command\" : \"stopIt\" }", w.buf());

  JSONReader r(w.buf());
  bool found = r.Seek("command");
  EXPECT(found);
  EXPECT_EQ(r.Type(), JSONReader::kString);
  EXPECT(r.IsStringLiteral("stopIt"));
}


TEST_CASE(JSON_JSONStream_Primitives) {
  TextBuffer tb(256);
  JSONStream js(&tb);

  js.OpenObject();
  js.CloseObject();

  EXPECT_STREQ("{}", tb.buf());

  js.Clear();
  js.OpenArray();
  js.CloseArray();
  EXPECT_STREQ("[]", tb.buf());

  js.Clear();
  js.PrintValueBool(true);
  EXPECT_STREQ("true", tb.buf());

  js.Clear();
  js.PrintValueBool(false);
  EXPECT_STREQ("false", tb.buf());

  js.Clear();
  js.PrintValue(static_cast<intptr_t>(4));
  EXPECT_STREQ("4", tb.buf());

  js.Clear();
  js.PrintValue(1.0);
  EXPECT_STREQ("1.000000", tb.buf());

  js.Clear();
  js.PrintValue("hello");
  EXPECT_STREQ("\"hello\"", tb.buf());
}


TEST_CASE(JSON_JSONStream_Array) {
  TextBuffer tb(256);
  JSONStream js(&tb);
  js.Clear();
  js.OpenArray();
  js.PrintValueBool(true);
  js.PrintValueBool(false);
  js.CloseArray();
  EXPECT_STREQ("[true,false]", tb.buf());
}


TEST_CASE(JSON_JSONStream_Object) {
  TextBuffer tb(256);
  JSONStream js(&tb);
  js.Clear();
  js.OpenObject();
  js.PrintProperty("key1", "a");
  js.PrintProperty("key2", "b");
  js.CloseObject();
  EXPECT_STREQ("{\"key1\":\"a\",\"key2\":\"b\"}", tb.buf());
}

TEST_CASE(JSON_JSONStream_NestedObject) {
  TextBuffer tb(256);
  JSONStream js(&tb);
  js.OpenObject();
  js.OpenObject("key");
  js.PrintProperty("key1", "d");
  js.CloseObject();
  js.CloseObject();
  EXPECT_STREQ("{\"key\":{\"key1\":\"d\"}}", tb.buf());
}


TEST_CASE(JSON_JSONStream_ObjectArray) {
  TextBuffer tb(256);
  JSONStream js(&tb);
  js.OpenArray();
  js.OpenObject();
  js.PrintProperty("key", "e");
  js.CloseObject();
  js.OpenObject();
  js.PrintProperty("yek", "f");
  js.CloseObject();
  js.CloseArray();
  EXPECT_STREQ("[{\"key\":\"e\"},{\"yek\":\"f\"}]", tb.buf());
}


TEST_CASE(JSON_JSONStream_ArrayArray) {
  TextBuffer tb(256);
  JSONStream js(&tb);
  js.OpenArray();
  js.OpenArray();
  js.PrintValue((intptr_t)4);
  js.CloseArray();
  js.OpenArray();
  js.PrintValueBool(false);
  js.CloseArray();
  js.CloseArray();
  EXPECT_STREQ("[[4],[false]]", tb.buf());
}


TEST_CASE(JSON_JSONStream_Printf) {
  TextBuffer tb(256);
  JSONStream js(&tb);
  js.OpenArray();
  js.PrintfValue("%d %s", 2, "hello");
  js.CloseArray();
  EXPECT_STREQ("[\"2 hello\"]", tb.buf());
}


TEST_CASE(JSON_JSONStream_ObjectPrintf) {
  TextBuffer tb(256);
  JSONStream js(&tb);
  js.OpenObject();
  js.PrintfProperty("key", "%d %s", 2, "hello");
  js.CloseObject();
  EXPECT_STREQ("{\"key\":\"2 hello\"}", tb.buf());
}


TEST_CASE(JSON_JSONStream_DartObject) {
  TextBuffer tb(256);
  JSONStream js(&tb);
  js.OpenArray();
  js.PrintValue(Object::Handle(Object::null()));
  js.OpenObject();
  js.PrintProperty("object_key", Object::Handle(Object::null()));
  js.CloseArray();
  EXPECT_STREQ("[{\"type\":\"null\"},{\"object_key\":{\"type\":\"null\"}]",
               tb.buf());
}

TEST_CASE(JSON_JSONStream_EscapedString) {
  TextBuffer tb(256);
  JSONStream js(&tb);
  js.PrintValue("Hel\"\"lo\r\n\t");
  EXPECT_STREQ("\"Hel\\\"\\\"lo\\r\\n\\t\"", tb.buf());
}


}  // namespace dart
