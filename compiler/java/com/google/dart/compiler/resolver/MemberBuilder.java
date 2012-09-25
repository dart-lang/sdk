// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.common.annotations.VisibleForTesting;
import com.google.common.base.Objects;
import com.google.dart.compiler.DartCompilerContext;
import com.google.dart.compiler.ErrorCode;
import com.google.dart.compiler.ast.ASTVisitor;
import com.google.dart.compiler.ast.DartBlock;
import com.google.dart.compiler.ast.DartClass;
import com.google.dart.compiler.ast.DartExpression;
import com.google.dart.compiler.ast.DartField;
import com.google.dart.compiler.ast.DartFieldDefinition;
import com.google.dart.compiler.ast.DartFunction;
import com.google.dart.compiler.ast.DartFunctionTypeAlias;
import com.google.dart.compiler.ast.DartIdentifier;
import com.google.dart.compiler.ast.DartMethodDefinition;
import com.google.dart.compiler.ast.DartNativeBlock;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.DartParameter;
import com.google.dart.compiler.ast.DartParameterizedTypeNode;
import com.google.dart.compiler.ast.DartPropertyAccess;
import com.google.dart.compiler.ast.DartThisExpression;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.ast.Modifiers;
import com.google.dart.compiler.common.HasSourceInfo;
import com.google.dart.compiler.common.SourceInfo;
import com.google.dart.compiler.type.Type;
import com.google.dart.compiler.type.Types;
import com.google.dart.compiler.util.apache.StringUtils;

import java.util.ArrayList;
import java.util.List;

/**
 * Builds the method, field and constructor elements of classes and the library in a DartUnit.
 */
public class MemberBuilder {
  private ResolutionContext topLevelContext;
  private LibraryElement libraryElement;

  public void exec(DartUnit unit, DartCompilerContext context, CoreTypeProvider typeProvider) {
    Scope scope = unit.getLibrary().getElement().getScope();
    exec(unit, context, scope, typeProvider);
  }

  @VisibleForTesting
  public void exec(DartUnit unit, DartCompilerContext compilerContext, Scope scope,
                   CoreTypeProvider typeProvider) {
    libraryElement = unit.getLibrary().getElement();
    topLevelContext = new ResolutionContext(scope, compilerContext, typeProvider);
    unit.accept(new MemberElementBuilder(typeProvider));
  }

  /**
   * Creates elements for the fields, methods and constructors of a class. The
   * elements are added to the ClassElement.
   *
   * TODO(ngeoffray): Errors reported:
   *  - Duplicate member names in the same class.
   *  - Unresolved types.
   */
  private class MemberElementBuilder extends ResolveVisitor {
    EnclosingElement currentHolder;
    private EnclosingElement enclosingElement;
    private ResolutionContext context;
    private boolean isStatic;
    private boolean isFactory;

    MemberElementBuilder(CoreTypeProvider typeProvider) {
      super(typeProvider);
      context = topLevelContext;
      currentHolder = libraryElement;
    }

    @Override
    ResolutionContext getContext() {
      return context;
    }

    @Override
    boolean isStaticContext() {
      return isStatic;
    }

    @Override
    boolean isFactoryContext() {
      return isFactory;
    }

    @Override
    protected EnclosingElement getEnclosingElement() {
      return enclosingElement;
    }

    @Override
    public Element visitClass(DartClass node) {
      assert !ElementKind.of(currentHolder).equals(ElementKind.CLASS) : "nested class?";
      beginClassContext(node);
      ClassElement classElement = node.getElement();
      EnclosingElement previousEnclosingElement = enclosingElement;
      enclosingElement = classElement;
      // visit fields, to make their Elements ready for constructor parameters
      for (DartNode member : node.getMembers()) {
        if (member instanceof DartFieldDefinition) {
          member.accept(this);
        }
      }
      // visit all other members
      for (DartNode member : node.getMembers()) {
        if (!(member instanceof DartFieldDefinition)) {
          member.accept(this);
        }
      }
      // check that constructor names don't conflict with member names
      for (ConstructorElement constructor : classElement.getConstructors()) {
        String name = constructor.getName();
        Element member = classElement.lookupLocalElement(name);
        if (member != null) {
          resolutionError(constructor.getNameLocation(),
              ResolverErrorCode.CONSTRUCTOR_WITH_NAME_OF_MEMBER);
        }
      }
      // done with this class
      enclosingElement = previousEnclosingElement;
      endClassContext();
      return null;
    }

