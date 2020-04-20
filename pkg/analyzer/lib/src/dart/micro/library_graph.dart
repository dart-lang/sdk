// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/scanner/token_impl.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/feature_set_provider.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/analysis/unlinked_api_signature.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary/api_signature.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/link.dart' as graph
    show DependencyWalker, Node;
import 'package:analyzer/src/summary2/informative_data.dart';
import 'package:collection/collection.dart';
import 'package:convert/convert.dart';

/// Ensure that the [FileState.libraryCycle] for the [file] and anything it
/// depends on is computed.
void computeLibraryCycle(Uint32List linkedSalt, FileState file) {
  var libraryWalker = _LibraryWalker(linkedSalt);
  libraryWalker.walk(libraryWalker.getNode(file));
}

class FileState {
  final FileSystemState _fsState;

  /**
   * The path of the file.
   */
  final String path;

  /**
   * The URI of the file.
   */
  final Uri uri;

  /**
   * The [Source] of the file with the [uri].
   */
  final Source source;

  final List<FileState> importedFiles = [];
  final List<FileState> exportedFiles = [];
  final List<FileState> partedFiles = [];
  final Set<FileState> directReferencedFiles = Set();
  final Set<FileState> directReferencedLibraries = Set();
  final List<FileState> libraryFiles = [];

  List<int> _digest;
  bool _exists;
  List<int> _apiSignature;
  UnlinkedUnit2 unlinked2;
  LibraryCycle _libraryCycle;

  FileState._(this._fsState, this.path, this.uri, this.source);

  List<int> get apiSignature => _apiSignature;

  List<int> get digest => _digest;

  bool get exists => _exists;

  /// Return the [LibraryCycle] this file belongs to, even if it consists of
  /// just this file.  If the library cycle is not known yet, compute it.
  LibraryCycle get libraryCycle {
    if (_libraryCycle == null) {
      computeLibraryCycle(_fsState._linkedSalt, this);
    }
    return _libraryCycle;
  }

  LineInfo get lineInfo => LineInfo(unlinked2.lineStarts);

  /// Return the [uri] string.
  String get uriStr => uri.toString();

  void internal_setLibraryCycle(LibraryCycle cycle, String signature) {
    _libraryCycle = cycle;
  }

  CompilationUnit parse(AnalysisErrorListener errorListener, String content) {
    AnalysisOptionsImpl analysisOptions = _fsState._analysisOptions;
    FeatureSet featureSet =
        _fsState.featureSetProvider.getFeatureSet(path, uri);

    CharSequenceReader reader = CharSequenceReader(content);
    Scanner scanner = Scanner(source, reader, errorListener)
      ..configureFeatures(featureSet);
    Token token = PerformanceStatistics.scan.makeCurrentWhile(() {
      return scanner.tokenize(reportScannerErrors: false);
    });
    LineInfo lineInfo = LineInfo(scanner.lineStarts);

    bool useFasta = analysisOptions.useFastaParser;
    // Pass the feature set from the scanner to the parser
    // because the scanner may have detected a language version comment
    // and downgraded the feature set it holds.
    Parser parser = Parser(
      source,
      errorListener,
      featureSet: scanner.featureSet,
      useFasta: useFasta,
    );
    parser.enableOptionalNewAndConst = true;
    CompilationUnit unit = parser.parseCompilationUnit(token);
    unit.lineInfo = lineInfo;

    // StringToken uses a static instance of StringCanonicalizer, so we need
    // to clear it explicitly once we are done using it for this file.
    StringToken.canonicalizer.clear();

    return unit;
  }

