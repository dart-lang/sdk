// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:gardening/src/console_table.dart';
import 'package:expect/expect.dart';

void main() {
  testEmpty();
  testHeaderSingle();
  testHeaderSingleRightAlign();
  testHeaderSingleCenter();
  testColumnWrap();
  testColumnWrapAllAlignments();
  testRowWrapAllAlignments();
  testRowWrapAllAlignmentsWithDividers();
  testTruncateAllAlignmentsWithDividers();
}

void testEmpty() {
  var printTable = new ConsoleTable();
  StringBuffer buffer = new StringBuffer();
  printTable.printToSink([], buffer);
  Expect.equals("", buffer.toString());
}

void testHeaderSingle() {
  var printTable = new ConsoleTable()
    ..addHeader(new Column("test 1"), (item) => "");
  StringBuffer buffer = new StringBuffer();
  printTable.printToSink([], buffer);
  String expected =
      "test 1                                                                          \n"
      "--------------------------------------------------------------------------------\n";
  Expect.equals(expected, buffer.toString());
}

void testHeaderSingleRightAlign() {
  var printTable = new ConsoleTable()
    ..addHeader(new Column("test 1", alignment: ALIGNMENT.right), (item) => "");
  StringBuffer buffer = new StringBuffer();
  printTable.printToSink([], buffer);
  String expected =
      "                                                                          test 1\n"
      "--------------------------------------------------------------------------------\n";
  Expect.equals(expected, buffer.toString());
}

void testHeaderSingleCenter() {
  var printTable = new ConsoleTable()
    ..addHeader(
        new Column("test 1", alignment: ALIGNMENT.center), (item) => "");
  StringBuffer buffer = new StringBuffer();
  printTable.printToSink([], buffer);
  String expected =
      "                                     test 1                                     \n"
      "--------------------------------------------------------------------------------\n";
  Expect.equals(expected, buffer.toString());
}

void testColumnWrap() {
  var printTable = new ConsoleTable()
    ..addHeader(
        new Column(
            "This is a very-very-long text_that should fit in a smallersmaller window",
            alignment: ALIGNMENT.left,
            width: 10),
        (item) => "")
    ..addHeader(new Column("this should not wrap", alignment: ALIGNMENT.left),
        (item) => "");
  StringBuffer buffer = new StringBuffer();
  printTable.printToSink([], buffer);

  var expected =
      "This is a                                                                       \n"
      "very-very-                                                                      \n"
      "long                                                                            \n"
      "text_that                                                                       \n"
      "should fit                                                                      \n"
      "in a                                                                            \n"
      "smallersma                                                                      \n"
      "ller                                                                            \n"
      "window     this should not wrap                                                 \n"
      "--------------------------------------------------------------------------------\n";
  Expect.equals(expected, buffer.toString());
}

void testColumnWrapAllAlignments() {
  var printTable = new ConsoleTable()
    ..addHeader(
        new Column("This is a very long text that should fit in a small window",
            alignment: ALIGNMENT.left, width: 10),
        (item) => "")
    ..addHeader(
        new Column("This is a not as long a text",
            alignment: ALIGNMENT.center, width: 10),
        (item) => "")
    ..addHeader(
        new Column("this is a short text",
            alignment: ALIGNMENT.right, width: 10),
        (item) => "")
    ..addHeader(new Column("this should not wrap", alignment: ALIGNMENT.left),
        (item) => "");

  StringBuffer buffer = new StringBuffer();
  printTable.printToSink([], buffer);

  var expected =
      "This is a                                                                       \n"
      "very long                                                                       \n"
      "text that   This is a                                                           \n"
      "should fit   not as                                                             \n"
      "in a small   long a    this is a                                                \n"
      "window        text    short text this should not wrap                           \n"
      "--------------------------------------------------------------------------------\n";
  Expect.equals(expected, buffer.toString());
}

