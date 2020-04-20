#!/usr/bin/python
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
"""Templating to help generate structured text."""

import logging
import re

_logger = logging.getLogger('emitter')


def Format(template, **parameters):
    """Create a string using the same template syntax as Emitter.Emit."""
    e = Emitter()
    e._Emit(template, parameters)
    return ''.join(e.Fragments())


class Emitter(object):
    """An Emitter collects string fragments to be assembled into a single string.
  """

    def __init__(self, bindings=None):
        self._items = []  # A new list
        self._bindings = bindings or Emitter.Frame({}, None)

    def EmitRaw(self, item):
        """Emits literal string with no substitition."""
        self._items.append(item)

    def Emit(self, template_source, **parameters):
        """Emits a template, substituting named parameters and returning emitters to
    fill the named holes.

    Ordinary substitution occurs at $NAME or $(NAME).  If there is no parameter
    called NAME, the text is left as-is. So long as you don't bind FOO as a
    parameter, $FOO in the template will pass through to the generated text.

    Substitution of $?NAME and $(?NAME) yields an empty string if NAME is not a
    parameter.

    Values passed as named parameters should be strings or simple integral
    values (int or long).

    Named holes are created at $!NAME or $(!NAME).  A hole marks a position in
    the template that may be filled in later.  An Emitter is returned for each
    named hole in the template.  The holes are filled by emitting to the
    corresponding emitter.

    Subtemplates can be created by using $#NAME(...), where text can be placed
    inside of the parentheses and will conditionally expand depdending on if
    NAME is set to True or False. The text inside the parentheses may use
    further $#NAME and $NAME substitutions, but is not permitted to create
    holes.

    Emit returns either a single Emitter if the template contains one hole or a
    tuple of emitters for several holes, in the order that the holes occur in
    the template.

    The emitters for the holes remember the parameters passed to the initial
    call to Emit.  Holes can be used to provide a binding context.
    """
        return self._Emit(template_source, parameters)

    def _Emit(self, template_source, parameters):
        """Implementation of Emit, with map in place of named parameters."""
        template = self._ParseTemplate(template_source)
        parameter_bindings = self._bindings.Extend(parameters)

        hole_names = template._holes

        if hole_names:
            hole_map = {}
            replacements = {}
            for name in hole_names:
                emitter = Emitter(parameter_bindings)
                replacements[name] = emitter._items
                hole_map[name] = emitter
            full_bindings = parameter_bindings.Extend(replacements)
        else:
            full_bindings = parameter_bindings

        self._ApplyTemplate(template, full_bindings, self._items)

        # Return None, a singleton or tuple of the hole names.
        if not hole_names:
            return None
        if len(hole_names) == 1:
            return hole_map[hole_names[0]]
        else:
            return tuple(hole_map[name] for name in hole_names)

    def Fragments(self):
        """Returns a list of all the string fragments emitted."""

        def _FlattenTo(item, output):
            if isinstance(item, list):
                for subitem in item:
                    _FlattenTo(subitem, output)
            elif isinstance(item, Emitter.DeferredLookup):
                value = item._environment.Lookup(item._lookup._name,
                                                 item._lookup._value_if_missing)
                if item._lookup._subtemplate:
                    _FlattenSubtemplate(item, value, output)
                else:
                    _FlattenTo(value, output)
            else:
                output.append(str(item))

        def _FlattenSubtemplate(item, value, output):
            """Handles subtemplates created by $#NAME(...)"""
            if value is True:
                # Expand items in subtemplate
                _FlattenTo(item._lookup._subitems, output)
            elif value is not False:
                if value != item._lookup._value_if_missing:
                    raise RuntimeError(
                        'Value for NAME in $#NAME(...) syntax must be a boolean'
                    )
                # Expand it into the string literal composed of $#NAME(,
                # the values inside the parentheses, and ).
                _FlattenTo(value, output)
                _FlattenTo(item._lookup._subitems, output)
                _FlattenTo(')', output)

        output = []
        _FlattenTo(self._items, output)
        return output

    def Bind(self, var, template_source, **parameters):
        """Adds a binding for var to this emitter."""
        template = self._ParseTemplate(template_source)
        if template._holes:
            raise RuntimeError('Cannot have holes in Emitter.Bind')
        bindings = self._bindings.Extend(parameters)
        value = Emitter(bindings)
        value._ApplyTemplate(template, bindings, self._items)
        self._bindings = self._bindings.Extend({var: value._items})
        return value

    def _ParseTemplate(self, source):
        """Converts the template string into a Template object."""
        # TODO(sra): Cache the parsing.
        items = []
        holes = []

        # Break source into a sequence of text fragments and substitution lookups.
        pos = 0
        while True:
            match = Emitter._SUBST_RE.search(source, pos)
            if not match:
                items.append(source[pos:])
                break
            text_fragment = source[pos:match.start()]
            if text_fragment:
                items.append(text_fragment)
            pos = match.end()
            term = match.group()
            name = match.group(1) or match.group(2)  # $NAME and $(NAME)
            if name:
                item = Emitter.Lookup(name, term, term)
                items.append(item)
                continue
            name = match.group(3) or match.group(4)  # $!NAME and $(!NAME)
            if name:
                item = Emitter.Lookup(name, term, term)
                items.append(item)
                holes.append(name)
                continue
            name = match.group(5) or match.group(6)  # $?NAME and $(?NAME)
            if name:
                item = Emitter.Lookup(name, term, '')
                items.append(item)
                holes.append(name)
                continue
            name = match.group(7)                    # $#NAME(...)
            if name:
                # Since it's possible for this to nest, find the matching right
                # paren for this left paren.
                paren_count = 1
                curr_pos = pos
                while curr_pos < len(source):
                    if source[curr_pos] == ')':
                        paren_count -= 1
                        if paren_count == 0:
                            break
                    elif source[curr_pos] == '(':
                        # Account for nested parentheses
                        paren_count += 1
                    curr_pos += 1
                if curr_pos == len(source):
                    # No matching right paren, so not a lookup. Ignore and
                    # continue.
                    items.append(term)
                    continue
                matched_template = self._ParseTemplate(source[pos:curr_pos])
                if len(matched_template._holes) > 0:
                    raise RuntimeError(
                        '$#NAME syntax cannot contains holes in its arguments')
                item = Emitter.Lookup(name, term, term, matched_template)
                items.append(item)
                # Continue after the right paren
                pos = curr_pos + 1
                continue
            raise RuntimeError('Unexpected group')

        if len(holes) != len(set(holes)):
            raise RuntimeError('Cannot have repeated holes %s' % holes)
        return Emitter.Template(items, holes)

    _SUBST_RE = re.compile(
        #  $FOO    $(FOO)      $!FOO    $(!FOO)      $?FOO     $(?FOO)       $#FOO(
        r'\$(\w+)|\$\((\w+)\)|\$!(\w+)|\$\(!(\w+)\)|\$\?(\w+)|\$\(\?(\w+)\)|\$#(\w+)\('
    )

    def _ApplyTemplate(self, template, bindings, items_list):
        """Emits the items from the parsed template."""
        result = []
        for item in template._items:
            if isinstance(item, str):
                if item:
                    result.append(item)
            elif isinstance(item, Emitter.Lookup):
                # Bind lookup to the current environment (bindings)
                # TODO(sra): More space efficient to do direct lookup.
                result.append(Emitter.DeferredLookup(item, bindings))
                # If the item has a subtemplate, apply the subtemplate and save
                # the result in the item's subitems
                if item._subtemplate:
                    self._ApplyTemplate(item._subtemplate, bindings,
                                        item._subitems)
            else:
                raise RuntimeError('Unexpected template element')
        # Collected fragments are in a sublist, so self._items contains one element
        # (sublist) per template application.
        items_list.append(result)

    class Lookup(object):
        """An element of a parsed template."""

        def __init__(self, name, original, default, subtemplate=None):
            self._name = name
            self._original = original
            self._value_if_missing = default
            self._subtemplate = subtemplate
            self._subitems = []

    class DeferredLookup(object):
        """A lookup operation that is deferred until final string generation."""

        # TODO(sra): A deferred lookup will be useful when we add expansions that
        # have behaviour condtional on the contents, e.g. adding separators between
        # a list of items.
        def __init__(self, lookup, environment):
            self._lookup = lookup
            self._environment = environment

    class Template(object):
        """A parsed template."""

        def __init__(self, items, holes):
            self._items = items  # strings and lookups
            self._holes = holes

    class Frame(object):
        """A Frame is a set of bindings derived from a parent."""

        def __init__(self, map, parent):
            self._map = map
            self._parent = parent

        def Lookup(self, name, default):
            if name in self._map:
                return self._map[name]
            if self._parent:
                return self._parent.Lookup(name, default)
            return default

        def Extend(self, map):
            return Emitter.Frame(map, self)
