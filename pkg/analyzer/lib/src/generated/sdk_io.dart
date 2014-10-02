// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.sdk.io;

import 'java_core.dart';
import 'java_io.dart';
import 'java_engine_io.dart';
import 'source_io.dart';
import 'error.dart';
import 'scanner.dart';
import 'ast.dart';
import 'parser.dart';
import 'sdk.dart';
import 'engine.dart';

/**
 * Instances of the class `DirectoryBasedDartSdk` represent a Dart SDK installed in a
 * specified directory. Typical Dart SDK layout is something like...
 *
 * <pre>
 *    dart-sdk/
 *       bin/
 *          dart[.exe]  <-- VM
 *       lib/
 *          core/
 *             core.dart
 *             ... other core library files ...
 *          ... other libraries ...
 *       util/
 *          ... Dart utilities ...
 *    Chromium/   <-- Dartium typically exists in a sibling directory
 * </pre>
 */
class DirectoryBasedDartSdk implements DartSdk {
  /**
   * The [AnalysisContext] which is used for all of the sources in this [DartSdk].
   */
  InternalAnalysisContext _analysisContext;

  /**
   * The directory containing the SDK.
   */
  JavaFile _sdkDirectory;

  /**
   * The revision number of this SDK, or `"0"` if the revision number cannot be discovered.
   */
  String _sdkVersion;

  /**
   * The file containing the dart2js executable.
   */
  JavaFile _dart2jsExecutable;

  /**
   * The file containing the dart formatter executable.
   */
  JavaFile _dartFmtExecutable;

  /**
   * The file containing the Dartium executable.
   */
  JavaFile _dartiumExecutable;

  /**
   * The file containing the pub executable.
   */
  JavaFile _pubExecutable;

  /**
   * The file containing the VM executable.
   */
  JavaFile _vmExecutable;

  /**
   * A mapping from Dart library URI's to the library represented by that URI.
   */
  LibraryMap _libraryMap;

  /**
   * The default SDK, or `null` if the default SDK either has not yet been created or cannot
   * be created for some reason.
   */
  static DirectoryBasedDartSdk _DEFAULT_SDK;

  /**
   * The name of the directory within the SDK directory that contains executables.
   */
  static String _BIN_DIRECTORY_NAME = "bin";

  /**
   * The name of the directory on non-Mac that contains dartium.
   */
  static String _DARTIUM_DIRECTORY_NAME = "chromium";

  /**
   * The name of the dart2js executable on non-windows operating systems.
   */
  static String _DART2JS_EXECUTABLE_NAME = "dart2js";

  /**
   * The name of the file containing the dart2js executable on Windows.
   */
  static String _DART2JS_EXECUTABLE_NAME_WIN = "dart2js.bat";

  /**
   * The name of the dart formatter executable on non-windows operating systems.
   */
  static String _DARTFMT_EXECUTABLE_NAME = "dartfmt";

  /**
   * The name of the dart formatter executable on windows operating systems.
   */
  static String _DARTFMT_EXECUTABLE_NAME_WIN = "dartfmt.bat";

  /**
   * The name of the file containing the Dartium executable on Linux.
   */
  static String _DARTIUM_EXECUTABLE_NAME_LINUX = "chrome";

  /**
   * The name of the file containing the Dartium executable on Macintosh.
   */
  static String _DARTIUM_EXECUTABLE_NAME_MAC = "Chromium.app/Contents/MacOS/Chromium";

  /**
   * The name of the file containing the Dartium executable on Windows.
   */
  static String _DARTIUM_EXECUTABLE_NAME_WIN = "Chrome.exe";

  /**
   * The name of the [System] property whose value is the path to the default Dart SDK
   * directory.
   */
  static String _DEFAULT_DIRECTORY_PROPERTY_NAME = "com.google.dart.sdk";

  /**
   * The name of the directory within the SDK directory that contains documentation for the
   * libraries.
   */
  static String _DOCS_DIRECTORY_NAME = "docs";

