// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * **docgen** is a tool for creating machine readable representations of Dart
 * code metadata, including: classes, members, comments and annotations.
 *
 * docgen is run on a `.dart` file or a directory containing `.dart` files.
 *
 *      $ dart docgen.dart [OPTIONS] [FILE/DIR]
 *
 * This creates files called `docs/<library_name>.yaml` in your current
 * working directory.
 */
library docgen;

import 'dart:io';
import 'dart:json';
import 'dart:async';

import 'package:logging/logging.dart';
import 'package:markdown/markdown.dart' as markdown;
import 'package:path/path.dart' as path;

import 'dart2yaml.dart';
import 'src/io.dart';
import '../../../sdk/lib/_internal/compiler/compiler.dart' as api;
import '../../../sdk/lib/_internal/compiler/implementation/filenames.dart';
import '../../../sdk/lib/_internal/compiler/implementation/mirrors/dart2js_mirror.dart'
    as dart2js;
import '../../../sdk/lib/_internal/compiler/implementation/mirrors/mirrors.dart';
import '../../../sdk/lib/_internal/compiler/implementation/source_file_provider.dart';
import '../../../sdk/lib/_internal/libraries.dart';

var logger = new Logger('Docgen');

const String USAGE = 'Usage: dart docgen.dart [OPTIONS] [fooDir/barFile]';


List<String> validAnnotations = const ['metadata.Experimental', 
    'metadata.DomName', 'metadata.Deprecated', 'metadata.Unstable', 
    'meta.deprecated', 'metadata.SupportedBrowser'];

/// Current library being documented to be used for comment links.
LibraryMirror _currentLibrary;

/// Current class being documented to be used for comment links.
ClassMirror _currentClass;

/// Current member being documented to be used for comment links.
MemberMirror _currentMember;

/// Support for [:foo:]-style code comments to the markdown parser.
List<markdown.InlineSyntax> markdownSyntaxes =
  [new markdown.CodeSyntax(r'\[:\s?((?:.|\n)*?)\s?:\]')];

/// Resolves reference links in doc comments.
markdown.Resolver linkResolver;

/// Index of all indexable items. This also ensures that no class is
/// created more than once.
Map<String, Indexable> entityMap = new Map<String, Indexable>();

/// This is set from the command line arguments flag --include-private
bool _includePrivate = false;

/**
 * Docgen constructor initializes the link resolver for markdown parsing.
 * Also initializes the command line arguments.
 *
 * [packageRoot] is the packages directory of the directory being analyzed.
 * If [includeSdk] is `true`, then any SDK libraries explicitly imported will
 * also be documented.
 * If [parseSdk] is `true`, then all Dart SDK libraries will be documented.
 * This option is useful when only the SDK libraries are needed.
 *
 * Returns `true` if docgen sucessfuly completes.
 */
Future<bool> docgen(List<String> files, {String packageRoot,
    bool outputToYaml: true, bool includePrivate: false, bool includeSdk: false,
    bool parseSdk: false, bool append: false}) {
  _includePrivate = includePrivate;
  if (!append) {
    var dir = new Directory('docs');
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  }

  if (packageRoot == null && !parseSdk) {
    var type = FileSystemEntity.typeSync(files.first);
    if (type == FileSystemEntityType.DIRECTORY) {
      packageRoot = _findPackageRoot(files.first);
    } else if (type == FileSystemEntityType.FILE) {
      logger.warning('WARNING: No package root defined. If Docgen fails, try '
          'again by setting the --package-root option.');
    }
  }
  logger.info('Package Root: ${packageRoot}');

  linkResolver = (name) =>
      fixReference(name, _currentLibrary, _currentClass, _currentMember);

  return getMirrorSystem(files, packageRoot: packageRoot, parseSdk: parseSdk)
    .then((MirrorSystem mirrorSystem) {
      if (mirrorSystem.libraries.isEmpty) {
        throw new StateError('No library mirrors were created.');
      }
      _documentLibraries(mirrorSystem.libraries.values,includeSdk: includeSdk,
          outputToYaml: outputToYaml, append: append, parseSdk: parseSdk);

      return true;
    });
}

List<String> _listLibraries(List<String> args) {
  if (args.length != 1) throw new UnsupportedError(USAGE);
  var libraries = new List<String>();
  var type = FileSystemEntity.typeSync(args[0]);

  if (type == FileSystemEntityType.FILE) {
    if (args[0].endsWith('.dart')) {
      libraries.add(path.absolute(args[0]));
      logger.info('Added to libraries: ${libraries.last}');
    }
  } else {
    libraries.addAll(_listDartFromDir(args[0]));
  }
  return libraries;
}

