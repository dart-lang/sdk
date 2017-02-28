// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.library_index;

import 'ast.dart';

/// Provides name-based access to library, class, and member AST nodes.
///
/// When constructed, a given set of libraries are indexed immediately, and
/// will not be up-to-date with changes made after it was created.
class LibraryIndex {
  static const String getterPrefix = 'get:';
  static const String setterPrefix = 'set:';

  /// A special class name that can be used to access the top-level members
  /// of a library.
  static const String topLevel = '::';

  final Map<String, _ClassTable> _libraries = <String, _ClassTable>{};

  /// Indexes the libraries with the URIs given in [libraryUris].
  LibraryIndex(Program program, Iterable<String> libraryUris) {
    for (var uri in libraryUris) {
      _libraries[uri] = new _ClassTable();
    }
    for (var library in program.libraries) {
      var index = _libraries['${library.importUri}'];
      if (index != null) {
        index.build(library);
      }
    }
  }

  /// Indexes the libraries with the URIs given in [libraryUris].
  LibraryIndex.byUri(Program program, Iterable<Uri> libraryUris)
      : this(program, libraryUris.map((uri) => '$uri'));

  /// Indexes the libraries with the URIs given in [libraryUris].
  LibraryIndex.coreLibraries(Program program) {
    for (var library in program.libraries) {
      if (library.importUri.scheme == 'dart') {
        _libraries['${library.importUri}'] = new _ClassTable()..build(library);
      }
    }
  }

  /// Indexes the entire program.
  ///
  /// Consider using another constructor to only index the libraries that
  /// are needed.
  LibraryIndex.all(Program program) {
    for (var library in program.libraries) {
      _libraries['${library.importUri}'] = new _ClassTable()..build(library);
    }
  }

  _ClassTable _getLibraryIndex(String uri) {
    _ClassTable libraryIndex = _libraries[uri];
    if (libraryIndex == null) {
      throw "The library '$uri' has not been indexed";
    }
    return libraryIndex;
  }

  /// Returns the library with the given URI.
  ///
  /// Throws an error if it does not exist.
  Library getLibrary(String uri) => _getLibraryIndex(uri).library;

  /// Like [getLibrary] but returns `null` if not found.
  Library tryGetLibrary(String uri) => _libraries[uri]?.library;

  /// True if the library with the given URI exists and was indexed.
  bool containsLibrary(String uri) => _libraries.containsKey(uri);

  /// Returns the class with the given name in the given library.
  ///
  /// An error is thrown if the class is not found.
  Class getClass(String library, String className) {
    return _getLibraryIndex(library).getClass(className);
  }

  /// Like [getClass] but returns `null` if not found.
  Class tryGetClass(String library, String className) {
    return _libraries[library]?.tryGetClass(className);
  }

  /// Returns the member with the given name, in the given class, in the
  /// given library.
  ///
  /// If a getter or setter is wanted, the `get:` or `set:` prefix must be
  /// added in front of the member name.
  ///
  /// The special class name `::` can be used to access top-level members.
  ///
  /// If the member name is private it is considered private to [library].
  /// It is not possible with this class to lookup members whose name is private
  /// to a library other than the one containing it.
  ///
  /// An error is thrown if the member is not found.
  Member getMember(String library, String className, String memberName) {
    return _getLibraryIndex(library).getMember(className, memberName);
  }

  /// Like [getMember] but returns `null` if not found.
  Member tryGetMember(String library, String className, String memberName) {
    return _libraries[library]?.tryGetMember(className, memberName);
  }

  /// Returns the top-level member with the given name, in the given library.
  ///
  /// If a getter or setter is wanted, the `get:` or `set:` prefix must be
  /// added in front of the member name.
  ///
  /// If the member name is private it is considered private to [library].
  /// It is not possible with this class to lookup members whose name is private
  /// to a library other than the one containing it.
  ///
  /// An error is thrown if the member is not found.
  Member getTopLevelMember(String library, String memberName) {
    return getMember(library, topLevel, memberName);
  }

  /// Like [getTopLevelMember] but returns `null` if not found.
  Member tryGetTopLevelMember(
      String library, String className, String memberName) {
    return tryGetMember(library, topLevel, memberName);
  }
}

class _ClassTable {
  Library library;
  final Map<String, _MemberTable> classes = <String, _MemberTable>{};

  void build(Library library) {
    this.library = library;
    classes[LibraryIndex.topLevel] = new _MemberTable.topLevel(this);
    for (var class_ in library.classes) {
      classes[class_.name] = new _MemberTable(this, class_);
    }
  }

  String get containerName {
    // For useful error messages, it can be helpful to indicate if the library
    // is external.  If a class or member was not found in an external library,
    // it might be that it exists in the actual library, but its interface was
    // not included in this build unit.
    return library.isExternal
        ? "external library '${library.importUri}'"
        : "library '${library.importUri}'";
  }

  _MemberTable _getClassIndex(String name) {
    var indexer = classes[name];
    if (indexer == null) {
      throw "Class '$name' not found in $containerName";
    }
    return indexer;
  }

  Class getClass(String name) {
    return _getClassIndex(name).class_;
  }

  Class tryGetClass(String name) {
    return classes[name]?.class_;
  }

  Member getMember(String className, String memberName) {
    return _getClassIndex(className).getMember(memberName);
  }

  Member tryGetMember(String className, String memberName) {
    return classes[className]?.tryGetMember(memberName);
  }
}

class _MemberTable {
  final _ClassTable parent;
  final Class class_; // Null for top-level.
  final Map<String, Member> members = <String, Member>{};

  Library get library => parent.library;

  _MemberTable(this.parent, this.class_) {
    class_.procedures.forEach(addMember);
    class_.fields.forEach(addMember);
    class_.constructors.forEach(addMember);
  }

  _MemberTable.topLevel(this.parent) : class_ = null {
    library.procedures.forEach(addMember);
    library.fields.forEach(addMember);
  }

  String getDisambiguatedName(Member member) {
    if (member is Procedure) {
      if (member.isGetter) return LibraryIndex.getterPrefix + member.name.name;
      if (member.isSetter) return LibraryIndex.setterPrefix + member.name.name;
    }
    return member.name.name;
  }

  void addMember(Member member) {
    if (member.name.isPrivate && member.name.library != library) {
      // Members whose name is private to other libraries cannot currently
      // be found with the LibraryIndex class.
      return;
    }
    members[getDisambiguatedName(member)] = member;
  }

  String get containerName {
    if (class_ == null) {
      return "top-level of ${parent.containerName}";
    } else {
      return "class '${class_.name}' in ${parent.containerName}";
    }
  }

  Member getMember(String name) {
    var member = members[name];
    if (member == null) {
      String message = "A member with disambiguated name '$name' was not found "
          "in $containerName";
      var getter = LibraryIndex.getterPrefix + name;
      var setter = LibraryIndex.setterPrefix + name;
      if (members[getter] != null || members[setter] != null) {
        throw "$message. Did you mean '$getter' or '$setter'?";
      }
      throw message;
    }
    return member;
  }

  Member tryGetMember(String name) => members[name];
}
