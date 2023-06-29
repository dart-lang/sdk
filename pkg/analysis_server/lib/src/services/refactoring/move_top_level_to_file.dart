// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_custom_generated.dart'
    show CommandParameter, SaveUriCommandParameter;
import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/services/refactoring/framework/refactoring_producer.dart';
import 'package:analysis_server/src/utilities/extensions/ast.dart';
import 'package:analysis_server/src/utilities/extensions/string.dart';
import 'package:analysis_server/src/utilities/import_analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:collection/collection.dart';

/// A refactoring that will move one or more top-level declarations to a
/// different file. The destination file can either be a new file or an existing
/// file.
class MoveTopLevelToFile extends RefactoringProducer {
  /// Return the name used for this command when communicating with the client
  /// (and for analytics).
  static const String commandName = 'dart.refactor.move_top_level_to_file';

  @override
  late String title;

  /// The default path of the file to which the declarations should be moved.
  late String defaultFilePath;

  /// Initialize a newly created refactoring producer to use the given
  /// [context].
  MoveTopLevelToFile(super.context);

  @override
  bool get isExperimental => false;

  @override
  CodeActionKind get kind => DartCodeActionKind.RefactorMove;

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
    var destinationFile =
        unitResult.session.resourceProvider.getFile(destinationFilePath);
    var destinationExists = destinationFile.exists;
    var insertOffset = 0;
    var insertLeadingNewline = false;
    String? fileHeader;
    if (!destinationExists) {
      var headerTokens = unitResult.unit.fileHeader;
      if (headerTokens.isNotEmpty) {
        var offset = headerTokens.first.offset;
        var end = headerTokens.last.end;
        fileHeader = utils.getText(offset, end - offset);
      }
    } else {
      // If the file exists, insert at the end because there may be directives
      // at the start.
      insertOffset = destinationFile.lengthSync;
      insertLeadingNewline = true;
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
      builder.addInsertion(insertOffset, (builder) {
        if (insertLeadingNewline) {
          builder.writeln();
        }
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
          builder.importLibrary(destinationImportUri, prefix: prefix);
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
      var element = entry.key;
      var imports = entry.value;
      for (var import in imports) {
        var library = import.importedLibrary;
        if (library == null || library.isDartCore) {
          continue;
        }
        var hasShowCombinator =
            import.combinators.whereType<ShowElementCombinator>().isNotEmpty;
        builder.importLibrary(
          library.source.uri,
          prefix: import.prefix?.element.name,
          showName: hasShowCombinator ? element.name : null,
        );
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

    var candidateMembers = <CompilationUnitMember, String?>{};
    var sealedDeclarations = <CompilationUnitMember>[];
    for (var node in selectedNodes) {
      String? name;
      if (node is ClassDeclaration && validSelection(node.name)) {
        if (node.sealedKeyword != null) {
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
      candidateMembers[node] = name;
    }

    var index = _SealedSubclassIndex(
      unitResult.unit,
      candidateElements: candidateMembers.keys
          .map((member) => member.declaredElement)
          .whereNotNull()
          .toSet(),
    );

    if (index.hasInvalidCandidateSet) {
      return null;
    }

    // Include any direct subclasses of any sealed candidate.
    for (var sub in index
        .findSubclassesOfSealedRecursively(candidateMembers.keys.toSet())) {
      candidateMembers[sub] ??=
          sub is NamedCompilationUnitMember ? sub.name.lexeme : null;
    }

    // Ensure there aren't any subclasses of sealed items in other parts of this
    // library that could result in invalid code.
    //
    // Technically we could allow this is moving to another part of the same
    // library but at this point we don't know the destination.
    if (_otherPartsContainDirectSubclassesOfSealedCandidates(
        candidateMembers.keys)) {
      return null;
    }

    return _MembersToMove(unitPath, [
      _MemberGroup(candidateMembers.entries
          .map((entry) => _Member(entry.key, entry.value))
          .toList())
    ]);
  }

  /// Checks whether any part files in [libraryResult] that aren't the source
  /// file contain direct subclasses of any sealed [candidates].
  bool _otherPartsContainDirectSubclassesOfSealedCandidates(
    Iterable<CompilationUnitMember> candidates,
  ) {
    return libraryResult.units
        // Exclude the source file.
        .where((unit) => unit != unitResult)
        // All sealed superclasses.
        .expand((unit) => unit.unit.declarations)
        .expand((declaration) => declaration.sealedSuperclassElements)
        // Check if any of them are in the source file.
        .map((element) => element.enclosingElement2)
        .contains(unitResult.unit.declaredElement);
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
      var previous = firstMember.beginToken.previous;
      if (previous != null) {
        var previousLine = lineInfo.getLocation(previous.offset).lineNumber;
        if (previousLine + 1 < startLine) {
          start = lineInfo.getOffsetOfLine(previousLine);
        }
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
    return name.toFileName;
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
}

/// A helper to for matching sealed classes to their subclasses.
class _SealedSubclassIndex {
  final CompilationUnit unit;

  /// The set of initial candidate elements.
  final Set<Element> candidateElements;

  /// A map of sealed named classes/mixin elements to a set of their subclasses.
  final Map<Element, Set<CompilationUnitMember>> sealedTypeSubclasses = {};

  /// Whether or not the candidate set is invalid.
  ///
  /// It's valid to select a sealed class/mixin with or without it's subclasses
  /// because they will be moved automatically.
  ///
  /// It's not valid to select subclasses of sealed class/mixins as we won't
  /// expand the candidate set upwards.
  ///
  /// When the candidate set is invalid, other results produced by this class
  /// may be incomplete.
  bool hasInvalidCandidateSet = false;

  _SealedSubclassIndex(
    this.unit, {
    required this.candidateElements,
  }) {
    final isCandidate = candidateElements.contains;

    // Index the declaration against each of its direct superclasses.
    for (var declaration in unit.declarations) {
      for (var superElement in declaration.sealedSuperclassElements) {
        sealedTypeSubclasses
            .putIfAbsent(superElement, () => {})
            .add(declaration);

        // If this declaration is a candidate but it's sealed super is not,
        // we have an invalid selection.
        if (isCandidate(declaration.declaredElement) &&
            !isCandidate(superElement)) {
          hasInvalidCandidateSet = true;
          return;
        }
      }
    }
  }

  /// Returns a set of that includes [members] and for each member that is
  /// sealed, it's direct subclasses.
  ///
  /// If any subclass is itself sealed, recursively includes it's direct
  /// subclasses.
  Set<CompilationUnitMember> findSubclassesOfSealedRecursively(
      Set<CompilationUnitMember> members) {
    return {
      ...members,
      ...members.whereType<NamedCompilationUnitMember>().expand((member) =>
          findSubclassesOfSealedRecursively(
              sealedTypeSubclasses[member.declaredElement] ?? const {})),
    };
  }
}

extension on CompilationUnitMember {
  /// Gets all sealed [ClassElement]s that are superclasses of this member.
  Iterable<ClassElement> get sealedSuperclassElements {
    return superclasses
        .map((type) => type?.element)
        .whereType<ClassElement>()
        .where((element) => element.isSealed);
  }

  /// Gets all [NamedType]s that are superclasses of this member.
  List<NamedType?> get superclasses {
    final declaration = this;

    if (declaration is ClassDeclaration) {
      final extendsType = declaration.extendsClause?.superclass;
      final implementsTypes = declaration.implementsClause?.interfaces;
      final mixesInTypes = declaration.withClause?.mixinTypes;

      return [
        if (extendsType != null) extendsType,
        ...?implementsTypes,
        ...?mixesInTypes,
      ];
    } else if (declaration is MixinDeclaration) {
      final interfaceTypes = declaration.implementsClause?.interfaces;
      final constraintTypes = declaration.onClause?.superclassConstraints;

      return [
        ...?interfaceTypes,
        ...?constraintTypes,
      ];
    }

    return const [];
  }
}
