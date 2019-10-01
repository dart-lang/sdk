// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/error/analyzer_error_code.dart';

/**
 * The hints and coding recommendations for best practices which are not
 * mentioned in the Dart Language Specification.
 */
class HintCode extends AnalyzerErrorCode {
  /**
   * When the target expression uses '?.' operator, it can be `null`, so all the
   * subsequent invocations should also use '?.' operator.
   */
  static const HintCode CAN_BE_NULL_AFTER_NULL_AWARE = const HintCode(
      'CAN_BE_NULL_AFTER_NULL_AWARE',
      "The target expression uses '?.', so its value can be null.",
      correction: "Replace the '.' with a '?.' in the invocation.");

  /**
   * Dead code is code that is never reached, this can happen for instance if a
   * statement follows a return statement.
   */
  static const HintCode DEAD_CODE = const HintCode('DEAD_CODE', "Dead code.",
      correction: "Try removing the code, or "
          "fixing the code before it so that it can be reached.");

  /**
   * Dead code is code that is never reached. This case covers cases where the
   * user has catch clauses after `catch (e)` or `on Object catch (e)`.
   */
  static const HintCode DEAD_CODE_CATCH_FOLLOWING_CATCH = const HintCode(
      'DEAD_CODE_CATCH_FOLLOWING_CATCH',
      "Dead code: catch clauses after a 'catch (e)' or "
          "an 'on Object catch (e)' are never reached.",
      correction:
          "Try reordering the catch clauses so that they can be reached, or "
          "removing the unreachable catch clauses.");

  /**
   * Dead code is code that is never reached. This case covers cases where the
   * user has an on-catch clause such as `on A catch (e)`, where a supertype of
   * `A` was already caught.
   *
   * Parameters:
   * 0: name of the subtype
   * 1: name of the supertype
   */
  static const HintCode DEAD_CODE_ON_CATCH_SUBTYPE = const HintCode(
      'DEAD_CODE_ON_CATCH_SUBTYPE',
      "Dead code: this on-catch block will never be executed because '{0}' is "
          "a subtype of '{1}' and hence will have been caught above.",
      correction:
          "Try reordering the catch clauses so that this block can be reached, "
          "or removing the unreachable catch clause.");

  /**
   * Users should not create a class named `Function` anymore.
   */
  static const HintCode DEPRECATED_FUNCTION_CLASS_DECLARATION = const HintCode(
      'DEPRECATED_FUNCTION_CLASS_DECLARATION',
      "Declaring a class named 'Function' is deprecated.",
      correction: "Try renaming the class.");

  /**
   * `Function` should not be extended anymore.
   */
  static const HintCode DEPRECATED_EXTENDS_FUNCTION = const HintCode(
      'DEPRECATED_EXTENDS_FUNCTION', "Extending 'Function' is deprecated.",
      correction: "Try removing 'Function' from the 'extends' clause.");

  /**
   * Parameters:
   * 0: the name of the member
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a deprecated library or class
  // member is used in a different package.
  //
  // #### Example
  //
  // If the method `m` in the class `C` is annotated with `@deprecated`, then
  // the following code produces this diagnostic:
  //
  // ```dart
  // void f(C c) {
  //   c.[!m!]();
  // }
  // ```
  //
  // #### Common fixes
  //
  // The documentation for declarations that are annotated with `@deprecated`
  // should indicate what code to use in place of the deprecated code.
  static const HintCode DEPRECATED_MEMBER_USE = const HintCode(
      'DEPRECATED_MEMBER_USE', "'{0}' is deprecated and shouldn't be used.",
      correction: "Try replacing the use of the deprecated member with the "
          "replacement.",
      hasPublishedDocs: true);

  /**
   * Parameters:
   * 0: the name of the member
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a deprecated library member or
  // class member is used in the same package in which it's declared.
  //
  // #### Example
  //
  // The following code produces this diagnostic:
  //
  // ```dart
  // @deprecated
  // var x = 0;
  // var y = [!x!];
  // ```
  //
  // #### Common fixes
  //
  // The fix depends on what's been deprecated and what the replacement is. The
  // documentation for deprecated declarations should indicate what code to use
  // in place of the deprecated code.
  static const HintCode DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE =
      const HintCode('DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE',
          "'{0}' is deprecated and shouldn't be used.",
          correction: "Try replacing the use of the deprecated member with the "
              "replacement.",
          hasPublishedDocs: true);

  /**
   * `Function` should not be mixed in anymore.
   */
  static const HintCode DEPRECATED_MIXIN_FUNCTION = const HintCode(
      'DEPRECATED_MIXIN_FUNCTION', "Mixing in 'Function' is deprecated.",
      correction: "Try removing 'Function' from the 'with' clause.");

  /**
   * Hint to use the ~/ operator.
   */
  static const HintCode DIVISION_OPTIMIZATION = const HintCode(
      'DIVISION_OPTIMIZATION',
      "The operator x ~/ y is more efficient than (x / y).toInt().",
      correction: "Try re-writing the expression to use the '~/' operator.");

  /**
   * Duplicate imports.
   */
  static const HintCode DUPLICATE_IMPORT = const HintCode(
      'DUPLICATE_IMPORT', "Duplicate import.",
      correction: "Try removing all but one import of the library.");

  /**
   * Duplicate hidden names.
   */
  static const HintCode DUPLICATE_HIDDEN_NAME =
      const HintCode('DUPLICATE_HIDDEN_NAME', "Duplicate hidden name.",
          correction: "Try removing the repeated name from the list of hidden "
              "members.");

  /**
   * Duplicate shown names.
   */
  static const HintCode DUPLICATE_SHOWN_NAME =
      const HintCode('DUPLICATE_SHOWN_NAME', "Duplicate shown name.",
          correction: "Try removing the repeated name from the list of shown "
              "members.");

  /**
   * It is a bad practice for a source file in a package "lib" directory
   * hierarchy to traverse outside that directory hierarchy. For example, a
   * source file in the "lib" directory should not contain a directive such as
   * `import '../web/some.dart'` which references a file outside the lib
   * directory.
   */
  static const HintCode FILE_IMPORT_INSIDE_LIB_REFERENCES_FILE_OUTSIDE =
      const HintCode(
          'FILE_IMPORT_INSIDE_LIB_REFERENCES_FILE_OUTSIDE',
          "A file in the 'lib' directory shouldn't import a file outside the "
              "'lib' directory.",
          correction: "Try removing the import, or "
              "moving the imported file inside the 'lib' directory.");