    private void checkParameterInitializer(DartMethodDefinition method, DartParameter parameter) {
      if (Elements.isNonFactoryConstructor(method.getElement())) {
        if (method.getModifiers().isRedirectedConstructor()) {
          resolutionError(parameter.getName(),
              ResolverErrorCode.PARAMETER_INIT_WITH_REDIR_CONSTRUCTOR);
        }

        FieldElement element =
          Elements.lookupLocalField((ClassElement) currentHolder, parameter.getParameterName());
        if (element == null) {
          resolutionError(parameter, ResolverErrorCode.PARAMETER_NOT_MATCH_FIELD,
                          parameter.getName());
        } else if (element.isStatic()) {
          resolutionError(parameter,
                          ResolverErrorCode.PARAMETER_INIT_STATIC_FIELD,
                          parameter.getName());
        }

        // Field parameters are not visible as parameters, so we do not declare them
        // in the context. Instead we record the resolved field element.
        Elements.setParameterInitializerElement(parameter.getElement(), element);

        // The editor expects the referenced elements to be non-null
        DartPropertyAccess prop = (DartPropertyAccess)parameter.getName();
        prop.setElement(element);
        prop.getName().setElement(element);

        // If no type specified, use type of field.
        if (parameter.getTypeNode() == null && element != null) {
          Elements.setType(parameter.getElement(), element.getType());
        }
      } else {
        resolutionError(parameter.getName(),
            ResolverErrorCode.PARAMETER_INIT_OUTSIDE_CONSTRUCTOR);
      }
    }

    @Override
    public Element visitFunctionTypeAlias(DartFunctionTypeAlias node) {
      isStatic = false;
      isFactory = false;
      assert !ElementKind.of(currentHolder).equals(ElementKind.CLASS) : "nested class?";
      FunctionAliasElement element = node.getElement();
      currentHolder = element;
      context = context.extend((ClassElement) currentHolder); // Put type variables in scope.
      visit(node.getTypeParameters());
      List<VariableElement> parameters = new ArrayList<VariableElement>();
      for (DartParameter parameter : node.getParameters()) {
        parameters.add((VariableElement) parameter.accept(this));
      }
      Type returnType = resolveType(node.getReturnTypeNode(), false, false, true,
          TypeErrorCode.NO_SUCH_TYPE, TypeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS);
      ClassElement functionElement = getTypeProvider().getFunctionType().getElement();
      element.setFunctionType(Types.makeFunctionType(getContext(), functionElement,
                                                     parameters, returnType));
      currentHolder = libraryElement;
      context = topLevelContext;
      return null;
    }

    @Override
    public Element visitMethodDefinition(final DartMethodDefinition method) {
      isFactory = method.getModifiers().isFactory();
      isStatic = method.getModifiers().isStatic() || isFactory;
      MethodNodeElement element = method.getElement();
      if (element == null) {
        switch (getMethodKind(method)) {
          case NONE:
          case CONSTRUCTOR:
            element = buildConstructor(method);
            checkConstructor(element, method);
            addConstructor((ClassElement) currentHolder, (ConstructorNodeElement) element);
            break;

          case METHOD:
            element = Elements.methodFromMethodNode(method, currentHolder);
            addMethod(currentHolder, element);
            break;
        }
      } else {
        // This is a top-level element, and an element was already created in
        // TopLevelElementBuilder.
        Elements.addMethod(currentHolder, element);
        assertTopLevel(method);
      }
      if (element != null) {
        checkTopLevelMainFunction(method);
        checkModifiers(element, method);
        recordElement(method, element);
        recordElement(method.getName(), element);
        ResolutionContext previous = context;
        context = context.extend(element.getName());
        EnclosingElement previousEnclosingElement = enclosingElement;
        enclosingElement = element;
        resolveFunction(method.getFunction(), element);
        enclosingElement = previousEnclosingElement;
        context = previous;
      }
      return null;
    }

    @Override
    protected void resolveFunctionWithParameters(DartFunction node, MethodElement element) {
      super.resolveFunctionWithParameters(node, element);
      // Bind "formal initializers" to fields.
      if (node.getParent() instanceof DartMethodDefinition) {
        DartMethodDefinition method = (DartMethodDefinition) node.getParent();
        for (DartParameter parameter : node.getParameters()) {
          if (parameter.getQualifier() instanceof DartThisExpression) {
            checkParameterInitializer(method, parameter);
          }
        }
      }
    }

