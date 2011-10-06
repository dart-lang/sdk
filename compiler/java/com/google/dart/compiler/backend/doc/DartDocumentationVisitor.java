// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.backend.doc;

import com.google.common.io.CharStreams;
import com.google.dart.compiler.Source;
import com.google.dart.compiler.ast.DartClass;
import com.google.dart.compiler.ast.DartComment;
import com.google.dart.compiler.ast.DartField;
import com.google.dart.compiler.ast.DartMethodDefinition;
import com.google.dart.compiler.ast.DartNodeTraverser;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.ast.LibraryUnit;
import com.google.dart.compiler.resolver.ClassElement;
import com.google.dart.compiler.resolver.ConstructorElement;
import com.google.dart.compiler.resolver.Element;
import com.google.dart.compiler.resolver.ElementKind;
import com.google.dart.compiler.resolver.EnclosingElement;
import com.google.dart.compiler.resolver.FieldElement;
import com.google.dart.compiler.resolver.MethodElement;
import com.google.dart.compiler.resolver.VariableElement;
import com.google.dart.compiler.type.FunctionType;
import com.google.dart.compiler.type.InterfaceType;
import com.google.dart.compiler.type.Type;
import com.google.dart.compiler.type.TypeKind;

import java.io.CharArrayWriter;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.PrintStream;
import java.io.Reader;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedList;
import java.util.List;
import java.util.Set;

class DartDocumentationVisitor extends DartNodeTraverser<Void> {
  private String outputDirectory;
  private String library;
  private PrintStream stream;
  private List<DartComment> dartDocComments;
  private Set<LinkInformation> anchors;
  private Set<LinkInformation> links;
  private char[] unitSource;

  DartDocumentationVisitor(String out,
                           String lib,
                           List<DartComment> comments,
                           Set<LinkInformation> anchors,
                           Set<LinkInformation> links) {
    outputDirectory = out;
    library = lib;
    dartDocComments = (comments == null)
        ? Collections.<DartComment>emptyList()
        : new ArrayList<DartComment>(comments);
    this.anchors = anchors;
    this.links = links;
    stream = null;
    unitSource = null;
  }

  public void initialize(DartUnit unit) {
    readSource(unit.getSource());
  }
  
  private boolean isPrivateName(String name) {
    return !name.isEmpty() && name.charAt(0) == '_';
  }

  private void readSource(Source source) {
    try {
      Reader reader = source.getSourceReader();
      CharArrayWriter writer = new CharArrayWriter();
      CharStreams.copy(reader, writer);
      unitSource = writer.toCharArray();
    } catch (IOException e) {
      throw new RuntimeException(e);
    }
  }

  // TODO(ager): This is inefficient but fast enough for now. Optimize it.
  private DartComment getDocComment(int position) {
    // Find closest comment before the position.
    DartComment closest = null;
    for (DartComment comment : dartDocComments) {
      if (position > comment.getSourceStart()) {
        if (closest == null) {
          closest = comment;
        } else {
          int bestDistance = position - closest.getSourceStart();
          int currentDistance = position - comment.getSourceStart();
          if (currentDistance < bestDistance) {
            closest = comment;
          }
        }
      }
    }
    if (closest == null) {
      return null;
    }
    // Check that there are only white space characters between the
    // end of the comment and the position.
    int commentEnd = closest.getSourceStart() + closest.getSourceLength();
    for (int i = commentEnd; i < position; i++) {
      if (!Character.isWhitespace(unitSource[i])) {
        return null;
      }
    }
    return closest;
  }

  // Names of anchor elements can only contain letters and
  // digits. Method names can contain other characters. If they do, a
  // simple mangling is used by just printing the code point value
  // instead.
  //
  // TODO(ager): Come up with something better for the mangling?
  private String anchorEscape(String string) {
    StringBuffer buffer = new StringBuffer();
    for (int i = 0; i < string.length(); i++) {
      char c = string.charAt(i);
      if (Character.isLetterOrDigit(c)) {
        buffer.append(c);
      } else {
        buffer.append(string.codePointAt(i));
      }
    }
    return buffer.toString();
  }

