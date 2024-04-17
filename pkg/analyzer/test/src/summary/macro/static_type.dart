// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:macros/macros.dart';

/*macro*/ class IsExactly implements FunctionDefinitionMacro {
  const IsExactly();

  @override
  buildDefinitionForFunction(declaration, builder) async {
    var positional = declaration.positionalParameters.toList();
    var first = positional[0];
    var second = positional[1];

    var firstTypeCode = first.type.code;
    var secondTypeCode = second.type.code;

    var firstStaticType = await builder.resolve(firstTypeCode);
    var secondStaticType = await builder.resolve(secondTypeCode);

    var result = await firstStaticType.isExactly(secondStaticType);
    builder.augment(
      FunctionBodyCode.fromString('=> $result; // isExactly'),
    );
  }
}

/*macro*/ class IsExactly_enclosingClassInterface_formalParameterType
    implements MethodDefinitionMacro {
  const IsExactly_enclosingClassInterface_formalParameterType();

  @override
  buildDefinitionForMethod(declaration, builder) async {
    var enclosingType = await builder.declarationOf(declaration.definingType);
    enclosingType as ClassDeclaration;

    var firstType = enclosingType.interfaces.first;
    var secondType = declaration.positionalParameters.first.type;

    var firstTypeCode = firstType.code;
    var secondTypeCode = secondType.code;

    var firstStaticType = await builder.resolve(firstTypeCode);
    var secondStaticType = await builder.resolve(secondTypeCode);

    var result = await firstStaticType.isExactly(secondStaticType);

    builder.augment(
      FunctionBodyCode.fromString('=> $result; // isExactly'),
    );
  }
}

/*macro*/ class IsSubtype implements FunctionDefinitionMacro {
  const IsSubtype();

  @override
  Future<void> buildDefinitionForFunction(
    FunctionDeclaration declaration,
    FunctionDefinitionBuilder builder,
  ) async {
    var positional = declaration.positionalParameters.toList();
    var first = positional[0];
    var second = positional[1];

    var firstTypeCode = first.type.code;
    var secondTypeCode = second.type.code;

    var firstStaticType = await builder.resolve(firstTypeCode);
    var secondStaticType = await builder.resolve(secondTypeCode);

    var result = await firstStaticType.isSubtypeOf(secondStaticType);
    builder.augment(
      FunctionBodyCode.fromString('=> $result; // isSubtype'),
    );
  }
}