  void refresh() {
    _digest = utf8.encode(_fsState.getFileDigest(path));
    _exists = _digest.isNotEmpty;
    String unlinkedKey = path;

    // Prepare bytes of the unlinked bundle - existing or new.
    List<int> bytes;
    {
      bytes = _fsState._byteStore.get(unlinkedKey);
      // unlinked summary should be updated if contents have changed, can be
      // seen if file digest has changed.
      if (bytes != null) {
        var ciderUnlinkedUnit = CiderUnlinkedUnit.fromBuffer(bytes);
        if (!const ListEquality()
            .equals(ciderUnlinkedUnit.contentDigest, _digest)) {
          bytes = null;
        }
      }

      if (bytes == null || bytes.isEmpty) {
        String content;
        try {
          content = _fsState._resourceProvider.getFile(path).readAsStringSync();
        } catch (_) {
          content = '';
        }
        var unit = parse(AnalysisErrorListener.NULL_LISTENER, content);
        _fsState._logger.run('Create unlinked for $path', () {
          var unlinkedBuilder = serializeAstCiderUnlinked(_digest, unit);
          bytes = unlinkedBuilder.toBuffer();
          _fsState._byteStore.put(unlinkedKey, bytes);
        });

        unlinked2 = CiderUnlinkedUnit.fromBuffer(bytes).unlinkedUnit;
        _prefetchDirectReferences(unlinked2);
      }
    }

    // Read the unlinked bundle.
    unlinked2 = CiderUnlinkedUnit.fromBuffer(bytes).unlinkedUnit;
    _apiSignature = Uint8List.fromList(unlinked2.apiSignature);

    // Build the graph.
    for (var directive in unlinked2.imports) {
      var file = _fileForRelativeUri(directive.uri);
      importedFiles.add(file);
    }
    for (var directive in unlinked2.exports) {
      var file = _fileForRelativeUri(directive.uri);
      exportedFiles.add(file);
    }
    for (var uri in unlinked2.parts) {
      var file = _fileForRelativeUri(uri);
      partedFiles.add(file);
    }
    libraryFiles.add(this);
    libraryFiles.addAll(partedFiles);

    // Compute referenced files.
    directReferencedFiles
      ..addAll(importedFiles)
      ..addAll(exportedFiles)
      ..addAll(partedFiles);
    directReferencedLibraries..addAll(importedFiles)..addAll(exportedFiles);
  }

  FileState _fileForRelativeUri(String relativeUri) {
    if (relativeUri.isEmpty) {
      return _fsState.unresolvedFile;
    }

    Uri absoluteUri;
    try {
      absoluteUri = resolveRelativeUri(uri, Uri.parse(relativeUri));
    } on FormatException {
      return _fsState.unresolvedFile;
    }

    return _fsState.getFileForUri(absoluteUri);
  }

  void _prefetchDirectReferences(UnlinkedUnit2 unlinkedUnit2) {
    if (_fsState.prefetchFiles == null) {
      return;
    }

    var paths = <String>{};

    void findPathForUri(String relativeUri) {
      if (relativeUri.isEmpty) {
        return;
      }
      Uri absoluteUri;
      try {
        absoluteUri = resolveRelativeUri(uri, Uri.parse(relativeUri));
      } on FormatException {
        return;
      }
      var p = _fsState.getPathForUri(absoluteUri);
      if (p != null) {
        paths.add(p);
      }
    }

    for (var directive in unlinked2.imports) {
      findPathForUri(directive.uri);
    }
    for (var directive in unlinked2.exports) {
      findPathForUri(directive.uri);
    }
    for (var uri in unlinked2.parts) {
      findPathForUri(uri);
    }
    _fsState.prefetchFiles(paths.toList());
  }

  static CiderUnlinkedUnitBuilder serializeAstCiderUnlinked(
      List<int> digest, CompilationUnit unit) {
    var exports = <UnlinkedNamespaceDirectiveBuilder>[];
    var imports = <UnlinkedNamespaceDirectiveBuilder>[];
    var parts = <String>[];
    var hasDartCoreImport = false;
    var hasLibraryDirective = false;
    var hasPartOfDirective = false;
    for (var directive in unit.directives) {
      if (directive is ExportDirective) {
        var builder = _serializeNamespaceDirective(directive);
        exports.add(builder);
      } else if (directive is ImportDirective) {
        var builder = _serializeNamespaceDirective(directive);
        imports.add(builder);
        if (builder.uri == 'dart:core') {
          hasDartCoreImport = true;
        }
      } else if (directive is LibraryDirective) {
        hasLibraryDirective = true;
      } else if (directive is PartDirective) {
        var uriStr = directive.uri.stringValue;
        parts.add(uriStr ?? '');
      } else if (directive is PartOfDirective) {
        hasPartOfDirective = true;
      }
    }
    if (!hasDartCoreImport) {
      imports.add(
        UnlinkedNamespaceDirectiveBuilder(
          uri: 'dart:core',
        ),
      );
    }
    var informativeData = createInformativeData(unit);
    var unlinkedBuilder = UnlinkedUnit2Builder(
      apiSignature: computeUnlinkedApiSignature(unit),
      exports: exports,
      imports: imports,
      parts: parts,
      hasLibraryDirective: hasLibraryDirective,
      hasPartOfDirective: hasPartOfDirective,
      lineStarts: unit.lineInfo.lineStarts,
      informativeData: informativeData,
    );
    return CiderUnlinkedUnitBuilder(
        contentDigest: digest, unlinkedUnit: unlinkedBuilder);
  }

