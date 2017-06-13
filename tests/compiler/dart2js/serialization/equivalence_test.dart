// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.serialization_test;

import 'dart:io';
import '../memory_compiler.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/common/resolution.dart';
import 'package:compiler/src/constants/constructors.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/diagnostics/invariant.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/elements/resolution_types.dart';
import 'package:compiler/src/elements/visitor.dart';
import 'package:compiler/src/filenames.dart';
import 'package:compiler/src/library_loader.dart';
import 'package:compiler/src/ordered_typeset.dart';
import 'package:compiler/src/serialization/element_serialization.dart';
import 'package:compiler/src/serialization/equivalence.dart';
import 'package:compiler/src/serialization/json_serializer.dart';
import 'package:compiler/src/serialization/serialization.dart';
import 'package:expect/expect.dart';
import '../equivalence/check_helpers.dart';

const TEST_SOURCES = const <String, String>{
  'main.dart': '''
import 'library.dart';
import 'deferred_library.dart' deferred as prefix;

asyncMethod() async {}
asyncStarMethod() async* {}
syncStarMethod() sync* {}
get asyncGetter async {}
get asyncStarGetter async* {}
get syncStarGetter sync* {}

genericMethod<T>() {}

class Class1 {
  factory Class1.deferred() = prefix.DeferredClass;
  factory Class1.unresolved() = Unresolved;
}
''',
  'deferred_library.dart': '''
class DeferredClass {
}

get getter => 0;
set setter(_) {}
get property => 0;
set property(_) {}
''',
  'library.dart': '''
class Type {}
''',
};

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
      entryPoint = Uri.base.resolve(nativeToUriPath(arg));
    }
  }
  Map<String, String> sourceFiles = const <String, String>{};
  if (entryPoint == null) {
    entryPoint = Uri.parse('memory:main.dart');
    sourceFiles = TEST_SOURCES;
  }
  asyncTest(() async {
    CompilationResult result = await runCompiler(
        memorySourceFiles: sourceFiles,
        entryPoint: entryPoint,
        options: [Flags.analyzeAll, Flags.genericMethodSyntax]);
    Compiler compiler = result.compiler;
    testSerialization(compiler.libraryLoader.libraries, compiler.reporter,
        compiler.resolution, compiler.libraryLoader,
        outPath: outPath, prettyPrint: prettyPrint);
    Expect.isFalse(
        compiler.reporter.hasReportedError, "Unexpected errors occured.");
  });
}

