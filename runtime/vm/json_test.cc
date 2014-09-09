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
                     "  \"foo\": \"outer foo\",     "
                     "  \"quote\": \"\\\"\",        "
                     "  \"white\": \"\\t \\n\",     "
                     "}";

  JSONReader reader(jobj);
  bool found;
  char s[128];

  found = reader.Seek("id");
  EXPECT(found);
  EXPECT_EQ(reader.Type(), JSONReader::kInteger);
  found = reader.Seek("foo");
  EXPECT(found);
  EXPECT_EQ(reader.Type(), JSONReader::kString);
  EXPECT(reader.IsStringLiteral("outer foo"));

  found = reader.Seek("quote");
  EXPECT(found);
  EXPECT_EQ(reader.Type(), JSONReader::kString);
  reader.GetRawValueChars(s, sizeof s);
  EXPECT_STREQ("\\\"", s);
  reader.GetDecodedValueChars(s, sizeof s);
  EXPECT_STREQ("\"", s);

  found = reader.Seek("white");
  EXPECT(found);
  EXPECT_EQ(reader.Type(), JSONReader::kString);
  reader.GetRawValueChars(s, sizeof s);
  EXPECT_STREQ("\\t \\n", s);
  reader.GetDecodedValueChars(s, sizeof s);
  EXPECT_STREQ("\t \n", s);

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
  {
    JSONStream js;
    {
      JSONObject jsobj(&js);
    }
    EXPECT_STREQ("{}", js.ToCString());
  }
  {
    JSONStream js;
    {
      JSONArray jsarr(&js);
    }
    EXPECT_STREQ("[]", js.ToCString());
  }
  {
    JSONStream js;
    {
      JSONArray jsarr(&js);
      jsarr.AddValue(true);
    }
    EXPECT_STREQ("[true]", js.ToCString());
  }
  {
    JSONStream js;
    {
      JSONArray jsarr(&js);
      jsarr.AddValue(false);
    }
    EXPECT_STREQ("[false]", js.ToCString());
  }
  {
    JSONStream js;
    {
      JSONArray jsarr(&js);
      jsarr.AddValue(static_cast<intptr_t>(4));
    }
    EXPECT_STREQ("[4]", js.ToCString());
  }
  {
    JSONStream js;
    {
      JSONArray jsarr(&js);
      jsarr.AddValue(1.0);
    }
    EXPECT_STREQ("[1.000000]", js.ToCString());
  }
  {
    JSONStream js;
    {
      JSONArray jsarr(&js);
      jsarr.AddValue("hello");
    }
    EXPECT_STREQ("[\"hello\"]", js.ToCString());
  }
  {
    JSONStream js;
    {
      JSONArray jsarr(&js);
      jsarr.AddValueF("h%s", "elo");
    }
    EXPECT_STREQ("[\"helo\"]", js.ToCString());
  }
}


TEST_CASE(JSON_JSONStream_Array) {
  JSONStream js;
  {
    JSONArray jsarr(&js);
    jsarr.AddValue(true);
    jsarr.AddValue(false);
  }
  EXPECT_STREQ("[true,false]", js.ToCString());
}


TEST_CASE(JSON_JSONStream_Object) {
  JSONStream js;
  {
    JSONObject jsobj(&js);
    jsobj.AddProperty("key1", "a");
    jsobj.AddProperty("key2", "b");
  }
  EXPECT_STREQ("{\"key1\":\"a\",\"key2\":\"b\"}", js.ToCString());
}

TEST_CASE(JSON_JSONStream_NestedObject) {
  JSONStream js;
  {
    JSONObject jsobj(&js);
    JSONObject jsobj1(&jsobj, "key");
    jsobj1.AddProperty("key1", "d");
  }
  EXPECT_STREQ("{\"key\":{\"key1\":\"d\"}}", js.ToCString());
}


TEST_CASE(JSON_JSONStream_ObjectArray) {
  JSONStream js;
  {
    JSONArray jsarr(&js);
    {
      JSONObject jsobj(&jsarr);
      jsobj.AddProperty("key", "e");
    }
    {
      JSONObject jsobj(&jsarr);
      jsobj.AddProperty("yek", "f");
    }
  }
  EXPECT_STREQ("[{\"key\":\"e\"},{\"yek\":\"f\"}]", js.ToCString());
}


TEST_CASE(JSON_JSONStream_ArrayArray) {
  JSONStream js;
  {
    JSONArray jsarr(&js);
    {
      JSONArray jsarr1(&jsarr);
      jsarr1.AddValue(static_cast<intptr_t>(4));
    }
    {
      JSONArray jsarr1(&jsarr);
      jsarr1.AddValue(false);
    }
  }
  EXPECT_STREQ("[[4],[false]]", js.ToCString());
}


TEST_CASE(JSON_JSONStream_Printf) {
  JSONStream js;
  {
    JSONArray jsarr(&js);
    jsarr.AddValueF("%d %s", 2, "hello");
  }
  EXPECT_STREQ("[\"2 hello\"]", js.ToCString());
}


TEST_CASE(JSON_JSONStream_ObjectPrintf) {
  JSONStream js;
  {
    JSONObject jsobj(&js);
    jsobj.AddPropertyF("key", "%d %s", 2, "hello");
  }
  EXPECT_STREQ("{\"key\":\"2 hello\"}", js.ToCString());
}


TEST_CASE(JSON_JSONStream_DartObject) {
  JSONStream js;
  {
    JSONArray jsarr(&js);
    jsarr.AddValue(Object::Handle(Object::null()));
    JSONObject jsobj(&jsarr);
    jsobj.AddProperty("object_key", Object::Handle(Object::null()));
  }
  EXPECT_STREQ("[{\"type\":\"@null\",\"id\":\"objects\\/null\","
               "\"valueAsString\":\"null\"},"
               "{\"object_key\":{\"type\":\"@null\",\"id\":\"objects\\/null\","
               "\"valueAsString\":\"null\"}}]",
               js.ToCString());
}

TEST_CASE(JSON_JSONStream_EscapedString) {
  JSONStream js;
  {
    JSONArray jsarr(&js);
    jsarr.AddValue("Hel\"\"lo\r\n\t");
  }
  EXPECT_STREQ("[\"Hel\\\"\\\"lo\\r\\n\\t\"]", js.ToCString());
}


TEST_CASE(JSON_JSONStream_Options) {
  const char* arguments[] = {"a", "b", "c"};
  const char* option_keys[] = {"dog", "cat"};
  const char* option_values[] = {"apple", "banana"};

  JSONStream js;
  EXPECT(js.num_arguments() == 0);
  js.SetArguments(&arguments[0], 3);
  EXPECT(js.num_arguments() == 3);
  EXPECT_STREQ("a", js.command());

  EXPECT(js.num_options() == 0);
  js.SetOptions(&option_keys[0], &option_values[0], 3);
  EXPECT(js.num_options() == 3);
  EXPECT(!js.HasOption("lizard"));
  EXPECT(js.HasOption("dog"));
  EXPECT(js.HasOption("cat"));
  EXPECT(js.OptionIs("cat", "banana"));
  EXPECT(!js.OptionIs("dog", "banana"));
}

}  // namespace dart