  static UnlinkedNamespaceDirectiveBuilder _serializeNamespaceDirective(
      NamespaceDirective directive) {
    return UnlinkedNamespaceDirectiveBuilder(
      configurations: directive.configurations.map((configuration) {
        var name = configuration.name.components.join('.');
        var value = configuration.value?.stringValue ?? '';
        return UnlinkedNamespaceDirectiveConfigurationBuilder(
          name: name,
          value: value,
          uri: configuration.uri.stringValue ?? '',
        );
      }).toList(),
      uri: directive.uri.stringValue ?? '',
    );
  }
}

class FileSystemState {
  final PerformanceLog _logger;
  final ResourceProvider _resourceProvider;
  final MemoryByteStore _byteStore;
  final SourceFactory _sourceFactory;
  final AnalysisOptions _analysisOptions;
  final Uint32List _linkedSalt;

  /**
   * A function that returns the digest for a file as a String. The function
   * returns a non null value, returns an empty string if file does
   * not exist/has no contents.
   */
  final String Function(String path) getFileDigest;

  final Map<String, FileState> _pathToFile = {};
  final Map<Uri, FileState> _uriToFile = {};

  final FeatureSetProvider featureSetProvider;

  /**
   * A function that fetches the given list of files. This function can be used
   * to batch file reads in systems where file fetches are expensive.
   */
  final void Function(List<String> paths) prefetchFiles;

  /**
   * The [FileState] instance that correspond to an unresolved URI.
   */
  FileState _unresolvedFile;

  FileSystemState(
    this._logger,
    this._resourceProvider,
    this._byteStore,
    this._sourceFactory,
    this._analysisOptions,
    this._linkedSalt,
    this.featureSetProvider,
    this.getFileDigest,
    this.prefetchFiles,
  );

  /**
   * Return the [FileState] instance that correspond to an unresolved URI.
   */
  FileState get unresolvedFile {
    if (_unresolvedFile == null) {
      _unresolvedFile = FileState._(this, null, null, null);
      _unresolvedFile.refresh();
    }
    return _unresolvedFile;
  }

  FileState getFileForPath(String path) {
    var file = _pathToFile[path];
    if (file == null) {
      var fileUri = _resourceProvider.pathContext.toUri(path);
      var uri = _sourceFactory.restoreUri(
        _FakeSource(path, fileUri),
      );

      var source = _sourceFactory.forUri2(uri);
      file = FileState._(this, path, uri, source);

      _pathToFile[path] = file;
      _uriToFile[uri] = file;

      file.refresh();
    }
    return file;
  }

  FileState getFileForUri(Uri uri) {
    FileState file = _uriToFile[uri];
    if (file == null) {
      var source = _sourceFactory.forUri2(uri);
      if (source == null) {
        print('[library_graph] could not create source for $uri');
      }
      var path = source.fullName;

      file = FileState._(this, path, uri, source);
      _pathToFile[path] = file;
      _uriToFile[uri] = file;

      file.refresh();
    }
    return file;
  }

  String getPathForUri(Uri uri) {
    var source = _sourceFactory.forUri2(uri);
    if (source == null) {
      return null;
    }
    return source.fullName;
  }
}

/// Information about libraries that reference each other, so form a cycle.
class LibraryCycle {
  /// The libraries that belong to this cycle.
  final List<FileState> libraries = [];

