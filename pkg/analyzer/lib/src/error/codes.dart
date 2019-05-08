// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';

export 'package:analyzer/src/analysis_options/error/option_codes.dart';
export 'package:analyzer/src/dart/error/hint_codes.dart';
export 'package:analyzer/src/dart/error/lint_codes.dart';
export 'package:analyzer/src/dart/error/todo_codes.dart';

/**
 * The error codes used for compile time errors caused by constant evaluation
 * that would throw an exception when run in checked mode. The client of the
 * analysis engine is responsible for determining how these errors should be
 * presented to the user (for example, a command-line compiler might elect to
 * treat these errors differently depending whether it is compiling it "checked"
 * mode).
 */
class CheckedModeCompileTimeErrorCode extends ErrorCode {
  // TODO(paulberry): improve the text of these error messages so that it's
  // clear to the user that the error is coming from constant evaluation (and
  // hence the constant needs to be a subtype of the annotated type) as opposed
  // to static type analysis (which only requires that the two types be
  // assignable).  Also consider populating the "correction" field for these
  // errors.

  /**
   * 16.12.2 Const: It is a compile-time error if evaluation of a constant
   * object results in an uncaught exception being thrown.
   */
  static const CheckedModeCompileTimeErrorCode
      CONST_CONSTRUCTOR_FIELD_TYPE_MISMATCH =
      const CheckedModeCompileTimeErrorCode(
          'CONST_CONSTRUCTOR_FIELD_TYPE_MISMATCH',
          "A value of type '{0}' can't be assigned to the field '{1}', which "
              "has type '{2}'.");

  /**
   * 16.12.2 Const: It is a compile-time error if evaluation of a constant
   * object results in an uncaught exception being thrown.
   */
  static const CheckedModeCompileTimeErrorCode
      CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH =
      const CheckedModeCompileTimeErrorCode(
          'CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH',
          "A value of type '{0}' can't be assigned to a parameter of type "
              "'{1}'.");

  /**
   * 7.6.1 Generative Constructors: In checked mode, it is a dynamic type error
   * if o is not <b>null</b> and the interface of the class of <i>o</i> is not a
   * subtype of the static type of the field <i>v</i>.
   *
   * 16.12.2 Const: It is a compile-time error if evaluation of a constant
   * object results in an uncaught exception being thrown.
   *
   * Parameters:
   * 0: the name of the type of the initializer expression
   * 1: the name of the type of the field
   */
  static const CheckedModeCompileTimeErrorCode
      CONST_FIELD_INITIALIZER_NOT_ASSIGNABLE =
      const CheckedModeCompileTimeErrorCode(
          'CONST_FIELD_INITIALIZER_NOT_ASSIGNABLE',
          "The initializer type '{0}' can't be assigned to the field type "
              "'{1}'.");

  /**
   * 16.12.2 Const: It is a compile-time error if evaluation of a constant
   * object results in an uncaught exception being thrown.
   */
  static const CheckedModeCompileTimeErrorCode VARIABLE_TYPE_MISMATCH =
      const CheckedModeCompileTimeErrorCode(
          'VARIABLE_TYPE_MISMATCH',
          "A value of type '{0}' can't be assigned to a variable of type "
              "'{1}'.");

  /**
   * Initialize a newly created error code to have the given [name]. The message
   * associated with the error will be created from the given [message]
   * template. The correction associated with the error will be created from the
   * given [correction] template.
   */
  const CheckedModeCompileTimeErrorCode(String name, String message,
      {String correction})
      : super.temporary(name, message, correction: correction);

  @override
  ErrorSeverity get errorSeverity =>
      ErrorType.CHECKED_MODE_COMPILE_TIME_ERROR.severity;

  @override
  ErrorType get type => ErrorType.CHECKED_MODE_COMPILE_TIME_ERROR;
}

/**
 * The error codes used for compile time errors. The convention for this class
 * is for the name of the error code to indicate the problem that caused the
 * error to be generated and for the error message to explain what is wrong and,
 * when appropriate, how the problem can be corrected.
 */
class CompileTimeErrorCode extends ErrorCode {
  /**
   * Member lookups ignore abstract declarations, which means that there will
   * be a compile-time error if the targeted member `m` is abstract, as well as
   * when it does not exist at all.
   *
   * Parameters:
   * 0: the display name for the kind of the found abstract member
   * 1: the name of the member
   */
  static const CompileTimeErrorCode ABSTRACT_SUPER_MEMBER_REFERENCE =
      const CompileTimeErrorCode('ABSTRACT_SUPER_MEMBER_REFERENCE',
          "The {0} '{1}' is always abstract in the supertype.");

  /**
   * Enum proposal: It is also a compile-time error to explicitly instantiate an
   * enum via 'new' or 'const' or to access its private fields.
   */
  static const CompileTimeErrorCode ACCESS_PRIVATE_ENUM_FIELD =
      const CompileTimeErrorCode(
          'ACCESS_PRIVATE_ENUM_FIELD',
          "The private fields of an enum can't be accessed, even within the "
              "same library.");

  /**
   * 14.2 Exports: It is a compile-time error if a name <i>N</i> is re-exported
   * by a library <i>L</i> and <i>N</i> is introduced into the export namespace
   * of <i>L</i> by more than one export, unless each all exports refer to same
   * declaration for the name N.
   *
   * Parameters:
   * 0: the name of the ambiguous element
   * 1: the name of the first library in which the type is found
   * 2: the name of the second library in which the type is found
   */
  static const CompileTimeErrorCode AMBIGUOUS_EXPORT =
      const CompileTimeErrorCode('AMBIGUOUS_EXPORT',
          "The name '{0}' is defined in the libraries '{1}' and '{2}'.",
          correction: "Try removing the export of one of the libraries, or "
              "explicitly hiding the name in one of the export directives.");

  static const CompileTimeErrorCode AMBIGUOUS_SET_OR_MAP_LITERAL_BOTH =
      const CompileTimeErrorCode(
          'AMBIGUOUS_SET_OR_MAP_LITERAL_BOTH',
          "This literal must be both a map and a set, because some elements "
              "spread a 'Map' and others spread an 'Iterable', but that isn't "
              "allowed.",
          correction:
              "Try removing or changing some of the elements so that all of "
              "the elements are consistent.");

  static const CompileTimeErrorCode AMBIGUOUS_SET_OR_MAP_LITERAL_EITHER =
      const CompileTimeErrorCode(
          'AMBIGUOUS_SET_OR_MAP_LITERAL_EITHER',
          "This literal must be either a map or a set, but none of the "
              "elements have enough type information to know which, and that isn't "
              "allowed.",
          correction:
              "Try adding type arguments to the literal (one for sets, two "
              "for maps).");

  /**
   * 15 Metadata: The constant expression given in an annotation is type checked
   * and evaluated in the scope surrounding the declaration being annotated.
   *
   * 16.12.2 Const: It is a compile-time error if <i>T</i> is not a class
   * accessible in the current scope, optionally followed by type arguments.
   *
   * 16.12.2 Const: If <i>e</i> is of the form <i>const T.id(a<sub>1</sub>,
   * &hellip;, a<sub>n</sub>, x<sub>n+1</sub>: a<sub>n+1</sub>, &hellip;
   * x<sub>n+k</sub>: a<sub>n+k</sub>)</i> it is a compile-time error if
   * <i>T</i> is not a class accessible in the current scope, optionally
   * followed by type arguments.
   *
   * Parameters:
   * 0: the name of the non-type element
   */
  static const CompileTimeErrorCode ANNOTATION_WITH_NON_CLASS =
      const CompileTimeErrorCode(
          'ANNOTATION_WITH_NON_CLASS', "The name '{0}' isn't a class.",
          correction: "Try importing the library that declares the class, "
              "correcting the name to match a defined class, or "
              "defining a class with the given name.");

  static const CompileTimeErrorCode ANNOTATION_WITH_TYPE_ARGUMENTS =
      const CompileTimeErrorCode('ANNOTATION_WITH_TYPE_ARGUMENTS',
          "An annotation (metadata) can't use type arguments.");

  /**
   * 17.6.3 Asynchronous For-in: It is a compile-time error if an asynchronous
   * for-in statement appears inside a synchronous function.
   */
  static const CompileTimeErrorCode ASYNC_FOR_IN_WRONG_CONTEXT =
      const CompileTimeErrorCode('ASYNC_FOR_IN_WRONG_CONTEXT',
          "The asynchronous for-in can only be used in an asynchronous function.",
          correction:
              "Try marking the function body with either 'async' or 'async*', or "
              "removing the 'await' before the for loop.");

  /**
   * 16.30 Await Expressions: It is a compile-time error if the function
   * immediately enclosing _a_ is not declared asynchronous. (Where _a_ is the
   * await expression.)
   */
  static const CompileTimeErrorCode AWAIT_IN_WRONG_CONTEXT =
      const CompileTimeErrorCode('AWAIT_IN_WRONG_CONTEXT',
          "The await expression can only be used in an asynchronous function.",
          correction:
              "Try marking the function body with either 'async' or 'async*'.");

  /**
   * 16.33 Identifier Reference: It is a compile-time error if a built-in
   * identifier is used as the declared name of a prefix, class, type parameter
   * or type alias.
   *
   * Parameters:
   * 0: the built-in identifier that is being used
   */
  static const CompileTimeErrorCode BUILT_IN_IDENTIFIER_AS_PREFIX_NAME =
      const CompileTimeErrorCode('BUILT_IN_IDENTIFIER_AS_PREFIX_NAME',
          "The built-in identifier '{0}' can't be used as a prefix name.",
          correction: "Try choosing a different name for the prefix.");

  /**
   * 12.30 Identifier Reference: It is a compile-time error to use a built-in
   * identifier other than dynamic as a type annotation.
   *
   * Parameters:
   * 0: the built-in identifier that is being used
   */
  static const CompileTimeErrorCode BUILT_IN_IDENTIFIER_AS_TYPE =
      const CompileTimeErrorCode('BUILT_IN_IDENTIFIER_AS_TYPE',
          "The built-in identifier '{0}' can't be used as a type.",
          correction: "Try correcting the name to match an existing type.");

  /**
   * 16.33 Identifier Reference: It is a compile-time error if a built-in
   * identifier is used as the declared name of a prefix, class, type parameter
   * or type alias.
   *
   * Parameters:
   * 0: the built-in identifier that is being used
   */
  static const CompileTimeErrorCode BUILT_IN_IDENTIFIER_AS_TYPE_NAME =
      const CompileTimeErrorCode('BUILT_IN_IDENTIFIER_AS_TYPE_NAME',
          "The built-in identifier '{0}' can't be used as a type name.",
          correction: "Try choosing a different name for the type.");

  /**
   * 16.33 Identifier Reference: It is a compile-time error if a built-in
   * identifier is used as the declared name of a prefix, class, type parameter
   * or type alias.
   *
   * Parameters:
   * 0: the built-in identifier that is being used
   */
  static const CompileTimeErrorCode BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME =
      const CompileTimeErrorCode('BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME',
          "The built-in identifier '{0}' can't be used as a typedef name.",
          correction: "Try choosing a different name for the typedef.");

  /**
   * 16.33 Identifier Reference: It is a compile-time error if a built-in
   * identifier is used as the declared name of a prefix, class, type parameter
   * or type alias.
   *
   * Parameters:
   * 0: the built-in identifier that is being used
   */
  static const CompileTimeErrorCode BUILT_IN_IDENTIFIER_AS_TYPE_PARAMETER_NAME =
      const CompileTimeErrorCode('BUILT_IN_IDENTIFIER_AS_TYPE_PARAMETER_NAME',
          "The built-in identifier '{0}' can't be used as a type parameter name.",
          correction: "Try choosing a different name for the type parameter.");

  /**
   * 13.9 Switch: It is a compile-time error if the class <i>C</i> implements
   * the operator <i>==</i>.
   *
   * Parameters:
   * 0: the this of the switch case expression
   */
  static const CompileTimeErrorCode CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS =
      const CompileTimeErrorCode('CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS',
          "The switch case expression type '{0}' can't override the == operator.");

  /**
   * 10.11 Class Member Conflicts: Let `C` be a class. It is a compile-time
   * error if `C` declares a constructor named `C.n`, and a static member with
   * basename `n`.
   *
   * Parameters:
   * 0: the name of the constructor
   */
  static const CompileTimeErrorCode CONFLICTING_CONSTRUCTOR_AND_STATIC_FIELD =
      const CompileTimeErrorCode(
          'CONFLICTING_CONSTRUCTOR_AND_STATIC_FIELD',
          "'{0}' can't be used to name both a constructor and a static field "
              "in this class.",
          correction: "Try renaming either the constructor or the field.");

  /**
   * 10.11 Class Member Conflicts: Let `C` be a class. It is a compile-time
   * error if `C` declares a constructor named `C.n`, and a static member with
   * basename `n`.
   *
   * Parameters:
   * 0: the name of the constructor
   */
  static const CompileTimeErrorCode CONFLICTING_CONSTRUCTOR_AND_STATIC_METHOD =
      const CompileTimeErrorCode(
          'CONFLICTING_CONSTRUCTOR_AND_STATIC_METHOD',
          "'{0}' can't be used to name both a constructor and a static method "
              "in this class.",
          correction: "Try renaming either the constructor or the method.");

  /**
   * 10.11 Class Member Conflicts: Let `C` be a class. It is a compile-time
   * error if `C` declares a getter or a setter with basename `n`, and has a
   * method named `n`.
   *
   * Parameters:
   * 0: the name of the class defining the conflicting field
   * 1: the name of the conflicting field
   * 2: the name of the class defining the method with which the field conflicts
   */
  static const CompileTimeErrorCode CONFLICTING_FIELD_AND_METHOD =
      const CompileTimeErrorCode(
          'CONFLICTING_FIELD_AND_METHOD',
          "Class '{0}' can't define field '{1}' and have method '{2}.{1}' "
              "with the same name.",
          correction: "Try converting the getter to a method, or "
              "renaming the field to a name that doesn't conflict.");

  /**
   * 10.10 Superinterfaces: It is a compile-time error if a class `C` has two
   * superinterfaces that are different instantiations of the same generic
   * class. For example, a class may not have both `List<int>` and `List<num>`
   * as superinterfaces.
   *
   * Parameters:
   * 0: the name of the class implementing the conflicting interface
   * 1: the first conflicting type
   * 1: the second conflicting type
   */
  static const CompileTimeErrorCode CONFLICTING_GENERIC_INTERFACES =
      const CompileTimeErrorCode(
          'CONFLICTING_GENERIC_INTERFACES',
          "The class '{0}' cannot implement both '{1}' and '{2}' because the "
              "type arguments are different.");

  /**
   * 10.11 Class Member Conflicts: Let `C` be a class. It is a compile-time
   * error if `C` declares a method named `n`, and has a getter or a setter
   * with basename `n`.
   *
   * Parameters:
   * 0: the name of the class defining the conflicting method
   * 1: the name of the conflicting method
   * 2: the name of the class defining the field with which the method conflicts
   */
  static const CompileTimeErrorCode CONFLICTING_METHOD_AND_FIELD =
      const CompileTimeErrorCode(
          'CONFLICTING_METHOD_AND_FIELD',
          "Class '{0}' can't define method '{1}' and have field '{2}.{1}' "
              "with the same name.",
          correction: "Try converting the method to a getter, or "
              "renaming the method to a name that doesn't conflict.");

  /**
   * 10.11 Class Member Conflicts: Let `C` be a class. It is a compile-time
   * error if `C` declares a static member with basename `n`, and has an
   * instance member with basename `n`.
   *
   * Parameters:
   * 0: the name of the class defining the conflicting member
   * 1: the name of the conflicting static member
   * 2: the name of the class defining the field with which the method conflicts
   */
  static const CompileTimeErrorCode CONFLICTING_STATIC_AND_INSTANCE =
      const CompileTimeErrorCode(
          'CONFLICTING_STATIC_AND_INSTANCE',
          "Class '{0}' can't define static member '{1}' and have instance "
              "member '{2}.{1}' with the same name.",
          correction:
              "Try renaming the member to a name that doesn't conflict.");

  /**
   * 7. Classes: It is a compile time error if a generic class declares a type
   * variable with the same name as the class or any of its members or
   * constructors.
   *
   * Parameters:
   * 0: the name of the type variable
   */
  static const CompileTimeErrorCode CONFLICTING_TYPE_VARIABLE_AND_CLASS =
      const CompileTimeErrorCode(
          'CONFLICTING_TYPE_VARIABLE_AND_CLASS',
          "'{0}' can't be used to name both a type variable and the class in "
              "which the type variable is defined.",
          correction: "Try renaming either the type variable or the class.");

  /**
   * 7. Classes: It is a compile time error if a generic class declares a type
   * variable with the same name as the class or any of its members or
   * constructors.
   *
   * Parameters:
   * 0: the name of the type variable
   */
  static const CompileTimeErrorCode CONFLICTING_TYPE_VARIABLE_AND_MEMBER =
      const CompileTimeErrorCode(
          'CONFLICTING_TYPE_VARIABLE_AND_MEMBER',
          "'{0}' can't be used to name both a type variable and a member in "
              "this class.",
          correction: "Try renaming either the type variable or the member.");

  /**
   * 16.12.2 Const: It is a compile-time error if evaluation of a constant
   * object results in an uncaught exception being thrown.
   */
  static const CompileTimeErrorCode CONST_CONSTRUCTOR_THROWS_EXCEPTION =
      const CompileTimeErrorCode('CONST_CONSTRUCTOR_THROWS_EXCEPTION',
          "Const constructors can't throw exceptions.",
          correction:
              "Try removing the throw statement, or removing the keyword 'const'.");

  /**
   * 10.6.3 Constant Constructors: It is a compile-time error if a constant
   * constructor is declared by a class C if any instance variable declared in C
   * is initialized with an expression that is not a constant expression.
   *
   * Parameters:
   * 0: the name of the field
   */
  static const CompileTimeErrorCode
      CONST_CONSTRUCTOR_WITH_FIELD_INITIALIZED_BY_NON_CONST =
      const CompileTimeErrorCode(
          'CONST_CONSTRUCTOR_WITH_FIELD_INITIALIZED_BY_NON_CONST',
          "Can't define the const constructor because the field '{0}' "
              "is initialized with a non-constant value.",
          correction: "Try initializing the field to a constant value, or "
              "removing the keyword 'const' from the constructor.");

  /**
   * 7.6.3 Constant Constructors: The superinitializer that appears, explicitly
   * or implicitly, in the initializer list of a constant constructor must
   * specify a constant constructor of the superclass of the immediately
   * enclosing class or a compile-time error occurs.
   *
   * 12.1 Mixin Application: For each generative constructor named ... an
   * implicitly declared constructor named ... is declared. If Sq is a
   * generative const constructor, and M does not declare any fields, Cq is
   * also a const constructor.
   */
  static const CompileTimeErrorCode CONST_CONSTRUCTOR_WITH_MIXIN_WITH_FIELD =
      const CompileTimeErrorCode(
          'CONST_CONSTRUCTOR_WITH_MIXIN_WITH_FIELD',
          "Const constructor can't be declared for a class with a mixin "
              "that declares an instance field.",
          correction: "Try removing the 'const' keyword or "
              "removing the 'with' clause from the class declaration, "
              "or removing fields from the mixin class.");

  /**
   * 7.6.3 Constant Constructors: The superinitializer that appears, explicitly
   * or implicitly, in the initializer list of a constant constructor must
   * specify a constant constructor of the superclass of the immediately
   * enclosing class or a compile-time error occurs.
   *
   * Parameters:
   * 0: the name of the superclass
   */
  static const CompileTimeErrorCode CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER =
      const CompileTimeErrorCode(
          'CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER',
          "Constant constructor can't call non-constant super constructor of "
              "'{0}'.",
          correction: "Try calling a const constructor in the superclass, or "
              "removing the keyword 'const' from the constructor.");

  /**
   * 7.6.3 Constant Constructors: It is a compile-time error if a constant
   * constructor is declared by a class that has a non-final instance variable.
   *
   * The above refers to both locally declared and inherited instance variables.
   */
  static const CompileTimeErrorCode CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD =
      const CompileTimeErrorCode('CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD',
          "Can't define a const constructor for a class with non-final fields.",
          correction: "Try making all of the fields final, or "
              "removing the keyword 'const' from the constructor.");

  /**
   * 12.12.2 Const: It is a compile-time error if <i>T</i> is a deferred type.
   */
  static const CompileTimeErrorCode CONST_DEFERRED_CLASS =
      const CompileTimeErrorCode('CONST_DEFERRED_CLASS',
          "Deferred classes can't be created with 'const'.",
          correction: "Try using 'new' to create the instance, or "
              "changing the import to not be deferred.");

  /**
   * 6.2 Formal Parameters: It is a compile-time error if a formal parameter is
   * declared as a constant variable.
   */
  static const CompileTimeErrorCode CONST_FORMAL_PARAMETER =
      const CompileTimeErrorCode(
          'CONST_FORMAL_PARAMETER', "Parameters can't be const.",
          correction: "Try removing the 'const' keyword.");

  /**
   * 5 Variables: A constant variable must be initialized to a compile-time
   * constant or a compile-time error occurs.
   */
  static const CompileTimeErrorCode CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE =
      const CompileTimeErrorCode('CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE',
          "Const variables must be initialized with a constant value.",
          correction:
              "Try changing the initializer to be a constant expression.");

  /**
   * 5 Variables: A constant variable must be initialized to a compile-time
   * constant or a compile-time error occurs.
   *
   * 12.1 Constants: A qualified reference to a static constant variable that is
   * not qualified by a deferred prefix.
   */
  static const CompileTimeErrorCode
      CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE_FROM_DEFERRED_LIBRARY =
      const CompileTimeErrorCode(
          'CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE_FROM_DEFERRED_LIBRARY',
          "Constant values from a deferred library can't be used to "
              "initialized a const variable.",
          correction:
              "Try initializing the variable without referencing members of the "
              "deferred library, or "
              "changing the import to not be deferred.");

  /**
   * 7.5 Instance Variables: It is a compile-time error if an instance variable
   * is declared to be constant.
   */
  static const CompileTimeErrorCode CONST_INSTANCE_FIELD =
      const CompileTimeErrorCode('CONST_INSTANCE_FIELD',
          "Only static fields can be declared as const.",
          correction:
              "Try declaring the field as final, or adding the keyword 'static'.");

  static const CompileTimeErrorCode CONST_SPREAD_EXPECTED_LIST_OR_SET =
      const CompileTimeErrorCode('CONST_SPREAD_EXPECTED_LIST_OR_SET',
          "A list or a set is expected in this spread.");

  static const CompileTimeErrorCode CONST_SPREAD_EXPECTED_MAP =
      const CompileTimeErrorCode(
          'CONST_SPREAD_EXPECTED_MAP', "A map is expected in this spread.");

  /**
   * 12.8 Maps: It is a compile-time error if the key of an entry in a constant
   * map literal is an instance of a class that implements the operator
   * <i>==</i> unless the key is a string or integer.
   *
   * Parameters:
   * 0: the type of the entry's key
   */
  static const CompileTimeErrorCode
      CONST_MAP_KEY_EXPRESSION_TYPE_IMPLEMENTS_EQUALS =
      const CompileTimeErrorCode(
          'CONST_MAP_KEY_EXPRESSION_TYPE_IMPLEMENTS_EQUALS',
          "The constant map entry key expression type '{0}' can't override "
              "the == operator.",
          correction: "Try using a different value for the key, or "
              "removing the keyword 'const' from the map.");

  /**
   * 5 Variables: A constant variable must be initialized to a compile-time
   * constant (12.1) or a compile-time error occurs.
   *
   * Parameters:
   * 0: the name of the uninitialized final variable
   */
  static const CompileTimeErrorCode CONST_NOT_INITIALIZED =
      const CompileTimeErrorCode('CONST_NOT_INITIALIZED',
          "The const variable '{0}' must be initialized.",
          correction: "Try adding an initialization to the declaration.");

  /**
   * Parameters:
   * 0: the type of the element
   */
  static const CompileTimeErrorCode CONST_SET_ELEMENT_TYPE_IMPLEMENTS_EQUALS =
      const CompileTimeErrorCode(
          'CONST_SET_ELEMENT_TYPE_IMPLEMENTS_EQUALS',
          "The constant set element type '{0}' can't override "
              "the == operator.",
          correction: "Try using a different value for the element, or "
              "removing the keyword 'const' from the set.");

  /**
   * 16.12.2 Const: An expression of one of the forms !e, e1 && e2 or e1 || e2,
   * where e, e1 and e2 are constant expressions that evaluate to a boolean
   * value.
   */
  static const CompileTimeErrorCode CONST_EVAL_TYPE_BOOL =
      const CompileTimeErrorCode(
          'CONST_EVAL_TYPE_BOOL',
          "In constant expressions, operands of this operator must be of type "
              "'bool'.");

  /**
   * 16.12.2 Const: An expression of one of the forms !e, e1 && e2 or e1 || e2,
   * where e, e1 and e2 are constant expressions that evaluate to a boolean
   * value.
   */
  static const CompileTimeErrorCode CONST_EVAL_TYPE_BOOL_INT =
      const CompileTimeErrorCode(
          'CONST_EVAL_TYPE_BOOL_INT',
          "In constant expressions, operands of this operator must be of type "
              "'bool' or 'int'.");

  /**
   * 16.12.2 Const: An expression of one of the forms e1 == e2 or e1 != e2 where
   * e1 and e2 are constant expressions that evaluate to a numeric, string or
   * boolean value or to null.
   */
  static const CompileTimeErrorCode CONST_EVAL_TYPE_BOOL_NUM_STRING =
      const CompileTimeErrorCode(
          'CONST_EVAL_TYPE_BOOL_NUM_STRING',
          "In constant expressions, operands of this operator must be of type "
              "'bool', 'num', 'String' or 'null'.");

  /**
   * 16.12.2 Const: An expression of one of the forms ~e, e1 ^ e2, e1 & e2,
   * e1 | e2, e1 >> e2 or e1 << e2, where e, e1 and e2 are constant expressions
   * that evaluate to an integer value or to null.
   */
  static const CompileTimeErrorCode CONST_EVAL_TYPE_INT =
      const CompileTimeErrorCode(
          'CONST_EVAL_TYPE_INT',
          "In constant expressions, operands of this operator must be of type "
              "'int'.");