    @Override
    public Element visitFieldDefinition(DartFieldDefinition node) {
      isStatic = false;
      isFactory = false;
      for (DartField fieldNode : node.getFields()) {
        if (fieldNode.getModifiers().isStatic()) {
          isStatic = true;
        }
      }
      Type type = resolveType(node.getTypeNode(), isStatic, false, true, TypeErrorCode.NO_SUCH_TYPE,
          TypeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS);
      for (DartField fieldNode : node.getFields()) {
        if (fieldNode.getModifiers().isAbstractField()) {
          buildAbstractField(fieldNode);
        } else {
          buildField(fieldNode, type);
        }
      }
      return null;
    }

    private void beginClassContext(final DartClass node) {
      assert !ElementKind.of(currentHolder).equals(ElementKind.CLASS) : "nested class?";
      currentHolder = node.getElement();
      context = context.extend((ClassElement) currentHolder);
    }

    private void endClassContext() {
      currentHolder = libraryElement;
      context = topLevelContext;
    }

    private Element resolveConstructorName(final DartMethodDefinition method) {
      return method.getName().accept(new ASTVisitor<Element>() {
        @Override
        public Element visitPropertyAccess(DartPropertyAccess node) {
          Element element = context.resolveName(node);
          if (ElementKind.of(element) == ElementKind.CLASS) {
            return resolveType(node);
          } else {
            element = node.getQualifier().accept(this);
            recordElement(node.getQualifier(), element);
          }
          if (ElementKind.of(element) == ElementKind.CLASS) {
            return Elements.constructorFromMethodNode(
                method, node.getPropertyName(), (ClassElement) currentHolder, (ClassElement) element);
          } else {
            // Nothing else is valid. Already warned in getMethodKind().
            return getTypeProvider().getDynamicType().getElement();
          }
        }
        @Override
        public Element visitIdentifier(DartIdentifier node) {
          return resolveType(node);
        }
        private Element resolveType(DartNode node) {
          return context.resolveType(
              node,
              node,
              null,
              true,
              false,
              false,
              ResolverErrorCode.NO_SUCH_TYPE_CONSTRUCTOR,
              ResolverErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS).getElement();
        }
        @Override
        public Element visitParameterizedTypeNode(DartParameterizedTypeNode node) {
          Element element = node.getExpression().accept(this);
          if (ElementKind.of(element).equals(ElementKind.CONSTRUCTOR)) {
            recordElement(node.getExpression(), currentHolder);
          } else {
            recordElement(node.getExpression(), element);
          }
          return element;
        }
        @Override
        public Element visitNode(DartNode node) {
          throw new RuntimeException("Unexpected node " + node);
        }
      });
    }

    private MethodNodeElement buildConstructor(final DartMethodDefinition method) {
      // Resolve the constructor's name and class name.
      Element e = resolveConstructorName(method);

      switch (ElementKind.of(e)) {
        default:
          // Report an error and create a fake constructor element below.
          resolutionError(method.getName(), ResolverErrorCode.INVALID_TYPE_NAME_IN_CONSTRUCTOR);
          break;

        case DYNAMIC:
        case CLASS:
          break;

        case CONSTRUCTOR:
          return (ConstructorNodeElement) e;
      }

      // If the constructor name resolves to a class or there was an error,
      // create the unnamed constructor.
      return Elements.constructorFromMethodNode(method, "", (ClassElement) currentHolder,
                                                (ClassElement) e);
    }

    private FieldElement buildField(DartField fieldNode, Type type) {
      assert !fieldNode.getModifiers().isAbstractField();
      Modifiers modifiers = fieldNode.getModifiers();
      // top-level fields are implicitly static.
      if (context == topLevelContext) {
        modifiers = modifiers.makeStatic();
      }
      if (fieldNode.getValue() != null) {
        modifiers = modifiers.makeInitialized();
      }
      FieldNodeElement fieldElement = fieldNode.getElement();
      if (fieldElement == null) {
        fieldElement = Elements.fieldFromNode(fieldNode, currentHolder, fieldNode.getObsoleteMetadata(),
            modifiers);
        addField(currentHolder, fieldElement);
      } else {
        // This is a top-level element, and an element was already created in
        // TopLevelElementBuilder.
        Elements.addField(currentHolder, fieldElement);
        assertTopLevel(fieldNode);
      }
      fieldElement.setType(type);
      recordElement(fieldNode.getName(), fieldElement);
      return recordElement(fieldNode, fieldElement);
    }

    private void assertTopLevel(DartNode node) throws AssertionError {
      if (!currentHolder.getKind().equals(ElementKind.LIBRARY)) {
        throw topLevelContext.internalError(node, "expected top-level node");
      }
    }

