// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.serialization_test;

import 'dart:io';
import 'memory_compiler.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/constants/constructors.dart';
import 'package:compiler/src/constants/expressions.dart';
import 'package:compiler/src/dart_types.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/diagnostics/invariant.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/elements/visitor.dart';
import 'package:compiler/src/ordered_typeset.dart';
import 'package:compiler/src/serialization/serialization.dart';
import 'package:compiler/src/serialization/json_serializer.dart';
import 'package:compiler/src/tree/tree.dart';

main(List<String> arguments) {
  // Ensure that we can print out constant expressions.
  DEBUG_MODE = true;

  Uri entryPoint;
  String outPath;
  bool prettyPrint = false;
  for (String arg in arguments) {
    if (arg.startsWith('--')) {
      if (arg.startsWith('--out=')) {
        outPath = arg.substring('--out='.length);
      } else if (arg == '--pretty-print') {
        prettyPrint = true;
      } else {
        print("Unknown option $arg");
      }
    } else {
      if (entryPoint != null) {
        print("Multiple entrypoints is not supported.");
      }
      entryPoint = Uri.parse(arg);
    }
  }
  if (entryPoint == null) {
    entryPoint = Uri.parse('dart:core');
  }
  asyncTest(() async {
    CompilationResult result = await runCompiler(
        entryPoint: entryPoint, options: ['--analyze-all']);
    Compiler compiler = result.compiler;
    testSerialization(compiler.libraryLoader.libraries,
                      outPath: outPath,
                      prettyPrint: prettyPrint);
  });
}

void testSerialization(Iterable<LibraryElement> libraries1,
                       {String outPath,
                        bool prettyPrint}) {
  Serializer serializer = new Serializer(const JsonSerializationEncoder());
  for (LibraryElement library1 in libraries1) {
    serializer.serialize(library1);
  }
  String text = serializer.toText();
  String outText = text;
  if (prettyPrint) {
    outText = serializer.prettyPrint();
  }
  if (outPath != null) {
    new File(outPath).writeAsStringSync(outText);
  } else if (prettyPrint) {
    print(outText);
  }

  Deserializer deserializer = new Deserializer.fromText(
      text, const JsonSerializationDecoder());
  List<LibraryElement> libraries2 = <LibraryElement>[];
  for (LibraryElement library1 in libraries1) {
    LibraryElement library2 =
        deserializer.lookupLibrary(library1.canonicalUri);
    if (library2 == null) {
      throw new ArgumentError('No library ${library1.canonicalUri} found.');
    }
    checkLibraryContent('library1', 'library2', 'library', library1, library2);
    libraries2.add(library2);
  }

  Serializer serializer2 = new Serializer(const JsonSerializationEncoder());
  for (LibraryElement library2 in libraries2) {
    serializer2.serialize(library2);
  }
  String text2 = serializer2.toText();

  Deserializer deserializer3 = new Deserializer.fromText(
      text2, const JsonSerializationDecoder());
  for (LibraryElement library1 in libraries1) {
    LibraryElement library2 =
        deserializer.lookupLibrary(library1.canonicalUri);
    if (library2 == null) {
      throw new ArgumentError('No library ${library1.canonicalUri} found.');
    }
    LibraryElement library3 =
        deserializer3.lookupLibrary(library1.canonicalUri);
    if (library3 == null) {
      throw new ArgumentError('No library ${library1.canonicalUri} found.');
    }
    checkLibraryContent('library1', 'library3', 'library', library1, library3);
    checkLibraryContent('library2', 'library3', 'library', library2, library3);
  }
}

/// Check the equivalence of [library1] and [library2] and their content.
///
/// Uses [object1], [object2] and [property] to provide context for failures.
checkLibraryContent(
    Object object1, object2, String property,
    LibraryElement library1, LibraryElement library2) {
  checkElementProperties(object1, object2, property, library1, library2);
}

/// Check the equivalence of [element1] and [element2] and their properties.
///
/// Uses [object1], [object2] and [property] to provide context for failures.
checkElementProperties(
    Object object1, object2, String property,
    Element element1, Element element2) {
  const ElementPropertyEquivalence().visit(element1, element2);
}

/// Check the equivalence of the two lists of elements, [list1] and [list2].
///
/// Uses [object1], [object2] and [property] to provide context for failures.
checkElementLists(Object object1, Object object2, String property,
                  Iterable<Element> list1, Iterable<Element> list2) {
  checkListEquivalence(object1, object2, property,
                  list1, list2, checkElementProperties);
}

