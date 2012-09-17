/*
 * Copyright (c) 2012, the Dart project authors.
 * 
 * Licensed under the Eclipse Public License v1.0 (the "License"); you may not use this file except
 * in compliance with the License. You may obtain a copy of the License at
 * 
 * http://www.eclipse.org/legal/epl-v10.html
 * 
 * Unless required by applicable law or agreed to in writing, software distributed under the License
 * is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
 * or implied. See the License for the specific language governing permissions and limitations under
 * the License.
 */
package com.google.dart.compiler.ast;

import com.google.common.collect.ImmutableList;
import com.google.common.collect.Lists;
import com.google.dart.compiler.common.SourceInfo;
import com.google.dart.compiler.parser.Token;
import com.google.dart.compiler.resolver.Element;
import com.google.dart.compiler.resolver.ElementKind;
import com.google.dart.compiler.resolver.FieldElement;
import com.google.dart.compiler.resolver.MethodElement;
import com.google.dart.compiler.resolver.NodeElement;
import com.google.dart.compiler.resolver.VariableElement;
import com.google.dart.compiler.type.InterfaceType;
import com.google.dart.compiler.type.Type;
import com.google.dart.compiler.type.TypeKind;

import java.util.Collections;
import java.util.List;

/**
 * Defines utility methods that operate on nodes in a Dart AST structure (instances of
 * {@link DartNode} and its subclasses).
 */
public class ASTNodes {
  
  /**
   * Returns complete field access node for given field name.
   * 
   * <pre>
   * node = 1;        => node
   * obj.node = 1;    => obj.node
   * </pre>
   * 
   * Note, that we don't check if given {@link DartNode} is actually field name.
   */
  public static DartNode getPropertyAccessNode(DartNode node) {
    DartNode parent = node.getParent();
    if (parent instanceof DartPropertyAccess && ((DartPropertyAccess) parent).getName() == node) {
      return parent;
    }
    return node;
  }

  public static List<DartNode> findDeepestCommonPath(List<DartNode> nodes) {
    List<List<DartNode>> parents = Lists.newArrayList();
    for (DartNode node : nodes) {
      parents.add(getParents(node));
    }
    return getLongestListPrefix(parents);
  }

  /**
   * @return the {@link DartNode} of given {@link Class} which is given {@link DartNode} itself, or
   *         one of its parents.
   */
  @SuppressWarnings("unchecked")
  public static <E extends DartNode> E getAncestor(DartNode node, Class<E> enclosingClass) {
    while (node != null && !enclosingClass.isInstance(node)) {
      node = node.getParent();
    };
    return (E) node;
  }

  /**
   * Get the element associated with the given AST node.
   * 
   * @param node the target node
   * @param includeDeclarations <code>true</code> if elements should be returned for declaration
   *          sites as well as for reference sites
   * @return the associated element (or <code>null</code> if none can be found)
   */
  public static Element getElement(DartNode node, boolean includeDeclarations) {
    Element targetElement = node.getElement();
    DartNode parent = node.getParent();
    // name of named parameter in invocation
    if (node instanceof DartIdentifier && node.getParent() instanceof DartNamedExpression) {
      DartNamedExpression namedExpression = (DartNamedExpression) node.getParent();
      if (namedExpression.getName() == node) {
        Object parameterId = ((DartIdentifier) node).getInvocationParameterId();
        if (parameterId instanceof VariableElement) {
          targetElement = (VariableElement) parameterId;
        }
      }
    }
    // target of "new X()" or "new X.a()" is not just a type, it is a constructor
    if (parent instanceof DartTypeNode || parent instanceof DartPropertyAccess) {
      DartNode grandparent = parent.getParent();
      if (grandparent instanceof DartNewExpression) {
        targetElement = ((DartNewExpression) grandparent).getElement();
      }
    } else if (parent instanceof DartRedirectConstructorInvocation
        || parent instanceof DartSuperConstructorInvocation) {
      targetElement = parent.getElement();
    }
    return targetElement;
  }

  /**
   * Return the class definition enclosing the given node, or <code>null</code> if the node is not a
   * child of a class definition.
   * 
   * @param node the node enclosed in the class definition to be returned
   * @return the class definition enclosing the given node
   */
  public static DartClass getEnclosingDartClass(DartNode node) {
    return getEnclosingNodeOfType(DartClass.class, node);
  }

  /**
   * Return the first node of the given class that encloses the given node, or <code>null</code> if
   * the node is not a child of a node of the given class. The node itself will <b>not</b> be
   * returned, even if it is an instance of the given class.
   * 
   * @param enclosingNodeClass the class of node to be returned
   * @param node the child of the node to be returned
   * @return the specified parent of the given node
   */
  @SuppressWarnings("unchecked")
  public static <E extends DartNode> E getEnclosingNodeOfType(Class<E> enclosingNodeClass,
      DartNode node) {
    DartNode parent = node.getParent();
    while (parent != null && !enclosingNodeClass.isInstance(parent)) {
      parent = parent.getParent();
    }
    return (E) parent;
  }

  public static int getExclusiveEnd(DartNode node) {
    SourceInfo sourceInfo = node.getSourceInfo();
    return sourceInfo.getOffset() + sourceInfo.getLength();
  }

  /**
   * @return the {@link FieldElement} with {@link ElementKind#VARIABLE} if the given
   *         {@link DartIdentifier} is the field reference, or <code>null</code> in the other case.
   */
  public static FieldElement getFieldElement(DartIdentifier node) {
    NodeElement element = node.getElement();
    if (ElementKind.of(element) == ElementKind.FIELD) {
      return (FieldElement) element;
    }
    return null;
  }

  public static int getInclusiveEnd(DartNode node) {
    SourceInfo sourceInfo = node.getSourceInfo();
    return sourceInfo.getOffset() + sourceInfo.getLength() - 1;
  }

  /**
   * @return the {@link DartExpression} qualified if given node is name part of
   *         {@link DartPropertyAccess}. May be <code>null</code>.
   */
  public static DartNode getNodeQualifier(DartIdentifier node) {
    if (node.getParent() instanceof DartPropertyAccess) {
      DartPropertyAccess propertyAccess = (DartPropertyAccess) node.getParent();
      if (propertyAccess.getName() == node) {
        return propertyAccess.getQualifier();
      }
    }
    return null;
  }

