// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/codegen/tools.dart';
import 'package:front_end/src/codegen/tools.dart';
import 'package:path/path.dart' as path;

import 'api.dart';
import 'codegen_dart_protocol.dart';
import 'from_html.dart';
import 'implied_types.dart';

GeneratedFile target(bool responseRequiresRequestTime) =>
    new GeneratedFile('lib/protocol/protocol_common.dart', (String pkgPath) {
      CodegenCommonVisitor visitor = new CodegenCommonVisitor(
          path.basename(pkgPath),
          responseRequiresRequestTime,
          readApi(pkgPath));
      return visitor.collectCode(visitor.visitApi);
    });

/**
 * A visitor that produces Dart code defining the common types associated with
 * the API.
 */
class CodegenCommonVisitor extends CodegenProtocolVisitor {
  /**
   * Initialize a newly created visitor to generate code in the package with the
   * given [packageName] corresponding to the types in the given [api] that are
   * common to multiple protocols.
   */
  CodegenCommonVisitor(
      String packageName, bool responseRequiresRequestTime, Api api)
      : super(packageName, responseRequiresRequestTime, api);

  @override
  void emitImports() {
    writeln("import 'dart:convert' hide JsonDecoder;");
    writeln();
    writeln("import 'package:analyzer/src/generated/utilities_general.dart';");
    writeln("import 'package:$packageName/protocol/protocol.dart';");
    writeln(
        "import 'package:$packageName/src/protocol/protocol_internal.dart';");
  }

  @override
  List<ImpliedType> getClassesToEmit() {
    List<ImpliedType> types = impliedTypes.values.where((ImpliedType type) {
      ApiNode node = type.apiNode;
      return node is TypeDefinition && node.isExternal;
    }).toList();
    types.sort((first, second) =>
        capitalize(first.camelName).compareTo(capitalize(second.camelName)));
    return types;
  }
}