  /**
   * The suffix added to the name of a library to derive the name of the file containing the
   * documentation for that library.
   */
  static String _DOC_FILE_SUFFIX = "_api.json";

  /**
   * The name of the directory within the SDK directory that contains the libraries file.
   */
  static String _INTERNAL_DIR = "_internal";

  /**
   * The name of the directory within the SDK directory that contains the libraries.
   */
  static String _LIB_DIRECTORY_NAME = "lib";

  /**
   * The name of the libraries file.
   */
  static String _LIBRARIES_FILE = "libraries.dart";

  /**
   * The name of the pub executable on windows.
   */
  static String _PUB_EXECUTABLE_NAME_WIN = "pub.bat";

  /**
   * The name of the pub executable on non-windows operating systems.
   */
  static String _PUB_EXECUTABLE_NAME = "pub";

  /**
   * The name of the file within the SDK directory that contains the version number of the SDK.
   */
  static String _VERSION_FILE_NAME = "version";

  /**
   * The name of the file containing the VM executable on the Windows operating system.
   */
  static String _VM_EXECUTABLE_NAME_WIN = "dart.exe";

  /**
   * The name of the file containing the VM executable on non-Windows operating systems.
   */
  static String _VM_EXECUTABLE_NAME = "dart";

  /**
   * Return the default Dart SDK, or `null` if the directory containing the default SDK cannot
   * be determined (or does not exist).
   *
   * @return the default Dart SDK
   */
  static DirectoryBasedDartSdk get defaultSdk {
    if (_DEFAULT_SDK == null) {
      JavaFile sdkDirectory = defaultSdkDirectory;
      if (sdkDirectory == null) {
        return null;
      }
      _DEFAULT_SDK = new DirectoryBasedDartSdk(sdkDirectory);
    }
    return _DEFAULT_SDK;
  }

  /**
   * Return the default directory for the Dart SDK, or `null` if the directory cannot be
   * determined (or does not exist). The default directory is provided by a [System] property
   * named `com.google.dart.sdk`.
   *
   * @return the default directory for the Dart SDK
   */
  static JavaFile get defaultSdkDirectory {
    String sdkProperty = JavaSystemIO.getProperty(_DEFAULT_DIRECTORY_PROPERTY_NAME);
    if (sdkProperty == null) {
      return null;
    }
    JavaFile sdkDirectory = new JavaFile(sdkProperty);
    if (!sdkDirectory.exists()) {
      return null;
    }
    return sdkDirectory;
  }

  /**
   * Initialize a newly created SDK to represent the Dart SDK installed in the given directory.
   *
   * @param sdkDirectory the directory containing the SDK
   * @param useDart2jsPaths `true` if the dart2js path should be used when it is available
   */
  DirectoryBasedDartSdk(JavaFile sdkDirectory, [bool useDart2jsPaths = false]) {
    this._sdkDirectory = sdkDirectory.getAbsoluteFile();
    _libraryMap = initialLibraryMap(useDart2jsPaths);
  }

  @override
  Source fromFileUri(Uri uri) {
    JavaFile file = new JavaFile.fromUri(uri);
    String filePath = file.getAbsolutePath();
    String libPath = libraryDirectory.getAbsolutePath();
    if (!filePath.startsWith("${libPath}${JavaFile.separator}")) {
      return null;
    }
    filePath = filePath.substring(libPath.length + 1);
    for (SdkLibrary library in _libraryMap.sdkLibraries) {
      String libraryPath = library.path;
      if (filePath.replaceAll('\\', '/') == libraryPath) {
        String path = library.shortName;
        try {
          return new FileBasedSource.con2(parseUriWithException(path), file);
        } on URISyntaxException catch (exception) {
          AnalysisEngine.instance.logger.logInformation2("Failed to create URI: ${path}", exception);
          return null;
        }
      }
      libraryPath = new JavaFile(libraryPath).getParent();
      if (filePath.startsWith("${libraryPath}${JavaFile.separator}")) {
        String path = "${library.shortName}/${filePath.substring(libraryPath.length + 1)}";
        try {
          return new FileBasedSource.con2(parseUriWithException(path), file);
        } on URISyntaxException catch (exception) {
          AnalysisEngine.instance.logger.logInformation2("Failed to create URI: ${path}", exception);
          return null;
        }
      }
    }
    return null;
  }

