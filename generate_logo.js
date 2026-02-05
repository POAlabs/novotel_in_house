#!/usr/bin/env node

/**
 * Script to generate Android app icons (logos) only - no splash screens
 */

const sharp = require('sharp');
const fs = require('fs');
const path = require('path');

// Configuration
const inputPath = 'assets/logo.jfif';
const outputDir = 'android/app/src/main/res';

// Ensure output directory exists
if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
}

// Android app icon sizes (width, height) for each density
const androidIconSizes = {
    'mipmap-hdpi': [48, 48],
    'mipmap-mdpi': [32, 32],  
    'mipmap-xhdpi': [72, 72],
    'mipmap-xxhdpi': [96, 96],
    'mipmap-xxxhdpi': [144, 144]
};

async function generateAndroidIcons() {
    console.log('Generating Android app icons...');

    try {
        // Generate app icons
        for (const [density, [width, height]] of Object.entries(androidIconSizes)) {
            const outputDirPath = path.join(outputDir, density);
            
            // Create directory if it doesn't exist
            if (!fs.existsSync(outputDirPath)) {
                fs.mkdirSync(outputDirPath, { recursive: true });
            }

            // Generate square app icon
            const squareIconPath = path.join(outputDirPath, 'ic_launcher.png');
            await sharp(inputPath)
                .resize(width, height, {
                    fit: 'cover',
                    position: 'center'
                })
                .png({ quality: 80, compressionLevel: 9 })
                .toFile(squareIconPath);

            // Generate round app icon with circular mask
            const roundIconPath = path.join(outputDirPath, 'ic_launcher_round.png');
            const svgBuffer = Buffer.from(
                `<svg width="${width}" height="${height}" xmlns="http://www.w3.org/2000/svg">
                    <circle cx="${width/2}" cy="${height/2}" r="${width/2}" fill="white"/>
                </svg>`
            );
            
            await sharp(inputPath)
                .resize(width, height, {
                    fit: 'cover',
                    position: 'center'
                })
                .composite([{
                    input: svgBuffer,
                    blend: 'dest-in'
                }])
                .png({ quality: 80, compressionLevel: 9 })
                .toFile(roundIconPath);

            console.log(`✓ Generated ${density}/ic_launcher.png (${width}x${height})`);
            console.log(`✓ Generated ${density}/ic_launcher_round.png (${width}x${height})`);
        }

        console.log('\n🎉 Android app icons generated successfully!');
        console.log('Total files generated:', Object.keys(androidIconSizes).length * 2);
        console.log('Asset size optimized with PNG quality 80 and compression level 9');

    } catch (error) {
        console.error('Error generating Android icons:', error);
        process.exit(1);
    }
}

// Run the function
generateAndroidIcons();
