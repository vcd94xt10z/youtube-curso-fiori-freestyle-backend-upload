class ZCL_ZFILE_DPC_EXT definition
  public
  inheriting from ZCL_ZFILE_DPC
  create public .

public section.

  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~CREATE_STREAM
    redefinition .
  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~DELETE_STREAM
    redefinition .
  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~UPDATE_STREAM
    redefinition .
  methods /IWBEP/IF_MGW_CORE_SRV_RUNTIME~READ_STREAM
    redefinition .
protected section.

  methods FILESET_DELETE_ENTITY
    redefinition .
  methods FILESET_GET_ENTITYSET
    redefinition .
  methods FILESET_UPDATE_ENTITY
    redefinition .
  methods FILESET_GET_ENTITY
    redefinition .
private section.
ENDCLASS.



CLASS ZCL_ZFILE_DPC_EXT IMPLEMENTATION.


method /IWBEP/IF_MGW_APPL_SRV_RUNTIME~CREATE_STREAM.
  DATA: ld_fileid  TYPE zfile-fileid.
  DATA: ls_file    TYPE zfile.

  DATA(lo_msg) = me->/iwbep/if_mgw_conv_srv_runtime~get_message_container( ).

  IF iv_slug = ''.
    lo_msg->add_message_text_only(
      EXPORTING
        iv_msg_type = 'E'
        iv_msg_text = 'Slug não informado no cabeçalho'
    ).

    RAISE EXCEPTION type /iwbep/cx_mgw_busi_exception
      EXPORTING
        message_container = lo_msg.
  ENDIF.

  CLEAR ld_fileid.

  SELECT MAX( fileid )
    INTO ld_fileid
    FROM zfile.

  CLEAR ls_file.
  ls_file-fileid   = ld_fileid + 1.
  ls_file-filename = iv_slug.
  ls_file-filesize = xstrlen( is_media_resource-value ).
  ls_file-erdat    = sy-datum.
  ls_file-erzet    = sy-uzeit.
  ls_file-ernam    = sy-uname.
  ls_file-mimetype = is_media_resource-mime_type.
  ls_file-content  = is_media_resource-value.
  INSERT zfile FROM ls_file.

  copy_data_to_ref(
    EXPORTING
      is_data = ls_file
    CHANGING
      cr_data = er_entity
  ).
endmethod.


method /IWBEP/IF_MGW_APPL_SRV_RUNTIME~DELETE_STREAM.
  DATA: ls_key_tab LIKE LINE OF it_key_tab.

  DATA(lo_msg) = me->/iwbep/if_mgw_conv_srv_runtime~get_message_container( ).

  READ TABLE it_key_tab INTO ls_key_tab WITH KEY name = 'Fileid'.
  IF sy-subrc <> 0.
    lo_msg->add_message_text_only(
      EXPORTING
        iv_msg_type = 'E'
        iv_msg_text = 'Id não informado'
    ).

    RAISE EXCEPTION type /iwbep/cx_mgw_busi_exception
      EXPORTING
        message_container = lo_msg.
  ENDIF.

  SELECT COUNT(*)
    FROM zfile
   WHERE fileid = ls_key_tab-value.

  IF sy-subrc <> 0.
    lo_msg->add_message_text_only(
      EXPORTING
        iv_msg_type = 'E'
        iv_msg_text = 'Id não encontrado'
    ).

    RAISE EXCEPTION type /iwbep/cx_mgw_busi_exception
      EXPORTING
        message_container = lo_msg.
  ENDIF.

  DELETE FROM zfile
   WHERE fileid = ls_key_tab-value.
endmethod.


