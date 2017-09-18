// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This transformations outputs a Coq definitions to resemble the Dart syntax
// tree.
//
// Classes that are supposed to be converted are marked with the `@coq`
// annotation. Some fields within these classes will be converted according to
// the following rules:
//
// 1. A field labeled `@nocoq` will not be converted.
//
// 2. A field labeled `@coq` or `@coqopt` will be converted unless it's type is
// unuspported, in which case an exception will be raised.
//
// 3. An unannotated field will be converted if it has type `T` or `List<T>`,
// where `T` is a class marked for conversion.
//
// Classes marked `@coqref` are referenced by natural numbered IDs wherever
// fields of their type appear, and we have a finite map resolving these IDs.
// This breaks cycles in the AST graph and provides a way to identify nodes for
// substitution.
//
// All classes with data members are given an induction type definition with a
// single constructor, holding the data members of that class. Classes with
// subclasses are also given an inductive definition enumerating all (converted)
// subclasses. Their data-member type definition will appear inline in the data
// member definitions for their leaf subclasses. Due to this representation,
// converted classes with subclasses must be abstract.
//
// Since the whole syntax tree is mutually recursive, all the types are dumped
// into one big "Inductive ... with ... with ... " definition.

library kernel.transformations.coq;

import 'dart:io';
import '../ast.dart';
import '../coq_annot.dart' as coq_annot;
import '../core_types.dart' show CoreTypes;

enum RefStyle { direct, identified }

enum FieldStyle { list, optional, normal }

class CoqFieldInfo {
  // Only one of these two may be non-null.
  final CoqClassInfo type;
  final String primitiveCoqType;

  final String dartName;
  final FieldStyle style;
  bool definitional = false;

  String get innerRefType => type == null ? primitiveCoqType : type.refType;

  String get refType {
    if (type != null) {
      var rt = definitional ? type.coqType : type.refType;
      if (style == FieldStyle.list) {
        return "list $rt";
      } else if (style == FieldStyle.optional) {
        return "option $rt";
      } else {
        return rt;
      }
    } else {
      if (style == FieldStyle.list) {
        return "list " + primitiveCoqType;
      } else if (style == FieldStyle.optional) {
        return "option " + primitiveCoqType;
      } else {
        return primitiveCoqType;
      }
    }
  }

  CoqFieldInfo(this.dartName, this.type, this.primitiveCoqType, this.style);
}

class CoqClassInfo {
  final Class cls;
  final RefStyle refStyle;

  List<CoqClassInfo> subs = <CoqClassInfo>[];
  List<CoqFieldInfo> fields = <CoqFieldInfo>[];

  bool needsOption = false;
  bool needsList = false;

  String get coqType => coqifyName(cls.name);
  String get coqTypeCaps => coqifyName(cls.name, capitalize: true);
  String get abbrevName => abbrev(cls.name);
  String get abbrevNameCaps => abbrev(cls.name, capitalize: true);
  String get refType => refStyle == RefStyle.direct ? coqType : "nat";

  CoqClassInfo(this.cls, this.refStyle);

  Iterable<CoqClassInfo> supersWithData(CoqLibInfo info) sync* {
    for (Supertype st = cls.supertype;
        st != null;
        st = st.classNode.supertype) {
      Class spr = st.classNode;
      var sprInfo = info.classes[spr];
      if (sprInfo == null) break;
      if (sprInfo.fields.length == 0) continue;
      yield sprInfo;
    }
  }
}

class CoqLibInfo {
  final Map<Class, CoqClassInfo> classes = <Class, CoqClassInfo>{};
  CoqLibInfo();
}

