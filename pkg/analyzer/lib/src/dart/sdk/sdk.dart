// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_engine_io.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:yaml/yaml.dart';

/// An abstract implementation of a Dart SDK in which the available libraries
/// are stored in a library map. Subclasses are responsible for populating the
/// library map.
abstract class AbstractDartSdk implements DartSdk {
  /// The resource provider used to access the file system.
  ResourceProvider resourceProvider;

  /// A mapping from Dart library URI's to the library represented by that URI.
  LibraryMap libraryMap = LibraryMap();

  /// The [AnalysisOptions] to use to create the [context].
  AnalysisOptions _analysisOptions;

  /// The [AnalysisContext] which is used for all of the sources in this SDK.
  SdkAnalysisContext _analysisContext;

  /// The mapping from Dart URI's to the corresponding sources.
  final Map<String, Source> _uriToSourceMap = HashMap<String, Source>();

  /// Return the analysis options for this SDK analysis context.
  AnalysisOptions get analysisOptions => _analysisOptions;

  /// Set the [options] for this SDK analysis context.  Throw [StateError] if
  /// the context has been already created.
  set analysisOptions(AnalysisOptions options) {
    if (_analysisContext != null) {
      throw StateError(
          'Analysis options cannot be changed after context creation.');
    }
    _analysisOptions = options;
  }

  @override
  AnalysisContext get context {
    if (_analysisContext == null) {
      var factory = SourceFactory([DartUriResolver(this)]);
      _analysisContext = SdkAnalysisContext(_analysisOptions, factory);
    }
    return _analysisContext;
  }

  @override
  List<SdkLibrary> get sdkLibraries => libraryMap.sdkLibraries;

  /// Return the path separator used by the resource provider.
  String get separator => resourceProvider.pathContext.separator;

  @override
  List<String> get uris => libraryMap.uris;

  /// Add the extensions from one or more sdk extension files to this sdk. The
  /// [extensions] should be a table mapping the names of extensions to the
  /// paths where those extensions can be found.
  void addExtensions(Map<String, String> extensions) {
    extensions.forEach((String uri, String path) {
      SdkLibraryImpl library = SdkLibraryImpl(uri);
      library.path = path;
      libraryMap.setLibrary(uri, library);
    });
  }

  /// Return info for debugging https://github.com/dart-lang/sdk/issues/35226.
  Map<String, Object> debugInfo() {
    return <String, Object>{
      'runtimeType': '$runtimeType',
      'libraryMap': libraryMap.debugInfo(),
    };
  }

  @override
  Source fromFileUri(Uri uri) {
    File file =
        resourceProvider.getFile(resourceProvider.pathContext.fromUri(uri));
    String path = _getPath(file);
    if (path == null) {
      return null;
    }
    try {
      return file.createSource(Uri.parse(path));
    } on FormatException catch (exception, stackTrace) {
      AnalysisEngine.instance.instrumentationService.logInfo(
          "Failed to create URI: $path",
          CaughtException(exception, stackTrace));
    }
    return null;
  }

  String getRelativePathFromFile(File file);

  @override
  SdkLibrary getSdkLibrary(String dartUri) => libraryMap.getLibrary(dartUri);

  Source internalMapDartUri(String dartUri) {
    // TODO(brianwilkerson) Figure out how to unify the implementations in the
    // two subclasses.
    String libraryName;
    String relativePath;
    int index = dartUri.indexOf('/');
    if (index >= 0) {
      libraryName = dartUri.substring(0, index);
      relativePath = dartUri.substring(index + 1);
    } else {
      libraryName = dartUri;
      relativePath = "";
    }
    SdkLibrary library = getSdkLibrary(libraryName);
    if (library == null) {
      return null;
    }
    String srcPath;
    if (relativePath.isEmpty) {
      srcPath = library.path;
    } else {
      String libraryPath = library.path;
      int index = libraryPath.lastIndexOf(separator);
      if (index == -1) {
        index = libraryPath.lastIndexOf('/');
        if (index == -1) {
          return null;
        }
      }
      String prefix = libraryPath.substring(0, index + 1);
      srcPath = '$prefix$relativePath';
    }
    String filePath = srcPath.replaceAll('/', separator);
    try {
      File file = resourceProvider.getFile(filePath);
      return file.createSource(Uri.parse(dartUri));
    } on FormatException {
      return null;
    }
  }

  @override
  Source mapDartUri(String dartUri) {
    Source source = _uriToSourceMap[dartUri];
    if (source == null) {
      source = internalMapDartUri(dartUri);
      _uriToSourceMap[dartUri] = source;
    }
    return source;
  }

