// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.sdk;

import 'dart:collection';

import 'ast.dart';
import 'engine.dart' show AnalysisContext;
import 'source.dart' show ContentCache, Source, UriKind;

/**
 * A Dart SDK installed in a specified location.
 */
abstract class DartSdk {
  /**
   * The short name of the dart SDK 'async' library.
   */
  static final String DART_ASYNC = "dart:async";

  /**
   * The short name of the dart SDK 'core' library.
   */
  static final String DART_CORE = "dart:core";

  /**
   * The short name of the dart SDK 'html' library.
   */
  static final String DART_HTML = "dart:html";

  /**
   * The version number that is returned when the real version number could not
   * be determined.
   */
  static final String DEFAULT_VERSION = "0";

  /**
   * Return the analysis context used for all of the sources in this [DartSdk].
   */
  AnalysisContext get context;

  /**
   * Return a list containing all of the libraries defined in this SDK.
   */
  List<SdkLibrary> get sdkLibraries;

  /**
   * Return the revision number of this SDK, or `"0"` if the revision number
   * cannot be discovered.
   */
  String get sdkVersion;

  /**
   * Return a list containing the library URI's for the libraries defined in
   * this SDK.
   */
  List<String> get uris;

  /**
   * Return a source representing the given 'file:' [uri] if the file is in this
   * SDK, or `null` if the file is not in this SDK.
   */
  Source fromFileUri(Uri uri);

  /**
   * Return the library representing the library with the given 'dart:' [uri],
   * or `null` if the given URI does not denote a library in this SDK.
   */
  SdkLibrary getSdkLibrary(String uri);

  /**
   * Return the source representing the library with the given 'dart:' [uri], or
   * `null` if the given URI does not denote a library in this SDK.
   */
  Source mapDartUri(String uri);
}

/**
 * A map from Dart library URI's to the [SdkLibraryImpl] representing that
 * library.
 */
class LibraryMap {
  /**
   * A table mapping Dart library URI's to the library.
   */
  HashMap<String, SdkLibraryImpl> _libraryMap =
      new HashMap<String, SdkLibraryImpl>();

  /**
   * Return a list containing all of the sdk libraries in this mapping.
   */
  List<SdkLibrary> get sdkLibraries => new List.from(_libraryMap.values);

  /**
   * Return a list containing the library URI's for which a mapping is available.
   */
  List<String> get uris => new List.from(_libraryMap.keys.toSet());

  /**
   * Return the library with the given 'dart:' [uri], or `null` if the URI does
   * not map to a library.
   */
  SdkLibrary getLibrary(String uri) => _libraryMap[uri];

  /**
   * Set the library with the given 'dart:' [uri] to the given [library].
   */
  void setLibrary(String dartUri, SdkLibraryImpl library) {
    _libraryMap[dartUri] = library;
  }

  /**
   * Return the number of library URI's for which a mapping is available.
   */
  int size() => _libraryMap.length;
}

class SdkLibrariesReader_LibraryBuilder extends RecursiveAstVisitor<Object> {
  /**
   * The prefix added to the name of a library to form the URI used in code to
   * reference the library.
   */
  static String _LIBRARY_PREFIX = "dart:";

  /**
   * The name of the optional parameter used to indicate whether the library is
   * an implementation library.
   */
  static String _IMPLEMENTATION = "implementation";

  /**
   * The name of the optional parameter used to specify the path used when
   * compiling for dart2js.
   */
  static String _DART2JS_PATH = "dart2jsPath";

  /**
   * The name of the optional parameter used to indicate whether the library is
   * documented.
   */
  static String _DOCUMENTED = "documented";

  /**
   * The name of the optional parameter used to specify the category of the
   * library.
   */
  static String _CATEGORY = "category";

  /**
   * The name of the optional parameter used to specify the platforms on which
   * the library can be used.
   */
  static String _PLATFORMS = "platforms";

