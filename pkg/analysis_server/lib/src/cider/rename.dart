// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/micro/resolve_file.dart';
import 'package:analyzer/src/dart/micro/utils.dart';

class CiderRenameComputer {
  final FileResolver _fileResolver;

  CiderRenameComputer(this._fileResolver);

  /// Check if the identifier at the [line], [column] for the file at the
  /// [filePath] can be renamed.
  RenameRefactoringElement? canRename(String filePath, int line, int column) {
    var resolvedUnit = _fileResolver.resolve(path: filePath);
    var lineInfo = resolvedUnit.lineInfo;
    var offset = lineInfo.getOffsetOfLine(line) + column;

    var node = NodeLocator(offset).searchWithin(resolvedUnit.unit);
    var element = getElementOfNode(node);

    if (node == null || element == null) {
      return null;
    }
    if (element.source != null && element.source!.isInSystemLibrary) {
      return null;
    }
    if (element is MethodElement && element.isOperator) {
      return null;
    }
    if (!_canRenameElement(element)) {
      return null;
    }
    return RenameRefactoring.getElementToRename(node, element);
  }

  bool _canRenameElement(Element element) {
    if (element is PropertyAccessorElement) {
      element = element.variable;
    }
    var enclosingElement = element.enclosingElement;
    if (element is LabelElement || element is LocalElement) {
      return true;
    }
    if (enclosingElement is ClassElement ||
        enclosingElement is ExtensionElement) {
      return true;
    }
    return false;
  }
}