  // TODO(ager): This is inefficient. Use something else.
  private void escapeAndPrint(PrintStream stream, String string) {
    for (int i = 0; i < string.length(); i++) {
      char c = string.charAt(i);
      switch (c) {
        case '<':
        stream.print("&lt;");
        break;
      case '>':
        stream.print("&gt;");
        break;
      case '&':
        stream.print("&amp;");
        break;
      case '"':
        stream.print("&quot;");
        break;
      default:
        stream.print(c);
        break;
      }
    }
  }

  // TODO(ager): This is inefficient. Use something else.
  private void escapeAndAppendChar(StringBuffer buffer, char c) {
    switch (c) {
      case '<':
        buffer.append("&lt;");
        break;
      case '>':
        buffer.append("&gt;");
        break;
      case '&':
        buffer.append("&amp;");
        break;
      case '"':
        buffer.append("&quot;");
        break;
      default:
        buffer.append(c);
        break;
    }
  }

  private String commentToString(DartComment comment) {
    if (comment.isDartDoc()) {
      // Get rid of all the '*' and '/' in the beginning.
      StringBuffer buffer = new StringBuffer();
      int index = comment.getSourceStart();
      while (unitSource[index] != '/') {
        index++;
      }
      index += 3;  // '/**'
      while (index < unitSource.length) {
        while (unitSource[index] != '\n' && unitSource[index] != '*') {
          escapeAndAppendChar(buffer, unitSource[index++]);
        }
        // Check if a '*' is the end of comment.
        if (unitSource[index] == '*') {
          if (unitSource[index + 1] == '/') {
            return buffer.toString();
          } else {
            buffer.append(unitSource[index++]);
            continue;
          }
        }
        // Preserve newline chars.
        buffer.append('\n');
        while (unitSource[index] != '*') {
          index++;
        }
        index++;  // '*'
        if (unitSource[index] == '/') {
          assert((index + 1 - comment.getSourceStart()) == comment.getSourceLength());
          return buffer.toString();
        }
      }
    }
    return "";
  }

  private void printClassTypeParameters(ClassElement classElement) {
    List<? extends Type> typeParameters = classElement.getTypeParameters();
    if (typeParameters.size() > 0) {
      stream.print("&lt;");
      boolean first = true;
      for (Type type : typeParameters) {
        if (!first) {
          stream.print(",");
        } else {
          first = false;
        }
        escapeAndPrint(stream, type.getElement().getName());
      }
      stream.print("&gt;");
    }
  }

  private void printClassReference(ClassElement classElement) {
    String name = classElement.getName();
    LinkInformation linkInfo = new LinkInformation(classElement.getLibrary().getName(),
                                                   name,
                                                   name + "::" + name);
    links.add(linkInfo);
    stream.print(linkInfo.anchorReferenceStartTag());
    stream.print(name);
    printClassTypeParameters(classElement);
    stream.print("</a>");
  }

  /**
   * @param elm the element from which to start the resolution of the name.
   * @param name the name of the referred element.
   * @return <code>true</code> iff the element reference can be resolved and is printed.
   */
  private boolean printElementReference(Element elm, String name) {
    // For methods search the parameters.
    if (elm.getKind() == ElementKind.METHOD ||
        elm.getKind() == ElementKind.CONSTRUCTOR) {
      MethodElement method = (MethodElement) elm;
      for (VariableElement param : method.getParameters()) {
        if (param.getName().equals(name)) {
          assert(elm.getEnclosingElement().getKind() == ElementKind.CLASS);
          ClassElement enclosingClass = (ClassElement) elm.getEnclosingElement();
          String libraryName = enclosingClass.getLibrary().getName();
          String className = enclosingClass.getName();
          String elementReference =
              enclosingClass.getName() + "::" + anchorEscape(method.getName()) + "::" + name;
          LinkInformation linkInfo = new LinkInformation(libraryName, className, elementReference);
          links.add(linkInfo);
          stream.print("<code>");
          stream.print(linkInfo.anchorReferenceStartTag());
          stream.print(name);
          stream.print("</a></code>");
          return true;
        }
      }
    }

    // Search enclosing elements. For classes start with the element
    // itself to allow class comments to refer to members of the
    // class.
    EnclosingElement enclosing = elm.getEnclosingElement();
    if (elm.getKind() == ElementKind.CLASS) {
      enclosing = (ClassElement) elm;
    }
    while (enclosing != null) {
      if (printElementReferenceFromEnclosingElement(name, enclosing)) {
        return true;
      }
      enclosing = enclosing.getEnclosingElement();
    }
    return false;
  }


