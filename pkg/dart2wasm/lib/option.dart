// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';

import 'package:dart2wasm/compiler_options.dart';

class Option<T> {
  final String name;
  final void Function(ArgParser a) applyToParser;
  final void Function(CompilerOptions o, T v) _applyToOptions;
  final T Function(dynamic v) converter;

  void applyToOptions(CompilerOptions o, dynamic v) =>
      _applyToOptions(o, converter(v));

  Option(this.name, this.applyToParser, this._applyToOptions, this.converter);
}

class Flag extends Option<bool> {
  Flag(String name, void applyToOptions(CompilerOptions o, bool v),
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
  ValueOption(String name, void applyToOptions(CompilerOptions o, T v),
      T converter(dynamic v), {String? defaultsTo, bool hide = false})
      : super(
            name,
            (a) => a.addOption(name, defaultsTo: defaultsTo, hide: hide),
            applyToOptions,
            converter);
}

class IntOption extends ValueOption<int> {
  IntOption(String name, void applyToOptions(CompilerOptions o, int v),
      {String? defaultsTo})
      : super(name, applyToOptions, (v) => int.parse(v),
            defaultsTo: defaultsTo);
}

class StringOption extends ValueOption<String> {
  StringOption(String name, void applyToOptions(CompilerOptions o, String v),
      {String? defaultsTo, bool hide = false})
      : super(name, applyToOptions, (v) => v,
            defaultsTo: defaultsTo, hide: hide);
}

class UriOption extends ValueOption<Uri> {
  UriOption(String name, void applyToOptions(CompilerOptions o, Uri v),
      {String? defaultsTo})
      : super(name, applyToOptions, (v) => Uri.file(Directory(v).absolute.path),
            defaultsTo: defaultsTo);
}

class MultiValueOption<T> extends Option<List<T>> {
  MultiValueOption(
      String name,
      void Function(CompilerOptions o, List<T> v) applyToOptions,
      T converter(dynamic v),
      {Iterable<String>? defaultsTo,
      String? abbr})
      : super(
            name,
            (a) => a.addMultiOption(name, abbr: abbr, defaultsTo: defaultsTo),
            applyToOptions,
            (vs) => vs.map(converter).cast<T>().toList());
}

class IntMultiOption extends MultiValueOption<int> {
  IntMultiOption(name, void applyToOptions(CompilerOptions o, List<int> v),
      {Iterable<String>? defaultsTo})
      : super(name, applyToOptions, (v) => int.parse(v),
            defaultsTo: defaultsTo);
}

class StringMultiOption extends MultiValueOption<String> {
  StringMultiOption(
      name, void applyToOptions(CompilerOptions o, List<String> v),
      {String? abbr, Iterable<String>? defaultsTo})
      : super(name, applyToOptions, (v) => v,
            abbr: abbr, defaultsTo: defaultsTo);
}

class UriMultiOption extends MultiValueOption<Uri> {
  UriMultiOption(name, void applyToOptions(CompilerOptions o, List<Uri> v),
      {Iterable<String>? defaultsTo})
      : super(name, applyToOptions, (v) => Uri.file(Directory(v).absolute.path),
            defaultsTo: defaultsTo);
}
