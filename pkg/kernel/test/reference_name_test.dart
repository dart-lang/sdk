// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/src/equivalence.dart';

void testReferenceNames(Map<ReferenceNameKind, List<ReferenceNameObject>> map1,
    Map<ReferenceNameKind, List<ReferenceNameObject>> map2) {
  Expect.setEquals(map1.keys, map2.keys);
  map1.forEach((ReferenceNameKind kind1, List<ReferenceNameObject> list1) {
    map1.forEach((ReferenceNameKind kind2, List<ReferenceNameObject> list2) {
      for (int index1 = 0; index1 < list1.length; index1++) {
        for (int index2 = 0; index2 < list2.length; index2++) {
          ReferenceName name1 = list1[index1].referenceName;
          Object object1 = list1[index1].object;
          ReferenceName name2 = list2[index2].referenceName;
          Object object2 = list2[index2].object;
          if (kind1 == kind2 && index1 == index2) {
            Expect.equals(
                name1,
                name2,
                "Expected $name1 for ${object1} (${object1.runtimeType}) and "
                "$name2 for $object2 (${object2.runtimeType}) to be equal.");
          } else {
            Expect.notEquals(
                name1,
                name2,
                "Expected $name1 for ${object1} (${object1.runtimeType}) and "
                "$name2 for $object2 (${object2.runtimeType}) to be unequal.");
          }
        }
      }
    });
  });
}

void main() {
  Component component1 = createComponent();
  Map<ReferenceNameKind, List<ReferenceNameObject>> referenceNames1 =
      computeReferenceNamesFromComponent(component1);

  Component component2 = createComponent();
  Map<ReferenceNameKind, List<ReferenceNameObject>> referenceNames2 =
      computeReferenceNamesFromComponent(component2);

  Component component3 = createComponent();
  component3.computeCanonicalNames();
  CanonicalName root3 = component3.root;
  Map<ReferenceNameKind, List<ReferenceNameObject>> referenceNames3 =
      computeReferenceNamesFromCanonicalName(root3);

  Component component4 = createComponent();
  component4.computeCanonicalNames();
  CanonicalName root4 = component3.root;
  Map<ReferenceNameKind, List<ReferenceNameObject>> referenceNames4 =
      computeReferenceNamesFromCanonicalName(root4);

  testReferenceNames(referenceNames1, referenceNames2);
  testReferenceNames(referenceNames1, referenceNames3);
  testReferenceNames(referenceNames3, referenceNames4);
}