  /**
   * 16.12.2 Const: An expression of one of the forms e, e1 + e2, e1 - e2, e1 *
   * e2, e1 / e2, e1 ~/ e2, e1 > e2, e1 < e2, e1 >= e2, e1 <= e2 or e1 % e2,
   * where e, e1 and e2 are constant expressions that evaluate to a numeric
   * value or to null.
   */
  static const CompileTimeErrorCode CONST_EVAL_TYPE_NUM =
      const CompileTimeErrorCode(
          'CONST_EVAL_TYPE_NUM',
          "In constant expressions, operands of this operator must be of type "
              "'num'.");

  static const CompileTimeErrorCode CONST_EVAL_TYPE_TYPE =
      const CompileTimeErrorCode(
          'CONST_EVAL_TYPE_TYPE',
          "In constant expressions, operands of this operator must be of type "
              "'Type'.");

  /**
   * 16.12.2 Const: It is a compile-time error if evaluation of a constant
   * object results in an uncaught exception being thrown.
   */
  static const CompileTimeErrorCode CONST_EVAL_THROWS_EXCEPTION =
      const CompileTimeErrorCode('CONST_EVAL_THROWS_EXCEPTION',
          "Evaluation of this constant expression throws an exception.");

  /**
   * 16.12.2 Const: It is a compile-time error if evaluation of a constant
   * object results in an uncaught exception being thrown.
   */
  static const CompileTimeErrorCode CONST_EVAL_THROWS_IDBZE =
      const CompileTimeErrorCode(
          'CONST_EVAL_THROWS_IDBZE',
          "Evaluation of this constant expression throws an "
              "IntegerDivisionByZeroException.");

  /**
   * 16.12.2 Const: If <i>T</i> is a parameterized type <i>S&lt;U<sub>1</sub>,
   * &hellip;, U<sub>m</sub>&gt;</i>, let <i>R = S</i>; It is a compile time
   * error if <i>S</i> is not a generic type with <i>m</i> type parameters.
   *
   * Parameters:
   * 0: the name of the type being referenced (<i>S</i>)
   * 1: the number of type parameters that were declared
   * 2: the number of type arguments provided
   *
   * See [StaticWarningCode.NEW_WITH_INVALID_TYPE_PARAMETERS], and
   * [StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS].
   */
  static const CompileTimeErrorCode CONST_WITH_INVALID_TYPE_PARAMETERS =
      const CompileTimeErrorCode(
          'CONST_WITH_INVALID_TYPE_PARAMETERS',
          "The type '{0}' is declared with {1} type parameters, but {2} type "
              "arguments were given.",
          correction:
              "Try adjusting the number of type arguments to match the number of "
              "type parameters.");

  /**
   * 16.12.2 Const: If <i>e</i> is of the form <i>const T(a<sub>1</sub>,
   * &hellip;, a<sub>n</sub>, x<sub>n+1</sub>: a<sub>n+1</sub>, &hellip;,
   * x<sub>n+k</sub>: a<sub>n+k</sub>)</i> it is a compile-time error if the
   * type <i>T</i> does not declare a constant constructor with the same name as
   * the declaration of <i>T</i>.
   */
  static const CompileTimeErrorCode CONST_WITH_NON_CONST =
      const CompileTimeErrorCode('CONST_WITH_NON_CONST',
          "The constructor being called isn't a const constructor.",
          correction: "Try using 'new' to call the constructor.");

  /**
   * 16.12.2 Const: In all of the above cases, it is a compile-time error if
   * <i>a<sub>i</sub>, 1 &lt;= i &lt;= n + k</i>, is not a compile-time constant
   * expression.
   */
  static const CompileTimeErrorCode CONST_WITH_NON_CONSTANT_ARGUMENT =
      const CompileTimeErrorCode('CONST_WITH_NON_CONSTANT_ARGUMENT',
          "Arguments of a constant creation must be constant expressions.",
          correction: "Try making the argument a valid constant, or "
              "use 'new' to call the constructor.");

  /**
   * 16.12.2 Const: It is a compile-time error if <i>T</i> is not a class
   * accessible in the current scope, optionally followed by type arguments.
   *
   * 16.12.2 Const: If <i>e</i> is of the form <i>const T.id(a<sub>1</sub>,
   * &hellip;, a<sub>n</sub>, x<sub>n+1</sub>: a<sub>n+1</sub>, &hellip;
   * x<sub>n+k</sub>: a<sub>n+k</sub>)</i> it is a compile-time error if
   * <i>T</i> is not a class accessible in the current scope, optionally
   * followed by type arguments.
   *
   * Parameters:
   * 0: the name of the non-type element
   */
  static const CompileTimeErrorCode CONST_WITH_NON_TYPE =
      const CompileTimeErrorCode(
          'CONST_WITH_NON_TYPE', "The name '{0}' isn't a class.",
          correction: "Try correcting the name to match an existing class.");

  /**
   * 16.12.2 Const: If <i>T</i> is a parameterized type, it is a compile-time
   * error if <i>T</i> includes a type variable among its type arguments.
   */
  static const CompileTimeErrorCode CONST_WITH_TYPE_PARAMETERS =
      const CompileTimeErrorCode('CONST_WITH_TYPE_PARAMETERS',
          "A constant creation can't use a type parameter as a type argument.",
          correction:
              "Try replacing the type parameter with a different type.");

  /**
   * 16.12.2 Const: It is a compile-time error if <i>T.id</i> is not the name of
   * a constant constructor declared by the type <i>T</i>.
   *
   * Parameters:
   * 0: the name of the type
   * 1: the name of the requested constant constructor
   */
  static const CompileTimeErrorCode CONST_WITH_UNDEFINED_CONSTRUCTOR =
      const CompileTimeErrorCode('CONST_WITH_UNDEFINED_CONSTRUCTOR',
          "The class '{0}' doesn't have a constant constructor '{1}'.",
          correction: "Try calling a different constructor.");

  /**
   * 16.12.2 Const: It is a compile-time error if <i>T.id</i> is not the name of
   * a constant constructor declared by the type <i>T</i>.
   *
   * Parameters:
   * 0: the name of the type
   */
  static const CompileTimeErrorCode CONST_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT =
      const CompileTimeErrorCode('CONST_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT',
          "The class '{0}' doesn't have a default constant constructor.",
          correction: "Try calling a different constructor.");

  /**
   * 15.3.1 Typedef: It is a compile-time error if any default values are
   * specified in the signature of a function type alias.
   */
  static const CompileTimeErrorCode DEFAULT_VALUE_IN_FUNCTION_TYPE_ALIAS =
      const CompileTimeErrorCode('DEFAULT_VALUE_IN_FUNCTION_TYPE_ALIAS',
          "Default parameter values aren't allowed in typedefs.",
          correction: "Try removing the default value.");

  /**
   * It is an error to call the default List constructor with a length argument
   * and a type argument which is potentially non-nullable.
   */
  static const CompileTimeErrorCode DEFAULT_LIST_CONSTRUCTOR_MISMATCH =
      const CompileTimeErrorCode(
          'DEFAULT_LIST_CONSTRUCTOR_MISMATCH',
          "A list whose values cannot be 'null' cannot be given an initial length "
              "because the initial values would all be 'null'.",
          correction: "Try removing the argument.");

  /**
   * 6.2.1 Required Formals: By means of a function signature that names the
   * parameter and describes its type as a function type. It is a compile-time
   * error if any default values are specified in the signature of such a
   * function type.
   */
  static const CompileTimeErrorCode DEFAULT_VALUE_IN_FUNCTION_TYPED_PARAMETER =
      const CompileTimeErrorCode('DEFAULT_VALUE_IN_FUNCTION_TYPED_PARAMETER',
          "Default values aren't allowed in function typed parameters.",
          correction: "Try removing the default value.");

  /**
   * 7.6.2 Factories: It is a compile-time error if <i>k</i> explicitly
   * specifies a default value for an optional parameter.
   */
  static const CompileTimeErrorCode
      DEFAULT_VALUE_IN_REDIRECTING_FACTORY_CONSTRUCTOR =
      const CompileTimeErrorCode(
          'DEFAULT_VALUE_IN_REDIRECTING_FACTORY_CONSTRUCTOR',
          "Default values aren't allowed in factory constructors that redirect "
              "to another constructor.",
          correction: "Try removing the default value.");

  /**
   * It is an error if a required named parameter has a default value.
   */
  static const CompileTimeErrorCode DEFAULT_VALUE_ON_REQUIRED_PARAMETER =
      const CompileTimeErrorCode('DEFAULT_VALUE_ON_REQUIRED_PARAMETER',
          "Required named parameters cannot have a default value.",
          correction: "Try removing either the default value or the 'required' "
              "modifier.");

  /**
   * 3.1 Scoping: It is a compile-time error if there is more than one entity
   * with the same name declared in the same scope.
   */
  static const CompileTimeErrorCode DUPLICATE_CONSTRUCTOR_DEFAULT =
      const CompileTimeErrorCode('DUPLICATE_CONSTRUCTOR_DEFAULT',
          "The default constructor is already defined.",
          correction: "Try giving one of the constructors a name.");

  /**
   * 3.1 Scoping: It is a compile-time error if there is more than one entity
   * with the same name declared in the same scope.
   *
   * Parameters:
   * 0: the name of the duplicate entity
   */
  static const CompileTimeErrorCode DUPLICATE_CONSTRUCTOR_NAME =
      const CompileTimeErrorCode('DUPLICATE_CONSTRUCTOR_NAME',
          "The constructor with name '{0}' is already defined.",
          correction: "Try renaming one of the constructors.");

  /**
   * 3.1 Scoping: It is a compile-time error if there is more than one entity
   * with the same name declared in the same scope.
   *
   * 7 Classes: It is a compile-time error if a class declares two members of
   * the same name.
   *
   * 7 Classes: It is a compile-time error if a class has an instance member and
   * a static member with the same name.
   *
   * Parameters:
   * 0: the name of the duplicate entity
   */
  static const CompileTimeErrorCode DUPLICATE_DEFINITION =
      const CompileTimeErrorCode(
          'DUPLICATE_DEFINITION', "The name '{0}' is already defined.",
          correction: "Try renaming one of the declarations.");

  /**
   * 18.3 Parts: It's a compile-time error if the same library contains two part
   * directives with the same URI.
   *
   * Parameters:
   * 0: the URI of the duplicate part
   */
  static const CompileTimeErrorCode DUPLICATE_PART = const CompileTimeErrorCode(
      'DUPLICATE_PART',
      "The library already contains a part with the uri '{0}'.",
      correction:
          "Try removing all but one of the duplicated part directives.");

  /**
   * 12.14.2 Binding Actuals to Formals: It is a compile-time error if
   * <i>q<sub>i</sub> = q<sub>j</sub></i> for any <i>i != j</i> [where
   * <i>q<sub>i</sub></i> is the label for a named argument].
   *
   * Parameters:
   * 0: the name of the parameter that was duplicated
   */
  static const CompileTimeErrorCode DUPLICATE_NAMED_ARGUMENT =
      const CompileTimeErrorCode('DUPLICATE_NAMED_ARGUMENT',
          "The argument for the named parameter '{0}' was already specified.",
          correction: "Try removing one of the named arguments, or "
              "correcting one of the names to reference a different named parameter.");

  /**
   * 16.10 Maps: It is a compile-time error if two keys of a constant map
   * literal are equal according to their `==` operator (16.27).
   */
  static const CompileTimeErrorCode EQUAL_KEYS_IN_CONST_MAP =
      const CompileTimeErrorCode('EQUAL_KEYS_IN_CONST_MAP',
          "Two keys in a constant map literal can't be equal.");

  /**
   * 16.11 Sets: It is a compile-time error if two elements of a constant set
   * literal are equal according to their `==` operator (16.27).
   */
  static const CompileTimeErrorCode EQUAL_ELEMENTS_IN_CONST_SET =
      const CompileTimeErrorCode('EQUAL_ELEMENTS_IN_CONST_SET',
          "Two values in a constant set can't be equal.");

  /**
   * SDK implementation libraries can be exported only by other SDK libraries.
   *
   * Parameters:
   * 0: the uri pointing to a library
   */
  static const CompileTimeErrorCode EXPORT_INTERNAL_LIBRARY =
      const CompileTimeErrorCode('EXPORT_INTERNAL_LIBRARY',
          "The library '{0}' is internal and can't be exported.");

  /**
   * 14.2 Exports: It is a compile-time error if the compilation unit found at
   * the specified URI is not a library declaration.
   *
   * Parameters:
   * 0: the uri pointing to a non-library declaration
   */
  static const CompileTimeErrorCode EXPORT_OF_NON_LIBRARY =
      const CompileTimeErrorCode('EXPORT_OF_NON_LIBRARY',
          "The exported library '{0}' can't have a part-of directive.",
          correction: "Try exporting the library that the part is a part of.");

  static const CompileTimeErrorCode EXPRESSION_IN_MAP =
      const CompileTimeErrorCode(
          'EXPRESSION_IN_MAP', "Expressions cannot be used in a map literal.",
          correction:
              "Try removing the expression or converting it to be a map entry.");

  /**
   * 7.9 Superclasses: It is a compile-time error if the extends clause of a
   * class <i>C</i> includes a type expression that does not denote a class
   * available in the lexical scope of <i>C</i>.
   *
   * Parameters:
   * 0: the name of the superclass that was not found
   */
  static const CompileTimeErrorCode EXTENDS_NON_CLASS = const CompileTimeErrorCode(
      'EXTENDS_NON_CLASS', "Classes can only extend other classes.",
      correction:
          "Try specifying a different superclass, or removing the extends clause.");

  /**
   * 12.2 Null: It is a compile-time error for a class to attempt to extend or
   * implement Null.
   *
   * 12.3 Numbers: It is a compile-time error for a class to attempt to extend
   * or implement int.
   *
   * 12.3 Numbers: It is a compile-time error for a class to attempt to extend
   * or implement double.
   *
   * 12.3 Numbers: It is a compile-time error for any type other than the types
   * int and double to
   * attempt to extend or implement num.
   *
   * 12.4 Booleans: It is a compile-time error for a class to attempt to extend
   * or implement bool.
   *
   * 12.5 Strings: It is a compile-time error for a class to attempt to extend
   * or implement String.
   *
   * Parameters:
   * 0: the name of the type that cannot be extended
   *
   * See [IMPLEMENTS_DISALLOWED_CLASS] and [MIXIN_OF_DISALLOWED_CLASS].
   *
   * TODO(scheglov) We might want to restore specific code with FrontEnd.
   * https://github.com/dart-lang/sdk/issues/31821
   */
  static const CompileTimeErrorCode EXTENDS_DISALLOWED_CLASS =
      const CompileTimeErrorCode(
          'EXTENDS_DISALLOWED_CLASS', "Classes can't extend '{0}'.",
          correction: "Try specifying a different superclass, or "
              "removing the extends clause.");

  /**
   * 7.9 Superclasses: It is a compile-time error if the extends clause of a
   * class <i>C</i> includes a deferred type expression.
   *
   * Parameters:
   * 0: the name of the type that cannot be extended
   *
   * See [IMPLEMENTS_DEFERRED_CLASS], and [MIXIN_DEFERRED_CLASS].
   */
  static const CompileTimeErrorCode EXTENDS_DEFERRED_CLASS =
      const CompileTimeErrorCode(
          'EXTENDS_DEFERRED_CLASS', "Classes can't extend deferred classes.",
          correction: "Try specifying a different superclass, or "
              "removing the extends clause.");

  /**
   * 12.14.2 Binding Actuals to Formals: It is a static warning if <i>m &lt;
   * h</i> or if <i>m &gt; n</i>.
   *
   * 16.12.2 Const: It is a compile-time error if evaluation of a constant
   * object results in an uncaught exception being thrown.
   *
   * Parameters:
   * 0: the maximum number of positional arguments
   * 1: the actual number of positional arguments given
   */
  static const CompileTimeErrorCode EXTRA_POSITIONAL_ARGUMENTS =
      const CompileTimeErrorCode('EXTRA_POSITIONAL_ARGUMENTS',
          "Too many positional arguments: {0} expected, but {1} found.",
          correction: "Try removing the extra arguments.");

  /**
   * 12.14.2 Binding Actuals to Formals: It is a static warning if <i>m &lt;
   * h</i> or if <i>m &gt; n</i>.
   *
   * 16.12.2 Const: It is a compile-time error if evaluation of a constant
   * object results in an uncaught exception being thrown.
   *
   * Parameters:
   * 0: the maximum number of positional arguments
   * 1: the actual number of positional arguments given
   *
   * See [NOT_ENOUGH_REQUIRED_ARGUMENTS].
   */
  static const CompileTimeErrorCode EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED =
      const CompileTimeErrorCode('EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED',
          "Too many positional arguments: {0} expected, but {1} found.",
          correction: "Try removing the extra positional arguments, "
              "or specifying the name for named arguments.");

  /**
   * 7.6.1 Generative Constructors: Let <i>k</i> be a generative constructor. It
   * is a compile time error if more than one initializer corresponding to a
   * given instance variable appears in <i>k</i>'s list.
   *
   * Parameters:
   * 0: the name of the field being initialized multiple times
   */
  static const CompileTimeErrorCode FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS =
      const CompileTimeErrorCode('FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS',
          "The field '{0}' can't be initialized twice in the same constructor.",
          correction: "Try removing one of the initializations.");

  /**
   * 7.6.1 Generative Constructors: Let <i>k</i> be a generative constructor. It
   * is a compile time error if <i>k</i>'s initializer list contains an
   * initializer for a variable that is initialized by means of an initializing
   * formal of <i>k</i>.
   */
  static const CompileTimeErrorCode
      FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER =
      const CompileTimeErrorCode(
          'FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER',
          "Fields can't be initialized in both the parameter list and the "
              "initializers.",
          correction: "Try removing one of the initializations.");

  /**
   * 5 Variables: It is a compile-time error if a final instance variable that
   * has is initialized by means of an initializing formal of a constructor is
   * also initialized elsewhere in the same constructor.
   *
   * Parameters:
   * 0: the name of the field in question
   */
  static const CompileTimeErrorCode FINAL_INITIALIZED_MULTIPLE_TIMES =
      const CompileTimeErrorCode('FINAL_INITIALIZED_MULTIPLE_TIMES',
          "'{0}' is a final field and so can only be set once.",
          correction: "Try removing all but one of the initializations.");

  /**
   * 7.6.1 Generative Constructors: It is a compile-time error if an
   * initializing formal is used by a function other than a non-redirecting
   * generative constructor.
   */
  static const CompileTimeErrorCode FIELD_INITIALIZER_FACTORY_CONSTRUCTOR =
      const CompileTimeErrorCode('FIELD_INITIALIZER_FACTORY_CONSTRUCTOR',
          "Initializing formal parameters can't be used in factory constructors.",
          correction: "Try using a normal parameter.");

  /**
   * 7.6.1 Generative Constructors: It is a compile-time error if an
   * initializing formal is used by a function other than a non-redirecting
   * generative constructor.
   */
  static const CompileTimeErrorCode FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR =
      const CompileTimeErrorCode('FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR',
          "Initializing formal parameters can only be used in constructors.",
          correction: "Try using a normal parameter.");

  /**
   * 7.6.1 Generative Constructors: A generative constructor may be redirecting,
   * in which case its only action is to invoke another generative constructor.
   *
   * 7.6.1 Generative Constructors: It is a compile-time error if an
   * initializing formal is used by a function other than a non-redirecting
   * generative constructor.
   */
  static const CompileTimeErrorCode FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR =
      const CompileTimeErrorCode('FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR',
          "The redirecting constructor can't have a field initializer.",
          correction: "Try using a normal parameter.");

  /**
   * Temporary error to work around dartbug.com/28515.
   *
   * We cannot yet properly summarize function-typed parameters with generic
   * arguments, so to prevent confusion, we produce an error for any such
   * constructs (regardless of whether summaries are in use).
   *
   * TODO(paulberry): remove this once dartbug.com/28515 is fixed.
   */
  static const CompileTimeErrorCode GENERIC_FUNCTION_TYPED_PARAM_UNSUPPORTED =
      const CompileTimeErrorCode('GENERIC_FUNCTION_TYPED_PARAM_UNSUPPORTED',
          "Analysis of generic function typed parameters is not yet supported.",
          correction:
              "Try using an explicit typedef, or changing type parameters to "
              "`dynamic`.");

  /**
   * 7.10 Superinterfaces: It is a compile-time error if the implements clause
   * of a class <i>C</i> specifies a malformed type or deferred type as a
   * superinterface.
   *
   * See [EXTENDS_DEFERRED_CLASS], and [MIXIN_DEFERRED_CLASS].
   */
  static const CompileTimeErrorCode IMPLEMENTS_DEFERRED_CLASS =
      const CompileTimeErrorCode('IMPLEMENTS_DEFERRED_CLASS',
          "Classes and mixins can't implement deferred classes.",
          correction: "Try specifying a different interface, "
              "removing the class from the list, or "
              "changing the import to not be deferred.");

  /**
   * 12.2 Null: It is a compile-time error for a class to attempt to extend or
   * implement Null.
   *
   * 12.3 Numbers: It is a compile-time error for a class to attempt to extend
   * or implement int.
   *
   * 12.3 Numbers: It is a compile-time error for a class to attempt to extend
   * or implement double.
   *
   * 12.3 Numbers: It is a compile-time error for any type other than the types
   * int and double to
   * attempt to extend or implement num.
   *
   * 12.4 Booleans: It is a compile-time error for a class to attempt to extend
   * or implement bool.
   *
   * 12.5 Strings: It is a compile-time error for a class to attempt to extend
   * or implement String.
   *
   * Parameters:
   * 0: the name of the type that cannot be implemented
   *
   * See [EXTENDS_DISALLOWED_CLASS].
   */
  static const CompileTimeErrorCode IMPLEMENTS_DISALLOWED_CLASS =
      const CompileTimeErrorCode('IMPLEMENTS_DISALLOWED_CLASS',
          "Classes and mixins can't implement '{0}'.",
          correction: "Try specifying a different interface, or "
              "remove the class from the list.");

  /**
   * 7.10 Superinterfaces: It is a compile-time error if the implements clause
   * of a class <i>C</i> includes a type expression that does not denote a class
   * available in the lexical scope of <i>C</i>.
   *
   * Parameters:
   * 0: the name of the interface that was not found
   */
  static const CompileTimeErrorCode IMPLEMENTS_NON_CLASS =
      const CompileTimeErrorCode('IMPLEMENTS_NON_CLASS',
          "Classes and mixins can only implement classes.",
          correction:
              "Try specifying a class, or remove the name from the list.");

  /**
   * 10.10 Superinterfaces: It is a compile-time error if two elements in the
   * type list of the implements clause of a class `C` specifies the same
   * type `T`.
   *
   * Parameters:
   * 0: the name of the interface that is implemented more than once
   */
  static const CompileTimeErrorCode IMPLEMENTS_REPEATED =
      const CompileTimeErrorCode(
          'IMPLEMENTS_REPEATED', "'{0}' can only be implemented once.",
          correction: "Try removing all but one occurrence of the class name.");

  /**
   * 7.10 Superinterfaces: It is a compile-time error if the superclass of a
   * class <i>C</i> appears in the implements clause of <i>C</i>.
   *
   * Parameters:
   * 0: the name of the class that appears in both "extends" and "implements"
   *    clauses
   */
  static const CompileTimeErrorCode IMPLEMENTS_SUPER_CLASS =
      const CompileTimeErrorCode('IMPLEMENTS_SUPER_CLASS',
          "'{0}' can't be used in both 'extends' and 'implements' clauses.",
          correction: "Try removing one of the occurrences.");

  /**
   * 7.6.1 Generative Constructors: Note that <b>this</b> is not in scope on the
   * right hand side of an initializer.
   *
   * 12.10 This: It is a compile-time error if this appears in a top-level
   * function or variable initializer, in a factory constructor, or in a static
   * method or variable initializer, or in the initializer of an instance
   * variable.
   */
  static const CompileTimeErrorCode IMPLICIT_THIS_REFERENCE_IN_INITIALIZER =
      const CompileTimeErrorCode('IMPLICIT_THIS_REFERENCE_IN_INITIALIZER',
          "Only static members can be accessed in initializers.");

  /**
   * SDK implementation libraries can be imported only by other SDK libraries.
   *
   * Parameters:
   * 0: the uri pointing to a library
   */
  static const CompileTimeErrorCode IMPORT_INTERNAL_LIBRARY =
      const CompileTimeErrorCode('IMPORT_INTERNAL_LIBRARY',
          "The library '{0}' is internal and can't be imported.");

  /**
   * 14.1 Imports: It is a compile-time error if the specified URI of an
   * immediate import does not refer to a library declaration.
   *
   * Parameters:
   * 0: the uri pointing to a non-library declaration
   *
   * See [StaticWarningCode.IMPORT_OF_NON_LIBRARY].
   */
  static const CompileTimeErrorCode IMPORT_OF_NON_LIBRARY =
      const CompileTimeErrorCode('IMPORT_OF_NON_LIBRARY',
          "The imported library '{0}' can't have a part-of directive.",
          correction: "Try importing the library that the part is a part of.");

  /**
   * 13.9 Switch: It is a compile-time error if values of the expressions
   * <i>e<sub>k</sub></i> are not instances of the same class <i>C</i>, for all
   * <i>1 &lt;= k &lt;= n</i>.
   *
   * Parameters:
   * 0: the expression source code that is the unexpected type
   * 1: the name of the expected type
   */
  static const CompileTimeErrorCode INCONSISTENT_CASE_EXPRESSION_TYPES =
      const CompileTimeErrorCode('INCONSISTENT_CASE_EXPRESSION_TYPES',
          "Case expressions must have the same types, '{0}' isn't a '{1}'.");

  /**
   * If a class declaration does not have a member declaration with a
   * particular name, but some super-interfaces do have a member with that
   * name, it's a compile-time error if there is no signature among the
   * super-interfaces that is a valid override of all the other super-interface
   * signatures with the same name. That "most specific" signature becomes the
   * signature of the class's interface.
   *
   * Parameters:
   * 0: the name of the instance member with inconsistent inheritance.
   * 1: the list of all inherited signatures for this member.
   */
  static const CompileTimeErrorCode INCONSISTENT_INHERITANCE =
      const CompileTimeErrorCode('INCONSISTENT_INHERITANCE',
          "Superinterfaces don't have a valid override for '{0}': {1}.",
          correction:
              "Try adding an explicit override that is consistent with all "
              "of the inherited members.");

