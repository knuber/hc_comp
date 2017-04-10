Using 'C' option on PO receipt to match invoice -> calculates PPV and stores properly in POMVAR for reporting

PrePaid
---

Idea is 3 Items on PO:
 * Down Payment to 1210
 * Down Payment Credit to 1210
 * Product
 * Product
 * Product

Caveats
 * Flags are global: separate receivers; freight per line `POMN06 OP 1`
 * Purchasing needs to be aware of the invoicing pattern for proper PO setup
 * If one invoice for freight & duty that is separate from product, need to have carrier & broker setup with same remit-to vendor.
 * If duty/freight/down-payment receipts are not vouchered at month end, may need to edit receipt before accrual posting `APMN07 OP 3`

Pros:
 * Account rec is simple
 * Variance is calculated & reportable

Cons:
 * PO correctness imperative

New Steps:
 * Add freight & customs data to PO (need to have guidance, maybe % of PO value/weight)
 * Add 2 more PO lines calculated by hand (.3 * PO total)
 * Add PO receipt for down payment
 * Edit freight/duty receipts at month end (unless have good estimate up front)





