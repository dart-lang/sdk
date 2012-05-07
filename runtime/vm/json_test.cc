// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "platform/json.h"
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

}  // namespace dart