void testSerialization(
    Iterable<LibraryElement> libraries1,
    DiagnosticReporter reporter,
    Resolution resolution,
    LibraryProvider libraryProvider,
    {String outPath,
    bool prettyPrint}) {
  Serializer serializer = new Serializer();
  for (LibraryElement library1 in libraries1) {
    serializer.serialize(library1);
  }
  String text = serializer.toText(const JsonSerializationEncoder());
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
      new DeserializationContext(reporter, resolution, libraryProvider),
      Uri.parse('out1.data'),
      text,
      const JsonSerializationDecoder());
  List<LibraryElement> libraries2 = <LibraryElement>[];
  for (LibraryElement library1 in libraries1) {
    LibraryElement library2 = deserializer.lookupLibrary(library1.canonicalUri);
    if (library2 == null) {
      throw new ArgumentError('No library ${library1.canonicalUri} found.');
    }
    checkLibraryContent('library1', 'library2', 'library', library1, library2);
    libraries2.add(library2);
  }

  Serializer serializer2 = new Serializer();
  for (LibraryElement library2 in libraries2) {
    serializer2.serialize(library2);
  }
  String text2 = serializer2.toText(const JsonSerializationEncoder());

  Deserializer deserializer3 = new Deserializer.fromText(
      new DeserializationContext(reporter, resolution, libraryProvider),
      Uri.parse('out2.data'),
      text2,
      const JsonSerializationDecoder());
  for (LibraryElement library1 in libraries1) {
    LibraryElement library2 = deserializer.lookupLibrary(library1.canonicalUri);
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
checkLibraryContent(Object object1, object2, String property,
    LibraryElement library1, LibraryElement library2) {
  checkElementProperties(object1, object2, property, library1, library2);
}

/// Check the equivalence of [element1] and [element2] and their properties.
///
/// Uses [object1], [object2] and [property] to provide context for failures.
checkElementProperties(Object object1, object2, String property,
    Element element1, Element element2) {
  currentCheck =
      new Check(currentCheck, object1, object2, property, element1, element2);
  const ElementPropertyEquivalence().visit(element1, element2);
  currentCheck = currentCheck.parent;
}

/// Checks the equivalence of [constructor1] and [constructor2].
void constantConstructorEquivalence(
    ConstantConstructor constructor1, ConstantConstructor constructor2) {
  const ConstantConstructorEquivalence().visit(constructor1, constructor2);
}

/// Visitor that checks the equivalence of [ConstantConstructor]s.
class ConstantConstructorEquivalence
    extends ConstantConstructorVisitor<dynamic, ConstantConstructor> {
  const ConstantConstructorEquivalence();

  @override
  void visit(
      ConstantConstructor constructor1, ConstantConstructor constructor2) {
    if (identical(constructor1, constructor2)) return;
    check(constructor1, constructor2, 'kind', constructor1.kind,
        constructor2.kind);
    constructor1.accept(this, constructor2);
  }

  @override
  visitGenerative(GenerativeConstantConstructor constructor1,
      GenerativeConstantConstructor constructor2) {
    ResolutionInterfaceType type1 = constructor1.type;
    ResolutionInterfaceType type2 = constructor2.type;
    checkTypes(constructor1, constructor2, 'type', type1, type2);
    check(constructor1, constructor2, 'defaultValues.length',
        constructor1.defaultValues.length, constructor2.defaultValues.length);
    constructor1.defaultValues.forEach((k, v) {
      checkConstants(constructor1, constructor2, 'defaultValue[$k]', v,
          constructor2.defaultValues[k]);
    });
    check(constructor1, constructor2, 'fieldMap.length',
        constructor1.fieldMap.length, constructor2.fieldMap.length);
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
        constructor1,
        constructor2,
        'superConstructorInvocation',
        constructor1.superConstructorInvocation,
        constructor2.superConstructorInvocation);
  }

  @override
  visitRedirectingFactory(RedirectingFactoryConstantConstructor constructor1,
      RedirectingFactoryConstantConstructor constructor2) {
    checkConstants(
        constructor1,
        constructor2,
        'targetConstructorInvocation',
        constructor1.targetConstructorInvocation,
        constructor2.targetConstructorInvocation);
  }

  @override
  visitRedirectingGenerative(
      RedirectingGenerativeConstantConstructor constructor1,
      RedirectingGenerativeConstantConstructor constructor2) {
    check(constructor1, constructor2, 'defaultValues.length',
        constructor1.defaultValues.length, constructor2.defaultValues.length);
    constructor1.defaultValues.forEach((k, v) {
      checkConstants(constructor1, constructor2, 'defaultValue[$k]', v,
          constructor2.defaultValues[k]);
    });
    checkConstants(
        constructor1,
        constructor2,
        'thisConstructorInvocation',
        constructor1.thisConstructorInvocation,
        constructor2.thisConstructorInvocation);
  }
}

/// Check the equivalence of the two lists of elements, [list1] and [list2].
///
/// Uses [object1], [object2] and [property] to provide context for failures.
checkElementLists(Object object1, Object object2, String property,
    Iterable<Element> list1, Iterable<Element> list2) {
  checkListEquivalence(
      object1, object2, property, list1, list2, checkElementProperties);
}

/// Check the equivalence of the two metadata annotations, [metadata1] and
/// [metadata2].
///
/// Uses [object1], [object2] and [property] to provide context for failures.
checkMetadata(Object object1, Object object2, String property,
    MetadataAnnotation metadata1, MetadataAnnotation metadata2) {
  check(object1, object2, property, metadata1, metadata2,
      areMetadataAnnotationsEquivalent);
}

/// Visitor that checks for equivalence of [Element] properties.
class ElementPropertyEquivalence extends BaseElementVisitor<dynamic, Element> {
  const ElementPropertyEquivalence();

