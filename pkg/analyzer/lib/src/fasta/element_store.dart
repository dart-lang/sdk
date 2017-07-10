// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.analyzer.element_store;

import 'package:analyzer/src/kernel/loader.dart' show ReferenceLevelLoader;

import 'package:kernel/ast.dart';

import 'package:analyzer/analyzer.dart' show ParameterKind;

import 'package:analyzer/analyzer.dart' as analyzer;

import 'package:analyzer/dart/element/element.dart';

import 'package:analyzer/dart/element/type.dart' as analyzer;

import 'package:front_end/src/fasta/deprecated_problems.dart'
    show deprecated_internalProblem;

import 'package:front_end/src/fasta/kernel/kernel_builder.dart';

import 'package:front_end/src/fasta/dill/dill_member_builder.dart';

import 'mock_element.dart';

import 'mock_type.dart';

abstract class ElementStore implements ReferenceLevelLoader {
  Element operator [](Builder builder);

  factory ElementStore(
          LibraryBuilder coreLibrary, Map<Uri, LibraryBuilder> builders) =
      ElementStoreImplementation;
}

// ClassElement,
// ClassMemberElement,
// CompilationUnitElement,
// ConstructorElement,
// Element,
// FieldElement,
// FieldFormalParameterElement,
// FunctionElement,
// FunctionTypedElement,
// LibraryElement,
// LocalElement,
// LocalVariableElement,
// MethodElement,
// ParameterElement,
// PrefixElement,
// PropertyAccessorElement,
// TopLevelVariableElement,
// TypeParameterElement,
// VariableElement;
class ElementStoreImplementation implements ElementStore {
  final LibraryBuilder coreLibrary;

  final Map<Builder, Element> elements;

  ElementStoreImplementation.internal(this.coreLibrary, this.elements);

  Element operator [](Builder builder) {
    // Avoid storing local elements in the element store to reduce memory
    // usage. So they both implement [Element] and [Builder].
    return builder is Element ? builder : elements[builder];
  }

  factory ElementStoreImplementation(
      LibraryBuilder coreLibrary, Map<Uri, LibraryBuilder> libraries) {
    Map<Builder, Element> elements = <Builder, Element>{};
    libraries.forEach((Uri uri, LibraryBuilder library) {
      KernelCompilationUnitElement unit =
          new KernelCompilationUnitElement(library);
      KernelLibraryElement element = new KernelLibraryElement(unit);
      elements[library] = element;
      unit.library = element;
      library.forEach((String name, Builder builder) {
        do {
          if (builder is ClassBuilder) {
            elements[builder] = new KernelClassElement(builder);
          } else if (builder is KernelFunctionTypeAliasBuilder) {
            elements[builder] = new KernelFunctionTypeAliasElement(builder);
          } else if (builder is DillMemberBuilder) {
            Member member = builder.member;
            if (member is Field) {} else if (member is Procedure) {
              buildDillFunctionElement(builder, unit, elements);
            } else {
              deprecated_internalProblem(
                  "Unhandled $name ${member.runtimeType} in $uri");
            }
          } else if (builder is KernelProcedureBuilder) {
            buildKernelFunctionElement(builder, unit, elements);
          } else if (builder is BuiltinTypeBuilder) {
            // TODO(ahe): Set up elements for dynamic and void.
          } else {
            deprecated_internalProblem(
                "Unhandled $name ${builder.runtimeType} in $uri");
          }
          builder = builder.next;
        } while (builder != null);
      });
    });
    return new ElementStoreImplementation.internal(coreLibrary, elements);
  }

  bool get ignoreRedirectingFactories => false;

  Constructor getCoreClassConstructorReference(String className,
      {String constructorName, String library}) {
    assert(library == null);
    return coreLibrary
        .getConstructor(className, constructorName: constructorName)
        .target;
  }

  Library getLibraryReference(LibraryElement element) {
    return deprecated_internalProblem("not supported.");
  }

  Class getClassReference(covariant KernelClassElement cls) => cls.builder.cls;

  Member getMemberReference(Element element) {
    if (element is KernelFunctionElement) {
      return element.procedure;
    } else {
      return deprecated_internalProblem(
          "getMemberReference(${element.runtimeType})");
    }
  }

  Class getRootClassReference() => deprecated_internalProblem("not supported.");

  Constructor getRootClassConstructorReference() {
    return deprecated_internalProblem("not supported.");
  }

  Class getCoreClassReference(String className) {
    return deprecated_internalProblem("not supported.");
  }

  TypeParameter tryGetClassTypeParameter(TypeParameterElement element) {
    return deprecated_internalProblem("not supported.");
  }

  Class getSharedMixinApplicationClass(
      Library library, Class supertype, Class mixin) {
    return deprecated_internalProblem("not supported.");
  }

  bool get strongMode => false;

