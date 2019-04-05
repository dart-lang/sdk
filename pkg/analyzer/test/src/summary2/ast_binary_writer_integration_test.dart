// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary2/ast_binary_reader.dart';
import 'package:analyzer/src/summary2/ast_binary_writer.dart';
import 'package:analyzer/src/summary2/ast_text_printer.dart';
import 'package:analyzer/src/summary2/linked_bundle_context.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/summary2/linked_unit_context.dart';
import 'package:analyzer/src/summary2/linking_bundle_context.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/summary2/tokens_writer.dart';
import 'package:front_end/src/testing/package_root.dart' as package_root;
import 'package:test/test.dart';

import '../dart/ast/parse_base.dart';

main() {
  group('AstBinaryWriter |', () {
    _buildTests();
  });
}

/// Parse the [code] into AST, serialize using [AstBinaryWriter], read using
/// [AstBinaryReader], and dump back into code. The resulting code must be
/// the same as the input [code].
///
/// Whitespaces and newlines are normalized and ignored.
/// Files with parsing errors are silently skipped.
void _assertCode(ParseBase base, String code) {
  code = code.trimRight();
  code = code.replaceAll('\t', ' ');
  code = code.replaceAll('\r\n', '\n');
  code = code.replaceAll('\r', '\n');

  LineInfo lineInfo;
  LinkedNodeUnit linkedNodeUnit;
  {
    var path = base.newFile('/home/test/lib/test.dart', content: code).path;

    ParseResult parseResult;
    try {
      parseResult = base.parseUnit(path);
    } catch (e) {
      return;
    }

    // Code with parsing errors cannot be restored.
    if (parseResult.errors.isNotEmpty) {
      return;
    }

    lineInfo = parseResult.lineInfo;
    var originalUnit = parseResult.unit;

    TokensResult tokensResult = TokensWriter().writeTokens(
      originalUnit.beginToken,
      originalUnit.endToken,
    );
    var tokensContext = tokensResult.toContext();

    var rootReference = Reference.root();
    var dynamicRef = rootReference.getChild('dart:core').getChild('dynamic');

    var linkingBundleContext = LinkingBundleContext(dynamicRef);
    var writer = new AstBinaryWriter(linkingBundleContext, tokensContext);
    var unitLinkedNode = writer.writeNode(originalUnit);

    linkedNodeUnit = LinkedNodeUnitBuilder(
      node: unitLinkedNode,
      tokens: tokensResult.tokens,
    );
  }

  var rootReference = Reference.root();
  var bundleContext = LinkedBundleContext(
    LinkedElementFactory(null, null, rootReference),
    LinkedNodeBundleBuilder(
      references: LinkedNodeReferencesBuilder(name: ['']),
    ),
  );
  var unitContext = LinkedUnitContext(bundleContext, null, linkedNodeUnit);

  var reader = AstBinaryReader(unitContext);
  var deserializedUnit = reader.readNode(linkedNodeUnit.node);

  var buffer = StringBuffer();
  deserializedUnit.accept(
    AstTextPrinter(buffer, lineInfo),
  );

  expect(buffer.toString(), code);
}

void _buildTests() {
  var provider = PhysicalResourceProvider.INSTANCE;
  var pathContext = provider.pathContext;

  var packageRoot = pathContext.normalize(package_root.packageRoot);
  var dartFiles = Directory(packageRoot)
      .listSync(recursive: true)
      .whereType<File>()
      .where((e) => e.path.endsWith('.dart'))
      .toList();

  var base = ParseBase();
  for (var file in dartFiles) {
    // TODO(scheglov) https://github.com/dart-lang/sdk/issues/36262
    if (file.path.endsWith('issue_31198.dart')) {
      continue;
    }

    var relPath = pathContext.relative(file.path, from: packageRoot);
    test(relPath, () {
      var code = file.readAsStringSync();
      _assertCode(base, code);
    });
  }
}
