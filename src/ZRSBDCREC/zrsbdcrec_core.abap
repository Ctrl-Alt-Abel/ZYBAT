*&---------------------------------------------------------------------*
*&  Include           ZRSBDCREC_CORE
*&---------------------------------------------------------------------*

* start-of-selection ***************************************************
START-OF-SELECTION.
* get records *********************************************************
  CALL FUNCTION 'BDC_OBJECT_READ'
    EXPORTING
      queue_id         = qid
    TABLES
      dynprotab        = dynprotab
    EXCEPTIONS
      not_found        = 1
      system_failure   = 2
      invalid_datatype = 3
      OTHERS           = 4.
  IF sy-subrc >< 0.
    MESSAGE s627 WITH qid. EXIT.
  ENDIF.
* create file with testdata *******************************************
  IF testdata = 'X'.
*   fill internal table to determine structure of record
    PERFORM fill_dynpro_fields.
*   create testfile
    PERFORM create_testfile.
    IF sy-subrc = 0.
      MESSAGE s610 WITH dsn.
    ENDIF.
  ENDIF.
* generate source lines of report *************************************
  IF report = space.
    STOP.
  ENDIF.
* same lines for all records ------------------------------------------
* ***report <report>
  CLEAR source.
  source = '*----------------------------------------------------------------------*'.
  append_clear_src.
  source = '** This file is generated by ZYBAT'.
  append_clear_src.
  source = '** (Pretty Printer Advised)'.
  append_clear_src.
  source = '** USE AT YOUR OWN RISK'.
  append_clear_src.
  source = '*----------------------------------------------------------------------*'.
  append_clear_src.
  APPEND source.
  CONCATENATE 'report'
              report
              INTO source SEPARATED BY space.
  append_clear_src.
  source =    '       no standard page heading line-size 255.'.
  append_clear_src.   append_clear_src.
  source =    'DATA: bdcdata LIKE bdcdata OCCURS 0 WITH HEADER LINE.'.
  append_clear_src.
  source =    'DATA: gi_count TYPE i VALUE 1,'.
  append_clear_src.
  source =    'gc_count TYPE c,'.
  append_clear_src.
  source =    'g_string TYPE string.'.
  append_clear_src.
  source = '*----------------------------------------------------------------------*'.
  append_clear_src.
  source-line1 = '*&      Form  RECORDING'.
  append_clear_src.
  source = '*----------------------------------------------------------------------*'.
  append_clear_src.
  source-line1 = 'FORM RECORDING.'.
  append_clear_src.
  LOOP AT dynprotab.
    CASE dynprotab-dynbegin.
*     new transaction -------------------------------------------------
      WHEN 'T'.
*       store transaction AFTER getting field values!
        IF NOT tcode IS INITIAL.
*         ***perform bdc_transaction using dynprotab-fnam.
          source-line1 = 'perform bdc_transaction using'.
          CONCATENATE ''''
                      tcode
                      '''.'
                      INTO source-line2.
          append_clear_src.   append_clear_src.
        ENDIF.
*       save tcode for next transaction
        tcode = dynprotab-fnam.
*     new dynpro ------------------------------------------------------
      WHEN 'X'.
