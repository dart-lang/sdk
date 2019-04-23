//
// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/front_end/messages.yaml' and run
// 'dart pkg/analyzer/tool/messages/generate.dart' to update.

part of 'syntactic_errors.dart';

final fastaAnalyzerErrorCodes = <ErrorCode>[
  null,
  _EQUALITY_CANNOT_BE_EQUALITY_OPERAND,
  _CONTINUE_OUTSIDE_OF_LOOP,
  _EXTERNAL_CLASS,
  _STATIC_CONSTRUCTOR,
  _EXTERNAL_ENUM,
  _PREFIX_AFTER_COMBINATOR,
  _TYPEDEF_IN_CLASS,
  _COVARIANT_AFTER_VAR,
  _INVALID_AWAIT_IN_FOR,
  _IMPORT_DIRECTIVE_AFTER_PART_DIRECTIVE,
  _WITH_BEFORE_EXTENDS,
  _VAR_RETURN_TYPE,
  _TYPE_ARGUMENTS_ON_TYPE_VARIABLE,
  _TOP_LEVEL_OPERATOR,
  _SWITCH_HAS_MULTIPLE_DEFAULT_CASES,
  _SWITCH_HAS_CASE_AFTER_DEFAULT_CASE,
  _STATIC_OPERATOR,
  _STATIC_AFTER_VAR,
  _STATIC_AFTER_FINAL,
  _STATIC_AFTER_CONST,
  _REDIRECTION_IN_NON_FACTORY_CONSTRUCTOR,
  _REDIRECTING_CONSTRUCTOR_WITH_BODY,
  _NATIVE_CLAUSE_SHOULD_BE_ANNOTATION,
  _MULTIPLE_WITH_CLAUSES,
  _MULTIPLE_PART_OF_DIRECTIVES,
  _MULTIPLE_ON_CLAUSES,
  _MULTIPLE_LIBRARY_DIRECTIVES,
  _MULTIPLE_EXTENDS_CLAUSES,
  _MISSING_STATEMENT,
  _MISSING_PREFIX_IN_DEFERRED_IMPORT,
  _MISSING_KEYWORD_OPERATOR,
  _MISSING_EXPRESSION_IN_THROW,
  _MISSING_CONST_FINAL_VAR_OR_TYPE,
  _MISSING_ASSIGNMENT_IN_INITIALIZER,
  _MISSING_ASSIGNABLE_SELECTOR,
  _MISSING_INITIALIZER,
  _LIBRARY_DIRECTIVE_NOT_FIRST,
  _INVALID_UNICODE_ESCAPE,
  _INVALID_OPERATOR,
  _INVALID_HEX_ESCAPE,
  _EXPECTED_INSTEAD,
  _IMPLEMENTS_BEFORE_WITH,
  _IMPLEMENTS_BEFORE_ON,
  _IMPLEMENTS_BEFORE_EXTENDS,
  _ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE,
  _EXTERNAL_AFTER_CONST,
  _EXTERNAL_AFTER_FACTORY,
  _EXTERNAL_AFTER_STATIC,
  _EXTERNAL_METHOD_WITH_BODY,
  _EXTERNAL_FIELD,
  _ABSTRACT_CLASS_MEMBER,
  _BREAK_OUTSIDE_OF_LOOP,
  _CLASS_IN_CLASS,
  _COLON_IN_PLACE_OF_IN,
  _CONSTRUCTOR_WITH_RETURN_TYPE,
  _MODIFIER_OUT_OF_ORDER,
  _TYPE_BEFORE_FACTORY,
  _CONST_AND_FINAL,
  _CONFLICTING_MODIFIERS,
  _CONST_CLASS,
  _VAR_AS_TYPE_NAME,
  _CONST_FACTORY,
  _CONST_METHOD,
  _CONTINUE_WITHOUT_LABEL_IN_CASE,
  _INVALID_THIS_IN_INITIALIZER,
  _COVARIANT_AND_STATIC,
  _COVARIANT_MEMBER,
  _DEFERRED_AFTER_PREFIX,
  _DIRECTIVE_AFTER_DECLARATION,
  _DUPLICATED_MODIFIER,
  _DUPLICATE_DEFERRED,
  _DUPLICATE_LABEL_IN_SWITCH_STATEMENT,
  _DUPLICATE_PREFIX,
  _ENUM_IN_CLASS,
  _EXPORT_DIRECTIVE_AFTER_PART_DIRECTIVE,
  _EXTERNAL_TYPEDEF,
  _EXTRANEOUS_MODIFIER,
  _FACTORY_TOP_LEVEL_DECLARATION,
  _FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR,
  _FINAL_AND_COVARIANT,
  _FINAL_AND_VAR,
  _INITIALIZED_VARIABLE_IN_FOR_EACH,
  _CATCH_SYNTAX_EXTRA_PARAMETERS,
  _CATCH_SYNTAX,
  _EXTERNAL_FACTORY_REDIRECTION,
  _EXTERNAL_FACTORY_WITH_BODY,
  _EXTERNAL_CONSTRUCTOR_WITH_BODY,
  _FIELD_INITIALIZED_OUTSIDE_DECLARING_CLASS,
  _VAR_AND_TYPE,
  _INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER,
  _STACK_OVERFLOW,
  _MISSING_CATCH_OR_FINALLY,
  _EXPERIMENT_NOT_ENABLED,
  _EXPECTED_ELSE_OR_COMMA,
  _INVALID_SUPER_IN_INITIALIZER,
];

