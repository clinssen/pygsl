/*
 * Author : Pierre Schnizer <schnizer@users.sourceforge.net>
 */
#ifndef PyGSL_API_H
#define PyGSL_API_H 1


/*
#define PyGSL_API_UNIQUE_SYMBOL PyGSL_API
*/
/*
 * This API import trick was copied from Numeric/arrayobject.h
 */
#if defined(PyGSL_API_UNIQUE_SYMBOL)
#define PyGSL_API PyGSL_API_UNIQUE_SYMBOL
#endif

/* C API address pointer */ 
#if defined(PyGSL_NO_IMPORT_API)
extern void **PyGSL_API;
#else
#if defined(PyGSL_API_UNIQUE_SYMBOL)
void **PyGSL_API;
#else
static void **PyGSL_API;
#endif /* PyGSL_API_UNIQUE_SYMBOL */
#endif /* PyGSL_NO_IMPORT_API */


#ifndef _PyGSL_API_MODULE
#define PyGSL_API_EXTERN extern
#else /* _PyGSL_API_MODULE */
#define PyGSL_API_EXTERN static
#endif /* _PyGSL_API_MODULE */


/* zero here for historical reasons, perhaps to order them meaningfull now? */
#define PyGSL_RNG_ObjectType_NUM         0

/* Functions found in the file <pygsl/error_helpers.h> */
#define PyGSL_error_flag_NUM             1
#define PyGSL_error_flag_to_pyint_NUM    2
#define PyGSL_add_traceback_NUM          3
#define PyGSL_module_error_handler_NUM   4

#define PyGSL_error_string_for_callback_NUM   5
#define PyGSL_pyfloat_to_double_NUM           6
#define PyGSL_pylong_to_ulong_NUM             7
#define PyGSL_pylong_to_uint_NUM              8
#define PyGSL_check_python_return_NUM         9
#define PyGSL_clear_name_NUM                 10 

#define PyGSL_PyComplex_to_gsl_complex_NUM             11
#define PyGSL_PyComplex_to_gsl_complex_float_NUM       12
#define PyGSL_PyComplex_to_gsl_complex_long_double_NUM 13



#define PyGSL_stride_recalc_NUM                        14
#define PyGSL_PyArray_prepare_gsl_vector_view_NUM      15
#define PyGSL_PyArray_prepare_gsl_matrix_view_NUM      16
#define PyGSL_PyArray_generate_gsl_vector_view_NUM     17 
#define PyGSL_PyArray_generate_gsl_matrix_view_NUM     18
#define PyGSL_copy_pyarray_to_gslvector_NUM            19
#define PyGSL_copy_pyarray_to_gslmatrix_NUM            20
#define PyGSL_copy_gslvector_to_pyarray_NUM            21
#define PyGSL_copy_gslmatrix_to_pyarray_NUM            22

#define PyGSL_gsl_rng_from_pyobject_NUM                23 
#define PyGSL_function_wrap_helper_NUM                 24
#define PyGSL_NENTRIES_NUM                             25

#ifndef _PyGSL_API_MODULE
#endif /* _PyGSL_API_MODULE */

/*
 * Entries in the API. 
 * WARNING: This is the length of the entries. 
 * All Entries defined here with _NUM must be smaller than this number!!
 */


/* 
 * I define the error handler here as the api import shall also set the error 
 * handler. The error handler must be set in each module speratley as on some 
 * platforms GSL is linked statically, thus each module has its seperate error
 * gsl handler.
 * And I think the other platforms can spare these extra cycles, so I do that 
 * on all platforms.
 */
PyGSL_API_EXTERN void 
PyGSL_module_error_handler(const char *reason, /* name of function */
			   const char *file,   /* from CPP */
			   int line,           /* from CPP */
			   int gsl_error);     /* real "reason" */


#ifndef _PyGSL_API_MODULE
#define PyGSL_module_error_handler\
 (*(void (*)(const char *, const char *, int, int)) PyGSL_API[PyGSL_module_error_handler_NUM])
#endif  /* _PyGSL_API_MODULE */

#define PyGSL_SET_ERROR_HANDLER() \
        gsl_set_error_handler(&(*(void (*)(const char *, const char *, int, int))PyGSL_API[PyGSL_module_error_handler_NUM]))
        
#define init_pygsl()\
{ \
   PyObject *pygsl = NULL, *c_api = NULL, *md = NULL; \
   if ( \
      (pygsl = PyImport_ImportModule("pygsl.init"))    != NULL && \
      (md = PyModule_GetDict(pygsl))                   != NULL && \
      (c_api = PyDict_GetItemString(md, "_PYGSL_API")) != NULL && \
      (PyCObject_Check(c_api))                                    \
     ) { \
	 PyGSL_API = (void **)PyCObject_AsVoidPtr(c_api); \
         PyGSL_SET_ERROR_HANDLER(); \
         if((void *) PyGSL_SET_ERROR_HANDLER() != PyGSL_API[PyGSL_module_error_handler_NUM]){\
            fprintf(stderr, "Installation of error handler failed! In File %s\n", __FILE__); \
         }\
   } else { \
        PyGSL_API = NULL; \
        fprintf(stderr, "Import of pygsl.init Failed!!! File %s\n", __FILE__);\
   } \
} 
#endif  /*  PyGSL_API_H */