  @override
  AnalysisContext get context {
    if (_analysisContext == null) {
      _analysisContext = new SdkAnalysisContext();
      SourceFactory factory = new SourceFactory([new DartUriResolver(this)]);
      _analysisContext.sourceFactory = factory;
      List<String> uris = this.uris;
      ChangeSet changeSet = new ChangeSet();
      for (String uri in uris) {
        changeSet.addedSource(factory.forUri(uri));
      }
      _analysisContext.applyChanges(changeSet);
    }
    return _analysisContext;
  }

  /**
   * Return the file containing the dart2js executable, or `null` if it does not exist.
   *
   * @return the file containing the dart2js executable
   */
  JavaFile get dart2JsExecutable {
    if (_dart2jsExecutable == null) {
      _dart2jsExecutable = _verifyExecutable(new JavaFile.relative(new JavaFile.relative(_sdkDirectory, _BIN_DIRECTORY_NAME), OSUtilities.isWindows() ? _DART2JS_EXECUTABLE_NAME_WIN : _DART2JS_EXECUTABLE_NAME));
    }
    return _dart2jsExecutable;
  }

  /**
   * Return the file containing the dart formatter executable, or `null` if it does not exist.
   *
   * @return the file containing the dart formatter executable
   */
  JavaFile get dartFmtExecutable {
    if (_dartFmtExecutable == null) {
      _dartFmtExecutable = _verifyExecutable(new JavaFile.relative(new JavaFile.relative(_sdkDirectory, _BIN_DIRECTORY_NAME), OSUtilities.isWindows() ? _DARTFMT_EXECUTABLE_NAME_WIN : _DARTFMT_EXECUTABLE_NAME));
    }
    return _dartFmtExecutable;
  }

  /**
   * Return the file containing the Dartium executable, or `null` if it does not exist.
   *
   * @return the file containing the Dartium executable
   */
  JavaFile get dartiumExecutable {
    if (_dartiumExecutable == null) {
      _dartiumExecutable = _verifyExecutable(new JavaFile.relative(dartiumWorkingDirectory, dartiumBinaryName));
    }
    return _dartiumExecutable;
  }

  /**
   * Return the directory where dartium can be found (the directory that will be the working
   * directory is Dartium is invoked without changing the default).
   *
   * @return the directory where dartium can be found
   */
  JavaFile get dartiumWorkingDirectory => getDartiumWorkingDirectory(_sdkDirectory.getParentFile());

  /**
   * Return the directory where dartium can be found (the directory that will be the working
   * directory is Dartium is invoked without changing the default).
   *
   * @param installDir the installation directory
   * @return the directory where dartium can be found
   */
  JavaFile getDartiumWorkingDirectory(JavaFile installDir) => new JavaFile.relative(installDir, _DARTIUM_DIRECTORY_NAME);

  /**
   * Return the directory containing the SDK.
   *
   * @return the directory containing the SDK
   */
  JavaFile get directory => _sdkDirectory;

  /**
   * Return the directory containing documentation for the SDK.
   *
   * @return the SDK's documentation directory
   */
  JavaFile get docDirectory => new JavaFile.relative(_sdkDirectory, _DOCS_DIRECTORY_NAME);

  /**
   * Return the auxiliary documentation file for the given library, or `null` if no such file
   * exists.
   *
   * @param libraryName the name of the library associated with the documentation file to be
   *          returned
   * @return the auxiliary documentation file for the library
   */
  JavaFile getDocFileFor(String libraryName) {
    JavaFile dir = docDirectory;
    if (!dir.exists()) {
      return null;
    }
    JavaFile libDir = new JavaFile.relative(dir, libraryName);
    JavaFile docFile = new JavaFile.relative(libDir, "${libraryName}${_DOC_FILE_SUFFIX}");
    if (docFile.exists()) {
      return docFile;
    }
    return null;
  }

