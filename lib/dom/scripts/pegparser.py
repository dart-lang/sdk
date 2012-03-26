#!/usr/bin/python
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import logging
import re
import weakref

_logger = logging.getLogger('pegparser')

# functions can refer to each other, hence creating infinite loops. The
# following hashmap is used to memoize functions that were already compiled.
_compiled_functions_memory = weakref.WeakKeyDictionary()

_regex_type = type(re.compile(r''))
_list_type = type([])
_function_type = type(lambda func: 0)


class _PegParserState(object):
  """Object for storing parsing state variables and options"""

  def __init__(self, text, whitespace_rule, strings_are_tokens):
    # Parsing state:
    self.text = text
    self.is_whitespace_mode = False

    # Error message helpers:
    self.max_pos = None
    self.max_rule = None

    # Parsing options:
    self.whitespace_rule = whitespace_rule
    self.strings_are_tokens = strings_are_tokens


class _PegParserRule(object):
  """Base class for all rules"""

  def __init__(self):
    return

  def __str__(self):
    return self.__class__.__name__

  def _match_impl(self, state, pos):
    """Default implementation of the matching algorithm.
    Should be overwritten by sub-classes.
    """
    raise RuntimeError('_match_impl not implemented')

  def match(self, state, pos):
    """Matches the rule against the text in the given position.

    The actual rule evaluation is delegated to _match_impl,
    while this function deals mostly with support tasks such as
    skipping whitespace, debug information and data for exception.

    Args:
      state -- the current parsing state and options.
      pos -- the current offset in the text.

    Returns:
      (next position, value) if the rule matches, or
      (None, None) if it doesn't.
    """
    if not state.is_whitespace_mode:
      # Skip whitespace
      pos = _skip_whitespace(state, pos)

      # Track position for possible error messaging
      if pos > state.max_pos:
        # Store position and the rule.
        state.max_pos = pos
        if isinstance(self, _StringRule):
          state.max_rule = [self]
        else:
          state.max_rule = []
      elif pos == state.max_pos:
        if isinstance(self, _StringRule):
          state.max_rule.append(self)

      if _logger.isEnabledFor(logging.DEBUG):
        # Used for debugging
        _logger.debug('Try:   pos=%s char=%s rule=%s' % \
          (pos, state.text[pos:pos + 1], self))

    # Delegate the matching logic to the the specialized function.
    res = self._match_impl(state, pos)

    if not state.is_whitespace_mode \
      and _logger.isEnabledFor(logging.DEBUG):
      # More debugging information
      (nextPos, ast) = res
      if nextPos is not None:
        _logger.debug('Match! pos=%s char=%s rule=%s' % \
          (pos, state.text[pos:pos + 1], self))
      else:
        _logger.debug('Fail.  pos=%s char=%s rule=%s' % \
          (pos, state.text[pos:pos + 1], self))

    return res


def _compile(rule):
  """Recursively compiles user-defined rules into parser rules.
  Compilation is performed by converting strings, regular expressions, lists
  and functions into _StringRule, _RegExpRule, SEQUENCE and _FunctionRule
  (respectively). Memoization is used to avoid infinite recursion as rules
  may refer to each other."""
  if rule is None:
    raise RuntimeError('None is not a valid rule')
  elif isinstance(rule, str):
    return _StringRule(rule)
  elif isinstance(rule, _regex_type):
    return _RegExpRule(rule)
  elif isinstance(rule, _list_type):
    return SEQUENCE(*rule)
  elif isinstance(rule, _function_type):
    # Memoize compiled functions to avoid infinite compliation loops.
    if rule in _compiled_functions_memory:
      return _compiled_functions_memory[rule]
    else:
      compiled_function = _FunctionRule(rule)
      _compiled_functions_memory[rule] = compiled_function
      compiled_function._sub_rule = _compile(rule())
      return compiled_function
  elif isinstance(rule, _PegParserRule):
    return rule
  else:
    raise RuntimeError('Invalid rule type %s: %s', (type(rule), rule))


def _skip_whitespace(state, pos):
  """Returns the next non-whitespace position.
  This is done by matching the optional whitespace_rule with the current
  text."""
  if not state.whitespace_rule:
    return pos
  state.is_whitespace_mode = True
  nextPos = pos
  while nextPos is not None:
    pos = nextPos
    (nextPos, ast) = state.whitespace_rule.match(state, pos)
  state.is_whitespace_mode = False
  return pos


class _StringRule(_PegParserRule):
  """This rule tries to match a whole string."""

  def __init__(self, string):
    """Constructor.
    Args:
      string -- string to match.
    """
    _PegParserRule.__init__(self)
    self._string = string

  def __str__(self):
    return '"%s"' % self._string

  def _match_impl(self, state, pos):
    """Tries to match the string at the current position"""
    if state.text.startswith(self._string, pos):
      nextPos = pos + len(self._string)
      if state.strings_are_tokens:
        return (nextPos, None)
      else:
        return (nextPos, self._string)
    return (None, None)