  /**
   * @return the {@link VariableElement} if the given {@link DartIdentifier} is the parameter
   *         reference, or <code>null</code> in the other case.
   */
  public static VariableElement getParameterElement(DartIdentifier node) {
    Element element = node.getElement();
    if (ElementKind.of(element) == ElementKind.PARAMETER) {
      return (VariableElement) element;
    }
    return null;
  }

  /**
   * @return the index of given {@link VariableElement} in parameters, or <code>-1</code> if not
   *         parameter.
   */
  public static int getParameterIndex(VariableElement variableElement) {
    Element enclosingElement = variableElement.getEnclosingElement();
    if (enclosingElement instanceof MethodElement) {
      MethodElement methodElement = (MethodElement) enclosingElement;
      return methodElement.getParameters().indexOf(variableElement);
    }
    return -1;
  }

  /**
   * Returns the closest ancestor of <code>node</code> that is an instance of
   * <code>parentClass</code>, or <code>null</code> if none.
   * <p>
   * <b>Warning:</b> This method does not stop at any boundaries like parentheses, statements, body
   * declarations, etc. The resulting node may be in a totally different scope than the given node.
   * Consider using one of the {@link ASTResolving}<code>.find(..)</code> methods instead.
   * </p>
   * 
   * @param node the node
   * @param parentClass the class of the sought ancestor node
   * @return the closest ancestor of <code>node</code> that is an instance of
   *         <code>parentClass</code>, or <code>null</code> if none
   */
  @SuppressWarnings("unchecked")
  public static <E extends DartNode> E getParent(DartNode node, Class<E> parentClass) {
    do {
      node = node.getParent();
    } while (node != null && !parentClass.isInstance(node));
    return (E) node;
  }

//  private static class ChildrenCollector extends ASTVisitor<Void> {
//    public List<DartNode> result;
//
//    @Override
//    public Void visitNode(DartNode node) {
//      // first visitNode: on the node's parent: do nothing, return true
//      if (result == null) {
//        result = Lists.newArrayList();
//        return super.visitNode(node);
//      } else {
//        result.add(node);
//      }
//    }
//  }
//
//  public static final int NODE_ONLY = 0;
//  public static final int INCLUDE_FIRST_PARENT = 1;
//
//  public static final int INCLUDE_ALL_PARENTS = 2;
//  public static final int WARNING = 1 << 0;
//  public static final int ERROR = 1 << 1;
//
//  public static final int PROBLEMS = WARNING | ERROR;
//  private static final Message[] EMPTY_MESSAGES = new Message[0];
//
//  private static final IProblem[] EMPTY_PROBLEMS = new IProblem[0];
//
//  private static final int CLEAR_VISIBILITY =
//      ~(Modifier.PUBLIC | Modifier.PROTECTED | Modifier.PRIVATE);
//
//  public static String asFormattedString(DartNode node,
//      int indent,
//      String lineDelim,
//      Map<String, String> options) {
//    String unformatted = asString(node);
//    TextEdit edit = CodeFormatterUtil.format2(node, unformatted, indent, lineDelim, options);
//    if (edit != null) {
//      Document document = new Document(unformatted);
//      try {
//        edit.apply(document, TextEdit.NONE);
//      } catch (BadLocationException e) {
//        JavaPlugin.log(e);
//      }
//      return document.get();
//    }
//    return unformatted; // unknown node
//  }
//
//  public static String asString(DartNode node) {
//    ASTFlattener flattener = new ASTFlattener();
//    node.accept(flattener);
//    return flattener.getResult();
//  }
//
//  public static int changeVisibility(int modifiers, int visibility) {
//    return modifiers & CLEAR_VISIBILITY | visibility;
//  }
//
//  public static InfixExpression.Operator convertToInfixOperator(Assignment.Operator operator) {
//    if (operator.equals(Assignment.Operator.PLUS_ASSIGN)) {
//      return InfixExpression.Operator.PLUS;
//    }
//
//    if (operator.equals(Assignment.Operator.MINUS_ASSIGN)) {
//      return InfixExpression.Operator.MINUS;
//    }
//
//    if (operator.equals(Assignment.Operator.TIMES_ASSIGN)) {
//      return InfixExpression.Operator.TIMES;
//    }
//
//    if (operator.equals(Assignment.Operator.DIVIDE_ASSIGN)) {
//      return InfixExpression.Operator.DIVIDE;
//    }
//
//    if (operator.equals(Assignment.Operator.BIT_AND_ASSIGN)) {
//      return InfixExpression.Operator.AND;
//    }
//
//    if (operator.equals(Assignment.Operator.BIT_OR_ASSIGN)) {
//      return InfixExpression.Operator.OR;
//    }
//
//    if (operator.equals(Assignment.Operator.BIT_XOR_ASSIGN)) {
//      return InfixExpression.Operator.XOR;
//    }
//
//    if (operator.equals(Assignment.Operator.REMAINDER_ASSIGN)) {
//      return InfixExpression.Operator.REMAINDER;
//    }
//
//    if (operator.equals(Assignment.Operator.LEFT_SHIFT_ASSIGN)) {
//      return InfixExpression.Operator.LEFT_SHIFT;
//    }
//
//    if (operator.equals(Assignment.Operator.RIGHT_SHIFT_SIGNED_ASSIGN)) {
//      return InfixExpression.Operator.RIGHT_SHIFT_SIGNED;
//    }
//
//    if (operator.equals(Assignment.Operator.RIGHT_SHIFT_UNSIGNED_ASSIGN)) {
//      return InfixExpression.Operator.RIGHT_SHIFT_UNSIGNED;
//    }
//
//    Assert.isTrue(false, "Cannot convert assignment operator"); //$NON-NLS-1$
//    return null;
//  }
//
//  public static DartNode findDeclaration(IBinding binding, DartNode root) {
//    root = root.getRoot();
//    if (root instanceof CompilationUnit) {
//      return ((CompilationUnit) root).findDeclaringNode(binding);
//    }
//    return null;
//  }
//
//  public static Modifier findModifierNode(int flag, List<IExtendedModifier> modifiers) {
//    for (int i = 0; i < modifiers.size(); i++) {
//      Object curr = modifiers.get(i);
//      if (curr instanceof Modifier && ((Modifier) curr).getKeyword().toFlagValue() == flag) {
//        return (Modifier) curr;
//      }
//    }
//    return null;
//  }
//
//  public static DartNode findParent(DartNode node, StructuralPropertyDescriptor[][] pathes) {
//    for (int p = 0; p < pathes.length; p++) {
//      StructuralPropertyDescriptor[] path = pathes[p];
//      DartNode current = node;
//      int d = path.length - 1;
//      for (; d >= 0 && current != null; d--) {
//        StructuralPropertyDescriptor descriptor = path[d];
//        if (!descriptor.equals(current.getLocationInParent())) {
//          break;
//        }
//        current = current.getParent();
//      }
//      if (d < 0) {
//        return current;
//      }
//    }
//    return null;
//  }
//
//  public static VariableDeclaration findVariableDeclaration(IVariableBinding binding, DartNode root) {
//    if (binding.isField()) {
//      return null;
//    }
//    DartNode result = findDeclaration(binding, root);
//    if (result instanceof VariableDeclaration) {
//      return (VariableDeclaration) result;
//    }
//
//    return null;
//  }
//
//  public static List<BodyDeclaration> getBodyDeclarations(DartNode node) {
//    if (node instanceof AbstractTypeDeclaration) {
//      return ((AbstractTypeDeclaration) node).bodyDeclarations();
//    } else if (node instanceof AnonymousClassDeclaration) {
//      return ((AnonymousClassDeclaration) node).bodyDeclarations();
//    }
//    // should not happen.
//    Assert.isTrue(false);
//    return null;
//  }
//
//  /**
//   * Returns the structural property descriptor for the "bodyDeclarations" property of this node
//   * (element type: {@link BodyDeclaration}).
//   * 
//   * @param node the node, either an {@link AbstractTypeDeclaration} or an
//   *          {@link AnonymousClassDeclaration}
//   * @return the property descriptor
//   */
//  public static ChildListPropertyDescriptor getBodyDeclarationsProperty(DartNode node) {
//    if (node instanceof AbstractTypeDeclaration) {
//      return ((AbstractTypeDeclaration) node).getBodyDeclarationsProperty();
//    } else if (node instanceof AnonymousClassDeclaration) {
//      return AnonymousClassDeclaration.BODY_DECLARATIONS_PROPERTY;
//    }
//    // should not happen.
//    Assert.isTrue(false);
//    return null;
//  }
//
//  /**
//   * Returns a list of the direct children of a node. The siblings are ordered by start offset.
//   * 
//   * @param node the node to get the children for
//   * @return the children
//   */
//  public static List<DartNode> getChildren(DartNode node) {
//    ChildrenCollector visitor = new ChildrenCollector();
//    node.accept(visitor);
//    return visitor.result;
//  }
//
//  /**
//   * Returns the list that contains the given DartNode. If the node isn't part of any list,
//   * <code>null</code> is returned.
//   * 
//   * @param node the node in question
//   * @return the list that contains the node or <code>null</code>
//   */
//  public static List<? extends DartNode> getContainingList(DartNode node) {
//    StructuralPropertyDescriptor locationInParent = node.getLocationInParent();
//    if (locationInParent != null && locationInParent.isChildListProperty()) {
//      return (List<? extends DartNode>) node.getParent().getStructuralProperty(locationInParent);
//    }
//    return null;
//  }
//
//  public static int getDimensions(VariableDeclaration declaration) {
//    int dim = declaration.getExtraDimensions();
//    Type type = getType(declaration);
//    if (type instanceof ArrayType) {
//      dim += ((ArrayType) type).getDimensions();
//    }
//    return dim;
//  }
//
//  /**
//   * Returns the element type. This is a convenience method that returns its argument if it is a
//   * simple type and the element type if the parameter is an array type.
//   * 
//   * @param type The type to get the element type from.
//   * @return The element type of the type or the type itself.
//   */
//  public static Type getElementType(Type type) {
//    if (!type.isArrayType()) {
//      return type;
//    }
//    return ((ArrayType) type).getElementType();
//  }
//
//  public static ITypeBinding getEnclosingType(DartNode node) {
//    while (node != null) {
//      if (node instanceof AbstractTypeDeclaration) {
//        return ((AbstractTypeDeclaration) node).resolveBinding();
//      } else if (node instanceof AnonymousClassDeclaration) {
//        return ((AnonymousClassDeclaration) node).resolveBinding();
//      }
//      node = node.getParent();
//    }
//    return null;
//  }
//
//  public static int getExclusiveEnd(DartNode node) {
//    return node.getStartPosition() + node.getLength();
//  }
//
//  /**
//   * Returns the type to which an inlined variable initializer should be cast, or <code>null</code>
//   * if no cast is necessary.
//   * 
//   * @param initializer the initializer expression of the variable to inline
//   * @param reference the reference to the variable (which is to be inlined)
//   * @return a type binding to which the initializer should be cast, or <code>null</code> iff no
//   *         cast is necessary
//   */
//  public static ITypeBinding getExplicitCast(Expression initializer, Expression reference) {
//    ITypeBinding initializerType = initializer.resolveTypeBinding();
//    ITypeBinding referenceType = reference.resolveTypeBinding();
//    if (initializerType == null || referenceType == null) {
//      return null;
//    }
//
//    if (initializerType.isPrimitive()
//        && referenceType.isPrimitive()
//        && !referenceType.isEqualTo(initializerType)) {
//      return referenceType;
//
//    } else if (initializerType.isPrimitive() && !referenceType.isPrimitive()) { // initializer is autoboxed
//      ITypeBinding unboxedReferenceType =
//          Bindings.getUnboxedTypeBinding(referenceType, reference.getAST());
//      if (!unboxedReferenceType.isEqualTo(initializerType)) {
//        return unboxedReferenceType;
//      } else if (needsExplicitBoxing(reference)) {
//        return referenceType;
//      }
//
//    } else if (!initializerType.isPrimitive() && referenceType.isPrimitive()) { // initializer is autounboxed
//      ITypeBinding unboxedInitializerType =
//          Bindings.getUnboxedTypeBinding(initializerType, reference.getAST());
//      if (!unboxedInitializerType.isEqualTo(referenceType)) {
//        return referenceType;
//      }
//
//    } else if (initializerType.isRawType() && referenceType.isParameterizedType()) {
//      return referenceType; // don't lose the unchecked conversion
//
//    } else if (!TypeRules.canAssign(initializerType, referenceType)) {
//      if (!Bindings.containsTypeVariables(referenceType)) {
//        return referenceType;
//      }
//    }
//
//    return null;
//  }
//
//  public static IVariableBinding getFieldBinding(Name node) {
//    IVariableBinding result = getVariableBinding(node);
//    if (result == null || !result.isField()) {
//      return null;
//    }
//
//    return result;
//  }
//
//  public static int getInclusiveEnd(DartNode node) {
//    return node.getStartPosition() + node.getLength() - 1;
//  }
//
//  /**
//   * Computes the insertion index to be used to add the given member to the the list
//   * <code>container</code>.
//   * 
//   * @param member the member to add
//   * @param container a list containing objects of type <code>BodyDeclaration</code>
//   * @return the insertion index to be used
//   */
//  public static int getInsertionIndex(BodyDeclaration member,
//      List<? extends BodyDeclaration> container) {
//    int containerSize = container.size();
//
//    MembersOrderPreferenceCache orderStore =
//        JavaPlugin.getDefault().getMemberOrderPreferenceCache();
//
//    int orderIndex = getOrderPreference(member, orderStore);
//
//    int insertPos = containerSize;
//    int insertPosOrderIndex = -1;
//
//    for (int i = containerSize - 1; i >= 0; i--) {
//      int currOrderIndex = getOrderPreference(container.get(i), orderStore);
//      if (orderIndex == currOrderIndex) {
//        if (insertPosOrderIndex != orderIndex) { // no perfect match yet
//          insertPos = i + 1; // after a same kind
//          insertPosOrderIndex = orderIndex; // perfect match
//        }
//      } else if (insertPosOrderIndex != orderIndex) { // not yet a perfect match
//        if (currOrderIndex < orderIndex) { // we are bigger
//          if (insertPosOrderIndex == -1) {
//            insertPos = i + 1; // after
//            insertPosOrderIndex = currOrderIndex;
//          }
//        } else {
//          insertPos = i; // before
//          insertPosOrderIndex = currOrderIndex;
//        }
//      }
//    }
//    return insertPos;
//  }
//
//  public static SimpleName getLeftMostSimpleName(Name name) {
//    if (name instanceof SimpleName) {
//      return (SimpleName) name;
//    } else {
//      final SimpleName[] result = new SimpleName[1];
//      ASTVisitor visitor = new ASTVisitor() {
//        @Override
//        public boolean visit(QualifiedName qualifiedName) {
//          Name left = qualifiedName.getQualifier();
//          if (left instanceof SimpleName) {
//            result[0] = (SimpleName) left;
//          } else {
//            left.accept(this);
//          }
//          return false;
//        }
//      };
//      name.accept(visitor);
//      return result[0];
//    }
//  }
//
//  public static SimpleType getLeftMostSimpleType(QualifiedType type) {
//    final SimpleType[] result = new SimpleType[1];
//    ASTVisitor visitor = new ASTVisitor() {
//      @Override
//      public boolean visit(QualifiedType qualifiedType) {
//        Type left = qualifiedType.getQualifier();
//        if (left instanceof SimpleType) {
//          result[0] = (SimpleType) left;
//        } else {
//          left.accept(this);
//        }
//        return false;
//      }
//    };
//    type.accept(visitor);
//    return result[0];
//  }
//
//  public static IVariableBinding getLocalVariableBinding(Name node) {
//    IVariableBinding result = getVariableBinding(node);
//    if (result == null || result.isField()) {
//      return null;
//    }
//
//    return result;
//  }
//
//  public static Message[] getMessages(DartNode node, int flags) {
//    DartNode root = node.getRoot();
//    if (!(root instanceof CompilationUnit)) {
//      return EMPTY_MESSAGES;
//    }
//    Message[] messages = ((CompilationUnit) root).getMessages();
//    if (root == node) {
//      return messages;
//    }
//    final int iterations = computeIterations(flags);
//    List<Message> result = new ArrayList<Message>(5);
//    for (int i = 0; i < messages.length; i++) {
//      Message message = messages[i];
//      DartNode temp = node;
//      int count = iterations;
//      do {
//        int nodeOffset = temp.getStartPosition();
//        int messageOffset = message.getStartPosition();
//        if (nodeOffset <= messageOffset && messageOffset < nodeOffset + temp.getLength()) {
//          result.add(message);
//          count = 0;
//        } else {
//          count--;
//        }
//      } while ((temp = temp.getParent()) != null && count > 0);
//    }
//    return result.toArray(new Message[result.size()]);
//  }
//
//  public static IMethodBinding getMethodBinding(Name node) {
//    IBinding binding = node.resolveBinding();
//    if (binding instanceof IMethodBinding) {
//      return (IMethodBinding) binding;
//    }
//    return null;
//  }
//
//  public static List<IExtendedModifier> getModifiers(VariableDeclaration declaration) {
//    Assert.isNotNull(declaration);
//    if (declaration instanceof SingleVariableDeclaration) {
//      return ((SingleVariableDeclaration) declaration).modifiers();
//    } else if (declaration instanceof VariableDeclarationFragment) {
//      DartNode parent = declaration.getParent();
//      if (parent instanceof VariableDeclarationExpression) {
//        return ((VariableDeclarationExpression) parent).modifiers();
//      } else if (parent instanceof VariableDeclarationStatement) {
//        return ((VariableDeclarationStatement) parent).modifiers();
//      }
//    }
//    return new ArrayList<IExtendedModifier>(0);
//  }
//
//  /**
//   * Returns the source of the given node from the location where it was parsed.
//   * 
//   * @param node the node to get the source from
//   * @param extendedRange if set, the extended ranges of the nodes should ne used
//   * @param removeIndent if set, the indentation is removed.
//   * @return return the source for the given node or null if accessing the source failed.
//   */
//  public static String getNodeSource(DartNode node, boolean extendedRange, boolean removeIndent) {
//    DartNode root = node.getRoot();
//    if (root instanceof CompilationUnit) {
//      CompilationUnit astRoot = (CompilationUnit) root;
//      ITypeRoot typeRoot = astRoot.getTypeRoot();
//      try {
//        if (typeRoot != null && typeRoot.getBuffer() != null) {
//          IBuffer buffer = typeRoot.getBuffer();
//          int offset =
//              extendedRange ? astRoot.getExtendedStartPosition(node) : node.getStartPosition();
//          int length = extendedRange ? astRoot.getExtendedLength(node) : node.getLength();
//          String str = buffer.getText(offset, length);
//          if (removeIndent) {
//            IJavaProject project = typeRoot.getJavaProject();
//            int indent = StubUtility.getIndentUsed(buffer, node.getStartPosition(), project);
//            str =
//                Strings.changeIndent(
//                    str,
//                    indent,
//                    project,
//                    new String(),
//                    typeRoot.findRecommendedLineSeparator());
//          }
//          return str;
//        }
//      } catch (JavaModelException e) {
//        // ignore
//      }
//    }
//    return null;
//  }
//
//  public static DartNode getNormalizedNode(DartNode node) {
//    DartNode current = node;
//    // normalize name
//    if (QualifiedName.NAME_PROPERTY.equals(current.getLocationInParent())) {
//      current = current.getParent();
//    }
//    // normalize type
//    if (QualifiedType.NAME_PROPERTY.equals(current.getLocationInParent())
//        || SimpleType.NAME_PROPERTY.equals(current.getLocationInParent())) {
//      current = current.getParent();
//    }
//    // normalize parameterized types
//    if (ParameterizedType.TYPE_PROPERTY.equals(current.getLocationInParent())) {
//      current = current.getParent();
//    }
//    return current;
//  }

