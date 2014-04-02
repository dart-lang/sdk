// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library docgen.models;

import 'dart:io';

import 'package:markdown/markdown.dart' as markdown;

import '../../../../sdk/lib/_internal/compiler/implementation/mirrors/source_mirrors.dart';
import '../../../../sdk/lib/_internal/compiler/implementation/mirrors/mirrors_util.dart'
    as dart2js_util;
import '../../../../sdk/lib/_internal/compiler/implementation/mirrors/dart2js_mirrors.dart'
    as dart2js_mirrors;

import 'library_helpers.dart';
import 'mdn.dart';
import 'model_helpers.dart';
import 'package_helpers.dart';

/// Docgen representation of an item to be documented, that wraps around a
/// dart2js mirror.
abstract class MirrorBased<TMirror extends DeclarationMirror> {
  /// The original dart2js mirror around which this object wraps.
  TMirror get mirror;

  /// Return an informative [Object.toString] for debugging.
  String toString() => "${super.toString()} - $mirror";
}

/// A Docgen wrapper around the dart2js mirror for a generic type.
class Generic extends MirrorBased<TypeVariableMirror> {
  final TypeVariableMirror mirror;

  Generic(this.mirror);

  Map toMap() => {
    'name': dart2js_util.nameOf(mirror),
    'type': dart2js_util.qualifiedNameOf(mirror.upperBound)
  };
}

/// For types that we do not explicitly create or have not yet created in our
/// entity map (like core types).
class DummyMirror implements Indexable {
  final DeclarationMirror mirror;
  /// The library that contains this element, if any. Used as a hint to help
  /// determine which object we're referring to when looking up this mirror in
  /// our map.
  final Indexable owner;
  DummyMirror(this.mirror, [this.owner]);

  String get docName {
    if (mirror == null) return '';
    if (mirror is LibraryMirror) {
      return dart2js_util.qualifiedNameOf(mirror).replaceAll('.','-');
    }
    var mirrorOwner = mirror.owner;
    if (mirrorOwner == null) return dart2js_util.qualifiedNameOf(mirror);
    var simpleName = dart2js_util.nameOf(mirror);
    if (mirror is MethodMirror && (mirror as MethodMirror).isConstructor) {
      // We name constructors specially -- repeating the class name and a
      // "-" to separate the constructor from its name (if any).
      simpleName = '${dart2js_util.nameOf(mirrorOwner)}-$simpleName';
    }
    return getDocgenObject(mirrorOwner, owner).docName + '.' +
        simpleName;
  }

  bool get isPrivate => mirror == null? false : mirror.isPrivate;

  String get packageName {
    var libMirror = _getOwningLibraryFromMirror(mirror);
    if (libMirror != null) {
      return getPackageName(libMirror);
    }
    return '';
  }

  String get packagePrefix => packageName == null || packageName.isEmpty ?
      '' : '$packageName/';

  LibraryMirror _getOwningLibraryFromMirror(DeclarationMirror mirror) {
    if (mirror is LibraryMirror) return mirror;
    if (mirror == null) return null;
    return _getOwningLibraryFromMirror(mirror.owner);
  }

  noSuchMethod(Invocation invocation) {
    throw new UnimplementedError(invocation.memberName.toString());
  }
}

