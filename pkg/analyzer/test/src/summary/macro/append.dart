// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/api.dart';

/// Resolves top-level identifier references of form `{{uri@name}}`.
Future<List<Object>> resolveIdentifiers(
  TypePhaseIntrospector introspector,
  String withIdentifiers,
) async {
  final result = <Object>[];
  var lastMatchEnd = 0;

  void addStringPart(int end) {
    final str = withIdentifiers.substring(lastMatchEnd, end);
    result.add(str);
  }

  final pattern = RegExp(r'\{\{(.+)@(\w+)\}\}');
  for (final match in pattern.allMatches(withIdentifiers)) {
    addStringPart(match.start);
    // ignore: deprecated_member_use
    final identifier = await introspector.resolveIdentifier(
      Uri.parse(match.group(1)!),
      match.group(2)!,
    );
    result.add(identifier);
    lastMatchEnd = match.end;
  }

  addStringPart(withIdentifiers.length);
  return result;
}

Future<NamedTypeAnnotationCode> _codeA(TypePhaseIntrospector builder) async {
  return NamedTypeAnnotationCode(
    // ignore:deprecated_member_use
    name: await builder.resolveIdentifier(
      Uri.parse('package:test/append.dart'),
      'A',
    ),
  );
}

class A {}

/*macro*/ class AppendInterfaceA implements ClassTypesMacro, MixinTypesMacro {
  const AppendInterfaceA();

  @override
  buildTypesForClass(clazz, builder) async {
    builder.appendInterfaces([
      await _codeA(builder),
    ]);
  }

  @override
  buildTypesForMixin(clazz, builder) async {
    builder.appendInterfaces([
      await _codeA(builder),
    ]);
  }
}

/*macro*/ class AppendMixinA implements ClassTypesMacro {
  const AppendMixinA();

  @override
  buildTypesForClass(clazz, builder) async {
    builder.appendMixins([
      await _codeA(builder),
    ]);
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
    final parts = await resolveIdentifiers(builder, code);
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
    _declare(builder);
  }

  @override
  buildDeclarationsForConstructor(constructor, builder) async {
    _declare(builder);
  }

  @override
  buildDeclarationsForField(field, builder) async {
    _declare(builder);
  }

  @override
  buildDeclarationsForMethod(method, builder) async {
    _declare(builder);
  }

  void _declare(MemberDeclarationBuilder builder) {
    builder.declareInType(
      DeclarationCode.fromString(code),
    );
  }
}

/*macro*/ class DeclareType implements ClassTypesMacro {
  final String name;
  final String code;

  const DeclareType(this.name, this.code);

  const DeclareType.named(this.name, this.code);

  @override
  buildTypesForClass(clazz, builder) {
    builder.declareType(
      name,
      DeclarationCode.fromString(code),
    );
  }
}
