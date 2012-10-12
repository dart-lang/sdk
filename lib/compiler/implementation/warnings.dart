// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class MessageKind {
  final String template;
  const MessageKind(this.template);

  static const GENERIC = const MessageKind('#{1}');

  static const NOT_ASSIGNABLE = const MessageKind(
      '#{2} is not assignable to #{1}');
  static const VOID_EXPRESSION = const MessageKind(
      'expression does not yield a value');
  static const VOID_VARIABLE = const MessageKind(
      'variable cannot be of type void');
  static const RETURN_VALUE_IN_VOID = const MessageKind(
      'cannot return value from void function');
  static const RETURN_NOTHING = const MessageKind(
      'value of type #{1} expected');
  static const MISSING_ARGUMENT = const MessageKind(
      'missing argument of type #{1}');
  static const ADDITIONAL_ARGUMENT = const MessageKind(
      'additional argument');
  static const METHOD_NOT_FOUND = const MessageKind(
      'no method named #{2} in class #{1}');
  static const MEMBER_NOT_STATIC = const MessageKind(
      '#{1}.#{2} is not static');
  static const NO_INSTANCE_AVAILABLE = const MessageKind(
      '#{1} is only available in instance methods');

  static const UNREACHABLE_CODE = const MessageKind(
      'unreachable code');
  static const MISSING_RETURN = const MessageKind(
      'missing return');
  static const MAYBE_MISSING_RETURN = const MessageKind(
      'not all paths lead to a return or throw statement');

  static const CANNOT_RESOLVE = const MessageKind(
      'cannot resolve #{1}');
  static const CANNOT_RESOLVE_CONSTRUCTOR = const MessageKind(
      'cannot resolve constructor #{1}');
  static const CANNOT_RESOLVE_CONSTRUCTOR_FOR_IMPLICIT = const MessageKind(
      'cannot resolve constructor #{1} for implicit super call');
  static const CANNOT_RESOLVE_TYPE = const MessageKind(
      'cannot resolve type #{1}');
  static const DUPLICATE_DEFINITION = const MessageKind(
      'duplicate definition of #{1}');
  static const DUPLICATE_IMPORT = const MessageKind(
      'duplicate import of #{1}');
  static const DUPLICATE_EXPORT = const MessageKind(
      'duplicate export of #{1}');
  static const NOT_A_TYPE = const MessageKind(
      '#{1} is not a type');
  static const NOT_A_PREFIX = const MessageKind(
      '#{1} is not a prefix');
  static const NO_SUPER_IN_OBJECT = const MessageKind(
      "'Object' does not have a superclass");
  static const CANNOT_FIND_CONSTRUCTOR = const MessageKind(
      'cannot find constructor #{1}');
  static const CANNOT_FIND_CONSTRUCTOR2 = const MessageKind(
      'cannot find constructor #{1} in #{2}');
  static const CYCLIC_CLASS_HIERARCHY = const MessageKind(
      '#{1} creates a cycle in the class hierarchy');
  static const INVALID_RECEIVER_IN_INITIALIZER = const MessageKind(
      'field initializer expected');
  static const NO_SUPER_IN_STATIC = const MessageKind(
      "'super' is only available in instance methods");
  static const DUPLICATE_INITIALIZER = const MessageKind(
      'field #{1} is initialized more than once');
  static const ALREADY_INITIALIZED = const MessageKind(
      '#{1} was already initialized here');
  static const INIT_STATIC_FIELD = const MessageKind(
      'cannot initialize static field #{1}');
  static const NOT_A_FIELD = const MessageKind(
      '#{1} is not a field');
  static const CONSTRUCTOR_CALL_EXPECTED = const MessageKind(
      "only call to 'this' or 'super' constructor allowed");
  static const INVALID_FOR_IN = const MessageKind(
      'invalid for-in variable declaration.');
  static const INVALID_INITIALIZER = const MessageKind(
      'invalid initializer');
  static const FUNCTION_WITH_INITIALIZER = const MessageKind(
      'only constructors can have initializers');
  static const REDIRECTING_CONSTRUCTOR_CYCLE = const MessageKind(
      'cyclic constructor redirection');
  static const REDIRECTING_CONSTRUCTOR_HAS_BODY = const MessageKind(
      'redirecting constructor cannot have a body');
  static const REDIRECTING_CONSTRUCTOR_HAS_INITIALIZER = const MessageKind(
      'redirecting constructor cannot have other initializers');
  static const SUPER_INITIALIZER_IN_OBJECT = const MessageKind(
      "'Object' cannot have a super initializer");
  static const DUPLICATE_SUPER_INITIALIZER = const MessageKind(
      'cannot have more than one super initializer');
  static const INVALID_ARGUMENTS = const MessageKind(
      "arguments do not match the expected parameters of #{1}");
  static const NO_MATCHING_CONSTRUCTOR = const MessageKind(
      "super call arguments and constructor parameters don't match");
  static const NO_MATCHING_CONSTRUCTOR_FOR_IMPLICIT = const MessageKind(
      "implicit super call arguments and constructor parameters don't match");
  static const NO_CONSTRUCTOR = const MessageKind(
      '#{1} is a #{2}, not a constructor');
  static const FIELD_PARAMETER_NOT_ALLOWED = const MessageKind(
      'a field parameter is only allowed in generative constructors');
  static const INVALID_PARAMETER = const MessageKind(
      "cannot resolve parameter");
  static const NOT_INSTANCE_FIELD = const MessageKind(
      '#{1} is not an instance field');
  static const NO_CATCH_NOR_FINALLY = const MessageKind(
      "expected 'catch' or 'finally'");
  static const EMPTY_CATCH_DECLARATION = const MessageKind(
      'expected an identifier in catch declaration');
  static const EXTRA_CATCH_DECLARATION = const MessageKind(
      'extra parameter in catch declaration');
  static const PARAMETER_WITH_TYPE_IN_CATCH = const MessageKind(
      'cannot use type annotations in catch');
  static const PARAMETER_WITH_MODIFIER_IN_CATCH = const MessageKind(
      'cannot use modifiers in catch');
  static const OPTIONAL_PARAMETER_IN_CATCH = const MessageKind(
      'cannot use optional parameters in catch');
  static const THROW_WITHOUT_EXPRESSION = const MessageKind(
      'cannot use re-throw outside of catch block (expression expected after '
      '"throw")');
  static const UNBOUND_LABEL = const MessageKind(
      'cannot resolve label #{1}');
  static const NO_BREAK_TARGET = const MessageKind(
      'break statement not inside switch or loop');
  static const NO_CONTINUE_TARGET = const MessageKind(
      'continue statement not inside loop');
  static const EXISTING_LABEL = const MessageKind(
      'original declaration of duplicate label #{1}');
  static const DUPLICATE_LABEL = const MessageKind(
      'duplicate declaration of label #{1}');
  static const UNUSED_LABEL = const MessageKind(
      'unused label #{1}');
  static const INVALID_CONTINUE = const MessageKind(
      'target of continue is not a loop or switch case');
  static const TYPE_VARIABLE_AS_CONSTRUCTOR = const MessageKind(
      'cannot use type variable as constructor');
  static const DUPLICATE_TYPE_VARIABLE_NAME = const MessageKind(
      'type variable #{1} already declared');
  static const INVALID_BREAK = const MessageKind(
      'target of break is not a statement');
  static const INVALID_USE_OF_SUPER = const MessageKind(
      'super not allowed here');
  static const INVALID_CASE_DEFAULT = const MessageKind(
      'default only allowed on last case of a switch');

  static const SWITCH_CASE_TYPES_NOT_EQUAL = const MessageKind(
      "case expressions don't all have the same type.");
  static const SWITCH_CASE_VALUE_OVERRIDES_EQUALS = const MessageKind(
      "case expression value overrides 'operator=='.");
  static const SWITCH_INVALID = const MessageKind(
      "switch cases contain invalid expressions.");

  static const INVALID_ARGUMENT_AFTER_NAMED = const MessageKind(
      'non-named argument after named argument');

  static const NOT_A_COMPILE_TIME_CONSTANT = const MessageKind(
      'not a compile-time constant');
  static const CYCLIC_COMPILE_TIME_CONSTANTS = const MessageKind(
      'cycle in the compile-time constant computation');
  static const CONSTRUCTOR_IS_NOT_CONST = const MessageKind(
      'constructor is not a const constructor');

  static const KEY_NOT_A_STRING_LITERAL = const MessageKind(
      'map-literal key not a string literal');

  static const NO_SUCH_LIBRARY_MEMBER = const MessageKind(
      '#{1} has no member named #{2}');

  static const CANNOT_INSTANTIATE_INTERFACE = const MessageKind(
      "cannot instantiate interface '#{1}'");

  static const CANNOT_INSTANTIATE_TYPEDEF = const MessageKind(
      "cannot instantiate typedef '#{1}'");

  static const NO_DEFAULT_CLASS = const MessageKind(
      "no default class on enclosing interface '#{1}'");

  static const CYCLIC_TYPE_VARIABLE = const MessageKind(
      "cyclic reference to type variable #{1}");
  static const TYPE_NAME_EXPECTED = const MessageKind(
      "class or interface name expected");

  static const CANNOT_EXTEND = const MessageKind(
      "#{1} cannot be extended");

  static const CANNOT_IMPLEMENT = const MessageKind(
      "#{1} cannot be implemented");

  static const ILLEGAL_SUPER_SEND = const MessageKind(
      "#{1} cannot be called on super");

  static const ADDITIONAL_TYPE_ARGUMENT = const MessageKind(
      "additional type argument");

  static const MISSING_TYPE_ARGUMENT = const MessageKind(
      "missing type argument");

  static const MISSING_ARGUMENTS_TO_ASSERT = const MessageKind(
      "missing arguments to assert");

  static const GETTER_MISMATCH = const MessageKind(
      "Error: setter disagrees on: #{1}.");

  static const SETTER_MISMATCH = const MessageKind(
      "Error: getter disagrees on: #{1}.");

  static const NO_STATIC_OVERRIDE = const MessageKind(
      "Error: static member cannot override instance member '#{1}' of '#{2}'.");

  static const NO_STATIC_OVERRIDE_CONT = const MessageKind(
      "Info: this is the instance member that cannot be overridden "
      "by a static member.");

  static const CANNOT_OVERRIDE_FIELD_WITH_METHOD = const MessageKind(
      "Error: method cannot override field '#{1}' of '#{2}'.");

  static const CANNOT_OVERRIDE_FIELD_WITH_METHOD_CONT = const MessageKind(
      "Info: this is the field that cannot be overridden by a method.");

  static const CANNOT_OVERRIDE_METHOD_WITH_FIELD = const MessageKind(
      "Error: field cannot override method '#{1}' of '#{2}'.");

  static const CANNOT_OVERRIDE_METHOD_WITH_FIELD_CONT = const MessageKind(
      "Info: this is the method that cannot be overridden by a field.");

  static const BAD_ARITY_OVERRIDE = const MessageKind(
      "Error: cannot override method '#{1}' in '#{2}'; "
      "the parameters do not match.");

  static const BAD_ARITY_OVERRIDE_CONT = const MessageKind(
      "Info: this is the method whose parameters do not match.");

  static const MISSING_FORMALS = const MessageKind(
      "Error: Formal parameters are missing.");

  // TODO(ahe): Change the message below when it becomes an error.
  static const EXTRA_FORMALS = const MessageKind(
      "Warning: Formal parameters will not be allowed here in M1.");

  static const CONSTRUCTOR_WITH_RETURN_TYPE = const MessageKind(
      "Error: cannot have return type for constructor.");

  static const ILLEGAL_FINAL_METHOD_MODIFIER = const MessageKind(
      "Error: cannot have final modifier on method.");

  static const ILLEGAL_CONSTRUCTOR_MODIFIERS = const MessageKind(
      "Error: illegal constructor modifiers: #{1}.");

  static const PARAMETER_NAME_EXPECTED = const MessageKind(
      "Error: parameter name expected.");

  static const CANNOT_RESOLVE_GETTER = const MessageKind(
      'cannot resolve getter.');

  static const CANNOT_RESOLVE_SETTER = const MessageKind(
      'cannot resolve setter.');

  static const VOID_NOT_ALLOWED = const MessageKind(
      'type void is only allowed in a return type.');

  static const BEFORE_TOP_LEVEL = const MessageKind(
      'Error: part header must come before top-level definitions.');

  static const LIBRARY_NAME_MISMATCH = const MessageKind(
      'Warning: expected part of library name "#{1}".');

  static const DUPLICATED_PART_OF = const MessageKind(
      'Error: duplicated part-of directive.');

  static const ILLEGAL_DIRECTIVE = const MessageKind(
      'Error: directive not allowed here.');

  static const DUPLICATED_LIBRARY_NAME = const MessageKind(
      'Warning: duplicated library name "#{1}".');

  static const INVALID_SOURCE_FILE_LOCATION = const MessageKind('''
Invalid offset (#{1}) in source map.
File: #{2}
Length: #{3}''');

  static const PATCH_RETURN_TYPE_MISMATCH = const MessageKind(
      "Patch return type '#{3}' doesn't match '#{2}' on origin method '#{1}'.");

  static const PATCH_REQUIRED_PARAMETER_COUNT_MISMATCH = const MessageKind(
      "Required parameter count of patch method (#{3}) doesn't match parameter "
      "count on origin method '#{1}' (#{2}).");

  static const PATCH_OPTIONAL_PARAMETER_COUNT_MISMATCH = const MessageKind(
      "Optional parameter count of patch method (#{3}) doesn't match parameter "
      "count on origin method '#{1}' (#{2}).");

  static const PATCH_OPTIONAL_PARAMETER_NAMED_MISMATCH = const MessageKind(
      "Optional parameters of origin and patch method '#{1}' must "
      "both be either named or positional.");

  static const PATCH_PARAMETER_MISMATCH = const MessageKind(
      "Patch method parameter '#{3}' doesn't match '#{2}' on origin method "
      "#{1}.");
  
  static const TOP_LEVEL_VARIABLE_DECLARED_STATIC = const MessageKind(
      "Top-level variable cannot be declared static.");

  static const WRONG_NUMBER_OF_ARGUMENTS_FOR_ASSERT = const MessageKind(
      "Wrong number of arguments to assert. Should be 1, but given #{1}.");

  static const ASSERT_IS_GIVEN_NAMED_ARGUMENTS = const MessageKind(
      "assert takes no named arguments, but given #{1}.");


  static const COMPILER_CRASHED = const MessageKind(
      "Error: The compiler crashed when compiling this element.");

  static const PLEASE_REPORT_THE_CRASH = const MessageKind('''
The compiler is broken.

When compiling the above element, the compiler crashed. It is not
possible to tell if this is caused by a problem in your program or
not. Regardless, the compiler should not crash.

The Dart team would greatly appreciate if you would take a moment to
report this problem at http://dartbug.com/new.

Please include the following information:

* the name and version of your operating system,

* the Dart SDK build number (#{1}), and

* the entire message you see here (including the full stack trace
  below as well as the source location above).
''');

  toString() => template;

  Message message([List arguments = const []]) {
    return new Message(this, arguments);
  }

  CompilationError error([List arguments = const []]) {
    return new CompilationError(this, arguments);
  }
}

