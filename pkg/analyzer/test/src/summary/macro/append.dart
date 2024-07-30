// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:macros/macros.dart';

/// Resolves top-level identifier references of form `{{uri@name}}`.
Future<List<Object>> resolveIdentifiers(
  TypePhaseIntrospector introspector,
  String withIdentifiers,
) async {
  var result = <Object>[];
  var lastMatchEnd = 0;

  void addStringPart(int end) {
    var str = withIdentifiers.substring(lastMatchEnd, end);
    if (str.isNotEmpty) {
      result.add(str);
    }
  }

  var pattern = RegExp(r'\{\{(.+?)@(\w+?)\}\}');
  for (var match in pattern.allMatches(withIdentifiers)) {
    addStringPart(match.start);
    // ignore: deprecated_member_use
    var identifier = await introspector.resolveIdentifier(
      Uri.parse(match.group(1)!),
      match.group(2)!,
    );
    result.add(identifier);
    lastMatchEnd = match.end;
  }

  addStringPart(withIdentifiers.length);
  return result;
}

/*macro*/ class AppendInterface implements ClassTypesMacro, MixinTypesMacro {
  final String code;

  const AppendInterface(this.code);

  @override
  buildTypesForClass(clazz, builder) async {
    await _append(builder);
  }

  @override
  buildTypesForMixin(clazz, builder) async {
    await _append(builder);
  }

  Future<void> _append(InterfaceTypesBuilder builder) async {
    var parts = await resolveIdentifiers(builder, code);
    builder.appendInterfaces([
      RawTypeAnnotationCode.fromParts(parts),
    ]);
  }
}

/*macro*/ class AppendMixin implements ClassTypesMacro {
  final String code;

  const AppendMixin(this.code);

  @override
  buildTypesForClass(clazz, builder) async {
    await _append(builder);
  }

  Future<void> _append(MixinTypesBuilder builder) async {
    var parts = await resolveIdentifiers(builder, code);
    builder.appendMixins([
      RawTypeAnnotationCode.fromParts(parts),
    ]);
  }
}

/*macro*/ class AugmentDefinition implements MethodDefinitionMacro {
  final String code;

  const AugmentDefinition(this.code);

  @override
  buildDefinitionForMethod(method, builder) {
    builder.augment(
      FunctionBodyCode.fromString(code),
    );
  }
}

/*macro*/ class DeclareClassAppendInterfaceRawCode implements ClassTypesMacro {
  final String interfaceName;

  const DeclareClassAppendInterfaceRawCode(
    this.interfaceName,
  );

  @override
  buildTypesForClass(clazz, builder) {
    builder.declareType(
      interfaceName,
      DeclarationCode.fromString(
        'abstract interface class $interfaceName {}',
      ),
    );

    builder.appendInterfaces([
      RawTypeAnnotationCode.fromString(interfaceName),
    ]);
  }
}

/*macro*/ class DeclareInLibrary
    implements ClassDeclarationsMacro, FunctionDeclarationsMacro {
  final String code;

  const DeclareInLibrary(this.code);

  @override
  buildDeclarationsForClass(clazz, builder) async {
    await _declare(builder);
  }

  @override
  buildDeclarationsForFunction(clazz, builder) async {
    await _declare(builder);
  }

  Future<void> _declare(DeclarationBuilder builder) async {
    var parts = await resolveIdentifiers(builder, code);
    builder.declareInLibrary(
      DeclarationCode.fromParts(parts),
    );
  }
}

/*macro*/ class DeclareInType
    implements
        ClassDeclarationsMacro,
        ConstructorDeclarationsMacro,
        FieldDeclarationsMacro,
        MethodDeclarationsMacro {
  final String code;

  const DeclareInType(this.code);

  @override
  buildDeclarationsForClass(clazz, builder) async {
    await _declare(builder);
  }

  @override
  buildDeclarationsForConstructor(constructor, builder) async {
    await _declare(builder);
  }

  @override
  buildDeclarationsForField(field, builder) async {
    await _declare(builder);
  }

  @override
  buildDeclarationsForMethod(method, builder) async {
    await _declare(builder);
  }

  Future<void> _declare(MemberDeclarationBuilder builder) async {
    var parts = await resolveIdentifiers(builder, code);
    builder.declareInType(
      DeclarationCode.fromParts(parts),
    );
  }
}

/*macro*/ class DeclareType implements ClassTypesMacro {
  final String name;
  final String code;

  const DeclareType(this.name, this.code);

  const DeclareType.named(this.name, this.code);

  @override
  buildTypesForClass(clazz, builder) async {
    var parts = await resolveIdentifiers(builder, code);
    builder.declareType(
      name,
      DeclarationCode.fromParts(parts),
    );
  }
}

/*macro*/ class DeclareTypesPhase
    implements ClassTypesMacro, FunctionTypesMacro {
  final String typeName;
  final String code;

  const DeclareTypesPhase(this.typeName, this.code);

  @override
  buildTypesForClass(clazz, builder) async {
    await _declare(builder);
  }

  @override
  buildTypesForFunction(clazz, builder) async {
    await _declare(builder);
  }

  Future<void> _declare(TypeBuilder builder) async {
    var parts = await resolveIdentifiers(builder, code);
    builder.declareType(
      typeName,
      DeclarationCode.fromParts(parts),
    );
  }
}

/*macro*/ class SetExtendsType implements ClassTypesMacro {
  final String typeNameStr;
  final List<String> typeArgumentStrList;

  SetExtendsType(
    this.typeNameStr,
    this.typeArgumentStrList,
  );

  @override
  buildTypesForClass(clazz, builder) async {
    var typeNameParts = await resolveIdentifiers(builder, typeNameStr);
    var typeName = typeNameParts.single as Identifier;

    var typeArguments = <TypeAnnotationCode>[];
    for (var typeArgumentStr in typeArgumentStrList) {
      var parts = await resolveIdentifiers(builder, typeArgumentStr);
      var typeArgument = RawTypeAnnotationCode.fromParts(parts);
      typeArguments.add(typeArgument);
    }

    builder.extendsType(
      NamedTypeAnnotationCode(
        name: typeName,
        typeArguments: typeArguments,
      ),
    );
  }
}
