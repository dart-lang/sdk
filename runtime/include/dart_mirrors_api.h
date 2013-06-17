/*
 * Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
 * for details. All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file.
 */

#ifndef INCLUDE_DART_MIRRORS_API_H_
#define INCLUDE_DART_MIRRORS_API_H_

#include "include/dart_api.h"

/*
 * =================================
 * Classes and Interfaces Reflection
 * =================================
 */

/**
 * Returns the class name for the provided class or interface.
 */
DART_EXPORT Dart_Handle Dart_ClassName(Dart_Handle clazz);

/**
 * Returns the library for the provided class or interface.
 */
DART_EXPORT Dart_Handle Dart_ClassGetLibrary(Dart_Handle clazz);

/**
 * Returns the number of interfaces directly implemented by some class
 * or interface.
 *
 * TODO(turnidge): Finish documentation.
 */
DART_EXPORT Dart_Handle Dart_ClassGetInterfaceCount(Dart_Handle clazz,
                                                    intptr_t* count);

/**
 * Returns the interface at some index in the list of interfaces some
 * class or inteface.
 *
 * TODO(turnidge): Finish documentation.
 */
DART_EXPORT Dart_Handle Dart_ClassGetInterfaceAt(Dart_Handle clazz,
                                                 intptr_t index);

/**
 * Is this class defined by a typedef?
 *
 * Typedef definitions from the main program are represented as a
 * special kind of class handle.  See Dart_ClassGetTypedefReferent.
 *
 * TODO(turnidge): Finish documentation.
 */
DART_EXPORT bool Dart_ClassIsTypedef(Dart_Handle clazz);

/**
 * Returns a handle to the type to which a typedef refers.
 *
 * It is an error to call this function on a handle for which
 * Dart_ClassIsTypedef is not true.
 *
 * TODO(turnidge): Finish documentation.
 */
DART_EXPORT Dart_Handle Dart_ClassGetTypedefReferent(Dart_Handle clazz);

/**
 * Does this class represent the type of a function?
 */
DART_EXPORT bool Dart_ClassIsFunctionType(Dart_Handle clazz);

/**
 * Returns a function handle representing the signature associated
 * with a function type.
 *
 * The return value is a function handle (See Dart_IsFunction, etc.).
 *
 * TODO(turnidge): Finish documentation.
 */
DART_EXPORT Dart_Handle Dart_ClassGetFunctionTypeSignature(Dart_Handle clazz);


/*
 * =================================
 * Function and Variables Reflection
 * =================================
 */

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
 * Determines whether a function handle refers to an abstract method.
 *
 * \param function A handle to a function or method declaration.
 * \param is_static Returns whether the handle refers to an abstract method.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_FunctionIsAbstract(Dart_Handle function,
                                                bool* is_abstract);

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
 * Returns the return type of a function.
 *
 * \return A valid handle to a type or an error handle if the argument
 *   is not valid.
 */
DART_EXPORT Dart_Handle Dart_FunctionReturnType(Dart_Handle function);

/**
 * Determines the number of required and optional parameters.
 *
 * \param function A handle to a function or method declaration.
 * \param fixed_param_count Returns the number of required parameters.
 * \param opt_param_count Returns the number of optional parameters.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_FunctionParameterCounts(
  Dart_Handle function,
  int64_t* fixed_param_count,
  int64_t* opt_param_count);

/**
 * Returns a handle to the type of a function parameter.
 *
 * \return A valid handle to a type or an error handle if the argument
 *   is not valid.
 */
DART_EXPORT Dart_Handle Dart_FunctionParameterType(Dart_Handle function,
                                                   int parameter_index);

/**
 * Returns a list of the names of all variables declared in a library
 * or class.
 *
 * \param target A library or class.
 *
 * \return If no error occurs, a list of strings is returned.
 *   Otherwise an error handle is returned.
 */
DART_EXPORT Dart_Handle Dart_GetVariableNames(Dart_Handle target);

