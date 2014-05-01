// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.sdk;

import 'source.dart' show ContentCache, Source, UriKind;
import 'ast.dart';
import 'engine.dart' show AnalysisContext;

/**
 * Instances of the class `DartSdk` represent a Dart SDK installed in a specified location.
 */
abstract class DartSdk {
  /**
   * The short name of the dart SDK async library.
   */
  static final String DART_ASYNC = "dart:async";

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
   *
   * @param kind the kind of URI that was originally resolved in order to produce an encoding with
   *          the given URI
   * @param uri the URI of the file to be returned
   * @return the source representing the specified file
   */
  Source fromEncoding(UriKind kind, Uri uri);

  /**
   * Return the [AnalysisContext] used for all of the sources in this [DartSdk].
   *
   * @return the [AnalysisContext] used for all of the sources in this [DartSdk]
   */
  AnalysisContext get context;

  /**
   * Return an array containing all of the libraries defined in this SDK.
   *
   * @return the libraries defined in this SDK
   */
  List<SdkLibrary> get sdkLibraries;

  /**
   * Return the library representing the library with the given `dart:` URI, or `null`
   * if the given URI does not denote a library in this SDK.
   *
   * @param dartUri the URI of the library to be returned
   * @return the SDK library object
   */
  SdkLibrary getSdkLibrary(String dartUri);

  /**
   * Return the revision number of this SDK, or `"0"` if the revision number cannot be
   * discovered.
   *
   * @return the revision number of this SDK
   */
  String get sdkVersion;

  /**
   * Return an array containing the library URI's for the libraries defined in this SDK.
   *
   * @return the library URI's for the libraries defined in this SDK
   */
  List<String> get uris;

  /**
   * Return the source representing the library with the given `dart:` URI, or `null` if
   * the given URI does not denote a library in this SDK.
   *
   * @param dartUri the URI of the library to be returned
   * @return the source representing the specified library
   */
  Source mapDartUri(String dartUri);
}

/**
 * Instances of the class `LibraryMap` map Dart library URI's to the [SdkLibraryImpl
 ].
 */
class LibraryMap {
  /**
   * A table mapping Dart library URI's to the library.
   */
  Map<String, SdkLibraryImpl> _libraryMap = new Map<String, SdkLibraryImpl>();

  /**
   * Return the library with the given URI, or `null` if the URI does not map to a library.
   *
   * @param dartUri the URI of the library to be returned
   * @return the library with the given URI
   */
  SdkLibrary getLibrary(String dartUri) => _libraryMap[dartUri];

  /**
   * Return an array containing all the sdk libraries [SdkLibraryImpl] in the mapping
   *
   * @return the sdk libraries in the mapping
   */
  List<SdkLibrary> get sdkLibraries => new List.from(_libraryMap.values);

  /**
   * Return an array containing the library URI's for which a mapping is available.
   *
   * @return the library URI's for which a mapping is available
   */
  List<String> get uris => new List.from(_libraryMap.keys.toSet());

  /**
   * Return the library with the given URI, or `null` if the URI does not map to a library.
   *
   * @param dartUri the URI of the library to be returned
   * @param library the library with the given URI
   */
  void setLibrary(String dartUri, SdkLibraryImpl library) {
    _libraryMap[dartUri] = library;
  }

  /**
   * Return the number of library URI's for which a mapping is available.
   *
   * @return the number of library URI's for which a mapping is available
   */
  int size() => _libraryMap.length;
}

class SdkLibrariesReader_LibraryBuilder extends RecursiveAstVisitor<Object> {
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
   * The name of the optional parameter used to specify the path used when compiling for dart2js.
   */
  static String _DART2JS_PATH = "dart2jsPath";

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
   * The value of the [PLATFORMS] parameter used to specify that the library can
   * be used on the VM.
   */
  static String _VM_PLATFORM = "VM_PLATFORM";

  /**
   * A flag indicating whether the dart2js path should be used when it is available.
   */
  final bool _useDart2jsPaths;

  /**
   * The library map that is populated by visiting the AST structure parsed from the contents of
   * the libraries file.
   */
  LibraryMap _librariesMap = new LibraryMap();

  /**
   * Initialize a newly created library builder to use the dart2js path if the given value is
   * `true`.
   *
   * @param useDart2jsPaths `true` if the dart2js path should be used when it is available
   */
  SdkLibrariesReader_LibraryBuilder(this._useDart2jsPaths);

  /**
   * Return the library map that was populated by visiting the AST structure parsed from the
   * contents of the libraries file.
   *
   * @return the library map describing the contents of the SDK
   */
  LibraryMap get librariesMap => _librariesMap;