  /**
   * It is a bad practice for a source file ouside a package "lib" directory
   * hierarchy to traverse into that directory hierarchy. For example, a source
   * file in the "web" directory should not contain a directive such as
   * `import '../lib/some.dart'` which references a file inside the lib
   * directory.
   */
  static const HintCode FILE_IMPORT_OUTSIDE_LIB_REFERENCES_FILE_INSIDE =
      const HintCode(
          'FILE_IMPORT_OUTSIDE_LIB_REFERENCES_FILE_INSIDE',
          "A file outside the 'lib' directory shouldn't reference a file "
              "inside the 'lib' directory using a relative path.",
          correction: "Try using a package: URI instead.");

  /**
   * Deferred libraries shouldn't define a top level function 'loadLibrary'.
   */
  static const HintCode IMPORT_DEFERRED_LIBRARY_WITH_LOAD_FUNCTION =
      const HintCode(
          'IMPORT_DEFERRED_LIBRARY_WITH_LOAD_FUNCTION',
          "The library '{0}' defines a top-level function named 'loadLibrary' "
              "which is hidden by deferring this library.",
          correction: "Try changing the import to not be deferred, or "
              "rename the function in the imported library.");

  /**
   * When "strict-inference" is enabled, collection literal types must be
   * inferred via the context type, or have type arguments.
   */
  static const HintCode INFERENCE_FAILURE_ON_COLLECTION_LITERAL = HintCode(
      'INFERENCE_FAILURE_ON_COLLECTION_LITERAL',
      "The type argument(s) of '{0}' can't be inferred.",
      correction: "Use explicit type argument(s) for '{0}'.");

  /**
   * When "strict-inference" is enabled, recursive local functions, top-level
   * functions, methods, and function-typed function parameters must all
   * specify a return type. See the strict-inference resource:
   *
   * https://github.com/dart-lang/language/blob/master/resources/type-system/strict-inference.md
   */
  static const HintCode INFERENCE_FAILURE_ON_FUNCTION_RETURN_TYPE = HintCode(
      'INFERENCE_FAILURE_ON_FUNCTION_RETURN_TYPE',
      "The return type of '{0}' cannot be inferred.",
      correction: "Declare the return type of '{0}'.");

  /**
   * When "strict-inference" is enabled, types in instance creation
   * (constructor calls) must be inferred via the context type, or have type
   * arguments.
   */
  static const HintCode INFERENCE_FAILURE_ON_INSTANCE_CREATION = HintCode(
      'INFERENCE_FAILURE_ON_INSTANCE_CREATION',
      "The type argument(s) of '{0}' can't be inferred.",
      correction: "Use explicit type argument(s) for '{0}'.");

  /**
   * When "strict-inference" in enabled, uninitialized variables must be
   * declared with a specific type.
   */
  static const HintCode INFERENCE_FAILURE_ON_UNINITIALIZED_VARIABLE =
      const HintCode(
          'INFERENCE_FAILURE_ON_UNINITIALIZED_VARIABLE',
          "The type of {0} can't be inferred without either a type or "
              "initializer.",
          correction: "Try specifying the type of the variable.");

  /**
   * When "strict-inference" in enabled, function parameters must be
   * declared with a specific type, or inherit a type.
   */
  static const HintCode INFERENCE_FAILURE_ON_UNTYPED_PARAMETER = const HintCode(
      'INFERENCE_FAILURE_ON_UNTYPED_PARAMETER',
      "The type of {0} can't be inferred; a type must be explicitly provided.",
      correction: "Try specifying the type of the parameter.");

  /**
   * This hint is generated anywhere a @factory annotation is associated with
   * anything other than a method.
   */
  static const HintCode INVALID_FACTORY_ANNOTATION = const HintCode(
      'INVALID_FACTORY_ANNOTATION',
      "Only methods can be annotated as factories.");

  /**
   * This hint is generated anywhere a @factory annotation is associated with
   * a method that does not declare a return type.
   */
  static const HintCode INVALID_FACTORY_METHOD_DECL = const HintCode(
      'INVALID_FACTORY_METHOD_DECL',
      "Factory method '{0}' must have a return type.");

  /**
   * This hint is generated anywhere a @factory annotation is associated with
   * a non-abstract method that can return anything other than a newly allocated
   * object.
   *
   * Parameters:
   * 0: the name of the method
   */
  static const HintCode INVALID_FACTORY_METHOD_IMPL = const HintCode(
      'INVALID_FACTORY_METHOD_IMPL',
      "Factory method '{0}' doesn't return a newly allocated object.");

  /**
   * This hint is generated anywhere an @immutable annotation is associated with
   * anything other than a class.
   */
  static const HintCode INVALID_IMMUTABLE_ANNOTATION = const HintCode(
      'INVALID_IMMUTABLE_ANNOTATION',
      "Only classes can be annotated as being immutable.");

  /**
   * No parameters.
   */
  // #### Description
  //
  // The meaning of the `@literal` annotation is only defined when it's applied
  // to a const constructor.
  //
  // #### Example
  //
  // The following code produces this diagnostic:
  //
  // ```dart
  // import 'package:meta/meta.dart';
  //
  // [!@literal!]
  // var x;
  // ```
  //
  // #### Common fixes
  //
  // Remove the annotation:
  //
  // ```dart
  // var x;
  // ```
  static const HintCode INVALID_LITERAL_ANNOTATION = const HintCode(
      'INVALID_LITERAL_ANNOTATION',
      "Only const constructors can have the `@literal` annotation.",
      hasPublishedDocs: true);

  /**
   * This hint is generated anywhere where `@required` annotates a named
   * parameter with a default value.
   *
   * Parameters:
   * 0: the name of the member
   */
  static const HintCode INVALID_REQUIRED_NAMED_PARAM = const HintCode(
      'INVALID_REQUIRED_NAMED_PARAM',
      "The type parameter '{0}' is annotated with @required but only named "
          "parameters without a default value can be annotated with it.",
      correction: "Remove @required.");

  /**
   * This hint is generated anywhere where `@required` annotates an optional
   * positional parameter.
   *
   * Parameters:
   * 0: the name of the member
   */
  static const HintCode INVALID_REQUIRED_OPTIONAL_POSITIONAL_PARAM =
      const HintCode(
          'INVALID_REQUIRED_OPTIONAL_POSITIONAL_PARAM',
          "Incorrect use of the annotation @required on the optional "
              "positional parameter '{0}'. Optional positional parameters "
              "cannot be required.",
          correction: "Remove @required.");

