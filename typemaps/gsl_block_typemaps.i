/* -*- C -*- */
/**
 * Author: Pierre Schnizer 
 * Date  : December 2002
 * 
 * Changelog: 22. May 2002
 *            Update to use libpygsl
 */
/*
 * Typemaps to translate python arrays to gsl vectors and matrices. For 
 * matrices
 * only contingous numpy arrays need no copy. For vectors non contigous arrays 
 * are handled as well.
 * These typemaps suppose, that you define your arrays as IN, INOUT, 
 * IN_ONLY_SIZE, IN_SIZE_OUT. The default is subject to discussion.
 *
 * All element access  of gsl vectors and matrices uses gsl_matrix_get or 
 * gsl_vector_get. When this interface has settled one could define 
 * GSL_RANGE_CHECK_OFF.
 *
 */
/* ------------------------------------------------------------------------- */
/* ------------------------------------------------------------------------- */
/*   Helper Functions                                                        */
/* ------------------------------------------------------------------------- */
/* ------------------------------------------------------------------------- */
%{
#include <pygsl/utils.h>
#include <pygsl/block_helpers.h>
#include <typemaps/convert_block_description.h>
#include <string.h>
#include <assert.h>
%}
/*
 * Unfortunatley swig1.1 appended a blank to its variables. These typemaps make
 * heavy use of $basetype to map it to the corresponding gsl_types. So I have 
 * to #DEFINE a lot of names to allow that usage. I don't want to repeat the
 * same  wrapper for each type. Up to now the following correspondance exist
 * (They are illustrated for gsl_vector)
 *
 *     TO_PyArray_TYPE_gsl_vector 		    PyArray_DOUBLE
 *     TYPE_VIEW_$basetype       -> gsl_vector_view
 *     TYPE_VIEW_ARRAY$basetype  -> gsl_vector_view_array
 *
 * As swig 1.3 does not append a blank any more, many defines can vanish,
 * for the coorespondence between the vectors and their basis type the defines
 * will allways be needed.
 * These defines are to be found in convert_block_description.h. The file is 
 * generated by the script c.py (which is a hack and unreadable. I have to 
 * rewrite it.)
 */

/* ------------------------------------------------------------------------- */
/* ------------------------------------------------------------------------- */
/*   Typemaps to translate pyarrays to gsl_vectors.                          */
/* ------------------------------------------------------------------------- */
/* ------------------------------------------------------------------------- */
%typemap(arginit) gsl_vector *  %{
	  PyArrayObject * volatile _PyVector$argnum = NULL;
     	  TYPE_VIEW_$1_basetype _vector$argnum;
%}
%typemap(in) gsl_vector * IN  %{
     {
   
	  PyArrayObject * a_array;
	  int stride_recalc=0;

	  FUNC_MESS_BEGIN();
	  _PyVector$argnum = PyGSL_PyArray_PREPARE_gsl_vector_view($input, 
						TO_PyArray_TYPE_$1_basetype, 
						0, -1, $argnum, NULL);
	  if(_PyVector$argnum == NULL) goto fail;
	  a_array = _PyVector$argnum;

	  if(PyGSL_STRIDE_RECALC(a_array->strides[0],sizeof(BASIS_TYPE_$1_basetype), &stride_recalc) != GSL_SUCCESS)
	       goto fail;
	  
	  _vector$argnum  = TYPE_VIEW_ARRAY_STRIDES_$1_basetype(
                                    (BASIS_TYPE_C_$1_basetype *) a_array->data,
				    stride_recalc,
				    a_array->dimensions[0]);

	  $1 = ($basetype *) &(_vector$argnum.vector);
     }
%}

/* ------------------------------------------------------------------------- */
/*
 * There are some functions which set the values of the vector. So one would
 * like them to mimic Numeric.ones and the like ...
 */
%typemap(in) gsl_vector * IN_ONLY_SIZE %{
     {
	  PyArrayObject * a_array;

	  int stride_recalc=0;

	  FUNC_MESS_BEGIN();
	  _PyVector$argnum = PyGSL_PyArray_generate_gsl_vector_view($input, 
						TO_PyArray_TYPE_$1_basetype, 
								    $argnum);
	  if(_PyVector$argnum == NULL) goto fail;
	  a_array = _PyVector$argnum;
	  assert(a_array != NULL);
	  if(PyGSL_STRIDE_RECALC(a_array->strides[0],sizeof(BASIS_TYPE_$1_basetype), &stride_recalc) != GSL_SUCCESS)
	       goto fail;

	  _vector$argnum  = TYPE_VIEW_ARRAY_STRIDES_$1_basetype(
	                           (BASIS_TYPE_C_$1_basetype *) a_array->data, 
				   stride_recalc,
				   a_array->dimensions[0]);
	  $1 = ($basetype *) &(_vector$argnum.vector);

     }
%}
/* ------------------------------------------------------------------------- */

