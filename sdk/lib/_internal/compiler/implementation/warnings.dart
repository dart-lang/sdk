// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js;

const DONT_KNOW_HOW_TO_FIX = "";

/**
 * The messages in this file should meet the following guide lines:
 *
 * 1. The message should start with exactly one of "Error", "Internal error",
 * "Warning", "Info", or "Hint" followed by a colon. It is crucial to users to
 * be able to locate errors in the midst of warnings.
 * TODO(ahe): Remove these prefixes from the error message.
 *
 * 2. After the colon, one space and a complete sentence starting with an
 * uppercase letter, and ending with a period.
 *
 * 3. Reserved words and embedded identifiers should be in single quotes, so
 * prefer double quotes for the complete message. For example, "Error: The
 * class '#{className}' can't use 'super'." Notice that the word 'class' in the
 * preceding message is not quoted as it refers to the concept 'class', not the
 * reserved word. On the other hand, 'super' refers to the reserved word. Do
 * not quote 'null' and numeric literals.
 *
 * 4. Do not try to compose messages, as it can make translating them hard.
 *
 * 5. Try to keep the error messages short, but informative.
 *
 * 6. Use simple words and terminology, assume the reader of the message
 * doesn't have an advanced degree in math, and that English is not the
 * reader's native language. Do not assume any formal computer science
 * training. For example, do not use Latin abbreviations (prefer "that is" over
 * "i.e.", and "for example" over "e.g."). Also avoid phrases such as "if and
 * only if" and "iff", that level of precision is unnecessary.
 *
 * 7. Prefer contractions when they are in common use, for example, prefer
 * "can't" over "cannot". Using "cannot", "must not", "shall not", etc. is
 * off-putting to people new to programming.
 *
 * 8. Use common terminology, preferably from the Dart Language
 * Specification. This increases the user's chance of finding a good
 * explanation on the web.
 *
 * 9. Do not try to be cute or funny. It is extremely frustrating to work on a
 * product that crashes with a "tongue-in-cheek" message, especially if you did
 * not want to use this product to begin with with.
 *
 * 10. Do not lie, that is, do not write error messages containing phrases like
 * "can't happen".  If the user ever saw this message, it would be a
 * lie. Prefer messages like: "Internal error: This function should not be
 * called when 'x' is null.".
 *
 * 11. Prefer to not use imperative tone. That is, the message should not sound
 * accusing or like it is ordering the user around. The computer should
 * describe the problem, not criticize for violating the specification.
 *
 * Other things to keep in mind:
 *
 * An INFO message should always be preceded by a non-INFO message, and the
 * INFO messages are additional details about the preceding non-INFO
 * message. For example, consider duplicated elements. First report a WARNING
 * or ERROR about the duplicated element, and then report an INFO about the
 * location of the existing element.
 *
 * Generally, we want to provide messages that consists of three sentences:
 * 1. what is wrong, 2. why is it wrong, 3. how do I fix it. However, we
 * combine the first two in [template] and the last in [howToFix].
 */
class MessageKind {
  /// Should describe what is wrong and why.
  final String template;

  /// Should describe how to fix the problem. Elided when using --terse option.
  final String howToFix;

  /**
   *  Examples will be checked by
   *  tests/compiler/dart2js/message_kind_test.dart.
   *
   *  An example is either a String containing the example source code or a Map
   *  from filenames to source code. In the latter case, the filename for the
   *  main library code must be 'main.dart'.
   */
  final List examples;

  const MessageKind(this.template, {this.howToFix, this.examples});

  /// Do not use this. It is here for legacy and debugging. It violates item 4
  /// above.
  static const MessageKind GENERIC = const MessageKind('#{text}');

  static const DualKind NOT_ASSIGNABLE = const DualKind(
      error: const MessageKind(
          "Error: '#{fromType}' is not assignable to '#{toType}'."),
      warning: const MessageKind(
          "Warning: '#{fromType}' is not assignable to '#{toType}'."));

  static const MessageKind VOID_EXPRESSION = const MessageKind(
      "Warning: Expression does not yield a value.");

  static const MessageKind VOID_VARIABLE = const MessageKind(
      "Warning: Variable cannot be of type void.");

  static const MessageKind RETURN_VALUE_IN_VOID = const MessageKind(
      "Warning: Cannot return value from void function.");

  static const MessageKind RETURN_NOTHING = const MessageKind(
      "Warning: Value of type '#{returnType}' expected.");

  static const MessageKind MISSING_ARGUMENT = const MessageKind(
      "Warning: Missing argument of type '#{argumentType}'.");

  static const MessageKind ADDITIONAL_ARGUMENT = const MessageKind(
      "Warning: Additional argument.");

  static const MessageKind NAMED_ARGUMENT_NOT_FOUND = const MessageKind(
      "Warning: No named argument '#{argumentName}' found on method.");

  static const DualKind MEMBER_NOT_FOUND = const DualKind(
      error: const MessageKind(
          "Error: No member named '#{memberName}' in class '#{className}'."),
      warning: const MessageKind(
          "Warning: No member named '#{memberName}' in class '#{className}'."));

  static const MessageKind METHOD_NOT_FOUND = const MessageKind(
      "Warning: No method named '#{memberName}' in class '#{className}'.");

  static const MessageKind OPERATOR_NOT_FOUND = const MessageKind(
      "Warning: No operator '#{memberName}' in class '#{className}'.");

  static const MessageKind PROPERTY_NOT_FOUND = const MessageKind(
      "Warning: No property named '#{memberName}' in class '#{className}'.");

  static const MessageKind NOT_CALLABLE = const MessageKind(
      "Warning: '#{elementName}' is not callable.");

  static const DualKind MEMBER_NOT_STATIC = const DualKind(
      error: const MessageKind(
          "Error: '#{className}.#{memberName}' is not static."),
      warning: const MessageKind(
          "Warning: '#{className}.#{memberName}' is not static."));

  static const MessageKind NO_INSTANCE_AVAILABLE = const MessageKind(
      "Error: '#{name}' is only available in instance methods.");

  static const MessageKind PRIVATE_ACCESS = const MessageKind(
      "Warning: '#{name}' is declared private within library "
      "'#{libraryName}'.");

  static const MessageKind THIS_IS_THE_METHOD = const MessageKind(
      "Info: This is the method declaration.");

  static const MessageKind UNREACHABLE_CODE = const MessageKind(
      "Warning: Unreachable code.");

  static const MessageKind MISSING_RETURN = const MessageKind(
      "Warning: Missing return.");

  static const MessageKind MAYBE_MISSING_RETURN = const MessageKind(
      "Warning: Not all paths lead to a return or throw statement.");

  static const DualKind CANNOT_RESOLVE = const DualKind(
      error: const MessageKind("Error: Cannot resolve '#{name}'."),
      warning: const MessageKind("Warning: Cannot resolve '#{name}'."));

  static const MessageKind CANNOT_RESOLVE_CONSTRUCTOR = const MessageKind(
      "Error: Cannot resolve constructor '#{constructorName}'.");

  static const MessageKind CANNOT_RESOLVE_CONSTRUCTOR_FOR_IMPLICIT =
      const MessageKind("Error: cannot resolve constructor '#{constructorName}'"
          " for implicit super call.",
      howToFix: "Try explicitly invoking a constructor of the super class",
      examples: const ["""
class A {
  A.foo() {}
}
class B extends A {
  B();
}
main() => new B();
"""]);