class Message {
  final kind;
  final List arguments;
  String message;

  Message(this.kind, this.arguments);

  String toString() {
    if (message === null) {
      message = kind.template;
      int position = 1;
      for (var argument in arguments) {
        String string = slowToString(argument);
        message = message.replaceAll('#{${position++}}', string);
      }
    }
    return message;
  }

  bool operator==(other) {
    if (other is !Message) return false;
    return (kind == other.kind) && (toString() == other.toString());
  }

  String slowToString(object) {
    if (object is SourceString) {
      return object.slowToString();
    } else {
      return object.toString();
    }
  }
}

class Diagnostic {
  final Message message;
  Diagnostic(MessageKind kind, List arguments)
    : message = new Message(kind, arguments);
  String toString() => message.toString();
}

class TypeWarning extends Diagnostic {
  TypeWarning(MessageKind kind, List arguments)
    : super(kind, arguments);
}

class ResolutionError extends Diagnostic {
  ResolutionError(MessageKind kind, List arguments)
    : super(kind, arguments);
}

class ResolutionWarning extends Diagnostic {
  ResolutionWarning(MessageKind kind, List arguments)
    : super(kind, arguments);
}

class CompileTimeConstantError extends Diagnostic {
  CompileTimeConstantError(MessageKind kind, List arguments)
    : super(kind, arguments);
}

class CompilationError extends Diagnostic {
  CompilationError(MessageKind kind, List arguments)
    : super(kind, arguments);
}
