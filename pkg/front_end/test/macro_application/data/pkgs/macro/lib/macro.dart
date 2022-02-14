// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro

class FunctionDefinitionMacro1 implements FunctionDefinitionMacro {
  const FunctionDefinitionMacro1();

  FutureOr<void> buildDefinitionForFunction(FunctionDeclaration function,
      FunctionDefinitionBuilder builder) {
    builder.augment(new FunctionBodyCode.fromString('''{
  return 42;
}'''));
  }
}

macro

class FunctionDefinitionMacro2 implements FunctionDefinitionMacro {
  const FunctionDefinitionMacro2();

  FutureOr<void> buildDefinitionForFunction(FunctionDeclaration function,
      FunctionDefinitionBuilder builder) async {
    if (function.positionalParameters.isEmpty) {
      return;
    }
    StaticType returnType = await builder.resolve(function.returnType.code);
    StaticType parameterType =
    await builder.resolve(function.positionalParameters.first.type.code);
    builder.augment(new FunctionBodyCode.fromString('''{
  print('isExactly=${await returnType.isExactly(parameterType)}');
  print('isSubtype=${await returnType.isSubtypeOf(parameterType)}');
}'''));
  }
}


macro

class FunctionTypesMacro1 implements FunctionTypesMacro {
  const FunctionTypesMacro1();

  FutureOr<void> buildTypesForFunction(FunctionDeclaration function,
      TypeBuilder builder) {
    var name = '${function.identifier.name}GeneratedClass';
    builder.declareType(
        name, new DeclarationCode.fromParts(['class $name<T extends ',
      function.returnType.code, '> {}']));
  }
}

macro

class FunctionDeclarationsMacro1 implements FunctionDeclarationsMacro {
  const FunctionDeclarationsMacro1();

  FutureOr<void> buildDeclarationsForFunction(FunctionDeclaration function,
      DeclarationBuilder builder) {
    StringBuffer sb = new StringBuffer();
    if (function.isAbstract) {
      sb.write('a');
    }
    if (function.isExternal) {
      sb.write('e');
    }
    if (function.isGetter) {
      sb.write('g');
    }
    if (function.isOperator) {
      sb.write('o');
    }
    if (function.isSetter) {
      sb.write('s');
    }
    builder.declareInLibrary(new DeclarationCode.fromString('''
void ${function.identifier.name}GeneratedMethod_${sb}() {}
'''));
  }
}

macro

class FunctionDeclarationsMacro2 implements FunctionDeclarationsMacro {
  const FunctionDeclarationsMacro2();

  FutureOr<void> buildDeclarationsForFunction(FunctionDeclaration function,
      DeclarationBuilder builder) async {
    if (function.positionalParameters.isEmpty) {
      return;
    }
    StaticType returnType = await builder.resolve(function.returnType.code);
    StaticType parameterType =
    await builder.resolve(function.positionalParameters.first.type.code);
    bool isExactly = await returnType.isExactly(parameterType);
    bool isSubtype = await returnType.isSubtypeOf(parameterType);
    String tag = '${isExactly ? 'e' : ''}${isSubtype ? 's' : ''}';
    builder.declareInLibrary(new DeclarationCode.fromString('''
void ${function.identifier.name}GeneratedMethod_$tag() {}
'''));
  }
}

macro

class MethodDeclarationsMacro1 implements MethodDeclarationsMacro {
  const MethodDeclarationsMacro1();

  FutureOr<void> buildDeclarationsForMethod(MethodDeclaration method,
      ClassMemberDeclarationBuilder builder) {
    StringBuffer sb = new StringBuffer();
    if (method.isAbstract) {
      sb.write('a');
    }
    if (method.isExternal) {
      sb.write('e');
    }
    if (method.isGetter) {
      sb.write('g');
    }
    if (method.isOperator) {
      sb.write('o');
    }
    if (method.isSetter) {
      sb.write('s');
    }
    builder.declareInLibrary(new DeclarationCode.fromString('''
void ${method.definingClass.name}_${method.identifier.name}GeneratedMethod_${sb}() {}
'''));
  }
}

macro

class VariableDeclarationsMacro1 implements VariableDeclarationsMacro {
  const VariableDeclarationsMacro1();

