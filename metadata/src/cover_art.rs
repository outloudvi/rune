use std::path::Path;

use anyhow::Result;
use image::{GenericImageView, ImageBuffer, Pixel};
use lofty::file::TaggedFileExt;

use crate::crc::media_crc32;

pub struct CoverArt {
    pub crc: String,
    pub data: Vec<u8>,
}

fn decode_image(image_data: &Vec<u8>) -> Result<Vec<u8>> {
    // Decode the image from binary data
    let img = image::load_from_memory(image_data)?;

    // Resize the image to 16x16 pixels
    let resized = img.resize_exact(16, 16, image::imageops::FilterType::Lanczos3);

    // Create a new RGB image buffer
    let mut rgb_image = ImageBuffer::new(16, 16);

    // Copy the resized image into the RGB buffer
    for (x, y, pixel) in resized.pixels() {
        let rgb = pixel.to_rgb();
        rgb_image.put_pixel(x, y, rgb);
    }

    // Convert the RGB image into a flat RGB sequence
    let rgb_sequence: Vec<u8> = rgb_image.into_raw();

    Ok(rgb_sequence)
}

pub fn extract_cover_art_binary(file_path: &Path) -> Option<CoverArt> {
    let tagged_file = lofty::read_from_path(file_path).ok()?;

    let tag = tagged_file
        .primary_tag()
        .or_else(|| tagged_file.first_tag())?;

    let pictures = tag.pictures();
    if pictures.is_empty() {
        return None;
    }

    let picture = &pictures[0];
    let cover_data = picture.data().to_vec();

    if cover_data.is_empty() {
        return None;
    }

    let rgb_sequence = decode_image(&cover_data).ok()?;

    // Calculate the CRC
    let crc = media_crc32(&rgb_sequence, 0, 0, rgb_sequence.len());

    if crc == 0 {
        return None;
    }

    let crc_string = format!("{:08x}", crc);

    Some(CoverArt {
        crc: crc_string,
        data: cover_data,
    })
}
