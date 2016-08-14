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

  static final staticTypeWarning = new Category("StaticTypeWarning");

  static final staticWarning = new Category("StaticWarning");

  static final hint = new Category("Hint");

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

  /// The error of which this message is a specialization.
  ///
  /// For example, "Const is not allowed on getters" may be a specialization of
  /// "The 'const' keyword is not allowed here".
  ///
  /// Examples of the specialized message, should trigger for the more generic
  /// message, when the platform doesn't support the more specialized message.
  ///
  /// Specializations must have the same error-id (but not sub-id) as the more
  /// generic message.
  final String specializationOf;

  /// The categories of this message.
  ///
  /// The same message can be used in multiple categories, for example, as
  /// hint and warning.
  final List<Category> categories;

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
      this.specializationOf: null,
      this.categories,
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
      'categories':
          message.categories.map((category) => category.name).toList(),
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
      categories: [Category.analysisOptionsError],
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

  // Const constructors may not have a body.
  'CONST_CONSTRUCTOR_WITH_BODY': new Message(
      id: 'LGJGHW',
      subId: 0,
      categories: [Category.parserError],
      template: "Const constructor can't have a body.",
      howToFix: "Try removing the 'const' keyword or the body.",
      usedBy: [analyzer, dart2js],
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
      subId: 1,
      categories: [Category.parserError],
      template: "Only redirecting factory constructors can be declared to "
          "be 'const'.",
      howToFix: "Try removing the 'const' keyword or replacing the body with "
          "'=' followed by a valid target.",
      usedBy: [analyzer, dart2js],
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
      categories: [Category.parserError],
      template: "Can't have modifier '#{modifier}' here.",
      howToFix: "Try removing '#{modifier}'.",
      usedBy: [dart2js],
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
      categories: [Category.parserError],
      template: "Can't have modifier '#{modifier}' here.",
      howToFix: "Try replacing modifier '#{modifier}' with 'var', 'final', "
          "or a type.",
      usedBy: [dart2js],
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
      // The specialization could also be 'EXTRANEOUS_MODIFIER_REPLACE', but the
      // example below triggers 'EXTRANEOUS_MODIFIER'.
      specializationOf: 'EXTRANEOUS_MODIFIER',
      categories: [Category.parserError],
      template: "Classes can't be declared to be 'const'.",
      howToFix: "Try removing the 'const' keyword or moving to the class'"
          " constructor(s).",
      usedBy: [analyzer],
      examples: const [
        r"""
        const class C {}

        main() => new C();
        """
      ]),

  'CONST_METHOD': new Message(
      id: 'GRKIQE',
      subId: 3,
      // The specialization could also be 'EXTRANEOUS_MODIFIER_REPLACE', but the
      // example below triggers 'EXTRANEOUS_MODIFIER'.
      specializationOf: 'EXTRANEOUS_MODIFIER',
      categories: [Category.parserError],
      template: "Getters, setters and methods can't be declared to be 'const'.",
      howToFix: "Try removing the 'const' keyword.",
      usedBy: [analyzer],
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
      // The specialization could also be 'EXTRANEOUS_MODIFIER_REPLACE', but the
      // example below triggers 'EXTRANEOUS_MODIFIER'.
      specializationOf: 'EXTRANEOUS_MODIFIER',
      categories: [Category.parserError],
      template: "Enums can't be declared to be 'const'.",
      howToFix: "Try removing the 'const' keyword.",
      usedBy: [analyzer],
      examples: const ["const enum Foo { x } main() {}",]),

  'CONST_TYPEDEF': new Message(
      id: 'GRKIQE',
      subId: 5,
      // The specialization could also be 'EXTRANEOUS_MODIFIER_REPLACE', but the
      // example below triggers 'EXTRANEOUS_MODIFIER'.
      specializationOf: 'EXTRANEOUS_MODIFIER',
      categories: [Category.parserError],
      template: "Type aliases can't be declared to be 'const'.",
      howToFix: "Try removing the 'const' keyword.",
      usedBy: [analyzer],
      examples: const ["const typedef void Foo(); main() {}",]),

  'CONST_AND_FINAL': new Message(
      id: 'GRKIQE',
      subId: 6,
      // The specialization could also be 'EXTRANEOUS_MODIFIER_REPLACE', but the
      // example below triggers 'EXTRANEOUS_MODIFIER'.
      specializationOf: 'EXTRANEOUS_MODIFIER',
      categories: [Category.parserError],
      template: "Members can't be declared to be both 'const' and 'final'.",
      howToFix: "Try removing either the 'const' or 'final' keyword.",
      usedBy: [analyzer],
      examples: const [
        "final const int x = 499; main() {}",
        "const final int x = 499; main() {}",
        "class A { static final const int x = 499; } main() {}",
        "class A { static const final int x = 499; } main() {}",
      ]),

  'CONST_AND_VAR': new Message(
      id: 'GRKIQE',
      subId: 7,
      // The specialization could also be 'EXTRANEOUS_MODIFIER_REPLACE', but the
      // example below triggers 'EXTRANEOUS_MODIFIER'.
      specializationOf: 'EXTRANEOUS_MODIFIER',
      categories: [Category.parserError],
      template: "Members can't be declared to be both 'const' and 'var'.",
      howToFix: "Try removing either the 'const' or 'var' keyword.",
      usedBy: [analyzer],
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
      categories: [Category.parserError],
      template: "Classes can't be declared inside other classes.",
      howToFix: "Try moving the class to the top-level.",
      usedBy: [analyzer],
      examples: const ["class A { class B {} } main() { new A(); }",]),

  'CONSTRUCTOR_WITH_RETURN_TYPE': new Message(
      id: 'VOJBWY',
      categories: [Category.parserError],
      template: "Constructors can't have a return type.",
      howToFix: "Try removing the return type.",
      usedBy: [analyzer, dart2js],
      examples: const ["class A { int A() {} } main() { new A(); }",]),

  'MISSING_EXPRESSION_IN_THROW': new Message(
      id: 'FTGGMJ',
      subId: 0,
      categories: [Category.parserError],
      template: "Missing expression after 'throw'.",
      howToFix: "Did you mean 'rethrow'?",
      usedBy: [analyzer, dart2js],
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
      categories: [Category.compileTimeError],
      template: 'Rethrow must be inside of catch clause.',
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
      categories: [Category.compileTimeError],
      template: "Constructors can't return values.",
      howToFix:
          "Try removing the return statement or using a factory constructor.",
      usedBy: [analyzer, dart2js],
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
      categories: [Category.compileTimeError],
      template: "Can't return a value from a generator function "
          "(using the '#{modifier}' modifier).",
      howToFix: "Try removing the value, replacing 'return' with 'yield' or"
          " changing the method body modifier.",
      usedBy: [analyzer, dart2js],
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

  'NOT_ASSIGNABLE': new Message(
      id: 'FYQYXB',
      subId: 0,
      categories: [Category.staticTypeWarning],
      template: "'#{fromType}' is not assignable to '#{toType}'.",
      usedBy: [dart2js]),

  'FORIN_NOT_ASSIGNABLE': new Message(
      id: 'FYQYXB',
      subId: 1,
      categories: [Category.hint],
      template: "The element type '#{currentType}' of '#{expressionType}' "
          "is not assignable to '#{elementType}'.",
      usedBy: [dart2js],
      examples: const [
        """
        main() {
          List<int> list = <int>[1, 2];
          for (String x in list) x;
        }
        """
      ]),

  /**
   * 13.11 Return: It is a static type warning if the type of <i>e</i> may not
   * be assigned to the declared return type of the immediately enclosing
   * function.
   */
  'RETURN_OF_INVALID_TYPE': new Message(
      id: 'FYQYXB',
      subId: 2,
      specializationOf: 'NOT_ASSIGNABLE',
      categories: [Category.staticTypeWarning],
      template: "The return type '#{fromType}' is not a '#{toType}', as "
          "defined by the method '#{method}'.",
      usedBy: [analyzer],
      examples: const ["int foo() => 'foo'; main() { foo(); }"]),

  /**
   * 12.11.1 New: It is a static warning if the static type of <i>a<sub>i</sub>,
   * 1 &lt;= i &lt;= n+ k</i> may not be assigned to the type of the
   * corresponding formal parameter of the constructor <i>T.id</i> (respectively
   * <i>T</i>).
   *
   * 12.11.2 Const: It is a static warning if the static type of
   * <i>a<sub>i</sub>, 1 &lt;= i &lt;= n+ k</i> may not be assigned to the type
   * of the corresponding formal parameter of the constructor <i>T.id</i>
   * (respectively <i>T</i>).
   *
   * 12.14.2 Binding Actuals to Formals: Let <i>T<sub>i</sub></i> be the static
   * type of <i>a<sub>i</sub></i>, let <i>S<sub>i</sub></i> be the type of
   * <i>p<sub>i</sub>, 1 &lt;= i &lt;= n+k</i> and let <i>S<sub>q</sub></i> be
   * the type of the named parameter <i>q</i> of <i>f</i>. It is a static
   * warning if <i>T<sub>j</sub></i> may not be assigned to <i>S<sub>j</sub>, 1
   * &lt;= j &lt;= m</i>.
   *
   * 12.14.2 Binding Actuals to Formals: Furthermore, each <i>q<sub>i</sub>, 1
   * &lt;= i &lt;= l</i>, must have a corresponding named parameter in the set
   * <i>{p<sub>n+1</sub>, &hellip; p<sub>n+k</sub>}</i> or a static warning
   * occurs. It is a static warning if <i>T<sub>m+j</sub></i> may not be
   * assigned to <i>S<sub>r</sub></i>, where <i>r = q<sub>j</sub>, 1 &lt;= j
   * &lt;= l</i>.
   */
  'ARGUMENT_TYPE_NOT_ASSIGNABLE': new Message(
      id: 'FYQYXB',
      subId: 3,
      specializationOf: 'NOT_ASSIGNABLE',
      categories: [Category.hint, Category.staticWarning],
      template: "The argument type '#{fromType}' cannot be assigned to the "
          "parameter type '#{toType}'.",
      usedBy: [analyzer],
      // TODO(floitsch): support hint warnings and ways to specify which
      // category an example should trigger for.
      examples: const ["foo(int x) => x; main() { foo('bar'); }"]),

  'CANNOT_RESOLVE': new Message(
      id: 'ERUSKD',
      subId: 0,
      categories: [Category.staticTypeWarning],
      template: "Can't resolve '#{name}'.",
      usedBy: [dart2js]),

  /**
   * 12.15.1 Ordinary Invocation: Let <i>T</i> be the static type of <i>o</i>.
   * It is a static type warning if <i>T</i> does not have an accessible
   * instance member named <i>m</i>.
   */
  'UNDEFINED_METHOD': new Message(
      id: 'ERUSKD',
      subId: 1,
      categories: [Category.staticTypeWarning, Category.hint],
      template: "The method '#{memberName}' is not defined for the class"
          " '#{className}'.",
      usedBy: [dart2js, analyzer],
      examples: const [
        """
        class A {
          foo() { bar(); }
        }
        main() { new A().foo(); }
        """,
      ]),

  /**
   * 12.15.1 Ordinary Invocation: Let <i>T</i> be the static type of <i>o</i>.
   * It is a static type warning if <i>T</i> does not have an accessible
   * instance member named <i>m</i>.
   */
  'UNDEFINED_METHOD_WITH_CONSTRUCTOR': new Message(
      id: 'ERUSKD',
      subId: 2,
      specializationOf: "UNDEFINED_METHOD",
      categories: [Category.staticTypeWarning],
      template: "The method '#{memberName}' is not defined for the class"
          " '#{className}', but a constructor with that name is defined.",
      howToFix: "Try adding 'new' or 'const' to invoke the constuctor, or "
          "change the method name.",
      usedBy: [analyzer],
      examples: const [
        """
        class A {
          A.bar() {}
        }
        main() { A.bar(); }
        """,
      ]),

  /**
   * 12.17 Getter Invocation: Let <i>T</i> be the static type of <i>e</i>. It is
   * a static type warning if <i>T</i> does not have a getter named <i>m</i>.
   */
  'UNDEFINED_GETTER': new Message(
      id: 'ERUSKD',
      subId: 3,
      categories: [
        Category.staticTypeWarning,
        Category.staticWarning,
        Category.hint
      ],
      template: "The getter '#{memberName}' is not defined for the "
          "class '#{className}'.",
      usedBy: [dart2js, analyzer],
      examples: const [
        "class A {} main() { new A().x; }",
        "class A {} main() { A.x; }"
      ]),

  /**
   * 12.17 Getter Invocation: It is a static warning if there is no class
   * <i>C</i> in the enclosing lexical scope of <i>i</i>, or if <i>C</i> does
   * not declare, implicitly or explicitly, a getter named <i>m</i>.
   */
  'UNDEFINED_ENUM_CONSTANT': new Message(
      id: 'ERUSKD',
      subId: 4,
      specializationOf: 'UNDEFINED_GETTER',
      categories: [Category.staticTypeWarning],
      template: "There is no constant named '#{memberName}' in '#{className}'.",
      usedBy: [analyzer],
      examples: const [
        """
        enum E { ONE }
        E e() { return E.TWO; }
        main() { e(); }
       """
      ]),

  'UNDEFINED_INSTANCE_GETTER_BUT_SETTER': new Message(
      id: 'ERUSKD',
      subId: 5,
      specializationOf: 'UNDEFINED_GETTER',
      categories: [Category.staticTypeWarning,],
      template: "The setter '#{memberName}' in class '#{className}' can"
          " not be used as a getter.",
      usedBy: [dart2js],
      examples: const ["class A { set x(y) {} } main() { new A().x; }",]),

  /**
   * 12.18 Assignment: Evaluation of an assignment of the form
   * <i>e<sub>1</sub></i>[<i>e<sub>2</sub></i>] = <i>e<sub>3</sub></i> is
   * equivalent to the evaluation of the expression (a, i, e){a.[]=(i, e);
   * return e;} (<i>e<sub>1</sub></i>, <i>e<sub>2</sub></i>,
   * <i>e<sub>2</sub></i>).
   *
   * 12.29 Assignable Expressions: An assignable expression of the form
   * <i>e<sub>1</sub></i>[<i>e<sub>2</sub></i>] is evaluated as a method
   * invocation of the operator method [] on <i>e<sub>1</sub></i> with argument
   * <i>e<sub>2</sub></i>.
   *
   * 12.15.1 Ordinary Invocation: Let <i>T</i> be the static type of <i>o</i>.
   * It is a static type warning if <i>T</i> does not have an accessible
   * instance member named <i>m</i>.
   */
  'UNDEFINED_OPERATOR': new Message(
      id: 'ERUSKD',
      subId: 6,
      categories: [Category.staticTypeWarning, Category.hint],
      template: "The operator '#{memberName}' is not defined for the "
          "class '#{className}'.",
      usedBy: [dart2js, analyzer],
      examples: const ["class A {} main() { new A() + 3; }",]),

  /**
   * 12.18 Assignment: Let <i>T</i> be the static type of <i>e<sub>1</sub></i>.
   * It is a static type warning if <i>T</i> does not have an accessible
   * instance setter named <i>v=</i>.
   *
   * 12.18 Assignment: It is as static warning if an assignment of the form
   * <i>v = e</i> occurs inside a top level or static function (be it function,
   * method, getter, or setter) or variable initializer and there is no
   * declaration <i>d</i> with name <i>v=</i> in the lexical scope enclosing the
   * assignment.
   *
   * 12.18 Assignment: It is a static warning if there is no class <i>C</i> in
   * the enclosing lexical scope of the assignment, or if <i>C</i> does not
   * declare, implicitly or explicitly, a setter <i>v=</i>.
   */
  'UNDEFINED_SETTER': new Message(
      id: 'ERUSKD',
      subId: 7,
      categories: [
        Category.staticTypeWarning,
        Category.staticWarning,
        Category.hint
      ],
      template: "The setter '#{memberName}' is not defined for the "
          "class '#{className}'.",
      usedBy: [dart2js, analyzer],
      // TODO(eernst): When this.x access is available, add examples here,
      // e.g., "class A { var x; A(this.x) : x = 3; } main() => new A(2);"
      examples: const ["class A {} main() { new A().x = 499; }",]),

  'NO_SUCH_SUPER_MEMBER': new Message(
      id: 'ERUSKD',
      subId: 8,
      categories: [Category.staticTypeWarning],
      template:
          "Can't resolve '#{memberName}' in a superclass of '#{className}'.",
      usedBy: [dart2js]),

  /**
   * 12.17 Getter Invocation: Let <i>T</i> be the static type of <i>e</i>. It is
   * a static type warning if <i>T</i> does not have a getter named <i>m</i>.
   *
   * 12.17 Getter Invocation: It is a static warning if there is no class
   * <i>C</i> in the enclosing lexical scope of <i>i</i>, or if <i>C</i> does
   * not declare, implicitly or explicitly, a getter named <i>m</i>.
   */
  'UNDEFINED_SUPER_GETTER': new Message(
      id: 'ERUSKD',
      subId: 9,
      specializationOf: 'NO_SUCH_SUPER_MEMBER',
      categories: [Category.staticTypeWarning, Category.staticWarning],
      template: "The getter '#{memberName}' is not defined in a superclass "
          "of '#{className}'.",
      usedBy: [analyzer],
      examples: const [
        """
        class A {}
        class B extends A {
          foo() => super.x;
        }
        main() { new B().foo(); }
        """
      ]),

  /**
   * 12.15.4 Super Invocation: A super method invocation <i>i</i> has the form
   * <i>super.m(a<sub>1</sub>, &hellip;, a<sub>n</sub>, x<sub>n+1</sub>:
   * a<sub>n+1</sub>, &hellip; x<sub>n+k</sub>: a<sub>n+k</sub>)</i>. It is a
   * static type warning if <i>S</i> does not have an accessible instance member
   * named <i>m</i>.
   */
  'UNDEFINED_SUPER_METHOD': new Message(
      id: 'ERUSKD',
      subId: 10,
      specializationOf: 'NO_SUCH_SUPER_MEMBER',
      categories: [Category.staticTypeWarning],
      template: "The method '#{memberName}' is not defined in a superclass "
          "of '#{className}'.",
      usedBy: [analyzer],
      examples: const [
        """
        class A {}
        class B extends A {
          foo() => super.x();
        }
        main() { new B().foo(); }
        """
      ]),

  /**
   * 12.18 Assignment: Evaluation of an assignment of the form
   * <i>e<sub>1</sub></i>[<i>e<sub>2</sub></i>] = <i>e<sub>3</sub></i> is
   * equivalent to the evaluation of the expression (a, i, e){a.[]=(i, e);
   * return e;} (<i>e<sub>1</sub></i>, <i>e<sub>2</sub></i>,
   * <i>e<sub>2</sub></i>).
   *
   * 12.29 Assignable Expressions: An assignable expression of the form
   * <i>e<sub>1</sub></i>[<i>e<sub>2</sub></i>] is evaluated as a method
   * invocation of the operator method [] on <i>e<sub>1</sub></i> with argument
   * <i>e<sub>2</sub></i>.
   *
   * 12.15.1 Ordinary Invocation: Let <i>T</i> be the static type of <i>o</i>.
   * It is a static type warning if <i>T</i> does not have an accessible
   * instance member named <i>m</i>.
   */
  'UNDEFINED_SUPER_OPERATOR': new Message(
      id: 'ERUSKD',
      subId: 11,
      specializationOf: 'NO_SUCH_SUPER_MEMBER',
      categories: [Category.staticTypeWarning],
      template: "The operator '#{memberName}' is not defined in a superclass "
          "of '#{className}'.",
      usedBy: [analyzer],
      examples: const [
        """
        class A {}
        class B extends A {
          foo() => super + 499;
        }
        main() { new B().foo(); }
        """
      ]),

  /**
   * 12.18 Assignment: Let <i>T</i> be the static type of <i>e<sub>1</sub></i>.
   * It is a static type warning if <i>T</i> does not have an accessible
   * instance setter named <i>v=</i>.
   *
   * 12.18 Assignment: It is as static warning if an assignment of the form
   * <i>v = e</i> occurs inside a top level or static function (be it function,
   * method, getter, or setter) or variable initializer and there is no
   * declaration <i>d</i> with name <i>v=</i> in the lexical scope enclosing the
   * assignment.
   *
   * 12.18 Assignment: It is a static warning if there is no class <i>C</i> in
   * the enclosing lexical scope of the assignment, or if <i>C</i> does not
   * declare, implicitly or explicitly, a setter <i>v=</i>.

   */
  'UNDEFINED_SUPER_SETTER': new Message(
      id: 'ERUSKD',
      subId: 12,
      categories: [Category.staticTypeWarning, Category.staticWarning],
      template: "The setter '#{memberName}' is not defined in a superclass "
          "of '#{className}'.",
      usedBy: [analyzer, dart2js,],
      examples: const [
        """
        class A {}
        class B extends A {
          foo() { super.x = 499; }
        }
        main() { new B().foo(); }
        """,
        // TODO(floitsch): reenable this test.
        /*
        """
        main() => new B().m();
        class A {
          get x => 1;
        }
        class B extends A {
          m() { super.x = 2; }
        }
        """
        */
      ]),

  /**
   * 12.15.3 Unqualified Invocation: If there exists a lexically visible
   * declaration named <i>id</i>, let <i>f<sub>id</sub></i> be the innermost
   * such declaration. Then: [skip]. Otherwise, <i>f<sub>id</sub></i> is
   * considered equivalent to the ordinary method invocation
   * <b>this</b>.<i>id</i>(<i>a<sub>1</sub></i>, ..., <i>a<sub>n</sub></i>,
   * <i>x<sub>n+1</sub></i> : <i>a<sub>n+1</sub></i>, ...,
   * <i>x<sub>n+k</sub></i> : <i>a<sub>n+k</sub></i>).
   */
  'UNDEFINED_FUNCTION': new Message(
      id: 'ERUSKD',
      subId: 13,
      specializationOf: 'CANNOT_RESOLVE',
      categories: [Category.staticTypeWarning],
      template: "The function '#{memberName}' is not defined.",
      usedBy: [analyzer],
      examples: const ["main() { foo(); }",]),

  'UNDEFINED_STATIC_GETTER_BUT_SETTER': new Message(
      id: 'ERUSKD',
      subId: 14,
      specializationOf: 'CANNOT_RESOLVE',
      categories: [Category.staticTypeWarning],
      template: "Cannot resolve getter '#{name}'.",
      usedBy: [dart2js],
      examples: const ["set foo(x) {}  main() { foo; }",]),

  'UNDEFINED_STATIC_SETTER_BUT_GETTER': new Message(
      id: 'ERUSKD',
      subId: 15,
      specializationOf: 'CANNOT_RESOLVE',
      categories: [Category.staticTypeWarning],
      template: "Cannot resolve setter '#{name}'.",
      usedBy: [dart2js],
      examples: const [
        """
        main() {
          final x = 1;
          x = 2;
        }""",
        """
        main() {
          const x = 1;
          x = 2;
        }
        """,
        """
        final x = 1;
        main() { x = 3; }
        """,
        """
        const x = 1;
        main() { x = 3; }
        """,
        "get foo => null  main() { foo = 5; }",
        "const foo = 0  main() { foo = 5; }",
      ]),
};
