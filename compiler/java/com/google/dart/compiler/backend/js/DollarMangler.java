// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.backend.js;

import com.google.common.collect.ImmutableSet;
import com.google.dart.compiler.InternalCompilerException;
import com.google.dart.compiler.ast.LibraryUnit;
import com.google.dart.compiler.parser.Token;
import com.google.dart.compiler.resolver.ClassElement;
import com.google.dart.compiler.resolver.Element;
import com.google.dart.compiler.resolver.ElementKind;
import com.google.dart.compiler.resolver.FieldElement;
import com.google.dart.compiler.resolver.LibraryElement;
import com.google.dart.compiler.resolver.MethodElement;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Set;

/**
 * Mangles classes and members (including constructors and operators).
 * These must be accessible from outside the compilation unit and must therefore have a
 * predictable mangling.
 *
 * <p>Functions, constructors and initializers to become top-level functions. They
 * cannot conflict with other members, but must not conflict with predefined JavaScript globals.
 *
 * <p>Other members (fields, operators, methods) are always accessed through an object. The mangler
 * only needs to guard against conflicts with predefined JavaScript properties (like "prototype"
 *  and "__proto__").
 */
public class DollarMangler implements DartMangler {
  // TODO(floitsch): get rid of the blacklisted libraries.
  // Libraries, where class-names must not include the library-name.
  private static final Set<String> BLACKLISTED_LIBRARIES = ImmutableSet.<String>of("corelib",
      "corelib_impl", "dom");

  // Helpers for getters/setters/operator name mangling.
  private static final String OPERATOR_SUFFIX = "$operator";
  private static final String GETTER_SUFFIX = "$getter";
  private static final String SETTER_SUFFIX = "$setter";
  private static final String FIELD_SUFFIX = "$field";
  private static final String METHOD_SUFFIX = "$member";
  private static final String NAMED_SUFFIX = "$named";
  private static final String CONSTRUCTOR_SUFFIX = "$Constructor";
  private static final String FACTORY_SUFFIX = "$Factory";
  private static final String INITIALIZER_SUFFIX = "$Initializer";

  private static final String CLASS_SUFFIX = "$Dart";
  private static final String HOISTED_METHOD_SUFFIX = "$Hoisted";
  private static final String HOISTED_OPERATOR_SUFFIX = "$HoistedOperator";
  private static final String HOISTED_CONSTRUCTOR_SUFFIX = "$HoistedConstructor";
  private static final String HOISTED_STATIC_SUFFIX = "$HoistedStatic";


  private static final String NATIVE_PREFIX = "native_";

  private boolean isLibraryPrivate(String id) {
    return (id.length() > 0) && (id.charAt(0) == '_');
  }

  private String attachSuffix(String name, String suffix,
                              boolean isLibraryPrivate, LibraryElement currentLibrary) {
    if (isLibraryPrivate) {
      return name + '$' + mangleLibraryName(currentLibrary) + suffix + '_';
    }
    return name + suffix;
  }

  private String attachSuffix(String name, String suffix, LibraryElement currentLibrary) {
    return attachSuffix(name, suffix, isLibraryPrivate(name), currentLibrary);
  }

  private String mangleLibraryName(LibraryElement element) {
    LibraryUnit library = element.getLibraryUnit();
    if (isInBlacklist(library)) {
      return "";
    }

    // TODO(floitsch): Replace this libraryName + md5(source) with something more enhanced.

    String libName = library.getName();
    if (libName == null || libName.isEmpty()) {
      libName = "unnamed";
    }

    // If the libraryName is a path, cut off everything before the last slash.
    int nameStart = libName.lastIndexOf('/') + 1;

    // add space for md5 + trailing '$' (and possible leading 'l').
    StringBuilder sb = new StringBuilder(libName.length() + 8);

    // see if we have a leading number, in which case need to prepend an alpha char
    final char startChar = libName.charAt(nameStart);
    if ('0' <= startChar && startChar <= '9') {
      sb.append('l');
    }
    sb.append(libName.substring(nameStart));

    // Replace all non-word chars ([^a-z_A-Z0-9]) with "_".
    replaceNonWordChars(sb);

    MessageDigest md;
    try {
      md = MessageDigest.getInstance("MD5");
    } catch (NoSuchAlgorithmException e) {
      throw new AssertionError("Could not find MD5 digest");
    }
    byte[] md5 = md.digest(library.getSource().getUri().toString().getBytes());
    // Only use the first 6 hex characters of the md5.
    for (int i = 0; i < 3; i++) {
      sb.append(Integer.toHexString((md5[i] & 0xf0) >> 4));
      sb.append(Integer.toHexString(md5[i] & 0xf));
    }

    sb.append("$");

    return sb.toString();
  }