  String _getPath(File file) {
    List<SdkLibrary> libraries = libraryMap.sdkLibraries;
    int length = libraries.length;
    List<String> paths = List(length);
    String filePath = getRelativePathFromFile(file);
    if (filePath == null) {
      return null;
    }
    for (int i = 0; i < length; i++) {
      SdkLibrary library = libraries[i];
      String libraryPath = library.path.replaceAll('/', separator);
      if (filePath == libraryPath) {
        return library.shortName;
      }
      paths[i] = libraryPath;
    }
    for (int i = 0; i < length; i++) {
      SdkLibrary library = libraries[i];
      String libraryPath = paths[i];
      int index = libraryPath.lastIndexOf(separator);
      if (index >= 0) {
        String prefix = libraryPath.substring(0, index + 1);
        if (filePath.startsWith(prefix)) {
          String relPath =
              filePath.substring(prefix.length).replaceAll(separator, '/');
          return '${library.shortName}/$relPath';
        }
      }
    }
    return null;
  }
}

/// An SDK backed by URI mappings derived from an `_embedder.yaml` file.
class EmbedderSdk extends AbstractDartSdk {
  static const String _DART_COLON_PREFIX = 'dart:';

  static const String _EMBEDDED_LIB_MAP_KEY = 'embedded_libs';
  final Map<String, String> _urlMappings = HashMap<String, String>();

  EmbedderSdk(
      ResourceProvider resourceProvider, Map<Folder, YamlMap> embedderYamls) {
    this.resourceProvider = resourceProvider;
    embedderYamls?.forEach(_processEmbedderYaml);
  }

  @override
  String get allowedExperimentsJson {
    var coreSource = mapDartUri('dart:core');
    if (coreSource != null) {
      var coreFile = resourceProvider.getFile(coreSource.fullName);
      var embeddedFolder = coreFile.parent.parent;
      try {
        return embeddedFolder
            .getChildAssumingFolder('_internal')
            .getChildAssumingFile('allowed_experiments.json')
            .readAsStringSync();
      } catch (_) {}
    }
    return null;
  }

  @override
  // TODO(danrubel) Determine SDK version
  String get sdkVersion => '0';

  /// The url mappings for this SDK.
  Map<String, String> get urlMappings => _urlMappings;

  @override
  String getRelativePathFromFile(File file) => file.path;

  @override
  Source internalMapDartUri(String dartUri) {
    String libraryName;
    String relativePath;
    int index = dartUri.indexOf('/');
    if (index >= 0) {
      libraryName = dartUri.substring(0, index);
      relativePath = dartUri.substring(index + 1);
    } else {
      libraryName = dartUri;
      relativePath = "";
    }
    SdkLibrary library = getSdkLibrary(libraryName);
    if (library == null) {
      return null;
    }
    String srcPath;
    if (relativePath.isEmpty) {
      srcPath = library.path;
    } else {
      String libraryPath = library.path;
      int index = libraryPath.lastIndexOf(separator);
      if (index == -1) {
        index = libraryPath.lastIndexOf('/');
        if (index == -1) {
          return null;
        }
      }
      String prefix = libraryPath.substring(0, index + 1);
      srcPath = '$prefix$relativePath';
    }
    String filePath = srcPath.replaceAll('/', separator);
    try {
      File file = resourceProvider.getFile(filePath);
      return file.createSource(Uri.parse(dartUri));
    } on FormatException {
      return null;
    }
  }

  /// Install the mapping from [name] to [libDir]/[file].
  void _processEmbeddedLibs(String name, String file, Folder libDir) {
    if (!name.startsWith(_DART_COLON_PREFIX)) {
      // SDK libraries must begin with 'dart:'.
      return;
    }
    String libPath = libDir.canonicalizePath(file);
    _urlMappings[name] = libPath;
    SdkLibraryImpl library = SdkLibraryImpl(name);
    library.path = libPath;
    libraryMap.setLibrary(name, library);
  }

  /// Given the 'embedderYamls' from [EmbedderYamlLocator] check each one for
  /// the top level key 'embedded_libs'. Under the 'embedded_libs' key are key
  /// value pairs. Each key is a 'dart:' library uri and each value is a path
  /// (relative to the directory containing `_embedder.yaml`) to a dart script
  /// for the given library. For example:
  ///
  /// embedded_libs:
  ///   'dart:io': '../../sdk/io/io.dart'
  ///
  /// If a key doesn't begin with `dart:` it is ignored.
  void _processEmbedderYaml(Folder libDir, YamlMap map) {
    YamlNode embedded_libs = map[_EMBEDDED_LIB_MAP_KEY];
    if (embedded_libs is YamlMap) {
      embedded_libs.forEach((k, v) => _processEmbeddedLibs(k, v, libDir));
    }
  }
}

