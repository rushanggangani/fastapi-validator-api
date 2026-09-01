from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Dict

app = FastAPI(
	title="Transaction Validator App",
	description="Microservice for validating financial transactions before processing.",
	version ="1.0.0"
)

class TransactionData(BaseModel):
	transaction_id: str
	user_id: str
	amount: float
	currency: str
	merchant_type: str

@app.post("/api/v1/validate-transaction")
def validate_transaction(transaction: TransactionData) -> Dict[str,str]:
	"""
	Receives the transaction data and run business logic to flag risky behaviour
	"""

	if transaction.amount > 50000:
		return {
			"status": "FLAGGED",
			"transaction_id": transaction.transaction_id,
			"reason": "Amount exceeds automated approval threshold. Manual review required."
		}
	if transaction.merchant_type.lower() == "crypto_exchange":
		return {
			"status":"REJECTED",
			"transaction_id": transaction.transaction_id,
			"reason": "Merchant category currently blocked for this user tier."
		}
	return {
		"status": "APPROVED",
		"transaction_id": transaction.transaction_id,
		"message": "Transaction cleared for processing."
	} 
