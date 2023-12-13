// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/api.dart';

/*macro*/ class IsExactly implements FunctionDefinitionMacro {
  const IsExactly();

  @override
  buildDefinitionForFunction(declaration, builder) async {
    final positional = declaration.positionalParameters.toList();
    final first = positional[0];
    final second = positional[1];

    final firstTypeCode = first.type.code;
    final secondTypeCode = second.type.code;

    final firstStaticType = await builder.resolve(firstTypeCode);
    final secondStaticType = await builder.resolve(secondTypeCode);

    final result = await firstStaticType.isExactly(secondStaticType);
    builder.augment(
      FunctionBodyCode.fromString('=> $result; // isExactly'),
    );
  }
}
