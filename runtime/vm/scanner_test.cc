// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "vm/os.h"
#include "vm/scanner.h"
#include "vm/token.h"
#include "vm/unit_test.h"

namespace dart {

void LogTokenDesc(Scanner::TokenDescriptor token) {
  OS::Print("pos %2d:%d-%d token %s  ",
            token.position.line, token.position.column,
            token.position.column + token.length,
            Token::Name(token.kind));
  if (token.literal != NULL) {
    OS::Print("%s", token.literal->ToCString());
  }
  OS::Print("\n");
}


void LogTokenStream(const Scanner::GrowableTokenStream& token_stream) {
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


void CheckKind(const Scanner::GrowableTokenStream &token_stream,
               int index,
               Token::Kind kind) {
  if (token_stream[index].kind != kind) {
    OS::PrintErr("Token %d: expected kind %s but got %s\n", index,
        Token::Name(kind), Token::Name(token_stream[index].kind));
  }
  EXPECT_EQ(kind, token_stream[index].kind);
}


void CheckLiteral(const Scanner::GrowableTokenStream& token_stream,
                 int index,
                 const char* literal) {
  if (token_stream[index].literal == NULL) {
    OS::PrintErr("Token %d: expected literal \"%s\" but got nothing\n",
                 index, literal);
  } else if (strcmp(literal, token_stream[index].literal->ToCString())) {
    OS::PrintErr("Token %d: expected literal \"%s\" but got \"%s\"\n",
                 index, literal, token_stream[index].literal->ToCString());
  }
}


void CheckIdent(const Scanner::GrowableTokenStream& token_stream,
               int index,
               const char* literal) {
  CheckKind(token_stream, index, Token::kIDENT);
  CheckLiteral(token_stream, index, literal);
}


void CheckInteger(const Scanner::GrowableTokenStream& token_stream,
                 int index,
                 const char* literal) {
  CheckKind(token_stream, index, Token::kINTEGER);
  CheckLiteral(token_stream, index, literal);
}


void CheckLineNumber(const Scanner::GrowableTokenStream& token_stream,
                     int index,
                     int line_number) {
  if (token_stream[index].position.line != line_number) {
    OS::PrintErr("Token %d: expected line number %d but got %d\n",
        index, line_number, token_stream[index].position.line);
  }
}


void CheckNumTokens(const Scanner::GrowableTokenStream& token_stream,
                    int index) {
  if (token_stream.length() != index) {
    OS::PrintErr("Expected %d tokens but got only %d.\n",
        index, token_stream.length());
  }
}


const Scanner::GrowableTokenStream& Scan(const char* source) {
  Scanner scanner(String::Handle(String::New(source)),
                  String::Handle(String::New("")));

  OS::Print("\nScanning: <%s>\n", source);
  const Scanner::GrowableTokenStream& tokens = scanner.GetStream();
  LogTokenStream(tokens);
  return tokens;
}


void BoringTest() {
  const Scanner::GrowableTokenStream& tokens = Scan("x = iffy++;");

  CheckNumTokens(tokens, 6);
  CheckIdent(tokens, 0, "x");
  CheckKind(tokens, 1, Token::kASSIGN);
  CheckIdent(tokens, 2, "iffy");
  CheckKind(tokens, 3, Token::kINCR);
  CheckKind(tokens, 4, Token::kSEMICOLON);
}


void CommentTest() {
  const Scanner::GrowableTokenStream& tokens =
      Scan("Foo( /*block \n"
           "comment*/ 0xff) // line comment;");

  CheckNumTokens(tokens, 5);
  CheckIdent(tokens, 0, "Foo");
  CheckLineNumber(tokens, 0, 1);
  CheckKind(tokens, 1, Token::kLPAREN);
  CheckInteger(tokens, 2, "0xff");
  CheckKind(tokens, 3, Token::kRPAREN);
  CheckLineNumber(tokens, 3, 2);
}


void GreedIsGood() {
  // means i++ + j
  const Scanner::GrowableTokenStream& tokens = Scan("x=i+++j");

  CheckNumTokens(tokens, 7);
  CheckIdent(tokens, 0, "x");
  CheckKind(tokens, 1, Token::kASSIGN);
  CheckIdent(tokens, 2, "i");
  CheckKind(tokens, 3, Token::kINCR);
  CheckKind(tokens, 4, Token::kADD);
  CheckIdent(tokens, 5, "j");
}


void StringEscapes() {
  // sss = "\" \\ \n\r\t \'"
  const Scanner::GrowableTokenStream& tokens =
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


void InvalidStringEscapes() {
  const Scanner::GrowableTokenStream& high_start_4 =
      Scan("\"\\uD800\"");
  EXPECT_EQ(2, high_start_4.length());
  CheckKind(high_start_4, 0, Token::kERROR);
  EXPECT(high_start_4[0].literal->Equals("invalid code point"));
  CheckKind(high_start_4, 1, Token::kEOS);

  const Scanner::GrowableTokenStream& high_start_seq =
      Scan("\"\\u{D800}\"");
  EXPECT_EQ(2, high_start_seq.length());
  CheckKind(high_start_seq, 0, Token::kERROR);
  EXPECT(high_start_seq[0].literal->Equals("invalid code point"));
  CheckKind(high_start_seq, 1, Token::kEOS);

  const Scanner::GrowableTokenStream& high_end_4 =
      Scan("\"\\uDBFF\"");
  EXPECT_EQ(2, high_end_4.length());
  CheckKind(high_end_4, 0, Token::kERROR);
  EXPECT(high_end_4[0].literal->Equals("invalid code point"));
  CheckKind(high_end_4, 1, Token::kEOS);

  const Scanner::GrowableTokenStream& high_end_seq =
      Scan("\"\\u{DBFF}\"");
  EXPECT_EQ(2, high_end_seq.length());
  CheckKind(high_end_seq, 0, Token::kERROR);
  EXPECT(high_end_seq[0].literal->Equals("invalid code point"));
  CheckKind(high_end_seq, 1, Token::kEOS);

  const Scanner::GrowableTokenStream& low_start_4 =
      Scan("\"\\uDC00\"");
  EXPECT_EQ(2, low_start_4.length());
  CheckKind(low_start_4, 0, Token::kERROR);
  EXPECT(low_start_4[0].literal->Equals("invalid code point"));
  CheckKind(low_start_4, 1, Token::kEOS);

  const Scanner::GrowableTokenStream& low_start_seq =
      Scan("\"\\u{DC00}\"");
  EXPECT_EQ(2, low_start_seq.length());
  CheckKind(low_start_seq, 0, Token::kERROR);
  EXPECT(low_start_seq[0].literal->Equals("invalid code point"));
  CheckKind(low_start_seq, 1, Token::kEOS);

  const Scanner::GrowableTokenStream& low_end_4 =
      Scan("\"\\uDFFF\"");
  EXPECT_EQ(2, low_end_4.length());
  CheckKind(low_end_4, 0, Token::kERROR);
  EXPECT(low_end_4[0].literal->Equals("invalid code point"));
  CheckKind(low_end_4, 1, Token::kEOS);

  const Scanner::GrowableTokenStream& low_end_seq =
      Scan("\"\\u{DFFF}\"");
  EXPECT_EQ(2, low_end_seq.length());
  CheckKind(low_end_seq, 0, Token::kERROR);
  EXPECT(low_end_seq[0].literal->Equals("invalid code point"));
  CheckKind(low_end_seq, 1, Token::kEOS);

  const Scanner::GrowableTokenStream& out_of_range_low =
      Scan("\"\\u{110000}\"");
  EXPECT_EQ(2, out_of_range_low.length());
  CheckKind(out_of_range_low, 0, Token::kERROR);
  EXPECT(out_of_range_low[0].literal->Equals("invalid code point"));
  CheckKind(out_of_range_low, 1, Token::kEOS);

  const Scanner::GrowableTokenStream& out_of_range_high =
      Scan("\"\\u{FFFFFF}\"");
  EXPECT_EQ(2, out_of_range_high.length());
  CheckKind(out_of_range_high, 0, Token::kERROR);
  EXPECT(out_of_range_high[0].literal->Equals("invalid code point"));
  CheckKind(out_of_range_high, 1, Token::kEOS);
}


void RawString() {
  // rs = @"\' \\"
  const Scanner::GrowableTokenStream& tokens = Scan("rs = @\"\\\' \\\\\"");

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
  EXPECT_EQ(' ',  litchars[2]);
  EXPECT_EQ('\\', litchars[3]);
  EXPECT_EQ('\\', litchars[4]);
}


void MultilineString() {
  // |mls = '''
  // |1' x
  // |2''';
  const Scanner::GrowableTokenStream& tokens = Scan("mls = '''\n1' x\n2''';");

  EXPECT_EQ(5, tokens.length());
  CheckIdent(tokens, 0, "mls");
  CheckKind(tokens, 1, Token::kASSIGN);
  CheckKind(tokens, 2, Token::kSTRING);
  CheckKind(tokens, 3, Token::kSEMICOLON);
  CheckKind(tokens, 4, Token::kEOS);
  CheckLineNumber(tokens, 0, 1);
  CheckLineNumber(tokens, 4, 3);  // Semicolon is on line 3.
  const char* litchars = (tokens)[2].literal->ToCString();
  EXPECT_EQ(6, (tokens)[2].literal->Length());

  EXPECT_EQ('1',  litchars[0]);  // First newline is dropped.
  EXPECT_EQ('\'', litchars[1]);
  EXPECT_EQ(' ',  litchars[2]);
  EXPECT_EQ('x',  litchars[3]);
  EXPECT_EQ('\n', litchars[4]);
  EXPECT_EQ('2',  litchars[5]);
}


void EmptyString() {
  // es = "";
  const Scanner::GrowableTokenStream& tokens = Scan("es = \"\";");

  EXPECT_EQ(5, tokens.length());
  CheckIdent(tokens, 0, "es");
  CheckKind(tokens, 1, Token::kASSIGN);
  CheckKind(tokens, 2, Token::kSTRING);
  CheckKind(tokens, 3, Token::kSEMICOLON);
  CheckKind(tokens, 4, Token::kEOS);
  EXPECT_EQ(0, (tokens)[2].literal->Length());
}

void EmptyMultilineString() {
  // es = """""";
  const Scanner::GrowableTokenStream& tokens = Scan("es = \"\"\"\"\"\";");

  EXPECT_EQ(5, tokens.length());
  CheckIdent(tokens, 0, "es");
  CheckKind(tokens, 1, Token::kASSIGN);
  CheckKind(tokens, 2, Token::kSTRING);
  CheckKind(tokens, 3, Token::kSEMICOLON);
  CheckKind(tokens, 4, Token::kEOS);
  EXPECT_EQ(0, (tokens)[2].literal->Length());
}


void NumberLiteral() {
  const Scanner::GrowableTokenStream& tokens =
      Scan("5 0x5d 0.3 0.33 1E+12 .42 +5");

  CheckKind(tokens, 0, Token::kINTEGER);
  CheckKind(tokens, 1, Token::kINTEGER);
  CheckKind(tokens, 2, Token::kDOUBLE);
  CheckKind(tokens, 3, Token::kDOUBLE);
  CheckKind(tokens, 4, Token::kDOUBLE);
  CheckKind(tokens, 5, Token::kDOUBLE);
  CheckKind(tokens, 6, Token::kTIGHTADD);
  CheckKind(tokens, 7, Token::kINTEGER);
  CheckKind(tokens, 8, Token::kEOS);
}


void ScanLargeText() {
  const char* dart_source =
      "// This source is not meant to be valid Dart code. The text is used to"
      "// test the Dart scanner."
      ""
      "// Cartesian point implemetation."
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
      "interface Map<K extends Hashable,V> default HashMap<K, V> {"
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
  const Scanner::GrowableTokenStream& tokens =
      Scan("\\");

  EXPECT_EQ(2, tokens.length());
  CheckKind(tokens, 0, Token::kERROR);
  CheckKind(tokens, 1, Token::kEOS);
}


void FindLineTest() {
  const char* source =
      "/*1*/   \n"
      "/*2*/   class A {\n"
      "/*3*/      void foo() { }\n"
      "/*4*/   }\n";

  Scanner scanner(String::Handle(String::New(source)),
                  String::Handle(String::New("")));

  intptr_t first_token_index, last_token_index;
  scanner.TokenRangeAtLine(3, &first_token_index, &last_token_index);
  EXPECT_EQ(3, first_token_index);
  EXPECT_EQ(8, last_token_index);
  scanner.TokenRangeAtLine(100, &first_token_index, &last_token_index);
  EXPECT(first_token_index < 0);
  scanner.TokenRangeAtLine(1, &first_token_index, &last_token_index);
  EXPECT_EQ(0, first_token_index);
  EXPECT(last_token_index < 0);
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
  FindLineTest();
}

}  // namespace dart
