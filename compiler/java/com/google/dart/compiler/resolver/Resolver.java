// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.common.annotations.VisibleForTesting;
import com.google.common.collect.Sets;
import com.google.dart.compiler.DartCompilationPhase;
import com.google.dart.compiler.DartCompilerContext;
import com.google.dart.compiler.DartCompilerErrorCode;
import com.google.dart.compiler.ast.DartArrayLiteral;
import com.google.dart.compiler.ast.DartBinaryExpression;
import com.google.dart.compiler.ast.DartBlock;
import com.google.dart.compiler.ast.DartBooleanLiteral;
import com.google.dart.compiler.ast.DartBreakStatement;
import com.google.dart.compiler.ast.DartCatchBlock;
import com.google.dart.compiler.ast.DartClass;
import com.google.dart.compiler.ast.DartDoWhileStatement;
import com.google.dart.compiler.ast.DartDoubleLiteral;
import com.google.dart.compiler.ast.DartExpression;
import com.google.dart.compiler.ast.DartField;
import com.google.dart.compiler.ast.DartFieldDefinition;
import com.google.dart.compiler.ast.DartForInStatement;
import com.google.dart.compiler.ast.DartForStatement;
import com.google.dart.compiler.ast.DartFunction;
import com.google.dart.compiler.ast.DartFunctionExpression;
import com.google.dart.compiler.ast.DartFunctionObjectInvocation;
import com.google.dart.compiler.ast.DartFunctionTypeAlias;
import com.google.dart.compiler.ast.DartGotoStatement;
import com.google.dart.compiler.ast.DartIdentifier;
import com.google.dart.compiler.ast.DartIfStatement;
import com.google.dart.compiler.ast.DartInitializer;
import com.google.dart.compiler.ast.DartIntegerLiteral;
import com.google.dart.compiler.ast.DartInvocation;
import com.google.dart.compiler.ast.DartLabel;
import com.google.dart.compiler.ast.DartLiteral;
import com.google.dart.compiler.ast.DartMapLiteral;
import com.google.dart.compiler.ast.DartMethodDefinition;
import com.google.dart.compiler.ast.DartMethodInvocation;
import com.google.dart.compiler.ast.DartNamedExpression;
import com.google.dart.compiler.ast.DartNewExpression;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.DartParameter;
import com.google.dart.compiler.ast.DartPropertyAccess;
import com.google.dart.compiler.ast.DartRedirectConstructorInvocation;
import com.google.dart.compiler.ast.DartStatement;
import com.google.dart.compiler.ast.DartStringInterpolation;
import com.google.dart.compiler.ast.DartStringLiteral;
import com.google.dart.compiler.ast.DartSuperConstructorInvocation;
import com.google.dart.compiler.ast.DartSuperExpression;
import com.google.dart.compiler.ast.DartSwitchMember;
import com.google.dart.compiler.ast.DartSwitchStatement;
import com.google.dart.compiler.ast.DartThisExpression;
import com.google.dart.compiler.ast.DartTryStatement;
import com.google.dart.compiler.ast.DartTypeNode;
import com.google.dart.compiler.ast.DartTypedLiteral;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.ast.DartUnqualifiedInvocation;
import com.google.dart.compiler.ast.DartVariable;
import com.google.dart.compiler.ast.DartVariableStatement;
import com.google.dart.compiler.ast.DartWhileStatement;
import com.google.dart.compiler.ast.Modifiers;
import com.google.dart.compiler.type.FunctionType;
import com.google.dart.compiler.type.InterfaceType;
import com.google.dart.compiler.type.InterfaceType.Member;
import com.google.dart.compiler.type.Type;
import com.google.dart.compiler.type.TypeVariable;

import java.util.EnumSet;
import java.util.Iterator;
import java.util.List;
import java.util.Set;

/**
 * Resolves unqualified symbols in a compilation unit.
 */
public class Resolver {

  private final ResolutionContext topLevelContext;
  private final CoreTypeProvider typeProvider;
  private final InterfaceType rawArrayType;
  private final InterfaceType defaultLiteralMapType;


  private static final EnumSet<ElementKind> INVOKABLE_ELEMENTS = EnumSet.<ElementKind>of(
      ElementKind.FIELD,
      ElementKind.PARAMETER,
      ElementKind.VARIABLE,
      ElementKind.FUNCTION_OBJECT,
      ElementKind.METHOD);

  @VisibleForTesting
  public Resolver(DartCompilerContext compilerContext, Scope libraryScope,
                  CoreTypeProvider typeProvider) {
    compilerContext.getClass(); // Fast null-check.
    libraryScope.getClass(); // Fast null-check.
    typeProvider.getClass(); // Fast null-check.
    this.topLevelContext = new ResolutionContext(libraryScope, compilerContext, typeProvider);
    this.typeProvider = typeProvider;
    Type dynamicType = typeProvider.getDynamicType();
    Type stringType = typeProvider.getStringType();
    this.defaultLiteralMapType = typeProvider.getMapType(stringType, dynamicType);
    this.rawArrayType = typeProvider.getArrayType(dynamicType);
  }

  @VisibleForTesting
  public DartUnit exec(DartUnit unit) {
    // Visits all top level elements of a compilation unit and resolves names used in method
    // bodies.
    LibraryElement library = unit.getLibrary() != null ? unit.getLibrary().getElement() : null;
    unit.accept(new ResolveElementsVisitor(topLevelContext, library));
    return unit;
  }

