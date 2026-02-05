#!/usr/bin/env node

/**
 * Script to generate iOS app icons (logos) only - no splash screens
 */

const sharp = require('sharp');
const fs = require('fs');
const path = require('path');

// Configuration
const inputPath = 'assets/logo.jfif';
const outputDir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';

// Ensure output directory exists
if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
}

// iOS app icon sizes (width, height) for each required icon
const iosIconSizes = {
    'Icon-App-20x20@1x': [20, 20],
    'Icon-App-20x20@2x': [40, 40],
    'Icon-App-20x20@3x': [60, 60],
    'Icon-App-29x29@1x': [29, 29],
    'Icon-App-29x29@2x': [58, 58],
    'Icon-App-29x29@3x': [87, 87],
    'Icon-App-40x40@1x': [40, 40],
    'Icon-App-40x40@2x': [80, 80],
    'Icon-App-40x40@3x': [120, 120],
    'Icon-App-60x60@2x': [120, 120],
    'Icon-App-60x60@3x': [180, 180],
    'Icon-App-76x76@1x': [76, 76],
    'Icon-App-76x76@2x': [152, 152],
    'Icon-App-83.5x83.5@2x': [167, 167],
    'Icon-App-1024x1024@1x': [1024, 1024]
};

async function generateIOSIcons() {
    console.log('Generating iOS app icons...');

    try {
        // Generate app icons
        for (const [filename, [width, height]] of Object.entries(iosIconSizes)) {
            const outputPath = path.join(outputDir, filename + '.png');
            
            await sharp(inputPath)
                .resize(width, height, {
                    fit: 'cover',
                    position: 'center'
                })
                .png({ quality: 80, compressionLevel: 9 })
                .toFile(outputPath);

            console.log(`✓ Generated ${filename} (${width}x${height})`);
        }

        console.log('\n🎉 iOS app icons generated successfully!');
        console.log('Total files generated:', Object.keys(iosIconSizes).length);
        console.log('Asset size optimized with PNG quality 80 and compression level 9');

    } catch (error) {
        console.error('Error generating iOS icons:', error);
        process.exit(1);
    }
}

// Run the function
generateIOSIcons();