// Get the number associated with the annotation from `coq_annot.dart` on a
// [Field] or [Class] if one exists, and 0 otherwise. Throws an exception if
// invalid or multiple annotations are discoverted.
int getCoqAnnot(NamedNode N, List<Expression> annotations) {
  if (coq_annot.coqEnums.contains("$N")) {
    return coq_annot.coq;
  }

  int annot = 0;
  for (var A in annotations) {
    if (A is StaticGet) {
      var target = A.targetReference.node;
      var parent = target.parent;
      if (parent is Library) {
        if (parent is NamedNode && parent.name == "kernel.coq_annot") {
          if (target is Field) {
            if (annot != 0) {
              throw new Exception("ERROR: Multiple Coq annotations on ${N}!");
            }
            switch ("${target.name}") {
              case "coq":
                annot = coq_annot.coq;
                break;
              case "coqref":
                annot = coq_annot.coqref;
                break;
              case "nocoq":
                annot = coq_annot.nocoq;
                break;
              case "coqopt":
                annot = coq_annot.coqopt;
                break;
              case "coqsingle":
                annot = coq_annot.coqsingle;
                break;
              case "coqdef":
                annot = coq_annot.coqdef;
                break;
              case "coqsingledef":
                annot = coq_annot.coqsingledef;
                break;
              default:
                throw new Exception("ERROR: Invalid Coq annotation on ${N}!");
            }
          } else {
            throw new Exception("ERROR: Invalid Coq annotation on ${N}!");
          }
        }
      }
    }
  }
  return annot;
}

// Determine which classes we're going to convert.
class CoqPass1 extends RecursiveVisitor {
  CoqLibInfo info;
  CoqPass1(this.info);

  visitClass(Class C) {
    int annot = getCoqAnnot(C, C.annotations);
    if (annot == 0) return;

    if (annot != coq_annot.coq && annot != coq_annot.coqref) {
      throw new Exception("ERROR: Invalid Coq annotation on ${C.name}!");
    }

    info.classes[C] = new CoqClassInfo(
        C, annot == coq_annot.coq ? RefStyle.direct : RefStyle.identified);
  }
}

// Determine which fields we're going to convert and which classes have
// converted subclasses.
class CoqPass2 extends RecursiveVisitor {
  CoqLibInfo info;
  CoreTypes coreTypes;
  CoqPass2(this.info, this.coreTypes);

  CoqClassInfo currentClass = null;

  String getCoqPrimitiveType(Class cls) {
    if (cls == coreTypes.stringClass) {
      return "string";
    } else if (cls == coreTypes.boolClass) {
      return "bool";
    } else if (cls == coreTypes.intClass) {
      return "nat";
    } else {
      return null;
    }
  }

  visitClass(Class C) {
    var classInfo = info.classes[C];
    if (classInfo == null) return;

    if (C.supertype != null) {
      Class spr = C.supertype.classNode;
      var sprInfo = info.classes[spr];
      if (sprInfo != null) {
        sprInfo.subs.add(classInfo);
      }
    }

    currentClass = classInfo;
    C.visitChildren(this);
    currentClass = null;
  }

  visitField(Field F) {
    if (currentClass == null) return;

    int annot = getCoqAnnot(F, F.annotations);
    if (annot == coq_annot.nocoq) return;

    var type = F.type;
    if (type is! InterfaceType) return;

    var interfaceType = type as InterfaceType;

    var cls = null;
    bool isList = false;

    if (interfaceType.classNode == coreTypes.listClass) {
      isList = annot != coq_annot.coqsingle && annot != coq_annot.coqsingledef;
      if (interfaceType.typeArguments.length != 1) return;
      var elemType = interfaceType.typeArguments[0];
      if (elemType is InterfaceType) {
        cls = elemType.classNode;
      } else if (annot == coq_annot.coqopt) {
        throw new Exception("ERROR: Field $F may not be optional.");
      }
    } else {
      cls = interfaceType.classNode;
    }

    FieldStyle style = isList
        ? FieldStyle.list
        : (annot == coq_annot.coqopt ? FieldStyle.optional : FieldStyle.normal);

    CoqFieldInfo fieldInfo = null;
    var primitive = getCoqPrimitiveType(cls);
    var fieldName = F.name.name;

    if (primitive != null) {
      if (annot == 0) return;
      fieldInfo = new CoqFieldInfo(fieldName, null, primitive, style);
    } else {
      var fieldClassInfo = info.classes[cls];
      if (fieldClassInfo == null) {
        return;
      }
      fieldInfo = new CoqFieldInfo(fieldName, fieldClassInfo, null, style);

      if (style == FieldStyle.optional) {
        fieldClassInfo.needsOption = true;
      } else if (style == FieldStyle.list) {
        fieldClassInfo.needsList = true;
      }

      if (annot == coq_annot.coqdef || annot == coq_annot.coqsingledef) {
        fieldInfo.definitional = true;
      }
    }

    currentClass.fields.add(fieldInfo);
  }
}