  /**
   * Main entry point for IDE. Resolves a member (method or field)
   * incrementally in the given context.
   *
   * @param classElement the class enclosing the member.
   * @param member the member to resolve.
   * @param context a resolution context corresponding to classElement.
   */
  public void resolveMember(ClassElement classElement, Element member, ResolutionContext context) {
    ResolveElementsVisitor visitor;
    switch (member.getKind()) {
      case CONSTRUCTOR:
      case METHOD:
        ResolutionContext methodContext = context.extend(member.getName());
        visitor = new ResolveElementsVisitor(methodContext, classElement,
                                             (MethodElement) member);
        break;

        case FIELD:
          ResolutionContext fieldContext = context;
          if (member.getModifiers().isAbstractField()) {
            fieldContext = context.extend(member.getName());
          }
          visitor = new ResolveElementsVisitor(fieldContext, classElement);
          break;

      default:
        throw topLevelContext.internalError(member.getNode(),
                                            "unexpected element kind: %s", member.getKind());
    }
    member.getNode().accept(visitor);
  }

  /**
   * Resolves names in a method body.
   *
   * TODO(ngeoffray): Errors reported:
   *  - A default implementation not providing the default methods.
   *  - An interface with default methods but without a default implementation.
   *  - A member method shadowing a super property.
   *  - A member property shadowing a super method.
   *  - A formal parameter in a non-constructor shadowing a member.
   *  - A local variable shadowing another variable.
   *  - A local variable shadowing a formal parameter.
   *  - A local variable shadowing a class member.
   *  - Using 'this' or 'super' in a static or factory method, or in an initializer.
   *  - Using 'super' in a class without a super class.
   *  - Incorrectly using a resolved element.
   */
  @VisibleForTesting
  public class ResolveElementsVisitor extends ResolveVisitor {
    private EnclosingElement currentHolder;
    private MethodElement currentMethod;
    private boolean inInitializer;
    private MethodElement innermostFunction;
    private ResolutionContext context;
    private LabelElement currentLabel;
    private Set<LabelElement> referencedLabels = Sets.newHashSet();
    private Set<LabelElement> labelsInScopes = Sets.newHashSet();

    @VisibleForTesting
    public ResolveElementsVisitor(ResolutionContext context,
                                  EnclosingElement currentHolder,
                                  MethodElement currentMethod) {
      super(typeProvider);
      this.context = context;
      this.currentMethod = currentMethod;
      this.innermostFunction = currentMethod;
      this.currentHolder = currentHolder;
      this.inInitializer = false;
    }

    private ResolveElementsVisitor(ResolutionContext context, EnclosingElement currentHolder) {
      this(context, currentHolder, null);
    }

    @Override
    ResolutionContext getContext() {
      return context;
    }

    @Override
    public Element visitUnit(DartUnit unit) {
      for (DartNode node : unit.getTopLevelNodes()) {
        node.accept(this);
      }
      return null;
    }

    @Override
    public Element visitFunctionTypeAlias(DartFunctionTypeAlias alias) {
      return null;
    }

    @Override
    public Element visitClass(DartClass cls) {
      assert currentMethod == null : "nested class?";
      ClassElement classElement = cls.getSymbol();
      try {
        classElement.getAllSupertypes();
      } catch (CyclicDeclarationException e) {
        DartNode node = e.getElement().getNode();
        if (node == null) {
          node = cls;
        }
        resolutionError(node, DartCompilerErrorCode.CYCLIC_CLASS, e.getElement().getName());
      } catch (DuplicatedInterfaceException e) {
        resolutionError(cls, DartCompilerErrorCode.DUPLICATED_INTERFACE,
                        e.getFirst(), e.getSecond());
      }
      ResolutionContext previousContext = context;
      EnclosingElement previousHolder = currentHolder;
      currentHolder = classElement;
      context = topLevelContext.extend(classElement);

      for (Element element : classElement.getMembers()) {
        element.getNode().accept(this);
      }

      for (Element element : classElement.getConstructors()) {
        element.getNode().accept(this);
      }

      checkRedirectConstructorCycle(classElement.getConstructors(), context);
      if (Elements.needsImplicitDefaultConstructor(classElement)) {
        checkImplicitDefaultDefaultSuperInvocation(cls, classElement);
      }

      context = previousContext;
      currentHolder = previousHolder;
      return classElement;
    }


    /**
     * Returns <code>true</code> if the {@link ClassElement} has an implicit or a declared
     * default constructor.
     */
    boolean hasDefaultConstructor(ClassElement classElement) {
      if (Elements.needsImplicitDefaultConstructor(classElement)) {
        return true;
      }

      ConstructorElement defaultCtor = Elements.lookupConstructor(classElement, "");
      if (defaultCtor != null) {
        return defaultCtor.getParameters().isEmpty();
      }

      return false;
    }

    private void checkImplicitDefaultDefaultSuperInvocation(DartClass cls,
        ClassElement classElement) {
      assert (Elements.needsImplicitDefaultConstructor(classElement));

      InterfaceType supertype = classElement.getSupertype();
      if (supertype != null) {
        ClassElement superElement = supertype.getElement();
        if (!superElement.isDynamic()) {
          ConstructorElement superCtor = Elements.lookupConstructor(superElement, "");
          if (superCtor != null && !superCtor.getParameters().isEmpty()) {
            resolutionError(cls.getName(),
                DartCompilerErrorCode.CANNOT_RESOLVE_IMPLICIT_CALL_TO_SUPER_CONSTRUCTOR,
                cls.getSuperclass());
          }
        }
      }
    }

    private Element resolve(DartNode node) {
      if (node == null) {
        return null;
      } else {
        return node.accept(this);
      }
    }

