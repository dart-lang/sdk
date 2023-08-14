// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart' hide Element;
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/services/refactoring/legacy/naming_conventions.dart';
import 'package:analysis_server/src/services/refactoring/legacy/refactoring.dart';
import 'package:analysis_server/src/services/search/hierarchy.dart';
import 'package:analysis_server/src/utilities/flutter.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/micro/resolve_file.dart';
import 'package:analyzer/src/dart/micro/utils.dart';
import 'package:analyzer/src/generated/java_core.dart';
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
    } else if (element is MethodElement) {
      status = validateMethodName(name);
    } else if (element is TypeAliasElement) {
      status = validateTypeAliasName(name);
    } else if (element is InterfaceElement) {
      status = validateClassName(name);
    } else if (element is ConstructorElement) {
      status = validateConstructorName(name);
      _analyzePossibleConflicts(element, status, name);
    } else if (element is LibraryImportElement) {
      status = validateImportPrefixName(name);
    }

    if (status == null) {
      return null;
    }
    return CheckNameResponse(status, this, name);
  }

  void _analyzePossibleConflicts(
      ConstructorElement element, RefactoringStatus result, String newName) {
    var parentClass = element.enclosingElement;
    // Check if the "newName" is the name of the enclosing class.
    if (parentClass.name == newName) {
      result.addError('The constructor should not have the same name '
          'as the name of the enclosing class.');
    }
    // check if there are members with "newName" in the same ClassElement
    for (var newNameMember in getChildren(parentClass, newName)) {
      var message = format("Class '{0}' already declares {1} with name '{2}'.",
          parentClass.displayName, getElementKindName(newNameMember), newName);
      result.addError(message, newLocation_fromElement(newNameMember));
    }
  }

  FlutterWidgetState? _findFlutterStateClass(Element element, String newName) {
    if (Flutter.instance.isStatefulWidgetDeclaration(element)) {
      var oldStateName = '${element.displayName}State';
      var library = element.library!;
      var state =
          library.getClass(oldStateName) ?? library.getClass('_$oldStateName');
      if (state != null) {
        var flutterWidgetStateNewName = '${newName}State';
        // If the State was private, ensure that it stays private.
        if (state.name.startsWith('_') &&
            !flutterWidgetStateNewName.startsWith('_')) {
          flutterWidgetStateNewName = '_$flutterWidgetStateNewName';
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
  final String newName;

  CheckNameResponse(this.status, this.canRename, this.newName);

  LineInfo get lineInfo => canRename.lineInfo;

  String get oldName => canRename.refactoringElement.element.displayName;

  Future<RenameResponse?> computeRenameRanges2() async {
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
    var fileResolver = canRename._fileResolver;
    var matches = <CiderSearchMatch>[];
    for (var element in elements) {
      matches.addAll(await fileResolver.findReferences2(element));
    }
    FlutterWidgetRename? flutterRename;
    if (canRename._flutterWidgetState != null) {
      flutterRename = await _computeFlutterStateName();
    }
    var replaceMatches = <CiderReplaceMatch>[];
    if (element is ConstructorElement) {
      for (var match in matches) {
        var replaceInfo = <ReplaceInfo>[];
        for (var ref in match.references) {
          String replacement = newName.isNotEmpty ? '.$newName' : '';
          if (replacement.isEmpty &&
              ref.kind == MatchKind.REFERENCE_BY_CONSTRUCTOR_TEAR_OFF) {
            replacement = '.new';
          }
          if (ref.kind ==
              MatchKind.INVOCATION_BY_ENUM_CONSTANT_WITHOUT_ARGUMENTS) {
            replacement += '()';
          }
          replaceInfo
              .add(ReplaceInfo(replacement, ref.startPosition, ref.length));
        }
        replaceMatches.addMatch(match.path, replaceInfo);
      }
      if (element.isSynthetic) {
        var result = await _replaceSyntheticConstructor();
        if (result != null) {
          replaceMatches.addMatch(result.path, result.matches.toList());
        }
      }
    } else if (element is LibraryImportElement) {
      var replaceInfo = <ReplaceInfo>[];
      for (var match in matches) {
        for (var ref in match.references) {
          if (newName.isEmpty) {
            replaceInfo.add(ReplaceInfo('', ref.startPosition, ref.length));
          } else {
            var identifier = await _getInterpolationIdentifier(
                match.path, ref.startPosition);
            if (identifier != null) {
              var lineInfo = canRename.lineInfo;
              replaceInfo.add(ReplaceInfo('{$newName.${identifier.name}}',
                  lineInfo.getLocation(identifier.offset), identifier.length));
            } else {
              replaceInfo
                  .add(ReplaceInfo('$newName.', ref.startPosition, ref.length));
            }
          }
        }
        replaceMatches.addMatch(match.path, replaceInfo);
        var sourcePath = element.source.fullName;
        var infos = await _addElementDeclaration(element, sourcePath);
        replaceMatches.addMatch(sourcePath, infos);
      }
    } else {
      for (var match in matches) {
        replaceMatches.addMatch(
            match.path,
            match.references
                .map((info) =>
                    ReplaceInfo(newName, info.startPosition, info.length))
                .toList());
      }
      // add element declaration
      var sourcePath = element.source!.fullName;
      var infos = await _addElementDeclaration(element, sourcePath);
      replaceMatches.addMatch(sourcePath, infos);
    }
    return RenameResponse(matches, this, replaceMatches,
        flutterWidgetRename: flutterRename);
  }

  Future<List<ReplaceInfo>> _addElementDeclaration(
      Element element, String sourcePath) async {
    var infos = <ReplaceInfo>[];
    if (element is PropertyInducingElement && element.isSynthetic) {
      if (element.getter != null) {
        infos.add(ReplaceInfo(
            newName,
            lineInfo.getLocation(element.getter!.nameOffset),
            element.getter!.nameLength));
      }
      if (element.setter != null) {
        infos.add(ReplaceInfo(
            newName,
            lineInfo.getLocation(element.setter!.nameOffset),
            element.setter!.nameLength));
      }
    } else if (element is LibraryImportElement) {
      var unit =
          (await canRename._fileResolver.resolve2(path: sourcePath)).unit;
      var index = element.library.libraryImports.indexOf(element);
      var node = unit.directives.whereType<ImportDirective>().elementAt(index);
      final prefixNode = node.prefix;
      if (newName.isEmpty) {
        // We should not get `prefix == null` because we check in
        // `checkNewName` that the new name is different.
        if (prefixNode != null) {
          var prefixEnd = prefixNode.end;
          infos.add(ReplaceInfo(newName, lineInfo.getLocation(node.uri.end),
              prefixEnd - node.uri.end));
        }
      } else {
        if (prefixNode == null) {
          var uriEnd = node.uri.end;
          infos.add(
              ReplaceInfo(' as $newName', lineInfo.getLocation(uriEnd), 0));
        } else {
          var offset = prefixNode.offset;
          var length = prefixNode.length;
          infos.add(ReplaceInfo(newName, lineInfo.getLocation(offset), length));
        }
      }
    } else {
      var location = (await canRename._fileResolver.resolve2(path: sourcePath))
          .lineInfo
          .getLocation(element.nameOffset);
      infos.add(ReplaceInfo(newName, location, element.nameLength));
    }
    return infos;
  }

  Future<FlutterWidgetRename?> _computeFlutterStateName() async {
    var flutterState = canRename._flutterWidgetState;
    var stateClass = flutterState!.state;
    var stateName = flutterState.newName;
    var match = await canRename._fileResolver.findReferences2(stateClass);
    var sourcePath = stateClass.source.fullName;
    var location =
        stateClass.enclosingElement.lineInfo.getLocation(stateClass.nameOffset);
    CiderSearchMatch ciderMatch;
    var searchInfo =
        CiderSearchInfo(location, stateClass.nameLength, MatchKind.DECLARATION);
    try {
      ciderMatch = match.firstWhere((m) => m.path == sourcePath);
      ciderMatch.references.add(searchInfo);
    } catch (_) {
      match.add(CiderSearchMatch(sourcePath, [searchInfo]));
    }
    var replacements = match
        .map((m) => CiderReplaceMatch(
            m.path,
            m.references
                .map((p) => ReplaceInfo(
                    stateName, p.startPosition, stateClass.nameLength))
                .toList()))
        .toList();
    return FlutterWidgetRename(stateName, match, replacements);
  }

  /// If the given [reference] is before an interpolated [SimpleIdentifier] in
  /// an [InterpolationExpression] without surrounding curly brackets, return
  /// it. Otherwise return `null`.
  Future<SimpleIdentifier?> _getInterpolationIdentifier(
      String path, CharacterLocation loc) async {
    var resolvedUnit = await canRename._fileResolver.resolve2(path: path);
    var lineInfo = resolvedUnit.lineInfo;
    var node = NodeLocator(
            lineInfo.getOffsetOfLine(loc.lineNumber - 1) + loc.columnNumber)
        .searchWithin(resolvedUnit.unit);
    if (node is SimpleIdentifier) {
      var parent = node.parent;
      if (parent is InterpolationExpression && parent.rightBracket == null) {
        return node;
      }
    }
    return null;
  }

  Future<CiderReplaceMatch?> _replaceSyntheticConstructor() async {
    var element = canRename.refactoringElement.element;
    var interfaceElement = element.enclosingElement;

    var fileResolver = canRename._fileResolver;
    var libraryPath = interfaceElement!.library!.source.fullName;
    var resolvedLibrary = await fileResolver.resolveLibrary2(path: libraryPath);
    var result = resolvedLibrary.getElementDeclaration(interfaceElement);
    if (result == null) {
      return null;
    }

    var resolvedUnit = result.resolvedUnit;
    if (resolvedUnit == null) {
      return null;
    }

    var node = result.node;
    if (node is ClassDeclaration) {
      var utils = CorrectionUtils(resolvedUnit);
      var location = utils.prepareNewConstructorLocation(
          fileResolver.contextObjects!.analysisSession, node);
      if (location == null) {
        return null;
      }

      var header = '${interfaceElement.name}.$newName();';
      return CiderReplaceMatch(libraryPath, [
        ReplaceInfo(location.prefix + header + location.suffix,
            resolvedUnit.lineInfo.getLocation(location.offset), 0)
      ]);
    } else if (node is EnumDeclaration) {
      var utils = CorrectionUtils(resolvedUnit);
      var location = utils.prepareEnumNewConstructorLocation(node);
      var header = 'const ${interfaceElement.name}.$newName();';
      return CiderReplaceMatch(libraryPath, [
        ReplaceInfo(location.prefix + header + location.suffix,
            resolvedUnit.lineInfo.getLocation(location.offset), 0)
      ]);
    }
    return null;
  }
}

class CiderRenameComputer {
  final FileResolver _fileResolver;

  CiderRenameComputer(this._fileResolver);

  /// Check if the identifier at the [line], [column] for the file at the
  /// [filePath] can be renamed.
  Future<CanRenameResponse?> canRename2(
      String filePath, int line, int column) async {
    var resolvedUnit = await _fileResolver.resolve2(path: filePath);
    var lineInfo = resolvedUnit.lineInfo;
    var offset = lineInfo.getOffsetOfLine(line) + column;

    var node = NodeLocator(offset).searchWithin(resolvedUnit.unit);
    var element = getElementOfNode(node);

    if (node == null || element == null) {
      return null;
    }
    if (element.library?.isInSdk == true) {
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
      return true;
    }
    if (element is LibraryImportElement) {
      return true;
    }
    if (element is LabelElement || element is LocalElement) {
      return true;
    }
    if (enclosingElement is InterfaceElement ||
        enclosingElement is ExtensionElement ||
        enclosingElement is CompilationUnitElement) {
      return true;
    }
    return false;
  }
}

class CiderReplaceMatch {
  final String path;
  List<ReplaceInfo> matches;

  CiderReplaceMatch(this.path, this.matches);
}

class FlutterWidgetRename {
  final String name;
  // TODO(srawlins): Provide a deprecation message, or remove.
  // ignore: provide_deprecation_message
  @deprecated
  final List<CiderSearchMatch> matches;
  final List<CiderReplaceMatch> replacements;

  FlutterWidgetRename(this.name, this.matches, this.replacements);
}

/// The corresponding `State` declaration of a  Flutter `StatefulWidget`.
class FlutterWidgetState {
  ClassElement state;
  String newName;

  FlutterWidgetState(this.state, this.newName);
}

class RenameResponse {
  // TODO(srawlins): Provide a deprecation message, or remove.
  // ignore: provide_deprecation_message
  @deprecated
  final List<CiderSearchMatch> matches;
  final CheckNameResponse checkName;
  final List<CiderReplaceMatch> replaceMatches;
  FlutterWidgetRename? flutterWidgetRename;

  RenameResponse(this.matches, this.checkName, this.replaceMatches,
      {this.flutterWidgetRename});
}

class ReplaceInfo {
  final String replacementText;
  final CharacterLocation startPosition;
  final int length;

  ReplaceInfo(this.replacementText, this.startPosition, this.length);

  @override
  int get hashCode => Object.hash(
        replacementText,
        startPosition,
        length,
      );

  @override
  bool operator ==(Object other) =>
      other is ReplaceInfo &&
      replacementText == other.replacementText &&
      startPosition == other.startPosition &&
      length == other.length;
}

extension on List<CiderReplaceMatch> {
  void addMatch(String path, List<ReplaceInfo> infos) {
    for (var m in this) {
      if (m.path == path) {
        m.matches.addAll(infos);
        return;
      }
    }
    add(CiderReplaceMatch(path, infos));
  }
}
