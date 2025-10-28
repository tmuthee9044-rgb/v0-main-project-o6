import { NextResponse } from "next/server"
import { neon } from "@/lib/neon-wrapper"
import { readdir, readFile } from "fs/promises"
import { join } from "path"

const sql = neon(process.env.DATABASE_URL!)

export async function POST() {
  try {
    const results = {
      migrationsRun: [] as string[],
      errors: [] as string[],
      summary: "",
    }

    try {
      await sql`SELECT 1 as test`
    } catch (error: any) {
      return NextResponse.json(
        {
          success: false,
          error: "Database connection failed",
          details: error.message,
        },
        { status: 500 },
      )
    }

    try {
      await sql`
        CREATE TABLE IF NOT EXISTS schema_migrations (
          id SERIAL PRIMARY KEY,
          migration_name VARCHAR(255) UNIQUE NOT NULL,
          applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      `
    } catch (error: any) {
      results.errors.push(`Failed to create migrations table: ${error.message}`)
    }

    let appliedMigrations: string[] = []
    try {
      const rows = await sql`SELECT migration_name FROM schema_migrations`
      appliedMigrations = rows.map((row: any) => row.migration_name)
    } catch (error: any) {
      results.errors.push(`Failed to read migrations: ${error.message}`)
    }

    try {
      const scriptsDir = join(process.cwd(), "scripts")
      const files = await readdir(scriptsDir)
      const migrationFiles = files.filter((f) => f.endsWith(".sql") && f.match(/^\d{3}_/)).sort()

      for (const file of migrationFiles) {
        const migrationName = file.replace(".sql", "")

        if (appliedMigrations.includes(migrationName)) {
          continue // Skip already applied migrations
        }

        try {
          const filePath = join(scriptsDir, file)
          const migrationSQL = await readFile(filePath, "utf-8")

          // Note: We can't use sql`` template for dynamic SQL, so we use a workaround
          const statements = migrationSQL
            .split(";")
            .map((s) => s.trim())
            .filter((s) => s.length > 0 && !s.startsWith("--"))

          for (const statement of statements) {
            if (statement.trim()) {
              await sql.unsafe(statement)
            }
          }

          results.migrationsRun.push(migrationName)
        } catch (error: any) {
          results.errors.push(`Migration ${migrationName}: ${error.message}`)
        }
      }
    } catch (error: any) {
      results.errors.push(`Failed to read migration files: ${error.message}`)
    }

    results.summary = `Database sync completed. Ran ${results.migrationsRun.length} migrations. ${results.errors.length} errors encountered.`

    return NextResponse.json({
      success: results.errors.length === 0,
      message:
        results.errors.length === 0
          ? "Database schema synchronized successfully"
          : "Database sync completed with errors",
      results,
    })
  } catch (error: any) {
    console.error("Database sync error:", error)
    return NextResponse.json(
      {
        success: false,
        error: "Failed to sync database schema",
        details: error.message,
      },
      { status: 500 },
    )
  }
}
