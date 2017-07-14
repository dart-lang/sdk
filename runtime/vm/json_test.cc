// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "platform/text_buffer.h"
#include "vm/dart_api_impl.h"
#include "vm/json_stream.h"
#include "vm/unit_test.h"

namespace dart {

#ifndef PRODUCT

TEST_CASE(JSON_TextBuffer) {
  TextBuffer w(5);  // Small enough to make buffer grow at least once.
  w.Printf("{ \"%s\" : %d", "length", 175);
  EXPECT_STREQ("{ \"length\" : 175", w.buf());
  w.Printf(", \"%s\" : \"%s\" }", "command", "stopIt");
  EXPECT_STREQ("{ \"length\" : 175, \"command\" : \"stopIt\" }", w.buf());
}

TEST_CASE(JSON_JSONStream_Primitives) {
  {
    JSONStream js;
    { JSONObject jsobj(&js); }
    EXPECT_STREQ("{}", js.ToCString());
  }
  {
    JSONStream js;
    { JSONArray jsarr(&js); }
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
  EXPECT_STREQ(
      "[{\"type\":\"@Instance\","
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
      "var surrogates = '\\u{1D11E}\\u{1D11E}\\u{1D11E}"
      "\\u{1D11E}\\u{1D11E}';\n"
      "var wrongEncoding = '\\u{1D11E}' + surrogates[0] + '\\u{1D11E}';"
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
      EXPECT(!jsobj.AddPropertyStr("ascii", obj));
    }
    EXPECT_STREQ("{\"ascii\":\"Hello, World!\"}", js.ToCString());
  }

  {
    result = Dart_GetField(lib, NewString("ascii"));
    EXPECT_VALID(result);
    obj ^= Api::UnwrapHandle(result);

    JSONStream js;
    {
      JSONObject jsobj(&js);
      EXPECT(jsobj.AddPropertyStr("subrange", obj, 1, 4));
    }
    EXPECT_STREQ("{\"subrange\":\"ello\"}", js.ToCString());
  }

  {
    result = Dart_GetField(lib, NewString("unicode"));
    EXPECT_VALID(result);
    obj ^= Api::UnwrapHandle(result);

    JSONStream js;
    {
      JSONObject jsobj(&js);
      EXPECT(!jsobj.AddPropertyStr("unicode", obj));
    }
    EXPECT_STREQ("{\"unicode\":\"Îñţérñåţîöñåļîžåţîờñ\"}", js.ToCString());
  }

  {
    result = Dart_GetField(lib, NewString("surrogates"));
    EXPECT_VALID(result);
    obj ^= Api::UnwrapHandle(result);

    JSONStream js;
    {
      JSONObject jsobj(&js);
      EXPECT(!jsobj.AddPropertyStr("surrogates", obj));
    }
    EXPECT_STREQ("{\"surrogates\":\"𝄞𝄞𝄞𝄞𝄞\"}", js.ToCString());
  }

  {
    result = Dart_GetField(lib, NewString("wrongEncoding"));
    EXPECT_VALID(result);
    obj ^= Api::UnwrapHandle(result);

    JSONStream js;
    {
      JSONObject jsobj(&js);
      EXPECT(!jsobj.AddPropertyStr("wrongEncoding", obj));
    }
    EXPECT_STREQ("{\"wrongEncoding\":\"𝄞\\uD834𝄞\"}", js.ToCString());
  }

  {
    result = Dart_GetField(lib, NewString("nullInMiddle"));
    EXPECT_VALID(result);
    obj ^= Api::UnwrapHandle(result);

    JSONStream js;
    {
      JSONObject jsobj(&js);
      EXPECT(!jsobj.AddPropertyStr("nullInMiddle", obj));
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

TEST_CASE(JSON_JSONStream_AppendJSONStreamConsumer) {
  JSONStream js;

  {
    JSONObject obj(&js);
    {
      JSONArray arr(&obj, "test");
      const char* test_data = "{a, b, c},";
      AppendJSONStreamConsumer(Dart_StreamConsumer_kData, "",
                               reinterpret_cast<const uint8_t*>(&test_data[0]),
                               strlen(test_data), &js);
      AppendJSONStreamConsumer(Dart_StreamConsumer_kData, "",
                               reinterpret_cast<const uint8_t*>(&test_data[0]),
                               strlen(test_data), &js);
      AppendJSONStreamConsumer(Dart_StreamConsumer_kData, "",
                               reinterpret_cast<const uint8_t*>(&test_data[0]),
                               strlen(test_data) - 1, &js);
    }
  }

  EXPECT_STREQ("{\"test\":[{a, b, c},{a, b, c},{a, b, c}]}", js.ToCString());
}

#endif  // !PRODUCT

}  // namespace dart
