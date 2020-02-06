The files in this folder have the following dependencies.
Arrow means depends on, invert arrows for includes.

```
                           Call & CallbackMarshaller
                                       ↓
                           NativeCallingConvention
                             ↓         ↓                (Interop with backend)
                             ↓    NativeLocation     →  Location
(Interop with frontend)      ↓         ↓
AbstractType             ←  NativeType     →  Representation
ClassId                  ←
```

The other files stand on themselves.