  /**
   * @return parent {@link DartNode}s from {@link DartUnit} (at index "0") to the given one.
   */
  public static List<DartNode> getParents(DartNode node) {
    List<DartNode> parents = Lists.newArrayList();
    DartNode current = node;
    do {
      parents.add(current.getParent());
      current = current.getParent();
    } while (current.getParent() != null);
    Collections.reverse(parents);
    return parents;
  }

  /**
   * @return given {@link DartStatement} if not {@link DartBlock}, first child {@link DartStatement}
   *         if {@link DartBlock}, or <code>null</code> if more than one child.
   */
  public static DartStatement getSingleStatement(DartStatement statement) {
    if (statement instanceof DartBlock) {
      List<DartStatement> blockStatements = ((DartBlock) statement).getStatements();
      if (blockStatements.size() != 1) {
        return null;
      }
      return blockStatements.get(0);
    }
    return statement;
  }

  /**
   * @return given {@link DartStatement} if not {@link DartBlock}, all children
   *         {@link DartStatement}s if {@link DartBlock}.
   */
  public static List<DartStatement> getStatements(DartStatement statement) {
    if (statement instanceof DartBlock) {
      return ((DartBlock) statement).getStatements();
    }
    return ImmutableList.of(statement);
  }

  /**
   * @return the {@link DartThisExpression} if given node is name of {@link DartPropertyAccess} with
   *         {@link DartThisExpression} qualifier. May be <code>null</code>.
   */
  public static DartThisExpression getThisQualifier(DartIdentifier node) {
    if (node.getParent() instanceof DartPropertyAccess) {
      DartPropertyAccess propertyAccess = (DartPropertyAccess) node.getParent();
      if (propertyAccess.getName() == node
          && propertyAccess.getQualifier() instanceof DartThisExpression) {
        return (DartThisExpression) propertyAccess.getQualifier();
      }
    }
    return null;
  }