/// An item that is categorized in our mirrorToDocgen map, as a distinct,
/// searchable element.
///
/// These are items that refer to concrete entities (a Class, for example,
/// but not a Type, which is a "pointer" to a class) that we wish to be
/// globally resolvable. This includes things such as class methods and
/// variables, but parameters for methods are not "Indexable" as we do not want
/// the user to be able to search for a method based on its parameter names!
/// The set of indexable items also includes Typedefs, since the user can refer
/// to them as concrete entities in a particular scope.
abstract class Indexable<TMirror extends DeclarationMirror>
    extends MirrorBased<TMirror> {

  Library get owningLibrary => owner.owningLibrary;

  String get qualifiedName => fileName;
  final TMirror mirror;
  final bool isPrivate;
  /// The comment text pre-resolution. We keep this around because inherited
  /// methods need to resolve links differently from the superclass.
  String _unresolvedComment = '';

  Indexable(TMirror mirror)
      : this.mirror = mirror,
        this.isPrivate = isHidden(mirror) {

    var map = mirrorToDocgen[dart2js_util.qualifiedNameOf(this.mirror)];
    if (map == null) map = new Map<String, Set<Indexable>>();

    var set = map[owner.docName];
    if (set == null) set = new Set<Indexable>();
    set.add(this);
    map[owner.docName] = set;
    mirrorToDocgen[dart2js_util.qualifiedNameOf(this.mirror)] = map;
  }

  /// Returns this object's qualified name, but following the conventions
  /// we're using in Dartdoc, which is that library names with dots in them
  /// have them replaced with hyphens.
  String get docName;

  /// Converts all [foo] references in comments to <a>libraryName.foo</a>.
  markdown.Node fixReference(String name) {
    // Attempt the look up the whole name up in the scope.
    String elementName = findElementInScope(name);
    if (elementName != null) {
      return new markdown.Element.text('a', elementName);
    }
    return fixComplexReference(name);
  }

  /// Look for the specified name starting with the current member, and
  /// progressively working outward to the current library scope.
  String findElementInScope(String name) =>
      findElementInScopeWithPrefix(name, packagePrefix);

  /// The reference to this element based on where it is printed as a
  /// documentation file and also the unique URL to refer to this item.
  ///
  /// The qualified name (for URL purposes) and the file name are the same,
  /// of the form packageName/ClassName or packageName/ClassName.methodName.
  /// This defines both the URL and the directory structure.
  String get fileName =>  packagePrefix + ownerPrefix + name;

  /// The full docName of the owner element, appended with a '.' for this
  /// object's name to be appended.
  String get ownerPrefix => owner.docName != '' ? owner.docName + '.' : '';

  /// The prefix String to refer to the package that this item is in, for URLs
  /// and comment resolution.
  ///
  /// The prefix can be prepended to a qualified name to get a fully unique
  /// name among all packages.
  String get packagePrefix => '';

  /// Documentation comment with converted markdown and all links resolved.
  String _comment;

  /// Accessor to documentation comment with markdown converted to html and all
  /// links resolved.
  String get comment {
    if (_comment != null) return _comment;

    _comment = _commentToHtml();
    if (_comment.isEmpty) {
      _comment = _mdnComment();
    }
    return _comment;
  }

  void set comment(x) {
    _comment = x;
  }

  /// The simple name to refer to this item.
  String get name => dart2js_util.nameOf(mirror);

  /// Accessor to the parent item that owns this item.
  ///
  /// "Owning" is defined as the object one scope-level above which this item
  /// is defined. Ex: The owner for a top level class, would be its enclosing
  /// library. The owner of a local variable in a method would be the enclosing
  /// method.
  Indexable get owner => new DummyMirror(mirror.owner);

  /// Generates MDN comments from database.json.
  String _mdnComment();

  /// The type of this member to be used in index.txt.
  String get typeName => '';

  /// Creates a [Map] with this [Indexable]'s name and a preview comment.
  Map get previewMap {
    var finalMap = { 'name' : name, 'qualifiedName' : qualifiedName };
    var preview = _preview;
    if(preview != null) finalMap['preview'] = preview;
    return finalMap;
  }

  String get _preview {
    if (comment != '') {
      var index = comment.indexOf('</p>');
      return index > 0 ?
          '${comment.substring(0, index)}</p>' :
          '<p><i>Comment preview not available</i></p>';
    }
    return null;
  }

  /// Accessor to obtain the raw comment text for a given item, _without_ any
  /// of the links resolved.
  String get _commentText {
    String commentText;
    mirror.metadata.forEach((metadata) {
      if (metadata is CommentInstanceMirror) {
        CommentInstanceMirror comment = metadata;
        if (comment.isDocComment) {
          if (commentText == null) {
            commentText = comment.trimmedText;
          } else {
            commentText = '$commentText\n${comment.trimmedText}';
          }
        }
      }
    });
    return commentText;
  }

  /// Returns any documentation comments associated with a mirror with
  /// simple markdown converted to html.
  ///
  /// By default we resolve any comment references within our own scope.
  /// However, if a method is inherited, we want the inherited comments, but
  /// links to the subclasses's version of the methods.
  String _commentToHtml([Indexable resolvingScope]) {
    if (resolvingScope == null) resolvingScope = this;
    var commentText = _commentText;
    _unresolvedComment = commentText;

    var linkResolver = (name) => resolvingScope.fixReference(name);
    commentText = commentText == null ? '' :
        markdown.markdownToHtml(commentText.trim(), linkResolver: linkResolver,
            inlineSyntaxes: MARKDOWN_SYNTAXES);
    return commentText;
  }

  /// Return a map representation of this type.
  Map toMap();

  /// Expand the method map [mapToExpand] into a more detailed map that
  /// separates out setters, getters, constructors, operators, and methods.
  Map _expandMethodMap(Map<String, Method> mapToExpand) => {
    'setters': recurseMap(filterMap(mapToExpand,
        (key, val) => val.mirror.isSetter)),
    'getters': recurseMap(filterMap(mapToExpand,
        (key, val) => val.mirror.isGetter)),
    'constructors': recurseMap(filterMap(mapToExpand,
        (key, val) => val.mirror.isConstructor)),
    'operators': recurseMap(filterMap(mapToExpand,
        (key, val) => val.mirror.isOperator)),
    'methods': recurseMap(filterMap(mapToExpand,
        (key, val) => val.mirror.isRegularMethod && !val.mirror.isOperator))
  };

  /// Accessor to determine if this item and all of its owners are visible.
  bool get isVisible => isFullChainVisible(this);

  /// Returns true if [mirror] is the correct type of mirror that this Docgen
  /// object wraps. (Workaround for the fact that Types are not first class.)
  bool isValidMirror(DeclarationMirror mirror);
}

