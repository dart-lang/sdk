# Sort members

The sort members command is used to sort both top-level and member declarations.

The sort order is based on four criteria:

- The kind of the declaration.
- Whether the declaration is static.
- The visibility of the declaration.
- The name of the declaration.

The order of the kinds is influenced by the `sort_constructors_first` lint. When
the lint is enabled, constructors will be sorted before other members. When the
lint isn't enabled, fields will be sorted first, with constructors following.

## Field declarations

When a field declaration declares more than one field, for sorting purposes, the
name of the first field is used. For example, given the field declaration

```dart
int x, y, z;
```

The declaration will be sorted using the name `x`.

## Primary constructor bodies

A primary constructor body is placed in its own group, and that group always
sorts immediately before in-body constructors.
