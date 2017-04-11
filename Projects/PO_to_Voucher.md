Using 'C' option on PO receipt to match invoice -> calculates PPV and stores properly in POMVAR for reporting

PrePaid
---

Idea is 3 Items on PO:
* Down Payment to 1210
* Down Payment Credit to 1210
* Product
* Product
* Product

### Caveats
* Flags are global: separate receivers; freight per line `POMN06 OP 1`
* Purchasing needs to be aware of the invoicing pattern for proper PO setup
* If one invoice for freight & duty that is separate from product, need to have carrier & broker setup with same remit-to vendor.
* If duty/freight/down-payment receipts are not vouchered at month end, may need to edit receipt before accrual posting `APMN07 OP 3`

### Pros:
* Account rec is simple
* Variance is calculated & reportable

### Cons:
* PO correctness imperative

New Process Flow:
---------------------

_Invoicing matrix_

|Freight		|Prepaid				|Invoice					|Collect				|
|---------------|-----------------------|-----------------------	|-----------------------|
|Carrier Code	|Blank					|Blank						|Pick One				|
|Amt			|Blank					|6%							|6%						|

|Duty & Customs	|Prepaid				|Invoice					|Collect				|
|---------------|-----------------------|-----------------------	|-----------------------|
|Customs Broker	|Blank					|Blank						|Pick One				|
|Amt			|Blank					|6%							|6%						|



1.	Determine invoicing arrangement & terms

	`POMN06 OP 1` default flagged as calculate seprately and freight is singular per PO, not per-item

	Test:
	*	_would need to test to verify that freight per PO will create multiple receivers_
	*	_would also need to test if duty type invoice is possible_

2. Add 2 more PO lines calculated by hand
	1. Prepaid is 30% down or whatever terms are _(qty = `30%` price = `$1`)_
	2. Prepaid Credit is same with negative price unit as above _(qty = `30%`, price = `-$1`)_
3. Add PO receipt for down payment in full qty
4. Add receipts for goods _(receipts will be created for duty/freight depending on above configuration)_
5. Add receipt for credit based on invoice amount
6. Voucher goods final ivoice to product & credit receivers using 'C' option
7. Voucher freight & duty using the C option to true up to invoice (_container to PO association will be needed_)