/// A class containing contents of a Dart library.
class Library extends Indexable {
  final Map<String, Class> classes = {};
  final Map<String, Typedef> typedefs = {};
  final Map<String, Class> errors = {};

  /// Top-level variables in the library.
  Map<String, Variable> variables;

  /// Top-level functions in the library.
  Map<String, Method> functions;

  String packageName = '';
  bool _hasBeenCheckedForPackage = false;
  String packageIntro;

  Library get owningLibrary => this;

  /// Returns the [Library] for the given [mirror] if it has already been
  /// created, else creates it.
  factory Library(LibraryMirror mirror) {
    var library = getDocgenObject(mirror);
    if (library is DummyMirror) {
      library = new Library._(mirror);
    }
    return library;
  }

  Library._(LibraryMirror libraryMirror) : super(libraryMirror) {
    var exported = calcExportedItems(libraryMirror);
    var exportedClasses = addAll(exported['classes'],
        dart2js_util.typesOf(libraryMirror.declarations));
    updateLibraryPackage(mirror);
    exportedClasses.forEach((String mirrorName, TypeMirror mirror) {
        if (mirror is TypedefMirror) {
          // This is actually a Dart2jsTypedefMirror, and it does define value,
          // but we don't have visibility to that type.
          if (includePrivateMembers || !mirror.isPrivate) {
            typedefs[dart2js_util.nameOf(mirror)] = new Typedef(mirror, this);
          }
        } else if (mirror is ClassMirror) {
          var clazz = new Class(mirror, this);

          if (clazz.isError()) {
            errors[dart2js_util.nameOf(mirror)] = clazz;
          } else {
            classes[dart2js_util.nameOf(mirror)] = clazz;
          }
        } else {
          throw new ArgumentError(
              '${dart2js_util.nameOf(mirror)} - no class type match. ');
        }
    });
    this.functions = createMethods(addAll(exported['methods'],
        libraryMirror.declarations.values.where(
            (mirror) => mirror is MethodMirror)).values, this);
    this.variables = createVariables(addAll(exported['variables'],
        dart2js_util.variablesOf(libraryMirror.declarations)).values, this);
  }

  /// Look for the specified name starting with the current member, and
  /// progressively working outward to the current library scope.
  String findElementInScope(String name) {
    var lookupFunc = determineLookupFunc(name);
    var libraryScope = lookupFunc(mirror, name);
    if (libraryScope != null) {
      var result = getDocgenObject(libraryScope, this);
      if (result is DummyMirror) return packagePrefix + result.docName;
      return result.packagePrefix + result.docName;
    }
    return super.findElementInScope(name);
  }

  String _mdnComment() => '';

  /// For a library's [mirror], determine the name of the package (if any) we
  /// believe it came from (because of its file URI).
  ///
  /// If no package could be determined, we return an empty string.
  void updateLibraryPackage(LibraryMirror mirror) {
    if (mirror == null) return;
    if (_hasBeenCheckedForPackage) return;
    _hasBeenCheckedForPackage = true;
    if (mirror.uri.scheme != 'file') return;
    packageName = getPackageName(mirror);
    // Associate the package readme with all the libraries. This is a bit
    // wasteful, but easier than trying to figure out which partial match
    // is best.
    packageIntro = _packageIntro(getPackageDirectory(mirror));
  }