List<String> _listDartFromDir(String args) {
  var libraries = [];
  // To avoid anaylzing package files twice, only files with paths not
  // containing '/packages' will be added. The only exception is if the file to
  // analyze already has a '/package' in its path.
  var files = listDir(args, recursive: true).where((f) => f.endsWith('.dart') &&
      (!f.contains('${path.separator}packages') ||
          args.contains('${path.separator}packages'))).toList();
  
  files.forEach((f) {
    // Only add the file if it does not contain 'part of' 
    // TODO(janicejl): Remove when Issue(12406) is resolved.
    var contents = new File(f).readAsStringSync();
    if (!(contents.contains(new RegExp('\npart of ')) || 
        contents.startsWith(new RegExp('part of ')))) {
      libraries.add(f);
      logger.info('Added to libraries: $f');
    }
  });
  return libraries;
}

String _findPackageRoot(String directory) {
  var files = listDir(directory, recursive: true);
  // Return '' means that there was no pubspec.yaml and therefor no packageRoot.
  String packageRoot = files.firstWhere((f) =>
      f.endsWith('${path.separator}pubspec.yaml'), orElse: () => '');
  if (packageRoot != '') {
    packageRoot = path.join(path.dirname(packageRoot), 'packages');
  }
  return packageRoot;
}

List<String> _listSdk() {
  var sdk = new List<String>();
  LIBRARIES.forEach((String name, LibraryInfo info) {
    if (info.documented) {
      sdk.add('dart:$name');
      logger.info('Add to SDK: ${sdk.last}');
    }
  });
  return sdk;
}

/**
 * Analyzes set of libraries by getting a mirror system and triggers the
 * documentation of the libraries.
 */
Future<MirrorSystem> getMirrorSystem(List<String> args, {String packageRoot,
    bool parseSdk: false}) {
  var libraries = !parseSdk ? _listLibraries(args) : _listSdk();
  if (libraries.isEmpty) throw new StateError('No Libraries.');
  // Finds the root of SDK library based off the location of docgen.
  var sdkRoot = path.join(path.dirname(path.dirname(path.dirname(path.dirname(
        path.absolute(new Options().script))))), 'sdk');
  logger.info('SDK Root: ${sdkRoot}');
  return _analyzeLibraries(libraries, sdkRoot, packageRoot: packageRoot);
}

/**
 * Analyzes set of libraries and provides a mirror system which can be used
 * for static inspection of the source code.
 */
Future<MirrorSystem> _analyzeLibraries(List<String> libraries,
      String libraryRoot, {String packageRoot}) {
  SourceFileProvider provider = new SourceFileProvider();
  api.DiagnosticHandler diagnosticHandler =
        new FormattingDiagnosticHandler(provider).diagnosticHandler;
  Uri libraryUri = new Uri(scheme: 'file', path: appendSlash(libraryRoot));
  Uri packageUri = null;
  if (packageRoot != null) {
    packageUri = new Uri(scheme: 'file', path: appendSlash(packageRoot));
  }
  List<Uri> librariesUri = <Uri>[];
  libraries.forEach((library) {
    librariesUri.add(currentDirectory.resolve(library));
  });
  return dart2js.analyze(librariesUri, libraryUri, packageUri,
      provider.readStringFromUri, diagnosticHandler,
      ['--preserve-comments', '--categories=Client,Server'])
      ..catchError((error) {
        logger.severe('Error: Failed to create mirror system. ');
        // TODO(janicejl): Use the stack trace package when bug is resolved.
        // Currently, a string is thrown when it fails to create a mirror
        // system, and it is not possible to use the stack trace. BUG(#11622)
        // To avoid printing the stack trace.
        exit(1);
      });
}

/**
 * Creates documentation for filtered libraries.
 */