  /**
   * The value of the [PLATFORMS] parameter used to specify that the library can
   * be used on the VM.
   */
  static String _VM_PLATFORM = "VM_PLATFORM";

  /**
   * A flag indicating whether the dart2js path should be used when it is
   * available.
   */
  final bool _useDart2jsPaths;

  /**
   * The library map that is populated by visiting the AST structure parsed from
   * the contents of the libraries file.
   */
  LibraryMap _librariesMap = new LibraryMap();

  /**
   * Initialize a newly created library builder to use the dart2js path if
   * [_useDart2jsPaths] is `true`.
   */
  SdkLibrariesReader_LibraryBuilder(this._useDart2jsPaths);

  /**
   * Return the library map that was populated by visiting the AST structure
   * parsed from the contents of the libraries file.
   */
  LibraryMap get librariesMap => _librariesMap;

  @override
  Object visitMapLiteralEntry(MapLiteralEntry node) {
    String libraryName = null;
    Expression key = node.key;
    if (key is SimpleStringLiteral) {
      libraryName = "$_LIBRARY_PREFIX${key.value}";
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
   */
  String get category;

  /**
   * Return `true` if this library can be compiled to JavaScript by dart2js.
   */
  bool get isDart2JsLibrary;

  /**
   * Return `true` if the library is documented.
   */
  bool get isDocumented;

  /**
   * Return `true` if the library is an implementation library.
   */
  bool get isImplementation;

  /**
   * Return `true` if library is internal can be used only by other SDK libraries.
   */
  bool get isInternal;

  /**
   * Return `true` if this library can be used for both client and server.
   */
  bool get isShared;

  /**
   * Return `true` if this library can be run on the VM.
   */
  bool get isVmLibrary;

  /**
   * Return the path to the file defining the library. The path is relative to
   * the `lib` directory within the SDK.
   */
  String get path;

  /**
   * Return the short name of the library. This is the URI of the library,
   * including `dart:`.
   */
  String get shortName;
}

/**
 * The information known about a single library within the SDK.
 */
class SdkLibraryImpl implements SdkLibrary {
  /**
   * The bit mask used to access the bit representing the flag indicating
   * whether a library is intended to work on the dart2js platform.
   */
  static int DART2JS_PLATFORM = 1;

  /**
   * The bit mask used to access the bit representing the flag indicating
   * whether a library is intended to work on the VM platform.
   */
  static int VM_PLATFORM = 2;

  /**
   * The short name of the library. This is the name used after 'dart:' in a
   * URI.
   */
  String _shortName = null;

  /**
   * The path to the file defining the library. The path is relative to the
   * 'lib' directory within the SDK.
   */
  String path = null;

  /**
   * The name of the category containing the library. Unless otherwise specified
   * in the libraries file all libraries are assumed to be shared between server
   * and client.
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
   * Initialize a newly created library to represent the library with the given
   * [name].
   */
  SdkLibraryImpl(String name) {
    this._shortName = name;
  }

  /**
   * Set whether the library is documented.
   */
  void set documented(bool documented) {
    this._documented = documented;
  }

  /**
   * Set whether the library is an implementation library.
   */
  void set implementation(bool implementation) {
    this._implementation = implementation;
  }

  @override
  bool get isDart2JsLibrary => (_platforms & DART2JS_PLATFORM) != 0;

  @override
  bool get isDocumented => _documented;

  @override
  bool get isImplementation => _implementation;

  @override
  bool get isInternal => "Internal" == category;

  @override
  bool get isShared => category == "Shared";

  @override
  bool get isVmLibrary => (_platforms & VM_PLATFORM) != 0;

  @override
  String get shortName => _shortName;

  /**
   * Record that this library can be compiled to JavaScript by dart2js.
   */
  void setDart2JsLibrary() {
    _platforms |= DART2JS_PLATFORM;
  }

  /**
   * Record that this library can be run on the VM.
   */
  void setVmLibrary() {
    _platforms |= VM_PLATFORM;
  }
}