    /**
     * Creates FieldElement for AST getters and setters.
     *
     * class A {
     *   int get foo() { ... }
     *   set foo(x) { ... }
     * }
     *
     * The AST will have the shape (simplified):
     * DartClass
     *   members
     *     DartFieldDefinition
     *       DartField
     *       + name: foo
     *       + modifiers: abstractfield
     *       + accessor: int get foo() { ... }
     *     DartFieldDefinition
     *       DartField
     *       + name: foo
     *       + modifiers: abstractfield
     *       + accessor: set foo(x) { ... }
     *
     * MemberBuilder will reduce to one class element as below (simplified):
     * ClassElement
     *   members:
     *     FieldElement
     *     + name: foo
     *     + getter:
     *       MethodElement
     *       + name: foo
     *       + function: int get foo() { ... }
     *     + setter:
     *       MethodElement
     *       + name: foo
     *       + function: set foo(x) { ... }
     *
     */
    private FieldElement buildAbstractField(DartField fieldNode) {
      assert fieldNode.getModifiers().isAbstractField();
      boolean topLevelDefinition = fieldNode.getParent().getParent() instanceof DartUnit;
      DartMethodDefinition accessorNode = fieldNode.getAccessor();
      MethodNodeElement accessorElement = Elements.methodFromMethodNode(accessorNode, currentHolder);
      EnclosingElement previousEnclosingElement = enclosingElement;
      enclosingElement = accessorElement;
      recordElement(accessorNode, accessorElement);
      resolveFunction(accessorNode.getFunction(), accessorElement);
      enclosingElement = previousEnclosingElement;

      String name = fieldNode.getName().getName();
      Element element = null;
      if (currentHolder != null) {
          element = currentHolder.lookupLocalElement(name);
          if (element == null) {
            element = currentHolder.lookupLocalElement("setter " + name);
          }
      } else {
        // Top level nodes are not handled gracefully
        Scope scope = topLevelContext.getScope();
        LibraryElement library = context.getScope().getLibrary();
        element = scope.findElement(library, name);
        if (element == null) {
          element = scope.findElement(library, "setter " + name);
        }
      }

      FieldElementImplementation fieldElement = null;
      if (element == null || element.getKind().equals(ElementKind.FIELD)
          && element.getModifiers().isAbstractField()) {
        fieldElement = (FieldElementImplementation) element;
      }

      if (accessorNode.getModifiers().isGetter() && fieldElement != null && fieldElement.getSetter() != null) {
        MethodNodeElement oldSetter = fieldElement.getSetter();
        fieldElement = Elements.fieldFromNode(fieldNode, currentHolder, fieldNode.getObsoleteMetadata(),
            fieldNode.getModifiers());
        fieldElement.setSetter(oldSetter);
        addField(currentHolder, fieldElement);
      }

      if (fieldElement == null) {
        fieldElement = Elements.fieldFromNode(fieldNode, currentHolder, fieldNode.getObsoleteMetadata(),
            fieldNode.getModifiers());
        addField(currentHolder, fieldElement);
      }

      if (accessorNode.getModifiers().isGetter()) {
        if (fieldElement.getGetter() != null) {
          if (!topLevelDefinition) {
            reportDuplicateDeclaration(ResolverErrorCode.DUPLICATE_MEMBER, fieldElement.getGetter());
            reportDuplicateDeclaration(ResolverErrorCode.DUPLICATE_MEMBER, accessorElement);
          }
        } else {
          fieldElement.setGetter(accessorElement);
          fieldElement.setType(accessorElement.getReturnType());
        }
      } else if (accessorNode.getModifiers().isSetter()) {
        if (fieldElement.getSetter() != null) {
          if (!topLevelDefinition) {
            reportDuplicateDeclaration(ResolverErrorCode.DUPLICATE_MEMBER, fieldElement.getSetter());
            reportDuplicateDeclaration(ResolverErrorCode.DUPLICATE_MEMBER, accessorElement);
          }
        } else {
          fieldElement.setSetter(accessorElement);
          List<VariableElement> parameters = accessorElement.getParameters();
          Type type;
          if (parameters.size() == 0) {
            // Error flagged in parser
            type = getTypeProvider().getDynamicType();
          } else {
            type = parameters.get(0).getType();
          }
          fieldElement.setType(type);
        }
      }
      recordElement(fieldNode.getName(), accessorElement);
      return recordElement(fieldNode, fieldElement);
    }