void testRowWrapAllAlignments() {
  var printTable = new ConsoleTable()
    ..addHeader(
        new Column("This is a very long text that should fit in a small window",
            alignment: ALIGNMENT.left, width: 10),
        (item) => item["text1"])
    ..addHeader(
        new Column("This is a not as long a text",
            alignment: ALIGNMENT.center, width: 10),
        (item) => item["text2"])
    ..addHeader(
        new Column("test of a short text",
            alignment: ALIGNMENT.right, width: 10),
        (item) => item["text3"])
    ..addHeader(new Column("this should not wrap", alignment: ALIGNMENT.left),
        (item) => item["text4"]);
  StringBuffer buffer = new StringBuffer();
  printTable.printToSink([
    {
      "text1": "A this is a long text with a veryveryverybigword.",
      "text2": "B This is a short text",
      "text3": "C This is a longer text",
      "text4": "D This is a longer text"
    },
    {
      "text1": "A this is a long text with a veryveryverybigword.",
      "text2": "B This is a short text",
      "text3": "C This is a longer text",
      "text4": "D This is a longer text"
    },
    {
      "text1": "A this is a long text with a veryveryverybigword.",
      "text2": "B This is a short text",
      "text3": "C This is a longer text",
      "text4": "D This is a longer text"
    },
  ], buffer);

  var expected =
      "This is a                                                                       \n"
      "very long                                                                       \n"
      "text that   This is a                                                           \n"
      "should fit   not as                                                             \n"
      "in a small   long a    test of a                                                \n"
      "window        text    short text this should not wrap                           \n"
      "--------------------------------------------------------------------------------\n"
      "A this is   B This is  C This is D This is a longer text                        \n"
      "a long       a short    a longer                                                \n"
      "text with     text          text                                                \n"
      "a                                                                               \n"
      "veryveryve                                                                      \n"
      "rybigword.                                                                      \n"
      "A this is   B This is  C This is D This is a longer text                        \n"
      "a long       a short    a longer                                                \n"
      "text with     text          text                                                \n"
      "a                                                                               \n"
      "veryveryve                                                                      \n"
      "rybigword.                                                                      \n"
      "A this is   B This is  C This is D This is a longer text                        \n"
      "a long       a short    a longer                                                \n"
      "text with     text          text                                                \n"
      "a                                                                               \n"
      "veryveryve                                                                      \n"
      "rybigword.                                                                      \n";
  Expect.equals(expected, buffer.toString());
}

void testRowWrapAllAlignmentsWithDividers() {
  var printTable = new ConsoleTable(
      template: new Template(
          columnDivider: "|",
          rowDivider: "-",
          headerDivider: "*",
          cornerJoin: "|",
          rowJoin: "|",
          cellJoin: "+",
          leftRightFrame: "|",
          topBottomFrame: "="))
    ..addHeader(
        new Column("This is a very long text that should fit in a small window",
            alignment: ALIGNMENT.left, width: 10),
        (item) => item["text1"])
    ..addHeader(
        new Column("This is a not as long a text",
            alignment: ALIGNMENT.center, width: 10),
        (item) => item["text2"])
    ..addHeader(
        new Column("test is a short text",
            alignment: ALIGNMENT.right, width: 10),
        (item) => item["text3"])
    ..addHeader(new Column("this should not wrap", alignment: ALIGNMENT.left),
        (item) => item["text4"]);
  StringBuffer buffer = new StringBuffer();
  printTable.printToSink([
    {
      "text1": "A this is a long text with a veryveryverybigword.",
      "text2": "B This is a short text",
      "text3": "C This is a longer text",
      "text4": "D This is a longer text"
    },
    {
      "text1": "A this is a long text with a veryveryverybigword.",
      "text2": "B This is a short text",
      "text3": "C This is a longer text",
      "text4": "D This is a longer text"
    },
    {
      "text1": "A this is a long text with a veryveryverybigword.",
      "text2": "B This is a short text",
      "text3": "C This is a longer text",
      "text4": "D This is a longer text"
    },
  ], buffer);

  var expected =
      "|==============================================================================|\n"
      "|This is a |          |          |                                             |\n"
      "|very long |          |          |                                             |\n"
      "|text that | This is a|          |                                             |\n"
      "|should fit|  not as  |          |                                             |\n"
      "|in a small|  long a  | test is a|                                             |\n"
      "|window    |   text   |short text|this should not wrap                         |\n"
      "|******************************************************************************|\n"
      "|A this is | B This is| C This is|D This is a longer text                      |\n"
      "|a long    |  a short |  a longer|                                             |\n"
      "|text with |   text   |      text|                                             |\n"
      "|a         |          |          |                                             |\n"
      "|veryveryve|          |          |                                             |\n"
      "|rybigword.|          |          |                                             |\n"
      "|----------+----------+----------+---------------------------------------------|\n"
      "|A this is | B This is| C This is|D This is a longer text                      |\n"
      "|a long    |  a short |  a longer|                                             |\n"
      "|text with |   text   |      text|                                             |\n"
      "|a         |          |          |                                             |\n"
      "|veryveryve|          |          |                                             |\n"
      "|rybigword.|          |          |                                             |\n"
      "|----------+----------+----------+---------------------------------------------|\n"
      "|A this is | B This is| C This is|D This is a longer text                      |\n"
      "|a long    |  a short |  a longer|                                             |\n"
      "|text with |   text   |      text|                                             |\n"
      "|a         |          |          |                                             |\n"
      "|veryveryve|          |          |                                             |\n"
      "|rybigword.|          |          |                                             |\n"
      "|==============================================================================|\n";
  Expect.equals(expected, buffer.toString());
}

