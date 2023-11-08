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
    if (function.hasAbstract) {
      sb.write('a');
    }
    if (function.hasExternal) {
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
      MemberDeclarationBuilder builder) {
    StringBuffer sb = new StringBuffer();
    if (method.hasAbstract) {
      sb.write('a');
    }
    if (method.hasExternal) {
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
void ${method.definingType.name}_${name}GeneratedMethod_${sb}() {}
'''));
  }
}

macro

class VariableDeclarationsMacro1 implements VariableDeclarationsMacro {
  const VariableDeclarationsMacro1();

  FutureOr<void> buildDeclarationsForVariable(VariableDeclaration variable,
      DeclarationBuilder builder) {
    StringBuffer sb = new StringBuffer();
    if (variable.hasExternal) {
      sb.write('e');
    }
    if (variable.hasFinal) {
      sb.write('f');
    }
    if (variable.hasLate) {
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
      MemberDeclarationBuilder builder) {
    StringBuffer sb = new StringBuffer();
    if (field.hasExternal) {
      sb.write('e');
    }
    if (field.hasFinal) {
      sb.write('f');
    }
    if (field.hasLate) {
      sb.write('l');
    }
    builder.declareInLibrary(new DeclarationCode.fromString('''
void ${field.definingType.name}_${field.identifier.name}GeneratedMethod_${sb}() {}
'''));
  }
}

macro

class ClassDeclarationsMacro1 implements ClassDeclarationsMacro, MixinDeclarationsMacro {
  const ClassDeclarationsMacro1();

  FutureOr<void> buildDeclarationsForClass(IntrospectableClassDeclaration clazz,
    MemberDeclarationBuilder builder) => _build(clazz, builder);

  FutureOr<void> buildDeclarationsForMixin(IntrospectableMixinDeclaration mixin,
    MemberDeclarationBuilder builder) => _build(mixin, builder);

  FutureOr<void> _build(IntrospectableType type,
      MemberDeclarationBuilder builder) {
    StringBuffer sb = new StringBuffer();
    if (type is IntrospectableClassDeclaration) {
      if (type.hasAbstract) {
        sb.write('a');
      }
      if (type.hasExternal) {
        sb.write('e');
      }
    }
    builder.declareInLibrary(new DeclarationCode.fromString('''
void ${type.identifier.name}GeneratedMethod_${sb}() {}
'''));
  }
}

macro

class ClassDeclarationsMacro2 implements ClassDeclarationsMacro, MixinDeclarationsMacro {
  const ClassDeclarationsMacro2();
  FutureOr<void> buildDeclarationsForClass(IntrospectableClassDeclaration clazz,
      MemberDeclarationBuilder builder) => _build(clazz, builder);

  FutureOr<void> buildDeclarationsForMixin(IntrospectableMixinDeclaration mixin,
      MemberDeclarationBuilder builder) => _build(mixin, builder);

  FutureOr<void> _build(IntrospectableType type,
      MemberDeclarationBuilder builder) async {
    List<ConstructorDeclaration> constructors = await builder.constructorsOf(
        type);
    StringBuffer constructorsText = new StringBuffer();
    String comma = '';
    constructorsText.write('constructors=');
    for (ConstructorDeclaration constructor in constructors) {
      constructorsText.write(comma);
      String name = constructor.identifier.name;
      constructorsText.write("'$name'");
      comma = ',';
    }

    List<FieldDeclaration> fields = await builder.fieldsOf(type);
    StringBuffer fieldsText = new StringBuffer();
    comma = '';
    fieldsText.write('fields=');
    for (FieldDeclaration field in fields) {
      fieldsText.write(comma);
      String name = field.identifier.name;
      fieldsText.write("'$name'");
      comma = ',';
    }

    List<MethodDeclaration> methods = await builder.methodsOf(type);
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
void ${type.identifier.name}Introspection() {
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
      MemberDeclarationBuilder builder) {
    StringBuffer sb = new StringBuffer();
    if (constructor.hasAbstract) {
      sb.write('a');
    }
    if (constructor.hasExternal) {
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
    builder.declareInType(new DeclarationCode.fromString('''
void ${constructor.definingType.name}_${constructor.identifier
        .name}GeneratedMethod_${sb}() {}
'''));
  }
}

macro

class ToStringMacro implements ClassDeclarationsMacro, MixinDeclarationsMacro {
  const ToStringMacro();

  FutureOr<void> buildDeclarationsForClass(IntrospectableClassDeclaration clazz,
      MemberDeclarationBuilder builder) => _build(clazz, builder);

  FutureOr<void> buildDeclarationsForMixin(IntrospectableMixinDeclaration mixin,
      MemberDeclarationBuilder builder) => _build(mixin, builder);

  FutureOr<void> _build(IntrospectableType type, MemberDeclarationBuilder builder) async {
    Iterable<MethodDeclaration> methods = await builder.methodsOf(type);
    if (!methods.any((m) => m.identifier.name == 'toString')) {
      Iterable<FieldDeclaration> fields = await builder.fieldsOf(type);
      List<Object> parts = ['''
  toString() {
    return "${type.identifier.name}('''
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
      builder.declareInType(new DeclarationCode.fromParts(parts));
    }
  }
}

