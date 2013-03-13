// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.sdk;

import 'dart:io';
import 'dart:uri';
import 'java_core.dart';
import 'java_io.dart';
import 'java_engine.dart';
import 'java_engine_io.dart';
import 'package:analyzer_experimental/src/generated/source_io.dart';
import 'package:analyzer_experimental/src/generated/error.dart';
import 'package:analyzer_experimental/src/generated/scanner.dart';
import 'package:analyzer_experimental/src/generated/parser.dart';
import 'package:analyzer_experimental/src/generated/ast.dart';
import 'package:analyzer_experimental/src/generated/engine.dart' show AnalysisEngine;

/**
 * Represents a single library in the SDK
 */
abstract class SdkLibrary {
  /**
   * Return the name of the category containing the library.
   * @return the name of the category containing the library
   */
  String get category;
  /**
   * Return the path to the file defining the library. The path is relative to the {@code lib}directory within the SDK.
   * @return the path to the file defining the library
   */
  String get path;
  /**
   * Return the short name of the library. This is the name used after {@code dart:} in a URI.
   * @return the short name of the library
   */
  String get shortName;
  /**
   * Return {@code true} if this library can be compiled to JavaScript by dart2js.
   * @return {@code true} if this library can be compiled to JavaScript by dart2js
   */
  bool isDart2JsLibrary();
  /**
   * Return {@code true} if the library is documented.
   * @return {@code true} if the library is documented
   */
  bool isDocumented();
  /**
   * Return {@code true} if the library is an implementation library.
   * @return {@code true} if the library is an implementation library
   */
  bool isImplementation();
  /**
   * Return {@code true} if library can be used for both client and server.
   * @return {@code true} if this library can be used for both client and server.
   */
  bool isShared();
  /**
   * Return {@code true} if this library can be run on the VM.
   * @return {@code true} if this library can be run on the VM
   */
  bool isVmLibrary();
}
/**
 * Instances of the class {@code SdkLibrary} represent the information known about a single library
 * within the SDK.
 * @coverage dart.engine.sdk
 */
class SdkLibraryImpl implements SdkLibrary {
  /**
   * The short name of the library. This is the name used after {@code dart:} in a URI.
   */
  String _shortName = null;
  /**
   * The path to the file defining the library. The path is relative to the {@code lib} directory
   * within the SDK.
   */
  String _path = null;
  /**
   * The name of the category containing the library. Unless otherwise specified in the libraries
   * file all libraries are assumed to be shared between server and client.
   */
  String _category = "Shared";
  /**
   * A flag indicating whether the library is documented.
   */
  bool _documented = true;
  /**
   * A flag indicating whether the library is an implementation library.
   */
  bool _implementation = false;
  /**
   * An encoding of which platforms this library is intended to work on.
   */
  int _platforms = 0;
  /**
   * The bit mask used to access the bit representing the flag indicating whether a library is
   * intended to work on the dart2js platform.
   */
  static int DART2JS_PLATFORM = 1;
  /**
   * The bit mask used to access the bit representing the flag indicating whether a library is
   * intended to work on the VM platform.
   */
  static int VM_PLATFORM = 2;
  /**
   * Initialize a newly created library to represent the library with the given name.
   * @param name the short name of the library
   */
  SdkLibraryImpl(String name) {
    this._shortName = name;
  }
  String get category => _category;
  String get path => _path;
  String get shortName => _shortName;
  bool isDart2JsLibrary() => (_platforms & DART2JS_PLATFORM) != 0;
  bool isDocumented() => _documented;
  bool isImplementation() => _implementation;
  /**
   * Return {@code true} if library can be used for both client and server
   */
  bool isShared() => _category == "Shared";
  /**
   * Return {@code true} if this library can be run on the VM.
   * @return {@code true} if this library can be run on the VM
   */
  bool isVmLibrary() => (_platforms & VM_PLATFORM) != 0;
  /**
   * Set the name of the category containing the library to the given name.
   * @param category the name of the category containing the library
   */
  void set category(String category2) {
    this._category = category2;
  }
  /**
   * Record that this library can be compiled to JavaScript by dart2js.
   */
  void setDart2JsLibrary() {
    _platforms |= DART2JS_PLATFORM;
  }
  /**
   * Set whether the library is documented to match the given value.
   * @param documented {@code true} if the library is documented
   */
  void set documented(bool documented2) {
    this._documented = documented2;
  }
  /**
   * Set whether the library is an implementation library to match the given value.
   * @param implementation {@code true} if the library is an implementation library
   */
  void set implementation(bool implementation2) {
    this._implementation = implementation2;
  }
  /**
   * Set the path to the file defining the library to the given path. The path is relative to the{@code lib} directory within the SDK.
   * @param path the path to the file defining the library
   */
  void set path(String path2) {
    this._path = path2;
  }
  /**
   * Record that this library can be run on the VM.
   */
  void setVmLibrary() {
    _platforms |= VM_PLATFORM;
  }
}
/**
 * Instances of the class {@code SdkLibrariesReader} read and parse the libraries file
 * (dart-sdk/lib/_internal/libraries.dart) for information about the libraries in an SDK. The
 * library information is represented as a Dart file containing a single top-level variable whose
 * value is a const map. The keys of the map are the names of libraries defined in the SDK and the
 * values in the map are info objects defining the library. For example, a subset of a typical SDK
 * might have a libraries file that looks like the following:
 * <pre>
 * final Map&lt;String, LibraryInfo&gt; LIBRARIES = const &lt;LibraryInfo&gt; {
 * // Used by VM applications
 * "builtin" : const LibraryInfo(
 * "builtin/builtin_runtime.dart",
 * category: "Server",
 * platforms: VM_PLATFORM),
 * "compiler" : const LibraryInfo(
 * "compiler/compiler.dart",
 * category: "Tools",
 * platforms: 0),
 * };
 * </pre>
 * @coverage dart.engine.sdk
 */