  /**
   * Return the type associated with the given type node, or <code>null</code> if the type could not
   * be determined.
   * 
   * @param typeNode the type node whose type is to be returned
   * @return the type associated with the given type node
   */
  public static Type getType(DartTypeNode typeNode) {
    Type type = typeNode.getType();
    if (type == null) {
      DartNode parent = typeNode.getParent();
      if (parent instanceof DartTypeNode) {
        Type parentType = getType((DartTypeNode) parent);
        if (parentType != null && parentType.getKind() == TypeKind.INTERFACE) {
          int index = ((DartTypeNode) parent).getTypeArguments().indexOf(typeNode);
          return ((InterfaceType) parentType).getArguments().get(index);
        }
      }
    }
    return type;
  }

  /**
   * @return the {@link VariableElement} with {@link ElementKind#VARIABLE} if the given
   *         {@link DartIdentifier} is the local variable reference, or <code>null</code> in the
   *         other case.
   */
  public static VariableElement getVariableElement(DartIdentifier node) {
    NodeElement element = node.getElement();
    if (ElementKind.of(element) == ElementKind.VARIABLE) {
      return (VariableElement) element;
    }
    return null;
  }

  /**
   * @return the {@link VariableElement} with {@link ElementKind#VARIABLE} or
   *         {@link ElementKind#PARAMETER} if the given {@link DartIdentifier} is the reference to
   *         local variable or parameter, or <code>null</code> in the other case.
   */
  public static VariableElement getVariableOrParameterElement(DartIdentifier node) {
    NodeElement element = node.getElement();
    if (element instanceof VariableElement) {
      return (VariableElement) element;
    }
    return null;
  }