  static const MessageKind INVALID_UNNAMED_CONSTRUCTOR_NAME = const MessageKind(
      "Error: Unnamed constructor name must be '#{name}'.");

  static const MessageKind INVALID_CONSTRUCTOR_NAME = const MessageKind(
      "Error: Constructor name must start with '#{name}'.");

  static const DualKind CANNOT_RESOLVE_TYPE = const DualKind(
      error: const MessageKind("Error: Cannot resolve type '#{typeName}'."),
      warning: const MessageKind(
          "Warning: Cannot resolve type '#{typeName}'."));

  static const MessageKind DUPLICATE_DEFINITION = const MessageKind(
      "Error: Duplicate definition of '#{name}'.");

  static const MessageKind EXISTING_DEFINITION = const MessageKind(
      "Info: Existing definition of '#{name}'.");

  static const DualKind DUPLICATE_IMPORT = const DualKind(
      error: const MessageKind("Error: Duplicate import of '#{name}'."),
      warning: const MessageKind("Warning: Duplicate import of '#{name}'."));

  static const MessageKind HIDDEN_IMPORT = const MessageKind(
      "Warning: '#{name}' from library '#{hiddenUri}' is hidden by '#{name}' "
      "from library '#{hidingUri}'.",
      howToFix: "Try adding 'hide #{name}' to the import of '#{hiddenUri}'.",
      examples: const [
          const {
'main.dart':
"""
import 'dart:async'; // This imports a class Future.
import 'future.dart';

void main() => new Future();""",

'future.dart':
"""
library future;

class Future {}"""},

          const {
'main.dart':
"""
import 'future.dart';
import 'dart:async'; // This imports a class Future.

void main() => new Future();""",

'future.dart':
"""
library future;

class Future {}"""},

          const {
'main.dart':
"""
import 'export.dart';
import 'dart:async'; // This imports a class Future.

void main() => new Future();""",

'future.dart':
"""
library future;

class Future {}""",

'export.dart':
"""
library export;

export 'future.dart';"""},

         const {
'main.dart':
"""
import 'future.dart' as prefix;
import 'dart:async' as prefix; // This imports a class Future.

void main() => new prefix.Future();""",

'future.dart':
"""
library future;

class Future {}"""}]);


  static const MessageKind HIDDEN_IMPLICIT_IMPORT = const MessageKind(
      "Warning: '#{name}' from library '#{hiddenUri}' is hidden by '#{name}' "
      "from library '#{hidingUri}'.",
      howToFix: "Try adding an explicit "
                "'import \"#{hiddenUri}\" hide #{name}'.",
      examples: const [
          const {
'main.dart':
"""
// This hides the implicit import of class Type from dart:core.
import 'type.dart';

void main() => new Type();""",

'type.dart':
"""
library type;

class Type {}"""},
          const {
'conflictsWithDart.dart':
"""
library conflictsWithDart;

class Duration {
  static var x = 100;
}
""",

'conflictsWithDartAsWell.dart':
"""
library conflictsWithDartAsWell;

class Duration {
  static var x = 100;
}
""",

'main.dart':
r"""
library testDartConflicts;

import 'conflictsWithDart.dart';
import 'conflictsWithDartAsWell.dart';

main() {
  print("Hail Caesar ${Duration.x}");
}
"""}]);

  static const MessageKind DUPLICATE_EXPORT = const MessageKind(
      "Error: Duplicate export of '#{name}'.",
      howToFix: "Trying adding 'hide #{name}' to one of the exports.",
      examples: const [const {
'main.dart': """
export 'decl1.dart';
export 'decl2.dart';

main() {}""",
'decl1.dart': "class Class {}",
'decl2.dart': "class Class {}"}]);

  static const MessageKind DUPLICATE_EXPORT_CONT = const MessageKind(
      "Info: This is another export of '#{name}'.");

  static const MessageKind DUPLICATE_EXPORT_DECL = const MessageKind(
      "Info: The exported '#{name}' from export #{uriString} is defined here.");

  static const DualKind NOT_A_TYPE = const DualKind(
      error: const MessageKind("Error: '#{node}' is not a type."),
      warning: const MessageKind("Warning: '#{node}' is not a type."));

  static const MessageKind NOT_A_PREFIX = const MessageKind(
      "Error: '#{node}' is not a prefix.");

  static const DualKind CANNOT_FIND_CONSTRUCTOR = const DualKind(
      error: const MessageKind(
          "Error: Cannot find constructor '#{constructorName}'."),
      warning: const MessageKind(
          "Warning: Cannot find constructor '#{constructorName}'."));

  static const MessageKind CYCLIC_CLASS_HIERARCHY = const MessageKind(
      "Error: '#{className}' creates a cycle in the class hierarchy.");

  static const MessageKind CYCLIC_REDIRECTING_FACTORY = const MessageKind(
      'Error: Redirecting factory leads to a cyclic redirection.');

  static const MessageKind INVALID_RECEIVER_IN_INITIALIZER = const MessageKind(
      "Error: Field initializer expected.");

  static const MessageKind NO_SUPER_IN_STATIC = const MessageKind(
      "Error: 'super' is only available in instance methods.");

  static const MessageKind DUPLICATE_INITIALIZER = const MessageKind(
      "Error: Field '#{fieldName}' is initialized more than once.");

  static const MessageKind ALREADY_INITIALIZED = const MessageKind(
      "Info: '#{fieldName}' was already initialized here.");

  static const MessageKind INIT_STATIC_FIELD = const MessageKind(
      "Error: Cannot initialize static field '#{fieldName}'.");

  static const MessageKind NOT_A_FIELD = const MessageKind(
      "Error: '#{fieldName}' is not a field.");

  static const MessageKind CONSTRUCTOR_CALL_EXPECTED = const MessageKind(
      "Error: only call to 'this' or 'super' constructor allowed.");

  static const MessageKind INVALID_FOR_IN = const MessageKind(
      "Error: Invalid for-in variable declaration.");

  static const MessageKind INVALID_INITIALIZER = const MessageKind(
      "Error: Invalid initializer.");

  static const MessageKind FUNCTION_WITH_INITIALIZER = const MessageKind(
      "Error: Only constructors can have initializers.");

  static const MessageKind REDIRECTING_CONSTRUCTOR_CYCLE = const MessageKind(
      "Error: Cyclic constructor redirection.");

  static const MessageKind REDIRECTING_CONSTRUCTOR_HAS_BODY = const MessageKind(
      "Error: Redirecting constructor can't have a body.");

  static const MessageKind CONST_CONSTRUCTOR_HAS_BODY = const MessageKind(
      "Error: Const constructor or factory can't have a body.",
      howToFix: "Remove the 'const' keyword or the body",
      examples: const ["""
class C {
  const C() {}
}

main() => new C();"""]);

  static const MessageKind REDIRECTING_CONSTRUCTOR_HAS_INITIALIZER =
      const MessageKind(
          "Error: Redirecting constructor cannot have other initializers.");

  static const MessageKind SUPER_INITIALIZER_IN_OBJECT = const MessageKind(
      "Error: 'Object' cannot have a super initializer.");

  static const MessageKind DUPLICATE_SUPER_INITIALIZER = const MessageKind(
      "Error: Cannot have more than one super initializer.");

