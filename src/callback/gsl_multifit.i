/* -*- C -*- */
/**
 * author: Pierre Schnizer
 */
%{
#include <gsl/gsl_multifit.h>
#include <gsl/gsl_fit.h>
#include <gsl/gsl_matrix.h>
#include <gsl/gsl_vector.h>
%}
%include typemaps.i
%include gsl_block_typemaps.i

gsl_multifit_linear_workspace *
gsl_multifit_linear_alloc (size_t n, size_t p);

void
gsl_multifit_linear_free (gsl_multifit_linear_workspace * work);

%typemap(arginit) gsl_multifit_linear_workspace * work_provide %{
     int _work_provide_n_$1_name = -1;
     int _work_provide_p_$1_name = -1;
%}
%typemap( in) gsl_multifit_linear_workspace *  work_provide {
     if ((SWIG_ConvertPtr($input, (void **) &$1, SWIGTYPE_p_gsl_multifit_linear_workspace,1)) == -1){
	  goto fail;
     }
     _work_provide_n_$1_name = (int) $1->n;
     _work_provide_p_$1_name = (int) $1->p;
};
%typemap( in, numinputs = 0) gsl_vector * OUT %{
     /* All done in check as the workspace stores the information about the required size */
%}
%typemap(check) gsl_vector * OUT {
	  PyArrayObject * a_array;

	  int stride_recalc=0;

	  a_array = (PyArrayObject *) PyArray_FromDims(1, &_work_provide_n_work_provide, PyArray_DOUBLE);
	  if(NULL == a_array){
	       return NULL;
	  }
	  a_array = _PyVector$argnum;

	  /* Numpy calculates strides in bytes, gsl in basis type */
	  stride_recalc = a_array->strides[0] / sizeof(BASIS_TYPE_$1_basetype);
	  assert(a_array->strides[0] % sizeof(BASIS_TYPE_$1_basetype) == 0);

	  _vector$argnum  = TYPE_VIEW_ARRAY_STRIDES_$1_basetype((BASIS_TYPE_C_$1_basetype *) a_array->data, 
								stride_recalc,
								a_array->dimensions[0]);

	  $1 = ($basetype *) &(_vector$argnum.vector);
}
%typemap( in) gsl_matrix * OUT = gsl_vector * OUT;
%typemap(check) gsl_matrix * OUT {
	  PyArrayObject * a_array;

	  int stride_recalc=0, dimensions[2];
	  dimensions[0] = _work_provide_n_work_provide;
	  dimensions[1] = _work_provide_p_work_provide;
	  a_array = (PyArrayObject *) PyArray_FromDims(2, dimensions, PyArray_DOUBLE);
	  if(NULL == a_array){
	       return NULL;
	  }
	  _PyMatrix$argnum = a_array;

	  /* Numpy calculates strides in bytes, gsl in basis type */
	  stride_recalc = a_array->strides[0] / sizeof(BASIS_TYPE_$1_basetype);
	  assert(a_array->strides[0] % sizeof(BASIS_TYPE_$1_basetype) == 0);

	  assert(a_array != NULL);
	  assert(stride_recalc == 1);
	  /* (BASIS_TYPE_$1_basetype *) */
	  _matrix$argnum  = TYPE_VIEW_ARRAY_$1_basetype((BASIS_TYPE_C_$1_basetype *) a_array->data, 
							a_array->dimensions[0], a_array->dimensions[1]);

	  $1 = ($basetype *) &(_matrix$argnum.matrix);
}

/* ---------------------------------------------------------------------- */
/* 
 *  A typemap for translating numpy arrays to the least squares 
 *  representation.
 *
 * The length of vector x establishes the reference. All others check 
 * their length to this vector. So if you apply this typemap it will
 * fail if no variable was named x!!!
 *
 *
 */