  /**
   * This hint is generated anywhere where `@required` annotates a non named
   * parameter or a named parameter with default value.
   *
   * Parameters:
   * 0: the name of the member
   *
   * Deprecated: Use the more specific [INVALID_REQUIRED_NAMED_PARAM],
   * [INVALID_REQUIRED_OPTIONAL_POSITION_PARAM], and
   * [INVALID_REQUIRED_POSITION_PARAM]
   */
  @deprecated
  static const HintCode INVALID_REQUIRED_PARAM = const HintCode(
      'INVALID_REQUIRED_PARAM',
      "The type parameter '{0}' is annotated with @required but only named "
          "parameters without default value can be annotated with it.",
      correction: "Remove @required.");

  /**
   * This hint is generated anywhere where `@required` annotates a non optional
   * positional parameter.
   *
   * Parameters:
   * 0: the name of the member
   */
  static const HintCode INVALID_REQUIRED_POSITIONAL_PARAM = const HintCode(
      'INVALID_REQUIRED_POSITIONAL_PARAM',
      "Redundant use of the annotation @required on the required positional "
          "parameter '{0}'.",
      correction: "Remove @required.");

  /**
   * This hint is generated anywhere where `@sealed` annotates something other
   * than a class.
   *
   * Parameters:
   * 0: the name of the member
   */
  static const HintCode INVALID_SEALED_ANNOTATION = const HintCode(
      'INVALID_SEALED_ANNOTATION',
      "The member '{0}' is annotated with '@sealed' but only classes can be "
          "annotated with it.",
      correction: "Remove @sealed.");

  /**
   * This hint is generated anywhere where a member annotated with `@protected`
   * is used outside an instance member of a subclass.
   *
   * Parameters:
   * 0: the name of the member
   * 1: the name of the defining class
   */
  static const HintCode INVALID_USE_OF_PROTECTED_MEMBER = const HintCode(
      'INVALID_USE_OF_PROTECTED_MEMBER',
      "The member '{0}' can only be used within instance members of subclasses "
          "of '{1}'.");

  /// This hint is generated anywhere where a member annotated with
  /// `@visibleForTemplate` is used outside of a "template" Dart file.
  ///
  /// Parameters:
  /// 0: the name of the member
  /// 1: the name of the defining class
  static const HintCode INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER =
      const HintCode(
          'INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER',
          "The member '{0}' can only be used within '{1}' or a template "
              "library.");

  /// This hint is generated anywhere where a member annotated with
  /// `@visibleForTesting` is used outside the defining library, or a test.
  ///
  /// Parameters:
  /// 0: the name of the member
  /// 1: the name of the defining class
  static const HintCode INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER =
      const HintCode('INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER',
          "The member '{0}' can only be used within '{1}' or a test.");

  /// This hint is generated anywhere where a private declaration is annotated
  /// with `@visibleForTemplate` or `@visibleForTesting`.
  ///
  /// Parameters:
  /// 0: the name of the member
  /// 1: the name of the annotation
  static const HintCode INVALID_VISIBILITY_ANNOTATION = const HintCode(
      'INVALID_VISIBILITY_ANNOTATION',
      "The member '{0}' is annotated with '{1}', but this annotation is only "
          "meaningful on declarations of public members.");

  /**
   * Hint for the `x is double` type checks.
   */
  static const HintCode IS_DOUBLE = const HintCode(
      'IS_DOUBLE',
      "When compiled to JS, this test might return true when the left hand "
          "side is an int.",
      correction: "Try testing for 'num' instead.");

  /**
   * Hint for the `x is int` type checks.
   */
  // TODO(brianwilkerson) This hint isn't being generated. Decide whether to
  //  generate it or remove it.
  static const HintCode IS_INT = const HintCode(
      'IS_INT',
      "When compiled to JS, this test might return true when the left hand "
          "side is a double.",
      correction: "Try testing for 'num' instead.");

  /**
   * Hint for the `x is! double` type checks.
   */
  static const HintCode IS_NOT_DOUBLE = const HintCode(
      'IS_NOT_DOUBLE',
      "When compiled to JS, this test might return false when the left hand "
          "side is an int.",
      correction: "Try testing for 'num' instead.");

  /**
   * Hint for the `x is! int` type checks.
   */
  // TODO(brianwilkerson) This hint isn't being generated. Decide whether to
  //  generate it or remove it.
  static const HintCode IS_NOT_INT = const HintCode(
      'IS_NOT_INT',
      "When compiled to JS, this test might return false when the left hand "
          "side is a double.",
      correction: "Try testing for 'num' instead.");

  /**
   * Generate a hint for an element that is annotated with `@JS(...)` whose
   * library declaration is not similarly annotated.
   */
  static const HintCode MISSING_JS_LIB_ANNOTATION = const HintCode(
      'MISSING_JS_LIB_ANNOTATION',
      "The @JS() annotation can only be used if it is also declared on the "
          "library directive.",
      correction: "Try adding the annotation to the library directive.");

  /**
   * Generate a hint for a constructor, function or method invocation where a
   * required parameter is missing.
   *
   * Parameters:
   * 0: the name of the parameter
   */
  static const HintCode MISSING_REQUIRED_PARAM = const HintCode(
      'MISSING_REQUIRED_PARAM', "The parameter '{0}' is required.");

  /**
   * Generate a hint for a constructor, function or method invocation where a
   * required parameter is missing.
   *
   * Parameters:
   * 0: the name of the parameter
   * 1: message details
   */
  static const HintCode MISSING_REQUIRED_PARAM_WITH_DETAILS = const HintCode(
      'MISSING_REQUIRED_PARAM_WITH_DETAILS',
      "The parameter '{0}' is required. {1}.");

  /**
   * Parameters:
   * 0: the name of the declared return type
   */
  // #### Description
  //
  // Any function or method that doesn't end with either an explicit return or a
  // throw implicitly returns `null`. This is rarely the desired behavior. The
  // analyzer produces this diagnostic when it finds an implicit return.
  //
  // #### Example
  //
  // The following code produces this diagnostic:
  //
  // ```dart
  // [!int!] f(int x) {
  //   if (x < 0) {
  //     return 0;
  //   }
  // }
  // ```
  //
  // #### Common fixes
  //
  // Add a return statement that makes the return value explicit, even if `null`
  // is the appropriate value.
  static const HintCode MISSING_RETURN = const HintCode(
      'MISSING_RETURN',
      "This function has a return type of '{0}', but doesn't end with a "
          "return statement.",
      correction: "Try adding a return statement, "
          "or changing the return type to 'void'.",
      hasPublishedDocs: true);