  static const DualKind INVALID_ARGUMENTS = const DualKind(
      error: const MessageKind(
          "Error: Arguments do not match the expected parameters of "
          "'#{methodName}'."),
      warning: const MessageKind(
          "Warning: Arguments do not match the expected parameters of "
          "'#{methodName}'."));

  static const MessageKind NO_MATCHING_CONSTRUCTOR = const MessageKind(
      "Error: 'super' call arguments and constructor parameters do not match.");

  static const MessageKind NO_MATCHING_CONSTRUCTOR_FOR_IMPLICIT =
      const MessageKind(
          "Error: Implicit 'super' call arguments and constructor parameters "
          "do not match.");

  static const MessageKind CONST_CALLS_NON_CONST = const MessageKind(
      "Error: 'const' constructor cannot call a non-const constructor.");

  static const MessageKind CONST_CONSTRUCTOR_WITH_NONFINAL_FIELDS =
      const MessageKind(
          "Error: Can't declare constructor 'const' on class #{className} "
          "because the class contains non-final instance fields.",
          howToFix: "Try making all fields final.",
          examples: const ["""
class C {
  // 'a' must be declared final to allow for the const constructor.
  var a;
  const C(this.a);
}

main() => new C(0);"""]);

  static const MessageKind CONST_CONSTRUCTOR_WITH_NONFINAL_FIELDS_FIELD =
      const MessageKind("Info: This non-final field prevents using const "
                        "constructors.");

  static const MessageKind CONST_CONSTRUCTOR_WITH_NONFINAL_FIELDS_CONSTRUCTOR =
      const MessageKind("Info: This const constructor is not allowed due to "
                        "non-final fields.");


  static const MessageKind INITIALIZING_FORMAL_NOT_ALLOWED = const MessageKind(
      "Error: Initializing formal parameter only allowed in generative "
      "constructor.");

  static const MessageKind INVALID_PARAMETER = const MessageKind(
      "Error: Cannot resolve parameter.");

  static const MessageKind NOT_INSTANCE_FIELD = const MessageKind(
      "Error: '#{fieldName}' is not an instance field.");

  static const MessageKind NO_CATCH_NOR_FINALLY = const MessageKind(
      "Error: Expected 'catch' or 'finally'.");

  static const MessageKind EMPTY_CATCH_DECLARATION = const MessageKind(
      "Error: Expected an identifier in catch declaration.");

  static const MessageKind EXTRA_CATCH_DECLARATION = const MessageKind(
      "Error: Extra parameter in catch declaration.");

  static const MessageKind PARAMETER_WITH_TYPE_IN_CATCH = const MessageKind(
      "Error: Cannot use type annotations in catch.");

  static const MessageKind PARAMETER_WITH_MODIFIER_IN_CATCH = const MessageKind(
      "Error: Cannot use modifiers in catch.");

  static const MessageKind OPTIONAL_PARAMETER_IN_CATCH = const MessageKind(
      "Error: Cannot use optional parameters in catch.");

  static const MessageKind THROW_WITHOUT_EXPRESSION = const MessageKind(
      "Error: Cannot use re-throw outside of catch block "
      "(expression expected after 'throw').");

  static const MessageKind UNBOUND_LABEL = const MessageKind(
      "Error: Cannot resolve label '#{labelName}'.");

  static const MessageKind NO_BREAK_TARGET = const MessageKind(
      "Error: 'break' statement not inside switch or loop.");

  static const MessageKind NO_CONTINUE_TARGET = const MessageKind(
      "Error: 'continue' statement not inside loop.");

  static const MessageKind EXISTING_LABEL = const MessageKind(
      "Info: Original declaration of duplicate label '#{labelName}'.");

  static const DualKind DUPLICATE_LABEL = const DualKind(
      error: const MessageKind(
          "Error: Duplicate declaration of label '#{labelName}'."),
      warning: const MessageKind(
          "Warning: Duplicate declaration of label '#{labelName}'."));

  static const MessageKind UNUSED_LABEL = const MessageKind(
      "Warning: Unused label '#{labelName}'.");

  static const MessageKind INVALID_CONTINUE = const MessageKind(
      "Error: Target of continue is not a loop or switch case.");

  static const MessageKind INVALID_BREAK = const MessageKind(
      "Error: Target of break is not a statement.");

  static const MessageKind DUPLICATE_TYPE_VARIABLE_NAME = const MessageKind(
      "Error: Type variable '#{typeVariableName}' already declared.");

  static const DualKind TYPE_VARIABLE_WITHIN_STATIC_MEMBER = const DualKind(
      error: const MessageKind(
          "Error: Cannot refer to type variable '#{typeVariableName}' "
          "within a static member."),
      warning: const MessageKind(
          "Warning: Cannot refer to type variable '#{typeVariableName}' "
          "within a static member."));

  static const MessageKind TYPE_VARIABLE_IN_CONSTANT = const MessageKind(
      "Error: Constant expressions can't refer to type variables.",
      howToFix: "Try removing the type variable or replacing it with a "
                "concrete type.",
      examples: const ["""
class C<T> {
  const C();

  m(T t) => const C<T>();
}

void main() => new C().m(null);  
"""
]);


  static const MessageKind INVALID_TYPE_VARIABLE_BOUND = const MessageKind(
      "Warning: '#{typeArgument}' is not a subtype of bound '#{bound}' for "
      "type variable '#{typeVariable}' of type '#{thisType}'.",
      howToFix: "Try to change or remove the type argument.",
      examples: const ["""
class C<T extends num> {}

// 'String' is not a valid instantiation of T with bound num.'.
main() => new C<String>();
"""]);

  static const MessageKind INVALID_USE_OF_SUPER = const MessageKind(
      "Error: 'super' not allowed here.");

  static const MessageKind INVALID_CASE_DEFAULT = const MessageKind(
      "Error: 'default' only allowed on last case of a switch.");

  static const MessageKind SWITCH_CASE_TYPES_NOT_EQUAL = const MessageKind(
      "Error: 'case' expressions do not all have type '#{type}'.");

  static const MessageKind SWITCH_CASE_TYPES_NOT_EQUAL_CASE = const MessageKind(
      "Info: 'case' expression of type '#{type}'.");

  static const MessageKind SWITCH_CASE_VALUE_OVERRIDES_EQUALS =
      const MessageKind(
          "Error: 'case' expression type overrides 'operator=='.");

  static const MessageKind INVALID_ARGUMENT_AFTER_NAMED = const MessageKind(
      "Error: Unnamed argument after named argument.");

  static const MessageKind NOT_A_COMPILE_TIME_CONSTANT = const MessageKind(
      "Error: Not a compile-time constant.");

  static const MessageKind CYCLIC_COMPILE_TIME_CONSTANTS = const MessageKind(
      "Error: Cycle in the compile-time constant computation.");

  static const MessageKind CONSTRUCTOR_IS_NOT_CONST = const MessageKind(
      "Error: Constructor is not a 'const' constructor.");

  static const MessageKind KEY_NOT_A_STRING_LITERAL = const MessageKind(
      "Error: Map-literal key not a string literal.");

  static const DualKind NO_SUCH_LIBRARY_MEMBER = const DualKind(
      error: const MessageKind(
          "Error: '#{libraryName}' has no member named '#{memberName}'."),
      warning: const MessageKind(
          "Warning: '#{libraryName}' has no member named '#{memberName}'."));

