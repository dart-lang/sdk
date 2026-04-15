// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server_client/protocol.dart';
import 'package:analysis_server_client/server.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/utilities/extensions/string.dart';
import 'package:analyzer_testing/package_root.dart' as pkg_root;
import 'package:analyzer_utilities/tools.dart';
import 'package:path/path.dart';

void main() async {
  await GeneratedContent.generateAll(pkg_root.packageRoot, await allTargets);
}

Future<List<GeneratedContent>> get allTargets async {
  var elementUnit = await _getElementUnit();
  return <GeneratedContent>[
    GeneratedFile('analyzer/lib/src/dart/element/element.dart', (_) async {
      var generator = _ElementGenerator(elementUnit);
      return await generator.generate();
    }),
  ];
}

String get _analyzerPath => normalize(join(pkg_root.packageRoot, 'analyzer'));

String get _elementPath {
  return normalize(
    join(_analyzerPath, 'lib', 'src', 'dart', 'element', 'element.dart'),
  );
}

void writeEnum(StringBuffer buffer, String enumName, Set<String> values) {
  buffer.writeln('@generated');
  buffer.writeln('enum $enumName {');
  for (var value in values) {
    buffer.writeln('  $value,');
  }
  buffer.writeln('}');
}

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

Future<ResolvedUnitResult> _getElementUnit() async {
  var collection = AnalysisContextCollection(includedPaths: [_analyzerPath]);
  var analysisContext = collection.contextFor(_analyzerPath);
  var analysisSession = analysisContext.currentSession;
  var unitResult = await analysisSession.getResolvedUnit(_elementPath);
  return unitResult as ResolvedUnitResult;
}

enum _ElementFlagSource { none, firstFragment, stored }

class _ElementGenerator {
  final ResolvedUnitResult unitResult;

  final Set<String> elementStorageFlags = {};
  final Set<String> fragmentStorageFlags = {};
  final List<_Replacement> replacements = [];

  _ElementGenerator(this.unitResult);

  Future<String> generate() async {
    _replaceGeneratedFlags();
    _replaceStorageEnums();

    replacements.sort((a, b) => b.offset - a.offset);

    var newCode = unitResult.content;
    for (var replacement in replacements) {
      newCode =
          newCode.substring(0, replacement.offset) +
          replacement.text +
          newCode.substring(replacement.end);
    }

    return _formatSortCode(_elementPath, newCode);
  }

  void _replaceGeneratedFlags() {
    for (var declaration in unitResult.unit.declarations) {
      if (declaration is! ClassDeclarationImpl) {
        continue;
      }
      var classElement = declaration.declaredFragment!.element;
      var generateFlags = classElement.asGenerateElementFlags;
      if (generateFlags == null) {
        continue;
      }

      var className = classElement.name!;
      var isElement = className.endsWith('ElementImpl');
      var isFragment = className.endsWith('FragmentImpl');
      if (!isElement && !isFragment) {
        throw StateError('$className is not an element or fragment class.');
      }

      for (var child in classElement.children) {
        if (child.metadata.hasGenerated) {
          if (child is! PropertyAccessorElement) {
            throw StateError(
              'Only getters and setters can be marked as @generated, '
              'but ${classElement.name}.${child.name} is a ${child.kind.name}.',
            );
          }
        }
      }

      var existingGetters = <String, _ExistingGeneratedGetter>{};
      var body = declaration.body as BlockClassBodyImpl;
      for (var member in body.members) {
        if (member is MethodDeclarationImpl && member.isGenerated) {
          replacements.add(
            _Replacement(offset: member.offset, end: member.end, text: ''),
          );
          if (member.isGetter) {
            var getterElement = member.declaredFragment!.element;
            var getterName = getterElement.name!;
            existingGetters[getterName] = _ExistingGeneratedGetter(
              documentationComment: getterElement.documentationComment,
              annotations: member.metadata
                  .map((annotation) {
                    return unitResult.content.substring(
                      annotation.offset,
                      annotation.end,
                    );
                  })
                  .where((source) => source != '@generated')
                  .toList(),
            );
          }
        }
      }

      var storagePrefix = className.storagePrefix;
      var buffer = StringBuffer();

      for (var flag in generateFlags.flags) {
        var existing = existingGetters[flag.name];
        var documentationComment = existing?.documentationComment;
        var annotations = existing?.annotations ?? const [];
        if (isFragment) {
          if (flag.fragment) {
            var storageFlag = '${storagePrefix}_${flag.name}';
            var storageFlagCode = '_FragmentStorageFlag.$storageFlag';
            fragmentStorageFlags.add(storageFlag);

            // getter
            buffer.writeln();
            buffer.writeDocumentation(documentationComment);
            buffer.writeAnnotations(['@generated', ...annotations]);
            buffer.writeln('bool get ${flag.name} {');
            buffer.writeln('  return hasFlag($storageFlagCode);');
            buffer.writeln('}');

            // setter
            buffer.writeln();
            buffer.writeln('@generated');
            buffer.writeln('set ${flag.name}(bool value) {');
            buffer.writeln('  setFlag($storageFlagCode, value);');
            buffer.writeln('}');
          }
        } else {
          switch (flag.elementSource) {
            case _ElementFlagSource.none:
              break;
            case _ElementFlagSource.firstFragment:
              buffer.writeln();
              buffer.writeDocumentation(documentationComment);
              buffer.writeAnnotations(['@generated', ...annotations]);
              buffer.writeln('bool get ${flag.name} {');
              buffer.writeln('  return _firstFragment.${flag.name};');
              buffer.writeln('}');
            case _ElementFlagSource.stored:
              var storageFlag = '${storagePrefix}_${flag.name}';
              var storageFlagCode = '_ElementStorageFlag.$storageFlag';
              elementStorageFlags.add(storageFlag);

              // getter
              buffer.writeln();
              buffer.writeDocumentation(documentationComment);
              buffer.writeAnnotations(['@generated', ...annotations]);
              buffer.writeln('bool get ${flag.name} {');
              buffer.writeln('  return hasFlag($storageFlagCode);');
              buffer.writeln('}');

              // setter
              buffer.writeln();
              buffer.writeln('@generated');
              buffer.writeln('set ${flag.name}(bool value) {');
              buffer.writeln('  setFlag($storageFlagCode, value);');
              buffer.writeln('}');
          }
        }
      }

      if (buffer.isNotEmpty) {
        var body = declaration.body as BlockClassBodyImpl;
        var offset = body.rightBracket.offset;
        replacements.add(
          _Replacement(offset: offset, end: offset, text: '\n$buffer'),
        );
      }
    }
  }

