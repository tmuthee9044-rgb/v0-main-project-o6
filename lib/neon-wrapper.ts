import { neon as neonOriginal } from "@neondatabase/serverless"
import { Pool } from "pg"

// Cache for database clients
const clientCache = new Map<string, any>()
const poolCache = new Map<string, Pool>()

/**
 * Smart neon() wrapper that automatically detects local vs cloud PostgreSQL
 * and uses the appropriate driver for optimal performance
 */
export function neon(connectionString: string, options?: any) {
  // Check cache first
  if (clientCache.has(connectionString)) {
    return clientCache.get(connectionString)
  }

  const isLocalDatabase =
    connectionString.includes("localhost") ||
    connectionString.includes("127.0.0.1") ||
    connectionString.includes("@localhost") ||
    connectionString.includes("@127.0.0.1")

  if (isLocalDatabase) {
    // Use standard pg Pool for local/offline PostgreSQL
    console.log("[v0] Using local PostgreSQL connection (pg driver)")

    // Get or create pool for this connection string
    let pool = poolCache.get(connectionString)
    if (!pool) {
      pool = new Pool({
        connectionString,
        max: 20,
        idleTimeoutMillis: 30000,
        connectionTimeoutMillis: 5000, // Reduced timeout for faster failure detection
        statement_timeout: 10000, // 10 second query timeout
      })
      poolCache.set(connectionString, pool)

      // Graceful shutdown
      process.on("SIGTERM", async () => {
        await pool?.end()
      })
    }

    // Create Neon-compatible interface
    const sqlClient = async (query: string, params?: any[]) => {
      const client = await pool!.connect()
      try {
        const result = await client.query(query, params)
        return result.rows
      } catch (error: any) {
        console.error("[v0] Database query error:", error.message)
        throw error
      } finally {
        client.release()
      }
    }

    clientCache.set(connectionString, sqlClient)
    return sqlClient
  } else {
    // Use Neon serverless driver for cloud databases
    console.log("[v0] Using Neon serverless connection")
    const client = neonOriginal(connectionString, options)
    clientCache.set(connectionString, client)
    return client
  }
}

// Re-export other Neon types if needed
export * from "@neondatabase/serverless"
