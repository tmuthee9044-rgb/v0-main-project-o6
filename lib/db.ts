import { neon } from "@neondatabase/serverless"
import { sql as sqlClient, executeWithRetry } from "./db-client"

export const sql = sqlClient
export { executeWithRetry }

export function getSqlConnection() {
  const databaseUrl = process.env.DATABASE_URL
  if (!databaseUrl) {
    throw new Error("DATABASE_URL environment variable is required")
  }
  return neon(databaseUrl)
}

let db: any = null

async function initializeDb() {
  if (db) return db

  // Check if we have Neon database configuration
  const databaseUrl = process.env.DATABASE_URL

  if (!databaseUrl) {
    throw new Error("DATABASE_URL environment variable is required")
  }

  try {
    // Create Neon serverless connection
    const sqlInstance = neon(databaseUrl)

    db = {
      execute: async (query: string, params?: any[]) => {
        // Convert MySQL-style ? placeholders to PostgreSQL $1, $2, etc.
        let pgQuery = query
        if (params && params.length > 0) {
          params.forEach((_, index) => {
            pgQuery = pgQuery.replace("?", `$${index + 1}`)
          })
        }

        const results = await sqlInstance(pgQuery, params || [])
        return results
      },

      query: async (query: string, params?: any[]) => {
        // Convert MySQL-style ? placeholders to PostgreSQL $1, $2, etc.
        let pgQuery = query
        if (params && params.length > 0) {
          params.forEach((_, index) => {
            pgQuery = pgQuery.replace("?", `$${index + 1}`)
          })
        }

        const results = await sqlInstance(pgQuery, params || [])
        return results
      },
    }

    console.log("Neon database connected successfully")
    return db
  } catch (error) {
    console.error("Neon database connection failed:", error)
    throw error
  }
}

export async function query(sql: string, params?: any[]) {
  const database = await initializeDb()
  return database.query(sql, params)
}

export { db }
