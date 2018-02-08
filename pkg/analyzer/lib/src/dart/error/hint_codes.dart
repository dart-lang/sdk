// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.dart.error.hint_codes;

import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/element/element.dart';

/**
 * The hints and coding recommendations for best practices which are not
 * mentioned in the Dart Language Specification.
 */
class HintCode extends ErrorCode {
  /**
   * When an abstract supertype member is referenced with `super` as its target,
   * it cannot be overridden, so it is always a runtime error.
   *
   * Parameters:
   * 0: the display name for the kind of the referenced element
   * 1: the name of the referenced element
   */
  static const HintCode ABSTRACT_SUPER_MEMBER_REFERENCE = const HintCode(
      'ABSTRACT_SUPER_MEMBER_REFERENCE',
      "The {0} '{1}' is always abstract in the supertype.");

  /**
   * This hint is generated anywhere where the
   * [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE] would have been generated,
   * if we used propagated information for the warnings.
   *
   * Parameters:
   * 0: the name of the actual argument type
   * 1: the name of the expected type
   */
  static const HintCode ARGUMENT_TYPE_NOT_ASSIGNABLE = const HintCode(
      'ARGUMENT_TYPE_NOT_ASSIGNABLE',
      "The argument type '{0}' can't be assigned to the parameter type '{1}'.");

  /**
   * When the target expression uses '?.' operator, it can be `null`, so all the
   * subsequent invocations should also use '?.' operator.
   */
  static const HintCode CAN_BE_NULL_AFTER_NULL_AWARE = const HintCode(
      'CAN_BE_NULL_AFTER_NULL_AWARE',
      "The target expression uses '?.', so its value can be null.",
      "Replace the '.' with a '?.' in the invocation.");

  /**
   * Dead code is code that is never reached, this can happen for instance if a
   * statement follows a return statement.
   */
  static const HintCode DEAD_CODE = const HintCode(
      'DEAD_CODE',
      "Dead code.",
      "Try removing the code, or "
      "fixing the code before it so that it can be reached.");

  /**
   * Dead code is code that is never reached. This case covers cases where the
   * user has catch clauses after `catch (e)` or `on Object catch (e)`.
   */
  static const HintCode DEAD_CODE_CATCH_FOLLOWING_CATCH = const HintCode(
      'DEAD_CODE_CATCH_FOLLOWING_CATCH',
      "Dead code: catch clauses after a 'catch (e)' or "
      "an 'on Object catch (e)' are never reached.",
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
      "Try reordering the catch clauses so that this block can be reached, or "
      "removing the unreachable catch clause.");

  /**
   * Deprecated members should not be invoked or used.
   *
   * Parameters:
   * 0: the name of the member
   */
  static const HintCode DEPRECATED_MEMBER_USE = const HintCode(
      'DEPRECATED_MEMBER_USE',
      "'{0}' is deprecated and shouldn't be used.",
      "Try replacing the use of the deprecated member with the replacement.");

  /**
   * Users should not create a class named `Function` anymore.
   */
  static const HintCode DEPRECATED_FUNCTION_CLASS_DECLARATION = const HintCode(
      'DEPRECATED_FUNCTION_CLASS_DECLARATION',
      "Declaring a class named 'Function' is deprecated.",
      "Try renaming the class.");

  /**
   * `Function` should not be extended anymore.
   */
  static const HintCode DEPRECATED_EXTENDS_FUNCTION = const HintCode(
      'DEPRECATED_EXTENDS_FUNCTION',
      "Extending 'Function' is deprecated.",
      "Try removing 'Function' from the 'extends' clause.");

  /**
   * `Function` should not be mixed in anymore.
   */
  static const HintCode DEPRECATED_MIXIN_FUNCTION = const HintCode(
      'DEPRECATED_MIXIN_FUNCTION',
      "Mixing in 'Function' is deprecated.",
      "Try removing 'Function' from the 'with' clause.");

  /**
   * Hint to use the ~/ operator.
   */
  static const HintCode DIVISION_OPTIMIZATION = const HintCode(
      'DIVISION_OPTIMIZATION',
      "The operator x ~/ y is more efficient than (x / y).toInt().",
      "Try re-writing the expression to use the '~/' operator.");

