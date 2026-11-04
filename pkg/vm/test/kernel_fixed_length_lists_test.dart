// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:front_end/src/api_unstable/vm.dart'
    show computePlatformBinariesLocation;
import 'package:kernel/ast.dart';
import 'package:kernel/binary/ast_from_binary.dart';
import 'package:kernel/library_index.dart';
import 'package:test/test.dart';
import 'package:vm/metadata/inferred_type.dart';

void main() {
  final buildDir = computePlatformBinariesLocation(forceBuildDir: true);

  // Verify that all Dart SDK tools we ship in AOT form got the correct inferred
  // fixed length list types in the Kernel AST fields.
  for (final dillPath in [
    'gen/utils/dart2wasm/dart2wasm_product.aot.dill',
    'gen/utils/gen_kernel/gen_kernel.aot.dill',
    'gen/utils/kernel-service/frontend_server_aot_product.aot.dill',
    'gen/utils/compiler/dart2js_aot_product.aot.dill',
    'gen/utils/ddc/dartdevc_aot_product.aot.dill',
    'gen/utils/bazel/kernel_worker_aot_product.aot.dill',
  ]) {
    test('$dillPath infers fixed-length _Array for Kernel AST lists', () {
      final dillFile = File.fromUri(buildDir.resolve(dillPath));
      if (!dillFile.existsSync()) {
        fail('Expected AOT dill file to exist: ${dillFile.path}');
      }
      verifyKernelAstFixedLengthLists(dillFile);
    });
  }
}

void verifyKernelAstFixedLengthLists(File dillFile) {
  final (component, inferredTypes) = loadComponentWithInferredTypes(dillFile);
  final index = LibraryIndex(component, [
    'dart:core',
    'package:kernel/ast.dart',
  ]);

  final fixedListTypes = {
    for (final name in [
      'ConstantList',
      'ConstantMapEntryList',
      'DartTypeList',
      'ExpressionList',
      'NamedDartTypeList',
      'NamedExpressionList',
      'NamedParameterList',
      'PositionalParameterList',
      'StructuralParameterList',
      'TypeParameterList',
    ])
      index.getExtensionType('package:kernel/ast.dart', name),
  };
  final fixedArrayClasses = {
    index.getClass('dart:core', '_Array'),
    index.getClass('dart:core', '_List'),
    index.getClass('dart:core', '_ImmutableList'),
  };

  final seenListTypes = <ExtensionTypeDeclaration>{};
  final verified = <String>[];
  final failures = <String>[];
  for (final cls in index.getLibrary('package:kernel/ast.dart').classes) {
    for (final field in cls.fields) {
      final type = field.type;
      if (type is! ExtensionType ||
          !fixedListTypes.contains(type.extensionTypeDeclaration)) {
        continue;
      }
      seenListTypes.add(type.extensionTypeDeclaration);

      final inferred = inferredTypes[field];
      final inferredClass = inferred?.dartType?.classNode;
      final description =
          '${cls.name}.${field.name.text} '
          '(${type.extensionTypeDeclaration.name}) -> $inferred';
      if (fixedArrayClasses.contains(inferredClass)) {
        verified.add(description);
      } else {
        failures.add(description);
      }
    }
  }

  print(
    'Verified ${verified.length} Kernel AST fixed-length list fields in '
    '${dillFile.path}:\n  ${verified.join('\n  ')}',
  );

  expect(
    failures,
    isEmpty,
    reason:
        'Expected fixed-length _Array for Kernel AST list fields in '
        '${dillFile.path}:\n  ${failures.join('\n  ')}',
  );
  expect(seenListTypes, equals(fixedListTypes));
}

(Component, Map<TreeNode, InferredType>) loadComponentWithInferredTypes(
  File dillFile,
) {
  final component = Component();
  final inferredTypeRepo = InferredTypeMetadataRepository();
  component.addMetadataRepository(inferredTypeRepo);
  BinaryBuilderWithMetadata(
    dillFile.readAsBytesSync(),
  ).readComponent(component);
  return (component, inferredTypeRepo.mapping);
}
