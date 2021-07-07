// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

/// An [EditBuilder] used to build edits in YAML files.
///
/// Clients may not extend, implement or mix-in this class.
abstract class YamlEditBuilder implements EditBuilder {
  @override
  void addLinkedEdit(String groupName,
      void Function(YamlLinkedEditBuilder builder) buildLinkedEdit);
}

/// A [FileEditBuilder] used to build edits for YAML files.
///
/// Clients may not extend, implement or mix-in this class.
abstract class YamlFileEditBuilder implements FileEditBuilder {
  @override
  void addInsertion(
      int offset, void Function(YamlEditBuilder builder) buildEdit);

  @override
  void addReplacement(
      SourceRange range, void Function(YamlEditBuilder builder) buildEdit);
}

/// A [LinkedEditBuilder] used to build linked edits for YAML files.
///
/// Clients may not extend, implement or mix-in this class.
abstract class YamlLinkedEditBuilder implements LinkedEditBuilder {}
