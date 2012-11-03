// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.common.annotations.VisibleForTesting;
import com.google.common.collect.Lists;
import com.google.common.collect.Sets;
import com.google.dart.compiler.DartCompilationPhase;
import com.google.dart.compiler.DartCompilerContext;
import com.google.dart.compiler.ErrorCode;
import com.google.dart.compiler.ast.ASTNodes;
import com.google.dart.compiler.ast.ASTVisitor;
import com.google.dart.compiler.ast.DartArrayLiteral;
import com.google.dart.compiler.ast.DartBinaryExpression;
import com.google.dart.compiler.ast.DartBlock;
import com.google.dart.compiler.ast.DartBooleanLiteral;
import com.google.dart.compiler.ast.DartBreakStatement;
import com.google.dart.compiler.ast.DartCase;
import com.google.dart.compiler.ast.DartCatchBlock;
import com.google.dart.compiler.ast.DartClass;
import com.google.dart.compiler.ast.DartContinueStatement;
import com.google.dart.compiler.ast.DartDirective;
import com.google.dart.compiler.ast.DartDoWhileStatement;
import com.google.dart.compiler.ast.DartDoubleLiteral;
import com.google.dart.compiler.ast.DartExprStmt;
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
import com.google.dart.compiler.ast.DartMapLiteral;
import com.google.dart.compiler.ast.DartMethodDefinition;
import com.google.dart.compiler.ast.DartMethodInvocation;
import com.google.dart.compiler.ast.DartNamedExpression;
import com.google.dart.compiler.ast.DartNativeBlock;
import com.google.dart.compiler.ast.DartNewExpression;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.DartParameter;
import com.google.dart.compiler.ast.DartParameterizedTypeNode;
import com.google.dart.compiler.ast.DartPartOfDirective;
import com.google.dart.compiler.ast.DartPropertyAccess;
import com.google.dart.compiler.ast.DartRedirectConstructorInvocation;
import com.google.dart.compiler.ast.DartReturnStatement;
import com.google.dart.compiler.ast.DartStatement;
import com.google.dart.compiler.ast.DartStringInterpolation;
import com.google.dart.compiler.ast.DartStringLiteral;
import com.google.dart.compiler.ast.DartSuperConstructorInvocation;
import com.google.dart.compiler.ast.DartSuperExpression;
import com.google.dart.compiler.ast.DartSwitchMember;
import com.google.dart.compiler.ast.DartSwitchStatement;
import com.google.dart.compiler.ast.DartThisExpression;
import com.google.dart.compiler.ast.DartThrowExpression;
import com.google.dart.compiler.ast.DartTryStatement;
import com.google.dart.compiler.ast.DartTypeExpression;
import com.google.dart.compiler.ast.DartTypeNode;
import com.google.dart.compiler.ast.DartTypeParameter;
import com.google.dart.compiler.ast.DartUnaryExpression;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.ast.DartUnqualifiedInvocation;
import com.google.dart.compiler.ast.DartVariable;
import com.google.dart.compiler.ast.DartVariableStatement;
import com.google.dart.compiler.ast.DartWhileStatement;
import com.google.dart.compiler.ast.Modifiers;
import com.google.dart.compiler.common.HasSourceInfo;
import com.google.dart.compiler.common.SourceInfo;
import com.google.dart.compiler.parser.Token;
import com.google.dart.compiler.resolver.LabelElement.LabeledStatementType;
import com.google.dart.compiler.type.InterfaceType;
import com.google.dart.compiler.type.InterfaceType.Member;
import com.google.dart.compiler.type.Type;
import com.google.dart.compiler.type.TypeAnalyzer;
import com.google.dart.compiler.type.TypeKind;
import com.google.dart.compiler.type.TypeQuality;
import com.google.dart.compiler.type.TypeVariable;
import com.google.dart.compiler.type.Types;