const ParserErrorCode _ABSTRACT_CLASS_MEMBER = const ParserErrorCode(
    'ABSTRACT_CLASS_MEMBER',
    r"Members of classes can't be declared to be 'abstract'.",
    correction:
        "Try removing the 'abstract' keyword. You can add the 'abstract' keyword before the class declaration.");

const ParserErrorCode _BREAK_OUTSIDE_OF_LOOP = const ParserErrorCode(
    'BREAK_OUTSIDE_OF_LOOP',
    r"A break statement can't be used outside of a loop or switch statement.",
    correction: "Try removing the break statement.");

const ParserErrorCode _CATCH_SYNTAX = const ParserErrorCode('CATCH_SYNTAX',
    r"'catch' must be followed by '(identifier)' or '(identifier, identifier)'.",
    correction:
        "No types are needed, the first is given by 'on', the second is always 'StackTrace'.");

const ParserErrorCode _CATCH_SYNTAX_EXTRA_PARAMETERS = const ParserErrorCode(
    'CATCH_SYNTAX_EXTRA_PARAMETERS',
    r"'catch' must be followed by '(identifier)' or '(identifier, identifier)'.",
    correction:
        "No types are needed, the first is given by 'on', the second is always 'StackTrace'.");

const ParserErrorCode _CLASS_IN_CLASS = const ParserErrorCode(
    'CLASS_IN_CLASS', r"Classes can't be declared inside other classes.",
    correction: "Try moving the class to the top-level.");

const ParserErrorCode _COLON_IN_PLACE_OF_IN = const ParserErrorCode(
    'COLON_IN_PLACE_OF_IN', r"For-in loops use 'in' rather than a colon.",
    correction: "Try replacing the colon with the keyword 'in'.");

const ParserErrorCode _CONFLICTING_MODIFIERS = const ParserErrorCode(
    'CONFLICTING_MODIFIERS',
    r"Members can't be declared to be both '#string' and '#string2'.",
    correction: "Try removing one of the keywords.");

const ParserErrorCode _CONSTRUCTOR_WITH_RETURN_TYPE = const ParserErrorCode(
    'CONSTRUCTOR_WITH_RETURN_TYPE', r"Constructors can't have a return type.",
    correction: "Try removing the return type.");

const ParserErrorCode _CONST_AND_FINAL = const ParserErrorCode(
    'CONST_AND_FINAL',
    r"Members can't be declared to be both 'const' and 'final'.",
    correction: "Try removing either the 'const' or 'final' keyword.");

const ParserErrorCode _CONST_CLASS = const ParserErrorCode(
    'CONST_CLASS', r"Classes can't be declared to be 'const'.",
    correction:
        "Try removing the 'const' keyword. If you're trying to indicate that instances of the class can be constants, place the 'const' keyword on  the class' constructor(s).");

const ParserErrorCode _CONST_FACTORY = const ParserErrorCode('CONST_FACTORY',
    r"Only redirecting factory constructors can be declared to be 'const'.",
    correction:
        "Try removing the 'const' keyword, or replacing the body with '=' followed by a valid target.");

const ParserErrorCode _CONST_METHOD = const ParserErrorCode('CONST_METHOD',
    r"Getters, setters and methods can't be declared to be 'const'.",
    correction: "Try removing the 'const' keyword.");

