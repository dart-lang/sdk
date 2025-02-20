// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart' hide Element;
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/services/refactoring/legacy/naming_conventions.dart';
import 'package:analysis_server/src/services/refactoring/legacy/refactoring.dart';
import 'package:analysis_server/src/services/search/hierarchy.dart';
import 'package:analysis_server/src/utilities/change_builder.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/micro/resolve_file.dart';
import 'package:analyzer/src/dart/micro/utils.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';
import 'package:analyzer/src/utilities/extensions/flutter.dart';

class CanRenameResponse {
  final LineInfo lineInfo;
  final RenameRefactoringElement refactoringElement;
  final FileResolver _fileResolver;
  final String filePath;

  FlutterWidgetState? _flutterWidgetState;

  CanRenameResponse(
    this.lineInfo,
    this.refactoringElement,
    this._fileResolver,
    this.filePath,
  );

  String get oldName => refactoringElement.element2.displayName;

  CheckNameResponse? checkNewName(String name) {
    var element = refactoringElement.element2;

    RefactoringStatus? status;
    if (element is FormalParameterElement) {
      status = validateParameterName(name);
    } else if (element is VariableElement2) {
      status = validateVariableName(name);
    } else if (element is LocalFunctionElement ||
        element is TopLevelFunctionElement) {
      status = validateFunctionName(name);
    } else if (element is FieldElement2) {
      status = validateFieldName(name);
    } else if (element is MethodElement2) {
      status = validateMethodName(name);
    } else if (element is TypeAliasElement2) {
      status = validateTypeAliasName(name);
    } else if (element is InterfaceElement2) {
      status = validateClassName(name);
      _flutterWidgetState = _findFlutterStateClass(element, name);
    } else if (element is ConstructorElement2) {
      status = validateConstructorName(name);
      _analyzePossibleConflicts(element, status, name);
    } else if (element is MockLibraryImportElement) {
      status = validateImportPrefixName(name);
    }

    if (status == null) {
      return null;
    }
    return CheckNameResponse(status, this, name);
  }

  void _analyzePossibleConflicts(
    ConstructorElement2 element,
    RefactoringStatus result,
    String newName,
  ) {
    var parentClass = element.enclosingElement2;
    // Check if the "newName" is the name of the enclosing class.
    if (parentClass.name3 == newName) {
      result.addError(
        'The constructor should not have the same name '
        'as the name of the enclosing class.',
      );
    }
    // check if there are members with "newName" in the same ClassElement
    for (var newNameMember in getChildren(parentClass, newName)) {
      var message = format(
        "Class '{0}' already declares {1} with name '{2}'.",
        parentClass.displayName,
        getElementKindName(newNameMember),
        newName,
      );
      result.addError(message, newLocation_fromElement2(newNameMember));
    }
  }