  String _packageIntro(packageDir) {
    if (packageDir == null) return null;
    var dir = new Directory(packageDir);
    var files = dir.listSync();
    var readmes = files.where((FileSystemEntity each) => (each is File &&
        each.path.substring(packageDir.length + 1, each.path.length)
          .startsWith('README'))).toList();
    if (readmes.isEmpty) return '';
    // If there are multiples, pick the shortest name.
    readmes.sort((a, b) => a.path.length.compareTo(b.path.length));
    var readme = readmes.first;
    var linkResolver = (name) => globalFixReference(name);
    var contents = markdown.markdownToHtml(readme
      .readAsStringSync(), linkResolver: linkResolver,
      inlineSyntaxes: MARKDOWN_SYNTAXES);
    return contents;
  }

  String get packagePrefix => packageName == null || packageName.isEmpty ?
      '' : '$packageName/';

  Map get previewMap {
    var basic = super.previewMap;
    basic['packageName'] = packageName;
    if (packageIntro != null) {
      basic['packageIntro'] = packageIntro;
    }
    return basic;
  }

  String get name => docName;

  String get docName {
    return dart2js_util.qualifiedNameOf(mirror).replaceAll('.','-');
  }

  /// Checks if the given name is a key for any of the Class Maps.
  bool containsKey(String name) =>
      classes.containsKey(name) || errors.containsKey(name);

  /// Generates a map describing the [Library] object.
  Map toMap() => {
    'name': name,
    'qualifiedName': qualifiedName,
    'comment': comment,
    'variables': recurseMap(variables),
    'functions': _expandMethodMap(functions),
    'classes': {
      'class': classes.values.where((c) => c.isVisible)
        .map((e) => e.previewMap).toList(),
      'typedef': recurseMap(typedefs),
      'error': errors.values.where((e) => e.isVisible)
          .map((e) => e.previewMap).toList()
    },
    'packageName': packageName,
    'packageIntro' : packageIntro
  };

  String get typeName => 'library';

  bool isValidMirror(DeclarationMirror mirror) => mirror is LibraryMirror;
}

abstract class OwnedIndexable<TMirror extends DeclarationMirror>
    extends Indexable<TMirror> {
  /// List of the meta annotations on this item.
  final List<Annotation> annotations;

  /// The object one scope-level above which this item is defined.
  ///
  /// Ex: The owner for a top level class, would be its enclosing library.
  /// The owner of a local variable in a method would be the enclosing method.
  final Indexable owner;

  /// Returns this object's qualified name, but following the conventions
  /// we're using in Dartdoc, which is that library names with dots in them
  /// have them replaced with hyphens.
  String get docName => owner.docName + '.' + dart2js_util.nameOf(mirror);

  OwnedIndexable(DeclarationMirror mirror, Indexable owner)
      : annotations = createAnnotations(mirror, owner.owningLibrary),
        this.owner = owner,
        super(mirror);

  /// Generates MDN comments from database.json.
  String _mdnComment() {
    var domAnnotation = this.annotations.firstWhere(
        (e) => e.mirror.qualifiedName == #metadata.DomName,
        orElse: () => null);
    if (domAnnotation == null) return '';
    var domName = domAnnotation.parameters.single;

    return mdnComment(rootDirectory, logger, domName);
  }

  String get packagePrefix => owner.packagePrefix;
}

