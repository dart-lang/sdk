/*
 * Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
 * for details. All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file.
 */

#ifndef RUNTIME_INCLUDE_DART_MIRRORS_API_H_
#define RUNTIME_INCLUDE_DART_MIRRORS_API_H_

#include "dart_api.h"


/**
 * Returns the simple name for the provided type.
 */
DART_EXPORT Dart_Handle Dart_TypeName(Dart_Handle type);

/**
 * Returns the qualified name for the provided type.
 */
DART_EXPORT Dart_Handle Dart_QualifiedTypeName(Dart_Handle type);

/**
 * Returns a list of the names of all functions or methods declared in
 * a library or class.
 *
 * \param target A library or class.
 *
 * \return If no error occurs, a list of strings is returned.
 *   Otherwise an error handle is returned.
 */
DART_EXPORT Dart_Handle Dart_GetFunctionNames(Dart_Handle target);

/**
 * Looks up a function or method declaration by name from a library or
 * class.
 *
 * \param target The library or class containing the function.
 * \param function_name The name of the function.
 *
 * \return If an error is encountered, returns an error handle.
 *   Otherwise returns a function handle if the function is found of
 *   Dart_Null() if the function is not found.
 */
DART_EXPORT Dart_Handle Dart_LookupFunction(Dart_Handle target,
                                            Dart_Handle function_name);

/**
 * Returns the name for the provided function or method.
 *
 * \return A valid string handle if no error occurs during the
 *   operation.
 */
DART_EXPORT Dart_Handle Dart_FunctionName(Dart_Handle function);

/**
 * Returns a handle to the owner of a function.
 *
 * The owner of an instance method or a static method is its defining
 * class. The owner of a top-level function is its defining
 * library. The owner of the function of a non-implicit closure is the
 * function of the method or closure that defines the non-implicit
 * closure.
 *
 * \return A valid handle to the owner of the function, or an error
 *   handle if the argument is not a valid handle to a function.
 */
DART_EXPORT Dart_Handle Dart_FunctionOwner(Dart_Handle function);

/**
 * Determines whether a function handle referes to a static function
 * of method.
 *
 * For the purposes of the embedding API, a top-level function is
 * implicitly declared static.
 *
 * \param function A handle to a function or method declaration.
 * \param is_static Returns whether the function or method is declared static.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_FunctionIsStatic(Dart_Handle function,
                                              bool* is_static);

/**
 * Determines whether a function handle referes to a constructor.
 *
 * \param function A handle to a function or method declaration.
 * \param is_static Returns whether the function or method is a constructor.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_FunctionIsConstructor(Dart_Handle function,
                                                   bool* is_constructor);
/* TODO(turnidge): Document behavior for factory constructors too. */

/**
 * Determines whether a function or method is a getter.
 *
 * \param function A handle to a function or method declaration.
 * \param is_static Returns whether the function or method is a getter.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_FunctionIsGetter(Dart_Handle function,
                                              bool* is_getter);

/**
 * Determines whether a function or method is a setter.
 *
 * \param function A handle to a function or method declaration.
 * \param is_static Returns whether the function or method is a setter.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_FunctionIsSetter(Dart_Handle function,
                                              bool* is_setter);

/**
 * Returns the name of a library as declared in the #library directive.
 */
DART_EXPORT Dart_Handle Dart_LibraryName(Dart_Handle library);

/**
 * Returns a list of the names of all classes and interfaces declared
 * in a library.
 *
 * \return If no error occurs, a list of strings is returned.
 *   Otherwise an error handle is returned.
 */
DART_EXPORT Dart_Handle Dart_LibraryGetClassNames(Dart_Handle library);

/**
 * Retrieves the function of a closure.
 *
 * \return A handle to the function of the closure, or an error handle if the
 *   argument is not a closure.
 */
DART_EXPORT Dart_Handle Dart_ClosureFunction(Dart_Handle closure);


#endif /* INCLUDE_DART_MIRRORS_API_H_ */ /* NOLINT */
