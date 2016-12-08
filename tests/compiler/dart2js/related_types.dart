// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library related_types;

import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/core_types.dart';
import 'package:compiler/src/dart_types.dart';
import 'package:compiler/src/diagnostics/diagnostic_listener.dart';
import 'package:compiler/src/diagnostics/messages.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/filenames.dart';
import 'package:compiler/src/resolution/semantic_visitor.dart';
import 'package:compiler/src/tree/tree.dart';
import 'package:compiler/src/universe/call_structure.dart';
import 'package:compiler/src/universe/selector.dart';
import 'package:compiler/src/world.dart';
import 'memory_compiler.dart';

main(List<String> arguments) async {
  if (arguments.isNotEmpty) {
    Uri entryPoint = Uri.base.resolve(nativeToUriPath(arguments.last));
    CompilationResult result = await runCompiler(
        entryPoint: entryPoint,
        options: [Flags.analyzeOnly, '--categories=Client,Server']);
    if (result.isSuccess) {
      checkRelatedTypes(result.compiler);
    }
  } else {
    print('Usage dart related_types.dart <entry-point>');
  }
}

/// Check all loaded libraries in [compiler] for unrelated types.
void checkRelatedTypes(Compiler compiler) {
  compiler.closeResolution();
  compiler.closedWorld;
  for (LibraryElement library in compiler.libraryLoader.libraries) {
    checkLibraryElement(compiler, library);
  }
}

/// Check [library] for unrelated types.
void checkLibraryElement(Compiler compiler, LibraryElement library) {
  library.forEachLocalMember((Element element) {
    if (element.isClass) {
      ClassElement cls = element;
      cls.forEachLocalMember((MemberElement member) {
        checkMemberElement(compiler, member);
      });
    } else if (!element.isTypedef) {
      checkMemberElement(compiler, element);
    }
  });
}

/// Check [member] for unrelated types.
void checkMemberElement(Compiler compiler, MemberElement member) {
  if (!compiler.resolution.hasBeenResolved(member)) return;

  ResolvedAst resolvedAst = member.resolvedAst;
  if (resolvedAst.kind == ResolvedAstKind.PARSED) {
    RelatedTypesChecker relatedTypesChecker =
        new RelatedTypesChecker(compiler, resolvedAst);
    compiler.reporter.withCurrentElement(member.implementation, () {
      relatedTypesChecker.apply(resolvedAst.node);
    });
  }
}

class RelatedTypesChecker extends TraversalVisitor<DartType, dynamic> {
  final Compiler compiler;
  final ResolvedAst resolvedAst;

  RelatedTypesChecker(this.compiler, ResolvedAst resolvedAst)
      : this.resolvedAst = resolvedAst,
        super(resolvedAst.elements);

  ClosedWorld get world => compiler.closedWorld;

  CoreClasses get coreClasses => compiler.coreClasses;

  CoreTypes get coreTypes => compiler.coreTypes;

  DiagnosticReporter get reporter => compiler.reporter;

  InterfaceType get thisType => resolvedAst.element.enclosingClass.thisType;

  /// Returns `true` if there exists no common subtype of [left] and [right].
  bool hasEmptyIntersection(DartType left, DartType right) {
    if (left == right) return false;
    if (left == null || right == null) return false;
    ClassElement leftClass = const ClassFinder().findClass(left);
    ClassElement rightClass = const ClassFinder().findClass(right);
    if (leftClass != null && rightClass != null) {
      return !world.haveAnyCommonSubtypes(leftClass, rightClass);
    }
    return false;
  }

  /// Checks that there exists a common subtype of [left] and [right] or report
  /// a hint otherwise.
  void checkRelated(Node node, DartType left, DartType right) {
    if (hasEmptyIntersection(left, right)) {
      reporter.reportHintMessage(
          node, MessageKind.NO_COMMON_SUBTYPES, {'left': left, 'right': right});
    }
  }

