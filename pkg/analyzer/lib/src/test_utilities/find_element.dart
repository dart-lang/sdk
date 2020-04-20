// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/test_utilities/function_ast_visitor.dart';

/// Helper for finding elements declared in the resolved [unit].
class FindElement extends _FindElementBase {
  final CompilationUnit unit;

  FindElement(this.unit);

  @override
  CompilationUnitElement get unitElement => unit.declaredElement;

  ExportElement export(String targetUri) {
    ExportElement result;

    for (var export in unitElement.library.exports) {
      var exportedUri = export.exportedLibrary.source.uri.toString();
      if (exportedUri == targetUri) {
        if (result != null) {
          throw StateError('Not unique: $targetUri');
        }
        result = export;
      }
    }

    if (result != null) {
      return result;
    }
    throw StateError('Not found: $targetUri');
  }

  FieldFormalParameterElement fieldFormalParameter(String name) {
    return parameter(name) as FieldFormalParameterElement;
  }

  FunctionElement function(String name) {
    for (var function in unitElement.functions) {
      if (function.name == name) {
        return function;
      }
    }
    throw StateError('Not found: $name');
  }

  ImportElement import(String targetUri) {
    ImportElement importElement;

    for (var import in unitElement.library.imports) {
      var importedUri = import.importedLibrary.source.uri.toString();
      if (importedUri == targetUri) {
        if (importElement != null) {
          throw StateError('Not unique: $targetUri');
        }
        importElement = import;
      }
    }

    if (importElement != null) {
      return importElement;
    }
    throw StateError('Not found: $targetUri');
  }

  ImportFindElement importFind(String targetUri) {
    var import = this.import(targetUri);
    return ImportFindElement(import);
  }

  FunctionElement localFunction(String name) {
    FunctionElement result;

    unit.accept(FunctionAstVisitor(
      functionDeclarationStatement: (node) {
        var element = node.functionDeclaration.declaredElement;
        if (element is FunctionElement) {
          if (result != null) {
            throw StateError('Not unique: $name');
          }
          result = element;
        }
      },
    ));

    if (result == null) {
      throw StateError('Not found: $name');
    }
    return result;
  }

  LocalVariableElement localVar(String name) {
    LocalVariableElement result;

    void updateResult(Element element) {
      if (element is LocalVariableElement && element.name == name) {
        if (result != null) {
          throw StateError('Not unique: $name');
        }
        result = element;
      }
    }

    unit.accept(FunctionAstVisitor(
      declaredIdentifier: (node) {
        updateResult(node.declaredElement);
      },
      simpleIdentifier: (node) {
        if (node.parent is CatchClause) {
          updateResult(node.staticElement);
        }
      },
      variableDeclaration: (node) {
        updateResult(node.declaredElement);
      },
    ));

    if (result == null) {
      throw StateError('Not found: $name');
    }
    return result;
  }

  ParameterElement parameter(String name) {
    ParameterElement result;

    void findIn(List<ParameterElement> parameters) {
      for (var parameter in parameters) {
        if (parameter.name == name) {
          if (result != null) {
            throw StateError('Not unique: $name');
          }
          result = parameter;
        }
      }
    }

    void findInExecutables(List<ExecutableElement> executables) {
      for (var executable in executables) {
        findIn(executable.parameters);
      }
    }

    findInExecutables(unitElement.accessors);
    findInExecutables(unitElement.functions);

    for (var function in unitElement.functionTypeAliases) {
      findIn(function.function.parameters);
    }

    for (var extension_ in unitElement.extensions) {
      findInExecutables(extension_.accessors);
      findInExecutables(extension_.methods);
    }

    for (var mixin in unitElement.mixins) {
      findInExecutables(mixin.accessors);
      findInExecutables(mixin.constructors);
      findInExecutables(mixin.methods);
    }

    for (var class_ in unitElement.types) {
      findInExecutables(class_.accessors);
      findInExecutables(class_.constructors);
      findInExecutables(class_.methods);
    }

    unit.accept(
      FunctionAstVisitor(functionDeclarationStatement: (node) {
        var functionElement = node.functionDeclaration.declaredElement;
        findIn(functionElement.parameters);
      }),
    );

    if (result != null) {
      return result;
    }
    throw StateError('Not found: $name');
  }