  /**
   * 11.1.1 Inheritance and Overriding. Let `I` be the implicit interface of a
   * class `C` declared in library `L`. `I` inherits all members of
   * `inherited(I, L)` and `I` overrides `m'` if `m' ∈ overrides(I, L)`. It is
   * a compile-time error if `m` is a method and `m'` is a getter, or if `m`
   * is a getter and `m'` is a method.
   *
   * Parameters:
   * 0: the name of the the instance member with inconsistent inheritance.
   * 1: the name of the superinterface that declares the name as a getter.
   * 2: the name of the superinterface that declares the name as a method.
   */
  static const CompileTimeErrorCode INCONSISTENT_INHERITANCE_GETTER_AND_METHOD =
      const CompileTimeErrorCode(
          'INCONSISTENT_INHERITANCE_GETTER_AND_METHOD',
          "'{0}' is inherited as a getter (from '{1}') and also a "
              "method (from '{2}').",
          correction:
              "Try adjusting the supertypes of this class to remove the "
              "inconsistency.");

  /**
   * 7.6.1 Generative Constructors: Let <i>k</i> be a generative constructor. It
   * is a compile-time error if <i>k</i>'s initializer list contains an
   * initializer for a variable that is not an instance variable declared in the
   * immediately surrounding class.
   *
   * Parameters:
   * 0: the name of the initializing formal that is not an instance variable in
   *    the immediately enclosing class
   *
   * See [INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD].
   */
  static const CompileTimeErrorCode INITIALIZER_FOR_NON_EXISTENT_FIELD =
      const CompileTimeErrorCode('INITIALIZER_FOR_NON_EXISTENT_FIELD',
          "'{0}' isn't a field in the enclosing class.",
          correction: "Try correcting the name to match an existing field, or "
              "defining a field named '{0}'.");

  /**
   * 7.6.1 Generative Constructors: Let <i>k</i> be a generative constructor. It
   * is a compile-time error if <i>k</i>'s initializer list contains an
   * initializer for a variable that is not an instance variable declared in the
   * immediately surrounding class.
   *
   * Parameters:
   * 0: the name of the initializing formal that is a static variable in the
   *    immediately enclosing class
   *
   * See [INITIALIZING_FORMAL_FOR_STATIC_FIELD].
   */
  static const CompileTimeErrorCode INITIALIZER_FOR_STATIC_FIELD =
      const CompileTimeErrorCode(
          'INITIALIZER_FOR_STATIC_FIELD',
          "'{0}' is a static field in the enclosing class. Fields initialized "
              "in a constructor can't be static.",
          correction: "Try removing the initialization.");

  /**
   * 7.6.1 Generative Constructors: An initializing formal has the form
   * <i>this.id</i>. It is a compile-time error if <i>id</i> is not the name of
   * an instance variable of the immediately enclosing class.
   *
   * Parameters:
   * 0: the name of the initializing formal that is not an instance variable in
   *    the immediately enclosing class
   *
   * See [INITIALIZING_FORMAL_FOR_STATIC_FIELD], and
   * [INITIALIZER_FOR_NON_EXISTENT_FIELD].
   */
  static const CompileTimeErrorCode INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD =
      const CompileTimeErrorCode('INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD',
          "'{0}' isn't a field in the enclosing class.",
          correction: "Try correcting the name to match an existing field, or "
              "defining a field named '{0}'.");

  /**
   * 7.6.1 Generative Constructors: An initializing formal has the form
   * <i>this.id</i>. It is a compile-time error if <i>id</i> is not the name of
   * an instance variable of the immediately enclosing class.
   *
   * Parameters:
   * 0: the name of the initializing formal that is a static variable in the
   *    immediately enclosing class
   *
   * See [INITIALIZER_FOR_STATIC_FIELD].
   */
  static const CompileTimeErrorCode INITIALIZING_FORMAL_FOR_STATIC_FIELD =
      const CompileTimeErrorCode(
          'INITIALIZING_FORMAL_FOR_STATIC_FIELD',
          "'{0}' is a static field in the enclosing class. Fields initialized "
              "in a constructor can't be static.",
          correction: "Try removing the initialization.");

  /**
   * 12.30 Identifier Reference: Otherwise, e is equivalent to the property
   * extraction <b>this</b>.<i>id</i>.
   */
  static const CompileTimeErrorCode INSTANCE_MEMBER_ACCESS_FROM_FACTORY =
      const CompileTimeErrorCode('INSTANCE_MEMBER_ACCESS_FROM_FACTORY',
          "Instance members can't be accessed from a factory constructor.",
          correction: "Try removing the reference to the instance member.");

  /**
   * 12.30 Identifier Reference: Otherwise, e is equivalent to the property
   * extraction <b>this</b>.<i>id</i>.
   */
  static const CompileTimeErrorCode INSTANCE_MEMBER_ACCESS_FROM_STATIC =
      const CompileTimeErrorCode('INSTANCE_MEMBER_ACCESS_FROM_STATIC',
          "Instance members can't be accessed from a static method.",
          correction: "Try removing the reference to the instance member, or ."
              "removing the keyword 'static' from the method.");

  /**
   * Enum proposal: It is also a compile-time error to explicitly instantiate an
   * enum via 'new' or 'const' or to access its private fields.
   */
  static const CompileTimeErrorCode INSTANTIATE_ENUM =
      const CompileTimeErrorCode(
          'INSTANTIATE_ENUM', "Enums can't be instantiated.",
          correction: "Try using one of the defined constants.");

  static const CompileTimeErrorCode INTEGER_LITERAL_OUT_OF_RANGE =
      const CompileTimeErrorCode('INTEGER_LITERAL_OUT_OF_RANGE',
          "The integer literal {0} can't be represented in 64 bits.",
          correction:
              "Try using the BigInt class if you need an integer larger than "
              "9,223,372,036,854,775,807 or less than -9,223,372,036,854,775,808.");

  /**
   * An integer literal with static type `double` and numeric value `i`
   * evaluates to an instance of the `double` class representing the value `i`.
   * It is a compile-time error if the value `i` cannot be represented
   * _precisely_ by the an instace of `double`.
   */
  static const CompileTimeErrorCode INTEGER_LITERAL_IMPRECISE_AS_DOUBLE =
      const CompileTimeErrorCode(
          'INTEGER_LITERAL_IMPRECISE_AS_DOUBLE',
          "The integer literal is being used as a double, but can't be "
              'represented as a 64 bit double without overflow and/or loss of '
              'precision: {0}',
          correction:
              'Try using the BigInt class, or switch to the closest valid '
              'double: {1}');

  /**
   * 15 Metadata: Metadata consists of a series of annotations, each of which
   * begin with the character @, followed by a constant expression that must be
   * either a reference to a compile-time constant variable, or a call to a
   * constant constructor.
   */
  static const CompileTimeErrorCode INVALID_ANNOTATION =
      const CompileTimeErrorCode(
          'INVALID_ANNOTATION',
          "Annotation must be either a const variable reference or const "
              "constructor invocation.");

  /**
   * 15 Metadata: Metadata consists of a series of annotations, each of which
   * begin with the character @, followed by a constant expression that must be
   * either a reference to a compile-time constant variable, or a call to a
   * constant constructor.
   *
   * 12.1 Constants: A qualified reference to a static constant variable that is
   * not qualified by a deferred prefix.
   */
  static const CompileTimeErrorCode INVALID_ANNOTATION_FROM_DEFERRED_LIBRARY =
      const CompileTimeErrorCode('INVALID_ANNOTATION_FROM_DEFERRED_LIBRARY',
          "Constant values from a deferred library can't be used as annotations.",
          correction: "Try removing the annotation, or "
              "changing the import to not be deferred.");

  /**
   * 15 Metadata: Metadata consists of a series of annotations, each of which
   * begin with the character @, followed by a constant expression that must be
   * either a reference to a compile-time constant variable, or a call to a
   * constant constructor.
   */
  static const CompileTimeErrorCode INVALID_ANNOTATION_GETTER =
      const CompileTimeErrorCode(
          'INVALID_ANNOTATION_GETTER', "Getters cannot be used as annotations.",
          correction: "Try using a top-level variable or a field.");

  /**
   * 9. Functions: It is a compile-time error if an async, async* or sync*
   * modifier is attached to the body of a setter or constructor.
   */
  static const CompileTimeErrorCode INVALID_MODIFIER_ON_CONSTRUCTOR =
      const CompileTimeErrorCode('INVALID_MODIFIER_ON_CONSTRUCTOR',
          "The modifier '{0}' can't be applied to the body of a constructor.",
          correction: "Try removing the modifier.");

  /**
   * 9. Functions: It is a compile-time error if an async, async* or sync*
   * modifier is attached to the body of a setter or constructor.
   */
  static const CompileTimeErrorCode INVALID_MODIFIER_ON_SETTER =
      const CompileTimeErrorCode('INVALID_MODIFIER_ON_SETTER',
          "The modifier '{0}' can't be applied to the body of a setter.",
          correction: "Try removing the modifier.");

  /**
   * TODO(brianwilkerson) Remove this when we have decided on how to report
   * errors in compile-time constants. Until then, this acts as a placeholder
   * for more informative errors.
   *
   * See TODOs in ConstantVisitor
   */
  static const CompileTimeErrorCode INVALID_CONSTANT =
      const CompileTimeErrorCode('INVALID_CONSTANT', "Invalid constant value.");

  /**
   * 7.6 Constructors: It is a compile-time error if the name of a constructor
   * is not a constructor name.
   */
  static const CompileTimeErrorCode INVALID_CONSTRUCTOR_NAME =
      const CompileTimeErrorCode(
          'INVALID_CONSTRUCTOR_NAME', "Invalid constructor name.");

  /**
   * 7.6.2 Factories: It is a compile-time error if <i>M</i> is not the name of
   * the immediately enclosing class.
   */
  static const CompileTimeErrorCode INVALID_FACTORY_NAME_NOT_A_CLASS =
      const CompileTimeErrorCode(
          'INVALID_FACTORY_NAME_NOT_A_CLASS',
          "The name of a factory constructor must be the same as the name of "
              "the immediately enclosing class.");

  static const CompileTimeErrorCode INVALID_INLINE_FUNCTION_TYPE =
      const CompileTimeErrorCode('INVALID_INLINE_FUNCTION_TYPE',
          "Inline function types cannot be used for parameters in a generic function type.",
          correction:
              "Try using a generic function type (returnType 'Function(' parameters ')').");

  /**
   * It is an error if an optional parameter (named or otherwise) with no
   * default value has a potentially non-nullable type. This is produced in
   * cases where there is no valid default value.
   */
  static const CompileTimeErrorCode INVALID_OPTIONAL_PARAMETER_TYPE =
      const CompileTimeErrorCode(
          'INVALID_OPTIONAL_PARAMETER_TYPE',
          "The parameter '{0}' cannot have a value of 'null' because of its "
              "type, but no default value it valid, so it must be a required "
              "parameter.",
          correction: "Try making this nullable (by adding a '?') or "
              "making this a required parameter.");

  /**
   * If a class declaration has a member declaration, the signature of that
   * member declaration becomes the signature in the interface. It's a
   * compile-time error if that signature is not a valid override of all
   * super-interface member signatures with the same name. (Not just the
   * members of the immediate super-interfaces, but all of them. For
   * non-covariant parameters, it's sufficient to check just the immediate
   * super-interfaces).
   *
   * Parameters:
   * 0: the name of the declared member that is not a valid override.
   * 1: the name of the interface that declares the member.
   * 2: the type of the declared member in the interface.
   * 3. the name of the interface with the overridden member.
   * 4. the type of the overridden member.
   */
  static const CompileTimeErrorCode INVALID_OVERRIDE =
      const CompileTimeErrorCode('INVALID_OVERRIDE',
          "'{1}.{0}' ('{2}') isn't a valid override of '{3}.{0}' ('{4}').");

  /**
   * 12.10 This: It is a compile-time error if this appears in a top-level
   * function or variable initializer, in a factory constructor, or in a static
   * method or variable initializer, or in the initializer of an instance
   * variable.
   */
  static const CompileTimeErrorCode INVALID_REFERENCE_TO_THIS =
      const CompileTimeErrorCode('INVALID_REFERENCE_TO_THIS',
          "Invalid reference to 'this' expression.");

  /**
   * 12.6 Lists: It is a compile time error if the type argument of a constant
   * list literal includes a type parameter.
   *
   * Parameters:
   * 0: the name of the type parameter
   */
  static const CompileTimeErrorCode INVALID_TYPE_ARGUMENT_IN_CONST_LIST =
      const CompileTimeErrorCode(
          'INVALID_TYPE_ARGUMENT_IN_CONST_LIST',
          "Constant list literals can't include a type parameter as a type "
              "argument, such as '{0}'.",
          correction:
              "Try replacing the type parameter with a different type.");

  /**
   * 12.7 Maps: It is a compile time error if the type arguments of a constant
   * map literal include a type parameter.
   *
   * Parameters:
   * 0: the name of the type parameter
   */
  static const CompileTimeErrorCode INVALID_TYPE_ARGUMENT_IN_CONST_MAP =
      const CompileTimeErrorCode(
          'INVALID_TYPE_ARGUMENT_IN_CONST_MAP',
          "Constant map literals can't include a type parameter as a type "
              "argument, such as '{0}'.",
          correction:
              "Try replacing the type parameter with a different type.");

  static const CompileTimeErrorCode INVALID_TYPE_ARGUMENT_IN_CONST_SET =
      const CompileTimeErrorCode(
          'INVALID_TYPE_ARGUMENT_IN_CONST_SET',
          "Constant set literals can't include a type parameter as a type "
              "argument, such as '{0}'.",
          correction:
              "Try replacing the type parameter with a different type.");

  /**
   * The 'covariant' keyword was found in an inappropriate location.
   */
  static const CompileTimeErrorCode INVALID_USE_OF_COVARIANT =
      const CompileTimeErrorCode(
          'INVALID_USE_OF_COVARIANT',
          "The 'covariant' keyword can only be used for parameters in instance "
              "methods or before non-final instance fields.",
          correction: "Try removing the 'covariant' keyword.");

  /**
   * 14.2 Exports: It is a compile-time error if the compilation unit found at
   * the specified URI is not a library declaration.
   *
   * 14.1 Imports: It is a compile-time error if the compilation unit found at
   * the specified URI is not a library declaration.
   *
   * 14.3 Parts: It is a compile time error if the contents of the URI are not a
   * valid part declaration.
   *
   * Parameters:
   * 0: the URI that is invalid
   *
   * See [URI_DOES_NOT_EXIST].
   */
  static const CompileTimeErrorCode INVALID_URI =
      const CompileTimeErrorCode('INVALID_URI', "Invalid URI syntax: '{0}'.");

  /**
   * 13.13 Break: It is a compile-time error if no such statement
   * <i>s<sub>E</sub></i> exists within the innermost function in which
   * <i>s<sub>b</sub></i> occurs.
   *
   * 13.14 Continue: It is a compile-time error if no such statement or case
   * clause <i>s<sub>E</sub></i> exists within the innermost function in which
   * <i>s<sub>c</sub></i> occurs.
   *
   * Parameters:
   * 0: the name of the unresolvable label
   */
  static const CompileTimeErrorCode LABEL_IN_OUTER_SCOPE =
      const CompileTimeErrorCode('LABEL_IN_OUTER_SCOPE',
          "Can't reference label '{0}' declared in an outer method.");

  /**
   * 13.13 Break: It is a compile-time error if no such statement
   * <i>s<sub>E</sub></i> exists within the innermost function in which
   * <i>s<sub>b</sub></i> occurs.
   *
   * 13.14 Continue: It is a compile-time error if no such statement or case
   * clause <i>s<sub>E</sub></i> exists within the innermost function in which
   * <i>s<sub>c</sub></i> occurs.
   *
   * Parameters:
   * 0: the name of the unresolvable label
   */
  static const CompileTimeErrorCode LABEL_UNDEFINED =
      const CompileTimeErrorCode(
          'LABEL_UNDEFINED', "Can't reference undefined label '{0}'.",
          correction: "Try defining the label, or "
              "correcting the name to match an existing label.");

  static const CompileTimeErrorCode MAP_ENTRY_NOT_IN_MAP =
      const CompileTimeErrorCode('MAP_ENTRY_NOT_IN_MAP',
          "Map entries can only be used in a map literal.",
          correction:
              "Try converting the collection to a map or removing the map entry.");

  /**
   * 7 Classes: It is a compile time error if a class <i>C</i> declares a member
   * with the same name as <i>C</i>.
   */
  static const CompileTimeErrorCode MEMBER_WITH_CLASS_NAME =
      const CompileTimeErrorCode('MEMBER_WITH_CLASS_NAME',
          "Class members can't have the same name as the enclosing class.");

  /**
   * 12.1 Constants: A constant expression is ... a constant list literal.
   */
  static const CompileTimeErrorCode MISSING_CONST_IN_LIST_LITERAL =
      const CompileTimeErrorCode(
          'MISSING_CONST_IN_LIST_LITERAL',
          "List literals must be prefixed with 'const' when used as a constant "
              "expression.",
          correction: "Try adding the keyword 'const' before the literal.");

  /**
   * 12.1 Constants: A constant expression is ... a constant map literal.
   */
  static const CompileTimeErrorCode MISSING_CONST_IN_MAP_LITERAL =
      const CompileTimeErrorCode(
          'MISSING_CONST_IN_MAP_LITERAL',
          "Map literals must be prefixed with 'const' when used as a constant "
              "expression.",
          correction: "Try adding the keyword 'const' before the literal.");

  /**
   * 12.1 Constants: A constant expression is ... a constant set literal.
   */
  static const CompileTimeErrorCode MISSING_CONST_IN_SET_LITERAL =
      const CompileTimeErrorCode(
          'MISSING_CONST_IN_SET_LITERAL',
          "Set literals must be prefixed with 'const' when used as a constant "
              "expression.",
          correction: "Try adding the keyword 'const' before the literal.");

  static const CompileTimeErrorCode MISSING_DART_LIBRARY =
      const CompileTimeErrorCode(
          'MISSING_DART_LIBRARY', "Required library '{0}' is missing.",
          correction: "Check your Dart SDK installation for completeness.");

  /**
   * It is an error if an optional parameter (named or otherwise) with no
   * default value has a potentially non-nullable type.
   */
  static const CompileTimeErrorCode MISSING_DEFAULT_VALUE_FOR_PARAMETER =
      const CompileTimeErrorCode(
          'MISSING_DEFAULT_VALUE_FOR_PARAMETER',
          "The parameter '{0}' cannot have a value of 'null' because of its "
              "type, so it must either be a required parameter or have a "
              "default value.",
          correction:
              "Try adding either a default value or the 'required' modifier.");

  /**
   * It is an error if a named parameter that is marked as being required is
   * not bound to an argument at a call site.
   *
   * Parameters:
   * 0: the name of the parameter
   */
  static const CompileTimeErrorCode MISSING_REQUIRED_ARGUMENT =
      const CompileTimeErrorCode(
          'MISSING_REQUIRED_ARGUMENT',
          "The named parameter '{0}' is required so "
              "there needs to be a corresponding argument.",
          correction: "Try adding the required argument.");

  /**
   * It's a compile-time error to apply a mixin containing super-invocations to
   * a class that doesn't have a concrete implementation of the super-invoked
   * members compatible with the super-constraint interface.
   *
   * This ensures that if more than one super-constraint interface declares a
   * member with the same name, at least one of those members is more specific
   * than the rest, and this is the unique signature that super-invocations
   * are allowed to invoke.
   *
   * Parameters:
   * 0: the name of the super-invoked member
   * 1: the display name of the type of the super-invoked member in the mixin
   * 2: the display name of the type of the concrete member in the class
   */
  static const CompileTimeErrorCode
      MIXIN_APPLICATION_CONCRETE_SUPER_INVOKED_MEMBER_TYPE =
      const CompileTimeErrorCode(
          'MIXIN_APPLICATION_CONCRETE_SUPER_INVOKED_MEMBER_TYPE',
          "The super-invoked member '{0}' has the type '{1}', but the "
              "concrete member in the class has type '{2}'.");

  /**
   * It's a compile-time error to apply a mixin to a class that doesn't
   * implement all the `on` type requirements of the mixin declaration.
   *
   * Parameters:
   * 0: the display name of the mixin
   * 1: the display name of the superclass
   * 2: the display name of the type that is not implemented
   */
  static const CompileTimeErrorCode
      MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE = const CompileTimeErrorCode(
          'MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE',
          "'{0}' cannot be mixed onto '{1}' "
              "because '{1}' does not implement '{2}'.",
          correction: "Try extending the class '{0}'.");

  /**
   * It's a compile-time error to apply a mixin containing super-invocations to
   * a class that doesn't have a concrete implementation of the super-invoked
   * members compatible with the super-constraint interface.
   *
   * Parameters:
   * 0: the display name of the member without a concrete implementation
   */
  static const CompileTimeErrorCode
      MIXIN_APPLICATION_NO_CONCRETE_SUPER_INVOKED_MEMBER =
      const CompileTimeErrorCode(
          'MIXIN_APPLICATION_NO_CONCRETE_SUPER_INVOKED_MEMBER',
          "The class doesn't have a concrete implementation of the "
              "super-invoked member '{0}'.");

  /**
   * 9 Mixins: It is a compile-time error if a declared or derived mixin
   * explicitly declares a constructor.
   *
   * Parameters:
   * 0: the name of the mixin that is invalid
   */
  static const CompileTimeErrorCode MIXIN_CLASS_DECLARES_CONSTRUCTOR =
      const CompileTimeErrorCode(
          'MIXIN_CLASS_DECLARES_CONSTRUCTOR',
          "The class '{0}' can't be used as a mixin because it declares a "
              "constructor.");

  /**
   * The <i>mixinMember</i> production allows the same instance or static
   * members that a class would allow, but no constructors (for now).
   */
  static const CompileTimeErrorCode MIXIN_DECLARES_CONSTRUCTOR =
      const CompileTimeErrorCode(
          'MIXIN_DECLARES_CONSTRUCTOR', "Mixins can't declare constructors.");

  /**
   * 9.1 Mixin Application: It is a compile-time error if the with clause of a
   * mixin application <i>C</i> includes a deferred type expression.
   *
   * Parameters:
   * 0: the name of the type that cannot be extended
   *
   * See [EXTENDS_DEFERRED_CLASS], and [IMPLEMENTS_DEFERRED_CLASS].
   */
  static const CompileTimeErrorCode MIXIN_DEFERRED_CLASS =
      const CompileTimeErrorCode(
          'MIXIN_DEFERRED_CLASS', "Classes can't mixin deferred classes.",
          correction: "Try changing the import to not be deferred.");

  static const CompileTimeErrorCode
      MIXIN_INFERENCE_INCONSISTENT_MATCHING_CLASSES =
      const CompileTimeErrorCode(
          'MIXIN_INFERENCE_INCONSISTENT_MATCHING_CLASSES',
          "Type parameters could not be inferred for the mixin '{0}' because "
              "the base class implements the mixin's supertype constraint "
              "'{1}' in multiple conflicting ways");

  static const CompileTimeErrorCode MIXIN_INFERENCE_NO_MATCHING_CLASS =
      const CompileTimeErrorCode(
          'MIXIN_INFERENCE_NO_MATCHING_CLASS',
          "Type parameters could not be inferred for the mixin '{0}' because "
              "the base class does not implement the mixin's supertype "
              "constraint '{1}'");

  static const CompileTimeErrorCode MIXIN_INFERENCE_NO_POSSIBLE_SUBSTITUTION =
      const CompileTimeErrorCode(
          'MIXIN_INFERENCE_NO_POSSIBLE_SUBSTITUTION',
          "Type parameters could not be inferred for the mixin '{0}' because "
              "no type parameter substitution could be found matching the mixin's "
              "supertype constraints");

  /**
   * 9 Mixins: It is a compile-time error if a mixin is derived from a class
   * whose superclass is not Object.
   *
   * Parameters:
   * 0: the name of the mixin that is invalid
   */
  static const CompileTimeErrorCode MIXIN_INHERITS_FROM_NOT_OBJECT =
      const CompileTimeErrorCode(
          'MIXIN_INHERITS_FROM_NOT_OBJECT',
          "The class '{0}' can't be used as a mixin because it extends a class "
              "other than Object.");

  /**
   * A mixin declaration introduces a mixin and an interface, but not a class.
   */
  static const CompileTimeErrorCode MIXIN_INSTANTIATE =
      const CompileTimeErrorCode(
          'MIXIN_INSTANTIATE', "Mixins can't be instantiated.");

  /**
   * 12.2 Null: It is a compile-time error for a class to attempt to extend or
   * implement Null.
   *
   * 12.3 Numbers: It is a compile-time error for a class to attempt to extend
   * or implement int.
   *
   * 12.3 Numbers: It is a compile-time error for a class to attempt to extend
   * or implement double.
   *
   * 12.3 Numbers: It is a compile-time error for any type other than the types
   * int and double to attempt to extend or implement num.
   *
   * 12.4 Booleans: It is a compile-time error for a class to attempt to extend
   * or implement bool.
   *
   * 12.5 Strings: It is a compile-time error for a class to attempt to extend
   * or implement String.
   *
   * Parameters:
   * 0: the name of the type that cannot be extended
   *
   * See [IMPLEMENTS_DISALLOWED_CLASS].
   */
  static const CompileTimeErrorCode MIXIN_OF_DISALLOWED_CLASS =
      const CompileTimeErrorCode(
          'MIXIN_OF_DISALLOWED_CLASS', "Classes can't mixin '{0}'.");

  /**
   * 9.1 Mixin Application: It is a compile-time error if <i>M</i> does not
   * denote a class or mixin available in the immediately enclosing scope.
   */
  static const CompileTimeErrorCode MIXIN_OF_NON_CLASS =
      const CompileTimeErrorCode(
          'MIXIN_OF_NON_CLASS', "Classes can only mixin other classes.");

  /**
   * 9 Mixins: It is a compile-time error if a declared or derived mixin refers
   * to super.
   */
  static const CompileTimeErrorCode MIXIN_REFERENCES_SUPER =
      const CompileTimeErrorCode(
          'MIXIN_REFERENCES_SUPER',
          "The class '{0}' can't be used as a mixin because it references "
              "'super'.");

  static const CompileTimeErrorCode
      MIXIN_SUPER_CLASS_CONSTRAINT_DEFERRED_CLASS = const CompileTimeErrorCode(
          'MIXIN_SUPER_CLASS_CONSTRAINT_DEFERRED_CLASS',
          "Deferred classes can't be used as super-class constraints.",
          correction: "Try changing the import to not be deferred.");