  /// Check weakly typed collection methods, like `Map.containsKey`,
  /// `Map.containsValue` and `Iterable.contains`.
  void checkDynamicInvoke(Node node, DartType receiverType,
      List<DartType> argumentTypes, Selector selector) {
    if (selector.name == 'containsKey' &&
        selector.callStructure == CallStructure.ONE_ARG) {
      InterfaceType mapType = findMapType(receiverType);
      if (mapType != null) {
        DartType keyType = findMapKeyType(mapType);
        checkRelated(node, keyType, argumentTypes.first);
      }
    } else if (selector.name == 'containsValue' &&
        selector.callStructure == CallStructure.ONE_ARG) {
      InterfaceType mapType = findMapType(receiverType);
      if (mapType != null) {
        DartType valueType = findMapValueType(mapType);
        checkRelated(node, valueType, argumentTypes.first);
      }
    } else if (selector.name == 'contains' &&
        selector.callStructure == CallStructure.ONE_ARG) {
      InterfaceType iterableType = findIterableType(receiverType);
      if (iterableType != null) {
        DartType elementType = findIterableElementType(iterableType);
        checkRelated(node, elementType, argumentTypes.first);
      }
    } else if (selector.name == 'remove' &&
        selector.callStructure == CallStructure.ONE_ARG) {
      InterfaceType mapType = findMapType(receiverType);
      if (mapType != null) {
        DartType keyType = findMapKeyType(mapType);
        checkRelated(node, keyType, argumentTypes.first);
      }
      InterfaceType listType = findListType(receiverType);
      if (listType != null) {
        DartType valueType = findListElementType(listType);
        checkRelated(node, valueType, argumentTypes.first);
      }
    }
  }

  /// Return the interface type implemented by [type] or `null` if no interface
  /// type is implied by [type].
  InterfaceType findInterfaceType(DartType type) {
    return Types.computeInterfaceType(compiler.resolution, type);
  }

  /// Returns the supertype of [receiver] that implements [cls], if any.
  InterfaceType findClassType(DartType receiver, ClassElement cls) {
    InterfaceType interfaceType = findInterfaceType(receiver);
    if (interfaceType == null) return null;
    InterfaceType mapType = interfaceType.asInstanceOf(cls);
    if (mapType == null) return null;
    return mapType;
  }

  /// Returns the supertype of [receiver] that implements `Iterable`, if any.
  InterfaceType findIterableType(DartType receiver) {
    return findClassType(receiver, coreClasses.iterableClass);
  }

  /// Returns the element type of the supertype of [receiver] that implements
  /// `Iterable`, if any.
  DartType findIterableElementType(InterfaceType iterableType) {
    if (iterableType == null) return null;
    return iterableType.typeArguments[0];
  }

  /// Returns the supertype of [receiver] that implements `Map`, if any.
  InterfaceType findMapType(DartType receiver) {
    return findClassType(receiver, coreClasses.mapClass);
  }

  /// Returns the key type of the supertype of [receiver] that implements
  /// `Map`, if any.
  DartType findMapKeyType(InterfaceType mapType) {
    if (mapType == null) return null;
    return mapType.typeArguments[0];
  }

  /// Returns the value type of the supertype of [receiver] that implements
  /// `Map`, if any.
  DartType findMapValueType(InterfaceType mapType) {
    if (mapType == null) return null;
    return mapType.typeArguments[1];
  }

  /// Returns the supertype of [receiver] that implements `List`, if any.
  InterfaceType findListType(DartType receiver) {
    return findClassType(receiver, coreClasses.listClass);
  }

  /// Returns the element type of the supertype of [receiver] that implements
  /// `List`, if any.
  DartType findListElementType(InterfaceType listType) {
    if (listType == null) return null;
    return listType.typeArguments[0];
  }

  /// Returns the implied return type of [type] or `dynamic` if no return type
  /// is implied.
  DartType findReturnType(DartType type) {
    if (type is FunctionType) {
      return type.returnType;
    }
    return const DynamicType();
  }

  /// Visits [arguments] and returns the list of their corresponding types.
  List<DartType> findArgumentTypes(NodeList arguments) {
    List<DartType> argumentTypes = <DartType>[];
    for (Node argument in arguments) {
      argumentTypes.add(apply(argument));
    }
    return argumentTypes;
  }

  /// Finds the [MemberSignature] of the [name] property on [type], if any.
  MemberSignature lookupInterfaceMember(DartType type, Name name) {
    InterfaceType interfaceType = findInterfaceType(type);
    if (interfaceType == null) return null;
    return interfaceType.lookupInterfaceMember(name);
  }

  /// Returns the type of an access of the [name] property on [type], or
  /// `dynamic` if no property was found.
  DartType lookupInterfaceMemberAccessType(DartType type, Name name) {
    MemberSignature member = lookupInterfaceMember(type, name);
    if (member == null) return const DynamicType();
    return member.type;
  }

  /// Returns the function type of the [name] property on [type], or
  /// `dynamic` if no property was found.
  FunctionType lookupInterfaceMemberInvocationType(DartType type, Name name) {
    MemberSignature member = lookupInterfaceMember(type, name);
    if (member == null) return null;
    return member.functionType;
  }

  DartType apply(Node node, [_]) {
    DartType type = node.accept(this);
    if (type == null) {
      type = const DynamicType();
    }
    return type;
  }

  @override
  DartType visitEquals(Send node, Node left, Node right, _) {
    DartType leftType = apply(left);
    DartType rightType = apply(right);
    checkRelated(node, leftType, rightType);
    return coreTypes.boolType;
  }

