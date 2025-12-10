cmake_minimum_required(VERSION 3.6...4.0)
project(cmake-symbol-test LANGUAGES C)

include(parse_linker_output.cmake)

include(all_in_one.cmake)

option(PARALLEL_HEADER_CHECKS "Do Parallel Header Checks" ON)
option(SERIAL_HEADER_CHECKS "Do Serial Header Checks" ON)
option(PARALLEL_LINKER_SYMBOL_CHECKS "Do linker Parallel Symbol Checks" ON)
option(SERIAL_SYMBOL_CHECKS "Do Serial Symbol Checks" ON)

set(HEADERS_TO_CHECK
    float.h         HAVE_FLOAT_H
    iconv.h         HAVE_ICONV_H
    inttypes.h      HAVE_INTTYPES_H
    limits.h        HAVE_LIMITS_H
    malloc.h        HAVE_MALLOC_H
    math.h          HAVE_MATH_H
    memory.h        HAVE_MEMORY_H
    signal.h        HAVE_SIGNAL_H
    stdarg.h        HAVE_STDARG_H
    stddef.h        HAVE_STDDEF_H
    stdint.h        HAVE_STDINT_H
    stdio.h         HAVE_STDIO_H
    stdlib.h        HAVE_STDLIB_H
    string.h        HAVE_STRING_H
    strings.h       HAVE_STRINGS_H
    sys/types.h     HAVE_SYS_TYPES_H
    time.h          HAVE_TIME_H
    wchar.h         HAVE_WCHAR_H
)

if(PARALLEL_HEADER_CHECKS)
    string(TIMESTAMP start "%s")
    parallel_check_include_file(CHECKS ${HEADERS_TO_CHECK})
    string(TIMESTAMP end "%s")
    math(EXPR dt_parhdr "${end}-${start}")
else()
    math(EXPR dt_parhdr "UNKNOWN")
endif()

if(SERIAL_HEADER_CHECKS)
    string(TIMESTAMP start "%s")
    serial_check_include_file(CHECKS ${HEADERS_TO_CHECK})
    string(TIMESTAMP end "%s")
    math(EXPR dt_serhdr "${end}-${start}")
else()
    math(EXPR dt_serhdr "UNKNOWN")
endif()

set(known_headers)
set(i 0)
list(LENGTH HEADERS_TO_CHECK len_headers)
while(i LESS len_headers)
    list(GET HEADERS_TO_CHECK "${i}" header)
    math(EXPR i "${i} + 1")
    list(GET HEADERS_TO_CHECK "${i}" var)
    math(EXPR i "${i} + 1")
    set(b ${${var}})
    if(b)
        list(APPEND known_headers "${header}")
    endif()
endwhile()

message(STATUS "known_headers: ${known_headers}")