/// Check equivalence of the two lists, [list1] and [list2], using
/// [checkEquivalence] to check the pair-wise equivalence.
///
/// Uses [object1], [object2] and [property] to provide context for failures.
void checkListEquivalence(
    Object object1, Object object2, String property,
    Iterable list1, Iterable list2,
    void checkEquivalence(o1, o2, property, a, b)) {
  for (int i = 0; i < list1.length && i < list2.length; i++) {
    checkEquivalence(
        object1, object2, property,
        list1.elementAt(i), list2.elementAt(i));
  }
  for (int i = list1.length; i < list2.length; i++) {
    throw
        'Missing equivalent for element '
        '#$i ${list2.elementAt(i)} in `${property}` on $object2.\n'
        '`${property}` on $object1:\n ${list1.join('\n ')}\n'
        '`${property}` on $object2:\n ${list2.join('\n ')}';
  }
  for (int i = list2.length; i < list1.length; i++) {
    throw
        'Missing equivalent for element '
        '#$i ${list1.elementAt(i)} in `${property}` on $object1.\n'
        '`${property}` on $object1:\n ${list1.join('\n ')}\n'
        '`${property}` on $object2:\n ${list2.join('\n ')}';
  }
}

/// Checks the equivalence of the identity (but not properties) of [element1]
/// and [element2].
///
/// Uses [object1], [object2] and [property] to provide context for failures.
void checkElementIdentities(
    Object object1, Object object2, String property,
    Element element1, Element element2) {
  if (identical(element1, element2)) return;
  if (element1 == null || element2 == null) {
    check(object1, object2, property, element1, element2);
  }
  const ElementIdentityEquivalence().visit(element1, element2);
}

/// Checks the pair-wise equivalence of the identity (but not properties) of the
/// elements in [list] and [list2].
///
/// Uses [object1], [object2] and [property] to provide context for failures.
void checkElementListIdentities(
    Object object1, Object object2, String property,
    Iterable<Element> list1, Iterable<Element> list2) {
  checkListEquivalence(
      object1, object2, property,
      list1, list2, checkElementIdentities);
}

/// Checks the equivalence of [type1] and [type2].
///
/// Uses [object1], [object2] and [property] to provide context for failures.
void checkTypes(
    Object object1, Object object2, String property,
    DartType type1, DartType type2) {
  if (identical(type1, type2)) return;
  if (type1 == null || type2 == null) {
    check(object1, object2, property, type1, type2);
  }
  const TypeEquivalence().visit(type1, type2);
}

/// Checks the pair-wise equivalence of the types in [list1] and [list2].
///
/// Uses [object1], [object2] and [property] to provide context for failures.
void checkTypeLists(
    Object object1, Object object2, String property,
    List<DartType> list1, List<DartType> list2) {
  checkListEquivalence(object1, object2, property, list1, list2, checkTypes);
}

/// Checks the equivalence of [exp1] and [exp2].
///
/// Uses [object1], [object2] and [property] to provide context for failures.
void checkConstants(
    Object object1, Object object2, String property,
    ConstantExpression exp1, ConstantExpression exp2) {
  if (identical(exp1, exp2)) return;
  if (exp1 == null || exp2 == null) {
    check(object1, object2, property, exp1, exp2);
  }
  const ConstantEquivalence().visit(exp1, exp2);
}

/// Checks the pair-wise equivalence of the contants in [list1] and [list2].
///
/// Uses [object1], [object2] and [property] to provide context for failures.
void checkConstantLists(
    Object object1, Object object2, String property,
    List<ConstantExpression> list1,
    List<ConstantExpression> list2) {
  checkListEquivalence(
      object1, object2, property,
      list1, list2, checkConstants);
}

/// Checks the equivalence of [constructor1] and [constructor2].
void constantConstructorEquivalence(ConstantConstructor constructor1,
                                    ConstantConstructor constructor2) {
  const ConstantConstructorEquivalence().visit(constructor1, constructor2);
}

