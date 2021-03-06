CLASS ltcl_json_encode DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    DATA: cut               TYPE REF TO zcl_json_encoder_decoder,
          element_generator TYPE REF TO zcl_json_config_generator.

    METHODS:
      setup,

      check_scenario
        IMPORTING
          val TYPE any
          exp TYPE string,

      get_type_title
        IMPORTING
          val           TYPE any
        RETURNING
          VALUE(result) TYPE string.

    METHODS:
      simple_values                     FOR TESTING,
      boolean_values                    FOR TESTING,
      struct_simple_names               FOR TESTING,
      struct_complex_names_camelcase    FOR TESTING,
      struct_complex_names              FOR TESTING,
      struct_name_subsequent_capital    FOR TESTING,
      struct_keeping_empty_values       FOR TESTING,
      struct_empty                      FOR TESTING,
      struct_with_table_attribute       FOR TESTING,
      internal_table                    FOR TESTING,
      empty_internal_table              FOR TESTING,
      required_object_field             FOR TESTING,
      required_array_field              FOR TESTING,
      non_required_object_field         FOR TESTING,
      non_required_array_field          FOR TESTING,
      escaping_characters               FOR TESTING,
      keep_blank_spaces                 FOR TESTING.

ENDCLASS.


CLASS ltcl_json_encode IMPLEMENTATION.

  METHOD setup.
    cut = NEW #( ).
    element_generator = NEW #( ).
  ENDMETHOD.

  METHOD simple_values.

    DATA: value_string          TYPE string,
          value_char            TYPE char1,
          value_int             TYPE i,
          value_date            TYPE sy-datum,
          value_time            TYPE sy-uzeit,
          value_timestamp       TYPE timestamp,
          value_float           TYPE decfloat16,
          value_negative_float  TYPE decfloat16,
          value_conversion_exit TYPE matnr.

    value_string            = 'test'.
    value_char              = 'a'.
    value_int               = 10.
    value_date              = '20191023'.
    value_time              = '112200'.
    value_timestamp         = '20191023145508'.
    value_float             = '10.0203'.
    value_negative_float    = '10.0203-'.
    value_conversion_exit   = '000000000000000018'.

    "Without name
    check_scenario( val = value_string          exp = '"test"' ).
    check_scenario( val = value_char            exp = '"a"' ).
    check_scenario( val = value_int             exp = '10' ).
    check_scenario( val = value_float           exp = '10.0203' ).
    check_scenario( val = value_negative_float  exp = '-10.0203' ).
    check_scenario( val = value_conversion_exit exp = '"18"' ).
    check_scenario( val = value_date            exp = '"2019-10-23"' ).
    check_scenario( val = value_time            exp = '"11:22:00"' ).
    check_scenario( val = value_timestamp       exp = '"2019-10-23T14:55:08"' ).

    "Empty values
    FREE: value_string,
          value_int,
          value_conversion_exit,
          value_date,
          value_time,
          value_timestamp.
    element_generator->require_all_fields = abap_false.
    check_scenario( val = value_string          exp = '' ).
    check_scenario( val = value_int             exp = '' ).
    check_scenario( val = value_conversion_exit exp = '' ).
    check_scenario( val = value_date            exp = '' ).
    check_scenario( val = value_time            exp = '' ).
    check_scenario( val = value_timestamp       exp = '' ).

  ENDMETHOD.


  METHOD check_scenario.

    DATA: result     TYPE string,
          type_title TYPE string,
          error      TYPE string.

    element_generator->generate_data_type_config(
      EXPORTING
        data = val
    ).

    result = cut->encode(
      EXPORTING
        value = val
        element_config = element_generator->get_field_config( )
    ).

    type_title = get_type_title( val ).

    CONCATENATE 'Error in encoding of type '
                type_title
           INTO error SEPARATED BY space.

    cl_abap_unit_assert=>assert_equals( msg = error
                                        exp = exp
                                        act = result ).

  ENDMETHOD.

  METHOD get_type_title.

    DATA: type TYPE REF TO cl_abap_typedescr.
    type   = cl_abap_typedescr=>describe_by_data( val ).
    result = type->get_relative_name( ).

  ENDMETHOD.

  METHOD boolean_values.

    DATA: value_bool    TYPE abap_bool,
          value_boolean TYPE boolean,
          value_bool_d  TYPE boole_d,
          value_xfeld   TYPE xfeld.

    "Check boolean false
    check_scenario( val = value_bool    exp = 'false' ).
    check_scenario( val = value_boolean exp = 'false' ).
    check_scenario( val = value_bool_d  exp = 'false' ).
    check_scenario( val = value_xfeld   exp = 'false' ).

    "Check boolean true
    value_bool = value_boolean = value_bool_d = value_xfeld = 'X'.
    check_scenario( val = value_bool    exp = 'true' ).
    check_scenario( val = value_boolean exp = 'true' ).
    check_scenario( val = value_bool_d  exp = 'true' ).
    check_scenario( val = value_xfeld   exp = 'true' ).

  ENDMETHOD.

  METHOD struct_simple_names.

    DATA: lw_range    TYPE ace_generic_range,
          json_result TYPE string.

    lw_range-sign   = 'I'.
    lw_range-option = 'EQ'.
    lw_range-low    = '0010'.
    json_result = '{"sign":"I","option":"EQ","low":"0010"}'.
    check_scenario( val = lw_range exp  = json_result ).

  ENDMETHOD.

  METHOD struct_complex_names_camelcase.

    TYPES:
      BEGIN OF struct_complex_name,
        field_name TYPE string,
      END OF struct_complex_name.

    DATA: struct      TYPE struct_complex_name,
          json_result TYPE string.

    struct-field_name = 'test'.
    json_result = '{"fieldName":"test"}'.
    check_scenario( val = struct exp  = json_result ).

  ENDMETHOD.

  METHOD struct_complex_names.

    TYPES:
      BEGIN OF struct_complex_name,
        field_name TYPE string,
      END OF struct_complex_name.

    DATA: struct      TYPE struct_complex_name,
          json_result TYPE string.

    struct-field_name = 'test'.
    json_result = '{"field_name":"test"}'.
    element_generator->name_to_camel_case = abap_false.
    check_scenario( val = struct exp  = json_result ).

  ENDMETHOD.

  METHOD struct_keeping_empty_values.

    DATA: lw_range    TYPE ace_generic_range,
          json_result TYPE string.

    element_generator->require_all_fields = abap_true.
    json_result = '{"sign":"","option":"","low":"","high":""}'.
    check_scenario( val = lw_range exp = json_result ).

  ENDMETHOD.

  METHOD struct_empty.

    DATA: lw_range    TYPE ace_generic_range,
          json_result TYPE string.

    json_result = '{}'.
    check_scenario( val = lw_range exp  = json_result ).

  ENDMETHOD.

  METHOD struct_with_table_attribute.

    TYPES:
      t_elements TYPE STANDARD TABLE OF string WITH DEFAULT KEY,
      BEGIN OF struct_with_table_att,
        message  TYPE string,
        succeded TYPE t_elements,
        failed   TYPE t_elements,
      END OF struct_with_table_att.

    DATA: json_result TYPE string,
          element     TYPE string,
          struct      TYPE struct_with_table_att.

    struct-message = 'teste'.
    element = 'ok'.
    APPEND element TO struct-succeded.
    element = 'certo'.
    APPEND element TO struct-succeded.

    element = 'erro'.
    APPEND element TO struct-failed.

    CONCATENATE '{'
    '"message":"teste",'
    '"succeded":['
    '"ok",'
    '"certo"'
    '],'
    '"failed":['
    '"erro"'
    ']'
    '}' INTO json_result.

    check_scenario( val = struct exp = json_result ).

  ENDMETHOD.

  METHOD internal_table.

    DATA: lw_range    TYPE ace_generic_range,
          lt_range    TYPE ace_generic_range_t,
          json_result TYPE string.

    lw_range-sign   = 'I'.
    lw_range-option = 'EQ'.
    lw_range-low    = '0010'.
    lw_range-high   = '0019'.
    APPEND lw_range TO lt_range.
    lw_range-low    = '0020'.
    lw_range-high   = '0029'.
    APPEND lw_range TO lt_range.

    json_result = '[{"sign":"I","option":"EQ","low":"0010","high":"0019"},{"sign":"I","option":"EQ","low":"0020","high":"0029"}]'.
    check_scenario( val = lt_range exp = json_result ).

  ENDMETHOD.

  METHOD empty_internal_table.

    DATA: lw_range    TYPE ace_generic_range_t,
          json_result TYPE string.

    json_result = '[]'.
    check_scenario( val = lw_range exp = json_result ).
  ENDMETHOD.

  METHOD required_object_field.

    TYPES:
      BEGIN OF object_struct,
        name TYPE string,
      END OF object_struct,

      BEGIN OF struct,
        field TYPE object_struct,
      END OF struct.

    DATA: lw_struct   TYPE struct.
    element_generator->require_all_fields = abap_true.
    check_scenario( val = lw_struct exp = '{"field":{"name":""}}' ).

  ENDMETHOD.

  METHOD required_array_field.

    TYPES:
      table_struct TYPE STANDARD TABLE OF string WITH DEFAULT KEY,

      BEGIN OF struct,
        field TYPE table_struct,
      END OF struct.

    DATA: lw_struct   TYPE struct.
    element_generator->require_all_fields = abap_true.
    check_scenario( val = lw_struct exp = '{"field":[]}' ).

  ENDMETHOD.

  METHOD non_required_object_field.

    TYPES:
      BEGIN OF object_struct,
        name TYPE string,
      END OF object_struct,

      BEGIN OF struct,
        field TYPE object_struct,
      END OF struct.

    DATA: lw_struct   TYPE struct.
    element_generator->require_all_fields = abap_false.
    check_scenario( val = lw_struct exp = '{}' ).

  ENDMETHOD.

  METHOD non_required_array_field.

    TYPES:
      table_struct TYPE STANDARD TABLE OF string WITH DEFAULT KEY,

      BEGIN OF struct,
        field TYPE table_struct,
      END OF struct.

    DATA: lw_struct   TYPE struct.
    element_generator->require_all_fields = abap_false.
    check_scenario( val = lw_struct exp = '{}' ).

  ENDMETHOD.


  METHOD escaping_characters.

    TYPES:
      BEGIN OF struct,
        name TYPE string,
      END OF struct,

      BEGIN OF test_unit,
        struct        TYPE struct,
        expected_json TYPE string,
      END OF test_unit.

    DATA: test_data TYPE STANDARD TABLE OF test_unit.

    test_data = VALUE #(
        (
            struct-name   = 'test "ou" escape'
            expected_json = '{"name":"test \"ou\" escape"}'
        )
        (
            struct-name   = 'test D''Json escape'
            expected_json = '{"name":"test D''Json escape"}'
        )
    ).

    LOOP AT test_data ASSIGNING FIELD-SYMBOL(<test>).
      check_scenario( val = <test>-struct exp = <test>-expected_json ).
    ENDLOOP.

  ENDMETHOD.

  METHOD keep_blank_spaces.

    DATA: lw_range    TYPE ace_generic_range,
          json_result TYPE string.

    lw_range-low = 'TEST    TEST'.
    json_result = '{"low":"TEST    TEST"}'.
    check_scenario( val = lw_range exp  = json_result ).

  ENDMETHOD.

  METHOD struct_name_subsequent_capital.

    TYPES:
      BEGIN OF struct_complex_name,
        field_n_a_m_e TYPE string,
      END OF struct_complex_name.

    DATA: struct      TYPE struct_complex_name,
          json_result TYPE string.

    struct-field_n_a_m_e = 'test'.
    json_result = '{"fieldNAME":"test"}'.
    check_scenario( val = struct exp  = json_result ).

  ENDMETHOD.