  PrefixElement prefix(String name) {
    for (var import_ in unitElement.library.imports) {
      var prefix = import_.prefix;
      if (prefix?.name == name) {
        return prefix;
      }
    }
    throw StateError('Not found: $name');
  }

  TypeParameterElement typeParameter(String name) {
    TypeParameterElement result;

    void findIn(List<TypeParameterElement> typeParameters) {
      for (var typeParameter in typeParameters) {
        if (typeParameter.name == name) {
          if (result != null) {
            throw StateError('Not unique: $name');
          }
          result = typeParameter;
        }
      }
    }

    void findInClass(ClassElement class_) {
      findIn(class_.typeParameters);
      for (var method in class_.methods) {
        findIn(method.typeParameters);
      }
    }

    for (var type in unitElement.functionTypeAliases) {
      findIn(type.typeParameters);
      if (type is GenericTypeAliasElement) {
        findIn(type.function.typeParameters);
      }
    }

    for (var class_ in unitElement.types) {
      findInClass(class_);
    }

    for (var mixin in unitElement.mixins) {
      findInClass(mixin);
    }

    if (result != null) {
      return result;
    }
    throw StateError('Not found: $name');
  }
}

/// Helper for searching imported elements.
class ImportFindElement extends _FindElementBase {
  final ImportElement import;

  ImportFindElement(this.import);

  LibraryElement get importedLibrary => import.importedLibrary;

  PrefixElement get prefix => import.prefix;

  @override
  CompilationUnitElement get unitElement {
    return importedLibrary.definingCompilationUnit;
  }
}

abstract class _FindElementBase {
  CompilationUnitElement get unitElement;

  ClassElement class_(String name) {
    for (var class_ in unitElement.types) {
      if (class_.name == name) {
        return class_;
      }
    }
    throw StateError('Not found: $name');
  }

  ClassElement classOrMixin(String name) {
    for (var class_ in unitElement.types) {
      if (class_.name == name) {
        return class_;
      }
    }
    for (var mixin in unitElement.mixins) {
      if (mixin.name == name) {
        return mixin;
      }
    }
    throw StateError('Not found: $name');
  }

  ConstructorElement constructor(String name, {String of}) {
    assert(name != '');
    ConstructorElement result;
    for (var class_ in unitElement.types) {
      if (of == null || class_.name == of) {
        for (var constructor in class_.constructors) {
          if (constructor.name == name) {
            if (result != null) {
              throw StateError('Not unique: $name');
            }
            result = constructor;
          }
        }
      }
    }
    if (result != null) {
      return result;
    }
    throw StateError('Not found: $name');
  }

  ClassElement enum_(String name) {
    for (var enum_ in unitElement.enums) {
      if (enum_.name == name) {
        return enum_;
      }
    }
    throw StateError('Not found: $name');
  }

  ExtensionElement extension_(String name) {
    for (var extension_ in unitElement.extensions) {
      if (extension_.name == name) {
        return extension_;
      }
    }
    throw StateError('Not found: $name');
  }

  FieldElement field(String name, {String of}) {
    FieldElement result;

    void findIn(List<FieldElement> fields) {
      for (var field in fields) {
        if (field.name == name) {
          if (result != null) {
            throw StateError('Not unique: $name');
          }
          result = field;
        }
      }
    }

    for (var enum_ in unitElement.enums) {
      if (of != null && enum_.name != of) {
        continue;
      }
      findIn(enum_.fields);
    }

    for (var class_ in unitElement.types) {
      if (of != null && class_.name != of) {
        continue;
      }
      findIn(class_.fields);
    }

    for (var mixin in unitElement.mixins) {
      if (of != null && mixin.name != of) {
        continue;
      }
      findIn(mixin.fields);
    }

    for (var extension in unitElement.extensions) {
      if (of != null && extension.name != of) {
        continue;
      }
      findIn(extension.fields);
    }

    if (result != null) {
      return result;
    }
    throw StateError('Not found: $name');
  }