  FutureOr<void> buildDeclarationsForVariable(VariableDeclaration variable,
      DeclarationBuilder builder) {
    StringBuffer sb = new StringBuffer();
    if (variable.isExternal) {
      sb.write('e');
    }
    if (variable.isFinal) {
      sb.write('f');
    }
    if (variable.isLate) {
      sb.write('l');
    }
    builder.declareInLibrary(new DeclarationCode.fromString('''
void ${variable.identifier.name}GeneratedMethod_${sb}() {}
'''));
  }
}

macro

class FieldDeclarationsMacro1 implements FieldDeclarationsMacro {
  const FieldDeclarationsMacro1();

  FutureOr<void> buildDeclarationsForField(FieldDeclaration field,
      ClassMemberDeclarationBuilder builder) {
    StringBuffer sb = new StringBuffer();
    if (field.isExternal) {
      sb.write('e');
    }
    if (field.isFinal) {
      sb.write('f');
    }
    if (field.isLate) {
      sb.write('l');
    }
    builder.declareInLibrary(new DeclarationCode.fromString('''
void ${field.definingClass.name}_${field.identifier.name}GeneratedMethod_${sb}() {}
'''));
  }
}

macro

class ClassDeclarationsMacro1 implements ClassDeclarationsMacro {
  const ClassDeclarationsMacro1();

  FutureOr<void> buildDeclarationsForClass(ClassDeclaration clazz,
      ClassMemberDeclarationBuilder builder) {
    StringBuffer sb = new StringBuffer();
    if (clazz.isAbstract) {
      sb.write('a');
    }
    if (clazz.isExternal) {
      sb.write('e');
    }
    builder.declareInLibrary(new DeclarationCode.fromString('''
void ${clazz.identifier.name}GeneratedMethod_${sb}() {}
'''));
  }
}

macro

class ClassDeclarationsMacro2 implements ClassDeclarationsMacro {
  const ClassDeclarationsMacro2();

  FutureOr<void> buildDeclarationsForClass(ClassDeclaration clazz,
      ClassMemberDeclarationBuilder builder) async {
    List<ConstructorDeclaration> constructors = await builder.constructorsOf(
        clazz);
    StringBuffer constructorsText = new StringBuffer();
    String comma = '';
    constructorsText.write('constructors=');
    for (ConstructorDeclaration constructor in constructors) {
      constructorsText.write(comma);
      String name = constructor.identifier.name;
      constructorsText.write("'$name'");
      comma = ',';
    }

    List<FieldDeclaration> fields = await builder.fieldsOf(
        clazz);
    StringBuffer fieldsText = new StringBuffer();
    comma = '';
    fieldsText.write('fields=');
    for (FieldDeclaration field in fields) {
      fieldsText.write(comma);
      String name = field.identifier.name;
      fieldsText.write("'$name'");
      comma = ',';
    }

    List<MethodDeclaration> methods = await builder.methodsOf(
        clazz);
    StringBuffer methodsText = new StringBuffer();
    comma = '';
    methodsText.write('methods=');
    for (MethodDeclaration method in methods) {
      methodsText.write(comma);
      String name = method.identifier.name;
      methodsText.write("'$name'");
      comma = ',';
    }

    builder.declareInLibrary(new DeclarationCode.fromString('''
void ${clazz.identifier.name}Introspection() {
  print("$constructorsText");
  print("$fieldsText");
  print("$methodsText");
}
'''));
  }
}

macro

class ConstructorDeclarationsMacro1
    implements ConstructorDeclarationsMacro {
  const ConstructorDeclarationsMacro1();

  FutureOr<void> buildDeclarationsForConstructor(
      ConstructorDeclaration constructor,
      ClassMemberDeclarationBuilder builder) {
    StringBuffer sb = new StringBuffer();
    if (constructor.isAbstract) {
      sb.write('a');
    }
    if (constructor.isExternal) {
      sb.write('e');
    }
    if (constructor.isGetter) {
      sb.write('g');
    }
    if (constructor.isOperator) {
      sb.write('o');
    }
    if (constructor.isSetter) {
      sb.write('s');
    }
    if (constructor.isFactory) {
      sb.write('f');
    }
    builder.declareInClass(new DeclarationCode.fromString('''
void ${constructor.definingClass.name}_${constructor.identifier
        .name}GeneratedMethod_${sb}() {}
'''));
  }
}
