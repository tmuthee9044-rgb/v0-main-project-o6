import { neon } from "@neondatabase/serverless"

// Create a single reusable database connection instance
const connectionString = process.env.DATABASE_URL || process.env.POSTGRES_URL

if (!connectionString) {
  throw new Error("DATABASE_URL environment variable is required")
}

// Single instance reused throughout the application
export const sql = neon(connectionString)

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