/// Visitor that checks the equivalence of [ConstantConstructor]s.
class ConstantConstructorEquivalence
    extends ConstantConstructorVisitor<dynamic, ConstantConstructor> {
  const ConstantConstructorEquivalence();

  @override
  void visit(ConstantConstructor constructor1,
             ConstantConstructor constructor2) {
    if (identical(constructor1, constructor2)) return;
    check(constructor1, constructor2, 'kind',
          constructor1.kind, constructor2.kind);
    constructor1.accept(this, constructor2);
  }

  @override
  visitGenerative(
      GenerativeConstantConstructor constructor1,
      GenerativeConstantConstructor constructor2) {
    checkTypes(
        constructor1, constructor2, 'type',
        constructor1.type, constructor2.type);
    check(constructor1, constructor2, 'defaultValues.length',
          constructor1.defaultValues.length,
          constructor2.defaultValues.length);
    constructor1.defaultValues.forEach((k, v) {
      checkConstants(
          constructor1, constructor2, 'defaultValue[$k]',
          v, constructor2.defaultValues[k]);
    });
    check(constructor1, constructor2, 'fieldMap.length',
          constructor1.fieldMap.length,
          constructor2.fieldMap.length);
    constructor1.fieldMap.forEach((k1, v1) {
      bool matched = false;
      constructor2.fieldMap.forEach((k2, v2) {
        if (k1.name == k2.name &&
            k1.library.canonicalUri == k2.library.canonicalUri) {
          checkElementIdentities(
              constructor1, constructor2, 'fieldMap[${k1.name}].key', k1, k2);
          checkConstants(
              constructor1, constructor2, 'fieldMap[${k1.name}].value', v1, v2);
          matched = true;
        }
      });
      if (!matched) {
        throw 'Unmatched field $k1 = $v1';
      }
    });
    checkConstants(
        constructor1, constructor2, 'superConstructorInvocation',
        constructor1.superConstructorInvocation,
        constructor2.superConstructorInvocation);
  }

  @override
  visitRedirectingFactory(
      RedirectingFactoryConstantConstructor constructor1,
      RedirectingFactoryConstantConstructor constructor2) {
    checkConstants(
        constructor1, constructor2, 'targetConstructorInvocation',
        constructor1.targetConstructorInvocation,
        constructor2.targetConstructorInvocation);
  }

  @override
  visitRedirectingGenerative(
      RedirectingGenerativeConstantConstructor constructor1,
      RedirectingGenerativeConstantConstructor constructor2) {
    check(constructor1, constructor2, 'defaultValues.length',
          constructor1.defaultValues.length,
          constructor2.defaultValues.length);
    constructor1.defaultValues.forEach((k, v) {
      checkConstants(
          constructor1, constructor2, 'defaultValue[$k]',
          v, constructor2.defaultValues[k]);
    });
    checkConstants(
        constructor1, constructor2, 'thisConstructorInvocation',
        constructor1.thisConstructorInvocation,
        constructor2.thisConstructorInvocation);
  }
}

/// Check that the values [property] of [object1] and [object2], [value1] and
/// [value2] respectively, are equal and throw otherwise.
void check(var object1, var object2, String property, var value1, value2) {
  if (value1 != value2) {
    throw "$object1.$property = '${value1}' <> "
          "$object2.$property = '${value2}'";
  }
}

/// Visitor that checks for equivalence of [Element] identities.
class ElementIdentityEquivalence extends BaseElementVisitor<dynamic, Element> {
  const ElementIdentityEquivalence();

  void visit(Element element1, Element element2) {
    check(element1, element2, 'kind', element1.kind, element2.kind);
    element1.accept(this, element2);
  }

  @override
  void visitElement(Element e, Element arg) {
    throw new UnsupportedError("Unsupported element $e");
  }

  @override
  void visitLibraryElement(LibraryElement element1, LibraryElement element2) {
    check(element1, element2,
          'canonicalUri',
          element1.canonicalUri, element2.canonicalUri);
  }

  @override
  void visitCompilationUnitElement(CompilationUnitElement element1,
                                   CompilationUnitElement element2) {
    check(element1, element2,
          'name',
          element1.name, element2.name);
    visit(element1.library, element2.library);
  }

  @override
  void visitClassElement(ClassElement element1, ClassElement element2) {
    check(element1, element2,
          'name',
          element1.name, element2.name);
    visit(element1.library, element2.library);
  }

  void checkMembers(Element element1, Element element2) {
    check(element1, element2,
          'name',
          element1.name, element2.name);
    if (element1.enclosingClass != null || element2.enclosingClass != null) {
      visit(element1.enclosingClass, element2.enclosingClass);
    } else {
      visit(element1.library, element2.library);
    }
  }

  @override
  void visitFieldElement(FieldElement element1, FieldElement element2) {
    checkMembers(element1, element2);
  }

