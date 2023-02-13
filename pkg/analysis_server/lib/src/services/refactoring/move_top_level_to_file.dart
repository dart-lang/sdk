// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_custom_generated.dart'
    show CommandParameter, SaveUriCommandParameter;
import 'package:analysis_server/src/services/refactoring/framework/refactoring_producer.dart';
import 'package:analysis_server/src/utilities/extensions/ast.dart';
import 'package:analysis_server/src/utilities/import_analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// A refactoring that will move one or more top-level declarations to a
/// different file. The destination file can either be a new file or an existing
/// file.
class MoveTopLevelToFile extends RefactoringProducer {
  /// Return the name used for this command when communicating with the client.
  static const String commandName = 'move_top_level_to_file';

  @override
  late String title;

  /// The default path of the file to which the declarations should be moved.
  late String defaultFilePath;

  /// Initialize a newly created refactoring producer to use the given
  /// [context].
  MoveTopLevelToFile(super.context);

  @override
  List<CommandParameter> get parameters => [
        SaveUriCommandParameter(
          parameterLabel: 'Move to:',
          parameterTitle: 'Select a file to move to',
          actionLabel: 'Move',
          // defaultValue is a String URI.
          defaultValue: Uri.file(defaultFilePath).toString(),
          filters: {
            'Dart': ['dart']
          },
        ),
      ];

  @override
  Future<void> compute(
      List<Object?> commandArguments, ChangeBuilder builder) async {
    var members = _membersToMove();
    if (members == null) {
      return;
    }
    _initializeFromMembers(members);
    var sourcePath = members.containingFile;
    // TODO(dantup): Add refactor-specific validation for incoming arguments.
    // Argument is a String URI.
    var destinationUri = Uri.parse(commandArguments[0] as String);
    var destinationFilePath = destinationUri.toFilePath();

    var destinationImportUri =
        unitResult.session.uriConverter.pathToUri(destinationFilePath);
    if (destinationImportUri == null) {
      return;
    }
    var destinationExists =
        unitResult.session.resourceProvider.getFile(destinationFilePath).exists;
    String? fileHeader;
    if (!destinationExists) {
      var headerTokens = unitResult.unit.fileHeader;
      if (headerTokens.isNotEmpty) {
        var offset = headerTokens.first.offset;
        var end = headerTokens.last.end;
        fileHeader = utils.getText(offset, end - offset);
      }
    }

    var lineInfo = unitResult.lineInfo;
    var ranges = members.groups
        .map((group) =>
            group.sourceRange(lineInfo, includePreceedingLine: false))
        .toList();
    var analyzer = ImportAnalyzer(libraryResult, sourcePath, ranges);

    await builder.addDartFileEdit(destinationFilePath, (builder) {
      // TODO(dantup): Ensure the range inserted and deleted match (allowing for
      //  whitespace), including handling of leading/trailing comments etc.
      if (fileHeader != null) {
        builder.fileHeader = fileHeader + utils.endOfLine;
      }
      builder.addInsertion(0, (builder) {
        for (var i = 0; i < members.groups.length; i++) {
          var group = members.groups[i];
          var sourceRange =
              group.sourceRange(lineInfo, includePreceedingLine: i > 0);
          builder.write(utils.getRangeText(sourceRange));
        }
      });
      if (analyzer.hasMovingReferenceToStayingDeclaration) {
        builder.importLibrary(unitResult.uri);
      }
      _addImportsForMovingDeclarations(builder, analyzer);
    });
    await builder.addDartFileEdit(sourcePath, (builder) {
      if (analyzer.hasStayingReferenceToMovingDeclaration) {
        builder.importLibrary(destinationImportUri);
      }
      for (var group in members.groups) {
        var sourceRange =
            group.sourceRange(lineInfo, includePreceedingLine: true);
        builder.addDeletion(sourceRange);
      }
    });
    // TODO(brianwilkerson) This doesn't correctly handle prefixes. In order to
    //  use the correct prefix when adding the import we need to enhance
    //  `SearchMatch` to know the prefix used for a reference match. The index
    //  already has the required information, it just isn't available yet in the
    //  result object.
    var libraries = <LibraryElement, Set<Element>>{};
    for (var element in analyzer.movingDeclarations) {
      var matches = await searchEngine.searchReferences(element);
      for (var match in matches) {
        if (match.isResolved) {
          libraries.putIfAbsent(match.libraryElement, () => {}).add(element);
        }
      }
    }

    /// Don't update the library from which the code is being moved because
    /// that's already been done.
    libraries.remove(libraryResult.element);
    for (var entry in libraries.entries) {
      var library = entry.key;
      var prefixes = <String>{};
      for (var element in entry.value) {
        var prefixList =
            await searchEngine.searchPrefixesUsedInLibrary(library, element);
        prefixes.addAll(prefixList);
      }
      await builder.addDartFileEdit(library.source.fullName, (builder) {
        for (var prefix in prefixes) {
          if (prefix.isEmpty) {
            builder.importLibrary(destinationImportUri);
          } else {
            builder.importLibrary(destinationImportUri, prefix: prefix);
          }
        }
      });
    }
  }