  static const MessageKind CANNOT_INSTANTIATE_TYPEDEF = const MessageKind(
      "Error: Cannot instantiate typedef '#{typedefName}'.");

  static const MessageKind REQUIRED_PARAMETER_WITH_DEFAULT = const MessageKind(
      "Error: Non-optional parameters can't have a default value.",
      howToFix:
        "Try removing the default value or making the parameter optional.",
      examples: const ["""
main() {
  foo(a: 1) => print(a);
  foo(2);
}""", """
main() {
  foo(a = 1) => print(a);
  foo(2);
}"""]);

  static const MessageKind NAMED_PARAMETER_WITH_EQUALS = const MessageKind(
      "Error: Named optional parameters can't use '=' to specify a default "
      "value.",
      howToFix: "Try replacing '=' with ':'.",
      examples: const ["""
main() {
  foo({a = 1}) => print(a);
  foo(a: 2);
}"""]);

  static const MessageKind POSITIONAL_PARAMETER_WITH_EQUALS = const MessageKind(
      "Error: Positional optional parameters can't use ':' to specify a "
      "default value.",
      howToFix: "Try replacing ':' with '='.",
      examples: const ["""
main() {
  foo([a: 1]) => print(a);
  foo(2);
}"""]);

  static const MessageKind TYPEDEF_FORMAL_WITH_DEFAULT = const MessageKind(
      "Error: A parameter of a typedef can't specify a default value.",
      howToFix:
        "Try removing the default value.",
      examples: const ["""
typedef void F([int arg = 0]);

main() {
  F f;
}""", """
typedef void F({int arg: 0});

main() {
  F f;
}"""]);

  static const MessageKind FUNCTION_TYPE_FORMAL_WITH_DEFAULT = const MessageKind(
      "Error: A function type parameter can't specify a default value.",
      howToFix:
        "Try removing the default value.",
      examples: const ["""
foo(f(int i, [a = 1])) {}

main() {
  foo(1, 2);
}""", """
foo(f(int i, {a: 1})) {}

main() {
  foo(1, a: 2);
}"""]);

  static const MessageKind REDIRECTING_FACTORY_WITH_DEFAULT = const MessageKind(
      "Error: A parameter of a redirecting factory constructor can't specify a "
      "default value.",
      howToFix:
        "Try removing the default value.",
      examples: const ["""
class A {
  A([a]);
  factory A.foo([a = 1]) = A;
}

main() {
  new A.foo(1);
}""", """
class A {
  A({a});
  factory A.foo({a: 1}) = A;
}

main() {
  new A.foo(a: 1);
}"""]);

  static const MessageKind FORMAL_DECLARED_CONST = const MessageKind(
      "Error: A formal parameter can't be declared const.",
      howToFix: "Try removing 'const'.",
      examples: const ["""
foo(const x) {}
main() => foo(42);
""", """
foo({const x}) {}
main() => foo(42);
""", """
foo([const x]) {}
main() => foo(42);
"""]);

  static const MessageKind FORMAL_DECLARED_STATIC = const MessageKind(
      "Error: A formal parameter can't be declared static.",
      howToFix: "Try removing 'static'.",
      examples: const ["""
foo(static x) {}
main() => foo(42);
""", """
foo({static x}) {}
main() => foo(42);
""", """
foo([static x]) {}
main() => foo(42);
"""]);

  static const MessageKind FINAL_FUNCTION_TYPE_PARAMETER = const MessageKind(
      "Error: A function type parameter can't be declared final.",
      howToFix: "Try removing 'final'.",
      examples: const ["""
foo(final int x(int a)) {}
main() => foo((y) => 42);
""", """
foo({final int x(int a)}) {}
main() => foo((y) => 42);
""", """
foo([final int x(int a)]) {}
main() => foo((y) => 42);
"""]);

  static const MessageKind VAR_FUNCTION_TYPE_PARAMETER = const MessageKind(
      "Error: A function type parameter can't be declared with 'var'.",
      howToFix: "Try removing 'var'.",
      examples: const ["""
foo(var int x(int a)) {}
main() => foo((y) => 42);
""", """
foo({var int x(int a)}) {}
main() => foo((y) => 42);
""", """
foo([var int x(int a)]) {}
main() => foo((y) => 42);
"""]);

  static const MessageKind CANNOT_INSTANTIATE_TYPE_VARIABLE = const MessageKind(
      "Error: Cannot instantiate type variable '#{typeVariableName}'.");

  static const MessageKind CYCLIC_TYPE_VARIABLE = const MessageKind(
      "Warning: Type variable '#{typeVariableName}' is a supertype of itself.");

  static const CYCLIC_TYPEDEF = const MessageKind(
      "Error: A typedef can't refer to itself.",
      howToFix: "Try removing all references to '#{typedefName}' "
                "in the definition of '#{typedefName}'.",
      examples: const ["""
typedef F F(); // The return type 'F' is a self-reference.
main() { F f = null; }"""]);

  static const CYCLIC_TYPEDEF_ONE = const MessageKind(
      "Error: A typedef can't refer to itself through another typedef.",
      howToFix: "Try removing all references to "
                "'#{otherTypedefName}' in the definition of '#{typedefName}'.",
      examples: const ["""
typedef G F(); // The return type 'G' is a self-reference through typedef 'G'.
typedef F G(); // The return type 'F' is a self-reference through typedef 'F'.
main() { F f = null; }""",
"""
typedef G F(); // The return type 'G' creates a self-reference.
typedef H G(); // The return type 'H' creates a self-reference.
typedef H(F f); // The argument type 'F' creates a self-reference.
main() { F f = null; }"""]);

  static const MessageKind CLASS_NAME_EXPECTED = const MessageKind(
      "Error: Class name expected.");

  static const MessageKind CANNOT_EXTEND = const MessageKind(
      "Error: '#{type}' cannot be extended.");

  static const MessageKind CANNOT_IMPLEMENT = const MessageKind(
      "Error: '#{type}' cannot be implemented.");

  static const MessageKind CANNOT_EXTEND_MALFORMED = const MessageKind(
      "Error: A class can't extend a malformed type.",
      howToFix: "Try correcting the malformed type annotation or removing the "
        "'extends' clause.",
      examples: const ["""
class A extends Malformed {}
main() => new A();"""]);

  static const MessageKind CANNOT_IMPLEMENT_MALFORMED = const MessageKind(
      "Error: A class can't implement a malformed type.",
      howToFix: "Try correcting the malformed type annotation or removing the "
        "type from the 'implements' clause.",
      examples: const ["""
class A implements Malformed {}
main() => new A();"""]);

  static const MessageKind CANNOT_MIXIN_MALFORMED = const MessageKind(
      "Error: A class can't mixin a malformed type.",
      howToFix: "Try correcting the malformed type annotation or removing the "
        "type from the 'with' clause.",
      examples: const ["""
class A extends Object with Malformed {}
main() => new A();"""]);

  static const MessageKind CANNOT_MIXIN = const MessageKind(
      "Error: The type '#{type}' can't be mixed in.",
      howToFix: "Try removing '#{type}' from the 'with' clause.",
      examples: const ["""
class C extends Object with String {}

main() => new C();
""", """
typedef C = Object with String;

main() => new C();
"""]);

  static const MessageKind DUPLICATE_EXTENDS_IMPLEMENTS = const MessageKind(
      "Error: '#{type}' can not be both extended and implemented.");