macro

class SequenceMacro
    implements
        ClassDeclarationsMacro,
        MixinDeclarationsMacro,
        MethodDeclarationsMacro {
  final int index;

  const SequenceMacro(this.index);

  void _addMethod(ClassDeclaration clazz,
      MemberDeclarationBuilder builder) async {
  }

  Future<void> _findAllMethods(
      MemberDeclarationBuilder builder,
      IntrospectableType cls,
      List<MethodDeclaration> methods) async {
    if (cls is IntrospectableClassDeclaration) {
      if (cls.superclass != null) {
        await _findAllMethods(
          builder,
          await builder.typeDeclarationOf(cls.superclass!.identifier)
              as IntrospectableType,
          methods);
      }
      for (NamedTypeAnnotation mixin in cls.mixins) {
        await _findAllMethods(
          builder,
          await builder.typeDeclarationOf(mixin.identifier)
              as IntrospectableType,
          methods);
      }
      for (NamedTypeAnnotation interface in cls.interfaces) {
        await _findAllMethods(
          builder,
          await builder.typeDeclarationOf(interface.identifier)
              as IntrospectableType,
          methods);
      }
    }
    if (cls is IntrospectableMixinDeclaration) {
      for (NamedTypeAnnotation interface in cls.interfaces) {
        await _findAllMethods(
          builder,
          await builder.typeDeclarationOf(interface.identifier)
              as IntrospectableType,
          methods);
      }
      for (NamedTypeAnnotation superclass in cls.superclassConstraints) {
        await _findAllMethods(
          builder,
          await builder.typeDeclarationOf(superclass.identifier)
              as IntrospectableType,
          methods);
      }
    }
    methods.addAll(await builder.methodsOf(cls));
  }

  FutureOr<void> buildDeclarationsForClass(IntrospectableClassDeclaration clazz,
      MemberDeclarationBuilder builder) => _build(clazz, builder);

  FutureOr<void> buildDeclarationsForMixin(IntrospectableMixinDeclaration mixin,
      MemberDeclarationBuilder builder) => _build(mixin, builder);

  FutureOr<void> _build(IntrospectableType type,
      MemberDeclarationBuilder builder) async {
    List<MethodDeclaration> methods = [];
    await _findAllMethods(builder, type, methods);
    int index = 0;
    String suffix = '';
    while (methods.any((m) => m.identifier.name == 'method$suffix')) {
      index++;
      suffix = '$index';
    }
    builder.declareInType(new DeclarationCode.fromString('''
  method$suffix() {}'''));
  }

  FutureOr<void> buildDeclarationsForMethod(MethodDeclaration method,
      MemberDeclarationBuilder builder) {
    // Do nothing. The applying of this will show up in the declarations phase
    // application order.
  }
}

