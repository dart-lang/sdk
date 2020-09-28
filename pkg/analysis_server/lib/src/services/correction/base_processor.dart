// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/utilities/flutter.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/analysis/session_helper.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_workspace.dart';
import 'package:meta/meta.dart';

/// Base class for common processor functionality.
abstract class BaseProcessor {
  final int selectionOffset;
  final int selectionLength;
  final int selectionEnd;

  final CorrectionUtils utils;
  final String file;

  final TypeProvider typeProvider;

  final AnalysisSession session;
  final AnalysisSessionHelper sessionHelper;
  final ResolvedUnitResult resolvedResult;
  final ChangeWorkspace workspace;

  AstNode node;

  BaseProcessor({
    this.selectionOffset = -1,
    this.selectionLength = 0,
    @required this.resolvedResult,
    @required this.workspace,
  })  : file = resolvedResult.path,
        session = resolvedResult.session,
        sessionHelper = AnalysisSessionHelper(resolvedResult.session),
        typeProvider = resolvedResult.typeProvider,
        selectionEnd = (selectionOffset ?? 0) + (selectionLength ?? 0),
        utils = CorrectionUtils(resolvedResult);

  Flutter get flutter => Flutter.instance;

  @protected
  bool setupCompute() {
    final locator = NodeLocator(selectionOffset, selectionEnd);
    node = locator.searchWithin(resolvedResult.unit);
    return node != null;
  }
}
