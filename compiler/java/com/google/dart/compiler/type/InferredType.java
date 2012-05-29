// Copyright (c) 2012, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.type;

import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;

/**
 * Marker interface for {@link Type} which means that this {@link Type} was not specified by user,
 * but instead inferred from context.
 */
public interface InferredType {
  public static class Helper {
    /**
     * @return the mix of the given {@link Type} interface and {@link InferredType}.
     */
    public static Type make(final Type type) {
      if (type instanceof InterfaceType) {
        return (Type) Proxy.newProxyInstance(type.getClass().getClassLoader(), new Class<?>[] {
            InterfaceType.class,
            InferredType.class}, new InvocationHandler() {
          @Override
          public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
            return method.invoke(type, args);
          }
        });
      }
      return type;
    }
  }
}
