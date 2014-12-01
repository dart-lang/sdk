// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.testing.html_factory;

import 'package:analyzer/src/generated/html.dart';

/**
 * Utility methods to create HTML nodes.
 */
class HtmlFactory {
  static XmlAttributeNode attribute(String name, String value) {
    Token nameToken = stringToken(name);
    Token equalsToken = new Token.con1(TokenType.EQ, 0);
    Token valueToken = stringToken(value);
    return new XmlAttributeNode(nameToken, equalsToken, valueToken);
  }

  static Token gtToken() {
    return new Token.con1(TokenType.GT, 0);
  }

  static Token ltsToken() {
    return new Token.con1(TokenType.LT_SLASH, 0);
  }

  static Token ltToken() {
    return new Token.con1(TokenType.LT, 0);
  }

  static HtmlScriptTagNode scriptTag([List<XmlAttributeNode> attributes =
      XmlAttributeNode.EMPTY_LIST]) {
    return new HtmlScriptTagNode(
        ltToken(),
        stringToken("script"),
        attributes,
        sgtToken(),
        null,
        null,
        null,
        null);
  }

  static HtmlScriptTagNode scriptTagWithContent(String contents,
      [List<XmlAttributeNode> attributes = XmlAttributeNode.EMPTY_LIST]) {
    Token attributeEnd = gtToken();
    Token contentToken = stringToken(contents);
    attributeEnd.setNext(contentToken);
    Token contentEnd = ltsToken();
    contentToken.setNext(contentEnd);
    return new HtmlScriptTagNode(
        ltToken(),
        stringToken("script"),
        attributes,
        attributeEnd,
        null,
        contentEnd,
        stringToken("script"),
        gtToken());
  }

  static Token sgtToken() {
    return new Token.con1(TokenType.SLASH_GT, 0);
  }

  static Token stringToken(String value) {
    return new Token.con2(TokenType.STRING, 0, value);
  }

  static XmlTagNode tagNode(String name, [List<XmlAttributeNode> attributes =
      XmlAttributeNode.EMPTY_LIST]) {
    return new XmlTagNode(
        ltToken(),
        stringToken(name),
        attributes,
        sgtToken(),
        null,
        null,
        null,
        null);
  }
}