  void visit(Element element1, Element element2) {
    if (element1 == null && element2 == null) return;
    if (element1 == null || element2 == null) {
      throw currentCheck;
    }
    element1 = element1.declaration;
    element2 = element2.declaration;
    if (element1 == element2) return;
    check(element1, element2, 'kind', element1.kind, element2.kind);
    element1.accept(this, element2);
    check(element1, element2, 'isSynthesized', element1.isSynthesized,
        element2.isSynthesized);
    check(element1, element2, 'isLocal', element1.isLocal, element2.isLocal);
    check(element1, element2, 'isFinal', element1.isFinal, element2.isFinal);
    check(element1, element2, 'isConst', element1.isConst, element2.isConst);
    check(element1, element2, 'isAbstract', element1.isAbstract,
        element2.isAbstract);
    check(element1, element2, 'isStatic', element1.isStatic, element2.isStatic);
    check(element1, element2, 'isTopLevel', element1.isTopLevel,
        element2.isTopLevel);
    check(element1, element2, 'isClassMember', element1.isClassMember,
        element2.isClassMember);
    check(element1, element2, 'isInstanceMember', element1.isInstanceMember,
        element2.isInstanceMember);
    List<MetadataAnnotation> metadata1 = <MetadataAnnotation>[];
    metadata1.addAll(element1.metadata);
    if (element1.isPatched) {
      metadata1.addAll(element1.implementation.metadata);
    }
    List<MetadataAnnotation> metadata2 = <MetadataAnnotation>[];
    metadata2.addAll(element2.metadata);
    if (element2.isPatched) {
      metadata2.addAll(element2.implementation.metadata);
    }
    checkListEquivalence(
        element1, element2, 'metadata', metadata1, metadata2, checkMetadata);
  }

  @override
  void visitElement(Element e, Element arg) {
    throw new UnsupportedError("Unsupported element $e");
  }

  @override
  void visitLibraryElement(LibraryElement element1, LibraryElement element2) {
    checkElementIdentities(null, null, null, element1, element2);
    check(element1, element2, 'name', element1.name, element2.name);
    check(element1, element2, 'libraryName', element1.libraryName,
        element2.libraryName);
    visitMembers(element1, element2);
    visit(element1.entryCompilationUnit, element2.entryCompilationUnit);

    checkElementLists(
        element1,
        element2,
        'compilationUnits',
        LibrarySerializer.getCompilationUnits(element1),
        LibrarySerializer.getCompilationUnits(element2));

    checkElementLists(
        element1,
        element2,
        'imports',
        LibrarySerializer.getImports(element1),
        LibrarySerializer.getImports(element2));
    checkElementLists(
        element1, element2, 'exports', element1.exports, element2.exports);

    List<Element> imported1 = LibrarySerializer.getImportedElements(element1);
    List<Element> imported2 = LibrarySerializer.getImportedElements(element2);
    checkElementListIdentities(
        element1, element2, 'importScope', imported1, imported2);

    checkElementListIdentities(
        element1,
        element2,
        'exportScope',
        LibrarySerializer.getExportedElements(element1),
        LibrarySerializer.getExportedElements(element2));

    for (int index = 0; index < imported1.length; index++) {
      checkImportsFor(element1, element2, imported1[index], imported2[index]);
    }
  }

  void checkImportsFor(
      Element element1, Element element2, Element import1, Element import2) {
    List<ImportElement> imports1 = element1.library.getImportsFor(import1);
    List<ImportElement> imports2 = element2.library.getImportsFor(import2);
    checkElementListIdentities(element1, element2,
        'importsFor($import1/$import2)', imports1, imports2);
  }