  /**
   * Return <code>true</code> if the given method is a constructor.
   * 
   * @param method the method being tested
   * @return <code>true</code> if the given method is a constructor
   */
  public static boolean isConstructor(DartMethodDefinition method) {
    MethodElement methodElement = method.getElement();
    if (methodElement != null) {
      return methodElement.isConstructor();
    }
    return isConstructor(((DartClass) method.getParent()).getClassName(), method);
  }

  /**
   * Return <code>true</code> if the given method is a constructor.
   * 
   * @param className the name of the type containing the method definition
   * @param method the method being tested
   * @return <code>true</code> if the given method is a constructor
   */
  public static boolean isConstructor(String className, DartMethodDefinition method) {
    if (method.getModifiers().isFactory()) {
      return true;
    }
    DartExpression name = method.getName();
    if (name instanceof DartIdentifier) {
      return ((DartIdentifier) name).getName().equals(className);
    } else if (name instanceof DartPropertyAccess) {
      DartPropertyAccess property = (DartPropertyAccess) name;
      DartNode qualifier = property.getQualifier();
      if (qualifier instanceof DartIdentifier) {
        return ((DartIdentifier) qualifier).getName().equals(className);
      }
    }
    return false;
  }

  /**
   * @return <code>true</code> if given {@link DartNode} is the name of some {@link DartDeclaration}
   *         .
   */
  public static boolean isNameOfDeclaration(DartNode node) {
    return node.getParent() instanceof DartDeclaration<?>
        && ((DartDeclaration<?>) node.getParent()).getName() == node;
  }

