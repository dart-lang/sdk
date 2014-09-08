#!/usr/bin/python
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import os
import sys


_operation_suffix_map = {
  '__getter__': "Getter",
  '__setter__': "Setter",
  '__delete__': "Deleter",
}

class IDLNode(object):
  """Base class for all IDL elements.
  IDLNode may contain various child nodes, and have properties. Examples
  of IDLNode are interfaces, interface members, function arguments,
  etc.
  """

  def __init__(self, ast):
    """Initializes an IDLNode from a PegParser AST output."""
    self.id = self._find_first(ast, 'Id') if ast is not None else None

  def __repr__(self):
    """Generates string of the form <class id extra extra ... 0x12345678>."""
    extras = self._extra_repr()
    if isinstance(extras, list):
      extras = ' '.join([str(e) for e in extras])
    try:
      if self.id:
        return '<%s %s 0x%x>' % (
            type(self).__name__,
            ('%s %s' % (self.id, extras)).strip(),
            hash(self))
      return '<%s %s 0x%x>' % (
          type(self).__name__,
          extras,
          hash(self))
    except Exception, e:
      return "can't convert to string: %s" % e

  def _extra_repr(self):
    """Returns string of extra info for __repr__()."""
    return ''

  def __cmp__(self, other):
    """Override default compare operation.
    IDLNodes are equal if all their properties are equal."""
    if other is None or not isinstance(other, IDLNode):
      return 1
    return self.__dict__.__cmp__(other.__dict__)

  def reset_id(self, newId):
    """Reset the id of the Node.  This is typically done during a normalization
    phase (e.g., "DOMWindow" -> "Window")."""
    self.id = newId

  def all(self, type_filter=None):
    """Returns a list containing this node and all it child nodes
    (recursive).

    Args:
      type_filter -- can be used to limit the results to a specific
        node type (e.g. IDLOperation).
    """
    res = []
    if type_filter is None or isinstance(self, type_filter):
      res.append(self)
    for v in self._all_subnodes():
      if isinstance(v, IDLNode):
        res.extend(v.all(type_filter))
      elif isinstance(v, list):
        for item in v:
          if isinstance(item, IDLNode):
            res.extend(item.all(type_filter))
    return res

  def _all_subnodes(self):
    """Accessor used by all() to find subnodes."""
    return self.__dict__.values()

  def to_dict(self):
    """Converts the IDLNode and its children into a dictionary.
    This method is useful mostly for debugging and pretty printing.
    """
    res = {}
    for (k, v) in self.__dict__.items():
      if v == None or v == False or v == [] or v == {}:
        # Skip empty/false members.
        continue
      elif isinstance(v, IDLDictNode) and not len(v):
        # Skip empty dict sub-nodes.
        continue
      elif isinstance(v, list):
        # Convert lists:
        new_v = []
        for sub_node in v:
          if isinstance(sub_node, IDLNode):
            # Convert sub-node:
            new_v.append(sub_node.to_dict())
          else:
            new_v.append(sub_node)
        v = new_v
      elif isinstance(v, IDLNode):
        # Convert sub-node:
        v = v.to_dict()
      res[k] = v
    return res

  def _find_all(self, ast, label, max_results=sys.maxint):
    """Searches the AST for tuples with a given label. The PegParser
    output is composed of lists and tuples, where the tuple 1st argument
    is a label. If ast root is a list, will search recursively inside each
    member in the list.

    Args:
      ast -- the AST to search.
      label -- the label to look for.
      res -- results are put into this list.
      max_results -- maximum number of results.
    """
    res = []
    if max_results <= 0:
      return res

    if isinstance(ast, list):
      for childAst in ast:
        sub_res = self._find_all(childAst, label,
                     max_results - len(res))
        res.extend(sub_res)
    elif isinstance(ast, tuple):
      (nodeLabel, value) = ast
      if nodeLabel == label:
        res.append(value)
    return res

  def _find_first(self, ast, label):
    """Convenience method for _find_all(..., max_results=1).
    Returns a single element instead of a list, or None if nothing
    is found."""
    res = self._find_all(ast, label, max_results=1)
    if len(res):
      return res[0]
    return None

  def _has(self, ast, label):
    """Returns true if an element with the given label is
    in the AST by searching for it."""
    return len(self._find_all(ast, label, max_results=1)) == 1

  def _convert_all(self, ast, label, idlnode_ctor):
    """Converts AST elements into IDLNode elements.
    Uses _find_all to find elements with a given label and converts
    them into IDLNodes with a given constructor.
    Returns:
      A list of the converted nodes.
    Args:
      ast -- the ast element to start a search at.
      label -- the element label to look for.
      idlnode_ctor -- a constructor function of one of the IDLNode
        sub-classes.
    """
    res = []
    found = self._find_all(ast, label)
    if not found:
      return res
    if not isinstance(found, list):
      raise RuntimeError("Expected list but %s found" % type(found))
    for childAst in found:
      converted = idlnode_ctor(childAst)
      res.append(converted)
    return res

  def _convert_first(self, ast, label, idlnode_ctor):
    """Like _convert_all, but only converts the first found results."""
    childAst = self._find_first(ast, label)
    if not childAst:
      return None
    return idlnode_ctor(childAst)

  def _convert_ext_attrs(self, ast):
    """Helper method for uniform conversion of extended attributes."""
    self.ext_attrs = IDLExtAttrs(ast)

  def _convert_annotations(self, ast):
    """Helper method for uniform conversion of annotations."""
    self.annotations = IDLAnnotations(ast)


