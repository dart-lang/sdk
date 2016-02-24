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

  static final compileTimeError = new Category("CompileTimeError");

  final String name;

  Category(this.name);
}

enum Platform { dart2js, analyzer, }
const dart2js = Platform.dart2js;
const analyzer = Platform.analyzer;

class Message {
  /// Generic id for this message.
  ///
  /// This id should be shared by all errors that fall into the same category.
  /// In particular, we want errors of the same category to share the same
  /// explanation page, and want to disable warnings of the same category
  /// with just one line.
  final String id;

  /// The sub-id of the error.
  ///
  /// This id just needs to be unique within the same [id].
  final int subId;

  /// The error sub-id of which this message is a specialization.
  ///
  /// For example, "Const is not allowed on getters" may be a specialization of
  /// "The 'const' keyword is not allowed here".
  ///
  /// Examples of the specialized message, should trigger for the more generic
  /// message, when the platform doesn't support the more specialized message.
  final int specializationOf;

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
      this.specializationOf: -1,
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
  return new JsonEncoder.withIndent('  ').convert(jsonified);
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
      usedBy: [
        dart2js
      ],
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
      specializationOf: 0,
      category: Category.parserError,
      template: "Const constructor can't have a body.",
      howToFix: "Try removing the 'const' keyword or the body.",
      usedBy: [
        analyzer
      ],
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
      specializationOf: 0,
      category: Category.parserError,
      template: "Only redirecting factory constructors can be declared to "
          "be 'const'.",
      howToFix: "Try removing the 'const' keyword or replacing the body with "
          "'=' followed by a valid target.",
      usedBy: [
        analyzer
      ],
      examples: const [
        r"""
         class C {
           const factory C() {}
         }

         main() => new C();"""
      ]),

  'EXTRANEOUS_MODIFIER': new Message(
      id: 'GRKIQE',
      subId: 0,
      category: Category.parserError,
      template: "Can't have modifier '#{modifier}' here.",
      howToFix: "Try removing '#{modifier}'.",
      usedBy: [
        dart2js
      ],
      examples: const [
        "var String foo; main(){}",
        // "var get foo; main(){}",
        "var set foo; main(){}",
        "var final foo; main(){}",
        "var var foo; main(){}",
        "var const foo; main(){}",
        "var abstract foo; main(){}",
        "var static foo; main(){}",
        "var external foo; main(){}",
        "get var foo; main(){}",
        "set var foo; main(){}",
        "final var foo; main(){}",
        "var var foo; main(){}",
        "const var foo; main(){}",
        "abstract var foo; main(){}",
        "static var foo; main(){}",
        "external var foo; main(){}"
      ]),

  'EXTRANEOUS_MODIFIER_REPLACE': new Message(
      id: 'GRKIQE',
      subId: 1,
      category: Category.parserError,
      template: "Can't have modifier '#{modifier}' here.",
      howToFix: "Try replacing modifier '#{modifier}' with 'var', 'final', "
          "or a type.",
      usedBy: [
        dart2js
      ],
      examples: const [
        // "get foo; main(){}",
        "set foo; main(){}",
        "abstract foo; main(){}",
        "static foo; main(){}",
        "external foo; main(){}"
      ]),

  'CONST_CLASS': new Message(
      id: 'GRKIQE',
      subId: 2,
      // The specialization could also be 1, but the example below triggers 0.
      specializationOf: 0,
      category: Category.parserError,
      template: "Classes can't be declared to be 'const'",
      howToFix: "Try removing the 'const' keyword or moving to the class'"
          " constructor(s).",
      usedBy: [
        analyzer
      ],
      examples: const [
        r"""
        const class C {}

        main() => new C();
        """
      ]),

  'CONST_METHOD': new Message(
      id: 'GRKIQE',
      subId: 3,
      // The specialization could also be 1, but the example below triggers 0.
      specializationOf: 0,
      category: Category.parserError,
      template: "Getters, setters and methods can't be declared to be 'const'",
      howToFix: "Try removing the 'const' keyword.",
      usedBy: [
        analyzer
      ],
      examples: const [
        "const int foo() => 499; main() {}",
        "const int get foo => 499; main() {}",
        "const set foo(v) => 499; main() {}",
        "class A { const int foo() => 499; } main() { new A(); }",
        "class A { const int get foo => 499; } main() { new A(); }",
        "class A { const set foo(v) => 499; } main() { new A(); }",
      ]),

  'CONST_ENUM': new Message(
      id: 'GRKIQE',
      subId: 4,
      // The specialization could also be 1, but the example below triggers 0.
      specializationOf: 0,
      category: Category.parserError,
      template: "Enums can't be declared to be 'const'",
      howToFix: "Try removing the 'const' keyword.",
      usedBy: [analyzer],
      examples: const ["const enum Foo { x } main() {}",]),

  'CONST_TYPEDEF': new Message(
      id: 'GRKIQE',
      subId: 5,
      // The specialization could also be 1, but the example below triggers 0.
      specializationOf: 0,
      category: Category.parserError,
      template: "Type aliases can't be declared to be 'const'",
      howToFix: "Try removing the 'const' keyword.",
      usedBy: [analyzer],
      examples: const ["const typedef void Foo(); main() {}",]),

  'CONST_AND_FINAL': new Message(
      id: 'GRKIQE',
      subId: 6,
      // The specialization could also be 1, but the example below triggers 0.
      specializationOf: 0,
      category: Category.parserError,
      template: "Members can't be declared to be both 'const' and 'final'",
      howToFix: "Try removing either the 'const' or 'final' keyword.",
      usedBy: [
        analyzer
      ],
      examples: const [
        "final const int x = 499; main() {}",
        "const final int x = 499; main() {}",
        "class A { static final const int x = 499; } main() {}",
        "class A { static const final int x = 499; } main() {}",
      ]),

  'CONST_AND_VAR': new Message(
      id: 'GRKIQE',
      subId: 7,
      // The specialization could also be 1, but the example below triggers 0.
      specializationOf: 0,
      category: Category.parserError,
      template: "Members can't be declared to be both 'const' and 'var'",
      howToFix: "Try removing either the 'const' or 'var' keyword.",
      usedBy: [
        analyzer
      ],
      examples: const [
        "var const x = 499; main() {}",
        "const var x = 499; main() {}",
        "class A { var const x = 499; } main() {}",
        "class A { const var x = 499; } main() {}",
      ]),

  'CLASS_IN_CLASS': new Message(
      // Dart2js currently reports this as an EXTRANEOUS_MODIFIER error.
      // TODO(floitsch): make dart2js use this error instead.
      id: 'DOTHQH',
      category: Category.parserError,
      template: "Classes can't be declared inside other classes.",
      howToFix: "Try moving the class to the top-level.",
      usedBy: [analyzer],
      examples: const ["class A { class B {} } main() { new A(); }",]),

  'CONSTRUCTOR_WITH_RETURN_TYPE': new Message(
      id: 'VOJBWY',
      category: Category.parserError,
      template: "Constructors can't have a return type",
      howToFix: "Try removing the return type.",
      usedBy: [analyzer, dart2js],
      examples: const ["class A { int A() {} } main() { new A(); }",]),

  'MISSING_EXPRESSION_IN_THROW': new Message(
      id: 'FTGGMJ',
      subId: 0,
      category: Category.parserError,
      template: "Missing expression after 'throw'.",
      howToFix: "Did you mean 'rethrow'?",
      usedBy: [
        analyzer,
        dart2js
      ],
      examples: const [
        'main() { throw; }',
        'main() { try { throw 0; } catch(e) { throw; } }'
      ]),

  /**
   * 12.8.1 Rethrow: It is a compile-time error if an expression of the form
   * <i>rethrow;</i> is not enclosed within a on-catch clause.
   */
  'RETHROW_OUTSIDE_CATCH': new Message(
      id: 'MWETLC',
      category: Category.compileTimeError,
      template: 'Rethrow must be inside of catch clause',
      howToFix: "Try moving the expression into a catch clause, or "
          "using a 'throw' expression.",
      usedBy: [analyzer, dart2js],
      examples: const ["main() { rethrow; }"]),

  /**
   * 13.12 Return: It is a compile-time error if a return statement of the form
   * <i>return e;</i> appears in a generative constructor.
   */
  'RETURN_IN_GENERATIVE_CONSTRUCTOR': new Message(
      id: 'UOTDQH',
      category: Category.compileTimeError,
      template: "Constructors can't return values.",
      howToFix:
          "Try removing the return statement or using a factory constructor.",
      usedBy: [
        analyzer,
        dart2js
      ],
      examples: const [
        """
        class C {
          C() {
            return 1;
          }
        }

        main() => new C();"""
      ]),

  /**
   * 13.12 Return: It is a compile-time error if a return statement of the form
   * <i>return e;</i> appears in a generator function.
   */
  'RETURN_IN_GENERATOR': new Message(
      id: 'JRUTUQ',
      subId: 0,
      category: Category.compileTimeError,
      template: "Can't return a value from a generator function "
          "(using the '#{modifier}' modifier).",
      howToFix: "Try removing the value, replacing 'return' with 'yield' or"
          " changing the method body modifier",
      usedBy: [
        analyzer,
        dart2js
      ],
      examples: const [
        """
        foo() async* { return 0; }
        main() => foo();
        """,
        """
        foo() sync* { return 0; }
        main() => foo();
        """
      ]),
};