  /**
   * Duplicate imports.
   */
  static const HintCode DUPLICATE_IMPORT = const HintCode('DUPLICATE_IMPORT',
      "Duplicate import.", "Try removing all but one import of the library.");

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
          "Try removing the import, or "
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
          "Try using a package: URI instead.");

  /**
   * Generic type comments (`/*<T>*/` and `/*=T*/`) are no longer necessary and
   * will soon be ignored.
   */
  static const HintCode GENERIC_METHOD_COMMENT = const HintCode(
      'GENERIC_METHOD_COMMENT',
      "The generic type comment is being deprecated in favor of the real syntax.",
      "Try replacing the comment with the actual type annotation.");

  /**
   * Deferred libraries shouldn't define a top level function 'loadLibrary'.
   */
  static const HintCode IMPORT_DEFERRED_LIBRARY_WITH_LOAD_FUNCTION =
      const HintCode(
          'IMPORT_DEFERRED_LIBRARY_WITH_LOAD_FUNCTION',
          "The library '{0}' defines a top-level function named 'loadLibrary' "
          "which is hidden by deferring this library.",
          "Try changing the import to not be deferred, or "
          "rename the function in the imported library.");

  /**
   * This hint is generated anywhere where the
   * [StaticTypeWarningCode.INVALID_ASSIGNMENT] would have been generated, if we
   * used propagated information for the warnings.
   *
   * Parameters:
   * 0: the name of the right hand side type
   * 1: the name of the left hand side type
   */
  static const HintCode INVALID_ASSIGNMENT = const HintCode(
      'INVALID_ASSIGNMENT',
      "A value of type '{0}' can't be assigned to a variable of type '{1}'.",
      "Try changing the type of the variable, or "
      "casting the right-hand type to '{1}'.");

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
   * Generic Method DEP: number of type parameters must match.
   * <https://github.com/leafpetersen/dep-generic-methods/blob/master/proposal.md#function-subtyping>
   *
   * Parameters:
   * 0: the number of type parameters in the method
   * 1: the number of type parameters in the overridden method
   * 2: the name of the class where the overridden method is declared
   */
  static const HintCode INVALID_METHOD_OVERRIDE_TYPE_PARAMETERS = const HintCode(
      'INVALID_METHOD_OVERRIDE_TYPE_PARAMETERS',
      "The method has {0} type parameters, but it is overriding a method "
      "with {1} type parameters from '{2}'.",
      "Try changing the number of type parameters so that they are the same.");

  /**
   * Generic Method DEP: bounds of type parameters must be compatible.
   * <https://github.com/leafpetersen/dep-generic-methods/blob/master/proposal.md#function-subtyping>
   *
   * Parameters:
   * 0: the type parameter name
   * 1: the type parameter bound
   * 2: the overridden type parameter name
   * 3: the overridden type parameter bound
   * 4: the name of the class where the overridden method is declared
   */
  static const HintCode INVALID_METHOD_OVERRIDE_TYPE_PARAMETER_BOUND =
      const HintCode(
          'INVALID_METHOD_OVERRIDE_TYPE_PARAMETER_BOUND',
          "The type parameter '{0}' extends '{1}', but that is stricter than "
          "'{2}' extends '{3}' in the overridden method from '{4}'.",
          "Try changing the bounds on the type parameters so that they are compatible.");

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
      "Remove @required.");

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
  /// `@visibleForTesting` is used outside the defining library, or a test.
  ///
  /// Parameters:
  /// 0: the name of the member
  /// 1: the name of the defining class
  static const HintCode INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER =
      const HintCode('INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER',
          "The member '{0}' can only be used within '{1}' or a test.");

  /**
   * Hint for the `x is double` type checks.
   */
  static const HintCode IS_DOUBLE = const HintCode(
      'IS_DOUBLE',
      "When compiled to JS, this test might return true when the left hand "
      "side is an int.",
      "Try testing for 'num' instead.");

  /**
   * Hint for the `x is int` type checks.
   */
  static const HintCode IS_INT = const HintCode(
      'IS_INT',
      "When compiled to JS, this test might return true when the left hand "
      "side is a double.",
      "Try testing for 'num' instead.");

  /**
   * Hint for the `x is! double` type checks.
   */
  static const HintCode IS_NOT_DOUBLE = const HintCode(
      'IS_NOT_DOUBLE',
      "When compiled to JS, this test might return false when the left hand "
      "side is an int.",
      "Try testing for 'num' instead.");

  /**
   * Hint for the `x is! int` type checks.
   */
  static const HintCode IS_NOT_INT = const HintCode(
      'IS_NOT_INT',
      "When compiled to JS, this test might return false when the left hand "
      "side is a double.",
      "Try testing for 'num' instead.");

  /**
   * Generate a hint for an element that is annotated with `@JS(...)` whose
   * library declaration is not similarly annotated.
   */
  static const HintCode MISSING_JS_LIB_ANNOTATION = const HintCode(
      'MISSING_JS_LIB_ANNOTATION',
      "The @JS() annotation can only be used if it is also declared on the "
      "library directive.",
      "Try adding the annotation to the library directive.");

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
      "This function declares a return type of '{0}', but doesn't end with a "
      "return statement.",
      "Try adding a return statement, or changing the return type to 'void'.");

  /**
   * Generate a hint for classes that inherit from classes annotated with
   * `@immutable` but that are not immutable.
   */
  static const HintCode MUST_BE_IMMUTABLE = const HintCode(
      'MUST_BE_IMMUTABLE',
      "This class inherits from a class marked as @immutable, "
      "and therefore should be immutable (all instance fields must be final).");

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
   * A condition in a control flow statement could evaluate to `null` because it
   * uses the null-aware '?.' operator.
   */
  static const HintCode NULL_AWARE_IN_CONDITION = const HintCode(
      'NULL_AWARE_IN_CONDITION',
      "The value of the '?.' operator can be 'null', which isn't appropriate "
      "in a condition.",
      "Try replacing the '?.' with a '.', testing the left-hand side for null if "
      "necessary.");

  /**
   * Hint for classes that override equals, but not hashCode.
   *
   * Parameters:
   * 0: the name of the current class
   */
  static const HintCode OVERRIDE_EQUALS_BUT_NOT_HASH_CODE = const HintCode(
      'OVERRIDE_EQUALS_BUT_NOT_HASH_CODE',
      "The class '{0}' overrides 'operator==', but not 'get hashCode'.",
      "Try implementing 'hashCode'.");

  /**
   * A getter with the override annotation does not override an existing getter.
   */
  static const HintCode OVERRIDE_ON_NON_OVERRIDING_GETTER = const HintCode(
      'OVERRIDE_ON_NON_OVERRIDING_GETTER',
      "Getter doesn't override an inherited getter.",
      "Try updating this class to match the superclass, or "
      "removing the override annotation.");

  /**
   * A field with the override annotation does not override a getter or setter.
   */
  static const HintCode OVERRIDE_ON_NON_OVERRIDING_FIELD = const HintCode(
      'OVERRIDE_ON_NON_OVERRIDING_FIELD',
      "Field doesn't override an inherited getter or setter.",
      "Try updating this class to match the superclass, or "
      "removing the override annotation.");

  /**
   * A method with the override annotation does not override an existing method.
   */
  static const HintCode OVERRIDE_ON_NON_OVERRIDING_METHOD = const HintCode(
      'OVERRIDE_ON_NON_OVERRIDING_METHOD',
      "Method doesn't override an inherited method.",
      "Try updating this class to match the superclass, or "
      "removing the override annotation.");

  /**
   * A setter with the override annotation does not override an existing setter.
   */
  static const HintCode OVERRIDE_ON_NON_OVERRIDING_SETTER = const HintCode(
      'OVERRIDE_ON_NON_OVERRIDING_SETTER',
      "Setter doesn't override an inherited setter.",
      "Try updating this class to match the superclass, or "
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
   * Type checks of the type `x is! Null` should be done with `x != null`.
   */
  static const HintCode TYPE_CHECK_IS_NOT_NULL = const HintCode(
      'TYPE_CHECK_IS_NOT_NULL',
      "Tests for non-null should be done with '!= null'.",
      "Try replacing the 'is! Null' check with '!= null'.");

  /**
   * Type checks of the type `x is Null` should be done with `x == null`.
   */
  static const HintCode TYPE_CHECK_IS_NULL = const HintCode(
      'TYPE_CHECK_IS_NULL',
      "Tests for null should be done with '== null'.",
      "Try replacing the 'is Null' check with '== null'.");

  /**
   * This hint is generated anywhere where the
   * [StaticTypeWarningCode.UNDEFINED_GETTER] or
   * [StaticWarningCode.UNDEFINED_GETTER] would have been generated, if we used
   * propagated information for the warnings.
   *
   * Parameters:
   * 0: the name of the getter
   * 1: the name of the enclosing type where the getter is being looked for
   */
  static const HintCode UNDEFINED_GETTER = const HintCode(
      'UNDEFINED_GETTER',
      "The getter '{0}' isn't defined for the class '{1}'.",
      "Try defining a getter or field named '{0}', or invoke a different getter.");

  /**
   * An undefined name hidden in an import or export directive.
   */
  static const HintCode UNDEFINED_HIDDEN_NAME = const HintCode(
      'UNDEFINED_HIDDEN_NAME',
      "The library '{0}' doesn't export a member with the hidden name '{1}'.",
      "Try removing the name from the list of hidden members.");

  /**
   * This hint is generated anywhere where the
   * [StaticTypeWarningCode.UNDEFINED_METHOD] would have been generated, if we
   * used propagated information for the warnings.
   *
   * Parameters:
   * 0: the name of the method that is undefined
   * 1: the resolved type name that the method lookup is happening on
   */
  static const HintCode UNDEFINED_METHOD = const HintCode(
      'UNDEFINED_METHOD',
      "The method '{0}' isn't defined for the class '{1}'.",
      "Try correcting the name to the name of an existing method, or "
      "defining a method named '{0}'.");

  /**
   * This hint is generated anywhere where the
   * [StaticTypeWarningCode.UNDEFINED_OPERATOR] would have been generated, if we
   * used propagated information for the warnings.
   *
   * Parameters:
   * 0: the name of the operator
   * 1: the name of the enclosing type where the operator is being looked for
   */
  static const HintCode UNDEFINED_OPERATOR = const HintCode(
      'UNDEFINED_OPERATOR',
      "The operator '{0}' isn't defined for the class '{1}'.",
      "Try defining the operator '{0}'.");

  /**
   * This hint is generated anywhere where the
   * [StaticTypeWarningCode.UNDEFINED_SETTER] or
   * [StaticWarningCode.UNDEFINED_SETTER] would have been generated, if we used
   * propagated information for the warnings.
   *
   * Parameters:
   * 0: the name of the setter
   * 1: the name of the enclosing type where the setter is being looked for
   */
  static const HintCode UNDEFINED_SETTER = const HintCode(
      'UNDEFINED_SETTER',
      "The setter '{0}' isn't defined for the class '{1}'.",
      "Try defining a setter or field named '{0}', or invoke a different setter.");

  /**
   * An undefined name shown in an import or export directive.
   */
  static const HintCode UNDEFINED_SHOWN_NAME = const HintCode(
      'UNDEFINED_SHOWN_NAME',
      "The library '{0}' doesn't export a member with the shown name '{1}'.",
      "Try removing the name from the list of shown members.");

  /**
   * Unnecessary cast.
   */
  static const HintCode UNNECESSARY_CAST = const HintCode(
      'UNNECESSARY_CAST', "Unnecessary cast.", "Try removing the cast.");

  /**
   * Unnecessary `noSuchMethod` declaration.
   */
  static const HintCode UNNECESSARY_NO_SUCH_METHOD = const HintCode(
      'UNNECESSARY_NO_SUCH_METHOD',
      "Unnecessary 'noSuchMethod' declaration.",
      "Try removing the declaration of 'noSuchMethod'.");

  /**
   * Unnecessary type checks, the result is always false.
   */
  static const HintCode UNNECESSARY_TYPE_CHECK_FALSE = const HintCode(
      'UNNECESSARY_TYPE_CHECK_FALSE',
      "Unnecessary type check, the result is always false.",
      "Try correcting the type check, or removing the type check.");

  /**
   * Unnecessary type checks, the result is always true.
   */
  static const HintCode UNNECESSARY_TYPE_CHECK_TRUE = const HintCode(
      'UNNECESSARY_TYPE_CHECK_TRUE',
      "Unnecessary type check, the result is always true.",
      "Try correcting the type check, or removing the type check.");

  /**
   * Unused catch exception variables.
   */
  static const HintCode UNUSED_CATCH_CLAUSE = const HintCode(
      'UNUSED_CATCH_CLAUSE',
      "The exception variable '{0}' isn't used, so the 'catch' clause can be removed.",
      // TODO(brianwilkerson) Split this error code so that we can differentiate
      // between removing the catch clause and replacing the catch clause with
      // an on clause.
      "Try removing the catch clause.");

  /**
   * Unused catch stack trace variables.
   */
  static const HintCode UNUSED_CATCH_STACK = const HintCode(
      'UNUSED_CATCH_STACK',
      "The stack trace variable '{0}' isn't used and can be removed.",
      "Try removing the stack trace variable, or using it.");

  /**
   * See [Modifier.IS_USED_IN_LIBRARY].
   */
  static const HintCode UNUSED_ELEMENT = const HintCode('UNUSED_ELEMENT',
      "The {0} '{1}' isn't used.", "Try removing the declaration of '{1}'.");

  /**
   * Unused fields are fields which are never read.
   */
  static const HintCode UNUSED_FIELD = const HintCode(
      'UNUSED_FIELD',
      "The value of the field '{0}' isn't used.",
      "Try removing the field, or using it.");

  /**
   * Unused imports are imports which are never used.
   *
   * Parameters:
   * 0: The content of the unused import's uri
   */
  static const HintCode UNUSED_IMPORT = const HintCode('UNUSED_IMPORT',
      "Unused import: '{0}'.", "Try removing the import directive.");

  /**
   * Unused labels are labels that are never referenced in either a 'break' or
   * 'continue' statement.
   */
  static const HintCode UNUSED_LABEL = const HintCode(
      'UNUSED_LABEL',
      "The label '{0}' isn't used.",
      "Try removing the label, or "
      "using it in either a 'break' or 'continue' statement.");

  /**
   * Unused local variables are local variables that are never read.
   */
  static const HintCode UNUSED_LOCAL_VARIABLE = const HintCode(
      'UNUSED_LOCAL_VARIABLE',
      "The value of the local variable '{0}' isn't used.",
      "Try removing the variable, or using it.");

  /**
   * Unused shown names are names shown on imports which are never used.
   */
  static const HintCode UNUSED_SHOWN_NAME = const HintCode(
      'UNUSED_SHOWN_NAME',
      "The name {0} is shown, but not used.",
      "Try removing the name from the list of shown members.");

  /**
   * It will be a static type warning if <i>m</i> is not a generic method with
   * exactly <i>n</i> type parameters.
   *
   * Parameters:
   * 0: the name of the method being referenced (<i>G</i>)
   * 1: the number of type parameters that were declared
   * 2: the number of type arguments provided
   */
  static const HintCode WRONG_NUMBER_OF_TYPE_ARGUMENTS_METHOD = const HintCode(
      'WRONG_NUMBER_OF_TYPE_ARGUMENTS_METHOD',
      "The method '{0}' is declared with {1} type parameters, "
      "but {2} type arguments were given.",
      "Try adjusting the number of type arguments.");

  /**
   * Initialize a newly created error code to have the given [name]. The message
   * associated with the error will be created from the given [message]
   * template. The correction associated with the error will be created from the
   * given [correction] template.
   */
  const HintCode(String name, String message, [String correction])
      : super(name, message, correction);

  @override
  ErrorSeverity get errorSeverity => ErrorType.HINT.severity;

  @override
  ErrorType get type => ErrorType.HINT;
}
