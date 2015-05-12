// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.contributor.dart.importuri;

import 'dart:async';
import 'dart:collection';

import 'package:analysis_server/src/services/completion/dart_completion_manager.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:path/path.dart';

import '../../protocol_server.dart'
    show CompletionSuggestion, CompletionSuggestionKind;

/**
 * A contributor for calculating uri suggestions
 * for import and part directives.
 */
class ImportUriContributor extends DartCompletionContributor {
  _ImportUriSuggestionBuilder builder;

  @override
  bool computeFast(DartCompletionRequest request) {
    builder = new _ImportUriSuggestionBuilder(request);
    return builder.computeFast(request.target.containingNode);
  }

  @override
  Future<bool> computeFull(DartCompletionRequest request) {
    return new Future.value(false);
  }
}

class _ImportUriSuggestionBuilder extends SimpleAstVisitor {
  final DartCompletionRequest request;
  HashSet<String> _importedUris;

  _ImportUriSuggestionBuilder(this.request);

  bool computeFast(AstNode node) {
    node.accept(this);
    return true;
  }

  @override
  visitSimpleStringLiteral(SimpleStringLiteral node) {
    AstNode parent = node.parent;
    if (parent is ImportDirective && parent.uri == node) {
      String partial = node.literal.lexeme.substring(
          node.contentsOffset - node.offset, request.offset - node.offset);
      _computeImportedUris();
      request.replacementOffset = node.contentsOffset;
      request.replacementLength = node.contentsEnd - node.contentsOffset;
      _addDartSuggestions();
      _addPackageSuggestions(partial);
      _addFileSuggestions(partial);
    } else if (parent is PartDirective && parent.uri == node) {
      String partial = node.literal.lexeme.substring(
          node.contentsOffset - node.offset, request.offset - node.offset);
      _computeImportedUris();
      request.replacementOffset = node.contentsOffset;
      request.replacementLength = node.contentsEnd - node.contentsOffset;
      _addFileSuggestions(partial);
    }
  }

  void _addDartSuggestions() {
    _addSuggestion('dart:');
    SourceFactory factory = request.context.sourceFactory;
    for (SdkLibrary lib in factory.dartSdk.sdkLibraries) {
      if (!lib.isInternal && !lib.isImplementation) {
        if (!lib.shortName.startsWith('dart:_')) {
          _addSuggestion(lib.shortName);
        }
      }
    }
  }

  void _addFileSuggestions(String partial) {
    Source source = request.source;
    String sourceFullName = source.fullName;
    String sourceShortName = source.shortName;
    String dirPath = (partial.endsWith('/') || partial.endsWith(separator))
        ? partial
        : dirname(partial);
    String prefix = dirPath == '.' ? '' : dirPath;
    if (isRelative(dirPath)) {
      String sourceDir = dirname(sourceFullName);
      if (isAbsolute(sourceDir)) {
        dirPath = join(sourceDir, dirPath);
      } else {
        return;
      }
    }
    Resource dir = request.resourceProvider.getResource(dirPath);
    if (dir is Folder) {
      for (Resource child in dir.getChildren()) {
        String completion;
        if (child is Folder) {
          completion = '$prefix${child.shortName}$separator';
        } else {
          completion = '$prefix${child.shortName}';
        }
        if (completion != sourceShortName && completion != sourceFullName) {
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

  void _addSuggestion(String completion) {
    if (!_importedUris.contains(completion)) {
      request.addSuggestion(new CompletionSuggestion(
          CompletionSuggestionKind.IMPORT, DART_RELEVANCE_DEFAULT, completion,
          completion.length, 0, false, false));
    }
  }

  void _computeImportedUris() {
    _importedUris = new HashSet<String>();
    _importedUris.add('dart:core');
    for (Directive directive in request.unit.directives) {
      if (directive is ImportDirective) {
        String uri = directive.uriContent;
        if (uri != null && uri.length > 0) {
          _importedUris.add(uri);
        }
      }
    }
  }
}