  @override
  void visitFunctionElement(FunctionElement element1,
                            FunctionElement element2) {
    checkMembers(element1, element2);
  }

  void visitAbstractFieldElement(AbstractFieldElement element1,
                                 AbstractFieldElement element2) {
    checkMembers(element1, element2);
  }

  @override
  void visitTypeVariableElement(TypeVariableElement element1,
                                TypeVariableElement element2) {
    check(element1, element2,
          'name',
          element1.name, element2.name);
    visit(element1.typeDeclaration, element2.typeDeclaration);
  }

  @override
  void visitTypedefElement(TypedefElement element1, TypedefElement element2) {
    check(element1, element2,
          'name',
          element1.name, element2.name);
    visit(element1.library, element2.library);
  }

  @override
  void visitParameterElement(ParameterElement element1,
                             ParameterElement element2) {
    check(element1, element2,
          'name',
          element1.name, element2.name);
    visit(element1.functionDeclaration, element2.functionDeclaration);
  }
}

/// Visitor that checks for equivalence of [Element] properties.
class ElementPropertyEquivalence extends BaseElementVisitor<dynamic, Element> {
  const ElementPropertyEquivalence();

  void visit(Element element1, Element element2) {
    if (element1 == element2) return;
    check(element1, element2, 'kind', element1.kind, element2.kind);
    element1.accept(this, element2);
  }

  @override
  void visitElement(Element e, Element arg) {
    throw new UnsupportedError("Unsupported element $e");
  }

  @override
  void visitLibraryElement(LibraryElement element1, LibraryElement element2) {
    checkElementIdentities(null, null, null, element1, element2);
    check(element1, element2, 'name', element1.name, element2.name);
    check(element1, element2, 'getLibraryName',
          element1.getLibraryName(), element2.getLibraryName());
    visitMembers(element1, element2);
    visit(element1.entryCompilationUnit, element2.entryCompilationUnit);
    checkElementLists(
        element1, element2, 'compilationUnits',
        element1.compilationUnits.toList(),
        element2.compilationUnits.toList());

    bool filterTags(LibraryTag tag) => tag.asLibraryDependency() != null;

    List<LibraryTag> tags1 = element1.tags.where(filterTags).toList();
    List<LibraryTag> tags2 = element2.tags.where(filterTags).toList();
    checkListEquivalence(element1, element2, 'tags', tags1, tags2,
        (Object object1, Object object2, String property,
         LibraryDependency tag1, LibraryDependency tag2) {
      checkElementIdentities(
          tag1, tag2, 'getLibraryFromTag',
          element1.getLibraryFromTag(tag1),
          element2.getLibraryFromTag(tag2));
    });

    List<Element> imports1 = <Element>[];
    List<Element> imports2 = <Element>[];
    element1.forEachImport((Element import) {
      if (import.isAmbiguous) return;
      imports1.add(import);
    });
    element2.forEachImport((Element import) {
      if (import.isAmbiguous) return;
      imports2.add(import);
    });
    checkElementListIdentities(
        element1, element2, 'imports', imports1, imports2);

    List<Element> exports1 = <Element>[];
    List<Element> exports2 = <Element>[];
    element1.forEachExport((Element export) {
      if (export.isAmbiguous) return;
      exports1.add(export);
    });
    element2.forEachExport((Element export) {
      if (export.isAmbiguous) return;
      exports2.add(export);
    });
    checkElementListIdentities(
        element1, element2, 'exports', exports1, exports2);
  }

  @override
  void visitCompilationUnitElement(CompilationUnitElement element1,
                                   CompilationUnitElement element2) {
    check(element1, element2,
          'name',
          element1.name, element2.name);
    checkElementIdentities(
        element1, element2, 'library',
        element1.library, element2.library);
    check(element1, element2,
          'script.resourceUri',
          element1.script.resourceUri, element2.script.resourceUri);
    List<Element> members1 = <Element>[];
    List<Element> members2 = <Element>[];
    element1.forEachLocalMember((Element member) {
      members1.add(member);
    });
    element2.forEachLocalMember((Element member) {
      members2.add(member);
    });
    checkElementListIdentities(
        element1, element2, 'localMembers', members1, members2);
  }

