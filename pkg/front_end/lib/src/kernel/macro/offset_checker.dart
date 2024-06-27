// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/uri.dart';
import 'package:kernel/ast.dart';

import '../../api_prototype/compiler_options.dart';
import '../../testing/kernel_id_testing.dart';
import 'macro.dart';
import 'offsets.dart';

mixin MacroOffsetCheckerMixin implements HooksForTesting {
  final Map<Uri, Source> _sources = {};
  final Map<TreeNode, List<OffsetInfo?>> _beforeTextMap = {};
  List<String> get errors;

  @override
  void beforeMergingMacroAugmentations(Component component) {
    for (MapEntry<Uri, Source> entry in component.uriToSource.entries) {
      Uri uri = entry.key;
      if (uri.isScheme(intermediateAugmentationScheme)) {
        _sources[uri] = entry.value;
      }
    }
    component.accept(new BeforeOffsetVisitor(_sources, _beforeTextMap));
  }

  @override
  void afterMergingMacroAugmentations(Component component) {
    for (MapEntry<Uri, Source> entry in component.uriToSource.entries) {
      Uri uri = entry.key;
      if (isMacroLibraryUri(uri)) {
        _sources[uri] = entry.value;
      }
    }
    component.accept(new AfterOffsetVisitor(_sources, _beforeTextMap, errors));

    _sources.clear();
    _beforeTextMap.clear();
  }
}

class MacroOffsetCheckerHook extends HooksForTesting
    with MacroOffsetCheckerMixin {
  @override
  final List<String> errors;

  MacroOffsetCheckerHook(this.errors);
}

class MacroOffsetChecker extends MacroOffsetCheckerHook {
  MacroOffsetChecker() : super([]);

  @override
  void onBuildComponentComplete(Component component) {
    errors.forEach(print);
    errors.clear();
  }
}

abstract class OffsetVisitor extends FileUriVisitor {
  final List<(Uri, Source?)> _currentSources = [];
  final Map<Uri, Source> _sources;

  OffsetVisitor(this._sources);

  @override
  void enterFileUri(FileUriNode node) {
    _currentSources.add((node.fileUri, _sources[node.fileUri]));
  }

  @override
  void exitFileUri(FileUriNode node) {
    _currentSources.removeLast();
  }

  @override
  void defaultTreeNode(TreeNode node) {
    _collect(node);
    super.defaultTreeNode(node);
  }

  static final RegExp qualifiedNameRegExp =
      new RegExp(r'([a-zA-Z_][a-zA-Z_0-9]*)(\.[a-zA-Z_][a-zA-Z_0-9]*)*');

  static final RegExp simpleNameRegExp =
      new RegExp(r'([a-zA-Z_][a-zA-Z_0-9]*)');

  void _collect(TreeNode node) {
    if (_currentSources.isNotEmpty) {
      var (Uri currentUri, Source? currentSource) = _currentSources.last;
      if (currentSource == null) {
        if (isMacroLibraryUri(currentUri)) {
          throw "Missing source for macro library uri ${currentUri}.";
        }
        return;
      }
      String sourceText = currentSource.text;
      List<OffsetInfo?> offsetInfoList = [];
      for (int offset in node.fileOffsetsIfMultiple ?? [node.fileOffset]) {
        if (0 <= offset && offset < sourceText.length) {
          String character = sourceText.substring(offset, offset + 1);
          Match? simpleName =
              simpleNameRegExp.matchAsPrefix(sourceText, offset);
          Match? qualifiedName =
              qualifiedNameRegExp.matchAsPrefix(sourceText, offset);
          offsetInfoList.add(new OffsetInfo(currentSource, offset, character,
              simpleName?[0], qualifiedName?[1]));
        } else {
          offsetInfoList.add(null);
        }
      }
      registerNode(node, offsetInfoList);
    }
  }

  void registerNode(TreeNode node, List<OffsetInfo?> info);
}

class BeforeOffsetVisitor extends OffsetVisitor {
  final Map<TreeNode, List<OffsetInfo?>> textMap;

  BeforeOffsetVisitor(super.sources, this.textMap);

  @override
  void registerNode(TreeNode key, List<OffsetInfo?> info) {
    textMap[key] = info;
  }
}

class AfterOffsetVisitor extends OffsetVisitor {
  final Map<TreeNode, List<OffsetInfo?>> beforeTextMap;
  final List<String> errors;
  final Map<Uri, Map<String, String>> remapping = {};

  AfterOffsetVisitor(super.sources, this.beforeTextMap, this.errors);

  @override
  void registerNode(TreeNode node, List<OffsetInfo?> afterInfoList) {
    List<OffsetInfo?> beforeInfoList = beforeTextMap[node] ?? [];
    int length = beforeInfoList.length;
    if (afterInfoList.length > length) {
      length = afterInfoList.length;
    }

    for (int i = 0; i < length; i++) {
      OffsetInfo? beforeInfo =
          i < beforeInfoList.length ? beforeInfoList[i] : null;
      OffsetInfo? afterInfo =
          i < afterInfoList.length ? afterInfoList[i] : null;
      String? beforeText = beforeInfo?.text;
      String? afterText = afterInfo?.text;
      if (beforeText != afterText) {
        String? expectedText = beforeText;
        String? foundText = afterText;
        if (afterInfo != null && beforeInfo != null) {
          String? beforeSimpleName = beforeInfo.simpleName;
          String? afterQualifiedName = afterInfo.qualifiedName;
          if (beforeSimpleName != null && afterQualifiedName != null) {
            Map<String, String> map =
                remapping[beforeInfo.source.fileUri!] ??= {};
            String? alternativeQualifiedName = map[beforeSimpleName];
            if (alternativeQualifiedName != null) {
              expectedText = alternativeQualifiedName;
            } else {
              expectedText = map[beforeSimpleName] = afterQualifiedName;
            }
            foundText = afterQualifiedName;
          }
        }
        if (expectedText != foundText) {
          String message = 'Text mismatch on ${node} '
              '(${node.runtimeType}) offset $i: '
              'Before: ${beforeText != null ? "'${beforeText}'" : null}, '
              'expected: ${expectedText != null ? "'${expectedText}'" : null}, '
              'after: ${afterText != null ? "'${afterText}'" : null}, '
              'found: ${foundText != null ? "'${foundText}'" : null}.';
          if (beforeInfo != null) {
            errors.add(createMessageInLocation(
                {beforeInfo.source.fileUri!: beforeInfo.source},
                beforeInfo.source.fileUri,
                beforeInfo.offset,
                message));
          }
          if (afterInfo != null) {
            errors.add(createMessageInLocation(
                {afterInfo.source.fileUri!: afterInfo.source},
                afterInfo.source.fileUri,
                afterInfo.offset,
                'After location:'));
          }
        }
      }
    }
  }
}

class OffsetInfo {
  final Source source;
  final int offset;
  final String character;
  final String? simpleName;
  final String? qualifiedName;

  OffsetInfo(this.source, this.offset, this.character, this.simpleName,
      this.qualifiedName);

  String get text => simpleName ?? character;
}