macro

class SupertypesMacro implements ClassDefinitionMacro, MixinDefinitionMacro {
  const SupertypesMacro();
  FutureOr<void> buildDefinitionForClass(IntrospectableClassDeclaration clazz,
      TypeDefinitionBuilder builder) => _build(clazz, builder);

  FutureOr<void> buildDefinitionForMixin(IntrospectableMixinDeclaration mixin,
      TypeDefinitionBuilder builder) => _build(mixin, builder);

  FutureOr<void> _build(IntrospectableType type, TypeDefinitionBuilder builder) async {
    ParameterizedTypeDeclaration? superClass;
    if (type is IntrospectableClassDeclaration && type.superclass != null) {
      superClass =  await builder.typeDeclarationOf(type.superclass!.identifier)
          as ParameterizedTypeDeclaration?;
    }
    FunctionDefinitionBuilder getSuperClassBuilder = await builder.buildMethod(
        (await builder.methodsOf(type))
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
      MemberDeclarationBuilder builder) async {
    Identifier listIdentifier = await builder.resolveIdentifier(
        Uri.parse('dart:core'), 'List');
    builder.declareInType(new DeclarationCode.fromParts([
      field.type.code,
      ' get_${field.identifier.name}(',
      field.type.code,
      ' f) => ',
      field.identifier,
      ';',
    ]));
    builder.declareInType(new DeclarationCode.fromParts([
      field.type.code,
      ' Function() get_${field.identifier.name}Func(',
      field.type.code,
      ' Function(',
      field.type.code,
      ') f) => () => ',
      field.identifier,
      ';',
    ]));
    builder.declareInType(new DeclarationCode.fromParts([
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
    /*builder.declareInType(new DeclarationCode.fromParts([
      field.type.code,
      ' field_${field.identifier.name} = ',
      field.identifier,
      ';',
    ]));
    builder.declareInType(new DeclarationCode.fromParts([
      field.type.code,
      ' Function() field_${field.identifier.name}Func = () => ',
      field.identifier,
      ';',
    ]));
    builder.declareInType(new DeclarationCode.fromParts([
      listIdentifier,
      '<',
      field.type.code,
      '> field_${field.identifier.name}List = [',
      field.identifier,
      '];',
    ]));*/
  }

  FutureOr<void> buildDeclarationsForMethod(MethodDeclaration method,
      MemberDeclarationBuilder builder) async {
    Identifier listIdentifier = await builder.resolveIdentifier(
        Uri.parse('dart:core'), 'List');
    builder.declareInType(new DeclarationCode.fromParts([
      method.returnType.code,
      ' get_${method.identifier.name}() => ',
      method.identifier,
      '();',
    ]));
    builder.declareInType(new DeclarationCode.fromParts([
      method.returnType.code,
      ' Function() get_${method.identifier.name}Func() => () => ',
      method.identifier,
      '();',
    ]));
    builder.declareInType(new DeclarationCode.fromParts([
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
      MemberDeclarationBuilder builder) async {
    Identifier listIdentifier = await builder.resolveIdentifier(
        Uri.parse('dart:core'), 'List');
    builder.declareInType(new DeclarationCode.fromParts([
      constructor.positionalParameters.first.type.code,
      ' get_${constructor.identifier.name}() => throw "";',
    ]));
    builder.declareInType(new DeclarationCode.fromParts([
      constructor.positionalParameters.first.type.code,
      ' Function() get_${constructor.identifier.name}Func() => throw "";',
    ]));
    builder.declareInType(new DeclarationCode.fromParts([
      listIdentifier,
      '<',
      constructor.positionalParameters.first.type.code,
      '> get_${constructor.identifier.name}List() => throw "";',
    ]));
  }
}
