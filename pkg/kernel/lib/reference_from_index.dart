// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "ast.dart"
    show Class, Constructor, Extension, Field, Library, Procedure, Typedef;

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

class IndexedLibrary {
  final Map<String, Typedef> _typedefs = new Map<String, Typedef>();
  final Map<String, Class> _classes = new Map<String, Class>();
  final Map<String, IndexedClass> _indexedClasses =
      new Map<String, IndexedClass>();
  final Map<String, Extension> _extensions = new Map<String, Extension>();
  final Map<String, Procedure> _proceduresNotSetters =
      new Map<String, Procedure>();
  final Map<String, Procedure> _proceduresSetters =
      new Map<String, Procedure>();
  final Map<String, Field> _fields = new Map<String, Field>();

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
    for (int i = 0; i < library.procedures.length; i++) {
      Procedure procedure = library.procedures[i];
      if (procedure.isSetter) {
        _proceduresSetters[procedure.name.text] = procedure;
      } else {
        _proceduresNotSetters[procedure.name.text] = procedure;
      }
    }
    for (int i = 0; i < library.fields.length; i++) {
      Field field = library.fields[i];
      _fields[field.name.text] = field;
    }
  }

  Typedef lookupTypedef(String name) => _typedefs[name];
  Class lookupClass(String name) => _classes[name];
  IndexedClass lookupIndexedClass(String name) => _indexedClasses[name];
  Extension lookupExtension(String name) => _extensions[name];
  Procedure lookupProcedureNotSetter(String name) =>
      _proceduresNotSetters[name];
  Procedure lookupProcedureSetter(String name) => _proceduresSetters[name];
  Field lookupField(String name) => _fields[name];
}

class IndexedClass {
  final Map<String, Constructor> _constructors = new Map<String, Constructor>();
  final Map<String, Procedure> _proceduresNotSetters =
      new Map<String, Procedure>();
  final Map<String, Procedure> _proceduresSetters =
      new Map<String, Procedure>();
  final Map<String, Field> _fields = new Map<String, Field>();

  IndexedClass._(Class c) {
    for (int i = 0; i < c.constructors.length; i++) {
      Constructor constructor = c.constructors[i];
      _constructors[constructor.name.text] = constructor;
    }
    for (int i = 0; i < c.procedures.length; i++) {
      Procedure procedure = c.procedures[i];
      if (procedure.isSetter) {
        _proceduresSetters[procedure.name.text] = procedure;
      } else {
        _proceduresNotSetters[procedure.name.text] = procedure;
      }
    }
    for (int i = 0; i < c.fields.length; i++) {
      Field field = c.fields[i];
      _fields[field.name.text] = field;
    }
  }

  Constructor lookupConstructor(String name) => _constructors[name];
  Procedure lookupProcedureNotSetter(String name) =>
      _proceduresNotSetters[name];
  Procedure lookupProcedureSetter(String name) => _proceduresSetters[name];
  Field lookupField(String name) => _fields[name];
}