set(SYMBOLS_TO_CHECK
    LIBC_HAS_ABS        abs         double              1
    LIBC_HAS_ACOS       acos        double              1
    LIBC_HAS_ACOSF      acosf       float               1
    LIBC_HAS_ASIN       asin        double              1
    LIBC_HAS_ASINF      asinf       float               1
    LIBC_HAS_ATAN2      atan2       double              2
    LIBC_HAS_ATAN2F     atan2f      float               2
    LIBC_HAS_ATAN       atan        double              1
    LIBC_HAS_ATANF      atanf       float               1
    LIBC_HAS_ATOF       atof        "const char *"      1
    LIBC_HAS_ATOI       atoi        "const char *"      1
    LIBC_HAS_BCOPY      bcopy       "void *"            3
    LIBC_HAS_CALLOC     calloc      "size_t"            2
    LIBC_HAS_CEIL       ceil        double              1
    LIBC_HAS_CEILF      ceilf       float               1
    LIBC_HAS_COPYSIGN   copysign    double              2
    LIBC_HAS_COPYSIGNF  copysignf   float               2
    LIBC_HAS_COS        cos         double              1
    LIBC_HAS_COSF       cosf        float               1
    LIBC_HAS__EXIT      _Exit       int                 1
    LIBC_HAS_EXP        exp         double              1
    LIBC_HAS_EXPF       expf        float               1
    LIBC_HAS_FABS       fabs        double              1
    LIBC_HAS_FABSF      fabsf       float               1
    LIBC_HAS_FLOOR      floor       double              1
    LIBC_HAS_FLOORF     floorf      float               1
    LIBC_HAS_FMOD       fmod        double              2
    LIBC_HAS_FMODF      fmodf       float               2
    LIBC_HAS_FOPEN64    fopen64     "const char *"      2
    LIBC_HAS_FREE       free        "void *"            1
    LIBC_HAS_FSEEKO     fseeko      "FILE *"            3
    LIBC_HAS_FSEEKO64   fseeko64    "FILE *"            3
    LIBC_HAS_GETENV     getenv      "const char *"      1
    LIBC_HAS_INDEX      index       "const char *"      2
    LIBC_HAS_ITOA       itoa        int                 1
    LIBC_HAS_LOG        log         double              1
    LIBC_HAS_LOGF       logf        float               1
    LIBC_HAS_LOG10      log10       double              1
    LIBC_HAS_LOG10F     log10f      float               1
    LIBC_HAS_LROUND     lround      double              1
    LIBC_HAS_LROUNDF    lroundf     float               1
    LIBC_HAS__LTOA      _ltoa       long                3
    LIBC_HAS_MALLOC     malloc      size_t              1
    LIBC_HAS_MEMCMP     memcmp      "const void *"      3
    LIBC_HAS_MEMCPY     memcpy      "void *"            3
    LIBC_HAS_MEMMOVE    memmove     "void *"            3
    LIBC_HAS_MEMSET     memset      "void *"            3
    LIBC_HAS_MODF       modf        double              2
    LIBC_HAS_MODFF      modff       float               2
    LIBC_HAS_POW        pow         double              2
    LIBC_HAS_POWF       powf        float               2
    LIBC_HAS_PUTENV     putenv      "char *"            1
    LIBC_HAS_REALLOC    realloc     "void *"            2
    LIBC_HAS_RINDEX     rindex      "const char *"      2
    LIBC_HAS_ROUND      round       double              1
    LIBC_HAS_ROUNDF     roundf      float               1
    LIBC_HAS_SCALBN     scalbn      double              2
    LIBC_HAS_SCALBNF    scalbnf     float               2
    LIBC_HAS_SETENV     setenv      "const char *"      3
    LIBC_HAS_SIN        sin         double              1
    LIBC_HAS_SINF       sinf        float               1
    #LIBC_HAS_SQR       sqr         XXX                 XXXX
    LIBC_HAS_SQRT       sqrt        double              1
    LIBC_HAS_SQRTF      sqrtf       float               1
    LIBC_HAS_STRCHR     strchr      "const char *"      2
    LIBC_HAS_STRCMP     strcmp      "const char *"      2
    LIBC_HAS_STRLCAT    strlcat     "char *"            3
    LIBC_HAS_STRLCPY    strlcpy     "char *"            3
    LIBC_HAS_STRLEN     strlen      "const char *"      1
    LIBC_HAS_STRNCMP    strncmp     "const char *"      3
    LIBC_HAS_STRNLEN    strnlen     "const char *"      2
    LIBC_HAS_STRRCHR    strrchr     "const char *"      2
    LIBC_HAS_STRSTR     strstr      "const char *"      2
    LIBC_HAS_STRNSTR    strnstr     "const char *"      3
    LIBC_HAS_STRTOD     strtod      "const char *"      2
    LIBC_HAS_STRTOK_R   strtok_r    "char *"            3
    LIBC_HAS_STRTOL     strtol      "const char *"      3
    LIBC_HAS_STRTOLL    strtoll     "const char *"      3
    LIBC_HAS_STRTOUL    strtoul     "const char *"      3
    LIBC_HAS_STRTOULL   strtoull    "const char *"      3
    LIBC_HAS_TAN        tan         double              1
    LIBC_HAS_TANF       tanf        float               1
    LIBC_HAS_TRUNC      trunc       double              1
    LIBC_HAS_TRUNCF     truncf      float              1
    LIBC_HAS_UNSETENV   unsetenv    "const char *"      1
    LIBC_HAS_WCSNLEN    wcsnlen     "const wchar_t *"   2
    LIBC_HAS_WCSCMP     wcscmp      "const wchar_t *"   2
    LIBC_HAS_WCSDUP     wcsdup      "const wchar_t *"   1
    LIBC_HAS_WCSLCAT    wcslcat     "wchar_t *"         3
    LIBC_HAS_WCSLCPY    wcslcpy     "wchar_t *"         3
    LIBC_HAS_WCSLEN     wcslen      "const wchar_t *"   1
    LIBC_HAS_WCSNCMP    wcsncmp     "const wchar_t *"   3
    LIBC_HAS_WCSSTR     wcsstr      "const wchar_t *"   2
    LIBC_HAS_WCSTOL     wcstol      "const wchar_t *"   3
)
set(i 0)
list(LENGTH SYMBOLS_TO_CHECK LEN_SYMBOLS_TO_CHECK)
set(SYMBOLS )
while (i LESS LEN_SYMBOLS_TO_CHECK)
    math(EXPR symbol_index "${i} + 1")
    list(GET SYMBOLS_TO_CHECK "${symbol_index}" symbol)
    math(EXPR i "${i} + 4")
    list(APPEND SYMBOLS "${symbol}")
endwhile()

if(PARALLEL_LINKER_SYMBOL_CHECKS)
    string(TIMESTAMP start "%s")
    check_symbols_in_parallel(
        VAR_PREFIX LIBC_HAS_
        VAR_SUFFIX _LINKER
        VAR_UPPER
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
    serial_check_c_symbol_exists(HEADERS ${known_headers} CHECKS ${SYMBOLS_TO_CHECK})
    string(TIMESTAMP end "%s")
    math(EXPR dt_sersym "${end}-${start}")
else()
    math(EXPR dt_sersym "UNKNOWN")
endif()

if(PARALLEL_HEADER_CHECKS AND SERIAL_HEADER_CHECKS)
    compare_check_include_file(${HEADERS_TO_CHECK})
endif()

if(PARALLEL_LINKER_SYMBOL_CHECKS AND SERIAL_SYMBOL_CHECKS)
    compare_check_symbol_checks(
        VAR_PREFIX LIBC_HAS_
        SYMBOLS ${SYMBOLS}
    )
endif()

message(STATUS "parallel header:         ${dt_parhdr}s")
message(STATUS "serial header:           ${dt_serhdr}s")
message(STATUS "parallel C++ symbols:    ${dt_parsym}s")
message(STATUS "serial symbols:          ${dt_sersym}s")
message(STATUS "parallel linker symbols: ${dt_parsym}s")
