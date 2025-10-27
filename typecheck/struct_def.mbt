///|
pub(all) struct StructDef {
  name : String
  fields : Array[StructField]
} derive(Show)

///|
pub(all) struct StructField {
  name : String
  ty : Type
} derive(Show)

///|
pub fn StructDef::get_field_type(self : Self, field_name : String) -> Type? {
  for field in self.fields {
    if field.name == field_name {
      return Some(field.ty)
    }
  }
  return None
}

///|
pub fn Context::check_struct_def(
  self : Self,
  struct_def : @parser.StructDef,
) -> StructDef raise TypeCheckError {
  let sd = StructDef::{
    name: struct_def.name,
    fields: struct_def.fields.map(fn(t) {
      StructField::{
        name: t.name,
        ty: self.check_parser_type(t.ty, mutable=t.is_mut),
      }
    }),
  }
  self.struct_defs.set(struct_def.name, sd) // TODO: check here
  sd
}