  /**
   * Return the directory within the SDK directory that contains the libraries.
   *
   * @return the directory that contains the libraries
   */
  JavaFile get libraryDirectory => new JavaFile.relative(_sdkDirectory, _LIB_DIRECTORY_NAME);

  /**
   * Return the file containing the Pub executable, or `null` if it does not exist.
   *
   * @return the file containing the Pub executable
   */
  JavaFile get pubExecutable {
    if (_pubExecutable == null) {
      _pubExecutable = _verifyExecutable(new JavaFile.relative(new JavaFile.relative(_sdkDirectory, _BIN_DIRECTORY_NAME), OSUtilities.isWindows() ? _PUB_EXECUTABLE_NAME_WIN : _PUB_EXECUTABLE_NAME));
    }
    return _pubExecutable;
  }

  @override
  List<SdkLibrary> get sdkLibraries => _libraryMap.sdkLibraries;

  @override
  SdkLibrary getSdkLibrary(String dartUri) => _libraryMap.getLibrary(dartUri);

  /**
   * Return the revision number of this SDK, or `"0"` if the revision number cannot be
   * discovered.
   *
   * @return the revision number of this SDK
   */
  @override
  String get sdkVersion {
    if (_sdkVersion == null) {
      _sdkVersion = DartSdk.DEFAULT_VERSION;
      JavaFile revisionFile = new JavaFile.relative(_sdkDirectory, _VERSION_FILE_NAME);
      try {
        String revision = revisionFile.readAsStringSync();
        if (revision != null) {
          _sdkVersion = revision.trim();
        }
      } on JavaIOException catch (exception) {
      }
    }
    return _sdkVersion;
  }

  /**
   * Return an array containing the library URI's for the libraries defined in this SDK.
   *
   * @return the library URI's for the libraries defined in this SDK
   */
  @override
  List<String> get uris => _libraryMap.uris;

  /**
   * Return the file containing the VM executable, or `null` if it does not exist.
   *
   * @return the file containing the VM executable
   */
  JavaFile get vmExecutable {
    if (_vmExecutable == null) {
      _vmExecutable = _verifyExecutable(new JavaFile.relative(new JavaFile.relative(_sdkDirectory, _BIN_DIRECTORY_NAME), vmBinaryName));
    }
    return _vmExecutable;
  }

  /**
   * Return `true` if this SDK includes documentation.
   *
   * @return `true` if this installation of the SDK has documentation
   */
  bool get hasDocumentation => docDirectory.exists();

  /**
   * Return `true` if the Dartium binary is available.
   *
   * @return `true` if the Dartium binary is available
   */
  bool get isDartiumInstalled => dartiumExecutable != null;