/*
 * Attention! To allow the intermix of these typemaps that's absolutely 
 * necessary, as freearg is called afterwards and would free the memory 
 * again. That way all can be intermixed without problem. Just think pure
 * input. This here would not be called so freearg has to free the memory.
 */
%typemap( argout) gsl_vector * INOUT {
     assert(_PyVector$argnum != NULL);

     $result = t_output_helper($result,  PyArray_Return(_PyVector$argnum));
     _PyVector$argnum = NULL;
     FUNC_MESS_END();
}
/* ------------------------------------------------------------------------- */
%typemap( freearg) gsl_vector * {
  Py_XDECREF(_PyVector$argnum);
  _PyVector$argnum = NULL;
  FUNC_MESS_END();
}
/* ------------------------------------------------------------------------- */
/* ------------------------------------------------------------------------- */
%typemap(out) gsl_vector_view {
     PyArrayObject * out = NULL;
     BASIS_TYPE_$1_basetype tmp; 
     int i, dimension = -1;

     FUNC_MESS_BEGIN();
     DEBUG_MESS(4, "Copying vector %p with a size of %d and data at %p *(char * data) %d",
		&($1.vector), $1.vector.size, $1.vector.data, *((char *)$1.vector.data));
     dimension = $1.vector.size;
     DEBUG_MESS(2, "Creating a vector of length %d", dimension);
     assert(dimension > 0);
     out = (PyArrayObject *) PyArray_FromDims(1, &dimension, 
					      TO_PyArray_TYPE_$basetype);
     if(out == NULL) goto fail;
     DEBUG_MESS(2, "Size of BasisType = %d, stride = %d", sizeof(tmp), 
		out->strides[0]);
     assert(dimension == out->dimensions[0]);
     FUNC_MESS("Copying vector to PyArray");     
     /* Should I copy the array now? Increase the reference of a_array ? */
     for(i=0; i<out->dimensions[0]; i++){
	  DEBUG_MESS(2, "Writing element %d", i);
	  tmp = GET_$1_basetype(&($1.vector), i);
	  DEBUG_MESS(2, "Writing element %p", (void *)&tmp);
	  ((BASIS_TYPE_$1_basetype *) out->data)[i] = tmp;

	  FUNC_MESS("Element written");
     }

     $result = PyArray_Return(out);
     FUNC_MESS_END();
}
/* ------------------------------------------------------------------------- */
/* ------------------------------------------------------------------------- */
/* ------------------------------------------------------------------------- */
/*   Typemaps to translate pyarrays to gsl_matrix.                           */
/* ------------------------------------------------------------------------- */
/* ------------------------------------------------------------------------- */
/* ------------------------------------------------------------------------- */
%typemap(arginit) gsl_matrix *  %{
	  PyArrayObject * _PyMatrix$argnum = NULL;
	  TYPE_VIEW_$1_basetype _matrix$argnum;
%}

%typemap(in) gsl_matrix * IN  %{
     {
	  PyArrayObject * a_array;

	  FUNC_MESS_BEGIN();
	  _PyMatrix$argnum = PyGSL_PyArray_PREPARE_gsl_matrix_view(
	       $input, TO_PyArray_TYPE_$1_basetype, 1, -1, -1, $argnum, NULL);
	  a_array = _PyMatrix$argnum;
	  if (a_array == NULL) goto fail;
	  
	  _matrix$argnum  = TYPE_VIEW_ARRAY_$basetype(
	       (BASIS_TYPE_C_$basetype *) a_array->data, 
	       a_array->dimensions[0],
	       a_array->dimensions[1]);
	  $1 = &(_matrix$argnum.matrix);
	  DEBUG_MESS(2, "Matrix at %p", (void *) (_matrix$argnum.matrix.data));
     }
%}
/* ------------------------------------------------------------------------- */
/*
 * There are some functions which set the values of the matrix. So one would
 * like them to mimic Numeric.ones and the like ...
 */