    @Override
    public MethodElement visitMethodDefinition(DartMethodDefinition node) {
      MethodElement member = node.getSymbol();
      ResolutionContext previousContext = context;
      context = context.extend(member.getName());
      assert currentMethod == null : "Nested methods?";
      innermostFunction = currentMethod = member;

      DartFunction functionNode = node.getFunction();
      List<DartParameter> parameters = functionNode.getParams();

      FunctionType type = (FunctionType) member.getType();
      for (TypeVariable typeVariable : type.getTypeVariables()) {
        context.declare(typeVariable.getElement());
      }

      // First declare all normal parameters in the scope, putting them in the
      // scope of the default expressions so we can report better errors.
      for (DartParameter parameter : parameters) {
        assert parameter.getSymbol() != null;
        if (parameter.getQualifier() instanceof DartThisExpression) {
          checkParameterInitializer(node, parameter);
        } else {
          getContext().declare(parameter.getSymbol());
        }
      }
      for (DartParameter parameter : parameters) {
        // Then resolve the default values.
        resolveConstantExpression(parameter.getDefaultExpr());
      }

      if ((functionNode.getBody() == null)
          && !Elements.isNonFactoryConstructor(member)
          && !member.getModifiers().isAbstract()
          && !member.getEnclosingElement().isInterface()) {
        resolutionError(functionNode, DartCompilerErrorCode.METHOD_MUST_HAVE_BODY);
      }
      resolve(functionNode.getBody());

      if (Elements.isNonFactoryConstructor(member)) {
        resolveInitializers(node);
      }

      context = previousContext;
      innermostFunction = currentMethod = null;
      return member;
    }

    private void resolveConstantExpression(DartExpression defaultExpr) {
      resolve(defaultExpr);
      checkConstantExpression(defaultExpr);
    }

    private void checkConstantExpression(DartExpression defaultExpr) {
      // See bug 4568007.
    }

    private void checkConstantLiteral(DartExpression defaultExpr) {
      if ((!(defaultExpr instanceof DartLiteral))
          || ((defaultExpr instanceof DartTypedLiteral)
              && (!((DartTypedLiteral) defaultExpr).isConst()))) {
        resolutionError(defaultExpr, DartCompilerErrorCode.EXPECTED_CONSTANT_LITERAL);
      }
    }

    @Override
    public Element visitField(DartField node) {
      DartExpression expression = node.getValue();
      Modifiers modifiers = node.getModifiers();
      boolean isStatic = modifiers.isStatic();
      boolean isFinal = modifiers.isFinal();
      boolean isTopLevel = ElementKind.of(currentHolder).equals(ElementKind.LIBRARY);

      if (expression != null) {
        if (isStatic || isTopLevel) {
          checkConstantExpression(expression);
        } else {
          // TODO(5200401): Only allow constant literals for inline field initializers for now.
          checkConstantLiteral(expression);
        }
        resolve(expression);
      } else if (isStatic && isFinal) {
        resolutionError(node, DartCompilerErrorCode.STATIC_FINAL_REQUIRES_VALUE);
      }

      // If field is an acessor, both getter and setter need to be visited (if present).
      FieldElement field = node.getSymbol();
      if (field.getGetter() != null) {
        resolve(field.getGetter().getNode());
      }
      if (field.getSetter() != null) {
        resolve(field.getSetter().getNode());
      }
      return null;
    }

    @Override
    public Element visitFieldDefinition(DartFieldDefinition node) {
      visit(node.getFields());
      return null;
    }

    @Override
    public Element visitFunction(DartFunction node) {
      throw context.internalError(node, "should not be called.");
    }

    @Override
    public Element visitParameter(DartParameter x) {
      Element element = super.visitParameter(x);
      resolveConstantExpression(x.getDefaultExpr());
      getContext().declare(element);
      return element;
    }

    public Element resolveVariable(DartVariable x, Modifiers modifiers) {
      // Visit the initializer first.
      resolve(x.getValue());
      VariableElement element = Elements.variableElement(x, x.getVariableName(), modifiers);
      getContext().declare(recordElement(x, element));
      return element;
    }

    @Override
    public Element visitVariableStatement(DartVariableStatement node) {
      resolveVariableStatement(node, false);
      return null;
    }

    private void resolveVariableStatement(DartVariableStatement node,
                                          boolean isImplicitlyInitialized) {
       Type type = resolveType(node.getTypeNode(), inStaticContext(currentMethod));
       for (DartVariable variable : node.getVariables()) {
         Elements.setType(resolveVariable(variable, node.getModifiers()), type);
         checkVariableStatement(node, variable, isImplicitlyInitialized);
       }
     }

    @Override
    public Element visitLabel(DartLabel x) {
      LabelElement previousLabel = currentLabel;
      currentLabel = Elements.labelElement(x, x.getName(), innermostFunction);
      recordElement(x, currentLabel);
      x.visitChildren(this);
      if (!labelsInScopes.contains(currentLabel)) {
        // TODO(zundel): warning, not type error.
        // topLevelContext.typeError(x, DartCompilerErrorCode.USELESS_LABEL, x.getName());
      } else if (!referencedLabels.contains(currentLabel)) {
        // TODO(zundel): warning, not type error.
        // topLevelContext.typeError(x, DartCompilerErrorCode.UNREFERENCED_LABEL, x.getName());
      }
      currentLabel = previousLabel;
      return null;
    }

    @Override
    public Element visitFunctionExpression(DartFunctionExpression x) {
      MethodElement element;
      if (x.isStatement()) {
        // Function statement names live in the outer scope.
        element = getContext().declareFunction(x);
        getContext().pushFunctionScope(x);
      } else {
        // Function expression names live in their own scope.
        getContext().pushFunctionScope(x);
        element = getContext().declareFunction(x);
      }
      MethodElement previousFunction = innermostFunction;
      innermostFunction = element;
      DartFunction functionNode = x.getFunction();
      resolveFunction(functionNode, element, null);
      resolve(functionNode.getBody());
      innermostFunction = previousFunction;
      getContext().popScope();
      return recordElement(x, element);
    }

    @Override
    public Element visitBlock(DartBlock x) {
      getContext().pushScope("<block>");
      addLabelToStatement(x);
      x.visitChildren(this);
      getContext().popScope();
      return null;
    }

    @Override
    public Element visitBreakStatement(DartBreakStatement x) {
      // Handle corner case of L: break L;
      DartNode parent = x.getParent();
      if (parent instanceof DartLabel && x.getLabel() != null) {
        if (((DartLabel) parent).getLabel().getTargetName().equals(x.getLabel().getTargetName())) {
          getContext().pushScope("<break>");
          addLabelToStatement(x);
          visitGotoStatement(x);
          getContext().popScope();
          return null;
        }
      }
      return visitGotoStatement(x);
    }