  @override
  Source mapDartUri(String dartUri) {
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
      JavaFile file = new JavaFile.relative(libraryDirectory, library.path);
      if (!relativePath.isEmpty) {
        file = file.getParentFile();
        file = new JavaFile.relative(file, relativePath);
      }
      return new FileBasedSource.con2(parseUriWithException(dartUri), file);
    } on URISyntaxException catch (exception) {
      return null;
    }
  }

  /**
   * Read all of the configuration files to initialize the library maps.
   *
   * @param useDart2jsPaths `true` if the dart2js path should be used when it is available
   * @return the initialized library map
   */
  LibraryMap initialLibraryMap(bool useDart2jsPaths) {
    JavaFile librariesFile = new JavaFile.relative(new JavaFile.relative(libraryDirectory, _INTERNAL_DIR), _LIBRARIES_FILE);
    try {
      String contents = librariesFile.readAsStringSync();
      return new SdkLibrariesReader(useDart2jsPaths).readFromFile(librariesFile, contents);
    } catch (exception) {
      AnalysisEngine.instance.logger.logError2("Could not initialize the library map from ${librariesFile.getAbsolutePath()}", exception);
      return new LibraryMap();
    }
  }

  /**
   * Ensure that the dart VM is executable. If it is not, make it executable and log that it was
   * necessary for us to do so.
   */
  void _ensureVmIsExecutable() {
  }

  /**
   * Return the name of the file containing the Dartium executable.
   *
   * @return the name of the file containing the Dartium executable
   */
  String get dartiumBinaryName {
    if (OSUtilities.isWindows()) {
      return _DARTIUM_EXECUTABLE_NAME_WIN;
    } else if (OSUtilities.isMac()) {
      return _DARTIUM_EXECUTABLE_NAME_MAC;
    } else {
      return _DARTIUM_EXECUTABLE_NAME_LINUX;
    }
  }

  /**
   * Return the name of the file containing the VM executable.
   *
   * @return the name of the file containing the VM executable
   */
  String get vmBinaryName {
    if (OSUtilities.isWindows()) {
      return _VM_EXECUTABLE_NAME_WIN;
    } else {
      return _VM_EXECUTABLE_NAME;
    }
  }

  /**
   * Verify that the given executable file exists and is executable.
   *
   * @param file the binary file
   * @return the file if it exists and is executable, else `null`
   */
  JavaFile _verifyExecutable(JavaFile file) => file.isExecutable() ? file : null;
}

/**
 * Instances of the class `SdkLibrariesReader` read and parse the libraries file
 * (dart-sdk/lib/_internal/libraries.dart) for information about the libraries in an SDK. The
 * library information is represented as a Dart file containing a single top-level variable whose
 * value is a const map. The keys of the map are the names of libraries defined in the SDK and the
 * values in the map are info objects defining the library. For example, a subset of a typical SDK
 * might have a libraries file that looks like the following:
 *
 * <pre>
 * final Map&lt;String, LibraryInfo&gt; LIBRARIES = const &lt;LibraryInfo&gt; {
 *   // Used by VM applications
 *   "builtin" : const LibraryInfo(
 *     "builtin/builtin_runtime.dart",
 *     category: "Server",
 *     platforms: VM_PLATFORM),
 *
 *   "compiler" : const LibraryInfo(
 *     "compiler/compiler.dart",
 *     category: "Tools",
 *     platforms: 0),
 * };
 * </pre>
 */
class SdkLibrariesReader {
  /**
   * A flag indicating whether the dart2js path should be used when it is available.
   */
  final bool _useDart2jsPaths;

  /**
   * Initialize a newly created library reader to use the dart2js path if the given value is
   * `true`.
   *
   * @param useDart2jsPaths `true` if the dart2js path should be used when it is available
   */
  SdkLibrariesReader(this._useDart2jsPaths);

  /**
   * Return the library map read from the given source.
   *
   * @param file the [File] of the library file
   * @param libraryFileContents the contents from the library file
   * @return the library map read from the given source
   */
  LibraryMap readFromFile(JavaFile file, String libraryFileContents) => readFromSource(new FileBasedSource.con1(file), libraryFileContents);

  /**
   * Return the library map read from the given source.
   *
   * @param source the source of the library file
   * @param libraryFileContents the contents from the library file
   * @return the library map read from the given source
   */
  LibraryMap readFromSource(Source source, String libraryFileContents) {
    BooleanErrorListener errorListener = new BooleanErrorListener();
    Scanner scanner = new Scanner(source, new CharSequenceReader(libraryFileContents), errorListener);
    Parser parser = new Parser(source, errorListener);
    CompilationUnit unit = parser.parseCompilationUnit(scanner.tokenize());
    SdkLibrariesReader_LibraryBuilder libraryBuilder = new SdkLibrariesReader_LibraryBuilder(_useDart2jsPaths);
    // If any syntactic errors were found then don't try to visit the AST structure.
    if (!errorListener.errorReported) {
      unit.accept(libraryBuilder);
    }
    return libraryBuilder.librariesMap;
  }
}