class IDLDictNode(IDLNode):
  """Base class for dictionary-like IDL nodes such as extended attributes
  and annotations. The base class implements various dict interfaces."""

  def __init__(self, ast):
    IDLNode.__init__(self, None)
    if ast is not None and isinstance(ast, dict):
      self.__map = ast
    else:
      self.__map = {}

  def __len__(self):
    return len(self.__map)

  def __getitem__(self, key):
    return self.__map[key]

  def __setitem__(self, key, value):
    self.__map[key] = value

  def __delitem__(self, key):
    del self.__map[key]

  def __contains__(self, key):
    return key in self.__map

  def __iter__(self):
    return self.__map.__iter__()

  def get(self, key, default=None):
    return self.__map.get(key, default)

  def setdefault(self, key, value=None):
    return self.__map.setdefault(key, value)

  def items(self):
    return self.__map.items()

  def keys(self):
    return self.__map.keys()

  def values(self):
    return self.__map.values()

  def clear(self):
    self.__map = {}

  def to_dict(self):
    """Overrides the default IDLNode.to_dict behavior.
    The IDLDictNode members are copied into a new dictionary, and
    IDLNode members are recursively converted into dicts as well.
    """
    res = {}
    for (k, v) in self.__map.items():
      if isinstance(v, IDLNode):
        v = v.to_dict()
      res[k] = v
    return res

  def _all_subnodes(self):
    # Usually an IDLDictNode does not contain further IDLNodes.
    return []


class IDLFile(IDLNode):
  """IDLFile is the top-level node in each IDL file. It may contain interfaces."""

  def __init__(self, ast, filename=None):
    IDLNode.__init__(self, ast)
    self.filename = filename
    self.interfaces = self._convert_all(ast, 'Interface', IDLInterface)
    modules = self._convert_all(ast, 'Module', IDLModule)
    self.implementsStatements = self._convert_all(ast, 'ImplStmt',
      IDLImplementsStatement)
    self.typeDefs = self._convert_all(ast, 'TypeDef', IDLTypeDef)
    self.enums = self._convert_all(ast, 'Enum', IDLEnum)
    for module in modules:
      self.interfaces.extend(module.interfaces)
      self.implementsStatements.extend(module.implementsStatements)
      self.typeDefs.extend(module.typeDefs)


