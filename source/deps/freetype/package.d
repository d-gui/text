module deps.freetype;

version ( FreeType ):
public import bindbc.freetype;
public import deps.freetype.cache;
public import deps.freetype.funcs;
import bc.string.string : tempCString;
import core.stdc.stdio  : printf;
import core.stdc.stdlib : exit;


// global var
FT_Library ft;


//
static
this()
{
    /*
    This version attempts to load the FreeType shared library using well-known variations
    of the library name for the host system.
    */
    FTSupport ftret = loadFreeType();

    if ( ftret != ftSupport ) 
    {

        // Handle error. For most use cases, its reasonable to use the the error handling API in
        // bindbc-loader to retrieve error messages for logging and then abort. If necessary, it's
        // possible to determine the root cause via the return value:

        if ( ftret == FTSupport.noLibrary ) 
        {
            printf( "error: FreeType shared library failed to load.\n" );
            exit( -1 );
        }
        else 
        if ( FTSupport.badLibrary ) 
        {
            // One or more symbols failed to load. The likely cause is that the
            // shared library is for a lower version than bindbc-freetype was configured
            // to load (via FT_26, FT_27, etc.)
            printf( "error: FreeType: One or more symbols failed to load.\n" );
            exit( -1 );
        }
    }

    FT_Init_FreeType( &ft );
}


static
~this() 
{
    FT_Done_FreeType( ft );
}