class SdkLibrariesReader {
  /**
   * Return the library map read from the given source.
   * @return the library map read from the given source
   */
  LibraryMap readFrom(JavaFile librariesFile, String libraryFileContents) {
    List<bool> foundError = [false];
    AnalysisErrorListener errorListener = new AnalysisErrorListener_6(foundError);
    Source source = new FileBasedSource.con2(null, librariesFile, false);
    StringScanner scanner = new StringScanner(source, libraryFileContents, errorListener);
    Parser parser = new Parser(source, errorListener);
    CompilationUnit unit = parser.parseCompilationUnit(scanner.tokenize());
    SdkLibrariesReader_LibraryBuilder libraryBuilder = new SdkLibrariesReader_LibraryBuilder();
    if (!foundError[0]) {
      unit.accept(libraryBuilder);
    }
    return libraryBuilder.librariesMap;
  }
}
class SdkLibrariesReader_LibraryBuilder extends RecursiveASTVisitor<Object> {
  /**
   * The prefix added to the name of a library to form the URI used in code to reference the
   * library.
   */
  static String _LIBRARY_PREFIX = "dart:";
  /**
   * The name of the optional parameter used to indicate whether the library is an implementation
   * library.
   */
  static String _IMPLEMENTATION = "implementation";
  /**
   * The name of the optional parameter used to indicate whether the library is documented.
   */
  static String _DOCUMENTED = "documented";
  /**
   * The name of the optional parameter used to specify the category of the library.
   */
  static String _CATEGORY = "category";
  /**
   * The name of the optional parameter used to specify the platforms on which the library can be
   * used.
   */
  static String _PLATFORMS = "platforms";
  /**
   * The value of the {@link #PLATFORMS platforms} parameter used to specify that the library can
   * be used on the VM.
   */
  static String _VM_PLATFORM = "VM_PLATFORM";
  /**
   * The library map that is populated by visiting the AST structure parsed from the contents of
   * the libraries file.
   */
  LibraryMap _librariesMap = new LibraryMap();
  /**
   * Return the library map that was populated by visiting the AST structure parsed from the
   * contents of the libraries file.
   * @return the library map describing the contents of the SDK
   */
  LibraryMap get librariesMap => _librariesMap;
  Object visitMapLiteralEntry(MapLiteralEntry node) {
    String libraryName = null;
    Expression key3 = node.key;
    if (key3 is SimpleStringLiteral) {
      libraryName = "${_LIBRARY_PREFIX}${((key3 as SimpleStringLiteral)).value}";
    }
    Expression value9 = node.value;
    if (value9 is InstanceCreationExpression) {
      SdkLibraryImpl library = new SdkLibraryImpl(libraryName);
      List<Expression> arguments7 = ((value9 as InstanceCreationExpression)).argumentList.arguments;
      for (Expression argument in arguments7) {
        if (argument is SimpleStringLiteral) {
          library.path = ((argument as SimpleStringLiteral)).value;
        } else if (argument is NamedExpression) {
          String name19 = ((argument as NamedExpression)).name.label.name;
          Expression expression15 = ((argument as NamedExpression)).expression;
          if (name19 == _CATEGORY) {
            library.category = ((expression15 as SimpleStringLiteral)).value;
          } else if (name19 == _IMPLEMENTATION) {
            library.implementation = ((expression15 as BooleanLiteral)).value;
          } else if (name19 == _DOCUMENTED) {
            library.documented = ((expression15 as BooleanLiteral)).value;
          } else if (name19 == _PLATFORMS) {
            if (expression15 is SimpleIdentifier) {
              String identifier = ((expression15 as SimpleIdentifier)).name;
              if (identifier == _VM_PLATFORM) {
                library.setVmLibrary();
              } else {
                library.setDart2JsLibrary();
              }
            }
          }
        }
      }
      _librariesMap.setLibrary(libraryName, library);
    }
    return null;
  }
}
class AnalysisErrorListener_6 implements AnalysisErrorListener {
  List<bool> foundError;
  AnalysisErrorListener_6(this.foundError);
  void onError(AnalysisError error) {
    foundError[0] = true;
  }
}
/**
 * Instances of the class {@code LibraryMap} map Dart library URI's to the {@link SdkLibraryImpllibrary}.
 * @coverage dart.engine.sdk
 */