  void _replaceStorageEnums() {
    for (var declaration in unitResult.unit.declarations) {
      if (declaration is EnumDeclarationImpl) {
        var name = declaration.declaredFragment!.element.name!;
        if (name == '_ElementStorageFlag' || name == '_FragmentStorageFlag') {
          replacements.add(
            _Replacement(
              offset: declaration.offset,
              end: declaration.end,
              text: '',
            ),
          );
        }
      }
    }

    var buffer = StringBuffer();
    buffer.writeln();
    writeEnum(buffer, '_ElementStorageFlag', elementStorageFlags);
    buffer.writeln();
    writeEnum(buffer, '_FragmentStorageFlag', fragmentStorageFlags);

    var endOfFile = unitResult.content.length;
    replacements.add(
      _Replacement(offset: endOfFile, end: endOfFile, text: buffer.toString()),
    );
  }
}

class _ExistingGeneratedGetter {
  final String? documentationComment;
  final List<String> annotations;

  _ExistingGeneratedGetter({
    required this.documentationComment,
    required this.annotations,
  });
}

class _GenerateElementFlag {
  final String name;
  final bool fragment;
  final _ElementFlagSource elementSource;

  _GenerateElementFlag({
    required this.name,
    required this.fragment,
    required this.elementSource,
  });
}

class _GenerateElementFlags {
  final ClassElement element;
  final List<_GenerateElementFlag> flags;

  _GenerateElementFlags(this.element, this.flags);
}

class _Replacement {
  final int offset;
  final int end;
  final String text;

  _Replacement({required this.offset, required this.end, required this.text});
}

extension on StringBuffer {
  void writeAnnotations(List<String> annotations) {
    for (var annotation in annotations) {
      writeln(annotation);
    }
  }

  void writeDocumentation(String? documentationComment) {
    if (documentationComment != null) {
      writeln(documentationComment);
    }
  }
}

extension _ClassElementExtension on ClassElement {
  _GenerateElementFlags? get asGenerateElementFlags {
    var generateObject = metadata.annotations
        .map((annotation) {
          var generateObject = annotation.computeConstantValue();
          var generateObjectType = generateObject?.type;
          if (generateObjectType?.element?.name != 'GenerateElementFlags') {
            return null;
          }
          return generateObject;
        })
        .nonNulls
        .firstOrNull;
    if (generateObject == null) {
      return null;
    }

    var flagsField = generateObject.getField('flags')!;
    var flags = flagsField.toListValue()!.map((flag) {
      var variable = flag.variable!;
      var elementField = flag.getField('element')!;
      var elementSourceName = elementField.variable!.name!;
      return _GenerateElementFlag(
        name: variable.name!,
        fragment: flag.getField('fragment')!.toBoolValue()!,
        elementSource: _ElementFlagSource.values.byName(elementSourceName),
      );
    }).toList();
    return _GenerateElementFlags(this, flags);
  }
}

extension _ElementAnnotationExtension on ElementAnnotation {
  bool get isGenerated {
    var value = computeConstantValue();
    return value?.type?.element?.name == '_Generated';
  }
}

extension _MetadataExtension on Metadata {
  bool get hasGenerated {
    return annotations.any((annotation) => annotation.isGenerated);
  }
}

extension _MethodDeclarationImplExtension on MethodDeclarationImpl {
  bool get isGenerated {
    var element = declaredFragment!.element;
    return element.metadata.hasGenerated;
  }
}

extension _StringExtension on String {
  String get storagePrefix {
    var name = removeSuffixOrSelf('Impl');
    return name.substring(0, 1).toLowerCase() + name.substring(1);
  }
}