  /**
   * @param name the name of the referred element.
   * @param enclosing the enclosing element to start the resolution from.
   * @return <code>true</code> iff the element reference can be resolved and is printed.
   */
  private boolean printElementReferenceFromEnclosingElement(String name,
                                                            EnclosingElement enclosing) {
    Element localElement = enclosing.lookupLocalElement(name);
    if (localElement != null) {
      switch (localElement.getKind()) {
        case METHOD:
        case FIELD:
          assert(localElement.getEnclosingElement().getKind() == ElementKind.CLASS);
          ClassElement enclosingClass = (ClassElement) localElement.getEnclosingElement();
          if (enclosingClass != null) {
            String className = enclosingClass.getName();
            String elementReference = className + "::" + name;
            LinkInformation linkInfo = new LinkInformation(enclosingClass.getLibrary().getName(),
                                                           className,
                                                           elementReference);
            links.add(linkInfo);
            stream.print("<code>");
            stream.print(linkInfo.anchorReferenceStartTag());
            stream.print(name);
            stream.print("</a></code>");
            return true;
          } else {
            return false;
          }
        case CLASS:
          stream.print("<code>");
          printClassReference((ClassElement) localElement);
          stream.print("</code>");
          return true;
        default:
          return false;
      }
    }
    // For classes search type parameters, superclass and interfaces.
    if (enclosing.getKind() == ElementKind.CLASS) {
      ClassElement classElement = (ClassElement) enclosing;
      List<? extends Type> typeParameters = classElement.getTypeParameters();
      for (Type type : typeParameters) {
        if (type.getElement().getName().equals(name)) {
          String className = classElement.getName();
          String elementReference = className + "::" + className;
          LinkInformation linkInfo = new LinkInformation(classElement.getLibrary().getName(),
                                                         className,
                                                         elementReference);
          links.add(linkInfo);
          stream.print("<code>");
          stream.print(linkInfo.anchorReferenceStartTag());
          escapeAndPrint(stream, type.getElement().getName());
          stream.print("</a></code>");
          return true;
        }
      }
      InterfaceType supertype = classElement.getSupertype();
      if (supertype != null) {
        ClassElement superElement = supertype.getElement();
        if (printElementReferenceFromEnclosingElement(name, superElement)) {
          return true;
        }
      }
      List<InterfaceType> interfaces = classElement.getInterfaces();
      for (InterfaceType interfaceType : interfaces) {
        if (printElementReferenceFromEnclosingElement(name, interfaceType.getElement())) {
          return true;
        }
      }
    }
    return false;
  }

  private void printElementComment(Element elm) {
    DartComment comment = getDocComment(elm.getNode().getSourceStart());
    if (comment != null) {
      String rawComment = commentToString(comment);
      int length = rawComment.length();
      int index = 0;
      while (index < length) {
        int escapeIndex = rawComment.indexOf('[', index);
        if (escapeIndex == -1) {
          stream.print(rawComment.substring(index));
          break;
        } else {
          stream.print(rawComment.substring(index, escapeIndex));
          int escapeEndIndex = rawComment.indexOf(']', escapeIndex);
          if (escapeEndIndex == -1) {
            stream.print("[");
            index = escapeIndex + 1;
          } else {
            if (rawComment.charAt(escapeIndex + 1) == ':' &&
                rawComment.charAt(escapeEndIndex - 1) == ':') {
              // Pre-formatted code block [: code :].
              String code = rawComment.substring(escapeIndex + 2, escapeEndIndex - 1);
              stream.print("<code>");
              if (code.contains("\n")) {
                stream.println("<br>");
              }
              stream.print(code.replaceAll("\n", "<br>").replaceAll(" ", "&nbsp;"));
              if (code.contains("\n")) {
                stream.println("<br>");
              }
              stream.println("</code>\n");
            } else {
              // Element reference.
              String name = rawComment.substring(escapeIndex + 1, escapeEndIndex);
              if (!printElementReference(elm, name)) {
                stream.print("[");
                stream.print(name);
                stream.print("]");
              }
            }
            index = escapeEndIndex + 1;
          }
        }
      }
    }
  }

