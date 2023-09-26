// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/src/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_yaml.dart';
import 'package:yaml/yaml.dart';

/// An [EditBuilder] used to build edits in YAML files.
class YamlEditBuilderImpl extends EditBuilderImpl implements YamlEditBuilder {
  /// Initialize a newly created builder to build a source edit.
  YamlEditBuilderImpl(YamlFileEditBuilderImpl super.sourceFileEditBuilder,
      super.offset, super.length);

  YamlFileEditBuilderImpl get dartFileEditBuilder =>
      fileEditBuilder as YamlFileEditBuilderImpl;

  @override
  void addLinkedEdit(String groupName,
          void Function(YamlLinkedEditBuilder builder) buildLinkedEdit) =>
      super.addLinkedEdit(groupName,
          (builder) => buildLinkedEdit(builder as YamlLinkedEditBuilder));

  @override
  LinkedEditBuilderImpl createLinkedEditBuilder() {
    return YamlLinkedEditBuilderImpl(this);
  }

  /// Returns the indentation with the given [level].
  String getIndent(int level) => '  ' * level;
}

/// A [FileEditBuilder] used to build edits for YAML files.
class YamlFileEditBuilderImpl extends FileEditBuilderImpl
    implements YamlFileEditBuilder {
  /// The document parsed from the file contents.
  final YamlDocument document;

  /// Initialize a newly created builder to build a source file edit within the
  /// change being built by the given [changeBuilder]. The file being edited has
  /// the given [filePath], [document], and [timeStamp].
  YamlFileEditBuilderImpl(ChangeBuilderImpl changeBuilder, String filePath,
      this.document, int timeStamp)
      : super(changeBuilder, filePath, timeStamp);

  @override
  void addInsertion(
          int offset, void Function(YamlEditBuilder builder) buildEdit,
          {bool insertBeforeExisting = false}) =>
      super.addInsertion(
          offset, (builder) => buildEdit(builder as YamlEditBuilder),
          insertBeforeExisting: insertBeforeExisting);

  @override
  void addReplacement(SourceRange range,
          void Function(YamlEditBuilder builder) buildEdit) =>
      super.addReplacement(
          range, (builder) => buildEdit(builder as YamlEditBuilder));

  @override
  YamlFileEditBuilderImpl copyWith(ChangeBuilderImpl changeBuilder,
      {Map<YamlFileEditBuilderImpl, YamlFileEditBuilderImpl> editBuilderMap =
          const {}}) {
    var copy = YamlFileEditBuilderImpl(
        changeBuilder, fileEdit.file, document, fileEdit.fileStamp);
    copy.fileEdit.edits.addAll(fileEdit.edits);
    return copy;
  }

  @override
  EditBuilderImpl createEditBuilder(int offset, int length) {
    return YamlEditBuilderImpl(this, offset, length);
  }
}

/// A [LinkedEditBuilder] used to build linked edits for YAML files.
class YamlLinkedEditBuilderImpl extends LinkedEditBuilderImpl
    implements YamlLinkedEditBuilder {
  /// Initialize a newly created linked edit builder.
  YamlLinkedEditBuilderImpl(super.editBuilder);
}