    @Override
    public Element visitTryStatement(DartTryStatement x) {
      getContext().pushScope("<try>");
      addLabelToStatement(x);
      x.visitChildren(this);
      getContext().popScope();
      return null;
    }

    @Override
    public Element visitCatchBlock(DartCatchBlock x) {
      getContext().pushScope("<block>");
      addLabelToStatement(x);
      x.visitChildren(this);
      getContext().popScope();
      return null;
    }

    @Override
    public Element visitDoWhileStatement(DartDoWhileStatement x) {
      getContext().pushScope("<do>");
      addLabelToStatement(x);
      x.visitChildren(this);
      getContext().popScope();
      return null;
    }

    @Override
    public Element visitWhileStatement(DartWhileStatement x) {
      getContext().pushScope("<while>");
      addLabelToStatement(x);
      x.visitChildren(this);
      getContext().popScope();
      return null;
    }

    @Override
    public Element visitIfStatement(DartIfStatement x) {
      getContext().pushScope("<if>");
      addLabelToStatement(x);
      x.visitChildren(this);
      getContext().popScope();
      return null;
    }

    @Override
    public Element visitForInStatement(DartForInStatement x) {
      getContext().pushScope("<for in>");
      addLabelToStatement(x);

      if (x.introducesVariable()) {
        resolveVariableStatement(x.getVariableStatement(), true);
      } else {
        x.getIdentifier().accept(this);
      }
      x.getIterable().accept(this);
      x.getBody().accept(this);
      getContext().popScope();
      return null;
    }

    private void addLabelToStatement(DartStatement x) {
      if (currentLabel != null) {
        DartNode parent = x.getParent();
        if (parent instanceof DartLabel) {
          getContext().getScope().setLabel(currentLabel);
          labelsInScopes.add(currentLabel);
        }
      }
    }

    @Override
    public Element visitForStatement(DartForStatement x) {
      getContext().pushScope("<for>");
      addLabelToStatement(x);
      x.visitChildren(this);
      getContext().popScope();
      return null;
    }


    @Override
    public Element visitSwitchStatement(DartSwitchStatement x) {
      getContext().pushScope("<switch>");
      addLabelToStatement(x);
      x.visitChildren(this);
      getContext().popScope();
      return null;
    }

    @Override
    public Element visitSwitchMember(DartSwitchMember x) {
      getContext().pushScope("<switch member>");
      x.visitChildren(this);
      getContext().popScope();
      return null;
    }

    @Override
    public Element visitThisExpression(DartThisExpression x) {
      if (currentMethod.getModifiers().isStatic()) {
        resolutionError(x, DartCompilerErrorCode.STATIC_METHOD_ACCESS_THIS);
      } else if (ElementKind.of(currentHolder).equals(ElementKind.LIBRARY)) {
        resolutionError(x, DartCompilerErrorCode.TOP_LEVEL_METHOD_ACCESS_THIS);
      }
      return null;
    }

    @Override
    public Element visitSuperExpression(DartSuperExpression x) {
      if (ElementKind.of(currentHolder).equals(ElementKind.LIBRARY)) {
        resolutionError(x, DartCompilerErrorCode.TOP_LEVEL_METHOD_ACCESS_SUPER);
      } else if (currentMethod == null) {
        resolutionError(x, DartCompilerErrorCode.SUPER_OUTSIDE_OF_METHOD);
      } else if (currentMethod.getModifiers().isStatic()) {
        resolutionError(x, DartCompilerErrorCode.STATIC_METHOD_ACCESS_SUPER);
      } else if  (currentMethod.getModifiers().isFactory()) {
        resolutionError(x, DartCompilerErrorCode.FACTORY_ACCESS_SUPER);
      } else {
        return recordElement(x, Elements.superElement(
            x, ((ClassElement) currentHolder).getSupertype().getElement()));
      }
      return null;
    }

    @Override
    public Element visitSuperConstructorInvocation(DartSuperConstructorInvocation x) {
      visit(x.getArgs());
      String name = x.getName() == null ? "" : x.getName().getTargetName();
      InterfaceType supertype = ((ClassElement) currentHolder).getSupertype();
      ConstructorElement element = (supertype == null) ?
          null : Elements.lookupConstructor(supertype.getElement(), name);
      if (element == null) {
        resolutionError(x, DartCompilerErrorCode.CANNOT_RESOLVE_SUPER_CONSTRUCTOR, name);
      }
      return recordElement(x, element);
    }

    @Override
    public Element visitNamedExpression(DartNamedExpression node) {
      // Intentionally skip the expression's name -- it's stored as an identifier, but doesn't need
      // to be resolved.
      return node.getExpression().accept(this);
    }

    @Override
    public Element visitIdentifier(DartIdentifier x) {
      return resolveIdentifier(x, false);
    }

    private Element resolveIdentifier(DartIdentifier x, boolean isQualifier) {
      Element element = getContext().getScope().findElement(x.getTargetName());
      if (element == null) {
        if (isStaticContextOrInitializer()) {
          if (!context.shouldWarnOnNoSuchType()) {
            resolutionError(x, DartCompilerErrorCode.CANNOT_BE_RESOLVED, x.getTargetName());
          }
        }
      } else {
        switch (element.getKind()) {
          case FIELD:
            if (inStaticContext(currentMethod) && !inStaticContext(element)) {
              resolutionError(x, DartCompilerErrorCode.ILLEGAL_FIELD_ACCESS_FROM_STATIC,
                  x.getTargetName());
            }
            break;
          case METHOD:
            if (inStaticContext(currentMethod) && !inStaticContext(element)) {
              resolutionError(x, DartCompilerErrorCode.ILLEGAL_METHOD_ACCESS_FROM_STATIC,
                  x.getTargetName());
            }
            break;
          case CLASS:
            if (!isQualifier) {
              resolutionError(x, DartCompilerErrorCode.IS_A_CLASS, x.getTargetName());
            }
            break;

          default:
            break;
        }
      }

      if (inInitializer && (element != null && element.getKind().equals(ElementKind.FIELD))) {
        if (!element.getModifiers().isStatic() && !Elements.isTopLevel(element)) {
          resolutionError(x, DartCompilerErrorCode.CANNOT_ACCESS_FIELD_IN_INIT);
        }
      }

      // If we we haven't resolved the identifier, it will be normalized to
      // this.<identifier>.

      return recordElement(x, element);
    }