method /IWBEP/IF_MGW_APPL_SRV_RUNTIME~UPDATE_STREAM.
  DATA: ls_zfile   TYPE zfile.
  DATA: ls_key_tab TYPE /iwbep/s_mgw_name_value_pair.
  DATA: ls_header  TYPE ihttpnvp.
  DATA: ls_stream  TYPE ty_s_media_resource.

  DATA(lo_msg) = me->/iwbep/if_mgw_conv_srv_runtime~get_message_container( ).

  READ TABLE it_key_tab INTO ls_key_tab WITH KEY name = 'Fileid'.
  IF sy-subrc <> 0.
    lo_msg->add_message_text_only(
      EXPORTING
        iv_msg_type = 'E'
        iv_msg_text = 'Id não informado'
    ).

    RAISE EXCEPTION type /iwbep/cx_mgw_busi_exception
      EXPORTING
        message_container = lo_msg.
  ENDIF.

  " process
  CLEAR ls_zfile.

  SELECT SINGLE *
    INTO ls_zfile
    FROM zfile
   WHERE fileid = ls_key_tab-value.

  IF sy-subrc <> 0.
    lo_msg->add_message_text_only(
      EXPORTING
        iv_msg_type = 'E'
        iv_msg_text = 'Id não encontrado'
    ).

    RAISE EXCEPTION type /iwbep/cx_mgw_busi_exception
      EXPORTING
        message_container = lo_msg.
  ENDIF.

  ls_zfile-filesize = xstrlen( is_media_resource-value ).
  ls_zfile-mimetype = is_media_resource-mime_type.
  ls_zfile-content  = is_media_resource-value.
  MODIFY zfile FROM ls_zfile.
endmethod.


method /IWBEP/IF_MGW_CORE_SRV_RUNTIME~READ_STREAM.
  DATA: ls_zfile   TYPE zfile.
  DATA: ls_key_tab TYPE /iwbep/s_mgw_name_value_pair.
  DATA: ls_header  TYPE ihttpnvp.
  DATA: ls_stream  TYPE ty_s_media_resource.

  DATA(lo_msg) = me->/iwbep/if_mgw_conv_srv_runtime~get_message_container( ).

  READ TABLE is_request_details-key_tab INTO ls_key_tab WITH KEY name = 'Fileid'.
  IF sy-subrc <> 0.
    lo_msg->add_message_text_only(
      EXPORTING
        iv_msg_type = 'E'
        iv_msg_text = 'Id não informado'
    ).

    RAISE EXCEPTION type /iwbep/cx_mgw_busi_exception
      EXPORTING
        message_container = lo_msg.
  ENDIF.

  " process
  CLEAR ls_zfile.

  SELECT SINGLE *
    INTO ls_zfile
    FROM zfile
   WHERE fileid = ls_key_tab-value.

  IF sy-subrc <> 0.
    lo_msg->add_message_text_only(
      EXPORTING
        iv_msg_type = 'E'
        iv_msg_text = 'Id não encontrado'
    ).

    RAISE EXCEPTION type /iwbep/cx_mgw_busi_exception
      EXPORTING
        message_container = lo_msg.
  ENDIF.

  " output
  CLEAR ls_header.
  ls_header-name = 'content-disposition'.
  ls_header-value = 'outline; filename="' && ls_zfile-filename && '.pdf"'.
  set_header( ls_header ).

  ls_stream-value     = ls_zfile-content.
  ls_stream-mime_type = ls_zfile-mimetype.

  copy_data_to_ref(
    exporting
      is_data = ls_stream
    changing
      cr_data = cr_stream
  ).
endmethod.


method FILESET_DELETE_ENTITY.
  DATA: ls_key_tab LIKE LINE OF it_key_tab.

  DATA(lo_msg) = me->/iwbep/if_mgw_conv_srv_runtime~get_message_container( ).

  READ TABLE it_key_tab INTO ls_key_tab WITH KEY name = 'Fileid'.
  IF sy-subrc <> 0.
    lo_msg->add_message_text_only(
      EXPORTING
        iv_msg_type = 'E'
        iv_msg_text = 'Id não informado'
    ).

    RAISE EXCEPTION type /iwbep/cx_mgw_busi_exception
      EXPORTING
        message_container = lo_msg.
  ENDIF.

  SELECT COUNT(*)
    FROM zfile
   WHERE fileid = ls_key_tab-value.

  IF sy-subrc <> 0.
    lo_msg->add_message_text_only(
      EXPORTING
        iv_msg_type = 'E'
        iv_msg_text = 'Id não encontrado'
    ).

    RAISE EXCEPTION type /iwbep/cx_mgw_busi_exception
      EXPORTING
        message_container = lo_msg.
  ENDIF.

  DELETE FROM zfile
   WHERE fileid = ls_key_tab-value.