*       ***perform bdc_dynpro using dynprotab-program dynprotab-dynpro.
        source-line1 = 'perform bdc_dynpro      using'.
        CONCATENATE ''''
                    dynprotab-program
                    ''''
                    ' '''
                    dynprotab-dynpro
                    '''.'
                    INTO source-line2.
        append_clear_src.
*     dynpro field ----------------------------------------------------
      WHEN space.
*       ***perform bdc_field using <dynprotab-fnam> <dynprotab-fval>.
        CHECK dynprotab-fnam <> 'BDC_SUBSCR'.
        source-line1 = 'perform bdc_field       using'.
        CONCATENATE ''''
                    dynprotab-fnam
                    ''''
                    INTO source-line2.
        append_clear_src.
*       source line for read from dataset
        IF file = 'X'.
*         * ...records-<field>
          PERFORM source_line_for_var_field.
*       source line for read from records
        ELSE.
*         * ...<dynprotab-fval>
          PERFORM source_line_for_field_content USING dynprotab-fval.
        ENDIF.
    ENDCASE.
  ENDLOOP.
  IF file = 'X'.
*   ***enddo.
    source = 'enddo.'.
    append_clear_src.   append_clear_src.
  ENDIF.
  source = 'gi_count = gi_count + 1.'. append_clear_src.
  source = 'gc_count = gi_count.'. append_clear_src.
  tmp = pa_lines.
  CONCATENATE 'IF gi_count = ' tmp '.' INTO source SEPARATED BY space.
  append_clear_src.
  source = 'PERFORM bdc_field       USING ''BDC_OKCODE'''. append_clear_src.
  source = '                              ''=P+''.'. append_clear_src.
  source = 'ENDIF.'.  append_clear_src.
  source-line1 = 'ENDFORM.'.
  append_clear_src.
  source = '*----------------------------------------------------------------------*'.
  append_clear_src.
  source = '*        Start new screen                                              *'.
  append_clear_src.
  source = '*----------------------------------------------------------------------*'.
  append_clear_src.
  source = 'FORM BDC_DYNPRO USING PROGRAM DYNPRO.'.
  append_clear_src.
  source = 'CLEAR BDCDATA.'.
  append_clear_src.
  source = 'BDCDATA-PROGRAM  = PROGRAM.'.
  append_clear_src.
  source = 'BDCDATA-DYNPRO   = DYNPRO.'.
  append_clear_src.
  source = 'BDCDATA-DYNBEGIN = ''X''.'.
  append_clear_src.
  source = 'APPEND BDCDATA.'.
  append_clear_src.
  source = 'ENDFORM.'.
  append_clear_src.
  source = '*----------------------------------------------------------------------*'.
  append_clear_src.
  source = '*        Insert field                                                  *'.
  append_clear_src.
  source = '*----------------------------------------------------------------------*'.
  append_clear_src.
  source = 'FORM bdc_field USING fnam fval.'.
  append_clear_src.
  source-line1 = 'IF fval <> space.'.
  append_clear_src.
  source-line1 = 'CLEAR bdcdata.'.
  append_clear_src.
  source-line1 = 'bdcdata-fnam = fnam.'.
  append_clear_src.
  source-line1 = 'bdcdata-fval = fval.'.
  append_clear_src.
  source-line1 = 'APPEND bdcdata.'.
  append_clear_src.
  source-line1 = 'ENDIF.'.
  append_clear_src.
  source-line1 = 'ENDFORM.                    '.
  source-line2 = '"BDC_FIELD'.
  append_clear_src.
* scan src for user input fields****************************************
  PERFORM scan_src CHANGING source[].
* insert scanned data to source[]****************************************
  PERFORM insert_scan_source.
* insert read file program logic to source[]*****************************
  PERFORM insert_pgm_src.
* insert report *******************************************************
  INSERT REPORT report FROM source.
* insert selection texts **********************************************
* texts for generated report in textpool of this report
  READ TEXTPOOL sy-repid INTO text_tab LANGUAGE sy-langu.
  IF sy-subrc = 0.
*   delete texts that belong to this report
    DELETE text_tab WHERE id >< 'S' AND id >< 'I'.
    DELETE text_tab WHERE id  = 'S' AND key >< 'DATASET'.
*   insert title of actual report
    READ TEXTPOOL report INTO text_tab_2 LANGUAGE sy-langu.
    text_tab_2-id = 'R'.
    READ TABLE text_tab_2 WITH KEY id = 'R'.
    MOVE-CORRESPONDING text_tab_2 TO text_tab.
    APPEND text_tab.
*   insert textpool from text_tab
    INSERT TEXTPOOL report FROM text_tab.
  ENDIF.
* actualize EU-tree ***************************************************
  CONCATENATE 'PG_'
              report
              INTO tree_name.
  CALL FUNCTION 'WB_TREE_ACTUALIZE'
    EXPORTING
      tree_name = tree_name.
* success message *****************************************************
  MESSAGE s609 WITH report.