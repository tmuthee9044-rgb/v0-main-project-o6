import { NextResponse } from "next/server"
import { neon } from "@neondatabase/serverless"

const sql = neon(process.env.DATABASE_URL!)

export async function POST() {
  try {
    const results = {
      tablesCreated: [],
      columnsAdded: [],
      errors: [],
      summary: "",
    }

    // Customer table enhancements
    try {
      await sql`
        ALTER TABLE customers 
        ADD COLUMN IF NOT EXISTS customer_type VARCHAR(50) DEFAULT 'residential',
        ADD COLUMN IF NOT EXISTS plan VARCHAR(100),
        ADD COLUMN IF NOT EXISTS monthly_fee DECIMAL(10,2) DEFAULT 0,
        ADD COLUMN IF NOT EXISTS balance DECIMAL(10,2) DEFAULT 0,
        ADD COLUMN IF NOT EXISTS connection_quality VARCHAR(20) DEFAULT 'good',
        ADD COLUMN IF NOT EXISTS portal_login_id VARCHAR(100),
        ADD COLUMN IF NOT EXISTS portal_username VARCHAR(100),
        ADD COLUMN IF NOT EXISTS portal_password VARCHAR(255),
        ADD COLUMN IF NOT EXISTS installation_date DATE,
        ADD COLUMN IF NOT EXISTS last_payment_date DATE,
        ADD COLUMN IF NOT EXISTS contract_end_date DATE
      `
      results.columnsAdded.push(
        "customers: customer_type, plan, monthly_fee, balance, connection_quality, portal credentials",
      )
    } catch (error) {
      results.errors.push(`Customer table: ${error.message}`)
    }

    // Service plans table
    try {
      await sql`
        CREATE TABLE IF NOT EXISTS service_plans (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          name VARCHAR(100) NOT NULL,
          description TEXT,
          speed_download INTEGER NOT NULL,
          speed_upload INTEGER NOT NULL,
          data_limit INTEGER,
          price DECIMAL(10,2) NOT NULL,
          setup_fee DECIMAL(10,2) DEFAULT 0,
          fup_limit INTEGER,
          fup_speed INTEGER,
          contract_period INTEGER DEFAULT 12,
          is_active BOOLEAN DEFAULT true,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      `
      results.tablesCreated.push("service_plans")
    } catch (error) {
      results.errors.push(`Service plans table: ${error.message}`)
    }

    // Customer services table
    try {
      await sql`
        CREATE TABLE IF NOT EXISTS customer_services (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
          service_plan_id UUID REFERENCES service_plans(id),
          status VARCHAR(20) DEFAULT 'active',
          installation_date DATE,
          activation_date DATE,
          suspension_date DATE,
          termination_date DATE,
          monthly_fee DECIMAL(10,2),
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      `
      results.tablesCreated.push("customer_services")
    } catch (error) {
      results.errors.push(`Customer services table: ${error.message}`)
    }

    // Payments table enhancements
    try {
      await sql`
        CREATE TABLE IF NOT EXISTS payments (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
          amount DECIMAL(10,2) NOT NULL,
          payment_method VARCHAR(50) NOT NULL,
          payment_reference VARCHAR(100),
          mpesa_receipt_number VARCHAR(100),
          status VARCHAR(20) DEFAULT 'pending',
          payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      `
      results.tablesCreated.push("payments")
    } catch (error) {
      results.errors.push(`Payments table: ${error.message}`)
    }

    // Network devices table
    try {
      await sql`
        CREATE TABLE IF NOT EXISTS network_devices (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          name VARCHAR(100) NOT NULL,
          type VARCHAR(50) NOT NULL,
          ip_address INET,
          mac_address VARCHAR(17),
          location VARCHAR(200),
          status VARCHAR(20) DEFAULT 'active',
          last_seen TIMESTAMP,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      `
      results.tablesCreated.push("network_devices")
    } catch (error) {
      results.errors.push(`Network devices table: ${error.message}`)
    }

    // IP addresses table
    try {
      await sql`
        CREATE TABLE IF NOT EXISTS ip_addresses (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          ip_address INET NOT NULL UNIQUE,
          subnet_id UUID,
          customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
          status VARCHAR(20) DEFAULT 'available',
          assigned_date TIMESTAMP,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      `
      results.tablesCreated.push("ip_addresses")
    } catch (error) {
      results.errors.push(`IP addresses table: ${error.message}`)
    }

    // Create indexes for performance
    try {
      await sql`
        CREATE INDEX IF NOT EXISTS idx_customers_email ON customers(email);
        CREATE INDEX IF NOT EXISTS idx_customers_phone ON customers(phone);
        CREATE INDEX IF NOT EXISTS idx_customers_status ON customers(status);
        CREATE INDEX IF NOT EXISTS idx_payments_customer_id ON payments(customer_id);
        CREATE INDEX IF NOT EXISTS idx_payments_date ON payments(payment_date);
        CREATE INDEX IF NOT EXISTS idx_customer_services_customer_id ON customer_services(customer_id);
        CREATE INDEX IF NOT EXISTS idx_ip_addresses_customer_id ON ip_addresses(customer_id);
      `
      results.columnsAdded.push("Performance indexes created")
    } catch (error) {
      results.errors.push(`Indexes: ${error.message}`)
    }

    // Generate summary
    results.summary = `Database sync completed. Created ${results.tablesCreated.length} tables, added ${results.columnsAdded.length} column sets. ${results.errors.length} errors encountered.`

    return NextResponse.json({
      success: true,
      message: "Database schema synchronized successfully",
      results,
    })
  } catch (error) {
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
