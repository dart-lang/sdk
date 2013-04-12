// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js;

class MessageKind {
  final String template;
  const MessageKind(this.template);

  static const GENERIC = const MessageKind('#{text}');

  static const NOT_ASSIGNABLE = const MessageKind(
      '#{fromType} is not assignable to #{toType}');
  static const VOID_EXPRESSION = const MessageKind(
      'expression does not yield a value');
  static const VOID_VARIABLE = const MessageKind(
      'variable cannot be of type void');
  static const RETURN_VALUE_IN_VOID = const MessageKind(
      'cannot return value from void function');
  static const RETURN_NOTHING = const MessageKind(
      'value of type #{returnType} expected');
  static const MISSING_ARGUMENT = const MessageKind(
      'missing argument of type #{argumentType}');
  static const ADDITIONAL_ARGUMENT = const MessageKind(
      'additional argument');
  static const NAMED_ARGUMENT_NOT_FOUND = const MessageKind(
      "no named argument '#{argumentName}' found on method");
  static const METHOD_NOT_FOUND = const MessageKind(
      'no method named #{memberName} in class #{className}');
  static const NOT_CALLABLE = const MessageKind(
      "'#{elementName}' is not callable");
  static const MEMBER_NOT_STATIC = const MessageKind(
      '#{className}.#{memberName} is not static');
  static const NO_INSTANCE_AVAILABLE = const MessageKind(
      '#{name} is only available in instance methods');

  static const UNREACHABLE_CODE = const MessageKind(
      'unreachable code');
  static const MISSING_RETURN = const MessageKind(
      'missing return');
  static const MAYBE_MISSING_RETURN = const MessageKind(
      'not all paths lead to a return or throw statement');

