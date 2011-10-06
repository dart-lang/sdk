// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.backend.doc;

import com.google.dart.compiler.DartCompilerContext;
import com.google.dart.compiler.DartSource;
import com.google.dart.compiler.LibrarySource;
import com.google.dart.compiler.ast.DartClass;
import com.google.dart.compiler.ast.DartField;
import com.google.dart.compiler.ast.DartMethodDefinition;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.ast.LibraryUnit;
import com.google.dart.compiler.backend.common.AbstractBackend;
import com.google.dart.compiler.resolver.ClassElement;
import com.google.dart.compiler.resolver.CoreTypeProvider;
import com.google.dart.compiler.resolver.FieldElement;
import com.google.dart.compiler.resolver.MethodElement;
import com.google.dart.compiler.type.Type;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.PrintStream;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Generate documentation based on DartDoc comments.
 */
public class DartDocumentationGenerator extends AbstractBackend {

  private String outputDirectory;
  private String library;
  private PrintStream stream;
  private Set<LinkInformation> anchors;
  private Set<LinkInformation> links;

  public DartDocumentationGenerator(String out, String lib) {
    library = lib;
    outputDirectory = out;
    anchors = new HashSet<LinkInformation>();
    links = new HashSet<LinkInformation>();
  }

  private void generate(DartUnit unit) {
    LibraryUnit lib = unit.getLibrary();
    if (library == null || library.equals(lib.getName())) {
      DartDocumentationVisitor visitor =
          new DartDocumentationVisitor(outputDirectory,
                                       library,
                                       unit.getComments(),
                                       anchors,
                                       links);
      visitor.initialize(unit);
      visitor.visitNode(unit);
    }
  }

  private boolean isPrivateName(String name) {
    return name.charAt(0) == '_';
  }

  private void setPrintStream(String name) {
    String fileName = outputDirectory + File.separator + name + ".html";
    try {
      stream = new PrintStream(fileName);
    } catch (FileNotFoundException e) {
      throw new RuntimeException(e);
    }
  }

  private void printLibraryMembers(LibraryUnit lib) {
    List<ClassElement> classes = new ArrayList<ClassElement>(10);
    List<ClassElement> exceptions = new ArrayList<ClassElement>(10);
    List<FieldElement> fields = new ArrayList<FieldElement>(10);
    List<MethodElement> methods = new ArrayList<MethodElement>(10);
    for (DartNode dartNode : lib.getTopLevelNodes()) {
      if (dartNode instanceof DartClass) {
        DartClass dartClass = (DartClass) dartNode;
        ClassElement classElement = dartClass.getSymbol();
        String name = classElement.getName();
        if (isPrivateName(name)) {
          continue;
        }
        if (name.contains("Exception")) {
          exceptions.add(classElement);
        } else {
          classes.add(classElement);
        }
      } else if (dartNode instanceof DartField) {
        DartField dartField = (DartField) dartNode;
        FieldElement fieldElement = dartField.getSymbol();
        String name = fieldElement.getName();
        if (!isPrivateName(name)) {
          fields.add(fieldElement);
        }
      } else if (dartNode instanceof DartMethodDefinition) {
        DartMethodDefinition dartMethod = (DartMethodDefinition) dartNode;
        MethodElement methodElement = dartMethod.getSymbol();
        String name = methodElement.getName();
        if (!isPrivateName(name)) {
          methods.add(methodElement);
        }
      }
    }
    if (classes.size() > 0 || exceptions.size() > 0) {
      Collections.sort(classes, new ElementNameComparator());
      Collections.sort(exceptions, new ElementNameComparator());
      stream.println("\n<section id=\"classes-overview\">");
      stream.println("<h3>Classes and interfaces</h3>");
      stream.print("<ul>");
      printClassLibraryMembers(classes);
      printClassLibraryMembers(exceptions);
      stream.println("</ul>");
      stream.println("</section>");
    }
    if (methods.size() > 0) {
      Collections.sort(methods, new ElementNameComparator());
      stream.println("\n<section id=\"methods-overview\">");
      stream.println("<h3>Top-level methods</h3>");
      stream.print("<ul>");
      for (MethodElement methodElement : methods) {
        String name = methodElement.getName();
        // TODO(ager): Generate link to the right place once global methods are documented.
        stream.print("<li>");
        stream.print(name);
        stream.print("</li>");
      }
      stream.println("</ul>");
      stream.println("</section>");
    }
    if (fields.size() > 0) {
      Collections.sort(fields, new ElementNameComparator());
      stream.println("\n<section id=\"fields-overview\">");
      stream.println("<h3>Top-level fields</h3>");
      stream.print("<ul>");
      for (FieldElement fieldElement : fields) {
        String name = fieldElement.getName();
        // TODO(ager): Generate link to the right place once global fields are documented.
        stream.print("<li>");
        stream.print(name);
        stream.print("</li>");
      }
      stream.println("</ul>");
      stream.println("</section>");
    }
  }

  private void printClassLibraryMembers(List<ClassElement> classes) {
    for (ClassElement classElement : classes) {
      String name = classElement.getName();
      stream.print("<li>");
      LinkInformation linkInfo = new LinkInformation(classElement.getLibrary().getName(),
                                                     name,
                                                     name + "::" + name);
      links.add(linkInfo);
      stream.print(linkInfo.anchorReferenceStartTag());
      stream.print(name);
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
          stream.print(type.getElement().getName());
        }
        stream.print("&gt;");
      }
      stream.print("</a>");
      stream.print("</li>");
    }
  }

  @Override
  public boolean isOutOfDate(DartSource src, DartCompilerContext context) {
    return true;
  }

  @Override
  public void compileUnit(DartUnit unit, DartSource src, DartCompilerContext context,
                          CoreTypeProvider typeProvider) {
    generate(unit);
  }

  @Override
  public void packageApp(LibrarySource app, Collection<LibraryUnit> libraries,
                         DartCompilerContext context, CoreTypeProvider typeProvider) {
    // Generate index.html containing a list of libraries and their classes.
    setPrintStream("index");
    stream.println("<!DOCTYPE html>");
    stream.println("<html>");
    stream.println("<head>");
    stream.println("<meta charset=\"utf-8\">");
    stream.print("<title>");
    stream.print("Dart : Libraries");
    stream.println("</title>");
    stream.print("</head>");
    
    stream.println("<body>");
    stream.println("\n<header></header>\n");
  
    stream.println("<h1 id=\"title\">Library Reference</h1>");
    
    stream.println("<section id=\"libraries-overview\">");
    for (LibraryUnit lib : libraries) {
      if (library == null || library.equals(lib.getName())) {
        if (lib.getTopLevelNodes().size() > 0) {
          stream.print("<h2>");
          stream.print(lib.getName());
          stream.println("</h2>");
          printLibraryMembers(lib);
        }
      }
    }
    stream.println("</section>");
    stream.println("\n<footer></footer>\n");
    stream.println("</body></html>");
    // Validate the generated links.
    for (LinkInformation linkInfo : links) {
      if (!anchors.contains(linkInfo)) {
        System.out.print("Warning: link to element without anchor: ");
        System.out.println(linkInfo.className + "::" + linkInfo.elementName);
      }
    }
  }

  @Override
  public String getAppExtension() {
    throw new UnsupportedOperationException();
  }

  @Override
  public String getSourceMapExtension() {
    throw new UnsupportedOperationException();
  }
}
