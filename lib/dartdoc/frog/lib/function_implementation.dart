// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Exception thrown when a function receives the wrong number of arguments at
/// runtime. Overridden to provide a more informative error message.
// TODO(jmesserly): should the base class support a message?
class _ArgumentMismatchException extends ClosureArgumentMismatchException {
  final String _message;
  const _ArgumentMismatchException(this._message);
  String toString() => "Closure argument mismatch: $_message";
}

/// Implementation details for [Function]
/// Note: we don't expose this because it has no useful API. It's just some
/// helpers for our dynamic calling convention. Maybe in the future there will
/// be more stuff here, though.
class _FunctionImplementation implements Function native "Function" {
  /**
   * Generates a dynamic call stub for a function.
   * Our goal is to create a stub method like this on-the-fly:
   *   function($0, $1, capture) { return this($0, $1, true, capture); }
   *
   * This stub then replaces the dynamic one on Function, with one that is
   * specialized for that particular function, taking into account its default
   * arguments.
   */
  _genStub(argsLength, [names]) native @'''
    // Fast path #1: if no named arguments and arg count matches.
    var thisLength = this.$length || this.length;
    if (thisLength == argsLength && !names) {
      return this;
    }

    var paramsNamed = this.$optional ? (this.$optional.length / 2) : 0;
    var paramsBare = thisLength - paramsNamed;
    var argsNamed = names ? names.length : 0;
    var argsBare = argsLength - argsNamed;

    // Check we got the right number of arguments
    if (argsBare < paramsBare || argsLength > thisLength ||
        argsNamed > paramsNamed) {
      return function() {
        $throw(new _ArgumentMismatchException(
          'Wrong number of arguments to function. Expected ' + paramsBare +
          ' positional arguments and at most ' + paramsNamed +
          ' named arguments, but got ' + argsBare +
          ' positional arguments and ' + argsNamed + ' named arguments.'));
      };
    }

    // First, fill in all of the default values
    var p = new Array(paramsBare);
    if (paramsNamed) {
      p = p.concat(this.$optional.slice(paramsNamed));
    }
    // Fill in positional args
    var a = new Array(argsLength);
    for (var i = 0; i < argsBare; i++) {
      p[i] = a[i] = '$' + i;
    }
    // Then overwrite with supplied values for optional args
    var lastParameterIndex;
    var namesInOrder = true;
    for (var i = 0; i < argsNamed; i++) {
      var name = names[i];
      a[i + argsBare] = name;
      var j = this.$optional.indexOf(name);
      if (j < 0 || j >= paramsNamed) {
        return function() {
          $throw(new _ArgumentMismatchException(
            'Named argument "' + name + '" was not expected by function.' +
            ' Did you forget to mark the function parameter [optional]?'));
        };
      } else if (lastParameterIndex && lastParameterIndex > j) {
        namesInOrder = false;
      }
      p[j + paramsBare] = name;
      lastParameterIndex = j;
    }

    if (thisLength == argsLength && namesInOrder) {
      // Fast path #2: named arguments, but they're in order and all supplied.
      return this;
    }

    // Note: using Function instead of 'eval' to get a clean scope.
    // TODO(jmesserly): evaluate the performance of these stubs.
    var f = 'function(' + a.join(',') + '){return $f(' + p.join(',') + ');}';
    return new Function('$f', 'return ' + f + '').call(null, this);
  ''' {
    throw new _ArgumentMismatchException('');
  }
}