  FlutterWidgetState? _findFlutterStateClass(Element2 element, String newName) {
    if (element is ClassElement2 && element.isStatefulWidgetDeclaration) {
      var oldStateName = '${element.displayName}State';
      var library = element.library2;
      var state =
          library.getClass2(oldStateName) ??
          library.getClass2('_$oldStateName');
      if (state != null) {
        var flutterWidgetStateNewName = '${newName}State';
        // If the State was private, ensure that it stays private.
        if (state.name3!.startsWith('_') &&
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

  String get oldName => canRename.refactoringElement.element2.displayName;

  Future<RenameResponse?> computeRenameRanges2() async {
    var elements = <Element2>[];
    var element = canRename.refactoringElement.element2;
    if (element is PropertyInducingElement2 && element.isSynthetic) {
      var property = element;
      var getter = property.getter2;
      var setter = property.setter2;
      elements.addIfNotNull(getter);
      elements.addIfNotNull(setter);
    } else {
      elements.add(element);
    }
    var fileResolver = canRename._fileResolver;
    var matches = <CiderSearchMatch>[];
    for (var element in elements) {
      matches.addAll(await fileResolver.findReferences(element));
    }
    FlutterWidgetRename? flutterRename;
    if (canRename._flutterWidgetState != null) {
      flutterRename = await _computeFlutterStateName();
    }
    var replaceMatches = <CiderReplaceMatch>[];
    if (element is ConstructorElement2) {
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
          replaceInfo.add(
            ReplaceInfo(replacement, ref.startPosition, ref.length),
          );
        }
        replaceMatches.addMatch(match.path, replaceInfo);
      }
      if (element.isSynthetic) {
        var result = await _replaceSyntheticConstructor();
        if (result != null) {
          replaceMatches.addMatch(result.path, result.matches.toList());
        }
      }
    } else if (element is MockLibraryImportElement) {
      var replaceInfo = <ReplaceInfo>[];
      for (var match in matches) {
        for (var ref in match.references) {
          if (newName.isEmpty) {
            replaceInfo.add(ReplaceInfo('', ref.startPosition, ref.length));
          } else {
            var identifier = await _getInterpolationIdentifier(
              match.path,
              ref.startPosition,
            );
            if (identifier != null) {
              var lineInfo = canRename.lineInfo;
              replaceInfo.add(
                ReplaceInfo(
                  '{$newName.${identifier.name}}',
                  lineInfo.getLocation(identifier.offset),
                  identifier.length,
                ),
              );
            } else {
              replaceInfo.add(
                ReplaceInfo('$newName.', ref.startPosition, ref.length),
              );
            }
          }
        }
        replaceMatches.addMatch(match.path, replaceInfo);
        var sourcePath = element.libraryFragment.source.fullName;
        var infos = await _addElementDeclaration(element, sourcePath);
        replaceMatches.addMatch(sourcePath, infos);
      }
    } else {
      for (var match in matches) {
        replaceMatches.addMatch(
          match.path,
          match.references
              .map(
                (info) => ReplaceInfo(newName, info.startPosition, info.length),
              )
              .toList(),
        );
      }
      // add element declaration
      var sourcePath = element.library2!.firstFragment.source.fullName;
      var infos = await _addElementDeclaration(element, sourcePath);
      replaceMatches.addMatch(sourcePath, infos);
    }
    return RenameResponse(
      matches,
      this,
      replaceMatches,
      flutterWidgetRename: flutterRename,
    );
  }

  Future<List<ReplaceInfo>> _addElementDeclaration(
    Element2 element,
    String sourcePath,
  ) async {
    var infos = <ReplaceInfo>[];
    if (element is PropertyInducingElement2 && element.isSynthetic) {
      var getter = element.getter2;
      if (getter != null) {
        infos.add(
          ReplaceInfo(
            newName,
            lineInfo.getLocation(getter.firstFragment.nameOffset2!),
            getter.name3!.length,
          ),
        );
      }
      var setter = element.setter2;
      if (setter != null) {
        infos.add(
          ReplaceInfo(
            newName,
            lineInfo.getLocation(setter.firstFragment.nameOffset2!),
            setter.name3!.length,
          ),
        );
      }
    } else if (element is MockLibraryImportElement) {
      var unit = (await canRename._fileResolver.resolve(path: sourcePath)).unit;
      var index = element.libraryFragment.libraryImports2.indexOf(
        element.import,
      );
      var node = unit.directives.whereType<ImportDirective>().elementAt(index);
      var prefixNode = node.prefix;
      if (newName.isEmpty) {
        // We should not get `prefix == null` because we check in
        // `checkNewName` that the new name is different.
        if (prefixNode != null) {
          var prefixEnd = prefixNode.end;
          infos.add(
            ReplaceInfo(
              newName,
              lineInfo.getLocation(node.uri.end),
              prefixEnd - node.uri.end,
            ),
          );
        }
      } else {
        if (prefixNode == null) {
          var uriEnd = node.uri.end;
          infos.add(
            ReplaceInfo(' as $newName', lineInfo.getLocation(uriEnd), 0),
          );
        } else {
          var offset = prefixNode.offset;
          var length = prefixNode.length;
          infos.add(ReplaceInfo(newName, lineInfo.getLocation(offset), length));
        }
      }
    } else {
      var location = (await canRename._fileResolver.resolve(
        path: sourcePath,
      )).lineInfo.getLocation(element.firstFragment.nameOffset2!);
      infos.add(ReplaceInfo(newName, location, element.name3!.length));
    }
    return infos;
  }

  Future<FlutterWidgetRename?> _computeFlutterStateName() async {
    var flutterState = canRename._flutterWidgetState;
    var stateClass = flutterState!.state;
    var stateName = flutterState.newName;
    var match = await canRename._fileResolver.findReferences(stateClass);
    var firstFragment = stateClass.firstFragment;
    var libraryFragment = firstFragment.libraryFragment;
    var sourcePath = libraryFragment.source.fullName;
    var location = libraryFragment.lineInfo.getLocation(
      firstFragment.nameOffset2!,
    );
    CiderSearchMatch ciderMatch;
    var searchInfo = CiderSearchInfo(
      location,
      stateClass.name3!.length,
      MatchKind.DECLARATION,
    );
    try {
      ciderMatch = match.firstWhere((m) => m.path == sourcePath);
      ciderMatch.references.add(searchInfo);
    } catch (_) {
      match.add(CiderSearchMatch(sourcePath, [searchInfo]));
    }
    var replacements =
        match
            .map(
              (m) => CiderReplaceMatch(
                m.path,
                m.references
                    .map(
                      (p) => ReplaceInfo(
                        stateName,
                        p.startPosition,
                        stateClass.name3!.length,
                      ),
                    )
                    .toList(),
              ),
            )
            .toList();
    return FlutterWidgetRename(stateName, match, replacements);
  }

  /// If the reference at [loc] is before an interpolated [SimpleIdentifier] in
  /// an [InterpolationExpression] without surrounding curly brackets, return
  /// it. Otherwise return `null`.
  Future<SimpleIdentifier?> _getInterpolationIdentifier(
    String path,
    CharacterLocation loc,
  ) async {
    var resolvedUnit = await canRename._fileResolver.resolve(path: path);
    var lineInfo = resolvedUnit.lineInfo;
    var node = NodeLocator(
      lineInfo.getOffsetOfLine(loc.lineNumber - 1) + loc.columnNumber,
    ).searchWithin(resolvedUnit.unit);
    if (node is SimpleIdentifier) {
      var parent = node.parent;
      if (parent is InterpolationExpression && parent.rightBracket == null) {
        return node;
      }
    }
    return null;
  }

  Future<CiderReplaceMatch?> _replaceSyntheticConstructor() async {
    var element = canRename.refactoringElement.element2;
    var interfaceElement = element.enclosingElement2!;

    var fileResolver = canRename._fileResolver;
    var libraryPath = interfaceElement.library2!.firstFragment.source.fullName;
    var resolvedLibrary = await fileResolver.resolveLibrary2(path: libraryPath);
    var result = resolvedLibrary.getFragmentDeclaration(
      interfaceElement.firstFragment,
    );
    if (result == null) {
      return null;
    }

    var resolvedUnit = result.resolvedUnit;
    if (resolvedUnit == null) {
      return null;
    }

    var node = result.node;
    if (node is! NamedCompilationUnitMember) {
      return null;
    }
    var edit = await buildEditForInsertedConstructor(
      node,
      resolvedUnit: resolvedUnit,
      session: fileResolver.contextObjects!.analysisSession,
      (builder) => builder.writeConstructorDeclaration(
        interfaceElement.name3!,
        constructorName: newName,
        isConst: node is EnumDeclaration,
      ),
    );
    if (edit == null) {
      return null;
    }

    return CiderReplaceMatch(libraryPath, [
      ReplaceInfo(
        edit.replacement,
        resolvedUnit.lineInfo.getLocation(edit.offset),
        0,
      ),
    ]);
  }
}

class CiderRenameComputer {
  final FileResolver _fileResolver;

  CiderRenameComputer(this._fileResolver);

  /// Check if the identifier at the [line], [column] for the file at the
  /// [filePath] can be renamed.
  Future<CanRenameResponse?> canRename2(
    String filePath,
    int line,
    int column,
  ) async {
    var resolvedUnit = await _fileResolver.resolve(path: filePath);
    var lineInfo = resolvedUnit.lineInfo;
    var offset = lineInfo.getOffsetOfLine(line) + column;

    var node = NodeLocator(offset).searchWithin(resolvedUnit.unit);
    var element = getElementOfNode2(node);

    if (node == null || element == null) {
      return null;
    }
    if (element.library2?.isInSdk == true) {
      return null;
    }
    if (element is MethodElement2 && element.isOperator) {
      return null;
    }
    if (element is PropertyAccessorElement2) {
      element = element.variable3;
      if (element == null) {
        return null;
      }
    }
    if (!_canRenameElement(element)) {
      return null;
    }
    var refactoring = RenameRefactoring.getElementToRename2(node, element);
    if (refactoring != null) {
      return CanRenameResponse(lineInfo, refactoring, _fileResolver, filePath);
    }
    return null;
  }

  bool _canRenameElement(Element2 element) {
    var enclosingElement = element.enclosingElement2;
    if (element is ConstructorElement2) {
      return true;
    }
    if (element is MockLibraryImportElement) {
      return true;
    }
    if (element is LabelElement2 || element is LocalElement2) {
      return true;
    }
    if (enclosingElement is InterfaceElement2 ||
        enclosingElement is ExtensionElement2 ||
        enclosingElement is LibraryElement2) {
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
  ClassElement2 state;
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

  RenameResponse(
    this.matches,
    this.checkName,
    this.replaceMatches, {
    this.flutterWidgetRename,
  });
}

class ReplaceInfo {
  final String replacementText;
  final CharacterLocation startPosition;
  final int length;

  ReplaceInfo(this.replacementText, this.startPosition, this.length);

  @override
  int get hashCode => Object.hash(replacementText, startPosition, length);

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