void _documentLibraries(List<LibraryMirror> libs, {bool includeSdk: false,
    bool outputToYaml: true, bool append: false, bool parseSdk: false}) {
  libs.forEach((lib) {
    // Files belonging to the SDK have a uri that begins with 'dart:'.
    if (includeSdk || !lib.uri.toString().startsWith('dart:')) {
      var library = generateLibrary(lib);
      entityMap[library.qualifiedName] = library;
    }
  });
  // After everything is created, do a pass through all classes to make sure no
  // intermediate classes created by mixins are included.
  entityMap.values.where((e) => e is Class).forEach((c) => c.makeValid());
  // Everything is a subclass of Object, therefore empty the list to avoid a
  // giant list of subclasses to be printed out.
  if (parseSdk) entityMap['dart.core.Object'].subclasses.clear();

  var filteredEntities = entityMap.values.where(_isVisible);
  // Output libraries and classes to file after all information is generated.
  filteredEntities.where((e) => e is Class || e is Library).forEach((output) {
    _writeIndexableToFile(output, outputToYaml);
  });
  // Outputs a yaml file with all libraries and their preview comments after 
  // creating all libraries. This will help the viewer know what libraries are 
  // available to read in.
  var libraryMap = {'libraries' : filteredEntities.where((e) => 
      e is Library).map((e) => e.previewMap).toList()};
  _writeToFile(getYamlString(libraryMap), 'library_list.yaml', append: append);
  // Outputs all the qualified names documented with their type.
  // This will help generate search results.
  _writeToFile(filteredEntities.map((e) => 
      '${e.qualifiedName} ${e.typeName}').join('\n'),
      'index.txt', append: append);
}

Library generateLibrary(dart2js.Dart2JsLibraryMirror library) {
  _currentLibrary = library;
  var result = new Library(library.qualifiedName, _commentToHtml(library),
      _variables(library.variables),
      _methods(library.functions),
      _classes(library.classes), _isHidden(library));
  logger.fine('Generated library for ${result.name}');
  return result;
}

void _writeIndexableToFile(Indexable result, bool outputToYaml) {
  if (outputToYaml) {
    _writeToFile(getYamlString(result.toMap()), '${result.qualifiedName}.yaml');
  } else {
    _writeToFile(stringify(result.toMap()), '${result.qualifiedName}.json');
  }
}

/**
 * Returns true if a library name starts with an underscore, and false
 * otherwise.
 *
 * An example that starts with _ is _js_helper.
 * An example that contains ._ is dart._collection.dev
 */
// This is because LibraryMirror.isPrivate returns `false` all the time.
bool _isLibraryPrivate(LibraryMirror mirror) {
  var sdkLibrary = LIBRARIES[mirror.simpleName];
  if (sdkLibrary != null) {
    return !sdkLibrary.documented;
  } else if (mirror.simpleName.startsWith('_') || 
      mirror.simpleName.contains('._')) {
    return true;
  }
  return false;
}

/**
 * A declaration is private if itself is private, or the owner is private.
 */
// Issue(12202) - A declaration is public even if it's owner is private.
bool _isHidden(DeclarationMirror mirror) {
  if (mirror is LibraryMirror) {
    return _isLibraryPrivate(mirror);
  } else if (mirror.owner is LibraryMirror) {
    return (mirror.isPrivate || _isLibraryPrivate(mirror.owner));
  } else {
    return (mirror.isPrivate || _isHidden(mirror.owner));
  }
}

bool _isVisible(Indexable item) {
  return _includePrivate || !item.isPrivate;
}

/**
 * Returns a list of meta annotations assocated with a mirror.
 */
List<String> _annotations(DeclarationMirror mirror) {
  var annotationMirrors = mirror.metadata.where((e) =>
      e is dart2js.Dart2JsConstructedConstantMirror);
  var annotations = [];
  annotationMirrors.forEach((annotation) {
    var parameterList = annotation.type.variables.values
      .where((e) => e.isFinal)
      .map((e) => annotation.getField(e.simpleName).reflectee)
      .where((e) => e != null)
      .toList();
    if (validAnnotations.contains(annotation.type.qualifiedName)) {
      annotations.add(new Annotation(annotation.type.qualifiedName,
          parameterList));
    }
  });
  return annotations;
}

/**
 * Returns any documentation comments associated with a mirror with
 * simple markdown converted to html.
 */
String _commentToHtml(DeclarationMirror mirror) {
  String commentText;
  mirror.metadata.forEach((metadata) {
    if (metadata is CommentInstanceMirror) {
      CommentInstanceMirror comment = metadata;
      if (comment.isDocComment) {
        if (commentText == null) {
          commentText = comment.trimmedText;
        } else {
          commentText = '$commentText ${comment.trimmedText}';
        }
      }
    }
  });

  commentText = commentText == null ? '' :
      markdown.markdownToHtml(commentText.trim(), linkResolver: linkResolver,
          inlineSyntaxes: markdownSyntaxes);
  return commentText;
}

