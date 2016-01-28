// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
// An INFO message should always be preceded by a non-INFO message, and the
// INFO messages are additional details about the preceding non-INFO
// message. For example, consider duplicated elements. First report a WARNING
// or ERROR about the duplicated element, and then report an INFO about the
// location of the existing element.
//
// Generally, we want to provide messages that consists of three sentences:
// 1. what is wrong, 2. why is it wrong, 3. how do I fix it. However, we
// combine the first two in [template] and the last in [howToFix].

/// Padding used before and between import chains in the message for
/// [MessageKind.IMPORT_EXPERIMENTAL_MIRRORS].
const String IMPORT_EXPERIMENTAL_MIRRORS_PADDING = '\n*   ';

/// Padding used before and between import chains in the message for
/// [MessageKind.MIRRORS_LIBRARY_NOT_SUPPORT_BY_BACKEND].
const String MIRRORS_NOT_SUPPORTED_BY_BACKEND_PADDING = '\n   ';

/// Padding used before and between import chains in the message for
/// [MessageKind.DISALLOWED_LIBRARY_IMPORT].
const String DISALLOWED_LIBRARY_IMPORT_PADDING = '\n  ';

const DONT_KNOW_HOW_TO_FIX = "Computer says no!";

final Map<String, Map> MESSAGES = {
  /// Do not use this. It is here for legacy and debugging. It violates item
  /// 4 of the guide lines for error messages in the beginning of the file.
  'GENERIC': {'id': 'SOWPSL', 'template': "#{text}",},

  'NOT_ASSIGNABLE': {
    'id': 'VYNMAP',
    'template': "'#{fromType}' is not assignable to '#{toType}'.",
  },

  'FORIN_NOT_ASSIGNABLE': {
    'id': 'XQSRXO',
    'template': "The element type '#{currentType}' of '#{expressionType}' "
        "is not assignable to '#{elementType}'.",
  },

  'VOID_EXPRESSION': {
    'id': 'QHEVSC',
    'template': "Expression does not yield a value.",
  },

  'VOID_VARIABLE': {
    'id': 'RFEURK',
    'template': "Variable cannot be of type void.",
  },

  'RETURN_VALUE_IN_VOID': {
    'id': 'FUNYDS',
    'template': "Cannot return value from void function.",
  },

  'RETURN_NOTHING': {
    'id': 'HPPODJ',
    'template': "Value of type '#{returnType}' expected.",
  },

  'MISSING_ARGUMENT': {
    'id': 'LHMCIK',
    'template': "Missing argument of type '#{argumentType}'.",
  },

  'ADDITIONAL_ARGUMENT': {'id': 'GMITMA', 'template': "Additional argument.",},

  'NAMED_ARGUMENT_NOT_FOUND': {
    'id': 'UCEARQ',
    'template': "No named argument '#{argumentName}' found on method.",
  },

  'MEMBER_NOT_FOUND': {
    'id': 'MMQODC',
    'template': "No member named '#{memberName}' in class '#{className}'.",
  },

  'AWAIT_MEMBER_NOT_FOUND': {
    'id': 'XIDLIP',
    'template': "No member named 'await' in class '#{className}'.",
    'howToFix': "Did you mean to add the 'async' marker "
        "to '#{functionName}'?",
    'examples': [
      """
class A {
m() => await -3;
}
main() => new A().m();
"""
    ],
  },

  'AWAIT_MEMBER_NOT_FOUND_IN_CLOSURE': {
    'id': 'HBIYGN',
    'template': "No member named 'await' in class '#{className}'.",
    'howToFix': "Did you mean to add the 'async' marker "
        "to the enclosing function?",
    'examples': [
      """
class A {
m() => () => await -3;
}
main() => new A().m();
"""
    ],
  },

  'METHOD_NOT_FOUND': {
    'id': 'QYYHBU',
    'template': "No method named '#{memberName}' in class '#{className}'.",
  },

  'OPERATOR_NOT_FOUND': {
    'id': 'SXGOYS',
    'template': "No operator '#{memberName}' in class '#{className}'.",
  },

  'SETTER_NOT_FOUND': {
    'id': 'ADFRVF',
    'template': "No setter named '#{memberName}' in class '#{className}'.",
  },

  'SETTER_NOT_FOUND_IN_SUPER': {
    'id': 'OCVRNJ',
    'template': "No setter named '#{name}' in superclass of '#{className}'.",
  },

  'GETTER_NOT_FOUND': {
    'id': 'PBNXAC',
    'template': "No getter named '#{memberName}' in class '#{className}'.",
  },

  'NOT_CALLABLE': {
    'id': 'SEMKJO',
    'template': "'#{elementName}' is not callable.",
  },

  'MEMBER_NOT_STATIC': {
    'id': 'QIOISX',
    'template': "'#{className}.#{memberName}' is not static.",
  },

  'NO_INSTANCE_AVAILABLE': {
    'id': 'FQPYLR',
    'template': "'#{name}' is only available in instance methods.",
  },

  'NO_THIS_AVAILABLE': {
    'id': 'LXPXKG',
    'template': "'this' is only available in instance methods.",
  },

  'PRIVATE_ACCESS': {
    'id': 'DIMHCR',
    'template': "'#{name}' is declared private within library "
        "'#{libraryName}'.",
  },

  'THIS_IS_THE_DECLARATION': {
    'id': 'YIJWTO',
    'template': "This is the declaration of '#{name}'.",
  },

  'THIS_IS_THE_METHOD': {
    'id': 'PYXWLF',
    'template': "This is the method declaration.",
  },

  'CANNOT_RESOLVE': {'id': 'SPVJYO', 'template': "Cannot resolve '#{name}'.",},

  'CANNOT_RESOLVE_AWAIT': {
    'id': 'YQYLRS',
    'template': "Cannot resolve '#{name}'.",
    'howToFix': "Did you mean to add the 'async' marker "
        "to '#{functionName}'?",
    'examples': ["main() => await -3;", "foo() => await -3; main() => foo();"],
  },

  'CANNOT_RESOLVE_AWAIT_IN_CLOSURE': {
    'id': 'SIXRAA',
    'template': "Cannot resolve '#{name}'.",
    'howToFix': "Did you mean to add the 'async' marker "
        "to the enclosing function?",
    'examples': ["main() { (() => await -3)(); }",],
  },

  'CANNOT_RESOLVE_IN_INITIALIZER': {
    'id': 'VVEQFD',
    'template':
        "Cannot resolve '#{name}'. It would be implicitly looked up on this "
        "instance, but instances are not available in initializers.",
    'howToFix': "Try correcting the unresolved reference or move the "
        "initialization to a constructor body.",
    'examples': [
      """
class A {
var test = unresolvedName;
}
main() => new A();
"""
    ],
  },

  'CANNOT_RESOLVE_CONSTRUCTOR': {
    'id': 'QRPATN',
    'template': "Cannot resolve constructor '#{constructorName}'.",
  },

  'CANNOT_RESOLVE_CONSTRUCTOR_FOR_IMPLICIT': {
    'id': 'IFKCHF',
    'template': "cannot resolve constructor '#{constructorName}' "
        "for implicit super call.",
    'howToFix': "Try explicitly invoking a constructor of the super class",
    'examples': [
      """
class A {
A.foo() {}
}
class B extends A {
B();
}
main() => new B();
"""
    ],
  },

  'INVALID_UNNAMED_CONSTRUCTOR_NAME': {
    'id': 'VPJLVI',
    'template': "Unnamed constructor name must be '#{name}'.",
  },

  'INVALID_CONSTRUCTOR_NAME': {
    'id': 'LMDCAS',
    'template': "Constructor name must start with '#{name}'.",
  },

  'CANNOT_RESOLVE_TYPE': {
    'id': 'PQIAPG',
    'template': "Cannot resolve type '#{typeName}'.",
  },

  'DUPLICATE_DEFINITION': {
    'id': 'LVTYNW',
    'template': "Duplicate definition of '#{name}'.",
    'howToFix': "Try to rename or remove this definition.",
    'examples': [
      """
class C {
void f() {}
int get f => 1;
}

main() {
new C();
}

"""
    ],
  },

  'EXISTING_DEFINITION': {
    'id': 'DAUYKK',
    'template': "Existing definition of '#{name}'.",
  },

  'DUPLICATE_IMPORT': {
    'id': 'KYJFJN',
    'template': "Duplicate import of '#{name}'.",
  },

  'HIDDEN_IMPORT': {
    'id': 'ACRDPR',
    'template': "'#{name}' from library '#{hiddenUri}' is hidden by '#{name}' "
        "from library '#{hidingUri}'.",
    'howToFix': "Try adding 'hide #{name}' to the import of '#{hiddenUri}'.",
    'examples': [
      {
        'main.dart': """
import 'dart:async'; // This imports a class Future.
import 'future.dart';

void main() => new Future();""",
        'future.dart': """
library future;

class Future {}"""
      },
      {
        'main.dart': """
import 'future.dart';
import 'dart:async'; // This imports a class Future.

void main() => new Future();""",
        'future.dart': """
library future;

class Future {}"""
      },
      {
        'main.dart': """
import 'export.dart';
import 'dart:async'; // This imports a class Future.

void main() => new Future();""",
        'future.dart': """
library future;

class Future {}""",
        'export.dart': """
library export;

export 'future.dart';"""
      },
      {
        'main.dart': """
import 'future.dart' as prefix;
import 'dart:async' as prefix; // This imports a class Future.

void main() => new prefix.Future();""",
        'future.dart': """
library future;

class Future {}"""
      }
    ],
  },

  'HIDDEN_IMPLICIT_IMPORT': {
    'id': 'WDNFSI',
    'template': "'#{name}' from library '#{hiddenUri}' is hidden by '#{name}' "
        "from library '#{hidingUri}'.",
    'howToFix': "Try adding an explicit "
        "'import \"#{hiddenUri}\" hide #{name}'.",
    'examples': [
      {
        'main.dart': """
// This hides the implicit import of class Type from dart:core.
import 'type.dart';

void main() => new Type();""",
        'type.dart': """
library type;

class Type {}"""
      },
      {
        'conflictsWithDart.dart': """
library conflictsWithDart;

class Duration {
static var x = 100;
}
""",
        'conflictsWithDartAsWell.dart': """
library conflictsWithDartAsWell;

class Duration {
static var x = 100;
}
""",
        'main.dart': r"""
library testDartConflicts;

import 'conflictsWithDart.dart';
import 'conflictsWithDartAsWell.dart';

main() {
print("Hail Caesar ${Duration.x}");
}
"""
      }
    ],
  },

  'DUPLICATE_EXPORT': {
    'id': 'XGNOCL',
    'template': "Duplicate export of '#{name}'.",
    'howToFix': "Try adding 'hide #{name}' to one of the exports.",
    'examples': [
      {
        'main.dart': """
export 'decl1.dart';
export 'decl2.dart';

main() {}""",
        'decl1.dart': "class Class {}",
        'decl2.dart': "class Class {}"
      }
    ],
  },

  'DUPLICATE_EXPORT_CONT': {
    'id': 'BDROED',
    'template': "This is another export of '#{name}'.",
  },

  'DUPLICATE_EXPORT_DECL': {
    'id': 'GFFLMA',
    'template':
        "The exported '#{name}' from export #{uriString} is defined here.",
  },

  'EMPTY_HIDE': {
    'id': 'ODFAOC',
    'template': "Library '#{uri}' doesn't export a '#{name}' declaration.",
    'howToFix': "Try removing '#{name}' the 'hide' clause.",
    'examples': [
      {
        'main.dart': """
import 'dart:core' hide Foo;

main() {}"""
      },
      {
        'main.dart': """
export 'dart:core' hide Foo;

main() {}"""
      },
    ],
  },

  'EMPTY_SHOW': {
    'id': 'EXONIK',
    'template': "Library '#{uri}' doesn't export a '#{name}' declaration.",
    'howToFix': "Try removing '#{name}' from the 'show' clause.",
    'examples': [
      {
        'main.dart': """
import 'dart:core' show Foo;

main() {}"""
      },
      {
        'main.dart': """
export 'dart:core' show Foo;

main() {}"""
      },
    ],
  },

  'NOT_A_TYPE': {'id': 'CTTAXD', 'template': "'#{node}' is not a type.",},

  'NOT_A_PREFIX': {'id': 'LKEUMI', 'template': "'#{node}' is not a prefix.",},

  'PREFIX_AS_EXPRESSION': {
    'id': 'CYIMBJ',
    'template': "Library prefix '#{prefix}' is not a valid expression.",
  },

  'CANNOT_FIND_CONSTRUCTOR': {
    'id': 'DROVNH',
    'template': "Cannot find constructor '#{constructorName}' in class "
        "'#{className}'.",
  },

  'CANNOT_FIND_UNNAMED_CONSTRUCTOR': {
    'id': 'GDCTGB',
    'template': "Cannot find unnamed constructor in class "
        "'#{className}'.",
  },

  'CYCLIC_CLASS_HIERARCHY': {
    'id': 'HKFYOA',
    'template': "'#{className}' creates a cycle in the class hierarchy.",
  },

  'CYCLIC_REDIRECTING_FACTORY': {
    'id': 'QGETJC',
    'template': "Redirecting factory leads to a cyclic redirection.",
  },

  'INVALID_RECEIVER_IN_INITIALIZER': {
    'id': 'SYUTHA',
    'template': "Field initializer expected.",
  },

  'NO_SUPER_IN_STATIC': {
    'id': 'HSCESG',
    'template': "'super' is only available in instance methods.",
  },

  'DUPLICATE_INITIALIZER': {
    'id': 'GKVFEP',
    'template': "Field '#{fieldName}' is initialized more than once.",
  },

  'ALREADY_INITIALIZED': {
    'id': 'NCRMVD',
    'template': "'#{fieldName}' was already initialized here.",
  },

  'INIT_STATIC_FIELD': {
    'id': 'DBSRHA',
    'template': "Cannot initialize static field '#{fieldName}'.",
  },

  'NOT_A_FIELD': {
    'id': 'FYEPLC',
    'template': "'#{fieldName}' is not a field.",
  },

  'CONSTRUCTOR_CALL_EXPECTED': {
    'id': 'GEJCDX',
    'template': "only call to 'this' or 'super' constructor allowed.",
  },

  'INVALID_FOR_IN': {
    'id': 'AUQJBG',
    'template': "Invalid for-in variable declaration.",
  },

  'INVALID_INITIALIZER': {'id': 'JKUKSA', 'template': "Invalid initializer.",},

  'FUNCTION_WITH_INITIALIZER': {
    'id': 'BNRDDK',
    'template': "Only constructors can have initializers.",
  },

  'REDIRECTING_CONSTRUCTOR_CYCLE': {
    'id': 'CQTMEP',
    'template': "Cyclic constructor redirection.",
  },

  'REDIRECTING_CONSTRUCTOR_HAS_BODY': {
    'id': 'WXJQNE',
    'template': "Redirecting constructor can't have a body.",
  },

  'CONST_CONSTRUCTOR_HAS_BODY': {
    'id': 'GNEFQG',
    'template': "Const constructor or factory can't have a body.",
    'howToFix': "Remove the 'const' keyword or the body",
    'examples': [
      """
class C {
const C() {}
}

main() => new C();"""
    ],
  },

  'REDIRECTING_CONSTRUCTOR_HAS_INITIALIZER': {
    'id': 'NUIDSF',
    'template': "Redirecting constructor cannot have other initializers.",
  },

  'SUPER_INITIALIZER_IN_OBJECT': {
    'id': 'DXYGND',
    'template': "'Object' cannot have a super initializer.",
  },

  'DUPLICATE_SUPER_INITIALIZER': {
    'id': 'FFKOWP',
    'template': "Cannot have more than one super initializer.",
  },

  'SUPER_CALL_TO_FACTORY': {
    'id': 'YTOWGV',
    'template': "The target of the superinitializer must be a generative "
        "constructor.",
    'howToFix': "Try calling another constructor on the superclass.",
    'examples': [
      """
class Super {
factory Super() => null;
}
class Class extends Super {}
main() => new Class();
""",
      """
class Super {
factory Super() => null;
}
class Class extends Super {
Class();
}
main() => new Class();
""",
      """
class Super {
factory Super() => null;
}
class Class extends Super {
Class() : super();
}
main() => new Class();
""",
      """
class Super {
factory Super.foo() => null;
}
class Class extends Super {
Class() : super.foo();
}
main() => new Class();
"""
    ],
  },

  'THIS_CALL_TO_FACTORY': {
    'id': 'JLATDB',
    'template': "The target of the redirection clause must be a generative "
        "constructor",
    'howToFix': "Try redirecting to another constructor.",
    'examples': [
      """
class Class {
factory Class() => null;
Class.foo() : this();
}
main() => new Class.foo();
""",
      """
class Class {
factory Class.foo() => null;
Class() : this.foo();
}
main() => new Class();
"""
    ],
  },

  'INVALID_CONSTRUCTOR_ARGUMENTS': {
    'id': 'WVPLKL',
    'template': "Arguments do not match the expected parameters of constructor "
        "'#{constructorName}'.",
  },

  'NO_MATCHING_CONSTRUCTOR': {
    'id': 'OJQQLE',
    'template':
        "'super' call arguments and constructor parameters do not match.",
  },

  'NO_MATCHING_CONSTRUCTOR_FOR_IMPLICIT': {
    'id': 'WHCVID',
    'template': "Implicit 'super' call arguments and constructor parameters "
        "do not match.",
  },

  'CONST_CALLS_NON_CONST': {
    'id': 'CQFHXC',
    'template': "'const' constructor cannot call a non-const constructor.",
  },

  'CONST_CALLS_NON_CONST_FOR_IMPLICIT': {
    'id': 'SFCEXS',
    'template': "'const' constructor cannot call a non-const constructor. "
        "This constructor has an implicit call to a "
        "super non-const constructor.",
    'howToFix': "Try making the super constructor const.",
    'examples': [
      """
class C {
C(); // missing const
}
class D extends C {
final d;
const D(this.d);
}
main() => new D(0);"""
    ],
  },

  'CONST_CONSTRUCTOR_WITH_NONFINAL_FIELDS': {
    'id': 'XBHUDL',
    'template': "Can't declare constructor 'const' on class #{className} "
        "because the class contains non-final instance fields.",
    'howToFix': "Try making all fields final.",
    'examples': [
      """
class C {
// 'a' must be declared final to allow for the const constructor.
var a;
const C(this.a);
}

main() => new C(0);"""
    ],
  },

  'CONST_CONSTRUCTOR_WITH_NONFINAL_FIELDS_FIELD': {
    'id': 'YYAHVD',
    'template': "This non-final field prevents using const constructors.",
  },

  'CONST_CONSTRUCTOR_WITH_NONFINAL_FIELDS_CONSTRUCTOR': {
    'id': 'FROWJB',
    'template': "This const constructor is not allowed due to "
        "non-final fields.",
  },

  'INITIALIZING_FORMAL_NOT_ALLOWED': {
    'id': 'YIPXYP',
    'template': "Initializing formal parameter only allowed in generative "
        "constructor.",
  },

  'INVALID_PARAMETER': {
    'id': 'OWWLIX',
    'template': "Cannot resolve parameter.",
  },

  'NOT_INSTANCE_FIELD': {
    'id': 'VSPKMU',
    'template': "'#{fieldName}' is not an instance field.",
  },

  'THIS_PROPERTY': {'id': 'MWFIGH', 'template': "Expected an identifier.",},

  'NO_CATCH_NOR_FINALLY': {
    'id': 'OPJXPP',
    'template': "Expected 'catch' or 'finally'.",
  },

  'EMPTY_CATCH_DECLARATION': {
    'id': 'UNHCPY',
    'template': "Expected an identifier in catch declaration.",
  },

  'EXTRA_CATCH_DECLARATION': {
    'id': 'YGGRAK',
    'template': "Extra parameter in catch declaration.",
  },

  'PARAMETER_WITH_TYPE_IN_CATCH': {
    'id': 'EXQVDU',
    'template': "Cannot use type annotations in catch.",
  },

  'PARAMETER_WITH_MODIFIER_IN_CATCH': {
    'id': 'BQLKRF',
    'template': "Cannot use modifiers in catch.",
  },

  'OPTIONAL_PARAMETER_IN_CATCH': {
    'id': 'DAICPP',
    'template': "Cannot use optional parameters in catch.",
  },

  'THROW_WITHOUT_EXPRESSION': {
    'id': 'YHACYV',
    'template': "Cannot use re-throw outside of catch block "
        "(expression expected after 'throw').",
  },

  'UNBOUND_LABEL': {
    'id': 'GLDXHY',
    'template': "Cannot resolve label '#{labelName}'.",
  },

  'NO_BREAK_TARGET': {
    'id': 'VBXXBE',
    'template': "'break' statement not inside switch or loop.",
  },

  'NO_CONTINUE_TARGET': {
    'id': 'JTTHHM',
    'template': "'continue' statement not inside loop.",
  },

  'EXISTING_LABEL': {
    'id': 'AHCSXF',
    'template': "Original declaration of duplicate label '#{labelName}'.",
  },

  'DUPLICATE_LABEL': {
    'id': 'HPULLI',
    'template': "Duplicate declaration of label '#{labelName}'.",
  },

  'UNUSED_LABEL': {'id': 'KFREJO', 'template': "Unused label '#{labelName}'.",},

  'INVALID_CONTINUE': {
    'id': 'DSKTPX',
    'template': "Target of continue is not a loop or switch case.",
  },

  'INVALID_BREAK': {
    'id': 'MFCCWX',
    'template': "Target of break is not a statement.",
  },

  'DUPLICATE_TYPE_VARIABLE_NAME': {
    'id': 'BAYCCM',
    'template': "Type variable '#{typeVariableName}' already declared.",
  },

  'TYPE_VARIABLE_WITHIN_STATIC_MEMBER': {
    'id': 'XQLXRL',
    'template': "Cannot refer to type variable '#{typeVariableName}' "
        "within a static member.",
  },

  'TYPE_VARIABLE_IN_CONSTANT': {
    'id': 'ANDEVG',
    'template': "Constant expressions can't refer to type variables.",
    'howToFix': "Try removing the type variable or replacing it with a "
        "concrete type.",
    'examples': [
      """
class C<T> {
const C();

m(T t) => const C<T>();
}

void main() => new C().m(null);
"""
    ],
  },

  'INVALID_TYPE_VARIABLE_BOUND': {
    'id': 'WQAEDK',
    'template': "'#{typeArgument}' is not a subtype of bound '#{bound}' for "
        "type variable '#{typeVariable}' of type '#{thisType}'.",
    'howToFix': "Try to change or remove the type argument.",
    'examples': [
      """
class C<T extends num> {}

// 'String' is not a valid instantiation of T with bound num.'.
main() => new C<String>();
"""
    ],
  },

  'INVALID_USE_OF_SUPER': {
    'id': 'JKYYSN',
    'template': "'super' not allowed here.",
  },

  'INVALID_CASE_DEFAULT': {
    'id': 'ABSPBM',
    'template': "'default' only allowed on last case of a switch.",
  },

  'SWITCH_CASE_TYPES_NOT_EQUAL': {
    'id': 'UFQPBC',
    'template': "'case' expressions do not all have type '#{type}'.",
  },

  'SWITCH_CASE_TYPES_NOT_EQUAL_CASE': {
    'id': 'RDMVAC',
    'template': "'case' expression of type '#{type}'.",
  },

  'SWITCH_CASE_FORBIDDEN': {
    'id': 'UHSCSU',
    'template': "'case' expression may not be of type '#{type}'.",
  },

  'SWITCH_CASE_VALUE_OVERRIDES_EQUALS': {
    'id': 'NRTWXL',
    'template': "'case' expression type '#{type}' overrides 'operator =='.",
  },

  'INVALID_ARGUMENT_AFTER_NAMED': {
    'id': 'WAJURC',
    'template': "Unnamed argument after named argument.",
  },

  'NOT_A_COMPILE_TIME_CONSTANT': {
    'id': 'SBCHWL',
    'template': "Not a compile-time constant.",
  },

  'DEFERRED_COMPILE_TIME_CONSTANT': {
    'id': 'FHXTCK',
    'template': "A deferred value cannot be used as a compile-time constant.",
  },

  'DEFERRED_COMPILE_TIME_CONSTANT_CONSTRUCTION': {
    'id': 'TSBXLG',
    'template': "A deferred class cannot be used to create a "
        "compile-time constant.",
  },

  'CYCLIC_COMPILE_TIME_CONSTANTS': {
    'id': 'JJWJYE',
    'template': "Cycle in the compile-time constant computation.",
  },

  'CONSTRUCTOR_IS_NOT_CONST': {
    'id': 'DOJCUX',
    'template': "Constructor is not a 'const' constructor.",
  },

  'CONST_MAP_KEY_OVERRIDES_EQUALS': {
    'id': 'VJNWEL',
    'template': "Const-map key type '#{type}' overrides 'operator =='.",
  },

  'NO_SUCH_LIBRARY_MEMBER': {
    'id': 'IOXVBA',
    'template': "'#{libraryName}' has no member named '#{memberName}'.",
  },

  'CANNOT_INSTANTIATE_TYPEDEF': {
    'id': 'KOYNMU',
    'template': "Cannot instantiate typedef '#{typedefName}'.",
  },

  'REQUIRED_PARAMETER_WITH_DEFAULT': {
    'id': 'CJWECI',
    'template': "Non-optional parameters can't have a default value.",
    'howToFix':
        "Try removing the default value or making the parameter optional.",
    'examples': [
      """
main() {
foo(a: 1) => print(a);
foo(2);
}""",
      """
main() {
foo(a = 1) => print(a);
foo(2);
}"""
    ],
  },

  'NAMED_PARAMETER_WITH_EQUALS': {
    'id': 'RPJDXD',
    'template': "Named optional parameters can't use '=' to specify a default "
        "value.",
    'howToFix': "Try replacing '=' with ':'.",
    'examples': [
      """
main() {
foo({a = 1}) => print(a);
foo(a: 2);
}"""
    ],
  },

  'POSITIONAL_PARAMETER_WITH_EQUALS': {
    'id': 'JMSSDX',
    'template': "Positional optional parameters can't use ':' to specify a "
        "default value.",
    'howToFix': "Try replacing ':' with '='.",
    'examples': [
      """
main() {
foo([a: 1]) => print(a);
foo(2);
}"""
    ],
  },

  'TYPEDEF_FORMAL_WITH_DEFAULT': {
    'id': 'NABHHS',
    'template': "A parameter of a typedef can't specify a default value.",
    'howToFix': "Try removing the default value.",
    'examples': [
      """
typedef void F([int arg = 0]);

main() {
F f;
}""",
      """
typedef void F({int arg: 0});

main() {
F f;
}"""
    ],
  },

  'FUNCTION_TYPE_FORMAL_WITH_DEFAULT': {
    'id': 'APKYLU',
    'template': "A function type parameter can't specify a default value.",
    'howToFix': "Try removing the default value.",
    'examples': [
      """
foo(f(int i, [a = 1])) {}

main() {
foo(1, 2);
}""",
      """
foo(f(int i, {a: 1})) {}

main() {
foo(1, a: 2);
}"""
    ],
  },

  'REDIRECTING_FACTORY_WITH_DEFAULT': {
    'id': 'AWSSEY',
    'template':
        "A parameter of a redirecting factory constructor can't specify a "
        "default value.",
    'howToFix': "Try removing the default value.",
    'examples': [
      """
class A {
A([a]);
factory A.foo([a = 1]) = A;
}

main() {
new A.foo(1);
}""",
      """
class A {
A({a});
factory A.foo({a: 1}) = A;
}

main() {
new A.foo(a: 1);
}"""
    ],
  },

  'FORMAL_DECLARED_CONST': {
    'id': 'AVPRDK',
    'template': "A formal parameter can't be declared const.",
    'howToFix': "Try removing 'const'.",
    'examples': [
      """
foo(const x) {}
main() => foo(42);
""",
      """
foo({const x}) {}
main() => foo(42);
""",
      """
foo([const x]) {}
main() => foo(42);
"""
    ],
  },

  'FORMAL_DECLARED_STATIC': {
    'id': 'PJKDMX',
    'template': "A formal parameter can't be declared static.",
    'howToFix': "Try removing 'static'.",
    'examples': [
      """
foo(static x) {}
main() => foo(42);
""",
      """
foo({static x}) {}
main() => foo(42);
""",
      """
foo([static x]) {}
main() => foo(42);
"""
    ],
  },

  'FINAL_FUNCTION_TYPE_PARAMETER': {
    'id': 'JIOPIQ',
    'template': "A function type parameter can't be declared final.",
    'howToFix': "Try removing 'final'.",
    'examples': [
      """
foo(final int x(int a)) {}
main() => foo((y) => 42);
""",
      """
foo({final int x(int a)}) {}
main() => foo((y) => 42);
""",
      """
foo([final int x(int a)]) {}
main() => foo((y) => 42);
"""
    ],
  },

  'VAR_FUNCTION_TYPE_PARAMETER': {
    'id': 'FOQOHK',
    'template': "A function type parameter can't be declared with 'var'.",
    'howToFix': "Try removing 'var'.",
    'examples': [
      """
foo(var int x(int a)) {}
main() => foo((y) => 42);
""",
      """
foo({var int x(int a)}) {}
main() => foo((y) => 42);
""",
      """
foo([var int x(int a)]) {}
main() => foo((y) => 42);
"""
    ],
  },

  'CANNOT_INSTANTIATE_TYPE_VARIABLE': {
    'id': 'JAYHCH',
    'template': "Cannot instantiate type variable '#{typeVariableName}'.",
  },

  'CYCLIC_TYPE_VARIABLE': {
    'id': 'RQMPSO',
    'template': "Type variable '#{typeVariableName}' is a supertype of itself.",
  },

  'CYCLIC_TYPEDEF': {
    'id': 'VFERCQ',
    'template': "A typedef can't refer to itself.",
    'howToFix': "Try removing all references to '#{typedefName}' "
        "in the definition of '#{typedefName}'.",
    'examples': [
      """
typedef F F(); // The return type 'F' is a self-reference.
main() { F f = null; }"""
    ],
  },

  'CYCLIC_TYPEDEF_ONE': {
    'id': 'ASWLWR',
    'template': "A typedef can't refer to itself through another typedef.",
    'howToFix': "Try removing all references to "
        "'#{otherTypedefName}' in the definition of '#{typedefName}'.",
    'examples': [
      """
typedef G F(); // The return type 'G' is a self-reference through typedef 'G'.
typedef F G(); // The return type 'F' is a self-reference through typedef 'F'.
main() { F f = null; }""",
      """
typedef G F(); // The return type 'G' creates a self-reference.
typedef H G(); // The return type 'H' creates a self-reference.
typedef H(F f); // The argument type 'F' creates a self-reference.
main() { F f = null; }"""
    ],
  },

  'CLASS_NAME_EXPECTED': {'id': 'DPKNHY', 'template': "Class name expected.",},

  'CANNOT_EXTEND': {
    'id': 'GCIQXD',
    'template': "'#{type}' cannot be extended.",
  },

  'CANNOT_IMPLEMENT': {
    'id': 'IBOQKV',
    'template': "'#{type}' cannot be implemented.",
  },

  // TODO(johnnwinther): Split messages into reasons for malformedness.
  'CANNOT_EXTEND_MALFORMED': {
    'id': 'YPFJBD',
    'template': "Class '#{className}' can't extend the type '#{malformedType}' "
        "because it is malformed.",
    'howToFix': "Try correcting the malformed type annotation or removing the "
        "'extends' clause.",
    'examples': [
      """
class A extends Malformed {}
main() => new A();"""
    ],
  },

  'CANNOT_IMPLEMENT_MALFORMED': {
    'id': 'XJUIAQ',
    'template':
        "Class '#{className}' can't implement the type '#{malformedType}' "
        "because it is malformed.",
    'howToFix': "Try correcting the malformed type annotation or removing the "
        "type from the 'implements' clause.",
    'examples': [
      """
class A implements Malformed {}
main() => new A();"""
    ],
  },

  'CANNOT_MIXIN_MALFORMED': {
    'id': 'SSMNXN',
    'template': "Class '#{className}' can't mixin the type '#{malformedType}' "
        "because it is malformed.",
    'howToFix': "Try correcting the malformed type annotation or removing the "
        "type from the 'with' clause.",
    'examples': [
      """
class A extends Object with Malformed {}
main() => new A();"""
    ],
  },

  'CANNOT_MIXIN': {
    'id': 'KLSXDQ',
    'template': "The type '#{type}' can't be mixed in.",
    'howToFix': "Try removing '#{type}' from the 'with' clause.",
    'examples': [
      """
class C extends Object with String {}

main() => new C();
""",
      """
typedef C = Object with String;

main() => new C();
"""
    ],
  },

  'CANNOT_EXTEND_ENUM': {
    'id': 'JEPRST',
    'template':
        "Class '#{className}' can't extend the type '#{enumType}' because "
        "it is declared by an enum.",
    'howToFix': "Try making '#{enumType}' a normal class or removing the "
        "'extends' clause.",
    'examples': [
      """
enum Enum { A }
class B extends Enum {}
main() => new B();"""
    ],
  },

  'CANNOT_IMPLEMENT_ENUM': {
    'id': 'JMJMSH',
    'template': "Class '#{className}' can't implement the type '#{enumType}' "
        "because it is declared by an enum.",
    'howToFix': "Try making '#{enumType}' a normal class or removing the "
        "type from the 'implements' clause.",
    'examples': [
      """
enum Enum { A }
class B implements Enum {}
main() => new B();"""
    ],
  },

  'CANNOT_MIXIN_ENUM': {
    'id': 'YSYDIM',
    'template':
        "Class '#{className}' can't mixin the type '#{enumType}' because it "
        "is declared by an enum.",
    'howToFix': "Try making '#{enumType}' a normal class or removing the "
        "type from the 'with' clause.",
    'examples': [
      """
enum Enum { A }
class B extends Object with Enum {}
main() => new B();"""
    ],
  },

  'CANNOT_INSTANTIATE_ENUM': {
    'id': 'CQYIFU',
    'template': "Enum type '#{enumName}' cannot be instantiated.",
    'howToFix': "Try making '#{enumType}' a normal class or use an enum "
        "constant.",
    'examples': [
      """
enum Enum { A }
main() => new Enum(0);""",
      """
enum Enum { A }
main() => const Enum(0);"""
    ],
  },

  'EMPTY_ENUM_DECLARATION': {
    'id': 'JFPDOH',
    'template': "Enum '#{enumName}' must contain at least one value.",
    'howToFix': "Try adding an enum constant or making #{enumName} a "
        "normal class.",
    'examples': [
      """
enum Enum {}
main() { Enum e; }"""
    ],
  },

  'MISSING_ENUM_CASES': {
    'id': 'HHEOIW',
    'template': "Missing enum constants in switch statement: #{enumValues}.",
    'howToFix': "Try adding the missing constants or a default case.",
    'examples': [
      """
enum Enum { A, B }
main() {
switch (Enum.A) {
case Enum.B: break;
}
}""",
      """
enum Enum { A, B, C }
main() {
switch (Enum.A) {
case Enum.B: break;
}
}"""
    ],
  },

  'DUPLICATE_EXTENDS_IMPLEMENTS': {
    'id': 'BKRKEO',
    'template': "'#{type}' can not be both extended and implemented.",
  },

  'DUPLICATE_IMPLEMENTS': {
    'id': 'IWJFTU',
    'template': "'#{type}' must not occur more than once "
        "in the implements clause.",
  },

  'MULTI_INHERITANCE': {
    'id': 'NWXGOI',
    'template':
        "Dart2js does not currently support inheritance of the same class "
        "with different type arguments: Both #{firstType} and #{secondType} "
        "are supertypes of #{thisType}.",
  },

  'ILLEGAL_SUPER_SEND': {
    'id': 'LDRGIU',
    'template': "'#{name}' cannot be called on super.",
  },

  'NO_SUCH_SUPER_MEMBER': {
    'id': 'HIJJVG',
    'template':
        "Cannot resolve '#{memberName}' in a superclass of '#{className}'.",
  },

  'ADDITIONAL_TYPE_ARGUMENT': {
    'id': 'HWYHWH',
    'template': "Additional type argument.",
  },

  'MISSING_TYPE_ARGUMENT': {
    'id': 'KYTQWA',
    'template': "Missing type argument.",
  },

  // TODO(johnniwinther): Use ADDITIONAL_TYPE_ARGUMENT or
  // MISSING_TYPE_ARGUMENT instead.
  'TYPE_ARGUMENT_COUNT_MISMATCH': {
    'id': 'ECXGRM',
    'template': "Incorrect number of type arguments on '#{type}'.",
  },

  'GETTER_MISMATCH': {
    'id': 'MNODFW',
    'template': "Setter disagrees on: '#{modifiers}'.",
  },

  'SETTER_MISMATCH': {
    'id': 'FMNHPL',
    'template': "Getter disagrees on: '#{modifiers}'.",
  },

  'ILLEGAL_SETTER_FORMALS': {
    'id': 'COTPVN',
    'template': "A setter must have exactly one argument.",
  },

  'NO_STATIC_OVERRIDE': {
    'id': 'EHINXB',
    'template':
        "Static member cannot override instance member '#{memberName}' of "
        "'#{className}'.",
  },

  'NO_STATIC_OVERRIDE_CONT': {
    'id': 'TEVJMA',
    'template': "This is the instance member that cannot be overridden "
        "by a static member.",
  },

  'INSTANCE_STATIC_SAME_NAME': {
    'id': 'LTBFBO',
    'template': "Instance member '#{memberName}' and static member of "
        "superclass '#{className}' have the same name.",
  },

  'INSTANCE_STATIC_SAME_NAME_CONT': {
    'id': 'CHSUCQ',
    'template': "This is the static member with the same name.",
  },

  'INVALID_OVERRIDE_METHOD': {
    'id': 'NINKPI',
    'template': "The type '#{declaredType}' of method '#{name}' declared in "
        "'#{class}' is not a subtype of the overridden method type "
        "'#{inheritedType}' inherited from '#{inheritedClass}'.",
  },

  'INVALID_OVERRIDDEN_METHOD': {
    'id': 'BQHUPY',
    'template': "This is the overridden method '#{name}' declared in class "
        "'#{class}'.",
  },

  'INVALID_OVERRIDE_GETTER': {
    'id': 'KLMPWO',
    'template': "The type '#{declaredType}' of getter '#{name}' declared in "
        "'#{class}' is not assignable to the type '#{inheritedType}' of the "
        "overridden getter inherited from '#{inheritedClass}'.",
  },

  'INVALID_OVERRIDDEN_GETTER': {
    'id': 'ASSKCT',
    'template': "This is the overridden getter '#{name}' declared in class "
        "'#{class}'.",
  },

  'INVALID_OVERRIDE_GETTER_WITH_FIELD': {
    'id': 'TCCGXU',
    'template': "The type '#{declaredType}' of field '#{name}' declared in "
        "'#{class}' is not assignable to the type '#{inheritedType}' of the "
        "overridden getter inherited from '#{inheritedClass}'.",
  },

  'INVALID_OVERRIDE_FIELD_WITH_GETTER': {
    'id': 'UMMEXO',
    'template': "The type '#{declaredType}' of getter '#{name}' declared in "
        "'#{class}' is not assignable to the type '#{inheritedType}' of the "
        "overridden field inherited from '#{inheritedClass}'.",
  },

  'INVALID_OVERRIDE_SETTER': {
    'id': 'BWRGEC',
    'template': "The type '#{declaredType}' of setter '#{name}' declared in "
        "'#{class}' is not assignable to the type '#{inheritedType}' of the "
        "overridden setter inherited from '#{inheritedClass}'.",
  },

  'INVALID_OVERRIDDEN_SETTER': {
    'id': 'XQUOLL',
    'template': "This is the overridden setter '#{name}' declared in class "
        "'#{class}'.",
  },

  'INVALID_OVERRIDE_SETTER_WITH_FIELD': {
    'id': 'GKGOFA',
    'template': "The type '#{declaredType}' of field '#{name}' declared in "
        "'#{class}' is not assignable to the type '#{inheritedType}' of the "
        "overridden setter inherited from '#{inheritedClass}'.",
  },

  'INVALID_OVERRIDE_FIELD_WITH_SETTER': {
    'id': 'OOXKHQ',
    'template': "The type '#{declaredType}' of setter '#{name}' declared in "
        "'#{class}' is not assignable to the type '#{inheritedType}' of the "
        "overridden field inherited from '#{inheritedClass}'.",
  },

  'INVALID_OVERRIDE_FIELD': {
    'id': 'LDPKOL',
    'template': "The type '#{declaredType}' of field '#{name}' declared in "
        "'#{class}' is not assignable to the type '#{inheritedType}' of the "
        "overridden field inherited from '#{inheritedClass}'.",
  },

  'INVALID_OVERRIDDEN_FIELD': {
    'id': 'UNQFWX',
    'template': "This is the overridden field '#{name}' declared in class "
        "'#{class}'.",
  },

  'CANNOT_OVERRIDE_FIELD_WITH_METHOD': {
    'id': 'SYKCSK',
    'template': "Method '#{name}' in '#{class}' can't override field from "
        "'#{inheritedClass}'.",
  },

  'CANNOT_OVERRIDE_FIELD_WITH_METHOD_CONT': {
    'id': 'HYHQSO',
    'template': "This is the field that cannot be overridden by a method.",
  },

  'CANNOT_OVERRIDE_METHOD_WITH_FIELD': {
    'id': 'UROMAS',
    'template': "Field '#{name}' in '#{class}' can't override method from "
        "'#{inheritedClass}'.",
  },

  'CANNOT_OVERRIDE_METHOD_WITH_FIELD_CONT': {
    'id': 'NSORYS',
    'template': "This is the method that cannot be overridden by a field.",
  },

  'CANNOT_OVERRIDE_GETTER_WITH_METHOD': {
    'id': 'MMFIOH',
    'template': "Method '#{name}' in '#{class}' can't override getter from "
        "'#{inheritedClass}'.",
  },

  'CANNOT_OVERRIDE_GETTER_WITH_METHOD_CONT': {
    'id': 'YGWPDH',
    'template': "This is the getter that cannot be overridden by a method.",
  },

  'CANNOT_OVERRIDE_METHOD_WITH_GETTER': {
    'id': 'BNKNXO',
    'template': "Getter '#{name}' in '#{class}' can't override method from "
        "'#{inheritedClass}'.",
  },

  'CANNOT_OVERRIDE_METHOD_WITH_GETTER_CONT': {
    'id': 'KFBCYX',
    'template': "This is the method that cannot be overridden by a getter.",
  },

  'MISSING_FORMALS': {
    'id': 'BOERAF',
    'template': "Formal parameters are missing.",
  },

  'EXTRA_FORMALS': {
    'id': 'UTWRIU',
    'template': "Formal parameters are not allowed here.",
  },

  'UNARY_OPERATOR_BAD_ARITY': {
    'id': 'TNHLAL',
    'template': "Operator '#{operatorName}' must have no parameters.",
  },

  'MINUS_OPERATOR_BAD_ARITY': {
    'id': 'SXDRRU',
    'template': "Operator '-' must have 0 or 1 parameters.",
  },

  'BINARY_OPERATOR_BAD_ARITY': {
    'id': 'QKWAUM',
    'template': "Operator '#{operatorName}' must have exactly 1 parameter.",
  },

  'TERNARY_OPERATOR_BAD_ARITY': {
    'id': 'LSMQGF',
    'template': "Operator '#{operatorName}' must have exactly 2 parameters.",
  },

  'OPERATOR_OPTIONAL_PARAMETERS': {
    'id': 'HSGRBV',
    'template': "Operator '#{operatorName}' cannot have optional parameters.",
  },

  'OPERATOR_NAMED_PARAMETERS': {
    'id': 'EACWGS',
    'template': "Operator '#{operatorName}' cannot have named parameters.",
  },

  'CONSTRUCTOR_WITH_RETURN_TYPE': {
    'id': 'OPMBHF',
    'template': "Cannot have return type for constructor.",
  },

  'CANNOT_RETURN_FROM_CONSTRUCTOR': {
    'id': 'NFUGNH',
    'template': "Constructors can't return values.",
    'howToFix': "Remove the return statement or use a factory constructor.",
    'examples': [
      """
class C {
C() {
  return 1;
}
}

main() => new C();"""
    ],
  },

  'ILLEGAL_FINAL_METHOD_MODIFIER': {
    'id': 'YUKCVU',
    'template': "Cannot have final modifier on method.",
  },

  'ILLEGAL_CONST_FIELD_MODIFIER': {
    'id': 'JGFAGV',
    'template': "Cannot have const modifier on non-static field.",
    'howToFix': "Try adding a static modifier, or removing the const modifier.",
    'examples': [
      """
class C {
const int a = 1;
}

main() => new C();"""
    ],
  },

  'ILLEGAL_CONSTRUCTOR_MODIFIERS': {
    'id': 'WODRHN',
    'template': "Illegal constructor modifiers: '#{modifiers}'.",
  },

  'ILLEGAL_MIXIN_APPLICATION_MODIFIERS': {
    'id': 'OFLFHN',
    'template': "Illegal mixin application modifiers: '#{modifiers}'.",
  },

  'ILLEGAL_MIXIN_SUPERCLASS': {
    'id': 'TPVVYN',
    'template': "Class used as mixin must have Object as superclass.",
  },

  'ILLEGAL_MIXIN_OBJECT': {
    'id': 'CMVTLF',
    'template': "Cannot use Object as mixin.",
  },

  'ILLEGAL_MIXIN_CONSTRUCTOR': {
    'id': 'HXBUIB',
    'template': "Class used as mixin cannot have non-factory constructor.",
  },

  'ILLEGAL_MIXIN_CYCLE': {
    'id': 'ANXAMU',
    'template': "Class used as mixin introduces mixin cycle: "
        "'#{mixinName1}' <-> '#{mixinName2}'.",
  },

  'ILLEGAL_MIXIN_WITH_SUPER': {
    'id': 'KIEUGK',
    'template': "Cannot use class '#{className}' as a mixin because it uses "
        "'super'.",
  },

  'ILLEGAL_MIXIN_SUPER_USE': {
    'id': 'QKUPLH',
    'template': "Use of 'super' in class used as mixin.",
  },

  'PARAMETER_NAME_EXPECTED': {
    'id': 'JOUOBT',
    'template': "parameter name expected.",
  },

  'CANNOT_RESOLVE_GETTER': {
    'id': 'TDHKSW',
    'template': "Cannot resolve getter.",
  },

  'CANNOT_RESOLVE_SETTER': {
    'id': 'QQFANP',
    'template': "Cannot resolve setter.",
  },

  'ASSIGNING_FINAL_FIELD_IN_SUPER': {
    'id': 'LXUPCC',
    'template': "Cannot assign a value to final field '#{name}' "
        "in superclass '#{superclassName}'.",
  },

  'ASSIGNING_METHOD': {
    'id': 'JUVMYC',
    'template': "Cannot assign a value to a method.",
  },

  'ASSIGNING_METHOD_IN_SUPER': {
    'id': 'AGMAXN',
    'template': "Cannot assign a value to method '#{name}' "
        "in superclass '#{superclassName}'.",
  },

  'ASSIGNING_TYPE': {
    'id': 'VXTPWE',
    'template': "Cannot assign a value to a type.",
  },

  'IF_NULL_ASSIGNING_TYPE': {
    'id': 'XBRHGK',
    'template':
        "Cannot assign a value to a type. Note that types are never null, "
        "so this ??= assignment has no effect.",
    'howToFix': "Try removing the '??=' assignment.",
    'examples': ["class A {} main() { print(A ??= 3);}",],
  },

  'VOID_NOT_ALLOWED': {
    'id': 'DMMDXT',
    'template':
        "Type 'void' can't be used here because it isn't a return type.",
    'howToFix':
        "Try removing 'void' keyword or replace it with 'var', 'final', "
        "or a type.",
    'examples': ["void x; main() {}", "foo(void x) {} main() { foo(null); }",],
  },

  'NULL_NOT_ALLOWED': {
    'id': 'STYNSK',
    'template': "`null` can't be used here.",
  },

  'BEFORE_TOP_LEVEL': {
    'id': 'GRCXQF',
    'template': "Part header must come before top-level definitions.",
  },

  'IMPORT_PART_OF': {
    'id': 'VANCWE',
    'template': "The imported library must not have a 'part-of' directive.",
    'howToFix': "Try removing the 'part-of' directive or replacing the "
        "import of the library with a 'part' directive.",
    'examples': [
      {
        'main.dart': """
library library;

import 'part.dart';

main() {}
""",
        'part.dart': """
part of library;
"""
      }
    ],
  },

  'IMPORT_PART_OF_HERE': {
    'id': 'TRSZOJ',
    'template': 'The library is imported here.',
  },

  'MAIN_HAS_PART_OF': {
    'id': 'MFMRRL',
    'template': "The main application file must not have a 'part-of' "
                "directive.",
    'howToFix': "Try removing the 'part-of' directive or starting compilation "
                "from another file.",
    'examples': [
      {
        'main.dart': """
part of library;

main() {}
"""
      }
    ],
  },

  'LIBRARY_NAME_MISMATCH': {
    'id': 'AXGYPQ',
    'template': "Expected part of library name '#{libraryName}'.",
    'howToFix': "Try changing the directive to 'part of #{libraryName};'.",
    'examples': [
      {
        'main.dart': """
library lib.foo;

part 'part.dart';

main() {}
""",
        'part.dart': """
part of lib.bar;
"""
      }
    ],
  },

  'MISSING_LIBRARY_NAME': {
    'id': 'NYQNCA',
    'template': "Library has no name. Part directive expected library name "
        "to be '#{libraryName}'.",
    'howToFix': "Try adding 'library #{libraryName};' to the library.",
    'examples': [
      {
        'main.dart': """
part 'part.dart';

main() {}
""",
        'part.dart': """
part of lib.foo;
"""
      }
    ],
  },

  'THIS_IS_THE_PART_OF_TAG': {
    'id': 'RPSJRS',
    'template': "This is the part of directive.",
  },

  'MISSING_PART_OF_TAG': {
    'id': 'QNYCMV',
    'template': "This file has no part-of tag, but it is being used as a part.",
  },

  'DUPLICATED_PART_OF': {
    'id': 'UJDYHF',
    'template': "Duplicated part-of directive.",
  },

  'DUPLICATED_LIBRARY_NAME': {
    'id': 'OSEHXI',
    'template': "Duplicated library name '#{libraryName}'.",
  },

  'DUPLICATED_RESOURCE': {
    'id': 'UFWKBY',
    'template': "The resource '#{resourceUri}' is loaded through both "
        "'#{canonicalUri1}' and '#{canonicalUri2}'.",
  },

  'DUPLICATED_LIBRARY_RESOURCE': {
    'id': 'KYGYTT',
    'template':
        "The library '#{libraryName}' in '#{resourceUri}' is loaded through "
        "both '#{canonicalUri1}' and '#{canonicalUri2}'.",
  },

  // This is used as an exception.
  'INVALID_SOURCE_FILE_LOCATION': {
    'id': 'WIGJFG',
    'template': """
Invalid offset (#{offset}) in source map.
File: #{fileName}
Length: #{length}""",
  },

  'TOP_LEVEL_VARIABLE_DECLARED_STATIC': {
    'id': 'IVNDML',
    'template': "Top-level variable cannot be declared static.",
  },

  'REFERENCE_IN_INITIALIZATION': {
    'id': 'OVWTEU',
    'template': "Variable '#{variableName}' is referenced during its "
        "initialization.",
    'howToFix': "If you are trying to reference a shadowed variable, rename "
        "one of the variables.",
    'examples': [
      """
foo(t) {
var t = t;
return t;
}

main() => foo(1);
"""
    ],
  },

  'CONST_WITHOUT_INITIALIZER': {
    'id': 'UDWCNH',
    'template': "A constant variable must be initialized.",
    'howToFix': "Try adding an initializer or "
        "removing the 'const' modifier.",
    'examples': [
      """
void main() {
const c; // This constant variable must be initialized.
}"""
    ],
  },

  'FINAL_WITHOUT_INITIALIZER': {
    'id': 'YMESFI',
    'template': "A final variable must be initialized.",
    'howToFix': "Try adding an initializer or "
        "removing the 'final' modifier.",
    'examples': ["class C { static final field; } main() => C.field;"],
  },

  'CONST_LOOP_VARIABLE': {
    'id': 'WUSKMG',
    'template': "A loop variable cannot be constant.",
    'howToFix': "Try remove the 'const' modifier or "
        "replacing it with a 'final' modifier.",
    'examples': [
      """
void main() {
  for (const c in []) {}
}"""
    ],
  },

  'MEMBER_USES_CLASS_NAME': {
    'id': 'TVFYRK',
    'template': "Member variable can't have the same name as the class it is "
        "declared in.",
    'howToFix': "Try renaming the variable.",
    'examples': [
      """
class A { var A; }
main() {
var a = new A();
a.A = 1;
}
""",
      """
class A { static var A; }
main() => A.A = 1;
"""
    ],
  },

  'WRONG_NUMBER_OF_ARGUMENTS_FOR_ASSERT': {
    'id': 'IXYNUF',
    'template': "Wrong number of arguments to assert. Should be 1, but given "
        "#{argumentCount}.",
  },

  'ASSERT_IS_GIVEN_NAMED_ARGUMENTS': {
    'id': 'EJFDTO',
    'template':
        "'assert' takes no named arguments, but given #{argumentCount}.",
  },

  'FACTORY_REDIRECTION_IN_NON_FACTORY': {
    'id': 'DTBWEX',
    'template': "Factory redirection only allowed in factories.",
  },

  'MISSING_FACTORY_KEYWORD': {
    'id': 'HOQYYA',
    'template': "Did you forget a factory keyword here?",
  },

  'NO_SUCH_METHOD_IN_NATIVE': {
    'id': 'MSDDBX',
    'template':
        "'NoSuchMethod' is not supported for classes that extend native "
        "classes.",
  },

  'DEFERRED_LIBRARY_DART_2_DART': {
    'id': 'RIRQAH',
    'template': "Deferred loading is not supported by the dart backend yet. "
        "The output will not be split.",
  },

  'DEFERRED_LIBRARY_WITHOUT_PREFIX': {
    'id': 'CARRII',
    'template': "This import is deferred but there is no prefix keyword.",
    'howToFix': "Try adding a prefix to the import."
  },

  'DEFERRED_OLD_SYNTAX': {
    'id': 'QCBRAE',
    'template': "The DeferredLibrary annotation is obsolete.",
    'howToFix':
        "Use the \"import 'lib.dart' deferred as prefix\" syntax instead.",
  },

  'DEFERRED_LIBRARY_DUPLICATE_PREFIX': {
    'id': 'BBMJTD',
    'template': "The prefix of this deferred import is not unique.",
    'howToFix': "Try changing the import prefix."
  },

  'DEFERRED_TYPE_ANNOTATION': {
    'id': 'JOUEFD',
    'template': "The type #{node} is deferred. "
        "Deferred types are not valid as type annotations.",
    'howToFix': "Try using a non-deferred abstract class as an interface.",
  },

  'ILLEGAL_STATIC': {
    'id': 'HFBHVE',
    'template': "Modifier static is only allowed on functions declared in "
        "a class.",
  },

  'STATIC_FUNCTION_BLOAT': {
    'id': 'SJHTKF',
    'template': "Using '#{class}.#{name}' may lead to unnecessarily large "
        "generated code.",
    'howToFix': "Try adding '@MirrorsUsed(...)' as described at "
        "https://goo.gl/Akrrog.",
  },

  'NON_CONST_BLOAT': {
    'id': 'RDRSHO',
    'template': "Using 'new #{name}' may lead to unnecessarily large generated "
        "code.",
    'howToFix': "Try using 'const #{name}' or adding '@MirrorsUsed(...)' as "
        "described at https://goo.gl/Akrrog.",
  },

  'STRING_EXPECTED': {
    'id': 'OEJOOI',
    'template': "Expected a 'String', but got an instance of '#{type}'.",
  },

  'PRIVATE_IDENTIFIER': {
    'id': 'XAHVWI',
    'template': "'#{value}' is not a valid Symbol name because it starts with "
        "'_'.",
  },

  'PRIVATE_NAMED_PARAMETER': {
    'id': 'VFGCLK',
    'template': "Named optional parameter can't have a library private name.",
    'howToFix': "Try removing the '_' or making the parameter positional or "
        "required.",
    'examples': ["""foo({int _p}) {} main() => foo();"""],
  },

  'UNSUPPORTED_LITERAL_SYMBOL': {
    'id': 'OYCDII',
    'template':
        "Symbol literal '##{value}' is currently unsupported by dart2js.",
  },

  'INVALID_SYMBOL': {
    'id': 'RUXMBL',
    'template': '''
'#{value}' is not a valid Symbol name because is not:
* an empty String,
* a user defined operator,
* a qualified non-private identifier optionally followed by '=', or
* a qualified non-private identifier followed by '.' and a user-defined '''
        "operator.",
  },

  'AMBIGUOUS_REEXPORT': {
    'id': 'YNTOND',
    'template': "'#{name}' is (re)exported by multiple libraries.",
  },

  'AMBIGUOUS_LOCATION': {
    'id': 'SKLTYA',
    'template': "'#{name}' is defined here.",
  },

  'IMPORTED_HERE': {'id': 'IMUXAE', 'template': "'#{name}' is imported here.",},

  'OVERRIDE_EQUALS_NOT_HASH_CODE': {
    'id': 'MUHYXI',
    'template': "The class '#{class}' overrides 'operator==', "
        "but not 'get hashCode'.",
  },

  'INTERNAL_LIBRARY_FROM': {
    'id': 'RXOCLX',
    'template': "Internal library '#{resolvedUri}' is not accessible from "
        "'#{importingUri}'.",
  },

  'INTERNAL_LIBRARY': {
    'id': 'SYLJAV',
    'template': "Internal library '#{resolvedUri}' is not accessible.",
  },

  'JS_INTEROP_CLASS_CANNOT_EXTEND_DART_CLASS': {
    'id': 'LSHKJK',
    'template':
        "Js-interop class '#{cls}' cannot extend from the non js-interop "
        "class '#{superclass}'.",
    'howToFix': "Annotate the superclass with @JS.",
    'examples': [
      """
            import 'package:js/js.dart';

            class Foo { }

            @JS()
            class Bar extends Foo { }

            main() {
              new Bar();
            }
            """
    ],
  },

  'JS_INTEROP_CLASS_NON_EXTERNAL_MEMBER': {
    'id': 'QLLLEE',
    'template':
        "Member '#{member}' in js-interop class '#{cls}' is not external.",
    'howToFix': "Mark all interop methods external",
    'examples': [
      """
            import 'package:js/js.dart';

            @JS()
            class Foo {
              bar() {}
            }

            main() {
              new Foo().bar();
            }
            """
    ],
  },

  'JS_INTEROP_METHOD_WITH_NAMED_ARGUMENTS': {
    'id': 'TDQHRY',
    'template': "Js-interop method '#{method}' has named arguments but is not "
        "a factory constructor of an @anonymous @JS class.",
    'howToFix': "Remove all named arguments from js-interop method or "
        "in the case of a factory constructor annotate the class "
        "as @anonymous.",
    'examples': [
      """
            import 'package:js/js.dart';

            @JS()
            class Foo {
              external bar(foo, {baz});
            }

            main() {
              new Foo().bar(4, baz: 5);
            }
            """
    ],
  },

  'JS_OBJECT_LITERAL_CONSTRUCTOR_WITH_POSITIONAL_ARGUMENTS': {
    'id': 'EHEKUY',
    'template':
        "Parameter '#{parameter}' in anonymous js-interop class '#{cls}' "
        "object literal constructor is positional instead of named."
        ".",
    'howToFix': "Make all arguments in external factory object literal "
        "constructors named.",
    'examples': [
      """
            import 'package:js/js.dart';

            @anonymous
            @JS()
            class Foo {
              external factory Foo(foo, {baz});
            }

            main() {
              new Foo(5, baz: 5);
            }
            """
    ],
  },

  'LIBRARY_NOT_FOUND': {
    'id': 'BARPSL',
    'template': "Library not found '#{resolvedUri}'.",
  },

  'LIBRARY_NOT_SUPPORTED': {
    'id': 'GDXUNS',
    'template': "Library not supported '#{resolvedUri}'.",
    'howToFix': "Try removing the dependency or enabling support using "
        "the '--categories' option.",
    'examples': [
//            """
//            import 'dart:io';
//            main() {}
//            """
    ],
    // TODO(johnniwinther): Enable example when message_kind_test.dart
    // supports library loader callbacks.
  },

  'UNSUPPORTED_EQ_EQ_EQ': {
    'id': 'GPOVNO',
    'template': "'===' is not an operator. "
        "Did you mean '#{lhs} == #{rhs}' or 'identical(#{lhs}, #{rhs})'?",
  },

  'UNSUPPORTED_BANG_EQ_EQ': {
    'id': 'HDYKMV',
    'template': "'!==' is not an operator. "
        "Did you mean '#{lhs} != #{rhs}' or '!identical(#{lhs}, #{rhs})'?",
  },

  'UNSUPPORTED_PREFIX_PLUS': {
    'id': 'LSQTHP',
    'template': "'+' is not a prefix operator. ",
    'howToFix': "Try removing '+'.",
    'examples': ["main() => +2;  // No longer a valid way to write '2'"],
  },

  'UNSUPPORTED_THROW_WITHOUT_EXP': {
    'id': 'QOAKGE',
    'template': "No expression after 'throw'. "
        "Did you mean 'rethrow'?",
  },

  'DEPRECATED_TYPEDEF_MIXIN_SYNTAX': {
    'id': 'BBGGFE',
    'template': "'typedef' not allowed here. ",
    'howToFix': "Try replacing 'typedef' with 'class'.",
    'examples': [
      """
class B { }
class M1 {  }
typedef C = B with M1;  // Need to replace 'typedef' with 'class'.
main() { new C(); }
"""
    ],
  },

  'MIRRORS_EXPECTED_STRING': {
    'id': 'XSKTIB',
    'template':
        "Can't use '#{name}' here because it's an instance of '#{type}' "
        "and a 'String' value is expected.",
    'howToFix': "Did you forget to add quotes?",
    'examples': [
      """
// 'Foo' is a type literal, not a string.
@MirrorsUsed(symbols: const [Foo])
import 'dart:mirrors';

class Foo {}

main() {}
"""
    ],
  },

  'MIRRORS_EXPECTED_STRING_OR_TYPE': {
    'id': 'JQDJPL',
    'template':
        "Can't use '#{name}' here because it's an instance of '#{type}' "
        "and a 'String' or 'Type' value is expected.",
    'howToFix': "Did you forget to add quotes?",
    'examples': [
      """
// 'main' is a method, not a class.
@MirrorsUsed(targets: const [main])
import 'dart:mirrors';

main() {}
"""
    ],
  },

  'MIRRORS_EXPECTED_STRING_OR_LIST': {
    'id': 'UVYCOE',
    'template':
        "Can't use '#{name}' here because it's an instance of '#{type}' "
        "and a 'String' or 'List' value is expected.",
    'howToFix': "Did you forget to add quotes?",
    'examples': [
      """
// 'Foo' is not a string.
@MirrorsUsed(symbols: Foo)
import 'dart:mirrors';

class Foo {}

main() {}
"""
    ],
  },

  'MIRRORS_EXPECTED_STRING_TYPE_OR_LIST': {
    'id': 'WSYDFL',
    'template':
        "Can't use '#{name}' here because it's an instance of '#{type}' "
        "but a 'String', 'Type', or 'List' value is expected.",
    'howToFix': "Did you forget to add quotes?",
    'examples': [
      """
// '1' is not a string.
@MirrorsUsed(targets: 1)
import 'dart:mirrors';

main() {}
"""
    ],
  },

  'MIRRORS_CANNOT_RESOLVE_IN_CURRENT_LIBRARY': {
    'id': 'VDBBNE',
    'template': "Can't find '#{name}' in the current library.",
    // TODO(ahe): The closest identifiers in edit distance would be nice.
    'howToFix': "Did you forget to add an import?",
    'examples': [
      """
// 'window' is not in scope because dart:html isn't imported.
@MirrorsUsed(targets: 'window')
import 'dart:mirrors';

main() {}
"""
    ],
  },

  'MIRRORS_CANNOT_RESOLVE_IN_LIBRARY': {
    'id': 'RUEKXE',
    'template': "Can't find '#{name}' in the library '#{library}'.",
    // TODO(ahe): The closest identifiers in edit distance would be nice.
    'howToFix': "Is '#{name}' spelled right?",
    'examples': [
      """
// 'List' is misspelled.
@MirrorsUsed(targets: 'dart.core.Lsit')
import 'dart:mirrors';

main() {}
"""
    ],
  },

  'MIRRORS_CANNOT_FIND_IN_ELEMENT': {
    'id': 'ACPDCS',
    'template': "Can't find '#{name}' in '#{element}'.",
    // TODO(ahe): The closest identifiers in edit distance would be nice.
    'howToFix': "Is '#{name}' spelled right?",
    'examples': [
      """
// 'addAll' is misspelled.
@MirrorsUsed(targets: 'dart.core.List.addAl')
import 'dart:mirrors';

main() {}
"""
    ],
  },

  'INVALID_URI': {
    'id': 'QQEQMK',
    'template': "'#{uri}' is not a valid URI.",
    'howToFix': DONT_KNOW_HOW_TO_FIX,
    'examples': [
      """
// can't have a '[' in a URI
import '../../Udyn[mic ils/expect.dart';

main() {}
"""
    ],
  },

  'INVALID_PACKAGE_CONFIG': {
    'id': 'XKFAJO',
    'template': """Package config file '#{uri}' is invalid.
#{exception}""",
    'howToFix': DONT_KNOW_HOW_TO_FIX
  },

  'INVALID_PACKAGE_URI': {
    'id': 'MFVNNJ',
    'template': "'#{uri}' is not a valid package URI (#{exception}).",
    'howToFix': DONT_KNOW_HOW_TO_FIX,
    'examples': [
      """
// can't have a 'top level' package URI
import 'package:foo.dart';

main() {}
""",
      """
// can't have 2 slashes
import 'package://foo/foo.dart';

main() {}
""",
      """
// package name must be valid
import 'package:not\valid/foo.dart';

main() {}
"""
    ],
  },

  'READ_SCRIPT_ERROR': {
    'id': 'JDDYLH',
    'template': "Can't read '#{uri}' (#{exception}).",
    // Don't know how to fix since the underlying error is unknown.
    'howToFix': DONT_KNOW_HOW_TO_FIX,
    'examples': [
      """
// 'foo.dart' does not exist.
import 'foo.dart';

main() {}
"""
    ],
  },

  'READ_SELF_ERROR': {
    'id': 'CRJUAV',
    'template': "#{exception}",
    // Don't know how to fix since the underlying error is unknown.
    'howToFix': DONT_KNOW_HOW_TO_FIX
  },

  'EXTRANEOUS_MODIFIER': {
    'id': 'DPLVJG',
    'template': "Can't have modifier '#{modifier}' here.",
    'howToFix': "Try removing '#{modifier}'.",
    'examples': [
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
    ],
  },

  'EXTRANEOUS_MODIFIER_REPLACE': {
    'id': 'SSXDLN',
    'template': "Can't have modifier '#{modifier}' here.",
    'howToFix': "Try replacing modifier '#{modifier}' with 'var', 'final', "
        "or a type.",
    'examples': [
      // "get foo; main(){}",
      "set foo; main(){}",
      "abstract foo; main(){}",
      "static foo; main(){}",
      "external foo; main(){}"
    ],
  },

  'ABSTRACT_CLASS_INSTANTIATION': {
    'id': 'KOBCRO',
    'template': "Can't instantiate abstract class.",
    'howToFix': DONT_KNOW_HOW_TO_FIX,
    'examples': ["abstract class A {} main() { new A(); }"],
  },

  'BODY_EXPECTED': {
    'id': 'YXCAHO',
    'template': "Expected a function body or '=>'.",
    // TODO(ahe): In some scenarios, we can suggest removing the 'static'
    // keyword.
    'howToFix': "Try adding {}.",
    'examples': ["main();"],
  },

  'MIRROR_BLOAT': {
    'id': 'BSEAIT',
    'template':
        "#{count} methods retained for use by dart:mirrors out of #{total}"
        " total methods (#{percentage}%).",
  },

  'MIRROR_IMPORT': {'id': 'BDAETE', 'template': "Import of 'dart:mirrors'.",},

  'MIRROR_IMPORT_NO_USAGE': {
    'id': 'OJOHTR',
    'template':
        "This import is not annotated with @MirrorsUsed, which may lead to "
        "unnecessarily large generated code.",
    'howToFix': "Try adding '@MirrorsUsed(...)' as described at "
        "https://goo.gl/Akrrog.",
  },

  'JS_PLACEHOLDER_CAPTURE': {
    'id': 'EJXEGQ',
    'template': "JS code must not use '#' placeholders inside functions.",
    'howToFix': "Use an immediately called JavaScript function to capture the"
        " the placeholder values as JavaScript function parameters.",
  },

  'WRONG_ARGUMENT_FOR_JS_INTERCEPTOR_CONSTANT': {
    'id': 'JHRISO',
    'template':
        "Argument for 'JS_INTERCEPTOR_CONSTANT' must be a type constant.",
  },

  'EXPECTED_IDENTIFIER_NOT_RESERVED_WORD': {
    'id': 'FEJXJF',
    'template': "'#{keyword}' is a reserved word and can't be used here.",
    'howToFix': "Try using a different name.",
    'examples': ["do() {} main() {}"],
  },

  'NAMED_FUNCTION_EXPRESSION': {
    'id': 'CTHFPI',
    'template': "Function expression '#{name}' cannot be named.",
    'howToFix': "Try removing the name.",
    'examples': ["main() { var f = func() {}; }"],
  },

  'UNUSED_METHOD': {
    'id': 'PKLRQL',
    'template': "The method '#{name}' is never called.",
    'howToFix': "Consider deleting it.",
    'examples': ["deadCode() {} main() {}"],
  },

  'UNUSED_CLASS': {
    'id': 'TBIECC',
    'template': "The class '#{name}' is never used.",
    'howToFix': "Consider deleting it.",
    'examples': ["class DeadCode {} main() {}"],
  },

  'UNUSED_TYPEDEF': {
    'id': 'JBIPCN',
    'template': "The typedef '#{name}' is never used.",
    'howToFix': "Consider deleting it.",
    'examples': ["typedef DeadCode(); main() {}"],
  },

  'ABSTRACT_METHOD': {
    'id': 'HOKOBG',
    'template': "The method '#{name}' has no implementation in "
        "class '#{class}'.",
    'howToFix': "Try adding a body to '#{name}' or declaring "
        "'#{class}' to be 'abstract'.",
    'examples': [
      """
class Class {
method();
}
main() => new Class().method();
"""
    ],
  },

  'ABSTRACT_GETTER': {
    'id': 'VKTRNK',
    'template': "The getter '#{name}' has no implementation in "
        "class '#{class}'.",
    'howToFix': "Try adding a body to '#{name}' or declaring "
        "'#{class}' to be 'abstract'.",
    'examples': [
      """
class Class {
get getter;
}
main() => new Class();
"""
    ],
  },

  'ABSTRACT_SETTER': {
    'id': 'XGDGKK',
    'template': "The setter '#{name}' has no implementation in "
        "class '#{class}'.",
    'howToFix': "Try adding a body to '#{name}' or declaring "
        "'#{class}' to be 'abstract'.",
    'examples': [
      """
class Class {
set setter(_);
}
main() => new Class();
"""
    ],
  },

  'INHERIT_GETTER_AND_METHOD': {
    'id': 'UMEUEG',
    'template': "The class '#{class}' can't inherit both getters and methods "
        "by the named '#{name}'.",
    'howToFix': DONT_KNOW_HOW_TO_FIX,
    'examples': [
      """
class A {
get member => null;
}
class B {
member() {}
}
class Class implements A, B {
}
main() => new Class();
"""
    ],
  },

  'INHERITED_METHOD': {
    'id': 'GMSVBM',
    'template': "The inherited method '#{name}' is declared here in class "
        "'#{class}'.",
  },

  'INHERITED_EXPLICIT_GETTER': {
    'id': 'KKAVRS',
    'template': "The inherited getter '#{name}' is declared here in class "
        "'#{class}'.",
  },

  'INHERITED_IMPLICIT_GETTER': {
    'id': 'JBAMEJ',
    'template': "The inherited getter '#{name}' is implicitly declared by this "
        "field in class '#{class}'.",
  },

  'UNIMPLEMENTED_METHOD_ONE': {
    'id': 'CMCLWO',
    'template': "'#{class}' doesn't implement '#{method}' "
        "declared in '#{declarer}'.",
    'howToFix': "Try adding an implementation of '#{name}' or declaring "
        "'#{class}' to be 'abstract'.",
    'examples': [
      """
abstract class I {
m();
}
class C implements I {}
main() => new C();
""",
      """
abstract class I {
m();
}
class C extends I {}
main() => new C();
"""
    ],
  },

  'UNIMPLEMENTED_METHOD': {
    'id': 'IJSNQB',
    'template': "'#{class}' doesn't implement '#{method}'.",
    'howToFix': "Try adding an implementation of '#{name}' or declaring "
        "'#{class}' to be 'abstract'.",
    'examples': [
      """
abstract class I {
m();
}

abstract class J {
m();
}

class C implements I, J {}

main() {
new C();
}
""",
      """
abstract class I {
m();
}

abstract class J {
m();
}

class C extends I implements J {}

main() {
new C();
}
"""
    ],
  },

  'UNIMPLEMENTED_METHOD_CONT': {
    'id': 'KFBKPO',
    'template': "The method '#{name}' is declared here in class '#{class}'.",
  },

  'UNIMPLEMENTED_SETTER_ONE': {
    'id': 'QGKTEA',
    'template': "'#{class}' doesn't implement the setter '#{name}' "
        "declared in '#{declarer}'.",
    'howToFix': "Try adding an implementation of '#{name}' or declaring "
        "'#{class}' to be 'abstract'.",
    'examples': [
      """
abstract class I {
set m(_);
}
class C implements I {}
class D implements I {
set m(_) {}
}
main() {
new D().m = 0;
new C();
}
"""
    ],
  },

  'UNIMPLEMENTED_SETTER': {
    'id': 'VEEGJQ',
    'template': "'#{class}' doesn't implement the setter '#{name}'.",
    'howToFix': "Try adding an implementation of '#{name}' or declaring "
        "'#{class}' to be 'abstract'.",
    'examples': [
      """
abstract class I {
set m(_);
}
abstract class J {
set m(_);
}
class C implements I, J {}
main() => new C();
""",
      """
abstract class I {
set m(_);
}
abstract class J {
set m(_);
}
class C extends I implements J {}
main() => new C();
"""
    ],
  },

  'UNIMPLEMENTED_EXPLICIT_SETTER': {
    'id': 'SABABA',
    'template': "The setter '#{name}' is declared here in class '#{class}'.",
  },

  'UNIMPLEMENTED_IMPLICIT_SETTER': {
    'id': 'SWESAQ',
    'template': "The setter '#{name}' is implicitly declared by this field "
        "in class '#{class}'.",
  },

  'UNIMPLEMENTED_GETTER_ONE': {
    'id': 'ODEPFW',
    'template': "'#{class}' doesn't implement the getter '#{name}' "
        "declared in '#{declarer}'.",
    'howToFix': "Try adding an implementation of '#{name}' or declaring "
        "'#{class}' to be 'abstract'.",
    'examples': [
      """
abstract class I {
get m;
}
class C implements I {}
main() => new C();
""",
      """
abstract class I {
get m;
}
class C extends I {}
main() => new C();
"""
    ],
  },

  'UNIMPLEMENTED_GETTER': {
    'id': 'VHSECG',
    'template': "'#{class}' doesn't implement the getter '#{name}'.",
    'howToFix': "Try adding an implementation of '#{name}' or declaring "
        "'#{class}' to be 'abstract'.",
    'examples': [
      """
abstract class I {
get m;
}
abstract class J {
get m;
}
class C implements I, J {}
main() => new C();
""",
      """
abstract class I {
get m;
}
abstract class J {
get m;
}
class C extends I implements J {}
main() => new C();
"""
    ],
  },

  'UNIMPLEMENTED_EXPLICIT_GETTER': {
    'id': 'HFDJPP',
    'template': "The getter '#{name}' is declared here in class '#{class}'.",
  },

  'UNIMPLEMENTED_IMPLICIT_GETTER': {
    'id': 'BSCQNO',
    'template': "The getter '#{name}' is implicitly declared by this field "
        "in class '#{class}'.",
  },

  'INVALID_METADATA': {
    'id': 'RKJGDE',
    'template':
        "A metadata annotation must be either a reference to a compile-time "
        "constant variable or a call to a constant constructor.",
    'howToFix':
        "Try using a different constant value or referencing it through a "
        "constant variable.",
    'examples': [
'@Object main() {}',
'@print main() {}']
  },

  'INVALID_METADATA_GENERIC': {
    'id': 'WEEDQD',
    'template':
        "A metadata annotation using a constant constructor cannot use type "
        "arguments.",
    'howToFix':
        "Try removing the type arguments or referencing the constant "
        "through a constant variable.",
    'examples': [
      '''
class C<T> {
  const C();
}
@C<int>() main() {}
'''],
  },

  'EQUAL_MAP_ENTRY_KEY': {
    'id': 'KIDLPM',
    'template': "An entry with the same key already exists in the map.",
    'howToFix': "Try removing the previous entry or changing the key in one "
        "of the entries.",
    'examples': [
      """
main() {
var m = const {'foo': 1, 'foo': 2};
}"""
    ],
  },

  'BAD_INPUT_CHARACTER': {
    'id': 'SHQWJY',
    'template': "Character U+#{characterHex} isn't allowed here.",
    'howToFix': DONT_KNOW_HOW_TO_FIX,
    'examples': [
      """
main() {
String x = ç;
}
"""
    ],
  },

  'UNTERMINATED_STRING': {
    'id': 'TRLTHK',
    'template': "String must end with #{quote}.",
    'howToFix': DONT_KNOW_HOW_TO_FIX,
    'examples': [
      """
main() {
return '
;
}
""",
      """
main() {
return \"
;
}
""",
      """
main() {
return r'
;
}
""",
      """
main() {
return r\"
;
}
""",
      """
main() => '''
""",
      """
main() => \"\"\"
""",
      """
main() => r'''
""",
      """
main() => r\"\"\"
"""
    ],
  },

  'UNMATCHED_TOKEN': {
    'id': 'AGJKMQ',
    'template': "Can't find '#{end}' to match '#{begin}'.",
    'howToFix': DONT_KNOW_HOW_TO_FIX,
    'examples': ["main(", "main(){", "main(){]}",],
  },

  'UNTERMINATED_TOKEN': {
    'id': 'VIIXHQ',
    'template':
        // This is a fall-back message that shouldn't happen.
        "Incomplete token.",
  },

  'EXPONENT_MISSING': {
    'id': 'CXPLCR',
    'template':
        "Numbers in exponential notation should always contain an exponent"
        " (an integer number with an optional sign).",
    'howToFix': "Make sure there is an exponent, and remove any whitespace "
        "before it.",
    'examples': [
      """
main() {
var i = 1e;
}
"""
    ],
  },

  'HEX_DIGIT_EXPECTED': {
    'id': 'GKCAGV',
    'template': "A hex digit (0-9 or A-F) must follow '0x'.",
    'howToFix': DONT_KNOW_HOW_TO_FIX, // Seems obvious from the error message.
    'examples': [
      """
main() {
var i = 0x;
}
"""
    ],
  },

  'MALFORMED_STRING_LITERAL': {
    'id': 'DULNSD',
    'template':
        r"A '$' has special meaning inside a string, and must be followed by "
        "an identifier or an expression in curly braces ({}).",
    'howToFix': r"Try adding a backslash (\) to escape the '$'.",
    'examples': [
      r"""
main() {
return '$';
}
""",
      r'''
main() {
return "$";
}
''',
      r"""
main() {
return '''$''';
}
""",
      r'''
main() {
return """$""";
}
'''
    ],
  },

  'UNTERMINATED_COMMENT': {
    'id': 'NECJNM',
    'template': "Comment starting with '/*' must end with '*/'.",
    'howToFix': DONT_KNOW_HOW_TO_FIX,
    'examples': [
      r"""
main() {
}
/*"""
    ],
  },

  'MISSING_TOKEN_BEFORE_THIS': {
    'id': 'AFKXGU',
    'template': "Expected '#{token}' before this.",
    // Consider the second example below: the parser expects a ')' before
    // 'y', but a ',' would also have worked. We don't have enough
    // information to give a good suggestion.
    'howToFix': DONT_KNOW_HOW_TO_FIX,
    'examples': ["main() => true ? 1;", "main() => foo(x: 1 y: 2);",],
  },

  'MISSING_TOKEN_AFTER_THIS': {
    'id': 'FMUFJL',
    'template': "Expected '#{token}' after this.",
    // See [MISSING_TOKEN_BEFORE_THIS], we don't have enough information
    // to give a good suggestion.
    'howToFix': DONT_KNOW_HOW_TO_FIX,
    'examples': [
      "main(x) {x}",
      """
class S1 {}
class S2 {}
class S3 {}
class A = S1 with S2, S3
main() => new A();
"""
    ],
  },

  'CONSIDER_ANALYZE_ALL': {
    'id': 'HHILSH',
    'template': "Could not find '#{main}'.  Nothing will be analyzed.",
    'howToFix': "Try using '--analyze-all' to analyze everything.",
    'examples': [''],
  },

  'MISSING_MAIN': {
    'id': 'HNAOPV',
    'template': "Could not find '#{main}'.",
    // No example, test uses '--analyze-only' which will produce the above
    // message [CONSIDER_ANALYZE_ALL].  An example for a human operator
    // would be an empty file.
    'howToFix': "Try adding a method named '#{main}' to your program."
  },

  'MAIN_NOT_A_FUNCTION': {
    'id': 'PIURPA',
    'template': "'#{main}' is not a function.",
    'howToFix': DONT_KNOW_HOW_TO_FIX, // Don't state the obvious.
    'examples': ['var main;'],
  },

  'MAIN_WITH_EXTRA_PARAMETER': {
    'id': 'ONOGQB',
    'template': "'#{main}' cannot have more than two parameters.",
    'howToFix': DONT_KNOW_HOW_TO_FIX, // Don't state the obvious.
    'examples': ['main(a, b, c) {}'],
  },

  'COMPILER_CRASHED': {
    'id': 'MHDWAV',
    'template': "The compiler crashed when compiling this element.",
  },

  'PLEASE_REPORT_THE_CRASH': {
    'id': 'UUTHXX',
    'template': '''
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
''',
  },

  'POTENTIAL_MUTATION': {
    'id': 'YGNLLB',
    'template': "Variable '#{variableName}' is not known to be of type "
        "'#{shownType}' because it is potentially mutated in the scope for "
        "promotion.",
  },

  'POTENTIAL_MUTATION_HERE': {
    'id': 'ATMSVX',
    'template': "Variable '#{variableName}' is potentially mutated here.",
  },

  'POTENTIAL_MUTATION_IN_CLOSURE': {
    'id': 'XUAHTW',
    'template': "Variable '#{variableName}' is not known to be of type "
        "'#{shownType}' because it is potentially mutated within a closure.",
  },

  'POTENTIAL_MUTATION_IN_CLOSURE_HERE': {
    'id': 'UHFXLG',
    'template': "Variable '#{variableName}' is potentially mutated in a "
        "closure here.",
  },

  'ACCESSED_IN_CLOSURE': {
    'id': 'JJHKSF',
    'template': "Variable '#{variableName}' is not known to be of type "
        "'#{shownType}' because it is accessed by a closure in the scope for "
        "promotion and potentially mutated in the scope of "
        "'#{variableName}'.",
  },

  'ACCESSED_IN_CLOSURE_HERE': {
    'id': 'KMJVEA',
    'template': "Variable '#{variableName}' is accessed in a closure here.",
  },

  'NOT_MORE_SPECIFIC': {
    'id': 'EJHQAG',
    'template': "Variable '#{variableName}' is not shown to have type "
        "'#{shownType}' because '#{shownType}' is not more specific than the "
        "known type '#{knownType}' of '#{variableName}'.",
  },

  'NOT_MORE_SPECIFIC_SUBTYPE': {
    'id': 'APICDL',
    'template': "Variable '#{variableName}' is not shown to have type "
        "'#{shownType}' because '#{shownType}' is not a subtype of the "
        "known type '#{knownType}' of '#{variableName}'.",
  },

  'NOT_MORE_SPECIFIC_SUGGESTION': {
    'id': 'FFNCJX',
    'template': "Variable '#{variableName}' is not shown to have type "
        "'#{shownType}' because '#{shownType}' is not more specific than the "
        "known type '#{knownType}' of '#{variableName}'.",
    'howToFix': "Try replacing '#{shownType}' with '#{shownTypeSuggestion}'.",
  },

  'NO_COMMON_SUBTYPES': {
    'id': 'XKJOEC',
    'template': "Types '#{left}' and '#{right}' have no common subtypes.",
  },

  'HIDDEN_WARNINGS_HINTS': {
    'id': 'JBAWEK',
    'template':
        "#{warnings} warning(s) and #{hints} hint(s) suppressed in #{uri}.",
  },

  'HIDDEN_WARNINGS': {
    'id': 'JIYWDC',
    'template': "#{warnings} warning(s) suppressed in #{uri}.",
  },

  'HIDDEN_HINTS': {
    'id': 'RHNXQT',
    'template': "#{hints} hint(s) suppressed in #{uri}.",
  },

  'PREAMBLE': {
    'id': 'GXGWIF',
    'template': "When run on the command-line, the compiled output might"
        " require a preamble file located in:\n"
        "  <sdk>/lib/_internal/js_runtime/lib/preambles.",
  },

  'INVALID_SYNC_MODIFIER': {
    'id': 'FNYUYU',
    'template': "Invalid modifier 'sync'.",
    'howToFix': "Try replacing 'sync' with 'sync*'.",
    'examples': ["main() sync {}"],
  },

  'INVALID_AWAIT_FOR': {
    'id': 'IEYGCY',
    'template': "'await' is only supported on for-in loops.",
    'howToFix': "Try rewriting the loop as a for-in loop or removing the "
        "'await' keyword.",
    'examples': [
      """
main() async* {
await for (int i = 0; i < 10; i++) {}
}
"""
    ],
  },

  'INVALID_AWAIT_FOR_IN': {
    'id': 'FIEYGC',
    'template': "'await' is only supported in methods with an 'async' or "
                "'async*' body modifier.",
    'howToFix': "Try adding 'async' or 'async*' to the method body or "
                "removing the 'await' keyword.",
    'examples': [
      """
main(o) sync* {
  await for (var e in o) {}
}
"""
    ],
  },

  'INVALID_AWAIT': {
    'id': 'IEYHYD',
    'template': "'await' is only supported in methods with an 'async' or "
                "'async*' body modifier.",
    'howToFix': "Try adding 'async' or 'async*' to the method body.",
    'examples': [
      """
main() sync* {
  await null;
}
"""
    ],
  },

  'INVALID_YIELD': {
    'id': 'IPGGCY',
    'template': "'yield' is only supported in methods with a 'sync*' or "
                "'async*' body modifier.",
    'howToFix': "Try adding 'sync*' or 'async*' to the method body.",
    'examples': [
      """
main() async {
  yield 0;
}
"""
    ],
  },

  'ASYNC_MODIFIER_ON_ABSTRACT_METHOD': {
    'id': 'VRISLY',
    'template':
        "The modifier '#{modifier}' is not allowed on an abstract method.",
    'options': ['--enable-async'],
    'howToFix': "Try removing the '#{modifier}' modifier or adding a "
        "body to the method.",
    'examples': [
      """
abstract class A {
method() async;
}
class B extends A {
method() {}
}
main() {
A a = new B();
a.method();
}
"""
    ],
  },

  'ASYNC_MODIFIER_ON_CONSTRUCTOR': {
    'id': 'DHCFON',
    'template': "The modifier '#{modifier}' is not allowed on constructors.",
    'options': ['--enable-async'],
    'howToFix': "Try removing the '#{modifier}' modifier.",
    'examples': [
      """
class A {
A() async;
}
main() => new A();""",
      """
class A {
A();
factory A.a() async* {}
}
main() => new A.a();"""
    ],
  },

  'ASYNC_MODIFIER_ON_SETTER': {
    'id': 'NMJLJE',
    'template': "The modifier '#{modifier}' is not allowed on setters.",
    'options': ['--enable-async'],
    'howToFix': "Try removing the '#{modifier}' modifier.",
    'examples': [
      """
class A {
set foo(v) async {}
}
main() => new A().foo = 0;"""
    ],
  },

  'YIELDING_MODIFIER_ON_ARROW_BODY': {
    'id': 'UOGLUX',
    'template':
        "The modifier '#{modifier}' is not allowed on methods implemented "
        "using '=>'.",
    'options': ['--enable-async'],
    'howToFix': "Try removing the '#{modifier}' modifier or implementing "
        "the method body using a block: '{ ... }'.",
    'examples': ["main() sync* => null;", "main() async* => null;"],
  },

  // TODO(johnniwinther): Check for 'async' as identifier.
  'ASYNC_KEYWORD_AS_IDENTIFIER': {
    'id': 'VTWSMA',
    'template':
        "'#{keyword}' cannot be used as an identifier in a function body "
        "marked with '#{modifier}'.",
    'options': ['--enable-async'],
    'howToFix': "Try removing the '#{modifier}' modifier or renaming the "
        "identifier.",
    'examples': [
      """
main() async {
var await;
}""",
      """
main() async* {
var yield;
}""",
      """
main() sync* {
var yield;
}"""
    ],
  },

  'RETURN_IN_GENERATOR': {
    'id': 'AWGUVF',
    'template':
        "'return' with a value is not allowed in a method body using the "
        "'#{modifier}' modifier.",
    'howToFix': "Try removing the value, replacing 'return' with 'yield' "
        "or changing the method body modifier.",
    'examples': [
      """
foo() async* { return 0; }
main() => foo();
""",
      """
foo() sync* { return 0; }
main() => foo();
"""
    ],
  },

  'NATIVE_NOT_SUPPORTED': {
    'id': 'QMMLUT',
    'template': "'native' modifier is not supported.",
    'howToFix': "Try removing the 'native' implementation or analyzing the "
        "code with the --allow-native-extensions option.",
    'examples': [
      """
main() native "Main";
"""
    ],
  },

  'DART_EXT_NOT_SUPPORTED': {
    'id': 'JLPQFJ',
    'template': "The 'dart-ext' scheme is not supported.",
    'howToFix': "Try analyzing the code with the --allow-native-extensions "
        "option.",
    'examples': [
      """
import 'dart-ext:main';

main() {}
"""
    ],
  },

  'LIBRARY_TAG_MUST_BE_FIRST': {
    'id': 'JFUSRX',
    'template':
        "The library declaration should come before other declarations.",
    'howToFix': "Try moving the declaration to the top of the file.",
    'examples': [
      """
import 'dart:core';
library foo;
main() {}
""",
    ],
  },

  'ONLY_ONE_LIBRARY_TAG': {
    'id': 'CCXFMY',
    'template': "There can only be one library declaration.",
    'howToFix': "Try removing all other library declarations.",
    'examples': [
      """
library foo;
library bar;
main() {}
""",
      """
library foo;
import 'dart:core';
library bar;
main() {}
""",
    ],
  },

  'IMPORT_BEFORE_PARTS': {
    'id': 'NSMOQI',
    'template': "Import declarations should come before parts.",
    'howToFix': "Try moving this import further up in the file.",
    'examples': [
      {
        'main.dart': """
library test.main;
part 'part.dart';
import 'dart:core';
main() {}
""",
        'part.dart': """
part of test.main;
""",
      }
    ],
  },

  'EXPORT_BEFORE_PARTS': {
    'id': 'KYJTTC',
    'template': "Export declarations should come before parts.",
    'howToFix': "Try moving this export further up in the file.",
    'examples': [
      {
        'main.dart': """
library test.main;
part 'part.dart';
export 'dart:core';
main() {}
""",
        'part.dart': """
part of test.main;
""",
      }
    ],

//////////////////////////////////////////////////////////////////////////////
// Patch errors start.
//////////////////////////////////////////////////////////////////////////////
  },

  'PATCH_RETURN_TYPE_MISMATCH': {
    'id': 'DTOQDU',
    'template': "Patch return type '#{patchReturnType}' does not match "
        "'#{originReturnType}' on origin method '#{methodName}'.",
  },

  'PATCH_REQUIRED_PARAMETER_COUNT_MISMATCH': {
    'id': 'KJUUYC',
    'template': "Required parameter count of patch method "
        "(#{patchParameterCount}) does not match parameter count on origin "
        "method '#{methodName}' (#{originParameterCount}).",
  },

  'PATCH_OPTIONAL_PARAMETER_COUNT_MISMATCH': {
    'id': 'GUTGTE',
    'template': "Optional parameter count of patch method "
        "(#{patchParameterCount}) does not match parameter count on origin "
        "method '#{methodName}' (#{originParameterCount}).",
  },

  'PATCH_OPTIONAL_PARAMETER_NAMED_MISMATCH': {
    'id': 'MCHEIC',
    'template': "Optional parameters of origin and patch method "
        "'#{methodName}' must both be either named or positional.",
  },

  'PATCH_PARAMETER_MISMATCH': {
    'id': 'XISHPB',
    'template': "Patch method parameter '#{patchParameter}' does not match "
        "'#{originParameter}' on origin method '#{methodName}'.",
  },

  'PATCH_PARAMETER_TYPE_MISMATCH': {
    'id': 'UGRBYD',
    'template': "Patch method parameter '#{parameterName}' type "
        "'#{patchParameterType}' does not match '#{originParameterType}' on "
        "origin method '#{methodName}'.",
  },

  'PATCH_EXTERNAL_WITHOUT_IMPLEMENTATION': {
    'id': 'WSNMKD',
    'template': "External method without an implementation.",
  },

  'PATCH_POINT_TO_FUNCTION': {
    'id': 'CAVBPN',
    'template': "This is the function patch '#{functionName}'.",
  },

  'PATCH_POINT_TO_CLASS': {
    'id': 'TWDLDX',
    'template': "This is the class patch '#{className}'.",
  },

  'PATCH_POINT_TO_GETTER': {
    'id': 'TRBBNY',
    'template': "This is the getter patch '#{getterName}'.",
  },

  'PATCH_POINT_TO_SETTER': {
    'id': 'DAXDLW',
    'template': "This is the setter patch '#{setterName}'.",
  },

  'PATCH_POINT_TO_CONSTRUCTOR': {
    'id': 'VYQISY',
    'template': "This is the constructor patch '#{constructorName}'.",
  },

  'PATCH_POINT_TO_PARAMETER': {
    'id': 'TFPAGO',
    'template': "This is the patch parameter '#{parameterName}'.",
  },

  'PATCH_NON_EXISTING': {
    'id': 'AWOACF',
    'template': "Origin does not exist for patch '#{name}'.",
  },

  // TODO(ahe): Eventually, this error should be removed as it will be
  // handled by the regular parser.
  'PATCH_NONPATCHABLE': {
    'id': 'WQEPJI',
    'template': "Only classes and functions can be patched.",
  },

  'PATCH_NON_EXTERNAL': {
    'id': 'MHLXNK',
    'template': "Only external functions can be patched.",
  },

  'PATCH_NON_CLASS': {
    'id': 'UIALAB',
    'template': "Patching non-class with class patch '#{className}'.",
  },

  'PATCH_NON_GETTER': {
    'id': 'VTNQCJ',
    'template': "Cannot patch non-getter '#{name}' with getter patch.",
  },

  'PATCH_NO_GETTER': {
    'id': 'XOPDHD',
    'template': "No getter found for getter patch '#{getterName}'.",
  },

  'PATCH_NON_SETTER': {
    'id': 'XBOMMN',
    'template': "Cannot patch non-setter '#{name}' with setter patch.",
  },

  'PATCH_NO_SETTER': {
    'id': 'YITARQ',
    'template': "No setter found for setter patch '#{setterName}'.",
  },

  'PATCH_NON_CONSTRUCTOR': {
    'id': 'TWAEQV',
    'template': "Cannot patch non-constructor with constructor patch "
        "'#{constructorName}'.",
  },

  'PATCH_NON_FUNCTION': {
    'id': 'EDXBPI',
    'template': "Cannot patch non-function with function patch "
        "'#{functionName}'.",
  },

  'INJECTED_PUBLIC_MEMBER': {
    'id': 'JGMXMI',
    'template': "Non-patch members in patch libraries must be private.",
  },

  'EXTERNAL_WITH_BODY': {
    'id': 'GAVMSQ',
    'template':
        "External function '#{functionName}' cannot have a function body.",
    'options': ["--output-type=dart"],
    'howToFix': "Try removing the 'external' modifier or the function body.",
    'examples': [
      """
external foo() => 0;
main() => foo();
""",
      """
external foo() {}
main() => foo();
"""
    ],

//////////////////////////////////////////////////////////////////////////////
// Patch errors end.
//////////////////////////////////////////////////////////////////////////////
  },

  'EXPERIMENTAL_ASSERT_MESSAGE': {
    'id': 'NENGIS',
    'template': "Experimental language feature 'assertion with message'"
        " is not supported.",
    'howToFix':
        "Use option '--assert-message' to use assertions with messages.",
    'examples': [
      r'''
main() {
int n = -7;
assert(n > 0, 'must be positive: $n');
}
'''
    ],
  },

  'IMPORT_EXPERIMENTAL_MIRRORS': {
    'id': 'SCJYPH',
    'template': '''

****************************************************************
* WARNING: dart:mirrors support in dart2js is experimental,
*          and not recommended.
*          This implementation of mirrors is incomplete,
*          and often greatly increases the size of the generated
*          JavaScript code.
*
* Your app imports dart:mirrors via:'''
        '''
$IMPORT_EXPERIMENTAL_MIRRORS_PADDING#{importChain}
*
* You can disable this message by using the --enable-experimental-mirrors
* command-line flag.
*
* To learn what to do next, please visit:
*    http://dartlang.org/dart2js-reflection
****************************************************************
''',
  },

  'DISALLOWED_LIBRARY_IMPORT': {
    'id': 'OCSFJU',
    'template': '''
Your app imports the unsupported library '#{uri}' via:
'''
        '''
$DISALLOWED_LIBRARY_IMPORT_PADDING#{importChain}

Use the --categories option to support import of '#{uri}'.
''',
  },

  'MIRRORS_LIBRARY_NOT_SUPPORT_BY_BACKEND': {
    'id': 'JBTRRM',
    'template': """
dart:mirrors library is not supported when using this backend.

Your app imports dart:mirrors via:"""
        """
$MIRRORS_NOT_SUPPORTED_BY_BACKEND_PADDING#{importChain}""",
  },

  'CALL_NOT_SUPPORTED_ON_NATIVE_CLASS': {
    'id': 'HAULDW',
    'template': "Non-supported 'call' member on a native class, or a "
        "subclass of a native class.",
  },

  'DIRECTLY_THROWING_NSM': {
    'id': 'XLTPCS',
    'template': "This 'noSuchMethod' implementation is guaranteed to throw an "
        "exception. The generated code will be smaller if it is "
        "rewritten.",
    'howToFix': "Rewrite to "
        "'noSuchMethod(Invocation i) => super.noSuchMethod(i);'.",
  },

  'COMPLEX_THROWING_NSM': {
    'id': 'PLCXVX',
    'template': "This 'noSuchMethod' implementation is guaranteed to throw an "
        "exception. The generated code will be smaller and the compiler "
        "will be able to perform more optimizations if it is rewritten.",
    'howToFix': "Rewrite to "
        "'noSuchMethod(Invocation i) => super.noSuchMethod(i);'.",
  },

  'COMPLEX_RETURNING_NSM': {
    'id': 'HUTCTQ',
    'template': "Overriding 'noSuchMethod' causes the compiler to generate "
        "more code and prevents the compiler from doing some optimizations.",
    'howToFix': "Consider removing this 'noSuchMethod' implementation."
  },

  'UNRECOGNIZED_VERSION_OF_LOOKUP_MAP': {
    'id': 'OVAFEW',
    'template': "Unsupported version of package:lookup_map.",
    'howToFix': DONT_KNOW_HOW_TO_FIX
  },
};