  @override
  DartType visitNotEquals(Send node, Node left, Node right, _) {
    DartType leftType = apply(left);
    DartType rightType = apply(right);
    checkRelated(node, leftType, rightType);
    return coreTypes.boolType;
  }

  @override
  DartType visitIndex(Send node, Node receiver, Node index, _) {
    DartType receiverType = apply(receiver);
    DartType indexType = apply(index);
    InterfaceType mapType = findMapType(receiverType);
    DartType keyType = findMapKeyType(mapType);
    DartType valueType = findMapValueType(mapType);
    checkRelated(index, keyType, indexType);
    return valueType;
  }

  @override
  DartType visitLiteralInt(LiteralInt node) {
    return coreTypes.intType;
  }

  @override
  DartType visitLiteralString(LiteralString node) {
    return coreTypes.stringType;
  }

  @override
  DartType visitLiteralBool(LiteralBool node) {
    return coreTypes.boolType;
  }

  @override
  DartType visitLiteralMap(LiteralMap node) {
    return elements.getType(node);
  }

  @override
  DartType visitLiteralList(LiteralList node) {
    return elements.getType(node);
  }

  @override
  DartType visitLiteralNull(LiteralNull node) {
    return elements.getType(node);
  }

  @override
  DartType visitLocalVariableGet(Send node, LocalVariableElement variable, _) {
    return variable.type;
  }

  @override
  DartType visitLocalFunctionGet(Send node, LocalFunctionElement function, _) {
    return function.type;
  }

  @override
  DartType visitParameterGet(Send node, ParameterElement parameter, _) {
    return parameter.type;
  }

  @override
  DartType visitThisPropertyGet(Send node, Name name, _) {
    return lookupInterfaceMemberAccessType(thisType, name);
  }

  @override
  DartType visitDynamicPropertyGet(Send node, Node receiver, Name name, _) {
    DartType receiverType = apply(receiver);
    return lookupInterfaceMemberAccessType(receiverType, name);
  }

  @override
  DartType visitIfNotNullDynamicPropertyGet(
      Send node, Node receiver, Name name, _) {
    DartType receiverType = apply(receiver);
    return lookupInterfaceMemberAccessType(receiverType, name);
  }

  @override
  DartType visitStaticFieldGet(Send node, FieldElement field, _) {
    return field.type;
  }

  @override
  DartType visitTopLevelFieldGet(Send node, FieldElement field, _) {
    return field.type;
  }

  @override
  DartType visitDynamicPropertyInvoke(
      Send node, Node receiver, NodeList arguments, Selector selector, _) {
    DartType receiverType = apply(receiver);
    List<DartType> argumentTypes = findArgumentTypes(arguments);
    FunctionType methodType =
        lookupInterfaceMemberInvocationType(receiverType, selector.memberName);
    checkDynamicInvoke(node, receiverType, argumentTypes, selector);
    return findReturnType(methodType);
  }

  @override
  DartType visitThisPropertyInvoke(
      Send node, NodeList arguments, Selector selector, _) {
    DartType receiverType = thisType;
    List<DartType> argumentTypes = findArgumentTypes(arguments);
    FunctionType methodType =
        lookupInterfaceMemberInvocationType(receiverType, selector.memberName);
    checkDynamicInvoke(node, receiverType, argumentTypes, selector);
    return findReturnType(methodType);
  }

  @override
  DartType visitIfNotNullDynamicPropertyInvoke(
      Send node, Node receiver, NodeList arguments, Selector selector, _) {
    DartType receiverType = apply(receiver);
    List<DartType> argumentTypes = findArgumentTypes(arguments);
    FunctionType methodType =
        lookupInterfaceMemberInvocationType(receiverType, selector.memberName);
    checkDynamicInvoke(node, receiverType, argumentTypes, selector);
    return findReturnType(methodType);
  }

  @override
  DartType visitTopLevelFunctionInvoke(Send node, MethodElement function,
      NodeList arguments, CallStructure callStructure, _) {
    apply(arguments);
    return findReturnType(function.type);
  }

  @override
  DartType visitStaticFunctionInvoke(Send node, MethodElement function,
      NodeList arguments, CallStructure callStructure, _) {
    apply(arguments);
    return findReturnType(function.type);
  }
}

/// Computes the [ClassElement] implied by a type.
// TODO(johnniwinther): Handle type variables, function types and typedefs.
class ClassFinder extends BaseDartTypeVisitor<ClassElement, dynamic> {
  const ClassFinder();

  ClassElement findClass(DartType type) => type.accept(this, null);

  @override
  ClassElement visitType(DartType type, _) => null;

  @override
  ClassElement visitInterfaceType(InterfaceType type, _) {
    return type.element;
  }
}
