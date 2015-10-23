// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.contributor.dart.importuri;

import 'dart:async';
import 'dart:core' hide Resource;

import 'package:analysis_server/src/services/completion/dart_completion_manager.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:path/path.dart' show posix;
import 'package:path/src/context.dart';

import '../../protocol_server.dart'
    show CompletionSuggestion, CompletionSuggestionKind;

/**
 * A contributor for calculating uri suggestions
 * for import and part directives.
 */
class UriContributor extends DartCompletionContributor {
  _UriSuggestionBuilder builder;

  @override
  bool computeFast(DartCompletionRequest request) {
    builder = new _UriSuggestionBuilder(request);
    return builder.computeFast(request.target.containingNode);
  }

  @override
  Future<bool> computeFull(DartCompletionRequest request) {
    return new Future.value(false);
  }
}

class _UriSuggestionBuilder extends SimpleAstVisitor {
  final DartCompletionRequest request;

  _UriSuggestionBuilder(this.request);

  bool computeFast(AstNode node) {
    node.accept(this);
    return true;
  }

  @override
  visitExportDirective(ExportDirective node) {
    visitNamespaceDirective(node);
  }

  @override
  visitImportDirective(ImportDirective node) {
    visitNamespaceDirective(node);
  }

  visitNamespaceDirective(NamespaceDirective node) {
    StringLiteral uri = node.uri;
    if (uri is SimpleStringLiteral) {
      int offset = request.offset;
      if (uri.offset < offset &&
          (offset < uri.end || offset == uri.offset + 1)) {
        // Handle degenerate case where import or export is only line in file
        // and there is no semicolon
        visitSimpleStringLiteral(uri);
      }
    }
  }

  @override
  visitSimpleStringLiteral(SimpleStringLiteral node) {
    AstNode parent = node.parent;
    if (parent is NamespaceDirective && parent.uri == node) {
      String partialUri = _extractPartialUri(node);
      if (partialUri != null) {
        _addDartSuggestions();
        _addPackageSuggestions(partialUri);
        _addFileSuggestions(partialUri);
      }
    } else if (parent is PartDirective && parent.uri == node) {
      String partialUri = _extractPartialUri(node);
      if (partialUri != null) {
        _addFileSuggestions(partialUri);
      }
    }
  }

  void _addDartSuggestions() {
    _addSuggestion('dart:');
    SourceFactory factory = request.context.sourceFactory;
    for (SdkLibrary lib in factory.dartSdk.sdkLibraries) {
      if (!lib.isInternal && !lib.isImplementation) {
        if (!lib.shortName.startsWith('dart:_')) {
          _addSuggestion(lib.shortName,
              relevance: lib.shortName == 'dart:core'
                  ? DART_RELEVANCE_LOW
                  : DART_RELEVANCE_DEFAULT);
        }
      }
    }
  }

  void _addFileSuggestions(String partialUri) {
    ResourceProvider resProvider = request.resourceProvider;
    Context resContext = resProvider.pathContext;
    Source source = request.source;

    String parentUri;
    if ((partialUri.endsWith('/'))) {
      parentUri = partialUri;
    } else {
      parentUri = posix.dirname(partialUri);
      if (parentUri != '.' && !parentUri.endsWith('/')) {
        parentUri = '$parentUri/';
      }
    }
    String uriPrefix = parentUri == '.' ? '' : parentUri;

    String dirPath = resContext.normalize(parentUri);
    if (resContext.isRelative(dirPath)) {
      String sourceDirPath = resContext.dirname(source.fullName);
      if (resContext.isAbsolute(sourceDirPath)) {
        dirPath = resContext.join(sourceDirPath, dirPath);
      } else {
        return;
      }
    }

    Resource dir = resProvider.getResource(dirPath);
    if (dir is Folder) {
      for (Resource child in dir.getChildren()) {
        String completion;
        if (child is Folder) {
          completion = '$uriPrefix${child.shortName}/';
        } else {
          completion = '$uriPrefix${child.shortName}';
        }
        if (completion != source.shortName) {
          _addSuggestion(completion);
        }
      }
    }
  }

  void _addPackageFolderSuggestions(
      String partial, String prefix, Folder folder) {
    for (Resource child in folder.getChildren()) {
      if (child is Folder) {
        String childPrefix = '$prefix${child.shortName}/';
        _addSuggestion(childPrefix);
        if (partial.startsWith(childPrefix)) {
          _addPackageFolderSuggestions(partial, childPrefix, child);
        }
      } else {
        _addSuggestion('$prefix${child.shortName}');
      }
    }
  }

  void _addPackageSuggestions(String partial) {
    SourceFactory factory = request.context.sourceFactory;
    Map<String, List<Folder>> packageMap = factory.packageMap;
    if (packageMap != null) {
      _addSuggestion('package:');
      packageMap.forEach((String pkgName, List<Folder> folders) {
        String prefix = 'package:$pkgName/';
        _addSuggestion(prefix);
        for (Folder folder in folders) {
          if (folder.exists) {
            _addPackageFolderSuggestions(partial, prefix, folder);
          }
        }
      });
    }
  }

  void _addSuggestion(String completion,
      {int relevance: DART_RELEVANCE_DEFAULT}) {
    request.addSuggestion(new CompletionSuggestion(
        CompletionSuggestionKind.IMPORT,
        relevance,
        completion,
        completion.length,
        0,
        false,
        false));
  }

  String _extractPartialUri(SimpleStringLiteral node) {
    if (request.offset < node.contentsOffset) {
      return null;
    }
    String partial = node.literal.lexeme.substring(
        node.contentsOffset - node.offset, request.offset - node.offset);
    request.replacementOffset = node.contentsOffset;
    request.replacementLength = node.contentsEnd - node.contentsOffset;
    return partial;
  }
}