  /**
   * This hint is generated anywhere where a `@sealed` class is used as a
   * a superclass constraint of a mixin.
   */
  static const HintCode MIXIN_ON_SEALED_CLASS = const HintCode(
      'MIXIN_ON_SEALED_CLASS',
      "The class '{0}' shouldn't be used as a mixin constraint because it is "
          "sealed, and any class mixing in this mixin has '{0}' as a "
          "superclass.",
      correction:
          "Try composing with this class, or refer to its documentation for "
          "more information.");

  /**
   * Generate a hint for classes that inherit from classes annotated with
   * `@immutable` but that are not immutable.
   */
  static const HintCode MUST_BE_IMMUTABLE = const HintCode(
      'MUST_BE_IMMUTABLE',
      "This class (or a class which this class inherits from) is marked as "
          "'@immutable', but one or more of its instance fields are not final: "
          "{0}");

  /**
   * Generate a hint for methods that override methods annotated `@mustCallSuper`
   * that do not invoke the overridden super method.
   *
   * Parameters:
   * 0: the name of the class declaring the overridden method
   */
  static const HintCode MUST_CALL_SUPER = const HintCode(
      'MUST_CALL_SUPER',
      "This method overrides a method annotated as @mustCallSuper in '{0}', "
          "but doesn't invoke the overridden method.");

  /**
   * Generate a hint for non-const instance creation using a constructor
   * annotated with `@literal`.
   */
  static const HintCode NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR = const HintCode(
      'NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR',
      "This instance creation must be 'const', because the {0} constructor is "
          "marked as '@literal'.",
      correction: "Try adding a 'const' keyword.");

  /**
   * Generate a hint for non-const instance creation (with the `new` keyword)
   * using a constructor annotated with `@literal`.
   */
  static const HintCode NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR_USING_NEW =
      const HintCode(
          'NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR_USING_NEW',
          "This instance creation must be 'const', because the {0} constructor "
              "is marked as '@literal'.",
          correction: "Try replacing the 'new' keyword with 'const'.");

  /**
   * When the left operand of a binary expression uses '?.' operator, it can be
   * `null`.
   */
  static const HintCode NULL_AWARE_BEFORE_OPERATOR = const HintCode(
      'NULL_AWARE_BEFORE_OPERATOR',
      "The left operand uses '?.', so its value can be null.");

  /**
   * A condition in a control flow statement could evaluate to `null` because it
   * uses the null-aware '?.' operator.
   */
  static const HintCode NULL_AWARE_IN_CONDITION = const HintCode(
      'NULL_AWARE_IN_CONDITION',
      "The value of the '?.' operator can be 'null', which isn't appropriate "
          "in a condition.",
      correction:
          "Try replacing the '?.' with a '.', testing the left-hand side for "
          "null if necessary.");

  /**
   * A condition in operands of a logical operator could evaluate to `null`
   * because it uses the null-aware '?.' operator.
   */
  static const HintCode NULL_AWARE_IN_LOGICAL_OPERATOR = const HintCode(
      'NULL_AWARE_IN_LOGICAL_OPERATOR',
      "The value of the '?.' operator can be 'null', which isn't appropriate "
          "as an operand of a logical operator.");

  /**
   * Hint for classes that override equals, but not hashCode.
   *
   * Parameters:
   * 0: the name of the current class
   */
  // TODO(brianwilkerson) Decide whether we want to implement this check
  //  (possibly as a lint) or remove the hint code.
  static const HintCode OVERRIDE_EQUALS_BUT_NOT_HASH_CODE = const HintCode(
      'OVERRIDE_EQUALS_BUT_NOT_HASH_CODE',
      "The class '{0}' overrides 'operator==', but not 'get hashCode'.",
      correction: "Try implementing 'hashCode'.");

  /**
   * A getter with the override annotation does not override an existing getter.
   */
  static const HintCode OVERRIDE_ON_NON_OVERRIDING_GETTER = const HintCode(
      'OVERRIDE_ON_NON_OVERRIDING_GETTER',
      "Getter doesn't override an inherited getter.",
      correction: "Try updating this class to match the superclass, or "
          "removing the override annotation.");

  /**
   * A field with the override annotation does not override a getter or setter.
   */
  static const HintCode OVERRIDE_ON_NON_OVERRIDING_FIELD = const HintCode(
      'OVERRIDE_ON_NON_OVERRIDING_FIELD',
      "Field doesn't override an inherited getter or setter.",
      correction: "Try updating this class to match the superclass, or "
          "removing the override annotation.");

  /**
   * A method with the override annotation does not override an existing method.
   */
  static const HintCode OVERRIDE_ON_NON_OVERRIDING_METHOD = const HintCode(
      'OVERRIDE_ON_NON_OVERRIDING_METHOD',
      "Method doesn't override an inherited method.",
      correction: "Try updating this class to match the superclass, or "
          "removing the override annotation.");

  /**
   * A setter with the override annotation does not override an existing setter.
   */
  static const HintCode OVERRIDE_ON_NON_OVERRIDING_SETTER = const HintCode(
      'OVERRIDE_ON_NON_OVERRIDING_SETTER',
      "Setter doesn't override an inherited setter.",
      correction: "Try updating this class to match the superclass, or "
          "removing the override annotation.");