class LibraryMap {
  /**
   * A table mapping Dart library URI's to the library.
   */
  Map<String, SdkLibraryImpl> _libraryMap = new Map<String, SdkLibraryImpl>();
  /**
   * Initialize a newly created library map to be empty.
   */
  LibraryMap() : super() {
  }
  /**
   * Return the library with the given URI, or {@code null} if the URI does not map to a library.
   * @param dartUri the URI of the library to be returned
   * @return the library with the given URI
   */
  SdkLibrary getLibrary(String dartUri) => _libraryMap[dartUri];
  /**
   * Return an array containing all the sdk libraries {@link SdkLibraryImpl} in the mapping
   * @return the sdk libraries in the mapping
   */
  List<SdkLibrary> get sdkLibraries => new List.from(_libraryMap.values);
  /**
   * Return an array containing the library URI's for which a mapping is available.
   * @return the library URI's for which a mapping is available
   */
  List<String> get uris => new List.from(_libraryMap.keys.toSet());
  /**
   * Return the library with the given URI, or {@code null} if the URI does not map to a library.
   * @param dartUri the URI of the library to be returned
   * @param library the library with the given URI
   */
  void setLibrary(String dartUri, SdkLibraryImpl library) {
    _libraryMap[dartUri] = library;
  }
  /**
   * Return the number of library URI's for which a mapping is available.
   * @return the number of library URI's for which a mapping is available
   */
  int size() => _libraryMap.length;
}
/**
 * Instances of the class {@code DartSdk} represent a Dart SDK installed in a specified location.
 * @coverage dart.engine.sdk
 */