    private void addField(EnclosingElement holder, FieldNodeElement element) {
      if (holder != null) {
        checkUniqueName(holder, element);
        checkMemberNameNotSameAsEnclosingClassName(holder, element);
        Elements.addField(holder, element);
      }
    }

    private void addMethod(EnclosingElement holder, MethodNodeElement element) {
      checkUniqueName(holder, element);
      checkMemberNameNotSameAsEnclosingClassName(holder, element);
      Elements.addMethod(holder, element);
    }

    private void addConstructor(ClassElement cls, ConstructorNodeElement element) {
      checkUniqueName(cls, element);
      Elements.addConstructor(cls, element);
    }

    private ElementKind getMethodKind(DartMethodDefinition method) {
      if (!ElementKind.of(currentHolder).equals(ElementKind.CLASS)) {
        return ElementKind.METHOD;
      }

      if (method.getModifiers().isFactory()) {
        return ElementKind.CONSTRUCTOR;
      }

      DartExpression name = method.getName();
      if (name instanceof DartIdentifier) {
        if (((DartIdentifier) name).getName().equals(currentHolder.getName())) {
          return ElementKind.CONSTRUCTOR;
        } else {
          return ElementKind.METHOD;
        }
      } else {
        DartPropertyAccess property = (DartPropertyAccess) name;
        if (property.getQualifier() instanceof DartIdentifier) {
          DartIdentifier qualifier = (DartIdentifier) property.getQualifier();
          if (qualifier.getName().equals(currentHolder.getName())) {
            return ElementKind.CONSTRUCTOR;
          }
          resolutionError(method.getName(),
                          ResolverErrorCode.CANNOT_DECLARE_NON_FACTORY_CONSTRUCTOR);
        } else if (property.getQualifier() instanceof DartParameterizedTypeNode) {
          DartParameterizedTypeNode paramNode = (DartParameterizedTypeNode)property.getQualifier();
          if (paramNode.getExpression() instanceof DartIdentifier) {
            return ElementKind.CONSTRUCTOR;
          }
          resolutionError(method.getName(),
                          ResolverErrorCode.TOO_MANY_QUALIFIERS_FOR_METHOD);
        } else {
          // Multiple qualifiers (Foo.bar.baz)
          resolutionError(method.getName(),
                          ResolverErrorCode.TOO_MANY_QUALIFIERS_FOR_METHOD);
        }
      }

      return ElementKind.NONE;
    }

    /**
     * Checks that top-level "main()" has no parameters.
     */
    private void checkTopLevelMainFunction(DartMethodDefinition method) {
      if (Objects.equal(method.getName().toSource(), "main")
          && currentHolder instanceof LibraryElement
          && !method.getFunction().getParameters().isEmpty()) {
        resolutionError(method.getName(), ResolverErrorCode.MAIN_FUNCTION_PARAMETERS);
      }
    }

    private void checkModifiers(MethodElement element, DartMethodDefinition method) {
      Modifiers modifiers = method.getModifiers();
      boolean isNonFactoryConstructor = Elements.isNonFactoryConstructor(element);
      // TODO(ngeoffray): The errors should report the position of the modifier.
      if (isNonFactoryConstructor) {
        if (modifiers.isStatic()) {
          resolutionError(method.getName(), ResolverErrorCode.CONSTRUCTOR_CANNOT_BE_STATIC);
        }
        if (modifiers.isAbstract()) {
          resolutionError(method.getName(), ResolverErrorCode.CONSTRUCTOR_CANNOT_BE_ABSTRACT);
        }
        if (modifiers.isConstant()) {
          // Allow const ... native ... ; type of constructors.  Used in core libraries.
          DartBlock dartBlock = method.getFunction().getBody();
          if (dartBlock != null && !(dartBlock instanceof DartNativeBlock)) {
            resolutionError(method.getName(),
                            ResolverErrorCode.CONST_CONSTRUCTOR_CANNOT_HAVE_BODY);
          }
        }
      }

      if (modifiers.isFactory()) {
        if (modifiers.isConstant()) {
          // Allow const factory ... native ... ; type of constructors, used in core libraries.
          // Allow const factory redirecting.
          DartBlock dartBlock = method.getFunction().getBody();
          if (!(dartBlock instanceof DartNativeBlock || method.getRedirectedTypeName() != null)) {
            resolutionError(method.getName(), ResolverErrorCode.FACTORY_CANNOT_BE_CONST);
          }
        }
      }
      // TODO(ngeoffray): Add more checks on the modifiers. For
      // example const and missing body.
    }

