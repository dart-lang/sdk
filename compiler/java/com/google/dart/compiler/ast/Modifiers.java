// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

/**
 * Methods for working with modifier bits on various nodes.
 */
public class Modifiers {

  public static final Modifiers NONE = new Modifiers();

  // Sorting this list would be confusing when adding new modifiers,
  // as each one depends on the previously declared one.
  // TODO(ngeoffray): Make this an enum.
  private static final int FLAG_STATIC = 1;
  private static final int FLAG_CONSTANT = FLAG_STATIC << 1;
  private static final int FLAG_FACTORY = FLAG_CONSTANT << 1;
  private static final int FLAG_ABSTRACT = FLAG_FACTORY << 1;
  private static final int FLAG_GETTER = FLAG_ABSTRACT << 1;
  private static final int FLAG_SETTER = FLAG_GETTER << 1;
  private static final int FLAG_OPERATOR = FLAG_SETTER << 1;
  private static final int FLAG_NATIVE = FLAG_OPERATOR << 1;
  private static final int FLAG_INLINABLE = FLAG_NATIVE << 1;
  private static final int FLAG_ABSTRACTFIELD = FLAG_INLINABLE << 1;
  private static final int FLAG_REDIRECTEDCONSTRUCTOR = FLAG_ABSTRACTFIELD << 1;
  private static final int FLAG_FINAL = FLAG_REDIRECTEDCONSTRUCTOR << 1;
  private static final int FLAG_OPTIONAL = FLAG_FINAL << 1;
  private static final int FLAG_NAMED = FLAG_OPTIONAL << 1;
  private static final int FLAG_INITIALIZED = FLAG_NAMED << 1;
  private static final int FLAG_EXTERNAL = FLAG_INITIALIZED << 1;

  private final int value;

  public boolean isStatic() { return is(FLAG_STATIC); }
  public boolean isConstant() { return is(FLAG_CONSTANT); }
  public boolean isFactory() { return is(FLAG_FACTORY); }
  public boolean isAbstract() { return is(FLAG_ABSTRACT); }
  public boolean isGetter() { return is(FLAG_GETTER); }
  public boolean isSetter() { return is(FLAG_SETTER); }
  public boolean isOperator() { return is(FLAG_OPERATOR); }
  public boolean isNative() { return is(FLAG_NATIVE); }
  public boolean isInlinable() { return is(FLAG_INLINABLE); }
  public boolean isAbstractField() { return is(FLAG_ABSTRACTFIELD); }
  public boolean isRedirectedConstructor() { return is(FLAG_REDIRECTEDCONSTRUCTOR); }
  public boolean isFinal() { return is(FLAG_FINAL); }
  public boolean isOptional() { return is(FLAG_OPTIONAL); }
  public boolean isNamed() { return is(FLAG_NAMED); }
  public boolean isInitialized() { return is(FLAG_INITIALIZED); }
  public boolean isExternal() { return is(FLAG_EXTERNAL); }

  public Modifiers makeStatic() { return make(FLAG_STATIC); }
  public Modifiers makeConstant() { return make(FLAG_CONSTANT); }
  public Modifiers makeFactory() { return make(FLAG_FACTORY); }
  public Modifiers makeAbstract() { return make(FLAG_ABSTRACT); }
  public Modifiers makeGetter() { return make(FLAG_GETTER); }
  public Modifiers makeSetter() { return make(FLAG_SETTER); }
  public Modifiers makeOperator() { return make(FLAG_OPERATOR); }
  public Modifiers makeNative() { return make(FLAG_NATIVE); }
  public Modifiers makeInlinable() { return make(FLAG_INLINABLE); }
  public Modifiers makeAbstractField() { return make(FLAG_ABSTRACTFIELD); }
  public Modifiers makeRedirectedConstructor() { return make(FLAG_REDIRECTEDCONSTRUCTOR); }
  public Modifiers makeFinal() { return make(FLAG_FINAL); }
  public Modifiers makeOptional() { return make(FLAG_OPTIONAL); }
  public Modifiers makeNamed() { return make(FLAG_NAMED); }
  public Modifiers makeInitialized() { return make(FLAG_INITIALIZED); }
  public Modifiers makeExternal() { return make(FLAG_EXTERNAL); }

  public Modifiers removeStatic() { return remove(FLAG_STATIC); }
  public Modifiers removeConstant() { return remove(FLAG_CONSTANT); }
  public Modifiers removeFactory() { return remove(FLAG_FACTORY); }
  public Modifiers removeAbstract() { return remove(FLAG_ABSTRACT); }
  public Modifiers removeGetter() { return remove(FLAG_GETTER); }
  public Modifiers removeSetter() { return remove(FLAG_SETTER); }
  public Modifiers removeOperator() { return remove(FLAG_OPERATOR); }
  public Modifiers removeNative() { return remove(FLAG_NATIVE); }
  public Modifiers removeInlinable() { return remove(FLAG_INLINABLE); }
  public Modifiers removeAbstractField() { return remove(FLAG_ABSTRACTFIELD); }
  public Modifiers removeRedirectedConstructor() { return remove(FLAG_REDIRECTEDCONSTRUCTOR); }
  public Modifiers removeFinal() { return remove(FLAG_FINAL); }
  public Modifiers removeOptional() { return remove(FLAG_OPTIONAL); }
  public Modifiers removeNamed() { return remove(FLAG_NAMED); }
  public Modifiers removeIniitalized() { return remove(FLAG_INITIALIZED); }
  public Modifiers removeExternal() { return remove(FLAG_EXTERNAL); }

  public boolean is(int flag) {
    return (value & flag) != 0;
  }

  public boolean is(Modifiers modifier) {
    return is(modifier.value);
  }

  public Modifiers make(int flag) {
    return new Modifiers(value | flag);
  }

  public Modifiers remove(int flag) {
    return new Modifiers(value & ~flag);
  }

  private Modifiers() {
    this.value = 0;
  }

  private Modifiers(int value) {
    this.value = value;
  }
}
