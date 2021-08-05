module deps.freetype.funcs;

version ( FreeType ):
public import bindbc.freetype;
import bc.string.string : tempCString;
import core.stdc.stdio  : printf;
import deps.freetype    : ft;


struct Glyph
{
    // FreeType glyph
    ubyte*     buffer; // pixmap
    uint       width;
    uint       height;
    float      bearing_x;
    float      bearing_y;
    // GL glyph
    Vertex8[4] vertices;
    GLuint     vertexArray;
    GLuint     vertexBuffer;
    int        twidth;
    int        theight;
    GLuint     textureId;
}


nothrow @nogc:

void loadFace( string fontName, int ptSize, int deviceHDPI, int deviceVDPI, FT_Face* face )
{
    FT_Error error = FT_New_Face( ft, fontName.tempCString(), 0, face );
    assert( error == 0, "Cannot open font file" );

    force_ucs2_charmap( *face );

    FT_Set_Char_Size( *face, 0, ptSize, deviceHDPI, deviceVDPI );
}


void freeFace( FT_Face face ) 
{
    FT_Done_Face( face );
}

//nothrow @nogc
//void freeGlyph( Glyph glyph ) 
//{
//    //delete glyph;
//}

int force_ucs2_charmap( FT_Face face ) 
{
    for ( int i = 0; i < face.num_charmaps; i++ ) 
    {
        if ((  (face.charmaps[i].platform_id == 0)
            && (face.charmaps[i].encoding_id == 3))
           || ((face.charmaps[i].platform_id == 3)
            && (face.charmaps[i].encoding_id == 1))) 
        {
                return FT_Set_Charmap( face, face.charmaps[i] );
        }
    }
    return -1;
}


void rasterize( FT_Face face, uint glyphIndex, Glyph* glyph )
{
    FT_Error error;

    // Load Glyph
    FT_Int32 flags =  FT_LOAD_DEFAULT;

    error = 
        FT_Load_Glyph( 
            face,
            glyphIndex, // the glyph_index in the font file
            flags
        );
    if ( error )
    {
        printf( "error: FreeType: FT_Load_Glyph()\n" );
        return; // skip glyph
    }

    // Render Glyph
    FT_GlyphSlot slot = face.glyph;

    error = 
        FT_Render_Glyph( 
            slot, 
            FT_RENDER_MODE_NORMAL 
        );
    if ( error )
    {
        printf( "error: FreeType: FT_Render_Glyph()\n" );
        return; // skip glyph
    }

    // Save Glyph into memory
    with ( slot )
    {
        glyph.bearing_x = bitmap_left;
        glyph.bearing_y = bitmap_top;
    }
    with ( slot.bitmap )
    {
        glyph.buffer    = cast( ubyte* ) buffer;
        glyph.width     = width;
        glyph.height    = rows;
    }
}

// chechk in cache
//   create if need
//     get w x h
//     check free allocated memory
//       allocate memory if need
//     render
//     put in to cache

/**
 * index  : Glyph index
 * pixmap : Poiinter to Glyph pixels. Offset from CahcedGlypheSet start
 * w      : width of the pixmap
 * h      : height of the pixmap
 * stride : Same as 'w', but can be less than w
 */
struct CachedGlyph
{
    int    index;
    ubyte* pixmapOfsset;
    uint   w; // w can be less than texture w. for glyph with height 50: h is constant, w is variable
    uint   h;
    uint   stride;

    ubyte* pixmap( CacheGlyphSet* cacheGlyphSet )
    {
        return cacheGlyphSet.pixmap + pixmapOfsset;
    }
}

/**
 * pixmap : memory area, contains all glyphs pixmaps
 * w      : width of the pixmap
 * h      : height of the pixmap
 * glyphs : CachedGlyph, ordered by Glyph index
 */
struct CacheGlyphSet
{
    ubyte*        pixmap;
    uint          h;
    uint          w;
    CachedGlyph[] glyphs;

    void alllocatePixmap( int w, int h )
    {
        pixmap = malloc( w * h );
        this.w = w;
        this.h = h;
    }

    void reallocatePixmap( int w, int h )
    {
        pixmap = realloc( w * h );
        this.w = w;
        this.h = h;
    }

}


