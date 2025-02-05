// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/completion/dart/candidate_suggestion.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/completion_state.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_collector.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:path/path.dart' show posix;

/// The helper class that produces candidate suggestions based on the content
/// of the file system to complete within URIs in import, export and part
/// directives.
class UriHelper {
  /// The completion request being processed.
  final DartCompletionRequest request;

  /// The suggestion collector to which suggestions will be added.
  final SuggestionCollector collector;

  /// The state used to compute the candidate suggestions.
  final CompletionState state;

  UriHelper({
    required this.request,
    required this.collector,
    required this.state,
  });

  void addSuggestions(StringLiteral uri) {
    if (uri is! SimpleStringLiteral) {
      return;
    }

    var offset = request.offset;
    var start = uri.offset;
    var end = uri.end;
    if (offset > start) {
      if (offset < end) {
        // Quoted non-empty string
        _simpleStringLiteral(uri);
      } else if (offset == end) {
        if (end == start + 1) {
          // Quoted empty string
          _simpleStringLiteral(uri);
        } else {
          var data = request.content;
          if (end == data.length) {
            var ch = data[end - 1];
            if (ch != '"' && ch != "'") {
              // Insertion point at end of file
              // and missing closing quote on non-empty string
              _simpleStringLiteral(uri);
            }
          }
        }
      }
    } else if (offset == start && offset == end) {
      var data = request.content;
      if (end == data.length) {
        var ch = data[end - 1];
        if (ch == '"' || ch == "'") {
          // Insertion point at end of file
          // and missing closing quote on empty string
          _simpleStringLiteral(uri);
        }
      }
    }
  }

  void _addDartSuggestions() {
    _suggestUri('dart:');
    var factory = request.sourceFactory;
    for (var lib in factory.dartSdk!.sdkLibraries) {
      if (!lib.isInternal && !lib.isImplementation) {
        if (!lib.shortName.startsWith('dart:_')) {
          _suggestUri(lib.shortName);
        }
      }
    }
  }

  void _addFileSuggestions(String partialUri) {
    var resProvider = request.resourceProvider;
    var resContext = resProvider.pathContext;
    var source = request.source;

    String parentUri;
    if (partialUri.endsWith('/')) {
      parentUri = partialUri;
    } else {
      parentUri = posix.dirname(partialUri);
      if (parentUri != '.' && !parentUri.endsWith('/')) {
        parentUri = '$parentUri/';
      }
    }
    var uriPrefix = parentUri == '.' ? '' : parentUri;

    // Only handle file uris in the format file:///xxx or /xxx
    var parentUriScheme = Uri.parse(parentUri).scheme;
    if (!parentUri.startsWith('file://') && parentUriScheme != '') {
      return;
    }

    var dirPath = resProvider.pathContext.fromUri(parentUri);
    dirPath = resContext.normalize(dirPath);

    if (resContext.isRelative(dirPath)) {
      var sourceDirPath = resContext.dirname(source.fullName);
      if (resContext.isAbsolute(sourceDirPath)) {
        dirPath = resContext.normalize(resContext.join(sourceDirPath, dirPath));
      } else {
        return;
      }
      // Do not suggest relative paths reaching outside the 'lib' directory.
      var srcInLib = resContext.split(sourceDirPath).contains('lib');
      var dstInLib = resContext.split(dirPath).contains('lib');
      if (srcInLib && !dstInLib) {
        return;
      }
    }
    if (dirPath.endsWith('\\.')) {
      dirPath = dirPath.substring(0, dirPath.length - 1);
    }

    var pathContext = request.resourceProvider.pathContext;
    var dir = resProvider.getResource(dirPath);
    if (dir is Folder) {
      try {
        for (var child in dir.getChildren()) {
          String? completion;
          if (child is Folder) {
            if (!child.shortName.startsWith('.')) {
              completion = '$uriPrefix${child.shortName}/';
            }
          } else if (child is File) {
            if (file_paths.isDart(pathContext, child.shortName)) {
              completion = '$uriPrefix${child.shortName}';
            }
          }
          if (completion != null && completion != source.shortName) {
            _suggestUri(completion);
          }
        }
      } on FileSystemException {
        // Guard against I/O exceptions.
      }
    }
  }

  void _addPackageFolderSuggestions(
    String partial,
    String prefix,
    Folder folder,
  ) {
    var pathContext = request.resourceProvider.pathContext;
    try {
      for (var child in folder.getChildren()) {
        if (child is Folder) {
          var childPrefix = '$prefix${child.shortName}/';
          _suggestUri(childPrefix);
          if (partial.startsWith(childPrefix)) {
            _addPackageFolderSuggestions(partial, childPrefix, child);
          }
        } else if (child is File) {
          if (file_paths.isDart(pathContext, child.path)) {
            _suggestUri('$prefix${child.shortName}');
          }
        }
      }
    } on FileSystemException {
      // Guard against I/O exceptions.
      return;
    }
  }

  void _addPackageSuggestions(String partial) {
    var factory = request.sourceFactory;
    var packageMap = factory.packageMap;
    if (packageMap != null) {
      _suggestUri('package:');
      packageMap.forEach((pkgName, folders) {
        var prefix = 'package:$pkgName/';
        _suggestUri(prefix);
        for (var folder in folders) {
          if (folder.exists) {
            _addPackageFolderSuggestions(partial, prefix, folder);
          }
        }
      });
    }
  }

  String? _extractPartialUri(SimpleStringLiteral node) {
    if (request.offset < node.contentsOffset) {
      return null;
    }
    return node.literal.lexeme.substring(
      node.contentsOffset - node.offset,
      request.offset - node.offset,
    );
  }

  void _simpleStringLiteral(SimpleStringLiteral node) {
    switch (node.parent) {
      case Configuration():
      case NamespaceDirective():
        var partialUri = _extractPartialUri(node);
        if (partialUri != null) {
          _addDartSuggestions();
          _addPackageSuggestions(partialUri);
          _addFileSuggestions(partialUri);
        }
      case PartDirective():
      case PartOfDirective():
        var partialUri = _extractPartialUri(node);
        if (partialUri != null) {
          _addFileSuggestions(partialUri);
        }
    }
  }

  void _suggestUri(String uriStr) {
    var matcherScore = state.matcher.score(uriStr);
    if (matcherScore != -1) {
      collector.addSuggestion(
        UriSuggestion(uriStr: uriStr, matcherScore: matcherScore),
      );
    }
  }
}
