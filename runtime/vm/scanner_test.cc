// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/scanner.h"
#include "platform/assert.h"
#include "vm/os.h"
#include "vm/token.h"
#include "vm/unit_test.h"

namespace dart {

typedef ZoneGrowableArray<Scanner::TokenDescriptor> GrowableTokenStream;

static void LogTokenDesc(Scanner::TokenDescriptor token) {
  OS::Print("pos %2d:%d-%d token %s  ", token.position.line,
            token.position.column, token.position.column,
            Token::Name(token.kind));
  if (token.literal != NULL) {
    OS::Print("%s", token.literal->ToCString());
  }
  OS::Print("\n");
}

static void LogTokenStream(const GrowableTokenStream& token_stream) {
  int token_index = 0;
  EXPECT_GT(token_stream.length(), 0);
  while (token_index < token_stream.length()) {
    LogTokenDesc(token_stream[token_index]);
    ASSERT(token_stream[token_index].kind != Token::kILLEGAL);
    token_index++;
  }
  printf("%d tokens in stream.\n", token_index);
  EXPECT_EQ(token_stream.Last().kind, Token::kEOS);
}

static void CheckKind(const GrowableTokenStream& token_stream,
                      int index,
                      Token::Kind kind) {
  if (token_stream[index].kind != kind) {
    OS::PrintErr("Token %d: expected kind %s but got %s\n", index,
                 Token::Name(kind), Token::Name(token_stream[index].kind));
  }
  EXPECT_EQ(kind, token_stream[index].kind);
}

static void CheckLiteral(const GrowableTokenStream& token_stream,
                         int index,
                         const char* literal) {
  if (token_stream[index].literal == NULL) {
    OS::PrintErr("Token %d: expected literal \"%s\" but got nothing\n", index,
                 literal);
  } else if (strcmp(literal, token_stream[index].literal->ToCString())) {
    OS::PrintErr("Token %d: expected literal \"%s\" but got \"%s\"\n", index,
                 literal, token_stream[index].literal->ToCString());
  }
}

static void CheckIdent(const GrowableTokenStream& token_stream,
                       int index,
                       const char* literal) {
  CheckKind(token_stream, index, Token::kIDENT);
  CheckLiteral(token_stream, index, literal);
}

static void CheckInteger(const GrowableTokenStream& token_stream,
                         int index,
                         const char* literal) {
  CheckKind(token_stream, index, Token::kINTEGER);
  CheckLiteral(token_stream, index, literal);
}

static void CheckLineNumber(const GrowableTokenStream& token_stream,
                            int index,
                            int line_number) {
  if (token_stream[index].position.line != line_number) {
    OS::PrintErr("Token %d: expected line number %d but got %d\n", index,
                 line_number, token_stream[index].position.line);
  }
}

static void CheckNumTokens(const GrowableTokenStream& token_stream, int index) {
  if (token_stream.length() != index) {
    OS::PrintErr("Expected %d tokens but got only %" Pd ".\n", index,
                 token_stream.length());
  }
}

class Collector : public Scanner::TokenCollector {
 public:
  explicit Collector(GrowableTokenStream* ts) : ts_(ts) {}
  virtual ~Collector() {}

  virtual void AddToken(const Scanner::TokenDescriptor& token) {
    ts_->Add(token);
  }

