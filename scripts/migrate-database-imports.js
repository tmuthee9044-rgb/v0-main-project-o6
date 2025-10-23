#!/usr/bin/env node

/**
 * This script migrates all files from using @neondatabase/serverless directly
 * to using the smart db-client wrapper that supports both local PostgreSQL and Neon cloud
 */

const fs = require("fs")
const path = require("path")
const { execSync } = require("child_process")

// Directories to search
const searchDirs = ["app/actions", "app/api", "lib"]

// Statistics
let filesProcessed = 0
let filesUpdated = 0
const errors = []

console.log("🔄 Starting database import migration...\n")

function processFile(filePath) {
  try {
    const content = fs.readFileSync(filePath, "utf8")

    // Check if file imports from @neondatabase/serverless
    if (!content.includes("@neondatabase/serverless")) {
      return false
    }

    filesProcessed++
    console.log(`Processing: ${filePath}`)

    let newContent = content
    let wasModified = false

    // Replace the import statement
    if (content.includes('import { neon } from "@neondatabase/serverless"')) {
      newContent = newContent.replace(
        /import\s+{\s*neon\s*}\s+from\s+["']@neondatabase\/serverless["']/g,
        'import { sql } from "@/lib/db-client"',
      )
      wasModified = true
    }

    // Remove the sql = neon(...) line
    if (content.includes("const sql = neon(")) {
      newContent = newContent.replace(
        /const\s+sql\s*=\s*neon$$process\.env\.DATABASE_URL!?$$/g,
        "// Using shared sql client from db-client",
      )
      wasModified = true
    }

    // Handle cases where sql is created without const
    if (content.includes("sql = neon(")) {
      newContent = newContent.replace(
        /sql\s*=\s*neon$$process\.env\.DATABASE_URL!?$$/g,
        "// Using shared sql client from db-client",
      )
      wasModified = true
    }

    if (wasModified) {
      fs.writeFileSync(filePath, newContent, "utf8")
      filesUpdated++
      console.log(`  ✅ Updated: ${filePath}`)
      return true
    }

    return false
  } catch (error) {
    errors.push({ file: filePath, error: error.message })
    console.error(`  ❌ Error processing ${filePath}: ${error.message}`)
    return false
  }
}

function walkDirectory(dir) {
  const files = fs.readdirSync(dir)

  for (const file of files) {
    const filePath = path.join(dir, file)
    const stat = fs.statSync(filePath)

    if (stat.isDirectory()) {
      walkDirectory(filePath)
    } else if (file.endsWith(".ts") || file.endsWith(".tsx")) {
      processFile(filePath)
    }
  }
}

// Process each directory
for (const dir of searchDirs) {
  const fullPath = path.join(process.cwd(), dir)
  if (fs.existsSync(fullPath)) {
    console.log(`\n📁 Processing directory: ${dir}`)
    walkDirectory(fullPath)
  } else {
    console.log(`\n⚠️  Directory not found: ${dir}`)
  }
}

// Print summary
console.log("\n" + "=".repeat(60))
console.log("📊 Migration Summary:")
console.log("=".repeat(60))
console.log(`Files processed: ${filesProcessed}`)
console.log(`Files updated: ${filesUpdated}`)
console.log(`Errors: ${errors.length}`)

if (errors.length > 0) {
  console.log("\n❌ Errors encountered:")
  errors.forEach(({ file, error }) => {
    console.log(`  - ${file}: ${error}`)
  })
}

console.log("\n✅ Migration complete!")
console.log("\n📝 Next steps:")
console.log("1. Review the changes with: git diff")
console.log("2. Test the application: npm run dev")
console.log("3. Commit the changes if everything works")