    @Override
    public Element visitTypeNode(DartTypeNode x) {
      return resolveType(x, inStaticContext(currentMethod)).getElement();
    }

    @Override
    public Element visitPropertyAccess(DartPropertyAccess x) {
      Element qualifier = resolveQualifier(x.getQualifier());
      Element element = null;
      switch (ElementKind.of(qualifier)) {
        case CLASS:
          // Must be a static field.
          element = Elements.findElement(((ClassElement) qualifier), x.getPropertyName());
          switch (ElementKind.of(element)) {
            case FIELD:
              FieldElement field = (FieldElement) element;
              if (!field.getModifiers().isStatic()) {
                resolutionError(x.getName(), DartCompilerErrorCode.NOT_A_STATIC_FIELD,
                    x.getPropertyName());
              }
              break;

            case NONE:
              resolutionError(x.getName(), DartCompilerErrorCode.CANNOT_BE_RESOLVED,
                  x.getPropertyName());
              break;

            case METHOD:
              MethodElement method = (MethodElement) element;
              if (!method.getModifiers().isStatic()) {
                resolutionError(x.getName(), DartCompilerErrorCode.NOT_A_STATIC_METHOD,
                    x.getPropertyName());
              }
              break;

            default:
              resolutionError(x.getName(), DartCompilerErrorCode.EXPECTED_STATIC_FIELD,
                  element.getKind());
              break;
          }
          break;

        case SUPER:
          ClassElement cls = ((SuperElement) qualifier).getClassElement();
          Member member = cls.getType().lookupMember(x.getPropertyName());
          if (member != null) {
            element = member.getElement();
          }
          switch (ElementKind.of(element)) {
            case FIELD:
              FieldElement field = (FieldElement) element;
              if (field.getModifiers().isStatic()) {
                resolutionError(x.getName(), DartCompilerErrorCode.NOT_AN_INSTANCE_FIELD,
                  x.getPropertyName());
              }
              break;
            case METHOD:
              MethodElement method = (MethodElement) element;
              if (method.isStatic()) {
                resolutionError(x.getName(), DartCompilerErrorCode.NOT_AN_INSTANCE_FIELD,
                  x.getPropertyName());
              }
              break;

            case NONE:
              resolutionError(x.getName(), DartCompilerErrorCode.CANNOT_BE_RESOLVED,
                  x.getPropertyName());
              break;

            default:
              resolutionError(x.getName(),
                DartCompilerErrorCode.EXPECTED_AN_INSTANCE_FIELD_IN_SUPER_CLASS,
                element.getKind());
              break;
          }
          break;

        case LIBRARY:
          // Library prefix, lookup the element in the reference library.
          element = ((LibraryElement) qualifier).getScope().findElement(x.getPropertyName());
          if (element == null) {
            resolutionError(x, DartCompilerErrorCode.CANNOT_BE_RESOLVED_LIBRARY,
                x.getPropertyName(), qualifier.getName());
          }
          break;

        default:
          break;
      }
      return recordElement(x, element);
    }

    private Element resolveQualifier(DartNode qualifier) {
      return (qualifier instanceof DartIdentifier)
          ? resolveIdentifier((DartIdentifier) qualifier, true)
          : qualifier.accept(this);
    }

    @Override
    public Element visitMethodInvocation(DartMethodInvocation x) {
      Element target = resolveQualifier(x.getTarget());
      Element element = null;

      switch (ElementKind.of(target)) {
        case CLASS: {
          // Must be a static method or field.
          ClassElement classElement = (ClassElement) target;
          element = Elements.lookupLocalMethod(classElement, x.getFunctionNameString());
          if (element == null) {
            element = Elements.lookupLocalField(classElement, x.getFunctionNameString());
          }
          if (element == null || !element.getModifiers().isStatic()) {
            diagnoseErrorInMethodInvocation(x, (ClassElement) target, element);
          }
          break;
        }

        case SUPER: {
          // Must be a superclass' method or field.
          ClassElement classElement = ((SuperElement) target).getClassElement();
          InterfaceType type = classElement.getType();
          Member member = type.lookupMember(x.getFunctionNameString());
          if (member != null) {
            if (!member.getElement().getModifiers().isStatic()) {
              element = member.getElement();
            }
          }
          break;
        }

        case LIBRARY:
          // Library prefix, lookup the element in the reference library.
          element = ((LibraryElement) target).getScope().findElement(x.getFunctionNameString());
          if (element == null) {
            diagnoseErrorInMethodInvocation(x, null, null);
          }
          break;
      }

      checkInvocationTarget(x, currentMethod, target);
      visit(x.getArgs());
      return recordElement(x, element);
    }

    @Override
    public Element visitUnqualifiedInvocation(DartUnqualifiedInvocation x) {
      Element element = getContext().getScope().findElement(x.getTarget().getTargetName());
      ElementKind kind = ElementKind.of(element);
      if (!INVOKABLE_ELEMENTS.contains(kind)) {
        diagnoseErrorInUnqualifiedInvocation(x);
      } else {
        checkInvocationTarget(x, currentMethod, element);
      }
      recordElement(x.getTarget(), element);
      visit(x.getArgs());
      return null;
    }

    @Override
    public Element visitFunctionObjectInvocation(DartFunctionObjectInvocation x) {
      x.getTarget().accept(this);
      visit(x.getArgs());
      return null;
    }