/**
 * Looks up a variable declaration by name from a library or class.
 *
 * \param target The library or class containing the variable.
 * \param variable_name The name of the variable.
 *
 * \return If an error is encountered, returns an error handle.
 *   Otherwise returns a variable handle if the variable is found or
 *   Dart_Null() if the variable is not found.
 */
DART_EXPORT Dart_Handle Dart_LookupVariable(Dart_Handle target,
                                            Dart_Handle variable_name);

/**
 * Returns the name for the provided variable.
 */
DART_EXPORT Dart_Handle Dart_VariableName(Dart_Handle variable);

/**
 * Determines whether a variable is declared static.
 *
 * For the purposes of the embedding API, a top-level variable is
 * implicitly declared static.
 *
 * \param variable A handle to a variable declaration.
 * \param is_static Returns whether the variable is declared static.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_VariableIsStatic(Dart_Handle variable,
                                              bool* is_static);

/**
 * Determines whether a variable is declared final.
 *
 * \param variable A handle to a variable declaration.
 * \param is_final Returns whether the variable is declared final.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_VariableIsFinal(Dart_Handle variable,
                                             bool* is_final);

/**
 * Returns the type of a variable.
 *
 * \return A valid handle to a type of or an error handle if the
 *   argument is not valid.
 */
DART_EXPORT Dart_Handle Dart_VariableType(Dart_Handle function);

/**
 * Returns a list of the names of all type variables declared in a class.
 *
 * The type variables list preserves the original declaration order.
 *
 * \param clazz A class.
 *
 * \return If no error occurs, a list of strings is returned.
 *   Otherwise an error handle is returned.
 */
DART_EXPORT Dart_Handle Dart_GetTypeVariableNames(Dart_Handle clazz);

/**
 * Looks up a type variable declaration by name from a class.
 *
 * \param clazz The class containing the type variable.
 * \param variable_name The name of the type variable.
 *
 * \return If an error is encountered, returns an error handle.
 *   Otherwise returns a type variable handle if the type variable is
 *   found or Dart_Null() if the type variable is not found.
 */
DART_EXPORT Dart_Handle Dart_LookupTypeVariable(Dart_Handle clazz,
                                                Dart_Handle type_variable_name);

/**
 * Returns the name for the provided type variable.
 */
DART_EXPORT Dart_Handle Dart_TypeVariableName(Dart_Handle type_variable);

/**
 * Returns the owner of a function.
 *
 * The owner of a type variable is its defining class.
 *
 * \return A valid handle to the owner of the type variable, or an error
 *   handle if the argument is not a valid handle to a type variable.
 */
DART_EXPORT Dart_Handle Dart_TypeVariableOwner(Dart_Handle type_variable);

/**
 * Returns the upper bound of a type variable.
 *
 * The upper bound of a type variable is ...
 *
 * \return A valid handle to a type, or an error handle if the
 *   argument is not a valid handle.
 */
DART_EXPORT Dart_Handle Dart_TypeVariableUpperBound(Dart_Handle type_variable);
/* TODO(turnidge): Finish documentation. */


/*
 * ====================
 * Libraries Reflection
 * ====================
 */

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


/*
 * ===================
 * Closures Reflection
 * ===================
 */

/**
 * Retrieves the function of a closure.
 *
 * \return A handle to the function of the closure, or an error handle if the
 *   argument is not a closure.
 */
DART_EXPORT Dart_Handle Dart_ClosureFunction(Dart_Handle closure);

/*
 * ===================
 * Metadata Reflection
 * ===================
 */

/**
 * Get metadata associated with an object.
 *
 * \param obj Object for which the metadata is retrieved.
 *
 * \return If no error occurs, returns an array of metadata values.
 *   Returns an empty array if there is no metadata for the object.
 *   Returns an error if the evaluation of the metadata expressions fails.
 *
 */
DART_EXPORT Dart_Handle Dart_GetMetadata(Dart_Handle obj);

#endif  /* INCLUDE_DART_MIRRORS_API_H_ */  /* NOLINT */