  void visitMembers(ScopeContainerElement element1,
                    ScopeContainerElement element2) {
    Set<String> names = new Set<String>();
    element1.forEachLocalMember((Element member) {
      names.add(member.name);
    });
    element2.forEachLocalMember((Element member) {
      names.add(member.name);
    });
    for (String name in names) {
      Element member1 = element1.localLookup(name);
      Element member2 = element2.localLookup(name);
      if (member1 == null) {
        print('Missing member for $member2');
        continue;
      }
      if (member2 == null) {
        print('Missing member for $member1');
        continue;
      }
      visit(member1, member2);
    }
  }

  @override
  void visitClassElement(ClassElement element1, ClassElement element2) {
    checkElementIdentities(null, null, null, element1, element2);
    check(element1, element2, 'name',
          element1.name, element2.name);
    check(element1, element2, 'sourcePosition',
          element1.sourcePosition, element2.sourcePosition);
    checkElementIdentities(
        element1, element2, 'library',
        element1.library, element2.library);
    checkElementIdentities(
        element1, element2, 'compilationUnit',
        element1.compilationUnit, element2.compilationUnit);
    check(element1, element2, 'isObject',
        element1.isObject, element2.isObject);
    checkTypeLists(element1, element2, 'typeVariables',
        element1.typeVariables, element2.typeVariables);
    check(element1, element2, 'isAbstract',
        element1.isAbstract, element2.isAbstract);
    if (!element1.isObject) {
      checkTypes(element1, element2, 'supertype',
          element1.supertype, element2.supertype);
    }
    check(element1, element2, 'hierarchyDepth',
          element1.hierarchyDepth, element2.hierarchyDepth);
    checkTypeLists(
        element1, element2, 'allSupertypes',
        element1.allSupertypes.toList(),
        element2.allSupertypes.toList());
    OrderedTypeSet typeSet1 = element1.allSupertypesAndSelf;
    OrderedTypeSet typeSet2 = element1.allSupertypesAndSelf;
    checkListEquivalence(
        element1, element2, 'allSupertypes',
        typeSet1.levelOffsets,
        typeSet2.levelOffsets,
        check);
    check(element1, element2, 'allSupertypesAndSelf.levels',
          typeSet1.levels, typeSet2.levels);
    checkTypeLists(
        element1, element2, 'supertypes',
        typeSet1.supertypes.toList(),
        typeSet2.supertypes.toList());
    checkTypeLists(
        element1, element2, 'types',
        typeSet1.types.toList(),
        typeSet2.types.toList());

    checkTypeLists(
        element1, element2, 'interfaces',
        element1.interfaces.toList(),
        element2.interfaces.toList());

    visitMembers(element1, element2);
  }

  @override
  void visitFieldElement(FieldElement element1, FieldElement element2) {
    checkElementIdentities(null, null, null, element1, element2);
    check(element1, element2, 'name',
          element1.name, element2.name);
    check(element1, element2, 'sourcePosition',
          element1.sourcePosition, element2.sourcePosition);
    checkTypes(
        element1, element2, 'type',
        element1.type, element2.type);
    check(element1, element2, 'isConst',
          element1.isConst, element2.isConst);
    check(element1, element2, 'isFinal',
          element1.isFinal, element2.isFinal);
    if (element1.isConst) {
      checkConstants(
          element1, element2, 'constant',
          element1.constant, element2.constant);
    }
    check(element1, element2, 'isTopLevel',
          element1.isTopLevel, element2.isTopLevel);
    check(element1, element2, 'isStatic',
          element1.isStatic, element2.isStatic);
    check(element1, element2, 'isInstanceMember',
          element1.isInstanceMember, element2.isInstanceMember);

    checkElementIdentities(
        element1, element2, 'library',
        element1.library, element2.library);
    checkElementIdentities(
        element1, element2, 'compilationUnit',
        element1.compilationUnit, element2.compilationUnit);
    checkElementIdentities(
        element1, element2, 'enclosingClass',
        element1.enclosingClass, element2.enclosingClass);
  }

  @override
  void visitFunctionElement(FunctionElement element1,
                            FunctionElement element2) {
    checkElementIdentities(null, null, null, element1, element2);
    check(element1, element2, 'name',
          element1.name, element2.name);
    check(element1, element2, 'sourcePosition',
          element1.sourcePosition, element2.sourcePosition);
    checkTypes(
        element1, element2, 'type',
        element1.type, element2.type);
    checkListEquivalence(
        element1, element2, 'parameters',
        element1.parameters, element2.parameters,
        checkElementProperties);
    check(element1, element2, 'isOperator',
          element1.isOperator, element2.isOperator);

    checkElementIdentities(
        element1, element2, 'library',
        element1.library, element2.library);
    checkElementIdentities(
        element1, element2, 'compilationUnit',
        element1.compilationUnit, element2.compilationUnit);
    checkElementIdentities(
        element1, element2, 'enclosingClass',
        element1.enclosingClass, element2.enclosingClass);
  }

