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
