/**
 * build_pack.js
 * 
 * Orchestrates the complete pack build process:
 * 1. Build Docusaurus site
 * 2. Export docs to HTML with link rewriting
 * 3. Generate manifest
 * 4. Copy required assets
 * 5. Validate output
 * 6. Create ZIP archive
 * 
 * Usage: node build_pack.js [--skip-build]
 * Options:
 *   --skip-build  Skip the Docusaurus build step (useful for testing)
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const archiver = require('archiver');

// Import other modules
const { exportDocs } = require('./export_docs');
const { generateManifest } = require('./generate_manifest');

// Paths
const REPO_ROOT = path.resolve(__dirname, '..');
const WEBSITE_DIR = path.join(REPO_ROOT, 'website');
const BUILD_DIR = path.join(WEBSITE_DIR, 'build');
const CONTENT_DIR = path.join(REPO_ROOT, 'content');
const CONTENT_DOCS_DIR = path.join(CONTENT_DIR, 'docs');
const CONTENT_ASSETS_DIR = path.join(CONTENT_DIR, 'assets');

/**
 * Run Docusaurus build
 */
function buildDocusaurus() {
    console.log('\n📦 Building Docusaurus site...');
    console.log('   This may take a few minutes...\n');

    try {
        // Install dependencies if needed
        if (!fs.existsSync(path.join(WEBSITE_DIR, 'node_modules'))) {
            console.log('   Installing dependencies...');
            execSync('npm ci', {
                cwd: WEBSITE_DIR,
                stdio: 'inherit'
            });
        }

        // Run build
        execSync('npm run build', {
            cwd: WEBSITE_DIR,
            stdio: 'inherit'
        });

        console.log('✅ Docusaurus build complete');
    } catch (error) {
        throw new Error(`Docusaurus build failed: ${error.message}`);
    }
}

/**
 * Copy required assets from Docusaurus build
 */
function copyAssets() {
    console.log('\n📁 Copying assets...');

    // Create assets directory structure
    const assetDirs = ['css', 'js', 'img'];
    for (const dir of assetDirs) {
        const targetDir = path.join(CONTENT_ASSETS_DIR, dir);
        if (!fs.existsSync(targetDir)) {
            fs.mkdirSync(targetDir, { recursive: true });
        }
    }

    // Copy CSS files
    const cssSource = path.join(BUILD_DIR, 'assets', 'css');
    if (fs.existsSync(cssSource)) {
        copyDir(cssSource, path.join(CONTENT_ASSETS_DIR, 'css'));
    }

    // Copy JS files (optional, for interactive content)
    const jsSource = path.join(BUILD_DIR, 'assets', 'js');
    if (fs.existsSync(jsSource)) {
        copyDir(jsSource, path.join(CONTENT_ASSETS_DIR, 'js'));
    }

    // Copy images
    const imgSource = path.join(BUILD_DIR, 'img');
    if (fs.existsSync(imgSource)) {
        copyDir(imgSource, path.join(CONTENT_ASSETS_DIR, 'img'));
    }

    // Copy static assets
    const staticSource = path.join(BUILD_DIR, 'assets');
    if (fs.existsSync(staticSource)) {
        // Copy all asset types
        const items = fs.readdirSync(staticSource);
        for (const item of items) {
            const srcPath = path.join(staticSource, item);
            if (fs.statSync(srcPath).isDirectory()) {
                copyDir(srcPath, path.join(CONTENT_ASSETS_DIR, item));
            }
        }
    }

    console.log('✅ Assets copied');
}

/**
 * Recursively copy a directory
 */
function copyDir(src, dest) {
    if (!fs.existsSync(dest)) {
        fs.mkdirSync(dest, { recursive: true });
    }

    const entries = fs.readdirSync(src, { withFileTypes: true });
    for (const entry of entries) {
        const srcPath = path.join(src, entry.name);
        const destPath = path.join(dest, entry.name);

        if (entry.isDirectory()) {
            copyDir(srcPath, destPath);
        } else {
            fs.copyFileSync(srcPath, destPath);
        }
    }
}

/**
 * Validate the output
 */