const ParserErrorCode _CONTINUE_OUTSIDE_OF_LOOP = const ParserErrorCode(
    'CONTINUE_OUTSIDE_OF_LOOP',
    r"A continue statement can't be used outside of a loop or switch statement.",
    correction: "Try removing the continue statement.");

const ParserErrorCode _CONTINUE_WITHOUT_LABEL_IN_CASE = const ParserErrorCode(
    'CONTINUE_WITHOUT_LABEL_IN_CASE',
    r"A continue statement in a switch statement must have a label as a target.",
    correction:
        "Try adding a label associated with one of the case clauses to the continue statement.");

const ParserErrorCode _COVARIANT_AFTER_VAR = const ParserErrorCode(
    'COVARIANT_AFTER_VAR',
    r"The modifier 'covariant' should be before the modifier 'var'.",
    correction: "Try re-ordering the modifiers.");

const ParserErrorCode _COVARIANT_AND_STATIC = const ParserErrorCode(
    'COVARIANT_AND_STATIC',
    r"Members can't be declared to be both 'covariant' and 'static'.",
    correction: "Try removing either the 'covariant' or 'static' keyword.");

const ParserErrorCode _COVARIANT_MEMBER = const ParserErrorCode(
    'COVARIANT_MEMBER',
    r"Getters, setters and methods can't be declared to be 'covariant'.",
    correction: "Try removing the 'covariant' keyword.");

const ParserErrorCode _DEFERRED_AFTER_PREFIX = const ParserErrorCode(
    'DEFERRED_AFTER_PREFIX',
    r"The deferred keyword should come immediately before the prefix ('as' clause).",
    correction: "Try moving the deferred keyword before the prefix.");

const ParserErrorCode _DIRECTIVE_AFTER_DECLARATION = const ParserErrorCode(
    'DIRECTIVE_AFTER_DECLARATION',
    r"Directives must appear before any declarations.",
    correction: "Try moving the directive before any declarations.");

const ParserErrorCode _DUPLICATED_MODIFIER = const ParserErrorCode(
    'DUPLICATED_MODIFIER', r"The modifier '#lexeme' was already specified.",
    correction: "Try removing all but one occurence of the modifier.");

const ParserErrorCode _DUPLICATE_DEFERRED = const ParserErrorCode(
    'DUPLICATE_DEFERRED',
    r"An import directive can only have one 'deferred' keyword.",
    correction: "Try removing all but one 'deferred' keyword.");

const ParserErrorCode _DUPLICATE_LABEL_IN_SWITCH_STATEMENT =
    const ParserErrorCode('DUPLICATE_LABEL_IN_SWITCH_STATEMENT',
        r"The label '#name' was already used in this switch statement.",
        correction: "Try choosing a different name for this label.");

const ParserErrorCode _DUPLICATE_PREFIX = const ParserErrorCode(
    'DUPLICATE_PREFIX',
    r"An import directive can only have one prefix ('as' clause).",
    correction: "Try removing all but one prefix.");

const ParserErrorCode _ENUM_IN_CLASS = const ParserErrorCode(
    'ENUM_IN_CLASS', r"Enums can't be declared inside classes.",
    correction: "Try moving the enum to the top-level.");

const ParserErrorCode _EQUALITY_CANNOT_BE_EQUALITY_OPERAND = const ParserErrorCode(
    'EQUALITY_CANNOT_BE_EQUALITY_OPERAND',
    r"An equality expression can't be an operand of another equality expression.",
    correction: "Try re-writing the expression.");

const ParserErrorCode _EXPECTED_ELSE_OR_COMMA = const ParserErrorCode(
    'EXPECTED_ELSE_OR_COMMA', r"Expected 'else' or comma.");

const ParserErrorCode _EXPECTED_INSTEAD = const ParserErrorCode(
    'EXPECTED_INSTEAD', r"Expected '#string' instead of this.");

const ParserErrorCode _EXPERIMENT_NOT_ENABLED = const ParserErrorCode(
    'EXPERIMENT_NOT_ENABLED',
    r"This requires the '#string' experiment to be enabled.",
    correction:
        "Try enabling this experiment by adding it to the command line when compiling and running.");

