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
 * specified directory.
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
   * The file containing the Dartium executable.
   */
  JavaFile _dartiumExecutable;

  /**
   * The file containing the VM executable.
   */
  JavaFile _vmExecutable;

  /**
   * A mapping from Dart library URI's to the library represented by that URI.
   */
  LibraryMap _libraryMap;

  /**
   * The name of the directory within the SDK directory that contains executables.
   */
  static String _BIN_DIRECTORY_NAME = "bin";

  /**
   * The name of the directory within the SDK directory that contains Chromium.
   */
  static String _CHROMIUM_DIRECTORY_NAME = "chromium";

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
   * The name of the file within the SDK directory that contains the revision number of the SDK.
   */
  static String _REVISION_FILE_NAME = "revision";

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
    JavaFile sdkDirectory = defaultSdkDirectory;
    if (sdkDirectory == null) {
      return null;
    }
    return new DirectoryBasedDartSdk(sdkDirectory);
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
   */
  DirectoryBasedDartSdk(JavaFile sdkDirectory) : this.con1(sdkDirectory, false);

  /**
   * Initialize a newly created SDK to represent the Dart SDK installed in the given directory.
   *
   * @param sdkDirectory the directory containing the SDK
   * @param useDart2jsPaths `true` if the dart2js path should be used when it is available
   */
  DirectoryBasedDartSdk.con1(JavaFile sdkDirectory, bool useDart2jsPaths) {
    this._sdkDirectory = sdkDirectory.getAbsoluteFile();
    initializeSdk();
    initializeLibraryMap(useDart2jsPaths);
    _analysisContext = new AnalysisContextImpl();
    _analysisContext.sourceFactory = new SourceFactory([new DartUriResolver(this)]);
    List<String> uris = this.uris;
    ChangeSet changeSet = new ChangeSet();
    for (String uri in uris) {
      changeSet.added(_analysisContext.sourceFactory.forUri(uri));
    }
    _analysisContext.applyChanges(changeSet);
  }

  Source fromEncoding(UriKind kind, Uri uri) => new FileBasedSource.con2(new JavaFile.fromUri(uri), kind);

  AnalysisContext get context => _analysisContext;

  /**
   * Return the file containing the Dartium executable, or `null` if it does not exist.
   *
   * @return the file containing the Dartium executable
   */
  JavaFile get dartiumExecutable {
    if (_dartiumExecutable == null) {
      JavaFile file = new JavaFile.relative(dartiumWorkingDirectory, dartiumBinaryName);
      if (file.exists()) {
        _dartiumExecutable = file;
      }
    }
    return _dartiumExecutable;
  }

  /**
   * Return the directory where dartium can be found in the Dart SDK (the directory that will be the
   * working directory is Dartium is invoked without changing the default).
   *
   * @return the directory where dartium can be found
   */
  JavaFile get dartiumWorkingDirectory => new JavaFile.relative(_sdkDirectory.getParentFile(), _CHROMIUM_DIRECTORY_NAME);

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
    String pubBinaryName = OSUtilities.isWindows() ? _PUB_EXECUTABLE_NAME_WIN : _PUB_EXECUTABLE_NAME;
    JavaFile file = new JavaFile.relative(new JavaFile.relative(_sdkDirectory, _BIN_DIRECTORY_NAME), pubBinaryName);
    return file.exists() ? file : null;
  }

  List<SdkLibrary> get sdkLibraries => _libraryMap.sdkLibraries;

  SdkLibrary getSdkLibrary(String dartUri) => _libraryMap.getLibrary(dartUri);

  /**
   * Return the revision number of this SDK, or `"0"` if the revision number cannot be
   * discovered.
   *
   * @return the revision number of this SDK
   */
  String get sdkVersion {
    if (_sdkVersion == null) {
      _sdkVersion = DartSdk.DEFAULT_VERSION;
      JavaFile revisionFile = new JavaFile.relative(_sdkDirectory, _REVISION_FILE_NAME);
      try {
        String revision = revisionFile.readAsStringSync();
        if (revision != null) {
          _sdkVersion = revision;
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
  List<String> get uris => _libraryMap.uris;

  /**
   * Return the file containing the VM executable, or `null` if it does not exist.
   *
   * @return the file containing the VM executable
   */
  JavaFile get vmExecutable {
    if (_vmExecutable == null) {
      JavaFile file = new JavaFile.relative(new JavaFile.relative(_sdkDirectory, _BIN_DIRECTORY_NAME), vmBinaryName);
      if (file.exists()) {
        _vmExecutable = file;
      }
    }
    return _vmExecutable;
  }

  /**
   * Return `true` if this SDK includes documentation.
   *
   * @return `true` if this installation of the SDK has documentation
   */
  bool hasDocumentation() => docDirectory.exists();

  /**
   * Return `true` if the Dartium binary is available.
   *
   * @return `true` if the Dartium binary is available
   */
  bool get isDartiumInstalled => dartiumExecutable != null;

  Source mapDartUri(String dartUri) {
    SdkLibrary library = getSdkLibrary(dartUri);
    if (library == null) {
      return null;
    }
    return new FileBasedSource.con2(new JavaFile.relative(libraryDirectory, library.path), UriKind.DART_URI);
  }

  /**
   * Ensure that the dart VM is executable. If it is not, make it executable and log that it was
   * necessary for us to do so.
   */
  void ensureVmIsExecutable() {
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
   * Read all of the configuration files to initialize the library maps.
   *
   * @param useDart2jsPaths `true` if the dart2js path should be used when it is available
   */
  void initializeLibraryMap(bool useDart2jsPaths) {
    JavaFile librariesFile = new JavaFile.relative(new JavaFile.relative(libraryDirectory, _INTERNAL_DIR), _LIBRARIES_FILE);
    try {
      String contents = librariesFile.readAsStringSync();
      _libraryMap = new SdkLibrariesReader(useDart2jsPaths).readFrom(librariesFile, contents);
    } on JavaException catch (exception) {
      AnalysisEngine.instance.logger.logError2("Could not initialize the library map from ${librariesFile.getAbsolutePath()}", exception);
      _libraryMap = new LibraryMap();
    }
  }

  /**
   * Initialize the state of the SDK.
   */
  void initializeSdk() {
    if (!OSUtilities.isWindows()) {
      ensureVmIsExecutable();
    }
  }
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
  bool _useDart2jsPaths = false;

  /**
   * Initialize a newly created library reader to use the dart2js path if the given value is
   * `true`.
   *
   * @param useDart2jsPaths `true` if the dart2js path should be used when it is available
   */
  SdkLibrariesReader(bool useDart2jsPaths) {
    this._useDart2jsPaths = useDart2jsPaths;
  }

  /**
   * Return the library map read from the given source.
   *
   * @param file the [File] of the library file
   * @param libraryFileContents the contents from the library file
   * @return the library map read from the given source
   */
  LibraryMap readFrom(JavaFile file, String libraryFileContents) => readFrom2(new FileBasedSource.con2(file, UriKind.FILE_URI), libraryFileContents);

  /**
   * Return the library map read from the given source.
   *
   * @param source the source of the library file
   * @param libraryFileContents the contents from the library file
   * @return the library map read from the given source
   */
  LibraryMap readFrom2(Source source, String libraryFileContents) {
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