function validateOutput(manifest) {
    console.log('\n🔍 Validating output...');

    const errors = [];

    // Check manifest exists
    const manifestPath = path.join(CONTENT_DIR, 'index.json');
    if (!fs.existsSync(manifestPath)) {
        errors.push('Manifest (index.json) not found');
    }

    // Check all HTML files exist
    for (const [docId, meta] of Object.entries(manifest.docs)) {
        const htmlPath = path.join(CONTENT_DIR, meta.html);
        if (!fs.existsSync(htmlPath)) {
            errors.push(`HTML not found: ${meta.html}`);
        }
    }

    // Check assets directory exists
    if (!fs.existsSync(CONTENT_ASSETS_DIR)) {
        errors.push('Assets directory not found');
    }

    if (errors.length > 0) {
        console.log('❌ Validation failed:');
        errors.forEach(e => console.log(`   - ${e}`));
        return false;
    }

    console.log('✅ Validation passed');
    return true;
}

/**
 * Create the ZIP archive
 */
async function createZip(packVersion) {
    console.log('\n📦 Creating ZIP archive...');

    const zipPath = path.join(REPO_ROOT, `release_pack_${packVersion}.zip`);

    return new Promise((resolve, reject) => {
        const output = fs.createWriteStream(zipPath);
        const archive = archiver('zip', { zlib: { level: 9 } });

        output.on('close', () => {
            const sizeMB = (archive.pointer() / 1024 / 1024).toFixed(2);
            console.log(`✅ ZIP created: ${zipPath}`);
            console.log(`   Size: ${sizeMB} MB`);
            resolve(zipPath);
        });

        archive.on('error', reject);

        archive.pipe(output);

        // Add content directory
        archive.directory(CONTENT_DIR, 'content');

        archive.finalize();
    });
}

/**
 * Main build function
 */
async function buildPack(options = {}) {
    const startTime = Date.now();
    console.log('🚀 Starting pack build...\n');

    try {
        // Step 1: Build Docusaurus (unless skipped)
        if (!options.skipBuild) {
            buildDocusaurus();
        } else {
            console.log('⏭️  Skipping Docusaurus build (--skip-build)');
        }

        // Step 2: Clean and prepare content directory
        console.log('\n🧹 Cleaning content directory...');
        if (fs.existsSync(CONTENT_DIR)) {
            fs.rmSync(CONTENT_DIR, { recursive: true, force: true });
        }
        fs.mkdirSync(CONTENT_DOCS_DIR, { recursive: true });

        // Step 3: Export docs
        console.log('\n📄 Exporting docs...');
        const exportResult = await exportDocs();

        if (exportResult.failCount > 0 && exportResult.successCount === 0) {
            throw new Error('All doc exports failed');
        }

        // Step 4: Generate manifest
        console.log('\n📋 Generating manifest...');
        const manifest = generateManifest();

        // Step 5: Copy assets
        copyAssets();

        // Step 6: Validate
        const isValid = validateOutput(manifest);
        if (!isValid) {
            throw new Error('Validation failed');
        }

        // Step 7: Create ZIP
        const zipPath = await createZip(manifest.packVersion);

        // Summary
        const elapsed = ((Date.now() - startTime) / 1000).toFixed(1);
        console.log('\n' + '='.repeat(50));
        console.log('🎉 Pack build complete!');
        console.log('='.repeat(50));
        console.log(`   📦 Pack version: ${manifest.packVersion}`);
        console.log(`   📄 Docs exported: ${exportResult.successCount}`);
        console.log(`   ⏱️  Time: ${elapsed}s`);
        console.log(`   📁 Output: ${zipPath}`);

        return {
            success: true,
            packVersion: manifest.packVersion,
            zipPath,
            docsCount: exportResult.successCount
        };

    } catch (error) {
        console.error('\n❌ Build failed:', error.message);
        throw error;
    }
}

// Run if called directly
if (require.main === module) {
    const skipBuild = process.argv.includes('--skip-build');

    buildPack({ skipBuild })
        .then(() => process.exit(0))
        .catch(() => process.exit(1));
}

module.exports = { buildPack };