    @Override
    public Element visitNewExpression(DartNewExpression x) {
      this.visit(x.getArgs());

      Element element = x.getConstructor().accept(getContext().new Selector() {
        // Only 'new' expressions can have a type in a property access.
        @Override public Element visitTypeNode(DartTypeNode type) {
          return recordType(type, resolveType(type, inStaticContext(currentMethod)));
        }

        @Override public Element visitPropertyAccess(DartPropertyAccess node) {
          Element element = node.getQualifier().accept(this);
          if (ElementKind.of(element).equals(ElementKind.CLASS)) {
            return Elements.lookupConstructor(((ClassElement) element), node.getPropertyName());
          } else {
            return null;
          }
        }
      });


      if (ElementKind.of(element).equals(ElementKind.CLASS)) {
        // Check for default constructor or implicit default constructor
        ClassElement classElement = (ClassElement) element;
        element = Elements.lookupConstructor(classElement, "");
        if (element == null) {
          // Check that the class needs an implicit ctor and no extra args are passed
          if (Elements.needsImplicitDefaultConstructor(classElement) && x.getArgs().isEmpty()) {
            InterfaceType defaultClass = classElement.getDefaultClass();
            if (defaultClass != null) {
              classElement = defaultClass.getElement();
              element = Elements.lookupConstructor(classElement, "");
            }

            if (element == null) {
              return recordElement(x, element);
            }
          }
        }
      }

      // If there is a default implementation, lookup the constructor in the
      // default class.
      ConstructorElement constructor = checkIsConstructor(x, element);
      if (constructor != null
          && constructor.getConstructorType().getDefaultClass() != null) {
        ClassElement originalClass = constructor.getConstructorType();
        ClassElement defaultClass =
          constructor.getConstructorType().getDefaultClass().getElement();
        element = Elements.lookupConstructor(defaultClass, originalClass, constructor.getName());
        if (element == null) {
          // If the constructor hasn't been found, try the constructor of the default class.
          // TODO(ngeoffray): check earlier if the default class implements the interface.
          element = Elements.lookupConstructor(defaultClass, constructor.getName());
          if (element == null && Elements.needsImplicitDefaultConstructor(defaultClass)) {
            /*
             *  Record the element and prevent checkIsConstructor from reporting errors below
             *  since we know that w don't have an element.
             */
            return recordElement(x, element);
          }
        }

        // Will check that element is not null.
        constructor = checkIsConstructor(x, element);
      }

      return recordElement(x, constructor);
    }

    @Override
    public Element visitGotoStatement(DartGotoStatement x) {
      // Don't bother unless there's a target.
      if (x.getTargetName() != null) {
        Element element = getContext().getScope().findLabel(x.getTargetName(), innermostFunction);
        if (ElementKind.of(element).equals(ElementKind.LABEL)) {
          LabelElement labelElement = (LabelElement) element;
          MethodElement enclosingFunction = (labelElement).getEnclosingFunction();
          if (enclosingFunction == innermostFunction) {
            referencedLabels.add(labelElement);
            return recordElement(x, element);
          }
        }
        diagnoseErrorInGotoStatement(x, element);
      }
      return null;
    }

    public void diagnoseErrorInGotoStatement(DartGotoStatement x, Element element) {
      if (element == null) {
        resolutionError(x.getLabel(), DartCompilerErrorCode.CANNOT_RESOLVE_LABEL,
            x.getTargetName());
      } else if (ElementKind.of(element).equals(ElementKind.LABEL)) {
        resolutionError(x.getLabel(), DartCompilerErrorCode.CANNOT_ACCESS_OUTER_LABEL,
            x.getTargetName());
      } else {
        resolutionError(x.getLabel(), DartCompilerErrorCode.NOT_A_LABEL, x.getTargetName());
      }
    }

    private void diagnoseErrorInMethodInvocation(DartMethodInvocation node, ClassElement klass,
                                                 Element element) {
      String name = node.getFunctionNameString();
      ElementKind kind = ElementKind.of(element);
      DartNode errorNode = node.getFunctionName();
      switch (kind) {
        case NONE:
          resolutionError(errorNode, DartCompilerErrorCode.CANNOT_RESOLVE_METHOD, name);
          break;

        case CONSTRUCTOR:
          resolutionError(errorNode, DartCompilerErrorCode.IS_A_CONSTRUCTOR, klass.getName(),
                          name);
          break;

        case METHOD: {
          assert !((MethodElement) element).getModifiers().isStatic();
          resolutionError(errorNode, DartCompilerErrorCode.IS_AN_INSTANCE_METHOD,
              klass.getName(), name);
          break;
        }

        default:
          throw context.internalError(errorNode, "Unexpected kind of element: %s", kind);
      }
    }

    private void diagnoseErrorInUnqualifiedInvocation(DartUnqualifiedInvocation node) {
      String name = node.getTarget().getTargetName();
      Element element = getContext().getScope().findElement(name);
      ElementKind kind = ElementKind.of(element);
      switch (kind) {
        case NONE:
          if (isStaticContextOrInitializer()) {
            resolutionError(node, DartCompilerErrorCode.CANNOT_RESOLVE_METHOD, name);
          }
          break;

        case CONSTRUCTOR:
          resolutionError(node, DartCompilerErrorCode.DID_YOU_MEAN_NEW, name, "constructor");
          break;

        case CLASS:
          resolutionError(node, DartCompilerErrorCode.DID_YOU_MEAN_NEW, name, "class");
          break;

        case TYPE_VARIABLE:
          resolutionError(node, DartCompilerErrorCode.DID_YOU_MEAN_NEW, name, "type variable");
          break;

        case LABEL:
          resolutionError(node, DartCompilerErrorCode.CANNOT_CALL_LABEL);
          break;

        default:
          throw context.internalError(node, "Unexpected kind of element: %s", kind);
      }
    }

