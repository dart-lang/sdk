// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_custom_generated.dart';
import 'package:analysis_server/src/services/refactoring/framework/refactoring_producer.dart';
import 'package:analysis_server/src/utilities/extensions/ast.dart';
import 'package:analysis_server/src/utilities/import_analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// An object that can compute a refactoring in a Dart file.
class MoveTopLevelToFile extends RefactoringProducer {
  /// Return the name used for this command when communicating with the client.
  static const String commandName = 'move_top_level_to_file';

  @override
  late String title;

  /// The default path of the file to which the declaration should be moved.
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

  /// Return the member to be moved. As a side-effect, initialize the [title]
  /// and [defaultFilePath].
  _MemberToMove? get _memberToMove {
    // TODO(brianwilkerson) Extend this to support the selection of multiple
    //  top-level declarations by returning a list of the members to be moved.
    var node = selectedNode;
    // TODO(brianwilkerson) If the caret is at the end of the name and before
    //  the parameter list, then the `node` is the parameter list. This code
    //  doesn't handle that case yet.
    if (node is VariableDeclaration) {
      var declaration = node.parent?.parent;
      if (declaration is TopLevelVariableDeclaration &&
          declaration.variables.variables.length == 1 &&
          selectionIsInToken(node.name)) {
        return _memberFor(declaration, node.name.lexeme);
      }
    }
    if (node is! CompilationUnitMember) {
      return null;
    }
    String name;
    if (node is ClassDeclaration && selectionIsInToken(node.name)) {
      name = node.name.lexeme;
    } else if (node is EnumDeclaration && selectionIsInToken(node.name)) {
      name = node.name.lexeme;
    } else if (node is ExtensionDeclaration && selectionIsInToken(node.name)) {
      name = node.name!.lexeme;
    } else if (node is FunctionDeclaration &&
        node.parent is CompilationUnit &&
        selectionIsInToken(node.name)) {
      name = node.name.lexeme;
    } else if (node is MixinDeclaration && selectionIsInToken(node.name)) {
      name = node.name.lexeme;
    } else if (node is TypeAlias && selectionIsInToken(node.name)) {
      name = node.name.lexeme;
    } else {
      return null;
    }
    return _memberFor(node, name);
  }

  @override
  Future<void> compute(
      List<Object?> commandArguments, ChangeBuilder builder) async {
    var member = _memberToMove;
    if (member == null) {
      return;
    }
    var sourcePath = member.containingFile;
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

    var analyzer =
        ImportAnalyzer(libraryResult, sourcePath, range.node(member.node));

    await builder.addDartFileEdit(destinationFilePath, (builder) {
      // TODO(dantup): Ensure the range inserted and deleted match (allowing for
      //  whitespace), including handling of leading/trailing comments etc.
      builder.addInsertion(0, (builder) {
        if (fileHeader != null) {
          builder.writeln(fileHeader);
          builder.writeln();
        }
        builder.writeln(utils.getNodeText(member.node));
      });
      // TODO(brianwilkerson) Imports are added before the file header, which
      //  isn't what most users want.
      // TODO(brianwilkerson) Add imports required by the moved code.
      if (analyzer.hasMovingReferenceToStayingDeclaration) {
        builder.importLibrary(unitResult.uri);
      }
      _addImportsForMovingDeclarations(builder, analyzer);
    });
    await builder.addDartFileEdit(sourcePath, (builder) {
      if (analyzer.hasStayingReferenceToMovingDeclaration) {
        builder.importLibrary(destinationImportUri);
      }
      builder.addDeletion(range.deletionRange(member.node));
    });
    // TODO(brianwilkerson) Find references to the moved declaration(s) outside
    //  the source library and update the imports in those files.
  }

  @override
  bool isAvailable() => supportsFileCreation && _memberToMove != null;

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

  /// Computes a filename for a given class name (convert from PascalCase to
  /// snake_case).
  // TODO(brianwilkerson) Copied from handler_rename.dart. Move this code to a
  //  common location, preferably as an extension on `String`.
  String _fileNameForClassName(String className) {
    final fileName = className
        .replaceAllMapped(RegExp('[A-Z]'),
            (match) => match.start == 0 ? match[0]! : '_${match[0]}')
        .toLowerCase();
    return '$fileName.dart';
  }

  _MemberToMove? _memberFor(CompilationUnitMember declaration, String name) {
    // TODO(brianwilkeson) Handle other top-level members, including
    //  augmentations.
    var unitPath = unitResult.unit.declaredElement?.source.fullName;
    if (unitPath == null) {
      return null;
    }
    var context = unitResult.session.resourceProvider.pathContext;

    title = "Move '$name' to file";
    defaultFilePath =
        context.join(context.dirname(unitPath), _fileNameForClassName(name));
    return _MemberToMove(unitPath, declaration, name);
  }
}

/// Information about the member to be moved.
class _MemberToMove {
  /// The absolute and normalized path of the file containing the member.
  final String containingFile;

  /// The member to be moved.
  final CompilationUnitMember node;

  /// The name of the member.
  final String name;

  /// Initialize a newly created instance representing the [member] with the
  /// given [name].
  _MemberToMove(this.containingFile, this.node, this.name);
}
