function(parallel_check_include_file)
    cmake_parse_arguments(ARG "" "VAR_PREFIX;VAR_SUFFIX" "HEADERS" ${ARGN})

    set(c_ifdefs "")
    set(c_main_body "")

    set(header_var_list )

    foreach(header ${ARG_HEADERS})
        string(MAKE_C_IDENTIFIER "${header}" varname_core)
        string(TOUPPER "${varname_core}" varname_core)
        set(varname "${ARG_VAR_PREFIX}${varname_core}${ARG_VAR_SUFFIX}")

        if(DEFINED CACHE{${varname}})
            continue()
        endif()

        message(STATUS "Looking in parallel for ${header}")

        string(APPEND c_ifdefs "#if __has_include(<${header}>)\n#define M_${varname} \"1\"\n#else\n#define M_${varname} \"0\"\n#endif\nconst char *STR_${varname} = \"INFO[${varname}=\" M_${varname} \"]\";\n")
        string(APPEND c_main_body "  result += STR_${varname}[argc];\n")
    endforeach()

    if(NOT c_ifdefs)
        return()
    endif()
    string(MD5 md5_list "${c_main_body}")

    set(src "${CMAKE_CURRENT_BINARY_DIR}/${md5_list}_parallel_checks.c")
    set(bin "${CMAKE_CURRENT_BINARY_DIR}/${md5_list}_parallel_checks_bin")

    file(WRITE "${src}" "${c_ifdefs}int main(int argc, char *argv[]) {\n  int result = 0;  \n  (void)argv;\n${c_main_body}  return result;\n}\n")
    try_compile(COMPILED "${CMAKE_CURRENT_BINARY_DIR}/tt" SOURCES "${src}"
        COPY_FILE "${bin}"
    )
    if(NOT COMPILED)
        message(FATAL_ERROR "FIXME: Failure to build -> fall back")
    endif()

    foreach(header ${ARG_HEADERS})
        string(MAKE_C_IDENTIFIER "${header}" varname_core)
        string(TOUPPER "${varname_core}" varname_core)
        set(varname "${ARG_VAR_PREFIX}${varname_core}${ARG_VAR_SUFFIX}")

        if(DEFINED CACHE{${varname}})
            continue()
        endif()

        set(re "INFO\\[${varname}=(1|0)\\]")
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

        set("${varname}" "${v}" CACHE INTERNAL "Have include ${header}")
    endforeach()
endfunction()

include(CheckIncludeFile)

function(serial_check_include_file)
    cmake_parse_arguments(ARG "" "VAR_PREFIX;VAR_SUFFIX" "HEADERS" ${ARGN})

    foreach(header ${ARG_HEADERS})
        string(MAKE_C_IDENTIFIER "${header}" varname_core)
        string(TOUPPER "${varname_core}" varname_core)
        set(varname "${ARG_VAR_PREFIX}${varname_core}${ARG_VAR_SUFFIX}")

        check_include_file("${header}" "${varname}")
    endforeach()
endfunction()

function(compare_check_things RESULT)
    set(r TRUE)
    cmake_parse_arguments(ARG "" "VAR_PREFIX;VAR_SUFFIX;VAR_PREFIX_REF;VAR_SUFFIX_REF" "THINGS" ${ARGN})

    list(LENGTH ARG_CHECKS arg_checks_length)

    set(issues)
    foreach(thing ${ARG_THINGS})
        string(MAKE_C_IDENTIFIER "${thing}" varname_core)
        string(TOUPPER "${varname_core}" varname_core)
        set(varname "${ARG_VAR_PREFIX}${varname_core}${ARG_VAR_SUFFIX}")
        set(varname_ref "${ARG_VAR_PREFIX_REF}${varname_core}${ARG_VAR_SUFFIX_REF}")

        set(got "${${varname}}")
        set(ref "${${varname_ref}}")

        if(NOT ref STREQUAL got)
            list(APPEND issues ${thing})
        endif()

        message(STATUS "ref=${ref} got=${got}          ${thing}")
    endforeach()
    if(issues)
        message(WARNING "These don't match: ${issues}")
        set(r FALSE)
    else()
        message(STATUS "All checks match!")
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
endfunction()
