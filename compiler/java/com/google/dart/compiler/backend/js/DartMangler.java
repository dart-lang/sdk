// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.backend.js;

import com.google.dart.compiler.parser.Token;
import com.google.dart.compiler.resolver.ClassElement;
import com.google.dart.compiler.resolver.Element;
import com.google.dart.compiler.resolver.FieldElement;
import com.google.dart.compiler.resolver.LibraryElement;
import com.google.dart.compiler.resolver.MethodElement;

/**
 * Mangles dart identifiers so that they don't conflict with JavaScript identifiers.
 * This complements the JsScope infrastructure. The JsScope infrastructure deals with obfuscatable
 * identifiers, whereas the DartMangler deals with non-obfuscatable identifiers.
 *
 * @author floitsch@google.com (Florian Loitsch)
 */
public interface DartMangler {
  public static final String NEGATE_OPERATOR_NAME = "negate";

  /**
   * Mangles the given className, so that it does not clash with any global variable or other
   * mangled identifiers.
   * @return a String that identifies the class, and does not clash with any global variable.
   */
  public String mangleClassName(ClassElement classElement);
  @Deprecated
  public String mangleClassNameHack(LibraryElement library, String str);

  /**
   * Mangles the given constructor, so that it does not clash with any built-in JS property,
   * initializers, factories or other mangled fields.<br/>
   * The given LibraryElement is used if the constructor is library private.
   * @return a String that identifies the constructor, and does not clash with any global variable.
   */
  public String mangleConstructor(String constructorName, LibraryElement currentLibrary);

  /**
   * Returns a mangled identifier for the given method.
   */
  public String mangleNativeMethod(MethodElement methodElement);

  /**
   * Mangles the given initializer, so that it does not clash with any built-in JS property,
   * factories, constructors or other mangled fields.<br/>
   * The given LibraryElement is used if the initializer is library private.
   * @return a String that identifies the initializer, and does not clash with any global variable.
   */
  public String createInitializerSyntax(String constructorName, LibraryElement currentLibrary);

  /**
   * Mangles the given factory, so that it does not clash with any built-in JS property,
   * constructors, initializers or other mangled fields.<br/>
   * Note that factories may be unrelated to the containing class. A class <code>A</code> can
   * have a factory method returning an instance of class <code>B</code>. In this case
   * <code>className</code> equals <code>B</code>.<br>
   * The given LibraryElement is used if the factory is library private.
   *
   * @return a String that identifies the factory, and does not clash with any global variable.
   */
  public String createFactorySyntax(String className, String constructorName,
                                    LibraryElement currentlibrary);


  /**
   * <p>Returns a name for the given closure. The returned name does not
   * clash with any global variable or other mangled identifiers.</p>
   * The closure is identified by the closureIdentifier. Manglers are allowed to discard the
   * closureName completely.
   *
   * @param closureIdentifier must be a valid identifier of the form [a-zA-Z]+[0-9]*
   * @param closureName the closures short readable name. May be null.
   * @return a String that identifies the hoisted closure, and does not clash with any global
   * variable.
   */
  public String createHoistedFunctionName(Element holder,
                                          Element classMemberElement,
                                          String closureIdentifier,
                                          String closureName);

  /**
   * Mangles the given field, so that it does not clash with any built-in JS property or other
   * mangled fields or methods.<br/>
   * The given LibraryElement is used if the field is library private.
   * @return a String that identifies the member, and does not clash with built-in JS properties.
   */
  public String mangleField(FieldElement field, LibraryElement currentLibrary);

  /**
   * Mangles the given method, so that it does not clash with any built-in JS property or other
   * mangled fields or methods.<br/>
   * The given LibraryElement is used if the method is library private.
   * @return a String that identifies the member, and does not clash with built-in JS properties.
   */
  public String mangleMethod(MethodElement method, LibraryElement currentLibrary);
  public String mangleMethod(String methodName, LibraryElement currentLibrary);

  /**
   * Mangles the given method to its $named form.
   * @return a String that identifies the named form of the member.
   */
  public String mangleNamedMethod(MethodElement method, LibraryElement currentLibrary);
  public String mangleNamedMethod(String methodName, LibraryElement currentLibrary);

  /**
   * Mangles the given method, so that it does not clash with any built-in JS property or other
   * mangled fields or methods. This method is different than mangleMethod, as it returns
   * the fully qualified mangled name.
   * @return a String that identifies the entry, and does not clash with built-in JS properties.
   */
  public String mangleEntryPoint(MethodElement method, LibraryElement library);

  /**
   * @return the JavaScript property identifier for the given operation.
   */
  public String createOperatorSyntax(Token token);

  /**
   * @return the JavaScript property identifier for the given operation.
   */
  public String createOperatorSyntax(String operation);

  /**
   * @return the JavaScript getter property for the given member.
   */
  public String createGetterSyntax(String member, LibraryElement currentLibrary);
  public String createGetterSyntax(FieldElement member, LibraryElement currentLibrary);
  public String createGetterSyntax(MethodElement member, LibraryElement currentLibrary);

  /**
   * @return the JavaScript setter property for the given member.
   */
  public String createSetterSyntax(String member, LibraryElement currentLibrary);
  public String createSetterSyntax(FieldElement member, LibraryElement currentLibrary);
}