/// A class containing contents of a Dart class.
class Class
    extends OwnedIndexable<dart2js_mirrors.Dart2JsInterfaceTypeMirror>
    implements Comparable<Class> {

  /// List of the names of interfaces that this class implements.
  List<Class> interfaces = [];

  /// Names of classes that extends or implements this class.
  Set<Class> subclasses = new Set<Class>();

  /// Top-level variables in the class.
  Map<String, Variable> variables;

  /// Inherited variables in the class.
  final Map<String, Variable> inheritedVariables = {};

  /// Methods in the class.
  Map<String, Method> methods;

  final Map<String, Method> inheritedMethods = new Map<String, Method>();

  /// Generic infomation about the class.
  final Map<String, Generic> generics;

  Class superclass;
  bool get isAbstract => mirror.isAbstract;

  /// Make sure that we don't check for inherited comments more than once.
  bool _commentsEnsured = false;

  /// Returns the [Class] for the given [mirror] if it has already been created,
  /// else creates it.
  factory Class(ClassMirror mirror, Library owner) {
    var clazz = getDocgenObject(mirror, owner);
    if (clazz is DummyMirror) {
      clazz = new Class._(mirror, owner);
    }
    return clazz;
  }

  /// Called when we are constructing a superclass or interface class, but it
  /// is not known if it belongs to the same owner as the original class. In
  /// this case, we create an object whose owner is what the original mirror
  /// says it is.
  factory Class._possiblyDifferentOwner(ClassMirror mirror,
      Library originalOwner) {
    if (mirror.owner is LibraryMirror) {
      var realOwner = getDocgenObject(mirror.owner);
      if (realOwner is Library) {
        return new Class(mirror, realOwner);
      } else {
        return new Class(mirror, originalOwner);
      }
    } else {
      return new Class(mirror, originalOwner);
    }
  }

  Class._(ClassSourceMirror classMirror, Indexable owner)
      : generics = createGenerics(classMirror),
        super(classMirror, owner) {

    // The reason we do this madness is the superclass and interface owners may
    // not be this class's owner!! Example: BaseClient in http pkg.
    var superinterfaces = classMirror.superinterfaces.map(
        (interface) => new Class._possiblyDifferentOwner(interface, owner));
    this.superclass = classMirror.superclass == null? null :
        new Class._possiblyDifferentOwner(classMirror.superclass, owner);

    interfaces = superinterfaces.toList();
    variables = createVariables(
        dart2js_util.variablesOf(classMirror.declarations), this);
    methods = createMethods(classMirror.declarations.values.where(
        (mirror) => mirror is MethodMirror), this);

    // Tell superclass that you are a subclass, unless you are not
    // visible or an intermediary mixin class.
    if (!classMirror.isNameSynthetic && isVisible && superclass != null) {
      superclass.addSubclass(this);
    }

    if (this.superclass != null) addInherited(superclass);
    interfaces.forEach((interface) => addInherited(interface));
  }

  String _lookupInClassAndSuperclasses(String name) {
    var lookupFunc = determineLookupFunc(name);
    var classScope = this;
    while (classScope != null) {
      var classFunc = lookupFunc(classScope.mirror, name);
      if (classFunc != null) {
        return packagePrefix + getDocgenObject(classFunc, owner).docName;
      }
      classScope = classScope.superclass;
    }
    return null;
  }

  /// Look for the specified name starting with the current member, and
  /// progressively working outward to the current library scope.
  String findElementInScope(String name) {
    var lookupFunc = determineLookupFunc(name);
    var result = _lookupInClassAndSuperclasses(name);
    if (result != null) {
      return result;
    }
    result = owner.findElementInScope(name);
    return result == null ? super.findElementInScope(name) : result;
  }

  String get typeName => 'class';

  /// Add all inherited variables and methods from the provided superclass.
  /// If [_includePrivate] is true, it also adds the variables and methods from
  /// the superclass.
  void addInherited(Class superclass) {
    inheritedVariables.addAll(superclass.inheritedVariables);
    inheritedVariables.addAll(_allButStatics(superclass.variables));
    addInheritedMethod(superclass, this);
  }

  /** [newParent] refers to the actual class is currently using these methods.
   * which may be different because with the mirror system, we only point to the
   * original canonical superclasse's method.
   */
  void addInheritedMethod(Class parent, Class newParent) {
    parent.inheritedMethods.forEach((name, method) {
      if(!method.mirror.isConstructor){
        inheritedMethods[name] = new Method(method.mirror, newParent, method);
      }}
    );
    _allButStatics(parent.methods).forEach((name, method) {
      if (!method.mirror.isConstructor) {
        inheritedMethods[name] = new Method(method.mirror, newParent, method);
      }}
    );
  }

  /// Remove statics from the map of inherited items before adding them.
  Map _allButStatics(Map items) {
    var result = {};
    items.forEach((name, item) {
      if (!item.isStatic) {
        result[name] = item;
      }
    });
    return result;
  }

  /// Add the subclass to the class.
  ///
  /// If [this] is private (or an intermediary mixin class), it will add the
  /// subclass to the list of subclasses in the superclasses.
  void addSubclass(Class subclass) {
    if (docName == 'dart-core.Object') return;

    if (!includePrivateMembers && isPrivate || mirror.isNameSynthetic) {
      if (superclass != null) superclass.addSubclass(subclass);
      interfaces.forEach((interface) {
        interface.addSubclass(subclass);
      });
    } else {
      subclasses.add(subclass);
    }
  }

  /// Check if this [Class] is an error or exception.
  bool isError() {
    if (qualifiedName == 'dart-core.Error' ||
        qualifiedName == 'dart-core.Exception')
      return true;
    for (var interface in interfaces) {
      if (interface.isError()) return true;
    }
    if (superclass == null) return false;
    return superclass.isError();
  }

  /// Makes sure that all methods with inherited equivalents have comments.
  void ensureComments() {
    if (_commentsEnsured) return;
    _commentsEnsured = true;
    if (superclass != null) superclass.ensureComments();
    inheritedMethods.forEach((qualifiedName, inheritedMethod) {
      var method = methods[qualifiedName];
      if (method != null) {
        // if we have overwritten this method in this class, we still provide
        // the opportunity to inherit the comments.
        method.ensureCommentFor(inheritedMethod);
      }
    });
    // we need to populate the comments for all methods. so that the subclasses
    // can get for their inherited versions the comments.
    methods.forEach((qualifiedName, method) {
      if (!method.mirror.isConstructor) method.ensureCommentFor(method);
    });
  }

  /// If a class extends a private superclass, find the closest public
  /// superclass of the private superclass.
  String validSuperclass() {
    if (superclass == null) return 'dart-core.Object';
    if (superclass.isVisible) return superclass.qualifiedName;
    return superclass.validSuperclass();
  }

  /// Generates a map describing the [Class] object.
  Map toMap() => {
    'name': name,
    'qualifiedName': qualifiedName,
    'comment': comment,
    'isAbstract' : isAbstract,
    'superclass': validSuperclass(),
    'implements': interfaces.where((i) => i.isVisible)
        .map((e) => e.qualifiedName).toList(),
    'subclass': (subclasses.toList()..sort())
        .map((x) => x.qualifiedName).toList(),
    'variables': recurseMap(variables),
    'inheritedVariables': recurseMap(inheritedVariables),
    'methods': _expandMethodMap(methods),
    'inheritedMethods': _expandMethodMap(inheritedMethods),
    'annotations': annotations.map((a) => a.toMap()).toList(),
    'generics': recurseMap(generics)
  };

  int compareTo(Class other) => name.compareTo(other.name);

  bool isValidMirror(DeclarationMirror mirror) => mirror is ClassMirror;
}