// Conventional Coq code uses underscores instead of camelCase as Dart code
// does. This function converts the Dart convention to the Coq convention.
final coqReserved = <String>["let"];
String coqifyName(String S, {bool capitalize: false}) {
  List<int> codes = <int>[];
  bool skipUnderscore = false;
  for (int i = 0; i < S.length; ++i) {
    var c = S.codeUnitAt(i);
    if (c >= "A".codeUnits[0] && c <= "Z".codeUnits[0]) {
      if (i > 0 && !skipUnderscore) {
        codes.add("_".codeUnitAt(0));
      }
      if (!capitalize) c += ("a".codeUnits[0] - "A".codeUnits[0]);
      codes.add(c);
    } else {
      codes.add(c);
    }
    skipUnderscore = c == "_".codeUnits[0];
  }
  var name = new String.fromCharCodes(codes);
  if (coqReserved.contains(name)) {
    name = "dart_" + name;
  }
  return name;
}

// Give an abbreviation of a identifying by combining the capital letters of the
// identifier. For example, "ProcedureKind" becomes "pk" or "PK".
String abbrev(String S, {bool capitalize: false}) {
  List<int> codes = <int>[];
  for (var c in S.codeUnits)
    if (c >= 65 && c <= 90) codes.add(capitalize ? c : c + 32);
  return new String.fromCharCodes(codes);
}

void outputCoqImports() {
  print("""
Require Import Common.
""");
}

void outputCoqSyntax(CoqLibInfo info) {
  int defN = 0;
  defkw() => defN++ > 0 ? "with" : "Inductive";
  for (var classInfo in info.classes.values) {
    bool isAbstract = classInfo.subs.length > 0;

    Class cls = classInfo.cls;
    var coqName = classInfo.coqType;

    if (classInfo.cls.isEnum) {
      var enums = [];
      for (var fld in classInfo.fields) {
        if (fld.dartName == "values") continue;
        enums.add(coqifyName(fld.dartName, capitalize: true));
      }
      print("${defkw()} $coqName : Set := ${enums.join(" | ")}\n");
      continue;
    }

    if (!isAbstract || classInfo.fields.length > 0) {
      var suffix = isAbstract ? "_data" : "";
      var dataTypeName = coqName + suffix;
      var dataCtorName = coqifyName(cls.name, capitalize: true);

      print("${defkw()} ${dataTypeName} : Set :=");
      print("  | ${dataCtorName} : ");

      // Insert fields for superclasses.
      int arw = 0;
      arrow() => arw++ == 0 ? "" : "-> ";

      if (classInfo.refStyle == RefStyle.identified) {
        print("      ${arrow()}nat");
      }

      for (var sprInfo in classInfo.supersWithData(info)) {
        print("      ${arrow()}${sprInfo.coqType}_data");
      }

      for (CoqFieldInfo fld in classInfo.fields) {
        print("      ${arrow()}${fld.refType} (* ${fld.dartName} *)");
      }

      print("      ${arrow()}$dataTypeName\n");
    }

    if (classInfo.subs.length > 0) {
      print("${defkw()} $coqName : Set :=");

      var abbrevName = abbrev(cls.name, capitalize: true);
      for (var sub in classInfo.subs) {
        var subTypeName = coqifyName(sub.cls.name);
        var ctorName = coqifyName(sub.cls.name, capitalize: true);
        print("  | ${abbrevName}_${ctorName} : ${subTypeName} -> $coqName");
      }

      print("\n");
    }
  }
  print(".\n");
}

void outputCoqStore(info) {
  print("Record ast_store : Type := Ast_Store {");
  for (var classInfo in info.classes.values) {
    if (classInfo.refStyle != RefStyle.identified) continue;
    print("  ${classInfo.abbrevName}_refs : NatMap.t ${classInfo.coqType};");
  }
  print("}.\n");
}