  static const CompileTimeErrorCode
      MIXIN_SUPER_CLASS_CONSTRAINT_DISALLOWED_CLASS =
      const CompileTimeErrorCode(
          'MIXIN_SUPER_CLASS_CONSTRAINT_DISALLOWED_CLASS',
          "'{0}' can't be used as a super-class constraint.");

  static const CompileTimeErrorCode MIXIN_SUPER_CLASS_CONSTRAINT_NON_INTERFACE =
      const CompileTimeErrorCode('MIXIN_SUPER_CLASS_CONSTRAINT_NON_INTERFACE',
          "Only classes and mixins can be used as super-class constraints.");

  /**
   * 9.1 Mixin Application: It is a compile-time error if <i>S</i> does not
   * denote a class available in the immediately enclosing scope.
   */
  static const CompileTimeErrorCode MIXIN_WITH_NON_CLASS_SUPERCLASS =
      const CompileTimeErrorCode('MIXIN_WITH_NON_CLASS_SUPERCLASS',
          "Mixin can only be applied to class.");

  /**
   * 7.6.1 Generative Constructors: A generative constructor may be redirecting,
   * in which case its only action is to invoke another generative constructor.
   */
  static const CompileTimeErrorCode
      MULTIPLE_REDIRECTING_CONSTRUCTOR_INVOCATIONS = const CompileTimeErrorCode(
          'MULTIPLE_REDIRECTING_CONSTRUCTOR_INVOCATIONS',
          "Constructors can have at most one 'this' redirection.",
          correction: "Try removing all but one of the redirections.");

  /**
   * 7.6.1 Generative Constructors: Let <i>k</i> be a generative constructor.
   * Then <i>k</i> may include at most one superinitializer in its initializer
   * list or a compile time error occurs.
   */
  static const CompileTimeErrorCode MULTIPLE_SUPER_INITIALIZERS =
      const CompileTimeErrorCode('MULTIPLE_SUPER_INITIALIZERS',
          "Constructor may have at most one 'super' initializer.",
          correction: "Try removing all but one of the 'super' initializers.");

  /**
   * 15 Metadata: Metadata consists of a series of annotations, each of which
   * begin with the character @, followed by a constant expression that must be
   * either a reference to a compile-time constant variable, or a call to a
   * constant constructor.
   */
  static const CompileTimeErrorCode NO_ANNOTATION_CONSTRUCTOR_ARGUMENTS =
      const CompileTimeErrorCode('NO_ANNOTATION_CONSTRUCTOR_ARGUMENTS',
          "Annotation creation must have arguments.",
          correction: "Try adding an empty argument list.");

  /**
   * This error is generated if a constructor declaration has an implicit
   * invocation of a zero argument super constructor (`super()`), but the
   * superclass does not define a zero argument constructor.
   *
   * 7.6.1 Generative Constructors: If no superinitializer is provided, an
   * implicit superinitializer of the form <b>super</b>() is added at the end of
   * <i>k</i>'s initializer list, unless the enclosing class is class
   * <i>Object</i>.
   *
   * 7.6.1 Generative constructors. It is a compile-time error if class <i>S</i>
   * does not declare a generative constructor named <i>S</i> (respectively
   * <i>S.id</i>)
   *
   * Parameters:
   * 0: the name of the superclass that does not define the implicitly invoked
   *    constructor
   */
  static const CompileTimeErrorCode NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT =
      const CompileTimeErrorCode('NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT',
          "The superclass '{0}' doesn't have a zero argument constructor.",
          correction: "Try declaring a zero argument constructor in '{0}', or "
              "explicitly invoking a different constructor in '{0}'.");

  /**
   * This error is generated if a class declaration has an implicit default
   * constructor, which implicitly invokes a zero argument super constructor
   * (`super()`), but the superclass does not define a zero argument
   * constructor.
   *
   * 7.6 Constructors: Iff no constructor is specified for a class <i>C</i>, it
   * implicitly has a default constructor C() : <b>super<b>() {}, unless
   * <i>C</i> is class <i>Object</i>.
   *
   * 7.6.1 Generative constructors. It is a compile-time error if class <i>S</i>
   * does not declare a generative constructor named <i>S</i> (respectively
   * <i>S.id</i>)
   *
   * Parameters:
   * 0: the name of the superclass that does not define the implicitly invoked
   *    constructor
   * 1: the name of the subclass that does not contain any explicit constructors
   */
  static const CompileTimeErrorCode NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT =
      const CompileTimeErrorCode('NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT',
          "The superclass '{0}' doesn't have a zero argument constructor.",
          correction: "Try declaring a zero argument constructor in '{0}', or "
              "declaring a constructor in {1} that explicitly invokes a "
              "constructor in '{0}'.");

  /**
   * 13.2 Expression Statements: It is a compile-time error if a non-constant
   * map literal that has no explicit type arguments appears in a place where a
   * statement is expected.
   */
  static const CompileTimeErrorCode NON_CONST_MAP_AS_EXPRESSION_STATEMENT =
      const CompileTimeErrorCode(
          'NON_CONST_MAP_AS_EXPRESSION_STATEMENT',
          "A non-constant map or set literal without type arguments can't be "
              "used as an expression statement.");

  /**
   * 13.9 Switch: Given a switch statement of the form <i>switch (e) {
   * label<sub>11</sub> &hellip; label<sub>1j1</sub> case e<sub>1</sub>:
   * s<sub>1</sub> &hellip; label<sub>n1</sub> &hellip; label<sub>njn</sub> case
   * e<sub>n</sub>: s<sub>n</sub> default: s<sub>n+1</sub>}</i> or the form
   * <i>switch (e) { label<sub>11</sub> &hellip; label<sub>1j1</sub> case
   * e<sub>1</sub>: s<sub>1</sub> &hellip; label<sub>n1</sub> &hellip;
   * label<sub>njn</sub> case e<sub>n</sub>: s<sub>n</sub>}</i>, it is a
   * compile-time error if the expressions <i>e<sub>k</sub></i> are not
   * compile-time constants, for all <i>1 &lt;= k &lt;= n</i>.
   */
  static const CompileTimeErrorCode NON_CONSTANT_CASE_EXPRESSION =
      const CompileTimeErrorCode(
          'NON_CONSTANT_CASE_EXPRESSION', "Case expressions must be constant.");

  /**
   * 13.9 Switch: Given a switch statement of the form <i>switch (e) {
   * label<sub>11</sub> &hellip; label<sub>1j1</sub> case e<sub>1</sub>:
   * s<sub>1</sub> &hellip; label<sub>n1</sub> &hellip; label<sub>njn</sub> case
   * e<sub>n</sub>: s<sub>n</sub> default: s<sub>n+1</sub>}</i> or the form
   * <i>switch (e) { label<sub>11</sub> &hellip; label<sub>1j1</sub> case
   * e<sub>1</sub>: s<sub>1</sub> &hellip; label<sub>n1</sub> &hellip;
   * label<sub>njn</sub> case e<sub>n</sub>: s<sub>n</sub>}</i>, it is a
   * compile-time error if the expressions <i>e<sub>k</sub></i> are not
   * compile-time constants, for all <i>1 &lt;= k &lt;= n</i>.
   *
   * 12.1 Constants: A qualified reference to a static constant variable that is
   * not qualified by a deferred prefix.
   */
  static const CompileTimeErrorCode
      NON_CONSTANT_CASE_EXPRESSION_FROM_DEFERRED_LIBRARY =
      const CompileTimeErrorCode(
          'NON_CONSTANT_CASE_EXPRESSION_FROM_DEFERRED_LIBRARY',
          "Constant values from a deferred library can't be used as a case "
              "expression.",
          correction:
              "Try re-writing the switch as a series of if statements, or "
              "changing the import to not be deferred.");

  /**
   * 6.2.2 Optional Formals: It is a compile-time error if the default value of
   * an optional parameter is not a compile-time constant.
   */
  static const CompileTimeErrorCode NON_CONSTANT_DEFAULT_VALUE =
      const CompileTimeErrorCode('NON_CONSTANT_DEFAULT_VALUE',
          "Default values of an optional parameter must be constant.");

  /**
   * 6.2.2 Optional Formals: It is a compile-time error if the default value of
   * an optional parameter is not a compile-time constant.
   *
   * 12.1 Constants: A qualified reference to a static constant variable that is
   * not qualified by a deferred prefix.
   */
  static const CompileTimeErrorCode
      NON_CONSTANT_DEFAULT_VALUE_FROM_DEFERRED_LIBRARY =
      const CompileTimeErrorCode(
          'NON_CONSTANT_DEFAULT_VALUE_FROM_DEFERRED_LIBRARY',
          "Constant values from a deferred library can't be used as a default "
              "parameter value.",
          correction:
              "Try leaving the default as null and initializing the parameter "
              "inside the function body.");

  /**
   * 12.6 Lists: It is a compile time error if an element of a constant list
   * literal is not a compile-time constant.
   */
  static const CompileTimeErrorCode NON_CONSTANT_LIST_ELEMENT =
      const CompileTimeErrorCode('NON_CONSTANT_LIST_ELEMENT',
          "The values in a const list literal must be constants.",
          correction:
              "Try removing the keyword 'const' from the list literal.");

  /**
   * 12.6 Lists: It is a compile time error if an element of a constant list
   * literal is not a compile-time constant.
   *
   * 12.1 Constants: A qualified reference to a static constant variable that is
   * not qualified by a deferred prefix.
   */
  static const CompileTimeErrorCode
      NON_CONSTANT_LIST_ELEMENT_FROM_DEFERRED_LIBRARY =
      const CompileTimeErrorCode(
          'NON_CONSTANT_LIST_ELEMENT_FROM_DEFERRED_LIBRARY',
          "Constant values from a deferred library can't be used as values in "
              "a 'const' list.",
          correction:
              "Try removing the keyword 'const' from the list literal.");

  /**
   * 12.7 Maps: It is a compile time error if either a key or a value of an
   * entry in a constant map literal is not a compile-time constant.
   */
  static const CompileTimeErrorCode NON_CONSTANT_MAP_KEY =
      const CompileTimeErrorCode('NON_CONSTANT_MAP_KEY',
          "The keys in a const map literal must be constant.",
          correction: "Try removing the keyword 'const' from the map literal.");

  /**
   * 12.7 Maps: It is a compile time error if either a key or a value of an
   * entry in a constant map literal is not a compile-time constant.
   *
   * 12.1 Constants: A qualified reference to a static constant variable that is
   * not qualified by a deferred prefix.
   */
  static const CompileTimeErrorCode NON_CONSTANT_MAP_KEY_FROM_DEFERRED_LIBRARY =
      const CompileTimeErrorCode(
          'NON_CONSTANT_MAP_KEY_FROM_DEFERRED_LIBRARY',
          "Constant values from a deferred library can't be used as keys in a "
              "const map literal.",
          correction: "Try removing the keyword 'const' from the map literal.");

  /**
   * 12.7 Maps: It is a compile time error if either a key or a value of an
   * entry in a constant map literal is not a compile-time constant.
   */
  static const CompileTimeErrorCode NON_CONSTANT_MAP_VALUE =
      const CompileTimeErrorCode('NON_CONSTANT_MAP_VALUE',
          "The values in a const map literal must be constant.",
          correction: "Try removing the keyword 'const' from the map literal.");

  /**
   * 12.7 Maps: It is a compile time error if an element of a constant map
   * literal is not a compile-time constant.
   */
  static const CompileTimeErrorCode NON_CONSTANT_MAP_ELEMENT =
      const CompileTimeErrorCode('NON_CONSTANT_MAP_ELEMENT',
          "The elements in a const map literal must be constant.",
          correction: "Try removing the keyword 'const' from the map literal.");

  /**
   * 12.7 Maps: It is a compile time error if either a key or a value of an
   * entry in a constant map literal is not a compile-time constant.
   *
   * 12.1 Constants: A qualified reference to a static constant variable that is
   * not qualified by a deferred prefix.
   */
  static const CompileTimeErrorCode
      NON_CONSTANT_MAP_VALUE_FROM_DEFERRED_LIBRARY = const CompileTimeErrorCode(
          'NON_CONSTANT_MAP_VALUE_FROM_DEFERRED_LIBRARY',
          "Constant values from a deferred library can't be used as values in "
              "a const map literal.",
          correction: "Try removing the keyword 'const' from the map literal.");

  /**
   * 15 Metadata: Metadata consists of a series of annotations, each of which
   * begin with the character @, followed by a constant expression that must be
   * either a reference to a compile-time constant variable, or a call to a
   * constant constructor.
   *
   * "From deferred library" case is covered by
   * [CompileTimeErrorCode.INVALID_ANNOTATION_FROM_DEFERRED_LIBRARY].
   */
  static const CompileTimeErrorCode NON_CONSTANT_ANNOTATION_CONSTRUCTOR =
      const CompileTimeErrorCode('NON_CONSTANT_ANNOTATION_CONSTRUCTOR',
          "Annotation creation can only call a const constructor.");

  static const CompileTimeErrorCode NON_CONSTANT_SET_ELEMENT =
      const CompileTimeErrorCode('NON_CONSTANT_SET_ELEMENT',
          "The values in a const set literal must be constants.",
          correction: "Try removing the keyword 'const' from the set literal.");

  static const CompileTimeErrorCode
      NON_CONSTANT_SPREAD_EXPRESSION_FROM_DEFERRED_LIBRARY =
      const CompileTimeErrorCode(
          'NON_CONSTANT_SPREAD_EXPRESSION_FROM_DEFERRED_LIBRARY',
          "Constant values from a deferred library can't be spread into a "
              "const literal.",
          correction: "Try making the deferred import non-deferred.");

  static const CompileTimeErrorCode
      NON_CONSTANT_IF_ELEMENT_CONDITION_FROM_DEFERRED_LIBRARY =
      const CompileTimeErrorCode(
          'NON_CONSTANT_IF_ELEMENT_CONDITION_FROM_DEFERRED_LIBRARY',
          "Constant values from a deferred library can't be used as values in "
              "an if condition inside a const collection literal.",
          correction: "Try making the deferred import non-deferred.");

  static const CompileTimeErrorCode
      NON_CONSTANT_SET_ELEMENT_FROM_DEFERRED_LIBRARY =
      const CompileTimeErrorCode(
          'NON_CONSTANT_SET_ELEMENT_FROM_DEFERRED_LIBRARY',
          "Constant values from a deferred library can't be used as values in "
              "a 'const' set.",
          correction: "Try removing the keyword 'const' from the set literal.");

  /**
   * This error code is no longer being generated. It should be removed when the
   * reference to it in the linter has been removed and rolled into the SDK.
   */
  @deprecated
  static const CompileTimeErrorCode NON_CONSTANT_VALUE_IN_INITIALIZER =
      const CompileTimeErrorCode('NON_CONSTANT_VALUE_IN_INITIALIZER',
          "Initializer expressions in constant constructors must be constants.");

  static const CompileTimeErrorCode NON_SYNC_FACTORY =
      const CompileTimeErrorCode('NON_SYNC_FACTORY',
          "Factory bodies can't use 'async', 'async*', or 'sync*'.");

  /**
   * 12.14.2 Binding Actuals to Formals: It is a static warning if <i>m < h</i>
   * or if <i>m > n</i>.
   *
   * 16.12.2 Const: It is a compile-time error if evaluation of a constant
   * object results in an uncaught exception being thrown.
   *
   * Parameters:
   * 0: the expected number of required arguments
   * 1: the actual number of positional arguments given
   */
  static const CompileTimeErrorCode NOT_ENOUGH_REQUIRED_ARGUMENTS =
      const CompileTimeErrorCode('NOT_ENOUGH_REQUIRED_ARGUMENTS',
          "{0} required argument(s) expected, but {1} found.",
          correction: "Try adding the missing arguments.");

  static const CompileTimeErrorCode NOT_ITERABLE_SPREAD =
      const CompileTimeErrorCode('NOT_ITERABLE_SPREAD',
          "Spread elements in list or set literals must implement 'Iterable'.");

  static const CompileTimeErrorCode NOT_MAP_SPREAD = const CompileTimeErrorCode(
      'NOT_MAP_SPREAD',
      "Spread elements in map literals must implement 'Map'.");

  static const CompileTimeErrorCode NOT_NULL_AWARE_NULL_SPREAD =
      const CompileTimeErrorCode('NOT_NULL_AWARE_NULL_SPREAD',
          "The Null typed expression can't be used with a non-null-aware spread.");

  /**
   * 7.6.1 Generative Constructors: Let <i>C</i> be the class in which the
   * superinitializer appears and let <i>S</i> be the superclass of <i>C</i>.
   * Let <i>k</i> be a generative constructor. It is a compile-time error if
   * class <i>S</i> does not declare a generative constructor named <i>S</i>
   * (respectively <i>S.id</i>)
   */
  static const CompileTimeErrorCode NON_GENERATIVE_CONSTRUCTOR =
      const CompileTimeErrorCode('NON_GENERATIVE_CONSTRUCTOR',
          "The generative constructor '{0}' expected, but factory found.",
          correction:
              "Try calling a different constructor in the superclass, or "
              "making the called constructor not be a factory constructor.");

  /**
   * It is an error if the type `T` in the on-catch clause `on T catch` is
   * potentially nullable.
   */
  static const CompileTimeErrorCode NULLABLE_TYPE_IN_CATCH_CLAUSE =
      const CompileTimeErrorCode(
          'NULLABLE_TYPE_IN_CATCH_CLAUSE',
          "A nullable type cannot be used in an 'on' clause because it isn't valid "
              "to throw 'null'.",
          correction: "Try removing the question mark.");

  /**
   * It is a compile-time error for a class to extend, implement, or mixin a
   * type of the form T? for any T.
   */
  static const CompileTimeErrorCode NULLABLE_TYPE_IN_EXTENDS_CLAUSE =
      const CompileTimeErrorCode('NULLABLE_TYPE_IN_EXTENDS_CLAUSE',
          "A class cannot extend a nullable type.",
          correction: "Try removing the question mark.");

  /**
   * It is a compile-time error for a class to extend, implement, or mixin a
   * type of the form T? for any T.
   */
  static const CompileTimeErrorCode NULLABLE_TYPE_IN_IMPLEMENTS_CLAUSE =
      const CompileTimeErrorCode('NULLABLE_TYPE_IN_IMPLEMENTS_CLAUSE',
          "A class or mixin cannot implement a nullable type.",
          correction: "Try removing the question mark.");

  /**
   * It is a compile-time error for a class to extend, implement, or mixin a
   * type of the form T? for any T.
   */
  static const CompileTimeErrorCode NULLABLE_TYPE_IN_ON_CLAUSE =
      const CompileTimeErrorCode('NULLABLE_TYPE_IN_ON_CLAUSE',
          "A mixin cannot have a nullable type as a superclass constraint.",
          correction: "Try removing the question mark.");

  /**
   * It is a compile-time error for a class to extend, implement, or mixin a
   * type of the form T? for any T.
   */
  static const CompileTimeErrorCode NULLABLE_TYPE_IN_WITH_CLAUSE =
      const CompileTimeErrorCode('NULLABLE_TYPE_IN_WITH_CLAUSE',
          "A class or mixin cannot mix in a nullable type.",
          correction: "Try removing the question mark.");

  /**
   * 7.9 Superclasses: It is a compile-time error to specify an extends clause
   * for class Object.
   */
  static const CompileTimeErrorCode OBJECT_CANNOT_EXTEND_ANOTHER_CLASS =
      const CompileTimeErrorCode('OBJECT_CANNOT_EXTEND_ANOTHER_CLASS',
          "The class 'Object' can't extend any other class.");

  /**
   * 10.10 Superinterfaces: It is a compile-time error if two elements in the
   * type list of the implements clause of a class `C` specifies the same
   * type `T`.
   *
   * Parameters:
   * 0: the name of the interface that is implemented more than once
   */
  static const CompileTimeErrorCode ON_REPEATED = const CompileTimeErrorCode(
      'ON_REPEATED',
      "'{0}' can only be used in super-class constraints only once.",
      correction: "Try removing all but one occurrence of the class name.");

  /**
   * 7.1.1 Operators: It is a compile-time error to declare an optional
   * parameter in an operator.
   */
  static const CompileTimeErrorCode OPTIONAL_PARAMETER_IN_OPERATOR =
      const CompileTimeErrorCode('OPTIONAL_PARAMETER_IN_OPERATOR',
          "Optional parameters aren't allowed when defining an operator.",
          correction: "Try removing the optional parameters.");

  /**
   * 14.3 Parts: It is a compile time error if the contents of the URI are not a
   * valid part declaration.
   *
   * Parameters:
   * 0: the uri pointing to a non-library declaration
   */
  static const CompileTimeErrorCode PART_OF_NON_PART =
      const CompileTimeErrorCode('PART_OF_NON_PART',
          "The included part '{0}' must have a part-of directive.",
          correction: "Try adding a part-of directive to '{0}'.");

  /**
   * 14.1 Imports: It is a compile-time error if the current library declares a
   * top-level member named <i>p</i>.
   */
  static const CompileTimeErrorCode PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER =
      const CompileTimeErrorCode(
          'PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER',
          "The name '{0}' is already used as an import prefix and can't be "
              "used to name a top-level element.",
          correction:
              "Try renaming either the top-level element or the prefix.");

  /**
   * 16.32 Identifier Reference: If d is a prefix p, a compile-time error
   * occurs unless the token immediately following d is '.'.
   */
  static const CompileTimeErrorCode PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT =
      const CompileTimeErrorCode(
          'PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT',
          "The name '{0}' refers to an import prefix, so it must be followed "
              "by '.'.",
          correction:
              "Try correcting the name to refer to something other than a prefix, or "
              "renaming the prefix.");

  /**
   * It is an error for a mixin to add a private name that conflicts with a
   * private name added by a superclass or another mixin.
   */
  static const CompileTimeErrorCode PRIVATE_COLLISION_IN_MIXIN_APPLICATION =
      const CompileTimeErrorCode(
          'PRIVATE_COLLISION_IN_MIXIN_APPLICATION',
          "The private name '{0}', defined by '{1}', "
              "conflicts with the same name defined by '{2}'.",
          correction: "Try removing '{1}' from the 'with' clause.");

  /**
   * 6.2.2 Optional Formals: It is a compile-time error if the name of a named
   * optional parameter begins with an '_' character.
   */
  static const CompileTimeErrorCode PRIVATE_OPTIONAL_PARAMETER =
      const CompileTimeErrorCode('PRIVATE_OPTIONAL_PARAMETER',
          "Named optional parameters can't start with an underscore.");

  /**
   * 12.1 Constants: It is a compile-time error if the value of a compile-time
   * constant expression depends on itself.
   */
  static const CompileTimeErrorCode RECURSIVE_COMPILE_TIME_CONSTANT =
      const CompileTimeErrorCode('RECURSIVE_COMPILE_TIME_CONSTANT',
          "Compile-time constant expression depends on itself.");

  /**
   * 7.6.1 Generative Constructors: A generative constructor may be redirecting,
   * in which case its only action is to invoke another generative constructor.
   *
   * TODO(scheglov) review this later, there are no explicit "it is a
   * compile-time error" in specification. But it was added to the co19 and
   * there is same error for factories.
   *
   * https://code.google.com/p/dart/issues/detail?id=954
   */
  static const CompileTimeErrorCode RECURSIVE_CONSTRUCTOR_REDIRECT =
      const CompileTimeErrorCode('RECURSIVE_CONSTRUCTOR_REDIRECT',
          "Cycle in redirecting generative constructors.");

  /**
   * 7.6.2 Factories: It is a compile-time error if a redirecting factory
   * constructor redirects to itself, either directly or indirectly via a
   * sequence of redirections.
   */
  static const CompileTimeErrorCode RECURSIVE_FACTORY_REDIRECT =
      const CompileTimeErrorCode('RECURSIVE_FACTORY_REDIRECT',
          "Cycle in redirecting factory constructors.");

  /**
   * 7.10 Superinterfaces: It is a compile-time error if the interface of a
   * class <i>C</i> is a superinterface of itself.
   *
   * 8.1 Superinterfaces: It is a compile-time error if an interface is a
   * superinterface of itself.
   *
   * 7.9 Superclasses: It is a compile-time error if a class <i>C</i> is a
   * superclass of itself.
   *
   * Parameters:
   * 0: the name of the class that implements itself recursively
   * 1: a string representation of the implements loop
   */
  static const CompileTimeErrorCode RECURSIVE_INTERFACE_INHERITANCE =
      const CompileTimeErrorCode('RECURSIVE_INTERFACE_INHERITANCE',
          "'{0}' can't be a superinterface of itself: {1}.");

  /**
   * 7.10 Superinterfaces: It is a compile-time error if the interface of a
   * class <i>C</i> is a superinterface of itself.
   *
   * 8.1 Superinterfaces: It is a compile-time error if an interface is a
   * superinterface of itself.
   *
   * 7.9 Superclasses: It is a compile-time error if a class <i>C</i> is a
   * superclass of itself.
   *
   * Parameters:
   * 0: the name of the class that implements itself recursively
   */
  static const CompileTimeErrorCode RECURSIVE_INTERFACE_INHERITANCE_EXTENDS =
      const CompileTimeErrorCode('RECURSIVE_INTERFACE_INHERITANCE_EXTENDS',
          "'{0}' can't extend itself.");

  /**
   * 7.10 Superinterfaces: It is a compile-time error if the interface of a
   * class <i>C</i> is a superinterface of itself.
   *
   * 8.1 Superinterfaces: It is a compile-time error if an interface is a
   * superinterface of itself.
   *
   * 7.9 Superclasses: It is a compile-time error if a class <i>C</i> is a
   * superclass of itself.
   *
   * Parameters:
   * 0: the name of the class that implements itself recursively
   */
  static const CompileTimeErrorCode RECURSIVE_INTERFACE_INHERITANCE_IMPLEMENTS =
      const CompileTimeErrorCode('RECURSIVE_INTERFACE_INHERITANCE_IMPLEMENTS',
          "'{0}' can't implement itself.");

  /**
   * Parameters:
   * 0: the name of the mixin that constraints itself recursively
   */
  static const CompileTimeErrorCode RECURSIVE_INTERFACE_INHERITANCE_ON =
      const CompileTimeErrorCode('RECURSIVE_INTERFACE_INHERITANCE_ON',
          "'{0}' can't use itself as a superclass constraint.");

