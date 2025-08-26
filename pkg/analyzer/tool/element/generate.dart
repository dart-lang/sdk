// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server_client/protocol.dart';
import 'package:analysis_server_client/server.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/utilities/extensions/object.dart';
import 'package:analyzer/src/utilities/extensions/string.dart';
import 'package:analyzer_testing/package_root.dart' as pkg_root;
import 'package:analyzer_utilities/tools.dart';
import 'package:path/path.dart';

void main() async {
  await GeneratedContent.generateAll(pkg_root.packageRoot, await allTargets);
}

Future<List<GeneratedContent>> get allTargets async {
  var astLibrary = await _getElementLibrary();
  return <GeneratedContent>[
    GeneratedFile('analyzer/lib/src/dart/element/element.g.dart', (_) async {
      var generator = _ElementGenerator(astLibrary);
      return await generator.generate();
    }),
  ];
}

String get _analyzerPath => normalize(join(pkg_root.packageRoot, 'analyzer'));

Future<String> _formatSortCode(String path, String code) async {
  var server = Server();
  await server.start();
  server.listenToOutput();

  await server.send('analysis.setAnalysisRoots', {
    'included': [path],
    'excluded': [],
  });

  Future<void> updateContent() async {
    await server.send('analysis.updateContent', {
      'files': {
        path: {'type': 'add', 'content': code},
      },
    });
  }

  await updateContent();
  var formatResponse = await server.send('edit.format', {
    'file': path,
    'selectionOffset': 0,
    'selectionLength': code.length,
  });
  var formatResult = EditFormatResult.fromJson(
    ResponseDecoder(null),
    'result',
    formatResponse,
  );
  code = SourceEdit.applySequence(code, formatResult.edits);

  await updateContent();
  var sortResponse = await server.send('edit.sortMembers', {'file': path});
  var sortResult = EditSortMembersResult.fromJson(
    ResponseDecoder(null),
    'result',
    sortResponse,
  );
  code = SourceEdit.applySequence(code, sortResult.edit.edits);

  await server.kill();
  return code;
}

Future<LibraryElement> _getElementLibrary() async {
  var collection = AnalysisContextCollection(includedPaths: [_analyzerPath]);
  var analysisContext = collection.contextFor(_analyzerPath);
  var analysisSession = analysisContext.currentSession;

  var libraryResult = await analysisSession.getLibraryByUri(
    'package:analyzer/src/dart/element/element.dart',
  );
  libraryResult as LibraryElementResult;
  return libraryResult.element;
}

class _ElementGenerator {
  final LibraryElement astLibrary;

  final StringBuffer out = StringBuffer('''
// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Run 'dart pkg/analyzer/tool/element/generate.dart' to update.

part of 'element.dart';
''');

  _ElementGenerator(this.astLibrary);

  Future<String> generate() async {
    _writeMixins();
    var resultPath = normalize(
      join(_analyzerPath, 'lib', 'src', 'dart', 'element', 'element.g.dart'),
    );
    return _formatSortCode(resultPath, out.toString());
  }

  void _writeMixins() {
    for (var generateFragment in astLibrary.generateFragments) {
      var fragmentName = generateFragment.element.name;
      out.write('''
mixin _${fragmentName}Mixin {
  bool hasModifier(Modifier modifier);
  void setModifier(Modifier modifier, bool value);
''');
      for (var modifier in generateFragment.modifiers) {
        var name = modifier.name;
        var constName = name.removePrefixOrSelf('is').toScreamingSnake();
        out.write('''
${modifier.documentationComment ?? ''}
bool get $name {
  return hasModifier(Modifier.$constName);
}

set $name(bool value) {
  setModifier(Modifier.$constName, value);
}
''');
      }
      out.writeln('}\n');
    }
  }
}

class _GenerateElementModifier {
  final String name;
  final String? documentationComment;

  _GenerateElementModifier({
    required this.name,
    required this.documentationComment,
  });
}

class _GenerateFragment {
  final ClassElement element;
  final List<_GenerateElementModifier> modifiers;

  _GenerateFragment(this.element, this.modifiers);

  bool get isConcrete => !element.isAbstract;

  _GenerateFragment? get superNode {
    return element.supertype?.element
        .ifTypeOrNull<ClassElement>()
        ?.asGenerateFragment;
  }
}

extension on ClassElement {
  _GenerateFragment? get asGenerateFragment {
    var generateObject = metadata.annotations
        .map((annotation) {
          var generateObject = annotation.computeConstantValue();
          var generateObjectType = generateObject?.type;
          if (generateObjectType?.element?.name != 'GenerateFragmentImpl') {
            return null;
          }
          return generateObject;
        })
        .nonNulls
        .firstOrNull;
    if (generateObject == null) {
      return null;
    }

    var modifiersField = generateObject.getField('modifiers')!;
    var modifiers = modifiersField.toListValue()!.map((modifier) {
      var variable = modifier.variable!;
      return _GenerateElementModifier(
        name: variable.name!,
        documentationComment: variable.documentationComment,
      );
    }).toList();
    return _GenerateFragment(this, modifiers);
  }
}

extension on LibraryElement {
  List<_GenerateFragment> get generateFragments {
    return classes
        .map((element) => element.asGenerateFragment)
        .nonNulls
        .toList();
  }
}
