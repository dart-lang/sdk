// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/refactoring/naming_conventions.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analysis_server/src/utilities/flutter.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/micro/resolve_file.dart';
import 'package:analyzer/src/dart/micro/utils.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';

class CanRenameResponse {
  final LineInfo lineInfo;
  final RenameRefactoringElement refactoringElement;
  final FileResolver _fileResolver;
  final String filePath;

  FlutterWidgetState? _flutterWidgetState;

  CanRenameResponse(this.lineInfo, this.refactoringElement, this._fileResolver,
      this.filePath);

  String get oldName => refactoringElement.element.displayName;

  CheckNameResponse? checkNewName(String name) {
    var element = refactoringElement.element;
    _flutterWidgetState = _findFlutterStateClass(element, name);

    RefactoringStatus? status;
    if (element is ParameterElement) {
      status = validateParameterName(name);
    } else if (element is VariableElement) {
      status = validateVariableName(name);
    } else if (element is FunctionElement) {
      status = validateFunctionName(name);
    } else if (element is FieldElement) {
      status = validateFieldName(name);
    } else if (element is TypeAliasElement) {
      status = validateTypeAliasName(name);
    } else if (element is ClassElement) {
      status = validateClassName(name);
    }

    if (status == null) {
      return null;
    }
    return CheckNameResponse(status, this);
  }

  FlutterWidgetState? _findFlutterStateClass(Element element, String newName) {
    if (Flutter.instance.isStatefulWidgetDeclaration(element)) {
      var oldStateName = element.displayName + 'State';
      var library = element.library!;
      var state =
          library.getType(oldStateName) ?? library.getType('_' + oldStateName);
      if (state != null) {
        var flutterWidgetStateNewName = newName + 'State';
        // If the State was private, ensure that it stays private.
        if (state.name.startsWith('_') &&
            !flutterWidgetStateNewName.startsWith('_')) {
          flutterWidgetStateNewName = '_' + flutterWidgetStateNewName;
        }
        return FlutterWidgetState(state, flutterWidgetStateNewName);
      }
    }
    return null;
  }
}

class CheckNameResponse {
  final RefactoringStatus status;
  final CanRenameResponse canRename;

  CheckNameResponse(this.status, this.canRename);

  LineInfo get lineInfo => canRename.lineInfo;

  String get oldName => canRename.refactoringElement.element.displayName;

  RenameResponse? computeRenameRanges() {
    var elements = <Element>[];
    var element = canRename.refactoringElement.element;
    if (element is PropertyInducingElement && element.isSynthetic) {
      var property = element;
      var getter = property.getter;
      var setter = property.setter;
      elements.addIfNotNull(getter);
      elements.addIfNotNull(setter);
    } else {
      elements.add(element);
    }
    var matches = <CiderSearchMatch>[];
    for (var element in elements) {
      matches.addAll(canRename._fileResolver.findReferences(element));
    }
    FlutterWidgetRename? flutterRename;
    if (canRename._flutterWidgetState != null) {
      var stateWidget = canRename._flutterWidgetState!;
      var match = canRename._fileResolver.findReferences(stateWidget.state);
      flutterRename = FlutterWidgetRename(stateWidget.newName, match);
    }
    return RenameResponse(matches, this, flutterWidgetRename: flutterRename);
  }
}

class CiderRenameComputer {
  final FileResolver _fileResolver;

  CiderRenameComputer(this._fileResolver);

  /// Check if the identifier at the [line], [column] for the file at the
  /// [filePath] can be renamed.
  CanRenameResponse? canRename(String filePath, int line, int column) {
    var resolvedUnit = _fileResolver.resolve(path: filePath);
    var lineInfo = resolvedUnit.lineInfo;
    var offset = lineInfo.getOffsetOfLine(line) + column;

    var node = NodeLocator(offset).searchWithin(resolvedUnit.unit);
    var element = getElementOfNode(node);

    if (node == null || element == null) {
      return null;
    }
    if (element.source != null && element.source!.uri.isScheme('dart')) {
      return null;
    }
    if (element is MethodElement && element.isOperator) {
      return null;
    }
    if (element is PropertyAccessorElement) {
      element = element.variable;
    }
    if (!_canRenameElement(element)) {
      return null;
    }
    var refactoring = RenameRefactoring.getElementToRename(node, element);
    if (refactoring != null) {
      return CanRenameResponse(lineInfo, refactoring, _fileResolver, filePath);
    }
    return null;
  }

  bool _canRenameElement(Element element) {
    var enclosingElement = element.enclosingElement;
    if (element is ConstructorElement) {
      return false;
    }
    if (element is LabelElement || element is LocalElement) {
      return true;
    }
    if (enclosingElement is ClassElement ||
        enclosingElement is ExtensionElement ||
        enclosingElement is CompilationUnitElement) {
      return true;
    }

    return false;
  }
}

class FlutterWidgetRename {
  final String name;
  final List<CiderSearchMatch> matches;

  FlutterWidgetRename(this.name, this.matches);
}

/// The corresponding `State` declaration of a  Flutter `StatefulWidget`.
class FlutterWidgetState {
  ClassElement state;
  String newName;

  FlutterWidgetState(this.state, this.newName);
}

class RenameResponse {
  final List<CiderSearchMatch> matches;
  final CheckNameResponse checkName;
  FlutterWidgetRename? flutterWidgetRename;

  RenameResponse(this.matches, this.checkName, {this.flutterWidgetRename});
}
