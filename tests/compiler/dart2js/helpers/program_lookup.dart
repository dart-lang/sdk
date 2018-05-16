// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:compiler/src/common_elements.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/js_backend/namer.dart';
import 'package:compiler/src/js_emitter/model.dart';
import 'package:compiler/src/js/js.dart' as js;

MemberEntity lookupMember(ElementEnvironment elementEnvironment, String name) {
  MemberEntity member;
  int dotIndex = name.indexOf('.');
  if (dotIndex != -1) {
    String className = name.substring(0, dotIndex);
    name = name.substring(dotIndex + 1);
    ClassEntity cls = elementEnvironment.lookupClass(
        elementEnvironment.mainLibrary, className);
    Expect.isNotNull(cls, "No class '$className' found in the main library.");
    member = elementEnvironment.lookupClassMember(cls, name);
    member ??= elementEnvironment.lookupConstructor(cls, name);
    Expect.isNotNull(member, "No member '$name' found in $cls");
  } else {
    member = elementEnvironment.lookupLibraryMember(
        elementEnvironment.mainLibrary, name);
    Expect.isNotNull(member, "No member '$name' found in the main library.");
  }
  return member;
}

class ProgramLookup {
  final Program program;
  final Namer namer;

  ProgramLookup(Compiler compiler)
      : this.program = compiler.backend.emitter.emitter.programForTesting,
        this.namer = compiler.backend.namer;

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
    return getLibraryData(element)?.library;
  }

  ClassData getClassData(ClassEntity element) {
    return getLibraryData(element.library)?.getClassData(element);
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
  Map<ClassEntity, ClassData> _classMap = <ClassEntity, ClassData>{};
  Map<FunctionEntity, StaticMethod> _methodMap =
      <FunctionEntity, StaticMethod>{};

  LibraryData(this.library) {
    for (Class cls in library.classes) {
      assert(!_classMap.containsKey(cls.element));
      _classMap[cls.element] = new ClassData(cls);
    }
    for (StaticMethod method in library.statics) {
      ClassEntity enclosingClass = method.element?.enclosingClass;
      if (enclosingClass != null) {
        ClassData data =
            _classMap.putIfAbsent(enclosingClass, () => new ClassData(null));
        assert(!data._methodMap.containsKey(method.element));
        data._methodMap[method.element] = method;
      } else if (method.element != null) {
        assert(!_methodMap.containsKey(method.element));
        _methodMap[method.element] = method;
      }
    }
  }

  ClassData getClassData(ClassEntity element) {
    return _classMap[element];
  }

  StaticMethod getMethod(FunctionEntity function) {
    return _methodMap[function];
  }
}

class ClassData {
  final Class cls;
  Map<FunctionEntity, Method> _methodMap = <FunctionEntity, Method>{};

  ClassData(this.cls) {
    if (cls != null) {
      for (Method method in cls.methods) {
        assert(!_methodMap.containsKey(method.element));
        _methodMap[method.element] = method;
      }
    }
  }

  Method getMethod(FunctionEntity function) {
    return _methodMap[function];
  }
}

void forEachNode(js.Node root,
    {void Function(js.Call) onCall,
    void Function(js.PropertyAccess) onPropertyAccess}) {
  CallbackVisitor visitor =
      new CallbackVisitor(onCall: onCall, onPropertyAccess: onPropertyAccess);
  root.accept(visitor);
}

class CallbackVisitor extends js.BaseVisitor {
  final void Function(js.Call) onCall;
  final void Function(js.PropertyAccess) onPropertyAccess;

  CallbackVisitor({this.onCall, this.onPropertyAccess});

  @override
  visitCall(js.Call node) {
    if (onCall != null) onCall(node);
    super.visitCall(node);
  }

  @override
  visitAccess(js.PropertyAccess node) {
    if (onPropertyAccess != null) onPropertyAccess(node);
    super.visitAccess(node);
  }
}