  /**
   * 7.10 Superinterfaces: It is a compile-time error if the interface of a
   * class <i>C</i> is a superinterface of itself.
   *
   * 8.1 Superinterfaces: It is a compile-time error if an interface is a
   * superinterface of itself.
   *
   * 7.9 Superclasses: It is a compile-time error if a class <i>C</i> is a
   * superclass of itself.
   *
   * Parameters:
   * 0: the name of the class that implements itself recursively
   */
  static const CompileTimeErrorCode RECURSIVE_INTERFACE_INHERITANCE_WITH =
      const CompileTimeErrorCode('RECURSIVE_INTERFACE_INHERITANCE_WITH',
          "'{0}' can't use itself as a mixin.");

  /**
   * 7.6.2 Factories: It is a compile-time error if <i>k</i> is prefixed with
   * the const modifier but <i>k'</i> is not a constant constructor.
   */
  static const CompileTimeErrorCode REDIRECT_TO_MISSING_CONSTRUCTOR =
      const CompileTimeErrorCode('REDIRECT_TO_MISSING_CONSTRUCTOR',
          "The constructor '{0}' couldn't be found in '{1}'.",
          correction: "Try redirecting to a different constructor, or "
              "define the constructor named '{0}'.");

  /**
   * 7.6.2 Factories: It is a compile-time error if <i>k</i> is prefixed with
   * the const modifier but <i>k'</i> is not a constant constructor.
   */
  static const CompileTimeErrorCode REDIRECT_TO_NON_CLASS =
      const CompileTimeErrorCode(
          'REDIRECT_TO_NON_CLASS',
          "The name '{0}' isn't a type and can't be used in a redirected "
              "constructor.",
          correction: "Try redirecting to a different constructor.");

  /**
   * 7.6.2 Factories: It is a compile-time error if <i>k</i> is prefixed with
   * the const modifier but <i>k'</i> is not a constant constructor.
   */
  static const CompileTimeErrorCode REDIRECT_TO_NON_CONST_CONSTRUCTOR =
      const CompileTimeErrorCode(
          'REDIRECT_TO_NON_CONST_CONSTRUCTOR',
          "Constant factory constructor can't delegate to a non-constant "
              "constructor.",
          correction: "Try redirecting to a different constructor.");

  /**
   * 7.6.1 Generative constructors: A generative constructor may be
   * <i>redirecting</i>, in which case its only action is to invoke another
   * generative constructor.
   */
  static const CompileTimeErrorCode REDIRECT_GENERATIVE_TO_MISSING_CONSTRUCTOR =
      const CompileTimeErrorCode('REDIRECT_GENERATIVE_TO_MISSING_CONSTRUCTOR',
          "The constructor '{0}' couldn't be found in '{1}'.",
          correction: "Try redirecting to a different constructor, or "
              "defining the constructor named '{0}'.");

  /**
   * 7.6.1 Generative constructors: A generative constructor may be
   * <i>redirecting</i>, in which case its only action is to invoke another
   * generative constructor.
   */
  static const CompileTimeErrorCode
      REDIRECT_GENERATIVE_TO_NON_GENERATIVE_CONSTRUCTOR =
      const CompileTimeErrorCode(
          'REDIRECT_GENERATIVE_TO_NON_GENERATIVE_CONSTRUCTOR',
          "Generative constructor can't redirect to a factory constructor.",
          correction: "Try redirecting to a different constructor.");

  /**
   * 5 Variables: A local variable may only be referenced at a source code
   * location that is after its initializer, if any, is complete, or a
   * compile-time error occurs.
   */
  static const CompileTimeErrorCode REFERENCED_BEFORE_DECLARATION =
      const CompileTimeErrorCode('REFERENCED_BEFORE_DECLARATION',
          "Local variable '{0}' can't be referenced before it is declared.",
          correction: "Try moving the declaration to before the first use, or "
              "renaming the local variable so that it doesn't hide a name from an "
              "enclosing scope.");

  /**
   * 12.8.1 Rethrow: It is a compile-time error if an expression of the form
   * <i>rethrow;</i> is not enclosed within a on-catch clause.
   */
  static const CompileTimeErrorCode RETHROW_OUTSIDE_CATCH =
      const CompileTimeErrorCode(
          'RETHROW_OUTSIDE_CATCH', "Rethrow must be inside of catch clause.",
          correction:
              "Try moving the expression into a catch clause, or using a 'throw' "
              "expression.");

  /**
   * 13.12 Return: It is a compile-time error if a return statement of the form
   * <i>return e;</i> appears in a generative constructor.
   */
  static const CompileTimeErrorCode RETURN_IN_GENERATIVE_CONSTRUCTOR =
      const CompileTimeErrorCode('RETURN_IN_GENERATIVE_CONSTRUCTOR',
          "Constructors can't return values.",
          correction:
              "Try removing the return statement or using a factory constructor.");

  /**
   * 13.12 Return: It is a compile-time error if a return statement of the form
   * <i>return e;</i> appears in a generator function.
   */
  static const CompileTimeErrorCode RETURN_IN_GENERATOR = const CompileTimeErrorCode(
      'RETURN_IN_GENERATOR',
      "Can't return a value from a generator function (using the '{0}' modifier).",
      correction:
          "Try removing the value, replacing 'return' with 'yield' or changing the "
          "method body modifier.");

  /**
   * 14.1 Imports: It is a compile-time error if a prefix used in a deferred
   * import is used in another import clause.
   */
  static const CompileTimeErrorCode SHARED_DEFERRED_PREFIX =
      const CompileTimeErrorCode(
          'SHARED_DEFERRED_PREFIX',
          "The prefix of a deferred import can't be used in other import "
              "directives.",
          correction: "Try renaming one of the prefixes.");

  /**
   * 12.15.4 Super Invocation: A super method invocation <i>i</i> has the form
   * <i>super.m(a<sub>1</sub>, &hellip;, a<sub>n</sub>, x<sub>n+1</sub>:
   * a<sub>n+1</sub>, &hellip; x<sub>n+k</sub>: a<sub>n+k</sub>)</i>. It is a
   * compile-time error if a super method invocation occurs in a top-level
   * function or variable initializer, in an instance variable initializer or
   * initializer list, in class Object, in a factory constructor, or in a static
   * method or variable initializer.
   */
  static const CompileTimeErrorCode SUPER_IN_INVALID_CONTEXT =
      const CompileTimeErrorCode('SUPER_IN_INVALID_CONTEXT',
          "Invalid context for 'super' invocation.");

  /**
   * 7.6.1 Generative Constructors: A generative constructor may be redirecting,
   * in which case its only action is to invoke another generative constructor.
   */
  static const CompileTimeErrorCode SUPER_IN_REDIRECTING_CONSTRUCTOR =
      const CompileTimeErrorCode('SUPER_IN_REDIRECTING_CONSTRUCTOR',
          "The redirecting constructor can't have a 'super' initializer.");

  /**
   * 7.6.1 Generative Constructors: Let <i>k</i> be a generative constructor. It
   * is a compile-time error if a generative constructor of class Object
   * includes a superinitializer.
   */
  static const CompileTimeErrorCode SUPER_INITIALIZER_IN_OBJECT =
      const CompileTimeErrorCode('SUPER_INITIALIZER_IN_OBJECT',
          "The class 'Object' can't invoke a constructor from a superclass.");

  /**
   * 12.11 Instance Creation: It is a static type warning if any of the type
   * arguments to a constructor of a generic type <i>G</i> invoked by a new
   * expression or a constant object expression are not subtypes of the bounds
   * of the corresponding formal type parameters of <i>G</i>.
   *
   * 12.11.1 New: If T is malformed a dynamic error occurs. In checked mode, if
   * T is mal-bounded a dynamic error occurs.
   *
   * 12.1 Constants: It is a compile-time error if evaluation of a compile-time
   * constant would raise an exception.
   *
   * Parameters:
   * 0: the name of the type used in the instance creation that should be
   *    limited by the bound as specified in the class declaration
   * 1: the name of the bounding type
   *
   * See [StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS].
   */
  static const CompileTimeErrorCode TYPE_ARGUMENT_NOT_MATCHING_BOUNDS =
      const CompileTimeErrorCode(
          'TYPE_ARGUMENT_NOT_MATCHING_BOUNDS', "'{0}' doesn't extend '{1}'.",
          correction: "Try using a type that is or is a subclass of '{1}'.");

  /**
   * It is a compile-time error if a generic function type is used as a bound
   * for a formal type parameter of a class or a function.
   */
  static const CompileTimeErrorCode GENERIC_FUNCTION_TYPE_CANNOT_BE_BOUND =
      const CompileTimeErrorCode('GENERIC_FUNCTION_TYPE_CANNOT_BE_BOUND',
          'Generic function types may not be used as type parameter bounds',
          correction: 'Try making the free variable in the function type part'
              ' of the larger declaration signature');

  static const CompileTimeErrorCode FOR_IN_WITH_CONST_VARIABLE =
      const CompileTimeErrorCode('FOR_IN_WITH_CONST_VARIABLE',
          "A for-in loop-variable can't be 'const'.",
          correction: "Try removing the 'const' modifier from the variable, or "
              "use a different variable.");

  /**
   * It is a compile-time error if a generic function type is used as an actual
   * type argument.
   */
  static const CompileTimeErrorCode
      GENERIC_FUNCTION_TYPE_CANNOT_BE_TYPE_ARGUMENT =
      const CompileTimeErrorCode(
          'GENERIC_FUNCTION_TYPE_CANNOT_BE_TYPE_ARGUMENT',
          "A generic function type cannot be a type argument.",
          correction: "Try removing type parameters from the generic function "
              "type, or using 'dynamic' as the type argument here.");

  /**
   * 15.3.1 Typedef: Any self reference, either directly, or recursively via
   * another typedef, is a compile time error.
   */
  static const CompileTimeErrorCode TYPE_ALIAS_CANNOT_REFERENCE_ITSELF =
      const CompileTimeErrorCode(
          'TYPE_ALIAS_CANNOT_REFERENCE_ITSELF',
          "Typedefs can't reference themselves directly or recursively via "
              "another typedef.");

  static const CompileTimeErrorCode TYPE_PARAMETER_ON_CONSTRUCTOR =
      const CompileTimeErrorCode('TYPE_PARAMETER_ON_CONSTRUCTOR',
          "Constructors can't have type parameters.",
          correction: "Try removing the type parameters.");

  /**
   * 15 Metadata: Metadata consists of a series of annotations, each of which
   * begin with the character @, followed by a constant expression that must be
   * either a reference to a compile-time constant variable, or a call to a
   * constant constructor.
   */
  static const CompileTimeErrorCode UNDEFINED_ANNOTATION =
      const CompileTimeErrorCode(
          'UNDEFINED_ANNOTATION', "Undefined name '{0}' used as an annotation.",
          correction:
              "Try defining the name or importing it from another library.",
          isUnresolvedIdentifier: true);

  /**
   * 16.12.2 Const: It is a compile-time error if <i>T</i> is not a class
   * accessible in the current scope, optionally followed by type arguments.
   */
  static const CompileTimeErrorCode UNDEFINED_CLASS =
      const CompileTimeErrorCode('UNDEFINED_CLASS', "Undefined class '{0}'.",
          correction: "Try defining the class.", isUnresolvedIdentifier: true);

  /**
   * 7.6.1 Generative Constructors: Let <i>C</i> be the class in which the
   * superinitializer appears and let <i>S</i> be the superclass of <i>C</i>.
   * Let <i>k</i> be a generative constructor. It is a compile-time error if
   * class <i>S</i> does not declare a generative constructor named <i>S</i>
   * (respectively <i>S.id</i>)
   *
   * Parameters:
   * 0: the name of the superclass that does not define the invoked constructor
   * 1: the name of the constructor being invoked
   */
  static const CompileTimeErrorCode UNDEFINED_CONSTRUCTOR_IN_INITIALIZER =
      const CompileTimeErrorCode('UNDEFINED_CONSTRUCTOR_IN_INITIALIZER',
          "The class '{0}' doesn't have a constructor named '{1}'.",
          correction: "Try defining a constructor named '{1}' in '{0}', or "
              "invoking a different constructor.");

  /**
   * 7.6.1 Generative Constructors: Let <i>C</i> be the class in which the
   * superinitializer appears and let <i>S</i> be the superclass of <i>C</i>.
   * Let <i>k</i> be a generative constructor. It is a compile-time error if
   * class <i>S</i> does not declare a generative constructor named <i>S</i>
   * (respectively <i>S.id</i>)
   *
   * Parameters:
   * 0: the name of the superclass that does not define the invoked constructor
   */
  static const CompileTimeErrorCode
      UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT = const CompileTimeErrorCode(
          'UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT',
          "The class '{0}' doesn't have an unnamed constructor.",
          correction: "Try defining an unnamed constructor in '{0}', or "
              "invoking a different constructor.");

  /**
   * 12.14.2 Binding Actuals to Formals: Furthermore, each <i>q<sub>i</sub></i>,
   * <i>1<=i<=l</i>, must have a corresponding named parameter in the set
   * {<i>p<sub>n+1</sub></i> ... <i>p<sub>n+k</sub></i>} or a static warning
   * occurs.
   *
   * 16.12.2 Const: It is a compile-time error if evaluation of a constant
   * object results in an uncaught exception being thrown.
   *
   * Parameters:
   * 0: the name of the requested named parameter
   */
  static const CompileTimeErrorCode UNDEFINED_NAMED_PARAMETER =
      const CompileTimeErrorCode('UNDEFINED_NAMED_PARAMETER',
          "The named parameter '{0}' isn't defined.",
          correction:
              "Try correcting the name to an existing named parameter's name, or "
              "defining a named parameter with the name '{0}'.");

  /**
   * 14.2 Exports: It is a compile-time error if the compilation unit found at
   * the specified URI is not a library declaration.
   *
   * 14.1 Imports: It is a compile-time error if the compilation unit found at
   * the specified URI is not a library declaration.
   *
   * 14.3 Parts: It is a compile time error if the contents of the URI are not a
   * valid part declaration.
   *
   * Parameters:
   * 0: the URI pointing to a non-existent file
   *
   * See [INVALID_URI], [URI_HAS_NOT_BEEN_GENERATED].
   */
  static const CompileTimeErrorCode URI_DOES_NOT_EXIST =
      const CompileTimeErrorCode(
          'URI_DOES_NOT_EXIST', "Target of URI doesn't exist: '{0}'.",
          correction: "Try creating the file referenced by the URI, or "
              "Try using a URI for a file that does exist.");

  /**
   * Just like [URI_DOES_NOT_EXIST], but used when the URI refers to a file that
   * is expected to be generated.
   *
   * Parameters:
   * 0: the URI pointing to a non-existent file
   *
   * See [INVALID_URI], [URI_DOES_NOT_EXIST].
   */
  static const CompileTimeErrorCode URI_HAS_NOT_BEEN_GENERATED =
      const CompileTimeErrorCode('URI_HAS_NOT_BEEN_GENERATED',
          "Target of URI hasn't been generated: '{0}'.",
          correction:
              "Try running the generator that will generate the file referenced by "
              "the URI.");

  /**
   * 14.1 Imports: It is a compile-time error if <i>x</i> is not a compile-time
   * constant, or if <i>x</i> involves string interpolation.
   *
   * 14.3 Parts: It is a compile-time error if <i>s</i> is not a compile-time
   * constant, or if <i>s</i> involves string interpolation.
   *
   * 14.5 URIs: It is a compile-time error if the string literal <i>x</i> that
   * describes a URI is not a compile-time constant, or if <i>x</i> involves
   * string interpolation.
   */
  static const CompileTimeErrorCode URI_WITH_INTERPOLATION =
      const CompileTimeErrorCode(
          'URI_WITH_INTERPOLATION', "URIs can't use string interpolation.");

  /**
   * 7.1.1 Operators: It is a compile-time error if the arity of the
   * user-declared operator []= is not 2. It is a compile time error if the
   * arity of a user-declared operator with one of the names: &lt;, &gt;, &lt;=,
   * &gt;=, ==, +, /, ~/, *, %, |, ^, &, &lt;&lt;, &gt;&gt;, [] is not 1. It is
   * a compile time error if the arity of the user-declared operator - is not 0
   * or 1. It is a compile time error if the arity of the user-declared operator
   * ~ is not 0.
   *
   * Parameters:
   * 0: the name of the declared operator
   * 1: the number of parameters expected
   * 2: the number of parameters found in the operator declaration
   */
  static const CompileTimeErrorCode WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR =
      const CompileTimeErrorCode('WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR',
          "Operator '{0}' should declare exactly {1} parameter(s), but {2} found.");

  /**
   * 7.1.1 Operators: It is a compile time error if the arity of the
   * user-declared operator - is not 0 or 1.
   *
   * Parameters:
   * 0: the number of parameters found in the operator declaration
   */
  static const CompileTimeErrorCode
      WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR_MINUS =
      const CompileTimeErrorCode(
          'WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR_MINUS',
          "Operator '-' should declare 0 or 1 parameter, but {0} found.");

  /**
   * 7.3 Setters: It is a compile-time error if a setter's formal parameter list
   * does not include exactly one required formal parameter <i>p</i>.
   */
  static const CompileTimeErrorCode WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER =
      const CompileTimeErrorCode('WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER',
          "Setters should declare exactly one required parameter.");

  /**
   * ?? Yield: It is a compile-time error if a yield statement appears in a
   * function that is not a generator function.
   */
  static const CompileTimeErrorCode YIELD_EACH_IN_NON_GENERATOR =
      const CompileTimeErrorCode(
          'YIELD_EACH_IN_NON_GENERATOR',
          "Yield-each statements must be in a generator function "
              "(one marked with either 'async*' or 'sync*').",
          correction:
              "Try adding 'async*' or 'sync*' to the enclosing function.");

  /**
   * ?? Yield: It is a compile-time error if a yield statement appears in a
   * function that is not a generator function.
   */
  static const CompileTimeErrorCode YIELD_IN_NON_GENERATOR =
      const CompileTimeErrorCode(
          'YIELD_IN_NON_GENERATOR',
          "Yield statements must be in a generator function "
              "(one marked with either 'async*' or 'sync*').",
          correction:
              "Try adding 'async*' or 'sync*' to the enclosing function.");

  /**
   * Initialize a newly created error code to have the given [name]. The message
   * associated with the error will be created from the given [message]
   * template. The correction associated with the error will be created from the
   * given [correction] template.
   */
  const CompileTimeErrorCode(String name, String message,
      {String correction, bool isUnresolvedIdentifier: false})
      : super.temporary(name, message,
            correction: correction,
            isUnresolvedIdentifier: isUnresolvedIdentifier);

  @override
  ErrorSeverity get errorSeverity => ErrorType.COMPILE_TIME_ERROR.severity;

  @override
  ErrorType get type => ErrorType.COMPILE_TIME_ERROR;
}

/**
 * The error codes used for static type warnings. The convention for this class
 * is for the name of the error code to indicate the problem that caused the
 * error to be generated and for the error message to explain what is wrong and,
 * when appropriate, how the problem can be corrected.
 */
class StaticTypeWarningCode extends ErrorCode {
  /**
   * 12.7 Lists: A fresh instance (7.6.1) <i>a</i>, of size <i>n</i>, whose
   * class implements the built-in class <i>List&lt;E></i> is allocated.
   *
   * Parameters:
   * 0: the number of provided type arguments
   */
  static const StaticTypeWarningCode EXPECTED_ONE_LIST_TYPE_ARGUMENTS =
      const StaticTypeWarningCode(
          'EXPECTED_ONE_LIST_TYPE_ARGUMENTS',
          "List literals require exactly one type argument or none, "
              "but {0} found.",
          correction: "Try adjusting the number of type arguments.");

  /**
   * Parameters:
   * 0: the number of provided type arguments
   */
  static const StaticTypeWarningCode EXPECTED_ONE_SET_TYPE_ARGUMENTS =
      const StaticTypeWarningCode(
          'EXPECTED_ONE_SET_TYPE_ARGUMENTS',
          "Set literals require exactly one type argument or none, "
              "but {0} found.",
          correction: "Try adjusting the number of type arguments.");

  /**
   * 12.8 Maps: A fresh instance (7.6.1) <i>m</i>, of size <i>n</i>, whose class
   * implements the built-in class <i>Map&lt;K, V></i> is allocated.
   *
   * Parameters:
   * 0: the number of provided type arguments
   */
  static const StaticTypeWarningCode EXPECTED_TWO_MAP_TYPE_ARGUMENTS =
      const StaticTypeWarningCode(
          'EXPECTED_TWO_MAP_TYPE_ARGUMENTS',
          "Map literals require exactly two type arguments or none, "
              "but {0} found.",
          correction: "Try adjusting the number of type arguments.");

  /**
   * 9 Functions: It is a static warning if the declared return type of a
   * function marked async* may not be assigned to Stream.
   */
  static const StaticTypeWarningCode ILLEGAL_ASYNC_GENERATOR_RETURN_TYPE =
      const StaticTypeWarningCode(
          'ILLEGAL_ASYNC_GENERATOR_RETURN_TYPE',
          "Functions marked 'async*' must have a return type assignable to "
              "'Stream'.",
          correction: "Try fixing the return type of the function, or "
              "removing the modifier 'async*' from the function body.");

  /**
   * 9 Functions: It is a static warning if the declared return type of a
   * function marked async may not be assigned to Future.
   */
  static const StaticTypeWarningCode ILLEGAL_ASYNC_RETURN_TYPE =
      const StaticTypeWarningCode(
          'ILLEGAL_ASYNC_RETURN_TYPE',
          "Functions marked 'async' must have a return type assignable to "
              "'Future'.",
          correction: "Try fixing the return type of the function, or "
              "removing the modifier 'async' from the function body.");

  /**
   * 9 Functions: It is a static warning if the declared return type of a
   * function marked sync* may not be assigned to Iterable.
   */
  static const StaticTypeWarningCode ILLEGAL_SYNC_GENERATOR_RETURN_TYPE =
      const StaticTypeWarningCode('ILLEGAL_SYNC_GENERATOR_RETURN_TYPE',
          "Functions marked 'sync*' must have a return type assignable to 'Iterable'.",
          correction: "Try fixing the return type of the function, or "
              "removing the modifier 'sync*' from the function body.");

  /**
   * 12.15.1 Ordinary Invocation: It is a static type warning if <i>T</i> does
   * not have an accessible (3.2) instance member named <i>m</i>.
   *
   * Parameters:
   * 0: the name of the static member
   * 1: the kind of the static member (field, getter, setter, or method)
   * 2: the name of the defining class
   *
   * See [UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER].
   */
  static const StaticTypeWarningCode INSTANCE_ACCESS_TO_STATIC_MEMBER =
      const StaticTypeWarningCode('INSTANCE_ACCESS_TO_STATIC_MEMBER',
          "Static {1} '{0}' can't be accessed through an instance.",
          correction: "Try using the class '{2}' to access the {1}.");

  /**
   * 12.18 Assignment: It is a static type warning if the static type of
   * <i>e</i> may not be assigned to the static type of <i>v</i>. The static
   * type of the expression <i>v = e</i> is the static type of <i>e</i>.
   *
   * 12.18 Assignment: It is a static type warning if the static type of
   * <i>e</i> may not be assigned to the static type of <i>C.v</i>. The static
   * type of the expression <i>C.v = e</i> is the static type of <i>e</i>.
   *
   * 12.18 Assignment: Let <i>T</i> be the static type of <i>e<sub>1</sub></i>.
   * It is a static type warning if the static type of <i>e<sub>2</sub></i> may
   * not be assigned to <i>T</i>.
   *
   * Parameters:
   * 0: the name of the right hand side type
   * 1: the name of the left hand side type
   */
  static const StaticTypeWarningCode INVALID_ASSIGNMENT =
      const StaticTypeWarningCode('INVALID_ASSIGNMENT',
          "A value of type '{0}' can't be assigned to a variable of type '{1}'.",
          correction: "Try changing the type of the variable, or "
              "casting the right-hand type to '{1}'.");

  /**
   * 12.15.1 Ordinary Invocation: An ordinary method invocation <i>i</i> has the
   * form <i>o.m(a<sub>1</sub>, &hellip;, a<sub>n</sub>, x<sub>n+1</sub>:
   * a<sub>n+1</sub>, &hellip; x<sub>n+k</sub>: a<sub>n+k</sub>)</i>.
   *
   * Let <i>T</i> be the static type of <i>o</i>. It is a static type warning if
   * <i>T</i> does not have an accessible instance member named <i>m</i>. If
   * <i>T.m</i> exists, it is a static warning if the type <i>F</i> of
   * <i>T.m</i> may not be assigned to a function type. If <i>T.m</i> does not
   * exist, or if <i>F</i> is not a function type, the static type of <i>i</i>
   * is dynamic.
   *
   * 12.15.3 Static Invocation: It is a static type warning if the type <i>F</i>
   * of <i>C.m</i> may not be assigned to a function type.
   *
   * 12.15.4 Super Invocation: A super method invocation <i>i</i> has the form
   * <i>super.m(a<sub>1</sub>, &hellip;, a<sub>n</sub>, x<sub>n+1</sub>:
   * a<sub>n+1</sub>, &hellip; x<sub>n+k</sub>: a<sub>n+k</sub>)</i>. If
   * <i>S.m</i> exists, it is a static warning if the type <i>F</i> of
   * <i>S.m</i> may not be assigned to a function type.
   *
   * Parameters:
   * 0: the name of the identifier that is not a function type
   */
  static const StaticTypeWarningCode INVOCATION_OF_NON_FUNCTION =
      const StaticTypeWarningCode(
          'INVOCATION_OF_NON_FUNCTION', "'{0}' isn't a function.",
          // TODO(brianwilkerson) Split this error code so that we can provide
          // better error and correction messages.
          correction:
              "Try correcting the name to match an existing function, or "
              "define a method or function named '{0}'.");

  /**
   * 12.14.4 Function Expression Invocation: A function expression invocation
   * <i>i</i> has the form <i>e<sub>f</sub>(a<sub>1</sub>, &hellip;,
   * a<sub>n</sub>, x<sub>n+1</sub>: a<sub>n+1</sub>, &hellip;, x<sub>n+k</sub>:
   * a<sub>n+k</sub>)</i>, where <i>e<sub>f</sub></i> is an expression.
   *
   * It is a static type warning if the static type <i>F</i> of
   * <i>e<sub>f</sub></i> may not be assigned to a function type.
   */
  static const StaticTypeWarningCode INVOCATION_OF_NON_FUNCTION_EXPRESSION =
      const StaticTypeWarningCode('INVOCATION_OF_NON_FUNCTION_EXPRESSION',
          "The expression doesn't evaluate to a function, so it can't be invoked.");