    private void checkConstructor(MethodElement element, DartMethodDefinition method) {
      if (Elements.isNonFactoryConstructor(element) && method.getFunction() != null
          && method.getFunction().getReturnTypeNode() != null) {
        resolutionError(method.getFunction().getReturnTypeNode(),
            ResolverErrorCode.CONSTRUCTOR_CANNOT_HAVE_RETURN_TYPE);
      }
    }

    private void checkMemberNameNotSameAsEnclosingClassName(EnclosingElement holder, Element e) {
      if (ElementKind.of(holder) == ElementKind.CLASS) {
        if (Objects.equal(holder.getName(), e.getName())) {
          resolutionError(e.getNameLocation(), ResolverErrorCode.MEMBER_WITH_NAME_OF_CLASS);
        }
      }
    }
      
    private void checkUniqueName(EnclosingElement holder, Element e) {
      if (ElementKind.of(holder) == ElementKind.LIBRARY) {
        return;
      }
      Element other = lookupElementByName(holder, e.getName(), e.getModifiers());
      assert e != other : "forgot to call checkUniqueName() before adding to the class?";
      
      if (other == null && e instanceof FieldElement) {
        FieldElement eField = (FieldElement) e;
        if (!eField.getModifiers().isAbstractField()) {
          other = lookupElementByName(holder, "setter " + e.getName(), e.getModifiers());
        }
        if (eField.getModifiers().isAbstractField()
            && StringUtils.startsWith(e.getName(), "setter ")) {
          Element other2 = lookupElementByName(holder,
              StringUtils.removeStart(e.getName(), "setter "), e.getModifiers());
          if (other2 instanceof FieldElement) {
            FieldElement otherField = (FieldElement) other2;
            if (!otherField.getModifiers().isAbstractField()) {
              other = otherField;
            }
          }
        }
      }
      
      if (other != null) {
        ElementKind eKind = ElementKind.of(e);
        ElementKind oKind = ElementKind.of(other);

        // Constructors have a separate namespace.
        boolean oIsConstructor = oKind.equals(ElementKind.CONSTRUCTOR);
        boolean eIsConstructor = eKind.equals(ElementKind.CONSTRUCTOR);
        if (oIsConstructor != eIsConstructor) {
          return;
        }

        // Both can be constructors, as long as they're for different classes.
        if (oIsConstructor && eIsConstructor) {
          if (((ConstructorElement) e).getConstructorType() !=
              ((ConstructorElement) other).getConstructorType()) {
            return;
          }
        }

        boolean eIsOperator = e.getModifiers().isOperator();
        boolean oIsOperator = other.getModifiers().isOperator();
        if (oIsOperator != eIsOperator) {
          return;
        }

        // Operators and methods can share the same name.
        boolean oIsMethod = oKind.equals(ElementKind.METHOD);
        boolean eIsMethod = eKind.equals(ElementKind.METHOD);
        if ((oIsOperator && eIsMethod) || (oIsMethod && eIsOperator)) {
          return;
        }

        // Report initial declaration and current declaration.
        reportDuplicateDeclaration(ResolverErrorCode.DUPLICATE_MEMBER, other);
        reportDuplicateDeclaration(ResolverErrorCode.DUPLICATE_MEMBER, e);
      }
    }

    private Element lookupElementByName(EnclosingElement holder, String name, Modifiers modifiers) {
      Element element = holder.lookupLocalElement(name);
      if (element == null && ElementKind.of(holder).equals(ElementKind.CLASS)) {
        ClassElement cls = (ClassElement) holder;
        String ctorName = name.equals(holder.getName()) ? "" : name;
        for (Element e : cls.getConstructors()) {
          if (e.getName().equals(ctorName)) {
            return e;
          }
        }
      }
      return element;
    }

    void resolutionError(HasSourceInfo node, ErrorCode errorCode, Object... arguments) {
      resolutionError(node.getSourceInfo(), errorCode, arguments);
    }

    void resolutionError(SourceInfo sourceInfo, ErrorCode errorCode, Object... arguments) {
      topLevelContext.onError(sourceInfo, errorCode, arguments);
    }

    /**
     * Reports duplicate declaration for given named element.
     */
    private void reportDuplicateDeclaration(ErrorCode errorCode, Element element) {
      String name =
          element instanceof MethodElement
              ? Elements.getRawMethodName((MethodElement) element)
              : element.getName();
      resolutionError(element.getNameLocation(), errorCode, name);
    }
  }
}
