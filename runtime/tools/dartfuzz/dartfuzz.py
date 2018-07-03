#!/usr/bin/env python3
#
# Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import argparse
import random
import time

from enum import IntEnum
from enum import unique

# Version of DartFuzz. Increase this each time changes are made
# to preserve the property that a given version of DartFuzz yields
# the same fuzzed program for a deterministic random seed.

VERSION='1.0'

#
# Dart operators and types.
#

NUM_UNARY_OPS  = [ '-' ]
INT_UNARY_OPS  = NUM_UNARY_OPS + [ '~' ]

BOOL_BIN_OPS   = [ ' && ', ' || ' ]
NUM_BIN_OPS    = [ ' + ', ' - ', ' * ' ]
INT_BIN_OPS    = NUM_BIN_OPS + [ ' & ', ' | ', ' ^ ', ' % ', ' ~/ ', ' >> ', ' << ' ]
FP_BIN_OPS     = NUM_BIN_OPS + [ ' / ' ]

NUM_ASSIGN_OPS = [ ' = ', ' += ', ' -= ', ' *= ' ]
INT_ASSIGN_OPS = NUM_ASSIGN_OPS + [ ' &= ', ' |= ', ' ^= ', ' %= ', ' ~/= ', ' >>= ', ' <<= ' ]
FP_ASSIGN_OPS  = NUM_ASSIGN_OPS + [ ' /= ' ]

NUM_INC_OPS    = [ '++', '--' ]

REL_OPS        = [ ' == ', ' != ' ]
NUM_REL_OPS    = REL_OPS + [ ' > ', ' >= ', ' < ', ' <= ' ]

@unique
class Type(IntEnum):
  """Enum representing Dart types."""
  BOOL = 0,
  INT = 1,
  DOUBLE = 2,
  STRING = 3,
  INT_LIST = 4,
  INT_STRING_MAP = 5

Types = {
  Type.BOOL           : 'bool',
  Type.INT            : 'int',
  Type.DOUBLE         : 'double',
  Type.STRING         : 'String',
  Type.INT_LIST       : 'List<int>',
  Type.INT_STRING_MAP : 'Map<int, String>'
}

TypeList = list(Types.keys())

#
# DartFuzz generator class.
#

