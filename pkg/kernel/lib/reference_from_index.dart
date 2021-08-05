// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "ast.dart"
    show
        Class,
        Constructor,
        Extension,
        Field,
        Library,
        Member,
        Name,
        Procedure,
        ProcedureKind,
        Reference,
        Typedef;

class ReferenceFromIndex {
  Map<Library, IndexedLibrary> _indexedLibraries =
      new Map<Library, IndexedLibrary>.identity();

  /// Add an entry mapping from *new* [library] to an index of the old library.
  void addIndexedLibrary(Library library, IndexedLibrary indexedLibrary) {
    assert(!_indexedLibraries.containsKey(library));
    _indexedLibraries[library] = indexedLibrary;
  }

  /// Lookup the new library and get an index of the old library.
  IndexedLibrary? lookupLibrary(Library library) => _indexedLibraries[library];
}

abstract class IndexedContainer {
  final Map<Name, Reference> _getterReferences = new Map<Name, Reference>();
  final Map<Name, Reference> _setterReferences = new Map<Name, Reference>();

  Reference? lookupGetterReference(Name name) => _getterReferences[name];
  Reference? lookupSetterReference(Name name) => _setterReferences[name];

  Library get library;

  void _addProcedures(List<Procedure> procedures) {
    for (int i = 0; i < procedures.length; i++) {
      _addProcedure(procedures[i]);
    }
  }

  void _addProcedure(Procedure procedure) {
    Name name = procedure.name;
    if (procedure.isSetter) {
      assert(_setterReferences[name] == null);
      _setterReferences[name] = procedure.reference;
    } else {
      assert(_getterReferences[name] == null);
      assert(procedure.kind == ProcedureKind.Method ||
          procedure.kind == ProcedureKind.Getter ||
          procedure.kind == ProcedureKind.Operator);
      _getterReferences[name] = procedure.reference;
    }
  }

  void _addFields(List<Field> fields) {
    for (int i = 0; i < fields.length; i++) {
      Field field = fields[i];
      Name name = field.name;
      assert(_getterReferences[name] == null);
      _getterReferences[name] = field.getterReference;
      if (field.hasSetter) {
        assert(_setterReferences[name] == null);
        _setterReferences[name] = field.setterReference!;
      }
    }
  }
}

class IndexedLibrary extends IndexedContainer {
  final Map<String, Typedef> _typedefs = new Map<String, Typedef>();
  final Map<String, Class> _classes = new Map<String, Class>();
  final Map<String, IndexedClass> _indexedClasses =
      new Map<String, IndexedClass>();
  final Map<String, Extension> _extensions = new Map<String, Extension>();
  final Library library;

  IndexedLibrary(this.library) {
    for (int i = 0; i < library.typedefs.length; i++) {
      Typedef typedef = library.typedefs[i];
      assert(_typedefs[typedef.name] == null);
      _typedefs[typedef.name] = typedef;
    }
    for (int i = 0; i < library.classes.length; i++) {
      Class c = library.classes[i];
      assert(_classes[c.name] == null);
      _classes[c.name] = c;
      assert(_indexedClasses[c.name] == null);
      _indexedClasses[c.name] = new IndexedClass._(c, library);
    }
    for (int i = 0; i < library.extensions.length; i++) {
      Extension extension = library.extensions[i];
      assert(_extensions[extension.name] == null);
      _extensions[extension.name] = extension;
    }
    _addProcedures(library.procedures);
    _addFields(library.fields);
  }

  Typedef? lookupTypedef(String name) => _typedefs[name];
  Class? lookupClass(String name) => _classes[name];
  IndexedClass? lookupIndexedClass(String name) => _indexedClasses[name];
  Extension? lookupExtension(String name) => _extensions[name];
}

class IndexedClass extends IndexedContainer {
  final Class cls;
  final Map<Name, Member> _constructors = new Map<Name, Member>();
  final Library library;

  IndexedClass._(this.cls, this.library) {
    for (int i = 0; i < cls.constructors.length; i++) {
      Constructor constructor = cls.constructors[i];
      _constructors[constructor.name] = constructor;
    }
    for (int i = 0; i < cls.procedures.length; i++) {
      Procedure procedure = cls.procedures[i];
      if (procedure.isFactory) {
        _constructors[procedure.name] = procedure;
      } else {
        _addProcedure(procedure);
      }
    }
    _addFields(cls.fields);
  }

  Member? lookupConstructor(Name name) => _constructors[name];
}