endmethod.


method FILESET_GET_ENTITY.
  DATA: ls_zfile   TYPE zfile.
  DATA: ls_key_tab LIKE LINE OF it_key_tab.

  DATA(lo_msg) = me->/iwbep/if_mgw_conv_srv_runtime~get_message_container( ).

  READ TABLE it_key_tab INTO ls_key_tab WITH KEY name = 'Fileid'.
  IF sy-subrc <> 0.
    lo_msg->add_message_text_only(
      EXPORTING
        iv_msg_type = 'E'
        iv_msg_text = 'Id não informado'
    ).

    RAISE EXCEPTION type /iwbep/cx_mgw_busi_exception
      EXPORTING
        message_container = lo_msg.
  ENDIF.

  SELECT SINGLE *
    INTO ls_zfile
    FROM zfile
   WHERE fileid = ls_key_tab-value.

  IF sy-subrc <> 0.
    lo_msg->add_message_text_only(
      EXPORTING
        iv_msg_type = 'E'
        iv_msg_text = 'Id não encontrado'
    ).

    RAISE EXCEPTION type /iwbep/cx_mgw_busi_exception
      EXPORTING
        message_container = lo_msg.
  ENDIF.

  MOVE-CORRESPONDING ls_zfile TO er_entity.
endmethod.


method FILESET_GET_ENTITYSET.
  DATA: lt_zfile     TYPE STANDARD TABLE OF zfile.
  DATA: ls_zfile     TYPE zfile.
  DATA: ls_entityset LIKE LINE OF et_entityset.

  DATA(lo_msg) = me->/iwbep/if_mgw_conv_srv_runtime~get_message_container( ).

  CLEAR lt_zfile.

  SELECT *
    INTO TABLE lt_zfile
    FROM zfile.

  LOOP AT lt_zfile INTO ls_zfile.
    MOVE-CORRESPONDING ls_zfile TO ls_entityset.
    APPEND ls_entityset TO et_entityset.
  ENDLOOP.
endmethod.


method FILESET_UPDATE_ENTITY.
  DATA: ls_zfile   TYPE zfile.
  DATA: ls_key_tab LIKE LINE OF it_key_tab.

  DATA(lo_msg) = me->/iwbep/if_mgw_conv_srv_runtime~get_message_container( ).

  READ TABLE it_key_tab INTO ls_key_tab WITH KEY name = 'Fileid'.
  IF sy-subrc <> 0.
    lo_msg->add_message_text_only(
      EXPORTING
        iv_msg_type = 'E'
        iv_msg_text = 'Id não informado'
    ).

    RAISE EXCEPTION type /iwbep/cx_mgw_busi_exception
      EXPORTING
        message_container = lo_msg.
  ENDIF.

  SELECT SINGLE *
    INTO ls_zfile
    FROM zfile
   WHERE fileid = ls_key_tab-value.

  IF sy-subrc <> 0.
    lo_msg->add_message_text_only(
      EXPORTING
        iv_msg_type = 'E'
        iv_msg_text = 'Id não encontrado'
    ).

    RAISE EXCEPTION type /iwbep/cx_mgw_busi_exception
      EXPORTING
        message_container = lo_msg.
  ENDIF.

  io_data_provider->read_entry_data(
    IMPORTING
      es_data = er_entity
  ).

  ls_zfile-filename = er_entity-filename.
  MODIFY zfile FROM ls_zfile.
endmethod.
ENDCLASS.