  /**
   * @return <code>true</code> if given {@link List}s are equals at given position.
   */
  private static <T> boolean allListsEqual(List<List<T>> lists, int position) {
    T element = lists.get(0).get(position);
    for (List<T> list : lists) {
      if (list.get(position) != element) {
        return false;
      }
    }
    return true;
  }

  private static <T> List<T> getLongestListPrefix(List<List<T>> lists) {
    if (lists.isEmpty()) {
      return ImmutableList.of();
    }
    // prepare minimal length of all arrays
    int minLength = lists.get(0).size();
    for (List<T> list : lists) {
      minLength = Math.min(minLength, list.size());
    }
    // find length of the common prefix
    int length = -1;
    for (int i = 0; i < minLength; i++) {
      if (!allListsEqual(lists, i)) {
        break;
      }
      length++;
    }
    // done
    return lists.get(0).subList(0, length + 1);
  }

//  /**
//   * Returns the closest ancestor of <code>node</code> whose type is <code>nodeType</code>, or
//   * <code>null</code> if none.
//   * <p>
//   * <b>Warning:</b> This method does not stop at any boundaries like parentheses, statements, body
//   * declarations, etc. The resulting node may be in a totally different scope than the given node.
//   * Consider using one of the {@link ASTResolving}<code>.find(..)</code> methods instead.
//   * </p>
//   * 
//   * @param node the node
//   * @param nodeType the node type constant from {@link DartNode}
//   * @return the closest ancestor of <code>node</code> whose type is <code>nodeType</code>, or
//   *         <code>null</code> if none
//   */
//  public static DartNode getParent(DartNode node, int nodeType) {
//    do {
//      node = node.getParent();
//    } while (node != null && node.getNodeType() != nodeType);
//    return node;
//  }
//
//  public static IProblem[] getProblems(DartNode node, int scope, int severity) {
//    DartNode root = node.getRoot();
//    if (!(root instanceof CompilationUnit)) {
//      return EMPTY_PROBLEMS;
//    }
//    IProblem[] problems = ((CompilationUnit) root).getProblems();
//    if (root == node) {
//      return problems;
//    }
//    final int iterations = computeIterations(scope);
//    List<IProblem> result = new ArrayList<IProblem>(5);
//    for (int i = 0; i < problems.length; i++) {
//      IProblem problem = problems[i];
//      boolean consider = false;
//      if ((severity & PROBLEMS) == PROBLEMS) {
//        consider = true;
//      } else if ((severity & WARNING) != 0) {
//        consider = problem.isWarning();
//      } else if ((severity & ERROR) != 0) {
//        consider = problem.isError();
//      }
//      if (consider) {
//        DartNode temp = node;
//        int count = iterations;
//        do {
//          int nodeOffset = temp.getStartPosition();
//          int problemOffset = problem.getSourceStart();
//          if (nodeOffset <= problemOffset && problemOffset < nodeOffset + temp.getLength()) {
//            result.add(problem);
//            count = 0;
//          } else {
//            count--;
//          }
//        } while ((temp = temp.getParent()) != null && count > 0);
//      }
//    }
//    return result.toArray(new IProblem[result.size()]);
//  }
//
//  public static String getQualifier(Name name) {
//    if (name.isQualifiedName()) {
//      return ((QualifiedName) name).getQualifier().getFullyQualifiedName();
//    }
//    return ""; //$NON-NLS-1$
//  }
//
//  /**
//   * Returns the receiver's type binding of the given method invocation.
//   * 
//   * @param invocation method invocation to resolve type of
//   * @return the type binding of the receiver
//   */
//  public static ITypeBinding getReceiverTypeBinding(MethodInvocation invocation) {
//    ITypeBinding result = null;
//    Expression exp = invocation.getExpression();
//    if (exp != null) {
//      return exp.resolveTypeBinding();
//    } else {
//      AbstractTypeDeclaration type =
//          (AbstractTypeDeclaration) getParent(invocation, AbstractTypeDeclaration.class);
//      if (type != null) {
//        return type.resolveBinding();
//      }
//    }
//    return result;
//  }
//
//  public static String getSimpleNameIdentifier(Name name) {
//    if (name.isQualifiedName()) {
//      return ((QualifiedName) name).getName().getIdentifier();
//    } else {
//      return ((SimpleName) name).getIdentifier();
//    }
//  }
//
//  public static Name getTopMostName(Name name) {
//    Name result = name;
//    while (result.getParent() instanceof Name) {
//      result = (Name) result.getParent();
//    }
//    return result;
//  }
//
//  public static Type getTopMostType(Type type) {
//    Type result = type;
//    while (result.getParent() instanceof Type) {
//      result = (Type) result.getParent();
//    }
//    return result;
//  }
//
//  /**
//   * Returns the type node for the given declaration.
//   * 
//   * @param declaration the declaration
//   * @return the type node
//   */
//  public static Type getType(VariableDeclaration declaration) {
//    if (declaration instanceof SingleVariableDeclaration) {
//      return ((SingleVariableDeclaration) declaration).getType();
//    } else if (declaration instanceof VariableDeclarationFragment) {
//      DartNode parent = ((VariableDeclarationFragment) declaration).getParent();
//      if (parent instanceof VariableDeclarationExpression) {
//        return ((VariableDeclarationExpression) parent).getType();
//      } else if (parent instanceof VariableDeclarationStatement) {
//        return ((VariableDeclarationStatement) parent).getType();
//      } else if (parent instanceof FieldDeclaration) {
//        return ((FieldDeclaration) parent).getType();
//      }
//    }
//    Assert.isTrue(false, "Unknown VariableDeclaration"); //$NON-NLS-1$
//    return null;
//  }
//
//  public static ITypeBinding getTypeBinding(CompilationUnit root, IType type)
//      throws JavaModelException {
//    if (type.isAnonymous()) {
//      final IJavaElement parent = type.getParent();
//      if (parent instanceof IField && Flags.isEnum(((IMember) parent).getFlags())) {
//        final EnumConstantDeclaration constant =
//            (EnumConstantDeclaration) NodeFinder.perform(
//                root,
//                ((ISourceReference) parent).getSourceRange());
//        if (constant != null) {
//          final AnonymousClassDeclaration declaration = constant.getAnonymousClassDeclaration();
//          if (declaration != null) {
//            return declaration.resolveBinding();
//          }
//        }
//      } else {
//        final ClassInstanceCreation creation =
//            (ClassInstanceCreation) getParent(
//                NodeFinder.perform(root, type.getNameRange()),
//                ClassInstanceCreation.class);
//        if (creation != null) {
//          return creation.resolveTypeBinding();
//        }
//      }
//    } else {
//      final AbstractTypeDeclaration declaration =
//          (AbstractTypeDeclaration) getParent(
//              NodeFinder.perform(root, type.getNameRange()),
//              AbstractTypeDeclaration.class);
//      if (declaration != null) {
//        return declaration.resolveBinding();
//      }
//    }
//    return null;
//  }
//
//  public static ITypeBinding getTypeBinding(Name node) {
//    IBinding binding = node.resolveBinding();
//    if (binding instanceof ITypeBinding) {
//      return (ITypeBinding) binding;
//    }
//    return null;
//  }
//
//  public static String getTypeName(Type type) {
//    final StringBuffer buffer = new StringBuffer();
//    ASTVisitor visitor = new ASTVisitor() {
//      @Override
//      public void endVisit(ArrayType node) {
//        buffer.append("[]"); //$NON-NLS-1$
//      }
//
//      @Override
//      public boolean visit(PrimitiveType node) {
//        buffer.append(node.getPrimitiveTypeCode().toString());
//        return false;
//      }
//
//      @Override
//      public boolean visit(QualifiedName node) {
//        buffer.append(node.getName().getIdentifier());
//        return false;
//      }
//
//      @Override
//      public boolean visit(SimpleName node) {
//        buffer.append(node.getIdentifier());
//        return false;
//      }
//    };
//    type.accept(visitor);
//    return buffer.toString();
//  }
//
//  public static IVariableBinding getVariableBinding(Name node) {
//    IBinding binding = node.resolveBinding();
//    if (binding instanceof IVariableBinding) {
//      return (IVariableBinding) binding;
//    }
//    return null;
//  }
//
//  /**
//   * Returns true if a node at a given location is a body of a control statement. Such body nodes
//   * are interesting as when replacing them, it has to be evaluates if a Block is needed instead.
//   * E.g. <code> if (x) do(); -> if (x) { do1(); do2() } </code>
//   * 
//   * @param locationInParent Location of the body node
//   * @return Returns true if the location is a body node location of a control statement.
//   */
//  public static boolean isControlStatementBody(StructuralPropertyDescriptor locationInParent) {
//    return locationInParent == IfStatement.THEN_STATEMENT_PROPERTY
//        || locationInParent == IfStatement.ELSE_STATEMENT_PROPERTY
//        || locationInParent == ForStatement.BODY_PROPERTY
//        || locationInParent == EnhancedForStatement.BODY_PROPERTY
//        || locationInParent == WhileStatement.BODY_PROPERTY
//        || locationInParent == DoStatement.BODY_PROPERTY;
//  }
//
//  public static boolean isDeclaration(Name name) {
//    if (name.isQualifiedName()) {
//      return ((QualifiedName) name).getName().isDeclaration();
//    } else {
//      return ((SimpleName) name).isDeclaration();
//    }
//  }
//
//  /**
//   * Returns true if this is an existing node, i.e. it was created as part of a parsing process of a
//   * source code file. Returns false if this is a newly created node which has not yet been given a
//   * source position.
//   * 
//   * @param node the node to be tested.
//   * @return true if this is an existing node, false if not.
//   */
//  public static boolean isExistingNode(DartNode node) {
//    return node.getStartPosition() != -1;
//  }
//
//  public static boolean isLabel(SimpleName name) {
//    int parentType = name.getParent().getNodeType();
//    return parentType == DartNode.LABELED_STATEMENT
//        || parentType == DartNode.BREAK_STATEMENT
//        || parentType != DartNode.CONTINUE_STATEMENT;
//  }
//
//  public static boolean isLiteral(Expression expression) {
//    int type = expression.getNodeType();
//    return type == DartNode.BOOLEAN_LITERAL
//        || type == DartNode.CHARACTER_LITERAL
//        || type == DartNode.NULL_LITERAL
//        || type == DartNode.NUMBER_LITERAL
//        || type == DartNode.STRING_LITERAL
//        || type == DartNode.TYPE_LITERAL;
//  }
//
//  /**
//   * Returns <code>true</code> iff <code>parent</code> is a true ancestor of <code>node</code> (i.e.
//   * returns <code>false</code> if <code>parent == node</code>).
//   * 
//   * @param node node to test
//   * @param parent assumed parent
//   * @return <code>true</code> iff <code>parent</code> is a true ancestor of <code>node</code>
//   */
//  public static boolean isParent(DartNode node, DartNode parent) {
//    Assert.isNotNull(parent);
//    do {
//      node = node.getParent();
//      if (node == parent) {
//        return true;
//      }
//    } while (node != null);
//    return false;
//  }
//
//  public static boolean isSingleDeclaration(VariableDeclaration declaration) {
//    Assert.isNotNull(declaration);
//    if (declaration instanceof SingleVariableDeclaration) {
//      return true;
//    } else if (declaration instanceof VariableDeclarationFragment) {
//      DartNode parent = declaration.getParent();
//      if (parent instanceof VariableDeclarationExpression) {
//        return ((VariableDeclarationExpression) parent).fragments().size() == 1;
//      } else if (parent instanceof VariableDeclarationStatement) {
//        return ((VariableDeclarationStatement) parent).fragments().size() == 1;
//      }
//    }
//    return false;
//  }
//
//  public static boolean isStatic(BodyDeclaration declaration) {
//    return Modifier.isStatic(declaration.getModifiers());
//  }
//
//  /**
//   * Adds flags to the given node and all its descendants.
//   * 
//   * @param root The root node
//   * @param flags The flags to set
//   */
//  public static void setFlagsToAST(DartNode root, final int flags) {
//    root.accept(new GenericVisitor(true) {
//      @Override
//      protected boolean visitNode(DartNode node) {
//        node.setFlags(node.getFlags() | flags);
//        return true;
//      }
//    });
//  }
//
//  private static int computeIterations(int flags) {
//    switch (flags) {
//      case NODE_ONLY:
//        return 1;
//      case INCLUDE_ALL_PARENTS:
//        return Integer.MAX_VALUE;
//      case INCLUDE_FIRST_PARENT:
//        return 2;
//      default:
//        return 1;
//    }
//  }
//
//  private static int getOrderPreference(BodyDeclaration member, MembersOrderPreferenceCache store) {
//    int memberType = member.getNodeType();
//    int modifiers = member.getModifiers();
//
//    switch (memberType) {
//      case DartNode.TYPE_DECLARATION:
//      case DartNode.ENUM_DECLARATION:
//      case DartNode.ANNOTATION_TYPE_DECLARATION:
//        return store.getCategoryIndex(MembersOrderPreferenceCache.TYPE_INDEX) * 2;
//      case DartNode.FIELD_DECLARATION:
//        if (Modifier.isStatic(modifiers)) {
//          int index = store.getCategoryIndex(MembersOrderPreferenceCache.STATIC_FIELDS_INDEX) * 2;
//          if (Modifier.isFinal(modifiers)) {
//            return index; // first final static, then static
//          }
//          return index + 1;
//        }
//        return store.getCategoryIndex(MembersOrderPreferenceCache.FIELDS_INDEX) * 2;
//      case DartNode.INITIALIZER:
//        if (Modifier.isStatic(modifiers)) {
//          return store.getCategoryIndex(MembersOrderPreferenceCache.STATIC_INIT_INDEX) * 2;
//        }
//        return store.getCategoryIndex(MembersOrderPreferenceCache.INIT_INDEX) * 2;
//      case DartNode.ANNOTATION_TYPE_MEMBER_DECLARATION:
//        return store.getCategoryIndex(MembersOrderPreferenceCache.METHOD_INDEX) * 2;
//      case DartNode.METHOD_DECLARATION:
//        if (Modifier.isStatic(modifiers)) {
//          return store.getCategoryIndex(MembersOrderPreferenceCache.STATIC_METHODS_INDEX) * 2;
//        }
//        if (((MethodDeclaration) member).isConstructor()) {
//          return store.getCategoryIndex(MembersOrderPreferenceCache.CONSTRUCTORS_INDEX) * 2;
//        }
//        return store.getCategoryIndex(MembersOrderPreferenceCache.METHOD_INDEX) * 2;
//      default:
//        return 100;
//    }
//  }
//
//  /**
//   * Returns whether an expression at the given location needs explicit boxing.
//   * 
//   * @param expression the expression
//   * @return <code>true</code> iff an expression at the given location needs explicit boxing
//   */
//  private static boolean needsExplicitBoxing(Expression expression) {
//    StructuralPropertyDescriptor locationInParent = expression.getLocationInParent();
//    if (locationInParent == ParenthesizedExpression.EXPRESSION_PROPERTY) {
//      return needsExplicitBoxing((ParenthesizedExpression) expression.getParent());
//    }
//
//    if (locationInParent == ClassInstanceCreation.EXPRESSION_PROPERTY
//        || locationInParent == FieldAccess.EXPRESSION_PROPERTY
//        || locationInParent == MethodInvocation.EXPRESSION_PROPERTY) {
//      return true;
//    }
//
//    return false;
//  }

