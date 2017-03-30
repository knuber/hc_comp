
TRIM( 
	IF ( 
		[Order Details Current].[Combined Parts Master].[Part GL Expense Code] in ('1RE', '1CU' ) 
	)
	---basis territory code
	then(
		CASE trim([Order Details Current].[D_BillTo Customers].[BillTo Territory Code] )
			when '51' then 'DONNA'
			when '52' then 'DORAN'
			when '53' then 'RACHE'
			when '54' then 'KEN S'
			when '57' then 'KEN S'
			when '58' then 'JON H'
			else 
				IF ( 
					[Order Details Current].[D_ShipTo Customers].[Retail Rep] is null OR  
					[Order Details Current].[D_ShipTo Customers].[Retail Rep] is missing --BASIS usrcust
				)
				---basis billto salesman xref
				then(
					case substring( [Order Details Current].[D_BillTo Customers].[BillTo Salesman Code], 1, 3 ) 
						when ('501') then 'DORAN'
						when ('502') then 'DORAN'
						when ('503') then 'RACHE'
						when ('506') then 'JON H'
						when ('508') then 'JON H'
						--use salesman
						else trim( [Order Details Current].[D_BillTo Customers].[BillTo Salesman Code] ) 
					END
				---basis reatil rep xref
				) ELSE (  
					case substring( [Order Details Current].[D_ShipTo Customers].[Retail Rep], 1, 3 ) 
						when ('501') then 'DORAN'
						when ('502') then 'DORAN'
						when ('503') then 'RACHE'
						when ('506') then 'JON H'
						when ('508') then 'JON H'
						--use retail rep
						ELSE [Order Details Current].[D_ShipTo Customers].[Retail Rep]
					END
				)
		END
	) 
	else (
		IF ( 
			[Order Details Current].[Combined Parts Master].[Part GL Expense Code] = '1NU' 
		)
		--basis 1NU
		then(
			IF ( 
				[Order Details Current].[D_ShipTo Customers].[Nursery Rep] is null OR  
				[Order Details Current].[D_ShipTo Customers].[Nursery Rep] is missing 
			)
			--basis saleman code
			then(	
				IF ( 
					substring( [Order Details Current].[D_BillTo Customers].[BillTo Salesman Code], 1, 3 ) in ('400', '130') 
				)
				--400/130 = bill to salesman code
				then (
					[Order Details Current].[D_BillTo Customers].[BillTo Salesman Code]
				) 
				--<>400/130 = ship to salesman code
				else ( [Order Details Current].[D_ShipTo Customers].[ShipTo Salesman Code]
				)
			) 
			--nursery rep
			else (  
				[Order Details Current].[D_ShipTo Customers].[Nursery Rep] 
			)
		) 
		--basis 1GR/2WI & everything else
		else (
			IF ( 
				substring( [Order Details Current].[D_BillTo Customers].[BillTo Salesman Code], 1, 3 ) in ('400', '130')     
			) 
			-- 400/130 = bill to salesman code
			then (
				[Order Details Current].[D_BillTo Customers].[BillTo Salesman Code]
			) 
			-- <> 400/130
			else ( 
				IF ( 
					[Order Details Current].[D_ShipTo Customers].[Greenhouse Rep] is null OR  
					[Order Details Current].[D_ShipTo Customers].[Greenhouse Rep] is missing 
				)
				--ship to salesman code
				then(
					[Order Details Current].[D_ShipTo Customers].[ShipTo Salesman Code] 
				)  
				-- greenhouse rep
				ELSE (
					[Order Details Current].[D_ShipTo Customers].[Greenhouse Rep] 
				)
			)
		)
	)
)
