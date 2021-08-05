// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;
import 'package:kernel/type_environment.dart' as ir;

import '../common_elements.dart' show CommonElements;
import '../constants/values.dart'
    show
        ConstantValue;
import '../elements/types.dart';
import '../elements/entities.dart';
import '../ir/util.dart';
import '../kernel/element_map.dart';

/// [Dependencies] is a helper for collecting per [Entity] [DependencyInfo].
class Dependencies {
  final Map<ClassEntity, DependencyInfo> classes = {};
  final Map<ClassEntity, DependencyInfo> classType = {};
  final Map<MemberEntity, DependencyInfo> members = {};
  final Set<Local> localFunctions = {};
  final Map<ConstantValue, DependencyInfo> constants = {};

  void addClass(ClassEntity cls, [ImportEntity import]) {
    (classes[cls] ??= DependencyInfo()).registerImport(import);

    // Add a classType dependency as well just in case we optimize out
    // the class later.
    addClassType(cls, import);
  }

  void addClassType(ClassEntity cls, [ImportEntity import]) {
    (classType[cls] ??= DependencyInfo()).registerImport(import);
  }

  void addMember(MemberEntity m, [ImportEntity import]) {
    (members[m] ??= DependencyInfo()).registerImport(import);
  }

  void addConstant(ConstantValue c, [ImportEntity import]) {
    (constants[c] ??= DependencyInfo()).registerImport(import);
  }
}

class DependencyInfo {
  bool isDeferred = true;
  List<ImportEntity> imports;

  registerImport(ImportEntity import) {
    if (!isDeferred) return;
    // A null import represents a direct non-deferred dependency.
    if (import != null) {
      (imports ??= []).add(import);
    } else {
      imports = null;
      isDeferred = false;
    }
  }
}

class TypeDependencyVisitor implements DartTypeVisitor<void, Null> {
  final Dependencies _dependencies;
  final ImportEntity _import;
  final CommonElements _commonElements;

  TypeDependencyVisitor(this._dependencies, this._import, this._commonElements);

  @override
  void visit(DartType type, [_]) {
    type.accept(this, null);
  }

  void visitList(List<DartType> types) {
    types.forEach(visit);
  }

  @override
  void visitLegacyType(LegacyType type, Null argument) {
    visit(type.baseType);
  }

  @override
  void visitNullableType(NullableType type, Null argument) {
    visit(type.baseType);
  }

  @override
  void visitFutureOrType(FutureOrType type, Null argument) {
    _dependencies.addClassType(_commonElements.futureClass);
    visit(type.typeArgument);
  }

  @override
  void visitNeverType(NeverType type, Null argument) {
    // Nothing to add.
  }

  @override
  void visitDynamicType(DynamicType type, Null argument) {
    // Nothing to add.
  }

  @override
  void visitErasedType(ErasedType type, Null argument) {
    // Nothing to add.
  }

  @override
  void visitAnyType(AnyType type, Null argument) {
    // Nothing to add.
  }

  @override
  void visitInterfaceType(InterfaceType type, Null argument) {
    visitList(type.typeArguments);
    _dependencies.addClassType(type.element, _import);
  }

  @override
  void visitFunctionType(FunctionType type, Null argument) {
    for (FunctionTypeVariable typeVariable in type.typeVariables) {
      visit(typeVariable.bound);
    }
    visitList(type.parameterTypes);
    visitList(type.optionalParameterTypes);
    visitList(type.namedParameterTypes);
    visit(type.returnType);
  }

  @override
  void visitFunctionTypeVariable(FunctionTypeVariable type, Null argument) {
    // Nothing to add. Handled in [visitFunctionType].
  }

  @override
  void visitTypeVariableType(TypeVariableType type, Null argument) {
    // TODO(johnniwinther): Do we need to collect the bound?
  }

  @override
  void visitVoidType(VoidType type, Null argument) {
    // Nothing to add.
  }
}

class ConstantCollector extends ir.RecursiveVisitor {
  final KernelToElementMap elementMap;
  final Dependencies dependencies;
  final ir.StaticTypeContext staticTypeContext;

  ConstantCollector(this.elementMap, this.staticTypeContext, this.dependencies);

  CommonElements get commonElements => elementMap.commonElements;

  void add(ir.Expression node, {bool required = true}) {
    ConstantValue constant = elementMap
        .getConstantValue(staticTypeContext, node, requireConstant: required);
    if (constant != null) {
      dependencies.addConstant(
          constant, elementMap.getImport(getDeferredImport(node)));
    }
  }

  @override
  void visitIntLiteral(ir.IntLiteral literal) {}

  @override
  void visitDoubleLiteral(ir.DoubleLiteral literal) {}

  @override
  void visitBoolLiteral(ir.BoolLiteral literal) {}

  @override
  void visitStringLiteral(ir.StringLiteral literal) {}

  @override
  void visitSymbolLiteral(ir.SymbolLiteral literal) => add(literal);

  @override
  void visitNullLiteral(ir.NullLiteral literal) {}

  @override
  void visitListLiteral(ir.ListLiteral literal) {
    if (literal.isConst) {
      add(literal);
    } else {
      super.visitListLiteral(literal);
    }
  }

  @override
  void visitSetLiteral(ir.SetLiteral literal) {
    if (literal.isConst) {
      add(literal);
    } else {
      super.visitSetLiteral(literal);
    }
  }

  @override
  void visitMapLiteral(ir.MapLiteral literal) {
    if (literal.isConst) {
      add(literal);
    } else {
      super.visitMapLiteral(literal);
    }
  }

  @override
  void visitConstructorInvocation(ir.ConstructorInvocation node) {
    if (node.isConst) {
      add(node);
    } else {
      super.visitConstructorInvocation(node);
    }
  }

  @override
  void visitTypeParameter(ir.TypeParameter node) {
    // We avoid visiting metadata on the type parameter declaration. The bound
    // cannot hold constants so we skip that as well.
  }

  @override
  void visitVariableDeclaration(ir.VariableDeclaration node) {
    // We avoid visiting metadata on the parameter declaration by only visiting
    // the initializer. The type cannot hold constants so can kan skip that
    // as well.
    node.initializer?.accept(this);
  }

  @override
  void visitTypeLiteral(ir.TypeLiteral node) {
    if (node.type is! ir.TypeParameterType) add(node);
  }

  @override
  void visitInstantiation(ir.Instantiation node) {
    // TODO(johnniwinther): The CFE should mark constant instantiations as
    // constant.
    add(node, required: false);
    super.visitInstantiation(node);
  }

  @override
  void visitConstantExpression(ir.ConstantExpression node) {
    add(node);
  }
}
