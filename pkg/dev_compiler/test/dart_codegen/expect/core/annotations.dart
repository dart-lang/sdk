part of dart.core;
 class JsName {final String name;
 const JsName({
  this.name}
);
}
 class JsPeerInterface {final String name;
 const JsPeerInterface({
this.name}
);
}
 class SupportJsExtensionMethod {const SupportJsExtensionMethod();
}
 class Deprecated {final String expires;
 const Deprecated(String expires) : this.expires = expires;
 String toString() => "Deprecated feature. Will be removed $expires";
}
 class _Override {const _Override();
}
 const Deprecated deprecated = const Deprecated("next release");
 const Object override = const _Override();
 class _Proxy {const _Proxy();
}
 const Object proxy = const _Proxy();
