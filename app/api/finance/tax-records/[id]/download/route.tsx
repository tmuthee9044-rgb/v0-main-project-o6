import { type NextRequest, NextResponse } from "next/server"
import { neon } from "@neondatabase/serverless"
import { renderToStaticMarkup } from "react-dom/server"

const sql = neon(process.env.DATABASE_URL!)

function TaxReturnPDF({ taxRecord, company }: { taxRecord: any; company: any }) {
  return (
    <html>
      <head>
        <style>{`
          body { font-family: Arial, sans-serif; padding: 40px; }
          .header { text-align: center; margin-bottom: 30px; border-bottom: 2px solid #333; padding-bottom: 20px; }
          .company-name { font-size: 24px; font-weight: bold; margin-bottom: 5px; }
          .document-title { font-size: 20px; color: #666; margin-top: 10px; }
          .section { margin: 20px 0; }
          .section-title { font-size: 16px; font-weight: bold; margin-bottom: 10px; background: #f0f0f0; padding: 8px; }
          .info-row { display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #eee; }
          .label { font-weight: bold; }
          .amount { font-size: 18px; font-weight: bold; color: #2563eb; }
          .footer { margin-top: 40px; padding-top: 20px; border-top: 2px solid #333; text-align: center; color: #666; }
          table { width: 100%; border-collapse: collapse; margin: 10px 0; }
          th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
          th { background: #f0f0f0; font-weight: bold; }
          .status-badge { display: inline-block; padding: 4px 12px; border-radius: 4px; font-size: 12px; font-weight: bold; }
          .status-filed { background: #dcfce7; color: #166534; }
          .status-pending { background: #fef3c7; color: #92400e; }
        `}</style>
      </head>
      <body>
        <div className="header">
          <div className="company-name">{company.company_name || "ISP Management System"}</div>
          <div>{company.address || ""}</div>
          <div>Tax ID: {company.tax_number || "N/A"}</div>
          <div className="document-title">TAX RETURN DOCUMENT</div>
        </div>

        <div className="section">
          <div className="section-title">Return Information</div>
          <div className="info-row">
            <span className="label">Reference Number:</span>
            <span>{taxRecord.reference_number}</span>
          </div>
          <div className="info-row">
            <span className="label">Return Type:</span>
            <span>{taxRecord.return_type}</span>
          </div>
          <div className="info-row">
            <span className="label">Tax Authority:</span>
            <span>{taxRecord.tax_authority}</span>
          </div>
          <div className="info-row">
            <span className="label">Status:</span>
            <span className={`status-badge status-${taxRecord.status}`}>{taxRecord.status.toUpperCase()}</span>
          </div>
          <div className="info-row">
            <span className="label">Due Date:</span>
            <span>{new Date(taxRecord.due_date).toLocaleDateString()}</span>
          </div>
          {taxRecord.filed_date && (
            <div className="info-row">
              <span className="label">Filed Date:</span>
              <span>{new Date(taxRecord.filed_date).toLocaleDateString()}</span>
            </div>
          )}
        </div>

        <div className="section">
          <div className="section-title">Financial Summary</div>
          <table>
            <tbody>
              <tr>
                <td className="label">Total Revenue</td>
                <td style={{ textAlign: "right" }}>
                  KES {Number(taxRecord.total_revenue || 0).toLocaleString("en-US", { minimumFractionDigits: 2 })}
                </td>
              </tr>
              <tr>
                <td className="label">Total Expenses</td>
                <td style={{ textAlign: "right" }}>
                  KES {Number(taxRecord.total_expenses || 0).toLocaleString("en-US", { minimumFractionDigits: 2 })}
                </td>
              </tr>
              <tr>
                <td className="label">Taxable Income</td>
                <td style={{ textAlign: "right" }}>
                  KES {Number(taxRecord.taxable_income || 0).toLocaleString("en-US", { minimumFractionDigits: 2 })}
                </td>
              </tr>
              <tr style={{ background: "#f0f0f0" }}>
                <td className="label">Tax Due</td>
                <td style={{ textAlign: "right" }} className="amount">
                  KES {Number(taxRecord.tax_due || 0).toLocaleString("en-US", { minimumFractionDigits: 2 })}
                </td>
              </tr>
              {taxRecord.penalty_amount > 0 && (
                <tr>
                  <td className="label">Penalty Amount</td>
                  <td style={{ textAlign: "right", color: "#dc2626" }}>
                    KES {Number(taxRecord.penalty_amount).toLocaleString("en-US", { minimumFractionDigits: 2 })}
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

        {taxRecord.notes && (
          <div className="section">
            <div className="section-title">Notes</div>
            <p>{taxRecord.notes}</p>
          </div>
        )}

        <div className="footer">
          <p>This is a computer-generated document. No signature is required.</p>
          <p>
            Generated on {new Date().toLocaleDateString()} at {new Date().toLocaleTimeString()}
          </p>
        </div>
      </body>
    </html>
  )
}

export async function GET(request: NextRequest, { params }: { params: { id: string } }) {
  try {
    const { id } = params

    // Fetch tax record
    const [taxRecord] = await sql`
      SELECT * FROM tax_returns WHERE id = ${id}
    `

    if (!taxRecord) {
      return NextResponse.json({ error: "Tax record not found" }, { status: 404 })
    }

    // Fetch company profile
    const [company] = await sql`
      SELECT * FROM company_profiles LIMIT 1
    `

    // Generate HTML
    const html = renderToStaticMarkup(<TaxReturnPDF taxRecord={taxRecord} company={company || {}} />)

    // Return HTML as PDF (browser will handle PDF conversion)
    return new NextResponse(html, {
      headers: {
        "Content-Type": "text/html",
        "Content-Disposition": `attachment; filename="tax-return-${taxRecord.reference_number || id}.html"`,
      },
    })
  } catch (error) {
    console.error("Error generating tax return PDF:", error)
    return NextResponse.json({ error: "Failed to generate tax return PDF" }, { status: 500 })
  }
}
