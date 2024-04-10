// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';

/// Builds and returns a single [SourceEdit] for a new constructor, inserted
/// into [container].
Future<SourceEdit?> buildEditForInsertedConstructor(
  NamedCompilationUnitMember container,
  void Function(DartEditBuilder builder) buildEdit, {
  required ResolvedUnitResult resolvedUnit,
  required AnalysisSession session,
}) async {
  var builder = ChangeBuilder(session: session);
  await builder.addDartFileEdit(resolvedUnit.path, (builder) {
    builder.insertConstructor(container, buildEdit);
  });
  var fileEdit = builder.sourceChange.getFileEdit(resolvedUnit.path);
  if (fileEdit == null) {
    return null;
  }
  var edits = fileEdit.edits;
  if (edits.isEmpty) {
    return null;
  }
  assert(
    edits.length == 1,
    'Expected a single edit from addConstructorInsertion, but got '
    '${edits.length}',
  );
  return edits.first;
}
