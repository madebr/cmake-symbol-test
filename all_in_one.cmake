function(parallel_check_include_file)
    cmake_parse_arguments(ARG "" "" "CHECKS" ${ARGN})

    set(c_ifdefs "")
    set(c_main_body "")
    set(i 0)

    set(header_var_list )

    list(LENGTH ARG_CHECKS arg_checks_length)

    while (i LESS arg_checks_length)
        list(GET ARG_CHECKS "${i}" header)
        math(EXPR i "${i} + 1")
        list(GET ARG_CHECKS "${i}" var)
        math(EXPR i "${i} + 1")

        if(DEFINED CACHE{${var}})
            continue()
        endif()

        list(APPEND header_var_list "${header}" "${var}")

        message(STATUS "Looking in parallel for ${header}")

        string(APPEND c_ifdefs "#if __has_include(<${header}>)\n#define M${i} \"1\"\n#else\n#define M${i} \"0\"\n#endif\nconst char *V${i} = \"INFO[${var}=\" M${i} \"]\";\n")
        string(APPEND c_main_body "  result += V${i}[argc];\n")
    endwhile()

    list(LENGTH header_var_list length_header_var_list)
    if(length_header_var_list EQUAL 0)
        return()
    endif()
    string(MD5 md5_list "${header_var_list}")

    set(src "${CMAKE_CURRENT_BINARY_DIR}/${md5_list}_parallel_checks.c")
    set(bin "${CMAKE_CURRENT_BINARY_DIR}/${md5_list}_parallel_checks_bin")

    file(WRITE "${src}" "${c_ifdefs}int main(int argc, char *argv[]) {\n  int result = 0;  \n  (void)argv;\n${c_main_body}  return result;\n}\n")
    try_compile(COMPILED "${CMAKE_CURRENT_BINARY_DIR}/tt" SOURCES "${src}"
        COPY_FILE "${bin}"
    )
    if(NOT COMPILED)
        message(FATAL_ERROR "FIXME: Failure to build -> fall back")
    endif()

    set(i 0)
    while (i LESS length_header_var_list)
        list(GET header_var_list "${i}" header)
        math(EXPR i "${i} + 1")
        list(GET header_var_list "${i}" var)
        math(EXPR i "${i} + 1")

        set(re "INFO\\[${var}=(1|0)\\]")
        file(STRINGS "${bin}" has_include REGEX "${re}")

        if(NOT has_include)
            continue()
        endif()

        string(REGEX MATCH "${re}" yes_no "${has_include}")
        if(CMAKE_MATCH_1)
            message(STATUS "Looking in parallel for ${header} - found")
            set(v "1")
        else()
            message(STATUS "Looking in parallel for ${header} - not found")
            set(v "")
        endif()

        set("${var}" "${v}" CACHE INTERNAL "Have include ${header}")
    endwhile()
endfunction()

include(CheckIncludeFile)

function(serial_check_include_file)
    cmake_parse_arguments(ARG "" "" "CHECKS" ${ARGN})

    set(c_ifdefs "")
    set(c_main_body "")
    set(i 0)

    set(header_var_list )

    list(LENGTH ARG_CHECKS arg_checks_length)

    while (i LESS arg_checks_length)
        list(GET ARG_CHECKS "${i}" header)
        math(EXPR i "${i} + 1")
        list(GET ARG_CHECKS "${i}" var)
        math(EXPR i "${i} + 1")

        check_include_file("${header}" "${var}_REFERENCE")
    endwhile()
endfunction()

function(compare_check_include_file CHECKS)
    set(r TRUE)
    cmake_parse_arguments(ARG "" "" "CHECKS" ${ARGN})

    list(LENGTH ARG_CHECKS arg_checks_length)

    set(i 0)
    set(issues)
    while (i LESS arg_checks_length)
        list(GET ARG_CHECKS "${i}" header)
        math(EXPR i "${i} + 1")
        list(GET ARG_CHECKS "${i}" var)
        math(EXPR i "${i} + 1")

        set(ref "${${var}_REFERENCE}")
        set(got "${${var}}")

        if(NOT ref STREQUAL got)
            list(APPEND issues ${var})
        endif()

        message(STATUS "ref=${ref} got=${got}          ${var}")
    endwhile()
    if(issues)
        message(WARNING "These header checks don't match: ${issues}")
        set(r FALSE)
    else()
        message(STATUS "All header checks match!")
    endif()
    set(${RESULT} ${r} PARENT_SCOPE)