const ParserErrorCode _EXPORT_DIRECTIVE_AFTER_PART_DIRECTIVE =
    const ParserErrorCode('EXPORT_DIRECTIVE_AFTER_PART_DIRECTIVE',
        r"Export directives must precede part directives.",
        correction:
            "Try moving the export directives before the part directives.");

const ParserErrorCode _EXTERNAL_AFTER_CONST = const ParserErrorCode(
    'EXTERNAL_AFTER_CONST',
    r"The modifier 'external' should be before the modifier 'const'.",
    correction: "Try re-ordering the modifiers.");

const ParserErrorCode _EXTERNAL_AFTER_FACTORY = const ParserErrorCode(
    'EXTERNAL_AFTER_FACTORY',
    r"The modifier 'external' should be before the modifier 'factory'.",
    correction: "Try re-ordering the modifiers.");

const ParserErrorCode _EXTERNAL_AFTER_STATIC = const ParserErrorCode(
    'EXTERNAL_AFTER_STATIC',
    r"The modifier 'external' should be before the modifier 'static'.",
    correction: "Try re-ordering the modifiers.");

const ParserErrorCode _EXTERNAL_CLASS = const ParserErrorCode(
    'EXTERNAL_CLASS', r"Classes can't be declared to be 'external'.",
    correction: "Try removing the keyword 'external'.");

const ParserErrorCode _EXTERNAL_CONSTRUCTOR_WITH_BODY = const ParserErrorCode(
    'EXTERNAL_CONSTRUCTOR_WITH_BODY',
    r"External constructors can't have a body.",
    correction:
        "Try removing the body of the constructor, or removing the keyword 'external'.");

const ParserErrorCode _EXTERNAL_ENUM = const ParserErrorCode(
    'EXTERNAL_ENUM', r"Enums can't be declared to be 'external'.",
    correction: "Try removing the keyword 'external'.");

const ParserErrorCode _EXTERNAL_FACTORY_REDIRECTION = const ParserErrorCode(
    'EXTERNAL_FACTORY_REDIRECTION', r"A redirecting factory can't be external.",
    correction: "Try removing the 'external' modifier.");

const ParserErrorCode _EXTERNAL_FACTORY_WITH_BODY = const ParserErrorCode(
    'EXTERNAL_FACTORY_WITH_BODY', r"External factories can't have a body.",
    correction:
        "Try removing the body of the factory, or removing the keyword 'external'.");

const ParserErrorCode _EXTERNAL_FIELD = const ParserErrorCode(
    'EXTERNAL_FIELD', r"Fields can't be declared to be 'external'.",
    correction: "Try removing the keyword 'external'.");

const ParserErrorCode _EXTERNAL_METHOD_WITH_BODY = const ParserErrorCode(
    'EXTERNAL_METHOD_WITH_BODY',
    r"An external or native method can't have a body.");

const ParserErrorCode _EXTERNAL_TYPEDEF = const ParserErrorCode(
    'EXTERNAL_TYPEDEF', r"Typedefs can't be declared to be 'external'.",
    correction: "Try removing the keyword 'external'.");

const ParserErrorCode _EXTRANEOUS_MODIFIER = const ParserErrorCode(
    'EXTRANEOUS_MODIFIER', r"Can't have modifier '#lexeme' here.",
    correction: "Try removing '#lexeme'.");

const ParserErrorCode _FACTORY_TOP_LEVEL_DECLARATION = const ParserErrorCode(
    'FACTORY_TOP_LEVEL_DECLARATION',
    r"Top-level declarations can't be declared to be 'factory'.",
    correction: "Try removing the keyword 'factory'.");

const ParserErrorCode _FIELD_INITIALIZED_OUTSIDE_DECLARING_CLASS =
    const ParserErrorCode('FIELD_INITIALIZED_OUTSIDE_DECLARING_CLASS',
        r"A field can only be initialized in it's declaring class",
        correction:
            "Try passing a value into the superclass constructor, or moving the initialization into the constructor body.");

const ParserErrorCode _FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR =
    const ParserErrorCode('FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR',
        r"Field formal parameters can only be used in a constructor.",
        correction: "Try removing 'this.'.");

const ParserErrorCode _FINAL_AND_COVARIANT = const ParserErrorCode(
    'FINAL_AND_COVARIANT',
    r"Members can't be declared to be both 'final' and 'covariant'.",
    correction: "Try removing either the 'final' or 'covariant' keyword.");