ENDCLASS.

CLASS ltcl_json_decode DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    TYPES:
      BEGIN OF test_struct,
        valid     TYPE abap_bool,
        other     TYPE string,
        timestamp TYPE timestamp,
        time      TYPE sy-uzeit,
        date      TYPE sy-datum,
      END OF test_struct.

    DATA: cut               TYPE REF TO zcl_json_encoder_decoder,
          element_generator TYPE REF TO zcl_json_config_generator,
          element_config    TYPE REF TO zcl_json_element_config.

    METHODS:
      setup,

      check_scenario
        IMPORTING
          json     TYPE clike
          expected TYPE any
        CHANGING
          actual   TYPE any,

      check_attribute
        IMPORTING
          json TYPE string
          exp  TYPE string,

      check_normalize_array_attrib
        IMPORTING
          attribute_name TYPE string
          json           TYPE string
          expected       TYPE string.

    METHODS:
      struct                            FOR TESTING,
      table                             FOR TESTING,
      struct_camelcase_complex_names    FOR TESTING,
      struct_field_internal_table       FOR TESTING,
      timestamp                         FOR TESTING,
      date                              FOR TESTING,
      time                              FOR TESTING,
      simple_attribute                  FOR TESTING,
      nested_named_struct               FOR TESTING,
      handle_spaced_json                FOR TESTING,
      ascii_string                      FOR TESTING,
      normalize_array_field             FOR TESTING,
      normalize_nested_array_field      FOR TESTING,
      not_change_normalized_field       FOR TESTING,
      not_change_invalid_json           FOR TESTING,
      normalize_attribute_not_found     FOR TESTING,
      nested_struct_number              FOR TESTING,
      array_with_string_content         FOR TESTING,
      escaped_string                    FOR TESTING,
      negative_value                    FOR TESTING,
      undescore_is_valid FOR TESTING.