  /*
   * Replace all non-word characters with an underscore
   */
  private void replaceNonWordChars(StringBuilder sb) {
    /*
     * This code is implemented as a more efficient implementation than using
     * String.replaceAll("\\W", "_")
     */
    final int len = sb.length();
    for (int idx = 0; idx < len; idx++) {
      final char ch = sb.charAt(idx);
      if (!((ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') || (ch >= '0' && ch <= '9'))) {
        sb.setCharAt(idx, '_');
      }
    }
  }

  @Override
  public String mangleClassName(ClassElement classElement) {
    return mangleClassNameHack(classElement.getLibrary(), classElement.getName());
  }

  @Override
  @Deprecated
  public String mangleClassNameHack(LibraryElement library, String className) {
    String libraryToken = library == null ? "" : mangleLibraryName(library);
    return libraryToken + className + CLASS_SUFFIX;
  }

  private boolean isInBlacklist(LibraryUnit libraryUnit) {
    if (libraryUnit.getName() == null) {
      return false;
    }
    if (BLACKLISTED_LIBRARIES.contains(libraryUnit.getName())) {
      return true;
    }

    // Libraries that use the new syntax (with no name) will have a URI for a name, e.g.:
    //   file://blah/blah/coreimpl.dart
    for (String name : BLACKLISTED_LIBRARIES) {
      if (libraryUnit.getName().endsWith(name)) {
        return true;
      }
    }
    return false;
  }

  @Override
  public String mangleConstructor(String constructorName, LibraryElement currentLibrary) {
    return attachSuffix(constructorName, CONSTRUCTOR_SUFFIX, currentLibrary);
  }

  @Override
  public String createInitializerSyntax(String constructorName, LibraryElement currentLibrary) {
    return attachSuffix(constructorName, INITIALIZER_SUFFIX, currentLibrary);
  }

  @Override
  public String createFactorySyntax(String className, String constructor,
                                    LibraryElement currentLibrary) {
    // We can't just return the constructor + suffix.
    // A class might have factories for different classes.
    String factoryName;
    if (constructor.equals("")) {
      factoryName = className + "$";
    } else {
      factoryName = className + "$" + constructor + "$" + className.length();
    }

    return attachSuffix(factoryName, FACTORY_SUFFIX, isLibraryPrivate(constructor), currentLibrary);
  }

  private boolean containsDollar(String str) {
    return str.indexOf('$') >= 0;
  }

  private String createHoistedFunctionName(String holderName,
                                           String elementName,
                                           String closureIdentifier,
                                           String closureName,
                                           String suffix) {
    assert closureIdentifier.indexOf('$') == -1;
    boolean containsDollar = containsDollar(holderName)
                             || containsDollar(elementName)
                             || (closureName != null && containsDollar(closureName));
    String result;
    if (closureName != null) {
      // Return a mangled id of the form:
      //   class$method$id$closure$$Hoisted, or
      //   class$method$id$closure$12_23_45$Hoisted  (if any of the strings contains dollars).
      result = holderName + "$" + elementName + "$" + closureIdentifier + "$" + closureName + "$";
      if (containsDollar) {
        result += holderName.length() + "_" + elementName.length() + "_"
            + closureIdentifier.length();
      }
    } else {
      // Return a mangled id of the form:
      //   class$method$id$$Hoisted, or
      //   class$method$id$12_23$Hoisted  (if any of the strings contains dollars).
      result = holderName + "$" + elementName + "$" + closureIdentifier + "$";
      if (containsDollar) {
        result += holderName.length() + "_" + holderName.length();
      }
    }
    return result + suffix;
  }

  @Override
  public String createHoistedFunctionName(Element holder,
                                          Element element,
                                          String closureIdentifier,
                                          String closureName) {
    String holderName = "";
    switch (ElementKind.of(holder)) {
      case CLASS:
        holderName = mangleClassName((ClassElement) holder);
        break;

      case LIBRARY:
        holderName = mangleLibraryName((LibraryElement) holder);
        break;
    }

    String name = element.getName();
    String suffix;
    switch (ElementKind.of(element)) {
      case METHOD:
        if (element.getModifiers().isOperator()) {
          suffix = HOISTED_OPERATOR_SUFFIX;
          if (!name.equals(NEGATE_OPERATOR_NAME)) {
            name = Token.lookup(name).name();
          }
        } else {
          suffix = HOISTED_METHOD_SUFFIX;
        }
        break;

      case CONSTRUCTOR:
        suffix = HOISTED_CONSTRUCTOR_SUFFIX;
        break;

      default:
        // Otherwise we are in a static initializer.
        suffix = HOISTED_STATIC_SUFFIX;
    }
    return createHoistedFunctionName(holderName, name, closureIdentifier, closureName,
                                     suffix);
  }

  private String createFieldOrMethodBaseName(Element field, boolean accessor) {
    String prefix = "";
    Element enclosing = field.getEnclosingElement();
    if (ElementKind.of(enclosing).equals(ElementKind.LIBRARY)) {
      prefix = mangleLibraryName((LibraryElement) enclosing);
    } else if (!accessor && field.getModifiers().isStatic()) {
      prefix = mangleClassName((ClassElement) enclosing);
    }
    return prefix + field.getName();
  }

  @Override
  public String mangleField(FieldElement field, LibraryElement currentLibrary) {
    return attachSuffix(createFieldOrMethodBaseName(field, false), FIELD_SUFFIX,
                        isLibraryPrivate(field.getName()), currentLibrary);
  }

  @Override
  public String mangleMethod(MethodElement method, LibraryElement currentLibrary) {
    String methodName = method.getName();
    if (method.getModifiers().isOperator()) {
      methodName = createOperatorSyntax(methodName);
    } else if (method.getModifiers().isGetter()) {
      methodName = createGetterSyntax(methodName, currentLibrary);
    } else if (method.getModifiers().isSetter()) {
      methodName = createSetterSyntax(methodName, currentLibrary);
    } else {
      methodName = attachSuffix(methodName, METHOD_SUFFIX, currentLibrary);
    }

    String prefix = "";
    if (ElementKind.of(method.getEnclosingElement()).equals(ElementKind.LIBRARY)) {
      prefix = mangleLibraryName((LibraryElement) method.getEnclosingElement());
    }
    return prefix + methodName;
  }

  @Override
  public String mangleNamedMethod(MethodElement method, LibraryElement currentLibrary) {
    // There can be no named shims for operators, getters, or setters.
    String methodName = method.getName();
    methodName = attachSuffix(methodName, NAMED_SUFFIX, currentLibrary);

    String prefix = "";
    if (ElementKind.of(method.getEnclosingElement()).equals(ElementKind.LIBRARY)) {
      prefix = mangleLibraryName((LibraryElement) method.getEnclosingElement());
    }
    return prefix + methodName;
  }

  @Override
  public String mangleNamedMethod(String methodName, LibraryElement currentLibrary) {
    return attachSuffix(methodName, NAMED_SUFFIX, currentLibrary);
  }

  @Override
  public String mangleEntryPoint(MethodElement method, LibraryElement library) {
    Element holder = method.getEnclosingElement();
    switch (ElementKind.of(holder)) {
      case CLASS:
        String mangledClassName = mangleClassName((ClassElement) holder);
        return mangledClassName + "." + mangleMethod(method.getName(), library);

      case LIBRARY:
        return mangleMethod(method, library);
    }
    throw new InternalCompilerException("Unknown entry point kind" + method);
  }

  @Override
  public String createGetterSyntax(FieldElement field, LibraryElement currentLibrary) {
    return attachSuffix(createFieldOrMethodBaseName(field, true), GETTER_SUFFIX,
                        isLibraryPrivate(field.getName()), currentLibrary);
  }

  @Override
  public String createGetterSyntax(MethodElement field, LibraryElement currentLibrary) {
    return attachSuffix(createFieldOrMethodBaseName(field, true), GETTER_SUFFIX,
                        isLibraryPrivate(field.getName()), currentLibrary);
  }

  @Override
  public String createSetterSyntax(FieldElement field, LibraryElement currentLibrary) {
    return attachSuffix(createFieldOrMethodBaseName(field, true), SETTER_SUFFIX,
                        isLibraryPrivate(field.getName()), currentLibrary);
  }

  @Override
  public String mangleMethod(String methodName, LibraryElement currentLibrary) {
    return attachSuffix(methodName, METHOD_SUFFIX, currentLibrary);
  }

  private static String getNegateOperator() {
    return NEGATE_OPERATOR_NAME + OPERATOR_SUFFIX;
  }

  @Override
  public String createOperatorSyntax(Token token) {
    return token.name() + OPERATOR_SUFFIX;
  }

  @Override
  public String createOperatorSyntax(String operation) {
    if (operation.equals(NEGATE_OPERATOR_NAME)) {
      return getNegateOperator();
    }
    return Token.lookup(operation).name() + OPERATOR_SUFFIX;
  }

  @Override
  public String createGetterSyntax(String member, LibraryElement currentLibrary) {
    return attachSuffix(member, GETTER_SUFFIX, currentLibrary);
  }

  @Override
  public String createSetterSyntax(String member, LibraryElement currentLibrary) {
    return attachSuffix(member, SETTER_SUFFIX, currentLibrary);
  }

  @Override
  public String mangleNativeMethod(MethodElement element) {
    String elementName = element.getName();
    String encodedName = null;
    if (element.getModifiers().isOperator()) {
      if ("negate".equals(elementName)) {
        encodedName = elementName;
      } else {
        encodedName = Token.lookup(elementName).name();
      }
    } else if (element.getModifiers().isGetter()) {
      encodedName = "get$" + elementName;
    } else if (element.getModifiers().isSetter()) {
      encodedName = "set$" + elementName;
    } else {
      encodedName = elementName;
    }
    String holderName = element.getEnclosingElement().getName();
    return NATIVE_PREFIX + holderName + "_" + encodedName;
  }
}
