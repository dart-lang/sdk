// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.generated.sdk;

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisContext, AnalysisOptions, AnalysisOptionsImpl;
import 'package:analyzer/src/generated/source.dart' show Source;
import 'package:analyzer/src/generated/utilities_general.dart';
import 'package:analyzer/src/summary/idl.dart' show PackageBundle;

/**
 * A Dart SDK installed in a specified location.
 */
abstract class DartSdk {
  /**
   * The short name of the dart SDK 'async' library.
   */
  static const String DART_ASYNC = "dart:async";

  /**
   * The short name of the dart SDK 'core' library.
   */
  static const String DART_CORE = "dart:core";

  /**
   * The short name of the dart SDK 'html' library.
   */
  static const String DART_HTML = "dart:html";

  /**
   * The prefix shared by all dart library URIs.
   */
  static const String DART_LIBRARY_PREFIX = "dart:";

  /**
   * The version number that is returned when the real version number could not
   * be determined.
   */
  static const String DEFAULT_VERSION = "0";

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
   * Return the linked [PackageBundle] for this SDK, if it can be provided, or
   * `null` otherwise.
   *
   * This is a temporary API, don't use it.
   */
  PackageBundle getLinkedBundle();

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
 * Manages the DartSdk's that have been created. Clients need to create multiple
 * SDKs when the analysis options associated with those SDK's contexts will
 * produce different analysis results.
 */
class DartSdkManager {
  /**
   * The absolute path to the directory containing the default SDK.
   */
  final String defaultSdkDirectory;

  /**
   * A flag indicating whether it is acceptable to use summaries when they are
   * available.
   */
  final bool canUseSummaries;

  /**
   * A table mapping (an encoding of) analysis options and SDK locations to the
   * DartSdk from that location that has been configured with those options.
   */
  Map<SdkDescription, DartSdk> sdkMap = new HashMap<SdkDescription, DartSdk>();

  /**
   * Initialize a newly created manager.
   */
  DartSdkManager(this.defaultSdkDirectory, this.canUseSummaries);

  /**
   * Return any SDK that has been created, or `null` if no SDKs have been
   * created.
   */
  DartSdk get anySdk {
    if (sdkMap.isEmpty) {
      return null;
    }
    return sdkMap.values.first;
  }

  /**
   * Return a list of the descriptors of the SDKs that are currently being
   * managed.
   */
  List<SdkDescription> get sdkDescriptors => sdkMap.keys.toList();

  /**
   * Return the Dart SDK that is appropriate for the given SDK [description].
   * If such an SDK has not yet been created, then the [ifAbsent] function will
   * be invoked to create it.
   */
  DartSdk getSdk(SdkDescription description, DartSdk ifAbsent()) {
    return sdkMap.putIfAbsent(description, ifAbsent);
  }
}

/**
 * A map from Dart library URI's to the [SdkLibraryImpl] representing that
 * library.
 */
class LibraryMap {
  /**
   * A table mapping Dart library URI's to the library.
   */
  LinkedHashMap<String, SdkLibraryImpl> _libraryMap =
      new LinkedHashMap<String, SdkLibraryImpl>();

  /**
   * Return a list containing all of the sdk libraries in this mapping.
   */
  List<SdkLibrary> get sdkLibraries => new List.from(_libraryMap.values);

  /**
   * Return a list containing the library URI's for which a mapping is available.
   */
  List<String> get uris => _libraryMap.keys.toList();

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

/**
 * A description of a [DartSdk].
 */
class SdkDescription {
  /**
   * The paths to the files or directories that define the SDK.
   */
  final List<String> paths;

  /**
   * The analysis options that will be used by the SDK's context.
   */
  final AnalysisOptions options;

  /**
   * Initialize a newly created SDK description to describe an SDK based on the
   * files or directories at the given [paths] that is analyzed using the given
   * [options].
   */
  SdkDescription(this.paths, this.options);

  @override
  int get hashCode {
    int hashCode = options.encodeCrossContextOptions();
    for (String path in paths) {
      hashCode = JenkinsSmiHash.combine(hashCode, path.hashCode);
    }
    return JenkinsSmiHash.finish(hashCode);
  }

  @override
  bool operator ==(Object other) {
    if (other is SdkDescription) {
      if (options.encodeCrossContextOptions() !=
          other.options.encodeCrossContextOptions()) {
        return false;
      }
      int length = paths.length;
      if (other.paths.length != length) {
        return false;
      }
      for (int i = 0; i < length; i++) {
        if (other.paths[i] != paths[i]) {
          return false;
        }
      }
      return true;
    }
    return false;
  }

  @override
  String toString() {
    StringBuffer buffer = new StringBuffer();
    bool needsSeparator = false;
    void add(String optionName) {
      if (needsSeparator) {
        buffer.write(', ');
      }
      buffer.write(optionName);
      needsSeparator = true;
    }

    for (String path in paths) {
      add(path);
    }
    if (needsSeparator) {
      buffer.write(' ');
    }
    buffer.write('(');
    buffer.write(AnalysisOptionsImpl
        .decodeCrossContextOptions(options.encodeCrossContextOptions()));
    buffer.write(')');
    return buffer.toString();
  }
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
   * The name of the `dart2js` platform.
   */
  static String _DART2JS_PLATFORM = 'DART2JS_PLATFORM';

  /**
   * The name of the optional parameter used to indicate whether the library is
   * documented.
   */
  static String _DOCUMENTED = "documented";

  /**
   * The name of the optional parameter used to specify the category of the
   * library.
   */
  static String _CATEGORIES = "categories";