ENDCLASS.

CLASS ltcl_json_decode IMPLEMENTATION.

  METHOD setup.
    cut = NEW #( ).
    element_generator = NEW #( ).
  ENDMETHOD.

  METHOD struct.

    DATA: lw_actual   TYPE ace_generic_range,
          lw_expected TYPE ace_generic_range.

    lw_expected-sign    = 'I'.
    lw_expected-option  = 'EQ'.
    lw_expected-low     = '0010'.

    check_scenario( EXPORTING
                        json = '{"sign":"I","option":"EQ","low":"0010","high":""}'
                        expected = lw_expected
                    CHANGING
                        actual   = lw_actual ).

  ENDMETHOD.


  METHOD check_scenario.

    element_config = element_generator->generate_data_type_config(
                     data   = expected ).

    cut->decode(
      EXPORTING
        json_string = json
        element_config = element_config
      CHANGING
        result       = actual
    ).

    cl_abap_unit_assert=>assert_equals(
      EXPORTING
        act = actual
        exp = expected
    ).

  ENDMETHOD.

  METHOD table.

    DATA: lt_actual   TYPE ace_generic_range_t,
          lw_expected TYPE ace_generic_range,
          lt_expected TYPE ace_generic_range_t.

    lw_expected-sign    = 'I'.
    lw_expected-option  = 'EQ'.
    lw_expected-low     = '0010'.
    APPEND lw_expected TO lt_expected.
    lw_expected-low     = '0020'.
    APPEND lw_expected TO lt_expected.

    check_scenario( EXPORTING
                        json = '[{"sign":"I","option":"EQ","low":"0010","high":""},{"sign":"I","option":"EQ","low":"0020","high":""}]'
                        expected = lt_expected
                    CHANGING
                        actual   = lt_actual ).

  ENDMETHOD.

  METHOD struct_camelcase_complex_names.

    TYPES:
      BEGIN OF struct_complex_name,
        field_name TYPE string,
      END OF struct_complex_name.

    DATA: expected TYPE struct_complex_name,
          actual   TYPE struct_complex_name.

    expected-field_name = 'Valdir'.
    check_scenario( EXPORTING
                        json = '{"fieldName":"Valdir"}'
                        expected = expected
                    CHANGING
                        actual   = actual ).
  ENDMETHOD.

  METHOD timestamp.

    DATA: expected TYPE test_struct,
          actual   TYPE test_struct.

    expected-timestamp = '20191023145508'.
    check_scenario( EXPORTING
                        json = '{"timestamp":"2019-10-23T14:55:08"}'
                        expected = expected
                    CHANGING
                        actual   = actual ).

  ENDMETHOD.

  METHOD date.

    DATA: expected TYPE test_struct,
          actual   TYPE test_struct.

    expected-date = '20191023'.
    check_scenario( EXPORTING
                        json = '{"date":"2019-10-23"}'
                        expected = expected
                    CHANGING
                        actual   = actual ).
  ENDMETHOD.

  METHOD time.

    DATA: expected TYPE test_struct,
          actual   TYPE test_struct.

    expected-time       = '145508'.
    check_scenario( EXPORTING
                        json = '{"time":"14:55:08"}'
                        expected = expected
                    CHANGING
                        actual   = actual ).
  ENDMETHOD.

  METHOD struct_field_internal_table.

    TYPES:
      BEGIN OF ty_it,
        name TYPE string,
      END OF ty_it,

      ty_it_t TYPE STANDARD TABLE OF ty_it WITH DEFAULT KEY,

      BEGIN OF struct_complex_name,
        field_name TYPE string,
        names      TYPE ty_it_t,
      END OF struct_complex_name.

    DATA: struct          TYPE struct_complex_name,
          actual          TYPE struct_complex_name,
          internal_struct TYPE ty_it.

    struct-field_name = 'test'.
    internal_struct-name = 'test'. APPEND internal_struct TO struct-names.
    check_scenario( EXPORTING
                    json = '{"fieldName":"test","names":[{"name":"test"}]}'
                    expected = struct
                CHANGING
                    actual   = actual ).

  ENDMETHOD.

  METHOD simple_attribute.
    check_attribute( json = '{"simple":"value"}' exp = 'value' ).
    check_attribute( json = '{"simple":true}' exp = 'X' ).
    check_attribute( json = '{"simple":false}' exp = '' ).
    check_attribute( json = '{"simple":null}' exp = '' ).
    check_attribute( json = '{"$simple":"value"}' exp = 'value' ).
  ENDMETHOD.


  METHOD check_attribute.

    TYPES:
      BEGIN OF struct,
        simple TYPE string,
      END OF struct.

    DATA: decoded TYPE struct.
    element_config = element_generator->generate_data_type_config(
                     data   = decoded ).

    cut->decode(
      EXPORTING
        json_string = json
        element_config = element_config
      CHANGING
        result       = decoded
    ).

    cl_abap_unit_assert=>assert_equals( msg = 'should returns filled struct'
                                        exp = decoded-simple
                                        act = exp ).

  ENDMETHOD.

  METHOD nested_named_struct.

    TYPES:
      BEGIN OF nested,
        name TYPE string,
      END OF nested,
      BEGIN OF main,
        nested TYPE nested,
      END OF main.

    DATA: decoded TYPE main.
    element_config = element_generator->generate_data_type_config(
                     data   = decoded ).

    cut->decode(
      EXPORTING
        json_string = '{"nested":{"name":"test"}}'
        element_config = element_config
      CHANGING
        result       = decoded
    ).

    cl_abap_unit_assert=>assert_equals( msg = 'Should returns filled struct'
                                        exp = 'test'
                                        act = decoded-nested-name ).

  ENDMETHOD.

  METHOD handle_spaced_json.

    TYPES:
      BEGIN OF nested,
        name TYPE string,
      END OF nested,
      BEGIN OF main,
        nested TYPE nested,
      END OF main.

    DATA: decoded TYPE main.
    element_config = element_generator->generate_data_type_config(
                     data   = decoded ).

    cut->decode(
      EXPORTING
        json_string     = '{ "nested" : { "name" : "test" } }'
        element_config  = element_config
      CHANGING
        result          = decoded
    ).

    cl_abap_unit_assert=>assert_equals( msg = 'Should returns filled struct'
                                        exp = 'test'
                                        act = decoded-nested-name ).

  ENDMETHOD.

  METHOD ascii_string.
    check_attribute( json = '{"simple":"2019-12-05T12:03:51+00:00"}' exp = '2019-12-05T12:03:51+00:00' ).
  ENDMETHOD.

  METHOD normalize_array_field.

    DATA: json     TYPE string,
          expected TYPE string.

    json        = '{"a":"v","d":{"e":"v"}}'.
    expected    = '{"a":"v","d":[{"e":"v"}]}'.

    check_normalize_array_attrib(
          attribute_name = 'd'
          json     = json
          expected = expected ).

  ENDMETHOD.

  METHOD normalize_nested_array_field.

    DATA: json     TYPE string,
          expected TYPE string.

    json     = '{"a":{"b":"c"},"d":{"e":"f"},"g":{"h":{"array":"teste"},"i":"j"},"k":"l"}'.
    expected = '{"a":{"b":"c"},"d":{"e":"f"},"g":{"h":[{"array":"teste"}],"i":"j"},"k":"l"}'.

    check_normalize_array_attrib(
          attribute_name = 'h'
          json     = json
          expected = expected ).

    json     = '{"a":{"b":"c"},"d":{"e":"f"},"g":{"h":{"array":"teste"},"i":"j"},"k":"l"}'.
    expected = '{"a":{"b":"c"},"d":{"e":"f"},"g":[{"h":{"array":"teste"},"i":"j"}],"k":"l"}'.

    check_normalize_array_attrib(
          attribute_name = 'g'
          json     = json
          expected = expected ).

  ENDMETHOD.

  METHOD not_change_normalized_field.

    DATA: json     TYPE string,
          expected TYPE string.

    json        = '{"a":"v","d":[{"e":"v"}]}'.
    expected    = '{"a":"v","d":[{"e":"v"}]}'.

    check_normalize_array_attrib(
          attribute_name = 'd'
          json     = json
          expected = expected ).

  ENDMETHOD.

  METHOD not_change_invalid_json.

    DATA: json     TYPE string,
          expected TYPE string.

    json        = '{"a":"v","d":"b"}}'.
    expected    = '{"a":"v","d":"b"}}'.

    check_normalize_array_attrib(
          attribute_name = 'd'
          json     = json
          expected = expected ).


  ENDMETHOD.

  METHOD normalize_attribute_not_found.

    DATA: json     TYPE string,
          expected TYPE string.

    json        = '{"a":"v","d":{"e":"v"}}'.
    expected    = '{"a":"v","d":{"e":"v"}}'.

    check_normalize_array_attrib(
          attribute_name = 'test'
          json     = json
          expected = expected ).

  ENDMETHOD.

  METHOD check_normalize_array_attrib.

    DATA result TYPE string.

    result = cut->normalize_array_attribute( attribute_name = attribute_name
                                             json_string    = json ).

    cl_abap_unit_assert=>assert_equals( msg = 'Error trying normalize array attribute'
                                        exp = expected
                                        act = result ).

  ENDMETHOD.

  METHOD nested_struct_number.

    TYPES:
      BEGIN OF nested,
        code TYPE string,
      END OF nested,
      BEGIN OF main,
        status TYPE nested,
      END OF main.

    DATA: decoded TYPE main.
    element_config = element_generator->generate_data_type_config(
                     data   = decoded ).

    cut->decode(
      EXPORTING
        json_string     = '{ "status" : { "code" : 930 } }'
        element_config  = element_config
      CHANGING
        result          = decoded
    ).

    cl_abap_unit_assert=>assert_equals( msg = 'Should returns filled struct'
                                        exp = '930'
                                        act = decoded-status-code ).

  ENDMETHOD.

  METHOD array_with_string_content.

    TYPES:
      BEGIN OF main,
        test TYPE STANDARD TABLE OF string WITH DEFAULT KEY,
      END OF main.

    DATA: decoded TYPE main.
    element_config = element_generator->generate_data_type_config(
                     data   = decoded ).

    cut->decode(
      EXPORTING
        json_string     = '{ "test" : [ "value", "value1" ] }'
        element_config  = element_config
      CHANGING
        result          = decoded
    ).

    cl_abap_unit_assert=>assert_equals( msg = 'Should returns filled struct'
                                        exp = 2
                                        act = lines( decoded-test ) ).

  ENDMETHOD.

  METHOD escaped_string.

    TYPES:
      BEGIN OF nested,
        c_stat TYPE string,
        m_stat TYPE string,
      END OF nested,
      BEGIN OF main,
        status TYPE nested,
      END OF main.

    DATA: decoded TYPE main.

    DATA(element_config) = element_generator->generate_data_type_config( data = decoded ).

    cut->decode(
      EXPORTING
        json_string    = '{ "status": { "cStat": "-1","mStat": "det[0].prod.cest must match \"[0-9]{7}\"" }}'
        element_config = element_config
      CHANGING
        result         = decoded
    ).

    cl_abap_unit_assert=>assert_equals( msg = 'Should returns filled struct'
                                        exp = 'det[0].prod.cest must match [0-9]{7}'
                                        act = decoded-status-m_stat ).

  ENDMETHOD.

  METHOD negative_value.

    TYPES:
      BEGIN OF json,
        value TYPE int8,
      END OF json.

    DATA: decoded TYPE json.
    DATA(element_config) = element_generator->generate_data_type_config( data = decoded ).

    cut->decode(
      EXPORTING
        json_string    = '{"value":-34}'
        element_config = element_config
      CHANGING
        result         = decoded
    ).

    cl_abap_unit_assert=>assert_equals(
      EXPORTING
        exp = '34-'
        act = decoded-value
*        msg      =
    ).

  ENDMETHOD.

  METHOD undescore_is_valid.
    TYPES:
      BEGIN OF json,
        value TYPE string,
      END OF json.

    DATA: decoded TYPE json.
    DATA(element_config) = element_generator->generate_data_type_config( data = decoded ).

    cut->decode(
      EXPORTING
        json_string    = '{"value": "created_at"}'
        element_config = element_config
      CHANGING
        result         = decoded
    ).

    cl_abap_unit_assert=>assert_equals(
      EXPORTING
        exp = 'created_at'
        act = decoded-value
*        msg      =
    ).


  ENDMETHOD.

