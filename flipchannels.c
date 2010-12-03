/*
 * Guillaume Cottenceau (gc at mandrakesoft.com)
 *
 * Small modification for R/B channel flippage by MHW.
 *
 * Everything else is Copyright 2002 MandrakeSoft.
 *
 * This software may be freely redistributed under the terms of the GNU
 * public license.
 *
 */

#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>

#define PNG_DEBUG 3
#include <png.h>

void abort_(const char * s, ...)
{
    va_list args;
    va_start(args, s);
    vfprintf(stderr, s, args);
    fprintf(stderr, "\n");
    va_end(args);
    abort();
}

int x, y;

int width, height;
png_byte color_type;
png_byte bit_depth;

png_structp png_ptr;
png_infop info_ptr;
int number_of_passes;
png_bytep * row_pointers;

void read_png_file(char* file_name)
{
    unsigned char header[8]; /* 8 is the maximum size that can be checked */
	
    /* open file and test for it being a png */
    FILE *fp = fopen(file_name, "rb");
    if (!fp)
        abort_("[read_png_file] File %s could not be opened for reading", file_name);
    fread(header, 1, 8, fp);
    if (png_sig_cmp(header, 0, 8))
        abort_("[read_png_file] File %s is not recognized as a PNG file", file_name);
	
	
    /* initialize stuff */
    png_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
    
    if (!png_ptr)
        abort_("[read_png_file] png_create_read_struct failed");
	
    info_ptr = png_create_info_struct(png_ptr);
    if (!info_ptr)
        abort_("[read_png_file] png_create_info_struct failed");
	
    if (setjmp(png_jmpbuf(png_ptr)))
        abort_("[read_png_file] Error during init_io");
	
    png_init_io(png_ptr, fp);
    png_set_sig_bytes(png_ptr, 8);
	
    png_read_info(png_ptr, info_ptr);
	
    width = info_ptr->width;
    height = info_ptr->height;
    color_type = info_ptr->color_type;
    bit_depth = info_ptr->bit_depth;
	
    number_of_passes = png_set_interlace_handling(png_ptr);
    png_read_update_info(png_ptr, info_ptr);
	
	
    /* read file */
    if (setjmp(png_jmpbuf(png_ptr)))
        abort_("[read_png_file] Error during read_image");
	
    row_pointers = (png_bytep*) malloc(sizeof(png_bytep) * height);
    for (y=0; y<height; y++)
        row_pointers[y] = (png_byte*) malloc(info_ptr->rowbytes);
	
    png_read_image(png_ptr, row_pointers);
	
	fclose(fp);
}


void write_png_file(char* file_name)
{
    /* create file */
    FILE *fp = fopen(file_name, "wb");
    if (!fp)
        abort_("[write_png_file] File %s could not be opened for writing", file_name);
	
	
    /* initialize stuff */
    png_ptr = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
    
    if (!png_ptr)
        abort_("[write_png_file] png_create_write_struct failed");
	
    info_ptr = png_create_info_struct(png_ptr);
    if (!info_ptr)
        abort_("[write_png_file] png_create_info_struct failed");
	
    if (setjmp(png_jmpbuf(png_ptr)))
        abort_("[write_png_file] Error during init_io");
	
    png_init_io(png_ptr, fp);
	
	
    /* write header */
    if (setjmp(png_jmpbuf(png_ptr)))
        abort_("[write_png_file] Error during writing header");
	
    png_set_IHDR(png_ptr, info_ptr, width, height,
				 bit_depth, color_type, PNG_INTERLACE_NONE,
				 PNG_COMPRESSION_TYPE_BASE, PNG_FILTER_TYPE_BASE);
	
    png_write_info(png_ptr, info_ptr);
	
	
    /* write bytes */
    if (setjmp(png_jmpbuf(png_ptr)))
        abort_("[write_png_file] Error during writing bytes");
	
    png_write_image(png_ptr, row_pointers);
	
	
    /* end write */
    if (setjmp(png_jmpbuf(png_ptr)))
        abort_("[write_png_file] Error during end of write");
	
    png_write_end(png_ptr, NULL);
	
	/* cleanup heap allocation */
    for (y=0; y<height; y++)
        free(row_pointers[y]);
    free(row_pointers);
	
	fclose(fp);
}


void process_file(void)
{
	int i;
	
    if (info_ptr->color_type != PNG_COLOR_TYPE_RGBA)
        abort_("[process_file] color_type of input file must be PNG_COLOR_TYPE_RGBA (is %d)", info_ptr->color_type);
	
	
    /* Run through the pixels and flip R and B. */
    for (i = 0; i < height; i++){
        for (y = 0; y < width * 4; y += 4){
            png_byte tmp;
			
            tmp = *(*(row_pointers+i)+y);
            *(*(row_pointers+i)+y) = *(*(row_pointers+i)+y+2);
            *(*(row_pointers+i)+y+2) = tmp;
        }
    }
}


int mainC(int argc, char **argv)
{
    if (argc != 3)
        abort_("Usage: program_name <file_in> <file_out>");
	
    read_png_file(argv[1]);
    process_file();
    write_png_file(argv[2]);
	
	return 0;
}