  /**
   * 12.20 Conditional: It is a static type warning if the type of
   * <i>e<sub>1</sub></i> may not be assigned to bool.
   *
   * 13.5 If: It is a static type warning if the type of the expression <i>b</i>
   * may not be assigned to bool.
   *
   * 13.7 While: It is a static type warning if the type of <i>e</i> may not be
   * assigned to bool.
   *
   * 13.8 Do: It is a static type warning if the type of <i>e</i> cannot be
   * assigned to bool.
   */
  static const StaticTypeWarningCode NON_BOOL_CONDITION =
      const StaticTypeWarningCode(
          'NON_BOOL_CONDITION', "Conditions must have a static type of 'bool'.",
          correction: "Try changing the condition.");

  /**
   * 17.17 Assert: It is a static type warning if the type of <i>e</i> may not
   * be assigned to bool.
   */
  static const StaticTypeWarningCode NON_BOOL_EXPRESSION =
      const StaticTypeWarningCode('NON_BOOL_EXPRESSION',
          "The expression in an assert must be of type 'bool'.",
          correction: "Try changing the expression.");

  /**
   * 12.28 Unary Expressions: The expression !<i>e</i> is equivalent to the
   * expression <i>e</i>?<b>false<b> : <b>true</b>.
   *
   * 12.20 Conditional: It is a static type warning if the type of
   * <i>e<sub>1</sub></i> may not be assigned to bool.
   */
  static const StaticTypeWarningCode NON_BOOL_NEGATION_EXPRESSION =
      const StaticTypeWarningCode('NON_BOOL_NEGATION_EXPRESSION',
          "Negation argument must have a static type of 'bool'.",
          correction: "Try changing the argument to the '!' operator.");

  /**
   * 12.21 Logical Boolean Expressions: It is a static type warning if the
   * static types of both of <i>e<sub>1</sub></i> and <i>e<sub>2</sub></i> may
   * not be assigned to bool.
   *
   * Parameters:
   * 0: the lexeme of the logical operator
   */
  static const StaticTypeWarningCode NON_BOOL_OPERAND =
      const StaticTypeWarningCode('NON_BOOL_OPERAND',
          "The operands of the '{0}' operator must be assignable to 'bool'.");

  /**
   * 15.8 Parameterized Types: It is a static type warning if <i>A<sub>i</sub>,
   * 1 &lt;= i &lt;= n</i> does not denote a type in the enclosing lexical scope.
   */
  static const StaticTypeWarningCode NON_TYPE_AS_TYPE_ARGUMENT =
      const StaticTypeWarningCode('NON_TYPE_AS_TYPE_ARGUMENT',
          "The name '{0}' isn't a type so it can't be used as a type argument.",
          correction: "Try correcting the name to an existing type, or "
              "defining a type named '{0}'.",
          isUnresolvedIdentifier: true);

  /**
   * 13.11 Return: It is a static type warning if the type of <i>e</i> may not
   * be assigned to the declared return type of the immediately enclosing
   * function.
   *
   * Parameters:
   * 0: the return type as declared in the return statement
   * 1: the expected return type as defined by the method
   * 2: the name of the method
   */
  static const StaticTypeWarningCode RETURN_OF_INVALID_TYPE =
      const StaticTypeWarningCode('RETURN_OF_INVALID_TYPE',
          "The return type '{0}' isn't a '{1}', as defined by the method '{2}'.");

  /**
   * 13.11 Return: It is a static type warning if the type of <i>e</i> may not
   * be assigned to the declared return type of the immediately enclosing
   * function.
   *
   * Parameters:
   * 0: the return type as declared in the return statement
   * 1: the expected return type as defined by the method
   */
  static const StaticTypeWarningCode RETURN_OF_INVALID_TYPE_FROM_CLOSURE =
      const StaticTypeWarningCode('RETURN_OF_INVALID_TYPE_FROM_CLOSURE',
          "The return type '{0}' isn't a '{1}', as defined by anonymous closure.");

  /**
   * 12.11 Instance Creation: It is a static type warning if any of the type
   * arguments to a constructor of a generic type <i>G</i> invoked by a new
   * expression or a constant object expression are not subtypes of the bounds
   * of the corresponding formal type parameters of <i>G</i>.
   *
   * 15.8 Parameterized Types: If <i>S</i> is the static type of a member
   * <i>m</i> of <i>G</i>, then the static type of the member <i>m</i> of
   * <i>G&lt;A<sub>1</sub>, &hellip;, A<sub>n</sub>&gt;</i> is <i>[A<sub>1</sub>,
   * &hellip;, A<sub>n</sub>/T<sub>1</sub>, &hellip;, T<sub>n</sub>]S</i> where
   * <i>T<sub>1</sub>, &hellip;, T<sub>n</sub></i> are the formal type
   * parameters of <i>G</i>. Let <i>B<sub>i</sub></i> be the bounds of
   * <i>T<sub>i</sub>, 1 &lt;= i &lt;= n</i>. It is a static type warning if
   * <i>A<sub>i</sub></i> is not a subtype of <i>[A<sub>1</sub>, &hellip;,
   * A<sub>n</sub>/T<sub>1</sub>, &hellip;, T<sub>n</sub>]B<sub>i</sub>, 1 &lt;=
   * i &lt;= n</i>.
   *
   * 7.6.2 Factories: It is a static type warning if any of the type arguments
   * to <i>k'</i> are not subtypes of the bounds of the corresponding formal
   * type parameters of type.
   *
   * Parameters:
   * 0: the name of the type used in the instance creation that should be
   *    limited by the bound as specified in the class declaration
   * 1: the name of the bounding type
   *
   * See [TYPE_PARAMETER_SUPERTYPE_OF_ITS_BOUND].
   */
  static const StaticTypeWarningCode TYPE_ARGUMENT_NOT_MATCHING_BOUNDS =
      const StaticTypeWarningCode(
          'TYPE_ARGUMENT_NOT_MATCHING_BOUNDS', "'{0}' doesn't extend '{1}'.",
          correction: "Try using a type that is or is a subclass of '{1}'.");

  /**
   * 10 Generics: It is a static type warning if a type parameter is a supertype
   * of its upper bound.
   *
   * Parameters:
   * 0: the name of the type parameter
   * 1: the name of the bounding type
   *
   * See [TYPE_ARGUMENT_NOT_MATCHING_BOUNDS].
   */
  static const StaticTypeWarningCode TYPE_PARAMETER_SUPERTYPE_OF_ITS_BOUND =
      const StaticTypeWarningCode('TYPE_PARAMETER_SUPERTYPE_OF_ITS_BOUND',
          "'{0}' can't be a supertype of its upper bound.",
          correction: "Try using a type that is or is a subclass of '{1}'.");

  /**
   * 12.17 Getter Invocation: It is a static warning if there is no class
   * <i>C</i> in the enclosing lexical scope of <i>i</i>, or if <i>C</i> does
   * not declare, implicitly or explicitly, a getter named <i>m</i>.
   *
   * Parameters:
   * 0: the name of the enumeration constant that is not defined
   * 1: the name of the enumeration used to access the constant
   */
  static const StaticTypeWarningCode UNDEFINED_ENUM_CONSTANT =
      const StaticTypeWarningCode('UNDEFINED_ENUM_CONSTANT',
          "There is no constant named '{0}' in '{1}'.",
          correction:
              "Try correcting the name to the name of an existing constant, or "
              "defining a constant named '{0}'.");

  /**
   * 12.15.3 Unqualified Invocation: If there exists a lexically visible
   * declaration named <i>id</i>, let <i>f<sub>id</sub></i> be the innermost
   * such declaration. Then: [skip]. Otherwise, <i>f<sub>id</sub></i> is
   * considered equivalent to the ordinary method invocation
   * <b>this</b>.<i>id</i>(<i>a<sub>1</sub></i>, ..., <i>a<sub>n</sub></i>,
   * <i>x<sub>n+1</sub></i> : <i>a<sub>n+1</sub></i>, ...,
   * <i>x<sub>n+k</sub></i> : <i>a<sub>n+k</sub></i>).
   *
   * Parameters:
   * 0: the name of the method that is undefined
   */
  static const StaticTypeWarningCode UNDEFINED_FUNCTION =
      const StaticTypeWarningCode(
          'UNDEFINED_FUNCTION', "The function '{0}' isn't defined.",
          correction: "Try importing the library that defines '{0}', "
              "correcting the name to the name of an existing function, or "
              "defining a function named '{0}'.",
          isUnresolvedIdentifier: true);

  /**
   * 12.17 Getter Invocation: Let <i>T</i> be the static type of <i>e</i>. It is
   * a static type warning if <i>T</i> does not have a getter named <i>m</i>.
   *
   * Parameters:
   * 0: the name of the getter
   * 1: the name of the enclosing type where the getter is being looked for
   */
  // TODO(brianwilkerson) When the "target" is an enum, report
  //  UNDEFINED_ENUM_CONSTANT instead.
  static const StaticTypeWarningCode UNDEFINED_GETTER =
      const StaticTypeWarningCode('UNDEFINED_GETTER',
          "The getter '{0}' isn't defined for the class '{1}'.",
          correction: "Try importing the library that defines '{0}', "
              "correcting the name to the name of an existing getter, or "
              "defining a getter or field named '{0}'.");

  /**
   * 12.15.1 Ordinary Invocation: Let <i>T</i> be the static type of <i>o</i>.
   * It is a static type warning if <i>T</i> does not have an accessible
   * instance member named <i>m</i>.
   *
   * Parameters:
   * 0: the name of the method that is undefined
   * 1: the resolved type name that the method lookup is happening on
   */
  static const StaticTypeWarningCode UNDEFINED_METHOD =
      const StaticTypeWarningCode('UNDEFINED_METHOD',
          "The method '{0}' isn't defined for the class '{1}'.",
          correction:
              "Try correcting the name to the name of an existing method, or "
              "defining a method named '{0}'.");

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
   *
   * Parameters:
   * 0: the name of the operator
   * 1: the name of the enclosing type where the operator is being looked for
   */
  static const StaticTypeWarningCode UNDEFINED_OPERATOR =
      const StaticTypeWarningCode('UNDEFINED_OPERATOR',
          "The operator '{0}' isn't defined for the class '{1}'.",
          correction: "Try defining the operator '{0}'.");

  static const StaticTypeWarningCode UNDEFINED_PREFIXED_NAME =
      const StaticTypeWarningCode(
          'UNDEFINED_PREFIXED_NAME',
          "The name '{0}' is being referenced through the prefix '{1}', but it "
              "isn't defined in any of the libraries imported using that prefix.",
          correction: "Try correcting the prefix or "
              "importing the library that defines '{0}'.");

  /**
   * 12.18 Assignment: Let <i>T</i> be the static type of <i>e<sub>1</sub></i>.
   * It is a static type warning if <i>T</i> does not have an accessible
   * instance setter named <i>v=</i>.
   *
   * Parameters:
   * 0: the name of the setter
   * 1: the name of the enclosing type where the setter is being looked for
   */
  static const StaticTypeWarningCode UNDEFINED_SETTER =
      const StaticTypeWarningCode('UNDEFINED_SETTER',
          "The setter '{0}' isn't defined for the class '{1}'.",
          correction: "Try importing the library that defines '{0}', "
              "correcting the name to the name of an existing setter, or "
              "defining a setter or field named '{0}'.");

  /**
   * 12.17 Getter Invocation: Let <i>T</i> be the static type of <i>e</i>. It is
   * a static type warning if <i>T</i> does not have a getter named <i>m</i>.
   *
   * Parameters:
   * 0: the name of the getter
   * 1: the name of the enclosing type where the getter is being looked for
   */
  static const StaticTypeWarningCode UNDEFINED_SUPER_GETTER =
      const StaticTypeWarningCode('UNDEFINED_SUPER_GETTER',
          "The getter '{0}' isn't defined in a superclass of '{1}'.",
          correction:
              "Try correcting the name to the name of an existing getter, or "
              "defining a getter or field named '{0}' in a superclass.");

  /**
   * 12.15.4 Super Invocation: A super method invocation <i>i</i> has the form
   * <i>super.m(a<sub>1</sub>, &hellip;, a<sub>n</sub>, x<sub>n+1</sub>:
   * a<sub>n+1</sub>, &hellip; x<sub>n+k</sub>: a<sub>n+k</sub>)</i>. It is a
   * static type warning if <i>S</i> does not have an accessible instance member
   * named <i>m</i>.
   *
   * Parameters:
   * 0: the name of the method that is undefined
   * 1: the resolved type name that the method lookup is happening on
   */
  static const StaticTypeWarningCode UNDEFINED_SUPER_METHOD =
      const StaticTypeWarningCode('UNDEFINED_SUPER_METHOD',
          "The method '{0}' isn't defined in a superclass of '{1}'.",
          correction:
              "Try correcting the name to the name of an existing method, or "
              "defining a method named '{0}' in a superclass.");

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
   *
   * Parameters:
   * 0: the name of the operator
   * 1: the name of the enclosing type where the operator is being looked for
   */
  static const StaticTypeWarningCode UNDEFINED_SUPER_OPERATOR =
      const StaticTypeWarningCode('UNDEFINED_SUPER_OPERATOR',
          "The operator '{0}' isn't defined in a superclass of '{1}'.",
          correction: "Try defining the operator '{0}' in a superclass.");

  /**
   * 12.18 Assignment: Let <i>T</i> be the static type of <i>e<sub>1</sub></i>.
   * It is a static type warning if <i>T</i> does not have an accessible
   * instance setter named <i>v=</i>.
   *
   * Parameters:
   * 0: the name of the setter
   * 1: the name of the enclosing type where the setter is being looked for
   */
  static const StaticTypeWarningCode UNDEFINED_SUPER_SETTER =
      const StaticTypeWarningCode('UNDEFINED_SUPER_SETTER',
          "The setter '{0}' isn't defined in a superclass of '{1}'.",
          correction:
              "Try correcting the name to the name of an existing setter, or "
              "defining a setter or field named '{0}' in a superclass.");

  /**
   * 12.15.1 Ordinary Invocation: It is a static type warning if <i>T</i> does
   * not have an accessible (3.2) instance member named <i>m</i>.
   *
   * This is a specialization of [INSTANCE_ACCESS_TO_STATIC_MEMBER] that is used
   * when we are able to find the name defined in a supertype. It exists to
   * provide a more informative error message.
   *
   * Parameters:
   * 0: the name of the defining type
   */
  static const StaticTypeWarningCode
      UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER =
      const StaticTypeWarningCode(
          'UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER',
          "Static members from supertypes must be qualified by the name of the defining type.",
          correction: "Try adding '{0}.' before the name.");

  /**
   * 15.8 Parameterized Types: It is a static type warning if <i>G</i> is not a
   * generic type with exactly <i>n</i> type parameters.
   *
   * Parameters:
   * 0: the name of the type being referenced (<i>G</i>)
   * 1: the number of type parameters that were declared
   * 2: the number of type arguments provided
   *
   * See [CompileTimeErrorCode.CONST_WITH_INVALID_TYPE_PARAMETERS], and
   * [CompileTimeErrorCode.NEW_WITH_INVALID_TYPE_PARAMETERS].
   */
  static const StaticTypeWarningCode WRONG_NUMBER_OF_TYPE_ARGUMENTS =
      const StaticTypeWarningCode(
          'WRONG_NUMBER_OF_TYPE_ARGUMENTS',
          "The type '{0}' is declared with {1} type parameters, "
              "but {2} type arguments were given.",
          correction: "Try adjusting the number of type arguments.");

  /**
   * It will be a static type warning if <i>m</i> is not a generic method with
   * exactly <i>n</i> type parameters.
   *
   * Parameters:
   * 0: the name of the class being instantiated
   * 1: the name of the constructor being invoked
   */
  static const StaticTypeWarningCode
      WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR = const StaticTypeWarningCode(
          'WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR',
          "The constructor '{0}.{1}' does not have type parameters.",
          correction: "Try moving type arguments to after the type name.");

  /**
   * It will be a static type warning if <i>m</i> is not a generic method with
   * exactly <i>n</i> type parameters.
   *
   * Parameters:
   * 0: the name of the method being referenced (<i>G</i>)
   * 1: the number of type parameters that were declared
   * 2: the number of type arguments provided
   */
  static const StaticTypeWarningCode WRONG_NUMBER_OF_TYPE_ARGUMENTS_METHOD =
      const StaticTypeWarningCode(
          'WRONG_NUMBER_OF_TYPE_ARGUMENTS_METHOD',
          "The method '{0}' is declared with {1} type parameters, "
              "but {2} type arguments were given.",
          correction: "Try adjusting the number of type arguments.");

  /**
   * 17.16.1 Yield: Let T be the static type of e [the expression to the right
   * of "yield"] and let f be the immediately enclosing function.  It is a
   * static type warning if either:
   *
   * - the body of f is marked async* and the type Stream<T> may not be
   *   assigned to the declared return type of f.
   *
   * - the body of f is marked sync* and the type Iterable<T> may not be
   *   assigned to the declared return type of f.
   *
   * 17.16.2 Yield-Each: Let T be the static type of e [the expression to the
   * right of "yield*"] and let f be the immediately enclosing function.  It is
   * a static type warning if T may not be assigned to the declared return type
   * of f.  If f is synchronous it is a static type warning if T may not be
   * assigned to Iterable.  If f is asynchronous it is a static type warning if
   * T may not be assigned to Stream.
   */
  static const StaticTypeWarningCode YIELD_OF_INVALID_TYPE =
      const StaticTypeWarningCode(
          'YIELD_OF_INVALID_TYPE',
          "The type '{0}' implied by the 'yield' expression must be assignable "
              "to '{1}'.");

  /**
   * 17.6.2 For-in. If the iterable expression does not implement Iterable,
   * this warning is reported.
   *
   * Parameters:
   * 0: The type of the iterable expression.
   * 1: The sequence type -- Iterable for `for` or Stream for `await for`.
   */
  static const StaticTypeWarningCode FOR_IN_OF_INVALID_TYPE =
      const StaticTypeWarningCode('FOR_IN_OF_INVALID_TYPE',
          "The type '{0}' used in the 'for' loop must implement {1}.");

  /**
   * 17.6.2 For-in. It the iterable expression does not implement Iterable with
   * a type argument that can be assigned to the for-in variable's type, this
   * warning is reported.
   *
   * Parameters:
   * 0: The type of the iterable expression.
   * 1: The sequence type -- Iterable for `for` or Stream for `await for`.
   * 2: The loop variable type.
   */
  static const StaticTypeWarningCode FOR_IN_OF_INVALID_ELEMENT_TYPE =
      const StaticTypeWarningCode(
          'FOR_IN_OF_INVALID_ELEMENT_TYPE',
          "The type '{0}' used in the 'for' loop must implement {1} with a "
              "type argument that can be assigned to '{2}'.");

  /**
   * Initialize a newly created error code to have the given [name]. The message
   * associated with the error will be created from the given [message]
   * template. The correction associated with the error will be created from the
   * given [correction] template.
   */
  const StaticTypeWarningCode(String name, String message,
      {String correction, bool isUnresolvedIdentifier: false})
      : super.temporary(name, message,
            correction: correction,
            isUnresolvedIdentifier: isUnresolvedIdentifier);

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.ERROR;

  @override
  ErrorType get type => ErrorType.STATIC_TYPE_WARNING;
}

/**
 * The error codes used for static warnings. The convention for this class is
 * for the name of the error code to indicate the problem that caused the error
 * to be generated and for the error message to explain what is wrong and, when
 * appropriate, how the problem can be corrected.
 */
class StaticWarningCode extends ErrorCode {
  /**
   * 14.1 Imports: If a name <i>N</i> is referenced by a library <i>L</i> and
   * <i>N</i> is introduced into the top level scope <i>L</i> by more than one
   * import then:
   * 1. A static warning occurs.
   * 2. If <i>N</i> is referenced as a function, getter or setter, a
   *    <i>NoSuchMethodError</i> is raised.
   * 3. If <i>N</i> is referenced as a type, it is treated as a malformed type.
   *
   * Parameters:
   * 0: the name of the ambiguous type
   * 1: the name of the first library that the type is found
   * 2: the name of the second library that the type is found
   */
  static const StaticWarningCode AMBIGUOUS_IMPORT = const StaticWarningCode(
      'AMBIGUOUS_IMPORT', "The name '{0}' is defined in the libraries {1}.",
      correction: "Try using 'as prefix' for one of the import directives, or "
          "hiding the name from all but one of the imports.");

  /**
   * 12.11.1 New: It is a static warning if the static type of <i>a<sub>i</sub>,
   * 1 &lt;= i &lt;= n+ k</i> may not be assigned to the type of the
   * corresponding formal parameter of the constructor <i>T.id</i> (respectively
   * <i>T</i>).
   *
   * 16.12.2 Const: It is a static warning if the static type of
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
   *
   * Parameters:
   * 0: the name of the actual argument type
   * 1: the name of the expected type
   */
  static const StaticWarningCode ARGUMENT_TYPE_NOT_ASSIGNABLE =
      const StaticWarningCode('ARGUMENT_TYPE_NOT_ASSIGNABLE',
          "The argument type '{0}' can't be assigned to the parameter type '{1}'.");

  /**
   * 5 Variables: Attempting to assign to a final variable elsewhere will cause
   * a NoSuchMethodError to be thrown, because no setter is defined for it. The
   * assignment will also give rise to a static warning for the same reason.
   *
   * A constant variable is always implicitly final.
   */
  static const StaticWarningCode ASSIGNMENT_TO_CONST = const StaticWarningCode(
      'ASSIGNMENT_TO_CONST', "Constant variables can't be assigned a value.",
      correction: "Try removing the assignment, or "
          "remove the modifier 'const' from the variable.");

  /**
   * 5 Variables: Attempting to assign to a final variable elsewhere will cause
   * a NoSuchMethodError to be thrown, because no setter is defined for it. The
   * assignment will also give rise to a static warning for the same reason.
   */
  static const StaticWarningCode ASSIGNMENT_TO_FINAL = const StaticWarningCode(
      'ASSIGNMENT_TO_FINAL',
      "'{0}' can't be used as a setter because it is final.",
      correction: "Try finding a different setter, or making '{0}' non-final.");

  /**
   * 5 Variables: Attempting to assign to a final variable elsewhere will cause
   * a NoSuchMethodError to be thrown, because no setter is defined for it. The
   * assignment will also give rise to a static warning for the same reason.
   */
  static const StaticWarningCode ASSIGNMENT_TO_FINAL_LOCAL =
      const StaticWarningCode('ASSIGNMENT_TO_FINAL_LOCAL',
          "'{0}', a final variable, can only be set once.",
          correction: "Try making '{0}' non-final.");

  /**
   * 5 Variables: Attempting to assign to a final variable elsewhere will cause
   * a NoSuchMethodError to be thrown, because no setter is defined for it. The
   * assignment will also give rise to a static warning for the same reason.
   */
  static const StaticWarningCode ASSIGNMENT_TO_FINAL_NO_SETTER =
      const StaticWarningCode('ASSIGNMENT_TO_FINAL_NO_SETTER',
          "No setter named '{0}' in class '{1}'.",
          correction:
              "Try correcting the name to reference an existing setter, or "
              "declare the setter.");

  /**
   * 12.18 Assignment: It is as static warning if an assignment of the form
   * <i>v = e</i> occurs inside a top level or static function (be it function,
   * method, getter, or setter) or variable initializer and there is neither a
   * local variable declaration with name <i>v</i> nor setter declaration with
   * name <i>v=</i> in the lexical scope enclosing the assignment.
   */
  static const StaticWarningCode ASSIGNMENT_TO_FUNCTION =
      const StaticWarningCode(
          'ASSIGNMENT_TO_FUNCTION', "Functions can't be assigned a value.");

  /**
   * 12.18 Assignment: Let <i>T</i> be the static type of <i>e<sub>1</sub></i>
   * It is a static type warning if <i>T</i> does not have an accessible
   * instance setter named <i>v=</i>.
   */
  static const StaticWarningCode ASSIGNMENT_TO_METHOD = const StaticWarningCode(
      'ASSIGNMENT_TO_METHOD', "Methods can't be assigned a value.");

  /**
   * 12.18 Assignment: It is as static warning if an assignment of the form
   * <i>v = e</i> occurs inside a top level or static function (be it function,
   * method, getter, or setter) or variable initializer and there is neither a
   * local variable declaration with name <i>v</i> nor setter declaration with
   * name <i>v=</i> in the lexical scope enclosing the assignment.
   */
  static const StaticWarningCode ASSIGNMENT_TO_TYPE = const StaticWarningCode(
      'ASSIGNMENT_TO_TYPE', "Types can't be assigned a value.");

  /**
   * 13.9 Switch: It is a static warning if the last statement of the statement
   * sequence <i>s<sub>k</sub></i> is not a break, continue, rethrow, return
   * or throw statement.
   */
  static const StaticWarningCode CASE_BLOCK_NOT_TERMINATED =
      const StaticWarningCode(
          'CASE_BLOCK_NOT_TERMINATED',
          "The last statement of the 'case' should be 'break', 'continue', "
              "'rethrow', 'return' or 'throw'.",
          correction: "Try adding one of the required statements.");

  /**
   * 12.32 Type Cast: It is a static warning if <i>T</i> does not denote a type
   * available in the current lexical scope.
   */
  static const StaticWarningCode CAST_TO_NON_TYPE = const StaticWarningCode(
      'CAST_TO_NON_TYPE',
      "The name '{0}' isn't a type, so it can't be used in an 'as' expression.",
      correction: "Try changing the name to the name of an existing type, or "
          "creating a type with the name '{0}'.");

  /**
   * 7.4 Abstract Instance Members: It is a static warning if an abstract member
   * is declared or inherited in a concrete class.
   *
   * Parameters:
   * 0: the name of the abstract method
   * 1: the name of the enclosing class
   */
  static const StaticWarningCode CONCRETE_CLASS_WITH_ABSTRACT_MEMBER =
      const StaticWarningCode('CONCRETE_CLASS_WITH_ABSTRACT_MEMBER',
          "'{0}' must have a method body because '{1}' isn't abstract.",
          correction: "Try making '{1}' abstract, or adding a body to '{0}'.");

  /**
   * 16.12.2 Const: Given an instance creation expression of the form <i>const
   * q(a<sub>1</sub>, &hellip; a<sub>n</sub>)</i> it is a static warning if
   * <i>q</i> is the constructor of an abstract class but <i>q</i> is not a
   * factory constructor.
   */
  static const StaticWarningCode CONST_WITH_ABSTRACT_CLASS =
      const StaticWarningCode('CONST_WITH_ABSTRACT_CLASS',
          "Abstract classes can't be created with a 'const' expression.",
          correction: "Try creating an instance of a subtype.");