    private void diagnoseErrorInInitializer(DartIdentifier x) {
      String name = x.getTargetName();
      Element element = getContext().getScope().findElement(name);
      ElementKind kind = ElementKind.of(element);
      switch (kind) {
        case NONE:
          resolutionError(x, DartCompilerErrorCode.CANNOT_RESOLVE_FIELD, name);
          break;

        case FIELD:
          FieldElement field = (FieldElement) element;
          if (field.isStatic()) {
            resolutionError(x, DartCompilerErrorCode.CANNOT_INIT_STATIC_FIELD_IN_INITIALIZER);
          } else {
            resolutionError(x, DartCompilerErrorCode.CANNOT_INIT_FIELD_FROM_SUPERCLASS);
          }
          break;

        case METHOD:
          resolutionError(x, DartCompilerErrorCode.EXPECTED_FIELD_NOT_METHOD, name);
          break;

        case CLASS:
          resolutionError(x, DartCompilerErrorCode.EXPECTED_FIELD_NOT_CLASS, name);
          break;

        case PARAMETER:
          resolutionError(x, DartCompilerErrorCode.EXPECTED_FIELD_NOT_PARAMETER, name);
          break;

        case TYPE_VARIABLE:
          resolutionError(x, DartCompilerErrorCode.EXPECTED_FIELD_NOT_TYPE_VAR, name);
          break;

        case VARIABLE:
        case LABEL:
        default:
          throw context.internalError(x, "Unexpected kind of element: %s", kind);
      }
    }

    @Override
    public Element visitInitializer(DartInitializer x) {
      if (x.getName() != null) {
        // Make sure the identifier is a local instance field.
        FieldElement element = Elements.lookupLocalField(
            (ClassElement) currentHolder, x.getName().getTargetName());
        if (element == null || element.isStatic()) {
          diagnoseErrorInInitializer(x.getName());
        }
        recordElement(x.getName(), element);
      }

      assert !inInitializer;
      inInitializer = true;
      Element element = x.getValue().accept(this);
      inInitializer = false;
      return element;
    }

    @Override
    public Element visitRedirectConstructorInvocation(DartRedirectConstructorInvocation x) {
      visit(x.getArgs());
      String name = x.getName() != null ? x.getName().getTargetName() : "";
      ConstructorElement element = Elements.lookupConstructor((ClassElement) currentHolder, name);
      if (element == null) {
        resolutionError(x, DartCompilerErrorCode.CANNOT_RESOLVE_CONSTRUCTOR, name);
      }
      return recordElement(x, element);
    }

    @Override
    public Element visitIntegerLiteral(DartIntegerLiteral node) {
      recordType(node, typeProvider.getIntType());
      return null;
    }

    @Override
    public Element visitDoubleLiteral(DartDoubleLiteral node) {
      recordType(node, typeProvider.getDoubleType());
      return null;
    }

    @Override
    public Element visitBooleanLiteral(DartBooleanLiteral node) {
      recordType(node, typeProvider.getBoolType());
      return null;
    }

    @Override
    public Element visitStringLiteral(DartStringLiteral node) {
      recordType(node, typeProvider.getStringType());
      return null;
    }

    @Override
    public Element visitStringInterpolation(DartStringInterpolation node) {
      node.visitChildren(this);
      recordType(node, typeProvider.getStringType());
      return null;
    }

    Element recordType(DartNode node, Type type) {
      node.setType(type);
      return type.getElement();
    }

    @Override
    public Element visitBinaryExpression(DartBinaryExpression node) {
      Element lhs = resolve(node.getArg1());
      resolve(node.getArg2());
      if (node.getOperator().isAssignmentOperator()) {
        switch (ElementKind.of(lhs)) {
         case FIELD:
         case PARAMETER:
         case VARIABLE:
           if (lhs.getModifiers().isFinal()) {
             topLevelContext.resolutionError(node, DartCompilerErrorCode.CANNOT_ASSIGN_TO_FINAL, lhs.getName());
           }
           break;
        }
      }
      return null;
    }

    @Override
    public Element visitMapLiteral(DartMapLiteral node) {
      List<DartTypeNode> typeArgs = node.getTypeArguments();
      InterfaceType type = topLevelContext.instantiateParameterizedType(
        defaultLiteralMapType.getElement(), node, typeArgs, inStaticContext(currentMethod));
      // instantiateParametersType() will complain for wrong number of parameters (!=2)
      recordType(node, type);
      visit(node.getEntries());
      return null;
    }

    @Override
    public Element visitArrayLiteral(DartArrayLiteral node) {
      List<DartTypeNode> typeArgs = node.getTypeArguments();
      InterfaceType type = topLevelContext.instantiateParameterizedType(rawArrayType.getElement(),
        node, typeArgs, inStaticContext(currentMethod));
      // instantiateParametersType() will complain for wrong number of parameters (!=1)
      recordType(node, type);
      visit(node.getExpressions());
      return null;
    }

    private ConstructorElement checkIsConstructor(DartNewExpression source, Element element) {
      if (!ElementKind.of(element).equals(ElementKind.CONSTRUCTOR)) {
        if (!context.shouldWarnOnNoSuchType()) {
          resolutionError(source.getConstructor(),
              DartCompilerErrorCode.NEW_EXPRESSION_NOT_CONSTRUCTOR);
        }
        return null;
      }
      return (ConstructorElement) element;
    }

    private void checkConstructor(DartMethodDefinition node,
                                  ConstructorElement superCall) {
      ClassElement currentClass = (ClassElement) currentHolder;
      if (superCall == null) {
        // Look for a default constructor in our super type
        InterfaceType supertype = currentClass.getSupertype();
        if (supertype != null) {
          superCall = Elements.lookupConstructor(supertype.getElement(), "");
        }
      }

      if ((superCall == null)
          && !currentClass.isObject()
          && !currentClass.isObjectChild()) {
        InterfaceType supertype = currentClass.getSupertype();
        if (supertype != null) {
          ClassElement superElement = supertype.getElement();
          if (superElement != null) {
            if (!hasDefaultConstructor(superElement)) {
              resolutionError(node,
                  DartCompilerErrorCode.CANNOT_RESOLVE_IMPLICIT_CALL_TO_SUPER_CONSTRUCTOR,
                  superElement.getName());
            }
          }
        }
      } else if ((superCall != null)
          && node.getModifiers().isConstant()
          && !superCall.getModifiers().isConstant()) {
        resolutionError(node,
            DartCompilerErrorCode.CONST_CONSTRUCTOR_MUST_CALL_CONST_SUPER);
      }
    }

