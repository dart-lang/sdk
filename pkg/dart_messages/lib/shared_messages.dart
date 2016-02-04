// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// An update to this file must be followed by regenerating the corresponding
// json, dart2js and analyzer file. Use `publish.dart` in the bin directory.
//
// Every message in this file must have an id. Use `message_id.dart` in the
// bin directory to generate a fresh one.

// The messages in this file should meet the following guide lines:
//
// 1. The message should be a complete sentence starting with an uppercase
// letter, and ending with a period.
//
// 2. Reserved words and embedded identifiers should be in single quotes, so
// prefer double quotes for the complete message. For example, "The
// class '#{className}' can't use 'super'." Notice that the word 'class' in the
// preceding message is not quoted as it refers to the concept 'class', not the
// reserved word. On the other hand, 'super' refers to the reserved word. Do
// not quote 'null' and numeric literals.
//
// 3. Do not try to compose messages, as it can make translating them hard.
//
// 4. Try to keep the error messages short, but informative.
//
// 5. Use simple words and terminology, assume the reader of the message
// doesn't have an advanced degree in math, and that English is not the
// reader's native language. Do not assume any formal computer science
// training. For example, do not use Latin abbreviations (prefer "that is" over
// "i.e.", and "for example" over "e.g."). Also avoid phrases such as "if and
// only if" and "iff", that level of precision is unnecessary.
//
// 6. Prefer contractions when they are in common use, for example, prefer
// "can't" over "cannot". Using "cannot", "must not", "shall not", etc. is
// off-putting to people new to programming.
//
// 7. Use common terminology, preferably from the Dart Language
// Specification. This increases the user's chance of finding a good
// explanation on the web.
//
// 8. Do not try to be cute or funny. It is extremely frustrating to work on a
// product that crashes with a "tongue-in-cheek" message, especially if you did
// not want to use this product to begin with.
//
// 9. Do not lie, that is, do not write error messages containing phrases like
// "can't happen".  If the user ever saw this message, it would be a
// lie. Prefer messages like: "Internal error: This function should not be
// called when 'x' is null.".
//
// 10. Prefer to not use imperative tone. That is, the message should not sound
// accusing or like it is ordering the user around. The computer should
// describe the problem, not criticize for violating the specification.
//
// Other things to keep in mind:
//
// Generally, we want to provide messages that consists of three sentences:
// 1. what is wrong, 2. why is it wrong, 3. how do I fix it. However, we
// combine the first two in [template] and the last in [howToFix].

import 'dart:convert';

/// Encodes the category of the message.
///
/// This is currently only used in the analyzer.
// TODO(floitsch): encode severity and type in the category, so we can generate
// the corresponding ErrorCode subclasses.
class Category {
  static final analysisOptionsError = new Category("AnalysisOptionsError");

  static final analysisOptionsWarning = new Category("AnalysisOptionsWarning");

  static final checkedModeCompileTimeError =
      new Category("CheckedModeCompileTimeError");

  static final parserError = new Category("ParserError");

  final String name;

  Category(this.name);
}

enum Platform {
  dart2js, analyzer,
}
const dart2js = Platform.dart2js;
const analyzer = Platform.analyzer;

class Message {
  final String id;
  final int subId;
  final Category category;
  final String template;
  // The analyzer fills holes positionally (and not named). The following field
  // overrides the order of the holes.
  // For example the template "The argument #field in #cls is bad", could have
  // the order `["cls", "field"]', which means that the analyzer would first
  // provide the class `cls` and then only `field`.
  // This list is generally `null`, but when it is provided it must contain all
  // holes.
  final List<String> templateHoleOrder;
  final String howToFix;
  final List<String> options;
  final List examples;
  final List<Platform> usedBy;

  Message(
      {this.id,
      this.subId: 0,
      this.category,
      this.template,
      this.templateHoleOrder,
      this.howToFix,
      this.options,
      this.usedBy: const [],
      this.examples});
}

String get messagesAsJson {
  var jsonified = {};
  MESSAGES.forEach((String name, Message message) {
    jsonified[name] = {
      'id': message.id,
      'subId': message.subId,
      'category': message.category.name,
      'template': message.template,
      'templateHoleOrder': message.templateHoleOrder,
      'howToFix': message.howToFix,
      'options': message.options,
      'usedBy': message.usedBy.map((platform) => platform.toString()).toList(),
      'examples': message.examples,
    };
  });
  return JSON.encode(jsonified);
}

final Map<String, Message> MESSAGES = {
  'exampleMessage': new Message(
      id: 'use an Id generated by bin/message_id.dart',
      category: Category.analysisOptionsError,
      template: "#use #named #arguments",
      templateHoleOrder: ["arguments", "named", "use"],
      howToFix: "an explanation on how to fix things",
      examples: [
        r'''
      Some multiline example;
      That generates the bug.''',
        {
          'fileA.dart': '''
        or a map from file to content.
        again multiline''',
          'fileB.dart': '''
        with possibly multiple files.
        muliline too'''
        }
      ]),

  // Const constructors (factory or not) may not have a body.
  'CONST_CONSTRUCTOR_OR_FACTORY_WITH_BODY': new Message(
      id: 'LGJGHW',
      subId: 0,
      category: Category.parserError,
      template: "Const constructor or factory can't have a body.",
      howToFix: "Remove the 'const' keyword or the body.",
      usedBy: [dart2js],
      examples: const [
        r"""
         class C {
           const C() {}
         }

         main() => new C();""",
        r"""
         class C {
           const factory C() {}
         }

         main() => new C();"""
      ]),
  // Const constructors may not have a body.
  'CONST_CONSTRUCTOR_WITH_BODY': new Message(
      id: 'LGJGHW',
      subId: 1,
      category: Category.parserError,
      template: "Const constructor can't have a body.",
      howToFix: "Try removing the 'const' keyword or the body.",
      usedBy: [analyzer],
      examples: const [
        r"""
         class C {
           const C() {}
         }

         main() => new C();"""
      ]),
  // Const constructor factories may only redirect (and must not have a body).
  'CONST_FACTORY': new Message(
      id: 'LGJGHW',
      subId: 2,
      category: Category.parserError,
      template: "Only redirecting factory constructors can be declared to "
          "be 'const'.",
      howToFix: "Try removing the 'const' keyword or replacing the body with "
          "'=' followed by a valid target",
      usedBy: [analyzer],
      examples: const [
        r"""
         class C {
           const factory C() {}
         }

         main() => new C();"""
      ]),
};