endfunction()

include(CheckSymbolExists)
include(CheckCSourceCompiles)

function(serial_check_c_symbol_exists)
    cmake_parse_arguments(ARG "" "PREFIX;SUFFIX" "SYMBOLS;HEADERS" ${ARGN})
    set(i 0)

    set(src_hdr)
    foreach(hdr IN LISTS ARG_HEADERS)
        string(APPEND src_hdr "#include <${hdr}>\n")
    endforeach()

    foreach(symbol_name ${ARG_SYMBOLS})
        string(MAKE_C_IDENTIFIER "${symbol_name}" symbol_name_upper)
        string(TOUPPER "${symbol_name}" symbol_name_upper)
        set(varname "${ARG_PREFIX}${symbol_name_upper}${ARG_SUFFIX}")

        check_symbol_exists("${symbol_name}" "${ARG_HEADERS}" "${varname}")
    endforeach()

#    list(LENGTH ARG_SYMBOLS arg_checks_length)
#
#    while (i LESS arg_checks_length)
#        list(GET ARG_CHECKS "${i}" var)
#        math(EXPR i "${i} + 1")
#        list(GET ARG_CHECKS "${i}" symbol)
#        math(EXPR i "${i} + 1")
#        list(GET ARG_CHECKS "${i}" first)
#        math(EXPR i "${i} + 1")
#        list(GET ARG_CHECKS "${i}" count)
#        math(EXPR i "${i} + 1")
#
#        set(args "0")
#        set(a 1)
#        while(a LESS ${count})
#            string(APPEND args ", 0")
#            math(EXPR a "${a}+1")
#        endwhile()
#
#        set(src "${src_hdr}int main() {\n ${symbol}(${args});\n return 0;\n}\n")
#
#        check_symbol_exists("${symbol}" "${header_list}" "${var}_REFERENCE")
##        check_c_source_compiles("${src}" "${var}_REFERENCE")
#
#    endwhile()
endfunction()

function(compare_check_symbol_checks RESULT)
    cmake_parse_arguments(ARG "" "VAR_PREFIX;VAR_SUFFIX;VAR_PREFIX_REF;VAR_SUFFIX_REF" "SYMBOLS" ${ARGN})

    set(r TRUE)

    if(NOT ARG_VAR_PREFIX AND NOT ARG_VAR_SUFFIX)
        message(FATAL_ERROR "At least one of VAR_PREFIX or VAR_SUFFIX must be defined")
    endif()

    list(LENGTH ARG_CHECKS arg_checks_length)
    set(issues_linker)

    foreach(symbol ${ARG_SYMBOLS})
        string(MAKE_C_IDENTIFIER "${symbol}" varname_core)
        string(TOUPPER "${varname_core}" varname_core)
        set(varname "${ARG_VAR_PREFIX}${varname_core}${ARG_VAR_SUFFIX}")
        set(refvarname "${ARG_VAR_PREFIX_REF}${varname_core}${ARG_VAR_SUFFIX_REF}")

        set(ref "${${refvarname}}")
        set(got "${${varname}}")

        if(NOT ref STREQUAL got)
            list(APPEND issues_linker ${symbol})
        endif()

        message(STATUS "ref=${ref} got=${got}     ${varname}")
    endforeach()
    if(issues_linker)
        message(WARNING "These symbol checks don't match using LINKER: ${issues_linker}")
        set(r FALSE)
    else()
        message(STATUS "All LINKER symbol checks match!")
    endif()
    set(${RESULT} ${r} PARENT_SCOPE)
endfunction()