  /**
   * 14.2 Exports: It is a static warning to export two different libraries with
   * the same name.
   *
   * Parameters:
   * 0: the uri pointing to a first library
   * 1: the uri pointing to a second library
   * 2:e the shared name of the exported libraries
   */
  static const StaticWarningCode EXPORT_DUPLICATED_LIBRARY_NAMED =
      const StaticWarningCode('EXPORT_DUPLICATED_LIBRARY_NAMED',
          "The exported libraries '{0}' and '{1}' can't have the same name '{2}'.",
          correction:
              "Try adding a hide clause to one of the export directives.");

  /**
   * 12.14.2 Binding Actuals to Formals: It is a static warning if <i>m &lt;
   * h</i> or if <i>m &gt; n</i>.
   *
   * Parameters:
   * 0: the maximum number of positional arguments
   * 1: the actual number of positional arguments given
   *
   * See [NOT_ENOUGH_REQUIRED_ARGUMENTS].
   */
  static const StaticWarningCode EXTRA_POSITIONAL_ARGUMENTS =
      const StaticWarningCode('EXTRA_POSITIONAL_ARGUMENTS',
          "Too many positional arguments: {0} expected, but {1} found.",
          correction: "Try removing the extra positional arguments.");

  /**
   * 12.14.2 Binding Actuals to Formals: It is a static warning if <i>m &lt;
   * h</i> or if <i>m &gt; n</i>.
   *
   * Parameters:
   * 0: the maximum number of positional arguments
   * 1: the actual number of positional arguments given
   *
   * See [NOT_ENOUGH_REQUIRED_ARGUMENTS].
   */
  static const StaticWarningCode EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED =
      const StaticWarningCode('EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED',
          "Too many positional arguments: {0} expected, but {1} found.",
          correction: "Try removing the extra positional arguments, "
              "or specifying the name for named arguments.");

  /**
   * 5. Variables: It is a static warning if a final instance variable that has
   * been initialized at its point of declaration is also initialized in a
   * constructor.
   */
  static const StaticWarningCode
      FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION =
      const StaticWarningCode(
          'FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION',
          "Fields can't be initialized in the constructor if they are final "
              "and have already been initialized at their declaration.",
          correction: "Try removing one of the initializations.");

  /**
   * 5. Variables: It is a static warning if a final instance variable that has
   * been initialized at its point of declaration is also initialized in a
   * constructor.
   *
   * Parameters:
   * 0: the name of the field in question
   */
  static const StaticWarningCode
      FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR =
      const StaticWarningCode(
          'FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR',
          "'{0}' is final and was given a value when it was declared, "
              "so it can't be set to a new value.",
          correction: "Try removing one of the initializations.");

  /**
   * 7.6.1 Generative Constructors: Execution of an initializer of the form
   * <b>this</b>.<i>v</i> = <i>e</i> proceeds as follows: First, the expression
   * <i>e</i> is evaluated to an object <i>o</i>. Then, the instance variable
   * <i>v</i> of the object denoted by this is bound to <i>o</i>.
   *
   * 12.14.2 Binding Actuals to Formals: Let <i>T<sub>i</sub></i> be the static
   * type of <i>a<sub>i</sub></i>, let <i>S<sub>i</sub></i> be the type of
   * <i>p<sub>i</sub>, 1 &lt;= i &lt;= n+k</i> and let <i>S<sub>q</sub></i> be
   * the type of the named parameter <i>q</i> of <i>f</i>. It is a static
   * warning if <i>T<sub>j</sub></i> may not be assigned to <i>S<sub>j</sub>, 1
   * &lt;= j &lt;= m</i>.
   *
   * Parameters:
   * 0: the name of the type of the initializer expression
   * 1: the name of the type of the field
   */
  static const StaticWarningCode FIELD_INITIALIZER_NOT_ASSIGNABLE =
      const StaticWarningCode('FIELD_INITIALIZER_NOT_ASSIGNABLE',
          "The initializer type '{0}' can't be assigned to the field type '{1}'.");

  /**
   * 7.6.1 Generative Constructors: An initializing formal has the form
   * <i>this.id</i>. It is a static warning if the static type of <i>id</i> is
   * not assignable to <i>T<sub>id</sub></i>.
   *
   * Parameters:
   * 0: the name of the type of the field formal parameter
   * 1: the name of the type of the field
   */
  static const StaticWarningCode FIELD_INITIALIZING_FORMAL_NOT_ASSIGNABLE =
      const StaticWarningCode('FIELD_INITIALIZING_FORMAL_NOT_ASSIGNABLE',
          "The parameter type '{0}' is incompatible with the field type '{1}'.",
          correction: "Try changing or removing the parameter's type, or "
              "changing the field's type.");

  /**
   * 5 Variables: It is a static warning if a library, static or local variable
   * <i>v</i> is final and <i>v</i> is not initialized at its point of
   * declaration.
   *
   * Parameters:
   * 0: the name of the uninitialized final variable
   */
  static const StaticWarningCode FINAL_NOT_INITIALIZED =
      const StaticWarningCode('FINAL_NOT_INITIALIZED',
          "The final variable '{0}' must be initialized.",
          // TODO(brianwilkerson) Split this error code so that we can suggest
          // initializing fields in constructors (FINAL_FIELD_NOT_INITIALIZED
          // and FINAL_VARIABLE_NOT_INITIALIZED).
          correction: "Try initializing the variable.");

  /**
   * 7.6.1 Generative Constructors: Each final instance variable <i>f</i>
   * declared in the immediately enclosing class must have an initializer in
   * <i>k</i>'s initializer list unless it has already been initialized by one
   * of the following means:
   * * Initialization at the declaration of <i>f</i>.
   * * Initialization by means of an initializing formal of <i>k</i>.
   * or a static warning occurs.
   *
   * Parameters:
   * 0: the name of the uninitialized final variable
   */
  static const StaticWarningCode FINAL_NOT_INITIALIZED_CONSTRUCTOR_1 =
      const StaticWarningCode('FINAL_NOT_INITIALIZED_CONSTRUCTOR_1',
          "The final variable '{0}' must be initialized.",
          correction: "Try adding an initializer for the field.");

  /**
   * 7.6.1 Generative Constructors: Each final instance variable <i>f</i>
   * declared in the immediately enclosing class must have an initializer in
   * <i>k</i>'s initializer list unless it has already been initialized by one
   * of the following means:
   * * Initialization at the declaration of <i>f</i>.
   * * Initialization by means of an initializing formal of <i>k</i>.
   * or a static warning occurs.
   *
   * Parameters:
   * 0: the name of the uninitialized final variable
   * 1: the name of the uninitialized final variable
   */
  static const StaticWarningCode FINAL_NOT_INITIALIZED_CONSTRUCTOR_2 =
      const StaticWarningCode('FINAL_NOT_INITIALIZED_CONSTRUCTOR_2',
          "The final variables '{0}' and '{1}' must be initialized.",
          correction: "Try adding initializers for the fields.");

  /**
   * 7.6.1 Generative Constructors: Each final instance variable <i>f</i>
   * declared in the immediately enclosing class must have an initializer in
   * <i>k</i>'s initializer list unless it has already been initialized by one
   * of the following means:
   * * Initialization at the declaration of <i>f</i>.
   * * Initialization by means of an initializing formal of <i>k</i>.
   * or a static warning occurs.
   *
   * Parameters:
   * 0: the name of the uninitialized final variable
   * 1: the name of the uninitialized final variable
   * 2: the number of additional not initialized variables that aren't listed
   */
  static const StaticWarningCode FINAL_NOT_INITIALIZED_CONSTRUCTOR_3_PLUS =
      const StaticWarningCode('FINAL_NOT_INITIALIZED_CONSTRUCTOR_3',
          "The final variables '{0}', '{1}' and '{2}' more must be initialized.",
          correction: "Try adding initializers for the fields.");

  /**
   * 14.1 Imports: It is a static warning to import two different libraries with
   * the same name.
   *
   * Parameters:
   * 0: the uri pointing to a first library
   * 1: the uri pointing to a second library
   * 2: the shared name of the imported libraries
   */
  static const StaticWarningCode IMPORT_DUPLICATED_LIBRARY_NAMED =
      const StaticWarningCode('IMPORT_DUPLICATED_LIBRARY_NAMED',
          "The imported libraries '{0}' and '{1}' can't have the same name '{2}'.",
          correction: "Try adding a hide clause to one of the imports.");

  /**
   * 14.1 Imports: It is a static warning if the specified URI of a deferred
   * import does not refer to a library declaration.
   *
   * Parameters:
   * 0: the uri pointing to a non-library declaration
   *
   * See [CompileTimeErrorCode.IMPORT_OF_NON_LIBRARY].
   */
  static const StaticWarningCode IMPORT_OF_NON_LIBRARY =
      const StaticWarningCode('IMPORT_OF_NON_LIBRARY',
          "The imported library '{0}' can't have a part-of directive.",
          correction: "Try importing the library that the part is a part of.");

  /**
   * 7.1 Instance Methods: It is a static warning if an instance method
   * <i>m1</i> overrides an instance member <i>m2</i>, the signature of
   * <i>m2</i> explicitly specifies a default value for a formal parameter
   * <i>p</i> and the signature of <i>m1</i> specifies a different default value
   * for <i>p</i>.
   */
  static const StaticWarningCode
      INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_NAMED = const StaticWarningCode(
          'INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_NAMED',
          "Parameters can't override default values, "
              "this method overrides '{0}.{1}' where '{2}' has a different value.",
          correction: "Try using the same default value in both methods.",
          errorSeverity: ErrorSeverity.WARNING);

  /**
   * 7.1 Instance Methods: It is a static warning if an instance method
   * <i>m1</i> overrides an instance member <i>m2</i>, the signature of
   * <i>m2</i> explicitly specifies a default value for a formal parameter
   * <i>p</i> and the signature of <i>m1</i> specifies a different default value
   * for <i>p</i>.
   */
  static const StaticWarningCode
      INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_POSITIONAL =
      const StaticWarningCode(
          'INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_POSITIONAL',
          "Parameters can't override default values, this method overrides "
              "'{0}.{1}' where this positional parameter has a different value.",
          correction: "Try using the same default value in both methods.",
          errorSeverity: ErrorSeverity.WARNING);

  /**
   * 12.6 Lists: A run-time list literal &lt;<i>E</i>&gt; [<i>e<sub>1</sub></i>
   * &hellip; <i>e<sub>n</sub></i>] is evaluated as follows:
   * * The operator []= is invoked on <i>a</i> with first argument <i>i</i> and
   *   second argument <i>o<sub>i+1</sub></i><i>, 1 &lt;= i &lt;= n</i>
   *
   * 12.14.2 Binding Actuals to Formals: Let <i>T<sub>i</sub></i> be the static
   * type of <i>a<sub>i</sub></i>, let <i>S<sub>i</sub></i> be the type of
   * <i>p<sub>i</sub>, 1 &lt;= i &lt;= n+k</i> and let <i>S<sub>q</sub></i> be
   * the type of the named parameter <i>q</i> of <i>f</i>. It is a static
   * warning if <i>T<sub>j</sub></i> may not be assigned to <i>S<sub>j</sub>, 1
   * &lt;= j &lt;= m</i>.
   *
   * Parameters:
   * 0: the actual type of the list element
   * 1: the expected type of the list element
   */
  static const StaticWarningCode LIST_ELEMENT_TYPE_NOT_ASSIGNABLE =
      const StaticWarningCode('LIST_ELEMENT_TYPE_NOT_ASSIGNABLE',
          "The element type '{0}' can't be assigned to the list type '{1}'.");

  /**
   * 12.7 Map: A run-time map literal &lt;<i>K</i>, <i>V</i>&gt;
   * [<i>k<sub>1</sub></i> : <i>e<sub>1</sub></i> &hellip; <i>k<sub>n</sub></i>
   * : <i>e<sub>n</sub></i>] is evaluated as follows:
   * * The operator []= is invoked on <i>m</i> with first argument
   *   <i>k<sub>i</sub></i> and second argument <i>e<sub>i</sub></i><i>, 1 &lt;=
   *   i &lt;= n</i>
   *
   * 12.14.2 Binding Actuals to Formals: Let <i>T<sub>i</sub></i> be the static
   * type of <i>a<sub>i</sub></i>, let <i>S<sub>i</sub></i> be the type of
   * <i>p<sub>i</sub>, 1 &lt;= i &lt;= n+k</i> and let <i>S<sub>q</sub></i> be
   * the type of the named parameter <i>q</i> of <i>f</i>. It is a static
   * warning if <i>T<sub>j</sub></i> may not be assigned to <i>S<sub>j</sub>, 1
   * &lt;= j &lt;= m</i>.
   */
  static const StaticWarningCode MAP_KEY_TYPE_NOT_ASSIGNABLE =
      const StaticWarningCode('MAP_KEY_TYPE_NOT_ASSIGNABLE',
          "The element type '{0}' can't be assigned to the map key type '{1}'.");

  /**
   * 12.7 Map: A run-time map literal &lt;<i>K</i>, <i>V</i>&gt;
   * [<i>k<sub>1</sub></i> : <i>e<sub>1</sub></i> &hellip; <i>k<sub>n</sub></i>
   * : <i>e<sub>n</sub></i>] is evaluated as follows:
   * * The operator []= is invoked on <i>m</i> with first argument
   *   <i>k<sub>i</sub></i> and second argument <i>e<sub>i</sub></i><i>, 1 &lt;=
   *   i &lt;= n</i>
   *
   * 12.14.2 Binding Actuals to Formals: Let <i>T<sub>i</sub></i> be the static
   * type of <i>a<sub>i</sub></i>, let <i>S<sub>i</sub></i> be the type of
   * <i>p<sub>i</sub>, 1 &lt;= i &lt;= n+k</i> and let <i>S<sub>q</sub></i> be
   * the type of the named parameter <i>q</i> of <i>f</i>. It is a static
   * warning if <i>T<sub>j</sub></i> may not be assigned to <i>S<sub>j</sub>, 1
   * &lt;= j &lt;= m</i>.
   */
  static const StaticWarningCode MAP_VALUE_TYPE_NOT_ASSIGNABLE =
      const StaticWarningCode('MAP_VALUE_TYPE_NOT_ASSIGNABLE',
          "The element type '{0}' can't be assigned to the map value type '{1}'.");

  /**
   * 10.3 Setters: It is a compile-time error if a class has a setter named
   * `v=` with argument type `T` and a getter named `v` with return type `S`,
   * and `S` may not be assigned to `T`.
   *
   * Parameters:
   * 0: the name of the getter
   * 1: the type of the getter
   * 2: the type of the setter
   * 3: the name of the setter
   */
  static const StaticWarningCode MISMATCHED_GETTER_AND_SETTER_TYPES =
      const StaticWarningCode(
          'MISMATCHED_GETTER_AND_SETTER_TYPES',
          "The return type of getter '{0}' is '{1}' which isn't assignable "
              "to the type '{2}' of its setter '{3}'.",
          correction: "Try changing the types so that they are compatible.");

  /**
   * 17.9 Switch: It is a static warning if all of the following conditions
   * hold:
   * * The switch statement does not have a 'default' clause.
   * * The static type of <i>e</i> is an enumerated typed with elements
   *   <i>id<sub>1</sub></i>, &hellip;, <i>id<sub>n</sub></i>.
   * * The sets {<i>e<sub>1</sub></i>, &hellip;, <i>e<sub>k</sub></i>} and
   *   {<i>id<sub>1</sub></i>, &hellip;, <i>id<sub>n</sub></i>} are not the
   *   same.
   *
   * Parameters:
   * 0: the name of the constant that is missing
   */
  static const StaticWarningCode MISSING_ENUM_CONSTANT_IN_SWITCH =
      const StaticWarningCode(
          'MISSING_ENUM_CONSTANT_IN_SWITCH', "Missing case clause for '{0}'.",
          correction: "Try adding a case clause for the missing constant, or "
              "adding a default clause.");

  /**
   * 13.12 Return: It is a static warning if a function contains both one or
   * more return statements of the form <i>return;</i> and one or more return
   * statements of the form <i>return e;</i>.
   */
  static const StaticWarningCode MIXED_RETURN_TYPES = const StaticWarningCode(
      'MIXED_RETURN_TYPES',
      "Functions can't include return statements both with and without values.",
      // TODO(brianwilkerson) Split this error code depending on whether the
      // function declares a return type.
      correction: "Try making all the return statements consistent "
          "(either include a value or not).");

  /**
   * 12.11.1 New: It is a static warning if <i>q</i> is a constructor of an
   * abstract class and <i>q</i> is not a factory constructor.
   */
  static const StaticWarningCode NEW_WITH_ABSTRACT_CLASS =
      const StaticWarningCode('NEW_WITH_ABSTRACT_CLASS',
          "Abstract classes can't be created with a 'new' expression.",
          correction: "Try creating an instance of a subtype.");

  /**
   * 15.8 Parameterized Types: Any use of a malbounded type gives rise to a
   * static warning.
   *
   * Parameters:
   * 0: the name of the type being referenced (<i>S</i>)
   * 1: the number of type parameters that were declared
   * 2: the number of type arguments provided
   *
   * See [CompileTimeErrorCode.CONST_WITH_INVALID_TYPE_PARAMETERS], and
   * [StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS].
   */
  static const StaticWarningCode NEW_WITH_INVALID_TYPE_PARAMETERS =
      const StaticWarningCode(
          'NEW_WITH_INVALID_TYPE_PARAMETERS',
          "The type '{0}' is declared with {1} type parameters, "
              "but {2} type arguments were given.",
          correction: "Try adjusting the number of type arguments.");

  /**
   * 12.11.1 New: It is a static warning if <i>T</i> is not a class accessible
   * in the current scope, optionally followed by type arguments.
   *
   * Parameters:
   * 0: the name of the non-type element
   */
  static const StaticWarningCode NEW_WITH_NON_TYPE = const StaticWarningCode(
      'NEW_WITH_NON_TYPE', "The name '{0}' isn't a class.",
      correction: "Try correcting the name to match an existing class.");

  /**
   * 12.11.1 New: If <i>T</i> is a class or parameterized type accessible in the
   * current scope then:
   * 1. If <i>e</i> is of the form <i>new T.id(a<sub>1</sub>, &hellip;,
   *    a<sub>n</sub>, x<sub>n+1</sub>: a<sub>n+1</sub>, &hellip;,
   *    x<sub>n+k</sub>: a<sub>n+k</sub>)</i> it is a static warning if
   *    <i>T.id</i> is not the name of a constructor declared by the type
   *    <i>T</i>.
   * If <i>e</i> of the form <i>new T(a<sub>1</sub>, &hellip;, a<sub>n</sub>,
   * x<sub>n+1</sub>: a<sub>n+1</sub>, &hellip;, x<sub>n+k</sub>:
   * a<sub>n+kM/sub>)</i> it is a static warning if the type <i>T</i> does not
   * declare a constructor with the same name as the declaration of <i>T</i>.
   */
  static const StaticWarningCode NEW_WITH_UNDEFINED_CONSTRUCTOR =
      const StaticWarningCode('NEW_WITH_UNDEFINED_CONSTRUCTOR',
          "The class '{0}' doesn't have a constructor named '{1}'.",
          correction: "Try invoking a different constructor, or "
              "define a constructor named '{1}'.");

  /**
   * 12.11.1 New: If <i>T</i> is a class or parameterized type accessible in the
   * current scope then:
   * 1. If <i>e</i> is of the form <i>new T.id(a<sub>1</sub>, &hellip;,
   * a<sub>n</sub>, x<sub>n+1</sub>: a<sub>n+1</sub>, &hellip;, x<sub>n+k</sub>:
   * a<sub>n+k</sub>)</i> it is a static warning if <i>T.id</i> is not the name
   * of a constructor declared by the type <i>T</i>. If <i>e</i> of the form
   * <i>new T(a<sub>1</sub>, &hellip;, a<sub>n</sub>, x<sub>n+1</sub>:
   * a<sub>n+1</sub>, &hellip;, x<sub>n+k</sub>: a<sub>n+kM/sub>)</i> it is a
   * static warning if the type <i>T</i> does not declare a constructor with the
   * same name as the declaration of <i>T</i>.
   */
  static const StaticWarningCode NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT =
      const StaticWarningCode('NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT',
          "The class '{0}' doesn't have a default constructor.",
          correction:
              "Try using one of the named constructors defined in '{0}'.");

  /**
   * 7.9.1 Inheritance and Overriding: It is a static warning if a non-abstract
   * class inherits an abstract method.
   *
   * 7.10 Superinterfaces: Let <i>C</i> be a concrete class that does not
   * declare its own <i>noSuchMethod()</i> method. It is a static warning if the
   * implicit interface of <i>C</i> includes an instance member <i>m</i> of type
   * <i>F</i> and <i>C</i> does not declare or inherit a corresponding instance
   * member <i>m</i> of type <i>F'</i> such that <i>F' <: F</i>.
   *
   * 7.4 Abstract Instance Members: It is a static warning if an abstract member
   * is declared or inherited in a concrete class unless that member overrides a
   * concrete one.
   *
   * Parameters:
   * 0: the name of the first member
   * 1: the name of the second member
   * 2: the name of the third member
   * 3: the name of the fourth member
   * 4: the number of additional missing members that aren't listed
   */
  static const StaticWarningCode
      NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FIVE_PLUS =
      const StaticWarningCode(
          'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FIVE_PLUS',
          "Missing concrete implementations of {0}, {1}, {2}, {3} and {4} more.",
          correction:
              "Try implementing the missing methods, or make the class abstract.");

  /**
   * 7.9.1 Inheritance and Overriding: It is a static warning if a non-abstract
   * class inherits an abstract method.
   *
   * 7.10 Superinterfaces: Let <i>C</i> be a concrete class that does not
   * declare its own <i>noSuchMethod()</i> method. It is a static warning if the
   * implicit interface of <i>C</i> includes an instance member <i>m</i> of type
   * <i>F</i> and <i>C</i> does not declare or inherit a corresponding instance
   * member <i>m</i> of type <i>F'</i> such that <i>F' <: F</i>.
   *
   * 7.4 Abstract Instance Members: It is a static warning if an abstract member
   * is declared or inherited in a concrete class unless that member overrides a
   * concrete one.
   *
   * Parameters:
   * 0: the name of the first member
   * 1: the name of the second member
   * 2: the name of the third member
   * 3: the name of the fourth member
   */
  static const StaticWarningCode
      NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FOUR =
      const StaticWarningCode(
          'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FOUR',
          "Missing concrete implementations of {0}, {1}, {2} and {3}.",
          correction:
              "Try implementing the missing methods, or make the class abstract.");

  /**
   * 7.9.1 Inheritance and Overriding: It is a static warning if a non-abstract
   * class inherits an abstract method.
   *
   * 7.10 Superinterfaces: Let <i>C</i> be a concrete class that does not
   * declare its own <i>noSuchMethod()</i> method. It is a static warning if the
   * implicit interface of <i>C</i> includes an instance member <i>m</i> of type
   * <i>F</i> and <i>C</i> does not declare or inherit a corresponding instance
   * member <i>m</i> of type <i>F'</i> such that <i>F' <: F</i>.
   *
   * 7.4 Abstract Instance Members: It is a static warning if an abstract member
   * is declared or inherited in a concrete class unless that member overrides a
   * concrete one.
   *
   * Parameters:
   * 0: the name of the member
   */
  static const StaticWarningCode
      NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE = const StaticWarningCode(
          'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE',
          "Missing concrete implementation of {0}.",
          correction:
              "Try implementing the missing method, or make the class abstract.");

  /**
   * 7.9.1 Inheritance and Overriding: It is a static warning if a non-abstract
   * class inherits an abstract method.
   *
   * 7.10 Superinterfaces: Let <i>C</i> be a concrete class that does not
   * declare its own <i>noSuchMethod()</i> method. It is a static warning if the
   * implicit interface of <i>C</i> includes an instance member <i>m</i> of type
   * <i>F</i> and <i>C</i> does not declare or inherit a corresponding instance
   * member <i>m</i> of type <i>F'</i> such that <i>F' <: F</i>.
   *
   * 7.4 Abstract Instance Members: It is a static warning if an abstract member
   * is declared or inherited in a concrete class unless that member overrides a
   * concrete one.
   *
   * Parameters:
   * 0: the name of the first member
   * 1: the name of the second member
   * 2: the name of the third member
   */
  static const StaticWarningCode
      NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_THREE =
      const StaticWarningCode(
          'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_THREE',
          "Missing concrete implementations of {0}, {1} and {2}.",
          correction:
              "Try implementing the missing methods, or make the class abstract.");

  /**
   * 7.9.1 Inheritance and Overriding: It is a static warning if a non-abstract
   * class inherits an abstract method.
   *
   * 7.10 Superinterfaces: Let <i>C</i> be a concrete class that does not
   * declare its own <i>noSuchMethod()</i> method. It is a static warning if the
   * implicit interface of <i>C</i> includes an instance member <i>m</i> of type
   * <i>F</i> and <i>C</i> does not declare or inherit a corresponding instance
   * member <i>m</i> of type <i>F'</i> such that <i>F' <: F</i>.
   *
   * 7.4 Abstract Instance Members: It is a static warning if an abstract member
   * is declared or inherited in a concrete class unless that member overrides a
   * concrete one.
   *
   * Parameters:
   * 0: the name of the first member
   * 1: the name of the second member
   */
  static const StaticWarningCode
      NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO = const StaticWarningCode(
          'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO',
          "Missing concrete implementations of {0} and {1}.",
          correction:
              "Try implementing the missing methods, or make the class abstract.");

  /**
   * 13.11 Try: An on-catch clause of the form <i>on T catch (p<sub>1</sub>,
   * p<sub>2</sub>) s</i> or <i>on T s</i> matches an object <i>o</i> if the
   * type of <i>o</i> is a subtype of <i>T</i>. It is a static warning if
   * <i>T</i> does not denote a type available in the lexical scope of the
   * catch clause.
   *
   * Parameters:
   * 0: the name of the non-type element
   */
  static const StaticWarningCode NON_TYPE_IN_CATCH_CLAUSE =
      const StaticWarningCode('NON_TYPE_IN_CATCH_CLAUSE',
          "The name '{0}' isn't a type and can't be used in an on-catch clause.",
          correction: "Try correcting the name to match an existing class.");