  /**
   * The name of the optional parameter used to specify the patches for
   * the library.
   */
  static String _PATCHES = "patches";

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

  // To be backwards-compatible the new categories field is translated to
  // an old approximation.
  String convertCategories(String categories) {
    switch (categories) {
      case "":
        return "Internal";
      case "Client":
        return "Client";
      case "Server":
        return "Server";
      case "Client,Server":
        return "Shared";
      case "Client,Server,Embedded":
        return "Shared";
    }
    return "Shared";
  }

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
          if (name == _CATEGORIES) {
            library.category =
                convertCategories((expression as StringLiteral).stringValue);
          } else if (name == _IMPLEMENTATION) {
            library._implementation = (expression as BooleanLiteral).value;
          } else if (name == _DOCUMENTED) {
            library.documented = (expression as BooleanLiteral).value;
          } else if (name == _PATCHES) {
            if (expression is MapLiteral) {
              expression.entries.forEach((MapLiteralEntry entry) {
                int platforms = _convertPlatforms(entry.key);
                Expression pathsListLiteral = entry.value;
                if (pathsListLiteral is ListLiteral) {
                  List<String> paths = <String>[];
                  pathsListLiteral.elements.forEach((Expression pathExpr) {
                    if (pathExpr is SimpleStringLiteral) {
                      String path = pathExpr.value;
                      _validatePatchPath(path);
                      paths.add(path);
                    } else {
                      throw new ArgumentError(
                          'The "patch" argument items must be simple strings.');
                    }
                  });
                  library.setPatchPaths(platforms, paths);
                } else {
                  throw new ArgumentError(
                      'The "patch" argument values must be list literals.');
                }
              });
            }
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

  /**
   * Validate the given [path] to a patch file. Throw [ArgumentError] if not a
   * valid path: is absolute, or contains `..`.
   */
  void _validatePatchPath(String path) {
    if (path.contains(r'\')) {
      throw new ArgumentError('The path to a patch file must be posix: $path');
    }
    if (path.contains('..')) {
      throw new ArgumentError(
          'The path to a patch file cannot contain "..": $path');
    }
    if (path.startsWith('/')) {
      throw new ArgumentError(
          'The path to a patch file cannot be absolute: $path');
    }
  }

  /**
   * Return the platform constant value for the given [expr].
   * Throw [ArgumentError] if not a valid platform name given.
   */
  static int _convertPlatform(Expression expr) {
    if (expr is SimpleIdentifier) {
      String name = expr.name;
      if (name == _DART2JS_PLATFORM) {
        return SdkLibraryImpl.DART2JS_PLATFORM;
      }
      if (name == _VM_PLATFORM) {
        return SdkLibraryImpl.VM_PLATFORM;
      }
      throw new ArgumentError('Invalid platform name: $name');
    }
    throw new ArgumentError('Invalid platform type: ${expr.runtimeType}');
  }

  /**
   * Return the platforms combination value for the [expr], which should be
   * either `name1 | name2` or `name`.  Throw [ArgumentError] if any of the
   * names is not a valid platform name.
   */
  static int _convertPlatforms(Expression expr) {
    if (expr is BinaryExpression) {
      TokenType operator = expr.operator?.type;
      if (operator == TokenType.BAR) {
        return _convertPlatforms(expr.leftOperand) |
            _convertPlatforms(expr.rightOperand);
      } else {
        throw new ArgumentError('Invalid platforms combination: $operator');
      }
    } else {
      return _convertPlatform(expr);
    }
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

  /**
   * Return the list of paths to the patch files that should be applied
   * to this library for the given [platform], not `null`.
   */
  List<String> getPatches(int platform);
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

  @override
  final String shortName;

  /**
   * The path to the file defining the library. The path is relative to the
   * 'lib' directory within the SDK.
   */
  @override
  String path = null;

  /**
   * The name of the category containing the library. Unless otherwise specified
   * in the libraries file all libraries are assumed to be shared between server
   * and client.
   */
  @override
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
   * The mapping from the platform combination to the list of paths (relative
   * to the `sdk/lib` folder) of patches that should be applied to this library
   * on every platform in the combination.
   */
  final Map<int, List<String>> _platformsToPatchPaths =
      new HashMap<int, List<String>>();

  /**
   * Initialize a newly created library to represent the library with the given
   * [name].
   */
  SdkLibraryImpl(this.shortName);

  /**
   * Set whether the library is documented.
   */
  void set documented(bool documented) {
    this._documented = documented;
  }

  @override
  bool get isDart2JsLibrary => (_platforms & DART2JS_PLATFORM) != 0;

  @override
  bool get isDocumented => _documented;

  @override
  bool get isImplementation => _implementation;

  @override
  bool get isInternal => category == "Internal";

  @override
  bool get isShared => category == "Shared";

  @override
  bool get isVmLibrary => (_platforms & VM_PLATFORM) != 0;

  @override
  List<String> getPatches(int platform) {
    List<String> paths = <String>[];
    _platformsToPatchPaths.forEach((int platforms, List<String> value) {
      if ((platforms & platform) != 0) {
        paths.addAll(value);
      }
    });
    return paths;
  }

  /**
   * Record that this library can be compiled to JavaScript by dart2js.
   */
  void setDart2JsLibrary() {
    _platforms |= DART2JS_PLATFORM;
  }

  /**
   * Add a new patch with the given [path] that should be applied for the
   * given [platforms].
   */
  void setPatchPaths(int platforms, List<String> paths) {
    _platformsToPatchPaths[platforms] = paths;
  }

  /**
   * Record that this library can be run on the VM.
   */
  void setVmLibrary() {
    _platforms |= VM_PLATFORM;
  }
}
