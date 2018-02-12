// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/js_emitter/model.dart';

class ProgramLookup {
  final Program program;

  ProgramLookup(Compiler compiler)
      : this.program = compiler.backend.emitter.emitter.programForTesting;

  Map<LibraryEntity, LibraryData> libraryMap;

  LibraryData getLibraryData(LibraryEntity element) {
    if (libraryMap == null) {
      libraryMap = <LibraryEntity, LibraryData>{};
      for (Fragment fragment in program.fragments) {
        for (Library library in fragment.libraries) {
          assert(!libraryMap.containsKey(library.element));
          libraryMap[library.element] = new LibraryData(library);
        }
      }
    }
    return libraryMap[element];
  }

  Library getLibrary(LibraryEntity element) {
    return getLibraryData(element).library;
  }

  ClassData getClassData(ClassEntity element) {
    return getLibraryData(element.library).getClassData(element);
  }

  Class getClass(ClassEntity element) {
    return getClassData(element)?.cls;
  }

  Method getMethod(FunctionEntity function) {
    if (function.enclosingClass != null) {
      return getClassData(function.enclosingClass).getMethod(function);
    } else {
      return getLibraryData(function.library).getMethod(function);
    }
  }
}

class LibraryData {
  final Library library;
  Map<ClassEntity, ClassData> _classMap;
  Map<FunctionEntity, StaticMethod> _methodMap;

  LibraryData(this.library);
  ClassData getClassData(ClassEntity element) {
    if (_classMap == null) {
      _classMap = <ClassEntity, ClassData>{};
      for (Class cls in library.classes) {
        assert(!_classMap.containsKey(cls.element));
        _classMap[cls.element] = new ClassData(cls);
      }
    }
    return _classMap[element];
  }

  StaticMethod getMethod(FunctionEntity function) {
    if (_methodMap == null) {
      _methodMap = <FunctionEntity, StaticMethod>{};
      for (StaticMethod method in library.statics) {
        assert(!_methodMap.containsKey(method.element));
        _methodMap[method.element] = method;
      }
    }
    return _methodMap[function];
  }
}

class ClassData {
  final Class cls;
  Map<FunctionEntity, Method> _methodMap;

  ClassData(this.cls);

  Method getMethod(FunctionEntity function) {
    if (_methodMap == null) {
      _methodMap = <FunctionEntity, Method>{};
      for (Method method in cls.methods) {
        assert(!_methodMap.containsKey(method.element));
        _methodMap[method.element] = method;
      }
    }
    return _methodMap[function];
  }
}