  private ASTNodes() {
    // no instance;
  }

  /**
   * Looks to see if the property access requires a getter.
   * <p>
   * A property access requires a getter if it is on the right hand side of an assignment, or if it
   * is on the left hand side of an assignment and uses one of the assignment operators other than
   * plain '='.
   * <p>
   * Note, that we don't check if given {@link DartNode} is actually field name.
   */
  public static boolean inGetterContext(DartNode node) {
    if (node.getParent() instanceof DartBinaryExpression) {
      DartBinaryExpression expr = (DartBinaryExpression) node.getParent();
      if (expr.getArg1() == node && expr.getOperator() == Token.ASSIGN) {
        return false;
      }
    }
    return true;
  }

  /**
   * Looks to see if the property access requires a setter.
   * <p>
   * Basically, this boils down to any property access on the left hand side of an assignment.
   * <p>
   * Keep in mind that an assignment of the form node = <expr> is the only kind of write-only
   * expression. Other types of assignments also read the value and require a getter access.
   * <p>
   * Note, that we don't check if given {@link DartNode} is actually field name.
   */
  public static boolean inSetterContext(DartNode node) {
    if (node.getParent() instanceof DartUnaryExpression) {
      DartUnaryExpression expr = (DartUnaryExpression) node.getParent();
      return expr.getArg() == node && expr.getOperator().isCountOperator();
    }
    if (node.getParent() instanceof DartBinaryExpression) {
      DartBinaryExpression expr = (DartBinaryExpression) node.getParent();
      return expr.getArg1() == node && expr.getOperator().isAssignmentOperator();
    }
    return false;
  }

}