class Typedef extends OwnedIndexable {
  final String returnType;

  final Map<String, Parameter> parameters;

  /// Generic information about the typedef.
  final Map<String, Generic> generics;

  /// Returns the [Library] for the given [mirror] if it has already been
  /// created, else creates it.
  factory Typedef(TypedefMirror mirror, Library owningLibrary) {
    var aTypedef = getDocgenObject(mirror, owningLibrary);
    if (aTypedef is DummyMirror) {
      aTypedef = new Typedef._(mirror, owningLibrary);
    }
    return aTypedef;
  }

  Typedef._(TypedefMirror mirror, Library owningLibrary)
      : returnType = getDocgenObject(mirror.referent.returnType).docName,
        generics = createGenerics(mirror),
        parameters = createParameters(mirror.referent.parameters,
            owningLibrary),
        super(mirror, owningLibrary);

  Map toMap() {
    var map = {
      'name': name,
      'qualifiedName': qualifiedName,
      'comment': comment,
      'return': returnType,
      'parameters': recurseMap(parameters),
      'annotations': annotations.map((a) => a.toMap()).toList(),
      'generics': recurseMap(generics)
    };

    // Typedef is displayed on the library page as a class, so a preview is
    // added manually
    var preview = _preview;
    if(preview != null) map['preview'] = preview;

    return map;
  }

  markdown.Node fixReference(String name) => null;

  String get typeName => 'typedef';

  bool isValidMirror(DeclarationMirror mirror) => mirror is TypedefMirror;
}

/// A class containing properties of a Dart variable.
class Variable extends OwnedIndexable {

  bool isFinal;
  bool isStatic;
  bool isConst;
  Type type;
  String _variableName;

  factory Variable(String variableName, VariableMirror mirror,
      Indexable owner) {
    var variable = getDocgenObject(mirror);
    if (variable is DummyMirror) {
      return new Variable._(variableName, mirror, owner);
    }
    return variable;
  }

  Variable._(this._variableName, VariableMirror mirror, Indexable owner) :
      super(mirror, owner) {
    isFinal = mirror.isFinal;
    isStatic = mirror.isStatic;
    isConst = mirror.isConst;
    type = new Type(mirror.type, owner.owningLibrary);
  }

  String get name => _variableName;

  /// Generates a map describing the [Variable] object.
  Map toMap() => {
    'name': name,
    'qualifiedName': qualifiedName,
    'comment': comment,
    'final': isFinal,
    'static': isStatic,
    'constant': isConst,
    'type': new List.filled(1, type.toMap()),
    'annotations': annotations.map((a) => a.toMap()).toList()
  };

  String get typeName => 'property';

