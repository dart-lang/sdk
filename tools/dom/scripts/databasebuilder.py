#!/usr/bin/python
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import copy
import database
import logging
import monitored
import multiprocessing
import os
import os.path
import re
import sys
import tempfile
import time
import traceback

import idl_validator

import compiler
import compute_interfaces_info_individual
from compute_interfaces_info_individual import InterfaceInfoCollector
import idl_definitions

from idlnode import *

_logger = logging.getLogger('databasebuilder')

# Used in source annotations to specify the parent interface declaring
# a displaced declaration. The 'via' attribute specifies the parent interface
# which implements a displaced declaration.
_VIA_ANNOTATION_ATTR_NAME = 'via'


class DatabaseBuilderOptions(object):
    """Used in specifying options when importing new interfaces"""

    def __init__(self,
                 idl_defines=[],
                 source=None,
                 source_attributes={},
                 rename_operation_arguments_on_merge=False,
                 add_new_interfaces=True,
                 obsolete_old_declarations=False,
                 logging_level=logging.WARNING):
        """Constructor.
    Args:
      idl_defines -- list of definitions for the idl gcc pre-processor
      source -- the origin of the IDL file, used for annotating the
        database.
      source_attributes -- this map of attributes is used as
        annotation attributes.
      rename_operation_arguments_on_merge -- if True, will rename
        operation arguments when merging using the new name rather
        than the old.
      add_new_interfaces -- when False, if an interface is a new
        addition, it will be ignored.
      obsolete_old_declarations -- when True, if a declaration
        from a certain source is not re-declared, it will be removed.
    """
        self.source = source
        self.source_attributes = source_attributes
        self.idl_defines = idl_defines
        self.rename_operation_arguments_on_merge = \
            rename_operation_arguments_on_merge
        self.add_new_interfaces = add_new_interfaces
        self.obsolete_old_declarations = obsolete_old_declarations
        _logger.setLevel(logging_level)


def format_exception(e):
    exception_list = traceback.format_stack()
    exception_list = exception_list[:-2]
    exception_list.extend(traceback.format_tb(sys.exc_info()[2]))
    exception_list.extend(
        traceback.format_exception_only(sys.exc_info()[0],
                                        sys.exc_info()[1]))

    exception_str = "Traceback (most recent call last):\n"
    exception_str += "".join(exception_list)
    # Removing the last \n
    exception_str = exception_str[:-1]

    return exception_str


# Compile IDL using Blink's IDL compiler.
def _compile_idl_file(build, file_name, import_options):
    try:
        idl_file_fullpath = os.path.realpath(file_name)
        idl_definition = build.idl_compiler.compile_file(idl_file_fullpath)
        return idl_definition
    except Exception as err:
        print 'ERROR: idl_compiler.py: ' + os.path.basename(file_name)
        print err
        print
        print 'Stack Dump:'
        print format_exception(err)

    return 1


# Create the Model (IDLFile) from the new AST of the compiled IDL file.
def _load_idl_file(build, file_name, import_options):
    try:
        # Compute interface name from IDL filename (it's one for one in WebKit).
        name = os.path.splitext(os.path.basename(file_name))[0]

        idl_definition = new_asts[name]
        return IDLFile(idl_definition, file_name)
    except Exception as err:
        print 'ERROR: loading AST from cache: ' + os.path.basename(file_name)
        print err
        print
        print 'Stack Dump:'
        print format_exception(err)

    return 1


# New IDL parser builder.
class Build():

    def __init__(self, provider):
        # TODO(terry): Consider using the generator to do the work today we're
        #              driven by the databasebuilder.  Blink compiler requires
        #              an output directory even though we don't use (yet). Might
        #              use the code generator portion of the new IDL compiler
        #              then we'd have a real output directory. Today we use the
        #              compiler to only create an AST.
        self.output_directory = tempfile.mkdtemp()
        attrib_file = os.path.join('Source',
                                   idl_validator.EXTENDED_ATTRIBUTES_FILENAME)
        # Create compiler.
        self.idl_compiler = compiler.IdlCompilerDart(
            self.output_directory,
            attrib_file,
            interfaces_info=provider._info_collector.interfaces_info,
            only_if_changed=True)

    def format_exception(self, e):
        exception_list = traceback.format_stack()
        exception_list = exception_list[:-2]
        exception_list.extend(traceback.format_tb(sys.exc_info()[2]))
        exception_list.extend(
            traceback.format_exception_only(sys.exc_info()[0],
                                            sys.exc_info()[1]))

        exception_str = "Traceback (most recent call last):\n"
        exception_str += "".join(exception_list)
        # Removing the last \n
        exception_str = exception_str[:-1]

        return exception_str

    def generate_from_idl(self, idl_file):
        try:
            idl_file_fullpath = os.path.realpath(idl_file)
            self.idl_compiler.compile_file(idl_file_fullpath)
        except Exception as err:
            print 'ERROR: idl_compiler.py: ' + os.path.basename(idl_file)
            print err
            print
            print 'Stack Dump:'
            print self.format_exception(err)

            return 1

        return IDLFile(idl_ast, file_name)


