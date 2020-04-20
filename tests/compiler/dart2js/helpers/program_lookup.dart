// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';
import 'package:compiler/src/common_elements.dart';
import 'package:compiler/src/deferred_load.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/js_backend/namer.dart';
import 'package:compiler/src/js_emitter/model.dart';
import 'package:compiler/src/js_model/js_strategy.dart';
import 'package:compiler/src/js/js.dart' as js;

ClassEntity lookupClass(JElementEnvironment elementEnvironment, String name) {
  ClassEntity cls =
      elementEnvironment.lookupClass(elementEnvironment.mainLibrary, name);
  Expect.isNotNull(cls, "No class '$name' found in the main library.");
  return cls;
}

MemberEntity lookupMember(JElementEnvironment elementEnvironment, String name) {
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

  ProgramLookup(JsBackendStrategy backendStrategy)
      : this.program = backendStrategy.emitterTask.emitter.programForTesting,
        this.namer = backendStrategy.namerForTesting;

  Fragment getFragment(OutputUnit outputUnit) {
    for (Fragment fragment in program.fragments) {
      if (fragment.outputUnit == outputUnit) {
        return fragment;
      }
    }
    return null;
  }

  Map<LibraryEntity, LibraryData> libraryMap;

  LibraryData getLibraryData(LibraryEntity element) {
    if (libraryMap == null) {
      libraryMap = <LibraryEntity, LibraryData>{};
      for (Fragment fragment in program.fragments) {
        for (Library library in fragment.libraries) {
          assert(!libraryMap.containsKey(library.element));
          libraryMap[library.element] = new LibraryData(library, fragment);
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
      return getClassData(function.enclosingClass)?.getMethod(function);
    } else {
      return getLibraryData(function.library)?.getMethod(function);
    }
  }

  Field getField(FieldEntity field) {
    if (field.enclosingClass != null) {
      return getClassData(field.enclosingClass)?.getField(field);
    } else {
      return getLibraryData(field.library)?.getField(field);
    }
  }

  StaticField getStaticField(FieldEntity field) {
    if (field.enclosingClass != null) {
      return getClassData(field.enclosingClass)?.getStaticField(field);
    } else {
      return getLibraryData(field.library)?.getStaticField(field);
    }
  }
}

class LibraryData {
  final Library library;
  Map<ClassEntity, ClassData> _classMap = {};
  Map<FunctionEntity, StaticMethod> _methodMap = {};
  Map<FieldEntity, Field> _fieldMap = {};
  Map<FieldEntity, StaticField> _staticFieldMap = {};

  LibraryData(this.library, Fragment fragment) {
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

    void addField(Field field) {
      ClassEntity enclosingClass = field.element?.enclosingClass;
      if (enclosingClass != null) {
        ClassData data =
            _classMap.putIfAbsent(enclosingClass, () => new ClassData(null));
        assert(!data._fieldMap.containsKey(field.element));
        data._fieldMap[field.element] = field;
      } else if (field.element != null) {
        assert(!_fieldMap.containsKey(field.element));
        _fieldMap[field.element] = field;
      }
    }

    for (Field field in library.staticFieldsForReflection) {
      addField(field);
    }

    void addStaticField(StaticField field) {
      ClassEntity enclosingClass = field.element?.enclosingClass;
      if (enclosingClass != null) {
        ClassData data =
            _classMap.putIfAbsent(enclosingClass, () => new ClassData(null));
        assert(!data._fieldMap.containsKey(field.element));
        data._staticFieldMap[field.element] = field;
      } else if (field.element != null) {
        assert(!_fieldMap.containsKey(field.element));
        _staticFieldMap[field.element] = field;
      }
    }

    for (StaticField field in fragment.staticNonFinalFields) {
      addStaticField(field);
    }
    for (StaticField field in fragment.staticLazilyInitializedFields) {
      addStaticField(field);
    }
  }

  ClassData getClassData(ClassEntity element) {
    return _classMap[element];
  }

  StaticMethod getMethod(FunctionEntity function) {
    return _methodMap[function];
  }

  Field getField(FieldEntity field) {
    return _fieldMap[field];
  }

  StaticField getStaticField(FieldEntity field) {
    return _staticFieldMap[field];
  }

  @override
  String toString() => 'LibraryData(library=$library,_classMap=$_classMap,'
      '_methodMap=$_methodMap,_fieldMap=$_fieldMap)';
}

class ClassData {
  final Class cls;
  Map<FunctionEntity, Method> _methodMap = {};
  Map<FieldEntity, Field> _fieldMap = {};
  Map<FieldEntity, StaticField> _staticFieldMap = {};
  Map<FieldEntity, StubMethod> _checkedSetterMap = {};

  ClassData(this.cls) {
    if (cls != null) {
      for (Method method in cls.methods) {
        assert(!_methodMap.containsKey(method.element));
        _methodMap[method.element] = method;
      }
      for (Field field in cls.fields) {
        assert(!_fieldMap.containsKey(field.element));
        _fieldMap[field.element] = field;
      }
      for (StubMethod checkedSetter in cls.checkedSetters) {
        assert(!_checkedSetterMap.containsKey(checkedSetter.element));
        _checkedSetterMap[checkedSetter.element] = checkedSetter;
      }
    }
  }

  Method getMethod(FunctionEntity function) {
    return _methodMap[function];
  }

  Field getField(FieldEntity field) {
    return _fieldMap[field];
  }

  StaticField getStaticField(FieldEntity field) {
    return _staticFieldMap[field];
  }

  StubMethod getCheckedSetter(FieldEntity field) {
    return _checkedSetterMap[field];
  }

  @override
  String toString() => 'ClassData(cls=$cls,'
      '_methodMap=$_methodMap,_fieldMap=$_fieldMap)';
}

void forEachNode(js.Node root,
    {void Function(js.Call) onCall,
    void Function(js.PropertyAccess) onPropertyAccess,
    void Function(js.Assignment) onAssignment,
    void Function(js.Switch) onSwitch}) {
  CallbackVisitor visitor = new CallbackVisitor(
      onCall: onCall,
      onPropertyAccess: onPropertyAccess,
      onAssignment: onAssignment,
      onSwitch: onSwitch);
  root.accept(visitor);
}

class CallbackVisitor extends js.BaseVisitor {
  final void Function(js.Call) onCall;
  final void Function(js.PropertyAccess) onPropertyAccess;
  final void Function(js.Assignment) onAssignment;
  final void Function(js.Switch) onSwitch;

  CallbackVisitor(
      {this.onCall, this.onPropertyAccess, this.onAssignment, this.onSwitch});

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

  @override
  visitAssignment(js.Assignment node) {
    if (onAssignment != null) onAssignment(node);
    return super.visitAssignment(node);
  }

  @override
  visitSwitch(js.Switch node) {
    if (onSwitch != null) onSwitch(node);
    return super.visitSwitch(node);
  }
}