  /// The library cycles that this cycle references directly.
  final Set<LibraryCycle> directDependencies = Set<LibraryCycle>();

  /// The transitive signature of this cycle.
  ///
  /// It is based on the API signatures of all files of the [libraries], and
  /// the signatures of the cycles that the [libraries] reference
  /// directly.  So, indirectly it is based on the transitive closure of all
  /// files that [libraries] reference (but we don't compute these files).
  List<int> signature;

  /// The hash of all the paths of the files in this cycle.
  String cyclePathsHash;

  LibraryCycle();

  String get signatureStr {
    return hex.encode(signature);
  }

  @override
  String toString() {
    return '[' + libraries.join(', ') + ']';
  }
}

class _FakeSource implements Source {
  @override
  final String fullName;

  @override
  final Uri uri;

  _FakeSource(this.fullName, this.uri);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Node in [_LibraryWalker].
class _LibraryNode extends graph.Node<_LibraryNode> {
  final _LibraryWalker walker;
  final FileState file;

  _LibraryNode(this.walker, this.file);

  @override
  bool get isEvaluated => file._libraryCycle != null;

  @override
  List<_LibraryNode> computeDependencies() {
    return file.directReferencedLibraries.map(walker.getNode).toList();
  }
}

/// Helper that organizes dependencies of a library into topologically
/// sorted [LibraryCycle]s.
class _LibraryWalker extends graph.DependencyWalker<_LibraryNode> {
  final Uint32List _linkedSalt;
  final Map<FileState, _LibraryNode> nodesOfFiles = {};

  _LibraryWalker(this._linkedSalt);

  @override
  void evaluate(_LibraryNode v) {
    evaluateScc([v]);
  }

  @override
  void evaluateScc(List<_LibraryNode> scc) {
    var cycle = LibraryCycle();

    var signature = ApiSignature();
    signature.addUint32List(_linkedSalt);

    // Sort libraries to produce stable signatures.
    scc.sort((first, second) {
      var firstPath = first.file.path;
      var secondPath = second.file.path;
      return firstPath.compareTo(secondPath);
    });

    // Append direct referenced cycles.
    for (var node in scc) {
      var file = node.file;
      _appendDirectlyReferenced(cycle, signature, file.importedFiles);
      _appendDirectlyReferenced(cycle, signature, file.exportedFiles);
    }

    // Fill the cycle with libraries.
    for (var node in scc) {
      cycle.libraries.add(node.file);

      signature.addString(node.file.uriStr);

      signature.addInt(node.file.libraryFiles.length);
      for (var file in node.file.libraryFiles) {
        signature.addBool(file.exists);
        signature.addBytes(file.apiSignature);
      }
    }

    // Compute the general library cycle signature.
    cycle.signature = signature.toByteList();

    // Compute the cycle file paths signature.
    var filePathsSignature = ApiSignature();
    for (var node in scc) {
      filePathsSignature.addString(node.file.path);
    }
    cycle.cyclePathsHash = filePathsSignature.toHex();

    // Compute library specific signatures.
    for (var node in scc) {
      var librarySignatureBuilder = ApiSignature()
        ..addString(node.file.uriStr)
        ..addBytes(cycle.signature);
      var librarySignature = librarySignatureBuilder.toHex();

      node.file.internal_setLibraryCycle(
        cycle,
        librarySignature,
      );
    }
  }

  _LibraryNode getNode(FileState file) {
    return nodesOfFiles.putIfAbsent(file, () => _LibraryNode(this, file));
  }

  void _appendDirectlyReferenced(
    LibraryCycle cycle,
    ApiSignature signature,
    List<FileState> directlyReferenced,
  ) {
    signature.addInt(directlyReferenced.length);
    for (var referencedLibrary in directlyReferenced) {
      var referencedCycle = referencedLibrary._libraryCycle;
      // We get null when the library is a part of the cycle being build.
      if (referencedCycle == null) continue;

      if (cycle.directDependencies.add(referencedCycle)) {
        signature.addBytes(referencedCycle.signature);
      }
    }
  }
}