/**
 * Converts all [foo] references in comments to <a>libraryName.foo</a>.
 */
markdown.Node fixReference(String name, LibraryMirror currentLibrary,
    ClassMirror currentClass, MemberMirror currentMember) {
  var reference;
  var memberScope = currentMember == null ?
      null : currentMember.lookupInScope(name);
  if (memberScope != null) {
    reference = memberScope.qualifiedName;
  } else {
    var classScope = currentClass == null ?
        null : currentClass.lookupInScope(name);
    if (classScope != null) {
      reference = classScope.qualifiedName;
    } else {
      var libraryScope = currentLibrary == null ?
          null : currentLibrary.lookupInScope(name);
      reference = libraryScope != null ? libraryScope.qualifiedName : name;
    }
  }
  return new markdown.Element.text('a', reference);
}

/**
 * Returns a map of [Variable] objects constructed from [mirrorMap].
 */
Map<String, Variable> _variables(Map<String, VariableMirror> mirrorMap) {
  var data = {};
  // TODO(janicejl): When map to map feature is created, replace the below with
  // a filter. Issue(#9590).
  mirrorMap.forEach((String mirrorName, VariableMirror mirror) {
    _currentMember = mirror;
    if (_includePrivate || !_isHidden(mirror)) {
      entityMap[mirror.qualifiedName] = new Variable(mirrorName, mirror.isFinal,
         mirror.isStatic, mirror.isConst, _type(mirror.type),
         _commentToHtml(mirror), _annotations(mirror), mirror.qualifiedName,
         _isHidden(mirror), mirror.owner.qualifiedName);
      data[mirrorName] = entityMap[mirror.qualifiedName];
    }
  });
  return data;
}

/**
 * Returns a map of [Method] objects constructed from [mirrorMap].
 */
MethodGroup _methods(Map<String, MethodMirror> mirrorMap) {
  var group = new MethodGroup();
  mirrorMap.forEach((String mirrorName, MethodMirror mirror) {
    if (_includePrivate || !_isHidden(mirror)) {
      group.addMethod(mirror);
    }
  });
  return group;
}

/**
 * Returns the [Class] for the given [mirror] has already been created, and if
 * it does not exist, creates it.
 */
Class _class(ClassMirror mirror) {
  var clazz = entityMap[mirror.qualifiedName];
  if (clazz == null) {
    var superclass = mirror.superclass != null ?
        _class(mirror.superclass) : null;
    var interfaces =
        mirror.superinterfaces.map((interface) => _class(interface));
    clazz = new Class(mirror.simpleName, superclass, _commentToHtml(mirror),
        interfaces.toList(), _variables(mirror.variables),
        _methods(mirror.methods), _annotations(mirror), _generics(mirror),
        mirror.qualifiedName, _isHidden(mirror), mirror.owner.qualifiedName,
        mirror.isAbstract);
    if (superclass != null)
      clazz.addInherited(superclass);
    interfaces.forEach((interface) {
      clazz.addInherited(interface);
    });
    entityMap[mirror.qualifiedName] = clazz;
  }
  return clazz;
}

/**
 * Returns a map of [Class] objects constructed from [mirrorMap].
 */
ClassGroup _classes(Map<String, ClassMirror> mirrorMap) {
  var group = new ClassGroup();
  mirrorMap.forEach((String mirrorName, ClassMirror mirror) {
      group.addClass(mirror);
  });
  return group;
}

/**
 * Returns a map of [Parameter] objects constructed from [mirrorList].
 */
Map<String, Parameter> _parameters(List<ParameterMirror> mirrorList) {
  var data = {};
  mirrorList.forEach((ParameterMirror mirror) {
    _currentMember = mirror;
    data[mirror.simpleName] = new Parameter(mirror.simpleName,
        mirror.isOptional, mirror.isNamed, mirror.hasDefaultValue,
        _type(mirror.type), mirror.defaultValue,
        _annotations(mirror));
  });
  return data;
}

/**
 * Returns a map of [Generic] objects constructed from the class mirror.
 */
Map<String, Generic> _generics(ClassMirror mirror) {
  return new Map.fromIterable(mirror.typeVariables,
      key: (e) => e.toString(),
      value: (e) => new Generic(e.toString(), e.upperBound.qualifiedName));
}

/**
 * Returns a single [Type] object constructed from the Method.returnType
 * Type mirror.
 */
Type _type(TypeMirror mirror) {
  return new Type(mirror.qualifiedName, _typeGenerics(mirror));
}