class IDLModule(IDLNode):
  """IDLModule has an id, and may contain interfaces, type defs and
  implements statements."""
  def __init__(self, ast):
    IDLNode.__init__(self, ast)
    self._convert_ext_attrs(ast)
    self._convert_annotations(ast)
    self.interfaces = self._convert_all(ast, 'Interface', IDLInterface)
    self.typeDefs = self._convert_all(ast, 'TypeDef', IDLTypeDef)
    self.enums = self._convert_all(ast, 'Enum', IDLNode)
    self.implementsStatements = self._convert_all(ast, 'ImplStmt',
      IDLImplementsStatement)


class IDLExtAttrs(IDLDictNode):
  """IDLExtAttrs is an IDLDictNode that stores IDL Extended Attributes.
  Modules, interfaces, members and arguments can all own IDLExtAttrs."""
  def __init__(self, ast=None):
    IDLDictNode.__init__(self, None)
    if not ast:
      return
    ext_attrs_ast = self._find_first(ast, 'ExtAttrs')
    if not ext_attrs_ast:
      return
    for ext_attr in self._find_all(ext_attrs_ast, 'ExtAttr'):
      name = self._find_first(ext_attr, 'Id')
      value = self._find_first(ext_attr, 'ExtAttrValue')

      if name == 'Constructor':
        # There might be multiple constructor attributes, collect them
        # as a list.  Represent plain Constructor attribute
        # (without any signature) as None.
        assert value is None
        func_value = None
        ctor_args = self._find_first(ext_attr, 'ExtAttrArgList')
        if ctor_args:
          func_value = IDLExtAttrFunctionValue(None, ctor_args)
        self.setdefault('Constructor', []).append(func_value)
        continue

      func_value = self._find_first(value, 'ExtAttrFunctionValue')
      if func_value:
        # E.g. NamedConstructor=Audio(optional DOMString src)
        self[name] = IDLExtAttrFunctionValue(
            func_value,
            self._find_first(func_value, 'ExtAttrArgList'))
        continue

      self[name] = value

  def _all_subnodes(self):
    # Extended attributes may contain IDLNodes, e.g. IDLExtAttrFunctionValue
    return self.values()


class IDLExtAttrFunctionValue(IDLNode):
  """IDLExtAttrFunctionValue."""
  def __init__(self, func_value_ast, arg_list_ast):
    IDLNode.__init__(self, func_value_ast)
    self.arguments = self._convert_all(arg_list_ast, 'Argument', IDLArgument)


class IDLType(IDLNode):
  """IDLType is used to describe constants, attributes and operations'
  return and input types. IDLType matches AST labels such as ScopedName,
  StringType, VoidType, IntegerType, etc."""

  def __init__(self, ast):
    IDLNode.__init__(self, ast)
    self.nullable = self._has(ast, 'Nullable')
    # Search for a 'ScopedName' or any label ending with 'Type'.
    if isinstance(ast, list):
      self.id = self._find_first(ast, 'ScopedName')
      if not self.id:
        # FIXME: use regexp search instead
        def findType(ast):
          for label, childAst in ast:
            if label.endswith('Type'):
              type = self._label_to_type(label, ast)
              if type != 'sequence':
                return type
              type_ast = self._find_first(childAst, 'Type')
              if not type_ast:
                return type
              return 'sequence<%s>' % findType(type_ast)
          raise Exception('No type declaration found in %s' % ast)
        self.id = findType(ast)
      array_modifiers = self._find_first(ast, 'ArrayModifiers')
      if array_modifiers:
        self.id += array_modifiers
    elif isinstance(ast, tuple):
      (label, value) = ast
      if label == 'ScopedName':
        self.id = value
      else:
        self.id = self._label_to_type(label, ast)
    elif isinstance(ast, str):
      self.id = ast
    if not self.id:
      raise SyntaxError('Could not parse type %s' % (ast))

  def _label_to_type(self, label, ast):
    if label == 'LongLongType':
      label = 'long long'
    elif label.endswith('Type'):
      # Omit 'Type' suffix and lowercase the rest.
      label = '%s%s' % (label[0].lower(), label[1:-4])

    # Add unsigned qualifier.
    if self._has(ast, 'Unsigned'):
      label = 'unsigned %s' % label
    return label