Component createComponent() {
  Component component = new Component();
  Library library1 = new Library(Uri.parse('test:library1'), fileUri: dummyUri);
  component.libraries.add(library1);
  Library library2 = new Library(Uri.parse('test:library2'), fileUri: dummyUri);
  component.libraries.add(library2);

  library1.addProcedure(new Procedure(
      new Name('foo'), ProcedureKind.Method, new FunctionNode(null),
      fileUri: dummyUri));
  library1.addProcedure(new Procedure(
      new Name('bar'), ProcedureKind.Operator, new FunctionNode(null),
      fileUri: dummyUri));
  library1.addProcedure(new Procedure(
      new Name('baz'), ProcedureKind.Factory, new FunctionNode(null),
      fileUri: dummyUri));
  library1.addProcedure(new Procedure(
      new Name('boz'), ProcedureKind.Getter, new FunctionNode(null),
      fileUri: dummyUri));
  // The setter should be distinct from the getter even when they have the same
  // name.
  library1.addProcedure(new Procedure(
      new Name('boz'), ProcedureKind.Setter, new FunctionNode(null),
      fileUri: dummyUri));

  library1.addProcedure(new Procedure(
      new Name('_boz', library2), ProcedureKind.Getter, new FunctionNode(null),
      fileUri: dummyUri));
  // The setter should be distinct from the getter even when they have the same
  // name.
  library1.addProcedure(new Procedure(
      new Name('_boz', library2), ProcedureKind.Setter, new FunctionNode(null),
      fileUri: dummyUri));

  library1.addField(
      new Field.immutable(new Name('_foo', library1), fileUri: dummyUri));
  library1.addField(
      new Field.mutable(new Name('_bar', library2), fileUri: dummyUri));

  Class class1 = new Class(name: 'Foo', fileUri: dummyUri);
  library2.addClass(class1);
  Class class2 = new Class(name: 'Bar', fileUri: dummyUri);
  library2.addClass(class2);

  class2.addConstructor(new Constructor(new FunctionNode(null),
      name: new Name(''), fileUri: dummyUri));
  class2.addConstructor(new Constructor(new FunctionNode(null),
      name: new Name('_', library1), fileUri: dummyUri));

  class2.addProcedure(new Procedure(
      new Name('foo'), ProcedureKind.Method, new FunctionNode(null),
      fileUri: dummyUri));
  class2.addProcedure(new Procedure(
      new Name('bar'), ProcedureKind.Operator, new FunctionNode(null),
      fileUri: dummyUri));
  class2.addProcedure(new Procedure(
      new Name('baz'), ProcedureKind.Factory, new FunctionNode(null),
      fileUri: dummyUri));
  class2.addProcedure(new Procedure(
      new Name('boz'), ProcedureKind.Getter, new FunctionNode(null),
      fileUri: dummyUri));
  // The setter should be distinct from the getter even when they have the same
  // name.
  class2.addProcedure(new Procedure(
      new Name('boz'), ProcedureKind.Setter, new FunctionNode(null),
      fileUri: dummyUri));

  class2.addProcedure(new Procedure(
      new Name('_boz', library2), ProcedureKind.Getter, new FunctionNode(null),
      fileUri: dummyUri));
  // The setter should be distinct from the getter even when they have the same
  // name.
  class2.addProcedure(new Procedure(
      new Name('_boz', library2), ProcedureKind.Setter, new FunctionNode(null),
      fileUri: dummyUri));

  class2.addField(
      new Field.immutable(new Name('_foo', library1), fileUri: dummyUri));
  class2.addField(
      new Field.mutable(new Name('_bar', library2), fileUri: dummyUri));

  library1.addExtension(new Extension(name: 'Baz', fileUri: dummyUri));

  library1.addTypedef(new Typedef('Boz', dummyDartType, fileUri: dummyUri));

  return component;
}

void sortReferenceNames(Map<ReferenceNameKind, List<ReferenceNameObject>> map) {
  map.forEach((key, value) {
    value.sort(
        (n1, n2) => n1.referenceName.name!.compareTo(n2.referenceName.name!));
  });
}