/**
 * Returns a list of [Type] objects constructed from TypeMirrors.
 */
List<Type> _typeGenerics(TypeMirror mirror) {
  if (mirror is ClassMirror && !mirror.isTypedef) {
    var innerList = [];
    mirror.typeArguments.forEach((e) {
      innerList.add(new Type(e.qualifiedName, _typeGenerics(e)));
    });
    return innerList;
  }
  return [];
}

/**
 * Writes text to a file in the 'docs' directory.
 */
void _writeToFile(String text, String filename, {bool append: false}) {
  Directory dir = new Directory('docs');
  if (!dir.existsSync()) {
    dir.createSync();
  }
  File file = new File('docs/$filename');
  if (!file.existsSync()) {
    file.createSync();
  }
  file.writeAsStringSync(text, mode: append ? FileMode.APPEND : FileMode.WRITE);
}

/**
 * Transforms the map by calling toMap on each value in it.
 */
Map recurseMap(Map inputMap) {
  var outputMap = {};
  inputMap.forEach((key, value) {
    if (value is Map) {
      outputMap[key] = recurseMap(value);
    } else {
      outputMap[key] = value.toMap();
    }
  });
  return outputMap;
}

/**
 * A class representing all programming constructs, like library or class.
 */
class Indexable {
  String name;
  String qualifiedName;
  bool isPrivate;

  /// Documentation comment with converted markdown.
  String comment;

  /// Qualified Name of the owner of this Indexable Item.
  /// For Library, owner will be "";
  String owner;

  Indexable(this.name, this.comment, this.qualifiedName, this.isPrivate,
      this.owner);
  
  /// The type of this member to be used in index.txt.
  String get typeName => '';
  
  /**
   * Creates a [Map] with this [Indexable]'s name and a preview comment.
   */
  Map get previewMap {
    var finalMap = { 'name' : qualifiedName };
    if (comment != '') {
      var index = comment.indexOf('</p>');
      finalMap['preview'] = '${comment.substring(0, index)}</p>';
    }
    return finalMap;
  }
}

/**
 * A class containing contents of a Dart library.
 */
class Library extends Indexable {

  /// Top-level variables in the library.
  Map<String, Variable> variables;

  /// Top-level functions in the library.
  MethodGroup functions;

  /// Classes defined within the library
  ClassGroup classes;

  Library(String name, String comment, this.variables,
      this.functions, this.classes, bool isPrivate) : super(name, comment,
          name, isPrivate, "") {}

  /// Generates a map describing the [Library] object.
  Map toMap() => {
    'name': name,
    'qualifiedName': qualifiedName,
    'comment': comment,
    'variables': recurseMap(variables),
    'functions': functions.toMap(),
    'classes': classes.toMap()
  };
  
  String get typeName => 'library';
}

/**
 * A class containing contents of a Dart class.
 */
class Class extends Indexable {

  /// List of the names of interfaces that this class implements.
  List<Class> interfaces = [];

  /// Names of classes that extends or implements this class.
  Set<String> subclasses = new Set<String>();

  /// Top-level variables in the class.
  Map<String, Variable> variables;

  /// Inherited variables in the class.
  Map<String, Variable> inheritedVariables = {};

  /// Methods in the class.
  MethodGroup methods;

  /// Inherited methods in the class.
  MethodGroup inheritedMethods = new MethodGroup();

  /// Generic infomation about the class.
  Map<String, Generic> generics;

  Class superclass;
  bool isAbstract;

  /// List of the meta annotations on the class.
  List<String> annotations;

  Class(String name, this.superclass, String comment, this.interfaces,
      this.variables, this.methods, this.annotations, this.generics,
      String qualifiedName, bool isPrivate, String owner, this.isAbstract) 
      : super(name, comment, qualifiedName, isPrivate, owner);

  String get typeName => 'class';
  
  /**
   * Returns a list of all the parent classes.
   */
  List<Class> parent() {
    var parent = superclass == null ? [] : [superclass];
    parent.addAll(interfaces);
    return parent;
  }

  /**
   * Add all inherited variables and methods from the provided superclass.
   * If [_includePrivate] is true, it also adds the variables and methods from
   * the superclass.
   */
  void addInherited(Class superclass) {
    inheritedVariables.addAll(superclass.inheritedVariables);
    if (_isVisible(superclass)) {
      inheritedVariables.addAll(superclass.variables);
    }
    inheritedMethods.addInherited(superclass);
  }