void testTruncateAllAlignmentsWithDividers() {
  var printTable = new ConsoleTable(
      template: new Template(
          columnDivider: " ",
          rowDivider: "-",
          headerDivider: "=",
          cellJoin: "/"))
    ..addHeader(
        new Column("This is a very long text that should fit in a small window",
            alignment: ALIGNMENT.left,
            cellBehaviour: TEXTBEHAVIOUR.truncateLeft,
            headerBehaviour: TEXTBEHAVIOUR.truncateRight,
            width: 10),
        (item) => item["text1"])
    ..addHeader(
        new Column("This is a not as long a text",
            alignment: ALIGNMENT.center,
            cellBehaviour: TEXTBEHAVIOUR.truncateRight,
            headerBehaviour: TEXTBEHAVIOUR.truncateLeft,
            width: 10),
        (item) => item["text2"])
    ..addHeader(
        new Column("test is a short text",
            alignment: ALIGNMENT.right, width: 10),
        (item) => item["text3"])
    ..addHeader(new Column("this should not wrap", alignment: ALIGNMENT.left),
        (item) => item["text4"]);
  StringBuffer buffer = new StringBuffer();
  printTable.printToSink([
    {
      "text1": "A this is a long text with a veryveryverybigword.",
      "text2": "B This is a short text",
      "text3": "C This is a longer text",
      "text4": "D This is a longer text"
    },
    {
      "text1": "A this is a long text with a veryveryverybigword.",
      "text2": "B This is a short text",
      "text3": "C This is a longer text",
      "text4": "D This is a longer text"
    },
    {
      "text1": "A this is a long text with a veryveryverybigword.",
      "text2": "B This is a short text",
      "text3": "C This is a longer text",
      "text4": "D This is a longer text"
    },
  ], buffer);

  var expected =
      "                       test is a                                                \n"
      "This is... ... a text short text this should not wrap                           \n"
      "================================================================================\n"
      "A this ... ...rt text  C This is D This is a longer text                        \n"
      "                        a longer                                                \n"
      "                            text                                                \n"
      "----------/----------/----------/-----------------------------------------------\n"
      "A this ... ...rt text  C This is D This is a longer text                        \n"
      "                        a longer                                                \n"
      "                            text                                                \n"
      "----------/----------/----------/-----------------------------------------------\n"
      "A this ... ...rt text  C This is D This is a longer text                        \n"
      "                        a longer                                                \n"
      "                            text                                                \n";
  Expect.equals(expected, buffer.toString());
}
