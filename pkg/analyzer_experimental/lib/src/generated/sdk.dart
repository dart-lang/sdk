// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.
library engine.sdk;
import 'java_core.dart';
import 'java_engine.dart';
import 'source.dart' show ContentCache, Source, UriKind;
import 'engine.dart' show AnalysisContext;
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
   * Return {@code true} if library is internal can be used only by other SDK libraries.
   * @return {@code true} if library is internal can be used only by other SDK libraries
   */
  bool isInternal();

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
  bool isInternal() => "Internal" == _category;

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
 * Instances of the class {@code LibraryMap} map Dart library URI's to the {@link SdkLibraryImpllibrary}.
 * @coverage dart.engine.sdk
 */
class LibraryMap {

  /**
   * A table mapping Dart library URI's to the library.
   */
  Map<String, SdkLibraryImpl> _libraryMap = new Map<String, SdkLibraryImpl>();

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
abstract class DartSdk {

  /**
   * The short name of the dart SDK core library.
   */
  static final String DART_CORE = "dart:core";

  /**
   * The short name of the dart SDK html library.
   */
  static final String DART_HTML = "dart:html";

  /**
   * The version number that is returned when the real version number could not be determined.
   */
  static final String DEFAULT_VERSION = "0";

  /**
   * Return the source representing the file with the given URI.
   * @param contentCache the content cache used to access the contents of the mapped source
   * @param kind the kind of URI that was originally resolved in order to produce an encoding with
   * the given URI
   * @param uri the URI of the file to be returned
   * @return the source representing the specified file
   */
  Source fromEncoding(ContentCache contentCache, UriKind kind, Uri uri);

  /**
   * Return the {@link AnalysisContext} used for all of the sources in this {@link DartSdk}.
   * @return the {@link AnalysisContext} used for all of the sources in this {@link DartSdk}
   */
  AnalysisContext get context;

  /**
   * Return an array containing all of the libraries defined in this SDK.
   * @return the libraries defined in this SDK
   */
  List<SdkLibrary> get sdkLibraries;

  /**
   * Return the library representing the library with the given {@code dart:} URI, or {@code null}if the given URI does not denote a library in this SDK.
   * @param dartUri the URI of the library to be returned
   * @return the SDK library object
   */
  SdkLibrary getSdkLibrary(String dartUri);

  /**
   * Return the revision number of this SDK, or {@code "0"} if the revision number cannot be
   * discovered.
   * @return the revision number of this SDK
   */
  String get sdkVersion;

  /**
   * Return an array containing the library URI's for the libraries defined in this SDK.
   * @return the library URI's for the libraries defined in this SDK
   */
  List<String> get uris;

  /**
   * Return the source representing the library with the given {@code dart:} URI, or {@code null} if
   * the given URI does not denote a library in this SDK.
   * @param contentCache the content cache used to access the contents of the mapped source
   * @param dartUri the URI of the library to be returned
   * @return the source representing the specified library
   */
  Source mapDartUri(ContentCache contentCache, String dartUri);
}