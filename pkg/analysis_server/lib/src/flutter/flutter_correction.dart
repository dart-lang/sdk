// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' hide Element;
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:meta/meta.dart';

class FlutterCorrections {
  final String file;
  final String fileContent;

  final int selectionOffset;
  final int selectionLength;
  final int selectionEnd;
  final SourceRange selectionRange;

  final AnalysisSession session;
  final CompilationUnit unit;

  CorrectionUtils utils;

  FlutterCorrections(
      {@required this.file,
      @required this.fileContent,
      @required this.selectionOffset,
      @required this.selectionLength,
      @required this.session,
      @required this.unit})
      : assert(file != null),
        assert(fileContent != null),
        assert(selectionOffset != null),
        assert(selectionLength != null),
        assert(session != null),
        assert(unit != null),
        selectionEnd = selectionOffset + selectionLength,
        selectionRange = new SourceRange(selectionOffset, selectionLength) {
    utils = new CorrectionUtils(unit, buffer: fileContent);
  }

  /**
   * Returns the EOL to use for this [CompilationUnit].
   */
  String get eol => utils.endOfLine;

  /// Wrap the code between [selectionOffset] and [selectionEnd] into a new
  /// widget with the [parentType].  It is expected that the parent widget has
  /// the default constructor and the `child` named parameter.
  Future<SourceChange> wrapWidget(InterfaceType parentType) async {
    String src = utils.getText(selectionOffset, selectionLength);
    var changeBuilder = new DartChangeBuilder(session);
    await changeBuilder.addFileEdit(file, (builder) {
      builder.addReplacement(selectionRange, (builder) {
        builder.write('new ');
        builder.writeType(parentType);
        builder.write('(');
        if (src.contains(eol)) {
          String indentOld = utils.getLinePrefix(selectionOffset);
          String indentNew = indentOld + utils.getIndent(1);
          builder.write(eol);
          builder.write(indentNew);
          src = _replaceSourceIndent(src, indentOld, indentNew);
          src += ',$eol$indentOld';
        }
        builder.write('child: ');
        builder.selectHere();
        builder.write(src);
        builder.write(')');
      });
    });
    return changeBuilder.sourceChange;
  }

  static String _replaceSourceIndent(
      String source, String indentOld, String indentNew) {
    return source.replaceAll(
        new RegExp('^$indentOld', multiLine: true), indentNew);
  }
}
