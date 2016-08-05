dart_library.library('matcher', null, /* Imports */[
  'dart_sdk'
], function load__matcher(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const mirrors = dart_sdk.mirrors;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const matcher = Object.create(null);
  const mirror_matchers = Object.create(null);
  const src__core_matchers = Object.create(null);
  const src__description = Object.create(null);
  const src__error_matchers = Object.create(null);
  const src__interfaces = Object.create(null);
  const src__iterable_matchers = Object.create(null);
  const src__map_matchers = Object.create(null);
  const src__numeric_matchers = Object.create(null);
  const src__operator_matchers = Object.create(null);
  const src__pretty_print = Object.create(null);
  const src__string_matchers = Object.create(null);
  const src__util = Object.create(null);
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.functionType(core.bool, [dart.dynamic])))();
  let isInstanceOf = () => (isInstanceOf = dart.constFn(src__core_matchers.isInstanceOf$()))();
  let dynamicAnddynamicTobool = () => (dynamicAnddynamicTobool = dart.constFn(dart.functionType(core.bool, [dart.dynamic, dart.dynamic])))();
  let ListOfString = () => (ListOfString = dart.constFn(core.List$(core.String)))();
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let ListOfbool = () => (ListOfbool = dart.constFn(core.List$(core.bool)))();
  let ListOfMatcher = () => (ListOfMatcher = dart.constFn(core.List$(src__interfaces.Matcher)))();
  let dynamicToMatcher = () => (dynamicToMatcher = dart.constFn(dart.definiteFunctionType(src__interfaces.Matcher, [dart.dynamic])))();
  let dynamic__ToMatcher = () => (dynamic__ToMatcher = dart.constFn(dart.definiteFunctionType(src__interfaces.Matcher, [dart.dynamic], [core.int])))();
  let Fn__ToMatcher = () => (Fn__ToMatcher = dart.constFn(dart.definiteFunctionType(src__interfaces.Matcher, [dynamicTobool()], [core.String])))();
  let IterableAndFnAndStringToMatcher = () => (IterableAndFnAndStringToMatcher = dart.constFn(dart.definiteFunctionType(src__interfaces.Matcher, [core.Iterable, dynamicAnddynamicTobool(), core.String])))();
  let IterableToMatcher = () => (IterableToMatcher = dart.constFn(dart.definiteFunctionType(src__interfaces.Matcher, [core.Iterable])))();
  let dynamicAnddynamicToMatcher = () => (dynamicAnddynamicToMatcher = dart.constFn(dart.definiteFunctionType(src__interfaces.Matcher, [dart.dynamic, dart.dynamic])))();
  let numAndnumToMatcher = () => (numAndnumToMatcher = dart.constFn(dart.definiteFunctionType(src__interfaces.Matcher, [core.num, core.num])))();
  let dynamic__ToMatcher$ = () => (dynamic__ToMatcher$ = dart.constFn(dart.definiteFunctionType(src__interfaces.Matcher, [dart.dynamic], [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic])))();
  let StringToMatcher = () => (StringToMatcher = dart.constFn(dart.definiteFunctionType(src__interfaces.Matcher, [core.String])))();
  let StringToString = () => (StringToString = dart.constFn(dart.definiteFunctionType(core.String, [core.String])))();
  let ListOfStringToMatcher = () => (ListOfStringToMatcher = dart.constFn(dart.definiteFunctionType(src__interfaces.Matcher, [ListOfString()])))();
  let MapAndMapTovoid = () => (MapAndMapTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.Map, core.Map])))();
  let MatchToString = () => (MatchToString = dart.constFn(dart.definiteFunctionType(core.String, [core.Match])))();
  let String__ToMatcher = () => (String__ToMatcher = dart.constFn(dart.definiteFunctionType(src__interfaces.Matcher, [core.String], [dart.dynamic])))();
  let dynamicTobool$ = () => (dynamicTobool$ = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let dynamicAnddynamicAnddynamic__ToListOfMatcher = () => (dynamicAnddynamicAnddynamic__ToListOfMatcher = dart.constFn(dart.definiteFunctionType(ListOfMatcher(), [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic])))();
  let dynamicToString = () => (dynamicToString = dart.constFn(dart.definiteFunctionType(core.String, [dart.dynamic])))();
  let dynamicAndintAndSet__ToString = () => (dynamicAndintAndSet__ToString = dart.constFn(dart.definiteFunctionType(core.String, [dart.dynamic, core.int, core.Set, core.bool])))();
  let dynamic__ToString = () => (dynamic__ToString = dart.constFn(dart.definiteFunctionType(core.String, [dart.dynamic], {maxLineLength: core.int, maxItems: core.int})))();
  let intToString = () => (intToString = dart.constFn(dart.definiteFunctionType(core.String, [core.int])))();
  let StringTobool = () => (StringTobool = dart.constFn(dart.definiteFunctionType(core.bool, [core.String])))();
  src__interfaces.Matcher = class Matcher extends core.Object {
    new() {
    }
    describeMismatch(item, mismatchDescription, matchState, verbose) {
      return mismatchDescription;
    }
  };
  dart.setSignature(src__interfaces.Matcher, {
    constructors: () => ({new: dart.definiteFunctionType(src__interfaces.Matcher, [])}),
    methods: () => ({describeMismatch: dart.definiteFunctionType(src__interfaces.Description, [dart.dynamic, src__interfaces.Description, core.Map, core.bool])})
  });
  src__core_matchers._IsTrue = class _IsTrue extends src__interfaces.Matcher {
    new() {
      super.new();
    }
    matches(item, matchState) {
      return dart.equals(item, true);
    }
    describe(description) {
      return description.add('true');
    }
  };
  dart.setSignature(src__core_matchers._IsTrue, {
    constructors: () => ({new: dart.definiteFunctionType(src__core_matchers._IsTrue, [])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__interfaces.Description, [src__interfaces.Description])
    })
  });
  src__core_matchers.isTrue = dart.const(new src__core_matchers._IsTrue());
  matcher.isTrue = src__core_matchers.isTrue;
  src__core_matchers._IsFalse = class _IsFalse extends src__interfaces.Matcher {
    new() {
      super.new();
    }
    matches(item, matchState) {
      return dart.equals(item, false);
    }
    describe(description) {
      return description.add('false');
    }
  };
  dart.setSignature(src__core_matchers._IsFalse, {
    constructors: () => ({new: dart.definiteFunctionType(src__core_matchers._IsFalse, [])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__interfaces.Description, [src__interfaces.Description])
    })
  });
  src__core_matchers.isFalse = dart.const(new src__core_matchers._IsFalse());
  matcher.isFalse = src__core_matchers.isFalse;
  src__core_matchers._Empty = class _Empty extends src__interfaces.Matcher {
    new() {
      super.new();
    }
    matches(item, matchState) {
      return core.bool._check(dart.dload(item, 'isEmpty'));
    }
    describe(description) {
      return description.add('empty');
    }
  };
  dart.setSignature(src__core_matchers._Empty, {
    constructors: () => ({new: dart.definiteFunctionType(src__core_matchers._Empty, [])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__interfaces.Description, [src__interfaces.Description])
    })
  });
  src__core_matchers.isEmpty = dart.const(new src__core_matchers._Empty());
  matcher.isEmpty = src__core_matchers.isEmpty;
  src__core_matchers.same = function(expected) {
    return new src__core_matchers._IsSameAs(expected);
  };
  dart.fn(src__core_matchers.same, dynamicToMatcher());
  matcher.same = src__core_matchers.same;
  src__core_matchers.equals = function(expected, limit) {
    if (limit === void 0) limit = 100;
    return typeof expected == 'string' ? new src__core_matchers._StringEqualsMatcher(expected) : new src__core_matchers._DeepMatcher(expected, limit);
  };
  dart.fn(src__core_matchers.equals, dynamic__ToMatcher());
  matcher.equals = src__core_matchers.equals;
  const _featureDescription = Symbol('_featureDescription');
  const _featureName = Symbol('_featureName');
  const _matcher = Symbol('_matcher');
  src__core_matchers.CustomMatcher = class CustomMatcher extends src__interfaces.Matcher {
    new(featureDescription, featureName, matcher) {
      this[_featureDescription] = featureDescription;
      this[_featureName] = featureName;
      this[_matcher] = src__util.wrapMatcher(matcher);
      super.new();
    }
    featureValueOf(actual) {
      return actual;
    }
    matches(item, matchState) {
      let f = this.featureValueOf(item);
      if (dart.test(this[_matcher].matches(f, matchState))) return true;
      src__util.addStateInfo(matchState, dart.map({feature: f}, core.String, dart.dynamic));
      return false;
    }
    describe(description) {
      return description.add(this[_featureDescription]).add(' ').addDescriptionOf(this[_matcher]);
    }
    describeMismatch(item, mismatchDescription, matchState, verbose) {
      mismatchDescription.add('has ').add(this[_featureName]).add(' with value ').addDescriptionOf(matchState[dartx.get]('feature'));
      let innerDescription = new src__description.StringDescription();
      this[_matcher].describeMismatch(matchState[dartx.get]('feature'), innerDescription, core.Map._check(matchState[dartx.get]('state')), verbose);
      if (dart.notNull(innerDescription.length) > 0) {
        mismatchDescription.add(' which ').add(innerDescription.toString());
      }
      return mismatchDescription;
    }
  };
  dart.setSignature(src__core_matchers.CustomMatcher, {
    constructors: () => ({new: dart.definiteFunctionType(src__core_matchers.CustomMatcher, [core.String, core.String, dart.dynamic])}),
    methods: () => ({
      featureValueOf: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__interfaces.Description, [src__interfaces.Description])
    })
  });
  matcher.CustomMatcher = src__core_matchers.CustomMatcher;
  const _name = Symbol('_name');
  src__core_matchers.TypeMatcher = class TypeMatcher extends src__interfaces.Matcher {
    new(name) {
      this[_name] = name;
      super.new();
    }
    describe(description) {
      return description.add(this[_name]);
    }
  };
  dart.setSignature(src__core_matchers.TypeMatcher, {
    constructors: () => ({new: dart.definiteFunctionType(src__core_matchers.TypeMatcher, [core.String])}),
    methods: () => ({describe: dart.definiteFunctionType(src__interfaces.Description, [src__interfaces.Description])})
  });
  src__core_matchers._IsList = class _IsList extends src__core_matchers.TypeMatcher {
    new() {
      super.new("List");
    }
    matches(item, matchState) {
      return core.List.is(item);
    }
  };
  dart.setSignature(src__core_matchers._IsList, {
    constructors: () => ({new: dart.definiteFunctionType(src__core_matchers._IsList, [])}),
    methods: () => ({matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map])})
  });
  src__core_matchers.isList = dart.const(new src__core_matchers._IsList());
  matcher.isList = src__core_matchers.isList;
  src__core_matchers.predicate = function(f, description) {
    if (description === void 0) description = 'satisfies function';
    return new src__core_matchers._Predicate(f, description);
  };
  dart.fn(src__core_matchers.predicate, Fn__ToMatcher());
  matcher.predicate = src__core_matchers.predicate;
  src__core_matchers._IsNotNull = class _IsNotNull extends src__interfaces.Matcher {
    new() {
      super.new();
    }
    matches(item, matchState) {
      return item != null;
    }
    describe(description) {
      return description.add('not null');
    }
  };
  dart.setSignature(src__core_matchers._IsNotNull, {
    constructors: () => ({new: dart.definiteFunctionType(src__core_matchers._IsNotNull, [])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__interfaces.Description, [src__interfaces.Description])
    })
  });
  src__core_matchers.isNotNull = dart.const(new src__core_matchers._IsNotNull());
  matcher.isNotNull = src__core_matchers.isNotNull;
  src__core_matchers.hasLength = function(matcher) {
    return new src__core_matchers._HasLength(src__util.wrapMatcher(matcher));
  };
  dart.fn(src__core_matchers.hasLength, dynamicToMatcher());
  matcher.hasLength = src__core_matchers.hasLength;
  src__core_matchers.isInstanceOf$ = dart.generic(T => {
    class isInstanceOf extends src__interfaces.Matcher {
      new() {
        super.new();
      }
      matches(obj, matchState) {
        return T.is(obj);
      }
      describe(description) {
        return description.add(dart.str`an instance of ${dart.wrapType(T)}`);
      }
    }
    dart.addTypeTests(isInstanceOf);
    dart.setSignature(isInstanceOf, {
      constructors: () => ({new: dart.definiteFunctionType(src__core_matchers.isInstanceOf$(T), [])}),
      methods: () => ({
        matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
        describe: dart.definiteFunctionType(src__interfaces.Description, [src__interfaces.Description])
      })
    });
    return isInstanceOf;
  });
  src__core_matchers.isInstanceOf = isInstanceOf();
  matcher.isInstanceOf$ = src__core_matchers.isInstanceOf$;
  matcher.isInstanceOf = src__core_matchers.isInstanceOf;
  src__core_matchers._IsNaN = class _IsNaN extends src__interfaces.Matcher {
    new() {
      super.new();
    }
    matches(item, matchState) {
      return core.double.NAN[dartx.compareTo](core.num._check(item)) == 0;
    }
    describe(description) {
      return description.add('NaN');
    }
  };
  dart.setSignature(src__core_matchers._IsNaN, {
    constructors: () => ({new: dart.definiteFunctionType(src__core_matchers._IsNaN, [])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__interfaces.Description, [src__interfaces.Description])
    })
  });
  src__core_matchers.isNaN = dart.const(new src__core_matchers._IsNaN());
  matcher.isNaN = src__core_matchers.isNaN;
  src__core_matchers._ReturnsNormally = class _ReturnsNormally extends src__interfaces.Matcher {
    new() {
      super.new();
    }
    matches(f, matchState) {
      try {
        dart.dcall(f);
        return true;
      } catch (e) {
        let s = dart.stackTrace(e);
        src__util.addStateInfo(matchState, dart.map({exception: e, stack: s}, core.String, dart.dynamic));
        return false;
      }

    }
    describe(description) {
      return description.add("return normally");
    }
    describeMismatch(item, mismatchDescription, matchState, verbose) {
      mismatchDescription.add('threw ').addDescriptionOf(matchState[dartx.get]('exception'));
      if (dart.test(verbose)) {
        mismatchDescription.add(' at ').add(dart.toString(matchState[dartx.get]('stack')));
      }
      return mismatchDescription;
    }
  };
  dart.setSignature(src__core_matchers._ReturnsNormally, {
    constructors: () => ({new: dart.definiteFunctionType(src__core_matchers._ReturnsNormally, [])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__interfaces.Description, [src__interfaces.Description])
    })
  });
  src__core_matchers.returnsNormally = dart.const(new src__core_matchers._ReturnsNormally());
  matcher.returnsNormally = src__core_matchers.returnsNormally;
  src__core_matchers._IsAnything = class _IsAnything extends src__interfaces.Matcher {
    new() {
      super.new();
    }
    matches(item, matchState) {
      return true;
    }
    describe(description) {
      return description.add('anything');
    }
  };
  dart.setSignature(src__core_matchers._IsAnything, {
    constructors: () => ({new: dart.definiteFunctionType(src__core_matchers._IsAnything, [])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__interfaces.Description, [src__interfaces.Description])
    })
  });
  src__core_matchers.anything = dart.const(new src__core_matchers._IsAnything());
  matcher.anything = src__core_matchers.anything;
  matcher.TypeMatcher = src__core_matchers.TypeMatcher;
  src__core_matchers.contains = function(expected) {
    return new src__core_matchers._Contains(expected);
  };
  dart.fn(src__core_matchers.contains, dynamicToMatcher());
  matcher.contains = src__core_matchers.contains;
  src__core_matchers._NotEmpty = class _NotEmpty extends src__interfaces.Matcher {
    new() {
      super.new();
    }
    matches(item, matchState) {
      return core.bool._check(dart.dload(item, 'isNotEmpty'));
    }
    describe(description) {
      return description.add('non-empty');
    }
  };
  dart.setSignature(src__core_matchers._NotEmpty, {
    constructors: () => ({new: dart.definiteFunctionType(src__core_matchers._NotEmpty, [])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__interfaces.Description, [src__interfaces.Description])
    })
  });
  src__core_matchers.isNotEmpty = dart.const(new src__core_matchers._NotEmpty());
  matcher.isNotEmpty = src__core_matchers.isNotEmpty;
  src__core_matchers._IsNull = class _IsNull extends src__interfaces.Matcher {
    new() {
      super.new();
    }
    matches(item, matchState) {
      return item == null;
    }
    describe(description) {
      return description.add('null');
    }
  };
  dart.setSignature(src__core_matchers._IsNull, {
    constructors: () => ({new: dart.definiteFunctionType(src__core_matchers._IsNull, [])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__interfaces.Description, [src__interfaces.Description])
    })
  });
  src__core_matchers.isNull = dart.const(new src__core_matchers._IsNull());
  matcher.isNull = src__core_matchers.isNull;
  src__core_matchers._IsMap = class _IsMap extends src__core_matchers.TypeMatcher {
    new() {
      super.new("Map");
    }
    matches(item, matchState) {
      return core.Map.is(item);
    }
  };
  dart.setSignature(src__core_matchers._IsMap, {
    constructors: () => ({new: dart.definiteFunctionType(src__core_matchers._IsMap, [])}),
    methods: () => ({matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map])})
  });
  src__core_matchers.isMap = dart.const(new src__core_matchers._IsMap());
  matcher.isMap = src__core_matchers.isMap;
  src__core_matchers._IsNotNaN = class _IsNotNaN extends src__interfaces.Matcher {
    new() {
      super.new();
    }
    matches(item, matchState) {
      return core.double.NAN[dartx.compareTo](core.num._check(item)) != 0;
    }
    describe(description) {
      return description.add('not NaN');
    }
  };
  dart.setSignature(src__core_matchers._IsNotNaN, {
    constructors: () => ({new: dart.definiteFunctionType(src__core_matchers._IsNotNaN, [])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__interfaces.Description, [src__interfaces.Description])
    })
  });
  src__core_matchers.isNotNaN = dart.const(new src__core_matchers._IsNotNaN());
  matcher.isNotNaN = src__core_matchers.isNotNaN;
  src__core_matchers.isIn = function(expected) {
    return new src__core_matchers._In(expected);
  };
  dart.fn(src__core_matchers.isIn, dynamicToMatcher());
  matcher.isIn = src__core_matchers.isIn;
  const _out = Symbol('_out');
  src__description.StringDescription = class StringDescription extends core.Object {
    new(init) {
      if (init === void 0) init = '';
      this[_out] = new core.StringBuffer();
      this[_out].write(init);
    }
    get length() {
      return this[_out].length;
    }
    toString() {
      return dart.toString(this[_out]);
    }
    add(text) {
      this[_out].write(text);
      return this;
    }
    replace(text) {
      this[_out].clear();
      return this.add(text);
    }
    addDescriptionOf(value) {
      if (src__interfaces.Matcher.is(value)) {
        value.describe(this);
      } else {
        this.add(src__pretty_print.prettyPrint(value, {maxLineLength: 80, maxItems: 25}));
      }
      return this;
    }
    addAll(start, separator, end, list) {
      let separate = false;
      this.add(start);
      for (let item of list) {
        if (separate) {
          this.add(separator);
        }
        this.addDescriptionOf(item);
        separate = true;
      }
      this.add(end);
      return this;
    }
  };
  src__description.StringDescription[dart.implements] = () => [src__interfaces.Description];
  dart.setSignature(src__description.StringDescription, {
    constructors: () => ({new: dart.definiteFunctionType(src__description.StringDescription, [], [core.String])}),
    methods: () => ({
      add: dart.definiteFunctionType(src__interfaces.Description, [core.String]),
      replace: dart.definiteFunctionType(src__interfaces.Description, [core.String]),
      addDescriptionOf: dart.definiteFunctionType(src__interfaces.Description, [dart.dynamic]),
      addAll: dart.definiteFunctionType(src__interfaces.Description, [core.String, core.String, core.String, core.Iterable])
    })
  });
  matcher.StringDescription = src__description.StringDescription;
  src__error_matchers._ConcurrentModificationError = class _ConcurrentModificationError extends src__core_matchers.TypeMatcher {
    new() {
      super.new("ConcurrentModificationError");
    }
    matches(item, matchState) {
      return core.ConcurrentModificationError.is(item);
    }
  };
  dart.setSignature(src__error_matchers._ConcurrentModificationError, {
    constructors: () => ({new: dart.definiteFunctionType(src__error_matchers._ConcurrentModificationError, [])}),
    methods: () => ({matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map])})
  });
  src__error_matchers.isConcurrentModificationError = dart.const(new src__error_matchers._ConcurrentModificationError());
  matcher.isConcurrentModificationError = src__error_matchers.isConcurrentModificationError;
  src__error_matchers._CyclicInitializationError = class _CyclicInitializationError extends src__core_matchers.TypeMatcher {
    new() {
      super.new("CyclicInitializationError");
    }
    matches(item, matchState) {
      return core.CyclicInitializationError.is(item);
    }
  };
  dart.setSignature(src__error_matchers._CyclicInitializationError, {
    constructors: () => ({new: dart.definiteFunctionType(src__error_matchers._CyclicInitializationError, [])}),
    methods: () => ({matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map])})
  });
  src__error_matchers.isCyclicInitializationError = dart.const(new src__error_matchers._CyclicInitializationError());
  matcher.isCyclicInitializationError = src__error_matchers.isCyclicInitializationError;
  src__error_matchers._ArgumentError = class _ArgumentError extends src__core_matchers.TypeMatcher {
    new() {
      super.new("ArgumentError");
    }
    matches(item, matchState) {
      return core.ArgumentError.is(item);
    }
  };
  dart.setSignature(src__error_matchers._ArgumentError, {
    constructors: () => ({new: dart.definiteFunctionType(src__error_matchers._ArgumentError, [])}),
    methods: () => ({matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map])})
  });
  src__error_matchers.isArgumentError = dart.const(new src__error_matchers._ArgumentError());
  matcher.isArgumentError = src__error_matchers.isArgumentError;
  src__error_matchers._Exception = class _Exception extends src__core_matchers.TypeMatcher {
    new() {
      super.new("Exception");
    }
    matches(item, matchState) {
      return core.Exception.is(item);
    }
  };
  dart.setSignature(src__error_matchers._Exception, {
    constructors: () => ({new: dart.definiteFunctionType(src__error_matchers._Exception, [])}),
    methods: () => ({matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map])})
  });
  src__error_matchers.isException = dart.const(new src__error_matchers._Exception());
  matcher.isException = src__error_matchers.isException;
  src__error_matchers._NullThrownError = class _NullThrownError extends src__core_matchers.TypeMatcher {
    new() {
      super.new("NullThrownError");
    }
    matches(item, matchState) {
      return core.NullThrownError.is(item);
    }
  };
  dart.setSignature(src__error_matchers._NullThrownError, {
    constructors: () => ({new: dart.definiteFunctionType(src__error_matchers._NullThrownError, [])}),
    methods: () => ({matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map])})
  });
  src__error_matchers.isNullThrownError = dart.const(new src__error_matchers._NullThrownError());
  matcher.isNullThrownError = src__error_matchers.isNullThrownError;
  src__error_matchers._RangeError = class _RangeError extends src__core_matchers.TypeMatcher {
    new() {
      super.new("RangeError");
    }
    matches(item, matchState) {
      return core.RangeError.is(item);
    }
  };
  dart.setSignature(src__error_matchers._RangeError, {
    constructors: () => ({new: dart.definiteFunctionType(src__error_matchers._RangeError, [])}),
    methods: () => ({matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map])})
  });
  src__error_matchers.isRangeError = dart.const(new src__error_matchers._RangeError());
  matcher.isRangeError = src__error_matchers.isRangeError;
  src__error_matchers._FormatException = class _FormatException extends src__core_matchers.TypeMatcher {
    new() {
      super.new("FormatException");
    }
    matches(item, matchState) {
      return core.FormatException.is(item);
    }
  };
  dart.setSignature(src__error_matchers._FormatException, {
    constructors: () => ({new: dart.definiteFunctionType(src__error_matchers._FormatException, [])}),
    methods: () => ({matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map])})
  });
  src__error_matchers.isFormatException = dart.const(new src__error_matchers._FormatException());
  matcher.isFormatException = src__error_matchers.isFormatException;
  src__error_matchers._StateError = class _StateError extends src__core_matchers.TypeMatcher {
    new() {
      super.new("StateError");
    }
    matches(item, matchState) {
      return core.StateError.is(item);
    }
  };
  dart.setSignature(src__error_matchers._StateError, {
    constructors: () => ({new: dart.definiteFunctionType(src__error_matchers._StateError, [])}),
    methods: () => ({matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map])})
  });
  src__error_matchers.isStateError = dart.const(new src__error_matchers._StateError());
  matcher.isStateError = src__error_matchers.isStateError;
  src__error_matchers._NoSuchMethodError = class _NoSuchMethodError extends src__core_matchers.TypeMatcher {
    new() {
      super.new("NoSuchMethodError");
    }
    matches(item, matchState) {
      return core.NoSuchMethodError.is(item);
    }
  };
  dart.setSignature(src__error_matchers._NoSuchMethodError, {
    constructors: () => ({new: dart.definiteFunctionType(src__error_matchers._NoSuchMethodError, [])}),
    methods: () => ({matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map])})
  });
  src__error_matchers.isNoSuchMethodError = dart.const(new src__error_matchers._NoSuchMethodError());
  matcher.isNoSuchMethodError = src__error_matchers.isNoSuchMethodError;
  src__error_matchers._UnimplementedError = class _UnimplementedError extends src__core_matchers.TypeMatcher {
    new() {
      super.new("UnimplementedError");
    }
    matches(item, matchState) {
      return core.UnimplementedError.is(item);
    }
  };
  dart.setSignature(src__error_matchers._UnimplementedError, {
    constructors: () => ({new: dart.definiteFunctionType(src__error_matchers._UnimplementedError, [])}),
    methods: () => ({matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map])})
  });
  src__error_matchers.isUnimplementedError = dart.const(new src__error_matchers._UnimplementedError());
  matcher.isUnimplementedError = src__error_matchers.isUnimplementedError;
  src__error_matchers._UnsupportedError = class _UnsupportedError extends src__core_matchers.TypeMatcher {
    new() {
      super.new("UnsupportedError");
    }
    matches(item, matchState) {
      return core.UnsupportedError.is(item);
    }
  };
  dart.setSignature(src__error_matchers._UnsupportedError, {
    constructors: () => ({new: dart.definiteFunctionType(src__error_matchers._UnsupportedError, [])}),
    methods: () => ({matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map])})
  });
  src__error_matchers.isUnsupportedError = dart.const(new src__error_matchers._UnsupportedError());
  matcher.isUnsupportedError = src__error_matchers.isUnsupportedError;
  matcher.Matcher = src__interfaces.Matcher;
  src__interfaces.Description = class Description extends core.Object {};
  matcher.Description = src__interfaces.Description;
  src__iterable_matchers.pairwiseCompare = function(expected, comparator, description) {
    return new src__iterable_matchers._PairwiseCompare(expected, comparator, description);
  };
  dart.fn(src__iterable_matchers.pairwiseCompare, IterableAndFnAndStringToMatcher());
  matcher.pairwiseCompare = src__iterable_matchers.pairwiseCompare;
  src__iterable_matchers.anyElement = function(matcher) {
    return new src__iterable_matchers._AnyElement(src__util.wrapMatcher(matcher));
  };
  dart.fn(src__iterable_matchers.anyElement, dynamicToMatcher());
  matcher.anyElement = src__iterable_matchers.anyElement;
  src__iterable_matchers.orderedEquals = function(expected) {
    return new src__iterable_matchers._OrderedEquals(expected);
  };
  dart.fn(src__iterable_matchers.orderedEquals, IterableToMatcher());
  matcher.orderedEquals = src__iterable_matchers.orderedEquals;
  src__iterable_matchers.unorderedEquals = function(expected) {
    return new src__iterable_matchers._UnorderedEquals(expected);
  };
  dart.fn(src__iterable_matchers.unorderedEquals, IterableToMatcher());
  matcher.unorderedEquals = src__iterable_matchers.unorderedEquals;
  src__iterable_matchers.unorderedMatches = function(expected) {
    return new src__iterable_matchers._UnorderedMatches(expected);
  };
  dart.fn(src__iterable_matchers.unorderedMatches, IterableToMatcher());
  matcher.unorderedMatches = src__iterable_matchers.unorderedMatches;
  src__iterable_matchers.everyElement = function(matcher) {
    return new src__iterable_matchers._EveryElement(src__util.wrapMatcher(matcher));
  };
  dart.fn(src__iterable_matchers.everyElement, dynamicToMatcher());
  matcher.everyElement = src__iterable_matchers.everyElement;
  src__map_matchers.containsValue = function(value) {
    return new src__map_matchers._ContainsValue(value);
  };
  dart.fn(src__map_matchers.containsValue, dynamicToMatcher());
  matcher.containsValue = src__map_matchers.containsValue;
  src__map_matchers.containsPair = function(key, value) {
    return new src__map_matchers._ContainsMapping(key, src__util.wrapMatcher(value));
  };
  dart.fn(src__map_matchers.containsPair, dynamicAnddynamicToMatcher());
  matcher.containsPair = src__map_matchers.containsPair;
  const _value = Symbol('_value');
  const _equalValue = Symbol('_equalValue');
  const _lessThanValue = Symbol('_lessThanValue');
  const _greaterThanValue = Symbol('_greaterThanValue');
  const _comparisonDescription = Symbol('_comparisonDescription');
  const _valueInDescription = Symbol('_valueInDescription');
  src__numeric_matchers._OrderingComparison = class _OrderingComparison extends src__interfaces.Matcher {
    new(value, equalValue, lessThanValue, greaterThanValue, comparisonDescription, valueInDescription) {
      if (valueInDescription === void 0) valueInDescription = true;
      this[_value] = value;
      this[_equalValue] = equalValue;
      this[_lessThanValue] = lessThanValue;
      this[_greaterThanValue] = greaterThanValue;
      this[_comparisonDescription] = comparisonDescription;
      this[_valueInDescription] = valueInDescription;
      super.new();
    }
    matches(item, matchState) {
      if (dart.equals(item, this[_value])) {
        return this[_equalValue];
      } else if (dart.test(dart.dsend(item, '<', this[_value]))) {
        return this[_lessThanValue];
      } else {
        return this[_greaterThanValue];
      }
    }
    describe(description) {
      if (dart.test(this[_valueInDescription])) {
        return description.add(this[_comparisonDescription]).add(' ').addDescriptionOf(this[_value]);
      } else {
        return description.add(this[_comparisonDescription]);
      }
    }
    describeMismatch(item, mismatchDescription, matchState, verbose) {
      mismatchDescription.add('is not ');
      return this.describe(mismatchDescription);
    }
  };
  dart.setSignature(src__numeric_matchers._OrderingComparison, {
    constructors: () => ({new: dart.definiteFunctionType(src__numeric_matchers._OrderingComparison, [dart.dynamic, core.bool, core.bool, core.bool, core.String], [core.bool])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__interfaces.Description, [src__interfaces.Description])
    })
  });
  src__numeric_matchers.isPositive = dart.const(new src__numeric_matchers._OrderingComparison(0, false, false, true, 'a positive value', false));
  matcher.isPositive = src__numeric_matchers.isPositive;
  src__numeric_matchers.isZero = dart.const(new src__numeric_matchers._OrderingComparison(0, true, false, false, 'a value equal to'));
  matcher.isZero = src__numeric_matchers.isZero;
  src__numeric_matchers.inOpenClosedRange = function(low, high) {
    return new src__numeric_matchers._InRange(low, high, false, true);
  };
  dart.fn(src__numeric_matchers.inOpenClosedRange, numAndnumToMatcher());
  matcher.inOpenClosedRange = src__numeric_matchers.inOpenClosedRange;
  src__numeric_matchers.inClosedOpenRange = function(low, high) {
    return new src__numeric_matchers._InRange(low, high, true, false);
  };
  dart.fn(src__numeric_matchers.inClosedOpenRange, numAndnumToMatcher());
  matcher.inClosedOpenRange = src__numeric_matchers.inClosedOpenRange;
  src__numeric_matchers.lessThanOrEqualTo = function(value) {
    return new src__numeric_matchers._OrderingComparison(value, true, true, false, 'a value less than or equal to');
  };
  dart.fn(src__numeric_matchers.lessThanOrEqualTo, dynamicToMatcher());
  matcher.lessThanOrEqualTo = src__numeric_matchers.lessThanOrEqualTo;
  src__numeric_matchers.isNegative = dart.const(new src__numeric_matchers._OrderingComparison(0, false, true, false, 'a negative value', false));
  matcher.isNegative = src__numeric_matchers.isNegative;
  src__numeric_matchers.inInclusiveRange = function(low, high) {
    return new src__numeric_matchers._InRange(low, high, true, true);
  };
  dart.fn(src__numeric_matchers.inInclusiveRange, numAndnumToMatcher());
  matcher.inInclusiveRange = src__numeric_matchers.inInclusiveRange;
  src__numeric_matchers.lessThan = function(value) {
    return new src__numeric_matchers._OrderingComparison(value, false, true, false, 'a value less than');
  };
  dart.fn(src__numeric_matchers.lessThan, dynamicToMatcher());
  matcher.lessThan = src__numeric_matchers.lessThan;
  src__numeric_matchers.greaterThan = function(value) {
    return new src__numeric_matchers._OrderingComparison(value, false, false, true, 'a value greater than');
  };
  dart.fn(src__numeric_matchers.greaterThan, dynamicToMatcher());
  matcher.greaterThan = src__numeric_matchers.greaterThan;
  src__numeric_matchers.isNonNegative = dart.const(new src__numeric_matchers._OrderingComparison(0, true, false, true, 'a non-negative value', false));
  matcher.isNonNegative = src__numeric_matchers.isNonNegative;
  src__numeric_matchers.inExclusiveRange = function(low, high) {
    return new src__numeric_matchers._InRange(low, high, false, false);
  };
  dart.fn(src__numeric_matchers.inExclusiveRange, numAndnumToMatcher());
  matcher.inExclusiveRange = src__numeric_matchers.inExclusiveRange;
  src__numeric_matchers.closeTo = function(value, delta) {
    return new src__numeric_matchers._IsCloseTo(value, delta);
  };
  dart.fn(src__numeric_matchers.closeTo, numAndnumToMatcher());
  matcher.closeTo = src__numeric_matchers.closeTo;
  src__numeric_matchers.greaterThanOrEqualTo = function(value) {
    return new src__numeric_matchers._OrderingComparison(value, true, false, true, 'a value greater than or equal to');
  };
  dart.fn(src__numeric_matchers.greaterThanOrEqualTo, dynamicToMatcher());
  matcher.greaterThanOrEqualTo = src__numeric_matchers.greaterThanOrEqualTo;
  src__numeric_matchers.isNonZero = dart.const(new src__numeric_matchers._OrderingComparison(0, false, true, true, 'a value not equal to'));
  matcher.isNonZero = src__numeric_matchers.isNonZero;
  src__numeric_matchers.isNonPositive = dart.const(new src__numeric_matchers._OrderingComparison(0, true, true, false, 'a non-positive value', false));
  matcher.isNonPositive = src__numeric_matchers.isNonPositive;
  src__operator_matchers.allOf = function(arg0, arg1, arg2, arg3, arg4, arg5, arg6) {
    if (arg1 === void 0) arg1 = null;
    if (arg2 === void 0) arg2 = null;
    if (arg3 === void 0) arg3 = null;
    if (arg4 === void 0) arg4 = null;
    if (arg5 === void 0) arg5 = null;
    if (arg6 === void 0) arg6 = null;
    return new src__operator_matchers._AllOf(src__operator_matchers._wrapArgs(arg0, arg1, arg2, arg3, arg4, arg5, arg6));
  };
  dart.fn(src__operator_matchers.allOf, dynamic__ToMatcher$());
  matcher.allOf = src__operator_matchers.allOf;
  src__operator_matchers.isNot = function(matcher) {
    return new src__operator_matchers._IsNot(src__util.wrapMatcher(matcher));
  };
  dart.fn(src__operator_matchers.isNot, dynamicToMatcher());
  matcher.isNot = src__operator_matchers.isNot;
  src__operator_matchers.anyOf = function(arg0, arg1, arg2, arg3, arg4, arg5, arg6) {
    if (arg1 === void 0) arg1 = null;
    if (arg2 === void 0) arg2 = null;
    if (arg3 === void 0) arg3 = null;
    if (arg4 === void 0) arg4 = null;
    if (arg5 === void 0) arg5 = null;
    if (arg6 === void 0) arg6 = null;
    return new src__operator_matchers._AnyOf(src__operator_matchers._wrapArgs(arg0, arg1, arg2, arg3, arg4, arg5, arg6));
  };
  dart.fn(src__operator_matchers.anyOf, dynamic__ToMatcher$());
  matcher.anyOf = src__operator_matchers.anyOf;
  src__string_matchers.endsWith = function(suffixString) {
    return new src__string_matchers._StringEndsWith(suffixString);
  };
  dart.fn(src__string_matchers.endsWith, StringToMatcher());
  matcher.endsWith = src__string_matchers.endsWith;
  src__string_matchers.startsWith = function(prefixString) {
    return new src__string_matchers._StringStartsWith(prefixString);
  };
  dart.fn(src__string_matchers.startsWith, StringToMatcher());
  matcher.startsWith = src__string_matchers.startsWith;
  src__string_matchers.matches = function(re) {
    return new src__string_matchers._MatchesRegExp(re);
  };
  dart.fn(src__string_matchers.matches, dynamicToMatcher());
  matcher.matches = src__string_matchers.matches;
  src__string_matchers.collapseWhitespace = function(string) {
    let result = new core.StringBuffer();
    let skipSpace = true;
    for (let i = 0; i < dart.notNull(string[dartx.length]); i++) {
      let character = string[dartx.get](i);
      if (dart.test(src__string_matchers._isWhitespace(character))) {
        if (!skipSpace) {
          result.write(' ');
          skipSpace = true;
        }
      } else {
        result.write(character);
        skipSpace = false;
      }
    }
    return result.toString()[dartx.trim]();
  };
  dart.fn(src__string_matchers.collapseWhitespace, StringToString());
  matcher.collapseWhitespace = src__string_matchers.collapseWhitespace;
  src__string_matchers.equalsIgnoringCase = function(value) {
    return new src__string_matchers._IsEqualIgnoringCase(value);
  };
  dart.fn(src__string_matchers.equalsIgnoringCase, StringToMatcher());
  matcher.equalsIgnoringCase = src__string_matchers.equalsIgnoringCase;
  src__string_matchers.equalsIgnoringWhitespace = function(value) {
    return new src__string_matchers._IsEqualIgnoringWhitespace(value);
  };
  dart.fn(src__string_matchers.equalsIgnoringWhitespace, StringToMatcher());
  matcher.equalsIgnoringWhitespace = src__string_matchers.equalsIgnoringWhitespace;
  src__string_matchers.stringContainsInOrder = function(substrings) {
    return new src__string_matchers._StringContainsInOrder(substrings);
  };
  dart.fn(src__string_matchers.stringContainsInOrder, ListOfStringToMatcher());
  matcher.stringContainsInOrder = src__string_matchers.stringContainsInOrder;
  src__util.addStateInfo = function(matchState, values) {
    let innerState = core.Map.from(matchState);
    matchState[dartx.clear]();
    matchState[dartx.set]('state', innerState);
    matchState[dartx.addAll](values);
  };
  dart.fn(src__util.addStateInfo, MapAndMapTovoid());
  matcher.addStateInfo = src__util.addStateInfo;
  src__util.wrapMatcher = function(x) {
    if (src__interfaces.Matcher.is(x)) {
      return x;
    } else if (src__util._Predicate.is(x)) {
      return src__core_matchers.predicate(x);
    } else {
      return src__core_matchers.equals(x);
    }
  };
  dart.fn(src__util.wrapMatcher, dynamicToMatcher());
  matcher.wrapMatcher = src__util.wrapMatcher;
  src__util.escape = function(str) {
    str = str[dartx.replaceAll]('\\', '\\\\');
    return str[dartx.replaceAllMapped](src__util._escapeRegExp, dart.fn(match => {
      let mapped = src__util._escapeMap[dartx.get](match.get(0));
      if (mapped != null) return mapped;
      return src__util._getHexLiteral(match.get(0));
    }, MatchToString()));
  };
  dart.fn(src__util.escape, StringToString());
  matcher.escape = src__util.escape;
  mirror_matchers.hasProperty = function(name, matcher) {
    if (matcher === void 0) matcher = null;
    return new mirror_matchers._HasProperty(name, matcher == null ? null : src__util.wrapMatcher(matcher));
  };
  dart.fn(mirror_matchers.hasProperty, String__ToMatcher());
  const _name$ = Symbol('_name');
  const _matcher$ = Symbol('_matcher');
  mirror_matchers._HasProperty = class _HasProperty extends src__interfaces.Matcher {
    new(name, matcher) {
      if (matcher === void 0) matcher = null;
      this[_name$] = name;
      this[_matcher$] = matcher;
      super.new();
    }
    matches(item, matchState) {
      let mirror = mirrors.reflect(item);
      let classMirror = mirror.type;
      let symbol = core.Symbol.new(this[_name$]);
      let candidate = classMirror.declarations[dartx.get](symbol);
      if (candidate == null) {
        src__util.addStateInfo(matchState, dart.map({reason: dart.str`has no property named "${this[_name$]}"`}, core.String, core.String));
        return false;
      }
      let isInstanceField = mirrors.VariableMirror.is(candidate) && !dart.test(candidate.isStatic);
      let isInstanceGetter = mirrors.MethodMirror.is(candidate) && dart.test(candidate.isGetter) && !dart.test(candidate.isStatic);
      if (!(isInstanceField || isInstanceGetter)) {
        src__util.addStateInfo(matchState, dart.map({reason: dart.str`has a member named "${this[_name$]}", but it is not an instance property`}, core.String, core.String));
        return false;
      }
      if (this[_matcher$] == null) return true;
      let result = mirror.getField(symbol);
      let resultMatches = this[_matcher$].matches(result.reflectee, matchState);
      if (!dart.test(resultMatches)) {
        src__util.addStateInfo(matchState, dart.map({value: result.reflectee}, core.String, dart.dynamic));
      }
      return resultMatches;
    }
    describe(description) {
      description.add(dart.str`has property "${this[_name$]}"`);
      if (this[_matcher$] != null) {
        description.add(' which matches ').addDescriptionOf(this[_matcher$]);
      }
      return description;
    }
    describeMismatch(item, mismatchDescription, matchState, verbose) {
      let reason = matchState == null ? null : matchState[dartx.get]('reason');
      if (reason != null) {
        mismatchDescription.add(core.String._check(reason));
      } else {
        mismatchDescription.add(dart.str`has property "${this[_name$]}" with value `).addDescriptionOf(matchState[dartx.get]('value'));
        let innerDescription = new src__description.StringDescription();
        this[_matcher$].describeMismatch(matchState[dartx.get]('value'), innerDescription, core.Map._check(matchState[dartx.get]('state')), verbose);
        if (dart.notNull(innerDescription.length) > 0) {
          mismatchDescription.add(' which ').add(innerDescription.toString());
        }
      }
      return mismatchDescription;
    }
  };
  dart.setSignature(mirror_matchers._HasProperty, {
    constructors: () => ({new: dart.definiteFunctionType(mirror_matchers._HasProperty, [core.String], [src__interfaces.Matcher])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__interfaces.Description, [src__interfaces.Description])
    })
  });
  const _expected = Symbol('_expected');
  src__core_matchers._IsSameAs = class _IsSameAs extends src__interfaces.Matcher {
    new(expected) {
      this[_expected] = expected;
      super.new();
    }
    matches(item, matchState) {
      return core.identical(item, this[_expected]);
    }
    describe(description) {
      return description.add('same instance as ').addDescriptionOf(this[_expected]);
    }
  };
  dart.setSignature(src__core_matchers._IsSameAs, {
    constructors: () => ({new: dart.definiteFunctionType(src__core_matchers._IsSameAs, [dart.dynamic])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__interfaces.Description, [src__interfaces.Description])
    })
  });
  const _limit = Symbol('_limit');
  const _compareIterables = Symbol('_compareIterables');
  const _compareSets = Symbol('_compareSets');
  const _recursiveMatch = Symbol('_recursiveMatch');
  const _match = Symbol('_match');
  src__core_matchers._DeepMatcher = class _DeepMatcher extends src__interfaces.Matcher {
    new(expected, limit) {
      if (limit === void 0) limit = 1000;
      this[_expected] = expected;
      this[_limit] = limit;
      this.count = null;
      super.new();
    }
    [_compareIterables](expected, actual, matcher, depth, location) {
      if (!core.Iterable.is(actual)) return ['is not Iterable', location];
      let expectedIterator = dart.dload(expected, 'iterator');
      let actualIterator = dart.dload(actual, 'iterator');
      for (let index = 0;; index++) {
        let expectedNext = dart.dsend(expectedIterator, 'moveNext');
        let actualNext = dart.dsend(actualIterator, 'moveNext');
        if (!dart.test(expectedNext) && !dart.test(actualNext)) return null;
        let newLocation = dart.str`${location}[${index}]`;
        if (!dart.test(expectedNext)) return JSArrayOfString().of(['longer than expected', newLocation]);
        if (!dart.test(actualNext)) return JSArrayOfString().of(['shorter than expected', newLocation]);
        let rp = dart.dcall(matcher, dart.dload(expectedIterator, 'current'), dart.dload(actualIterator, 'current'), newLocation, depth);
        if (rp != null) return core.List._check(rp);
      }
    }
    [_compareSets](expected, actual, matcher, depth, location) {
      if (!core.Iterable.is(actual)) return ['is not Iterable', location];
      actual = dart.dsend(actual, 'toSet');
      for (let expectedElement of expected) {
        if (dart.test(dart.dsend(actual, 'every', dart.fn(actualElement => dart.dcall(matcher, expectedElement, actualElement, location, depth) != null, dynamicTobool$())))) {
          return [dart.str`does not contain ${expectedElement}`, location];
        }
      }
      if (dart.test(dart.dsend(dart.dload(actual, 'length'), '>', expected.length))) {
        return ['larger than expected', location];
      } else if (dart.test(dart.dsend(dart.dload(actual, 'length'), '<', expected.length))) {
        return ['smaller than expected', location];
      } else {
        return null;
      }
    }
    [_recursiveMatch](expected, actual, location, depth) {
      if (src__interfaces.Matcher.is(expected)) {
        let matchState = dart.map();
        if (dart.test(expected.matches(actual, matchState))) return null;
        let description = new src__description.StringDescription();
        expected.describe(description);
        return JSArrayOfString().of([dart.str`does not match ${description}`, location]);
      } else {
        try {
          if (dart.equals(expected, actual)) return null;
        } catch (e) {
          return JSArrayOfString().of([dart.str`== threw "${e}"`, location]);
        }

      }
      if (dart.notNull(depth) > dart.notNull(this[_limit])) return JSArrayOfString().of(['recursion depth limit exceeded', location]);
      if (depth == 0 || dart.notNull(this[_limit]) > 1) {
        if (core.Set.is(expected)) {
          return this[_compareSets](expected, actual, dart.bind(this, _recursiveMatch), dart.notNull(depth) + 1, location);
        } else if (core.Iterable.is(expected)) {
          return this[_compareIterables](expected, actual, dart.bind(this, _recursiveMatch), dart.notNull(depth) + 1, location);
        } else if (core.Map.is(expected)) {
          if (!core.Map.is(actual)) return JSArrayOfString().of(['expected a map', location]);
          let err = dart.equals(expected[dartx.length], dart.dload(actual, 'length')) ? '' : 'has different length and ';
          for (let key of expected[dartx.keys]) {
            if (!dart.test(dart.dsend(actual, 'containsKey', key))) {
              return JSArrayOfString().of([dart.str`${err}is missing map key '${key}'`, location]);
            }
          }
          for (let key of core.Iterable._check(dart.dload(actual, 'keys'))) {
            if (!dart.test(expected[dartx.containsKey](key))) {
              return JSArrayOfString().of([dart.str`${err}has extra map key '${key}'`, location]);
            }
          }
          for (let key of expected[dartx.keys]) {
            let rp = this[_recursiveMatch](expected[dartx.get](key), dart.dindex(actual, key), dart.str`${location}['${key}']`, dart.notNull(depth) + 1);
            if (rp != null) return rp;
          }
          return null;
        }
      }
      let description = new src__description.StringDescription();
      if (dart.notNull(depth) > 0) {
        description.add('was ').addDescriptionOf(actual).add(' instead of ').addDescriptionOf(expected);
        return JSArrayOfString().of([description.toString(), location]);
      }
      return JSArrayOfString().of(["", location]);
    }
    [_match](expected, actual, matchState) {
      let rp = this[_recursiveMatch](expected, actual, '', 0);
      if (rp == null) return null;
      let reason = null;
      if (dart.test(dart.dsend(dart.dload(rp[dartx.get](0), 'length'), '>', 0))) {
        if (dart.test(dart.dsend(dart.dload(rp[dartx.get](1), 'length'), '>', 0))) {
          reason = dart.str`${rp[dartx.get](0)} at location ${rp[dartx.get](1)}`;
        } else {
          reason = rp[dartx.get](0);
        }
      } else {
        reason = '';
      }
      src__util.addStateInfo(matchState, dart.map({reason: reason}, core.String, dart.dynamic));
      return core.String._check(reason);
    }
    matches(item, matchState) {
      return this[_match](this[_expected], item, matchState) == null;
    }
    describe(description) {
      return description.addDescriptionOf(this[_expected]);
    }
    describeMismatch(item, mismatchDescription, matchState, verbose) {
      let reason = matchState[dartx.get]('reason');
      if (dart.equals(dart.dload(reason, 'length'), 0) && dart.notNull(mismatchDescription.length) > 0) {
        mismatchDescription.add('is ').addDescriptionOf(item);
      } else {
        mismatchDescription.add(core.String._check(reason));
      }
      return mismatchDescription;
    }
  };
  dart.setSignature(src__core_matchers._DeepMatcher, {
    constructors: () => ({new: dart.definiteFunctionType(src__core_matchers._DeepMatcher, [dart.dynamic], [core.int])}),
    methods: () => ({
      [_compareIterables]: dart.definiteFunctionType(core.List, [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic]),
      [_compareSets]: dart.definiteFunctionType(core.List, [core.Set, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic]),
      [_recursiveMatch]: dart.definiteFunctionType(core.List, [dart.dynamic, dart.dynamic, core.String, core.int]),
      [_match]: dart.definiteFunctionType(core.String, [dart.dynamic, dart.dynamic, core.Map]),
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__interfaces.Description, [src__interfaces.Description])
    })
  });
  const _value$ = Symbol('_value');
  src__core_matchers._StringEqualsMatcher = class _StringEqualsMatcher extends src__interfaces.Matcher {
    new(value) {
      this[_value$] = value;
      super.new();
    }
    get showActualValue() {
      return true;
    }
    matches(item, matchState) {
      return dart.equals(this[_value$], item);
    }
    describe(description) {
      return description.addDescriptionOf(this[_value$]);
    }
    describeMismatch(item, mismatchDescription, matchState, verbose) {
      if (!(typeof item == 'string')) {
        return mismatchDescription.addDescriptionOf(item).add('is not a string');
      } else {
        let buff = new core.StringBuffer();
        buff.write('is different.');
        let escapedItem = src__util.escape(core.String._check(item));
        let escapedValue = src__util.escape(this[_value$]);
        let minLength = dart.notNull(escapedItem[dartx.length]) < dart.notNull(escapedValue[dartx.length]) ? escapedItem[dartx.length] : escapedValue[dartx.length];
        let start = 0;
        for (; start < dart.notNull(minLength); start++) {
          if (escapedValue[dartx.codeUnitAt](start) != escapedItem[dartx.codeUnitAt](start)) {
            break;
          }
        }
        if (start == minLength) {
          if (dart.notNull(escapedValue[dartx.length]) < dart.notNull(escapedItem[dartx.length])) {
            buff.write(' Both strings start the same, but the given value also' + ' has the following trailing characters: ');
            src__core_matchers._StringEqualsMatcher._writeTrailing(buff, escapedItem, escapedValue[dartx.length]);
          } else {
            buff.write(' Both strings start the same, but the given value is' + ' missing the following trailing characters: ');
            src__core_matchers._StringEqualsMatcher._writeTrailing(buff, escapedValue, escapedItem[dartx.length]);
          }
        } else {
          buff.write('\nExpected: ');
          src__core_matchers._StringEqualsMatcher._writeLeading(buff, escapedValue, start);
          src__core_matchers._StringEqualsMatcher._writeTrailing(buff, escapedValue, start);
          buff.write('\n  Actual: ');
          src__core_matchers._StringEqualsMatcher._writeLeading(buff, escapedItem, start);
          src__core_matchers._StringEqualsMatcher._writeTrailing(buff, escapedItem, start);
          buff.write('\n          ');
          for (let i = start > 10 ? 14 : start; i > 0; i--)
            buff.write(' ');
          buff.write(dart.str`^\n Differ at offset ${start}`);
        }
        return mismatchDescription.replace(buff.toString());
      }
    }
    static _writeLeading(buff, s, start) {
      if (dart.notNull(start) > 10) {
        buff.write('... ');
        buff.write(s[dartx.substring](dart.notNull(start) - 10, start));
      } else {
        buff.write(s[dartx.substring](0, start));
      }
    }
    static _writeTrailing(buff, s, start) {
      if (dart.notNull(start) + 10 > dart.notNull(s[dartx.length])) {
        buff.write(s[dartx.substring](start));
      } else {
        buff.write(s[dartx.substring](start, dart.notNull(start) + 10));
        buff.write(' ...');
      }
    }
  };
  dart.setSignature(src__core_matchers._StringEqualsMatcher, {
    constructors: () => ({new: dart.definiteFunctionType(src__core_matchers._StringEqualsMatcher, [core.String])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__interfaces.Description, [src__interfaces.Description])
    }),
    statics: () => ({
      _writeLeading: dart.definiteFunctionType(dart.void, [core.StringBuffer, core.String, core.int]),
      _writeTrailing: dart.definiteFunctionType(dart.void, [core.StringBuffer, core.String, core.int])
    }),
    names: ['_writeLeading', '_writeTrailing']
  });
  src__core_matchers._HasLength = class _HasLength extends src__interfaces.Matcher {
    new(matcher) {
      if (matcher === void 0) matcher = null;
      this[_matcher] = matcher;
      super.new();
    }
    matches(item, matchState) {
      try {
        if (dart.test(dart.dsend(dart.dsend(dart.dload(item, 'length'), '*', dart.dload(item, 'length')), '>=', 0))) {
          return this[_matcher].matches(dart.dload(item, 'length'), matchState);
        }
      } catch (e) {
      }

      return false;
    }
    describe(description) {
      return description.add('an object with length of ').addDescriptionOf(this[_matcher]);
    }
    describeMismatch(item, mismatchDescription, matchState, verbose) {
      try {
        if (dart.test(dart.dsend(dart.dsend(dart.dload(item, 'length'), '*', dart.dload(item, 'length')), '>=', 0))) {
          return mismatchDescription.add('has length of ').addDescriptionOf(dart.dload(item, 'length'));
        }
      } catch (e) {
      }

      return mismatchDescription.add('has no length property');
    }
  };
  dart.setSignature(src__core_matchers._HasLength, {
    constructors: () => ({new: dart.definiteFunctionType(src__core_matchers._HasLength, [], [src__interfaces.Matcher])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__interfaces.Description, [src__interfaces.Description])
    })
  });
  src__core_matchers._Contains = class _Contains extends src__interfaces.Matcher {
    new(expected) {
      this[_expected] = expected;
      super.new();
    }
    matches(item, matchState) {
      if (typeof item == 'string') {
        return dart.notNull(item[dartx.indexOf](core.Pattern._check(this[_expected]))) >= 0;
      } else if (core.Iterable.is(item)) {
        if (src__interfaces.Matcher.is(this[_expected])) {
          return item[dartx.any](dart.fn(e => core.bool._check(dart.dsend(this[_expected], 'matches', e, matchState)), dynamicTobool$()));
        } else {
          return item[dartx.contains](this[_expected]);
        }
      } else if (core.Map.is(item)) {
        return item[dartx.containsKey](this[_expected]);
      }
      return false;
    }
    describe(description) {
      return description.add('contains ').addDescriptionOf(this[_expected]);
    }
    describeMismatch(item, mismatchDescription, matchState, verbose) {
      if (typeof item == 'string' || core.Iterable.is(item) || core.Map.is(item)) {
        return super.describeMismatch(item, mismatchDescription, matchState, verbose);
      } else {
        return mismatchDescription.add('is not a string, map or iterable');
      }
    }
  };
  dart.setSignature(src__core_matchers._Contains, {
    constructors: () => ({new: dart.definiteFunctionType(src__core_matchers._Contains, [dart.dynamic])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__interfaces.Description, [src__interfaces.Description])
    })
  });
  src__core_matchers._In = class _In extends src__interfaces.Matcher {
    new(expected) {
      this[_expected] = expected;
      super.new();
    }
    matches(item, matchState) {
      if (typeof this[_expected] == 'string') {
        return core.bool._check(dart.dsend(dart.dsend(this[_expected], 'indexOf', item), '>=', 0));
      } else if (core.Iterable.is(this[_expected])) {
        return core.bool._check(dart.dsend(this[_expected], 'any', dart.fn(e => dart.equals(e, item), dynamicTobool$())));
      } else if (core.Map.is(this[_expected])) {
        return core.bool._check(dart.dsend(this[_expected], 'containsKey', item));
      }
      return false;
    }
    describe(description) {
      return description.add('is in ').addDescriptionOf(this[_expected]);
    }
  };
  dart.setSignature(src__core_matchers._In, {
    constructors: () => ({new: dart.definiteFunctionType(src__core_matchers._In, [dart.dynamic])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__interfaces.Description, [src__interfaces.Description])
    })
  });
  src__core_matchers._PredicateFunction = dart.typedef('_PredicateFunction', () => dart.functionType(core.bool, [dart.dynamic]));
  const _description = Symbol('_description');
  src__core_matchers._Predicate = class _Predicate extends src__interfaces.Matcher {
    new(matcher, description) {
      this[_matcher] = matcher;
      this[_description] = description;
      super.new();
    }
    matches(item, matchState) {
      return dart.dcall(this[_matcher], item);
    }
    describe(description) {
      return description.add(this[_description]);
    }
  };
  dart.setSignature(src__core_matchers._Predicate, {
    constructors: () => ({new: dart.definiteFunctionType(src__core_matchers._Predicate, [src__core_matchers._PredicateFunction, core.String])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__interfaces.Description, [src__interfaces.Description])
    })
  });
  const _matcher$0 = Symbol('_matcher');
  src__iterable_matchers._IterableMatcher = class _IterableMatcher extends src__interfaces.Matcher {
    new() {
      super.new();
    }
    describeMismatch(item, mismatchDescription, matchState, verbose) {
      if (!core.Iterable.is(item)) {
        return mismatchDescription.addDescriptionOf(item).add(' not an Iterable');
      } else {
        return super.describeMismatch(item, mismatchDescription, matchState, verbose);
      }
    }
  };
  dart.setSignature(src__iterable_matchers._IterableMatcher, {
    constructors: () => ({new: dart.definiteFunctionType(src__iterable_matchers._IterableMatcher, [])})
  });
  src__iterable_matchers._EveryElement = class _EveryElement extends src__iterable_matchers._IterableMatcher {
    new(matcher) {
      this[_matcher$0] = matcher;
      super.new();
    }
    matches(item, matchState) {
      if (!core.Iterable.is(item)) {
        return false;
      }
      let i = 0;
      for (let element of core.Iterable._check(item)) {
        if (!dart.test(this[_matcher$0].matches(element, matchState))) {
          src__util.addStateInfo(matchState, dart.map({index: i, element: element}, core.String, dart.dynamic));
          return false;
        }
        ++i;
      }
      return true;
    }
    describe(description) {
      return description.add('every element(').addDescriptionOf(this[_matcher$0]).add(')');
    }
    describeMismatch(item, mismatchDescription, matchState, verbose) {
      if (matchState[dartx.get]('index') != null) {
        let index = matchState[dartx.get]('index');
        let element = matchState[dartx.get]('element');
        mismatchDescription.add('has value ').addDescriptionOf(element).add(' which ');
        let subDescription = new src__description.StringDescription();
        this[_matcher$0].describeMismatch(element, subDescription, core.Map._check(matchState[dartx.get]('state')), verbose);
        if (dart.notNull(subDescription.length) > 0) {
          mismatchDescription.add(subDescription.toString());
        } else {
          mismatchDescription.add("doesn't match ");
          this[_matcher$0].describe(mismatchDescription);
        }
        mismatchDescription.add(dart.str` at index ${index}`);
        return mismatchDescription;
      }
      return super.describeMismatch(item, mismatchDescription, matchState, verbose);
    }
  };
  dart.setSignature(src__iterable_matchers._EveryElement, {
    constructors: () => ({new: dart.definiteFunctionType(src__iterable_matchers._EveryElement, [src__interfaces.Matcher])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__interfaces.Description, [src__interfaces.Description])
    })
  });
  src__iterable_matchers._AnyElement = class _AnyElement extends src__iterable_matchers._IterableMatcher {
    new(matcher) {
      this[_matcher$0] = matcher;
      super.new();
    }
    matches(item, matchState) {
      return core.bool._check(dart.dsend(item, 'any', dart.fn(e => this[_matcher$0].matches(e, matchState), dynamicTobool$())));
    }
    describe(description) {
      return description.add('some element ').addDescriptionOf(this[_matcher$0]);
    }
  };
  dart.setSignature(src__iterable_matchers._AnyElement, {
    constructors: () => ({new: dart.definiteFunctionType(src__iterable_matchers._AnyElement, [src__interfaces.Matcher])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__interfaces.Description, [src__interfaces.Description])
    })
  });
  const _expected$ = Symbol('_expected');
  src__iterable_matchers._OrderedEquals = class _OrderedEquals extends src__interfaces.Matcher {
    new(expected) {
      this[_expected$] = expected;
      this[_matcher$0] = null;
      super.new();
      this[_matcher$0] = src__core_matchers.equals(this[_expected$], 1);
    }
    matches(item, matchState) {
      return core.Iterable.is(item) && dart.test(this[_matcher$0].matches(item, matchState));
    }
    describe(description) {
      return description.add('equals ').addDescriptionOf(this[_expected$]).add(' ordered');
    }
    describeMismatch(item, mismatchDescription, matchState, verbose) {
      if (!core.Iterable.is(item)) {
        return mismatchDescription.add('is not an Iterable');
      } else {
        return this[_matcher$0].describeMismatch(item, mismatchDescription, matchState, verbose);
      }
    }
  };
  dart.setSignature(src__iterable_matchers._OrderedEquals, {
    constructors: () => ({new: dart.definiteFunctionType(src__iterable_matchers._OrderedEquals, [core.Iterable])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__interfaces.Description, [src__interfaces.Description])
    })
  });
  const _expectedValues = Symbol('_expectedValues');
  const _test = Symbol('_test');
  src__iterable_matchers._UnorderedMatches = class _UnorderedMatches extends src__interfaces.Matcher {
    new(expected) {
      this[_expected$] = expected[dartx.map](src__interfaces.Matcher)(src__util.wrapMatcher)[dartx.toList]();
      super.new();
    }
    [_test](item) {
      if (!core.Iterable.is(item)) return 'not iterable';
      item = dart.dsend(item, 'toList');
      if (dart.notNull(this[_expected$][dartx.length]) > dart.notNull(core.num._check(dart.dload(item, 'length')))) {
        return dart.str`has too few elements (${dart.dload(item, 'length')} < ${this[_expected$][dartx.length]})`;
      } else if (dart.notNull(this[_expected$][dartx.length]) < dart.notNull(core.num._check(dart.dload(item, 'length')))) {
        return dart.str`has too many elements (${dart.dload(item, 'length')} > ${this[_expected$][dartx.length]})`;
      }
      let matched = ListOfbool().filled(core.int._check(dart.dload(item, 'length')), false);
      let expectedPosition = 0;
      for (let expectedMatcher of this[_expected$]) {
        let actualPosition = 0;
        let gotMatch = false;
        for (let actualElement of core.Iterable._check(item)) {
          if (!dart.test(matched[dartx.get](actualPosition))) {
            if (dart.test(expectedMatcher.matches(actualElement, dart.map()))) {
              matched[dartx.set](actualPosition, gotMatch = true);
              break;
            }
          }
          ++actualPosition;
        }
        if (!gotMatch) {
          return dart.toString(new src__description.StringDescription().add('has no match for ').addDescriptionOf(expectedMatcher).add(dart.str` at index ${expectedPosition}`));
        }
        ++expectedPosition;
      }
      return null;
    }
    matches(item, mismatchState) {
      return this[_test](item) == null;
    }
    describe(description) {
      return description.add('matches ').addAll('[', ', ', ']', this[_expected$]).add(' unordered');
    }
    describeMismatch(item, mismatchDescription, matchState, verbose) {
      return mismatchDescription.add(this[_test](item));
    }
  };
  dart.setSignature(src__iterable_matchers._UnorderedMatches, {
    constructors: () => ({new: dart.definiteFunctionType(src__iterable_matchers._UnorderedMatches, [core.Iterable])}),
    methods: () => ({
      [_test]: dart.definiteFunctionType(core.String, [dart.dynamic]),
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__interfaces.Description, [src__interfaces.Description])
    })
  });
  src__iterable_matchers._UnorderedEquals = class _UnorderedEquals extends src__iterable_matchers._UnorderedMatches {
    new(expected) {
      this[_expectedValues] = expected[dartx.toList]();
      super.new(expected[dartx.map](src__interfaces.Matcher)(src__core_matchers.equals));
    }
    describe(description) {
      return description.add('equals ').addDescriptionOf(this[_expectedValues]).add(' unordered');
    }
  };
  dart.setSignature(src__iterable_matchers._UnorderedEquals, {
    constructors: () => ({new: dart.definiteFunctionType(src__iterable_matchers._UnorderedEquals, [core.Iterable])})
  });
  src__iterable_matchers._Comparator = dart.typedef('_Comparator', () => dart.functionType(core.bool, [dart.dynamic, dart.dynamic]));
  const _comparator = Symbol('_comparator');
  const _description$ = Symbol('_description');
  src__iterable_matchers._PairwiseCompare = class _PairwiseCompare extends src__iterable_matchers._IterableMatcher {
    new(expected, comparator, description) {
      this[_expected$] = expected;
      this[_comparator] = comparator;
      this[_description$] = description;
      super.new();
    }
    matches(item, matchState) {
      if (!core.Iterable.is(item)) return false;
      if (!dart.equals(dart.dload(item, 'length'), this[_expected$][dartx.length])) return false;
      let iterator = dart.dload(item, 'iterator');
      let i = 0;
      for (let e of this[_expected$]) {
        dart.dsend(iterator, 'moveNext');
        if (!dart.test(dart.dcall(this[_comparator], e, dart.dload(iterator, 'current')))) {
          src__util.addStateInfo(matchState, dart.map({index: i, expected: e, actual: dart.dload(iterator, 'current')}, core.String, dart.dynamic));
          return false;
        }
        i++;
      }
      return true;
    }
    describe(description) {
      return description.add(dart.str`pairwise ${this[_description$]} `).addDescriptionOf(this[_expected$]);
    }
    describeMismatch(item, mismatchDescription, matchState, verbose) {
      if (!core.Iterable.is(item)) {
        return mismatchDescription.add('is not an Iterable');
      } else if (!dart.equals(dart.dload(item, 'length'), this[_expected$][dartx.length])) {
        return mismatchDescription.add(dart.str`has length ${dart.dload(item, 'length')} instead of ${this[_expected$][dartx.length]}`);
      } else {
        return mismatchDescription.add('has ').addDescriptionOf(matchState[dartx.get]("actual")).add(dart.str` which is not ${this[_description$]} `).addDescriptionOf(matchState[dartx.get]("expected")).add(dart.str` at index ${matchState[dartx.get]("index")}`);
      }
    }
  };
  dart.setSignature(src__iterable_matchers._PairwiseCompare, {
    constructors: () => ({new: dart.definiteFunctionType(src__iterable_matchers._PairwiseCompare, [core.Iterable, src__iterable_matchers._Comparator, core.String])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__interfaces.Description, [src__interfaces.Description])
    })
  });
  const _value$0 = Symbol('_value');
  src__map_matchers._ContainsValue = class _ContainsValue extends src__interfaces.Matcher {
    new(value) {
      this[_value$0] = value;
      super.new();
    }
    matches(item, matchState) {
      return core.bool._check(dart.dsend(item, 'containsValue', this[_value$0]));
    }
    describe(description) {
      return description.add('contains value ').addDescriptionOf(this[_value$0]);
    }
  };
  dart.setSignature(src__map_matchers._ContainsValue, {
    constructors: () => ({new: dart.definiteFunctionType(src__map_matchers._ContainsValue, [dart.dynamic])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__interfaces.Description, [src__interfaces.Description])
    })
  });
  const _key = Symbol('_key');
  const _valueMatcher = Symbol('_valueMatcher');
  src__map_matchers._ContainsMapping = class _ContainsMapping extends src__interfaces.Matcher {
    new(key, valueMatcher) {
      this[_key] = key;
      this[_valueMatcher] = valueMatcher;
      super.new();
    }
    matches(item, matchState) {
      return dart.test(dart.dsend(item, 'containsKey', this[_key])) && dart.test(this[_valueMatcher].matches(dart.dindex(item, this[_key]), matchState));
    }
    describe(description) {
      return description.add('contains pair ').addDescriptionOf(this[_key]).add(' => ').addDescriptionOf(this[_valueMatcher]);
    }
    describeMismatch(item, mismatchDescription, matchState, verbose) {
      if (!dart.test(dart.dsend(item, 'containsKey', this[_key]))) {
        return mismatchDescription.add(" doesn't contain key ").addDescriptionOf(this[_key]);
      } else {
        mismatchDescription.add(' contains key ').addDescriptionOf(this[_key]).add(' but with value ');
        this[_valueMatcher].describeMismatch(dart.dindex(item, this[_key]), mismatchDescription, matchState, verbose);
        return mismatchDescription;
      }
    }
  };
  dart.setSignature(src__map_matchers._ContainsMapping, {
    constructors: () => ({new: dart.definiteFunctionType(src__map_matchers._ContainsMapping, [dart.dynamic, src__interfaces.Matcher])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__interfaces.Description, [src__interfaces.Description])
    })
  });
  src__numeric_matchers._isNumeric = function(value) {
    return typeof value == 'number';
  };
  dart.fn(src__numeric_matchers._isNumeric, dynamicTobool$());
  const _delta = Symbol('_delta');
  src__numeric_matchers._IsCloseTo = class _IsCloseTo extends src__interfaces.Matcher {
    new(value, delta) {
      this[_value] = value;
      this[_delta] = delta;
      super.new();
    }
    matches(item, matchState) {
      if (!dart.test(src__numeric_matchers._isNumeric(item))) {
        return false;
      }
      let diff = dart.dsend(item, '-', this[_value]);
      if (dart.test(dart.dsend(diff, '<', 0))) diff = dart.dsend(diff, 'unary-');
      return core.bool._check(dart.dsend(diff, '<=', this[_delta]));
    }
    describe(description) {
      return description.add('a numeric value within ').addDescriptionOf(this[_delta]).add(' of ').addDescriptionOf(this[_value]);
    }
    describeMismatch(item, mismatchDescription, matchState, verbose) {
      if (!(typeof item == 'number')) {
        return mismatchDescription.add(' not numeric');
      } else {
        let diff = dart.dsend(item, '-', this[_value]);
        if (dart.test(dart.dsend(diff, '<', 0))) diff = dart.dsend(diff, 'unary-');
        return mismatchDescription.add(' differs by ').addDescriptionOf(diff);
      }
    }
  };
  dart.setSignature(src__numeric_matchers._IsCloseTo, {
    constructors: () => ({new: dart.definiteFunctionType(src__numeric_matchers._IsCloseTo, [core.num, core.num])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__interfaces.Description, [src__interfaces.Description])
    })
  });
  const _low = Symbol('_low');
  const _high = Symbol('_high');
  const _lowMatchValue = Symbol('_lowMatchValue');
  const _highMatchValue = Symbol('_highMatchValue');
  src__numeric_matchers._InRange = class _InRange extends src__interfaces.Matcher {
    new(low, high, lowMatchValue, highMatchValue) {
      this[_low] = low;
      this[_high] = high;
      this[_lowMatchValue] = lowMatchValue;
      this[_highMatchValue] = highMatchValue;
      super.new();
    }
    matches(value, matchState) {
      if (!(typeof value == 'number')) {
        return false;
      }
      if (dart.test(dart.dsend(value, '<', this[_low])) || dart.test(dart.dsend(value, '>', this[_high]))) {
        return false;
      }
      if (dart.equals(value, this[_low])) {
        return this[_lowMatchValue];
      }
      if (dart.equals(value, this[_high])) {
        return this[_highMatchValue];
      }
      return true;
    }
    describe(description) {
      return description.add("be in range from " + dart.str`${this[_low]} (${dart.test(this[_lowMatchValue]) ? 'inclusive' : 'exclusive'}) to ` + dart.str`${this[_high]} (${dart.test(this[_highMatchValue]) ? 'inclusive' : 'exclusive'})`);
    }
    describeMismatch(item, mismatchDescription, matchState, verbose) {
      if (!(typeof item == 'number')) {
        return mismatchDescription.addDescriptionOf(item).add(' not numeric');
      } else {
        return super.describeMismatch(item, mismatchDescription, matchState, verbose);
      }
    }
  };
  dart.setSignature(src__numeric_matchers._InRange, {
    constructors: () => ({new: dart.definiteFunctionType(src__numeric_matchers._InRange, [core.num, core.num, core.bool, core.bool])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__interfaces.Description, [src__interfaces.Description])
    })
  });
  const _matcher$1 = Symbol('_matcher');
  src__operator_matchers._IsNot = class _IsNot extends src__interfaces.Matcher {
    new(matcher) {
      this[_matcher$1] = matcher;
      super.new();
    }
    matches(item, matchState) {
      return !dart.test(this[_matcher$1].matches(item, matchState));
    }
    describe(description) {
      return description.add('not ').addDescriptionOf(this[_matcher$1]);
    }
  };
  dart.setSignature(src__operator_matchers._IsNot, {
    constructors: () => ({new: dart.definiteFunctionType(src__operator_matchers._IsNot, [src__interfaces.Matcher])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__interfaces.Description, [src__interfaces.Description])
    })
  });
  const _matchers = Symbol('_matchers');
  src__operator_matchers._AllOf = class _AllOf extends src__interfaces.Matcher {
    new(matchers) {
      this[_matchers] = matchers;
      super.new();
    }
    matches(item, matchState) {
      for (let matcher of this[_matchers]) {
        if (!dart.test(matcher.matches(item, matchState))) {
          src__util.addStateInfo(matchState, dart.map({matcher: matcher}, core.String, src__interfaces.Matcher));
          return false;
        }
      }
      return true;
    }
    describeMismatch(item, mismatchDescription, matchState, verbose) {
      let matcher = matchState[dartx.get]('matcher');
      dart.dsend(matcher, 'describeMismatch', item, mismatchDescription, matchState[dartx.get]('state'), verbose);
      return mismatchDescription;
    }
    describe(description) {
      return description.addAll('(', ' and ', ')', this[_matchers]);
    }
  };
  dart.setSignature(src__operator_matchers._AllOf, {
    constructors: () => ({new: dart.definiteFunctionType(src__operator_matchers._AllOf, [core.List$(src__interfaces.Matcher)])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__interfaces.Description, [src__interfaces.Description])
    })
  });
  src__operator_matchers._AnyOf = class _AnyOf extends src__interfaces.Matcher {
    new(matchers) {
      this[_matchers] = matchers;
      super.new();
    }
    matches(item, matchState) {
      for (let matcher of this[_matchers]) {
        if (dart.test(matcher.matches(item, matchState))) {
          return true;
        }
      }
      return false;
    }
    describe(description) {
      return description.addAll('(', ' or ', ')', this[_matchers]);
    }
  };
  dart.setSignature(src__operator_matchers._AnyOf, {
    constructors: () => ({new: dart.definiteFunctionType(src__operator_matchers._AnyOf, [core.List$(src__interfaces.Matcher)])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__interfaces.Description, [src__interfaces.Description])
    })
  });
  src__operator_matchers._wrapArgs = function(arg0, arg1, arg2, arg3, arg4, arg5, arg6) {
    let args = null;
    if (core.List.is(arg0)) {
      if (arg1 != null || arg2 != null || arg3 != null || arg4 != null || arg5 != null || arg6 != null) {
        dart.throw(new core.ArgumentError('If arg0 is a List, all other arguments must be' + ' null.'));
      }
      args = arg0;
    } else {
      args = [arg0, arg1, arg2, arg3, arg4, arg5, arg6][dartx.where](dart.fn(e => e != null, dynamicTobool$()));
    }
    return args[dartx.map](src__interfaces.Matcher)(dart.fn(e => src__util.wrapMatcher(e), dynamicToMatcher()))[dartx.toList]();
  };
  dart.fn(src__operator_matchers._wrapArgs, dynamicAnddynamicAnddynamic__ToListOfMatcher());
  src__pretty_print.prettyPrint = function(object, opts) {
    let maxLineLength = opts && 'maxLineLength' in opts ? opts.maxLineLength : null;
    let maxItems = opts && 'maxItems' in opts ? opts.maxItems : null;
    function _prettyPrint(object, indent, seen, top) {
      if (src__interfaces.Matcher.is(object)) {
        let description = new src__description.StringDescription();
        object.describe(description);
        return dart.str`<${description}>`;
      }
      if (dart.test(seen.contains(object))) return "(recursive)";
      seen = seen.union(core.Set.from([object]));
      function pp(child) {
        return _prettyPrint(child, dart.notNull(indent) + 2, seen, false);
      }
      dart.fn(pp, dynamicToString());
      if (core.Iterable.is(object)) {
        let type = core.List.is(object) ? "" : dart.notNull(src__pretty_print._typeName(object)) + ":";
        let strings = object[dartx.map](core.String)(pp)[dartx.toList]();
        if (maxItems != null && dart.notNull(strings[dartx.length]) > dart.notNull(maxItems)) {
          strings[dartx.replaceRange](dart.notNull(maxItems) - 1, strings[dartx.length], JSArrayOfString().of(['...']));
        }
        let singleLine = dart.str`${type}[${strings[dartx.join](', ')}]`;
        if ((maxLineLength == null || dart.notNull(singleLine[dartx.length]) + dart.notNull(indent) <= dart.notNull(maxLineLength)) && !dart.test(singleLine[dartx.contains]("\n"))) {
          return singleLine;
        }
        return dart.str`${type}[\n` + dart.notNull(strings[dartx.map](core.String)(dart.fn(string => dart.notNull(src__pretty_print._indent(dart.notNull(indent) + 2)) + dart.notNull(string), StringToString()))[dartx.join](",\n")) + "\n" + dart.notNull(src__pretty_print._indent(indent)) + "]";
      } else if (core.Map.is(object)) {
        let strings = object[dartx.keys][dartx.map](core.String)(dart.fn(key => dart.str`${pp(key)}: ${pp(object[dartx.get](key))}`, dynamicToString()))[dartx.toList]();
        if (maxItems != null && dart.notNull(strings[dartx.length]) > dart.notNull(maxItems)) {
          strings[dartx.replaceRange](dart.notNull(maxItems) - 1, strings[dartx.length], JSArrayOfString().of(['...']));
        }
        let singleLine = dart.str`{${strings[dartx.join](", ")}}`;
        if ((maxLineLength == null || dart.notNull(singleLine[dartx.length]) + dart.notNull(indent) <= dart.notNull(maxLineLength)) && !dart.test(singleLine[dartx.contains]("\n"))) {
          return singleLine;
        }
        return "{\n" + dart.notNull(strings[dartx.map](core.String)(dart.fn(string => dart.notNull(src__pretty_print._indent(dart.notNull(indent) + 2)) + dart.notNull(string), StringToString()))[dartx.join](",\n")) + "\n" + dart.notNull(src__pretty_print._indent(indent)) + "}";
      } else if (typeof object == 'string') {
        let lines = object[dartx.split]("\n");
        return "'" + dart.notNull(lines[dartx.map](core.String)(src__pretty_print._escapeString)[dartx.join](dart.str`\\n'\n${src__pretty_print._indent(dart.notNull(indent) + 2)}'`)) + "'";
      } else {
        let value = dart.toString(object)[dartx.replaceAll]("\n", dart.notNull(src__pretty_print._indent(indent)) + "\n");
        let defaultToString = value[dartx.startsWith]("Instance of ");
        if (dart.test(top)) value = dart.str`<${value}>`;
        if (typeof object == 'number' || typeof object == 'boolean' || core.Function.is(object) || object == null || dart.test(defaultToString)) {
          return value;
        } else {
          return dart.str`${src__pretty_print._typeName(object)}:${value}`;
        }
      }
    }
    dart.fn(_prettyPrint, dynamicAndintAndSet__ToString());
    return _prettyPrint(object, 0, core.Set.new(), true);
  };
  dart.fn(src__pretty_print.prettyPrint, dynamic__ToString());
  src__pretty_print._indent = function(length) {
    return ListOfString().filled(length, ' ')[dartx.join]('');
  };
  dart.fn(src__pretty_print._indent, intToString());
  src__pretty_print._typeName = function(x) {
    try {
      if (x == null) return "null";
      let type = dart.toString(dart.runtimeType(x));
      return dart.test(type[dartx.startsWith]("_")) ? "?" : type;
    } catch (e) {
      return "?";
    }

  };
  dart.fn(src__pretty_print._typeName, dynamicToString());
  src__pretty_print._escapeString = function(source) {
    return src__util.escape(source)[dartx.replaceAll]("'", "\\'");
  };
  dart.fn(src__pretty_print._escapeString, StringToString());
  const _value$1 = Symbol('_value');
  const _matchValue = Symbol('_matchValue');
  src__string_matchers._StringMatcher = class _StringMatcher extends src__interfaces.Matcher {
    new() {
      super.new();
    }
    describeMismatch(item, mismatchDescription, matchState, verbose) {
      if (!(typeof item == 'string')) {
        return mismatchDescription.addDescriptionOf(item).add(' not a string');
      } else {
        return super.describeMismatch(item, mismatchDescription, matchState, verbose);
      }
    }
  };
  dart.setSignature(src__string_matchers._StringMatcher, {
    constructors: () => ({new: dart.definiteFunctionType(src__string_matchers._StringMatcher, [])})
  });
  src__string_matchers._IsEqualIgnoringCase = class _IsEqualIgnoringCase extends src__string_matchers._StringMatcher {
    new(value) {
      this[_value$1] = value;
      this[_matchValue] = value[dartx.toLowerCase]();
      super.new();
    }
    matches(item, matchState) {
      return typeof item == 'string' && this[_matchValue] == item[dartx.toLowerCase]();
    }
    describe(description) {
      return description.addDescriptionOf(this[_value$1]).add(' ignoring case');
    }
  };
  dart.setSignature(src__string_matchers._IsEqualIgnoringCase, {
    constructors: () => ({new: dart.definiteFunctionType(src__string_matchers._IsEqualIgnoringCase, [core.String])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__interfaces.Description, [src__interfaces.Description])
    })
  });
  src__string_matchers._IsEqualIgnoringWhitespace = class _IsEqualIgnoringWhitespace extends src__string_matchers._StringMatcher {
    new(value) {
      this[_value$1] = value;
      this[_matchValue] = src__string_matchers.collapseWhitespace(value);
      super.new();
    }
    matches(item, matchState) {
      return typeof item == 'string' && this[_matchValue] == src__string_matchers.collapseWhitespace(item);
    }
    describe(description) {
      return description.addDescriptionOf(this[_matchValue]).add(' ignoring whitespace');
    }
    describeMismatch(item, mismatchDescription, matchState, verbose) {
      if (typeof item == 'string') {
        return mismatchDescription.add('is ').addDescriptionOf(src__string_matchers.collapseWhitespace(item)).add(' with whitespace compressed');
      } else {
        return super.describeMismatch(item, mismatchDescription, matchState, verbose);
      }
    }
  };
  dart.setSignature(src__string_matchers._IsEqualIgnoringWhitespace, {
    constructors: () => ({new: dart.definiteFunctionType(src__string_matchers._IsEqualIgnoringWhitespace, [core.String])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__interfaces.Description, [src__interfaces.Description])
    })
  });
  const _prefix = Symbol('_prefix');
  src__string_matchers._StringStartsWith = class _StringStartsWith extends src__string_matchers._StringMatcher {
    new(prefix) {
      this[_prefix] = prefix;
      super.new();
    }
    matches(item, matchState) {
      return typeof item == 'string' && dart.test(item[dartx.startsWith](this[_prefix]));
    }
    describe(description) {
      return description.add('a string starting with ').addDescriptionOf(this[_prefix]);
    }
  };
  dart.setSignature(src__string_matchers._StringStartsWith, {
    constructors: () => ({new: dart.definiteFunctionType(src__string_matchers._StringStartsWith, [core.String])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__interfaces.Description, [src__interfaces.Description])
    })
  });
  const _suffix = Symbol('_suffix');
  src__string_matchers._StringEndsWith = class _StringEndsWith extends src__string_matchers._StringMatcher {
    new(suffix) {
      this[_suffix] = suffix;
      super.new();
    }
    matches(item, matchState) {
      return typeof item == 'string' && dart.test(item[dartx.endsWith](this[_suffix]));
    }
    describe(description) {
      return description.add('a string ending with ').addDescriptionOf(this[_suffix]);
    }
  };
  dart.setSignature(src__string_matchers._StringEndsWith, {
    constructors: () => ({new: dart.definiteFunctionType(src__string_matchers._StringEndsWith, [core.String])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__interfaces.Description, [src__interfaces.Description])
    })
  });
  const _substrings = Symbol('_substrings');
  src__string_matchers._StringContainsInOrder = class _StringContainsInOrder extends src__string_matchers._StringMatcher {
    new(substrings) {
      this[_substrings] = substrings;
      super.new();
    }
    matches(item, matchState) {
      if (!(typeof item == 'string')) {
        return false;
      }
      let from_index = 0;
      for (let s of this[_substrings]) {
        from_index = core.int._check(dart.dsend(item, 'indexOf', s, from_index));
        if (dart.notNull(from_index) < 0) return false;
      }
      return true;
    }
    describe(description) {
      return description.addAll('a string containing ', ', ', ' in order', this[_substrings]);
    }
  };
  dart.setSignature(src__string_matchers._StringContainsInOrder, {
    constructors: () => ({new: dart.definiteFunctionType(src__string_matchers._StringContainsInOrder, [core.List$(core.String)])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__interfaces.Description, [src__interfaces.Description])
    })
  });
  const _regexp = Symbol('_regexp');
  src__string_matchers._MatchesRegExp = class _MatchesRegExp extends src__string_matchers._StringMatcher {
    new(re) {
      this[_regexp] = null;
      super.new();
      if (typeof re == 'string') {
        this[_regexp] = core.RegExp.new(re);
      } else if (core.RegExp.is(re)) {
        this[_regexp] = re;
      } else {
        dart.throw(new core.ArgumentError('matches requires a regexp or string'));
      }
    }
    matches(item, matchState) {
      return typeof item == 'string' ? this[_regexp].hasMatch(item) : false;
    }
    describe(description) {
      return description.add(dart.str`match '${this[_regexp].pattern}'`);
    }
  };
  dart.setSignature(src__string_matchers._MatchesRegExp, {
    constructors: () => ({new: dart.definiteFunctionType(src__string_matchers._MatchesRegExp, [dart.dynamic])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__interfaces.Description, [src__interfaces.Description])
    })
  });
  src__string_matchers._isWhitespace = function(ch) {
    return ch == ' ' || ch == '\n' || ch == '\r' || ch == '\t';
  };
  dart.fn(src__string_matchers._isWhitespace, StringTobool());
  src__util._Predicate = dart.typedef('_Predicate', () => dart.functionType(core.bool, [dart.dynamic]));
  src__util._escapeMap = dart.const(dart.map({'\n': '\\n', '\r': '\\r', '\f': '\\f', '\b': '\\b', '\t': '\\t', '\v': '\\v', '': '\\x7F'}, core.String, core.String));
  dart.defineLazy(src__util, {
    get _escapeRegExp() {
      return core.RegExp.new(dart.str`[\\x00-\\x07\\x0E-\\x1F${src__util._escapeMap[dartx.keys][dartx.map](core.String)(src__util._getHexLiteral)[dartx.join]()}]`);
    }
  });
  src__util._getHexLiteral = function(input) {
    let rune = input[dartx.runes].single;
    return '\\x' + dart.notNull(rune[dartx.toRadixString](16)[dartx.toUpperCase]()[dartx.padLeft](2, '0'));
  };
  dart.fn(src__util._getHexLiteral, StringToString());
  // Exports:
  exports.matcher = matcher;
  exports.mirror_matchers = mirror_matchers;
  exports.src__core_matchers = src__core_matchers;
  exports.src__description = src__description;
  exports.src__error_matchers = src__error_matchers;
  exports.src__interfaces = src__interfaces;
  exports.src__iterable_matchers = src__iterable_matchers;
  exports.src__map_matchers = src__map_matchers;
  exports.src__numeric_matchers = src__numeric_matchers;
  exports.src__operator_matchers = src__operator_matchers;
  exports.src__pretty_print = src__pretty_print;
  exports.src__string_matchers = src__string_matchers;
  exports.src__util = src__util;
});
