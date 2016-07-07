dart_library.library('path', null, /* Imports */[
  'dart_sdk'
], function load__path(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const path$ = Object.create(null);
  const src__characters = Object.create(null);
  const src__context = Object.create(null);
  const src__internal_style = Object.create(null);
  const src__parsed_path = Object.create(null);
  const src__path_exception = Object.create(null);
  const src__style__posix = Object.create(null);
  const src__style__url = Object.create(null);
  const src__style__windows = Object.create(null);
  const src__style = Object.create(null);
  const src__utils = Object.create(null);
  let IterableOfString = () => (IterableOfString = dart.constFn(core.Iterable$(core.String)))();
  let ListOfString = () => (ListOfString = dart.constFn(core.List$(core.String)))();
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let String__ToString = () => (String__ToString = dart.constFn(dart.definiteFunctionType(core.String, [core.String], [core.String, core.String, core.String, core.String, core.String, core.String])))();
  let StringToString = () => (StringToString = dart.constFn(dart.definiteFunctionType(core.String, [core.String])))();
  let StringTobool = () => (StringTobool = dart.constFn(dart.definiteFunctionType(core.bool, [core.String])))();
  let String__ToString$ = () => (String__ToString$ = dart.constFn(dart.definiteFunctionType(core.String, [core.String], [core.String, core.String, core.String, core.String, core.String, core.String, core.String])))();
  let IterableOfStringToString = () => (IterableOfStringToString = dart.constFn(dart.definiteFunctionType(core.String, [IterableOfString()])))();
  let StringToListOfString = () => (StringToListOfString = dart.constFn(dart.definiteFunctionType(ListOfString(), [core.String])))();
  let String__ToString$0 = () => (String__ToString$0 = dart.constFn(dart.definiteFunctionType(core.String, [core.String], {from: core.String})))();
  let StringAndStringTobool = () => (StringAndStringTobool = dart.constFn(dart.definiteFunctionType(core.bool, [core.String, core.String])))();
  let dynamicToString = () => (dynamicToString = dart.constFn(dart.definiteFunctionType(core.String, [dart.dynamic])))();
  let StringToUri = () => (StringToUri = dart.constFn(dart.definiteFunctionType(core.Uri, [core.String])))();
  let VoidToContext = () => (VoidToContext = dart.constFn(dart.definiteFunctionType(src__context.Context, [])))();
  let StringAndListOfStringTodynamic = () => (StringAndListOfStringTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.String, ListOfString()])))();
  let intToString = () => (intToString = dart.constFn(dart.definiteFunctionType(core.String, [core.int])))();
  let VoidToString = () => (VoidToString = dart.constFn(dart.definiteFunctionType(core.String, [])))();
  let intTobool = () => (intTobool = dart.constFn(dart.definiteFunctionType(core.bool, [core.int])))();
  dart.defineLazy(path$, {
    get posix() {
      return src__context.Context.new({style: src__style.Style.posix});
    }
  });
  dart.defineLazy(path$, {
    get windows() {
      return src__context.Context.new({style: src__style.Style.windows});
    }
  });
  dart.defineLazy(path$, {
    get url() {
      return src__context.Context.new({style: src__style.Style.url});
    }
  });
  dart.defineLazy(path$, {
    get context() {
      return src__context.createInternal();
    }
  });
  dart.copyProperties(path$, {
    get style() {
      return path$.context.style;
    }
  });
  dart.copyProperties(path$, {
    get current() {
      let uri = core.Uri.base;
      if (dart.equals(uri, path$._currentUriBase)) return path$._current;
      path$._currentUriBase = uri;
      if (dart.equals(src__style.Style.platform, src__style.Style.url)) {
        path$._current = dart.toString(uri.resolve('.'));
        return path$._current;
      } else {
        let path = uri.toFilePath();
        let lastIndex = dart.notNull(path[dartx.length]) - 1;
        dart.assert(path[dartx.get](lastIndex) == '/' || path[dartx.get](lastIndex) == '\\');
        path$._current = path[dartx.substring](0, lastIndex);
        return path$._current;
      }
    }
  });
  path$._currentUriBase = null;
  path$._current = null;
  dart.copyProperties(path$, {
    get separator() {
      return path$.context.separator;
    }
  });
  path$.absolute = function(part1, part2, part3, part4, part5, part6, part7) {
    if (part2 === void 0) part2 = null;
    if (part3 === void 0) part3 = null;
    if (part4 === void 0) part4 = null;
    if (part5 === void 0) part5 = null;
    if (part6 === void 0) part6 = null;
    if (part7 === void 0) part7 = null;
    return path$.context.absolute(part1, part2, part3, part4, part5, part6, part7);
  };
  dart.fn(path$.absolute, String__ToString());
  path$.basename = function(path) {
    return path$.context.basename(path);
  };
  dart.fn(path$.basename, StringToString());
  path$.basenameWithoutExtension = function(path) {
    return path$.context.basenameWithoutExtension(path);
  };
  dart.fn(path$.basenameWithoutExtension, StringToString());
  path$.dirname = function(path) {
    return path$.context.dirname(path);
  };
  dart.fn(path$.dirname, StringToString());
  path$.extension = function(path) {
    return path$.context.extension(path);
  };
  dart.fn(path$.extension, StringToString());
  path$.rootPrefix = function(path) {
    return path$.context.rootPrefix(path);
  };
  dart.fn(path$.rootPrefix, StringToString());
  path$.isAbsolute = function(path) {
    return path$.context.isAbsolute(path);
  };
  dart.fn(path$.isAbsolute, StringTobool());
  path$.isRelative = function(path) {
    return path$.context.isRelative(path);
  };
  dart.fn(path$.isRelative, StringTobool());
  path$.isRootRelative = function(path) {
    return path$.context.isRootRelative(path);
  };
  dart.fn(path$.isRootRelative, StringTobool());
  path$.join = function(part1, part2, part3, part4, part5, part6, part7, part8) {
    if (part2 === void 0) part2 = null;
    if (part3 === void 0) part3 = null;
    if (part4 === void 0) part4 = null;
    if (part5 === void 0) part5 = null;
    if (part6 === void 0) part6 = null;
    if (part7 === void 0) part7 = null;
    if (part8 === void 0) part8 = null;
    return path$.context.join(part1, part2, part3, part4, part5, part6, part7, part8);
  };
  dart.fn(path$.join, String__ToString$());
  path$.joinAll = function(parts) {
    return path$.context.joinAll(parts);
  };
  dart.fn(path$.joinAll, IterableOfStringToString());
  path$.split = function(path) {
    return path$.context.split(path);
  };
  dart.fn(path$.split, StringToListOfString());
  path$.normalize = function(path) {
    return path$.context.normalize(path);
  };
  dart.fn(path$.normalize, StringToString());
  path$.relative = function(path, opts) {
    let from = opts && 'from' in opts ? opts.from : null;
    return path$.context.relative(path, {from: from});
  };
  dart.fn(path$.relative, String__ToString$0());
  path$.isWithin = function(parent, child) {
    return path$.context.isWithin(parent, child);
  };
  dart.fn(path$.isWithin, StringAndStringTobool());
  path$.withoutExtension = function(path) {
    return path$.context.withoutExtension(path);
  };
  dart.fn(path$.withoutExtension, StringToString());
  path$.fromUri = function(uri) {
    return path$.context.fromUri(uri);
  };
  dart.fn(path$.fromUri, dynamicToString());
  path$.toUri = function(path) {
    return path$.context.toUri(path);
  };
  dart.fn(path$.toUri, StringToUri());
  path$.prettyUri = function(uri) {
    return path$.context.prettyUri(uri);
  };
  dart.fn(path$.prettyUri, dynamicToString());
  const _current = Symbol('_current');
  const _parse = Symbol('_parse');
  const _needsNormalization = Symbol('_needsNormalization');
  const _isWithinFast = Symbol('_isWithinFast');
  const _pathDirection = Symbol('_pathDirection');
  src__context.Context = class Context extends core.Object {
    static new(opts) {
      let style = opts && 'style' in opts ? opts.style : null;
      let current = opts && 'current' in opts ? opts.current : null;
      if (current == null) {
        if (style == null) {
          current = path$.current;
        } else {
          current = ".";
        }
      }
      if (style == null) {
        style = src__style.Style.platform;
      } else if (!src__internal_style.InternalStyle.is(style)) {
        dart.throw(new core.ArgumentError("Only styles defined by the path package are " + "allowed."));
      }
      return new src__context.Context._(src__internal_style.InternalStyle.as(style), current);
    }
    _internal() {
      this.style = src__internal_style.InternalStyle.as(src__style.Style.platform);
      this[_current] = null;
    }
    _(style, current) {
      this.style = style;
      this[_current] = current;
    }
    get current() {
      return this[_current] != null ? this[_current] : path$.current;
    }
    get separator() {
      return this.style.separator;
    }
    absolute(part1, part2, part3, part4, part5, part6, part7) {
      if (part2 === void 0) part2 = null;
      if (part3 === void 0) part3 = null;
      if (part4 === void 0) part4 = null;
      if (part5 === void 0) part5 = null;
      if (part6 === void 0) part6 = null;
      if (part7 === void 0) part7 = null;
      src__context._validateArgList("absolute", JSArrayOfString().of([part1, part2, part3, part4, part5, part6, part7]));
      if (part2 == null && dart.test(this.isAbsolute(part1)) && !dart.test(this.isRootRelative(part1))) {
        return part1;
      }
      return this.join(this.current, part1, part2, part3, part4, part5, part6, part7);
    }
    basename(path) {
      return this[_parse](path).basename;
    }
    basenameWithoutExtension(path) {
      return this[_parse](path).basenameWithoutExtension;
    }
    dirname(path) {
      let parsed = this[_parse](path);
      parsed.removeTrailingSeparators();
      if (dart.test(parsed.parts[dartx.isEmpty])) return parsed.root == null ? '.' : parsed.root;
      if (parsed.parts[dartx.length] == 1) {
        return parsed.root == null ? '.' : parsed.root;
      }
      parsed.parts[dartx.removeLast]();
      parsed.separators[dartx.removeLast]();
      parsed.removeTrailingSeparators();
      return dart.toString(parsed);
    }
    extension(path) {
      return this[_parse](path).extension;
    }
    rootPrefix(path) {
      return path[dartx.substring](0, this.style.rootLength(path));
    }
    isAbsolute(path) {
      return dart.notNull(this.style.rootLength(path)) > 0;
    }
    isRelative(path) {
      return !dart.test(this.isAbsolute(path));
    }
    isRootRelative(path) {
      return this.style.isRootRelative(path);
    }
    join(part1, part2, part3, part4, part5, part6, part7, part8) {
      if (part2 === void 0) part2 = null;
      if (part3 === void 0) part3 = null;
      if (part4 === void 0) part4 = null;
      if (part5 === void 0) part5 = null;
      if (part6 === void 0) part6 = null;
      if (part7 === void 0) part7 = null;
      if (part8 === void 0) part8 = null;
      let parts = JSArrayOfString().of([part1, part2, part3, part4, part5, part6, part7, part8]);
      src__context._validateArgList("join", parts);
      return this.joinAll(parts[dartx.where](dart.fn(part => part != null, StringTobool())));
    }
    joinAll(parts) {
      let buffer = new core.StringBuffer();
      let needsSeparator = false;
      let isAbsoluteAndNotRootRelative = false;
      for (let part of parts[dartx.where](dart.fn(part => part != '', StringTobool()))) {
        if (dart.test(this.isRootRelative(part)) && isAbsoluteAndNotRootRelative) {
          let parsed = this[_parse](part);
          parsed.root = this.rootPrefix(buffer.toString());
          if (dart.test(this.style.needsSeparator(parsed.root))) {
            parsed.separators[dartx.set](0, this.style.separator);
          }
          buffer.clear();
          buffer.write(dart.toString(parsed));
        } else if (dart.test(this.isAbsolute(part))) {
          isAbsoluteAndNotRootRelative = !dart.test(this.isRootRelative(part));
          buffer.clear();
          buffer.write(part);
        } else {
          if (dart.notNull(part[dartx.length]) > 0 && dart.test(this.style.containsSeparator(part[dartx.get](0)))) {
          } else if (dart.test(needsSeparator)) {
            buffer.write(this.separator);
          }
          buffer.write(part);
        }
        needsSeparator = this.style.needsSeparator(part);
      }
      return buffer.toString();
    }
    split(path) {
      let parsed = this[_parse](path);
      parsed.parts = parsed.parts[dartx.where](dart.fn(part => !dart.test(part[dartx.isEmpty]), StringTobool()))[dartx.toList]();
      if (parsed.root != null) parsed.parts[dartx.insert](0, parsed.root);
      return parsed.parts;
    }
    normalize(path) {
      if (!dart.test(this[_needsNormalization](path))) return path;
      let parsed = this[_parse](path);
      parsed.normalize();
      return dart.toString(parsed);
    }
    [_needsNormalization](path) {
      let start = 0;
      let codeUnits = path[dartx.codeUnits];
      let previousPrevious = null;
      let previous = null;
      let root = this.style.rootLength(path);
      if (root != 0) {
        start = root;
        previous = src__characters.SLASH;
        if (dart.equals(this.style, src__style.Style.windows)) {
          for (let i = 0; i < dart.notNull(root); i++) {
            if (codeUnits[dartx.get](i) == src__characters.SLASH) return true;
          }
        }
      }
      for (let i = start; dart.notNull(i) < dart.notNull(codeUnits[dartx.length]); i = dart.notNull(i) + 1) {
        let codeUnit = codeUnits[dartx.get](i);
        if (dart.test(this.style.isSeparator(codeUnit))) {
          if (dart.equals(this.style, src__style.Style.windows) && codeUnit == src__characters.SLASH) return true;
          if (previous != null && dart.test(this.style.isSeparator(core.int._check(previous)))) return true;
          if (dart.equals(previous, src__characters.PERIOD) && (previousPrevious == null || dart.equals(previousPrevious, src__characters.PERIOD) || dart.test(this.style.isSeparator(core.int._check(previousPrevious))))) {
            return true;
          }
        }
        previousPrevious = previous;
        previous = codeUnit;
      }
      if (previous == null) return true;
      if (dart.test(this.style.isSeparator(core.int._check(previous)))) return true;
      if (dart.equals(previous, src__characters.PERIOD) && (previousPrevious == null || dart.equals(previousPrevious, src__characters.SLASH) || dart.equals(previousPrevious, src__characters.PERIOD))) {
        return true;
      }
      return false;
    }
    relative(path, opts) {
      let from = opts && 'from' in opts ? opts.from : null;
      if (from == null && dart.test(this.isRelative(path))) return this.normalize(path);
      from = from == null ? this.current : this.absolute(from);
      if (dart.test(this.isRelative(from)) && dart.test(this.isAbsolute(path))) {
        return this.normalize(path);
      }
      if (dart.test(this.isRelative(path)) || dart.test(this.isRootRelative(path))) {
        path = this.absolute(path);
      }
      if (dart.test(this.isRelative(path)) && dart.test(this.isAbsolute(from))) {
        dart.throw(new src__path_exception.PathException(dart.str`Unable to find a path to "${path}" from "${from}".`));
      }
      let fromParsed = this[_parse](from);
      fromParsed.normalize();
      let pathParsed = this[_parse](path);
      pathParsed.normalize();
      if (dart.notNull(fromParsed.parts[dartx.length]) > 0 && fromParsed.parts[dartx.get](0) == '.') {
        return pathParsed.toString();
      }
      if (fromParsed.root != pathParsed.root && (fromParsed.root == null || pathParsed.root == null || fromParsed.root[dartx.toLowerCase]()[dartx.replaceAll]('/', '\\') != pathParsed.root[dartx.toLowerCase]()[dartx.replaceAll]('/', '\\'))) {
        return pathParsed.toString();
      }
      while (dart.notNull(fromParsed.parts[dartx.length]) > 0 && dart.notNull(pathParsed.parts[dartx.length]) > 0 && fromParsed.parts[dartx.get](0) == pathParsed.parts[dartx.get](0)) {
        fromParsed.parts[dartx.removeAt](0);
        fromParsed.separators[dartx.removeAt](1);
        pathParsed.parts[dartx.removeAt](0);
        pathParsed.separators[dartx.removeAt](1);
      }
      if (dart.notNull(fromParsed.parts[dartx.length]) > 0 && fromParsed.parts[dartx.get](0) == '..') {
        dart.throw(new src__path_exception.PathException(dart.str`Unable to find a path to "${path}" from "${from}".`));
      }
      pathParsed.parts[dartx.insertAll](0, ListOfString().filled(fromParsed.parts[dartx.length], '..'));
      pathParsed.separators[dartx.set](0, '');
      pathParsed.separators[dartx.insertAll](1, ListOfString().filled(fromParsed.parts[dartx.length], this.style.separator));
      if (pathParsed.parts[dartx.length] == 0) return '.';
      if (dart.notNull(pathParsed.parts[dartx.length]) > 1 && pathParsed.parts[dartx.last] == '.') {
        pathParsed.parts[dartx.removeLast]();
        let _ = pathParsed.separators;
        _[dartx.removeLast]();
        _[dartx.removeLast]();
        _[dartx.add]('');
      }
      pathParsed.root = '';
      pathParsed.removeTrailingSeparators();
      return pathParsed.toString();
    }
    isWithin(parent, child) {
      let parentIsAbsolute = this.isAbsolute(parent);
      let childIsAbsolute = this.isAbsolute(child);
      if (dart.test(parentIsAbsolute) && !dart.test(childIsAbsolute)) {
        child = this.absolute(child);
        if (dart.test(this.style.isRootRelative(parent))) parent = this.absolute(parent);
      } else if (dart.test(childIsAbsolute) && !dart.test(parentIsAbsolute)) {
        parent = this.absolute(parent);
        if (dart.test(this.style.isRootRelative(child))) child = this.absolute(child);
      } else if (dart.test(childIsAbsolute) && dart.test(parentIsAbsolute)) {
        let childIsRootRelative = this.style.isRootRelative(child);
        let parentIsRootRelative = this.style.isRootRelative(parent);
        if (dart.test(childIsRootRelative) && !dart.test(parentIsRootRelative)) {
          child = this.absolute(child);
        } else if (dart.test(parentIsRootRelative) && !dart.test(childIsRootRelative)) {
          parent = this.absolute(parent);
        }
      }
      let fastResult = this[_isWithinFast](parent, child);
      if (fastResult != null) return fastResult;
      let relative = null;
      try {
        relative = this.relative(child, {from: parent});
      } catch (_) {
        if (src__path_exception.PathException.is(_)) {
          return false;
        } else
          throw _;
      }

      let parts = this.split(core.String._check(relative));
      return dart.test(this.isRelative(core.String._check(relative))) && parts[dartx.first] != '..' && parts[dartx.first] != '.';
    }
    [_isWithinFast](parent, child) {
      if (parent == '.') parent = '';
      let parentRootLength = this.style.rootLength(parent);
      let childRootLength = this.style.rootLength(child);
      if (parentRootLength != childRootLength) return false;
      let parentCodeUnits = parent[dartx.codeUnits];
      let childCodeUnits = child[dartx.codeUnits];
      for (let i = 0; i < dart.notNull(parentRootLength); i++) {
        let parentCodeUnit = parentCodeUnits[dartx.get](i);
        let childCodeUnit = childCodeUnits[dartx.get](i);
        if (parentCodeUnit == childCodeUnit) continue;
        if (!dart.test(this.style.isSeparator(parentCodeUnit)) || !dart.test(this.style.isSeparator(childCodeUnit))) {
          return false;
        }
      }
      let lastCodeUnit = src__characters.SLASH;
      let parentIndex = parentRootLength;
      let childIndex = childRootLength;
      while (dart.notNull(parentIndex) < dart.notNull(parent[dartx.length]) && dart.notNull(childIndex) < dart.notNull(child[dartx.length])) {
        let parentCodeUnit = parentCodeUnits[dartx.get](parentIndex);
        let childCodeUnit = childCodeUnits[dartx.get](childIndex);
        if (parentCodeUnit == childCodeUnit) {
          lastCodeUnit = parentCodeUnit;
          parentIndex = dart.notNull(parentIndex) + 1;
          childIndex = dart.notNull(childIndex) + 1;
          continue;
        }
        let parentIsSeparator = this.style.isSeparator(parentCodeUnit);
        let childIsSeparator = this.style.isSeparator(childCodeUnit);
        if (dart.test(parentIsSeparator) && dart.test(childIsSeparator)) {
          lastCodeUnit = parentCodeUnit;
          parentIndex = dart.notNull(parentIndex) + 1;
          childIndex = dart.notNull(childIndex) + 1;
          continue;
        }
        if (dart.test(parentIsSeparator) && dart.test(this.style.isSeparator(lastCodeUnit))) {
          parentIndex = dart.notNull(parentIndex) + 1;
          continue;
        } else if (dart.test(childIsSeparator) && dart.test(this.style.isSeparator(lastCodeUnit))) {
          childIndex = dart.notNull(childIndex) + 1;
          continue;
        }
        if (parentCodeUnit == src__characters.PERIOD) {
          if (dart.test(this.style.isSeparator(lastCodeUnit))) {
            parentIndex = dart.notNull(parentIndex) + 1;
            if (parentIndex == parent[dartx.length]) break;
            parentCodeUnit = parentCodeUnits[dartx.get](parentIndex);
            if (dart.test(this.style.isSeparator(parentCodeUnit))) {
              parentIndex = dart.notNull(parentIndex) + 1;
              continue;
            }
            if (parentCodeUnit == src__characters.PERIOD) {
              parentIndex = dart.notNull(parentIndex) + 1;
              if (parentIndex == parent[dartx.length] || dart.test(this.style.isSeparator(parentCodeUnits[dartx.get](parentIndex)))) {
                return null;
              }
            }
          }
        }
        if (childCodeUnit == src__characters.PERIOD) {
          if (dart.test(this.style.isSeparator(lastCodeUnit))) {
            childIndex = dart.notNull(childIndex) + 1;
            if (childIndex == child[dartx.length]) break;
            childCodeUnit = childCodeUnits[dartx.get](childIndex);
            if (dart.test(this.style.isSeparator(childCodeUnit))) {
              childIndex = dart.notNull(childIndex) + 1;
              continue;
            }
            if (childCodeUnit == src__characters.PERIOD) {
              childIndex = dart.notNull(childIndex) + 1;
              if (childIndex == child[dartx.length] || dart.test(this.style.isSeparator(childCodeUnits[dartx.get](childIndex)))) {
                return null;
              }
            }
          }
        }
        let childDirection = this[_pathDirection](childCodeUnits, childIndex);
        if (!dart.equals(childDirection, src__context._PathDirection.belowRoot)) return null;
        let parentDirection = this[_pathDirection](parentCodeUnits, parentIndex);
        if (!dart.equals(parentDirection, src__context._PathDirection.belowRoot)) return null;
        return false;
      }
      if (childIndex == child[dartx.length]) {
        let direction = this[_pathDirection](parentCodeUnits, parentIndex);
        return dart.equals(direction, src__context._PathDirection.aboveRoot) ? null : false;
      }
      let direction = this[_pathDirection](childCodeUnits, childIndex);
      if (dart.equals(direction, src__context._PathDirection.atRoot)) return false;
      if (dart.equals(direction, src__context._PathDirection.aboveRoot)) return null;
      return dart.test(this.style.isSeparator(childCodeUnits[dartx.get](childIndex))) || dart.test(this.style.isSeparator(lastCodeUnit));
    }
    [_pathDirection](codeUnits, index) {
      let depth = 0;
      let reachedRoot = false;
      let i = index;
      while (dart.notNull(i) < dart.notNull(codeUnits[dartx.length])) {
        while (dart.notNull(i) < dart.notNull(codeUnits[dartx.length]) && dart.test(this.style.isSeparator(codeUnits[dartx.get](i)))) {
          i = dart.notNull(i) + 1;
        }
        if (i == codeUnits[dartx.length]) break;
        let start = i;
        while (dart.notNull(i) < dart.notNull(codeUnits[dartx.length]) && !dart.test(this.style.isSeparator(codeUnits[dartx.get](i)))) {
          i = dart.notNull(i) + 1;
        }
        if (dart.notNull(i) - dart.notNull(start) == 1 && codeUnits[dartx.get](start) == src__characters.PERIOD) {
        } else if (dart.notNull(i) - dart.notNull(start) == 2 && codeUnits[dartx.get](start) == src__characters.PERIOD && codeUnits[dartx.get](dart.notNull(start) + 1) == src__characters.PERIOD) {
          depth--;
          if (depth < 0) break;
          if (depth == 0) reachedRoot = true;
        } else {
          depth++;
        }
        if (i == codeUnits[dartx.length]) break;
        i = dart.notNull(i) + 1;
      }
      if (depth < 0) return src__context._PathDirection.aboveRoot;
      if (depth == 0) return src__context._PathDirection.atRoot;
      if (reachedRoot) return src__context._PathDirection.reachesRoot;
      return src__context._PathDirection.belowRoot;
    }
    withoutExtension(path) {
      let parsed = this[_parse](path);
      for (let i = dart.notNull(parsed.parts[dartx.length]) - 1; i >= 0; i--) {
        if (!dart.test(parsed.parts[dartx.get](i)[dartx.isEmpty])) {
          parsed.parts[dartx.set](i, parsed.basenameWithoutExtension);
          break;
        }
      }
      return dart.toString(parsed);
    }
    fromUri(uri) {
      if (typeof uri == 'string') uri = core.Uri.parse(core.String._check(uri));
      return this.style.pathFromUri(core.Uri._check(uri));
    }
    toUri(path) {
      if (dart.test(this.isRelative(path))) {
        return this.style.relativePathToUri(path);
      } else {
        return this.style.absolutePathToUri(this.join(this.current, path));
      }
    }
    prettyUri(uri) {
      if (typeof uri == 'string') uri = core.Uri.parse(core.String._check(uri));
      if (dart.equals(dart.dload(uri, 'scheme'), 'file') && dart.equals(this.style, src__style.Style.url)) return dart.toString(uri);
      if (!dart.equals(dart.dload(uri, 'scheme'), 'file') && !dart.equals(dart.dload(uri, 'scheme'), '') && !dart.equals(this.style, src__style.Style.url)) {
        return dart.toString(uri);
      }
      let path = this.normalize(this.fromUri(uri));
      let rel = this.relative(path);
      return dart.notNull(this.split(rel)[dartx.length]) > dart.notNull(this.split(path)[dartx.length]) ? path : rel;
    }
    [_parse](path) {
      return src__parsed_path.ParsedPath.parse(path, this.style);
    }
  };
  dart.defineNamedConstructor(src__context.Context, '_internal');
  dart.defineNamedConstructor(src__context.Context, '_');
  dart.setSignature(src__context.Context, {
    constructors: () => ({
      new: dart.definiteFunctionType(src__context.Context, [], {style: src__style.Style, current: core.String}),
      _internal: dart.definiteFunctionType(src__context.Context, []),
      _: dart.definiteFunctionType(src__context.Context, [src__internal_style.InternalStyle, core.String])
    }),
    methods: () => ({
      absolute: dart.definiteFunctionType(core.String, [core.String], [core.String, core.String, core.String, core.String, core.String, core.String]),
      basename: dart.definiteFunctionType(core.String, [core.String]),
      basenameWithoutExtension: dart.definiteFunctionType(core.String, [core.String]),
      dirname: dart.definiteFunctionType(core.String, [core.String]),
      extension: dart.definiteFunctionType(core.String, [core.String]),
      rootPrefix: dart.definiteFunctionType(core.String, [core.String]),
      isAbsolute: dart.definiteFunctionType(core.bool, [core.String]),
      isRelative: dart.definiteFunctionType(core.bool, [core.String]),
      isRootRelative: dart.definiteFunctionType(core.bool, [core.String]),
      join: dart.definiteFunctionType(core.String, [core.String], [core.String, core.String, core.String, core.String, core.String, core.String, core.String]),
      joinAll: dart.definiteFunctionType(core.String, [core.Iterable$(core.String)]),
      split: dart.definiteFunctionType(core.List$(core.String), [core.String]),
      normalize: dart.definiteFunctionType(core.String, [core.String]),
      [_needsNormalization]: dart.definiteFunctionType(core.bool, [core.String]),
      relative: dart.definiteFunctionType(core.String, [core.String], {from: core.String}),
      isWithin: dart.definiteFunctionType(core.bool, [core.String, core.String]),
      [_isWithinFast]: dart.definiteFunctionType(core.bool, [core.String, core.String]),
      [_pathDirection]: dart.definiteFunctionType(src__context._PathDirection, [core.List$(core.int), core.int]),
      withoutExtension: dart.definiteFunctionType(core.String, [core.String]),
      fromUri: dart.definiteFunctionType(core.String, [dart.dynamic]),
      toUri: dart.definiteFunctionType(core.Uri, [core.String]),
      prettyUri: dart.definiteFunctionType(core.String, [dart.dynamic]),
      [_parse]: dart.definiteFunctionType(src__parsed_path.ParsedPath, [core.String])
    })
  });
  path$.Context = src__context.Context;
  src__path_exception.PathException = class PathException extends core.Object {
    new(message) {
      this.message = message;
    }
    toString() {
      return dart.str`PathException: ${this.message}`;
    }
  };
  src__path_exception.PathException[dart.implements] = () => [core.Exception];
  dart.setSignature(src__path_exception.PathException, {
    constructors: () => ({new: dart.definiteFunctionType(src__path_exception.PathException, [core.String])})
  });
  path$.PathException = src__path_exception.PathException;
  src__style.Style = class Style extends core.Object {
    static _getPlatformStyle() {
      if (core.Uri.base.scheme != 'file') return src__style.Style.url;
      if (!dart.test(core.Uri.base.path[dartx.endsWith]('/'))) return src__style.Style.url;
      if (core.Uri.new({path: 'a/b'}).toFilePath() == 'a\\b') return src__style.Style.windows;
      return src__style.Style.posix;
    }
    get context() {
      return src__context.Context.new({style: this});
    }
    toString() {
      return this.name;
    }
  };
  dart.setSignature(src__style.Style, {
    statics: () => ({_getPlatformStyle: dart.definiteFunctionType(src__style.Style, [])}),
    names: ['_getPlatformStyle']
  });
  dart.defineLazy(src__style.Style, {
    get posix() {
      return new src__style__posix.PosixStyle();
    },
    get windows() {
      return new src__style__windows.WindowsStyle();
    },
    get url() {
      return new src__style__url.UrlStyle();
    },
    get platform() {
      return src__style.Style._getPlatformStyle();
    }
  });
  path$.Style = src__style.Style;
  src__characters.PLUS = 43;
  src__characters.MINUS = 45;
  src__characters.PERIOD = 46;
  src__characters.SLASH = 47;
  src__characters.ZERO = 48;
  src__characters.NINE = 57;
  src__characters.COLON = 58;
  src__characters.UPPER_A = 65;
  src__characters.UPPER_Z = 90;
  src__characters.LOWER_A = 97;
  src__characters.LOWER_Z = 122;
  src__characters.BACKSLASH = 92;
  src__context.createInternal = function() {
    return new src__context.Context._internal();
  };
  dart.fn(src__context.createInternal, VoidToContext());
  src__context._validateArgList = function(method, args) {
    for (let i = 1; i < dart.notNull(args[dartx.length]); i++) {
      if (args[dartx.get](i) == null || args[dartx.get](i - 1) != null) continue;
      let numArgs = null;
      for (numArgs = args[dartx.length]; dart.test(dart.dsend(numArgs, '>=', 1)); numArgs = dart.dsend(numArgs, '-', 1)) {
        if (args[dartx.get](core.int._check(dart.dsend(numArgs, '-', 1))) != null) break;
      }
      let message = new core.StringBuffer();
      message.write(dart.str`${method}(`);
      message.write(args[dartx.take](core.int._check(numArgs))[dartx.map](core.String)(dart.fn(arg => arg == null ? "null" : dart.str`"${arg}"`, StringToString()))[dartx.join](", "));
      message.write(dart.str`): part ${i - 1} was null, but part ${i} was not.`);
      dart.throw(new core.ArgumentError(message.toString()));
    }
  };
  dart.fn(src__context._validateArgList, StringAndListOfStringTodynamic());
  src__context._PathDirection = class _PathDirection extends core.Object {
    new(name) {
      this.name = name;
    }
    toString() {
      return this.name;
    }
  };
  dart.setSignature(src__context._PathDirection, {
    constructors: () => ({new: dart.definiteFunctionType(src__context._PathDirection, [core.String])})
  });
  dart.defineLazy(src__context._PathDirection, {
    get aboveRoot() {
      return dart.const(new src__context._PathDirection("above root"));
    },
    get atRoot() {
      return dart.const(new src__context._PathDirection("at root"));
    },
    get reachesRoot() {
      return dart.const(new src__context._PathDirection("reaches root"));
    },
    get belowRoot() {
      return dart.const(new src__context._PathDirection("below root"));
    }
  });
  src__internal_style.InternalStyle = class InternalStyle extends src__style.Style {
    getRoot(path) {
      let length = this.rootLength(path);
      if (dart.notNull(length) > 0) return path[dartx.substring](0, length);
      return dart.test(this.isRootRelative(path)) ? path[dartx.get](0) : null;
    }
    relativePathToUri(path) {
      let segments = this.context.split(path);
      if (dart.test(this.isSeparator(path[dartx.codeUnitAt](dart.notNull(path[dartx.length]) - 1)))) segments[dartx.add]('');
      return core.Uri.new({pathSegments: segments});
    }
  };
  dart.setSignature(src__internal_style.InternalStyle, {
    methods: () => ({
      getRoot: dart.definiteFunctionType(core.String, [core.String]),
      relativePathToUri: dart.definiteFunctionType(core.Uri, [core.String])
    })
  });
  const _splitExtension = Symbol('_splitExtension');
  src__parsed_path.ParsedPath = class ParsedPath extends core.Object {
    get extension() {
      return this[_splitExtension]()[dartx.get](1);
    }
    get isAbsolute() {
      return this.root != null;
    }
    static parse(path, style) {
      let root = style.getRoot(path);
      let isRootRelative = style.isRootRelative(path);
      if (root != null) path = path[dartx.substring](root[dartx.length]);
      let parts = JSArrayOfString().of([]);
      let separators = JSArrayOfString().of([]);
      let start = 0;
      if (dart.test(path[dartx.isNotEmpty]) && dart.test(style.isSeparator(path[dartx.codeUnitAt](0)))) {
        separators[dartx.add](path[dartx.get](0));
        start = 1;
      } else {
        separators[dartx.add]('');
      }
      for (let i = start; i < dart.notNull(path[dartx.length]); i++) {
        if (dart.test(style.isSeparator(path[dartx.codeUnitAt](i)))) {
          parts[dartx.add](path[dartx.substring](start, i));
          separators[dartx.add](path[dartx.get](i));
          start = i + 1;
        }
      }
      if (start < dart.notNull(path[dartx.length])) {
        parts[dartx.add](path[dartx.substring](start));
        separators[dartx.add]('');
      }
      return new src__parsed_path.ParsedPath._(style, root, isRootRelative, parts, separators);
    }
    _(style, root, isRootRelative, parts, separators) {
      this.style = style;
      this.root = root;
      this.isRootRelative = isRootRelative;
      this.parts = parts;
      this.separators = separators;
    }
    get basename() {
      let copy = this.clone();
      copy.removeTrailingSeparators();
      if (dart.test(copy.parts[dartx.isEmpty])) return this.root == null ? '' : this.root;
      return copy.parts[dartx.last];
    }
    get basenameWithoutExtension() {
      return this[_splitExtension]()[dartx.get](0);
    }
    get hasTrailingSeparator() {
      return !dart.test(this.parts[dartx.isEmpty]) && (this.parts[dartx.last] == '' || this.separators[dartx.last] != '');
    }
    removeTrailingSeparators() {
      while (!dart.test(this.parts[dartx.isEmpty]) && this.parts[dartx.last] == '') {
        this.parts[dartx.removeLast]();
        this.separators[dartx.removeLast]();
      }
      if (dart.notNull(this.separators[dartx.length]) > 0) this.separators[dartx.set](dart.notNull(this.separators[dartx.length]) - 1, '');
    }
    normalize() {
      let leadingDoubles = 0;
      let newParts = JSArrayOfString().of([]);
      for (let part of this.parts) {
        if (part == '.' || part == '') {
        } else if (part == '..') {
          if (dart.notNull(newParts[dartx.length]) > 0) {
            newParts[dartx.removeLast]();
          } else {
            leadingDoubles++;
          }
        } else {
          newParts[dartx.add](part);
        }
      }
      if (!dart.test(this.isAbsolute)) {
        newParts[dartx.insertAll](0, ListOfString().filled(leadingDoubles, '..'));
      }
      if (newParts[dartx.length] == 0 && !dart.test(this.isAbsolute)) {
        newParts[dartx.add]('.');
      }
      let newSeparators = ListOfString().generate(newParts[dartx.length], dart.fn(_ => this.style.separator, intToString()), {growable: true});
      newSeparators[dartx.insert](0, dart.test(this.isAbsolute) && dart.notNull(newParts[dartx.length]) > 0 && dart.test(this.style.needsSeparator(this.root)) ? this.style.separator : '');
      this.parts = newParts;
      this.separators = newSeparators;
      if (this.root != null && dart.equals(this.style, src__style.Style.windows)) {
        this.root = this.root[dartx.replaceAll]('/', '\\');
      }
      this.removeTrailingSeparators();
    }
    toString() {
      let builder = new core.StringBuffer();
      if (this.root != null) builder.write(this.root);
      for (let i = 0; i < dart.notNull(this.parts[dartx.length]); i++) {
        builder.write(this.separators[dartx.get](i));
        builder.write(this.parts[dartx.get](i));
      }
      builder.write(this.separators[dartx.last]);
      return builder.toString();
    }
    [_splitExtension]() {
      let file = this.parts[dartx.lastWhere](dart.fn(p => p != '', StringTobool()), {orElse: dart.fn(() => null, VoidToString())});
      if (file == null) return JSArrayOfString().of(['', '']);
      if (file == '..') return JSArrayOfString().of(['..', '']);
      let lastDot = file[dartx.lastIndexOf]('.');
      if (dart.notNull(lastDot) <= 0) return JSArrayOfString().of([file, '']);
      return JSArrayOfString().of([file[dartx.substring](0, lastDot), file[dartx.substring](lastDot)]);
    }
    clone() {
      return new src__parsed_path.ParsedPath._(this.style, this.root, this.isRootRelative, ListOfString().from(this.parts), ListOfString().from(this.separators));
    }
  };
  dart.defineNamedConstructor(src__parsed_path.ParsedPath, '_');
  dart.setSignature(src__parsed_path.ParsedPath, {
    constructors: () => ({
      parse: dart.definiteFunctionType(src__parsed_path.ParsedPath, [core.String, src__internal_style.InternalStyle]),
      _: dart.definiteFunctionType(src__parsed_path.ParsedPath, [src__internal_style.InternalStyle, core.String, core.bool, core.List$(core.String), core.List$(core.String)])
    }),
    methods: () => ({
      removeTrailingSeparators: dart.definiteFunctionType(dart.void, []),
      normalize: dart.definiteFunctionType(dart.void, []),
      [_splitExtension]: dart.definiteFunctionType(core.List$(core.String), []),
      clone: dart.definiteFunctionType(src__parsed_path.ParsedPath, [])
    })
  });
  let const$;
  src__style__posix.PosixStyle = class PosixStyle extends src__internal_style.InternalStyle {
    new() {
      this.separatorPattern = core.RegExp.new('/');
      this.needsSeparatorPattern = core.RegExp.new('[^/]$');
      this.rootPattern = core.RegExp.new('^/');
      this.name = 'posix';
      this.separator = '/';
      this.separators = const$ || (const$ = dart.constList(['/'], core.String));
      this.relativeRootPattern = null;
    }
    containsSeparator(path) {
      return path[dartx.contains]('/');
    }
    isSeparator(codeUnit) {
      return codeUnit == src__characters.SLASH;
    }
    needsSeparator(path) {
      return dart.test(path[dartx.isNotEmpty]) && !dart.test(this.isSeparator(path[dartx.codeUnitAt](dart.notNull(path[dartx.length]) - 1)));
    }
    rootLength(path) {
      if (dart.test(path[dartx.isNotEmpty]) && dart.test(this.isSeparator(path[dartx.codeUnitAt](0)))) return 1;
      return 0;
    }
    isRootRelative(path) {
      return false;
    }
    getRelativeRoot(path) {
      return null;
    }
    pathFromUri(uri) {
      if (uri.scheme == '' || uri.scheme == 'file') {
        return core.Uri.decodeComponent(uri.path);
      }
      dart.throw(new core.ArgumentError(dart.str`Uri ${uri} must have scheme 'file:'.`));
    }
    absolutePathToUri(path) {
      let parsed = src__parsed_path.ParsedPath.parse(path, this);
      if (dart.test(parsed.parts[dartx.isEmpty])) {
        parsed.parts[dartx.addAll](JSArrayOfString().of(["", ""]));
      } else if (dart.test(parsed.hasTrailingSeparator)) {
        parsed.parts[dartx.add]("");
      }
      return core.Uri.new({scheme: 'file', pathSegments: parsed.parts});
    }
  };
  dart.setSignature(src__style__posix.PosixStyle, {
    constructors: () => ({new: dart.definiteFunctionType(src__style__posix.PosixStyle, [])}),
    methods: () => ({
      containsSeparator: dart.definiteFunctionType(core.bool, [core.String]),
      isSeparator: dart.definiteFunctionType(core.bool, [core.int]),
      needsSeparator: dart.definiteFunctionType(core.bool, [core.String]),
      rootLength: dart.definiteFunctionType(core.int, [core.String]),
      isRootRelative: dart.definiteFunctionType(core.bool, [core.String]),
      getRelativeRoot: dart.definiteFunctionType(core.String, [core.String]),
      pathFromUri: dart.definiteFunctionType(core.String, [core.Uri]),
      absolutePathToUri: dart.definiteFunctionType(core.Uri, [core.String])
    })
  });
  let const$0;
  src__style__url.UrlStyle = class UrlStyle extends src__internal_style.InternalStyle {
    new() {
      this.separatorPattern = core.RegExp.new('/');
      this.needsSeparatorPattern = core.RegExp.new("(^[a-zA-Z][-+.a-zA-Z\\d]*://|[^/])$");
      this.rootPattern = core.RegExp.new("[a-zA-Z][-+.a-zA-Z\\d]*://[^/]*");
      this.relativeRootPattern = core.RegExp.new("^/");
      this.name = 'url';
      this.separator = '/';
      this.separators = const$0 || (const$0 = dart.constList(['/'], core.String));
    }
    containsSeparator(path) {
      return path[dartx.contains]('/');
    }
    isSeparator(codeUnit) {
      return codeUnit == src__characters.SLASH;
    }
    needsSeparator(path) {
      if (dart.test(path[dartx.isEmpty])) return false;
      if (!dart.test(this.isSeparator(path[dartx.codeUnitAt](dart.notNull(path[dartx.length]) - 1)))) return true;
      return dart.test(path[dartx.endsWith]("://")) && this.rootLength(path) == path[dartx.length];
    }
    rootLength(path) {
      if (dart.test(path[dartx.isEmpty])) return 0;
      if (dart.test(this.isSeparator(path[dartx.codeUnitAt](0)))) return 1;
      let index = path[dartx.indexOf]("/");
      if (dart.notNull(index) > 0 && dart.test(path[dartx.startsWith]('://', dart.notNull(index) - 1))) {
        index = path[dartx.indexOf]('/', dart.notNull(index) + 2);
        if (dart.notNull(index) > 0) return index;
        return path[dartx.length];
      }
      return 0;
    }
    isRootRelative(path) {
      return dart.test(path[dartx.isNotEmpty]) && dart.test(this.isSeparator(path[dartx.codeUnitAt](0)));
    }
    getRelativeRoot(path) {
      return dart.test(this.isRootRelative(path)) ? '/' : null;
    }
    pathFromUri(uri) {
      return dart.toString(uri);
    }
    relativePathToUri(path) {
      return core.Uri.parse(path);
    }
    absolutePathToUri(path) {
      return core.Uri.parse(path);
    }
  };
  dart.setSignature(src__style__url.UrlStyle, {
    constructors: () => ({new: dart.definiteFunctionType(src__style__url.UrlStyle, [])}),
    methods: () => ({
      containsSeparator: dart.definiteFunctionType(core.bool, [core.String]),
      isSeparator: dart.definiteFunctionType(core.bool, [core.int]),
      needsSeparator: dart.definiteFunctionType(core.bool, [core.String]),
      rootLength: dart.definiteFunctionType(core.int, [core.String]),
      isRootRelative: dart.definiteFunctionType(core.bool, [core.String]),
      getRelativeRoot: dart.definiteFunctionType(core.String, [core.String]),
      pathFromUri: dart.definiteFunctionType(core.String, [core.Uri]),
      absolutePathToUri: dart.definiteFunctionType(core.Uri, [core.String])
    })
  });
  let const$1;
  src__style__windows.WindowsStyle = class WindowsStyle extends src__internal_style.InternalStyle {
    new() {
      this.separatorPattern = core.RegExp.new('[/\\\\]');
      this.needsSeparatorPattern = core.RegExp.new('[^/\\\\]$');
      this.rootPattern = core.RegExp.new('^(\\\\\\\\[^\\\\]+\\\\[^\\\\/]+|[a-zA-Z]:[/\\\\])');
      this.relativeRootPattern = core.RegExp.new("^[/\\\\](?![/\\\\])");
      this.name = 'windows';
      this.separator = '\\';
      this.separators = const$1 || (const$1 = dart.constList(['/', '\\'], core.String));
    }
    containsSeparator(path) {
      return path[dartx.contains]('/');
    }
    isSeparator(codeUnit) {
      return codeUnit == src__characters.SLASH || codeUnit == src__characters.BACKSLASH;
    }
    needsSeparator(path) {
      if (dart.test(path[dartx.isEmpty])) return false;
      return !dart.test(this.isSeparator(path[dartx.codeUnitAt](dart.notNull(path[dartx.length]) - 1)));
    }
    rootLength(path) {
      if (dart.test(path[dartx.isEmpty])) return 0;
      if (path[dartx.codeUnitAt](0) == src__characters.SLASH) return 1;
      if (path[dartx.codeUnitAt](0) == src__characters.BACKSLASH) {
        if (dart.notNull(path[dartx.length]) < 2 || path[dartx.codeUnitAt](1) != src__characters.BACKSLASH) return 1;
        let index = path[dartx.indexOf]('\\', 2);
        if (dart.notNull(index) > 0) {
          index = path[dartx.indexOf]('\\', dart.notNull(index) + 1);
          if (dart.notNull(index) > 0) return index;
        }
        return path[dartx.length];
      }
      if (dart.notNull(path[dartx.length]) < 3) return 0;
      if (!dart.test(src__utils.isAlphabetic(path[dartx.codeUnitAt](0)))) return 0;
      if (path[dartx.codeUnitAt](1) != src__characters.COLON) return 0;
      if (!dart.test(this.isSeparator(path[dartx.codeUnitAt](2)))) return 0;
      return 3;
    }
    isRootRelative(path) {
      return this.rootLength(path) == 1;
    }
    getRelativeRoot(path) {
      let length = this.rootLength(path);
      if (length == 1) return path[dartx.get](0);
      return null;
    }
    pathFromUri(uri) {
      if (uri.scheme != '' && uri.scheme != 'file') {
        dart.throw(new core.ArgumentError(dart.str`Uri ${uri} must have scheme 'file:'.`));
      }
      let path = uri.path;
      if (uri.host == '') {
        if (dart.test(path[dartx.startsWith]('/'))) path = path[dartx.replaceFirst]("/", "");
      } else {
        path = dart.str`\\\\${uri.host}${path}`;
      }
      return core.Uri.decodeComponent(path[dartx.replaceAll]("/", "\\"));
    }
    absolutePathToUri(path) {
      let parsed = src__parsed_path.ParsedPath.parse(path, this);
      if (dart.test(parsed.root[dartx.startsWith]('\\\\'))) {
        let rootParts = parsed.root[dartx.split]('\\')[dartx.where](dart.fn(part => part != '', StringTobool()));
        parsed.parts[dartx.insert](0, rootParts[dartx.last]);
        if (dart.test(parsed.hasTrailingSeparator)) {
          parsed.parts[dartx.add]("");
        }
        return core.Uri.new({scheme: 'file', host: rootParts[dartx.first], pathSegments: parsed.parts});
      } else {
        if (parsed.parts[dartx.length] == 0 || dart.test(parsed.hasTrailingSeparator)) {
          parsed.parts[dartx.add]("");
        }
        parsed.parts[dartx.insert](0, parsed.root[dartx.replaceAll]("/", "")[dartx.replaceAll]("\\", ""));
        return core.Uri.new({scheme: 'file', pathSegments: parsed.parts});
      }
    }
  };
  dart.setSignature(src__style__windows.WindowsStyle, {
    constructors: () => ({new: dart.definiteFunctionType(src__style__windows.WindowsStyle, [])}),
    methods: () => ({
      containsSeparator: dart.definiteFunctionType(core.bool, [core.String]),
      isSeparator: dart.definiteFunctionType(core.bool, [core.int]),
      needsSeparator: dart.definiteFunctionType(core.bool, [core.String]),
      rootLength: dart.definiteFunctionType(core.int, [core.String]),
      isRootRelative: dart.definiteFunctionType(core.bool, [core.String]),
      getRelativeRoot: dart.definiteFunctionType(core.String, [core.String]),
      pathFromUri: dart.definiteFunctionType(core.String, [core.Uri]),
      absolutePathToUri: dart.definiteFunctionType(core.Uri, [core.String])
    })
  });
  src__utils.isAlphabetic = function(char) {
    return dart.notNull(char) >= src__characters.UPPER_A && dart.notNull(char) <= src__characters.UPPER_Z || dart.notNull(char) >= src__characters.LOWER_A && dart.notNull(char) <= src__characters.LOWER_Z;
  };
  dart.fn(src__utils.isAlphabetic, intTobool());
  src__utils.isNumeric = function(char) {
    return dart.notNull(char) >= src__characters.ZERO && dart.notNull(char) <= src__characters.NINE;
  };
  dart.fn(src__utils.isNumeric, intTobool());
  // Exports:
  exports.path = path$;
  exports.src__characters = src__characters;
  exports.src__context = src__context;
  exports.src__internal_style = src__internal_style;
  exports.src__parsed_path = src__parsed_path;
  exports.src__path_exception = src__path_exception;
  exports.src__style__posix = src__style__posix;
  exports.src__style__url = src__style__url;
  exports.src__style__windows = src__style__windows;
  exports.src__style = src__style;
  exports.src__utils = src__utils;
});