  get comment {
    if (_comment != null) return _comment;
    if (owner is Class) {
      (owner as Class).ensureComments();
    }
    return super.comment;
  }

  String findElementInScope(String name) {
    var lookupFunc = determineLookupFunc(name);
    var result = lookupFunc(mirror, name);
    if (result != null) {
      result = getDocgenObject(result);
      if (result is DummyMirror) return packagePrefix + result.docName;
      return result.packagePrefix + result.docName;
    }

    if (owner != null) {
      var result = owner.findElementInScope(name);
      if (result != null) {
        return result;
      }
    }
    return super.findElementInScope(name);
  }

  bool isValidMirror(DeclarationMirror mirror) => mirror is VariableMirror;
}

/// A class containing properties of a Dart method.
class Method extends OwnedIndexable {

  /// Parameters for this method.
  final Map<String, Parameter> parameters;

  final bool isStatic;
  final bool isAbstract;
  final bool isConst;
  final Type returnType;
  Method methodInheritedFrom;

  /// Qualified name to state where the comment is inherited from.
  String commentInheritedFrom = "";

  factory Method(MethodMirror mirror, Indexable owner,
      [Method methodInheritedFrom]) {
    var method = getDocgenObject(mirror, owner);
    if (method is DummyMirror) {
      method = new Method._(mirror, owner, methodInheritedFrom);
    }
    return method;
  }

  Method._(MethodMirror mirror, Indexable owner, this.methodInheritedFrom)
      : returnType = new Type(mirror.returnType, owner.owningLibrary),
        isStatic = mirror.isStatic,
        isAbstract = mirror.isAbstract,
        isConst = mirror.isConstConstructor,
        parameters = createParameters(mirror.parameters, owner),
        super(mirror, owner);

  Method get originallyInheritedFrom => methodInheritedFrom == null ?
      this : methodInheritedFrom.originallyInheritedFrom;

  /// Look for the specified name starting with the current member, and
  /// progressively working outward to the current library scope.
  String findElementInScope(String name) {
    var lookupFunc = determineLookupFunc(name);

    var memberScope = lookupFunc(this.mirror, name);
    if (memberScope != null) {
      // do we check for a dummy mirror returned here and look up with an owner
      // higher ooooor in getDocgenObject do we include more things in our
      // lookup
      var result = getDocgenObject(memberScope, owner);
      if (result is DummyMirror && owner.owner != null
          && owner.owner is! DummyMirror) {
        var aresult = getDocgenObject(memberScope, owner.owner);
        if (aresult is! DummyMirror) result = aresult;
      }
      if (result is DummyMirror) return packagePrefix + result.docName;
      return result.packagePrefix + result.docName;
    }

    if (owner != null) {
      var result = owner.findElementInScope(name);
      if (result != null) return result;
    }
    return super.findElementInScope(name);
  }

  String get docName {
    if ((mirror as MethodMirror).isConstructor) {
      // We name constructors specially -- including the class name again and a
      // "-" to separate the constructor from its name (if any).
      return '${owner.docName}.${dart2js_util.nameOf(mirror.owner)}-'
             '${dart2js_util.nameOf(mirror)}';
    }
    return super.docName;
  }

  String get fileName => packagePrefix + docName;

  /// Makes sure that the method with an inherited equivalent have comments.
  void ensureCommentFor(Method inheritedMethod) {
    if (comment.isNotEmpty) return;

    comment = inheritedMethod._commentToHtml(this);
    _unresolvedComment = inheritedMethod._unresolvedComment;
    commentInheritedFrom = inheritedMethod.commentInheritedFrom == '' ?
        new DummyMirror(inheritedMethod.mirror).docName :
        inheritedMethod.commentInheritedFrom;
  }

  /// Generates a map describing the [Method] object.
  Map toMap() => {
    'name': name,
    'qualifiedName': qualifiedName,
    'comment': comment,
    'commentFrom': (methodInheritedFrom != null &&
        commentInheritedFrom == methodInheritedFrom.docName ? ''
        : commentInheritedFrom),
    'inheritedFrom': (methodInheritedFrom == null? '' :
        originallyInheritedFrom.docName),
    'static': isStatic,
    'abstract': isAbstract,
    'constant': isConst,
    'return': [returnType.toMap()],
    'parameters': recurseMap(parameters),
    'annotations': annotations.map((a) => a.toMap()).toList()
  };

  String get typeName {
    MethodMirror theMirror = mirror;
    if (theMirror.isConstructor) return 'constructor';
    if (theMirror.isGetter) return 'getter';
    if (theMirror.isSetter) return'setter';
    if (theMirror.isOperator) return 'operator';
    return 'method';
  }