  @override
  void visitConstructorElement(ConstructorElement element1,
                               ConstructorElement element2) {
    checkElementIdentities(null, null, null, element1, element2);
    checkElementIdentities(
        element1, element2, 'enclosingClass',
        element1.enclosingClass, element2.enclosingClass);
    check(
        element1, element2, 'name',
        element1.name, element2.name);
    check(element1, element2, 'sourcePosition',
          element1.sourcePosition, element2.sourcePosition);
    checkListEquivalence(
        element1, element2, 'parameters',
        element1.parameters, element2.parameters,
        checkElementProperties);
    checkTypes(
        element1, element2, 'type',
        element1.type, element2.type);
    check(element1, element2, 'isConst',
          element1.isConst, element2.isConst);
    check(element1, element2, 'isExternal',
          element1.isExternal, element2.isExternal);
    if (element1.isConst && !element1.isExternal) {
      constantConstructorEquivalence(
          element1.constantConstructor,
          element2.constantConstructor);
    }
  }

  @override
  void visitAbstractFieldElement(AbstractFieldElement element1,
                                 AbstractFieldElement element2) {
    visit(element1.getter, element2.getter);
    visit(element1.setter, element2.setter);
  }

  @override
  void visitTypeVariableElement(TypeVariableElement element1,
                                TypeVariableElement element2) {
    checkElementIdentities(null, null, null, element1, element2);
    check(element1, element2, 'name', element1.name, element2.name);
    check(element1, element2, 'sourcePosition',
          element1.sourcePosition, element2.sourcePosition);
    check(element1, element2, 'index', element1.index, element2.index);
    checkTypes(
        element1, element2, 'type',
        element1.type, element2.type);
    checkTypes(
        element1, element2, 'bound',
        element1.bound, element2.bound);
  }

  @override
  void visitTypedefElement(TypedefElement element1,
                           TypedefElement element2) {
    checkElementIdentities(null, null, null, element1, element2);
    check(element1, element2, 'name', element1.name, element2.name);
    check(element1, element2, 'sourcePosition',
          element1.sourcePosition, element2.sourcePosition);
    checkTypes(
        element1, element2, 'alias',
        element1.alias, element2.alias);
    checkTypeLists(
        element1, element2, 'typeVariables',
        element1.typeVariables, element2.typeVariables);
    checkElementIdentities(
        element1, element2, 'library',
        element1.library, element2.library);
    checkElementIdentities(
        element1, element2, 'compilationUnit',
        element1.compilationUnit, element2.compilationUnit);
    // TODO(johnniwinther): Check the equivalence of typedef parameters.
  }

  @override
  void visitParameterElement(ParameterElement element1,
                             ParameterElement element2) {
    checkElementIdentities(null, null, null, element1, element2);
    checkElementIdentities(
        element1, element2, 'functionDeclaration',
        element1.functionDeclaration, element2.functionDeclaration);
    check(element1, element2, 'name', element1.name, element2.name);
    check(element1, element2, 'sourcePosition',
          element1.sourcePosition, element2.sourcePosition);
    checkTypes(
        element1, element2, 'type',
        element1.type, element2.type);
    check(
        element1, element2, 'isOptional',
        element1.isOptional, element2.isOptional);
    check(
        element1, element2, 'isNamed',
        element1.isNamed, element2.isNamed);
    check(element1, element2, 'name', element1.name, element2.name);
    if (element1.isOptional) {
      checkConstants(
          element1, element2, 'constant',
          element1.constant, element2.constant);
    }
    checkElementIdentities(
        element1, element2, 'compilationUnit',
        element1.compilationUnit, element2.compilationUnit);
  }

  @override
  void visitFieldParameterElement(InitializingFormalElement element1,
                                  InitializingFormalElement element2) {
    visitParameterElement(element1, element2);
    checkElementIdentities(
        element1, element2, 'fieldElement',
        element1.fieldElement, element2.fieldElement);
  }
}

/// Visitor that checks for equivalence of [DartType]s.
class TypeEquivalence implements DartTypeVisitor<dynamic, DartType> {
  const TypeEquivalence();