%typemap(arginit) (double *, size_t ) %{
     PyArrayObject *_PyVector$argnum = NULL;
     size_t         _PyVectorLength$1_name   = 0; 
%}

%typemap(in)  (double * ,  size_t ){
     /* This should be a preprocessor diretive. */
     if ( '$1_name' == 'x' )
	  _PyVector$argnum = PyGSL_PyArray_PREPARE_gsl_vector_view($input, PyArray_DOUBLE, 0, -1, $argnum, NULL);
     else
	  _PyVector$argnum = PyGSL_PyArray_PREPARE_gsl_vector_view($input, PyArray_DOUBLE, 0, _PyVectorLengthx , $argnum, NULL);
     
     if (_PyVector$argnum == NULL)
	  goto fail;
     $1 = (double *) (_PyVector$argnum->data);
     $2 = (size_t) _PyVector$argnum->strides[0]/sizeof(double);
     _PyVectorLength$1_name = (size_t) _PyVector$argnum->dimensions[0];
};
%typemap(argout) (double *, size_t ) {
     Py_XDECREF(_PyVector$argnum);
};

%typemap( in, numinputs=0) const size_t n {
     $1 = 0;
};

%typemap(check) const size_t n {
     $1 = _PyVectorLengthx;
};

%apply double * OUTPUT {double * c0, 
                       double * c1, 
		       double * cov00, 
                       double * cov01, 
                       double * cov11, 
		       double * sumsq,
		       double * chisq};

int
gsl_multifit_linear (const gsl_matrix * IN,
                     const gsl_vector * IN,
                     gsl_vector * OUT,
                     gsl_matrix * OUT,
                     double * chisq,
                     gsl_multifit_linear_workspace * work_provide);

int
gsl_multifit_wlinear (const gsl_matrix * IN,
                      const gsl_vector * IN,
                      const gsl_vector * IN,
                      gsl_vector * OUT,
                      gsl_matrix * OUT,
                      double * chisq,
                      gsl_multifit_linear_workspace * work_provide);




%apply (double *, size_t){(const double * x, const size_t xstride),
			  (const double * y, const size_t ystride),
			  (const double * w, const size_t wstride)
			 };
/* ---------------------------------------------------------------------- */		       
int gsl_fit_linear (const double * x, const size_t xstride,
                    const double * y, const size_t ystride,
                    const size_t n,
                    double * c0, double * c1, 
                    double * cov00, double * cov01, double * cov11, 
                    double * sumsq);


int gsl_fit_wlinear (const double * x, const size_t xstride,
                     const double * w, const size_t wstride,
                     const double * y, const size_t ystride,
                     const size_t n,
                     double * c0, double * c1, 
                     double * cov00, double * cov01, double * cov11, 
                     double * chisq);

%apply double * OUTPUT {double * y, 
			double * y_err} 

int
gsl_fit_linear_est (const double x, 
                    const double c0, const double c1, 
                    const double c00, const double c01, const double c11,
                    double *y, double *y_err);


int gsl_fit_mul (const double * x, const size_t xstride,
                 const double * y, const size_t ystride,
                 const size_t n,
                 double * c1, 
                 double * cov11, 
                 double * sumsq);

int gsl_fit_wmul (const double * x, const size_t xstride,
                  const double * w, const size_t wstride,
                  const double * y, const size_t ystride,
                  const size_t n,
                  double * c1, 
                  double * cov11, 
                  double * sumsq);


int
gsl_fit_mul_est (const double x, 
                 const double c1, 
                 const double c11,
                 double *y, double *y_err);


/*
int gsl_fit_poly (const double * x, 
                  const double * w,
                  const double * y, 
                  size_t n,
                  double * c, size_t m,
                  double * chisq);

int gsl_fit_fns (const double * A, 
                 const double * w,
                 const double * y, 
                 size_t n,
                 double * c, size_t m,
                 double * chisq);

int gsl_fit_linear_nd (double * m, double * y, double * w);
*/