%typemap(in) gsl_matrix * IN_ONLY_SIZE  {
	  PyArrayObject * a_array;
	  FUNC_MESS_BEGIN();
	  _PyMatrix$argnum = PyGSL_PyArray_generate_gsl_matrix_view(
	       $input, TO_PyArray_TYPE_$1_basetype, $argnum);
	  a_array = _PyMatrix$argnum;
	  if (a_array == NULL) goto fail;
	  
	  _matrix$argnum  = TYPE_VIEW_ARRAY_$basetype(
	       (BASIS_TYPE_C_$basetype *) a_array->data, 
	       a_array->dimensions[0],
	       a_array->dimensions[1]);
	  $1 = &(_matrix$argnum.matrix);	  
}
/* ------------------------------------------------------------------------- */
/*
 * Attention! To allow the intermix of these typemaps that's absolutely 
 * necessary, as freearg is called afterwards and would free the memory 
 * again. That way all can be intermixed without problem. Just think pure
 * input. This here would not be called so freearg has to free the memory.
 */
%typemap( argout) gsl_matrix * INOUT {
     assert((PyObject *) _PyMatrix$argnum != NULL);
     $result = t_output_helper($result,  PyArray_Return(_PyMatrix$argnum));
     _PyMatrix$argnum = NULL;
     FUNC_MESS_END();
}
%typemap( freearg) gsl_matrix * {
     Py_XDECREF(_PyMatrix$argnum);
     _PyMatrix$argnum = NULL;
     FUNC_MESS_END();
}
/* ------------------------------------------------------------------------- */
%typemap(arginit) gsl_vector * INOUT        = gsl_vector * ;
%typemap(arginit) gsl_vector * IN           = gsl_vector * ;
%typemap(in)      gsl_vector * INOUT        = gsl_vector * IN;
%typemap(in)      gsl_vector * IN_SIZE_OUT  = gsl_vector * IN_ONLY_SIZE;
%typemap(argout)  gsl_vector * IN_SIZE_OUT  = gsl_vector * INOUT;
%typemap(out)     gsl_vector = gsl_vector_view;

/* ------------------------------------------------------------------------- */
%typemap(arginit) gsl_matrix * INOUT        = gsl_matrix * ;
%typemap(arginit) gsl_matrix * IN           = gsl_matrix * ;
%typemap(in)      gsl_matrix * INOUT        = gsl_matrix * IN;
%typemap(in)      gsl_matrix * IN_SIZE_OUT  = gsl_matrix * IN_ONLY_SIZE;
%typemap(argout)  gsl_matrix * IN_SIZE_OUT  = gsl_matrix * INOUT;
%typemap(freearg) gsl_matrix * INOUT        = gsl_matrix *;
%typemap(freearg) gsl_matrix * IN           = gsl_matrix *;
%typemap(freearg) gsl_matrix * IN_SIZE_OUT  = gsl_matrix *;
%typemap(freearg) gsl_matrix * IN_ONLY_SIZE = gsl_matrix *;

/* ------------------------------------------------------------------------- */
/*              DEFAULT BEHAVIOUR                                            */
/* ------------------------------------------------------------------------- */
/*   Make IN the default behaviour  for const                                */   
%apply gsl_vector  * IN          {const gsl_vector               *,
				  const gsl_vector_complex       *, 
				  const gsl_vector_complex_float *, 
                                  const gsl_vector_float         *, 
                                  const gsl_vector_long          *, 
                                  const gsl_vector_int           *, 
                                  const gsl_vector_short         *, 
                                  const gsl_vector_char          *};
%apply gsl_matrix  * IN          {const gsl_matrix               *,
				  const gsl_matrix_complex       *, 
				  const gsl_matrix_complex_float *, 
                                  const gsl_matrix_float         *, 
                                  const gsl_matrix_long          *, 
                                  const gsl_matrix_int           *, 
                                  const gsl_matrix_short         *, 
                                  const gsl_matrix_char          *};

/*   Make INOUT the default behaviour                                        */   
%apply gsl_vector  * IN          {gsl_vector               *,
				  gsl_vector_complex       *, 
				  gsl_vector_complex_float *, 
                                  gsl_vector_float         *, 
                                  gsl_vector_long          *, 
                                  gsl_vector_int           *, 
                                  gsl_vector_short         *, 
                                  gsl_vector_char          *};
%apply gsl_matrix  * IN          {gsl_matrix               *,
				  gsl_matrix_complex       *, 
				  gsl_matrix_complex_float *, 
                                  gsl_matrix_float         *, 
                                  gsl_matrix_long          *, 
                                  gsl_matrix_int           *, 
                                  gsl_matrix_short         *, 
                                  gsl_matrix_char          *};

/* ------------------------------------------------------------------------- */