class DatabaseBuilder(object):

    def __init__(self, database):
        """DatabaseBuilder is used for importing and merging interfaces into
    the Database"""
        self._info_collector = InterfaceInfoCollector()

        self._database = database
        self._imported_interfaces = []
        self._impl_stmts = []
        self.conditionals_met = set()

        # Spin up the new IDL parser.
        self.build = Build(self)

        # Global typedef to mapping.
        self.global_type_defs = monitored.Dict(
            'databasebuilder.global_type_defs', {
                'Transferable': 'MessagePort',
            })

    # TODO(terry): Consider keeping richer type information (e.g.,
    #              IdlArrayOrSequenceType from the Blink parser) instead of just
    #              a type name.
    def _resolve_type_defs(self, idl_file):
        for type_node in idl_file.all(IDLType):
            resolved = False
            type_name = type_node.id
            for typedef in self.global_type_defs:
                seq_name_typedef = 'sequence<%s>' % typedef
                if type_name == typedef:
                    type_node.id = self.global_type_defs[typedef]
                    resolved = True
                elif type_name == seq_name_typedef:
                    type_node.id = 'sequence<%s>' % self.global_type_defs[
                        typedef]
                    resolved = True
            if not (resolved):
                for typedef in idl_file.typeDefs:
                    if type_name == typedef.id:
                        type_node.id = typedef.type.id
                        resolved = True

    def _strip_ext_attributes(self, idl_file):
        """Strips unuseful extended attributes."""
        for ext_attrs in idl_file.all(IDLExtAttrs):
            # TODO: Decide which attributes are uninteresting.
            pass

    def _rename_types(self, idl_file, import_options):
        """Rename interface and type names with names provided in the
    options. Also clears scopes from scoped names"""

        strip_modules = lambda name: name.split('::')[-1]

        def rename_node(idl_node):
            idl_node.reset_id(strip_modules(idl_node.id))

        def rename_ext_attrs(ext_attrs_node):
            for type_valued_attribute_name in ['DartSupplemental']:
                if type_valued_attribute_name in ext_attrs_node:
                    value = ext_attrs_node[type_valued_attribute_name]
                    if isinstance(value, str):
                        ext_attrs_node[
                            type_valued_attribute_name] = strip_modules(value)

        map(rename_node, idl_file.all(IDLInterface))
        map(rename_node, idl_file.all(IDLType))
        map(rename_ext_attrs, idl_file.all(IDLExtAttrs))

    def _annotate(self, interface, import_options):
        """Adds @ annotations based on the source and source_attributes
    members of import_options."""

        source = import_options.source
        if not source:
            return

        def add_source_annotation(idl_node):
            annotation = IDLAnnotation(
                copy.deepcopy(import_options.source_attributes))
            idl_node.annotations[source] = annotation
            if ((isinstance(idl_node, IDLInterface) or
                 isinstance(idl_node, IDLMember)) and
                    idl_node.is_fc_suppressed):
                annotation['suppressed'] = None

        add_source_annotation(interface)

        map(add_source_annotation, interface.parents)
        map(add_source_annotation, interface.constants)
        map(add_source_annotation, interface.attributes)
        map(add_source_annotation, interface.operations)

    def _sign(self, node):
        """Computes a unique signature for the node, for merging purposed, by
    concatenating types and names in the declaration."""
        if isinstance(node, IDLType):
            res = node.id
            if res.startswith('unsigned '):
                res = res[len('unsigned '):]
            if hasattr(node, 'nullable') and node.nullable:
                res += '?'
            return res

        res = []
        if isinstance(node, IDLInterface):
            res = ['interface', node.id]
        elif isinstance(node, IDLParentInterface):
            res = ['parent', self._sign(node.type)]
        elif isinstance(node, IDLOperation):
            res = ['op']
            for special in node.specials:
                res.append(special)
            if node.id is not None:
                res.append(node.id)
            for arg in node.arguments:
                res.append(self._sign(arg.type))
            res.append(self._sign(node.type))
        elif isinstance(node, IDLAttribute):
            res = []
            if node.is_read_only:
                res.append('readonly')
            res.append(node.id)
            res.append(self._sign(node.type))
        elif isinstance(node, IDLConstant):
            res = []
            res.append('const')
            res.append(node.id)
            res.append(node.value)
            res.append(self._sign(node.type))
        else:
            raise TypeError("Can't sign input of type %s" % type(node))
        return ':'.join(res)

    def _build_signatures_map(self, idl_node_list):
        """Creates a hash table mapping signatures to idl_nodes for the
    given list of nodes"""
        res = {}
        for idl_node in idl_node_list:
            sig = self._sign(idl_node)
            if sig is None:
                continue
            if sig in res:
                op = res[sig]
                # Only report if the operations that match are either both suppressed
                # or both not suppressed.  Optional args aren't part of type signature
                # for this routine. Suppressing a non-optional type and supplementing
                # with an optional type appear the same.
                if idl_node.is_fc_suppressed == op.is_fc_suppressed:
                    raise RuntimeError(
                        'Warning: Multiple members have the same '
                        '  signature: "%s"' % sig)
            res[sig] = idl_node
        return res

    def _get_parent_interfaces(self, interface):
        """Return a list of all the parent interfaces of a given interface"""
        res = []

        def recurse(current_interface):
            if current_interface in res:
                return
            res.append(current_interface)
            for parent in current_interface.parents:
                parent_name = parent.type.id
                if self._database.HasInterface(parent_name):
                    recurse(self._database.GetInterface(parent_name))

        recurse(interface)
        return res[1:]

    def _merge_ext_attrs(self, old_attrs, new_attrs):
        """Merges two sets of extended attributes.

    Returns: True if old_attrs has changed.
    """
        changed = False
        for (name, value) in new_attrs.items():
            if name in old_attrs and old_attrs[name] == value:
                pass  # Identical
            else:
                if name == 'ImplementedAs' and name in old_attrs:
                    continue
                old_attrs[name] = value
                changed = True
        return changed

    def _merge_nodes(self, old_list, new_list, import_options):
        """Merges two lists of nodes. Annotates nodes with the source of each
    node.

    Returns:
      True if the old_list has changed.

    Args:
      old_list -- the list to merge into.
      new_list -- list containing more nodes.
      import_options -- controls how merging is done.
    """
        changed = False

        source = import_options.source

        old_signatures_map = self._build_signatures_map(old_list)
        new_signatures_map = self._build_signatures_map(new_list)

        # Merge new items
        for (sig, new_node) in new_signatures_map.items():
            if sig not in old_signatures_map:
                # New node:
                old_list.append(new_node)
                changed = True
            else:
                # Merge old and new nodes:
                old_node = old_signatures_map[sig]
                if (source not in old_node.annotations and
                        source in new_node.annotations):
                    old_node.annotations[source] = new_node.annotations[source]
                    changed = True
                # Maybe rename arguments:
                if isinstance(old_node, IDLOperation):
                    for i in range(0, len(old_node.arguments)):
                        old_arg = old_node.arguments[i]
                        new_arg = new_node.arguments[i]

                        old_arg_name = old_arg.id
                        new_arg_name = new_arg.id
                        if (old_arg_name != new_arg_name and
                            (old_arg_name == 'arg' or
                             old_arg_name.endswith('Arg') or
                             import_options.rename_operation_arguments_on_merge)
                           ):
                            old_node.arguments[i].id = new_arg_name
                            changed = True

                        if self._merge_ext_attrs(old_arg.ext_attrs,
                                                 new_arg.ext_attrs):
                            changed = True

                        # Merge in [Default=Undefined] and DOMString a = null handling in
                        # IDL.  The IDL model (IDLArgument) coalesces these two different
                        # default value syntaxes into the default_value* models.
                        old_default_value = old_arg.default_value
                        new_default_value = new_arg.default_value
                        old_default_value_is_null = old_arg.default_value_is_null
                        new_default_value_is_null = new_arg.default_value_is_null
                        if old_default_value != new_default_value:
                            old_arg.default_value = new_default_value
                            changed = True
                        if old_default_value_is_null != new_default_value_is_null:
                            old_arg.default_value_is_null = new_default_value_is_null
                            changed = True

                        # Merge in any optional argument differences.
                        old_optional = old_arg.optional
                        new_optional = new_arg.optional
                        if old_optional != new_optional:
                            old_arg.optional = new_optional
                            changed = True
                # Maybe merge annotations:
                if (isinstance(old_node, IDLAttribute) or
                        isinstance(old_node, IDLOperation)):
                    if self._merge_ext_attrs(old_node.ext_attrs,
                                             new_node.ext_attrs):
                        changed = True

        # Remove annotations on obsolete items from the same source
        if import_options.obsolete_old_declarations:
            for (sig, old_node) in old_signatures_map.items():
                if (source in old_node.annotations and
                        sig not in new_signatures_map):
                    _logger.warn(
                        '%s not available in %s anymore' % (sig, source))
                    del old_node.annotations[source]
                    changed = True

        return changed

    def _merge_interfaces(self, old_interface, new_interface, import_options):
        """Merges the new_interface into the old_interface, annotating the
    interface with the sources of each change."""

        changed = False

        source = import_options.source
        if (source and source not in old_interface.annotations and
                source in new_interface.annotations and
                not new_interface.is_supplemental):
            old_interface.annotations[source] = new_interface.annotations[
                source]
            changed = True

        def merge_list(what):
            old_list = old_interface.__dict__[what]
            new_list = new_interface.__dict__[what]

            if what != 'parents' and old_interface.id != new_interface.id:
                for node in new_list:
                    node.doc_js_interface_name = old_interface.id
                    node.ext_attrs['ImplementedBy'] = new_interface.id

            changed = self._merge_nodes(old_list, new_list, import_options)

            # Delete list items with zero remaining annotations.
            if changed and import_options.obsolete_old_declarations:

                def has_annotations(idl_node):
                    return len(idl_node.annotations)

                old_interface.__dict__[what] = filter(has_annotations, old_list)

            return changed

        # Smartly merge various declarations:
        if merge_list('parents'):
            changed = True
        if merge_list('constants'):
            changed = True
        if merge_list('attributes'):
            changed = True
        if merge_list('operations'):
            changed = True

        if self._merge_ext_attrs(old_interface.ext_attrs,
                                 new_interface.ext_attrs):
            changed = True

        _logger.info('merged interface %s (changed=%s, supplemental=%s)' %
                     (old_interface.id, changed, new_interface.is_supplemental))

        return changed

    def _merge_impl_stmt(self, impl_stmt, import_options):
        """Applies "X implements Y" statemetns on the proper places in the
    database"""
        implementor_name = impl_stmt.implementor.id
        implemented_name = impl_stmt.implemented.id
        _logger.info('merging impl stmt %s implements %s' % (implementor_name,
                                                             implemented_name))

        source = import_options.source
        if self._database.HasInterface(implementor_name):
            interface = self._database.GetInterface(implementor_name)
            if interface.parents is None:
                interface.parents = []
            for parent in interface.parents:
                if parent.type.id == implemented_name:
                    if source and source not in parent.annotations:
                        parent.annotations[source] = IDLAnnotation(
                            import_options.source_attributes)
                    return
            # not found, so add new one
            parent = IDLParentInterface(None)
            parent.type = IDLType(implemented_name)
            if source:
                parent.annotations[source] = IDLAnnotation(
                    import_options.source_attributes)
            interface.parents.append(parent)

    def merge_imported_interfaces(self):
        """Merges all imported interfaces and loads them into the DB."""
        imported_interfaces = self._imported_interfaces

        # Step 1: Pre process imported interfaces
        for interface, import_options in imported_interfaces:
            self._annotate(interface, import_options)

        # Step 2: Add all new interfaces and merge overlapping ones
        for interface, import_options in imported_interfaces:
            if not interface.is_supplemental:
                if self._database.HasInterface(interface.id):
                    old_interface = self._database.GetInterface(interface.id)
                    self._merge_interfaces(old_interface, interface,
                                           import_options)
                else:
                    if import_options.add_new_interfaces:
                        self._database.AddInterface(interface)

        # Step 3: Merge in supplemental interfaces
        for interface, import_options in imported_interfaces:
            if interface.is_supplemental:
                target = interface.id
                if self._database.HasInterface(target):
                    old_interface = self._database.GetInterface(target)
                    self._merge_interfaces(old_interface, interface,
                                           import_options)
                else:
                    _logger.warning("Supplemental target '%s' not found",
                                    target)

        # Step 4: Resolve 'implements' statements
        for impl_stmt, import_options in self._impl_stmts:
            self._merge_impl_stmt(impl_stmt, import_options)

        self._impl_stmts = []
        self._imported_interfaces = []

    def _compute_dart_idl_implements(self, idl_filename):
        full_path = os.path.realpath(idl_filename)

        with open(full_path) as f:
            idl_file_contents = f.read()

        implements_re = (r'^\s*' r'(\w+)\s+' r'implements\s+' r'(\w+)\s*' r';')

        implements_matches = re.finditer(implements_re, idl_file_contents,
                                         re.MULTILINE)
        return [match.groups() for match in implements_matches]

    # Compile the IDL file with the Blink compiler and remember each AST for the
    # IDL.
    def _blink_compile_idl_files(self, file_paths, import_options, is_dart_idl):
        if not (is_dart_idl):
            start_time = time.time()

            # Compute information for individual files
            # Information is stored in global variables interfaces_info and
            # partial_interface_files.
            for file_path in file_paths:
                self._info_collector.collect_info(file_path)

            end_time = time.time()
            print 'Compute dependencies %s seconds' % round(
                (end_time - start_time), 2)
        else:
            # Compute the interface_info for dart.idl for implements defined.  This
            # file is special in that more than one interface can exist in this file.
            implement_pairs = self._compute_dart_idl_implements(file_paths[0])

            self._info_collector.interfaces_info['__dart_idl___'] = {
                'implement_pairs': implement_pairs,
            }

        # Parse the IDL files serially.
        start_time = time.time()

        for file_path in file_paths:
            file_path = os.path.normpath(file_path)
            ast = _compile_idl_file(self.build, file_path, import_options)
            self._process_ast(
                os.path.splitext(os.path.basename(file_path))[0], ast)

        end_time = time.time()
        print 'Compiled %s IDL files in %s seconds' % (
            len(file_paths), round((end_time - start_time), 2))

    def _process_ast(self, filename, ast):
        if len(ast) == 1:
            ast = ast.values()[0]
        else:
            print 'ERROR: Processing AST: ' + os.path.basename(file_name)
        new_asts[filename] = ast

    def import_idl_files(self, file_paths, import_options, is_dart_idl):
        self._blink_compile_idl_files(file_paths, import_options, is_dart_idl)

        start_time = time.time()

        # Parse the IDL files in serial.
        for file_path in file_paths:
            file_path = os.path.normpath(file_path)
            idl_file = _load_idl_file(self.build, file_path, import_options)
            _logger.info('Processing %s' % os.path.splitext(
                os.path.basename(file_path))[0])
            self._process_idl_file(idl_file, import_options, is_dart_idl)

        end_time = time.time()

        for warning in report_unions_to_any():
            _logger.warning(warning)

        print 'Total %s files %sprocessed in databasebuilder in %s seconds' % \
        (len(file_paths), '', round((end_time - start_time), 2))

    def _process_idl_file(self, idl_file, import_options, dart_idl=False):
        # TODO(terry): strip_ext_attributes on an idl_file does nothing.
        #self._strip_ext_attributes(idl_file)
        self._resolve_type_defs(idl_file)
        self._rename_types(idl_file, import_options)

        def enabled(idl_node):
            return self._is_node_enabled(idl_node, import_options.idl_defines)

        for interface in idl_file.interfaces:
            if not self._is_node_enabled(interface, import_options.idl_defines):
                _logger.info('skipping interface %s (source=%s)' %
                             (interface.id, import_options.source))
                continue

            _logger.info('importing interface %s (source=%s file=%s)' %
                         (interface.id, import_options.source,
                          os.path.basename(idl_file.filename)))

            interface.attributes = filter(enabled, interface.attributes)
            interface.operations = filter(enabled, interface.operations)
            self._imported_interfaces.append((interface, import_options))

        # If an IDL dictionary then there is no implementsStatements.
        if hasattr(idl_file, 'implementsStatements'):
            for implStmt in idl_file.implementsStatements:
                self._impl_stmts.append((implStmt, import_options))

        for enum in idl_file.enums:
            self._database.AddEnum(enum)

        for dictionary in idl_file.dictionaries:
            self._database.AddDictionary(dictionary)

        # TODO(terry): Hack to remember all typedef unions they're mapped to any
        #              - no type.
        for typedef in idl_file.typeDefs:
            self._database.AddTypeDef(typedef)

    def _is_node_enabled(self, node, idl_defines):
        if not 'Conditional' in node.ext_attrs:
            return True

        def enabled(condition):
            return 'ENABLE_%s' % condition in idl_defines

        conditional = node.ext_attrs['Conditional']
        if conditional.find('&') != -1:
            for condition in conditional.split('&'):
                condition = condition.strip()
                self.conditionals_met.add(condition)
                if not enabled(condition):
                    return False
            return True

        for condition in conditional.split('|'):
            condition = condition.strip()
            self.conditionals_met.add(condition)
            if enabled(condition):
                return True
        return False

    def fix_displacements(self, source):
        """E.g. In W3C, something is declared on HTMLDocument but in WebKit
    its on Document, so we need to mark that something in HTMLDocument
    with @WebKit(via=Document). The 'via' attribute specifies the
    parent interface that has the declaration."""

        for interface in self._database.GetInterfaces():
            changed = False

            _logger.info('fixing displacements in %s' % interface.id)

            for parent_interface in self._get_parent_interfaces(interface):
                _logger.info('scanning parent %s of %s' % (parent_interface.id,
                                                           interface.id))

                def fix_nodes(local_list, parent_list):
                    changed = False
                    parent_signatures_map = self._build_signatures_map(
                        parent_list)
                    for idl_node in local_list:
                        sig = self._sign(idl_node)
                        if sig in parent_signatures_map:
                            parent_member = parent_signatures_map[sig]
                            if (source in parent_member.annotations and
                                    source not in idl_node.annotations and
                                    _VIA_ANNOTATION_ATTR_NAME not in
                                    parent_member.annotations[source]):
                                idl_node.annotations[source] = IDLAnnotation({
                                    _VIA_ANNOTATION_ATTR_NAME:
                                    parent_interface.id
                                })
                                changed = True
                    return changed

                changed = fix_nodes(interface.constants,
                                    parent_interface.constants) or changed
                changed = fix_nodes(interface.attributes,
                                    parent_interface.attributes) or changed
                changed = fix_nodes(interface.operations,
                                    parent_interface.operations) or changed
            if changed:
                _logger.info(
                    'fixed displaced declarations in %s' % interface.id)

    def normalize_annotations(self, sources):
        """Makes the IDLs less verbose by removing annotation attributes
    that are identical to the ones defined at the interface level.

    Args:
      sources -- list of source names to normalize."""
        for interface in self._database.GetInterfaces():
            _logger.debug('normalizing annotations for %s' % interface.id)
            for source in sources:
                if (source not in interface.annotations or
                        not interface.annotations[source]):
                    continue
                top_level_annotation = interface.annotations[source]

                def normalize(idl_node):
                    if (source in idl_node.annotations and
                            idl_node.annotations[source]):
                        annotation = idl_node.annotations[source]
                        for name, value in annotation.items():
                            if (name in top_level_annotation and
                                    value == top_level_annotation[name]):
                                del annotation[name]

                map(normalize, interface.parents)
                map(normalize, interface.constants)
                map(normalize, interface.attributes)
                map(normalize, interface.operations)

    def map_dictionaries(self):
        """Changes the type of operations/constructors arguments from an IDL
       dictionary to a Dictionary.  The IDL dictionary is just an enums of
       strings which are checked at run-time."""

        def dictionary_to_map(type_node):
            if self._database.HasDictionary(type_node.id):
                type_node.dictionary = type_node.id
                type_node.id = 'Dictionary'

        def all_types(node):
            map(dictionary_to_map, node.all(IDLType))

        for interface in self._database.GetInterfaces():
            map(all_types, interface.all(IDLExtAttrFunctionValue))
            map(all_types, interface.attributes)
            map(all_types, interface.operations)

    def fetch_constructor_data(self, options):
        window_interface = self._database.GetInterface('Window')
        for attr in window_interface.attributes:
            type = attr.type.id
            if not type.endswith('Constructor'):
                continue
            type = re.sub('(Constructor)+$', '', type)
            # TODO(antonm): Ideally we'd like to have pristine copy of WebKit IDLs and fetch
            # this information directly from it.  Unfortunately right now database is massaged
            # a lot so it's difficult to maintain necessary information on Window itself.
            interface = self._database.GetInterface(type)
            if 'V8EnabledPerContext' in attr.ext_attrs:
                interface.ext_attrs['synthesizedV8EnabledPerContext'] = \
                    attr.ext_attrs['V8EnabledPerContext']
            if 'V8EnabledAtRuntime' in attr.ext_attrs:
                interface.ext_attrs['synthesizedV8EnabledAtRuntime'] = \
                    attr.ext_attrs['V8EnabledAtRuntime'] or attr.id

    # Iterate of the database looking for relationships between dictionaries and
    # interfaces marked with NoInterfaceObject.  This mechanism can be used for
    # other IDL analysis.
    def examine_database(self):
        # Contains list of dictionary structure: {'dictionary': dictionary, 'usages': []}
        self._diag_dictionaries = []
        self._dictionaries_used_types = []

        # Record any dictionary.
        for dictionary in self._database.GetDictionaries():
            self._diag_dictionaries.append({
                'dictionary': dictionary,
                'usages': []
            })

        # Contains list of NoInterfaceObject structures: {'no_interface_object': dictionary, 'usages': []}
        self._diag_no_interfaces = []
        self._no_interfaces_used_types = []

        # Record any interface with Blink IDL Extended Attribute 'NoInterfaceObject'.
        for interface in self._database.GetInterfaces():
            if interface.is_no_interface_object:
                self._diag_no_interfaces.append({
                    'no_interface_object':
                    interface,
                    'usages': []
                })

        for interface in self._database.GetInterfaces():
            self._constructors(interface)
            self._constructors(interface, check_dictionaries=False)

            for attribute in interface.attributes:
                self._attribute_operation(interface, attribute)
                self._attribute_operation(
                    interface, attribute, check_dictionaries=False)

            for operation in interface.operations:
                self._attribute_operation(interface, operation)
                self._attribute_operation(
                    interface, operation, check_dictionaries=False)

        # Report all dictionaries and their usage.
        self._output_examination()
        # Report all interface marked with NoInterfaceObject and their usage.
        self._output_examination(check_dictionaries=False)

        print '\nKey:'
        print '  (READ-ONLY) - read-only attribute has relationship'
        print '  (GET/SET)   - attribute has relationship'
        print '  RETURN      - operation\'s returned value has relationship'
        print '  (ARGUMENT)  - operation\'s argument(s) has relationship'
        print ''
        print '  (New)       - After dictionary name if constructor(s) exist'
        print '  (Ops,Props,New) after a NoInterfaceObject name is defined as:'
        print '    Ops       - number of operations for a NoInterfaceObject'
        print '    Props     - number of properties for a NoInterfaceObject'
        print '    New       - T(#) number constructors for a NoInterfaceObject'
        print '                F no constructors for a NoInterfaceObject'
        print '                e.g., an interface 5 operations, 3 properties and 2'
        print '                      constructors would display (5,3,T(2))'

        print '\n\nExamination Complete\n'

    def _output_examination(self, check_dictionaries=True):
        # Output diagnostics. First columns is Dictionary or NoInterfaceObject e.g.,
        # |  Dictionary  |  Used In Interface  |  Usage Operation/Attribute  |
        print '\n\n'
        title_bar = ['Dictionary', 'Used In Interface', 'Usage Operation/Attribute'] if check_dictionaries \
                    else ['NoInterfaceObject (Ops,Props,New)', 'Used In Interface', 'Usage Operation/Attribute']
        self._tabulate_title(title_bar)
        diags = self._diag_dictionaries if check_dictionaries else self._diag_no_interfaces
        for diag in diags:
            if not (check_dictionaries):
                interface = diag['no_interface_object']
                ops_count = len(interface.operations)
                properties_count = len(interface.attributes)
                any_constructors = 'Constructor' in interface.ext_attrs
                constructors = 'T(%s)' % len(interface.ext_attrs['Constructor']
                                            ) if any_constructors else 'F'
                interface_detail = '%s (%s,%s,%s)' % \
                    (diag['no_interface_object'].id,
                     ops_count,
                     properties_count,
                     constructors)
                self._tabulate([interface_detail, '', ''])
            else:
                dictionary = diag['dictionary']
                any_constructors = 'Constructor' in dictionary.ext_attrs
                self._tabulate([
                    '%s%s' % (dictionary.id,
                              ' (New)' if any_constructors else ''), '', ''
                ])
            for usage in diag['usages']:
                detail = ''
                if 'attribute' in usage:
                    attribute_type = 'READ-ONLY' if not usage[
                        'argument'] else 'GET/SET'
                    detail = '(%s) %s' % (attribute_type, usage['attribute'])
                elif 'operation' in usage:
                    detail = '%s %s%s' % ('RETURN' if usage['result'] else '',
                                          usage['operation'], '(ARGUMENT)'
                                          if usage['argument'] else '')
                self._tabulate([None, usage['interface'], detail])
            self._tabulate_break()

    # operation_or_attribute either IDLOperation or IDLAttribute if None then
    # its a constructor (IDLExtAttrFunctionValue).
    def _mark_usage(self,
                    interface,
                    operation_or_attribute=None,
                    check_dictionaries=True):
        for diag in self._diag_dictionaries if check_dictionaries else self._diag_no_interfaces:
            for usage in diag['usages']:
                if not usage['interface']:
                    usage['interface'] = interface.id
                    if isinstance(operation_or_attribute, IDLOperation):
                        usage['operation'] = operation_or_attribute.id
                        if check_dictionaries:
                            usage['result'] = hasattr(operation_or_attribute.type, 'dictionary') and \
                              operation_or_attribute.type.dictionary == diag['dictionary'].id
                        else:
                            usage[
                                'result'] = operation_or_attribute.type.id == diag[
                                    'no_interface_object'].id
                        usage['argument'] = False
                        for argument in operation_or_attribute.arguments:
                            if check_dictionaries:
                                arg = hasattr(
                                    argument.type, 'dictionary'
                                ) and argument.type.dictionary == diag[
                                    'dictionary'].id
                            else:
                                arg = argument.type.id == diag[
                                    'no_interface_object'].id
                            if arg:
                                usage['argument'] = arg
                    elif isinstance(operation_or_attribute, IDLAttribute):
                        usage['attribute'] = operation_or_attribute.id
                        usage['result'] = True
                        usage[
                            'argument'] = not operation_or_attribute.is_read_only
                    elif not operation_or_attribute:
                        # Its a constructor only argument is dictionary or interface with NoInterfaceObject.
                        usage['operation'] = 'constructor'
                        usage['result'] = False
                        usage['argument'] = True

    def _remember_usage(self, node, check_dictionaries=True):
        if check_dictionaries:
            used_types = self._dictionaries_used_types
            diag_list = self._diag_dictionaries
            diag_name = 'dictionary'
        else:
            used_types = self._no_interfaces_used_types
            diag_list = self._diag_no_interfaces
            diag_name = 'no_interface_object'

        if len(used_types) > 0:
            normalized_used = list(set(used_types))
            for recorded_id in normalized_used:
                for diag in diag_list:
                    if diag[diag_name].id == recorded_id:
                        diag['usages'].append({'interface': None, 'node': node})

    # Iterator function to look for any IDLType that is a dictionary then remember
    # that dictionary.
    def _dictionary_used(self, type_node):
        if hasattr(type_node, 'dictionary'):
            dictionary_id = type_node.dictionary
            if self._database.HasDictionary(dictionary_id):
                for diag_dictionary in self._diag_dictionaries:
                    if diag_dictionary['dictionary'].id == dictionary_id:
                        # Record the dictionary that was referenced.
                        self._dictionaries_used_types.append(dictionary_id)
                        return

            # If we get to this point, the IDL dictionary was never defined ... oops.
            print 'DIAGNOSE_ERROR: IDL Dictionary %s doesn\'t exist.' % dictionary_id

    # Iterator function to look for any IDLType that is an interface marked with
    # NoInterfaceObject then remember that interface.
    def _no_interface_used(self, type_node):
        if hasattr(type_node, 'id'):
            no_interface_id = type_node.id
            if self._database.HasInterface(no_interface_id):
                no_interface = self._database.GetInterface(no_interface_id)
                if no_interface.is_no_interface_object:
                    for diag_no_interface in self._diag_no_interfaces:
                        if diag_no_interface[
                                'no_interface_object'].id == no_interface_id:
                            # Record the interface marked with NoInterfaceObject.
                            self._no_interfaces_used_types.append(
                                no_interface_id)
                            return

    def _constructors(self, interface, check_dictionaries=True):
        if check_dictionaries:
            self._dictionaries_used_types = []
            constructor_function = self._dictionary_constructor_types
        else:
            self._no_interfaces_used_types = []
            constructor_function = self._no_interface_constructor_types

        map(constructor_function, interface.all(IDLExtAttrFunctionValue))

        self._mark_usage(interface, check_dictionaries=check_dictionaries)

    # Scan an attribute or operation for a dictionary or interface with NoInterfaceObject
    # reference.
    def _attribute_operation(self,
                             interface,
                             operation_attribute,
                             check_dictionaries=True):
        if check_dictionaries:
            self._dictionaries_used_types = []
            used = self._dictionary_used
        else:
            self._no_interfaces_used_types = []
            used = self._no_interface_used

        map(used, operation_attribute.all(IDLType))

        self._remember_usage(
            operation_attribute, check_dictionaries=check_dictionaries)
        self._mark_usage(
            interface,
            operation_attribute,
            check_dictionaries=check_dictionaries)

    # Iterator function for map to iterate over all constructor types
    # (IDLExtAttrFunctionValue) that have a dictionary reference.
    def _dictionary_constructor_types(self, node):
        self._dictionaries_used_types = []
        map(self._dictionary_used, node.all(IDLType))
        self._remember_usage(node)

    # Iterator function for map to iterate over all constructor types
    # (IDLExtAttrFunctionValue) that reference an interface with NoInterfaceObject.
    def _no_interface_constructor_types(self, node):
        self._no_interfaces_used_types = []
        map(self._no_interface_used, node.all(IDLType))
        self._remember_usage(node, check_dictionaries=False)

    # Maximum width of each column.
    def _TABULATE_WIDTH(self):
        return 45

    def _tabulate_title(self, row_title):
        title_separator = "=" * self._TABULATE_WIDTH()
        self._tabulate([title_separator, title_separator, title_separator])
        self._tabulate(row_title)
        self._tabulate([title_separator, title_separator, title_separator])

    def _tabulate_break(self):
        break_separator = "-" * self._TABULATE_WIDTH()
        self._tabulate([break_separator, break_separator, break_separator])

    def _tabulate(self, columns):
        """Tabulate a list of columns for a row.  Each item in columns is a column
       value each column will be padded up to _TABULATE_WIDTH.  Each
       column starts/ends with a vertical bar '|' the format a row:

           | columns[0] | columns[1] | columns[2] | ... |
    """
        if len(columns) > 0:
            for column in columns:
                value = '' if not column else column
                sys.stdout.write('|{0:^{1}}'.format(value,
                                                    self._TABULATE_WIDTH()))
        else:
            sys.stdout.write('|{0:^{1}}'.format('', self._TABULATE_WIDTH()))

        sys.stdout.write('|\n')