/// A Dart SDK installed in a specified directory. Typical Dart SDK layout is
/// something like...
///
///     dart-sdk/
///        bin/
///           dart[.exe]  <-- VM
///        lib/
///           core/
///              core.dart
///              ... other core library files ...
///           ... other libraries ...
///        util/
///           ... Dart utilities ...
///     Chromium/   <-- Dartium typically exists in a sibling directory
class FolderBasedDartSdk extends AbstractDartSdk {
  /// The name of the directory within the SDK directory that contains
  /// executables.
  static const String _BIN_DIRECTORY_NAME = "bin";

  /// The name of the directory within the SDK directory that contains
  /// documentation for the libraries.
  static const String _DOCS_DIRECTORY_NAME = "docs";

  /// The name of the directory within the SDK directory that contains the
  /// sdk_library_metadata directory.
  static const String _INTERNAL_DIR = "_internal";

  /// The name of the sdk_library_metadata directory that contains the package
  /// holding the libraries.dart file.
  static const String _SDK_LIBRARY_METADATA_DIR = "sdk_library_metadata";

  /// The name of the directory within the sdk_library_metadata that contains
  /// libraries.dart.
  static const String _SDK_LIBRARY_METADATA_LIB_DIR = "lib";

  /// The name of the directory within the SDK directory that contains the
  /// libraries.
  static const String _LIB_DIRECTORY_NAME = "lib";

  /// The name of the libraries file.
  static const String _LIBRARIES_FILE = "libraries.dart";

  /// The name of the pub executable on windows.
  static const String _PUB_EXECUTABLE_NAME_WIN = "pub.bat";

  /// The name of the pub executable on non-windows operating systems.
  static const String _PUB_EXECUTABLE_NAME = "pub";

  /// The name of the file within the SDK directory that contains the version
  /// number of the SDK.
  static const String _VERSION_FILE_NAME = "version";

  /// The directory containing the SDK.
  final Folder _sdkDirectory;

  /// The directory within the SDK directory that contains the libraries.
  Folder _libraryDirectory;

  /// The revision number of this SDK, or `"0"` if the revision number cannot be
  /// discovered.
  String _sdkVersion;

  /// The file containing the pub executable.
  File _pubExecutable;

  /// Initialize a newly created SDK to represent the Dart SDK installed in the
  /// [sdkDirectory].
  FolderBasedDartSdk(ResourceProvider resourceProvider, Folder sdkDirectory)
      : _sdkDirectory = sdkDirectory {
    this.resourceProvider = resourceProvider;
    libraryMap = initialLibraryMap();
  }

  @override
  String get allowedExperimentsJson {
    try {
      return _sdkDirectory
          .getChildAssumingFolder('lib')
          .getChildAssumingFolder('_internal')
          .getChildAssumingFile('allowed_experiments.json')
          .readAsStringSync();
    } catch (_) {
      return null;
    }
  }

  /// Return the directory containing the SDK.
  Folder get directory => _sdkDirectory;

  /// Return the directory containing documentation for the SDK.
  Folder get docDirectory =>
      _sdkDirectory.getChildAssumingFolder(_DOCS_DIRECTORY_NAME);

  /// Return the directory within the SDK directory that contains the libraries.
  Folder get libraryDirectory {
    return _libraryDirectory ??=
        _sdkDirectory.getChildAssumingFolder(_LIB_DIRECTORY_NAME);
  }

  /// Return the file containing the Pub executable, or `null` if it does not
  /// exist.
  File get pubExecutable {
    return _pubExecutable ??= _sdkDirectory
        .getChildAssumingFolder(_BIN_DIRECTORY_NAME)
        .getChildAssumingFile(OSUtilities.isWindows()
            ? _PUB_EXECUTABLE_NAME_WIN
            : _PUB_EXECUTABLE_NAME);
  }

  /// Return the revision number of this SDK, or `"0"` if the revision number
  /// cannot be discovered.
  @override
  String get sdkVersion {
    if (_sdkVersion == null) {
      _sdkVersion = DartSdk.DEFAULT_VERSION;
      File revisionFile =
          _sdkDirectory.getChildAssumingFile(_VERSION_FILE_NAME);
      try {
        String revision = revisionFile.readAsStringSync();
        if (revision != null) {
          _sdkVersion = revision.trim();
        }
      } on FileSystemException {
        // Fall through to return the default.
      }
    }
    return _sdkVersion;
  }

  /// Determine the search order for trying to locate the [_LIBRARIES_FILE].
  Iterable<File> get _libraryMapLocations sync* {
    yield libraryDirectory
        .getChildAssumingFolder(_INTERNAL_DIR)
        .getChildAssumingFolder(_SDK_LIBRARY_METADATA_DIR)
        .getChildAssumingFolder(_SDK_LIBRARY_METADATA_LIB_DIR)
        .getChildAssumingFile(_LIBRARIES_FILE);
    yield libraryDirectory
        .getChildAssumingFolder(_INTERNAL_DIR)
        .getChildAssumingFile(_LIBRARIES_FILE);
  }

