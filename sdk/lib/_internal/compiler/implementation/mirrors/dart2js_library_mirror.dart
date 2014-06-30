// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.mirrors;


class Dart2JsLibraryMirror
    extends Dart2JsElementMirror
    with ObjectMirrorMixin, ContainerMixin
    implements LibrarySourceMirror {
  List<LibraryDependencySourceMirror> _libraryDependencies;

  Dart2JsLibraryMirror(Dart2JsMirrorSystem system, LibraryElement library)
      : super(system, library);

  Function operator [](Symbol name) {
    throw new UnsupportedError('LibraryMirror.operator [] unsupported.');
  }

  LibraryElement get _element => super._element;

  Uri get uri => _element.canonicalUri;

  DeclarationMirror get owner => null;

  bool get isPrivate => false;

  LibraryMirror library() => this;

  /**
   * Returns the library name (for libraries with a library tag) or the script
   * file name (for scripts without a library tag). The latter case is used to
   * provide a 'library name' for scripts, to use for instance in dartdoc.
   */
  String get _simpleNameString {
    if (_element.libraryTag != null) {
      return _element.libraryTag.name.toString();
    } else {
      // Use the file name as script name.
      String path = _element.canonicalUri.path;
      return path.substring(path.lastIndexOf('/') + 1);
    }
  }

  Symbol get qualifiedName => simpleName;

  void _forEachElement(f(Element element)) => _element.forEachLocalMember(f);

  Iterable<Dart2JsDeclarationMirror> _getDeclarationMirrors(Element element) {
    if (element.isClass || element.isTypedef) {
      return [mirrorSystem._getTypeDeclarationMirror(element)];
    } else {
      return super._getDeclarationMirrors(element);
    }
  }

  Map<Symbol, MethodMirror> get topLevelMembers => null;

  /**
   * Computes the first token of this library using the first library tag as
   * indicator.
   */
  Token getBeginToken() {
    if (_element.libraryTag != null) {
      return _element.libraryTag.getBeginToken();
    } else if (!_element.tags.isEmpty) {
      return _element.tags.first.getBeginToken();
    }
    return null;
  }

  /**
   * Computes the first token of this library using the last library tag as
   * indicator.
   */
  Token getEndToken() {
    if (!_element.tags.isEmpty) {
      return _element.tags.last.getEndToken();
    }
    return null;
  }

  void _ensureLibraryDependenciesAnalyzed() {
    if (_libraryDependencies == null) {
      _libraryDependencies = <LibraryDependencySourceMirror>[];
      for (LibraryTag node in _element.tags) {
        LibraryDependency libraryDependency = node.asLibraryDependency();
        if (libraryDependency != null) {
          LibraryElement targetLibraryElement =
              _element.getLibraryFromTag(libraryDependency);
          assert(targetLibraryElement != null);
          LibraryMirror targetLibrary =
              mirrorSystem._getLibrary(targetLibraryElement);
          _libraryDependencies.add(new Dart2JsLibraryDependencyMirror(
              libraryDependency, this, targetLibrary));
        }
      }
    }
  }

  List<LibraryDependencyMirror> get libraryDependencies {
    _ensureLibraryDependenciesAnalyzed();
    return _libraryDependencies;
  }
}

class Dart2JsLibraryDependencyMirror implements LibraryDependencySourceMirror {
  final LibraryDependency _node;
  final Dart2JsLibraryMirror _sourceLibrary;
  final Dart2JsLibraryMirror _targetLibrary;
  List<CombinatorMirror> _combinators;

  Dart2JsLibraryDependencyMirror(this._node,
                                 this._sourceLibrary,
                                 this._targetLibrary);

  SourceLocation get location {
    return new Dart2JsSourceLocation(
      _sourceLibrary._element.entryCompilationUnit.script,
      _sourceLibrary.mirrorSystem.compiler.spanFromNode(_node));
  }

  List<CombinatorMirror> get combinators {
    if (_combinators == null) {
      _combinators = <CombinatorMirror>[];
      if (_node.combinators != null) {
        for (Combinator combinator in _node.combinators.nodes) {
          List<String> identifiers = <String>[];
          for (Identifier identifier in combinator.identifiers.nodes) {
            identifiers.add(identifier.source);
          }
          _combinators.add(new Dart2JsCombinatorMirror(
              identifiers, isShow: combinator.isShow));
        }
      }
    }
    return _combinators;
  }

  LibraryMirror get sourceLibrary => _sourceLibrary;

  LibraryMirror get targetLibrary => _targetLibrary;

  /*String*/ get prefix {
    Import import = _node.asImport();
    if (import != null && import.prefix != null) {
      return import.prefix.source;
    }
    return null;
  }

  bool get isImport => _node.asImport() != null;

  bool get isExport => _node.asExport() != null;

  List<InstanceMirror> get metadata => const <InstanceMirror>[];
}

class Dart2JsCombinatorMirror implements CombinatorSourceMirror {
  final List/*<String>*/ identifiers;
  final bool isShow;

  Dart2JsCombinatorMirror(this.identifiers, {bool isShow: true})
      : this.isShow = isShow;

  bool get isHide => !isShow;
}

class Dart2JsSourceLocation implements SourceLocation {
  final Script _script;
  final SourceSpan _span;
  int _line;
  int _column;

  Dart2JsSourceLocation(this._script, this._span);

  int _computeLine() {
    var sourceFile = _script.file;
    if (sourceFile != null) {
      return sourceFile.getLine(offset) + 1;
    }
    var index = 0;
    var lineNumber = 0;
    while (index <= offset && index < sourceText.length) {
      index = sourceText.indexOf('\n', index) + 1;
      if (index <= 0) break;
      lineNumber++;
    }
    return lineNumber;
  }

  int get line {
    if (_line == null) {
      _line = _computeLine();
    }
    return _line;
  }

  int _computeColumn() {
    if (length == 0) return 0;

    var sourceFile = _script.file;
    if (sourceFile != null) {
      return sourceFile.getColumn(sourceFile.getLine(offset), offset) + 1;
    }
    int index = offset - 1;
    var columnNumber = 0;
    while (0 <= index && index < sourceText.length) {
      columnNumber++;
      var codeUnit = sourceText.codeUnitAt(index);
      if (codeUnit == $CR || codeUnit == $LF) {
        break;
      }
      index--;
    }
    return columnNumber;
  }

  int get column {
    if (_column == null) {
      _column = _computeColumn();
    }
    return _column;
  }

  int get offset => _span.begin;

  int get length => _span.end - _span.begin;

  String get text => _script.text.substring(_span.begin, _span.end);

  Uri get sourceUri => _script.resourceUri;

  String get sourceText => _script.text;
}