  get comment {
    if (_comment != null) return _comment;
    if (owner is Class) {
      (owner as Class).ensureComments();
    }
    var result = super.comment;
    if (result == '' && methodInheritedFrom != null) {
      // This should be NOT from the MIRROR, but from the COMMENT.
      methodInheritedFrom.comment; // Ensure comment field has been populated.
      _unresolvedComment = methodInheritedFrom._unresolvedComment;

      var linkResolver = (name) => fixReference(name);
      comment = _unresolvedComment == null ? '' :
        markdown.markdownToHtml(_unresolvedComment.trim(),
            linkResolver: linkResolver, inlineSyntaxes: MARKDOWN_SYNTAXES);
      commentInheritedFrom = comment != '' ?
          methodInheritedFrom.commentInheritedFrom : '';
      result = comment;
    }
    return result;
  }

  bool isValidMirror(DeclarationMirror mirror) => mirror is MethodMirror;
}

/// Docgen wrapper around the dart2js mirror for a Dart
/// method/function parameter.
class Parameter extends MirrorBased {
  final ParameterMirror mirror;
  final String name;
  final bool isOptional;
  final bool isNamed;
  final bool hasDefaultValue;
  final Type type;
  final String defaultValue;
  /// List of the meta annotations on the parameter.
  final List<Annotation> annotations;

  Parameter(ParameterMirror mirror, Library owningLibrary)
      : this.mirror = mirror,
        name = dart2js_util.nameOf(mirror),
        isOptional = mirror.isOptional,
        isNamed = mirror.isNamed,
        hasDefaultValue = mirror.hasDefaultValue,
        defaultValue = '${mirror.defaultValue}',
        type = new Type(mirror.type, owningLibrary),
        annotations = createAnnotations(mirror, owningLibrary);

  /// Generates a map describing the [Parameter] object.
  Map toMap() => {
    'name': name,
    'optional': isOptional,
    'named': isNamed,
    'default': hasDefaultValue,
    'type': new List.filled(1, type.toMap()),
    'value': defaultValue,
    'annotations': annotations.map((a) => a.toMap()).toList()
  };
}

/// Docgen wrapper around the mirror for a return type, and/or its generic
/// type parameters.
///
/// Return types are of a form [outer]<[inner]>.
/// If there is no [inner] part, [inner] will be an empty list.
///
/// For example:
///        int size()
///          "return" :
///            - "outer" : "dart-core.int"
///              "inner" :
///
///        List<String> toList()
///          "return" :
///            - "outer" : "dart-core.List"
///              "inner" :
///                - "outer" : "dart-core.String"
///                  "inner" :
///
///        Map<String, List<int>>
///          "return" :
///            - "outer" : "dart-core.Map"
///              "inner" :
///                - "outer" : "dart-core.String"
///                  "inner" :
///                - "outer" : "dart-core.List"
///                  "inner" :
///                    - "outer" : "dart-core.int"
///                      "inner" :
class Type extends MirrorBased {
  final TypeMirror mirror;
  final Library owningLibrary;

  Type(this.mirror, this.owningLibrary);

  Map toMap() {
    var result = getDocgenObject(mirror, owningLibrary);
    return {
      // We may encounter types whose corresponding library has not been
      // processed yet, so look up with the owningLibrary at the last moment.
      'outer': result.packagePrefix + result.docName,
      'inner': _createTypeGenerics(mirror).map((e) => e.toMap()).toList(),
    };
  }

  /// Returns a list of [Type] objects constructed from TypeMirrors.
  List<Type> _createTypeGenerics(TypeMirror mirror) {
    if (mirror is! ClassMirror) return [];
    return mirror.typeArguments.map((e) => new Type(e, owningLibrary)).toList();
  }
}

/// Holds the name of the annotation, and its parameters.
class Annotation extends MirrorBased {
  /// The class of this annotation.
  final ClassMirror mirror;
  final Library owningLibrary;
  List<String> parameters;

  Annotation(InstanceMirror originalMirror, this.owningLibrary)
      : mirror = originalMirror.type {
    parameters = dart2js_util.variablesOf(originalMirror.type.declarations)
        .where((e) => e.isFinal)
        .map((e) => originalMirror.getField(e.simpleName).reflectee)
        .where((e) => e != null)
        .toList();
  }

  Map toMap() => {
    'name': getDocgenObject(mirror, owningLibrary).docName,
    'parameters': parameters
  };
}