  /**
   * Add the subclass to the class.
   *
   * If [this] is private, it will add the subclass to the list of subclasses in
   * the superclasses.
   */
  void addSubclass(Class subclass) {
    if (!_includePrivate && isPrivate) {
      if (superclass != null) superclass.addSubclass(subclass);
      interfaces.forEach((interface) {
        interface.addSubclass(subclass);
      });
    } else {
      subclasses.add(subclass.qualifiedName);
    }
  }
  
  /**
   * Check if this [Class] is an error or exception.
   */
  bool isError() {
    if (qualifiedName == 'dart.core.Error' || 
        qualifiedName == 'dart.core.Exception')
      return true;
    for (var interface in interfaces) {
      if (interface.isError()) return true;
    }
    if (superclass == null) return false;
    return superclass.isError();
  }

  /**
   * Check that the class exists in the owner library.
   *
   * If it does not exist in the owner library, it is a mixin applciation and
   * should be removed.
   */
  void makeValid() {
    var library = entityMap[owner];
    if (library != null && !library.classes.containsKey(name)) {
      this.isPrivate = true;
      // Since we are now making the mixin a private class, make all elements
      // with the mixin as an owner private too.
      entityMap.values.where((e) => e.owner == qualifiedName)
        .forEach((element) => element.isPrivate = true);
      // Move the subclass up to the next public superclass
      subclasses.forEach((subclass) => addSubclass(entityMap[subclass]));
    }
  }

  /**
   * Makes sure that all methods with inherited equivalents have comments.
   */
  void ensureComments() {
    inheritedMethods.forEach((qualifiedName, inheritedMethod) {
      var method = methods[qualifiedName];
      if (method != null) method.ensureCommentFor(inheritedMethod);
    });
  }

  /**
   * If a class extends a private superclass, find the closest public superclass
   * of the private superclass.
   */
  String validSuperclass() {
    if (superclass == null) return 'dart.core.Object';
    if (_isVisible(superclass)) return superclass.qualifiedName;
    return superclass.validSuperclass();
  }

  /// Generates a map describing the [Class] object.
  Map toMap() => {
    'name': name,
    'qualifiedName': qualifiedName,
    'comment': comment,
    'isAbstract' : isAbstract,
    'superclass': validSuperclass(),
    'implements': interfaces.where(_isVisible)
        .map((e) => e.qualifiedName).toList(),
    'subclass': subclasses.toList(),
    'variables': recurseMap(variables),
    'inheritedVariables': recurseMap(inheritedVariables),
    'methods': methods.toMap(),
    'inheritedMethods': inheritedMethods.toMap(),
    'annotations': annotations.map((a) => a.toMap()).toList(),
    'generics': recurseMap(generics)
  };
}

/**
 * A container to categorize classes into the following groups: abstract
 * classes, regular classes, typedefs, and errors.
 */
class ClassGroup {
  Map<String, Class> classes = {};
  Map<String, Typedef> typedefs = {};
  Map<String, Class> errors = {};

  void addClass(ClassMirror mirror) {
    _currentClass = mirror;
    if (mirror.isTypedef) {
      if (_includePrivate || !mirror.isPrivate) {
        entityMap[mirror.qualifiedName] = new Typedef(mirror.simpleName,
            mirror.value.returnType.qualifiedName, _commentToHtml(mirror),
            _generics(mirror), _parameters(mirror.value.parameters),
            _annotations(mirror), mirror.qualifiedName,  _isHidden(mirror),
            mirror.owner.qualifiedName);
        typedefs[mirror.simpleName] = entityMap[mirror.qualifiedName];
      }
    } else {
      var clazz = _class(mirror);
  
      // Adding inherited parent variables and methods.
      clazz.parent().forEach((parent) {
        if (_isVisible(clazz)) {
          parent.addSubclass(clazz);
        }
      });
  
      clazz.ensureComments();
  
      if (clazz.isError()) {
        errors[mirror.simpleName] = clazz;
      } else if (mirror.isClass) {
        classes[mirror.simpleName] = clazz;
      } else {
        throw new ArgumentError('${mirror.simpleName} - no class type match. ');
      }
    }
  }

  /**
   * Checks if the given name is a key for any of the Class Maps.
   */
  bool containsKey(String name) {
    return classes.containsKey(name) || errors.containsKey(name);
  }
  