void outputCoqSyntaxValidity(CoqLibInfo info) {
  int defN = 0;
  defkw() => defN++ > 0 ? "with" : "Fixpoint";

  validityPredicate(CoqClassInfo CI) {
    if (CI.refStyle == RefStyle.identified) {
      var mapName = "${CI.abbrevName}_refs";
      return (X) => "NatMap.In $X ($mapName ast)";
    } else {
      return (X) => "${CI.coqType}_validity ast $X";
    }
  }

  for (var CI in info.classes.values) {
    stdout.write(
        "${defkw()} ${CI.coqType}_validity (ast : ast_store) (T : ${CI.coqType}) {struct T} : Prop :=");
    if (CI.cls.isEnum) {
      stdout.write(" True\n");
      continue;
    } else {
      stdout.write("\n");
    }

    print("  match T with");
    for (var sub in CI.subs) {
      print(
          "    | ${CI.abbrevNameCaps}_${sub.coqTypeCaps} ST => ${sub.coqType}_validity ast ST");
    }

    if (CI.subs.length > 0) {
      print("end");
      if (CI.fields.length == 0) continue;
      print(
          "${defkw()} ${CI.coqType}_data_validity (ast : ast_store) (T : ${CI.coqType}_data) {struct T}: Prop :=");
      print("  match T with");
    }

    int i = 0;
    var fieldNames = [];
    var validityClauses = [];

    for (var SI in CI.supersWithData(info)) {
      var f = "f${i++}";
      fieldNames.add(f);
      validityClauses.add("${SI.coqType}_data_validity ast $f");
    }

    for (var fld in CI.fields) {
      if (fld.type == null) {
        fieldNames.add("_");
        continue;
      }

      var f = "f${i++}";
      fieldNames.add(f);

      var pred;
      if (fld.style == FieldStyle.normal) {
        pred = validityPredicate(fld.type)(f);
      } else if (fld.style == FieldStyle.list) {
        pred = "${fld.type.coqType}_list_validity ast $f";
      } else if (fld.style == FieldStyle.optional) {
        pred = "${fld.type.coqType}_option_validity ast $f";
      }

      validityClauses.add(pred);
    }

    var clause = "True";
    if (validityClauses.length > 0) {
      clause = validityClauses.join(" /\\\n        ");
    }

    print(
        "    | ${CI.coqTypeCaps} ${fieldNames.join(" ")} =>\n        $clause");
    print("  end");
  }

  for (var CI in info.classes.values) {
    var pred = validityPredicate(CI)("X");
    if (CI.needsList) {
      var def = """
with ${CI.coqType}_list_validity (ast : ast_store) (L : ${CI.coqType}_list) {struct L} : Prop :=
  match L with
    | ${CI.coqType}_nil => True
    | ${CI.coqType}_cons X XS => $pred /\\ ${CI.coqType}_list_validity ast XS
  end""";
      print(def);
    }
    if (CI.needsOption) {
      var def = """
with ${CI.coqType}_option_validity (ast : ast_store) (O : ${CI.coqType}_option) {struct O} : Prop :=
  match O with
    | ${CI.coqType}_none => True
    | ${CI.coqType}_some X => $pred
  end""";
      print(def);
    }
  }

  print(".\n");
}

void outputCoqStoreValidity(CoqLibInfo info) {
  var clauses = [];
  for (var CI in info.classes.values) {
    if (CI.refStyle != RefStyle.identified) continue;
    var mapName = "${CI.abbrevName}_refs";
    clauses.add(
        "  forall (n : nat), forall (X : ${CI.coqType}), NatMap.MapsTo n X ($mapName ast) -> ${CI.coqType}_validity ast X");
  }
  var clause = clauses.join(" /\\\n");
  print(
      "Definition ast_store_validity (ast : ast_store) : Prop := \n$clause\n.");
}

Program transformProgram(CoreTypes coreTypes, Program program) {
  for (Library lib in program.libraries) {
    // TODO(30610): Ideally we'd output to the file in the coq annotation on the
    // library name, but currently fasta throws away annotations on libraries.
    // Instead, we just special case "kernel.ast" and output to stdout.
    if ("$lib" != "kernel.ast") continue;
    var info = new CoqLibInfo();
    (new CoqPass1(info)).visitLibrary(lib);
    (new CoqPass2(info, coreTypes)).visitLibrary(lib);
    outputCoqImports();
    outputCoqSyntax(info);
  }
  return program;
}