ENDCLASS.

CLASS json_structure DEFINITION.

  PUBLIC SECTION.

    METHODS:
      add_element
        IMPORTING
          type  TYPE char1
          name  TYPE string OPTIONAL
          value TYPE string OPTIONAL,
      get_structure
        RETURNING
          VALUE(result) TYPE scanner=>json_element,
      level_up_element.

  PROTECTED SECTION.
  PRIVATE SECTION.

    DATA: actual_element TYPE REF TO data,
          elements       TYPE STANDARD TABLE OF REF TO data.
    METHODS create_element
      IMPORTING
        type          TYPE char1
        name          TYPE string
        value         TYPE string
      RETURNING
        VALUE(result) TYPE REF TO data.
    METHODS initialize_element
      IMPORTING
        type    TYPE char1
        name    TYPE string
        value   TYPE string
      CHANGING
        element TYPE scanner=>json_element.

ENDCLASS.

CLASS json_structure IMPLEMENTATION.

  METHOD add_element.

    IF me->actual_element IS NOT BOUND.
      me->actual_element = create_element( type  = type
                                           name  = name
                                           value = value ).
      APPEND me->actual_element TO me->elements.
      RETURN.
    ENDIF.

    FIELD-SYMBOLS:
      <elements> TYPE scanner=>t_json_element,
      <element>  TYPE scanner=>json_element,
      <actual>   TYPE scanner=>json_element.

    ASSIGN:
     me->actual_element->* TO <element>,
     <element>-children->* TO <elements>.

    APPEND INITIAL LINE TO <elements> ASSIGNING <actual>.
    initialize_element(
      EXPORTING
        type    = type
        name    = name
        value   = value
      CHANGING
        element = <actual>
    ).
    GET REFERENCE OF <actual> INTO me->actual_element.
    APPEND me->actual_element TO me->elements.

  ENDMETHOD.


  METHOD create_element.
    FIELD-SYMBOLS: <json_element> TYPE scanner=>json_element.
    CREATE DATA: result TYPE scanner=>json_element.
    ASSIGN result->* TO <json_element>.
    initialize_element(
        EXPORTING
            type  = type
            name  = name
            value = value
        CHANGING
            element = <json_element> ).
  ENDMETHOD.


  METHOD get_structure.
    DATA: ref_first TYPE REF TO data.
    FIELD-SYMBOLS: <result> LIKE result.

    READ TABLE me->elements INTO ref_first INDEX 1.
    IF sy-subrc NE 0.
      RETURN.
    ENDIF.
    ASSIGN ref_first->* TO <result>.
    result = <result>.
  ENDMETHOD.


  METHOD initialize_element.
    CREATE DATA element-children TYPE scanner=>t_json_element.
    element-type     = type.
    element-name     = name.
    element-value    = value.
  ENDMETHOD.


  METHOD level_up_element.

    IF lines( me->elements ) <= 1.
      RETURN.
    ENDIF.

    READ TABLE me->elements INTO me->actual_element INDEX lines( me->elements )  - 1.
    DELETE me->elements INDEX lines( me->elements ).

  ENDMETHOD.