  @override
  void visitCompilationUnitElement(
      CompilationUnitElement element1, CompilationUnitElement element2) {
    checkElementIdentities(
        element1, element2, 'library', element1.library, element2.library);
    check(element1, element2, 'script.resourceUri', element1.script.resourceUri,
        element2.script.resourceUri);
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

  void visitMembers(
      ScopeContainerElement element1, ScopeContainerElement element2) {
    Set<String> names = new Set<String>();
    Iterable<Element> members1 = element1.isLibrary
        ? LibrarySerializer.getMembers(element1)
        : ClassSerializer.getMembers(element1);
    Iterable<Element> members2 = element2.isLibrary
        ? LibrarySerializer.getMembers(element2)
        : ClassSerializer.getMembers(element2);
    for (Element member in members1) {
      names.add(member.name);
    }
    for (Element member in members2) {
      names.add(member.name);
    }
    element1 = element1.implementation;
    element2 = element2.implementation;
    for (String name in names) {
      Element member1 = element1.localLookup(name);
      Element member2 = element2.localLookup(name);
      if (member1 == null) {
        String message =
            'Missing member for $member2 in\n ${members1.join('\n ')}';
        if (member2.isAbstractField) {
          // TODO(johnniwinther): Ensure abstract fields are handled correctly.
          //print(message);
          continue;
        } else {
          throw message;
        }
      }
      if (member2 == null) {
        String message =
            'Missing member for $member1 in\n ${members2.join('\n ')}';
        if (member1.isAbstractField) {
          // TODO(johnniwinther): Ensure abstract fields are handled correctly.
          //print(message);
          continue;
        } else {
          throw message;
        }
      }
      currentCheck = new Check(
          currentCheck, element1, element2, 'member:$name', member1, member2);
      visit(member1, member2);
      currentCheck = currentCheck.parent;
    }
  }

  @override
  void visitClassElement(ClassElement element1, ClassElement element2) {
    checkElementIdentities(null, null, null, element1, element2);
    check(element1, element2, 'name', element1.name, element2.name);
    if (!element1.isUnnamedMixinApplication) {
      check(element1, element2, 'sourcePosition', element1.sourcePosition,
          element2.sourcePosition);
    } else {
      check(element1, element2, 'sourcePosition.uri',
          element1.sourcePosition.uri, element2.sourcePosition.uri);
      MixinApplicationElement mixin1 = element1;
      MixinApplicationElement mixin2 = element2;
      checkElementIdentities(
          mixin1, mixin2, 'subclass', mixin1.subclass, mixin2.subclass);
      checkTypes(
          mixin1, mixin2, 'mixinType', mixin1.mixinType, mixin2.mixinType);
    }
    checkElementIdentities(
        element1, element2, 'library', element1.library, element2.library);
    checkElementIdentities(element1, element2, 'compilationUnit',
        element1.compilationUnit, element2.compilationUnit);
    checkTypeLists(element1, element2, 'typeVariables', element1.typeVariables,
        element2.typeVariables);
    checkTypes(
        element1, element2, 'thisType', element1.thisType, element2.thisType);
    checkTypes(
        element1, element2, 'rawType', element1.rawType, element2.rawType);
    check(element1, element2, 'isObject', element1.isObject, element2.isObject);
    checkTypeLists(element1, element2, 'typeVariables', element1.typeVariables,
        element2.typeVariables);
    check(element1, element2, 'isAbstract', element1.isAbstract,
        element2.isAbstract);
    check(element1, element2, 'isUnnamedMixinApplication',
        element1.isUnnamedMixinApplication, element2.isUnnamedMixinApplication);
    check(element1, element2, 'isProxy', element1.isProxy, element2.isProxy);
    check(element1, element2, 'isInjected', element1.isInjected,
        element2.isInjected);
    check(element1, element2, 'isEnumClass', element1.isEnumClass,
        element2.isEnumClass);
    if (element1.isEnumClass) {
      EnumClassElement enum1 = element1;
      EnumClassElement enum2 = element2;
      checkElementLists(
          enum1, enum2, 'enumValues', enum1.enumValues, enum2.enumValues);
    }
    if (!element1.isObject) {
      checkTypes(element1, element2, 'supertype', element1.supertype,
          element2.supertype);
    }
    check(element1, element2, 'hierarchyDepth', element1.hierarchyDepth,
        element2.hierarchyDepth);
    checkTypeLists(element1, element2, 'allSupertypes',
        element1.allSupertypes.toList(), element2.allSupertypes.toList());
    OrderedTypeSet typeSet1 = element1.allSupertypesAndSelf;
    OrderedTypeSet typeSet2 = element2.allSupertypesAndSelf;
    checkListEquivalence(element1, element2, 'allSupertypes',
        typeSet1.levelOffsets, typeSet2.levelOffsets, check);
    check(element1, element2, 'allSupertypesAndSelf.levels', typeSet1.levels,
        typeSet2.levels);
    checkTypeLists(element1, element2, 'supertypes',
        typeSet1.supertypes.toList(), typeSet2.supertypes.toList());
    checkTypeLists(element1, element2, 'types', typeSet1.types.toList(),
        typeSet2.types.toList());

    checkTypeLists(element1, element2, 'interfaces',
        element1.interfaces.toList(), element2.interfaces.toList());

    List<ConstructorElement> getConstructors(ClassElement cls) {
      return cls.implementation.constructors.map((c) => c.declaration).toList();
    }

    checkElementLists(element1, element2, 'constructors',
        getConstructors(element1), getConstructors(element2));

    checkElementIdentities(
        element1,
        element2,
        'defaultConstructor',
        element1.lookupDefaultConstructor(),
        element2.lookupDefaultConstructor());

    visitMembers(element1, element2);

    ClassElement superclass1 = element1.superclass;
    ClassElement superclass2 = element2.superclass;
    while (superclass1 != null && superclass1.isMixinApplication) {
      checkElementProperties(
          element1, element2, 'supermixin', superclass1, superclass2);
      superclass1 = superclass1.superclass;
      superclass2 = superclass2.superclass;
    }
  }

  @override
  void visitFieldElement(FieldElement element1, FieldElement element2) {
    checkElementIdentities(null, null, null, element1, element2);
    check(element1, element2, 'name', element1.name, element2.name);
    check(element1, element2, 'sourcePosition', element1.sourcePosition,
        element2.sourcePosition);
    checkTypes(element1, element2, 'type', element1.type, element2.type);
    checkConstants(
        element1, element2, 'constant', element1.constant, element2.constant);
    check(element1, element2, 'isTopLevel', element1.isTopLevel,
        element2.isTopLevel);
    check(element1, element2, 'isStatic', element1.isStatic, element2.isStatic);
    check(element1, element2, 'isInstanceMember', element1.isInstanceMember,
        element2.isInstanceMember);
    check(element1, element2, 'isInjected', element1.isInjected,
        element2.isInjected);

    checkElementIdentities(
        element1, element2, 'library', element1.library, element2.library);
    checkElementIdentities(element1, element2, 'compilationUnit',
        element1.compilationUnit, element2.compilationUnit);
    checkElementIdentities(element1, element2, 'enclosingClass',
        element1.enclosingClass, element2.enclosingClass);
  }

  @override
  void visitFunctionElement(
      FunctionElement element1, FunctionElement element2) {
    checkElementIdentities(null, null, null, element1, element2);
    check(element1, element2, 'name', element1.name, element2.name);
    check(element1, element2, 'sourcePosition', element1.sourcePosition,
        element2.sourcePosition);
    checkTypes(element1, element2, 'type', element1.type, element2.type);
    checkListEquivalence(element1, element2, 'parameters', element1.parameters,
        element2.parameters, checkElementProperties);
    check(element1, element2, 'isOperator', element1.isOperator,
        element2.isOperator);
    check(element1, element2, 'asyncMarker', element1.asyncMarker,
        element2.asyncMarker);
    check(element1, element2, 'isInjected', element1.isInjected,
        element2.isInjected);

    checkElementIdentities(
        element1, element2, 'library', element1.library, element2.library);
    checkElementIdentities(element1, element2, 'compilationUnit',
        element1.compilationUnit, element2.compilationUnit);
    checkElementIdentities(element1, element2, 'enclosingClass',
        element1.enclosingClass, element2.enclosingClass);

    check(
        element1,
        element2,
        'functionSignature.type',
        element1.functionSignature.type,
        element2.functionSignature.type,
        areTypesEquivalent);
    checkElementLists(
        element1,
        element2,
        'functionSignature.requiredParameters',
        element1.functionSignature.requiredParameters,
        element2.functionSignature.requiredParameters);
    checkElementLists(
        element1,
        element2,
        'functionSignature.optionalParameters',
        element1.functionSignature.optionalParameters,
        element2.functionSignature.optionalParameters);
    check(
        element1,
        element2,
        'functionSignature.requiredParameterCount',
        element1.functionSignature.requiredParameterCount,
        element2.functionSignature.requiredParameterCount);
    check(
        element1,
        element2,
        'functionSignature.optionalParameterCount',
        element1.functionSignature.optionalParameterCount,
        element2.functionSignature.optionalParameterCount);
    check(
        element1,
        element2,
        'functionSignature.optionalParametersAreNamed',
        element1.functionSignature.optionalParametersAreNamed,
        element2.functionSignature.optionalParametersAreNamed);
    check(
        element1,
        element2,
        'functionSignature.hasOptionalParameters',
        element1.functionSignature.hasOptionalParameters,
        element2.functionSignature.hasOptionalParameters);
    check(
        element1,
        element2,
        'functionSignature.parameterCount',
        element1.functionSignature.parameterCount,
        element2.functionSignature.parameterCount);
    checkElementLists(
        element1,
        element2,
        'functionSignature.orderedOptionalParameters',
        element1.functionSignature.orderedOptionalParameters,
        element2.functionSignature.orderedOptionalParameters);
    checkTypeLists(element1, element2, 'typeVariables', element1.typeVariables,
        element2.typeVariables);
  }

  @override
  void visitConstructorElement(
      ConstructorElement element1, ConstructorElement element2) {
    checkElementIdentities(null, null, null, element1, element2);
    checkElementIdentities(element1, element2, 'enclosingClass',
        element1.enclosingClass, element2.enclosingClass);
    check(element1, element2, 'name', element1.name, element2.name);
    if (!element1.isSynthesized) {
      check(element1, element2, 'sourcePosition', element1.sourcePosition,
          element2.sourcePosition);
    } else {
      check(element1, element2, 'sourcePosition.uri',
          element1.sourcePosition.uri, element2.sourcePosition.uri);
    }
    checkListEquivalence(element1, element2, 'parameters', element1.parameters,
        element2.parameters, checkElementProperties);
    checkTypes(element1, element2, 'type', element1.type, element2.type);
    check(element1, element2, 'isExternal', element1.isExternal,
        element2.isExternal);
    if (element1.isConst && !element1.isExternal) {
      constantConstructorEquivalence(
          element1.constantConstructor, element2.constantConstructor);
    }
    check(element1, element2, 'isRedirectingGenerative',
        element1.isRedirectingGenerative, element2.isRedirectingGenerative);
    check(element1, element2, 'isRedirectingFactory',
        element1.isRedirectingFactory, element2.isRedirectingFactory);
    checkElementIdentities(element1, element2, 'effectiveTarget',
        element1.effectiveTarget, element2.effectiveTarget);
    if (element1.isRedirectingFactory) {
      checkElementIdentities(
          element1,
          element2,
          'immediateRedirectionTarget',
          element1.immediateRedirectionTarget,
          element2.immediateRedirectionTarget);
      checkElementIdentities(
          element1,
          element2,
          'redirectionDeferredPrefix',
          element1.redirectionDeferredPrefix,
          element2.redirectionDeferredPrefix);
      check(
          element1,
          element2,
          'isEffectiveTargetMalformed',
          element1.isEffectiveTargetMalformed,
          element2.isEffectiveTargetMalformed);
    }
    checkElementIdentities(element1, element2, 'definingConstructor',
        element1.definingConstructor, element2.definingConstructor);
    check(
        element1,
        element2,
        'effectiveTargetType',
        element1.computeEffectiveTargetType(element1.enclosingClass.thisType),
        element2.computeEffectiveTargetType(element2.enclosingClass.thisType),
        areTypesEquivalent);
    check(
        element1,
        element2,
        'effectiveTargetType.raw',
        element1.computeEffectiveTargetType(element1.enclosingClass.rawType),
        element2.computeEffectiveTargetType(element2.enclosingClass.rawType),
        areTypesEquivalent);
    checkElementIdentities(
        element1,
        element2,
        'immediateRedirectionTarget',
        element1.immediateRedirectionTarget,
        element2.immediateRedirectionTarget);
    checkElementIdentities(element1, element2, 'redirectionDeferredPrefix',
        element1.redirectionDeferredPrefix, element2.redirectionDeferredPrefix);
    check(element1, element2, 'isInjected', element1.isInjected,
        element2.isInjected);
  }

  @override
  void visitAbstractFieldElement(
      AbstractFieldElement element1, AbstractFieldElement element2) {
    visit(element1.getter, element2.getter);
    visit(element1.setter, element2.setter);
  }

  @override
  void visitTypeVariableElement(
      TypeVariableElement element1, TypeVariableElement element2) {
    checkElementIdentities(null, null, null, element1, element2);
    check(element1, element2, 'name', element1.name, element2.name);
    check(element1, element2, 'sourcePosition', element1.sourcePosition,
        element2.sourcePosition);
    check(element1, element2, 'index', element1.index, element2.index);
    checkTypes(element1, element2, 'type', element1.type, element2.type);
    checkTypes(element1, element2, 'bound', element1.bound, element2.bound);
  }

  @override
  void visitTypedefElement(TypedefElement element1, TypedefElement element2) {
    checkElementIdentities(null, null, null, element1, element2);
    check(element1, element2, 'name', element1.name, element2.name);
    check(element1, element2, 'sourcePosition', element1.sourcePosition,
        element2.sourcePosition);
    checkTypes(element1, element2, 'alias', element1.alias, element2.alias);
    checkTypeLists(element1, element2, 'typeVariables', element1.typeVariables,
        element2.typeVariables);
    checkElementIdentities(
        element1, element2, 'library', element1.library, element2.library);
    checkElementIdentities(element1, element2, 'compilationUnit',
        element1.compilationUnit, element2.compilationUnit);
    // TODO(johnniwinther): Check the equivalence of typedef parameters.
  }

  @override
  void visitParameterElement(
      ParameterElement element1, ParameterElement element2) {
    checkElementIdentities(null, null, null, element1, element2);
    checkElementIdentities(element1, element2, 'functionDeclaration',
        element1.functionDeclaration, element2.functionDeclaration);
    check(element1, element2, 'name', element1.name, element2.name);
    check(element1, element2, 'sourcePosition', element1.sourcePosition,
        element2.sourcePosition);
    checkTypes(element1, element2, 'type', element1.type, element2.type);
    check(element1, element2, 'isOptional', element1.isOptional,
        element2.isOptional);
    check(element1, element2, 'isNamed', element1.isNamed, element2.isNamed);
    check(element1, element2, 'name', element1.name, element2.name);
    if (element1.isOptional) {
      checkConstants(
          element1, element2, 'constant', element1.constant, element2.constant);
    }
    checkElementIdentities(element1, element2, 'compilationUnit',
        element1.compilationUnit, element2.compilationUnit);
  }

  @override
  void visitFieldParameterElement(
      InitializingFormalElement element1, InitializingFormalElement element2) {
    visitParameterElement(element1, element2);
    checkElementIdentities(element1, element2, 'fieldElement',
        element1.fieldElement, element2.fieldElement);
  }

  @override
  void visitImportElement(ImportElement element1, ImportElement element2) {
    check(element1, element2, 'uri', element1.uri, element2.uri);
    check(element1, element2, 'isDeferred', element1.isDeferred,
        element2.isDeferred);
    checkElementProperties(
        element1, element2, 'prefix', element1.prefix, element2.prefix);
    checkElementIdentities(element1, element2, 'importedLibrary',
        element1.importedLibrary, element2.importedLibrary);
  }

  @override
  void visitExportElement(ExportElement element1, ExportElement element2) {
    check(element1, element2, 'uri', element1.uri, element2.uri);
    checkElementIdentities(element1, element2, 'importedLibrary',
        element1.exportedLibrary, element2.exportedLibrary);
  }

  @override
  void visitPrefixElement(PrefixElement element1, PrefixElement element2) {
    check(element1, element2, 'isDeferred', element1.isDeferred,
        element2.isDeferred);
    checkElementIdentities(element1, element2, 'deferredImport',
        element1.deferredImport, element2.deferredImport);
    if (element1.isDeferred) {
      checkElementProperties(element1, element2, 'loadLibrary',
          element1.loadLibrary, element2.loadLibrary);
    }
    element1.forEachLocalMember((Element member1) {
      String name = member1.name;
      Element member2 = element2.lookupLocalMember(name);
      checkElementIdentities(
          element1, element2, 'lookupLocalMember:$name', member1, member2);
      checkImportsFor(element1, element2, member1, member2);
    });
  }

  @override
  void visitErroneousElement(
      ErroneousElement element1, ErroneousElement element2) {
    check(element1, element2, 'messageKind', element1.messageKind,
        element2.messageKind);
  }
}
