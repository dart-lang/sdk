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
        Reference,
        Procedure,
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
  IndexedLibrary lookupLibrary(Library library) => _indexedLibraries[library];
}

abstract class IndexedContainer {
  final Map<String, Reference> _getterReferences = new Map<String, Reference>();
  final Map<String, Reference> _setterReferences = new Map<String, Reference>();

  Reference lookupGetterReference(String name) => _getterReferences[name];
  Reference lookupSetterReference(String name) => _setterReferences[name];

  void _addProcedures(List<Procedure> procedures) {
    for (int i = 0; i < procedures.length; i++) {
      Procedure procedure = procedures[i];
      String name = procedure.name.text;
      if (procedure.isSetter) {
        _setterReferences[name] = procedure.reference;
      } else {
        _getterReferences[name] = procedure.reference;
      }
    }
  }

  void _addFields(List<Field> fields) {
    for (int i = 0; i < fields.length; i++) {
      Field field = fields[i];
      String name = field.name.text;
      _getterReferences[name] = field.getterReference;
      if (field.hasSetter) {
        _setterReferences[name] = field.setterReference;
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

  IndexedLibrary(Library library) {
    for (int i = 0; i < library.typedefs.length; i++) {
      Typedef typedef = library.typedefs[i];
      _typedefs[typedef.name] = typedef;
    }
    for (int i = 0; i < library.classes.length; i++) {
      Class c = library.classes[i];
      _classes[c.name] = c;
      _indexedClasses[c.name] = new IndexedClass._(c);
    }
    for (int i = 0; i < library.extensions.length; i++) {
      Extension extension = library.extensions[i];
      _extensions[extension.name] = extension;
    }
    _addProcedures(library.procedures);
    _addFields(library.fields);
  }

  Typedef lookupTypedef(String name) => _typedefs[name];
  Class lookupClass(String name) => _classes[name];
  IndexedClass lookupIndexedClass(String name) => _indexedClasses[name];
  Extension lookupExtension(String name) => _extensions[name];
}

class IndexedClass extends IndexedContainer {
  final Map<String, Constructor> _constructors = new Map<String, Constructor>();

  IndexedClass._(Class c) {
    for (int i = 0; i < c.constructors.length; i++) {
      Constructor constructor = c.constructors[i];
      _constructors[constructor.name.text] = constructor;
    }
    _addProcedures(c.procedures);
    _addFields(c.fields);
  }

  Constructor lookupConstructor(String name) => _constructors[name];
}
