// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analyzer/utilities/package_config_file_builder.dart';
import 'package:language_server_protocol/protocol_custom_generated.dart';
import 'package:language_server_protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExhaustiveFlutterWidgetPreviewsTest);
  });
}

@reflectiveTest
class ExhaustiveFlutterWidgetPreviewsTest
    extends AbstractLspAnalysisServerTest {
  @override
  bool get addFlutterLocalizationsPackageDep => true;

  Future<FlutterWidgetPreviews?> getFlutterWidgetPreviews(Uri uri) {
    var request = makeRequest(
      CustomMethods.getFlutterWidgetPreviews,
      TextDocumentIdentifier(uri: uri),
    );
    return expectSuccessfulResponseTo(request, FlutterWidgetPreviews.fromJson);
  }

  Future<FlutterWidgetPreviews?> getWorkspaceFlutterWidgetPreviews() {
    var request = makeRequest(
      CustomMethods.getWorkspaceFlutterWidgetPreviews,
      null,
    );
    return expectSuccessfulResponseTo(request, FlutterWidgetPreviews.fromJson);
  }

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(flutter: true);
    addFlutter();
    addSkyEngine(sdkPath: sdkRoot.path);
    failTestOnErrorDiagnostic = false;
  }

  Future<void> test_addDeletePreviews() async {
    var filePath = join(projectFolderPath, 'lib', 'previews.dart');
    var fileUri = Uri.file(filePath);
    newFile(filePath, '''
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

@Preview(name: 'Initial')
Widget preview1() => Text('1');
''');

    await initialize();
    var result = await getFlutterWidgetPreviews(fileUri);
    expect(result!.previews, hasLength(1));
    expect(result.previews.first.functionName, 'preview1');

    // Add a preview
    newFile(filePath, '''
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

@Preview(name: 'Initial')
Widget preview1() => Text('1');

@Preview(name: 'Added')
Widget preview2() => Text('2');
''');

    result = await getFlutterWidgetPreviews(fileUri);
    expect(result!.previews, hasLength(2));
    expect(result.previews.any((p) => p.functionName == 'preview2'), isTrue);

    // Delete a preview
    newFile(filePath, '''
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

@Preview(name: 'Added')
Widget preview2() => Text('2');
''');

    result = await getFlutterWidgetPreviews(fileUri);
    expect(result!.previews, hasLength(1));
    expect(result.previews.first.functionName, 'preview2');
  }

  Future<void> test_annotationProperties() async {
    newFile(join(projectFolderPath, 'lib', 'previews.dart'), '''
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

class MyMultiPreview extends MultiPreview {
  const MyMultiPreview(List<Preview> previews) : super(previews);
}

@Preview(
  name: 'Custom Name',
  group: 'My Group',
)
Widget myPreview() => Text('Hello');

@MyMultiPreview([
  Preview(name: 'Light', brightness: Brightness.light),
  Preview(name: 'Dark', brightness: Brightness.dark),
])
Widget multiPreview() => Text('Multi');
''');

    await initialize();
    var result = await getFlutterWidgetPreviews(
      Uri.file(join(projectFolderPath, 'lib', 'previews.dart')),
    );

    expect(result, isNotNull);
    expect(result!.previews, hasLength(2));

    var custom = result.previews.firstWhere(
      (p) => p.functionName == 'myPreview',
    );
    expect(custom.previewAnnotation, contains("name: 'Custom Name'"));
    expect(custom.previewAnnotation, contains("group: 'My Group'"));
    expect(custom.isMultiPreview, isFalse);

    var multi = result.previews.firstWhere(
      (p) => p.functionName == 'multiPreview',
    );
    expect(multi.isMultiPreview, isTrue);
    // Since namespacing is applied, we check for the literal value without assuming prefixing.
    expect(multi.previewAnnotation, contains("'Light'"));
    expect(multi.previewAnnotation, contains('Brightness.light'));
    expect(multi.previewAnnotation, contains("'Dark'"));
    expect(multi.previewAnnotation, contains('Brightness.dark'));
  }

  Future<void> test_annotationSourceGeneration() async {
    newFile(join(projectFolderPath, 'lib', 'previews.dart'), '''
    import 'package:flutter/material.dart';
    import 'package:flutter/widget_previews.dart';

    enum MyEnum { a, b }

    class ComplexPreview extends Preview {
    final List<int> list;
    final Map<String, dynamic> map;
    final MyEnum e;
    final (int, {String s}) record;
    final Size? size;

    const ComplexPreview({
    required super.name,
    required this.list,
    required this.map,
    required this.e,
    required this.record,
    this.size,
    });
    }

    @ComplexPreview(
    name: 'Complex',
    list: [1, 2, 3],
    map: {'key': 'value', 'nested': [true, false]},
    e: MyEnum.a,
    record: (1, s: 'hello'),
    size: Size(100, 200),
    )
    Widget complexPreview() => Text('Complex');

    class CustomSize {
    final double value;
    const CustomSize.square(this.value);
    }

    class NamedConstructorPreview extends Preview {
    final CustomSize size;
    const NamedConstructorPreview({required super.name, required this.size});
    }

    @NamedConstructorPreview(
    name: 'Named Constructor',
    size: CustomSize.square(150),
    )
    Widget namedConstructorPreview() => Text('Named');
    ''');

    await initialize();
    var result = await getFlutterWidgetPreviews(
      Uri.file(join(projectFolderPath, 'lib', 'previews.dart')),
    );

    expect(result, isNotNull);
    expect(result!.previews, hasLength(2));

    var complex = result.previews.firstWhere(
      (p) => p.functionName == 'complexPreview',
    );
    var source = complex.previewAnnotation;

    // Validate that namespaces/prefixes are applied (e.g., _i1.ComplexPreview)
    // and that nested structures are correctly formatted.
    expect(source, contains("name: 'Complex'"));
    expect(source, contains('list: [1, 2, 3]'));
    expect(source, contains("map: {'key': 'value', 'nested': [true, false]}"));
    expect(source, contains('MyEnum.a'));
    expect(source, contains("record: (1, s: 'hello')"));
    expect(source, contains('Size(100.0, 200.0)'));

    var named = result.previews.firstWhere(
      (p) => p.functionName == 'namedConstructorPreview',
    );
    expect(named.previewAnnotation, contains('CustomSize.square(150.0)'));
  }

  Future<void> test_customPreviewTypes() async {
    newFile(join(projectFolderPath, 'lib', 'previews.dart'), '''
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

class MyPreview extends Preview {
  final String customAttribute;
  const MyPreview({required String name, required this.customAttribute}) : super(name: name);
}

@MyPreview(name: 'Custom', customAttribute: 'Some Value')
Widget customPreview() => Text('Custom');
''');

    await initialize();
    var result = await getFlutterWidgetPreviews(
      Uri.file(join(projectFolderPath, 'lib', 'previews.dart')),
    );

    expect(result, isNotNull);
    expect(result!.previews, hasLength(1));
    var preview = result.previews.first;
    expect(preview.functionName, 'customPreview');
    expect(preview.previewAnnotation, contains("name: 'Custom'"));
    expect(
      preview.previewAnnotation,
      contains("customAttribute: 'Some Value'"),
    );
  }

  Future<void> test_errorsAndPropagation() async {
    var depPath = join(projectFolderPath, 'lib', 'dep.dart');
    var mainPath = join(projectFolderPath, 'lib', 'main.dart');
    var mainUri = Uri.file(mainPath);

    newFile(depPath, 'int x = "not an int"; // Error');
    newFile(mainPath, '''
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'dep.dart';

@Preview(name: 'Has Dep Error')
Widget preview() => Text(x.toString());
''');

    await initialize();
    var result = await getFlutterWidgetPreviews(mainUri);
    expect(result!.previews, hasLength(1));
    var preview = result.previews.first;
    expect(preview.hasError, isFalse);
    expect(preview.dependencyHasErrors, isTrue);

    // Fix error in dep
    newFile(depPath, 'int x = 1;');
    result = await getFlutterWidgetPreviews(mainUri);
    expect(result!.previews.first.dependencyHasErrors, isFalse);

    // Add error to main
    newFile(mainPath, '''
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'dep.dart';

@Preview(name: 'Has Local Error')
Widget preview() => Text(x.toString()) // Missing semicolon
''');
    result = await getFlutterWidgetPreviews(mainUri);
    expect(result!.previews.first.hasError, isTrue);
    expect(result.previews.first.dependencyHasErrors, isFalse);
  }

  Future<void> test_parts() async {
    var mainPath = join(projectFolderPath, 'lib', 'main.dart');
    var partPath = join(projectFolderPath, 'lib', 'part.dart');
    var mainUri = Uri.file(mainPath);

    newFile(mainPath, '''
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
part 'part.dart';

@Preview(name: 'Main Preview')
Widget mainPreview() => Text('Main');
''');

    newFile(partPath, '''
part of 'main.dart';

@Preview(name: 'Part Preview')
Widget partPreview() => Text('Part');
''');

    await initialize();
    var result = await getFlutterWidgetPreviews(mainUri);
    expect(result!.previews, hasLength(2));
    expect(result.previews.any((p) => p.functionName == 'mainPreview'), isTrue);
    expect(result.previews.any((p) => p.functionName == 'partPreview'), isTrue);
    expect(result.previews.map((p) => p.libraryUri.toString()).toSet(), {
      'package:test/main.dart',
    });
    expect(result.scriptUris.map((e) => e.toString()), [
      'file:///home/my_project/lib/main.dart',
      'file:///home/my_project/lib/part.dart',
    ]);
  }

  Future<void> test_pubWorkspace() async {
    // Setup a workspace with two packages
    newFile(join(projectFolderPath, 'pubspec.yaml'), '''
workspace:
  - pkgs/a
  - pkgs/b
''');
    newFile(join(projectFolderPath, 'pkgs', 'a', 'pubspec.yaml'), '''
name: a
environment:
  sdk: ^3.7.0
dependencies:
  flutter:
    sdk: flutter
''');
    newFile(join(projectFolderPath, 'pkgs', 'b', 'pubspec.yaml'), '''
name: b
environment:
  sdk: ^3.7.0
dependencies:
  flutter:
    sdk: flutter
''');

    newFile(join(projectFolderPath, 'pkgs', 'a', 'lib', 'a.dart'), '''
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
@Preview(name: 'Pkg A')
Widget a() => Text('A');
''');
    newFile(join(projectFolderPath, 'pkgs', 'b', 'lib', 'b.dart'), '''
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
@Preview(name: 'Pkg B')
Widget b() => Text('B');
''');

    var config = PackageConfigFileBuilder();
    // Do NOT add 'test' package here as writeTestPackageConfig will add it.
    config.add(name: 'a', rootPath: join(projectFolderPath, 'pkgs', 'a'));
    config.add(name: 'b', rootPath: join(projectFolderPath, 'pkgs', 'b'));

    writeTestPackageConfig(config: config, flutter: true);

    await initialize();
    var result = await getWorkspaceFlutterWidgetPreviews();
    expect(result!.previews, hasLength(2));
    expect(result.previews.any((p) => p.packageName == 'a'), isTrue);
    expect(result.previews.any((p) => p.packageName == 'b'), isTrue);
  }

  Future<void> test_workspacePreviews() async {
    newFile(join(projectFolderPath, 'lib', 'a.dart'), '''
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
@Preview(name: 'A')
Widget a() => Text('A');
''');
    newFile(join(projectFolderPath, 'lib', 'b.dart'), '''
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
@Preview(name: 'B')
Widget b() => Text('B');
''');

    await initialize();
    var result = await getWorkspaceFlutterWidgetPreviews();
    expect(result!.previews, hasLength(2));
    expect(result.previews.any((p) => p.functionName == 'a'), isTrue);
    expect(result.previews.any((p) => p.functionName == 'b'), isTrue);
  }
}