struct CacheGlyphSetStorage
{
    CacheGlyphSet ;
}


/** */
struct GlyphCache
{
    CacheGlyphSetStorage storage;

    Glyph* create( string fontName, uint fontSize, uint glyphIndex )
    {
        return null;
    }

    Glyph* read( string fontName, uint fontSize, uint glyphIndex )
    {
        return null;
    }

    void update( string fontName, uint fontSize, uint glyphIndex )
    {
        //
    }

    Glyph* readCreate( string fontName, uint fontSize, uint glyphIndex )
    {
        auto ret = read( fontName, fontSize, glyphIndex );

        if ( ret is null )
        {
            ret = create( fontName, fontSize, glyphIndex );
        }

        return ret;
    }
}


struct CRUDCache( T )
{
    T* create( ARGS... )( ARGS args )
    {
        return null;
    }

    T* read( ARGS... )( ARGS args )
    {
        return null;
    }

    void update( ARGS... )( ARGS args )
    {
        //
    }

    void delete()
    {
        //
    }

    T* readCreate( ARGS... )( ARGS args )
    {
        return null;
    }
}


//
struct GlyphCache
{
    size_t glyphsCount;
    Glyph  glyph;
    void*  pixmap;
}


struct FreeTypeCache
{
    FTC_Manager    manager;
    FTC_CMapCache  cmapCache;
    FTC_ImageCache imageCache;

    this( string name )
    {
        auto err = 
            FTC_Manager_New( 
                ft,
                128,
                0,
                0,
                requester,
                null,
                &manager
            );

        err = FTC_CMapCache_New( manager, &cmapCache );
        err = FTC_ImageCache_New( manager, &imageCache );
    }

    ~this()
    {
        FTC_Manager_Done( manager );
    }

    FT_Glyph lookup( FTC_FaceID face_id, height, glyphIndex )
    {
        //
        FTC_ScalerRec scaler;
        scaler.face_id = face_id;
        scaler.height  = height;
        scaler.pixel   = 1;

        auto size = lookupSize( &scaler );

        //
        FTC_ImageTypeRec imageType;
        imageType.face_id = face_id;
        imageType.height  = height;
        imageType.flags   = FT_LOAD_DEFAULT; // FT_LOAD_DEFAULT | FT_LOAD_NO_SCALE | FT_LOAD_*
        auto glyph = lookupImage( &imageType, glyphIndex );

        return glyph;
    }

    FT_Face lookupFace( FTC_FaceID face_id )
    {
        FT_Face face;

        auto err = 
            FTC_Manager_LookupFace( 
                manager,
                face_id,
                &face
            );

        if ( !err )
        {
            return face;
        }
        else
        {
            handleError( err );
            return null;
        }
    }

    FT_Size lookupSize( FTC_Scaler scaler )
    {
        FT_Size size;

        auto err = 
            FTC_Manager_LookupSize( 
                manager,
                scaler,
                &size
            );

        if ( !err )
        {
            return face;
        }
        else
        {
            handleError( err );
            return null;
        }
    }

    FT_Glyph lookupGlyphIndex( FTC_FaceID face_id, FT_Int cmap_index, FT_UInt32 char_code )
    {
        auto glyphIndex = 
            FTC_CMapCache_Lookup( 
                cmapCache, 
                cmap_index, 
                char_code 
            );

        return glyphIndex;
    }

    FT_Glyph lookupImage( FTC_ImageType type, FT_UInt glyphIndex )
    {
        FT_Glyph glyph;
        FTC_Node node;

        auto err = 
            FTC_ImageCache_Lookup( 
                imageCache,
                type,
                glyphIndex,
                &glyph,
                &node
            );

        if ( !err )
        {
            return glyph;
        }
        else
        {
            handleError( err );
            return null;
        }
    }


    static
    void handleError( FT_Error err )
    {
        const char* errString = FT_Error_String( err );
        printf( "error: FreeType: [%d]: %s\n", err, errString );
    }

    static
    FT_Error requester( 
        FTC_FaceID face_id,
        FT_Library library,
        FT_Pointer req_data,
        FT_Face*   face
    )
    {
        auto err = 
            FT_New_Face( 
               library,
               req_data.fileName,
               req_data.faceIndex,
               face );

        return err;
    }
}

