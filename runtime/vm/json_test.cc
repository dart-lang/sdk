// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "platform/json.h"
#include "vm/json_stream.h"
#include "vm/unit_test.h"
#include "vm/dart_api_impl.h"

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
  char buffer[1024];
  ElideJSONSubstring("classes", js.ToCString(), buffer);
  EXPECT_STREQ("[{\"type\":\"@Instance\","
               "\"_vmType\":\"null\","
               "\"class\":{\"type\":\"@Class\",\"fixedId\":true,\"id\":\"\","
               "\"name\":\"Null\"},"
               "\"kind\":\"Null\","
               "\"fixedId\":true,"
               "\"id\":\"objects\\/null\","
               "\"valueAsString\":\"null\"},"
               "{\"object_key\":"
               "{\"type\":\"@Instance\","
               "\"_vmType\":\"null\","
               "\"class\":{\"type\":\"@Class\",\"fixedId\":true,\"id\":\"\","
               "\"name\":\"Null\"},"
               "\"kind\":\"Null\","
               "\"fixedId\":true,"
               "\"id\":\"objects\\/null\","
               "\"valueAsString\":\"null\"}}]",
               buffer);
}

TEST_CASE(JSON_JSONStream_EscapedString) {
  JSONStream js;
  {
    JSONArray jsarr(&js);
    jsarr.AddValue("Hel\"\"lo\r\n\t");
  }
  EXPECT_STREQ("[\"Hel\\\"\\\"lo\\r\\n\\t\"]", js.ToCString());
}


TEST_CASE(JSON_JSONStream_DartString) {
  const char* kScriptChars =
      "var ascii = 'Hello, World!';\n"
      "var unicode = '\\u00CE\\u00F1\\u0163\\u00E9r\\u00F1\\u00E5\\u0163"
      "\\u00EE\\u00F6\\u00F1\\u00E5\\u013C\\u00EE\\u017E\\u00E5\\u0163"
      "\\u00EE\\u1EDD\\u00F1';\n"
      "var surrogates = '\\u{1D11E}\\u{1D11E}\\u{1D11E}\\u{1D11E}"
      "\\u{1D11E}';\n"
      "var nullInMiddle = 'This has\\u0000 four words.';";

  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  EXPECT_VALID(lib);

  Dart_Handle result;
  String& obj = String::Handle();

  {
    result = Dart_GetField(lib, NewString("ascii"));
    EXPECT_VALID(result);
    obj ^= Api::UnwrapHandle(result);

    JSONStream js;
    {
      JSONObject jsobj(&js);
      jsobj.AddPropertyStr("ascci", obj);;
    }
    EXPECT_STREQ("{\"ascci\":\"Hello, World!\"}", js.ToCString());
  }

  {
    result = Dart_GetField(lib, NewString("unicode"));
    EXPECT_VALID(result);
    obj ^= Api::UnwrapHandle(result);

    JSONStream js;
    {
      JSONObject jsobj(&js);
      jsobj.AddPropertyStr("unicode", obj);
    }
    EXPECT_STREQ("{\"unicode\":\"\\u00CE\\u00F1\\u0163\\u00E9r\\u00F1\\u00E5"
                 "\\u0163\\u00EE\\u00F6\\u00F1\\u00E5\\u013C\\u00EE\\u017E"
                 "\\u00E5\\u0163\\u00EE\\u1EDD\\u00F1\"}", js.ToCString());
  }

  {
    result = Dart_GetField(lib, NewString("surrogates"));
    EXPECT_VALID(result);
    obj ^= Api::UnwrapHandle(result);

    JSONStream js;
    {
      JSONObject jsobj(&js);
      jsobj.AddPropertyStr("surrogates", obj);
    }
    EXPECT_STREQ("{\"surrogates\":\"\\uD834\\uDD1E\\uD834\\uDD1E\\uD834\\uDD1E"
                 "\\uD834\\uDD1E\\uD834\\uDD1E\"}", js.ToCString());
  }

  {
    result = Dart_GetField(lib, NewString("nullInMiddle"));
    EXPECT_VALID(result);
    obj ^= Api::UnwrapHandle(result);

    JSONStream js;
    {
      JSONObject jsobj(&js);
      jsobj.AddPropertyStr("nullInMiddle", obj);
    }
    EXPECT_STREQ("{\"nullInMiddle\":\"This has\\u0000 four words.\"}",
                 js.ToCString());
  }
}


TEST_CASE(JSON_JSONStream_Params) {
  const char* param_keys[] = {"dog", "cat"};
  const char* param_values[] = {"apple", "banana"};

  JSONStream js;
  EXPECT(js.num_params() == 0);
  js.SetParams(&param_keys[0], &param_values[0], 2);
  EXPECT(js.num_params() == 2);
  EXPECT(!js.HasParam("lizard"));
  EXPECT(js.HasParam("dog"));
  EXPECT(js.HasParam("cat"));
  EXPECT(js.ParamIs("cat", "banana"));
  EXPECT(!js.ParamIs("dog", "banana"));
}

}  // namespace dart