class _RegExpRule(_PegParserRule):
  """This rule tries to matches a regular expression."""

  def __init__(self, reg_exp):
    """Constructor.
    Args:
      reg_exp -- a regular expression used in matching.
    """
    _PegParserRule.__init__(self)
    self.reg_exp = reg_exp

  def __str__(self):
    return 'regexp'

  def _match_impl(self, state, pos):
    """Tries to match the regular expression with current text"""
    matchObj = self.reg_exp.match(state.text, pos)
    if matchObj:
      matchStr = matchObj.group()
      return (pos + len(matchStr), matchStr)
    return (None, None)


class _FunctionRule(_PegParserRule):
  """Function rule wraps a rule defined via a Python function.

  Defining rules via functions helps break the grammar into parts, labeling
  the ast, and supporting recursive definitions in the grammar

  Usage Example:
    def Func(): return ['function', TOKEN('('), TOKEN(')')]
    def Var(): return OR('x', 'y')
    def Program(): return OR(Func, Var)

  When matched with 'function()', will return the tuple:
    ('Program', ('Func', 'function'))
  When matched with 'x', will return the tuple:
    ('Program', ('Var', 'x'))

  Functions who's name begins with '_' will not be labelled. This is useful
  for creating utility rules. Extending the example above:

    def _Program(): return OR(Func, Var)

  When matched with 'function()', will return the tuple:
    ('Func', 'function')
  """

  def __init__(self, func):
    """Constructor.
    Args:
      func -- the original function will be used for labeling output.
    """
    _PegParserRule.__init__(self)
    self._func = func
    # Sub-rule is compiled by _compile to avoid infinite recursion.
    self._sub_rule = None

  def __str__(self):
    return self._func.__name__

  def _match_impl(self, state, pos):
    """Simply invokes the sub rule"""
    (nextPos, ast) = self._sub_rule.match(state, pos)
    if nextPos is not None:
      if not self._func.__name__.startswith('_'):
        ast = (self._func.__name__, ast)
      return (nextPos, ast)
    return (None, None)


class SEQUENCE(_PegParserRule):
  """This rule expects all given rules to match in sequence.
  Note that SEQUENCE is equivalent to a rule composed of a Python list of
  rules.
  Usage example: SEQUENCE('A', 'B', 'C')
         or: ['A', 'B', 'C']
  Will match 'ABC' but not 'A', 'B' or ''.
  """
  def __init__(self, *rules):
    """Constructor.
    Args:
      rules -- one or more rules to match.
    """
    _PegParserRule.__init__(self)
    self._sub_rules = []
    for rule in rules:
      self._sub_rules.append(_compile(rule))

  def _match_impl(self, state, pos):
    """Tries to match all the sub rules"""
    sequence = []
    for rule in self._sub_rules:
      (nextPos, ast) = rule.match(state, pos)
      if nextPos is not None:
        if ast:
          if isinstance(ast, _list_type):
            sequence.extend(ast)
          else:
            sequence.append(ast)
        pos = nextPos
      else:
        return (None, None)
    return (pos, sequence)


class OR(_PegParserRule):
  """This rule matches one and only one of multiple sub-rules.
  Usage example: OR('A', 'B', 'C')
  Will match 'A', 'B' or 'C'.
  """
  def __init__(self, *rules):
    """Constructor.
    Args:
      rules -- rules to choose from.
    """
    _PegParserRule.__init__(self)
    self._sub_rules = []
    for rule in rules:
      self._sub_rules.append(_compile(rule))

  def _match_impl(self, state, pos):
    """Tries to match at leat one of the sub rules"""
    for rule in self._sub_rules:
      (nextPos, ast) = rule.match(state, pos)
      if nextPos is not None:
        return (nextPos, ast)
    return (None, None)


class MAYBE(_PegParserRule):
  """Will try to match the given rule, tolerating absence.
  Usage example: MAYBE('A')
  Will match 'A' but also ''.
  """
  def __init__(self, rule):
    """Constructor.
    Args:
      rule -- the rule that may be absent.
    """
    _PegParserRule.__init__(self)
    self._sub_rule = _compile(rule)

  def _match_impl(self, state, pos):
    """Tries to match at leat one of the sub rules"""
    (nextPos, ast) = self._sub_rule.match(state, pos)
    if nextPos is not None:
      return (nextPos, ast)
    return (pos, None)


class MANY(_PegParserRule):
  """Will try to match the given rule one or more times.
  Usage example 1: MANY('A')
  Will match 'A', 'AAAAA' but not ''.
  Usage example 2: MANY('A', separator=',')
  Will match 'A', 'A,A' but not 'AA'.
  """

  def __init__(self, rule, separator=None):
    """Constructor.
    Args:
      rule -- the rule to match multiple times.
      separator -- this optional rule is used to match separators.
    """
    _PegParserRule.__init__(self)
    self._sub_rule = _compile(rule)
    self._separator = _compile(separator) if separator else None

  def _match_impl(self, state, pos):
    res = []
    count = 0
    while True:
      if count > 0 and self._separator:
        (nextPos, ast) = self._separator.match(state, pos)
        if nextPos is not None:
          pos = nextPos
          if ast:
            res.append(ast)
        else:
          break
      (nextPos, ast) = self._sub_rule.match(state, pos)
      if nextPos is None:
        break
      count += 1
      pos = nextPos
      res.append(ast)
    if count > 0:
      return (pos, res)
    return (None, None)