/*
%apply gsl_vector *              {gsl_vector_complex       *, 
				  gsl_vector_complex_float *, 
                                  gsl_vector_float         *, 
                                  gsl_vector_long          *, 
                                  gsl_vector_int           *, 
                                  gsl_vector_short         *, 
                                  gsl_vector_char          *};
*/
%apply gsl_vector_view           {gsl_vector_complex_view       , 
				  gsl_vector_complex_float_view , 
                                  gsl_vector_float_view         , 
                                  gsl_vector_long_view          , 
                                  gsl_vector_int_view           , 
                                  gsl_vector_short_view         , 
                                  gsl_vector_char_view          };
%apply gsl_vector * IN_SIZE_OUT  {gsl_vector_complex       * IN_SIZE_OUT, 
				  gsl_vector_complex_float * IN_SIZE_OUT, 
                                  gsl_vector_float         * IN_SIZE_OUT, 
                                  gsl_vector_long          * IN_SIZE_OUT, 
                                  gsl_vector_int           * IN_SIZE_OUT, 
                                  gsl_vector_short         * IN_SIZE_OUT, 
                                  gsl_vector_char          * IN_SIZE_OUT};
%apply gsl_vector * IN_ONLY_SIZE {gsl_vector_complex       * IN_ONLY_SIZE, 
				  gsl_vector_complex_float * IN_ONLY_SIZE, 
                                  gsl_vector_float         * IN_ONLY_SIZE, 
                                  gsl_vector_long          * IN_ONLY_SIZE, 
                                  gsl_vector_int           * IN_ONLY_SIZE, 
                                  gsl_vector_short         * IN_ONLY_SIZE, 
                                  gsl_vector_char          * IN_ONLY_SIZE};
%apply gsl_vector * INOUT        {gsl_vector_complex       * INOUT, 
				  gsl_vector_complex_float * INOUT, 
                                  gsl_vector_float         * INOUT, 
                                  gsl_vector_long          * INOUT, 
                                  gsl_vector_int           * INOUT, 
                                  gsl_vector_short         * INOUT, 
                                  gsl_vector_char          * INOUT};
%apply gsl_vector * IN           {gsl_vector_complex       * IN, 
				  gsl_vector_complex_float * IN, 
                                  gsl_vector_float         * IN, 
                                  gsl_vector_long          * IN, 
                                  gsl_vector_int           * IN, 
                                  gsl_vector_short         * IN, 
                                  gsl_vector_char          * IN};

/*
%apply gsl_matrix *              {gsl_matrix_complex       *, 
				  gsl_matrix_complex_float *, 
                                  gsl_matrix_float         *, 
                                  gsl_matrix_long          *, 
                                  gsl_matrix_int           *, 
                                  gsl_matrix_short         *, 
                                  gsl_matrix_char          *};
*/
%apply gsl_matrix * IN_SIZE_OUT  {gsl_matrix_complex       * IN_SIZE_OUT, 
				  gsl_matrix_complex_float * IN_SIZE_OUT, 
                                  gsl_matrix_float         * IN_SIZE_OUT, 
                                  gsl_matrix_long          * IN_SIZE_OUT, 
                                  gsl_matrix_int           * IN_SIZE_OUT, 
                                  gsl_matrix_short         * IN_SIZE_OUT, 
                                  gsl_matrix_char          * IN_SIZE_OUT};
%apply gsl_matrix * IN_ONLY_SIZE {gsl_matrix_complex       * IN_ONLY_SIZE, 
				  gsl_matrix_complex_float * IN_ONLY_SIZE, 
                                  gsl_matrix_float         * IN_ONLY_SIZE, 
                                  gsl_matrix_long          * IN_ONLY_SIZE, 
                                  gsl_matrix_int           * IN_ONLY_SIZE, 
                                  gsl_matrix_short         * IN_ONLY_SIZE, 
                                  gsl_matrix_char          * IN_ONLY_SIZE};
%apply gsl_matrix * INOUT        {gsl_matrix_complex       * INOUT, 
				  gsl_matrix_complex_float * INOUT, 
                                  gsl_matrix_float         * INOUT, 
                                  gsl_matrix_long          * INOUT, 
                                  gsl_matrix_int           * INOUT, 
                                  gsl_matrix_short         * INOUT, 
                                  gsl_matrix_char          * INOUT};
%apply gsl_matrix * IN           {gsl_matrix_complex       * IN, 
				  gsl_matrix_complex_float * IN, 
                                  gsl_matrix_float         * IN, 
                                  gsl_matrix_long          * IN, 
                                  gsl_matrix_int           * IN, 
                                  gsl_matrix_short         * IN, 
                                  gsl_matrix_char          * IN};

/* EOF */
