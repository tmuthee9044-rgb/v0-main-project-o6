import { neon } from "@neondatabase/serverless"
import postgres from "postgres"

function createDatabaseConnection() {
  const databaseUrl = process.env.DATABASE_URL

  if (!databaseUrl) {
    throw new Error("DATABASE_URL environment variable is required")
  }

  // Check if this is a Neon cloud database or local PostgreSQL
  const isNeonDatabase = databaseUrl.includes("neon.tech")

  if (isNeonDatabase) {
    // Use Neon serverless driver for cloud database
    console.log("[v0] Using Neon serverless driver for cloud database")
    return neon(databaseUrl)
  } else {
    // Use postgres driver for local PostgreSQL
    console.log("[v0] Using postgres driver for local PostgreSQL database")
    const sql = postgres(databaseUrl, {
      max: 10,
      idle_timeout: 20,
      connect_timeout: 10,
    })
    return sql
  }
}

// Export the SQL connection
export const sql = createDatabaseConnection()

// Helper function to get SQL connection (for compatibility)
export function getSqlConnection() {
  return sql
}

// Execute with retry logic
export async function executeWithRetry<T>(operation: () => Promise<T>, maxRetries = 3, delayMs = 1000): Promise<T> {
  let lastError: Error | null = null

  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await operation()
    } catch (error) {
      lastError = error as Error
      console.error(`[v0] Database operation failed (attempt ${attempt}/${maxRetries}):`, error)

      if (attempt < maxRetries) {
        await new Promise((resolve) => setTimeout(resolve, delayMs * attempt))
      }
    }
  }

  throw lastError
}

// Legacy exports for compatibility
let db: any = null

async function initializeDb() {
  if (db) return db

  const databaseUrl = process.env.DATABASE_URL

  if (!databaseUrl) {
    throw new Error("DATABASE_URL environment variable is required")
  }

  try {
    const sqlInstance = createDatabaseConnection()

    db = {
      execute: async (query: string, params?: any[]) => {
        const results = await sqlInstance(query, params || [])
        return results
      },

      query: async (query: string, params?: any[]) => {
        const results = await sqlInstance(query, params || [])
        return results
      },
    }

    console.log("[v0] Database connected successfully")
    return db
  } catch (error) {
    console.error("[v0] Database connection failed:", error)
    throw error
  }
}

export async function query(sqlQuery: string, params?: any[]) {
  const database = await initializeDb()
  return database.query(sqlQuery, params)
}

export { db }