  static const CANNOT_RESOLVE = const MessageKind(
      'cannot resolve #{name}');
  static const CANNOT_RESOLVE_CONSTRUCTOR = const MessageKind(
      'cannot resolve constructor #{constructorName}');
  static const CANNOT_RESOLVE_CONSTRUCTOR_FOR_IMPLICIT = const MessageKind(
      'cannot resolve constructor #{constructorName} for implicit super call');
  static const CANNOT_RESOLVE_TYPE = const MessageKind(
      'cannot resolve type #{typeName}');
  static const DUPLICATE_DEFINITION = const MessageKind(
      'duplicate definition of #{name}');
  static const DUPLICATE_IMPORT = const MessageKind(
      'duplicate import of #{name}');
  static const DUPLICATE_EXPORT = const MessageKind(
      'duplicate export of #{name}');
  static const NOT_A_TYPE = const MessageKind(
      '#{node} is not a type');
  static const NOT_A_PREFIX = const MessageKind(
      '#{node} is not a prefix');
  static const NO_SUPER_IN_OBJECT = const MessageKind(
      "'Object' does not have a superclass");
  static const CANNOT_FIND_CONSTRUCTOR = const MessageKind(
      'cannot find constructor #{constructorName}');
  static const CANNOT_FIND_CONSTRUCTOR2 = const MessageKind(
      'cannot find constructor #{constructorName} in #{className}');
  static const CYCLIC_CLASS_HIERARCHY = const MessageKind(
      '#{className} creates a cycle in the class hierarchy');
  static const INVALID_RECEIVER_IN_INITIALIZER = const MessageKind(
      'field initializer expected');
  static const NO_SUPER_IN_STATIC = const MessageKind(
      "'super' is only available in instance methods");
  static const DUPLICATE_INITIALIZER = const MessageKind(
      'field #{fieldName} is initialized more than once');
  static const ALREADY_INITIALIZED = const MessageKind(
      '#{fieldName} was already initialized here');
  static const INIT_STATIC_FIELD = const MessageKind(
      'cannot initialize static field #{fieldName}');
  static const NOT_A_FIELD = const MessageKind(
      '#{fieldName} is not a field');
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
      "arguments do not match the expected parameters of #{methodName}");
  static const NO_MATCHING_CONSTRUCTOR = const MessageKind(
      "super call arguments and constructor parameters don't match");
  static const NO_MATCHING_CONSTRUCTOR_FOR_IMPLICIT = const MessageKind(
      "implicit super call arguments and constructor parameters don't match");
  static const FIELD_PARAMETER_NOT_ALLOWED = const MessageKind(
      'a field parameter is only allowed in generative constructors');
  static const INVALID_PARAMETER = const MessageKind(
      "cannot resolve parameter");
  static const NOT_INSTANCE_FIELD = const MessageKind(
      '#{fieldName} is not an instance field');
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
      'cannot resolve label #{labelName}');
  static const NO_BREAK_TARGET = const MessageKind(
      'break statement not inside switch or loop');
  static const NO_CONTINUE_TARGET = const MessageKind(
      'continue statement not inside loop');
  static const EXISTING_LABEL = const MessageKind(
      'original declaration of duplicate label #{labelName}');
  static const DUPLICATE_LABEL = const MessageKind(
      'duplicate declaration of label #{labelName}');
  static const UNUSED_LABEL = const MessageKind(
      'unused label #{labelName}');
  static const INVALID_CONTINUE = const MessageKind(
      'target of continue is not a loop or switch case');
  static const INVALID_BREAK = const MessageKind(
      'target of break is not a statement');

  static const TYPE_VARIABLE_AS_CONSTRUCTOR = const MessageKind(
      'cannot use type variable as constructor');
  static const DUPLICATE_TYPE_VARIABLE_NAME = const MessageKind(
      'type variable #{typeVariableName} already declared');
  static const TYPE_VARIABLE_WITHIN_STATIC_MEMBER = const MessageKind(
      'cannot refer to type variable #{typeVariableName} '
      'within a static member');

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
      '#{libraryName} has no member named #{memberName}');

  static const CANNOT_INSTANTIATE_INTERFACE = const MessageKind(
      "cannot instantiate interface '#{interfaceName}'");

  static const CANNOT_INSTANTIATE_TYPEDEF = const MessageKind(
      "cannot instantiate typedef '#{typedefName}'");

  static const CANNOT_INSTANTIATE_TYPE_VARIABLE = const MessageKind(
      "cannot instantiate type variable '#{typeVariableName}'");

  static const NO_DEFAULT_CLASS = const MessageKind(
      "no default class on enclosing interface '#{interfaceName}'");

  static const CYCLIC_TYPE_VARIABLE = const MessageKind(
      "type variable #{typeVariableName} is a supertype of itself");

  static const CLASS_NAME_EXPECTED = const MessageKind(
      "class name expected");

  static const INTERFACE_TYPE_EXPECTED = const MessageKind(
      "interface type expected");

  static const CANNOT_EXTEND = const MessageKind(
      "#{type} cannot be extended");

  static const CANNOT_IMPLEMENT = const MessageKind(
      "#{type} cannot be implemented");

  static const DUPLICATE_EXTENDS_IMPLEMENTS = const MessageKind(
      "Error: #{type} can not be both extended and implemented.");

  static const DUPLICATE_IMPLEMENTS = const MessageKind(
      "Error: #{type} must not occur more than once "
      "in the implements clause.");

  static const ILLEGAL_SUPER_SEND = const MessageKind(
      "#{name} cannot be called on super");

  static const NO_SUCH_SUPER_MEMBER = const MessageKind(
      "Cannot resolve #{memberName} in a superclass of #{className}");

  static const ADDITIONAL_TYPE_ARGUMENT = const MessageKind(
      "additional type argument");

  static const MISSING_TYPE_ARGUMENT = const MessageKind(
      "missing type argument");

  // TODO(johnniwinther): Use ADDITIONAL_TYPE_ARGUMENT or MISSING_TYPE_ARGUMENT
  // instead.
  static const TYPE_ARGUMENT_COUNT_MISMATCH = const MessageKind(
      "incorrect number of type arguments on #{type}");

  static const MISSING_ARGUMENTS_TO_ASSERT = const MessageKind(
      "missing arguments to assert");

  static const GETTER_MISMATCH = const MessageKind(
      "Error: setter disagrees on: #{modifiers}.");

  static const SETTER_MISMATCH = const MessageKind(
      "Error: getter disagrees on: #{modifiers}.");

  static const ILLEGAL_SETTER_FORMALS = const MessageKind(
      "Error: a setter must have exactly one argument.");

  static const NO_STATIC_OVERRIDE = const MessageKind(
      "Error: static member cannot override instance member '#{memberName}' of "
      "'#{className}'.");

  static const NO_STATIC_OVERRIDE_CONT = const MessageKind(
      "Info: this is the instance member that cannot be overridden "
      "by a static member.");

  static const CANNOT_OVERRIDE_FIELD_WITH_METHOD = const MessageKind(
      "Error: method cannot override field '#{memberName}' of '#{className}'.");

  static const CANNOT_OVERRIDE_FIELD_WITH_METHOD_CONT = const MessageKind(
      "Info: this is the field that cannot be overridden by a method.");

  static const CANNOT_OVERRIDE_METHOD_WITH_FIELD = const MessageKind(
      "Error: field cannot override method '#{memberName}' of '#{className}'.");

  static const CANNOT_OVERRIDE_METHOD_WITH_FIELD_CONT = const MessageKind(
      "Info: this is the method that cannot be overridden by a field.");

  static const BAD_ARITY_OVERRIDE = const MessageKind(
      "Error: cannot override method '#{memberName}' in '#{className}'; "
      "the parameters do not match.");

  static const BAD_ARITY_OVERRIDE_CONT = const MessageKind(
      "Info: this is the method whose parameters do not match.");

  static const MISSING_FORMALS = const MessageKind(
      "Error: Formal parameters are missing.");

  static const EXTRA_FORMALS = const MessageKind(
      "Error: Formal parameters are not allowed here.");

  static const UNARY_OPERATOR_BAD_ARITY = const MessageKind(
      "Error: Operator #{operatorName} must have no parameters.");

  static const MINUS_OPERATOR_BAD_ARITY = const MessageKind(
      "Error: Operator - must have 0 or 1 parameters.");

  static const BINARY_OPERATOR_BAD_ARITY = const MessageKind(
      "Error: Operator #{operatorName} must have exactly 1 parameter.");

  static const TERNARY_OPERATOR_BAD_ARITY = const MessageKind(
      "Error: Operator #{operatorName} must have exactly 2 parameters.");

  static const OPERATOR_OPTIONAL_PARAMETERS = const MessageKind(
      "Error: Operator #{operatorName} cannot have optional parameters.");

  static const OPERATOR_NAMED_PARAMETERS = const MessageKind(
      "Error: Operator #{operatorName} cannot have named parameters.");

  // TODO(ahe): This message is hard to localize.  This is acceptable,
  // as it will be removed when we ship Dart version 1.0.
  static const DEPRECATED_FEATURE_WARNING = const MessageKind(
      "Warning: deprecated language feature, #{featureName}, "
      "will be removed in a future Dart milestone.");

  // TODO(ahe): This message is hard to localize.  This is acceptable,
  // as it will be removed when we ship Dart version 1.0.
  static const DEPRECATED_FEATURE_ERROR = const MessageKind(
      "Error: #{featureName} are not legal "
      "due to option --reject-deprecated-language-features.");

  static const CONSTRUCTOR_WITH_RETURN_TYPE = const MessageKind(
      "Error: cannot have return type for constructor.");

  static const ILLEGAL_FINAL_METHOD_MODIFIER = const MessageKind(
      "Error: cannot have final modifier on method.");

  static const ILLEGAL_CONSTRUCTOR_MODIFIERS = const MessageKind(
      "Error: illegal constructor modifiers: #{modifiers}.");

  static const ILLEGAL_MIXIN_APPLICATION_MODIFIERS = const MessageKind(
      "Error: illegal mixin application modifiers: #{modifiers}.");

  static const ILLEGAL_MIXIN_SUPERCLASS = const MessageKind(
      "Error: class used as mixin must have Object as superclass.");

  static const ILLEGAL_MIXIN_CONSTRUCTOR = const MessageKind(
      "Error: class used as mixin cannot have non-factory constructor.");

  static const ILLEGAL_MIXIN_CYCLE = const MessageKind(
      "Error: class used as mixin introduces mixin cycle: "
      "#{mixinName1} <-> #{mixinName2}.");

  static const ILLEGAL_MIXIN_WITH_SUPER = const MessageKind(
      "Error: cannot use class #{className} as a mixin because it uses super.");

  static const ILLEGAL_MIXIN_SUPER_USE = const MessageKind(
      "Use of super in class used as mixin.");

  static const PARAMETER_NAME_EXPECTED = const MessageKind(
      "Error: parameter name expected.");

  static const CANNOT_RESOLVE_GETTER = const MessageKind(
      'cannot resolve getter.');

  static const CANNOT_RESOLVE_SETTER = const MessageKind(
      'cannot resolve setter.');

  static const CANNOT_RESOLVE_INDEX = const MessageKind(
      'cannot resolve [] member.');

  static const VOID_NOT_ALLOWED = const MessageKind(
      'type void is only allowed in a return type.');

  static const BEFORE_TOP_LEVEL = const MessageKind(
      'Error: part header must come before top-level definitions.');

  static const LIBRARY_NAME_MISMATCH = const MessageKind(
      'Warning: expected part of library name "#{libraryName}".');

  static const MISSING_PART_OF_TAG = const MessageKind(
      'Note: This file has no part-of tag, but it is being used as a part.');

  static const DUPLICATED_PART_OF = const MessageKind(
      'Error: duplicated part-of directive.');

  static const ILLEGAL_DIRECTIVE = const MessageKind(
      'Error: directive not allowed here.');

  static const DUPLICATED_LIBRARY_NAME = const MessageKind(
      'Warning: duplicated library name "#{libraryName}".');

  static const INVALID_SOURCE_FILE_LOCATION = const MessageKind('''
Invalid offset (#{offset}) in source map.
File: #{fileName}
Length: #{length}''');

  static const TOP_LEVEL_VARIABLE_DECLARED_STATIC = const MessageKind(
      "Top-level variable cannot be declared static.");

  static const WRONG_NUMBER_OF_ARGUMENTS_FOR_ASSERT = const MessageKind(
      "Wrong number of arguments to assert. Should be 1, but given "
      "#{argumentCount}.");

  static const ASSERT_IS_GIVEN_NAMED_ARGUMENTS = const MessageKind(
      "assert takes no named arguments, but given #{argumentCount}.");

  static const FACTORY_REDIRECTION_IN_NON_FACTORY = const MessageKind(
      "Error: Factory redirection only allowed in factories.");

  static const MISSING_FACTORY_KEYWORD = const MessageKind(
      "Did you forget a factory keyword here?");

  static const DEFERRED_LIBRARY_NAME_MISMATCH = const MessageKind(
      'Error: Library name mismatch "#{expectedName}" != "#{actualName}".');

  static const ILLEGAL_STATIC = const MessageKind(
      "Error: Modifier static is only allowed on functions declared in"
      " a class.");

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

