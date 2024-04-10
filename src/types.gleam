import gleam/list
import gleam/int
import gleam/string

//
// General
pub type UniqueId =
  String

//
// Primitive

pub type Primitive {
  PrimitiveVoid
  PrimitiveBoolean
  PrimitiveSignedInteger(Int)
  PrimitiveUnsignedInteger(Int)
}

pub fn primitive_satisfies(s: Primitive, o: Primitive) -> Bool {
  s == o
}

pub fn primitive_debug(s: Primitive) -> String {
  case s {
    PrimitiveVoid -> "void"
    PrimitiveBoolean -> "bool"
    PrimitiveSignedInteger(bits) -> "i" <> int.to_string(bits)
    PrimitiveUnsignedInteger(bits) -> "u" <> int.to_string(bits)
  }
}

//
// Function

pub type FunctionArgument {
  FunctionArgument(name: String, typ: Type)
}

pub fn function_argument_satisfies(
  s: FunctionArgument,
  o: FunctionArgument,
) -> Bool {
  case s, o {
    FunctionArgument(_, contravariant_s), FunctionArgument(_, contravariant_o) ->
      type_satisfies(contravariant_o, contravariant_s)
  }
}

pub fn function_argument_debug(s: FunctionArgument) -> String {
  case s {
    FunctionArgument(name, typ) -> name <> ": " <> type_debug(typ)
  }
}

pub type Function {
  Function(arguments: List(FunctionArgument), return: Type)
}

pub fn function_satisfies(s: Function, o: Function) -> Bool {
  case s, o {
    Function(args_s, ret_s), Function(args_o, ret_o) ->
      type_satisfies(ret_s, ret_o)
      && // don't allow arity mismatch
      list.length(args_s) == list.length(args_o)
      && list.zip(args_s, args_o)
      |> list.all(fn(p) { function_argument_satisfies(p.0, p.1) })
  }
}

pub fn function_debug(s: Function) -> String {
  case s {
    Function(args, ret) ->
      "fn("
      <> args
      |> list.map(function_argument_debug)
      |> string.join(", ")
      <> "): "
      <> type_debug(ret)
  }
}

//
// Trait

pub type Trait {
  Trait(id: UniqueId, extends: List(Trait))
}

pub fn trait_debug(s: Trait) -> String {
  case s {
    Trait(id, extends) ->
      "trait "
      <> id
      <> case extends {
        [] -> ""
        _ ->
          " extends "
          <> extends
          |> list.map(fn(s) { s.id })
          |> string.join(", ")
      }
  }
}

pub fn trait_satisfies(subject: Trait, other: Trait) -> Bool {
  subject == other
  || subject.extends
  |> list.contains(other)
  || subject.extends
  |> list.any(trait_satisfies(_, other))
}

//
// Struct
pub type StructField {
  StructField(name: String, typ: Type)
}

pub fn struct_field_debug(s: StructField) -> String {
  case s {
    StructField(name, typ) -> name <> ": " <> type_debug(typ)
  }
}

pub type Struct {
  Struct(id: UniqueId, fields: List(StructField))
}

pub fn struct_satisfies(subject: Struct, other: Struct) -> Bool {
  subject == other
}

pub fn struct_debug(s: Struct) -> String {
  case s {
    Struct(id, fields) ->
      "struct "
      <> id
      <> " {"
      <> fields
      |> list.map(struct_field_debug)
      |> list.map(fn(s) { " " <> s })
      |> string.join(";")
      <> " }"
  }
}

//
// Enum
pub type EnumField {
  EnumField(name: String, typ: Type)
}

pub fn enum_field_debug(s: EnumField) -> String {
  case s {
    EnumField(name, typ) -> name <> ": " <> type_debug(typ)
  }
}

pub type EnumVariant {
  EnumVariantPlain(name: String)
  EnumVariantValues(name: String, data: List(Type))
  EnumVariantFields(name: String, fields: List(EnumField))
}

pub fn enum_variant_debug(s: EnumVariant) -> String {
  case s {
    EnumVariantPlain(name) -> name
    EnumVariantValues(name, data) ->
      name
      <> "("
      <> data
      |> list.map(type_debug)
      |> string.join(", ")
      <> ")"
    EnumVariantFields(name, fields) ->
      name
      <> " {"
      <> fields
      |> list.map(enum_field_debug)
      |> list.map(fn(s) { " " <> s })
      |> string.join(";")
      <> " }"
  }
}

pub type Enum {
  Enum(id: UniqueId, variants: List(EnumVariant))
}

pub fn enum_satisfies(subject: Enum, other: Enum) -> Bool {
  subject == other
}

pub fn enum_debug(s: Enum) {
  case s {
    Enum(id, variants) ->
      "enum "
      <> id
      <> " {"
      <> variants
      |> list.map(enum_variant_debug)
      |> list.map(fn(s) { " " <> s })
      |> string.join(";")
      <> " }"
  }
}

//
// Type

pub type Type {
  TypeNever
  TypePrimitive(Primitive)
  TypeFunction(Function)
  TypeTrait(Trait)
  TypeStruct(Struct)
  TypeEnum(Enum)
}

fn type_debug(s: Type) -> String {
  case s {
    TypeNever -> "never"
    TypePrimitive(p) -> primitive_debug(p)
    TypeTrait(t) -> trait_debug(t)
    TypeFunction(f) -> function_debug(f)
    TypeStruct(s) -> struct_debug(s)
    TypeEnum(e) -> enum_debug(e)
  }
}

pub fn type_satisfies(subject: Type, other: Type) -> Bool {
  case subject, other {
    _, _ if subject == other -> True

    TypeNever, _ -> True

    TypePrimitive(s), TypePrimitive(t) -> primitive_satisfies(s, t)
    TypeFunction(s), TypeFunction(t) -> function_satisfies(s, t)
    TypeTrait(s), TypeTrait(t) -> trait_satisfies(s, t)
    TypeStruct(s), TypeStruct(t) -> struct_satisfies(s, t)
    TypeEnum(s), TypeEnum(t) -> enum_satisfies(s, t)

    _, _ -> False
  }
}