  /**
   * 7.1.1 Operators: It is a static warning if the return type of the
   * user-declared operator []= is explicitly declared and not void.
   */
  static const StaticWarningCode NON_VOID_RETURN_FOR_OPERATOR =
      const StaticWarningCode('NON_VOID_RETURN_FOR_OPERATOR',
          "The return type of the operator []= must be 'void'.",
          correction: "Try changing the return type to 'void'.");

  /**
   * 7.3 Setters: It is a static warning if a setter declares a return type
   * other than void.
   */
  static const StaticWarningCode NON_VOID_RETURN_FOR_SETTER =
      const StaticWarningCode('NON_VOID_RETURN_FOR_SETTER',
          "The return type of the setter must be 'void' or absent.",
          correction: "Try removing the return type, or "
              "define a method rather than a setter.");

  /**
   * 15.1 Static Types: A type <i>T</i> is malformed iff:
   * * <i>T</i> has the form <i>id</i> or the form <i>prefix.id</i>, and in the
   *   enclosing lexical scope, the name <i>id</i> (respectively
   *   <i>prefix.id</i>) does not denote a type.
   * * <i>T</i> denotes a type parameter in the enclosing lexical scope, but
   * occurs in the signature or body of a static member.
   * * <i>T</i> is a parameterized type of the form <i>G&lt;S<sub>1</sub>, ..,
   * S<sub>n</sub>&gt;</i>,
   *
   * Any use of a malformed type gives rise to a static warning.
   *
   * Parameters:
   * 0: the name that is not a type
   */
  static const StaticWarningCode NOT_A_TYPE = const StaticWarningCode(
      'NOT_A_TYPE', "{0} isn't a type.",
      correction: "Try correcting the name to match an existing type.");

  /**
   * 12.14.2 Binding Actuals to Formals: It is a static warning if <i>m &lt;
   * h</i> or if <i>m &gt; n</i>.
   *
   * Parameters:
   * 0: the expected number of required arguments
   * 1: the actual number of positional arguments given
   *
   * See [EXTRA_POSITIONAL_ARGUMENTS].
   */
  static const StaticWarningCode NOT_ENOUGH_REQUIRED_ARGUMENTS =
      const StaticWarningCode('NOT_ENOUGH_REQUIRED_ARGUMENTS',
          "{0} required argument(s) expected, but {1} found.",
          correction: "Try adding the additional required arguments.");

  /**
   * 14.3 Parts: It is a static warning if the referenced part declaration
   * <i>p</i> names a library other than the current library as the library to
   * which <i>p</i> belongs.
   *
   * Parameters:
   * 0: the name of expected library name
   * 1: the non-matching actual library name from the "part of" declaration
   */
  static const StaticWarningCode PART_OF_DIFFERENT_LIBRARY =
      const StaticWarningCode('PART_OF_DIFFERENT_LIBRARY',
          "Expected this library to be part of '{0}', not '{1}'.",
          correction: "Try including a different part, or "
              "changing the name of the library in the part's part-of directive.");

  /**
   * 7.6.2 Factories: It is a static warning if the function type of <i>k'</i>
   * is not a subtype of the type of <i>k</i>.
   *
   * Parameters:
   * 0: the name of the redirected constructor
   * 1: the name of the redirecting constructor
   */
  static const StaticWarningCode REDIRECT_TO_INVALID_FUNCTION_TYPE =
      const StaticWarningCode('REDIRECT_TO_INVALID_FUNCTION_TYPE',
          "The redirected constructor '{0}' has incompatible parameters with '{1}'.",
          correction: "Try redirecting to a different constructor, or "
              "directly invoking the desired constructor rather than redirecting to it.");

  /**
   * 7.6.2 Factories: It is a static warning if the function type of <i>k'</i>
   * is not a subtype of the type of <i>k</i>.
   *
   * Parameters:
   * 0: the name of the redirected constructor's return type
   * 1: the name of the redirecting constructor's return type
   */
  static const StaticWarningCode REDIRECT_TO_INVALID_RETURN_TYPE =
      const StaticWarningCode('REDIRECT_TO_INVALID_RETURN_TYPE',
          "The return type '{0}' of the redirected constructor isn't assignable to '{1}'.",
          correction: "Try redirecting to a different constructor, or "
              "directly invoking the desired constructor rather than redirecting to it.");

  /**
   * 7.6.2 Factories: It is a static warning if type does not denote a class
   * accessible in the current scope; if type does denote such a class <i>C</i>
   * it is a static warning if the referenced constructor (be it <i>type</i> or
   * <i>type.id</i>) is not a constructor of <i>C</i>.
   */
  static const StaticWarningCode REDIRECT_TO_MISSING_CONSTRUCTOR =
      const StaticWarningCode('REDIRECT_TO_MISSING_CONSTRUCTOR',
          "The constructor '{0}' couldn't be found in '{1}'.",
          correction:
              "Try correcting the constructor name to an existing constructor, or "
              "defining the constructor in '{1}'.");

  /**
   * 7.6.2 Factories: It is a static warning if type does not denote a class
   * accessible in the current scope; if type does denote such a class <i>C</i>
   * it is a static warning if the referenced constructor (be it <i>type</i> or
   * <i>type.id</i>) is not a constructor of <i>C</i>.
   */
  static const StaticWarningCode REDIRECT_TO_NON_CLASS = const StaticWarningCode(
      'REDIRECT_TO_NON_CLASS',
      "The name '{0}' isn't a type and can't be used in a redirected constructor.",
      correction: "Try correcting the name to match an existing class.");

  /**
   * 13.12 Return: Let <i>f</i> be the function immediately enclosing a return
   * statement of the form <i>return;</i> It is a static warning if both of the
   * following conditions hold:
   * * <i>f</i> is not a generative constructor.
   * * The return type of <i>f</i> may not be assigned to void.
   */
  static const StaticWarningCode RETURN_WITHOUT_VALUE = const StaticWarningCode(
      'RETURN_WITHOUT_VALUE', "Missing return value after 'return'.",
      correction: null);

  /**
   * Parameters:
   * 0: the actual type of the set element
   * 1: the expected type of the set element
   */
  static const StaticWarningCode SET_ELEMENT_TYPE_NOT_ASSIGNABLE =
      const StaticWarningCode('SET_ELEMENT_TYPE_NOT_ASSIGNABLE',
          "The element type '{0}' can't be assigned to the set type '{1}'.");

  /**
   * 12.16.3 Static Invocation: It is a static warning if <i>C</i> does not
   * declare a static method or getter <i>m</i>.
   *
   * Parameters:
   * 0: the name of the instance member
   */
  static const StaticWarningCode STATIC_ACCESS_TO_INSTANCE_MEMBER =
      const StaticWarningCode('STATIC_ACCESS_TO_INSTANCE_MEMBER',
          "Instance member '{0}' can't be accessed using static access.");

  /**
   * 13.9 Switch: It is a static warning if the type of <i>e</i> may not be
   * assigned to the type of <i>e<sub>k</sub></i>.
   */
  static const StaticWarningCode SWITCH_EXPRESSION_NOT_ASSIGNABLE =
      const StaticWarningCode(
          'SWITCH_EXPRESSION_NOT_ASSIGNABLE',
          "Type '{0}' of the switch expression isn't assignable to "
              "the type '{1}' of case expressions.");

  /**
   * 15.1 Static Types: It is a static warning to use a deferred type in a type
   * annotation.
   *
   * Parameters:
   * 0: the name of the type that is deferred and being used in a type
   *    annotation
   */
  static const StaticWarningCode TYPE_ANNOTATION_DEFERRED_CLASS =
      const StaticWarningCode('TYPE_ANNOTATION_DEFERRED_CLASS',
          "The deferred type '{0}' can't be used in a declaration, cast or type test.",
          correction: "Try using a different type, or "
              "changing the import to not be deferred.");

  /**
   * 12.31 Type Test: It is a static warning if <i>T</i> does not denote a type
   * available in the current lexical scope.
   */
  static const StaticWarningCode TYPE_TEST_WITH_NON_TYPE =
      const StaticWarningCode('TYPE_TEST_WITH_NON_TYPE',
          "The name '{0}' isn't a type and can't be used in an 'is' expression.",
          correction: "Try correcting the name to match an existing type.");

  /**
   * 12.31 Type Test: It is a static warning if <i>T</i> does not denote a type
   * available in the current lexical scope.
   */
  static const StaticWarningCode TYPE_TEST_WITH_UNDEFINED_NAME =
      const StaticWarningCode('TYPE_TEST_WITH_UNDEFINED_NAME',
          "The name '{0}' isn't defined, so it can't be used in an 'is' expression.",
          correction:
              "Try changing the name to the name of an existing type, or "
              "creating a type with the name '{0}'.");

  /**
   * 10 Generics: However, a type parameter is considered to be a malformed type
   * when referenced by a static member.
   *
   * 15.1 Static Types: Any use of a malformed type gives rise to a static
   * warning. A malformed type is then interpreted as dynamic by the static type
   * checker and the runtime.
   */
  static const StaticWarningCode TYPE_PARAMETER_REFERENCED_BY_STATIC =
      const StaticWarningCode('TYPE_PARAMETER_REFERENCED_BY_STATIC',
          "Static members can't reference type parameters of the class.",
          correction: "Try removing the reference to the type parameter, or "
              "making the member an instance member.");

  /**
   * 12.16.3 Static Invocation: A static method invocation <i>i</i> has the form
   * <i>C.m(a<sub>1</sub>, &hellip;, a<sub>n</sub>, x<sub>n+1</sub>:
   * a<sub>n+1</sub>, &hellip; x<sub>n+k</sub>: a<sub>n+k</sub>)</i>. It is a
   * static warning if <i>C</i> does not denote a class in the current scope.
   *
   * Parameters:
   * 0: the name of the undefined class
   */
  static const StaticWarningCode UNDEFINED_CLASS = const StaticWarningCode(
      'UNDEFINED_CLASS', "Undefined class '{0}'.",
      correction: "Try changing the name to the name of an existing class, or "
          "creating a class with the name '{0}'.",
      isUnresolvedIdentifier: true);

  /**
   * Same as [UNDEFINED_CLASS], but to catch using "boolean" instead of "bool".
   */
  static const StaticWarningCode UNDEFINED_CLASS_BOOLEAN =
      const StaticWarningCode(
          'UNDEFINED_CLASS_BOOLEAN', "Undefined class 'boolean'.",
          correction: "Try using the type 'bool'.");

  /**
   * 12.30 Identifier Reference: It is as static warning if an identifier
   * expression of the form <i>id</i> occurs inside a top level or static
   * function (be it function, method, getter, or setter) or variable
   * initializer and there is no declaration <i>d</i> with name <i>id</i> in the
   * lexical scope enclosing the expression.
   *
   * Parameters:
   * 0: the name of the identifier
   */
  static const StaticWarningCode UNDEFINED_IDENTIFIER =
      const StaticWarningCode('UNDEFINED_IDENTIFIER', "Undefined name '{0}'.",
          correction: "Try correcting the name to one that is defined, or "
              "defining the name.",
          isUnresolvedIdentifier: true);

  /**
   * If the identifier is 'await', be helpful about it.
   */
  static const StaticWarningCode UNDEFINED_IDENTIFIER_AWAIT =
      const StaticWarningCode('UNDEFINED_IDENTIFIER_AWAIT',
          "Undefined name 'await' in function body not marked with 'async'.",
          correction: "Try correcting the name to one that is defined, "
              "defining the name, or "
              "adding 'async' to the enclosing function body.");

  /**
   * 12.14.2 Binding Actuals to Formals: Furthermore, each <i>q<sub>i</sub></i>,
   * <i>1<=i<=l</i>, must have a corresponding named parameter in the set
   * {<i>p<sub>n+1</sub></i> &hellip; <i>p<sub>n+k</sub></i>} or a static
   * warning occurs.
   *
   * Parameters:
   * 0: the name of the requested named parameter
   */
  static const StaticWarningCode UNDEFINED_NAMED_PARAMETER =
      const StaticWarningCode('UNDEFINED_NAMED_PARAMETER',
          "The named parameter '{0}' isn't defined.",
          correction:
              "Try correcting the name to an existing named parameter, or "
              "defining a new parameter with this name.");

  /**
   * For the purposes of experimenting with potential non-null type semantics.
   *
   * Parameters: none
   */
  static const StaticWarningCode UNCHECKED_USE_OF_NULLABLE_VALUE =
      const StaticWarningCode(
          'UNCHECKED_USE_OF_NULLABLE_VALUE',
          'The expression is nullable and must be null-checked before it can be'
              ' used.',
          correction:
              'Try casting or check the value is not null before using it.');

  /**
   * It is a static warning to assign void to any non-void type in dart.
   * compile-time error). Report that error specially for a better user
   * experience.
   *
   * Parameters: none
   */
  static const StaticWarningCode USE_OF_VOID_RESULT = const StaticWarningCode(
      'USE_OF_VOID_RESULT',
      "The expression here has a type of 'void', and therefore cannot be used.",
      correction:
          'Check if you are using the correct API; there may be a function or'
          " call that returns void you didn't expect. Also check type parameters"
          ' and variables which, in rare cases, may be void as well.');

  @override
  final ErrorSeverity errorSeverity;

  /**
   * Initialize a newly created error code to have the given [name]. The message
   * associated with the error will be created from the given [message]
   * template. The correction associated with the error will be created from the
   * given [correction] template.
   */
  const StaticWarningCode(String name, String message,
      {String correction,
      this.errorSeverity: ErrorSeverity.ERROR,
      bool isUnresolvedIdentifier: false})
      : super.temporary(name, message,
            correction: correction,
            isUnresolvedIdentifier: isUnresolvedIdentifier);

  @override
  ErrorType get type => ErrorType.STATIC_WARNING;
}

/**
 * This class has Strong Mode specific error codes.
 * 
 * "Strong Mode" was the prototype for Dart 2's sound type system. Many of these
 * errors became part of Dart 2. Some of them are optional flags, used for
 * stricter checking.
 *
 * These error codes tend to use the same message across different severity
 * levels, so they are grouped for clarity.
 *
 * All of these error codes also use the "STRONG_MODE_" prefix in their name.
 */
class StrongModeCode extends ErrorCode {
  static const String _implicitCastMessage =
      "Unsafe implicit cast from '{0}' to '{1}'. "
      "This usually indicates that type information was lost and resulted in "
      "'dynamic' and/or a place that will have a failure at runtime.";

  static const String _implicitCastCorrection =
      "Try adding an explicit cast to '{1}' or improving the type of '{0}'.";

  /**
   * This is appended to the end of an error message about implicit dynamic.
   *
   * The idea is to make sure the user is aware that this error message is the
   * result of turning on a particular option, and they are free to turn it
   * back off.
   */
  static const String _implicitDynamicCorrection =
      "Try adding an explicit type like 'dynamic', or "
      "enable implicit-dynamic in your analysis options file.";

  static const String _inferredTypeMessage = "'{0}' has inferred type '{1}'.";

  static const StrongModeCode DOWN_CAST_COMPOSITE = const StrongModeCode(
      ErrorType.HINT, 'DOWN_CAST_COMPOSITE', _implicitCastMessage,
      correction: _implicitCastCorrection);

  static const StrongModeCode DOWN_CAST_IMPLICIT = const StrongModeCode(
      ErrorType.HINT, 'DOWN_CAST_IMPLICIT', _implicitCastMessage,
      correction: _implicitCastCorrection);

  static const StrongModeCode DOWN_CAST_IMPLICIT_ASSIGN = const StrongModeCode(
      ErrorType.HINT, 'DOWN_CAST_IMPLICIT_ASSIGN', _implicitCastMessage,
      correction: _implicitCastCorrection);

  static const StrongModeCode DYNAMIC_CAST = const StrongModeCode(
      ErrorType.HINT, 'DYNAMIC_CAST', _implicitCastMessage,
      correction: _implicitCastCorrection);

  static const StrongModeCode ASSIGNMENT_CAST = const StrongModeCode(
      ErrorType.HINT, 'ASSIGNMENT_CAST', _implicitCastMessage,
      correction: _implicitCastCorrection);

  static const StrongModeCode INVALID_PARAMETER_DECLARATION =
      const StrongModeCode(
          ErrorType.COMPILE_TIME_ERROR,
          'INVALID_PARAMETER_DECLARATION',
          "Type check failed: '{0}' isn't of type '{1}'.");

  static const StrongModeCode COULD_NOT_INFER = const StrongModeCode(
      ErrorType.COMPILE_TIME_ERROR,
      'COULD_NOT_INFER',
      "Couldn't infer type parameter '{0}'.{1}");

  static const StrongModeCode INFERRED_TYPE = const StrongModeCode(
      ErrorType.HINT, 'INFERRED_TYPE', _inferredTypeMessage);

  static const StrongModeCode INFERRED_TYPE_LITERAL = const StrongModeCode(
      ErrorType.HINT, 'INFERRED_TYPE_LITERAL', _inferredTypeMessage);

  static const StrongModeCode INFERRED_TYPE_ALLOCATION = const StrongModeCode(
      ErrorType.HINT, 'INFERRED_TYPE_ALLOCATION', _inferredTypeMessage);

  static const StrongModeCode INFERRED_TYPE_CLOSURE = const StrongModeCode(
      ErrorType.HINT, 'INFERRED_TYPE_CLOSURE', _inferredTypeMessage);

  static const StrongModeCode INVALID_CAST_LITERAL = const StrongModeCode(
      ErrorType.COMPILE_TIME_ERROR,
      'INVALID_CAST_LITERAL',
      "The literal '{0}' with type '{1}' isn't of expected type '{2}'.");

  static const StrongModeCode INVALID_CAST_LITERAL_LIST = const StrongModeCode(
      ErrorType.COMPILE_TIME_ERROR,
      'INVALID_CAST_LITERAL_LIST',
      "The list literal type '{0}' isn't of expected type '{1}'. The list's "
          "type can be changed with an explicit generic type argument or by "
          "changing the element types.");

  static const StrongModeCode INVALID_CAST_LITERAL_MAP = const StrongModeCode(
      ErrorType.COMPILE_TIME_ERROR,
      'INVALID_CAST_LITERAL_MAP',
      "The map literal type '{0}' isn't of expected type '{1}'. The maps's "
          "type can be changed with an explicit generic type arguments or by "
          "changing the key and value types.");

  static const StrongModeCode INVALID_CAST_LITERAL_SET = const StrongModeCode(
      ErrorType.COMPILE_TIME_ERROR,
      'INVALID_CAST_LITERAL_SET',
      "The set literal type '{0}' isn't of expected type '{1}'. The set's "
          "type can be changed with an explicit generic type argument or by "
          "changing the element types.");

  static const StrongModeCode INVALID_CAST_FUNCTION_EXPR = const StrongModeCode(
      ErrorType.COMPILE_TIME_ERROR,
      'INVALID_CAST_FUNCTION_EXPR',
      "The function expression type '{0}' isn't of type '{1}'. "
          "This means its parameter or return type does not match what is "
          "expected. Consider changing parameter type(s) or the returned type(s).");

  static const StrongModeCode INVALID_CAST_NEW_EXPR = const StrongModeCode(
      ErrorType.COMPILE_TIME_ERROR,
      'INVALID_CAST_NEW_EXPR',
      "The constructor returns type '{0}' that isn't of expected type '{1}'.");

  static const StrongModeCode INVALID_CAST_METHOD = const StrongModeCode(
      ErrorType.COMPILE_TIME_ERROR,
      'INVALID_CAST_METHOD',
      "The method tear-off '{0}' has type '{1}' that isn't of expected type "
          "'{2}'. This means its parameter or return type does not match what is "
          "expected.");

  static const StrongModeCode INVALID_CAST_FUNCTION = const StrongModeCode(
      ErrorType.COMPILE_TIME_ERROR,
      'INVALID_CAST_FUNCTION',
      "The function '{0}' has type '{1}' that isn't of expected type "
          "'{2}'. This means its parameter or return type does not match what is "
          "expected.");

  static const StrongModeCode INVALID_SUPER_INVOCATION = const StrongModeCode(
      ErrorType.COMPILE_TIME_ERROR,
      'INVALID_SUPER_INVOCATION',
      "super call must be last in an initializer "
          "list (see https://goo.gl/EY6hDP): '{0}'.");

  static const StrongModeCode NON_GROUND_TYPE_CHECK_INFO = const StrongModeCode(
      ErrorType.HINT,
      'NON_GROUND_TYPE_CHECK_INFO',
      "Runtime check on non-ground type '{0}' may throw StrongModeError.");

  static const StrongModeCode DYNAMIC_INVOKE = const StrongModeCode(
      ErrorType.HINT, 'DYNAMIC_INVOKE', "'{0}' requires a dynamic invoke.");

  static const StrongModeCode IMPLICIT_DYNAMIC_PARAMETER = const StrongModeCode(
      ErrorType.COMPILE_TIME_ERROR,
      'IMPLICIT_DYNAMIC_PARAMETER',
      "Missing parameter type for '{0}'.",
      correction: _implicitDynamicCorrection);

  static const StrongModeCode IMPLICIT_DYNAMIC_RETURN = const StrongModeCode(
      ErrorType.COMPILE_TIME_ERROR,
      'IMPLICIT_DYNAMIC_RETURN',
      "Missing return type for '{0}'.",
      correction: _implicitDynamicCorrection);

  static const StrongModeCode IMPLICIT_DYNAMIC_VARIABLE = const StrongModeCode(
      ErrorType.COMPILE_TIME_ERROR,
      'IMPLICIT_DYNAMIC_VARIABLE',
      "Missing variable type for '{0}'.",
      correction: _implicitDynamicCorrection);

  static const StrongModeCode IMPLICIT_DYNAMIC_FIELD = const StrongModeCode(
      ErrorType.COMPILE_TIME_ERROR,
      'IMPLICIT_DYNAMIC_FIELD',
      "Missing field type for '{0}'.",
      correction: _implicitDynamicCorrection);

  static const StrongModeCode IMPLICIT_DYNAMIC_TYPE = const StrongModeCode(
      ErrorType.COMPILE_TIME_ERROR,
      'IMPLICIT_DYNAMIC_TYPE',
      "Missing type arguments for generic type '{0}'.",
      correction: _implicitDynamicCorrection);

  static const StrongModeCode IMPLICIT_DYNAMIC_LIST_LITERAL =
      const StrongModeCode(
          ErrorType.COMPILE_TIME_ERROR,
          'IMPLICIT_DYNAMIC_LIST_LITERAL',
          "Missing type argument for list literal.",
          correction: _implicitDynamicCorrection);

  static const StrongModeCode IMPLICIT_DYNAMIC_MAP_LITERAL =
      const StrongModeCode(
          ErrorType.COMPILE_TIME_ERROR,
          'IMPLICIT_DYNAMIC_MAP_LITERAL',
          "Missing type arguments for map literal.",
          correction: _implicitDynamicCorrection);

  static const StrongModeCode IMPLICIT_DYNAMIC_FUNCTION = const StrongModeCode(
      ErrorType.COMPILE_TIME_ERROR,
      'IMPLICIT_DYNAMIC_FUNCTION',
      "Missing type arguments for generic function '{0}<{1}>'.",
      correction: _implicitDynamicCorrection);

  static const StrongModeCode IMPLICIT_DYNAMIC_METHOD = const StrongModeCode(
      ErrorType.COMPILE_TIME_ERROR,
      'IMPLICIT_DYNAMIC_METHOD',
      "Missing type arguments for generic method '{0}<{1}>'.",
      correction: _implicitDynamicCorrection);

  static const StrongModeCode IMPLICIT_DYNAMIC_INVOKE = const StrongModeCode(
      ErrorType.COMPILE_TIME_ERROR,
      'IMPLICIT_DYNAMIC_INVOKE',
      "Missing type arguments for calling generic function type '{0}'.",
      correction: _implicitDynamicCorrection);

  static const StrongModeCode NOT_INSTANTIATED_BOUND = const StrongModeCode(
      ErrorType.COMPILE_TIME_ERROR,
      'NOT_INSTANTIATED_BOUND',
      "Type parameter bound types must be instantiated.",
      correction: "Try adding type arguments.");

  /*
   * TODO(brianwilkerson) Make the TOP_LEVEL_ error codes be errors rather than
   * hints and then clean up the function _errorSeverity in
   * test/src/task/strong/strong_test_helper.dart.
   */
  /* TODO(leafp) Delete most of these.
   */
  static const StrongModeCode TOP_LEVEL_CYCLE = const StrongModeCode(
      ErrorType.COMPILE_TIME_ERROR,
      'TOP_LEVEL_CYCLE',
      "The type of '{0}' can't be inferred because it depends on itself through the cycle: {1}.",
      correction:
          "Try adding an explicit type to one or more of the variables in the cycle in order to break the cycle.");

  static const StrongModeCode TOP_LEVEL_FUNCTION_LITERAL_BLOCK =
      const StrongModeCode(ErrorType.HINT, 'TOP_LEVEL_FUNCTION_LITERAL_BLOCK',
          "The type of the function literal can't be inferred because the literal has a block as its body.",
          correction: "Try adding an explicit type to the variable.");

  static const StrongModeCode TOP_LEVEL_IDENTIFIER_NO_TYPE = const StrongModeCode(
      ErrorType.HINT,
      'TOP_LEVEL_IDENTIFIER_NO_TYPE',
      "The type of '{0}' can't be inferred because the type of '{1}' couldn't be inferred.",
      correction:
          "Try adding an explicit type to either the variable '{0}' or the variable '{1}'.");

  static const StrongModeCode TOP_LEVEL_INSTANCE_GETTER = const StrongModeCode(
      ErrorType.STATIC_WARNING,
      'TOP_LEVEL_INSTANCE_GETTER',
      "The type of '{0}' can't be inferred because it refers to an instance "
          "getter, '{1}', which has an implicit type.",
      correction: "Add an explicit type for either '{0}' or '{1}'.");

  static const StrongModeCode TOP_LEVEL_INSTANCE_METHOD = const StrongModeCode(
      ErrorType.STATIC_WARNING,
      'TOP_LEVEL_INSTANCE_METHOD',
      "The type of '{0}' can't be inferred because it refers to an instance "
          "method, '{1}', which has an implicit type.",
      correction: "Add an explicit type for either '{0}' or '{1}'.");

  @override
  final ErrorType type;

  /**
   * Initialize a newly created error code to have the given [type] and [name].
   *
   * The message associated with the error will be created from the given
   * [message] template. The correction associated with the error will be
   * created from the optional [correction] template.
   */
  const StrongModeCode(ErrorType type, String name, String message,
      {String correction})
      : type = type,
        super.temporary('STRONG_MODE_$name', message, correction: correction);

  @override
  ErrorSeverity get errorSeverity => type.severity;
}