  @Override
  public Void visitMethodDefinition(DartMethodDefinition node) {
    documentToplevelMethod(node.getSymbol());
    return null;
  }

  @Override
  public Void visitField(DartField node) {
    documentToplevelField(node.getSymbol());
    return null;
  }

  @Override
  public Void visitClass(DartClass node) {
    documentClass(node.getSymbol());
    return null;
  }

  private void printFunctionTypeParameterList(FunctionType type, Element element) {
    List<? extends Type> paramTypes = type.getParameterTypes();
    stream.print("(");
    boolean first = true;
    for (Type paramType : paramTypes) {
      if (first) {
        first = false;
      } else {
        stream.print(", ");
      }
      if (!printElementReference(element, paramType.getElement().getName())) {
        escapeAndPrint(stream, paramType.getElement().getName());
      }
    }
    stream.print(")");
  }

  private void printMethodParameterList(MethodElement method, ClassElement classElement) {
    String className = classElement.getName();
    stream.print("(");
    boolean first = true;
    boolean foundOptionalParam = false;
    for (VariableElement param : method.getParameters()) {
      if (first) {
        first = false;
      } else {
        stream.print(", ");
      }
      if (!foundOptionalParam && param.isNamed()) {
        stream.print("[");
        foundOptionalParam = true;
      }
      // Print type. Only print return type for function types. The
      // argument types are left for after the parameter name.
      Type paramType = param.getType();
      boolean isFunctionType = paramType.getKind() == TypeKind.FUNCTION;
      Element paramTypeElement = paramType.getElement();
      if (isFunctionType) {
        FunctionType functionType = (FunctionType) paramType;
        Element returnTypeElement = functionType.getReturnType().getElement();
        if (!printElementReference(method, returnTypeElement.getName())) {
          escapeAndPrint(stream, returnTypeElement.getName());
        }
      } else {
        if (!printElementReference(method, paramTypeElement.getName())) {
          escapeAndPrint(stream, paramTypeElement.getName());
        }
      }
      stream.print(" ");
      String elementReference =
          className + "::" + anchorEscape(method.getName()) + "::" + param.getName();
      LinkInformation linkInfo = new LinkInformation(classElement.getLibrary().getName(),
                                                     className,
                                                     elementReference);
      anchors.add(linkInfo);
      stream.print(linkInfo.anchorStartTag());
      stream.print(param.getName());
      stream.print("</a>");
      if (isFunctionType) {
        FunctionType functionType = (FunctionType) paramType;
        printFunctionTypeParameterList(functionType, method);
      }
      if (foundOptionalParam && param.getDefaultValue() != null) {
        stream.print(" = ");
        stream.print(param.getDefaultValue().toString());
      }
    }
    if (foundOptionalParam) {
      stream.print("]");
    }
    stream.print(")");
  }

  private void printSupertype(ClassElement classElement) {
    InterfaceType supertype = classElement.getSupertype();
    if (supertype != null && !isPrivateName(supertype.getElement().getName())) {
      stream.println("\n<section class=\"supertype\">");
      stream.println("<h2>Supertype:</h2>");
      stream.print("<ul><li>");
      // If the supertype is defined in a library for which we are not generating
      // documentation do not attempt to link to the non-existent documentation.
      LibraryUnit supertypeLibraryUnit = supertype.getElement().getLibrary().getLibraryUnit();
      if (library == null || library.equals(supertypeLibraryUnit.getName())) {
        printClassReference(supertype.getElement());
      } else {
        stream.print(supertype.getElement().getName());
      }
      stream.println("</li></ul>");
      stream.println("</section>");
    }
  }

  private void printInterfaces(ClassElement classElement) {
    List<InterfaceType> interfaces = classElement.getInterfaces();
    List<ClassElement> nonPrivateInterfaces = new LinkedList<ClassElement>();
    for (InterfaceType type : interfaces) {
      ClassElement element = type.getElement();
      if (!isPrivateName(element.getName())) {
        nonPrivateInterfaces.add(element);
      }
    }
    if (nonPrivateInterfaces.size() > 0) {
      Collections.sort(nonPrivateInterfaces, new ElementNameComparator());
      stream.println("\n<section class=\"interfaces\">");
      stream.println("<h2>Implemented interfaces:</h2>");
      stream.println("<ul>");
      boolean first = true;
      for (ClassElement element : nonPrivateInterfaces) {
        stream.print("<li>");
        printClassReference(element);
        stream.println("</li>");
      }
      stream.println("</ul>");
      stream.println("</section>");
    }
  }

