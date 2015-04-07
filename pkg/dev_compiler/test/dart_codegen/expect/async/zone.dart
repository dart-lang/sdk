part of dart.async;
 typedef dynamic ZoneCallback();
 typedef dynamic ZoneUnaryCallback(arg);
 typedef dynamic ZoneBinaryCallback(arg1, arg2);
 typedef dynamic HandleUncaughtErrorHandler(Zone self, ZoneDelegate parent, Zone zone, error, StackTrace stackTrace);
 typedef dynamic RunHandler(Zone self, ZoneDelegate parent, Zone zone, f());
 typedef dynamic RunUnaryHandler(Zone self, ZoneDelegate parent, Zone zone, f(arg), arg);
 typedef dynamic RunBinaryHandler(Zone self, ZoneDelegate parent, Zone zone, f(arg1, arg2), arg1, arg2);
 typedef ZoneCallback RegisterCallbackHandler(Zone self, ZoneDelegate parent, Zone zone, f());
 typedef ZoneUnaryCallback RegisterUnaryCallbackHandler(Zone self, ZoneDelegate parent, Zone zone, f(arg));
 typedef ZoneBinaryCallback RegisterBinaryCallbackHandler(Zone self, ZoneDelegate parent, Zone zone, f(arg1, arg2));
 typedef AsyncError ErrorCallbackHandler(Zone self, ZoneDelegate parent, Zone zone, Object error, StackTrace stackTrace);
 typedef void ScheduleMicrotaskHandler(Zone self, ZoneDelegate parent, Zone zone, f());
 typedef Timer CreateTimerHandler(Zone self, ZoneDelegate parent, Zone zone, Duration duration, void f());
 typedef Timer CreatePeriodicTimerHandler(Zone self, ZoneDelegate parent, Zone zone, Duration period, void f(Timer timer));
 typedef void PrintHandler(Zone self, ZoneDelegate parent, Zone zone, String line);
 typedef Zone ForkHandler(Zone self, ZoneDelegate parent, Zone zone, ZoneSpecification specification, Map zoneValues);
 class AsyncError implements Error {final error;
 final StackTrace stackTrace;
 AsyncError(this.error, this.stackTrace);
 String toString() => error.toString();
}
 class _ZoneFunction {final _Zone zone;
 final Function function;
 const _ZoneFunction(this.zone, this.function);
}
 abstract class ZoneSpecification {const factory ZoneSpecification({
dynamic handleUncaughtError(Zone self, ZoneDelegate parent, Zone zone, error, StackTrace stackTrace), dynamic run(Zone self, ZoneDelegate parent, Zone zone, f()), dynamic runUnary(Zone self, ZoneDelegate parent, Zone zone, f(arg), arg), dynamic runBinary(Zone self, ZoneDelegate parent, Zone zone, f(arg1, arg2), arg1, arg2), ZoneCallback registerCallback(Zone self, ZoneDelegate parent, Zone zone, f()), ZoneUnaryCallback registerUnaryCallback(Zone self, ZoneDelegate parent, Zone zone, f(arg)), ZoneBinaryCallback registerBinaryCallback(Zone self, ZoneDelegate parent, Zone zone, f(arg1, arg2)), AsyncError errorCallback(Zone self, ZoneDelegate parent, Zone zone, Object error, StackTrace stackTrace), void scheduleMicrotask(Zone self, ZoneDelegate parent, Zone zone, f()), Timer createTimer(Zone self, ZoneDelegate parent, Zone zone, Duration duration, void f()), Timer createPeriodicTimer(Zone self, ZoneDelegate parent, Zone zone, Duration period, void f(Timer timer)), void print(Zone self, ZoneDelegate parent, Zone zone, String line), Zone fork(Zone self, ZoneDelegate parent, Zone zone, ZoneSpecification specification, Map zoneValues)}
) = _ZoneSpecification;
 factory ZoneSpecification.from(ZoneSpecification other, {
dynamic handleUncaughtError(Zone self, ZoneDelegate parent, Zone zone, error, StackTrace stackTrace) : null, dynamic run(Zone self, ZoneDelegate parent, Zone zone, f()) : null, dynamic runUnary(Zone self, ZoneDelegate parent, Zone zone, f(arg), arg) : null, dynamic runBinary(Zone self, ZoneDelegate parent, Zone zone, f(arg1, arg2), arg1, arg2) : null, ZoneCallback registerCallback(Zone self, ZoneDelegate parent, Zone zone, f()) : null, ZoneUnaryCallback registerUnaryCallback(Zone self, ZoneDelegate parent, Zone zone, f(arg)) : null, ZoneBinaryCallback registerBinaryCallback(Zone self, ZoneDelegate parent, Zone zone, f(arg1, arg2)) : null, AsyncError errorCallback(Zone self, ZoneDelegate parent, Zone zone, Object error, StackTrace stackTrace), void scheduleMicrotask(Zone self, ZoneDelegate parent, Zone zone, f()) : null, Timer createTimer(Zone self, ZoneDelegate parent, Zone zone, Duration duration, void f()) : null, Timer createPeriodicTimer(Zone self, ZoneDelegate parent, Zone zone, Duration period, void f(Timer timer)) : null, void print(Zone self, ZoneDelegate parent, Zone zone, String line) : null, Zone fork(Zone self, ZoneDelegate parent, Zone zone, ZoneSpecification specification, Map zoneValues) : null}
) {
return new ZoneSpecification(handleUncaughtError: ((__x104) => DEVC$RT.cast(__x104, dynamic, __t98, "CompositeCast", """line 138, column 28 of dart:async/zone.dart: """, __x104 is __t98, false))(handleUncaughtError != null ? handleUncaughtError : other.handleUncaughtError), run: ((__x110) => DEVC$RT.cast(__x110, dynamic, __t105, "CompositeCast", """line 141, column 12 of dart:async/zone.dart: """, __x110 is __t105, false))(run != null ? run : other.run), runUnary: ((__x118) => DEVC$RT.cast(__x118, dynamic, __t111, "CompositeCast", """line 142, column 17 of dart:async/zone.dart: """, __x118 is __t111, false))(runUnary != null ? runUnary : other.runUnary), runBinary: ((__x128) => DEVC$RT.cast(__x128, dynamic, __t119, "CompositeCast", """line 143, column 18 of dart:async/zone.dart: """, __x128 is __t119, false))(runBinary != null ? runBinary : other.runBinary), registerCallback: ((__x135) => DEVC$RT.cast(__x135, dynamic, __t129, "CompositeCast", """line 144, column 25 of dart:async/zone.dart: """, __x135 is __t129, false))(registerCallback != null ? registerCallback : other.registerCallback), registerUnaryCallback: ((__x144) => DEVC$RT.cast(__x144, dynamic, __t136, "CompositeCast", """line 147, column 30 of dart:async/zone.dart: """, __x144 is __t136, false))(registerUnaryCallback != null ? registerUnaryCallback : other.registerUnaryCallback), registerBinaryCallback: ((__x155) => DEVC$RT.cast(__x155, dynamic, __t145, "CompositeCast", """line 150, column 31 of dart:async/zone.dart: """, __x155 is __t145, false))(registerBinaryCallback != null ? registerBinaryCallback : other.registerBinaryCallback), errorCallback: ((__x162) => DEVC$RT.cast(__x162, dynamic, __t156, "CompositeCast", """line 153, column 22 of dart:async/zone.dart: """, __x162 is __t156, false))(errorCallback != null ? errorCallback : other.errorCallback), scheduleMicrotask: ((__x168) => DEVC$RT.cast(__x168, dynamic, __t163, "CompositeCast", """line 156, column 26 of dart:async/zone.dart: """, __x168 is __t163, false))(scheduleMicrotask != null ? scheduleMicrotask : other.scheduleMicrotask), createTimer: ((__x175) => DEVC$RT.cast(__x175, dynamic, __t169, "CompositeCast", """line 159, column 21 of dart:async/zone.dart: """, __x175 is __t169, false))(createTimer != null ? createTimer : other.createTimer), createPeriodicTimer: ((__x183) => DEVC$RT.cast(__x183, dynamic, __t176, "CompositeCast", """line 160, column 28 of dart:async/zone.dart: """, __x183 is __t176, false))(createPeriodicTimer != null ? createPeriodicTimer : other.createPeriodicTimer), print: ((__x189) => DEVC$RT.cast(__x189, dynamic, __t184, "CompositeCast", """line 163, column 15 of dart:async/zone.dart: """, __x189 is __t184, false))(print != null ? print : other.print), fork: ((__x196) => DEVC$RT.cast(__x196, dynamic, __t190, "CompositeCast", """line 164, column 13 of dart:async/zone.dart: """, __x196 is __t190, false))(fork != null ? fork : other.fork));
}
 HandleUncaughtErrorHandler get handleUncaughtError;
 RunHandler get run;
 RunUnaryHandler get runUnary;
 RunBinaryHandler get runBinary;
 RegisterCallbackHandler get registerCallback;
 RegisterUnaryCallbackHandler get registerUnaryCallback;
 RegisterBinaryCallbackHandler get registerBinaryCallback;
 ErrorCallbackHandler get errorCallback;
 ScheduleMicrotaskHandler get scheduleMicrotask;
 CreateTimerHandler get createTimer;
 CreatePeriodicTimerHandler get createPeriodicTimer;
 PrintHandler get print;
 ForkHandler get fork;
}
 class _ZoneSpecification implements ZoneSpecification {const _ZoneSpecification({
this.handleUncaughtError : null, this.run : null, this.runUnary : null, this.runBinary : null, this.registerCallback : null, this.registerUnaryCallback : null, this.registerBinaryCallback : null, this.errorCallback : null, this.scheduleMicrotask : null, this.createTimer : null, this.createPeriodicTimer : null, this.print : null, this.fork : null}
);
 final handleUncaughtError;
 final run;
 final runUnary;
 final runBinary;
 final registerCallback;
 final registerUnaryCallback;
 final registerBinaryCallback;
 final errorCallback;
 final scheduleMicrotask;
 final createTimer;
 final createPeriodicTimer;
 final print;
 final fork;
}
 abstract class ZoneDelegate {dynamic handleUncaughtError(Zone zone, error, StackTrace stackTrace);
 dynamic run(Zone zone, f());
 dynamic runUnary(Zone zone, f(arg), arg);
 dynamic runBinary(Zone zone, f(arg1, arg2), arg1, arg2);
 ZoneCallback registerCallback(Zone zone, f());
 ZoneUnaryCallback registerUnaryCallback(Zone zone, f(arg));
 ZoneBinaryCallback registerBinaryCallback(Zone zone, f(arg1, arg2));
 AsyncError errorCallback(Zone zone, Object error, StackTrace stackTrace);
 void scheduleMicrotask(Zone zone, f());
 Timer createTimer(Zone zone, Duration duration, void f());
 Timer createPeriodicTimer(Zone zone, Duration period, void f(Timer timer));
 void print(Zone zone, String line);
 Zone fork(Zone zone, ZoneSpecification specification, Map zoneValues);
}
 abstract class Zone {Zone._();
 static const Zone ROOT = _ROOT_ZONE;
 static Zone _current = _ROOT_ZONE;
 static Zone get current => _current;
 dynamic handleUncaughtError(error, StackTrace stackTrace);
 Zone get parent;
 Zone get errorZone;
 bool inSameErrorZone(Zone otherZone);
 Zone fork({
ZoneSpecification specification, Map zoneValues}
);
 dynamic run(f());
 dynamic runUnary(f(arg), var arg);
 dynamic runBinary(f(arg1, arg2), var arg1, var arg2);
 dynamic runGuarded(f());
 dynamic runUnaryGuarded(f(arg), var arg);
 dynamic runBinaryGuarded(f(arg1, arg2), var arg1, var arg2);
 ZoneCallback registerCallback(callback());
 ZoneUnaryCallback registerUnaryCallback(callback(arg));
 ZoneBinaryCallback registerBinaryCallback(callback(arg1, arg2));
 ZoneCallback bindCallback(f(), {
bool runGuarded : true}
);
 ZoneUnaryCallback bindUnaryCallback(f(arg), {
bool runGuarded : true}
);
 ZoneBinaryCallback bindBinaryCallback(f(arg1, arg2), {
bool runGuarded : true}
);
 AsyncError errorCallback(Object error, StackTrace stackTrace);
 void scheduleMicrotask(void f());
 Timer createTimer(Duration duration, void callback());
 Timer createPeriodicTimer(Duration period, void callback(Timer timer));
 void print(String line);
 static Zone _enter(Zone zone) {
assert (zone != null); assert (!identical(zone, _current)); Zone previous = _current;
 _current = zone;
 return previous;
}
 static void _leave(Zone previous) {
assert (previous != null); Zone._current = previous;
}
 operator [](Object key);
}
 ZoneDelegate _parentDelegate(_Zone zone) {
if (zone.parent == null) return null;
 return zone.parent._delegate;
}
 class _ZoneDelegate implements ZoneDelegate {final _Zone _delegationTarget;
 _ZoneDelegate(this._delegationTarget);
 dynamic handleUncaughtError(Zone zone, error, StackTrace stackTrace) {
_ZoneFunction implementation = _delegationTarget._handleUncaughtError;
 _Zone implZone = implementation.zone;
 return (implementation.function)(implZone, _parentDelegate(implZone), zone, error, stackTrace);
}
 dynamic run(Zone zone, f()) {
_ZoneFunction implementation = _delegationTarget._run;
 _Zone implZone = implementation.zone;
 return (implementation.function)(implZone, _parentDelegate(implZone), zone, f);
}
 dynamic runUnary(Zone zone, f(arg), arg) {
_ZoneFunction implementation = _delegationTarget._runUnary;
 _Zone implZone = implementation.zone;
 return (implementation.function)(implZone, _parentDelegate(implZone), zone, f, arg);
}
 dynamic runBinary(Zone zone, f(arg1, arg2), arg1, arg2) {
_ZoneFunction implementation = _delegationTarget._runBinary;
 _Zone implZone = implementation.zone;
 return (implementation.function)(implZone, _parentDelegate(implZone), zone, f, arg1, arg2);
}
 ZoneCallback registerCallback(Zone zone, f()) {
_ZoneFunction implementation = _delegationTarget._registerCallback;
 _Zone implZone = implementation.zone;
 return ((__x197) => DEVC$RT.cast(__x197, dynamic, __t134, "DynamicCast", """line 522, column 12 of dart:async/zone.dart: """, __x197 is __t134, true))((implementation.function)(implZone, _parentDelegate(implZone), zone, f));
}
 ZoneUnaryCallback registerUnaryCallback(Zone zone, f(arg)) {
_ZoneFunction implementation = _delegationTarget._registerUnaryCallback;
 _Zone implZone = implementation.zone;
 return ((__x198) => DEVC$RT.cast(__x198, dynamic, __t142, "DynamicCast", """line 529, column 12 of dart:async/zone.dart: """, __x198 is __t142, true))((implementation.function)(implZone, _parentDelegate(implZone), zone, f));
}
 ZoneBinaryCallback registerBinaryCallback(Zone zone, f(arg1, arg2)) {
_ZoneFunction implementation = _delegationTarget._registerBinaryCallback;
 _Zone implZone = implementation.zone;
 return ((__x199) => DEVC$RT.cast(__x199, dynamic, __t152, "DynamicCast", """line 536, column 12 of dart:async/zone.dart: """, __x199 is __t152, true))((implementation.function)(implZone, _parentDelegate(implZone), zone, f));
}
 AsyncError errorCallback(Zone zone, Object error, StackTrace stackTrace) {
_ZoneFunction implementation = _delegationTarget._errorCallback;
 _Zone implZone = implementation.zone;
 if (identical(implZone, _ROOT_ZONE)) return null;
 return ((__x200) => DEVC$RT.cast(__x200, dynamic, AsyncError, "DynamicCast", """line 544, column 12 of dart:async/zone.dart: """, __x200 is AsyncError, true))((implementation.function)(implZone, _parentDelegate(implZone), zone, error, stackTrace));
}
 void scheduleMicrotask(Zone zone, f()) {
_ZoneFunction implementation = _delegationTarget._scheduleMicrotask;
 _Zone implZone = implementation.zone;
 (implementation.function)(implZone, _parentDelegate(implZone), zone, f);
}
 Timer createTimer(Zone zone, Duration duration, void f()) {
_ZoneFunction implementation = _delegationTarget._createTimer;
 _Zone implZone = implementation.zone;
 return ((__x201) => DEVC$RT.cast(__x201, dynamic, Timer, "DynamicCast", """line 558, column 12 of dart:async/zone.dart: """, __x201 is Timer, true))((implementation.function)(implZone, _parentDelegate(implZone), zone, duration, f));
}
 Timer createPeriodicTimer(Zone zone, Duration period, void f(Timer timer)) {
_ZoneFunction implementation = _delegationTarget._createPeriodicTimer;
 _Zone implZone = implementation.zone;
 return ((__x202) => DEVC$RT.cast(__x202, dynamic, Timer, "DynamicCast", """line 565, column 12 of dart:async/zone.dart: """, __x202 is Timer, true))((implementation.function)(implZone, _parentDelegate(implZone), zone, period, f));
}
 void print(Zone zone, String line) {
_ZoneFunction implementation = _delegationTarget._print;
 _Zone implZone = implementation.zone;
 (implementation.function)(implZone, _parentDelegate(implZone), zone, line);
}
 Zone fork(Zone zone, ZoneSpecification specification, Map zoneValues) {
_ZoneFunction implementation = _delegationTarget._fork;
 _Zone implZone = implementation.zone;
 return ((__x203) => DEVC$RT.cast(__x203, dynamic, Zone, "DynamicCast", """line 580, column 12 of dart:async/zone.dart: """, __x203 is Zone, true))((implementation.function)(implZone, _parentDelegate(implZone), zone, specification, zoneValues));
}
}
 abstract class _Zone implements Zone {const _Zone();
 _ZoneFunction get _runUnary;
 _ZoneFunction get _run;
 _ZoneFunction get _runBinary;
 _ZoneFunction get _registerCallback;
 _ZoneFunction get _registerUnaryCallback;
 _ZoneFunction get _registerBinaryCallback;
 _ZoneFunction get _errorCallback;
 _ZoneFunction get _scheduleMicrotask;
 _ZoneFunction get _createTimer;
 _ZoneFunction get _createPeriodicTimer;
 _ZoneFunction get _print;
 _ZoneFunction get _fork;
 _ZoneFunction get _handleUncaughtError;
 _Zone get parent;
 _ZoneDelegate get _delegate;
 Map get _map;
 bool inSameErrorZone(Zone otherZone) {
return identical(this, otherZone) || identical(errorZone, otherZone.errorZone);
}
}
 class _CustomZone extends _Zone {_ZoneFunction _runUnary;
 _ZoneFunction _run;
 _ZoneFunction _runBinary;
 _ZoneFunction _registerCallback;
 _ZoneFunction _registerUnaryCallback;
 _ZoneFunction _registerBinaryCallback;
 _ZoneFunction _errorCallback;
 _ZoneFunction _scheduleMicrotask;
 _ZoneFunction _createTimer;
 _ZoneFunction _createPeriodicTimer;
 _ZoneFunction _print;
 _ZoneFunction _fork;
 _ZoneFunction _handleUncaughtError;
 ZoneDelegate _delegateCache;
 final _Zone parent;
 final Map _map;
 ZoneDelegate get _delegate {
if (_delegateCache != null) return _delegateCache;
 _delegateCache = new _ZoneDelegate(this);
 return _delegateCache;
}
 _CustomZone(this.parent, ZoneSpecification specification, this._map) {
_run = (specification.run != null) ? new _ZoneFunction(this, specification.run) : parent._run;
 _runUnary = (specification.runUnary != null) ? new _ZoneFunction(this, specification.runUnary) : parent._runUnary;
 _runBinary = (specification.runBinary != null) ? new _ZoneFunction(this, specification.runBinary) : parent._runBinary;
 _registerCallback = (specification.registerCallback != null) ? new _ZoneFunction(this, specification.registerCallback) : parent._registerCallback;
 _registerUnaryCallback = (specification.registerUnaryCallback != null) ? new _ZoneFunction(this, specification.registerUnaryCallback) : parent._registerUnaryCallback;
 _registerBinaryCallback = (specification.registerBinaryCallback != null) ? new _ZoneFunction(this, specification.registerBinaryCallback) : parent._registerBinaryCallback;
 _errorCallback = (specification.errorCallback != null) ? new _ZoneFunction(this, specification.errorCallback) : parent._errorCallback;
 _scheduleMicrotask = (specification.scheduleMicrotask != null) ? new _ZoneFunction(this, specification.scheduleMicrotask) : parent._scheduleMicrotask;
 _createTimer = (specification.createTimer != null) ? new _ZoneFunction(this, specification.createTimer) : parent._createTimer;
 _createPeriodicTimer = (specification.createPeriodicTimer != null) ? new _ZoneFunction(this, specification.createPeriodicTimer) : parent._createPeriodicTimer;
 _print = (specification.print != null) ? new _ZoneFunction(this, specification.print) : parent._print;
 _fork = (specification.fork != null) ? new _ZoneFunction(this, specification.fork) : parent._fork;
 _handleUncaughtError = (specification.handleUncaughtError != null) ? new _ZoneFunction(this, specification.handleUncaughtError) : parent._handleUncaughtError;
}
 Zone get errorZone => _handleUncaughtError.zone;
 dynamic runGuarded(f()) {
try {
return run(f);
}
 catch (e, s) {
return handleUncaughtError(e, s);
}
}
 dynamic runUnaryGuarded(f(arg), arg) {
try {
return runUnary(f, arg);
}
 catch (e, s) {
return handleUncaughtError(e, s);
}
}
 dynamic runBinaryGuarded(f(arg1, arg2), arg1, arg2) {
try {
return runBinary(f, arg1, arg2);
}
 catch (e, s) {
return handleUncaughtError(e, s);
}
}
 ZoneCallback bindCallback(f(), {
bool runGuarded : true}
) {
ZoneCallback registered = registerCallback(f);
 if (runGuarded) {
return () => this.runGuarded(registered);
}
 else {
return () => this.run(registered);
}
}
 ZoneUnaryCallback bindUnaryCallback(f(arg), {
bool runGuarded : true}
) {
ZoneUnaryCallback registered = registerUnaryCallback(f);
 if (runGuarded) {
return (arg) => this.runUnaryGuarded(registered, arg);
}
 else {
return (arg) => this.runUnary(registered, arg);
}
}
 ZoneBinaryCallback bindBinaryCallback(f(arg1, arg2), {
bool runGuarded : true}
) {
ZoneBinaryCallback registered = registerBinaryCallback(f);
 if (runGuarded) {
return (arg1, arg2) => this.runBinaryGuarded(registered, arg1, arg2);
}
 else {
return (arg1, arg2) => this.runBinary(registered, arg1, arg2);
}
}
 operator [](Object key) {
var result = _map[key];
 if (result != null || _map.containsKey(key)) return result;
 if (parent != null) {
var value = parent[key];
 if (value != null) {
_map[key] = value;
}
 return value;
}
 assert (this == _ROOT_ZONE); return null;
}
 dynamic handleUncaughtError(error, StackTrace stackTrace) {
_ZoneFunction implementation = this._handleUncaughtError;
 assert (implementation != null); ZoneDelegate parentDelegate = _parentDelegate(implementation.zone);
 return (implementation.function)(implementation.zone, parentDelegate, this, error, stackTrace);
}
 Zone fork({
ZoneSpecification specification, Map zoneValues}
) {
_ZoneFunction implementation = this._fork;
 assert (implementation != null); ZoneDelegate parentDelegate = _parentDelegate(implementation.zone);
 return ((__x204) => DEVC$RT.cast(__x204, dynamic, Zone, "DynamicCast", """line 787, column 12 of dart:async/zone.dart: """, __x204 is Zone, true))((implementation.function)(implementation.zone, parentDelegate, this, specification, zoneValues));
}
 dynamic run(f()) {
_ZoneFunction implementation = this._run;
 assert (implementation != null); ZoneDelegate parentDelegate = _parentDelegate(implementation.zone);
 return (implementation.function)(implementation.zone, parentDelegate, this, f);
}
 dynamic runUnary(f(arg), arg) {
_ZoneFunction implementation = this._runUnary;
 assert (implementation != null); ZoneDelegate parentDelegate = _parentDelegate(implementation.zone);
 return (implementation.function)(implementation.zone, parentDelegate, this, f, arg);
}
 dynamic runBinary(f(arg1, arg2), arg1, arg2) {
_ZoneFunction implementation = this._runBinary;
 assert (implementation != null); ZoneDelegate parentDelegate = _parentDelegate(implementation.zone);
 return (implementation.function)(implementation.zone, parentDelegate, this, f, arg1, arg2);
}
 ZoneCallback registerCallback(f()) {
_ZoneFunction implementation = this._registerCallback;
 assert (implementation != null); ZoneDelegate parentDelegate = _parentDelegate(implementation.zone);
 return ((__x205) => DEVC$RT.cast(__x205, dynamic, __t134, "DynamicCast", """line 820, column 12 of dart:async/zone.dart: """, __x205 is __t134, true))((implementation.function)(implementation.zone, parentDelegate, this, f));
}
 ZoneUnaryCallback registerUnaryCallback(f(arg)) {
_ZoneFunction implementation = this._registerUnaryCallback;
 assert (implementation != null); ZoneDelegate parentDelegate = _parentDelegate(implementation.zone);
 return ((__x206) => DEVC$RT.cast(__x206, dynamic, __t142, "DynamicCast", """line 828, column 12 of dart:async/zone.dart: """, __x206 is __t142, true))((implementation.function)(implementation.zone, parentDelegate, this, f));
}
 ZoneBinaryCallback registerBinaryCallback(f(arg1, arg2)) {
_ZoneFunction implementation = this._registerBinaryCallback;
 assert (implementation != null); ZoneDelegate parentDelegate = _parentDelegate(implementation.zone);
 return ((__x207) => DEVC$RT.cast(__x207, dynamic, __t152, "DynamicCast", """line 836, column 12 of dart:async/zone.dart: """, __x207 is __t152, true))((implementation.function)(implementation.zone, parentDelegate, this, f));
}
 AsyncError errorCallback(Object error, StackTrace stackTrace) {
final _ZoneFunction implementation = this._errorCallback;
 assert (implementation != null); final Zone implementationZone = implementation.zone;
 if (identical(implementationZone, _ROOT_ZONE)) return null;
 final ZoneDelegate parentDelegate = _parentDelegate(DEVC$RT.cast(implementationZone, Zone, _Zone, "ImplicitCast", """line 845, column 57 of dart:async/zone.dart: """, implementationZone is _Zone, true));
 return ((__x208) => DEVC$RT.cast(__x208, dynamic, AsyncError, "DynamicCast", """line 846, column 12 of dart:async/zone.dart: """, __x208 is AsyncError, true))((implementation.function)(implementationZone, parentDelegate, this, error, stackTrace));
}
 void scheduleMicrotask(void f()) {
_ZoneFunction implementation = this._scheduleMicrotask;
 assert (implementation != null); ZoneDelegate parentDelegate = _parentDelegate(implementation.zone);
 return (implementation.function)(implementation.zone, parentDelegate, this, f);
}
 Timer createTimer(Duration duration, void f()) {
_ZoneFunction implementation = this._createTimer;
 assert (implementation != null); ZoneDelegate parentDelegate = _parentDelegate(implementation.zone);
 return ((__x209) => DEVC$RT.cast(__x209, dynamic, Timer, "DynamicCast", """line 862, column 12 of dart:async/zone.dart: """, __x209 is Timer, true))((implementation.function)(implementation.zone, parentDelegate, this, duration, f));
}
 Timer createPeriodicTimer(Duration duration, void f(Timer timer)) {
_ZoneFunction implementation = this._createPeriodicTimer;
 assert (implementation != null); ZoneDelegate parentDelegate = _parentDelegate(implementation.zone);
 return ((__x210) => DEVC$RT.cast(__x210, dynamic, Timer, "DynamicCast", """line 870, column 12 of dart:async/zone.dart: """, __x210 is Timer, true))((implementation.function)(implementation.zone, parentDelegate, this, duration, f));
}
 void print(String line) {
_ZoneFunction implementation = this._print;
 assert (implementation != null); ZoneDelegate parentDelegate = _parentDelegate(implementation.zone);
 return (implementation.function)(implementation.zone, parentDelegate, this, line);
}
}
 void _rootHandleUncaughtError(Zone self, ZoneDelegate parent, Zone zone, error, StackTrace stackTrace) {
_schedulePriorityAsyncCallback(() {
throw new _UncaughtAsyncError(error, stackTrace);
}
);
}
 dynamic _rootRun(Zone self, ZoneDelegate parent, Zone zone, f()) {
if (Zone._current == zone) return f();
 Zone old = Zone._enter(zone);
 try {
return f();
}
 finally {
Zone._leave(old);
}
}
 dynamic _rootRunUnary(Zone self, ZoneDelegate parent, Zone zone, f(arg), arg) {
if (Zone._current == zone) return f(arg);
 Zone old = Zone._enter(zone);
 try {
return f(arg);
}
 finally {
Zone._leave(old);
}
}
 dynamic _rootRunBinary(Zone self, ZoneDelegate parent, Zone zone, f(arg1, arg2), arg1, arg2) {
if (Zone._current == zone) return f(arg1, arg2);
 Zone old = Zone._enter(zone);
 try {
return f(arg1, arg2);
}
 finally {
Zone._leave(old);
}
}
 ZoneCallback _rootRegisterCallback(Zone self, ZoneDelegate parent, Zone zone, f()) {
return f;
}
 ZoneUnaryCallback _rootRegisterUnaryCallback(Zone self, ZoneDelegate parent, Zone zone, f(arg)) {
return f;
}
 ZoneBinaryCallback _rootRegisterBinaryCallback(Zone self, ZoneDelegate parent, Zone zone, f(arg1, arg2)) {
return f;
}
 AsyncError _rootErrorCallback(Zone self, ZoneDelegate parent, Zone zone, Object error, StackTrace stackTrace) => null;
 void _rootScheduleMicrotask(Zone self, ZoneDelegate parent, Zone zone, f()) {
if (!identical(_ROOT_ZONE, zone)) {
bool hasErrorHandler = !_ROOT_ZONE.inSameErrorZone(zone);
 f = zone.bindCallback(f, runGuarded: hasErrorHandler);
}
 _scheduleAsyncCallback(f);
}
 Timer _rootCreateTimer(Zone self, ZoneDelegate parent, Zone zone, Duration duration, void callback()) {
if (!identical(_ROOT_ZONE, zone)) {
callback = zone.bindCallback(callback);
}
 return Timer._createTimer(duration, callback);
}
 Timer _rootCreatePeriodicTimer(Zone self, ZoneDelegate parent, Zone zone, Duration duration, void callback(Timer timer)) {
if (!identical(_ROOT_ZONE, zone)) {
callback = ((__x213) => DEVC$RT.cast(__x213, __t142, __t211, "CompositeCast", """line 962, column 16 of dart:async/zone.dart: """, __x213 is __t211, false))(zone.bindUnaryCallback(callback));
}
 return Timer._createPeriodicTimer(duration, callback);
}
 void _rootPrint(Zone self, ZoneDelegate parent, Zone zone, String line) {
printToConsole(line);
}
 void _printToZone(String line) {
Zone.current.print(line);
}
 Zone _rootFork(Zone self, ZoneDelegate parent, Zone zone, ZoneSpecification specification, Map zoneValues) {
printToZone = _printToZone;
 if (specification == null) {
specification = const ZoneSpecification();
}
 else if (specification is! _ZoneSpecification) {
throw new ArgumentError("ZoneSpecifications must be instantiated" " with the provided constructor.");
}
 Map valueMap;
 if (zoneValues == null) {
if (zone is _Zone) {
valueMap = zone._map;
}
 else {
valueMap = new HashMap();
}
}
 else {
valueMap = new HashMap.from(zoneValues);
}
 return new _CustomZone(DEVC$RT.cast(zone, Zone, _Zone, "ImplicitCast", """line 999, column 26 of dart:async/zone.dart: """, zone is _Zone, true), specification, valueMap);
}
 class _RootZoneSpecification implements ZoneSpecification {HandleUncaughtErrorHandler get handleUncaughtError => _rootHandleUncaughtError;
 RunHandler get run => _rootRun;
 RunUnaryHandler get runUnary => _rootRunUnary;
 RunBinaryHandler get runBinary => _rootRunBinary;
 RegisterCallbackHandler get registerCallback => _rootRegisterCallback;
 RegisterUnaryCallbackHandler get registerUnaryCallback => _rootRegisterUnaryCallback;
 RegisterBinaryCallbackHandler get registerBinaryCallback => _rootRegisterBinaryCallback;
 ErrorCallbackHandler get errorCallback => _rootErrorCallback;
 ScheduleMicrotaskHandler get scheduleMicrotask => _rootScheduleMicrotask;
 CreateTimerHandler get createTimer => _rootCreateTimer;
 CreatePeriodicTimerHandler get createPeriodicTimer => _rootCreatePeriodicTimer;
 PrintHandler get print => _rootPrint;
 ForkHandler get fork => _rootFork;
}
 class _RootZone extends _Zone {const _RootZone();
 _ZoneFunction get _run => const _ZoneFunction(_ROOT_ZONE, _rootRun);
 _ZoneFunction get _runUnary => const _ZoneFunction(_ROOT_ZONE, _rootRunUnary);
 _ZoneFunction get _runBinary => const _ZoneFunction(_ROOT_ZONE, _rootRunBinary);
 _ZoneFunction get _registerCallback => const _ZoneFunction(_ROOT_ZONE, _rootRegisterCallback);
 _ZoneFunction get _registerUnaryCallback => const _ZoneFunction(_ROOT_ZONE, _rootRegisterUnaryCallback);
 _ZoneFunction get _registerBinaryCallback => const _ZoneFunction(_ROOT_ZONE, _rootRegisterBinaryCallback);
 _ZoneFunction get _errorCallback => const _ZoneFunction(_ROOT_ZONE, _rootErrorCallback);
 _ZoneFunction get _scheduleMicrotask => const _ZoneFunction(_ROOT_ZONE, _rootScheduleMicrotask);
 _ZoneFunction get _createTimer => const _ZoneFunction(_ROOT_ZONE, _rootCreateTimer);
 _ZoneFunction get _createPeriodicTimer => const _ZoneFunction(_ROOT_ZONE, _rootCreatePeriodicTimer);
 _ZoneFunction get _print => const _ZoneFunction(_ROOT_ZONE, _rootPrint);
 _ZoneFunction get _fork => const _ZoneFunction(_ROOT_ZONE, _rootFork);
 _ZoneFunction get _handleUncaughtError => const _ZoneFunction(_ROOT_ZONE, _rootHandleUncaughtError);
 _Zone get parent => null;
 Map get _map => _rootMap;
 static Map _rootMap = new HashMap();
 static ZoneDelegate _rootDelegate;
 ZoneDelegate get _delegate {
if (_rootDelegate != null) return _rootDelegate;
 return _rootDelegate = new _ZoneDelegate(this);
}
 Zone get errorZone => this;
 dynamic runGuarded(f()) {
try {
if (identical(_ROOT_ZONE, Zone._current)) {
return f();
}
 return _rootRun(null, null, this, f);
}
 catch (e, s) {
return handleUncaughtError(e, s);
}
}
 dynamic runUnaryGuarded(f(arg), arg) {
try {
if (identical(_ROOT_ZONE, Zone._current)) {
return f(arg);
}
 return _rootRunUnary(null, null, this, f, arg);
}
 catch (e, s) {
return handleUncaughtError(e, s);
}
}
 dynamic runBinaryGuarded(f(arg1, arg2), arg1, arg2) {
try {
if (identical(_ROOT_ZONE, Zone._current)) {
return f(arg1, arg2);
}
 return _rootRunBinary(null, null, this, f, arg1, arg2);
}
 catch (e, s) {
return handleUncaughtError(e, s);
}
}
 ZoneCallback bindCallback(f(), {
bool runGuarded : true}
) {
if (runGuarded) {
return () => this.runGuarded(f);
}
 else {
return () => this.run(f);
}
}
 ZoneUnaryCallback bindUnaryCallback(f(arg), {
bool runGuarded : true}
) {
if (runGuarded) {
return (arg) => this.runUnaryGuarded(f, arg);
}
 else {
return (arg) => this.runUnary(f, arg);
}
}
 ZoneBinaryCallback bindBinaryCallback(f(arg1, arg2), {
bool runGuarded : true}
) {
if (runGuarded) {
return (arg1, arg2) => this.runBinaryGuarded(f, arg1, arg2);
}
 else {
return (arg1, arg2) => this.runBinary(f, arg1, arg2);
}
}
 operator [](Object key) => null;
 dynamic handleUncaughtError(error, StackTrace stackTrace) {
return _rootHandleUncaughtError(null, null, this, error, stackTrace);
}
 Zone fork({
ZoneSpecification specification, Map zoneValues}
) {
return _rootFork(null, null, this, specification, zoneValues);
}
 dynamic run(f()) {
if (identical(Zone._current, _ROOT_ZONE)) return f();
 return _rootRun(null, null, this, f);
}
 dynamic runUnary(f(arg), arg) {
if (identical(Zone._current, _ROOT_ZONE)) return f(arg);
 return _rootRunUnary(null, null, this, f, arg);
}
 dynamic runBinary(f(arg1, arg2), arg1, arg2) {
if (identical(Zone._current, _ROOT_ZONE)) return f(arg1, arg2);
 return _rootRunBinary(null, null, this, f, arg1, arg2);
}
 ZoneCallback registerCallback(f()) => f;
 ZoneUnaryCallback registerUnaryCallback(f(arg)) => f;
 ZoneBinaryCallback registerBinaryCallback(f(arg1, arg2)) => f;
 AsyncError errorCallback(Object error, StackTrace stackTrace) => null;
 void scheduleMicrotask(void f()) {
_rootScheduleMicrotask(null, null, this, f);
}
 Timer createTimer(Duration duration, void f()) {
return Timer._createTimer(duration, f);
}
 Timer createPeriodicTimer(Duration duration, void f(Timer timer)) {
return Timer._createPeriodicTimer(duration, f);
}
 void print(String line) {
printToConsole(line);
}
}
 const _ROOT_ZONE = const _RootZone();
 dynamic runZoned(body(), {
Map zoneValues, ZoneSpecification zoneSpecification, Function onError}
) {
HandleUncaughtErrorHandler errorHandler;
 if (onError != null) {
errorHandler = (Zone self, ZoneDelegate parent, Zone zone, error, StackTrace stackTrace) {
try {
if (onError is ZoneBinaryCallback) {
return self.parent.runBinary(onError, error, stackTrace);
}
 return self.parent.runUnary(DEVC$RT.cast(onError, Function, __t142, "ImplicitCast", """line 1228, column 37 of dart:async/zone.dart: """, onError is __t142, true), error);
}
 catch (e, s) {
if (identical(e, error)) {
return parent.handleUncaughtError(zone, error, stackTrace);
}
 else {
return parent.handleUncaughtError(zone, e, s);
}
}
}
;
}
 if (zoneSpecification == null) {
zoneSpecification = new ZoneSpecification(handleUncaughtError: errorHandler);
}
 else if (errorHandler != null) {
zoneSpecification = new ZoneSpecification.from(zoneSpecification, handleUncaughtError: errorHandler);
}
 Zone zone = Zone.current.fork(specification: zoneSpecification, zoneValues: zoneValues);
 if (onError != null) {
return zone.runGuarded(body);
}
 else {
return zone.run(body);
}
}
 typedef dynamic __t98(Zone __u99, ZoneDelegate __u100, Zone __u101, dynamic __u102, StackTrace __u103);
 typedef dynamic __t105(Zone __u106, ZoneDelegate __u107, Zone __u108, dynamic __u109());
 typedef dynamic __t111(Zone __u112, ZoneDelegate __u113, Zone __u114, dynamic __u115(dynamic __u116), dynamic __u117);
 typedef dynamic __t119(Zone __u120, ZoneDelegate __u121, Zone __u122, dynamic __u123(dynamic __u124, dynamic __u125), dynamic __u126, dynamic __u127);
 typedef dynamic __t134();
 typedef __t134 __t129(Zone __u130, ZoneDelegate __u131, Zone __u132, dynamic __u133());
 typedef dynamic __t142(dynamic __u143);
 typedef __t142 __t136(Zone __u137, ZoneDelegate __u138, Zone __u139, dynamic __u140(dynamic __u141));
 typedef dynamic __t152(dynamic __u153, dynamic __u154);
 typedef __t152 __t145(Zone __u146, ZoneDelegate __u147, Zone __u148, dynamic __u149(dynamic __u150, dynamic __u151));
 typedef AsyncError __t156(Zone __u157, ZoneDelegate __u158, Zone __u159, Object __u160, StackTrace __u161);
 typedef void __t163(Zone __u164, ZoneDelegate __u165, Zone __u166, dynamic __u167());
 typedef Timer __t169(Zone __u170, ZoneDelegate __u171, Zone __u172, Duration __u173, void __u174());
 typedef Timer __t176(Zone __u177, ZoneDelegate __u178, Zone __u179, Duration __u180, void __u181(Timer __u182));
 typedef void __t184(Zone __u185, ZoneDelegate __u186, Zone __u187, String __u188);
 typedef Zone __t190(Zone __u191, ZoneDelegate __u192, Zone __u193, ZoneSpecification __u194, Map<dynamic, dynamic> __u195);
 typedef void __t211(Timer __u212);