  void visit(DartType type1, DartType type2) {
    check(type1, type2, 'kind', type1.kind, type2.kind);
    type1.accept(this, type2);
  }

  @override
  void visitDynamicType(DynamicType type, DynamicType other) {
  }

  @override
  void visitFunctionType(FunctionType type, FunctionType other) {
    checkTypeLists(
        type, other, 'parameterTypes',
        type.parameterTypes, other.parameterTypes);
    checkTypeLists(
        type, other, 'optionalParameterTypes',
        type.optionalParameterTypes, other.optionalParameterTypes);
    checkTypeLists(
        type, other, 'namedParameterTypes',
        type.namedParameterTypes, other.namedParameterTypes);
    for (int i = 0; i < type.namedParameters.length; i++) {
      if (type.namedParameters[i] != other.namedParameters[i]) {
        throw "Named parameter '$type.namedParameters[i]' <> "
              "'${other.namedParameters[i]}'";
      }
    }
  }

  void visitGenericType(GenericType type, GenericType other) {
    checkElementIdentities(
        type, other, 'element',
        type.element, other.element);
    checkTypeLists(
        type, other, 'typeArguments',
        type.typeArguments, other.typeArguments);
  }

  @override
  void visitMalformedType(MalformedType type, MalformedType other) {
  }

  @override
  void  visitStatementType(StatementType type, StatementType other) {
    throw new UnsupportedError("Unsupported type: $type");
  }

  @override
  void visitTypeVariableType(TypeVariableType type, TypeVariableType other) {
    checkElementIdentities(
        type, other, 'element',
        type.element, other.element);
  }

  @override
  void visitVoidType(VoidType type, VoidType argument) {
  }

  @override
  void visitInterfaceType(InterfaceType type, InterfaceType other) {
    visitGenericType(type, other);
  }

  @override
  void visitTypedefType(TypedefType type, TypedefType other) {
    visitGenericType(type, other);
  }
}

