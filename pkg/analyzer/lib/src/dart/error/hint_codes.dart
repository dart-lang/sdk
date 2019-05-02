// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/element/element.dart';

/**
 * The hints and coding recommendations for best practices which are not
 * mentioned in the Dart Language Specification.
 */
class HintCode extends ErrorCode {
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
          "Try reordering the catch clauses so that this block can be reached, or "
          "removing the unreachable catch clause.");

  /**
   * Deprecated members should not be invoked or used.
   *
   * Parameters:
   * 0: the name of the member
   */
  static const HintCode DEPRECATED_MEMBER_USE = const HintCode(
      'DEPRECATED_MEMBER_USE', "'{0}' is deprecated and shouldn't be used.",
      correction:
          "Try replacing the use of the deprecated member with the replacement.");

  /**
   * Deprecated members should not be invoked or used from within the package
   * where they are declared.
   *
   * Intentionally separate from DEPRECATED_MEMBER_USE, so that package owners
   * can ignore same-package deprecate member use Hints if they like, and
   * continue to see cross-package deprecated member use Hints.
   *
   * Parameters:
   * 0: the name of the member
   */
  static const HintCode DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE = const HintCode(
      'DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE',
      "'{0}' is deprecated and shouldn't be used.",
      correction:
          "Try replacing the use of the deprecated member with the replacement.");

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
      "The type argument(s) of '{0}' cannot be inferred.",
      correction: "Use explicit type argument(s) for '{0}'.");

  /**
   * When "strict-inference" is enabled, types in instance creation
   * (constructor calls) must be inferred via the context type, or have type
   * arguments.
   */
  static const HintCode INFERENCE_FAILURE_ON_INSTANCE_CREATION = HintCode(
      'INFERENCE_FAILURE_ON_INSTANCE_CREATION',
      "The type argument(s) of '{0}' cannot be inferred.",
      correction: "Use explicit type argument(s) for '{0}'.");

  /**
   * When "strict-inference" in enabled, uninitialized variables must be
   * declared with a specific type.
   */
  static const HintCode INFERENCE_FAILURE_ON_UNINITIALIZED_VARIABLE =
      const HintCode(
          'INFERENCE_FAILURE_ON_UNINITIALIZED_VARIABLE',
          "The type of {0} cannot be inferred without either a type or "
              "initializer.",
          correction: "Try specifying the type of the variable.");

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
   * This hint is generated anywhere a @literal annotation is associated with
   * anything other than a const constructor.
   */
  static const HintCode INVALID_LITERAL_ANNOTATION = const HintCode(
      'INVALID_LITERAL_ANNOTATION',
      "Only const constructors can be annotated as being literal.");

  /**
   * This hint is generated anywhere where `@required` annotates a non named
   * parameter or a named parameter with default value.
   *
   * Parameters:
   * 0: the name of the member
   */
  static const HintCode INVALID_REQUIRED_PARAM = const HintCode(
      'INVALID_REQUIRED_PARAM',
      "The type parameter '{0}' is annotated with @required but only named "
          "parameters without default value can be annotated with it.",
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
      const HintCode('INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER',
          "The member '{0}' can only be used within '{1}' or a template library.");

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
   * Generate a hint for methods or functions that have a return type, but do
   * not have a non-void return statement on all branches. At the end of methods
   * or functions with no return, Dart implicitly returns `null`, avoiding these
   * implicit returns is considered a best practice.
   *
   * Parameters:
   * 0: the name of the declared return type
   */
  static const HintCode MISSING_RETURN = const HintCode(
      'MISSING_RETURN',
      "This function has a return type of '{0}', but doesn't end with a "
          "return statement.",
      correction: "Try adding a return statement, "
          "or changing the return type to 'void'.");

  /**
   * This hint is generated anywhere where a `@sealed` class is used as a
   * a superclass constraint of a mixin.
   */
  static const HintCode MIXIN_ON_SEALED_CLASS = const HintCode(
      'MIXIN_ON_SEALED_CLASS',
      "The class '{0}' should not be used as a mixin constraint because it is "
          "sealed, and any class mixing in this mixin has '{0}' as a superclass.",
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
          "but does not invoke the overridden method.");

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
          "This instance creation must be 'const', because the {0} constructor is "
              "marked as '@literal'.",
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
          "Try replacing the '?.' with a '.', testing the left-hand side for null if "
          "necessary.");

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
   * A class defined in `dart:async` that was not exported from `dart:core`
   * before version 2.1 is being referenced via `dart:core` in code that is
   * expected to run on earlier versions.
   */
  static const HintCode SDK_VERSION_ASYNC_EXPORTED_FROM_CORE = const HintCode(
      'SDK_VERSION_ASYNC_EXPORTED_FROM_CORE',
      "The class '{0}' was not exported from 'dart:core' until version 2.1, "
          "but this code is required to be able to run on earlier versions.",
      correction:
          "Try either importing 'dart:async' or updating the SDK constraints.");

  /**
   * An as expression being used in a const context is expected to run on
   * versions of the SDK that did not support them.
   */
  static const HintCode SDK_VERSION_AS_EXPRESSION_IN_CONST_CONTEXT = const HintCode(
      'SDK_VERSION_AS_EXPRESSION_IN_CONST_CONTEXT',
      "The use of an as expression in a constant expression wasn't "
          "supported until version 2.2.2, but this code is required to be able "
          "to run on earlier versions.",
      correction: "Try updating the SDK constraints.");

  /**
   * The operator '&', '|' or '^' is being used on boolean values in code that
   * is expected to run on versions of the SDK that did not support it.
   */
  static const HintCode SDK_VERSION_BOOL_OPERATOR = const HintCode(
      'SDK_VERSION_BOOL_OPERATOR',
      "Using the operator '{0}' for 'bool's was not supported until version "
          "2.2.2, but this code is required to be able to run on earlier versions.",
      correction: "Try updating the SDK constraints.");

  /**
   * The operator '==' is being used on non-primitive values in code that
   * is expected to run on versions of the SDK that did not support it.
   */
  static const HintCode SDK_VERSION_EQ_EQ_OPERATOR_IN_CONST_CONTEXT = const HintCode(
      'SDK_VERSION_EQ_EQ_OPERATOR_IN_CONST_CONTEXT',
      "Using the operator '==' for non-primitive types was not supported until "
          "version 2.2.2, but this code is required to be able to run on earlier "
          "versions.",
      correction: "Try updating the SDK constraints.");

  /**
   * The operator '>>>' is being used in code that is expected to run on
   * versions of the SDK that did not support it.
   */
  static const HintCode SDK_VERSION_GT_GT_GT_OPERATOR = const HintCode(
      'SDK_VERSION_GT_GT_GT_OPERATOR',
      "The operator '>>>' was not supported until version 2.2.2, but this code "
          "is required to be able to run on earlier versions.",
      correction: "Try updating the SDK constraints.");

  /**
   * An is expression being used in a const context is expected to run on
   * versions of the SDK that did not support them.
   */
  static const HintCode SDK_VERSION_IS_EXPRESSION_IN_CONST_CONTEXT = const HintCode(
      'SDK_VERSION_IS_EXPRESSION_IN_CONST_CONTEXT',
      "The use of an is expression in a constant expression wasn't "
          "supported until version 2.2.2, but this code is required to be able "
          "to run on earlier versions.",
      correction: "Try updating the SDK constraints.");

  /**
   * A set literal is being used in code that is expected to run on versions of
   * the SDK that did not support them.
   */
  static const HintCode SDK_VERSION_SET_LITERAL = const HintCode(
      'SDK_VERSION_SET_LITERAL',
      "Set literals were not supported until version 2.2, "
          "but this code is required to be able to run on earlier versions.",
      correction: "Try updating the SDK constraints.");

  /**
   * The type Never is being used in code that is expected to run on versions of
   * the SDK that did not support it.
   */
  static const HintCode SDK_VERSION_NEVER = const HintCode(
      'SDK_VERSION_NEVER', "The type Never is not yet supported.");

  /**
   * The for, if or spread element is being used in code that is expected to run
   * on versions of the SDK that did not support them.
   */
  static const HintCode SDK_VERSION_UI_AS_CODE = const HintCode(
      'SDK_VERSION_UI_AS_CODE',
      "The for, if and spread elements were not supported until version 2.2.2, "
          "but this code is required to be able to run on earlier versions.",
      correction: "Try updating the SDK constraints.");

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
      "The class '{0}' should not be extended, mixed in, or implemented "
          "because it is sealed.",
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
   * When the '?.' operator is used on a target that we know to be non-null,
   * it is unnecessary.
   */
  static const HintCode UNNECESSARY_NULL_AWARE_CALL = const HintCode(
      'UNNECESSARY_NULL_AWARE_CALL',
      "The target expression cannot be null, and so '?.' is not necessary.",
      correction: "Replace the '?.' with a '.' in the invocation.");

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
      "The exception variable '{0}' isn't used, so the 'catch' clause can be removed.",
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
   * See [Modifier.IS_USED_IN_LIBRARY].
   */
  static const HintCode UNUSED_ELEMENT = const HintCode(
      'UNUSED_ELEMENT', "The {0} '{1}' isn't used.",
      correction: "Try removing the declaration of '{1}'.");

  /**
   * Unused fields are fields which are never read.
   */
  static const HintCode UNUSED_FIELD = const HintCode(
      'UNUSED_FIELD', "The value of the field '{0}' isn't used.",
      correction: "Try removing the field, or using it.");

  /**
   * Unused imports are imports which are never used.
   *
   * Parameters:
   * 0: The content of the unused import's uri
   */
  static const HintCode UNUSED_IMPORT = const HintCode(
      'UNUSED_IMPORT', "Unused import: '{0}'.",
      correction: "Try removing the import directive.");

  /**
   * Unused labels are labels that are never referenced in either a 'break' or
   * 'continue' statement.
   */
  static const HintCode UNUSED_LABEL =
      const HintCode('UNUSED_LABEL', "The label '{0}' isn't used.",
          correction: "Try removing the label, or "
              "using it in either a 'break' or 'continue' statement.");

  /**
   * Unused local variables are local variables that are never read.
   */
  static const HintCode UNUSED_LOCAL_VARIABLE = const HintCode(
      'UNUSED_LOCAL_VARIABLE',
      "The value of the local variable '{0}' isn't used.",
      correction: "Try removing the variable, or using it.");

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
  const HintCode(String name, String message, {String correction})
      : super.temporary(name, message, correction: correction);

  @override
  ErrorSeverity get errorSeverity => ErrorType.HINT.severity;

  @override
  ErrorType get type => ErrorType.HINT;
}
