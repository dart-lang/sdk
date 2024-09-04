// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:front_end/src/api_unstable/vm.dart' show resolveInputUri;

import 'compiler_options.dart';

class Option<T> {
  final String name;
  final void Function(ArgParser a) applyToParser;
  final void Function(WasmCompilerOptions o, T v) _applyToOptions;
  final T Function(dynamic v) converter;

  void applyToOptions(WasmCompilerOptions o, dynamic v) =>
      _applyToOptions(o, converter(v));

  Option(this.name, this.applyToParser, this._applyToOptions, this.converter);
}

class Flag extends Option<bool> {
  Flag(String name, void Function(WasmCompilerOptions o, bool v) applyToOptions,
      {String? abbr,
      String? help,
      bool? defaultsTo = false,
      bool negatable = true})
      : super(
            name,
            (a) => a.addFlag(name,
                abbr: abbr,
                help: help,
                defaultsTo: defaultsTo,
                negatable: negatable),
            applyToOptions,
            (v) => v);
}

class ValueOption<T> extends Option<T> {
  ValueOption(
      String name,
      void Function(WasmCompilerOptions o, T v) applyToOptions,
      T Function(dynamic v) converter,
      {String? defaultsTo,
      bool hide = false})
      : super(name, (a) => a.addOption(name, defaultsTo: defaultsTo),
            applyToOptions, converter);
}

class IntOption extends ValueOption<int> {
  IntOption(
      String name, void Function(WasmCompilerOptions o, int v) applyToOptions,
      {String? defaultsTo})
      : super(name, applyToOptions, (v) => int.parse(v),
            defaultsTo: defaultsTo);
}

class StringOption extends ValueOption<String> {
  StringOption(String name,
      void Function(WasmCompilerOptions o, String v) applyToOptions,
      {String? defaultsTo, bool hide = false})
      : super(name, applyToOptions, (v) => v, defaultsTo: defaultsTo);
}

class UriOption extends ValueOption<Uri> {
  UriOption(
      String name, void Function(WasmCompilerOptions o, Uri v) applyToOptions,
      {String? defaultsTo})
      : super(name, applyToOptions, (v) => resolveInputUri(v as String),
            defaultsTo: defaultsTo);
}

class MultiValueOption<T> extends Option<List<T>> {
  MultiValueOption(
      String name,
      void Function(WasmCompilerOptions o, List<T> v) applyToOptions,
      T Function(dynamic v) converter,
      {Iterable<String>? defaultsTo,
      String? abbr})
      : super(
            name,
            (a) => a.addMultiOption(name, abbr: abbr, defaultsTo: defaultsTo),
            applyToOptions,
            (vs) => vs.map(converter).cast<T>().toList());
}

class IntMultiOption extends MultiValueOption<int> {
  IntMultiOption(
      name, void Function(WasmCompilerOptions o, List<int> v) applyToOptions,
      {Iterable<String>? defaultsTo})
      : super(name, applyToOptions, (v) => int.parse(v),
            defaultsTo: defaultsTo);
}

class StringMultiOption extends MultiValueOption<String> {
  StringMultiOption(
      name, void Function(WasmCompilerOptions o, List<String> v) applyToOptions,
      {String? abbr, Iterable<String>? defaultsTo})
      : super(name, applyToOptions, (v) => v,
            abbr: abbr, defaultsTo: defaultsTo);
}

class UriMultiOption extends MultiValueOption<Uri> {
  UriMultiOption(
      name, void Function(WasmCompilerOptions o, List<Uri> v) applyToOptions,
      {Iterable<String>? defaultsTo})
      : super(name, applyToOptions, (v) => Uri.file(Directory(v).absolute.path),
            defaultsTo: defaultsTo);
}
