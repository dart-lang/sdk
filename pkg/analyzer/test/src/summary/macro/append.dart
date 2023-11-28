// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/api.dart';

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

/*macro*/ class DeclareInLibrary implements ClassDeclarationsMacro {
  final String code;

  const DeclareInLibrary(this.code);

  @override
  buildDeclarationsForClass(clazz, builder) async {
    builder.declareInLibrary(
      DeclarationCode.fromString(code),
    );
  }
}

/*macro*/ class DeclareInType implements ClassDeclarationsMacro {
  final String code;

  const DeclareInType(this.code);

  @override
  buildDeclarationsForClass(clazz, builder) async {
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
