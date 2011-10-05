#!/usr/bin/python
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""Utility to render a single Dart interface."""


def Render(interface, extra_snippets,
           common_prefix=None, super_interface=None,
           source_filter=None):
  """Generates Dart code for the given interface.

  Returns:
    A string containing the Dart code for the given interface.

  Args: interface -- an IDLInterface instance. It is assumed that
      all types have been converted to Dart types (e.g. int,
      String), unless they are in the same package as the interface.
    extra_snippets -- additional snippet text with method
      signatures that were extracted from the implementation snippet
      file
    common_prefix -- the prefix for the common library, if any.
    super_interface -- the name of the common interface that this interface
      implements, if any.
    source_filter -- if specified, rewrites the names of any superinterfaces
      that are not from this source to use the common prefix.
  """

  output = []

  # Local utilities
  def Write(text):
    """Shorthand for output appendage"""
    output.append(text)

  # insert text with 2 spaces of indentation
  def WriteLines(text):
    for text_line in text.split('\n'):
      if text_line.strip():
        Write('  %s\n' % text_line)
      else:
        Write('\n')

  def AttributeOutputOrder(a, b):
    """Canonical output ordering for attributes."""
    if a.id < b.id: return -1
    if a.id > b.id: return 1
    # Getters before setters:
    if a.is_fc_setter < b.is_fc_setter: return -1
    if a.is_fc_setter > b.is_fc_setter: return 1
    return 0

  def ConstantOutputOrder(a, b):
    """Canonical output ordering for constants."""
    if a.id < b.id: return -1
    if a.id > b.id: return 1
    return 0

  # Dartc code:
  # TODO(vsm): Add appropriate package / namespace syntax.
  # Write('package %s;\n\n' % package_name)

  if super_interface:
    typename = super_interface
  else:
    typename = interface.id

  Write('interface %s' % typename)

  extends = []
  suppressed_extends = []

  for parent in interface.parents:
    if (source_filter is None or source_filter in parent.annotations
        # TODO(dstockwell): core types (like List) should have a prefix
        or '<' in parent.type.id):
      extends.append(parent.type.id)
    else:
      suppressed_extends.append('%s.%s' % (common_prefix, parent.type.id))
  if extends:
    Write(' extends %s' % (', '.join(extends)))
  if suppressed_extends:
    if not extends:
      Write(' /* extends ')
    else:
      Write(' /*, ')
    Write('%s */' % (', '.join(suppressed_extends)))

  Write(' {\n')

  # Generate members:
  for const in sorted(interface.constants, ConstantOutputOrder):
    Write('\n')
    Write('  static final %s %s = %s;\n' %
          (const.type.id, const.id, const.value))

  for attr in sorted(interface.attributes, AttributeOutputOrder):
    Write('\n')
    if attr.is_fc_getter:
      Write('  %s get %s();\n' % (attr.type.id, attr.id))
    elif attr.is_fc_setter:
      Write('  void set %s(%s value);\n' %
            (attr.id, attr.type.id))

  # Overloaded argument types exposed by this interface.
  # Set of sorted tuples of type identifiers
  overloadedTypes = set()

  # Given a sorted sequence of type identifiers, return an appropriate type
  # name
  def TypeName(typeIds):
    typeName = '%s_%s' % (interface.id, '_OR_'.join(typeIds))
    # Remove any template syntax before returning
    return typeName.replace('<', '_').replace('>', '_')

  # Given a list of overloaded arguments, choose a suitable name
  def OverloadedName(args):
    ids = list(set(map(lambda arg: arg.id, args)))
    ids.sort()
    return '_OR_'.join(ids)

  # Given a list of overloaded arguments, choose a suitable type
  def OverloadedType(args):
    typeIds = list(set(map(lambda arg: arg.type.id, args)))
    if len(typeIds) == 1:
      return typeIds[0]
    else:
      typeIds.sort()
      overloadedTypes.add(tuple(typeIds))
      return TypeName(typeIds)

  # Given a list of overloaded arguments, render a dart argument
  def DartArg(args):
    filtered = filter(None, args)
    optional = len(filtered) < len(ops) or any(
        map(lambda arg: arg.is_optional, filtered))
    type = OverloadedType(filtered)
    name = OverloadedName(filtered)
    if optional:
      return '%s %s = null' % (type, name)
    else:
      return '%s %s' % (type, name)

  # Group overloaded operations by id
  opsById = {}
  for op in interface.operations:
    if op.id not in opsById:
      opsById[op.id] = []
    opsById[op.id].append(op)

  sortedOpIds = list(opsById.keys())
  sortedOpIds.sort()

  # Generate operations
  for id in sortedOpIds:
    ops = opsById[id]
    # Zip together arguments from each overload by position, then convert
    # to a dart argument
    args = map(lambda *args: DartArg(args),
               *map(lambda op: op.arguments, ops))
    Write('\n')
    # TODO(dstockwell): ensure return type is the same, or relax
    Write('  %s %s(%s);\n' % (ops[0].type.id, id, ', '.join(args)))

  # Write snippet text that was inlined in the IDL.
  for snippet in interface.snippets:
    Write('\n')
    WriteLines(snippet.text)

  # Write snippets that were derived from the implementation
  # snippet file (see class SnippetManager).

  # TODO(vsm): Test if snippets are extra methods or extra types.
  # Since Dart doesn't permit inner types, append after the interface.
  # Consider moving these types to auxilary classes instead.
  if extra_snippets is not None:
    if 'interface' in extra_snippets:
      Write('}\n')
      Write('\n')
      Write(extra_snippets)
    else:
      Write('\n')
      WriteLines(extra_snippets)
      Write('}\n')
  else:
    Write('}\n')

  # TODO(vsm): Use typedef if / when that is supported in Dart.
  # Define variant as subtype.
  if interface.id is not typename:
    Write('\ninterface %s extends %s {\n' % (interface.id, typename))
    # Regenerate static consts as these are not inherited.
    for const in sorted(interface.constants, ConstantOutputOrder):
      Write('\n')
      Write('  static final %s %s = %s;\n' %
            (const.type.id, const.id, const.value))
    Write('}\n')


  # Inject interfaces for overloaded argument types.
  for types in sorted(overloadedTypes):
    typeToInject = TypeName(types)
    Write('\ninterface %s {}\n' % typeToInject)
    for type in types:
      Write('interface %s extends %s;\n' % (type, typeToInject))

  return ''.join(output)