class IDLEnum(IDLNode):
  """IDLNode for 'enum [id] { [string]+ }'"""
  def __init__(self, ast):
    IDLNode.__init__(self, ast)
    self._convert_annotations(ast)
    # TODO(antonm): save enum values.


class IDLTypeDef(IDLNode):
  """IDLNode for 'typedef [type] [id]' declarations."""
  def __init__(self, ast):
    IDLNode.__init__(self, ast)
    self._convert_annotations(ast)
    self.type = self._convert_first(ast, 'Type', IDLType)


class IDLInterface(IDLNode):
  """IDLInterface node contains operations, attributes, constants,
  as well as parent references."""

  def __init__(self, ast):
    IDLNode.__init__(self, ast)
    self._convert_ext_attrs(ast)
    self._convert_annotations(ast)
    self.parents = self._convert_all(ast, 'ParentInterface',
      IDLParentInterface)
    javascript_interface_name = self.ext_attrs.get('InterfaceName', self.id)
    self.javascript_binding_name = javascript_interface_name
    self.doc_js_name = javascript_interface_name

    if not (self._find_first(ast, 'Callback') is None):
      self.ext_attrs['Callback'] = None
    if not (self._find_first(ast, 'Partial') is None):
      self.is_supplemental = True
      self.ext_attrs['Supplemental'] = None

    self.operations = self._convert_all(ast, 'Operation',
      lambda ast: IDLOperation(ast, self.doc_js_name))
    self.attributes = self._convert_all(ast, 'Attribute',
      lambda ast: IDLAttribute(ast, self.doc_js_name))
    self.constants = self._convert_all(ast, 'Const',
      lambda ast: IDLConstant(ast, self.doc_js_name))
    self.is_supplemental = 'Supplemental' in self.ext_attrs
    self.is_no_interface_object = 'NoInterfaceObject' in self.ext_attrs
    self.is_fc_suppressed = 'Suppressed' in self.ext_attrs


  def reset_id(self, new_id):
    """Reset the id of the Interface and corresponding the JS names."""
    if self.id != new_id:
      self.id = new_id
      self.doc_js_name = new_id
      self.javascript_binding_name = new_id
      for member in self.operations:
        member.doc_js_interface_name = new_id
      for member in self.attributes:
        member.doc_js_interface_name = new_id
      for member in self.constants:
        member.doc_js_interface_name = new_id

  def has_attribute(self, candidate):
    for attribute in self.attributes:
      if (attribute.id == candidate.id and
          attribute.is_read_only == candidate.is_read_only):
        return True
    return False


class IDLParentInterface(IDLNode):
  """This IDLNode specialization is for 'Interface Child : Parent {}'
  declarations."""
  def __init__(self, ast):
    IDLNode.__init__(self, ast)
    self._convert_annotations(ast)
    self.type = self._convert_first(ast, 'InterfaceType', IDLType)


class IDLMember(IDLNode):
  """A base class for constants, attributes and operations."""

  def __init__(self, ast, doc_js_interface_name):
    IDLNode.__init__(self, ast)
    self.type = self._convert_first(ast, 'Type', IDLType)
    self._convert_ext_attrs(ast)
    self._convert_annotations(ast)
    self.doc_js_interface_name = doc_js_interface_name
    self.is_fc_suppressed = 'Suppressed' in self.ext_attrs
    self.is_static = self._has(ast, 'Static')