  Map toMap() => {
    'class': classes.values.where(_isVisible)
      .map((e) => e.previewMap).toList(),
    'typedef': recurseMap(typedefs),
    'error': errors.values.where(_isVisible)
      .map((e) => e.previewMap).toList()
  };
}

class Typedef extends Indexable {
  String returnType;

  Map<String, Parameter> parameters;

  /// Generic information about the typedef.
  Map<String, Generic> generics;

  /// List of the meta annotations on the typedef.
  List<String> annotations;

  Typedef(String name, this.returnType, String comment, this.generics,
      this.parameters, this.annotations,
      String qualifiedName, bool isPrivate, String owner) 
        : super(name, comment, qualifiedName, isPrivate, owner);

  Map toMap() => {
    'name': name,
    'qualifiedName': qualifiedName,
    'comment': comment,
    'return': returnType,
    'parameters': recurseMap(parameters),
    'annotations': annotations.map((a) => a.toMap()).toList(),
    'generics': recurseMap(generics)
  };
  
  String get typeName => 'typedef';
}

/**
 * A class containing properties of a Dart variable.
 */
class Variable extends Indexable {

  bool isFinal;
  bool isStatic;
  bool isConst;
  Type type;

  /// List of the meta annotations on the variable.
  List<String> annotations;

  Variable(String name, this.isFinal, this.isStatic, this.isConst, this.type,
      String comment, this.annotations, String qualifiedName, bool isPrivate,
      String owner) : super(name, comment, qualifiedName, isPrivate, owner);

  /// Generates a map describing the [Variable] object.
  Map toMap() => {
    'name': name,
    'qualifiedName': qualifiedName,
    'comment': comment,
    'final': isFinal.toString(),
    'static': isStatic.toString(),
    'constant': isConst.toString(),
    'type': new List.filled(1, type.toMap()),
    'annotations': annotations.map((a) => a.toMap()).toList()
  };
  
  String get typeName => 'property';
}

/**
 * A class containing properties of a Dart method.
 */
class Method extends Indexable {

  /// Parameters for this method.
  Map<String, Parameter> parameters;

  bool isStatic;
  bool isAbstract;
  bool isConst;
  bool isConstructor;
  bool isGetter;
  bool isSetter;
  bool isOperator;
  Type returnType;

  /// Qualified name to state where the comment is inherited from.
  String commentInheritedFrom = "";

  /// List of the meta annotations on the method.
  List<String> annotations;

  Method(String name, this.isStatic, this.isAbstract, this.isConst,
      this.returnType, String comment, this.parameters, this.annotations,
      String qualifiedName, bool isPrivate, String owner, this.isConstructor,
      this.isGetter, this.isSetter, this.isOperator) 
        : super(name, comment, qualifiedName, isPrivate, owner);

  /**
   * Makes sure that the method with an inherited equivalent have comments.
   */
  void ensureCommentFor(Method inheritedMethod) {
    if (comment.isNotEmpty) return;
    entityMap[inheritedMethod.owner].ensureComments();
    comment = inheritedMethod.comment;
    commentInheritedFrom = inheritedMethod.commentInheritedFrom == '' ?
        inheritedMethod.qualifiedName : inheritedMethod.commentInheritedFrom;
  }

  /// Generates a map describing the [Method] object.
  Map toMap() => {
    'name': name,
    'qualifiedName': qualifiedName,
    'comment': comment,
    'commentFrom': commentInheritedFrom,
    'static': isStatic.toString(),
    'abstract': isAbstract.toString(),
    'constant': isConst.toString(),
    'return': new List.filled(1, returnType.toMap()),
    'parameters': recurseMap(parameters),
    'annotations': annotations.map((a) => a.toMap()).toList()
  };
  
  String get typeName => isConstructor ? 'constructor' :
    isGetter ? 'getter' : isSetter ? 'setter' :
    isOperator ? 'operator' : 'method';
}

/**
 * A container to categorize methods into the following groups: setters,
 * getters, constructors, operators, regular methods.
 */
class MethodGroup {
  Map<String, Method> setters = {};
  Map<String, Method> getters = {};
  Map<String, Method> constructors = {};
  Map<String, Method> operators = {};
  Map<String, Method> regularMethods = {};