class TOKEN(_PegParserRule):
  """The matched rule will not appear in the the output.
  Usage example: ['A', TOKEN('.'), 'B']
  When matching 'A.B', will return the sequence ['A', 'B'].
  """

  def __init__(self, rule):
    """Constructor.
    Args:
      rule -- the rule to match.
    """
    _PegParserRule.__init__(self)
    self._sub_rule = _compile(rule)

  def _match_impl(self, state, pos):
    (nextPos, ast) = self._sub_rule.match(state, pos)
    if nextPos is not None:
      return (nextPos, None)
    return (None, None)


class LABEL(_PegParserRule):
  """The matched rule will appear in the output with the given label.
  Usage example: LABEL('number', re.compile(r'[0-9]+'))
  When matched with '1234', will return ('number', '1234').

  Keyword arguments:
  label -- a string.
  rule -- the rule to match.
  """

  def __init__(self, label, rule):
    """Constructor.
    Args:
      rule -- the rule to match.
    """
    _PegParserRule.__init__(self)
    self._label = label
    self._sub_rule = _compile(rule)

  def _match_impl(self, state, pos):
    (nextPos, ast) = self._sub_rule.match(state, pos)
    if nextPos is not None:
      return (nextPos, (self._label, ast))
    return (None, None)


class RAISE(_PegParserRule):
  """Raises a SyntaxError with a user-provided message.
  Usage example: ['A','B', RAISE('should have not gotten here')]
  Will not match 'A' but will raise an exception for 'AB'.
  This rule is useful mostly for debugging grammars.
  """
  def __init__(self, message):
    """Constructor.
    Args:
      message -- the message for the raised exception.
    """
    _PegParserRule.__init__(self)
    self._message = message

  def _match_impl(self, state, pos):
    raise RuntimeError(self._message)


class PegParser(object):
  """PegParser class.
  This generic parser can be configured with rules to parse a wide
  range of inputs.
  """

  def __init__(self, root_rule, whitespace_rule=None,
         strings_are_tokens=False):
    """Initializes a PegParser with rules and parsing options.

    Args:
      root_rule -- the top level rule to start matching at. Rule can be
        a regular expression, a string, or one of the special rules
        such as SEQUENCE, MANY, OR, etc.
      whitespace_rule -- used to identify and strip whitespace. Default
        isNone, configuring the parser to not tolerate whitespace.
      strings_are_tokens -- by default string rules are not treated as
        tokens. In many programming languages, strings are tokens,
        so this should be set to True.
    """
    self._strings_are_tokens = strings_are_tokens
    self._root_rule = _compile(root_rule)
    if whitespace_rule is None:
      self._whitespace_rule = None
    else:
      self._whitespace_rule = _compile(whitespace_rule)

  def parse(self, text, start_pos=0):
    """Parses the given text input
    Args:
      text -- data to parse.
      start_pos -- the offset to start parsing at.

    Returns:
      An abstract syntax tree, with nodes being pairs of the format
      (label, value), where label is a string or a function, and value
      is a string, a pair or a list of pairs.
    """

    def calculate_line_number_and_offset(globalOffset):
      """Calculates the line number and in-line offset"""
      i = 0
      lineNumber = 1
      lineOffset = 0
      lineData = []
      while i < globalOffset and i < len(text):
        if text[i] == '\n':
          lineNumber += 1
          lineOffset = 0
          lineData = []
        else:
          lineData.append(text[i])
          lineOffset += 1
        i += 1
      while i < len(text) and  text[i] != '\n':
        lineData.append(text[i])
        i += 1
      return (lineNumber, lineOffset, ''.join(lineData))

    def analyze_result(state, pos, ast):
      """Analyze match output"""
      if pos is not None:
        # Its possible that matching is successful but trailing
        # whitespace remains, so skip it.
        pos = _skip_whitespace(state, pos)
      if pos == len(state.text):
        # End of intput reached. Success!
        return ast

      # Failure - analyze and raise an error.
      (lineNumber, lineOffset, lineData) = \
        calculate_line_number_and_offset(state.max_pos)
      message = 'unexpected error'
      if state.max_rule:
        set = {}
        map(set.__setitem__, state.max_rule, [])

        def to_str(item):
          return item.__str__()

        expected = ' or '.join(map(to_str, set.keys()))
        found = state.text[state.max_pos:state.max_pos + 1]
        message = 'Expected %s but "%s" found: "%s"' % \
          (expected, found, lineData)
      raise SyntaxError(
        'At line %s offset %s: %s' % \
        (lineNumber, lineOffset, message))

    # Initialize state
    state = _PegParserState(text,
      whitespace_rule=self._whitespace_rule,
      strings_are_tokens=self._strings_are_tokens)

    # Match and analyze result
    (pos, ast) = self._root_rule.match(state, start_pos)
    return analyze_result(state, pos, ast)