const ParserErrorCode _FINAL_AND_VAR = const ParserErrorCode(
    'FINAL_AND_VAR', r"Members can't be declared to be both 'final' and 'var'.",
    correction: "Try removing the keyword 'var'.");

const ParserErrorCode _ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE =
    const ParserErrorCode('ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE',
        r"Illegal assignment to non-assignable expression.");

const ParserErrorCode _IMPLEMENTS_BEFORE_EXTENDS = const ParserErrorCode(
    'IMPLEMENTS_BEFORE_EXTENDS',
    r"The extends clause must be before the implements clause.",
    correction: "Try moving the extends clause before the implements clause.");

const ParserErrorCode _IMPLEMENTS_BEFORE_ON = const ParserErrorCode(
    'IMPLEMENTS_BEFORE_ON',
    r"The on clause must be before the implements clause.",
    correction: "Try moving the on clause before the implements clause.");

const ParserErrorCode _IMPLEMENTS_BEFORE_WITH = const ParserErrorCode(
    'IMPLEMENTS_BEFORE_WITH',
    r"The with clause must be before the implements clause.",
    correction: "Try moving the with clause before the implements clause.");

const ParserErrorCode _IMPORT_DIRECTIVE_AFTER_PART_DIRECTIVE =
    const ParserErrorCode('IMPORT_DIRECTIVE_AFTER_PART_DIRECTIVE',
        r"Import directives must precede part directives.",
        correction:
            "Try moving the import directives before the part directives.");

const ParserErrorCode _INITIALIZED_VARIABLE_IN_FOR_EACH = const ParserErrorCode(
    'INITIALIZED_VARIABLE_IN_FOR_EACH',
    r"The loop variable in a for-each loop can't be initialized.",
    correction:
        "Try removing the initializer, or using a different kind of loop.");

const ParserErrorCode _INVALID_AWAIT_IN_FOR = const ParserErrorCode(
    'INVALID_AWAIT_IN_FOR',
    r"The keyword 'await' isn't allowed for a normal 'for' statement.",
    correction: "Try removing the keyword, or use a for-each statement.");

const ParserErrorCode _INVALID_HEX_ESCAPE = const ParserErrorCode(
    'INVALID_HEX_ESCAPE',
    r"An escape sequence starting with '\x' must be followed by 2 hexadecimal digits.");

const ParserErrorCode _INVALID_OPERATOR = const ParserErrorCode(
    'INVALID_OPERATOR',
    r"The string '#lexeme' isn't a user-definable operator.");

const ParserErrorCode _INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER =
    const ParserErrorCode('INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER',
        r"The operator '?.' cannot be used with 'super' because 'super' cannot be null.",
        correction: "Try replacing '?.' with '.'");

const ParserErrorCode _INVALID_SUPER_IN_INITIALIZER = const ParserErrorCode(
    'INVALID_SUPER_IN_INITIALIZER',
    r"Can only use 'super' in an initializer for calling the superclass constructor (e.g. 'super()' or 'super.namedConstructor()')");

const ParserErrorCode _INVALID_THIS_IN_INITIALIZER = const ParserErrorCode(
    'INVALID_THIS_IN_INITIALIZER',
    r"Can only use 'this' in an initializer for field initialization (e.g. 'this.x = something') and constructor redirection (e.g. 'this()' or 'this.namedConstructor())");

const ParserErrorCode _INVALID_UNICODE_ESCAPE = const ParserErrorCode(
    'INVALID_UNICODE_ESCAPE',
    r"An escape sequence starting with '\u' must be followed by 4 hexadecimal digits or from 1 to 6 digits between '{' and '}'.");

const ParserErrorCode _LIBRARY_DIRECTIVE_NOT_FIRST = const ParserErrorCode(
    'LIBRARY_DIRECTIVE_NOT_FIRST',
    r"The library directive must appear before all other directives.",
    correction:
        "Try moving the library directive before any other directives.");

const ParserErrorCode _MISSING_ASSIGNABLE_SELECTOR = const ParserErrorCode(
    'MISSING_ASSIGNABLE_SELECTOR',
    r"Missing selector such as '.<identifier>' or '[0]'.",
    correction: "Try adding a selector.");

const ParserErrorCode _MISSING_ASSIGNMENT_IN_INITIALIZER =
    const ParserErrorCode('MISSING_ASSIGNMENT_IN_INITIALIZER',
        r"Expected an assignment after the field name.",
        correction: "To initialize a field, use the syntax 'name = value'.");

