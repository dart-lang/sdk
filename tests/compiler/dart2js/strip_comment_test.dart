// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library strip_comment_test;

import "package:expect/expect.dart";
import 'package:compiler/src/mirrors/mirrors_util.dart';

testComment(String strippedText, String commentText) {
  Expect.stringEquals(strippedText, stripComment(commentText));
}

void main() {
  testComment('', '//');
  testComment('', '// ');
  testComment(' ', '//  ');
  testComment('foo bar baz', '//foo bar baz');
  testComment('foo bar baz', '// foo bar baz');
  testComment('foo bar baz ', '// foo bar baz ');
  testComment(' foo bar baz  ', '//  foo bar baz  ');

  testComment('', '///');
  testComment('', '/// ');
  testComment(' ', '///  ');
  testComment('foo bar baz', '///foo bar baz');
  testComment('foo bar baz', '/// foo bar baz');
  testComment('foo bar baz ', '/// foo bar baz ');
  testComment(' foo bar baz  ', '///  foo bar baz  ');

  testComment('', '/**/');
  testComment('', '/* */');
  testComment(' ', '/*  */');
  testComment('foo bar baz', '/*foo bar baz*/');
  testComment('foo bar baz', '/* foo bar baz*/');
  testComment('foo bar baz ', '/* foo bar baz */');
  testComment(' foo bar baz  ', '/*  foo bar baz  */');
  testComment('foo\nbar\nbaz', '/*foo\nbar\nbaz*/');
  testComment('foo\nbar\nbaz', '/* foo\nbar\nbaz*/');
  testComment('foo \n bar \n baz ', '/* foo \n bar \n baz */');
  testComment('foo\nbar\nbaz', '/* foo\n *bar\n *baz*/');
  testComment('foo\nbar\nbaz', '/* foo\n * bar\n * baz*/');
  testComment('foo \nbar \nbaz ', '/* foo \n * bar \n * baz */');
  testComment('\nfoo\nbar\nbaz',
      '''/*
          * foo
          * bar
          * baz*/''');
  testComment('\nfoo\nbar\nbaz\n',
      '''/*
          * foo
          * bar
          * baz
          */''');

  testComment('', '/***/');
  testComment('', '/** */');
  testComment(' ', '/**  */');
  testComment('foo bar baz', '/**foo bar baz*/');
  testComment('foo bar baz', '/** foo bar baz*/');
  testComment('foo bar baz ', '/** foo bar baz */');
  testComment(' foo bar baz  ', '/**  foo bar baz  */');
  testComment('foo\nbar\nbaz', '/**foo\nbar\nbaz*/');
  testComment('foo\nbar\nbaz', '/** foo\nbar\nbaz*/');
  testComment('foo \n bar \n baz ', '/** foo \n bar \n baz */');
  testComment('foo\nbar\nbaz', '/** foo\n *bar\n *baz*/');
  testComment('foo\nbar\nbaz', '/** foo\n * bar\n * baz*/');
  testComment('foo \nbar \nbaz ', '/** foo \n * bar \n * baz */');
  testComment('\nfoo\nbar\nbaz',
      '''/**
          * foo
          * bar
          * baz*/''');
  testComment('\nfoo\nbar\nbaz\n',
      '''/**
          * foo
          * bar
          * baz
          */''');
}