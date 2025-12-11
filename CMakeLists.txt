cmake_minimum_required(VERSION 3.6...4.0)
project(cmake-symbol-test LANGUAGES C)

include(parse_linker_output.cmake)

include(all_in_one.cmake)

option(PARALLEL_HEADER_CHECKS "Do Parallel Header Checks" ON)
option(SERIAL_HEADER_CHECKS "Do Serial Header Checks" ON)
option(PARALLEL_LINKER_SYMBOL_CHECKS "Do linker Parallel Symbol Checks" ON)
option(SERIAL_SYMBOL_CHECKS "Do Serial Symbol Checks" ON)

set(HEADERS
    float.h
    iconv.h
    inttypes.h
    limits.h
    malloc.h
    math.h
    memory.h
    signal.h
    stdarg.h
    stddef.h
    stdint.h
    stdio.h
    stdlib.h
    string.h
    strings.h
    sys/types.h
    time.h
    wchar.h
)

if(PARALLEL_HEADER_CHECKS)
    message(STATUS "Doing Parallel Header Checks:")
    string(TIMESTAMP start "%s")
    parallel_check_include_file(HEADERS ${HEADERS} VAR_PREFIX "HAVE_" VAR_SUFFIX "_INCLUDED")
    string(TIMESTAMP end "%s")
    math(EXPR dt_parhdr "${end}-${start}")
else()
    math(EXPR dt_parhdr "UNKNOWN")
endif()

if(SERIAL_HEADER_CHECKS)
    message(STATUS "Doing Serial Header Checks:")
    string(TIMESTAMP start "%s")
    serial_check_include_file(HEADERS ${HEADERS} VAR_PREFIX "HAVE_" VAR_SUFFIX "_REFERENCE")
    string(TIMESTAMP end "%s")
    math(EXPR dt_serhdr "${end}-${start}")
else()
    math(EXPR dt_serhdr "UNKNOWN")
endif()

set(known_headers)
foreach(header ${HEADERS})
    string(MAKE_C_IDENTIFIER "${header}" varname_core)
    string(TOUPPER "${varname_core}" varname_core)
    set(varname "HAVE_${varname_core}_REFERENCE")
    set(b ${${varname}})
    if(b)
        list(APPEND known_headers "${header}")
    endif()
endforeach()

message(STATUS "Known headers: ${known_headers}")

set(SYMBOLS
    abs acos acosf asin asinf atan atan2 atan2f atanf atof atoi
    bcopy
    ceil ceilf copysign copysignf cos cosf
    _Exit exp expf
    fabs fabsf floor floorf fmod fmodf fopen64 fseeko fseeko64
    getenv
    _i64toa index itoa
    log log10 log10f logf lround lroundf _ltoa
    malloc memcmp memcpy memmove memset modf modff
    pow powf putenv
    rindex round roundf
    scalbn scalbnf setenv sin sinf sqr sqrt sqrtf sscanf strchr
    strcmp strlcat strlcpy strlen strncmp strnlen strpbrk
    strrchr strstr strnstr strtod strtok_r strtol strtoll strtoul strtoull
    tan tanf trunc truncf
    unsetenv
    vsnprintf vsscanf
    wcsnlen wcscmp wcsdup wcslcat wcslcpy wcslen wcsncmp wcsstr wcstol

    _copysign _fseeki64 _strrev _ui64toa _uitoa _ultoa _wcsdup
    strcasestr
)

if(PARALLEL_LINKER_SYMBOL_CHECKS)
    string(TIMESTAMP start "%s")
    check_symbols_in_parallel(RESULT
        VAR_PREFIX LIBC_HAS_
        VAR_SUFFIX _LINKER
        HEADERS ${known_headers}
        SYMBOLS ${SYMBOLS}
    )
    string(TIMESTAMP end "%s")
    math(EXPR dt_parldsym "${end}-${start}")
else()
    math(EXPR dt_parldsym "UNKNOWN")
endif()

if(SERIAL_SYMBOL_CHECKS)
    string(TIMESTAMP start "%s")
    if(CMAKE_C_COMPILER_ID MATCHES "(GNU|Clang|AppleClang)")
        list(APPEND CMAKE_REQUIRED_LIBRARIES "m")
    endif()
    serial_check_c_symbol_exists(HEADERS ${known_headers} SYMBOLS ${SYMBOLS} PREFIX "LIBC_HAS_" SUFFIX "_REFERENCE")
    string(TIMESTAMP end "%s")
    math(EXPR dt_sersym "${end}-${start}")
else()
    math(EXPR dt_sersym "UNKNOWN")
endif()

set(RESULT_HEADERS TRUE)
if(PARALLEL_HEADER_CHECKS AND SERIAL_HEADER_CHECKS)
    compare_check_things(RESULT_HEADERS
        VAR_PREFIX_REF HAVE_       VAR_SUFFIX_REF _REFERENCE
        VAR_PREFIX     HAVE_       VAR_SUFFIX     _INCLUDED
        THINGS ${HEADERS}
    )
endif()

set(RESULT_SYMBOLS TRUE)
if(PARALLEL_LINKER_SYMBOL_CHECKS AND SERIAL_SYMBOL_CHECKS)
    compare_check_things(RESULT_SYMBOLS
        VAR_PREFIX_REF LIBC_HAS_   VAR_SUFFIX_REF _REFERENCE
        VAR_PREFIX     LIBC_HAS_   VAR_SUFFIX     _LINKER
        THINGS ${SYMBOLS}
    )
endif()

message(STATUS "parallel header:         ${dt_parhdr}s")
message(STATUS "serial header:           ${dt_serhdr}s")
message(STATUS "parallel C++ symbols:    ${dt_parsym}s")
message(STATUS "serial symbols:          ${dt_sersym}s")
message(STATUS "parallel linker symbols: ${dt_parsym}s")

if(NOT RESULT_HEADERS OR NOT RESULT_SYMBOLS)
    message(FATAL_ERROR "Something did not match :(")
endif()
