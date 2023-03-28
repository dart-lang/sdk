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
  throw 42;
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
  throw 42;
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
        name, new DeclarationCode.fromParts(['''
class $name {
  external ''', function.returnType.code, ''' method();
}'''
    ]));
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
    String name;
    if (method.isOperator) {
      name = 'operator';
    } else {
      name = method.identifier.name;
    }
    builder.declareInLibrary(new DeclarationCode.fromString('''
void ${method.definingClass.name}_${name}GeneratedMethod_${sb}() {}
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

  FutureOr<void> buildDeclarationsForClass(IntrospectableClassDeclaration clazz,
      ClassMemberDeclarationBuilder builder) {
    StringBuffer sb = new StringBuffer();
    if (clazz.hasAbstract) {
      sb.write('a');
    }
    if (clazz.hasExternal) {
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

  FutureOr<void> buildDeclarationsForClass(IntrospectableClassDeclaration clazz,
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

macro

class ToStringMacro implements ClassDeclarationsMacro {
  const ToStringMacro();

  FutureOr<void> buildDeclarationsForClass(IntrospectableClassDeclaration clazz,
      ClassMemberDeclarationBuilder builder) async {
    Iterable<MethodDeclaration> methods = await builder.methodsOf(clazz);
    if (!methods.any((m) => m.identifier.name == 'toString')) {
      Iterable<FieldDeclaration> fields = await builder.fieldsOf(clazz);
      List<Object> parts = ['''
  toString() {
    return "${clazz.identifier.name}('''
      ];
      String comma = '';
      for (FieldDeclaration field in fields) {
        parts.add(comma);
        parts.add('${field.identifier.name}=\${');
        parts.add(field.identifier.name);
        parts.add('}');
        comma = ',';
      }
      parts.add(''')";
  }''');
      builder.declareInClass(new DeclarationCode.fromParts(parts));
    }
  }
}

macro

class SequenceMacro
    implements
        ClassDeclarationsMacro,
        MethodDeclarationsMacro {
  final int index;

  const SequenceMacro(this.index);

  void _addMethod(ClassDeclaration clazz,
      ClassMemberDeclarationBuilder builder) async {
  }

  Future<void> _findAllMethods(
      ClassMemberDeclarationBuilder builder,
      IntrospectableClassDeclaration cls,
      List<MethodDeclaration> methods) async {
    if (cls.superclass != null) {
      await _findAllMethods(
        builder,
        await builder.declarationOf(cls.superclass!.identifier)
            as IntrospectableClassDeclaration,
        methods);
    }
    for (NamedTypeAnnotation mixin in cls.mixins) {
      await _findAllMethods(
        builder,
        await builder.declarationOf(mixin.identifier)
            as IntrospectableClassDeclaration,
        methods);
    }
    for (NamedTypeAnnotation interface in cls.interfaces) {
      await _findAllMethods(
        builder,
        await builder.declarationOf(interface.identifier)
            as IntrospectableClassDeclaration,
        methods);
    }
    methods.addAll(await builder.methodsOf(cls));
  }

  FutureOr<void> buildDeclarationsForClass(IntrospectableClassDeclaration clazz,
      ClassMemberDeclarationBuilder builder) async {
    List<MethodDeclaration> methods = [];
    await _findAllMethods(builder, clazz, methods);
    int index = 0;
    String suffix = '';
    while (methods.any((m) => m.identifier.name == 'method$suffix')) {
      index++;
      suffix = '$index';
    }
    builder.declareInClass(new DeclarationCode.fromString('''
  method$suffix() {}'''));
  }

  FutureOr<void> buildDeclarationsForMethod(MethodDeclaration method,
      ClassMemberDeclarationBuilder builder) {
    // Do nothing. The applying of this will show up in the declarations phase
    // application order.
  }
}

macro

class SupertypesMacro implements ClassDefinitionMacro {
  const SupertypesMacro();

  FutureOr<void> buildDefinitionForClass(IntrospectableClassDeclaration clazz,
      ClassDefinitionBuilder builder) async {
    ClassDeclaration? superClass = clazz.superclass == null ? null :
        await builder.declarationOf(clazz.superclass!.identifier)
            as ClassDeclaration?;
    FunctionDefinitionBuilder getSuperClassBuilder = await builder.buildMethod(
        (await builder.methodsOf(clazz))
            .firstWhere((m) => m.identifier.name == 'getSuperClass')
            .identifier);
    getSuperClassBuilder.augment(new FunctionBodyCode.fromString('''{
    return "${superClass?.identifier.name}";
  }'''));
  }
}

