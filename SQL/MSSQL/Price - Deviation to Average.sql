SET SHOWPLAN_TEXT ON;
SELECT
	s.*
FROM
	(
	SELECT
 		r.*,
		(item_value_usd)/item_quantity act_price,
		(
			SUM(item_value_usd) OVER (PARTITION BY SUBSTRING(part,1,11), branding, geo, channel, os_year)/
			SUM(item_quantity) OVER (PARTITION BY SUBSTRING(part,1,11), branding, geo, channel, os_year)
		)*item_quantity avg_val ,
		(
			--actual price
			(item_value_usd)/item_quantity - 
			--average price
			(
				SUM(item_value_usd) OVER (PARTITION BY SUBSTRING(part,1,11), branding, geo, channel, os_year)/
				SUM(item_quantity) OVER (PARTITION BY SUBSTRING(part,1,11), branding, geo, channel, os_year)
			) 
		) *
		item_quantity dev_val
	FROM 
		r.om_rpt r
	WHERE
		os_year = '17' and
		part <> '' AND 
		geo <> '' and
		channel <> '' AND
		status <> 'CANCELLED' AND
		dcodat is not null AND
		item_quantity <> 0 AND
		SUBSTRING(exp_code,1,1) IN ('1','2')
	) s
	OPTION (MAXDOP 8)