/// Visitor that checks for structural equivalence of [ConstantExpression]s.
class ConstantEquivalence
    implements ConstantExpressionVisitor<dynamic, ConstantExpression> {
  const ConstantEquivalence();

  @override
  visit(ConstantExpression exp1, ConstantExpression exp2) {
    if (identical(exp1, exp2)) return;
    check(exp1, exp2, 'kind', exp1.kind, exp2.kind);
    exp1.accept(this, exp2);
  }

  @override
  visitBinary(BinaryConstantExpression exp1, BinaryConstantExpression exp2) {
    check(exp1, exp2, 'operator', exp1.operator, exp2.operator);
    checkConstants(exp1, exp2, 'left', exp1.left, exp2.left);
    checkConstants(exp1, exp2, 'right', exp1.right, exp2.right);
  }

  @override
  visitConcatenate(ConcatenateConstantExpression exp1,
                   ConcatenateConstantExpression exp2) {
    checkConstantLists(
        exp1, exp2, 'expressions',
        exp1.expressions, exp2.expressions);
  }

  @override
  visitConditional(ConditionalConstantExpression exp1,
                   ConditionalConstantExpression exp2) {
    checkConstants(
        exp1, exp2, 'condition', exp1.condition, exp2.condition);
    checkConstants(exp1, exp2, 'trueExp', exp1.trueExp, exp2.trueExp);
    checkConstants(exp1, exp2, 'falseExp', exp1.falseExp, exp2.falseExp);
  }

  @override
  visitConstructed(ConstructedConstantExpression exp1,
                   ConstructedConstantExpression exp2) {
    checkTypes(
        exp1, exp2, 'type',
        exp1.type, exp2.type);
    checkElementIdentities(
        exp1, exp2, 'target',
        exp1.target, exp2.target);
    checkConstantLists(
        exp1, exp2, 'arguments',
        exp1.arguments, exp2.arguments);
    check(exp1, exp2, 'callStructure', exp1.callStructure, exp2.callStructure);
  }

  @override
  visitFunction(FunctionConstantExpression exp1,
                FunctionConstantExpression exp2) {
    checkElementIdentities(
        exp1, exp2, 'element',
        exp1.element, exp2.element);
  }

  @override
  visitIdentical(IdenticalConstantExpression exp1,
                 IdenticalConstantExpression exp2) {
    checkConstants(exp1, exp2, 'left', exp1.left, exp2.left);
    checkConstants(exp1, exp2, 'right', exp1.right, exp2.right);
  }

  @override
  visitList(ListConstantExpression exp1, ListConstantExpression exp2) {
    checkTypes(
        exp1, exp2, 'type',
        exp1.type, exp2.type);
    checkConstantLists(
        exp1, exp2, 'values',
        exp1.values, exp2.values);
  }

  @override
  visitMap(MapConstantExpression exp1, MapConstantExpression exp2) {
    checkTypes(
        exp1, exp2, 'type',
        exp1.type, exp2.type);
    checkConstantLists(
        exp1, exp2, 'keys',
        exp1.keys, exp2.keys);
    checkConstantLists(
        exp1, exp2, 'values',
        exp1.values, exp2.values);
  }

  @override
  visitNamed(NamedArgumentReference exp1, NamedArgumentReference exp2) {
    check(exp1, exp2, 'name', exp1.name, exp2.name);
  }

  @override
  visitPositional(PositionalArgumentReference exp1,
                  PositionalArgumentReference exp2) {
    check(exp1, exp2, 'index', exp1.index, exp2.index);
  }

  @override
  visitSymbol(SymbolConstantExpression exp1, SymbolConstantExpression exp2) {
    // TODO: implement visitSymbol
  }

  @override
  visitType(TypeConstantExpression exp1, TypeConstantExpression exp2) {
    checkTypes(
        exp1, exp2, 'type',
        exp1.type, exp2.type);
  }

  @override
  visitUnary(UnaryConstantExpression exp1, UnaryConstantExpression exp2) {
    check(exp1, exp2, 'operator', exp1.operator, exp2.operator);
    checkConstants(
        exp1, exp2, 'expression', exp1.expression, exp2.expression);
  }

  @override
  visitVariable(VariableConstantExpression exp1,
                VariableConstantExpression exp2) {
    checkElementIdentities(
        exp1, exp2, 'element',
        exp1.element, exp2.element);
  }

  @override
  visitBool(BoolConstantExpression exp1, BoolConstantExpression exp2) {
    check(exp1, exp2, 'primitiveValue',
          exp1.primitiveValue, exp2.primitiveValue);
  }

  @override
  visitDouble(DoubleConstantExpression exp1, DoubleConstantExpression exp2) {
    check(exp1, exp2, 'primitiveValue',
          exp1.primitiveValue, exp2.primitiveValue);
  }

  @override
  visitInt(IntConstantExpression exp1, IntConstantExpression exp2) {
    check(exp1, exp2, 'primitiveValue',
          exp1.primitiveValue, exp2.primitiveValue);
  }

  @override
  visitNull(NullConstantExpression exp1, NullConstantExpression exp2) {
    // Do nothing.
  }

  @override
  visitString(StringConstantExpression exp1, StringConstantExpression exp2) {
    check(exp1, exp2, 'primitiveValue',
          exp1.primitiveValue, exp2.primitiveValue);
  }

  @override
  visitBoolFromEnvironment(BoolFromEnvironmentConstantExpression exp1,
                           BoolFromEnvironmentConstantExpression exp2) {
    checkConstants(exp1, exp2, 'name', exp1.name, exp2.name);
    checkConstants(
        exp1, exp2, 'defaultValue',
        exp1.defaultValue, exp2.defaultValue);
  }

  @override
  visitIntFromEnvironment(IntFromEnvironmentConstantExpression exp1,
                          IntFromEnvironmentConstantExpression exp2) {
    checkConstants(exp1, exp2, 'name', exp1.name, exp2.name);
    checkConstants(
        exp1, exp2, 'defaultValue',
        exp1.defaultValue, exp2.defaultValue);
  }

  @override
  visitStringFromEnvironment(StringFromEnvironmentConstantExpression exp1,
                             StringFromEnvironmentConstantExpression exp2) {
    checkConstants(exp1, exp2, 'name', exp1.name, exp2.name);
    checkConstants(
        exp1, exp2, 'defaultValue',
        exp1.defaultValue, exp2.defaultValue);
  }

  @override
  visitStringLength(StringLengthConstantExpression exp1,
                    StringLengthConstantExpression exp2) {
    checkConstants(
        exp1, exp2, 'expression',
        exp1.expression, exp2.expression);
  }

  @override
  visitDeferred(DeferredConstantExpression exp1,
                DeferredConstantExpression exp2) {
    // TODO: implement visitDeferred
  }
}