class DartSdk {
  /**
   * The short name of the dart SDK core library.
   */
  static String DART_CORE = "dart:core";
  /**
   * The short name of the dart SDK html library.
   */
  static String DART_HTML = "dart:html";
  /**
   * The directory containing the SDK.
   */
  JavaFile _sdkDirectory;
  /**
   * The revision number of this SDK, or {@code "0"} if the revision number cannot be discovered.
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
   * The name of the environment variable whose value is the path to the default Dart SDK directory.
   */
  static String _DART_SDK_ENVIRONMENT_VARIABLE_NAME = "DART_SDK";
  /**
   * The name of the file containing the Dartium executable on Linux.
   */
  static String _DARTIUM_EXECUTABLE_NAME_LINUX = "chromium/chrome";
  /**
   * The name of the file containing the Dartium executable on Macintosh.
   */
  static String _DARTIUM_EXECUTABLE_NAME_MAC = "Chromium.app/Contents/MacOS/Chromium";
  /**
   * The name of the file containing the Dartium executable on Windows.
   */
  static String _DARTIUM_EXECUTABLE_NAME_WIN = "chromium/Chrome.exe";
  /**
   * The name of the {@link System} property whose value is the path to the default Dart SDK
   * directory.
   */
  static String _DEFAULT_DIRECTORY_PROPERTY_NAME = "com.google.dart.sdk";
  /**
   * The version number that is returned when the real version number could not be determined.
   */
  static String _DEFAULT_VERSION = "0";
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
   * The name of the directory within the SDK directory that contains the packages.
   */
  static String _PKG_DIRECTORY_NAME = "pkg";
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
   * Return the default Dart SDK, or {@code null} if the directory containing the default SDK cannot
   * be determined (or does not exist).
   * @return the default Dart SDK
   */
  static DartSdk get defaultSdk {
    JavaFile sdkDirectory = defaultSdkDirectory;
    if (sdkDirectory == null) {
      return null;
    }
    return new DartSdk(sdkDirectory);
  }
  /**
   * Return the default directory for the Dart SDK, or {@code null} if the directory cannot be
   * determined (or does not exist). The default directory is provided by a {@link System} property
   * named {@code com.google.dart.sdk}, or, if the property is not defined, an environment variable
   * named {@code DART_SDK}.
   * @return the default directory for the Dart SDK
   */
  static JavaFile get defaultSdkDirectory {
    String sdkProperty = JavaSystemIO.getProperty(_DEFAULT_DIRECTORY_PROPERTY_NAME);
    if (sdkProperty == null) {
      sdkProperty = JavaSystemIO.getenv(_DART_SDK_ENVIRONMENT_VARIABLE_NAME);
      if (sdkProperty == null) {
        return null;
      }
    }
    JavaFile sdkDirectory = new JavaFile(sdkProperty);
    if (!sdkDirectory.exists()) {
      return null;
    }
    return sdkDirectory;
  }
  /**
   * Initialize a newly created SDK to represent the Dart SDK installed in the given directory.
   * @param sdkDirectory the directory containing the SDK
   */
  DartSdk(JavaFile sdkDirectory) {
    this._sdkDirectory = sdkDirectory.getAbsoluteFile();
    initializeSdk();
    initializeLibraryMap();
  }
  /**
   * Return the file containing the Dartium executable, or {@code null} if it does not exist.
   * @return the file containing the Dartium executable
   */
  JavaFile get dartiumExecutable {
    {
      if (_dartiumExecutable == null) {
        JavaFile file = new JavaFile.relative(_sdkDirectory, dartiumBinaryName);
        if (file.exists()) {
          _dartiumExecutable = file;
        }
      }
    }
    return _dartiumExecutable;
  }
  /**
   * Return the directory where dartium can be found in the Dart SDK (the directory that will be the
   * working directory is Dartium is invoked without changing the default).
   * @return the directory where dartium can be found
   */
  JavaFile get dartiumWorkingDirectory {
    if (OSUtilities.isWindows() || OSUtilities.isMac()) {
      return _sdkDirectory;
    } else {
      return new JavaFile.relative(_sdkDirectory, _CHROMIUM_DIRECTORY_NAME);
    }
  }
  /**
   * Return the directory containing the SDK.
   * @return the directory containing the SDK
   */
  JavaFile get directory => _sdkDirectory;
  /**
   * Return the directory containing documentation for the SDK.
   * @return the SDK's documentation directory
   */
  JavaFile get docDirectory => new JavaFile.relative(_sdkDirectory, _DOCS_DIRECTORY_NAME);
  /**
   * Return the auxiliary documentation file for the given library, or {@code null} if no such file
   * exists.
   * @param libraryName the name of the library associated with the documentation file to be
   * returned
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
   * @return the directory that contains the libraries
   */
  JavaFile get libraryDirectory => new JavaFile.relative(_sdkDirectory, _LIB_DIRECTORY_NAME);
  /**
   * Return the directory within the SDK directory that contains the packages.
   * @return the directory that contains the packages
   */
  JavaFile get packageDirectory => new JavaFile.relative(directory, _PKG_DIRECTORY_NAME);
  /**
   * Return an array containing all of the libraries defined in this SDK.
   * @return the libraries defined in this SDK
   */
  List<SdkLibrary> get sdkLibraries => _libraryMap.sdkLibraries;
  /**
   * Return the revision number of this SDK, or {@code "0"} if the revision number cannot be
   * discovered.
   * @return the revision number of this SDK
   */
  String get sdkVersion {
    {
      if (_sdkVersion == null) {
        _sdkVersion = _DEFAULT_VERSION;
        JavaFile revisionFile = new JavaFile.relative(_sdkDirectory, _REVISION_FILE_NAME);
        try {
          String revision = revisionFile.readAsStringSync();
          if (revision != null) {
            _sdkVersion = revision;
          }
        } on IOException catch (exception) {
        }
      }
    }
    return _sdkVersion;
  }
  /**
   * Return an array containing the library URI's for the libraries defined in this SDK.
   * @return the library URI's for the libraries defined in this SDK
   */
  List<String> get uris => _libraryMap.uris;
  /**
   * Return the file containing the VM executable, or {@code null} if it does not exist.
   * @return the file containing the VM executable
   */
  JavaFile get vmExecutable {
    {
      if (_vmExecutable == null) {
        JavaFile file = new JavaFile.relative(new JavaFile.relative(_sdkDirectory, _BIN_DIRECTORY_NAME), binaryName);
        if (file.exists()) {
          _vmExecutable = file;
        }
      }
    }
    return _vmExecutable;
  }
  /**
   * Return {@code true} if this SDK includes documentation.
   * @return {@code true} if this installation of the SDK has documentation
   */
  bool hasDocumentation() => docDirectory.exists();
  /**
   * Return {@code true} if the Dartium binary is available.
   * @return {@code true} if the Dartium binary is available
   */
  bool isDartiumInstalled() => dartiumExecutable != null;
  /**
   * Return the file representing the library with the given {@code dart:} URI, or {@code null} if
   * the given URI does not denote a library in this SDK.
   * @param dartUri the URI of the library to be returned
   * @return the file representing the specified library
   */
  JavaFile mapDartUri(String dartUri) {
    SdkLibrary library = _libraryMap.getLibrary(dartUri);
    if (library == null) {
      return null;
    }
    return new JavaFile.relative(libraryDirectory, library.path);
  }
  /**
   * Ensure that the dart VM is executable. If it is not, make it executable and log that it was
   * necessary for us to do so.
   */
  void ensureVmIsExecutable() {
  }
  /**
   * Return the name of the file containing the VM executable.
   * @return the name of the file containing the VM executable
   */
  String get binaryName {
    if (OSUtilities.isWindows()) {
      return _VM_EXECUTABLE_NAME_WIN;
    } else {
      return _VM_EXECUTABLE_NAME;
    }
  }
  /**
   * Return the name of the file containing the Dartium executable.
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
   * Read all of the configuration files to initialize the library maps.
   */
  void initializeLibraryMap() {
    try {
      JavaFile librariesFile = new JavaFile.relative(new JavaFile.relative(libraryDirectory, _INTERNAL_DIR), _LIBRARIES_FILE);
      String contents = librariesFile.readAsStringSync();
      _libraryMap = new SdkLibrariesReader().readFrom(librariesFile, contents);
    } on JavaException catch (exception) {
      AnalysisEngine.instance.logger.logError3(exception);
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