 private:
  GrowableTokenStream* ts_;
};

static const GrowableTokenStream& Scan(const char* source) {
  OS::Print("\nScanning: <%s>\n", source);

  Scanner scanner(String::Handle(String::New(source)),
                  String::Handle(String::New("")));
  GrowableTokenStream* tokens = new GrowableTokenStream(128);
  Collector collector(tokens);

  scanner.ScanAll(&collector);
  LogTokenStream(*tokens);
  return *tokens;
}

static void BoringTest() {
  const GrowableTokenStream& tokens = Scan("x = iffy++;");

  CheckNumTokens(tokens, 6);
  CheckIdent(tokens, 0, "x");
  CheckKind(tokens, 1, Token::kASSIGN);
  CheckIdent(tokens, 2, "iffy");
  CheckKind(tokens, 3, Token::kINCR);
  CheckKind(tokens, 4, Token::kSEMICOLON);
}

static void CommentTest() {
  const GrowableTokenStream& tokens = Scan(
      "Foo( /*block \n"
      "comment*/ 0xff) // line comment;");

  CheckNumTokens(tokens, 6);
  CheckIdent(tokens, 0, "Foo");
  CheckLineNumber(tokens, 0, 1);
  CheckKind(tokens, 1, Token::kLPAREN);
  CheckKind(tokens, 2, Token::kNEWLINE);
  CheckInteger(tokens, 3, "0xff");
  CheckKind(tokens, 4, Token::kRPAREN);
  CheckLineNumber(tokens, 4, 2);
}

static void GreedIsGood() {
  // means i++ + j
  const GrowableTokenStream& tokens = Scan("x=i+++j");

  CheckNumTokens(tokens, 7);
  CheckIdent(tokens, 0, "x");
  CheckKind(tokens, 1, Token::kASSIGN);
  CheckIdent(tokens, 2, "i");
  CheckKind(tokens, 3, Token::kINCR);
  CheckKind(tokens, 4, Token::kADD);
  CheckIdent(tokens, 5, "j");
}

static void StringEscapes() {
  // sss = "\" \\ \n\r\t \'"
  const GrowableTokenStream& tokens =
      Scan("sss = \"\\\" \\\\ \\n\\r\\t \\\'\"");

  EXPECT_EQ(4, tokens.length());
  CheckIdent(tokens, 0, "sss");
  CheckKind(tokens, 1, Token::kASSIGN);
  CheckKind(tokens, 2, Token::kSTRING);
  CheckKind(tokens, 3, Token::kEOS);
  CheckLineNumber(tokens, 2, 1);
  const char* litchars = (tokens)[2].literal->ToCString();
  EXPECT_EQ(9, (tokens)[2].literal->Length());

  EXPECT_EQ('"', litchars[0]);
  EXPECT_EQ(' ', litchars[1]);
  EXPECT_EQ('\\', litchars[2]);
  EXPECT_EQ('\n', litchars[4]);
  EXPECT_EQ('\r', litchars[5]);
  EXPECT_EQ('\t', litchars[6]);
  EXPECT_EQ('\'', litchars[8]);
}

static void InvalidStringEscapes() {
  const GrowableTokenStream& out_of_range_low = Scan("\"\\u{110000}\"");
  EXPECT_EQ(2, out_of_range_low.length());
  CheckKind(out_of_range_low, 0, Token::kERROR);
  EXPECT(out_of_range_low[0].literal->Equals("invalid code point"));
  CheckKind(out_of_range_low, 1, Token::kEOS);

  const GrowableTokenStream& out_of_range_high = Scan("\"\\u{FFFFFF}\"");
  EXPECT_EQ(2, out_of_range_high.length());
  CheckKind(out_of_range_high, 0, Token::kERROR);
  EXPECT(out_of_range_high[0].literal->Equals("invalid code point"));
  CheckKind(out_of_range_high, 1, Token::kEOS);
}

static void RawString() {
  // rs = @"\' \\"
  const GrowableTokenStream& tokens = Scan("rs = r\"\\\' \\\\\"");

  EXPECT_EQ(4, tokens.length());
  CheckIdent(tokens, 0, "rs");
  CheckKind(tokens, 1, Token::kASSIGN);
  CheckKind(tokens, 2, Token::kSTRING);
  CheckKind(tokens, 3, Token::kEOS);
  CheckLineNumber(tokens, 2, 1);
  const char* litchars = (tokens)[2].literal->ToCString();
  EXPECT_EQ(5, (tokens)[2].literal->Length());

  EXPECT_EQ('\\', litchars[0]);
  EXPECT_EQ('\'', litchars[1]);
  EXPECT_EQ(' ', litchars[2]);
  EXPECT_EQ('\\', litchars[3]);
  EXPECT_EQ('\\', litchars[4]);
}

static void MultilineString() {
  // |mls = '''
  // |1' x
  // |2''';
  const GrowableTokenStream& tokens = Scan("mls = '''\n1' x\n2''';");

  EXPECT_EQ(7, tokens.length());
  CheckIdent(tokens, 0, "mls");
  CheckKind(tokens, 1, Token::kASSIGN);
  CheckKind(tokens, 2, Token::kSTRING);
  CheckKind(tokens, 3, Token::kNEWLINE);
  CheckKind(tokens, 4, Token::kNEWLINE);
  CheckKind(tokens, 5, Token::kSEMICOLON);
  CheckKind(tokens, 6, Token::kEOS);
  CheckLineNumber(tokens, 0, 1);
  CheckLineNumber(tokens, 5, 3);  // Semicolon is on line 3.
  const char* litchars = (tokens)[2].literal->ToCString();
  EXPECT_EQ(6, (tokens)[2].literal->Length());

  EXPECT_EQ('1', litchars[0]);  // First newline is dropped.
  EXPECT_EQ('\'', litchars[1]);
  EXPECT_EQ(' ', litchars[2]);
  EXPECT_EQ('x', litchars[3]);
  EXPECT_EQ('\n', litchars[4]);
  EXPECT_EQ('2', litchars[5]);
}

static void EmptyString() {
  // es = "";
  const GrowableTokenStream& tokens = Scan("es = \"\";");

  EXPECT_EQ(5, tokens.length());
  CheckIdent(tokens, 0, "es");
  CheckKind(tokens, 1, Token::kASSIGN);
  CheckKind(tokens, 2, Token::kSTRING);
  CheckKind(tokens, 3, Token::kSEMICOLON);
  CheckKind(tokens, 4, Token::kEOS);
  EXPECT_EQ(0, (tokens)[2].literal->Length());
}

static void EmptyMultilineString() {
  // es = """""";
  const GrowableTokenStream& tokens = Scan("es = \"\"\"\"\"\";");

  EXPECT_EQ(5, tokens.length());
  CheckIdent(tokens, 0, "es");
  CheckKind(tokens, 1, Token::kASSIGN);
  CheckKind(tokens, 2, Token::kSTRING);
  CheckKind(tokens, 3, Token::kSEMICOLON);
  CheckKind(tokens, 4, Token::kEOS);
  EXPECT_EQ(0, (tokens)[2].literal->Length());
}

static void NumberLiteral() {
  const GrowableTokenStream& tokens = Scan("5 0x5d 0.3 0.33 1E+12 .42 +5");

  CheckKind(tokens, 0, Token::kINTEGER);
  CheckKind(tokens, 1, Token::kINTEGER);
  CheckKind(tokens, 2, Token::kDOUBLE);
  CheckKind(tokens, 3, Token::kDOUBLE);
  CheckKind(tokens, 4, Token::kDOUBLE);
  CheckKind(tokens, 5, Token::kDOUBLE);
  CheckKind(tokens, 6, Token::kADD);
  CheckKind(tokens, 7, Token::kINTEGER);
  CheckKind(tokens, 8, Token::kEOS);
}

static void ScanLargeText() {
  const char* dart_source =
      "// This source is not meant to be valid Dart code. The text is used to"
      "// test the Dart scanner."
      ""
      "// Cartesian point implementation."
      "class Point {"
      ""
      "  // Constructor"
      "  Point(Number x, Number y) : x(x), y(y) { }"
      ""
      "  // Addition for points."
      "  Point operator +(Point other) {"
      "    return new Point(x + other.x, y + other.y);"
      "  }"
      ""
      "  // Fields are const and they cannot be changed."
      "  const Number x;"
      "  const Number y;"
      "}"
      ""
      ""
      "// Polar point class that implements the Point interface."
      "class PolarPoint implements Point {"
      ""
      "  PolarPoint(Number theta, Number radius)"
      "      : theta(theta), radius(radius) { }"
      ""
      "  Number get x { return radius * Math.cos(theta); }"
      "  Number get y { return radius * Math.sin(theta); }"
      ""
      "  const Number theta;"
      "  const Number radius;"
      "}"
      ""
      "interface Map<K ,V> default HashMap<K, V> {"
      "  V operator [](K key);"
      "  void operator []=(K key, V value);"
      "  void forEach(function f(K key, V value));"
      "}"
      ""
      "class Foo {"
      "  static const Array kMyArray = [1,2,3,4,5,6];"
      "  static const Point kMyPoint = Point(1,2);"
      "}"
      ""
      "class DequeEntry<T> implements QueueEntry<T>{"
      "  DequeEntry<T> next;"
      "  DequeEntry<T> previous;"
      "  T value;"
      "}"
      ""
      "void forEach(void function f(T element)) {"
      "  for (int i = 0; i < this.length; i++) {"
      "    f(this[i]);"
      "  }"
      "}"
      ""
      ""
      "j!==!iffy  // means j !== !iffy";
  Scan(dart_source);
}

void InvalidText() {
  const GrowableTokenStream& tokens = Scan("\\");

  EXPECT_EQ(2, tokens.length());
  CheckKind(tokens, 0, Token::kERROR);
  CheckKind(tokens, 1, Token::kEOS);
}

void NewlinesTest() {
  const char* source =
      "var es = /* a\n"
      "            b\n"
      "          */ \"\"\"\n"
      "c\n"
      "d\n"
      "\"\"\";";

  const GrowableTokenStream& tokens = Scan(source);

  EXPECT_EQ(11, tokens.length());
  CheckKind(tokens, 0, Token::kVAR);
  CheckIdent(tokens, 1, "es");
  CheckKind(tokens, 2, Token::kASSIGN);
  CheckKind(tokens, 3, Token::kNEWLINE);
  CheckKind(tokens, 4, Token::kNEWLINE);
  CheckKind(tokens, 5, Token::kSTRING);
  CheckKind(tokens, 6, Token::kNEWLINE);
  CheckKind(tokens, 7, Token::kNEWLINE);
  CheckKind(tokens, 8, Token::kNEWLINE);
  CheckKind(tokens, 9, Token::kSEMICOLON);
  CheckKind(tokens, 10, Token::kEOS);

  EXPECT_EQ(4, (tokens)[5].literal->Length());
  const char* litchars = (tokens)[5].literal->ToCString();
  EXPECT_EQ('c', litchars[0]);  // First newline is dropped.
  EXPECT_EQ('\n', litchars[1]);
  EXPECT_EQ('d', litchars[2]);
  EXPECT_EQ('\n', litchars[3]);
}

TEST_CASE(Scanner_Test) {
  ScanLargeText();

  BoringTest();
  CommentTest();
  GreedIsGood();
  StringEscapes();
  InvalidStringEscapes();
  RawString();
  MultilineString();
  EmptyString();
  EmptyMultilineString();
  NumberLiteral();
  InvalidText();
  NewlinesTest();
}

}  // namespace dart