Map<ReferenceNameKind, List<ReferenceNameObject>>
    computeReferenceNamesFromComponent(Component component) {
  Map<ReferenceNameKind, List<ReferenceNameObject>> map = {};
  void add(ReferenceNameKind kind, ReferenceNameObject object) {
    (map[kind] ??= []).add(object);
  }

  for (Library library in component.libraries) {
    add(ReferenceNameKind.Library,
        new ReferenceNameObject(ReferenceName.fromNamedNode(library), library));
    for (Typedef typedef in library.typedefs) {
      add(
          ReferenceNameKind.Typedef,
          new ReferenceNameObject(
              ReferenceName.fromNamedNode(typedef), typedef));
    }
    for (Field field in library.fields) {
      add(
          ReferenceNameKind.Field,
          new ReferenceNameObject(
              ReferenceName.fromNamedNode(field, ReferenceNameKind.Field),
              field));
      add(
          ReferenceNameKind.Getter,
          new ReferenceNameObject(
              ReferenceName.fromNamedNode(field, ReferenceNameKind.Getter),
              field));
      if (field.hasSetter) {
        add(
            ReferenceNameKind.Setter,
            new ReferenceNameObject(
                ReferenceName.fromNamedNode(field, ReferenceNameKind.Setter),
                field));
      }
    }
    for (Procedure procedure in library.procedures) {
      ReferenceNameKind kind;
      if (procedure.isGetter) {
        kind = ReferenceNameKind.Getter;
      } else if (procedure.isSetter) {
        kind = ReferenceNameKind.Setter;
      } else {
        kind = ReferenceNameKind.Function;
      }
      add(
          kind,
          new ReferenceNameObject(
              ReferenceName.fromNamedNode(procedure), procedure));
    }
    for (Class cls in library.classes) {
      add(ReferenceNameKind.Declaration,
          new ReferenceNameObject(ReferenceName.fromNamedNode(cls), cls));

      for (Constructor constructor in cls.constructors) {
        add(
            ReferenceNameKind.Function,
            new ReferenceNameObject(
                ReferenceName.fromNamedNode(constructor), constructor));
      }
      for (Procedure procedure in cls.procedures) {
        ReferenceNameKind kind;
        if (procedure.isGetter) {
          kind = ReferenceNameKind.Getter;
        } else if (procedure.isSetter) {
          kind = ReferenceNameKind.Setter;
        } else {
          kind = ReferenceNameKind.Function;
        }
        add(
            kind,
            new ReferenceNameObject(
                ReferenceName.fromNamedNode(procedure), procedure));
      }
      for (Field field in cls.fields) {
        add(ReferenceNameKind.Field,
            new ReferenceNameObject(ReferenceName.fromNamedNode(field), field));
        add(
            ReferenceNameKind.Getter,
            new ReferenceNameObject(
                ReferenceName.fromNamedNode(field, ReferenceNameKind.Getter),
                field));
        if (field.hasSetter) {
          add(
              ReferenceNameKind.Setter,
              new ReferenceNameObject(
                  ReferenceName.fromNamedNode(field, ReferenceNameKind.Setter),
                  field));
        }
      }
    }
    for (Extension extension in library.extensions) {
      add(
          ReferenceNameKind.Declaration,
          new ReferenceNameObject(
              ReferenceName.fromNamedNode(extension), extension));
    }
  }
  sortReferenceNames(map);
  return map;
}

Map<ReferenceNameKind, List<ReferenceNameObject>>
    computeReferenceNamesFromCanonicalName(CanonicalName root) {
  Map<ReferenceNameKind, List<ReferenceNameObject>> map = {};

  void visit(CanonicalName canonicalName, ReferenceNameKind kind) {
    void addObject() {
      (map[kind] ??= []).add(new ReferenceNameObject(
          ReferenceName.fromCanonicalName(canonicalName), canonicalName));
    }

    switch (kind) {
      case ReferenceNameKind.Unknown:
        for (CanonicalName child in canonicalName.children) {
          visit(child, ReferenceNameKind.Library);
        }
        break;
      case ReferenceNameKind.Library:
        addObject();
        for (CanonicalName child in canonicalName.children) {
          ReferenceNameKind childKind = ReferenceNameKind.Declaration;
          if (CanonicalName.isSymbolicName(child.name)) {
            childKind = ReferenceName.kindFromSymbolicName(child.name);
          }
          visit(child, childKind);
        }
        break;
      case ReferenceNameKind.Declaration:
        addObject();
        for (CanonicalName child in canonicalName.children) {
          visit(child, ReferenceName.kindFromSymbolicName(child.name));
        }
        break;
      case ReferenceNameKind.Typedef:
      case ReferenceNameKind.Function:
      case ReferenceNameKind.Field:
      case ReferenceNameKind.Getter:
      case ReferenceNameKind.Setter:
        if (canonicalName.childrenOrNull != null) {
          // Private name
          for (CanonicalName child in canonicalName.children) {
            visit(child, kind);
          }
        } else {
          addObject();
        }
        break;
    }
  }

  visit(root, ReferenceNameKind.Unknown);

  sortReferenceNames(map);
  return map;
}

class ReferenceNameObject {
  final ReferenceName referenceName;
  final Object object;

  ReferenceNameObject(this.referenceName, this.object);
}
