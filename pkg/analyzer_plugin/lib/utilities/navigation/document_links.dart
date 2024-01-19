// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/doc_comment.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/ast/ast.dart';

/// A link to another document found in a Dart file.
class DartDocumentLink {
  final String targetPath;
  final int offset;
  final int length;

  DartDocumentLink(this.offset, this.length, this.targetPath);
}

/// A visitor to locate links to other documents in a file.
///
/// Such paths include "See example/a/b.dart" in documentation comments.
class DartDocumentLinkVisitor extends RecursiveAstVisitor<void> {
  final ParsedUnitResult unit;
  final String filePath;
  final ResourceProvider resourceProvider;
  final _documentLinks = <DartDocumentLink>[];

  /// The directory that contains `examples/api`, `null` if not found.
  late final Folder? folderWithExamplesApi = () {
    var file = resourceProvider.getFile(filePath);
    for (var parent in file.parent.withAncestors) {
      var apiFolder = parent
          .getChildAssumingFolder('examples')
          .getChildAssumingFolder('api');
      if (apiFolder.exists) {
        return parent;
      }
    }
    return null;
  }();

  DartDocumentLinkVisitor(this.resourceProvider, this.unit)
      : filePath = unit.path;

  List<DartDocumentLink> findLinks(AstNode node) {
    _documentLinks.clear();
    node.accept(this);
    return _documentLinks;
  }

  @override
  void visitComment(Comment node) {
    super.visitComment(node);

    var content = unit.content;

    var toolDirectives = node.docDirectives
        .where((directive) => directive.type == DocDirectiveType.tool)
        .whereType<BlockDocDirective>();
    for (var toolDirective in toolDirectives) {
      var contentsStart = toolDirective.openingTag.end;
      var contentsEnd = toolDirective.closingTag?.offset;

      // Skip unclosed tags.
      if (contentsEnd == null) {
        continue;
      }

      var strValue = content.substring(contentsStart, contentsEnd);
      if (strValue.isEmpty) {
        continue;
      }

      var seeCodeIn = '** See code in ';
      var startIndex = strValue.indexOf('${seeCodeIn}examples/api/');
      if (startIndex != -1) {
        final folderWithExamplesApi = this.folderWithExamplesApi;
        if (folderWithExamplesApi == null) {
          // Examples directory doesn't exist.
          return;
        }
        startIndex += seeCodeIn.length;
        var endIndex = strValue.indexOf('.dart') + 5;
        var pathSnippet = strValue.substring(startIndex, endIndex);
        // Split on '/' because that's what the comment syntax uses, but
        // re-join it using the resource provider to get the right separator
        // for the platform.
        var examplePath = resourceProvider.pathContext.joinAll([
          folderWithExamplesApi.path,
          ...pathSnippet.split('/'),
        ]);
        var offset = contentsStart + startIndex;
        var length = endIndex - startIndex;
        _documentLinks.add(DartDocumentLink(offset, length, examplePath));
      }
    }
  }
}