  static const MessageKind DUPLICATE_IMPLEMENTS = const MessageKind(
      "Error: '#{type}' must not occur more than once "
      "in the implements clause.");

  static const MessageKind MULTI_INHERITANCE = const MessageKind(
      "Internal Error: Inheritance of the same class with different type "
      "arguments is not supported: Both #{firstType} and #{secondType} are "
      "supertypes of #{thisType}.");

  static const MessageKind ILLEGAL_SUPER_SEND = const MessageKind(
      "Error: '#{name}' cannot be called on super.");

  static const DualKind NO_SUCH_SUPER_MEMBER = const DualKind(
      error: const MessageKind(
          "Error: Cannot resolve '#{memberName}' in a superclass of "
          "'#{className}'."),
      warning: const MessageKind(
          "Warning: Cannot resolve '#{memberName}' in a superclass of "
          "'#{className}'."));

  static const DualKind ADDITIONAL_TYPE_ARGUMENT = const DualKind(
      error: const MessageKind("Error: Additional type argument."),
      warning: const MessageKind("Warning: Additional type argument."));

  static const DualKind MISSING_TYPE_ARGUMENT = const DualKind(
      error: const MessageKind("Error: Missing type argument."),
      warning: const MessageKind("Warning: Missing type argument."));

  // TODO(johnniwinther): Use ADDITIONAL_TYPE_ARGUMENT or MISSING_TYPE_ARGUMENT
  // instead.
  static const MessageKind TYPE_ARGUMENT_COUNT_MISMATCH = const MessageKind(
      "Error: Incorrect number of type arguments on '#{type}'.");

  static const MessageKind GETTER_MISMATCH = const MessageKind(
      "Error: Setter disagrees on: '#{modifiers}'.");

  static const MessageKind SETTER_MISMATCH = const MessageKind(
      "Error: Getter disagrees on: '#{modifiers}'.");

  static const MessageKind ILLEGAL_SETTER_FORMALS = const MessageKind(
      "Error: A setter must have exactly one argument.");

  static const MessageKind NO_STATIC_OVERRIDE = const MessageKind(
      "Error: Static member cannot override instance member '#{memberName}' of "
      "'#{className}'.");

  static const MessageKind NO_STATIC_OVERRIDE_CONT = const MessageKind(
      "Info: This is the instance member that cannot be overridden "
      "by a static member.");

  static const MessageKind CANNOT_OVERRIDE_FIELD_WITH_METHOD =
      const MessageKind(
          "Error: Method cannot override field '#{memberName}' of "
          "'#{className}'.");

  static const MessageKind CANNOT_OVERRIDE_FIELD_WITH_METHOD_CONT =
      const MessageKind(
          "Info: This is the field that cannot be overridden by a method.");

  static const MessageKind CANNOT_OVERRIDE_METHOD_WITH_FIELD =
      const MessageKind(
          "Error: Field cannot override method '#{memberName}' of "
          "'#{className}'.");

  static const MessageKind CANNOT_OVERRIDE_METHOD_WITH_FIELD_CONT =
      const MessageKind(
          "Info: This is the method that cannot be overridden by a field.");

  static const MessageKind BAD_ARITY_OVERRIDE = const MessageKind(
      "Error: Cannot override method '#{memberName}' in '#{className}'; "
      "the parameters do not match.");

  static const MessageKind BAD_ARITY_OVERRIDE_CONT = const MessageKind(
      "Info: This is the method whose parameters do not match.");

  static const MessageKind MISSING_FORMALS = const MessageKind(
      "Error: Formal parameters are missing.");

  static const MessageKind EXTRA_FORMALS = const MessageKind(
      "Error: Formal parameters are not allowed here.");

  static const MessageKind UNARY_OPERATOR_BAD_ARITY = const MessageKind(
      "Error: Operator '#{operatorName}' must have no parameters.");

  static const MessageKind MINUS_OPERATOR_BAD_ARITY = const MessageKind(
      "Error: Operator '-' must have 0 or 1 parameters.");

  static const MessageKind BINARY_OPERATOR_BAD_ARITY = const MessageKind(
      "Error: Operator '#{operatorName}' must have exactly 1 parameter.");

  static const MessageKind TERNARY_OPERATOR_BAD_ARITY = const MessageKind(
      "Error: Operator '#{operatorName}' must have exactly 2 parameters.");

  static const MessageKind OPERATOR_OPTIONAL_PARAMETERS = const MessageKind(
      "Error: Operator '#{operatorName}' cannot have optional parameters.");

  static const MessageKind OPERATOR_NAMED_PARAMETERS = const MessageKind(
      "Error: Operator '#{operatorName}' cannot have named parameters.");

  static const MessageKind CONSTRUCTOR_WITH_RETURN_TYPE = const MessageKind(
      "Error: Cannot have return type for constructor.");

  static const MessageKind CANNOT_RETURN_FROM_CONSTRUCTOR = const MessageKind(
      "Error: Constructors can't return values.",
      howToFix: "Remove the return statement or use a factory constructor.",
      examples: const ["""
class C {
  C() {
    return 1;
  }
}

main() => new C();"""]);

  static const MessageKind ILLEGAL_FINAL_METHOD_MODIFIER = const MessageKind(
      "Error: Cannot have final modifier on method.");

  static const MessageKind ILLEGAL_CONSTRUCTOR_MODIFIERS = const MessageKind(
      "Error: Illegal constructor modifiers: '#{modifiers}'.");

  static const MessageKind ILLEGAL_MIXIN_APPLICATION_MODIFIERS =
      const MessageKind(
          "Error: Illegal mixin application modifiers: '#{modifiers}'.");

  static const MessageKind ILLEGAL_MIXIN_SUPERCLASS = const MessageKind(
      "Error: Class used as mixin must have Object as superclass.");

  static const MessageKind ILLEGAL_MIXIN_OBJECT = const MessageKind(
      "Error: Cannot use Object as mixin.");

  static const MessageKind ILLEGAL_MIXIN_CONSTRUCTOR = const MessageKind(
      "Error: Class used as mixin cannot have non-factory constructor.");

  static const MessageKind ILLEGAL_MIXIN_CYCLE = const MessageKind(
      "Error: Class used as mixin introduces mixin cycle: "
      "'#{mixinName1}' <-> '#{mixinName2}'.");

  static const MessageKind ILLEGAL_MIXIN_WITH_SUPER = const MessageKind(
      "Error: Cannot use class '#{className}' as a mixin because it uses "
      "'super'.");

  static const MessageKind ILLEGAL_MIXIN_SUPER_USE = const MessageKind(
      "Info: Use of 'super' in class used as mixin.");

  static const MessageKind PARAMETER_NAME_EXPECTED = const MessageKind(
      "Error: parameter name expected.");

  static const DualKind CANNOT_RESOLVE_GETTER = const DualKind(
      error: const MessageKind("Error: Cannot resolve getter."),
      warning: const MessageKind("Warning: Cannot resolve getter."));

  static const DualKind CANNOT_RESOLVE_SETTER = const DualKind(
      error: const MessageKind("Error: Cannot resolve setter."),
      warning: const MessageKind("Warning: Cannot resolve setter."));

  static const MessageKind VOID_NOT_ALLOWED = const MessageKind(
      "Error: Type 'void' can't be used here because it isn't a return type.",
      howToFix: "Try removing 'void' keyword or replace it with 'var', 'final',"
          " or a type.",
      examples: const [
          "void x; main() {}",
          "foo(void x) {} main() { foo(null); }",
      ]);