  /**
   * It is a bad practice for a package import to reference anything outside the
   * given package, or more generally, it is bad practice for a package import
   * to contain a "..". For example, a source file should not contain a
   * directive such as `import 'package:foo/../some.dart'`.
   */
  static const HintCode PACKAGE_IMPORT_CONTAINS_DOT_DOT = const HintCode(
      'PACKAGE_IMPORT_CONTAINS_DOT_DOT',
      "A package import shouldn't contain '..'.");

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when either the class `Future` or
  // `Stream` is referenced in a library that doesn't import `dart:async` in
  // code that has an SDK constraint whose lower bound is less than 2.1.0. In
  // earlier versions, these classes weren't defined in `dart:core`, so the
  // import was necessary.
  //
  // #### Example
  //
  // Here's an example of a pubspec that defines an SDK constraint with a lower
  // bound of less than 2.1.0:
  //
  // ```yaml
  // %uri="pubspec.yaml"
  // environment:
  //   sdk: '>=2.0.0 <2.4.0'
  // ```
  //
  // In the package that has that pubspec, code like the following produces this
  // diagnostic:
  //
  // ```dart
  // void f([!Future!] f) {}
  // ```
  //
  // #### Common fixes
  //
  // If you don't need to support older versions of the SDK, then you can
  // increase the SDK constraint to allow the classes to be referenced:
  //
  // ```yaml
  // environment:
  //   sdk: '>=2.1.0 <2.4.0'
  // ```
  //
  // If you need to support older versions of the SDK, then import the
  // `dart:async` library.
  //
  // ```dart
  // import 'dart:async';
  //
  // void f(Future f) {}
  // ```
  static const HintCode SDK_VERSION_ASYNC_EXPORTED_FROM_CORE = const HintCode(
      'SDK_VERSION_ASYNC_EXPORTED_FROM_CORE',
      "The class '{0}' wasn't exported from 'dart:core' until version 2.1, "
          "but this code is required to be able to run on earlier versions.",
      correction:
          "Try either importing 'dart:async' or updating the SDK constraints.",
      hasPublishedDocs: true);

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an as expression inside a
  // [constant context](#constant-context) is found in code that has an SDK
  // constraint whose lower bound is less than 2.3.2. Using an as expression in
  // a [constant context](#constant-context) wasn't supported in earlier
  // versions, so this code won't be able to run against earlier versions of the
  // SDK.
  //
  // #### Example
  //
  // Here's an example of a pubspec that defines an SDK constraint with a lower
  // bound of less than 2.3.2:
  //
  // ```yaml
  // %uri="pubspec.yaml"
  // environment:
  //   sdk: '>=2.1.0 <2.4.0'
  // ```
  //
  // In the package that has that pubspec, code like the following generates
  // this diagnostic:
  //
  // ```dart
  // const num n = 3;
  // const int i = [!n as int!];
  // ```
  //
  // #### Common fixes
  //
  // If you don't need to support older versions of the SDK, then you can
  // ncrease the SDK constraint to allow the expression to be used:
  //
  // ```yaml
  // environment:
  //   sdk: '>=2.3.2 <2.4.0'
  // ```
  //
  // If you need to support older versions of the SDK, then either rewrite the
  // code to not use an as expression, or change the code so that the as
  // expression is not in a [constant context](#constant-context).:
  //
  // ```dart
  // num x = 3;
  // int y = x as int;
  // ```
  static const HintCode SDK_VERSION_AS_EXPRESSION_IN_CONST_CONTEXT = const HintCode(
      'SDK_VERSION_AS_EXPRESSION_IN_CONST_CONTEXT',
      "The use of an as expression in a constant expression wasn't "
          "supported until version 2.3.2, but this code is required to be able "
          "to run on earlier versions.",
      correction: "Try updating the SDK constraints.",
      hasPublishedDocs: true);

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when any use of the `&`, `|` or `^`
  // operators on the class `bool` inside a
  // [constant context](#constant-context) is found in code that has an SDK
  // constraint whose lower bound is less than 2.3.2. Using these operators in a
  // [constant context](#constant-context) wasn't supported in earlier versions,
  // so this code won't be able to run against earlier versions of the SDK.
  //
  // #### Example
  //
  // Here's an example of a pubspec that defines an SDK constraint with a lower
  // bound of less than 2.3.2:
  //
  // ```yaml
  // %uri="pubspec.yaml"
  // environment:
  //   sdk: '>=2.1.0 <2.4.0'
  // ```
  //
  // In the package that has that pubspec, code like the following produces this
  // diagnostic:
  //
  // ```dart
  // const bool a = true;
  // const bool b = false;
  // const bool c = a [!&!] b;
  // ```
  //
  // #### Common fixes
  //
  // If you don't need to support older versions of the SDK, then you can
  // increase the SDK constraint to allow the operators to be used:
  //
  // ```yaml
  // environment:
  //  sdk: '>=2.3.2 <2.4.0'
  // ```
  //
  // If you need to support older versions of the SDK, then either rewrite the
  // code to not use these operators, or change the code so that the expression
  // is not in a [constant context](#constant-context).:
  //
  // ```dart
  // const bool a = true;
  // const bool b = false;
  // bool c = a & b;
  // ```
  static const HintCode SDK_VERSION_BOOL_OPERATOR_IN_CONST_CONTEXT = const HintCode(
      'SDK_VERSION_BOOL_OPERATOR_IN_CONST_CONTEXT',
      "The use of the operator '{0}' for 'bool' operands in a constant context "
          "wasn't supported until version 2.3.2, but this code is required to "
          "be able to run on earlier versions.",
      correction: "Try updating the SDK constraints.",
      hasPublishedDocs: true);

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the operator `==` is used on a
  // non-primitive type inside a [constant context](#constant-context) is found
  // in code that has an SDK constraint whose lower bound is less than 2.3.2.
  // Using this operator in a [constant context](#constant-context) wasn't
  // supported in earlier versions, so this code won't be able to run against
  // earlier versions of the SDK.
  //
  // #### Example
  //
  // Here's an example of a pubspec that defines an SDK constraint with a lower
  // bound of less than 2.3.2:
  //
  // ```yaml
  // %uri="pubspec.yaml"
  // environment:
  //   sdk: '>=2.1.0 <2.4.0'
  // ```
  //
  // In the package that has that pubspec, code like the following produces this
  // diagnostic:
  //
  // ```dart
  // class C {}
  // const C a = null;
  // const C b = null;
  // const bool same = a [!==!] b;
  // ```
  //
  // #### Common fixes
  //
  // If you don't need to support older versions of the SDK, then you can
  // increase the SDK constraint to allow the operator to be used:
  //
  // ```yaml
  // environment:
  //   sdk: '>=2.3.2 <2.4.0'
  // ```
  //
  // If you need to support older versions of the SDK, then either rewrite the
  // code to not use the `==` operator, or change the code so that the
  // expression is not in a [constant context](#constant-context).:
  //
  // ```dart
  // class C {}
  // const C a = null;
  // const C b = null;
  // bool same = a == b;
  // ```
  static const HintCode SDK_VERSION_EQ_EQ_OPERATOR_IN_CONST_CONTEXT =
      const HintCode(
          'SDK_VERSION_EQ_EQ_OPERATOR_IN_CONST_CONTEXT',
          "Using the operator '==' for non-primitive types wasn't supported "
              "until version 2.3.2, but this code is required to be able to "
              "run on earlier versions.",
          correction: "Try updating the SDK constraints.",
          hasPublishedDocs: true);

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an extension declaration or an
  // extension override is found in code that has an SDK constraint whose lower
  // bound is less than 2.6.0. Using extensions wasn't supported in earlier
  // versions, so this code won't be able to run against earlier versions of the
  // SDK.
  //
  // #### Example
  //
  // Here's an example of a pubspec that defines an SDK constraint with a lower
  // bound of less than 2.6.0:
  //
  // ```yaml
  // %uri="pubspec.yaml"
  // environment:
  //  sdk: '>=2.4.0 <2.7.0'
  // ```
  //
  // In the package that has that pubspec, code like the following generates
  // this diagnostic:
  //
  // ```dart
  // [!extension!] E on String {
  //   void sayHello() {
  //     print('Hello $this');
  //   }
  // }
  // ```
  //
  // #### Common fixes
  //
  // If you don't need to support older versions of the SDK, then you can
  // increase the SDK constraint to allow the syntax to be used:
  //
  // ```yaml
  // environment:
  //   sdk: '>=2.6.0 <2.7.0'
  // ```
  //
  // If you need to support older versions of the SDK, then rewrite the code to
  // not make use of extensions. The most common way to do this is to rewrite
  // the members of the extension as top-level functions (or methods) that take
  // the value that would have been bound to `this` as a parameter:
  //
  // ```dart
  // void sayHello(String s) {
  //   print('Hello $s');
  // }
  // ```
  static const HintCode SDK_VERSION_EXTENSION_METHODS = const HintCode(
      'SDK_VERSION_EXTENSION_METHODS',
      "Extension methods weren't supported until version 2.6.0, "
          "but this code is required to be able to run on earlier versions.",
      correction: "Try updating the SDK constraints.",
      hasPublishedDocs: true);

