import { neon } from "@neondatabase/serverless"
import postgres from "postgres"

const connectionString = process.env.DATABASE_URL || process.env.POSTGRES_URL

if (!connectionString) {
  throw new Error("DATABASE_URL environment variable is required")
}

// Detect if this is a Neon cloud database or local PostgreSQL
const isNeonDatabase = connectionString.includes("neon.tech")

// Create appropriate connection based on database type
export const sql = isNeonDatabase
  ? neon(connectionString)
  : postgres(connectionString, {
      max: 10,
      idle_timeout: 20,
      connect_timeout: 10,
    })

console.log(`[v0] Using ${isNeonDatabase ? "Neon cloud" : "local PostgreSQL"} database`)

// Helper function for retry logic on rate limit errors
export async function executeWithRetry<T>(queryFn: () => Promise<T>, maxRetries = 3): Promise<T> {
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      return await queryFn()
    } catch (error: any) {
      // Check if it's a rate limit error (429)
      if (error.status === 429 && attempt < maxRetries - 1) {
        // Exponential backoff with jitter
        const delay = Math.pow(2, attempt) * 1000 + Math.random() * 1000
        await new Promise((resolve) => setTimeout(resolve, delay))
        continue
      }
      throw error
    }
  }
  throw new Error("Max retries exceeded")
}