  static const MessageKind NULL_NOT_ALLOWED = const MessageKind(
      "Error: `null` can't be used here.");

  static const MessageKind BEFORE_TOP_LEVEL = const MessageKind(
      "Error: Part header must come before top-level definitions.");

  static const MessageKind LIBRARY_NAME_MISMATCH = const MessageKind(
      "Warning: Expected part of library name '#{libraryName}'.");

  static const MessageKind MISSING_PART_OF_TAG = const MessageKind(
      "Error: This file has no part-of tag, but it is being used as a part.");

  static const MessageKind DUPLICATED_PART_OF = const MessageKind(
      "Error: Duplicated part-of directive.");

  static const MessageKind ILLEGAL_DIRECTIVE = const MessageKind(
      "Error: Directive not allowed here.");

  static const MessageKind DUPLICATED_LIBRARY_NAME = const MessageKind(
      "Warning: Duplicated library name '#{libraryName}'.");

  // This is used as an exception.
  static const MessageKind INVALID_SOURCE_FILE_LOCATION = const MessageKind('''
Invalid offset (#{offset}) in source map.
File: #{fileName}
Length: #{length}''');

  static const MessageKind TOP_LEVEL_VARIABLE_DECLARED_STATIC =
      const MessageKind(
          "Error: Top-level variable cannot be declared static.");

  static const MessageKind REFERENCE_IN_INITIALIZATION = const MessageKind(
       "Error: Variable '#{variableName}' is referenced during its "
       "initialization.",
       howToFix: "If you are trying to reference a shadowed variable, rename"
         " one of the variables.",
       examples: const ["""
foo(t) {
  var t = t;
  return t;
}

main() => foo(1);
"""]);

  static const MessageKind CONST_WITHOUT_INITIALIZER = const MessageKind(
      "Error: A constant variable must be initialized.",
      howToFix: "Try adding an initializer or "
                "removing the 'const' modifier.",
      examples: const ["""
void main() {
  const c; // This constant variable must be initialized.
}"""]);

  static const MessageKind FINAL_WITHOUT_INITIALIZER = const MessageKind(
      "Error: A final variable must be initialized.",
      howToFix: "Try adding an initializer or "
                "removing the 'final' modifier.",
      examples: const [
          "class C { static final field; } main() => C.field;"]);

  static const MessageKind MEMBER_USES_CLASS_NAME = const MessageKind(
      "Error: Member variable can't have the same name as the class it is "
      "declared in.",
      howToFix: "Try renaming the variable.",
      examples: const ["""
class A { var A; }
main() {
  var a = new A();
  a.A = 1;
}
""", """
class A { static var A; }
main() => A.A = 1;
"""]);

  static const MessageKind WRONG_NUMBER_OF_ARGUMENTS_FOR_ASSERT =
      const MessageKind(
          "Error: Wrong number of arguments to assert. Should be 1, but given "
          "#{argumentCount}.");

  static const MessageKind ASSERT_IS_GIVEN_NAMED_ARGUMENTS = const MessageKind(
      "Error: 'assert' takes no named arguments, but given #{argumentCount}.");

  static const MessageKind FACTORY_REDIRECTION_IN_NON_FACTORY =
      const MessageKind(
          "Error: Factory redirection only allowed in factories.");

  static const MessageKind MISSING_FACTORY_KEYWORD = const MessageKind(
      "Hint: Did you forget a factory keyword here?");

  static const MessageKind DEFERRED_LIBRARY_NAME_MISMATCH =
      const MessageKind(
          "Error: Library name mismatch '#{expectedName}' != '#{actualName}'.");

  static const MessageKind ILLEGAL_STATIC = const MessageKind(
      "Error: Modifier static is only allowed on functions declared in "
      "a class.");

  static const MessageKind STATIC_FUNCTION_BLOAT = const MessageKind(
      "Hint: Using '#{class}.#{name}' may result in larger output.");

  static const MessageKind NON_CONST_BLOAT = const MessageKind('''
Hint: Using "new #{name}' may result in larger output.
Use 'const #{name}' if possible.''');

  static const MessageKind STRING_EXPECTED = const MessageKind(
      "Error: Expected a 'String', but got an instance of '#{type}'.");

  static const MessageKind PRIVATE_IDENTIFIER = const MessageKind(
      "Error: '#{value}' is not a valid Symbol name because it starts with "
      "'_'.");

  static const MessageKind PRIVATE_NAMED_PARAMETER = const MessageKind(
      "Error: Named optional parameter can't have a library private name.",
      howToFix: "Try removing the '_' or making the parameter positional or "
        "required.",
      examples: const ["""foo({int _p}) {} main() => foo();"""]
      );

  static const MessageKind UNSUPPORTED_LITERAL_SYMBOL = const MessageKind(
      "Internal Error: Symbol literal '##{value}' is currently unsupported.");

  static const MessageKind INVALID_SYMBOL = const MessageKind('''
Error: '#{value}' is not a valid Symbol name because is not:
 * an empty String,
 * a user defined operator,
 * a qualified non-private identifier optionally followed by '=', or
 * a qualified non-private identifier followed by '.' and a user-defined '''
"operator.");

  static const MessageKind AMBIGUOUS_REEXPORT = const MessageKind(
      "Info: '#{name}' is (re)exported by multiple libraries.");

  static const MessageKind AMBIGUOUS_LOCATION = const MessageKind(
      "Info: '#{name}' is defined here.");

  static const MessageKind IMPORTED_HERE = const MessageKind(
      "Info: '#{name}' is imported here.");

  static const MessageKind OVERRIDE_EQUALS_NOT_HASH_CODE = const MessageKind(
      "Hint: The class '#{class}' overrides 'operator==', "
      "but not 'get hashCode'.");

  static const MessageKind PACKAGE_ROOT_NOT_SET = const MessageKind(
      "Error: Cannot resolve '#{uri}'. Package root has not been set.");

  static const MessageKind INTERNAL_LIBRARY_FROM = const MessageKind(
      "Error: Internal library '#{resolvedUri}' is not accessible from "
      "'#{importingUri}'.");

  static const MessageKind INTERNAL_LIBRARY = const MessageKind(
      "Error: Internal library '#{resolvedUri}' is not accessible.");

  static const MessageKind LIBRARY_NOT_FOUND = const MessageKind(
      "Error: Library not found '#{resolvedUri}'.");

  static const MessageKind UNSUPPORTED_EQ_EQ_EQ = const MessageKind(
      "Error: '===' is not an operator. "
      "Did you mean '#{lhs} == #{rhs}' or 'identical(#{lhs}, #{rhs})'?");

  static const MessageKind UNSUPPORTED_BANG_EQ_EQ = const MessageKind(
      "Error: '!==' is not an operator. "
      "Did you mean '#{lhs} != #{rhs}' or '!identical(#{lhs}, #{rhs})'?");

  static const MessageKind UNSUPPORTED_PREFIX_PLUS = const MessageKind(
      "Error: '+' is not a prefix operator. ",
      howToFix: "Try removing '+'.",
      examples: const [
          "main() => +2;  // No longer a valid way to write '2'"
      ]);

  static const MessageKind UNSUPPORTED_THROW_WITHOUT_EXP = const MessageKind(
      "Error: No expression after 'throw'. "
      "Did you mean 'rethrow'?");