  /**
   * No parameters.
   */
  /* // #### Description
  //
  // The analyzer produces this diagnostic when the operator `>>>` is used in
  // code that has an SDK constraint whose lower bound is less than 2.X.0. This
  // operator wasn't supported in earlier versions, so this code won't be able
  // to run against earlier versions of the SDK.
  //
  // #### Example
  //
  // Here's an example of a pubspec that defines an SDK constraint with a lower
  // bound of less than 2.X.0:
  //
  // ```yaml
  // %uri="pubspec.yaml"
  // environment:
  //  sdk: '>=2.0.0 <2.4.0'
  // ```
  //
  // In the package that has that pubspec, code like the following produces this
  // diagnostic:
  //
  // ```dart
  // int x = 3 [!>>>!] 4;
  // ```
  //
  // #### Common fixes
  //
  // If you don't need to support older versions of the SDK, then you can
  // increase the SDK constraint to allow the operator to be used:
  //
  // ```yaml
  // environment:
  //   sdk: '>=2.3.2 <2.4.0'
  // ```
  //
  // If you need to support older versions of the SDK, then rewrite the code to
  // not use the `>>>` operator:
  //
  // ```dart
  // int x = logicalShiftRight(3, 4);
  //
  // int logicalShiftRight(int leftOperand, int rightOperand) {
  //   int divisor = 1 << rightOperand;
  //   if (divisor == 0) {
  //     return 0;
  //   }
  //   return leftOperand ~/ divisor;
  // }
  // ``` */
  static const HintCode SDK_VERSION_GT_GT_GT_OPERATOR = const HintCode(
      'SDK_VERSION_GT_GT_GT_OPERATOR',
      "The operator '>>>' wasn't supported until version 2.3.2, but this code "
          "is required to be able to run on earlier versions.",
      correction: "Try updating the SDK constraints.");

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an is expression inside a
  // [constant context](#constant-context) is found in code that has an SDK
  // constraint whose lower bound is less than 2.3.2. Using an is expression in
  // a [constant context](#constant-context) wasn't supported in earlier
  // versions, so this code won't be able to run against earlier versions of the
  // SDK.
  //
  // #### Example
  //
  // Here's an example of a pubspec that defines an SDK constraint with a lower
  // bound of less than 2.3.2:
  //
  // ```yaml
  // %uri="pubspec.yaml"
  // environment:
  //   sdk: '>=2.1.0 <2.4.0'
  // ```
  //
  // In the package that has that pubspec, code like the following generates
  // this diagnostic:
  //
  // ```dart
  // const x = 4;
  // const y = [!x is int!] ? 0 : 1;
  // ```
  //
  // #### Common fixes
  //
  // If you don't need to support older versions of the SDK, then you can
  // increase the SDK constraint to allow the expression to be used:
  //
  // ```yaml
  // environment:
  //   sdk: '>=2.3.2 <2.4.0'
  // ```
  //
  // If you need to support older versions of the SDK, then either rewrite the
  // code to not use the is operator, or, if that's not possible, change the
  // code so that the is expression is not in a
  // [constant context](#constant-context).:
  //
  // ```dart
  // const x = 4;
  // var y = x is int ? 0 : 1;
  // ```
  static const HintCode SDK_VERSION_IS_EXPRESSION_IN_CONST_CONTEXT = const HintCode(
      'SDK_VERSION_IS_EXPRESSION_IN_CONST_CONTEXT',
      "The use of an is expression in a constant context wasn't supported "
          "until version 2.3.2, but this code is required to be able to run on "
          "earlier versions.",
      correction: "Try updating the SDK constraints.",
      hasPublishedDocs: true);

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a set literal is found in code
  // that has an SDK constraint whose lower bound is less than 2.2.0. Set
  // literals weren't supported in earlier versions, so this code won't be able
  // to run against earlier versions of the SDK.
  //
  // #### Example
  //
  // Here's an example of a pubspec that defines an SDK constraint with a lower
  // bound of less than 2.2.0:
  //
  // ```yaml
  // %uri="pubspec.yaml"
  // environment:
  //   sdk: '>=2.1.0 <2.4.0'
  // ```
  //
  // In the package that has that pubspec, code like the following produces this
  // diagnostic:
  //
  // ```dart
  // var s = [!<int>{}!];
  // ```
  //
  // #### Common fixes
  //
  // If you don't need to support older versions of the SDK, then you can
  // increase the SDK constraint to allow the syntax to be used:
  //
  // ```yaml
  // environment:
  //   sdk: '>=2.2.0 <2.4.0'
  // ```
  //
  // If you do need to support older versions of the SDK, then replace the set
  // literal with code that creates the set without the use of a literal:
  //
  // ```dart
  // var s = new Set<int>();
  // ```
  static const HintCode SDK_VERSION_SET_LITERAL = const HintCode(
      'SDK_VERSION_SET_LITERAL',
      "Set literals weren't supported until version 2.2, but this code is "
          "required to be able to run on earlier versions.",
      correction: "Try updating the SDK constraints.",
      hasPublishedDocs: true);

