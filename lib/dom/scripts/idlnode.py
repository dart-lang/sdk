#!/usr/bin/python
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import sys


class IDLNode(object):
  """Base class for all IDL elements.
  IDLNode may contain various child nodes, and have properties. Examples
  of IDLNode are modules, interfaces, interface members, function arguments,
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
  """IDLFile is the top-level node in each IDL file. It may contain
  modules or interfaces."""

  def __init__(self, ast, filename=None):
    IDLNode.__init__(self, ast)
    self.filename = filename
    self.modules = self._convert_all(ast, 'Module', IDLModule)
    self.interfaces = self._convert_all(ast, 'Interface', IDLInterface)


class IDLModule(IDLNode):
  """IDLModule has an id, and may contain interfaces, type defs and
  implements statements."""
  def __init__(self, ast):
    IDLNode.__init__(self, ast)
    self._convert_ext_attrs(ast)
    self._convert_annotations(ast)
    self.interfaces = self._convert_all(ast, 'Interface', IDLInterface)
    self.typeDefs = self._convert_all(ast, 'TypeDef', IDLTypeDef)
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

      func_value = self._find_first(value, 'ExtAttrFunctionValue')
      if func_value:
        # E.g. NamedConstructor=Audio(in [Optional] DOMString src)
        self[name] = IDLExtAttrFunctionValue(
            func_value,
            self._find_first(func_value, 'ExtAttrArgList'))
        continue

      ctor_args = not value and self._find_first(ext_attr, 'ExtAttrArgList')
      if ctor_args:
        # E.g. Constructor(Element host)
        self[name] = IDLExtAttrFunctionValue(None, ctor_args)
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
    # Search for a 'ScopedName' or any label ending with 'Type'.
    if isinstance(ast, list):
      self.id = self._find_first(ast, 'ScopedName')
      if not self.id:
        # FIXME: use regexp search instead
        for childAst in ast:
          (label, childAst) = childAst
          if label.endswith('Type'):
            self.id = self._label_to_type(label, ast)
            break
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
    if label == 'AnyArrayType':
      return 'any[]'
    if label == 'DOMStringArrayType':
      return 'DOMString[]'
    if label == 'LongLongType':
      label = 'long long'
    elif label.endswith('Type'):
      # Omit 'Type' suffix and lowercase the rest.
      label = '%s%s' % (label[0].lower(), label[1:-4])

    # Add unsigned qualifier.
    if self._has(ast, 'Unsigned'):
      label = 'unsigned %s' % label
    return label


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
    self.javascript_binding_name = self.id
    self.doc_js_name = self.id
    self.operations = self._convert_all(ast, 'Operation', 
      lambda ast: IDLOperation(ast, self.doc_js_name))
    self.attributes = self._convert_all(ast, 'Attribute',
      lambda ast: IDLAttribute(ast, self.doc_js_name))
    self.constants = self._convert_all(ast, 'Const',
      lambda ast: IDLConstant(ast, self.doc_js_name))
    self.is_supplemental = 'Supplemental' in self.ext_attrs
    self.is_no_interface_object = 'NoInterfaceObject' in self.ext_attrs
    self.is_fc_suppressed = 'Suppressed' in self.ext_attrs

  def has_attribute(self, candidate):
    for attribute in self.attributes:
      if (attribute.id == candidate.id and
          attribute.is_fc_getter == candidate.is_fc_getter and
          attribute.is_fc_setter == candidate.is_fc_setter):
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
    self.raises = self._convert_first(ast, 'Raises', IDLType)
    self.specials = self._find_all(ast, 'Special')
    self.is_stringifier = self._has(ast, 'Stringifier')
  def _extra_repr(self):
    return [self.arguments]


class IDLAttribute(IDLMember):
  """IDLNode specialization for 'attribute type name' declarations."""
  def __init__(self, ast, doc_js_interface_name):
    IDLMember.__init__(self, ast, doc_js_interface_name)
    self.is_read_only = self._has(ast, 'ReadOnly')
    # There are various ways to define exceptions for attributes:
    self.raises = self._convert_first(ast, 'Raises', IDLType)
    self.get_raises = self.raises \
      or self._convert_first(ast, 'GetRaises', IDLType)
    self.set_raises = self.raises \
      or self._convert_first(ast, 'SetRaises', IDLType)
    # FremontCut IDL syntax defines getters and setters separately:
    self.is_fc_getter = self._has(ast, 'AttrGetter')
    self.is_fc_setter = self._has(ast, 'AttrSetter')
  def _extra_repr(self):
    extra = []
    if self.is_fc_getter: extra.append('get')
    if self.is_fc_setter: extra.append('set')
    if self.is_read_only: extra.append('readonly')
    if self.raises: extra.append('raises')
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
    self._convert_ext_attrs(ast)
    # WebKit and Web IDL differ in how Optional is declared:
    self.is_optional = self._has(ast, 'Optional') \
      or ('Optional' in self.ext_attrs)


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
