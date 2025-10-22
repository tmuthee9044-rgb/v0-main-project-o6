"use client"

import { useState } from "react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Badge } from "@/components/ui/badge"
import { Switch } from "@/components/ui/switch"
import { Textarea } from "@/components/ui/textarea"
import {
  CreditCard,
  Smartphone,
  Building,
  Webhook,
  TestTube,
  Save,
  AlertCircle,
  CheckCircle,
  DollarSign,
} from "lucide-react"
import { toast } from "@/hooks/use-toast"

export default function PaymentSettingsPage() {
  const [activeTab, setActiveTab] = useState("mpesa")
  const [isLoading, setIsLoading] = useState(false)
  const [testResults, setTestResults] = useState<Record<string, "success" | "error" | null>>({})

  const handleSave = async () => {
    setIsLoading(true)
    try {
      await new Promise((resolve) => setTimeout(resolve, 1000))
      toast({
        title: "Settings saved",
        description: "Payment gateway configuration has been updated successfully.",
      })
    } catch (error) {
      toast({
        title: "Error",
        description: "Failed to save settings. Please try again.",
        variant: "destructive",
      })
    } finally {
      setIsLoading(false)
    }
  }

  const handleTest = async (service: string) => {
    setTestResults((prev) => ({ ...prev, [service]: null }))
    try {
      await new Promise((resolve) => setTimeout(resolve, 2000))
      const success = Math.random() > 0.2 // 80% success rate for demo
      setTestResults((prev) => ({ ...prev, [service]: success ? "success" : "error" }))
      toast({
        title: success ? "Test successful" : "Test failed",
        description: success
          ? `${service} integration test passed successfully.`
          : `${service} integration test failed. Please check your configuration.`,
        variant: success ? "default" : "destructive",
      })
    } catch (error) {
      setTestResults((prev) => ({ ...prev, [service]: "error" }))
    }
  }

  return (
    <div className="flex-1 space-y-4 p-4 md:p-8 pt-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-3xl font-bold tracking-tight">Payment Gateway</h2>
          <p className="text-muted-foreground">Configure M-Pesa and other payment processing systems</p>
        </div>
        <div className="flex items-center space-x-2">
          <Badge variant="default" className="bg-green-100 text-green-800">
            Configured
          </Badge>
          <Button onClick={handleSave} disabled={isLoading}>
            <Save className="mr-2 h-4 w-4" />
            {isLoading ? "Saving..." : "Save Changes"}
          </Button>
        </div>
      </div>

      <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-4">
        <TabsList className="grid w-full grid-cols-4">
          <TabsTrigger value="mpesa">M-Pesa</TabsTrigger>
          <TabsTrigger value="banking">Banking</TabsTrigger>
          <TabsTrigger value="methods">Payment Methods</TabsTrigger>
          <TabsTrigger value="webhooks">Webhooks</TabsTrigger>
        </TabsList>

        <TabsContent value="mpesa" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center space-x-2">
                <Smartphone className="h-5 w-5" />
                <span>M-Pesa Daraja API Configuration</span>
              </CardTitle>
              <CardDescription>Configure M-Pesa payment integration using Safaricom Daraja API</CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="flex items-center justify-between">
                <div className="space-y-0.5">
                  <Label className="text-base">Enable M-Pesa Payments</Label>
                  <div className="text-sm text-muted-foreground">Accept payments via M-Pesa STK Push and C2B</div>
                </div>
                <Switch defaultChecked />
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="mpesa-environment">Environment</Label>
                  <Select defaultValue="sandbox">
                    <SelectTrigger>
                      <SelectValue placeholder="Select environment" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="sandbox">Sandbox</SelectItem>
                      <SelectItem value="production">Production</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <div className="space-y-2">
                  <Label htmlFor="mpesa-shortcode">Business Short Code *</Label>
                  <Input id="mpesa-shortcode" placeholder="Enter your business short code" defaultValue="" />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="mpesa-consumer-key">Consumer Key *</Label>
                  <Input id="mpesa-consumer-key" placeholder="Enter consumer key from Daraja" defaultValue="" />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="mpesa-consumer-secret">Consumer Secret *</Label>
                  <Input id="mpesa-consumer-secret" type="password" placeholder="Enter consumer secret from Daraja" />
                </div>
              </div>

              <div className="space-y-4">
                <Label className="text-base">STK Push Configuration</Label>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="stk-shortcode">STK Push Short Code</Label>
                    <Input id="stk-shortcode" placeholder="Enter STK push short code" defaultValue="" />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="stk-passkey">Passkey *</Label>
                    <Input id="stk-passkey" type="password" placeholder="Enter STK push passkey from Daraja" />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="stk-callback">Callback URL</Label>
                    <Input id="stk-callback" placeholder="https://yourdomain.com/api/mpesa/callback" defaultValue="" />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="stk-timeout">Timeout URL</Label>
                    <Input id="stk-timeout" placeholder="https://yourdomain.com/api/mpesa/timeout" defaultValue="" />
                  </div>
                </div>
              </div>

              <div className="space-y-4">
                <Label className="text-base">C2B Configuration</Label>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="c2b-shortcode">C2B Short Code</Label>
                    <Input id="c2b-shortcode" placeholder="Enter C2B short code" defaultValue="" />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="c2b-validation">Validation URL</Label>
                    <Input
                      id="c2b-validation"
                      placeholder="https://yourdomain.com/api/mpesa/validation"
                      defaultValue=""
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="c2b-confirmation">Confirmation URL</Label>
                    <Input
                      id="c2b-confirmation"
                      placeholder="https://yourdomain.com/api/mpesa/confirmation"
                      defaultValue=""
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="c2b-response-type">Response Type</Label>
                    <Select defaultValue="Completed">
                      <SelectTrigger>
                        <SelectValue placeholder="Select response type" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="Completed">Completed</SelectItem>
                        <SelectItem value="Cancelled">Cancelled</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                </div>
              </div>

              <div className="flex items-center space-x-2">
                <Button
                  variant="outline"
                  onClick={() => handleTest("M-Pesa")}
                  disabled={testResults["M-Pesa"] === null}
                >
                  <TestTube className="mr-2 h-4 w-4" />
                  Test M-Pesa Integration
                </Button>
                {testResults["M-Pesa"] === "success" && (
                  <div className="flex items-center space-x-1 text-green-600">
                    <CheckCircle className="h-4 w-4" />
                    <span className="text-sm">Integration successful</span>
                  </div>
                )}
                {testResults["M-Pesa"] === "error" && (
                  <div className="flex items-center space-x-1 text-red-600">
                    <AlertCircle className="h-4 w-4" />
                    <span className="text-sm">Integration failed</span>
                  </div>
                )}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="banking" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center space-x-2">
                <Building className="h-5 w-5" />
                <span>Bank Integration</span>
              </CardTitle>
              <CardDescription>Configure bank account details and direct bank transfers</CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="space-y-4">
                <Label className="text-base">Primary Bank Account</Label>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="bank-name">Bank Name *</Label>
                    <Select defaultValue="equity">
                      <SelectTrigger>
                        <SelectValue placeholder="Select bank" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="equity">Equity Bank</SelectItem>
                        <SelectItem value="kcb">KCB Bank</SelectItem>
                        <SelectItem value="coop">Co-operative Bank</SelectItem>
                        <SelectItem value="absa">Absa Bank</SelectItem>
                        <SelectItem value="standard">Standard Chartered</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="account-number">Account Number *</Label>
                    <Input id="account-number" placeholder="Enter bank account number" defaultValue="" />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="account-name">Account Name *</Label>
                    <Input id="account-name" placeholder="Enter account holder name" defaultValue="" />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="branch-code">Branch Code</Label>
                    <Input id="branch-code" placeholder="Enter branch code" defaultValue="" />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="swift-code">SWIFT Code</Label>
                    <Input id="swift-code" placeholder="Enter SWIFT code" defaultValue="" />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="iban">IBAN (if applicable)</Label>
                    <Input id="iban" placeholder="Enter IBAN" />
                  </div>
                </div>
              </div>

              <div className="space-y-4">
                <Label className="text-base">Bank Transfer Settings</Label>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="flex items-center space-x-2">
                    <Switch id="bank-transfers" defaultChecked />
                    <Label htmlFor="bank-transfers">Accept Bank Transfers</Label>
                  </div>
                  <div className="flex items-center space-x-2">
                    <Switch id="auto-reconciliation" />
                    <Label htmlFor="auto-reconciliation">Auto Reconciliation</Label>
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="transfer-fee">Transfer Fee (KES)</Label>
                    <Input
                      id="transfer-fee"
                      type="number"
                      placeholder="Enter transfer fee"
                      defaultValue=""
                      min="0"
                      step="0.01"
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="min-transfer">Minimum Transfer Amount</Label>
                    <Input
                      id="min-transfer"
                      type="number"
                      placeholder="Enter minimum transfer amount"
                      defaultValue=""
                      min="0"
                      step="0.01"
                    />
                  </div>
                </div>
              </div>

              <div className="space-y-2">
                <Label htmlFor="bank-instructions">Payment Instructions</Label>
                <Textarea
                  id="bank-instructions"
                  placeholder="Enter instructions for customers making bank transfers"
                  defaultValue="Please use your customer ID as the reference when making bank transfers. Transfers may take 1-2 business days to reflect in your account."
                  rows={3}
                />
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="methods" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center space-x-2">
                <CreditCard className="h-5 w-5" />
                <span>Payment Methods</span>
              </CardTitle>
              <CardDescription>Configure available payment methods and their settings</CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="space-y-4">
                <Label className="text-base">Available Payment Methods</Label>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="flex items-center justify-between p-4 border rounded-lg">
                    <div className="flex items-center space-x-3">
                      <Smartphone className="h-5 w-5 text-green-600" />
                      <div>
                        <div className="font-medium">M-Pesa</div>
                        <div className="text-sm text-muted-foreground">Mobile money payments</div>
                      </div>
                    </div>
                    <Switch defaultChecked />
                  </div>

                  <div className="flex items-center justify-between p-4 border rounded-lg">
                    <div className="flex items-center space-x-3">
                      <Building className="h-5 w-5 text-blue-600" />
                      <div>
                        <div className="font-medium">Bank Transfer</div>
                        <div className="text-sm text-muted-foreground">Direct bank transfers</div>
                      </div>
                    </div>
                    <Switch defaultChecked />
                  </div>

                  <div className="flex items-center justify-between p-4 border rounded-lg">
                    <div className="flex items-center space-x-3">
                      <CreditCard className="h-5 w-5 text-purple-600" />
                      <div>
                        <div className="font-medium">Credit/Debit Cards</div>
                        <div className="text-sm text-muted-foreground">Visa, Mastercard payments</div>
                      </div>
                    </div>
                    <Switch />
                  </div>

                  <div className="flex items-center justify-between p-4 border rounded-lg">
                    <div className="flex items-center space-x-3">
                      <DollarSign className="h-5 w-5 text-green-600" />
                      <div>
                        <div className="font-medium">Cash Payments</div>
                        <div className="text-sm text-muted-foreground">In-person cash payments</div>
                      </div>
                    </div>
                    <Switch defaultChecked />
                  </div>
                </div>
              </div>

              <div className="space-y-4">
                <Label className="text-base">Payment Processing</Label>
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="processing-fee">Processing Fee (%)</Label>
                    <Input
                      id="processing-fee"
                      type="number"
                      placeholder="Enter processing fee"
                      defaultValue=""
                      min="0"
                      max="10"
                      step="0.1"
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="min-payment">Minimum Payment (KES)</Label>
                    <Input
                      id="min-payment"
                      type="number"
                      placeholder="Enter minimum payment"
                      defaultValue=""
                      min="0"
                      step="0.01"
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="max-payment">Maximum Payment (KES)</Label>
                    <Input
                      id="max-payment"
                      type="number"
                      placeholder="Enter maximum payment"
                      defaultValue=""
                      min="0"
                      step="0.01"
                    />
                  </div>
                </div>
              </div>

              <div className="space-y-4">
                <Label className="text-base">Payment Options</Label>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="flex items-center space-x-2">
                    <Switch id="partial-payments" defaultChecked />
                    <Label htmlFor="partial-payments">Allow Partial Payments</Label>
                  </div>
                  <div className="flex items-center space-x-2">
                    <Switch id="overpayments" defaultChecked />
                    <Label htmlFor="overpayments">Allow Overpayments</Label>
                  </div>
                  <div className="flex items-center space-x-2">
                    <Switch id="auto-receipts" defaultChecked />
                    <Label htmlFor="auto-receipts">Auto-generate Receipts</Label>
                  </div>
                  <div className="flex items-center space-x-2">
                    <Switch id="payment-reminders" defaultChecked />
                    <Label htmlFor="payment-reminders">Send Payment Reminders</Label>
                  </div>
                </div>
              </div>

              <div className="space-y-4">
                <Label className="text-base">Currency Settings</Label>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="base-currency">Base Currency</Label>
                    <Select defaultValue="kes">
                      <SelectTrigger>
                        <SelectValue placeholder="Select currency" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="kes">KES - Kenyan Shilling</SelectItem>
                        <SelectItem value="ugx">UGX - Ugandan Shilling</SelectItem>
                        <SelectItem value="tzs">TZS - Tanzanian Shilling</SelectItem>
                        <SelectItem value="usd">USD - US Dollar</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                  <div className="flex items-center space-x-2 pt-6">
                    <Switch id="multi-currency" />
                    <Label htmlFor="multi-currency">Enable Multi-Currency</Label>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="webhooks" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center space-x-2">
                <Webhook className="h-5 w-5" />
                <span>Webhook Configuration</span>
              </CardTitle>
              <CardDescription>Configure webhooks for payment notifications and callbacks</CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="space-y-4">
                <Label className="text-base">Webhook Endpoints</Label>
                <div className="space-y-4">
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div className="space-y-2">
                      <Label htmlFor="payment-success-webhook">Payment Success URL</Label>
                      <Input
                        id="payment-success-webhook"
                        placeholder="https://yourdomain.com/webhooks/payment-success"
                        defaultValue=""
                      />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="payment-failed-webhook">Payment Failed URL</Label>
                      <Input
                        id="payment-failed-webhook"
                        placeholder="https://yourdomain.com/webhooks/payment-failed"
                        defaultValue=""
                      />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="payment-pending-webhook">Payment Pending URL</Label>
                      <Input
                        id="payment-pending-webhook"
                        placeholder="https://yourdomain.com/webhooks/payment-pending"
                        defaultValue=""
                      />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="refund-webhook">Refund URL</Label>
                      <Input id="refund-webhook" placeholder="https://yourdomain.com/webhooks/refund" defaultValue="" />
                    </div>
                  </div>
                </div>
              </div>

              <div className="space-y-4">
                <Label className="text-base">Webhook Security</Label>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="webhook-secret">Webhook Secret Key</Label>
                    <Input id="webhook-secret" type="password" placeholder="Enter webhook secret key" />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="signature-method">Signature Method</Label>
                    <Select defaultValue="hmac-sha256">
                      <SelectTrigger>
                        <SelectValue placeholder="Select method" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="hmac-sha256">HMAC-SHA256</SelectItem>
                        <SelectItem value="hmac-sha1">HMAC-SHA1</SelectItem>
                        <SelectItem value="md5">MD5</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                </div>
              </div>

              <div className="space-y-4">
                <Label className="text-base">Retry Configuration</Label>
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="max-retries">Max Retries</Label>
                    <Input
                      id="max-retries"
                      type="number"
                      placeholder="Enter max retries"
                      defaultValue=""
                      min="0"
                      max="10"
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="retry-delay">Retry Delay (seconds)</Label>
                    <Input id="retry-delay" type="number" placeholder="Enter retry delay" defaultValue="" min="1" />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="timeout">Timeout (seconds)</Label>
                    <Input id="timeout" type="number" placeholder="Enter timeout" defaultValue="" min="1" max="300" />
                  </div>
                </div>
              </div>

              <div className="space-y-4">
                <Label className="text-base">Webhook Events</Label>
                <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                  <div className="flex items-center space-x-2">
                    <Switch id="payment-created" defaultChecked />
                    <Label htmlFor="payment-created">Payment Created</Label>
                  </div>
                  <div className="flex items-center space-x-2">
                    <Switch id="payment-completed" defaultChecked />
                    <Label htmlFor="payment-completed">Payment Completed</Label>
                  </div>
                  <div className="flex items-center space-x-2">
                    <Switch id="payment-failed" defaultChecked />
                    <Label htmlFor="payment-failed">Payment Failed</Label>
                  </div>
                  <div className="flex items-center space-x-2">
                    <Switch id="payment-cancelled" defaultChecked />
                    <Label htmlFor="payment-cancelled">Payment Cancelled</Label>
                  </div>
                  <div className="flex items-center space-x-2">
                    <Switch id="refund-created" />
                    <Label htmlFor="refund-created">Refund Created</Label>
                  </div>
                  <div className="flex items-center space-x-2">
                    <Switch id="refund-completed" />
                    <Label htmlFor="refund-completed">Refund Completed</Label>
                  </div>
                  <div className="flex items-center space-x-2">
                    <Switch id="chargeback-created" />
                    <Label htmlFor="chargeback-created">Chargeback Created</Label>
                  </div>
                  <div className="flex items-center space-x-2">
                    <Switch id="dispute-created" />
                    <Label htmlFor="dispute-created">Dispute Created</Label>
                  </div>
                </div>
              </div>

              <div className="flex items-center space-x-2">
                <Button
                  variant="outline"
                  onClick={() => handleTest("Webhooks")}
                  disabled={testResults.Webhooks === null}
                >
                  <TestTube className="mr-2 h-4 w-4" />
                  Test Webhooks
                </Button>
                {testResults.Webhooks === "success" && (
                  <div className="flex items-center space-x-1 text-green-600">
                    <CheckCircle className="h-4 w-4" />
                    <span className="text-sm">Webhooks working</span>
                  </div>
                )}
                {testResults.Webhooks === "error" && (
                  <div className="flex items-center space-x-1 text-red-600">
                    <AlertCircle className="h-4 w-4" />
                    <span className="text-sm">Webhook test failed</span>
                  </div>
                )}
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  )
}