  void addMethod(MethodMirror mirror) {
    var method = new Method(mirror.simpleName, mirror.isStatic,
        mirror.isAbstract, mirror.isConstConstructor, _type(mirror.returnType),
        _commentToHtml(mirror), _parameters(mirror.parameters),
        _annotations(mirror), mirror.qualifiedName, _isHidden(mirror),
        mirror.owner.qualifiedName, mirror.isConstructor, mirror.isGetter,
        mirror.isSetter, mirror.isOperator);
    entityMap[mirror.qualifiedName] = method;
    _currentMember = mirror;
    if (mirror.isSetter) {
      setters[mirror.simpleName] = method;
    } else if (mirror.isGetter) {
      getters[mirror.simpleName] = method;
    } else if (mirror.isConstructor) {
      constructors[mirror.simpleName] = method;
    } else if (mirror.isOperator) {
      operators[mirror.simpleName] = method;
    } else if (mirror.isRegularMethod) {
      regularMethods[mirror.simpleName] = method;
    } else {
      throw new ArgumentError('${mirror.simpleName} - no method type match');
    }
  }

  void addInherited(Class parent) {
    setters.addAll(parent.inheritedMethods.setters);
    getters.addAll(parent.inheritedMethods.getters);
    operators.addAll(parent.inheritedMethods.operators);
    regularMethods.addAll(parent.inheritedMethods.regularMethods);
    if (_isVisible(parent)) {
      setters.addAll(parent.methods.setters);
      getters.addAll(parent.methods.getters);
      operators.addAll(parent.methods.operators);
      regularMethods.addAll(parent.methods.regularMethods);
    }
  }

  Map toMap() => {
    'setters': recurseMap(setters),
    'getters': recurseMap(getters),
    'constructors': recurseMap(constructors),
    'operators': recurseMap(operators),
    'methods': recurseMap(regularMethods)
  };

  Method operator [](String qualifiedName) {
    if (setters.containsKey(qualifiedName)) return setters[qualifiedName];
    if (getters.containsKey(qualifiedName)) return getters[qualifiedName];
    if (operators.containsKey(qualifiedName)) return operators[qualifiedName];
    if (regularMethods.containsKey(qualifiedName)) {
      return regularMethods[qualifiedName];
    }
    return null;
  }

  void forEach(void f(String key, Method value)) {
    setters.forEach(f);
    getters.forEach(f);
    operators.forEach(f);
    regularMethods.forEach(f);
  }
}

/**
 * A class containing properties of a Dart method/function parameter.
 */
class Parameter {

  String name;
  bool isOptional;
  bool isNamed;
  bool hasDefaultValue;
  Type type;
  String defaultValue;

  /// List of the meta annotations on the parameter.
  List<String> annotations;

  Parameter(this.name, this.isOptional, this.isNamed, this.hasDefaultValue,
      this.type, this.defaultValue, this.annotations);

  /// Generates a map describing the [Parameter] object.
  Map toMap() => {
    'name': name,
    'optional': isOptional.toString(),
    'named': isNamed.toString(),
    'default': hasDefaultValue.toString(),
    'type': new List.filled(1, type.toMap()),
    'value': defaultValue,
    'annotations': annotations.map((a) => a.toMap()).toList()
  };
}

/**
 * A class containing properties of a Generic.
 */
class Generic {
  String name;
  String type;

  Generic(this.name, this.type);

  Map toMap() => {
    'name': name,
    'type': type
  };
}

/**
 * Holds the name of a return type, and its generic type parameters.
 *
 * Return types are of a form [outer]<[inner]>.
 * If there is no [inner] part, [inner] will be an empty list.
 *
 * For example:
 *        int size()
 *          "return" :
 *            - "outer" : "dart.core.int"
 *              "inner" :
 *
 *        List<String> toList()
 *          "return" :
 *            - "outer" : "dart.core.List"
 *              "inner" :
 *                - "outer" : "dart.core.String"
 *                  "inner" :
 *
 *        Map<String, List<int>>
 *          "return" :
 *            - "outer" : "dart.core.Map"
 *              "inner" :
 *                - "outer" : "dart.core.String"
 *                  "inner" :
 *                - "outer" : "dart.core.List"
 *                  "inner" :
 *                    - "outer" : "dart.core.int"
 *                      "inner" :
 */
class Type {
  String outer;
  List<Type> inner;

  Type(this.outer, this.inner);

  Map toMap() => {
    'outer': outer,
    'inner': inner.map((e) => e.toMap()).toList()
  };
}

/**
 * Holds the name of the annotation, and its parameters.
 */
class Annotation {
  String qualifiedName;
  List<String> parameters;

  Annotation(this.qualifiedName, this.parameters);

  Map toMap() => {
    'name': qualifiedName,
    'parameters': parameters
  };
}