class IDLOperation(IDLMember):
  """IDLNode specialization for 'type name(args)' declarations."""
  def __init__(self, ast, doc_js_interface_name):
    IDLMember.__init__(self, ast, doc_js_interface_name)
    self.type = self._convert_first(ast, 'ReturnType', IDLType)
    self.arguments = self._convert_all(ast, 'Argument', IDLArgument)
    self.specials = self._find_all(ast, 'Special')
    self.is_stringifier = self._has(ast, 'Stringifier')
    # Special case: there are getters of the form
    # getter <ReturnType>(args).  For now force the name to be __getter__,
    # but it should be operator[] later.
    if self.id is None:
      if self.specials == ['getter']:
        self.id = '__getter__'
      elif self.specials == ['setter']:
        self.id = '__setter__'
        # Special case: if it's a setter, ignore 'declared' return type
        self.type = IDLType([('VoidType', None)])
      elif self.specials == ['deleter']:
        self.id = '__delete__'
      else:
        raise Exception('Cannot handle %s: operation has no id' % ast)

      if len(self.arguments) >= 1 and (self.id in _operation_suffix_map) and not self.ext_attrs.get('ImplementedAs'):
        arg = self.arguments[0]
        operation_category = 'Named' if arg.type.id == 'DOMString' else 'Indexed'
        self.ext_attrs.setdefault('ImplementedAs', 'anonymous%s%s' % (operation_category, _operation_suffix_map[self.id]))

  def _extra_repr(self):
    return [self.arguments]

  def SameSignatureAs(self, operation):
    if self.type != operation.type:
      return False
    return [a.type for a in self.arguments] == [a.type for a in operation.arguments]

class IDLAttribute(IDLMember):
  """IDLNode specialization for 'attribute type name' declarations."""
  def __init__(self, ast, doc_js_interface_name):
    IDLMember.__init__(self, ast, doc_js_interface_name)
    self.is_read_only = self._has(ast, 'ReadOnly')
    # There are various ways to define exceptions for attributes:
  def _extra_repr(self):
    extra = []
    if self.is_read_only: extra.append('readonly')
    return extra

class IDLConstant(IDLMember):
  """IDLNode specialization for 'const type name = value' declarations."""
  def __init__(self, ast, doc_js_interface_name):
    IDLMember.__init__(self, ast, doc_js_interface_name)
    self.value = self._find_first(ast, 'ConstExpr')


class IDLArgument(IDLNode):
  """IDLNode specialization for operation arguments."""
  def __init__(self, ast):
    IDLNode.__init__(self, ast)
    self.type = self._convert_first(ast, 'Type', IDLType)
    self.optional = self._has(ast, 'Optional')
    self._convert_ext_attrs(ast)
    # TODO(vsm): Recover this from the type instead.
    if 'Callback' in self.type.id:
      self.ext_attrs['Callback'] = None

  def __repr__(self):
    return '<IDLArgument(type = %s, id = %s)>' % (self.type, self.id)


class IDLImplementsStatement(IDLNode):
  """IDLNode specialization for 'X implements Y' declarations."""
  def __init__(self, ast):
    IDLNode.__init__(self, ast)
    self.implementor = self._convert_first(ast, 'ImplStmtImplementor',
      IDLType)
    self.implemented = self._convert_first(ast, 'ImplStmtImplemented',
      IDLType)


class IDLAnnotations(IDLDictNode):
  """IDLDictNode specialization for a list of FremontCut annotations."""
  def __init__(self, ast=None):
    IDLDictNode.__init__(self, ast)
    self.id = None
    if not ast:
      return
    for annotation in self._find_all(ast, 'Annotation'):
      name = self._find_first(annotation, 'Id')
      value = IDLAnnotation(annotation)
      self[name] = value


class IDLAnnotation(IDLDictNode):
  """IDLDictNode specialization for one annotation."""
  def __init__(self, ast=None):
    IDLDictNode.__init__(self, ast)
    self.id = None
    if not ast:
      return
    for arg in self._find_all(ast, 'AnnotationArg'):
      name = self._find_first(arg, 'Id')
      value = self._find_first(arg, 'AnnotationArgValue')
      self[name] = value
