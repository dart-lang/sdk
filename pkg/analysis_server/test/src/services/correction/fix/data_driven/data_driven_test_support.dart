// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/data_driven.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/code_template.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform_set.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform_set_manager.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/utilities/package_config_file_builder.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

import '../../../../../abstract_single_unit.dart';
import '../fix_processor.dart';

/// A base class defining support for writing fix processor tests for
/// data-driven fixes.
abstract class DataDrivenBulkFixProcessorTest extends BulkFixProcessorTest
    with DataDrivenFixProcessorTestMixin {}

/// A base class defining support for writing fix processor tests for
/// data-driven fixes.
abstract class DataDrivenFixProcessorTest extends FixProcessorTest
    with DataDrivenFixProcessorTestMixin {}

mixin DataDrivenFixProcessorTestMixin on AbstractSingleUnitTest {
  /// Returns the URI used to import the library created by [setPackageContent].
  String get importUri => 'package:p/lib.dart';

  FixKind get kind => DartFixKind.DATA_DRIVEN;

  /// Adds the file containing the data used by the data-driven fix with the
  /// given [content].
  void addPackageDataFile(String content) {
    newFile(
      '$workspaceRootPath/p/lib/${TransformSetManager.dataFileName}',
      content,
    );
  }

  /// Adds the file in the SDK containing the data used by the data-driven fix
  /// with the given [content].
  void addSdkDataFile(String content) {
    newFile(
      '${sdkRoot.path}/lib/_internal/${TransformSetManager.dataFileName}',
      content,
    );
  }

  /// Returns a code template that will produce the given [text].
  CodeTemplate codeTemplate(String text) {
    return CodeTemplate(CodeTemplateKind.expression, [
      TemplateText(text),
    ], null);
  }

  /// A method that can be used as an error filter to ignore any unused_import
  /// diagnostics.
  bool ignoreUnusedImport(Diagnostic diagnostic) =>
      diagnostic.diagnosticCode != WarningCode.unusedImport;

  /// Sets the content of the library that defines the element referenced by the
  /// data on which this test is based.
  void setPackageContent(String content) {
    newFile('$workspaceRootPath/p/lib/lib.dart', content);
    writeTestPackageConfig(
      config:
          PackageConfigFileBuilder()
            ..add(name: 'p', rootPath: '$workspaceRootPath/p'),
    );
  }

  /// Sets the data on which this test is based.
  void setPackageData(Transform transform) {
    DataDriven.transformSetsForTests = [
      TransformSet()..addTransform(transform),
    ];
  }

  @override
  Future<void> tearDown() async {
    DataDriven.transformSetsForTests = null;
    TransformSetManager.instance.clearCache();
    await super.tearDown();
  }
}