  /**
   * No parameters.
   */
  /* // #### Description
  //
  // The analyzer produces this diagnostic when a reference to the class `Never`
  // is found in code that has an SDK constraint whose lower bound is less than
  // 2.X.0. This class wasn't defined in earlier versions, so this code won't be
  // able to run against earlier versions of the SDK.
  //
  // #### Example
  //
  // Here's an example of a pubspec that defines an SDK constraint with a lower
  // bound of less than 2.X.0:
  //
  // ```yaml
  // %uri="pubspec.yaml"
  // environment:
  //   sdk: '>=2.5.0 <2.6.0'
  // ```
  //
  // In the package that has that pubspec, code like the following produces this
  // diagnostic:
  //
  // ```dart
  // [!Never!] n;
  // ```
  //
  // #### Common fixes
  //
  // If you don't need to support older versions of the SDK, then you can
  // increase the SDK constraint to allow the type to be used:
  //
  // ```yaml
  // environment:
  //   sdk: '>=2.X.0 <2.7.0'
  // ```
  //
  // If you need to support older versions of the SDK, then rewrite the code to
  // not reference this class:
  //
  // ```dart
  // dynamic x;
  // ``` */
  static const HintCode SDK_VERSION_NEVER = const HintCode(
      // TODO(brianwilkerson) Replace the message with the following when we know
      //  when this feature will ship:
      //    The type 'Never' wasn't supported until version 2.X.0, but this code
      //    is required to be able to run on earlier versions.
      'SDK_VERSION_NEVER',
      "The type Never is not yet supported.");

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a for, if, or spread element is
  // found in code that has an SDK constraint whose lower bound is less than
  // 2.3.0. Using a for, if, or spread element wasn't supported in earlier
  // versions, so this code won't be able to run against earlier versions of the
  // SDK.
  //
  // #### Example
  //
  // Here's an example of a pubspec that defines an SDK constraint with a lower
  // bound of less than 2.3.0:
  //
  // ```yaml
  // %uri="pubspec.yaml"
  // environment:
  //   sdk: '>=2.2.0 <2.4.0'
  // ```
  //
  // In the package that has that pubspec, code like the following generates
  // this diagnostic:
  //
  // ```dart
  // var digits = [[!for (int i = 0; i < 10; i++) i!]];
  // ```
  //
  // #### Common fixes
  //
  // If you don't need to support older versions of the SDK, then you can
  // increase the SDK constraint to allow the syntax to be used:
  //
  // ```yaml
  // environment:
  //   sdk: '>=2.3.0 <2.4.0'
  // ```
  //
  // If you need to support older versions of the SDK, then rewrite the code to
  // not make use of those elements:
  //
  // ```dart
  // var digits = _initializeDigits();
  //
  // List<int> _initializeDigits() {
  //   var digits = <int>[];
  //   for (int i = 0; i < 10; i++) {
  //     digits.add(i);
  //   }
  //   return digits;
  // }
  // ```
  static const HintCode SDK_VERSION_UI_AS_CODE = const HintCode(
      'SDK_VERSION_UI_AS_CODE',
      "The for, if, and spread elements weren't supported until version 2.2.2, "
          "but this code is required to be able to run on earlier versions.",
      correction: "Try updating the SDK constraints.",
      hasPublishedDocs: true);

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an if or spread element inside
  // a [constant context](#constant-context) is found in code that has an
  // SDK constraint whose lower bound is less than 2.5.0. Using an if or
  // spread element inside a [constant context](#constant-context) wasn't
  // supported in earlier versions, so this code won't be able to run against
  // earlier versions of the SDK.
  //
  // #### Example
  //
  // Here's an example of a pubspec that defines an SDK constraint with a lower
  // bound of less than 2.5.0:
  //
  // ```yaml
  // %uri="pubspec.yaml"
  // environment:
  //   sdk: '>=2.4.0 <2.6.0'
  // ```
  //
  // In the package that has that pubspec, code like the following generates
  // this diagnostic:
  //
  // ```dart
  // const a = [1, 2];
  // const b = [[!...a!]];
  // ```
  //
  // #### Common fixes
  //
  // If you don't need to support older versions of the SDK, then you can
  // increase the SDK constraint to allow the syntax to be used:
  //
  // ```yaml
  // environment:
  //   sdk: '>=2.5.0 <2.6.0'
  // ```
  //
  // If you need to support older versions of the SDK, then rewrite the code to
  // not make use of those elements:
  //
  // ```dart
  // const a = [1, 2];
  // const b = [1, 2];
  // ```
  //
  // If that's not possible, change the code so that the element is not in a
  // [constant context](#constant-context).:
  //
  // ```dart
  // const a = [1, 2];
  // var b = [...a];
  // ```
  static const HintCode SDK_VERSION_UI_AS_CODE_IN_CONST_CONTEXT = const HintCode(
      'SDK_VERSION_UI_AS_CODE_IN_CONST_CONTEXT',
      "The if and spread elements weren't supported in constant expressions "
          "until version 2.5.0, but this code is required to be able to run on "
          "earlier versions.",
      correction: "Try updating the SDK constraints.",
      hasPublishedDocs: true);

  /**
   * When "strict-raw-types" is enabled, raw types must be inferred via the
   * context type, or have type arguments.
   */
  static const HintCode STRICT_RAW_TYPE = HintCode('STRICT_RAW_TYPE',
      "The generic type '{0}' should have explicit type arguments but doesn't.",
      correction: "Use explicit type arguments for '{0}'.");

  /**
   * This hint is generated anywhere where a `@sealed` class or mixin is used as
   * a super-type of a class.
   */
  static const HintCode SUBTYPE_OF_SEALED_CLASS = const HintCode(
      'SUBTYPE_OF_SEALED_CLASS',
      "The class '{0}' shouldn't be extended, mixed in, or implemented because "
          "it is sealed.",
      correction:
          "Try composing instead of inheriting, or refer to its documentation "
          "for more information.");

  /**
   * Type checks of the type `x is! Null` should be done with `x != null`.
   */
  static const HintCode TYPE_CHECK_IS_NOT_NULL = const HintCode(
      'TYPE_CHECK_IS_NOT_NULL',
      "Tests for non-null should be done with '!= null'.",
      correction: "Try replacing the 'is! Null' check with '!= null'.");

  /**
   * Type checks of the type `x is Null` should be done with `x == null`.
   */
  static const HintCode TYPE_CHECK_IS_NULL = const HintCode(
      'TYPE_CHECK_IS_NULL', "Tests for null should be done with '== null'.",
      correction: "Try replacing the 'is Null' check with '== null'.");

