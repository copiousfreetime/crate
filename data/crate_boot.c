#include <stdlib.h>
#include <getopt.h>
#include <ruby.h>

/** from ruby's original main.c **/
#if defined(__MACOS__) && defined(__MWERKS__)
#include <console.h>
#endif

#define CRATE_MAIN_FILE   "application.rb"
#define CRATE_MAIN_CLASS  "App"
#define CRATE_RUN_METHOD  "run"

struct crate_app {
  char  *file_name;
  char  *class_name;
  VALUE  app_instance;
  char  *method_name;
  ID     run_method;
} ;

typedef struct crate_app crate_app; 

/* crate 'secret' options */
static struct option longopts[] = {
  { "crate-file",   required_argument, NULL, 1 },
  { "crate-class",  required_argument, NULL, 2 },
  { "crate-method", required_argument, NULL, 3 },
  { NULL,           0,                 NULL, 0 }
};

int crate_init_from_options(crate_app *ca, int argc, char** argv )
{
  int ch ;
  int done = 0;

  ca->file_name   = CRATE_MAIN_FILE;
  ca->class_name  = CRATE_MAIN_CLASS;
  ca->method_name = CRATE_RUN_METHOD;
    
  while ( !done && (ch = getopt_long( argc, argv, "", longopts, NULL ) ) != 1 ) {
    switch ( ch ) {
    case 1:
      ca->file_name = optarg;
      break;

    case 2:
      ca->class_name = optarg;
      break;

    case 3:
      ca->method_name = optarg;
      break;

    default:
      done = 1;
      break;
    }
  }
  
  return optind;
}

/**
 * Make the actual application call, we call the application instance with the
 * method given and pass it ARGV and ENV in that order
 */
VALUE crate_wrap_app( VALUE arg )
{
  crate_app *ca = (crate_app*)arg;

  return rb_funcall( ca->app_instance, 
                     ca->run_method, 2, 
                     rb_const_get_at( rb_cObject, rb_intern("ARGV") ), 
                     rb_const_get_at( rb_cObject, rb_intern("ENV") ) );
}

static VALUE dump_backtrace( VALUE elem, VALUE n ) 
{
  fprintf( stderr, "\tfrom %s\n", RSTRING(elem)->ptr );
}

/**
 * ifdef items from ruby's original main.c
 */

/* to link startup code with ObjC support */
#if (defined(__APPLE__) || defined(__NeXT__)) && defined(__MACH__)
static void objcdummyfunction( void ) { objc_msgSend(); }
#endif


int main( int argc, char** argv ) 
{
  int state  = 0;
  int rc     = 0;
  int opt_mv = 0;

  crate_app ca;

  /** startup items from ruby's original main.c */
#ifdef _WIN32
  NtInitialize(&argc, &argv);
#endif
#if defined(__MACOS__) && defined(__MWERKS__)
  argc = ccommand(&argv);
#endif

  /* setup ruby */
  ruby_init();
  ruby_script( argv[0] );
  ruby_init_loadpath();

  /* strip out the crate specific arguments from argv using --crate- */
  opt_mv = crate_init_from_options( &ca, argc, argv );
  argc -= opt_mv;
  argv += opt_mv;
  
  /* make ARGV available */
  ruby_set_argv( argc, argv );

  /* load up the amalgalite libs */
  printf(" am_bootstrap_lift .. \n");
  am_bootstrap_lift( Qnil, Qnil );
  
  /* require the class file */
  printf(" Requiring %s\n", ca.file_name );
  rb_require( ca.file_name );

  /* get an instance of the application class and pack up the instance and the
   * method 
   */
  ca.app_instance = rb_class_new_instance(0, 0, rb_const_get( rb_cObject, rb_intern( ca.class_name ) ) );
  ca.run_method   = rb_intern( ca.method_name );
 
  /* invoke the class / method passing in ARGV and ENV */
  rb_protect( crate_wrap_app, (VALUE)&ca, &state );

  /* check the results */
  if ( state ) {

    /* exception was raised, check the $! var */
    VALUE lasterr  = rb_gv_get("$!");
   
    /* system exit was called so just propogate that up to our exit */
    if ( rb_obj_is_instance_of( lasterr, rb_eSystemExit ) ) {

      rc = NUM2INT( rb_attr_get( lasterr, rb_intern("status") ) );
      printf(" Caught SystemExit -> $? will be %d\n", rc );

    } else {

      /* some other exception was raised so dump that out */
      VALUE klass     = rb_class_path( CLASS_OF( lasterr ) );
      VALUE message   = rb_obj_as_string( lasterr );
      VALUE backtrace = rb_funcall( lasterr, rb_intern("backtrace"), 0 );

      fprintf( stderr, "%s: %s\n", RSTRING( klass )->ptr, RSTRING( message )->ptr );
      rb_iterate( rb_each, backtrace, dump_backtrace, Qnil );

      rc = state;
    }
  } 

  /* shut down ruby */
  ruby_finalize();

  /* exit the program */
  exit( rc );
}