    private void checkInvocationTarget(DartInvocation node,
                                       MethodElement callSite,
                                       Element target) {
      if (callSite != null
          && callSite.isStatic()
          && ElementKind.of(target).equals(ElementKind.METHOD)) {
        if (!target.getModifiers().isStatic() && !Elements.isTopLevel(target)) {
          resolutionError(node, DartCompilerErrorCode.INSTANCE_METHOD_FROM_STATIC);
        }
      }
    }

    private void checkVariableStatement(DartVariableStatement node,
                                        DartVariable variable,
                                        boolean isImplicitlyInitialized) {
      if (node.getModifiers().isFinal()) {
        if (!isImplicitlyInitialized && (variable.getValue() == null)) {
          resolutionError(variable.getName(), DartCompilerErrorCode.CONSTANTS_MUST_BE_INITIALIZED);
        } else if (isImplicitlyInitialized && (variable.getValue() != null)) {
          resolutionError(variable.getName(), DartCompilerErrorCode.CANNOT_BE_INITIALIZED);
        } else {
          checkConstantExpression(variable.getValue());
        }
      }
    }

    private void checkParameterInitializer(DartMethodDefinition method, DartParameter parameter) {
      if (Elements.isNonFactoryConstructor(method.getSymbol())) {
        if (method.getModifiers().isRedirectedConstructor()) {
          resolutionError(parameter.getName(),
              DartCompilerErrorCode.PARAMETER_INIT_WITH_REDIR_CONSTRUCTOR);
        }

        FieldElement element =
          Elements.lookupLocalField((ClassElement) currentHolder, parameter.getParameterName());
        if (element == null) {
          resolutionError(parameter, DartCompilerErrorCode.PARAMETER_NOT_MATCH_FIELD,
                          parameter.getName());
        } else if (element.isStatic()) {
          resolutionError(parameter,
                          DartCompilerErrorCode.PARAMETER_INIT_STATIC_FIELD,
                          parameter.getName());
        }

        // Field parameters are not visible as parameters, so we do not declare them
        // in the context. Instead we record the resolved field element.
        Elements.setParameterInitializerElement(parameter.getSymbol(), element);
      } else {
        resolutionError(parameter.getName(),
            DartCompilerErrorCode.PARAMETER_INIT_OUTSIDE_CONSTRUCTOR);
      }
    }

    private void resolveInitializers(DartMethodDefinition node) {
      assert null != node;
      Iterator<DartInitializer> initializers = node.getInitializers().iterator();
      ConstructorElement constructorElement = null;
      while (initializers.hasNext()) {
        DartInitializer initializer = initializers.next();
        Element element = resolve(initializer);
        if (ElementKind.of(element) == ElementKind.CONSTRUCTOR) {
          constructorElement = (ConstructorElement) element;
        }
      }

      checkConstructor(node, constructorElement);
    }

    private void resolutionError(DartNode node, DartCompilerErrorCode errorCode,
        Object... arguments) {
      context.resolutionError(node, errorCode, arguments);
    }

    private boolean inStaticContext(Element element) {
      return element == null || Elements.isTopLevel(element)
        || element.getModifiers().isStatic() || element.getModifiers().isFactory();
    }

    @Override
    boolean isStaticContext() {
      return inStaticContext(currentMethod);
    }

    boolean isStaticContextOrInitializer() {
      return inStaticContext(currentMethod) || inInitializer;
    }
  }

  public static class Phase implements DartCompilationPhase {
    /**
     * Executes symbol resolution on the given compilation unit.
     *
     * @param context The listener through which compilation errors are reported
     *          (not <code>null</code>)
     */
    @Override
    public DartUnit exec(DartUnit unit, DartCompilerContext context,
                         CoreTypeProvider typeProvider) {
      Scope unitScope = unit.getLibrary().getElement().getScope();
      return new Resolver(context, unitScope, typeProvider).exec(unit);
    }
  }

  private void checkRedirectConstructorCycle(List<ConstructorElement> constructors,
                                             ResolutionContext context) {
    for (ConstructorElement element : constructors) {
      if (hasRedirectedConstructorCycle(element)) {
        context.resolutionError(element.getNode(),
            DartCompilerErrorCode.REDIRECTED_CONSTRUCTOR_CYCLE);
      }
    }
  }

  private boolean hasRedirectedConstructorCycle(ConstructorElement constructorElement) {
    ConstructorElement next = getNextConstructorInvocation(constructorElement);
    while (next != null) {
      if (constructorElement.getName().equals(next.getName())) {
        return true;
      }
      next = getNextConstructorInvocation(next);
    }
    return false;
  }

  private ConstructorElement getNextConstructorInvocation(ConstructorElement constructor) {
    List<DartInitializer> inits = ((DartMethodDefinition) constructor.getNode()).getInitializers();
    // The parser ensures that redirected constructors can be the only item in the initialization
    // list.
    if (inits.size() == 1) {
      Element element = (Element) inits.get(0).getValue().getSymbol();
      if (ElementKind.of(element).equals(ElementKind.CONSTRUCTOR)) {
        ConstructorElement nextConstructorElement = (ConstructorElement) element;
        ClassElement nextClass = (ClassElement) nextConstructorElement.getEnclosingElement();
        ClassElement currentClass = (ClassElement) constructor.getEnclosingElement();
        if (nextClass.getName().equals(currentClass.getName())) {
          return nextConstructorElement;
        }
      }
    }
    return null;
  }
}