* the Dart SDK build number (#{buildId}), and

* the entire message you see here (including the full stack trace
  below as well as the source location above).
''');


  //////////////////////////////////////////////////////////////////////////////
  // Patch errors start.
  //////////////////////////////////////////////////////////////////////////////

  static const PATCH_RETURN_TYPE_MISMATCH = const MessageKind(
      "Patch return type '#{patchReturnType}' doesn't match "
      "'#{originReturnType}' on origin method '#{methodName}'.");

  static const PATCH_REQUIRED_PARAMETER_COUNT_MISMATCH = const MessageKind(
      "Required parameter count of patch method (#{patchParameterCount}) "
      "doesn't match parameter count on origin method '#{methodName}' "
      "(#{originParameterCount}).");

  static const PATCH_OPTIONAL_PARAMETER_COUNT_MISMATCH = const MessageKind(
      "Optional parameter count of patch method (#{patchParameterCount}) "
      "doesn't match parameter count on origin method '#{methodName}' "
      "(#{originParameterCount}).");

  static const PATCH_OPTIONAL_PARAMETER_NAMED_MISMATCH = const MessageKind(
      "Optional parameters of origin and patch method '#{methodName}' must "
      "both be either named or positional.");

  static const PATCH_PARAMETER_MISMATCH = const MessageKind(
      "Patch method parameter '#{patchParameter}' doesn't match "
      "'#{originParameter}' on origin method #{methodName}.");

  static const PATCH_EXTERNAL_WITHOUT_IMPLEMENTATION = const MessageKind(
      "External method without an implementation.");

  static const PATCH_POINT_TO_FUNCTION = const MessageKind(
      "Info: This is the function patch '#{functionName}'.");

  static const PATCH_POINT_TO_CLASS = const MessageKind(
      "Info: This is the class patch '#{className}'.");

  static const PATCH_POINT_TO_GETTER = const MessageKind(
      "Info: This is the getter patch '#{getterName}'.");

  static const PATCH_POINT_TO_SETTER = const MessageKind(
      "Info: This is the setter patch '#{setterName}'.");

  static const PATCH_POINT_TO_CONSTRUCTOR = const MessageKind(
      "Info: This is the constructor patch '#{constructorName}'.");

  static const PATCH_NON_EXISTING = const MessageKind(
      "Error: Origin does not exist for patch '#{name}'.");

  static const PATCH_NONPATCHABLE = const MessageKind(
      "Error: Only classes and functions can be patched.");

  static const PATCH_NON_EXTERNAL = const MessageKind(
      "Error: Only external functions can be patched.");

  static const PATCH_NON_CLASS = const MessageKind(
      "Error: Patching non-class with class patch '#{className}'.");

  static const PATCH_NON_GETTER = const MessageKind(
      "Error: Cannot patch non-getter '#{name}' with getter patch.");

  static const PATCH_NO_GETTER = const MessageKind(
      "Error: No getter found for getter patch '#{getterName}'.");

  static const PATCH_NON_SETTER = const MessageKind(
      "Error: Cannot patch non-setter '#{name}' with setter patch.");

  static const PATCH_NO_SETTER = const MessageKind(
      "Error: No setter found for setter patch '#{setterName}'.");

  static const PATCH_NON_CONSTRUCTOR = const MessageKind(
      "Error: Cannot patch non-constructor with constructor patch "
      "'#{constructorName}'.");

  static const PATCH_NON_FUNCTION = const MessageKind(
      "Error: Cannot patch non-function with function patch "
      "'#{functionName}'.");

  //////////////////////////////////////////////////////////////////////////////
  // Patch errors end.
  //////////////////////////////////////////////////////////////////////////////

  toString() => template;

  Message message([Map arguments = const {}]) {
    return new Message(this, arguments);
  }

  CompilationError error([Map arguments = const {}]) {
    return new CompilationError(this, arguments);
  }
}

class Message {
  final kind;
  final Map arguments;
  String message;

  Message(this.kind, this.arguments) {
    assert(() { computeMessage(); return true; });
  }

  String computeMessage() {
    if (message == null) {
      message = kind.template;
      arguments.forEach((key, value) {
        String string = slowToString(value);
        message = message.replaceAll('#{${key}}', string);
      });
      assert(invariant(
          CURRENT_ELEMENT_SPANNABLE,
          !message.contains(new RegExp(r"#\{.+\}")),
          message: 'Missing arguments in error message: "$message"'));
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
  Diagnostic(MessageKind kind, [Map arguments = const {}])
      : message = new Message(kind, arguments);
  String toString() => message.toString();
}

class TypeWarning extends Diagnostic {
  TypeWarning(MessageKind kind, [Map arguments = const {}])
    : super(kind, arguments);
}

class ResolutionError extends Diagnostic {
  ResolutionError(MessageKind kind, [Map arguments = const {}])
      : super(kind, arguments);
}

class ResolutionWarning extends Diagnostic {
  ResolutionWarning(MessageKind kind, [Map arguments = const {}])
    : super(kind, arguments);
}

class CompileTimeConstantError extends Diagnostic {
  CompileTimeConstantError(MessageKind kind, [Map arguments = const {}])
    : super(kind, arguments);
}

class CompilationError extends Diagnostic {
  CompilationError(MessageKind kind, [Map arguments = const {}])
    : super(kind, arguments);
}