  private void printSubTypes(ClassElement classElement) {
    Set<InterfaceType> subtypes = classElement.getSubtypes();
    List<ClassElement> relevantSubtypes = new LinkedList<ClassElement>();
    // Filter out private subtypes. In addition, filter out subtypes not in the
    // library for which we are generating documentation.
    for (InterfaceType type : subtypes) {
      ClassElement element = type.getElement();
      if (!isPrivateName(element.getName())) {
        LibraryUnit subtypeLibraryUnit = element.getLibrary().getLibraryUnit();
        if (library == null || library.equals(subtypeLibraryUnit.getName())) {
          relevantSubtypes.add(element);
        }
      }
    }
    // Subtypes include the type itself.
    if (relevantSubtypes.size() > 1) {
      Collections.sort(relevantSubtypes, new ElementNameComparator());
      stream.println("\n<section class=\"subtypes\">");
      stream.println("<h2>Subtypes:</h2>");
      stream.println("<ul>");
      for (ClassElement subtype : relevantSubtypes) {
        // Don't list the class itself as a subtype.
        if (subtype == classElement) {
          continue;
        }
        stream.print("<li>");
        printClassReference(subtype);
        stream.println("</li>");
      }
      stream.println("</ul>");
      stream.println("</section>");
    }
  }

  private void documentFields(ClassElement classElement, List<FieldElement> fields) {
    if (fields.size() == 0) {
      return;
    }
    Collections.sort(fields, new ElementNameComparator());
    stream.println("<h2>Fields</h2>");
    stream.println("<dl>");
    for (FieldElement field : fields) {
      documentMemberField(field, classElement);
    }
    stream.println("</dl>");
  }

  private void documentConstructors(ClassElement classElement,
                                    List<ConstructorElement> constructors) {
    if (constructors.size() == 0) {
      return;
    }
    stream.println("<h2>Constructors</h2>");
    stream.println("<dl>");
    for (ConstructorElement constr : constructors) {
      documentConstructor(constr, classElement);
    }
    stream.println("</dl>");
  }

  private void documentMethods(ClassElement classElement, List<MethodElement> methods) {
    if (methods.size() == 0) {
      return;
    }
    Collections.sort(methods, new ElementNameComparator());
    stream.println("<h2>Methods</h2>");
    stream.println("<dl>");
    for (MethodElement method : methods) {
      documentMemberField(method, classElement);
    }
    stream.println("</dl>");
  }

  private void documentClass(ClassElement classElement) {
    String name = classElement.getName();
    if (isPrivateName(name)) {
      return;
    }
    String fileName = outputDirectory + File.separator + name + ".html";
    try {
      stream = new PrintStream(fileName);
    } catch (FileNotFoundException e) {
      throw new RuntimeException(e);
    }
    stream.println("<!DOCTYPE html>");
    stream.println("<html>");

    // Head.
    stream.println("\n<head>");
    stream.println("<meta charset=\"utf-8\">");
    stream.print("<title>");
    stream.print("Dart : Libraries : ");
    stream.print(library + " : ");
    stream.print(name);
    stream.println("</title>");
    stream.println("</head>");

    // Body.
    stream.println("\n<body>");
    
    stream.println("\n<header></header>\n");

    stream.print("<h1 id=\"title\">");
    if (classElement.isInterface()) {
      stream.print("interface ");
    } else {
      stream.print("class ");
    }
    LinkInformation linkInfo = new LinkInformation(classElement.getLibrary().getName(),
                                                   name,
                                                   name + "::" + name);
    anchors.add(linkInfo);
    stream.print(linkInfo.anchorStartTag());
    stream.print(name);
    printClassTypeParameters(classElement);
    stream.println("</a></h1>");
    
    stream.println("\n<section id=\"inheritance\">");
    printSupertype(classElement);
    printInterfaces(classElement);
    printSubTypes(classElement);
    stream.println("\n</section>");
    
    stream.println("\n<section id=\"summary\">");
    printElementComment(classElement);
    stream.println("</section>");
    
    List<FieldElement> fields = new ArrayList<FieldElement>(10);
    List<MethodElement> methods = new ArrayList<MethodElement>(10);
    List<ConstructorElement> constructors = new ArrayList<ConstructorElement>(10);
    
    getNonPrivateMembers(classElement, fields, methods, constructors);
    
    stream.println("\n<section id=\"fields\">");
    documentFields(classElement, fields);
    stream.println("</section>");

    stream.println("\n<section id=\"constructors\">");
    documentConstructors(classElement, constructors);
    stream.println("</section>");

    stream.println("\n<section id=\"methods\">");
    documentMethods(classElement, methods);
    stream.println("</section>");
    
    stream.println("\n<footer></footer>\n");
    stream.println("</body></html>");
  }

