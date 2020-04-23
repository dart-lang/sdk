// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:meta/meta.dart';

class FlutterCorrections {
  final ResolvedUnitResult resolveResult;
  final int selectionOffset;
  final int selectionLength;
  final int selectionEnd;

  final CorrectionUtils utils;

  AstNode node;

  FlutterCorrections(
      {@required this.resolveResult,
      @required this.selectionOffset,
      @required this.selectionLength})
      : assert(resolveResult != null),
        assert(selectionOffset != null),
        assert(selectionLength != null),
        selectionEnd = selectionOffset + selectionLength,
        utils = CorrectionUtils(resolveResult) {
    node = NodeLocator(selectionOffset, selectionEnd)
        .searchWithin(resolveResult.unit);
  }

  /// Returns the EOL to use for this [CompilationUnit].
  String get eol => utils.endOfLine;
}