  static const MessageKind DEPRECATED_TYPEDEF_MIXIN_SYNTAX = const MessageKind(
      "Warning: 'typedef' not allowed here. ",
      howToFix: "Try replacing 'typedef' with 'class'.",
      examples: const [
          """
class B { }
class M1 {  }
typedef C = B with M1;  // Need to replace 'typedef' with 'class'.
main() { new C(); }
"""]
);

  static const MessageKind MIRRORS_EXPECTED_STRING = const MessageKind(
      "Hint: Can't use '#{name}' here because it's an instance of '#{type}' "
      "and a 'String' value is expected.",
      howToFix: "Did you forget to add quotes?",
      examples: const [
          """
// 'Foo' is a type literal, not a string.
@MirrorsUsed(symbols: const [Foo])
import 'dart:mirrors';

class Foo {}

main() {}
"""]);

  static const MessageKind MIRRORS_EXPECTED_STRING_OR_TYPE = const MessageKind(
      "Hint: Can't use '#{name}' here because it's an instance of '#{type}' "
      "and a 'String' or 'Type' value is expected.",
      howToFix: "Did you forget to add quotes?",
      examples: const [
          """
// 'main' is a method, not a class.
@MirrorsUsed(targets: const [main])
import 'dart:mirrors';

main() {}
"""]);

  static const MessageKind MIRRORS_EXPECTED_STRING_OR_LIST = const MessageKind(
      "Hint: Can't use '#{name}' here because it's an instance of '#{type}' "
      "and a 'String' or 'List' value is expected.",
      howToFix: "Did you forget to add quotes?",
      examples: const [
          """
// 'Foo' is not a string.
@MirrorsUsed(symbols: Foo)
import 'dart:mirrors';

class Foo {}

main() {}
"""]);

  static const MessageKind MIRRORS_EXPECTED_STRING_TYPE_OR_LIST =
      const MessageKind(
      "Hint: Can't use '#{name}' here because it's an instance of '#{type}' "
      "but a 'String', 'Type', or 'List' value is expected.",
      howToFix: "Did you forget to add quotes?",
      examples: const [
          """
// '1' is not a string.
@MirrorsUsed(targets: 1)
import 'dart:mirrors';

main() {}
"""]);

  static const MessageKind MIRRORS_CANNOT_RESOLVE_IN_CURRENT_LIBRARY =
      const MessageKind(
      "Hint: Can't find '#{name}' in the current library.",
      // TODO(ahe): The closest identifiers in edit distance would be nice.
      howToFix: "Did you forget to add an import?",
      examples: const [
          """
// 'window' is not in scope because dart:html isn't imported.
@MirrorsUsed(targets: 'window')
import 'dart:mirrors';

main() {}
"""]);

  static const MessageKind MIRRORS_CANNOT_RESOLVE_IN_LIBRARY =
      const MessageKind(
      "Hint: Can't find '#{name}' in the library '#{library}'.",
      // TODO(ahe): The closest identifiers in edit distance would be nice.
      howToFix: "Is '#{name}' spelled right?",
      examples: const [
          """
// 'List' is misspelled.
@MirrorsUsed(targets: 'dart.core.Lsit')
import 'dart:mirrors';

main() {}
"""]);

  static const MessageKind MIRRORS_CANNOT_FIND_IN_ELEMENT =
      const MessageKind(
      "Hint: Can't find '#{name}' in '#{element}'.",
      // TODO(ahe): The closest identifiers in edit distance would be nice.
      howToFix: "Is '#{name}' spelled right?",
      examples: const [
          """
// 'addAll' is misspelled.
@MirrorsUsed(targets: 'dart.core.List.addAl')
import 'dart:mirrors';

main() {}
"""]);

  static const MessageKind READ_SCRIPT_ERROR = const MessageKind(
      "Error: Can't read '#{uri}' (#{exception}).",
      // Don't know how to fix since the underlying error is unknown.
      howToFix: DONT_KNOW_HOW_TO_FIX,
      examples: const [
          """
// 'foo.dart' does not exist.
import 'foo.dart';

main() {}
"""]);