  private void getNonPrivateMembers(ClassElement classElement,
                                    List<FieldElement> fields,
                                    List<MethodElement> methods,
                                    List<ConstructorElement> constructors) {
    for (Element member : classElement.getMembers()) {
      String elementName = member.getName();
      if (isPrivateName(elementName)) {
        continue;
      }
      switch (member.getKind()) {
        case METHOD:
          methods.add((MethodElement) member);
          break;
        case FIELD:
          fields.add((FieldElement) member);
          break;
      }
    }
    
    List<ConstructorElement> constructorList = classElement.getConstructors();
    for (ConstructorElement c : constructorList) {
      if (isPrivateName(c.getName())) {
        continue;
      }
      constructors.add(c);
    }
  }

  private void documentMemberField(MethodElement method, ClassElement classElement) {
    String className = classElement.getName();
    stream.println("<dt>");
    stream.print("<code>");
    if (method.isStatic()) {
      stream.print("static ");
    }
    Type returnType = ((FunctionType) method.getType()).getReturnType();
    String returnTypeName = returnType.getElement().getName();
    if (!printElementReference(method, returnTypeName)) {
      escapeAndPrint(stream, returnTypeName);
    }
    stream.print(" ");

    String elementReference = className + "::" + anchorEscape(method.getName());
    LinkInformation linkInfo = new LinkInformation(classElement.getLibrary().getName(),
                                                   className,
                                                   elementReference);
    anchors.add(linkInfo);
    stream.print(linkInfo.anchorStartTag());
    escapeAndPrint(stream, method.getName());
    stream.print("</a>");
    printMethodParameterList(method, classElement);
    stream.print("</code>");
    stream.println("</dt>");
    stream.println("<dd>");
    printElementComment(method);
    stream.println("</dd>");
  }

  private void documentMemberField(FieldElement field, ClassElement classElement) {
    String className = classElement.getName();
    stream.println("<dt>");
    stream.print("<span class=\"field-type\"><code>");
    String typeName = field.getType().getElement().getName();
    if (!printElementReference(field, typeName)) {
      escapeAndPrint(stream, typeName);
    }
    stream.println("</code></span>");
    stream.print("<span class=\"field-name\"><code>");
    LinkInformation linkInfo = new LinkInformation(classElement.getLibrary().getName(),
                                                   className,
                                                   className + "::" + field.getName());
    anchors.add(linkInfo);
    stream.print(linkInfo.anchorStartTag());
    stream.println(field.getName());
    stream.println("</a></code></span>");
    stream.println("</dt>");
    stream.println("<dd>");
    printElementComment(field);
    stream.println("</dd>");
    
  }

  private void documentConstructor(ConstructorElement constr, ClassElement classElement) {
    String className = classElement.getName();
    stream.println("<dt>");
    stream.print("<code>");
    printClassReference(constr.getConstructorType());
    if (!constr.getName().isEmpty()) {
      stream.print(".");
      String elementReference = className + "::" + constr.getName();
      LinkInformation linkInfo = new LinkInformation(classElement.getLibrary().getName(),
                                                     className,
                                                     elementReference);
      anchors.add(linkInfo);
      stream.print(linkInfo.anchorStartTag());
      stream.print(constr.getName());
      stream.print("</a>");
    }
    printMethodParameterList(constr, classElement);
    stream.println("</code>");
    stream.println("</dt>");
    stream.println("<dd>");
    printElementComment(constr);
    stream.println("</dd>");
  }

  private void documentToplevelMethod(MethodElement method) {
  }

  private void documentToplevelField(FieldElement field) {
  }
}
