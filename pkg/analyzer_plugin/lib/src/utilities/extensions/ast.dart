// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';

extension NamedTypeExtension on NamedType {
  String get qualifiedName {
    final importPrefix = this.importPrefix;
    if (importPrefix != null) {
      return '${importPrefix.name.lexeme}.${name2.lexeme}';
    } else {
      return name2.lexeme;
    }
  }
}
