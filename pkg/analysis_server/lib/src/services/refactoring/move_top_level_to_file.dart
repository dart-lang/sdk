// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_custom_generated.dart';
import 'package:analysis_server/src/services/refactoring/framework/refactoring_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
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
        CommandParameter(
          label: 'Move to:',
          type: CommandParameterType.filePath,
          defaultValue: defaultFilePath,
        ),
      ];

  /// Return the member to be moved. As a side-effect, initialize the [title]
  /// and [defaultFilePath].
  _MemberToMove? get _memberToMove {
    var node = selectedNode;
    if (node is ClassDeclaration && selectionIsInToken(node.name2)) {
      var name = node.name2.lexeme;
      var unitPath = result.unit.declaredElement?.source.fullName;
      if (unitPath == null) {
        return null;
      }
      var context = result.session.resourceProvider.pathContext;

      title = "Move '$name' to file";
      defaultFilePath =
          context.join(context.dirname(unitPath), _fileNameForClassName(name));
      return _MemberToMove(unitPath, node, name);
    }
    // TODO(brianwilkeson) Handle other top-level members.
    return null;
  }

  @override
  Future<void> compute(
      List<String> commandArguments, ChangeBuilder builder) async {
    var member = _memberToMove;
    if (member == null) {
      return;
    }
    // TODO(brianwilkerson) Copy the file header to the new file.
    await builder.addDartFileEdit(commandArguments[0], (builder) {
      // TODO(dantup): Ensure the range inserted and deleted match (allowing for
      //  whitespace), including handling of leading/trailing comments etc.
      builder.addInsertion(0, (builder) {
        builder.writeln(utils.getNodeText(member.node));
      });
    });
    await builder.addDartFileEdit(member.containingFile, (builder) {
      builder.addDeletion(range.deletionRange(member.node));
    });
  }

  @override
  bool isAvailable() => supportsFileCreation && _memberToMove != null;

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