  FunctionTypeAliasElement functionTypeAlias(String name) {
    for (var element in unitElement.functionTypeAliases) {
      if (element is GenericTypeAliasElement && element.name == name) {
        return element;
      }
    }
    throw StateError('Not found: $name');
  }

  PropertyAccessorElement getter(String name, {String of}) {
    PropertyAccessorElement result;

    void findIn(List<PropertyAccessorElement> accessors) {
      for (var accessor in accessors) {
        if (accessor.isGetter && accessor.displayName == name) {
          if (result != null) {
            throw StateError('Not unique: $name');
          }
          result = accessor;
        }
      }
    }

    for (var enum_ in unitElement.enums) {
      if (of != null && enum_.name != of) {
        continue;
      }
      findIn(enum_.accessors);
    }

    for (var extension_ in unitElement.extensions) {
      if (of != null && extension_.name != of) {
        continue;
      }
      findIn(extension_.accessors);
    }

    for (var class_ in unitElement.types) {
      if (of != null && class_.name != of) {
        continue;
      }
      findIn(class_.accessors);
    }

    for (var mixin in unitElement.mixins) {
      if (of != null && mixin.name != of) {
        continue;
      }
      findIn(mixin.accessors);
    }

    if (result != null) {
      return result;
    }
    throw StateError('Not found: $name');
  }

  MethodElement method(String name, {String of}) {
    MethodElement result;

    void findIn(List<MethodElement> methods) {
      for (var method in methods) {
        if (method.name == name) {
          if (result != null) {
            throw StateError('Not unique: $name');
          }
          result = method;
        }
      }
    }

    for (var extension_ in unitElement.extensions) {
      if (of != null && extension_.name != of) {
        continue;
      }
      findIn(extension_.methods);
    }

    for (var class_ in unitElement.types) {
      if (of != null && class_.name != of) {
        continue;
      }
      findIn(class_.methods);
    }

    for (var mixin in unitElement.mixins) {
      if (of != null && mixin.name != of) {
        continue;
      }
      findIn(mixin.methods);
    }

    if (result != null) {
      return result;
    }
    throw StateError('Not found: $name');
  }

  ClassElement mixin(String name) {
    for (var mixin in unitElement.mixins) {
      if (mixin.name == name) {
        return mixin;
      }
    }
    throw StateError('Not found: $name');
  }

  PropertyAccessorElement setter(String name, {String of}) {
    PropertyAccessorElement result;

    void findIn(List<PropertyAccessorElement> accessors) {
      for (var accessor in accessors) {
        if (accessor.isSetter && accessor.displayName == name) {
          if (result != null) {
            throw StateError('Not unique: $name');
          }
          result = accessor;
        }
      }
    }

    for (var extension_ in unitElement.extensions) {
      if (of != null && extension_.name != of) {
        continue;
      }
      findIn(extension_.accessors);
    }

    for (var class_ in unitElement.types) {
      if (of != null && class_.name != of) {
        continue;
      }
      findIn(class_.accessors);
    }

    for (var mixin in unitElement.mixins) {
      if (of != null && mixin.name != of) {
        continue;
      }
      findIn(mixin.accessors);
    }

    if (result != null) {
      return result;
    }
    throw StateError('Not found: $name');
  }

  FunctionElement topFunction(String name) {
    for (var function in unitElement.functions) {
      if (function.name == name) {
        return function;
      }
    }
    throw StateError('Not found: $name');
  }

  PropertyAccessorElement topGet(String name) {
    return topVar(name).getter;
  }

  PropertyAccessorElement topSet(String name) {
    return topVar(name).setter;
  }

  TopLevelVariableElement topVar(String name) {
    for (var variable in unitElement.topLevelVariables) {
      if (variable.name == name) {
        return variable;
      }
    }
    throw StateError('Not found: $name');
  }

  ConstructorElement unnamedConstructor(String name) {
    return class_(name).unnamedConstructor;
  }
}