  /// Return info for debugging https://github.com/dart-lang/sdk/issues/35226.
  @override
  Map<String, Object> debugInfo() {
    var result = super.debugInfo();
    result['directory'] = _sdkDirectory.path;
    return result;
  }

  @override
  String getRelativePathFromFile(File file) {
    String filePath = file.path;
    String libPath = libraryDirectory.path;
    if (!filePath.startsWith("$libPath$separator")) {
      return null;
    }
    return filePath.substring(libPath.length + 1);
  }

  /// Read all of the configuration files to initialize the library maps.
  /// Return the initialized library map.
  LibraryMap initialLibraryMap() {
    List<String> searchedPaths = <String>[];
    StackTrace lastStackTrace;
    Object lastException;
    for (File librariesFile in _libraryMapLocations) {
      try {
        String contents = librariesFile.readAsStringSync();
        return SdkLibrariesReader().readFromFile(librariesFile, contents);
      } catch (exception, stackTrace) {
        searchedPaths.add(librariesFile.path);
        lastException = exception;
        lastStackTrace = stackTrace;
      }
    }
    StringBuffer buffer = StringBuffer();
    buffer.writeln('Could not initialize the library map from $searchedPaths');
    if (resourceProvider is MemoryResourceProvider) {
      (resourceProvider as MemoryResourceProvider).writeOn(buffer);
    }
    // TODO(39284): should this exception be silent?
    AnalysisEngine.instance.instrumentationService.logException(
        SilentException(buffer.toString(), lastException, lastStackTrace));
    return LibraryMap();
  }

  @override
  Source internalMapDartUri(String dartUri) {
    String libraryName;
    String relativePath;
    int index = dartUri.indexOf('/');
    if (index >= 0) {
      libraryName = dartUri.substring(0, index);
      relativePath = dartUri.substring(index + 1);
    } else {
      libraryName = dartUri;
      relativePath = "";
    }
    SdkLibrary library = getSdkLibrary(libraryName);
    if (library == null) {
      return null;
    }
    try {
      File file = libraryDirectory.getChildAssumingFile(library.path);
      if (relativePath.isNotEmpty) {
        File relativeFile = file.parent.getChildAssumingFile(relativePath);
        if (relativeFile.path == file.path) {
          // The relative file is the library, so return a Source for the
          // library rather than the part format.
          return file.createSource(Uri.parse(library.shortName));
        }
        file = relativeFile;
      }
      return file.createSource(Uri.parse(dartUri));
    } on FormatException {
      return null;
    }
  }
}

/// An object used to read and parse the libraries file
/// (dart-sdk/lib/_internal/sdk_library_metadata/lib/libraries.dart) for
/// information about the libraries in an SDK. The library information is
/// represented as a Dart file containing a single top-level variable whose
/// value is a const map. The keys of the map are the names of libraries defined
/// in the SDK and the values in the map are info objects defining the library.
/// For example, a subset of a typical SDK might have a libraries file that
/// looks like the following:
///
///     final Map<String, LibraryInfo> LIBRARIES = const <LibraryInfo> {
///       // Used by VM applications
///       "builtin" : const LibraryInfo(
///         "builtin/builtin_runtime.dart",
///         category: "Server",
///         platforms: VM_PLATFORM),
///
///       "compiler" : const LibraryInfo(
///         "compiler/compiler.dart",
///         category: "Tools",
///         platforms: 0),
///     };
class SdkLibrariesReader {
  /// Return the library map read from the given [file], given that the content
  /// of the file is already known to be [libraryFileContents].
  LibraryMap readFromFile(File file, String libraryFileContents) =>
      readFromSource(file.createSource(), libraryFileContents);

  /// Return the library map read from the given [source], given that the
  /// content of the file is already known to be [libraryFileContents].
  LibraryMap readFromSource(Source source, String libraryFileContents) {
    // TODO(paulberry): initialize the feature set appropriately based on the
    // version of the SDK we are reading, and enable flags.
    var featureSet = FeatureSet.fromEnableFlags([]);

    var parseResult = parseString(
      content: libraryFileContents,
      featureSet: featureSet,
      throwIfDiagnostics: false,
    );
    var unit = parseResult.unit;

    var libraryBuilder = SdkLibrariesReader_LibraryBuilder();
    if (parseResult.errors.isEmpty) {
      unit.accept(libraryBuilder);
    }
    return libraryBuilder.librariesMap;
  }
}