import java.util.EnumSet;
import java.util.Iterator;
import java.util.List;
import java.util.Set;
/**
 * Resolves unqualified elements in a compilation unit.
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
  public void resolveMember(ClassNodeElement classElement, NodeElement member, ResolutionContext context) {
    ResolveElementsVisitor visitor;
    if(member == null) {
      return;
    }
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
        throw topLevelContext.internalError(member,
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
    private EnclosingElement enclosingElement;
    private MethodElement currentMethod;
    private boolean inInstanceVariableInitializer;
    private boolean inInitializer;
    private MethodElement innermostFunction;
    private ResolutionContext context;
    private Set<LabelElement> referencedLabels = Sets.newHashSet();
    private Set<LabelElement> labelsInScopes = Sets.newHashSet();
    private Set<FieldElement> finalsNeedingInitializing = Sets.newHashSet();
    private Set<FieldElement> resolvedFields = Sets.newHashSet();

    @VisibleForTesting
    public ResolveElementsVisitor(ResolutionContext context,
                                  EnclosingElement currentHolder,
                                  MethodElement currentMethod) {
      super(typeProvider);
      this.context = context;
      this.currentMethod = currentMethod;
      this.innermostFunction = currentMethod;
      this.currentHolder = currentHolder;
      this.enclosingElement = currentHolder;
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
    protected EnclosingElement getEnclosingElement() {
      return enclosingElement;
    }

    @Override
    public Element visitUnit(DartUnit unit) {
      for (DartDirective directive : unit.getDirectives()) {
        if (directive instanceof DartPartOfDirective) {
          directive.accept(this);
        }
      }
      for (DartNode node : unit.getTopLevelNodes()) {
        node.accept(this);
      }
      checkRedirectingFactoryConstructorsCycle(unit);
      return null;
    }

    private void checkRedirectingFactoryConstructorsCycle(DartUnit unit) {
      unit.accept(new ASTVisitor<Void>() {
        @Override
        public Void visitMethodDefinition(DartMethodDefinition node) {
          MethodNodeElement element = node.getElement();
          if (ElementKind.of(element) == ElementKind.CONSTRUCTOR) {
            ConstructorElement constructor = (ConstructorElement) element;
            if (hasRedirectingFactoryConstructorCycle(constructor)) {
              onError(constructor.getNameLocation(),
                  ResolverErrorCode.REDIRECTION_CONSTRUCTOR_CYCLE);
            }
          }
          return super.visitMethodDefinition(node);
        }
      });
    }
    
    private boolean hasRedirectingFactoryConstructorCycle(ConstructorElement element) {
      Set<ConstructorElement> constructors = Sets.newHashSet();
      while (element != null) {
        if (constructors.contains(element)) {
          return true;
        }
        constructors.add(element);
        element = element.getRedirectingFactoryConstructor();
      }
      return false;
    }
    
    @Override
    public Element visitFunctionTypeAlias(DartFunctionTypeAlias alias) {
      alias.getMetadata().accept(this);
      getContext().pushFunctionAliasScope(alias);
      resolveFunctionAlias(alias);

      getContext().pushScope("<parameters>");
      try {
        List<DartParameter> parameters = alias.getParameters();
        for (DartParameter parameter : parameters) {
          assert parameter.getElement() != null;
          if (parameter.getQualifier() instanceof DartThisExpression) {
            onError(parameter.getName(), ResolverErrorCode.PARAMETER_INIT_OUTSIDE_CONSTRUCTOR);
          } else {
            if (DartIdentifier.isPrivateName(parameter.getElement().getName())) {
              if (parameter.getModifiers().isOptional()) {
                onError(parameter.getName(),
                    ResolverErrorCode.OPTIONAL_PARAMETERS_CANNOT_START_WITH_UNDER);
              }
              if (parameter.getModifiers().isNamed()) {
                onError(parameter.getName(),
                    ResolverErrorCode.NAMED_PARAMETERS_CANNOT_START_WITH_UNDER);
              }
            }
            getContext().declare(parameter.getElement(), ResolverErrorCode.DUPLICATE_PARAMETER);
          }
        }
      } finally {
        getContext().popScope();
      }

      getContext().popScope();
      return null;
    }

    @Override
    public Element visitClass(DartClass cls) {
      assert currentMethod == null : "nested class?";
      ClassNodeElement classElement = cls.getElement();
      try {
        classElement.getAllSupertypes();
      } catch (CyclicDeclarationException e) {
        HasSourceInfo errorTarget = e.getElement();
        if (errorTarget == null) {
          errorTarget = cls;
        }
        onError(errorTarget, ResolverErrorCode.CYCLIC_CLASS, e.getElement().getName());
      }
      checkClassTypeVariables(classElement);
      cls.getMetadata().accept(this);

      // Push new resolution context.
      ResolutionContext previousContext = context;
      EnclosingElement previousHolder = currentHolder;
      EnclosingElement previousEnclosingElement = enclosingElement;
      currentHolder = classElement;
      enclosingElement = classElement;
      context = topLevelContext.extend(classElement);

      // members
      this.finalsNeedingInitializing.clear();
      for (DartNode member : cls.getMembers()) {
        if (ElementKind.of(member.getElement()) == ElementKind.CONSTRUCTOR) {
          continue;
        }
        member.accept(this);
      }

      // constructors
      boolean testForAllConstantFields = false;
      for (DartNode member : cls.getMembers()) {
        if (member instanceof DartMethodDefinition) {
          DartMethodDefinition method = (DartMethodDefinition) member;
          if (method.getElement().isConstructor()) {
            method.accept(this);
            if (method.getModifiers().isConstant()) {
              testForAllConstantFields = true;
            }
          }
        }
      }

      if (testForAllConstantFields) {
        InterfaceType interfaceType = classElement.getType();
        while (interfaceType != null && interfaceType != typeProvider.getObjectType()) {
          ClassElement interfaceElement = interfaceType.getElement();
          constVerifyMembers(interfaceElement.getMembers(), classElement, interfaceElement);
          interfaceType = interfaceElement.getSupertype();
        }
      }

      checkRedirectConstructorCycle(classElement.getConstructors(), context);
      if (Elements.needsImplicitDefaultConstructor(classElement)) {
        checkImplicitDefaultDefaultSuperInvocation(cls, classElement);
      }

      if (cls.getDefaultClass() != null && classElement.getDefaultClass() == null) {
        onError(cls.getDefaultClass(), ResolverErrorCode.NO_SUCH_TYPE, cls.getDefaultClass());
      } else if (classElement.getDefaultClass() != null) {
        recordElement(cls.getDefaultClass().getExpression(),
                      classElement.getDefaultClass().getElement());
        bindDefaultTypeParameters(classElement.getDefaultClass().getElement().getTypeParameters(),
                                  cls.getDefaultClass().getTypeParameters(),
                                  context);

        // Make sure the 'default' clause matches the referenced class type parameters
        checkDefaultClassTypeParamsToDefaultDecl(classElement.getDefaultClass(),
                                                 cls.getDefaultClass());

        ClassElement defaultClass = classElement.getDefaultClass().getElement();
        if (defaultClass.isInterface()) {
          onError(cls.getDefaultClass().getExpression(),
              ResolverErrorCode.DEFAULT_MUST_SPECIFY_CLASS);
        }

        // Make sure the default class matches the interface type parameters
        checkInterfaceTypeParamsToDefault(classElement, defaultClass);
      }

      if (!classElement.isInterface() && Elements.needsImplicitDefaultConstructor(classElement)) {
        // Check to see that all final fields are initialized when no explicit
        // generative constructor is declared
        cls.accept(new ASTVisitor<DartNode>() {
          @Override
          public DartNode visitField(DartField node) {
            FieldElement fieldElement = node.getElement();
            if (fieldElement != null && fieldElement.getModifiers().isFinal()
                && !fieldElement.isStatic()
                && !fieldElement.getModifiers().isConstant()
                && !fieldElement.getModifiers().isGetter()
                && !fieldElement.getModifiers().isSetter()
                && !fieldElement.getModifiers().isInitialized()) {
              onError(node, ResolverErrorCode.FINAL_FIELD_MUST_BE_INITIALIZED,
                  fieldElement.getName());
            }
            return null;
          }
        });
      }

      context = previousContext;
      currentHolder = previousHolder;
      enclosingElement = previousEnclosingElement;
      return classElement;
    }

    private void constVerifyMembers(Iterable<? extends Element> members, ClassElement originalClass,
        ClassElement currentClass) {
      for (Element element : members) {
        Modifiers modifiers = element.getModifiers();
        if (ElementKind.of(element).equals(ElementKind.FIELD) && !modifiers.isFinal()
            && !modifiers.isStatic() && !modifiers.isAbstractField()) {
          FieldElement field = (FieldElement) element;
          HasSourceInfo errorNode = field.getSetter() == null ? element : field.getSetter();
          onError(errorNode, currentClass == originalClass
              ? ResolverErrorCode.CONST_CLASS_WITH_NONFINAL_FIELDS
              : ResolverErrorCode.CONST_CLASS_WITH_INHERITED_NONFINAL_FIELDS,
              originalClass.getName(), field.getName(), currentClass.getName());
        }
      }
    }

    /**
     * Sets the type in the AST of the default clause of an interface so that the type
     * parameters to resolve back to the default class.
     */
    private void bindDefaultTypeParameters(List<Type> parameterTypes,
                                           List<DartTypeParameter> parameterNodes,
                                           ResolutionContext classContext) {
      Iterator<? extends Type> typeIterator = parameterTypes.iterator();
      Iterator<DartTypeParameter> nodeIterator = parameterNodes.iterator();

      while(typeIterator.hasNext() && nodeIterator.hasNext()) {

        Type type = typeIterator.next();
        DartTypeParameter node = nodeIterator.next();

        if (type.getElement().getName().equals(node.getName().getName())) {
          node.setType(type);
          recordElement(node.getName(), type.getElement());
        } else {
          node.setType(typeProvider.getDynamicType());
        }

        DartTypeNode boundNode = node.getBound();
        if (boundNode != null) {
          Type bound =
              classContext.resolveType(
                  boundNode,
                  false,
                  false,
                  false,
                  ResolverErrorCode.NO_SUCH_TYPE,
                  ResolverErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS);
          boundNode.setType(bound);
        }
      }

      while (nodeIterator.hasNext()) {
        DartTypeParameter node = nodeIterator.next();
        node.setType(typeProvider.getDynamicType());
      }
    }
    /**
     * If type parameters are present, the type parameters of the default statement
     * must exactly match those of those declared in the class it references.
     *
     */
    private void checkDefaultClassTypeParamsToDefaultDecl(InterfaceType defaultClassType,
                                                          DartParameterizedTypeNode defaultClassRef) {
      if (defaultClassRef.getTypeParameters().isEmpty()) {
        return;
      }
      ClassElement defaultClassElement = defaultClassType.getElement();
      boolean match = true;
      if (defaultClassElement.getTypeParameters().isEmpty()) {
        match = false;
      } else {
        // TODO(zundel): This is effective in catching mistakes, but highlights the entire type
        // expression - A more specific indication of where the error started might be appreciated.
        String defaultClassSource = defaultClassElement.getDeclarationNameWithTypeParameters();
        String refSource = defaultClassRef.toSource();
        if (!refSource.equals(defaultClassSource)) {
          match = false;
        }
      }
      if (!match) {
        // TODO(zundel): work harder to point out where the type param match failure starts.
        onError(defaultClassRef, ResolverErrorCode.TYPE_PARAMETERS_MUST_MATCH_EXACTLY);
      }
    }

    private void checkInterfaceTypeParamsToDefault(ClassElement interfaceElement,
                                                   ClassElement defaultClassElement) {

      List<Type> interfaceTypeParams = interfaceElement.getTypeParameters();

      List<Type> defaultTypeParams = defaultClassElement.getTypeParameters();


      if (defaultTypeParams.size() != interfaceTypeParams.size()) {

        onError(interfaceElement.getNameLocation(),
                ResolverErrorCode.DEFAULT_CLASS_MUST_HAVE_SAME_TYPE_PARAMS);
      } else {
        Iterator<? extends Type> interfaceIterator = interfaceTypeParams.iterator();
        Iterator<? extends Type> defaultIterator = defaultTypeParams.iterator();
        while (interfaceIterator.hasNext()) {
          Type iVar = interfaceIterator.next();
          Type dVar = defaultIterator.next();
          String iVarName = iVar.getElement().getName();
          String dVarName = dVar.getElement().getName();
          if (!iVarName.equals(dVarName)) {
            onError(iVar.getElement(), ResolverErrorCode.TYPE_VARIABLE_DOES_NOT_MATCH,
                    iVarName, dVarName, defaultClassElement.getName());
          }
        }
      }
    }

    /**
     * Check that used type variables are unique and don't shadow and existing elements.
     */
    private void checkClassTypeVariables(ClassElement classElement) {
      Set<String> declaredVariableNames = Sets.newHashSet();
      for (Type type : classElement.getTypeParameters()) {
        if (type instanceof TypeVariable) {
          Element typeVariableElement = type.getElement();
          String name = typeVariableElement.getName();
          // Check that type variables are unique in this Class  declaration.
          if (declaredVariableNames.contains(name)) {
            onError(typeVariableElement, ResolverErrorCode.DUPLICATE_TYPE_VARIABLE, name);
          } else {
            declaredVariableNames.add(name);
          }
        }
      }
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
          boolean superHasDefaultCtor =
              (superCtor != null && superCtor.getParameters().isEmpty())
                  || (superCtor == null && Elements.needsImplicitDefaultConstructor(superElement));
          if (!superHasDefaultCtor) {
            onError(cls.getName(),
                ResolverErrorCode.CANNOT_RESOLVE_IMPLICIT_CALL_TO_SUPER_CONSTRUCTOR,
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
    public Element visitTypeParameter(DartTypeParameter node) {
      node.getMetadata().accept(this);
      return super.visitTypeParameter(node);
    }

    @Override
    public MethodElement visitMethodDefinition(DartMethodDefinition node) {
      node.getMetadata().accept(this);
      MethodElement member = node.getElement();
      ResolutionContext previousContext = context;
      context = context.extend(member.getName());
      assert currentMethod == null : "Nested methods?";
      innermostFunction = currentMethod = member;
      EnclosingElement previousEnclosingElement = enclosingElement;
      enclosingElement = member;

      DartFunction functionNode = node.getFunction();
      List<DartParameter> parameters = functionNode.getParameters();
      Set<FieldElement> initializedFields = Sets.newHashSet();
      
      // remember field with initializers
      if (previousEnclosingElement instanceof ClassElement) {
        ClassElement classElement = (ClassElement) previousEnclosingElement;
        for (Element classMember : classElement.getMembers()) {
          if (ElementKind.of(classMember) == ElementKind.FIELD) {
            FieldElement fieldMember = (FieldElement) classMember;
            if (fieldMember.getModifiers().isFinal() && fieldMember.getModifiers().isInitialized()) {
              initializedFields.add(fieldMember);
            }
          }
        }
      }

      // First declare all normal parameters in the scope, putting them in the
      // scope of the default expressions so we can report better errors.
      for (DartParameter parameter : parameters) {
        assert parameter.getElement() != null;
        parameter.getMetadata().accept(this);

        if (!(parameter.getQualifier() instanceof DartThisExpression)) {
          getContext().declare(
              parameter.getElement(),
              ResolverErrorCode.DUPLICATE_PARAMETER);
        }
      }
      for (DartParameter parameter : parameters) {
        // Then resolve the default values.
        resolve(parameter.getDefaultExpr());
        if (parameter.getQualifier() instanceof DartThisExpression && parameter.getElement() != null
            && !initializedFields.add(parameter.getElement().getParameterInitializerElement())) {
          onError(parameter, ResolverErrorCode.DUPLICATE_INITIALIZATION, parameter.getName());
        }
      }

      DartBlock body = functionNode.getBody();
      boolean isInterface = false;
      boolean isAbstractClass = false;
      if (ElementKind.of(member.getEnclosingElement()).equals(ElementKind.CLASS)) {
        ClassElement cl = (ClassElement) member.getEnclosingElement();
        isInterface = cl.isInterface();
        isAbstractClass = cl.getModifiers().isAbstract();
      }

      if (body == null) {
        if (member.getModifiers().isStatic() && !member.getModifiers().isExternal()) {
          onError(functionNode, ResolverErrorCode.STATIC_METHOD_MUST_HAVE_BODY);
        } else if (!Elements.isNonFactoryConstructor(member) && !member.getModifiers().isAbstract()
            && !member.getModifiers().isExternal() && node.getRedirectedTypeName() == null
            && !(isInterface || isAbstractClass)) {
          onError(functionNode, ResolverErrorCode.METHOD_MUST_HAVE_BODY);
        }
      }
      resolve(functionNode.getBody());

      if (Elements.isNonFactoryConstructor(member)
          && !(body instanceof DartNativeBlock)) {
        resolveInitializers(node, initializedFields);
      }

      // resolve redirecting factory constructor
      {
        DartTypeNode rcTypeName = node.getRedirectedTypeName();
        if (rcTypeName != null) {
          Type rcType = resolveType(rcTypeName, true, true, false,
              TypeErrorCode.NO_SUCH_TYPE, ResolverErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS);
          switch (TypeKind.of(rcType)) {
            case INTERFACE:
              ConstructorElement targetConstructor = null;
              Element element = recordType(rcTypeName, rcType);
              DartIdentifier rcName = node.getRedirectedConstructorName();
              if (rcName != null) {
                element = ((ClassElement) element).lookupConstructor(rcName.getName());
                switch (ElementKind.of(element)) {
                  case CONSTRUCTOR:
                    targetConstructor = (ConstructorElement) element;
                    recordElement(rcName, element);
                    if (member.getModifiers().isConstant() && !element.getModifiers().isConstant()) {
                      onError(rcName,
                          ResolverErrorCode.REDIRECTION_CONSTRUCTOR_TARGET_MUST_BE_CONST);
                    }
                    break;
                }
              } else {
                targetConstructor = ((ClassElement) element).lookupConstructor(element.getName());
              }
              Elements.setRedirectingFactoryConstructor(((ConstructorElement) member),
                  targetConstructor);
              break;
            default:
              onError(rcTypeName, ResolverErrorCode.REDIRECTION_CONSTRUCTOR_TARGET_TYPE);
          }
        }
      }

      context = previousContext;
      innermostFunction = currentMethod = null;
      enclosingElement = previousEnclosingElement;
      return member;
    }

    @Override
    public Element visitField(DartField node) {
      DartExpression expression = node.getValue();
      Modifiers modifiers = node.getModifiers();
      boolean isFinal = modifiers.isFinal();
      boolean isTopLevel = ElementKind.of(currentHolder).equals(ElementKind.LIBRARY);
      boolean isStatic = modifiers.isStatic();

      if (expression != null) {
        inInstanceVariableInitializer = !isTopLevel;
        try {
          resolve(expression);
        } finally {
          inInstanceVariableInitializer = false;
        }
        // Now, this constant has a type. Save it for future reference.
        Element element = node.getElement();
        Type expressionType = expression.getType();
        if (isFinal && expressionType != null && TypeKind.of(element.getType()) == TypeKind.DYNAMIC) {
          TypeQuality typeQuality = TypeAnalyzer.getTypeQuality(expression);
          Type fieldType = Types.makeInferred(expressionType, typeQuality);
          Elements.setType(element, fieldType);
        }
      } else if (isFinal) {
        if (modifiers.isConstant()) {
          onError(node, ResolverErrorCode.CONST_REQUIRES_VALUE);
        } else if (isStatic) {
          onError(node, ResolverErrorCode.STATIC_FINAL_REQUIRES_VALUE);
        } else if (isTopLevel) {
          onError(node, ResolverErrorCode.TOPLEVEL_FINAL_REQUIRES_VALUE);
        } else {
          // If a final instance field wasn't initialized at declaration, we must check
          // at construction time.
          this.finalsNeedingInitializing.add(node.getElement());
        }
      }

      // If field is an accessor, both getter and setter need to be visited (if present).
      // We check for duplicates because top-level fields are visited twice - for each accessor.
      FieldNodeElement field = node.getElement();
      if (!resolvedFields.contains(field)) {
        resolvedFields.add(field);
        if (field.getGetter() != null) {
          resolve(field.getGetter().getNode());
        }
        if (field.getSetter() != null) {
          resolve(field.getSetter().getNode());
        }
      }
      return null;
    }

    @Override
    public Element visitFieldDefinition(DartFieldDefinition node) {
      node.getMetadata().accept(this);
      visit(node.getFields());
      return null;
    }

    @Override
    public Element visitFunction(DartFunction node) {
      throw context.internalError(node, "should not be called.");
    }

    @Override
    public Element visitParameter(DartParameter x) {
      x.getMetadata().accept(this);
      Element element = super.visitParameter(x);
      resolve(x.getDefaultExpr());
      getContext().declare(
          element,
          ResolverErrorCode.DUPLICATE_PARAMETER);
      return element;
    }

    @Override
    public Element visitVariable(DartVariable node) {
      node.getMetadata().accept(this);
      return super.visitVariable(node);
    }

    public VariableElement resolveVariable(DartVariable x, Modifiers modifiers) {
      // Visit the initializer first.
      resolve(x.getValue());
      VariableElement element = Elements.variableElement(enclosingElement, x, x.getVariableName(), modifiers);
      getContext().declare(
          recordElement(x, element),
          ResolverErrorCode.DUPLICATE_LOCAL_VARIABLE_ERROR);
      recordElement(x.getName(), element);
      return element;
    }

    @Override
    public Element visitVariableStatement(DartVariableStatement node) {
      resolveVariableStatement(node, false);
      return null;
    }

    private void resolveVariableStatement(DartVariableStatement node,
                                          boolean isImplicitlyInitialized) {
      Type type =
          resolveType(
              node.getTypeNode(),
              ASTNodes.isStaticContext(node),
              ASTNodes.isFactoryContext(node),
              true,
              TypeErrorCode.NO_SUCH_TYPE,
              TypeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS);
      for (DartVariable variable : node.getVariables()) {
        String name = variable.getVariableName();
        getContext().getScope().removeDeclaredButNotReachedVariable(name);
        Elements.setType(resolveVariable(variable, node.getModifiers()), type);
        checkVariableStatement(node, variable, isImplicitlyInitialized);
      }
     }

    @Override
    public Element visitLabel(DartLabel x) {
      DartNode parent = x.getParent();
      if (!(parent instanceof DartSwitchMember && ((DartSwitchMember) parent).getLabels().contains(
          x))) {
        LabelElement labelElement;
        DartStatement childStatement = x.getStatement();
        while (childStatement instanceof DartLabel) {
          childStatement = ((DartLabel) childStatement).getStatement();
        }
        if (childStatement instanceof DartSwitchStatement) {
          labelElement = Elements.switchLabelElement(x, x.getName(), innermostFunction);
        } else {
          labelElement = Elements.statementLabelElement(x, x.getName(), innermostFunction);
        }
        recordElement(x.getLabel(), labelElement);
        recordElement(x, labelElement);
      }
      x.visitChildren(this);
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
      // record element
      if (x.getName() != null) {
        recordElement(x.getName(), element);
      }
      recordElement(x, element);
      // visit function
      MethodElement previousFunction = innermostFunction;
      innermostFunction = element;
      {
        DartFunction functionNode = x.getFunction();
        EnclosingElement previousEnclosingElement = enclosingElement;
        enclosingElement = element;
        getContext().pushFunctionScope(x);
        try {
          resolveFunction(functionNode, element);
          resolve(functionNode.getBody());
        } finally {
          getContext().popScope();
          enclosingElement = previousEnclosingElement;
        }
      }
      innermostFunction = previousFunction;
      getContext().popScope();
      return element;
    }

    @Override
    public Element visitBlock(DartBlock x) {
      getContext().pushScope("<block>");
      addLabelToStatement(x);
      // Remember names of Block variables.
      for (DartStatement statement : x.getStatements()) {
        if (statement instanceof DartVariableStatement) {
          DartVariableStatement node = (DartVariableStatement) statement;
          List<DartVariable> variables = node.getVariables();
          for (DartVariable variable : variables) {
            String name = variable.getVariableName();
            getContext().getScope().addDeclaredButNotReachedVariable(name);
          }
        }
      }
      // Visit statements.
      x.visitChildren(this);
      getContext().popScope();
      return null;
    }

    @Override
    public Element visitBreakStatement(DartBreakStatement x) {
      // Handle corner case of L: break L;
      DartNode parent = x.getParent();
      if (parent instanceof DartLabel && x.getLabel() != null) {
        if (((DartLabel) parent).getLabel().getName().equals(x.getLabel().getName())) {
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

      x.getIterable().accept(this);
      if (x.introducesVariable()) {
        resolveVariableStatement(x.getVariableStatement(), true);
      } else {
        x.getIdentifier().accept(this);
      }
      x.getBody().accept(this);
      getContext().popScope();
      return null;
    }

    private void addLabelToStatement(DartNode x) {
      DartNode parent = x.getParent();
      while (parent instanceof DartLabel) {
        DartLabel label = (DartLabel) parent;
        LabelElement currentLabel = label.getElement();
        getContext().getScope().addLabel(currentLabel);
        labelsInScopes.add(currentLabel);
        parent = parent.getParent();
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
      // The scope of a label on the case statement is the case statement itself. These labels
      // need to be resolved before the continue <label>; statements can be resolved.
      for (DartSwitchMember member : x.getMembers()) {
        recordSwitchMemberLabel(member);
      }
      x.visitChildren(this);
      getContext().popScope();
      return null;
    }

    @Override
    public Element visitCase(DartCase node) {
      super.visitCase(node);
      List<DartStatement> statements = node.getStatements();
      // the last statement should be: break, continue, return, throw
      if (!statements.isEmpty()) {
        DartStatement lastStatement = statements.get(statements.size() - 1);
        if (!isValidLastSwitchCaseStatement(lastStatement)) {
          onError(lastStatement, ResolverErrorCode.SWITCH_CASE_FALL_THROUGH);
        }
      }
      // done
      return null;
    }

    private boolean isValidLastSwitchCaseStatement(DartStatement statement) {
      if (statement instanceof DartExprStmt) {
        DartExprStmt exprStmt = (DartExprStmt) statement;
        if (exprStmt.getExpression() instanceof DartThrowExpression) {
          return true;
        }
      }
      return statement instanceof DartBreakStatement || statement instanceof DartContinueStatement
          || statement instanceof DartReturnStatement;
    }

    @Override
    public Element visitSwitchMember(DartSwitchMember x) {
      getContext().pushScope("<switch member>");
      x.visitChildren(this);
      getContext().popScope();
      return null;
    }

    private void recordSwitchMemberLabel(DartSwitchMember x) {
      List<DartLabel> labels = x.getLabels();
      for (DartLabel label : labels) {
        LabelElement labelElement =  Elements.switchMemberLabelElement(label, label.getName(),
            innermostFunction);
        recordElement(label.getLabel(), labelElement);
        recordElement(label, labelElement);
        if (getContext().getScope().hasLocalLabel(label.getName())) {
          onError(label, ResolverErrorCode.DUPLICATE_LABEL_IN_SWITCH_STATEMENT);
        }
        getContext().getScope().addLabel(labelElement);
        labelsInScopes.add(labelElement);
      }
    }

    @Override
    public Element visitThisExpression(DartThisExpression x) {
      if (ElementKind.of(currentHolder).equals(ElementKind.LIBRARY)) {
        onError(x, ResolverErrorCode.THIS_ON_TOP_LEVEL);
      } else if (currentMethod == null) {
        onError(x, ResolverErrorCode.THIS_OUTSIDE_OF_METHOD);
      } else if (currentMethod.getModifiers().isStatic()) {
        onError(x, ResolverErrorCode.THIS_IN_STATIC_METHOD);
      } else if (currentMethod.getModifiers().isFactory()) {
        onError(x, ResolverErrorCode.THIS_IN_FACTORY_CONSTRUCTOR);
      } else if (inInitializer) {
        onError(x, ResolverErrorCode.THIS_IN_INITIALIZER_AS_EXPRESSION);
      }
      return null;
    }

    @Override
    public Element visitDirective(DartDirective node) {
      node.getMetadata().accept(this);
      return super.visitDirective(node);
    }

    @Override
    public Element visitPartOfDirective(DartPartOfDirective node) {
      node.getMetadata().accept(this);
      String elementName = "__library_" + node.getLibraryName();
      Element element = context.getScope().findElement(null, elementName);
      if (ElementKind.of(element) == ElementKind.LIBRARY) {
        node.getName().setElement(element);
        return element;
      }
      return null;
    }

    @Override
    public Element visitSuperExpression(DartSuperExpression x) {
      if (ElementKind.of(currentHolder).equals(ElementKind.LIBRARY)) {
        onError(x, ResolverErrorCode.SUPER_ON_TOP_LEVEL);
      } else if (currentMethod == null) {
        onError(x, ResolverErrorCode.SUPER_OUTSIDE_OF_METHOD);
      } else if (currentMethod.getModifiers().isStatic()) {
        onError(x, ResolverErrorCode.SUPER_IN_STATIC_METHOD);
      } else if  (currentMethod.getModifiers().isFactory()) {
        onError(x, ResolverErrorCode.SUPER_IN_FACTORY_CONSTRUCTOR);
      } else {
        return recordElement(x, Elements.superElement(
            x, ((ClassElement) currentHolder).getSupertype().getElement()));
      }
      return null;
    }

    @Override
    public Element visitSuperConstructorInvocation(DartSuperConstructorInvocation x) {
      visit(x.getArguments());
      String name = x.getName() == null ? "" : x.getName().getName();
      InterfaceType supertype = ((ClassElement) currentHolder).getSupertype();
      ConstructorElement element;
      if (supertype == null) {
        element = null;
      } else {
        ClassElement classElement = supertype.getElement();
        element = Elements.lookupConstructor(classElement, name);
        if (element == null && "".equals(name) && x.getArguments().isEmpty()
            && Elements.needsImplicitDefaultConstructor(classElement)) {
          element = new SyntheticDefaultConstructorElement(null, classElement, typeProvider);
        }
      }
      if (element == null) {
        onError(x, ResolverErrorCode.CANNOT_RESOLVE_SUPER_CONSTRUCTOR, name);
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
      if (x.getParent() instanceof DartLabel) {
        return x.getElement();
      }
      Scope scope = getContext().getScope();
      String name = x.getName();
      Element element = scope.findElement(scope.getLibrary(), name);
      if (element == null) {
        element = scope.findElement(scope.getLibrary(), "setter " + name);
      }
      if (element == null) {
        // A private identifier could refer to a field in a different library. In this case
        // we want to provide a more useful error message in the type analyzer.
        if (DartIdentifier.isPrivateName(name)) {
          Element found = scope.findElement(null, name);
          if (found != null) {
            Element enclosingElement = found.getEnclosingElement();
            String referencedElementName = enclosingElement == null
                ? name : String.format("%s.%s", enclosingElement.getName(), name);
            onError(x, ResolverErrorCode.ILLEGAL_ACCESS_TO_PRIVATE_MEMBER,
                            name, referencedElementName);
          }
        }
        if (isStaticOrFactoryContextOrInitializer(x) && !isQualifier) {
          onError(x, ResolverErrorCode.CANNOT_BE_RESOLVED, name);
          x.markResolutionAlreadyReportedThatTheMethodCouldNotBeFound();
        }
      } else {
        element = checkResolvedIdentifier(x, isQualifier, scope, name, element);
      }
      
      if (ElementKind.of(element) == ElementKind.DUPLICATE) {
        DuplicateElement duplicateElement = (DuplicateElement) element;
        List<String> locations = duplicateElement.getLocations();
        onError(x, ResolverErrorCode.DUPLICATE_IMPORTED_NAME, element.getName(), locations.size(),
            locations);
        return null;
      }

      if (inInitializer && ElementKind.of(element) == ElementKind.FIELD) {
        if (!element.getModifiers().isStatic() && !Elements.isTopLevel(element)) {
          onError(x, ResolverErrorCode.CANNOT_ACCESS_FIELD_IN_INIT);
        }
      }

      // May be local variable declared in lexical scope, but its declaration is not visited yet.
      if (getContext().getScope().isDeclaredButNotReachedVariable(name)) {
        onError(x, ResolverErrorCode.USING_LOCAL_VARIABLE_BEFORE_DECLARATION, x);
      }

      if (!isQualifier) {
        switch (ElementKind.of(element)) {
          case FUNCTION_TYPE_ALIAS:
            onError(x, ResolverErrorCode.CANNOT_USE_TYPE, name);
            break;
          case TYPE_VARIABLE:
            onError(x, ResolverErrorCode.CANNOT_USE_TYPE_VARIABLE, name);
            break;
          case DUPLICATE:
            DuplicateElement duplicateElement = (DuplicateElement) element;
            List<String> locations = duplicateElement.getLocations();
            onError(x, ResolverErrorCode.DUPLICATE_IMPORTED_NAME, element.getName(),
                locations.size(), locations);
            return null;
        }
      }

      // If we we haven't resolved the identifier, it will be normalized to
      // this.<identifier>.

      return recordElement(x, element);
    }

    /**
     * Possibly recursive check on the resolved identifier.
     */
    private Element checkResolvedIdentifier(DartIdentifier x, boolean isQualifier, Scope scope,
                                            String name, Element element) {
      switch (element.getKind()) {
        case FIELD:
          if (!Elements.isStaticContext(element) && !element.getModifiers().isConstant()) {
            if (inInstanceVariableInitializer) {
              onError(x, ResolverErrorCode.CANNOT_USE_INSTANCE_FIELD_IN_INSTANCE_FIELD_INITIALIZER);
            }
          }
          if (ASTNodes.isStaticContext(x) && !Elements.isStaticContext(element)) {
            onError(x, ResolverErrorCode.ILLEGAL_FIELD_ACCESS_FROM_STATIC, name);
          }
          if (isIllegalPrivateAccess(x, enclosingElement, element, x.getName())) {
            return null;
          }
          break;
        case METHOD:
          if (ASTNodes.isStaticContext(x) && !Elements.isStaticContext(element)) {
            onError(x, ResolverErrorCode.ILLEGAL_METHOD_ACCESS_FROM_STATIC,
                name);
          }
          if (isIllegalPrivateAccess(x, enclosingElement, element, x.getName())) {
            return null;
          }
          if (!element.getModifiers().isStatic() && !Elements.isTopLevel(element)) {
            if (referencedFromInitializer(x)) {
              onError(x, ResolverErrorCode.INSTANCE_METHOD_FROM_INITIALIZER);
            }
          }
          break;
        case CLASS:
          if (!isQualifier) {
            return typeProvider.getTypeType().getElement();
          }
          break;
        case TYPE_VARIABLE:
          // Type variables are not legal in identifier expressions, but the type variable
          // may be hiding a class element.
          LibraryElement libraryElement = scope.getLibrary();
          Scope libraryScope = libraryElement.getScope();
          // dip again at the library level.
          element = libraryScope.findElement(libraryElement, name);
          if (element == null) {
            onError(x, ResolverErrorCode.TYPE_VARIABLE_NOT_ALLOWED_IN_IDENTIFIER);
          } else {
            return checkResolvedIdentifier(x, isQualifier, libraryScope, name, element);
          }
          break;
        default:
          break;
      }
      return element;
    }

    @Override
    public Element visitTypeNode(DartTypeNode x) {
      // prepare ErrorCode, depends on the context
      ErrorCode errorCode = ResolverErrorCode.NO_SUCH_TYPE;
      ErrorCode wrongNumberErrorCode = ResolverErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS;
      {
        DartNode p = x.getParent();
        if (p instanceof DartTypeExpression) {
          DartTypeExpression typeExpression = (DartTypeExpression) p;
          if (typeExpression.getTypeNode() == x) {
            DartNode pp = p.getParent();
            if (pp instanceof DartBinaryExpression) {
              Token operator = ((DartBinaryExpression) pp).getOperator();
              if (operator == Token.AS || operator == Token.IS) {
                errorCode = TypeErrorCode.NO_SUCH_TYPE;
              }
            }
          }
        }
      }
      // do Type resolve
      return resolveType(x, ASTNodes.isStaticContext(x), ASTNodes.isFactoryContext(x), false,
          errorCode, wrongNumberErrorCode).getElement();
    }

    @Override
    public Element visitPropertyAccess(DartPropertyAccess x) {
      Element qualifier = resolveQualifier(x.getRealTarget());
      Element element = null;
      switch (ElementKind.of(qualifier)) {
        case CLASS:
          // Must be a static field.
          element = Elements.findElement(((ClassElement) qualifier), x.getPropertyName());
          if (element == null) {
            element = Elements.findElement(((ClassElement) qualifier), "setter " + x.getPropertyName());
          }
          if (isIllegalPrivateAccess(x.getName(), qualifier, element, x.getPropertyName())) {
            // break;
            return null;
          }
          switch (ElementKind.of(element)) {
            case FIELD:
              FieldElement field = (FieldElement) element;
              x.setType(field.getType());
              if (!field.getModifiers().isStatic()) {
                onError(x.getName(), ResolverErrorCode.NOT_A_STATIC_FIELD,
                    x.getPropertyName());
              }
              if (ASTNodes.inSetterContext(x)) {
                if (field.getGetter() != null) {
                  if (field.getSetter() == null) {
                    onError(x.getName(), ResolverErrorCode.FIELD_DOES_NOT_HAVE_A_SETTER);
                  }
                }
              }
              if (ASTNodes.inGetterContext(x)) {
                if (field.getSetter() != null) {
                  if (field.getGetter() == null) {
                    onError(x.getName(), ResolverErrorCode.FIELD_DOES_NOT_HAVE_A_GETTER);
                  }
                }
              }
              break;

            case NONE:
              x.getName().markResolutionAlreadyReportedThatTheMethodCouldNotBeFound();
              onError(x.getName(), TypeErrorCode.CANNOT_BE_RESOLVED,
                  x.getPropertyName());
              break;

            case METHOD:
              MethodElement method = (MethodElement) element;
              if (!method.getModifiers().isStatic()) {
                onError(x.getName(), ResolverErrorCode.NOT_A_STATIC_METHOD,
                    x.getPropertyName());
              }
              break;

            default:
              onError(x.getName(), ResolverErrorCode.EXPECTED_STATIC_FIELD,
                  element.getKind());
              break;
          }
          break;

        case SUPER:
          if (isIllegalPrivateAccess(x.getName(), qualifier, element, x.getPropertyName())) {
            return null;
          }
          ClassElement cls = ((SuperElement) qualifier).getClassElement();
          Member member = cls.getType().lookupMember(x.getPropertyName());
          if (member != null) {
            element = member.getElement();
          }
          switch (ElementKind.of(element)) {
            case FIELD:
              FieldElement field = (FieldElement) element;
              if (field.getModifiers().isStatic()) {
                onError(x.getName(), ResolverErrorCode.NOT_AN_INSTANCE_FIELD,
                  x.getPropertyName());
              }
              break;
            case METHOD:
              MethodElement method = (MethodElement) element;
              if (method.isStatic()) {
                onError(x.getName(), ResolverErrorCode.NOT_AN_INSTANCE_FIELD,
                  x.getPropertyName());
              }
              break;

            case NONE:
              onError(x.getName(), TypeErrorCode.CANNOT_BE_RESOLVED,
                  x.getPropertyName());
              break;

            default:
              onError(x.getName(),
                ResolverErrorCode.EXPECTED_AN_INSTANCE_FIELD_IN_SUPER_CLASS,
                element.getKind());
              break;
          }
          break;

        case LIBRARY_PREFIX:
          // Library prefix, lookup the element in the referenced library.
          Scope scope = ((LibraryPrefixElement) qualifier).getScope();
          element = scope.findElement(scope.getLibrary(), x.getPropertyName());
          if (element != null) {
            recordElement(x.getQualifier(), element.getEnclosingElement());
          } else {
            onError(x, ResolverErrorCode.CANNOT_BE_RESOLVED_LIBRARY,
                x.getPropertyName(), qualifier.getName());
          }
          break;

        case NONE: {
          // TODO(zundel): This is a bit awkward.  Maybe it would be better to have an
          // ElementKind of THIS just like we have for SUPER?
          if (x.getRealTarget() instanceof DartThisExpression) {
            Element foundElement = Elements.findElement(currentHolder, x.getPropertyName());
            if (foundElement != null && !foundElement.getModifiers().isStatic()) {
              if (ElementKind.of(foundElement) == ElementKind.TYPE_VARIABLE) {
                onError(x.getRealTarget(), ResolverErrorCode.TYPE_VARIABLE_NOT_ALLOWED_IN_IDENTIFIER);
                break;
              }
              element = foundElement;
            }
          }
        }

        default:
          break;
      }
      if (ElementKind.of(element) == ElementKind.DUPLICATE) {
        DuplicateElement duplicateElement = (DuplicateElement) element;
        List<String> locations = duplicateElement.getLocations();
        onError(x.getName(), ResolverErrorCode.DUPLICATE_IMPORTED_NAME, duplicateElement.getName(),
            locations.size(), locations);
        return null;
      }
      return recordElement(x, element);
    }

    private boolean isIllegalPrivateAccess(DartNode diagnosticNode, Element qualifier,
        Element element, String name) {
      if (DartIdentifier.isPrivateName(name)) {
        if (element == null) {
          element = getContext().getScope().findElement(null, name);
        }
        if (element != null) {
          Element enclosingLibrary = Elements.getLibraryElement(enclosingElement);
          Element identifierEnclosingLibrary = Elements.getLibraryElement(element);
          if (!enclosingLibrary.equals(identifierEnclosingLibrary)) {
            onError(diagnosticNode, ResolverErrorCode.ILLEGAL_ACCESS_TO_PRIVATE, name);
            return true;
          }
        }
      }
      return false;
    }

    private Element resolveQualifier(DartNode qualifier) {
      if (qualifier == null) {
        return null;
      }
      return (qualifier instanceof DartIdentifier)
          ? resolveIdentifier((DartIdentifier) qualifier, true)
          : qualifier.accept(this);
    }

    @Override
    public Element visitMethodInvocation(DartMethodInvocation x) {
      DartIdentifier name = x.getFunctionName();
      Element target = resolveQualifier(x.getRealTarget());
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
            diagnoseErrorInMethodInvocation(x, classElement, element);
          } else {
            if (isIllegalPrivateAccess(x.getFunctionName(), target, element,
                x.getFunctionNameString())) {
              break;
            }
          }
          break;
        }

        case SUPER: {
          if (x.getParent() instanceof DartInitializer) {
            onError(x, ResolverErrorCode.SUPER_METHOD_INVOCATION_IN_CONSTRUCTOR_INITIALIZER);
          }
          // Must be a superclass' method or field.
          ClassElement classElement = ((SuperElement) target).getClassElement();
          InterfaceType type = classElement.getType();
          Member member = type.lookupMember(x.getFunctionNameString());
          if (member != null) {
            if (!member.getElement().getModifiers().isStatic()) {
              element = member.getElement();
              // Must be accessible.
              if (!Elements.isAccessible(context.getScope().getLibrary(), element)) {
                name.markResolutionAlreadyReportedThatTheMethodCouldNotBeFound();
                onError(name, ResolverErrorCode.CANNOT_ACCESS_METHOD, x.getFunctionNameString());
              }
            }
          }
          break;
        }

        case LIBRARY_PREFIX:
          // Library prefix, lookup the element in the reference library.
          LibraryPrefixElement library = ((LibraryPrefixElement) target);
          element = library.getScope().findElement(context.getScope().getLibrary(),
                                                   x.getFunctionNameString());
          if (element == null) {
            diagnoseErrorInMethodInvocation(x, library, null);
          } else {
            recordElement(x.getTarget(), element.getEnclosingElement());
            name.setElement(element);
          }
          break;
      }

      checkInvocationTarget(x, currentMethod, target);
      visit(x.getArguments());
      if (name != null) {
        recordElement(name, element);
      }
      return recordElement(x, element);
    }

    @Override
    public Element visitUnqualifiedInvocation(DartUnqualifiedInvocation x) {
      Scope scope = getContext().getScope();
      Element element = scope.findElement(scope.getLibrary(), x.getTarget().getName());
      if (element == null) {
        element = scope.findElement(scope.getLibrary(), "setter " + x.getTarget().getName());
      }
      ElementKind kind = ElementKind.of(element);
      if (kind == ElementKind.DUPLICATE) {
        DuplicateElement duplicateElement = (DuplicateElement) element;
        List<String> locations = duplicateElement.getLocations();
        onError(x.getTarget(), ResolverErrorCode.DUPLICATE_IMPORTED_NAME, element.getName(),
            locations.size(), locations);
        return null;
      } else if (!INVOKABLE_ELEMENTS.contains(kind)) {
        diagnoseErrorInUnqualifiedInvocation(x);
      } else {
        checkInvocationTarget(x, currentMethod, element);
      }
      if (Elements.isAbstractFieldWithoutGetter(element)) {
        String name = element.getName();
        if (isStaticOrFactoryContextOrInitializer(x)) {
          onError(x.getTarget(), ResolverErrorCode.USE_ASSIGNMENT_ON_SETTER, name);
        } else {
          onError(x.getTarget(), TypeErrorCode.USE_ASSIGNMENT_ON_SETTER, name);
        }
      }
      recordElement(x, element);
      recordElement(x.getTarget(), element);
      visit(x.getArguments());
      return null;
    }

    @Override
    public Element visitFunctionObjectInvocation(DartFunctionObjectInvocation x) {
      x.getTarget().accept(this);
      visit(x.getArguments());
      return null;
    }

    @Override
    public Element visitNewExpression(final DartNewExpression x) {
      this.visit(x.getArguments());

      Element element = x.getConstructor().accept(getContext().new Selector() {
        // Only 'new' expressions can have a type in a property access.
        @Override
        public Element visitTypeNode(DartTypeNode type) {
          ErrorCode errorCode = x.isConst() ? ResolverErrorCode.NO_SUCH_TYPE_CONST : TypeErrorCode.NO_SUCH_TYPE;
          return recordType(type, resolveType(type, ASTNodes.isStaticContext(x),
                                              ASTNodes.isFactoryContext(x),
                                              false,
                                              errorCode,
                                              ResolverErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS));
        }

        @Override public Element visitPropertyAccess(DartPropertyAccess node) {
          Element element = node.getQualifier().accept(this);
          if (ElementKind.of(element).equals(ElementKind.CLASS)) {
            assert node.getQualifier() instanceof DartTypeNode;
            recordType(node, node.getQualifier().getType());
            return Elements.lookupConstructor(((ClassElement) element), node.getPropertyName());
          } else {
            return null;
          }
        }
      });


      switch (ElementKind.of(element)) {
        case DYNAMIC:
          return null;
        case CLASS:
        // Check for default constructor.
        ClassElement classElement = (ClassElement) element;
        element = Elements.lookupConstructor(classElement, "");
        // If no default constructor, may be use implicit default constructor.
        if (element == null
            && x.getArguments().isEmpty()
            && Elements.needsImplicitDefaultConstructor(classElement)) {
          element = new SyntheticDefaultConstructorElement(null, classElement, typeProvider);
        }
        break;
        case CONSTRUCTOR:
          if (enclosingElement != null) {
            Element enclosingLibrary = Elements.getLibraryElement(enclosingElement);
            Element constructorEnclosingLibrary = Elements.getLibraryElement(element);
            if (element != null && DartIdentifier.isPrivateName(element.getName())
                && !enclosingLibrary.equals(constructorEnclosingLibrary)) {
              onError(x.getConstructor(), ResolverErrorCode.ILLEGAL_ACCESS_TO_PRIVATE,
                  element.getName());
              return null;
            }
          }
        break;
        case TYPE_VARIABLE:
          onError(x.getConstructor(), ResolverErrorCode.NEW_EXPRESSION_CANT_USE_TYPE_VAR);
          return null;
        default:
          break;
      }

      // Will check that element is not null.
      ConstructorElement constructor = checkIsConstructor(x, element);

      // Check constructor.
      if (constructor != null) {
        boolean constConstructor = constructor.getModifiers().isConstant();
        // Check for using "const" to non-const constructor.
        if (x.isConst() && !constConstructor) {
          onError(x, ResolverErrorCode.CONST_AND_NONCONST_CONSTRUCTOR);
        }
        // Check for using "const" with type variables as type arguments.
        if (x.isConst() && constConstructor) {
          DartTypeNode typeNode = Types.constructorTypeNode(x);
          List<DartTypeNode> typeArguments = typeNode.getTypeArguments();
          for (DartTypeNode typeArgument : typeArguments) {
            if (typeArgument.getType() instanceof TypeVariable) {
              onError(typeArgument, ResolverErrorCode.CONST_WITH_TYPE_VARIABLE);
            }
          }
        }
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
          if (x instanceof DartBreakStatement
              && labelElement.getStatementType() == LabeledStatementType.SWITCH_MEMBER_STATEMENT) {
            onError(x.getLabel(), ResolverErrorCode.BREAK_LABEL_RESOLVES_TO_CASE_OR_DEFAULT);
            return null;
          }
          if (x instanceof DartContinueStatement
              && labelElement.getStatementType() == LabeledStatementType.SWITCH_STATEMENT) {
            onError(x.getLabel(), ResolverErrorCode.CONTINUE_LABEL_RESOLVES_TO_SWITCH);
            return null;
          }
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
        onError(x.getLabel(), ResolverErrorCode.CANNOT_RESOLVE_LABEL,
            x.getTargetName());
      } else if (ElementKind.of(element).equals(ElementKind.LABEL)) {
        onError(x.getLabel(), ResolverErrorCode.CANNOT_ACCESS_OUTER_LABEL,
            x.getTargetName());
      } else {
        onError(x.getLabel(), ResolverErrorCode.NOT_A_LABEL, x.getTargetName());
      }
    }

    private void diagnoseErrorInMethodInvocation(DartMethodInvocation node, Element classOrLibrary,
                                                 Element element) {
      String name = node.getFunctionNameString();
      ElementKind kind = ElementKind.of(element);
      DartNode errorNode = node.getFunctionName();
      switch (kind) {
        case NONE:
          switch (ElementKind.of(classOrLibrary)) {
            case CLASS:
              onError(errorNode, ResolverErrorCode.CANNOT_RESOLVE_METHOD_IN_CLASS, name,
                      classOrLibrary.getName());
              node.getFunctionName().markResolutionAlreadyReportedThatTheMethodCouldNotBeFound();
              break;
            case LIBRARY:
              onError(errorNode, ResolverErrorCode.CANNOT_RESOLVE_METHOD_IN_LIBRARY, name,
                      classOrLibrary.getName());
              break;
            default:
              onError(errorNode, ResolverErrorCode.CANNOT_RESOLVE_METHOD, name);
          }

          break;

        case CONSTRUCTOR:
          onError(errorNode, ResolverErrorCode.IS_A_CONSTRUCTOR, classOrLibrary.getName(),
              name);
          break;

        case METHOD: {
          assert !((MethodElement) element).getModifiers().isStatic();
          onError(errorNode, ResolverErrorCode.IS_AN_INSTANCE_METHOD,
              classOrLibrary.getName(), name);
          break;
        }

        case FIELD: {
          onError(errorNode, ResolverErrorCode.IS_AN_INSTANCE_FIELD,
              classOrLibrary.getName(), name);
          break;
        }

        default:
          throw context.internalError(errorNode, "Unexpected kind of element: %s", kind);
      }
    }

    private void diagnoseErrorInUnqualifiedInvocation(DartUnqualifiedInvocation node) {
      String name = node.getTarget().getName();
      Scope scope = getContext().getScope();
      Element element = scope.findElement(scope.getLibrary(), name);
      ElementKind kind = ElementKind.of(element);
      switch (kind) {
        case NONE:
          if (isStaticOrFactoryContextOrInitializer(node) || ASTNodes.isFactoryContext(node)) {
            node.getTarget().markResolutionAlreadyReportedThatTheMethodCouldNotBeFound();
            onError(node.getTarget(), ResolverErrorCode.CANNOT_RESOLVE_METHOD, name);
          }
          if (scope.findElement(null, name) != null) {
            node.getTarget().markResolutionAlreadyReportedThatTheMethodCouldNotBeFound();
            onError(node.getTarget(), ResolverErrorCode.CANNOT_ACCESS_METHOD, name);
          }
          break;

        case CONSTRUCTOR:
          onError(node, ResolverErrorCode.DID_YOU_MEAN_NEW, name, "constructor");
          break;

        case CLASS:
          onError(node, ResolverErrorCode.DID_YOU_MEAN_NEW, name, "class");
          break;

        case TYPE_VARIABLE:
          onError(node, ResolverErrorCode.DID_YOU_MEAN_NEW, name, "type variable");
          break;

        case FUNCTION_TYPE_ALIAS:
          onError(node, ResolverErrorCode.CANNOT_CALL_FUNCTION_TYPE_ALIAS);
          break;

        case LIBRARY_PREFIX:
          onError(node, ResolverErrorCode.CANNOT_CALL_LIBRARY_PREFIX);
          break;

        default:
          throw context.internalError(node, "Unexpected kind of element: %s", kind);
      }
    }

    private void diagnoseErrorInInitializer(DartIdentifier x) {
      String name = x.getName();
      Scope scope = getContext().getScope();
      Element element = scope.findElement(scope.getLibrary(), name);
      ElementKind kind = ElementKind.of(element);
      switch (kind) {
        case NONE:
          onError(x, ResolverErrorCode.CANNOT_RESOLVE_FIELD, name);
          break;

        case FIELD:
          FieldElement field = (FieldElement) element;
          recordElement(x, field);
          if (field.isStatic()) {
            onError(x, ResolverErrorCode.CANNOT_INIT_STATIC_FIELD_IN_INITIALIZER);
          } else if (field.getModifiers().isAbstractField()) {
            /*
             * If we get here then we know that this is a property accessor and not a true field.
             * If there was a field and property accessor with the same name a name collision error
             * would keep us from reaching this point.
             */
            onError(x, ResolverErrorCode.CANNOT_INIT_STATIC_FIELD_IN_INITIALIZER);
          } else {
            onError(x, ResolverErrorCode.INIT_FIELD_ONLY_IMMEDIATELY_SURROUNDING_CLASS);
          }
          break;

        case METHOD:
          onError(x, ResolverErrorCode.EXPECTED_FIELD_NOT_METHOD, name);
          break;

        case CLASS:
          onError(x, ResolverErrorCode.EXPECTED_FIELD_NOT_CLASS, name);
          break;

        case PARAMETER:
          onError(x, ResolverErrorCode.EXPECTED_FIELD_NOT_PARAMETER, name);
          break;

        case TYPE_VARIABLE:
          onError(x, ResolverErrorCode.EXPECTED_FIELD_NOT_TYPE_VAR, name);
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
            (ClassElement) currentHolder, x.getName().getName());
        if (element == null || element.isStatic() || element.getModifiers().isAbstractField()) {
          diagnoseErrorInInitializer(x.getName());
       }
        recordElement(x.getName(), element);
      }

      assert !inInitializer;
      DartExpression value = x.getValue();
      if (value == null) {
        return null;
      }
      inInitializer = true;
      Element element = value.accept(this);
      inInitializer = false;
      return element;
    }

    @Override
    public Element visitRedirectConstructorInvocation(DartRedirectConstructorInvocation x) {

      visit(x.getArguments());
      String name = x.getName() != null ? x.getName().getName() : "";
      ConstructorElement element = Elements.lookupConstructor((ClassElement) currentHolder, name);
      if (element == null) {
        onError(x, ResolverErrorCode.CANNOT_RESOLVE_CONSTRUCTOR, name);
      }
      return recordElement(x, element);
    }

    @Override
    public Element visitReturnStatement(DartReturnStatement x) {
      if (x.getValue() != null) {
        // Dart Spec v0.03, section 11.10.
        // Generative constructors cannot return arbitrary expressions in the form: 'return e;'
        // they can though have return statement in the form: 'return;'
        if ((currentMethod == innermostFunction)
            && Elements.isNonFactoryConstructor(currentMethod)) {
          onError(x, ResolverErrorCode.INVALID_RETURN_IN_CONSTRUCTOR);
        }
        return x.getValue().accept(this);
      }
      return null;
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
             topLevelContext.onError(node.getArg1(), ResolverErrorCode.CANNOT_ASSIGN_TO_FINAL,
                                     lhs.getName());
           }
           break;
         case METHOD:
            if (!lhs.getModifiers().isSetter() && !lhs.getModifiers().isGetter()) {
              topLevelContext.onError(node.getArg1(), ResolverErrorCode.CANNOT_ASSIGN_TO_METHOD,
                  lhs.getName());
            }
            if (lhs.getModifiers().isSetter()) {
              node.setElement(lhs);
            }
           break;
        }
      }

      return null;
    }

    @Override
    public Element visitUnaryExpression(DartUnaryExpression node) {
      DartExpression arg = node.getArg();
      Element argElement = resolve(arg);
      if (node.getOperator().isCountOperator()) {
        switch (ElementKind.of(argElement)) {
          case FIELD:
          case PARAMETER:
          case VARIABLE:
            if (argElement.getModifiers().isFinal()) {
              topLevelContext.onError(arg, ResolverErrorCode.CANNOT_ASSIGN_TO_FINAL,
                  argElement.getName());
            }
            break;
        }
      }
      if (node.getOperator() == Token.CONDITIONAL) {
        if (ElementKind.of(argElement) != ElementKind.PARAMETER) {
          onError(arg, ResolverErrorCode.FORMAL_PARAMETER_NAME_EXPECTED);
        }
      }
      return null;
    }

    @Override
    public Element visitMapLiteral(DartMapLiteral node) {
      List<DartTypeNode> originalTypeArgs = node.getTypeArguments();
      List<DartTypeNode> typeArgs = Lists.newArrayList();
      DartTypeNode implicitKey = new DartTypeNode(
          new DartIdentifier("String"));
      switch (originalTypeArgs.size()) {
        case 1:
          // Old (pre spec 0.11) map specification
          typeArgs.add(implicitKey);
          typeArgs.add(originalTypeArgs.get(0));
          // TODO(scheglov) enable this warning
//          topLevelContext.onError(originalTypeArgs.get(0), ResolverErrorCode.DEPRECATED_MAP_LITERAL_SYNTAX);
          break;
        case 2:
          typeArgs.add(originalTypeArgs.get(0));
          typeArgs.add(originalTypeArgs.get(1));
          break;
        default:
          topLevelContext.onError(node, ResolverErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS,
                                  defaultLiteralMapType,
                                  originalTypeArgs.size(), 1);
          // fall through
        case 0:
          typeArgs.add(implicitKey);
          DartTypeNode implicitValue = new DartTypeNode(new DartIdentifier("dynamic"));
          typeArgs.add(implicitValue);
          break;
      }

      InterfaceType type =
          context.instantiateParameterizedType(
              defaultLiteralMapType.getElement(),
              node,
              typeArgs,
              ASTNodes.isStaticContext(node),
              ASTNodes.isFactoryContext(node),
              ResolverErrorCode.NO_SUCH_TYPE,
              ResolverErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS);
      // instantiateParametersType() will complain for wrong number of parameters (!=2)
      if (node.isConst()) {
        checkTypeArgumentsInConstLiteral(typeArgs, ResolverErrorCode.CONST_MAP_WITH_TYPE_VARIABLE);
      }
      recordType(node, type);
      visit(node.getEntries());
      return null;
    }

    @Override
    public Element visitArrayLiteral(DartArrayLiteral node) {
      List<DartTypeNode> typeArgs = node.getTypeArguments();
      InterfaceType type =
          context.instantiateParameterizedType(
              rawArrayType.getElement(),
              node,
              typeArgs,
              ASTNodes.isStaticContext(node),
              ASTNodes.isFactoryContext(node),
              ResolverErrorCode.NO_SUCH_TYPE,
              ResolverErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS);
      // instantiateParametersType() will complain for wrong number of parameters (!=1)
      if (node.isConst()) {
        checkTypeArgumentsInConstLiteral(typeArgs, ResolverErrorCode.CONST_ARRAY_WITH_TYPE_VARIABLE);
      }
      recordType(node, type);
      visit(node.getExpressions());
      return null;
    }

    private void checkTypeArgumentsInConstLiteral(List<DartTypeNode> typeArgs, ErrorCode errorCode) {
      for (DartTypeNode typeNode : typeArgs) {
        Type type = typeNode.getType();
        if (type != null && type.getKind() == TypeKind.VARIABLE) {
          onError(typeNode, errorCode);
        }
      }
    }

    private ConstructorElement checkIsConstructor(DartNewExpression node, Element element) {
      if (!ElementKind.of(element).equals(ElementKind.CONSTRUCTOR)) {
        ResolverErrorCode errorCode = node.isConst()
            ? ResolverErrorCode.NEW_EXPRESSION_NOT_CONST_CONSTRUCTOR
            : ResolverErrorCode.NEW_EXPRESSION_NOT_CONSTRUCTOR;
        onError(ASTNodes.getConstructorNameNode(node), errorCode);
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
        if (superCall != null) {

          // Do positional parameters match?
          int superPositionalCount = Elements.getNumberOfRequiredParameters(superCall);
          if (superPositionalCount > 0) {
            onError(node, ResolverErrorCode.TOO_FEW_ARGUMENTS_IN_IMPLICIT_SUPER,
                superCall.getType().toString());
          }
        }
      }

      if (superCall == null
          && !currentClass.isObject()
          && !currentClass.isObjectChild()) {
        InterfaceType supertype = currentClass.getSupertype();
        if (supertype != null) {
          ClassElement superElement = supertype.getElement();
          if (superElement != null) {
            if (!hasDefaultConstructor(superElement)) {
              onError(node,
                  ResolverErrorCode.CANNOT_RESOLVE_IMPLICIT_CALL_TO_SUPER_CONSTRUCTOR,
                  superElement.getName());
            }
          }
        }
      } else if (superCall != null
          && node.getModifiers().isConstant()
          && !superCall.getModifiers().isConstant()) {
        onError(node.getName(),
            ResolverErrorCode.CONST_CONSTRUCTOR_MUST_CALL_CONST_SUPER);
      }
    }

    private void checkInvocationTarget(DartInvocation node,
                                       MethodElement callSite,
                                       Element target) {

      if (ElementKind.of(target).equals(ElementKind.METHOD)) {
        if (callSite != null && callSite.isStatic())
          if (!target.getModifiers().isStatic() && !Elements.isTopLevel(target)) {
            onError(node, ResolverErrorCode.INSTANCE_METHOD_FROM_STATIC);
          }
        if (!target.getModifiers().isStatic() && !Elements.isTopLevel(target)) {
          if (referencedFromRedirectConstructor(node)) {
            onError(node, ResolverErrorCode.INSTANCE_METHOD_FROM_REDIRECT);
          } else if (referencedFromInitializer(node)) {
            onError(node, ResolverErrorCode.INSTANCE_METHOD_FROM_INITIALIZER);
          }
        }
      }
    }

    private boolean referencedFromInitializer(DartNode node) {
      do {
        if (node instanceof DartInitializer) {
          return true;
        }
        node = node.getParent();
      } while (node != null);
      return false;
    }

    private boolean referencedFromRedirectConstructor(DartNode node) {
      do {
        if (node instanceof DartRedirectConstructorInvocation) {
          return true;
        }
        node = node.getParent();
      } while (node != null);
      return false;
    }

    private void checkVariableStatement(DartVariableStatement node,
                                        DartVariable variable,
                                        boolean isImplicitlyInitialized) {
      Modifiers modifiers = node.getModifiers();
      if (modifiers.isFinal()) {
        if (!isImplicitlyInitialized && (variable.getValue() == null)) {
          onError(variable.getName(), ResolverErrorCode.CONSTANTS_MUST_BE_INITIALIZED);
        } else if (modifiers.isStatic() && variable.getValue() != null) {
          resolve(variable.getValue());
          node.setType(variable.getValue().getType());
        }
      }
    }

    private void resolveInitializers(DartMethodDefinition node, Set<FieldElement> initializedFields) {
      Iterator<DartInitializer> initializers = node.getInitializers().iterator();
      ConstructorElement constructorElement = null;
      while (initializers.hasNext()) {
        DartInitializer initializer = initializers.next();
        Element element = resolve(initializer);
        if ((ElementKind.of(element) == ElementKind.CONSTRUCTOR) && initializer.isInvocation()) {
          constructorElement = (ConstructorElement) element;
        } else if (initializer.getName() != null && initializer.getName().getElement() != null
            && initializer.getName().getElement().getModifiers() != null
            && !initializedFields.add((FieldElement)initializer.getName().getElement())) {
          onError(initializer, ResolverErrorCode.DUPLICATE_INITIALIZATION, initializer.getName());
        }
      }

      // Look for final fields that are not initialized
      ClassElement classElement = (ClassElement)enclosingElement.getEnclosingElement();
      Element methodElement = node.getElement();
      if (classElement != null && methodElement != null
          && !classElement.isInterface()
          && !classElement.getModifiers().isNative()
          && !methodElement.getModifiers().isExternal()
          && !methodElement.getModifiers().isRedirectedConstructor()) {
        for (Element member : classElement.getMembers()) {
          switch (ElementKind.of(member)) {
            case FIELD:
              FieldElement fieldMember = (FieldElement)member;
              if (fieldMember.getModifiers().isFinal()
                  && !fieldMember.getModifiers().isInitialized()
                  && !initializedFields.contains(fieldMember)) {
                FieldNodeElement n = (FieldNodeElement)fieldMember;
                onError(n.getNode(), ResolverErrorCode.FINAL_FIELD_MUST_BE_INITIALIZED,
                    fieldMember.getName());
              }
          }
        }
      }

      checkConstructor(node, constructorElement);
    }

    private void onError(HasSourceInfo target, ErrorCode errorCode, Object... arguments) {
      context.onError(target, errorCode, arguments);
    }

    private void onError(SourceInfo target, ErrorCode errorCode, Object... arguments) {
      context.onError(target, errorCode, arguments);
    }

    boolean isStaticOrFactoryContextOrInitializer(DartNode x) {
      return ASTNodes.isStaticOrFactoryContext(x) || inInitializer;
    }
  }

  public static class Phase implements DartCompilationPhase {
    /**
     * Executes element resolution on the given compilation unit.
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

  private void checkRedirectConstructorCycle(List<ConstructorNodeElement> constructors,
                                             ResolutionContext context) {
    for (ConstructorNodeElement element : constructors) {
      if (hasRedirectedConstructorCycle(element)) {
        context.onError(element, ResolverErrorCode.REDIRECTED_CONSTRUCTOR_CYCLE);
      }
    }
  }

  private boolean hasRedirectedConstructorCycle(ConstructorNodeElement constructorElement) {
    Set<ConstructorNodeElement> visited = Sets.newHashSet();
    ConstructorNodeElement next = getNextConstructorInvocation(constructorElement);
    while (next != null) {
      if (visited.contains(next)) {
        return true;
      }
      if (constructorElement.getName().equals(next.getName())) {
        return true;
      }
      visited.add(next);
      next = getNextConstructorInvocation(next);
    }
    return false;
  }

  private ConstructorNodeElement getNextConstructorInvocation(ConstructorNodeElement constructor) {
    List<DartInitializer> inits = ((DartMethodDefinition) constructor.getNode()).getInitializers();
    // Parser ensures that redirected constructors can be the only item in the initialization list.
    if (inits.size() == 1) {
      DartExpression value = inits.get(0).getValue();
      if (value != null) {
        Element element = value.getElement();
        if (ElementKind.of(element).equals(ElementKind.CONSTRUCTOR)) {
          ConstructorElement nextConstructorElement = (ConstructorElement) element;
          ClassElement nextClass = (ClassElement) nextConstructorElement.getEnclosingElement();
          ClassElement currentClass = (ClassElement) constructor.getEnclosingElement();
          if (nextClass == currentClass) {
            return (ConstructorNodeElement) nextConstructorElement;
          }
        }
      }
    }
    return null;
  }
}
