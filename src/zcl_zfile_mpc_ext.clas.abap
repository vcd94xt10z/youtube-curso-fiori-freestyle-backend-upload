class ZCL_ZFILE_MPC_EXT definition
  public
  inheriting from ZCL_ZFILE_MPC
  create public .

public section.

  methods DEFINE
    redefinition .
protected section.
private section.
ENDCLASS.



CLASS ZCL_ZFILE_MPC_EXT IMPLEMENTATION.


method DEFINE.
  DATA: obj_entity_type TYPE REF TO /iwbep/if_mgw_odata_entity_typ,
          obj_property    TYPE REF TO /iwbep/if_mgw_odata_property.

  super->define( ).
  obj_entity_type = model->get_entity_type( iv_entity_name = 'File' ).

  IF obj_entity_type IS BOUND.
    obj_property = obj_entity_type->get_property( iv_property_name = 'Fileid' ).
    obj_property->set_as_content_type( ).
  ENDIF.
endmethod.
ENDCLASS.
