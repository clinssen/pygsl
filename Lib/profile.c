/*
  One dimensional Python array can be directly passed to
  vectors. If not a function will be invoked. If it has 
  to work on the array it will increase this counter via
  PyGSL_INCREASE_vector_transform_counter
 */
int pygsl_profile_vector_transform_counter = 0;
/*
 * Two dimensional Python array can be directly passed to
 * matrices, if they are contingous. (Currently not performed )
 * If not a function will be invoked. If it has 
 * to work on the array it will increase this counter via
 * INCREASE_matrix_transform_counter
 */
int pygsl_profile_matrix_transform_counter = 0;

/*
 * From a mathematical point of view 0 is also a legal 
 * complex number. (YMMV;-) Complex objects are 
 * transferred directly  to  the underlying  function,
 * whereas other numeric objects have to  be converted. 
 * In that case this counter is increased. via 
 * 
 */
int pygsl_profile_complex_transform_counter = 0;

/*
 * From a mathematical point of view 0 is also a legal 
 * float. Float objects are 
 * transferred directly  to  the underlying  function,
 * whereas other numeric objects have to  be converted. 
 * In that case this counter is increased. via 
 * 
 */
int pygsl_profile_float_transform_counter = 0;