const ParserErrorCode _MISSING_CATCH_OR_FINALLY = const ParserErrorCode(
    'MISSING_CATCH_OR_FINALLY',
    r"A try block must be followed by an 'on', 'catch', or 'finally' clause.",
    correction:
        "Try adding either a catch or finally clause, or remove the try statement.");

const ParserErrorCode _MISSING_CONST_FINAL_VAR_OR_TYPE = const ParserErrorCode(
    'MISSING_CONST_FINAL_VAR_OR_TYPE',
    r"Variables must be declared using the keywords 'const', 'final', 'var' or a type name.",
    correction:
        "Try adding the name of the type of the variable or the keyword 'var'.");

const ParserErrorCode _MISSING_EXPRESSION_IN_THROW = const ParserErrorCode(
    'MISSING_EXPRESSION_IN_THROW', r"Missing expression after 'throw'.",
    correction:
        "Add an expression after 'throw' or use 'rethrow' to throw a caught exception");

const ParserErrorCode _MISSING_INITIALIZER =
    const ParserErrorCode('MISSING_INITIALIZER', r"Expected an initializer.");

const ParserErrorCode _MISSING_KEYWORD_OPERATOR = const ParserErrorCode(
    'MISSING_KEYWORD_OPERATOR',
    r"Operator declarations must be preceded by the keyword 'operator'.",
    correction: "Try adding the keyword 'operator'.");

const ParserErrorCode _MISSING_PREFIX_IN_DEFERRED_IMPORT =
    const ParserErrorCode('MISSING_PREFIX_IN_DEFERRED_IMPORT',
        r"Deferred imports should have a prefix.",
        correction: "Try adding a prefix to the import.");

const ParserErrorCode _MISSING_STATEMENT =
    const ParserErrorCode('MISSING_STATEMENT', r"Expected a statement.");

const ParserErrorCode _MODIFIER_OUT_OF_ORDER = const ParserErrorCode(
    'MODIFIER_OUT_OF_ORDER',
    r"The modifier '#string' should be before the modifier '#string2'.",
    correction: "Try re-ordering the modifiers.");

const ParserErrorCode _MULTIPLE_EXTENDS_CLAUSES = const ParserErrorCode(
    'MULTIPLE_EXTENDS_CLAUSES',
    r"Each class definition can have at most one extends clause.",
    correction:
        "Try choosing one superclass and define your class to implement (or mix in) the others.");

const ParserErrorCode _MULTIPLE_LIBRARY_DIRECTIVES = const ParserErrorCode(
    'MULTIPLE_LIBRARY_DIRECTIVES',
    r"Only one library directive may be declared in a file.",
    correction: "Try removing all but one of the library directives.");

const ParserErrorCode _MULTIPLE_ON_CLAUSES = const ParserErrorCode(
    'MULTIPLE_ON_CLAUSES',
    r"Each mixin definition can have at most one on clause.",
    correction: "Try combining all of the on clauses into a single clause.");

const ParserErrorCode _MULTIPLE_PART_OF_DIRECTIVES = const ParserErrorCode(
    'MULTIPLE_PART_OF_DIRECTIVES',
    r"Only one part-of directive may be declared in a file.",
    correction: "Try removing all but one of the part-of directives.");

const ParserErrorCode _MULTIPLE_WITH_CLAUSES = const ParserErrorCode(
    'MULTIPLE_WITH_CLAUSES',
    r"Each class definition can have at most one with clause.",
    correction: "Try combining all of the with clauses into a single clause.");

const ParserErrorCode _NATIVE_CLAUSE_SHOULD_BE_ANNOTATION = const ParserErrorCode(
    'NATIVE_CLAUSE_SHOULD_BE_ANNOTATION',
    r"Native clause in this form is deprecated.",
    correction:
        "Try removing this native clause and adding @native() or @native('native-name') before the declaration.");

const ParserErrorCode _PREFIX_AFTER_COMBINATOR = const ParserErrorCode(
    'PREFIX_AFTER_COMBINATOR',
    r"The prefix ('as' clause) should come before any show/hide combinators.",
    correction: "Try moving the prefix before the combinators.");

const ParserErrorCode _REDIRECTING_CONSTRUCTOR_WITH_BODY = const ParserErrorCode(
    'REDIRECTING_CONSTRUCTOR_WITH_BODY',
    r"Redirecting constructors can't have a body.",
    correction:
        "Try removing the body, or not making this a redirecting constructor.");