  @override
  bool isAvailable() {
    if (supportsFileCreation) {
      var members = _membersToMove();
      if (members != null) {
        _initializeFromMembers(members);
        return true;
      }
    }
    return false;
  }

  /// Use the [builder] to add the imports that need to be added to the library
  /// to which the code is being moved based on the information in the import
  /// [analyzer].
  void _addImportsForMovingDeclarations(
      DartFileEditBuilder builder, ImportAnalyzer analyzer) {
    for (var entry in analyzer.movingReferences.entries) {
      var library = entry.key.library;
      if (library != null && !library.isDartCore) {
        var uri = library.source.uri;
        for (var prefix in entry.value) {
          builder.importLibrary(uri, prefix: prefix.isEmpty ? null : prefix);
        }
      }
    }
  }

  /// Initialize the [title] and [defaultFilePath] based on the [members] being
  /// moved.
  void _initializeFromMembers(_MembersToMove members) {
    title = members.title;
    var sourcePath = members.containingFile;
    var context = unitResult.session.resourceProvider.pathContext;
    defaultFilePath =
        context.join(context.dirname(sourcePath), members.defaultFileName);
  }

  /// Return a description of the member to be moved.
  _MembersToMove? _membersToMove() {
    var unitPath = unitResult.path;
    var selectedNodes = _selectedNodes();
    if (selectedNodes == null) {
      return null;
    }
    var multipleSelected = selectedNodes.length > 1;
    bool validSelection(Token? token) {
      return multipleSelected || selectionIsInToken(token);
    }

    var candidateMembers = <_Member>[];
    var sealedDeclarations = <CompilationUnitMember>[];
    for (var node in selectedNodes) {
      String? name;
      if (node is ClassDeclaration && validSelection(node.name)) {
        if ((node as ClassDeclarationImpl).sealedKeyword != null) {
          sealedDeclarations.add(node);
        }
        name = node.name.lexeme;
      } else if (node is EnumDeclaration && validSelection(node.name)) {
        name = node.name.lexeme;
      } else if (node is ExtensionDeclaration && validSelection(node.name)) {
        name = node.name!.lexeme;
      } else if (node is FunctionDeclaration &&
          node.parent is CompilationUnit &&
          validSelection(node.name)) {
        name = node.name.lexeme;
      } else if (node is MixinDeclaration && validSelection(node.name)) {
        if ((node as MixinDeclarationImpl).sealedKeyword != null) {
          sealedDeclarations.add(node);
        }
        name = node.name.lexeme;
      } else if (node is TopLevelVariableDeclaration) {
        var variables = node.variables.variables;
        if (variables.length == 1) {
          name = variables[0].name.lexeme;
        }
      } else if (node is TypeAlias && validSelection(node.name)) {
        name = node.name.lexeme;
      } else {
        return null;
      }
      candidateMembers.add(_Member(node, name));
    }
    if (sealedDeclarations.isNotEmpty) {
      // TODO(brianwilkerson) Handle sealed classes by adding all of their
      //  subclasses to `members`.
      return null;
    }
    return _MembersToMove(unitPath, [_MemberGroup(candidateMembers)]);
  }

