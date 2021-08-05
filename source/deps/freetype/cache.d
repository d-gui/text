module deps.freetype.cache;

version ( FreeType ):
public import bindbc.freetype;
import bc.string.string : tempCString;
import core.stdc.stdio  : printf;
import core.stdc.stdlib : exit;


// FreeType font cache
FTC_Manager    manager;
FTC_CMapCache  cmapCache;
FTC_ImageCache imageCache;


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


//
static
this()
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


static
~this() 
{
    FTC_Manager_Done( manager );
}