const ParserErrorCode _REDIRECTION_IN_NON_FACTORY_CONSTRUCTOR =
    const ParserErrorCode('REDIRECTION_IN_NON_FACTORY_CONSTRUCTOR',
        r"Only factory constructor can specify '=' redirection.",
        correction:
            "Try making this a factory constructor, or remove the redirection.");

const ParserErrorCode _STACK_OVERFLOW = const ParserErrorCode('STACK_OVERFLOW',
    r"The file has too many nested expressions or statements.",
    correction: "Try simplifying the code.");

const ParserErrorCode _STATIC_AFTER_CONST = const ParserErrorCode(
    'STATIC_AFTER_CONST',
    r"The modifier 'static' should be before the modifier 'const'.",
    correction: "Try re-ordering the modifiers.");

const ParserErrorCode _STATIC_AFTER_FINAL = const ParserErrorCode(
    'STATIC_AFTER_FINAL',
    r"The modifier 'static' should be before the modifier 'final'.",
    correction: "Try re-ordering the modifiers.");

const ParserErrorCode _STATIC_AFTER_VAR = const ParserErrorCode(
    'STATIC_AFTER_VAR',
    r"The modifier 'static' should be before the modifier 'var'.",
    correction: "Try re-ordering the modifiers.");

const ParserErrorCode _STATIC_CONSTRUCTOR = const ParserErrorCode(
    'STATIC_CONSTRUCTOR', r"Constructors can't be static.",
    correction: "Try removing the keyword 'static'.");

const ParserErrorCode _STATIC_OPERATOR = const ParserErrorCode(
    'STATIC_OPERATOR', r"Operators can't be static.",
    correction: "Try removing the keyword 'static'.");

const ParserErrorCode _SWITCH_HAS_CASE_AFTER_DEFAULT_CASE =
    const ParserErrorCode('SWITCH_HAS_CASE_AFTER_DEFAULT_CASE',
        r"The default case should be the last case in a switch statement.",
        correction:
            "Try moving the default case after the other case clauses.");

const ParserErrorCode _SWITCH_HAS_MULTIPLE_DEFAULT_CASES =
    const ParserErrorCode('SWITCH_HAS_MULTIPLE_DEFAULT_CASES',
        r"The 'default' case can only be declared once.",
        correction: "Try removing all but one default case.");

const ParserErrorCode _TOP_LEVEL_OPERATOR = const ParserErrorCode(
    'TOP_LEVEL_OPERATOR', r"Operators must be declared within a class.",
    correction:
        "Try removing the operator, moving it to a class, or converting it to be a function.");

const ParserErrorCode _TYPEDEF_IN_CLASS = const ParserErrorCode(
    'TYPEDEF_IN_CLASS', r"Typedefs can't be declared inside classes.",
    correction: "Try moving the typedef to the top-level.");

const ParserErrorCode _TYPE_ARGUMENTS_ON_TYPE_VARIABLE = const ParserErrorCode(
    'TYPE_ARGUMENTS_ON_TYPE_VARIABLE',
    r"Can't use type arguments with type variable '#name'.",
    correction: "Try removing the type arguments.");

const ParserErrorCode _TYPE_BEFORE_FACTORY = const ParserErrorCode(
    'TYPE_BEFORE_FACTORY', r"Factory constructors cannot have a return type.",
    correction: "Try removing the type appearing before 'factory'.");

const ParserErrorCode _VAR_AND_TYPE = const ParserErrorCode('VAR_AND_TYPE',
    r"Variables can't be declared using both 'var' and a type name.",
    correction: "Try removing 'var.'");

const ParserErrorCode _VAR_AS_TYPE_NAME = const ParserErrorCode(
    'VAR_AS_TYPE_NAME', r"The keyword 'var' can't be used as a type name.");

const ParserErrorCode _VAR_RETURN_TYPE = const ParserErrorCode(
    'VAR_RETURN_TYPE', r"The return type can't be 'var'.",
    correction:
        "Try removing the keyword 'var', or replacing it with the name of the return type.");

const ParserErrorCode _WITH_BEFORE_EXTENDS = const ParserErrorCode(
    'WITH_BEFORE_EXTENDS',
    r"The extends clause must be before the with clause.",
    correction: "Try moving the extends clause before the with clause.");