macro

class ImportConflictMacro implements FunctionDefinitionMacro {
  const ImportConflictMacro();

  FutureOr<void> buildDefinitionForFunction(FunctionDeclaration function,
      FunctionDefinitionBuilder builder) {
    builder.augment(new FunctionBodyCode.fromParts([
      '{\n  ',
      'var ',
      'prefix',
      ' = ',
      function.positionalParameters
          .elementAt(0)
          .type
          .code,
      ';\n  ',
      'var prefix0',
      ' = ',
      function.positionalParameters
          .elementAt(1)
          .type
          .code,
      ';\n  ',
      'var pre',
      'fix',
      '10 = ',
      function.positionalParameters
          .elementAt(2)
          .type
          .code,
      ';\n',
      '}',
    ]));
  }
}

macro

class InferableMacro
    implements
        FieldDeclarationsMacro,
        MethodDeclarationsMacro,
        ConstructorDeclarationsMacro {
  const InferableMacro();

  FutureOr<void> buildDeclarationsForField(FieldDeclaration field,
      ClassMemberDeclarationBuilder builder) async {
    Identifier listIdentifier = await builder.resolveIdentifier(
        Uri.parse('dart:core'), 'List');
    builder.declareInClass(new DeclarationCode.fromParts([
      field.type.code,
      ' get_${field.identifier.name}(',
      field.type.code,
      ' f) => ',
      field.identifier,
      ';',
    ]));
    builder.declareInClass(new DeclarationCode.fromParts([
      field.type.code,
      ' Function() get_${field.identifier.name}Func(',
      field.type.code,
      ' Function(',
      field.type.code,
      ') f) => () => ',
      field.identifier,
      ';',
    ]));
    builder.declareInClass(new DeclarationCode.fromParts([
      listIdentifier,
      '<',
      field.type.code,
      '> get_${field.identifier.name}List(',
      listIdentifier,
      '<',
      field.type.code,
      '> l) => [',
      field.identifier,
      '];',
    ]));
    // TODO(johnniwinther): Enable these when field augmentation is supported.
    /*builder.declareInClass(new DeclarationCode.fromParts([
      field.type.code,
      ' field_${field.identifier.name} = ',
      field.identifier,
      ';',
    ]));
    builder.declareInClass(new DeclarationCode.fromParts([
      field.type.code,
      ' Function() field_${field.identifier.name}Func = () => ',
      field.identifier,
      ';',
    ]));
    builder.declareInClass(new DeclarationCode.fromParts([
      listIdentifier,
      '<',
      field.type.code,
      '> field_${field.identifier.name}List = [',
      field.identifier,
      '];',
    ]));*/
  }

  FutureOr<void> buildDeclarationsForMethod(MethodDeclaration method,
      ClassMemberDeclarationBuilder builder) async {
    Identifier listIdentifier = await builder.resolveIdentifier(
        Uri.parse('dart:core'), 'List');
    builder.declareInClass(new DeclarationCode.fromParts([
      method.returnType.code,
      ' get_${method.identifier.name}() => ',
      method.identifier,
      '();',
    ]));
    builder.declareInClass(new DeclarationCode.fromParts([
      method.returnType.code,
      ' Function() get_${method.identifier.name}Func() => () => ',
      method.identifier,
      '();',
    ]));
    builder.declareInClass(new DeclarationCode.fromParts([
      listIdentifier,
      '<',
      method.returnType.code,
      '> get_${method.identifier.name}List() => [',
      method.identifier,
      '()];',
    ]));
  }

  FutureOr<void> buildDeclarationsForConstructor(
      ConstructorDeclaration constructor,
      ClassMemberDeclarationBuilder builder) async {
    Identifier listIdentifier = await builder.resolveIdentifier(
        Uri.parse('dart:core'), 'List');
    builder.declareInClass(new DeclarationCode.fromParts([
      constructor.positionalParameters.first.type.code,
      ' get_${constructor.identifier.name}() => throw "";',
    ]));
    builder.declareInClass(new DeclarationCode.fromParts([
      constructor.positionalParameters.first.type.code,
      ' Function() get_${constructor.identifier.name}Func() => throw "";',
    ]));
    builder.declareInClass(new DeclarationCode.fromParts([
      listIdentifier,
      '<',
      constructor.positionalParameters.first.type.code,
      '> get_${constructor.identifier.name}List() => throw "";',
    ]));
  }
}