  /**
   * An undefined name hidden in an import or export directive.
   */
  static const HintCode UNDEFINED_HIDDEN_NAME = const HintCode(
      'UNDEFINED_HIDDEN_NAME',
      "The library '{0}' doesn't export a member with the hidden name '{1}'.",
      correction: "Try removing the name from the list of hidden members.");

  /**
   * An undefined name shown in an import or export directive.
   */
  static const HintCode UNDEFINED_SHOWN_NAME = const HintCode(
      'UNDEFINED_SHOWN_NAME',
      "The library '{0}' doesn't export a member with the shown name '{1}'.",
      correction: "Try removing the name from the list of shown members.");

  /**
   * Unnecessary cast.
   */
  static const HintCode UNNECESSARY_CAST = const HintCode(
      'UNNECESSARY_CAST', "Unnecessary cast.",
      correction: "Try removing the cast.");

  /**
   * Unnecessary `noSuchMethod` declaration.
   */
  static const HintCode UNNECESSARY_NO_SUCH_METHOD = const HintCode(
      'UNNECESSARY_NO_SUCH_METHOD', "Unnecessary 'noSuchMethod' declaration.",
      correction: "Try removing the declaration of 'noSuchMethod'.");

  /**
   * Unnecessary type checks, the result is always false.
   */
  static const HintCode UNNECESSARY_TYPE_CHECK_FALSE = const HintCode(
      'UNNECESSARY_TYPE_CHECK_FALSE',
      "Unnecessary type check, the result is always false.",
      correction: "Try correcting the type check, or removing the type check.");

  /**
   * Unnecessary type checks, the result is always true.
   */
  static const HintCode UNNECESSARY_TYPE_CHECK_TRUE = const HintCode(
      'UNNECESSARY_TYPE_CHECK_TRUE',
      "Unnecessary type check, the result is always true.",
      correction: "Try correcting the type check, or removing the type check.");

  /**
   * Unused catch exception variables.
   */
  static const HintCode UNUSED_CATCH_CLAUSE = const HintCode(
      'UNUSED_CATCH_CLAUSE',
      "The exception variable '{0}' isn't used, so the 'catch' clause can be "
          "removed.",
      // TODO(brianwilkerson) Split this error code so that we can differentiate
      // between removing the catch clause and replacing the catch clause with
      // an on clause.
      correction: "Try removing the catch clause.");

  /**
   * Unused catch stack trace variables.
   */
  static const HintCode UNUSED_CATCH_STACK = const HintCode(
      'UNUSED_CATCH_STACK',
      "The stack trace variable '{0}' isn't used and can be removed.",
      correction: "Try removing the stack trace variable, or using it.");

  /**
   * Parameters:
   * 0: the name that is declared but not referenced
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a private class, enum, mixin,
  // typedef, top level variable, top level function, or method is declared but
  // never referenced.
  //
  // #### Example
  //
  // Assuming that no code in the library references `_C`, the following code
  // produces this diagnostic:
  //
  // ```dart
  // class [!_C!] {}
  // ```
  //
  // #### Common fixes
  //
  // If the declaration isn't needed, then remove it.
  //
  // If the declaration was intended to be used, then add the missing code.
  static const HintCode UNUSED_ELEMENT = const HintCode(
      'UNUSED_ELEMENT', "The declaration '{0}' isn't referenced.",
      correction: "Try removing the declaration of '{0}'.",
      hasPublishedDocs: true);

  /**
   * Parameters:
   * 0: the name of the unused field
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a private field is declared but
  // never read, even if it's written in one or more places.
  //
  // #### Example
  //
  // The following code produces this diagnostic:
  //
  // ```dart
  // class Point {
  //   int [!_x!];
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the field isn't needed, then remove it.
  //
  // If the field was intended to be used, then add the missing code.
  static const HintCode UNUSED_FIELD = const HintCode(
      'UNUSED_FIELD', "The value of the field '{0}' isn't used.",
      correction: "Try removing the field, or using it.",
      hasPublishedDocs: true);

  /**
   * Parameters:
   * 0: the content of the unused import's uri
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an import isn't needed because
  // none of the names that are imported are referenced within the importing
  // library.
  //
  // #### Example
  //
  // The following code produces this diagnostic:
  //
  // ```dart
  // import [!'dart:async'!];
  //
  // void main() {}
  // ```
  //
  // #### Common fixes
  //
  // If the import isn't needed, then remove it.
  //
  // If some of the imported names are intended to be used, then add the missing
  // code.
  static const HintCode UNUSED_IMPORT = const HintCode(
      'UNUSED_IMPORT', "Unused import: '{0}'.",
      correction: "Try removing the import directive.", hasPublishedDocs: true);

  /**
   * Unused labels are labels that are never referenced in either a 'break' or
   * 'continue' statement.
   */
  static const HintCode UNUSED_LABEL =
      const HintCode('UNUSED_LABEL', "The label '{0}' isn't used.",
          correction: "Try removing the label, or "
              "using it in either a 'break' or 'continue' statement.");

  /**
   * Parameters:
   * 0: the name of the unused variable
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a local variable is declared but
  // never read, even if it's written in one or more places.
  //
  // #### Example
  //
  // The following code produces this diagnostic:
  //
  // ```dart
  // void main() {
  //   int [!count!] = 0;
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the variable isn't needed, then remove it.
  //
  // If the variable was intended to be used, then add the missing code.
  static const HintCode UNUSED_LOCAL_VARIABLE = const HintCode(
      'UNUSED_LOCAL_VARIABLE',
      "The value of the local variable '{0}' isn't used.",
      correction: "Try removing the variable, or using it.",
      hasPublishedDocs: true);

  /**
   * Unused shown names are names shown on imports which are never used.
   */
  static const HintCode UNUSED_SHOWN_NAME = const HintCode(
      'UNUSED_SHOWN_NAME', "The name {0} is shown, but not used.",
      correction: "Try removing the name from the list of shown members.");

  /**
   * Initialize a newly created error code to have the given [name]. The message
   * associated with the error will be created from the given [message]
   * template. The correction associated with the error will be created from the
   * given [correction] template.
   */
  const HintCode(String name, String message,
      {String correction, bool hasPublishedDocs})
      : super.temporary(name, message,
            correction: correction, hasPublishedDocs: hasPublishedDocs);

  @override
  ErrorSeverity get errorSeverity => ErrorType.HINT.severity;

  @override
  ErrorType get type => ErrorType.HINT;
}