  static void buildDillFunctionElement(DillMemberBuilder builder,
      KernelCompilationUnitElement unit, Map<Builder, Element> elements) {
    Procedure procedure = builder.member;
    List<VariableDeclaration> positionalParameters =
        procedure.function.positionalParameters;
    List<VariableDeclaration> namedParameters =
        procedure.function.namedParameters;
    int requiredParameterCount = procedure.function.requiredParameterCount;
    List<KernelParameterElement> parameters = new List<KernelParameterElement>(
        positionalParameters.length + namedParameters.length);
    int i = 0;
    for (VariableDeclaration parameter in positionalParameters) {
      parameters[i] = buildFormalParameter(parameter,
          isOptional: i >= requiredParameterCount);
      i++;
    }
    for (VariableDeclaration parameter in namedParameters) {
      parameters[i++] = buildFormalParameter(parameter, isNamed: true);
    }
    elements[builder] = new KernelFunctionElement(procedure, unit, parameters);
  }

  static void buildKernelFunctionElement(KernelProcedureBuilder builder,
      KernelCompilationUnitElement unit, Map<Builder, Element> elements) {
    assert(builder.procedure != null);
    List<KernelParameterElement> parameters;
    int i = 0;
    if (builder.formals != null) {
      parameters = new List<KernelParameterElement>(builder.formals.length);
      for (KernelFormalParameterBuilder parameter in builder.formals) {
        assert(parameter.declaration != null);
        elements[parameter] = parameters[i++] = buildFormalParameter(
            parameter.declaration,
            isOptional: parameter.isOptional,
            isNamed: parameter.isNamed);
      }
    } else {
      parameters = new List<KernelParameterElement>(0);
    }
    elements[builder] =
        new KernelFunctionElement(builder.procedure, unit, parameters);
  }

  static KernelParameterElement buildFormalParameter(
      VariableDeclaration parameter,
      {bool isOptional: true,
      bool isNamed: false}) {
    ParameterKind kind = isOptional
        ? (isNamed ? ParameterKind.NAMED : ParameterKind.POSITIONAL)
        : ParameterKind.REQUIRED;
    return new KernelParameterElement(parameter, kind);
  }
}

class KernelLibraryElement extends MockLibraryElement {
  final KernelCompilationUnitElement definingCompilationUnit;

  KernelLibraryElement(this.definingCompilationUnit);

  FunctionElement get loadLibraryFunction => null;
}

class KernelCompilationUnitElement extends MockCompilationUnitElement {
  final LibraryBuilder builder;

  KernelLibraryElement library;

  KernelCompilationUnitElement(this.builder);

  KernelLibraryElement get enclosingElement => library;

  String get uri => "${builder.uri}";
}

class KernelFunctionElement extends MockFunctionElement {
  final Procedure procedure;

  final KernelCompilationUnitElement enclosingElement;

  final List<KernelParameterElement> parameters;

  KernelFunctionElement(this.procedure, this.enclosingElement, this.parameters);

  KernelLibraryElement get library => enclosingElement.library;
}

class KernelParameterElement extends MockParameterElement {
  final VariableDeclaration declaration;

  final ParameterKind parameterKind;

  KernelParameterElement(this.declaration, this.parameterKind);
}

/// Both an [Element] and [Builder] to using memory to store local elements in
/// [ElementStore].
class AnalyzerLocalVariableElemment extends MockElement
    implements LocalVariableElement {
  final analyzer.VariableDeclaration variable;

  AnalyzerLocalVariableElemment(this.variable)
      : super(ElementKind.LOCAL_VARIABLE);

  String get name => variable.name.name;

  bool get isFinal => false; // TODO(ahe): implement this.

  bool get isConst => false; // TODO(ahe): implement this.

  analyzer.VariableDeclaration get target => variable;

  get type => null;

  get constantValue => deprecated_internalProblem("not supported.");

  computeConstantValue() => deprecated_internalProblem("not supported.");
}

/// Both an [Element] and [Builder] to using memory to store local elements in
/// [ElementStore].
class AnalyzerParameterElement extends MockParameterElement {
  final analyzer.FormalParameter parameter;

  AnalyzerParameterElement(this.parameter);

  String get name => parameter.identifier.name;

  bool get isFinal => false; // TODO(ahe): implement this.

  bool get isConst => false; // TODO(ahe): implement this.

  analyzer.FormalParameter get target => parameter;
}

class KernelClassElement extends MockClassElement {
  final KernelClassBuilder builder;

  KernelInterfaceType rawType;

  KernelClassElement(this.builder) {
    rawType = new KernelInterfaceType(this);
  }
}

class KernelFunctionTypeAliasElement extends MockFunctionTypeAliasElement {
  final KernelFunctionTypeAliasBuilder builder;

  KernelFunctionTypeAliasElement(this.builder);

  @override
  analyzer.DartType get returnType {
    return deprecated_internalProblem("not supported.");
  }

  @override
  analyzer.FunctionType get type {
    return deprecated_internalProblem("not supported.");
  }

  @override
  List<TypeParameterElement> get typeParameters {
    return deprecated_internalProblem("not supported.");
  }
}

class KernelInterfaceType extends MockInterfaceType {
  final KernelClassElement element;

  KernelInterfaceType(this.element);

  List<analyzer.DartType> get typeArguments => const <analyzer.DartType>[];
}