  /// Return a list containing the top-level declarations that are selected, or
  /// `null` if there are no such nodes.
  List<CompilationUnitMember>? _selectedNodes() {
    var selection = this.selection;
    if (selection == null) {
      return null;
    }
    var node = selection.coveringNode;
    if (node is CompilationUnit) {
      var nodes = selection.nodesInRange();
      if (nodes.isNotEmpty &&
          !nodes.any((element) => element is! CompilationUnitMember)) {
        return nodes.cast<CompilationUnitMember>();
      }
      return null;
    } else if (node is VariableDeclaration) {
      var declaration = node.parent?.parent;
      if (declaration is TopLevelVariableDeclaration &&
          declaration.variables.variables.length == 1 &&
          selectionIsInToken(node.name)) {
        return [declaration];
      }
    } else if (node is CompilationUnitMember) {
      return [node];
    }
    return null;
  }
}

/// Information about a member to be moved.
class _Member {
  /// The member to be moved.
  final CompilationUnitMember member;

  /// The name of the member, or `null` if the member doesn't have a name, such
  /// as an unnamed extension or a variable declaration with multiple variables.
  final String? name;

  /// Initialize a newly created instance representing the [member] with the
  /// given [name].
  _Member(this.member, this.name);
}

/// Information about a contiguous group of members to be moved.
class _MemberGroup {
  /// The contiguous members to be moved.
  final List<_Member> members;

  /// Initialize a newly created instance representing a group of contiguous
  /// [members].
  _MemberGroup(this.members);

  /// Return the member representing the [declaration].
  _Member? memberFor(CompilationUnitMember declaration) {
    for (var member in members) {
      if (member.member == declaration) {
        return member;
      }
    }
    return null;
  }

  /// Return the source range that includes all of the members in this group.
  SourceRange sourceRange(LineInfo lineInfo,
      {required bool includePreceedingLine}) {
    var firstMember = members.first.member;
    var start = firstMember.offset;
    if (includePreceedingLine) {
      var startLine = lineInfo.getLocation(start).lineNumber;
      var previousLine = lineInfo
          .getLocation(firstMember.beginToken.previous!.offset)
          .lineNumber;
      if (previousLine + 1 < startLine) {
        start = lineInfo.getOffsetOfLine(previousLine);
      }
    }

    var lastMember = members.last.member;
    var end = lastMember.end;
    var endLine = lineInfo.getLocation(end).lineNumber;
    var nextToken = lastMember.endToken.next!;
    if (nextToken.isEof) {
      end = nextToken.offset;
    } else {
      var nextLine = lineInfo.getLocation(nextToken.offset).lineNumber;
      if (endLine < nextLine - 1) {
        end = lineInfo.getOffsetOfLine(endLine);
      }
    }
    return range.startOffsetEndOffset(start, end);
  }
}

/// Information about the members to be moved.
class _MembersToMove {
  /// The absolute and normalized path of the file containing the members.
  final String containingFile;

  /// The members to be moved, in groups of contiguous members.
  final List<_MemberGroup> groups;

  /// Initialize a newly created instance representing the [member] with the
  /// given [name].
  _MembersToMove(this.containingFile, this.groups);

  /// Return the name that should be used for the file to which the members will
  /// be moved.
  String get defaultFileName {
    if (groups.isEmpty) {
      return 'newFile.dart';
    }
    var name = groups[0].members[0].name;
    if (name == null) {
      return 'newFile.dart';
    }
    return _fileNameForClassName(name);
  }

  /// Return `true` if there are no members to be moved.
  bool get isEmpty => groups.isEmpty;

  /// Return the title to be used for the refactoring.
  String get title {
    var count = 0;
    for (var group in groups) {
      for (var member in group.members) {
        var node = member.member;
        if (node is TopLevelVariableDeclaration) {
          count += node.variables.variables.length;
        } else {
          count++;
        }
      }
    }
    if (count == 1) {
      return "Move '${groups[0].members[0].name}' to file";
    }
    return 'Move $count declarations to file';
  }

  /// Computes a filename for a given class name (convert from PascalCase to
  /// snake_case).
  String _fileNameForClassName(String className) {
    // TODO(brianwilkerson) Copied from handler_rename.dart. Move this code to a
    //  common location, preferably as an extension on `String` and make the
    //  name more general (because it can be used for any top-level declaration,
    //  not just classes).
    final fileName = className
        .replaceAllMapped(RegExp('[A-Z]'),
            (match) => match.start == 0 ? match[0]! : '_${match[0]}')
        .toLowerCase();
    return '$fileName.dart';
  }
}