  static const MessageKind EXTRANEOUS_MODIFIER = const MessageKind(
      "Error: Can't have modifier '#{modifier}' here.",
      howToFix: "Try removing '#{modifier}'.",
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
          "external var foo; main(){}"]);

  static const MessageKind EXTRANEOUS_MODIFIER_REPLACE = const MessageKind(
      "Error: Can't have modifier '#{modifier}' here.",
      howToFix: "Try replacing modifier '#{modifier}' with 'var', 'final',"
          " or a type.",
      examples: const [
          // "get foo; main(){}",
          "set foo; main(){}",
          "abstract foo; main(){}",
          "static foo; main(){}",
          "external foo; main(){}"]);

  static const MessageKind ABSTRACT_CLASS_INSTANTIATION = const MessageKind(
      "Warning: Can't instantiate abstract class.",
      howToFix: DONT_KNOW_HOW_TO_FIX,
      examples: const ["abstract class A {} main() { new A(); }"]);

  static const MessageKind BODY_EXPECTED = const MessageKind(
      "Error: Expected a function body or '=>'.",
      // TODO(ahe): In some scenarios, we can suggest removing the 'static'
      // keyword.
      howToFix: "Try adding {}.",
      examples: const [
          "main();"]);

  static const MessageKind MIRROR_BLOAT = const MessageKind(
      "Hint: #{count} methods retained for use by dart:mirrors out of #{total}"
      " total methods (#{percentage}%).");

  static const MessageKind MIRROR_IMPORT = const MessageKind(
      "Info: Import of 'dart:mirrors'.");

  static const MessageKind WRONG_ARGUMENT_FOR_JS_INTERCEPTOR_CONSTANT =
      const MessageKind(
      "Error: Argument for 'JS_INTERCEPTOR_CONSTANT' must be a type constant.");

  static const MessageKind COMPILER_CRASHED = const MessageKind(
      "Error: The compiler crashed when compiling this element.");

  static const MessageKind PLEASE_REPORT_THE_CRASH = const MessageKind('''
The compiler is broken.

When compiling the above element, the compiler crashed. It is not
possible to tell if this is caused by a problem in your program or
not. Regardless, the compiler should not crash.

The Dart team would greatly appreciate if you would take a moment to
report this problem at http://dartbug.com/new.

Please include the following information:

* the name and version of your operating system,

* the Dart SDK build number (#{buildId}), and

* the entire message you see here (including the full stack trace
  below as well as the source location above).
''');

  static const MessageKind POTENTIAL_MUTATION = const MessageKind(
      "Hint: Variable '#{variableName}' is not known to be of type "
      "'#{shownType}' because it is potentially mutated in the scope for "
      "promotion.");

  static const MessageKind POTENTIAL_MUTATION_HERE = const MessageKind(
      "Info: Variable '#{variableName}' is potentially mutated here.");

  static const MessageKind POTENTIAL_MUTATION_IN_CLOSURE = const MessageKind(
      "Hint: Variable '#{variableName}' is not known to be of type "
      "'#{shownType}' because it is potentially mutated within a closure.");

  static const MessageKind POTENTIAL_MUTATION_IN_CLOSURE_HERE =
      const MessageKind(
          "Info: Variable '#{variableName}' is potentially mutated in a "
          "closure here.");

  static const MessageKind ACCESSED_IN_CLOSURE = const MessageKind(
      "Hint: Variable '#{variableName}' is not known to be of type "
      "'#{shownType}' because it is accessed by a closure in the scope for "
      "promotion and potentially mutated in the scope of '#{variableName}'.");

  static const MessageKind ACCESSED_IN_CLOSURE_HERE = const MessageKind(
      "Info: Variable '#{variableName}' is accessed in a closure here.");

  static const MessageKind NOT_MORE_SPECIFIC = const MessageKind(
      "Hint: Variable '#{variableName}' is not shown to have type "
      "'#{shownType}' because '#{shownType}' is not more specific than the "
      "known type '#{knownType}' of '#{variableName}'.");

  //////////////////////////////////////////////////////////////////////////////
  // Patch errors start.
  //////////////////////////////////////////////////////////////////////////////

  static const MessageKind PATCH_RETURN_TYPE_MISMATCH = const MessageKind(
      "Error: Patch return type '#{patchReturnType}' does not match "
      "'#{originReturnType}' on origin method '#{methodName}'.");

  static const MessageKind PATCH_REQUIRED_PARAMETER_COUNT_MISMATCH =
      const MessageKind(
          "Error: Required parameter count of patch method "
          "(#{patchParameterCount}) does not match parameter count on origin "
          "method '#{methodName}' (#{originParameterCount}).");

  static const MessageKind PATCH_OPTIONAL_PARAMETER_COUNT_MISMATCH =
      const MessageKind(
          "Error: Optional parameter count of patch method "
          "(#{patchParameterCount}) does not match parameter count on origin "
          "method '#{methodName}' (#{originParameterCount}).");

  static const MessageKind PATCH_OPTIONAL_PARAMETER_NAMED_MISMATCH =
      const MessageKind(
          "Error: Optional parameters of origin and patch method "
          "'#{methodName}' must both be either named or positional.");

  static const MessageKind PATCH_PARAMETER_MISMATCH = const MessageKind(
      "Error: Patch method parameter '#{patchParameter}' does not match "
      "'#{originParameter}' on origin method '#{methodName}'.");

  static const MessageKind PATCH_PARAMETER_TYPE_MISMATCH = const MessageKind(
      "Error: Patch method parameter '#{parameterName}' type "
      "'#{patchParameterType}' does not match '#{originParameterType}' on "
      "origin method '#{methodName}'.");

  static const MessageKind PATCH_EXTERNAL_WITHOUT_IMPLEMENTATION =
      const MessageKind("Error: External method without an implementation.");

  static const MessageKind PATCH_POINT_TO_FUNCTION = const MessageKind(
      "Info: This is the function patch '#{functionName}'.");

  static const MessageKind PATCH_POINT_TO_CLASS = const MessageKind(
      "Info: This is the class patch '#{className}'.");

  static const MessageKind PATCH_POINT_TO_GETTER = const MessageKind(
      "Info: This is the getter patch '#{getterName}'.");

  static const MessageKind PATCH_POINT_TO_SETTER = const MessageKind(
      "Info: This is the setter patch '#{setterName}'.");

  static const MessageKind PATCH_POINT_TO_CONSTRUCTOR = const MessageKind(
      "Info: This is the constructor patch '#{constructorName}'.");

  static const MessageKind PATCH_POINT_TO_PARAMETER = const MessageKind(
      "Info: This is the patch parameter '#{parameterName}'.");

  static const MessageKind PATCH_NON_EXISTING = const MessageKind(
      "Error: Origin does not exist for patch '#{name}'.");

  // TODO(ahe): Eventually, this error should be removed as it will be handled
  // by the regular parser.
  static const MessageKind PATCH_NONPATCHABLE = const MessageKind(
      "Error: Only classes and functions can be patched.");

  static const MessageKind PATCH_NON_EXTERNAL = const MessageKind(
      "Error: Only external functions can be patched.");

  static const MessageKind PATCH_NON_CLASS = const MessageKind(
      "Error: Patching non-class with class patch '#{className}'.");

  static const MessageKind PATCH_NON_GETTER = const MessageKind(
      "Error: Cannot patch non-getter '#{name}' with getter patch.");

  static const MessageKind PATCH_NO_GETTER = const MessageKind(
      "Error: No getter found for getter patch '#{getterName}'.");

  static const MessageKind PATCH_NON_SETTER = const MessageKind(
      "Error: Cannot patch non-setter '#{name}' with setter patch.");

  static const MessageKind PATCH_NO_SETTER = const MessageKind(
      "Error: No setter found for setter patch '#{setterName}'.");

  static const MessageKind PATCH_NON_CONSTRUCTOR = const MessageKind(
      "Error: Cannot patch non-constructor with constructor patch "
      "'#{constructorName}'.");

  static const MessageKind PATCH_NON_FUNCTION = const MessageKind(
      "Error: Cannot patch non-function with function patch "
      "'#{functionName}'.");

  //////////////////////////////////////////////////////////////////////////////
  // Patch errors end.
  //////////////////////////////////////////////////////////////////////////////

  toString() => template;

  Message message([Map arguments = const {}, bool terse = false]) {
    return new Message(this, arguments, terse);
  }

  CompilationError error([Map arguments = const {}, bool terse = false]) {
    return new CompilationError(this, arguments, terse);
  }

  bool get hasHowToFix => howToFix != null && howToFix != DONT_KNOW_HOW_TO_FIX;
}

class DualKind {
  final MessageKind error;
  final MessageKind warning;

  const DualKind({this.error, this.warning});
}

class Message {
  final MessageKind kind;
  final Map arguments;
  final bool terse;
  String message;

  Message(this.kind, this.arguments, this.terse) {
    assert(() { computeMessage(); return true; });
  }

  String computeMessage() {
    if (message == null) {
      message = kind.template;
      arguments.forEach((key, value) {
        message = message.replaceAll('#{${key}}', value.toString());
      });
      assert(invariant(
          CURRENT_ELEMENT_SPANNABLE,
          !message.contains(new RegExp(r'#\{.+\}')),
          message: 'Missing arguments in error message: "$message"'));
      if (!terse && kind.hasHowToFix) {
        String howToFix = kind.howToFix;
        arguments.forEach((key, value) {
          howToFix = howToFix.replaceAll('#{${key}}', value.toString());
        });
        message = '$message\n$howToFix';
      }
    }
    return message;
  }

  String toString() {
    return computeMessage();
  }

  bool operator==(other) {
    if (other is !Message) return false;
    return (kind == other.kind) && (toString() == other.toString());
  }

  int get hashCode => throw new UnsupportedError('Message.hashCode');
}

class Diagnostic {
  final Message message;
  Diagnostic(MessageKind kind, Map arguments, bool terse)
      : message = new Message(kind, arguments, terse);
  String toString() => message.toString();
}

class TypeWarning extends Diagnostic {
  TypeWarning(MessageKind kind, Map arguments, bool terse)
    : super(kind, arguments, terse);
}

class ResolutionWarning extends Diagnostic {
  ResolutionWarning(MessageKind kind, Map arguments, bool terse)
    : super(kind, arguments, terse);
}

class CompileTimeConstantError extends Diagnostic {
  CompileTimeConstantError(MessageKind kind, Map arguments, bool terse)
    : super(kind, arguments, terse);
}

class CompilationError extends Diagnostic {
  CompilationError(MessageKind kind, Map arguments, bool terse)
    : super(kind, arguments, terse);
}