class DartFuzz(object):
  """Generates a random, but runnable Dart program for fuzz testing."""

  def  __init__(self, seed):
    """Constructor.

    Args:
      seed: int, random seed from which randomness is obtained.
    """
    self._seed = seed

  def Run(self):
    # Setup
    self._rand = random.Random()
    self._rand.seed(self._seed)
    self._indent = 0
    self._num_classes = self._rand.randint(1, 4)
    # Header.
    self.EmitHeader()
    # Top level.
    for v in range(0, len(TypeList)):
      self.EmitTopVarDecl(v)
    self.EmitTopLevelMethod()
    # Classes.
    for c in range(0, self._num_classes):
      self.EmitClass(c)
    # Main.
    self.EmitMain()

  #
  # Program components.
  #

  def EmitHeader(self):
    self.EmitLn('')
    self.EmitLn('// The Dart Project Fuzz Tester (' + VERSION + ').')
    self.EmitLn('// Program generated as:')
    self.EmitLn('//   dartfuzz.py --seed ' + str(self._seed))
    self.EmitLn('')

  def EmitTopLevelMethod(self):
    self.EmitLn('')
    self.EmitLn('void top() {')
    self._indent += 2
    self.EmitStmtList(0)
    self._indent -= 2
    self.EmitLn('}')

  def EmitTopVarDecl(self, v):
    tp = v  # int as type
    self.EmitType(tp)
    self.Emit(' var' + str(v) + ' = ')
    self.EmitLiteral(tp)
    self.Emit(';', end='\n')

  def EmitClass(self, class_id):
    self.EmitLn('')
    self.EmitLn('class X' + str(class_id), end='')
    if class_id > 0:
      self.Emit(' extends X' + str(class_id - 1))
    self.Emit(' {', end='\n')
    self._indent += 2
    self.EmitFieldDecls()
    self.EmitMethod(class_id)
    self._indent -= 2
    self.EmitLn('}')

  def EmitFieldDecls(self):
    pass

  def EmitMethod(self, class_id):
    self.EmitLn('void run() {')
    self._indent += 2
    if class_id > 0:
      self.EmitLn('super.run();')
    else:
      self.EmitLn('top();')
    self.EmitStmtList(0)
    self._indent -= 2
    self.EmitLn('}')

  def EmitMain(self):
    self.EmitLn('')
    self.EmitLn('main() {')
    self._indent += 2
    self.EmitLn('try {')
    self._indent += 2
    self.EmitLn('new X' + str(self._num_classes - 1) + '().run();')
    self._indent -= 2
    self.EmitLn('} catch (e) {')
    self._indent += 2
    self.EmitLn('print("exception");')
    self._indent -= 2
    self.EmitLn('} finally {')
    self._indent += 2
    for v in range(0, len(TypeList)):
      self.EmitLn("print(var" + str(v) + ");");
    self.EmitLn('print("done");')
    self._indent -= 2
    self.EmitLn('}')
    self._indent -= 2
    self.EmitLn('}')

  #
  # Statements.
  #

  def EmitStmtList(self, depth):
    num_stmts = self._rand.randint(1, 4)
    for s in range(0, num_stmts):
      if not self.EmitStmt(depth):
        return False  # rest would be dead code
    return True

  def EmitStmt(self, depth):
    self.EmitLn('', end='')
    r = self._rand.randint(1, 8)  # favors assignment
    if r == 1 and depth <= 2:
      return self.EmitIf(depth)
    elif r == 2:
      return self.EmitPrint(depth)
    else:
      return self.EmitAssign(depth)

  def EmitIf(self, depth):
    self.Emit('if (')
    self.EmitExpr(Type.BOOL, 0)
    self.Emit(') {', end='\n')
    self._indent += 2
    self.EmitStmtList(depth + 1)
    self._indent -= 2
    self.EmitLn('} else {')
    self._indent += 2
    self.EmitStmtList(depth + 1)
    self._indent -= 2
    self.EmitLn('}')
    return True

  def EmitPrint(self, depth):
    self.Emit('print(')
    tp = self.RandomType()
    self.EmitExpr(tp, 0)
    self.Emit(');', end='\n')
    return True

  def EmitAssign(self, depth):
    tp = self.RandomType()
    self.EmitVar(tp)
    self.EmitAssignOp(tp)
    self.EmitExpr(tp, 0)
    self.Emit(';', end='\n')
    return True

  #
  # Expressions.
  #

  def RandLen(self, x):
    return self._rand.randint(0, len(x) - 1)

  def EmitAssignOp(self, tp):
    if tp == Type.INT:
      self.Emit(INT_ASSIGN_OPS[self.RandLen(INT_ASSIGN_OPS)])
    elif tp == Type.DOUBLE:
      self.Emit(FP_ASSIGN_OPS[self.RandLen(FP_ASSIGN_OPS)])
    else:
      self.Emit(' = ')

  def EmitUnaryOp(self, tp):
    """Emit same type in-out binary operator."""
    if tp == Type.INT:
      self.Emit(INT_UNARY_OPS[self.RandLen(INT_UNARY_OPS)])
    elif tp == Type.DOUBLE:
      self.Emit(NUM_UNARY_OPS[self.RandLen(NUM_UNARY_OPS)])
    else:
      self.Emit(' !')

  def EmitBinOp(self, tp):
    """Emit same type in-out binary operator."""
    if tp == Type.BOOL:
      self.Emit(BOOL_BIN_OPS[self.RandLen(BOOL_BIN_OPS)])
    elif tp == Type.INT:
      self.Emit(INT_BIN_OPS[self.RandLen(INT_BIN_OPS)])
    elif tp == Type.DOUBLE:
      self.Emit(FP_BIN_OPS[self.RandLen(FP_BIN_OPS)])
    else:
      self.Emit(' + ')

  def EmitRelOp(self, tp):
    """Emit one type in, boolean out operator."""
    if tp == Type.INT or tp == Type.DOUBLE:
      self.Emit(NUM_REL_OPS[self.RandLen(NUM_REL_OPS)])
    else:
      self.Emit(REL_OPS[self.RandLen(REL_OPS)])

  def EmitExpr(self, tp, depth):
    if (depth > 2):
      self.EmitTerm(tp)
      return
    r = self._rand.randint(1, 5)
    if r == 1 and tp <= Type.DOUBLE:
      # Unary operator: (~(x))
      self.Emit('(')
      self.EmitUnaryOp(tp)
      self.Emit('(')
      self.EmitExpr(tp, depth + 1)
      self.Emit('))')
    elif r == 2 and tp <= Type.STRING:
      # Binary operator: (x + y)
      self.Emit('(')
      self.EmitExpr(tp, depth + 1)
      self.EmitBinOp(tp)
      self.EmitExpr(tp, depth + 1)
      self.Emit(')')
    elif r == 3 and Type.INT <= tp and tp <= Type.DOUBLE:
      # Pre- or post-increment/decrement: (++x) or (x++)
      self.Emit('(')
      pre = self._rand.randint(1, 1)
      if pre == 1:
        self.Emit(NUM_INC_OPS[self.RandLen(NUM_INC_OPS)])
      self.EmitVar(tp);
      if pre == 2:
        self.Emit(NUM_INC_OPS[self.RandLen(NUM_INC_OPS)])
      self.Emit(')')
    elif r == 4:
      # Type conversion: x.toInt()
      self.EmitTypeConv(tp, depth)
    else:
      # Terminal expression: x or 1
      self.EmitTerm(tp)

  def EmitTypeConv(self, tp, depth):
    if tp == Type.BOOL:
      new_tp = self.RandomType()
      self.Emit('(')
      self.EmitExpr(new_tp, depth + 1)
      self.EmitRelOp(new_tp)
      self.EmitExpr(new_tp, depth + 1)
      self.Emit(')')
    elif tp == Type.INT:
      self.Emit('(')
      self.EmitExpr(Type.DOUBLE, depth + 1)
      self.Emit(').toInt()')
    elif tp == Type.DOUBLE:
      self.Emit('(')
      self.EmitExpr(Type.INT, depth + 1)
      self.Emit(').toDouble()')
    else:
      self.EmitTerm(tp)

  def EmitTerm(self, tp):
    r = self._rand.randint(1, 2)
    if r == 1:
      self.EmitVar(tp)
    else:
      self.EmitLiteral(tp)

  def EmitVar(self, tp):
    v = int(tp)  # type as int
    self.Emit('var' + str(v))

  def EmitLiteral(self, tp):
    if tp == Type.BOOL:
      self.Emit('true' if self._rand.randint(0, 1) == 0 else 'false')
    elif tp == Type.INT:
      self.Emit(str(self._rand.randint(-1000, 1000)))
    elif tp == Type.DOUBLE:
      self.Emit(str(self._rand.uniform(-1000.0, +1000.0)))
    elif tp == Type.STRING:
      len = self._rand.randint(1, 5)
      self.Emit('"' + ''.join(self._rand.choice('AaBbCcDdEeFfGgHh')
                              for _ in range(len)) + '"')
    elif tp == Type.INT_LIST:
      len = self._rand.randint(1, 5)
      self.Emit('[')
      self.EmitLiteral(Type.INT)
      for i in range(1, len):
        self.Emit(', ')
        self.EmitLiteral(Type.INT)
      self.Emit(']')
    elif tp == Type.INT_STRING_MAP:
      len = self._rand.randint(1, 5)
      self.Emit('{ 0 : ')
      self.EmitLiteral(Type.STRING)
      for i in range(1, len):
        self.Emit(', ' + str(i) + ' : ')
        self.EmitLiteral(Type.STRING)
      self.Emit('}')

  #
  # Types.
  #

  def RandomType(self):
    return TypeList[self._rand.randint(0, len(TypeList) - 1)]

  def EmitType(self, tp):
    self.Emit(Types[tp])

  #
  # Output.
  #

  def EmitLn(self, line, end='\n'):
    """Emits indented line to append to program (stdout).

    Args:
      line: string, line to append to program.
    """
    print(self._indent * ' ', end='')
    print(line, end=end)

  def Emit(self, txt, end=''):
    """Emits string to append to program (stdout).

    Args:
      txt: string, text to append to program.
    """
    print(txt, end=end)

#
# Main driver.
#

def main():
  # Handle arguments.
  parser = argparse.ArgumentParser()
  parser.add_argument('--seed', default=0, type=int,
                      help='random seed (0 forces time-based seed)')
  args = parser.parse_args()

  # By default (zero seed), select a random seed.
  seed = args.seed
  if seed == 0:
    # Pick system's best way of seeding randomness.
    # Then pick a user visible nonzero seed.
    random.seed()
    while seed == 0:
      seed = random.getrandbits(64)

  # Run DartFuzz.
  fuzzer = DartFuzz(seed)
  fuzzer.Run()

if __name__ == '__main__':
  main()