  @override
  Object visitMapLiteralEntry(MapLiteralEntry node) {
    String libraryName = null;
    Expression key = node.key;
    if (key is SimpleStringLiteral) {
      libraryName = "${_LIBRARY_PREFIX}${key.value}";
    }
    Expression value = node.value;
    if (value is InstanceCreationExpression) {
      SdkLibraryImpl library = new SdkLibraryImpl(libraryName);
      List<Expression> arguments = value.argumentList.arguments;
      for (Expression argument in arguments) {
        if (argument is SimpleStringLiteral) {
          library.path = argument.value;
        } else if (argument is NamedExpression) {
          String name = argument.name.label.name;
          Expression expression = argument.expression;
          if (name == _CATEGORY) {
            library.category = (expression as SimpleStringLiteral).value;
          } else if (name == _IMPLEMENTATION) {
            library.implementation = (expression as BooleanLiteral).value;
          } else if (name == _DOCUMENTED) {
            library.documented = (expression as BooleanLiteral).value;
          } else if (name == _PLATFORMS) {
            if (expression is SimpleIdentifier) {
              String identifier = expression.name;
              if (identifier == _VM_PLATFORM) {
                library.setVmLibrary();
              } else {
                library.setDart2JsLibrary();
              }
            }
          } else if (_useDart2jsPaths && name == _DART2JS_PATH) {
            if (expression is SimpleStringLiteral) {
              library.path = expression.value;
            }
          }
        }
      }
      _librariesMap.setLibrary(libraryName, library);
    }
    return null;
  }
}

/**
 * Represents a single library in the SDK
 */
abstract class SdkLibrary {
  /**
   * Return the name of the category containing the library.
   *
   * @return the name of the category containing the library
   */
  String get category;

  /**
   * Return the path to the file defining the library. The path is relative to the `lib`
   * directory within the SDK.
   *
   * @return the path to the file defining the library
   */
  String get path;

  /**
   * Return the short name of the library. This is the name used after `dart:` in a URI.
   *
   * @return the short name of the library
   */
  String get shortName;

  /**
   * Return `true` if this library can be compiled to JavaScript by dart2js.
   *
   * @return `true` if this library can be compiled to JavaScript by dart2js
   */
  bool get isDart2JsLibrary;

  /**
   * Return `true` if the library is documented.
   *
   * @return `true` if the library is documented
   */
  bool get isDocumented;

  /**
   * Return `true` if the library is an implementation library.
   *
   * @return `true` if the library is an implementation library
   */
  bool get isImplementation;

  /**
   * Return `true` if library is internal can be used only by other SDK libraries.
   *
   * @return `true` if library is internal can be used only by other SDK libraries
   */
  bool get isInternal;

  /**
   * Return `true` if library can be used for both client and server.
   *
   * @return `true` if this library can be used for both client and server.
   */
  bool get isShared;

  /**
   * Return `true` if this library can be run on the VM.
   *
   * @return `true` if this library can be run on the VM
   */
  bool get isVmLibrary;
}

/**
 * Instances of the class `SdkLibrary` represent the information known about a single library
 * within the SDK.
 */
class SdkLibraryImpl implements SdkLibrary {
  /**
   * The short name of the library. This is the name used after `dart:` in a URI.
   */
  String _shortName = null;

  /**
   * The path to the file defining the library. The path is relative to the `lib` directory
   * within the SDK.
   */
  String path = null;

  /**
   * The name of the category containing the library. Unless otherwise specified in the libraries
   * file all libraries are assumed to be shared between server and client.
   */
  String category = "Shared";

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
   *
   * @param name the short name of the library
   */
  SdkLibraryImpl(String name) {
    this._shortName = name;
  }

  @override
  String get shortName => _shortName;

  @override
  bool get isDart2JsLibrary => (_platforms & DART2JS_PLATFORM) != 0;

  @override
  bool get isDocumented => _documented;

  @override
  bool get isImplementation => _implementation;

  @override
  bool get isInternal => "Internal" == category;

  /**
   * Return `true` if library can be used for both client and server
   */
  @override
  bool get isShared => category == "Shared";

  /**
   * Return `true` if this library can be run on the VM.
   *
   * @return `true` if this library can be run on the VM
   */
  @override
  bool get isVmLibrary => (_platforms & VM_PLATFORM) != 0;

  /**
   * Record that this library can be compiled to JavaScript by dart2js.
   */
  void setDart2JsLibrary() {
    _platforms |= DART2JS_PLATFORM;
  }

  /**
   * Set whether the library is documented to match the given value.
   *
   * @param documented `true` if the library is documented
   */
  void set documented(bool documented) {
    this._documented = documented;
  }

  /**
   * Set whether the library is an implementation library to match the given value.
   *
   * @param implementation `true` if the library is an implementation library
   */
  void set implementation(bool implementation) {
    this._implementation = implementation;
  }

  /**
   * Record that this library can be run on the VM.
   */
  void setVmLibrary() {
    _platforms |= VM_PLATFORM;
  }
}