ENDCLASS.

CLASS ltcl_scanner DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    TYPES:
      BEGIN OF test_instance,
        json     TYPE string,
        expected TYPE scanner=>json_element,
      END OF test_instance,

      t_tests_instance TYPE STANDARD TABLE OF test_instance WITH DEFAULT KEY.

    DATA: cut            TYPE REF TO scanner,
          json_structure TYPE REF TO json_structure.

    METHODS:
      setup,

      check_json_element_tree
        IMPORTING expected      TYPE scanner=>json_element
                  actual        TYPE scanner=>json_element
        RETURNING VALUE(result) TYPE abap_bool,

      check_tests_scenarios
        IMPORTING
          test_instances TYPE t_tests_instance.

    METHODS:
      is_valid                          FOR TESTING RAISING cx_static_check,
      json_simple_attrib_struct_tree    FOR TESTING RAISING cx_static_check,
      json_object_struct_tree           FOR TESTING RAISING cx_static_check,
      json_array_struct_tree            FOR TESTING RAISING cx_static_check,
      json_array_struct_content_tree    FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_scanner IMPLEMENTATION.

  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD is_valid.

    TYPES:
      BEGIN OF valid_test,
        json TYPE string,
        ok   TYPE abap_bool,
      END OF valid_test.

    DATA: valid_tests TYPE STANDARD TABLE OF valid_test.

    valid_tests = VALUE #( ( json = 'foo' ok = abap_false )
                           ( json = '}{' ok = abap_false )
                           ( json = '{]' ok = abap_false )
                           ( json = '{}' ok = abap_true )
                           ( json = '{"foo":"bar"}' ok = abap_true )
                           ( json = '{"foo":true}' ok = abap_true )
                           ( json = '{"foo":false}' ok = abap_true )
                           ( json = '{"foo":null}' ok = abap_true )
                           ( json = '{"foo":0}' ok = abap_true )
                           ( json = '{"foo":0.1}' ok = abap_true )
                           ( json = '{"foo":1.2}' ok = abap_true )
                           ( json = '{"foo":-1.2}' ok = abap_true )
                           ( json = '{"foo":"bar","bar":{"baz":["qux"]}}' ok = abap_true )
                           ( json = '{"foo":"bar","bar":{"baz":["qux","quy"]}}' ok = abap_true ) ).

    LOOP AT valid_tests ASSIGNING FIELD-SYMBOL(<test>).

      cl_abap_unit_assert=>assert_equals(
        EXPORTING
            act = cut->valid( <test>-json )
            exp = <test>-ok
            msg = |Json: { <test>-json } expected ok: { <test>-ok }| ).

    ENDLOOP.

  ENDMETHOD.

  METHOD check_json_element_tree.

    FIELD-SYMBOLS:
      <actual_children>   TYPE scanner=>t_json_element,
      <expected_children> TYPE scanner=>t_json_element,
      <expected>          TYPE scanner=>json_element,
      <actual>            TYPE scanner=>json_element.

    result = abap_true.

    IF expected-type NE actual-type.
      result = abap_false.
      RETURN.
    ENDIF.

    IF expected-name NE actual-name.
      result = abap_false.
      RETURN.
    ENDIF.

    IF expected-value NE actual-value.
      result = abap_false.
      RETURN.
    ENDIF.

    ASSIGN: expected-children->* TO <expected_children>,
            actual-children->* TO <actual_children>.

    IF lines( <expected_children> ) NE lines( <actual_children> ).
      result = abap_false.
      RETURN.
    ENDIF.

    LOOP AT <expected_children> ASSIGNING <expected>.

      READ TABLE <actual_children> ASSIGNING <actual> INDEX sy-tabix.

      result = check_json_element_tree( expected = <expected>
                                        actual   = <actual> ).

      IF result EQ abap_false.
        RETURN.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD check_tests_scenarios.

    DATA: json_element   TYPE scanner=>json_element.

    LOOP AT test_instances ASSIGNING FIELD-SYMBOL(<test>).

      cut->valid( json = <test>-json ).
      json_element = cut->get_json_element_tree( ).

      cl_abap_unit_assert=>assert_true(
        EXPORTING
          act = check_json_element_tree( expected = <test>-expected
                                         actual   = json_element )
          msg = |Scenario: { <test>-json }|
      ).

    ENDLOOP.

  ENDMETHOD.

  METHOD json_object_struct_tree.

    DATA: test_instances TYPE t_tests_instance,
          json_element   TYPE scanner=>json_element.

    "Scenario: json with array
    json_structure = NEW #( ).
    json_structure->add_element( type = scanner=>json_element_type-object ).
    json_structure->add_element(
      EXPORTING
        type  = scanner=>json_element_type-attribute
        name  = 'atr'
        value = 'value'
    ).
    json_structure->level_up_element( ).
    json_structure->add_element(
      EXPORTING
        type  = scanner=>json_element_type-name
        name  = 'test'
    ).
    json_structure->add_element(
      EXPORTING
        type  = scanner=>json_element_type-array
    ).
    json_structure->add_element(
      EXPORTING
        type  = scanner=>json_element_type-object
    ).
    json_structure->add_element(
      EXPORTING
        type  = scanner=>json_element_type-attribute
        name  = 'foo'
        value = 'bar'
    ).
    APPEND VALUE #( json = '{"atr":"value","test":[{"foo":"bar"}]}'
                    expected = json_structure->get_structure( ) ) TO test_instances.

    "Scenario: json with object + attributes
    json_structure = NEW #( ).
    json_structure->add_element( type = scanner=>json_element_type-object ).
    json_structure->add_element(
      EXPORTING
        type  = scanner=>json_element_type-attribute
        name  = 'atr'
        value = 'value'
    ).
    json_structure->level_up_element( ).
    json_structure->add_element(
      EXPORTING
        type  = scanner=>json_element_type-name
        name  = 'attributes'
*        value =
    ).
    json_structure->add_element( type = scanner=>json_element_type-object ).
    json_structure->add_element(
      EXPORTING
        type  = scanner=>json_element_type-attribute
        name  = 'foo'
        value = 'bar'
    ).
    json_structure->level_up_element( ). "
    json_structure->level_up_element( ).
    json_structure->level_up_element( ).
    json_structure->add_element(
      EXPORTING
        type  = scanner=>json_element_type-attribute
        name  = 'at'
        value = 'value'
    ).
    APPEND VALUE #( json = '{"atr":"value","attributes":{"foo":"bar"},"at":"value"}'
                    expected = json_structure->get_structure( ) ) TO test_instances.


    json_structure = NEW #( ).
    json_structure->add_element( type = scanner=>json_element_type-object ).
    json_structure->add_element(
      EXPORTING
        type  = scanner=>json_element_type-name
        name  = 'attributes'
    ).
    json_structure->add_element( type = scanner=>json_element_type-object ).
    json_structure->add_element(
      EXPORTING
        type  = scanner=>json_element_type-name
        name  = 'foo'
    ).
    json_structure->add_element( type = scanner=>json_element_type-object ).
    json_structure->add_element(
      EXPORTING
        type  = scanner=>json_element_type-attribute
        name  = 'bar'
        value = 'foo'
    ).

    APPEND VALUE #( json = '{"attributes":{"foo":{"bar":"foo"}}}'
                    expected = json_structure->get_structure( ) ) TO test_instances.


    check_tests_scenarios(
        test_instances = test_instances
    ).

  ENDMETHOD.

  METHOD json_simple_attrib_struct_tree.

    DATA: test_instances TYPE t_tests_instance,
          json_element   TYPE scanner=>json_element.

    "Scenario: simple json
    json_structure = NEW #( ).
    json_structure->add_element( type = scanner=>json_element_type-object ).
    APPEND VALUE #( json = '{}' expected = json_structure->get_structure( ) ) TO test_instances.

    "Scenario: simple json with attributes
    json_structure = NEW #( ).
    json_structure->add_element( type = scanner=>json_element_type-object ).
    json_structure->add_element(
      EXPORTING
        type  = scanner=>json_element_type-attribute
        name  = 'atr'
        value = 'value'
    ).

    json_structure->level_up_element( ).
    json_structure->add_element(
      EXPORTING
        type  = scanner=>json_element_type-attribute
        name  = 'foo'
        value = 'value complex'
    ).
    APPEND VALUE #( json = '{"atr":"value","foo":"value complex"}' expected = json_structure->get_structure( ) ) TO test_instances.

    "Negative value
    json_structure = NEW #( ).
    json_structure->add_element( type = scanner=>json_element_type-object ).
    json_structure->add_element(
      EXPORTING
        type  = scanner=>json_element_type-attribute
        name  = 'value'
        value = '-34'
    ).
    APPEND VALUE #( json = '{"value":-34}' expected = json_structure->get_structure( ) ) TO test_instances.

    check_tests_scenarios( test_instances = test_instances ).

  ENDMETHOD.

  METHOD json_array_struct_tree.

    DATA: test_instances TYPE t_tests_instance,
          json_element   TYPE scanner=>json_element.

    "Scenario: json with array
    json_structure = NEW #( ).
    json_structure->add_element( type = scanner=>json_element_type-object ).
    json_structure->add_element(
      EXPORTING
        type  = scanner=>json_element_type-name
        name  = 'test'
    ).
    json_structure->add_element( type  = scanner=>json_element_type-array ).
    APPEND VALUE #( json = '{"test":[]}'
                    expected = json_structure->get_structure( ) ) TO test_instances.

    json_structure = NEW #( ).
    json_structure->add_element( type = scanner=>json_element_type-object ).
    json_structure->add_element(
      EXPORTING
        type  = scanner=>json_element_type-name
        name  = 'test'
    ).
    json_structure->add_element(
      EXPORTING
        type  = scanner=>json_element_type-array
    ).
    json_structure->add_element(
      EXPORTING
        type  = scanner=>json_element_type-object
    ).
    json_structure->add_element(
      EXPORTING
        type  = scanner=>json_element_type-attribute
        name  = 'foo'
        value = 'bar'
    ).
    json_structure->level_up_element( ).
    json_structure->level_up_element( ).
    json_structure->add_element(
      EXPORTING
        type  = scanner=>json_element_type-object
    ).
    json_structure->add_element(
      EXPORTING
        type  = scanner=>json_element_type-attribute
        name  = 'bar'
        value = 'foo'
    ).
    APPEND VALUE #( json = '{"test":[{"foo":"bar"},{"bar":"foo"}]}'
                    expected = json_structure->get_structure( ) ) TO test_instances.

    check_tests_scenarios( test_instances = test_instances ).

  ENDMETHOD.

  METHOD json_array_struct_content_tree.
    DATA: test_instances TYPE t_tests_instance,
          json_element   TYPE scanner=>json_element.

    "Scenario: json with array with 1 string content
    json_structure = NEW #( ).
    json_structure->add_element( type = scanner=>json_element_type-object ).
    json_structure->add_element(
      EXPORTING
        type  = scanner=>json_element_type-name
        name  = 'succeded'
    ).
    json_structure->add_element( type = scanner=>json_element_type-array ).
    json_structure->add_element( type  = scanner=>json_element_type-value_string
                                 value = 'primeiro' ).

    APPEND VALUE #( json = '{"succeded":["primeiro"]}'
                    expected = json_structure->get_structure( ) ) TO test_instances.

    "Scenario: json with array with some strings content
    json_structure = NEW #( ).
    json_structure->add_element( type = scanner=>json_element_type-object ).
    json_structure->add_element(
      EXPORTING
        type  = scanner=>json_element_type-name
        name  = 'succeded'
    ).
    json_structure->add_element( type = scanner=>json_element_type-array ).
    json_structure->add_element( type  = scanner=>json_element_type-value_string
                                 value = 'primeiro' ).
    json_structure->level_up_element( ).
    json_structure->add_element( type  = scanner=>json_element_type-value_string
                                 value = 'segundo' ).

    APPEND VALUE #( json = '{"succeded":["primeiro","segundo"]}'
                    expected = json_structure->get_structure( ) ) TO test_instances.

    "Scenario: json with nested array with some strings content
    json_structure = NEW #( ).
    json_structure->add_element( type = scanner=>json_element_type-object ).
    json_structure->add_element(
      EXPORTING
        type  = scanner=>json_element_type-name
        name  = 'succeded'
    ).
    json_structure->add_element( type = scanner=>json_element_type-array ).
    json_structure->add_element( type  = scanner=>json_element_type-value_string
                                 value = 'primeiro' ).
    json_structure->level_up_element( ).
    json_structure->add_element( type  = scanner=>json_element_type-value_string
                                 value = 'segundo' ).
    json_structure->level_up_element( ). "Back from string element to array
    json_structure->level_up_element( ). "Back from array to named element
    json_structure->level_up_element( ). "back from named element to object
    json_structure->add_element(
      EXPORTING
        type  = scanner=>json_element_type-attribute
        name  = 'test'
        value = 'value'
    ).

    APPEND VALUE #( json = '{"succeded":["primeiro","segundo"],"test":"value"}'
                    expected = json_structure->get_structure( ) ) TO test_instances.

    check_tests_scenarios( test_instances = test_instances ).
  ENDMETHOD.

ENDCLASS.
