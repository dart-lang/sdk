// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library related_types;

import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/common_elements.dart';
import 'package:compiler/src/elements/resolution_types.dart';
import 'package:compiler/src/diagnostics/diagnostic_listener.dart';
import 'package:compiler/src/diagnostics/messages.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/elements/names.dart';
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

class RelatedTypesChecker
    extends TraversalVisitor<ResolutionDartType, dynamic> {
  final Compiler compiler;
  final ResolvedAst resolvedAst;

  RelatedTypesChecker(this.compiler, ResolvedAst resolvedAst)
      : this.resolvedAst = resolvedAst,
        super(resolvedAst.elements);

  ClosedWorld get world =>
      compiler.resolutionWorldBuilder.closedWorldForTesting;

  CommonElements get commonElements => compiler.resolution.commonElements;

  DiagnosticReporter get reporter => compiler.reporter;

  ResolutionInterfaceType get thisType =>
      resolvedAst.element.enclosingClass.thisType;

  /// Returns `true` if there exists no common subtype of [left] and [right].
  bool hasEmptyIntersection(ResolutionDartType left, ResolutionDartType right) {
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
  void checkRelated(
      Node node, ResolutionDartType left, ResolutionDartType right) {
    if (hasEmptyIntersection(left, right)) {
      reporter.reportHintMessage(
          node, MessageKind.NO_COMMON_SUBTYPES, {'left': left, 'right': right});
    }
  }

  /// Check weakly typed collection methods, like `Map.containsKey`,
  /// `Map.containsValue` and `Iterable.contains`.
  void checkDynamicInvoke(Node node, ResolutionDartType receiverType,
      List<ResolutionDartType> argumentTypes, Selector selector) {
    if (selector.name == 'containsKey' &&
        selector.callStructure == CallStructure.ONE_ARG) {
      ResolutionInterfaceType mapType = findMapType(receiverType);
      if (mapType != null) {
        ResolutionDartType keyType = findMapKeyType(mapType);
        checkRelated(node, keyType, argumentTypes.first);
      }
    } else if (selector.name == 'containsValue' &&
        selector.callStructure == CallStructure.ONE_ARG) {
      ResolutionInterfaceType mapType = findMapType(receiverType);
      if (mapType != null) {
        ResolutionDartType valueType = findMapValueType(mapType);
        checkRelated(node, valueType, argumentTypes.first);
      }
    } else if (selector.name == 'contains' &&
        selector.callStructure == CallStructure.ONE_ARG) {
      ResolutionInterfaceType iterableType = findIterableType(receiverType);
      if (iterableType != null) {
        ResolutionDartType elementType = findIterableElementType(iterableType);
        checkRelated(node, elementType, argumentTypes.first);
      }
    } else if (selector.name == 'remove' &&
        selector.callStructure == CallStructure.ONE_ARG) {
      ResolutionInterfaceType mapType = findMapType(receiverType);
      if (mapType != null) {
        ResolutionDartType keyType = findMapKeyType(mapType);
        checkRelated(node, keyType, argumentTypes.first);
      }
      ResolutionInterfaceType listType = findListType(receiverType);
      if (listType != null) {
        ResolutionDartType valueType = findListElementType(listType);
        checkRelated(node, valueType, argumentTypes.first);
      }
    }
  }

  /// Return the interface type implemented by [type] or `null` if no interface
  /// type is implied by [type].
  ResolutionInterfaceType findInterfaceType(ResolutionDartType type) {
    return Types.computeInterfaceType(compiler.resolution, type);
  }

  /// Returns the supertype of [receiver] that implements [cls], if any.
  ResolutionInterfaceType findClassType(
      ResolutionDartType receiver, ClassElement cls) {
    ResolutionInterfaceType interfaceType = findInterfaceType(receiver);
    if (interfaceType == null) return null;
    ResolutionInterfaceType mapType = interfaceType.asInstanceOf(cls);
    if (mapType == null) return null;
    return mapType;
  }

  /// Returns the supertype of [receiver] that implements `Iterable`, if any.
  ResolutionInterfaceType findIterableType(ResolutionDartType receiver) {
    return findClassType(receiver, commonElements.iterableClass);
  }

  /// Returns the element type of the supertype of [receiver] that implements
  /// `Iterable`, if any.
  ResolutionDartType findIterableElementType(
      ResolutionInterfaceType iterableType) {
    if (iterableType == null) return null;
    return iterableType.typeArguments[0];
  }

  /// Returns the supertype of [receiver] that implements `Map`, if any.
  ResolutionInterfaceType findMapType(ResolutionDartType receiver) {
    return findClassType(receiver, commonElements.mapClass);
  }

  /// Returns the key type of the supertype of [receiver] that implements
  /// `Map`, if any.
  ResolutionDartType findMapKeyType(ResolutionInterfaceType mapType) {
    if (mapType == null) return null;
    return mapType.typeArguments[0];
  }

  /// Returns the value type of the supertype of [receiver] that implements
  /// `Map`, if any.
  ResolutionDartType findMapValueType(ResolutionInterfaceType mapType) {
    if (mapType == null) return null;
    return mapType.typeArguments[1];
  }

  /// Returns the supertype of [receiver] that implements `List`, if any.
  ResolutionInterfaceType findListType(ResolutionDartType receiver) {
    return findClassType(receiver, commonElements.listClass);
  }

  /// Returns the element type of the supertype of [receiver] that implements
  /// `List`, if any.
  ResolutionDartType findListElementType(ResolutionInterfaceType listType) {
    if (listType == null) return null;
    return listType.typeArguments[0];
  }

  /// Returns the implied return type of [type] or `dynamic` if no return type
  /// is implied.
  ResolutionDartType findReturnType(ResolutionDartType type) {
    if (type is ResolutionFunctionType) {
      return type.returnType;
    }
    return const ResolutionDynamicType();
  }

  /// Visits [arguments] and returns the list of their corresponding types.
  List<ResolutionDartType> findArgumentTypes(NodeList arguments) {
    List<ResolutionDartType> argumentTypes = <ResolutionDartType>[];
    for (Node argument in arguments) {
      argumentTypes.add(apply(argument));
    }
    return argumentTypes;
  }

  /// Finds the [MemberSignature] of the [name] property on [type], if any.
  MemberSignature lookupInterfaceMember(ResolutionDartType type, Name name) {
    ResolutionInterfaceType interfaceType = findInterfaceType(type);
    if (interfaceType == null) return null;
    return interfaceType.lookupInterfaceMember(name);
  }

  /// Returns the type of an access of the [name] property on [type], or
  /// `dynamic` if no property was found.
  ResolutionDartType lookupInterfaceMemberAccessType(
      ResolutionDartType type, Name name) {
    MemberSignature member = lookupInterfaceMember(type, name);
    if (member == null) return const ResolutionDynamicType();
    return member.type;
  }

  /// Returns the function type of the [name] property on [type], or
  /// `dynamic` if no property was found.
  ResolutionFunctionType lookupInterfaceMemberInvocationType(
      ResolutionDartType type, Name name) {
    MemberSignature member = lookupInterfaceMember(type, name);
    if (member == null) return null;
    return member.functionType;
  }

  ResolutionDartType apply(Node node, [_]) {
    ResolutionDartType type = node.accept(this);
    if (type == null) {
      type = const ResolutionDynamicType();
    }
    return type;
  }

  @override
  ResolutionInterfaceType visitEquals(Send node, Node left, Node right, _) {
    ResolutionDartType leftType = apply(left);
    ResolutionDartType rightType = apply(right);
    checkRelated(node, leftType, rightType);
    return commonElements.boolType;
  }

  @override
  ResolutionInterfaceType visitNotEquals(Send node, Node left, Node right, _) {
    ResolutionDartType leftType = apply(left);
    ResolutionDartType rightType = apply(right);
    checkRelated(node, leftType, rightType);
    return commonElements.boolType;
  }

  @override
  ResolutionDartType visitIndex(Send node, Node receiver, Node index, _) {
    ResolutionDartType receiverType = apply(receiver);
    ResolutionDartType indexType = apply(index);
    ResolutionInterfaceType mapType = findMapType(receiverType);
    ResolutionDartType keyType = findMapKeyType(mapType);
    ResolutionDartType valueType = findMapValueType(mapType);
    checkRelated(index, keyType, indexType);
    return valueType;
  }

  @override
  ResolutionInterfaceType visitLiteralInt(LiteralInt node) {
    return commonElements.intType;
  }

  @override
  ResolutionInterfaceType visitLiteralString(LiteralString node) {
    return commonElements.stringType;
  }

  @override
  ResolutionInterfaceType visitLiteralBool(LiteralBool node) {
    return commonElements.boolType;
  }

  @override
  ResolutionDartType visitLiteralMap(LiteralMap node) {
    return elements.getType(node);
  }

  @override
  ResolutionDartType visitLiteralList(LiteralList node) {
    return elements.getType(node);
  }

  @override
  ResolutionDartType visitLiteralNull(LiteralNull node) {
    return elements.getType(node);
  }

  @override
  ResolutionDartType visitLocalVariableGet(
      Send node, LocalVariableElement variable, _) {
    return variable.type;
  }

  @override
  ResolutionDartType visitLocalFunctionGet(
      Send node, LocalFunctionElement function, _) {
    return function.type;
  }

  @override
  ResolutionDartType visitParameterGet(
      Send node, ParameterElement parameter, _) {
    return parameter.type;
  }

  @override
  ResolutionDartType visitThisPropertyGet(Send node, Name name, _) {
    return lookupInterfaceMemberAccessType(thisType, name);
  }

  @override
  ResolutionDartType visitDynamicPropertyGet(
      Send node, Node receiver, Name name, _) {
    ResolutionDartType receiverType = apply(receiver);
    return lookupInterfaceMemberAccessType(receiverType, name);
  }

  @override
  ResolutionDartType visitIfNotNullDynamicPropertyGet(
      Send node, Node receiver, Name name, _) {
    ResolutionDartType receiverType = apply(receiver);
    return lookupInterfaceMemberAccessType(receiverType, name);
  }

  @override
  ResolutionDartType visitStaticFieldGet(Send node, FieldElement field, _) {
    return field.type;
  }

  @override
  ResolutionDartType visitTopLevelFieldGet(Send node, FieldElement field, _) {
    return field.type;
  }

  @override
  ResolutionDartType visitDynamicPropertyInvoke(
      Send node, Node receiver, NodeList arguments, Selector selector, _) {
    ResolutionDartType receiverType = apply(receiver);
    List<ResolutionDartType> argumentTypes = findArgumentTypes(arguments);
    ResolutionFunctionType methodType =
        lookupInterfaceMemberInvocationType(receiverType, selector.memberName);
    checkDynamicInvoke(node, receiverType, argumentTypes, selector);
    return findReturnType(methodType);
  }

  @override
  ResolutionDartType visitThisPropertyInvoke(
      Send node, NodeList arguments, Selector selector, _) {
    ResolutionDartType receiverType = thisType;
    List<ResolutionDartType> argumentTypes = findArgumentTypes(arguments);
    ResolutionFunctionType methodType =
        lookupInterfaceMemberInvocationType(receiverType, selector.memberName);
    checkDynamicInvoke(node, receiverType, argumentTypes, selector);
    return findReturnType(methodType);
  }

  @override
  ResolutionDartType visitIfNotNullDynamicPropertyInvoke(
      Send node, Node receiver, NodeList arguments, Selector selector, _) {
    ResolutionDartType receiverType = apply(receiver);
    List<ResolutionDartType> argumentTypes = findArgumentTypes(arguments);
    ResolutionFunctionType methodType =
        lookupInterfaceMemberInvocationType(receiverType, selector.memberName);
    checkDynamicInvoke(node, receiverType, argumentTypes, selector);
    return findReturnType(methodType);
  }

  @override
  ResolutionDartType visitTopLevelFunctionInvoke(
      Send node,
      MethodElement function,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    apply(arguments);
    return findReturnType(function.type);
  }

  @override
  ResolutionDartType visitStaticFunctionInvoke(
      Send node,
      MethodElement function,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    apply(arguments);
    return findReturnType(function.type);
  }
}

/// Computes the [ClassElement] implied by a type.
// TODO(johnniwinther): Handle type variables, function types and typedefs.
class ClassFinder extends BaseResolutionDartTypeVisitor<ClassElement, dynamic> {
  const ClassFinder();

  ClassElement findClass(ResolutionDartType type) => type.accept(this, null);

  @override
  ClassElement visitType(ResolutionDartType type, _) => null;

  @override
  ClassElement visitInterfaceType(ResolutionInterfaceType type, _) {
    return type.element;
  }
}
